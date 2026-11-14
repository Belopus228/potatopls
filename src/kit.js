// Конструктор окружения: стены, двери, фонари, деревья, дома, машины, трава, рельеф, вода
import * as THREE from 'three';
import { G, rand, rng, PI, TAU, clamp, damp, wait } from './g.js';
import { M, C, glowMat, memo, cv, tex, px, nz } from './tex.js';
import { GEO } from './level.js';
import { windify } from './gfx.js';

export const at = (x, z, rot, lx, lz) => [x + lx * Math.cos(rot) + lz * Math.sin(rot), z - lx * Math.sin(rot) + lz * Math.cos(rot)];
// стена вдоль оси X или Z с проёмами. gaps: [[центр от начала, ширина, высота=2.35], ...]
export function wall(L, mat, ax, az, bx, bz, y, h, th = .3, gaps = [], o = {}) {
  const hz = Math.abs(bx - ax) > Math.abs(bz - az); if (hz ? bx < ax : bz < az) { [ax, bx] = [bx, ax];[az, bz] = [bz, az]; gaps = gaps.map(g => [(hz ? bx - ax : bz - az) - g[0], g[1], g[2]]); }
  const len = hz ? bx - ax : bz - az, put = (s0, s1, y0, y1) => { if (s1 - s0 < .02 || y1 - y0 < .02) return; const m = (s0 + s1) / 2; hz ? L.box(mat, ax + m, (y0 + y1) / 2, az, s1 - s0, y1 - y0, th, o) : L.box(mat, ax, (y0 + y1) / 2, az + m, th, y1 - y0, s1 - s0, o); };
  let cur = 0; for (const g of gaps.slice().sort((a, b) => a[0] - b[0])) { const gh = g[2] ?? 2.35; put(cur, g[0] - g[1] / 2, y, y + h); put(g[0] - g[1] / 2, g[0] + g[1] / 2, y + gh, y + h); cur = g[0] + g[1] / 2; } put(cur, len, y, y + h);
}
// дверь: створка + коллайдер. o: w,h,mat,label,locked() -> текст или '', onOpen
export function door(L, x, y, z, rot = 0, o = {}) {
  const w = o.w || 1.5, h = o.h || 2.35, g = new THREE.Group(); g.position.set(x - Math.cos(rot) * w / 2, y, z + Math.sin(rot) * w / 2); g.rotation.y = rot; L.group.add(g);
  const leaf = new THREE.Mesh(new THREE.BoxGeometry(w, h, .09), o.mat || C(0x6a4a30, .6)); leaf.position.set(w / 2, h / 2, 0); leaf.castShadow = true; g.add(leaf);
  const kn = new THREE.Mesh(GEO.sph(), M.gold()); kn.scale.setScalar(.06); kn.position.set(w - .18, h * .45, .08); g.add(kn);
  const col = L.world.mover(x, y + h / 2, z, w, h, .3, rot), d = { open: false, col, g, a: 0 };
  d.setOpen = (v, quiet) => { if (d.open === v) return; d.open = v; col.off = v; if (!quiet) G.audio.sfx('door'); };
  L.onUpdate(dt => { d.a = damp(d.a, d.open ? 1 : 0, 7, dt); g.rotation.y = rot + d.a * 1.75 * (o.dir || 1); });
  if (o.label !== false) d.it = L.interact(x, y + 1, z, 2.3, o.label || 'Открыть', () => { const msg = o.locked && o.locked(); if (msg) { G.audio.sfx('deny'); if (typeof msg === 'string') G.ui.toast(msg, 'hint'); return; } d.setOpen(true); if (o.onOpen) o.onOpen(d); }, { cond: () => !d.open });
  return d;
}
export function ceilLamp(L, x, y, z, color = 0xfff0d0, int = 22, dist = 12, o) { L.box(glowMat(color, 2.4), x, y - .04, z, o && o.rz ? .26 : 1.1, .06, o && o.rz ? 1.1 : .26, { solid: false }); return L.lamp(x, y - .6, z, color, int * .6, dist, o); }
export function lampPost(L, x, z, y = 0, color = 0xffc98a, h = 6.2, rot = 0) {
  L.cyl(M.metalDark(), x, y + h / 2, z, .1, h, { solid: true, seg: 6 }); const [ax, az] = at(x, z, rot, .65, 0); L.box(M.metalDark(), (x + ax) / 2, y + h, (z + az) / 2, 1.4, .09, .09, { rot, solid: false }); const day = L.def.env && L.def.env.day; L.box(day ? C(0xf2f2ee, .3) : glowMat(color, 3), ax, y + h - .09, az, .5, .09, .24, { rot, solid: false });
  if (day) return null; L.glow(ax, y + h - .2, az, 3.2, color, .45); return L.lamp(ax, y + h - 1, az, color, 70, 24);
}
export function tree(L, x, z, s = 1, kind = 'oak', y) {
  y = y ?? L.world.height(x, z); const r = L.r;
  if (kind === 'pine' || kind === 'snowpine') { L.cyl(M.bark(), x, y + 1.2 * s, z, .2 * s, 2.4 * s, { solid: true, seg: 6, r2: .6 }); for (let i = 0; i < 4; i++) { const k = 1 - i * .2; L.cone(M.leaves(kind === 'pine' ? 0x24552e : 0x2c5a40), x, y + (2.1 + i * 1.25) * s, z, 1.75 * s * k, 2.3 * s * k, { seg: 7 }); if (kind === 'snowpine') L.cone(C(0xf2f6fa, .9), x, y + (2.55 + i * 1.25) * s, z, 1.3 * s * k, 1.5 * s * k, { seg: 7 }); } }
  else if (kind === 'cypress') { L.cyl(M.bark(), x, y + .6 * s, z, .16 * s, 1.2 * s, { solid: true, seg: 6 }); L.sph(M.leaves(0x1f4a2a), x, y + 3.4 * s, z, 1, { ico: 1, s: [.85 * s, 3 * s, .85 * s] }); }
  else if (kind === 'bare') { L.cyl(M.bark(), x, y + 2 * s, z, .2 * s, 4 * s, { solid: true, seg: 6, r2: .4 }); for (let i = 0; i < 5; i++) { const a = r() * TAU, hh = (2 + r() * 2) * s; L.add(M.bark(), GEO.cyl(5, .3), x + Math.sin(a) * .7 * s, y + hh + .6 * s, z + Math.cos(a) * .7 * s, { s: [.07 * s, 1.9 * s, .07 * s], rz: -Math.cos(a) * .9, rx: Math.sin(a) * .9 }); } }
  else { const birch = kind === 'birch'; L.cyl(birch ? C(0xe8e6de, .8) : M.bark(), x, y + 1.6 * s, z, (birch ? .15 : .26) * s, 3.2 * s, { solid: true, seg: 7, r2: .65 }); const col = birch ? 0x6fa83a : kind === 'autumn' ? 0xc9862a : 0x3f7a2c; for (let i = 0; i < 5; i++) { const a = r() * TAU, d = i ? (.7 + r() * .7) * s : 0; L.sph(M.leaves(i % 2 ? col : (col & 0xfefefe) - 0x101808), x + Math.sin(a) * d, y + (3.3 + r() * 1.4) * s + (i ? 0 : .9 * s), z + Math.cos(a) * d, (1.25 + r() * .6) * s, { ico: 1, ry: r() * 6 }); } }
}
export function bush(L, x, z, s = 1, col = 0x356a2a, y) { y = y ?? L.world.height(x, z); for (let i = 0; i < 3; i++) L.sph(M.leaves(col), x + (L.r() - .5) * s, y + .45 * s, z + (L.r() - .5) * s, (.55 + L.r() * .3) * s, { ico: 1, ry: L.r() * 6 }); }
export function bench(L, x, z, rot = 0, y = 0) { L.box(M.planks(), x, y + .45, z, 1.8, .08, .5, { rot }); const [bx, bz] = at(x, z, rot, 0, -.24); L.box(M.planks(), bx, y + .8, bz, 1.8, .4, .07, { rot, solid: false }); for (const s of [-1, 1]) { const [lx, lz] = at(x, z, rot, s * .75, 0); L.box(M.metalDark(), lx, y + .22, lz, .08, .44, .5, { rot, solid: false }); } }
export function bin(L, x, z, y = 0) { L.cyl(0x3a5a44, x, y + .45, z, .28, .9, { solid: true, seg: 8, r2: 1.15 }); }
export function car(L, x, z, rot = 0, color = 0xb02a2a, y = 0) {
  L.box(color, x, y + .62, z, 1.8, .62, 4.2, { rot, gloss: 1 }); const [cx, cz] = at(x, z, rot, 0, -.2); L.box(0x1a2530, cx, y + 1.17, cz, 1.6, .52, 2.1, { rot, gloss: 1, solid: false }); L.box(color, cx, y + 1.45, cz, 1.62, .06, 2.0, { rot, gloss: 1, solid: false });
  for (const sx of [-1, 1]) for (const sz of [-1, 1]) { const [wx, wz] = at(x, z, rot, sx * .88, sz * 1.35); L.add(M.rubber(), GEO.cyl(10), wx, y + .33, wz, { s: [.33, .24, .33], rz: PI / 2, ry: rot }); }
  for (const sx of [-1, 1]) { const [hx, hz] = at(x, z, rot, sx * .6, 2.11), [tx, tz] = at(x, z, rot, sx * .6, -2.11); L.box(glowMat(0xfff2c0, 1.5), hx, y + .68, hz, .34, .16, .04, { rot, solid: false }); L.box(glowMat(0xff2010, 1.2), tx, y + .7, tz, .34, .14, .04, { rot, solid: false }); }
}
export function fence(L, ax, az, bx, bz, h = 1.1, mat, y = 0, step = 2) { const len = Math.hypot(bx - ax, bz - az), rot = Math.atan2(-(bz - az), bx - ax), n = Math.max(1, Math.round(len / step)); mat = mat || M.planksDark(); L.box(mat, (ax + bx) / 2, y + h * .55, (az + bz) / 2, len, h * .8, .07, { rot, col: { nocam: true } }); for (let i = 0; i <= n; i++) L.box(mat, ax + (bx - ax) * i / n, y + h / 2, az + (bz - az) * i / n, .12, h, .12, { rot, solid: false }); }
// панельная многоэтажка. o: rot, solid, door ('s'), sign
export function block(L, x, z, w, d, floors, fi = 0, o = {}) {
  const h = floors * 3, y = o.y || 0, rot = o.rot || 0; L.box(M.facade(fi), x, y + h / 2, z, w, h, d, { rot, solid: o.solid !== false }); L.box(M.concDark(), x, y + h + .35, z, w + .5, .7, d + .5, { rot, solid: false });
  if (o.far) return; L.box(M.concDark(), x, y + .5, z, w + .12, 1, d + .12, { rot, solid: false });
  for (let i = 0; i < (o.doors || 0); i++) { const lx = (i - (o.doors - 1) / 2) * 13.6, [dx, dz] = at(x, z, rot, lx, d / 2 + .05), [cx, cz] = at(x, z, rot, lx, d / 2 + 1.1); L.box(M.metalDark(), dx, y + 1.15, dz, 1.5, 2.3, .1, { rot, solid: false }); L.box(M.concrete(), cx, y + 2.65, cz, 3, .2, 2.2, { rot, solid: false }); L.box(glowMat(0xfff0c0, 2), cx, y + 2.52, cz, .5, .06, .5, { rot, solid: false }); L.lamp(cx, y + 2.2, cz, 0xfff0c0, 14, 9); for (const s of [-1, 1]) { const [px, pz] = at(x, z, rot, lx + s * 1.4, d / 2 + 2.05); L.cyl(M.metalDark(), px, y + 1.3, pz, .06, 2.6, { solid: true, seg: 6 }); } }
}
// деревенский дом. o: rot, mat, roof, h
export function house(L, x, z, w, d, o = {}) {
  const rot = o.rot || 0, h = o.h || 3, y = o.y ?? L.world.height(x, z), mat = o.mat || M.logs(), roof = o.roof ?? 0x8a3a2a; L.box(M.stone(), x, y + .15, z, w + .2, .9, d + .2, { rot, solid: false }); L.box(mat, x, y + h / 2 + .3, z, w, h, d, { rot });
  L.add(roof, GEO.prism(), x, y + h + .3, z, { s: [w + .9, w * .42, d + .9], ry: rot, color: roof }); const [hx, hz] = at(x, z, rot, w * .25, d * .2); L.box(M.brick(), hx, y + h + w * .3, hz, .6, 1.6, .6, { rot, solid: false });
  const [dx, dz] = at(x, z, rot, 0, d / 2 + .04); L.box(o.door ?? 0x5a3a22, dx, y + 1.3, dz, 1.1, 2, .08, { rot, solid: false }); const [sx, sz] = at(x, z, rot, 0, d / 2 + .7); L.box(M.planks(), sx, y + .15, sz, 1.8, .3, 1.2, { rot });
  for (const s of [-1, 1]) { const [wx, wz] = at(x, z, rot, s * w * .3, d / 2 + .04); L.box(o.lit ? glowMat(0xffd98a, 1.6) : C(0x7fa6c8, .1, .6), wx, y + 1.75, wz, 1, 1, .06, { rot, solid: false }); L.box(0xf2f2ee, wx, y + 1.75, wz, 1.16, 1.16, .03, { rot, solid: false }); for (const sd of [-1, 1]) { const [qx, qz] = at(x, z, rot, sd * (w / 2 + .04), s * d * .22); L.box(o.lit ? glowMat(0xffd98a, 1.6) : C(0x7fa6c8, .1, .6), qx, y + 1.75, qz, .06, 1, 1, { rot, solid: false }); } }
}
export function garage(L, x, z, rot = 0, col = 0x6b6258) { L.box(M.ribs('#' + col.toString(16).padStart(6, '0')), x, 1.25, z, 3.2, 2.5, 5.6, { rot }); L.box(M.metalDark(), x, 2.56, z, 3.4, .12, 5.8, { rot, solid: false }); }
export function kiosk(L, x, z, rot, name, col = 0xd22f2f, glow = 0xffd23a) {
  L.box(col, x, 1.5, z, 4, 3, 2.6, { rot, gloss: 1 }); const [fx, fz] = at(x, z, rot, 0, 1.32); L.box(glowMat(0xfff2d0, 1.4), fx, 1.75, fz, 2.6, 1.1, .05, { rot, solid: false }); const [cx, cz] = at(x, z, rot, 0, 1.75); L.box(0xf2f2ee, cx, 1.1, cz, 2.9, .1, .7, { rot, solid: false }); L.box(col, cx, 3.05, cz, 4.3, .12, 3.6, { rot, solid: false });
  const [sx, sz] = at(x, z, rot, 0, 1.4); L.sign(name, sx, 3.55, sz, 3.8, .8, rot, { bg: '#1a0d0d', fg: '#' + glow.toString(16).padStart(6, '0'), glow: 1.8, border: '#' + glow.toString(16).padStart(6, '0') }); L.lamp(cx, 2.4, cz, 0xffe2a8, 30, 12);
}
// трава: инстансы пучков. place(i) -> [x,y,z] или null
export function grass(L, n, place, o = {}) {
  n = Math.round(n * G.gfx.Q.grass); if (n < 1) return; const geo = memo('grassgeo', () => {
    const p = [], c = [], nn = []; for (let k = 0; k < 3; k++) { const a = k * 2.1, cs = Math.cos(a), sn = Math.sin(a), ox = cs * .09, oz = sn * .09, w = .07, lean = .12; p.push(ox - sn * w, 0, oz + cs * w, ox + sn * w, 0, oz - cs * w, ox + cs * lean, .55 + k * .12, oz + sn * lean); c.push(.45, .6, .32, .45, .6, .32, 1, 1.15, .7); nn.push(0, 1, 0, 0, 1, 0, 0, 1, 0); }
    const g = new THREE.BufferGeometry(); g.setAttribute('position', new THREE.Float32BufferAttribute(p, 3)); g.setAttribute('color', new THREE.Float32BufferAttribute(c, 3)); g.setAttribute('normal', new THREE.Float32BufferAttribute(nn, 3)); return g;
  });
  const mat = memo('grassmat' + (o.color || 0), () => windify(new THREE.MeshStandardMaterial({ color: o.color || 0x6fae3e, vertexColors: true, side: THREE.DoubleSide, roughness: 1 }), .28, 2.1));
  const im = new THREE.InstancedMesh(geo, mat, n), m = new THREE.Matrix4(), q = new THREE.Quaternion(), s = new THREE.Vector3(), v = new THREE.Vector3(), e = new THREE.Euler(), col = new THREE.Color(); let k = 0;
  for (let i = 0; i < n; i++) { const p = place(i); if (!p) continue; e.set(0, L.r() * TAU, 0); q.setFromEuler(e); const sc = (.7 + L.r() * .9) * (o.s || 1); s.set(sc, sc * (.7 + L.r() * .7), sc); m.compose(v.set(p[0], p[1], p[2]), q, s); im.setMatrixAt(k, m); col.setHSL(.24 + L.r() * .08, .5 + L.r() * .2, .42 + L.r() * .2); im.setColorAt(k++, col); }
  im.count = k; im.receiveShadow = true; im.frustumCulled = false; im.userData.keepGeo = true; L.group.add(im); L.trash.push({ dispose: () => im.dispose() }); return im;
}
const detail = () => memo('t.detail', () => { const c = cv(256); px(c, (x, y, d, i) => { const v = 190 + (nz(x * 3, y * 3) - .5) * 80 + (nz(x * 11 + 9, y * 11) - .5) * 60; d[i] = d[i + 1] = d[i + 2] = v; d[i + 3] = 255; }); return tex(c); });
// рельеф: сетка size x size, seg делений; hfn(x,z) -> высота; colfn(x,z,h,ny) -> hex
export function terrain(L, size, seg, hfn, colfn, o = {}) {
  const n = seg + 1, H = new Float32Array(n * n), st = size / seg, half = size / 2, cx = o.cx || 0, cz = o.cz || 0;
  for (let j = 0; j < n; j++) for (let i = 0; i < n; i++) H[j * n + i] = hfn(cx - half + i * st, cz - half + j * st);
  const hf = (x, z) => { if (Math.abs(x - cx) > half + 2 || Math.abs(z - cz) > half + 2) return o.out ?? -200; const fx = clamp((x - cx + half) / st, 0, seg - .001), fz = clamp((z - cz + half) / st, 0, seg - .001), i = fx | 0, j = fz | 0, tx = fx - i, tz = fz - j, a = H[j * n + i], b = H[j * n + i + 1], c = H[(j + 1) * n + i], d = H[(j + 1) * n + i + 1]; return tx + tz < 1 ? a + (b - a) * tx + (c - a) * tz : d + (c - d) * (1 - tx) + (b - d) * (1 - tz); };
  const g = new THREE.BufferGeometry(), P = new Float32Array(n * n * 3), U = new Float32Array(n * n * 2), Cc = new Float32Array(n * n * 3), I = [], col = new THREE.Color();
  for (let j = 0; j < n; j++) for (let i = 0; i < n; i++) { const k = j * n + i, x = cx - half + i * st, z = cz - half + j * st; P[k * 3] = x; P[k * 3 + 1] = H[k]; P[k * 3 + 2] = z; U[k * 2] = x / (o.tile || 5); U[k * 2 + 1] = z / (o.tile || 5); }
  for (let j = 0; j < seg; j++) for (let i = 0; i < seg; i++) { const a = j * n + i; I.push(a, a + n, a + 1, a + 1, a + n, a + n + 1); }
  g.setAttribute('position', new THREE.BufferAttribute(P, 3)); g.setAttribute('uv', new THREE.BufferAttribute(U, 2)); g.setIndex(I); g.computeVertexNormals(); const Nn = g.attributes.normal;
  for (let k = 0; k < n * n; k++) { col.set(colfn(P[k * 3], P[k * 3 + 2], H[k], Nn.getY(k))); const v = .9 + ((k * 7919) % 97) / 97 * .2; Cc[k * 3] = col.r * v; Cc[k * 3 + 1] = col.g * v; Cc[k * 3 + 2] = col.b * v; }
  g.setAttribute('color', new THREE.BufferAttribute(Cc, 3));
  const m = new THREE.Mesh(g, memo('m.terrain', () => new THREE.MeshStandardMaterial({ map: detail(), vertexColors: true, roughness: 1 }))); m.receiveShadow = true; L.group.add(m); L.world.hf = hf; return hf;
}
export function water(L, y, size = 600, x = 0, z = 0, mat) { const m = mat || M.water(), w = L.mesh(GEO.plane(), m, x, y, z, { rx: -PI / 2, s: [size, size, 1], recv: true }); const n = m.userData.water; if (n) { n.repeat.set(size / 14, size / 14); L.onUpdate((dt, t) => { n.offset.set(t * .012, t * .02); }); } return w; }
// паутина-декаль
export function web(L, x, y, z, s, ry = 0, rx = 0) { return L.sign('', x, y, z, s, s, ry, { tex: memo('webt', () => { const c = cv(256), g = c.getContext('2d'); g.strokeStyle = 'rgba(255,255,255,.8)'; g.lineWidth = 1.5; g.translate(128, 128); for (let i = 0; i < 14; i++) { const a = i / 14 * TAU; g.beginPath(); g.moveTo(0, 0); g.lineTo(Math.cos(a) * 126, Math.sin(a) * 126); g.stroke(); } g.lineWidth = 1; for (let k = 1; k < 9; k++) { g.beginPath(); for (let i = 0; i <= 14; i++) { const a = i / 14 * TAU, rr = k * 14, a0 = a - TAU / 28; i ? g.quadraticCurveTo(Math.cos(a0) * rr * .86, Math.sin(a0) * rr * .86, Math.cos(a) * rr, Math.sin(a) * rr) : g.moveTo(rr, 0); } g.stroke(); } return tex(c, { rep: false }); }), bg: 'none', dbl: true, rx }); }
// невидимая стена
export const barrier = (L, x, z, sx, sz, rot = 0, h = 30) => L.world.box(x, h / 2 - 2, z, sx, h, sz, rot, { nocam: true });
// ящики россыпью: list [[x,z,(y),(o)]]
export function crates(L, list, Crate) { for (const c of list) { const fid = `${L.id}.cr.${c[0]}.${c[1]}`; if (G.game.flag(fid)) continue; G.game.spawn(new Crate(c[0], c[2] || 0, c[1], { fid, ...(c[3] || {}) })); } }
