#!/usr/bin/env bash
# install-moon.sh — поставить всё, что рис не может принести сам: плагины
# (в магазине это отдельные записи) и их место на сцене/баре.
#
# Идемпотентно: плагин той же версии не переустанавливается (иначе стираются
# его настройки в plugins.json), позиция ставится только если её ещё нет,
# координаты считаются от активного монитора, а не зашиты под 3440.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}/ryoku/plugins.json"

installed_version() {
  ryoku plugin list --json 2>/dev/null | jq -r --arg id "$1" \
    '.[] | select(.id == $id) | .version' 2>/dev/null | head -1
}

repo_version() {
  jq -r '.version' "$ROOT/plugins/$1/manifest.json"
}

has_placement() {
  jq -e --arg id "$1" 'has($id) and (.[$id] | has("host"))' "$CFG" >/dev/null 2>&1
}

place() {
  local id="$1"; shift
  # `enabled` — идемпотентный выключатель, его ставим всегда;
  # координаты и хост не трогаем, если пользователь уже расставил сам
  if [ "${1:-}" != "enabled" ] && has_placement "$id"; then
    echo "place: $id уже стоит, не трогаю"
    return 0
  fi
  ryoku-plugins-place "$id" "$@" || echo "place: $id — не удалось, поставь вручную в Settings → Add-ons" >&2
}

install_plugin() {
  local id="$1"
  [ -d "$ROOT/plugins/$id" ] || { echo "install: нет каталога plugins/$id" >&2; return 1; }
  local have repo
  have="$(installed_version "$id")"
  repo="$(repo_version "$id")"
  if [ "$have" = "$repo" ]; then
    echo "plugin: $id $repo уже стоит"
    return 0
  fi
  if [ -n "$have" ]; then
    echo "plugin: $id $have -> $repo, переустановка"
    ryoku plugin remove "$id" >/dev/null 2>&1 || true
  fi
  ryoku plugin add "$ROOT/plugins/$id" --yes >/dev/null
  echo "plugin: $id $repo"
}

# геометрия активного монитора: виджеты справа, но не за краем
read -r SW SH <<<"$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | "\(.width) \(.height)"' | head -1)"
SW="${SW:-1920}"; SH="${SH:-1080}"
MX=$(( SW * 73 / 100 ))
MY1=$(( SH * 29 / 100 ))
MY2=$(( SH * 44 / 100 ))

install_plugin moon-phase
place moon-phase host topbarGlyph
place moon-phase enabled true

install_plugin moon
place moon host desktopWidget
place moon desktopWidget "$MX" "$MY1" 1
place moon enabled true

install_plugin moon-tasks
place moon-tasks host desktopWidget
place moon-tasks desktopWidget "$MX" "$MY2" 1
place moon-tasks enabled true

echo "готово: плагины на месте (сцена: $MX,$MY1 и $MX,$MY2)"
