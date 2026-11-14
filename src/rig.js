// Персонажи: процедурный скиннинг (1 draw call на тело), лицо-декаль с фото, процедурные анимации
import * as THREE from 'three';
import { G, damp, lerp, smooth, sat, PI, TAU } from './g.js';
import { featherTex, faceTex, memo, blobTex, fogFaceTex } from './tex.js';

const _m = new THREE.Matrix4(), _q = new THREE.Quaternion(), _e = new THREE.Euler(), _p = new THREE.Vector3(), _s = new THREE.Vector3(), _c = new THREE.Color(), _v = new THREE.Vector3(), _n3 = new THREE.Matrix3(), UP = new THREE.Vector3(0, 1, 0);
const gc = {};
const CAP = (r, h) => gc[`c${r}_${h}`] || (gc[`c${r}_${h}`] = new THREE.CapsuleGeometry(r, h, 4, 8));
const SPH = gc.s = new THREE.SphereGeometry(1, 14, 10), BOX = gc.b = new THREE.BoxGeometry(1, 1, 1), CYL = gc.cy = new THREE.CylinderGeometry(1, 1, 1, 12), CONE = gc.co = new THREE.ConeGeometry(1, 1, 12), TOR = gc.t = new THREE.TorusGeometry(1, .09, 6, 18);
const HCAP = (a = .5) => gc['h' + a] || (gc['h' + a] = new THREE.SphereGeometry(1, 16, 8, 0, TAU, 0, PI * a));
// геометрия лица: фронтальная «заплатка» сферы с плоской проекцией UV
const FACE_GEO = (() => { const g = new THREE.SphereGeometry(1, 24, 16, PI / 2 - 1.25, 2.5, PI * .2, PI * .66), P = g.attributes.position, U = g.attributes.uv; for (let i = 0; i < P.count; i++) U.setXY(i, .5 + P.getX(i) / 1.72, (P.getY(i) + .98) / 1.6); return g; })();
const faceMat = t => memo('fm' + t.uuid, () => new THREE.MeshStandardMaterial({ map: t, alphaMap: featherTex(), transparent: true, roughness: .7, depthWrite: false, polygonOffset: true, polygonOffsetFactor: -1, polygonOffsetUnits: -1 }));

// part: {g, p:[x,y,z], r:[rx,ry,rz] | q, s, c:hex, b:boneIndex}
function skinned(parts, defs, matOpts) {
  const pos = [], nor = [], col = [], si = [], sw = [], idx = [];
  for (const pt of parts) {
    const g = pt.g, P = g.attributes.position, Nn = g.attributes.normal, base = pos.length / 3, s = pt.s ?? 1;
    if (pt.q) _q.copy(pt.q); else { _e.set(...(pt.r || [0, 0, 0])); _q.setFromEuler(_e); }
    s.length ? _s.set(...s) : _s.setScalar(s); _m.compose(_p.set(...pt.p), _q, _s); _n3.getNormalMatrix(_m); _c.set(pt.c);
    for (let i = 0; i < P.count; i++) {
      _v.fromBufferAttribute(P, i).applyMatrix4(_m); pos.push(_v.x, _v.y, _v.z); _v.fromBufferAttribute(Nn, i).applyMatrix3(_n3).normalize(); nor.push(_v.x, _v.y, _v.z);
      col.push(_c.r, _c.g, _c.b); si.push(pt.b, 0, 0, 0); sw.push(1, 0, 0, 0);
    }
    if (g.index) { const I = g.index.array; for (let i = 0; i < I.length; i++) idx.push(base + I[i]); } else for (let i = 0; i < P.count; i++) idx.push(base + i);
  }
  const geo = new THREE.BufferGeometry();
  geo.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3)); geo.setAttribute('normal', new THREE.Float32BufferAttribute(nor, 3)); geo.setAttribute('color', new THREE.Float32BufferAttribute(col, 3));
  geo.setAttribute('skinIndex', new THREE.Uint16BufferAttribute(si, 4)); geo.setAttribute('skinWeight', new THREE.Float32BufferAttribute(sw, 4)); geo.setIndex(idx);
  const bones = defs.map(d => { const b = new THREE.Bone(); b.name = d.n; return b; });
  defs.forEach((d, i) => { const b = bones[i]; if (d.par >= 0) { const pp = defs[d.par].p; b.position.set(d.p[0] - pp[0], d.p[1] - pp[1], d.p[2] - pp[2]); bones[d.par].add(b); } else b.position.set(...d.p); });
  const mat = new THREE.MeshStandardMaterial({ vertexColors: true, roughness: .72, ...matOpts });
  const mesh = new THREE.SkinnedMesh(geo, mat); mesh.add(bones[0]); mesh.updateMatrixWorld(true); mesh.bind(new THREE.Skeleton(bones));
  mesh.frustumCulled = false; mesh.castShadow = true; const b = {}; bones.forEach(x => b[x.name] = x);
  return { mesh, b, mat, geo };
}
const seg = (a, b, rad, c, bone) => { const d = _v.set(b[0] - a[0], b[1] - a[1], b[2] - a[2]), len = d.length(); return { g: CAP(rad, Math.max(.01, +(len - rad * 2).toFixed(2))), p: [(a[0] + b[0]) / 2, (a[1] + b[1]) / 2, (a[2] + b[2]) / 2], q: new THREE.Quaternion().setFromUnitVectors(UP, d.normalize()), c, b: bone }; };
function blobShadow(r) { const m = new THREE.Mesh(gc.pl || (gc.pl = new THREE.PlaneGeometry(1, 1)), memo('blobm', () => new THREE.MeshBasicMaterial({ map: blobTex(), transparent: true, depthWrite: false, opacity: .8 }))); m.rotation.x = -PI / 2; m.position.y = .03; m.scale.setScalar(r * 2.6); m.renderOrder = 1; return m; }

