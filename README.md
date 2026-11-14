# moon-ryoku

Лунное оформление Ryoku для магазина: полный рис `moon`, палитра `Moon` и плагин
`moon-phase` — как отдельные записи, чтобы люди брали целиком или по частям.

**Статус:** P1 и P2 закрыты (обои ждут ассет Алана), P3 закрыт, P4 — без публикации.
**Репозиторий:** https://github.com/AlanMillerSora/moon-ryoku (public, MIT).
**План:** [`docs/PLAN.md`](docs/PLAN.md) · **Решения:** [`docs/DECISIONS.md`](docs/DECISIONS.md) · **Дизайн-язык:** [`docs/DESIGN.md`](docs/DESIGN.md)

## Продукты

| Артефакт | Каталог | Что | Этап |
|---|---|---|---|
| `moon` | `rices` | весь лук: sumi + рамка + рейлы, палитра, обои | P2 |
| `Moon` | `colorschemes` | палитра 16 Material-ролей + terminal | P1 |
| `moon-phase` | `plugins` | фаза Луны в баре, считается локально | P3 |
| `Moon Rail` | `barstyles` | только бар, опция | P6 |
| lock / decor / hero | — | добивка образа, опция | P6 |

## Дизайн-основа

Берём систему Ryoku, а не свой стиль: сетка 4/8/12/16/24/32/48, строка 48,
радиус 6, border 1, глубина рамкой и волосом; типографика в три голоса — Fraunces
(дисплей), Space Grotesk (UI), SpaceMono (метки), шелл на системном mono; цвет —
paper/ink-тиры (`.88`, `.68`), линии `.26/.13/.42`, заливки `.05/.10/.16` и
**один** акцент `#E7E9EE`; печать бренда — 月; зерно 0.10 только на арте.
Свой бренд Ryoku (vermillion, золото, жёсткие тени, радиус 0) не тащим.
Подробно: [`docs/DESIGN.md`](docs/DESIGN.md), сводка — `docs/PLAN.md` §1.1.

## Как ведём прогресс

Правило простое: **выполненный пункт зачёркивается (`~~текст~~`), а не удаляется.**
Зачёркивание ставится только после прохождения гейта этапа. Новые пункты
добавляются в конец своего этапа.

### P0 — скелет и решения
- ~~создать репозиторий и дерево каталогов по плану~~
- ~~лицензия MIT, README, CHANGELOG~~
- ~~зафиксировать решения: слаг `moon`, холодная палитра, оба WM~~ → `docs/DECISIONS.md`
- ~~политика поддержки и авторства в `docs/DECISIONS.md`~~

### P1 — палитра и токены
- ~~`src/palette.json`: 16 ролей + terminal 16 ANSI + альфы состояний~~
- ~~`src/tokens.json`: сетка 4/8/12/16/24/32/48, row 48, радиус 6, border 1, shadow off, barSeps G1/G2, mono tray~~
- ~~типографика: Fraunces / Space Grotesk / SpaceMono, трекинг 1.4 и 2.2; шелл — системный mono~~
- ~~`colorschemes/Moon/Moon.json` и `registry-entry.json` генерируются из `src/palette.json`~~
- ~~`tools/check-contrast.py`: текст ≥ 4.5, UI ≥ 3 — все пары проходят~~
- ~~гейт: схема установлена локально и видна в каталоге `ryoku-shell theme catalog` (не применялась)~~

### P2 — рис
- ~~`src/rice.base.json` (схема 1.0.9) + `src/rice.override.json` + `tools/build-rice.py`~~
- ~~`rices/moon/rice.json` собран из whitelist, 4.3 КБ вместо 179 КБ capture~~
- ~~санитайзер внутри сборки: whitelist ключей, запрет `/home/`, IP, hostname~~
- ~~обои 3440×1440 (`wall.webp`) и `palette.json`, `color: fixed`~~
- ~~импорт в каталог: `rice list` → `moon compat=ok`~~
- [ ] печать 月: capture 1.0.9 больше не пишет `layers` — перенесена в бренд Store-карточки (P4)
- ~~гейт: `apply` → `restore previous`; откат вернул `shell.json`, `theme.json` и `colors.json` байт-в-байт~~
- [ ] обои: ассет делает Алан (фото или генерация), рис ждёт файл
- [ ] находка гейта: обои риса не применились (`ryogami` оставил прежний `lastAppliedKey`), чинить в P4
- [ ] скриншоты 3440/1920 — отложены отдельным заходом
- [ ] niri: указать в README «скоро», проверка отдельным заходом

### P3 — плагин `moon-phase`
- ~~`manifest.json`, `service/Main.qml`, `content/Widget.qml`, `content/Panel.qml`~~
- ~~расчёт фазы (разность эклиптических долгот), обновление раз в минуту~~
- ~~настройки `showPercent`; без сети, sudo и композитора~~
- ~~`ryoku plugin validate` → 0 blocking, 0 warnings; `add --bar` → `bar list` показывает `moon-phase plugin shown`~~
- ~~`preview-widget.png` — настоящий снимок с бара (`grim -s 2`, 106×84)~~
- ~~проверка панели: рендер с живым сервисом и Ryoku-темой, данные верные~~
- ~~найден и исправлен дефект: `property int synodicDays` роняло компиляцию сервиса → виджет всегда показывал 0 %~~
- ~~CPU-гейт: дельта 0.01 с за 60 с = 0.017 % ядра (плагин на баре, 60 с с/без)~~

### P4 — упаковка и публикация
- [ ] poster и скриншоты с чистого профиля — отложены Аланом
- ~~`docs/README.md`: поставить, откатить, форкнуть, шрифты, обои, ограничения~~
- ~~`tests/validate-catalogue.sh` в клоне ryostore: запись плагина проходит (`store catalogue OK`)~~
- [ ] запись риса в магазине — ждёт настоящий preview (скриншоты)
- [ ] `ryoku-hub rice publish moon <ryostore>` + PR — только по «добро» Алана
- ~~шрифты: трио записано в рис, гейт 15 px провален по кириллице → UI на mono (откат по решению)~~
- ~~рейлы sumi: рис теперь владеет `look.shell.frameBars.rails` (левый + правый)~~
- ~~доска прогресса и `docs/MAINTAINING.md` (процедура поддержки)~~

### P5 — поддержка
- ~~процедура после релизов Ryoku: `docs/MAINTAINING.md` (smoke apply/restore, тема, плагин, бамп версий, PR)~~
- [ ] первый реальный прогон процедуры на следующем релизе Ryoku

### P6 — расширение (опция)
- [ ] `Moon Warm` (селенит `#E3CFA6`)
- [ ] lockscreen, decor, launcher-image, fastfetch

## Структура

```
rices/moon/          rice.json, palette.json, poster.png, screenshots/
colorschemes/Moon/   Moon.json
plugins/moon-phase/  manifest.json, service/, content/, assets/
src/                 единственный источник истины (palette, tokens, override)
tools/               build, sanitize, contrast, shoot, validate
docs/                PLAN.md, DECISIONS.md, README.md, MAINTAINING.md
```

`rices/moon/rice.json` и `colorschemes/Moon/Moon.json` генерируются из `src/` и
руками не правятся.

## Команды

```sh
ryoku-hub rice preflight
ryoku-hub rice import rices/moon
ryoku-hub rice apply moon
ryoku-hub rice restore previous
ryoku plugin validate plugins/moon-phase
tests/validate-catalogue.sh        # из клона ryostore
```

Лицензия: MIT (`LICENSE`). Автор: Alan. Плагин и записи помечаются `official: false`.
