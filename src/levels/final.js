// ФИНАЛ — ПЕРВЫЙ ЭТАЖ, 23:59: двор П-46 в тумане и сам ФОГ
import * as THREE from 'three';
import { G, wait, rand, PI, TAU, damp, dampAng, clamp } from '../g.js';
import { LEVELS } from '../game.js';
import { M, C, glowMat } from '../tex.js';
import { lampPost, block, bench, car } from '../kit.js';
import { NPC, Enemy, Crate, Pickup } from '../actors.js';
import { Boss } from '../bosses.js';
import { makeFog } from '../rig.js';
import { lines, tip } from '../script.js';
import { DRUN_LOOK } from './murino.js';

const _v = new THREE.Vector3(), R = 24;
const FOGGY = { top: 0x1a1e2a, hor: 0x8a94a6, bot: 0x4a5060, sun: [.2, .75, .3], sunCol: 0xcfd8ee, sunInt: .9, hemiSky: 0xaab4c8, hemiGnd: 0x4a4e58, hemiInt: .95, fogExp: [0x9aa4b4, .028], stars: .5, clouds: .9, cloudCol: 0x8a94a6, exposure: 1.05, bloom: [.5, .7, .85], envInt: .6, lamp: 3, lampCol: 0xdfe8ff, shadowSize: 40 };

// тело ФОГа: голова и две руки, которые двигаются к целям
class FogBody {
  constructor() {
    Object.assign(this, makeFog()); this.h = 12; this.fl = 0; this.time = 0; this.base = null;
    this.headRest = new THREE.Vector3(0, 13.5, 25); this.headT = new THREE.Vector3(0, -16, 25); this.hk = 1.6;
    this.rest = [new THREE.Vector3(12, 8.5, 15), new THREE.Vector3(-12, 8.5, 15)]; this.ht = this.rest.map(v => new THREE.Vector3(v.x, -9, v.z)); this.k = [2, 2]; this.flat = [0, 0];
    this.head.position.copy(this.headT); this.head.rotation.order = 'YXZ'; this.head.rotation.y = PI; this.hands.forEach((h, i) => { h.position.copy(this.ht[i]); h.rotation.order = 'YXZ'; h.rotation.y = PI; });
    this.em = new THREE.Color(0xaab4c4); this.hot = new THREE.Color(0xff5a4a);
  }
  rise() { this.headT.copy(this.headRest); this.ht.forEach((t, i) => t.copy(this.rest[i])); }
  flash(v) { this.fl = v; } play() { } set(n) { this.base = n; }
  update(dt) {
    this.time += dt; const t = this.time, P = G.player.pos, hp = this.head.position;
    if (this.base === 'dead') { this.headT.y = Math.max(-20, this.headT.y - dt * 5); for (const T of this.ht) T.y = Math.max(-10, T.y - dt * 4); this.hk = 1.2; }
    hp.x = damp(hp.x, this.headT.x, this.hk, dt); hp.y = damp(hp.y, this.headT.y + Math.sin(t * .9) * .5, this.hk, dt); hp.z = damp(hp.z, this.headT.z, this.hk, dt);
    const hd = Math.hypot(P.x - hp.x, P.z - hp.z); this.head.rotation.y = dampAng(this.head.rotation.y, Math.atan2(P.x - hp.x, P.z - hp.z), 3, dt); this.head.rotation.x = damp(this.head.rotation.x, clamp(Math.atan2(hp.y - P.y - 1.5, hd), -.15, .9), 3, dt);
    this.hands.forEach((h, i) => {
      const T = this.ht[i], k = this.k[i], p = h.position, bob = this.flat[i] ? 0 : Math.sin(t * 1.3 + i * 2) * .5; p.x = damp(p.x, T.x, k, dt); p.y = damp(p.y, T.y + bob, k, dt); p.z = damp(p.z, T.z, k, dt);
      if (!this.flat[i]) h.rotation.y = dampAng(h.rotation.y, Math.atan2(P.x - p.x, P.z - p.z), 4, dt); h.rotation.x = damp(h.rotation.x, this.flat[i] ? 0 : -.35, 9, dt);
    });
    this.fl = Math.max(0, this.fl - dt * 4); this.mat.emissive.copy(this.em).lerp(this.hot, this.fl); this.mat.emissiveIntensity = .55 + this.fl;
  }
  dispose() { this.root.removeFromParent(); this.root.traverse(o => { if (o.isSkinnedMesh) { o.geometry.dispose(); if (o.skeleton) o.skeleton.dispose(); } }); this.mat.dispose(); this.fm.dispose(); }
}
// рука/лицо как цель: принимает удары за босса
class FogPart {
  constructor(boss, r, h, solid) { this.boss = boss; this.pos = new THREE.Vector3(0, -60, 0); this.r = r; this.h = h; this.aimY = h * .45; this.team = 'enemy'; this.dead = true; this.sr = solid; this.solidR = 0; this.stunnable = false; this.root = new THREE.Group(); }
  on(x, z) { this.pos.set(x, 0, z); this.dead = false; this.solidR = this.sr; }
  off() { this.dead = true; this.solidR = 0; this.pos.y = -60; }
  update() { } dispose() { this.root.removeFromParent(); }
  hurt(dmg, from, knock, kind) { return this.boss.hitPart(this, dmg, kind); }
}

