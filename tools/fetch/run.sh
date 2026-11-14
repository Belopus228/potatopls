#!/bin/bash
# Что скачать на раннере GitHub Actions. $1 — папка результата; файл .ref в ней — имя ссылки refs/fetch/<имя>.
OUT=$1
echo a1 > "$OUT/.ref"
cd /tmp
sudo apt-get install -y -qq ffmpeg git-lfs > /dev/null 2>&1
ffmpeg -version | head -1

# 1. Каталог музыки Кевина Маклауда (CC BY 4.0): названия, темп, настроение
mkdir -p "$OUT/km"
for u in pieces.json index.json ; do
  curl -sL -m 60 -o "$OUT/km/$u" -w "$u %{http_code} %{size_download}\n" "https://incompetech.com/music/royalty-free/$u"
done
curl -sL -m 60 -o "$OUT/km/index.html" -w "index %{http_code} %{size_download}\n" "https://incompetech.com/music/royalty-free/music.html"
curl -sL -m 60 -o "$OUT/km/full_list.html" -w "list %{http_code} %{size_download}\n" "https://incompetech.com/music/royalty-free/full_list.php"

# 2. Кандидаты: уменьшенные копии для анализа (моно, 22 кГц), полные файлы скачаем вторым заходом
mkdir -p "$OUT/km/a" /tmp/km
while IFS= read -r t; do
  [ -z "$t" ] && continue
  enc=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$t")
  code=$(curl -sL -m 120 -o "/tmp/km/$t.mp3" -w "%{http_code}" "https://incompetech.com/music/royalty-free/mp3-royaltyfree/$enc.mp3")
  if [ "$code" = "200" ] && [ -s "/tmp/km/$t.mp3" ]; then
    d=$(ffprobe -v error -show_entries format=duration:format_tags=title,artist -of default=nw=1 "/tmp/km/$t.mp3" | tr '\n' ' ')
    ffmpeg -v error -y -i "/tmp/km/$t.mp3" -ac 1 -ar 22050 -c:a libvorbis -q:a 0 "$OUT/km/a/$t.ogg"
    echo "OK $t | $(stat -c %s "/tmp/km/$t.mp3") | $d"
  else
    echo "НЕТ $code $t"
  fi
done < "$GITHUB_WORKSPACE/tools/fetch/tracks.txt" | tee "$OUT/km/tracks_report.txt"

# 3. Звуки Kenney (CC0) и библиотека анимаций Quaternius (CC0) из series-ai/jam-ready-assets (там Git LFS)
PACKS="kenney-impact-sounds kenney-rpg-audio kenney-interface-sounds kenney-ui-audio kenney-digital-audio kenney-sci-fi-sounds kenney-foley-sounds kenney-casino-audio kenney-music-jingles kenney-voiceover-pack-fighter kenney-retro-sounds-1 kenney-retro-sounds-2 quaternius-universal-animation-library quaternius-universal-animation-library-2"
git lfs install --skip-smudge > /dev/null
GIT_LFS_SKIP_SMUDGE=1 git clone -q --depth 1 --filter=blob:none --sparse https://github.com/series-ai/jam-ready-assets.git jam && cd jam
git sparse-checkout set $PACKS
inc=$(echo $PACKS | sed 's/ /\/**,/g')/**
git lfs pull --include="$inc" 2>&1 | tail -3
mkdir -p "$OUT/jam"
for p in $PACKS; do
  [ -d "$p" ] && cp -r "$p" "$OUT/jam/" && echo "$p: $(du -sh "$p" | cut -f1), файлов $(find "$p" -type f | wc -l)"
done
find "$OUT/jam" -type f -size +95M -print -delete
(cd "$OUT/jam" && find . -type f -printf '%s %p\n' | sort -k2 > "$OUT/jam_listing.txt")
head -c 300 "$OUT/jam/kenney-impact-sounds/License.txt" 2>/dev/null
