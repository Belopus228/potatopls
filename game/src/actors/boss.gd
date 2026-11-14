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
	super._physics_process(dt)


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
		get_tree().create_timer(1.6, false).timeout.connect(func(): cb.call())


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
