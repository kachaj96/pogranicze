"""Wanderer (IRON school) character: model, joint rig, idle + walk, 8 directions.

Run:  blender -b --python tools/art/blender/wanderer.py -- <out_dir>
Then: python3 -I tools/art/pixelize.py character <out_dir> <final_dir>

Character faces -Y at rest. Joints are empties (axes = world axes at rest),
so rotation_euler.x swings a limb forward (negative) or backward (positive).
"""

import math
import os
import sys

import bpy

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import iso_rig as R  # noqa: E402

CANVAS = (192, 144)
ANCHOR = (80, 128)
DIRECTIONS = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
ANIMS = {"idle": 4, "walk": 8}

# Material pass indices (palette ramps live in pixelize.py).
M = {}


def build():
    M["skin"] = R.material("skin", 1)
    M["cloak"] = R.material("cloak", 2, bump=0.55, bump_scale=7.0, stretch_z=0.25)
    M["tunic"] = R.material("tunic", 3, bump=0.35, bump_scale=12.0, stretch_z=0.4)
    M["trousers"] = R.material("trousers", 4, bump=0.3, bump_scale=10.0)
    M["leather"] = R.material("leather", 5, bump=0.25, bump_scale=25.0)
    M["metal"] = R.material("metal", 6, bump=0.15, bump_scale=30.0)
    M["hair"] = R.material("hair", 7, bump=0.5, bump_scale=30.0, stretch_z=0.3)
    M["wood"] = R.material("wood", 8)
    M["eyes"] = R.material("eyes", 16)

    root = R.joint("root", (0, 0, 0))
    pelvis = R.joint("pelvis", (0, 0, 0.98), root)
    spine = R.joint("spine", (0, 0, 1.02), pelvis)
    neck = R.joint("neck", (0, 0, 1.52), spine)
    cloak_j = R.joint("cloak", (0, 0.06, 1.50), spine)

    # --- legs
    for side, sx in (("L", 1), ("R", -1)):
        x = 0.10 * sx
        hip = R.joint("hip." + side, (x, 0, 0.94), pelvis)
        knee = R.joint("knee." + side, (x, -0.01, 0.52), hip)
        ankle = R.joint("ankle." + side, (x, 0, 0.11), knee)
        R.limb("thigh." + side, (x, 0, 0.96), (x, -0.01, 0.52), 0.085, 0.07, M["trousers"], hip)
        R.limb("shin." + side, (x, -0.01, 0.52), (x, 0, 0.14), 0.07, 0.06, M["trousers"], knee)
        R.limb("bootcuff." + side, (x, 0, 0.30), (x, 0, 0.12), 0.075, 0.07, M["leather"], knee)
        R.box("boot." + side, (0.13, 0.27, 0.12), (x, -0.05, 0.06), M["leather"], ankle, bevel=0.03)

    # --- hips, tunic skirt, belt, scabbard
    R.box("hips", (0.34, 0.22, 0.16), (0, 0, 0.97), M["tunic"], pelvis, bevel=0.04)
    R.cylinder("skirt", 0.25, 0.2, 0.36, (0, 0, 0.82), M["tunic"], pelvis, verts=20)
    belt = R.cylinder("belt", 0.205, 0.205, 0.07, (0, 0, 1.0), M["leather"], pelvis, verts=20)
    R.box("buckle", (0.08, 0.03, 0.06), (0, -0.21, 1.0), M["metal"], pelvis, bevel=0.005)
    R.box("pouch", (0.09, 0.07, 0.1), (-0.17, -0.1, 0.93), M["leather"], pelvis, bevel=0.015)
    # Sword in scabbard strapped across the back, hilt above the right shoulder.
    back = R.joint("sword_back", (0, 0.34, 1.25), J("spine"))
    back.rotation_euler = (math.radians(8), math.radians(-32), 0)
    R.box("scabbard_body", (0.06, 0.04, 0.78), (0, 0.34, 1.2), M["leather"], back, bevel=0.012)
    R.box("scabbard_tip", (0.065, 0.045, 0.07), (0, 0.34, 0.83), M["metal"], back, bevel=0.012)
    R.box("guard", (0.2, 0.05, 0.035), (0, 0.34, 1.6), M["metal"], back, bevel=0.01)
    R.limb("grip", (0, 0.34, 1.61), (0, 0.34, 1.78), 0.02, 0.02, M["wood"], back)
    R.sphere("pommel", 0.035, (0, 0.34, 1.8), M["metal"], back, segments=8)

    # --- torso
    torso = R.box("torso", (0.40, 0.25, 0.50), (0, 0, 1.27), M["tunic"], spine, bevel=0.06)
    # widen chest / narrow waist with a simple taper
    for v in torso.data.vertices:
        t = (v.co.z + 0.25) / 0.5  # 0 at waist, 1 at shoulders
        v.co.x *= 0.85 + 0.25 * t
        v.co.y *= 0.95 + 0.1 * t
    R.box("strap", (0.42, 0.27, 0.05), (0, 0, 1.24), M["leather"], spine, bevel=0.01,
          rotation=(0, math.radians(35), 0))

    # --- cloak: open shell over back and shoulders
    import bmesh
    me = bpy.data.meshes.new("cloak_mesh")
    bm = bmesh.new()
    rings = []
    for k, (z, r) in enumerate(((1.50, 0.25), (1.30, 0.29), (1.0, 0.31), (0.72, 0.34), (0.48, 0.37))):
        ring = []
        for i in range(15):
            a = math.radians(-115 + 230 * i / 14) + math.pi / 2  # centred on +Y (back)
            ring.append(bm.verts.new((math.cos(a) * r, math.sin(a) * r * 0.9 + 0.03, z)))
        rings.append(ring)
    for k in range(len(rings) - 1):
        for i in range(14):
            bm.faces.new((rings[k][i], rings[k][i + 1], rings[k + 1][i + 1], rings[k + 1][i]))
    bm.to_mesh(me)
    bm.free()
    cloak = bpy.data.objects.new("cloak_shell", me)
    bpy.context.scene.collection.objects.link(cloak)
    sol = cloak.modifiers.new("solid", "SOLIDIFY")
    sol.thickness = 0.025
    R._finish(cloak, M["cloak"], parent=cloak_j)
    R.cylinder("collar", 0.2, 0.17, 0.08, (0, 0.02, 1.52), M["cloak"], cloak_j, verts=16)

    # --- arms
    for side, sx in (("L", 1), ("R", -1)):
        x = 0.26 * sx
        shoulder = R.joint("shoulder." + side, (x, 0, 1.46), spine)
        elbow = R.joint("elbow." + side, (x + 0.02 * sx, 0, 1.17), shoulder)
        R.limb("upperarm." + side, (x, 0, 1.47), (x + 0.02 * sx, 0, 1.17), 0.065, 0.055, M["tunic"], shoulder)
        R.limb("forearm." + side, (x + 0.02 * sx, 0, 1.17), (x + 0.03 * sx, -0.02, 0.92), 0.055, 0.045, M["tunic"], elbow)
        R.limb("bracer." + side, (x + 0.02 * sx, -0.005, 1.10), (x + 0.03 * sx, -0.02, 0.95), 0.062, 0.055, M["metal"], elbow)
        R.sphere("hand." + side, 0.05, (x + 0.03 * sx, -0.025, 0.88), M["skin"], elbow, segments=10)
    # Iron pauldron on the left shoulder only (asymmetric on purpose).
    R.sphere("pauldron", 0.12, (0.27, 0, 1.47), M["metal"], bpy.data.objects["shoulder.L"], scale=(1.0, 1.05, 0.7), segments=14)

    # --- head and hood
    R.limb("neckpiece", (0, 0, 1.52), (0, 0, 1.6), 0.06, 0.06, M["skin"], neck)
    R.sphere("head", 0.14, (0, -0.01, 1.69), M["skin"], neck, scale=(0.95, 1.0, 1.08), segments=16)
    R.sphere("hair", 0.145, (0, 0.03, 1.71), M["hair"], neck, scale=(1.0, 1.0, 1.05), segments=14)
    R.box("beard", (0.15, 0.07, 0.09), (0, -0.12, 1.60), M["hair"], neck, bevel=0.03)
    R.box("brow", (0.17, 0.05, 0.035), (0, -0.125, 1.74), M["hair"], neck, bevel=0.012)
    for ex in (-0.05, 0.05):
        R.sphere("eye", 0.022, (ex, -0.13, 1.705), M["eyes"], neck, segments=8)
    R.box("nose", (0.035, 0.04, 0.05), (0, -0.15, 1.67), M["skin"], neck, bevel=0.012)
    hood = R.sphere("hood", 0.18, (0, 0.045, 1.72), M["cloak"], neck, scale=(1.0, 1.0, 1.08), segments=16)
    # Cut the face opening: remove front-facing vertices of the hood.
    import bmesh as _bm
    b = _bm.new()
    b.from_mesh(hood.data)
    kill = [v for v in b.verts if v.co.y < -0.06 and v.co.z < 0.13 and v.co.z > -0.14]
    _bm.ops.delete(b, geom=kill, context="VERTS")
    b.to_mesh(hood.data)
    b.free()
    hs = hood.modifiers.new("solid", "SOLIDIFY")
    hs.thickness = 0.02
    R.cylinder("hood_tip", 0.07, 0.01, 0.16, (0, 0.17, 1.74), M["cloak"], neck, rotation=(math.radians(-70), 0, 0), verts=10)
    return root


