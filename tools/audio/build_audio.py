#!/usr/bin/env python3
"""Собирает музыку и звуки игры из готовых записей: нарезает, сводит, выравнивает громкость.

  PYTHONPATH=/tmp/pyy python3 tools/audio/build_audio.py [--src /tmp/src] [--only music|sfx|имя,…] [--dry]

Откуда берутся записи (обе коллекции свободные, авторство — в game/CREDITS.md):
  <src>/km/<трек>.mp3   — музыка Кевина Маклауда (incompetech.com), CC BY 4.0;
  <src>/jam/<пак>/…     — звуки Kenney (kenney.nl), CC0 1.0.
Скачивает их tools/fetch/run.sh на раннере GitHub Actions (из этой среды интернет закрыт).
Результат: game/assets/audio/music/<имя>.ogg и game/assets/audio/sfx/<имя>[_N].ogg.
Нужны ffmpeg и Python 3.8+. Каждый звук обрабатывается один раз: ffmpeg по рецепту из таблицы ниже.
"""
import array, glob, json, math, os, re, shutil, subprocess, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
GAME = os.path.join(ROOT, 'game', 'assets', 'audio')
FF = os.environ.get('FFMPEG', shutil.which('ffmpeg') or '/tmp/ffmpeg')

# ---------- музыка ----------
# имя в игре: (трек, начало, конец, темп) — окно зацикливания в секундах; конец 0 — до конца трека.
# Границы приводятся к целым тактам по темпу, чтобы петля не спотыкалась.
MUSIC = {
    'menu': ('Sneaky Snitch', 5.5, 132.0, 87),          # мемная классика: тихое вступление, дальше ровно
    'dorm': ('Anxiety', 0.6, 108.6, 0),                 # общага: тревожный электронный фон
    'murino': ('Lobby Time', 2.0, 155.0, 128),          # двор и лифт: лёгкий грув
    'milk': ('Carefree', 1.0, 140.0, 96),               # село: укулеле
    'myt': ('Monkeys Spinning Monkeys', 0.1, 100.0, 144),
    'banya': ('Frost Waltz', 2.6, 120.0, 99),
    'jmur': ('Hidden Agenda', 2.7, 120.0, 132),         # кладбище и казино: крадущаяся тема (мимо тихого вступления)
    'fog': ('Oppressive Gloom', 4.0, 150.0, 58),        # финальный двор: тяжёлый марш
    'fight': ('The Complex', 6.0, 150.0, 104),          # драка: механический напор
    'boss': ('Volatile Reaction', 3.1, 120.0, 155),     # боссы глав
    'boss2': ('Black Vortex', 4.0, 140.0, 163),         # финальный босс: 7/8
    'win': ('Controlled Chaos', 116.0, 150.0, 80),      # победа над боссом: самый плотный кусок
}
MUSIC_SR = '44100'

