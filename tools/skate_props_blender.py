"""Builds and bakes the Skate Park props (run inside Blender: exec(open(path).read())).
Same pipeline as the park props (tools/blender_props_lib.py): real materials, baked per prop.
Ramps rise towards +Y (Blender +Y becomes Roblox +Z, which is downhill on the maps).
Writes assets/models/skate/SkateProps.fbx and <Prop>_Color/_Normal.png.
"""
import math
import os
import random

import bmesh

TOOLS = r"C:\Users\kgkan\Documents\GitHub\Ragdoll Biker 💀🦴\tools"
ROOT = r"C:\Users\kgkan\Documents\GitHub\Ragdoll Biker 💀🦴\assets\models\skate"
SRC = os.path.join(ROOT, "src")
exec(open(os.path.join(TOOLS, "blender_props_lib.py"), encoding="utf-8").read())
reset_scene()
random.seed(23)


# --- skate materials ---------------------------------------------------------------------------------
def concrete(name="Concrete", tone=(0.62, 0.62, 0.6)):
    def build(g):
        co = g.coords((1, 1, 1))
        stains = g.add("ShaderNodeTexNoise")
        stains.inputs["Scale"].default_value = 0.35
        stains.inputs["Detail"].default_value = 6.0
        g.link(co[0], co[1], stains, "Vector")
        speckle = g.add("ShaderNodeTexNoise")
        speckle.inputs["Scale"].default_value = 45.0
        speckle.inputs["Detail"].default_value = 2.0
        g.link(co[0], co[1], speckle, "Vector")
        # hairline cracks: big wobbly cells, only a thin faint line at their edges
        warp = g.add("ShaderNodeTexNoise")
        warp.inputs["Scale"].default_value = 0.8
        g.link(co[0], co[1], warp, "Vector")
        warped = g.add("ShaderNodeMix", data_type="VECTOR")
        warped.inputs[0].default_value = 0.25
        g.link(co[0], co[1], warped, 4)
        g.link(warp, "Color", warped, 5)
        cracks = g.add("ShaderNodeTexVoronoi", feature="DISTANCE_TO_EDGE")
        cracks.inputs["Scale"].default_value = 0.07
        g.link(warped, 1, cracks, "Vector")
        crack_line = g.math("MULTIPLY", g.math("LESS_THAN", (cracks, "Distance"), 0.004), (stains, "Fac"))
        base = g.ramp((stains, "Fac"), [(0.3, tuple(c * 0.82 for c in tone)), (0.7, tuple(min(1, c * 1.06) for c in tone))])
        speckled = g.mix(g.math("MULTIPLY", (speckle, "Fac"), 0.35), base, tuple(c * 0.7 for c in tone))
        cracked = g.mix(g.math("MULTIPLY", crack_line, 0.45), speckled, (0.3, 0.3, 0.3))
        height = g.math("SUBTRACT", g.math("MULTIPLY", (speckle, "Fac"), 0.4), g.math("MULTIPLY", crack_line, 0.6))
        g.finish(shaded(g, cracked, ao_distance=1.5, edge=0.18, edge_colour=tuple(min(1, c * 1.25) for c in tone)), height=height, bump=0.25, roughness=0.9, bevel=0.06)
    return material(name, build)


def diamond_plate():
    """Steel tread plate: raised diamonds, worn bright edges."""
    def build(g):
        co = g.coords((2.2, 2.2, 2.2))
        rot = g.add("ShaderNodeMapping")
        rot.inputs["Rotation"].default_value = (0, 0, math.radians(45))
        rot.inputs["Scale"].default_value = (1, 3, 1)
        g.link(co[0], co[1], rot, 0)
        bricks = g.add("ShaderNodeTexBrick")
        bricks.inputs["Mortar Size"].default_value = 0.35
        bricks.inputs["Scale"].default_value = 1.0
        g.link(rot, 0, bricks, "Vector")
        studs = g.math("SUBTRACT", 1.0, (bricks, "Fac"))
        base = g.mix(g.math("MULTIPLY", studs, 0.5), (0.36, 0.37, 0.4), (0.7, 0.72, 0.76))
        lit = g.mix(g.math("MULTIPLY", g.edge_mask(0.04, 14), 0.8), base, (0.9, 0.92, 0.95))
        g.finish(shaded(g, lit), height=studs, bump=0.6, roughness=0.35, bevel=0.03)
    return material("TreadPlate", build)


