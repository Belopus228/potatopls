#!/bin/bash
# Отправить содержимое папки $1 в refs/fetch/<имя из $1/.ref>. Можно звать много раз: так частичный результат не пропадёт.
OUT=$1
cd "$OUT" || exit 0
[ -d .git ] || git init -q
git checkout -q -B f 2>/dev/null
git add -A
git -c user.name=fetch -c user.email=fetch@users.noreply.github.com commit -q -m "fetch $(date -u +%T)" 2>/dev/null
git push -q --force "https://x-access-token:${TOKEN}@github.com/${REPO}.git" HEAD:refs/fetch/$(cat .ref 2>/dev/null || echo data) 2>&1 | tail -1
echo "flush $(date -u +%T): $(du -sh --exclude=.git . | cut -f1)"
