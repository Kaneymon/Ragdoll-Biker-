"""Builds the low-poly park props in Blender (run inside Blender: exec(open(path).read())).

Every prop is one joined mesh textured from a shared atlas (assets/models/park/ParkAtlas.png,
painted by tools/park_atlas.py): while modelling, faces use materials named after atlas cells;
at the end each face's UVs are squeezed into its cell and the object gets the single atlas
material. Units are studs; front = -Y, up = +Z. Exports assets/models/park/ParkProps.fbx.
"""
import math
import random

import bmesh
import bpy

ROOT = r"C:\Users\kgkan\Documents\GitHub\Ragdoll Biker 💀🦴\assets\models\park"
CELLS = ["LeafLight", "LeafDark", "FirNeedle", "Bark", "WoodLight", "WoodDark", "Metal", "PaintRed",
         "PaintBlue", "PaintYellow", "PetalPink", "PetalYellow", "PetalPurple", "Stone", "Glow", "Rope"]
GRID = 4
MARGIN = 0.12  # keep UVs away from cell edges so neighbours never bleed in

random.seed(11)

for obj in list(bpy.data.objects):
    bpy.data.objects.remove(obj, do_unlink=True)
for mesh in list(bpy.data.meshes):
    bpy.data.meshes.remove(mesh)


def cell_material(name):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    return mat


# --- primitives (each returns a new object using one atlas cell) -------------------------------
def finish(obj, cell, location=(0, 0, 0), rotation=(0, 0, 0)):
    obj.location = location
    obj.rotation_euler = rotation
    obj.data.materials.append(cell_material(cell))
    return obj


def cylinder(cell, radius, depth, location, rotation=(0, 0, 0), sides=8, radius2=None):
    bpy.ops.mesh.primitive_cone_add(vertices=sides, radius1=radius, radius2=radius if radius2 is None else radius2, depth=depth)
    return finish(bpy.context.object, cell, location, rotation)


def cone(cell, radius, depth, location, sides=8):
    bpy.ops.mesh.primitive_cone_add(vertices=sides, radius1=radius, radius2=0, depth=depth)
    return finish(bpy.context.object, cell, location)


def box(cell, size, location, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1)
    obj = bpy.context.object
    obj.scale = size
    bpy.ops.object.transform_apply(scale=True)
    return finish(obj, cell, location, rotation)


def blob(cell, radius, location, squash=0.85, jitter=0.18):
    """Low-poly rounded lump (leaves, bushes): a jittered icosphere."""
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=radius)
    obj = bpy.context.object
    for v in obj.data.vertices:
        v.co *= 1 + random.uniform(-jitter, jitter)
        v.co.z *= squash
    return finish(obj, cell, location)


def tube(cell, a, b, radius, sides=6):
    """Cylinder from point a to point b."""
    from mathutils import Vector
    a, b = Vector(a), Vector(b)
    mid, d = (a + b) / 2, b - a
    obj = cylinder(cell, radius, d.length, mid, sides=sides)
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = d.to_track_quat("Z", "Y")
    return obj


def join(name, parts):
    bpy.ops.object.select_all(action="DESELECT")
    for p in parts:
        p.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    obj = bpy.context.object
    obj.name = name
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)  # origin = ground centre
    return obj


# --- props ---------------------------------------------------------------------------------------
def oak_tree():
    parts = [cylinder("Bark", 1.3, 10, (0, 0, 5), radius2=0.8, sides=7)]
    parts.append(tube("Bark", (0, 0, 7), (2.4, 0.5, 10), 0.45))
    parts.append(tube("Bark", (0, 0, 7.5), (-2, -0.8, 10.5), 0.4))
    for x, y, z, r, c in [(0, 0, 13, 5.5, "LeafLight"), (2.8, 0.6, 11.5, 4, "LeafDark"),
                          (-2.6, -0.9, 12, 4.2, "LeafLight"), (0.4, 2.2, 15, 3.6, "LeafDark")]:
        parts.append(blob(c, r, (x, y, z)))
    return join("OakTree", parts)


