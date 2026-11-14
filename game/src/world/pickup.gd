class_name Pickup
extends Node3D
## Подбираемое: деньги («котлета»), еда, сюжетные вещи. Крутится, притягивается к игроку.

const LOOK := {
	"cash": {"box": Vector3(0.3, 0.12, 0.18), "col": Color(0.3, 0.75, 0.32)},
	"bread": {"box": Vector3(0.34, 0.16, 0.2), "col": Color(0.78, 0.55, 0.28)},
	"banana": {"box": Vector3(0.34, 0.1, 0.1), "col": Color(1.0, 0.86, 0.2)},
	"doshik": {"box": Vector3(0.3, 0.14, 0.24), "col": Color(0.95, 0.95, 0.9)},
	"milk": {"box": Vector3(0.16, 0.34, 0.16), "col": Color(0.96, 0.97, 1.0)},
	"shawa": {"box": Vector3(0.14, 0.36, 0.14), "col": Color(0.9, 0.78, 0.55)},
	"plums": {"box": Vector3(0.22, 0.22, 0.22), "col": Color(0.45, 0.2, 0.6)},
	"energy": {"box": Vector3(0.13, 0.3, 0.13), "col": Color(0.1, 0.8, 0.3)},
	"kvass": {"box": Vector3(0.15, 0.36, 0.15), "col": Color(0.5, 0.3, 0.12)},
	"chain": {"prop": "rpg/Necklace1", "h": 0.45},
	"tasty": {"prop": "rpg/Heart", "h": 0.42},
	"spray": {"box": Vector3(0.14, 0.4, 0.14), "col": Color(0.85, 0.15, 0.12)},
	"kicks": {"box": Vector3(0.34, 0.16, 0.16), "col": Color(0.3, 0.5, 1.0)},
	"key_dorm": {"prop": "rpg/Key1", "h": 0.4},
	"note_dorm": {"prop": "rpg/Parchment", "h": 0.4},
	"parcel": {"prop": "village/Package_1", "h": 0.45},
	"fuse": {"box": Vector3(0.1, 0.3, 0.1), "col": Color(0.9, 0.7, 0.2)},
	"handle": {"prop": "plat/Lever", "h": 0.45},
	"wood": {"prop": "nature/WoodLog", "h": 0.3},
	"broom": {"box": Vector3(0.12, 0.6, 0.12), "col": Color(0.3, 0.5, 0.2)},
	"candle": {"prop": "dung/Candle", "h": 0.4},
	"chip": {"prop": "rpg/Coin_Star", "h": 0.38},
}

var item := ""
var n := 1
var t := 0.0
var vel := Vector3.ZERO
var flying := false
var rest_y := 0.0
var vis: Node3D
var label: Label3D
var on_take: Callable
var magnet := 2.3
var taken := false
var delay := 0.0


func init(id: String, count := 1, o := {}) -> void:
	item = id
	n = count
	vis = Node3D.new()
	add_child(vis)
	var d: Dictionary = LOOK.get(id, {})
	if id.begins_with("btn"):
		_box(Vector3(0.3, 0.12, 0.3), Color(1.0, 0.82, 0.12), true)
	elif d.has("prop"):
		var sc: PackedScene = Level.prop_scene(d["prop"])
		var node: Node3D = sc.instantiate()
		var a := Level.prop_aabb(d["prop"])
		var s := float(d["h"]) / maxf(maxf(a.size.x, a.size.y), 0.001)
		node.scale = Vector3.ONE * s
		node.position = -(a.position + a.size * 0.5) * s
		vis.add_child(node)
	else:
		_box(d.get("box", Vector3(0.25, 0.25, 0.25)), d.get("col", Color(1, 0.8, 0.2)), id != "cash" and Items.DEFS.get(id, {}).get("kind", "") != "food")
	if id == "cash" and count >= 15:
		vis.scale = Vector3.ONE * 1.5
	if o.has("on_take"):
		on_take = o["on_take"]
	if id != "cash":
		label = Label3D.new()
		label.text = Items.name_of(id)
		label.font = UI.font_text()
		label.font_size = 40
		label.pixel_size = 0.005
		label.outline_size = 10
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		label.position.y = 0.55
		label.visible = false
		add_child(label)
	t = randf() * 6.0


func _box(size: Vector3, col: Color, glow: bool) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = Mats.glow(col, 1.6) if glow else Mats.flat(col, 0.5)
	vis.add_child(mi)
	if item == "cash":
		var band := MeshInstance3D.new()
		var b2 := BoxMesh.new()
		b2.size = Vector3(size.x * 0.25, size.y * 1.05, size.z * 1.05)
		band.mesh = b2
		band.material_override = Mats.flat(Color(0.95, 0.95, 0.85), 0.6)
		vis.add_child(band)


func _ready() -> void:
	rest_y = global_position.y


## Подбросить (выпало из врага или ящика).
func toss() -> void:
	flying = true
	delay = 0.35
	var a := randf() * TAU
	vel = Vector3(cos(a) * randf_range(1.0, 2.6), randf_range(3.5, 5.5), sin(a) * randf_range(1.0, 2.6))


func _physics_process(dt: float) -> void:
	t += dt
	delay = maxf(0.0, delay - dt)
	vis.rotation.y = t * 2.2
	vis.position.y = 0.0 if flying else sin(t * 2.6) * 0.08
	var p := G.player
	if flying:
		vel.y -= 16.0 * dt
		var np := global_position + vel * dt
		var space := get_world_3d().direct_space_state
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(global_position + Vector3(0, 0.2, 0), np - Vector3(0, 0.25, 0), 1))
		if not hit.is_empty() and vel.y < 0.0:
			global_position = (hit["position"] as Vector3) + Vector3(0, 0.35, 0)
			flying = false
		else:
			global_position = np
		if global_position.y < -50.0:
			queue_free()
	if p == null or p.dead or taken or delay > 0.0 or G.mode != "play":
		return
	var d := p.center().distance_to(global_position)
	if label:
		label.visible = d < 5.0
	var mg := magnet * (2.6 if G.has("magnet") and item == "cash" else 1.0)
	if d < mg and not flying:
		global_position = global_position.move_toward(p.center(), (6.0 + (mg - d) * 6.0) * dt)
	if d < 0.9:
		_take()


func _take() -> void:
	taken = true
	if item == "cash":
		G.pay(n)
		Snd.sfx("coin", -6.0, 1.0, 0.1)
	else:
		G.give(item, n)
	if on_take.is_valid():
		on_take.call()
	queue_free()
