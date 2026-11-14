// Игра: сохранения, загрузка уровней, скрипты, чекпойнты
import * as THREE from 'three';
import { G, wait, rand, TAU } from './g.js';
import { Level } from './level.js';
import { Pickup } from './actors.js';
import { inv } from './items.js';

const SAVE = 'mell3d.save.v1', SET = 'mell3d.set.v1', PROG = 'mell3d.prog.v1';
export const LEVELS = {};
export const ORDER = ['dorm', 'murino', 'milk', 'myt', 'banya', 'final'];
const ls = { get(k) { try { return JSON.parse(localStorage.getItem(k)); } catch (e) { return null; } }, set(k, v) { try { localStorage.setItem(k, JSON.stringify(v)); } catch (e) { } }, del(k) { try { localStorage.removeItem(k); } catch (e) { } } };

export class Game {
  constructor() { this.mark = null; this.loading = false; this.inScript = 0; this.saveT = 0; }
  defaults() { return { level: 'dorm', cp: 'start', hp: 100, rage: 0, money: 0, inv: {}, gear: {}, flags: {}, t: 0, kills: 0, deaths: 0, earned: 0 }; }
  loadSettings() { G.settings = { q: G.mobile ? 1 : 2, vol: .8, music: .5, sens: 1, invY: false, autoCam: true, shake: true, easy: false, dyn: true, ...(ls.get(SET) || {}) }; G.q = G.settings.q; }
  saveSettings() { ls.set(SET, G.settings); }
  hasSave() { return !!ls.get(SAVE); }
  write() { const S = G.save, p = G.player; if (!S || G.mode === 'menu' || this.menuLevel) return; if (!p.dead) { S.hp = p.hp; S.rage = p.rage; } ls.set(SAVE, S); }
  unlocked() { const p = ls.get(PROG) || []; return ORDER.filter(id => p.includes(id) && LEVELS[id]).map(id => ({ id, title: LEVELS[id].title })); }
  flag(k) { return G.save.flags[k]; }
  setFlag(k, v = 1) { G.save.flags[k] = v; }
  // ---------- запуск ----------
  toMenu() { if (G.level && !this.menuLevel) this.write(); this.menuLevel = true; G.save = this.defaults(); G.run(this.load('menu', 'start', true), true); }
  newGame() { ls.del(SAVE); this.menuLevel = false; G.save = this.defaults(); G.player.hp = 100; G.player.rage = 0; G.run(this.load('dorm', 'start'), true); }
  continue() { this.menuLevel = false; G.save = { ...this.defaults(), ...(ls.get(SAVE) || {}) }; G.player.hp = G.save.hp > 0 ? G.save.hp : 100; G.player.rage = G.save.rage || 0; G.run(this.load(G.save.level, G.save.cp), true); }
  startChapter(id, cp = 'start') { this.menuLevel = false; const k = LEVELS[id].kit || {}, S = G.save = this.defaults(); Object.assign(S.gear, k.gear); Object.assign(S.inv, k.inv); Object.assign(S.flags, k.flags); S.money = k.money || 0; G.player.hp = 100 + 20 * (S.gear.hp || 0); G.player.rage = 0; G.run(this.load(id, cp), true); }
  travel(id, cp = 'start') { if (this.loading) return; G.run(this.load(id, cp), true); }
  respawn() { const p = G.player; p.hp = p.maxHp; G.run(this.load(G.save.level, G.save.cp), true); }
  unload() {
    G.clearCo(); for (const e of G.ents) e.dispose(); G.ents.length = 0; if (G.level) { G.level.dispose(); G.level = null; } G.fx.clear(); G.gfx.lamps = []; this.mark = null; this.inScript = 0; G.ui.endDlg(); G.ui.bossBar(null); G.ui.objective(''); G.cam.free(); G.cam.maxDist = 8; if (G.cam.want > 8) G.cam.want = 5.2; G.hitstop = 0;
  }
  *load(id, cpId = 'start', menu = false) {
    if (this.loading) return; this.loading = true; const ui = G.ui, p = G.player, def = LEVELS[id]; G.mode = 'cut'; ui.close(); p.lock = true;
    yield* ui.fadeTo(1, .3); yield;
    this.unload(); const L = G.level = new Level(def); G.gfx.scene.add(L.group); L.cps = {}; G.gfx.setEnv(def.env); G.fx.weather(def.weather || null);
    def.build(L); L.finish(); G.gfx.lamps = L.lamps;
    const cp = L.cps[cpId] || L.cps.start || [0, 0, 0, 0]; p.reset(); p.place(cp[0], cp[1], cp[2], cp[3] || 0); p.hidden = menu; p.root.visible = !menu; G.cam.snap(); G.cam.update(.016);
    if (!menu) { const S = G.save; S.level = id; S.cp = L.cps[cpId] ? cpId : 'start'; const pr = ls.get(PROG) || []; if (!pr.includes(id)) { pr.push(id); ls.set(PROG, pr); } }
    try { G.gfx.renderer.compile(G.gfx.scene, G.gfx.camera); } catch (e) { }
    yield; yield; G.audio.music(def.music); this.loading = false; p.lock = false;
    if (menu) { G.mode = 'menu'; ui.menu(); if (L.start) G.run(L.start()); yield* ui.fadeTo(0, .6); return; }
    this.write(); G.mode = 'play'; G.input.pressed = {};
    if (!this.flag('seen_' + id)) { this.setFlag('seen_' + id); ui.bigTitle(def.title, def.sub || ''); } else if (def.title) ui.toast(def.title, 'hint');
    if (L.start) G.run(L.start(cpId));
    yield* ui.fadeTo(0, .5);
  }
  // ---------- мир ----------
  spawn(a) { G.ents.push(a); G.level.group.add(a.root); return a; }
  drop(pos, amount) { let n = 0; while (amount > 0 && n++ < 7) { const v = amount >= 40 ? 20 : amount >= 12 ? 5 : amount >= 5 ? 5 : amount; amount -= v; this.spawn(new Pickup(pos.x, pos.y, pos.z, { money: v, pop: 1 })); } if (amount > 0) { G.save.money += amount; G.save.earned = (G.save.earned || 0) + amount; } }
  // постоянный предмет на уровне (не появляется снова после подбора)
  item(id, x, y, z, fid, o = {}) { if (this.flag(fid)) return null; return this.spawn(new Pickup(x, y, z, { item: id, fid, ...o })); }
  cash(v, x, y, z, fid) { if (fid && this.flag(fid)) return null; return this.spawn(new Pickup(x, y, z, { money: v, fid })); }
  onKill(e) { G.save.kills++; const L = G.level; if (L && L.onKill) L.onKill(e); }
  goal(text, x, y, z) { G.ui.objective(text); this.mark = x === undefined ? null : new THREE.Vector3(x, y, z); }
  checkpoint(id, quiet) { const S = G.save; if (S.cp === id) return; S.cp = id; this.write(); if (!quiet) G.ui.toast('💾 Сохранено', 'hint'); }
  quickEat() { const id = inv.bestFood(); if (!id) { G.ui.toast('Еды нет. Ломай ящики или зайди к темщику.', 'hint'); G.audio.sfx('deny'); } else inv.use(id); }
  onDeath() { G.save.deaths++; G.audio.sfx('lose'); G.audio.music(null); const self = this; G.run(function* () { yield* wait(1.5); if (G.player.dead && !self.loading) { G.mode = 'dead'; G.ui.death(); } }, true); }
  pause() { G.ui.pause(); }
  // скрипт (диалог/кат-сцена): блокирует управление, по окончании возвращает игру
  script(fn, mode = 'dialog') {
    if (G.mode !== 'play' && !this.inScript) return null; const self = this;
    return G.run(function* () { self.inScript++; G.mode = mode; try { yield* fn(); } finally { self.inScript = Math.max(0, self.inScript - 1); if (!self.inScript) { G.ui.endDlg(); G.cam.free(); if (G.mode === 'dialog' || G.mode === 'cut') { G.mode = 'play'; G.input.pressed = {}; } } } });
  }
  talk(npc) { const p = G.player; this.script(function* () { p.face(npc.pos.x, npc.pos.z); p.vel.set(0, p.vel.y, 0); npc.yaw = Math.atan2(p.pos.x - npc.pos.x, p.pos.z - npc.pos.z); const a = npc.body.base; if (!npc.o.keepAnim) npc.body.set('talk'); try { yield* npc.o.talk(npc); } finally { npc.body.set(npc.o.keepAnim ? a : (npc.o.anim || null)); } }); }
  update(dt) {
    const m = G.mode, L = G.level, p = G.player;
    if (m === 'play') { G.save.t += dt; this.saveT += dt; if (this.saveT > 15) { this.saveT = 0; this.write(); } }
    if (L && !this.loading) {
      if (!this.menuLevel) p.update(dt);
      const E = G.ents; for (let i = 0; i < E.length; i++) E[i].update(dt);
      for (let i = E.length - 1; i >= 0; i--) if (E[i].gone) { E[i].dispose(); E.splice(i, 1); }
      L.update(dt);
    }
    G.stepCo();
  }
}
