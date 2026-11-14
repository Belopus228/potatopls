class_name Enemy
extends Actor
## Противник с простым ИИ (см. Bestiary). Боссы наследуются и переопределяют _ai().

var kind := ""
var def := {}
var state := "idle"
var st := 0.0                   # время в текущем состоянии
var home := Vector3.ZERO
var aggro := false
var stun_t := 0.0
var cd := 0.0
var no_push := false
var active := true              # false — стоит и ждёт (до начала боя)
var boss := false
var guard := 1.0                # множитель получаемого урона (у боссов меньше 1, пока не «открылись»)
var hittable := true
var hit_once := false
var dash_dir := Vector3.ZERO
var kb_v := Vector3.ZERO
var bar: Sprite3D
var bar_bg: Sprite3D
var fly_phase := 0.0
var wander_t := 0.0
var wander_to := Vector3.ZERO
var on_death: Callable
var leash := 30.0
var title := ""
var len_f := 0.0                # насколько модель выступает вперёд и назад от центра (длинные: крысы, волки)
var len_b := 0.0
var _dead_t := 0.0
var _stars: Label3D
var _los := false               # видит ли игрока (проверка лучом раз в ~0,15 с)
var _los_t := 0.0
var _lost_t := 0.0              # сколько секунд игрока не видно
var _crumb := Vector3.ZERO      # куда бежим, пока игрока не видно: точка его следа
var _crumb_t := 0.0
var _fit := 0.0                 # сдвиг модели вдоль тела, чтобы морда и хвост не торчали сквозь стену
var _ret_t := 0.0

static var _white: ImageTexture


func init(k: String, o := {}) -> void:
	kind = k
	def = Bestiary.DEFS.get(k, {}).duplicate(true)
	for key in o:
		def[key] = o[key]
	title = def.get("name", k)
	if def.has("human"):
		model = Model.human(def["human"])
	elif def.has("model"):
		model = Model.creature(def["model"], def.get("size", 1.0), def.get("colors", {}))
	if model:
		add_child(model)
		model.play("idle", 0.0)
		if def.has("model"):
			var b := model.bounds()
			len_f = maxf(0.0, -b.position.z)
			len_b = maxf(0.0, b.end.z)
	collision_layer = 4
	collision_mask = 1
	make_capsule(def.get("r", 0.45), def.get("h", 1.0))
	hp_max = float(def.get("hp", 30)) * float(o.get("hp_mul", 1.0))
	hp = hp_max
	fly_phase = randf() * TAU
	wander_t = randf_range(1.0, 4.0)
	cd = randf_range(0.2, 1.0)
	if o.get("alert", false):
		aggro = true
		state = "chase"
	if def.get("ai", "melee") in ["flyer", "flyer_shooter"]:
		gravity = 0.0


func _ready() -> void:
	G.ents.append(self)
	floor_max_angle = deg_to_rad(50.0)
	_make_bar()
	if not boss:
		make_blob(1.0, 0.45)


func _process(_dt: float) -> void:
	if blob and not dead:
		update_blob(safe_ground())


func _exit_tree() -> void:
	G.ents.erase(self)


func _make_bar() -> void:
	if boss:
		return
	if _white == null:
		var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		_white = ImageTexture.create_from_image(img)
	bar_bg = Sprite3D.new()
	bar_bg.texture = _white
	bar_bg.modulate = Color(0, 0, 0, 0.7)
	bar_bg.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	bar_bg.pixel_size = 0.01
	bar_bg.scale = Vector3(22, 3.2, 1)
	bar_bg.position.y = height + 0.35
	bar_bg.no_depth_test = true
	bar_bg.visible = false
	add_child(bar_bg)
	bar = Sprite3D.new()
	bar.texture = _white
	bar.modulate = Color(1.0, 0.3, 0.25)
	bar.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	bar.pixel_size = 0.01
	bar.position.y = height + 0.35
	bar.no_depth_test = true
	bar.render_priority = 1
	bar.visible = false
	add_child(bar)


func _update_bar() -> void:
	if bar == null:
		return
	var show := hp < hp_max and not dead
	bar.visible = show
	bar_bg.visible = show
	var k := clampf(hp / hp_max, 0.0, 1.0)
	bar.scale = Vector3(21.0 * k, 2.2, 1)
	bar.offset = Vector2(0, 0)


