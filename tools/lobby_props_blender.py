"""Builds and bakes the Lobby props (run inside Blender: exec(open(path).read())).
ShopStall  = a wooden market stall with a striped canvas awning and a blank sign board (the shop
             name is drawn on in Roblox with a SurfaceGui). Front = -Y (Roblox -Z), 14 x 9 studs.
BoardFrame = a metal leaderboard stand: two posts and a frame around a dark 16 x 10 panel.
Beanbag    = a slumped fabric beanbag for the AFK corner.
Same pipeline as the other props (blender_props_lib.py). Writes assets/models/lobby/LobbyProps.fbx.
"""
import math
import os
import random

TOOLS = r"C:\Users\kgkan\Documents\GitHub\Ragdoll Biker 💀🦴\tools"
ROOT = r"C:\Users\kgkan\Documents\GitHub\Ragdoll Biker 💀🦴\assets\models\lobby"
SRC = ROOT
os.makedirs(ROOT, exist_ok=True)
exec(open(os.path.join(TOOLS, "blender_props_lib.py"), encoding="utf-8").read())
reset_scene()
random.seed(71)


def canvas():
    """Striped red/white awning canvas with a woven texture and sun-faded folds."""
    def build(g):
        co = g.coords((1, 1, 1))
        sep = g.add("ShaderNodeSeparateXYZ")
        g.link(co[0], co[1], sep, 0)
        stripes = g.math("GREATER_THAN", g.math("PINGPONG", (sep, "X"), 1.0), 0.5)
        weave = g.add("ShaderNodeTexWave", wave_type="BANDS", bands_direction="X")
        weave.inputs["Scale"].default_value = 60.0
        g.link(co[0], co[1], weave, "Vector")
        weave2 = g.add("ShaderNodeTexWave", wave_type="BANDS", bands_direction="Z")
        weave2.inputs["Scale"].default_value = 60.0
        g.link(co[0], co[1], weave2, "Vector")
        cloth = g.math("MULTIPLY", g.math("ADD", (weave, "Fac"), (weave2, "Fac")), 0.5)
        col = g.mix(stripes, (0.78, 0.12, 0.1), (0.92, 0.9, 0.84))
        fade = g.add("ShaderNodeTexNoise")
        fade.inputs["Scale"].default_value = 1.5
        g.link(co[0], co[1], fade, "Vector")
        col = g.mix(g.math("MULTIPLY", (fade, "Fac"), 0.3), col, (0.95, 0.92, 0.85))
        col = g.mix(g.math("MULTIPLY", cloth, 0.12), col, (0.2, 0.15, 0.12))
        g.finish(shaded(g, col, ao_distance=1.5), height=cloth, bump=0.25, roughness=0.95, bevel=0.02)
    return material("Canvas", build)


def fabric(name, colour):
    def build(g):
        co = g.coords((1, 1, 1))
        weave = g.add("ShaderNodeTexWave", wave_type="BANDS", bands_direction="DIAGONAL")
        weave.inputs["Scale"].default_value = 45.0
        g.link(co[0], co[1], weave, "Vector")
        folds = g.add("ShaderNodeTexNoise")
        folds.inputs["Scale"].default_value = 2.2
        folds.inputs["Detail"].default_value = 4.0
        g.link(co[0], co[1], folds, "Vector")
        col = g.mix(g.math("MULTIPLY", (folds, "Fac"), 0.35), colour, tuple(c * 0.55 for c in colour))
        col = g.mix(g.math("MULTIPLY", (weave, "Fac"), 0.1), col, (1, 1, 1))
        seam = g.edge_mask(0.08, 8)
        col = g.mix(g.math("MULTIPLY", seam, 0.35), col, tuple(c * 0.45 for c in colour))
        g.finish(shaded(g, col, ao_distance=1.2), height=(folds, "Fac"), bump=0.4, roughness=0.95, bevel=0.1)
    return material(name, build)


def screen_panel():
    def build(g):
        noise = g.add("ShaderNodeTexNoise")
        noise.inputs["Scale"].default_value = 8.0
        col = g.ramp((noise, "Fac"), [(0.3, (0.05, 0.06, 0.09)), (0.7, (0.09, 0.1, 0.14))])
        g.finish(col, roughness=0.3, bevel=0.0)
    return material("BoardPanel", build)


