// Помощники для сценариев уровней
import { G, wait } from './g.js';
export const say = (who, text) => G.ui.say(who, text);
export const choose = opts => G.ui.choose(opts);
export function* lines(arr) { for (const [w, t] of arr) yield* G.ui.say(w, t); }
export const tip = (pc, touch) => G.ui.toast(G.touch ? (touch || pc) : pc, 'hint');
// встать лицом друг к другу
export const cam = (...a) => G.cam.shot(...a);
export function* pan(px, py, pz, lx, ly, lz, t = 1.5, cut = false) { G.cam.shot(px, py, pz, lx, ly, lz, cut); yield* wait(t); }
