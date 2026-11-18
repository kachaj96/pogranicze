"""Write assets/raw/procedural/manifest.json (asset id = file, sha12, size, anchor, review)."""

import hashlib
import json
from pathlib import Path

from PIL import Image

D = Path("assets/raw/procedural")
PROPS = {"house": ((160, 226), (3, 2)), "tree": ((144, 216), (1, 1)), "seal_stone": ((48, 128), (1, 1))}

entries = []
char = json.loads((D / "wanderer.json").read_text())
for p in sorted(D.glob("*.png")):
    n = p.stem
    e = {"file": p.name, "sha12": hashlib.sha256(p.read_bytes()).hexdigest()[:12],
         "size": list(Image.open(p).size), "source": "procedural, tools/art", "license": "project-owned",
         "perspective": "isometric 2:1 (camera elev 30, azim 45)", "review": "pending"}
    if n in PROPS:
        e.update(anchor=list(PROPS[n][0]), footprint_cells=list(PROPS[n][1]), generator="tools/art/blender/props.py")
    elif n.startswith("wanderer"):
        e.update(frame_size=char["frame_size"], anchor=char["anchor"], directions=char["directions"],
                 generator="tools/art/blender/wanderer.py", meta="wanderer.json")
    elif n.startswith("block"):
        e.update(anchor=[32, 52], footprint_cells=[1, 1], generator="tools/art/gen_terrain.py")
    else:
        e.update(anchor=[32, 16], generator="tools/art/gen_terrain.py")
    entries.append(e)
(D / "manifest.json").write_text(json.dumps({"assets": entries}, indent=2, ensure_ascii=False) + "\n")
print(len(entries), "entries")