def fir_tree():
    parts = [cylinder("Bark", 0.9, 4, (0, 0, 2), radius2=0.7, sides=6)]
    for z, r, h in [(6, 5.2, 7), (10, 4, 6), (13.5, 2.8, 5), (16.3, 1.6, 3.6)]:
        parts.append(cone("FirNeedle", r, h, (0, 0, z), sides=8))
    return join("FirTree", parts)


def bush():
    parts = [blob("LeafDark", 2.2, (0, 0, 1.6)), blob("LeafLight", 1.7, (1.6, 0.4, 1.3)),
             blob("LeafDark", 1.5, (-1.4, -0.6, 1.2)), blob("LeafLight", 1.3, (0.3, -1.4, 1.1))]
    return join("Bush", parts)


def flower(x, y, petal, height):
    parts = [tube("LeafDark", (x, y, 0), (x, y, height), 0.08, sides=4)]
    for i in range(5):
        a = i * math.tau / 5
        parts.append(blob(petal, 0.32, (x + math.cos(a) * 0.35, y + math.sin(a) * 0.35, height), squash=0.5, jitter=0.05))
    parts.append(blob("PetalYellow" if petal != "PetalYellow" else "WoodLight", 0.22, (x, y, height + 0.05), squash=0.6, jitter=0))
    parts.append(blob("LeafLight", 0.35, (x + 0.25, y, height * 0.4), squash=0.4, jitter=0))  # leaf
    return parts


def flower_patch():
    parts = []
    for i in range(9):
        petal = ["PetalPink", "PetalPurple", "PetalYellow"][i % 3]
        parts += flower(random.uniform(-2.2, 2.2), random.uniform(-2.2, 2.2), petal, random.uniform(0.9, 1.6))
    return join("FlowerPatch", parts)


def bench():
    parts = []
    for i, y in enumerate((-0.5, 0, 0.5)):
        parts.append(box("WoodLight", (6, 0.45, 0.18), (0, y, 1.9)))
    for z in (2.6, 3.2):
        parts.append(box("WoodLight", (6, 0.16, 0.45), (0, 0.85, z), rotation=(math.radians(-12), 0, 0)))
    for x in (-2.5, 2.5):
        parts.append(box("Metal", (0.25, 1.4, 0.25), (x, 0, 1.75)))
        parts.append(box("Metal", (0.25, 0.25, 1.8), (x, -0.5, 0.9)))
        parts.append(box("Metal", (0.25, 0.25, 3.3), (x, 0.65, 1.65), rotation=(math.radians(-10), 0, 0)))
    return join("Bench", parts)


def picnic_table():
    parts = []
    for y in (-0.9, -0.3, 0.3, 0.9):
        parts.append(box("WoodLight", (7, 0.55, 0.22), (0, y, 3.2)))
    for y in (-2.6, 2.6):
        for dy in (-0.3, 0.3):
            parts.append(box("WoodLight", (7, 0.55, 0.2), (0, y + dy, 1.8)))
    for x in (-2.8, 2.8):
        for s in (-1, 1):
            parts.append(tube("WoodDark", (x, s * 2.9, 0), (x, 0, 3.1), 0.2, sides=4))
        parts.append(box("WoodDark", (0.3, 6, 0.3), (x, 0, 1.6)))
    return join("PicnicTable", parts)


def lamp():
    parts = [cylinder("Metal", 0.6, 0.6, (0, 0, 0.3), sides=8), cylinder("Metal", 0.22, 11, (0, 0, 5.8), radius2=0.16, sides=8)]
    parts.append(box("Rope", (1.6, 1.6, 0.25), (0, 0, 11.4)))
    parts.append(box("Glow", (1.2, 1.2, 1.6), (0, 0, 12.4)))
    parts.append(cone("Rope", 1.3, 0.9, (0, 0, 13.65), sides=4))
    for x, y in ((0.65, 0.65), (-0.65, 0.65), (0.65, -0.65), (-0.65, -0.65)):
        parts.append(box("Rope", (0.15, 0.15, 1.7), (x, y, 12.4)))
    return join("Lamp", parts)