// ---------- позы ----------
const REST = { hx: 0, hy: 0, hz: 0, hY: 0, sx: 0, sy: 0, sz: 0, nx: 0, ny: 0, alx: 0, alz: .1, fl: -.15, arx: 0, arz: -.1, fr: -.15, llx: 0, llz: .03, kl: 0, lrx: 0, lrz: -.03, kr: 0 };
const S = Math.sin, Co = Math.cos, ext = (t, a = .15, b = .4, c = .55, d = 1) => smooth(a, b, t) * (1 - smooth(c, d, t));
const guard = t => { t.alx = -1.05; t.fl = -1.75; t.arx = -1.05; t.fr = -1.75; t.alz = .25; t.arz = -.25; t.sx = .12; t.hY = -.06; t.llx = -.3; t.kl = .3; t.lrx = .28; t.kr = .4; };
export const POSE = {
  idle(r, t, τ) { const b = S(τ * 1.7); t.sx = .02 * b; t.hY = -.006 * (1 + b); t.alx = .03 * b; t.arx = .03 * b; t.nx = .02 * S(τ * .9 + 1); t.ny = .1 * S(τ * .45); },
  run(r, t, τ, sp) {
    const k = sat((sp / r.scale - 1.5) / 5), φ = r.phase, s = S(φ), c = Co(φ), A = lerp(.5, .95, k), Bm = lerp(.4, .95, k);
    t.llx = -A * s; t.lrx = A * s; t.kl = lerp(.9, 1.6, k) * Math.max(0, c) + .1; t.kr = lerp(.9, 1.6, k) * Math.max(0, -c) + .1;
    t.alx = Bm * s; t.arx = -Bm * s; t.fl = t.fr = -(.35 + .9 * k); t.sx = .05 + .17 * k; t.sy = -.14 * s; t.hy = .1 * s; t.hY = -.02 - .035 * k + .03 * Co(2 * φ); t.nx = -(.03 + .08 * k);
  },
  jump(r, t) { t.llx = -.7; t.kl = 1.2; t.lrx = .2; t.kr = .6; t.alx = -.5; t.arx = -.5; t.alz = .6; t.arz = -.6; t.fl = -.6; t.fr = -.6; t.sx = .1; },
  fall(r, t, τ) { t.llx = -.25; t.kl = .4; t.lrx = .15; t.kr = .3; t.alz = 1.1 + .1 * S(τ * 20); t.arz = -1.1 - .1 * S(τ * 20); t.alx = -.2; t.arx = -.2; t.sx = .05; },
  punchR(r, t, u) { guard(t); const e = ext(u); t.arx = lerp(-.9, -1.55, e); t.fr = lerp(-1.9, -.05, e); t.arz = -.05; t.sy = lerp(-.2, .6, e); t.hy = .25 * e; t.sx = .12 + .1 * e; },
  punchL(r, t, u) { guard(t); const e = ext(u); t.alx = lerp(-.9, -1.55, e); t.fl = lerp(-1.9, -.05, e); t.alz = .05; t.sy = lerp(.2, -.6, e); t.hy = -.25 * e; t.sx = .12 + .1 * e; },
  kick(r, t, u) { guard(t); const e = ext(u, .1, .42, .6, 1); t.lrx = lerp(.3, -1.55, e); t.kr = lerp(1.3, .05, e); t.sx = -.3 * e; t.llx = .1; t.kl = .2; t.hY = -.03; },
  throw(r, t, u) { const e = smooth(.3, .6, u), bk = 1 - smooth(.75, 1, u); t.arx = lerp(-2.9, -1, e) * bk; t.fr = lerp(-1.5, -.1, e); t.sy = lerp(-.5, .55, e) * bk; t.alx = .35; t.sx = .1 * e; t.llx = -.3; t.lrx = .25; t.kl = .2; t.kr = .3; },
  spray(r, t, τ) { t.arx = -1.5 + .05 * S(τ * 30); t.fr = -.05; t.arz = -.05; t.sy = .25; t.alx = -.3; t.fl = -.8; t.llx = -.25; t.lrx = .2; t.kl = .2; t.kr = .25; },
  roll(r, t, u) { t.sx = 1.1; t.llx = -1.7; t.kl = 2.1; t.lrx = -1.7; t.kr = 2.1; t.alx = -1.3; t.arx = -1.3; t.fl = -1.8; t.fr = -1.8; t.nx = .5; t.hY = -.5; r.spin = TAU * smooth(0, 1, u); },
  hit(r, t) { t.sx = -.4; t.nx = -.35; t.alz = .8; t.arz = -.8; t.alx = -.3; t.arx = -.3; t.hY = -.05; t.kl = .3; t.kr = .3; },
  dead(r, t) { t.hx = -1.5; t.hY = -.8; t.alz = 1.25; t.arz = -1.25; t.llx = -.12; t.lrx = .18; t.llz = .25; t.lrz = -.25; t.nx = -.3; },
  talk(r, t, τ) { POSE.idle(r, t, τ); t.arx = -.55 - .2 * S(τ * 5); t.fr = -1.3 + .3 * S(τ * 3.7); t.nx = .06 * S(τ * 4); },
  sit(r, t, τ) { t.llx = -1.5; t.kl = 1.5; t.lrx = -1.5; t.kr = 1.5; t.hY = -.44; t.alx = -.5; t.arx = -.5; t.fl = -.7; t.fr = -.7; t.sx = .05 + .02 * S(τ * 1.5); },
  dance(r, t, τ) { const b = S(τ * 9), h = S(τ * 4.5); t.hY = -.07 + .05 * b; t.hz = .16 * h; t.sz = -.12 * h; t.sy = .35 * h; t.alx = -2.5 + .5 * b; t.arx = -2.5 - .5 * b; t.fl = -.9; t.fr = -.9; t.alz = .35; t.arz = -.35; t.kl = .35 + .3 * b; t.kr = .35 - .3 * b; t.llx = -.2 - .15 * b; t.lrx = -.2 + .15 * b; t.nx = .1 * b; },
  cheer(r, t, τ) { const b = S(τ * 10); t.alx = -2.8; t.arx = -2.8; t.alz = .4 + .15 * b; t.arz = -.4 - .15 * b; t.hY = -.04 + .04 * b; t.sx = -.1; },
  cast(r, t, τ) { t.alx = -2.9; t.arx = -2.9; t.alz = .3; t.arz = -.3; t.fl = -.2; t.fr = -.2; t.sx = -.22; t.hY = .02 * S(τ * 14); },
  slam(r, t) { t.sx = .75; t.alx = -1.2; t.arx = -1.2; t.fl = -.3; t.fr = -.3; t.hY = -.32; t.kl = .9; t.kr = .9; t.llx = -.65; t.lrx = -.65; },
  sweep(r, t) { t.alx = -1.3; t.arx = -1.3; t.alz = -.3; t.arz = .3; t.fl = -.3; t.fr = -.3; t.sx = .25; t.hY = -.1; t.kl = .3; t.kr = .3; },
  point(r, t) { t.arx = -1.5; t.fr = -.05; t.sy = .2; },
  wave(r, t, τ) { t.arx = -2.6; t.arz = -.5 - .3 * S(τ * 9); t.fr = -.4; },
  crouch(r, t) { t.hY = -.3; t.llx = -.8; t.kl = 1.4; t.lrx = -.8; t.kr = 1.4; t.sx = .4; t.alx = -.4; t.arx = -.4; },
  charge(r, t, τ) { POSE.run(r, t, τ, 9 * r.scale); t.sx = .6; t.alx = -1.4; t.arx = -1.4; t.fl = -.2; t.fr = -.2; },
};

