class_name Player
extends Actor
## Игрок: ходьба, бег, прыжок (двойной — с кроссами), серия из трёх ударов, перекат,
## бросок «котлеты», дихлофос, ульта «АМ-АМ-АМ», еда, взаимодействие.

const WALK := 4.3
const RUN := 7.3
const JUMP := 9.2
const COMBO := [
	{"anim": "Punch_Right", "speed": 2.1, "hit": 0.15, "next": 0.25, "dur": 0.38, "dmg": 10.0, "reach": 1.75, "kb": 2.5},
	{"anim": "Punch_Left", "speed": 2.1, "hit": 0.15, "next": 0.25, "dur": 0.38, "dmg": 12.0, "reach": 1.75, "kb": 2.5},
	{"anim": "Kick_Right", "speed": 1.9, "hit": 0.2, "next": 0.4, "dur": 0.48, "dmg": 22.0, "reach": 2.0, "kb": 8.0},
]
const HEAVY := {"anim": "Kick_Left", "speed": 1.5, "hit": 0.28, "next": 0.55, "dur": 0.6, "dmg": 38.0, "reach": 2.2, "kb": 12.0}

var st := 100.0                 # выносливость
var rage := 0.0
var spray := 1.0                # заряд дихлофоса 0..1
var state := "move"             # move, attack, roll, hurt, throw, spray, ult, dead
var state_t := 0.0
var combo_i := 0
var combo_queued := false
var hit_done := false
var cur_hit := {}
var inv_t := 0.0
var coyote := 0.0
var jump_buf := 0.0
var air_jumps := 0
var st_delay := 0.0
var exhausted := false
var near: Variant = null
var slip := 0.0                 # 0..1 — скользко (мыло, лёд); сбрасывается каждый кадр
var slow_t := 0.0               # замедление (паутина)
var buff_t := 0.0               # энергетик: бесконечный бег
var safe_pos := Vector3.ZERO
var safe_t := 0.0
var anim_lock := ""             # анимация, навязанная сценкой ("Sit", "Phone"…)
var roll_dir := Vector3.ZERO
var charge_t := 0.0
var throw_cd := 0.0
var step_t := 0.0
var spray_tick := 0.0
var ult_wave := 0
var sprinting := false
var chain_node: Node3D
var can_node: Node3D
var _was_floor := true
var _spray_fx: CPUParticles3D


func _ready() -> void:
	name = "Player"
	collision_layer = 2
	collision_mask = 1
	make_capsule(0.36, 1.76)
	floor_max_angle = deg_to_rad(52.0)
	floor_snap_length = 0.35
	floor_constant_speed = true
	set_skin(String(G.save.get("skin", "casual")))
	_spray_fx = Fx.spray_emitter()
	add_child(_spray_fx)


func set_skin(skin: String) -> void:
	if model:
		model.queue_free()
	var look: Dictionary = Cast.SKINS.get(skin, Cast.SKINS["casual"])
	model = Model.human(look)
	add_child(model)
	model.play("Idle")
	chain_node = null
	can_node = null


func place(pos: Vector3, y := 0.0) -> void:
	global_position = pos
	velocity = Vector3.ZERO
	set_yaw(y)
	safe_pos = pos
	reset_physics_interpolation()


func revive() -> void:
	dead = false
	hp_max = G.max_hp()
	hp = hp_max
	st = 100.0
	state = "move"
	inv_t = 0.0
	anim_lock = ""
	slow_t = 0.0
	if model:
		model.play("Idle", 0.0)


func add_rage(v: float) -> void:
	if G.has("am"):
		rage = clampf(rage + v, 0.0, 100.0)


func heal(v: float) -> void:
	hp = minf(G.max_hp(), hp + v)


# ---------- основной цикл ----------

