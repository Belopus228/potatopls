#!/usr/bin/env python3
"""Озвучивает реплики игры через Fish Audio (https://fish.audio) и кладёт записи в game/assets/audio/voice/.

  FISH_API_KEY=... python3 tools/voice/fish_tts.py              — озвучить всё, чего ещё нет
  FISH_API_KEY=... python3 tools/voice/fish_tts.py --limit 10   — пробный заход: первые 10 реплик
  python3 tools/voice/fish_tts.py --dry                         — ничего не отправлять, показать план
  ... --only drun,ch      — только эти говорящие        ... --force — перезаписать готовые записи

Голоса задаются в tools/voice/voices.json: у каждого говорящего поле "id" — идентификатор голоса на Fish Audio
(он виден в адресе страницы голоса: https://fish.audio/m/<id>/). Пустой "id" — берётся запасной голос
("default_m" / "default_f" по полю "g"), а если и он пуст, реплика пропускается.
Ключ API берётся только из переменной окружения FISH_API_KEY; в файлы и журнал он не попадает.
Нужен только стандартный Python 3.8+.
"""
import concurrent.futures as cf, json, os, re, sys, time, urllib.error, urllib.request

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
HERE = os.path.join(ROOT, 'tools', 'voice')
OUT = os.path.join(ROOT, 'game', 'assets', 'audio', 'voice')
API = 'https://api.fish.audio/v1/tts'


def arg(name, default=None):
    if name in sys.argv:
        i = sys.argv.index(name)
        return sys.argv[i + 1] if i + 1 < len(sys.argv) and not sys.argv[i + 1].startswith('--') else True
    return default


def speakable(text):
    """Что произносить: без ремарок *в звёздочках*, с рублями словом."""
    t = re.sub(r'\*[^*]*\*', ' ', text)
    t = t.replace('₽', ' рублей ').replace('\n', ' ')
    t = re.sub(r'\s+', ' ', t).strip(' —-')
    return t if re.search(r'[A-Za-zА-Яа-яЁё0-9]', t) else ''


def voice_for(cfg, who):
    v = cfg.get('voices', {}).get(who, {})
    seen = set()
    while v.get('same_as') and v['same_as'] not in seen:      # «говорит тем же голосом, что и …»
        seen.add(v['same_as'])
        base = cfg.get('voices', {}).get(v['same_as'], {})
        v = {**base, **{k: x for k, x in v.items() if k != 'same_as' and x not in ('', None)}}
    vid = (v.get('id') or '').strip()
    if not vid and not v.get('skip'):
        vid = (cfg.get('default_f' if v.get('g') == 'f' else 'default_m') or '').strip()
    return ('' if v.get('skip') else vid), float(v.get('speed', 1.0))


def tts(key, text, vid, speed, model, tries=4):
    body = json.dumps({
        'text': text, 'reference_id': vid, 'format': 'mp3', 'mp3_bitrate': 64, 'sample_rate': 44100,
        'normalize': True, 'language': 'ru', 'latency': 'normal',
        'prosody': {'speed': speed, 'volume': 0, 'normalize_loudness': True},
    }).encode('utf-8')
    wait = 3.0
    for n in range(tries):
        req = urllib.request.Request(API, data=body, method='POST', headers={
            'Authorization': 'Bearer ' + key, 'Content-Type': 'application/json', 'model': model})
        try:
            with urllib.request.urlopen(req, timeout=120) as r:
                data = r.read()
            if len(data) < 800:
                raise RuntimeError('слишком короткий ответ (%d байт)' % len(data))
            return data
        except urllib.error.HTTPError as e:
            msg = e.read()[:300].decode('utf-8', 'replace')
            if e.code in (401, 402, 403):
                raise RuntimeError('Fish Audio отказал (%d): %s' % (e.code, msg)) from None
            if n == tries - 1:
                raise RuntimeError('ошибка %d: %s' % (e.code, msg)) from None
        except (urllib.error.URLError, TimeoutError, RuntimeError) as e:
            if n == tries - 1:
                raise RuntimeError(str(e)) from None
        time.sleep(wait)
        wait *= 2


def main():
    lines = json.load(open(os.path.join(HERE, 'lines.json'), encoding='utf-8'))
    cfg = json.load(open(os.path.join(HERE, 'voices.json'), encoding='utf-8'))
    model = str(arg('--model') or cfg.get('model') or 's2.1-pro')
    limit = int(arg('--limit') or cfg.get('limit') or 0)
    only = set(str(arg('--only')).split(',')) if arg('--only') else None
    dry, force = bool(arg('--dry')), bool(arg('--force'))
    os.makedirs(OUT, exist_ok=True)

    todo, have, novoice, silent = [], 0, {}, 0
    for ln in lines:
        if only and ln['who'] not in only:
            continue
        path = os.path.join(OUT, ln['key'] + '.mp3')
        if os.path.exists(path) and not force:
            have += 1
            continue
        text = speakable(ln['text'])
        if not text:
            silent += 1
            continue
        vid, speed = voice_for(cfg, ln['who'])
        if not vid:
            novoice[ln['who']] = novoice.get(ln['who'], 0) + 1
            continue
        todo.append((ln, text, vid, speed, path))
    if limit > 0:
        todo = todo[:limit]
    chars = sum(len(t[1]) for t in todo)
    print('реплик всего %d; готово %d; к озвучке %d (%d знаков, модель %s); без слов %d' % (len(lines), have, len(todo), chars, model, silent))
    if novoice:
        print('голос не задан (впиши "id" в tools/voice/voices.json): ' + ', '.join('%s ×%d' % kv for kv in sorted(novoice.items(), key=lambda x: -x[1])))
    if dry or not todo:
        return 0
    key = os.environ.get('FISH_API_KEY', '').strip()
    if not key:
        print('Нет ключа: задай переменную окружения FISH_API_KEY (в GitHub — секрет репозитория FISH_API_KEY).')
        return 2

    done, failed, stop = 0, [], []

    def one(item):
        ln, text, vid, speed, path = item
        if stop:
            return ln, 'пропущено'
        try:
            data = tts(key, text, vid, speed, model)
        except RuntimeError as e:
            if 'отказал' in str(e):
                stop.append(str(e))
            return ln, str(e)
        with open(path, 'wb') as f:
            f.write(data)
        return ln, None

    with cf.ThreadPoolExecutor(int(cfg.get('parallel', 2))) as ex:
        for ln, err in ex.map(one, todo):
            if err is None:
                done += 1
                if done % 20 == 0:
                    print('  … %d из %d' % (done, len(todo)))
            elif err != 'пропущено':
                failed.append((ln, err))
    print('озвучено %d, не удалось %d' % (done, len(failed)))
    for ln, err in failed[:12]:
        print('  %s [%s] %s — %s' % (ln['key'], ln['who'], ln['text'][:40], err))
    if stop:
        print('Остановлено: ' + stop[0])
        return 3
    return 0 if not failed else 1


if __name__ == '__main__':
    sys.exit(main())
