# lunarcustom — план проекта «Moon» для Ryoku

**Цель:** лунное оформление рабочего стола, которое ставится из Ryoku Store одним
нажатием и разбирается на куски, каждый из которых живёт своей записью в магазине.
**Владелец:** Алан. **Исполнитель:** LunarAI. **Базис:** Ryoku 1.0.9 Amaterasu,
Hyprland 0.57.2 (+ niri), стиль бара `sumi` (встроенный: рамка + рейлы).
**Статус:** P0–P2 закрыты (у P2 открыты обои), следующий шаг — P3 (плагин).
**Дизайн-язык:** [`docs/DESIGN.md`](DESIGN.md) — разбор типографики, цвета, геометрии и движения Ryoku.

## 1. Что выпускаем

| Артефакт | Каталог магазина | Что это | Приоритет |
|---|---|---|---|
| `moon` | `rices` | полный лук: sumi + рамка + рейлы, палитра, обои | P2 ✅ (обои — P4) |
| `Moon` | `colorschemes` («Themes») | палитра 16 Material-ролей + terminal, работает и без риса | P1 ✅ |
| `moon-phase` | `plugins` | виджет фазы Луны в баре, считается локально | P3 |
| `Moon Rail` | `barstyles` | отдельный folder style для тех, кто хочет только бар | P6, опция |
| `moon` lock/decor/hero | `lockscreens`, `decors`, `launcher-images` | добивка образа | P6, опция |

Ограничения магазина, принятые как данность:
- рис **не может** ссылаться на куски (нет поля зависимостей) — рис обязан быть
  самодостаточным;
- в `bundle` рис положить нельзя (только package / script / plugin / nautilus-pack);
- `barstyles` в магазине — folder styles, рис на них не ссылается; поэтому рис
  остаётся на встроенном `sumi`;
- `official: false` для всего нашего, `upstream` обязателен;
- контент, требующий одного WM, помечается `windowManager` + `windowManagerReason`.

### 1.1. Дизайн-система Ryoku, которую наследуем

Разбор — `docs/DESIGN.md`. Для риса берём то, что делает систему цельной, и
отбрасываем чужой бренд.

| Что | Берём | Не берём |
|---|---|---|
| Сетка | 4 / 8 / 12 / 16 / 24 / 32 / 48, строка 48, контроль 26 | micro-шкалу шелла 2–18 для крупных блоков |
| Геометрия | радиус 6, border 1, глубина рамкой и волосом | радиус 0 и жёсткие тени 6/8 (пройденный постерный слой) |
| Цвет | paper/ink-тиры (inkMuted .88, inkFaint .68), линии .26/.13/.42, заливки .05/.10/.16, **один акцент** | vermillion `#e2342a` и золото `#d9a441` — бренд Ryoku, не Moon |
| Типографика | три голоса: Fraunces (дисплей), Space Grotesk (UI), SpaceMono (метки); шелл — системный mono | Inter Display 200 и Iosevka из веб-брифа |
| Движение | 90 hover, 110 значение, 170 селектор, 210 смена контента, 250 в шелле, 600–800 рамка; OutCubic/OutQuad | M3-кривые для наших поверхностей (они не анимируются через Tokens) |
| Иконография | печать 月 вместо пиктограммы, один знак | набор иероглифов, «японский шум» |
| Арт | зерно 0.10 только на превью и обложке | зерно под текстом настроек |
| Масштаб | уважение `motionScale` и `reduceMotion` через свои токены | per-monitor `uiScale` — это уже делает шелл |

Итог: Moon — лунная калька системы Ryoku, а не отдельный стиль. Всё, что видит
пользователь, кроме цвета, печати и обоев, он уже видел в Hub и Store.

## 2. Структура репозитория

```
moon-ryoku/                      # отдельный git-репо, MIT
  rices/moon/
    rice.json                    # минимальный манифест (не полный capture)
    palette.json                 # 16 ролей, т.к. color: fixed
    poster.png                   # 16:9, реальный скриншот
    screenshots/01.webp …        # галерея
  colorschemes/Moon/
    Moon.json                    # dark (+ light, опционально)
  plugins/moon-phase/
    manifest.json
    service/Main.qml             # логика и состояние, без UI
    content/Widget.qml           # вид на баре
    README.md  LICENSE  assets/preview-widget.png
  src/                           # единственный источник истины
    palette.json  tokens.json  rice.override.json
  tools/
    build-rice.py                # src -> rices/moon/rice.json + palette.json + санитайзер
    build-rice.sh                # src -> colorschemes/Moon/* и dist/
    check-contrast.py            # AA для текста и UI
    shoot.sh                     # скриншоты с чистого профиля
    validate.sh                  # import + apply/restore + схемы + validate-catalogue
  docs/README.md  CHANGELOG.md  MAINTAINING.md
```

