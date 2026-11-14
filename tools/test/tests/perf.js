// нагрузка на кадр по уровням: вызовы отрисовки, треугольники, текстуры, геометрии
await T.ready();
const g = G.gfx, info = g.renderer.info; info.autoReset = false;
const V = { menu: [[0, 0, 0, 0]], dorm: [[0, 0, 0, Math.PI / 2]], murino: [[-20, 0, 10, .5], [0, 0, 30, Math.PI]], milk: [[-20, 1.4, 0, Math.PI / 2], [300, 0, 317, Math.PI]], myt: [[0, 0, -8, 0]], banya: [[4, 1, -24, -.6]], final: [[0, 0, -20, 0]] };
for (const id of Object.keys(V)) {
  if (id !== 'menu') { G.game.startChapter(id); sim(150); T.flush(); }
  for (const [x, y, z, yaw] of V[id]) {
    if (id !== 'menu') { const gy = G.level.world.ground(x, z, y + 3); G.player.place(x, gy, z, yaw); G.cam.snap(); sim(12); }
    g.focus.copy(G.player.pos); for (let i = 0; i < 40; i++) g.updateLamps(.1);
    info.reset(); const t0 = performance.now(); g.render(.016); const ms = performance.now() - t0;
    let meshes = 0, lights = 0; g.scene.traverse(o => { if (o.isMesh || o.isPoints || o.isSprite) meshes++; if (o.isLight) lights++; });
    say(`${id} @${x},${z}: вызовов ${info.render.calls}, треугольников ${(info.render.triangles / 1000).toFixed(0)}k, точек ${info.render.points}, объектов в сцене ${meshes}, сущностей ${G.ents.length}, геометрий ${info.memory.geometries}, текстур ${info.memory.textures}, программ ${info.programs.length}, кадр (SwiftShader) ${ms.toFixed(0)} мс`);
  }
}
return log.join('\n') + '\nОШИБКИ(' + errs.length + '): ' + errs.slice(0, 3).join(' | ');