# ---------- звуки ----------
# имя в игре: [(пак, шаблон файла внутри пака, фильтры ffmpeg), …]. Несколько файлов — варианты звука
# (hit_1, hit_2, …): игра берёт случайный и не повторяет прошлый. Шаблон — glob, файлы сортируются по имени.
LOW = 'highpass=f=45,lowpass=f=12000'
SFX = {
    'item': [('kenney-music-jingles', '**/jingles-pizzicato_00.ogg', '')],
    'coin': [('kenney-rpg-audio', '**/handleCoins2.ogg', ''), ('kenney-rpg-audio', '**/handleCoins.ogg', 'atrim=0:0.5,afade=t=out:st=0.35:d=0.15')],
    'land': [('kenney-impact-sounds', '**/impactSoft_heavy_00[01].ogg', LOW)],
    'jump': [('kenney-foley-sounds', '**/woosh4.ogg', 'asetrate=44100*1.15,aresample=44100')],
    'step': [('kenney-impact-sounds', '**/footstep_concrete_00?.ogg', '')],
    'step_wood': [('kenney-impact-sounds', '**/footstep_wood_00?.ogg', '')],
    'step_grass': [('kenney-impact-sounds', '**/footstep_grass_00?.ogg', '')],
    'step_snow': [('kenney-impact-sounds', '**/footstep_snow_00?.ogg', '')],
    'swing': [('kenney-foley-sounds', '**/woosh[1245].ogg', '')],
    'hit': [('kenney-impact-sounds', '**/impactPunch_medium_00?.ogg', '')],
    'hit_big': [('kenney-impact-sounds', '**/impactPunch_heavy_00?.ogg', '')],
    'roll': [('kenney-rpg-audio', '**/cloth1.ogg', 'asetrate=44100*1.2,aresample=44100'), ('kenney-rpg-audio', '**/cloth2.ogg', 'asetrate=44100*1.2,aresample=44100'), ('kenney-rpg-audio', '**/cloth3.ogg', '')],
    'hurt': [('kenney-impact-sounds', '**/impactSoft_heavy_003.ogg', ''), ('kenney-retro-sounds-2', '**/hurt2.ogg', 'volume=0.6,asetrate=44100*0.85,aresample=44100')],
    'deny': [('kenney-interface-sounds', '**/error_00[56].ogg', '')],
    'throw': [('kenney-foley-sounds', '**/woosh3.ogg', 'asetrate=44100*1.25,aresample=44100')],
    'spray': [('kenney-sci-fi-sounds', '**/thrusterFire_000.ogg', 'atrim=0:0.9,afade=t=out:st=0.6:d=0.3,highpass=f=900,lowpass=f=9000,volume=0.8')],
    'slime': [('kenney-sci-fi-sounds', '**/slime_000.ogg', '')],
    'am': [('kenney-sci-fi-sounds', '**/lowFrequency_explosion_00[01].ogg', '')],
    'eat': [('kenney-rpg-audio', '**/chop.ogg', 'asetrate=44100*1.1,aresample=44100'), ('kenney-rpg-audio', '**/chop.ogg', 'asetrate=44100*0.9,aresample=44100')],
    'alert': [('kenney-retro-sounds-1', '**/creature[24].ogg', 'asetrate=44100*0.9,aresample=44100')],
    'dash': [('kenney-foley-sounds', '**/woosh6.ogg', '')],
    'shoot': [('kenney-sci-fi-sounds', '**/laserSmall_00[03].ogg', ''), ('kenney-digital-audio', '**/laser1.ogg', '')],
    'die': [('kenney-retro-sounds-1', '**/creature5.ogg', 'asetrate=44100*0.8,aresample=44100'), ('kenney-impact-sounds', '**/impactSoft_heavy_004.ogg', LOW)],
    'crate': [('kenney-impact-sounds', '**/impactWood_light_00?.ogg', '')],
    'break': [('kenney-impact-sounds', '**/impactWood_heavy_00[024].ogg', '')],
    'door': [('kenney-rpg-audio', '**/doorOpen_1.ogg', '')],
    'ui': [('kenney-interface-sounds', '**/click_003.ogg', ''), ('kenney-ui-audio', '**/click3.ogg', 'volume=0.7')],
    'blip': [('kenney-interface-sounds', '**/select_001.ogg', '')],
    'lose': [('kenney-retro-sounds-2', '**/gameover1.ogg', '')],
    'open': [('kenney-rpg-audio', '**/doorOpen_2.ogg', '')],
    'boss_die': [('kenney-sci-fi-sounds', '**/explosionCrunch_004.ogg', ''), ('kenney-sci-fi-sounds', '**/lowFrequency_explosion_000.ogg', 'volume=0.9')],
    'roar': [('kenney-retro-sounds-1', '**/rumble2.ogg', 'volume=0.8'), ('kenney-retro-sounds-1', '**/creature1.ogg', 'asetrate=44100*0.7,aresample=44100')],
    'crash': [('kenney-impact-sounds', '**/impactMetal_heavy_00[02].ogg', LOW)],
    'phone': [('kenney-retro-sounds-1', '**/radar1.ogg', 'asetrate=44100*1.1,aresample=44100')],
    'unlock': [('kenney-rpg-audio', '**/metalLatch.ogg', ''), ('kenney-rpg-audio', '**/metalClick.ogg', '')],
    'win': [('kenney-music-jingles', '**/jingles-pizzicato_11.ogg', ''), ('kenney-music-jingles', '**/jingles-steel_00.ogg', '')],
    'lift': [('kenney-digital-audio', '**/threeTone1.ogg', ''), ('kenney-digital-audio', '**/powerUp1.ogg', 'atrim=0:0.9')],
    'cups': [('kenney-casino-audio', '**/chips-handle-5.ogg', ''), ('kenney-casino-audio', '**/dice-shake-2.ogg', '')],
}
SIL = 'silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.02,areverse,silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.02,areverse'


