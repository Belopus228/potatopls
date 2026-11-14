class_name Level
extends Node3D
## Основа уровня и «конструктор»: стены, полы, лестницы, дома, предметы, вывески, свет,
## интерактивы, триггеры, контрольные точки. Сами уровни наследуются и переопределяют build() и begin().

const ENVS := {
	# top, horizon, ground — небо; sun — цвет, энергия, поворот (градусы); amb — яркость неба; fog — цвет и плотность
	"day": {"top": Color(0.22, 0.42, 0.75), "hor": Color(0.62, 0.74, 0.86), "gnd": Color(0.3, 0.32, 0.3), "sun": Color(1.0, 0.96, 0.88), "sun_e": 0.95, "rot": Vector3(-48, -35, 0), "amb": 0.45, "fog": Color(0.66, 0.76, 0.86), "fog_d": 0.004, "day": true},
	"clean": {"top": Color(0.35, 0.6, 0.9), "hor": Color(0.82, 0.9, 0.96), "gnd": Color(0.6, 0.65, 0.7), "sun": Color(1.0, 1.0, 0.98), "sun_e": 0.9, "rot": Vector3(-55, 30, 0), "amb": 0.5, "fog": Color(0.85, 0.92, 0.97), "fog_d": 0.006, "day": true},
	"dusk": {"top": Color(0.16, 0.18, 0.38), "hor": Color(0.95, 0.52, 0.32), "gnd": Color(0.2, 0.18, 0.2), "sun": Color(1.0, 0.6, 0.38), "sun_e": 0.9, "rot": Vector3(-14, -60, 0), "amb": 0.45, "fog": Color(0.75, 0.5, 0.45), "fog_d": 0.006, "day": true},
	"snow": {"top": Color(0.55, 0.62, 0.74), "hor": Color(0.86, 0.88, 0.92), "gnd": Color(0.8, 0.82, 0.86), "sun": Color(1.0, 0.92, 0.84), "sun_e": 0.7, "rot": Vector3(-28, -50, 0), "amb": 0.5, "fog": Color(0.84, 0.87, 0.92), "fog_d": 0.011, "day": true},
	"night": {"top": Color(0.015, 0.02, 0.06), "hor": Color(0.06, 0.07, 0.16), "gnd": Color(0.02, 0.02, 0.04), "sun": Color(0.5, 0.6, 1.0), "sun_e": 0.28, "rot": Vector3(-55, 40, 0), "amb": 0.55, "fog": Color(0.07, 0.08, 0.17), "fog_d": 0.012, "day": false},
	"fog": {"top": Color(0.42, 0.45, 0.5), "hor": Color(0.6, 0.62, 0.66), "gnd": Color(0.4, 0.42, 0.45), "sun": Color(0.8, 0.84, 0.95), "sun_e": 0.5, "rot": Vector3(-60, 10, 0), "amb": 0.85, "fog": Color(0.6, 0.62, 0.66), "fog_d": 0.035, "day": true},
	"grave": {"top": Color(0.02, 0.05, 0.05), "hor": Color(0.1, 0.2, 0.16), "gnd": Color(0.03, 0.05, 0.04), "sun": Color(0.55, 0.9, 0.7), "sun_e": 0.3, "rot": Vector3(-50, -20, 0), "amb": 0.6, "fog": Color(0.1, 0.2, 0.16), "fog_d": 0.03, "day": false},
	"indoor": {"bg": Color(0.02, 0.02, 0.03), "sun_e": 0.0, "amb_col": Color(0.42, 0.42, 0.5), "amb": 0.75, "fog": Color(0.05, 0.05, 0.07), "fog_d": 0.0, "day": false},
}
const _FACES := [
	[Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(0, 1, 0)], [Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 1, 0)],
	[Vector3(0, 1, 0), Vector3(1, 0, 0), Vector3(0, 0, -1)], [Vector3(0, -1, 0), Vector3(1, 0, 0), Vector3(0, 0, 1)],
	[Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 1, 0)], [Vector3(0, 0, -1), Vector3(-1, 0, 0), Vector3(0, 1, 0)],
]

static var _scn := {}
static var _aabb := {}

