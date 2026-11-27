"""Paints the shared texture sheet for the low-poly park props (assets/models/park/ParkAtlas.png).
4x4 cells of 128 px; each Blender material named after a cell maps its faces into that cell.
The cell order here must match CELLS in the Blender build script."""
import sys
import numpy as np
from PIL import Image, ImageFilter

CELL = 128
CELLS = [  # name, base RGB, pattern
    ("LeafLight", (110, 200, 80), "speckle"), ("LeafDark", (60, 150, 60), "speckle"),
    ("FirNeedle", (40, 110, 70), "needles"), ("Bark", (120, 80, 50), "streaks"),
    ("WoodLight", (205, 150, 95), "grain"), ("WoodDark", (150, 100, 60), "grain"),
    ("Metal", (150, 160, 175), "brushed"), ("PaintRed", (230, 85, 80), "soft"),
    ("PaintBlue", (80, 160, 235), "soft"), ("PaintYellow", (250, 200, 60), "soft"),
    ("PetalPink", (250, 130, 180), "soft"), ("PetalYellow", (255, 225, 90), "soft"),
    ("PetalPurple", (170, 120, 240), "soft"), ("Stone", (170, 170, 165), "speckle"),
    ("Glow", (255, 240, 170), "soft"), ("Rope", (60, 60, 70), "streaks"),
]

rng = np.random.default_rng(7)


def cell(base, pattern):
    y, x = np.mgrid[0:CELL, 0:CELL] / CELL
    shade = 1.0 + 0.12 * (0.5 - y)  # gentle top-lit gradient
    noise = rng.normal(0, 1, (CELL, CELL))
    if pattern == "speckle":
        shade += 0.10 * noise
    elif pattern == "needles":
        shade += 0.12 * np.sign(np.sin(x * 90 + noise)) * 0.6 + 0.05 * noise
    elif pattern == "streaks":
        shade += 0.10 * np.sin(x * 60 + np.sin(y * 7) * 2) + 0.05 * noise
    elif pattern == "grain":
        shade += 0.08 * np.sin(y * 70 + np.sin(x * 9) * 3) + 0.03 * noise
    elif pattern == "brushed":
        shade += 0.06 * np.sin(y * 200) + 0.04 * noise
    else:  # soft
        shade += 0.03 * noise
    rgb = np.clip(np.array(base)[None, None, :] * shade[:, :, None], 0, 255)
    return rgb.astype(np.uint8)


atlas = np.zeros((CELL * 4, CELL * 4, 3), np.uint8)
for i, (_, base, pattern) in enumerate(CELLS):
    r, c = divmod(i, 4)
    atlas[r * CELL:(r + 1) * CELL, c * CELL:(c + 1) * CELL] = cell(base, pattern)
Image.fromarray(atlas).filter(ImageFilter.SMOOTH).save(sys.argv[1])
print("cells:", [c[0] for c in CELLS])
