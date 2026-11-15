# Moon — установка, откат, настройка

Moon — это три отдельные записи, каждая ставится сама по себе: полный рис `moon`
(бар sumi, рамка, палитра, обои), схема `Moon` (16 Material-ролей + заявленный блок terminal) и
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
  его читает `sumi`): левый — `quick-settings`, `workspaces`, `music`,
  `notifications`, док, `tray`, `audio-output`, `bluetooth`, `network`, `clock`,
  `battery`. Правый рейл выключен осознанно: он дублировал статусы и уведомления,
  которые и так приходят карточками и колоколом, а один рейл держит один столбец
  внимания (разбор — вкладка «Sumi» на сайте брифа). Блок `look.shell.bars.*` в рисе — наследие старых схем: в
  1.0.9 его не читает ни шелл, ни `ryoku-hub` (`qsbar` берёт раскладку из
  `shell.json → qsbar.layout`), поэтому на вид он не влияет.
- **Тема:** `moon`, `followWallpaper: false` (монохром не плывёт за обоями),
  палитра из `palette.json` (16 ролей + terminal; как её видит система — см.
  «Терминал» ниже).
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

Известный дефект 1.0.9 (проверено 14.11.2026): `restore previous` не возвращает
блок оформления окон. `~/.config/ryoku/desktop.json` после отката остаётся без
`desktop.appearance` (было 6313 байт, стало 72), и живые значения падают на
модульные: гэпы 12/18, граница 2, радиус 0, blur включён — проверяйте
`hyprctl getoption decoration:rounding` и Hub → Appearance. Лечится так: перед
применением риса сохраните `~/.config/ryoku/desktop.json`, после отката верните
его на место и примените:

```sh
ryoku-hub desktop preview "$(cat ~/.config/ryoku/desktop.json)"
```

Схема:

```sh
ryoku-shell theme Default      # вернуться на встроенную схему
```

Отдельной команды удаления схемы в 1.0.9 нет (`ryoku-shell theme` принимает
только id схемы или `catalog`): чтобы убрать Moon совсем, удалите каталог
`~/.local/share/ryoku/themes/moon`.

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
| рейлы `sumi` (что где стоит) | Ryoku Hub → **Bar Studio** — он правит `frameBars`, из которого `sumi` рисует рейлы |
| виджеты и позиции QS Bar (стили `qsbar`/`orpheus`) | QS Bar Settings (`Super+comma` → Bar) или `ryoku-shell bar ...` |
| обои | `Super+W` |

Тёплый вариант палитры — `Moon Warm` (селенит `#E3CFA6`): он собирается из
`src/palette.warm.json` в `colorschemes/Moon Warm/` и в v1 по умолчанию не
ставится. Поставить самому:

```sh
./tools/build-rice.sh
mkdir -p ~/.local/share/ryoku/themes/moon-warm
python3 - <<'PY'
import json
src = "colorschemes/Moon Warm/Moon Warm.json"
dst = __import__("os").path.expanduser("~/.local/share/ryoku/themes/moon-warm")
scheme = json.load(open(src))["dark"]
json.dump({"dark": scheme}, open(dst + "/scheme.json", "w"), indent=2)
json.dump({"label": "Moon Warm", "provider": "Alan"}, open(dst + "/meta.json", "w"), indent=2)
PY
ryoku-shell theme catalog | grep -i "moon warm"   # id = имя каталога
ryoku-shell theme moon-warm
```

Формат темы ровно такой, как у уже стоящей `moon`: каталог
`~/.local/share/ryoku/themes/<id>/` с `scheme.json` (`dark`) и `meta.json`.

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

Рис просит три голоса: `primary` — Space Grotesk, `secondary` — Space Mono,
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
- хотите посмотреть варианты у себя: `otf-space-grotesk` есть в репозитории
  Ryoku (`pacman -S otf-space-grotesk`), Fraunces у вас лежит локальным пакетом
  `ttf-fraunces-variable` (в подключённых репозиториях его нет —
  `pacman -Si ttf-fraunces-variable` → not found, ставьте из AUR/локально);
  Space Mono есть как `ttf-space-mono-nerd`, но **кириллицы в нём нет**
  (`fc-query` не находит U+0410) — для русского берите моно с кириллицей,
  например уже стоящий JetBrains Mono. Менять шрифт — Hub → Appearance.

## Обои

Обои в рис входят отдельным файлом (`rices/moon/wall.webp`), но в Ryoku 1.0.9
рис не переставляет обои: `ryogami` остаётся на прежнем `lastAppliedKey`. Пока
это так, обои ставятся руками — `Super+W` или

