extends Level
## ГЛАВА 4 — МЫТИЩИ. Город чистых рук: привокзальная площадь с фонтаном, прачечная, склад с крышей,
## помывочная с душами, санпропускник, проспект Чистоты и Дворец Мойдодыра.

const HALL := Vector3(0, 0, -78)
const WHITE := Color(0.62, 0.67, 0.74)

var guard_npc: Npc
var bath: Npc
var boss: Moidodyr
var gate := {}
var bath_gate := {}
var hall_gate := {}
var patrol_gate := {}
var jet: MeshInstance3D


func build() -> void:
	title = "МЫТИЩИ"
	chapter = "ГЛАВА 4"
	music = "myt"
	set_env("clean")
	_ground()
	_plaza()
	_laundry()
	_warehouse()
	_bath()
	_market()
	_prospect()
	_palace()
	_people()
	cp("start", Vector3(0, 1.0, 72.5), 0)
	cp("plaza", Vector3(0, 0.1, 40), 0)
	cp("gate", Vector3(0, 0.1, 6), 0)
	cp("palace", Vector3(0, 0.1, -43), 0)


func _ground() -> void:
	slab(-80, -135, 80, 95, 0.0, "clean_ground", 1.0)
	arrival(Vector3(0, 0.9, 74), "МЫТИЩИ", {"col": Color(0.86, 0.9, 0.94)})
	blocker(Vector3(-60, 4, -20), Vector3(1, 12, 230))
	blocker(Vector3(60, 4, -20), Vector3(1, 12, 230))
	var k := 0
	for z in [60.0, 30.0, 0.0, -30.0, -60.0, -90.0]:
		for sx in [-1.0, 1.0]:
			building(Vector3(sx * 71, 0, z), Vector3(20, 22 + (k * 7) % 16, 27), "facade_new", {"tint": Color(0.8, 0.85, 0.92)})
			k += 1
	building(Vector3(0, 0, -122), Vector3(120, 30, 16), "facade_new", {"tint": Color(0.8, 0.85, 0.92)})
	txt("ЧИСТОТА — ЗАЛОГ ВСЕГО", Vector3(0, 22, -113.8), 0, 3.0, {"col": Color(0.3, 0.7, 1.0)})


func _plaza() -> void:
	slab(-20, 37, 20, 67, 0.04, "clean_floor", 0.06, {"col": false})
	slab(-3, 10, 3, 37, 0.04, "clean_floor", 0.06, {"col": false})
	slab(-16, 19, 16, 23, 0.04, "clean_floor", 0.06, {"col": false})
	slab(-16, 26.5, 16, 30.5, 0.04, "clean_floor", 0.06, {"col": false})
	# фонтан
	cyl(Vector3(0, 0.35, 52), 4.2, 0.7, "marble_soft", {"seg": 24})
	cyl(Vector3(0, 0.72, 52), 3.8, 0.04, "water", {"col": false, "seg": 24})
	cyl(Vector3(0, 1.5, 52), 0.5, 3.0, "marble_soft")
	cyl(Vector3(0, 3.1, 52), 1.0, 0.3, "marble_soft", {"col": false, "r_top": 1.5})
	if not G.flag("my_fountain"):
		jet = mesh_box(Vector3(0.6, 3.6, 0.6), Color(0.6, 0.85, 1.0, 0.6))
		jet.position = Vector3(0, 5.0, 52)
		var soap := mesh_box(Vector3(0.5, 0.22, 0.32), Color(0.98, 0.7, 0.8))
		soap.position = Vector3(0, 3.38, 52)
		jet.set_meta("soap", soap)
	box(Vector3(6.6, 0.6, 52), Vector3(0.7, 1.2, 0.5), "metal")
	txt("ВЕНТИЛЬ", Vector3(6.6, 1.45, 52), 180, 0.2, {"col": Color(1.0, 0.85, 0.2), "outline": 5, "dbl": true})
	interact(Vector3(6.6, 1.0, 51.3), 2.2, "Вентиль фонтана", _fountain, {"cond": func(): return not G.flag("my_fountain")})
	if G.flag("my_fountain") and not G.flag("my_s3"):
		pickup("soap", Vector3(3.2, 0.8, 46.6), 1, {"on_take": func():
			G.set_flag("my_s3")
			_goal()})
	for a in [[Vector3(-9, 0, 44), 0.0], [Vector3(9, 0, 44), 0.0], [Vector3(-9, 0, 60), 180.0], [Vector3(9, 0, 60), 180.0]]:
		bench(a[0], a[1], "clean_white")
	for sx in [-6.5, 6.5]:
		cyl(Vector3(sx, 2.6, 37.4), 0.14, 5.2, "clean_white")
	board("МЫТИЩИ — ГОРОД ЧИСТЫХ РУК", Vector3(0, 4.9, 37.34), 180, 13.4, 1.0, {"col": Color(0.2, 0.6, 1.0), "bg": WHITE})
	board("МЫТИЩИ — ГОРОД ЧИСТЫХ РУК", Vector3(0, 4.9, 37.46), 0, 13.4, 1.0, {"col": Color(0.2, 0.6, 1.0), "bg": WHITE})
	board("МОЙ РУКИ ПЕРЕД ЕДОЙ,\nПОСЛЕ ЕДЫ И ВМЕСТО ЕДЫ", Vector3(-12, 2.2, 63.0), 0, 5.2, 1.3, {"col": Color(0.15, 0.4, 0.8), "bg": WHITE})
	board("ГРЯЗЬ НЕ ПРОЙДЁТ.\nИ ТЫ НЕ ПРОЙДЁШЬ", Vector3(12, 2.2, 63.0), 0, 5.2, 1.3, {"col": Color(0.15, 0.4, 0.8), "bg": WHITE})
	for p in [Vector3(-17, 0, 40), Vector3(17, 0, 40), Vector3(-17, 0, 64), Vector3(17, 0, 64)]:
		cyl(p + Vector3(0, 0.5, 0), 0.9, 1.0, "marble_soft", {"seg": 10})
		prop("nature/Bush_1", p + Vector3(0, 1.0, 0), 0, 1.0, {"h": 1.3, "col": "none"})
	for p in [Vector3(-4, 0.3, 44), Vector3(5, 0.3, 58)]:
		enemy("soap", p)


