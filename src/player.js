// Игрок: движение, прыжки, перекат, комбо, броски котлет, дихлофос, «АМ-АМ-АМ»
import * as THREE from 'three';
import { G, damp, dampAng, angDiff, rand, PI, yawTo, wait } from './g.js';
import { makeHuman, makeProp } from './rig.js';
import { photoTex } from './tex.js';
import { FACE } from './faces.js';
import { Shot } from './actors.js';

const GRAV = 26;
const ATK = [
  { a: 'punchR', d: .3, hit: .1, dmg: 12, range: 1.9, lunge: 4.5, knock: 3 },
  { a: 'punchL', d: .3, hit: .1, dmg: 13, range: 1.9, lunge: 4.5, knock: 3 },
  { a: 'kick', d: .52, hit: .2, dmg: 25, range: 2.25, lunge: 6.5, knock: 10, heavy: true }];
const _v = new THREE.Vector3();

export class Player {
  constructor() {
    this.pos = new THREE.Vector3(); this.vel = new THREE.Vector3(); this.safe = new THREE.Vector3(); this.yaw = 0; this.r = .34; this.h = 1.75; this.team = 'player';
    this.rig = makeHuman({ face: photoTex(FACE.ch), top: 0xf7f7f5, pants: 0x1c1e25, shoes: 0xf4f4f4, hair: 0x2a2018, chain: true });
    this.root = this.rig.root; this.can = makeProp('can'); this.can.visible = false; this.rig.hand.add(this.can); this.hp = 100; this.reset();
  }
  reset() {
    this.stamina = 100; this.rage = this.rage || 0; this.charge = 100; this.onGround = true; this.dead = false; this.lock = false; this.inv = 0; this.atk = null; this.combo = 0; this.comboT = 0; this.stagger = 0; this.throwCd = 0;
    this.coyote = 0; this.jbuf = 0; this.rollT = 0; this.wantAtk = 0; this.ultT = 0; this.jumps = 0; this.near = null; this.hspeed = 0; this.sprinting = false; this.slow = 0; this.slip = 0; this.buff = 0; this.exh = false; this.stRest = 0; this.gsolid = null; this.fallV = 0; this.safeT = 0; this.sprayT = 0; this.hitInv = false;
    this.rig.set(null); this.rig.anim = null; this.hidden = false; this.root.visible = true; this.vel.set(0, 0, 0);
  }
  get maxHp() { return 100 + 20 * (G.save.gear.hp || 0); }
  get dmgMul() { return 1 + .25 * (G.save.gear.chain || 0); }
  place(x, y, z, yaw = 0) { this.pos.set(x, y, z); this.vel.set(0, 0, 0); this.yaw = yaw; this.safe.copy(this.pos); this.root.position.copy(this.pos); this.root.rotation.y = yaw; this.onGround = true; }
  face(x, z) { this.yaw = yawTo(this.pos.x, this.pos.z, x, z); }