var id := ""
var title := ""
var chapter := ""
var music := ""
var cps := {}
var kill_y := -25.0
var is_day := true
var env_name := "day"
var inter: Array = []
var trigs: Array = []
var ticks: Array[Callable] = []
var zones: Array = []
var t := 0.0
var rng := RandomNumberGenerator.new()
var wenv: WorldEnvironment
var env: Environment
var sun: DirectionalLight3D
var body: StaticBody3D
var _st := {}
var _mats := {}
var _lamps: Array = []
var _pool: Array = []
var _lamp_t := 0.0


# ---------- жизненный цикл ----------

func setup() -> void:
	rng.seed = hash(id) + 7
	body = StaticBody3D.new()
	body.name = "Static"
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	wenv = WorldEnvironment.new()
	env = Environment.new()
	wenv.environment = env
	add_child(wenv)
	sun = DirectionalLight3D.new()
	add_child(sun)
	set_env("day")
	build()
	commit()
	apply_quality()


## Геометрия, персонажи, задания. Переопределяется.
func build() -> void:
	pass


## Вызывается после загрузки, когда экран открылся. cp — контрольная точка, с которой начали.
func begin(_cp: String) -> void:
	pass


func _physics_process(dt: float) -> void:
	t += dt
	var p := G.player
	if p == null:
		return
	if G.mode == "play":
		var pp := p.global_position
		for tr in trigs:
			if tr["done"] or (tr.has("cond") and not tr["cond"].call()):
				continue
			var d: Vector3 = (pp - tr["pos"]).abs()
			var h: Vector3 = tr["half"]
			if d.x <= h.x and d.y <= h.y and d.z <= h.z:
				if tr["once"]:
					tr["done"] = true
				tr["fn"].call()
		for z in zones:
			var d2: Vector3 = (pp - z["pos"]).abs()
			var h2: Vector3 = z["half"]
			if d2.x <= h2.x and d2.y <= h2.y and d2.z <= h2.z:
				z["fn"].call(dt)
	for f in ticks:
		f.call(dt)
	_update_lamps(dt)


# ---------- окружение ----------

func set_env(nm: String, o := {}) -> void:
	env_name = nm
	var e: Dictionary = ENVS[nm].duplicate()
	for k in o:
		e[k] = o[k]
	is_day = e.get("day", true)
	if e.has("bg"):
		env.background_mode = Environment.BG_COLOR
		env.background_color = e["bg"]
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = e.get("amb_col", Color(0.4, 0.4, 0.45))
	else:
		var sm := ProceduralSkyMaterial.new()
		sm.sky_top_color = e["top"]
		sm.sky_horizon_color = e["hor"]
		sm.ground_horizon_color = e["hor"]
		sm.ground_bottom_color = e["gnd"]
		sm.sun_angle_max = 12.0
		sm.sky_curve = 0.12
		var sky := Sky.new()
		sky.sky_material = sm
		env.background_mode = Environment.BG_SKY
		env.sky = sky
		env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = e.get("amb", 0.7)
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 1.0
	if G.opts.has("tm"):
		env.tonemap_mode = int(G.opts["tm"]) as Environment.ToneMapper
	if G.opts.has("nofog"):
		e["fog_d"] = 0.0
	if G.opts.has("bgcol"):
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.1, 0.3, 0.1)
	env.fog_enabled = float(e.get("fog_d", 0.0)) > 0.0
	env.fog_light_color = e.get("fog", Color(0.6, 0.7, 0.8))
	env.fog_density = e.get("fog_d", 0.0)
	env.fog_sky_affect = e.get("fog_sky", 0.35)
	sun.visible = float(e.get("sun_e", 0.0)) > 0.0
	sun.light_color = e.get("sun", Color.WHITE)
	sun.light_energy = e.get("sun_e", 0.0)
	sun.rotation_degrees = e.get("rot", Vector3(-50, -30, 0))
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 70.0
	sun.shadow_bias = 0.06
	sun.shadow_normal_bias = 1.5
	apply_quality()


