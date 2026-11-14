// Интерфейс: HUD, диалоги, меню, инвентарь, магазин, кодовый замок, панель ливта
import * as THREE from 'three';
import { G, clamp, wait, until } from './g.js';
import { FACE } from './faces.js';
import { ITEMS, inv } from './items.js';
import { QUAL } from './gfx.js';

export const WHO = {
  ch: { n: 'Ч', f: FACE.ch }, drun: { n: 'Друн', f: FACE.drun, p: 1.15 }, bral: { n: 'Брал', f: FACE.bral, p: .9 }, dod: { n: 'Дод', f: FACE.dod, p: .75 }, dark: { n: 'Тёмный Друн', f: FACE.dark, c: '#b38cff', p: .6 }, pale: { n: '???', f: FACE.pale, p: .7 },
  fog: { n: 'ФОГ', e: '🌫️', c: '#e6ebf2', p: .4 }, phone: { n: 'Бурмалфон', e: '📱', c: '#8fe3ff', p: 1.5 }, sys: { n: '', e: '💬' },
};
const $ = (s, r = document) => r.querySelector(s);
const KEYS = [['WASD / стрелки', 'ходьба'], ['Мышь', 'камера (колесо — зум)'], ['Shift', 'бег'], ['Пробел', 'прыжок'], ['ЛКМ / J', 'удар (серия из трёх)'], ['ПКМ / F', 'бросить котлету денег'], ['C / колёсико', 'перекат (неуязвимость)'], ['E', 'действие, разговор'], ['Q (держать)', 'дихлофос'], ['R', '«АМ-АМ-АМ» (когда ярость полная)'], ['1', 'съесть еду'], ['Tab / I', 'инвентарь'], ['Esc / P', 'пауза']];
const v3 = new THREE.Vector3();