Правило: `rices/moon/rice.json` и `colorschemes/Moon/Moon.json` **генерируются**
из `src/`; руками не правятся. Это единственный способ держать рис и тему
синхронными.

## 3. Фазы

### P0 — решения и скелет (0.5 дня)
- Зафиксировать: слаг `moon`, палитра холодная (`#E7E9EE`), цель — оба WM.
- `git init`, MIT, README с политикой поддержки, каталоги из §2.
- **Гейт:** дерево создано, решения записаны в `docs/README.md`, лицензия на месте.

### P1 — палитра и токены (0.5 дня)
- `src/palette.json`: 16 ролей формата магазина (`mSurface #0B0B0D`, `mOnSurface
  #F4F4F6`, `mPrimary #E7E9EE`, `mSecondary #C9CBD2`, `mTertiary #9EA2AB`, `mError
  #B4534B`, `mOutline #2A2A2E`, `mShadow #000000`) + terminal (16 ANSI) + **альфы
  состояний** из Ryoku (fill `.04/.08/.18/.22`, border `.4/.25`).
- `src/tokens.json`: сетка приложений Ryoku (4/8/12/16/24/32/48, row 48, rail 268,
  content 1000), радиус 6, border 1, shadow off, `barSeps` G1/G2,
  `tray.monochromeIcons: true`; типографика: Fraunces (дисплей), Space Grotesk (UI),
  SpaceMono (метки), трекинг 1.4/2.2; шелл — системный mono (не форсим).
- **Гейт:** `check-contrast.py` — текст ≥ 4.5:1, UI ≥ 3:1; `Moon.json` ставится и
  виден в `Super+W`.

### P2 — рис (1 день)
- Собираем `rice.json` из шаблона + override, **не** `capture` целиком.
  Владеем только: `look.hypr.appearance`, `look.wm.{hyprland,niri}` (тонкие границы,
  без blur), `look.shell` = `{barStyle:"sumi", bars (оба рейла осмысленно заполнены),
  theme, launcher, stage}`, `look.theme`, `assets.{wallpaper,cursor}`, `color: fixed`.
- Не владеем: `look.profile`, `look.plugins`, `look.widgets` координаты, `appOverrides`,
  списки мониторов, `aiTools`, погодные локации, любые пути.
- **Гейт:** `ryoku-hub rice import rices/moon` → `apply moon` на чистом профиле →
  визуально = скриншот → `restore previous` возвращает исходное. Скриншоты на
  3440×1440 и 1920×1080. ~~Пройден 14.11.2026: откат вернул конфиг байт-в-байт.~~
- **Открыто:** обои v1 (3440×1440 из рендера Луны) отклонены Аланом — не годятся.
  Переделать в P4: композиция (луна не «в правом углу», а часть кадра), масштаб,
  зерно и вигнет, вариант 1920 и 3440. Плюс починить, что рис не ставит обои:
  `ryogami` остаётся на прежнем `lastAppliedKey`.

### P3 — плагин `moon-phase` (1.5–2 дня)
- Живая фаза по разности эклиптических долгот (проверенная формула из брифа),
  подпись с процентом, клик — «следующее полнолуние»; обновление раз в минуту.
- Без сети, без `sudo`, без обращений к композитору, без чтения чужих файлов;
  настройки: `showPercent`, `size`, `label`.
- **Гейт:** `ryoku plugin validate` зелёный, `ryoku plugin add --bar --yes`,
  CPU < 0.2 %, ошибок в логе нет, reduced-motion уважается.

### P4 — упаковка и публикация (0.5–1 день)
- Скриншоты с чистого профиля (без личных файлов, хостов, токенов), poster 16:9.
- `docs/README.md`: что меняется, как откатить, как настроить под себя (fork).
- Печать 月 в бренд-блоке и на карточке Store; зерно только на арте, не под текстом.
- Записи `registry.json` генерируются скриптом; в клоне магазина
  `tests/validate-catalogue.sh` → `catalogue OK`.
- Публикация: `ryoku-hub rice publish moon /path/to/ryostore` → обои/hero в Release
  тег `rices` → PR (или форма сабмита, если PR не выйдет).
- **Гейт:** PR открыт, CI зелёный, чек-лист §6 закрыт.

