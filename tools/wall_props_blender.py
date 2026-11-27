"""Builds and bakes the brick wall pieces (run inside Blender: exec(open(path).read())).
BrickWall = one wall section with a stone coping on top; BrickColumn = a brick pillar with a
stone cap, set between wall sections. Same pipeline as the other props (blender_props_lib.py).
Writes assets/models/walls/WallProps.fbx and <Prop>_Color/_Normal.png.
"""
import os
import random

TOOLS = r"C:\Users\kgkan\Documents\GitHub\Ragdoll Biker 💀🦴\tools"
ROOT = r"C:\Users\kgkan\Documents\GitHub\Ragdoll Biker 💀🦴\assets\models\walls"
SRC = ROOT
os.makedirs(ROOT, exist_ok=True)
exec(open(os.path.join(TOOLS, "blender_props_lib.py"), encoding="utf-8").read())
reset_scene()
random.seed(41)


def brick():
    """Red bricks in a running bond with recessed light mortar and colour variation per brick."""
    def build(g):
        co = g.coords((1, 1, 1))
        # the brick node is flat (uses x, y): feed it (x, z) on front/back faces and (y, z) on the
        # ends, picked by which way the face points, so courses always run horizontally
        sep = g.add("ShaderNodeSeparateXYZ")
        g.link(co[0], co[1], sep, 0)
        front = g.add("ShaderNodeCombineXYZ")
        g.link(sep, "X", front, "X")
        g.link(sep, "Z", front, "Y")
        side = g.add("ShaderNodeCombineXYZ")
        g.link(sep, "Y", side, "X")
        g.link(sep, "Z", side, "Y")
        geo = g.add("ShaderNodeNewGeometry")
        nsep = g.add("ShaderNodeSeparateXYZ")
        g.link(geo, "Normal", nsep, 0)
        pick = g.math("GREATER_THAN", g.math("ABSOLUTE", (nsep, "X")), 0.5)
        chooser = g.add("ShaderNodeMix", data_type="VECTOR")
        g.link(pick[0], pick[1], chooser, 0)
        g.link(front, 0, chooser, 4)
        g.link(side, 0, chooser, 5)
        bricks = g.add("ShaderNodeTexBrick")
        bricks.inputs["Color1"].default_value = (0.55, 0.2, 0.13, 1)
        bricks.inputs["Color2"].default_value = (0.42, 0.14, 0.09, 1)
        bricks.inputs["Mortar"].default_value = (0.72, 0.7, 0.65, 1)
        bricks.inputs["Scale"].default_value = 1.6
        bricks.inputs["Mortar Size"].default_value = 0.035
        bricks.inputs["Brick Width"].default_value = 0.75
        bricks.inputs["Row Height"].default_value = 0.28
        bricks.inputs["Bias"].default_value = 0.1
        g.link(chooser, 1, bricks, "Vector")
        grime = g.add("ShaderNodeTexNoise")
        grime.inputs["Scale"].default_value = 2.5
        grime.inputs["Detail"].default_value = 6.0
        g.link(co[0], co[1], grime, "Vector")
        pores = g.add("ShaderNodeTexNoise")
        pores.inputs["Scale"].default_value = 30.0
        g.link(co[0], co[1], pores, "Vector")
        col = g.mix(g.math("MULTIPLY", (grime, "Fac"), 0.35), (bricks, "Color"), (0.3, 0.12, 0.08))
        col = g.mix(g.math("MULTIPLY", (pores, "Fac"), 0.25), col, (0.75, 0.45, 0.35))
        height = g.math("SUBTRACT", 1.0, (bricks, "Fac"))  # mortar (Fac 1) sits lower
        g.finish(shaded(g, col, ao_distance=1.0, edge=0.2, edge_colour=(0.85, 0.55, 0.45)), height=height, bump=0.6, roughness=0.9, bevel=0.05)
    return material("Brick", build)


def coping_stone():
    def build(g):
        noise = g.add("ShaderNodeTexNoise")
        noise.inputs["Scale"].default_value = 12.0
        noise.inputs["Detail"].default_value = 5.0
        col = g.ramp((noise, "Fac"), [(0.35, (0.55, 0.53, 0.5)), (0.7, (0.78, 0.76, 0.72))])
        g.finish(shaded(g, col, edge=0.3, edge_colour=(0.92, 0.9, 0.86)), height=(noise, "Fac"), bump=0.3, roughness=0.85, bevel=0.06)
    return material("CopingStone", build)


def brick_wall():
    length, height, thick = 12, 7, 1.6
    parts = [box(brick(), (length, thick, height), (0, 0, height / 2))]
    parts.append(box(coping_stone(), (length + 0.1, thick + 0.5, 0.45), (0, 0, height + 0.22)))
    return join("BrickWall", parts)


def brick_column():
    size, height = 2.6, 8.6
    parts = [box(brick(), (size, size, height), (0, 0, height / 2))]
    parts.append(box(coping_stone(), (size + 0.6, size + 0.6, 0.5), (0, 0, height + 0.25)))
    parts.append(box(coping_stone(), (size * 0.6, size * 0.6, 0.6), (0, 0, height + 0.8)))
    parts.append(box(coping_stone(), (size + 0.3, size + 0.3, 0.4), (0, 0, 0.2)))  # plinth
    return join("BrickColumn", parts)


bake_all([(brick_wall, 1024, False), (brick_column, 512, False)], "WallProps.fbx")
