extends Node
## Точка входа: создаёт мир (контейнер уровня, игрок, камера) и интерфейс, затем G.boot() решает, что грузить.


func _ready() -> void:
	G.main = self
	var world := Node3D.new()
	world.name = "World"
	add_child(world)
	G.world = world
	var p := Player.new()
	world.add_child(p)
	G.player = p
	var c := CamRig.new()
	world.add_child(c)
	G.cam = c
	var ui := UI.new()
	ui.name = "UI"
	add_child(ui)
	G.ui = ui
	G.boot.call_deferred()
