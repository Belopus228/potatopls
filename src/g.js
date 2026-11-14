// Общий синглтон игры + мелкие утилиты
import * as THREE from 'three';
export const G = { dt: 0, time: 0, mode: 'boot', ents: [], co: [], mobile: false, q: 2 };
export const V3 = THREE.Vector3;
export const PI = Math.PI, TAU = Math.PI * 2;
export const clamp = (v, a, b) => v < a ? a : v > b ? b : v;
export const sat = v => v < 0 ? 0 : v > 1 ? 1 : v;
export const lerp = (a, b, t) => a + (b - a) * t;
export const damp = (a, b, k, dt) => a + (b - a) * (1 - Math.exp(-k * dt));
export const smooth = (a, b, x) => { x = sat((x - a) / (b - a)); return x * x * (3 - 2 * x); };
export const angDiff = (a, b) => { let d = (b - a) % TAU; if (d > PI) d -= TAU; if (d < -PI) d += TAU; return d; };
export const dampAng = (a, b, k, dt) => a + angDiff(a, b) * (1 - Math.exp(-k * dt));
export function rng(seed) { let s = (seed >>> 0) || 1; return () => { s ^= s << 13; s >>>= 0; s ^= s >>> 17; s ^= s << 5; s >>>= 0; return s / 4294967296; }; }
export const rand = (a = 1, b) => b === undefined ? Math.random() * a : a + Math.random() * (b - a);
export const pick = a => a[Math.random() * a.length | 0];
export const dist2 = (ax, az, bx, bz) => Math.hypot(ax - bx, az - bz);
export const yawTo = (ax, az, bx, bz) => Math.atan2(bx - ax, bz - az);
// корутины: генераторы, шаг каждый кадр
export function* wait(t) { while ((t -= G.dt) > 0) yield; }
export function* until(fn) { while (!fn()) yield; }
G.run = (gen, keep = false) => { if (typeof gen === 'function') gen = gen(); G.co.push({ gen, keep, dead: false }); return gen; };
G.stepCo = () => { const a = G.co.slice(); for (const c of a) { if (c.dead) continue; let done; try { done = c.gen.next().done; } catch (e) { console.error('co', e); done = true; } if (done) { c.dead = true; const i = G.co.indexOf(c); if (i >= 0) G.co.splice(i, 1); } } };
G.clearCo = () => { for (const c of G.co) if (!c.keep) c.dead = true; G.co = G.co.filter(c => c.keep); };
export const sleep = ms => new Promise(r => setTimeout(r, ms));
