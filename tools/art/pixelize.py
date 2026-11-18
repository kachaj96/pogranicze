"""Turn Blender data passes into palette-mapped pixel art.

Each material index has a hand-picked 4-colour ramp (dark -> light) based on
docs/05_ART_DIRECTION.md. Light = direct diffuse + ambient occlusion,
quantised into bands, so every frame and direction shares one palette.

Usage:
  python3 -I tools/art/pixelize.py character <render_dir> <out_dir> <name>
  python3 -I tools/art/pixelize.py still <render_dir> <out_dir> <name>
"""

import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image


def hexc(s):
    s = s.lstrip("#")
    return [int(s[i:i + 2], 16) for i in (0, 2, 4)]


RAMPS = {
    1: ["#4e3029", "#80513f", "#b07a5e", "#d6a47f"],   # skin
    2: ["#18211f", "#26332f", "#36493f", "#4c6253"],   # cloak / dark wool
    3: ["#36261b", "#5a412d", "#7c5c3d", "#a08156"],   # tunic / ochre wool
    4: ["#1c1a1a", "#2c2826", "#403833", "#584d45"],   # trousers
    5: ["#21150d", "#3a2617", "#5a3b23", "#7b5434"],   # leather
    6: ["#1d2427", "#44525a", "#7a8a8c", "#c9d3cc"],   # iron
    7: ["#1b1410", "#30231b", "#473427", "#5e4634"],   # hair
    8: ["#2b1e14", "#4a3322", "#6a4b31", "#8a6644"],   # wood
    9: ["#2a2d28", "#4f5047", "#7d7b6c", "#aaa58f"],   # plaster / daub
    10: ["#1a1716", "#2f2a27", "#4a423c", "#655a51"],  # dark timber / shingles
    11: ["#171c20", "#2e3b40", "#4b5e60", "#71847f"],  # stone
    12: ["#1a2418", "#2a3a26", "#3f5636", "#5d7646"],  # leaves
    13: ["#221812", "#3b2a1f", "#56402e", "#6e553e"],  # bark
    14: ["#7a4a1c", "#c07a2c", "#e8a850", "#ffe2a0"],  # warm window glow (emissive)
    15: ["#2b2320", "#4a3a2c", "#6b5639", "#8c7448"],  # thatch / straw
    16: ["#0f0d0c", "#1a1512", "#2a201a", "#3a2c22"],  # eyes
    17: ["#4a3552", "#816782", "#b38fb8", "#e8cdf0"],  # taint / broken seal glow (emissive)
}
BANDS = (0.16, 0.40, 0.72)
EMISSIVE = {14, 17}
OUTLINE_DARKEN = 0.75


def load16(path):
    im = Image.open(path)
    a = np.array(im, dtype=np.float64)
    if a.ndim == 3:
        a = a[..., 0]
    return a / (65535.0 if a.max() > 255 else 255.0)


def shade(render_dir, frame):
    tag = f"{frame:04d}.png"
    diff = load16(render_dir / f"diff_{tag}")
    ao = load16(render_dir / f"ao_{tag}")
    idx = np.rint(load16(render_dir / f"idx_{tag}") * 64.0).astype(int)
    alpha = load16(render_dir / f"alpha_{tag}")
    h, w = diff.shape
    out = np.zeros((h, w, 4), dtype=np.uint8)
    light = diff * 0.82 + ao * 0.32
    band = np.digitize(light, BANDS)
    solid = (alpha >= 0.5) & (idx > 0)
    for mi, ramp in RAMPS.items():
        mask = solid & (idx == mi)
        if not mask.any():
            continue
        cols = np.array([hexc(c) for c in ramp], dtype=np.uint8)
        b = band if mi not in EMISSIVE else np.clip(band + 2, 0, 3)
        if mi == 6:  # metal: highlight only on the brightest spots
            b = np.where(light > 0.9, 3, np.minimum(b, 2))
        out[mask, :3] = cols[b[mask]]
        out[mask, 3] = 255
    # Cast shadow on the ground: two translucent steps, never on the object itself.
    sp = render_dir / f"shadow_{tag}"
    if sp.exists():
        s = 1.0 - load16(sp)
        # Fade towards the canvas border so a clipped shadow never shows a straight edge.
        yy, xx = np.mgrid[0:h, 0:w]
        edge = np.minimum(np.minimum(xx, w - 1 - xx), np.minimum(yy, h - 1 - yy))
        s = s * np.clip(edge / 18.0, 0.0, 1.0)
        ground = ~solid
        out[ground & (s > 0.22)] = [18, 22, 26, 96]
        out[ground & (s > 0.5)] = [18, 22, 26, 140]
    return out, idx


def cleanup(img):
    """Remove isolated single pixels whose 4 neighbours all share another colour."""
    a = img.copy()
    h, w, _ = img.shape
    for y in range(1, h - 1):
        for x in range(1, w - 1):
            if img[y, x, 3] == 0:
                continue
            n = [img[y - 1, x], img[y + 1, x], img[y, x - 1], img[y, x + 1]]
            if all(nn[3] == 255 for nn in n):
                first = n[0]
                if all((nn == first).all() for nn in n) and not (img[y, x] == first).all():
                    a[y, x] = first
    return a


