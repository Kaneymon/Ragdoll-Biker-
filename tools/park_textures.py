"""Paints the hand-drawn style source textures used by the park prop materials
(tools/park_props_blender.py bakes them onto each prop):
  Leaves.png     - tileable dense canopy of overlapping leaves (opaque)
  LeafCard.png   - a loose cluster of leaves on a transparent background (leaf cards)
  FirNeedles.png - tileable fir boughs: branches covered in needles
  Petal.png      - a single petal shape, pale at the tip, deeper at the base (transparent background)
  GrassBlades.png - a tuft of curved grass blades growing from the bottom edge (transparent background)
Usage: python tools/park_textures.py <outdir>
"""
import math
import os
import random
import sys

from PIL import Image, ImageDraw, ImageFilter

OUT = sys.argv[1]
rng = random.Random(5)

LEAF_GREENS = [(70, 140, 50), (90, 165, 60), (110, 185, 70), (60, 120, 45), (130, 195, 80)]


def jitter(colour, amount):
    return tuple(max(0, min(255, c + rng.randint(-amount, amount))) for c in colour)


def leaf_points(cx, cy, length, width, angle, steps=10):
    """Outline of a pointed oval leaf (both ends pointed, widest just below the middle)."""
    pts = []
    for side in (1, -1):
        rng_steps = range(steps + 1) if side == 1 else range(steps, -1, -1)
        for i in rng_steps:
            t = i / steps
            x = (t - 0.5) * length
            y = side * width / 2 * math.sin(math.pi * t) ** 0.8 * (1.1 - 0.3 * t)
            pts.append((x, y))
    ca, sa = math.cos(angle), math.sin(angle)
    return [(cx + x * ca - y * sa, cy + x * sa + y * ca) for x, y in pts]


def draw_leaf(draw, cx, cy, length, width, angle, colour, shadow=True):
    if shadow:
        draw.polygon(leaf_points(cx + 3, cy + 4, length, width, angle), fill=(25, 55, 20, 110))
    draw.polygon(leaf_points(cx, cy, length, width, angle), fill=colour + (255,), outline=tuple(int(c * 0.7) for c in colour) + (255,))
    # lit half: a lighter sliver along one side
    light = tuple(min(255, int(c * 1.18)) for c in colour) + (255,)
    draw.polygon(leaf_points(cx - math.sin(angle) * width * 0.12, cy + math.cos(angle) * width * 0.12, length * 0.9, width * 0.45, angle), fill=light)
    # midrib and a few veins
    ca, sa = math.cos(angle), math.sin(angle)
    vein = tuple(min(255, int(c * 1.35)) for c in colour) + (200,)
    a = (cx - ca * length * 0.48, cy - sa * length * 0.48)
    b = (cx + ca * length * 0.45, cy + sa * length * 0.45)
    draw.line([a, b], fill=vein, width=2)
    for k in (-0.25, 0, 0.22):
        px, py = cx + ca * length * k, cy + sa * length * k
        for side in (1, -1):
            va = angle + side * 0.9
            draw.line([(px, py), (px + math.cos(va) * width * 0.4, py + math.sin(va) * width * 0.4)], fill=vein, width=1)