func set_state(s: String) -> void:
	state = s
	st = 0.0
	hit_once = false


func play(a: String, blend := 0.15, speed := 1.0, restart := false) -> float:
	return model.play(a, blend, speed * float(def.get("anim_k", 1.0)), restart) if model else 0.0


# ---------- цикл ----------

func _physics_process(dt: float) -> void:
	st += dt
	cd = maxf(0.0, cd - dt)
	if dead:
		_dead_tick(dt)
		return
	var frozen := G.mode != "play" or not active
	if stun_t > 0.0 and not frozen:
		stun_t -= dt
		velocity.x = move_toward(velocity.x, 0.0, 20.0 * dt)
		velocity.z = move_toward(velocity.z, 0.0, 20.0 * dt)
		if _stars:
			_stars.visible = true
			_stars.rotation.y += dt * 6.0
		if stun_t <= 0.0:
			if _stars:
				_stars.visible = false
			set_state("chase")
	elif frozen:
		velocity.x = move_toward(velocity.x, 0.0, 30.0 * dt)
		velocity.z = move_toward(velocity.z, 0.0, 30.0 * dt)
		if gravity == 0.0:
			velocity.y = move_toward(velocity.y, 0.0, 10.0 * dt)
		if not boss and state != "idle":
			play("idle", 0.3)
	else:
		_ai(dt)
	velocity += kb_v
	kb_v = kb_v.move_toward(Vector3.ZERO, 40.0 * dt)
	if gravity > 0.0:
		if not is_on_floor():
			velocity.y -= gravity * dt
		elif velocity.y < 0.0:
			velocity.y = -1.0
	move_and_slide()
	velocity -= kb_v
	turn_model(dt, 10.0)
	_fit_walls(dt)
	if global_position.y < -40.0:
		die(true)


# ---------- зрение и стены ----------

## Видна ли точка от глаз существа: стены, пол и крупная мебель загораживают.
func sees_point(to: Vector3) -> bool:
	var space := get_world_3d().direct_space_state
	var eye := global_position + Vector3(0, maxf(0.45, height * 0.8), 0)
	if space.intersect_ray(PhysicsRayQueryParameters3D.create(eye, to, 1)).is_empty():
		return true
	# второй луч повыше: низкий ящик или стол не должен прятать игрока от крысы
	var eye2 := global_position + Vector3(0, height + 0.5, 0)
	return space.intersect_ray(PhysicsRayQueryParameters3D.create(eye2, to + Vector3(0, 0.5, 0), 1)).is_empty()


func sees_player(dt := 0.0) -> bool:
	_los_t -= dt
	if _los_t <= 0.0:
		_los_t = 0.13 + randf() * 0.06
		var p := G.player
		_los = p != null and sees_point(p.global_position + Vector3(0, 1.1, 0))
		if bar and hp < hp_max and not dead:
			bar.visible = _los
			bar_bg.visible = _los
	return _los


## Куда бежать за игроком. Пока его видно — к нему. Иначе — по его следам: к самой свежей точке следа,
## которую видно отсюда. Так существо выходит через дверь, а не бьётся в стену, за которой стоит игрок.
func chase_pos(p: Player, dt: float) -> Vector3:
	if sees_player(dt):
		_lost_t = 0.0
		_crumb = p.global_position
		return _crumb
	_lost_t += dt
	_crumb_t -= dt
	if _crumb_t <= 0.0:
		_crumb_t = 0.25
		if _crumb == Vector3.ZERO:
			_crumb = global_position
		for i in range(p.trail.size() - 1, -1, -1):
			var c: Vector3 = p.trail[i]
			if absf(c.y - global_position.y) < 3.0 and sees_point(c + Vector3(0, 0.7, 0)):
				_crumb = c
				break
	return _crumb


