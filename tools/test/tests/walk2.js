try {
const g = G.game, P = G.player, f = k => g.flag(k), press = () => { G.input.press('interact'); sim(4); }; G.god = true;
// Мурино: подъезд, ливт, станция
T.chapter('murino'); G.save.inv.pass = 1; say('--- Мурино', T.state());
T.path([[-28, -40], [-28, -53], [-4, -56.4]], 'двор -> вход ГСК -> проезд');
T.path([[-28, -54], [-28, -40], [-24, 0], [0, 30], [0, 51.4]], 'ГСК -> подъезд П-46'); say('near=' + (P.near && P.near.label)); press(); T.flush(); sim(40);
T.path([[0, 55], [1.2, 61.2]], 'подъезд -> ливт'); say('near=' + (P.near && P.near.label));
T.path([[0, 55], [0, 49], [30, 20], [56, -24], [64.5, -24]], 'ливт -> станция'); say('y на платформе=' + P.pos.y.toFixed(2) + ' near=' + (P.near && P.near.label));
// Молочное
T.chapter('milk'); say('--- Молочное', T.state());
T.path([[-67, 26.4]], 'к кондукторше'); say('near=' + (P.near && P.near.name || P.near && P.near.label)); press(); T.flush();
T.path([[-60, 22], [-56, 0], [10, 0], [29, -5.2]], 'остановка -> улица -> Дед'); say('near=' + (P.near && P.near.label)); press(); T.flush();
T.path([[26, -8], [26, -23], [33, -27]], 'Дед -> огород'); 
T.path([[26, -23], [10, -30], [-36, -36], [-36, -41], [-36, -52.3]], 'огород -> трансформатор'); say('near=' + (P.near && P.near.label));
T.path([[-36, -41], [-36, -34], [0, 4], [38, 4], [40, 66], [42.2, 84]], 'трансформатор -> гнездо', ); say('у ящика с ручкой: ' + P.pos.toArray().map(v => v.toFixed(1)));
T.path([[40, 66], [38, 34], [-60, 23], [-66.5, 25.6]], 'гнездо -> остановка');
T.path([[40, 30], [62, -10], [67, -24], [80, -24], [97, -24]], 'пляж и пирс'); say('y на пирсе=' + P.pos.y.toFixed(2));
// Мытищи
T.chapter('myt'); say('--- Мытищи', T.state());
T.path([[0, -40], [0, -6], [3, 20.6]], 'станция -> вахтёр'); say('near=' + (P.near && P.near.label)); press(); T.flush();
T.path([[-10, 14], [-19, 6], [-24.4, 6], [-23.6, 8.4]], 'вахтёр -> душевая'); say('near=' + (P.near && P.near.label)); press(); T.flush();
T.path([[-23.5, 2.6]], 'к рычагу'); say('near=' + (P.near && P.near.label));
T.path([[-23.5, 6], [-19, 6], [10, 8], [25.2, 9.4]], 'душевая -> магазин'); say('near=' + (P.near && P.near.label));
T.path([[0, -6], [-5, -16.6]], 'к Бралу'); say('near=' + (P.near && P.near.label));
G.save.inv.soap = 1; T.use('Вахтёр чистоты'); T.path([[0, 20], [0, 26.5]], 'ворота'); T.flush(); say('в арене: ' + (G.mode) + ' ' + P.pos.toArray().map(v => v.toFixed(1)));
// Банька
T.chapter('banya'); say('--- Банька', T.state());
T.path([[0, -72], [0, -30], [-6, -14], [-7.6, -12.2]], 'станция -> Дод'); say('near=' + (P.near && P.near.label)); press(); T.flush();
T.path([[-8, -4], [-9.6, 1.6]], 'Дод -> Пра Дод'); say('near=' + (P.near && P.near.label));
T.path([[-6, -8], [-8.4, -8]], 'к двери баньки'); T.path([[-6, -18], [-15, -17.2]], 'к топке'); say('near=' + (P.near && P.near.label));
T.path([[-24, -20], [-46, 13]], 'к дровам 1'); T.path([[-22, 63]], 'к дровам 2'); T.path([[0, 70], [40, 68], [66, 66], [66, 68.6]], 'к сараю'); say('веник: ' + G.save.inv.venik + ' дрова: ' + G.save.inv.wood);
T.path([[70, 40], [62, -17]], 'к дровам 3'); sim(30); say('дрова: ' + G.save.inv.wood); T.path([[30, -20], [6, -10], [-9.6, 1.6]], 'обратно к Пра Доду');
T.path([[10, 10], [18, 24], [26, 33]], 'на озеро к проруби'); say('у проруби y=' + P.pos.y.toFixed(2)); T.walk(30, 36, 4); sim(30); say('в проруби -> ' + P.pos.toArray().map(v => v.toFixed(1)) + ' hp=' + P.hp);
// финал
T.chapter('final'); say('--- Финал', T.state()); T.path([[0, -17]], 'во двор'); sim(5); say('mode=' + G.mode);
return log.join('\n') + '\nОШИБКИ(' + errs.length + '):\n' + [...new Set(errs)].join('\n');
} catch (e) { return log.join('\n') + '\n!! ИСКЛЮЧЕНИЕ ' + (e.stack || e); }
