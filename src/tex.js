// Процедурные текстуры (canvas) и общие материалы
import * as THREE from 'three';
import { rng, smooth, PI, TAU } from './g.js';

export const cv = (w, h = w) => { const c = document.createElement('canvas'); c.width = w; c.height = h; return c; };
export function tex(c, o = {}) {
  const t = new THREE.CanvasTexture(c);
  if (o.srgb !== false) t.colorSpace = THREE.SRGBColorSpace;
  if (o.rep !== false) t.wrapS = t.wrapT = THREE.RepeatWrapping;
  t.anisotropy = o.aniso || 8; return t;
}
const cache = {};
export const memo = (k, f) => cache[k] || (cache[k] = f());

// --- тайловый шум 256x256 ---
const N = 256, NA = new Float32Array(N * N);
(() => {
  const r = rng(1337);
  for (let o = 0; o < 5; o++) {
    const g = 4 << o, grid = new Float32Array(g * g), amp = 1 / (1 << o);
    for (let i = 0; i < g * g; i++) grid[i] = r();
    for (let y = 0; y < N; y++) for (let x = 0; x < N; x++) {
      const fx = x / N * g, fy = y / N * g, x0 = fx | 0, y0 = fy | 0, tx = fx - x0, ty = fy - y0;
      const sx = tx * tx * (3 - 2 * tx), sy = ty * ty * (3 - 2 * ty), x1 = (x0 + 1) % g, y1 = (y0 + 1) % g;
      const a = grid[y0 * g + x0], b = grid[y0 * g + x1], c = grid[y1 * g + x0], d = grid[y1 * g + x1];
      NA[y * N + x] += (a + (b - a) * sx + (c - a) * sy + (a - b - c + d) * sx * sy) * amp;
    }
  }
  for (let i = 0; i < N * N; i++) NA[i] /= 1.9375;
})();
export const nz = (x, y) => NA[((y | 0) & 255) * N + ((x | 0) & 255)];
export function px(c, fn) {
  const ctx = c.getContext('2d'), im = ctx.getImageData(0, 0, c.width, c.height), d = im.data, w = c.width, h = c.height;
  for (let y = 0, i = 0; y < h; y++) for (let x = 0; x < w; x++, i += 4) fn(x, y, d, i);
  ctx.putImageData(im, 0, 0); return c;
}
const grain = (c, amt, sc = 1, ox = 0) => px(c, (x, y, d, i) => { const n = (nz(x * sc + ox, y * sc + ox * 3) - .5) * amt; d[i] += n; d[i + 1] += n; d[i + 2] += n; });
const fill = (c, col) => { const g = c.getContext('2d'); g.fillStyle = col; g.fillRect(0, 0, c.width, c.height); return g; };
const gray = (c, fn) => px(c, (x, y, d, i) => { d[i] = d[i + 1] = d[i + 2] = fn(x, y); d[i + 3] = 255; });

export function normalMap(src, k = 2) {
  const w = src.width, h = src.height, s = src.getContext('2d').getImageData(0, 0, w, h).data, c = cv(w, h), ctx = c.getContext('2d'), o = ctx.createImageData(w, h), d = o.data;
  const H = (x, y) => s[(((y + h) % h) * w + ((x + w) % w)) * 4];
  for (let y = 0, i = 0; y < h; y++) for (let x = 0; x < w; x++, i += 4) {
    const dx = (H(x + 1, y) - H(x - 1, y)) / 255 * k, dy = (H(x, y + 1) - H(x, y - 1)) / 255 * k, l = 1 / Math.hypot(dx, dy, 1);
    d[i] = (-dx * l * .5 + .5) * 255; d[i + 1] = (dy * l * .5 + .5) * 255; d[i + 2] = (l * .5 + .5) * 255; d[i + 3] = 255;
  }
  ctx.putImageData(o, 0, 0); return tex(c, { srgb: false });
}

