extends Level
## ГЛАВА 3 — СЕЛО МОЛОЧНОЕ. Станция, трамвайное кольцо, село с колодцем и рынком, выпас, сарай Деда,
## трансформатор с рубильниками, лес за электропастухом, гнездо паучностей и Паучья яма с Маткой.

const PIT := Vector3(150, 0, -20)
const NEST := Vector3(-32, 0, -106)

var kond: Npc
var ded: Npc
var maid: Npc
var boss: SpiderMother
var gate := {}
var pit_gate := {}
var nest_on := false


func build() -> void:
	title = "СЕЛО МОЛОЧНОЕ"
	chapter = "ГЛАВА 3"
	music = "milk"
	steps = "grass"
	set_env("day")
	_ground()
	_village()
	_farm()
	_forest()
	_pit()
	_people()
	cp("start", Vector3(0, 1.0, 72.5), 0)
	cp("tram", Vector3(3, 0.1, 47), 0)
	cp("well", Vector3(0, 0.1, 6), 0)
	cp("forest", Vector3(0, 0.1, -66), 0)
	cp("pit", PIT + Vector3(0, 0.1, 20), 0)


func _ground() -> void:
	slab(-80, -135, 80, 95, 0.0, "grass", 1.0)
	arrival(Vector3(0, 0.9, 74), "СЕЛО МОЛОЧНОЕ", {"col": Color(0.2, 0.42, 0.3)})
	# дорога через всё село
	slab(-2.6, -62, 2.6, 67, 0.03, "dirt", 0.06, {"col": false})
	slab(-22, 49, 62, 51.2, 0.03, "dirt", 0.06, {"col": false})
	slab(2.6, 28.8, 27, 31.2, 0.03, "dirt", 0.06, {"col": false})
	slab(-22, 10.8, -2.6, 13.2, 0.03, "dirt", 0.06, {"col": false})
	slab(2.6, -9.2, 27, -6.8, 0.03, "dirt", 0.06, {"col": false})
	# края мира
	blocker(Vector3(-62, 4, -20), Vector3(1, 12, 230))
	blocker(Vector3(62, 4, -20), Vector3(1, 12, 230))
	blocker(Vector3(0, 4, -128), Vector3(130, 12, 1))
	scatter(["nature/CommonTree_1", "nature/CommonTree_2", "nature/CommonTree_3", "nature/BirchTree_1", "nature/BirchTree_2"], Vector3.ZERO, 1.0, 46,
		{"sc": [2.2, 3.2], "rect": Rect2(-78, -60, 15, 150), "col": "none"})
	scatter(["nature/CommonTree_1", "nature/CommonTree_2", "nature/CommonTree_3", "nature/BirchTree_1", "nature/BirchTree_2"], Vector3.ZERO, 1.0, 46,
		{"sc": [2.2, 3.2], "rect": Rect2(63, -60, 15, 150), "col": "none"})
	# трамвайное кольцо: рельсы и «Гота»
	for dz in [-0.75, 0.75]:
		box(Vector3(20, 0.08, 53.2 + dz), Vector3(86, 0.1, 0.14), "metal_dark", {"col": false})
	wagon(Vector3(12, 0.05, 53.2), 9.0, Color(0.78, 0.16, 0.12), true, {"w": 2.4, "h": 2.6, "stripe": Color(0.95, 0.85, 0.5)})
	txt("ГОТА · 1989", Vector3(12, 1.55, 51.95), 180, 0.34, {"col": Color(0.98, 0.9, 0.6), "outline": 6})
	txt("ГОТА · 1989", Vector3(12, 1.55, 54.45), 0, 0.34, {"col": Color(0.98, 0.9, 0.6), "outline": 6})
	for x in [-18.0, 2.0, 30.0, 50.0]:
		cyl(Vector3(x, 3.0, 55.4), 0.1, 6.0, "wood_dark")
		box(Vector3(x, 5.6, 54.4), Vector3(0.08, 0.08, 2.2), "metal_dark", {"col": false})
	box(Vector3(16, 5.5, 53.2), Vector3(80, 0.04, 0.04), "black", {"col": false})
	cyl(Vector3(4.6, 1.3, 50.2), 0.06, 2.6, "metal_dark")
	board("ТРАМВАЙ «ГОТА»\nСЕЛО — ПАУЧЬЯ ЯМА", Vector3(4.6, 2.5, 50.2), 0, 2.6, 0.8, {"col": Color(1.0, 0.9, 0.4)})


