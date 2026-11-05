#!/usr/bin/env python3
"""MoyaHogushi app icon: fog-blue ground, drifting haze, and a warm sun breaking through."""

import os
from PIL import Image, ImageDraw, ImageFilter

SIZE = 1024
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                   "MoyaHogushi/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png")

TOP = (96, 118, 134)
BOTTOM = (40, 54, 66)
SUN_CORE = (255, 196, 128)
SUN_EDGE = (231, 118, 62)


def gradient() -> Image.Image:
    img = Image.new("RGB", (SIZE, SIZE))
    px = img.load()
    for y in range(SIZE):
        t = y / (SIZE - 1)
        row = tuple(int(TOP[i] + (BOTTOM[i] - TOP[i]) * t) for i in range(3))
        for x in range(SIZE):
            px[x, y] = row
    return img


def glow(color, center, radius, alpha, blur) -> Image.Image:
    layer = Image.new("RGBA", (SIZE, SIZE), (*color, 0))
    d = ImageDraw.Draw(layer)
    cx, cy = center
    d.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), fill=(*color, alpha))
    return layer.filter(ImageFilter.GaussianBlur(blur))


def main():
    base = gradient().convert("RGBA")

    base.alpha_composite(glow(SUN_EDGE, (512, 470), 330, 120, 120))

    sun = Image.new("RGBA", (SIZE, SIZE), (*SUN_EDGE, 0))
    d = ImageDraw.Draw(sun)
    d.ellipse((512 - 190, 470 - 190, 512 + 190, 470 + 190), fill=(*SUN_EDGE, 255))
    d.ellipse((512 - 150, 470 - 150, 512 + 150, 470 + 150), fill=(*SUN_CORE, 255))
    base.alpha_composite(sun.filter(ImageFilter.GaussianBlur(2)))

    haze = [
        ((200, 640), 230, 235, 60),
        ((560, 700), 290, 225, 55),
        ((860, 610), 210, 230, 62),
        ((380, 840), 300, 215, 45),
        ((800, 860), 260, 215, 50),
        ((512, 560), 200, 240, 38),
    ]
    for center, radius, tone, alpha in haze:
        base.alpha_composite(glow((tone, tone + 6, tone + 10), center, radius, alpha * 3, 70))

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    base.convert("RGB").save(OUT)
    print("Saved", OUT)


if __name__ == "__main__":
    main()