func _physics_process(dt: float) -> void:
	hp_max = G.max_hp()
	inv_t = maxf(0.0, inv_t - dt)
	throw_cd = maxf(0.0, throw_cd - dt)
	slow_t = maxf(0.0, slow_t - dt)
	buff_t = maxf(0.0, buff_t - dt)
	state_t += dt
	var ctl := G.mode == "play" and not dead
	var on_floor := is_on_floor()
	if on_floor:
		coyote = 0.12
		air_jumps = 1 if G.has("kicks") else 0
	else:
		coyote = maxf(0.0, coyote - dt)
	jump_buf = maxf(0.0, jump_buf - dt)

	# ввод
	var mv := Vector2.ZERO
	if ctl:
		mv = Inp.move()
	var cam_yaw: float = G.cam.yaw if G.cam else 0.0
	var wish := Vector3(mv.x, 0, -mv.y).rotated(Vector3.UP, cam_yaw)
	if wish.length() > 1.0:
		wish = wish.normalized()
	sprinting = false

	if dead:
		velocity.x = move_toward(velocity.x, 0.0, 30.0 * dt)
		velocity.z = move_toward(velocity.z, 0.0, 30.0 * dt)
	elif not ctl:
		_idle_locked(dt, on_floor)
	else:
		if Inp.hit("jump"):
			jump_buf = 0.14
		match state:
			"move": _st_move(dt, wish, on_floor)
			"attack": _st_attack(dt, wish)
			"roll": _st_roll(dt)
			"hurt": _st_hurt(dt)
			"throw": _st_throw(dt, wish)
			"spray": _st_spray(dt, wish)
			"ult": _st_ult(dt)
		_common_actions()

	# гравитация и движение
	if not on_floor:
		velocity.y -= gravity * dt
	elif velocity.y < 0.0:
		velocity.y = -1.0
	move_and_slide()
	_separate(dt)
	turn_model(dt, 16.0)

	# приземление
	var now_floor := is_on_floor()
	if now_floor and not _was_floor and not dead:
		Snd.sfx("land", -6.0)
		Fx.dust(get_parent(), global_position)
	_was_floor = now_floor

	# выносливость и заряды
	st_delay = maxf(0.0, st_delay - dt)
	if st_delay <= 0.0 and not sprinting:
		st = minf(100.0, st + 30.0 * dt)
	if exhausted and st >= 35.0:
		exhausted = false
	if state != "spray":
		spray = minf(1.0, spray + dt / 11.0)

	# безопасная точка и падение за край
	if now_floor and ctl and state == "move":
		safe_t += dt
		if safe_t > 0.4 and get_platform_velocity().length() < 0.1:
			safe_t = 0.0
			safe_pos = global_position
	if G.level and global_position.y < G.level.kill_y and not dead:
		place(safe_pos + Vector3(0, 0.3, 0), yaw)
		if ctl:
			hurt(12.0, global_position, 0.0, true)
			G.toast("Упал. Бывает", "small")
	slip = 0.0
	_find_near(ctl)


func _idle_locked(dt: float, on_floor: bool) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 40.0 * dt)
	velocity.z = move_toward(velocity.z, 0.0, 40.0 * dt)
	if state in ["attack", "roll", "throw", "spray", "ult", "hurt"]:
		state = "move"
		_spray_fx.emitting = false
	if anim_lock != "":
		model.play(anim_lock, 0.25)
	elif on_floor:
		model.play("Idle", 0.2)
	else:
		model.play("Fall", 0.2)


