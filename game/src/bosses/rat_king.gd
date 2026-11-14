class_name RatKing
extends Boss
## Крысиный Король: разбегается и таранит. Увернись — врежется в стену или колонну и «откроется».
## Вблизи бьёт хвостом по кругу; на 66% и 33% здоровья зовёт крыс; на второй фазе таранит дважды подряд.

var charges_left := 0
var summoned := 0
var close_t := 0.0
var tail_used := false          # хвостом — не чаще раза между таранами, иначе вплотную бой не кончается
var dir := Vector3.ZERO


func _init() -> void:
	var m := Model.creature("rat", 2.2, {"Grey": Color("4a3a30"), "Pink": Color("d08a80")})
	init_boss("Крысиный Король", 460.0, m, 1.1, 2.0)
	var at := m.attach("Head")
	var cr: Node3D = Level.prop_scene("rpg/Crown").instantiate()
	var a := Level.prop_aabb("rpg/Crown")
	var s := 0.7 / maxf(a.size.x, 0.01) / m.scene.scale.x
	cr.scale = Vector3.ONE * s
	cr.position = Vector3(0, 0.32 / m.scene.scale.x, 0.0)
	at.add_child(cr)


func _check_phase() -> void:
	if phase == 1 and hp < hp_max * 0.5:
		phase = 2
		Fx.text(get_parent(), global_position + Vector3(0, height + 0.8, 0), "КОРОЛЬ В ЯРОСТИ!", Color(1, 0.3, 0.2), 1.1)
		model.set_emission(Color(1.0, 0.15, 0.1), 0.35)
		Snd.sfx("roar", 0.0, 1.2)


func _summon_due() -> bool:
	return (summoned == 0 and hp < hp_max * 0.66) or (summoned == 1 and hp < hp_max * 0.33)


func _ai(dt: float) -> void:
	var p := G.player
	if p.dead:
		_stop(dt)
		play("idle", 0.3)
		return
	var d := player_dist()
	match state:
		"rest":
			rest_walk(dt, 2.6 if phase == 1 else 3.6, 4.5)
			close_t = close_t + dt if d < 4.2 else maxf(0.0, close_t - dt)
			if st > (1.5 if phase == 1 else 0.9):
				if _summon_due():
					set_state("summon")
					play("attack", 0.1, 0.7, true)
				elif close_t > 1.0 and not tail_used:
					close_t = 0.0
					tail_used = true
					set_state("tail_w")
					Fx.warn(get_parent(), global_position, 4.6, 0.7)
				else:
					charges_left = 1 if phase == 1 else 2
					tail_used = false
					set_state("charge_w")
					Snd.sfx("roar", -2.0)
		"charge_w":
			_stop(dt)
			face(p.global_position)
			play("idle", 0.1)
			model.position.x = sin(st * 50.0) * 0.07
			if st >= (0.95 if phase == 1 else 0.7):
				model.position.x = 0.0
				dir = fwd()
				set_state("charge")
				play("run", 0.05, 1.7)
				Snd.sfx("dash", -2.0, 0.7)
		"charge":
			velocity.x = dir.x * 15.5
			velocity.z = dir.z * 15.5
			if not hit_once and blast(global_position + dir * 1.3, 1.9, 14.0, 12.0, 2.2):
				hit_once = true
			if st > 0.15 and is_on_wall():
				G.cam.shake(0.7)
				Snd.sfx("crash", 0.0)
				Fx.dust(get_parent(), global_position + dir * 1.2 + Vector3(0, 1, 0))
				Fx.burst(get_parent(), global_position + dir * 1.2 + Vector3(0, 1, 0), Color(0.6, 0.6, 0.6), 14, 6.0)
				velocity = -dir * 3.0
				set_state("crash")
				open(3.2, "ВРЕЗАЛСЯ! БЕЙ!")
				play("hit", 0.05, 0.5, true)
			elif st >= 1.6:
				set_state("skid")
		"crash":
			_stop(dt, 12.0)
			model.rotation.z = sin(st * 9.0) * 0.12
			if open_t <= 0.0:
				model.rotation.z = 0.0
				set_state("rest")
		"skid":
			_stop(dt, 14.0)
			play("idle", 0.2)
			if st > (0.7 if phase == 1 else 0.45):
				charges_left -= 1
				set_state("charge_w" if charges_left > 0 else "rest")
		"tail_w":
			_stop(dt)
			play("idle", 0.1)
			if st >= 0.7:
				blast(global_position, 4.6, 10.0, 11.0)
				Fx.ring(get_parent(), global_position + Vector3(0, 0.2, 0), Color(0.9, 0.6, 0.4), 4.8, 0.3)
				Snd.sfx("swing", 0.0, 0.6)
				yaw += TAU * 0.999
				set_state("tail_r")
		"tail_r":
			_stop(dt)
			if st > 0.9:
				set_state("rest")
		"summon":
			_stop(dt)
			if st > 0.5 and not hit_once:
				hit_once = true
				summoned += 1
				Snd.sfx("roar", 0.0, 1.4)
				Fx.text(get_parent(), global_position + Vector3(0, height + 0.6, 0), "КО МНЕ, СЕРЫЕ!", Color(1, 0.8, 0.6), 0.9)
				for i in 2:
					var a := TAU * i / 2.0 + randf()
					var pos := arena + Vector3(cos(a), 0, sin(a)) * (arena_r - 1.5)
					pos.y = global_position.y + 0.3
					G.level.enemy("rat", pos, {"alert": true})
			if st > 1.3:
				set_state("rest")
		_:
			set_state("rest")