func _laundry() -> void:
	slab(-46, 44, -22, 62, 0.05, "clean_tiles", 0.1, {"col": false})
	room(-46, 44, -22, 62, 0, 4.2, "clean_wall", {"e": [[53, 3.0, 2.8]]}, 0.3)
	ceiling(-46, 44, -22, 62, 4.2, "clean_white")
	for x in [-41.0, -34.0, -27.0]:
		ceil_lamp(Vector3(x, 4.15, 53), Color(0.85, 0.95, 1.0), 0.6, 7.0)
	txt("ПРАЧЕЧНАЯ «БЕЛЫЙ ШУМ»", Vector3(-21.75, 3.5, 53), 90, 0.5, {"col": Color(0.2, 0.55, 0.95)})
	for i in 8:
		prop("home/Bathroom_WashingMachine", Vector3(-44.4 + i * 2.7, 0, 45.0), 0, 1.0, {"h": 1.05})
		prop("home/Bathroom_WashingMachine", Vector3(-44.4 + i * 2.7, 0, 61.0), 180, 1.0, {"h": 1.05})
	box(Vector3(-36, 0.45, 53), Vector3(7, 0.9, 1.5), "clean_white")
	box(Vector3(-36, 1.0, 53), Vector3(1.2, 0.2, 0.9), Color(0.9, 0.9, 1.0), {"col": false})
	trigger(Vector3(-34, 1.2, 53), Vector3(10, 2, 8), _laundry_fight, true, func(): return not G.flag("my_l"))
	if G.flag("my_l") and not G.flag("my_s1"):
		_soap1()


func _soap1() -> void:
	pickup("soap", Vector3(-43.5, 0.8, 53), 1, {"on_take": func():
		G.set_flag("my_s1")
		_goal()})


func _warehouse() -> void:
	building(Vector3(34, 0, 53), Vector3(20, 7, 18), "facade_new", {"tint": Color(0.74, 0.8, 0.88), "roof": "concrete_dark"})
	txt("СКЛАД МЫЛА\n(ПУСТОЙ)", Vector3(23.9, 5.4, 46.0), -90, 0.5, {"col": Color(0.2, 0.55, 0.95)})
	for i in 7:
		var top := float(i + 1)
		box(Vector3(22.9, top * 0.5, 61.0 - i * 2.0), Vector3(2.2, top, 2.0), "wood")
	for p in [Vector3(29, 7, 47), Vector3(41, 7, 59)]:
		prop("cyber/AC", p, rng.randf() * 360.0, 1.0, {"h": 1.3})
	prop("cyber/Antenna_1", Vector3(42, 7, 46), 0, 1.0, {"h": 3.5})
	for p in [Vector3(31, 8.6, 52), Vector3(38, 8.6, 56), Vector3(36, 8.6, 48)]:
		enemy("drone", p)
	crate(Vector3(30, 7, 58.5), [["cash", 18], ["energy", 1]])
	if not G.flag("my_s2"):
		pickup("soap", Vector3(40.5, 7.8, 52), 1, {"on_take": func():
			G.set_flag("my_s2")
			_goal()})


