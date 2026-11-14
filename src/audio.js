// Звук: всё синтезируется на лету (WebAudio) — эффекты, «голос» и процедурная музыка
import { G, clamp } from './g.js';

const N = n => 440 * Math.pow(2, (n - 69) / 12);
const SC = { min: [0, 2, 3, 5, 7, 8, 10], maj: [0, 2, 4, 5, 7, 9, 11], phr: [0, 1, 3, 5, 7, 8, 10], pen: [0, 3, 5, 7, 10], dor: [0, 2, 3, 5, 7, 9, 10] };
// треки: bpm, тоника (midi), лад, аккорды (ступени), бас-рисунок, ударные, тембр
export const TRACKS = {
  menu: { bpm: 96, root: 45, sc: 'min', ch: [0, 5, 3, 4], bass: 'x..x..x.x..x..x.', kick: 'x...x...x...x...', hat: '..x...x...x...x.', sn: '....x.......x...', lead: .45, wave: 'triangle', pad: .5 },
  dorm: { bpm: 84, root: 43, sc: 'dor', ch: [0, 3, 0, 4], bass: 'x.....x...x.....', kick: 'x.......x.......', hat: '....x.......x...', sn: '', lead: .3, wave: 'sine', pad: .7 },
  murino: { bpm: 104, root: 41, sc: 'phr', ch: [0, 1, 0, 5], bass: 'x.x...x.x.x...x.', kick: 'x...x...x..x....', hat: '..x...x...x...xx', sn: '....x.......x...', lead: .4, wave: 'sawtooth', pad: .55 },
  village: { bpm: 132, root: 50, sc: 'min', ch: [0, 5, 2, 6], bass: 'x.xx..x.x.xx..x.', kick: 'x...x...x...x...', hat: '..x...x...x...x.', sn: '....x.......x..x', lead: .7, wave: 'square', pad: .3 },
  clean: { bpm: 110, root: 48, sc: 'maj', ch: [0, 4, 5, 3], bass: 'x...x...x...x.x.', kick: 'x.......x.....x.', hat: 'x.x.x.x.x.x.x.x.', sn: '....x.......x...', lead: .6, wave: 'triangle', pad: .7 },
  banya: { bpm: 92, root: 45, sc: 'pen', ch: [0, 3, 0, 2], bass: 'x..x....x..x..x.', kick: 'x.....x.x.......', hat: '', sn: '....x.......x...', lead: .5, wave: 'triangle', pad: .6 },
  boss: { bpm: 150, root: 40, sc: 'phr', ch: [0, 0, 1, 5], bass: 'xxx.xxx.xxx.xx.x', kick: 'x.x.x.x.x.x.x.xx', hat: 'xxxxxxxxxxxxxxxx', sn: '....x.......x...', lead: .65, wave: 'sawtooth', pad: .25 },
  fog: { bpm: 128, root: 38, sc: 'phr', ch: [0, 1, 4, 1], bass: 'x.xxx.x.x.xxx.xx', kick: 'x...x...x...x.x.', hat: '..x...x...x...x.', sn: '....x.......x...', lead: .6, wave: 'sawtooth', pad: .6 },
  win: { bpm: 120, root: 48, sc: 'maj', ch: [0, 3, 4, 0], bass: 'x.x.x.x.x.x.x.x.', kick: 'x...x...x...x...', hat: '..x...x...x...x.', sn: '....x.......x...', lead: .8, wave: 'square', pad: .5 },
};

