#!/bin/bash
# Что скачать на раннере GitHub Actions. $1 — папка результата; файл .ref в ней — имя ссылки refs/fetch/<имя>.
# После каждого этапа результат отправляется (flush.sh), чтобы зависший этап не унёс с собой остальное.
OUT=$1
HERE="$GITHUB_WORKSPACE/tools/fetch"
echo a3 > "$OUT/.ref"
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

# 2. Звуки Kenney (CC0) и библиотека анимаций Quaternius (CC0) из series-ai/jam-ready-assets (там Git LFS).
#    Клон неглубокий, но полный: с частичным клоном git lfs перебирает всё дерево и запрашивает каждый файл отдельно.
PACKS="kenney-impact-sounds kenney-rpg-audio kenney-interface-sounds kenney-ui-audio kenney-digital-audio kenney-sci-fi-sounds kenney-foley-sounds kenney-casino-audio kenney-music-jingles kenney-voiceover-pack-fighter kenney-retro-sounds-1 kenney-retro-sounds-2 quaternius-universal-animation-library quaternius-universal-animation-library-2"
git lfs install --skip-smudge > /dev/null
GIT_LFS_SKIP_SMUDGE=1 timeout 400 git clone -q --depth 1 https://github.com/series-ai/jam-ready-assets.git jam; echo "клон: код $?, $(du -sh jam | cut -f1), $(date -u +%T)"
cd jam
inc=$(echo $PACKS | sed 's/ /\/**,/g')/**
timeout 500 git lfs pull --include="$inc" 2>&1 | tail -4; echo "lfs pull: код ${PIPESTATUS[0]}, $(date -u +%T)"
mkdir -p "$OUT/jam"
for p in $PACKS; do
  [ -d "$p" ] && cp -r "$p" "$OUT/jam/" && echo "$p: $(du -sh "$p" | cut -f1), файлов $(find "$p" -type f | wc -l)"
done
find "$OUT/jam" -type f -size +95M -print -delete
find "$OUT/jam" -name "*.glb" -exec ls -la {} \;
grep -rl "git-lfs.github.com/spec" "$OUT/jam" 2>/dev/null | wc -l
cd /tmp; echo "kenney/quaternius готово $(date -u +%T)"; flush