class Body {
  constructor(root, h, r) { this.root = root; this.h = h; this.time = Math.random() * 10; this.mats = []; this.shadow = blobShadow(r || .4); root.add(this.shadow); this.fl = 0; }
  flash(v) { this.fl = v; }
  _flash(dt) { if (this.fl > 0 || this._fz) { this.fl = Math.max(0, this.fl - dt * 5); this._fz = this.fl > 0; for (const m of this.mats) m.emissive.setScalar(this.fl * (m.userData.fk || 1)).add(m.userData.em || _c.set(0)); } this.shadow.visible = !G.gfx.renderer.shadowMap.enabled || !G.gfx.sun.castShadow; }
  play() { } set() { }
  dispose() { this.root.removeFromParent(); this.root.traverse(o => { if (o.geometry && o.userData.own) o.geometry.dispose(); }); for (const m of this.mats) m.dispose(); }
}
export class Rig extends Body {
  constructor(sk, o, hY) {
    const root = new THREE.Group(); super(root, 1.9 * (o.scale || 1), .4 * (o.scale || 1));
    root.add(sk.mesh); sk.mesh.userData.own = true; this.mesh = sk.mesh; this.b = sk.b; this.mats.push(sk.mat); this.scale = o.scale || 1; sk.mesh.scale.setScalar(this.scale);
    this.p = { ...REST }; this.t = { ...REST }; this.anim = null; this.base = null; this.at = 0; this.dur = 0; this.phase = Math.random() * 6; this.stiff = 14; this.spin = 0; this.look = 0; this.hipY = hY;
    this.hand = new THREE.Object3D(); this.hand.position.set(0, -.27, 0); this.b.foreR.add(this.hand);
  }
  play(name, dur = .4) { this.anim = name; this.at = 0; this.dur = dur; }
  set(name) { this.base = name; }
  update(dt, speed = 0, air = 0) {
    this.time += dt; const t = this.t, p = this.p, b = this.b; let a;
    if (this.anim) { this.at += dt; if (this.at >= this.dur) this.anim = null; }
    for (const k in REST) t[k] = REST[k]; this.spin = 0;
    if (this.anim) { a = this.anim; POSE[a](this, t, this.at / this.dur, speed); }
    else { a = this.base || (air > 0 ? 'jump' : air < 0 ? 'fall' : speed > .3 ? 'run' : 'idle'); if (a === 'run') this.phase += speed / this.scale * dt * TAU / (.9 + .52 * speed / this.scale); POSE[a](this, t, this.time, speed); }
    const k = 1 - Math.exp(-(this.anim ? 26 : a === 'dead' ? 7 : this.stiff) * dt); for (const key in t) p[key] += (t[key] - p[key]) * k;
    b.hips.position.y = this.hipY + p.hY; b.hips.rotation.set(p.hx + this.spin, p.hy, p.hz); b.spine.rotation.set(p.sx, p.sy, p.sz); b.head.rotation.set(p.nx, p.ny + this.look, 0);
    b.armL.rotation.set(p.alx, 0, p.alz); b.foreL.rotation.x = p.fl; b.armR.rotation.set(p.arx, 0, p.arz); b.foreR.rotation.x = p.fr;
    b.legL.rotation.set(p.llx, 0, p.llz); b.shinL.rotation.x = p.kl; b.legR.rotation.set(p.lrx, 0, p.lrz); b.shinR.rotation.x = p.kr;
    this._flash(dt);
  }
}