func _village() -> void:
	var mats := ["logs", "planks", "logs", "planks"]
	var k := 0
	for z in [37.0, 22.0, -22.0, -37.0]:
		hut(Vector3(-12, 0, z), Vector3(7, 3.0, 6), {"door": "e", "mat": mats[k % 4], "roof": "roof" if k % 2 == 0 else "rust"})
		if not (z == 22.0):
			hut(Vector3(12.5, 0, z), Vector3(7, 3.0, 6), {"door": "w", "mat": mats[(k + 1) % 4], "roof": "rust" if k % 2 == 0 else "roof"})
		k += 1
	hut(Vector3(13.5, 0, 17.5), Vector3(8, 3.0, 6), {"door": "w", "mat": "planks"})
	# огороды и заборчики у изб
	for z in [37.0, -22.0]:
		fence(-20, z - 5, -20, z + 5)
		for i in 5:
			prop(["crops/Lettuce_3", "crops/Carrot_3", "crops/Pumpkin_3", "crops/Tomato_3", "crops/Beet_3"][i], Vector3(-18.2, 0, z - 3.2 + i * 1.6), rng.randf() * 360.0, 1.0, {"h": 0.5})
	# площадь: колодец, рынок, колокольня
	slab(-9, -11, 9, 11, 0.04, "dirt", 0.06, {"col": false})
	prop("village/Well", Vector3(5.5, 0, 0), 0, 1.0, {"h": 2.4})
	prop("village/Bell_Tower", Vector3(9.5, 0, -14), 0, 1.0, {"h": 9.0})
	prop("village/MarketStand_1", Vector3(-7.4, 0, 2.5), 90, 1.0, {"h": 2.9})
	txt("МОЛОКО И ВКУСНОСТИ", Vector3(-5.9, 3.2, 2.5), 90, 0.34, {"col": Color(1.0, 0.95, 0.8), "outline": 8})
	bench(Vector3(5.5, 0, 6.5), 180)
	bench(Vector3(-6.5, 0, -6), 90)
	prop("village/Cart", Vector3(-6.5, 0, -1.5), 30, 1.0, {"h": 1.3})
	for p in [Vector3(-8.2, 0, 6), Vector3(-8.6, 0, 7.2)]:
		prop("village/Barrel", p, 0, 1.0, {"h": 1.0})
	board("ДОБРО ПОЖАЛОВАТЬ\nВ СЕЛО МОЛОЧНОЕ\nнаселение: 32 чел. и паучности", Vector3(-4.4, 2.0, 62), 0, 4.2, 1.5, {"col": Color(0.95, 0.95, 0.9), "bg": Color(0.12, 0.3, 0.16)})
	for sx in [-1.9, 1.9]:
		cyl(Vector3(-4.4 + sx, 0.9, 62), 0.07, 1.8, "wood_dark")
	# трансформатор
	box(Vector3(30, 1.6, 30), Vector3(3.4, 3.2, 3.4), "brick")
	box(Vector3(30, 3.3, 30), Vector3(3.8, 0.2, 3.8), "concrete_dark", {"col": false})
	box(Vector3(28.27, 1.1, 30), Vector3(0.08, 2.0, 1.1), "metal_dark", {"col": false})
	txt("ТП-1989\nНЕ ВЛЕЗАЙ —\nА ТО АМ-АМ", Vector3(28.2, 2.55, 30), -90, 0.24, {"col": Color(1.0, 0.85, 0.1), "outline": 6})
	interact(Vector3(27.6, 1.1, 30), 2.4, "Открыть щиток", _transformer, {"cond": func(): return not G.flag("mk_power")})
	for i in 4:
		cyl(Vector3(30 - i * 9.0, 3.0, 33.5), 0.1, 6.0, "wood_dark")
	# пруд и рыбак
	cyl(Vector3(40, 0.04, -9), 9.0, 0.06, "water", {"col": false, "seg": 26})
	blocker(Vector3(40, 1, -9), Vector3(13.4, 3, 13.4))
	blocker(Vector3(40, 1, -9), Vector3(13.4, 3, 13.4), 45)
	for i in 7:
		var a := TAU * i / 7.0
		prop("nature/Lilypad", Vector3(40 + cos(a) * rng.randf_range(2, 7), 0.08, -9 + sin(a) * rng.randf_range(2, 7)), rng.randf() * 360.0, 1.0, {"w": 0.9})
	for p in [Vector3(50.5, 0, -4), Vector3(45, 0, -19.5), Vector3(36, 0, 1.5)]:
		prop("nature/Willow_%d" % (1 + rng.randi() % 4), p, rng.randf() * 360.0, 3.0)
	box(Vector3(31.4, 0.2, -9), Vector3(3.2, 0.14, 1.4), "planks")
	for p in [Vector3(-28, 0, 44), Vector3(26, 0, 42), Vector3(44, 0, 20), Vector3(-30, 0, -32), Vector3(30, 0, -32), Vector3(52, 0, 40), Vector3(-44, 0, 50), Vector3(48, 0, -36)]:
		prop("nature/BirchTree_%d" % (1 + rng.randi() % 5), p, rng.randf() * 360.0, rng.randf_range(2.3, 3.0))
	scatter(["nature/Flowers", "nature/Grass", "nature/Grass_2", "nature/Plant_1", "nature/Plant_3"], Vector3(0, 0, 5), 1.0, 70, {"sc": [0.9, 1.5], "rect": Rect2(-58, -58, 116, 122),
		"avoid_rects": [Rect2(-4, -64, 8, 134), Rect2(-10, -12, 20, 24), Rect2(-24, 48, 90, 8)]})
	# осы и шершни за избами
	for p in [Vector3(26, 1.5, 36), Vector3(34, 1.5, 26)]:
		enemy("bee", p)
	for p in [Vector3(22, 1.5, -2), Vector3(-24, 1.5, -30), Vector3(46, 1.5, 30)]:
		enemy("wasp", p)
	crate(Vector3(18, 0, 26.5), [["cash", 10]])
	crate(Vector3(-17, 0, -30), [["cash", 8], ["bread", 1]])
	crate(Vector3(52, 0, 6), [["cash", 14]])