def run(args):
    r = subprocess.run([FF, '-hide_banner', '-v', 'error', '-y'] + args, capture_output=True, text=True)
    if r.returncode != 0:
        raise RuntimeError('ffmpeg: ' + (r.stderr or '')[-400:])


def music(name, src, dst):
    track, a, b, bpm = MUSIC[name]
    f = os.path.join(src, 'km', track + '.mp3')
    if not os.path.exists(f):
        return 'нет файла ' + os.path.basename(f)
    if bpm:
        bar = 60.0 / bpm * 4.0
        a = round(a / bar) * bar
        b = round(b / bar) * bar
    fade = 0.6
    ln = b - a
    # петля: берём окно и в конце добавляем начало окна с плавным входом — стык не слышно
    af = ('atrim=%f:%f,asetpts=N/SR/TB,afade=t=in:st=0:d=0.15,' % (a, b) +
          'loudnorm=I=-16:TP=-1.5:LRA=11,alimiter=limit=0.92,aresample=%s,' % MUSIC_SR)   # без ограничителя после сведения пики уходят за 1.0
    tmp = dst + '.wav'
    run(['-i', f, '-ac', '2', '-ar', MUSIC_SR, '-af', af, '-t', '%f' % ln, tmp])
    loop = ('[1:a]atrim=0:%f,asetpts=N/SR/TB,afade=t=out:st=0:d=%f[x];'
            '[0:a][x]acrossfade=d=%f:c1=tri:c2=tri,alimiter=limit=0.85:attack=5:release=60[out]' % (fade, fade, fade))
    enc = ['-map', '[out]', '-c:a', 'libvorbis', '-q:a', '2', '-metadata', 'title=%s' % track,
           '-metadata', 'artist=Kevin MacLeod', '-metadata', 'comment=incompetech.com, CC BY 4.0']
    run(['-i', tmp, '-i', tmp, '-filter_complex', loop] + enc + [dst])
    # Vorbis после ограничителя всё равно выстреливает выше 1.0: меряем и, если надо, гасим и кодируем заново
    for _ in range(3):
        peak = peak_of(dst)
        if peak <= 0.95:
            break
        gain = 20.0 * math.log10(0.9 / peak)
        run(['-i', tmp, '-i', tmp, '-filter_complex',
             loop.replace('alimiter=limit=0.85', 'volume=%fdB,alimiter=limit=0.85' % gain)] + enc + [dst])
    os.remove(tmp)
    return '%.0f с, окно %.1f–%.1f, пик %.2f' % (ln, a, b, peak_of(dst))


def peak_of(path):
    """Наибольший отсчёт записи в долях полной шкалы (декодируем целиком: файлы небольшие)."""
    r = subprocess.run([FF, '-v', 'error', '-i', path, '-ac', '1', '-ar', '8000', '-f', 'f32le', '-'], capture_output=True)
    if r.returncode != 0 or not r.stdout:
        return 1.0
    a = array.array('f')
    a.frombytes(r.stdout)
    return max(abs(v) for v in a[::37]) if len(a) else 1.0


