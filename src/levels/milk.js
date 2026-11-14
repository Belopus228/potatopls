// ГЛАВА 3 — СЕЛО МОЛОЧНОЕ: трамвай «Гота», паучности, трансформатор, Паучья яма
import * as THREE from 'three';
import { G, wait, rand, PI, TAU, lerp, smooth, damp } from '../g.js';
import { LEVELS } from '../game.js';
import { GEO } from '../level.js';
import { M, C, glowMat, faceTex } from '../tex.js';
import { lampPost, crates, at, block, bench, tree, bush, house, fence, barrier, terrain, water, grass, web } from '../kit.js';
import { NPC, Enemy, Crate } from '../actors.js';
import { Boss } from '../bosses.js';
import { Spider } from '../rig.js';
import { WirePuzzle } from '../puzzles.js';
import { inv } from '../items.js';
import { lines, tip } from '../script.js';
import { DAY } from './murino_env.js';

const _v = new THREE.Vector3(), PX = 300, PZ = 300;
const GOODS = [{ id: 'milk', price: 30 }, { id: 'bread', price: 8 }, { id: 'kvas', price: 60 }, { id: 'hp', price: 90, max: 5 }, { id: 'chain', price: 160, max: 3 }];

// ---------- ПАУЧЬЯ МАТКА ----------
class SpiderQueen extends Boss {
  constructor(x, y, z) { super(x, y, z, { name: 'ПАУЧЬЯ МАТКА', hp: 800, r: 2.5, h: 3, mass: 14, solidR: 1.9, aimY: 1.8, goo: 0x9ed63a, bug: true, body: new Spider({ size: 2.3, color: 0x1e1512, color2: 0x7a2a2a }) }); this.waves = 0; }
  *ai() {
    const P = this.P, ph = this.hp / this.maxHp, fast = ph < .4;
    if ((ph < .7 && this.waves < 1) || (ph < .4 && this.waves < 2)) { this.waves++; this.body.play('cast', 1.2); G.audio.sfx('screech'); _v.set(this.pos.x, this.pos.y + 5, this.pos.z); G.fx.text(_v, 'ДЕТИ МОИ!', 'alert'); yield* this.wait(1); this.summon('spiderling', 3 + this.waves, 5); yield* this.wait(.5); }
    const d = this.dist(), r = Math.random();
    if (d < 5.2 && r < .5) { this.body.play('crouch', .8); yield* this.blast(this.pos.x, this.pos.z, 5.4, fast ? .6 : .8, 18, { fxc: 0x8a7a60 }); yield* this.wait(.6, 4); }
    else if (r < .45) { // плевки паутиной
      for (let i = 0; i < (fast ? 5 : 3); i++) { this.body.play('cast', .5); yield* this.wait(.35, 10); const a = this.toP() + rand(-.12, .12), dd = this.dist(), sp = 17, t = Math.max(.3, dd / sp), gr = 5; this.shoot({ x: this.pos.x + Math.sin(a) * 2, z: this.pos.z + Math.cos(a) * 2, y: this.pos.y + 2.2, vx: Math.sin(a) * sp, vz: Math.cos(a) * sp, vy: (P.pos.y + 1 - this.pos.y - 2.2) / t + .5 * gr * t, grav: gr, dmg: 11, kind: 'web', onHit: p => { p.slow = 2.6; G.ui.toast('🕸️ Паутина! Ты замедлен', 'hint'); } }); G.audio.sfx('squish'); }
      yield* this.wait(.5, 5);
    } else if (r < .8 || d > 12) { // прыжок-удар
      this.body.play('crouch', .6); G.audio.sfx('screech'); yield* this.wait(.5, 10); const sx = this.pos.x, sz = this.pos.z; let tx = P.pos.x, tz = P.pos.z; const dc = Math.hypot(tx - PX, tz - PZ); if (dc > 20) { tx = PX + (tx - PX) / dc * 20; tz = PZ + (tz - PZ) / dc * 20; }
      const T = fast ? .85 : 1.05, y0 = this.pos.y; _v.set(tx, y0, tz); G.fx.disc(_v, 5.2, T); this.fly = true; this.solidR = 0; this.invul = true; let t = 0;
      while (t < T) { t += G.dt; const k = Math.min(1, t / T); this.pos.x = lerp(sx, tx, k); this.pos.z = lerp(sz, tz, k); this.pos.y = y0 + Math.sin(k * PI) * 9; yield; }
      this.pos.y = y0; this.fly = false; this.solidR = 1.9; this.invul = false; this.vel.set(0, 0, 0); _v.set(tx, y0, tz); G.fx.ring(_v, 1.5, 6, .4, 0xffb060); G.fx.burst('dust', _v, 18, { s: 2 }); G.audio.sfx('boom'); G.cam.shake(1); this.hitCircle(tx, tz, 5.2, 22, 12);
      this.vul = 1.5; _v.set(tx, y0 + 4.5, tz); G.fx.text(_v, 'ЗАСТРЯЛА!', 'good'); this.body.set('crouch'); yield* this.wait(fast ? 1.7 : 2.3); this.body.set(null); this.vul = 1;
    } else if (fast) { // дождь из паутины
      this.body.play('cast', 1.6); G.audio.sfx('screech'); for (let i = 0; i < 6; i++) { const a = rand(TAU), rr = rand(0, 6); G.run(this.blast(P.pos.x + Math.sin(a) * rr, P.pos.z + Math.cos(a) * rr, 2.6, 1, 12, { fx: 'dust', fxc: 0xffffff, color: 0xffffff, shake: .2, sfx: 'squish' })); yield* this.wait(.22); } yield* this.wait(1, 4);
    }
    yield* this.chase(fast ? 5.2 : 4, rand(.8, 1.8), 4.2);
  }
}

