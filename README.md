# moon-ryoku

Лунное оформление Ryoku для магазина: полный рис `moon`, палитра `Moon` и плагин
`moon-phase` — как отдельные записи, чтобы люди брали целиком или по частям.

**Статус:** P0 закрыт, следующий шаг — P1 (палитра и токены).
**План:** [`docs/PLAN.md`](docs/PLAN.md) · **Решения:** [`docs/DECISIONS.md`](docs/DECISIONS.md)

## Продукты

| Артефакт | Каталог | Что | Этап |
|---|---|---|---|
| `moon` | `rices` | весь лук: sumi + рамка + рейлы, палитра, обои | P2 |
| `Moon` | `colorschemes` | палитра 16 Material-ролей + terminal | P1 |
| `moon-phase` | `plugins` | фаза Луны в баре, считается локально | P3 |
| `Moon Rail` | `barstyles` | только бар, опция | P6 |
| lock / decor / hero | — | добивка образа, опция | P6 |

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
- [ ] `src/palette.json`: 16 ролей + terminal 16 ANSI
- [ ] `src/tokens.json`: rounding 2–3, gaps 16, border 2, shadow off, barSeps G1/G2, mono tray
- [ ] `colorschemes/Moon/Moon.json` из `src/palette.json`
- [ ] `tools/check-contrast.py`: текст ≥ 4.5, UI ≥ 3
- [ ] гейт: схема ставится и видна в `Super+W`

### P2 — рис
- [ ] `src/rice.override.json` + `tools/build-rice.sh`
- [ ] `rices/moon/rice.json` из шаблона, не полный capture
- [ ] `tools/sanitize.jq`: whitelist ключей, запрет путей/IP/hostname/токенов
- [ ] обои и курсор в `rices/moon/`, `color: fixed` + `palette.json`
- [ ] гейт: `import` → `apply` на чистом профиле → `restore previous`, скриншоты 3440/1920

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