func _cow(p: Vector3, yaw: float) -> void:
	var m := Model.creature("cow", 1.5)
	add_child(m)
	m.position = p
	m.rotation.y = deg_to_rad(yaw)
	m.play("eat" if rng.randf() < 0.6 else "idle", 0.0)
	blocker(p + Vector3(0, 0.8, 0), Vector3(1.1, 1.6, 2.2), yaw)


func _farm() -> void:
	# выпас за жердями
	fence(-52, -6, -22, -6)
	fence(-52, 30, -22, 30)
	fence(-52, -6, -52, 30)
	fence(-22, -6, -22, 10.4)
	fence(-22, 13.6, -22, 30)
	for a in [[Vector3(-30, 0, 2), 40.0], [Vector3(-42, 0, 8), 200.0], [Vector3(-36, 0, 22), 120.0], [Vector3(-46, 0, 24), -60.0], [Vector3(-28, 0, 18), 10.0]]:
		_cow(a[0], a[1])
	for p in [Vector3(-47, 0, -2), Vector3(-45.6, 0, -2.6), Vector3(-46.4, 0.9, -2.2)]:
		box(p + Vector3(0, 0.45, 0), Vector3(1.3, 0.9, 1.3), "grass_dry")
	box(Vector3(-38, 0.3, 28.4), Vector3(4.0, 0.6, 1.0), "wood_dark")
	box(Vector3(-38, 0.62, 28.4), Vector3(3.7, 0.06, 0.7), "water", {"col": false})
	for p in [Vector3(-34, 1.5, 6), Vector3(-44, 1.5, 16), Vector3(-30, 1.5, 26)]:
		enemy("wasp", p)
	# изба Деда и сарай
	hut(Vector3(-12, 0, -50), Vector3(8, 3.2, 7), {"door": "e", "lit": true})
	prop("village/Bonfire_Lit", Vector3(-5.6, 0, -45.4), 0, 1.0, {"h": 0.9})
	prop("nature/WoodLog", Vector3(-6.4, 0, -54.2), 60, 1.0, {"w": 1.6})
	# сарай: x 8..22, z -58..-46
	slab(8, -58, 22, -46, 0.05, "planks", 0.1, {"col": false})
	wall_gaps(8, -58, 8, -46, 0, 4.0, "planks", [[6.0, 2.6, 2.7]], 0.3)
	wall(22, -58, 22, -46, 0, 4.0, "planks", 0.3)
	wall(8, -58, 22, -58, 0, 4.0, "planks", 0.3)
	wall(8, -46, 22, -46, 0, 4.0, "planks", 0.3)
	ceiling(8, -58, 22, -46, 4.0, "planks")
	for sg in [-1.0, 1.0]:
		ramp(Vector3(15, 3.9, -52 + sg * 6.6), Vector3(15, 6.6, -52), 15.0, "rust", 0.18)
	lamp(Vector3(15, 3.3, -52), Color(1.0, 0.8, 0.5), 2.6, 12.0)
	txt("САРАЙ", Vector3(7.8, 3.2, -52), -90, 0.5, {"col": Color(0.95, 0.9, 0.8), "outline": 8})
	for p in [Vector3(20.3, 0, -56.3), Vector3(20.3, 0, -54.6), Vector3(18.8, 0, -56.4), Vector3(20.4, 1.2, -55.6)]:
		box(p + Vector3(0, 0.6, 0), Vector3(1.4, 1.2, 1.4), "grass_dry")
	prop("village/Cart", Vector3(11, 0, -47.6), 100, 1.0, {"h": 1.3})
	for p in [Vector3(9.4, 0, -56.8), Vector3(10.7, 0, -57)]:
		prop("village/Barrel", p, 0, 1.0, {"h": 1.0})
	door(Vector3(8, 0, -52), 90, {"w": 2.6, "h": 2.7, "label": "Открыть сарай", "mat": "wood_dark",
		"locked": func(): return "" if G.flag("mk_ded") else "Сарай заперт. Чей он — спроси в избе рядом"})
	trigger(Vector3(15, 1.2, -52), Vector3(5.5, 2, 5), _barn_fight, true, func(): return G.flag("mk_ded") and not G.flag("mk_barn"))
	if G.flag("mk_barn") and not G.has("fuse") and not G.flag("mk_power"):
		pickup("fuse", Vector3(15, 0.8, -52))
	# бидоны молочницы
	if not G.flag("mk_bidons"):
		for it in [["mk_b1", Vector3(-49, 0.6, 27)], ["mk_b2", Vector3(25.5, 0.6, -52)], ["mk_b3", Vector3(49, 0.6, -16.5)]]:
			if not G.flag(it[0]):
				var fl: String = it[0]
				pickup("bidon", it[1], 1, {"on_take": func(): G.set_flag(fl)})


