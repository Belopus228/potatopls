// Эффекты: частицы, кольца, диски-предупреждения, всплывающий текст, погода
import * as THREE from 'three';
import { G, rand, PI, TAU, sat } from './g.js';
import { puffTex, glowTex, ringTex, discTex, memo } from './tex.js';

const PV = `attribute vec4 aCol; attribute float aSize; varying vec4 vCol; uniform float uScale;
void main(){ vCol=aCol; vec4 mv=modelViewMatrix*vec4(position,1.); gl_Position=projectionMatrix*mv; gl_PointSize=min(aSize*uScale/max(.1,-mv.z),420.); }`;
const PF = `uniform sampler2D map; varying vec4 vCol; uniform float uAdd;
void main(){ vec4 t=texture2D(map,gl_PointCoord); float a=t.a*vCol.a; if(a<.004) discard; gl_FragColor=vec4(vCol.rgb*t.rgb*mix(1.,a,uAdd),a);
  #include <tonemapping_fragment>
  #include <colorspace_fragment>
}`;
const WV = `attribute vec3 aRnd; uniform vec3 uCam,uVel,uBox; uniform float uTime,uSize,uScale,uSway; varying float vA;
void main(){ vec3 p=aRnd*uBox+uVel*uTime; p.x+=sin(uTime*.8+aRnd.y*40.)*uSway; p.z+=cos(uTime*.7+aRnd.x*40.)*uSway;
  p=mod(p-uCam,uBox)-uBox*.5+uCam; vec4 mv=viewMatrix*vec4(p,1.); gl_Position=projectionMatrix*mv; gl_PointSize=min(uSize*(.6+aRnd.z*.8)*uScale/max(.3,-mv.z),90.);
  vA=smoothstep(uBox.x*.5,uBox.x*.3,length(p.xz-uCam.xz))*smoothstep(.3,1.5,-mv.z); }`;
const WF = `uniform vec3 uCol; uniform float uA; uniform int uShape; varying float vA;
void main(){ vec2 c=gl_PointCoord-.5; float a;
  if(uShape==0) a=smoothstep(.07,.0,abs(c.x))*smoothstep(.5,.2,abs(c.y));           // дождь
  else if(uShape==1) a=smoothstep(.5,.1,length(c));                                  // снег/пыль
  else { float r=length(c); a=smoothstep(.5,.44,r)*(smoothstep(.3,.46,r)*.9+.12)+smoothstep(.12,.0,length(c-vec2(-.15,-.15)))*.8; } // пузыри
  gl_FragColor=vec4(uCol,a*uA*vA); if(gl_FragColor.a<.01) discard;
  #include <tonemapping_fragment>
  #include <colorspace_fragment>
}`;
const WEATHER = {
  rain: { n: 1400, vel: [-1.5, -26, 1], size: .55, col: 0xaac4e6, a: .5, shape: 0, sway: 0, box: [36, 22, 36] },
  snow: { n: 1100, vel: [.6, -1.6, .3], size: .11, col: 0xffffff, a: .9, shape: 1, sway: .5, box: [40, 22, 40] },
  dust: { n: 260, vel: [.15, .05, .1], size: .09, col: 0xfff2c8, a: .5, shape: 1, sway: .4, box: [30, 12, 30], add: true },
  spores: { n: 320, vel: [.1, .25, 0], size: .12, col: 0xb8ff8a, a: .7, shape: 1, sway: .7, box: [34, 14, 34], add: true },
  bubbles: { n: 220, vel: [.2, .8, .1], size: .3, col: 0xdff6ff, a: .7, shape: 2, sway: .6, box: [40, 16, 40] },
  embers: { n: 300, vel: [.3, 1.4, 0], size: .09, col: 0xff8a3a, a: .9, shape: 1, sway: .8, box: [30, 14, 30], add: true },
  ash: { n: 700, vel: [1.2, -.7, .4], size: .13, col: 0xcfd4dc, a: .6, shape: 1, sway: .9, box: [40, 20, 40] },
};