def shop_stall():
    plank = wood("StallWood", (0.62, 0.42, 0.24), (0.36, 0.22, 0.11))
    dark = wood("StallWoodDark", (0.42, 0.27, 0.15), (0.22, 0.13, 0.07))
    metal = painted_metal("StallMetal", (0.18, 0.2, 0.24))
    parts = []
    w, d = 14.0, 7.0
    parts.append(box(plank, (w, d, 0.5), (0, 0, 0.25)))  # floor
    parts.append(box(dark, (w, 1.4, 3.6), (0, -d / 2 + 0.7, 2.3)))  # counter front
    parts.append(box(plank, (w + 0.4, 1.9, 0.3), (0, -d / 2 + 0.8, 4.25)))  # counter top
    parts.append(box(dark, (w, 0.4, 8.0), (0, d / 2 - 0.2, 4.5)))  # back wall
    for x in (-w / 2 + 0.3, w / 2 - 0.3):
        for y in (-d / 2 + 0.3, d / 2 - 0.3):
            parts.append(box(plank, (0.55, 0.55, 9.0), (x, y, 4.75)))  # posts
        parts.append(box(dark, (0.4, d - 0.6, 3.6), (x, 0, 2.3)))  # side panels
    parts.append(box(metal, (w + 1.0, 0.3, 0.3), (0, -d / 2 - 0.4, 8.7)))  # awning bar
    # sloped striped awning from the back top down over the counter
    awning = box(canvas(), (w + 1.2, d + 1.6, 0.18), (0, -0.4, 9.4), rotation=(math.radians(-14), 0, 0))
    parts.append(awning)
    for i in range(int(w + 1)):  # scalloped valance
        parts.append(box(canvas(), (0.9, 0.12, 0.7), (-w / 2 + 0.5 + i, -d / 2 - 1.2, 8.35)))
    parts.append(box(dark, (w * 0.8, 0.3, 2.2), (0, -d / 2 - 0.2, 11.0)))  # sign board (text added in Roblox)
    for x in (-w * 0.3, w * 0.3):
        parts.append(box(metal, (0.15, 0.15, 1.4), (x, -d / 2 - 0.2, 10.0)))  # sign posts
    for i in range(5):  # a few crates on the counter for life
        s = random.uniform(0.8, 1.3)
        parts.append(box(plank, (s, s, s), (-w / 2 + 2 + i * 2.5, -d / 2 + 0.9, 4.4 + s / 2)))
    return join("ShopStall", parts)


def board_frame():
    metal = painted_metal("BoardMetal", (0.2, 0.22, 0.27))
    trim = painted_metal("BoardTrim", (0.95, 0.7, 0.12))
    parts = []
    w, h = 16.0, 10.0
    for x in (-w / 2 - 0.4, w / 2 + 0.4):
        parts.append(box(metal, (0.6, 0.6, h + 4.5), (x, 0, (h + 4.5) / 2)))  # legs
        parts.append(box(metal, (1.6, 1.6, 0.3), (x, 0, 0.15)))  # feet
    parts.append(box(screen_panel(), (w, 0.3, h), (0, 0.15, 4 + h / 2)))  # panel (text drawn in Roblox)
    for z in (4 - 0.25, 4 + h + 0.25):
        parts.append(box(trim, (w + 1.4, 0.7, 0.5), (0, 0, z)))  # top/bottom trim
    for x in (-w / 2 - 0.1, w / 2 + 0.1):
        parts.append(box(trim, (0.5, 0.7, h + 1.0), (x, 0, 4 + h / 2)))  # side trim
    return join("BoardFrame", parts)


def beanbag():
    bag = blob(fabric("BeanbagFabric", (0.15, 0.45, 0.85)), 2.0, (0, 0, 1.3), squash=0.6, jitter=0.12, subdivisions=3)
    for v in bag.data.vertices:  # flat bottom and a dent to sit in
        if v.co.z < -0.6:
            v.co.z = -0.6
        if v.co.z > 0.2 and v.co.y > -0.3:
            v.co.z -= 0.35 * (v.co.z - 0.2)
    return join("Beanbag", [bag])


bake_all([(shop_stall, 1024, False), (board_frame, 512, False), (beanbag, 512, False)], "LobbyProps.fbx")
