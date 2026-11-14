#!/usr/bin/env python3
"""make-card.py — карточка Store из настоящего снимка рабочего стола.

Берёт скриншот (grim, 3440×1440 и т.п.), режет в 16:9, притемняет низ и края,
ставит печать 月, слово MOON и подпись, добавляет зерно 0.10 — как в
docs/DESIGN.md («зерно только на арте»). Ничего не рисует «с нуля»: фон всегда
реальный снимок, поэтому карточка не врёт про то, как выглядит рис.

Использование:
    python3 tools/make-card.py /tmp/moon-clean.png dist/store/rices/moon/assets/preview.webp
    python3 tools/make-card.py shot.png out.png --side right --width 1600 --height 900
"""
import argparse
import math
import os
import random

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

FONT_DISPLAY = "/usr/share/fonts/TTF/Fraunces[SOFT,WONK,opsz,wght].ttf"
FONT_UI = "/usr/share/fonts/TTF/JetBrainsMonoNerdFontMono-Regular.ttf"
FONT_JP = "/usr/share/fonts/noto-cjk/NotoSansCJK-Regular.ttc"

INK = (244, 244, 246)
DIM = (168, 168, 178)


def cover(img, width, height, side):
    """Обрезка в 16:9 с привязкой к краю (чтобы не резать рейл бара)."""
    w, h = img.size
    target = width / height
    if w / h > target:
        new_w = int(h * target)
        x = 0 if side == "left" else (w - new_w if side == "right" else (w - new_w) // 2)
        box = (x, 0, x + new_w, h)
    else:
        new_h = int(w / target)
        box = (0, 0, w, new_h)
    return img.crop(box).resize((width, height), Image.LANCZOS)


def gradient(size, top_alpha, bottom_alpha, start_ratio):
    """Вертикальный градиент прозрачность сверху вниз."""
    width, height = size
    layer = Image.new("L", (1, height))
    start = int(height * start_ratio)
    for y in range(height):
        if y < start:
            value = int(top_alpha)
        else:
            t = (y - start) / max(1, height - start)
            value = int(top_alpha + (bottom_alpha - top_alpha) * t)
        layer.putpixel((0, y), value)
    return layer.resize((width, height))


def vignette(size, strength):
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


def grain(size, amount, seed=7):
    width, height = size
    rnd = random.Random(seed)
    noise = Image.new("L", (width, height))
    data = [128 + int(rnd.gauss(0, amount)) for _ in range(width * height)]
    noise.putdata([max(0, min(255, v)) for v in data])
    return noise


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("screenshot")
    ap.add_argument("out")
    ap.add_argument("--width", type=int, default=1600)
    ap.add_argument("--height", type=int, default=900)
    ap.add_argument("--side", choices=["left", "center", "right"], default="left",
                    help="какой край снимка держать при обрезке в 16:9")
    ap.add_argument("--title", default="MOON")
    ap.add_argument("--tagline", default="Холодный монохром. Две рейки. Один свет.")
    args = ap.parse_args()

    base = cover(Image.open(args.screenshot).convert("RGB"), args.width, args.height, args.side)

    shade = Image.new("RGB", base.size, (6, 6, 8))
    mask = gradient(base.size, 0, 215, 0.45)
    base = Image.composite(shade, base, mask)
    vig = vignette(base.size, 0.55)
    base = Image.composite(shade, base, vig)

    overlay = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    # печать 月 — маленький штамп в рамке, как клеймо категории в Store
    seal_box = int(args.height * 0.105)
    seal_font = ImageFont.truetype(FONT_JP, int(seal_box * 0.66), index=0)
    sx, sy = int(args.width * 0.055), int(args.height * 0.615)
    draw.rectangle((sx, sy, sx + seal_box, sy + seal_box),
                   outline=(244, 244, 246, 110), width=1)
    seal_layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    ImageDraw.Draw(seal_layer).text((sx + seal_box / 2, sy + seal_box / 2 - 2), "月",
                                    font=seal_font, fill=(244, 244, 246, 230), anchor="mm")
    overlay = Image.alpha_composite(overlay, seal_layer)

    draw = ImageDraw.Draw(overlay)
    title_font = ImageFont.truetype(FONT_DISPLAY, int(args.height * 0.10))
    tag_font = ImageFont.truetype(FONT_UI, int(args.height * 0.026))
    meta_font = ImageFont.truetype(FONT_UI, int(args.height * 0.019))

    x = int(args.width * 0.055)
    draw.text((x + seal_box + int(args.width * 0.022), sy + seal_box // 2 + 6), args.title,
              font=title_font, fill=INK, anchor="ls")
    draw.text((x, int(args.height * 0.805)), args.tagline, font=tag_font, fill=INK,
              anchor="ls")
    draw.text((x, int(args.height * 0.895)), "RYOKU · SUMI", font=meta_font, fill=DIM,
              anchor="ls")

    card = Image.alpha_composite(base.convert("RGBA"), overlay).convert("RGB")

    # зерно 0.10: лёгкий шум только на арте
    noise = grain(card.size, 6)
    card = Image.blend(card, Image.merge("RGB", (noise, noise, noise)), 0.045)
    card = card.filter(ImageFilter.GaussianBlur(0.3))

    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    if args.out.lower().endswith(".webp"):
        card.save(args.out, "WEBP", quality=92, method=6)
    else:
        card.save(args.out)
    print(f"card: {args.out} {card.size[0]}×{card.size[1]} "
          f"({os.path.getsize(args.out) // 1024} KiB)")


if __name__ == "__main__":
    main()
