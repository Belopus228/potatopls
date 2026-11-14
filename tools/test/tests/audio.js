// проверка звука: разблокировка, все эффекты, все треки — без исключений
await T.ready();
const A = G.audio; let ok = true;
try { A.unlock(); } catch (e) { say('!! unlock: ' + e); ok = false; }
say('ctx: ' + (A.ctx ? A.ctx.state + ' sr ' + A.ctx.sampleRate : 'нет'));
const used = new Set(); // имена, реально вызываемые в коде, собираем перехватом
const names = ['step', 'jump', 'land', 'whoosh', 'hit', 'hit2', 'hurt', 'coin', 'pick', 'item', 'ui', 'ui2', 'deny', 'talk', 'throw', 'cash', 'spray', 'eat', 'door', 'lever', 'boom', 'slam', 'zap', 'roar', 'screech', 'squish', 'splash', 'bubble', 'steam', 'bell', 'ding', 'quest', 'win', 'lose', 'power', 'tram', 'fog', 'am'];
for (const n of names) { try { A.sfx(n); A.sfx(n, .5); } catch (e) { say('!! sfx ' + n + ': ' + e); ok = false; } }
try { A.vox(A.ctx ? A.ctx.currentTime : 0, 150, 1); A.vox(A.ctx ? A.ctx.currentTime : 0, 90, 1.4); } catch (e) { say('!! vox: ' + e); ok = false; }
const tracks = [...new Set(Object.values(G.game.constructor.LEVELS || {}).map(l => l.music))];
say('треки уровней: ' + JSON.stringify(Object.keys(window.__LV || {})));
for (const t of ['menu', 'dorm', 'murino', 'milk', 'clean', 'banya', 'boss', 'final', 'fog', 'calm', 'end']) {
  try { A.music(t); const has = !!A.track; for (let i = 0; i < 400; i++) { A.next = A.ctx ? A.ctx.currentTime : 0; A.update(); } say(`трек ${t}: ${has ? 'есть' : 'НЕТ'}, шаг ${A.step}`); } catch (e) { say('!! music ' + t + ': ' + (e.stack || e)); ok = false; }
}
A.music(null);
// какие имена звуков/треков вызываются из игры, но не описаны
const _sfx = A.sfx.bind(A), _mus = A.music.bind(A); const seenS = new Set(), seenM = new Set(); A.sfx = (n, k) => { seenS.add(n); return _sfx(n, k); }; A.music = n => { seenM.add(n); return _mus(n); };
for (const id of ['dorm', 'murino', 'milk', 'myt', 'banya', 'final']) { G.game.startChapter(id); sim(120); T.flush(); const p = G.player; for (let i = 0; i < 60; i++) { G.input.press(['attack', 'jump', 'dodge', 'throw'][i % 4]); G.input.keys.up = i % 20 < 12; sim(6); } G.input.keys = {}; }
say('вызванные sfx: ' + [...seenS].join(',')); say('неизвестные sfx: ' + ([...seenS].filter(n => !names.includes(n)).join(',') || '—')); say('вызванные треки: ' + [...seenM].join(','));
say(ok ? 'ok: звук без исключений' : '!! были исключения');
return log.join('\n') + '\nОШИБКИ(' + errs.length + '): ' + errs.slice(0, 5).join(' | ');
