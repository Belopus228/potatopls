extends Level
## ГЛАВА 6 — ЖМУРИНО. Город-отражение Мурино: улица Последняя, казино «Бурмалда», кладбище с тремя склепами,
## двор ЖК «Вечный покой» и парадная с Консьержем.

const HALL := Vector3(0, 0, -53)
const GREEN := Color(0.45, 1.0, 0.7)
const WALL := ["plaster_green", "plaster_dark", 1.6]
const C1 := Vector3(-34, 0, 20)      # склеп Купца
const C2 := Vector3(34, 0, 14)       # склеп Поэта
const C3 := Vector3(-30, 0, -8)      # склеп Управдома
const FAT := Vector3(34, 0, -8)

var keeper: Npc
var boss: Concierge
var door_gate := {}
var poet_gate := {}
var hall_gate := {}
var flames: Array = []
var crypt1_on := false


func build() -> void:
	title = "ЖМУРИНО"
	chapter = "ГЛАВА 6"
	music = "jmur"
	set_env("grave")
	_ground()
	_street()
	_casino()
	_cemetery()
	_crypts()
	_yard()
	_lobby()
	_people()
	cp("start", Vector3(0, 1.0, 72.5), 0)
	cp("gate", Vector3(0, 0.1, 36), 0)
	cp("yard", Vector3(0, 0.1, -25), 0)
	cp("boss", Vector3(0, 0.1, -33), 0)


func _ground() -> void:
	slab(-80, -135, 80, 95, 0.0, "dirt", 1.0)
	arrival(Vector3(0, 0.9, 74), "ЖМУРИНО", {"col": Color(0.14, 0.2, 0.17)})
	slab(-2.4, -36, 2.4, 67, 0.03, "asphalt", 0.06, {"col": false})
	blocker(Vector3(-60, 4, -20), Vector3(1, 12, 230))
	blocker(Vector3(60, 4, -20), Vector3(1, 12, 230))
	var k := 0
	for z in [60.0, 30.0, 0.0, -30.0, -60.0]:
		for sx in [-1.0, 1.0]:
			building(Vector3(sx * 72, 0, z), Vector3(20, 26 + (k * 7) % 18, 27), "facade_dark", {"lit": 0.5})
			k += 1


func _street() -> void:
	post(Vector3(-4, 0, 62), 0, GREEN)
	post(Vector3(4, 0, 53), 0, GREEN)
	post(Vector3(-4, 0, 45), 0, GREEN)
	kiosk(Vector3(-12, 0, 54), 90, "ВЕНКИ И ШАВЕРМА", GREEN, "КРУГЛОСУТОЧНО. ВЕЧНО")
	board("ЖМУРИНО\nгород-побратим Мурино\nнаселение: было", Vector3(5.4, 2.0, 63), 0, 4.4, 1.5, {"col": Color(0.8, 1.0, 0.85), "bg": Color(0.06, 0.12, 0.09)})
	for sx in [-1.9, 1.9]:
		cyl(Vector3(5.4 + sx, 0.9, 63), 0.07, 1.8, "metal_dark")
	bench(Vector3(-5.5, 0, 49), 90)
	scatter(["nature/CommonTree_Dead_1", "nature/CommonTree_Dead_2", "nature/BirchTree_Dead_3", "nature/Willow_Dead_2", "nature/BirchTree_Dead_5"], Vector3.ZERO, 1.0, 22,
		{"sc": [2.2, 3.2], "rect": Rect2(-58, 42, 116, 24), "avoid_rects": [Rect2(-17, 48, 22, 12), Rect2(-5, 40, 10, 30), Rect2(4, 44, 46, 16)]})
	# ограда кладбища
	wall(-60, 40, -3.4, 40, 0, 2.4, "brick", 0.5)
	wall(3.4, 40, 60, 40, 0, 2.4, "brick", 0.5)
	for sx in [-3.4, 3.4]:
		box(Vector3(sx, 2.0, 40), Vector3(0.9, 4.0, 0.9), "brick")
	box(Vector3(0, 4.3, 40), Vector3(8.0, 0.7, 0.6), "metal_dark", {"col": false})
	txt("ЖМУРИНСКОЕ КЛАДБИЩЕ", Vector3(0, 4.3, 40.33), 0, 0.42, {"col": GREEN, "glow": 1.2, "outline": 0})
	for p in [Vector3(-6, 0.3, 46), Vector3(7, 0.3, 44)]:
		enemy("skull", p)
	trigger(Vector3(0, 1, 36), Vector3(3, 2, 2), func():
		if String(G.save["cp"]) == "start":
			G.checkpoint("gate"))