// ---------- текстуры поверхностей ----------
function asphalt(wet = .5) {
  const p0 = .74 - wet * .3, p1 = p0 + .12;
  const c = cv(512); fill(c, '#33363b');
  px(c, (x, y, d, i) => {
    const n = nz(x * 2, y * 2), m = nz(x * .5 + 40, y * .5 + 90), sp = nz(x * 7 + 11, y * 7 + 3), pud = smooth(p0, p1, m);
    const v = (n - .5) * 26 + (sp > .72 ? 20 : 0) - (sp < .25 ? 10 : 0) - pud * 22; d[i] += v; d[i + 1] += v; d[i + 2] += v + pud * 6;
  });
  const g = c.getContext('2d'), r = rng(5); g.strokeStyle = 'rgba(8,8,10,.5)'; g.lineWidth = 1.2;
  for (let k = 0; k < 9; k++) { let x = r() * 512, y = r() * 512; g.beginPath(); g.moveTo(x, y); for (let j = 0; j < 9; j++) { x += (r() - .5) * 70; y += (r() - .5) * 70; g.lineTo(x, y); } g.stroke(); }
  const rc = gray(cv(256), (x, y) => { const pud = smooth(p0, p1, nz(x + 40, y + 90)); return (1 - pud) * (200 + nz(x * 5, y * 5) * 55) + pud * 18; });
  const hc = gray(cv(256), (x, y) => (nz(x * 6, y * 6) * .6 + nz(x * 13 + 7, y * 13) * .4) * 255 * (1 - smooth(p0, p1, nz(x + 40, y + 90))));
  return { map: tex(c), rough: tex(rc, { srgb: false }), normal: normalMap(hc, 1.5) };
}
function concrete(base = [146, 148, 150]) {
  const c = cv(256); fill(c, `rgb(${base})`); grain(c, 30, 2); grain(c, 18, 7, 5);
  const g = c.getContext('2d');
  for (let k = 0; k < 14; k++) { const x = (k * 53) % 256, gr = g.createLinearGradient(0, 0, 0, 256); gr.addColorStop(0, 'rgba(40,36,30,.22)'); gr.addColorStop(1, 'rgba(40,36,30,0)'); g.fillStyle = gr; g.fillRect(x, 0, 6 + (k % 4) * 4, 256); }
  g.strokeStyle = 'rgba(0,0,0,.28)'; g.lineWidth = 2; g.strokeRect(1, 1, 254, 254);
  return tex(c);
}
function pavers() {
  const c = cv(256), g = fill(c, '#6d6f72'), r = rng(9);
  for (let y = 0; y < 8; y++) for (let x = 0; x < 8; x++) { const v = 120 + r() * 40 | 0; g.fillStyle = `rgb(${v},${v},${v + 4})`; g.fillRect(x * 32 + 1.5, y * 32 + 1.5, 29, 29); }
  grain(c, 26, 3); return tex(c);
}
function grass() {
  const c = cv(256); fill(c, '#3f6a2a');
  px(c, (x, y, d, i) => { const a = nz(x, y), b = nz(x * 5 + 9, y * 5), e = nz(x * 13, y * 13 + 31); d[i] += (a - .5) * 46 + (e - .5) * 30 + (b > .6 ? 18 : 0); d[i + 1] += (a - .5) * 50 + (e - .5) * 44; d[i + 2] += (a - .5) * 20 + (e - .5) * 14; });
  return tex(c);
}
function dirt() { const c = cv(256); fill(c, '#7a6248'); grain(c, 50, 2); grain(c, 40, 9, 3); px(c, (x, y, d, i) => { if (nz(x * 11 + 5, y * 11) > .74) { d[i] += 34; d[i + 1] += 30; d[i + 2] += 24; } }); return tex(c); }
function sand() { const c = cv(256); fill(c, '#d9c594'); grain(c, 24, 3); px(c, (x, y, d, i) => { const s = Math.sin((y + nz(x, y) * 40) / 256 * TAU * 12) * 9; d[i] += s; d[i + 1] += s; d[i + 2] += s * .8; }); return tex(c); }
function logs() {
  const c = cv(256); fill(c, '#96683c');
  const prof = y => Math.cos(((y % 64) / 64 - .5) * PI);       // 0 на стыке, 1 в центре бревна
  px(c, (x, y, d, i) => { const p = prof(y), gr = (nz(x, y * 8 + ((y / 64 | 0) * 37)) - .5) * 44, v = (p - .75) * 110 + gr; d[i] += v; d[i + 1] += v * .85; d[i + 2] += v * .6; });
  return { map: tex(c), normal: normalMap(gray(cv(128), (x, y) => Math.pow(prof(y * 2), .6) * 255), 5) };
}
function planks(base = [150, 112, 70], dark = 1) {
  const c = cv(256); fill(c, `rgb(${base})`); const r = rng(21), tone = []; for (let b = 0; b < 8; b++) tone.push((r() - .5) * 34 * dark);
  px(c, (x, y, d, i) => { const b = x >> 5, e = x & 31, gap = e < 1.5 || e > 30 ? -70 : 0, gr = (nz(x * 8 + b * 31, y + b * 57) - .5) * 40, v = tone[b] + gr + gap; d[i] += v; d[i + 1] += v * .85; d[i + 2] += v * .62; });
  return { map: tex(c), normal: normalMap(gray(cv(128), (x, y) => ((x & 15) < 1 ? 0 : 200) + nz(x * 16, y * 2) * 55), 2.2) };
}
function brick(a = [150, 70, 52]) {
  const c = cv(256), g = fill(c, '#b9b3a6'), r = rng(31);
  for (let y = 0; y < 16; y++) for (let x = -1; x < 8; x++) { const k = .8 + r() * .4; g.fillStyle = `rgb(${a[0] * k | 0},${a[1] * k | 0},${a[2] * k | 0})`; g.fillRect(x * 32 + (y & 1 ? 16 : 0) + 1.5, y * 16 + 1.5, 29, 13); }
  grain(c, 26, 5);
  return { map: tex(c), normal: normalMap(gray(cv(256), (x, y) => { const yy = y % 16, xx = (x + ((y >> 4) & 1 ? 16 : 0)) % 32; return (yy < 2 || xx < 2) ? 40 : 210; }), 2.5) };
}
function mosaic(pal = ['#2a7fb8', '#3aa0d0', '#e8f4fa', '#1f5f94', '#7fd0e8', '#3aa0d0'], grout = '#dfe9ee') {
  const c = cv(256), g = fill(c, grout), r = rng(41);
  for (let y = 0; y < 16; y++) for (let x = 0; x < 16; x++) { g.fillStyle = pal[r() * pal.length | 0]; g.fillRect(x * 16 + 1, y * 16 + 1, 14, 14); }
  grain(c, 10, 3);
  return { map: tex(c), normal: normalMap(gray(cv(128), (x, y) => ((x & 7) < 1 || (y & 7) < 1) ? 60 : 220), 1.6) };
}
function bigTiles(a = '#e4ecf1', b = '#a9d3e6') { const c = cv(128), g = fill(c, b); g.fillStyle = a; for (let y = 0; y < 2; y++) for (let x = 0; x < 2; x++) g.fillRect(x * 64 + 1.5, y * 64 + 1.5, 61, 61); grain(c, 8, 2); return tex(c); }
function wall2(paint = '#4c8a6a', top = '#d8d4c4') {
  const c = cv(64, 256), g = fill(c, top); g.fillStyle = paint; g.fillRect(0, 142, 64, 114); g.fillStyle = 'rgba(0,0,0,.35)'; g.fillRect(0, 140, 64, 3);
  const gr = g.createLinearGradient(0, 200, 0, 256); gr.addColorStop(0, 'rgba(30,24,16,0)'); gr.addColorStop(1, 'rgba(30,24,16,.4)'); g.fillStyle = gr; g.fillRect(0, 200, 64, 56);
  grain(c, 22, 4); return tex(c);
}
function lino(a = '#7d6149', b = '#a08465') { const c = cv(128), g = fill(c, a); g.fillStyle = b; g.fillRect(0, 0, 64, 64); g.fillRect(64, 64, 64, 64); grain(c, 26, 2); return tex(c); }
function ribs(base = '#6b6258') { const c = cv(128), g = fill(c, base); for (let x = 0; x < 128; x += 16) { g.fillStyle = 'rgba(255,255,255,.14)'; g.fillRect(x, 0, 5, 128); g.fillStyle = 'rgba(0,0,0,.22)'; g.fillRect(x + 11, 0, 5, 128); } grain(c, 18, 2); return tex(c); }
function glassWall() {
  const c = cv(256), g = fill(c, '#dfeaf2'), r = rng(51);
  for (let y = 0; y < 4; y++) for (let x = 0; x < 4; x++) { const gr = g.createLinearGradient(0, y * 64, 0, y * 64 + 64), k = r() * 30 | 0; gr.addColorStop(0, `rgb(${70 + k},${170 + k},${225})`); gr.addColorStop(1, `rgb(${30 + k},${110 + k},${190})`); g.fillStyle = gr; g.fillRect(x * 64 + 2, y * 64 + 2, 60, 60); g.fillStyle = 'rgba(255,255,255,.25)'; g.beginPath(); g.moveTo(x * 64 + 6, y * 64 + 40); g.lineTo(x * 64 + 40, y * 64 + 6); g.lineTo(x * 64 + 56, y * 64 + 6); g.lineTo(x * 64 + 6, y * 64 + 56); g.fill(); }
  return tex(c);
}
// панельный фасад: 6x6 окон на тайл, + карта свечения окон
function facade(seed, p) {
  const c = cv(512), g = fill(c, p.wall), e = cv(256), ge = fill(e, '#000'), r = rng(seed), cw = 512 / 6, ch = 512 / 6;
  const lits = ['#ffd98a', '#ffe9b8', '#ffcf70', '#dfe8ff', '#ffd98a', '#9fd0ff', '#ff6fd8'];
  for (let row = 0; row < 6; row++) for (let col = 0; col < 6; col++) {
    const x = col * cw, y = row * ch, acc = p.accent && (col === p.accCol || (p.accRow && row === 5));
    if (acc) { g.fillStyle = p.accent; g.fillRect(x, y, cw, ch); }
    g.strokeStyle = 'rgba(0,0,0,.22)'; g.lineWidth = 1.5; g.strokeRect(x + .5, y + .5, cw - 1, ch - 1);
    const lod = col % 3 === 1, wx = x + cw * (lod ? .1 : .22), wy = y + ch * .2, ww = cw * (lod ? .8 : .56), wh = ch * (lod ? .42 : .52), lit = r() < p.lit, lc = lits[r() * lits.length | 0];
    g.fillStyle = lit ? lc : `rgb(${22 + r() * 16 | 0},${32 + r() * 18 | 0},${46 + r() * 20 | 0})`; g.fillRect(wx, wy, ww, wh);
    if (lit) { g.fillStyle = 'rgba(120,70,20,.35)'; g.fillRect(wx, wy, ww * (.2 + r() * .25), wh); ge.fillStyle = lc; ge.fillRect(wx / 2 + 1, wy / 2 + 1, ww / 2 - 2, wh / 2 - 2); }
    else { g.fillStyle = 'rgba(160,190,220,.16)'; g.beginPath(); g.moveTo(wx, wy + wh); g.lineTo(wx + ww * .6, wy); g.lineTo(wx + ww, wy); g.lineTo(wx + ww * .4, wy + wh); g.fill(); }
    g.strokeStyle = p.frame || '#ecece8'; g.lineWidth = 2.4; g.strokeRect(wx, wy, ww, wh); g.beginPath(); g.moveTo(wx + ww * (lod ? .33 : .5), wy); g.lineTo(wx + ww * (lod ? .33 : .5), wy + wh); if (lod) { g.moveTo(wx + ww * .66, wy); g.lineTo(wx + ww * .66, wy + wh); } g.stroke();
    if (lod) { g.fillStyle = p.balc || '#8a8f96'; g.fillRect(wx - 2, wy + wh, ww + 4, ch * .26); g.strokeStyle = 'rgba(0,0,0,.3)'; g.lineWidth = 1; g.strokeRect(wx - 2, wy + wh, ww + 4, ch * .26); if (r() < .3) { g.fillStyle = '#d9d9d9'; g.fillRect(wx + ww * .6, wy + wh + 4, 14, 10); } }
    const st = g.createLinearGradient(0, wy + wh, 0, y + ch); st.addColorStop(0, 'rgba(30,26,20,.28)'); st.addColorStop(1, 'rgba(30,26,20,0)'); g.fillStyle = st; if (!lod) g.fillRect(wx + ww * .1, wy + wh + 2, ww * .8, ch * .24);
  }
  grain(c, 20, 2);
  return { map: tex(c), emi: tex(e) };
}

