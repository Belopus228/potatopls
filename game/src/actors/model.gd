class_name Model
extends Node3D
## Обёртка над импортированной моделью: скелет, анимации, перекраска, вспышка при ударе.
##
## Люди (Quaternius Ultimate Modular Men / Women) делят одну библиотеку анимаций на риг;
## к 24 клипам из набора добавляются позы, собранные кодом (сидеть, прыжок, падение, танец, крик).
## Существа играют свои клипы; обращение идёт по смыслу: play("idle"), play("attack")…

const MELLSTROY_SCENE := "res://assets/chars/mellstroy.glb"
const _Retarget := preload("res://src/actors/retarget.gd")
const RIGS := {
	"men": {"anims": "res://assets/chars/men_anims.glb", "dir": "res://assets/chars/men/"},
	"women": {"anims": "res://assets/chars/women_anims.glb", "dir": "res://assets/chars/women/"},
}
## смысл -> варианты имён клипов (первый найденный)
const SEM := {
	"idle": ["Idle", "Flying_Idle", "Flying"],
	"walk": ["Walk", "Flying_Idle", "Flying", "Run"],
	"run": ["Run", "Gallop", "Fast_Flying", "Walk", "Flying"],
	"attack": ["Attack", "Bite_Front", "Punch", "Headbutt", "Attack_Headbutt", "Punch_Right"],
	"attack2": ["Kick", "Weapon", "Bite_InPlace", "Attack_Kick", "SwordSlash", "Kick_Right", "Attack", "Punch", "Bite_Front", "Headbutt"],
	"shoot": ["Shoot", "Gun_Shoot", "Attack", "Punch", "Bite_Front"],
	"hit": ["HitRecieve", "HitReact", "HitRecieve_1", "Idle_HitReact_Left"],
	"death": ["Death", "Dead"],
	"jump": ["Jump", "Gallop_Jump", "Flying"],
	"dance": ["Dance", "Yes", "Wave", "Eating"],
	"yes": ["Yes", "Wave", "Hello"],
	"no": ["No"],
	"eat": ["Eating", "Idle_Headlow", "Idle"],
}
const LOOPING := ["Idle", "Idle_2", "Idle_Neutral", "Idle_Gun", "Idle_Gun_Pointing", "Idle_Sword", "Idle_Headlow", "Walk", "Run", "Run_Back", "Run_Left", "Run_Right",
	"Run_Shoot", "Gallop", "Flying", "Flying_Idle", "Fast_Flying", "Dance", "Eating", "Sit", "Fall", "Shout", "Cheer", "Jump_Idle", "Lie", "Squat", "Steam"]

static var _libs := {}          # ключ -> AnimationLibrary
static var _mat_cache := {}     # "путь материала|цвет" -> Material
static var _flash_mat: StandardMaterial3D

var scene: Node3D
var skel: Skeleton3D
var ap: AnimationPlayer
var cur := ""
var meshes: Array[MeshInstance3D] = []
var _flash_t := 0.0
var _sem_cache := {}


## Человек. look: { rig = "mellstroy" | "men" | "women", body = "casual", colors = { … }, scale = 1.0 }
static func human(look: Dictionary) -> Model:
	var m := Model.new()
	var rig: String = look.get("rig", "men")
	if rig == "mellstroy" and ResourceLoader.exists(MELLSTROY_SCENE):
		var ps_m: PackedScene = load(MELLSTROY_SCENE)
		m._setup_mellstroy(ps_m.instantiate(), look)
	else:
		var use_rig := rig if RIGS.has(rig) else "men"
		var ps: PackedScene = load(RIGS[use_rig]["dir"] + String(look.get("body", "casual")) + ".glb")
		m._setup(ps.instantiate(), "rig:" + use_rig, RIGS[use_rig]["anims"], true)
		if look.has("colors"):
			m.recolor(look["colors"])
	if look.has("scale"):
		m.scale = Vector3.ONE * float(look["scale"])
	return m


func _setup_mellstroy(inst: Node3D, look: Dictionary) -> void:
	scene = inst
	# В Sketchfab-сцене корень mellstroy_FBX имеет масштаб 0.0254 (дюймы -> метры),
	# а после скининга модель уже смотрит вдоль -Z и имеет рост 1.833 м (низ стоп y = -1.018).
	var k := 1.80 / 1.833
	scene.scale = Vector3.ONE * (k / 0.0254)
	scene.rotation = Vector3.ZERO
	scene.position = Vector3(-0.031 * k, 1.038 * k, 0.0)
	add_child(scene)
	skel = scene.find_child("Skeleton3D", true, false)
	for n in scene.find_children("*", "MeshInstance3D", true, false):
		meshes.append(n)
	var own: AnimationPlayer = scene.find_child("AnimationPlayer", true, false)
	if own:
		own.name = "SrcAnim"
		own.queue_free()
	if not _libs.has("rig:men"):
		var tmp_men := Model.new()
		var ps_men: PackedScene = load(RIGS["men"]["dir"] + "casual.glb")
		tmp_men._setup(ps_men.instantiate(), "rig:men", RIGS["men"]["anims"], true)
		tmp_men.free()
	if not _libs.has("rig:mellstroy"):
		_libs["rig:mellstroy"] = _Retarget.build_mellstroy_lib(_libs["rig:men"], self, skel, scene)
	_tune_mellstroy_mats(look)
	ap = AnimationPlayer.new()
	ap.name = "Anim"
	scene.add_child(ap)
	ap.add_animation_library("", _libs["rig:mellstroy"])
	ap.playback_default_blend_time = 0.15