def swing_set():
    parts = []
    w, h = 7, 9
    for x in (-w, w):
        for s in (-1, 1):
            parts.append(tube("PaintBlue", (x, s * 3, 0), (x, 0, h), 0.28))
    parts.append(tube("PaintRed", (-w - 0.5, 0, h), (w + 0.5, 0, h), 0.34))
    for x in (-3.2, 3.2):
        for dx in (-0.8, 0.8):
            parts.append(tube("Rope", (x + dx, 0, h), (x + dx, 0, 2.2), 0.06, sides=4))
        parts.append(box("PaintYellow", (2.2, 0.9, 0.2), (x, 0, 2.1)))
    return join("SwingSet", parts)


def jungle_gym():
    parts = []
    size, levels = 3, 2
    colours = ["PaintYellow", "PaintRed"]
    for i in range(3):
        for j in range(3):
            x, y = (i - 1) * size, (j - 1) * size
            parts.append(tube(colours[(i + j) % 2], (x, y, 0), (x, y, size * levels), 0.16))
    for k in range(1, levels + 1):
        z = k * size
        for i in range(3):
            parts.append(tube("PaintBlue", ((i - 1) * size, -size, z), ((i - 1) * size, size, z), 0.14))
            parts.append(tube("PaintBlue", (-size, (i - 1) * size, z), (size, (i - 1) * size, z), 0.14))
    parts.append(box("WoodLight", (size * 2, size * 2, 0.25), (0, 0, size + 0.1)))  # platform
    # slide off the front
    slide = box("PaintRed", (2.2, 7, 0.2), (size + 3.0, 0, size * 0.55), rotation=(0, math.radians(30), math.radians(90)))
    parts.append(slide)
    return join("JungleGym", parts)


# --- texturing -----------------------------------------------------------------------------------
def atlas_material():
    mat = bpy.data.materials.get("ParkAtlas") or bpy.data.materials.new("ParkAtlas")
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = next(n for n in nodes if n.type == "BSDF_PRINCIPLED")
    tex = next((n for n in nodes if n.type == "TEX_IMAGE"), None) or nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(ROOT + r"\ParkAtlas.png", check_existing=True)
    mat.node_tree.links.new(tex.outputs[0], bsdf.inputs[0])
    bsdf.inputs["Roughness"].default_value = 0.85
    return mat


def bake_uvs(obj, atlas):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(60), island_margin=0.02)
    bpy.ops.object.mode_set(mode="OBJECT")
    mesh = obj.data
    uv = mesh.uv_layers.active.data
    names = [m.name for m in mesh.materials]
    span = (1 - 2 * MARGIN) / GRID
    for poly in mesh.polygons:
        index = CELLS.index(names[poly.material_index])
        row, col = divmod(index, GRID)
        u0, v0 = col / GRID + MARGIN / GRID, 1 - (row + 1) / GRID + MARGIN / GRID
        for li in poly.loop_indices:
            u, v = uv[li].uv
            uv[li].uv = (u0 + u * span, v0 + v * span)
    mesh.materials.clear()
    mesh.materials.append(atlas)


BUILDERS = [oak_tree, fir_tree, bush, flower_patch, bench, picnic_table, lamp, swing_set, jungle_gym]
atlas = atlas_material()
props = []
for i, build in enumerate(BUILDERS):
    obj = build()
    bake_uvs(obj, atlas)
    obj.location = (i * 22, 0, 0)  # spread out for previews; Roblox re-pivots each one
    props.append(obj)

bpy.ops.object.select_all(action="DESELECT")
for p in props:
    p.select_set(True)
bpy.ops.export_scene.fbx(filepath=ROOT + r"\ParkProps.fbx", use_selection=True, object_types={"MESH"},
                         path_mode="COPY", embed_textures=True, apply_unit_scale=True)
bpy.ops.wm.save_as_mainfile(filepath=ROOT + r"\ParkProps.blend", copy=True)
print("built", [p.name for p in props])
