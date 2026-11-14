// смена качества на лету: лампы уровня сохраняются, кадр рисуется без ошибок; авто-снижение при малом FPS
try {
await T.ready(); const want = (c, m) => say((c ? 'ok: ' : '!! ПРОВАЛ: ') + m); const g = G.gfx;
G.game.startChapter('murino'); sim(150); T.flush(); const n0 = g.lamps.length; want(n0 > 5, 'ламп на уровне: ' + n0);
for (const q of [1, 2, 3, 0, 2]) { g.setQuality(q); g.focus.copy(G.player.pos); for (let i = 0; i < 20; i++) g.updateLamps(.1); g.render(.016); const lit = g.slots.filter(s => s.cur && s.l.intensity > 1).length;
  want(g.lamps.length === n0 && g.slots.length === [0, 2, 4, 6][q] && lit === g.slots.length && !!g.composer === (q >= 2), `качество ${q}: ламп ${g.lamps.length}, слотов ${g.slots.length}, горит ${lit}, блум ${!!g.composer}`); }
// авто-снижение: имитируем 1 кадр в секунду на минимальном разрешении
G.settings.dyn = true; g.setQuality(2); G.settings.q = 2; g.scale = .55; g.slow = 0; let steps = 0; while (G.q === 2 && steps++ < 12) { g.acc = 0; g.frames = 0; g.render(1.01); }
want(G.q === 1 && G.settings.q === 1 && steps <= 6, `авто-снижение качества: q=${G.q} за ${steps} «секунд», масштаб ${g.scale}`);
want(/графика снижена/.test(G.ui.toasts.textContent), 'подсказка о снижении показана');
G.settings.dyn = false; g.scale = 1; g.resize(); g.render(.016);
return log.join('\n') + '\nОШИБКИ(' + errs.length + '):\n' + [...new Set(errs)].join('\n');
} catch (e) { return log.join('\n') + '\n!! ИСКЛЮЧЕНИЕ ' + (e.stack || e); }
