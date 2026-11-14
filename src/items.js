// Предметы и инвентарь
import { G } from './g.js';

// t: food — еда, quest — сюжетное, gear — постоянное улучшение, junk — на продажу
export const ITEMS = {
  bread: { n: 'Хлеб', i: '🍞', t: 'food', heal: 15, d: '«Дай хотя бы хлеба». Восстанавливает 15 здоровья.', price: 8 },
  banana: { n: 'Банан', i: '🍌', t: 'food', heal: 22, d: '«Бананы есть?» — Есть. +22 здоровья.', price: 12 },
  doshik: { n: 'Доширак', i: '🍜', t: 'food', heal: 35, d: 'Заварил — и жизнь наладилась. +35 здоровья.', price: 20 },
  milk: { n: 'Молоко «Молочное»', i: '🥛', t: 'food', heal: 50, d: 'Парное, из того самого села. +50 здоровья.', price: 30 },
  shava: { n: 'Шаверма', i: '🌯', t: 'food', heal: 70, d: 'Муринская классика. +70 здоровья.', price: 45 },
  plums: { n: 'Сливы', i: '🍇', t: 'food', heal: 20, rage: 50, d: '«Сливы!» +20 здоровья и +50 ярости.', price: 35 },
  energy: { n: 'Энергетик «Бурмалда»', i: '🥫', t: 'food', buff: 30, d: 'Полминуты бегаешь и не устаёшь.', price: 25 },
  kvas: { n: 'Квас', i: '🍺', t: 'food', heal: 100, d: 'Холодный, из погреба Пра Дода. +100 здоровья.', price: 60 },
  // сюжетные
  note_dorm: { n: 'Записка коменданта', i: '📝', t: 'quest', d: '«Код от подвала — это цифры на стенах. Считай точки: одна точка — первая цифра…»' },
  key_dorm: { n: 'Ключ от вахты', i: '🗝️', t: 'quest', d: 'Открывает выход из общаги.' },
  parcel: { n: 'Посылка для П-46', i: '📦', t: 'quest', d: 'Курьеры ищут эту квартиру уже третий год.' },
  pass: { n: 'Пропуск в «пезд»', i: '🪪', t: 'quest', d: 'Пропуск в подъезд гигахрущёвки П-46.' },
  fuse: { n: 'Предохранитель', i: '🔌', t: 'quest', d: 'Для трансформаторной будки в Молочном.' },
  crank: { n: 'Ручка контроллера', i: '🔧', t: 'quest', d: 'Без неё трамвай «Гота» никуда не поедет.' },
  soap: { n: 'Пропуск «Чистые руки»', i: '🧼', t: 'quest', d: 'Выдаётся только тем, кто помылся.' },
  wood: { n: 'Дрова', i: '🪵', t: 'quest', d: 'Берёзовые. Для печки.' },
  venik: { n: 'Дубовый веник', i: '🌿', t: 'quest', d: 'Пра Дод без него в парилку не пускает.' },
  btn1: { n: 'Кнопка ливта «М»', i: '🔴', t: 'quest', d: 'Кнопка из Молочного. Липкая от паутины.' },
  btn2: { n: 'Кнопка ливта «Ы»', i: '🔵', t: 'quest', d: 'Кнопка из Мытищ. Идеально чистая.' },
  btn3: { n: 'Кнопка ливта «Б»', i: '🟡', t: 'quest', d: 'Кнопка из Баньки. Ещё тёплая.' },
  // улучшения
  spray: { n: 'Дихлофос', i: '🧴', t: 'gear', d: 'Зажми [Q] — облако дихлофоса. Жуки и пауки его ненавидят. Заряд копится сам.' },
  ult: { n: '«АМ-АМ-АМ»', i: '😱', t: 'gear', d: 'Бей врагов, копи ярость и жми [R]: три волны крика оглушают всех вокруг.' },
  kicks: { n: 'Кроссы Друна', i: '👟', t: 'gear', d: 'Двойной прыжок. Жми прыжок ещё раз в воздухе.' },
  chain: { n: 'Золотая цепь', i: '📿', t: 'gear', d: 'Каждая цепь: +25% к урону. Что за бизнес!' },
  hp: { n: 'Вкусность', i: '🧁', t: 'gear', d: 'Каждая вкусность: +20 к максимальному здоровью.' },
  phone: { n: 'Бурмалфон', i: '📱', t: 'gear', d: 'Показывает метку цели. Друн на связи.' },
};
export const inv = {
  count: id => (ITEMS[id].t === 'gear' ? G.save.gear[id] : G.save.inv[id]) || 0,
  has: (id, n = 1) => inv.count(id) >= n,
  add(id, n = 1, quiet) {
    const it = ITEMS[id], S = G.save; if (it.t === 'gear') S.gear[id] = (S.gear[id] || 0) + n; else S.inv[id] = (S.inv[id] || 0) + n;
    if (id === 'hp') G.player.hp = Math.min(G.player.maxHp, G.player.hp + 20 * n);
    if (!quiet) { G.ui.toast(`${it.i} ${it.n}${n > 1 ? ' ×' + n : ''}`, it.t === 'food' ? 'item' : 'big', it.t === 'food' ? '' : it.d); G.audio.sfx(it.t === 'food' ? 'pick' : 'item'); }
  },
  take(id, n = 1) { const S = G.save; if ((S.inv[id] || 0) < n) return false; S.inv[id] -= n; if (S.inv[id] <= 0) delete S.inv[id]; return true; },
  use(id) {
    const it = ITEMS[id], p = G.player; if (!it || it.t !== 'food' || !inv.has(id) || p.dead) return false;
    if (it.heal && !it.rage && !it.buff && p.hp >= p.maxHp) { G.ui.toast('Ч и так здоров', 'hint'); G.audio.sfx('deny'); return false; }
    inv.take(id); if (it.heal) p.heal(it.heal); if (it.rage) p.addRage(it.rage); if (it.buff) { p.buff = it.buff; p.stamina = 100; G.ui.toast('🥫 Бурмалда в крови!', 'hint'); } G.audio.sfx('eat'); return true;
  },
  // лучшая еда под текущую нехватку здоровья
  bestFood() { const p = G.player, need = p.maxHp - p.hp; let best = null, bs = 1e9; for (const id in G.save.inv) { const it = ITEMS[id]; if (!it || !it.heal) continue; const s = it.heal >= need ? it.heal - need : (need - it.heal) * 2 + 50; if (s < bs) { bs = s; best = id; } } return best; },
  foods() { return Object.keys(G.save.inv).filter(id => ITEMS[id] && ITEMS[id].t === 'food'); },
};