## Длинные существа: если морда (или хвост) упирается в стену, модель сдвигается вдоль тела.
## Столкновение у существа — узкая капсула, иначе оно не пройдёт в дверь; а тело вдвое длиннее.
func _fit_walls(dt: float) -> void:
	if model == null or model.scene == null or len_f <= radius + 0.1 or dead:
		return
	var a := model.rotation.y
	var f := Vector3(-sin(a), 0, -cos(a))
	var from := global_position + Vector3(0, minf(0.5, maxf(0.25, height * 0.6)), 0)
	var space := get_world_3d().direct_space_state
	var want := 0.0
	var front := len_f + 0.06
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, from + f * front, 1))
	if not hit.is_empty():
		want = front - from.distance_to(hit["position"])
	elif len_b > radius + 0.1:
		var back := len_b * 0.75
		hit = space.intersect_ray(PhysicsRayQueryParameters3D.create(from, from - f * back, 1))
		if not hit.is_empty():
			want = -(back - from.distance_to(hit["position"]))
	_fit = lerpf(_fit, want, clampf(14.0 * dt, 0.0, 1.0))
	model.scene.position.z = _fit


func _ai(dt: float) -> void:
	var p := G.player
	if p == null:
		return
	var to := p.global_position - global_position
	var dist := Vector2(to.x, to.z).length()
	var ai: String = def.get("ai", "melee")
	if state == "idle":
		_idle(dt, dist, to.y)
		return
	if p.dead:
		set_state("idle")
		aggro = false
		return
	if state == "return":
		_go(home, float(def.get("speed", 3.5)), dt)
		hp = minf(hp_max, hp + hp_max * 0.2 * dt)
		_update_bar()
		play("walk", 0.2)
		_ret_t += dt
		if flat_dist(home) < 1.0:
			set_state("idle")
		elif _ret_t > 6.0:
			home = global_position      # дом за стеной по прямой недостижим — остаёмся тут
			set_state("idle")
		elif dist < float(def.get("sight", 9)) * 0.7 and sees_player(dt):
			aggro = true
			set_state("chase")
		return
	if not boss and (global_position.distance_to(home) > leash or _lost_t > 6.0):
		aggro = false
		_lost_t = 0.0
		_ret_t = 0.0
		set_state("return")
		return
	match ai:
		"melee": _ai_melee(dt, p, dist)
		"charger": _ai_charger(dt, p, dist)
		"leaper": _ai_leaper(dt, p, dist)
		"flyer": _ai_flyer(dt, p, dist, false)
		"flyer_shooter": _ai_flyer(dt, p, dist, true)
		"shooter": _ai_shooter(dt, p, dist)
		_: _ai_melee(dt, p, dist)


func _idle(dt: float, dist: float, dy: float) -> void:
	var sight: float = def.get("sight", 9)
	if dist < sight and absf(dy) < 4.0 and not G.player.dead and (dist < 1.5 or sees_player(dt)):
		aggro = true
		_lost_t = 0.0
		_crumb = global_position
		set_state("chase")
		Snd.sfx("alert", -10.0, 1.0, 0.2)
		return
	wander_t -= dt
	if wander_t <= 0.0:
		wander_t = randf_range(2.5, 6.0)
		var a := randf() * TAU
		wander_to = home + Vector3(cos(a), 0, sin(a)) * randf_range(0.5, 3.0)
	if flat_dist(wander_to) > 0.5 and wander_to != Vector3.ZERO:
		_go(wander_to, float(def.get("speed", 3.5)) * 0.35, dt)
		play("walk", 0.25, 0.7)
	else:
		_stop(dt)
		play("idle", 0.25)
	_hover(dt, home.y)


func _stop(dt: float, rate := 30.0) -> void:
	velocity.x = move_toward(velocity.x, 0.0, rate * dt)
	velocity.z = move_toward(velocity.z, 0.0, rate * dt)


## Идти к точке с расталкиванием соседей.
func _go(target: Vector3, speed: float, dt: float, turn := true) -> void:
	var d := target - global_position
	d.y = 0.0
	var dir := d.normalized() if d.length() > 0.05 else Vector3.ZERO
	var sep := Vector3.ZERO
	for e in G.ents:
		if e == self or not is_instance_valid(e) or e.dead:
			continue
		var o: Vector3 = global_position - e.global_position
		o.y = 0.0
		var l := o.length()
		var m: float = radius + e.radius + 0.15
		if l < m and l > 0.001:
			sep += o / l * (m - l) * 3.0
	var v := dir * speed + sep
	velocity.x = move_toward(velocity.x, v.x, 26.0 * dt)
	velocity.z = move_toward(velocity.z, v.z, 26.0 * dt)
	if turn and dir != Vector3.ZERO:
		yaw = lerp_angle(yaw, atan2(-dir.x, -dir.z), clampf(9.0 * dt, 0.0, 1.0))


