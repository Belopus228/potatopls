class_name SpiderMother
extends Boss
## Паучья Матка: прыгает на игрока (красный круг — уходи); приземлившись, застревает лапами и «открывается».
## Плюётся паутиной, вблизи кусает, зовёт паучков; на второй фазе прыгает дважды подряд.

var leaps_left := 0
var webs_left := 0
var summoned := 0
var cycle := 0
var target := Vector3.ZERO
var close_t := 0.0


func _init() -> void:
	var m := Model.creature("spider", 3.3, {})
	init_boss("Паучья Матка", 650.0, m, 1.5, 2.2)
	base_guard = 0.3
	guard = 0.3
	def["weak_spray"] = 1.8
	arena_r = 15.0


func _check_phase() -> void:
	if phase == 1 and hp < hp_max * 0.5:
		phase = 2
		Fx.text(get_parent(), global_position + Vector3(0, height + 0.8, 0), "МАТКА В БЕШЕНСТВЕ!", Color(1, 0.3, 0.2), 1.1)
		model.set_emission(Color(1.0, 0.1, 0.1), 0.4)
		Snd.sfx("roar", 0.0, 1.3)


func _summon_due() -> bool:
	return (summoned == 0 and hp < hp_max * 0.7) or (summoned == 1 and hp < hp_max * 0.35)


func _clamp_arena(p: Vector3, margin := 3.0) -> Vector3:
	var d := p - arena
	d.y = 0.0
	d = d.limit_length(arena_r - margin)
	return Vector3(arena.x + d.x, p.y, arena.z + d.z)


func _begin_leap() -> void:
	set_state("leap_w")
	play("idle", 0.1)
	Snd.sfx("alert", -2.0, 0.6)


func _ai(dt: float) -> void:
	var p := G.player
	if p.dead:
		_stop(dt)
		play("idle", 0.3)
		return
	var d := player_dist()
	match state:
		"rest":
			rest_walk(dt, 2.8 if phase == 1 else 3.7, 4.2)
			close_t = close_t + dt if d < 4.4 else maxf(0.0, close_t - dt * 0.5)
			if st > (1.4 if phase == 1 else 0.9):
				if _summon_due():
					set_state("summon")
					play("attack", 0.1, 0.7, true)
				elif close_t > 0.9:
					close_t = 0.0
					set_state("bite_w")
					Fx.warn(get_parent(), global_position + fwd() * 2.4, 2.7, 0.5)
				else:
					cycle += 1
					if cycle % 2 == 1:
						leaps_left = 1 if phase == 1 else 2
						_begin_leap()
					else:
						webs_left = 3 if phase == 1 else 5
						set_state("web")
		"leap_w":
			_stop(dt)
			face(p.global_position)
			model.scale.y = 1.0 - minf(st, 0.5) * 0.5
			if st >= 0.35 and not hit_once:
				hit_once = true
				target = _clamp_arena(p.global_position)
				Fx.warn(get_parent(), target, 3.6, 1.25)
			if st >= 0.8:
				model.scale.y = 1.0
				var dv := target - global_position
				var tt := 0.8
				velocity = Vector3(dv.x / tt, gravity * tt * 0.5 + dv.y / tt, dv.z / tt)
				set_state("leap")
				play("jump", 0.05, 1.0, true)
				Snd.sfx("jump", 0.0, 0.6)
		"leap":
			if st > 0.15 and is_on_floor():
				velocity.x = 0.0
				velocity.z = 0.0
				G.cam.shake(0.7)
				Snd.sfx("crash", 0.0, 0.8)
				Fx.dust(get_parent(), global_position + Vector3(0, 0.4, 0))
				Fx.ring(get_parent(), global_position + Vector3(0, 0.2, 0), Color(0.9, 0.85, 0.8), 3.8, 0.3)
				blast(global_position, 3.6, 20.0, 12.0)
				leaps_left -= 1
				if leaps_left > 0:
					set_state("leap_p")
				else:
					set_state("stuck")
					open(2.8 if phase == 1 else 2.4, "ЗАСТРЯЛА! БЕЙ!")
					play("hit", 0.1, 0.4, true)
			elif st > 2.5:
				set_state("rest")
		"leap_p":
			_stop(dt)
			play("idle", 0.2)
			if st > 0.3:
				_begin_leap()
		"stuck":
			_stop(dt)
			model.rotation.z = sin(st * 10.0) * 0.06
			if open_t <= 0.0:
				model.rotation.z = 0.0
				set_state("rest")
		"web":
			_stop(dt)
			face(p.global_position)
			if st >= 0.5:
				play("attack", 0.05, 1.4, true)
				var from := global_position + Vector3(0, 1.7, 0) + fwd() * 1.7
				var to := p.center()
				var flat := Vector3(to.x - from.x, 0, to.z - from.z)
				var tt := clampf(flat.length() / 12.0, 0.35, 1.5)
				var v := flat / tt + Vector3(0, (to.y - from.y) / tt + 0.5 * 6.0 * tt, 0)
				Shot.fire(get_parent(), "web", from, v, 9.0, "enemy", {})
				Snd.sfx("shoot", -4.0, 1.3)
				webs_left -= 1
				if webs_left > 0:
					st = 0.12
				else:
					set_state("rest")
		"bite_w":
			_stop(dt)
			if st >= 0.5:
				play("attack", 0.05, 1.3, true)
				blast(global_position + fwd() * 2.4, 2.7, 15.0, 9.0)
				Snd.sfx("swing", 0.0, 0.6)
				set_state("bite_r")
		"bite_r":
			_stop(dt)
			if st > 0.7:
				set_state("rest")
		"summon":
			_stop(dt)
			if st > 0.5 and not hit_once:
				hit_once = true
				summoned += 1
				Snd.sfx("roar", 0.0, 1.5)
				Fx.text(get_parent(), global_position + Vector3(0, height + 0.6, 0), "ДЕТКИ! КУШАТЬ!", Color(1, 0.8, 0.8), 0.9)
				for i in (3 if summoned == 1 else 4):
					var a := TAU * i / 4.0 + randf()
					var pos := _clamp_arena(global_position + Vector3(cos(a), 0, sin(a)) * 5.0, 2.0)
					pos.y = global_position.y + 0.3
					G.level.enemy("spiderling", pos, {"alert": true})
					Fx.puff(get_parent(), pos + Vector3(0, 0.4, 0), Color(0.9, 0.9, 0.9, 0.7), 6)
			if st > 1.3:
				set_state("rest")
		_:
			set_state("rest")
