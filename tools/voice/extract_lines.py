#!/usr/bin/env python3
"""Собирает все реплики диалогов из кода игры в tools/voice/lines.json.

  python3 tools/voice/extract_lines.py           — пересобрать список и таблицу tools/voice/SPEAKERS.md
  python3 tools/voice/extract_lines.py --check   — только показать сводку

Реплика — это say([["кто", "текст"], …]) или G.ui.choose("кто", "текст", […]) в game/src/**/*.gd.
Ключ записи — первые 12 знаков md5 от «кто|текст»: тот же расчёт делает игра (Snd.voice_key),
поэтому запись game/assets/audio/voice/<ключ>.mp3 находится без таблиц соответствия.
Реплики, собранные из кусков («…%s…» % x), пропускаются: их текст известен только во время игры.
"""
import glob, hashlib, json, os, re, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
SRC = os.path.join(ROOT, 'game', 'src')
OUT = os.path.join(ROOT, 'tools', 'voice', 'lines.json')
TABLE = os.path.join(ROOT, 'tools', 'voice', 'SPEAKERS.md')

STR = r'"((?:[^"\\]|\\.)*)"'
WHO = r'(?:"([a-z_0-9]+)"|\{\s*"n"\s*:\s*' + STR + r'[^}]*\})'
PAIR = re.compile(r'\[\s*' + WHO + r'\s*,\s*' + STR + r'\s*(\]|%|\+)')
CHOOSE = re.compile(r'\.choose\(\s*' + WHO + r'\s*,\s*' + STR + r'\s*(,|%|\+)')
NAMES = re.compile(r'"([a-z_0-9]+)"\s*:\s*\{\s*"name"\s*:\s*' + STR)


def unesc(s):
    return s.replace('\\n', '\n').replace('\\t', '\t').replace('\\"', '"').replace('\\\\', '\\')


def key(who, text):
    return hashlib.md5((who + '|' + text).encode('utf-8')).hexdigest()[:12]


def balanced(src, i):
    """Текст от открывающей скобки в позиции i до парной закрывающей (строки учитываются)."""
    depth = 0; j = i; q = False
    while j < len(src):
        c = src[j]
        if q:
            if c == '\\': j += 1
            elif c == '"': q = False
        elif c == '"': q = True
        elif c in '([{': depth += 1
        elif c in ')]}':
            depth -= 1
            if depth == 0: return src[i:j + 1]
        j += 1
    return src[i:]


def collect():
    cast = {}
    with open(os.path.join(SRC, 'data', 'cast.gd'), encoding='utf-8') as f:
        for m in NAMES.finditer(f.read()):
            cast[m.group(1)] = unesc(m.group(2))
    lines, skipped, seen = [], [], set()
    for path in sorted(glob.glob(os.path.join(SRC, '**', '*.gd'), recursive=True)):
        rel = os.path.relpath(path, os.path.join(ROOT, 'game'))
        src = open(path, encoding='utf-8').read()
        found = []
        for m in re.finditer(r'\bsay\(\s*\[', src):
            block = balanced(src, m.end() - 1)
            base = m.end() - 1
            for pm in PAIR.finditer(block):
                found.append((base + pm.start(), pm))
        for cm in CHOOSE.finditer(src):
            found.append((cm.start(), cm))
        for pos, m in sorted(found, key=lambda x: x[0]):
            who = m.group(1) or unesc(m.group(2))
            text = unesc(m.group(3))
            where = '%s:%d' % (rel, src.count('\n', 0, pos) + 1)
            if m.group(4) in '%+':
                skipped.append((where, who, text))
                continue
            k = key(who, text)
            if k in seen:
                continue
            seen.add(k)
            lines.append({'key': k, 'who': who, 'name': cast.get(who, who), 'text': text, 'src': where})
    return lines, skipped


def main():
    lines, skipped = collect()
    by = {}
    for ln in lines:
        d = by.setdefault(ln['who'], {'name': ln['name'], 'n': 0, 'chars': 0})
        d['n'] += 1; d['chars'] += len(ln['text'])
    total = sum(d['chars'] for d in by.values())
    print('реплик: %d, знаков: %d, говорящих: %d, пропущено составных: %d' % (len(lines), total, len(by), len(skipped)))
    for w, d in sorted(by.items(), key=lambda x: -x[1]['chars']):
        print('  %-22s %-24s реплик %3d, знаков %5d' % (w, d['name'], d['n'], d['chars']))
    for where, who, text in skipped:
        print('  составная, без озвучки: %s [%s] %s' % (where, who, text[:60]))
    if '--check' in sys.argv:
        return
    with open(OUT, 'w', encoding='utf-8') as f:
        json.dump(lines, f, ensure_ascii=False, indent=1)
        f.write('\n')
    with open(TABLE, 'w', encoding='utf-8') as f:
        f.write('# Кто сколько говорит\n\nСобрано скриптом `tools/voice/extract_lines.py`. Всего реплик: %d, знаков: %d.\n\n' % (len(lines), total))
        f.write('| Ключ в voices.json | Кто | Реплик | Знаков |\n|---|---|---|---|\n')
        for w, d in sorted(by.items(), key=lambda x: -x[1]['chars']):
            f.write('| `%s` | %s | %d | %d |\n' % (w, d['name'], d['n'], d['chars']))
    print('записано:', os.path.relpath(OUT, ROOT), 'и', os.path.relpath(TABLE, ROOT))


if __name__ == '__main__':
    main()
