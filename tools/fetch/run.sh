#!/bin/bash
# Что скачать на раннере GitHub Actions. $1 — папка результата; файл .ref в ней — имя ссылки refs/fetch/<имя>.
# После каждого этапа результат отправляется (flush.sh), чтобы зависший этап не унёс с собой остальное.
OUT=$1
HERE="$GITHUB_WORKSPACE/tools/fetch"
echo a4 > "$OUT/.ref"
cd /tmp
flush() { bash "$HERE/flush.sh" "$OUT"; }
echo "старт $(date -u +%T)"; flush

# 1. Музыка Кевина Маклауда (CC BY 4.0): исходные файлы выбранных треков. Нарезка и сведение — в tools/audio.
mkdir -p "$OUT/km"
one() {
  t="$1"
  enc=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$t")
  code=$(curl -sL --connect-timeout 15 -m 120 -o "$2/km/$t.mp3" -w "%{http_code} %{time_total}s" "https://incompetech.com/music/royalty-free/mp3-royaltyfree/$enc.mp3")
  if [ "${code%% *}" = "200" ] && [ -s "$2/km/$t.mp3" ]; then echo "OK $t | $(stat -c %s "$2/km/$t.mp3")"; else rm -f "$2/km/$t.mp3"; echo "НЕТ $code $t"; fi
}
export -f one
grep -v '^$' "$HERE/tracks.txt" | xargs -d '\n' -P 6 -I{} bash -c 'one "$1" "$2"' _ {} "$OUT"
echo "музыка готова $(date -u +%T)"; flush

