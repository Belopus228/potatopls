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