func _bath() -> void:
	slab(-46, 18, -16, 32, 0.05, "clean_tiles", 0.1, {"col": false})
	room(-46, 18, -16, 32, 0, 4.0, "clean_tiles", {"e": [[21.5, 2.6, 2.6], [28.5, 2.6, 2.6]]}, 0.3)
	wall(-40, 25, -16, 25, 0, 4.0, "clean_tiles", 0.3)
	ceiling(-46, 18, -16, 32, 4.0, "clean_white")
	for x in [-42.0, -33.0, -24.0]:
		ceil_lamp(Vector3(x, 3.95, 21.5), Color(0.85, 0.95, 1.0), 0.6, 7.0)
		ceil_lamp(Vector3(x, 3.95, 28.5), Color(0.85, 0.95, 1.0), 0.6, 7.0)
	for i in 4:
		hazard(Vector3(-21.5 - i * 5.0, 1.75, 21.5), Vector3(0.9, 3.5, 6.6), {"phase": i * 0.65, "dmg": 8.0})
		hazard(Vector3(-36.5 + i * 5.0, 1.75, 28.5), Vector3(0.9, 3.5, 6.6), {"phase": i * 0.65 + 0.4, "dmg": 8.0})
		box(Vector3(-21.5 - i * 5.0, 3.8, 21.5), Vector3(0.5, 0.25, 6.6), "metal", {"col": false})
		box(Vector3(-36.5 + i * 5.0, 3.8, 28.5), Vector3(0.5, 0.25, 6.6), "metal", {"col": false})
	txt("ПОМЫВОЧНАЯ № 1", Vector3(-15.75, 3.5, 25), 90, 0.5, {"col": Color(0.2, 0.55, 0.95)})
	txt("ВХОД", Vector3(-15.75, 2.95, 21.5), 90, 0.26, {"col": Color(0.2, 0.7, 0.3)})
	txt("ВЫХОД", Vector3(-15.75, 2.95, 28.5), 90, 0.26, {"col": Color(0.85, 0.3, 0.25)})
	txt("ОСТОРОЖНО:\nКИПЯТОК", Vector3(-17.5, 2.6, 18.2), 0, 0.3, {"col": Color(0.9, 0.25, 0.2), "outline": 6})
	cyl(Vector3(-42, 6.0, 20), 0.6, 4.2, "brick")
	for p in [Vector3(-44.6, 0, 26.2), Vector3(-44.6, 0, 30.6)]:
		prop("home/Bathroom_Sink", p, 90, 1.0)
	if not G.has("pass_clean") and not G.flag("my_gate"):
		bath_gate = barrier(Vector3(-16, 1.4, 28.5), Vector3(0.3, 2.8, 2.6), Color(0.7, 0.9, 1.0, 0.4))


func _market() -> void:
	kiosk(Vector3(24, 0, 28.5), -90, "МЫЛЬНЫЙ РЯД", Color(0.3, 0.7, 1.0), "ВСЁ, КРОМЕ МЫЛА", "clean_white")
	kiosk(Vector3(24, 0, 21), -90, "ШВАБРЫ", Color(0.5, 0.8, 0.9), "УЧЁТ", "clean_white")
	for p in [Vector3(30, 0, 32), Vector3(31.4, 0, 31), Vector3(30.6, 1.0, 31.6)]:
		box(p + Vector3(0, 0.5, 0), Vector3(1.0, 1.0, 1.0), "wood")
	crate(Vector3(38, 0, 33), [["cash", 12]])
	prop("home/Trashcan_Large", Vector3(41.6, 0, 17), 0, 1.0, {"h": 1.2})
	prop("home/Trashcan_Green", Vector3(43, 0, 17.4), 0, 1.0, {"h": 1.1})
	enemy("drone", Vector3(34, 2.0, 26))