func _st_move(dt: float, wish: Vector3, on_floor: bool) -> void:
	var want_run := (Inp.down("sprint") or Inp.touch_run) and wish.length() > 0.6 and not exhausted
	sprinting = want_run and on_floor
	var spd := RUN if want_run else WALK
	if slow_t > 0.0:
		spd *= 0.45
	if sprinting and buff_t <= 0.0:
		st -= 15.0 * dt
		st_delay = 0.7
		if st <= 0.0:
			st = 0.0
			exhausted = true
	var acc := (52.0 if on_floor else 20.0) * (1.0 - slip * 0.93)
	var target := wish * spd
	velocity.x = move_toward(velocity.x, target.x, acc * dt)
	velocity.z = move_toward(velocity.z, target.z, acc * dt)
	if wish.length() > 0.15:
		yaw = lerp_angle(yaw, atan2(-wish.x, -wish.z), clampf(13.0 * dt, 0.0, 1.0))
	# прыжок
	if jump_buf > 0.0:
		if coyote > 0.0:
			velocity.y = JUMP
			coyote = 0.0
			jump_buf = 0.0
			Snd.sfx("jump", -4.0)
			model.play("Jump", 0.05, 1.0, true)
		elif air_jumps > 0:
			air_jumps -= 1
			velocity.y = JUMP * 0.92
			jump_buf = 0.0
			Snd.sfx("jump", -2.0, 1.25)
			Fx.ring(get_parent(), global_position, Color(1, 0.85, 0.3), 1.2, 0.3)
			model.play("Jump", 0.05, 1.0, true)
	# анимация
	var hs := Vector2(velocity.x, velocity.z).length()
	if not on_floor:
		if velocity.y < 1.0 or not model.playing() or model.cur != "Jump":
			if coyote <= 0.0:
				model.play("Fall", 0.18)
	elif hs < 0.5:
		model.play("Idle", 0.18)
	elif hs < 2.4:
		model.play("Walk", 0.18, clampf(hs / 1.5, 0.7, 1.7))
	else:
		model.play("Run", 0.15, clampf(hs / 4.7, 0.8, 1.7))
		step_t -= dt * hs
		if step_t <= 0.0:
			step_t = 2.3
			Snd.sfx("step", -14.0, 1.0, 0.15)
	# действия
	if Inp.hit("attack") and on_floor:
		_start_attack(0)
	elif Inp.hit("dodge") and on_floor and st >= 12.0:
		_start_roll(wish)
	elif Inp.hit("throw") and throw_cd <= 0.0:
		_start_throw()
	elif Inp.down("gadget") and G.has("spray") and spray > 0.08 and on_floor:
		state = "spray"
		state_t = 0.0
		spray_tick = 0.0
		Snd.sfx("spray", -4.0)
	elif Inp.hit("gadget") and G.has("spray") and spray <= 0.08:
		G.toast("Дихлофос копится…", "small")
	elif Inp.hit("ult"):
		if G.has("am") and rage >= 100.0:
			_start_ult()
		elif G.has("am"):
			G.toast("Ярость ещё не накопилась", "small")


func _common_actions() -> void:
	if Inp.hit("item"):
		eat()
	if Inp.hit("interact") and near != null and state in ["move", "spray"]:
		var it: Dictionary = near
		near = null
		Snd.sfx("ui", -6.0)
		it["fn"].call()


# ---------- удары ----------

func _start_attack(i: int, heavy := false) -> void:
	state = "attack"
	state_t = 0.0
	combo_i = i
	combo_queued = false
	hit_done = false
	cur_hit = HEAVY if heavy else COMBO[i]
	var tgt := _aim_target(3.4, 1.9)
	if tgt:
		face(tgt.global_position)
	else:
		var mv := Inp.move()
		if mv.length() > 0.3:
			var w := Vector3(mv.x, 0, -mv.y).rotated(Vector3.UP, G.cam.yaw)
			yaw = atan2(-w.x, -w.z)
	model.play(cur_hit["anim"], 0.06, cur_hit["speed"], true)
	var f := fwd()
	velocity.x = f.x * 3.4
	velocity.z = f.z * 3.4
	Snd.sfx("swing", -8.0, 1.0 + i * 0.08)


func _st_attack(dt: float, _wish: Vector3) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 16.0 * dt)
	velocity.z = move_toward(velocity.z, 0.0, 16.0 * dt)
	if Inp.hit("attack"):
		combo_queued = true
	if not hit_done and state_t >= float(cur_hit["hit"]):
		hit_done = true
		_do_hit()
	if state_t >= float(cur_hit["next"]) and combo_queued and combo_i < COMBO.size() - 1 and cur_hit != HEAVY:
		_start_attack(combo_i + 1)
	elif state_t >= float(cur_hit["next"]) and Inp.hit("dodge") and st >= 12.0:
		_start_roll(Vector3.ZERO)
	elif state_t >= float(cur_hit["dur"]):
		state = "move"