func _hover(dt: float, base_y: float) -> void:
	if gravity > 0.0:
		return
	fly_phase += dt * 2.2
	var want := base_y + float(def.get("fly", 1.2)) + sin(fly_phase) * 0.18
	velocity.y = clampf((want - global_position.y) * 4.0, -5.0, 5.0)


func _strike(p: Player, reach_bonus := 0.5) -> bool:
	var d := p.global_position - global_position
	if Vector2(d.x, d.z).length() < float(def.get("reach", 1.4)) + reach_bonus and absf(d.y) < 2.0 and (boss or sees_point(p.global_position + Vector3(0, 1.0, 0))):
		return p.hurt(float(def.get("dmg", 8)), global_position, 6.0)
	return false


func _ai_melee(dt: float, p: Player, dist: float) -> void:
	var reach: float = def.get("reach", 1.4)
	var windup: float = def.get("windup", 0.4)
	match state:
		"chase":
			_go(chase_pos(p, dt), def.get("speed", 3.5), dt)
			play("run" if float(def.get("speed", 3.5)) > 3.0 else "walk", 0.2)
			if dist < reach * 0.85 and cd <= 0.0 and _los:
				set_state("windup")
				var l := model.length("attack")
				play("attack", 0.08, l / maxf(windup * 2.0, 0.2), true)
		"windup":
			_stop(dt)
			face(p.global_position)
			if st >= windup:
				_strike(p)
				Snd.sfx("swing", -10.0, 0.8)
				set_state("recover")
		"recover":
			_stop(dt)
			if st >= float(def.get("recover", 0.55)):
				cd = def.get("cd", 0.35)
				set_state("chase")
		_:
			set_state("chase")


func _ai_charger(dt: float, p: Player, dist: float) -> void:
	match state:
		"chase":
			_go(chase_pos(p, dt), def.get("speed", 4.0), dt)
			play("run", 0.2)
			if dist < 6.5 and cd <= 0.0 and _los:
				set_state("windup")
		"windup":
			_stop(dt)
			face(p.global_position)
			play("idle", 0.1)
			if model:
				model.position.x = sin(st * 60.0) * 0.04
			if st >= float(def.get("windup", 0.45)):
				if model:
					model.position.x = 0.0
				dash_dir = fwd()
				set_state("dash")
				play("run", 0.05, 1.8)
				Snd.sfx("dash", -8.0, 1.0, 0.2)
		"dash":
			var sp: float = def.get("dash", 10.0)
			velocity.x = dash_dir.x * sp
			velocity.z = dash_dir.z * sp
			if not hit_once and _strike(p, 0.3):
				hit_once = true
			if is_on_wall() and st > 0.08:
				_on_wall_hit()
			elif st >= 0.6:
				set_state("recover")
		"recover":
			_stop(dt, 20.0)
			play("idle", 0.2)
			if st >= float(def.get("recover", 0.8)):
				cd = def.get("cd", 1.0)
				set_state("chase")
		_:
			set_state("chase")


func _on_wall_hit() -> void:
	set_state("recover")
	st = -0.4
	if G.player and flat_dist(G.player.global_position) < 8.0:
		G.cam.shake(0.15)


func _ai_leaper(dt: float, p: Player, dist: float) -> void:
	match state:
		"chase":
			_go(chase_pos(p, dt), def.get("speed", 4.0), dt)
			play("walk", 0.2, 1.3)
			if dist < 6.5 and dist > 1.5 and cd <= 0.0 and is_on_floor() and _los:
				set_state("windup")
			elif dist <= 1.5 and cd <= 0.0 and _los:
				set_state("bite")
				play("attack", 0.08, 1.2, true)
		"bite":
			_stop(dt)
			face(p.global_position)
			if st >= 0.35 and not hit_once:
				hit_once = true
				_strike(p)
			if st >= 0.8:
				cd = 0.5
				set_state("chase")
		"windup":
			_stop(dt)
			face(p.global_position)
			play("idle", 0.1)
			if model:
				model.scale.y = 1.0 - minf(st, 0.4) * 0.6
			if st >= float(def.get("windup", 0.4)):
				if model:
					model.scale.y = 1.0
				var d := p.global_position - global_position
				var tt := 0.62
				velocity = Vector3(d.x / tt, gravity * tt * 0.5 + d.y / tt, d.z / tt)
				set_state("leap")
				play("jump", 0.05, 1.0, true)
		"leap":
			if st > 0.12 and is_on_floor():
				_strike(p, 0.6)
				Fx.dust(get_parent(), global_position)
				set_state("recover")
		"recover":
			_stop(dt)
			play("idle", 0.2)
			if st >= float(def.get("recover", 0.9)):
				cd = def.get("cd", 1.2)
				set_state("chase")
		_:
			set_state("chase")


