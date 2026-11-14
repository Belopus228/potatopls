// Камера от третьего лица: орбита, столкновения со стенами, тряска, кат-сцены
import * as THREE from 'three';
import { G, clamp, damp, dampAng, PI } from './g.js';

export class Cam {
  constructor(camera) {
    this.c = camera; this.yaw = PI; this.pitch = .3; this.want = 5.2; this.cur = 5.2; this.tgt = new THREE.Vector3(); this.look = new THREE.Vector3(); this.sh = 0; this.idle = 0;
    this.cine = null; this.cp = new THREE.Vector3(); this.cl = new THREE.Vector3(); this.blend = 0; this.kick = 0; this.baseFov = 62; this.v = new THREE.Vector3(); this.maxDist = 8;
  }
  zoom(d) { this.want = clamp(this.want + d * .7, 2.4, this.maxDist); }
  shake(v) { if (G.settings.shake !== false) this.sh = Math.max(this.sh, v); }
  // встать за спину игрока
  snap(yaw) { const p = G.player; this.yaw = (yaw ?? p.yaw) + PI; this.pitch = .3; this.tgt.set(p.pos.x, p.pos.y + 1.45, p.pos.z); this.cur = this.want; this.blend = 0; this.cine = null; }
  // кат-сцена: камера плавно едет в точку и смотрит на цель
  shot(px, py, pz, lx, ly, lz, cut = false, k = 3) { this.cine = { p: new THREE.Vector3(px, py, pz), l: new THREE.Vector3(lx, ly, lz), k }; if (cut || this.blend < .01) { if (cut) { this.cp.copy(this.cine.p); this.cl.copy(this.cine.l); } else { this.cp.copy(this.c.position); this.cl.copy(this.look); } } this.blend = 1; }
  free() { this.cine = null; }
  update(dt) {
    const p = G.player, inp = G.input, S = G.settings, w = G.level && G.level.world, c = this.c;
    if (G.mode === 'play' && !p.lock) {
      const k = S.sens || 1, lx = inp.look.x, ly = inp.look.y;
      this.yaw -= lx * .0026 * k; this.pitch = clamp(this.pitch + ly * .0022 * k * (S.invY ? -1 : 1), -.5, 1.3);
      if (lx || ly) this.idle = 0; else this.idle += dt;
      // авто-доворот за спину при беге (удобно на телефоне)
      if (S.autoCam !== false && this.idle > 1.4 && p.hspeed > 2.5) this.yaw = dampAng(this.yaw, p.yaw + PI, G.touch ? 1.3 : .55, dt);
    }
    const ty = p.pos.y + 1.45; this.tgt.x = damp(this.tgt.x, p.pos.x, 22, dt); this.tgt.z = damp(this.tgt.z, p.pos.z, 22, dt); this.tgt.y = damp(this.tgt.y, ty, p.onGround ? 9 : 16, dt);
    const cp = Math.cos(this.pitch), dx = Math.sin(this.yaw) * cp, dy = Math.sin(this.pitch), dz = Math.cos(this.yaw) * cp, t = this.tgt;
    let d = this.want; if (w) d = Math.max(.7, w.ray(t.x, t.y, t.z, dx, dy, dz, this.want + .35, true) - .35);
    this.cur = d < this.cur ? damp(this.cur, d, 30, dt) : damp(this.cur, d, 4, dt);
    const v = this.v.set(t.x + dx * this.cur, t.y + dy * this.cur, t.z + dz * this.cur); this.look.set(t.x, t.y + .2, t.z);
    if (this.cine) { this.cp.lerp(this.cine.p, 1 - Math.exp(-this.cine.k * dt)); this.cl.lerp(this.cine.l, 1 - Math.exp(-this.cine.k * dt)); this.blend = 1; }
    else if (this.blend > 0) { this.blend = Math.max(0, this.blend - dt * 1.6); }
    if (this.blend > 0) { const b = this.blend * this.blend * (3 - 2 * this.blend); v.lerp(this.cp, b); this.look.lerp(this.cl, b); }
    if (this.sh > 0) { const s = this.sh * .22; v.x += (Math.random() - .5) * s; v.y += (Math.random() - .5) * s; v.z += (Math.random() - .5) * s; this.sh = Math.max(0, this.sh - dt * 2.2 - this.sh * dt * 3); }
    c.position.copy(v); c.lookAt(this.look);
    const base = innerWidth < innerHeight ? 78 : this.baseFov, kick = (p.sprinting ? 6 : 0) + this.kick; this.kick = damp(this.kick, 0, 4, dt);
    const f = damp(c.fov, base + kick, 5, dt); if (Math.abs(f - c.fov) > .01) { c.fov = f; c.updateProjectionMatrix(); }
    G.gfx.focus.copy(p.pos);
  }
}