// ---------- человек ----------
// o: skin, top, pants, shoes, hair, sleeve:'short'|'long'|'none', style:'tee'|'puffer'|'robe', hairStyle, face(Texture), head, fat, scale, beard, chain, pack, capColor, shorts, body:'moidodyr'
export function makeHuman(o = {}) {
  const hs = o.head || 1.3, fat = o.fat || 1, skin = o.skin ?? 0xdda68c, top = o.top ?? 0xf4f4f4, pants = o.pants ?? 0x23252b, shoes = o.shoes ?? 0xf0f0f0, hair = o.hair ?? 0x3a2a1c, sl = o.sleeve || 'short';
  const puff = o.style === 'puffer' ? 1.28 : 1, sx = .22 * (1 + (fat - 1) * .5) * (puff > 1 ? 1.1 : 1), md = o.body === 'moidodyr';
  const D = [{ n: 'root', par: -1, p: [0, 0, 0] }, { n: 'hips', par: 0, p: [0, .96, 0] }, { n: 'spine', par: 1, p: [0, 1.02, 0] }, { n: 'head', par: 2, p: [0, 1.52, 0] },
  { n: 'armL', par: 2, p: [sx, 1.44, 0] }, { n: 'foreL', par: 4, p: [sx, 1.17, 0] }, { n: 'armR', par: 2, p: [-sx, 1.44, 0] }, { n: 'foreR', par: 6, p: [-sx, 1.17, 0] },
  { n: 'legL', par: 1, p: [.1, .93, 0] }, { n: 'shinL', par: 8, p: [.1, .49, 0] }, { n: 'legR', par: 1, p: [-.1, .93, 0] }, { n: 'shinR', par: 10, p: [-.1, .49, 0] }];
  const parts = [], P = (g, p, c, b, s, r) => parts.push({ g, p, c, b, s, r });
  const rx = .118 * hs, ry = .148 * hs, rz = .132 * hs, hc = [0, 1.57 + ry, .01], armC = sl !== 'none' ? top : skin, foreC = sl === 'long' ? top : skin;
  if (md) {   // Мойдодыр: тумба-умывальник на ножках
    P(BOX, [0, 1.22, 0], 0xf4f6f8, 2, [.66, .62, .44]); P(BOX, [0, 1.22, .225], 0xdfe6ea, 2, [.56, .5, .02]); P(SPH, [-.14, 1.36, .24], 0xe23a3a, 2, .045); P(SPH, [.14, 1.36, .24], 0x3a7be2, 2, .045);
    P(CYL, [0, 1.6, .06], 0xeaf6fb, 3, [.33, .14, .3]); P(CYL, [0, 1.672, .06], 0x6fc6e6, 3, [.27, .01, .24]); P(BOX, [0, 1.95, -.17], 0xcfd8dc, 3, [.56, .62, .06]); P(BOX, [0, 1.96, -.135], 0x9fd0e8, 3, [.48, .52, .02]);
    P(CYL, [0, 1.76, -.1], 0xc9ced2, 3, [.03, .22, .03]); P(CYL, [0, 1.86, -.02], 0xc9ced2, 3, [.028, .18, .028], [PI / 2, 0, 0]);
    P(SPH, [0, .95, 0], 0xcfd8dc, 1, [.3, .12, .2]);
  } else {
    P(SPH, [0, .95, 0], o.style === 'robe' ? top : pants, 1, [.175 * fat * puff, .14, .13 * fat * puff]);
    P(CAP(.15, .2), [0, 1.25, 0], top, 2, [1.3 * fat * puff, 1, .9 * fat * puff]);
    if (fat > 1.15) P(SPH, [0, 1.12, .06], top, 2, [.2 * fat, .19, .18 * fat]);
    if (puff > 1) for (let i = 0; i < 4; i++) P(SPH, [0, 1.09 + i * .105, 0], top, 2, [.2 * puff * (i === 3 ? .92 : 1), .075, .15 * puff]);
    if (o.style === 'robe') P(CONE, [0, .72, 0], top, 1, [.26 * fat, .62, .22 * fat]);
    P(CYL, [0, 1.53, 0], skin, 2, [.055, .12, .055]);
    if (o.chain) P(TOR, [0, 1.4, .075], 0xffc530, 2, [.12, .12, .1], [PI / 2 - .55, 0, 0]);
    if (o.pack) { P(BOX, [0, 1.27, -.27], o.pack, 2, [.4, .44, .3]); P(BOX, [0, 1.27, -.425], 0xffffff, 2, [.3, .12, .01]); }
  }
  for (const s of [1, -1]) {
    const ab = s > 0 ? 4 : 6, fb = ab + 1, lb = s > 0 ? 8 : 10, kb = lb + 1, x = sx * s, ar = md ? .05 : .058 * puff;
    P(SPH, [x, 1.44, 0], md ? 0xc9ced2 : armC, ab, .085 * puff); P(CAP(ar, .17), [x, 1.3, 0], md ? 0xc9ced2 : armC, ab); P(CAP(md ? .045 : .052 * (sl === 'long' ? puff : 1), .16), [x, 1.045, 0], md ? 0xc9ced2 : foreC, fb);
    if (md) P(BOX, [x, .88, .02], s > 0 ? 0xf2a03a : 0xff8fc0, fb, s > 0 ? [.1, .16, .2] : [.13, .09, .2]); else P(SPH, [x, .9, 0], skin, fb, [.058, .07, .05]);
    P(CAP(md ? .07 : .085, .27), [.1 * s, .71, 0], md ? 0xc9ced2 : pants, lb, md ? 1 : [fat > 1.2 ? 1.2 : 1, 1, fat > 1.2 ? 1.2 : 1]); P(CAP(md ? .06 : .068, .28), [.1 * s, .27, 0], md ? 0xc9ced2 : (o.shorts ? skin : pants), kb);
    P(CAP(.058, .13), [.1 * s, .058, .045], md ? 0x3a3f46 : shoes, kb, [1.05, 1, 1], [PI / 2, 0, 0]);
  }
  if (!md) {
    P(SPH, hc, skin, 3, [rx, ry, rz]); P(SPH, [rx * .97, hc[1] - .01, 0], skin, 3, .032 * hs); P(SPH, [-rx * .97, hc[1] - .01, 0], skin, 3, .032 * hs);
    const st = o.hairStyle || 'buzz';
    if (st === 'buzz' || st === 'cap' || st === 'banya') P(HCAP(.5), hc, hair, 3, [rx * 1.035, ry * 1.04, rz * 1.045], [-.4, 0, 0]);
    if (st === 'fringe') { P(HCAP(.52), hc, hair, 3, [rx * 1.07, ry * 1.08, rz * 1.08], [-.2, 0, 0]); P(SPH, [0, hc[1] + ry * .66, rz * .72], hair, 3, [rx * .95, ry * .3, rz * .42]); }
    if (st === 'hood') { P(HCAP(.66), hc, top, 3, [rx * 1.22, ry * 1.17, rz * 1.25], [-.62, 0, 0]); P(TOR, [0, 1.5, .0], top, 2, [.15, .15, .2], [PI / 2, 0, 0]); }
    if (st === 'cap') { P(HCAP(.45), hc, o.capColor ?? 0x222222, 3, [rx * 1.09, ry * 1.09, rz * 1.09], [-.12, 0, 0]); P(BOX, [0, hc[1] + ry * .42, rz * 1.15], o.capColor ?? 0x222222, 3, [rx * 1.5, .012, rz * .7], [.15, 0, 0]); }
    if (st === 'banya') P(CONE, [0, hc[1] + ry * 1.1, -.01], 0xe9dfc8, 3, [rx * 1.25, ry * 1.5, rz * 1.25]);
    if (o.beard) { P(SPH, [0, hc[1] - ry * .82, rz * .5], o.beard, 3, [rx * .86, ry * .55, rz * .62]); P(CONE, [0, hc[1] - ry * 1.5, rz * .5], o.beard, 3, [rx * .6, ry * 1.1, rz * .4], [PI, 0, 0]); }
  }
  const sk = skinned(parts, D, { roughness: o.rough ?? .72 }), rig = new Rig(sk, o, .96);
  const ft = o.face || faceTex({ skin: '#' + new THREE.Color(skin).getHexString() });
  const fm = new THREE.Mesh(FACE_GEO, faceMat(ft));
  if (md) { fm.geometry = gc.pl || (gc.pl = new THREE.PlaneGeometry(1, 1)); fm.material = memo('mdface', () => new THREE.MeshStandardMaterial({ map: faceTex({ skin: '#9fd0e8', mood: 'angry', stache: '#e8eef2', brow: '#1a3a5a' }), roughness: .2, emissive: 0x224455, emissiveIntensity: .5 })); fm.position.set(0, .44, -.12); fm.scale.set(.46, .5, 1); }
  else { fm.position.set(0, hc[1] - 1.52, hc[2]); fm.scale.set(rx * 1.025, ry * 1.025, rz * 1.025); }
  sk.b.head.add(fm); rig.face = fm; rig.headY = hc[1] * rig.scale;
  return rig;
}

