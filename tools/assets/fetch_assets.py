#!/usr/bin/env python3
"""Скачивает CC0-модели из открытых репозиториев GitHub и раскладывает их в game/assets.

  python3 tools/assets/fetch_assets.py            — всё по списку (уже скачанное берётся из кэша)
  python3 tools/assets/fetch_assets.py chars      — только группы, чьё имя начинается с "chars"

Кэш: $ASSET_CACHE (по умолчанию /tmp/asset_cache). Нужен gh (GitHub CLI) с авторизацией.
Все модели — CC0 (Quaternius, KayKit, Kenney); источники перечислены в game/CREDITS.md.
"""
import os, sys, subprocess, urllib.parse, shutil, concurrent.futures as cf
sys.path.insert(0, os.path.dirname(__file__))
import glbtool

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
OUT = os.path.join(ROOT, 'game', 'assets')
CACHE = os.environ.get('ASSET_CACHE', '/tmp/asset_cache')

QS = 'trebeljahr/quaternius-showcase'            # public/glb/<pack>/<Name>.glb
MEN = ('Hhk187/Zomopocalypse', 'Assets/Models/Characters/Ultimate Modular Men Pack-glb/')
WOMEN = ('lucky89x/english-game-v3', 'assets/Ultimate Modular Women - April 2022/Individual Characters/glTF/')
MON = ('flawlesshappiness/EmotionCreatures', 'Assets/Quaternius/Ultimate Monsters/')

# (куда, репозиторий, путь, режим)  режим: pack — как есть в один GLB; strip — без анимаций
M = []


def add(group, dst, repo, path, mode='pack'):
    M.append((group, dst, repo, path, mode))


# --- люди: Ultimate Modular Men / Women (Quaternius, CC0) ---
for dst, src in [('adventurer', 'Adventurer'), ('astronaut', 'Astronaut'), ('beach', 'Beach Character'), ('suit', 'Business Man'),
                 ('casual', 'Casual Character'), ('farmer', 'Farmer'), ('hoodie', 'Hoodie Character'), ('king', 'King'),
                 ('punk', 'Punk'), ('swat', 'Swat'), ('worker', 'Worker')]:
    add('chars', f'chars/men/{dst}.glb', MEN[0], MEN[1] + src + '.glb', 'strip')
add('chars', 'chars/men_anims.glb', MEN[0], MEN[1] + 'Casual Character.glb', 'pack')
for dst, src in [('casual', 'Casual'), ('formal', 'Formal'), ('worker', 'Worker'), ('witch', 'Witch'), ('suit', 'Suit'), ('punk', 'Punk'), ('medieval', 'Medieval')]:
    add('chars', f'chars/women/{dst}.glb', WOMEN[0], WOMEN[1] + src + '.gltf', 'strip')
add('chars', 'chars/women_anims.glb', WOMEN[0], WOMEN[1] + 'Casual.gltf', 'pack')

# --- существа (Quaternius, CC0) ---
for dst, src in [('rat', 'easy_enemies_pack/Rat'), ('spider', 'easy_enemies_pack/Spider'), ('wasp', 'easy_enemies_pack/Wasp'), ('frog', 'easy_enemies_pack/Frog'),
                 ('cow', 'animals_pack/Cow'), ('bull', 'animals_pack/Bull'), ('wolf', 'animals_pack/Wolf'), ('husky', 'animals_pack/Husky'),
                 ('mech', 'mech_pack/Mike'), ('drone_walk', 'cyberpunk_pack/Enemy_2Legs'), ('drone_fly', 'cyberpunk_pack/Enemy_Flying'), ('drone_big', 'cyberpunk_pack/Enemy_Large'),
                 ('skull', 'platformer_game_pack/Skull'), ('chest', 'platformer_game_pack/Chest')]:
    add('creatures', f'creatures/{dst}.glb', QS, f'public/glb/{src}.glb')
for dst, src in [('ghost', 'Flying/glTF/Ghost'), ('ghost_skull', 'Flying/glTF/Ghost_Skull'), ('pigeon', 'Flying/glTF/Pigeon'), ('bee', 'Flying/glTF/Armabee'),
                 ('yeti', 'Big/glTF/Yeti'), ('demon', 'Big/glTF/Demon'), ('mushroom_king', 'Big/glTF/MushroomKing'), ('ninja_big', 'Big/glTF/Ninja'),
                 ('blob_pink', 'Blob/glTF/PinkBlob'), ('blob_green', 'Blob/glTF/GreenBlob'), ('blob_spiky', 'Blob/glTF/GreenSpikyBlob'), ('blob_yeti', 'Blob/glTF/Yeti'),
                 ('mushnub', 'Blob/glTF/Mushnub'), ('chicken', 'Blob/glTF/Chicken'), ('cat', 'Blob/glTF/Cat'), ('dog', 'Blob/glTF/Dog')]:
    add('creatures', f'creatures/{dst}.glb', MON[0], MON[1] + src + '.gltf')

# дополнительные списки (окружение, предметы) лежат в props_manifest.py, если он есть
try:
    import props_manifest
    props_manifest.register(add)
except ImportError:
    pass


def fetch(repo, path):
    local = os.path.join(CACHE, repo, path)
    if os.path.exists(local) and os.path.getsize(local) > 200:
        return local
    os.makedirs(os.path.dirname(local), exist_ok=True)
    url = f"repos/{repo}/contents/{urllib.parse.quote(path)}"
    with open(local + '.part', 'wb') as f:
        r = subprocess.run(['gh', 'api', url, '-H', 'Accept: application/vnd.github.raw'], stdout=f, stderr=subprocess.PIPE)
    if r.returncode != 0:
        os.remove(local + '.part')
        raise RuntimeError(f'{repo}/{path}: {r.stderr.decode()[:200]}')
    os.replace(local + '.part', local)
    return local


def one(item):
    group, dst, repo, path, mode = item
    out = os.path.join(OUT, dst)
    if os.path.exists(out) and not os.environ.get('FORCE'):
        return dst, 0, 'есть'
    src = fetch(repo, path)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    if mode == 'copy':
        shutil.copyfile(src, out)
    else:
        glbtool.convert(src, out, strip=(mode == 'strip'))
    return dst, os.path.getsize(out), mode


if __name__ == '__main__':
    want = sys.argv[1:]
    items = [m for m in M if not want or any(m[0].startswith(w) for w in want)]
    tot = 0; n = 0
    with cf.ThreadPoolExecutor(6) as ex:
        for dst, size, how in ex.map(one, items):
            if size:
                n += 1; tot += size
    print(f'{len(items)} по списку, записано {n} файлов, {tot / 1048576:.1f} МБ')
