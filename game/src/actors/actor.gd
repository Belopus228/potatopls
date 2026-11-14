class_name Actor
extends CharacterBody3D
## Общее для игрока и существ: модель, здоровье, поворот, отталкивание.

var model: Model
var hp := 100.0
var hp_max := 100.0
var dead := false
var radius := 0.4
var height := 1.8
var yaw := 0.0                  # куда смотрит (вокруг Y); 0 — на север (-Z)
var gravity := 26.0
var blob: MeshInstance3D            # мягкая тень-пятно под ногами: без неё герой «висит» над полом


func make_capsule(r: float, h: float) -> void:
	radius = r
	height = h
	var cs := CollisionShape3D.new()
	var sh := CapsuleShape3D.new()
	sh.radius = r
	sh.height = maxf(h, r * 2.0 + 0.01)
	cs.shape = sh
	cs.position.y = sh.height * 0.5
	add_child(cs)


func set_yaw(y: float) -> void:
	yaw = y
	if model:
		model.rotation.y = y


func fwd() -> Vector3:
	return Vector3(-sin(yaw), 0, -cos(yaw))


static func yaw_to(from: Vector3, to: Vector3) -> float:
	return atan2(-(to.x - from.x), -(to.z - from.z))


func face(to: Vector3) -> void:
	yaw = yaw_to(global_position, to)


func turn_model(dt: float, rate := 14.0) -> void:
	if model:
		model.rotation.y = lerp_angle(model.rotation.y, yaw, clampf(rate * dt, 0.0, 1.0))


func center() -> Vector3:
	return global_position + Vector3(0, height * 0.55, 0)


func flat_dist(p: Vector3) -> float:
	return Vector2(p.x - global_position.x, p.z - global_position.z).length()


## Пятно тени под ногами. Настоящая тень от лампы есть, но далеко не везде (и её нет у мелких врагов),
## а пятно сразу ставит существо на пол. Пропадает, когда существо в прыжке, и не бросает тень сама.
func make_blob(size := 1.0, alpha := 0.5) -> void:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2.ONE
	mi.mesh = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_texture = Fx._dot()
	m.albedo_color = Color(0, 0, 0, alpha)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	m.no_depth_test = false
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.rotation.x = -PI * 0.5
	mi.scale = Vector3(size, size, 1.0)
	mi.top_level = true
	blob = mi
	if get_parent():
		get_parent().add_child(mi)


## Высота под ногами (для тени): луч вниз от ступней.
func safe_ground() -> float:
	var space := get_world_3d().direct_space_state
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(global_position + Vector3(0, 0.2, 0), global_position + Vector3(0, -6, 0), 1))
	return float((hit["position"] as Vector3).y) if not hit.is_empty() else global_position.y


func update_blob(ground_y: float) -> void:
	if blob == null:
		return
	var h := maxf(0.0, global_position.y - ground_y)
	blob.global_position = Vector3(global_position.x, ground_y + 0.02, global_position.z)
	var k := clampf(1.0 - h / 3.0, 0.15, 1.0)
	blob.scale = Vector3(radius * 3.2 * k, radius * 3.2 * k, 1.0)
	blob.visible = not dead or h < 0.4