func _casino() -> void:
	# павильон: x 32..46, z 46..58, вход с запада
	var pink := Color(1.0, 0.3, 0.6)
	slab(2.4, 51, 32, 53, 0.03, "asphalt", 0.06, {"col": false})
	slab(32, 46, 46, 58, 0.06, "carpet", 0.12, {"col": false})
	wall(32, 46, 46, 46, 0, 4.4, "plaster_dark", 0.4)
	wall(32, 58, 46, 58, 0, 4.4, "plaster_dark", 0.4)
	wall(46, 46, 46, 58, 0, 4.4, "plaster_dark", 0.4)
	wall_gaps(32, 46, 32, 58, 0, 4.4, "plaster_dark", [[6.0, 4.0, 3.0]], 0.4)
	slab(31.5, 45.5, 46.5, 58.5, 4.8, "metal_dark", 0.4)
	txt("БУРМАЛДА", Vector3(31.7, 5.9, 52), -90, 1.3, {"col": pink, "glow": 2.2})
	txt("КАЗИНО · ФИШКИ · НАПЁРСТКИ", Vector3(31.7, 3.7, 52), -90, 0.26, {"col": Color(1.0, 0.9, 0.4), "glow": 1.2})
	lamp(Vector3(29.5, 3.2, 52), pink, 2.6, 11.0)
	lamp(Vector3(39, 3.6, 52), Color(1.0, 0.8, 0.5), 2.4, 12.0)
	box(Vector3(42, 0.5, 52), Vector3(1.6, 1.0, 4.0), Color(0.08, 0.35, 0.16))
	for i in 3:
		cyl(Vector3(41.9, 1.14, 51.0 + i * 1.0), 0.16, 0.28, "red", {"col": false, "seg": 10})
	for z in [47.2, 56.8]:
		for x in [35.0, 37.4]:
			box(Vector3(x, 0.9, z), Vector3(0.9, 1.8, 0.7), "metal_dark")
			box(Vector3(x, 1.3, z + (0.37 if z < 50.0 else -0.37)), Vector3(0.6, 0.5, 0.04), Mats.glow(pink if x < 36.0 else Color(0.3, 0.8, 1.0), 1.8), {"col": false})
	if not G.flag("jm_chip1"):
		pickup("chip", Vector3(-15.6, 0.7, 55.2), 1, {"on_take": func(): G.set_flag("jm_chip1")})


func _grave(p: Vector3, kind: int, epitaph := "") -> void:
	var yaw := rng.randf_range(-12.0, 12.0)
	box(p + Vector3(0, 0.1, 1.0), Vector3(1.0, 0.2, 2.0), "dirt", {"col": false, "yaw": yaw})
	if kind == 0:
		box(p + Vector3(0, 0.6, 0), Vector3(0.9, 1.2, 0.24), "concrete_dark", {"yaw": yaw})
		box(p + Vector3(0, 1.25, 0), Vector3(0.6, 0.14, 0.24), "concrete_dark", {"yaw": yaw, "col": false})
	elif kind == 1:
		box(p + Vector3(0, 0.85, 0), Vector3(0.14, 1.7, 0.14), "wood_dark", {"yaw": yaw})
		box(p + Vector3(0, 1.25, 0), Vector3(0.8, 0.14, 0.14), "wood_dark", {"yaw": yaw, "col": false})
	else:
		box(p + Vector3(0, 0.45, 0), Vector3(1.1, 0.9, 0.5), "marble", {"yaw": yaw})
	if epitaph != "":
		txt(epitaph, p + Vector3(0, 0.72, 0.14), 0, 0.11, {"col": Color(0.85, 0.95, 0.88), "outline": 4})


