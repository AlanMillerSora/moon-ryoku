#!/usr/bin/env python3
"""make-wall.py — обои риса из личного исходника: один свет, монохром, зерно.

Не «перекраска фильтром»: картинка обесцвечивается, тени уводятся в холод,
свет сохраняется, края притемняются вигнетом, сверху зерно 0.10 — тот же рецепт,
что у карточки Store, но без текста и печати.

    python3 tools/make-wall.py ~/Pictures/Wallpapers/Angel1.png /tmp/wall-moon.webp
    python3 tools/make-wall.py in.png out.webp --ratio 21:9 --side center --width 3440

Палитру для риса из готовых обоев считает `tools/build-rice.py` по src/palette.json;
если хочется вывести роль из тона обоев, смотри --sample.
"""
import argparse
import math
import os
import random

from PIL import Image, ImageFilter, ImageOps

INK = (244, 244, 246)


def parse_ratio(value):
    w, h = value.split(":")
    return int(w) / int(h)


def cover(img, ratio, side):
    w, h = img.size
    if w / h > ratio:
        new_w = int(h * ratio)
        x = 0 if side == "left" else (w - new_w if side == "right" else (w - new_w) // 2)
        box = (x, 0, x + new_w, h)
    else:
        new_h = int(w / ratio)
        y = 0 if side == "top" else (h - new_h if side == "bottom" else (h - new_h) // 2)
        box = (0, y, w, y + new_h)
    return img.crop(box)


def cool_mono(img, shadow=(10, 11, 16), light=(244, 244, 246), mid=None, lift=0.92):
    """Обесцветить и подкрасить: тени в холод, светлые места — лунный свет.

    Светимость сохраняем (не инвертируем и не выжигаем): серая картинка идёт в
    ImageOps.colorize по трём точкам — тень, середина, свет.
    """
    gray = ImageOps.autocontrast(img.convert("L"), cutoff=0.5)
    gray = gray.point(lambda v: int(255 * (v / 255) ** lift))
    if mid is None:
        mid = tuple(int(shadow[i] + (light[i] - shadow[i]) * 0.45) for i in range(3))
    return ImageOps.colorize(gray, black=shadow, mid=mid, white=light)


def vignette(size, strength=0.45):
    width, height = size
    small = Image.new("L", (64, 36), 0)
    px = small.load()
    for y in range(36):
        for x in range(64):
            dx = (x - 31.5) / 31.5
            dy = (y - 17.5) / 17.5
            d = min(1.0, math.sqrt(dx * dx + dy * dy) / 1.15)
            px[x, y] = int(255 * strength * (d ** 2.2))
    return small.resize((width, height), Image.BICUBIC)


def grain(size, amount=6, seed=11):
    width, height = size
    rnd = random.Random(seed)
    noise = Image.new("L", (width, height))
    noise.putdata([max(0, min(255, 128 + int(rnd.gauss(0, amount)))) for _ in range(width * height)])
    return noise


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("source")
    ap.add_argument("out")
    ap.add_argument("--ratio", default="16:9", help="16:9, 21:9 или 3440:1440")
    ap.add_argument("--side", choices=["left", "center", "right", "top", "bottom"], default="center")
    ap.add_argument("--width", type=int, default=3440)
    ap.add_argument("--shadow", default="#0A0B10", help="цвет тени")
    ap.add_argument("--light", default="#F4F4F6", help="цвет света")
    args = ap.parse_args()

    ratio = parse_ratio(args.ratio)
    height = round(args.width / ratio)
    src = Image.open(args.source).convert("RGB")
    base = cover(src, ratio, args.side).resize((args.width, height), Image.LANCZOS)

    shadow = tuple(int(args.shadow[i:i + 2], 16) for i in (1, 3, 5))
    light = tuple(int(args.light[i:i + 2], 16) for i in (1, 3, 5))
    base = cool_mono(base, shadow, light)

    dark = Image.new("RGB", base.size, (6, 6, 8))
    base = Image.composite(dark, base, vignette(base.size, 0.45))

    noise = grain(base.size)
    base = Image.blend(base, Image.merge("RGB", (noise, noise, noise)), 0.045)
    base = base.filter(ImageFilter.GaussianBlur(0.25))

    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    if args.out.lower().endswith(".webp"):
        base.save(args.out, "WEBP", quality=90, method=6)
    else:
        base.save(args.out)
    print(f"wall: {args.out} {base.size[0]}×{base.size[1]} ({os.path.getsize(args.out) // 1024} KiB)")


if __name__ == "__main__":
    main()
