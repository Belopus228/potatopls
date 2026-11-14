// ГЛАВА 5 — БАНЬКА: зимний лес, дрова и веник, каменка ровно на 100°, Банник и прорубь
import * as THREE from 'three';
import { G, wait, rand, PI, TAU, lerp, smooth, yawTo } from '../g.js';
import { LEVELS } from '../game.js';
import { M, C, glowMat, faceTex, photoTex } from '../tex.js';
import { lampPost, crates, bench, tree, house, fence, barrier, terrain } from '../kit.js';
import { NPC, Enemy, Crate } from '../actors.js';
import { Boss } from '../bosses.js';
import { makeHuman, makeProp } from '../rig.js';
import { inv } from '../items.js';
import { FACE } from '../faces.js';
import { lines, tip } from '../script.js';

const _v = new THREE.Vector3(), HX = 30, HZ = 36, LR = 24, Y = 1;
const DUSK = { top: 0x1c2c5c, hor: 0xf0a878, bot: 0x7a8098, sun: [-.6, .3, -.45], sunCol: 0xffb47a, sunGlow: 0xff9a5a, sunInt: 2.1, sunSize: 120, hemiSky: 0xa0b4e6, hemiGnd: 0xdfe4f0, hemiInt: .85, fog: [0xc9b4b8, 46, 250], clouds: .5, cloudCol: 0xffc8a8, stars: .12, exposure: 1.05, bloom: [.45, .6, .9], envInt: .7, lamp: 1.6, lampCol: 0xffc890, shadowSize: 46 };
const GOODS = [{ id: 'kvas', price: 60 }, { id: 'shava', price: 45 }, { id: 'plums', price: 35 }, { id: 'energy', price: 25 }, { id: 'hp', price: 90, max: 7 }, { id: 'chain', price: 160, max: 3 }];
const BAN = { n: 'БАННИК', e: '♨️', c: '#ffb38a', p: .45 }, PRA = { n: 'Пра Дод', e: '🧙' };

