# Moon — установка, откат, настройка

Moon — это три отдельные записи, каждая ставится сама по себе: полный рис `moon`
(бар sumi, рамка, палитра, обои), схема `Moon` (16 Material-ролей + terminal) и
плагин `moon-phase` (фаза Луны в баре). Рис и тему можно взять вместе, плагин —
отдельно.

## Что внутри

| Запись | Каталог магазина | Что делает |
| --- | --- | --- |
| `moon` | Rices | бар `sumi` (две рейки), рамка 2 px, радиус 6, гэпы 12, без blur и тени, тема `moon`, `color: fixed` |
| `Moon` | Themes (`colorschemes`) | холодная палитра: `mSurface #0B0B0D`, `mPrimary #E7E9EE`; работает и без риса |
| `moon-phase` | Plugins | серп Луны и процент освещённости; карточка с фазой и следующим полнолунием |

## Внутри: что именно меняет рис

- **Геометрия окна:** граница 1 px, радиус 6, гэпы 12, без blur, без тени,
  анимации включены, неактивное окно плавно гаснет до 0.92.
- **Бар:** стиль `sumi` (встроенный: рамка по краям + вертикальные рейлы), толщина
  2 px, угол 0. Состав рейлов задаётся в `look.shell.frameBars.rails` (именно
  его читает `sumi`): левый — `quick-settings`, `workspaces`, `music`, док,
  `tray`, `audio-output`, `bluetooth`, `network`, `clock`, `battery`; правый —
  `notifications`. Параллельно заполнены `look.shell.bars.*` — это модель QS
  Bar, она нужна тем, кто сидит на `qsbar`/`orpheus`.
- **Тема:** `moon`, `followWallpaper: false` (монохром не плывёт за обоями),
  палитра из `palette.json` (16 ролей + terminal).
- **Не трогает:** профиль, плагины, координаты виджетов сцены, `appOverrides`,
  мониторы, погоду, пути — всё это остаётся вашим.

## Установка

Через Hub: **Store → нужный каталог → Moon / Moon Phase → Install**, затем
применить рис (**Rices → Moon → Apply**) и включить схему (`Super+W` или
Store → Themes → Moon).

То же из терминала:

```sh
ryoku-hub rice import /путь/к/moon-ryoku/rices/moon   # только абсолютный путь
ryoku-hub rice apply moon
ryoku plugin add /путь/к/moon-ryoku/plugins/moon-phase --bar --yes
ryoku-shell theme moon
```

Перед применением риса можно спросить, всё ли готово: `ryoku-hub rice preflight`.

## Откат

Рис:

```sh
ryoku-hub rice restore previous
```

Команда возвращает `shell.json`, `theme.json` и `colors.json` к снимку, который
рис сделал перед применением. Если после установки вы что-то меняли руками —
эти правки пропадут, как и у любого риса.

Схема:

```sh
ryoku-shell theme Default     # вернуться на встроенную схему
ryoku-shell theme remove moon
```

Плагин:

```sh
ryoku plugin remove moon-phase
```

Если шелл после экспериментов выглядит странно, проверка одна:
`ryoku-shell barstyle sumi` (вернуть встроенный бар) и `ryoku-shell theme Default`.

## Настроить под себя

| Что | Где |
| --- | --- |
| гэпы, границы, радиусы | Ryoku Hub → Appearance |
| палитра | Store → Themes → **Moon** (или своя схема) |
| виджеты и позиции бара | QS Bar Settings (`Super+comma` → Bar) или `ryoku-shell bar ...` |
| обои | `Super+W` |

Своя копия риса, которую обновления не перетирают:

```sh
ryoku-hub rice fork moon
```

`fork` кладёт копию в `~/.config/ryoku/rices/<новый-слаг>`; правьте её и
применяйте как обычный рис. `rices/moon/rice.json` и
`colorschemes/Moon/Moon.json` в репозитории генерируются из `src/` — если
хотите менять их у себя, меняйте `src/` и собирайте: `python3 tools/build-rice.py`
и `./tools/build-rice.sh`.

## Шрифты

Рис просит три голоса: `primary` — Space Grotesk, `secondary` — SpaceMono,
`tertiary` — Fraunces (поле `look.shell.theme.attributes.font`).

Честно про 1.0.9:

- шрифт интерфейса шелла берётся не из `theme.attributes.font`, а из
  `shell.json` → `fontFamily` (см. `shell/Theme.qml`: `fontPrimary` читает
  `Config.fontFamily`, а `fontSecondary`/`fontTertiary` жёстко равны primary).
  Поэтому три голоса в шелле сейчас не разносятся, и рис их не «включает» —
  трио в рис записано как заявленное намерение, интерфейс остаётся на моно;
- гейт 15 px провален по покрытию: в Space Grotesk и Fraunces нет кириллицы
  (`fc-list :charset=0410` не находит ни одного из них, а JetBrains Mono
  находит), Space Mono в системе не установлен. Русский текст в интерфейсе
  начал бы прыгать на подстановочный шрифт посреди строки, поэтому UI остаётся
  моно — это и есть оговорённый откат «при провале — mono»;
- хотите посмотреть варианты у себя: `otf-space-grotesk` и
  `ttf-fraunces-variable` есть в репозиториях, Space Mono ставится пакетом
  `ttf-space-mono`; менять шрифт — Hub → Appearance.

## Обои

Обои в рис входят отдельным файлом (`rices/moon/wall.webp`), но в Ryoku 1.0.9
рис не переставляет обои: `ryogami` остаётся на прежнем `lastAppliedKey`. Пока
это так, обои ставятся руками — `Super+W` или

```sh
ryogami wallpaper set /путь/к/картинке
```

Финальный ассет для Moon готовит автор (Алан); до него в репозитории лежит
временная картинка.

## Плагин и бар sumi

`moon-phase` — плагин хоста `topbarGlyph`. В Ryoku 1.0.9 такой виджет рисуется
на **QS Bar** (стили `qsbar`, `orpheus` и другие, которые собирают бар из списка
виджетов). Встроенный рейл `sumi` строится из фиксированного каталога
(`Ryoku/FrameBars/BarCatalog.js`) и мест для плагинов не имеет, поэтому на
`sumi` плагин стоит включённым, но не виден.

Проверить, где он реально рисуется:

```sh
ryoku-shell barstyle qsbar     # виджет появится справа
ryoku-shell bar list | grep moon-phase
ryoku-shell barstyle sumi      # вернуть рейл
```

Настройка одна: `showPercent` (показывать процент рядом с серпом) — ставится в
**Ryoku Settings → Add-ons → Plugins → Moon Phase**, либо
`ryoku-shell bar set moon-phase showPercent false`.

## niri

Поддержка niri заявлена, но проверка — отдельным заходом: скоро. Рис не трогает
настройки композитора (`look.wm` в нём нет), плагин к композитору не обращается
вовсе, так что ломаться там нечему — но и «проверено на niri» мы пока не пишем.

## Если что-то пошло не так

1. `ryoku-hub rice restore previous` — вернуть вид до риса.
2. `ryoku-shell theme Default` — вернуть схему.
3. `ryoku plugin remove moon-phase` — убрать плагин.
4. Лог шелла: `journalctl --user -u ryoku-shell -f` (ошибки QML видны сразу
   после установки плагина), полный лог — `~/.local/share/ryoku/.../log.qslog`.

## Публикация

В магазин ничего не выгружено. Порядок, когда будет «добро»: рис + тема одним
PR, плагин — отдельным; `ryoku-hub rice publish moon <клон ryostore>` и
`ryoku plugin share moon-phase`, затем `tests/validate-catalogue.sh` в клоне.
