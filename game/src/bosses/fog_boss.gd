class_name FogBoss
extends Boss
## ФОГ — туман над Мурино. Лицо в тумане недосягаемо: бить можно только ладонь, пока она застряла в асфальте.
## Ладонь бьёт по красному кругу; ФОГ выдыхает кольца (перепрыгни), сыплет сгустки, втягивает к пасти —
## крикни «АМ-АМ-АМ» во время вдоха, и он подавится.

const HOVER := 9.0
const SEQ1 := ["slam", "rings", "slam", "drops", "slam", "inhale"]
const SEQ2 := ["slam", "rings", "drops", "slam", "inhale"]

var head: Node3D
var mouth: MeshInstance3D
var eyes: Array = []
var palm: Node3D
var palm_mat: StandardMaterial3D
var cycle := 0
var slams_left := 0
var rings_left := 0
var drops_left := 0
var tick_t := 0.0
var summoned := 0
var target := Vector3.ZERO
var ground := 0.0
var fog_d := 0.03                   # желаемая плотность тумана: уровень плавно подводит к ней
var mouth_at := Vector3.ZERO        # точка на земле под пастью


func _init() -> void:
	var m := Model.creature("rat", 0.2, {})
	init_boss("ФОГ", 1500.0, m, 1.6, 1.4)
	m.visible = false
	base_guard = 0.25
	guard = 0.25
	gravity = 0.0
	hittable = false
	arena_r = 20.0
	def["weak_spray"] = 0.6
	palm_mat = StandardMaterial3D.new()
	palm_mat.albedo_color = Color(0.84, 0.87, 0.93, 0.94)
	palm_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	palm_mat.roughness = 1.0
	palm_mat.emission_enabled = true
	palm_mat.emission = Color(0.7, 0.75, 0.9)
	palm_mat.emission_energy_multiplier = 0.35
	palm = Node3D.new()
	add_child(palm)
	var parts := [[Vector3(0, 0.6, 0.4), Vector3(3.2, 1.2, 3.0)], [Vector3(2.1, 0.5, 0.5), Vector3(1.3, 0.8, 0.8)]]
	for i in 4:
		parts.append([Vector3(-1.2 + i * 0.8, 0.5, -2.1), Vector3(0.64, 0.9, 2.1)])
	for q in parts:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = q[1]
		mi.mesh = bm
		mi.material_override = palm_mat
		mi.position = q[0]
		palm.add_child(mi)


## Лицо в тумане: ставит уровень, когда знает, где арена.
func make_head(level: Node3D, at: Vector3) -> void:
	head = Node3D.new()
	level.add_child(head)
	head.position = at
	mouth_at = Vector3(at.x, 0.0, at.z + 6.0)
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.86, 0.89, 0.94, 0.92)
	fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fm.roughness = 1.0
	fm.emission_enabled = true
	fm.emission = Color(0.6, 0.65, 0.78)
	fm.emission_energy_multiplier = 0.45
	var skull := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 5.5
	sm.height = 12.5
	sm.radial_segments = 20
	sm.rings = 10
	skull.mesh = sm
	skull.material_override = fm
	skull.scale = Vector3(1.0, 1.0, 0.7)
	head.add_child(skull)
	var dark := Mats.flat(Color(0.02, 0.02, 0.04))
	for sx in [-1.0, 1.0]:
		var e := MeshInstance3D.new()
		var em := SphereMesh.new()
		em.radius = 1.15
		em.height = 2.8
		e.mesh = em
		e.material_override = dark
		e.position = Vector3(sx * 2.0, 1.3, 3.3)
		head.add_child(e)
		var pu := MeshInstance3D.new()
		var pm := SphereMesh.new()
		pm.radius = 0.34
		pm.height = 0.68
		pu.mesh = pm
		pu.material_override = Mats.glow(Color(1.0, 0.25, 0.2), 3.0)
		pu.position = Vector3(sx * 2.0, 1.2, 4.3)
		head.add_child(pu)
		eyes.append(pu)
	mouth = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(3.6, 1.0, 0.8)
	mouth.mesh = bm
	mouth.material_override = dark
	mouth.position = Vector3(0, -2.7, 3.5)
	head.add_child(mouth)
	head.scale = Vector3.ONE * 0.01


