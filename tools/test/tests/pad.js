// геймпад (подмена navigator.getGamepads): движение, камера, кнопки
try {
await T.ready(); const want = (c, m) => say((c ? 'ok: ' : '!! ПРОВАЛ: ') + m);
G.game.startChapter('murino'); sim(150); T.flush(); const P = G.player; T.tp(0, 0, 30, 0);
const pad = { connected: true, axes: [0, 0, 0, 0], buttons: Array.from({ length: 17 }, () => ({ pressed: false, value: 0 })) };
Object.defineProperty(navigator, 'getGamepads', { value: () => [pad], configurable: true });
const p0 = P.pos.clone(); pad.axes[1] = -1; sim(30); pad.axes[1] = 0; want(P.pos.distanceTo(p0) > 2, 'стик вперёд: прошёл ' + P.pos.distanceTo(p0).toFixed(1) + ' м');
const y0 = G.cam.yaw; pad.axes[2] = 1; sim(20); pad.axes[2] = 0; want(Math.abs(G.cam.yaw - y0) > .2, 'правый стик крутит камеру: ' + (G.cam.yaw - y0).toFixed(2));
sim(20); const seen = {}; const _hit = G.input.hit.bind(G.input);
for (let i = 0; i < 16; i++) { const before = { mode: G.mode, cur: G.ui.cur, atk: !!P.atk, y: P.pos.y, roll: P.rollT }; pad.buttons[i].pressed = true; sim(2); const after = { mode: G.mode, cur: G.ui.cur, atk: !!P.atk, vy: P.vel.y, roll: P.rollT }; pad.buttons[i].pressed = false; sim(2);
  let what = ''; if (after.atk && !before.atk) what = 'удар'; else if (after.vy > 1) what = 'прыжок'; else if (after.roll > 0 && !(before.roll > 0)) what = 'перекат'; else if (after.mode !== before.mode || after.cur !== before.cur) what = 'экран ' + after.mode + '/' + after.cur;
  seen[i] = what; if (G.mode !== 'play') { G.ui.handler && G.ui.handler('back'); sim(5); if (G.mode !== 'play') { G.ui.resume && G.ui.resume(); sim(5); } } sim(40); }
say('кнопки: ' + Object.entries(seen).filter(([, v]) => v).map(([k, v]) => k + '=' + v).join(', '));
want(Object.values(seen).includes('удар') && Object.values(seen).includes('прыжок') && Object.values(seen).includes('перекат'), 'кнопки геймпада: удар, прыжок, перекат');
want(Object.values(seen).some(v => v.startsWith('экран pause')), 'кнопка паузы на геймпаде');
return log.join('\n') + '\nОШИБКИ(' + errs.length + '):\n' + [...new Set(errs)].join('\n');
} catch (e) { return log.join('\n') + '\n!! ИСКЛЮЧЕНИЕ ' + (e.stack || e); }
