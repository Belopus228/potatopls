// Прогон автотестов: node tools/test/all.mjs [full walk walk2 bosses misc audio pad qual leak]
// Игра открывается из docs/index.html в headless-Chromium (WebGL через SwiftShader) и проходится скриптом.
import { spawnSync } from 'child_process'; import path from 'path'; import { fileURLToPath, pathToFileURL } from 'url';
const dir = path.dirname(fileURLToPath(import.meta.url)), root = path.resolve(dir, '../..');
const names = process.argv.slice(2).length ? process.argv.slice(2) : ['full', 'walk', 'walk2', 'bosses', 'misc', 'audio', 'pad', 'qual', 'leak'];
const url = pathToFileURL(path.join(root, 'docs/index.html')).href + '?nodyn&q=0'; let bad = 0;
for (const n of names) {
  const t0 = Date.now(), r = spawnSync(process.execPath, [path.join(dir, 'run.mjs'), url, '320x180', path.join(dir, 'tests/common.js'), path.join(dir, `tests/${n}.js`)], { encoding: 'utf8', timeout: 900000, env: { ...process.env, AWS_LAMBDA_JS_RUNTIME: process.env.AWS_LAMBDA_JS_RUNTIME || 'nodejs22.x' } });
  const out = (r.stdout || '') + (r.stderr || ''), fails = out.split('\n').filter(l => /!! ПРОВАЛ|!! ИСКЛЮЧЕНИЕ|\[pageerror\]|\[evalerr\]|flush timeout, mode=(?!end)/.test(l)), m = /ОШИБКИ\((\d+)\)/.exec(out), errs = m ? +m[1] : -1;
  const ok = r.status === 0 && !fails.length && errs === 0; if (!ok) bad++;
  if (process.env.VERBOSE || !ok) console.log(out);
  console.log(`${ok ? 'OK  ' : 'FAIL'} ${n.padEnd(7)} ${((Date.now() - t0) / 1000).toFixed(0)}с  проверок ok: ${(out.match(/^ok:/gm) || []).length}, провалов: ${fails.length}, ошибок консоли: ${errs < 0 ? '?' : errs}`);
}
console.log(bad ? `\nПровалено наборов: ${bad}` : '\nВсе наборы прошли'); process.exit(bad ? 1 : 0);