func _tune_mellstroy_mats(look: Dictionary) -> void:
	var shirt_mod: Color = look.get("shirt_mod", Color.WHITE)
	var pants_mod: Color = look.get("pants_mod", Color.WHITE)
	for mi in meshes:
		if mi.mesh == null:
			continue
		var mname := String(mi.name)
		for i in mi.mesh.get_surface_count():
			var base: Material = mi.mesh.surface_get_material(i)
			if not (base is StandardMaterial3D):
				continue
			var m2: StandardMaterial3D = (base as StandardMaterial3D).duplicate()
			m2.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			m2.roughness = 0.76
			if mname == "Object_42": # корпус и браслет часов
				m2.metallic = 0.55
				m2.roughness = 0.28
			elif mname == "Object_43": # циферблат часов
				m2.roughness = 0.22
			elif mname == "Object_46": # кроссовки
				m2.roughness = 0.58
			elif mname == "Object_38": # торс / футболка
				m2.albedo_color = shirt_mod
				m2.roughness = 0.80
			elif mname == "Object_41": # штаны
				m2.albedo_color = pants_mod
				m2.roughness = 0.82
			elif mname == "Object_44": # голова и волосы
				m2.roughness = 0.68
			mi.set_surface_override_material(i, m2)


## Существо из res://assets/creatures/<name>.glb. size — желаемая высота в метрах (0 — как в файле).
static func creature(cname: String, size := 0.0, colors := {}) -> Model:
	var m := Model.new()
	var path := "res://assets/creatures/%s.glb" % cname
	var ps: PackedScene = load(path)
	m._setup(ps.instantiate(), "c:" + cname, "", false)
	if size > 0.0:
		var h: float = max(m.bounds().size.y, 0.01)
		m.scene.scale *= size / h
	if not colors.is_empty():
		m.recolor(colors)
	return m


func _setup(inst: Node3D, lib_key: String, anim_src: String, is_human: bool) -> void:
	scene = inst
	add_child(scene)
	scene.rotation.y = PI            # модели смотрят в +Z, у нас «вперёд» — это -Z
	skel = scene.find_child("Skeleton3D", true, false)
	for n in scene.find_children("*", "MeshInstance3D", true, false):
		meshes.append(n)
	var own: AnimationPlayer = scene.find_child("AnimationPlayer", true, false)
	if not _libs.has(lib_key):
		_libs[lib_key] = _build_lib(own, anim_src, is_human)
	if own:
		own.name = "SrcAnim"
		own.queue_free()
	ap = AnimationPlayer.new()
	ap.name = "Anim"
	scene.add_child(ap)
	ap.add_animation_library("", _libs[lib_key])
	ap.playback_default_blend_time = 0.15


func _build_lib(own: AnimationPlayer, anim_src: String, is_human: bool) -> AnimationLibrary:
	var lib := AnimationLibrary.new()
	var src := own
	var tmp: Node = null
	if src == null and anim_src != "":
		tmp = (load(anim_src) as PackedScene).instantiate()
		src = tmp.find_child("AnimationPlayer", true, false)
	if src:
		for full in src.get_animation_list():
			var a: Animation = src.get_animation(full)
			var nm := String(full).get_slice("|", String(full).get_slice_count("|") - 1)
			for pre in ["Rat_", "Spider_", "Wasp_", "Frog_", "Snake_"]:
				if nm.begins_with(pre):
					nm = nm.substr(pre.length())
			a.loop_mode = Animation.LOOP_LINEAR if nm in LOOPING else Animation.LOOP_NONE
			if not lib.has_animation(nm):
				lib.add_animation(nm, a)
	if is_human and skel:
		Poses.add_human_clips(lib, scene, skel)
	if tmp:
		tmp.free()
	return lib


func has(nm: String) -> bool:
	return ap.has_animation(nm) or SEM.has(nm)


## Имя клипа по смыслу ("attack") или точное имя ("Punch_Left").
func clip(nm: String) -> String:
	if ap.has_animation(nm):
		return nm
	if _sem_cache.has(nm):
		return _sem_cache[nm]
	var res := ""
	for c in SEM.get(nm, []):
		if ap.has_animation(c):
			res = c
			break
	_sem_cache[nm] = res
	return res