// ---------- паук / таракан ----------
export class Spider extends Body {
  constructor(o = {}) {
    const z = o.size || 1, legs = o.legs || 8, hY = .75 * z, c1 = o.color ?? 0x2e2019, c2 = o.color2 ?? 0x6b4a2e, half = legs / 2;
    const D = [{ n: 'root', par: -1, p: [0, 0, 0] }, { n: 'body', par: 0, p: [0, hY, 0] }], parts = [], P = (g, p, c, b, s, r) => parts.push({ g, p, c, b, s, r });
    P(SPH, [0, hY + .12 * z, -.75 * z], c1, 1, [.62 * z, .52 * z, .85 * z]); P(SPH, [0, hY + .5 * z, -.8 * z], c2, 1, [.3 * z, .12 * z, .5 * z]); P(SPH, [0, hY, .22 * z], c1, 1, [.42 * z, .33 * z, .5 * z]);
    if (o.roach) { P(CAP(.012 * z / .35, .5 * z), [.12 * z, hY + .15 * z, .85 * z], c1, 1, 1, [1.1, 0, -.3]); P(CAP(.012 * z / .35, .5 * z), [-.12 * z, hY + .15 * z, .85 * z], c1, 1, 1, [1.1, 0, .3]); }
    else { P(CONE, [.14 * z, hY - .2 * z, .66 * z], 0x1a1210, 1, [.07 * z, .3 * z, .07 * z], [PI - .3, 0, 0]); P(CONE, [-.14 * z, hY - .2 * z, .66 * z], 0x1a1210, 1, [.07 * z, .3 * z, .07 * z], [PI - .3, 0, 0]); }
    for (let i = 0; i < legs; i++) {
      const s = i < half ? 1 : -1, j = i % half, a = (j / (half - 1) - .5) * 1.9, dx = Co(a) * s, dz = -S(a), hip = [.3 * z * s, hY, (.4 - j * .22) * z], knee = [hip[0] + dx * .8 * z, hY + .62 * z, hip[2] + dz * .8 * z], foot = [hip[0] + dx * 1.55 * z, 0, hip[2] + dz * 1.55 * z];
      D.push({ n: 'l' + i, par: 1, p: hip }); parts.push(seg(hip, knee, .075 * z, c1, i + 2), seg(knee, foot, .055 * z, c2, i + 2));
    }
    const sk = skinned(parts, D, { roughness: o.roach ? .35 : .95 }), root = new THREE.Group(); super(root, 1.3 * z, 1.1 * z);
    root.add(sk.mesh); sk.mesh.userData.own = true; this.b = sk.b; this.mats.push(sk.mat); this.legs = legs; this.z = z; this.hY = hY; this.phase = Math.random() * 6; this.pose = 0; this.dead = 0; this.at = 0; this.anim = null;
    if (!o.roach) { const em = memo('speye', () => new THREE.MeshStandardMaterial({ color: 0, emissive: 0xff2a1a, emissiveIntensity: 3 })); for (let k = 0; k < 6; k++) { const e = new THREE.Mesh(SPH, em); e.scale.setScalar(.05 * z * (k < 2 ? 1.5 : 1)); e.position.set(((k % 2) ? 1 : -1) * (.09 + (k >> 1) * .09) * z, (.12 + (k >> 1) * .06) * z, (.66 - (k >> 1) * .07) * z); this.b.body.add(e); } }
  }
  play(n, d = .5) { this.anim = n; this.at = 0; this.dur = d; } set(n) { this.base = n; }
  update(dt, speed = 0, air = 0) {
    this.time += dt; if (this.anim) { this.at += dt; if (this.at >= this.dur) this.anim = null; }
    const a = this.anim || this.base, b = this.b, half = this.legs / 2, mv = sat(speed / (2 * this.z)); this.phase += dt * (4 + speed * 2.2 / this.z);
    const rear = a === 'cast' || a === 'crouch' ? 1 : 0, dd = a === 'dead' ? 1 : 0; this.pose = damp(this.pose, rear, 10, dt); this.dead = damp(this.dead, dd, 6, dt);
    b.body.position.y = this.hY * (1 - .7 * this.dead) + S(this.phase * 2) * .03 * this.z * mv + (a === 'crouch' ? -.25 * this.z : 0) + .04 * this.z * S(this.time * 2);
    b.body.rotation.x = -.45 * this.pose * (a === 'cast' ? 1 : -.3) + (air ? -.3 : 0); b.body.rotation.z = this.dead * 2.9;
    for (let i = 0; i < this.legs; i++) {
      const s = i < half ? 1 : -1, g = (i + (i < half ? 0 : 1)) % 2, ph = this.phase + g * PI, L = b['l' + i], front = (i % half) === 0;
      L.rotation.y = S(ph) * .38 * mv * s; L.rotation.z = s * (Math.max(0, Co(ph)) * .32 * mv + (front ? this.pose * .9 : 0) + this.dead * 1.0 + (air ? .5 : 0) + .03 * S(this.time * 3 + i));
    }
    this._flash(dt);
  }
}

