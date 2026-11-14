// статистика HDR-яркости кадра без блума (для подбора порогов)
function h2f(h) { const s = (h & 0x8000) ? -1 : 1, e = (h & 0x7C00) >> 10, f = h & 0x03FF; if (e === 0) return s * Math.pow(2, -14) * (f / 1024); if (e === 31) return f ? NaN : s * Infinity; return s * Math.pow(2, e - 15) * (1 + f / 1024); }
function hdr(tag) {
  const g = G.gfx; if (!g.composer) return 'нет композера';
  g.focus.copy(G.player.pos); for (let i = 0; i < 40; i++) g.updateLamps(.1); const was = g.bloom.enabled; g.bloom.enabled = false; g.render(.016); g.bloom.enabled = was;
  const rt = g.composer.writeBuffer, w = rt.width, h = rt.height, buf = new Uint16Array(w * h * 4); g.renderer.readRenderTargetPixels(rt, 0, 0, w, h, buf);
  const v = new Float32Array(w * h); for (let i = 0; i < w * h; i++) v[i] = Math.max(h2f(buf[i * 4]), h2f(buf[i * 4 + 1]), h2f(buf[i * 4 + 2]));
  // отдельно нижняя половина кадра (земля/стены) — буфер снизу вверх
  const s = Array.from(v).sort((a, b) => a - b), q = p => s[Math.min(s.length - 1, Math.floor(p * s.length))].toFixed(2), over = t => (100 * s.filter(x => x > t).length / s.length).toFixed(1) + '%';
  say(`${tag}: ${w}x${h} p50 ${q(.5)} p75 ${q(.75)} p90 ${q(.9)} p97 ${q(.97)} p99.5 ${q(.995)} max ${q(1)} | >1: ${over(1)} >1.5: ${over(1.5)} >2: ${over(2)} >3: ${over(3)} | thr ${g.bloom.threshold} str ${g.bloom.strength} | лампы ${g.slots.filter(s => s.cur).map(s => Math.round(s.l.intensity)).join(',')}`);
}
const V = { dorm: [[0, 0, 0, Math.PI / 2], [15, 0, 3, 0], [-20, 0, 0, -Math.PI / 2]], murino: [[-20, 0, 10, .5], [0, 0, 30, Math.PI], [20, 0, -20, 2]], milk: [[-20, 1.4, 0, Math.PI / 2], [10, 1.4, 6, 0]], myt: [[0, 0, -8, 0], [0, 0, 20, Math.PI], [12, 0, 10, 1]], banya: [[4, 1, -24, -.6], [0, 1, -6, 2]], final: [[0, 0, -20, 0], [6, 0, -4, Math.PI]] };
await T.ready();
for (const id of (window.HDR_LV || Object.keys(V))) {
  G.game.startChapter(id); sim(150); T.flush();
  for (const [x, y, z, yaw] of V[id]) { const gy = G.level.world.ground(x, z, y + 3); G.player.place(x, gy, z, yaw); G.cam.yaw = yaw + Math.PI; G.cam.snap(); sim(12); hdr(id + ' @' + x + ',' + z); }
}
return log.join('\n') + '\nerrors: ' + errs.length + ' ' + errs.slice(0, 3).join(' | ');
