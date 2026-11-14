try {
const g = G.game, P = G.player, f = k => g.flag(k), want = (c, m) => say((c ? 'ok: ' : '!! ПРОВАЛ: ') + m);
// --- ФОГ, фаза 3: вдох и «АМ-АМ-АМ»
T.chapter('final'); T.walk(0, -15, 6); sim(10); T.flush(); { const b = T.boss(); G.god = true; b.hp = b.maxHp * .27; let t = 0, pulled = 0, choke = false, x0; G.save.gear.ult = 1;
  while (t < 60 && !choke) { const z0 = P.pos.z; sim(1); t += 1 / 30; if (b.ph === 3 && P.pos.z - z0 > .05) { pulled++; if (pulled === 40) { P.rage = 100; G.input.press('ult'); } } if (b.vul === 2) choke = true; }
  want(b.ph === 3 && pulled >= 40, 'вдох тянет игрока, кадров: ' + pulled); want(choke, 'ульта во время вдоха -> ПОДАВИЛСЯ (vul 2), лицо уязвимо: ' + !b.face.dead);
  const hp = b.hp; P.place(0, 0, 13.5, 0); sim(2); for (let i = 0; i < 20; i++) { G.input.press('attack'); sim(8); } want(b.hp < hp, 'удары по лицу проходят: ' + hp.toFixed(0) + ' -> ' + b.hp.toFixed(0)); G.god = false; }
// --- смерть и возрождение
T.chapter('murino'); { P.hp = 1; const e = T.ents(e => e.team === 'enemy' && e.c)[0]; P.place(e.pos.x + .5, e.pos.y, e.pos.z); let n = 0; while (!P.dead && n++ < 600) sim(1); want(P.dead, 'игрок погиб от врага ' + e.name); n = 0; while (G.ui.cur !== 'dead' && n++ < 300) sim(1); want(G.ui.cur === 'dead' && G.mode === 'dead', 'экран смерти: ' + (document.querySelector('.dead h1') || {}).textContent);
  G.ui.handler('re'); sim(120); T.flush(); want(!P.dead && P.hp === P.maxHp && G.mode === 'play' && G.save.deaths === 1, 'возрождение: hp ' + P.hp + ', смертей ' + G.save.deaths); }
// --- пауза, инвентарь, настройки, еда
{ G.input.press('pause'); sim(2); want(G.mode === 'pause' && G.ui.cur === 'pause', 'пауза'); const t0 = G.time; sim(30); want(G.time === t0, 'время стоит на паузе'); G.ui.handler('set'); sim(2); want(G.ui.cur === 'set' || !!document.querySelector('#screen.on'), 'настройки из паузы: ' + G.ui.cur); 
  const html = document.querySelector('#screen').innerText.replace(/\s+/g, ' ').slice(0, 300); say('настройки: ' + html); G.ui.handler('back'); sim(2); want(G.ui.cur === 'pause', 'назад в паузу: ' + G.ui.cur); G.ui.handler('back'); sim(2); want(G.mode === 'play', 'продолжить');
  G.input.press('inv'); sim(2); want(G.ui.cur === 'inv', 'инвентарь'); say('инвентарь: ' + document.querySelector('#screen').innerText.replace(/\s+/g, ' ').slice(0, 200)); P.hp = 50; G.ui.handler('sel', 'doshik'); G.ui.handler('use'); sim(2); want(P.hp === 85, 'съел доширак из инвентаря: hp ' + P.hp); G.ui.handler('back'); sim(2); want(G.mode === 'play', 'закрыл инвентарь');
  P.hp = 40; G.input.press('item1'); sim(2); want(P.hp > 40, 'быстрая еда (1): hp ' + P.hp); }
// --- сохранение: выйти в меню и продолжить
{ g.setFlag('test_flag'); G.save.money = 777; G.input.press('pause'); sim(2); G.ui.handler('menu'); sim(150); want(G.mode === 'menu' && !!document.querySelector('[data-a=cont]'), 'в меню есть «Продолжить»'); want(!!document.querySelector('[data-a=chap]'), 'в меню есть «Главы»');
  G.ui.handler('chap'); sim(2); say('главы: ' + [...document.querySelectorAll('[data-a=go]')].map(b => b.textContent).join(', ')); G.ui.handler('back'); sim(2);
  G.ui.handler('cont'); sim(150); T.flush(); want(G.level.id === 'murino' && G.save.money === 777 && f('test_flag'), 'продолжение: ' + T.state()); }
// --- падение за карту / вода
T.chapter('milk'); { G.god = false; T.tp(62, 2, 4, 0); sim(20); const h0 = P.hp; G.cam.yaw = Math.PI / 2 + Math.PI; G.input.keys.up = true; G.input.keys.sprint = true; let n = 0, mx = 0; while (P.hp === h0 && n++ < 600) { sim(1); mx = Math.max(mx, P.pos.x); } G.input.keys = {}; sim(5); say('заплыл до x=' + mx.toFixed(0)); want(P.pos.x < mx - 3 && P.hp === h0 - 10, 'утонул в море -> вернуло на берег: ' + P.pos.toArray().map(v => v.toFixed(0)) + ' hp ' + P.hp); }
// --- банная печь: перегрев, подсказка
T.chapter('banya'); { G.save.flags.b_dod = 1; G.save.flags.b_ok = 1; const picks = [0, 0, 0, /*150 -> сброс*/ 2, 2, 2, /*-15 -> погасла, подсказка*/ 3]; T.use('Затопить печь', picks); want(!f('b_fire') && G.mode === 'play', 'печь: перегрев и «погасла» отработали, ответов осталось ' + picks.length); }
return log.join('\n') + '\nОШИБКИ(' + errs.length + '):\n' + [...new Set(errs)].join('\n');
} catch (e) { return log.join('\n') + '\n!! ИСКЛЮЧЕНИЕ ' + (e.stack || e); }
