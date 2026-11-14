// Точка входа
import { G } from './g.js';
import { Gfx } from './gfx.js';
import { Input } from './input.js';
import { Audio } from './audio.js';
import { Fx } from './fx.js';
import { Cam } from './camera.js';
import { Player } from './player.js';
import { UI } from './ui.js';
import { Game, LEVELS } from './game.js';
import './levels/index.js';

const canvas = document.getElementById('c'), q = new URLSearchParams(location.search), boot = document.getElementById('boot');
const fail = e => { const m = String((e && (e.stack || e.message)) || e).slice(0, 600); console.error(m); let d = document.getElementById('err'); if (!d) { d = document.createElement('pre'); d.id = 'err'; d.style.cssText = 'position:fixed;left:6px;bottom:6px;z-index:999;max-width:90vw;max-height:40vh;overflow:auto;background:rgba(120,0,0,.9);color:#fff;font:11px monospace;padding:6px;border-radius:6px;white-space:pre-wrap;pointer-events:none'; document.body.appendChild(d); } d.textContent = m; };
addEventListener('error', e => fail(e.error || e.message)); addEventListener('unhandledrejection', e => fail(e.reason));
try {
  G.mobile = matchMedia('(pointer:coarse)').matches || /Android|iPhone|iPad|iPod/i.test(navigator.userAgent); G.touch = false;
  const game = G.game = new Game(); game.loadSettings(); if (q.has('q')) G.q = G.settings.q = +q.get('q'); if (q.has('god')) G.god = true; if (q.has('nodyn')) G.settings.dyn = false;
  G.gfx = new Gfx(canvas); G.audio = new Audio(); G.ui = new UI(); G.input = new Input(canvas); G.fx = new Fx(G.gfx.scene); G.cam = new Cam(G.gfx.camera);
  G.save = game.defaults(); G.player = new Player(); G.gfx.scene.add(G.player.root); G.audio.setVol(G.settings.vol, G.settings.music);
  if (G.mobile || q.has('touch')) G.input.setTouch(true);
  const unlock = () => G.audio.unlock(); addEventListener('pointerdown', unlock, true); addEventListener('keydown', unlock, true);
  document.addEventListener('visibilitychange', () => { if (document.hidden) { if (G.mode === 'play') game.pause(); game.write(); } });
  addEventListener('pagehide', () => game.write());
  if (q.has('lv') && LEVELS[q.get('lv')]) game.startChapter(q.get('lv'), q.get('cp') || 'start'); else game.toMenu();
  let last = performance.now(), n = 0;
  const step = (dt, render) => {
    const inp = G.input; inp.update(dt); if (inp.hit('pause')) { if (G.mode === 'play') game.pause(); } if (inp.hit('inv')) { if (G.mode === 'play') G.ui.inventory(); }
    if (G.mode === 'pause') dt = 0; else if (G.hitstop > 0) { G.hitstop -= dt; dt *= .06; }
    G.dt = dt; G.time += dt;
    if (G.mode !== 'pause') { game.update(dt); G.cam.update(dt || .0001); G.fx.update(dt); }
    G.ui.update(dt); G.audio.update(); if (render) G.gfx.render(dt); inp.endFrame();
  };
  const frame = t => {
    requestAnimationFrame(frame); const dt = Math.min(.05, Math.max(.0005, (t - last) / 1000)); last = t;
    try { step(dt, true); } catch (e) { fail(e); G.input.endFrame(); }
    if (++n === 3) { boot.style.opacity = 0; setTimeout(() => boot.remove(), 600); }
  };
  // отладка/автотесты: прогнать n кадров симуляции без отрисовки
  window.sim = (n, dt = 1 / 30) => { for (let i = 0; i < n; i++) step(dt, false); return G.mode; };
  requestAnimationFrame(frame); window.G = G;
} catch (e) { fail(e); boot.querySelector('.bs').textContent = 'Ошибка запуска: нужен браузер с WebGL2'; }
