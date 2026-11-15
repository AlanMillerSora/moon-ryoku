#!/usr/bin/env python3
"""build-rice.py — собирает rices/moon из src/ и проверяет санитайзером.

Вход:  src/rice.base.json      структура, снятая с текущей версии Ryoku (1.0.9)
       src/rice.override.json  значения Moon (whitelist)
       src/palette.json        16 Material-ролей
       src/tokens.json         плотность и бар
Выход: rices/moon/rice.json, rices/moon/palette.json
Проверки: нет ключей вне whitelist, нет /home/, hostname, IP, токенов и
ключей вида token/secret/api_key; проверяются и rice.json, и palette.json.
"""
import json
import os
import re
import socket
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "rices", "moon")

WHITELIST = {
    "schema", "slug", "name", "author", "blurb", "tags", "createdWith", "color", "assets", "look",
}
LOOK_WHITELIST = {"hypr", "wm", "shell", "theme", "launcher",
                  "visualizer", "stage", "matugen", "ryogami"}

# Новые ветки, которых нет в базовой схеме 1.0.9, но которые рис сознательно
# добавляет (sumi рисует рейлы из frameBars).
ALLOWED_NEW_PATHS = {
    "look.shell.frameBars",
    "look.visualizer",
    "look.stage",
    "look.matugen",
    "look.ryogami",
    "assets.wallpaper",
    "assets.cursor",
    "assets.fastfetchStyle",
}

FORBIDDEN = [
    re.compile(r"/home/"),
    re.compile(r"/Users/"),
    re.compile(r"\b\d{1,3}(?:\.\d{1,3}){3}\b"),
    # токены и приватные ключи: даже случайно попавший секрет не должен уехать в магазин
    re.compile(r"gh[pousr]_[A-Za-z0-9]{20,}"),
    re.compile(r"github_pat_[A-Za-z0-9_]{20,}"),
    re.compile(r"sk-[A-Za-z0-9]{20,}"),
    re.compile(r"xox[baprs]-[A-Za-z0-9-]{10,}"),
    re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----"),
]

# ключи, которых в манифесте риса быть не может (секреты/учётки)
FORBIDDEN_KEYS = re.compile(r"(?i)(token|secret|passw|api_?key|credential)")


def merge(base, override):
    out = {}
    for k, v in base.items():
        if isinstance(v, dict) and isinstance(override.get(k), dict):
            out[k] = merge(v, override[k])
        else:
            out[k] = v
    for k, v in override.items():
        if k not in out:
            out[k] = v
        elif isinstance(v, dict) and isinstance(out.get(k), dict):
            out[k] = merge(out[k], v)
        else:
            out[k] = v
    return out


def palette_from_roles(roles, term):
    """wallust+Material палитра для риса (формат как у store-рисов)."""
    return {
        "background": roles["mSurface"],
        "foreground": roles["mOnSurface"],
        "cursor": roles["mPrimary"],
        "color0": term["normal"]["black"],
        "color1": term["normal"]["red"],
        "color2": term["normal"]["green"],
        "color3": term["normal"]["yellow"],
        "color4": term["normal"]["blue"],
        "color5": term["normal"]["magenta"],
        "color6": term["normal"]["cyan"],
        "color7": term["normal"]["white"],
        "color8": term["bright"]["black"],
        "color9": term["bright"]["red"],
        "color10": term["bright"]["green"],
        "color11": term["bright"]["yellow"],
        "color12": term["bright"]["blue"],
        "color13": term["bright"]["magenta"],
        "color14": term["bright"]["cyan"],
        "color15": term["bright"]["white"],
        "primary": roles["mPrimary"],
        "onPrimary": roles["mOnPrimary"],
        "primaryContainer": roles["mHover"],
        "onPrimaryContainer": roles["mOnHover"],
        "secondary": roles["mSecondary"],
        "onSecondary": roles["mOnSecondary"],
        "secondaryContainer": roles["mSurfaceVariant"],
        "onSecondaryContainer": roles["mOnSurfaceVariant"],
        "tertiary": roles["mTertiary"],
        "onTertiary": roles["mOnTertiary"],
        "tertiaryContainer": "#1E1E24",
        "onTertiaryContainer": roles["mOnSurface"],
        "error": roles["mError"],
        "onError": roles["mOnError"],
        "errorContainer": "#3A1E1B",
        "onErrorContainer": roles["mOnError"],
        "surface": roles["mSurface"],
        "onSurface": roles["mOnSurface"],
        "surfaceVariant": roles["mSurfaceVariant"],
        "onSurfaceVariant": roles["mOnSurfaceVariant"],
        "surfaceContainerLowest": "#08080A",
        "surfaceContainerLow": "#101012",
        "surfaceContainer": roles["mSurfaceVariant"],
        "surfaceContainerHigh": "#1C1C21",
        "surfaceContainerHighest": "#222228",
        "surfaceTint": roles["mPrimary"],
        "outline": roles["mOutline"],
        "outlineVariant": "#1F1F24",
        "inverseSurface": roles["mOnSurface"],
        "inverseOnSurface": roles["mSurface"],
        "shadow": roles["mShadow"],
        "scrim": "#000000",
    }


