// ГЛАВА 4 — МЫТИЩИ: город образцовой чистоты, мыльная головоломка, Мойдодыр
import * as THREE from 'three';
import { G, wait, rand, PI, TAU, damp } from '../g.js';
import { LEVELS } from '../game.js';
import { M, C, glowMat, faceTex, photoTex } from '../tex.js';
import { wall, lampPost, crates, block, bench, bin, tree, kiosk, barrier } from '../kit.js';
import { NPC, Enemy, Crate } from '../actors.js';
import { Boss } from '../bosses.js';
import { makeHuman } from '../rig.js';
import { SlidePuzzle } from '../puzzles.js';
import { inv } from '../items.js';
import { FACE } from '../faces.js';
import { lines, tip } from '../script.js';

const _v = new THREE.Vector3(), AZ = 46;
const CLEAN = { day: 1, top: 0x2a8ae8, hor: 0xd8f2ff, bot: 0x9fc0d0, sun: [.35, .8, -.4], sunCol: 0xffffff, sunInt: 2.4, hemiSky: 0xd0ecff, hemiGnd: 0x9ab0b8, hemiInt: .4, fog: [0xd8f2ff, 60, 300], clouds: .35, exposure: 1, bloom: [.25, .5, 1.3], envInt: .4, shadowSize: 44 };
const GOODS = [{ id: 'bread', price: 8 }, { id: 'banana', price: 12 }, { id: 'shava', price: 45 }, { id: 'kvas', price: 60 }, { id: 'hp', price: 90, max: 6 }, { id: 'chain', price: 160, max: 3 }];
const MOI = { n: 'МОЙДОДЫР', e: '🚰', c: '#8fe3ff', p: .5 };

// ---------- МОЙДОДЫР ----------
class Moidodyr extends Boss {
  constructor(x, y, z) { super(x, y, z, { name: 'МОЙДОДЫР', hp: 980, r: 1.5, h: 4.4, mass: 12, solidR: 1.25, aimY: 2.5, goo: 0xa8dcff, body: makeHuman({ body: 'moidodyr', scale: 2.3 }) }); this.hot = false; this.n = 0; }
  shout(t, cls = 'alert') { _v.set(this.pos.x, this.pos.y + 5.6, this.pos.z); G.fx.text(_v, t, cls); }
  // куски мыла по дуге: попадание — скользко
  *volley(n) {
    for (let i = 0; i < n; i++) {
      this.body.play('throw', .36); yield* this.wait(.2, 12); const a = this.toP() + rand(-.1, .1), sp = 16, t = Math.max(.3, this.dist() / sp), gr = 8, y0 = this.pos.y + 3.2;
      this.shoot({ x: this.pos.x + Math.sin(a) * 1.6, z: this.pos.z + Math.cos(a) * 1.6, y: y0, vx: Math.sin(a) * sp, vz: Math.cos(a) * sp, vy: (this.P.pos.y + 1 - y0) / t + .5 * gr * t, grav: gr, dmg: 10, kind: 'soap', onHit: p => { p.slip = 3.5; G.ui.toast('🧼 Скользко! Ты на мыле', 'hint'); } });
      G.audio.sfx('throw'); yield* this.wait(.2, 8);
    }
    yield* this.wait(.5, 5);
  }
  // струя: дорожка ударов от босса к игроку
  *jet() {
    this.body.play('point', 1.3); G.audio.sfx('steam'); this.shout('СТРУЯ!'); yield* this.wait(.55, 10); const a = this.toP();
    for (let i = 1; i <= (this.hot ? 9 : 7); i++) G.run(this.blast(this.pos.x + Math.sin(a) * i * 3.1, this.pos.z + Math.cos(a) * i * 3.1, 2.3, .5 + i * .1, 13, { fx: 'water', color: 0x3ad0ff, ring: 0xa8dcff, sfx: 'splash', shake: .2, y: this.pos.y }));
    yield* this.wait(1.7, 2);
  }
  // кипяток с потолка
  *rain(n) {
    const P = this.P; this.body.play('cast', 1.2); G.audio.sfx('steam');
    for (let i = 0; i < n; i++) { const a = rand(TAU), rr = i ? rand(1, 8) : 0; G.run(this.blast(P.pos.x + Math.sin(a) * rr, P.pos.z + Math.cos(a) * rr, 2.6, 1, 13, { fx: 'steam', color: 0xff8a3a, sfx: 'steam', shake: .15, y: this.pos.y })); yield* this.wait(.2); }
    yield* this.wait(.9, 4);
  }
  // «головомойка»: волны по полу, потом выдыхается
  *spin() {
    yield* this.go(0, AZ, 9, 2.5, 1.5); this.body.play('cast', .9); this.shout('ГОЛОВОМОЙКА!'); G.audio.sfx('roar'); yield* this.wait(.8);
    for (let i = 0; i < (this.hot ? 3 : 2); i++) { G.run(this.shockwave(this.pos.x, this.pos.z, 30, 2.2, 14, 0x3ad0ff)); this.body.play('slam', .5); G.cam.shake(.5); let t = 1; while ((t -= G.dt) > 0) { this.yaw += G.dt * 13; yield; } }
    this.vul = 1.6; this.shout('ВЫДОХСЯ!', 'good'); this.body.set('sit'); G.audio.sfx('steam'); yield* this.wait(this.hot ? 2.4 : 3); this.body.set(null); this.vul = 1; yield* this.wait(.3, 6);
  }
  *ai() {
    const ph = this.hp / this.maxHp, d = this.dist();
    if (ph < .5 && !this.hot) { this.hot = true; this.invul = true; this.shout('ВКЛЮЧАЮ КИПЯТОК!'); this.body.play('cast', 1.4); G.audio.sfx('roar'); G.cam.shake(.8); yield* this.wait(1.2); this.invul = false; yield* this.rain(7); return; }
    if (d < 4.8 && Math.random() < .5) { this.body.play('slam', .7); yield* this.blast(this.pos.x, this.pos.z, 4.6, .75, 17, { fx: 'water', sfx: 'splash' }); yield* this.wait(.6, 5); }
    else {
      const k = this.n++ % 4;
      if (k === 0) yield* this.volley(this.hot ? 5 : 3);
      else if (k === 1) yield* this.jet();
      else if (k === 2) { if (this.minions() < 4) { this.body.play('cast', 1); this.shout('ПУЗЫРИ!'); G.audio.sfx('bubble'); yield* this.wait(.7); this.summon('bubble', this.hot ? 4 : 3, 4.5); } else yield* this.volley(3); if (this.hot) yield* this.rain(5); }
      else yield* this.spin();
    }
    yield* this.chase(this.hot ? 4.6 : 3.8, rand(.8, 1.6), 4);
  }
}