func _cemetery() -> void:
	var epi := ["ЛИВТ № 3\n1989–1989\nне доехал", "СОВЕСТЬ УК\nпомним,\nне видели", "ГОРЯЧАЯ ВОДА\nушла летом,\nне вернулась", "ПАРКОВКА\nеё и не было", "ДОМОФОН\nне отвечал\nпри жизни", "ТИШИНА\nпосле 23:00",
		"WI-FI\nловил\nтолько здесь", "ДЕТСКАЯ\nПЛОЩАДКА\nпо проекту", "ПОСЛЕДНИЙ\n«ПОЕЗ»\n23:59", "ЗАРПЛАТА\nДРУНА\n1989–1989"]
	var ei := 0
	for gx in range(-52, 53, 8):
		for gz in range(32, -16, -8):
			if absi(gx) < 6:
				continue
			var p := Vector3(gx + rng.randf_range(-1.2, 1.2), 0, gz + rng.randf_range(-1.2, 1.2))
			var skip := false
			for c in [C1, C2, C3]:
				if Vector2(p.x - c.x, p.z - c.z).length() < 8.8:
					skip = true
			if skip or Vector2(p.x - FAT.x, p.z - FAT.z).length() < 5.0:
				continue
			var near_road: bool = absi(gx) < 13
			var kind := 0 if near_road else rng.randi() % 3
			_grave(p, kind, epi[ei % epi.size()] if near_road else "")
			if near_road:
				ei += 1
	scatter(["nature/CommonTree_Dead_1", "nature/CommonTree_Dead_2", "nature/BirchTree_Dead_3", "nature/Willow_Dead_2", "nature/Willow_Dead_4", "nature/BirchTree_Dead_5"], Vector3.ZERO, 1.0, 34,
		{"sc": [2.2, 3.4], "rect": Rect2(-57, -17, 114, 54), "avoid": [[C1, 9.0], [C2, 9.0], [C3, 9.0], [FAT, 7.0]], "avoid_rects": [Rect2(-5, -20, 10, 60)]})
	for p in [Vector3(-14, 2.6, 28), Vector3(14, 2.6, 22), Vector3(-16, 2.6, 4), Vector3(16, 2.6, -4), Vector3(-44, 2.6, 4), Vector3(46, 2.6, 28), Vector3(0, 3.0, 10)]:
		lamp(p, GREEN, 1.5, 11.0)
	for p in [Vector3(-5, 0, 28), Vector3(5, 0, 10), Vector3(-5, 0, -8)]:
		prop("dung/Torch", p, 0, 1.0, {"h": 2.1})
		var g := mesh_box(Vector3(0.22, 0.3, 0.22), Mats.glow(GREEN, 3.0))
		g.position = p + Vector3(0, 2.15, 0)
	# памятник ливтёру
	box(Vector3(12, 0.5, 6), Vector3(3.0, 1.0, 2.0), "marble")
	for sx in [-0.62, 0.62]:
		box(Vector3(12 + sx, 2.3, 6), Vector3(1.2, 2.6, 0.2), "metal", {"col": false})
	box(Vector3(12, 3.75, 6), Vector3(2.7, 0.3, 0.4), "metal_dark", {"col": false})
	txt("ЛИВТЁРУ — ОТ ЖИЛЬЦОВ.\nОБЕЩАЛ ПОЧИНИТЬ В 1989-м", Vector3(12, 0.55, 7.03), 0, 0.16, {"col": Color(0.9, 1.0, 0.9), "outline": 4})
	for p in [Vector3(-20, 0.3, 30), Vector3(18, 0.3, 30), Vector3(-10, 0.3, 14), Vector3(22, 0.3, 2), Vector3(-44, 0.3, -6), Vector3(48, 0.3, 8)]:
		enemy("skull", p)
	for p in [Vector3(-24, 1.6, 6), Vector3(10, 1.6, 22), Vector3(46, 1.6, 22), Vector3(-48, 1.6, 30)]:
		enemy("jmur", p)
	for p in [Vector3(-14, 0.3, -2), Vector3(14, 0.3, 14), Vector3(-46, 0.3, 14)]:
		enemy("zombie", p)
	crate(Vector3(-54, 0, 34), [["cash", 16], ["doshik", 1]])
	if not G.flag("jm_chip3"):
		crate(Vector3(54, 0, -14), [["chip", 1], ["cash", 12]], {"on_break": func(): G.set_flag("jm_chip3")})
	else:
		crate(Vector3(54, 0, -14), [["cash", 8]])
	crate(Vector3(20, 0, -14), [["cash", 14]])
	# Жирный Жмур с ключом
	if not G.flag("jm_key"):
		var fat := enemy("jmur", FAT + Vector3(0, 1.8, 0), {"name": "Жирный Жмур", "size": 2.6, "r": 0.9, "h": 2.0, "hp": 230, "dmg": 15, "speed": 3.0, "money": [20, 30]})
		fat.on_death = func():
			if is_inside_tree():
				pickup("key_crypt", Vector3(fat.global_position.x, 0.8, fat.global_position.z), 1, {"on_take": func():
					G.set_flag("jm_key")
					_goal()}).toss()
				G.toast("Жирный Жмур выплюнул ключ", "")
	elif not G.has("key_crypt") and not G.flag("jm_c3"):
		pickup("key_crypt", FAT + Vector3(0, 0.8, 0))
	# вторая ограда: двор ЖК
	wall(-60, -20, -3.4, -20, 0, 2.4, "brick", 0.5)
	wall(3.4, -20, 60, -20, 0, 2.4, "brick", 0.5)
	for sx in [-3.4, 3.4]:
		box(Vector3(sx, 1.6, -20), Vector3(0.9, 3.2, 0.9), "brick")


