"""Procedural isometric 2:1 pixel-art terrain (proof of concept).

Generates 64x32 floor tiles and a raised stone block with exact diamond
geometry, a restricted palette from docs/05_ART_DIRECTION.md and light from
the upper left. Textures are periodic in the tile's plane coordinates, so
tiles repeat on the isometric lattice without seams.

Usage: python3 -I tools/art/gen_terrain.py <out_dir>
"""

import math
import random
import sys
from pathlib import Path

from PIL import Image

W, H = 64, 32
HW, HH = 32, 16
EDGE_SHADE = False  # True draws a subtle tile rim (combat grid look)


def hexc(s):
    s = s.lstrip("#")
    return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4))


# Material ramps (dark -> light). Derived from the art bible accents.
GRASS = [hexc(c) for c in ("#1f2a22", "#2a3a2b", "#34472f", "#3f5436", "#4c623d", "#5b7245", "#6e8450")]
DIRT = [hexc(c) for c in ("#2a2320", "#3a2f28", "#4a3c31", "#5a4a3b", "#6d5a47", "#806b55")]
STONE = [hexc(c) for c in ("#171c20", "#232d31", "#2e3b40", "#34454a", "#43555a", "#566a6c", "#6f8282", "#8a9a96")]
MOSS = [hexc(c) for c in ("#2f3f2a", "#3f5434", "#556a55")]
TAINT = [hexc(c) for c in ("#2b2030", "#4a3552", "#816782", "#b38fb8", "#e0c4e6")]


def periodic_noise(u, v, seed, octaves=((1, 1.0), (2, 0.6), (3, 0.45), (5, 0.3), (8, 0.2))):
    """Smooth noise periodic in u, v with period 1 (sum of integer-frequency waves)."""
    rnd = random.Random(seed)
    total = 0.0
    norm = 0.0
    for freq, amp in octaves:
        for _ in range(3):
            a = rnd.randint(-freq, freq)
            b = rnd.randint(-freq, freq)
            if a == 0 and b == 0:
                b = freq
            ph = rnd.random() * math.tau
            total += amp * math.sin(math.tau * (a * u + b * v) + ph)
            norm += amp
    return 0.5 + 0.5 * total / norm


def plane_uv(px, py):
    """Pixel centre of a 64x32 tile image -> plane coords (u, v) in [0, 1) around the tile."""
    sx = px + 0.5 - HW
    sy = py + 0.5 - HH
    a = sx / HW
    b = sy / HH
    return ((a + b) * 0.5) % 1.0, ((b - a) * 0.5) % 1.0


def in_diamond(px, py):
    return abs(px + 0.5 - HW) / HW + abs(py + 0.5 - HH) / HH <= 1.0


def ramp(colors, t):
    t = min(0.999, max(0.0, t))
    return colors[int(t * len(colors))]


