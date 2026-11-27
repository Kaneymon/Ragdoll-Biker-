"""Builds and bakes the low-poly park props (run inside Blender: exec(open(path).read())).
Materials, primitives and baking come from tools/blender_props_lib.py; the painted source
textures from tools/park_textures.py (assets/models/park/src).
Writes assets/models/park/ParkProps.fbx and <Prop>_Color/_Normal.png.
"""
import os
import random

TOOLS = r"C:\Users\kgkan\Documents\GitHub\Ragdoll Biker 💀🦴\tools"
ROOT = r"C:\Users\kgkan\Documents\GitHub\Ragdoll Biker 💀🦴\assets\models\park"
SRC = os.path.join(ROOT, "src")
exec(open(os.path.join(TOOLS, "blender_props_lib.py"), encoding="utf-8").read())
reset_scene()
random.seed(11)


# --- props -----------------------------------------------------------------------------------------
def oak_tree():
    parts = [cylinder(bark(), 1.3, 10, (0, 0, 5), radius2=0.8, sides=9)]
    parts.append(tube(bark(), (0, 0, 7), (2.4, 0.5, 10), 0.45))
    parts.append(tube(bark(), (0, 0, 7.5), (-2, -0.8, 10.5), 0.4))
    parts += leafy([(0, 0, 13, 5.2), (2.8, 0.6, 11.5, 3.8), (-2.6, -0.9, 12, 4.0), (0.4, 2.2, 15, 3.4)], leaves(), leaf_card(), 9, 3.6)
    return join("OakTree", parts)


def fir_tree():
    parts = [cylinder(bark(), 0.9, 4, (0, 0, 2), radius2=0.7, sides=8)]
    for z, r, h in [(6, 5.2, 7), (10, 4, 6), (13.5, 2.8, 5), (16.3, 1.6, 3.6)]:
        parts.append(cone(fir(), r, h, (0, 0, z), sides=14, jag=0.9))
    return join("FirTree", parts)


def bush():
    parts = leafy([(0, 0, 1.6, 2.1), (1.6, 0.4, 1.3, 1.6), (-1.4, -0.6, 1.2, 1.4), (0.3, -1.4, 1.1, 1.2)], leaves(), leaf_card(), 6, 1.8)
    return join("Bush", parts)


PETALS = [("PetalPink", (0.98, 0.45, 0.68)), ("PetalPurple", (0.62, 0.42, 0.95)), ("PetalYellow", (1.0, 0.82, 0.25))]


def flower(x, y, petal_mat, height):
    stem = plain("Stem", (0.2, 0.5, 0.18))
    parts = [tube(stem, (x, y, 0), (x, y, height), 0.07, sides=5)]
    for i in range(5):
        a = i * math.tau / 5
        parts.append(blob(petal_mat, 0.32, (x + math.cos(a) * 0.35, y + math.sin(a) * 0.35, height), squash=0.45, jitter=0.05, subdivisions=1))
    parts.append(blob(plain("FlowerCentre", (0.95, 0.75, 0.2)), 0.2, (x, y, height + 0.06), squash=0.6, jitter=0, subdivisions=1))
    parts.append(blob(stem, 0.35, (x + 0.25, y, height * 0.4), squash=0.35, jitter=0, subdivisions=1))
    return parts


def flower_patch():
    parts = []
    for i in range(9):
        name, colour = PETALS[i % 3]
        parts += flower(random.uniform(-2.2, 2.2), random.uniform(-2.2, 2.2), petal(name, colour), random.uniform(0.9, 1.6))
    return join("FlowerPatch", parts)


def bench():
    plank = wood("WoodPlank", (0.62, 0.42, 0.24), (0.36, 0.22, 0.12))
    frame = iron()
    parts = []
    for y in (-0.5, 0, 0.5):
        parts.append(box(plank, (6, 0.45, 0.18), (0, y, 1.9)))
    for z in (2.6, 3.2):
        parts.append(box(plank, (6, 0.16, 0.45), (0, 0.85, z), rotation=(math.radians(-12), 0, 0)))
    for x in (-2.5, 2.5):
        parts.append(box(frame, (0.25, 1.4, 0.25), (x, 0, 1.75)))
        parts.append(box(frame, (0.25, 0.25, 1.8), (x, -0.5, 0.9)))
        parts.append(box(frame, (0.25, 0.25, 3.3), (x, 0.65, 1.65), rotation=(math.radians(-10), 0, 0)))
    return join("Bench", parts)


