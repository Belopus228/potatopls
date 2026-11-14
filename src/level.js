// Уровень: батчинг статической геометрии + коллайдеры + триггеры/интерактив
import * as THREE from 'three';
import { G, rng, clamp } from './g.js';
import { World } from './world.js';
import { M, memo, signTex, glowTex } from './tex.js';

const UB = new THREE.BoxGeometry(1, 1, 1), _m = new THREE.Matrix4(), _n = new THREE.Matrix3(), _v = new THREE.Vector3(), _q = new THREE.Quaternion(), _e = new THREE.Euler(0, 0, 0, 'YXZ'), _s = new THREE.Vector3(), _c = new THREE.Color();
const geoCache = {};
const GEO = {
  cyl: (seg = 10, r2 = 1) => geoCache['c' + seg + '_' + r2] || (geoCache['c' + seg + '_' + r2] = new THREE.CylinderGeometry(r2, 1, 1, seg)),
  sph: (w = 12, h = 8) => geoCache['s' + w + '_' + h] || (geoCache['s' + w + '_' + h] = new THREE.SphereGeometry(1, w, h)),
  ico: (d = 0) => geoCache['i' + d] || (geoCache['i' + d] = new THREE.IcosahedronGeometry(1, d)),
  cone: (seg = 8) => geoCache['k' + seg] || (geoCache['k' + seg] = new THREE.ConeGeometry(1, 1, seg)),
  plane: () => geoCache.pl || (geoCache.pl = new THREE.PlaneGeometry(1, 1)),
  tor: (t = .1) => geoCache['t' + t] || (geoCache['t' + t] = new THREE.TorusGeometry(1, t, 6, 16)),
  // призма (двускатная крыша): основание 1x1, конёк вдоль Z на высоте 1
  prism: () => geoCache.pr || (geoCache.pr = (() => {
    const g = new THREE.BufferGeometry(), h = Math.SQRT1_2 * 0 + 1, nx = 1 / Math.hypot(1, .5), ny = .5 / Math.hypot(1, .5);
    const p = [-.5, 0, .5, 0, 1, .5, 0, 1, -.5, -.5, 0, -.5, /**/ .5, 0, -.5, 0, 1, -.5, 0, 1, .5, .5, 0, .5, /**/ -.5, 0, .5, .5, 0, .5, 0, 1, .5, /**/ .5, 0, -.5, -.5, 0, -.5, 0, 1, -.5];
    const n = [-nx, ny, 0, -nx, ny, 0, -nx, ny, 0, -nx, ny, 0, nx, ny, 0, nx, ny, 0, nx, ny, 0, nx, ny, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, -1, 0, 0, -1, 0, 0, -1];
    const u = [0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 1, 0, .5, 1, 0, 0, 1, 0, .5, 1];
    g.setAttribute('position', new THREE.Float32BufferAttribute(p, 3)); g.setAttribute('normal', new THREE.Float32BufferAttribute(n, 3)); g.setAttribute('uv', new THREE.Float32BufferAttribute(u, 2));
    g.setIndex([0, 1, 2, 0, 2, 3, 4, 5, 6, 4, 6, 7, 8, 9, 10, 11, 12, 13]); return g;
  })()),
};
export { GEO };
export const VC = () => memo('m.vc', () => new THREE.MeshStandardMaterial({ vertexColors: true, roughness: .78 }));
export const VCG = () => memo('m.vcg', () => new THREE.MeshStandardMaterial({ vertexColors: true, roughness: .3, metalness: .25 }));

