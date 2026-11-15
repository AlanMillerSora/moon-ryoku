# Видео-презентация риса Moon — сценарий и команды

Короткий ролик на 40–50 секунд: рабочий стол, рейл, часы-луна, терминал с музыкой
и cava, окна, смена воркспейса, финал. Ниже — что снимать, чем и как собрать.

## 0. Подготовка (5 минут)

```sh
# чистый стол: закрыть лишнее, свернуть чат
hyprctl dispatch 'hl.dsp.focus({ workspace = 1 })'

# музыка: локальный файл (Spotify тоже можно, но тогда звук писать с выхода)
mpv --no-video --volume=65 ~/Music/moon-theme.mp3 &

# визуализатор Ryoku по краям экрана (штатный, не cava)
qs -c shell ipc call visualizer setEnabled true
qs -c shell ipc call visualizer setSmoothing 0.55
qs -c shell ipc call visualizer setGain 1.2
# выключить после съёмки: qs -c shell ipc call visualizer setEnabled false
```

Проверь, что на экране нет личного: уведомления, ник, переписка. Часы-луна
(`plugins/moon`) должны стоять на обоях: `ryoku-plugins-place moon enabled true`.

## 1. Раскадровка (что показываем)

| # | сек | кадр | как снять |
|---|-----|------|-----------|
| 1 | 0–5 | пустой стол: обои с серпом, sumi-рейл, часы-луна | статичный кадр, зум в посте |
| 2 | 5–10 | наведение на рейл, подписи, клик по воркспейсу | мышь медленно, без рывков |
| 3 | 10–14 | лаунчер: `Super+Space`, набор `kitty` | ввод по одной букве |
| 4 | 14–24 | терминал: `fastfetch`, потом `cava` под музыку | главный кадр, 8–10 с |
| 5 | 24–29 | перетаскивание окна: граница 1 px, радиус 6, без блюра | медленный драг |
| 6 | 29–34 | смена воркспейса (рейл), затем крупно часы-луна | `Super+2`, потом `Super+1` |
| 7 | 34–40 | пустой стол + лёгкий зум на серп | финал |

Если хочется второй свет — на 34-й секунде `Super+W` → тема **Moon Warm**,
3 секунды, и обратно на **Moon**. В ролике это читается как «луна бывает тёплой».

## 2. Запись

Полный экран, 60 fps, без звука (музыку добавим в посте — так чище):

```sh
mkdir -p ~/Videos/moon
cd ~/Videos/moon

# старт записи кадра 1
wf-recorder -f 01-desktop.mp4 -r 60
# ... показал кадр ... Ctrl+C

# остальные кадры так же:
wf-recorder -f 02-rail.mp4 -r 60
wf-recorder -f 03-launcher.mp4 -r 60
wf-recorder -f 04-terminal.mp4 -r 60
wf-recorder -f 05-window.mp4 -r 60
wf-recorder -f 06-workspaces.mp4 -r 60
wf-recorder -f 07-final.mp4 -r 60
```

Альтернатива одной сессией с системным звуком (если хочешь живой cava под музыку
в кадре, а не наложенную дорожку):

```sh
# имя выхода для pactl list sources short | grep monitor
wf-recorder -a -f full.mp4 -r 60
```

Резка по времени потом: `ffmpeg -ss 00:00:06 -to 00:00:09 -i full.mp4 -c copy cut.mp4`.

## 3. Сборка (ffmpeg)

Кросс-фейды по 0.4 с, 1440p, h264, без звука:

```sh
cd ~/Videos/moon
printf "file '%s'\n" 01-desktop.mp4 02-rail.mp4 03-launcher.mp4 04-terminal.mp4 \
  05-window.mp4 06-workspaces.mp4 07-final.mp4 > list.txt

ffmpeg -f concat -safe 0 -i list.txt -vf "fps=60,scale=2560:-2" -c:v libx264 \
  -preset slow -crf 18 -pix_fmt yuv420p silent.mp4
```

Плавные склейки (тот же порядок, xfade 0.4 с — подставь длительности своих кадров):

```sh
ffmpeg \
 -i 01-desktop.mp4 -i 02-rail.mp4 -i 03-launcher.mp4 -i 04-terminal.mp4 \
 -i 05-window.mp4 -i 06-workspaces.mp4 -i 07-final.mp4 \
 -filter_complex "\
[0][1]xfade=transition=fade:duration=0.4:offset=4.6[v1];\
[v1][2]xfade=transition=fade:duration=0.4:offset=9.2[v2];\
[v2][3]xfade=transition=fade:duration=0.4:offset=13.4[v3];\
[v3][4]xfade=transition=fade:duration=0.4:offset=23.5[v4];\
[v4][5]xfade=transition=fade:duration=0.4:offset=28.6[v5];\
[v5][6]xfade=transition=fade:duration=0.4:offset=34.2,scale=2560:-2[v]" \
 -map "[v]" -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p silent.mp4
```

Музыка и финальный файл:

```sh
ffmpeg -i silent.mp4 -i ~/Music/moon-theme.mp3 -map 0:v -map 1:a \
  -c:v copy -c:a aac -b:a 192k -shortest moon-rice.mp4
```

Короткий превью-ролик для карточки магазина (6 с, без звука, 1280×720):

```sh
ffmpeg -i moon-rice.mp4 -t 6 -vf "scale=1280:720" -an -c:v libvpx-vp9 -crf 34 -b:v 0 preview.webm
```

## 4. Что ещё можно показать (и чем)

- **cava** — `kitty -e cava` под музыку. У тебя уже стоит `foreground = '#E7E9EE'`
  (мой цвет), фон `'default'`; если хочешь ровно рис — `background = '#0B0B0D'`
  и раскомментируй `gradient = 1` в `~/.config/cava/config`.
- **fastfetch** — `fastfetch --config ~/.config/ryoku/fastfetch.jsonc` (если пресета
  ещё нет, `fastfetch` покажет системный; для ролика достаточно лого и палитры).
- **Визуализатор Ryoku** — `qs -c shell ipc call visualizer cycleStyle 1` меняет
  форму; годится для кадра на 20-й секунде.
- **Виджет луны** — крупный план: перетащить его мышью ближе к центру и снять
  область 600×400 через `wf-recorder -g "x,y wxh"`.
- **Терминал с палитрой** — `kitty +kitten themes --dump-theme`? Проще:
  `printf` цветными блоками, или `ls --color=always /` — покажет ANSI.
- **Смена темы** — `Super+W` Moon ↔ Moon Warm; снимать 3–4 секунды, в посте ускорить.

## 5. Ограничения и честность

- Рис **не ставит обои** — их надо поставить заранее (`ryogami wallpaper set`).
- Скриншоты и видео — твои: в них видно твой рабочий стол, проверь на личное.
- Звук лучше накладывать в посте: запись системного звука тянет loopback и в
  кадре может щёлкать.
- 3440×1440 в 60 fps — тяжёлый файл; для соцсетей снимай в 1440p и кадрируй
  в 16:9, для карточки магазина — 1280×720.

## 6. Быстрый вариант на 15 секунд (для сторис)

1. Пустой стол с серпом — 3 с.
2. Рейл: наведение и клик — 3 с.
3. Терминал с cava под бит — 6 с.
4. Финальный кадр с часами-луной — 3 с.

Собирается тем же concat + музыка, без xfade — просто склейки.