func rise_up() -> void:
	if head:
		var tw := head.create_tween()
		tw.tween_property(head, "scale", Vector3.ONE, 1.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func start() -> void:
	super.start()
	ground = arena.y
	hittable = false


func _check_phase() -> void:
	if phase == 1 and hp < hp_max * 0.5:
		phase = 2
		cycle = 0
		fog_d = 0.05
		_shout("ТУМАН СГУЩАЕТСЯ!", Color(1, 0.4, 0.35), 1.3)
		Snd.sfx("roar", 0.0, 0.7)
		G.cam.shake(0.8)
		for pu in eyes:
			(pu as MeshInstance3D).scale = Vector3.ONE * 1.7


func _shout(text: String, col := Color(0.9, 0.92, 1.0), size := 1.1) -> void:
	var at: Vector3 = head.global_position + Vector3(0, -5.0, 5.0) if head else global_position + Vector3(0, 3, 0)
	Fx.text(get_parent(), at, text, col, size)


func _on_hurt(dmg: float, from: Vector3, kb: float, how: String) -> void:
	palm_mat.emission_energy_multiplier = 2.6
	super._on_hurt(dmg, from, kb, how)


func _summon_due() -> bool:
	return (summoned == 0 and hp < hp_max * 0.72) or (summoned == 1 and hp < hp_max * 0.36)


func _hover_to(to: Vector3, dt: float, k := 3.0) -> void:
	var want := Vector3(to.x, ground + HOVER, to.z)
	var d := want - global_position
	velocity = d * k
	velocity = velocity.limit_length(26.0)


func _ai(dt: float) -> void:
	var p := G.player
	palm_mat.emission_energy_multiplier = move_toward(palm_mat.emission_energy_multiplier, 0.35, dt * 5.0)
	if head:
		var hd := p.global_position - head.global_position
		head.rotation.y = lerp_angle(head.rotation.y, atan2(hd.x, hd.z), clampf(dt * 2.5, 0.0, 1.0))
		head.position.y += sin(G.level.t * 1.3) * dt * 0.5
	if p.dead:
		_hover_to(arena, dt)
		return
	match state:
		"rest":
			hittable = false
			_hover_to(p.global_position + Vector3(0, 0, -5.0), dt, 1.6)
			if st > (1.5 if phase == 1 else 1.0):
				if _summon_due():
					set_state("summon")
				else:
					var seq: Array = SEQ1 if phase == 1 else SEQ2
					var what: String = seq[cycle % seq.size()]
					cycle += 1
					match what:
						"slam":
							slams_left = 1 if phase == 1 else 2
							set_state("slam_w")
						"rings":
							rings_left = 2 if phase == 1 else 3
							tick_t = 0.5
							set_state("rings")
							_shout("Х-Х-Х-Х…")
						"drops":
							drops_left = 8 if phase == 1 else 12
							tick_t = 0.3
							set_state("drops")
							_shout("ТУМАН ИДЁТ")
						_:
							set_state("inhale")
							_shout("ВДОХ…", Color(1, 0.5, 0.4), 1.3)
							Snd.sfx("roar", -2.0, 0.5)
		"slam_w":
			if st < 0.6:
				target = clamp_arena(p.global_position, 1.5)
				_hover_to(target, dt, 7.0)
			else:
				_hover_to(target, dt, 9.0)
				if not hit_once:
					hit_once = true
					Fx.warn(get_parent(), Vector3(target.x, ground, target.z), 3.5, 0.62)
					Snd.sfx("alert", -3.0, 0.6)
			if st >= 1.2:
				global_position.x = target.x
				global_position.z = target.z
				velocity = Vector3(0, -42.0, 0)
				set_state("slam")
		"slam":
			velocity = Vector3(0, -42.0, 0)
			if is_on_floor() or global_position.y <= ground + 0.05 or st > 1.0:
				velocity = Vector3.ZERO
				G.cam.shake(0.9)
				Snd.sfx("crash", 0.0, 0.6)
				Fx.dust(get_parent(), global_position + Vector3(0, 0.4, 0))
				Fx.ring(get_parent(), global_position + Vector3(0, 0.2, 0), Color(0.85, 0.88, 0.95), 4.2, 0.3)
				blast(global_position, 3.5, 24.0, 13.0, 3.0)
				slams_left -= 1
				if slams_left > 0:
					set_state("rise")
				else:
					set_state("stuck")
					hittable = true
					open(2.9 if phase == 1 else 2.5, "ЛАДОНЬ ЗАСТРЯЛА! БЕЙ!")
		"stuck":
			velocity = Vector3.ZERO
			palm.rotation.z = sin(st * 14.0) * 0.04
			if open_t <= 0.0:
				palm.rotation.z = 0.0
				hittable = false
				set_state("rise")
		"rise":
			hittable = false
			velocity = Vector3(0, 15.0, 0)
			if global_position.y >= ground + HOVER - 0.5:
				velocity = Vector3.ZERO
				set_state("slam_w" if slams_left > 0 else "rest")
		"rings":
			_hover_to(mouth_at + Vector3(7, 0, 2), dt, 2.0)
			tick_t -= dt
			if tick_t <= 0.0 and rings_left > 0:
				tick_t = 1.25 if phase == 1 else 1.0
				rings_left -= 1
				ring_start(Vector3(mouth_at.x, ground, mouth_at.z), 9.5 if phase == 1 else 11.0, 48.0, 14.0, Color(0.85, 0.9, 1.0))
				Snd.sfx("spray", -2.0, 0.5)
				G.cam.shake(0.3)
			if rings_left <= 0 and tick_t <= 0.0:
				set_state("rest")
		"drops":
			_hover_to(p.global_position + Vector3(0, 0, -7.0), dt, 1.5)
			tick_t -= dt
			if tick_t <= 0.0 and drops_left > 0:
				tick_t = 0.3 if phase == 1 else 0.22
				drops_left -= 1
				var lead := Vector3(p.velocity.x, 0, p.velocity.z) * 0.5
				var at := clamp_arena(p.global_position + lead + Vector3(randf_range(-3.5, 3.5), 0, randf_range(-3.5, 3.5)), 0.5)
				at.y = ground
				drop(at, 2.2, 0.95, 15.0, Color(0.85, 0.9, 1.0))
			if drops_left <= 0 and drops.is_empty():
				set_state("rest")
		"inhale":
			_hover_to(mouth_at + Vector3(-7, 0, 2), dt, 2.0)
			if mouth:
				mouth.scale = Vector3(1.0, 1.0 + minf(st, 0.6) * 4.0, 1.0)
			if st > 0.6:
				var to := mouth_at - p.global_position
				to.y = 0.0
				var dist := to.length()
				if p.state == "ult":
					_end_inhale()
					_choke()
					return
				if dist < 3.2:
					p.hurt(22.0, mouth_at, 15.0)
					_shout("АМ.", Color(1, 0.4, 0.35), 1.2)
					_end_inhale()
					set_state("rest")
					return
				p.move_and_collide(to.normalized() * (5.2 if phase == 1 else 6.0) * dt)
				if randf() < 0.3:
					Fx.puff(get_parent(), p.global_position + Vector3(randf_range(-2, 2), randf_range(0.5, 2), randf_range(-2, 2)), Color(0.85, 0.88, 0.95, 0.5), 2)
			if st > 3.4:
				_end_inhale()
				set_state("tired")
				global_position = Vector3(clamp_arena(mouth_at + Vector3(0, 0, 7.0), 2.0).x, ground + 0.02, clamp_arena(mouth_at + Vector3(0, 0, 7.0), 2.0).z)
				hittable = true
				open(2.2, "ЗАПЫХАЛСЯ! БЕЙ!")
		"tired":
			velocity = Vector3.ZERO
			if open_t <= 0.0:
				hittable = false
				set_state("rise")
		"summon":
			_hover_to(arena, dt, 2.0)
			if st > 0.5 and not hit_once:
				hit_once = true
				summoned += 1
				_shout("ПАКОСТИ! КО МНЕ!")
				Snd.sfx("roar", 0.0, 1.0)
				for i in (3 if summoned == 1 else 4):
					var a := TAU * i / 4.0 + randf()
					var pos := clamp_arena(p.global_position + Vector3(cos(a), 0, sin(a)) * 6.0, 2.0)
					pos.y = ground + 0.5
					G.level.enemy("imp" if (summoned == 1 or i < 2) else "gopnik2", pos, {"alert": true})
					Fx.puff(get_parent(), pos + Vector3(0, 0.5, 0), Color(0.9, 0.9, 0.95, 0.7), 8)
			if st > 1.4:
				set_state("rest")
		_:
			set_state("rest")


func _end_inhale() -> void:
	if mouth:
		mouth.scale = Vector3.ONE


func _choke() -> void:
	var p := G.player
	var at := clamp_arena(p.global_position + p.fwd() * 3.2, 2.0)
	global_position = Vector3(at.x, ground + 0.02, at.z)
	velocity = Vector3.ZERO
	G.cam.shake(0.9)
	Snd.sfx("crash", 0.0, 0.6)
	Fx.dust(get_parent(), global_position + Vector3(0, 0.4, 0))
	set_state("stuck")
	hittable = true
	open(4.2, "ПОДАВИЛСЯ! БЕЙ!")


func die(silent := false) -> void:
	_end_inhale()
	if head and not silent:
		var tw := head.create_tween()
		tw.tween_property(head, "scale", Vector3.ONE * 0.01, 2.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(head.queue_free)
	super.die(silent)