def floor_tile(kind, seed):
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    pix = img.load()
    rnd = random.Random(seed)
    for py in range(H):
        for px in range(W):
            if not in_diamond(px, py):
                continue
            u, v = plane_uv(px, py)
            n = periodic_noise(u, v, seed)
            fine = periodic_noise(u, v, seed + 7, ((6, 1.0), (9, 0.7), (13, 0.5)))
            t = 0.55 * n + 0.45 * fine
            if kind == "grass":
                pix[px, py] = ramp(GRASS, 0.15 + t * 0.75) + (255,)
            elif kind in ("dirt", "crack"):
                pix[px, py] = ramp(DIRT, 0.1 + t * 0.8) + (255,)
    if kind == "grass":
        # Grass tufts: short blades, light tip, dark root.
        for _ in range(46):
            x, y = rnd.randrange(4, W - 4), rnd.randrange(3, H - 2)
            if not (in_diamond(x, y) and in_diamond(x, y - 2)):
                continue
            hgt = rnd.choice((1, 2, 2, 3))
            pix[x, y] = GRASS[1] + (255,)
            for k in range(1, hgt + 1):
                pix[x, y - k] = GRASS[min(6, 3 + k)] + (255,)
        # A few pebbles.
        for _ in range(3):
            x, y = rnd.randrange(10, W - 10), rnd.randrange(8, H - 8)
            if in_diamond(x + 1, y + 1):
                pix[x, y] = STONE[6] + (255,)
                pix[x + 1, y] = STONE[4] + (255,)
                pix[x, y + 1] = STONE[2] + (255,)
    if kind == "crack":
        # Jagged fissure across the tile with a tainted glow.
        x, y = 12.0, 17.0
        pts = []
        while x < 52:
            pts.append((int(x), int(y)))
            x += rnd.uniform(1.0, 2.0)
            y += rnd.uniform(-1.2, 1.2)
            y = min(22, max(10, y))
        for (cx, cy) in pts:
            for dx in range(-2, 3):
                for dy in range(-1, 2):
                    qx, qy = cx + dx, cy + dy
                    if in_diamond(qx, qy) and abs(dx) + abs(dy) * 2 >= 2:
                        r, g, b, _ = pix[qx, qy]
                        tr, tg, tb = TAINT[1]
                        pix[qx, qy] = ((r + tr) // 2, (g + tg) // 2, (b + tb) // 2, 255)
        for i, (cx, cy) in enumerate(pts):
            if in_diamond(cx, cy):
                pix[cx, cy] = TAINT[0] + (255,)
            if in_diamond(cx, cy - 1):
                pix[cx, cy - 1] = (TAINT[3] if i % 3 else TAINT[4]) + (255,)
    # Upper-left light: lighten the NW edge, darken the SE edge by one step.
    for py in range(H):
        for px in range(W):
            if not in_diamond(px, py):
                continue
            edge = abs(px + 0.5 - HW) / HW + abs(py + 0.5 - HH) / HH
            if EDGE_SHADE and edge > 0.9:
                r, g, b, a = pix[px, py]
                if py < HH:
                    f = 1.08 if px < HW else 1.0
                else:
                    f = 0.82
                pix[px, py] = (min(255, int(r * f)), min(255, int(g * f)), min(255, int(b * f)), a)
    return img


def stone_block(seed, height=36):
    """Raised stone block occupying one cell. Foot (cell centre) at (32, height + 16)."""
    rnd = random.Random(seed)
    img = Image.new("RGBA", (W, H + height), (0, 0, 0, 0))
    pix = img.load()
    for py in range(H + height):
        for px in range(W):
            sx = px + 0.5 - HW
            # Top face: diamond shifted up by height.
            ty = py + 0.5 - HH
            if abs(sx) / HW + abs(ty) / HH <= 1.0:
                u, v = plane_uv(px, py)
                t = periodic_noise(u, v, seed, ((2, 1.0), (4, 0.6), (7, 0.5)))
                pix[px, py] = ramp(STONE, 0.45 + t * 0.5) + (255,)
                continue
            # Side faces: between the lower edges of the top diamond and the base diamond.
            if abs(sx) > HW:
                continue
            top_edge = HH + (HH * (1 - abs(sx) / HW))  # lower edge of top face
            bot_edge = top_edge + height
            if not (top_edge <= py + 0.5 <= bot_edge):
                continue
            depth = py + 0.5 - top_edge  # 0 at top, height at bottom
            left = sx < 0
            # Brick courses parallel to the face edge.
            course_h = 6
            row = int(depth // course_h)
            along = (abs(sx) + (row % 2) * 7)
            mortar = (depth % course_h) < 1.0 or (along % 14) < 1.0
            base = 3 if left else 1
            n = periodic_noise((sx / 64) % 1, (depth / 40) % 1, seed + row, ((3, 1.0), (7, 0.5)))
            shade = base + (1 if n > 0.62 else 0) - (1 if n < 0.3 else 0)
            if mortar:
                shade = base - 2
            shade -= int(depth / height * 1.5)  # darker towards the ground
            pix[px, py] = STONE[max(0, min(len(STONE) - 1, shade))] + (255,)
    # Outline the top face rim with a light highlight (upper-left light).
    for px in range(1, W - 1):
        sx = px + 0.5 - HW
        y_top = int(HH - HH * (1 - abs(sx) / HW))
        if 0 <= y_top < H + height and pix[px, y_top][3]:
            pix[px, y_top] = STONE[7] + (255,) if sx < 0 else STONE[6] + (255,)
    # Moss on the top and dripping down the left face.
    for _ in range(26):
        x = rnd.randrange(8, 40)
        y = rnd.randrange(6, 26)
        if pix[x, y][3]:
            pix[x, y] = rnd.choice(MOSS) + (255,)
    # Crack on the right face (wounded world motif, used sparingly).
    x, y = 44, 30
    for _ in range(12):
        if 0 <= x < W and 0 <= y < H + height and pix[x, y][3]:
            pix[x, y] = STONE[0] + (255,)
        x += rnd.choice((0, 1))
        y += 1
    return img


def mock_scene(tiles, block, crack, path, cols=8, rows=8, scale=3):
    """Composite a small board to judge seams and readability."""
    width = (cols + rows) * HW + 8
    height = (cols + rows) * HH + 60
    img = Image.new("RGBA", (width, height), (23, 28, 32, 255))
    ox, oy = rows * HW, 50
    blocks = {(2, 2), (2, 3), (5, 4)}
    cracks = {(4, 2), (3, 6)}
    paths = {(c, 5) for c in range(cols)} | {(c, 4) for c in range(1, 3)}
    for r in range(rows):
        for c in range(cols):
            x = ox + (c - r) * HW - HW
            y = oy + (c + r) * HH - HH
            t = tiles[(c * 7 + r * 3) % len(tiles)]
            if (c, r) in cracks:
                t = crack
            elif (c, r) in paths:
                t = path
            img.alpha_composite(t, (x, y))
    for (c, r) in sorted(blocks, key=lambda p: p[0] + p[1]):
        x = ox + (c - r) * HW - HW
        y = oy + (c + r) * HH - HH - (block.height - H)
        img.alpha_composite(block, (x, y))
    return img.resize((img.width * scale, img.height * scale), Image.Resampling.NEAREST)


def main():
    out = Path(sys.argv[1] if len(sys.argv) > 1 else "assets/raw/procedural")
    out.mkdir(parents=True, exist_ok=True)
    grass = [floor_tile("grass", s) for s in (11, 12, 13)]
    path = floor_tile("dirt", 21)
    crack = floor_tile("crack", 31)
    block = stone_block(41)
    for i, g in enumerate(grass):
        g.save(out / f"floor_grass_{i}.png")
    path.save(out / "floor_dirt_path.png")
    crack.save(out / "floor_crack.png")
    block.save(out / "block_stone.png")
    mock_scene(grass, block, crack, path).save(out / "_preview_board.png")
    print("written to", out)


if __name__ == "__main__":
    main()
