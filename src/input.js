// Ввод: клавиатура + мышь (pointer lock), тач (стик + кнопки), геймпад
import { G, clamp } from './g.js';

const KEY = { KeyW: 'up', ArrowUp: 'up', KeyS: 'down', ArrowDown: 'down', KeyA: 'left', ArrowLeft: 'left', KeyD: 'right', ArrowRight: 'right', Space: 'jump', ShiftLeft: 'sprint', ShiftRight: 'sprint', KeyE: 'interact', Enter: 'interact', KeyF: 'throw', KeyQ: 'gadget', KeyR: 'ult', KeyC: 'dodge', KeyL: 'dodge', KeyI: 'inv', Tab: 'inv', Escape: 'pause', KeyP: 'pause', Digit1: 'item1', Digit2: 'item2', Digit3: 'item3', KeyJ: 'attack', KeyK: 'throw' };
const PAD = { 0: 'jump', 2: 'attack', 1: 'dodge', 3: 'interact', 5: 'throw', 4: 'gadget', 7: 'ult', 9: 'pause', 8: 'inv' };

export class Input {
  constructor(canvas) {
    this.canvas = canvas; this.keys = {}; this.pressed = {}; this.move = { x: 0, y: 0 }; this.look = { x: 0, y: 0 }; this.stick = { x: 0, y: 0, on: false }; this.locked = false; this.pad = {}; this.drag = false;
    addEventListener('keydown', e => {
      const a = KEY[e.code]; if (G.touch && a) this.setTouch(false);
      if (a) { if (['Space', 'Tab', 'ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight'].includes(e.code) && G.mode !== 'menu') e.preventDefault(); if (!e.repeat) this.pressed[a] = true; this.keys[a] = true; }
      G.ui && G.ui.key(e);
    });
    addEventListener('keyup', e => { const a = KEY[e.code]; if (a) this.keys[a] = false; });
    addEventListener('blur', () => { this.keys = {}; });
    canvas.addEventListener('mousedown', e => {
      if (G.touch) return; if (G.mode === 'play' && !this.locked) { this.lock(); this.drag = true; }
      if (G.mode !== 'play') { G.ui && G.ui.click(); return; } const a = e.button === 0 ? 'attack' : e.button === 2 ? 'throw' : 'dodge'; this.pressed[a] = true; this.keys[a] = true; e.preventDefault();
    });
    addEventListener('mouseup', e => { this.drag = false; const a = e.button === 0 ? 'attack' : e.button === 2 ? 'throw' : 'dodge'; this.keys[a] = false; });
    addEventListener('mousemove', e => { if (this.locked || this.drag) { this.look.x += e.movementX || 0; this.look.y += e.movementY || 0; } });
    canvas.addEventListener('contextmenu', e => e.preventDefault());
    addEventListener('wheel', e => { if (G.mode === 'play' && G.cam) G.cam.zoom(e.deltaY > 0 ? 1 : -1); }, { passive: true });
    document.addEventListener('pointerlockchange', () => { const was = this.locked; this.locked = document.pointerLockElement === canvas; if (was && !this.locked && G.mode === 'play' && !this.freeing) G.game.pause(); this.freeing = false; });
    document.addEventListener('pointerlockerror', () => { this.locked = false; });
    addEventListener('pointerdown', e => { if (e.pointerType === 'touch' && !G.touch) this.setTouch(true); }, true);
    this.buildTouch();
  }
  lock() { if (G.touch || this.locked) return; try { const p = this.canvas.requestPointerLock(); if (p && p.catch) p.catch(() => { }); } catch (e) { } }
  unlock() { if (this.locked) { this.freeing = true; document.exitPointerLock(); } }
  setTouch(v) { G.touch = v; document.body.classList.toggle('touch', v); if (v) this.unlock(); }
  press(a) { this.pressed[a] = true; }
  hit(a) { if (this.pressed[a]) { this.pressed[a] = false; return true; } return false; }
  held(a) { return !!this.keys[a]; }
  buildTouch() {
    const el = this.tel = document.createElement('div'); el.id = 'touch';
    el.innerHTML = `<div id="tz-look"></div><div id="tz-move"></div><div id="stick"><div id="knob"></div></div>
      <div class="tb big" data-a="attack" style="right:26px;bottom:30px">👊</div><div class="tb" data-a="jump" style="right:150px;bottom:22px">⤒</div>
      <div class="tb" data-a="dodge" style="right:128px;bottom:112px">💨</div><div class="tb" data-a="throw" style="right:36px;bottom:150px">💸</div>
      <div class="tb sm" data-a="gadget" id="tb-gadget" style="right:36px;bottom:238px">🧴</div><div class="tb sm" data-a="ult" id="tb-ult" style="right:112px;bottom:206px">😱</div>
      <div class="tb wide" data-a="interact" id="tb-int" style="right:210px;bottom:120px">E</div>
      <div class="tb sm" data-a="item1" id="tb-item" style="left:50%;bottom:16px;margin-left:-26px">🍜</div>
      <div class="tb sm top" data-a="inv" style="right:74px;top:12px">🎒</div><div class="tb sm top" data-a="pause" style="right:12px;top:12px">⏸</div>`;
    document.body.appendChild(el);
    const stick = el.querySelector('#stick'), knob = el.querySelector('#knob'), mv = el.querySelector('#tz-move'), lk = el.querySelector('#tz-look'); let mid = null, ox = 0, oy = 0; const R = 56, looks = new Map();
    mv.addEventListener('pointerdown', e => { if (mid !== null) return; mid = e.pointerId; ox = e.clientX; oy = e.clientY; stick.style.display = 'block'; stick.style.left = ox - 70 + 'px'; stick.style.top = oy - 70 + 'px'; knob.style.transform = ''; mv.setPointerCapture(e.pointerId); e.preventDefault(); });
    mv.addEventListener('pointermove', e => { if (e.pointerId !== mid) return; let dx = (e.clientX - ox) / R, dy = (e.clientY - oy) / R; const l = Math.hypot(dx, dy); if (l > 1) { dx /= l; dy /= l; } this.stick.x = dx; this.stick.y = -dy; this.stick.on = true; this.stick.far = l > 1.25; knob.style.transform = `translate(${dx * R}px,${dy * R}px)`; });
    const end = e => { if (e.pointerId !== mid) return; mid = null; this.stick.x = this.stick.y = 0; this.stick.on = false; this.stick.far = false; stick.style.display = 'none'; };
    mv.addEventListener('pointerup', end); mv.addEventListener('pointercancel', end);
    lk.addEventListener('pointerdown', e => { looks.set(e.pointerId, [e.clientX, e.clientY]); lk.setPointerCapture(e.pointerId); e.preventDefault(); });
    lk.addEventListener('pointermove', e => { const p = looks.get(e.pointerId); if (!p) return; this.look.x += (e.clientX - p[0]) * 2.2; this.look.y += (e.clientY - p[1]) * 2.2; p[0] = e.clientX; p[1] = e.clientY; });
    const lend = e => looks.delete(e.pointerId); lk.addEventListener('pointerup', lend); lk.addEventListener('pointercancel', lend);
    el.querySelectorAll('.tb').forEach(b => {
      const a = b.dataset.a;
      b.addEventListener('pointerdown', e => { e.preventDefault(); e.stopPropagation(); this.pressed[a] = true; this.keys[a] = true; b.classList.add('on'); G.audio && G.audio.unlock(); });
      const up = e => { this.keys[a] = false; b.classList.remove('on'); }; b.addEventListener('pointerup', up); b.addEventListener('pointercancel', up); b.addEventListener('pointerleave', up);
    });
  }
  update(dt) {
    const k = this.keys; let x = (k.right ? 1 : 0) - (k.left ? 1 : 0), y = (k.up ? 1 : 0) - (k.down ? 1 : 0); const l = Math.hypot(x, y); if (l > 1) { x /= l; y /= l; }
    this.sprint = !!k.sprint;
    if (this.stick.on) { x = this.stick.x; y = this.stick.y; this.sprint = this.stick.far; }
    const gp = navigator.getGamepads ? navigator.getGamepads()[0] : null;
    if (gp && gp.connected) {
      const dz = v => Math.abs(v) < .2 ? 0 : v, ax = dz(gp.axes[0] || 0), ay = dz(gp.axes[1] || 0);
      if (ax || ay) { x = ax; y = -ay; } this.look.x += dz(gp.axes[2] || 0) * dt * 1100; this.look.y += dz(gp.axes[3] || 0) * dt * 800;
      gp.buttons.forEach((b, i) => { const a = PAD[i], was = this.pad[i]; this.pad[i] = b.pressed; if (a && b.pressed && !was) this.pressed[a] = true; if (a === 'attack') k.padAtk = b.pressed; });
      if (gp.buttons[10] && gp.buttons[10].pressed || gp.buttons[6] && gp.buttons[6].pressed) this.sprint = true;
    }
    this.move.x = clamp(x, -1, 1); this.move.y = clamp(y, -1, 1);
  }
  endFrame() { this.pressed = {}; this.look.x = this.look.y = 0; }
}