// ---------- БАННИК ----------
class Bannik extends Boss {
  constructor(x, y, z) {
    const body = makeHuman({ face: faceTex({ mood: 'angry', skin: '#d87860', stache: '#f2f2f2', brow: '#f2f2f2' }), top: 0xe9dfc8, style: 'robe', sleeve: 'none', hairStyle: 'banya', beard: 0xf2f2f2, hair: 0xf2f2f2, fat: 1.45, skin: 0xd87860, scale: 2 });
    const br = makeProp('broom'); br.scale.setScalar(1.3); body.hand.add(br);
    super(x, y, z, { name: 'БАННИК', hp: 860, r: 1.25, h: 3.8, mass: 12, solidR: 1, aimY: 2.2, body }); this.n = 0; this.p2 = false;
  }
  shout(t, cls = 'alert') { _v.set(this.pos.x, this.pos.y + 4.8, this.pos.z); G.fx.text(_v, t, cls); }
  *tubs(n) {
    this.body.play('throw', .5); yield* this.wait(.28, 12); const a = this.toP(), sp = 14, t = Math.max(.3, this.dist() / sp), gr = 12, y0 = this.pos.y + 2.8;
    for (let i = 0; i < n; i++) { const b = a + (i - (n - 1) / 2) * .24; this.shoot({ x: this.pos.x + Math.sin(b) * 1.4, z: this.pos.z + Math.cos(b) * 1.4, y: y0, vx: Math.sin(b) * sp, vz: Math.cos(b) * sp, vy: (this.P.pos.y + 1 - y0) / t + .5 * gr * t, grav: gr, dmg: 12, kind: 'tub', knock: 8 }); }
    G.audio.sfx('throw'); yield* this.wait(.7, 6);
  }
  // облако пара: висит и жжёт несколько секунд
  *cloud(x, z) {
    const y = this.floorY(x, z); yield* this.blast(x, z, 2.8, .8, 9, { fx: 'steam', color: 0xffffff, ring: 0xffffff, sfx: 'steam', shake: 0, y });
    for (let i = 0; i < 4 && !this.dead; i++) { yield* this.wait(.45); _v.set(x, y + .3, z); G.fx.burst('steam', _v, 5, { s: 1.3 }); this.hitCircle(x, z, 2.8, 7, 3); }
  }
  *steam() {
    const P = this.P; this.body.play('cast', 1); this.shout('ПАР!'); G.audio.sfx('steam'); yield* this.wait(.5);
    for (let i = 0; i < (this.p2 ? 4 : 3); i++) { const a = rand(TAU), rr = i ? rand(3, 7) : 0; G.run(this.cloud(P.pos.x + Math.sin(a) * rr, P.pos.z + Math.cos(a) * rr)); yield* this.wait(.25); }
    yield* this.wait(1, 4);
  }
  *stones(n) {
    const P = this.P; this.body.play('cast', 1.2); this.shout('КАМЕНКА!');
    for (let i = 0; i < n; i++) { const a = rand(TAU), rr = i ? rand(1, 8) : 0; G.run(this.blast(P.pos.x + Math.sin(a) * rr, P.pos.z + Math.cos(a) * rr, 2.4, .95, 14, { fx: 'fire', color: 0xff7a2a, ring: 0xffb060, sfx: 'slam', shake: .25 })); yield* this.wait(.18); }
    yield* this.wait(.9, 4);
  }
  // разбег: если на пути прорубь — ныряет, вылетает и стоит, дрожит
  *dash() {
    const P = this.P; this.body.play('crouch', .75); this.shout('С ЛЁГКИМ ПАРОМ!'); G.audio.sfx('roar'); yield* this.wait(.75, 10);
    const a = this.toP(), sp = 15; let t = 1.5, hitP = false; this.yaw = a; this.body.set('charge');
    while (t > 0) {
      t -= G.dt; this.vel.x = Math.sin(a) * sp; this.vel.z = Math.cos(a) * sp; this.speed = sp; if (Math.random() < .5) G.fx.burst('snow', this.pos, 1);
      if (!hitP && this.dist() < this.r + P.r + .4 && Math.abs(P.pos.y - this.pos.y) < 2) hitP = P.hurt(18, this.pos, 13);
      if (Math.hypot(this.pos.x - HX, this.pos.z - HZ) < 2.3) {
        this.speed = 0; this.vel.set(0, 0, 0); this.body.set('hit'); _v.set(HX, .2, HZ); G.fx.burst('water', _v, 30, { s: 2, sp: 1.6 }); G.fx.ring(_v, 1, 7, .6, 0xa8dcff); G.audio.sfx('splash'); G.cam.shake(.8); this.shout('БУЛТЫХ!', 'good'); yield* this.wait(.7);
        const b = yawTo(HX, HZ, P.pos.x, P.pos.z), tx = HX + Math.sin(b) * 6.5, tz = HZ + Math.cos(b) * 6.5, sx = this.pos.x, sz = this.pos.z, y0 = this.pos.y, T = .6; let k = 0; this.fly = true; this.solidR = 0;
        while (k < 1) { k = Math.min(1, k + G.dt / T); this.pos.x = lerp(sx, tx, k); this.pos.z = lerp(sz, tz, k); this.pos.y = lerp(y0, 0, k) + Math.sin(k * PI) * 4; yield; }
        this.pos.y = 0; this.fly = false; this.solidR = 1; this.vel.set(0, 0, 0); this.vul = 1.8; this.shout('ОСТЫЛ!', 'good'); G.audio.sfx('land', 1.5); G.fx.burst('snow', this.pos, 12, { s: 1.5 });
        let w = this.p2 ? 3.2 : 4; while ((w -= G.dt) > 0) { if (Math.random() < .25) { _v.set(this.pos.x + rand(-.6, .6), this.pos.y + rand(1, 3.4), this.pos.z + rand(-.6, .6)); G.fx.burst('steam', _v, 1, { s: .7 }); } yield; }
        this.vul = 1; this.body.set(null); return;
      }
      yield;
    }
    this.speed = 0; this.body.set(null); yield* this.wait(.7, 5);
  }
  *ai() {
    const ph = this.hp / this.maxHp, d = this.dist();
    if (ph < .5 && !this.p2) { this.p2 = true; this.invul = true; this.shout('ПОДДАМ ПАРКУ!'); this.body.play('cast', 1.4); G.audio.sfx('roar'); G.cam.shake(.8); yield* this.wait(1.2); this.invul = false; this.summon('steam', 3, 5); yield* this.stones(7); return; }
    if (d < 4.4 && Math.random() < .55) { this.body.play('sweep', .65); yield* this.wait(.3, 10); const a = this.yaw; yield* this.blast(this.pos.x + Math.sin(a) * 2.2, this.pos.z + Math.cos(a) * 2.2, 3.4, .35, 16, { fx: 'snow', sfx: 'whoosh' }); yield* this.wait(.6, 5); }
    else {
      const k = this.n++ % 5;
      if (k === 0 || k === 3) yield* this.dash();
      else if (k === 1) yield* this.tubs(this.p2 ? 5 : 3);
      else if (k === 2) yield* this.steam();
      else if (this.p2) { for (let i = 0; i < 2; i++) { G.run(this.shockwave(this.pos.x, this.pos.z, 28, 2.2, 14, 0xffb060)); this.body.play('slam', .5); G.cam.shake(.5); yield* this.wait(1); } yield* this.wait(.5, 5); }
      else yield* this.stones(5);
    }
    yield* this.chase(this.p2 ? 4.8 : 4, rand(.8, 1.6), 3.6);
  }
}

