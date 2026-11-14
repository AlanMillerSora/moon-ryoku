#!/usr/bin/env python3
"""build-store.py — упаковка риса Moon для магазина ryostore.

Собирает dist/store/rices/moon/ из rices/moon/ по контракту
ryostore/rices/AUTHORING.md:

  rice.json        манифест риса + поля магазина
                   (schema, id, category, version, destination, files[])
  palette.json     фиксированная палитра (color: fixed), install: true
  wall.webp        обои риса, install: true
  assets/preview.webp  настоящий снимок рабочего стола с печатью 月, install: false

Хеши считаются здесь же, поэтому запись магазина и файлы не расходятся.
Ничего не публикует: результат — каталог, который копируется в клон ryostore.
"""
import argparse
import hashlib
import json
import os
import shutil
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "rices", "moon")
OUT = os.path.join(ROOT, "dist", "store", "rices", "moon")

# что ставится вместе с рисом и что лишь показывается в магазине
FILES = [
    ("palette.json", True),
    ("wall.webp", True),
    ("assets/preview.webp", False),
]


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--wallpaper-url", default="",
                    help="Release-ассет обоев (тег rices); с ним wall.webp не "
                         "ставится внутри риса, а обои тянутся по URL")
    args = ap.parse_args()

    rice = json.load(open(os.path.join(SRC, "rice.json"), encoding="utf-8"))
    override = json.load(open(os.path.join(ROOT, "src", "rice.override.json"), encoding="utf-8"))

    missing = [src for src, _ in FILES if not os.path.isfile(os.path.join(SRC, src))]
    if missing:
        print("build-store: нет файлов:", ", ".join(missing))
        return 1

    if os.path.isdir(OUT):
        shutil.rmtree(OUT)
    os.makedirs(OUT)

    files = []
    planned = [row for row in FILES if not (args.wallpaper_url and row[0] == "wall.webp")]
    for source, install in planned:
        src_path = os.path.join(SRC, source)
        dst_path = os.path.join(OUT, source)
        os.makedirs(os.path.dirname(dst_path) or OUT, exist_ok=True)
        shutil.copy2(src_path, dst_path)
        files.append({
            "source": source,
            "destination": source,
            "mode": "0644",
            "size": os.path.getsize(src_path),
            "sha256": sha256(src_path),
            "install": install,
        })

    meta = override.get("store", {})
    store = dict(rice)
    store.update({
        "schema": 1,
        "id": rice["slug"],
        "category": "rices",
        "version": meta.get("version", "1.0.0"),
        "destination": f"ryoku/rices/{rice['slug']}",
        "files": files,
    })
    # порядок ключей как у существующих рисов магазина
    ordered = {k: store[k] for k in
               ("schema", "id", "category", "version", "destination", "slug", "name",
                "author", "blurb", "tags", "createdWith", "color", "assets", "look", "files")
               if k in store}
    for key, value in store.items():
        ordered.setdefault(key, value)

    with open(os.path.join(OUT, "rice.json"), "w", encoding="utf-8") as f:
        json.dump(ordered, f, indent=2, ensure_ascii=False)
        f.write("\n")

    entry = {
        "id": ordered["id"],
        "name": ordered["name"],
        "version": ordered["version"],
        "path": f"rices/{ordered['id']}",
        "author": "Alan Miller",
        "upstream": "https://github.com/AlanMillerSora/moon-ryoku",
        "summary": meta.get("summary", rice.get("blurb", "")),
        "description": meta.get("description", rice.get("blurb", "")),
        "tags": meta.get("tags", rice.get("tags", [])),
        "accent": json.load(open(os.path.join(SRC, "palette.json")))["primary"],
        "surface": json.load(open(os.path.join(SRC, "palette.json")))["background"],
        "preview": "assets/preview.webp",
        "screenshots": [],
        "manifest": "rice.json",
        "manifestSha256": sha256(os.path.join(OUT, "rice.json")),
        "blurb": meta.get("summary", rice.get("blurb", "")),
        "official": False,
        "lastUpdated": meta.get("lastUpdated",
                                __import__("datetime").date.today().isoformat()),
        "createdWith": ordered.get("createdWith", ""),
        "color": ordered.get("color", {}).get("mode", "fixed"),
        "palette": f"rices/{ordered['id']}/palette.json",
        "rounding": ordered.get("look", {}).get("hypr", {}).get("appearance", {}).get("rounding", 6),
    }
    if args.wallpaper_url:
        entry["wallpaper"] = args.wallpaper_url

    with open(os.path.join(OUT, "registry-entry.json"), "w", encoding="utf-8") as f:
        json.dump(entry, f, indent=2, ensure_ascii=False)
        f.write("\n")

    preview = os.path.join(OUT, "assets", "preview.webp")
    print(f"store: dist/store/rices/moon ({len(files)} files, "
          f"preview {os.path.getsize(preview) // 1024} KiB, id={ordered['id']}, "
          f"version={ordered['version']})")
    print("manifest sha256:", sha256(os.path.join(OUT, "rice.json")))
    return 0


if __name__ == "__main__":
    sys.exit(main())
