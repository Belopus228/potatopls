extends Level
## ГЛАВА 2 — МУРИНО. Двор-узел: Друн и шаверма, курьер и посылка в ГСК «Пакость», гигахрущёвка П-46
## с ливтом, Тёмный Друн на крыше, станция «поеза» в Молочное, Мытищи, Баньку и Жмурино.

const RY := 90.0                        # высота крыши П-46
const FLOORS := ["1", "9", "46", "404", "1989", "200К", "-1", "4 млн", "32"]

var drun: Npc
var courier: Npc
var boss: DarkDrun
var roof_gate: Array = []
var fog_wall: CollisionShape3D
var fog_vis: MeshInstance3D
var gop_alive := 0
var pigeons_left := 0
var gop_garage: Door


func build() -> void:
	title = "МУРИНО"
	chapter = "ГЛАВА 2"
	music = "murino"
	set_env("night")
	_ground()
	_p46()
	_yard()
	_garages()
	_station()
	_people()
	cp("start", Vector3(-64, 0.1, 0), -90)
	cp("lobby", Vector3(0, 0.1, 60), 0)
	cp("roof", Vector3(0, RY + 0.1, 66.5), 0)
	cp("station", Vector3(56, 1.0, -24), 90)


func _ground() -> void:
	slab(-110, -110, 110, 110, 0.0, "asphalt_wet", 1.0)
	slab(-52, -22, 52, 52, 0.03, "grass", 0.06, {"col": false})
	# дорожки
	slab(-70, -3, 52, 3, 0.05, "asphalt", 0.06, {"col": false})
	slab(-3, -30, 3, 62, 0.05, "asphalt", 0.06, {"col": false})
	slab(-3, 21, 30, 27, 0.05, "asphalt", 0.06, {"col": false})
	slab(52, -34, 56, 3, 0.05, "asphalt", 0.06, {"col": false})
	# дома вокруг (границы двора)
	building(Vector3(-92, 0, 10), Vector3(22, 66, 90), "facade_new")
	building(Vector3(-92, 0, -62), Vector3(22, 48, 40), "facade_brick")
	building(Vector3(92, 0, 30), Vector3(22, 78, 70), "facade_panel")
	building(Vector3(-56, 0, 76), Vector3(34, 60, 22), "facade_brick")
	building(Vector3(58, 0, 76), Vector3(36, 72, 22), "facade_new")
	building(Vector3(0, 0, -92), Vector3(150, 54, 16), "facade_panel")
	building(Vector3(96, 0, -70), Vector3(20, 40, 40), "facade_dark")
	txt("ЖК «ТУМАННЫЙ»", Vector3(-80.8, 14, 10), 90, 2.2, {"col": Color(0.6, 0.8, 1.0), "glow": 1.6})
	txt("МУРИНО — ЭТО\nНЕ ЖМУРИНО!", Vector3(0, 20, -83.8), 0, 3.2, {"col": Color(0.4, 0.9, 1.0), "glow": 1.8})
	# невидимые границы
	blocker(Vector3(-78, 5, 0), Vector3(1, 12, 180))
	blocker(Vector3(78, 5, 0), Vector3(1, 12, 180))
	blocker(Vector3(0, 5, -80), Vector3(180, 12, 1))
	blocker(Vector3(0, 5, 63.2), Vector3(180, 12, 0.6)).position.x = -93.5
	blocker(Vector3(93.5, 5, 63.2), Vector3(173, 12, 0.6))
	# фонари вдоль дорожек
	for x in [-62.0, -46.0, -30.0, -14.0, 14.0, 30.0, 46.0]:
		post(Vector3(x, 0, 4.4), 180)
	for z in [-26.0, -12.0, 16.0, 34.0, 50.0]:
		post(Vector3(4.4, 0, z), -90)
	for p in [Vector3(-20, 0, 30), Vector3(-36, 0, 22), Vector3(22, 0, 44), Vector3(40, 0, 14), Vector3(-44, 0, -14), Vector3(34, 0, -14)]:
		post(p, 0)