func _crypt(c: Vector3, nm: String, side: String) -> void:
	var x0 := c.x - 4.0
	var x1 := c.x + 4.0
	var z0 := c.z - 4.0
	var z1 := c.z + 4.0
	var sx := 1.0 if side == "e" else -1.0
	slab(x0, z0, x1, z1, 0.05, "concrete_dark", 0.1, {"col": false})
	room(x0, z0, x1, z1, 0, 3.6, "concrete_dark", {side: [[c.z, 2.4, 2.6]]}, 0.4)
	slab(x0 - 0.5, z0 - 0.5, x1 + 0.5, z1 + 0.5, 4.0, "concrete_dark", 0.4)
	txt(nm, Vector3(c.x + sx * 4.3, 3.15, c.z), 90.0 * sx, 0.36, {"col": GREEN, "glow": 0.8, "outline": 8})
	box(c + Vector3(-sx * 1.8, 0.45, 0), Vector3(1.3, 0.9, 2.6), "marble")
	lamp(c + Vector3(0, 2.8, 0), GREEN, 1.7, 8.0)
	for dz in [-3.0, 3.0]:
		prop("dung/Candelabrum_tall", c + Vector3(-sx * 3.2, 0, dz), 0, 1.0, {"h": 1.8})
	slab(c.x + sx * 4.0, c.z - 1.4, c.x + sx * 9.0, c.z + 1.4, 0.03, "asphalt", 0.06, {"col": false})


func _candle(flag: String, pos: Vector3) -> void:
	if G.flag(flag) or G.flag("jm_door"):
		return
	pickup("candle", pos, 1, {"on_take": func():
		G.set_flag(flag)
		_goal()})


func _crypts() -> void:
	# Купец: засада
	_crypt(C1, "СКЛЕП КУПЦА", "e")
	trigger(C1 + Vector3(0, 1.2, 0), Vector3(3.2, 2, 3.2), _crypt1_fight, true, func(): return not G.flag("jm_k1"))
	if G.flag("jm_k1"):
		_candle("jm_c1", C1 + Vector3(0.4, 0.8, 0))
	# лесенка из ящиков на крышу склепа Купца: там фишка
	for i in 3:
		box(Vector3(C1.x - 1.0 + i * 1.5, (i + 1) * 0.5, C1.z + 5.3), Vector3(1.5, float(i + 1), 1.5), "wood")
	box(Vector3(C1.x + 3.4, 1.5, C1.z + 5.3), Vector3(1.4, 3.0, 1.5), "wood")
	if not G.flag("jm_chip2"):
		pickup("chip", C1 + Vector3(0, 4.8, 0), 1, {"on_take": func(): G.set_flag("jm_chip2")})
	# Поэт: кодовый замок
	_crypt(C2, "СКЛЕП ПОЭТА", "w")
	board("«Я ждал свой ливт. Он не пришёл.\nКод — год, когда трамвай пошёл»", C2 + Vector3(-4.3, 1.5, 2.9), -90, 3.0, 0.9, {"col": Color(0.85, 1.0, 0.9), "bg": Color(0.08, 0.1, 0.09)})
	if not G.flag("jm_poet"):
		poet_gate = barrier(C2 + Vector3(-4.0, 1.3, 0), Vector3(0.3, 2.6, 2.4), Color(0.2, 0.22, 0.24, 1.0))
		interact(C2 + Vector3(-4.6, 1.1, 0), 2.2, "Кодовый замок", _poet_lock, {"cond": func(): return not G.flag("jm_poet")})
	_candle("jm_c2", C2 + Vector3(-0.4, 0.8, 0))
	crate(C2 + Vector3(2.6, 0, -2.6), [["cash", 20], ["plums", 1]])
	# Управдом: ключ у Жирного Жмура
	_crypt(C3, "СКЛЕП УПРАВДОМА", "e")
	door(C3 + Vector3(4.0, 0, 0), 90, {"w": 2.4, "h": 2.6, "label": "Открыть склеп", "mat": "metal_dark",
		"locked": func(): return "" if (G.has("key_crypt") or G.flag("jm_c3")) else "Заперто. Ключ проглотил Жирный Жмур — он летает на востоке кладбища"})
	_candle("jm_c3", C3 + Vector3(0.4, 0.8, 0))
	if not G.flag("jm_c3"):
		for p in [C3 + Vector3(-1, 0.3, -2.4), C3 + Vector3(-1, 0.3, 2.4)]:
			enemy("zombie", p, {"sight": 5.0})
		enemy("skull", C3 + Vector3(1.5, 0.3, 0), {"sight": 5.0})