func _prospect() -> void:
	# санпропускник
	wall(-60, 10, -3.2, 10, 0, 5.0, "clean_wall", 0.5)
	wall(3.2, 10, 60, 10, 0, 5.0, "clean_wall", 0.5)
	box(Vector3(0, 5.5, 10), Vector3(7.4, 1.0, 0.7), WHITE, {"col": false})
	txt("САНПРОПУСКНИК", Vector3(0, 5.6, 10.37), 0, 0.5, {"col": Color(0.2, 0.55, 0.95), "outline": 0})
	txt("ГРЯЗНЫМ ВХОД ВОСПРЕЩЁН", Vector3(0, 5.18, 10.37), 0, 0.22, {"col": Color(0.85, 0.25, 0.2), "outline": 0})
	if not G.flag("my_gate"):
		gate = barrier(Vector3(0, 2.25, 10), Vector3(6.0, 4.5, 0.3), Color(0.6, 0.9, 1.0, 0.4))
	trigger(Vector3(0, 1, 6), Vector3(3, 2, 2), func(): G.checkpoint("gate"))
	# проспект Чистоты
	slab(-7, -50, 7, 10, 0.04, "clean_floor", 0.06, {"col": false})
	var k := 0
	for z in [-2.0, -18.0, -34.0]:
		for sx in [-1.0, 1.0]:
			building(Vector3(sx * 22, 0, z), Vector3(16, 13 + (k * 5) % 9, 12), "facade_new", {"tint": Color(0.8, 0.85, 0.92)})
			box(Vector3(sx * 9.6, 0.5, z + 7.6), Vector3(1.6, 1.0, 1.6), "marble_soft")
			box(Vector3(sx * 9.6, 1.4, z + 7.6), Vector3(1.2, 0.7, 0.8), Color(0.98, 0.72, 0.82) if k % 2 == 0 else Color(0.75, 0.9, 1.0), {"col": false, "yaw": 25.0 * sx})
			box(Vector3(sx * 8.2, 0.45, z), Vector3(0.8, 0.9, 9.0), Color(0.2, 0.5, 0.26))
			k += 1
	for sx in [-1.0, 1.0]:
		blocker(Vector3(sx * 37, 4, -20), Vector3(1, 10, 60))
	txt("ПРОСПЕКТ ЧИСТОТЫ", Vector3(-13.9, 4.2, -2), 90, 0.6, {"col": Color(0.2, 0.55, 0.95)})
	for p in [Vector3(-4, 2.0, -4), Vector3(5, 2.0, -12)]:
		enemy("drone", p)
	for p in [Vector3(-3, 0.3, -8), Vector3(4, 0.3, -15)]:
		enemy("soap", p)
	crate(Vector3(17, 0, -10), [["cash", 15], ["doshik", 1]])
	crate(Vector3(-17, 0, -26), [["cash", 12], ["plums", 1]])
	trigger(Vector3(0, 1, -22), Vector3(7, 2, 1.5), _patrol, true, func(): return not G.flag("my_patrol"))
	trigger(Vector3(0, 1, -43), Vector3(4, 2, 2), func(): G.checkpoint("palace"))
	# маршрутка обратно к вокзалу
	wagon(Vector3(11.5, 0.0, -45), 5.6, WHITE, false, {"w": 2.2, "h": 2.2, "base": 0.5, "stripe": Color(0.2, 0.55, 0.95)})
	txt("ЧИСТАЯ ЛИНИЯ", Vector3(10.36, 1.25, -45), -90, 0.24, {"col": Color(0.2, 0.55, 0.95), "outline": 0})
	interact(Vector3(9.8, 1.0, -45), 2.4, "Маршрутка до вокзала", func():
		await cut(func():
			await G.ui.fade_to(1.0, 0.4)
			G.player.place(Vector3(0, 0.1, 62), PI)
			G.cam.snap()
			G.checkpoint("plaza", true)
			await G.wait(0.5)
			await G.ui.fade_to(0.0, 0.4))
		_goal(), {"cond": func(): return G.flag("my_boss")})