// ---------- пакость (слизень-прыгун) и туманник/пузырь ----------
export class Blob extends Body {
  constructor(o = {}) {
    const z = o.size || 1, root = new THREE.Group(); super(root, .9 * z, .5 * z);
    const mat = new THREE.MeshStandardMaterial({ color: o.color ?? 0x4a3a5c, roughness: .35, metalness: .1, emissive: o.em ?? 0x000000, emissiveIntensity: o.emK ?? 1 }); mat.userData.em = new THREE.Color(o.em ?? 0).multiplyScalar(o.emK ?? 1); this.mats.push(mat);
    const body = this.body = new THREE.Mesh(SPH, mat); body.scale.set(.5 * z, .42 * z, .5 * z); body.position.y = .42 * z; body.castShadow = true; root.add(body);
    const em = memo('bleye' + (o.eye ?? 0xfff36a), () => new THREE.MeshStandardMaterial({ color: 0, emissive: o.eye ?? 0xfff36a, emissiveIntensity: 2.5 }));
    for (const s of [1, -1]) { const e = new THREE.Mesh(SPH, em); e.scale.set(.2, .26, .12); e.position.set(.38 * s, .22, .82); body.add(e); const h = new THREE.Mesh(CONE, mat); h.scale.set(.16, .5, .16); h.position.set(.45 * s, .85, 0); h.rotation.z = -.5 * s; body.add(h); }
    this.z = z; this.ph = Math.random() * 6; this.sq = 0;
  }
  play(n) { if (n === 'hit' || n === 'cast' || n === 'punchR') this.sq = 1; } set(n) { this.base = n; }
  update(dt, speed = 0) {
    this.time += dt; this.ph += dt * (3 + speed * 2.2); this.sq = damp(this.sq, 0, 6, dt); const z = this.z, hop = speed > .2 ? Math.abs(S(this.ph)) : 0, br = S(this.time * 3) * .04, d = this.base === 'dead' ? 1 : 0;
    this.dk = damp(this.dk || 0, d, 8, dt); const sy = (1 + br + hop * .25 - this.sq * .35) * (1 - this.dk * .8), sxz = (1 - br * .5 - hop * .1 + this.sq * .3) * (1 + this.dk * .6);
    this.body.scale.set(.5 * z * sxz, .42 * z * sy, .5 * z * sxz); this.body.position.y = .42 * z * sy + hop * .45 * z; this._flash(dt);
  }
}
export class Wisp extends Body {
  constructor(o = {}) {
    const z = o.size || 1, root = new THREE.Group(); super(root, 1.5 * z, .45 * z); const bub = o.bubble;
    const mat = new THREE.MeshStandardMaterial(bub ? { color: 0xbfe9ff, roughness: .02, metalness: .9, transparent: true, opacity: .45, envMapIntensity: 2, emissive: 0x3a88bb, emissiveIntensity: .25 } : { color: o.color ?? 0xdfe6ee, roughness: .9, transparent: true, opacity: .82, emissive: o.em ?? 0x8fa6c0, emissiveIntensity: o.emK ?? .5 });
    mat.userData.em = new THREE.Color(mat.emissive).multiplyScalar(mat.emissiveIntensity); mat.userData.fk = 1; this.mats.push(mat);
    const g = this.g = new THREE.Group(); root.add(g); const head = new THREE.Mesh(SPH, mat); head.scale.setScalar(.42 * z); g.add(head);
    if (!bub) { const tail = new THREE.Mesh(CONE, mat); tail.scale.set(.4 * z, 1.1 * z, .4 * z); tail.position.y = -.62 * z; tail.rotation.x = PI; g.add(tail); for (const s of [1, -1]) { const a = new THREE.Mesh(CAP(.06, .3), mat); a.scale.setScalar(z); a.position.set(.45 * z * s, -.15 * z, .1 * z); a.rotation.z = .7 * s; g.add(a); } }
    const f = new THREE.Mesh(FACE_GEO, faceMat(faceTex({ skin: bub ? '#cfeeff' : '#f4f4f0', mood: bub ? 'angry' : 'creepy' }))); f.scale.setScalar(.43 * z); g.add(f);
    this.z = z; this.fly = o.fly ?? 1.3; g.position.y = this.fly;
  }
  set(n) { this.base = n; } play(n) { if (n === 'cast') this.pulse = 1; }
  update(dt, speed = 0) {
    this.time += dt; this.pulse = damp(this.pulse || 0, 0, 4, dt); const d = this.base === 'dead' ? 1 : 0; this.dk = damp(this.dk || 0, d, 5, dt);
    this.g.position.y = this.fly + S(this.time * 2.2) * .18 - this.dk * .6; this.g.rotation.x = Math.min(.5, speed * .12); this.g.rotation.z = S(this.time * 1.3) * .08;
    this.g.scale.setScalar((1 + this.pulse * .35) * (1 - this.dk * .9)); this.mats[0].opacity = (this.mats[0].userData.op ?? (this.mats[0].userData.op = this.mats[0].opacity)) * (1 - this.dk); this._flash(dt);
  }
}

