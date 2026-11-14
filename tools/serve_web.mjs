// Статический сервер для браузерной сборки v2 (экспорт Godot «Web»).
//   node tools/serve_web.mjs [папка] [порт]      по умолчанию: out/web, порт 8060
// Слушает 0.0.0.0, чтобы игру можно было открыть с телефона в той же сети.
// Отдаёт .wasm с правильным типом и сжимает крупные файлы (wasm 36 МБ → около 9 МБ по сети).
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import zlib from 'node:zlib';

const dir = path.resolve(process.argv[2] || 'out/web');
const port = +(process.argv[3] || process.env.PORT || 8060);
const MIME = {
  '.html': 'text/html; charset=utf-8', '.js': 'text/javascript', '.wasm': 'application/wasm', '.pck': 'application/octet-stream',
  '.png': 'image/png', '.jpg': 'image/jpeg', '.svg': 'image/svg+xml', '.ico': 'image/x-icon', '.json': 'application/json',
};
const SQUEEZE = new Set(['.wasm', '.js', '.html', '.pck']);
const cache = new Map(); // путь → { mtime, gz }

function gz(file, st) {
  const hit = cache.get(file);
  if (hit && hit.mtime === st.mtimeMs) return hit.gz;
  const buf = zlib.gzipSync(fs.readFileSync(file), { level: 6 });
  cache.set(file, { mtime: st.mtimeMs, gz: buf });
  return buf;
}

if (!fs.existsSync(path.join(dir, 'index.html'))) {
  console.error(`[web] в папке ${dir} нет index.html. Распакуй сюда Mellstroynost-3D-web.zip из релиза или сделай экспорт «Web» из Godot.`);
  process.exit(1);
}

http.createServer((req, res) => {
  let p;
  try { p = decodeURIComponent(req.url.split('?')[0]); } catch { res.writeHead(400); return res.end(); }
  if (p.endsWith('/')) p += 'index.html';
  const file = path.join(dir, path.normalize(p));
  if (!file.startsWith(dir)) { res.writeHead(403); return res.end(); }
  fs.stat(file, (err, st) => {
    if (err || !st.isFile()) { res.writeHead(404, { 'content-type': 'text/plain; charset=utf-8' }); return res.end('404'); }
    const ext = path.extname(file);
    const head = { 'content-type': MIME[ext] || 'application/octet-stream', 'cache-control': 'no-cache' };
    if (SQUEEZE.has(ext) && /\bgzip\b/.test(req.headers['accept-encoding'] || '')) {
      const body = gz(file, st);
      res.writeHead(200, { ...head, 'content-encoding': 'gzip', 'content-length': body.length, vary: 'accept-encoding' });
      return res.end(req.method === 'HEAD' ? undefined : body);
    }
    res.writeHead(200, { ...head, 'content-length': st.size });
    if (req.method === 'HEAD') return res.end();
    fs.createReadStream(file).pipe(res);
  });
}).listen(port, '0.0.0.0', () => {
  console.log(`[web] ${dir}`);
  console.log(`[web] http://localhost:${port}/`);
  for (const a of Object.values(os.networkInterfaces()).flat()) {
    if (a && a.family === 'IPv4' && !a.internal) console.log(`[web] http://${a.address}:${port}/  (с телефона в той же сети Wi-Fi)`);
  }
});