func _palace() -> void:
	slab(-24, -106, 24, -50, 0.05, "mosaic_soft", 0.1, {"col": false})
	wall(-24, -50, -3.6, -50, 0, 9.0, "marble_soft", 0.8)
	wall(3.6, -50, 24, -50, 0, 9.0, "marble_soft", 0.8)
	wall(-24, -106, 24, -106, 0, 9.0, "marble_soft", 0.8)
	wall(-24, -106, -24, -50, 0, 9.0, "marble_soft", 0.8)
	wall(24, -106, 24, -50, 0, 9.0, "marble_soft", 0.8)
	box(Vector3(0, 8.2, -50), Vector3(8.0, 1.6, 0.9), "marble_soft", {"col": false})
	txt("ДВОРЕЦ ЧИСТОТЫ", Vector3(0, 8.2, -49.5), 0, 0.9, {"col": Color(0.2, 0.55, 0.95), "outline": 0})
	for z in [-60.0, -72.0, -84.0, -96.0]:
		for sx in [-13.0, 13.0]:
			cyl(Vector3(sx, 4.5, z), 0.9, 9.0, "marble_soft", {"seg": 12})
			cyl(Vector3(sx, 9.1, z), 1.2, 0.3, "marble_soft", {"col": false, "seg": 12})
	# трон-умывальник
	box(Vector3(0, 0.8, -102.5), Vector3(8.0, 1.6, 3.0), "marble_soft")
	box(Vector3(0, 1.62, -102.3), Vector3(6.8, 0.06, 2.0), "water", {"col": false})
	box(Vector3(0, 4.6, -105.3), Vector3(6.0, 5.0, 0.2), Color(0.75, 0.88, 0.95), {"col": false})
	cyl(Vector3(0, 2.6, -104.4), 0.2, 2.0, "gold", {"col": false})
	box(Vector3(0, 3.6, -103.6), Vector3(0.3, 0.3, 1.8), "gold", {"col": false})
	txt("ДА ЗДРАВСТВУЕТ МЫЛО ДУШИСТОЕ", Vector3(-23.5, 6.0, -78), 90, 0.8, {"col": Color(0.2, 0.55, 0.95), "outline": 0})
	txt("И ПОЛОТЕНЦЕ ПУШИСТОЕ", Vector3(23.5, 6.0, -78), -90, 0.8, {"col": Color(0.2, 0.55, 0.95), "outline": 0})
	if not G.flag("my_boss"):
		boss = Moidodyr.new()
		add_child(boss)
		boss.global_position = Vector3(0, 0.2, -96)
		boss.home = boss.global_position
		boss.arena = HALL
		boss.set_yaw(PI)
		trigger(Vector3(0, 1.5, -54.5), Vector3(4, 2.5, 1.5), _boss_intro)


func _people() -> void:
	guard_npc = npc("clean_guard", Vector3(4.8, 0, 12.4), 180, {"talk": _talk_guard, "mark": "!" if not G.flag("my_talk") else ""})
	bath = npc("banshica", Vector3(-18.8, 0, 30.6), 90, {"talk": _talk_bath})
	npc("seller", Vector3(21.4, 0, 28.5), 90, {"mark": "₽", "label": "Купить", "talk": func():
		await say([["seller", "Мыла нет. Мыло — стратегический запас Дворца. Есть всё остальное."]])
		Menus.shop(G.ui, "МЫЛЬНЫЙ РЯД", "Всё, кроме мыла", ["milk", "doshik", "energy", "tasty", "chain"])
		await G.ui.panel_closed})
	npc(Bestiary.GOP2, Vector3(42.4, 0, 19.4), 60, {"name": "Грязнуля", "anim": "Squat", "mark": "?" if not G.flag("my_dirty") else "", "talk": _talk_dirty})
	trigger(Vector3(0, 1, 40), Vector3(3, 2, 2), func():
		if String(G.save["cp"]) == "start":
			G.checkpoint("plaza"))


func begin(cp_name: String) -> void:
	if cp_name == "start" and not G.flag("my_seen"):
		G.set_flag("my_seen")
		title_card()
	_goal()


