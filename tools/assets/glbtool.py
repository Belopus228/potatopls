#!/usr/bin/env python3
"""Мелкий инструмент для glTF/GLB без зависимостей.

  glbtool.py pack  in.(gltf|glb) out.glb           — упаковать в один GLB (base64/внешние буферы -> BIN)
  glbtool.py strip in.(gltf|glb) out.glb           — то же, но без анимаций (скелет и скин остаются)
  glbtool.py info  in.(gltf|glb)                   — краткая сводка

Используется, чтобы анимации людей лежали в одном файле на риг, а не в каждой модели.
"""
import sys, os, json, struct, base64


def load(path):
    raw = open(path, 'rb').read()
    if raw[:4] == b'glTF':
        jl = struct.unpack('<I', raw[12:16])[0]
        g = json.loads(raw[20:20 + jl])
        off = 20 + jl
        bins = []
        while off < len(raw):
            cl, ct = struct.unpack('<II', raw[off:off + 8])
            if ct == 0x004E4942:
                bins.append(raw[off + 8:off + 8 + cl])
            off += 8 + cl
        bufs = []
        for i, b in enumerate(g.get('buffers', [])):
            if 'uri' in b:
                bufs.append(_uri(b['uri'], path))
            else:
                bufs.append(bins[0] if bins else b'')
        return g, bufs
    g = json.loads(raw.decode('utf8'))
    return g, [_uri(b['uri'], path) for b in g.get('buffers', [])]


def _uri(uri, path):
    if uri.startswith('data:'):
        return base64.b64decode(uri.split(',', 1)[1])
    return open(os.path.join(os.path.dirname(path), uri), 'rb').read()


def repack(g, bufs, strip_anims=False, keep_anims=None):
    """Собирает один буфер только из используемых bufferView. keep_anims — список имён (после '|'), которые оставить."""
    g = json.loads(json.dumps(g))
    if strip_anims:
        g.pop('animations', None)
    elif keep_anims is not None and 'animations' in g:
        g['animations'] = [a for a in g['animations'] if a.get('name', '').split('|')[-1] in keep_anims]
    acc = g.get('accessors', [])
    used = set()
    for m in g.get('meshes', []):
        for p in m.get('primitives', []):
            used.update(p.get('attributes', {}).values())
            if 'indices' in p:
                used.add(p['indices'])
            for t in p.get('targets', []):
                used.update(t.values())
    for s in g.get('skins', []):
        if 'inverseBindMatrices' in s:
            used.add(s['inverseBindMatrices'])
    for a in g.get('animations', []):
        for s in a['samplers']:
            used.add(s['input']); used.add(s['output'])
    amap = {old: new for new, old in enumerate(sorted(used))}
    new_acc = [acc[i] for i in sorted(used)]
    bvs = g.get('bufferViews', [])
    used_bv = set()
    for a in new_acc:
        if 'bufferView' in a:
            used_bv.add(a['bufferView'])
        if 'sparse' in a:
            used_bv.add(a['sparse']['indices']['bufferView']); used_bv.add(a['sparse']['values']['bufferView'])
    for im in g.get('images', []):
        if 'bufferView' in im:
            used_bv.add(im['bufferView'])
    bmap = {}
    out = bytearray()
    new_bvs = []
    for i in sorted(used_bv):
        bv = dict(bvs[i])
        data = bufs[bv.get('buffer', 0)][bv.get('byteOffset', 0):bv.get('byteOffset', 0) + bv['byteLength']]
        while len(out) % 4:
            out.append(0)
        bv['buffer'] = 0; bv['byteOffset'] = len(out)
        out += data
        bmap[i] = len(new_bvs); new_bvs.append(bv)
    for a in new_acc:
        if 'bufferView' in a:
            a['bufferView'] = bmap[a['bufferView']]
        if 'sparse' in a:
            a['sparse']['indices']['bufferView'] = bmap[a['sparse']['indices']['bufferView']]
            a['sparse']['values']['bufferView'] = bmap[a['sparse']['values']['bufferView']]
    for im in g.get('images', []):
        if 'bufferView' in im:
            im['bufferView'] = bmap[im['bufferView']]
        elif 'uri' in im and im['uri'].startswith('data:'):
            pass
    for m in g.get('meshes', []):
        for p in m.get('primitives', []):
            p['attributes'] = {k: amap[v] for k, v in p['attributes'].items()}
            if 'indices' in p:
                p['indices'] = amap[p['indices']]
            if 'targets' in p:
                p['targets'] = [{k: amap[v] for k, v in t.items()} for t in p['targets']]
    for s in g.get('skins', []):
        if 'inverseBindMatrices' in s:
            s['inverseBindMatrices'] = amap[s['inverseBindMatrices']]
    for a in g.get('animations', []):
        for s in a['samplers']:
            s['input'] = amap[s['input']]; s['output'] = amap[s['output']]
    g['accessors'] = new_acc
    g['bufferViews'] = new_bvs
    while len(out) % 4:
        out.append(0)
    g['buffers'] = [{'byteLength': len(out)}]
    return g, bytes(out)


def save_glb(path, g, bin_):
    js = json.dumps(g, separators=(',', ':'), ensure_ascii=False).encode('utf8')
    while len(js) % 4:
        js += b' '
    total = 12 + 8 + len(js) + 8 + len(bin_)
    os.makedirs(os.path.dirname(path) or '.', exist_ok=True)
    with open(path, 'wb') as f:
        f.write(b'glTF' + struct.pack('<II', 2, total))
        f.write(struct.pack('<II', len(js), 0x4E4F534A) + js)
        f.write(struct.pack('<II', len(bin_), 0x004E4942) + bin_)


def convert(src, dst, strip=False, keep=None):
    g, bufs = load(src)
    g2, b2 = repack(g, bufs, strip_anims=strip, keep_anims=keep)
    save_glb(dst, g2, b2)
    return os.path.getsize(dst)


if __name__ == '__main__':
    cmd = sys.argv[1]
    if cmd in ('pack', 'strip'):
        n = convert(sys.argv[2], sys.argv[3], strip=(cmd == 'strip'))
        print(f'{sys.argv[3]}: {n // 1024} KB')
    elif cmd == 'info':
        g, bufs = load(sys.argv[2])
        print({k: len(v) for k, v in g.items() if isinstance(v, list)}, 'bin', sum(len(b) for b in bufs) // 1024, 'KB')
        print('animations:', [a.get('name') for a in g.get('animations', [])])