func _yard() -> void:
	slab(-20, -36, 20, -20, 0.03, "asphalt", 0.06, {"col": false})
	trigger(Vector3(0, 1, -24), Vector3(3, 2, 1.5), func(): G.checkpoint("yard"))
	bench(Vector3(-8, 0, -29), 0)
	bench(Vector3(12, 0, -31), 0)
	post(Vector3(-12, 0, -24), 0, GREEN)
	post(Vector3(15, 0, -24), 0, GREEN)
	board("ОБЪЯВЛЕНИЯ\nСобрание жильцов перенесено на вечность.\nЛивт не работает. И не работал.\nГорячей воды нет. Холодной тоже.\nТишина — круглосуточно.", Vector3(-9, 2.0, -35.6), 0, 5.6, 2.4, {"col": Color(0.85, 1.0, 0.9), "bg": Color(0.07, 0.1, 0.08), "th": 0.24})
	for sx in [-17.0, 17.0]:
		prop("nature/CommonTree_Dead_2", Vector3(sx, 0, -30), rng.randf() * 360.0, 3.4)
	# лампады у входа
	for i in 3:
		var p := Vector3(-4.6 + i * 4.6, 0, -33.6) if i != 1 else Vector3(0, 3.4, -35.4)
		if i != 1:
			cyl(p + Vector3(0, 0.6, 0), 0.1, 1.2, "metal_dark")
			cyl(p + Vector3(0, 1.3, 0), 0.34, 0.24, "metal_dark", {"col": false, "r_top": 0.42})
		else:
			box(p, Vector3(0.5, 0.5, 0.5), "metal_dark", {"col": false})
		var fl := mesh_box(Vector3(0.26, 0.36, 0.26), Mats.glow(GREEN, 3.2))
		fl.position = p + (Vector3(0, 1.62, 0) if i != 1 else Vector3(0, -0.2, 0.3))
		fl.visible = G.flag("jm_door")
		var l := lamp(fl.position + Vector3(0, 0.3, 0.4), GREEN, 2.6, 10.0)
		l["off"] = not G.flag("jm_door")
		flames.append([fl, l])
	txt("ЖК «ВЕЧНЫЙ ПОКОЙ» · ПАРАДНАЯ № 0", Vector3(0, 4.6, -35.7), 0, 0.42, {"col": GREEN, "glow": 1.0, "outline": 8})
	if not G.flag("jm_door"):
		door_gate = barrier(Vector3(0, 1.5, -36), Vector3(3.2, 3.0, 0.3), Color(0.12, 0.14, 0.13, 1.0))
		interact(Vector3(0, 1.1, -34.8), 2.6, "Зажечь лампады", _light, {"cond": func(): return not G.flag("jm_door")})
	for p in [Vector3(-10, 0.3, -27), Vector3(9, 0.3, -27)]:
		enemy("zombie", p)
	enemy("jmur", Vector3(0, 1.6, -30))
	# катафалк обратно к станции
	wagon(Vector3(17, 0.0, -33), 5.6, Color(0.07, 0.07, 0.09), false, {"w": 2.2, "h": 2.0, "base": 0.5, "stripe": GREEN})
	txt("РИТУАЛ-ТАКСИ", Vector3(15.86, 1.2, -33), -90, 0.22, {"col": GREEN, "outline": 0, "glow": 0.8})
	interact(Vector3(15.2, 1.0, -33), 2.4, "Ритуал-такси до станции", func():
		await cut(func():
			await G.ui.fade_to(1.0, 0.4)
			G.player.place(Vector3(0, 0.1, 62), PI)
			G.cam.snap()
			G.checkpoint("gate", true)
			await G.wait(0.5)
			await G.ui.fade_to(0.0, 0.4))
		_goal(), {"cond": func(): return G.flag("jm_boss")})