LEVELS.myt = {
  id: 'myt', title: 'МЫТИЩИ', sub: 'ГЛАВА 4', music: 'clean', weather: 'bubbles', seed: 41, env: CLEAN,
  kit: { gear: { phone: 1, spray: 1, chain: 1, ult: 1, kicks: 1, hp: 1 }, money: 140, inv: { doshik: 2, shava: 1, bread: 1 }, flags: { m_boss: 1, m_drun: 1, m_lift: 1 } },
  build(L) {
    const g = G.game, f = k => g.flag(k), TL = M.bigTiles(), MO = M.mosaic();
    // --- земля и границы ---
    L.box(M.pavers(), 0, -.25, 6, 110, .5, 156); L.box(TL, 0, .03, -25, 10, .06, 42, { solid: false }); L.box(TL, 0, .03, 10, 42, .06, 28, { solid: false });
    for (const s of [-1, 1]) L.box(M.grass(), s * 24.5, .02, -26, 31, .04, 36, { solid: false });
    barrier(L, -44, 0, 2, 150); barrier(L, 44, 0, 2, 150); barrier(L, 0, -58, 100, 2);
    block(L, -57, -22, 13.6, 54.4, 9, 1); block(L, 57, -22, 13.6, 54.4, 12, 1); block(L, -57, 44, 13.6, 54.4, 14, 1); block(L, 57, 44, 13.6, 54.4, 10, 1);
    [[-110, -40, 20], [110, -10, 26], [-100, 60, 30], [105, 80, 22], [-30, 130, 34], [40, 140, 28], [0, -120, 18], [-70, -110, 24], [80, -120, 30]].forEach(([x, z, fl], i) => block(L, x, z, i % 2 ? 34 : 54.4, i % 2 ? 54.4 : 27.2, fl, 1, { far: 1, solid: false }));
    const post = (text, x, z, w, h, ry, o) => { L.sign(text, x, 2.2, z, w, h, ry, { bg: '#ffffff', fg: '#0f4a7a', border: '#0f4a7a', ...o }); for (const s of [-1, 1]) L.cyl(M.white(), x + Math.cos(ry) * s * (w / 2 - .1), 1.1, z - Math.sin(ry) * s * (w / 2 - .1), .05, 2.2, { seg: 6, solid: true }); };
    // --- станция ---
    L.box(M.concrete(), 0, .2, -49.5, 34, .4, 7); L.box(0xffd21f, 0, .41, -52.8, 34, .02, .3, { solid: false });
    for (const dz of [-.72, .72]) L.box(M.metal(), 0, .14, -55 + dz, 110, .14, .1, { solid: false }); for (let i = 0; i < 44; i++) L.box(M.planksDark(), -54 + i * 2.5, .05, -55, .3, .1, 2.6, { solid: false });
    L.box(0x2f8a55, 6, 2.05, -55, 26, 2.7, 2.7, { gloss: 1 }); L.box(C(0x1a2a3a, .1, .7), 6, 2.6, -53.63, 24, .9, .06, { solid: false }); L.box(0xdfe3e6, 6, 3.5, -55, 25.6, .2, 2.4, { solid: false }); L.box(M.metalDark(), 6, .5, -55, 24, .6, 2.2, { solid: false });
    for (const x of [-12, 0, 12]) L.cyl(M.metalDark(), x, 2.1, -47, .1, 3.4, { seg: 6, solid: true }); L.box(M.ribs('#5a8aa8'), 0, 3.9, -48.6, 30, .16, 5, { solid: false });
    L.sign('МЫТИЩИ', 0, 4.8, -46.05, 9, 1.5, 0, { bg: '#0f4a7a', fg: '#ffffff', border: '#fff' }); L.sign('МЫТИЩИ', 0, 4.8, -46.15, 9, 1.5, PI, { bg: '#0f4a7a', fg: '#ffffff', border: '#fff' });
    post('ГОРОД ОБРАЗЦОВОЙ ЧИСТОТЫ\nГРЯЗНЫМ ВЪЕЗД ВОСПРЕЩЁН', 8.6, -43, 5.4, 1.5, PI); post('МОЙ РУКИ.\nМОЙ ВСЁ.', -8.4, -28, 3, 1.4, PI); post('ПЯТНО = ВРАГ', 8.4, -14, 3.4, .9, PI);
    // --- бульвар ---
    for (const z of [-38, -24, -10]) for (const s of [-1, 1]) lampPost(L, s * 6.4, z, 0, 0xffffff, 6, s > 0 ? PI : 0);
    for (const z of [-33, -17]) for (const s of [-1, 1]) bench(L, s * 6.2, z, s > 0 ? -PI / 2 : PI / 2);
    for (let i = 0; i < 6; i++) for (const s of [-1, 1]) tree(L, s * (14 + (i % 2) * 10), -42 + i * 7, 1, 'birch', 0);
    for (let i = 0; i < 10; i++) for (const s of [-1, 1]) L.sph(M.leaves(0x3f9a4a), s * 9.2, .7, -42 + i * 4, .8, { ico: 1 });
    for (const [x, z] of [[-6.4, -20], [6.4, -30], [-19, 20], [19, 20]]) L.cyl(0xf2f6f8, x, .45, z, .28, .9, { solid: true, seg: 8, r2: 1.15 });
    // фонтан
    L.cyl(MO, 0, .25, 8, 5, .5, { seg: 24, solid: true }); L.cyl(M.water(), 0, .53, 8, 4.6, .06, { seg: 24 }); L.cyl(M.white(), 0, 1.5, 8, .5, 2, { seg: 10, solid: true }); L.sph(C(0xdff6ff, .05, .9), 0, 3.3, 8, 1.1);
    let ft = 0; L.onUpdate(dt => { ft -= dt; if (ft <= 0 && G.player.pos.distanceToSquared(_v.set(0, 0, 8)) < 3600) { ft = .12; _v.set(rand(-.3, .3), 4.3, 8 + rand(-.3, .3)); G.fx.burst('water', _v, 2, { sp: .7 }); } });
    // --- Душевая №1 (головоломка) ---
    L.box(MO, -29.5, .04, 6, 15.6, .08, 10.6, { solid: false });
    wall(L, TL, -37.4, .6, -21.6, .6, 0, 3.4, .4); wall(L, TL, -37.4, 11.4, -21.6, 11.4, 0, 3.4, .4); wall(L, TL, -37.4, .6, -37.4, 11.4, 0, 3.4, .4); wall(L, TL, -21.6, .6, -21.6, 11.4, 0, 3.4, .4, [[5.4, 2.4, 2.6]]);
    L.sign('ДУШЕВАЯ №1', -21.35, 3, 6, 4.4, .7, PI / 2, { bg: '#0f4a7a', fg: '#fff', glow: .6 });
    for (let i = 0; i < 6; i++) { const x = -36 + i * 2; L.cyl(M.metal(), x, 1.6, 11.1, .04, 3, { seg: 6 }); L.box(M.metal(), x, 3.05, 10.92, .06, .06, .42, { solid: false }); L.cyl(M.metal(), x, 2.95, 10.75, .18, .1, { seg: 8 }); }
    L.box(M.metalDark(), -23.2, .6, 1.3, .4, 1.2, .3, { solid: false }); L.box(glowMat(0xff5a3a, 1.6), -23.2, 1.3, 1.45, .12, .5, .12, { solid: false });
    const att = { n: 'Банщица', e: '🧽' }, grd = { n: 'Вахтёр чистоты', e: '🧤' }, shp = { n: 'Продавщица', e: '🧴' }, mash = { n: 'Машинист', e: '🚂' };
    function* washed() {
      G.audio.sfx('ding'); yield* wait(.5); yield* lines([[att, 'Заработало! Ну, становись под душ, чумазый.']]);
      yield* G.ui.fadeTo(1, .4); G.audio.sfx('splash'); G.player.place(-32, .08, 9.8, PI); G.cam.snap(); yield* wait(.3); yield* G.ui.fadeTo(0, .4);
      G.cam.shot(-32, 2.3, 5.6, -32, 1.3, 9.8, true); G.player.rig.play('cheer', 2.2);
      for (let i = 0; i < 16; i++) { _v.set(-32 + rand(-.4, .4), 2.7, 9.9 + rand(-.3, .3)); G.fx.burst('water', _v, 4, { sp: .5 }); G.fx.burst('bub', _v, 2); if (i % 4 === 0) G.audio.sfx('bubble'); yield* wait(.13); }
      yield* lines([['sys', 'Ч помылся. Впервые с прошлого августа.'], [att, 'Вот. Теперь ты условно чистый. Держи пропуск «Чистые руки». И шею вытри.']]);
      inv.add('soap'); an.setMark(null); g.checkpoint('plaza', true); g.write(); setGoal();
    }
    const sp = new SlidePuzzle(L, -37, 1, .08, 2, ['.oB...', '...B..', '.#..B.', '...#.o', '.....o'], { solved: !!f('y_wash'), onSolve: () => { g.setFlag('y_wash'); g.script(washed, 'cut'); } });
    L.sp = sp;
    L.interact(-23.2, 1.1, 1.7, 1.7, 'Вернуть мыло на место', () => sp.reset(), { cond: () => !sp.solved });
    let st = 0; L.onUpdate(dt => { if (!sp.solved) return; st -= dt; if (st <= 0 && G.player.pos.distanceToSquared(_v.set(-30, 0, 6)) < 900) { st = .1; _v.set(-36 + (Math.random() * 6 | 0) * 2, 2.8, 10.7); G.fx.burst('water', _v, 2, { sp: .3 }); } });
    // --- магазин ---
    kiosk(L, 30, 6, -PI / 2, 'ЧИСТОТА', 0x2a9ad6, 0xdff6ff);
    // --- Дворец Чистоты ---
    wall(L, TL, -44, 24, 44, 24, 0, 7, .8, [[44, 4.4, 4]]); wall(L, TL, -22, 24.4, -22, 68, 0, 7, .8); wall(L, TL, 22, 24.4, 22, 68, 0, 7, .8); wall(L, TL, -22, 68, 22, 68, 0, 7, .8);
    L.sign('ДВОРЕЦ ЧИСТОТЫ', 0, 5.5, 23.55, 12, 1.6, PI, { bg: '#0f4a7a', fg: '#ffffff', glow: .8, border: '#fff' }); L.sign('ВХОД ТОЛЬКО С ПРОПУСКОМ «ЧИСТЫЕ РУКИ»', -6.4, 2.2, 23.55, 5, .8, PI, { bg: '#ffffff', fg: '#c01818', border: '#c01818' });
    L.box(MO, 0, .04, AZ, 43.2, .08, 43.2, { solid: false });
    for (const [x, z] of [[-12, 36], [12, 36], [-12, 56], [12, 56]]) { L.cyl(M.white(), x, 3.5, z, .9, 7, { seg: 12, solid: true }); L.cyl(MO, x, .3, z, 1.25, .6, { seg: 12 }); L.cyl(MO, x, 6.8, z, 1.25, .4, { seg: 12 }); }
    L.box(M.white(), 0, 1.6, 65.6, 14, 3.2, 3.6); L.box(C(0x9fd0e8, .05, .9), 0, 6.3, 67.3, 10, 5, .2, { solid: false }); L.cyl(M.metal(), 0, 4.2, 66.6, .3, 2, { seg: 8 }); L.box(M.metal(), 0, 5.1, 65.6, .5, .4, 2.4, { solid: false });
    L.sph(glowMat(0xe23a3a, 1.5), -1.8, 3.6, 66.2, .4); L.sph(glowMat(0x3a7be2, 1.5), 1.8, 3.6, 66.2, .4);
    const gm = L.mesh(new THREE.BoxGeometry(4.4, 4, .14), C(0x7fd0f0, .05, .5, { transparent: true, opacity: .5 }), 0, 2, 24), gcol = L.world.mover(0, 2, 24, 4.4, 4, .8); let gopen = !!f('y_gate'); gcol.off = gopen; gm.position.y = gopen ? 6.3 : 2;
    L.onUpdate(dt => { gm.position.y = damp(gm.position.y, gopen ? 6.3 : 2, 5, dt); }); const setGate = v => { if (gopen === v) return; gopen = v; gcol.off = v; G.audio.sfx('door'); };
    // --- точки и цели ---
    L.cps = { start: [0, .4, -49, 0], plaza: [0, 0, -2, 0], gate: [0, 0, 19, 0] };
    function setGoal() {
      if (f('y_boss')) return g.goal('Кнопка «Ы» у тебя! Возвращайся на станцию к машинисту', -6, 1.8, -50.5);
      if (f('y_gate')) return g.goal('Победи Мойдодыра во Дворце Чистоты', 0, 2, 40);
      if (inv.has('soap')) return g.goal('Покажи пропуск вахтёру у Дворца Чистоты', 3.4, 1.6, 22.2);
      if (!f('y_talk')) return g.goal('Иди к Дворцу Чистоты на севере', 3.4, 1.6, 22.2);
      if (!f('y_att')) return g.goal('Помойся в Душевой №1 — слева от фонтана', -22.5, 1.5, 6);
      g.goal('Затолкай три куска мыла в мыльницы (синие круги)', -31, 1, 6);
    }
    L.trigger(0, -3, 0, () => g.checkpoint('plaza'), { box: [21, 2] });
    // --- NPC ---
    const clean = (o) => ({ face: faceTex({ mood: 'smile', skin: '#f2d2c0', blush: 1 }), top: 0xffffff, sleeve: 'long', pants: 0x7fd0f0, shoes: 0xffffff, skin: 0xf2d2c0, ...o });
    g.spawn(new NPC(3.4, 0, 22.2, { name: 'Вахтёр чистоты', yaw: PI, mark: f('y_gate') ? null : '!', look: clean({ face: faceTex({ mood: 'angry', skin: '#f2d2c0' }), hairStyle: 'cap', capColor: 0x2a9ad6 }), *talk(n) {
      if (f('y_boss')) return yield* lines([[grd, 'Ты победил Самого?! И… наследил. Ладно. Иди уже. Я подотру.']]);
      if (f('y_gate')) return yield* lines([[grd, 'Проходи, проходи. Только ноги вытри.']]);
      if (inv.has('soap')) { yield* lines([[grd, 'Пропуск «Чистые руки»… Настоящий. И пахнешь ты теперь… терпимо.'], [grd, 'Проходи. Но там — Сам. Не груби ему. И ничего не трогай.']]); g.setFlag('y_gate'); n.setMark(null); setGate(true); g.checkpoint('gate', true); g.write(); return setGoal(); }
      yield* lines(f('y_talk') ? [[grd, 'Сначала — Душевая №1. Слева от фонтана. Потом — разговор.']] : [[grd, 'Стоять! Во Дворец Чистоты — только с пропуском «Чистые руки».'], ['ch', 'А кнопку от ливта тут не видели? Синюю такую.'], [grd, 'Кнопку забрал Сам. Мойдодыр. Она теперь стерильная. А ты — нет.'], [grd, 'Марш в Душевую №1, слева от фонтана. Помоешься — выдадут пропуск.']]); g.setFlag('y_talk'); setGoal();
    } }));
    const an = g.spawn(new NPC(-23.2, .08, 9.6, { name: 'Банщица', yaw: -PI / 2, mark: f('y_wash') ? null : '!', look: clean({ top: 0xdff4ff, style: 'robe', sleeve: 'short', hair: 0xf4e7a0, hairStyle: 'fringe', fat: 1.2 }), *talk(n) {
      if (f('y_wash')) { if (!inv.has('soap') && !f('y_gate')) { inv.add('soap'); setGoal(); } return yield* lines([[att, 'С лёгким паром. Пропуск не потеряй — второй раз мыться заставлю.']]); }
      yield* lines([[att, 'Душ не работает: мыльный автомат заклинило, куски мыла разъехались по полу.'], [att, 'Затолкай все три куска в мыльницы — синие круги. Мыло скользит до упора, пока во что-нибудь не упрётся.'], [att, 'Запутаешься — дёрни рычаг у входа, верну мыло на место.']]);
      n.setMark(null); g.setFlag('y_att'); g.setFlag('y_talk'); setGoal(); tip('Подойди к куску мыла с нужной стороны и нажми E — он уедет от тебя', 'Подойди к куску мыла с нужной стороны и нажми кнопку действия — он уедет от тебя');
    } }));
    g.spawn(new NPC(26.6, 0, 9.4, { name: 'Продавщица', yaw: -PI / 2, mark: '?', label: 'Купить', look: clean({ top: 0x2a9ad6, hair: 0x8a5a2a, hairStyle: 'fringe' }), *talk() { yield* lines([[shp, 'Всё свежее, всё мытое. Трижды. Руками не трогать!']]); yield* G.ui.shop('МАГАЗИН «ЧИСТОТА»', GOODS, 'Вкусности в стерильной упаковке'); } }));
    g.spawn(new NPC(-6.15, 0, -17, { name: 'Брал', yaw: PI / 2, still: true, solid: false, anim: 'sit', keepAnim: true, mark: f('y_bral') ? null : '?', look: { face: photoTex(FACE.bral), top: 0x6a5a3a, sleeve: 'long', pants: 0x3a3a34, hair: 0x5a3a22, hairStyle: 'fringe' }, *talk(n) {
      if (f('y_bral')) yield* lines([['bral', 'Мойдодыр силён, пока свежий. Покрутится, выдохнется — вот тогда и бей. А волны по полу — перепрыгивай.']]);
      else {
        yield* lines([['bral', 'О, Ч. А меня во Дворец не пускают. Говорят, я «пятно». Третий день тут сижу.'], ['bral', 'Дай хотя бы хлеба.']]);
        if (!inv.has('bread')) yield* lines([['ch', 'Хлеба нет.'], ['bral', 'В «Чистоте» продают, справа от фонтана. Я бы сам купил, да меня и туда не пускают.']]);
        else if ((yield* G.ui.choose(['Дать хлеб', 'Самому мало'])) === 0) { inv.take('bread'); yield* lines([['bral', 'От души. Держи вкусность — берёг на чёрный день. А день тут, сам видишь, белый.']]); inv.add('hp'); g.setFlag('y_bral'); n.setMark(null); }
        else yield* lines([['bral', 'Плаки-плаки…']]);
      }
      n.yaw = n.yaw0;
    } }));
    g.spawn(new NPC(-6, .4, -50.5, { name: 'Машинист', yaw: 0, mark: f('y_boss') ? '!' : null, label: 'Сесть на «поез»', look: { face: faceTex({ mood: 'smile', stache: '#555' }), top: 0x20305a, sleeve: 'long', pants: 0x20305a, hairStyle: 'cap', capColor: 0x20305a }, *talk() {
      yield* lines([[mash, f('y_boss') ? 'Чистенький! И с кнопкой. Едем в Мурино?' : '«Поез» стоит, пока ты тут. Но если хочешь назад без кнопки — дело твоё.']]);
      if ((yield* G.ui.choose(['Поехали в Мурино', 'Остаться в Мытищах'])) === 0) { G.audio.sfx('tram'); g.travel('murino', 'station'); }
    } }));
    // --- предметы и враги ---
    crates(L, [[-16, -40], [16, -38], [-20, -8], [20, -10], [-26, 18], [26, 18], [36, -4], [-39, -14], [10, 28], [-10, 28], [-18, 63], [18, 63]], Crate);
    g.item('hp', -40.6, .5, 6, 'myt.hp'); g.cash(20, 38, .5, 20, 'myt.c1'); g.cash(20, -30, .5, -44, 'myt.c2'); g.item('plums', 2.8, 1, 8, 'myt.pl'); g.item('banana', 19, .5, 27, 'myt.bn'); g.cash(20, 40, .5, -50, 'myt.c3');
    const E = (k, x, z) => g.spawn(new Enemy(k, x, 0, z));
    if (!f('y_boss')) { E('myt', -4, -28); E('myt', 5, -19); E('bubble', -13, -24); E('bubble', 14, -31); E('myt', -14, 2); E('myt', 13, 17); E('bubble', 9, -1); E('bubble', -10, 15); E('myt', 17, -7); E('bubble', 19, 12); E('myt', -19, -12); E('bubble', 34, -12); }
    // --- босс ---
    if (!f('y_boss')) {
      const boss = g.spawn(new Moidodyr(0, 0, 58)); boss.yaw = PI; boss.sync(); boss.fade = true;
      L.trigger(0, 30, 0, () => g.script(function* () {
        setGate(false); G.audio.music('boss'); G.cam.shot(4, 2.2, 47, 0, 3.2, 58, false, 2.2); yield* wait(.9);
        if (!f('y_met')) { yield* lines([[MOI, 'КТО. ПРИНЁС. ГРЯЗЬ. В МОЙ. ДВОРЕЦ?!'], ['ch', 'Я только что мылся! У меня пропуск!'], [MOI, 'За ушами — не мыл. Под ногтями — Мурино. Я тут главный по мочалкам и старший по кранам.'], [MOI, 'Кнопку получит только чистый. То есть — НИКТО.'], ['ch', 'Ам-ам-ам… Ну, держись, раковина.']]); g.setFlag('y_met'); }
        boss.body.play('cast', 1.2); G.audio.sfx('roar'); G.cam.shake(.8); G.ui.bigTitle('МОЙДОДЫР', 'БОСС', 2400); yield* wait(1.3); boss.start(); g.goal('Победи Мойдодыра. Когда выдохнется — бей!');
        tip('Волны по полу перепрыгивай. Мыло делает пол скользким', 'Волны по полу перепрыгивай. Мыло делает пол скользким');
      }, 'cut'), { box: [21, 3] });
      boss.onDefeat = () => { g.setFlag('y_boss'); inv.add('btn2'); g.pay(100); G.audio.music('clean'); G.audio.sfx('win'); setGate(true); g.checkpoint('gate', true); g.write(); setGoal(); g.script(function* () { yield* lines([[MOI, 'Буль… Ладно. Ты… условно чистый. Забирай кнопку. Она стерильная, не лапай!'], ['ch', 'Кнопка «Ы». Вторая есть. Чистая победа.']]); }); };
    }
    L.start = function* (cp) { setGoal(); if (cp === 'start' && !f('y_talk')) { yield* wait(1.2); tip('Мытищи. Тут слишком чисто… «Мыти» грязнуль не любят', 'Мытищи. Тут слишком чисто… «Мыти» грязнуль не любят'); } };
  },
};
