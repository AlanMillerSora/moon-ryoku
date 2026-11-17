#!/usr/bin/env bash
# moon-task-prompt.sh — одна клавиша: спросить текст и добавить дело в виджет.
# Спрашиваем в маленьком окне kitty (без сети, без GUI-запросов прав).
set -euo pipefail
command -v kitty >/dev/null 2>&1 || { echo "нужен kitty" >&2; exit 1; }
exec kitty --class moon-task-prompt --title "новая задача" \
  --override font_size=12 --override window_padding_width=14 \
  -e bash -lc 'read -rp "задача: " t; [ -n "${t// /}" ] && "$HOME/.local/bin/moon-task" add "$t"'