func _lobby() -> void:
	building(Vector3(0, 0, -84), Vector3(64, 70, 30), "facade_dark", {"lit": 0.6})
	txt("ВЕЧНЫЙ ПОКОЙ", Vector3(0, 40, -68.8), 0, 5.0, {"col": GREEN, "glow": 1.6})
	slab(-15, -68, 15, -36, 0.05, "tiles_green", 0.1, {"col": false})
	wall_gaps(-15, -36, 15, -36, 0, 5.5, WALL, [[15.0, 3.2, 3.0]], 0.5)
	wall(-15, -68, -15, -36, 0, 5.5, WALL, 0.5)
	wall(15, -68, 15, -36, 0, 5.5, WALL, 0.5)
	ceiling(-15, -68.6, 15, -36, 5.5, "plaster_dark")
	box(Vector3(0, 6.0, -52), Vector3(31, 0.5, 33), "concrete_dark", {"col": false})
	for p in [Vector3(-7, 5.45, -44), Vector3(7, 5.45, -44), Vector3(-7, 5.45, -60), Vector3(7, 5.45, -60)]:
		ceil_lamp(p, Color(0.72, 1.0, 0.85), 2.5, 15.0)
	lamp(Vector3(0, 3.4, -62.5), Color(0.85, 1.0, 0.9), 2.4, 13.0)   # свет у будки: Консьержа видно от самой двери
	for i in 12:
		box(Vector3(-14.6, 1.5, -39.5 - i * 0.9), Vector3(0.3, 0.6, 0.8), "metal_dark", {"col": false})
	txt("ПОЧТА.\nПИСЕМ НЕТ", Vector3(-14.7, 2.6, -44.5), 90, 0.3, {"col": Color(0.85, 1.0, 0.9), "outline": 6})
	box(Vector3(14.7, 1.5, -52), Vector3(0.12, 3.0, 2.8), "metal", {"col": false})
	box(Vector3(14.68, 1.5, -52), Vector3(0.14, 3.0, 0.06), "black", {"col": false})
	txt("ЛИВТ.\nТОЛЬКО ВНИЗ", Vector3(14.7, 3.6, -52), -90, 0.3, {"col": Color(1.0, 0.4, 0.35), "glow": 0.8, "outline": 6})
	# будка консьержа
	box(Vector3(0, 0.6, -66.4), Vector3(6.0, 1.2, 1.0), "wood_dark")
	box(Vector3(0, 2.1, -65.95), Vector3(6.0, 1.8, 0.06), "glass", {"col": false})
	box(Vector3(0, 3.2, -66.4), Vector3(6.4, 0.3, 1.4), "wood_dark", {"col": false})
	txt("КОНСЬЕРЖ", Vector3(0, 3.75, -65.9), 0, 0.46, {"col": GREEN, "glow": 1.2, "outline": 8})
	txt("УШЁЛ НАВСЕГДА. БУДУ ЧЕРЕЗ 5 МИНУТ", Vector3(0, 1.5, -65.9), 0, 0.15, {"col": Color.WHITE, "outline": 4})
	if not G.flag("jm_boss"):
		boss = Concierge.new()
		add_child(boss)
		boss.global_position = Vector3(0, 0.2, -62)
		boss.home = boss.global_position
		boss.arena = HALL
		boss.set_yaw(PI)
		trigger(Vector3(0, 1.5, -40.6), Vector3(5, 2.5, 1.8), _boss_intro)


func _people() -> void:
	keeper = npc(Cast.look_of("ded"), Vector3(3.8, 0, 42.4), 180, {"name": "Сторож", "talk": _talk_keeper, "mark": "!" if not G.flag("jm_talk") else ""})
	npc("seller", Vector3(-9.4, 0, 54), -90, {"name": "Гробовщик", "mark": "₽", "label": "Купить", "talk": func():
		await say([[{"n": "Гробовщик"}, "Венки, свечи кончились, шаверма свежая. Относительно. Тебе на вынос или навсегда?"]])
		Menus.shop(G.ui, "ВЕНКИ И ШАВЕРМА", "Круглосуточно. Вечно", ["shawa", "doshik", "kvass", "energy", "tasty"])
		await G.ui.panel_closed})
	npc("croupier", Vector3(43.4, 0, 52), 90, {"talk": _talk_croupier, "mark": "?" if not G.flag("jm_casino") else ""})
	npc(Bestiary.GUARD, Vector3(31, 0, 55.4), 90, {"name": "Охранник", "talk": func():
		await say([[{"n": "Охранник"}, "Фейс-контроль. Живым можно. Мёртвым тоже. Без фишек — только смотреть."]])})


func begin(cp_name: String) -> void:
	if cp_name == "start" and not G.flag("jm_seen"):
		G.set_flag("jm_seen")
		title_card()
	_goal()


