# MAINTAINING — как поддерживать Moon после релизов Ryoku

Записи живут в публичном репозитории и магазине, поэтому обновление — это всегда
проверка на свежей системе, бамп версии и PR. Ниже — порядок, без которого
запись в магазине стареет молча.

## После каждого релиза Ryoku

1. `ryoku update` (или штатное обновление системы), затем `ryoku --version`.
2. Smoke риса: импорт и гейт отката на текущем релизе.

   ```sh
   ryoku-hub rice preflight
   ryoku-hub rice import "$PWD/rices/moon"
   ryoku-hub rice apply moon
   ryoku-hub rice restore previous
   ```

   Гейт считается пройденным, если откат вернул `shell.json`, `theme.json` и
   `~/.cache/ryoku/colors.json` к снимку из `rice home/` (сравнивать `sha256sum`).
3. Smoke схемы: `ryoku-shell theme catalog | grep moon`, `ryoku-shell theme moon`,
   затем `ryoku-shell theme Default`.
4. Smoke плагина: `ryoku plugin validate plugins/moon-phase`,
   `ryoku plugin add plugins/moon-phase --bar --yes`,
   `ryoku-shell bar list | grep moon-phase`, лог без новых QML-ошибок
   (`journalctl --user -u ryoku-shell`).
5. Если проверки зелёные — бамп в **источниках**, а не в генерируемом:
   `src/rice.override.json` (`createdWith`), `src/tokens.json` при смене сетки,
   `plugins/moon-phase/manifest.json` (`version`) и `product-manifest.json`
   через `tools/pack-product.py`; `rices/moon/rice.json` и
   `colorschemes/*/*.json` пересобираются (`python3 tools/build-rice.py`,
   `./tools/build-rice.sh`) и руками не правятся. Плюс `README.md`,
   `CHANGELOG.md` и `lastUpdated` в записях магазина (`YYYY-MM-DD`).
6. Пересобрать генерируемое: `python3 tools/build-rice.py && ./tools/build-rice.sh`
   и `python3 tools/check-contrast.py` (все пары AA).
7. Пересобрать карточку и запись магазина: `python3 tools/make-card.py <снимок>
   rices/moon/assets/preview.webp`, `python3 tools/build-store.py` (с
   `--wallpaper-url`, когда обои уже лежат Release-ассетом). Для плагина —
   `ryoku plugin export moon-phase --to <tmp>` и `tools/pack-product.py
   plugins/moon-phase --touch` в клоне `ryostore`. Перед PR: строгий прогон
   только для риса — `python3 tests/validate-store.py --root . --categories
   rices --require-media`; для плагина и всего остального — полный
   `tests/validate-catalogue.sh` без флага. Флаг `--require-media` по
   `plugins` красный из-за чужих записей (у большинства плагинов магазина
   превью меньше 1280×720 — на 14.11.2026 это 42 записи из 49), это не наш
   дефект.

## Если что-то сломалось

- Симптом → сначала лог и воспроизведение, потом правка. Плагин: `.qslog`
  показывает ошибки компонента (`PluginObjectSlot: ...`), `ryoku plugin validate`
  их не ловит — он проверяет манифест и правила, а не компиляцию QML.
- Сломанный item не оставляем в магазине: чиним и выпускаем, либо снимаем запись
  и пишем об этом в `upstream`.
- Схема ломает читаемость (контраст ниже AA) — правим `src/palette.json`,
  `tools/check-contrast.py` обязан остаться зелёным.

## Правила, которые нельзя нарушать

- `official: false`, `upstream` жив, `lastUpdated` в дате — для рисов и плагинов.
  Запись схемы в `colorschemes/registry.json` в 1.0.9 состоит из
  `id/name/provider/path/accent/surface/dark` (без `official`/`upstream`), как у
  всех существующих тем магазина (в клоне на 14.11.2026 — 119 записей).
- Плагин: без сети, `sudo` и композитора; импорты только `QtQuick*`,
  `Quickshell*`, `Ryoku.PluginKit[.Singletons]`.
- Рис владеет только whitelist-ключами из `docs/PLAN.md` §4; `capture` целиком не
  коммитим.
- Публикация — только после явного «добро» Алана; рис + тема одним PR, плагин
  отдельным.

## Проверка утверждений

Любое «работает» подтверждается командой и её выводом в этой же сессии. Чек-лист
перед отчётом: `git diff` прочитан, тесты/валидаторы запущены, `README` и
`CHANGELOG` обновлены, откат проверен.