func _p46() -> void:
	# три блока: по бокам от пезда и над ним
	building(Vector3(-21, 0, 74), Vector3(28, RY, 22), "facade_panel")
	building(Vector3(21, 0, 74), Vector3(28, RY, 22), "facade_panel")
	building(Vector3(0, 3, 74), Vector3(14, RY - 3, 22), "facade_panel", {"col": false})
	blocker(Vector3(0, 3 + (RY - 3) * 0.5, 74), Vector3(14, RY - 3, 22))
	box(Vector3(0, 1.5, 80), Vector3(14, 3, 10), "concrete_dark")
	# вестибюль
	slab(-7, 63, 7, 75, 0.02, "tiles", 0.05, {"col": false})
	wall_gaps(-7, 63.15, 7, 63.15, 0, 3.0, "concrete", [[7.0, 2.2, 2.4]], 0.3)
	ceiling(-7, 63.3, 7, 75, 2.98)
	ceil_lamp(Vector3(0, 2.95, 69), Color(0.8, 0.95, 1.0), 2.4, 10.0)
	txt("П-46", Vector3(0, 4.3, 62.9), 180, 1.3, {"col": Color(1.0, 0.82, 0.12), "glow": 1.6})
	txt("ЭТАЖЕЙ: 200 000 · ЛИВТ РАБОТАЕТ (НЕТ)", Vector3(0, 3.25, 62.9), 180, 0.3, {"col": Color(0.9, 0.9, 0.9), "glow": 0.8})
	lamp(Vector3(0, 3.4, 61.5), Color(1.0, 0.85, 0.5), 2.6, 9.0)
	# ливт
	box(Vector3(0, 1.35, 74.8), Vector3(2.4, 2.7, 0.4), "metal", {"col": false})
	box(Vector3(0, 1.3, 74.58), Vector3(0.04, 2.5, 0.05), "black", {"col": false})
	txt("ЛИВТ", Vector3(0, 2.75, 74.55), 180, 0.26, {"col": Color(0.5, 0.9, 1.0), "glow": 1.5})
	box(Vector3(1.6, 1.3, 74.7), Vector3(0.3, 0.45, 0.1), Mats.glow(Color(1.0, 0.75, 0.2), 1.6), {"col": false})
	interact(Vector3(0.9, 1.1, 73.9), 2.2, "Вызвать ливт", _lift)
	# почтовые ящики, будка консьержа
	for i in 6:
		box(Vector3(-6.8, 1.0 + (i % 2) * 0.5, 65.2 + (i / 2) * 0.7), Vector3(0.2, 0.42, 0.6), "metal_dark", {"col": false})
	txt("КВ. 1 — 4 000 000", Vector3(-6.78, 2.2, 65.9), 90, 0.2, {"col": Color(0.85, 0.85, 0.85), "outline": 4})
	box(Vector3(5.3, 0.6, 67.5), Vector3(2.6, 1.2, 0.3), "wood_dark")
	box(Vector3(4.15, 0.6, 69.0), Vector3(0.3, 1.2, 3.0), "wood_dark")
	prop("home/Chair_2", Vector3(5.8, 0, 69.2), 200)
	txt("КОНСЬЕРЖ\nУШЁЛ В ТУМАН", Vector3(6.82, 2.0, 69.0), -90, 0.24, {"col": Color(1.0, 0.5, 0.4), "outline": 4})
	door(Vector3(0, 0, 63.15), 0, {"w": 2.2, "h": 2.4, "label": "Открыть «пезд»", "mat": "metal_dark",
		"locked": func(): return "" if G.has("pass_p46") or G.flag("m_boss") else "Домофон: «Предъявите пропуск в пезд»",
		"on_open": func():
			if String(G.save["cp"]) == "start":
				G.checkpoint("lobby")})
	# крыша
	for a in [[Vector3(0, RY + 2, 62.9), Vector3(72, 4, 0.5)], [Vector3(0, RY + 2, 85.1), Vector3(72, 4, 0.5)], [Vector3(-35.1, RY + 2, 74), Vector3(0.5, 4, 23)], [Vector3(35.1, RY + 2, 74), Vector3(0.5, 4, 23)]]:
		blocker(a[0], a[1])
	txt("МУРИНО", Vector3(0, RY + 3.4, 84.4), 180, 3.4, {"col": Color(0.5, 0.88, 1.0), "glow": 1.3, "dbl": true})
	lamp(Vector3(-9, RY + 2.6, 82), Color(0.5, 0.85, 1.0), 3.0, 18.0)
	lamp(Vector3(9, RY + 2.6, 82), Color(0.5, 0.85, 1.0), 3.0, 18.0)
	lamp(Vector3(0, RY + 3.0, 68), Color(0.8, 0.7, 1.0), 2.4, 16.0)
	for p in [Vector3(-20, RY, 80), Vector3(18, RY, 81), Vector3(-28, RY, 68), Vector3(27, RY, 67)]:
		prop("cyber/AC", p, rng.randf() * 360.0, 1.0, {"h": 1.3})
	prop("cyber/Antenna_2", Vector3(-31, RY, 82), 0, 1.0, {"h": 4.5})
	prop("cyber/Antenna_1", Vector3(31, RY, 80), 0, 1.0, {"h": 3.5})
	box(Vector3(0, RY + 1.3, 64.2), Vector3(3.0, 2.6, 1.6), "concrete_dark")
	txt("ЛИВТ", Vector3(0, RY + 2.9, 65.02), 0, 0.3, {"col": Color(0.5, 0.9, 1.0), "glow": 1.5})
	interact(Vector3(0, RY + 1.0, 65.6), 2.2, "Ливт вниз", func():
		await cut(func():
			await G.ui.fade_to(1.0, 0.4)
			G.player.place(Vector3(0, 0.1, 72.5), PI)
			G.cam.snap()
			await G.wait(0.3)
			await G.ui.fade_to(0.0, 0.4))
		_goal(), {"cond": func(): return G.flag("m_boss")})
	if not G.flag("m_boss"):
		boss = DarkDrun.new()
		add_child(boss)
		boss.global_position = Vector3(0, RY + 0.1, 78)
		boss.home = boss.global_position
		boss.arena = Vector3(0, RY, 74)
		boss.set_yaw(PI)
		boss.model.play("Dance", 0.0)
		boss.on_defeat = _boss_dead
		trigger(Vector3(0, RY + 1.5, 70.5), Vector3(12, 2.5, 2.0), _boss_intro)


