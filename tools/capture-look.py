#!/usr/bin/env python3
"""capture-look.py — снять «как сейчас» с живой машины в src/rice.look.json.

Берёт блоки, которые рис обязан принести с собой, чтобы после установки (или
после чужого риса) вернулось всё, а не половина:

  look.visualizer  реакция на звук (aura/wave, чувствительность, включён ли)
  look.stage       эффект глубины обоев и его движение
  look.matugen     чем красятся приложения
  look.ryogami     переходы и поведение обоев

Персональное (пути, мониторы, последняя обои, id) вырезается: рис не должен
тащить чужие данные. Скрипт идемпотентен и ничего не применяет.
"""
import json
import os
import re
import sys

CFG = os.path.expanduser("~/.config/ryoku")
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "src", "rice.look.json")

STAGE_KEYS = ("edge", "editGridSize", "editGridSnap", "front", "motion",
              "quality", "shadow", "shadowAngle")


def load(name, default):
    path = os.path.join(CFG, name)
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return default


def strip_personal(node, path=""):
    """Убрать ключи, которые описывают машину, а не оформление."""
    banned = re.compile(r"(?i)(lastapplied|last_applied|source_color|sourcеcolor|"
                        r"monitor|screen|path|dir|home|user|host|machine|"
                        r"activeid|active_id)")
    if isinstance(node, dict):
        out = {}
        for key, value in node.items():
            if banned.search(key):
                continue
            out[key] = strip_personal(value, f"{path}.{key}")
        return out
    if isinstance(node, list):
        return [strip_personal(v, path) for v in node]
    if isinstance(node, str):
        if node.startswith("/") or node.startswith("file://"):
            return ""
        return node
    return node


def main():
    visualizer = strip_personal(load("visualizer.json", {}))
    stage_raw = load("stage.json", {})
    stage = {k: stage_raw[k] for k in STAGE_KEYS if k in stage_raw}
    matugen = strip_personal(load("matugen.json", {}))
    ryogami = strip_personal(load("ryogami.json", {}))
    # filterBar — состояние фильтров в пикере, не оформление
    ryogami.pop("filterBar", None)

    look = {
        "visualizer": visualizer,
        "stage": stage,
        "matugen": matugen,
        "ryogami": ryogami,
    }

    blob = json.dumps(look, ensure_ascii=False)
    if "/home/" in blob or "/Users/" in blob:
        print("capture-look: в снимке остались личные пути — прерываю")
        return 1

    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(look, f, ensure_ascii=False, indent=2)
        f.write("\n")

    print(f"capture-look: {os.path.relpath(OUT, ROOT)} "
          f"(visualizer {len(visualizer)} ключей, stage {len(stage)}, "
          f"matugen {len(matugen)}, ryogami {len(ryogami)})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