func _forest() -> void:
	# электропастух поперёк села
	fence(-62, -62, -2.4, -62, 1.4, "metal_dark")
	fence(2.4, -62, 62, -62, 1.4, "metal_dark")
	for sx in [-2.4, 2.4]:
		cyl(Vector3(sx, 1.6, -62), 0.12, 3.2, "metal_dark")
	board("ЭЛЕКТРОПАСТУХ\nБЕЗ ТОКА ВОРОТА НЕ ОТКРЫТЬ", Vector3(0, 3.5, -62), 0, 4.8, 0.9, {"col": Color(1.0, 0.85, 0.1)})
	if not G.flag("mk_power"):
		gate = barrier(Vector3(0, 1.5, -62), Vector3(4.6, 3.0, 0.25), Color(1.0, 0.8, 0.1, 0.45))
	# тропа в лес: ворота -> поворот -> гнездо
	var path := [Vector3(0, 0, -62), Vector3(-4, 0, -76), Vector3(-16, 0, -86), Vector3(-26, 0, -96), NEST]
	var avoid: Array = [[NEST, 11.0], [Vector3(34, 0, -100), 7.0]]
	for i in path.size() - 1:
		var a: Vector3 = path[i]
		var b: Vector3 = path[i + 1]
		var d := b - a
		box((a + b) * 0.5 + Vector3(0, 0.04, 0), Vector3(3.4, 0.06, d.length() + 2.0), "dirt", {"yaw": rad_to_deg(atan2(d.x, d.z)), "col": false})
		for f in [0.0, 0.33, 0.66, 1.0]:
			avoid.append([a + d * f, 4.2])
	# боковая тропка к тайнику
	for f in [0.0, 0.25, 0.5, 0.75, 1.0]:
		avoid.append([Vector3(-4, 0, -76).lerp(Vector3(34, 0, -100), f), 3.6])
	scatter(["nature/PineTree_1", "nature/PineTree_2", "nature/PineTree_3", "nature/CommonTree_1", "nature/CommonTree_4", "nature/BirchTree_1", "nature/BirchTree_3"], Vector3.ZERO, 1.0, 150,
		{"sc": [2.2, 3.4], "rect": Rect2(-60, -126, 120, 62), "avoid": avoid})
	scatter(["nature/Bush_1", "nature/Bush_2", "nature/BushBerries_1", "nature/Rock_Moss_1", "nature/Rock_Moss_3", "nature/TreeStump_Moss", "crops/Mushroom_2"], Vector3.ZERO, 1.0, 60,
		{"sc": [0.8, 1.4], "rect": Rect2(-60, -126, 120, 62), "avoid": avoid, "col": "none"})
	for p in [Vector3(-3, 0.3, -72), Vector3(-10, 0.3, -82), Vector3(-20, 0.3, -90), Vector3(8, 0.3, -84)]:
		enemy("mushnub", p)
	for p in [Vector3(-14, 0.3, -88), Vector3(-25, 0.3, -98), Vector3(14, 0.3, -88)]:
		enemy("spider", p)
	enemy("wasp", Vector3(-8, 1.5, -78))
	# тайник: цепь в паутине
	if not G.flag("mk_stash"):
		crate(Vector3(34, 0, -100), [["chain", 1], ["cash", 20]], {"on_break": func(): G.set_flag("mk_stash")})
	for p in [Vector3(31, 0.3, -97), Vector3(37, 0.3, -98)]:
		enemy("spider", p)
	enemy("bee", Vector3(34, 1.6, -104))
	# гнездо: коконы и паутина
	cyl(NEST + Vector3(0, 0.03, 0), 9.5, 0.06, Color(0.86, 0.86, 0.82), {"col": false, "seg": 20})
	for i in 9:
		var a := TAU * i / 9.0 + 0.3
		var r := 8.6 + rng.randf() * 1.5
		var cpos := NEST + Vector3(cos(a) * r, 0, sin(a) * r)
		if cpos.distance_to(Vector3(-26, 0, -96)) < 4.5:
			continue
		cyl(cpos + Vector3(0, 0.9, 0), 0.55, 1.8, Color(0.93, 0.93, 0.9), {"r_top": 0.25, "seg": 8})
		box(cpos + Vector3(0, 2.6, 0), Vector3(0.05, 2.0, 0.05), Color(0.95, 0.95, 0.95), {"col": false})
	cyl(NEST + Vector3(0, 1.3, -2.5), 1.0, 2.6, Color(0.96, 0.96, 0.92), {"r_top": 0.45, "seg": 10})
	txt("ГНЕЗДО", NEST + Vector3(0, 3.6, -2.5), 0, 0.5, {"col": Color(1.0, 0.5, 0.45), "outline": 8})
	interact(NEST + Vector3(0, 1.0, -1.2), 2.4, "Разорвать кокон", _nest_fight, {"cond": func(): return not G.flag("mk_nest") and not nest_on})
	if G.flag("mk_nest") and not G.has("handle") and not G.flag("mk_ride"):
		pickup("handle", NEST + Vector3(0, 0.8, 0.5))