// ---------- спрайты, знаки, лица ----------
export const glowTex = () => memo('glow', () => { const c = cv(64), g = c.getContext('2d'), gr = g.createRadialGradient(32, 32, 0, 32, 32, 32); gr.addColorStop(0, 'rgba(255,255,255,1)'); gr.addColorStop(.25, 'rgba(255,255,255,.55)'); gr.addColorStop(1, 'rgba(255,255,255,0)'); g.fillStyle = gr; g.fillRect(0, 0, 64, 64); return tex(c, { rep: false }); });
export const puffTex = () => memo('puff', () => { const c = cv(64); px(c, (x, y, d, i) => { const r = Math.hypot(x - 32, y - 32) / 32, a = Math.max(0, 1 - r) * (0.55 + nz(x * 4, y * 4) * .9); d[i] = d[i + 1] = d[i + 2] = 255; d[i + 3] = Math.min(255, a * a * 330); }); return tex(c, { rep: false }); });
export const ringTex = () => memo('ring', () => { const c = cv(128), g = c.getContext('2d'), gr = g.createRadialGradient(64, 64, 30, 64, 64, 64); gr.addColorStop(0, 'rgba(255,255,255,0)'); gr.addColorStop(.7, 'rgba(255,255,255,.25)'); gr.addColorStop(.9, 'rgba(255,255,255,1)'); gr.addColorStop(1, 'rgba(255,255,255,0)'); g.fillStyle = gr; g.fillRect(0, 0, 128, 128); return tex(c, { rep: false }); });
export const discTex = () => memo('disc', () => { const c = cv(128), g = c.getContext('2d'), gr = g.createRadialGradient(64, 64, 0, 64, 64, 64); gr.addColorStop(0, 'rgba(255,255,255,.45)'); gr.addColorStop(.8, 'rgba(255,255,255,.6)'); gr.addColorStop(.93, 'rgba(255,255,255,1)'); gr.addColorStop(1, 'rgba(255,255,255,0)'); g.fillStyle = gr; g.fillRect(0, 0, 128, 128); return tex(c, { rep: false }); });
export const blobTex = () => memo('blob', () => { const c = cv(64), g = c.getContext('2d'), gr = g.createRadialGradient(32, 32, 0, 32, 32, 32); gr.addColorStop(0, 'rgba(0,0,0,.55)'); gr.addColorStop(1, 'rgba(0,0,0,0)'); g.fillStyle = gr; g.fillRect(0, 0, 64, 64); return tex(c, { rep: false }); });
export const webTex = () => memo('web', () => {
  const c = cv(256), g = c.getContext('2d'); g.strokeStyle = 'rgba(255,255,255,.85)'; g.lineWidth = 1.6; g.translate(128, 128);
  for (let i = 0; i < 14; i++) { const a = i / 14 * TAU; g.beginPath(); g.moveTo(0, 0); g.lineTo(Math.cos(a) * 180, Math.sin(a) * 180); g.stroke(); }
  g.lineWidth = 1; for (let k = 1; k < 9; k++) { g.beginPath(); for (let i = 0; i <= 14; i++) { const a = i / 14 * TAU, rr = k * 15 * (1 + .08 * Math.sin(i * 3 + k)); const x = Math.cos(a) * rr, y = Math.sin(a) * rr; i ? g.quadraticCurveTo(Math.cos(a - TAU / 28) * rr * .86, Math.sin(a - TAU / 28) * rr * .86, x, y) : g.moveTo(x, y); } g.stroke(); }
  return tex(c, { rep: false });
});
const FONT = 'Impact, "Arial Black", "DejaVu Sans", sans-serif';
export function signTex(text, o = {}) {
  const w = o.w || 512, h = o.h || 128, c = cv(w, h), g = c.getContext('2d');
  if (o.bg !== 'none') { g.fillStyle = o.bg || '#111'; g.fillRect(0, 0, w, h); }
  if (o.border) { g.strokeStyle = o.border; g.lineWidth = h * .07; g.strokeRect(h * .05, h * .05, w - h * .1, h - h * .1); }
  const lines = String(text).split('\n'); let fs = (h * .8) / lines.length; g.textAlign = 'center'; g.textBaseline = 'middle';
  g.font = `${o.bold === false ? '' : 'bold '}${fs}px ${o.font || FONT}`;
  const mw = Math.max(...lines.map(l => g.measureText(l).width)); if (mw > w * .9) { fs *= w * .9 / mw; g.font = `bold ${fs}px ${o.font || FONT}`; }
  lines.forEach((l, i) => { const y = h / 2 + (i - (lines.length - 1) / 2) * fs * 1.08; if (o.stroke) { g.strokeStyle = o.stroke; g.lineWidth = fs * .14; g.lineJoin = 'round'; g.strokeText(l, w / 2, y); } g.fillStyle = o.fg || '#fff'; g.fillText(l, w / 2, y); });
  return tex(c, { rep: false });
}
export function graffitiTex(ch, col, dots) {
  const c = cv(256), g = c.getContext('2d'); g.textAlign = 'center'; g.textBaseline = 'middle'; g.font = `bold 190px ${FONT}`; g.lineJoin = 'round';
  g.strokeStyle = 'rgba(0,0,0,.85)'; g.lineWidth = 22; g.strokeText(ch, 128, 108); g.strokeStyle = '#fff'; g.lineWidth = 9; g.strokeText(ch, 128, 108); g.fillStyle = col; g.fillText(ch, 128, 108);
  for (let i = 0; i < 5; i++) { g.fillStyle = col; g.fillRect(70 + i * 27, 150 + (i * 37 % 20), 5, 40 + (i * 53 % 40)); }
  for (let i = 0; i < dots; i++) { g.beginPath(); g.arc(128 + (i - (dots - 1) / 2) * 34, 232, 11, 0, TAU); g.fillStyle = '#fff'; g.fill(); g.lineWidth = 4; g.strokeStyle = '#000'; g.stroke(); }
  return tex(c, { rep: false });
}
// овальная маска-растушёвка для лица
export const featherTex = () => memo('feather', () => { const c = cv(64, 78), g = fill(c, '#000'); g.translate(32, 39); g.scale(32, 39); const gr = g.createRadialGradient(0, 0, .55, 0, 0, .98); gr.addColorStop(0, '#fff'); gr.addColorStop(1, '#000'); g.fillStyle = gr; g.fillRect(-1, -1, 2, 2); return tex(c, { rep: false, srgb: false }); });
export function photoTex(url) {
  return memo('ph' + url.slice(-40) + url.length, () => { const t = new THREE.Texture(cv(2)); t.colorSpace = THREE.SRGBColorSpace; const im = new Image(); im.onload = () => { t.image = im; t.needsUpdate = true; }; im.src = url; return t; });
}
// рисованное лицо: mood: 'smile' | 'angry' | 'tired' | 'creepy' | 'happy' | 'robot'
export function faceTex(o = {}) {
  const key = 'face' + JSON.stringify(o);
  return memo(key, () => {
    const c = cv(128, 156), g = fill(c, o.skin || '#e0ac8c'), m = o.mood || 'smile', ey = 62;
    const eye = (x) => {
      if (m === 'creepy') { g.fillStyle = '#000'; g.beginPath(); g.ellipse(x, ey, 15, 21, 0, 0, TAU); g.fill(); g.fillStyle = '#fff'; g.beginPath(); g.arc(x + 2, ey + 3, 2.5, 0, TAU); g.fill(); return; }
      g.fillStyle = '#fff'; g.beginPath(); g.ellipse(x, ey, 14, m === 'tired' ? 7 : 11, 0, 0, TAU); g.fill(); g.strokeStyle = 'rgba(0,0,0,.6)'; g.lineWidth = 2; g.stroke();
      g.fillStyle = o.eye || '#3a2a1a'; g.beginPath(); g.arc(x, ey + 1, m === 'happy' ? 7 : 5.5, 0, TAU); g.fill(); g.fillStyle = '#fff'; g.beginPath(); g.arc(x + 2, ey - 2, 2, 0, TAU); g.fill();
    };
    eye(40); eye(88);
    g.strokeStyle = o.brow || '#3a2a1a'; g.lineWidth = 5; g.lineCap = 'round'; const b = m === 'angry' ? 9 : m === 'tired' ? -4 : m === 'creepy' ? 0 : -2;
    if (m !== 'creepy') { g.beginPath(); g.moveTo(24, ey - 20 - b); g.lineTo(54, ey - 18 + b); g.moveTo(74, ey - 18 + b); g.lineTo(104, ey - 20 - b); g.stroke(); }
    g.strokeStyle = 'rgba(90,40,30,.55)'; g.lineWidth = 3; g.beginPath(); g.moveTo(64, 72); g.lineTo(60, 92); g.lineTo(68, 93); g.stroke();
    g.lineWidth = 4; g.strokeStyle = '#5a1f1a'; g.beginPath();
    if (m === 'smile' || m === 'happy') { g.arc(64, 104, 22, .15 * PI, .85 * PI); g.stroke(); if (m === 'happy') { g.fillStyle = '#fff'; g.beginPath(); g.arc(64, 106, 20, .12 * PI, .88 * PI); g.fill(); g.stroke(); } }
    else if (m === 'angry') { g.arc(64, 132, 22, 1.2 * PI, 1.8 * PI); g.stroke(); }
    else if (m === 'creepy') { g.strokeStyle = '#000'; g.lineWidth = 5; g.arc(64, 92, 34, .12 * PI, .88 * PI); g.stroke(); }
    else { g.moveTo(46, 116); g.lineTo(82, 116); g.stroke(); }
    if (o.stache) { g.fillStyle = o.stache; g.beginPath(); g.ellipse(64, 101, 22, 6, 0, 0, TAU); g.fill(); }
    if (o.blush) { g.fillStyle = 'rgba(255,90,90,.3)'; g.beginPath(); g.arc(26, 92, 10, 0, TAU); g.arc(102, 92, 10, 0, TAU); g.fill(); }
    return tex(c, { rep: false });
  });
}
export const fogFaceTex = () => memo('fogface', () => {
  const c = cv(512, 640), g = c.getContext('2d'), gr = g.createRadialGradient(256, 300, 40, 256, 320, 330); gr.addColorStop(0, '#fbfbf7'); gr.addColorStop(.75, '#d6d8dc'); gr.addColorStop(1, 'rgba(190,195,205,0)');
  g.fillStyle = gr; g.beginPath(); g.ellipse(256, 320, 236, 310, 0, 0, TAU); g.fill();
  const hole = (x, y, rx, ry) => { const h = g.createRadialGradient(x, y, 0, x, y, Math.max(rx, ry)); h.addColorStop(0, '#000'); h.addColorStop(.8, '#050506'); h.addColorStop(1, 'rgba(30,30,36,0)'); g.fillStyle = h; g.beginPath(); g.ellipse(x, y, rx, ry, 0, 0, TAU); g.fill(); };
  hole(160, 250, 62, 82); hole(352, 250, 62, 82); g.fillStyle = '#fff'; g.beginPath(); g.arc(170, 262, 7, 0, TAU); g.arc(362, 262, 7, 0, TAU); g.fill();
  g.strokeStyle = '#08080a'; g.lineWidth = 13; g.lineCap = 'round'; g.beginPath(); g.arc(256, 330, 170, .14 * PI, .86 * PI); g.stroke();
  g.lineWidth = 5; for (let i = 0; i < 9; i++) { const a = (.2 + i * .075) * PI; g.beginPath(); g.moveTo(256 + Math.cos(a) * 160, 330 + Math.sin(a) * 160); g.lineTo(256 + Math.cos(a) * 182, 330 + Math.sin(a) * 182); g.stroke(); }
  px(c, (x, y, d, i) => { const n = (nz(x, y) - .5) * 26; d[i] += n; d[i + 1] += n; d[i + 2] += n; });
  return tex(c, { rep: false });
});
export function tramTex() {
  return memo('tram', () => {
    const c = cv(512, 128), g = fill(c, '#1f6fd0'); g.fillStyle = '#f2f4f6'; g.fillRect(0, 0, 512, 16); g.fillStyle = '#e9edf0'; g.fillRect(0, 74, 512, 8); g.fillStyle = '#17539c'; g.fillRect(0, 104, 512, 24);
    for (let i = 0; i < 6; i++) { const x = 18 + i * 82; const gr = g.createLinearGradient(0, 22, 0, 70); gr.addColorStop(0, '#9fc4e6'); gr.addColorStop(1, '#27394d'); g.fillStyle = gr; g.fillRect(x, 24, 64, 44); g.strokeStyle = '#0d2a4d'; g.lineWidth = 3; g.strokeRect(x, 24, 64, 44); }
    g.fillStyle = '#ffd23a'; g.font = `bold 15px ${FONT}`; g.fillText('МОЛОЧНОЕ — МУРИНО', 170, 97); grain(c, 14, 2); return tex(c, { rep: false });
  });
}

