#!/usr/bin/env python3
"""Рисует бесшовные текстуры для уровней (game/assets/tex/*.png). Нужны numpy и Pillow.

Всё процедурное и детерминированное: одинаковый результат при каждом запуске.
"""
import os, sys
import numpy as np
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(__file__), '..', '..', 'game', 'assets', 'tex')
N = 512


def noise(n=N, cells=8, seed=0):
    r = np.random.default_rng(seed)
    g = r.random((cells, cells))
    xs = np.arange(n) * cells / n
    x0 = np.floor(xs).astype(int) % cells
    fx = xs - np.floor(xs)
    fx = fx * fx * (3 - 2 * fx)
    x1 = (x0 + 1) % cells
    a = g[np.ix_(x0, x0)]; b = g[np.ix_(x0, x1)]; c = g[np.ix_(x1, x0)]; d = g[np.ix_(x1, x1)]
    FX = fx[None, :]; FY = fx[:, None]
    return (a * (1 - FX) + b * FX) * (1 - FY) + (c * (1 - FX) + d * FX) * FY


def fbm(n=N, base=4, octs=5, seed=0, gain=0.5):
    out = np.zeros((n, n)); amp = 1.0; tot = 0.0
    for o in range(octs):
        out += amp * noise(n, min(base * 2 ** o, n), seed + o * 17); tot += amp; amp *= gain
    return out / tot


def speck(seed, amt):
    return (np.random.default_rng(seed).random((N, N)) - 0.5) * amt


def col(c):
    return np.array([int(c[i:i + 2], 16) for i in (1, 3, 5)], dtype=np.float32) / 255.0


def mix(a, b, t):
    t = np.clip(t, 0, 1)[..., None]
    return a * (1 - t) + b * t


def shade(base, v):
    return np.clip(base[None, None, :] * v[..., None], 0, 1)


def save(name, arr, size=N):
    im = Image.fromarray((np.clip(arr, 0, 1) * 255 + 0.5).astype(np.uint8))
    if size != arr.shape[0]:
        im = im.resize((size, size), Image.LANCZOS)
    os.makedirs(OUT, exist_ok=True)
    im.save(os.path.join(OUT, name + '.png'), optimize=True)


def grid_lines(n_cells, width, n=N):
    """маска швов сетки n_cells × n_cells (1 — шов)"""
    m = np.zeros((n, n)); step = n // n_cells
    for i in range(n_cells):
        m[i * step:i * step + width, :] = 1; m[:, i * step:i * step + width] = 1
    return m


def asphalt():
    v = 0.92 + fbm(base=6, seed=1) * 0.22 + speck(2, 0.16)
    a = shade(col('#3b3d42'), v)
    peb = np.random.default_rng(3).random((N, N)) > 0.992
    a[peb] = a[peb] * 1.5 + 0.08
    save('asphalt', a)


def concrete():
    v = 0.9 + fbm(base=4, seed=5) * 0.2 + speck(6, 0.05)
    a = shade(col('#9a9c9e'), v)
    stains = fbm(base=3, seed=8)
    a = mix(a, a * np.array([0.78, 0.74, 0.7]), (stains - 0.55) * 4)
    save('concrete', a)


def panel():
    v = 0.92 + fbm(base=5, seed=11) * 0.16 + speck(12, 0.05)
    a = shade(col('#a7a59d'), v)
    seam = np.zeros((N, N)); seam[:7, :] = 1; seam[:, :7] = 1; seam[-3:, :] = 0.5; seam[:, -3:] = 0.5
    a = mix(a, a * 0.42, seam)
    # потёки под горизонтальным швом
    drip = np.clip((noise(N, 32, 13)[0:1, :] - 0.55) * 4, 0, 1) * np.clip(1 - np.arange(N)[:, None] / 150.0, 0, 1)
    a = mix(a, a * np.array([0.7, 0.66, 0.6]), drip)
    save('panel', a)