func apply_quality() -> void:
	if env == null:
		return
	var q := G.quality
	sun.shadow_enabled = q >= 1 and sun.visible
	env.glow_enabled = q >= 1
	env.glow_intensity = 0.5
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.25
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	var want: int = [3, 5, 8][q]
	while _pool.size() > want:
		var e: Dictionary = _pool.pop_back()
		if e["lamp"] != null:
			e["lamp"]["on"] = false
		e["l"].queue_free()
	while _pool.size() < want:
		var l := OmniLight3D.new()
		l.light_energy = 0.0
		l.shadow_enabled = false
		l.omni_attenuation = 1.1
		add_child(l)
		_pool.append({"l": l, "lamp": null, "w": 0.0})


# ---------- геометрия ----------

func _stool(mat: Variant) -> SurfaceTool:
	var m := Mats.get_mat(mat)
	var key := m.get_instance_id()
	if not _st.has(key):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		_st[key] = st
		_mats[key] = m
	return _st[key]


## Собрать накопленные коробки в меши (по одному на материал). Можно звать повторно.
func commit() -> void:
	for key in _st:
		var st: SurfaceTool = _st[key]
		st.set_material(_mats[key])
		var mesh := st.commit()
		if mesh == null or mesh.get_surface_count() == 0:
			continue
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.name = "Batch"
		add_child(mi)
	_st.clear()
	_mats.clear()


func _quad(st: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, n: Vector3, u := Vector2.ONE, uo := Vector2.ZERO) -> void:
	# p0..p3 — против часовой стрелки, если смотреть снаружи; в Godot лицевая сторона — по часовой
	var uv := [Vector2(uo.x, uo.y + u.y), Vector2(uo.x + u.x, uo.y + u.y), Vector2(uo.x + u.x, uo.y), Vector2(uo.x, uo.y)]
	var pts := [p0, p1, p2, p3]
	for i in [0, 2, 1, 0, 3, 2]:
		st.set_normal(n)
		st.set_uv(uv[i])
		st.add_vertex(pts[i])


func _add_box(st: SurfaceTool, xf: Transform3D, s: Vector3, skip_bottom := false) -> void:
	var h := s * 0.5
	for f in _FACES:
		var n: Vector3 = f[0]
		if skip_bottom and n.y < -0.5:
			continue
		var u: Vector3 = f[1]
		var v: Vector3 = f[2]
		var c := n * h
		var eu := u * absf(u.dot(h))
		var ev := v * absf(v.dot(h))
		_quad(st, xf * (c - eu - ev), xf * (c + eu - ev), xf * (c + eu + ev), xf * (c - eu + ev), xf.basis * n, Vector2(eu.length() * 2.0, ev.length() * 2.0))


func _xf(c: Vector3, o: Dictionary) -> Transform3D:
	return Transform3D(Basis.from_euler(Vector3(deg_to_rad(o.get("pitch", 0.0)), deg_to_rad(o.get("yaw", 0.0)), deg_to_rad(o.get("roll", 0.0)))), c)


## Коробка: центр, размер, материал. o: yaw/pitch/roll (градусы), col=false — без столкновений, hidden — только столкновение.
func box(c: Vector3, s: Vector3, mat: Variant = "concrete", o := {}) -> CollisionShape3D:
	var xf := _xf(c, o)
	if not o.get("hidden", false):
		_add_box(_stool(mat), xf, s)
	if o.get("col", true):
		return _col_box(xf, s)
	return null


func _col_box(xf: Transform3D, s: Vector3) -> CollisionShape3D:
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = s
	cs.shape = bs
	cs.transform = xf
	body.add_child(cs)
	return cs


## Невидимая стена; возвращает форму, которую можно выключить (disabled = true).
func blocker(c: Vector3, s: Vector3, yaw := 0.0) -> CollisionShape3D:
	return _col_box(_xf(c, {"yaw": yaw}), s)


## Пол/плита: прямоугольник по XZ, верх на высоте y.
func slab(x0: float, z0: float, x1: float, z1: float, y: float, mat: Variant = "concrete", th := 0.5, o := {}) -> void:
	box(Vector3((x0 + x1) * 0.5, y - th * 0.5, (z0 + z1) * 0.5), Vector3(absf(x1 - x0), th, absf(z1 - z0)), mat, o)


