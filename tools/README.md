# tools

| Скрипт | Этап | Задача |
|---|---|---|
| `check-contrast.py` | P1 | AA для всех `src/palette*.json`: текст ≥ 4.5, UI ≥ 3, все 15 ANSI на фоне терминала |
| `build-rice.sh` | P1 | `src/palette*.json` → `colorschemes/<Name>/*` + `dist/scheme.json` (с блоком `terminal`) |
| `build-rice.py` | P2 | `src/rice.base.json` + `src/rice.override.json` → `rices/moon/rice.json` + `palette.json`; санитайзер: whitelist, базовая схема, `/home/`, IP, hostname, токены, ключи вида `api_key` |
| `make-card.py` | P4 | настоящий снимок → карточка магазина 1600×900: печать 月, MOON, подпись, зерно |
| `build-store.py` | P4 | `rices/moon` → `dist/store/rices/moon`: манифест магазина с хешами + `registry-entry.json` |
| `pack-product.py` | P4 | не в репозитории: лежит в клоне `ryostore`, пересчитывает `product-manifest.json` плагина |
| `validate-catalogue.sh` | P4 | не в репозитории: лежит в клоне `ryostore`, проверяет записи магазина |

Сборка целиком:

```sh
python3 tools/check-contrast.py
python3 tools/build-rice.py
./tools/build-rice.sh
python3 tools/build-store.py        # когда есть rices/moon/assets/preview.webp
```

Скриншотов и автотестов применения здесь нет: гейты `apply`/`restore`,
`plugin add` и бар проверяются руками по `docs/MAINTAINING.md` (скриншоты —
отдельный заход).
