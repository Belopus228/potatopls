try {
const g = G.game, P = G.player, f = k => g.flag(k); G.god = true;
T.ready(); G.ui.handler('new'); sim(90); T.flush(); say('--- общага пешком', T.state());
T.path([[-5, 2.4], [-5, 0], [14.9, 0], [15, 2.9]], 'комната -> кухня'); sim(20); T.flush(); say('записка: ' + G.save.inv.note_dorm);
T.path([[15, 0], [18.6, 0]], 'кухня -> замок'); say('near=' + (P.near && P.near.label));
{ const code = String(f('dormCode')); G.input.press('interact'); sim(4); for (const d of code) { G.ui.handler('d', d); sim(2); } sim(30); T.flush(); say('подвал открыт: ' + f('dorm_open')); }
T.path([[15, 0], [15, -2.8], [17.6, -2.6]], 'к ящику с дихлофосом'); for (let i = 0; i < 12; i++) { G.input.press('attack'); sim(12); } sim(30); say('дихлофос: ' + G.save.gear.spray);
T.path([[15, -2.8], [15, 0], [18.6, 0], [21, 0], [26.6, 0], [30, 0]], 'лестница в подвал'); say('y в подвале: ' + P.pos.y.toFixed(2)); sim(10); T.flush();
T.fight(5); say('ключ: ' + G.save.inv.key_dorm);
T.path([[27.5, 0], [21, 0], [-19, 0], [-24.6, 0]], 'подвал -> выход'); say('y наверху: ' + P.pos.y.toFixed(2) + ' near=' + (P.near && P.near.label));
G.input.press('interact'); sim(10); T.flush(); sim(90); T.flush(); say('--- Мурино пешком', T.state());
T.path([[-30, 8], [-22, 16.6]], 'старт -> Друн'); say('near=' + (P.near && P.near.label)); G.input.press('interact'); sim(4); T.flush();
T.path([[-10, 24], [20, 24], [38.6, 20.4]], 'Друн -> курьер'); say('near=' + (P.near && P.near.label)); G.input.press('interact'); sim(4); T.flush();
T.path([[30, 0], [0, -30], [0, -43]], 'курьер -> гаражи (север)');
const gap = T.walk(-2, -54, 8); say('щель между гаражами 0.8 м проходима: ' + gap);
if (!gap) { T.path([[-33, -43], [-30.05, -44.4], [-30.05, -52], [-20, -56], [0, -56.4]], 'вход в ГСК у вывески'); }
T.walk(0.6, -56.5, 6); for (let i = 0; i < 10; i++) { G.input.press('attack'); sim(12); } sim(40); T.grab('parcel'); say('посылка: ' + G.save.inv.parcel);
return log.join('\n') + '\nОШИБКИ(' + errs.length + '):\n' + [...new Set(errs)].join('\n');
} catch (e) { return log.join('\n') + '\n!! ИСКЛЮЧЕНИЕ ' + (e.stack || e); }
