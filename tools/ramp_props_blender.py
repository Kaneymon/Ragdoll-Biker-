"""Builds and bakes the mega ramp look (run inside Blender: exec(open(path).read())).
Chipboard  = one 16x16 stud tile of OSB panel boards (strands, board seams, screw rows), baked flat
             to Chipboard_Color.png / Chipboard_Normal.png for a Roblox MaterialVariant.
RampBarrier = a 16 stud metal barrier section (posts, rails, diamond-plate kick plate) for the
             sides of the ramps and the lobby edge. Length runs along Blender +Y (Roblox +Z).
Same pipeline as the other props (blender_props_lib.py). Writes assets/models/ramp/.
"""
import math
import os
import random

import bpy

TOOLS = r"C:\Users\kgkan\Documents\GitHub\Ragdoll Biker 💀🦴\tools"
ROOT = r"C:\Users\kgkan\Documents\GitHub\Ragdoll Biker 💀🦴\assets\models\ramp"
SRC = ROOT
os.makedirs(ROOT, exist_ok=True)
exec(open(os.path.join(TOOLS, "blender_props_lib.py"), encoding="utf-8").read())
reset_scene()
random.seed(61)

TILE = 16.0  # studs per texture tile (MaterialVariant.StudsPerTile)
BOARD = 8.0  # board width; boards are 16 long, rows staggered by half a board


# --- chipboard --------------------------------------------------------------------------------------
def strand_layer(g, co, angle, seed):
    """Random-toned stretched flakes at one orientation: returns (tone socket, edge socket)."""
    rot = g.add("ShaderNodeMapping")
    rot.inputs["Rotation"].default_value = (0, 0, angle)
    rot.inputs["Scale"].default_value = (2.4, 0.55, 1)  # long thin strands
    rot.inputs["Location"].default_value = (seed * 3.1, seed * 1.7, seed)
    g.link(co[0], co[1], rot, 0)
    cells = g.add("ShaderNodeTexVoronoi", feature="F1")
    cells.inputs["Scale"].default_value = 1.6
    cells.inputs["Randomness"].default_value = 0.9
    g.link(rot, 0, cells, "Vector")
    edges = g.add("ShaderNodeTexVoronoi", feature="DISTANCE_TO_EDGE")
    edges.inputs["Scale"].default_value = 1.6
    edges.inputs["Randomness"].default_value = 0.9
    g.link(rot, 0, edges, "Vector")
    tone = g.add("ShaderNodeSeparateColor")
    g.link(cells, "Color", tone, 0)
    return (tone, 0), (edges, "Distance")


def seam_mask(g, co):
    """1 on the gaps between boards (vertical every BOARD, horizontal every TILE, staggered)."""
    sep = g.add("ShaderNodeSeparateXYZ")
    g.link(co[0], co[1], sep, 0)
    # across: board edges every BOARD studs
    fx = g.math("PINGPONG", (sep, "X"), BOARD / 2)  # distance to the nearest board edge
    across = g.math("LESS_THAN", fx, 0.05)
    # along: board ends every TILE studs, the second column of boards offset by half
    column = g.math("FLOOR", g.math("DIVIDE", (sep, "X"), BOARD))
    shift = g.math("MULTIPLY", g.math("MODULO", column, 2), TILE / 2)
    fy = g.math("PINGPONG", g.math("ADD", (sep, "Y"), shift), TILE / 2)
    along = g.math("LESS_THAN", fy, 0.05)
    lines = g.math("MAXIMUM", across, along)
    # screw heads in a row 0.35 in from every board edge, one per stud
    sx = g.math("PINGPONG", (sep, "X"), BOARD / 2)
    near_edge = g.math("LESS_THAN", g.math("ABSOLUTE", g.math("SUBTRACT", sx, 0.35)), 0.08)
    per_stud = g.math("LESS_THAN", g.math("ABSOLUTE", g.math("SUBTRACT", g.math("FRACT", (sep, "Y")), 0.5)), 0.08)
    screws = g.math("MULTIPLY", near_edge, per_stud)
    return lines, screws


