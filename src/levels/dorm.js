// ГЛАВА 1 — ОБЩАГА: обучение, кодовый замок, Тараканий Царь
import * as THREE from 'three';
import { G, wait, PI, TAU } from '../g.js';
import { LEVELS } from '../game.js';
import { GEO } from '../level.js';
import { M, C, glowMat, graffitiTex, faceTex, photoTex, memo } from '../tex.js';
import { wall, door, ceilLamp, crates, at } from '../kit.js';
import { NPC, Enemy, Crate } from '../actors.js';
import { RoachKing } from '../bosses.js';
import { inv } from '../items.js';
import { FACE } from '../faces.js';
import { lines, tip } from '../script.js';

const GOODS = [{ id: 'bread', price: 8 }, { id: 'doshik', price: 20 }, { id: 'energy', price: 25 }, { id: 'hp', price: 60, max: 1 }];
LEVELS.dorm = {
  id: 'dorm', title: 'ОБЩАГА', sub: 'ГЛАВА 1', music: 'dorm', seed: 11,
  env: { indoor: true, bg: 0x08090c, top: 0x343840, hor: 0x565a62, bot: 0x2a2622, fog: [0x101216, 16, 56], hemiSky: 0xc4ccdc, hemiGnd: 0x5a4e40, hemiInt: .62, sun: [.1, 1, .07], sunCol: 0xfff1d6, sunInt: .85, shadowSize: 20, exposure: 1.08, lamp: 4.5, lampCol: 0xffe6c0, envInt: .32, bloom: [.3, .5, 1.1] },
  build(L) {
    const g = G.game, W = M.wall2('#4c8a6a'), WK = M.wall2('#8a8f6a'), FL = M.lino(), TL = M.bigTiles(), CE = M.ceil(), CN = M.concDark(), H = 3.2;
    if (!g.flag('dormCode')) { const d = [1, 2, 3, 4, 5, 6, 7, 8, 9].sort(() => Math.random() - .5); g.setFlag('dormCode', '' + d[0] + d[1] + d[2]); }
    const code = g.flag('dormCode'); L.world.base = -60;   // есть подвал: пол только там, где он построен
    // --- коробка этажа ---
    L.box(FL, -8, -.15, 0, 36, .3, 15.2); L.box(TL, 15, -.15, 0, 10, .3, 15.2); L.box(CE, -3, H + .15, 0, 46, .3, 15.2);
    const gaps = [3, 9, 15, 21, 27, 35].map(c => [c, 1.4]);
    wall(L, W, -20, 7.6, 20, 7.6, 0, H); wall(L, W, -20, -7.6, 20, -7.6, 0, H); wall(L, W, -20, 1.6, 20, 1.6, 0, H, .3, gaps); wall(L, W, -20, -1.6, 20, -1.6, 0, H, .3, gaps);
    for (const x of [-14, -8, -2, 4, 10]) { wall(L, x === 10 ? WK : W, x, 1.75, x, 7.45, 0, H); wall(L, x === 10 ? WK : W, x, -7.45, x, -1.75, 0, H); }
    wall(L, W, -20, -7.6, -20, 7.6, 0, H, .3, [[7.6, 2.2]]); wall(L, W, 20, -7.6, 20, 7.6, 0, H, .3, [[7.6, 1.6]]);
    // вахта
    L.box(FL, -23, -.15, 0, 6, .3, 6.3); L.box(CE, -23, H + .15, 0, 6.3, .3, 6.6); wall(L, WK, -26, 3, -20, 3, 0, H); wall(L, WK, -26, -3, -20, -3, 0, H); wall(L, WK, -26, -3, -26, 3, 0, H, .3, [[3, 1.8]]);
    L.box(M.planksDark(), -23.4, .55, 2, 2.6, 1.1, .7); L.box(C(0x7fa6c8, .1, .5, { transparent: true, opacity: .35 }), -23.4, 1.75, 2.3, 2.6, 1.3, .05, { solid: false }); L.sign('ВАХТА', -23.4, 2.75, 2.82, 1.8, .45, PI, { bg: '#f2f2e6', fg: '#a01818' });
    L.sign('ВЫХОД', -25.82, 2.75, 0, 1.2, .36, PI / 2, { bg: '#0a3a14', fg: '#7dff8a', glow: 1.5 }); ceilLamp(L, -23, H, 0, 0xfff0d0, 18, 10);
    // --- комнаты ---
    const cols = [0x8a3a3a, 0x3a5a8a, 0x5a8a3a, 0x8a7a3a, 0x6a3a8a, 0x3a8a80];
    const bed = (x, z, col) => { L.box(M.planksDark(), x, .25, z, 1, .5, 2.1); L.box(col, x, .58, z, .96, .18, 2.05, { solid: false }); L.box(0xf0f0ea, x, .72, z + .72, .7, .14, .44, { solid: false }); };
    const desk = (x, z) => { L.box(M.planks(), x, .76, z, 1.5, .07, .7, { solid: false }); L.box(M.planksDark(), x, .36, z, 1.4, .72, .6); L.box(0x2a2a30, x - .2, .98, z, .5, .34, .05, { solid: false, gloss: 1 }); L.box(M.planksDark(), x, .3, z - .9 * Math.sign(z), .45, .6, .45); };
    const poster = (t, x, y, z, ry, bg, fg, w = 1.5, h = 1) => L.sign(t, x, y, z, w, h, ry, { bg, fg, border: fg, cw: 256 });
    const P = [['ЧТО ЗА\nБИЗНЕС?', '#1a1a1a', '#ffd21f'], ['АМ АМ\nАМ', '#7a1414', '#fff'], ['ХАМАМ', '#10305a', '#7fe0ff'], ['Я ПОМЫЛСЯ', '#f2f2e6', '#1a6a2a'], ['СЛИВЫ!', '#3a1450', '#e9a0ff'], ['ПОСИДИМ', '#143a1a', '#c9ff7a'], ['СКОЛЬКО-\nСКОЛЬКО?', '#402a10', '#ffb060'], ['ПЛАКИ-\nПЛАКИ', '#101a40', '#9fb8ff'], ['БУРМАЛДА', '#1a1a1a', '#ff5a8a'], ['ДАЙ ХОТЯ\nБЫ ХЛЕБА', '#3a3020', '#ffe9a8']];
    for (let i = 0; i < 5; i++) for (const d of [1, -1]) {
      const cx = -17 + i * 6, cz = d * 4.6, k = i * 2 + (d > 0 ? 0 : 1);
      bed(cx - 2.33, cz + d * .4, cols[k % 6]); bed(cx + 2.33, cz + d * .4, cols[(k + 3) % 6]); desk(cx, cz + d * 2.45); L.box(M.planksDark(), cx + 2.2, 1.1, cz - d * 2.5, 1.2, 2.2, .6);
      L.box(glowMat(0x1c2c50, .9), cx, 1.85, d * 7.43, 1.7, 1.3, .05, { solid: false }); L.box(0xf2f2ee, cx, 1.85, d * 7.44, 1.9, 1.5, .03, { solid: false }); L.box(0xf2f2ee, cx, 1.85, d * 7.41, .06, 1.3, .06, { solid: false });
      ceilLamp(L, cx, H, cz, k % 3 === 1 ? 0xd8e6ff : 0xffe2b0, 16, 9, k === 7 ? { flicker: 1 } : undefined); const p = P[k % P.length]; poster(p[0], cx - 2.83, 1.9, cz - d * 1.6, PI / 2, p[1], p[2]);
      L.sign(String(101 + k), cx + 1.15, 2.2, d * 1.42, .5, .26, d > 0 ? PI : 0, { bg: '#e8e2c8', fg: '#222', cw: 128 });
    }
    for (let i = 0; i < 5; i++) ceilLamp(L, -16 + i * 8, H, 0, 0xfff0d0, 20, 11, i === 3 ? { flicker: 1 } : undefined);
    poster('МУРИНО —\nЭТО НЕ\nЖМУРИНО!', -9, 1.9, -1.43, 0, '#0d1626', '#7fe0ff', 1.6, 1.2); poster('ФОГ\nИДЁТ', 3, 1.9, 1.43, PI, '#d8dce2', '#111', 1.2, 1.3);
    // граффити-цифры кода
    const gr = (n, x, y, z, ry, col) => { const t = graffitiTex(code[n], col, n + 1); L.trash.push(t); return L.sign('', x, y, z, 1.7, 1.7, ry, { tex: t, bg: 'none' }); };
    gr(0, -19.83, 1.7, -5.4, PI / 2, '#ff3b6b'); gr(1, 9.83, 1.7, 5.6, -PI / 2, '#3bd0ff'); gr(2, 16, 1.75, -7.43, 0, '#b6ff3b');
    // кухня
    L.box(0xe8e8e4, 15, .45, 7.1, 9.4, .9, .7, { gloss: 1 }); L.box(0x2a2a2e, 12.5, .92, 7.1, .7, .06, .6, { solid: false }); L.box(0x2a2a2e, 13.5, .92, 7.1, .7, .06, .6, { solid: false }); L.box(M.metal(), 16.5, .9, 7.1, 1, .08, .55, { solid: false });
    L.box(0xf4f4f0, 19.3, .95, 6.3, .8, 1.9, .8, { gloss: 1 }); L.box(M.planks(), 15, .78, 4.2, 2.4, .08, 1.2, { solid: false }); L.box(M.planksDark(), 15, .37, 4.2, 2.2, .74, 1); ceilLamp(L, 15, H, 4.6, 0xfff4e0, 22, 12); L.sign('КУХНЯ', 15, 2.75, 1.78, 1.4, .36, 0, { bg: '#e8e2c8', fg: '#222', cw: 256 });
    L.sign('НЕ КОРМИТЬ\nТАРАКАНОВ!', 12, 2, 7.43, 1.6, .8, PI, { bg: '#f2e6a0', fg: '#a01818', cw: 256 });
    // умывальная
    for (let i = 0; i < 4; i++) { L.box(0xf4f6f8, 11.6 + i * 1.5, .78, -7.15, 1, .3, .6, { gloss: 1 }); L.cyl(M.metal(), 11.6 + i * 1.5, 1.06, -7.3, .03, .26, { seg: 6 }); }
    L.box(M.glass(), 13.8, 1.8, -7.42, 5.6, 1, .05, { solid: false, fit: 1 }); for (let i = 0; i < 3; i++) wall(L, TL, 17.5, -6.8 + i * 1.7, 19.85, -6.8 + i * 1.7, 0, 2.1, .1); L.box(C(0x3a88bb, .05, .5, { transparent: true, opacity: .5 }), 14, .012, -4, 3.5, .02, 2.4, { solid: false });
    ceilLamp(L, 15, H, -4.6, 0xd8ecff, 22, 12, { flicker: 1 }); L.sign('УМЫВАЛЬНАЯ', 15, 2.75, -1.78, 1.8, .36, PI, { bg: '#e8e2c8', fg: '#222', cw: 256 });
    // --- подвал ---
    L.box(FL, 20.6, -.15, 0, 1.2, .3, 3.4);
    L.stairs(M.concrete(), 24.2, 0, 3.4, 6, -3.6, 0, { rot: -PI / 2 }); wall(L, CN, 20, 1.7, 27.2, 1.7, -3.6, 6.8); wall(L, CN, 20, -1.7, 27.2, -1.7, -3.6, 6.8); L.box(CE, 23.6, H + .15, 0, 7.4, .3, 3.7);
    L.box(M.concDark(), 39, -3.75, 0, 24, .3, 24.4); L.box(M.ceil(0x4a4c50), 39, 1.95, 0, 24.4, .3, 24.8);
    wall(L, M.brick(), 27, -12, 27, 12, -3.6, 5.4, .4, [[12, 3.4, 3.4]]); wall(L, M.brick(), 51, -12, 51, 12, -3.6, 5.4, .4); wall(L, M.brick(), 27, 12, 51, 12, -3.6, 5.4, .4); wall(L, M.brick(), 27, -12, 51, -12, -3.6, 5.4, .4);
    for (const [x, z] of [[34, 6.5], [34, -6.5], [45, 6.5], [45, -6.5]]) L.cyl(M.concrete(), x, -.9, z, .8, 5.4, { solid: true, seg: 10 });
    for (const z of [-11.5, 11.5]) L.add(M.metalDark(), GEO.cyl(8), 39, 1.1, z, { s: [.16, 23, .16], rz: PI / 2 });
    for (const [x, z, c] of [[32, 0, 0x9dff7a], [46, 0, 0x9dff7a], [39, 9, 0xffb060], [39, -9, 0xffb060]]) ceilLamp(L, x, 1.8, z, c, 30, 16, { flicker: x === 46 ? 1 : 0 });
    L.box(C(0x4a6a2a, .1, .3, { transparent: true, opacity: .55 }), 41, -3.59, 3, 5, .02, 3.6, { solid: false }); L.sign('ТРОННЫЙ\nЗАЛ', 50.75, -.6, 0, 3.2, 1.6, -PI / 2, { bg: 'none', fg: '#c9b040', stroke: '#000' });
    // --- точки сохранения ---
    L.cps = { start: [-5, 0, 4.4, PI], base: [17.5, 0, 0, PI / 2], out: [-18, 0, 0, -PI / 2] };
    // --- двери ---
    const bd = door(L, 20, 0, 0, PI / 2, { w: 1.6, label: false, mat: M.metalDark() }); if (g.flag('dorm_open')) bd.setOpen(true, true);
    L.sign('ПОДВАЛ\nКОД ●●●', 19.82, 2.72, 0, 1.3, .5, -PI / 2, { bg: '#1a1a1a', fg: '#ffd21f', cw: 256 });
    L.interact(19.3, 1, 0, 2.2, 'Кодовый замок', () => g.script(function* () {
      const c = yield* G.ui.keypad('ПОДВАЛ', 3, inv.has('note_dorm') ? 'Цифры нарисованы на стенах. Считай точки под ними: • — первая, •• — вторая, ••• — третья.' : 'Нужен код. Комендант оставил записку на кухне.');
      if (c === code) { g.setFlag('dorm_open'); bd.setOpen(true); G.audio.sfx('ding'); G.ui.toast('🔓 Подвал открыт', 'big'); g.goal('Спустись в подвал', 30, -3, 0); g.checkpoint('base'); }
      else if (c !== null) { G.audio.sfx('deny'); G.ui.toast('Неверный код', 'hint'); }
    }), { cond: () => !bd.open });
    door(L, -26, 0, 0, PI / 2, { w: 1.8, label: 'Выйти на улицу', mat: M.metalDark(), dir: -1, locked: () => inv.has('key_dorm') ? '' : 'Заперто. Ключ комендант унёс в подвал.', onOpen: () => g.script(function* () { yield* lines([['ch', 'Поехали. Мурино ждёт.']]); g.travel('murino'); }) });
    // --- NPC ---
    g.spawn(new NPC(-6.75, .22, 5, { name: 'Брал', yaw: PI / 2, anim: 'sit', keepAnim: 1, still: true, solid: false, look: { face: photoTex(FACE.bral), top: 0x7a7f88, sleeve: 'long', pants: 0x2a2f3a, hair: 0x5a3a22, hairStyle: 'fringe' }, *talk() { yield* lines(inv.has('key_dorm') ? [['bral', 'Ты завалил Царя?! Красавчик, Ч. Беги, пока туман не пришёл. Я тут… посижу.']] : [['bral', 'Записка на кухне — в конце коридора направо. Код от подвала как-то связан с цифрами на стенах.'], ['bral', 'И найди дихлофос. В умывальной вроде стоял ящик с красным крестом.']]); } }));
    g.spawn(new NPC(-12.6, 0, .95, { name: 'Темщик', yaw: PI, mark: '?', look: { face: faceTex({ mood: 'happy', skin: '#d8a888' }), top: 0x1a1a1a, sleeve: 'long', pants: 0x1a1a1a, hairStyle: 'cap', capColor: 0xb01818, chain: true, skin: 0xd8a888 }, *talk() { yield* lines([[{ n: 'Темщик', e: '🧢' }, 'Что за бизнес? Дошики, хлеб, бурмалда. Всё свежее, почти.']]); yield* G.ui.shop('ЛАРЁК ТЕМЩИКА', GOODS, 'Сколько-сколько?'); } }));
    g.spawn(new NPC(-23.4, 0, 1.2, { name: 'Вахтёрша', yaw: PI, look: { face: faceTex({ mood: 'angry', skin: '#e0b8a0' }), top: 0x6a4a7a, sleeve: 'long', pants: 0x3a3a44, hair: 0xb8b8c0, hairStyle: 'fringe', fat: 1.3, skin: 0xe0b8a0 }, *talk() { yield* lines(inv.has('key_dorm') ? [[{ n: 'Вахтёрша', e: '👵' }, 'Ключ? Ну иди, иди. И дверь за собой закрой — туман напустишь!']] : [[{ n: 'Вахтёрша', e: '👵' }, 'Куда?! После одиннадцати не выпускаю! Ключ у коменданта, комендант в подвале. А в подвал я не пойду — там ЭТОТ, усатый.']]); } }));
    // --- предметы и враги ---
    g.item('note_dorm', 15, .95, 4.2, 'dorm.note', { onTake: () => g.script(function* () { yield* lines([['sys', '«Код от подвала я записал на стенах, чтоб не забыть. Три цифры в трёх комнатах. Точки под цифрой — её номер по порядку. — Комендант»']]); g.goal('Найди три цифры на стенах и введи код у двери подвала', 19.3, 1.2, 0); }) });
    if (!g.flag('dorm.spray')) { g.spawn(new Crate(18.6, 0, -2.6, { s: .9, mat: C(0xf4f4f0, .5), item: 'spray', ifid: 'dorm.spray', fid: 'dorm.sprayc', yaw: 0 })); L.sign('✚', 18.6, .5, -2.14, .5, .5, 0, { bg: 'none', fg: '#d22' }); }
    crates(L, [[-18.5, 6.6], [-11, -6.6], [1, 6.8], [7.5, -6.5], [11.2, 2.6], [18.8, -1.2], [-21, -2.2], [30, 9.5, -3.6], [30, -9.5, -3.6], [48.5, 10, -3.6], [48.5, -10, -3.6, { item: 'doshik' }]], Crate);
    g.cash(20, 7, .3, -6.9, 'dorm.c1'); g.cash(20, -17, .3, 6.9, 'dorm.c2'); g.item('banana', 1, .95, -7.05, 'dorm.b1'); g.item('hp', 49.5, -3.3, 0, 'dorm.hp');
    const E = (k, x, z, y = 0) => g.spawn(new Enemy(k, x, y, z));
    E('roach', 5, 0); E('roach', 12, -.6); E('roach', 13, 5); E('roach', 17.5, 3.4); E('roach', 12.5, -4); E('roach', 16, -5.5); E('roach', 18, -3.6); E('roach', -11, -5); E('roach', 1, 5.5);
    E('roach', 31, 4, -3.6); E('roach', 31, -5, -3.6);
    // --- босс ---
    if (!g.flag('dorm_boss')) {
      const boss = g.spawn(new RoachKing(44.5, -3.6, 0)); boss.yaw = -PI / 2; boss.sync();
      const gate = L.world.mover(27, -1.9, 0, .5, 3.4, 3.6); gate.off = true; const gm = L.mesh(new THREE.BoxGeometry(.3, 3.4, 3.5), M.metalDark(), 27, -1.9, 0, { cast: 1 }); gm.visible = false;
      L.trigger(31.5, 0, 0, () => g.script(function* () {
        gate.off = false; gm.visible = true; G.audio.sfx('door'); G.audio.music('boss'); G.cam.shot(37, -1.4, 3.2, 44.5, -2.6, 0, false, 2.5); yield* wait(.7);
        boss.body.play('cast', 1.3); G.audio.sfx('roar'); G.cam.shake(.8); G.ui.bigTitle('ТАРАКАНИЙ ЦАРЬ', 'БОСС', 2600); yield* wait(1.7);
        yield* lines([['ch', 'Что за бизнес… Он же размером с «Газель»!']]); boss.start(); g.goal('Победи Тараканьего Царя. Уворачивайся от разгона — пусть врежется в стену!');
      }, 'cut'), { box: [2.2, 12] });
      boss.fade = true; boss.onDefeat = () => { g.setFlag('dorm_boss'); gate.off = true; gm.visible = false; inv.add('key_dorm'); inv.add('chain'); G.audio.music('dorm'); G.audio.sfx('win'); g.goal('Выйди из общаги через вахту', -25.4, 1.2, 0); g.checkpoint('base', true); g.write(); g.script(function* () { yield* lines([['ch', 'Ам-ам-ам! Ключ. И цепь золотая — вкусность. Теперь на выход.']]); }); };
    }
    L.trigger(-5, 0, 2.2, () => tip('ЛКМ — удар (три подряд — комбо). C — перекат. ПКМ — швырнуть котлету денег.', '👊 удар (три подряд — комбо) · 💨 перекат · 💸 бросок'));
    L.trigger(15, -4.5, 3, () => { if (!inv.has('spray')) tip('В ящике с красным крестом — дихлофос. Разбей его!'); });
    L.start = function* () {
      if (!g.flag('dorm_intro')) {
        g.setFlag('dorm_intro'); yield* wait(1.1);
        g.script(function* () {
          yield* lines([['phone', '*бзззз* Входящий вызов: ДРУН'], ['drun', 'Ч! Ты чё, спишь?! ФОГ ИДЁТ! Туман уже у вашей общаги!'], ['ch', 'Друн?.. Какой ещё Фог?'], ['drun', 'Тот самый. Вали оттуда и дуй ко мне в Мурино, я у шавермы. И осторожно — тараканы у вас уже с собаку!'], ['bral', 'Ч, вахтёрша выход заперла. Ключ комендант унёс в подвал, а подвал на кодовом замке.'], ['bral', 'Он записку на кухне оставил. Кухня в конце коридора, направо. На, держи дошики на дорожку.']]);
          inv.add('doshik', 2); inv.add('phone', 1, true); g.goal('Найди записку коменданта на кухне', 15, 1.2, 4.2); tip('WASD — ходьба, мышь — камера, E — действие', 'Слева стик, справа камера. Кнопка E — действие');
        });
      } else if (g.flag('dorm_boss')) g.goal('Выйди из общаги через вахту', -25.4, 1.2, 0); else if (g.flag('dorm_open')) g.goal('Спустись в подвал', 30, -3, 0);
      else if (inv.has('note_dorm')) g.goal('Найди три цифры на стенах и введи код у двери подвала', 19.3, 1.2, 0); else g.goal('Найди записку коменданта на кухне', 15, 1.2, 4.2);
    };
  },
};