func _bench(p: Vector3, yaw: float) -> void:
	box(p + Vector3(0, 0.45, 0), Vector3(1.8, 0.1, 0.5), "wood", {"yaw": yaw})
	box(p + Vector3(0, 0.8, 0).rotated(Vector3.UP, 0) + Basis.from_euler(Vector3(0, deg_to_rad(yaw), 0)) * Vector3(0, 0, -0.24), Vector3(1.8, 0.45, 0.08), "wood", {"yaw": yaw, "col": false})
	for sx in [-0.75, 0.75]:
		box(p + Basis.from_euler(Vector3(0, deg_to_rad(yaw), 0)) * Vector3(sx, 0.22, 0), Vector3(0.1, 0.44, 0.45), "metal_dark", {"yaw": yaw, "col": false})


func _kiosk(c: Vector3, yaw: float, name1: String, col: Color, sub := "") -> void:
	var b := Basis.from_euler(Vector3(0, deg_to_rad(yaw), 0))
	box(c + Vector3(0, 1.4, 0), Vector3(4.0, 2.8, 3.0), "metal_dark", {"yaw": yaw})
	box(c + Vector3(0, 2.95, 0), Vector3(4.6, 0.3, 3.6), col, {"yaw": yaw, "col": false})
	box(c + b * Vector3(0, 1.65, 1.52), Vector3(2.6, 1.0, 0.06), Mats.glow(Color(1.0, 0.88, 0.6), 1.5), {"yaw": yaw, "col": false})
	box(c + b * Vector3(0, 1.05, 1.75), Vector3(2.8, 0.1, 0.5), "metal", {"yaw": yaw, "col": false})
	txt(name1, c + b * Vector3(0, 3.55, 1.82), yaw, 0.5, {"col": col, "glow": 1.6})
	if sub != "":
		txt(sub, c + b * Vector3(0, 2.45, 1.56), yaw, 0.2, {"col": Color.WHITE, "glow": 0.6})
	lamp(c + b * Vector3(0, 2.2, 3.0), Color(1.0, 0.82, 0.5), 2.8, 10.0)