func _do_hit() -> void:
	var f := fwd()
	var reach: float = cur_hit["reach"]
	var dmg: float = float(cur_hit["dmg"]) * G.dmg_mult()
	var any := false
	for e in G.ents.duplicate():
		if not is_instance_valid(e) or e.dead:
			continue
		var d: Vector3 = e.global_position - global_position
		var dy: float = (e.global_position.y + e.height * 0.5) - (global_position.y + 0.9)
		var fl := Vector2(d.x, d.z)
		if fl.length() > reach + e.radius or absf(dy) > 1.6 + e.height * 0.5:
			continue
		if fl.length() > 0.7 and fl.normalized().dot(Vector2(f.x, f.z)) < 0.25:
			continue
		if e.hurt(dmg, global_position, cur_hit["kb"], "melee"):
			any = true
	for c in G.breakables.duplicate():
		if is_instance_valid(c) and c.global_position.distance_to(global_position + f * 0.9 + Vector3(0, 0.6, 0)) < reach * 0.8 + 0.5:
			c.hurt(dmg, global_position)
			any = true
	if any:
		add_rage(7.0 if combo_i < 2 else 12.0)
		Snd.sfx("hit" if combo_i < 2 else "hit_big", -3.0)
		G.cam.shake(0.12 if combo_i < 2 else 0.3)


func _aim_target(max_d: float, max_dy: float, cone := -0.2) -> Actor:
	var best: Actor = null
	var bd := 1e9
	var ref := fwd()
	var mv := Inp.move()
	if mv.length() > 0.3 and G.cam:
		ref = Vector3(mv.x, 0, -mv.y).rotated(Vector3.UP, G.cam.yaw).normalized()
	for e in G.ents:
		if not is_instance_valid(e) or e.dead:
			continue
		var d: Vector3 = e.global_position - global_position
		var fl := Vector2(d.x, d.z)
		var dist := fl.length() - float(e.radius)
		if dist > max_d or absf(d.y) > max_dy + e.height:
			continue
		var dot := fl.normalized().dot(Vector2(ref.x, ref.z)) if fl.length() > 0.01 else 1.0
		if dot < cone:
			continue
		var score := dist - dot * 1.5
		if score < bd:
			bd = score
			best = e
	return best


# ---------- перекат ----------

func _start_roll(wish: Vector3) -> void:
	state = "roll"
	state_t = 0.0
	st -= 22.0
	st_delay = 0.8
	if st < 0.0:
		st = 0.0
	roll_dir = wish.normalized() if wish.length() > 0.2 else fwd()
	yaw = atan2(-roll_dir.x, -roll_dir.z)
	model.play("Roll", 0.05, 2.5, true)
	Snd.sfx("roll", -6.0)


func _st_roll(_dt: float) -> void:
	var k := 1.0 - clampf(state_t / 0.52, 0.0, 1.0) * 0.55
	var spd := 10.5 * k * (1.0 - slip * 0.3)
	velocity.x = roll_dir.x * spd
	velocity.z = roll_dir.z * spd
	if state_t >= 0.52:
		state = "move"


func rolling_iframes() -> bool:
	return state == "roll" and state_t < 0.42


# ---------- урон ----------

func hurt(dmg: float, from: Vector3, kb := 6.0, force := false) -> bool:
	if dead or G.opts.has("god"):
		return false
	if not force and (inv_t > 0.0 or state == "ult" or rolling_iframes() or G.mode != "play"):
		return false
	hp -= dmg
	inv_t = 0.75
	model.flash(Color(1, 0.25, 0.2), 0.7)
	G.cam.shake(0.35)
	Snd.sfx("hurt", -2.0)
	add_rage(dmg * 0.5)
	G.ui.hud.damage_flash()
	_spray_fx.emitting = false
	if hp <= 0.0:
		hp = 0.0
		_die()
		return true
	if kb > 0.0:
		var d := global_position - from
		d.y = 0.0
		d = d.normalized() if d.length() > 0.05 else -fwd()
		velocity.x = d.x * kb
		velocity.z = d.z * kb
		velocity.y = maxf(velocity.y, 2.5)
		state = "hurt"
		state_t = 0.0
		model.play("HitRecieve" if randf() < 0.5 else "HitRecieve_2", 0.05, 1.5, true)
	return true