class Fog extends Boss {
  constructor() {
    super(0, 0, 25, { name: 'ФОГ', hp: 1600, r: .01, h: 12, mass: 99, solidR: 0, fly: true, aimY: 6, body: new FogBody() });
    this.noAim = true; this.invul = true; this.ph = 1; this.n = 0; this.side = 0; this.fogT = .028; this.dn = 0; this.da = 0;
    this.hands = [new FogPart(this, 2.2, 1.7, 1.5), new FogPart(this, 2.2, 1.7, 1.5)]; this.face = new FogPart(this, 4.2, 7, 3.7);
  }
  sync() { }   // корень неподвижен: голова и руки живут в мировых координатах
  say(t, cls = 'alert') { const P = this.P.pos; _v.set(P.x, P.y + 3.3, P.z); G.fx.text(_v, t, cls); }
  count() { return G.ents.filter(e => e.c && e.team === 'enemy' && !e.dead).length; }
  hitPart(part, dmg, kind) {
    if (this.dead || !this.active) return false; dmg = Math.max(1, Math.round(dmg * this.vul)); this.hp -= dmg; const p = part.pos, spray = kind === 'spray'; this.body.flash(spray ? .3 : .8);
    if (!spray || Math.random() < .3) { _v.set(p.x + rand(-1, 1), p.y + part.aimY, p.z + rand(-1, 1)); G.fx.burst('hit', _v, 5); G.fx.burst('fog', _v, 2, { s: .45 }); }
    _v.set(p.x, p.y + Math.min(part.h, 3) + .6, p.z); if (spray) { this.da += dmg; if (++this.dn % 4 === 0) { G.fx.text(_v, String(this.da), 'dot'); this.da = 0; } } else G.fx.text(_v, String(dmg), this.vul > 1 ? 'dmg alert' : 'dmg');
    if (this.hp <= 0) this.die(); return true;
  }
  die() { if (this.dead) return; for (const p of [...this.hands, this.face]) p.off(); this.fogT = .008; super.die(); }
  // ладонь зависает над игроком и бьёт; потом на время застревает в асфальте
  *slam(i, stuck) {
    const P = this.P, B = this.body, part = this.hands[i]; let t = this.ph > 1 ? .75 : 1; B.k[i] = 5;
    while ((t -= G.dt) > 0) { B.ht[i].set(P.pos.x, 8.5, P.pos.z); yield; }
    let x = B.ht[i].x, z = B.ht[i].z; const d = Math.hypot(x, z); if (d > R - 1.5) { x *= (R - 1.5) / d; z *= (R - 1.5) / d; }
    B.ht[i].set(x, 10.5, z); _v.set(x, 0, z); G.fx.disc(_v, 3.6, .6); G.audio.sfx('whoosh'); yield* this.wait(.42); B.k[i] = 26; B.ht[i].y = .45; B.flat[i] = 1; yield* this.wait(.18);
    _v.set(x, 0, z); G.cam.shake(.9); G.audio.sfx('slam'); G.fx.ring(_v, 1, 6.5, .45, 0xdfe6ee); G.fx.burst('fog', _v, 8); G.fx.burst('dust', _v, 10, { s: 1.6 }); this.hitCircle(x, z, 3.6, 20, 12);
    part.on(x, z); if (!this.told) { this.told = 1; _v.set(x, 2.8, z); G.fx.text(_v, 'ЗАСТРЯЛА! БЕЙ!', 'good'); }
    yield* this.wait(stuck); part.off(); B.flat[i] = 0; B.k[i] = 3.5; B.ht[i].copy(B.rest[i]);
  }
  // обе ладони бьют в землю — по двору идёт кольцо тумана
  *rings(n) {
    const B = this.body; this.say('ТУМАН ИДЁТ'); for (let j = 0; j < 2; j++) { B.k[j] = 6; B.ht[j].set(j ? -6 : 6, 9, 9); } yield* this.wait(.8);
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < 2; j++) { B.k[j] = 24; B.ht[j].y = .5; B.flat[j] = 1; _v.set(j ? -6 : 6, 0, 9); G.fx.disc(_v, 3, .2); } yield* this.wait(.2);
      G.cam.shake(.7); G.audio.sfx('slam'); this.hitCircle(6, 9, 3, 16, 10); this.hitCircle(-6, 9, 3, 16, 10); G.run(this.shockwave(0, 9, 36, 2.5, 14, 0xdfe6ee)); yield* this.wait(.5);
      for (let j = 0; j < 2; j++) { B.k[j] = 6; B.ht[j].y = 7; B.flat[j] = 0; } yield* this.wait(.65);
    }
    for (let j = 0; j < 2; j++) { B.k[j] = 3.5; B.ht[j].copy(B.rest[j]); } yield* this.wait(.5);
  }
  // сгустки тумана изо рта, доворачивают за игроком
  *breath(n) {
    const B = this.body, P = this.P.pos; this.say('Х-Х-Х-Х…'); G.audio.sfx('fog'); yield* this.wait(.6);
    for (let i = 0; i < n; i++) { const h = B.head.position, ox = h.x + rand(-1.5, 1.5), oy = Math.max(2, h.y - 3), oz = h.z - 4, dx = P.x - ox, dy = P.y + 1 - oy, dz = P.z - oz, dl = Math.hypot(dx, dy, dz) || 1, sp = 12; this.shoot({ x: ox, y: oy, z: oz, vx: dx / dl * sp, vy: dy / dl * sp, vz: dz / dl * sp, dmg: 11, kind: 'orb', color: 0xdfe6ee, r: .42, life: 5, home: 1.3 }); G.audio.sfx('throw'); yield* this.wait(.34); }
    yield* this.wait(.6);
  }
  wisps(n) { for (let i = 0; i < n; i++) { const a = rand(TAU), d = rand(8, 16), x = Math.sin(a) * d, z = Math.cos(a) * d; _v.set(x, 1, z); G.fx.burst('fog', _v, 6); G.game.spawn(new Enemy('wisp', x, 0, z, { alert: 1, relentless: 1, food: .35 })); } }
  // лицо опускается и втягивает; крик «АМ-АМ-АМ» — подавится
  *inhale() {
    const B = this.body, P = this.P; this.say('ВДОХ…'); B.hk = 2.2; B.headT.set(0, 5.6, 19.5); for (let j = 0; j < 2; j++) { B.k[j] = 3; B.ht[j].set(j ? -13 : 13, 3, 17); } yield* this.wait(1.3); G.audio.sfx('fog');
    let t = 4.4, bite = 0, choke = false, fx = 0;
    while (t > 0) {
      t -= G.dt; bite -= G.dt; fx -= G.dt; const dx = -P.pos.x, dz = 17 - P.pos.z, d = Math.hypot(dx, dz) || 1, pull = 4.3 * G.dt; if (d > 2 && !P.dead) { P.pos.x += dx / d * pull; P.pos.z += dz / d * pull; }
      if (fx <= 0) { fx = .07; const a = rand(TAU), rr = rand(4, 14); _v.set(P.pos.x + Math.sin(a) * rr * .4 + dx / d * rr, rand(.5, 3), P.pos.z + Math.cos(a) * rr * .4 + dz / d * rr); G.fx.trail(_v, 0xdfe6ee, 1.1); }
      if (d < 5.6 && bite <= 0) { bite = .8; _v.set(0, P.pos.y, 20); P.hurt(16, _v, 14); }
      if (P.ultT > 0) { choke = true; break; } yield;
    }
    this.vul = choke ? 2 : 1.4; this.say(choke ? 'ПОДАВИЛСЯ! БЕЙ!' : 'ЗАПЫХАЛСЯ! БЕЙ!', 'good'); G.cam.shake(.6); G.audio.sfx('slam'); B.headT.set(0, 4.6, 18.5); this.face.on(0, 18.5);
    yield* this.wait(choke ? 5 : 3.6); this.face.off(); this.vul = 1; B.hk = 1.8; B.headT.copy(B.headRest); for (let j = 0; j < 2; j++) { B.k[j] = 3.5; B.ht[j].copy(B.rest[j]); } yield* this.wait(.8);
  }
  *rage(text, dens) { this.say(text); G.audio.sfx('roar'); G.cam.shake(1); this.fogT = dens; this.body.flash(1); yield* this.wait(1.6); }
  *ai() {
    const k = this.hp / this.maxHp;
    if (k < .6 && this.ph < 2) { this.ph = 2; yield* this.rage('ТУМАН ГУСТЕЕТ', .04); return; }
    if (k < .28 && this.ph < 3) { this.ph = 3; yield* this.rage('ФОГ СПУСКАЕТСЯ', .046); yield* this.inhale(); return; }
    const n = this.n++, i = (this.side ^= 1);
    if (this.ph === 1) { const m = n % 4; if (m === 0 || m === 2) yield* this.slam(i, 2.8); else if (m === 1) yield* this.breath(4); else { if (this.count() < 2) this.wisps(2); yield* this.rings(1); } }
    else if (this.ph === 2) { const m = n % 4; if (m === 0 || m === 2) { yield* this.slam(i, 1); yield* this.slam(1 - i, 2.5); } else if (m === 1) yield* this.breath(6); else { if (this.count() < 3) this.wisps(2); yield* this.rings(2); } }
    else { const m = n % 3; if (m === 0) { yield* this.slam(i, .9); yield* this.slam(1 - i, 2.3); } else if (m === 1) yield* this.inhale(); else { yield* this.breath(5); yield* this.rings(2); } }
    yield* this.wait(this.ph > 1 ? .5 : .9);
  }
}

