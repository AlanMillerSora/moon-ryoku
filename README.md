# moon-ryoku

Лунное оформление Ryoku для магазина: полный рис `moon`, палитра `Moon` и плагин
`moon-phase` — как отдельные записи, чтобы люди брали целиком или по частям.

**Статус:** P1 закрыт, следующий шаг — P2 (рис).
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
- [ ] гейт: `apply` → проверка → `restore previous`, скриншоты 3440/1920 (нужен твой «ок», меняет вид на минуту)

### P3 — плагин `moon-phase`
- [ ] `manifest.json`, `service/Main.qml`, `content/Widget.qml`
- [ ] расчёт фазы (разность эклиптических долгот), обновление раз в минуту
- [ ] настройки `showPercent`, `size`, `label`; без сети, sudo и композитора
- [ ] гейт: `ryoku plugin validate` + `add --bar`, CPU < 0.2 %

### P4 — упаковка и публикация
- [ ] poster и скриншоты с чистого профиля
- [ ] `docs/README.md`: поставить, откатить, форкнуть
- [ ] `tests/validate-catalogue.sh` в клоне ryostore
- [ ] `ryoku-hub rice publish moon <ryostore>` + PR

### P5 — поддержка
- [ ] smoke `apply`/`restore` после каждого релиза Ryoku
- [ ] бамп `version`, `createdWith`, `lastUpdated`, CHANGELOG

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