  update(dt) {
    const inp = G.input, L = G.level, w = L.world, S = G.save, rig = this.rig, pos = this.pos, vel = this.vel;
    const ctl = G.mode === 'play' && !this.dead && !this.lock && this.stagger <= 0 && this.ultT <= 0;
    this.inv -= dt; this.stagger -= dt; this.throwCd -= dt; this.comboT -= dt; this.coyote -= dt; this.jbuf -= dt; this.rollT -= dt; this.wantAtk -= dt; this.buff -= dt; this.slip -= dt; if (this.comboT <= 0) this.combo = 0;
    let wx = 0, wz = 0, wl = 0;
    if (ctl) { const cy = G.cam.yaw, s = Math.sin(cy), c = Math.cos(cy), mx = inp.move.x, my = inp.move.y; wx = -s * my + c * mx; wz = -c * my - s * mx; wl = Math.hypot(wx, wz); if (wl > 1) { wx /= wl; wz /= wl; wl = 1; } }
    if (ctl) {
      if (inp.hit('jump')) this.jbuf = .13;
      if (inp.hit('dodge') && this.rollT <= -.15 && this.stamina >= 18) {
        const a = wl > .2 ? Math.atan2(wx, wz) : this.yaw; this.rdx = Math.sin(a); this.rdz = Math.cos(a); this.yaw = a; this.rollT = .45; this.inv = Math.max(this.inv, .36); this.hitInv = false; this.stamina -= 18; this.stRest = .7; this.atk = null;
        rig.play('roll', .45); G.audio.sfx('whoosh'); G.fx.burst('dust', pos, 4);
      }
      if (inp.hit('attack')) this.wantAtk = .25;
      if (inp.hit('throw')) this.throw();
      if (inp.hit('ult')) this.ult();
      if (inp.hit('interact') && this.near) { const it = this.near; this.near = null; G.audio.sfx('ui'); it.use(it); }
      if (inp.hit('item1')) G.game.quickEat();
      if (this.wantAtk > 0 && (!this.atk || this.atk.t > this.atk.d * .6) && this.rollT <= 0) { this.wantAtk = 0; this.attack(wx, wz, wl); }
    }
    const spraying = ctl && S.gear.spray && inp.held('gadget') && this.charge > 1 && !this.atk && this.rollT <= 0;
    // скорость
    let sp = 4.8; this.sprinting = false;
    if (this.stamina <= 0) this.exh = true; else if (this.stamina > 28) this.exh = false;
    if (ctl && inp.sprint && wl > .3 && (!this.exh || this.buff > 0) && !this.atk && !spraying) { sp = 7.8; this.sprinting = true; if (this.buff <= 0) { this.stamina = Math.max(0, this.stamina - 11 * dt); this.stRest = .6; } }
    this.stRest -= dt; if (this.stRest <= 0) this.stamina = Math.min(100, this.stamina + 26 * dt);
    if (spraying) sp = 2.8; if (this.atk) sp = this.atk.t < this.atk.hit + .1 ? 0 : 1.6; if (this.slow > 0) { sp *= .42; this.slow -= dt; }
    if (this.rollT > 0) { const k = this.rollT / .45, v = 5.5 + 7 * k; vel.x = this.rdx * v; vel.z = this.rdz * v; }
    else if (this.stagger > 0 || this.ultT > 0) { vel.x = damp(vel.x, 0, 6, dt); vel.z = damp(vel.z, 0, 6, dt); }
    else { const acc = this.onGround ? (this.slip > 0 ? 5 : 40) : 13, tx = wx * sp, tz = wz * sp, ax = tx - vel.x, az = tz - vel.z, al = Math.hypot(ax, az), st = acc * dt; if (al <= st) { vel.x = tx; vel.z = tz; } else { vel.x += ax / al * st; vel.z += az / al * st; } }
    if (this.atk && this.atk.face !== undefined) this.yaw = dampAng(this.yaw, this.atk.face, 24, dt);
    else if (spraying) this.yaw = dampAng(this.yaw, G.cam.yaw + PI, 16, dt);
    else if (wl > .1 && this.rollT <= 0) this.yaw = dampAng(this.yaw, Math.atan2(wx, wz), 13, dt);
    // прыжок
    if (this.onGround) { this.coyote = .11; this.jumps = 0; }
    if (this.jbuf > 0 && ctl && this.rollT <= 0) {
      if (this.coyote > 0) { vel.y = 9.3; this.jbuf = 0; this.coyote = 0; this.onGround = false; this.jumps = 1; G.audio.sfx('jump'); G.fx.burst('dust', pos, 3); }
      else if (S.gear.kicks && this.jumps < 2) { vel.y = 8.6; this.jumps = 2; this.jbuf = 0; G.audio.sfx('jump'); G.fx.ring(pos, .2, 1.2, .3, 0x9fe8ff, 0); }
    }
    if (!inp.held('jump') && vel.y > 3.5 && !this.onGround && G.mode === 'play') vel.y -= 34 * dt;
    vel.y = Math.max(-42, vel.y - GRAV * dt);
    // интеграция
    const wasG = this.onGround, hs = Math.hypot(vel.x, vel.z), n = Math.min(4, Math.max(1, Math.ceil(hs * dt / .2))), gs = this.gsolid;
    if (gs && gs.dyn && wasG) { pos.x += gs.vx * dt; pos.z += gs.vz * dt; }
    for (let i = 0; i < n; i++) { pos.x += vel.x * dt / n; pos.z += vel.z * dt / n; w.collide(pos, this.r, this.h); }
    for (const e of G.ents) if (e.solidR && !e.dead) { const dx = pos.x - e.pos.x, dz = pos.z - e.pos.z, rr = e.solidR + this.r, d2 = dx * dx + dz * dz; if (d2 < rr * rr && pos.y < e.pos.y + (e.h || 2) && pos.y + this.h > e.pos.y) { const d = Math.sqrt(d2) || .01; pos.x = e.pos.x + dx / d * rr; pos.z = e.pos.z + dz / d * rr; } }
    const py = pos.y; pos.y += vel.y * dt;
    const cl = w.ceil(pos.x, pos.z, py); if (pos.y + this.h > cl) { pos.y = cl - this.h; if (vel.y > 0) vel.y = 0; }
    const g = w.ground(pos.x, pos.z, Math.max(py, pos.y)); this.gsolid = w.gs;
    if (pos.y <= g + .001 && vel.y <= 0) { if (!wasG && vel.y < -9) { G.audio.sfx('land', Math.min(1.6, -vel.y / 14)); G.fx.burst('dust', pos, 5); } pos.y = g; vel.y = 0; this.onGround = true; }
    else if (wasG && vel.y <= 0 && pos.y - g < .5) { pos.y = g; vel.y = 0; this.onGround = true; }
    else this.onGround = false;
    if (pos.y < w.killY || (L.hazard && L.hazard(pos))) this.respawnSafe();
    else if (this.onGround && !(this.gsolid && this.gsolid.dyn) && (!L.unsafe || !L.unsafe(pos))) { this.safeT -= dt; if (this.safeT <= 0) { this.safeT = .35; this.safe.copy(pos); } }
    // атака
    if (this.atk) { const A = this.atk; A.t += dt; if (!A.done && A.t >= A.hit) { A.done = true; this.strike(A); } if (A.t >= A.d) this.atk = null; }
    // дихлофос
    if (spraying) {
      this.charge = Math.max(0, this.charge - 24 * dt); this.sprayT -= dt; rig.set('spray'); this.can.visible = true;
      if (this.sprayT <= 0) {
        this.sprayT = .09; G.audio.sfx('spray'); const fx = Math.sin(this.yaw), fz = Math.cos(this.yaw);
        for (let i = 0; i < 2; i++) { const a = this.yaw + rand(-.3, .3), s = rand(7, 11); G.fx.soft.emit(pos.x + fx * .7, pos.y + 1.25, pos.z + fz * .7, Math.sin(a) * s, rand(-.6, .8), Math.cos(a) * s, rand(.35, .5), .25, 1.5, .62, .95, .45, .5, 0, 2.2); }
        for (const e of G.ents) { if (!e.hurt || e.dead || e.team === 'player') continue; const dx = e.pos.x - pos.x, dz = e.pos.z - pos.z, d = Math.hypot(dx, dz) - (e.r || .4); if (d > 4.6 || Math.abs(e.pos.y - pos.y) > 2.5) continue; if (Math.abs(angDiff(this.yaw, Math.atan2(dx, dz))) > .62 && d > .4) continue; e.hurt(Math.round((e.bug ? 5 : 2) * this.dmgMul), pos, e.bug ? 1.5 : .3, 'spray'); }
      }
    } else { if (rig.base === 'spray') rig.set(null); this.can.visible = false; this.charge = Math.min(100, this.charge + 10 * dt); }
    // ульта
    if (this.ultT > 0) {
      this.ultT -= dt; const k = 1 - this.ultT, want = k > .62 ? 3 : k > .34 ? 2 : k > .06 ? 1 : 0;
      if (want > this.ultN) {
        this.ultN = want; G.audio.vox(0, 158 - want * 9, 1.3); G.fx.ring(pos, .6, 9, .5, 0xffd24a); G.cam.shake(.8); G.cam.kick = 5; _v.set(pos.x, pos.y + 2.3, pos.z); G.fx.text(_v, 'АМ!', 'ult');
        for (const e of G.ents) { if (!e.hurt || e.dead || e.team === 'player') continue; if (Math.hypot(e.pos.x - pos.x, e.pos.z - pos.z) - (e.r || .4) < 9) { e.hurt(Math.round(17 * this.dmgMul), pos, 9, 'ult'); if (e.stunnable !== false) e.stun = Math.max(e.stun || 0, 2.2); } }
      }
    }
    // визуал
    this.hspeed = Math.hypot(vel.x, vel.z); this.root.position.copy(pos); this.root.rotation.y = this.yaw;
    rig.update(dt, this.onGround ? this.hspeed : 0, this.onGround ? 0 : (vel.y > 0 ? 1 : -1));
    if (this.onGround && this.hspeed > 1.5) { const ph = Math.floor(rig.phase / PI); if (ph !== this.lastPh) { this.lastPh = ph; G.audio.sfx('step', this.sprinting ? 1.4 : 1); if (this.sprinting) G.fx.burst('dust', pos, 1, { s: .6 }); } }
    this.root.visible = !this.hidden && !(this.inv > 0 && this.hitInv && (G.time * 18 | 0) % 2);
    // интерактив рядом
    this.near = null;
    if (ctl) { let best = 1e9; for (const it of L.inter) { if (it.off || (it.cond && !it.cond())) continue; const dx = it.pos.x - pos.x, dz = it.pos.z - pos.z, d = Math.hypot(dx, dz); if (d < it.r && d < best && Math.abs(it.pos.y - pos.y - .9) < 2.4) { best = d; this.near = it; } } }
  }
  attack(wx, wz, wl) {
    const A = { ...ATK[this.combo % 3], t: 0, done: false }, pos = this.pos; this.combo++; this.comboT = .85;
    let dir = wl > .2 ? Math.atan2(wx, wz) : this.yaw, best = null, bd = 4.4;
    for (const e of G.ents) { if (e.team !== 'enemy' || e.dead || e.noAim) continue; const d = Math.hypot(e.pos.x - pos.x, e.pos.z - pos.z) - e.r; if (d > bd || Math.abs(e.pos.y - pos.y) > 3) continue; if (Math.abs(angDiff(dir, yawTo(pos.x, pos.z, e.pos.x, e.pos.z))) < (wl > .2 ? 1.25 : 2.4)) { bd = d; best = e; } }
    if (best) dir = yawTo(pos.x, pos.z, best.pos.x, best.pos.z); A.face = dir;
    const lunge = best ? Math.min(A.lunge, Math.max(0, bd - .7) * 10) : A.lunge * .55; this.vel.x = Math.sin(dir) * lunge; this.vel.z = Math.cos(dir) * lunge;
    this.atk = A; this.rig.play(A.a, A.d); G.audio.sfx('whoosh');
  }
  strike(A) {
    const pos = this.pos; let hit = 0;
    for (const e of G.ents) {
      if (!e.hurt || e.dead || e.team === 'player') continue; const dx = e.pos.x - pos.x, dz = e.pos.z - pos.z, d = Math.hypot(dx, dz) - (e.r || .4);
      if (d > A.range || pos.y > e.pos.y + (e.h || 1) + .6 || pos.y + this.h < e.pos.y - .6) continue; if (Math.abs(angDiff(A.face, Math.atan2(dx, dz))) > 1.3 && d > .5) continue;
      if (e.hurt(Math.round(A.dmg * this.dmgMul * rand(.9, 1.15)), pos, A.knock, 'melee')) { hit++; if (e.team === 'enemy') this.addRage(A.heavy ? 8 : 5); }
    }
    if (hit) { G.hitstop = A.heavy ? .09 : .05; G.cam.shake(A.heavy ? .55 : .25); G.audio.sfx(A.heavy ? 'hit2' : 'hit'); }
  }
  addRage(v) { if (!G.save.gear.ult) return; const was = this.rage; this.rage = Math.min(100, this.rage + v); if (was < 100 && this.rage >= 100) { G.audio.sfx('power'); G.ui.toast('😱 Ярость накоплена — жми «АМ-АМ-АМ»!', 'hint'); } }
  throw() {
    if (this.throwCd > 0 || this.atk || this.rollT > 0) return; this.throwCd = .42; const S = G.save, cash = S.money >= 2, pos = this.pos, cam = G.gfx.camera; if (cash) S.money -= 2;
    const f = cam.getWorldDirection(_v), fy = Math.atan2(f.x, f.z); let best = null, bs = .5;
    for (const e of G.ents) { if (e.team !== 'enemy' || e.dead || e.noAim) continue; const d = Math.hypot(e.pos.x - pos.x, e.pos.z - pos.z); if (d > 30) continue; const a = Math.abs(angDiff(fy, yawTo(pos.x, pos.z, e.pos.x, e.pos.z))) + d * .006; if (a < bs) { bs = a; best = e; } }
    const ox = pos.x, oy = pos.y + 1.35, oz = pos.z; let tx, ty, tz;
    if (best) { tx = best.pos.x; ty = best.pos.y + (best.aimY ?? (best.h || 1) * .55); tz = best.pos.z; } else { tx = cam.position.x + f.x * 32; ty = cam.position.y + f.y * 32 + 1; tz = cam.position.z + f.z * 32; }
    const dx = tx - ox, dy = ty - oy, dz = tz - oz, dl = Math.hypot(dx, dz) || 1, v = 26, t = dl / v, gr = 7; this.yaw = Math.atan2(dx, dz); this.rig.play('throw', .36); G.audio.sfx('throw');
    G.run(function* () { yield* wait(.11); G.game.spawn(new Shot({ x: ox + dx / dl * .5, y: oy, z: oz + dz / dl * .5, vx: dx / dl * v, vy: Math.max(-14, Math.min(16, dy / t + .5 * gr * t)), vz: dz / dl * v, team: 'player', dmg: Math.round((cash ? 11 : 6) * G.player.dmgMul), kind: cash ? 'cash' : 'slipper', grav: gr, knock: 3 })); });
  }
  ult() {
    if (!G.save.gear.ult || this.ultT > 0) return; if (this.rage < 100) { G.audio.sfx('deny'); return; }
    this.rage = 0; this.ultT = 1; this.ultN = 0; this.inv = 1.4; this.hitInv = false; this.atk = null; this.rig.play('cheer', 1);
  }
  hurt(dmg, from, knock = 6) {
    if (this.inv > 0 || this.dead || G.mode !== 'play' || G.god) return false; dmg = Math.max(1, Math.round(dmg * (G.settings.easy ? .55 : 1)));
    this.hp -= dmg; this.inv = .8; this.hitInv = true; this.stagger = .22; this.atk = null; this.rollT = Math.min(this.rollT, 0);
    if (from) { const a = yawTo(from.x, from.z, this.pos.x, this.pos.z); this.vel.x = Math.sin(a) * knock; this.vel.z = Math.cos(a) * knock; } if (this.onGround) { this.vel.y = 3.2; this.onGround = false; }
    this.rig.play('hit', .28); this.rig.flash(1); G.cam.shake(.6); G.ui.hurt(); G.audio.sfx('hurt'); _v.set(this.pos.x, this.pos.y + 2.1, this.pos.z); G.fx.text(_v, '−' + dmg, 'bad'); this.addRage(4);
    if (this.hp <= 0) { this.hp = 0; this.dead = true; this.rig.set('dead'); G.game.onDeath(); }
    return true;
  }
  heal(n) { const was = this.hp; this.hp = Math.min(this.maxHp, this.hp + n); G.fx.burst('heal', this.pos, 10); _v.set(this.pos.x, this.pos.y + 2.1, this.pos.z); if (this.hp > was) G.fx.text(_v, '+' + Math.round(this.hp - was), 'good'); }
  respawnSafe() {
    this.pos.copy(this.safe); this.vel.set(0, 0, 0); this.inv = 1.5; this.hitInv = true; this.onGround = true; if (G.mode === 'play' && !G.god) { this.hp = Math.max(1, this.hp - 10); G.ui.hurt(); G.audio.sfx('splash'); }
    G.cam.tgt.set(this.pos.x, this.pos.y + 1.45, this.pos.z);
  }
}
