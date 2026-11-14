class_name Npc
extends Node3D
## Персонаж для разговоров: стоит (или сидит), поворачивается к игроку, по кнопке действия запускает диалог.

var model: Model
var cast_id := ""
var cname := ""
var solid := true
var it: Dictionary
var talk_fn: Callable
var base_yaw := 0.0
var yaw := 0.0
var look_at_player := true
var anim := "Idle"
var mark: Label3D
var walking := false
var height := 1.8


func init(cast: Variant, o := {}) -> void:
	var look: Dictionary = {}
	if cast is String:
		cast_id = cast
		cname = Cast.name_of(cast)
		look = Cast.look_of(cast)
	else:
		look = cast
	cname = o.get("name", cname)
	if o.has("creature"):
		model = Model.creature(o["creature"], o.get("size", 1.0), o.get("colors", {}))
	else:
		model = Model.human(look)
	add_child(model)
	anim = o.get("anim", "Idle")
	model.play(anim, 0.0)
	model.ap.seek(randf() * 1.5, true)
	if o.has("talk"):
		talk_fn = o["talk"]
	solid = o.get("solid", true)
	look_at_player = o.get("look", anim in ["Idle", "Idle_Neutral", "idle"])
	if o.has("mark"):
		set_mark(o["mark"])


func set_yaw(y: float) -> void:
	yaw = y
	base_yaw = y
	if model:
		model.rotation.y = y


func set_mark(ch: String) -> void:
	if ch == "":
		if mark:
			mark.visible = false
		return
	if mark == null:
		mark = Label3D.new()
		mark.font = UI.font_big()
		mark.font_size = 96
		mark.pixel_size = 0.006
		mark.modulate = Color(1.0, 0.82, 0.12)
		mark.outline_size = 16
		mark.outline_modulate = Color(0, 0, 0, 1)
		mark.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		mark.position.y = height + 0.55
		add_child(mark)
	mark.text = ch
	mark.visible = true


func talk() -> void:
	if not talk_fn.is_valid():
		return
	G.cut_begin()
	if look_at_player and G.player:
		yaw = Actor.yaw_to(global_position, G.player.global_position)
		G.player.face(global_position)
	await talk_fn.call()
	G.cut_end()


func play(a: String, blend := 0.2) -> void:
	anim = a
	model.play(a, blend)


func _process(dt: float) -> void:
	if mark and mark.visible:
		mark.position.y = height + 0.55 + sin(Time.get_ticks_msec() * 0.004) * 0.06
	if walking or not look_at_player or G.player == null:
		model.rotation.y = lerp_angle(model.rotation.y, yaw, clampf(8.0 * dt, 0.0, 1.0))
		return
	var d := G.player.global_position.distance_to(global_position)
	var want := base_yaw
	if d < 5.0 and G.mode in ["play", "cut"]:
		want = Actor.yaw_to(global_position, G.player.global_position)
	yaw = lerp_angle(yaw, want, clampf(5.0 * dt, 0.0, 1.0))
	model.rotation.y = yaw


## Пройти к точке (для сценок): await npc.walk_to(...)
func walk_to(pos: Vector3, speed := 3.0, run := false) -> void:
	walking = true
	model.play("Run" if run else "Walk", 0.2, 1.0 if run else clampf(speed / 1.5, 0.8, 1.8))
	while is_inside_tree() and Vector2(pos.x - global_position.x, pos.z - global_position.z).length() > 0.2:
		var d := pos - global_position
		d.y = 0.0
		var step := d.normalized() * speed * get_physics_process_delta_time()
		global_position += step
		global_position.y = move_toward(global_position.y, pos.y, 4.0 * get_physics_process_delta_time())
		yaw = Actor.yaw_to(global_position, pos)
		await get_tree().physics_frame
	walking = false
	base_yaw = yaw
	model.play(anim, 0.2)