func _pit() -> void:
	slab(PIT.x - 30, PIT.z - 30, PIT.x + 30, PIT.z + 36, 0.0, "dirt", 1.0)
	# стены ямы
	for i in 18:
		var a := TAU * i / 18.0
		if absf(angle_difference(a, PI * 0.5)) < 0.2:
			continue                                   # вход с юга
		var c := PIT + Vector3(cos(a) * 18.5, 3.0, sin(a) * 18.5)
		box(c, Vector3(7.0, 6.0 + rng.randf() * 2.0, 3.0), "earth_wall", {"yaw": -rad_to_deg(a) + 90.0})
		prop("nature/Rock_%d" % (1 + rng.randi() % 7), PIT + Vector3(cos(a) * 16.6, 0, sin(a) * 16.6), rng.randf() * 360.0, 1.0, {"h": rng.randf_range(1.2, 2.6), "col": "none", "tint": Color(0.5, 0.47, 0.45)})
	for sx in [-1.0, 1.0]:
		box(PIT + Vector3(sx * 5.0, 3.0, 23), Vector3(3.0, 6.0, 10.0), "earth_wall")
	blocker(PIT + Vector3(0, 3, 35.5), Vector3(60, 10, 1))
	blocker(PIT + Vector3(-12, 3, 30), Vector3(1, 10, 12))
	blocker(PIT + Vector3(22, 3, 30), Vector3(1, 10, 12))
	# паутина и коконы
	for i in 10:
		var a := TAU * i / 10.0 + 0.2
		var c := PIT + Vector3(cos(a) * 15.2, 0, sin(a) * 15.2)
		if absf(angle_difference(a, PI * 0.5)) < 0.35:
			continue
		cyl(c + Vector3(0, 1.0, 0), 0.6, 2.0, Color(0.66, 0.66, 0.6), {"r_top": 0.25, "seg": 8, "col": false})
	for i in 6:
		var a := TAU * i / 6.0
		box(PIT + Vector3(cos(a) * 9.0, 7.5, sin(a) * 9.0), Vector3(19.0, 0.04, 0.08), Color(0.95, 0.95, 0.95, 0.8), {"yaw": -rad_to_deg(a), "col": false})
	cyl(PIT + Vector3(0, 0.03, 0), 15.5, 0.05, "earth_floor", {"col": false, "seg": 28})
	txt("ПАУЧЬЯ ЯМА", PIT + Vector3(0, 7.6, 18.2), 0, 1.4, {"col": Color(1.0, 0.4, 0.35), "outline": 12})
	# трамвай у края ямы
	for dz in [-0.75, 0.75]:
		box(PIT + Vector3(6, 0.08, 30 + dz), Vector3(40, 0.1, 0.14), "metal_dark", {"col": false})
	wagon(PIT + Vector3(8, 0.05, 30), 9.0, Color(0.78, 0.16, 0.12), true, {"w": 2.4, "h": 2.6, "stripe": Color(0.95, 0.85, 0.5)})
	interact(PIT + Vector3(4.5, 1.0, 28.2), 2.6, "Трамвай обратно в село", func():
		await cut(func():
			await G.ui.fade_to(1.0, 0.4)
			G.player.place(Vector3(3, 0.1, 47), 0.0)
			G.cam.snap()
			G.checkpoint("tram", true)
			await G.wait(0.5)
			await G.ui.fade_to(0.0, 0.4))
		_goal(), {"cond": func(): return G.flag("mk_boss")})
	if not G.flag("mk_boss"):
		boss = SpiderMother.new()
		add_child(boss)
		boss.global_position = PIT + Vector3(0, 0.2, -6)
		boss.home = boss.global_position
		boss.arena = PIT
		boss.set_yaw(PI)
		trigger(PIT + Vector3(0, 1.5, 12.5), Vector3(4, 2.5, 1.5), _boss_intro)


