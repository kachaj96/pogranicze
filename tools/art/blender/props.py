"""Environment props rendered with the same 2:1 rig and palette pipeline.

Run:  blender -b --python tools/art/blender/props.py -- <out_dir> <prop>
      prop: house | tree | seal_stone
Then: python3 -I tools/art/pixelize.py still <out_dir>/<prop> <final_dir> <prop>

World origin = footprint centre on the ground; footprint in logical cells is
listed in PROPS so the game can block the right cells.
"""

import math
import os
import random
import sys

import bmesh
import bpy

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import iso_rig as R  # noqa: E402

# name: (canvas_w, canvas_h, anchor_x, anchor_y, footprint cells)
PROPS = {
    "house": (320, 272, 160, 226, (3, 2)),
    "tree": (288, 240, 144, 216, (1, 1)),
    "seal_stone": (96, 144, 48, 128, (1, 1)),
}


def mats():
    return {
        "plaster": R.material("plaster", 9, bump=0.35, bump_scale=14.0),
        "timber": R.material("timber", 10, bump=0.3, bump_scale=20.0, stretch_z=0.2),
        "shingle": R.material("shingle", 10, bump=0.8, bump_scale=9.0, stretch_z=2.5),
        "stone": R.material("stone", 11, bump=0.9, bump_scale=8.0),
        "leaves": R.material("leaves", 12, bump=1.6, bump_scale=14.0),
        "bark": R.material("bark", 13, bump=0.9, bump_scale=10.0, stretch_z=0.15),
        "glow": R.material("glow", 14, emissive=True),
        "wood": R.material("wood", 8, bump=0.3, bump_scale=20.0, stretch_z=0.2),
        "taint": R.material("taint", 17, emissive=True),
    }


def house(M):
    W, D, H = 2.8, 1.8, 1.9
    R.box("foundation", (W + 0.12, D + 0.12, 0.3), (0, 0, 0.15), M["stone"], bevel=0.04)
    R.box("walls", (W, D, H), (0, 0, 0.3 + H / 2), M["plaster"], bevel=0.02)
    # Timber frame: corner posts, sill, top beam, and braces on the two visible faces.
    for sx in (-1, 1):
        for sy in (-1, 1):
            R.box("post", (0.12, 0.12, H), (sx * W / 2, sy * D / 2, 0.3 + H / 2), M["timber"], bevel=0.01)
    for z in (0.36, 0.3 + H - 0.05, 0.3 + H * 0.55):
        R.box("beam_x", (W + 0.02, 0.06, 0.1), (0, -D / 2 - 0.02, z), M["timber"], bevel=0.01)
        R.box("beam_y", (0.06, D + 0.02, 0.1), (W / 2 + 0.02, 0, z), M["timber"], bevel=0.01)
    for x in (-0.75, 0.75):
        R.box("mid_post", (0.1, 0.06, H), (x, -D / 2 - 0.02, 0.3 + H / 2), M["timber"], bevel=0.01)
    R.box("brace", (0.08, 0.06, 1.2), (-1.08, -D / 2 - 0.025, 0.3 + H * 0.3), M["timber"], bevel=0.01,
          rotation=(0, math.radians(32), 0))
    R.box("brace2", (0.06, 0.08, 1.1), (W / 2 + 0.025, 0.45, 0.3 + H * 0.3), M["timber"], bevel=0.01,
          rotation=(math.radians(-35), 0, 0))
    # Door (front, -Y face) and windows with warm light.
    R.box("door", (0.62, 0.08, 1.15), (0.05, -D / 2 - 0.02, 0.3 + 0.575), M["wood"], bevel=0.01)
    R.box("door_frame", (0.76, 0.06, 1.25), (0.05, -D / 2 - 0.005, 0.3 + 0.62), M["timber"], bevel=0.01)
    R.box("window_f", (0.42, 0.06, 0.38), (-1.1, -D / 2 - 0.03, 1.45), M["glow"], bevel=0.0)
    R.box("window_s", (0.06, 0.42, 0.38), (W / 2 + 0.03, -0.35, 1.45), M["glow"], bevel=0.0)
    for (loc, size) in (((-1.1, -D / 2 - 0.05, 1.45), (0.04, 0.05, 0.4)), ((-1.1, -D / 2 - 0.05, 1.45), (0.44, 0.05, 0.04))):
        R.box("mullion", size, loc, M["timber"], bevel=0.0)
    R.box("shutter", (0.2, 0.05, 0.42), (-1.42, -D / 2 - 0.05, 1.45), M["wood"], bevel=0.008, rotation=(0, 0, math.radians(-25)))
    # Gable roof along X, with overhang. Built from two slabs.
    rh = 1.25
    pitch = math.atan2(rh, D / 2 + 0.25)
    slab_len = math.hypot(rh, D / 2 + 0.25) + 0.12
    for sy in (-1, 1):
        R.box("roof", (W + 0.5, slab_len, 0.12), (0, sy * (D / 4 + 0.08), 0.3 + H + rh / 2 - 0.02), M["shingle"],
              bevel=0.02, rotation=(-sy * pitch, 0, 0))
    # Gable triangles (plaster) on both short ends.
    for sx in (-1, 1):
        me = bpy.data.meshes.new("gable")
        bm = bmesh.new()
        x = sx * W / 2
        v = [bm.verts.new((x, -D / 2, 0.3 + H)), bm.verts.new((x, D / 2, 0.3 + H)), bm.verts.new((x, 0, 0.3 + H + rh))]
        bm.faces.new(v)
        bm.to_mesh(me)
        bm.free()
        g = bpy.data.objects.new("gable", me)
        bpy.context.scene.collection.objects.link(g)
        g.modifiers.new("s", "SOLIDIFY").thickness = 0.05
        R._finish(g, M["plaster"], smooth=False)
    R.box("ridge", (W + 0.55, 0.14, 0.12), (0, 0, 0.3 + H + rh + 0.02), M["timber"], bevel=0.02)
    R.box("chimney", (0.36, 0.36, 1.3), (0.8, 0.35, 0.3 + H + 0.75), M["stone"], bevel=0.03)
    # Repairs (art bible motif): a patched plank and an iron band on the door.
    R.box("patch", (0.4, 0.04, 0.22), (0.9, -D / 2 - 0.03, 0.75), M["wood"], bevel=0.005, rotation=(0, math.radians(6), 0))
    R.box("door_band", (0.64, 0.1, 0.05), (0.05, -D / 2 - 0.03, 1.2), M["timber"], bevel=0.0)
    # Small props at the door: barrel and firewood.
    R.cylinder("barrel", 0.22, 0.22, 0.55, (-0.55, -D / 2 - 0.35, 0.275), M["wood"], verts=14)
    R.cylinder("barrel_hoop", 0.225, 0.225, 0.05, (-0.55, -D / 2 - 0.35, 0.42), M["timber"], verts=14)
    for i in range(5):
        R.cylinder("log", 0.07, 0.07, 0.6, (W / 2 + 0.25, -0.5 + i * 0.15, 0.08 + (i % 2) * 0.12), M["bark"],
                   rotation=(0, math.radians(90), math.radians(90)), verts=8)


