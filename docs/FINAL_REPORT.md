# FINAL REPORT — Moon (Ryoku rice), 14.11.2026

Итог по фазам и всё, что осталось открытым. Каждое утверждение — с командой,
которой оно проверено. Публикаций в магазин нет.

## Состояние по фазам

| Фаза | Состояние | Чем проверено |
| --- | --- | --- |
| P0 | сделано | дерево, MIT, `docs/DECISIONS.md`, репозиторий на GitHub |
| P1 | сделано | `python3 tools/check-contrast.py` → все пары AA; `ryoku-shell theme catalog` → `moon` на месте |
| P2 | сделано, кроме обоев | `rice apply`/`restore` (P2-гейт), рис 4.3 КБ из whitelist |
| P3 | сделано | см. «Плагин» ниже |
| P4 | сделано без публикации | `tests/validate-catalogue.sh` в клоне ryostore → `store catalogue OK`; `docs/README.md` |
| P5 | процедура готова | `docs/MAINTAINING.md`, первый прогон — на следующем релизе Ryoku |
| P6 | опция, сделана частично | `Moon Warm` собирается и проходит AA; остальное не начато намеренно |

## Плагин `moon-phase`: что было сломано и как проверено

1. Сервис не компилировался вообще: `service/Main.qml:22`
   `readonly property int synodicDays: 29.530588853` → QML роняет компонент
   целиком («Invalid property assignment: int expected»). Виджет на баре жил без
   сервиса: рисовал новолуние и «0 %».
   Проверка: лог живого шелла
   `PluginObjectSlot: .../store/plugin-views/moon-phase/<hash>/service/Main.qml?v=0.1.0:22:40:
   Invalid property assignment: int expected`; воспроизведено стендом
   (`Qt.createComponent` → `status=3`, тот же errorString).
   Исправлено (`real`), стенд после правки: `frac=0.1445471271730033
   illum=0.19242352865271012 age=4.268561782428265 name=Waxing crescent
   next=24.11.2026 17:59`.
2. Живой бар: виджет показывает серп и «19%» (`grim -s 2`, снимок лёг в
   `plugins/moon-phase/assets/preview-widget.png`). Расчёт 19.21 % совпал с
   независимым пересчётом той же формулы на Python.
3. Панель: `content/Panel.qml` проверена рендером в отдельном Quickshell-стенде
   с живым сервисом и настоящей темой Ryoku — фаза, «19% · 4.3 d», «Next full:
   24.11.2026 17:59». Живой клик по глифу в headless-сессии не воспроизводим:
   указатель нечем инжектить без `uinput`/root; хост-код открытия панели
   (`qsbar/Theme.qml` → `openPluginPanel`, `BarSlot.qml` → `togglePanel`) не
   менялся.
4. CPU: 60 с с плагином 5.30 с, 60 с без — 5.29 с → дельта 0.01 с = 0.017 %
   ядра, порог 0.2 % (`/tmp/plugin-cpu.out`, метод — `/proc/<pid>/stat`
   utime+stime у `qs -c shell`, переключение `ryoku-shell bar hide|show
   moon-phase` на QS Bar).
5. `ryoku plugin validate plugins/moon-phase` → `0 blocking, 0 warnings`.

## Открытые вопросы (нужно решение Алана)

1. **`sumi` не умеет хостить виджеты плагинов.** `topbarGlyph` рисуется только
   на QS Bar: рейл `sumi` собирается из фиксированного каталога
   `/usr/lib/qt6/qml/Ryoku/FrameBars/BarCatalog.js` (17 id, `normalize` фильтрует
   всё остальное). Факт: на `qsbar` виджет виден и работает, на `sumi` (рис Moon)
   — нет. Варианты: (а) оставить как есть и написать в карточке «виджет для QS
   Bar» (сейчас так и написано); (б) перенести лук Moon на `qsbar`; (в) убрать
   плагин из v1. Решение — за Аланом, по умолчанию выбран (а).