def sfx_group(name, items, src, dst):
    """Один звук игры: все совпадения по шаблонам становятся вариантами (имя.ogg или имя_1.ogg, имя_2.ogg…)."""
    files = []
    for pack, pat, af in items:
        found = sorted(glob.glob(os.path.join(src, 'jam', pack, pat), recursive=True))
        if not found:
            return 'нет файла %s/%s' % (pack, pat)
        files += [(f, af) for f in found]
    made = []
    for i, (f, af) in enumerate(files, 1):
        out = dst + ('' if len(files) == 1 else '_%d' % i) + '.ogg'
        chain = ','.join([x for x in [SIL, af, 'loudnorm=I=-17:TP=-1.0:LRA=9', 'aresample=44100', 'aformat=channel_layouts=mono'] if x])
        run(['-i', f, '-af', chain, '-c:a', 'libvorbis', '-q:a', '4', out])
        made.append(os.path.basename(out))
    return '%d: %s' % (len(made), ', '.join(made))


def main():
    src = '/tmp/src'
    if '--src' in sys.argv:
        src = sys.argv[sys.argv.index('--src') + 1]
    only = None
    if '--only' in sys.argv:
        only = set(sys.argv[sys.argv.index('--only') + 1].split(','))
    dry = '--dry' in sys.argv
    mdir = os.path.join(GAME, 'music')
    sdir = os.path.join(GAME, 'sfx')
    os.makedirs(mdir, exist_ok=True)
    os.makedirs(sdir, exist_ok=True)
    ok = bad = 0
    want_m = None if (only is None or 'music' in only) else {n for n in only if n in MUSIC}
    want_s = None if (only is None or 'sfx' in only) else {n for n in only if n in SFX}
    if want_m is None or want_m:
        for name in MUSIC:
            if want_m is not None and name not in want_m:
                continue
            dst = os.path.join(mdir, name + '.ogg')
            if dry:
                print('music/%-6s ← %s' % (name, MUSIC[name][0])); continue
            try:
                print('music/%-6s ← %-28s %s' % (name, MUSIC[name][0], music(name, src, dst))); ok += 1
            except RuntimeError as e:
                print('music/%-6s ОШИБКА %s' % (name, e)); bad += 1
    if want_s is None or want_s:
        for name, items in SFX.items():
            if want_s is not None and name not in want_s:
                continue
            if dry:
                print('sfx/%-10s ← %d' % (name, len(items))); continue
            try:
                print('sfx/%-10s ← %s' % (name, sfx_group(name, items, src, os.path.join(sdir, name)))); ok += 1
            except RuntimeError as e:
                print('sfx/%-10s ОШИБКА %s' % (name, e)); bad += 1
    # старые файлы, которых больше нет в таблице, убираем — иначе в сборку попадут оба варианта
    if not only and not dry:
        keep_m = {n + '.ogg' for n in MUSIC}
        keep_s = set()
        for n, items in SFX.items():
            cnt = sum(len(glob.glob(os.path.join(src, 'jam', p, pat), recursive=True)) for p, pat, _ in items)
            keep_s |= {n + '.ogg'} if cnt <= 1 else {'%s_%d.ogg' % (n, i) for i in range(1, cnt + 1)}
        for d, keep in ((mdir, keep_m), (sdir, keep_s)):
            for fn in os.listdir(d):
                if fn.endswith('.ogg') and fn not in keep:
                    os.remove(os.path.join(d, fn)); print('убрал', os.path.join(os.path.basename(d), fn))
                if fn.endswith('.ogg.import'):
                    base = fn[:-7]
                    if base not in keep:
                        os.remove(os.path.join(d, fn))
    print('готово: %d, ошибок %d' % (ok, bad))
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())