def chipboard():
    def build(g):
        co = g.coords((1, 1, 1))
        tones, edges = [], []
        for k, angle in enumerate((0.15, 1.25, 2.3, 0.7)):
            t, e = strand_layer(g, co, angle, k + 1)
            tones.append(t)
            edges.append(e)
        # stack the layers: a noise picks which flake is on top at each spot
        picker = g.add("ShaderNodeTexNoise")
        picker.inputs["Scale"].default_value = 3.0
        picker.inputs["Detail"].default_value = 2.0
        g.link(co[0], co[1], picker, "Vector")
        pick = (picker, "Fac")
        tone, edge = tones[0], edges[0]
        for i in range(1, len(tones)):
            lo, hi = 0.3 + 0.12 * i, 0.38 + 0.12 * i
            m = g.math("GREATER_THAN", pick, lo + random.uniform(-0.04, 0.04))
            m = g.math("MULTIPLY", m, g.math("LESS_THAN", pick, hi + 0.25))
            tone = (g.mix(m, tone, tones[i])[0], 2)
            edge = (g.mix(m, edge, edges[i])[0], 2)
        sep = g.add("ShaderNodeSeparateColor")
        g.link(tone[0], tone[1], sep, 0)
        tone_v = (sep, 0)
        esep = g.add("ShaderNodeSeparateColor")
        g.link(edge[0], edge[1], esep, 0)
        flake_edge = g.math("LESS_THAN", (esep, 0), 0.035)
        col = g.ramp(tone_v, [(0.0, (0.36, 0.24, 0.12)), (0.35, (0.6, 0.45, 0.25)), (0.7, (0.74, 0.6, 0.38)), (1.0, (0.85, 0.72, 0.5))])
        col = g.mix(g.math("MULTIPLY", flake_edge, 0.35), col, (0.3, 0.2, 0.1))
        dirt = g.add("ShaderNodeTexNoise")
        dirt.inputs["Scale"].default_value = 0.35
        dirt.inputs["Detail"].default_value = 6.0
        g.link(co[0], co[1], dirt, "Vector")
        col = g.mix(g.math("MULTIPLY", g.math("SUBTRACT", (dirt, "Fac"), 0.45, clamp=True), 0.9), col, (0.42, 0.32, 0.2))
        lines, screws = seam_mask(g, co)
        col = g.mix(lines, col, (0.12, 0.08, 0.05))
        col = g.mix(screws, col, (0.55, 0.56, 0.58))
        height = g.math("SUBTRACT", g.math("MULTIPLY", tone_v, 0.25), g.math("ADD", g.math("MULTIPLY", flake_edge, 0.15), g.math("MULTIPLY", lines, 1.0)))
        g.finish(col, height=height, bump=0.6, roughness=0.85, bevel=0.0)
    return material("Chipboard", build)


def bake_tile():
    bpy.ops.mesh.primitive_plane_add(size=TILE, location=(TILE / 2, TILE / 2, 0))
    plane = bpy.context.object
    plane.name = "Chipboard"
    bpy.ops.object.transform_apply(location=True)
    plane.data.materials.append(chipboard())
    for kind, space in (("Color", "sRGB"), ("Normal", "Non-Color")):
        img = bake(plane, kind, 1024, space)
        save_png(img, os.path.join(ROOT, f"Chipboard_{kind}.png"))
    bpy.data.objects.remove(plane, do_unlink=True)
    print("baked Chipboard tile")


