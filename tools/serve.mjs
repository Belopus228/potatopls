// Простой статический сервер для docs/ (0.0.0.0, чтобы открыть с телефона в той же сети)
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { fileURLToPath } from 'node:url';

const dir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', 'docs');
const port = +(process.env.PORT || 8080);
const types = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript', '.css': 'text/css', '.jpg': 'image/jpeg', '.png': 'image/png', '.json': 'application/json', '.zip': 'application/zip' };
http.createServer((req, res) => {
  let p = decodeURIComponent(req.url.split('?')[0]); if (p.endsWith('/')) p += 'index.html';
  const f = path.join(dir, path.normalize(p).replace(/^(\.\.[\/\\])+/, ''));
  if (!f.startsWith(dir)) { res.writeHead(403); return res.end(); }
  fs.readFile(f, (e, data) => {
    if (e) { res.writeHead(404, { 'content-type': 'text/plain; charset=utf-8' }); return res.end('404'); }
    res.writeHead(200, { 'content-type': types[path.extname(f)] || 'application/octet-stream', 'cache-control': 'no-store' }); res.end(data);
  });
}).listen(port, '0.0.0.0', () => {
  console.log(`[serve] http://localhost:${port}/`);
  for (const a of Object.values(os.networkInterfaces()).flat()) if (a && a.family === 'IPv4' && !a.internal) console.log(`[serve] http://${a.address}:${port}/  (для телефона в той же Wi-Fi сети)`);
});
