// полное прохождение: общага -> Мурино -> Молочное -> Мытищи -> Банька -> финал
try {
const g = G.game, P = G.player, f = k => g.flag(k), want = (c, m) => { if (!c) say('!! ПРОВАЛ: ' + m); else say('ok: ' + m); };
G.settings.easy = false; { let n = 0; while ((G.mode !== 'menu' || g.loading) && n++ < 3000) sim(2); } want(G.ui.cur === 'menu' && !document.querySelector('[data-a=cont]'), 'меню без «Продолжить» на чистом профиле'); G.ui.handler('new'); sim(90); T.flush(); say('--- ОБЩАГА', T.state());
// записка
want(T.grab('note_dorm') === 1, 'записка'); T.flush(); want(G.save.inv.note_dorm === 1, 'записка в инвентаре');
// код
{ const code = String(f('dormCode')); T.use('Кодовый замок', false); sim(5); want(G.ui.cur === 'pad', 'клавиатура открыта'); for (const d of code) { G.ui.handler('d', d); sim(2); } sim(10); T.flush(); want(f('dorm_open'), 'подвал открыт кодом ' + code); }
want(T.breakCrate('spray'), 'дихлофос из ящика'); T.flush();
// босс
T.tp(33, -3.6, 0, Math.PI / 2); sim(10); want(G.mode !== 'play', 'кат-сцена Царя'); T.flush(); want(T.boss() && T.boss().active, 'Царь активен'); T.fight(40); want(f('dorm_boss') && G.save.inv.key_dorm, 'Царь побеждён, ключ'); say(T.state());
T.use('Выйти на улицу', false); T.flush(); sim(60); T.flush(); want(G.level.id === 'murino', 'переход в Мурино'); say('--- МУРИНО', T.state());
// Мурино
T.use('Друн'); want(G.save.gear.ult === 1, 'ульта от Друна'); T.use('Курьер'); want(f('m_cour'), 'квест курьера'); want(T.breakCrate('parcel'), 'посылка'); T.use('Курьер'); want(G.save.inv.pass === 1, 'пропуск');
// ливт: симон по-честному
{ T.use('Вызвать ливт', false); let guard = 0; while (G.ui.cur !== 'simon' && guard++ < 400) { G.ui.adv = true; sim(2); } want(G.ui.cur === 'simon', 'симон открыт');
  let rounds = 0; guard = 0; let seq = [], last = 0, phase = '';
  while (G.ui.cur === 'simon' && guard++ < 40000) {
    const t = document.querySelector('#sm-t'), txt = t ? t.textContent : ''; const lit = document.querySelector('.pad .lit');
    if (txt === 'СМОТРИ') { if (phase !== 'see') { phase = 'see'; seq = []; last = 0; } const n = lit ? +lit.id.slice(2) : 0; if (n && n !== last) seq.push(n); last = n; }
    else if (txt === 'ПОВТОРИ' && phase === 'see') { phase = 'rep'; rounds++; for (const n of seq) G.ui.handler('d', n); }
    sim(1);
  }
  T.flush(); want(f('m_lift') && rounds === 3, 'симон пройден, раундов ' + rounds); want(Math.abs(P.pos.y - 90.4) < 1, 'на крыше y=' + P.pos.y.toFixed(1)); }
T.tp(0, 90.4, 70, Math.PI); sim(10); want(G.mode !== 'play', 'кат-сцена Тёмного Друна'); T.flush(); T.fight(50); want(f('m_boss') && G.save.gear.kicks === 1, 'Тёмный Друн побеждён, кроссы'); say(T.state());
T.use('Ливт вниз'); want(P.pos.y < 2, 'спустился в лобби');
T.use('Машинист', [0]); sim(60); T.flush(); want(G.level.id === 'milk', 'приехал в Молочное'); say('--- МОЛОЧНОЕ', T.state());
// Молочное
T.use('Кондукторша'); want(f('k_talk'), 'кондукторша'); T.use('Дед'); want(f('k_ded'), 'дед дал задание');
{ const ga = T.ents(e => e.tag === 'garden'); want(ga.length === 5, 'паучностей на огороде: ' + ga.length); for (const e of ga) e.hurt(999, P.pos, 0, 'melee'); sim(60); want(f('k_garden'), 'огород чист'); }
T.use('Дед'); want(G.save.inv.fuse === 1, 'предохранитель'); T.use('Вставить предохранитель'); want(f('k_fuse'), 'предохранитель вставлен');
{ const wp = G.level.wp, sol = [[1, 2, 0, 0], [0, 0, 0, 0], [0, 0, 2, 0], [0, 0, 0, 1]], path = [[0, 0], [1, 0], [1, 1], [1, 2], [2, 2], [2, 3], [3, 3]]; let turns = 0;
  for (const [i, j] of path) { const t = wp.tiles[j * 4 + i]; const it = G.level.inter.find(x => x.label === 'Повернуть' && Math.abs(x.pos.x - t.g.position.x) < .1 && Math.abs(x.pos.z - t.g.position.z) < .1); let n = 0; while ((t.r & 3) !== sol[j][i] && n++ < 5) { if (f('k_power')) break; P.place(it.pos.x, it.pos.y - .8, it.pos.z + .3); sim(2); if (P.near !== it) say('!! плитка недоступна', i, j, P.near && P.near.label); G.input.press('interact'); sim(3); turns++; } }
  sim(20); T.flush(); want(f('k_power'), 'ток пошёл, поворотов ' + turns); }
want(T.breakCrate('crank'), 'ручка контроллера'); say(T.state());
T.use('Кондукторша', false); T.flush(); sim(30); T.flush(); want(f('k_ride') && Math.hypot(P.pos.x - 300, P.pos.z - 317) < 3, 'приехал в яму: ' + P.pos.toArray().map(v => v.toFixed(0))); want(T.boss() && T.boss().active, 'Матка активна');
T.fight(60); want(f('k_boss') && G.save.inv.btn1 === 1, 'Матка побеждена, кнопка 1'); T.use('Вылезти по паутине'); want(P.pos.x < 0, 'вылез из ямы'); say(T.state());
T.use('Кондукторша', [0]); sim(60); T.flush(); want(G.level.id === 'murino', 'вернулся в Мурино'); say(T.state());
T.use('Машинист', [1]); sim(60); T.flush(); want(G.level.id === 'myt', 'приехал в Мытищи'); say('--- МЫТИЩИ', T.state());
// Мытищи
T.use('Вахтёр чистоты'); want(f('y_talk'), 'вахтёр'); T.use('Банщица'); want(f('y_att'), 'банщица');
{ const sp = G.level.sp, moves = [[2, 0, -1, 0], [3, 1, 1, 0], [4, 2, 0, -1], [4, 0, -1, 0], [0, 0, 0, 1], [0, 4, 1, 0], [5, 1, 0, 1]]; let okm = 0;
  for (const [i, j, di, dj] of moves) { const b = sp.blocks.find(b => b.i === i && b.j === j); if (!b) { say('!! нет блока в', i, j); break; } P.place(b.x - di * 1.35, .08, b.z - dj * 1.35); sim(3); if (P.near !== b.it) say('!! мыло недоступно', i, j, P.near && P.near.label, P.pos.toArray().map(v => v.toFixed(1))); G.input.press('interact'); sim(3); let n = 0; while (sp.busy && n++ < 200) sim(1); okm++; }
  sim(30); T.flush(); want(f('y_wash') && G.save.inv.soap === 1, 'мыло в мыльницах, пропуск, ходов ' + okm); }
T.use('Брал'); want(!f('y_bral'), 'Брал без хлеба'); T.use('Продавщица', false); { let n = 0; while (G.ui.cur !== 'shop' && n++ < 300) { G.ui.adv = true; sim(2); } want(G.ui.cur === 'shop', 'магазин открыт'); const m0 = G.save.money; G.ui.handler('buy', 0); sim(2); want(G.save.inv.bread === 1 && G.save.money === m0 - 8, 'куплен хлеб'); G.ui.handler('back'); sim(5); T.flush(); } { const h0 = G.save.gear.hp || 0; T.use('Брал', [0]); want(f('y_bral') && G.save.gear.hp === h0 + 1, 'Брал получил хлеб, дал вкусность'); } T.use('Вахтёр чистоты'); want(f('y_gate'), 'ворота открыты');
T.tp(0, 0, 30, 0); sim(10); want(G.mode !== 'play', 'кат-сцена Мойдодыра'); T.flush(); T.fight(70); want(f('y_boss') && G.save.inv.btn2 === 1, 'Мойдодыр побеждён, кнопка 2'); say(T.state());
T.use('Машинист', [0]); sim(60); T.flush(); want(G.level.id === 'murino', 'вернулся в Мурино');
T.use('Машинист', [2]); sim(60); T.flush(); want(G.level.id === 'banya', 'приехал в Баньку'); say('--- БАНЬКА', T.state());
// Банька
T.use('Дод'); want(f('b_dod'), 'Дод'); want(T.grab('wood') === 3, 'дрова x3'); want(T.grab('venik') === 1, 'веник'); say(T.state());
T.use('Пра Дод', [1]); want(f('b_ok'), 'Пра Дод принял дрова и веник');
T.use('Затопить печь', [1, 1, 1, 2, 1, 2]); sim(30); T.flush(); want(f('b_fire'), 'печь 100°'); sim(30); T.flush(); want(T.boss() && T.boss().active, 'Банник активен; игрок ' + P.pos.toArray().map(v => v.toFixed(0)));
{ // разбег через прорубь: встать за прорубью напротив босса
  const b = T.boss(); G.god = true; let cold = 0, t = 0; while (t < 150 && !cold) { const a = Math.atan2(30 - b.pos.x, 36 - b.pos.z); P.pos.set(30 + Math.sin(a) * 9, 0, 36 + Math.cos(a) * 9); sim(1); t += 1 / 30; if (b.vul > 1.5) cold = 1; } want(cold, 'Банник нырнул в прорубь за ' + t.toFixed(0) + 'с'); G.god = false; }
T.fight(60); want(f('b_boss') && G.save.inv.btn3 === 1, 'Банник побеждён, кнопка 3'); T.use('Попариться'); want(P.hp === P.maxHp, 'попарился'); say(T.state());
T.use('Машинист', [0]); sim(60); T.flush(); want(G.level.id === 'murino', 'вернулся в Мурино'); say(T.state());
T.tp(0, .1, 60, 0); T.use('Вызвать ливт', false); T.flush(); sim(60); T.flush(); want(G.level.id === 'final', 'финал'); say('--- ФИНАЛ', T.state());
// финал
T.tp(0, 0, -8, 0); sim(10); want(G.mode !== 'play', 'кат-сцена ФОГа'); T.flush(); { const b = T.boss(); want(b && b.active, 'ФОГ активен'); G.god = true; let t = 0, stuck = 0, hit = 0;
  const run = (sec, tag) => { let t = 0, s = 0; while (t < sec && !b.dead) { G.input.keys.up = true; G.cam.yaw += .03; sim(1); t += 1 / 30; for (const h of [...b.hands, b.face]) if (!h.dead) { s++; if (s % 20 === 0) h.hurt(30, P.pos, 0, 'melee'); } } G.input.keys = {}; say(`ФОГ фаза ${b.ph} (${tag}): ${t.toFixed(0)}с, hp ${b.hp}, кадров с уязвимой частью ${s}`); };
  run(45, 'ф1'); b.hp = b.maxHp * .58; run(45, 'ф2'); b.hp = b.maxHp * .26; run(60, 'ф3'); if (!b.dead) { b.hp = 1; b.hitPart(b.face, 5); } sim(120); G.god = false; let n = 0; while (G.ui.cur !== 'end' && n++ < 3000) { G.ui.adv = true; sim(2); } want(G.ui.cur === 'end' && G.mode === 'end', 'экран концовки: ' + (document.querySelector('.cred') || {}).innerText); }
say(T.state()); G.ui.handler('menu'); sim(120); want(G.mode === 'menu', 'вернулись в меню'); want(g.hasSave(), 'сохранение есть');
g.continue(); sim(90); T.flush(); want(G.level.id === 'final' && f('f_boss'), 'продолжить -> двор после победы'); T.use('Друн', [2]); say(T.state());
} catch (e) { say('!! ИСКЛЮЧЕНИЕ: ' + (e.stack || e)); }
return log.join('\n') + '\nОШИБКИ(' + errs.length + '):\n' + [...new Set(errs)].join('\n');