func _st_hurt(dt: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 18.0 * dt)
	velocity.z = move_toward(velocity.z, 0.0, 18.0 * dt)
	if state_t > 0.3:
		state = "move"


func _die() -> void:
	dead = true
	state = "dead"
	model.play("Death", 0.08, 1.0, true)
	G.on_player_dead()


# ---------- бросок, дихлофос, ульта, еда ----------

func _start_throw() -> void:
	if not G.spend(2):
		G.toast("Нет бабок на котлету", "small")
		Snd.sfx("deny", -6.0)
		throw_cd = 0.4
		return
	state = "throw"
	state_t = 0.0
	hit_done = false
	throw_cd = 0.55
	var tgt := _aim_target(16.0, 6.0, 0.3)
	if tgt:
		face(tgt.global_position)
	elif G.cam:
		yaw = G.cam.yaw
	model.play("Sword_Slash", 0.06, 2.4, true)


func _st_throw(dt: float, wish: Vector3) -> void:
	var target := wish * WALK * 0.5
	velocity.x = move_toward(velocity.x, target.x, 30.0 * dt)
	velocity.z = move_toward(velocity.z, target.z, 30.0 * dt)
	if not hit_done and state_t >= 0.16:
		hit_done = true
		var tgt := _aim_target(16.0, 6.0, 0.3)
		var from := global_position + Vector3(0, 1.35, 0) + fwd() * 0.5
		var dir := fwd()
		if tgt:
			dir = (tgt.center() - from).normalized()
		else:
			dir = (dir + Vector3(0, 0.06, 0)).normalized()
		Shot.fire(get_parent(), "cash", from, dir * 24.0, 16.0 * G.dmg_mult(), "player")
		Snd.sfx("throw", -5.0)
	if state_t >= 0.4:
		state = "move"


func _st_spray(dt: float, wish: Vector3) -> void:
	var target := wish * WALK * 0.55
	velocity.x = move_toward(velocity.x, target.x, 30.0 * dt)
	velocity.z = move_toward(velocity.z, target.z, 30.0 * dt)
	if G.cam and wish.length() < 0.2:
		yaw = lerp_angle(yaw, G.cam.yaw, clampf(8.0 * dt, 0.0, 1.0))
	elif wish.length() >= 0.2:
		yaw = lerp_angle(yaw, atan2(-wish.x, -wish.z), clampf(8.0 * dt, 0.0, 1.0))
	model.play("Idle_Gun_Pointing", 0.12)
	spray -= dt * 0.3
	_spray_fx.emitting = true
	_spray_fx.position = Vector3(0, 1.25, 0) + fwd() * 0.55
	_spray_fx.direction = fwd()
	spray_tick -= dt
	if spray_tick <= 0.0:
		spray_tick = 0.1
		var f := fwd()
		for e in G.ents.duplicate():
			if not is_instance_valid(e) or e.dead:
				continue
			var d: Vector3 = e.global_position - global_position
			var fl := Vector2(d.x, d.z)
			if fl.length() > 4.8 + e.radius or absf(d.y) > 2.5:
				continue
			if fl.length() > 0.8 and fl.normalized().dot(Vector2(f.x, f.z)) < 0.72:
				continue
			e.hurt(3.2 * G.dmg_mult(), global_position, 0.6, "spray")
	if not Inp.down("gadget") or spray <= 0.0:
		spray = maxf(spray, 0.0)
		state = "move"
		_spray_fx.emitting = false


func _start_ult() -> void:
	state = "ult"
	state_t = 0.0
	ult_wave = 0
	rage = 0.0
	velocity = Vector3.ZERO
	model.play("Shout", 0.08)
	G.ui.big_text("АМ-АМ-АМ!")


