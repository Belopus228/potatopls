class_name Boss
extends Enemy
## Основа босса: полоса здоровья на экране, «открытые» окна, фазы, торжественная гибель.

var phase := 1
var on_defeat: Callable
var arena := Vector3.ZERO           # центр арены
var arena_r := 12.0
var open_t := 0.0                   # сколько ещё босс «открыт» (получает полный урон)
var base_guard := 0.3
var music_after := ""
var rings: Array = []               # расходящиеся кольца по земле: их надо перепрыгивать
var ring_on := false
var ring_r := 0.0
var ring_c := Vector3.ZERO
var drops: Array = []               # отложенные удары по площади (красные круги)


func init_boss(nm: String, hp_total: float, mdl: Model, r: float, h: float) -> void:
	boss = true
	kind = nm
	title = nm
	def = {"name": nm, "no_stun": true, "armor": true, "money": [0, 0], "food": 0.0, "weak_spray": 1.0}
	model = mdl
	add_child(model)
	model.play("idle", 0.0)
	collision_layer = 4
	collision_mask = 1
	make_capsule(r, h)
	hp_max = hp_total
	hp = hp_total
	active = false
	leash = 9999.0
	guard = base_guard


## Начать бой.
func start() -> void:
	active = true
	aggro = true
	guard = base_guard
	G.ui.hud.set_boss(self)
	set_state("rest")


func _physics_process(dt: float) -> void:
	if open_t > 0.0 and not dead:
		open_t -= dt
		if open_t <= 0.0:
			guard = base_guard
			_on_closed()
	if not dead and G.mode == "play":
		_rings_tick(dt)
		_drops_tick(dt)
	super._physics_process(dt)


## Кольцо по земле от точки c: расходится со скоростью speed; кто не подпрыгнул — получает dmg.
func ring_start(c: Vector3, speed := 9.0, max_r := 22.0, dmg := 12.0, col := Color(0.6, 0.25, 1.0)) -> void:
	var mi := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.92
	tm.outer_radius = 1.0
	tm.rings = 40
	tm.ring_segments = 6
	mi.mesh = tm
	mi.material_override = Mats.glow(col, 3.0)
	get_parent().add_child(mi)
	mi.global_position = c + Vector3(0, 0.25, 0)
	mi.scale = Vector3(0.5, 0.6, 0.5)
	rings.append({"mesh": mi, "c": c, "r": 0.5, "speed": speed, "max": max_r, "dmg": dmg, "hit": false})
	ring_on = true
	ring_r = 0.5
	ring_c = c


func _rings_tick(dt: float) -> void:
	if rings.is_empty():
		ring_on = false
		return
	var p := G.player
	var best := 1e9
	ring_on = false
	for r in rings.duplicate():
		var rr: float = float(r["r"]) + dt * float(r["speed"])
		r["r"] = rr
		var mi: MeshInstance3D = r["mesh"]
		var c: Vector3 = r["c"]
		if rr > float(r["max"]) or not is_instance_valid(mi):
			if is_instance_valid(mi):
				mi.queue_free()
			rings.erase(r)
			continue
		mi.scale = Vector3(rr, 0.6, rr)
		var pd := Vector2(p.global_position.x - c.x, p.global_position.z - c.z).length()
		var dy := p.global_position.y - c.y
		if not r["hit"] and absf(pd - rr) < 0.7 and dy < 0.8 and dy > -2.0:
			if p.hurt(float(r["dmg"]), c, 7.0):
				r["hit"] = true
		ring_on = true
		if absf(pd - rr) < best:
			best = absf(pd - rr)
			ring_r = rr
			ring_c = c


func clear_rings() -> void:
	for r in rings:
		if is_instance_valid(r["mesh"]):
			(r["mesh"] as Node).queue_free()
	rings.clear()
	drops.clear()
	ring_on = false


## Удар по площади с задержкой: красный круг предупреждает, через delay секунд — взрыв.
func drop(pos: Vector3, r: float, delay: float, dmg: float, fx_col := Color(0.8, 0.9, 1.0), warn_col := Color(1, 0.2, 0.15, 0.45)) -> void:
	Fx.warn(get_parent(), pos, r, delay, warn_col)
	drops.append({"pos": pos, "r": r, "t": delay, "dmg": dmg, "col": fx_col})


func _drops_tick(dt: float) -> void:
	for d in drops.duplicate():
		d["t"] = float(d["t"]) - dt
		if float(d["t"]) <= 0.0:
			drops.erase(d)
			var pos: Vector3 = d["pos"]
			blast(pos, float(d["r"]), float(d["dmg"]), 8.0, 2.5)
			Fx.burst(get_parent(), pos + Vector3(0, 0.5, 0), d["col"], 12, 7.0)
			Fx.ring(get_parent(), pos + Vector3(0, 0.2, 0), d["col"], float(d["r"]), 0.25)
			Snd.sfx("crash", -7.0, 1.4)