export class Level {
  constructor(def) {
    this.def = def; this.id = def.id; this.group = new THREE.Group(); this.world = new World(); this.batches = new Map();
    this.ups = []; this.inter = []; this.trig = []; this.lamps = []; this.r = rng(def.seed || 7); this.trash = []; this.t = 0;
  }
  rnd(a = 1, b) { return b === undefined ? this.r() * a : a + this.r() * (b - a); }
  _mat(mat, o) { if (typeof mat === 'number') { o.color = mat; return o.gloss ? VCG() : VC(); } return mat; }
  batch(mat) { let b = this.batches.get(mat); if (!b) { b = { p: [], n: [], u: [], c: [], i: [], mat, vc: !!mat.vertexColors }; this.batches.set(mat, b); } return b; }
  // коробка: центр, размеры. o: rot, solid(=true), uv:[tu,tv]|n, fit, uvOff, col:{nocam,nowalk,ghost}, color
  box(mat, x, y, z, sx, sy, sz, o = {}) {
    mat = this._mat(mat, o); const b = this.batch(mat), P = UB.attributes.position.array, Nn = UB.attributes.normal.array, U = UB.attributes.uv.array, I = UB.index.array;
    const rot = o.rot || 0, c = Math.cos(rot), s = Math.sin(rot), base = b.p.length / 3, t = o.uv ?? mat.userData.tile ?? 2, tu = t[0] || t, tv = t[1] || t, off = o.uvOff;
    if (b.vc) _c.set(o.color ?? 0xffffff);
    for (let i = 0; i < 24; i++) {
      const px = P[i * 3] * sx, py = P[i * 3 + 1] * sy, pz = P[i * 3 + 2] * sz, nx = Nn[i * 3], nz = Nn[i * 3 + 2], f = i >> 2;
      b.p.push(x + px * c + pz * s, y + py, z - px * s + pz * c); b.n.push(nx * c + nz * s, Nn[i * 3 + 1], -nx * s + nz * c);
      if (o.fit) b.u.push(U[i * 2], U[i * 2 + 1]); else b.u.push(U[i * 2] * (f < 2 ? sz : sx) / tu + (off ? off[0] : 0), U[i * 2 + 1] * (f === 2 || f === 3 ? sz : sy) / tv + (off ? off[1] : 0));
      if (b.vc) b.c.push(_c.r, _c.g, _c.b);
    }
    for (let i = 0; i < I.length; i++) b.i.push(base + I[i]);
    if (o.solid !== false) return this.world.box(x, y, z, sx, sy, sz, rot, o.col);
  }
  // произвольная геометрия в батч. o: ry, rx, rz, s (число или [x,y,z]), color, uvs (масштаб uv)
  add(mat, g, x, y, z, o = {}) {
    mat = this._mat(mat, o); const b = this.batch(mat), P = g.attributes.position, Nn = g.attributes.normal, U = g.attributes.uv, base = b.p.length / 3, sc = o.s ?? 1, us = o.uvs || 1;
    _e.set(o.rx || 0, o.ry || 0, o.rz || 0); _q.setFromEuler(_e); if (sc.length) _s.set(sc[0], sc[1], sc[2]); else _s.set(sc, sc, sc);
    _m.compose(_v.set(x, y, z), _q, _s); _n.getNormalMatrix(_m); if (b.vc) _c.set(o.color ?? 0xffffff);
    for (let i = 0; i < P.count; i++) {
      _v.fromBufferAttribute(P, i).applyMatrix4(_m); b.p.push(_v.x, _v.y, _v.z);
      _v.fromBufferAttribute(Nn, i).applyMatrix3(_n).normalize(); b.n.push(_v.x, _v.y, _v.z);
      b.u.push(U ? U.getX(i) * (us[0] || us) : 0, U ? U.getY(i) * (us[1] || us) : 0); if (b.vc) b.c.push(_c.r, _c.g, _c.b);
    }
    if (g.index) { const I = g.index.array; for (let i = 0; i < I.length; i++) b.i.push(base + I[i]); } else for (let i = 0; i < P.count; i++) b.i.push(base + i);
  }
  cyl(mat, x, y, z, r, h, o = {}) { this.add(mat, GEO.cyl(o.seg || 10, o.r2 ?? 1), x, y, z, { ...o, s: [r, h, r] }); if (o.solid) return this.world.cyl(x, z, r, y - h / 2, y + h / 2, o.col); }
  sph(mat, x, y, z, r, o = {}) { this.add(mat, o.ico !== undefined ? GEO.ico(o.ico) : GEO.sph(), x, y, z, { ...o, s: o.s || r }); }
  cone(mat, x, y, z, r, h, o = {}) { this.add(mat, GEO.cone(o.seg || 8), x, y, z, { ...o, s: [r, h, r] }); }
  // наклонная плита-пандус: подъём вдоль локальной +z
  ramp(mat, x, z, sx, sz, ya, yb, o = {}) {
    const rot = o.rot || 0, len = Math.hypot(sz, yb - ya), th = o.th || .2;
    this.add(mat, UB, x, (ya + yb) / 2 - th / 2, z, { ...o, ry: rot, rx: -Math.atan2(yb - ya, sz), s: [sx, th, len], uvs: [sx / 2, len / 2] });
    return this.world.ramp(x, z, sx, sz, ya, yb, rot, o.col);
  }
  // лестница: визуально ступени, коллайдер — пандус
  stairs(mat, x, z, w, depth, ya, yb, o = {}) {
    const rot = o.rot || 0, n = Math.max(2, Math.ceil(Math.abs(yb - ya) / .3)), c = Math.cos(rot), s = Math.sin(rot);
    for (let i = 0; i < n; i++) { const lz = -depth / 2 + (i + .5) * depth / n, top = ya + (yb - ya) * (i + .5) / n, y0 = Math.min(ya, yb) - .2; this.box(mat, x + lz * s, (top + y0) / 2, z + lz * c, w, top - y0, depth / n + .01, { rot, solid: false, ...o }); }
    return this.world.ramp(x, z, w, depth, ya, yb, rot, o.col);
  }
  finish() {
    for (const b of this.batches.values()) {
      if (!b.p.length) continue; const g = new THREE.BufferGeometry();
      g.setAttribute('position', new THREE.Float32BufferAttribute(b.p, 3)); g.setAttribute('normal', new THREE.Float32BufferAttribute(b.n, 3)); g.setAttribute('uv', new THREE.Float32BufferAttribute(b.u, 2));
      if (b.vc) g.setAttribute('color', new THREE.Float32BufferAttribute(b.c, 3)); g.setIndex(b.i);
      const m = new THREE.Mesh(g, b.mat); m.castShadow = !b.mat.userData.noCast; m.receiveShadow = true; this.group.add(m); this.trash.push(g);
    }
    this.batches.clear();
  }
  // ----- отдельные (не батч) объекты -----
  mesh(geo, mat, x = 0, y = 0, z = 0, o = {}) { const m = new THREE.Mesh(geo, mat); m.position.set(x, y, z); if (o.ry) m.rotation.y = o.ry; if (o.rx) m.rotation.x = o.rx; if (o.s) m.scale.setScalar ? (o.s.length ? m.scale.set(...o.s) : m.scale.setScalar(o.s)) : 0; m.castShadow = !!o.cast; m.receiveShadow = !!o.recv; (o.parent || this.group).add(m); return m; }
  // табличка / вывеска. o: glow, bg, fg, border, tex, w/h холста, dbl
  sign(text, x, y, z, w, h, ry = 0, o = {}) {
    const t = o.tex || signTex(text, { w: o.cw || 512, h: o.ch || Math.round((o.cw || 512) * h / w), ...o }); if (!o.tex) this.trash.push(t);
    const mat = new THREE.MeshStandardMaterial({ map: t, roughness: .6, transparent: o.bg === 'none' || !!o.alpha, side: o.dbl ? THREE.DoubleSide : THREE.FrontSide, ...(o.glow ? { emissiveMap: t, emissive: 0xffffff, emissiveIntensity: o.glow } : {}) });
    if (mat.transparent) { mat.depthWrite = false; mat.polygonOffset = true; mat.polygonOffsetFactor = -2; }
    this.trash.push(mat); const m = this.mesh(GEO.plane(), mat, x, y, z, { ry, rx: o.rx, s: [w, h, 1] }); if (o.rx) m.rotation.order = 'YXZ'; return m;
  }
  glow(x, y, z, size, color, op = .8) { const s = new THREE.Sprite(memo('sp' + color + op, () => new THREE.SpriteMaterial({ map: glowTex(), color, transparent: true, opacity: op, blending: THREE.AdditiveBlending, depthWrite: false, fog: true }))); s.position.set(x, y, z); s.scale.setScalar(size); this.group.add(s); return s; }
  lamp(x, y, z, color = 0xffd9a0, int = 40, dist = 18, o = {}) { const L = { x, y, z, color, int, dist, ...o }; this.lamps.push(L); return L; }
  // ----- геймплей -----
  interact(x, y, z, r, label, use, o = {}) { const it = { pos: new THREE.Vector3(x, y, z), r, label, use, ...o }; this.inter.push(it); return it; }
  trigger(x, z, r, fn, o = {}) { const t = { x, z, r, fn, once: o.once !== false, ...o }; this.trig.push(t); return t; }
  onUpdate(fn) { this.ups.push(fn); return fn; }
  update(dt) {
    this.t += dt; const p = G.player.pos;
    if (G.mode === 'play') for (let i = this.trig.length - 1; i >= 0; i--) {
      const t = this.trig[i]; if (t.off) continue;
      const inside = t.box ? (Math.abs(p.x - t.x) < t.box[0] && Math.abs(p.z - t.z) < t.box[1]) : ((p.x - t.x) ** 2 + (p.z - t.z) ** 2 < t.r * t.r);
      if (inside && (t.y0 === undefined || (p.y >= t.y0 && p.y <= t.y1))) { if (!t.in) { t.in = true; if (t.once) this.trig.splice(i, 1); t.fn(t); } } else { if (t.in && t.leave) t.leave(t); t.in = false; }
    }
    for (let i = 0; i < this.ups.length; i++) this.ups[i](dt, this.t);
  }
  dispose() {
    this.group.traverse(o => { if (o.geometry && !Object.values(geoCache).includes(o.geometry) && !o.userData.keepGeo) o.geometry.dispose(); });
    for (const t of this.trash) t.dispose && t.dispose(); this.group.removeFromParent();
  }
}