```sh
ryogami wallpaper set /путь/к/картинке
```

Финальный ассет для Moon пришёл от автора (Алан, 15.11.2026): ангел с гало и
серпом Луны. Он лежит в `rices/moon/wall.webp` (3440×1440) и в `refs/walls/`
как исходник 4K; карточка Store снята уже на нём.

## Терминал: почему ANSI-цвета не из риса

В 1.0.9 цвета терминала (`~/.cache/ryoku/colors.json`) всегда выводит движок
темы из шести ролей активной схемы; `palette.json` риса и блок `terminal` в
схеме на них не влияют (проверено: `apply` риса при активной теме `moon` не
меняет `colors.json`, переключение `Default` → `moon` тоже берёт производные).
У монохромной Moon «яркий чёрный» (`color8`) получается равным `mOutline`
(`#2A2A2E`) — это 1.4:1 на фоне, то есть приглушённый текст в терминале почти не
виден. Рис на это не влияет; если нужны читаемые ANSI — возьмите
`rices/moon/palette.json` как тему терминала у себя (в нём все цвета, кроме
`color0`, держат AA на `#0B0B0D`).

## Часы и Луна на сцене (`moon`)

Один виджет на обоях: кольцо синодического месяца (30 волосяных делений,
светлая риска — полнолуние), метка на кольце — маленький серп текущей фазы,
внутри время, под циферблатом название фазы (Fraunces) и процент.
Это не своё окно: плагин монтируется в существующий слой виджетов Ryoku
(`ryoku-widgets`), перерисовка раз в минуту, анимаций нет.

```sh
ryoku plugin add /путь/к/moon-ryoku/plugins/moon --yes
ryoku-plugins-place moon host desktopWidget
ryoku-plugins-place moon desktopWidget 2528 420 1
```

Настройки: `showPhase`, `showPercent`.

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

## Карточка Store и что именно уезжает в репозиторий магазина

Карточка — реальный снимок рабочего стола с печатью 月, словом MOON и подписью
(`rices/moon/assets/preview.webp`, 1600×900). Делается скриптом из снимка:

```sh
grim /tmp/moon-clean.png                          # пустой воркспейс, курсор в угол
python3 tools/make-card.py /tmp/moon-clean.png rices/moon/assets/preview.webp
python3 tools/build-store.py                      # dist/store/rices/moon/
```

Обои риса из своего исходника (монохром, холодная тень, зерно):

```sh
python3 tools/make-wall.py ~/Pictures/Wallpapers/Angel1.png refs/walls/angel1-moon-candidate.webp \
    --width 3440 --ratio 16:9 --side center
```

`tools/build-store.py` собирает запись магазина: `rice.json` с полями
`id/category/version/destination/files` и хешами, `palette.json`, `wall.webp` и
`assets/preview.webp` (install false), плюс готовый `registry-entry.json`
(`official: false`, `upstream`, `lastUpdated`). Проверка на клоне магазина:

```sh
# в клон магазина едут только файлы риса, без самого registry-entry.json
mkdir -p /путь/к/ryostore/rices/moon/assets
cp dist/store/rices/moon/rice.json dist/store/rices/moon/palette.json \
   dist/store/rices/moon/wall.webp /путь/к/ryostore/rices/moon/
cp dist/store/rices/moon/assets/preview.webp /путь/к/ryostore/rices/moon/assets/
# запись из dist/store/rices/moon/registry-entry.json добавляется в rices/registry.json
cd /путь/к/ryostore && python3 tests/validate-store.py --root . --categories rices --require-media
cd /путь/к/ryostore && tests/validate-catalogue.sh
```

Строгий `--require-media` (превью ≥ 1280×720) гоняется только по `rices`: у
части чужих плагинов в магазине превью мелкие, и прогон с этим флагом красный не
из-за нас. Полный `tests/validate-catalogue.sh` — без флага.

## Публикация

В магазин ничего не выгружено. Порядок, когда будет «добро»: рис + тема одним
PR, плагин — отдельным. Для риса: `tools/build-store.py --wallpaper-url
<Release-ассет тега rices>` (с URL обои не ставятся из папки риса, а тянутся
ссылкой) → скопировать файлы и запись в клон → `validate-store.py --require-media
--categories rices` и `tests/validate-catalogue.sh` → PR. Плагин:
`ryoku plugin export` → `ryoku plugin share moon-phase`. Оба шага требуют
явного «добро».

Карточка сейчас снята на текущих обоях автора; когда появится финальный ассет
Moon, её нужно переснять тем же `tools/make-card.py` — иначе карточка обещает не
те обои.
