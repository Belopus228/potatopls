// Рендер: сцена, небо, свет, тени, пост-обработка, качество
import * as THREE from 'three';
import { EffectComposer } from 'three/addons/postprocessing/EffectComposer.js';
import { RenderPass } from 'three/addons/postprocessing/RenderPass.js';
import { UnrealBloomPass } from 'three/addons/postprocessing/UnrealBloomPass.js';
import { OutputPass } from 'three/addons/postprocessing/OutputPass.js';
import { G, damp, clamp } from './g.js';

export const QUAL = [
  { name: 'Низкое', dpr: 1, shadow: 0, bloom: false, lamps: 0, grass: .25, parts: .5 },
  { name: 'Среднее', dpr: 1.5, shadow: 1024, bloom: false, lamps: 2, grass: .55, parts: .8 },
  { name: 'Высокое', dpr: 1.5, shadow: 2048, bloom: true, lamps: 4, grass: 1, parts: 1, msaa: 4 },
  { name: 'Ультра', dpr: 2, shadow: 4096, bloom: true, lamps: 6, grass: 1.5, parts: 1.3, msaa: 4 },
];
const SKY_V = `varying vec3 vDir; void main(){ vDir=position; gl_Position=projectionMatrix*modelViewMatrix*vec4(position,1.); gl_Position.z=gl_Position.w; }`;
const SKY_F = `
uniform vec3 uTop,uHor,uBot,uSunDir,uSunCol,uCloudCol; uniform float uCloud,uStars,uTime,uSunSize; varying vec3 vDir;
float hash(vec2 p){ return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p){ vec2 i=floor(p),f=fract(p); f=f*f*(3.-2.*f); return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y); }
float fbm(vec2 p){ float a=.5,s=0.; for(int i=0;i<4;i++){ s+=a*noise(p); p=p*2.03+vec2(17.,3.); a*=.5; } return s; }
void main(){
  vec3 d=normalize(vDir); float h=d.y;
  vec3 col = h>0. ? mix(uHor,uTop,pow(h,.55)) : mix(uHor,uBot,pow(min(1.,-h*3.),.7));
  float sd=max(dot(d,normalize(uSunDir)),0.);
  col += uSunCol*(pow(sd,uSunSize)*.9 + pow(sd,8.)*.16 + smoothstep(.9994,.9998,sd)*5.);
  if(uStars>0. && h>0.){ vec2 sp=d.xz/(h+.25)*110.; float hs=hash(floor(sp)); col+=vec3(step(.9978,hs))*uStars*smoothstep(0.,.3,h)*(.6+.4*sin(uTime*2.+hs*400.)); }
  if(uCloud>0. && h>-.02){ vec2 cp=d.xz/(max(h,0.)+.18)*1.4+uTime*vec2(.006,.002); float c=smoothstep(1.-uCloud,1.35-uCloud,fbm(cp));
    float lit=.72+.28*fbm(cp*2.+3.); col=mix(col,uCloudCol*lit+uSunCol*pow(sd,6.)*.3,c*smoothstep(-.02,.12,h)*.92); }
  gl_FragColor=vec4(col,1.);
  #include <tonemapping_fragment>
  #include <colorspace_fragment>
}`;

// яркостный фильтр блума: мягкое «колено», в свечение идёт только превышение над порогом (сцена в HDR, иначе белые стены выжигают кадр)
const BRIGHT_F = `uniform sampler2D tDiffuse; uniform float luminosityThreshold; varying vec2 vUv;
void main(){
  vec3 c=min(texture2D(tDiffuse,vUv).rgb,vec3(16.));
  float v=max(c.r,max(c.g,c.b)),t=luminosityThreshold,k=.25;
  float s=clamp(v-t+k,0.,2.*k); s=s*s/(4.*k);
  c*=max(s,v-t)/max(v,1e-4);
  float m=max(c.r,max(c.g,c.b)); c*=min(1.,3./max(m,1e-4));
  gl_FragColor=vec4(c,1.);
}`;