def wrapped(size, draw_fn, count):
    """Draw `count` items, repeating each across the edges so the result tiles."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    for _ in range(count):
        x, y = rng.uniform(0, size), rng.uniform(0, size)
        params = draw_fn(None, 0, 0, measure=True)
        for dx in (-size, 0, size):
            for dy in (-size, 0, size):
                draw_fn(draw, x + dx, y + dy, params=params)
    return img


def leaves_tile():
    size = 1024
    base = Image.new("RGBA", (size, size), (45, 95, 35, 255))

    def leaf(draw, x, y, measure=False, params=None):
        if measure:
            return (rng.uniform(70, 110), rng.uniform(0.38, 0.5), rng.uniform(0, math.tau), jitter(rng.choice(LEAF_GREENS), 12))
        length, ratio, angle, colour = params
        draw_leaf(draw, x, y, length, length * ratio, angle, colour)

    layer = wrapped(size, leaf, 520)
    base.alpha_composite(layer)
    return base.filter(ImageFilter.SMOOTH)


def leaf_card():
    size = 512
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    for _ in range(85):
        r, a = rng.uniform(0, size * 0.4), rng.uniform(0, math.tau)
        x, y = size / 2 + math.cos(a) * r, size / 2 + math.sin(a) * r
        length = rng.uniform(55, 85)
        draw_leaf(draw, x, y, length, length * rng.uniform(0.4, 0.5), a + rng.uniform(-0.6, 0.6), jitter(rng.choice(LEAF_GREENS), 12))
    return img


def fir_tile():
    size = 1024
    img = Image.new("RGBA", (size, size), (22, 60, 38, 255))
    draw = ImageDraw.Draw(img, "RGBA")
    greens = [(35, 95, 60), (45, 115, 70), (30, 80, 50), (60, 135, 80)]
    for _ in range(420):  # boughs: a twig with needles fanning off both sides
        x, y = rng.uniform(0, size), rng.uniform(0, size)
        angle = math.pi / 2 + rng.uniform(-0.5, 0.5)  # hanging down-ish
        length = rng.uniform(90, 160)
        colour = rng.choice(greens)
        for dx in (-size, 0, size):
            for dy in (-size, 0, size):
                ox, oy = x + dx, y + dy
                ex, ey = ox + math.cos(angle) * length, oy + math.sin(angle) * length
                draw.line([(ox, oy), (ex, ey)], fill=(60, 45, 30, 255), width=3)
                for i in range(18):
                    t = i / 18
                    px, py = ox + (ex - ox) * t, oy + (ey - oy) * t
                    n = 26 * (1 - t * 0.5)
                    for side in (1, -1):
                        na = angle + side * 0.7
                        tip = jitter(colour, 15)
                        draw.line([(px, py), (px + math.cos(na) * n, py + math.sin(na) * n)], fill=tip + (255,), width=3)
                        hl = tuple(min(255, int(c * 1.4)) for c in tip) + (255,)
                        draw.line([(px + math.cos(na) * n * 0.6, py + math.sin(na) * n * 0.6), (px + math.cos(na) * n, py + math.sin(na) * n)], fill=hl, width=2)
    return img.filter(ImageFilter.SMOOTH)


def petal():
    size = 256
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    for i in range(60, 0, -1):  # concentric petal shapes: white-ish tip to saturated base
        t = i / 60
        shade = int(255 * (0.75 + 0.25 * t))
        draw = ImageDraw.Draw(img, "RGBA")
        draw.polygon(leaf_points(size / 2, size / 2, size * 0.92 * t + 10, size * 0.6 * t + 6, -math.pi / 2, 12), fill=(shade, shade, shade, 255))
    draw = ImageDraw.Draw(img, "RGBA")
    for k in range(-2, 3):  # veins
        draw.line([(size / 2, size * 0.9), (size / 2 + k * 18, size * 0.2)], fill=(200, 200, 200, 160), width=2)
    return img.filter(ImageFilter.SMOOTH)


def grass_blades():
    size = 512
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    for _ in range(70):
        base_x = rng.uniform(size * 0.08, size * 0.92)
        height = rng.uniform(size * 0.45, size * 0.97)
        lean = rng.uniform(-0.45, 0.45) * height
        width = rng.uniform(10, 20)
        dark = jitter((55, 120, 40), 15)
        light = jitter((150, 210, 90), 15)
        steps = 12
        left, right = [], []
        for i in range(steps + 1):
            t = i / steps
            x = base_x + lean * t * t  # curves over towards the tip
            y = size - height * t
            w = width * (1 - t) ** 0.8 / 2
            left.append((x - w, y))
            right.append((x + w, y))
        pts = left + right[::-1]
        draw.polygon(pts, fill=dark + (255,))
        # lighter towards the tip: draw the upper part again in the light colour
        upper = left[5:] + right[5:][::-1]
        draw.polygon(upper, fill=tuple((a + b) // 2 for a, b in zip(dark, light)) + (255,))
        tip = left[9:] + right[9:][::-1]
        draw.polygon(tip, fill=light + (255,))
        draw.line([(base_x, size), left[-1]], fill=tuple(min(255, c + 30) for c in light) + (150,), width=1)
    return img


os.makedirs(OUT, exist_ok=True)
leaves_tile().convert("RGB").save(os.path.join(OUT, "Leaves.png"))
leaf_card().save(os.path.join(OUT, "LeafCard.png"))
fir_tile().convert("RGB").save(os.path.join(OUT, "FirNeedles.png"))
petal().save(os.path.join(OUT, "Petal.png"))
grass_blades().save(os.path.join(OUT, "GrassBlades.png"))
print("painted")
