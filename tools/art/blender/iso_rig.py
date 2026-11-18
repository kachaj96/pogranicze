"""Shared Blender setup for POGRANICZE sprite renders (Blender 4.5 LTS, Cycles CPU).

Projection: orthographic, camera elevation 30 deg, azimuth 45 deg. This gives
exact 2:1 isometry: one world unit (= one logical cell) spans 64x32 px.
1 world unit = 45.2548 px horizontally; vertical world units are * cos(30).

The render does NOT produce final colours. It writes data passes that
tools/art/pixelize.py turns into palette-mapped pixel art:
  diff_####.png  direct diffuse light (all albedo = 1, so this is irradiance)
  ao_####.png    ambient occlusion
  idx_####.png   material pass index / 64
  alpha_####.png coverage
"""

import math

import bpy
from mathutils import Matrix, Vector

PX_PER_UNIT = 64.0 / math.sqrt(2.0)  # 45.2548
CAM_ELEV = math.radians(30.0)
CAM_AZIM = math.radians(45.0)


def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 24
    scene.cycles.use_denoising = False
    scene.cycles.max_bounces = 2
    scene.cycles.diffuse_bounces = 1
    scene.cycles.pixel_filter_type = "BOX"
    scene.cycles.filter_width = 1.0
    scene.render.film_transparent = True
    scene.view_settings.view_transform = "Raw"
    scene.view_settings.look = "None"
    scene.world = bpy.data.worlds.new("World")
    scene.world.color = (0.0, 0.0, 0.0)
    scene.world.light_settings.distance = 0.35
    vl = scene.view_layers[0]
    vl.use_pass_diffuse_direct = True
    vl.use_pass_ambient_occlusion = True
    vl.use_pass_material_index = True
    vl.cycles.use_pass_shadow_catcher = True
    return scene


def ground_catcher(size=8.0):
    """Invisible ground plane that only records cast shadows (shadow_ pass)."""
    bpy.ops.mesh.primitive_plane_add(size=size, location=(0, 0, 0))
    plane = bpy.context.active_object
    plane.name = "shadow_catcher"
    plane.is_shadow_catcher = True
    return plane


def setup_camera(scene, canvas_w, canvas_h, anchor_x, anchor_y):
    """Ortho camera so that world origin lands on pixel (anchor_x, anchor_y)."""
    cam_data = bpy.data.cameras.new("iso_cam")
    cam_data.type = "ORTHO"
    big = max(canvas_w, canvas_h)
    cam_data.ortho_scale = big / PX_PER_UNIT
    cam_data.shift_x = -(anchor_x - canvas_w / 2.0) / big
    cam_data.shift_y = (anchor_y - canvas_h / 2.0) / big
    cam_data.clip_start = 0.1
    cam_data.clip_end = 100.0
    cam = bpy.data.objects.new("iso_cam", cam_data)
    scene.collection.objects.link(cam)
    cam.rotation_euler = (math.pi / 2.0 - CAM_ELEV, 0.0, CAM_AZIM)
    forward = cam.rotation_euler.to_matrix() @ Vector((0.0, 0.0, -1.0))
    cam.location = -forward * 30.0
    scene.camera = cam
    scene.render.resolution_x = canvas_w
    scene.render.resolution_y = canvas_h
    scene.render.resolution_percentage = 100
    return cam


def setup_sun(scene, cam, strength=math.pi):
    """Sun from the screen's upper-left and slightly in front (art bible)."""
    light_dir_cam = Vector((0.5, -0.22, -0.84)).normalized()  # direction light travels
    light_dir = cam.rotation_euler.to_matrix() @ light_dir_cam
    sun_data = bpy.data.lights.new("sun", "SUN")
    sun_data.energy = strength
    sun_data.angle = math.radians(2.0)
    sun = bpy.data.objects.new("sun", sun_data)
    scene.collection.objects.link(sun)
    sun.rotation_euler = light_dir.to_track_quat("-Z", "Y").to_euler()
    return sun