def chain_link_mesh():
    def build(g):
        uv = g.add("ShaderNodeUVMap", uv_map="UVMap")
        mp = g.add("ShaderNodeMapping")
        mp.inputs["Scale"].default_value = (6, 3.5, 1)  # about one diamond per 2 studs
        g.link(uv, 0, mp, 0)
        tex = g.add("ShaderNodeTexImage")
        tex.image = image("ChainLink.png")
        g.link(mp, 0, tex, "Vector")
        g.finish((tex, 0), roughness=0.4, alpha=(tex, 1), bevel=0.01)
    return material("ChainLink", build)


def steel():
    return iron("Steel", (0.42, 0.44, 0.48))


# --- shapes ------------------------------------------------------------------------------------------
def extrude_profile(mat, name, profile, width):
    """A solid from a closed (y, z) profile, extruded along X (centred)."""
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    left = [bm.verts.new((-width / 2, y, z)) for y, z in profile]
    right = [bm.verts.new((width / 2, y, z)) for y, z in profile]
    bm.faces.new(list(reversed(left)))
    bm.faces.new(right)
    n = len(profile)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((left[i], left[j], right[j], right[i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    mesh.uv_layers.new(name="UVMap")
    obj.data.materials.append(mat)
    return obj


def curve_profile(radius, height, deck, back_drop=True, steps=10):
    """Quarter-pipe style transition rising towards +Y, with a flat deck on top."""
    top = math.acos(1 - height / radius)
    pts = [(0.0, 0.0)]
    for i in range(1, steps + 1):
        t = top * i / steps
        pts.append((radius * math.sin(t), radius * (1 - math.cos(t))))
    lip_y = pts[-1][0]  # where the curve meets the deck (the coping goes here)
    pts.append((lip_y + deck, height))
    pts.append((lip_y + deck, 0.0))
    return pts, lip_y


def bump_mesh(mat, size, height, steps=18):
    """Smooth concrete mound (hip/speed bump) that rises out of the ground."""
    mesh = bpy.data.meshes.new("Bump")
    bm = bmesh.new()
    grid = {}
    for i in range(steps + 1):
        for j in range(steps + 1):
            u, v = i / steps * 2 - 1, j / steps * 2 - 1
            r = min(1.0, math.sqrt(u * u + v * v))
            z = height * math.cos(r * math.pi / 2) ** 2 if r < 1 else 0.0
            grid[i, j] = bm.verts.new((u * size[0] / 2, v * size[1] / 2, z))
    for i in range(steps):
        for j in range(steps):
            bm.faces.new((grid[i, j], grid[i + 1, j], grid[i + 1, j + 1], grid[i, j + 1]))
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new("Bump", mesh)
    bpy.context.scene.collection.objects.link(obj)
    mesh.uv_layers.new(name="UVMap")
    obj.data.materials.append(mat)
    return obj


# --- props -------------------------------------------------------------------------------------------
def quarter_pipe():
    width, radius, height = 18, 8, 6
    profile, lip_y = curve_profile(radius, height, deck=3.5)
    parts = [extrude_profile(concrete(), "QP", profile, width)]
    parts.append(tube(steel(), (-width / 2, lip_y, height + 0.15), (width / 2, lip_y, height + 0.15), 0.25, sides=10))  # coping
    return join("QuarterPipe", parts)


def launch_ramp():
    width, radius, height = 12, 12, 4.5
    profile, lip_y = curve_profile(radius, height, deck=0.4)
    parts = [extrude_profile(concrete("ConcreteRamp", (0.66, 0.65, 0.62)), "Kicker", profile, width)]
    parts.append(box(diamond_plate(), (width, 2.4, 0.12), (0, 0.6, 0.06)))  # metal plate at the bottom
    parts.append(tube(steel(), (-width / 2, lip_y, height + 0.12), (width / 2, lip_y, height + 0.12), 0.2, sides=10))
    return join("SkateLaunchRamp", parts)


def jump_box():
    plank = wood("WoodDeck", (0.66, 0.46, 0.27), (0.38, 0.24, 0.13), grain_scale=3.0)
    side = wood("WoodSide", (0.5, 0.34, 0.2), (0.28, 0.17, 0.09))
    width, height, run, top = 12, 3, 7, 8
    parts = [
        extrude_profile(plank, "Up", [(-top / 2 - run, 0), (-top / 2, height), (-top / 2, 0)], width),
        extrude_profile(plank, "Down", [(top / 2, 0), (top / 2, height), (top / 2 + run, 0)], width),
        box(plank, (width, top, 0.3), (0, 0, height - 0.15)),
        box(side, (width - 0.2, top, height - 0.3), (0, 0, (height - 0.3) / 2)),
    ]
    for x in (-width / 2, width / 2):  # side trim boards
        parts.append(box(side, (0.25, top + 2 * run * 0.9, 0.35), (x, 0, 0.2)))
    return join("JumpBox", parts)


def grind_box():
    length, width, height = 14, 2.6, 1.8
    parts = [box(concrete("ConcreteBox", (0.6, 0.6, 0.58)), (length, width, height), (0, 0, height / 2))]
    for s in (-1, 1):  # steel L-angle on both top edges
        parts.append(box(steel(), (length + 0.1, 0.55, 0.09), (0, s * (width / 2 - 0.25), height + 0.045)))
        parts.append(box(steel(), (length + 0.1, 0.09, 0.55), (0, s * (width / 2 + 0.045), height - 0.23)))
    return join("GrindBox", parts)


def grind_rail():
    rail = painted_metal("RailPaint", (0.95, 0.72, 0.15))
    length, h = 16, 1.7
    parts = [tube(rail, (-length / 2, 0, h), (length / 2, 0, h), 0.2, sides=12)]
    for x in (-length / 2 + 1, 0, length / 2 - 1):
        parts.append(box(rail, (0.3, 0.3, h - 0.2), (x, 0, (h - 0.2) / 2)))
        parts.append(box(steel(), (1.4, 1.0, 0.12), (x, 0, 0.06)))  # base plate
    return join("GrindRail", parts)


def hip_bump():
    return join("HipBump", [bump_mesh(concrete("ConcreteBump", (0.64, 0.63, 0.6)), (16, 12), 2.4)])


def skate_bench():
    plank = wood("WoodDeck", (0.66, 0.46, 0.27), (0.38, 0.24, 0.13), grain_scale=3.0)
    parts = []
    for x in (-3, 3):
        parts.append(box(concrete("ConcreteBench", (0.58, 0.58, 0.56)), (1.2, 2.2, 1.9), (x, 0, 0.95)))
    for y in (-0.75, 0, 0.75):
        parts.append(box(plank, (8.4, 0.62, 0.28), (0, y, 2.0)))
    return join("SkateBench", parts)


def chain_fence():
    length, height = 12, 7
    parts = []
    for x in (-length / 2, length / 2):
        parts.append(cylinder(steel(), 0.18, height + 0.4, (x, 0, (height + 0.4) / 2), sides=8))
    parts.append(tube(steel(), (-length / 2, 0, height), (length / 2, 0, height), 0.12, sides=8))
    bpy.ops.mesh.primitive_plane_add(size=1, location=(0, 0, height / 2), rotation=(math.pi / 2, 0, 0))
    mesh_card = bpy.context.object  # upright wire panel between the posts
    mesh_card.scale = (length, height, 1)
    mesh_card.data.materials.append(chain_link_mesh())
    parts.append(mesh_card)
    return join("ChainLinkFence", parts)


PROPS = [  # builder, texture size, has alpha cards
    (quarter_pipe, 1024, False), (launch_ramp, 1024, False), (jump_box, 1024, False), (grind_box, 512, False),
    (grind_rail, 512, False), (hip_bump, 1024, False), (skate_bench, 512, False), (chain_fence, 512, True),
]
bake_all(PROPS, "SkateProps.fbx")
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT, "SkateProps.blend"), copy=True)
