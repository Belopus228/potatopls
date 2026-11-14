class_name DarkDrun
extends Boss
## Тёмный Друн на крыше П-46. Серия ударов — после неё он выдыхается и «открывается».
## Шаг сквозь тень за спину, тёмные шары; на второй фазе — «ТЁМНЫЙ ХАМАМ» (кольцо по земле: перепрыгни).

var hits_left := 0
var orbs_left := 0
var cycle := 0


func _init() -> void:
	var m := Model.human(Cast.look_of("dark"))
	m.scale = Vector3.ONE * 1.22
	init_boss("Тёмный Друн", 700.0, m, 0.48, 2.15)
	base_guard = 0.35
	guard = 0.35
	m.set_emission(Color(0.35, 0.18, 0.75), 0.9)


func _check_phase() -> void:
	if phase == 1 and hp < hp_max * 0.5:
		phase = 2
		Fx.text(get_parent(), global_position + Vector3(0, height + 0.7, 0), "ФОГ ДАЁТ СИЛУ!", Color(0.75, 0.5, 1.0), 1.1)
		model.set_emission(Color(0.55, 0.2, 1.0), 1.6)
		Snd.sfx("roar", 0.0, 0.8)


func _on_closed() -> void:
	if state == "tired":
		set_state("rest")


func _ai(dt: float) -> void:
	var p := G.player
	if p.dead:
		_stop(dt)
		play("Idle", 0.3)
		return
	var d := player_dist()
	match state:
		"rest":
			face(p.global_position)
			if d > 5.0:
				_go(p.global_position, 3.6, dt, false)
				play("Walk", 0.2, 1.5)
			else:
				_stop(dt)
				play("Idle_Sword", 0.25)
			if st > (1.25 if phase == 1 else 0.8):
				cycle += 1
				var pick := cycle % (3 if phase == 1 else 4)
				if pick == 1:
					hits_left = 3
					set_state("dash_w")
				elif pick == 2:
					set_state("vanish")
					Snd.sfx("dash", -2.0, 0.6)
				elif pick == 3 and phase == 2:
					set_state("hamam_w")
					play("Shout", 0.1)
					Fx.text(get_parent(), global_position + Vector3(0, height + 0.5, 0), "ТЁМНЫЙ ХАМАМ!", Color(0.75, 0.5, 1.0), 1.0)
				else:
					orbs_left = 3 if phase == 1 else 5
					set_state("orbs")
		"dash_w":
			_stop(dt)
			face(p.global_position)
			play("Idle_Sword", 0.1)
			model.position.x = sin(st * 60.0) * 0.03
			if st >= 0.55:
				model.position.x = 0.0
				set_state("dash")
				play("Run", 0.05, 1.8)
		"dash":
			face(p.global_position)
			var f := fwd()
			velocity.x = f.x * 13.0
			velocity.z = f.z * 13.0
			if d < 1.7 or st > 0.9:
				set_state("punch")
				play("Punch_Right" if hits_left % 2 == 1 else "Punch_Left", 0.05, 1.9, true)
		"punch":
			_stop(dt, 40.0)
			if st >= 0.2 and not hit_once:
				hit_once = true
				blast(global_position + fwd() * 1.0, 1.5, 10.0 if hits_left > 1 else (14.0 if phase == 2 else 12.0), 7.0)
				Snd.sfx("swing", -4.0, 0.8)
			if st >= 0.42:
				hits_left -= 1
				if hits_left > 0:
					face(p.global_position)
					if d > 2.2:
						set_state("dash")
						play("Run", 0.05, 1.8)
					else:
						set_state("punch")
						play("Kick_Right" if hits_left == 1 else "Punch_Left", 0.05, 1.8, true)
				else:
					set_state("tired")
					play("HitRecieve_2", 0.1, 0.45, true)
					open(1.7 if phase == 1 else 1.4)
		"tired":
			_stop(dt)
			if st > 2.2:
				set_state("rest")
		"vanish":
			_stop(dt)
			model.set_alpha(maxf(0.0, 1.0 - st * 4.0))
			hittable = st < 0.2
			if st >= 0.62:
				var back := p.global_position - p.fwd() * 1.9
				back.y = p.global_position.y
				global_position = back
				face(p.global_position)
				model.set_alpha(1.0)
				model.rotation.y = yaw
				hittable = true
				set_state("kick")
				play("Kick_Right", 0.0, 1.5, true)
				Fx.puff(get_parent(), center(), Color(0.3, 0.1, 0.5, 0.6), 10)
		"kick":
			_stop(dt, 40.0)
			if st >= 0.3 and not hit_once:
				hit_once = true
				if not blast(global_position + fwd() * 1.1, 1.7, 15.0, 9.0):
					open(1.3, "ПРОМАЗАЛ! БЕЙ!")
				Snd.sfx("swing", -2.0, 0.7)
			if st >= 0.75:
				set_state("tired" if open_t > 0.0 else "rest")
		"orbs":
			_stop(dt)
			face(p.global_position)
			play("Gun_Shoot" if st > 0.25 else "Idle_Gun_Pointing", 0.1, 1.4)
			if st >= 0.42:
				var from := global_position + Vector3(0, 1.7, 0) + fwd() * 0.6
				var v := (p.center() - from).normalized() * (10.0 if phase == 1 else 12.5)
				Shot.fire(get_parent(), "dark", from, v, 8.0, "enemy", {"home": 0.9})
				Snd.sfx("shoot", -4.0, 0.7)
				orbs_left -= 1
				if orbs_left > 0:
					st = 0.12
				else:
					set_state("rest")
		"hamam_w":
			_stop(dt)
			if st >= 0.8:
				ring_start(global_position, 9.0, 22.0, 12.0)
				G.cam.shake(0.5)
				Snd.sfx("am", 0.0, 0.6)
				set_state("rest")
		_:
			set_state("rest")