def unknown_paths(node, base, allowed, path=""):
    """Пути, которых нет в base и которые не разрешены явно."""
    out = []
    if isinstance(node, dict):
        for k, v in node.items():
            key = f"{path}.{k}" if path else k
            if key in allowed:
                continue
            if not isinstance(base, dict) or k not in base:
                out.append(key)
                continue
            out.extend(unknown_paths(v, base[k], allowed, key))
    elif isinstance(node, list) and isinstance(base, list) and base and node:
        # списки сравниваем по первому элементу: схема в base задаёт форму
        out.extend(unknown_paths(node[0], base[0], allowed, f"{path}[]"))
    return out


def walk(node, path, problems):
    if isinstance(node, dict):
        for k, v in node.items():
            if FORBIDDEN_KEYS.search(k):
                problems.append(f"{path}.{k}: ключ похож на секрет")
            walk(v, f"{path}.{k}" if path else k, problems)
    elif isinstance(node, list):
        for i, v in enumerate(node):
            walk(v, f"{path}[{i}]", problems)
    elif isinstance(node, str):
        for rx in FORBIDDEN:
            if rx.search(node):
                problems.append(f"{path}: {node[:60]}")


def main():
    base = json.load(open(os.path.join(ROOT, "src", "rice.base.json"), encoding="utf-8"))
    override = json.load(open(os.path.join(ROOT, "src", "rice.override.json"), encoding="utf-8"))
    pal = json.load(open(os.path.join(ROOT, "src", "palette.json"), encoding="utf-8"))
    tok = json.load(open(os.path.join(ROOT, "src", "tokens.json"), encoding="utf-8"))

    rice = merge(base, override)
    store = rice.pop("store", {})

    # блоки «как сейчас»: визуализатор, сцена, matugen, обои.
    # Снимаются с живой машины `tools/capture-look.py`, без личных путей.
    look_src = os.path.join(ROOT, "src", "rice.look.json")
    if os.path.isfile(look_src):
        extra = json.load(open(look_src, encoding="utf-8"))
        for block in ("visualizer", "stage", "matugen", "ryogami"):
            if isinstance(extra.get(block), dict) and extra[block]:
                rice.setdefault("look", {})[block] = extra[block]
        # терминальный fetch: файл лежит рядом с rice.json
        if os.path.isfile(os.path.join(OUT, "fastfetch.jsonc")):
            rice.setdefault("assets", {})["fastfetchStyle"] = "fastfetch.jsonc"
    rice["schema"] = 1
    rice["name"] = override["name"]
    rice["slug"] = override["slug"]
    rice["author"] = override["author"]

    # плотность и печать берём из общих токенов, а не дублируем в override
    rice.setdefault("look", {})["theme"] = dict(rice["look"].get("theme", {}), followWallpaper=False)

    problems = []
    extra = set(rice) - WHITELIST
    if extra:
        problems.append("ключи вне whitelist: " + ", ".join(sorted(extra)))
    extra_look = set(rice.get("look", {})) - LOOK_WHITELIST
    if extra_look:
        problems.append("look вне whitelist: " + ", ".join(sorted(extra_look)))
    for branch in ("look", "assets", "color"):
        for path in unknown_paths(rice.get(branch, {}), base.get(branch, {}),
                                  ALLOWED_NEW_PATHS, branch):
            problems.append("ключ вне базовой схемы и вне whitelist: " + path)
    walk(rice, "", problems)
    walk(store, "store", problems)
    palette = palette_from_roles(pal["dark"], pal["terminal"])
    walk(palette, "palette", problems)
    dump = json.dumps(rice, ensure_ascii=False) + json.dumps(palette, ensure_ascii=False)
    if socket.gethostname() and socket.gethostname() in dump:
        problems.append("в рисе есть hostname")
    if problems:
        print("санитайзер: ПРОВАЛ")
        for p in problems:
            print(" -", p)
        return 1

    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, "rice.json"), "w", encoding="utf-8") as f:
        json.dump(rice, f, indent=2, ensure_ascii=False)
        f.write("\n")
    with open(os.path.join(OUT, "palette.json"), "w", encoding="utf-8") as f:
        json.dump(palette, f, indent=2)
        f.write("\n")

    print(f"rice: rices/moon/rice.json ({os.path.getsize(os.path.join(OUT, 'rice.json'))} b)")
    print(f"palette: rices/moon/palette.json, density {tok['density']['basePx']}px, "
          f"radius {tok['geometry']['radius']}, bar {tok['bar']['style']}")
    print("санитайзер: ok")
    return 0


if __name__ == "__main__":
    sys.exit(main())
