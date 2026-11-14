// usage: node run.mjs <url> <WxH> file1.js [file2.js ...]  — склеивает файлы и выполняет в странице как тело async-функции
import fs from 'fs'; import puppeteer from 'puppeteer-core';
const [url, size, ...files] = process.argv.slice(2); const [w, h] = size.split('x').map(Number);
// браузер: свой Chrome/Chromium через CHROME_PATH, иначе @sparticuz/chromium (Linux x64, нужен AWS_LAMBDA_JS_RUNTIME=nodejs22.x)
let args = ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist', '--enable-webgl', '--allow-file-access-from-files', '--autoplay-policy=no-user-gesture-required'], exe = process.env.CHROME_PATH;
if (!exe) { const { default: chromium } = await import('@sparticuz/chromium'); chromium.setGraphicsMode = true; args = [...chromium.args, ...args]; exe = await chromium.executablePath(); } else args.push('--no-sandbox');
const b = await puppeteer.launch({ args, executablePath: exe, headless: 'shell', defaultViewport: { width: w, height: h }, protocolTimeout: 900000 });
const p = await b.newPage(); const seen = new Map();
p.on('console', m => { const t = m.text(); if (t.includes('willReadFrequently') || t.includes('GPU stall')) return; const n = (seen.get(t) || 0) + 1; seen.set(t, n); if (n <= 2) console.log('[page]', t.slice(0, 900)); });
p.on('pageerror', e => console.log('[pageerror]', String(e.stack || e).slice(0, 900)));
await p.goto(url, { waitUntil: 'load', timeout: 60000 });
await p.waitForFunction('window.G && window.sim && G.mode !== "boot"', { timeout: 120000 });
const src = files.map(f => fs.readFileSync(f, 'utf8')).join('\n;\n');
try { const r = await p.evaluate(`(async () => {\n${src}\n})()`); console.log(typeof r === 'string' ? r : JSON.stringify(r, null, 1)); } catch (e) { console.log('[evalerr]', String(e).slice(0, 1500)); }
const shot = process.env.SHOT; if (shot) { await new Promise(r => setTimeout(r, +(process.env.SHOTWAIT || 3000))); await p.screenshot({ path: shot }); }
await b.close();
