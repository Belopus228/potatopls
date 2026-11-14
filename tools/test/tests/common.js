// общая библиотека автотеста (выполняется в странице)
const log = [], errs = [], _ce = console.error; console.error = (...a) => { errs.push(a.map(x => (x && x.stack) || String(x)).join(' ').slice(0, 400)); _ce(...a); };
const say = (...a) => log.push(a.join(' '));
const T = {
  // прокрутить диалоги/кат-сцены до управления игроком. picks — очередь ответов (по умолчанию 0)
  flush(picks = [], max = 6000) {
    for (let i = 0; i < max; i++) {
      const ui = G.ui; if (G.mode === 'play' && !G.game.loading && !G.game.inScript && !ui.cur) return true;
      ui.adv = true; if (ui.nCh > 0 && ui.pickV < 0) ui.pickV = picks.length ? picks.shift() : 0; if (ui.cur === 'shop') ui.handler('back'); sim(2);
    }
    say('!! flush timeout, mode=' + G.mode + ' cur=' + G.ui.cur + ' inScript=' + G.game.inScript); return false;
  },
  find(label) { return G.level.inter.filter(it => !it.off && (!it.cond || it.cond()) && ((it.label || '').includes(label) || (it.npc && it.npc.name === label))); },
  // подойти к интерактиву и нажать «действие» по-честному (через near)
  use(label, picks, n = 0, ang = 0) {
    const it = this.find(label)[n]; if (!it) { say('!! нет интерактива: ' + label); return false; }
    const p = G.player, w = G.level.world, d = Math.min(1.1, it.r * .55); let ok = false;
    for (const a of [ang, ang + 1.57, ang + 3.14, ang + 4.71, ang + .78, ang + 2.35, ang + 3.92, ang + 5.5]) {
      const x = it.pos.x + Math.sin(a) * d, z = it.pos.z + Math.cos(a) * d, y = w.ground(x, z, it.pos.y + (it.npc ? 1 : .3)); p.place(x, y, z, a + Math.PI); sim(2);
      if (p.near === it) { ok = true; break; }
    }
    if (!ok) { say('!! не дотянуться честно: ' + label + ' near=' + (p.near && p.near.label)); p.near = it; }
    G.input.press('interact'); sim(2); if (picks !== false) this.flush(picks || []); return true;
  },
  tp(x, y, z, yaw = 0) { G.player.place(x, y, z, yaw); G.cam.snap(); sim(3); },
  ents(fn) { return G.ents.filter(fn); },
  boss() { return G.ents.find(e => e.boss); },
  // подобрать все пикапы предмета
  grab(item) { let n = 0; for (const e of [...G.ents]) if (e.o && e.o.item === item && !e.gone) { G.player.place(e.pos.x, e.pos.y, e.pos.z); sim(8); n++; } return n; },
  breakCrate(item) { const c = G.ents.find(e => e.breakable && e.o && e.o.item === item); if (!c) return false; c.hurt(); sim(40); return this.grab(item) > 0; },
  // бой: sec секунд ИИ босса при бессмертном игроке, который бегает по кругу; потом добить
  fight(sec, move = true, kill = true) {
    const b = this.boss(); if (!b) { say('!! нет босса'); return; } const p = G.player, was = G.god; G.god = true; let t = 0, maxVul = 1, hits = 0; const hp0 = b.hp;
    while (t < sec && !b.dead) { if (move) { G.input.keys.up = true; G.cam.yaw += .035; if ((t * 30 | 0) % 97 === 0) G.input.press('jump'); } sim(1); t += 1 / 30; if (b.vul > maxVul) maxVul = b.vul; if (p.pos.y < -30) { say('!! игрок провалился', p.pos.y.toFixed(1)); break; } }
    G.input.keys = {}; say(`бой ${b.name}: ${t.toFixed(0)}с, hp ${hp0}->${b.hp}, maxVul ${maxVul}, игрок hp ${p.hp}`);
    if (kill && !b.dead) { b.invul = false; if (b.hitPart) { b.hp = 1; b.hitPart(b.face, 5); } else b.hurt(99999, p.pos, 0, 'melee'); }
    sim(100); this.flush(); G.god = was;
  },
  state() { const S = G.save; return `[${G.level && G.level.id}/${S.cp}] mode=${G.mode} hp=${G.player.hp} ₽${S.money} inv=${JSON.stringify(S.inv)} gear=${JSON.stringify(S.gear)} цель="${G.ui.c.q}"`; },
};
// бот: дойти пешком до точки (держит «вперёд» и крутит камеру на цель)
T.walk = (x, z, maxSec = 25, tol = .7, sprint = true) => { const p = G.player, K = G.input.keys; let t = 0, lastD = 1e9, stall = 0, side = 1, dodge = 0;
  while (t < maxSec) { const dx = x - p.pos.x, dz = z - p.pos.z, d = Math.hypot(dx, dz); if (d < tol) { G.input.keys = {}; sim(2); return true; }
    if (d < lastD - .03) { lastD = d; stall = 0; } else stall += 1 / 30; if (stall > .6 && dodge <= 0) { dodge = .7; side = -side; stall = 0; lastD = 1e9; G.input.press('jump'); T.detours = (T.detours || 0) + 1; }
    G.cam.yaw = Math.atan2(dx, dz) + Math.PI + (dodge > 0 ? side * 1.2 : 0); dodge -= 1 / 30; K.up = true; K.sprint = sprint; sim(1); t += 1 / 30; if (G.mode !== 'play') { G.input.keys = {}; T.flush(); } }
  G.input.keys = {}; say(`!! не дошёл до (${x}, ${z}): стою в (${p.pos.x.toFixed(1)}, ${p.pos.y.toFixed(1)}, ${p.pos.z.toFixed(1)})`); return false; };
