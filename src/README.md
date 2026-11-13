# src — источник истины

Здесь лежат данные, из которых генерируются записи магазина:

- `palette.json` — 16 Material-ролей + terminal 16 ANSI + альфы состояний (готово);
- `tokens.json` — сетка, радиус 6, border 1, типографика 15 px, движение, бар (готово);
- `rice.override.json` — что рис разрешает себе менять поверх шаблона (P2).

`tools/build-rice.sh` собирает `rices/moon/rice.json` и `colorschemes/Moon/Moon.json`.
Руками эти два файла не правятся: правка идёт в `src/`, затем пересборка.
