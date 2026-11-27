"""Paints the Skate Park source textures:
  src/ChainLink.png      - tileable chain-link fence wire (transparent background)
  Graffiti_<n>.png       - spray-paint style tags for the concrete floor (transparent background)
Usage: python tools/skate_textures.py <outdir>   (graffiti go in <outdir>, chain link in <outdir>/src)
"""
import math
import os
import random
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

OUT = sys.argv[1]
FONTS = [r"C:\Windows\Fonts\impact.ttf", r"C:\Windows\Fonts\ariblk.ttf", r"C:\Windows\Fonts\comicbd.ttf"]
rng = random.Random(9)


def chain_link():
    size, cell = 256, 64  # one tile = 4x4 diamonds
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    for i in range(-1, size // cell + 2):
        for j in range(-1, size // cell + 2):
            cx, cy = i * cell, j * cell
            pts = [(cx, cy - cell / 2), (cx + cell / 2, cy), (cx, cy + cell / 2), (cx - cell / 2, cy), (cx, cy - cell / 2)]
            draw.line(pts, fill=(70, 72, 76, 255), width=7)  # wire shadow edge
            draw.line(pts, fill=(185, 190, 195, 255), width=4)  # galvanised wire
            draw.line([(p[0] - 1, p[1] - 1) for p in pts], fill=(240, 242, 245, 255), width=1)  # glint
    return img


PALETTES = [  # fill top, fill bottom, outline, shadow
    ((255, 90, 160), (160, 40, 220), (25, 20, 40), (0, 0, 0)),
    ((80, 230, 255), (40, 90, 255), (20, 25, 50), (0, 0, 0)),
    ((255, 230, 60), (255, 120, 30), (40, 20, 10), (0, 0, 0)),
    ((120, 255, 120), (20, 160, 90), (15, 40, 20), (0, 0, 0)),
    ((255, 255, 255), (190, 190, 210), (220, 30, 60), (0, 0, 0)),
]
WORDS = ["RAGDOLL", "BAIL!", "SEND IT", "OUCH", "BONES", "SK8", "SPLAT", "NO FEAR"]


def gradient_text(word, font, fill_top, fill_bottom):
    left, top, right, bottom = font.getbbox(word, stroke_width=0)
    w, h = right - left + 20, bottom - top + 20
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).text((10 - left, 10 - top), word, font=font, fill=255)
    grad = Image.new("RGBA", (w, h))
    for y in range(h):
        t = y / max(1, h - 1)
        c = tuple(int(a + (b - a) * t) for a, b in zip(fill_top, fill_bottom))
        ImageDraw.Draw(grad).line([(0, y), (w, y)], fill=c + (255,))
    grad.putalpha(mask)
    return grad, (left, top)


def tag(word, palette, font_path):
    fill_top, fill_bottom, outline, shadow = palette
    font = ImageFont.truetype(font_path, 150)
    canvas = Image.new("RGBA", (1024, 512), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas, "RGBA")
    left, top, right, bottom = draw.textbbox((0, 0), word, font=font, stroke_width=16)
    x, y = (1024 - (right - left)) // 2 - left, (512 - (bottom - top)) // 2 - top - 20
    # soft spray halo, hard shadow, thick outline
    halo = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(halo).text((x, y), word, font=font, fill=fill_bottom + (150,), stroke_width=34, stroke_fill=fill_bottom + (150,))
    canvas.alpha_composite(halo.filter(ImageFilter.GaussianBlur(14)))
    draw.text((x + 12, y + 12), word, font=font, fill=shadow + (200,), stroke_width=16, stroke_fill=shadow + (200,))
    draw.text((x, y), word, font=font, fill=outline + (255,), stroke_width=16, stroke_fill=outline + (255,))
    # paint drips running down from the letters
    for _ in range(9):
        dx = rng.randint(x + 20, x + right - left - 40)
        length = rng.randint(30, 110)
        top_y = y + bottom - top - 60
        draw.rectangle([dx, top_y, dx + 9, top_y + length], fill=fill_bottom + (235,))
        draw.ellipse([dx - 3, top_y + length - 6, dx + 12, top_y + length + 9], fill=fill_bottom + (235,))
    body, _ = gradient_text(word, font, fill_top, fill_bottom)
    canvas.alpha_composite(body, (x + font.getbbox(word)[0] - 10, y + font.getbbox(word)[1] - 10))
    # highlight sparkles
    for _ in range(4):
        sx, sy = rng.randint(x, x + right - left), rng.randint(y, y + 60)
        draw.line([(sx - 14, sy), (sx + 14, sy)], fill=(255, 255, 255, 230), width=4)
        draw.line([(sx, sy - 14), (sx, sy + 14)], fill=(255, 255, 255, 230), width=4)
    angle = rng.uniform(-10, 10)
    return canvas.rotate(angle, resample=Image.BICUBIC)


os.makedirs(os.path.join(OUT, "src"), exist_ok=True)
chain_link().save(os.path.join(OUT, "src", "ChainLink.png"))
for i, word in enumerate(WORDS, 1):
    tag(word, PALETTES[i % len(PALETTES)], FONTS[i % len(FONTS)]).save(os.path.join(OUT, f"Graffiti_{i}.png"))
print("painted", len(WORDS), "tags")
