// утечки GPU-памяти: повторная загрузка уровня не должна наращивать число текстур и геометрий
try {
await T.ready();
const g = G.gfx, info = g.renderer.info, want = (c, m) => say((c ? 'ok: ' : '!! ПРОВАЛ: ') + m);
for (const id of ['dorm', 'murino', 'milk', 'myt', 'banya', 'final']) {
  const rows = [];
  for (let k = 0; k < 3; k++) { G.game.startChapter(id); sim(150); T.flush(); g.render(.016); rows.push([info.memory.geometries, info.memory.textures]); }
  want(rows[2][0] === rows[1][0] && rows[2][1] === rows[1][1], `${id}: геометрий ${rows.map(r => r[0]).join(' → ')}, текстур ${rows.map(r => r[1]).join(' → ')}`);
}
// враги, убитые в бою, тоже должны освобождать свои текстуры костей
{ G.game.startChapter('murino'); sim(150); T.flush(); g.render(.016); const t0 = info.memory.textures; let n = 0;
  for (const e of [...G.ents]) if (e.hurt && e.hp > 0 && !e.boss && !e.npc && e !== G.player && e.kind) { e.hurt(99999, G.player.pos, 0, 'melee'); n++; }
  sim(200); g.render(.016); want(info.memory.textures <= t0, `мурино: убито врагов ${n}, текстур ${t0} → ${info.memory.textures}`); }
return log.join('\n') + '\nОШИБКИ(' + errs.length + '):\n' + [...new Set(errs)].join('\n');
} catch (e) { return log.join('\n') + '\n!! ИСКЛЮЧЕНИЕ ' + (e.stack || e); }