// ---------- материалы ----------
const std = (o) => new THREE.MeshStandardMaterial(o);
const tile = (m, t) => { m.userData.tile = t; return m; };
export const C = (hex, rough = .8, metal = 0, extra) => memo(`c${hex}_${rough}_${metal}_${extra ? JSON.stringify(extra) : ''}`, () => std({ color: hex, roughness: rough, metalness: metal, ...extra }));
export const glowMat = (hex, k = 2) => memo(`g${hex}_${k}`, () => std({ color: 0x000000, emissive: hex, emissiveIntensity: k, roughness: 1 }));
const PALS = [
  { wall: '#c9c1b2', accent: '#d97a3a', accCol: 2, lit: .34, balc: '#9a938a' },
  { wall: '#aeb6bd', accent: '#4f86b8', accCol: 4, lit: .3, balc: '#7f8992' },
  { wall: '#d2cdbf', accent: '#7da35a', accCol: 0, accRow: 1, lit: .38, balc: '#a39d90' },
  { wall: '#8d8f94', lit: .22, balc: '#6f7277', frame: '#cfcfcf' },
];
export const M = {
  asphalt: (wet = .15) => memo('m.asph' + wet, () => { const t = asphalt(wet); return tile(std({ map: t.map, roughnessMap: t.rough, normalMap: t.normal, roughness: 1, metalness: 0, envMapIntensity: 1.4 }), 9); }),
  concrete: () => memo('m.conc', () => tile(std({ map: concrete(), roughness: .92 }), 4)),
  concDark: () => memo('m.concd', () => tile(std({ map: concrete([92, 94, 98]), roughness: .95 }), 4)),
  pavers: () => memo('m.pav', () => tile(std({ map: pavers(), roughness: .9 }), 3)),
  grass: () => memo('m.grass', () => tile(std({ map: grass(), roughness: 1 }), 7)),
  dirt: () => memo('m.dirt', () => tile(std({ map: dirt(), roughness: 1 }), 5)),
  sand: () => memo('m.sand', () => tile(std({ map: sand(), roughness: 1 }), 8)),
  logs: () => memo('m.logs', () => { const t = logs(); return tile(std({ map: t.map, normalMap: t.normal, roughness: .85 }), [3, 1.4]); }),
  planks: () => memo('m.planks', () => { const t = planks(); return tile(std({ map: t.map, normalMap: t.normal, roughness: .8 }), 2); }),
  planksDark: () => memo('m.planksd', () => { const t = planks([96, 66, 42], 1.4); return tile(std({ map: t.map, normalMap: t.normal, roughness: .75 }), 2.4); }),
  planksLight: () => memo('m.planksl', () => { const t = planks([206, 168, 112], .7); return tile(std({ map: t.map, normalMap: t.normal, roughness: .7 }), 2.2); }),
  brick: () => memo('m.brick', () => { const t = brick(); return tile(std({ map: t.map, normalMap: t.normal, roughness: .9 }), 2.4); }),
  mosaic: () => memo('m.mos', () => { const t = mosaic(); return tile(std({ map: t.map, normalMap: t.normal, roughness: .22, envMapIntensity: 1.2 }), 2); }),
  mosaicWarm: () => memo('m.mosw', () => { const t = mosaic(['#c98a4a', '#e2b070', '#f3e2c4', '#a9642e', '#e9c48c'], '#f1e6d4'); return tile(std({ map: t.map, normalMap: t.normal, roughness: .3 }), 2); }),
  bigTiles: () => memo('m.bt', () => tile(std({ map: bigTiles(), roughness: .2, envMapIntensity: 1.1 }), 4)),
  wall2: (paint = '#4c8a6a') => memo('m.w2' + paint, () => tile(std({ map: wall2(paint), roughness: .7 }), [1.2, 3.6])),
  lino: () => memo('m.lino', () => tile(std({ map: lino(), roughness: .55 }), 2)),
  ribs: (c = '#6b6258') => memo('m.ribs' + c, () => tile(std({ map: ribs(c), roughness: .5, metalness: .5 }), 2)),
  glass: () => memo('m.glass', () => tile(std({ map: glassWall(), roughness: .08, metalness: .85, envMapIntensity: 1.6 }), 8)),
  facade: (i = 0) => memo('m.fac' + i, () => { const t = facade(100 + i * 7, PALS[i % PALS.length]); return tile(std({ map: t.map, emissiveMap: t.emi, emissive: 0xffffff, emissiveIntensity: 1.7, roughness: .86 }), [20.4, 18]); }),
  tram: () => memo('m.tram', () => std({ map: tramTex(), roughness: .35, metalness: .3 })),
  leaves: (hex = 0x3f7a2c) => memo('m.leaf' + hex, () => std({ color: hex, roughness: .95, flatShading: true })),
  bark: () => C(0x5a4030, .95),
  metal: () => C(0x8a8f96, .4, .8), metalDark: () => C(0x33363b, .5, .7), white: () => C(0xf2f2ee, .6), black: () => C(0x16171a, .7),
  ceil: (hex = 0xe4e0d4) => memo('m.ceil' + hex, () => { const m = std({ color: hex, roughness: .95 }); m.userData.noCast = true; return m; }),
  gold: () => C(0xffc530, .25, 1), stone: () => C(0x8c8a84, .95), rubber: () => C(0x1a1a1c, .9),
  water: () => memo('m.water', () => { const n = normalMap(gray(cv(256), (x, y) => (nz(x * 2, y * 2) * .6 + nz(x * 5 + 30, y * 5) * .4) * 255), 2.2); n.repeat.set(1, 1); const m = std({ color: 0x1c6f8f, roughness: .06, metalness: .6, normalMap: n, transparent: true, opacity: .86, envMapIntensity: 1.5 }); m.userData.tile = 14; m.userData.water = n; return m; }),
};