// ---------- ФОГ (финальный босс): лицо и руки ----------
export function makeFog() {
  const root = new THREE.Group(), mat = new THREE.MeshStandardMaterial({ color: 0xe9ebee, roughness: .9, emissive: 0xaab4c4, emissiveIntensity: .55, fog: false });
  const head = new THREE.Group(), sk = new THREE.Mesh(SPH, mat); sk.scale.set(4.2, 5.3, 3.6); head.add(sk);
  const fm = new THREE.MeshStandardMaterial({ map: fogFaceTex(), alphaMap: featherTex(), transparent: true, roughness: .9, depthWrite: false, emissiveMap: fogFaceTex(), emissive: 0xffffff, emissiveIntensity: .5, fog: false, polygonOffset: true, polygonOffsetFactor: -1 });
  const f = new THREE.Mesh(FACE_GEO, fm); f.scale.set(4.3, 5.42, 3.7); head.add(f); root.add(head);
  const hand = s => {
    const parts = [], P = (g, p, sc, r) => parts.push({ g, p, c: 0xe9ebee, b: 0, s: sc, r });
    P(BOX, [0, 0, 0], [2.2, .7, 2.4]); for (let i = 0; i < 4; i++) P(CAP(.26, 1.5), [(-.8 + i * .53), 0, 2.1], 1, [PI / 2, 0, 0]); P(CAP(.3, 1.0), [1.45 * s, 0, .3], 1, [PI / 2, 0, -.9 * s]); P(CAP(.5, 2.4), [0, .1, -2.4], 1, [PI / 2, 0, 0]);
    const k = skinned(parts, [{ n: 'root', par: -1, p: [0, 0, 0] }]); k.mesh.material = mat; k.mat.dispose(); k.mesh.castShadow = true; const g = new THREE.Group(); g.add(k.mesh); root.add(g); return g;
  };
  return { root, head, hands: [hand(1), hand(-1)], mat, fm };
}
// рука-предмет: веник, баллончик и т.п. (обычные меши)
export function makeProp(kind) {
  const g = new THREE.Group(), M = (geo, c, s, p, r, extra) => { const m = new THREE.Mesh(geo, memo('pm' + c + (extra || ''), () => new THREE.MeshStandardMaterial({ color: c, roughness: .7 }))); m.scale.set(...s); m.position.set(...p); if (r) m.rotation.set(...r); m.castShadow = true; g.add(m); return m; };
  if (kind === 'broom') { M(CYL, 0x8a623a, [.025, .5, .025], [0, -.05, .12], [PI / 2, 0, 0]); M(CONE, 0x4f7a34, [.2, .7, .12], [0, -.05, .7], [-PI / 2, 0, 0]); }
  if (kind === 'can') { M(CYL, 0xd22f2f, [.04, .16, .04], [0, -.04, .03]); M(CYL, 0xf2f2f2, [.02, .04, .02], [0, .06, .03]); }
  return g;
}