export class Audio {
  constructor() { this.ctx = null; this.vol = .8; this.mvol = .5; this.track = null; this.step = 0; this.next = 0; this.seed = 1; }
  unlock() {
    if (this.ctx) { if (this.ctx.state === 'suspended') this.ctx.resume(); return; }
    const AC = window.AudioContext || window.webkitAudioContext; if (!AC) return;
    try {
      const c = this.ctx = new AC(); this.master = c.createGain(); this.comp = c.createDynamicsCompressor(); this.comp.threshold.value = -14; this.comp.ratio.value = 5; this.master.connect(this.comp); this.comp.connect(c.destination);
      this.sg = c.createGain(); this.mg = c.createGain(); this.sg.connect(this.master); this.mg.connect(this.master);
      const len = c.sampleRate, b = this.noiseBuf = c.createBuffer(1, len, c.sampleRate), d = b.getChannelData(0); for (let i = 0; i < len; i++) d[i] = Math.random() * 2 - 1;
      // простая реверберация для музыки
      const rl = c.sampleRate * 1.6, rb = c.createBuffer(2, rl, c.sampleRate); for (let ch = 0; ch < 2; ch++) { const dd = rb.getChannelData(ch); for (let i = 0; i < rl; i++) dd[i] = (Math.random() * 2 - 1) * Math.pow(1 - i / rl, 2.6); }
      this.rev = c.createConvolver(); this.rev.buffer = rb; const rg = c.createGain(); rg.gain.value = .35; this.rev.connect(rg); rg.connect(this.mg);
      this.setVol(this.vol, this.mvol);
    } catch (e) { this.ctx = null; }
  }
  setVol(v, m) { this.vol = v; this.mvol = m; if (this.ctx) { this.sg.gain.value = v; this.mg.gain.value = m * .55; } }
  // базовые кирпичики
  tone(f, d, o = {}) {
    const c = this.ctx; if (!c) return; const t = c.currentTime + (o.at || 0), os = c.createOscillator(), g = c.createGain(), v = (o.v ?? .3);
    os.type = o.w || 'sine'; os.frequency.setValueAtTime(f, t); if (o.to) os.frequency.exponentialRampToValueAtTime(Math.max(20, o.to), t + d);
    g.gain.setValueAtTime(0, t); g.gain.linearRampToValueAtTime(v, t + (o.a ?? .005)); g.gain.exponentialRampToValueAtTime(.0008, t + d);
    let out = g; if (o.lp) { const fl = c.createBiquadFilter(); fl.type = 'lowpass'; fl.frequency.setValueAtTime(o.lp, t); if (o.lpTo) fl.frequency.exponentialRampToValueAtTime(o.lpTo, t + d); g.connect(fl); out = fl; }
    os.connect(g); out.connect(o.dest || this.sg); if (o.rev) out.connect(this.rev); os.start(t); os.stop(t + d + .05);
  }
  noise(d, o = {}) {
    const c = this.ctx; if (!c) return; const t = c.currentTime + (o.at || 0), s = c.createBufferSource(), g = c.createGain(), f = c.createBiquadFilter(), v = o.v ?? .3;
    s.buffer = this.noiseBuf; s.loop = true; f.type = o.t || 'lowpass'; f.frequency.setValueAtTime(o.f || 1200, t); if (o.to) f.frequency.exponentialRampToValueAtTime(o.to, t + d); f.Q.value = o.q || .8;
    g.gain.setValueAtTime(0, t); g.gain.linearRampToValueAtTime(v, t + (o.a ?? .004)); g.gain.exponentialRampToValueAtTime(.0008, t + d);
    s.connect(f); f.connect(g); g.connect(o.dest || this.sg); s.start(t, Math.random() * .5); s.stop(t + d + .05);
  }
  sfx(n, k = 1) {
    if (!this.ctx || this.vol <= 0) return; const r = .92 + Math.random() * .16;
    switch (n) {
      case 'step': this.noise(.06, { f: 500 * r, v: .07 * k }); break;
      case 'jump': this.tone(260 * r, .16, { to: 520, w: 'triangle', v: .16 }); break;
      case 'land': this.noise(.12, { f: 300, v: .2 * k }); this.tone(90, .1, { to: 50, v: .2 * k }); break;
      case 'whoosh': this.noise(.16, { t: 'bandpass', f: 500 * r, to: 2200, q: 1.5, v: .16 }); break;
      case 'hit': this.noise(.09, { f: 1800 * r, v: .4 }); this.tone(170 * r, .12, { to: 60, w: 'square', v: .28, lp: 900 }); break;
      case 'hit2': this.noise(.14, { f: 2600, v: .5 }); this.tone(120 * r, .22, { to: 40, w: 'square', v: .4, lp: 700 }); break;
      case 'hurt': this.tone(330 * r, .22, { to: 110, w: 'sawtooth', v: .28, lp: 1400 }); this.noise(.1, { f: 900, v: .25 }); break;
      case 'coin': this.tone(1320 * r, .09, { w: 'square', v: .1 }); this.tone(1760 * r, .16, { w: 'square', v: .1, at: .07 }); break;
      case 'pick': this.tone(660, .1, { w: 'triangle', v: .2 }); this.tone(990, .18, { w: 'triangle', v: .2, at: .08 }); break;
      case 'item': [523, 659, 784, 1047].forEach((f, i) => this.tone(f, .22, { w: 'triangle', v: .2, at: i * .08 })); break;
      case 'ui': this.tone(880, .05, { w: 'square', v: .07 }); break;
      case 'ui2': this.tone(520, .07, { w: 'square', v: .08 }); this.tone(780, .08, { w: 'square', v: .08, at: .05 }); break;
      case 'deny': this.tone(160, .16, { w: 'square', v: .14 }); this.tone(120, .2, { w: 'square', v: .14, at: .12 }); break;
      case 'talk': this.tone(k * (300 + Math.random() * 120), .045, { w: 'square', v: .05, lp: 1800 }); break;
      case 'throw': this.noise(.2, { t: 'bandpass', f: 900, to: 3000, q: 2, v: .18 }); break;
      case 'cash': this.noise(.05, { t: 'highpass', f: 3000, v: .2 }); this.noise(.05, { t: 'highpass', f: 3500, v: .2, at: .06 }); break;
      case 'spray': this.noise(.12, { t: 'highpass', f: 4200 * r, v: .09 }); break;
      case 'eat': for (let i = 0; i < 3; i++) this.noise(.07, { f: 700 + i * 200, v: .25, at: i * .12 }); this.tone(520, .2, { w: 'sine', v: .15, at: .4, to: 780 }); break;
      case 'door': this.tone(110, .3, { to: 70, w: 'sawtooth', v: .2, lp: 500 }); this.noise(.25, { f: 400, v: .2 }); break;
      case 'lever': this.tone(240, .05, { w: 'square', v: .16 }); this.noise(.08, { f: 2200, v: .2, at: .04 }); break;
      case 'boom': this.noise(.7, { f: 900, to: 80, v: .7 }); this.tone(80, .6, { to: 28, v: .6 }); break;
      case 'slam': this.noise(.4, { f: 500, to: 90, v: .6 }); this.tone(60, .4, { to: 30, v: .6 }); break;
      case 'zap': this.tone(1400, .22, { to: 180, w: 'sawtooth', v: .18 }); this.noise(.15, { t: 'highpass', f: 2500, v: .16 }); break;
      case 'roar': this.tone(95 * r, .9, { to: 55, w: 'sawtooth', v: .42, lp: 700, lpTo: 250 }); this.noise(.9, { f: 600, to: 150, v: .3 }); break;
      case 'screech': this.tone(1700 * r, .5, { to: 900, w: 'sawtooth', v: .14 }); this.tone(1750 * r, .5, { to: 1100, w: 'square', v: .08 }); break;
      case 'squish': this.tone(210 * r, .14, { to: 70, w: 'sine', v: .32 }); this.noise(.1, { f: 900, v: .2 }); break;
      case 'splash': this.noise(.4, { t: 'bandpass', f: 1400, to: 500, q: .7, v: .32 }); break;
      case 'bubble': this.tone(420 * r, .12, { to: 950, v: .15 }); break;
      case 'steam': this.noise(.9, { t: 'highpass', f: 2600, v: .16, a: .1 }); break;
      case 'bell': [1, 2.01, 2.99, 4.2].forEach((m, i) => this.tone(520 * m, 1.1 / (i + 1), { v: .14 / (i + 1), rev: 1 })); break;
      case 'ding': this.tone(1047, .5, { v: .2 }); this.tone(1568, .7, { v: .14, at: .1 }); break;
      case 'quest': [392, 523, 659, 784].forEach((f, i) => this.tone(f, .3, { w: 'triangle', v: .18, at: i * .1 })); break;
      case 'win': [523, 659, 784, 1047, 784, 1047, 1319].forEach((f, i) => this.tone(f, .34, { w: 'square', v: .12, at: i * .12 })); break;
      case 'lose': [392, 370, 349, 262].forEach((f, i) => this.tone(f, .5, { w: 'sawtooth', v: .14, at: i * .22, lp: 1200 })); break;
      case 'power': this.tone(80, .9, { to: 640, w: 'sawtooth', v: .16, lp: 2000 }); break;
      case 'tram': this.tone(1900, .25, { v: .12 }); this.tone(1500, .35, { v: .12, at: .2 }); break;
      case 'fog': this.tone(58, 2.2, { to: 44, w: 'sawtooth', v: .3, lp: 300, a: .5 }); this.noise(2, { f: 300, v: .16, a: .6 }); break;
      case 'am': for (let i = 0; i < 3; i++) this.vox(i * .24, 150 - i * 8, k); break;
    }
  }
  // «голос»: слог «АМ» — пила через форманты
  vox(at, f0 = 150, k = 1) {
    const c = this.ctx; if (!c) return; const t = c.currentTime + at, os = c.createOscillator(), g = c.createGain(); os.type = 'sawtooth'; os.frequency.setValueAtTime(f0 * 1.08, t); os.frequency.linearRampToValueAtTime(f0 * .9, t + .2);
    g.gain.setValueAtTime(0, t); g.gain.linearRampToValueAtTime(.55 * k, t + .02); g.gain.setValueAtTime(.5 * k, t + .1); g.gain.exponentialRampToValueAtTime(.001, t + .22);
    for (const [fa, fm, q] of [[820, 260, 7], [1250, 1000, 9], [2600, 2300, 9]]) { const b = c.createBiquadFilter(); b.type = 'bandpass'; b.Q.value = q; b.frequency.setValueAtTime(fa, t); b.frequency.setValueAtTime(fa, t + .09); b.frequency.exponentialRampToValueAtTime(fm, t + .15); os.connect(b); b.connect(g); }
    g.connect(this.sg); os.start(t); os.stop(t + .26);
  }
  // ---------- музыка ----------
  music(name) { if (this.trackName === name) return; this.trackName = name; this.track = TRACKS[name] || null; this.step = 0; this.next = this.ctx ? this.ctx.currentTime + .15 : 0; this.mel = null; }
  rnd() { this.seed = (this.seed * 1664525 + 1013904223) >>> 0; return this.seed / 4294967296; }
  update() {
    const c = this.ctx, T = this.track; if (!c || !T || this.mvol <= 0 || c.state !== 'running') return;
    if (this.next < c.currentTime - .3) this.next = c.currentTime + .05;
    const sp = 60 / T.bpm / 4;
    while (this.next < c.currentTime + .18) { this.tick(T, this.step, this.next - c.currentTime, sp); this.step++; this.next += sp; }
  }
  tick(T, st, at, sp) {
    const s = st % 16, bar = (st >> 4) % 4, sc = SC[T.sc], deg = T.ch[bar], d = this.mg, on = (p) => p && p[s] === 'x';
    const note = (i, oct = 0) => N(T.root + sc[((deg + i) % sc.length + sc.length) % sc.length] + 12 * (oct + Math.floor((deg + i) / sc.length)));
    if (on(T.kick)) { this.tone(130, .16, { to: 42, v: .55, at, dest: d }); }
    if (on(T.sn)) { this.noise(.13, { t: 'bandpass', f: 1700, q: .7, v: .28, at, dest: d }); this.tone(190, .08, { to: 120, v: .16, at, dest: d }); }
    if (on(T.hat)) this.noise(.035, { t: 'highpass', f: 6500, v: .1, at, dest: d });
    if (on(T.bass)) this.tone(note(0, 0), sp * 1.7, { w: 'sawtooth', v: .26, lp: 520, lpTo: 180, at, dest: d });
    if (s === 0 && T.pad) for (const i of [0, 2, 4]) this.tone(note(i, 1), sp * 16, { w: 'triangle', v: .05 * T.pad, a: sp * 3, at, dest: d, rev: 1 });
    // мелодия: мотив на такт, повторяется с вариациями
    if (s === 0 && (bar === 0 || !this.mel)) { if (!this.mel || this.rnd() < .5) { this.mel = []; let p = 4 + (this.rnd() * 4 | 0); for (let i = 0; i < 16; i++) { if (this.rnd() < T.lead * (i % 2 ? .45 : .9)) { p += (this.rnd() * 5 | 0) - 2; p = clamp(p, 0, 9); this.mel.push(p); } else this.mel.push(-1); } } }
    const m = this.mel && this.mel[s]; if (m >= 0 && m !== undefined) this.tone(note(m, 1), sp * (1.6 + this.rnd() * 2), { w: T.wave, v: T.wave === 'sine' || T.wave === 'triangle' ? .14 : .065, lp: 2400, at, dest: d, rev: 1 });
  }
}
