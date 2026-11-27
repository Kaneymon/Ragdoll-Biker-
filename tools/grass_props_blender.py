"""Builds and bakes the grass clump prop (run inside Blender: exec(open(path).read())).
Crossed upright cards with the painted grass-blade texture (tools/park_textures.py), baked with
alpha like the leaf cards. Writes assets/models/park/GrassClump.fbx and GrassClump_Color/_Normal.png.
"""
import math
import os
import random

TOOLS = r"C:\Users\kgkan\Documents\GitHub\Ragdoll Biker 💀🦴\tools"
ROOT = r"C:\Users\kgkan\Documents\GitHub\Ragdoll Biker 💀🦴\assets\models\park"
SRC = os.path.join(ROOT, "src")
exec(open(os.path.join(TOOLS, "blender_props_lib.py"), encoding="utf-8").read())
reset_scene()
random.seed(31)


def grass_card():
    def build(g):
        uv = g.add("ShaderNodeUVMap", uv_map="UVMap")
        tex = g.add("ShaderNodeTexImage")
        tex.image = image("GrassBlades.png")
        g.link(uv, 0, tex, "Vector")
        g.finish(shaded(g, (tex, 0), ao_distance=0.8), roughness=0.75, alpha=(tex, 1), bevel=0.01)
    return material("GrassCard", build)


def grass_clump():
    parts = []
    for i in range(5):  # cards fanned round the centre, each a little different in size and lean
        angle = i * math.pi / 5 + random.uniform(-0.2, 0.2)
        width, height = random.uniform(2.6, 3.4), random.uniform(1.8, 2.6)
        bpy.ops.mesh.primitive_plane_add(size=1, location=(random.uniform(-0.3, 0.3), random.uniform(-0.3, 0.3), height / 2), rotation=(math.pi / 2 + random.uniform(-0.15, 0.15), 0, angle))
        card_obj = bpy.context.object
        card_obj.scale = (width, height, 1)
        card_obj.data.materials.append(grass_card())
        parts.append(card_obj)
    return join("GrassClump", parts)


bake_all([(grass_clump, 512, True)], "GrassClump.fbx")
