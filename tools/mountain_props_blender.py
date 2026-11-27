"""Builds and bakes the Mountain props (run inside Blender: exec(open(path).read())).
Boulder = a chunky low-poly rock with layered stone, cracks, lichen and worn bright edges.
Same pipeline as the other props (blender_props_lib.py). Writes assets/models/mountain/MountainProps.fbx.
"""
import os
import random

TOOLS = r"C:\Users\kgkan\Documents\GitHub\Ragdoll Biker 💀🦴\tools"
ROOT = r"C:\Users\kgkan\Documents\GitHub\Ragdoll Biker 💀🦴\assets\models\mountain"
SRC = ROOT
os.makedirs(ROOT, exist_ok=True)
exec(open(os.path.join(TOOLS, "blender_props_lib.py"), encoding="utf-8").read())
reset_scene()
random.seed(53)


def stone():
    def build(g):
        co = g.coords((0.6, 0.6, 0.6))
        body = g.add("ShaderNodeTexNoise")
        body.inputs["Scale"].default_value = 1.6
        body.inputs["Detail"].default_value = 8.0
        body.inputs["Roughness"].default_value = 0.6
        g.link(co[0], co[1], body, "Vector")
        strata = g.add("ShaderNodeTexWave", wave_type="BANDS", bands_direction="Z")
        strata.inputs["Scale"].default_value = 0.45
        strata.inputs["Distortion"].default_value = 6.0
        strata.inputs["Detail"].default_value = 4.0
        g.link(co[0], co[1], strata, "Vector")
        warp = g.add("ShaderNodeMix", data_type="VECTOR")  # wobble the crack cells so they look natural
        warp.inputs[0].default_value = 0.35
        g.link(co[0], co[1], warp, 4)
        g.link(body, "Color", warp, 5)
        cracks = g.add("ShaderNodeTexVoronoi", feature="DISTANCE_TO_EDGE")
        cracks.inputs["Scale"].default_value = 0.7
        g.link(warp, 1, cracks, "Vector")
        crack = g.math("MULTIPLY", g.math("LESS_THAN", (cracks, "Distance"), 0.01), g.math("GREATER_THAN", (body, "Fac"), 0.45))
        lichen_noise = g.add("ShaderNodeTexNoise")
        lichen_noise.inputs["Scale"].default_value = 4.0
        lichen_noise.inputs["Detail"].default_value = 6.0
        g.link(co[0], co[1], lichen_noise, "Vector")
        geo = g.add("ShaderNodeNewGeometry")
        up = g.add("ShaderNodeSeparateXYZ")
        g.link(geo, "Normal", up, 0)
        lichen = g.math("MULTIPLY", g.math("GREATER_THAN", (lichen_noise, "Fac"), 0.58), g.math("GREATER_THAN", (up, "Z"), 0.55))
        tone = g.math("ADD", g.math("MULTIPLY", (body, "Fac"), 0.85), g.math("MULTIPLY", (strata, "Fac"), 0.12))
        col = g.ramp(tone, [(0.3, (0.07, 0.07, 0.075)), (0.5, (0.17, 0.165, 0.16)), (0.7, (0.3, 0.28, 0.25))])
        col = g.mix(g.math("MULTIPLY", crack, 0.6), col, (0.06, 0.06, 0.07))
        col = g.mix(g.math("MULTIPLY", lichen, 0.7), col, (0.34, 0.4, 0.2))
        height = g.math("SUBTRACT", tone, g.math("MULTIPLY", crack, 0.5))
        g.finish(shaded(g, col, ao_distance=2.0, edge=0.2, edge_colour=(0.42, 0.4, 0.37)), height=height, bump=0.9, roughness=0.92, bevel=0.15)
    return material("Stone", build)


def boulder():
    rock = blob(stone(), 4.0, (0, 0, 2.2), squash=0.6, jitter=0.32, subdivisions=2)
    for v in rock.data.vertices:  # flat-ish base so it sits on the ground
        if v.co.z < -1.0:
            v.co.z = -1.0 - (v.co.z + 1.0) * 0.15
    side = blob(stone(), 2.4, (2.8, 1.0, 1.2), squash=0.7, jitter=0.3, subdivisions=1)
    return join("Boulder", [rock, side])


bake_all([(boulder, 1024, False)], "MountainProps.fbx")