def J(name):
    return bpy.data.objects[name]


def key_pose(frame, pose):
    """pose: {joint_name: (rx, ry, rz) in degrees} plus optional 'pelvis_z'."""
    for name, rot in pose.items():
        if name == "pelvis_z":
            J("pelvis").location.z = 0.98 + rot
            J("pelvis").keyframe_insert("location", index=2, frame=frame)
            continue
        o = J(name)
        o.rotation_euler = tuple(math.radians(a) for a in rot)
        o.keyframe_insert("rotation_euler", frame=frame)


def walk_pose(p):
    s, c = math.sin(p), math.cos(p)
    pose = {}
    for side, ph in (("L", 0.0), ("R", math.pi)):
        sp, cp = math.sin(p + ph), math.cos(p + ph)
        thigh = -26.0 * sp
        knee = 6.0 + 42.0 * max(0.0, cp) ** 1.4
        pose["hip." + side] = (thigh, 0, 0)
        pose["knee." + side] = (knee, 0, 0)
        pose["ankle." + side] = (-(thigh + knee) * 0.7 + (8.0 if sp < -0.3 else 0.0), 0, 0)
        arm = 20.0 * sp
        pose["shoulder." + side] = (arm, 0, 4.0 if side == "L" else -4.0)
        pose["elbow." + side] = (-14.0 - 10.0 * max(0.0, -sp), 0, 0)
    pose["spine"] = (-5.0, 0, 5.0 * s)
    pose["neck"] = (3.0, 0, -4.0 * s)
    pose["cloak"] = (7.0 + 3.0 * math.cos(2 * p), 0, -3.0 * s)
    pose["pelvis_z"] = -0.035 + 0.025 * math.cos(2 * p)
    return pose


