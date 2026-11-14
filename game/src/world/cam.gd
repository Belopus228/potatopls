class_name CamRig
extends Node3D
## Камера от третьего лица: вращение мышью/стиком/пальцем, пружина от стен, тряска, кадры для сценок.

var yaw := 0.0
var pitch := -0.3
var dist := 5.6
var arm: SpringArm3D
var cam: Camera3D
var cine: Camera3D
var focus := Vector3.ZERO
var shake_amt := 0.0
var in_shot := false
var idle_t := 0.0
var _shot_tw: Tween


func _ready() -> void:
	name = "Cam"
	process_mode = Node.PROCESS_MODE_ALWAYS
	arm = SpringArm3D.new()
	var sh := SphereShape3D.new()
	sh.radius = 0.22
	arm.shape = sh
	arm.collision_mask = 1
	arm.margin = 0.12
	arm.spring_length = dist
	add_child(arm)
	cam = Camera3D.new()
	cam.fov = 64.0
	cam.near = 0.12
	cam.far = 500.0
	arm.add_child(cam)
	cam.current = true
	cine = Camera3D.new()
	cine.fov = 50.0
	cine.near = 0.12
	cine.far = 500.0
	cine.top_level = true
	add_child(cine)


func _unhandled_input(e: InputEvent) -> void:
	if G.mode != "play":
		return
	if e is InputEventMouseMotion and not G.touch:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or (e as InputEventMouseMotion).button_mask & MOUSE_BUTTON_MASK_RIGHT:
			var r: Vector2 = (e as InputEventMouseMotion).relative
			_rotate(r * 0.0032 * float(G.settings["sens"]))
	elif e is InputEventMouseButton and e.pressed:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP:
			dist = maxf(2.8, dist - 0.5)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			dist = minf(9.0, dist + 0.5)


func _rotate(d: Vector2) -> void:
	yaw = wrapf(yaw - d.x, -PI, PI)
	pitch = clampf(pitch - d.y * (-1.0 if G.settings["inv_y"] else 1.0), -1.25, 0.55)
	idle_t = 0.0


func _process(dt: float) -> void:
	var p := G.player
	if p == null:
		return
	if G.mode == "play":
		if Inp.look != Vector2.ZERO:
			_rotate(Inp.look * 0.0052 * float(G.settings["sens"]))
		var s := Inp.stick_look()
		if s != Vector2.ZERO:
			_rotate(s * dt * 2.8 * float(G.settings["sens"]))
		# без мыши камера сама доворачивается за спину при ходьбе
		idle_t += dt
		if (G.touch or Inp.last_device == "pad") and idle_t > 1.2:
			var hv := Vector2(p.velocity.x, p.velocity.z)
			if hv.length() > 2.0:
				var want := atan2(-hv.x, -hv.y)
				var diff := wrapf(want - yaw, -PI, PI)
				if absf(diff) < 2.4:
					yaw = wrapf(yaw + diff * clampf(1.1 * dt, 0.0, 1.0), -PI, PI)
	Inp.look = Vector2.ZERO
	var tgt := p.global_position + Vector3(0, 1.5, 0)
	focus = focus.lerp(tgt, 1.0 - exp(-dt * 14.0))
	if focus.distance_to(tgt) > 6.0:
		focus = tgt
	global_position = focus
	arm.rotation = Vector3(pitch, yaw, 0)
	arm.spring_length = lerpf(arm.spring_length, dist, 1.0 - exp(-dt * 8.0))
	if shake_amt > 0.001 and G.settings["shake"]:
		cam.h_offset = randf_range(-1, 1) * shake_amt * 0.35
		cam.v_offset = randf_range(-1, 1) * shake_amt * 0.35
		shake_amt = maxf(0.0, shake_amt - dt * 1.8)
	else:
		cam.h_offset = 0.0
		cam.v_offset = 0.0
		shake_amt = 0.0


func shake(a: float) -> void:
	shake_amt = minf(1.0, maxf(shake_amt, a))


func snap() -> void:
	var p := G.player
	if p:
		focus = p.global_position + Vector3(0, 1.5, 0)
		yaw = p.yaw
		pitch = -0.3
		global_position = focus
		arm.rotation = Vector3(pitch, yaw, 0)
	end_shot()


## Кадр для сценки: камера в точке pos смотрит на look. time > 0 — плавный наезд из предыдущего кадра.
func shot(pos: Vector3, look: Vector3, fov := 50.0, time := 0.0) -> void:
	var xf := Transform3D(Basis.IDENTITY, pos).looking_at(look, Vector3.UP)
	if _shot_tw:
		_shot_tw.kill()
	if not in_shot:
		cine.global_transform = cam.global_transform if time > 0.0 else xf
		cine.fov = cam.fov if time > 0.0 else fov
	in_shot = true
	cine.current = true
	if time > 0.0:
		_shot_tw = create_tween().set_parallel(true)
		_shot_tw.tween_property(cine, "global_transform", xf, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_shot_tw.tween_property(cine, "fov", fov, time)
	else:
		cine.global_transform = xf
		cine.fov = fov


func end_shot() -> void:
	if _shot_tw:
		_shot_tw.kill()
	in_shot = false
	cam.current = true


func cam_pos() -> Vector3:
	return cine.global_position if in_shot else cam.global_position


func active() -> Camera3D:
	return cine if in_shot else cam
