// Акторы: снаряды, подбираемые предметы, ящики, NPC, враги
import * as THREE from 'three';
import { G, damp, dampAng, angDiff, rand, pick, PI, TAU, yawTo, clamp } from './g.js';
import { makeHuman, Spider, Blob, Wisp, makeProp } from './rig.js';
import { memo, glowTex, faceTex, photoTex, cv, tex, M, C, glowMat } from './tex.js';
import { ITEMS, inv } from './items.js';

const _v = new THREE.Vector3(), BOX = new THREE.BoxGeometry(1, 1, 1), SPH = new THREE.SphereGeometry(1, 10, 8), CYL = new THREE.CylinderGeometry(1, 1, 1, 12);
export const GRAV = 26;
const EMO = '"Apple Color Emoji","Segoe UI Emoji","Noto Color Emoji","Twemoji Mozilla",sans-serif';
export const iconTex = e => memo('ico' + e, () => { const c = cv(96), g = c.getContext('2d'); g.font = `70px ${EMO}`; g.textAlign = 'center'; g.textBaseline = 'middle'; g.fillText(e, 48, 54); return tex(c, { rep: false }); });
const markTex = ch => memo('mark' + ch, () => { const c = cv(64), g = c.getContext('2d'); g.font = 'bold 56px Arial,sans-serif'; g.textAlign = 'center'; g.textBaseline = 'middle'; g.lineWidth = 9; g.strokeStyle = '#1a1200'; g.strokeText(ch, 32, 35); g.fillStyle = ch === '!' ? '#ffd21f' : '#8fe3ff'; g.fillText(ch, 32, 35); return tex(c, { rep: false }); });
const sprite = (t, s, o = {}) => { const m = new THREE.Sprite(new THREE.SpriteMaterial({ map: t, transparent: true, depthWrite: false, ...o })); m.scale.setScalar(s); return m; };
const mesh = (g, m, sx, sy, sz, x = 0, y = 0, z = 0) => { const o = new THREE.Mesh(g, m); o.scale.set(sx, sy, sz); o.position.set(x, y, z); o.castShadow = true; return o; };

export class Actor {
  constructor(x = 0, y = 0, z = 0) { this.pos = new THREE.Vector3(x, y, z); this.vel = new THREE.Vector3(); this.yaw = 0; this.r = .4; this.h = 1.6; this.dead = false; this.gone = false; this.root = null; this.onGround = false; this.step = .45; }
  update() { }
  sync() { this.root.position.copy(this.pos); this.root.rotation.y = this.yaw; }
  physics(dt, grav = GRAV) {
    const w = G.level.world, p = this.pos, v = this.vel, py = p.y; v.y = Math.max(-40, v.y - grav * dt); p.x += v.x * dt; p.z += v.z * dt; p.y += v.y * dt;
    const hit = w.collide(p, this.r, this.h, this.step), g = w.ground(p.x, p.z, Math.max(py, p.y), this.step);
    if (p.y <= g + .001 && v.y <= 0) { p.y = g; v.y = 0; this.onGround = true; } else if (this.onGround && v.y <= 0 && p.y - g < .5) { p.y = g; v.y = 0; } else this.onGround = false;
    if (p.y < w.killY) this.gone = true; return hit;
  }
  dispose() { if (this.body) this.body.dispose(); else if (this.root) this.root.removeFromParent(); }
}

