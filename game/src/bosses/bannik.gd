class_name Bannik
extends Boss
## Банник: топает — по полу идёт волна жара (перепрыгни); потом садится отдышаться и «открывается».
## Дышит паром веером, кидает раскалённые камни; на второй фазе топает дважды подряд.

var cycle := 0
var slams_left := 0
var volleys := 0
var stones_left := 0
var stone_t := 0.0


func _init() -> void:
	var m := Model.creature("yeti", 3.4, {"Yeti_Main": Color("d8705a"), "Yeti_Secondary": Color("f0c0a0")})
	init_boss("Банник", 760.0, m, 1.1, 3.2)
	base_guard = 0.3
	guard = 0.3
	arena_r = 12.5


func _check_phase() -> void:
	if phase == 1 and hp < hp_max * 0.5:
		phase = 2
		Fx.text(get_parent(), global_position + Vector3(0, height + 0.8, 0), "ПОДДАЙ-КА ПАРУ!", Color(1, 0.6, 0.4), 1.2)
		model.set_emission(Color(1.0, 0.3, 0.1), 0.45)
		Snd.sfx("roar", 0.0, 0.9)


func _ai(dt: float) -> void:
	var p := G.player
	if p.dead:
		_stop(dt)
		play("idle", 0.3)
		return
	var d := player_dist()
	match state:
		"rest":
			rest_walk(dt, 2.7 if phase == 1 else 3.5, 3.6)
			if st > (1.3 if phase == 1 else 0.85):
				cycle += 1
				match cycle % 3:
					1:
						slams_left = 1 if phase == 1 else 2
						set_state("slam_w")
						play("Duck", 0.15, 1.0, true)
					2:
						volleys = 2 if phase == 1 else 3
						set_state("steam")
					_:
						stones_left = 5 if phase == 1 else 7
						stone_t = 0.3
						set_state("stones")
						play("Weapon", 0.1, 1.0, true)
						Fx.text(get_parent(), global_position + Vector3(0, height + 0.5, 0), "КАМЕНКА!", Color(1, 0.6, 0.4), 0.9)
		"slam_w":
			_stop(dt)
			face(p.global_position)
			model.scale.y = 1.0 - minf(st, 0.5) * 0.3
			if st >= 0.7:
				model.scale.y = 1.0
				velocity.y = 9.0
				var dv := clamp_arena(p.global_position, 2.0) - global_position
				dv.y = 0.0
				dv = dv.limit_length(6.0)
				velocity.x = dv.x / 0.85
				velocity.z = dv.z / 0.85
				set_state("slam")
				play("Jump", 0.05, 1.0, true)
				Snd.sfx("jump", 0.0, 0.5)
		"slam":
			if st > 0.2 and is_on_floor():
				velocity.x = 0.0
				velocity.z = 0.0
				G.cam.shake(0.8)
				Snd.sfx("crash", 0.0, 0.7)
				Fx.dust(get_parent(), global_position + Vector3(0, 0.4, 0))
				blast(global_position, 2.6, 16.0, 11.0)
				ring_start(global_position, 8.5, 20.0, 9.0, Color(1.0, 0.45, 0.2))
				slams_left -= 1
				play("Jump_Land", 0.05, 1.0, true)
				set_state("slam_r")
			elif st > 2.5:
				set_state("rest")
		"slam_r":
			_stop(dt)
			if st > 0.55:
				if slams_left > 0:
					set_state("slam_w")
					play("Duck", 0.1, 1.2, true)
				else:
					set_state("tired")
					open(3.2 if phase == 1 else 2.9, "ОТДЫШКА! БЕЙ!")
					play("Duck", 0.2, 0.5, true)
		"tired":
			_stop(dt)
			if open_t <= 0.0:
				set_state("rest")
		"steam":
			_stop(dt)
			face(p.global_position)
			if st >= 0.55:
				play("Punch", 0.05, 1.3, true)
				shoot("steam", 9.5, 8.0, 4 if phase == 1 else 6, 0.22)
				Snd.sfx("spray", -2.0, 0.6)
				volleys -= 1
				if volleys > 0:
					st = 0.0
				else:
					set_state("rest")
		"stones":
			_stop(dt)
			stone_t -= dt
			if stone_t <= 0.0 and stones_left > 0:
				stone_t = 0.42 if phase == 1 else 0.3
				stones_left -= 1
				var lead := Vector3(p.velocity.x, 0, p.velocity.z) * 0.45
				var at := clamp_arena(p.global_position + lead + Vector3(randf_range(-1.4, 1.4), 0, randf_range(-1.4, 1.4)), 0.5)
				at.y = global_position.y
				drop(at, 2.0, 1.0, 10.0, Color(1.0, 0.5, 0.2))
				Snd.sfx("throw", -3.0, 0.7)
			if stones_left <= 0 and st > 0.6 and drops.is_empty():
				set_state("rest")
		_:
			set_state("rest")
	if state == "rest" and d < 3.0 and st > 0.5 and cd <= 0.0:
		cd = 2.2
		play("Punch", 0.05, 1.2, true)
		drop(global_position + fwd() * 2.0, 2.2, 0.4, 13.0, Color(1.0, 0.7, 0.5))
