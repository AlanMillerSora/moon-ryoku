#!/usr/bin/env bash
# build-rice.sh — собирает записи магазина из src/.
# Вход:  src/palette.json, src/palette.warm.json (опционально), src/tokens.json
# Выход: colorschemes/<Name>/<Name>.json        схемы для магазина
#        colorschemes/<Name>/registry-entry.json строки реестра colorschemes
#        dist/scheme.json, dist/meta.json       основная схема для локальной установки
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT" <<'PY'
import glob, json, os, sys

root = sys.argv[1]
tok = json.load(open(os.path.join(root, "src", "tokens.json"), encoding="utf-8"))
built = []

for path in sorted(glob.glob(os.path.join(root, "src", "palette*.json"))):
    pal = json.load(open(path, encoding="utf-8"))
    roles = pal["dark"]
    name, slug, provider = pal["name"], pal["slug"], pal["provider"]

    store_theme = {"dark": dict(roles, terminal=pal["terminal"])}
    os.makedirs(os.path.join(root, "colorschemes", name), exist_ok=True)
    with open(os.path.join(root, "colorschemes", name, f"{name}.json"), "w", encoding="utf-8") as f:
        json.dump(store_theme, f, indent=2, ensure_ascii=False)
        f.write("\n")

    entry = {
        "id": slug,
        "name": name,
        "provider": provider,
        "path": f"colorschemes/{name}",
        "accent": roles["mPrimary"],
        "surface": roles["mSurface"],
        "dark": roles,
    }
    with open(os.path.join(root, "colorschemes", name, "registry-entry.json"), "w", encoding="utf-8") as f:
        json.dump(entry, f, indent=2, ensure_ascii=False)
        f.write("\n")

    built.append(name)

    # dist/ — только основная схема (её ставит локальный установщик)
    if os.path.basename(path) == "palette.json":
        dist = os.path.join(root, "dist")
        os.makedirs(dist, exist_ok=True)
        with open(os.path.join(dist, "scheme.json"), "w", encoding="utf-8") as f:
            json.dump({"dark": roles}, f, indent=2, ensure_ascii=False)
            f.write("\n")
        with open(os.path.join(dist, "meta.json"), "w", encoding="utf-8") as f:
            json.dump({"label": name, "provider": provider}, f, indent=2, ensure_ascii=False)
            f.write("\n")

print("built schemes:", ", ".join(built))
for name in built:
    print("  colorschemes/%s/%s.json + registry-entry.json" % (name, name))
print("density:", tok["density"]["basePx"], "px  radius:", tok["geometry"]["radius"],
      "border:", tok["geometry"]["border"], "bar:", tok["bar"]["style"])
PY