func _yard() -> void:
	# шаверма и магазин
	_kiosk(Vector3(-36, 0, 9), 180, "ШАВЕРМА У АШОТА", Color(1.0, 0.62, 0.2), "С МЯСОМ. КАКИМ — НЕ СПРАШИВАЙ")
	_kiosk(Vector3(-24, 0, -10), 0, "ПРОДУКТЫ 24", Color(0.4, 0.9, 0.5), "ВКУСНОСТИ · ЦЕПИ")
	prop("home/Table_RoundSmall", Vector3(-31.5, 0, 6.2), 0)
	prop("home/Stool", Vector3(-30.6, 0, 6.3), 0)
	prop("home/Trashcan_Large", Vector3(-39.5, 0, 6.4), 0, 1.0, {"h": 1.1})
	# детская площадка
	slab(-12, 8, 12, 22, 0.06, "sand", 0.06, {"col": false})
	for sx in [-8.0, 8.0]:
		for sz in [9.0, 21.0]:
			cyl(Vector3(sx, 0.2, sz), 0.12, 0.4, "yellow")
	# качели
	for sx in [-7.0, -4.2]:
		cyl(Vector3(sx, 1.4, 12), 0.07, 2.8, "red")
	cyl(Vector3(-5.6, 2.75, 12), 0.06, 3.0, "red", {"col": false}).rotation.z = PI * 0.5
	for sx in [-6.2, -5.0]:
		box(Vector3(sx, 0.55, 12), Vector3(0.5, 0.06, 0.25), "wood", {"col": false})
		box(Vector3(sx - 0.2, 1.65, 12), Vector3(0.02, 2.2, 0.02), "metal", {"col": false})
		box(Vector3(sx + 0.2, 1.65, 12), Vector3(0.02, 2.2, 0.02), "metal", {"col": false})
	# горка
	box(Vector3(6, 1.0, 17.5), Vector3(1.6, 0.12, 1.6), "wood")
	for o in [Vector3(-0.7, 0, -0.7), Vector3(0.7, 0, -0.7), Vector3(-0.7, 0, 0.7), Vector3(0.7, 0, 0.7)]:
		cyl(Vector3(6, 0.5, 17.5) + o, 0.06, 1.0, "yellow", {"col": false})
	ramp(Vector3(6, 0.02, 13.4), Vector3(6, 1.06, 16.7), 1.2, "metal", 0.1)
	stairs(Vector3(6, 0, 20.2), Vector3(6, 1.06, 18.3), 1.2, "wood")
	# песочница
	for s in [[Vector3(-1.5, 0.15, 14), Vector3(3.2, 0.3, 0.2)], [Vector3(-1.5, 0.15, 17), Vector3(3.2, 0.3, 0.2)], [Vector3(-3.0, 0.15, 15.5), Vector3(0.2, 0.3, 3.2)], [Vector3(0.0, 0.15, 15.5), Vector3(0.2, 0.3, 3.2)]]:
		box(s[0], s[1], "wood", {"col": false})
	_bench(Vector3(-9.5, 0, 6.2), 0)
	_bench(Vector3(9.5, 0, 6.2), 0)
	_bench(Vector3(-14.2, 0, 15), 90)
	_bench(Vector3(14.2, 0, 15), -90)
	# остановка «Курьерская»
	box(Vector3(24, 1.25, 29.4), Vector3(5.0, 2.5, 0.12), "glass", {"col": false})
	blocker(Vector3(24, 1.25, 29.4), Vector3(5.0, 2.5, 0.2))
	box(Vector3(24, 2.6, 28.4), Vector3(5.4, 0.14, 2.4), "metal_dark", {"col": false})
	for sx in [-2.5, 2.5]:
		cyl(Vector3(24 + sx, 1.3, 27.4), 0.07, 2.6, "metal_dark")
	_bench(Vector3(24, 0, 28.8), 0)
	txt("ОСТ. «КУРЬЕРСКАЯ»", Vector3(24, 2.95, 27.2), 180, 0.3, {"col": Color(1.0, 0.85, 0.2), "glow": 1.2})
	lamp(Vector3(24, 2.3, 27.6), Color(1.0, 0.9, 0.7), 2.4, 9.0)
	# деревья и кусты
	scatter(["nature/BirchTree_1", "nature/BirchTree_2", "nature/BirchTree_3", "nature/CommonTree_1", "nature/CommonTree_3"], Vector3(0, 0, 14), 50.0, 34,
		{"sc": [2.0, 2.9], "rect": Rect2(-50, -20, 100, 70), "avoid": [[Vector3(-36, 0, 9), 6.0], [Vector3(-24, 0, -10), 6.0], [Vector3(24, 0, 28), 5.0], [Vector3(0, 0, 15), 15.0], [Vector3(0, 0, 60), 8.0]],
		"avoid_rects": [Rect2(-70, -5, 124, 10), Rect2(-5, -30, 10, 94), Rect2(-5, 19, 37, 10)]})
	scatter(["nature/Bush_1", "nature/Bush_2", "nature/BushBerries_1"], Vector3(0, 0, 14), 50.0, 26,
		{"sc": [0.8, 1.2], "rect": Rect2(-50, -20, 100, 70), "avoid": [[Vector3(0, 0, 15), 14.0]], "avoid_rects": [Rect2(-70, -5, 124, 10), Rect2(-5, -30, 10, 94), Rect2(-5, 19, 37, 10)]})
	# голуби-пакости у песочницы (задание бабушки)
	if not G.flag("m_pigeons"):
		for p in [Vector3(-2, 1.2, 12), Vector3(2, 1.2, 18), Vector3(-6, 1.2, 19), Vector3(8, 1.2, 11)]:
			var e := enemy("pigeon", p, {"sight": 6.5})
			pigeons_left += 1
			e.on_death = func():
				pigeons_left -= 1
				if pigeons_left <= 0:
					G.set_flag("m_pigeons")
					G.toast("Голуби разогнаны. Скажи бабушке", "")
	# ящики с мелочью
	crate(Vector3(-45, 0, 30), [["cash", 10]])
	crate(Vector3(44, 0, 40), [["cash", 12], ["bread", 1]])
	crate(Vector3(-48, 0, -16), [["doshik", 1]])
	crate(Vector3(46, 0, -18), [["cash", 9]])


func _garage(c: Vector3, open_side := 0) -> void:
	# open_side: 0 — закрыт, 1 — ворота смотрят на +Z (открыт), -1 — на -Z (открыт)
	if open_side == 0:
		box(c + Vector3(0, 1.4, 0), Vector3(3.9, 2.8, 6.0), "garage")
	else:
		box(c + Vector3(-1.85, 1.4, 0), Vector3(0.2, 2.8, 6.0), "garage")
		box(c + Vector3(1.85, 1.4, 0), Vector3(0.2, 2.8, 6.0), "garage")
		box(c + Vector3(0, 1.4, -2.9 * open_side), Vector3(3.9, 2.8, 0.2), "garage")
	box(c + Vector3(0, 2.9, 0), Vector3(4.1, 0.2, 6.3), "rust", {"col": open_side == 0})
	if open_side != 0:
		blocker(c + Vector3(0, 2.9, 0), Vector3(4.1, 0.2, 6.3))


