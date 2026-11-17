#!/usr/bin/env bash
# moon-task.sh — короткая команда для заметок виджета Moon Tasks.
# install-moon.sh кладёт её в ~/.local/bin/moon-task, дальше:
#   moon-task add "позвонить в банк"
#   moon-task list | toggle 2 | done 2 | clear
set -euo pipefail
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/ryoku/plugins/moon-tasks"
BIN="${XDG_DATA_HOME:-$HOME/.local/share}/ryoku/plugins/moon-tasks/bin/moon-task"
[ -x "$BIN" ] || { echo "moon-task: плагин moon-tasks не установлен" >&2; exit 1; }
exec "$BIN" "$STATE" "$@"
