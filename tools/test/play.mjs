// usage: [MOBILE=1 DSF=2] node play.mjs <url> [WxH] cmd...   cmds: w:ms  s:file.png  d:Key u:Key k:Key  e:js  c:x,y  m:x,y  md:left|right mu:left|right  t:x,y (tap)  ts:x,y tm:x,y te: (touch start/move/end)
import puppeteer from 'puppeteer-core';
const [url, size, ...cmds] = process.argv.slice(2); const [w, h] = size.split('x').map(Number);
// браузер: свой Chrome/Chromium через CHROME_PATH, иначе @sparticuz/chromium (Linux x64, нужен AWS_LAMBDA_JS_RUNTIME=nodejs22.x)
let args = ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist', '--enable-webgl', '--allow-file-access-from-files', '--autoplay-policy=no-user-gesture-required'], exe = process.env.CHROME_PATH;
if (!exe) { const { default: chromium } = await import('@sparticuz/chromium'); chromium.setGraphicsMode = true; args = [...chromium.args, ...args]; exe = await chromium.executablePath(); } else args.push('--no-sandbox');
const b = await puppeteer.launch({ args, executablePath: exe, headless: 'shell', defaultViewport: process.env.MOBILE ? { width: w, height: h, isMobile: true, hasTouch: true, deviceScaleFactor: +(process.env.DSF || 1) } : { width: w, height: h } });
const p = await b.newPage(); const seen = new Map();
p.on('console', m => { const t = m.text(); if (t.includes('willReadFrequently')) return; const n = (seen.get(t) || 0) + 1; seen.set(t, n); if (n <= 2) console.log('[page]', t.slice(0, 700)); });
p.on('pageerror', e => console.log('[pageerror]', String(e.stack || e).slice(0, 900)));
await p.goto(url, { waitUntil: 'load', timeout: 60000 });
const sleep = ms => new Promise(r => setTimeout(r, ms));
for (const c of cmds) {
  const i = c.indexOf(':'), k = c.slice(0, i), v = c.slice(i + 1);
  try {
    if (k === 'w') await sleep(+v); else if (k === 's') await p.screenshot({ path: v }); else if (k === 'd') await p.keyboard.down(v); else if (k === 'u') await p.keyboard.up(v); else if (k === 'k') { await p.keyboard.press(v); }
    else if (k === 'e') { const r = await p.evaluate(v); if (r !== undefined) console.log('[eval]', JSON.stringify(r)); } else if (k === 'c') { const [x, y] = v.split(',').map(Number); await p.mouse.click(x, y); } else if (k === 'm') { const [x, y] = v.split(',').map(Number); await p.mouse.move(x, y); }
    else if (k === 'md') { await p.mouse.down({ button: v || 'left' }); } else if (k === 'mu') { await p.mouse.up({ button: v || 'left' }); }
    else if (k === 't') { const [x, y] = v.split(',').map(Number); await p.touchscreen.tap(x, y); } else if (k === 'ts') { const [x, y] = v.split(',').map(Number); await p.touchscreen.touchStart(x, y); } else if (k === 'tm') { const [x, y] = v.split(',').map(Number); await p.touchscreen.touchMove(x, y); } else if (k === 'te') { await p.touchscreen.touchEnd(); }
  } catch (e) { console.log('[cmderr]', c.slice(0, 60), String(e).slice(0, 300)); }
}
await b.close();
