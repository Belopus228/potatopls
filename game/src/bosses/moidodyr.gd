class_name Moidodyr
extends Boss
## Мойдодыр: мыльные пузыри, таран со щёткой и «ДУШ» — кипяток с потолка по красным кругам.
## Врезался в колонну или перегрел бойлер после душа — «открывается».

var cycle := 0
var shots_left := 0
var rain_left := 0
var rain_t := 0.0
var dir := Vector3.ZERO
var summoned := 0


func _init() -> void:
	var m := Model.creature("mech", 3.6, {})
	init_boss("Мойдодыр", 780.0, m, 1.15, 3.4)
	base_guard = 0.3
	guard = 0.3
	arena_r = 21.0


func _check_phase() -> void:
	if phase == 1 and hp < hp_max * 0.5:
		phase = 2
		Fx.text(get_parent(), global_position + Vector3(0, height + 0.8, 0), "КИПЯТОК!", Color(0.5, 0.85, 1.0), 1.2)
		model.set_emission(Color(0.2, 0.6, 1.0), 0.5)
		Snd.sfx("roar", 0.0, 1.1)


func _summon_due() -> bool:
	return (summoned == 0 and hp < hp_max * 0.66) or (summoned == 1 and hp < hp_max * 0.33)


func _ai(dt: float) -> void:
	var p := G.player
	if p.dead:
		_stop(dt)
		play("idle", 0.3)
		return
	match state:
		"rest":
			rest_walk(dt, 2.6 if phase == 1 else 3.4, 5.0)
			if st > (1.3 if phase == 1 else 0.85):
				if _summon_due():
					set_state("summon")
					play("Hello", 0.1, 1.0, true)
				else:
					cycle += 1
					match cycle % 3:
						1:
							shots_left = 5 if phase == 1 else 8
							set_state("bubbles")
						2:
							set_state("sweep_w")
							Snd.sfx("roar", -2.0, 1.2)
						_:
							rain_left = 6 if phase == 1 else 10
							rain_t = 0.0
							set_state("shower")
							play("Dance", 0.15, 1.0)
							Fx.text(get_parent(), global_position + Vector3(0, height + 0.6, 0), "К ДУШУ!", Color(0.5, 0.85, 1.0), 1.0)
		"bubbles":
			_stop(dt)
			face(p.global_position)
			if st >= 0.45:
				play("Shoot", 0.05, 1.5, true)
				shoot("bubble", 7.5 if phase == 1 else 9.0, 9.0, 1, 0.0, {"home": 0.7})
				Snd.sfx("shoot", -5.0, 1.5)
				shots_left -= 1
				if shots_left > 0:
					st = 0.12 if phase == 1 else 0.2
				else:
					set_state("rest")
		"sweep_w":
			_stop(dt)
			face(p.global_position)
			play("idle", 0.1)
			model.position.x = sin(st * 50.0) * 0.07
			if st >= (0.85 if phase == 1 else 0.6):
				model.position.x = 0.0
				dir = fwd()
				set_state("sweep")
				play("run", 0.05, 1.6)
				Snd.sfx("dash", -2.0, 0.7)
		"sweep":
			velocity.x = dir.x * 14.5
			velocity.z = dir.z * 14.5
			if not hit_once and blast(global_position + dir * 1.4, 2.0, 20.0, 12.0, 3.0):
				hit_once = true
			if st > 0.15 and is_on_wall():
				G.cam.shake(0.7)
				Snd.sfx("crash", 0.0)
				Fx.dust(get_parent(), global_position + dir * 1.2 + Vector3(0, 1.5, 0))
				velocity = -dir * 3.0
				set_state("crash")
				open(2.8, "ВРЕЗАЛСЯ! БЕЙ!")
				play("hit", 0.05, 0.5, true)
			elif st >= 1.5:
				set_state("skid")
		"crash":
			_stop(dt, 12.0)
			model.rotation.z = sin(st * 9.0) * 0.1
			if open_t <= 0.0:
				model.rotation.z = 0.0
				set_state("rest")
		"skid":
			_stop(dt, 14.0)
			play("idle", 0.2)
			if st > 0.6:
				set_state("rest")
		"shower":
			_stop(dt)
			rain_t -= dt
			if rain_t <= 0.0 and rain_left > 0:
				rain_t = 0.36 if phase == 1 else 0.27
				rain_left -= 1
				var lead := Vector3(p.velocity.x, 0, p.velocity.z) * 0.5
				var at := clamp_arena(p.global_position + lead + Vector3(randf_range(-1.6, 1.6), 0, randf_range(-1.6, 1.6)), 0.5)
				at.y = global_position.y
				drop(at, 2.3, 0.95, 14.0, Color(0.6, 0.85, 1.0))
			if rain_left <= 0 and st > 0.6 and drops.is_empty():
				set_state("hot")
				open(3.0 if phase == 1 else 2.6, "БОЙЛЕР ПЕРЕГРЕЛСЯ! БЕЙ!")
				play("hit", 0.1, 0.4, true)
				Fx.puff(get_parent(), center() + Vector3(0, 1.5, 0), Color(1, 1, 1, 0.7), 16)
		"hot":
			_stop(dt)
			model.rotation.z = sin(st * 12.0) * 0.05
			if open_t <= 0.0:
				model.rotation.z = 0.0
				set_state("rest")
		"summon":
			_stop(dt)
			if st > 0.5 and not hit_once:
				hit_once = true
				summoned += 1
				Snd.sfx("roar", 0.0, 1.5)
				Fx.text(get_parent(), global_position + Vector3(0, height + 0.6, 0), "МОЧАЛКИ, КО МНЕ!", Color(0.8, 0.95, 1.0), 0.9)
				summon("soap", 2 if summoned == 1 else 3, 6.0)
				if summoned == 2:
					summon("drone", 1, 7.0)
			if st > 1.3:
				set_state("rest")
		_:
			set_state("rest")