// ---------- снаряд ----------
export class Shot extends Actor {
  constructor(o) {
    super(o.x, o.y, o.z); Object.assign(this, { team: 'enemy', dmg: 8, r: .25, grav: 0, life: 3, knock: 5, kind: 'orb', color: 0xb070ff }, o); this.vel.set(o.vx, o.vy, o.vz); const k = this.kind, g = this.root = new THREE.Group();
    if (k === 'cash') { g.add(mesh(BOX, C(0x4f9a4a, .8), .3, .1, .17), mesh(BOX, C(0xf2efe2, .8), .09, .11, .18)); this.tc = 0x8dff8a; }
    else if (k === 'slipper') { g.add(mesh(BOX, C(0x7a5236, .8), .13, .06, .32)); this.tc = 0xd8c0a0; }
    else if (k === 'web') { g.add(mesh(SPH, C(0xf2f2f2, .9), .3, .3, .3)); this.tc = 0xffffff; this.r = .35; }
    else if (k === 'box') { g.add(mesh(BOX, C(0xb98a55, .9), .5, .4, .5)); this.r = .4; }
    else if (k === 'soap') { g.add(mesh(BOX, C(0xff9ed0, .25), .55, .25, .36)); this.tc = 0xffffff; this.r = .45; }
    else if (k === 'tub') { g.add(mesh(CYL, M.planks(), .38, .3, .38)); this.r = .45; }
    else { g.add(mesh(SPH, glowMat(this.color, 3), this.r, this.r, this.r), sprite(glowTex(), this.r * 6, { color: this.color, blending: THREE.AdditiveBlending, opacity: .7 })); this.tc = this.color; g.children[0].castShadow = false; }
    this.sync(); this.tt = 0;
  }
  update(dt) {
    const p = this.pos, v = this.vel; this.life -= dt; if (this.life <= 0) { this.gone = true; return; }
    v.y -= this.grav * dt; p.addScaledVector(v, dt); this.root.position.copy(p); this.root.rotation.x += dt * 9; this.root.rotation.y += dt * 13;
    if (this.home && !G.player.dead) { const t = G.player.pos, a = yawTo(p.x, p.z, t.x, t.z), s = Math.hypot(v.x, v.z), cur = Math.atan2(v.x, v.z), n = cur + clamp(angDiff(cur, a), -this.home * dt, this.home * dt); v.x = Math.sin(n) * s; v.z = Math.cos(n) * s; }
    this.tt -= dt; if (this.tc && this.tt <= 0) { this.tt = .03; G.fx.trail(p, this.tc, this.r * 1.3); }
    const w = G.level.world; if (w.inside(p.x, p.y, p.z)) return this.pop(false);
    if (this.team === 'player') {
      for (const e of G.ents) { if (!e.hurt || e.dead || e.team === 'player') continue; const dx = e.pos.x - p.x, dz = e.pos.z - p.z, rr = (e.r || .4) + this.r; if (dx * dx + dz * dz > rr * rr || p.y < e.pos.y - .3 || p.y > e.pos.y + (e.h || 1) + .4) continue; _v.copy(p).addScaledVector(v, -.05); if (e.hurt(this.dmg, _v, this.knock, 'shot')) { if (e.team === 'enemy') G.player.addRage(3); G.audio.sfx('hit'); } return this.pop(true); }
    } else {
      const P = G.player, dx = P.pos.x - p.x, dz = P.pos.z - p.z, rr = P.r + this.r; if (dx * dx + dz * dz < rr * rr && p.y > P.pos.y - .2 && p.y < P.pos.y + P.h + .2) { _v.copy(p).addScaledVector(v, -.05); if (P.hurt(this.dmg, _v, this.knock) && this.onHit) this.onHit(P); return this.pop(true); }
    }
  }
  pop(hit) {
    this.gone = true; const k = this.kind, p = this.pos;
    if (k === 'cash') { G.fx.burst('cash', p, 7); G.audio.sfx('cash'); } else if (k === 'web') G.fx.burst('dust', p, 6, { color: 0xffffff }); else if (k === 'soap') { G.fx.burst('bub', p, 8); G.audio.sfx('bubble'); } else if (k === 'box' || k === 'tub' || k === 'slipper') G.fx.burst('dust', p, 5, { color: 0xb98a55 }); else G.fx.burst('magic', p, 8, { color: this.color });
    if (this.onPop) this.onPop(this, hit);
  }
}

