# tools

| Скрипт | Этап | Задача |
|---|---|---|
| `check-contrast.py` | P1 ✅ | AA для всех `src/palette*.json`: текст ≥ 4.5, UI ≥ 3, декор по порогу пары |
| `build-rice.sh` | P1 ✅ | `src/palette*.json` → `colorschemes/<Name>/*` + `dist/*` (основная схема) |
| `build-rice.py` | P2 ✅ | `src/rice.base.json` + `src/rice.override.json` → `rices/moon/rice.json` + `palette.json`, whitelist-санитайзер (нет `/home/`, IP, hostname, ключей вне whitelist) |
| `pack-product.py` | P4 | не в репозитории: лежит в клоне `ryostore`, пересчитывает `product-manifest.json` плагина |
| `validate-catalogue.sh` | P4 | не в репозитории: лежит в клоне `ryostore`, проверяет записи магазина |

Сборка целиком:

```sh
python3 tools/check-contrast.py
python3 tools/build-rice.py
./tools/build-rice.sh
```

Скриншотов и автотестов применения здесь нет: гейты `apply`/`restore`,
`plugin add` и бар проверяются руками по `docs/MAINTAINING.md` (скриншоты —
отдельный заход).
