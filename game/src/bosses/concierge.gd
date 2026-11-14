class_name Concierge
extends Boss
## Консьерж Жмурино — призрак при журнале. Шагает сквозь тень за спину и бьёт; после серии выдыхается и «открывается».
## Швыряет квитанции веером, зовёт жильцов; «ОБХОД» — холодное кольцо по полу (перепрыгни).

var cycle := 0
var blinks_left := 0
var volleys := 0
var summoned := 0


func _init() -> void:
	var m := Model.creature("ghost", 3.0, {"Ghost_Main": Color("a8f0c8")})
	init_boss("Консьерж", 880.0, m, 1.0, 3.0)
	base_guard = 0.3
	guard = 0.3
	arena_r = 13.0


func _check_phase() -> void:
	if phase == 1 and hp < hp_max * 0.5:
		phase = 2
		Fx.text(get_parent(), global_position + Vector3(0, height + 0.8, 0), "ПРИЁМ ОКОНЧЕН!", Color(0.5, 1.0, 0.7), 1.2)
		model.set_emission(Color(0.2, 1.0, 0.5), 0.5)
		Snd.sfx("roar", 0.0, 1.5)


func _summon_due() -> bool:
	return (summoned == 0 and hp < hp_max * 0.7) or (summoned == 1 and hp < hp_max * 0.35)


func _ai(dt: float) -> void:
	var p := G.player
	if p.dead:
		_stop(dt)
		play("idle", 0.3)
		return
	match state:
		"rest":
			hittable = true
			rest_walk(dt, 2.8 if phase == 1 else 3.6, 4.5)
			if st > (1.3 if phase == 1 else 0.85):
				if _summon_due():
					set_state("summon")
					play("Yes", 0.1, 1.0, true)
				else:
					cycle += 1
					match cycle % 3:
						1:
							blinks_left = 2 if phase == 1 else 3
							set_state("vanish")
							Snd.sfx("dash", -3.0, 0.6)
						2:
							volleys = 3 if phase == 1 else 4
							set_state("bills")
						_:
							set_state("slam_w")
							Fx.text(get_parent(), global_position + Vector3(0, height + 0.5, 0), "ОБХОД!", Color(0.5, 1.0, 0.7), 0.9)
		"vanish":
			_stop(dt)
			hittable = false
			model.set_alpha(maxf(0.15, 1.0 - st * 2.4))
			if st >= 0.5:
				blink_behind(2.3)
				blinks_left -= 1
				set_state("punch")
				Fx.warn(get_parent(), global_position + fwd() * 1.6, 2.5, 0.5)
		"punch":
			_stop(dt)
			model.set_alpha(minf(1.0, 0.3 + st * 2.0))
			if st >= 0.5 and not hit_once:
				hit_once = true
				hittable = true
				model.set_alpha(1.0)
				play("Punch", 0.05, 1.3, true)
				blast(global_position + fwd() * 1.6, 2.5, 16.0, 10.0)
				Snd.sfx("swing", 0.0, 0.7)
			if st >= 0.95:
				if blinks_left > 0:
					set_state("vanish")
					Snd.sfx("dash", -3.0, 0.6)
				else:
					set_state("tired")
					open(2.8 if phase == 1 else 2.5, "ЗАПЫХАЛСЯ! БЕЙ!")
					play("HitReact", 0.1, 0.4, true)
		"tired":
			_stop(dt)
			model.rotation.z = sin(st * 9.0) * 0.07
			if open_t <= 0.0:
				model.rotation.z = 0.0
				set_state("rest")
		"bills":
			_stop(dt)
			face(p.global_position)
			if st >= 0.5:
				play("Headbutt", 0.05, 1.3, true)
				shoot("chip", 10.5, 8.0, 5 if phase == 1 else 7, 0.17)
				Snd.sfx("throw", -3.0, 1.2)
				volleys -= 1
				if volleys > 0:
					st = 0.0
				else:
					set_state("rest")
		"slam_w":
			_stop(dt)
			model.position.y = minf(st, 0.7) * 2.2
			if st >= 0.8:
				model.position.y = 0.0
				G.cam.shake(0.6)
				Snd.sfx("crash", 0.0, 1.2)
				blast(global_position, 2.6, 15.0, 10.0)
				ring_start(global_position, 8.0, 20.0, 12.0, Color(0.3, 1.0, 0.6))
				if phase == 2:
					for i in 4:
						var a := TAU * i / 4.0 + randf()
						var at := clamp_arena(p.global_position + Vector3(cos(a), 0, sin(a)) * 3.0, 0.5)
						at.y = global_position.y
						drop(at, 2.0, 1.0 + i * 0.15, 12.0, Color(0.5, 1.0, 0.7))
				set_state("slam")
		"slam":
			_stop(dt)
			if st > 0.9:
				set_state("rest")
		"summon":
			_stop(dt)
			if st > 0.5 and not hit_once:
				hit_once = true
				summoned += 1
				Snd.sfx("roar", 0.0, 1.6)
				Fx.text(get_parent(), global_position + Vector3(0, height + 0.6, 0), "ЖИЛЬЦЫ! НА СОБРАНИЕ!", Color(0.7, 1.0, 0.8), 0.9)
				if summoned == 1:
					summon("skull", 3, 6.0)
				else:
					summon("zombie", 2, 6.0)
					summon("jmur", 1, 7.0)
			if st > 1.3:
				set_state("rest")
		_:
			set_state("rest")


func _on_closed() -> void:
	hittable = true
	model.set_alpha(1.0)
