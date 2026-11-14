#!/usr/bin/env python3
"""Музыка и звуки «Меллстройность 3D». Всё синтезируется из формул: ни одного чужого сэмпла.

Запуск:  pip install numpy soundfile
         python3 tools/audio/make_audio.py            # всё
         python3 tools/audio/make_audio.py music boss # только указанные дорожки / звуки
Результат: game/assets/audio/music/*.ogg (зацикленные дорожки) и game/assets/audio/sfx/*.wav.
"""
import os
import sys
import numpy as np
import soundfile as sf

SR = 32000
OUT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'game', 'assets', 'audio'))
TAU = 2.0 * np.pi
MAJ = [0, 2, 4, 5, 7, 9, 11]
MIN = [0, 2, 3, 5, 7, 8, 10]
DOR = [0, 2, 3, 5, 7, 9, 10]
PHR = [0, 1, 3, 5, 7, 8, 10]
HMIN = [0, 2, 3, 5, 7, 8, 11]
LYD = [0, 2, 4, 6, 7, 9, 11]
NOISE = np.random.default_rng(1989)


def f_of(m):
    return 440.0 * 2.0 ** ((m - 69) / 12.0)


def adsr(n, a, d, s, r):
    an, dn, rn = max(1, int(a * SR)), max(1, int(d * SR)), max(1, int(r * SR))
    e = np.full(n, s, np.float32)
    k = min(an, n)
    e[:k] = np.linspace(0.0, 1.0, k, endpoint=False)
    k2 = min(an + dn, n)
    if k2 > an:
        e[an:k2] = np.linspace(1.0, s, k2 - an)
    k3 = min(rn, n)
    e[n - k3:] *= np.linspace(1.0, 0.0, k3)
    return e