def tree(M):
    rnd = random.Random(7)
    R.cylinder("trunk", 0.26, 0.15, 2.0, (0, 0, 1.0), M["bark"], verts=12)
    for i in range(5):
        a = i * 1.3
        R.limb("root", (0, 0, 0.35), (math.cos(a) * 0.55, math.sin(a) * 0.55, -0.02), 0.11, 0.04, M["bark"])
    for (a, z, l) in ((0.6, 1.6, 0.9), (2.6, 1.9, 0.8), (4.4, 1.7, 0.85)):
        R.limb("branch", (0, 0, z), (math.cos(a) * l, math.sin(a) * l, z + 0.6), 0.08, 0.04, M["bark"])
    clusters = []
    for i in range(16):
        a = rnd.random() * math.tau
        rr = rnd.uniform(0.1, 0.75)
        clusters.append(((math.cos(a) * rr, math.sin(a) * rr, rnd.uniform(2.3, 3.3)), rnd.uniform(0.38, 0.6)))
    clusters.append(((0, 0, 2.8), 0.8))
    for (loc, r) in clusters:
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=3, radius=r, location=loc)
        o = bpy.context.active_object
        tex = bpy.data.textures.new("leafnoise", "VORONOI")
        tex.noise_scale = 0.18
        disp = o.modifiers.new("d", "DISPLACE")
        disp.texture = tex
        disp.strength = 0.22
        o.scale = (1.0, 1.0, 0.82)
        R._finish(o, M["leaves"])
    # A few ferns at the foot.
    for i in range(4):
        a = rnd.random() * math.tau
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.22, location=(math.cos(a) * 0.6, math.sin(a) * 0.6, 0.1))
        o = bpy.context.active_object
        o.scale = (1.3, 1.3, 0.5)
        R._finish(o, M["leaves"], smooth=False)


def seal_stone(M):
    me = bpy.data.meshes.new("menhir")
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co.x *= 0.56 if v.co.z < 0 else 0.4
        v.co.y *= 0.42 if v.co.z < 0 else 0.3
        v.co.z = (v.co.z + 0.5) * 1.75
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new("menhir", me)
    bpy.context.scene.collection.objects.link(o)
    sub = o.modifiers.new("sub", "SUBSURF")
    sub.levels = 1
    bev = o.modifiers.new("b", "BEVEL")
    bev.width = 0.03
    R._finish(o, M["stone"], smooth=False)
    # Glowing crack running down the front face and a carved seal ring.
    pts = [(0.03, -0.17, 1.55), (-0.06, -0.18, 1.25), (0.05, -0.19, 0.9), (-0.03, -0.2, 0.6), (0.06, -0.21, 0.25)]
    for a, b in zip(pts, pts[1:]):
        R.limb("crack", a, b, 0.022, 0.022, M["taint"])
    bpy.ops.mesh.primitive_torus_add(major_radius=0.14, minor_radius=0.016, location=(0, -0.175, 1.2), rotation=(math.radians(90), 0, 0))
    ring = bpy.context.active_object
    R._finish(ring, M["taint"])
    for i in range(3):
        a = i * 2.1
        R.box("rubble", (0.16, 0.12, 0.09), (math.cos(a) * 0.4, math.sin(a) * 0.35, 0.04), M["stone"], bevel=0.02,
              rotation=(0.2 * i, 0.3, a))


def main():
    args = sys.argv[sys.argv.index("--") + 1:]
    out_dir, prop = args[0], args[1]
    cw, ch, ax, ay, _ = PROPS[prop]
    scene = R.reset_scene()
    cam = R.setup_camera(scene, cw, ch, ax, ay)
    R.setup_sun(scene, cam)
    fo = R.setup_outputs(scene)
    M = mats()
    R.ground_catcher()
    {"house": house, "tree": tree, "seal_stone": seal_stone}[prop](M)
    R.render_frames(scene, fo, os.path.join(out_dir, prop), [1])
    print("RENDER DONE", prop)


main()
