// ГЛАВА 2 — МУРИНО: двор-хаб, курьеры, гигахрущёвка П-46, Тёмный Друн, станция «поеза»
import * as THREE from 'three';
import { G, wait, rand, PI, TAU, dampAng } from '../g.js';
import { LEVELS } from '../game.js';
import { GEO } from '../level.js';
import { M, C, glowMat, faceTex, photoTex } from '../tex.js';
import { wall, door, ceilLamp, lampPost, crates, at, block, car, bench, bin, tree, garage, kiosk, fence, barrier } from '../kit.js';
import { NPC, Enemy, Crate } from '../actors.js';
import { Boss } from '../bosses.js';
import { makeHuman } from '../rig.js';
import { inv } from '../items.js';
import { FACE } from '../faces.js';
import { lines, tip } from '../script.js';
import { NIGHT } from './murino_env.js';

const RY = 90.4, _v = new THREE.Vector3();
const GOODS = [{ id: 'shava', price: 45 }, { id: 'doshik', price: 20 }, { id: 'plums', price: 35 }, { id: 'energy', price: 25 }, { id: 'hp', price: 90, max: 4 }, { id: 'chain', price: 160, max: 3 }];
export const DRUN_LOOK = { face: photoTex(FACE.drun), top: 0x2a8a4a, sleeve: 'long', hairStyle: 'hood', pants: 0x333a55, shoes: 0xf0f0f0 };

// ---------- ТЁМНЫЙ ДРУН ----------
class DarkDrun extends Boss {
  constructor(x, y, z) { super(x, y, z, { name: 'ТЁМНЫЙ ДРУН', hp: 700, r: .6, h: 2.4, mass: 5, solidR: .5, guard: .45, body: makeHuman({ face: photoTex(FACE.dark), top: 0x121214, style: 'puffer', sleeve: 'long', hairStyle: 'hood', pants: 0x0c0c0e, shoes: 0x111111, scale: 1.28, skin: 0x8a6a60 }) }); this.p2 = false; this.cx = x; this.cz = z; }
  // после серии на миг открывается
  *tired(t = 1.2) { this.vul = 1.5; _v.set(this.pos.x, this.pos.y + 3.3, this.pos.z); G.fx.text(_v, 'ОТКРЫЛСЯ!', 'good'); this.body.set('crouch'); yield* this.wait(t); this.body.set(null); this.vul = 1; }
  *strike(anim, r, dmg, knock = 8) { this.body.play(anim, anim === 'kick' ? .5 : .32); G.audio.sfx('whoosh'); yield* this.wait(anim === 'kick' ? .2 : .11); const a = this.yaw, x = this.pos.x + Math.sin(a) * 1.3, z = this.pos.z + Math.cos(a) * 1.3; if (Math.abs(this.P.pos.y - this.pos.y) < 2) this.hitCircle(x, z, r, dmg, knock); yield* this.wait(anim === 'kick' ? .3 : .2); }
  *ai() {
    const P = this.P, ph = this.hp / this.maxHp;
    if (ph < .5 && !this.p2) {
      this.p2 = true; this.invul = true; _v.copy(this.pos); _v.y += 1.5; G.fx.burst('magic', _v, 20, { color: 0x6a3aff, s: 2 }); this.pos.x = this.cx; this.pos.z = this.cz; this.body.play('cast', 1.4); G.audio.sfx('roar'); _v.set(this.pos.x, this.pos.y + 3.4, this.pos.z); G.fx.text(_v, 'ТЁМНЫЙ ХАМАМ!', 'alert'); yield* this.wait(1.2);
      for (let i = 0; i < 3; i++) { G.run(this.shockwave(this.pos.x, this.pos.z, 32, 2.3, 12)); G.cam.shake(.6); this.body.play('slam', .5); yield* this.wait(1.05); }
      this.invul = false; this.summon('slime', 2, 5); yield* this.wait(.6, 6); return;
    }
    const r = Math.random();
    if (r < .38) { // рывок + серия
      this.body.play('crouch', .55); this.body.flash(.6); yield* this.wait(.55, 10); const a = this.toP(); let t = .42; this.yaw = a; G.audio.sfx('whoosh');
      while (t > 0 && this.dist() > 1.7) { t -= G.dt; this.vel.x = Math.sin(a) * 15; this.vel.z = Math.cos(a) * 15; this.speed = 15; if (Math.random() < .6) { _v.copy(this.pos); _v.y += 1.2; G.fx.trail(_v, 0x6a3aff, .8); } yield; }
      this.speed = 0; yield* this.strike('punchR', 2.1, 10); this.yaw = this.toP(); yield* this.strike('punchL', 2.1, 10); if (this.p2) { this.yaw = this.toP(); yield* this.strike('kick', 2.4, 14, 12); } yield* this.tired(this.p2 ? 1.1 : 1.4);
    } else if (r < .68) { // шаг сквозь тень
      _v.copy(this.pos); _v.y += 1.3; G.fx.burst('smoke', _v, 12, { color: 0x1a1024 }); G.audio.sfx('zap'); const a = P.yaw + PI, w = G.level.world, tx = P.pos.x + Math.sin(a) * 2.4, tz = P.pos.z + Math.cos(a) * 2.4;
      if (!w.inside(tx, P.pos.y + 1, tz) && Math.abs(tx) < 21 && tz > 55.5 && tz < 78) { this.pos.x = tx; this.pos.z = tz; } this.yaw = this.toP(); _v.copy(this.pos); _v.y += 1.3; G.fx.burst('smoke', _v, 12, { color: 0x1a1024 }); this.body.flash(1); this.body.play('crouch', .5);
      yield* this.wait(.62, 14); yield* this.strike('kick', 2.5, 15, 12); yield* this.tired(1.3);
    } else { // веер тёмных котлет
      yield* this.chase(4, .8, 7); for (let k = 0; k < (this.p2 ? 2 : 1); k++) { this.body.play('throw', .4); yield* this.wait(.2, 12); const a = this.toP(); for (let i = -2; i <= 2; i++) this.shoot({ vx: Math.sin(a + i * .2) * 12, vy: 0, vz: Math.cos(a + i * .2) * 12, y: this.pos.y + 1.5, dmg: 8, kind: 'orb', color: 0x8a4aff, r: .28, life: 3 }); G.audio.sfx('throw'); yield* this.wait(.45, 6); } yield* this.wait(.6, 5);
    }
    yield* this.chase(4.2, rand(.5, 1.3), 3);
  }
}