def outline(img):
    """1 px selective outline: darkened colour of the adjacent opaque pixel."""
    h, w, _ = img.shape
    out = img.copy()
    opaque = img[..., 3] == 255
    for y in range(h):
        for x in range(w):
            if opaque[y, x]:
                continue
            best = None
            for dy, dx in ((0, -1), (0, 1), (-1, 0), (1, 0)):
                yy, xx = y + dy, x + dx
                if 0 <= yy < h and 0 <= xx < w and opaque[yy, xx]:
                    c = img[yy, xx, :3].astype(int)
                    if best is None or c.sum() < best.sum():
                        best = c
            if best is not None:
                out[y, x, :3] = (best * OUTLINE_DARKEN * 0.55).astype(np.uint8)
                out[y, x, 3] = 255
    return out


def finish(render_dir, frame):
    img, _ = shade(render_dir, frame)
    return outline(cleanup(img))


def character(render_root, out_dir, name):
    render_root, out_dir = Path(render_root), Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    rmeta = json.loads((render_root / "render_meta.json").read_text())
    dirs = rmeta["directions"]
    fw, fh = rmeta["frame_size"]
    meta = {"name": name, "frame_size": [fw, fh], "anchor": rmeta["anchor"], "directions": dirs,
            "source": "procedural Blender render, tools/art/blender", "animations": {}}
    previews = {}
    for anim_dir in sorted(p for p in render_root.iterdir() if p.is_dir()):
        anim = anim_dir.name
        frames_by_dir = []
        for d in dirs:
            ddir = anim_dir / d
            nums = sorted(int(p.stem.split("_")[1]) for p in ddir.glob("alpha_*.png"))
            frames_by_dir.append([finish(ddir, n) for n in nums])
        count = len(frames_by_dir[0])
        sheet = Image.new("RGBA", (fw * count, fh * len(dirs)), (0, 0, 0, 0))
        for r, frames in enumerate(frames_by_dir):
            for c, f in enumerate(frames):
                sheet.paste(Image.fromarray(f, "RGBA"), (c * fw, r * fh))
        sheet.save(out_dir / f"{name}_{anim}.png")
        fps = 8 if anim == "walk" else 4
        meta["animations"][anim] = {"file": f"{name}_{anim}.png", "frames": count, "fps": fps,
                                    "loop": True, "layout": "rows=directions, cols=frames"}
        previews[anim] = frames_by_dir
    (out_dir / f"{name}.json").write_text(json.dumps(meta, indent=2) + "\n")
    return previews, (fw, fh), tuple(rmeta["anchor"])


def preview_gif(previews, path, size, anchor, scale=3):
    """4x2 grid of all 8 directions, walk then idle, on a dark ground."""
    frames_out = []
    for anim, reps in (("walk", 3), ("idle", 2)):
        if anim not in previews:
            continue
        by_dir = previews[anim]
        for _ in range(reps):
            for i in range(len(by_dir[0])):
                fw, fh = size
                ax, ay = anchor
                canvas = Image.new("RGBA", (fw * 4, fh * 2), (23, 28, 32, 255))
                for d in range(8):
                    x, y = (d % 4) * fw, (d // 4) * fh
                    ground = Image.new("RGBA", (fw, fh), (0, 0, 0, 0))
                    gp = ground.load()
                    for yy in range(fh):
                        for xx in range(fw):
                            if abs(xx + 0.5 - ax) / 64 + abs(yy + 0.5 - ay) / 32 <= 1:
                                gp[xx, yy] = (52, 71, 47, 255)
                    canvas.alpha_composite(ground, (x, y))
                    canvas.alpha_composite(Image.fromarray(by_dir[d][i], "RGBA"), (x, y))
                frames_out.append(canvas.resize((canvas.width * scale, canvas.height * scale), Image.Resampling.NEAREST).convert("P", palette=Image.Palette.ADAPTIVE))
    dur = 125
    frames_out[0].save(path, save_all=True, append_images=frames_out[1:], duration=dur, loop=0, disposal=2)


def still(render_dir, out_dir, name):
    render_dir, out_dir = Path(render_dir), Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    nums = sorted(int(p.stem.split("_")[1]) for p in render_dir.glob("alpha_*.png"))
    img = finish(render_dir, nums[0])
    Image.fromarray(img, "RGBA").save(out_dir / f"{name}.png")


if __name__ == "__main__":
    mode = sys.argv[1]
    if mode == "character":
        pv, size, anchor = character(sys.argv[2], sys.argv[3], sys.argv[4])
        preview_gif(pv, Path(sys.argv[3]) / f"_preview_{sys.argv[4]}.gif", size, anchor)
    elif mode == "still":
        still(sys.argv[2], sys.argv[3], sys.argv[4])