// ---------- подбираемое ----------
export class Pickup extends Actor {
  // o: money | item (+n) | fid (флаг сохранения) | pop (вылет из врага/ящика)
  constructor(x, y, z, o = {}) {
    super(x, y, z); this.o = o; this.r = .2; this.h = .4; this.t = rand(6); this.wait = o.pop ? .45 : 0; const g = this.root = new THREE.Group(), s = this.spin = new THREE.Group(); g.add(s);
    if (o.money) { const big = o.money >= 20; s.add(mesh(BOX, C(big ? 0xffc530 : 0x4f9a4a, big ? .3 : .8, big ? 1 : 0), .34, .12, .19, 0, .32, 0), mesh(BOX, C(0xf2efe2, .8), .1, .13, .2, 0, .32, 0)); }
    else { const it = ITEMS[o.item]; s.add(sprite(iconTex(it.i), .62)); s.children[0].position.y = .55; const gl = sprite(glowTex(), 1.5, { color: it.t === 'food' ? 0x9dff9a : 0xffd45a, blending: THREE.AdditiveBlending, opacity: .55 }); gl.position.y = .5; g.add(gl); }
    if (o.pop) { const a = rand(TAU), sp = rand(1.5, 4); this.vel.set(Math.sin(a) * sp, rand(4, 7), Math.cos(a) * sp); } else this.onGround = true;
    this.sync();
  }
  update(dt) {
    const p = this.pos, P = G.player; this.t += dt; this.wait -= dt;
    if (!this.onGround || this.vel.y > 0) { this.physics(dt); if (this.onGround) this.vel.set(0, 0, 0); }
    const dx = P.pos.x - p.x, dy = P.pos.y + .8 - p.y, dz = P.pos.z - p.z, d = Math.hypot(dx, dy, dz);
    if (this.wait <= 0 && !P.dead) {
      if (d < (this.o.money ? 3 : 1.6) && d > .01) { const s = (this.o.money ? 11 : 6) * dt / d; p.x += dx * s; p.y += dy * s; p.z += dz * s; this.onGround = true; }
      if (d < .75) return this.take();
    }
    this.root.position.set(p.x, p.y + Math.sin(this.t * 3) * .07, p.z); this.spin.rotation.y = this.t * 2.5;
  }
  take() {
    this.gone = true; const o = this.o;
    if (o.money) { G.save.money += o.money; G.save.earned = (G.save.earned || 0) + o.money; G.audio.sfx('coin'); _v.set(this.pos.x, this.pos.y + .6, this.pos.z); G.fx.text(_v, '+' + o.money + '₽', 'cash'); } else { inv.add(o.item, o.n || 1); G.fx.burst('heal', this.pos, 6, { color: 0xffe08a }); }
    if (o.fid) G.save.flags[o.fid] = 1; if (o.onTake) o.onTake();
  }
}

// ---------- ящик / бочка ----------
export class Crate extends Actor {
  constructor(x, y, z, o = {}) {
    super(x, y, z); this.o = o; const s = this.s = o.s || 1; this.r = .55 * s; this.h = s; this.team = 'prop'; this.breakable = true; this.noAim = true; this.hp = o.hp || 1; this.yaw = o.yaw ?? rand(-.3, .3);
    this.root = new THREE.Group(); const m = mesh(BOX, o.mat || M.planks(), s, s, s, 0, s / 2, 0); m.receiveShadow = true; this.root.add(m);
    for (const sx of [-1, 1]) this.root.add(mesh(BOX, C(0x6b4a2a, .9), .08 * s, s * 1.02, s * 1.02, sx * .4 * s, s / 2, 0));
    this.col = G.level.world.mover(x, y + s / 2, z, s, s, s, this.yaw); this.sync();
  }
  hurt() {
    if (this.dead) return false; if (--this.hp > 0) { G.fx.burst('dust', this.pos, 3, { color: 0xb98a55 }); return true; }
    this.dead = this.gone = true; this.col.off = true; _v.set(this.pos.x, this.pos.y + this.s / 2, this.pos.z); G.fx.burst('dust', _v, 9, { color: 0xb98a55, s: 1.2 }); G.fx.burst('spark', _v, 6, { color: 0xc99a60 }); G.audio.sfx('land', 1.5);
    const o = this.o; if (o.fid) G.save.flags[o.fid] = 1;
    if (o.item) G.game.spawn(new Pickup(_v.x, _v.y, _v.z, { item: o.item, pop: 1, fid: o.ifid }));
    else { const r = Math.random(); if (r < .14) G.game.spawn(new Pickup(_v.x, _v.y, _v.z, { item: pick(['bread', 'banana', 'doshik']), pop: 1 })); G.game.drop(_v, o.money ?? (r < .8 ? (2 + Math.random() * 7 | 0) : 0)); }
    return true;
  }
}