func _st_ult(_dt: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	var times := [0.12, 0.42, 0.72]
	if ult_wave < 3 and state_t >= times[ult_wave]:
		ult_wave += 1
		Snd.sfx("am", 0.0, 0.9 + ult_wave * 0.08)
		G.cam.shake(0.55)
		Fx.ring(get_parent(), global_position + Vector3(0, 0.15, 0), Color(1.0, 0.82, 0.12), 9.0, 0.45)
		Fx.text(get_parent(), global_position + Vector3(0, 2.3, 0), "АМ!", Color(1, 0.85, 0.15), 1.0)
		for e in G.ents.duplicate():
			if is_instance_valid(e) and not e.dead and e.global_position.distance_to(global_position) < 9.0 + e.radius:
				e.hurt(18.0 * G.dmg_mult(), global_position, 9.0, "ult")
		for c in G.breakables.duplicate():
			if is_instance_valid(c) and c.global_position.distance_to(global_position) < 7.0:
				c.hurt(50.0, global_position)
	if state_t >= 1.05:
		state = "move"


func eat() -> bool:
	var miss := G.max_hp() - hp
	var best := ""
	var best_heal := -1.0
	for id in Items.FOOD_ORDER:
		if not G.has(id):
			continue
		var h: float = Items.DEFS[id].get("heal", 0)
		# самое маленькое, чего хватает; иначе самое большое из имеющегося
		if best == "" or (h >= miss and (best_heal < miss or h < best_heal)) or (h < miss and best_heal < miss and h > best_heal):
			best = id
			best_heal = h
	if best == "":
		G.toast("Еды нет", "small")
		return false
	var d: Dictionary = Items.DEFS[best]
	if miss < 1.0 and not d.has("rage") and not d.has("buff"):
		G.toast("Ч и так здоров", "small")
		return false
	G.take(best)
	heal(d.get("heal", 0))
	if d.has("rage"):
		add_rage(d["rage"])
	if d.has("buff"):
		buff_t = d["buff"]
		G.toast("Бурмалда в крови!", "small")
	Snd.sfx("eat", -3.0)
	Fx.text(get_parent(), global_position + Vector3(0, 2.1, 0), "+%d" % int(d.get("heal", 0)), Color(0.5, 1, 0.5), 0.7)
	return true


func food_count() -> int:
	var n := 0
	for id in Items.FOOD_ORDER:
		n += G.count(id)
	return n


# ---------- прочее ----------

## Мягкое расталкивание с существами и NPC (без жёстких столкновений).
func _separate(dt: float) -> void:
	for e in G.ents:
		if not is_instance_valid(e) or e.dead or e.no_push:
			continue
		_push_from(e.global_position, radius + float(e.radius) * 0.85, e.height, dt)
	if G.level:
		for it in G.level.inter:
			if it.has("node") and is_instance_valid(it["node"]) and it["node"] is Npc and (it["node"] as Npc).solid:
				_push_from((it["node"] as Node3D).global_position, radius + 0.38, 1.8, dt)


func _push_from(p: Vector3, min_d: float, h: float, dt: float) -> void:
	var d := global_position - p
	if d.y > h or d.y < -1.8:
		return
	d.y = 0.0
	var l := d.length()
	if l < min_d and l > 0.001:
		var push := d / l * (min_d - l) * minf(1.0, 14.0 * dt)
		global_position += push


func _find_near(ctl: bool) -> void:
	near = null
	if not ctl or G.level == null:
		return
	var best := 1e9
	var f := fwd()
	var pp := global_position
	for it in G.level.inter:
		if it["off"]:
			continue
		if it.has("node"):
			if not is_instance_valid(it["node"]):
				continue
			it["pos"] = (it["node"] as Node3D).global_position + Vector3(0, 0.9, 0)
		if it.has("cond") and not it["cond"].call():
			continue
		var ip: Vector3 = it["pos"]
		var dx := ip.x - pp.x
		var dz := ip.z - pp.z
		var d := sqrt(dx * dx + dz * dz)
		if d >= float(it["r"]) or absf(ip.y - pp.y - 0.9) >= 2.4:
			continue
		var facing := (dx * f.x + dz * f.z) / d if d > 0.3 else 1.0
		var score := d - facing * 0.9
		if score < best:
			best = score
			near = it