## Стена между двумя точками по XZ: низ y0, высота h.
func wall(x0: float, z0: float, x1: float, z1: float, y0: float, h: float, mat: Variant = "plaster", th := 0.25, o := {}) -> void:
	var a := Vector2(x0, z0)
	var b := Vector2(x1, z1)
	var d := b - a
	var o2 := o.duplicate()
	o2["yaw"] = rad_to_deg(atan2(-d.y, d.x))
	var ln: float = d.length() + (0.0 if o.get("flush", false) else th)
	var cx := (x0 + x1) * 0.5
	var cz := (z0 + z1) * 0.5
	if mat is Array:
		# двухцветная стена: [низ, верх, высота границы] — как в подъездах: панель и побелка
		var split: float = minf(float(mat[2]), h)
		box(Vector3(cx, y0 + split * 0.5, cz), Vector3(ln, split, th + 0.02), mat[0], o2)
		if h > split:
			box(Vector3(cx, y0 + split + (h - split) * 0.5, cz), Vector3(ln, h - split, th), mat[1], o2)
	else:
		box(Vector3(cx, y0 + h * 0.5, cz), Vector3(ln, h, th), mat, o2)


## Стена с проёмами. gaps: [[расстояние от начала до центра проёма, ширина, высота (необязательно)], …]. Над проёмом — перемычка.
func wall_gaps(x0: float, z0: float, x1: float, z1: float, y0: float, h: float, mat: Variant, gaps: Array, th := 0.25) -> void:
	var a := Vector2(x0, z0)
	var b := Vector2(x1, z1)
	var len := (b - a).length()
	var dir := (b - a) / len
	var cuts := gaps.duplicate()
	cuts.sort_custom(func(p, q): return p[0] < q[0])
	var pos := 0.0
	for g in cuts:
		var gc: float = g[0]
		var gw: float = g[1]
		var gh: float = g[2] if g.size() > 2 else 2.2
		var s0 := gc - gw * 0.5
		if s0 > pos + 0.01:
			var p0 := a + dir * pos
			var p1 := a + dir * s0
			wall(p0.x, p0.y, p1.x, p1.y, y0, h, mat, th, {"flush": true})
		if gh < h - 0.01:
			var q0 := a + dir * s0
			var q1 := a + dir * (gc + gw * 0.5)
			var cx := (q0.x + q1.x) * 0.5
			var cz := (q0.y + q1.y) * 0.5
			box(Vector3(cx, y0 + gh + (h - gh) * 0.5, cz), Vector3(gw, h - gh, th), mat[1] if mat is Array else mat, {"yaw": rad_to_deg(atan2(-dir.y, dir.x))})
		pos = gc + gw * 0.5
	if pos < len - 0.01:
		var r0 := a + dir * pos
		wall(r0.x, r0.y, b.x, b.y, y0, h, mat, th, {"flush": true})


## Комната: четыре стены по периметру. gaps: { "n": [[x, ширина], …], "s": […], "w": [[z, ширина], …], "e": […] } — координаты проёмов мировые.
func room(x0: float, z0: float, x1: float, z1: float, y0: float, h: float, mat: Variant, gaps := {}, th := 0.25) -> void:
	var g: Array = []
	g = []
	for q in gaps.get("n", []):
		g.append([q[0] - x0, q[1]] + ([q[2]] if q.size() > 2 else []))
	wall_gaps(x0, z0, x1, z0, y0, h, mat, g, th)
	g = []
	for q in gaps.get("s", []):
		g.append([q[0] - x0, q[1]] + ([q[2]] if q.size() > 2 else []))
	wall_gaps(x0, z1, x1, z1, y0, h, mat, g, th)
	g = []
	for q in gaps.get("w", []):
		g.append([q[0] - z0, q[1]] + ([q[2]] if q.size() > 2 else []))
	wall_gaps(x0, z0, x0, z1, y0, h, mat, g, th)
	g = []
	for q in gaps.get("e", []):
		g.append([q[0] - z0, q[1]] + ([q[2]] if q.size() > 2 else []))
	wall_gaps(x1, z0, x1, z1, y0, h, mat, g, th)


## Пандус от точки a (середина нижнего края) до b (середина верхнего края).
func ramp(a: Vector3, b: Vector3, w: float, mat: Variant = "concrete", th := 0.3, o := {}) -> void:
	var d := b - a
	var basis := Basis.looking_at(d.normalized(), Vector3.UP)
	var xf := Transform3D(basis, (a + b) * 0.5 - basis.y * th * 0.5)
	var s := Vector3(w, th, d.length())
	if not o.get("hidden", false):
		_add_box(_stool(mat), xf, s)
	_col_box(xf, s)