func _goal() -> void:
	if G.flag("jm_boss"):
		if G.player and G.player.global_position.z < 0.0:
			G.goal("Кнопка «А» у тебя! Ритуал-такси довезёт до станции", Vector3(15.2, 0, -33))
		else:
			G.goal("Кнопка «А» у тебя! Возвращайся на «поез» в Мурино", Vector3(3, 0.9, 76))
	elif G.flag("jm_door"):
		G.goal("Войди в парадную. Консьерж ждёт", Vector3(0, 0, -38))
	elif G.count("candle") >= 3:
		G.goal("Зажги лампады у парадной ЖК «Вечный покой»", Vector3(0, 0, -34.8))
	elif G.flag("jm_talk"):
		var at := C1 + Vector3(5, 0, 0)
		if G.flag("jm_c1"):
			at = C2 + Vector3(-5, 0, 0)
			if G.flag("jm_c2"):
				at = FAT if not (G.has("key_crypt") or G.flag("jm_key")) else C3 + Vector3(5, 0, 0)
		G.goal("Найди три свечи в склепах: Купца, Поэта и Управдома (%d/3)" % G.count("candle"), at)
	else:
		G.goal("Поговори со сторожем у ворот кладбища", Vector3(3.8, 0, 42.4))


func _talk_keeper() -> void:
	var who := {"n": "Сторож", "c": GREEN}
	if G.flag("jm_boss"):
		await say([[who, "Консьержа выписал? Ну дела. Теперь хоть калитку на ночь закрывать не надо. Хотя тут всегда ночь."]])
	elif G.flag("jm_talk"):
		await say([[who, "Три свечи — три склепа. У Поэта код — год: читай эпитафию. Ключ Управдома — в Жирном Жмуре, на востоке."]])
	else:
		await say([[who, "Стой. Живой? …Живой. Давно таких не было. С восемьдесят девятого."],
			["ch", "Мне бы кнопку от ливта. С буквой «А»."],
			[who, "Кнопка у Консьержа. Он в парадной ЖК «Вечный покой» сидит — за кладбищем, прямо. Журнал ведёт: кто вошёл, кто не вышел."],
			[who, "Дверь парадной открывают три лампады. Лампадам нужны свечи, а свечи — в склепах: Купца, Поэта и Управдома."],
			[who, "К Купцу просто войди — он гостей любит. У Поэта замок с кодом, читай эпитафию. А ключ от склепа Управдома проглотил Жирный Жмур — летает на востоке."],
			["ch", "Три свечи. Что за бизнес… Посидим? Нет, не здесь."]])
		G.set_flag("jm_talk")
		keeper.set_mark("")
	_goal()


func _talk_croupier() -> void:
	if G.flag("jm_casino"):
		await say([["croupier", "Заведение закрыто на переучёт. Вы нас разорили. Приходите, когда умрёте."]])
		return
	if not G.flag("jm_cr_met"):
		G.set_flag("jm_cr_met")
		await say([["croupier", "Добро пожаловать в «Бурмалду». Ставки сделаны, ставок больше нет. Шучу. Есть."],
			["croupier", "Игра простая — напёрстки. Одна попытка — одна фишка. Угадаешь — отдам главный приз: кнопку от ливта с буквой «Ж». Запасную."],
			["croupier", "Фишки валяются по всему Жмурино: за ларьком, на крыше склепа Купца, в ящике у дальней ограды. Могу и продать — по шестьдесят."]])
	while true:
		var opts := ["Сыграть (фишек: %d)" % G.count("chip"), "Купить фишку за 60 ₽", "Уйти"]
		var c: int = await G.ui.choose("croupier", "Кручу-верчу, запутать хочу. Играем?", opts)
		if c == 1:
			if G.spend(60):
				G.give("chip")
			else:
				await say([["croupier", "Денег нет — фишек нет. Здесь не богадельня. Здесь казино при кладбище."]])
			continue
		if c != 0:
			return
		if G.count("chip") < 1:
			await say([["croupier", "Без фишки не кручу. Правила."]])
			continue
		G.take("chip")
		var tries := int(G.save["flags"].get("jm_tries", 0))
		G.save["flags"]["jm_tries"] = tries + 1
		var won: bool = await Puzzles.cups(G.ui, "БУРМАЛДА · НАПЁРСТКИ", maxi(3, 6 - tries))
		if won:
			await say([["croupier", "…Угадал. Так не бывает. Здесь никто не выигрывает с восемьдесят девятого."], ["croupier", "Забирай. Кнопка «Ж». И выигрыш. И уходи, пока живой."],
				["ch", "Кнопка «Ж»! Запасная. Что за бизнес — выигрывать у мёртвых."]])
			G.set_flag("jm_casino")
			G.give("btn5")
			G.pay(120)
			Snd.sfx("win", 0.0)
			return
		await say([["croupier", "Мимо. Фишка — моя. Ещё разок? С каждым разом кручу медленнее: жалко тебя."]])