func _garages() -> void:
	# три ряда гаражей, между ними проезды
	slab(-34, -64, 34, -30, 0.04, "dirt", 0.06, {"col": false})
	var open_n := {"-52,6": 1, "-36,10": -1, "-52,12": -1}
	for row in [-36.0, -52.0]:
		for i in 14:
			var x := -26.0 + i * 4.0
			var k := "%d,%d" % [int(row), i]
			if row == -36.0 and (i == 6 or i == 7):
				continue          # проезд от ворот
			_garage(Vector3(x, 0, row), open_n.get(k, 0))
	for i in 14:
		_garage(Vector3(-26.0 + i * 4.0, 0, -60.0 - 1.0), 1 if i == 13 else 0)
	# забор и вход у вывески
	wall(-30, -66, -30, -47, 0, 2.6, "rust", 0.2)
	wall(-30, -41, -30, -31, 0, 2.6, "rust", 0.2)
	wall(30, -66, 30, -31, 0, 2.6, "rust", 0.2)
	wall(-30, -31, -3.5, -31, 0, 2.6, "rust", 0.2)
	wall(3.5, -31, 30, -31, 0, 2.6, "rust", 0.2)
	wall(-30, -66, 30, -66, 0, 2.6, "rust", 0.2)
	txt("ГСК «ПАКОСТЬ»", Vector3(0, 3.6, -31), 0, 0.8, {"col": Color(1.0, 0.35, 0.3), "glow": 1.4, "dbl": true})
	box(Vector3(0, 3.0, -31), Vector3(7.4, 0.25, 0.3), "rust", {"col": false})
	lamp(Vector3(0, 2.6, -29.5), Color(1.0, 0.5, 0.35), 2.4, 10.0)
	for p in [Vector3(-14, 2.4, -44), Vector3(14, 2.4, -44), Vector3(0, 2.4, -44), Vector3(24, 2.4, -56.5), Vector3(-22, 2.4, -44)]:
		lamp(p, Color(1.0, 0.6, 0.35), 2.0, 10.0)
	# хлам
	for p in [Vector3(-12, 0, -42.2), Vector3(8, 0, -45.6), Vector3(18, 0, -42.4)]:
		prop("dung/Barrel", p, rng.randf() * 360.0)
	crate(Vector3(-20, 0, -45.4), [["cash", 8]])
	crate(Vector3(12, 0, -42.6), [["banana", 1]])
	crate(Vector3(14, 0, -35.0), [["cash", 16], ["plums", 1]])
	# пакости и крысы
	for p in [Vector3(-10, 1.0, -44), Vector3(4, 1.0, -44), Vector3(16, 1.0, -44), Vector3(22, 1.0, -55)]:
		enemy("imp", p)
	for p in [Vector3(-18, 0.2, -43), Vector3(10, 0.2, -45)]:
		enemy("rat", p)
	# посылка — в открытом гараже в дальнем углу (ряд -61, последний)
	if not G.has("parcel") and not G.has("pass_p46") and not G.flag("m_boss"):
		crate(Vector3(26, 0, -62.2), [["parcel", 1]], {"prop": "plat2/Crate", "size": 0.9})
	# гараж пакостников: за ним цепь
	if not G.flag("m_gop"):
		for p in [Vector3(-4, 0.2, -49), Vector3(-1, 0.2, -50.5), Vector3(-6.5, 0.2, -50.5)]:
			var g := enemy("gopnik" if p.x > -5 else "gopnik2", p, {"sight": 0.1})
			g.active = false
			g.model.play("Squat", 0.0)
			gop_alive += 1
			g.on_death = func():
				gop_alive -= 1
				if gop_alive <= 0:
					G.set_flag("m_gop")
					G.toast("Пакостники разбежались. В их гараже что-то блестит", "")
		trigger(Vector3(-3.5, 1, -46.5), Vector3(4.5, 2, 2.0), _gop_talk)
	if not G.flag("m_gop_loot"):
		pickup("chain", Vector3(-2, 0.7, -53.0), 1, {"on_take": func(): G.set_flag("m_gop_loot")})
		cash(Vector3(-1.2, 0.6, -52.2), 25)