// ---------- NPC ----------
export class NPC extends Actor {
  // o: look{}, name, yaw, anim, talk(generator*), label, mark, r, solid
  constructor(x, y, z, o = {}) {
    super(x, y, z); this.o = o; this.name = o.name; this.yaw = this.yaw0 = o.yaw || 0; this.body = o.body || makeHuman(o.look || {}); this.root = this.body.root; this.h = this.body.h; this.solidR = o.solid === false ? 0 : .42 * (this.body.scale || 1); if (o.anim) this.body.set(o.anim);
    if (o.talk) this.it = G.level.interact(0, 0, 0, o.r || 2.6, o.label || 'Поговорить', () => G.game.talk(this), { npc: this }), this.it.pos = this.pos;
    this.setMark(o.mark); this.sync(); this.speed = 0; this.path = null;
  }
  setMark(ch) { if (this.mark) { this.root.remove(this.mark); this.mark = null; } if (ch) { this.mark = sprite(markTex(ch), .55, { depthTest: false }); this.mark.position.y = this.h + .55; this.mark.renderOrder = 30; this.root.add(this.mark); } }
  // идти в точку (для кат-сцен)
  *walkTo(x, z, sp = 3.2) { while (Math.hypot(x - this.pos.x, z - this.pos.z) > .25) { const a = yawTo(this.pos.x, this.pos.z, x, z); this.yaw = dampAng(this.yaw, a, 10, G.dt); this.pos.x += Math.sin(a) * sp * G.dt; this.pos.z += Math.cos(a) * sp * G.dt; this.pos.y = G.level.world.ground(this.pos.x, this.pos.z, this.pos.y + .3); this.speed = sp; this.walking = true; yield; } this.speed = 0; this.walking = false; }
  update(dt) {
    const P = G.player, d = Math.hypot(P.pos.x - this.pos.x, P.pos.z - this.pos.z);
    if (!this.walking && !this.o.still) { const want = d < 5 && !this.o.noLook ? yawTo(this.pos.x, this.pos.z, P.pos.x, P.pos.z) : this.yaw0; this.yaw = dampAng(this.yaw, want, 5, dt); }
    if (this.mark) { this.mark.position.y = this.h + .55 + Math.sin(G.time * 4) * .06; this.mark.visible = d < 40; }
    this.sync(); this.body.update(dt, this.speed, 0);
  }
}