function makeTram() {
  const g = new THREE.Group(), body = new THREE.BoxGeometry(14.4, 2.7, 2.6), roof = new THREE.BoxGeometry(14, .25, 2.3), under = new THREE.BoxGeometry(13, .7, 2.1), front = new THREE.BoxGeometry(.12, 1.1, 2.2);
  for (const x of [-7.6, 7.6]) { const b = new THREE.Mesh(body, M.tram()); b.position.set(x, 2.25, 0); b.castShadow = true; g.add(b); const r = new THREE.Mesh(roof, C(0xdfe3e6, .5)); r.position.set(x, 3.7, 0); g.add(r); const u = new THREE.Mesh(under, M.metalDark()); u.position.set(x, .55, 0); g.add(u); for (const s of [-1, 1]) { const f = new THREE.Mesh(front, C(0x1a2a3a, .1, .7)); f.position.set(x + s * 7.22, 2.55, 0); g.add(f); } }
  const pan = new THREE.Mesh(new THREE.BoxGeometry(2.4, .08, .08), M.metalDark()); pan.position.set(7.6, 4.6, 0); g.add(pan); for (const s of [-1, 1]) { const p = new THREE.Mesh(new THREE.BoxGeometry(.06, 1, .06), M.metalDark()); p.position.set(7.6 + s * .9, 4.15, 0); p.rotation.z = s * .5; g.add(p); }
  return g;
}