LEVELS.final = {
  id: 'final', title: 'ПЕРВЫЙ ЭТАЖ', sub: 'ФИНАЛ · 23:59', music: 'fog', weather: 'ash', seed: 61, env: FOGGY,
  kit: { gear: { phone: 1, spray: 1, chain: 2, ult: 1, kicks: 1, hp: 3 }, money: 200, inv: { doshik: 2, shava: 2, kvas: 1, plums: 1, btn1: 1, btn2: 1, btn3: 1 }, flags: { m_boss: 1, m_drun: 1, m_lift: 1, k_boss: 1, y_boss: 1, b_boss: 1 } },
  build(L) {
    const g = G.game, f = k => g.flag(k), won = !!f('f_boss');
    L.box(M.asphalt(.7), 0, -.25, 0, 240, .5, 240); L.cyl(M.pavers(), 0, .03, 0, R + 1.5, .06, { seg: 40 });
    for (let i = 0; i < 24; i++) { const a = i / 24 * TAU; L.world.box(Math.sin(a) * (R + 2.4), 8, Math.cos(a) * (R + 2.4), 7.6, 20, 1, a, { nocam: true }); }
    // П-46 за спиной: отсюда Ч вышел из ливта
    L.box(M.facade(3), 0, 45, -43.6, 96, 90, 27.2); L.box(M.concrete(), 0, 3.5, -29.2, 8, .3, 2.6, { solid: false }); for (const s of [-1, 1]) L.cyl(M.metalDark(), s * 3.6, 1.7, -28.2, .08, 3.4, { seg: 6 });
    L.box(glowMat(0xfff0c0, 1.6), 0, 1.6, -29.92, 3.2, 3.2, .1, { solid: false }); L.box(M.metalDark(), 0, 1.6, -29.86, .08, 3.2, .1, { solid: false }); L.lamp(0, 2.6, -28, 0xfff0c0, 40, 16);
    L.sign('П-46', 0, 13.5, -29.9, 9, 3, 0, { bg: 'none', fg: '#ff5a5a', glow: 2.2, stroke: '#300' }); L.sign('ЛИВТ · 1 ЭТАЖ', 0, 4.3, -29.9, 4.4, .7, 0, { bg: '#101a10', fg: '#7dff8a', glow: 1.6 });
    const c1 = L.sign('23:59', 0, 8.4, -29.9, 7, 2.6, 0, { bg: '#0a0a0a', fg: '#ff4a3a', glow: 2.4 }), c2 = L.sign('00:00', 0, 8.4, -29.9, 7, 2.6, 0, { bg: '#0a0a0a', fg: '#7dff8a', glow: 2.4 }); c1.visible = !won; c2.visible = won;
    [[-70, 10, 20, 0], [72, -6, 24, 1], [-40, 76, 16, 2], [44, 78, 22, 0], [0, 110, 30, 1], [-110, -40, 26, 2], [112, 50, 18, 0]].forEach(([x, z, fl, fi], i) => block(L, x, z, i % 2 ? 54.4 : 13.6, i % 2 ? 13.6 : 54.4, fl, fi, { far: 1, solid: false }));
    for (let i = 0; i < 6; i++) { const a = i / 6 * TAU + .52, x = Math.sin(a) * (R - 1.6), z = Math.cos(a) * (R - 1.6); lampPost(L, x, z, 0, 0xcfe0ff, 6.2, a + PI / 2); }
    bench(L, -17, -13, .9); bench(L, 17, -13, -.9); car(L, -36, -14, .3, 0x3a4a6a); car(L, 37, -18, -.2, 0x6a2a2a); car(L, 34, 20, 1.2, 0x8a8a8a);
    L.cps = { start: [0, 0, -21.5, 0] };
    let fa = 0; L.onUpdate(dt => { fa -= dt; if (fa <= 0 && !won) { fa = .12; const a = rand(TAU); _v.set(Math.sin(a) * (R + 3), rand(0, 3), Math.cos(a) * (R + 3)); G.fx.burst('fog', _v, 1, { s: 1.6 }); } });
    // припасы появляются заново при каждой попытке
    if (!won) { for (const [id, x, z] of [['plums', -17, -8], ['plums', 17, -8], ['shava', -20, 4], ['kvas', 20, 4], ['doshik', 0, -19]]) g.spawn(new Pickup(x, .4, z, { item: id })); for (const [x, z] of [[-13, -16], [13, -16], [-21, -4], [21, -4]]) g.spawn(new Crate(x, 0, z, {})); }
    if (won) {
      let dn = .012; L.onUpdate(() => G.gfx.setFogDensity(dn)); g.goal('Туман ушёл. Поговори с Друном', 0, 1.6, -6);
      g.spawn(new NPC(0, 0, -6, { name: 'Друн', yaw: PI, mark: '!', look: DRUN_LOOK, anim: 'dance', *talk() {
        yield* lines([['drun', 'Ч! Ты это сделал! Тридцать второе августа, ноль-ноль — и ни тумана, ни пакостей. Ам-ам-ам!']]);
        const c = yield* G.ui.choose(['Сразиться с ФОГом ещё раз', 'Вернуться в Мурино', 'Посидим']); if (c === 0) { g.setFlag('f_boss', 0); g.setFlag('f_met', 0); g.travel('final'); } else if (c === 1) g.travel('murino', 'lobby'); else yield* lines([['drun', 'Посидим. Заслужил.']]);
      } }));
      L.start = function* () { };
      return;
    }
    const boss = g.spawn(new Fog()); for (const p of [...boss.hands, boss.face]) g.spawn(p);
    let dens = .028; L.onUpdate(dt => { dens = damp(dens, boss.fogT, .7, dt); G.gfx.setFogDensity(dens); });
    L.trigger(0, 0, 16, () => g.script(function* () {
      G.audio.music('boss'); G.cam.shot(0, 2.4, -9, 0, 10, 24, false, 1.5); boss.body.rise(); G.audio.sfx('fog'); G.cam.shake(.5); yield* wait(2.4);
      if (!f('f_met')) { yield* lines([['fog', 'Ч-ч-ч…'], ['fog', 'Никто не уезжает из Мурино. Мурино — это я.'], ['ch', 'Ты — сырость над болотом. А я прошёл Молочное, Мытищи и Баньку. Я даже помылся!'], ['fog', 'Тогда оставайся чистым. Навсегда.'], ['ch', 'АМ-АМ-АМ!']]); g.setFlag('f_met'); }
      G.audio.sfx('roar'); G.cam.shake(1); G.ui.bigTitle('ФОГ', 'ФИНАЛЬНЫЙ БОСС', 2600); yield* wait(1.4); G.cam.maxDist = 12; G.cam.want = 8.5; boss.start(); g.goal('Победи ФОГа. Бей по ладони, пока она застряла в асфальте!');
      tip('От ладони убегай или перекатывайся (C). Кольца тумана перепрыгивай. Когда ФОГ втягивает — кричи «АМ-АМ-АМ» (R)', 'От ладони убегай или перекатывайся 💨. Кольца тумана перепрыгивай. Когда ФОГ втягивает — жми 😱');
    }, 'cut'));
    boss.onDefeat = () => {
      g.setFlag('f_boss'); g.write();
      g.script(function* () {
        G.mode = 'cut'; G.cam.shot(0, 2.4, -14, 0, 6, 12, false, 1.2); yield* wait(1.4);
        yield* lines([['fog', 'Ч-ч-ч… Ты… просто… ветер…'], ['ch', 'Я не ветер. Я — Ч. И я приехал на первый этаж.'], ['sys', 'Туман редеет. Над Мурино впервые за лето видно звёзды.']]);
        c1.visible = false; c2.visible = true; G.audio.sfx('bell'); G.audio.music('win'); G.cam.shot(0, 2.6, -8, 0, 8, -30, false, 1.3); yield* wait(2);
        yield* lines([['phone', '*бзззз* Друн: «Ч! Ноль-ноль! Тридцать второе августа! Ты успел! Ам-ам-ам!»'], ['phone', 'Дод: «Посидим?» Брал: «Дай хотя бы хлеба!»'], ['ch', 'Посидим. Только сначала — помоюсь.']]);
        const S = G.save, t = S.t | 0, mm = String(t / 60 % 60 | 0).padStart(2, '0'), ss = String(t % 60).padStart(2, '0');
        G.mode = 'end'; G.ui.ending({ time: (t >= 3600 ? (t / 3600 | 0) + ':' : '') + mm + ':' + ss, kills: S.kills, deaths: S.deaths, money: S.earned || S.money });
      }, 'cut');
    };
    L.start = function* () { g.goal('Выйди во двор'); yield* wait(1); if (!f('f_met')) G.ui.toast('Первый этаж. 23:59. За дверью ливта — только туман', 'hint'); };
  },
};
