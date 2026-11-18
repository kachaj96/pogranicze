#!/usr/bin/env bash
# Rebuild all procedural art into assets/raw/procedural.
# Usage: BLENDER=/path/to/blender tools/art/build_all.sh [work_dir]
# Needs Blender 4.5 LTS and python3 with Pillow + numpy.
set -euo pipefail
cd "$(dirname "$0")/../.."
BLENDER="${BLENDER:-blender}"
WORK="${1:-$(mktemp -d)}"
OUT=assets/raw/procedural
mkdir -p "$OUT"
python3 -I tools/art/gen_terrain.py "$OUT" >/dev/null
rm -f "$OUT/_preview_board.png"
"$BLENDER" -b --python tools/art/blender/wanderer.py -- "$WORK/wanderer" >/dev/null 2>&1
python3 -I tools/art/pixelize.py character "$WORK/wanderer" "$OUT" wanderer
mv "$OUT/_preview_wanderer.gif" "$WORK/" 2>/dev/null || true
for p in house tree seal_stone; do
  "$BLENDER" -b --python tools/art/blender/props.py -- "$WORK/props" "$p" >/dev/null 2>&1
  python3 -I tools/art/pixelize.py still "$WORK/props/$p" "$OUT" "$p"
done
python3 -I tools/art/make_manifest.py
echo "built into $OUT (work dir $WORK)"