def harm(f, n, kind='saw', bright=6000.0, vib=0.0, vib_hz=5.5):
    """Сумма гармоник до частоты bright: пила, меандр или треугольник без алиасинга."""
    t = np.arange(n, dtype=np.float32) / SR
    ph = TAU * f * t
    if vib:
        ph = ph + (vib * f / vib_hz) * np.sin(TAU * vib_hz * t)
    top = min(bright, SR * 0.45)
    out = np.zeros(n, np.float32)
    for k in range(1, max(1, int(top / f)) + 1):
        if kind in ('square', 'tri') and k % 2 == 0:
            continue
        w = 1.0 / k
        if kind == 'tri':
            w = (1.0 / (k * k)) * (1.0 if (k // 2) % 2 == 0 else -1.0)
        w *= max(0.0, 1.0 - 0.7 * (k * f / top) ** 4)
        out += np.float32(w) * np.sin(k * ph)
    return out


def noise(n, lp=1, hp=False):
    x = NOISE.standard_normal(n + 64).astype(np.float32)
    if lp > 1:
        x = np.convolve(x, np.ones(lp, np.float32) / lp, mode='same')
    if hp:
        x = np.diff(x, prepend=x[0])
    return x[:n]


# ---------- инструменты (частота, длительность в секундах) ----------

def i_lead(f, dur, bright=3600.0):
    n = int((dur + 0.09) * SR)
    x = harm(f, n, 'saw', bright, vib=0.006) + 0.45 * harm(f * 1.005, n, 'square', bright * 0.7)
    return x * adsr(n, 0.012, 0.12, 0.68, 0.09) * 0.42


def i_pulse(f, dur, bright=3000.0):
    n = int((dur + 0.05) * SR)
    return harm(f, n, 'square', bright) * adsr(n, 0.004, 0.09, 0.45, 0.05) * 0.5


def i_bass(f, dur, bright=700.0):
    n = int((dur + 0.04) * SR)
    t = np.arange(n, dtype=np.float32) / SR
    x = harm(f, n, 'saw', bright) * 0.7 + np.sin(TAU * f * t) * 0.9
    return x * adsr(n, 0.004, 0.1, 0.72, 0.04) * 0.6


def i_sub(f, dur, _b=0.0):
    n = int((dur + 0.06) * SR)
    t = np.arange(n, dtype=np.float32) / SR
    return (np.sin(TAU * f * t) + 0.25 * np.sin(TAU * 2 * f * t)) * adsr(n, 0.01, 0.2, 0.8, 0.06) * 0.8


def i_pluck(f, dur, bright=5200.0):
    n = int((max(dur, 0.25) + 0.25) * SR)
    t = np.arange(n, dtype=np.float32) / SR
    out = np.zeros(n, np.float32)
    for k in range(1, max(1, int(min(bright, SR * 0.45) / f)) + 1):
        out += np.float32(1.0 / k) * np.sin(TAU * f * k * t * (1.0 + 0.0004 * k * k)) * np.exp(-t * (2.4 + 1.5 * k))
    out[:48] *= np.linspace(0.0, 1.0, 48)
    return out * 0.75


def i_bell(f, dur, bright=0.0):
    n = int((max(dur, 0.3) + 0.5) * SR)
    t = np.arange(n, dtype=np.float32) / SR
    x = np.sin(TAU * f * t + 2.2 * np.exp(-t * 6.0) * np.sin(TAU * f * 3.5 * t)) * np.exp(-t * 4.2)
    x += 0.3 * np.sin(TAU * f * 2.0 * t) * np.exp(-t * 7.0)
    x[:32] *= np.linspace(0.0, 1.0, 32)
    return x * 0.5


def i_box(f, dur, bright=0.0):
    n = int((max(dur, 0.3) + 0.7) * SR)
    t = np.arange(n, dtype=np.float32) / SR
    x = np.sin(TAU * f * t) * np.exp(-t * 3.2) + 0.35 * np.sin(TAU * f * 4.07 * t) * np.exp(-t * 9.0) + 0.15 * np.sin(TAU * f * 6.8 * t) * np.exp(-t * 14.0)
    x[:24] *= np.linspace(0.0, 1.0, 24)
    return x * 0.5


def i_ep(f, dur, bright=0.0):
    n = int((dur + 0.3) * SR)
    t = np.arange(n, dtype=np.float32) / SR
    x = np.sin(TAU * f * t + 0.9 * np.exp(-t * 5.0) * np.sin(TAU * f * 2.0 * t)) * (0.35 + 0.65 * np.exp(-t * 2.6))
    x *= 1.0 + 0.12 * np.sin(TAU * 4.2 * t)
    return x * adsr(n, 0.006, 0.2, 0.8, 0.28) * 0.5


def i_organ(f, dur, bright=0.0):
    n = int((dur + 0.1) * SR)
    t = np.arange(n, dtype=np.float32) / SR
    ph = TAU * f * t + 0.004 * f / 5.8 * np.sin(TAU * 5.8 * t) * TAU
    x = sum(w * np.sin(k * ph) for k, w in ((0.5, 0.5), (1, 1.0), (2, 0.6), (3, 0.35), (4, 0.3), (6, 0.12), (8, 0.08)))
    return x.astype(np.float32) * adsr(n, 0.03, 0.05, 0.9, 0.1) * 0.3


def i_pad(f, dur, bright=2000.0):
    n = int((dur + 0.5) * SR)
    x = harm(f * 0.996, n, 'saw', bright) + harm(f * 1.004, n, 'saw', bright) + 0.6 * harm(f * 2.002, n, 'tri', bright)
    return x * adsr(n, min(0.6, dur * 0.4), 0.3, 0.8, 0.5) * 0.22


def i_reed(f, dur, bright=2600.0):
    n = int((dur + 0.07) * SR)
    x = harm(f * 0.997, n, 'square', bright) + harm(f * 1.004, n, 'saw', bright) * 0.6
    return x * adsr(n, 0.03, 0.08, 0.8, 0.07) * 0.3


INST = {'lead': i_lead, 'pulse': i_pulse, 'bass': i_bass, 'sub': i_sub, 'pluck': i_pluck, 'bell': i_bell, 'box': i_box, 'ep': i_ep,
        'organ': i_organ, 'pad': i_pad, 'reed': i_reed}
_note_cache = {}


def note(inst, midi, dur, bright=None):
    key = (inst, midi, round(dur, 3), bright)
    if key not in _note_cache:
        fn = INST[inst]
        _note_cache[key] = (fn(f_of(midi), dur) if bright is None else fn(f_of(midi), dur, bright)).astype(np.float32)
    return _note_cache[key]


# ---------- ударные ----------

def d_kick(f0=135.0, f1=42.0, dur=0.34, punch=1.0):
    n = int(dur * SR)
    t = np.arange(n, dtype=np.float32) / SR
    f = f1 + (f0 - f1) * np.exp(-t * 30.0)
    x = np.sin(TAU * np.cumsum(f) / SR) * np.exp(-t * 9.5)
    x[:160] += noise(160, 2) * np.linspace(0.5, 0.0, 160) * punch
    return (x * 0.95).astype(np.float32)


def d_snare(dur=0.2, tone=185.0):
    n = int(dur * SR)
    t = np.arange(n, dtype=np.float32) / SR
    return (noise(n, 2, True) * np.exp(-t * 24.0) * 1.3 + np.sin(TAU * tone * t) * np.exp(-t * 32.0) * 0.5).astype(np.float32) * 0.6


def d_hat(dur=0.05, k=70.0):
    n = int(dur * SR)
    t = np.arange(n, dtype=np.float32) / SR
    return (noise(n, 1, True) * np.exp(-t * k)).astype(np.float32) * 0.3


def d_clap():
    n = int(0.2 * SR)
    t = np.arange(n, dtype=np.float32) / SR
    e = sum(np.exp(-np.maximum(t - d, 0.0) * 90.0) * (t >= d) for d in (0.0, 0.012, 0.026)) + np.exp(-t * 20.0) * 0.5
    return (noise(n, 3, True) * e).astype(np.float32) * 0.4


def d_tom(f=92.0, dur=0.4):
    n = int(dur * SR)
    t = np.arange(n, dtype=np.float32) / SR
    ff = f * (1.0 + 0.5 * np.exp(-t * 25.0))
    return (np.sin(TAU * np.cumsum(ff) / SR) * np.exp(-t * 8.0)).astype(np.float32) * 0.8


def d_rim():
    n = int(0.05 * SR)
    t = np.arange(n, dtype=np.float32) / SR
    return (np.sin(TAU * 1700.0 * t) * np.exp(-t * 120.0) + noise(n, 1, True) * np.exp(-t * 200.0) * 0.5).astype(np.float32) * 0.45


DRUM = {'k': d_kick(), 's': d_snare(), 'h': d_hat(), 'o': d_hat(0.22, 16.0), 'c': d_clap(), 't': d_tom(), 'T': d_tom(64.0, 0.5), 'r': d_rim(),
        'K': d_kick(110.0, 36.0, 0.5, 0.4)}


# ---------- песня ----------

class Song:
    def __init__(self, bpm, bars, root, scale, chords):
        self.bpm, self.bars, self.root, self.scale, self.chords = bpm, bars, root, scale, chords
        self.spb = 60.0 / bpm
        self.n = int(round(bars * 4 * self.spb * SR))
        self.tr = {}

    def add(self, track, beat, sig, gain=1.0):
        buf = self.tr.setdefault(track, np.zeros(self.n, np.float32))
        i = int(round(beat * self.spb * SR)) % self.n
        sig = sig[:self.n]
        end = i + len(sig)
        if end <= self.n:
            buf[i:end] += sig * gain
        else:
            k = self.n - i
            buf[i:] += sig[:k] * gain
            buf[:end - self.n] += sig[k:] * gain

    def deg(self, d, octv=0):
        """d — ступень лада с нуля (0 — тоника), может выходить за октаву."""
        return self.root + self.scale[d % 7] + 12 * (d // 7 + octv)

    def chord(self, bar):
        return self.chords[bar % len(self.chords)] - 1

    def play(self, track, inst, beat, dur_beats, midi, gain=1.0, bright=None):
        self.add(track, beat, note(inst, midi, dur_beats * self.spb, bright), gain)

    # --- слои ---
    def pad(self, track, inst, bars, octv=0, gain=1.0, bright=None, voices=(0, 2, 4)):
        for b in bars:
            c = self.chord(b)
            for v in voices:
                self.play(track, inst, b * 4, 4.0, self.deg(c + v, octv), gain, bright)

    def stabs(self, track, inst, bars, rhythm, octv=0, gain=1.0, dur=0.4, bright=None, voices=(0, 2, 4)):
        for b in bars:
            c = self.chord(b)
            for i, ch in enumerate(rhythm):
                if ch == 'x':
                    for v in voices:
                        self.play(track, inst, b * 4 + i * 4.0 / len(rhythm), dur, self.deg(c + v, octv), gain, bright)

    def bass(self, track, inst, bars, pattern, octv=-2, gain=1.0, bright=None):
        """pattern — строка на такт: цифра — ступень аккорда (0 тоника, 2 терция, 4 квинта, 7 октава), '.' — тянуть, '-' — пауза."""
        for b in bars:
            c = self.chord(b)
            step = 4.0 / len(pattern)
            i = 0
            while i < len(pattern):
                ch = pattern[i]
                if ch in '-.':
                    i += 1
                    continue
                j = i + 1
                while j < len(pattern) and pattern[j] == '.':
                    j += 1
                self.play(track, inst, b * 4 + i * step, (j - i) * step * 0.92, self.deg(c + int(ch), octv), gain, bright)
                i = j

    def arp(self, track, inst, bars, pattern, octv=0, gain=1.0, dur=0.45, bright=None):
        for b in bars:
            c = self.chord(b)
            step = 4.0 / len(pattern)
            for i, ch in enumerate(pattern):
                if ch not in '-.':
                    self.play(track, inst, b * 4 + i * step, dur, self.deg(c + int(ch), octv), gain, bright)

    def drums(self, bars, **rows):
        """rows: k='x...x...', s=…, h=… — 16 шагов на такт; x — в полную силу, o — тише."""
        for b in bars:
            for name, row in rows.items():
                step = 4.0 / len(row)
                for i, ch in enumerate(row):
                    if ch in 'xo':
                        self.add('drum_' + name, b * 4 + i * step, DRUM[name], 1.0 if ch == 'x' else 0.5)

    def melody(self, seed, density=0.55, span=(0, 9)):
        """Фраза на 4 такта: ритмический мотив из двух тактов, сильные доли — аккордовые тоны, слабые — поступенно."""
        r = np.random.default_rng(seed)
        motif = []
        for _ in range(2):
            row = [1 if ((i % 4 == 0 and r.random() < 0.9) or (i % 2 == 0 and r.random() < density) or r.random() < density * 0.4) else 0 for i in range(8)]
            row[0] = 1
            motif.append(row)
        out = []
        cur = 4
        for bi in range(4):
            tones = [self.chord(bi) + k for k in (0, 2, 4)]
            last = bi == 3
            ons = [i for i in range(8) if motif[bi % 2][i]]
            if last:
                ons = [i for i in ons if i < 5] or [0]
            for j, i in enumerate(ons):
                nxt = ons[j + 1] if j + 1 < len(ons) else 8
                final = last and j == len(ons) - 1
                if i % 4 == 0 or final:
                    cands = [c for c in (t + 7 * o for t in tones for o in (-1, 0, 1, 2)) if span[0] <= c <= span[1]]
                    cur = min(cands, key=lambda c: abs(c - cur) + (0.7 if c == cur else 0.0) + r.random() * 0.8)
                else:
                    cur = int(np.clip(cur + int(r.choice([-2, -1, -1, 1, 1, 2])), span[0], span[1]))
                out.append((bi * 4 + i * 0.5, ((8 - i) * 0.5 * 0.9) if final else (nxt - i) * 0.5, cur))
        return out

    def phrase(self, track, inst, notes, at_bar, octv=1, gain=1.0, bright=None, legato=0.95):
        for beat, dur, d in notes:
            self.play(track, inst, at_bar * 4 + beat, dur * legato, self.deg(d, octv), gain, bright)

    def mix(self, levels, delay=0.0, reverb=0.0, wet=()):
        """levels: {дорожка: громкость}. Эхо и «зал» считаются по кругу, поэтому петля бесшовная."""
        dry = np.zeros(self.n, np.float32)
        fx = np.zeros(self.n, np.float32)
        for name, buf in self.tr.items():
            g = levels.get(name, levels.get(name.split('_')[0], 1.0))
            # общий баланс: низ не должен забивать мелодию, тарелкам — чуть больше воздуха
            if name in ('bass',):
                g *= 0.42
            elif name in ('drum_k', 'drum_K', 'drum_T', 'drum_t'):
                g *= 0.55
            elif name in ('drum_h', 'drum_o', 'drum_r', 'drum_c'):
                g *= 1.7
            dry += buf * g
            if name in wet or name.split('_')[0] in wet:
                fx += buf * g
        out = dry.copy()
        if delay > 0.0:
            d = int(round(self.spb * 0.75 * SR))
            out += delay * np.roll(fx, d) + delay * 0.45 * np.roll(fx, 2 * d) + delay * 0.2 * np.roll(fx, 3 * d)
        if reverb > 0.0:
            rv = np.zeros(self.n, np.float32)
            for i, ms in enumerate((23, 37, 53, 71, 89, 113, 139, 167, 199, 241, 283, 331, 389, 449)):
                rv += np.roll(fx, int(ms * SR / 1000)) * (0.72 ** i) * (1.0 if i % 2 == 0 else -1.0)
            out += reverb * np.convolve(rv, np.ones(5, np.float32) / 5.0, mode='same')
        # уровень: основная масса сигнала — до 0.7, пики мягко прижимаются
        out = out / max(1e-6, float(np.percentile(np.abs(out), 99.7))) * 0.7
        out = np.tanh(out * 1.1) / np.tanh(1.1)
        return out / max(1e-6, float(np.max(np.abs(out)))) * 0.82


def rng_bars(a, b):
    return list(range(a, b))


# ---------- дорожки ----------

def song_menu():
    s = Song(96, 16, 57, MIN, [1, 6, 3, 7])
    s.pad('pad', 'pad', rng_bars(0, 16), 0, 1.0)
    s.arp('arp', 'bell', rng_bars(0, 16), '02479742', 1, 0.5)
    s.bass('bass', 'bass', rng_bars(4, 16), '0..0..0.', -2, 1.0)
    s.drums(rng_bars(4, 16), k='x.......x.x.....', h='..x...x...x...x.')
    s.drums(rng_bars(8, 16), c='....x.......x...')
    a, b = s.melody(11, 0.45), s.melody(12, 0.5)
    s.phrase('lead', 'lead', a, 4, 1, 0.8, 2600.0)
    s.phrase('lead', 'lead', b, 8, 1, 0.8, 2600.0)
    s.phrase('lead', 'lead', a, 12, 1, 0.8, 2600.0)
    return s.mix({'pad': 0.9, 'arp': 0.5, 'bass': 0.8, 'drum': 0.7, 'lead': 0.6}, 0.3, 0.35, ('arp', 'lead', 'pad'))


def song_dorm():
    s = Song(84, 16, 50, MIN, [1, 4, 7, 3, 6, 4, 5, 1])
    s.stabs('ep', 'ep', rng_bars(0, 16), 'x..x..x.', 0, 0.8, 1.2, None, (0, 2, 4, 6))
    s.bass('bass', 'bass', rng_bars(0, 16), '0...-.4.0.-.2.4.', -1, 1.0, 500.0)
    s.drums(rng_bars(2, 16), k='x.....x...x.....', r='....x.......x...', h='x.x.x.x.x.x.x.xo')
    a, b = s.melody(21, 0.4, (0, 8)), s.melody(22, 0.5, (0, 8))
    s.phrase('lead', 'box', a, 4, 1, 0.9)
    s.phrase('lead', 'box', b, 8, 1, 0.9)
    s.phrase('lead', 'box', a, 12, 1, 0.9)
    return s.mix({'ep': 0.9, 'bass': 0.85, 'drum': 0.6, 'lead': 0.75}, 0.22, 0.4, ('ep', 'lead'))


def song_murino():
    s = Song(112, 16, 52, MIN, [1, 1, 6, 7])
    s.bass('bass', 'bass', rng_bars(0, 16), '00070007', -2, 1.0, 900.0)
    s.pad('pad', 'pad', rng_bars(0, 16), 0, 0.9, 1700.0)
    s.arp('arp', 'pulse', rng_bars(4, 16), '0.2.4.2.7.4.2.4.', 1, 0.45, 0.2)
    s.drums(rng_bars(0, 4), k='x.......x.......', h='..x...x...x...x.')
    s.drums(rng_bars(4, 16), k='x.....x.x.......', s='....x.......x...', h='x.x.x.x.x.x.x.x.')
    s.drums([7, 11, 15], o='..............x.')
    a, b = s.melody(31, 0.6), s.melody(32, 0.55)
    s.phrase('lead', 'lead', a, 4, 1, 0.85)
    s.phrase('lead', 'lead', b, 8, 1, 0.85)
    s.phrase('lead', 'lead', a, 12, 1, 0.85)
    s.phrase('lead2', 'pulse', a, 12, 2, 0.3)
    return s.mix({'bass': 0.85, 'pad': 0.7, 'arp': 0.45, 'drum': 0.8, 'lead': 0.62, 'lead2': 0.5}, 0.28, 0.25, ('lead', 'lead2', 'arp'))


def song_milk():
    s = Song(120, 16, 55, MAJ, [1, 4, 5, 1, 1, 4, 5, 5])
    s.bass('bass', 'bass', rng_bars(0, 16), '0.4.0.4.', -2, 1.0, 650.0)
    s.stabs('reed', 'reed', rng_bars(0, 16), '.x.x.x.x', 0, 0.8, 0.22)
    s.drums(rng_bars(2, 16), k='x.......x.......', r='....x.......x...', h='..x...x...x...x.')
    s.drums([7, 15], t='........x.x.x.x.')
    a, b = s.melody(41, 0.7, (2, 11)), s.melody(42, 0.75, (2, 11))
    s.phrase('lead', 'pluck', a, 0, 1, 1.0)
    s.phrase('lead', 'pluck', b, 4, 1, 1.0)
    s.phrase('lead', 'pluck', a, 8, 1, 1.0)
    s.phrase('lead', 'pluck', b, 12, 1, 1.0)
    s.phrase('lead2', 'reed', a, 8, 1, 0.5)
    return s.mix({'bass': 0.8, 'reed': 0.55, 'drum': 0.65, 'lead': 0.95, 'lead2': 0.5}, 0.12, 0.25, ('lead', 'reed'))


def song_myt():
    s = Song(126, 16, 60, LYD, [1, 2, 6, 5])
    s.arp('arp', 'bell', rng_bars(0, 16), '0247' * 4, 1, 0.5, 0.3)
    s.bass('bass', 'bass', rng_bars(0, 16), '0.-0..7.0.-0.4..', -2, 1.0, 800.0)
    s.stabs('pulse', 'pulse', rng_bars(4, 16), '..x...x.', 0, 0.5, 0.2)
    s.drums(rng_bars(0, 4), h='x.x.x.x.x.x.x.x.')
    s.drums(rng_bars(4, 16), k='x...x...x...x...', c='....x.......x...', h='..x...x...x...x.', o='..............o.')
    a, b = s.melody(51, 0.65, (2, 11)), s.melody(52, 0.6, (2, 11))
    s.phrase('lead', 'bell', a, 4, 1, 1.0)
    s.phrase('lead', 'bell', b, 8, 1, 1.0)
    s.phrase('lead', 'bell', a, 12, 1, 1.0)
    s.phrase('lead2', 'pulse', b, 12, 1, 0.35)
    return s.mix({'arp': 0.4, 'bass': 0.8, 'pulse': 0.4, 'drum': 0.7, 'drum_h': 0.4, 'drum_o': 0.3, 'lead': 0.8, 'lead2': 0.5}, 0.25, 0.3, ('arp', 'lead'))


def song_banya():
    s = Song(92, 16, 57, DOR, [1, 4, 1, 7, 1, 4, 5, 1])
    s.pad('reed', 'reed', rng_bars(0, 16), 0, 0.5, 1500.0)
    s.bass('bass', 'bass', rng_bars(0, 16), '0..0..4.', -2, 1.0, 500.0)
    s.drums(rng_bars(0, 16), T='x.....x.........', t='........x.....x.', r='....x.......x.x.')
    s.drums(rng_bars(4, 16), h='..x...x...x...x.')
    a, b = s.melody(61, 0.6, (0, 9)), s.melody(62, 0.5, (0, 9))
    s.phrase('lead', 'pluck', a, 2, 1, 1.0, 3000.0)
    s.phrase('lead', 'pluck', b, 6, 1, 1.0, 3000.0)
    s.phrase('lead', 'pluck', a, 10, 1, 1.0, 3000.0)
    s.arp('arp', 'box', rng_bars(8, 16), '0.4.2.4.', 1, 0.4, 0.5)
    return s.mix({'reed': 0.6, 'bass': 0.85, 'drum': 0.7, 'lead': 0.9, 'arp': 0.4}, 0.2, 0.4, ('lead', 'arp', 'reed'))


def song_jmur():
    s = Song(76, 16, 49, HMIN, [1, 1, 4, 5, 1, 6, 4, 5])
    s.pad('organ', 'organ', rng_bars(0, 16), 0, 0.9)
    s.bass('bass', 'sub', rng_bars(0, 16), '0.......', -1, 1.0)
    s.arp('box', 'box', rng_bars(0, 16), '0.4.2.7.4.2.', 2, 0.6, 0.6)
    s.drums(rng_bars(4, 16), K='x.........x.....', r='........x.......')
    a, b = s.melody(71, 0.35, (0, 8)), s.melody(72, 0.4, (0, 8))
    s.phrase('lead', 'organ', a, 4, 1, 0.9)
    s.phrase('lead', 'organ', b, 8, 1, 0.9)
    s.phrase('lead', 'bell', a, 12, 1, 0.7)
    return s.mix({'organ': 0.7, 'bass': 0.9, 'box': 0.5, 'drum': 0.7, 'lead': 0.6}, 0.3, 0.6, ('box', 'lead', 'organ'))


def song_fog():
    s = Song(70, 16, 47, PHR, [1, 1, 2, 1, 1, 6, 2, 1])
    s.pad('pad', 'pad', rng_bars(0, 16), 0, 1.0, 1500.0, (0, 4, 7))
    s.pad('pad2', 'pad', rng_bars(0, 16), 1, 0.4, 1200.0, (0, 2))
    s.bass('bass', 'sub', rng_bars(0, 16), '0.......', -1, 1.0)
    s.drums(rng_bars(0, 16), K='x..x............')
    s.drums(rng_bars(8, 16), T='..........x...x.')
    a = s.melody(81, 0.25, (0, 7))
    s.phrase('lead', 'bell', a, 4, 2, 0.6)
    s.phrase('lead', 'bell', a, 12, 2, 0.6)
    s.arp('box', 'box', rng_bars(8, 12), '0...1...', 2, 0.35, 1.0)
    return s.mix({'pad': 1.0, 'pad2': 0.6, 'bass': 0.8, 'drum': 0.6, 'lead': 0.6, 'box': 0.5}, 0.35, 0.7, ('lead', 'box', 'pad', 'pad2'))


def song_boss():
    s = Song(150, 16, 52, PHR, [1, 1, 2, 1, 1, 1, 6, 7])
    s.bass('bass', 'bass', rng_bars(0, 16), '0000070000070040', -2, 1.0, 1100.0)
    s.stabs('stab', 'lead', rng_bars(0, 16), 'x..x..x.', 0, 0.6, 0.18, 3000.0)
    s.drums(rng_bars(0, 16), k='x...x...x...x.x.', s='....x.......x...', h='x.x.x.x.x.x.x.x.')
    s.drums([3, 7, 11, 15], s='....x.......x.xx', t='..........x.....')
    s.drums(rng_bars(8, 16), o='..x...x...x...x.')
    a, b = s.melody(91, 0.7, (0, 10)), s.melody(92, 0.75, (0, 10))
    s.phrase('lead', 'lead', a, 0, 1, 0.9, 4200.0)
    s.phrase('lead', 'lead', b, 4, 1, 0.9, 4200.0)
    s.phrase('lead', 'lead', a, 8, 1, 0.9, 4200.0)
    s.phrase('lead', 'lead', b, 12, 1, 0.9, 4200.0)
    s.phrase('lead2', 'pulse', a, 8, 2, 0.35)
    s.phrase('lead2', 'pulse', b, 12, 2, 0.35)
    return s.mix({'bass': 0.9, 'stab': 0.5, 'drum': 0.85, 'drum_h': 0.3, 'drum_o': 0.22, 'lead': 0.75, 'lead2': 0.5}, 0.18, 0.2, ('lead', 'lead2', 'stab'))


def song_win():
    s = Song(110, 8, 60, MAJ, [1, 4, 5, 1, 6, 4, 5, 1])
    s.pad('pad', 'pad', rng_bars(0, 8), 0, 0.8)
    s.bass('bass', 'bass', rng_bars(0, 8), '0.0.4.0.', -2, 1.0)
    s.arp('arp', 'bell', rng_bars(0, 8), '02479742', 1, 0.5, 0.3)
    s.drums(rng_bars(0, 8), k='x.......x.x.....', c='....x.......x...', h='x.x.x.x.x.x.x.x.')
    a, b = s.melody(101, 0.6, (2, 11)), s.melody(102, 0.6, (2, 11))
    s.phrase('lead', 'lead', a, 0, 1, 0.9)
    s.phrase('lead', 'lead', b, 4, 1, 0.9)
    return s.mix({'pad': 0.7, 'bass': 0.8, 'arp': 0.5, 'drum': 0.7, 'lead': 0.65}, 0.25, 0.3, ('lead', 'arp'))


SONGS = {'menu': song_menu, 'dorm': song_dorm, 'murino': song_murino, 'milk': song_milk, 'myt': song_myt, 'banya': song_banya,
         'jmur': song_jmur, 'fog': song_fog, 'boss': song_boss, 'win': song_win}


# ---------- звуки ----------

def tt(dur):
    return np.arange(int(dur * SR), dtype=np.float32) / SR


def sweep(f0, f1, dur, kind='sin', k=None):
    t = tt(dur)
    f = f0 + (f1 - f0) * (t / dur if k is None else 1.0 - np.exp(-t * k))
    ph = TAU * np.cumsum(f) / SR
    return np.sin(ph) if kind == 'sin' else np.sign(np.sin(ph)) * 0.6


def seq(*parts):
    return np.concatenate([p.astype(np.float32) for p in parts])


def at(total, *items):
    out = np.zeros(int(total * SR), np.float32)
    for when, sig in items:
        i = int(when * SR)
        sig = sig[:len(out) - i]
        out[i:i + len(sig)] += sig
    return out


def vowel(f0, dur, formants, drop=0.9):
    t = tt(dur)
    f = f0 * (1.0 - (1.0 - drop) * t / dur)
    ph = TAU * np.cumsum(f) / SR
    out = np.zeros(len(t), np.float32)
    for k in range(1, int(4200 / f0)):
        w = sum(a * np.exp(-((k * f0 - fc) / bw) ** 2) for fc, bw, a in formants) + 0.04
        out += np.float32(w / k ** 0.3) * np.sin(k * ph)
    return out


def sfx_all():
    e = np.exp
    S = {}
    S['item'] = at(0.4, (0.0, note('bell', 81, 0.1)), (0.08, note('bell', 88, 0.2)))
    t = tt(0.14)
    S['land'] = noise(len(t), 12) * e(-t * 40) * 1.5 + np.sin(TAU * 70 * t) * e(-t * 30)
    t = tt(0.16)
    S['jump'] = sweep(280, 620, 0.16) * e(-t * 9) * np.minimum(1.0, t * 200)
    t = tt(0.06)
    S['step'] = noise(len(t), 14) * e(-t * 90) * 1.6 + np.sin(TAU * 95 * t) * e(-t * 80) * 0.5
    t = tt(0.2)
    S['swing'] = noise(len(t), 5, True) * np.sin(np.pi * t / 0.2) ** 2 * (0.6 + 0.4 * np.sin(TAU * 9 * t))
    t = tt(0.14)
    S['hit'] = noise(len(t), 4) * e(-t * 45) * 1.4 + sweep(190, 60, 0.14) * e(-t * 28)
    t = tt(0.34)
    S['hit_big'] = noise(len(t), 5) * e(-t * 22) * 1.5 + sweep(140, 36, 0.34) * e(-t * 11) * 1.2 + noise(len(t), 1, True) * e(-t * 60) * 0.4
    t = tt(0.3)
    S['roll'] = noise(len(t), 16) * np.sin(np.pi * t / 0.3) ** 1.5 * 1.8
    t = tt(0.22)
    S['hurt'] = sweep(420, 170, 0.22, 'sq') * e(-t * 10) + noise(len(t), 3) * e(-t * 40) * 0.6
    S['deny'] = at(0.3, (0.0, harm(150, int(0.1 * SR), 'square', 1500) * adsr(int(0.1 * SR), 0.004, 0.02, 0.8, 0.02)),
                   (0.13, harm(118, int(0.15 * SR), 'square', 1500) * adsr(int(0.15 * SR), 0.004, 0.02, 0.8, 0.03)))
    t = tt(0.18)
    S['throw'] = noise(len(t), 4, True) * np.sin(np.pi * t / 0.18) * 0.8 + sweep(300, 700, 0.18) * 0.25 * np.sin(np.pi * t / 0.18)
    t = tt(0.4)
    S['spray'] = noise(len(t), 1, True) * np.minimum(1.0, t * 60) * e(-np.maximum(t - 0.25, 0) * 22) * (0.75 + 0.25 * np.sin(TAU * 31 * t))
    am = [seq(vowel(165 - i * 8, 0.13, ((750, 160, 1.0), (1150, 200, 0.7), (2500, 400, 0.2))) * adsr(int(0.13 * SR), 0.01, 0.03, 0.9, 0.02),
              vowel(150 - i * 8, 0.1, ((260, 120, 1.0), (1000, 300, 0.12))) * adsr(int(0.1 * SR), 0.01, 0.02, 0.7, 0.05) * 0.8) for i in range(3)]
    S['am'] = at(0.9, (0.0, am[0]), (0.26, am[1]), (0.52, am[2] * 1.15))
    S['eat'] = at(0.5, *[(d, noise(int(0.07 * SR), 6) * e(-tt(0.07) * 38) * (1.0 + 0.5 * np.sin(TAU * 40 * tt(0.07)))) for d in (0.0, 0.14, 0.29)])
    S['alert'] = at(0.36, (0.0, i_pulse(660, 0.09)), (0.13, i_pulse(880, 0.16)))
    t = tt(0.28)
    S['dash'] = noise(len(t), 7, True) * np.sin(np.pi * t / 0.28) ** 1.3 + sweep(200, 70, 0.28) * e(-t * 9) * 0.6
    t = tt(0.17)
    S['shoot'] = sweep(950, 280, 0.17, 'sq') * e(-t * 13) * 0.7 + sweep(950, 280, 0.17) * e(-t * 13) * 0.5
    t = tt(0.32)
    S['die'] = sweep(330, 70, 0.32, 'sq') * e(-t * 8) * 0.6 + noise(len(t), 5) * e(-t * 16)
    S['coin'] = at(0.4, (0.0, i_pulse(f_of(83), 0.06) * 0.7), (0.07, note('bell', 88, 0.25)))
    t = tt(0.16)
    S['crate'] = noise(len(t), 6) * e(-t * 35) * 1.5 + np.sin(TAU * 230 * t) * e(-t * 45) * 0.6 + np.sin(TAU * 330 * t) * e(-t * 60) * 0.3
    S['break'] = at(0.5, *[(d, noise(int(0.1 * SR), int(l)) * e(-tt(0.1) * 40) * a) for d, l, a in ((0.0, 4, 1.5), (0.05, 8, 1.2), (0.11, 3, 0.9), (0.19, 6, 0.8), (0.3, 5, 0.5))])
    t = tt(0.55)
    S['door'] = harm(96, len(t), 'saw', 1800, vib=0.05, vib_hz=7.0) * np.maximum(np.sin(np.pi * np.minimum(t / 0.45, 1.0)), 0.0) * 0.5 * (0.6 + 0.4 * np.sin(TAU * 23 * t)) + at(0.55, (0.44, S['crate'] * 0.8))
    t = tt(0.05)
    S['ui'] = np.sin(TAU * 1040 * t) * e(-t * 70) + np.sin(TAU * 1560 * t) * e(-t * 90) * 0.4
    t = tt(0.06)
    S['blip'] = harm(440, len(t), 'tri', 3000) * adsr(len(t), 0.004, 0.02, 0.6, 0.02)
    S['lose'] = at(1.5, *[(i * 0.28, i_lead(f_of(m), 0.24 if i < 3 else 0.6, 2200.0)) for i, m in enumerate((64, 63, 62, 57))])
    S['open'] = at(0.6, *[(i * 0.07, note('bell', m, 0.25)) for i, m in enumerate((76, 81, 85, 88))])
    t = tt(1.7)
    S['boss_die'] = noise(len(t), 10) * e(-t * 2.6) * 2.0 + sweep(160, 30, 1.7) * e(-t * 2.2) + at(1.7, (0.0, S['hit_big']), (0.35, S['hit_big'] * 0.7), (0.8, S['hit_big'] * 0.5))
    t = tt(0.85)
    S['roar'] = (harm(72, len(t), 'saw', 1400, vib=0.03, vib_hz=3.0) * (0.55 + 0.45 * np.sin(TAU * 27 * t)) + noise(len(t), 8) * 0.9) * np.maximum(np.sin(np.pi * np.minimum(t / 0.8, 1.0)), 0.0) ** 0.7
    t = tt(0.55)
    S['crash'] = noise(len(t), 3) * e(-t * 12) * 1.4 + sweep(120, 34, 0.55) * e(-t * 7) * 1.3 + noise(len(t), 1, True) * e(-t * 40) * 0.5
    t = tt(0.6)
    S['phone'] = harm(170, len(t), 'square', 1200) * (np.sin(TAU * 2.5 * t) > -0.2) * (0.6 + 0.4 * np.sin(TAU * 38 * t)) * 0.6
    S['unlock'] = at(0.5, (0.0, S['crate'] * 0.7), (0.1, i_pulse(f_of(72), 0.08) * 0.7), (0.2, i_pulse(f_of(79), 0.18) * 0.7))
    S['win'] = at(1.5, *[(i * 0.11, i_lead(f_of(m), 0.14, 3200.0)) for i, m in enumerate((72, 76, 79))], (0.33, i_lead(f_of(84), 0.7, 3200.0)),
                  (0.33, i_lead(f_of(76), 0.7, 2400.0) * 0.6), (0.33, i_lead(f_of(79), 0.7, 2400.0) * 0.6))
    t = tt(1.1)
    S['lift'] = at(1.1, (0.0, note('bell', 88, 0.5)), (0.0, note('bell', 93, 0.5) * 0.6)) + np.sin(TAU * 55 * t) * 0.12 * np.sin(np.pi * t / 1.1)
    return S


def write_ogg(path, x):
    with sf.SoundFile(path, 'w', SR, 1, format='OGG', subtype='VORBIS') as f:
        for i in range(0, len(x), 16000):
            f.write(x[i:i + 16000])


def main():
    want = set(sys.argv[1:])
    os.makedirs(os.path.join(OUT, 'music'), exist_ok=True)
    os.makedirs(os.path.join(OUT, 'sfx'), exist_ok=True)
    if not want or 'music' in want or want & set(SONGS):
        for name, fn in SONGS.items():
            if want and 'music' not in want and name not in want:
                continue
            x = fn().astype(np.float32)
            write_ogg(os.path.join(OUT, 'music', name + '.ogg'), x)
            print('music/%s.ogg  %.1f s' % (name, len(x) / SR))
    if not want or 'sfx' in want:
        for name, x in sfx_all().items():
            x = np.asarray(x, np.float32)
            n = min(len(x), int(0.006 * SR))
            x[-n:] *= np.linspace(1.0, 0.0, n)
            x = x / max(1e-6, float(np.max(np.abs(x)))) * 0.85
            sf.write(os.path.join(OUT, 'sfx', name + '.wav'), x, SR, subtype='PCM_16')
        print('sfx: %d файлов' % len(os.listdir(os.path.join(OUT, 'sfx'))))


if __name__ == '__main__':
    main()