func _people() -> void:
	kond = npc("konduktor", Vector3(3.4, 0, 49.4), 180, {"talk": _talk_kond, "mark": "!" if not G.flag("mk_talk") else ""})
	ded = npc("ded", Vector3(-6.4, 0, -50), -90, {"talk": _talk_ded, "mark": "?" if not G.flag("mk_ded") else ""})
	maid = npc("milkmaid", Vector3(-5.6, 0, 2.5), -90, {"talk": _talk_maid, "mark": "₽", "label": "Купить"})
	npc("rybak", Vector3(31.2, 0.27, -9), -90, {"talk": _talk_rybak, "anim": "Sit", "solid": false, "look": false})
	trigger(Vector3(0, 1, 6), Vector3(3, 2, 2), func():
		if String(G.save["cp"]) == "start":
			G.checkpoint("well"))
	trigger(Vector3(0, 1, -66), Vector3(3, 2, 2), func(): G.checkpoint("forest"))


func begin(cp_name: String) -> void:
	if cp_name == "start" and not G.flag("mk_seen"):
		G.set_flag("mk_seen")
		title_card()
		G.toast("Паучности и осы не любят дихлофос: зажми %s" % Inp.hint("gadget"), "")
	_goal()


func _goal() -> void:
	if G.flag("mk_boss"):
		if G.player and G.player.global_position.x > 100.0:
			G.goal("Кнопка «1» у тебя! Трамвай обратно в село", PIT + Vector3(4.5, 0, 28))
		else:
			G.goal("Кнопка «1» у тебя! Возвращайся на «поез» в Мурино", Vector3(3, 0.9, 76))
	elif G.flag("mk_ride"):
		G.goal("Победи Паучью Матку", PIT)
	elif G.has("handle"):
		G.goal("Отнеси ручку кондукторше — трамвай поедет в Паучью яму", Vector3(3.4, 0, 49.4))
	elif G.flag("mk_power"):
		G.goal("Найди ручку контроллера в гнезде, в лесу на севере", NEST)
	elif G.has("fuse"):
		G.goal("Вставь предохранитель в трансформатор на востоке села", Vector3(28, 0, 30))
	elif G.flag("mk_ded"):
		G.goal("Выгони паучностей из сарая Деда и забери предохранитель", Vector3(9, 0, -52))
	elif G.flag("mk_talk"):
		G.goal("Спроси предохранитель у Деда: крайняя изба на севере", Vector3(-6.4, 0, -50))
	else:
		G.goal("Поговори с кондукторшей у трамвая", Vector3(3.4, 0, 49.4))