def picnic_table():
    plank = wood("WoodPlank", (0.62, 0.42, 0.24), (0.36, 0.22, 0.12))
    legs = wood("WoodDark", (0.45, 0.3, 0.17), (0.25, 0.15, 0.08))
    parts = []
    for y in (-0.9, -0.3, 0.3, 0.9):
        parts.append(box(plank, (7, 0.55, 0.22), (0, y, 3.2)))
    for y in (-2.6, 2.6):
        for dy in (-0.3, 0.3):
            parts.append(box(plank, (7, 0.55, 0.2), (0, y + dy, 1.8)))
    for x in (-2.8, 2.8):
        for s in (-1, 1):
            parts.append(tube(legs, (x, s * 2.9, 0), (x, 0, 3.1), 0.2, sides=4))
        parts.append(box(legs, (0.3, 6, 0.3), (x, 0, 1.6)))
    return join("PicnicTable", parts)


def lamp():
    metal = iron("LampIron", (0.08, 0.09, 0.1))
    parts = [cylinder(metal, 0.6, 0.6, (0, 0, 0.3), sides=10), cylinder(metal, 0.22, 11, (0, 0, 5.8), radius2=0.16, sides=10)]
    parts.append(box(metal, (1.6, 1.6, 0.25), (0, 0, 11.4)))
    parts.append(box(glass(), (1.2, 1.2, 1.6), (0, 0, 12.4)))
    parts.append(cone(metal, 1.3, 0.9, (0, 0, 13.65), sides=4))
    for x, y in ((0.65, 0.65), (-0.65, 0.65), (0.65, -0.65), (-0.65, -0.65)):
        parts.append(box(metal, (0.15, 0.15, 1.7), (x, y, 12.4)))
    return join("Lamp", parts)


def swing_set():
    legs = painted_metal("PaintBlue", (0.2, 0.45, 0.85))
    bar = painted_metal("PaintRed", (0.85, 0.22, 0.18))
    seat = painted_metal("PaintYellow", (0.95, 0.72, 0.15))
    chain = iron("Chain", (0.3, 0.3, 0.33))
    parts = []
    w, h = 7, 9
    for x in (-w, w):
        for s in (-1, 1):
            parts.append(tube(legs, (x, s * 3, 0), (x, 0, h), 0.28))
    parts.append(tube(bar, (-w - 0.5, 0, h), (w + 0.5, 0, h), 0.34))
    for x in (-3.2, 3.2):
        for dx in (-0.8, 0.8):
            parts.append(tube(chain, (x + dx, 0, h), (x + dx, 0, 2.2), 0.06, sides=4))
        parts.append(box(seat, (2.2, 0.9, 0.2), (x, 0, 2.1)))
    return join("SwingSet", parts)


def jungle_gym():
    yellow = painted_metal("PaintYellow", (0.95, 0.72, 0.15))
    red = painted_metal("PaintRed", (0.85, 0.22, 0.18))
    blue = painted_metal("PaintBlue", (0.2, 0.45, 0.85))
    deck = wood("WoodPlank", (0.62, 0.42, 0.24), (0.36, 0.22, 0.12))
    parts = []
    size, levels = 3, 2
    for i in range(3):
        for j in range(3):
            x, y = (i - 1) * size, (j - 1) * size
            parts.append(tube((yellow, red)[(i + j) % 2], (x, y, 0), (x, y, size * levels), 0.16))
    for k in range(1, levels + 1):
        z = k * size
        for i in range(3):
            parts.append(tube(blue, ((i - 1) * size, -size, z), ((i - 1) * size, size, z), 0.14))
            parts.append(tube(blue, (-size, (i - 1) * size, z), (size, (i - 1) * size, z), 0.14))
    parts.append(box(deck, (size * 2, size * 2, 0.25), (0, 0, size + 0.1)))
    parts.append(box(red, (2.2, 7, 0.2), (size + 3.0, 0, size * 0.55), rotation=(0, math.radians(30), math.radians(90))))
    return join("JungleGym", parts)



PROPS = [  # builder, texture size, has leaf cards
    (oak_tree, 1024, True), (fir_tree, 1024, False), (bush, 512, True), (flower_patch, 512, False),
    (bench, 512, False), (picnic_table, 512, False), (lamp, 512, False), (swing_set, 512, False),
    (jungle_gym, 512, False),
]
bake_all(PROPS, "ParkProps.fbx")
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT, "ParkProps.blend"), copy=True)