// ---------- враги ----------
const HUM = { fat: 1, sleeve: 'long' };
export const EN = {
  roach: { name: 'Таракан', hp: 24, sp: 3.9, dmg: 6, r: .42, h: .55, reach: .95, aggro: 12, cd: .9, wind: .28, bug: 1, goo: 0xb9c94a, money: [1, 3], mass: .7, make: () => new Spider({ size: .36, roach: true, legs: 6, color: 0x5a2e14, color2: 0x7a4420 }) },
  spider: { name: 'Паучность', hp: 62, sp: 4.5, dmg: 12, r: .85, h: 1.1, reach: 1.5, aggro: 18, cd: 1.3, wind: .42, leap: 1, bug: 1, goo: 0x9ed63a, money: [4, 8], mass: 1.3, make: () => new Spider({ size: .72 }) },
  spiderling: { name: 'Паучёнок', hp: 16, sp: 5.4, dmg: 6, r: .42, h: .5, reach: .9, aggro: 40, cd: .9, wind: .25, bug: 1, goo: 0x9ed63a, money: [0, 2], mass: .6, make: () => new Spider({ size: .3, color: 0x3a2a22, color2: 0x8a6a3e }) },
  spitter: { name: 'Плевака', hp: 46, sp: 3.3, dmg: 10, r: .7, h: 1, aggro: 20, ranged: 'web', keep: 9, range: 16, cd: 2.2, wind: .5, bug: 1, goo: 0x9ed63a, money: [5, 9], make: () => new Spider({ size: .58, color: 0x2a3a1c, color2: 0x7a9a3e }) },
  slime: { name: 'Пакость', hp: 38, sp: 3.3, dmg: 9, r: .5, h: .9, reach: 1.15, aggro: 14, cd: 1.2, wind: .35, leap: 1, goo: 0x8a6ad0, money: [3, 7], make: () => new Blob({}) },
  snowy: { name: 'Снежная пакость', hp: 44, sp: 3.5, dmg: 10, r: .5, h: .9, reach: 1.15, aggro: 15, cd: 1.2, wind: .35, leap: 1, goo: 0xffffff, money: [4, 8], make: () => new Blob({ color: 0xe8f2fa, eye: 0x6fd0ff }) },
  wisp: { name: 'Туманник', hp: 24, sp: 2.8, dmg: 9, r: .45, h: 1.9, fly: 1, touch: 1, aggro: 17, cd: 1, goo: 0xdfe6ee, money: [2, 5], mass: .6, make: () => new Wisp({}) },
  steam: { name: 'Парной дух', hp: 30, sp: 3.2, dmg: 10, r: .45, h: 1.9, fly: 1, touch: 1, aggro: 18, cd: 1, goo: 0xffffff, money: [3, 6], mass: .6, make: () => new Wisp({ color: 0xfff0e0, em: 0xff9a5a, emK: .6 }) },
  bubble: { name: 'Пузырь', hp: 12, sp: 3.4, dmg: 8, r: .45, h: 1.9, fly: 1, touch: 1, popper: 1, aggro: 18, cd: 1, goo: 0xdff6ff, money: [1, 3], mass: .4, make: () => new Wisp({ bubble: true }) },
  courier: { name: 'Одичавший курьер', hp: 52, sp: 4, dmg: 9, r: .4, h: 1.8, aggro: 18, ranged: 'box', keep: 8, range: 14, cd: 2, wind: .45, human: 1, money: [6, 12], make: () => makeHuman({ face: faceTex({ mood: 'angry' }), top: 0xffd400, sleeve: 'long', pants: 0x222222, hairStyle: 'cap', capColor: 0xffd400, pack: 0xffd400 }) },
  gop: { name: 'Гопник', hp: 64, sp: 4.4, dmg: 11, r: .4, h: 1.8, reach: 1.25, aggro: 15, cd: 1.1, wind: .34, human: 1, money: [6, 12], make: () => makeHuman({ face: faceTex({ mood: 'angry', skin: '#d8a888' }), top: 0x1c2a5a, sleeve: 'long', pants: 0x1c2a5a, hairStyle: 'cap', capColor: 0x222222, skin: 0xd8a888 }) },
  myt: { name: 'Мыть', hp: 58, sp: 4.2, dmg: 12, r: .45, h: 1.8, reach: 1.3, aggro: 16, cd: 1.2, wind: .36, human: 1, goo: 0xa8dcff, money: [7, 13], make: () => makeHuman({ face: faceTex({ mood: 'happy', skin: '#f2d2c0', blush: 1 }), top: 0xdff4ff, sleeve: 'long', pants: 0x7fd0f0, shoes: 0xffffff, hair: 0xf4e7a0, skin: 0xf2d2c0 }) },
  banshik: { name: 'Парильщик', hp: 80, sp: 4, dmg: 13, r: .45, h: 1.8, reach: 1.6, aggro: 16, cd: 1.3, wind: .4, human: 1, money: [8, 15], make: () => { const h = makeHuman({ face: faceTex({ mood: 'angry', skin: '#e8a090', blush: 1 }), top: 0xe9dfc8, style: 'robe', sleeve: 'none', hairStyle: 'banya', fat: 1.25, skin: 0xe8a090 }); h.hand.add(makeProp('broom')); return h; } },
};
export class Enemy extends Actor {
  constructor(kind, x, y, z, o = {}) {
    super(x, y, z); const c = this.c = { ...EN[kind], ...o }; this.kind = kind; this.team = 'enemy'; this.hp = this.maxHp = c.hp; this.r = c.r; this.h = c.h; this.bug = c.bug; this.name = c.name;
    this.body = c.make(); this.root = this.body.root; if (c.scale) this.root.scale.setScalar(c.scale); this.home = this.pos.clone(); this.state = o.alert ? 'chase' : 'idle'; this.t = rand(1, 3); this.cd = rand(.4, 1.4); this.stun = 0; this.stag = 0; this.yaw = o.yaw ?? rand(TAU);
    this.aimY = c.fly ? 1.3 : c.h * .55; this.wdir = rand(TAU); this.side = 0; this.sideT = 0; this.dotN = 0; this.dotAcc = 0; this.losT = rand(.3); this.tcd = 0; if (c.fly) this.step = 1.2; this.sync();
  }
  steer(a, sp, dt, acc = 16) { const tx = Math.sin(a) * sp, tz = Math.cos(a) * sp, v = this.vel, k = Math.min(1, acc * dt / (Math.hypot(tx - v.x, tz - v.z) || 1)); v.x += (tx - v.x) * k; v.z += (tz - v.z) * k; }
  update(dt) {
    const c = this.c, p = this.pos, v = this.vel, P = G.player, w = G.level.world, body = this.body;
    if (this.dead) { this.t += dt; if (!c.fly) this.physics(dt); v.x *= .9; v.z *= .9; if (this.t > 1) this.root.scale.multiplyScalar(Math.max(0, 1 - 5 * dt)); if (this.t > 1.5) this.gone = true; this.sync(); body.update(dt, 0, 0); return; }
    const dx = P.pos.x - p.x, dz = P.pos.z - p.z, d = Math.hypot(dx, dz), toP = Math.atan2(dx, dz), frozen = G.mode !== 'play' || P.dead; let sp = 0, face = null;
    this.cd -= dt; this.stag -= dt; this.tcd -= dt; this.sideT -= dt;
    if (this.stun > 0) { this.stun -= dt; this.state = this.state === 'idle' ? 'idle' : 'chase'; if ((G.time * 6 | 0) % 2) body.flash(.25); }
    else if (frozen || this.stag > 0) { if (this.state === 'wind') this.state = 'chase'; }
    else switch (this.state) {
      case 'idle': {
        this.t -= dt; if (this.t <= 0) { this.t = rand(1.5, 4); this.wdir = Math.hypot(p.x - this.home.x, p.z - this.home.z) > 4 ? yawTo(p.x, p.z, this.home.x, this.home.z) : rand(TAU); this.walk = Math.random() < .6; }
        if (this.walk) { sp = c.sp * .3; face = this.wdir; }
        this.losT -= dt; if (d < c.aggro && this.losT <= 0 && Math.abs(P.pos.y - p.y) < 6) { this.losT = .3; const dy = P.pos.y + 1 - (p.y + this.aimY), dl = Math.hypot(d, dy); if (d < 4 || w.ray(p.x, p.y + this.aimY, p.z, dx / dl, dy / dl, dz / dl, dl) >= dl - .3) this.alert(); }
        break;
      }
      case 'chase': {
        face = toP; let a = toP; if (this.sideT > 0) a += this.side * 1.2;
        if (c.ranged) { sp = d > c.keep + 2 ? c.sp : d < c.keep - 2 ? -c.sp * .8 : 0; if (!sp) { a = toP + PI / 2 * (this.side || (this.side = Math.random() < .5 ? 1 : -1)); sp = c.sp * .45; } else if (sp < 0) { a = toP + PI; sp = -sp; } if (this.cd <= 0 && d < c.range) { this.state = 'wind'; this.t = c.wind; body.play('cast', c.wind + .2); } }
        else if (c.touch) { sp = c.sp; }
        else {
          sp = d > c.reach * .8 + P.r ? c.sp : 0;
          if (this.cd <= 0 && Math.abs(P.pos.y - p.y) < 2) { if (d < c.reach + P.r + .15) { this.state = 'wind'; this.t = c.wind; this.leaping = false; body.play(c.human ? 'crouch' : 'cast', c.wind); body.flash(.5); } else if (c.leap && d > 3 && d < 7 && Math.random() < dt * 2.2) { this.state = 'wind'; this.t = c.wind + .12; this.leaping = true; body.play('crouch', this.t); body.flash(.6); } }
        }
        if (d > c.aggro * 2.6 && !c.relentless) { this.state = 'idle'; this.t = 1; }
        this.face2 = a; break;
      }
      case 'wind': {
        face = toP; this.t -= dt; if (this.t > 0) break;
        if (c.ranged) { this.shoot(d); this.state = 'chase'; this.cd = c.cd * rand(.8, 1.3); this.side = -this.side; }
        else if (this.leaping) { const T = .5, k = Math.min(1, (d - .3) / T / 13); v.x = Math.sin(toP) * 13 * k; v.z = Math.cos(toP) * 13 * k; v.y = GRAV * T / 2 + Math.max(0, P.pos.y - p.y) * 2; this.onGround = false; this.state = 'air'; this.hitDone = false; G.audio.sfx('whoosh'); }
        else { if (c.human) body.play('punchR', .3); else body.play('hit', .2); if (d < c.reach + P.r + .6 && Math.abs(angDiff(this.yaw, toP)) < 1.2 && Math.abs(P.pos.y - p.y) < 2) P.hurt(c.dmg, p, 6); this.state = 'rec'; this.t = .35; this.cd = c.cd * rand(.8, 1.3); G.audio.sfx('whoosh'); }
        break;
      }
      case 'air': if (!this.hitDone && d < this.r + P.r + .25 && Math.abs(P.pos.y - p.y) < 1.6) { this.hitDone = true; P.hurt(Math.round(c.dmg * 1.2), p, 8); } if (this.onGround && v.y <= 0) { this.state = 'rec'; this.t = .5; this.cd = c.cd; G.fx.burst('dust', p, 4); } break;
      case 'rec': this.t -= dt; if (this.t <= 0) this.state = 'chase'; break;
    }
    // движение
    if (this.state !== 'air') { if (sp > 0) this.steer(this.state === 'chase' ? this.face2 : face, sp, dt); else { v.x = damp(v.x, 0, 8, dt); v.z = damp(v.z, 0, 8, dt); } }
    if (c.touch && !frozen && this.stun <= 0 && this.tcd <= 0 && d < this.r + P.r + .3 && Math.abs(P.pos.y - p.y) < 1.7) { this.tcd = c.cd; if (P.hurt(c.dmg, p, 7)) { v.x = -Math.sin(toP) * 6; v.z = -Math.cos(toP) * 6; } if (c.popper) return this.die(); }
    const px = p.x, pz = p.z; let hit;
    if (c.fly) { p.x += v.x * dt; p.z += v.z * dt; hit = w.collide(p, this.r, 1, 1.2); const g = w.ground(p.x, p.z, p.y + 1, 1.3); p.y = damp(p.y, g, 4, dt); this.onGround = true; if (p.y < w.killY) this.gone = true; }
    else hit = this.physics(dt);
    if (hit && sp > 0 && this.state === 'chase' && this.sideT <= -.4 && Math.hypot(p.x - px, p.z - pz) < sp * dt * .5) { this.side = Math.random() < .5 ? 1 : -1; this.sideT = rand(.5, 1.1); }
    // расталкивание
    for (const e of G.ents) { if (e === this || e.team !== 'enemy' || e.dead || !e.c || !!e.c.fly !== !!c.fly) continue; const ex = p.x - e.pos.x, ez = p.z - e.pos.z, rr = this.r + e.r, d2 = ex * ex + ez * ez; if (d2 < rr * rr && d2 > 1e-6) { const dd = Math.sqrt(d2), k = (rr - dd) / dd * .5 * (e.boss ? 2 : 1); p.x += ex * k; p.z += ez * k; } }
    if (d < this.r + P.r - .05 && d > .01 && !c.touch && Math.abs(P.pos.y - p.y) < 1.5) { const k = (this.r + P.r - d) / d; p.x -= dx * k; p.z -= dz * k; }
    if (face !== null) this.yaw = dampAng(this.yaw, face, this.state === 'wind' ? 12 : 8, dt);
    this.sync(); body.update(dt, Math.hypot(v.x, v.z), this.state === 'air' ? 1 : 0);
  }
  alert() { if (this.state !== 'idle') return; this.state = 'chase'; this.cd = Math.max(this.cd, .5); _v.set(this.pos.x, this.pos.y + this.h + .5, this.pos.z); G.fx.text(_v, '!', 'alert'); for (const e of G.ents) if (e !== this && e.team === 'enemy' && e.state === 'idle' && e.alert && e.pos.distanceTo(this.pos) < 9) e.state = 'chase'; }
  shoot(d) {
    const c = this.c, p = this.pos, P = G.player, a = yawTo(p.x, p.z, P.pos.x, P.pos.z), o = { x: p.x + Math.sin(a) * this.r, y: p.y + this.aimY + .2, z: p.z + Math.cos(a) * this.r, team: 'enemy', dmg: c.dmg, kind: c.ranged };
    const sp = c.ranged === 'web' ? 15 : 13, gr = c.ranged === 'web' ? 5 : 12, t = Math.max(.25, d / sp), dy = P.pos.y + 1 - o.y; o.vx = Math.sin(a) * sp; o.vz = Math.cos(a) * sp; o.vy = dy / t + .5 * gr * t; o.grav = gr;
    if (c.ranged === 'web') o.onHit = pl => { pl.slow = 2.6; G.ui.toast('🕸️ Паутина! Ты замедлен', 'hint'); };
    G.game.spawn(new Shot(o)); G.audio.sfx(c.ranged === 'web' ? 'squish' : 'throw');
  }
  hurt(dmg, from, knock = 4, kind) {
    if (this.dead || this.invul) return false; const c = this.c, p = this.pos, spray = kind === 'spray'; this.hp -= dmg; this.body.flash(spray ? .35 : 1);
    if (!spray || Math.random() < .3) { _v.set(p.x, p.y + this.aimY, p.z); G.fx.burst(c.goo ? 'goo' : 'hit', _v, spray ? 2 : 7, { color: c.goo }); }
    _v.set(p.x, p.y + this.h + (c.fly ? 1 : .35), p.z); if (spray) { this.dotAcc += dmg; if (++this.dotN % 4 === 0) { G.fx.text(_v, String(this.dotAcc), 'dot'); this.dotAcc = 0; } } else G.fx.text(_v, String(dmg), 'dmg');
    if (from && knock) { const a = yawTo(from.x, from.z, p.x, p.z), k = knock / (c.mass || 1); this.vel.x += Math.sin(a) * k; this.vel.z += Math.cos(a) * k; if (knock > 6 && this.onGround && !c.fly) { this.vel.y = 4; this.onGround = false; } }
    if (!spray && !c.armor) { this.stag = .28; this.body.play('hit', .25); }
    if (this.state === 'idle') { this.state = 'chase'; for (const e of G.ents) if (e !== this && e.team === 'enemy' && e.state === 'idle' && e.pos.distanceTo(p) < 9) e.state = 'chase'; }
    if (this.hp <= 0) this.die(); return true;
  }
  die() {
    if (this.dead) return; const c = this.c; this.dead = true; this.t = 0; this.state = 'dead'; this.body.set('dead'); _v.set(this.pos.x, this.pos.y + this.aimY, this.pos.z); G.fx.burst(c.goo ? 'goo' : 'dust', _v, 14, { color: c.goo, s: 1.3 }); G.audio.sfx(c.bug || c.goo ? 'squish' : 'hit2');
    if (c.money) G.game.drop(_v, c.money[0] + Math.random() * (c.money[1] - c.money[0] + 1) | 0); if (Math.random() < (c.food ?? .1)) G.game.spawn(new Pickup(_v.x, _v.y, _v.z, { item: pick(['bread', 'banana', 'doshik']), pop: 1 }));
    G.game.onKill(this); if (this.onDeath) this.onDeath(this);
  }
}
