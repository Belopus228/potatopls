try {
const g = G.game, P = G.player, f = k => g.flag(k);
const run = (name, setup, sec = 240) => { try { setup(); sim(20); T.flush(); const b = T.boss(); if (!b || !b.active) { say('!! босс не активен: ' + name + ' ' + T.state()); return; } say('· ' + name + ' — снаряжение ' + JSON.stringify(G.save.gear) + ' еда ' + JSON.stringify(G.save.inv)); T.bot(sec); } catch (e) { say('!! ' + name + ': ' + (e.stack || e)); } };
run('общага', () => { T.chapter('dorm', 'base'); G.save.gear.spray = 1; G.save.flags.dorm_open = 1; g.travel('dorm', 'base'); sim(90); T.flush(); T.walk(21, 0, 5); T.walk(30, 0, 8); });
run('мурино', () => { T.chapter('murino', 'roof'); G.save.gear.ult = 1; T.walk(0, 70, 8); });
run('молочное', () => { T.chapter('milk', 'pit'); });
run('мытищи', () => { T.chapter('myt', 'gate'); G.save.inv.soap = 1; T.use('Вахтёр чистоты'); T.walk(0, 20, 5); T.walk(0, 29, 8); });
run('банька', () => { T.chapter('banya'); G.save.flags.b_fire = 1; G.save.flags.b_dod = 1; G.save.flags.b_ok = 1; g.travel('banya', 'lake'); sim(90); T.flush(); });
run('финал', () => { T.chapter('final'); T.walk(0, -15, 6); }, 400);
return log.join('\n') + '\nОШИБКИ(' + errs.length + '):\n' + [...new Set(errs)].join('\n');
} catch (e) { return log.join('\n') + '\n!! ИСКЛЮЧЕНИЕ ' + (e.stack || e); }