func play(nm: String, blend := 0.15, speed := 1.0, restart := false) -> float:
	var c := clip(nm)
	if c == "":
		return 0.0
	if cur == c and not restart and ap.is_playing():
		ap.speed_scale = speed
		return ap.current_animation_length / max(speed, 0.01)
	cur = c
	ap.play(c, blend, speed)
	if restart:
		ap.seek(0.0, true)
	return ap.get_animation(c).length / max(speed, 0.01)


func length(nm: String) -> float:
	var c := clip(nm)
	return ap.get_animation(c).length if c != "" else 0.0


func playing() -> bool:
	return ap.is_playing()


## Перекраска по именам материалов из файла: { "White": Color(...), "Skin": Color(...) }
func recolor(colors: Dictionary) -> void:
	for mi in meshes:
		for i in mi.mesh.get_surface_count():
			var base: Material = mi.mesh.surface_get_material(i)
			if base == null or not colors.has(base.resource_name):
				continue
			var col: Color = colors[base.resource_name]
			var key := "%s|%s|%s" % [mi.mesh.resource_path, base.resource_name, col.to_html()]
			if not _mat_cache.has(key):
				var m2: StandardMaterial3D = base.duplicate()
				m2.albedo_color = col
				if col.a < 0.999:
					m2.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				_mat_cache[key] = m2
			mi.set_surface_override_material(i, _mat_cache[key])


## Свечение всей модели (тёмный Друн, призраки): energy 0 — выключить.
func set_emission(col: Color, energy: float) -> void:
	for mi in meshes:
		for i in mi.mesh.get_surface_count():
			var m: Material = mi.get_surface_override_material(i)
			if m == null:
				m = mi.mesh.surface_get_material(i)
			if m is StandardMaterial3D:
				var m2: StandardMaterial3D = m.duplicate()
				m2.emission_enabled = energy > 0.0
				m2.emission = col
				m2.emission_energy_multiplier = energy
				mi.set_surface_override_material(i, m2)


func set_alpha(a: float) -> void:
	for mi in meshes:
		mi.transparency = clampf(1.0 - a, 0.0, 1.0)


## Короткая белая вспышка (попадание).
func flash(col := Color(1, 1, 1), strength := 0.75) -> void:
	if _flash_mat == null:
		_flash_mat = StandardMaterial3D.new()
		_flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_flash_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var fm: StandardMaterial3D = _flash_mat.duplicate()
	fm.albedo_color = Color(col.r, col.g, col.b, strength)
	for mi in meshes:
		mi.material_overlay = fm
	_flash_t = 0.12
	set_process(true)


func _process(dt: float) -> void:
	if _flash_t > 0.0:
		_flash_t -= dt
		if _flash_t <= 0.0:
			for mi in meshes:
				mi.material_overlay = null


func bounds() -> AABB:
	var out := AABB()
	var first := true
	for mi in meshes:
		var xf := _xf_to(mi, self)
		var a: AABB = xf * mi.get_aabb()
		if mi.skin and skel:      # у скиновых мешей AABB в пространстве скелета неточен — берём по костям
			a = _skel_bounds()
		if first:
			out = a
			first = false
		else:
			out = out.merge(a)
	return out


func _skel_bounds() -> AABB:
	var xf := _xf_to(skel, self)
	var out := AABB(xf * skel.get_bone_global_rest(0).origin, Vector3.ZERO)
	for i in skel.get_bone_count():
		out = out.expand(xf * skel.get_bone_global_rest(i).origin)
	return out.grow(0.08)


static func _xf_to(n: Node3D, top: Node3D) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var c: Node = n
	while c != top and c != null:
		if c is Node3D:
			xf = (c as Node3D).transform * xf
		c = c.get_parent()
	return xf


## Точка крепления к кости: узел, внутри которого метры и оси модели (Y — вдоль кости).
func attach(bone: String) -> Node3D:
	if skel != null and skel.find_bone(bone) < 0 and _Retarget.ATTACH_ALIASES.has(bone):
		bone = _Retarget.ATTACH_ALIASES[bone]
	var ba := BoneAttachment3D.new()
	ba.bone_name = bone
	skel.add_child(ba)
	var fix := Node3D.new()
	var s: Vector3 = _xf_to(skel, self).basis.get_scale()
	fix.scale = Vector3.ONE / s
	ba.add_child(fix)
	return fix


## Спрятать часть модели: кости с этим префиксом сжимаются в точку (лишняя пара лап у «таракана»).
func hide_bones(prefixes: Array) -> void:
	for i in skel.get_bone_count():
		var bn := skel.get_bone_name(i)
		for p in prefixes:
			if bn.begins_with(p):
				skel.set_bone_pose_scale(i, Vector3.ONE * 0.001)
