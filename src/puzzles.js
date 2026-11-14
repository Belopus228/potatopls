// Головоломки в мире: провода (поворот плиток) и скользящее мыло
import * as THREE from 'three';
import { G, damp, PI } from './g.js';
import { C, glowMat, M } from './tex.js';

const BOX = new THREE.BoxGeometry(1, 1, 1);
const rot = (m, r) => ((m << r) | (m >> (4 - r))) & 15;       // биты: С=1 В=2 Ю=4 З=8
const DIRS = [[1, 0, -1, 4], [2, 1, 0, 8], [4, 0, 1, 1], [8, -1, 0, 2]]; // бит, dx(столбец), dz(ряд), встречный бит

// Провода: соединить вход (слева от клетки [0][0]) с выходом (справа от [n-1][n-1])
export class WirePuzzle {
  // types: строки вида 'ILLI' (I — прямая, L — угол, T — тройник); sol — «правильные» повороты (для проверки не нужны)
  constructor(L, x0, z0, y, cell, types, o = {}) {
    this.L = L; this.n = types.length; this.cell = cell; this.x0 = x0; this.z0 = z0; this.tiles = []; this.solved = !!o.solved; this.o = o; const n = this.n, base = { I: 5, L: 3, T: 11 };
    const off = C(0x5a3a22, .6, .4), on = glowMat(0xffd21f, 2.6), plate = C(0x2a2e34, .7, .3); this.mats = [off, on];
    for (let j = 0; j < n; j++) for (let i = 0; i < n; i++) {
      const t = { i, j, m: base[types[j][i]], r: o.solved ? o.sol[j][i] : (L.r() * 4 | 0), g: new THREE.Group(), bars: [], a: 0 }, cx = x0 + (i + .5) * cell, cz = z0 + (j + .5) * cell; t.g.position.set(cx, y, cz);
      const p = new THREE.Mesh(BOX, plate); p.scale.set(cell * .92, .08, cell * .92); p.position.y = .04; p.receiveShadow = true; t.g.add(p);
      const hub = new THREE.Mesh(BOX, off); hub.scale.set(.34, .16, .34); hub.position.y = .12; t.g.add(hub); t.bars.push(hub);
      for (const [bit, dx, dz] of DIRS) if (t.m & bit) { const b = new THREE.Mesh(BOX, off); b.scale.set(dx ? cell * .46 : .2, .12, dz ? cell * .46 : .2); b.position.set(dx * cell * .23, .11, dz * cell * .23); t.g.add(b); t.bars.push(b); }
      t.a = t.r; t.g.rotation.y = -t.r * PI / 2; L.group.add(t.g); this.tiles.push(t);
      L.interact(cx, y + .9, cz, cell * .62, 'Повернуть', () => this.turn(t), { cond: () => !this.solved && (!o.can || o.can()) });
    }
    if (!o.solved && this.check()) this.turn(this.tiles[1], true);
    L.onUpdate(dt => { for (const t of this.tiles) { t.a = damp(t.a, t.r, 14, dt); t.g.rotation.y = -t.a * PI / 2; } }); this.check();
  }
  turn(t, quiet) { t.r++; if (!quiet) G.audio.sfx('lever'); if (this.check() && !this.solved) { this.solved = true; if (this.o.onSolve) this.o.onSolve(); } }
  mask(t) { return rot(t.m, t.r & 3); }
  check() {
    const n = this.n, T = this.tiles, seen = new Set(), q = []; let ok = false; if (this.mask(T[0]) & 8) { q.push(T[0]); seen.add(T[0]); }
    while (q.length) { const t = q.pop(), m = this.mask(t); if (t.i === n - 1 && t.j === n - 1 && (m & 2)) ok = true; for (const [bit, dx, dz, back] of DIRS) { if (!(m & bit)) continue; const i = t.i + dx, j = t.j + dz; if (i < 0 || j < 0 || i >= n || j >= n) continue; const u = T[j * n + i]; if (!seen.has(u) && (this.mask(u) & back)) { seen.add(u); q.push(u); } } }
    for (const t of T) { const m = this.mats[seen.has(t) ? 1 : 0]; for (const b of t.bars) b.material = m; } return ok;
  }
}

