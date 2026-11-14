class_name Fx
extends RefCounted
## Мелкие эффекты: всплывающий текст, кольцо, пыль, осколки, облако дихлофоса.

static var _quad: QuadMesh
static var _pmat := {}
static var _dot_tex: GradientTexture2D


## Мягкий кружок для частиц: без него снег, пыль и пар летели белыми квадратами.
static func _dot() -> Texture2D:
	if _dot_tex == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.85), Color(1, 1, 1, 0)])
		var t := GradientTexture2D.new()
		t.gradient = g
		t.width = 32
		t.height = 32
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		_dot_tex = t
	return _dot_tex


static func _particle_mesh(col: Color, size := 0.18) -> QuadMesh:
	var key := "%s|%.2f" % [col.to_html(), size]
	if _pmat.has(key):
		return _pmat[key]
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = col
	m.albedo_texture = _dot()
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	q.material = m
	_pmat[key] = q
	return q


static func text(parent: Node, pos: Vector3, s: String, col := Color.WHITE, size := 0.8) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var l := Label3D.new()
	l.text = s
	l.font = UI.font_big()
	l.font_size = 64
	l.pixel_size = 0.0065 * size
	l.modulate = col
	l.outline_size = 14
	l.outline_modulate = Color(0, 0, 0, 0.9)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.render_priority = 5
	parent.add_child(l)
	l.global_position = pos + Vector3(randf_range(-0.25, 0.25), 0, randf_range(-0.25, 0.25))
	var tw := l.create_tween().set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y + 1.1, 0.75).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(l, "modulate:a", 0.0, 0.3).set_delay(0.45)
	tw.chain().tween_callback(l.queue_free)


## Расходящееся кольцо на земле.
static func ring(parent: Node, pos: Vector3, col: Color, radius: float, time := 0.4) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var mi := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.9
	tm.outer_radius = 1.0
	tm.rings = 28
	tm.ring_segments = 6
	mi.mesh = tm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = col
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	mi.global_position = pos
	mi.scale = Vector3(0.3, 0.25, 0.3)
	var tw := mi.create_tween().set_parallel(true)
	tw.tween_property(mi, "scale", Vector3(radius, 0.25, radius), time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(m, "albedo_color:a", 0.0, time)
	tw.chain().tween_callback(mi.queue_free)


static func _burst(parent: Node, pos: Vector3, col: Color, n: int, speed: float, life: float, size: float, grav: float) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var p := CPUParticles3D.new()
	p.mesh = _particle_mesh(col, size)
	p.amount = n
	p.one_shot = true
	p.explosiveness = 0.95
	p.lifetime = life
	p.direction = Vector3.UP
	p.spread = 80.0
	p.initial_velocity_min = speed * 0.5
	p.initial_velocity_max = speed
	p.gravity = Vector3(0, -grav, 0)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.3
	p.emitting = true
	parent.add_child(p)
	p.global_position = pos
	p.get_tree().create_timer(life + 0.3).timeout.connect(p.queue_free)


static func dust(parent: Node, pos: Vector3) -> void:
	_burst(parent, pos + Vector3(0, 0.1, 0), Color(0.8, 0.8, 0.78, 0.5), 6, 1.6, 0.45, 0.3, 1.0)


static func burst(parent: Node, pos: Vector3, col: Color, n := 12, speed := 5.0) -> void:
	_burst(parent, pos, col, n, speed, 0.7, 0.16, 12.0)


static func puff(parent: Node, pos: Vector3, col: Color, n := 10) -> void:
	_burst(parent, pos, col, n, 2.2, 0.8, 0.45, -0.6)


static func spray_emitter() -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.mesh = _particle_mesh(Color(0.8, 1.0, 0.75, 0.5), 0.4)
	p.amount = 26
	p.lifetime = 0.5
	p.direction = Vector3(0, 0, -1)
	p.spread = 22.0
	p.initial_velocity_min = 7.0
	p.initial_velocity_max = 10.0
	p.gravity = Vector3(0, 0.5, 0)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.6
	p.emitting = false
	p.local_coords = false
	return p


## Постоянный источник частиц (пар, дым, снег, туман).
static func emitter(col: Color, amount: int, life: float, size: float, dir: Vector3, speed: float, spread := 30.0, grav := Vector3.ZERO, box := Vector3.ZERO) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.mesh = _particle_mesh(col, size)
	p.amount = amount
	p.lifetime = life
	p.direction = dir
	p.spread = spread
	p.initial_velocity_min = speed * 0.6
	p.initial_velocity_max = speed
	p.gravity = grav
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.4
	if box != Vector3.ZERO:
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		p.emission_box_extents = box
	p.preprocess = life
	return p


## Круг-предупреждение на земле (куда сейчас ударит босс).
static func warn(parent: Node, pos: Vector3, radius: float, time: float, col := Color(1, 0.2, 0.15, 0.45)) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 1.0
	cm.bottom_radius = 1.0
	cm.height = 0.04
	cm.radial_segments = 28
	mi.mesh = cm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = col
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	mi.global_position = pos + Vector3(0, 0.05, 0)
	mi.scale = Vector3(radius * 0.2, 1, radius * 0.2)
	var tw := mi.create_tween()
	tw.tween_property(mi, "scale", Vector3(radius, 1, radius), time)
	tw.tween_callback(mi.queue_free)
	return mi