class PSys {
  constructor(n, add, map) {
    this.n = n; this.i = 0; this.pos = new Float32Array(n * 3); this.col = new Float32Array(n * 4); this.size = new Float32Array(n); this.d = new Float32Array(n * 12); this.live = 0;
    const g = this.geo = new THREE.BufferGeometry(); g.setAttribute('position', new THREE.BufferAttribute(this.pos, 3)); g.setAttribute('aCol', new THREE.BufferAttribute(this.col, 4)); g.setAttribute('aSize', new THREE.BufferAttribute(this.size, 1));
    this.u = { map: { value: map }, uScale: { value: 500 }, uAdd: { value: add ? 1 : 0 } };
    this.mesh = new THREE.Points(g, new THREE.ShaderMaterial({ uniforms: this.u, vertexShader: PV, fragmentShader: PF, transparent: true, depthWrite: false, blending: add ? THREE.AdditiveBlending : THREE.NormalBlending }));
    this.mesh.frustumCulled = false; this.mesh.renderOrder = add ? 21 : 20;
  }
  // d: vx vy vz life max s0 s1 a grav drag
  emit(x, y, z, vx, vy, vz, life, s0, s1, r, g, b, a, grav, drag) {
    const i = this.i; this.i = (i + 1) % this.n; const p = i * 3, c = i * 4, d = i * 12;
    this.pos[p] = x; this.pos[p + 1] = y; this.pos[p + 2] = z; this.col[c] = r; this.col[c + 1] = g; this.col[c + 2] = b; this.col[c + 3] = a; this.size[i] = s0;
    const D = this.d; D[d] = vx; D[d + 1] = vy; D[d + 2] = vz; D[d + 3] = life; D[d + 4] = life; D[d + 5] = s0; D[d + 6] = s1; D[d + 7] = a; D[d + 8] = grav; D[d + 9] = drag;
  }
  update(dt) {
    const D = this.d, P = this.pos, C = this.col, S = this.size; let live = 0;
    for (let i = 0; i < this.n; i++) {
      const d = i * 12; if (D[d + 3] <= 0) continue; D[d + 3] -= dt; const p = i * 3;
      if (D[d + 3] <= 0) { S[i] = 0; C[i * 4 + 3] = 0; continue; } live++;
      const k = 1 - D[d + 9] * dt; D[d] *= k; D[d + 1] = D[d + 1] * k - D[d + 8] * dt; D[d + 2] *= k;
      P[p] += D[d] * dt; P[p + 1] += D[d + 1] * dt; P[p + 2] += D[d + 2] * dt;
      const t = 1 - D[d + 3] / D[d + 4]; S[i] = D[d + 5] + (D[d + 6] - D[d + 5]) * t; C[i * 4 + 3] = D[d + 7] * (t < .12 ? t / .12 : 1 - (t - .12) / .88);
    }
    if (live || this.live) { const a = this.geo.attributes; a.position.needsUpdate = a.aCol.needsUpdate = a.aSize.needsUpdate = true; } this.live = live;
  }
}

