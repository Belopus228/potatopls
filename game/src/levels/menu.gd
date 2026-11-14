extends Level
## Фон главного меню: ночной двор в Мурино, герой на корточках, камера медленно облетает сцену.

var ang := 0.6


func build() -> void:
	music = "menu"
	set_env("night")
	slab(-60, -60, 60, 60, 0.0, "asphalt_wet", 1.0)
	slab(-7, -30, 7, 30, 0.03, "asphalt", 0.06, {"col": false})
	for i in 9:
		box(Vector3(0, 0.07, -24 + i * 6.0), Vector3(0.25, 0.02, 2.4), "white", {"col": false})
	building(Vector3(-24, 0, -20), Vector3(26, 46, 14), "facade_panel")
	building(Vector3(22, 0, -26), Vector3(22, 58, 14), "facade_new")
	building(Vector3(-30, 0, 12), Vector3(14, 34, 30), "facade_brick")
	building(Vector3(34, 0, 10), Vector3(16, 70, 26), "facade_panel")
	building(Vector3(0, 0, -52), Vector3(60, 80, 12), "facade_new")
	for x in [-9.0, 9.0]:
		for z in [-18.0, -4.0, 10.0]:
			post(Vector3(x, 0, z), 90.0 if x < 0 else -90.0)
	# ларёк
	box(Vector3(11.5, 1.4, 1.5), Vector3(3.2, 2.8, 2.6), "metal_dark")
	box(Vector3(11.5, 2.95, 1.5), Vector3(3.6, 0.3, 3.0), "red", {"col": false})
	txt("ШАВЕРМА", Vector3(9.85, 2.5, 1.5), -90.0, 0.55, {"col": Color(1.0, 0.75, 0.2), "glow": 2.0})
	box(Vector3(9.87, 1.6, 1.5), Vector3(0.05, 0.9, 1.8), Mats.glow(Color(1.0, 0.85, 0.5), 2.0), {"col": false})
	lamp(Vector3(9.0, 2.0, 1.5), Color(1.0, 0.8, 0.45), 3.0, 9.0)
	txt("МУРИНО — ЭТО\nНЕ ЖМУРИНО!", Vector3(-10.9, 9.0, -13.0), 90.0, 1.5, {"col": Color(0.4, 0.85, 1.0), "glow": 2.2})
	for p in [Vector3(-3.5, 0, -8), Vector3(4.5, 0, -14), Vector3(-5, 0, 9)]:
		prop("street/TrafficLight", p, 0.0, 1.0, {"h": 3.4})
	prop("home/Trashcan_Large", Vector3(8.2, 0, 4.2), 20.0, 1.0, {"h": 1.2})
	cp("start", Vector3(0, 0.05, 0), 0.0)


func begin(_cp: String) -> void:
	G.player.anim_lock = "Squat"
	G.player.set_yaw(PI * 0.9)
	Menus.main(G.ui)
	tick(_orbit)
	_orbit(0.0)


func _orbit(dt: float) -> void:
	ang += dt * 0.07
	var c := Vector3(1.2, 1.0, 0.0)
	G.cam.shot(c + Vector3(sin(ang) * 5.2 + 1.0, 1.1 + sin(ang * 0.7) * 0.25, cos(ang) * 5.2), c, 46.0)