export class UI {
  constructor() {
    const ui = this.root = $('#ui');
    ui.innerHTML = `<div id="hud" class="off"><div id="bars"><div id="ava"></div><div><div class="bar" id="hp"><em></em><i></i><b></b></div><div class="bar" id="st"><i></i></div><div class="bar" id="rg"><i></i></div><div class="bar" id="ch"><i></i></div></div></div>
      <div id="money"></div><div id="quest" class="hide"></div><div id="prompt"><kbd>E</kbd><span></span></div><div id="marker"><i></i><span></span></div>
      <div id="boss"><div class="bn"></div><div class="bbar"><em></em><i></i></div></div><div id="hints"></div></div>
      <div id="lowhp"></div><div id="flash"></div><div id="toasts"></div><div id="title"><span></span><b></b></div><div id="lb1"></div><div id="lb2"></div>
      <div id="dlg"><div class="dbox"><div class="dface"></div><div class="dname"></div><div class="dtext"></div><div class="dch"></div><div class="dnext">▶ дальше</div></div></div>
      <div id="fade"></div><div id="screen"></div><div id="rot">↻<br>Поверни телефон горизонтально</div>`;
    for (const id of ['hud', 'hp', 'st', 'rg', 'ch', 'money', 'quest', 'prompt', 'marker', 'boss', 'hints', 'lowhp', 'flash', 'toasts', 'title', 'dlg', 'fade', 'screen', 'ava']) this[id] = $('#' + id);
    this.ava.style.backgroundImage = `url(${FACE.ch})`; this.scr = this.screen; this.c = {}; this.adv = false; this.handler = null; this.bossA = null; this.fadeV = 0;
    this.hints.innerHTML = '<kbd>WASD</kbd> ходьба · <kbd>Shift</kbd> бег · <kbd>Пробел</kbd> прыжок · <kbd>ЛКМ</kbd> удар · <kbd>ПКМ</kbd> бросок · <kbd>C</kbd> перекат · <kbd>E</kbd> действие · <kbd>Tab</kbd> инвентарь';
    this.scr.addEventListener('click', e => { const b = e.target.closest('[data-a]'); if (b && this.handler) { G.audio.unlock(); G.audio.sfx('ui'); this.handler(b.dataset.a, b.dataset.v, b); } });
    this.scr.addEventListener('input', e => { const b = e.target.closest('[data-i]'); if (b && this.handler) this.handler(b.dataset.i, +b.value, b); });
    this.dlg.addEventListener('pointerdown', e => { const b = e.target.closest('[data-c]'); if (b) this.pickV = +b.dataset.c; else this.adv = true; G.audio.unlock(); });
  }
  set(k, v) { if (this.c[k] === v) return false; this.c[k] = v; return true; }
  click() { if (G.mode === 'dialog' || G.mode === 'cut') this.adv = true; }
  key(e) {
    const c = e.code; if (this.keyH && this.keyH(c, e)) return;
    if (G.mode === 'dialog' && this.nCh && /^Digit[1-9]$/.test(c)) { const n = +c.slice(5) - 1; if (n < this.nCh) this.pickV = n; }
    if (this.scr.classList.contains('on') && (c === 'Escape' || ((c === 'Tab' || c === 'KeyI') && this.cur === 'inv'))) { e.preventDefault(); if (this.handler) this.handler('back'); G.input.pressed = {}; }
  }
  // ---------- HUD ----------
  update(dt) {
    const p = G.player, S = G.save, m = G.mode; if (!p || !S) return; const b = document.body;
    if (this.set('hud', m === 'play' || m === 'dialog' || m === 'pause')) this.hud.classList.toggle('off', !this.c.hud);
    if (this.set('pl', m === 'play')) b.classList.toggle('playing', m === 'play'); if (this.set('cine', m === 'cut')) b.classList.toggle('cine', m === 'cut');
    const hw = Math.round(clamp(p.hp / p.maxHp, 0, 1) * 1000) / 10; if (this.set('hp', hw + '|' + p.maxHp)) { this.hp.children[0].style.width = this.hp.children[1].style.width = hw + '%'; this.hp.children[2].textContent = Math.ceil(p.hp) + ' / ' + p.maxHp; this.hp.style.width = Math.min(340, 190 + p.maxHp * .4) + 'px'; }
    if (this.set('st', Math.round(p.stamina))) { this.st.firstChild.style.width = p.stamina + '%'; this.st.firstChild.style.filter = p.exh ? 'grayscale(1)' : p.buff > 0 ? 'hue-rotate(160deg)' : ''; }
    if (this.set('gu', !!S.gear.ult)) this.rg.style.display = S.gear.ult ? '' : 'none'; if (this.set('gs', !!S.gear.spray)) this.ch.style.display = S.gear.spray ? '' : 'none';
    if (this.set('rg', Math.round(p.rage))) { this.rg.firstChild.style.width = p.rage + '%'; this.rg.classList.toggle('full', p.rage >= 100); } if (this.set('ch', Math.round(p.charge))) this.ch.firstChild.style.width = p.charge + '%';
    if (this.set('mo', S.money)) { this.money.textContent = '₽ ' + S.money; this.money.classList.remove('bump'); void this.money.offsetWidth; this.money.classList.add('bump'); }
    const near = m === 'play' && p.near ? p.near.label : ''; if (this.set('near', near)) { this.prompt.classList.toggle('on', !!near); this.prompt.lastChild.textContent = near; const tb = $('#tb-int'); tb.classList.toggle('show', !!near); tb.textContent = near; }
    if (this.set('low', p.hp < p.maxHp * .26 && !p.dead && m !== 'menu')) this.lowhp.classList.toggle('on', this.c.low);
    if (G.touch) { if (this.set('tg', !!S.gear.spray)) $('#tb-gadget').classList.toggle('hide', !S.gear.spray); if (this.set('tu', (S.gear.ult ? 1 : 0) + (p.rage >= 100 ? 1 : 0))) { const u = $('#tb-ult'); u.classList.toggle('hide', !S.gear.ult); u.classList.toggle('ready', p.rage >= 100); } const f = inv.bestFood(), n = inv.foods().reduce((a, id) => a + S.inv[id], 0); if (this.set('tf', f + n)) { const t = $('#tb-item'); t.classList.toggle('hide', !f); t.innerHTML = f ? ITEMS[f].i + `<b>${n}</b>` : ''; } }
    // метка цели
    const mk = G.game.mark, mel = this.marker; let show = false;
    if (mk && m === 'play') {
      const cam = G.gfx.camera, d = mk.distanceTo(p.pos); if (d > 3) {
        v3.copy(mk).project(cam); let x = v3.x, y = v3.y; const behind = v3.z > 1; if (behind) { x = -x; y = -y; } let edge = behind || Math.abs(x) > .93 || Math.abs(y) > .86;
        if (edge) { const k = 1 / Math.max(Math.abs(x) / .93, Math.abs(y) / .86, .0001); if (behind || k < 1) { x *= k; y *= k; } x = clamp(x, -.93, .93); y = clamp(y, -.86, .86); }
        mel.style.transform = `translate(${((x * .5 + .5) * innerWidth) | 0}px,${((-y * .5 + .5) * innerHeight) | 0}px)`; if (this.set('md', Math.round(d))) mel.lastChild.textContent = Math.round(d) + ' м'; if (this.set('me', edge)) mel.classList.toggle('edge', edge); show = true;
      }
    }
    if (this.set('ms', show)) mel.style.display = show ? 'block' : 'none';
    const B = this.bossA; if (B) { const w = Math.round(clamp(B.hp / B.maxHp, 0, 1) * 1000) / 10; if (this.set('bw', w)) this.boss.querySelector('i').style.width = this.boss.querySelector('em').style.width = w + '%'; if (B.gone || (B.dead && (this.bt = (this.bt || 0) + dt) > 1.5)) this.bossBar(null); }
  }
  objective(t) { if (!this.set('q', t)) return; this.quest.innerHTML = t ? '<b>ЦЕЛЬ</b>' + t : ''; this.quest.classList.toggle('hide', !t); this.quest.classList.remove('new'); void this.quest.offsetWidth; if (t) { this.quest.classList.add('new'); if (G.mode !== 'menu') G.audio.sfx('quest'); } }
  toast(t, cls = '', sub = '') { const e = document.createElement('div'); e.className = 'toast ' + cls; e.innerHTML = t + (sub ? `<small>${sub}</small>` : ''); this.toasts.appendChild(e); while (this.toasts.children.length > 4) this.toasts.firstChild.remove(); setTimeout(() => e.classList.add('out'), cls === 'big' ? 4200 : 2500); setTimeout(() => e.remove(), cls === 'big' ? 4700 : 3000); }
  bigTitle(big, small = '', t = 3400) { this.title.firstChild.textContent = small; this.title.lastChild.textContent = big; this.title.classList.add('on'); clearTimeout(this.tt); this.tt = setTimeout(() => this.title.classList.remove('on'), t); }
  hurt() { this.flash.classList.add('on'); void this.flash.offsetWidth; this.flash.classList.remove('on'); }
  bossBar(a, name) { this.bossA = a; this.bt = 0; this.c.bw = -1; this.boss.classList.toggle('on', !!a); if (a) this.boss.firstChild.textContent = name || a.name; }
  *fadeTo(v, t = .4) { const a = this.fadeV; let k = 0; while (k < 1) { k = Math.min(1, k + Math.min(G.dt, .034) / t); this.fadeV = a + (v - a) * k; this.fade.style.opacity = this.fadeV; yield; } }
  setFade(v) { this.fadeV = v; this.fade.style.opacity = v; }
  // ---------- диалоги ----------
  *say(who, text) {
    const W = typeof who === 'string' ? (WHO[who] || { n: who }) : who, d = this.dlg, face = $('.dface', d), tx = $('.dtext', d), nx = $('.dnext', d); d.classList.add('on');
    $('.dname', d).textContent = W.n || ''; $('.dname', d).style.color = W.c || ''; face.style.backgroundImage = W.f ? `url(${W.f})` : ''; face.textContent = W.f ? '' : (W.e || (W.n || '?')[0]); face.style.borderColor = W.c || ''; $('.dch', d).innerHTML = ''; this.nCh = 0;
    let n = 0, acc = 0; this.adv = false; tx.textContent = '';
    for (; ;) {
      if (n < text.length) { acc += G.dt * 60; const k = Math.min(text.length, acc | 0); if (k !== n) { if ((k >> 1) !== (n >> 1) && text[k - 1] !== ' ') G.audio.sfx('talk', W.p || 1); n = k; tx.textContent = text.slice(0, n); } }
      if (this.adv || G.input.hit('interact') || G.input.hit('jump')) { this.adv = false; if (n < text.length) { n = text.length; acc = 1e9; tx.textContent = text; } else break; }
      nx.style.visibility = n >= text.length ? 'visible' : 'hidden'; yield;
    }
    G.audio.sfx('ui');
  }
  // выбор ответа (после say — текст остаётся на экране)
  *choose(opts) {
    const d = this.dlg, c = $('.dch', d); c.innerHTML = opts.map((o, i) => `<button data-c="${i}"><kbd>${i + 1}</kbd>${o}</button>`).join(''); $('.dnext', d).style.visibility = 'hidden'; this.nCh = opts.length; this.pickV = -1; G.input.unlock();
    while (this.pickV < 0) yield; const r = this.pickV; this.nCh = 0; c.innerHTML = ''; this.adv = false; G.audio.sfx('ui2'); return r;
  }
  endDlg() { this.dlg.classList.remove('on'); }
  // ---------- экраны ----------
  open(name, html, cls = '') { this.cur = name; this.scr.innerHTML = html; this.scr.className = 'on ' + cls; this.keyH = null; G.input.unlock(); G.input.keys = {}; }
  close() { this.cur = null; this.scr.className = ''; this.scr.innerHTML = ''; this.handler = null; this.keyH = null; }
  goFull() { if (!G.touch) return; try { const el = document.documentElement, r = el.requestFullscreen || el.webkitRequestFullscreen; if (r && !document.fullscreenElement) { const p = r.call(el); if (p && p.then) p.then(() => screen.orientation && screen.orientation.lock && screen.orientation.lock('landscape').catch(() => { })).catch(() => { }); } } catch (e) { } }
  menu() {
    G.mode = 'menu'; const has = G.game.hasSave(), ch = G.game.unlocked();
    this.open('menu', `<div class="menu"><div class="logo">МЕЛЛ<b>СТРОЙНОСТЬ</b> 3D<small>ФАНАТСКАЯ ПАРОДИЯ · МУРИНО · МОЛОЧНОЕ · МЫТИЩИ · БАНЬКА</small></div>
      ${has ? '<button class="btn pri" data-a="cont">▶ ПРОДОЛЖИТЬ</button>' : ''}<button class="btn ${has ? '' : 'pri'}" data-a="new">НОВАЯ ИГРА</button>
      ${ch.length > 1 ? '<button class="btn" data-a="chap">ГЛАВЫ</button>' : ''}<button class="btn" data-a="set">НАСТРОЙКИ</button><button class="btn" data-a="help">УПРАВЛЕНИЕ</button></div>`, 'clear');
    this.handler = a => {
      if (a === 'cont') { this.goFull(); G.game.continue(); } else if (a === 'new') { if (has) this.confirm('Начать заново?', 'Текущее сохранение будет стёрто.', () => { this.goFull(); G.game.newGame(); }, () => this.menu()); else { this.goFull(); G.game.newGame(); } }
      else if (a === 'set') this.settings(() => this.menu()); else if (a === 'help') this.help(() => this.menu());
      else if (a === 'chap') { this.open('chap', `<div class="panel"><h2>ГЛАВЫ</h2>${ch.map(c => `<button class="btn" style="margin:4px 0;width:100%" data-a="go" data-v="${c.id}">${c.title}</button>`).join('')}<div class="row"><button class="btn sm" data-a="back">← Назад</button></div></div>`); this.handler = (a, v) => { if (a === 'go') { this.goFull(); G.game.startChapter(v); } else this.menu(); }; }
    };
  }
  confirm(title, text, yes, no) { this.open('confirm', `<div class="panel center"><h2>${title}</h2><p>${text}</p><div class="row" style="justify-content:center"><button class="btn sm pri" data-a="y">Да</button><button class="btn sm" data-a="back">Нет</button></div></div>`); this.handler = a => a === 'y' ? yes() : no(); }
  help(back) {
    const keys = `<div class="keys">${KEYS.map(k => `<kbd>${k[0]}</kbd><span>${k[1]}</span>`).join('')}</div>`;
    const phone = `<p><b>Телефон:</b> левая половина экрана — стик (тяни дальше, чтобы бежать), правая — камера. Кнопки справа: 👊 удар, ⤒ прыжок, 💨 перекат, 💸 бросок, 🧴 дихлофос, 😱 ульта, внизу по центру — еда. Геймпад тоже работает.</p>`;
    this.open('help', `<div class="panel"><h2>УПРАВЛЕНИЕ</h2>${G.touch ? phone + keys : keys + phone}
      <div class="row"><button class="btn sm pri" data-a="back">Понятно</button></div></div>`); this.handler = () => back();
  }
  settings(back) {
    const S = G.settings, seg = (k, opts) => `<div class="seg">${opts.map((o, i) => `<button data-a="${k}" data-v="${i}" class="${(+S[k] === i || S[k] === !!i && typeof S[k] === 'boolean') ? 'on' : ''}">${o}</button>`).join('')}</div>`, rng = (k, min, max, step) => `<input type="range" data-i="${k}" min="${min}" max="${max}" step="${step}" value="${S[k]}">`;
    this.open('set', `<div class="panel"><h2>НАСТРОЙКИ</h2>
      <div class="opt"><span>Графика<small>${QUAL[S.q].name}: тени, блум, частицы</small></span>${seg('q', ['Низк', 'Сред', 'Выс', 'Ультра'])}</div>
      <div class="opt"><span>Авто-разрешение<small>снижает чёткость, если мало FPS</small></span>${seg('dyn', ['Выкл', 'Вкл'])}</div>
      <div class="opt"><span>Громкость эффектов</span>${rng('vol', 0, 1, .05)}</div><div class="opt"><span>Громкость музыки</span>${rng('music', 0, 1, .05)}</div>
      <div class="opt"><span>Чувствительность камеры</span>${rng('sens', .3, 2.5, .05)}</div>
      <div class="opt"><span>Инверсия по вертикали</span>${seg('invY', ['Выкл', 'Вкл'])}</div><div class="opt"><span>Камера сама встаёт за спину</span>${seg('autoCam', ['Выкл', 'Вкл'])}</div>
      <div class="opt"><span>Тряска камеры</span>${seg('shake', ['Выкл', 'Вкл'])}</div><div class="opt"><span>Сложность<small>на лёгкой враги бьют вдвое слабее</small></span>${seg('easy', ['Обычная', 'Лёгкая'])}</div>
      <div class="row"><button class="btn sm pri" data-a="back">Готово</button></div></div>`);
    this.handler = (a, v) => { if (a === 'back') { G.game.saveSettings(); return back(); } if (a === 'q') { S.q = +v; G.gfx.scale = 1; G.gfx.setQuality(S.q); G.fx.weather(G.fx.wk); } else if (['vol', 'music', 'sens'].includes(a)) { S[a] = +v; G.audio.setVol(S.vol, S.music); if (a === 'vol') G.audio.sfx('coin'); return; } else S[a] = !!+v; this.settings(back); };
  }
  pause() {
    if (G.mode !== 'play') return; this.prev = 'play'; G.mode = 'pause';
    this.open('pause', `<div class="panel center"><h2>ПАУЗА</h2><div style="display:flex;flex-direction:column;gap:8px;align-items:center"><button class="btn pri" data-a="back">ПРОДОЛЖИТЬ</button><button class="btn" data-a="inv">ИНВЕНТАРЬ</button><button class="btn" data-a="set">НАСТРОЙКИ</button><button class="btn" data-a="help">УПРАВЛЕНИЕ</button><button class="btn" data-a="cp">С КОНТРОЛЬНОЙ ТОЧКИ</button><button class="btn" data-a="menu">В ГЛАВНОЕ МЕНЮ</button></div></div>`);
    this.handler = a => { if (a === 'back') this.resume(); else if (a === 'inv') { G.mode = 'play'; this.inventory(); } else if (a === 'set') this.settings(() => { G.mode = 'play'; this.pause(); }); else if (a === 'help') this.help(() => { G.mode = 'play'; this.pause(); }); else if (a === 'cp') { this.close(); G.game.respawn(); } else if (a === 'menu') { this.close(); G.game.toMenu(); } };
  }
  resume() { this.close(); G.mode = 'play'; G.input.pressed = {}; if (!G.touch) G.input.lock(); }
  inventory() {
    if (G.mode !== 'play') return; G.mode = 'pause'; const S = G.save, p = G.player;
    const draw = () => {
      const ids = Object.keys(S.inv).filter(i => ITEMS[i]), gear = Object.keys(S.gear).filter(i => ITEMS[i] && S.gear[i]); if (!this.sel || !(S.inv[this.sel] || S.gear[this.sel])) this.sel = ids[0] || gear[0]; const it = ITEMS[this.sel];
      const cell = (id, n, g) => `<div class="cell ${g ? 'gear' : ''} ${id === this.sel ? 'sel' : ''}" data-a="sel" data-v="${id}">${ITEMS[id].i}${n > 1 ? `<b>${n}</b>` : ''}</div>`;
      this.open('inv', `<div class="panel"><h2>ИНВЕНТАРЬ</h2><div>❤ ${Math.ceil(p.hp)} / ${p.maxHp} &nbsp; ₽ ${S.money} &nbsp; 👊 урон ×${p.dmgMul.toFixed(2)}</div>
        <div class="tabs">Вещи</div><div class="grid">${ids.map(i => cell(i, S.inv[i])).join('') || '<span style="opacity:.5;grid-column:1/-1">Пусто. Ломай ящики — там бывает еда.</span>'}</div>
        <div class="tabs">Улучшения</div><div class="grid">${gear.map(i => cell(i, S.gear[i], 1)).join('') || '<span style="opacity:.5;grid-column:1/-1">Пока ничего</span>'}</div>
        <div class="det">${it ? `<b>${it.i} ${it.n}</b><p>${it.d}</p>` : 'Выбери предмет'}</div>
        <div class="row">${it && it.t === 'food' && S.inv[this.sel] ? '<button class="btn sm pri" data-a="use">Съесть</button>' : ''}<button class="btn sm" data-a="back">Закрыть</button></div></div>`);
      this.handler = (a, v) => { if (a === 'sel') { this.sel = v; draw(); } else if (a === 'use') { inv.use(this.sel); draw(); } else this.resume(); };
    }; draw();
  }
  death() {
    const ph = ['ПЛАКИ-ПЛАКИ', 'ЭТО ЖМУРИНО', 'ПОТРАЧЕНО', 'НЕ ВКУСНОСТЬ'][Math.random() * 4 | 0];
    this.open('dead', `<div class="center dead" style="text-align:center"><h1>${ph}</h1><p>Ч упал. Но Ч встанет.</p><div class="row" style="justify-content:center"><button class="btn sm pri" data-a="re">ЕЩЁ РАЗ</button><button class="btn sm" data-a="menu">В МЕНЮ</button></div></div>`);
    this.handler = a => { this.close(); if (a === 'menu') G.game.toMenu(); else G.game.respawn(); };
  }
  ending(st) {
    this.open('end', `<div class="panel cred"><h1>КОНЕЦ</h1><p>«Последний ливт в Мурино ушёл на первый этаж 32 августа в 00:00».<br>Ч помылся. Ч поехал.</p>
      <p>Время: <b>${st.time}</b> · Врагов побеждено: <b>${st.kills}</b> · Падений: <b>${st.deaths}</b> · Собрано: <b>₽ ${st.money}</b></p>
      <p style="opacity:.6;font-size:13px">«Меллстройность 3D» — некоммерческая фанатская пародия по мотивам мемов про Мурино, село Молочное, Мытищи и Баньку. Все совпадения — шутка. Музыка, звуки и графика сгенерированы кодом.</p>
      <div class="row" style="justify-content:center"><button class="btn sm pri" data-a="menu">В МЕНЮ</button></div></div>`);
    this.handler = () => { this.close(); G.game.toMenu(); };
  }
  // ---------- мини-экраны для скриптов (генераторы) ----------
  *shop(title, goods, line) {
    let done = false; const S = G.save;
    const draw = () => {
      this.open('shop', `<div class="panel"><h2>${title}</h2><div>${line || ''} &nbsp; <b style="color:#a6ff9a">₽ ${S.money}</b></div>${goods.map((g, i) => { const it = ITEMS[g.id], own = inv.count(g.id), sold = g.max && own >= g.max; return `<div class="shop"><i>${it.i}</i><span>${it.n}${own ? ` <b>×${own}</b>` : ''}<small>${it.d}</small></span><button class="btn sm ${S.money >= g.price && !sold ? 'pri' : ''}" data-a="buy" data-v="${i}" ${sold ? 'disabled' : ''}>${sold ? 'куплено' : g.price + ' ₽'}</button></div>`; }).join('')}
        <div class="row"><button class="btn sm" data-a="back">Уйти</button></div></div>`);
      this.handler = (a, v) => { if (a === 'buy') { const g = goods[v]; if (S.money < g.price) { G.audio.sfx('deny'); this.toast('Не хватает бабок', 'hint'); return; } S.money -= g.price; inv.add(g.id, 1, true); G.audio.sfx('coin'); draw(); } else done = true; };
    }; draw(); while (!done) yield; this.close();
  }
  *keypad(title, len, hint = '') {
    let code = '', res; const draw = () => {
      this.open('pad', `<div class="panel center" style="width:min(340px,94vw)"><h2>${title}</h2><div class="code">${code.padEnd(len, '·')}</div><div class="pad">${[1, 2, 3, 4, 5, 6, 7, 8, 9].map(n => `<button data-a="d" data-v="${n}">${n}</button>`).join('')}<button data-a="c">⌫</button><button data-a="d" data-v="0">0</button><button data-a="back">✕</button></div><p style="font-size:13px">${hint}</p></div>`);
      this.handler = (a, v) => { if (a === 'd' && code.length < len) { code += v; if (code.length === len) res = code; } else if (a === 'c') code = code.slice(0, -1); else if (a === 'back') res = null; if (res === undefined) draw(); };
      this.keyH = c => { const m = /^(?:Digit|Numpad)(\d)$/.exec(c); if (m) { this.handler('d', m[1]); return true; } if (c === 'Backspace') { this.handler('c'); return true; } };
    }; draw(); while (res === undefined) yield; this.close(); return res;
  }
  // «ливт помнит маршрут»: повтори последовательность этажей
  *simon(title, rounds = [3, 4, 5]) {
    this.open('simon', `<div class="panel center" style="width:min(340px,94vw)"><h2>${title}</h2><div class="code" id="sm-t">СМОТРИ</div><div class="pad">${[7, 8, 9, 4, 5, 6, 1, 2, 3].map(n => `<button data-a="d" data-v="${n}" id="sm${n}">${n}</button>`).join('')}</div><p style="font-size:13px">Ливт покажет этажи. Повтори их в том же порядке.</p><div class="row" style="justify-content:center"><button class="btn sm" data-a="back">Уйти</button></div></div>`);
    let q = [], quit = false; this.handler = (a, v) => { if (a === 'back') quit = true; else q.push(+v); }; this.keyH = c => { const m = /^(?:Digit|Numpad)([1-9])$/.exec(c); if (m) { q.push(+m[1]); G.audio.sfx('ui'); return true; } };
    const T = () => $('#sm-t'), lit = function* (n, cls = 'lit', t = .34) { const b = $('#sm' + n); if (!b) return; b.classList.add(cls); G.audio.tone(200 + n * 70, .25, { w: 'square', v: .12 }); yield* wait(t); b.classList.remove(cls); yield* wait(.1); };
    for (let r = 0; r < rounds.length && !quit; r++) {
      const seq = []; for (let i = 0; i < rounds[r]; i++) { let n; do n = 1 + (Math.random() * 9 | 0); while (n === seq[i - 1]); seq.push(n); }
      for (let ok = false; !ok && !quit;) {
        T().textContent = 'СМОТРИ'; yield* wait(.6); for (const n of seq) { if (quit) break; yield* lit(n); } q = []; if (quit) break; T().textContent = 'ПОВТОРИ'; let i = 0, bad = false;
        while (i < seq.length && !bad && !quit) { if (q.length) { const n = q.shift(); if (n === seq[i]) { i++; yield* lit(n, 'lit', .12); T().textContent = '●'.repeat(i) + '○'.repeat(seq.length - i); } else { bad = true; G.audio.sfx('deny'); yield* lit(n, 'bad', .4); } } else yield; }
        ok = !bad && !quit; if (ok) { G.audio.sfx('ding'); T().textContent = `ЭТАП ${r + 1}/${rounds.length} ✓`; yield* wait(.7); }
      }
    }
    this.close(); return !quit;
  }
}
