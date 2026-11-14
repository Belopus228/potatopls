#!/bin/bash
# Что скачать на раннере GitHub Actions. $1 — папка результата; файл .ref в ней — имя ссылки refs/fetch/<имя>.
# После каждого этапа результат отправляется (flush.sh), чтобы зависший этап не унёс с собой остальное.
OUT=$1
HERE="$GITHUB_WORKSPACE/tools/fetch"
echo a2 > "$OUT/.ref"
cd /tmp
flush() { bash "$HERE/flush.sh" "$OUT"; }
echo "старт $(date -u +%T)"; flush

# 1. Звуки Kenney (CC0) и библиотека анимаций Quaternius (CC0) из series-ai/jam-ready-assets (там Git LFS)
PACKS="kenney-impact-sounds kenney-rpg-audio kenney-interface-sounds kenney-ui-audio kenney-digital-audio kenney-sci-fi-sounds kenney-foley-sounds kenney-casino-audio kenney-music-jingles kenney-voiceover-pack-fighter kenney-retro-sounds-1 kenney-retro-sounds-2 quaternius-universal-animation-library quaternius-universal-animation-library-2"
git lfs version || (sudo apt-get install -y -qq git-lfs > /dev/null 2>&1; git lfs version)
git lfs install --skip-smudge > /dev/null
GIT_LFS_SKIP_SMUDGE=1 timeout 300 git clone -q --depth 1 --filter=blob:none --sparse https://github.com/series-ai/jam-ready-assets.git jam
cd jam && git sparse-checkout set $PACKS
inc=$(echo $PACKS | sed 's/ /\/**,/g')/**
timeout 600 git lfs pull --include="$inc" 2>&1 | tail -3
mkdir -p "$OUT/jam"
for p in $PACKS; do
  [ -d "$p" ] && cp -r "$p" "$OUT/jam/" && echo "$p: $(du -sh "$p" | cut -f1), файлов $(find "$p" -type f | wc -l)"
done
find "$OUT/jam" -type f -size +95M -print -delete
(cd "$OUT/jam" && find . -type f -printf '%s %p\n' | sort -k2 > "$OUT/jam_listing.txt")
head -c 300 "$OUT/jam/kenney-impact-sounds/License.txt" 2>/dev/null; echo
cd /tmp; echo "kenney/quaternius готово $(date -u +%T)"; flush

# 2. Каталог музыки Кевина Маклауда (CC BY 4.0): названия, темп, настроение
mkdir -p "$OUT/km/a" /tmp/km
for u in pieces.json; do
  curl -sL --connect-timeout 15 -m 60 -o "$OUT/km/$u" -w "$u %{http_code} %{size_download} %{time_total}s\n" "https://incompetech.com/music/royalty-free/$u"
done
curl -sL --connect-timeout 15 -m 60 -o "$OUT/km/music.html" -w "music.html %{http_code} %{size_download} %{time_total}s\n" "https://incompetech.com/music/royalty-free/music.html"
grep -o 'src="[^"]*\.js[^"]*"' "$OUT/km/music.html" | head -20
echo "каталог готов $(date -u +%T)"; flush

# 3. Кандидаты: уменьшенные копии для анализа (моно, 22 кГц). Полные файлы — следующим заходом.
which ffmpeg > /dev/null || sudo apt-get install -y -qq ffmpeg > /dev/null 2>&1
ffmpeg -version | head -1
one() {
  t="$1"
  enc=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$t")
  code=$(curl -sL --connect-timeout 15 -m 90 -o "/tmp/km/$t.mp3" -w "%{http_code} %{time_total}s" "https://incompetech.com/music/royalty-free/mp3-royaltyfree/$enc.mp3")
  if [ "${code%% *}" = "200" ] && [ -s "/tmp/km/$t.mp3" ]; then
    d=$(ffprobe -v error -show_entries format=duration:format_tags=title,artist -of default=nw=1 "/tmp/km/$t.mp3" | tr '\n' ' ')
    ffmpeg -v error -y -i "/tmp/km/$t.mp3" -ac 1 -ar 22050 -c:a libvorbis -q:a 0 "$2/km/a/$t.ogg"
    echo "OK $t | $(stat -c %s "/tmp/km/$t.mp3") | $code | $d"
  else
    echo "НЕТ $code $t"
  fi
}
export -f one
grep -v '^$' "$HERE/tracks.txt" | xargs -d '\n' -P 6 -I{} bash -c 'one "$1" "$2"' _ {} "$OUT" | tee "$OUT/km/tracks_report.txt"
echo "музыка готова $(date -u +%T)"; flush