LEVELS.milk = {
  id: 'milk', title: 'СЕЛО МОЛОЧНОЕ', sub: 'ГЛАВА 3', music: 'village', weather: 'dust', seed: 31, env: DAY,
  kit: { gear: { phone: 1, spray: 1, chain: 1, ult: 1, kicks: 1, hp: 1 }, money: 120, inv: { doshik: 2, shava: 1 }, flags: { m_boss: 1, m_drun: 1, m_lift: 1 } },
  build(L) {
    const g = G.game, r = L.r, f = k => g.flag(k), TY = 1.3;
    const hfn = (x, z) => {
      let h = TY + Math.sin(x * .05) * .9 + Math.cos(z * .045 + 1) * .8 + Math.sin((x - z) * .11) * .35;
      h = lerp(TY, h, smooth(36, 72, Math.hypot(x + 4, z))); h = lerp(h, TY, (1 - smooth(3.5, 9, Math.abs(z - 30))) * (1 - smooth(60, 70, x)));
      h = lerp(h, TY, 1 - smooth(9, 15, Math.hypot(x + 36, z + 46))); h = lerp(h, TY + .8, 1 - smooth(13, 22, Math.hypot(x - 40, z - 80)));
      h += Math.max(smooth(96, 124, z), smooth(96, 124, -z), smooth(86, 114, -x)) * 13; return lerp(h, -3.6, smooth(58, 100, x));
    };
    const hf = terrain(L, 280, 104, hfn, (x, z, h, ny) => h < -.9 ? 0x9a9a78 : (x > 56 && h < .95) ? 0xdcc88c : ny < .86 ? 0x8a8068 : (Math.abs(z) < 3.2 && x > -66 && x < 58) ? 0x9c8460 : (Math.abs(z - 30) < 2.6 && x < 60) ? 0x8a8478 : (Math.abs(x - 40) < 2 && z > 3 && z < 66) || (Math.abs(x + 36) < 2 && z < -3 && z > -36) ? 0x9c8460 : Math.hypot(x - 40, z - 80) < 15 ? 0x7a7a5a : 0x6f9a3e, { cx: 4, cz: 0 });
    water(L, -1, 600, 180, 0); L.hazard = p => p.y < -2.7 && p.x < 250; L.unsafe = p => p.y < -1.1;
    for (const [x, z, sx, sz] of [[4, -112, 240, 2], [4, 112, 240, 2], [-98, 0, 2, 230], [112, 0, 2, 230]]) barrier(L, x, z, sx, sz, 0, 60);
    // --- трамвайная линия ---
    for (const dz of [-.72, .72]) L.box(M.metal(), -17, TY + .16, 30 + dz, 150, .14, .1, { solid: false }); for (let i = 0; i < 60; i++) L.box(M.planksDark(), -91 + i * 2.5, TY + .06, 30, .3, .12, 2.6, { solid: false });
    for (let i = 0; i < 8; i++) { const x = -88 + i * 20; L.cyl(M.planksDark(), x, TY + 3.2, 33.4, .13, 6.4, { seg: 6, solid: true }); L.box(M.metalDark(), x, TY + 5.6, 31.7, .08, .08, 3.6, { solid: false }); } L.box(M.rubber(), -17, TY + 5.5, 30, 150, .03, .03, { solid: false });
    L.box(M.concrete(), 58.6, TY + .5, 30, .6, 1, 3, {}); L.box(0xd22f2f, 58.5, TY + 1.15, 30, .7, .3, 3.2, { solid: false }); L.sign('КОНЕЦ ПУТИ', 58.2, TY + 2, 30, 2.6, .6, -PI / 2, { bg: '#fff', fg: '#c01818', dbl: 1 });
    L.box(M.concrete(), -70, TY + .2, 26.3, 18, .4, 3.4); L.box(C(0x7fa6c8, .1, .5, { transparent: true, opacity: .4 }), -70, TY + 1.7, 24.75, 6, 2.4, .08); L.box(M.planksLight(), -70, TY + 3, 25.6, 6.6, .12, 2.4, { solid: false }); for (const s of [-1, 1]) L.cyl(M.metalDark(), -70 + s * 3, TY + 1.7, 26.6, .06, 2.7, { seg: 6, solid: true }); bench(L, -70, 25.4, 0, TY + .4);
    L.sign('ПАНСИОНАТ «БЕРЕГОВОЙ»', -70, TY + 3.5, 26.8, 6.4, .7, 0, { bg: '#134a8a', fg: '#fff', dbl: 1 }); L.sign('ТРАМВАЙ № 1 · 1989', -70, TY + 2.5, 24.82, 3.4, .5, 0, { bg: '#f2f2e6', fg: '#134a8a' });
    block(L, -90, -2, 13.6, 40.8, 5, 2, { y: hf(-90, -2) - .5 }); L.sign('БЕРЕГОВОЙ', -83.1, hf(-90, -2) + 16.2, -2, 16, 2.4, PI / 2, { bg: 'none', fg: '#134a8a', stroke: '#fff' });
    const tram = makeTram(); tram.position.set(-58, TY + .2, 30); L.group.add(tram); const tcol = L.world.mover(-58, TY + 2, 30, 30, 4, 2.7);
    // --- село ---
    const HM = [M.logs(), M.brick(), M.planksLight(), M.logs()], RC = [0x8a3a2a, 0x3a6a4a, 0x3a5a8a, 0x6a6a70, 0x9a5a2a];
    [[-46, 11.5, PI], [-30, 12.5, PI], [-12, 11.5, PI], [8, 12.5, PI], [26, 11.5, PI], [-40, -11.5, 0], [-22, -12.5, 0], [-2, -11.5, 0], [16, -12.5, 0], [34, -11.5, 0]].forEach(([x, z, rot], i) => {
      house(L, x, z, 7 + (i % 3), 6, { rot, mat: HM[i % 4], roof: RC[i % 5], y: TY - .1 }); const s = rot ? 1 : -1; fence(L, x - 6, z + s * 4, x + 6, z + s * 4, 1, null, TY); fence(L, x - 6, z + s * 4, x - 6, z - s * 3, 1, null, TY); tree(L, x + 4.6, z + s * 6.5, .8 + r() * .3, i % 2 ? 'cypress' : 'oak'); if (i % 2) bush(L, x - 3, z - s * 4.5, 1.1);
    });
    for (let i = 0; i < 9; i++) { tree(L, -60 + i * 14 + r() * 3, 5.2 + (i % 2) * 1, .9, 'cypress'); } for (const [x, z, k, s] of [[-58, -24, 'oak', 1.3], [-50, -34, 'oak', 1.1], [-14, -30, 'oak', 1.2], [4, -44, 'birch', 1], [12, -60, 'oak', 1.4], [-20, 48, 'oak', 1.2], [-44, 52, 'birch', 1.1], [0, 62, 'oak', 1.3], [16, 46, 'birch', 1], [-66, 60, 'oak', 1.4], [58, -52, 'oak', 1.2], [52, 54, 'cypress', 1.1], [-76, -52, 'oak', 1.5], [-30, 78, 'oak', 1.3], [70, -62, 'cypress', 1]]) tree(L, x, z, s, k);
    for (let i = 0; i < 26; i++) { const a = i / 26 * TAU, x = 4 + Math.sin(a) * (104 + r() * 10), z = Math.cos(a) * (104 + r() * 8); if (x < 70) tree(L, x, z, 1.2 + r() * .8, i % 3 ? 'oak' : 'cypress'); }
    for (let i = 0; i < 16; i++) bush(L, -70 + r() * 120, (r() < .5 ? -1 : 1) * (18 + r() * 60), .8 + r() * .6, i % 3 ? 0x356a2a : 0x4a7a2a);
    grass(L, 5200, () => { const x = -86 + r() * 142, z = -92 + r() * 184, h = hf(x, z); if (h < .9 && x > 50) return null; if (Math.abs(z) < 3.4 || Math.abs(z - 30) < 3 || Math.hypot(x + 36, z + 46) < 9) return null; return [x, h, z]; });
    L.cyl(M.stone(), 3, TY + .45, -4, .9, .9, { seg: 10, solid: true }); L.add(0x7a4a2a, GEO.prism(), 3, TY + 1.9, -4, { s: [2.4, .8, 2.4], color: 0x7a4a2a }); for (const s of [-1, 1]) L.cyl(M.planksDark(), 3 + s * .8, TY + 1.2, -4, .06, 1.5, { seg: 5 });
    L.box(M.planksLight(), -8, TY + .8, 4.4, 2.6, .1, 1.1, { solid: false }); L.box(M.planksDark(), -8, TY + .4, 4.4, 2.4, .8, .9); for (let i = 0; i < 4; i++) L.cyl(M.metal(), -8.9 + i * .6, TY + 1.15, 4.4, .16, .6, { seg: 8 }); L.sign('МОЛОКО', -8, TY + 2.5, 4.9, 2.6, .7, 0, { bg: '#fff', fg: '#134a8a', border: '#134a8a', dbl: 1 }); for (const s of [-1, 1]) L.cyl(M.planksDark(), -8 + s * 1.3, TY + 1.4, 4.9, .05, 2.8, { seg: 5 });
    L.sign('с. МОЛОЧНОЕ', -62, TY + 2.3, 4, 4, .9, PI / 2, { bg: '#fff', fg: '#111', border: '#111', dbl: 1 }); for (const s of [-1, 1]) L.cyl(M.metal(), -62, TY + 1, 4 + s * 1.7, .05, 2, { seg: 5, solid: true });
    // огород Деда
    fence(L, 28, -20, 48, -20, 1.1, null, TY); fence(L, 48, -20, 48, -42, 1.1, null, hf(48, -30)); fence(L, 28, -42, 48, -42, 1.1, null, hf(38, -42)); fence(L, 28, -26, 28, -42, 1.1, null, hf(28, -34));
    for (let i = 0; i < 5; i++) for (let j = 0; j < 3; j++) { const x = 32 + i * 3.2, z = -26 - j * 5; L.box(M.dirt(), x, hf(x, z) + .08, z, 2.2, .3, 4, { solid: false }); for (let k = 0; k < 3; k++) L.sph(M.leaves(k % 2 ? 0x5a9a3a : 0x7aaa4a), x, hf(x, z) + .4, z - 1.3 + k * 1.3, .38, { ico: 0 }); }
    web(L, 38, hf(38, -42) + 1.4, -41.8, 3, 0); web(L, 47.8, hf(48, -30) + 1.3, -32, 2.6, PI / 2);
    // трансформатор
    L.box(M.concrete(), -36, TY + .05, -46, 14, .14, 14, {}); L.box(M.ribs('#7a8088'), -36, TY + 1.75, -55, 4, 3.3, 3); L.sign('ТП-1989\nНЕ ВЛЕЗАЙ — ПАУЧНОСТЬ!', -36, TY + 2.3, -53.45, 2.8, 1.1, 0, { bg: '#ffd21f', fg: '#111', border: '#111' });
    fence(L, -43.5, -38.5, -39, -38.5, 1.6, M.ribs('#5a5f66'), TY); fence(L, -33, -38.5, -28.5, -38.5, 1.6, M.ribs('#5a5f66'), TY); fence(L, -43.5, -38.5, -43.5, -53.5, 1.6, M.ribs('#5a5f66'), TY); fence(L, -28.5, -38.5, -28.5, -53.5, 1.6, M.ribs('#5a5f66'), TY);
    const lampG = glowMat(0xff3030, 2.5), lamp = L.mesh(GEO.sph(), f('k_power') ? glowMat(0x4dff6a, 2.5) : lampG, -36, TY + 3.7, -54, { s: .3 });
    L.box(glowMat(0xffd21f, 2), -41.2, TY + .3, -49, 1.6, .3, .3, { solid: false }); L.box(M.metalDark(), -30.8, TY + .3, -43, 1.6, .3, .3, { solid: false }); L.sign('ВХОД', -42.2, TY + 1, -49, 1.3, .45, PI / 2, { bg: '#111', fg: '#ffd21f', dbl: 1 }); L.sign('ЛИНИЯ', -29.8, TY + 1, -43, 1.5, .45, PI / 2, { bg: '#111', fg: '#ffd21f', dbl: 1 });
    const wp = new WirePuzzle(L, -40, -50, TY + .13, 2, ['ILLI', 'LITL', 'ILLI', 'LTLI'], { solved: !!f('k_power'), sol: [[1, 2, 0, 0], [0, 0, 0, 0], [0, 0, 2, 0], [0, 0, 0, 1]], can: () => f('k_fuse'), onSolve: () => { g.setFlag('k_power'); lamp.material = glowMat(0x4dff6a, 2.5); G.audio.sfx('power'); G.cam.shake(.4); G.ui.toast('⚡ Ток пошёл! Трамвайная линия запитана', 'big'); g.checkpoint('tp', true); g.write(); setGoal(); } });
    L.wp = wp;
    L.interact(-36, TY + 1.2, -53.2, 2.4, 'Вставить предохранитель', () => { if (!inv.has('fuse')) { G.audio.sfx('deny'); return G.ui.toast('Нужен предохранитель. Спроси у Деда в селе.', 'hint'); } inv.take('fuse'); g.setFlag('k_fuse'); G.audio.sfx('lever'); G.ui.toast('🔌 Предохранитель на месте. Теперь поверни плитки так, чтобы ток дошёл от «ВХОД» до «ЛИНИЯ»', 'big'); setGoal(); }, { cond: () => !f('k_fuse') && !f('k_power') });
    // гнездо
    for (let i = 0; i < 7; i++) { const a = i / 7 * TAU + .3, x = 40 + Math.sin(a) * 13, z = 80 + Math.cos(a) * 13; tree(L, x, z, 1 + r() * .4, 'bare'); if (i % 2) web(L, 40 + Math.sin(a + .4) * 12.5, hf(x, z) + 3, 80 + Math.cos(a + .4) * 12.5, 5, a + .4 + PI / 2); }
    for (let i = 0; i < 9; i++) { const x = 34 + r() * 12, z = 75 + r() * 11; L.sph(C(0xe8e4d8, .6), x, hf(x, z) + .35, z, 1, { s: [.4, .55, .4] }); } for (const [x, z] of [[36, 88], [45, 76], [33, 79]]) L.sph(C(0xdad6c8, .8), x, hf(x, z) + 1.1, z, 1, { s: [.7, 1.5, .7] });
    L.sign('ГНЕЗДО\nНЕ ХОДИ', 40, hf(40, 64) + 1.5, 64, 2, 1, PI, { bg: '#5a3a22', fg: '#ffe9a8', dbl: 1 }); L.cyl(M.planksDark(), 40, hf(40, 64) + .6, 64, .07, 1.4, { seg: 5, solid: true });
    // пляж
    L.box(M.planks(), 87, .2, -24, 26, .3, 3.2); L.ramp(M.planks(), 71.5, -24, 3.2, 5.2, hf(68.9, -24) - .25, .35, { rot: PI / 2 }); for (let i = 0; i < 6; i++) for (const s of [-1, 1]) L.cyl(M.planksDark(), 76 + i * 4.6, -1.2, -24 + s * 1.5, .14, 3.4, { seg: 6 });
    for (const [x, z, c] of [[66, -8, 0xd22f2f], [68, 6, 0x2a6ad0], [66, 18, 0xffc530], [70, -40, 0x2a8a4a], [67, 44, 0xff7ab0]]) { const y = hf(x, z); L.cyl(M.white(), x, y + 1.2, z, .05, 2.4, { seg: 5, solid: true }); L.cone(c, x, y + 2.5, z, 1.7, .7, { seg: 10, gloss: 1 }); L.box(M.planksLight(), x + 1.6, y + .3, z, .8, .12, 2, { rot: .2 }); }
    L.sign('ПЛЯЖ', 60, hf(60, 4) + 3.2, 4, 5, 1.2, -PI / 2, { bg: '#134a8a', fg: '#ffe9a8', dbl: 1 }); for (const s of [-1, 1]) L.cyl(M.planksLight(), 60, hf(60, 4) + 1.6, 4 + s * 2.4, .1, 3.2, { seg: 6, solid: true });
    // --- Паучья яма (отдельная арена) ---
    L.cyl(M.dirt(), PX, -.25, PZ, 27, .5, { seg: 28, solid: true }); for (let i = 0; i < 22; i++) { const a = i / 22 * TAU, x = PX + Math.sin(a) * 27.5, z = PZ + Math.cos(a) * 27.5, h = 13 + (i % 3) * 2; L.box(i % 2 ? M.stone() : M.dirt(), x, h / 2 - 1, z, 8.6, h, 4 + (i % 2), { rot: a }); if (i % 3 === 0) web(L, PX + Math.sin(a) * 25.2, 3 + (i % 2) * 2, PZ + Math.cos(a) * 25.2, 7, a + PI); }
    L.box(M.tram(), PX - 15, 1.2, PZ - 14, 14, 2.7, 2.6, { rot: .5, fit: 1 }); L.box(0xdfe3e6, PX - 15, 2.65, PZ - 14, 13.6, .2, 2.3, { rot: .5, solid: false });
    for (let i = 0; i < 14; i++) { const a = r() * TAU, d = 16 + r() * 8, x = PX + Math.sin(a) * d, z = PZ + Math.cos(a) * d; L.sph(C(0xe8e4d8, .6), x, .4, z, 1, { s: [.45, .62, .45] }); } for (const [dx, dz, c] of [[-18, 6, 0x9dff7a], [17, -9, 0x9dff7a], [4, 20, 0xffb060]]) { L.sph(glowMat(c, 2), PX + dx, .5, PZ + dz, .35); L.glow(PX + dx, .7, PZ + dz, 3, c, .5); L.lamp(PX + dx, 1.4, PZ + dz, c, 30, 16); }
    // --- точки ---
    L.cps = { start: [-72, TY + .4, 26.3, PI / 2], tp: [-36, TY + .2, -36, PI], pit: [PX, 0, PZ + 17, PI], out: [-66, TY + .4, 26.3, PI / 2] };
    const stop = [-66, TY + 1.6, 26.4], dedP = [30, TY + 1.2, -6.5], garden = { n: 0 };
    function setGoal() {
      if (f('k_boss')) return g.goal('Кнопка «М» у тебя! Вернись в Мурино — поговори с кондукторшей', ...stop); if (f('k_ride')) return g.goal('Победи Паучью Матку'); if (!f('k_talk')) return g.goal('Поговори с кондукторшей на остановке', ...stop);
      const pw = f('k_power'), cr = inv.has('crank'); if (pw && cr) return g.goal('Всё готово! Отнеси ручку кондукторше', ...stop);
      if (!pw) { if (f('k_fuse')) return g.goal('Поверни плитки: проведи ток от «ВХОД» к «ЛИНИЯ»', -36, TY + 1, -46); if (inv.has('fuse')) return g.goal('Вставь предохранитель в трансформатор ТП-1989', -36, TY + 1.2, -53); if (!f('k_ded')) return g.goal('Найди Деда в селе: у него есть предохранитель', ...dedP); return f('k_garden') ? g.goal('Огород чист. Вернись к Деду', ...dedP) : g.goal(`Выгони паучностей с огорода Деда (${garden.n}/5)`, 38, hf(38, -32) + 1, -32); }
      g.goal('Найди ручку контроллера в паучьем гнезде на севере', 40, hf(40, 80) + 1, 80);
    }
    // --- NPC ---
    const kon = { n: 'Кондукторша', e: '👩‍✈️' }, ded = { n: 'Дед', e: '👴' }, bab = { n: 'Молочница', e: '🥛' }, ryb = { n: 'Рыбак', e: '🎣' };
    const kn = g.spawn(new NPC(stop[0], TY + .4, stop[2], { name: 'Кондукторша', yaw: PI, mark: '!', look: { face: faceTex({ mood: 'smile', skin: '#e8b8a0', blush: 1 }), top: 0x134a8a, sleeve: 'long', pants: 0x1a2a44, hair: 0xa84a2a, hairStyle: 'fringe', skin: 0xe8b8a0 }, *talk(n) {
      if (f('k_boss')) { yield* lines([[kon, 'Живой! А трамвай… ну, трамвай в яме. Зато есть второй вагон. До Мурино довезу.']]); const c = yield* G.ui.choose(['Поехали в Мурино', 'Ещё погуляю']); if (c === 0) { G.audio.sfx('tram'); g.travel('murino', 'station'); } return; }
      if (!f('k_talk')) { yield* lines([[kon, 'Трамвай не идёт, милок. С восемьдесят девятого ходил, а теперь — паучности.'], [kon, 'Провода обесточили: в трансформаторе предохранитель сгорел. И ручку контроллера утащили в гнездо, на север.'], ['ch', 'А кнопку от ливта тут не видели? Красную такую.'], [kon, 'Кнопку Матка унесла. В Паучью яму. Туда только трамваем и доедешь… кхм. В общем: ток и ручка. Предохранитель спроси у Деда, он в конце села живёт.']]); g.setFlag('k_talk'); n.setMark(null); return setGoal(); }
      if (f('k_power') && inv.has('crank')) return yield* ride();
      yield* lines([[kon, f('k_power') ? 'Ток есть! Теперь ручку бы… Гнездо на севере, за табличкой «НЕ ХОДИ».' : inv.has('crank') ? 'Ручка есть, а тока нет. Трансформатор на юго-западе, за селом.' : 'Ток и ручка, милок. Ток — у трансформатора, ручка — в гнезде.']]);
    } }));
    const dn = g.spawn(new NPC(dedP[0], TY, dedP[2], { name: 'Дед', yaw: 0, mark: f('k_fuse') || f('k_power') || inv.has('fuse') ? null : '!', look: { face: faceTex({ mood: 'tired', skin: '#d8a888', stache: '#ddd' }), top: 0x5a6a4a, sleeve: 'long', pants: 0x3a3a34, hair: 0xdddddd, hairStyle: 'cap', capColor: 0x4a4a40, skin: 0xd8a888, beard: 0xdddddd }, *talk(n) {
      if (f('k_fuse') || f('k_power') || inv.has('fuse')) return yield* lines([[ded, 'Раньше паучности были мельче. И трамвай ходил. И молоко было молочнее.']]);
      if (!f('k_ded')) { yield* lines([[ded, 'Предохранитель? Есть. В сарае лежит, с восемьдесят девятого.'], [ded, 'Только у меня на огороде паучности капусту жрут. Пять штук. Выгонишь — отдам.']]); g.setFlag('k_ded'); for (const e of G.ents) if (e.tag === 'garden' && e.state === 'idle') e.c.aggro = 18; return setGoal(); }
      if (!f('k_garden')) return yield* lines([[ded, `Огород — за домом. Осталось паучностей: ${5 - garden.n}. Дихлофосом их, дихлофосом!`]]);
      yield* lines([[ded, 'Чисто! Вот это по-нашему. Держи предохранитель. И молока возьми — с собой.']]); inv.add('fuse'); inv.add('milk', 2); n.setMark(null); setGoal();
    } }));
    g.spawn(new NPC(-8, TY, 3.2, { name: 'Молочница', yaw: PI, mark: '?', label: 'Купить', look: { face: faceTex({ mood: 'happy', skin: '#e8b8a0', blush: 1 }), top: 0xf2f2f2, sleeve: 'short', pants: 0x7a3a3a, style: 'robe', hair: 0xf2f2f2, hairStyle: 'fringe', fat: 1.3, skin: 0xe8b8a0 }, *talk() { yield* lines([[bab, 'Молочко! Парное! Паучности не трогали — честное слово.']]); yield* G.ui.shop('МОЛОКО И ВКУСНОСТИ', GOODS, 'Сколько-сколько?'); } }));
    g.spawn(new NPC(96, .35, -24, { name: 'Рыбак', yaw: PI / 2, still: true, look: { face: faceTex({ mood: 'smile', skin: '#c89070' }), top: 0x3a5a4a, sleeve: 'long', pants: 0x3a3a34, hairStyle: 'cap', capColor: 0x6a7a4a, skin: 0xc89070 }, *talk() { yield* lines([[ryb, 'Тсс. Клюёт. Вчера паучность вытащил — на полтора метра. Отпустил: жалко.'], [ryb, 'Если к Матке пойдёшь — когда прыгнет и застрянет лапами, вот тогда и бей.']]); } }));
    // --- поездка в яму ---
    function* ride() {
      yield* lines([[kon, 'Ручка! И ток есть! Ну, с богом. Садись. Только держись — перед пляжем путь… немного кончается.'], ['ch', 'Что значит «кончается»?!']]);
      G.mode = 'cut'; yield* G.ui.fadeTo(1, .4); inv.take('crank'); G.player.hidden = true; kn.root.visible = false; tcol.off = true; G.audio.sfx('tram'); G.audio.music('boss');
      const sp = []; for (let i = 0; i < 4; i++) { const s = new Spider({ size: .7 + i * .12 }); s.root.rotation.y = PI / 2; L.group.add(s.root); sp.push(s); }
      let x = -58, v = 0, t = 0; yield* G.ui.fadeTo(0, .4);
      while (x < 46) { const dt = G.dt; t += dt; v = Math.min(22, v + 6 * dt); x += v * dt; tram.position.x = x; tram.position.y = TY + .2 + Math.sin(t * 22) * .02; sp.forEach((s, i) => { s.root.position.set(x - 20 - i * 3.5 + Math.sin(t * 2 + i) * 1.5, TY, 30 + (i % 2 ? 3.4 : -3.4) + Math.sin(t * 3 + i * 2) * 1.2); s.update(dt, 9, 0); }); G.player.place(x, TY + .2, 30); G.cam.shot(x + 13 - t * 1.2, TY + 5.5, 30 + 13, x - 3, TY + 2, 30, t < .1, 4); if (t > 2.5 && t < 2.6) G.ui.toast('🕷️ Паучности гонятся за трамваем!', 'hint'); yield; }
      G.cam.shake(1.2); G.audio.sfx('boom'); G.ui.setFade(1); for (const s of sp) s.dispose(); tram.visible = false; yield* wait(.8);
      g.setFlag('k_ride'); G.player.hidden = false; G.player.place(PX, 0, PZ + 17, PI); G.cam.snap(); g.checkpoint('pit', true); g.write(); yield* wait(.4); yield* G.ui.fadeTo(0, .6); yield* bossIntro();
    }
    function* bossIntro() {
      if (!boss || boss.active) return; G.mode = 'cut'; G.audio.music('boss'); G.cam.shot(PX + 5, 3, PZ + 9, PX, 2.5, PZ - 6, false, 2.2); yield* wait(.8); boss.body.play('cast', 1.4); G.audio.sfx('screech'); G.cam.shake(.9); G.ui.bigTitle('ПАУЧЬЯ МАТКА', 'БОСС', 2500); yield* wait(1.6);
      yield* lines([['ch', 'Так вот ты какая, Паучья яма… Посидим? Нет? Ну ам-ам-ам тогда.']]); boss.start(); setGoal(); tip('Когда Матка прыгнет и застрянет — бей! Дихлофос (Q) по ней тоже работает', 'Когда Матка прыгнет и застрянет — бей! Дихлофос 🧴 тоже работает');
    }
    // --- предметы и враги ---
    if (!inv.has('crank') && !f('k_ride')) g.spawn(new Crate(43, hf(43, 85), 85, { s: 1, item: 'crank', fid: 'milk.crc', ifid: 'milk.crank' }));
    crates(L, [[-50, 4, TY], [-26, -6, TY], [12, 5, TY], [44, -8, TY], [-34, -40.5, TY + .14], [64, 12, hf(64, 12)], [70, -30, hf(70, -30)], [-60, 44, hf(-60, 44)], [22, 60, hf(22, 60)], [-10, -70, hf(-10, -70)], [36, 74, hf(36, 74)]], Crate);
    g.item('hp', 98.5, .7, -24, 'milk.hp'); g.cash(20, -76, hf(-76, -52) + .4, -50, 'milk.c1'); g.cash(20, 52, hf(52, 56) + .4, 56, 'milk.c2'); g.item('plums', 3, TY + 1.5, -4, 'milk.pl'); g.cash(20, 72, hf(72, 44) + .4, 44, 'milk.c3'); g.item('kvas', PX + 20, .4, PZ + 4, 'milk.kv');
    const E = (k, x, z, o) => g.spawn(new Enemy(k, x, hf(x, z) > -50 ? hf(x, z) : 0, z, o));
    if (!f('k_boss')) {
      if (!f('k_garden')) [[33, -27], [39, -30], [44, -35], [35, -38], [42, -26]].forEach(([x, z]) => { E('spider', x, z, { aggro: f('k_ded') ? 18 : 9 }).tag = 'garden'; });
      E('spider', -20, 40); E('spider', 20, 50); E('spitter', 62, -20); E('spider', -50, -60); E('spitter', 37, 78); E('spitter', 44, 82); E('spider', 40, 72); E('spider', 34, 84); E('spiderling', 46, 78); E('spiderling', 38, 86); E('spider', -70, -20);
    }
    L.onKill = e => { if (e.tag !== 'garden' || f('k_garden')) return; garden.n++; if (garden.n >= 5) { g.setFlag('k_garden'); G.ui.toast('🥬 Огород свободен!', 'big'); dn.setMark('!'); } setGoal(); };
    // --- босс ---
    let boss = null;
    if (!f('k_boss')) {
      boss = g.spawn(new SpiderQueen(PX, 0, PZ - 8)); boss.yaw = 0; boss.sync(); boss.fade = true;
      boss.onDefeat = () => { g.setFlag('k_boss'); inv.add('btn1'); g.pay(100); G.audio.music('village'); G.audio.sfx('win'); g.checkpoint('pit', true); g.write(); setGoal(); g.script(function* () { yield* lines([['ch', 'Кнопка «М»! Липкая… Одна есть. Вылезаю отсюда по паутине.']]); }); };
    }
    L.interact(PX, 1.2, PZ + 24.6, 3, 'Вылезти по паутине', () => g.script(function* () { yield* G.ui.fadeTo(1, .4); G.player.place(-66, TY + .4, 23.5, 0); G.cam.snap(); kn.root.visible = true; g.checkpoint('out', true); yield* wait(.4); yield* G.ui.fadeTo(0, .4); }), { cond: () => f('k_boss') }); web(L, PX, 5, PZ + 25, 9, PI);
    if (f('k_ride')) { tram.visible = false; tcol.off = true; }
    L.start = function* (cp) { setGoal(); if (cp === 'pit' && boss) { yield* wait(.6); g.script(bossIntro, 'cut'); } else if (!f('k_talk')) { yield* wait(1); tip('Село Молочное. Паучности не любят дихлофос — зажми Q', 'Село Молочное. Паучности не любят дихлофос — держи 🧴'); } };
  },
};