func _talk_kond() -> void:
	if G.flag("mk_boss"):
		await say([["konduktor", "Матку одолел? Ну ты даёшь, милок. Теперь хоть трамваи по расписанию пойдут. С восемьдесят девятого ждём."]])
	elif G.has("handle") and G.flag("mk_power"):
		await say([["konduktor", "Ручка! Родная! И ток есть. Ну, держись за поручень: следующая остановка — Паучья яма."], ["ch", "Посидим… в трамвае. Поехали."]])
		G.take("handle")
		G.set_flag("mk_ride")
		Snd.sfx("door", 0.0, 0.8)
		await G.ui.fade_to(1.0, 0.5)
		G.player.place(PIT + Vector3(0, 0.1, 20), 0.0)
		G.cam.snap()
		G.checkpoint("pit", true)
		await G.wait(0.8)
		await G.ui.fade_to(0.0, 0.5)
		G.ui.big_title("ПАУЧЬЯ ЯМА", "конечная")
	elif G.flag("mk_ride"):
		await say([["konduktor", "Опять в яму? Ну, поехали. Только ты уж там… аккуратнее."]])
		await G.ui.fade_to(1.0, 0.4)
		G.player.place(PIT + Vector3(0, 0.1, 20), 0.0)
		G.cam.snap()
		G.checkpoint("pit", true)
		await G.wait(0.4)
		await G.ui.fade_to(0.0, 0.4)
	elif G.flag("mk_power"):
		await say([["konduktor", "Гудит, родная! Ток есть. Теперь ручку контроллера: гнездо — в лесу, за электропастухом. Ворота теперь открыты."]])
	elif G.flag("mk_talk"):
		await say([["konduktor", "Сначала ток, милок. Дед — на севере, в крайней избе. Трансформатор — на востоке, за избами."]])
	else:
		await say([["konduktor", "Трамвай не идёт, милок. С восемьдесят девятого ходил как часы, а теперь — паучности."],
			["ch", "Мне бы кнопку от ливта. Красную такую, с единичкой."],
			["konduktor", "Кнопку Матка унесла. В Паучью яму. Туда только моя «Гота» и доедет… а она стоит: в трансформаторе предохранитель сгорел, а ручку контроллера паучности в гнездо утащили."],
			["konduktor", "Предохранитель спроси у Деда — крайняя изба на севере. Он запасливый."],
			["ch", "Ток и ручка. Что за бизнес…"]])
		G.set_flag("mk_talk")
		kond.set_mark("")
	_goal()


func _talk_ded() -> void:
	if G.flag("mk_boss"):
		await say([["ded", "Тихо в селе стало. Аж непривычно. Посидим?"], ["ch", "Посидим. Но недолго — ливт ждёт."]])
	elif G.flag("mk_barn"):
		await say([["ded", "Трансформатор — на востоке, за избами. Рубильники там хитрые: надо ровно пятьдесят ампер, ни больше ни меньше."]])
	elif G.flag("mk_ded"):
		await say([["ded", "Сарай — через дорогу. Я отсюда посмотрю. У меня спина. И страх."]])
	else:
		await say([["ded", "Предохранитель? Есть. В сарае лежит, в ящике из-под гвоздей. С восемьдесят девятого."],
			["ded", "Только в сарае паучности завелись. Я туда не хожу — у меня спина. И страх."],
			["ch", "Посидим? …Ладно. Выгоню."],
			["ded", "Выгонишь — забирай. А вилы не трогай, они заговорённые."]])
		G.set_flag("mk_ded")
		G.set_flag("mk_talk")
		ded.set_mark("")
	_goal()


func _talk_maid() -> void:
	if not G.flag("mk_bidons") and G.count("bidon") >= 3:
		await say([["milkmaid", "Мои бидончики! Все три! Держи вкусность — настоящую. И молочка на дорожку."]])
		G.take("bidon", 3)
		G.set_flag("mk_bidons")
		G.give("tasty")
		G.give("milk")
		return
	if not G.flag("mk_bidon_ask"):
		G.set_flag("mk_bidon_ask")
		await say([["milkmaid", "Молочко! Парное! Паучности не трогали — честное слово."],
			["milkmaid", "Слушай, милок, я три бидона растеряла, когда от ос бежала: один на выпасе, один за сараем, один у пруда. Найдёшь — вкусностью угощу."]])
	elif not G.flag("mk_bidons"):
		await say([["milkmaid", "Бидонов пока %d из трёх. Выпас, сарай, пруд — там ищи." % G.count("bidon")]])
	Menus.shop(G.ui, "МОЛОКО И ВКУСНОСТИ", "Сколько-сколько?", ["milk", "bread", "plums", "tasty", "energy"])
	await G.ui.panel_closed


func _talk_rybak() -> void:
	if not G.flag("mk_rybak"):
		G.set_flag("mk_rybak")
		await say([["rybak", "Тсс. Клюёт. Вчера паучность вытащил — на полтора метра. Отпустил: жалко."],
			["rybak", "К Матке пойдёшь — смотри под ноги. Красный круг увидел — беги. Она прыгнет, лапами в землю застрянет — вот тогда и бей."],
			["rybak", "На, сливы. Сам не ем: на них клюёт плохо."]])
		G.give("plums")
	else:
		await say([["rybak", "Красный круг — беги. Застряла — бей. И дихлофос не жалей. Всё, тсс."]])


