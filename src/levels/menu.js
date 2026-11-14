// Фон главного меню: двор в Мурино, дождь, Ч танцует под фонарём
import { G, PI } from '../g.js';
import { LEVELS } from '../game.js';
import { M, photoTex } from '../tex.js';
import { block, lampPost, car, bench, tree } from '../kit.js';
import { NPC } from '../actors.js';
import { FACE } from '../faces.js';
import { NIGHT } from './murino_env.js';

LEVELS.menu = {
  id: 'menu', title: '', music: 'menu', weather: 'rain', seed: 3, env: NIGHT,
  build(L) {
    L.box(M.asphalt(.6), 0, -.25, 0, 220, .5, 220);
    block(L, 0, -34, 54.4, 13.6, 16, 0, { doors: 3 }); block(L, -40, -6, 13.6, 40.8, 22, 1, { rot: 0 }); block(L, 42, -10, 13.6, 34, 12, 2); block(L, 10, -80, 68, 13.6, 40, 3, { far: 1, solid: false }); block(L, -70, -70, 34, 13.6, 60, 1, { far: 1, solid: false }); block(L, 80, -60, 34, 13.6, 80, 0, { far: 1, solid: false });
    lampPost(L, -3.5, -2, 0, 0xffc98a, 6.2, 0); lampPost(L, 14, -14, 0, 0x9fd0ff, 6.2, PI); car(L, 7, -6, .4, 0xb02a2a); car(L, -9, -12, -1.2, 0x2a5ab0); bench(L, -1, -5.5, 0); tree(L, -12, -3, 1.1, 'bare'); tree(L, 16, -4, 1, 'bare');
    L.sign('МУРИНО — ЭТО\nНЕ ЖМУРИНО!', 0, 9, -27.1, 14, 3.6, 0, { bg: '#0d1626', fg: '#7fe0ff', glow: 1.7, border: '#7fe0ff' });
    L.cps.start = [0, 0, 0, 0];
    const ch = G.game.spawn(new NPC(0, 0, 0, { look: { face: photoTex(FACE.ch), top: 0xf7f7f5, pants: 0x1c1e25, shoes: 0xf4f4f4, hair: 0x2a2018, chain: true }, anim: 'dance', still: true, solid: false }));
    L.onUpdate((dt, t) => { const a = .5 + Math.sin(t * .07) * .55; G.cam.shot(Math.sin(a) * 6.2 + 1.6, 1.5 + Math.sin(t * .11) * .3, Math.cos(a) * 6.2, 2.4, 1.55, 0, t < .1, 1.5); G.gfx.focus.set(0, 0, 0); });
  },
};
