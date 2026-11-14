// Упаковка игры в архив: docs/index.html -> docs/mellstroynost-3d.zip (игра одним файлом + памятка).
// node tools/pack.mjs   (без внешних программ: zip пишется вручную, сжатие — zlib)
import fs from 'node:fs';
import path from 'node:path';
import zlib from 'node:zlib';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const html = fs.readFileSync(path.join(root, 'docs/index.html'));
const readme = `МЕЛЛСТРОЙНОСТЬ 3D
Фанатская 3D-игра от третьего лица: Общага, Мурино, Молочное, Мытищи, Банька и ФОГ.

КАК ЗАПУСТИТЬ
  ПК: открой файл Mellstroynost-3D.html двойным щелчком (Chrome, Edge, Firefox, Safari).
      Интернет не нужен — вся игра в одном файле.
  Телефон: надёжнее всего открыть игру по ссылке (см. README в репозитории) и повернуть экран горизонтально.
      На Android файл можно открыть и локально через Chrome.

УПРАВЛЕНИЕ (ПК)
  WASD / стрелки — ходьба        Shift — бег           Пробел — прыжок
  Мышь — камера, колесо — зум    ЛКМ / J — удар        ПКМ / F — бросить котлету денег
  C / колёсико — перекат         E — действие          Q (держать) — дихлофос
  R — ульта «АМ-АМ-АМ»           1 — съесть еду        Tab / I — инвентарь     Esc / P — пауза

УПРАВЛЕНИЕ (ТЕЛЕФОН)
  Левая половина экрана — стик (тяни дальше, чтобы бежать), правая — камера, кнопки справа — действия.

Если тормозит — Настройки → Графика → «Сред» или «Низк».
Прогресс сохраняется в браузере на контрольных точках.

Некоммерческая фанатская пародия. Все совпадения — шутка.
`;

const table = new Uint32Array(256); for (let n = 0; n < 256; n++) { let c = n; for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1; table[n] = c >>> 0; }
const crc32 = b => { let c = 0xffffffff; for (let i = 0; i < b.length; i++) c = table[(c ^ b[i]) & 255] ^ (c >>> 8); return (c ^ 0xffffffff) >>> 0; };
const d = new Date(), time = (d.getHours() << 11) | (d.getMinutes() << 5) | (d.getSeconds() >> 1), date = ((d.getFullYear() - 1980) << 9) | ((d.getMonth() + 1) << 5) | d.getDate();
const files = [['Mellstroynost-3D.html', html], ['README.txt', Buffer.from('\ufeff' + readme.replace(/\n/g, '\r\n'), 'utf8')]];
const parts = [], central = []; let off = 0;
for (const [name, data] of files) {
  const nm = Buffer.from(name, 'utf8'), z = zlib.deflateRawSync(data, { level: 9 }), crc = crc32(data);
  const lh = Buffer.alloc(30); lh.writeUInt32LE(0x04034b50, 0); lh.writeUInt16LE(20, 4); lh.writeUInt16LE(0x0800, 6); lh.writeUInt16LE(8, 8); lh.writeUInt16LE(time, 10); lh.writeUInt16LE(date, 12);
  lh.writeUInt32LE(crc, 14); lh.writeUInt32LE(z.length, 18); lh.writeUInt32LE(data.length, 22); lh.writeUInt16LE(nm.length, 26); lh.writeUInt16LE(0, 28);
  const ch = Buffer.alloc(46); ch.writeUInt32LE(0x02014b50, 0); ch.writeUInt16LE(20, 4); ch.writeUInt16LE(20, 6); ch.writeUInt16LE(0x0800, 8); ch.writeUInt16LE(8, 10); ch.writeUInt16LE(time, 12); ch.writeUInt16LE(date, 14);
  ch.writeUInt32LE(crc, 16); ch.writeUInt32LE(z.length, 20); ch.writeUInt32LE(data.length, 24); ch.writeUInt16LE(nm.length, 28); ch.writeUInt32LE(off, 42);
  parts.push(lh, nm, z); central.push(ch, nm); off += 30 + nm.length + z.length;
}
const cd = Buffer.concat(central), end = Buffer.alloc(22); end.writeUInt32LE(0x06054b50, 0); end.writeUInt16LE(files.length, 8); end.writeUInt16LE(files.length, 10); end.writeUInt32LE(cd.length, 12); end.writeUInt32LE(off, 16);
const zip = Buffer.concat([...parts, cd, end]), outFile = path.join(root, 'docs/mellstroynost-3d.zip');
fs.writeFileSync(outFile, zip);
console.log(`[pack] docs/mellstroynost-3d.zip  ${(zip.length / 1024).toFixed(0)} KB  (игра ${(html.length / 1024).toFixed(0)} KB)`);
