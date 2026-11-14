// Сборка: весь проект в ОДИН файл docs/index.html (JS + CSS + картинки внутри).
// node tools/build.mjs            — релизная сборка
// node tools/build.mjs --watch --serve — разработка (пересборка + сервер)
import * as esbuild from 'esbuild';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const out = path.join(root, 'docs');
const argv = process.argv.slice(2), watch = argv.includes('--watch'), serve = argv.includes('--serve');
const entry = (argv.find(a => a.startsWith('--entry=')) || '--entry=src/main.js').slice(8);
const outName = (argv.find(a => a.startsWith('--out=')) || '--out=index.html').slice(6);

const inline = {
  name: 'inline-html',
  setup(b) {
    b.onEnd(res => {
      if (res.errors.length || !res.outputFiles) return;
      let js = res.outputFiles[0].text.replace(/<\/script/gi, '<\\/script');
      if (js.includes('<!--')) js = js.replace(/<!--/g, '<\\!--');
      const html = fs.readFileSync(path.join(root, 'src/index.html'), 'utf8'), css = fs.readFileSync(path.join(root, 'src/style.css'), 'utf8');
      const page = html.replace('/*CSS*/', () => css).replace('/*JS*/', () => js).replace('__BUILD__', () => new Date().toISOString().slice(0, 16).replace('T', ' '));
      fs.mkdirSync(out, { recursive: true }); fs.writeFileSync(path.join(out, outName), page); fs.writeFileSync(path.join(out, '.nojekyll'), '');
      console.log(`[build] docs/${outName}  ${(page.length / 1024).toFixed(0)} KB  ${new Date().toLocaleTimeString()}`);
    });
  },
};
const opts = {
  entryPoints: [path.join(root, entry)], bundle: true, format: 'iife', write: false, minify: !watch, charset: 'utf8', target: ['es2020'],
  loader: { '.jpg': 'dataurl', '.png': 'dataurl' }, plugins: [inline], logLevel: 'warning', legalComments: 'none',
  alias: { 'three/addons': path.join(root, 'node_modules/three/examples/jsm') },
};
if (watch) { const ctx = await esbuild.context(opts); await ctx.watch(); console.log('[build] watching…'); if (serve) await import('./serve.mjs'); }
else await esbuild.build(opts);