export class Gfx {
  constructor(canvas) {
    const r = this.renderer = new THREE.WebGLRenderer({ canvas, antialias: !G.mobile, powerPreference: 'high-performance', stencil: false });
    r.outputColorSpace = THREE.SRGBColorSpace; r.toneMapping = THREE.ACESFilmicToneMapping; r.shadowMap.enabled = true; r.shadowMap.type = THREE.PCFShadowMap;
    this.scene = new THREE.Scene();
    this.camera = new THREE.PerspectiveCamera(62, 1, .15, 1500);
    this.hemi = new THREE.HemisphereLight(0xffffff, 0x444444, 1); this.scene.add(this.hemi);
    this.sun = new THREE.DirectionalLight(0xffffff, 2); this.scene.add(this.sun, this.sun.target);
    this.sunDir = new THREE.Vector3(.4, .8, .3).normalize();
    this.plamp = new THREE.PointLight(0xffe2b8, 0, 22, 1.5); this.scene.add(this.plamp);
    this.skyU = { uTop: { value: new THREE.Color() }, uHor: { value: new THREE.Color() }, uBot: { value: new THREE.Color() }, uSunDir: { value: this.sunDir }, uSunCol: { value: new THREE.Color() }, uCloudCol: { value: new THREE.Color() }, uCloud: { value: 0 }, uStars: { value: 0 }, uTime: { value: 0 }, uSunSize: { value: 300 } };
    this.sky = new THREE.Mesh(new THREE.SphereGeometry(500, 24, 16), new THREE.ShaderMaterial({ uniforms: this.skyU, vertexShader: SKY_V, fragmentShader: SKY_F, side: THREE.BackSide, depthWrite: false, fog: false }));
    this.sky.frustumCulled = false; this.sky.renderOrder = -1000; this.scene.add(this.sky);
    this.pmrem = new THREE.PMREMGenerator(r); this.envScene = new THREE.Scene(); this.envSky = new THREE.Mesh(this.sky.geometry, this.sky.material); this.envScene.add(this.envSky);
    this.slots = []; this.lamps = []; this.focus = new THREE.Vector3(); this.scale = 1; this.fps = 60; this.acc = 0; this.frames = 0; this.good = 0; this.slow = 0; this.lt = 0;
    this.uTime = { value: 0 };           // общий uniform времени для ветра/воды
    this.setQuality(G.q, true);
    addEventListener('resize', () => this.resize()); this.resize();
  }
  get Q() { return QUAL[G.q]; }
  setQuality(q, init) {
    G.q = clamp(q | 0, 0, 3); const Q = this.Q, r = this.renderer;
    r.shadowMap.enabled = Q.shadow > 0; this.sun.castShadow = Q.shadow > 0 && !(this.env && this.env.noShadow);
    if (Q.shadow) { const s = this.sun.shadow; if (s.map) { s.map.dispose(); s.map = null; } s.mapSize.set(Q.shadow, Q.shadow); s.bias = -.0004; s.normalBias = .05; }
    for (const s of this.slots) this.scene.remove(s.l); this.slots = [];
    for (let i = 0; i < Q.lamps; i++) { const l = new THREE.PointLight(0xffffff, 0, 18, 1.7); this.scene.add(l); this.slots.push({ l, cur: null, want: null, k: 0 }); }
    if (this.composer) { this.composer.dispose(); this.composer = null; }
    if (Q.bloom) {
      const sz = r.getDrawingBufferSize(new THREE.Vector2()), rt = new THREE.WebGLRenderTarget(sz.x || 2, sz.y || 2, { type: THREE.HalfFloatType, samples: G.mobile ? 0 : (Q.msaa || 0) });
      const c = this.composer = new EffectComposer(r, rt); c.addPass(new RenderPass(this.scene, this.camera));
      this.bloom = new UnrealBloomPass(new THREE.Vector2(256, 256), .5, .6, .9); this.bloom.materialHighPassFilter.fragmentShader = BRIGHT_F; this.bloom.materialHighPassFilter.needsUpdate = true; c.addPass(this.bloom); c.addPass(new OutputPass());
    }
    this.scene.traverse(o => { if (o.material) (Array.isArray(o.material) ? o.material : [o.material]).forEach(m => m.needsUpdate = true); });
    if (!init) { this.resize(); if (this.env) { const lamps = this.lamps; this.setEnv(this.env); this.lamps = lamps; } }
  }
  resize() {
    const w = innerWidth, h = innerHeight, pr = Math.min(devicePixelRatio || 1, this.Q.dpr) * this.scale;
    this.renderer.setPixelRatio(pr); this.renderer.setSize(w, h, false);
    if (this.composer) { this.composer.setPixelRatio(pr); this.composer.setSize(w, h); }
    this.camera.aspect = w / h; this.camera.fov = w < h ? 78 : 62; this.camera.updateProjectionMatrix();
  }
  setEnv(e) {
    this.env = e; const u = this.skyU, s = this.scene, Q = this.Q;
    u.uTop.value.set(e.top); u.uHor.value.set(e.hor); u.uBot.value.set(e.bot ?? e.hor); u.uSunCol.value.set(e.sunGlow ?? e.sunCol ?? 0); u.uCloudCol.value.set(e.cloudCol ?? 0xffffff);
    u.uCloud.value = G.q > 0 ? (e.clouds || 0) : 0; u.uStars.value = e.stars || 0; u.uSunSize.value = e.sunSize || 300;
    this.sunDir.set(...(e.sun || [.4, .8, .3])).normalize();
    this.sky.visible = !e.indoor; s.background = e.indoor ? new THREE.Color(e.bg ?? 0x000000) : null;
    s.fog = e.fogExp ? new THREE.FogExp2(e.fogExp[0], e.fogExp[1]) : e.fog ? new THREE.Fog(e.fog[0], e.fog[1], e.fog[2]) : null;
    this.hemi.color.set(e.hemiSky ?? 0xffffff); this.hemi.groundColor.set(e.hemiGnd ?? 0x444444); this.hemi.intensity = e.hemiInt ?? 1;
    this.sun.color.set(e.sunCol ?? 0xffffff); this.sun.intensity = e.sunInt ?? 0; this.sun.castShadow = Q.shadow > 0 && !e.noShadow && (e.sunInt ?? 0) > 0;
    const sc = this.sun.shadow.camera, S = e.shadowSize || 36; sc.left = -S; sc.right = S; sc.top = S; sc.bottom = -S; sc.near = 1; sc.far = 260; sc.updateProjectionMatrix();
    this.renderer.toneMappingExposure = e.exposure ?? 1;
    if (this.bloom) { const b = e.bloom || [.3, .5, 1.1]; this.bloom.strength = b[0]; this.bloom.radius = b[1]; this.bloom.threshold = b[2]; }
    this.plamp.intensity = (e.lamp || 0) * 1.7; this.plamp.color.set(e.lampCol ?? 0xffe2b8);
    if (this.envRT) this.envRT.dispose();
    const cl = u.uCloud.value, st = u.uStars.value; u.uCloud.value = 0; u.uStars.value = 0;
    this.envRT = this.pmrem.fromScene(this.envScene, 0, 1, 1200); u.uCloud.value = cl; u.uStars.value = st;
    s.environment = this.envRT.texture; s.environmentIntensity = e.envInt ?? .7;
    this.lamps = []; for (const sl of this.slots) { sl.cur = sl.want = null; sl.k = 0; sl.l.intensity = 0; }
  }
  setFogDensity(d) { const f = this.scene.fog; if (f && f.isFogExp2) f.density = d; }
  updateLamps(dt) {
    const n = this.slots.length; if (!n) return; this.lt -= dt;
    if (this.lt <= 0) {
      this.lt = .3; const f = this.focus, near = [];
      for (const L of this.lamps) { if (L.off) continue; L._d = (L.x - f.x) ** 2 + (L.z - f.z) ** 2 + (L.y - f.y) ** 2 * 2; if (near.length < n) { near.push(L); near.sort((a, b) => a._d - b._d); } else if (L._d < near[n - 1]._d) { near[n - 1] = L; near.sort((a, b) => a._d - b._d); } }
      for (const s of this.slots) { if (s.want && !near.includes(s.want)) s.want = null; }
      for (const L of near) { if (this.slots.some(s => s.want === L)) continue; const s = this.slots.find(s => !s.want); if (s) s.want = L; }
    }
    for (const s of this.slots) {
      if (s.cur !== s.want) { s.k = damp(s.k, 0, 14, dt); if (s.k < .06) { s.cur = s.want; if (s.cur) { s.l.position.set(s.cur.x, s.cur.y, s.cur.z); s.l.color.set(s.cur.color); s.l.distance = s.cur.dist || 18; } } }
      else s.k = damp(s.k, 1, 7, dt);
      let fl = 1; if (s.cur && s.cur.flicker) { const t = G.time * 9 + s.cur.x; fl = (Math.sin(t) * Math.sin(t * 2.7) > .55) ? .25 : 1; }
      s.l.intensity = s.cur ? s.cur.int * s.k * fl : 0;
    }
  }
  render(dt) {
    const c = this.camera, f = this.focus, d = this.sunDir;
    this.sky.position.copy(c.position); this.skyU.uTime.value = G.time; this.uTime.value = G.time;
    this.sun.position.set(f.x + d.x * 110, f.y + d.y * 110, f.z + d.z * 110); this.sun.target.position.copy(f);
    this.plamp.position.set(f.x, f.y + 3.5, f.z); this.updateLamps(dt);
    if (this.composer) this.composer.render(dt); else this.renderer.render(this.scene, c);
    // динамическое разрешение
    this.acc += dt; this.frames++;
    if (this.acc >= 1) {
      this.fps = this.frames / this.acc; this.acc = 0; this.frames = 0;
      if (G.settings && G.settings.dyn && G.mode === 'play') {
        if (this.fps < 27 && this.scale > .55) { this.scale = Math.max(.55, this.scale - .12); this.good = 0; this.resize(); }
        else if (this.fps > 56 && this.scale < 1) { if (++this.good > 4) { this.scale = Math.min(1, this.scale + .08); this.good = 0; this.resize(); } } else this.good = 0;
        // совсем слабое устройство: разрешение уже минимальное, а кадров всё равно мало — снижаем качество на ступень
        if (this.fps < 22 && this.scale <= .56 && G.q > 0) { if (++this.slow >= 4) { this.slow = 0; this.scale = .8; G.settings.q = G.q - 1; this.setQuality(G.q - 1); G.game.saveSettings(); G.ui.toast('Мало кадров — графика снижена: «' + QUAL[G.q].name + '»', 'hint'); } } else this.slow = 0;
      }
    }
  }
}
// покачивание на ветру для листвы/травы (инжект в стандартные материалы)
export function windify(mat, amp = .12, freq = 1.6) {
  mat.onBeforeCompile = sh => {
    sh.uniforms.uTime = G.gfx.uTime;
    sh.vertexShader = 'uniform float uTime;\n' + sh.vertexShader.replace('#include <begin_vertex>', `#include <begin_vertex>
      #ifdef USE_INSTANCING
        vec3 wp0=(instanceMatrix*vec4(position,1.)).xyz;
      #else
        vec3 wp0=position;
      #endif
      float wk=${amp.toFixed(3)}*max(0.,position.y)*(.6+.4*sin(wp0.x*.7+wp0.z*.9));
      transformed.x+=sin(uTime*${freq.toFixed(2)}+wp0.x*.35+wp0.z*.27)*wk; transformed.z+=cos(uTime*${(freq * .8).toFixed(2)}+wp0.x*.21-wp0.z*.4)*wk*.7;`);
  };
  mat.customProgramCacheKey = () => 'wind' + amp + '_' + freq; return mat;
}