## Лестница: видимые ступени + невидимый пандус для ходьбы.
func stairs(a: Vector3, b: Vector3, w: float, mat: Variant = "concrete", steps := 0) -> void:
	var d := b - a
	var run := Vector2(d.x, d.z).length()
	var n: int = steps if steps > 0 else maxi(2, int(round(absf(d.y) / 0.2)))
	var yaw := rad_to_deg(atan2(-d.x, -d.z))
	for i in n:
		var f0 := float(i) / n
		var f1 := float(i + 1) / n
		var top := a.y + d.y * f1
		var cx := a.x + d.x * (f0 + f1) * 0.5
		var cz := a.z + d.z * (f0 + f1) * 0.5
		var hh := absf(top - minf(a.y, b.y)) + 0.02
		box(Vector3(cx, top - hh * 0.5, cz), Vector3(w, hh, run / n + 0.01), mat, {"yaw": yaw, "col": false})
	ramp(a, b, w, mat, 0.3, {"hidden": true})


## Цилиндр (колонны, бочки, столбы).
func cyl(c: Vector3, r: float, h: float, mat: Variant = "concrete", o := {}) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = o.get("r_top", r)
	cm.bottom_radius = r
	cm.height = h
	cm.radial_segments = o.get("seg", 14)
	cm.rings = 1
	mi.mesh = cm
	mi.material_override = Mats.get_mat(mat)
	mi.position = c
	add_child(mi)
	if o.get("col", true):
		var cs := CollisionShape3D.new()
		var sh := CylinderShape3D.new()
		sh.radius = r
		sh.height = h
		cs.shape = sh
		cs.position = c
		body.add_child(cs)
	return mi