func _station() -> void:
	# платформа и «поез»
	slab(56, -36, 74, -12, 0.9, "concrete", 0.9)
	stairs(Vector3(53.4, 0, -24), Vector3(56.0, 0.9, -24), 5.0, "concrete")
	box(Vector3(66, 2.2, -12.6), Vector3(16, 4.4, 0.4), "brick")
	box(Vector3(66, 4.5, -24), Vector3(17, 0.25, 9), "metal_dark", {"col": false})
	for z in [-34.0, -14.0]:
		cyl(Vector3(58.5, 2.65, z), 0.12, 3.5, "metal_dark")
	txt("ПОЕЗ", Vector3(66, 5.4, -19.4), 0, 1.3, {"col": Color(1.0, 0.82, 0.12), "glow": 1.6, "dbl": true})
	txt("МОЛОЧНОЕ · МЫТИЩИ · БАНЬКА · ЖМУРИНО", Vector3(66, 3.7, -12.84), 180, 0.34, {"col": Color(0.9, 0.95, 1.0), "glow": 0.9})
	lamp(Vector3(62, 4.0, -24), Color(1.0, 0.9, 0.7), 3.0, 14.0)
	# состав
	var tz := -24.0
	box(Vector3(70.5, 2.5, tz - 4.0), Vector3(3.0, 3.0, 9.0), Color(0.16, 0.3, 0.62))
	box(Vector3(70.5, 2.9, tz - 4.0), Vector3(3.06, 0.9, 9.04), Mats.glow(Color(1.0, 0.92, 0.7), 1.3), {"col": false})
	box(Vector3(70.5, 1.7, tz - 4.0), Vector3(3.08, 0.3, 9.06), Color(0.9, 0.9, 0.9), {"col": false})
	box(Vector3(70.5, 2.5, tz + 6.5), Vector3(3.0, 3.0, 9.0), Color(0.16, 0.3, 0.62))
	box(Vector3(70.5, 2.9, tz + 6.5), Vector3(3.06, 0.9, 9.04), Mats.glow(Color(1.0, 0.92, 0.7), 1.3), {"col": false})
	box(Vector3(70.5, 1.7, tz + 6.5), Vector3(3.08, 0.3, 9.06), Color(0.9, 0.9, 0.9), {"col": false})
	box(Vector3(70.5, 2.6, tz - 9.2), Vector3(2.9, 2.6, 1.4), Color(0.75, 0.12, 0.1), {"col": false})
	for z in [-31.0, -27.0, -21.0, -17.0, -13.0, -11.0]:
		cyl(Vector3(70.5, 0.95, z), 0.5, 3.2, "black", {"col": false, "seg": 10}).rotation.z = PI * 0.5
	slab(69, -70, 72, 40, 0.42, "rust", 0.4, {"col": false})
	blocker(Vector3(70.5, 3, -18), Vector3(3.2, 6, 60))
	# туман на рельсах, пока Тёмный Друн на крыше
	if not G.flag("m_boss"):
		fog_wall = blocker(Vector3(55, 3, -24), Vector3(0.6, 8, 14))
		fog_vis = mesh_box(Vector3(18, 7, 26), Color(0.65, 0.68, 0.75, 0.55))
		fog_vis.position = Vector3(64, 3.5, -24)
		fog_vis.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _people() -> void:
	drun = npc("drun", Vector3(-32.4, 0, 6.6), 150, {"talk": _talk_drun, "mark": "" if G.flag("m_drun") else "!"})
	npc("ashot", Vector3(-36, 0, 6.6), 180, {"mark": "₽", "label": "Купить", "talk": func():
		await say([["ashot", "Шаверма, брат! С мясом! Каким — не спрашивай."]])
		Menus.shop(G.ui, "ШАВЕРМА У АШОТА", "Сколько-сколько?", ["shawa", "doshik", "banana", "plums", "energy"])
		await G.ui.panel_closed})
	npc("seller", Vector3(-24, 0, -7.6), 0, {"mark": "₽", "label": "Купить", "name": "Продавщица", "talk": func():
		await say([[{"n": "Продавщица"}, "Вкусности, цепи, барсетки. Берём, не стесняемся."]])
		Menus.shop(G.ui, "ПРОДУКТЫ 24", "Вкусности и цепи", ["tasty", "chain", "heavy", "magnet", "bread"])
		await G.ui.panel_closed})
	courier = npc("courier", Vector3(22.6, 0, 27.6), 180, {"talk": _talk_courier, "mark": "" if G.flag("m_courier") else "?"})
	npc("mashinist", Vector3(60, 0.9, -21), -90, {"talk": _talk_train, "label": "Сесть на «поез»", "r": 2.8})
	# бабушка на лавке
	npc({"rig": "women", "body": "formal", "colors": {"LimeGreen": Color("7a3a4a"), "Red": Color("d8d8d8"), "Brown": Color("5a4a3a"), "Skin": Color("e0b8a0"), "Gold": Color("c0a060")}},
		Vector3(-9.5, 0, 6.3), 0, {"name": "Бабушка", "anim": "Sit", "solid": false, "look": false, "mark": "" if G.flag("m_granny") else "?", "talk": _talk_granny})
	# жители на корточках
	npc(Bestiary.GOP2, Vector3(9.8, 0, 6.9), 20, {"name": "Сосед по двору", "anim": "Squat", "talk": func():
		await say([[{"n": "Сосед по двору"}, "Слышь, Ч. Говорят, на крыше П-46 кто-то туман гонит. Чёрный такой. Весь в чёрном."], [{"n": "Сосед по двору"}, "А в гаражах пакостники сидят. На корточках. Как я. Но злые."]])})


func begin(cp_name: String) -> void:
	Story.mark_done("dorm")
	if cp_name == "start" and not G.flag("m_seen"):
		G.set_flag("m_seen")
		title_card()
		G.toast("Жёлтая метка ведёт к цели. %s" % ("Тяни стик до упора — бег" if G.touch else "Shift — бег"), "")
	_goal()


func _need() -> int:
	return Story.BUTTONS.size() - Story.buttons_have()