2. **`rice restore previous` не возвращает оформление окон.** После гейта
   `~/.config/ryoku/desktop.json` оказался без `desktop.appearance`
   (6313 → 72 байта), живые значения упали на модульные: `general:gaps_in 12`,
   `gaps_out 18`, `border_size 2`, `decoration:rounding 0`, blur включён.
   Восстановлено копией `desktop.json` + `ryoku-hub desktop preview
   "$(cat ~/.config/ryoku/desktop.json)"` → снова 16/16/4/8, blur off,
   `desktop.json` побайтово равен сохранённой копии (`cmp` → тишина).
   Это дефект инструмента риса, не нашего манифеста; обход описан в
   `docs/README.md`.
3. **Обои.** Ассет готовит Алан; в репозитории лежит временный `wall.webp`, рис
   его не применяет (`ryogami` остаётся на прежнем `lastAppliedKey`) — обход и
   команда `ryogami wallpaper set` в `docs/README.md`.
4. **Скриншоты отложены**, а значит запись риса в магазине не собрать: контракт
   `ryostore` требует настоящий `preview` ≥ 1280×720. Запись плагина собрана и
   проходит (`store catalogue OK`), запись риса и карточка с печатью 月 ждут
   скриншоты.
5. **Шрифты.** Трио `Space Grotesk` / `Space Mono` / `Fraunces` записано в рис,
   но в 1.0.9 шелл читает только `shell.json:fontFamily`
   (`shell/services/Theme.qml:202-208`), а `Space Grotesk` и `Fraunces` не
   содержат кириллицы (`fc-list :charset=0410` — пусто), `Space Mono` не
   установлен. По решению «при провале — mono» интерфейс оставлен на моно.
6. **niri** не проверялся: в README честно «скоро».

## ANSI терминала: ограничение движка 1.0.9

- Цвета терминала (`~/.cache/ryoku/colors.json`) пишет движок темы из шести
  ролей активной схемы; `palette.json` риса и блок `terminal` в схеме на них не
  влияют. Проверено: после `rice apply moon` при активной теме `moon` файл
  остался с производными (`color1 #A84840`, `color8 #2A2A2E`); переключение
  `Default` → `moon` тоже даёт производные (`color8 #2A2A2E`); у
  `hancore-blackturq` живой `color8` = `#485362`, то есть его собственный
  `terminal.bright.black #322F3B` тоже не используется.
- Следствие: у монохромной Moon `color8` = `mOutline` = `#2A2A2E` → 1.4:1 на
  фоне, приглушённый текст в терминале почти не виден. Это поведение движка, а
  не манифеста риса; варианты для Алана: (а) принять и держать свой профиль
  терминала (в `rices/moon/palette.json` все цвета, кроме `color0`, проходят AA
  на `#0B0B0D`); (б) поднять `mOutline` в `src/palette.json` до `#84848D` —
  тогда `color8` станет 5.3:1, но волосяные линии карточек станут заметно
  светлее и «тихий» вид потеряется.
- Сама рис-палитра исправлена: `color8` был 3.89 (ниже AA) → `#84848D` (5.31),
  `check-contrast.py` теперь проверяет все 15 ANSI-цветов на фоне терминала,
  `dist/scheme.json` собирается с блоком `terminal`.

## Что осталось сделать (и почему не сейчас)

- `poster.png` + скриншоты 3440×1080 и 1920×1080 с чистого профиля — отложены
  Аланом; без них нельзя закрыть `preview` риса и карточку Store.
- Публикация: рис + тема одним PR, плагин отдельным — только после «добро».
- P6-опции (lockscreen, decor, launcher-image, fastfetch, виджеты сцены, fork
  `moon-ultrawide`) — отдельные записи и отдельная поддержка, не начаты.

## Процесс

Ревью каждой фазы субагентом-ревьюером (максимум 2 круга) и финальное
адверсариальное ревью — результаты и исправления перечислены ниже по мере
закрытия.