func _ai_flyer(dt: float, p: Player, dist: float, shooter: bool) -> void:
	var base_y := p.global_position.y
	match state:
		"chase":
			_hover(dt, base_y)
			if shooter:
				var want := 7.0
				var dir := (global_position - p.global_position)
				dir.y = 0.0
				dir = dir.normalized() if dir.length() > 0.1 else Vector3.FORWARD
				var side := dir.cross(Vector3.UP) * sin(fly_phase * 0.4) * 3.0
				var tgt := chase_pos(p, dt)
				_go((p.global_position + dir * want + side) if _los else tgt, def.get("speed", 4.0), dt, false)
				face(p.global_position)
				play("idle", 0.2)
				if cd <= 0.0 and dist < float(def.get("reach", 9.0)) + 2.0 and _los:
					set_state("aim")
			else:
				_go(chase_pos(p, dt), def.get("speed", 4.0), dt)
				play("run", 0.2)
				if dist < 3.2 and cd <= 0.0 and _los:
					set_state("windup")
					play("attack", 0.1, 1.0, true)
		"aim":
			_stop(dt)
			_hover(dt, base_y)
			face(p.global_position)
			if st > 0.15 and not hit_once:
				hit_once = true
				model.flash(Color(1, 0.9, 0.3), 0.6)
			if st >= 0.5:
				var from := center() + fwd() * 0.5
				var v := (p.center() - from).normalized() * float(def.get("shot_speed", 10.0))
				Shot.fire(get_parent(), def.get("shot", "bolt"), from, v, def.get("dmg", 8), "enemy")
				play("shoot", 0.05, 1.0, true)
				Snd.sfx("shoot", -8.0, 1.0, 0.2)
				cd = def.get("cd", 2.0)
				set_state("chase")
		"windup":
			_stop(dt)
			face(p.global_position)
			velocity.y = 1.2
			if st >= float(def.get("windup", 0.45)):
				dash_dir = (p.center() - global_position).normalized()
				set_state("dive")
		"dive":
			velocity = dash_dir * 9.5
			if not hit_once and _strike(p, 0.3):
				hit_once = true
			if st >= 0.45 or (is_on_floor() and st > 0.1):
				set_state("recover")
		"recover":
			_stop(dt)
			_hover(dt, base_y)
			play("idle", 0.2)
			if st >= float(def.get("recover", 0.8)):
				cd = def.get("cd", 0.8)
				set_state("chase")
		_:
			set_state("chase")


func _ai_shooter(dt: float, p: Player, dist: float) -> void:
	match state:
		"chase":
			var tgt := chase_pos(p, dt)
			if dist > 9.0 or not _los:
				_go(tgt, def.get("speed", 3.5), dt)
				play("walk", 0.2)
			elif dist < 4.0:
				_go(global_position + (global_position - p.global_position), def.get("speed", 3.5), dt, false)
				face(p.global_position)
				play("walk", 0.2)
			else:
				_stop(dt)
				face(p.global_position)
				play("idle", 0.2)
			if cd <= 0.0 and dist < 12.0 and _los:
				set_state("aim")
				play("shoot", 0.1, 1.0, true)
		"aim":
			_stop(dt)
			face(p.global_position)
			if st >= 0.45:
				var from := center() + fwd() * 0.5
				var v := (p.center() - from).normalized() * float(def.get("shot_speed", 10.0))
				Shot.fire(get_parent(), def.get("shot", "bolt"), from, v, def.get("dmg", 8), "enemy")
				Snd.sfx("shoot", -8.0, 1.0, 0.2)
				cd = def.get("cd", 2.0)
				set_state("chase")
		_:
			set_state("chase")