T.path = (pts, name) => { let ok = true; T.detours = 0; for (const [x, z, t] of pts) if (!T.walk(x, z, t || 25)) { ok = false; break; } say((ok ? 'ok: ' : '!! ПРОВАЛ: ') + 'маршрут ' + name + ' -> ' + G.player.pos.toArray().map(v => v.toFixed(1)) + (T.detours ? ' (обходов: ' + T.detours + ')' : '')); return ok; };
T.ready = () => { let n = 0; while ((G.mode !== 'menu' || G.game.loading) && n++ < 3000) sim(2); };
T.chapter = (id, cp) => { T.ready(); G.game.startChapter(id, cp); sim(90); T.flush(); };
// бот-боец: идёт к цели, бьёт, выбегает из красных кругов, перепрыгивает кольца, ест при низком здоровье
T.bot = (sec, o = {}) => {
  const p = G.player, K = G.input.keys, fx = G.fx, b = T.boss(); let t = 0, hits = 0, lastHp = p.hp, lost = 0, ate = 0, ults = 0; const hp0 = b ? b.hp : 0; G.god = false;
  while (t < sec && b && !b.dead && !p.dead) {
    let tgt = null, bd = 1e9; for (const e of G.ents) { if (e.team !== 'enemy' || e.dead || e.noAim || !e.hurt) continue; const d = Math.hypot(e.pos.x - p.pos.x, e.pos.z - p.pos.z) - (e.r || .4), w = (e.boss || e.sr) ? d - 4 : d; if (w < bd) { bd = w; tgt = e; } }
    let danger = null; for (const d of fx.discs) if (d.t > 0 && d.t < (o.react || .75)) { const dx = p.pos.x - d.m.position.x, dz = p.pos.z - d.m.position.z, dd = Math.hypot(dx, dz); if (dd < d.r + .7) { danger = { dx, dz, dd }; break; } }
    K.up = K.sprint = false;
    if (danger) { const a = danger.dd > .25 ? Math.atan2(danger.dx, danger.dz) : p.yaw + Math.PI; G.cam.yaw = a + Math.PI; K.up = true; K.sprint = true; if (p.rollT <= -.15 && p.stamina > 20) G.input.press('dodge'); }
    else if (tgt) { const dx = tgt.pos.x - p.pos.x, dz = tgt.pos.z - p.pos.z, d = Math.hypot(dx, dz) - (tgt.r || .4); G.cam.yaw = Math.atan2(dx, dz) + Math.PI; if (d > 1.4) { K.up = true; K.sprint = d > 7; } if (d < 2.1) G.input.press('attack'); }
    for (const r of fx.rings) if (r.t > 0 && r.r1 > 20) { const rad = r.m.scale.x / 2, dd = Math.hypot(p.pos.x - r.m.position.x, p.pos.z - r.m.position.z); if (dd - rad > -.3 && dd - rad < 1.5 && p.onGround) G.input.press('jump'); }
    if (p.hp < p.maxHp * .45 && (t * 30 | 0) % 20 === 0 && G.game && Object.keys(G.save.inv).some(i => ['bread', 'banana', 'doshik', 'milk', 'shava', 'kvas', 'plums'].includes(i))) { G.input.press('item1'); ate++; }
    if (p.rage >= 100 && bd < 6) { G.input.press('ult'); ults++; }
    sim(1); t += 1 / 30; if (p.hp < lastHp) { hits++; lost += lastHp - p.hp; } lastHp = p.hp; if (G.mode !== 'play' && !p.dead) { K.up = false; T.flush(); }
  }
  G.input.keys = {}; const res = `${b ? b.name : '?'}: ${b && b.dead ? 'ПОБЕДА' : p.dead ? 'ИГРОК ПОГИБ' : 'время вышло'} за ${t.toFixed(0)}с; босс ${hp0}->${b ? Math.max(0, b.hp) : '?'}; попаданий по игроку ${hits}, потеряно hp ${lost}, осталось ${p.hp}/${p.maxHp}, еды съедено ~${ate}, ульт ${ults}`; say(res); sim(100); if (!p.dead) T.flush(); return res;
};
