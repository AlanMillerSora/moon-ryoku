#!/usr/bin/env bash
# install-moon.sh — поставить всё, что рис не может принести сам:
# плагины (магазин ставит их отдельными записями) и их место на сцене/баре.
# Рис при этом уже применён; скрипт только доставляет плагины и раскладку.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

install_plugin() {
  local dir="$1" id="$2"
  if ryoku plugin list 2>/dev/null | grep -q "^$id "; then
    ryoku plugin remove "$id" >/dev/null 2>&1 || true
  fi
  ryoku plugin add "$dir" --yes >/dev/null
  echo "plugin: $id"
}

install_plugin "$ROOT/plugins/moon-phase" moon-phase
ryoku-plugins-place moon-phase host topbarGlyph || true
ryoku-plugins-place moon-phase enabled true || true

install_plugin "$ROOT/plugins/moon" moon
ryoku-plugins-place moon host desktopWidget
ryoku-plugins-place moon desktopWidget 2528 420 1
ryoku-plugins-place moon enabled true

install_plugin "$ROOT/plugins/moon-tasks" moon-tasks
ryoku-plugins-place moon-tasks host desktopWidget
ryoku-plugins-place moon-tasks desktopWidget 2528 640 1
ryoku-plugins-place moon-tasks enabled true

echo "готово: плагины на месте"