func _goal() -> void:
	if G.flag("my_boss"):
		if G.player and G.player.global_position.z < 0.0:
			G.goal("Кнопка «Э» у тебя! Маршрутка довезёт до вокзала", Vector3(9.8, 0, -45))
		else:
			G.goal("Кнопка «Э» у тебя! Возвращайся на «поез» в Мурино", Vector3(3, 0.9, 76))
	elif G.flag("my_gate"):
		G.goal("Иди во Дворец Чистоты по проспекту", Vector3(0, 0, -52))
	elif G.has("pass_clean"):
		G.goal("Покажи пропуск вахтёру чистоты", Vector3(4.8, 0, 12.4))
	elif G.count("soap") >= 3:
		G.goal("Помойся в Помывочной № 1. Осторожно: кипяток!", Vector3(-15, 0, 21.5))
	elif G.flag("my_talk"):
		var at := Vector3(-21, 0, 53)
		if G.flag("my_s1"):
			at = Vector3(22.9, 0, 62.5) if not G.flag("my_s2") else Vector3(6.6, 0, 51.3)
		G.goal("Найди три куска мыла: прачечная, крыша склада, фонтан (%d/3)" % G.count("soap"), at)
	else:
		G.goal("Подойди к санпропускнику", Vector3(4.8, 0, 12.4))


func _talk_guard() -> void:
	if G.flag("my_boss"):
		await say([["clean_guard", "Мойдодыр… сломан? Значит, можно не мыть руки? …Нет. Привычка."]])
	elif G.flag("my_gate"):
		await say([["clean_guard", "Проходи, гражданин. Дворец — прямо по проспекту. Ноги вытирай."]])
	elif G.has("pass_clean"):
		await say([["clean_guard", "Руки. …Чистые. Скрипят. Пропуск. …Настоящий."], ["clean_guard", "Проходи, гражданин. Мойдодыр принимает во Дворце Чистоты. Ноги вытирай."]])
		G.set_flag("my_gate")
		barrier_off(gate)
		Snd.sfx("unlock", 0.0)
	elif G.flag("my_talk"):
		await say([["clean_guard", "Помывочная № 1 — к западу, с трубой. Мыло своё: три куска. Без пропуска не пущу."]])
	else:
		await say([["clean_guard", "Стоять. Руки. …Грязные. Грязным вход воспрещён."],
			["ch", "Что за бизнес? Я с дороги. Мне бы кнопку от ливта — такую, с буквой «Э»."],
			["clean_guard", "Кнопка — во Дворце Чистоты, у самого Мойдодыра. Он её лично отмыл. Но к нему — только с пропуском «Чистые руки»."],
			["clean_guard", "Пропуск выдают в Помывочной № 1. Мыло своё: три куска. Говорят, один завалялся в прачечной, один — на крыше склада, а третий мусолит фонтан."]])
		G.set_flag("my_talk")
		guard_npc.set_mark("")
	_goal()


func _talk_bath() -> void:
	if G.has("pass_clean") or G.flag("my_gate"):
		await say([["banshica", "С лёгким паром. Ещё раз? Нет? Ну и ходи чистый."]])
	elif G.count("soap") >= 3:
		await say([["banshica", "Три куска! Богато. А ну встань ровно… Да не дёргайся ты."], ["ch", "Ам-ам-ам! Горячо!"],
			["banshica", "Всё. Чистые руки — чистая совесть. Держи пропуск. Выход — вон там, я открою."]])
		G.take("soap", 3)
		G.give("pass_clean")
		barrier_off(bath_gate)
	else:
		await say([["banshica", "Через кипяток прошёл, а мыла не принёс? Без мыла не мою. Три куска неси: прачечная, склад, фонтан."]])
	_goal()


func _talk_dirty() -> void:
	if G.flag("my_dirty"):
		await say([[{"n": "Грязнуля"}, "Вкусно было. Жирно. Я теперь ещё неделю мыться не буду."]])
	elif G.has("shawa"):
		await say([[{"n": "Грязнуля"}, "Чую… муринская! С мясом! Давай сюда!"], ["ch", "Держи. Только руки… ладно, не мой."],
			[{"n": "Грязнуля"}, "Спаситель! На, цепь. Золотая. Немытая. Тут за неё штраф, а тебе в самый раз."]])
		G.take("shawa")
		G.give("chain")
		G.set_flag("my_dirty")
	else:
		await say([[{"n": "Грязнуля"}, "Псс. Ч. Я тут последний немытый. Третий день за баками прячусь."],
			[{"n": "Грязнуля"}, "Шавермы бы. Жирной, муринской. Принесёшь — отдам кое-что блестящее."]])


