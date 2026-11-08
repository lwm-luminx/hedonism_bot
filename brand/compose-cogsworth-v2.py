#!/usr/bin/env python3
"""Compose the framed and borderless Cogsworth v2 icons from transparent-v2.png.

transparent-v2.png is the supplied art-deco aperture clock on a transparent
canvas. This script places it on the same warm charcoal backgrounds the v1
variants used: a full-bleed field (borderless) and a rounded macOS tile
(framed). Requires Pillow.
"""

from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
SOURCES = ROOT / "brand/concepts/cogsworth"
SIZE = 1254
SS = 4  # supersampling for smooth tile edges


def radial(size, inner, outer, center=(0.5, 0.42)):
    """Warm charcoal radial gradient, brighter slightly above center."""
    small = 256
    grad = Image.new("RGB", (small, small))
    px = grad.load()
    cx, cy = center[0] * small, center[1] * small
    rmax = (2 * (small / 2) ** 2) ** 0.5
    for y in range(small):
        for x in range(small):
            t = min(1.0, (((x - cx) ** 2 + (y - cy) ** 2) ** 0.5) / rmax)
            t = t ** 1.4
            px[x, y] = tuple(round(a + (b - a) * t) for a, b in zip(inner, outer))
    return grad.resize((size, size), Image.BICUBIC).filter(ImageFilter.GaussianBlur(4))


def squircle_mask(size, inset, exponent=5.0):
    big = size * SS
    mask = Image.new("L", (big, big), 0)
    half = (big - 2 * inset * SS) / 2
    c = big / 2
    pts = []
    import math
    for i in range(2000):
        a = 2 * math.pi * i / 2000
        ca, sa = math.cos(a), math.sin(a)
        x = c + half * (abs(ca) ** (2 / exponent)) * (1 if ca >= 0 else -1)
        y = c + half * (abs(sa) ** (2 / exponent)) * (1 if sa >= 0 else -1)
        pts.append((x, y))
    ImageDraw.Draw(mask).polygon(pts, fill=255)
    return mask.resize((size, size), Image.LANCZOS)


def clock(height):
    art = Image.open(SOURCES / "transparent-v2.png").convert("RGBA")
    # The supplied PNG has faint alpha noise across the canvas; drop it so the
    # crop and the shadows follow the clock itself.
    alpha = art.getchannel("A").point(lambda v: v if v >= 10 else 0)
    art.putalpha(alpha)
    art = art.crop(alpha.getbbox())
    width = round(art.width * height / art.height)
    return art.resize((width, height), Image.LANCZOS)


def place(canvas, art, center_y, shadow_strength=150):
    x = (canvas.width - art.width) // 2
    y = round(center_y - art.height / 2)
    # contact shadow under the base plus a soft overall glow-shadow
    shadow = Image.new("L", canvas.size, 0)
    shadow.paste(art.getchannel("A"), (x, y + round(art.height * 0.02)))
    shadow = shadow.filter(ImageFilter.GaussianBlur(art.height * 0.03))
    shadow = shadow.point(lambda v: v * shadow_strength // 255)
    canvas.paste(Image.new("RGBA", canvas.size, (0, 0, 0, 255)), (0, 0), shadow)
    floor = Image.new("L", canvas.size, 0)
    fx0, fx1 = x + art.width * 0.08, x + art.width * 0.92
    fy = y + art.height
    ImageDraw.Draw(floor).ellipse((fx0, fy - art.height * 0.035, fx1, fy + art.height * 0.012), fill=190)
    floor = floor.filter(ImageFilter.GaussianBlur(art.height * 0.025))
    canvas.paste(Image.new("RGBA", canvas.size, (0, 0, 0, 255)), (0, 0), floor)
    canvas.alpha_composite(art, (x, y))
    return canvas


def borderless():
    canvas = radial(SIZE, (40, 35, 31), (14, 13, 12)).convert("RGBA")
    art = clock(round(SIZE * 0.70))
    return place(canvas, art, SIZE * 0.5).convert("RGB")


def framed():
    canvas = radial(SIZE, (27, 25, 24), (17, 15, 15), center=(0.5, 0.3)).convert("RGBA")
    inset = 47
    tile_mask = squircle_mask(SIZE, inset)
    # drop shadow of the tile on the outer surface
    shadow = tile_mask.filter(ImageFilter.GaussianBlur(14))
    shadow = ImageChops.offset(shadow, 0, 8).point(lambda v: v * 200 // 255)
    canvas.paste(Image.new("RGBA", canvas.size, (6, 6, 5, 255)), (0, 0), shadow)
    plate = radial(SIZE, (36, 32, 29), (19, 18, 17), center=(0.5, 0.4)).convert("RGBA")
    canvas.paste(plate, (0, 0), tile_mask)
    # thin dark rim with a faint top highlight
    rim = ImageChops.subtract(tile_mask, squircle_mask(SIZE, inset + 3))
    canvas.paste(Image.new("RGBA", canvas.size, (10, 10, 9, 255)), (0, 0), rim)
    hl = ImageChops.subtract(squircle_mask(SIZE, inset + 3), squircle_mask(SIZE, inset + 5))
    fade = Image.linear_gradient("L").resize((SIZE, SIZE)).point(lambda v: max(0, 110 - v))
    hl = ImageChops.multiply(hl, fade)
    canvas.paste(Image.new("RGBA", canvas.size, (90, 82, 72, 255)), (0, 0), hl)
    tile = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    place(tile, clock(round(SIZE * 0.64)), SIZE * 0.5)
    tile.putalpha(ImageChops.multiply(tile.getchannel("A"), tile_mask))
    canvas.alpha_composite(tile)
    return canvas.convert("RGB")


if __name__ == "__main__":
    borderless().save(SOURCES / "borderless-v2.png", optimize=True)
    framed().save(SOURCES / "framed-v2.png", optimize=True)