## Отдельный (не слитый) меш-коробка: то, что двигается или исчезает.
func mesh_box(s: Vector3, mat: Variant, parent: Node = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = s
	mi.mesh = bm
	mi.material_override = Mats.get_mat(mat)
	(parent if parent else self).add_child(mi)
	return mi


## Дом-коробка с окнами: c — центр основания, size — ширина (X), высота, глубина (Z). style — текстура фасада.
func building(c: Vector3, size: Vector3, style := "facade_panel", o := {}) -> void:
	var yaw: float = o.get("yaw", 0.0)
	var xf := _xf(c + Vector3(0, size.y * 0.5, 0), {"yaw": yaw})
	var night: float = o.get("lit", 0.0 if is_day else 1.6)
	var m := Mats.uv(style, style + "_e" if night > 0.0 else "", night, o.get("tint", Color.WHITE))
	var st := _stool(m)
	var h := size * 0.5
	var bay: float = o.get("bay", 12.0)      # метров на плитку текстуры (4 окна × 4 этажа)
	for f in _FACES:
		var n: Vector3 = f[0]
		if absf(n.y) > 0.5:
			continue
		var u: Vector3 = f[1]
		var v: Vector3 = f[2]
		var eu := u * absf(u.dot(h))
		var ev := v * absf(v.dot(h))
		var cc := n * h
		var reps := Vector2(maxf(1.0, round(eu.length() * 2.0 / bay * 4.0) / 4.0), maxf(0.25, round(size.y / bay * 4.0) / 4.0))
		_quad(st, xf * (cc - eu - ev), xf * (cc + eu - ev), xf * (cc + eu + ev), xf * (cc - eu + ev), xf.basis * n, reps)
	var rt := _stool(o.get("roof", "roof"))
	var top := Vector3(0, h.y, 0)
	_quad(rt, xf * (top + Vector3(-h.x, 0, h.z)), xf * (top + Vector3(h.x, 0, h.z)), xf * (top + Vector3(h.x, 0, -h.z)), xf * (top + Vector3(-h.x, 0, -h.z)), Vector3.UP, Vector2(size.x, size.z))
	if o.get("col", true):
		_col_box(xf, size)
	if o.get("parapet", true):
		for sgn in [-1.0, 1.0]:
			box(c + Vector3(0, size.y + 0.25, 0) + xf.basis * Vector3(0, 0, sgn * (h.z - 0.1)), Vector3(size.x, 0.5, 0.2), "concrete_dark", {"yaw": yaw, "col": false})
			box(c + Vector3(0, size.y + 0.25, 0) + xf.basis * Vector3(sgn * (h.x - 0.1), 0, 0), Vector3(0.2, 0.5, size.z), "concrete_dark", {"yaw": yaw, "col": false})


# ---------- модели окружения ----------

static func prop_scene(key: String) -> PackedScene:
	if not _scn.has(key):
		_scn[key] = load("res://assets/props/%s.glb" % key)
	return _scn[key]


static func prop_aabb(key: String) -> AABB:
	if _aabb.has(key):
		return _aabb[key]
	var n: Node3D = prop_scene(key).instantiate()
	var out := AABB()
	var first := true
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var a: AABB = Model._xf_to(mi, n) * (mi as MeshInstance3D).get_aabb()
		out = a if first else out.merge(a)
		first = false
	n.free()
	_aabb[key] = out
	return out


## Модель из assets/props: key вида "home/Bed_Bunk". yaw — градусы; sc — число или Vector3.
## o: col ("box", "trunk", "none"), r (радиус ствола), parent, h (подогнать высоту в метрах), w (подогнать ширину).
func prop(key: String, pos: Vector3, yaw := 0.0, sc: Variant = 1.0, o := {}) -> Node3D:
	var n: Node3D = prop_scene(key).instantiate()
	var a := prop_aabb(key)
	var s: Vector3 = sc if sc is Vector3 else Vector3.ONE * float(sc)
	if o.has("h"):
		s = Vector3.ONE * (float(o["h"]) / maxf(a.size.y, 0.001))
	elif o.has("w"):
		s = Vector3.ONE * (float(o["w"]) / maxf(maxf(a.size.x, a.size.z), 0.001))
	n.scale = s
	n.rotation.y = deg_to_rad(yaw)
	n.position = pos - (Vector3(0, a.position.y * s.y, 0) if o.get("ground", true) else Vector3.ZERO)
	var parent: Node = o.get("parent", self)
	parent.add_child(n)
	var col: String = o.get("col", Props.col_for(key))
	if col == "box":
		var cen := (a.position + a.size * 0.5) * s
		var xf := Transform3D(Basis.from_euler(Vector3(0, deg_to_rad(yaw), 0)), n.position) * Transform3D(Basis.IDENTITY, cen)
		_col_box(xf, a.size * s)
	elif col == "trunk":
		var cs := CollisionShape3D.new()
		var sh := CylinderShape3D.new()
		sh.radius = o.get("r", maxf(0.18, minf(a.size.x, a.size.z) * s.x * 0.09))
		sh.height = a.size.y * s.y
		cs.shape = sh
		cs.position = pos + Vector3(0, sh.height * 0.5, 0)
		body.add_child(cs)
	return n


## Разбросать модели по кругу: keys — варианты, n — сколько. o: sc [мин, макс], avoid [[Vector3, радиус], …], col, seed.
func scatter(keys: Array, center: Vector3, radius: float, n: int, o := {}) -> void:
	var sc: Array = o.get("sc", [0.9, 1.2])
	var avoid: Array = o.get("avoid", [])
	var tries := 0
	var placed := 0
	while placed < n and tries < n * 12:
		tries += 1
		var ang := rng.randf() * TAU
		var rr := sqrt(rng.randf()) * radius
		var p := center + Vector3(cos(ang) * rr, 0, sin(ang) * rr)
		if o.has("rect"):
			var rc: Rect2 = o["rect"]
			p = Vector3(rc.position.x + rng.randf() * rc.size.x, center.y, rc.position.y + rng.randf() * rc.size.y)
		var ok := true
		for av in avoid:
			var ap: Vector3 = av[0]
			if Vector2(p.x - ap.x, p.z - ap.z).length() < float(av[1]):
				ok = false
				break
		if o.has("avoid_rects"):
			for rc2 in o["avoid_rects"]:
				if (rc2 as Rect2).has_point(Vector2(p.x, p.z)):
					ok = false
					break
		if not ok:
			continue
		var key: String = keys[rng.randi() % keys.size()]
		var o2 := {}
		if o.has("col"):
			o2["col"] = o["col"]
		prop(key, p, rng.randf() * 360.0, lerpf(sc[0], sc[1], rng.randf()) * float(o.get("mul", 1.0)), o2)
		placed += 1


# ---------- текст и свет ----------

## Надпись в мире. yaw 0 — смотрит на юг (+Z). h — высота строки в метрах. o: col, glow (множитель яркости), outline, dbl, w (ширина переноса).
func txt(text: String, pos: Vector3, yaw := 0.0, h := 0.5, o := {}) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font = UI.font_big() if o.get("big", true) else UI.font_text()
	l.font_size = 72
	l.pixel_size = h / 72.0
	var c: Color = o.get("col", Color.WHITE)
	var gl: float = o.get("glow", 0.0)
	l.modulate = Color(c.r * (1.0 + gl), c.g * (1.0 + gl), c.b * (1.0 + gl), c.a) if gl > 0.0 else c
	l.outline_size = o.get("outline", 10)
	l.outline_modulate = o.get("ocol", Color(0, 0, 0, 0.9))
	l.position = pos
	l.rotation.y = deg_to_rad(yaw)
	l.rotation.x = deg_to_rad(o.get("pitch", 0.0))
	l.double_sided = o.get("dbl", false)
	l.shaded = false
	l.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if o.has("w"):
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.width = float(o["w"]) / l.pixel_size
	(o.get("parent", self) as Node).add_child(l)
	return l


## Табличка: плоская доска с текстом.
func board(text: String, pos: Vector3, yaw: float, w: float, h: float, o := {}) -> void:
	var b := Basis.from_euler(Vector3(0, deg_to_rad(yaw), 0))
	box(pos, Vector3(w, h, 0.08), o.get("bg", Color(0.1, 0.1, 0.12)), {"yaw": yaw, "col": false})
	var lines := text.count("\n") + 1
	var o2 := o.duplicate()
	if not o2.has("outline"):
		o2["outline"] = 0
	txt(text, pos + b * Vector3(0, 0, 0.05), yaw, minf(h * 0.8 / lines, o.get("th", 9.0)), o2)


## Источник света (берётся из пула ближайших к игроку). energy ~1..4, range в метрах.
func lamp(pos: Vector3, col := Color(1.0, 0.86, 0.62), energy := 2.2, lrange := 9.0) -> Dictionary:
	var d := {"pos": pos, "col": col, "e": energy, "r": lrange, "on": false, "off": false}
	_lamps.append(d)
	return d


## Потолочный светильник: плафон + свет.
func ceil_lamp(pos: Vector3, col := Color(1.0, 0.9, 0.7), energy := 2.0, lrange := 8.0) -> Dictionary:
	box(pos + Vector3(0, -0.06, 0), Vector3(0.5, 0.1, 0.5), Mats.glow(col, 2.2), {"col": false})
	return lamp(pos + Vector3(0, -0.5, 0), col, energy, lrange)


## Уличный фонарь.
func post(pos: Vector3, yaw := 0.0, col := Color(1.0, 0.78, 0.45)) -> void:
	prop("street/Streetlight_Single", pos, yaw, 1.0, {"h": 5.2, "col": "trunk", "r": 0.16})
	if not is_day:
		lamp(pos + Vector3(0, 4.6, 0), col, 3.0, 13.0)
		var g := mesh_box(Vector3(0.34, 0.34, 0.34), Mats.glow(col, 3.0))
		g.position = pos + Vector3(0, 4.75, 0)


func _update_lamps(dt: float) -> void:
	if _lamps.is_empty() or _pool.is_empty():
		return
	_lamp_t -= dt
	if _lamp_t <= 0.0:
		_lamp_t = 0.25
		var focus: Vector3 = G.player.global_position if G.player else Vector3.ZERO
		var cand: Array = []
		for lp in _lamps:
			if not lp["off"]:
				lp["d"] = (lp["pos"] as Vector3).distance_squared_to(focus)
				cand.append(lp)
		cand.sort_custom(func(a, b): return a["d"] < b["d"])
		var want := {}
		for i in mini(cand.size(), _pool.size()):
			want[cand[i]] = true
		for e in _pool:
			if e["lamp"] != null and not want.has(e["lamp"]):
				e["fade"] = true
		for lp in want:
			if lp["on"]:
				continue
			for e in _pool:
				if e["lamp"] == null:
					e["lamp"] = lp
					e["fade"] = false
					e["w"] = 0.0
					lp["on"] = true
					var l: OmniLight3D = e["l"]
					l.position = lp["pos"]
					l.light_color = lp["col"]
					l.omni_range = lp["r"]
					break
	for e in _pool:
		if e["lamp"] == null:
			continue
		var lp2: Dictionary = e["lamp"]
		if e.get("fade", false) or lp2["off"]:
			e["w"] = maxf(0.0, float(e["w"]) - dt * 4.0)
			if float(e["w"]) <= 0.0:
				lp2["on"] = false
				e["lamp"] = null
				(e["l"] as OmniLight3D).light_energy = 0.0
				continue
		else:
			e["w"] = minf(1.0, float(e["w"]) + dt * 3.0)
		(e["l"] as OmniLight3D).light_energy = float(lp2["e"]) * float(e["w"])


# ---------- игровые объекты ----------

func cp(nm: String, pos: Vector3, yaw := 0.0) -> void:
	cps[nm] = [pos, deg_to_rad(yaw)]


## Точка взаимодействия. fn — что делать (может быть корутиной). o: cond (Callable -> bool), node (следовать за узлом).
func interact(pos: Vector3, r: float, label: String, fn: Callable, o := {}) -> Dictionary:
	var d := {"pos": pos, "r": r, "label": label, "fn": fn, "off": false}
	for k in o:
		d[k] = o[k]
	inter.append(d)
	return d


## Зона-триггер: срабатывает, когда игрок внутри коробки (pos ± half).
func trigger(pos: Vector3, half: Vector3, fn: Callable, once := true, cond: Variant = null) -> Dictionary:
	var d := {"pos": pos, "half": half, "fn": fn, "once": once, "done": false}
	if cond != null:
		d["cond"] = cond
	trigs.append(d)
	return d


## Зона с постоянным эффектом: fn(dt) зовётся каждый кадр, пока игрок внутри.
func zone(pos: Vector3, half: Vector3, fn: Callable) -> Dictionary:
	var d := {"pos": pos, "half": half, "fn": fn}
	zones.append(d)
	return d


func tick(fn: Callable) -> void:
	ticks.append(fn)


func npc(cast: Variant, pos: Vector3, yaw := 0.0, o := {}) -> Npc:
	var n := Npc.new()
	n.init(cast, o)
	add_child(n)
	n.global_position = pos
	n.set_yaw(deg_to_rad(yaw))
	if o.has("talk"):
		var lbl: String = o.get("label", "Поговорить")
		n.it = interact(pos + Vector3(0, 0.9, 0), o.get("r", 2.4), lbl, n.talk, {"node": n})
	return n


func enemy(kind: String, pos: Vector3, o := {}) -> Enemy:
	var e := Enemy.new()
	e.init(kind, o)
	add_child(e)
	e.global_position = pos
	e.home = pos
	return e


func pickup(item: String, pos: Vector3, n := 1, o := {}) -> Pickup:
	var p := Pickup.new()
	p.init(item, n, o)
	add_child(p)
	p.global_position = pos
	return p


func cash(pos: Vector3, amount: int, o := {}) -> Pickup:
	return pickup("cash", pos, amount, o)


func crate(pos: Vector3, loot: Array = [], o := {}) -> Crate:
	var c := Crate.new()
	c.init(loot, o)
	add_child(c)
	c.global_position = pos
	return c


func door(pos: Vector3, yaw := 0.0, o := {}) -> Door:
	var d := Door.new()
	add_child(d)
	d.global_position = pos
	d.rotation.y = deg_to_rad(yaw)
	d.init(self, o)
	return d


# ---------- сценки ----------

## Выполнить корутину как сценку: управление блокируется, диалоги идут.
func cut(fn: Callable) -> void:
	G.cut_begin()
	await fn.call()
	G.cut_end()


func say(lines: Array) -> void:
	await G.ui.say(lines)


func title_card() -> void:
	if title != "":
		G.ui.big_title(title, chapter)