LEVELS.murino = {
  id: 'murino', title: 'МУРИНО', sub: 'ГЛАВА 2', music: 'murino', weather: 'rain', seed: 21, env: NIGHT,
  kit: { gear: { phone: 1, spray: 1, chain: 1 }, money: 60, inv: { doshik: 2 }, flags: { dorm_boss: 1 } },
  build(L) {
    const g = G.game, r = L.r, f = k => g.flag(k);
    L.box(M.asphalt(.6), 0, -.25, 0, 330, .5, 330); L.box(M.pavers(), 0, .02, 0, 44, .1, 44); L.box(M.grass(), -32, .02, -14, 14, .12, 26); L.box(M.grass(), 32, .02, 8, 12, .12, 20); L.box(M.dirt(), 0, .03, -56, 64, .1, 7, { solid: false });
    for (const [x, z, sx, sz] of [[0, -72, 146, 2], [-72, 0, 2, 146], [72, 0, 2, 146], [0, 81, 146, 2]]) barrier(L, x, z, sx, sz);
    // --- дома по периметру ---
    block(L, -82, -34, 13.6, 54.4, 18, 1); block(L, -82, 38, 13.6, 54.4, 24, 0); block(L, 86, -40, 13.6, 68, 16, 2); block(L, 86, 36, 13.6, 54.4, 22, 1); block(L, -34, -84, 68, 13.6, 14, 0, { doors: 0 }); block(L, 40.8, -84, 54.4, 13.6, 20, 2);
    block(L, -61.2, 66.8, 27.2, 27.2, 12, 2); block(L, 61.2, 66.8, 27.2, 27.2, 9, 0);
    const far = [[-150, -60, 60], [-140, 60, 90], [150, -90, 70], [160, 40, 110], [-40, -160, 80], [70, -170, 50], [-120, -150, 100], [140, 150, 60], [-150, 150, 75], [0, 190, 120], [-90, 200, 60], [100, 210, 95], [210, -30, 85], [-210, 0, 105]];
    far.forEach(([x, z, fl], i) => block(L, x, z, i % 2 ? 34 : 54.4, i % 2 ? 54.4 : 27.2, fl, i % 4, { far: 1, solid: false }));
    // --- П-46 ---
    const F = M.facade(3); L.box(F, -27.2, 45, 66.8, 40.8, 90, 27.2); L.box(F, 27.2, 45, 66.8, 40.8, 90, 27.2); L.box(F, 0, 48, 66.8, 13.6, 84, 27.2); L.box(M.concDark(), 0, 90.2, 66.8, 96, .4, 28);
    L.sign('П-46', 0, 9.5, 53.05, 9, 3, 0, { bg: 'none', fg: '#ff5a5a', glow: 2.2, stroke: '#300' }); L.sign('ЭТАЖЕЙ: 200 000 · ЛИВТ РАБОТАЕТ (НЕТ)', 0, 6.6, 53.05, 12, .8, 0, { bg: '#1a1a1a', fg: '#ffd21f', glow: 1.2 });
    const LW = M.wall2('#5a6a8a'); wall(L, M.concrete(), -6.8, 53.2, 6.8, 53.2, 0, 6, .4, [[6.8, 2.2, 2.6]]); wall(L, LW, -6.8, 64, 6.8, 64, 0, 6, .4); wall(L, LW, -6.62, 53.4, -6.62, 63.8, 0, 6, .14); wall(L, LW, 6.62, 53.4, 6.62, 63.8, 0, 6, .14);
    L.box(M.bigTiles(), 0, .04, 58.6, 13.2, .1, 10.6); L.box(M.ceil(), 0, 5.9, 58.6, 13.2, .2, 10.6); ceilLamp(L, 0, 5.8, 58, 0xd8e6ff, 30, 14, { flicker: 1 }); ceilLamp(L, 0, 5.8, 62, 0xfff0d0, 26, 12);
    for (const s of [-1, 1]) L.box(M.metal(), s * .78, 1.4, 63.74, 1.5, 2.6, .1, { solid: false }); L.box(M.metalDark(), 0, 1.4, 63.76, 3.3, 2.9, .06, { solid: false }); L.box(glowMat(0xff3030, 2), 2.1, 1.4, 63.72, .22, .34, .06, { solid: false }); L.sign('ЛИВТ', 0, 3.4, 63.75, 1.6, .5, PI, { bg: '#101a10', fg: '#7dff8a', glow: 1.6 });
    for (let i = 0; i < 6; i++) L.box(0x3a5a7a, -6.4, 1.2 + (i % 3) * .5, 55 + (i / 3 | 0) * 1.2, .2, .4, 1, { solid: false, gloss: 1 }); L.sign('КВ. 1 — 4 000 000', -6.5, 2.9, 55.6, 2.2, .4, PI / 2, { bg: '#e8e2c8', fg: '#222' }); L.box(M.planksDark(), 5, .55, 60.5, 2, 1.1, .8); L.sign('КОНСЬЕРЖ\nУШЁЛ В ТУМАН', 5, 2.2, 63.75, 1.8, .8, PI, { bg: '#f2e6a0', fg: '#a01818' });
    const pd = door(L, 0, 0, 53.2, 0, { w: 2.2, h: 2.6, mat: M.metalDark(), label: 'Открыть «пезд»', locked: () => inv.has('pass') ? '' : 'Домофон: «Предъявите пропуск в пезд»' }); if (f('m_lift')) pd.setOpen(true, true);
    L.box(M.concrete(), 0, 2.9, 51.6, 5, .25, 3.4, { solid: false }); for (const s of [-1, 1]) L.cyl(M.metalDark(), s * 2.2, 1.4, 50.2, .08, 2.8, { solid: true, seg: 6 }); L.lamp(0, 2.4, 51.5, 0xfff0c0, 24, 12); L.box(glowMat(0xfff0c0, 2), 0, 2.74, 51.6, .7, .06, .7, { solid: false });
    // --- крыша ---
    for (const [x, z, sx, sz] of [[0, 54.3, 46, .4], [0, 79.3, 46, .4], [-22.4, 66.8, .4, 26], [22.4, 66.8, .4, 26]]) L.world.box(x, RY + 12, z, sx, 26, sz, 0, { nocam: true });
    for (const z of [53.5, 80.1]) L.box(M.concDark(), 0, RY + .5, z, 95, 1, .5, { solid: false }); for (const x of [-47.4, 47.4]) L.box(M.concDark(), x, RY + .5, 66.8, .5, 1, 27, { solid: false });
    for (const s of [-1, 1]) { L.box(M.ribs('#5a5f66'), s * 26, RY + 1.2, 60, 5, 2.4, 4, { solid: false }); L.box(M.ribs('#5a5f66'), s * 31, RY + .9, 73, 3.4, 1.8, 3.4, { solid: false }); L.cyl(M.metalDark(), s * 24.5, RY + 5, 76, .12, 10, { seg: 6 }); L.sph(glowMat(0xff2020, 3), s * 24.5, RY + 10.1, 76, .22); L.glow(s * 24.5, RY + 10.1, 76, 4, 0xff3030, .6); L.cyl(M.metal(), s * 36, RY + 1.6, 64, 1.6, 3.2, { seg: 12 }); lampPost(L, s * 20.5, 78, RY, 0xbfd0ff, 5, s > 0 ? PI : 0); }
    L.box(M.brick(), 0, RY + 1.7, 77.6, 5, 3.4, 2.6); L.box(M.metal(), 0, RY + 1.25, 76.27, 1.6, 2.5, .08, { solid: false }); L.sign('ЛИВТ', 0, RY + 2.95, 76.25, 1.4, .45, PI, { bg: '#101a10', fg: '#7dff8a', glow: 1.6 }); L.lamp(0, RY + 2.6, 75.2, 0x9dff9a, 22, 12);
    L.sign('МУРИНО', 0, RY + 3.2, 54.6, 17, 3.6, 0, { bg: 'none', fg: '#7fe0ff', glow: 2.4, stroke: '#04283a' }); L.lamp(-8, RY + 2.5, 56, 0x7fe0ff, 40, 20); L.lamp(8, RY + 2.5, 56, 0x7fe0ff, 40, 20);
    for (let i = 0; i < 5; i++) L.box(C(0x3a4a66, .05, .6, { transparent: true, opacity: .5 }), -14 + i * 7 + r() * 2, RY + .012, 60 + r() * 14, 2 + r() * 2, .02, 1.5 + r() * 2, { solid: false });
    // --- двор ---
    for (const [x, z] of [[-18, -18], [18, -18], [-18, 18], [18, 18]]) lampPost(L, x, z, .07, 0xffc98a, 6.2, x > 0 ? PI : 0);
    for (const [x, z, rot] of [[-52, 0, 0], [-40, 24, PI / 2], [44, -6, PI], [46, 30, PI], [-10, 44, PI / 2], [10, 44, -PI / 2], [-40, -44, 0], [36, -44, PI]]) lampPost(L, x, z, 0, r() < .3 ? 0x9fd0ff : 0xffc98a, 6.2, rot);
    L.box(0x2a6ad0, -6, 1.4, -6, 2.2, .14, 2.2, { gloss: 1 }); for (const [dx, dz] of [[-1, -1], [1, -1], [-1, 1], [1, 1]]) L.cyl(0xd22f2f, -6 + dx, .7, -6 + dz, .07, 1.4, { seg: 6, gloss: 1 }); L.ramp(0xffc530, -6, -9.2, 1.4, 4.2, 0, 1.47, { rot: 0, gloss: 1, th: .12 }); L.stairs(0xd22f2f, -3.9, -6, 1.2, 2, 1.47, 0, { rot: PI / 2, gloss: 1 });
    L.box(M.planks(), 7, .2, -7, 4, .4, 4, { solid: false }); L.box(M.sand(), 7, .32, -7, 3.6, .2, 3.6, { solid: false }); for (const s of [-1, 1]) { L.cyl(0x2a8a4a, 7 + s * 1.6, 1.3, 6, .07, 2.6, { seg: 6, gloss: 1, solid: true }); } L.box(0x2a8a4a, 7, 2.6, 6, 3.4, .1, .1, { solid: false, gloss: 1 }); for (const s of [-.6, .6]) { L.box(M.metalDark(), 7 + s, 1.6, 6, .03, 2, .03, { solid: false }); L.box(M.planks(), 7 + s, .6, 6, .5, .06, .3, { solid: false }); }
    L.cyl(0xd22f2f, -7, .35, 8, 1.5, .12, { seg: 12, gloss: 1 }); L.cyl(M.metalDark(), -7, .4, 8, .1, .8, { seg: 6, solid: true });
    bench(L, -14, 0, PI / 2, .07); bench(L, 14, 0, -PI / 2, .07); bench(L, 0, 15, PI, .07); bench(L, 0, -15, 0, .07); bin(L, -14, 2, .07); bin(L, 14, -2, .07); bin(L, -22, 17.5);
    for (const [x, z, s, k] of [[-12, -12, 1, 'bare'], [12, 12, 1.1, 'autumn'], [-13, 12, .9, 'autumn'], [13, -12, 1, 'bare'], [-30, -20, 1.2, 'autumn'], [-34, -8, 1, 'bare'], [-29, -4, 1.1, 'autumn'], [30, 4, 1, 'autumn'], [34, 14, 1.2, 'bare'], [31, 0, .9, 'autumn']]) tree(L, x, z, s, k, .1);
    const cc = [0xb02a2a, 0x2a5ab0, 0xd8d8d8, 0x1a1a1e, 0x2a8a4a, 0xc9a020, 0x7a7f88]; [[-26, -30, 0], [-22.6, -30, 0], [-19.2, -30, PI], [26, -30, 0], [22.6, -30, PI], [-46, 14, PI / 2], [-46, 18, PI / 2], [48, 6, PI / 2], [48, 10.5, -PI / 2], [20, 36, PI / 2], [-20, 36, PI / 2]].forEach(([x, z, rot], i) => car(L, x, z, rot + (r() - .5) * .1, cc[i % cc.length]));
    kiosk(L, -24, 22, PI, 'ШАВЕРМА У АШОТА', 0xd22f2f, 0xffd23a); L.box(0xf2f2ee, 28, 2.2, 32, 14, 4.4, 8, { gloss: 1 }); L.sign('ПРОДУКТЫ 24', 28, 5.2, 27.95, 9, 1.4, PI, { bg: '#0d2a14', fg: '#7dff8a', glow: 2 }); L.box(glowMat(0xfff2d0, 1.2), 28, 1.7, 27.96, 9, 2.2, .06, { solid: false }); L.lamp(28, 2.6, 26.4, 0xbfffd0, 40, 16);
    L.sign('ВКУСНОСТИ', -75.1, 14, -30, 16, 3.4, PI / 2, { bg: 'none', fg: '#ff6fd8', glow: 2.2, stroke: '#30062a' }); L.sign('ЖК «ТУМАННЫЙ»', 79.1, 16, 30, 20, 3.4, -PI / 2, { bg: 'none', fg: '#ffd23a', glow: 2, stroke: '#302000' }); L.sign('МУРИНО — ЭТО\nНЕ ЖМУРИНО!', -30, 12, -77.1, 22, 6, 0, { bg: '#0d1626', fg: '#7fe0ff', glow: 1.6, border: '#7fe0ff' });
    // гаражи
    const gc = [0x6b6258, 0x4a5a6a, 0x6a4a3a, 0x5a6a4a]; for (let i = 0; i < 15; i++) { if (i) garage(L, -28 + i * 4, -48, 0, gc[i % 4]); if (i !== 6 && i !== 7) garage(L, -28 + i * 4, -64.5, 0, gc[(i + 2) % 4]); }
    L.sign('ГСК «ПАКОСТЬ»', -30, 3.4, -45.15, 6, 1, 0, { bg: '#2a1a1a', fg: '#ffb060' }); fence(L, -30.5, -45.2, -30.5, -67.3, 2, M.ribs('#4a4a4a')); fence(L, 30.5, -45.2, 30.5, -67.3, 2, M.ribs('#4a4a4a')); L.lamp(0, 3, -56.5, 0xffb060, 30, 16, { flicker: 1 });
    // остановка
    L.box(C(0x7fa6c8, .1, .5, { transparent: true, opacity: .4 }), 42, 1.4, 25.2, 5, 2.4, .08); L.box(M.metalDark(), 42, 2.7, 24, 5.4, .1, 2.6, { solid: false }); for (const s of [-1, 1]) L.cyl(M.metalDark(), 42 + s * 2.5, 1.35, 22.9, .06, 2.7, { seg: 6, solid: true }); bench(L, 42, 24.4, PI); L.sign('ОСТ. «КУРЬЕРСКАЯ»', 42, 3.1, 22.7, 4.4, .6, PI, { bg: '#10203a', fg: '#fff', glow: 1 }); L.lamp(42, 2.4, 24, 0xd8e6ff, 26, 12);
    for (let i = 0; i < 6; i++) L.box(0xf2f2f2, 37, .012, 12 + i * 1.2, 4, .02, .5, { solid: false });
    // станция «поеза»
    L.box(M.concrete(), 64, .45, -24, 10, .9, 36); L.stairs(M.concrete(), 57.5, -24, 6, 3, 0, .9, { rot: PI / 2 }); L.box(0xffd21f, 68.6, .905, -24, .3, .02, 36, { solid: false });
    for (const z of [-33.5, -17.5]) { L.box(M.tram(), 71.7, 2.3, z, 2.7, 2.9, 14.6, { fit: 1 }); L.box(0xdfe3e6, 71.7, 3.8, z, 2.5, .2, 14.2, { solid: false, gloss: 1 }); L.box(M.metalDark(), 71.7, .55, z, 2.2, .7, 13, { solid: false }); }
    for (const x of [70.9, 72.5]) L.box(M.metal(), x, .12, -24, .12, .14, 110, { solid: false }); for (let i = 0; i < 44; i++) L.box(M.planksDark(), 71.7, .04, -78 + i * 2.5, 2.8, .1, .3, { solid: false });
    for (const z of [-38, -24, -10]) { for (const x of [60.5, 67.5]) L.cyl(M.metalDark(), x, 2.6, z, .1, 3.4, { seg: 6, solid: true }); ceilLamp(L, 64, 4.25, z, 0xfff0d0, 30, 14, { rz: 1 }); } L.box(M.ribs('#4a5560'), 64, 4.4, -24, 9, .16, 32, { solid: false });
    L.sign('ПОЕЗ', 59.9, 5.3, -24, 7, 1.5, -PI / 2, { bg: '#10203a', fg: '#ffd21f', glow: 1.8, border: '#ffd21f' }); L.sign('МОЛОЧНОЕ · МЫТИЩИ · БАНЬКА', 64, 3.6, -41.9, 8, .7, 0, { bg: '#1a1a1a', fg: '#7dff8a', glow: 1.3, dbl: 1 });
    // --- точки ---
    L.cps = { start: [-64, 0, 0, PI / 2], lobby: [0, .1, 56.5, 0], roof: [0, RY, 73.5, PI], station: [62, .9, -24, -PI / 2] };
    // --- NPC ---
    const quest = () => f('m_boss') ? (inv.has('btn1') && inv.has('btn2') && inv.has('btn3') ? 5 : 4) : f('m_lift') ? 3 : inv.has('pass') ? 2 : f('m_drun') ? 1 : 0;
    const setGoal = () => { const q = quest(), np = inv.has('parcel'); if (q === 0) g.goal('Найди Друна у ларька с шавермой', -22, 1.2, 18.5); else if (q === 1) np ? g.goal('Отнеси посылку курьеру на остановку', 40, 1.2, 21.5) : f('m_cour') ? g.goal('Найди посылку курьера в гаражах ГСК «Пакость»', 0, 1.2, -56.5) : g.goal('Поговори с курьером на остановке', 40, 1.2, 21.5); else if (q === 2) g.goal('Войди в «пезд» П-46 и вызови ливт', 0, 1.5, 62.5); else if (q === 3) g.goal('Вызови ливт в П-46', 0, 1.5, 62.5); else if (q === 4) g.goal(`Собери три кнопки ливта (${['btn1', 'btn2', 'btn3'].filter(b => inv.has(b)).length}/3). Садись на «поез»`, 69, 2, -24); else g.goal('Все кнопки собраны! Вызови ливт в П-46', 0, 1.5, 62.5); };
    const drun = g.spawn(new NPC(-22, 0, 18.4, { name: 'Друн', yaw: PI, mark: f('m_drun') ? null : '!', look: DRUN_LOOK, *talk(n) {
      if (!f('m_drun')) {
        yield* lines([['drun', 'Ч! Живой! Ам-ам-ам, как я рад. Садись, посидим… нет, некогда сидеть.'], ['drun', 'Слушай. 32 августа в 00:00 последний ливт в Мурино уходит на первый этаж. Кто не успел — того забирает Фог.'], ['ch', 'А сейчас какое число?'], ['drun', '31-е. С половиной. Ливт стоит в гигахрущёвке П-46, но в «пезд» без пропуска не пустят. Пропуск есть у курьера на остановке.'], ['drun', 'И ещё: если прижмут — ори. Вот так: «АМ! АМ! АМ!». Я тебя научу.']]);
        g.setFlag('m_drun'); n.setMark(null); inv.add('ult'); tip('Бей врагов — копится ярость. Полная шкала: жми R', 'Бей врагов — копится ярость. Полная шкала: жми 😱'); setGoal();
      } else { const q = quest(); yield* lines([['drun', q <= 1 ? 'Курьер на остановке, вон там, за площадкой. Жёлтый такой, уставший.' : q <= 3 ? 'Пропуск есть? Дуй в П-46. Ливт любит, когда его уважают: запомни, какие этажи он покажет.' : q === 4 ? 'Кнопки от ливта растащили: одна в Молочном, одна в Мытищах, одна в Баньке. «Поез» ходит со станции.' : 'Все три? Красавчик. В ливт — и на первый этаж. Только чую, Фог так просто не отпустит…']]); }
    } }));
    const ashot = { n: 'Ашот', e: '🌯' }; g.spawn(new NPC(-26.6, 0, 19.6, { name: 'Ашот', yaw: PI, mark: '?', r: 2.2, look: { face: faceTex({ mood: 'happy', skin: '#c89070', stache: '#2a1a10' }), top: 0xf2f2f2, sleeve: 'short', pants: 0x2a2a2a, hairStyle: 'cap', capColor: 0xf2f2f2, fat: 1.3, skin: 0xc89070 }, label: 'Купить', *talk() { yield* lines([[ashot, 'Шаверма, брат! С мясом! Каким — не спрашивай.']]); yield* G.ui.shop('ШАВЕРМА У АШОТА', GOODS, 'Вкусности и цепи'); } }));
    const cour = { n: 'Курьер', e: '🛵' }; const cn = g.spawn(new NPC(40.5, 0, 21.6, { name: 'Курьер', yaw: PI, mark: inv.has('pass') ? null : '!', look: { face: faceTex({ mood: 'tired' }), top: 0xffd400, sleeve: 'long', pants: 0x222222, hairStyle: 'cap', capColor: 0xffd400, pack: 0xffd400 }, *talk(n) {
      if (inv.has('pass') || f('m_lift')) return yield* lines([[cour, 'Квартира 3 999 999… Мне всего-то на девять тысяч этажей выше. Спасибо, брат.']]);
      if (inv.has('parcel')) { yield* lines([[cour, 'Посылка! Целая! Ну, почти. Держи пропуск — мне он уже не поможет, а тебе в самый раз.'], [cour, 'И осторожнее в «пезде»: ливт там… с характером.']]); inv.take('parcel'); inv.add('pass'); n.setMark(null); g.pay(30); G.ui.toast('+30 ₽ чаевые', 'hint'); g.checkpoint('start', true); setGoal(); return; }
      yield* lines(f('m_cour') ? [[cour, 'Гаражи — за площадкой, на юге. ГСК «Пакость». Название, говорят, не случайное.']] : [[cour, 'Третий год ищу квартиру 4 000 000 в П-46. Третий год, брат.'], ['ch', 'Мне бы пропуск в «пезд».'], [cour, 'Дам. Но у меня пакости посылку утащили — в гаражи, в ГСК. Принеси, и пропуск твой.']]); g.setFlag('m_cour'); setGoal();
    } }));
    const mash = { n: 'Машинист', e: '🚂' }; g.spawn(new NPC(66.5, .9, -24, { name: 'Машинист', yaw: -PI / 2, mark: f('m_boss') ? '!' : null, look: { face: faceTex({ mood: 'smile', stache: '#555' }), top: 0x20305a, sleeve: 'long', pants: 0x20305a, hairStyle: 'cap', capColor: 0x20305a }, label: 'Сесть на «поез»', *talk() {
      if (!f('m_boss')) return yield* lines([[mash, '«Поез» не идёт. Рельсы в тумане. Говорят, с крыши П-46 кто-то тёмный туман гонит…']]);
      const D = [['milk', 'Село Молочное', 'btn1'], ['myt', 'Мытищи', 'btn2'], ['banya', 'Банька', 'btn3']]; yield* lines([[mash, 'Куда едем? «Поез» идёт по расписанию. Расписания нет.']]);
      const c = yield* G.ui.choose([...D.map(d => d[1] + (inv.has(d[2]) ? ' — кнопка уже у тебя ✓' : '')), 'Остаться в Мурино']); if (c > 2) return; if (!LEVELS[D[c][0]]) return yield* lines([[mash, 'Туда пути ещё кладут. Приходи позже.']]);
      yield* lines([['ch', 'Поехали!']]); G.audio.sfx('tram'); g.travel(D[c][0]);
    } }));
    // --- ливт ---
    L.interact(1.2, 1.3, 62.6, 2.6, 'Вызвать ливт', () => g.script(function* () {
      const q = quest();
      if (q <= 3 && !f('m_boss')) {
        if (!f('m_lift')) { yield* lines([['sys', 'Панель ливта мигает. Он как будто что-то вспоминает…']]); const ok = yield* G.ui.simon('ЛИВТ П-46'); if (!ok) return; g.setFlag('m_lift'); G.audio.sfx('ding'); yield* lines([['sys', 'Ливт: «МАРШРУТ ПРИНЯТ. ЭТАЖ: КРЫША. КНОПКИ ПЕРВОГО ЭТАЖА ОТСУТСТВУЮТ».']]); }
        yield* G.ui.fadeTo(1, .5); G.audio.sfx('power'); G.player.place(0, RY, 73.5, PI); G.cam.snap(); yield* wait(1); g.checkpoint('roof', true); yield* G.ui.fadeTo(0, .5);
      } else if (q === 4) yield* lines([['sys', `Ливт: «ДЛЯ ПЕРВОГО ЭТАЖА НЕ ХВАТАЕТ КНОПОК: ${3 - ['btn1', 'btn2', 'btn3'].filter(b => inv.has(b)).length}». На крышу он больше не едет.`]]);
      else { yield* lines([['ch', 'Три кнопки. Вставляю. Поехали… на первый этаж.'], ['sys', 'Ливт: «ПЕРВЫЙ ЭТАЖ. ВРЕМЯ: 23:59. 31 АВГУСТА».']]); if (LEVELS.final) g.travel('final'); else yield* lines([['sys', 'Ливт вздрогнул и замер. (Финал ещё не построен.)']]); }
    }));
    L.interact(0, RY + 1.2, 75.9, 2.2, 'Ливт вниз', () => g.script(function* () { yield* G.ui.fadeTo(1, .4); G.player.place(0, .1, 60, PI); G.cam.snap(); g.checkpoint('lobby', true); yield* wait(.5); yield* G.ui.fadeTo(0, .4); setGoal(); }), { cond: () => f('m_boss') });
    // --- предметы, враги ---
    if (!inv.has('parcel') && !inv.has('pass') && !f('m_lift')) g.spawn(new Crate(1.5, .05, -56.6, { s: 1, item: 'parcel', fid: 'mur.parcelc', ifid: 'mur.parcel', yaw: .2 }));
    crates(L, [[-27, -56], [-22, -57.5], [20, -56], [26, -57], [-50, -30], [-52, 28], [50, -50], [30, 44], [-44, 44], [8, 56, .1], [-5.5, 62.5, .1]], Crate);
    g.cash(20, -24, 2.9, -48, 'mur.g1'); g.cash(20, 4, 2.9, -48, 'mur.g2'); g.cash(20, 16, 2.9, -64.5, 'mur.g3'); g.item('hp', -16, 2.95, -64.5, 'mur.hp1'); g.item('plums', 24, 2.95, -48, 'mur.pl'); g.item('shava', -6, 1.9, -6, 'mur.sh'); g.item('hp', 38, RY + .4, 78, 'mur.hp2'); g.cash(20, -36, RY + .5, 60, 'mur.r1');
    const E = (k, x, z, y = 0) => g.spawn(new Enemy(k, x, y, z));
    if (!f('m_boss')) { E('slime', -8, -56); E('slime', 6, -57); E('slime', -3, -55.5); E('slime', 12, -56.5); E('slime', -16, -57); E('wisp', -4, 6); E('wisp', 8, -2); E('wisp', -30, -12); E('gop', 44, -30); E('gop', 47, -33); E('courier', 34, 40); E('courier', -48, -46); E('wisp', 50, 20); }
    else { E('wisp', -4, 6); E('slime', 6, -57); E('slime', -8, -56); }
    // --- босс ---
    if (!f('m_boss')) {
      const boss = g.spawn(new DarkDrun(0, RY, 62)); boss.yaw = 0; boss.sync(); boss.body.set('dance');
      L.trigger(0, 70, 0, () => g.script(function* () {
        G.audio.music('boss'); G.cam.shot(3.5, RY + 1.6, 67.5, 0, RY + 2, 62, false, 2.4); yield* wait(1);
        yield* lines([['ch', 'Друн? Ты как сюда раньше меня?.. И чё ты в чёрном?'], ['dark', 'Друн внизу. Шаверму жрёт. А Ч — тут. И Ч никуда не поедет.'], ['dark', 'Кнопки от ливта Ч раскидал: Молочное, Мытищи, Банька. Фог сказал — никто не уедет на первый этаж.'], ['ch', 'Что за бизнес… Ты же не Друн. Ты — ТЁМНЫЙ ДРУН!']]);
        boss.body.set(null); boss.body.play('cast', 1); G.audio.sfx('roar'); G.cam.shake(.7); G.ui.bigTitle('ТЁМНЫЙ ДРУН', 'БОСС', 2400); yield* wait(1.2); boss.start(); g.goal('Победи Тёмного Друна. Уворачивайся от серии — после неё он открывается!');
      }, 'cut'), { box: [20, 2.5], y0: RY - 1, y1: RY + 6 });
      boss.fade = true; boss.onDefeat = () => { g.setFlag('m_boss'); inv.add('kicks'); g.pay(80); G.audio.music('murino'); G.audio.sfx('win'); g.checkpoint('roof', true); g.write(); setGoal(); g.script(function* () { yield* lines([['dark', 'Плаки-плаки… Фог всё равно придёт…'], ['phone', '*бзззз* Друн: «Ч! Туман с рельсов ушёл, поез снова ходит! И слышь — тот тёмный мои кроссы обронил. Носи, они с двойным прыжком».'], ['ch', 'Три кнопки. Молочное, Мытищи, Банька. Поехали.']]); tip('Кроссы Друна: нажми прыжок ещё раз в воздухе'); }); };
    }
    L.trigger(-50, 0, 6, () => { if (!f('m_drun')) tip('Жёлтая метка ведёт к цели. Shift — бег', 'Жёлтая метка ведёт к цели. Тяни стик до упора — бег'); });
    L.start = function* (cp) { setGoal(); if (cp === 'station' && quest() === 5) G.ui.toast('Все три кнопки у тебя. Пора в П-46!', 'big'); };
  },
};
