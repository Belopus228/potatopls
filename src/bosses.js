// Боссы: общий класс + Тараканий Царь. Остальные — в файлах уровней.
import * as THREE from 'three';
import { G, damp, dampAng, angDiff, rand, PI, TAU, yawTo, clamp } from './g.js';
import { Actor, Enemy, Shot, GRAV } from './actors.js';
import { Spider } from './rig.js';
import { M } from './tex.js';

const _v = new THREE.Vector3();
export class Boss extends Actor {
  // o: name, hp, r, h, body, mass, aimY, solidR, goo, fly
  constructor(x, y, z, o) {
    super(x, y, z); Object.assign(this, { team: 'enemy', boss: true, stunnable: false, vul: 1, speed: 0, active: false, blocked: false, t: 0 }, o); this.maxHp = this.hp; this.root = this.body.root; this.c = { mass: o.mass || 6, fly: o.fly, armor: 1 };
    this.aimY = o.aimY ?? this.h * .5; this.solidR = o.solidR ?? this.r * .8; this.brain = null; this.sync();
  }
  start() { if (this.active) return; this.active = true; this.brain = this.ai(); G.ui.bossBar(this, this.name); }
  *ai() { }
  get P() { return G.player; }
  dist() { return Math.hypot(this.P.pos.x - this.pos.x, this.P.pos.z - this.pos.z); }
  toP() { return yawTo(this.pos.x, this.pos.z, this.P.pos.x, this.P.pos.z); }
  *wait(t, face) { while ((t -= G.dt) > 0) { if (face) this.yaw = dampAng(this.yaw, this.toP(), face, G.dt); yield; } }
  // идти к точке/игроку
  *go(x, z, sp, maxT = 3, stop = .6) { while ((maxT -= G.dt) > 0 && Math.hypot(x - this.pos.x, z - this.pos.z) > stop) { const a = yawTo(this.pos.x, this.pos.z, x, z); this.yaw = dampAng(this.yaw, a, 8, G.dt); this.vel.x = damp(this.vel.x, Math.sin(a) * sp, 10, G.dt); this.vel.z = damp(this.vel.z, Math.cos(a) * sp, 10, G.dt); this.speed = sp; yield; } this.speed = 0; }
  *chase(sp, maxT = 3, stop = 2.5) { while ((maxT -= G.dt) > 0 && this.dist() > stop) { const a = this.toP(); this.yaw = dampAng(this.yaw, a, 7, G.dt); this.vel.x = damp(this.vel.x, Math.sin(a) * sp, 10, G.dt); this.vel.z = damp(this.vel.z, Math.cos(a) * sp, 10, G.dt); this.speed = sp; yield; } this.speed = 0; }
  // урон по кругу; jump — можно перепрыгнуть
  hitCircle(x, z, r, dmg, knock = 9, jump = false) { if (this.dead) return false; const P = this.P, d = Math.hypot(P.pos.x - x, P.pos.z - z); if (d > r + P.r) return false; if (jump && P.pos.y > this.floorY(x, z) + .7) return false; _v.set(x, P.pos.y, z); return P.hurt(dmg, _v, knock); }
  floorY(x, z) { return G.level.world.ground(x, z, this.pos.y + 1, 1.5); }
  // предупреждение + удар по площади
  *blast(x, z, r, t, dmg, o = {}) { const y = o.y ?? this.floorY(x, z); _v.set(x, y, z); G.fx.disc(_v, r, t, o.color); yield* this.wait(t); _v.set(x, y, z); G.fx.ring(_v, r * .3, r * 1.1, .35, o.ring ?? 0xffb060); G.fx.burst(o.fx || 'dust', _v, 12, { s: 1.6, color: o.fxc }); G.audio.sfx(o.sfx || 'slam'); G.cam.shake(o.shake ?? .5); return this.hitCircle(x, z, r, dmg, o.knock ?? 9, o.jump); }
  // расходящееся кольцо по земле: перепрыгни!
  *shockwave(x, z, rMax = 30, T = 2.2, dmg = 14, color = 0xb070ff) {
    const y = this.floorY(x, z), P = this.P; _v.set(x, y, z); G.fx.ring(_v, 1, rMax, T, color, .12); G.fx.ring(_v, .6, rMax * .96, T, 0xffffff, .1); G.audio.sfx('zap'); let t = 0, done = false;
    while (t < T * .8) { t += G.dt; const k = t / T, r = 1 + (rMax - 1) * (1 - (1 - k) * (1 - k)), d = Math.hypot(P.pos.x - x, P.pos.z - z); if (!done && Math.abs(d - r) < .75 && P.pos.y < y + .65 && Math.abs(P.pos.y - y) < 3) { _v.set(x, P.pos.y, z); done = P.hurt(dmg, _v, 7) || P.inv > 0; } yield; }
  }
  shoot(o) { return G.game.spawn(new Shot({ x: this.pos.x, y: this.pos.y + this.aimY, z: this.pos.z, team: 'enemy', ...o })); }
  summon(kind, n, rad = 3, o = {}) { const out = []; for (let i = 0; i < n; i++) { const a = rand(TAU), x = this.pos.x + Math.sin(a) * rad, z = this.pos.z + Math.cos(a) * rad, e = new Enemy(kind, x, this.floorY(x, z), z, { alert: 1, relentless: 1, food: .25, ...o }); _v.set(x, e.pos.y + .5, z); G.fx.burst('smoke', _v, 6); out.push(G.game.spawn(e)); } return out; }
  minions() { return G.ents.filter(e => e.team === 'enemy' && !e.boss && !e.dead).length; }
  update(dt) {
    const p = this.pos, v = this.vel;
    if (this.dead) { this.t += dt; if (!this.fly) this.physics(dt); v.x *= .9; v.z *= .9; this.sync(); this.body.update(dt, 0, 0); if (this.t > 2.2 && !this.fin) { this.fin = true; if (this.onDefeat) this.onDefeat(this); } if (this.fin && this.fade) { this.root.scale.multiplyScalar(Math.max(0, 1 - 3 * dt)); if (this.root.scale.x < .03) this.gone = true; } return; }
    if (this.active && G.mode === 'play' && !this.P.dead) { try { if (this.brain.next().done) this.brain = this.ai(); } catch (e) { console.error('boss', e); this.brain = this.ai(); } }
    else { this.speed = 0; }
    if (!this.speed) { v.x = damp(v.x, 0, 7, dt); v.z = damp(v.z, 0, 7, dt); }
    if (!this.fly) { const px = p.x, pz = p.z, hit = this.physics(dt), want = Math.hypot(v.x, v.z) * dt; this.blocked = hit && want > .01 && Math.hypot(p.x - px, p.z - pz) < want * .45; }
    this.sync(); this.body.update(dt, Math.hypot(v.x, v.z), this.onGround || this.fly ? 0 : 1);
  }
  hurt(dmg, from, knock = 0, kind) {
    if (this.dead || this.invul || !this.active) return false; dmg = Math.max(1, Math.round(dmg * this.vul)); this.hp -= dmg; this.body.flash(kind === 'spray' ? .3 : .8); const p = this.pos;
    if (kind !== 'spray' || Math.random() < .3) { _v.set(p.x + rand(-.5, .5) * this.r, p.y + this.aimY, p.z + rand(-.5, .5) * this.r); G.fx.burst(this.goo ? 'goo' : 'hit', _v, 6, { color: this.goo }); }
    _v.set(p.x, p.y + this.h + .4, p.z); if (kind === 'spray') { this.dotAcc = (this.dotAcc || 0) + dmg; if ((this.dotN = (this.dotN || 0) + 1) % 4 === 0) { G.fx.text(_v, String(this.dotAcc), 'dot'); this.dotAcc = 0; } } else G.fx.text(_v, String(dmg), this.vul > 1 ? 'dmg alert' : 'dmg');
    if (this.onHurt) this.onHurt(dmg, kind); if (this.hp <= 0) this.die(); return true;
  }
  die() { if (this.dead) return; this.dead = true; this.hp = 0; this.t = 0; this.speed = 0; this.body.set('dead'); G.hitstop = .3; G.cam.shake(1.2); G.audio.sfx('boom'); G.audio.sfx('roar'); _v.set(this.pos.x, this.pos.y + this.aimY, this.pos.z); G.fx.burst(this.goo ? 'goo' : 'smoke', _v, 30, { color: this.goo, s: 2 }); G.fx.ring(this.pos, 1, 12, .8, 0xffffff); for (const e of G.ents) if (e.team === 'enemy' && !e.boss && !e.dead && e.die) e.die(); G.game.onKill(this); G.audio.music(null); }
}