func _transformer() -> void:
	if not G.has("fuse"):
		await cut(func(): await say([["ch", "Предохранитель сгорел. Чёрный, как Тёмный Друн. Нужен новый."]]))
		return
	await cut(func():
		await say([["ch", "Предохранитель на месте. Теперь рубильники… Дед говорил — ровно пятьдесят ампер."]])
		var ok: bool = await Puzzles.switches(G.ui, "ТП-1989", "Включи рубильники так, чтобы вышло ровно 50 ампер.", [5, 10, 15, 20, 25, 30], 50)
		if not ok:
			return
		G.take("fuse")
		G.set_flag("mk_power")
		barrier_off(gate)
		Snd.sfx("unlock", 0.0, 0.7)
		G.cam.shake(0.3)
		await say([["ch", "Гудит! Ток пошёл. Ворота электропастуха должны открыться."]]))
	_goal()


func _barn_fight() -> void:
	G.toast("Паучности лезут из сена!", "")
	Snd.sfx("alert", 0.0)
	wave([["spiderling", Vector3(19, 0.3, -49)], ["spiderling", Vector3(19.5, 0.3, -52)], ["spiderling", Vector3(17, 0.3, -56)], ["spider", Vector3(18, 0.3, -54)], ["spiderling", Vector3(12, 0.3, -56)]], func():
		if not is_inside_tree():
			return
		wave([["spider", Vector3(19, 0.3, -50)], ["spider", Vector3(18, 0.3, -55.5)], ["spiderling", Vector3(13, 0.3, -48)], ["spiderling", Vector3(12.5, 0.3, -56)]], func():
			if not is_inside_tree():
				return
			G.set_flag("mk_barn")
			Snd.sfx("win", -4.0)
			G.toast("Сарай чист. В ящике из-под гвоздей — предохранитель", "")
			pickup("fuse", Vector3(15, 0.8, -52), 1, {"on_take": func(): _goal()})
			_goal()))


func _nest_fight() -> void:
	nest_on = true
	await cut(func(): await say([["ch", "В коконе что-то твёрдое… Ручка! Сейчас я её…"], [{"n": "Гнездо"}, "щщщЩЩЩЩ!"]]))
	Snd.sfx("alert", 0.0)
	var ring := func(n: int, kind: String, r: float) -> Array:
		var l: Array = []
		for i in n:
			var a := TAU * i / n + randf()
			l.append([kind, NEST + Vector3(cos(a) * r, 0.3, sin(a) * r)])
		return l
	wave(ring.call(5, "spiderling", 6.5) + ring.call(2, "spider", 7.5), func():
		if not is_inside_tree():
			return
		G.toast("Из кокона лезет нянька!", "")
		wave([["spider", NEST + Vector3(0, 0.4, -5), {"name": "Паучиха-нянька", "size": 1.25, "r": 0.95, "h": 1.3, "hp": 150, "dmg": 13}]] + ring.call(3, "spiderling", 6.0), func():
			if not is_inside_tree():
				return
			G.set_flag("mk_nest")
			Snd.sfx("win", -4.0)
			pickup("handle", NEST + Vector3(0, 0.8, 0.5), 1, {"on_take": func(): _goal()})
			G.toast("Ручка контроллера выпала из кокона", "")))


func _boss_intro() -> void:
	pit_gate = barrier(PIT + Vector3(0, 2.5, 15.6), Vector3(8, 5, 0.4), Color(0.95, 0.95, 0.95, 0.55))
	await cut(func():
		Snd.music("boss")
		G.cam.shot(PIT + Vector3(5, 2.2, 3), PIT + Vector3(0, 1.4, -6), 55.0)
		await G.wait(0.8)
		await say([["ch", "Так вот ты какая, Паучья яма… Посидим? Нет? Ну ам-ам-ам тогда."], ["mother", "ЩЩЩЩ… КНОПКА… МОЯ… БЛЕСТИТ…"]])
		boss.play("attack", 0.1, 0.8, true)
		Snd.sfx("roar", 0.0, 1.4)
		G.cam.shake(0.7)
		G.ui.big_title("ПАУЧЬЯ МАТКА", "БОСС")
		await G.wait(1.2)
		G.cam.end_shot())
	boss.on_defeat = _boss_dead
	boss.start()
	G.goal("Победи Паучью Матку. Красный круг — беги; застряла — бей!")


func test_boss() -> void:
	G.player.place(PIT + Vector3(0, 0.1, 12.5), 0.0)


func _boss_dead() -> void:
	G.set_flag("mk_boss")
	Story.mark_done("milk")
	Snd.music(music)
	Snd.sfx("win", 0.0)
	G.pay(90)
	barrier_off(pit_gate)
	await cut(func():
		await say([["mother", "щщщ… блестит… не моя…"], ["ch", "Кнопка «1»! Липкая… Одна есть. Что за бизнес — у паука кнопки отбирать."]])
		G.give("btn1"))
	G.checkpoint("pit", true)
	_goal()
