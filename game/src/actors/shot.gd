class_name Shot
extends Node3D
## Снаряд: котлета денег, мыльный пузырь, паутина, заряд дрона, туманный шар, снежок.

const KINDS := {
	"cash": {"col": Color(0.35, 0.8, 0.35), "size": Vector3(0.26, 0.1, 0.16), "grav": 5.0, "life": 1.6, "spin": 14.0},
	"bubble": {"col": Color(0.7, 0.9, 1.0, 0.6), "r": 0.32, "grav": 0.0, "life": 4.0},
	"web": {"col": Color(0.95, 0.95, 0.95), "r": 0.22, "grav": 6.0, "life": 3.0},
	"bolt": {"col": Color(1.0, 0.8, 0.2), "r": 0.14, "grav": 0.0, "life": 3.0, "glow": 3.0},
	"orb": {"col": Color(0.75, 0.8, 0.95), "r": 0.36, "grav": 0.0, "life": 5.0, "glow": 1.5},
	"dark": {"col": Color(0.5, 0.2, 0.9), "r": 0.3, "grav": 0.0, "life": 4.0, "glow": 2.5},
	"steam": {"col": Color(1.0, 0.75, 0.7, 0.7), "r": 0.4, "grav": -1.0, "life": 2.2},
	"snow": {"col": Color(0.95, 0.97, 1.0), "r": 0.2, "grav": 9.0, "life": 3.0},
	"sting": {"col": Color(0.2, 0.2, 0.1), "r": 0.1, "grav": 0.0, "life": 2.5},
	"chip": {"col": Color(0.9, 0.2, 0.25), "r": 0.18, "grav": 3.0, "life": 3.0, "spin": 10.0},
}

var kind := "cash"
var vel := Vector3.ZERO
var dmg := 10.0
var side := "player"
var life := 2.0
var grav := 0.0
var rad := 0.2
var spin := 0.0
var kb := 3.0
var mesh: MeshInstance3D
var home_t := 0.0          # самонаведение (сек), для шаров босса


static func fire(parent: Node, k: String, from: Vector3, v: Vector3, damage: float, sd: String, o := {}) -> Shot:
	var s := Shot.new()
	s.kind = k
	s.vel = v
	s.dmg = damage
	s.side = sd
	var d: Dictionary = KINDS[k]
	s.life = o.get("life", d["life"])
	s.grav = d["grav"]
	s.spin = d.get("spin", 0.0)
	s.kb = o.get("kb", 3.0)
	s.home_t = o.get("home", 0.0)
	s.mesh = MeshInstance3D.new()
	var col: Color = d["col"]
	if d.has("size"):
		var bm := BoxMesh.new()
		bm.size = d["size"]
		s.mesh.mesh = bm
		s.rad = 0.25
	else:
		var sm := SphereMesh.new()
		sm.radius = d["r"]
		sm.height = float(d["r"]) * 2.0
		sm.radial_segments = 10
		sm.rings = 6
		s.mesh.mesh = sm
		s.rad = d["r"]
	s.mesh.material_override = Mats.glow(col, d["glow"]) if d.has("glow") else Mats.flat(col, 0.4)
	s.mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	s.add_child(s.mesh)
	parent.add_child(s)
	s.global_position = from
	return s


func _physics_process(dt: float) -> void:
	life -= dt
	if life <= 0.0:
		_pop(false)
		return
	vel.y -= grav * dt
	if home_t > 0.0 and side == "enemy" and G.player and not G.player.dead:
		home_t -= dt
		var want := (G.player.center() - global_position).normalized() * vel.length()
		vel = vel.lerp(want, clampf(2.2 * dt, 0.0, 1.0))
	var from := global_position
	var to := from + vel * dt
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(from, to, 1)
	var hit := space.intersect_ray(q)
	if not hit.is_empty():
		global_position = hit["position"]
		_pop(true)
		return
	global_position = to
	if spin > 0.0:
		mesh.rotate_y(spin * dt)
		mesh.rotate_x(spin * 0.7 * dt)
	if side == "player":
		for e in G.ents.duplicate():
			if not is_instance_valid(e) or e.dead:
				continue
			if _near_capsule(e.global_position, e.radius, e.height):
				if e.hurt(dmg, from, kb, "shot"):
					Snd.sfx("hit", -5.0)
				_pop(true)
				return
		for c in G.breakables.duplicate():
			if is_instance_valid(c) and c.global_position.distance_to(to) < 0.8:
				c.hurt(dmg, from)
				_pop(true)
				return
	else:
		var p := G.player
		if p and not p.dead and _near_capsule(p.global_position, p.radius, p.height):
			if p.hurt(dmg, from, kb):
				if kind == "web":
					p.slow_t = 3.0
					G.toast("Паутина! Ты замедлен", "small")
				elif kind == "bubble":
					p.slip = 1.0
			_pop(true)


func _near_capsule(base: Vector3, r: float, h: float) -> bool:
	var p := global_position
	var y := clampf(p.y, base.y + r * 0.5, base.y + maxf(h - r * 0.5, r))
	return p.distance_to(Vector3(base.x, y, base.z)) < r + rad


func _pop(hit: bool) -> void:
	if hit:
		var d: Dictionary = KINDS[kind]
		Fx.burst(get_parent(), global_position, d["col"], 6, 3.0)
	queue_free()