def brick():
    bw, bh, mort = 128, 64, 6
    a = np.zeros((N, N, 3), dtype=np.float32)
    r = np.random.default_rng(21)
    base = col('#8c3f2e'); m = col('#b9b2a6')
    a[:] = m
    grain = fbm(base=16, seed=22)
    for row in range(N // bh):
        off = (bw // 2) if row % 2 else 0
        for c in range(N // bw + 1):
            x0 = c * bw + off - bw; y0 = row * bh
            tone = base * (0.8 + r.random() * 0.4) * np.array([1, 0.92 + r.random() * 0.16, 0.9 + r.random() * 0.2])
            for xx in range(x0 + mort // 2, x0 + bw - mort // 2):
                a[y0 + mort // 2:y0 + bh - mort // 2, xx % N] = tone
    a *= (0.88 + grain * 0.24)[..., None]
    save('brick', a)


def plaster():
    v = 0.95 + fbm(base=6, seed=31) * 0.08 + speck(32, 0.02)
    strokes = noise(N, 64, 33)[:, 0:1] * 0.03
    save('plaster', shade(col('#f2f0ea'), v + strokes))


def wallpaper():
    a = np.zeros((N, N, 3), dtype=np.float32); a[:] = col('#d9c9a3')
    xs = np.arange(N)
    stripe = ((xs // 32) % 2)[None, :].repeat(N, 0)
    a = mix(a, col('#cdb98c')[None, None, :].repeat(N, 0).repeat(N, 1), stripe * 0.9)
    yy, xx = np.mgrid[0:N, 0:N]
    d = np.abs((xx % 64) - 32) + np.abs((yy % 64) - 32)
    a = mix(a, a * np.array([0.8, 0.72, 0.6]), (d < 9).astype(float))
    a = mix(a, a * 1.12, ((d > 12) & (d < 14)).astype(float))
    a *= (0.96 + fbm(base=8, seed=41) * 0.08)[..., None]
    save('wallpaper', a)


def wood(name, seed, vertical, tone):
    a = np.zeros((N, N, 3), dtype=np.float32)
    r = np.random.default_rng(seed)
    pl = 64
    grain = noise(N, 128, seed + 1)[:, 0:1].repeat(N, 1) * 0.5 + fbm(base=8, seed=seed + 2) * 0.5
    stretched = np.repeat(noise(N // 8, 16, seed + 3), 8, axis=1)[:N // 8].repeat(8, 0)
    base = col(tone)
    for i in range(N // pl):
        t = base * (0.82 + r.random() * 0.36)
        a[i * pl:(i + 1) * pl, :] = t
        a[i * pl:i * pl + 3, :] *= 0.45
        # торцевые стыки досок
        for j in range(2):
            x = int(r.random() * N)
            a[i * pl:(i + 1) * pl, x:x + 3] *= 0.5
    a *= (0.86 + grain * 0.18 + stretched * 0.1)[..., None]
    if vertical:
        a = np.transpose(a, (1, 0, 2))
    save(name, a)


def logs():
    a = np.zeros((N, N, 3), dtype=np.float32)
    n = 6; h = N / n
    yy = np.arange(N)
    prof = np.sin(((yy % h) / h) * np.pi)           # круглый профиль бревна
    v = 0.45 + 0.6 * prof
    grain = np.repeat(noise(N // 4, 32, 51), 4, axis=1)[:N // 4].repeat(4, 0)
    base = col('#9a6a3c')
    r = np.random.default_rng(52)
    for i in range(n):
        y0 = int(i * h); y1 = int((i + 1) * h)
        a[y0:y1, :] = base * (0.85 + r.random() * 0.3)
    a *= (v[:, None] * (0.85 + grain * 0.3))[..., None]
    save('logs', a)


def lino():
    yy, xx = np.mgrid[0:N, 0:N]
    d = (np.abs((xx % 128) - 64) + np.abs((yy % 128) - 64)) < 64
    a = np.where(d[..., None], col('#8a5a3a')[None, None, :], col('#b98a55')[None, None, :]).astype(np.float32)
    a *= (0.9 + fbm(base=6, seed=61) * 0.14 + speck(62, 0.05))[..., None]
    save('lino', a)


def tiles():
    a = np.zeros((N, N, 3), dtype=np.float32)
    r = np.random.default_rng(71); c = 4; s = N // c
    for i in range(c):
        for j in range(c):
            a[i * s:(i + 1) * s, j * s:(j + 1) * s] = col('#eef1f2') * (0.93 + r.random() * 0.08)
    yy, xx = np.mgrid[0:N, 0:N]
    hl = 1 + 0.05 * (1 - ((xx % s) + (yy % s)) / (2 * s))
    a *= hl[..., None]
    a = mix(a, col('#8d9498')[None, None, :].repeat(N, 0).repeat(N, 1), grid_lines(c, 5))
    save('tiles', a)


def mosaic():
    a = np.zeros((N, N, 3), dtype=np.float32)
    r = np.random.default_rng(81); c = 16; s = N // c
    pal = [col('#2f7fb5'), col('#3d9ad1'), col('#62b6e0'), col('#9fd8ee'), col('#e9f4f8'), col('#2a6a9c')]
    for i in range(c):
        for j in range(c):
            a[i * s:(i + 1) * s, j * s:(j + 1) * s] = pal[int(r.random() ** 1.3 * len(pal)) % len(pal)] * (0.95 + r.random() * 0.1)
    a = mix(a, col('#dfe9ee')[None, None, :].repeat(N, 0).repeat(N, 1), grid_lines(c, 3))
    save('mosaic', a)


def metal():
    streak = noise(N, 128, 91)[:, 0:1].repeat(N, 1)
    v = 0.9 + streak * 0.14 + fbm(base=8, seed=92) * 0.08
    save('metal', shade(col('#9aa0a8'), v))


def rust():
    v = 0.85 + fbm(base=6, seed=101) * 0.3
    a = shade(col('#6f7479'), v)
    blot = fbm(base=5, seed=102, octs=6)
    a = mix(a, shade(col('#8a4a22'), 0.8 + fbm(base=24, seed=103) * 0.5), (blot - 0.45) * 5)
    save('rust', a)


def garage():
    xs = np.arange(N)
    rib = 0.8 + 0.2 * np.sin(xs / N * np.pi * 2 * 12)
    v = rib[None, :].repeat(N, 0) * (0.92 + fbm(base=6, seed=111) * 0.16)
    a = shade(col('#5f7a6e'), v)
    blot = fbm(base=6, seed=112, octs=6)
    a = mix(a, shade(col('#7a4526'), 0.7 + fbm(base=20, seed=113) * 0.5), (blot - 0.58) * 6)
    save('garage', a)


def roof():
    ys = np.arange(N)
    wave = 0.75 + 0.25 * np.sin(ys / N * np.pi * 2 * 10)
    v = wave[:, None].repeat(N, 1) * (0.9 + fbm(base=6, seed=121) * 0.2)
    save('roof', shade(col('#6d6f73'), v))


def grass():
    v = fbm(base=5, seed=131, octs=6)
    a = mix(shade(col('#3f7a32'), 0.85 + v * 0.3), shade(col('#5c9a3a'), 0.9 + v * 0.2), (fbm(base=10, seed=132) - 0.4) * 3)
    r = np.random.default_rng(133)
    im = Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8)); d = ImageDraw.Draw(im)
    for i in range(2600):
        x = r.integers(0, N); y = r.integers(0, N); l = r.integers(3, 8); g = int(110 + r.random() * 90)
        d.line([(x, y), (x + r.integers(-2, 3), y - l)], fill=(int(g * 0.55), g, int(g * 0.35)), width=1)
    save('grass', np.asarray(im).astype(np.float32) / 255.0)


def dirt():
    v = 0.85 + fbm(base=5, seed=141, octs=6) * 0.3 + speck(142, 0.06)
    a = shade(col('#6b5238'), v)
    peb = np.random.default_rng(143).random((N, N)) > 0.994
    a[peb] = a[peb] * 1.5 + 0.06
    save('dirt', a)


def snow():
    v = fbm(base=4, seed=151, octs=5)
    a = mix(shade(col('#f4f7fb'), np.ones((N, N))), shade(col('#cfdcec'), np.ones((N, N))), (v - 0.45) * 2.2)
    sp = np.random.default_rng(152).random((N, N)) > 0.996
    a[sp] = 1.0
    save('snow', a)


def ice():
    v = fbm(base=4, seed=161)
    a = mix(shade(col('#a9d7ee'), np.ones((N, N))), shade(col('#d9f0fa'), np.ones((N, N))), (v - 0.4) * 2.5)
    im = Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8)); d = ImageDraw.Draw(im)
    r = np.random.default_rng(162)
    for i in range(9):
        x, y = r.integers(0, N), r.integers(0, N); ang = r.random() * 6.28
        pts = [(x, y)]
        for k in range(14):
            ang += (r.random() - 0.5) * 1.1
            x += np.cos(ang) * 26; y += np.sin(ang) * 26
            pts.append((x, y))
        for ox in (-N, 0, N):
            for oy in (-N, 0, N):
                d.line([(px + ox, py + oy) for px, py in pts], fill=(240, 250, 255), width=2)
    save('ice', np.asarray(im).astype(np.float32) / 255.0)


def carpet():
    yy, xx = np.mgrid[0:N, 0:N]
    a = np.zeros((N, N, 3), dtype=np.float32); a[:] = col('#7d1420')
    d = np.abs((xx % 128) - 64) + np.abs((yy % 128) - 64)
    a = mix(a, col('#c79a2e')[None, None, :].repeat(N, 0).repeat(N, 1), ((d > 44) & (d < 52)).astype(float))
    a = mix(a, col('#a81c2c')[None, None, :].repeat(N, 0).repeat(N, 1), (d < 20).astype(float))
    a *= (0.9 + speck(171, 0.16))[..., None]
    save('carpet', a)


def marble():
    w = fbm(base=3, seed=181, octs=6)
    yy, xx = np.mgrid[0:N, 0:N]
    vein = np.abs(np.sin((xx / N * 2 * np.pi * 2) + w * 9.0))
    a = shade(col('#ecebe6'), 0.96 + fbm(base=6, seed=182) * 0.06)
    a = mix(a, a * np.array([0.62, 0.64, 0.68]), (0.1 - vein) * 9)
    save('marble', a)


def facade(name, wall, seed, lit_frac=0.4, floors=4, bays=4, balcony=False, stripe=None):
    """Фасад: floors × bays окон на плитку. Вторая картинка *_e — карта свечения (горящие окна)."""
    r = np.random.default_rng(seed)
    a = shade(col(wall), 0.92 + fbm(base=6, seed=seed + 1) * 0.14 + speck(seed + 2, 0.04)).astype(np.float32)
    e = np.zeros((N, N, 3), dtype=np.float32)
    ch = N // floors; cw = N // bays
    for f in range(floors):
        a[f * ch:f * ch + 4, :] *= 0.55                   # межэтажный шов
        if stripe is not None and f % 2 == 0:
            a[f * ch + 4:f * ch + 22, :] = col(stripe) * 0.9
        for b in range(bays):
            if f == 0:
                a[:, b * cw:b * cw + 3] *= 0.6
            x0 = b * cw + int(cw * 0.22); x1 = b * cw + int(cw * 0.78)
            y0 = f * ch + int(ch * 0.26); y1 = f * ch + int(ch * 0.78)
            a[y0 - 4:y1 + 4, x0 - 4:x1 + 4] = col('#d8d6cf') * 0.9          # рама
            lit = r.random() < lit_frac
            if lit:
                warm = r.random()
                c = col('#ffd98a') if warm < 0.6 else (col('#bfe3ff') if warm < 0.85 else col('#ff9bb0'))
                a[y0:y1, x0:x1] = c * 0.95
                e[y0:y1, x0:x1] = c
                if r.random() < 0.5:                                         # шторы
                    k = int((x1 - x0) * (0.2 + r.random() * 0.3))
                    a[y0:y1, x0:x0 + k] *= 0.7; e[y0:y1, x0:x0 + k] *= 0.5
            else:
                a[y0:y1, x0:x1] = col('#26303c') * (0.8 + r.random() * 0.5)
                a[y0:y0 + (y1 - y0) // 3, x0:x1] *= 1.25                     # отражение неба
            a[y0:y1, (x0 + x1) // 2 - 1:(x0 + x1) // 2 + 2] = col('#d8d6cf') * 0.85   # переплёт
            if balcony and b % 2 == 1:
                a[y1 - 2:y1 + int(ch * 0.16), x0 - 12:x1 + 12] = col('#8f9498') * (0.8 + r.random() * 0.25)
                e[y1 - 2:y1 + int(ch * 0.16), x0 - 12:x1 + 12] = 0
    save(name, a)
    save(name + '_e', e)


if __name__ == '__main__':
    asphalt(); concrete(); panel(); brick(); plaster(); wallpaper()
    wood('wood', 45, False, '#a8733f'); wood('planks', 47, True, '#8d6a45')
    logs(); lino(); tiles(); mosaic(); metal(); rust(); garage(); roof(); grass(); dirt(); snow(); ice(); carpet(); marble()
    facade('facade_panel', '#a9a79f', 200, 0.4, balcony=True)
    facade('facade_new', '#e6e2d8', 210, 0.45, stripe='#d9772b')
    facade('facade_brick', '#9a5a44', 220, 0.35)
    facade('facade_dark', '#3a3d46', 230, 0.12)
    print('текстуры:', len(os.listdir(OUT)))
