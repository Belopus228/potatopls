// Простая физика мира: коллайдеры (коробки/пандусы/цилиндры), сетка, запросы земли, лучи
import { clamp } from './g.js';

export class World {
  constructor() { this.solids = []; this.grid = new Map(); this.cs = 6; this.hf = null; this.qid = 0; this.out = []; this.killY = -25; this.dyn = []; this.gs = null; }
  _ins(s) {
    const c = Math.abs(s.c), n = Math.abs(s.s), ex = c * s.hx + n * s.hz, ez = n * s.hx + c * s.hz, cs = this.cs;
    for (let ix = Math.floor((s.x - ex) / cs); ix <= Math.floor((s.x + ex) / cs); ix++) for (let iz = Math.floor((s.z - ez) / cs); iz <= Math.floor((s.z + ez) / cs); iz++) {
      const k = ix * 4096 + iz; let a = this.grid.get(k); if (!a) this.grid.set(k, a = []); a.push(s);
    }
    this.solids.push(s); return s;
  }
  // центр x,y,z; полные размеры; rot вокруг Y
  box(x, y, z, sx, sy, sz, rot = 0, o) { return this._ins({ t: 0, x, z, y0: y - sy / 2, y1: y + sy / 2, hx: sx / 2, hz: sz / 2, c: Math.cos(rot), s: Math.sin(rot), q: 0, ...o }); }
  // пандус: подъём вдоль локальной +z от ya до yb
  ramp(x, z, sx, sz, ya, yb, rot = 0, o) { return this._ins({ t: 1, x, z, ya, yb, y0: Math.min(ya, yb) - 1, y1: Math.max(ya, yb), hx: sx / 2, hz: sz / 2, c: Math.cos(rot), s: Math.sin(rot), q: 0, ...o }); }
  cyl(x, z, r, y0, y1, o) { return this._ins({ t: 2, x, z, y0, y1, hx: r, hz: r, r, c: 1, s: 0, q: 0, ...o }); }
  // подвижное тело (лифт, трамвай, дверь): то же, что box, но вне сетки — можно менять x/z/y0/y1 каждый кадр
  mover(x, y, z, sx, sy, sz, rot = 0, o) { const s = { t: 0, x, z, y0: y - sy / 2, y1: y + sy / 2, hx: sx / 2, hz: sz / 2, c: Math.cos(rot), s: Math.sin(rot), q: 0, dyn: true, vx: 0, vy: 0, vz: 0, ...o }; this.dyn.push(s); return s; }
  query(x0, z0, x1, z1) {
    const out = this.out, cs = this.cs, id = ++this.qid; out.length = 0;
    for (let ix = Math.floor(x0 / cs); ix <= Math.floor(x1 / cs); ix++) for (let iz = Math.floor(z0 / cs); iz <= Math.floor(z1 / cs); iz++) {
      const a = this.grid.get(ix * 4096 + iz); if (!a) continue;
      for (let i = 0; i < a.length; i++) { const s = a[i]; if (s.q !== id && !s.off) { s.q = id; out.push(s); } }
    }
    for (let i = 0; i < this.dyn.length; i++) { const s = this.dyn[i]; if (!s.off && s.x - s.hx - s.hz < x1 && s.x + s.hx + s.hz > x0 && s.z - s.hx - s.hz < z1 && s.z + s.hx + s.hz > z0) out.push(s); }
    return out;
  }
  top(s, lz) { return s.t === 1 ? s.ya + (s.yb - s.ya) * clamp((lz + s.hz) / (2 * s.hz), 0, 1) : s.y1; }
  height(x, z) { return this.hf ? this.hf(x, z) : 0; }
  // высота опоры под точкой (с учётом шага)
  ground(x, z, fy, step = .45) {
    let g = this.height(x, z); const a = this.query(x - .3, z - .3, x + .3, z + .3); this.gs = null;
    for (let i = 0; i < a.length; i++) {
      const s = a[i]; if (s.ghost || s.nowalk) continue; const dx = x - s.x, dz = z - s.z;
      if (s.t === 2) { if (dx * dx + dz * dz > (s.r + .1) * (s.r + .1)) continue; if (s.y1 <= fy + step && s.y1 > g) { g = s.y1; this.gs = s; } continue; }
      const lx = dx * s.c - dz * s.s, lz = dx * s.s + dz * s.c;
      if (Math.abs(lx) > s.hx + .12 || Math.abs(lz) > s.hz + .12) continue;
      const t = this.top(s, lz); if (t <= fy + step && t > g) { g = t; this.gs = s; }
    }
    return g;
  }
  // выталкивание круга (радиус r, ноги p.y, рост h) из блокирующих тел. Возвращает true при контакте
  collide(p, r, h, step = .45) {
    let hit = false;
    for (let it = 0; it < 2; it++) {
      const a = this.query(p.x - r - .1, p.z - r - .1, p.x + r + .1, p.z + r + .1); let any = false;
      for (let i = 0; i < a.length; i++) {
        const s = a[i]; if (s.ghost || s.y0 >= p.y + h) continue; const dx = p.x - s.x, dz = p.z - s.z;
        if (s.t === 2) {
          if (s.y1 <= p.y + step) continue; const d2 = dx * dx + dz * dz, rr = r + s.r; if (d2 >= rr * rr) continue;
          const d = Math.sqrt(d2) || .001, k = (rr - d) / d; p.x += dx * k; p.z += dz * k; any = true; continue;
        }
        let lx = dx * s.c - dz * s.s, lz = dx * s.s + dz * s.c;
        const cx = clamp(lx, -s.hx, s.hx), cz = clamp(lz, -s.hz, s.hz);
        if (this.top(s, cz) <= p.y + step) continue;
        const ex = lx - cx, ez = lz - cz, d2 = ex * ex + ez * ez;
        if (d2 >= r * r) continue;
        if (d2 < 1e-9) { const px = s.hx - Math.abs(lx), pz = s.hz - Math.abs(lz); if (px < pz) lx = (lx < 0 ? -1 : 1) * (s.hx + r); else lz = (lz < 0 ? -1 : 1) * (s.hz + r); }
        else { const d = Math.sqrt(d2), k = (r - d) / d; lx += ex * k; lz += ez * k; }
        p.x = s.x + lx * s.c + lz * s.s; p.z = s.z - lx * s.s + lz * s.c; any = true;
      }
      if (!any) break; hit = true;
    }
    return hit;
  }
  // потолок над головой (нижняя грань тела выше ног), либо Infinity
  ceil(x, z, fy) {
    let c = Infinity; const a = this.query(x - .2, z - .2, x + .2, z + .2);
    for (let i = 0; i < a.length; i++) { const s = a[i]; if (s.ghost || s.t === 1 || s.y0 < fy + .9) continue; const dx = x - s.x, dz = z - s.z, lx = dx * s.c - dz * s.s, lz = dx * s.s + dz * s.c; if (Math.abs(lx) <= s.hx && Math.abs(lz) <= s.hz && s.y0 < c) c = s.y0; }
    return c;
  }
  // точка внутри тела или под землёй?
  inside(x, y, z) {
    if (y < this.height(x, z)) return true; const a = this.query(x, z, x, z);
    for (let i = 0; i < a.length; i++) { const s = a[i]; if (s.ghost || y < s.y0) continue; const dx = x - s.x, dz = z - s.z; if (s.t === 2) { if (y <= s.y1 && dx * dx + dz * dz <= s.r * s.r) return true; continue; } const lx = dx * s.c - dz * s.s, lz = dx * s.s + dz * s.c; if (Math.abs(lx) <= s.hx && Math.abs(lz) <= s.hz && y <= this.top(s, lz)) return true; }
    return false;
  }
  // луч (для камеры и прямой видимости). Возвращает расстояние до ближайшего пересечения или max
  ray(ox, oy, oz, dx, dy, dz, max, cam = false) {
    let best = max; const ex = ox + dx * max, ez = oz + dz * max;
    const a = this.query(Math.min(ox, ex) - .1, Math.min(oz, ez) - .1, Math.max(ox, ex) + .1, Math.max(oz, ez) + .1);
    for (let i = 0; i < a.length; i++) {
      const s = a[i]; if (s.ghost || (cam && s.nocam)) continue;
      const rx = ox - s.x, rz = oz - s.z, lox = rx * s.c - rz * s.s, loz = rx * s.s + rz * s.c, ldx = dx * s.c - dz * s.s, ldz = dx * s.s + dz * s.c;
      let t0 = 0, t1 = best, ok = true;
      const slab = (o, d, mn, mx) => { if (Math.abs(d) < 1e-7) { if (o < mn || o > mx) ok = false; return; } let a0 = (mn - o) / d, a1 = (mx - o) / d; if (a0 > a1) { const t = a0; a0 = a1; a1 = t; } if (a0 > t0) t0 = a0; if (a1 < t1) t1 = a1; if (t0 > t1) ok = false; };
      slab(lox, ldx, -s.hx, s.hx); if (ok) slab(oy, dy, s.t === 1 ? Math.min(s.ya, s.yb) : s.y0, s.y1); if (ok) slab(loz, ldz, -s.hz, s.hz);
      if (ok && t0 < best) best = t0;
    }
    if (this.hf) for (let k = 1; k <= 6; k++) { const t = best * k / 6; if (oy + dy * t < this.hf(ox + dx * t, oz + dz * t) + .15) { best = Math.min(best, best * (k - 1) / 6 + .05); break; } }
    else if (dy < 0) { const t = (oy - .12) / -dy; if (t < best && t > 0) best = t; }
    return best;
  }
}