func _goal() -> void:
	if G.flag("m_boss"):
		if _need() <= 0:
			G.goal("Все кнопки собраны! Вызови ливт в П-46", Vector3(0, 0, 72))
		else:
			G.goal("Собери кнопки ливта (%d/%d). Садись на «поез»" % [Story.buttons_have(), Story.BUTTONS.size()], Vector3(60, 0.9, -22))
	elif G.has("pass_p46"):
		G.goal("Войди в «пезд» П-46 и вызови ливт", Vector3(0, 0, 66))
	elif G.has("parcel"):
		G.goal("Отнеси посылку курьеру на остановку", Vector3(22.6, 0, 27))
	elif G.flag("m_courier"):
		G.goal("Найди посылку курьера в гаражах ГСК «Пакость»", Vector3(26, 0, -61))
	elif G.flag("m_drun"):
		G.goal("Поговори с курьером на остановке", Vector3(22.6, 0, 27))
	else:
		G.goal("Найди Друна у ларька с шавермой", Vector3(-32.4, 0, 7))


func _talk_drun() -> void:
	if not G.flag("m_drun"):
		await say([["drun", "Ч! Живой! Ам-ам-ам, как я рад. Садись, посидим… нет, некогда сидеть."],
			["drun", "Слушай. 32 августа в 00:00 последний ливт в Мурино уходит на первый этаж. Кто не успел — того забирает Фог."],
			["ch", "А сейчас какое число?"],
			["drun", "31-е. С половиной. Ливт стоит в гигахрущёвке П-46, но в «пезд» без пропуска не пустят. Пропуск есть у курьера на остановке."],
			["drun", "И ещё: если прижмут — ори. Вот так: «АМ! АМ! АМ!». Я тебя научу."]])
		drun.play("Shout")
		Snd.sfx("am", 0.0)
		await G.wait(0.9)
		drun.play("Idle")
		G.give("am")
		G.set_flag("m_drun")
		drun.set_mark("")
		G.ui.hud.refresh_hints()
		G.toast("Бей врагов — копится ярость. Полная шкала: жми %s" % Inp.hint("ult"), "")
	elif G.flag("m_boss") and _need() <= 0:
		await say([["drun", "Все кнопки? Красавчик. В ливт — и на первый этаж. Только чую, Фог так просто не отпустит…"]])
	elif G.flag("m_boss"):
		await say([["drun", "Кнопки от ливта растащили: в Молочном, в Мытищах, в Баньке и в Жмурино. «Поез» ходит со станции."]])
	elif G.has("pass_p46"):
		await say([["drun", "Пропуск есть? Дуй в П-46. Ливт любит, когда его уважают: запомни, какие этажи он покажет."]])
	else:
		await say([["drun", "Курьер на остановке, вон там, за площадкой. Жёлтый такой, уставший."]])
	_goal()


func _talk_courier() -> void:
	if G.has("pass_p46") or G.flag("m_boss"):
		await say([["courier", "Квартира 3 999 999… Мне всего-то на девять тысяч этажей выше. Спасибо, брат."]])
	elif G.has("parcel"):
		await say([["courier", "Посылка! Целая! Ну, почти. Держи пропуск — мне он уже не поможет, а тебе в самый раз."], ["courier", "И осторожнее в «пезде»: ливт там… с характером."]])
		G.take("parcel")
		G.give("pass_p46")
		G.pay(30)
		G.toast("+30 ₽ чаевые", "small")
	elif G.flag("m_courier"):
		await say([["courier", "Гаражи — за площадкой, на юге. ГСК «Пакость». Название, говорят, не случайное."]])
	else:
		await say([["courier", "Третий год ищу квартиру 4 000 000 в П-46. Третий год, брат."], ["ch", "Мне бы пропуск в «пезд»."],
			["courier", "Дам. Но у меня пакости посылку утащили — в гаражи, в ГСК. Принеси, и пропуск твой."]])
		G.set_flag("m_courier")
		G.set_flag("m_drun")
		courier.set_mark("")
	_goal()


func _talk_granny() -> void:
	if G.flag("m_granny"):
		await say([[{"n": "Бабушка"}, "Сижу, милок. Посидим. Туман-то какой идёт, а?"]])
	elif G.flag("m_pigeons"):
		await say([[{"n": "Бабушка"}, "Разогнал! Вот это по-нашему. Держи вкусность — сама пекла. В восемьдесят девятом."]])
		G.give("tasty")
		G.set_flag("m_granny")
	else:
		await say([[{"n": "Бабушка"}, "Милок, разгони голубей-пакостей у песочницы. Всю лавку загадили, сесть негде."], ["ch", "Посидим… потом. Сейчас разгоню."]])


func _gop_talk() -> void:
	await cut(func():
		G.cam.shot(Vector3(-3.5, 1.6, -45.0), Vector3(-3.5, 1.0, -50.0), 50.0, 0.6)
		await say([[{"n": "Пакостник"}, "Э, слышь. Семки есть? А если найду?"], ["ch", "Что за бизнес… Ам-ам-ам вам, а не семки."]])
		G.cam.end_shot())
	for e in G.ents:
		if is_instance_valid(e) and e.kind in ["gopnik", "gopnik2"]:
			e.active = true
			e.aggro = true
			e.def["sight"] = 12.0
			e.set_state("chase")