# --- metal barrier -----------------------------------------------------------------------------------
def galvanised():
    def build(g):
        mask = g.edge_mask(0.05, 14)
        spangle = g.add("ShaderNodeTexVoronoi", feature="F1")
        spangle.inputs["Scale"].default_value = 9.0
        co = g.coords((1, 1, 1))
        g.link(co[0], co[1], spangle, "Vector")
        sp = g.add("ShaderNodeSeparateColor")
        g.link(spangle, "Color", sp, 0)
        streak = g.add("ShaderNodeTexNoise")
        streak.inputs["Scale"].default_value = 30.0
        g.link(g.coords((1, 1, 10))[0], 0, streak, "Vector")
        base = g.ramp(g.math("ADD", g.math("MULTIPLY", (sp, 0), 0.5), g.math("MULTIPLY", (streak, "Fac"), 0.5)),
                      [(0.25, (0.38, 0.4, 0.42)), (0.6, (0.55, 0.57, 0.6)), (0.85, (0.66, 0.68, 0.7))])
        grime = g.add("ShaderNodeTexNoise")
        grime.inputs["Scale"].default_value = 2.0
        grime.inputs["Detail"].default_value = 6.0
        g.link(co[0], co[1], grime, "Vector")
        base = g.mix(g.math("MULTIPLY", g.math("SUBTRACT", (grime, "Fac"), 0.55, clamp=True), 1.2), base, (0.25, 0.24, 0.22))
        lit = g.mix(g.math("MULTIPLY", mask, 0.7), base, (0.9, 0.92, 0.95))
        g.finish(shaded(g, lit, ao_distance=0.8), roughness=0.4, bevel=0.03)
    return material("Galvanised", build)


def diamond_plate():
    def build(g):
        co = g.coords((1, 1, 1))
        sep = g.add("ShaderNodeSeparateXYZ")
        g.link(co[0], co[1], sep, 0)
        a = g.math("ADD", (sep, "Y"), (sep, "Z"))
        b = g.math("SUBTRACT", (sep, "Y"), (sep, "Z"))
        wa = g.math("PINGPONG", g.math("MULTIPLY", a, 2.2), 0.5)
        wb = g.math("PINGPONG", g.math("MULTIPLY", b, 6.0), 0.5)
        lozenge = g.math("MULTIPLY", g.math("LESS_THAN", wa, 0.12), g.math("LESS_THAN", wb, 0.35))
        noise = g.add("ShaderNodeTexNoise")
        noise.inputs["Scale"].default_value = 12.0
        g.link(co[0], co[1], noise, "Vector")
        base = g.ramp((noise, "Fac"), [(0.3, (0.42, 0.44, 0.47)), (0.7, (0.6, 0.62, 0.65))])
        col = g.mix(g.math("MULTIPLY", lozenge, 0.6), base, (0.82, 0.84, 0.87))
        mask = g.edge_mask(0.04, 14)
        col = g.mix(g.math("MULTIPLY", mask, 0.6), col, (0.92, 0.93, 0.95))
        g.finish(shaded(g, col, ao_distance=0.6), height=lozenge, bump=0.5, roughness=0.35, bevel=0.03)
    return material("DiamondPlate", build)


def ramp_barrier():
    metal, plate = galvanised(), diamond_plate()
    length, height = 16.0, 3.6
    parts = []
    for y in (-length / 2 + 0.25, length / 2 - 0.25):
        parts.append(box(metal, (0.4, 0.4, height), (0, y, height / 2)))  # post
        parts.append(box(metal, (0.9, 0.9, 0.1), (0, y, 0.05)))  # base flange
        parts.append(cylinder(metal, 0.26, 0.12, (0, y, height + 0.06)))  # post cap
    parts.append(cylinder(metal, 0.17, length, (0, 0, height - 0.1), rotation=(math.pi / 2, 0, 0), sides=10))  # top rail
    parts.append(cylinder(metal, 0.12, length, (0, 0, 2.2), rotation=(math.pi / 2, 0, 0), sides=10))  # mid rail
    parts.append(box(plate, (0.12, length, 1.1), (0, 0, 0.65)))  # kick plate
    for y in (-length / 4, 0, length / 4):  # balusters
        parts.append(box(metal, (0.12, 0.12, 2.1), (0, y, 2.15)))
    return join("RampBarrier", parts)


bake_tile()
bake_all([(ramp_barrier, 1024, False)], "RampProps.fbx")