LEVELS.banya = {
  id: 'banya', title: 'БАНЬКА', sub: 'ГЛАВА 5', music: 'banya', weather: 'snow', seed: 51, env: DUSK,
  kit: { gear: { phone: 1, spray: 1, chain: 1, ult: 1, kicks: 1, hp: 2 }, money: 160, inv: { doshik: 2, shava: 1, milk: 1 }, flags: { m_boss: 1, m_drun: 1, m_lift: 1 } },
  build(L) {
    const g = G.game, r = L.r, f = k => g.flag(k), dH = (x, z) => Math.hypot(x - HX, z - HZ), SNOW = C(0xf4f8fc, .95), LOG = M.logs(), PD = M.planksDark();
    const hfn = (x, z) => {
      let h = Y + .6 + Math.sin(x * .06) * .9 + Math.cos(z * .05 + 2) * .8 + Math.sin((x + z) * .09) * .45;
      h = lerp(Y, h, smooth(19, 30, Math.hypot(x, z + 10))); h = lerp(Y, h, smooth(9, 16, Math.hypot(x, z + 76)));
      h = lerp(h, Y, (1 - smooth(2.5, 6, Math.abs(x))) * (1 - smooth(-30, -26, z)) * smooth(-82, -76, z));
      const dl = dH(x, z); h = lerp(0, h, smooth(LR + .5, LR + 7, dl)); h -= 3.2 * (1 - smooth(2.2, 3.8, dl));
      return h + smooth(86, 108, Math.max(Math.abs(x - 4), Math.abs(z - 2))) * 12;
    };
    const hf = terrain(L, 200, 100, hfn, (x, z, h, ny) => { const dl = dH(x, z); return dl < 4.2 ? 0x8fb0c4 : dl < LR + 1.5 ? 0xb9dcf0 : ny < .88 ? 0xc4d0dc : (Math.abs(x) < 2.6 && z > -76 && z < -28) || Math.hypot(x, z + 10) < 17 ? 0xdde3ea : 0xf6f9fc; }, { cx: 4, cz: 2, tile: 6 });
    barrier(L, -84, 2, 2, 190); barrier(L, 92, 2, 2, 190); barrier(L, 4, -90, 190, 2); barrier(L, 4, 94, 190, 2);
    L.hazard = p => p.y < -1.1 && dH(p.x, p.z) < 5; L.unsafe = p => dH(p.x, p.z) < 5.6;
    // --- озеро и прорубь ---
    L.mesh(new THREE.RingGeometry(3.6, LR + .4, 48), C(0xb4dcf2, .07, .25), HX, .05, HZ, { rx: -PI / 2, recv: true }); L.cyl(C(0x10384a, .05, .6), HX, -.55, HZ, 3.9, .06, { seg: 20 });
    for (let i = 0; i < 22; i++) { const a = i / 22 * TAU + .1, x = HX + Math.sin(a) * (LR + 3.4), z = HZ + Math.cos(a) * (LR + 3.4); L.sph(SNOW, x, hf(x, z) + .1, z, 1, { s: [3.4, 1 + (i % 3) * .3, 2.2], ry: a }); }
    const ring = []; for (let i = 0; i < 22; i++) { const a = i / 22 * TAU, s = L.world.box(HX + Math.sin(a) * (LR + .9), 4, HZ + Math.cos(a) * (LR + .9), 7.4, 12, 1, a, { nocam: true }); s.off = true; ring.push(s); }
    L.sign('ПРОРУБЬ\nНЕ НЫРЯТЬ', HX + 5.2, 1.5, HZ - 3, 2, 1, -PI / 2 - .5, { bg: '#134a8a', fg: '#fff', border: '#fff', dbl: 1 }); L.cyl(PD, HX + 5.2, .7, HZ - 3, .07, 1.5, { seg: 5, solid: true });
    L.box(PD, HX - 3.2, .3, HZ + 2.4, .5, 1.6, .1, { rot: .9, solid: false }); for (let i = 0; i < 4; i++) L.box(PD, HX - 3.2, -.2 + i * .3, HZ + 2.4, .5, .05, .16, { rot: .9, solid: false });
    // --- лес ---
    const W = [[-46, 14], [-22, 64], [62, -18]], SH = [66, 68];
    const clear = (x, z) => Math.hypot(x, z + 10) < 25 || Math.hypot(x, z + 76) < 13 || (Math.abs(x) < 5 && z > -80 && z < -24) || dH(x, z) < LR + 6 || W.some(w => Math.hypot(x - w[0], z - w[1]) < 5) || Math.hypot(x - SH[0], z - SH[1]) < 9;
    for (let i = 0; i < 130; i++) { const x = -82 + r() * 172, z = -88 + r() * 180; if (clear(x, z)) continue; tree(L, x, z, .9 + r() * .8, i % 5 === 0 ? 'bare' : i % 3 === 0 ? 'pine' : 'snowpine'); }
    for (let i = 0; i < 40; i++) { const x = -80 + r() * 168, z = -86 + r() * 176; if (dH(x, z) < LR + 5 || Math.hypot(x, z + 10) < 12) continue; L.sph(SNOW, x, hf(x, z) - .1, z, 1, { s: [1.6 + r() * 2, .5 + r() * .5, 1.4 + r() * 1.6], ry: r() * 6 }); }
    // --- станция ---
    const SY = Y + .4; L.box(M.planks(), 0, Y + .2, -79, 18, .4, 5); for (const dz of [-.72, .72]) L.box(M.metal(), 0, Y + .14, -84 + dz, 150, .14, .1, { solid: false }); for (let i = 0; i < 60; i++) L.box(PD, -74 + i * 2.5, Y + .05, -84, .3, .1, 2.6, { solid: false });
    L.box(0x2f8a55, 5, Y + 2.05, -84, 26, 2.7, 2.7, { gloss: 1 }); L.box(C(0x1a2a3a, .1, .7), 5, Y + 2.6, -82.63, 24, .9, .06, { solid: false }); L.box(SNOW, 5, Y + 3.5, -84, 25.6, .3, 2.5, { solid: false }); L.box(M.metalDark(), 5, Y + .5, -84, 24, .6, 2.2, { solid: false });
    L.sign('БАНЬКА', 0, Y + 4.2, -76.4, 6, 1.2, 0, { bg: '#5a3a22', fg: '#ffe9a8', border: '#ffe9a8' }); L.sign('БАНЬКА', 0, Y + 4.2, -76.5, 6, 1.2, PI, { bg: '#5a3a22', fg: '#ffe9a8', border: '#ffe9a8' }); for (const s of [-1, 1]) L.cyl(PD, s * 3.2, Y + 2.4, -76.45, .1, 4.4, { seg: 6, solid: true });
    lampPost(L, -7, -75, Y, 0xffb060, 5, 0); lampPost(L, 5.2, -50, hf(5.2, -50), 0xffb060, 5, PI); lampPost(L, -5.2, -32, hf(-5.2, -32), 0xffb060, 5, 0);
    L.sign('БАНЬКА ПРА ДОДА →\nПАР. КВАС. ПОСИДИМ.', 4.6, Y + 1.7, -68, 3.6, 1.2, PI, { bg: '#5a3a22', fg: '#ffe9a8', border: '#ffe9a8', dbl: 1 }); for (const s of [-1, 1]) L.cyl(PD, 4.6 + s * 1.6, Y + .8, -68, .07, 1.7, { seg: 5, solid: true });
    // --- банька ---
    house(L, -15, -8, 13, 9, { rot: PI / 2, mat: LOG, roof: 0x4a3226, h: 3.6, lit: 1, y: Y });
    L.sign('БАНЬКА ПРА ДОДА', -10.42, Y + 3.2, -8, 5.2, .8, PI / 2, { bg: '#5a3a22', fg: '#ffe9a8', border: '#ffe9a8' });
    L.box(M.metalDark(), -15, Y + 1.05, -14.58, 1.3, 1.1, .14, { solid: false }); L.box(M.brick(), -15, Y + 1, -14.62, 2.4, 2, .2, { solid: false });
    const fire = L.mesh(new THREE.BoxGeometry(.8, .5, .08), f('b_fire') ? glowMat(0xff7a2a, 3) : C(0x1a1a1c, .9), -15, Y + .95, -14.72);
    L.box(PD, -15, Y + 3, -15.5, 4.4, .12, 2, { solid: false }); for (const s of [-1, 1]) L.cyl(PD, -15 + s * 2, Y + 1.5, -16.3, .08, 3, { seg: 6, solid: true }); L.box(SNOW, -15, Y + 3.14, -15.5, 4.5, .16, 2.1, { solid: false });
    for (let i = 0; i < 3; i++) L.box(LOG, -18.2, Y + .25 + i * .42, -15.6, 1.6, .4, .9, { solid: i === 0 }); const sl = L.lamp(-15, Y + 1.4, -15.8, 0xff8a3a, f('b_fire') ? 40 : 6, 12);
    bench(L, -9.2, -12, PI / 2, Y); L.cyl(M.planks(), -8.6, Y + .5, -4.6, .6, 1, { seg: 10, solid: true }); L.cyl(C(0x3a6a8a, .1, .4), -8.6, Y + .98, -4.6, .5, .04, { seg: 10 });
    L.box(LOG, -15, Y + .7, 1.4, 3.6, 1.4, 2.8); L.box(SNOW, -15, Y + 1.5, 1.4, 3.9, .3, 3.1, { solid: false }); L.box(0x5a3a22, -13.16, Y + .65, 1.4, .08, 1.2, 1, { solid: false }); L.sign('ПОГРЕБ · КВАС', -13.1, Y + 1.9, 1.4, 2.6, .5, PI / 2, { bg: '#f2f2e6', fg: '#5a3a22', border: '#5a3a22' });
    lampPost(L, -4, -17, Y, 0xffb060, 5, 0); lampPost(L, 3, -1, Y, 0xffb060, 5, PI); fence(L, -22, -18, -22, 4, 1.1, PD, Y); fence(L, -22, 4, -8, 6, 1.1, PD, Y);
    for (const [k, y, s] of [[0, .7, .9], [1, 1.9, .65], [2, 2.8, .45]]) L.sph(SNOW, 8, Y + y, -16, s); L.cone(0xff7a2a, 8, Y + 2.8, -15.5, .08, .4, { rx: PI / 2 }); L.world.cyl(8, -16, .8, Y, Y + 3);
    let smk = 0; L.onUpdate(dt => { smk -= dt; if (smk <= 0 && G.player.pos.distanceToSquared(_v.set(-13, Y, -11)) < 8100) { smk = f('b_fire') ? .1 : .5; _v.set(-13.2, Y + 8.6, -11.25); G.fx.burst(f('b_fire') ? 'steam' : 'smoke', _v, 1, { s: f('b_fire') ? 1.3 : .7 }); } });
    // --- дрова и сарай с веником ---
    W.forEach(([x, z], i) => { const y = hf(x, z); L.cyl(M.bark(), x + 1.2, y + .3, z, .5, .6, { seg: 8, solid: true }); for (let k = 0; k < 4; k++) L.box(LOG, x - 1.4, y + .2 + (k >> 1) * .4, z - .4 + (k % 2) * .8, 1.6, .38, .7, { solid: k === 0, rot: .2 }); });
    { const [x, z] = SH, y = hf(x, z); L.box(PD, x, y + 1.4, z + 2.2, 6.4, 2.8, .2); L.box(PD, x - 3.1, y + 1.4, z, .2, 2.8, 4.4); L.box(PD, x + 3.1, y + 1.4, z, .2, 2.8, 4.4); L.box(PD, x, y + 2.9, z, 7, .2, 5.2, { solid: false }); L.box(SNOW, x, y + 3.1, z, 7.2, .3, 5.4, { solid: false }); L.box(M.dirt(), x, y + .04, z, 6, .1, 4.2, { solid: false }); L.sign('ВЕНИКИ', x, y + 3.6, z - 2.7, 2.6, .6, PI, { bg: '#5a3a22', fg: '#ffe9a8', border: '#ffe9a8' }); L.lamp(x, y + 2.2, z - 1, 0xffb060, 24, 12); L.box(glowMat(0xffb060, 2), x, y + 2.7, z - 1, .3, .12, .3, { solid: false }); }
    // --- точки и цели ---
    L.cps = { start: [0, SY, -79, 0], yard: [-2, Y, -22, 0], lake: [18, 0, 24, PI / 4] };
    const DODP = [-9.15, Y + 1.6, -12], PRAP = [-11.4, Y + 1.6, 1.4];
    function setGoal() {
      if (f('b_boss')) return g.goal('Кнопка «Б» у тебя! Возвращайся на станцию к машинисту', -6, SY + 1.5, -79.5);
      if (f('b_fire')) return g.goal('Победи Банника на озере. Замани его в прорубь — и бей, пока дрожит!', HX, 1, HZ);
      if (f('b_ok')) return g.goal('Затопи печь: каменка должна показать ровно 100°', -15, Y + 1.2, -15.6);
      if (!f('b_dod')) return g.goal('Найди Дода у баньки', ...DODP);
      const w = inv.count('wood'), v = inv.has('venik'); if (w >= 3 && v) return g.goal('Отнеси дрова и веник Пра Доду', ...PRAP);
      const i = W.findIndex((_, k) => !f('banya.w' + k)); if (w < 3 && i >= 0) return g.goal(`Собери дрова в лесу (${w}/3)${v ? '' : ' и найди веник'}`, W[i][0], hf(W[i][0], W[i][1]) + 1, W[i][1]);
      g.goal('Найди дубовый веник в сарае за озером', SH[0], hf(SH[0], SH[1]) + 1, SH[1]);
    }
    L.trigger(0, -26, 0, () => g.checkpoint('yard'), { box: [8, 2] });
    // --- печь: головоломка с градусами ---
    function* stove() {
      if (!f('b_ok')) return yield* lines([['sys', f('b_dod') ? 'Топка пустая и холодная. Сначала дрова и веник — Пра Доду.' : 'Топка пустая и холодная. Изнутри кто-то сердито сопит.']]);
      let T = 30, fails = 0; yield* lines([['sys', 'Ты закладываешь берёзовые дрова в топку. Каменка: 30°.']]);
      for (; ;) {
        yield* G.ui.say('sys', `Каменка: ${T}°. Нужно ровно 100°. Больше 120° — угоришь. Что поддать?`);
        const c = yield* G.ui.choose(['Охапка дров: +40°', 'Ковш кваса на камни: +25°', 'Ковш ледяной воды: −15°', 'Отойти от печи']); if (c === 3) return;
        T += [40, 25, -15][c]; _v.set(-15, Y + 1.2, -15.1); G.fx.burst(c === 2 ? 'steam' : 'fire', _v, 8); G.audio.sfx(c === 2 ? 'steam' : 'power'); if (T === 100) break;
        if (T > 120 || T < 10) { fails++; yield* lines(T > 120 ? [[PRA, 'Угорим! Заливай!'], ['sys', 'Пра Дод вылил на камни целый ушат. Каменка снова: 30°.']] : [['sys', 'Печь погасла. Разжигаешь заново. Каменка: 30°.']]); T = 30; if (fails === 2) yield* lines([[PRA, 'Подскажу, внучок: четыре ковша кваса и два — воды. Только воду лей вовремя, чтоб за сто двадцать не ушло.']]); }
      }
      g.setFlag('b_fire'); fire.material = glowMat(0xff7a2a, 3); sl.int = 40; G.audio.sfx('ding'); yield* lines([['sys', 'Каменка: ровно 100°. Банька задышала.'], [PRA, 'Во-от. Теперь — баня. Ой… а это кто там сопит?']]);
      G.mode = 'cut'; G.audio.music(null); armBoss(); boss.fly = true; boss.pos.set(-13.2, Y + 7.4, -11.25); boss.yaw = PI / 2; boss.root.scale.setScalar(.01); G.cam.shot(-1, Y + 4.5, -19, -13.2, Y + 9.5, -11.25, false, 2); yield* wait(1.1);
      G.cam.shake(1); G.audio.sfx('boom'); for (let i = 0; i < 3; i++) { _v.set(-13.2, Y + 9 + i, -11.25); G.fx.burst('steam', _v, 14, { s: 2 }); } let k = 0; while (k < 1) { k = Math.min(1, k + G.dt * 2.5); boss.root.scale.setScalar(k); boss.pos.y = Y + 7.4 + k * 2; yield; } boss.body.play('cast', 1.4); G.audio.sfx('roar'); yield* wait(.9);
      yield* lines([[BAN, 'КТО. МОЮ. БАНЮ. ТОПИТ?!'], ['dod', 'О! Вылез! Ч, это Банник. Он холода боится — зови его на озеро!'], [BAN, 'Четвёртый пар — МОЙ! А кнопка — тёплая. Не отдам!'], ['ch', 'Пошли на лёд, дед. Там и поговорим.']]);
      const sx = boss.pos.x, sy = boss.pos.y, sz = boss.pos.z; k = 0; G.audio.sfx('whoosh'); while (k < 1) { k = Math.min(1, k + G.dt / 1.1); boss.pos.set(lerp(sx, 14, k), lerp(sy, 3, k) + Math.sin(k * PI) * 9, lerp(sz, 16, k)); G.cam.shot(-1, Y + 4.5, -19, boss.pos.x, boss.pos.y + 2, boss.pos.z, false, 5); yield; }
      yield* G.ui.fadeTo(1, .35); boss.pos.set(39, 0, 45); boss.fly = false; boss.vel.set(0, 0, 0); boss.yaw = -PI * .75; G.player.place(18, 0, 24, PI / 4); G.cam.free(); G.cam.snap(); g.checkpoint('lake', true); g.write(); setGoal(); yield* wait(.3); yield* G.ui.fadeTo(0, .4);
    }
    L.interact(-15, Y + 1, -15.6, 2.4, 'Затопить печь', () => g.script(stove), { cond: () => !f('b_fire') });
    L.interact(-9.7, Y + 1, -8, 2.2, 'Попариться', () => g.script(function* () { yield* G.ui.fadeTo(1, .5); G.audio.sfx('steam'); yield* wait(.8); const p = G.player; p.hp = p.maxHp; yield* G.ui.fadeTo(0, .5); yield* lines([['dod', 'Вот! Вот это — посидели. С лёгким паром, Ч.']]); G.ui.toast('♨️ С лёгким паром! Здоровье восстановлено', 'big'); }), { cond: () => f('b_boss') });
    // --- NPC ---
    const mash = { n: 'Машинист', e: '🚂' };
    g.spawn(new NPC(DODP[0], Y, DODP[2], { name: 'Дод', yaw: PI / 2, still: true, solid: false, anim: 'sit', keepAnim: true, mark: f('b_dod') ? null : '!', look: { face: photoTex(FACE.dod), top: 0xf2efe6, style: 'robe', sleeve: 'none', hairStyle: 'banya', fat: 1.35, skin: 0xe8b090 }, *talk(n) {
      if (!f('b_dod')) {
        yield* lines([['dod', 'Ч! Какие люди! Заходи, посидим, попаримся!'], ['dod', '…А, нет. Не попаримся. Банька остыла. Банник печку задул, дрова по лесу раскидал, а веник Пра Дода уволок в сарай за озером.'], ['ch', 'А кнопку от ливта не видел? Жёлтую.'], ['dod', 'Кнопку он в каменку сунул. Говорит: «Кто мою баню без спросу топит — того запарю». Затопим — сам вылезет.'], ['dod', 'Нужны три охапки дров и дубовый веник. Без веника Пра Дод к печке не подпустит. Он строгий.']]);
        g.setFlag('b_dod'); n.setMark(null); setGoal();
      } else yield* lines([['dod', f('b_boss') ? 'Ну вот теперь — посидим! Заходи в баньку, дверь открыта.' : f('b_fire') ? 'Банник холода боится! Встань так, чтобы прорубь была между вами. Нырнёт, вылетит, задрожит — тогда и бей.' : f('b_ok') ? 'Топи! Топка — с торца, под навесом. Пар нужен ровно сто градусов.' : inv.count('wood') < 3 ? 'Дрова — в лесу: на западе, на севере и на востоке. Снежные пакости их стерегут.' : inv.has('venik') ? 'Всё собрал? Неси Пра Доду, он у погреба.' : 'Веник — в сарае за озером, на северо-востоке. Там парильщики. Злые, как пар.']]);
      n.yaw = n.yaw0;
    } }));
    const pn = g.spawn(new NPC(PRAP[0], Y, PRAP[2], { name: 'Пра Дод', yaw: PI / 2, mark: f('b_ok') ? '?' : '!', look: { face: faceTex({ mood: 'smile', skin: '#e0a890', stache: '#eeeeee', brow: '#eeeeee' }), top: 0xe9dfc8, style: 'robe', sleeve: 'short', hairStyle: 'banya', beard: 0xeeeeee, hair: 0xeeeeee, skin: 0xe0a890, fat: 1.2 }, *talk(n) {
      if (!f('b_ok')) {
        if (inv.count('wood') >= 3 && inv.has('venik')) { yield* lines([[PRA, 'Берёзовые… сухие. И веник мой, дубовый! Ну, внучок, уважил.'], [PRA, 'Топи. Топка с торца, под навесом. Только запомни: пар — ровно сто градусов. Меньше — не баня. Больше ста двадцати — угоришь.']]); inv.take('wood', 3); inv.take('venik'); g.setFlag('b_ok'); n.setMark('?'); g.write(); return setGoal(); }
        yield* lines([[PRA, 'Без дров нет жара. Без веника нет бани. Без бани нет жизни. Неси, внучок.']]);
      } else yield* lines([[PRA, f('b_boss') ? 'Банник-то присмирел. Давно его так не парили.' : 'Квасу? Холодный, из погреба.']]);
      if ((yield* G.ui.choose(['Заглянуть в погреб (купить)', 'Уйти'])) === 0) yield* G.ui.shop('ПОГРЕБ ПРА ДОДА', GOODS, 'Квас холодный, вкусности тёплые');
    } }));
    g.spawn(new NPC(-6, SY, -79.5, { name: 'Машинист', yaw: 0, mark: f('b_boss') ? '!' : null, label: 'Сесть на «поез»', look: { face: faceTex({ mood: 'smile', stache: '#555' }), top: 0x20305a, sleeve: 'long', pants: 0x20305a, hairStyle: 'cap', capColor: 0x20305a }, *talk() {
      yield* lines([[mash, f('b_boss') ? 'Распаренный! И с кнопкой. Едем в Мурино?' : '«Поез» подождёт. Но если хочешь назад без кнопки — дело твоё.']]);
      if ((yield* G.ui.choose(['Поехали в Мурино', 'Остаться в Баньке'])) === 0) { G.audio.sfx('tram'); g.travel('murino', 'station'); }
    } }));
    // --- предметы и враги ---
    if (!f('b_ok')) { W.forEach(([x, z], i) => g.item('wood', x, hf(x, z) + .5, z, 'banya.w' + i, { onTake: setGoal })); g.item('venik', SH[0], hf(SH[0], SH[1]) + .6, SH[1] + 1, 'banya.venik', { onTake: setGoal }); }
    const cr = (x, z) => [x, z, hf(x, z)]; crates(L, [cr(-6, -60), cr(7, -42), cr(6, -20), cr(-20, 10), cr(-50, 20), cr(-26, 58), cr(58, -22), cr(70, 62), cr(40, 70), cr(-60, -40), cr(50, 0), cr(-40, -70)], Crate);
    g.item('hp', 76, hf(76, 78) + .5, 78, 'banya.hp'); g.item('plums', HX + 14, .5, HZ + 14, 'banya.pl'); g.cash(20, -66, hf(-66, 40) + .5, 40, 'banya.c1'); g.cash(20, 78, hf(78, -50) + .5, -50, 'banya.c2'); g.cash(20, -50, hf(-50, -60) + .5, -60, 'banya.c3'); g.item('kvas', -70, hf(-70, 76) + .5, 76, 'banya.kv');
    const E = (k, x, z) => g.spawn(new Enemy(k, x, hf(x, z), z));
    if (!f('b_boss')) {
      E('snowy', -5, -46); E('snowy', 6, -40); E('snowy', -44, 10); E('snowy', -49, 18); E('steam', -40, 20); E('snowy', -24, 60); E('snowy', -18, 67); E('snowy', 60, -14); E('snowy', 66, -20); E('steam', 56, -24);
      E('banshik', 60, 62); E('banshik', 70, 60); E('banshik', 64, 56); E('steam', 73, 66); E('snowy', 30, -30); E('steam', -60, -20); E('banshik', -56, 50);
    }
    // --- босс ---
    let boss = null;
    function armBoss() {
      boss = g.spawn(new Bannik(39, 0, 45)); boss.yaw = -PI * .75; boss.sync(); boss.fade = true;
      L.trigger(HX, HZ, LR - 2, () => g.script(function* () {
        const P = G.player.pos; G.audio.music('boss'); G.cam.shot(P.x - 2.5, P.y + 2.2, P.z - 3.5, boss.pos.x, 2.4, boss.pos.z, false, 2.2); yield* wait(.8);
        if (!f('b_met')) { yield* lines([[BAN, 'Ну, грязнуля, сейчас я тебя попарю. С веничком. До первого августа.'], ['ch', 'До тридцать второго, дед. Ам-ам-ам!']]); g.setFlag('b_met'); }
        boss.body.play('cast', 1.2); G.audio.sfx('roar'); G.cam.shake(.8); G.ui.bigTitle('БАННИК', 'БОСС', 2400); yield* wait(1.3); for (const s of ring) s.off = false; boss.start(); setGoal();
        tip('Встань так, чтобы прорубь была между тобой и Банником, когда он разбегается', 'Встань так, чтобы прорубь была между тобой и Банником, когда он разбегается');
      }, 'cut'));
      boss.onDefeat = () => { g.setFlag('b_boss'); inv.add('btn3'); G.save.money += 100; for (const s of ring) s.off = true; G.audio.music('banya'); G.audio.sfx('win'); g.checkpoint('yard', true); g.write(); setGoal(); g.script(function* () { yield* lines([[BAN, 'Ох… Уф… Ладно. Хороший пар. Уважил. Забирай кнопку — она ещё тёплая.'], ['ch', 'Кнопка «Б». Третья! Все три. Пора в ливт.'], ['phone', '*бзззз* Дод: «Ч! Ну вот теперь — посидим! Заходи в баньку, пока поез не ушёл».']]); }); };
    }
    if (f('b_fire') && !f('b_boss')) armBoss();
    L.start = function* (cp) { setGoal(); if (cp === 'start' && !f('b_dod')) { yield* wait(1.2); tip('Банька. Холодно. Где-то впереди должно быть тепло', 'Банька. Холодно. Где-то впереди должно быть тепло'); } };
  },
};
