#!/usr/bin/env python3
"""check-contrast.py — проверка пар роль/фон по WCAG 2.x.

Читает каждый src/palette*.json (холодная Moon и тёплый Moon Warm), считает
контраст для пар из "pairs" и падает с кодом 1, если хоть одна пара ниже порога.
Текст — 4.5:1, UI — 3:1, декор — низкий порог, заданный в самой паре.
"""
import glob
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def lin(c):
    c = c / 255
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def lum(hex_color):
    h = hex_color.lstrip("#")
    r, g, b = (int(h[i:i + 2], 16) for i in (0, 2, 4))
    return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)


def ratio(a, b):
    la, lb = sorted((lum(a), lum(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


def check(path):
    pal = json.load(open(path, encoding="utf-8"))
    roles = pal["dark"]
    fails = []
    print(f"== {pal['name']} ({os.path.relpath(path, ROOT)})")
    print(f"{'пара':42s} {'контраст':>9s}  {'порог':>5s}  итог")
    for fg, bg, need, label in pal["pairs"]:
        c = ratio(roles[fg], roles[bg])
        ok = c >= need
        if not ok:
            fails.append((label, fg, bg, c, need))
        print(f"{label + ' (' + fg + '/' + bg + ')':42s} {c:9.2f}  {need:5.1f}  {'ok' if ok else 'FAIL'}")

    term = pal["terminal"]
    tc = ratio(term["foreground"], term["background"])
    tok = tc >= 4.5
    if not tok:
        fails.append(("terminal fg/bg", "foreground", "background", tc, 4.5))
    print(f"{'терминал fg/bg':42s} {tc:9.2f}  {4.5:5.1f}  {'ok' if tok else 'FAIL'}")
    return fails


def main():
    paths = sorted(glob.glob(os.path.join(ROOT, "src", "palette*.json")))
    if not paths:
        print("нет src/palette*.json")
        return 1
    all_fails = []
    for path in paths:
        for fail in check(path):
            all_fails.append((os.path.basename(path), fail))
        print()
    if all_fails:
        print("провал:", "; ".join(f"{p}: {f[0]} {f[3]:.2f} < {f[4]}" for p, f in all_fails))
        return 1
    print("все пары во всех палитрах проходят пороги")
    return 0


if __name__ == "__main__":
    sys.exit(main())