// Скользящие блоки: толкни — блок едет до упора. Все блоки — на сливы.
export class SlidePuzzle {
  // map: строки; '#' стена, '.' пол, 'B' блок, 'o' слив, 'X' блок на сливе
  constructor(L, x0, z0, y, cell, map, o = {}) {
    this.L = L; this.x0 = x0; this.z0 = z0; this.y = y; this.cell = cell; this.o = o; this.h = map.length; this.w = map[0].length; this.walls = map.map(r => [...r].map(c => c === '#')); this.goals = []; this.blocks = []; this.solved = !!o.solved;
    const soap = C(0xff9ed0, .2, .05), done = glowMat(0x7dff8a, 1.2), pill = M.white();
    for (let j = 0; j < this.h; j++) for (let i = 0; i < this.w; i++) {
      const c = map[j][i], [cx, cz] = this.pos(i, j);
      if (c === '#' && !o.noWalls) L.box(pill, cx, y + .6, cz, cell * .9, 1.2, cell * .9);
      if (c === 'o' || c === 'X') { this.goals.push([i, j]); L.cyl(C(0x1a2a3a, .3, .6), cx, y + .012, cz, cell * .36, .03, { seg: 14 }); L.cyl(glowMat(0x3ad0ff, 1.5), cx, y + .02, cz, cell * .42, .02, { seg: 14 }); }
      if (c === 'B' || c === 'X') { const m = new THREE.Mesh(BOX, soap); m.scale.set(cell * .8, cell * .55, cell * .8); m.castShadow = true; L.group.add(m); const b = { i, j, i0: i, j0: j, m, col: L.world.mover(cx, y + .5, cz, cell * .8, 1, cell * .8), x: cx, z: cz }; this.blocks.push(b); const it = L.interact(cx, y + .9, cz, cell * .95, 'Толкнуть', () => this.push(b), { cond: () => !this.solved && !this.busy }); b.it = it; }
    }
    this.mats = [soap, done]; if (this.solved) this.blocks.forEach((b, k) => { const g = this.goals[k]; if (g) { b.i = g[0]; b.j = g[1]; } });
    L.onUpdate(dt => { let mv = false; for (const b of this.blocks) { const [tx, tz] = this.pos(b.i, b.j); if (Math.abs(tx - b.x) + Math.abs(tz - b.z) > .01) { mv = true; const sp = 11 * dt, dx = tx - b.x, dz = tz - b.z, d = Math.hypot(dx, dz); if (d <= sp) { b.x = tx; b.z = tz; G.audio.sfx('land'); this.settle(); } else { b.x += dx / d * sp; b.z += dz / d * sp; if (Math.random() < .4) G.fx.burst('bub', b.m.position, 1); } } b.m.position.set(b.x, y + cell * .28, b.z); b.col.x = b.x; b.col.z = b.z; b.it.pos.set(b.x, y + .9, b.z); } this.busy = mv; }); this.paint();
  }
  pos(i, j) { return [this.x0 + (i + .5) * this.cell, this.z0 + (j + .5) * this.cell]; }
  free(i, j, self) { return i >= 0 && j >= 0 && i < this.w && j < this.h && !this.walls[j][i] && !this.blocks.some(b => b !== self && b.i === i && b.j === j); }
  push(b) {
    const p = G.player.pos, dx = b.x - p.x, dz = b.z - p.z, di = Math.abs(dx) > Math.abs(dz) ? Math.sign(dx) : 0, dj = di ? 0 : Math.sign(dz); let n = 0; while (this.free(b.i + di, b.j + dj, b)) { b.i += di; b.j += dj; n++; }
    if (n) { G.audio.sfx('whoosh'); G.player.rig.play('kick', .4); this.busy = true; } else G.audio.sfx('deny');
  }
  onGoal(b) { return this.goals.some(g => g[0] === b.i && g[1] === b.j); }
  paint() { for (const b of this.blocks) b.m.material = this.mats[this.onGoal(b) ? 1 : 0]; }
  settle() { this.paint(); if (!this.solved && this.blocks.every(b => this.onGoal(b))) { this.solved = true; G.audio.sfx('ding'); if (this.o.onSolve) this.o.onSolve(); } }
  reset() { if (this.solved) return; for (const b of this.blocks) { b.i = b.i0; b.j = b.j0; } G.audio.sfx('lever'); }
}