# ---------- урон и смерть ----------

func hurt(dmg: float, from: Vector3, kb := 3.0, how := "melee") -> bool:
	if dead or not hittable:
		return false
	var m := guard
	if how == "spray":
		m *= float(def.get("weak_spray", 0.4))
	dmg *= m
	hp -= dmg
	if model:
		model.flash()
	if how != "spray" or randf() < 0.3:
		Fx.text(get_parent(), global_position + Vector3(0, height + 0.3, 0), str(int(round(dmg))), Color(1, 0.9, 0.3) if dmg >= 20.0 else Color.WHITE, 0.6 if dmg < 20.0 else 0.85)
	if not aggro:
		aggro = true
		if state == "idle":
			set_state("chase")
	_update_bar()
	if hp <= 0.0:
		die()
		return true
	_on_hurt(dmg, from, kb, how)
	return true


func _on_hurt(_dmg: float, from: Vector3, kb: float, how: String) -> void:
	var d := global_position - from
	d.y = 0.0
	d = d.normalized() if d.length() > 0.05 else Vector3.ZERO
	if not def.get("armor", false):
		kb_v = d * kb * (0.5 if how == "spray" else 1.0)
		if how in ["melee", "shot"] and state in ["chase", "recover", "idle", "return"]:
			play("hit", 0.05, 1.3, true)
	if how == "ult":
		stun(2.4)
	elif how == "spray" and float(def.get("weak_spray", 0.4)) > 1.0:
		stun(0.45)


func stun(sec: float) -> void:
	if def.get("no_stun", false):
		return
	stun_t = maxf(stun_t, sec)
	set_state("stun")
	if model:
		model.position.x = 0.0
		model.scale.y = 1.0
	play("hit", 0.1, 0.6)
	if _stars == null:
		_stars = Label3D.new()
		_stars.text = "* * *"
		_stars.font = UI.font_big()
		_stars.font_size = 48
		_stars.pixel_size = 0.008
		_stars.modulate = Color(1, 0.9, 0.3)
		_stars.outline_size = 8
		_stars.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		_stars.position.y = height + 0.55
		add_child(_stars)
	_stars.visible = true


func die(silent := false) -> void:
	if dead:
		return
	dead = true
	hp = 0.0
	_update_bar()
	if _stars:
		_stars.visible = false
	collision_layer = 0
	G.ents.erase(self)
	if not silent:
		G.save["kills"] = int(G.save["kills"]) + 1
		play("death", 0.08, 1.0, true)
		Snd.sfx("die", -6.0, 1.0, 0.2)
		_drop()
		if G.player:
			G.player.add_rage(4.0)
	if on_death.is_valid():
		on_death.call()
	_dead_t = 0.0
	if silent:
		queue_free()


func _drop() -> void:
	var m: Array = def.get("money", [1, 3])
	var total := randi_range(m[0], m[1])
	var n := clampi(total, 0, 3)
	if G.level == null:
		return
	for i in n:
		var amt := total / n + (total % n if i == 0 else 0)
		var pk := G.level.cash(global_position + Vector3(0, 0.6, 0), amt)
		pk.toss()
	if randf() < float(def.get("food", 0.07)):
		var pk2 := G.level.pickup(["bread", "banana", "doshik"][randi() % 3], global_position + Vector3(0, 0.6, 0))
		pk2.toss()
	if def.get("puddle", false) and G.level.has_method("add_puddle"):
		G.level.call("add_puddle", global_position)


func _dead_tick(dt: float) -> void:
	_dead_t += dt
	velocity.x = move_toward(velocity.x, 0.0, 20.0 * dt)
	velocity.z = move_toward(velocity.z, 0.0, 20.0 * dt)
	if gravity == 0.0:
		velocity.y -= 14.0 * dt
	elif not is_on_floor():
		velocity.y -= gravity * dt
	move_and_slide()
	if _dead_t > 1.3 and model:
		model.scale = model.scale.move_toward(Vector3.ONE * 0.01, dt * 2.2)
	if _dead_t > 1.9:
		queue_free()