export class Fx {
  constructor(scene) {
    this.scene = scene; const m = G.mobile ? .6 : 1;
    this.soft = new PSys(500 * m | 0, false, puffTex()); this.add = new PSys(700 * m | 0, true, glowTex()); scene.add(this.soft.mesh, this.add.mesh);
    this.rings = []; this.discs = []; this.texts = []; this.wx = null; this.col = new THREE.Color();
    const pg = new THREE.PlaneGeometry(1, 1); pg.rotateX(-PI / 2);
    for (let i = 0; i < 10; i++) { const r = new THREE.Mesh(pg, new THREE.MeshBasicMaterial({ map: ringTex(), transparent: true, depthWrite: false, blending: THREE.AdditiveBlending, fog: false })); r.visible = false; r.renderOrder = 15; scene.add(r); this.rings.push({ m: r, t: 0 }); }
    for (let i = 0; i < 14; i++) { const r = new THREE.Mesh(pg, new THREE.MeshBasicMaterial({ map: discTex(), transparent: true, depthWrite: false, fog: false, polygonOffset: true, polygonOffsetFactor: -3 })); r.visible = false; r.renderOrder = 14; scene.add(r); this.discs.push({ m: r, t: 0 }); }
    this.layer = document.createElement('div'); this.layer.id = 'fxl'; document.getElementById('ui').prepend(this.layer);
    for (let i = 0; i < 16; i++) { const e = document.createElement('div'); e.className = 'ftext'; this.layer.appendChild(e); this.texts.push({ e, t: 0, p: new THREE.Vector3() }); }
    this.v = new THREE.Vector3();
  }
  // пресеты
  burst(kind, p, n = 8, o = {}) {
    n = Math.max(1, Math.round(n * G.gfx.Q.parts)); const c = this.col, x = p.x, y = p.y, z = p.z, s = o.s || 1, sp = o.sp || 1;
    for (let i = 0; i < n; i++) {
      const a = rand(TAU), u = rand(-1, 1), h = Math.sqrt(1 - u * u), dx = Math.cos(a) * h, dz = Math.sin(a) * h, dy = u;
      switch (kind) {
        case 'hit': c.setHSL(.1 + rand(.06), 1, .6); this.add.emit(x, y, z, dx * 7 * sp, dy * 6 + 2, dz * 7 * sp, rand(.15, .35), .35 * s, .05, c.r, c.g, c.b, 1, 14, 2); break;
        case 'spark': c.set(o.color ?? 0xffd070); this.add.emit(x, y, z, dx * 5 * sp, Math.abs(dy) * 6 * sp, dz * 5 * sp, rand(.3, .7), .18 * s, .02, c.r, c.g, c.b, 1, 16, 1); break;
        case 'dust': c.set(o.color ?? 0x9a948a); this.soft.emit(x + dx * .2 * s, y + .1, z + dz * .2 * s, dx * 1.6 * sp, .5 + rand(.8), dz * 1.6 * sp, rand(.4, .9), .5 * s, 1.5 * s, c.r, c.g, c.b, .5, -.4, 2.5); break;
        case 'smoke': c.set(o.color ?? 0x55585e); this.soft.emit(x + dx * .3 * s, y + dy * .3 * s, z + dz * .3 * s, dx * .8 * sp, 1 + rand(1.2), dz * .8 * sp, rand(.8, 1.8), .8 * s, 2.6 * s, c.r, c.g, c.b, .55, -.5, 1.2); break;
        case 'steam': c.set(o.color ?? 0xf2f2f2); this.soft.emit(x + dx * .4 * s, y + rand(.4), z + dz * .4 * s, dx * 1.5 * sp, 1.5 + rand(2), dz * 1.5 * sp, rand(.9, 1.9), .9 * s, 3.4 * s, c.r, c.g, c.b, .42, -.8, 1.4); break;
        case 'goo': c.set(o.color ?? 0x9ed63a); this.soft.emit(x, y, z, dx * 4 * sp, Math.abs(dy) * 5 + 1, dz * 4 * sp, rand(.35, .7), .34 * s, .1, c.r, c.g, c.b, 1, 18, 1); break;
        case 'cash': c.setHSL(.33 + rand(.05), .6, .45 + rand(.2)); this.soft.emit(x, y, z, dx * 3.5 * sp, Math.abs(dy) * 5 + 2, dz * 3.5 * sp, rand(.6, 1.2), .24 * s, .16, c.r, c.g, c.b, 1, 9, 2.4); break;
        case 'water': c.set(o.color ?? 0xa8dcff); this.soft.emit(x + dx * .2, y, z + dz * .2, dx * 3 * sp, Math.abs(dy) * 6 * sp + 2, dz * 3 * sp, rand(.4, .8), .28 * s, .1, c.r, c.g, c.b, .85, 18, .6); break;
        case 'heal': c.set(o.color ?? 0x7dff8a); this.add.emit(x + dx * .5, y + rand(1.4), z + dz * .5, 0, 1.5 + rand(1), 0, rand(.6, 1.1), .3, .05, c.r, c.g, c.b, .9, 0, 0); break;
        case 'magic': c.set(o.color ?? 0xb070ff); this.add.emit(x + dx * .3 * s, y + dy * .3 * s, z + dz * .3 * s, dx * 3 * sp, dy * 3 * sp + 1, dz * 3 * sp, rand(.4, .9), .5 * s, .05, c.r, c.g, c.b, .9, 0, 2); break;
        case 'fire': c.setHSL(.03 + rand(.07), 1, .55); this.add.emit(x + dx * .25 * s, y + rand(.2), z + dz * .25 * s, dx * .6, 1.6 + rand(1.6), dz * .6, rand(.3, .7), .7 * s, .1, c.r, c.g, c.b, .8, -1, 1); break;
        case 'fog': c.set(o.color ?? 0xdfe4ea); this.soft.emit(x + dx * 1.5 * s, y + Math.abs(dy) * s, z + dz * 1.5 * s, dx * 1.2 * sp, rand(.6), dz * 1.2 * sp, rand(1.2, 2.6), 2 * s, 5 * s, c.r, c.g, c.b, .4, 0, .8); break;
        case 'snow': c.set(0xffffff); this.soft.emit(x + dx * .3, y + .1, z + dz * .3, dx * 2.4 * sp, Math.abs(dy) * 3 + 1, dz * 2.4 * sp, rand(.4, .8), .3 * s, .5 * s, 1, 1, 1, .8, 9, 2); break;
        case 'bub': c.set(0xdff6ff); this.add.emit(x + dx * .4 * s, y + dy * .4 * s, z + dz * .4 * s, dx * 1.5 * sp, 1 + rand(1.5), dz * 1.5 * sp, rand(.6, 1.3), .22 * s, .3 * s, c.r, c.g, c.b, .6, -.6, 1.5); break;
      }
    }
  }
  trail(p, color = 0x7dff8a, s = .3) { const c = this.col.set(color); this.add.emit(p.x, p.y, p.z, rand(-.3, .3), rand(-.3, .3), rand(-.3, .3), .28, s, .02, c.r, c.g, c.b, .7, 0, 0); }
  ring(p, r0, r1, t = .4, color = 0xffffff, y = .08) { let r = this.rings.find(r => r.t <= 0) || this.rings[0]; r.t = r.T = t; r.r0 = r0; r.r1 = r1; r.m.position.set(p.x, p.y + y, p.z); r.m.material.color.set(color); r.m.visible = true; }
  // предупреждающий диск на земле: заполняется за t секунд
  disc(p, r, t, color = 0xff3b30) { let d = this.discs.find(d => d.t <= 0); if (!d) return null; d.t = d.T = t; d.r = r; d.m.position.set(p.x, p.y + .06, p.z); d.m.material.color.set(color); d.m.visible = true; d.m.scale.setScalar(r * 2); return d; }
  text(p, str, cls = '') { let t = this.texts.find(t => t.t <= 0) || this.texts[0]; t.t = .9; t.p.copy(p); t.e.textContent = str; t.e.className = 'ftext on ' + cls; t.ox = rand(-18, 18); }
  weather(kind) {
    if (this.wx) { this.scene.remove(this.wx); this.wx.geometry.dispose(); this.wx.material.dispose(); this.wx = null; } this.wk = kind; const W = WEATHER[kind]; if (!W || G.q === 0) return;
    const n = W.n * G.gfx.Q.parts | 0, a = new Float32Array(n * 3); for (let i = 0; i < a.length; i++) a[i] = Math.random();
    const g = new THREE.BufferGeometry(); g.setAttribute('aRnd', new THREE.BufferAttribute(a, 3)); g.setAttribute('position', new THREE.BufferAttribute(new Float32Array(n * 3), 3));
    this.wu = { uCam: { value: new THREE.Vector3() }, uVel: { value: new THREE.Vector3(...W.vel) }, uBox: { value: new THREE.Vector3(...W.box) }, uTime: { value: 0 }, uSize: { value: W.size }, uScale: { value: 500 }, uSway: { value: W.sway }, uCol: { value: new THREE.Color(W.col) }, uA: { value: W.a }, uShape: { value: W.shape } };
    this.wx = new THREE.Points(g, new THREE.ShaderMaterial({ uniforms: this.wu, vertexShader: WV, fragmentShader: WF, transparent: true, depthWrite: false, blending: W.add ? THREE.AdditiveBlending : THREE.NormalBlending }));
    this.wx.frustumCulled = false; this.wx.renderOrder = 19; this.scene.add(this.wx);
  }
  update(dt) {
    const cam = G.gfx.camera, sc = innerHeight / (2 * Math.tan(cam.fov * PI / 360)); this.soft.u.uScale.value = this.add.u.uScale.value = sc;
    this.soft.update(dt); this.add.update(dt);
    for (const r of this.rings) if (r.t > 0) { r.t -= dt; const k = 1 - Math.max(0, r.t) / r.T, e = 1 - (1 - k) * (1 - k); r.m.scale.setScalar((r.r0 + (r.r1 - r.r0) * e) * 2); r.m.material.opacity = 1 - k; if (r.t <= 0) r.m.visible = false; }
    for (const d of this.discs) if (d.t > 0) { d.t -= dt; const k = 1 - Math.max(0, d.t) / d.T; d.m.material.opacity = .3 + .5 * k + .15 * Math.sin(G.time * 24) * k; if (d.t <= 0) d.m.visible = false; }
    if (this.wx) { this.wu.uCam.value.copy(cam.position); this.wu.uTime.value = G.time; this.wu.uScale.value = sc; }
    const w = innerWidth, h = innerHeight, v = this.v;
    for (const t of this.texts) if (t.t > 0) { t.t -= dt; if (t.t <= 0) { t.e.className = 'ftext'; continue; } v.copy(t.p).project(cam); if (v.z > 1) { t.e.style.opacity = 0; continue; } const k = 1 - t.t / .9; t.e.style.transform = `translate(${(v.x * .5 + .5) * w + t.ox}px,${(-v.y * .5 + .5) * h - k * 60}px) translate(-50%,-50%) scale(${1 + .5 * Math.max(0, .25 - k) * 4})`; t.e.style.opacity = sat(2.5 - k * 2.5); }
  }
  clear() { for (const s of [this.soft, this.add]) { s.d.fill(0); s.size.fill(0); s.live = 1; } for (const r of this.rings) { r.t = 0; r.m.visible = false; } for (const d of this.discs) { d.t = 0; d.m.visible = false; } for (const t of this.texts) { t.t = 0; t.e.className = 'ftext'; } }
}
