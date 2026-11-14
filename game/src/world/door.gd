class_name Door
extends Node3D
## Дверь на петлях. o: w, h, mat, label, locked (Callable -> String: причина, "" — открыто),
## on_open (Callable), auto (сама открывается при подходе), dir (в какую сторону распахивается: 1 / -1).

var is_open := false
var w := 1.0
var h := 2.1
var pivot: Node3D
var col: CollisionShape3D
var it: Dictionary
var locked: Callable
var on_open: Callable
var dir := 1.0
var auto := false
var lvl: Level


func init(level: Level, o := {}) -> void:
	lvl = level
	w = o.get("w", 1.0)
	h = o.get("h", 2.1)
	dir = o.get("dir", 1.0)
	auto = o.get("auto", false)
	if o.has("locked"):
		locked = o["locked"]
	if o.has("on_open"):
		on_open = o["on_open"]
	pivot = Node3D.new()
	pivot.position = Vector3(-w * 0.5, 0, 0)
	add_child(pivot)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(w, h, 0.08)
	mi.mesh = bm
	mi.material_override = Mats.get_mat(o.get("mat", "wood_dark"))
	mi.position = Vector3(w * 0.5, h * 0.5, 0)
	pivot.add_child(mi)
	var knob := MeshInstance3D.new()
	var km := BoxMesh.new()
	km.size = Vector3(0.06, 0.16, 0.16)
	knob.mesh = km
	knob.material_override = Mats.get_mat("gold")
	knob.position = Vector3(w - 0.12, h * 0.48, 0)
	pivot.add_child(knob)
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	col = CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(w, h, 0.2)
	col.shape = bs
	col.position = Vector3(0, h * 0.5, 0)
	body.add_child(col)
	var label: String = o.get("label", "Открыть")
	if not auto and label != "":
		it = level.interact(global_position + Vector3(0, 1.0, 0), o.get("r", 2.0), label, use, {"cond": func(): return not is_open})


func _physics_process(_dt: float) -> void:
	if auto and not is_open and G.player and G.mode == "play":
		if G.player.global_position.distance_to(global_position) < 2.4 and absf(G.player.global_position.y - global_position.y) < 2.0:
			if not locked.is_valid() or String(locked.call()) == "":
				set_open(true)


func use() -> void:
	if locked.is_valid():
		var why := String(locked.call())
		if why != "":
			G.toast(why, "small")
			Snd.sfx("deny", -5.0)
			return
	set_open(true)
	if on_open.is_valid():
		on_open.call()


func set_open(v: bool, instant := false) -> void:
	if is_open == v:
		return
	is_open = v
	col.set_deferred("disabled", v)
	var ang := deg_to_rad(100.0) * dir if v else 0.0
	if instant:
		pivot.rotation.y = ang
	else:
		Snd.sfx("door", -6.0)
		create_tween().tween_property(pivot, "rotation:y", ang, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