func _poet_lock() -> void:
	var code: String = await Puzzles.keypad(G.ui, "СКЛЕП ПОЭТА", 4, "«Я ждал свой ливт. Он не пришёл. Код — год, когда трамвай пошёл». Про этот год тут твердят все.")
	if code == "":
		return
	if code == "1989":
		G.set_flag("jm_poet")
		barrier_off(poet_gate)
		Snd.sfx("unlock", 0.0, 0.8)
		G.toast("Плита отъехала. С восемьдесят девятого ждала", "")
	else:
		Snd.sfx("deny", 0.0)
		G.toast("Плита не шелохнулась. «…год, когда трамвай пошёл»", "small")


func _crypt1_fight() -> void:
	if crypt1_on:
		return
	crypt1_on = true
	G.toast("Купец гостей любит. На ужин", "")
	Snd.sfx("alert", 0.0)
	wave([["skull", C1 + Vector3(-2.4, 0.3, -2.6)], ["skull", C1 + Vector3(-2.4, 0.3, 2.6)], ["skull", C1 + Vector3(2.4, 0.3, -2.6)], ["zombie", C1 + Vector3(-2.6, 0.3, 0)]], func():
		if not is_inside_tree():
			return
		wave([["jmur", C1 + Vector3(6, 1.6, 0)], ["skull", C1 + Vector3(2.4, 0.3, 2.6)], ["zombie", C1 + Vector3(7, 0.3, 2)]], func():
			if not is_inside_tree():
				return
			G.set_flag("jm_k1")
			Snd.sfx("win", -4.0)
			G.toast("На саркофаге Купца догорает свеча", "")
			_candle("jm_c1", C1 + Vector3(0.4, 0.8, 0))))


func _light() -> void:
	if G.count("candle") < 3:
		await cut(func(): await say([["ch", "Три лампады, и все пустые. Нужны свечи: пока %d из трёх." % G.count("candle")]]))
		return
	G.take("candle", 3)
	G.set_flag("jm_door")
	for f in flames:
		(f[0] as MeshInstance3D).visible = true
		f[1]["off"] = false
	Snd.sfx("unlock", 0.0, 0.6)
	G.cam.shake(0.4)
	barrier_off(door_gate)
	await cut(func(): await say([["ch", "Горят. Зелёным. Дверь парадной открылась… сама. Ну, посидим у консьержа."]]))
	G.checkpoint("boss")
	_goal()


func _boss_intro() -> void:
	hall_gate = barrier(Vector3(0, 1.5, -36.2), Vector3(3.2, 3.0, 0.4), Color(0.4, 1.0, 0.7, 0.4))
	await cut(func():
		Snd.music("boss")
		G.cam.shot(Vector3(5, 2.6, -52), Vector3(0, 2.0, -62), 55.0)
		await G.wait(0.8)
		await say([["ch", "Парадная. Чисто, тихо… Слишком тихо."],
			["concierge", "ВЫ К КОМУ?"],
			["ch", "Я за кнопкой. С буквой «А»."],
			["concierge", "В ЖУРНАЛЕ ВАС НЕТ. ЖИВЫМ ВХОД ВОСПРЕЩЁН. ВЫХОД — ТЕМ БОЛЕЕ."],
			["ch", "Ам-ам-ам тогда."]])
		boss.play("No", 0.1, 1.0, true)
		Snd.sfx("roar", 0.0, 1.5)
		G.cam.shake(0.7)
		G.ui.big_title("КОНСЬЕРЖ", "БОСС")
		await G.wait(1.2)
		G.cam.end_shot())
	boss.on_defeat = _boss_dead
	boss.start()
	G.goal("Победи Консьержа. Исчез — жди удара со спины; запыхался — бей!")


func test_boss() -> void:
	G.set_flag("jm_door")
	barrier_off(door_gate)
	G.player.place(Vector3(0, 0.1, -40.6), 0.0)


func _boss_dead() -> void:
	G.set_flag("jm_boss")
	Story.mark_done("jmur")
	Snd.music(music)
	Snd.sfx("win", 0.0)
	G.pay(120)
	barrier_off(hall_gate)
	await cut(func():
		await say([["concierge", "Запишите… в журнал… «выбыл»…"], ["ch", "Кнопка «А». Холодная, как консьерж. Четыре есть! Ливт, жди."]])
		G.give("btn4"))
	G.checkpoint("yard", true)
	_goal()
