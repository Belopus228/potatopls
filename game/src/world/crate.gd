class_name Crate
extends StaticBody3D
## Ящик: ломается ударом, из него выпадает добыча. loot: [["cash", 8], ["doshik", 1], …]

var loot: Array = []
var hp := 18.0
var dead := false
var vis: Node3D
var on_break: Callable
var size := 0.9


func init(l: Array, o := {}) -> void:
	loot = l
	hp = o.get("hp", 18.0)
	size = o.get("size", 0.9)
	collision_layer = 1
	collision_mask = 0
	var key: String = o.get("prop", "village/Crate")
	var a := Level.prop_aabb(key)
	var s := size / maxf(a.size.y, 0.001)
	vis = Level.prop_scene(key).instantiate()
	vis.scale = Vector3.ONE * s
	vis.position = Vector3(-(a.position.x + a.size.x * 0.5) * s, -a.position.y * s, -(a.position.z + a.size.z * 0.5) * s)
	add_child(vis)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = a.size * s
	cs.shape = bs
	cs.position.y = a.size.y * s * 0.5
	add_child(cs)
	if o.has("on_break"):
		on_break = o["on_break"]
	if o.get("cross", false):
		var l3 := Label3D.new()
		l3.text = "+"
		l3.font = UI.font_big()
		l3.font_size = 160
		l3.pixel_size = 0.0026
		l3.modulate = Color(0.9, 0.1, 0.1)
		l3.outline_size = 24
		l3.outline_modulate = Color.WHITE
		l3.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l3.position.y = size + 0.35
		add_child(l3)


func _ready() -> void:
	G.breakables.append(self)


func _exit_tree() -> void:
	G.breakables.erase(self)


func hurt(dmg: float, _from: Vector3) -> void:
	if dead:
		return
	hp -= dmg
	var tw := create_tween()
	tw.tween_property(vis, "scale", vis.scale * 0.9, 0.05)
	tw.tween_property(vis, "scale", vis.scale, 0.08)
	Snd.sfx("crate", -6.0, 1.0, 0.15)
	if hp <= 0.0:
		_break()


func _break() -> void:
	dead = true
	G.breakables.erase(self)
	Fx.burst(get_parent(), global_position + Vector3(0, 0.5, 0), Color(0.6, 0.42, 0.24), 14, 5.5)
	Snd.sfx("break", -3.0)
	if G.level:
		for it in loot:
			var pk := G.level.pickup(it[0], global_position + Vector3(0, 0.6, 0), int(it[1]) if it.size() > 1 else 1)
			pk.toss()
	if on_break.is_valid():
		on_break.call()
	queue_free()