func _talk_train() -> void:
	if not G.flag("m_boss"):
		await say([["mashinist", "«Поез» не идёт. Рельсы в тумане. Говорят, с крыши П-46 кто-то тёмный туман гонит…"]])
		return
	var opts: Array = []
	var ids: Array = []
	for b in Story.BUTTONS:
		var nm: String = b[2]
		if G.has(b[1]):
			nm += " — кнопка уже у тебя"
		opts.append(nm)
		ids.append(b[0])
	opts.append("Остаться в Мурино")
	var c: int = await G.ui.choose("mashinist", "Куда едем? «Поез» идёт по расписанию. Расписания нет.", opts)
	if c >= ids.size():
		return
	if not ResourceLoader.exists("res://src/levels/%s.gd" % ids[c]):
		await say([["mashinist", "Туда пути ещё кладут. Приходи позже."]])
		return
	await say([["mashinist", "Поехали!"]])
	G.checkpoint("station", true)
	G.travel(ids[c])


func _lift() -> void:
	if G.flag("m_boss"):
		if _need() > 0:
			await cut(func():
				await say([["lift", "«ДЛЯ ПЕРВОГО ЭТАЖА НЕ ХВАТАЕТ КНОПОК: %d». На крышу он больше не едет." % _need()]]))
			return
		await cut(func():
			await say([["ch", "Кнопки на месте. Вставляю. Поехали… на первый этаж."], ["lift", "«ПЕРВЫЙ ЭТАЖ. ВРЕМЯ: 23:59. 31 АВГУСТА»."]]))
		if not ResourceLoader.exists("res://src/levels/final.gd"):
			G.toast("Ливт вздрогнул и замер. (Финал ещё строится.)", "")
			return
		Story.mark_done("murino")
		G.travel("final")
		return
	await cut(func():
		await say([["lift", "Панель ливта мигает. Он как будто что-то вспоминает…"]])
		var ok: bool = await Puzzles.simon(G.ui, "ЛИВТ П-46", "Запомни, какие этажи покажет ливт.", FLOORS, 4)
		if not ok:
			return
		await say([["lift", "«МАРШРУТ ПРИНЯТ. ЭТАЖ: КРЫША. КНОПКИ ПЕРВОГО ЭТАЖА ОТСУТСТВУЮТ»."]])
		await G.ui.fade_to(1.0, 0.5)
		Snd.sfx("lift", 0.0)
		G.player.place(Vector3(0, RY + 0.1, 66.6), 0.0)
		G.cam.snap()
		await G.wait(1.0)
		G.checkpoint("roof", true)
		await G.ui.fade_to(0.0, 0.5))


func _boss_intro() -> void:
	for a in [[Vector3(0, RY + 2, 66.8), Vector3(8, 4, 0.4)]]:
		roof_gate.append(blocker(a[0], a[1]))
	await cut(func():
		Snd.music("boss")
		G.cam.shot(Vector3(3.5, RY + 1.6, 73.0), Vector3(0, RY + 1.6, 78), 50.0)
		await G.wait(1.0)
		boss.model.play("Idle", 0.3)
		await say([["ch", "Друн? Ты как сюда раньше меня?.. И чё ты в чёрном?"], ["dark", "Друн внизу. Шаверму жрёт. А Ч — тут. И Ч никуда не поедет."],
			["dark", "Кнопки от ливта Ч раскидал: Молочное, Мытищи, Банька, Жмурино. Фог сказал — никто не уедет на первый этаж."], ["ch", "Что за бизнес… Ты же не Друн. Ты — ТЁМНЫЙ ДРУН!"]])
		boss.model.play("Shout", 0.1)
		Snd.sfx("roar", 0.0)
		G.cam.shake(0.7)
		G.ui.big_title("ТЁМНЫЙ ДРУН", "БОСС")
		await G.wait(1.2)
		G.cam.end_shot())
	for g in roof_gate:
		g.disabled = true
	boss.start()
	G.goal("Победи Тёмного Друна. Уворачивайся от серии — после неё он открывается!")


func _boss_dead() -> void:
	G.set_flag("m_boss")
	Snd.music("murino")
	Snd.sfx("win", 0.0)
	G.pay(80)
	if fog_wall:
		fog_wall.disabled = true
	if fog_vis:
		fog_vis.queue_free()
	await cut(func():
		await say([["dark", "Плаки-плаки… Фог всё равно придёт…"],
			["phone", "*бзззз* Друн: «Ч! Туман с рельсов ушёл, поез снова ходит! И слышь — тот тёмный мои кроссы обронил. Носи, они с двойным прыжком»."],
			["ch", "Кнопки: Молочное, Мытищи, Банька, Жмурино. Поехали."]])
		G.give("kicks"))
	G.checkpoint("roof", true)
	G.toast("Кроссы Друна: нажми прыжок ещё раз в воздухе", "")
	_goal()