def setup_outputs(scene):
    """Compositor file outputs for the data passes. Returns the File Output node."""
    scene.use_nodes = True
    tree = scene.node_tree
    for n in list(tree.nodes):
        tree.nodes.remove(n)
    rl = tree.nodes.new("CompositorNodeRLayers")
    comp = tree.nodes.new("CompositorNodeComposite")
    tree.links.new(rl.outputs["Image"], comp.inputs["Image"])
    fo = tree.nodes.new("CompositorNodeOutputFile")
    fo.format.file_format = "PNG"
    fo.format.color_depth = "16"
    fo.format.color_mode = "BW"
    fo.file_slots.clear()
    for name in ("diff_", "ao_", "idx_", "alpha_", "shadow_"):
        fo.file_slots.new(name)
    to_bw = tree.nodes.new("CompositorNodeRGBToBW")
    tree.links.new(rl.outputs["DiffDir"], to_bw.inputs[0])
    tree.links.new(to_bw.outputs[0], fo.inputs["diff_"])
    ao_bw = tree.nodes.new("CompositorNodeRGBToBW")
    tree.links.new(rl.outputs["AO"], ao_bw.inputs[0])
    tree.links.new(ao_bw.outputs[0], fo.inputs["ao_"])
    div = tree.nodes.new("CompositorNodeMath")
    div.operation = "DIVIDE"
    div.inputs[1].default_value = 64.0
    tree.links.new(rl.outputs["IndexMA"], div.inputs[0])
    tree.links.new(div.outputs[0], fo.inputs["idx_"])
    tree.links.new(rl.outputs["Alpha"], fo.inputs["alpha_"])
    sh_bw = tree.nodes.new("CompositorNodeRGBToBW")
    tree.links.new(rl.outputs["Shadow Catcher"], sh_bw.inputs[0])
    tree.links.new(sh_bw.outputs[0], fo.inputs["shadow_"])
    return fo


_materials = {}


def material(name, index, emissive=False, bump=0.0, bump_scale=18.0, stretch_z=1.0):
    """White diffuse material tagged with a pass index (colour comes from the palette).
    bump > 0 adds procedural noise folds/grain that become pixel detail after banding."""
    if name in _materials:
        return _materials[name]
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    m.pass_index = index
    nt = m.node_tree
    bsdf = nt.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (1, 1, 1, 1)
    bsdf.inputs["Roughness"].default_value = 1.0
    if bump > 0:
        coord = nt.nodes.new("ShaderNodeTexCoord")
        mapping = nt.nodes.new("ShaderNodeMapping")
        mapping.inputs["Scale"].default_value = (1.0, 1.0, stretch_z)
        noise = nt.nodes.new("ShaderNodeTexNoise")
        noise.inputs["Scale"].default_value = bump_scale
        noise.inputs["Detail"].default_value = 3.0
        bmp = nt.nodes.new("ShaderNodeBump")
        bmp.inputs["Strength"].default_value = bump
        nt.links.new(coord.outputs["Object"], mapping.inputs["Vector"])
        nt.links.new(mapping.outputs["Vector"], noise.inputs["Vector"])
        nt.links.new(noise.outputs["Fac"], bmp.inputs["Height"])
        nt.links.new(bmp.outputs["Normal"], bsdf.inputs["Normal"])
    if emissive:
        bsdf.inputs["Emission Color"].default_value = (1, 1, 1, 1)
        bsdf.inputs["Emission Strength"].default_value = 1.0
    _materials[name] = m
    return m


def render_frames(scene, fo, out_dir, frames):
    fo.base_path = out_dir
    for f in frames:
        scene.frame_set(f)
        bpy.ops.render.render(write_still=False)


# ---------------------------------------------------------------- mesh helpers

def _finish(obj, mat, smooth=True, parent=None):
    if mat is not None:
        obj.data.materials.append(mat)
    if smooth:
        for p in obj.data.polygons:
            p.use_smooth = True
    if parent is not None:
        set_parent(obj, parent)
    return obj


def set_parent(obj, parent):
    bpy.context.view_layer.update()
    mw = obj.matrix_world.copy()
    obj.parent = parent
    obj.matrix_parent_inverse = parent.matrix_world.inverted()
    obj.matrix_world = mw


def joint(name, location, parent=None):
    e = bpy.data.objects.new(name, None)
    bpy.context.scene.collection.objects.link(e)
    e.location = location
    e.rotation_mode = "XYZ"
    if parent is not None:
        set_parent(e, parent)
    return e


def box(name, size, location, mat, parent=None, bevel=0.02, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=location, rotation=rotation)
    o = bpy.context.active_object
    o.name = name
    o.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel > 0:
        mod = o.modifiers.new("bevel", "BEVEL")
        mod.width = bevel
        mod.segments = 2
    return _finish(o, mat, smooth=bevel > 0, parent=parent)


def cylinder(name, r1, r2, depth, location, mat, parent=None, rotation=(0, 0, 0), verts=16):
    bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=r1, radius2=r2, depth=depth, location=location, rotation=rotation)
    o = bpy.context.active_object
    o.name = name
    return _finish(o, mat, parent=parent)


def sphere(name, radius, location, mat, parent=None, scale=(1, 1, 1), segments=16):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=segments // 2, radius=radius, location=location)
    o = bpy.context.active_object
    o.name = name
    o.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return _finish(o, mat, parent=parent)


def limb(name, top, bottom, r_top, r_bottom, mat, parent=None):
    """Tapered cylinder from point top to point bottom."""
    top, bottom = Vector(top), Vector(bottom)
    d = bottom - top
    mid = (top + bottom) / 2
    rot = d.to_track_quat("Z", "Y").to_euler()
    return cylinder(name, r_top, r_bottom, d.length, mid, mat, parent=parent, rotation=rot, verts=12)