### P5 — поддержка (постоянно)
- После каждого релиза Ryoku: `ryoku update` → smoke `apply`/`restore` → бамп
  `version`, `createdWith`, `lastUpdated` → PR.
- Следить за issues, держать `upstream` живым; если не тянем — сказать команде и
  снять item, а не оставлять сломанным.

### P6 — расширение (опция)
- `colorschemes/Moon Warm` (селенитовый `#E3CFA6`), lockscreen, decor, launcher-image,
  fastfetch-пресет. Каждый — отдельная запись, отдельный PR, отдельная поддержка.

## 4. Что именно владеет рис (whitelist для санитайзера)

```
look.hypr.appearance      rounding, gaps, border, shadow, blur off, animations
  (capture 1.0.9 не пишет look.wm — рис его не содержит; WM-настройки не трогаем)
look.shell.barStyle       "sumi"
look.shell.bars.left_bar  launcher, workspaces, clock
look.shell.bars.right_bar audio, network, battery, status, tray
look.shell.theme          монохром, reduce motion off
look.launcher             {} (раскладку пользователя не трогаем)
look.theme                followWallpaper false (fixed)
  (печать 月 в 1.0.9 в рис не попадает — только в Store-карточку на P4)
assets.wallpaper, assets.cursor
color: fixed + palette.json
```

Всё остальное — вне whitelist; санитайзер в `build-rice.py` валит сборку при любом лишнем ключе,
пути `/home/`, IP, hostname, токене.

## 5. Команды (проверено на 1.0.9)

```sh
ryoku-hub rice preflight                     # можно ли снимать/применять
ryoku-hub rice import rices/moon             # проверка и импорт локального риса
ryoku-hub rice apply moon                    # применить (с бэкапом)
ryoku-hub rice restore previous              # откат
ryoku-hub rice export moon /tmp/moon-export  # портативная копия
ryoku-hub rice publish moon /path/to/ryostore
ryoku plugin validate plugins/moon-phase
ryoku plugin add plugins/moon-phase --bar --yes
tests/validate-catalogue.sh                  # из клона ryostore
```

## 6. Критерии готовности (definition of done)

1. `apply` на чистом профиле не ломает локскрин, раскладку, bluetooth/сеть.
2. `restore previous` возвращает состояние до риса на 100 %.
3. Ноль личных данных и ноль ключей вне whitelist (CI-проверка).
4. Контраст AA: текст ≥ 4.5, UI ≥ 3.
5. Плагин: без сети, sudo, композитора; CPU в покое < 0.2 %.
6. Скриншоты реальные, с чистого профиля, 3440 и 1920.
7. `catalogue OK` + зелёный PR; `official:false`, `upstream`, `lastUpdated`.
8. README: как поставить, как откатить, как форкнуть и что менять.

## 7. Риски

| Риск | Как закрываем |
|---|---|
| Схема рис-манифеста меняется между релизами | минимальный манифест + smoke после каждого `ryoku update` |
| `sumi` переименуют/уберут | fallback `orpheus` по коду + `createdWith` и заметка в README |
| Личные данные в capture | whitelist-санитайзер валит сборку |
| Нет зависимостей у кусков | рис самодостаточен, куски — бонус в README |
| Долгий ревью магазина | сначала рис, потом тема, плагин последним |
| Требование «без WM в коде» | плагин только на Quickshell API, без `hyprctl` |
| Лицензии обоев | свои или NASA PD с кредитом в README |
| niri не проверен | тест-матрица: apply/restore на обоих WM |

## 8. Открытые решения (за Аланом)

1. Палитра в v1: только холодная или сразу пара (Moon / Moon Warm)?
2. Ультравайд-вариант: отдельный fork-рис `moon-ultrawide` или основным?
3. Плагин: только в баре, или ещё виджет на сцене (две точки входа)?
4. Локскрин в v1 включаем или откладываем?
5. Лицензия: MIT (по умолчанию) — ок?
6. ~~Радиус: 6 (как в Hub/Store)~~ — решено: 6.
7. ~~Печать бренда~~ — решено: 月 (универсально: луна и месяц).
8. ~~Шрифт шелла~~ — решено: остаётся как есть (JetBrains Mono 15 px), семейство рис не форсит.
9. ~~Плотность~~ — решено: база 15 px.
10. ~~Лицензия~~ — решено: MIT.

## 9. Вне рамок

Не трогаем Cutive Mono Cyrillic V7 и старый райс LunarEclipse. Не меняем системные
пакеты ради риса. Не публикуем, пока чек-лист §6 не зелёный. Не тащим зависимости
от магазинных barstyles.