// ---------- ТАРАКАНИЙ ЦАРЬ (общага) ----------
export class RoachKing extends Boss {
  constructor(x, y, z) {
    const body = new Spider({ size: 1.45, roach: true, legs: 6, color: 0x4a220e, color2: 0x8a4a1e }); super(x, y, z, { name: 'ТАРАКАНИЙ ЦАРЬ', hp: 330, r: 1.5, h: 1.7, body, goo: 0xb9c94a, bug: true, mass: 8 });
    const crown = new THREE.Group(), gm = M.gold(); const ring = new THREE.Mesh(new THREE.CylinderGeometry(.34, .3, .2, 8, 1, true), gm); crown.add(ring); for (let i = 0; i < 5; i++) { const s = new THREE.Mesh(new THREE.ConeGeometry(.08, .28, 4), gm); const a = i / 5 * TAU; s.position.set(Math.sin(a) * .31, .22, Math.cos(a) * .31); crown.add(s); } crown.position.set(0, .52, .45); crown.traverse(o => o.castShadow = true); body.b.body.add(crown); this.n = 0; this.waves = 0;
  }
  *ai() {
    const P = this.P; yield* this.chase(3.4, rand(1.2, 2.2), 3.4);
    const ph = this.hp / this.maxHp; if ((ph < .66 && this.waves < 1) || (ph < .33 && this.waves < 2)) { this.waves++; this.body.play('cast', 1); G.audio.sfx('screech'); _v.set(this.pos.x, this.pos.y + 3, this.pos.z); G.fx.text(_v, 'ПОДДАННЫЕ!', 'alert'); yield* this.wait(.9); this.summon('roach', 2 + this.waves, 3.5); }
    if (this.dist() < 4.6 && Math.random() < .55) { this.body.play('crouch', .8); yield* this.blast(this.pos.x, this.pos.z, 4.3, .8, 16, { fxc: 0x8a8070 }); yield* this.wait(.7, 4); return; }
    // разгон
    this.body.play('cast', .9); G.audio.sfx('screech'); _v.set(this.pos.x, this.pos.y + 3, this.pos.z); G.fx.text(_v, '!!', 'alert'); yield* this.wait(.85, 9);
    const a = this.toP(), sp = ph < .5 ? 17 : 14; let t = 1.5, hitP = false; this.yaw = a;
    while (t > 0) {
      t -= G.dt; this.vel.x = Math.sin(a) * sp; this.vel.z = Math.cos(a) * sp; this.speed = sp; if (Math.random() < .5) G.fx.burst('dust', this.pos, 1);
      if (!hitP && this.dist() < this.r + P.r + .3 && P.pos.y < this.pos.y + 1.4) { hitP = P.hurt(18, this.pos, 13); }
      if (this.blocked && t < 1.35) { // врезался в стену — оглушён
        this.vel.x = -Math.sin(a) * 4; this.vel.z = -Math.cos(a) * 4; this.speed = 0; G.cam.shake(.9); G.audio.sfx('slam'); G.fx.burst('dust', this.pos, 14, { s: 1.5 }); _v.set(this.pos.x, this.pos.y + 3, this.pos.z); G.fx.text(_v, 'ОГЛУШЁН!', 'good');
        this.vul = 1.7; this.body.set('dead'); yield* this.wait(2.8); this.body.set(null); this.vul = 1; yield* this.wait(.4, 6); return;
      }
      yield;
    }
    this.speed = 0; yield* this.wait(.6, 5);
  }
}