def idle_pose(p):
    s = math.sin(p)
    pose = {
        "spine": (-1.5 * s, 0, 0),
        "neck": (1.0 * s, 0, 0),
        "cloak": (2.5 + 1.5 * s, 0, 0),
        "pelvis_z": -0.004 + 0.006 * s,
    }
    for side, sx in (("L", 1), ("R", -1)):
        pose["hip." + side] = (0, 0, 0)
        pose["knee." + side] = (3.0, 0, 0)
        pose["ankle." + side] = (-3.0, 0, 0)
        pose["shoulder." + side] = (2.0 * s, 0, 3.0 * sx)
        pose["elbow." + side] = (-10.0 - 2.0 * s, 0, 0)
    return pose


def main():
    out_dir = sys.argv[sys.argv.index("--") + 1]
    scene = R.reset_scene()
    cam = R.setup_camera(scene, CANVAS[0], CANVAS[1], *ANCHOR)
    os.makedirs(out_dir, exist_ok=True)
    import json
    with open(os.path.join(out_dir, "render_meta.json"), "w") as fh:
        json.dump({"frame_size": list(CANVAS), "anchor": list(ANCHOR), "directions": DIRECTIONS}, fh)
    R.setup_sun(scene, cam)
    fo = R.setup_outputs(scene)
    root = build()
    R.ground_catcher()
    frame = 1
    ranges = {}
    for anim, count in ANIMS.items():
        start = frame
        for i in range(count):
            p = 2 * math.pi * i / count
            key_pose(frame, walk_pose(p) if anim == "walk" else idle_pose(p))
            frame += 1
        ranges[anim] = range(start, frame)
    for fc in (bpy.data.actions[:] if bpy.data.actions else []):
        for curve in fc.fcurves:
            for kp in curve.keyframe_points:
                kp.interpolation = "CONSTANT"
    for d_index, d_name in enumerate(DIRECTIONS):
        root.rotation_euler = (0, 0, math.radians(45 + (4 - d_index) * 45))
        for anim, frames in ranges.items():
            R.render_frames(scene, fo, os.path.join(out_dir, anim, d_name), frames)
    print("RENDER DONE", out_dir)


main()