func _fountain() -> void:
	await cut(func():
		await say([["ch", "Мыло лежит на самом верху, под струёй. Кипяток… Надо перекрыть воду."]])
		var ok: bool = await Puzzles.switches(G.ui, "ВЕНТИЛЬ ФОНТАНА", "Перекрой подачу: вентили должны дать ровно 70 атмосфер.", [10, 20, 30, 40, 50, 60], 70, "атм")
		if not ok:
			return
		G.set_flag("my_fountain")
		if jet:
			if jet.has_meta("soap"):
				(jet.get_meta("soap") as Node).queue_free()
			jet.queue_free()
			jet = null
		Snd.sfx("unlock", 0.0, 0.8)
		pickup("soap", Vector3(3.2, 0.8, 46.6), 1, {"on_take": func():
			G.set_flag("my_s3")
			_goal()}).toss()
		await say([["ch", "Струя стихла — и мыло смыло на плитку. Что за бизнес."]]))


func _laundry_fight() -> void:
	G.toast("Машинки выплюнули мыть!", "")
	Snd.sfx("alert", 0.0)
	wave([["soap", Vector3(-42, 0.3, 48)], ["soap", Vector3(-42, 0.3, 58)], ["soap", Vector3(-30, 0.3, 48)], ["drone_walk", Vector3(-40, 0.3, 53)]], func():
		if not is_inside_tree():
			return
		wave([["drone_walk", Vector3(-42, 0.3, 47)], ["drone_walk", Vector3(-42, 0.3, 59)], ["soap", Vector3(-28, 0.3, 58)], ["soap", Vector3(-36, 0.3, 57)]], func():
			if not is_inside_tree():
				return
			G.set_flag("my_l")
			Snd.sfx("win", -4.0)
			G.toast("В дальней машинке что-то стукнуло: мыло!", "")
			_soap1()))


func _patrol() -> void:
	patrol_gate = barrier(Vector3(0, 2, -40), Vector3(14, 4, 0.3), Color(0.6, 0.9, 1.0, 0.4))
	G.ui.big_text("ТРЕВОГА: ГРЯЗЬ НА ПРОСПЕКТЕ!")
	Snd.sfx("alert", 0.0)
	wave([["drone", Vector3(-5, 2, -30)], ["drone", Vector3(5, 2, -30)], ["drone_walk", Vector3(-3, 0.3, -34)], ["drone_walk", Vector3(3, 0.3, -34)], ["soap", Vector3(0, 0.3, -28)]], func():
		if not is_inside_tree():
			return
		G.set_flag("my_patrol")
		barrier_off(patrol_gate)
		Snd.sfx("win", -4.0)
		G.toast("Патруль чистоты разбит", ""))


func _boss_intro() -> void:
	hall_gate = barrier(Vector3(0, 2.5, -50.6), Vector3(7.2, 5, 0.4), Color(0.6, 0.9, 1.0, 0.45))
	await cut(func():
		Snd.music("boss")
		G.cam.shot(Vector3(6, 3.0, -84), Vector3(0, 2.2, -96), 55.0)
		await G.wait(0.8)
		await say([["ch", "Ничего себе хамам… Чистенько."],
			["moidodyr", "Я — ВЕЛИКИЙ УМЫВАЛЬНИК, ЗНАМЕНИТЫЙ МОЙДОДЫР. А ТЫ — ГРЯЗНУЛЯ ИЗ МУРИНО."],
			["ch", "Я помылся! У меня пропуск!"],
			["moidodyr", "ПРОПУСК — БУМАЖКА. КНОПКА — МОЯ: Я ЕЁ ОТМЫЛ. К ДУШУ!"]])
		boss.play("Hello", 0.1, 1.0, true)
		Snd.sfx("roar", 0.0, 1.1)
		G.cam.shake(0.7)
		G.ui.big_title("МОЙДОДЫР", "БОСС")
		await G.wait(1.2)
		G.cam.end_shot())
	boss.on_defeat = _boss_dead
	boss.start()
	G.goal("Победи Мойдодыра. Уведи его таран в колонну или дождись перегрева после душа!")


func test_boss() -> void:
	G.player.place(Vector3(0, 0.1, -54.5), 0.0)


func _boss_dead() -> void:
	G.set_flag("my_boss")
	Story.mark_done("myt")
	Snd.music(music)
	Snd.sfx("win", 0.0)
	G.pay(100)
	barrier_off(hall_gate)
	await cut(func():
		await say([["moidodyr", "БУЛЬ… БУЛЬ… КРАН… ТЕЧЁТ…"], ["ch", "Кнопка «Э». Идеально чистая. Две есть. Что за бизнес — отмывать чужие кнопки."]])
		G.give("btn2"))
	G.checkpoint("palace", true)
	_goal()