## Выстрел(ы) в игрока: n снарядов веером с шагом spread (радианы).
func shoot(shot_kind: String, speed: float, dmg: float, n := 1, spread := 0.0, o := {}) -> void:
	var from := global_position + Vector3(0, height * 0.7, 0) + fwd() * (radius + 0.4)
	var base := (G.player.center() - from).normalized()
	for i in n:
		var a := (i - (n - 1) * 0.5) * spread
		Shot.fire(get_parent(), shot_kind, from, base.rotated(Vector3.UP, a) * speed, dmg, "enemy", o)


## Позвать подмогу: n врагов вокруг босса.
func summon(enemy_kind: String, n: int, r := 5.0, o := {}) -> void:
	var o2 := o.duplicate()
	o2["alert"] = true
	for i in n:
		var a := TAU * i / n + randf()
		var pos := clamp_arena(global_position + Vector3(cos(a), 0, sin(a)) * r, 1.5)
		pos.y = global_position.y + 0.3
		G.level.enemy(enemy_kind, pos, o2)
		Fx.puff(get_parent(), pos + Vector3(0, 0.5, 0), Color(0.9, 0.9, 0.9, 0.7), 6)


func clamp_arena(p: Vector3, margin := 2.0) -> Vector3:
	var d := p - arena
	d.y = 0.0
	d = d.limit_length(maxf(1.0, arena_r - margin))
	return Vector3(arena.x + d.x, p.y, arena.z + d.z)


## Возникнуть за спиной игрока.
func blink_behind(dist := 2.0) -> void:
	var p := G.player
	Fx.puff(get_parent(), center(), Color(0.5, 0.5, 0.6, 0.6), 10)
	var back := clamp_arena(p.global_position - p.fwd() * dist, 1.0)
	back.y = p.global_position.y
	global_position = back
	face(p.global_position)
	model.rotation.y = yaw
	Fx.puff(get_parent(), center(), Color(0.5, 0.5, 0.6, 0.6), 10)


## Открыться: sec секунд босс получает полный урон.
func open(sec: float, text := "ОТКРЫЛСЯ! БЕЙ!") -> void:
	open_t = sec
	guard = 1.0
	if text != "":
		Fx.text(get_parent(), global_position + Vector3(0, height + 0.6, 0), text, Color(1, 0.85, 0.2), 1.1)
	Snd.sfx("open", -3.0)


func _on_closed() -> void:
	pass


func hurt(dmg: float, from: Vector3, kb := 3.0, how := "melee") -> bool:
	if not active:
		return false
	var before := hp
	var res := super.hurt(dmg, from, 0.0, how)
	if res and guard < 0.99 and before - hp < dmg * 0.5 and randf() < 0.25 and how == "melee":
		Fx.text(get_parent(), global_position + Vector3(0, height + 0.2, 0), "слабо!", Color(0.7, 0.7, 0.7), 0.6)
	return res


func _on_hurt(_dmg: float, _from: Vector3, _kb: float, _how: String) -> void:
	_check_phase()


func _check_phase() -> void:
	pass


func die(silent := false) -> void:
	if dead:
		return
	dead = true
	hp = 0.0
	collision_layer = 0
	G.ents.erase(self)
	if silent:
		queue_free()
		return
	G.save["kills"] = int(G.save["kills"]) + 1
	clear_rings()
	G.ui.hud.set_boss(null)
	play("death", 0.1, 0.7, true)
	Snd.sfx("boss_die", 0.0)
	G.cam.shake(0.8)
	for e in G.ents.duplicate():
		if is_instance_valid(e) and not e.boss:
			e.die()
	for i in 8:
		Fx.burst(get_parent(), center() + Vector3(randf_range(-1, 1), randf_range(0, 1.5), randf_range(-1, 1)), Color(1, 0.85, 0.2), 10, 7.0)
	_dead_t = -2.0
	if on_defeat.is_valid():
		var cb := on_defeat
		get_tree().create_timer(1.6, false).timeout.connect(func():
			if cb.is_valid():   # уровень могли сменить, пока шла анимация гибели
				cb.call())


## Пауза между атаками: шагать к игроку, держась лицом к нему.
func rest_walk(dt: float, speed: float, keep := 3.0) -> void:
	var p := G.player
	var d := flat_dist(p.global_position)
	face(p.global_position)
	if d > keep:
		_go(p.global_position, speed, dt, false)
		play("walk", 0.25)
	else:
		_stop(dt)
		play("idle", 0.25)


func player_dist() -> float:
	return flat_dist(G.player.global_position)


## Удар по области вокруг точки.
func blast(pos: Vector3, r: float, dmg: float, kb := 8.0, max_dy := 1.6) -> bool:
	var p := G.player
	if p.dead:
		return false
	var d := p.global_position - pos
	if Vector2(d.x, d.z).length() < r + p.radius and absf(d.y) < max_dy:
		return p.hurt(dmg, pos, kb)
	return false
