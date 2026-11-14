extends Level
## ФИНАЛ — ПЕРВЫЙ ЭТАЖ. 23:59. Парадная П-46, двор в тумане и ФОГ.

const R := 22.0
const RED := Color(1.0, 0.3, 0.25)
const GREEN := Color(0.5, 1.0, 0.55)

var boss: FogBoss
var clock: Label3D
var won := false
var fog_now := 0.03
var yard_gate := {}


func build() -> void:
	title = "ПЕРВЫЙ ЭТАЖ"
	chapter = "ФИНАЛ · 23:59"
	music = "fog"
	won = G.flag("f_boss")
	fog_now = 0.006 if won else 0.03
	set_env("night", {"fog": Color(0.34, 0.37, 0.45), "fog_d": fog_now, "amb": 0.75, "fog_sky": 0.2 if won else 0.95})
	_house()
	_yard()
	cp("start", Vector3(0, 0.1, 43.5), 0)
	cp("yard", Vector3(0, 0.1, 27), 0)
	tick(_fog_tick)
	if won:
		_drun()
	else:
		_boss()


func _fog_tick(dt: float) -> void:
	var want := 0.006
	if boss and is_instance_valid(boss) and not boss.dead:
		want = boss.fog_d if boss.active else 0.03
	fog_now = lerpf(fog_now, want, clampf(dt * 0.7, 0.0, 1.0))
	env.fog_density = fog_now
	env.fog_sky_affect = clampf(fog_now / 0.03, 0.2, 0.95)


func _house() -> void:
	slab(-130, -130, 130, 130, 0.0, "asphalt", 1.0)
	building(Vector3(0, 0, 60), Vector3(96, 90, 28), "facade_panel")
	txt("П-46", Vector3(0, 15.5, 45.8), 180, 4.0, {"col": RED, "glow": 1.8})
	box(Vector3(0, 9.4, 45.8), Vector3(8.4, 3.0, 0.2), Color(0.03, 0.03, 0.03), {"col": false})
	clock = txt("00:00" if won else "23:59", Vector3(0, 9.4, 45.66), 180, 2.2, {"col": GREEN if won else RED, "glow": 2.0, "outline": 0})
	# парадная: x -7..7, z 32..46
	slab(-7, 32, 7, 46, 0.05, "tiles", 0.1, {"col": false})
	room(-7, 32, 7, 46, 0, 4.0, ["plaster_green", "plaster", 1.5], {"n": [[0.0, 2.6, 2.7]]}, 0.4)
	ceiling(-7, 32, 7, 46, 4.0, "ceiling")
	box(Vector3(0, 4.3, 39), Vector3(15, 0.4, 15), "concrete_dark", {"col": false})
	ceil_lamp(Vector3(-3, 3.95, 42), Color(1.0, 0.9, 0.7), 2.0, 9.0)
	ceil_lamp(Vector3(3, 3.95, 36), Color(1.0, 0.9, 0.7), 2.0, 9.0)
	box(Vector3(0, 1.5, 45.75), Vector3(2.8, 3.0, 0.1), "metal", {"col": false})
	box(Vector3(0, 1.5, 45.7), Vector3(0.06, 3.0, 0.1), "black", {"col": false})
	txt("ЛИВТ · 1 ЭТАЖ", Vector3(0, 3.4, 45.7), 180, 0.34, {"col": GREEN, "glow": 1.2, "outline": 6})
	for i in 8:
		box(Vector3(-6.7, 1.5, 34.5 + i * 0.9), Vector3(0.3, 0.6, 0.8), "metal_dark", {"col": false})
	txt("ВЫХОД ВО ДВОР", Vector3(0, 3.3, 32.3), 180, 0.3, {"col": RED, "glow": 1.0, "outline": 6})
	# автомат с вкусностями
	box(Vector3(6.2, 1.1, 39), Vector3(0.9, 2.2, 1.3), "metal_dark")
	box(Vector3(5.73, 1.3, 39), Vector3(0.04, 1.3, 1.0), Mats.glow(Color(1.0, 0.8, 0.4), 1.6), {"col": false})
	txt("ВКУСНОСТИ", Vector3(5.7, 2.35, 39), -90, 0.2, {"col": Color(1.0, 0.85, 0.3), "glow": 1.0, "outline": 5})
	interact(Vector3(5.4, 1.1, 39), 2.2, "Автомат с вкусностями", func():
		Menus.shop(G.ui, "АВТОМАТ", "Последний шанс закупиться", ["doshik", "shawa", "kvass", "energy", "tasty"])
		await G.ui.panel_closed)
	door(Vector3(0, 0, 32), 0, {"w": 2.6, "h": 2.7, "label": "Выйти во двор", "mat": "metal_dark"})
	if not won:
		crate(Vector3(-5.4, 0, 44.4), [["doshik", 1], ["cash", 20]])
		crate(Vector3(-5.4, 0, 33.6), [["plums", 1]])
		pickup("kvass", Vector3(4.6, 0.8, 44.4))
	# далёкие дома в тумане
	var far := [[Vector3(-70, 0, -10), Vector3(14, 60, 54)], [Vector3(72, 0, 6), Vector3(14, 72, 54)], [Vector3(-40, 0, -76), Vector3(54, 48, 14)], [Vector3(44, 0, -78), Vector3(54, 66, 14)],
		[Vector3(0, 0, -112), Vector3(60, 90, 16)], [Vector3(-110, 0, 40), Vector3(14, 78, 54)], [Vector3(112, 0, -50), Vector3(14, 54, 54)]]
	for f in far:
		building(f[0], f[1], "facade_panel", {"col": false, "lit": 1.2})


func _yard() -> void:
	cyl(Vector3(0, 0.03, 0), R + 1.5, 0.06, "concrete_dark", {"col": false, "seg": 40})
	slab(-3.4, R, 3.4, 32, 0.04, "concrete_dark", 0.06, {"col": false})
	for i in 24:
		var a := TAU * i / 24.0
		if absf(angle_difference(a, PI * 0.5)) < 0.2:
			continue
		blocker(Vector3(cos(a) * (R + 2.6), 6, sin(a) * (R + 2.6)), Vector3(7.4, 14, 1), -rad_to_deg(a) + 90.0)
		box(Vector3(cos(a) * (R + 2.2), 0.2, sin(a) * (R + 2.2)), Vector3(6.6, 0.4, 0.4), "concrete", {"yaw": -rad_to_deg(a) + 90.0, "col": false})
	for sx in [-1.0, 1.0]:
		blocker(Vector3(sx * 4.6, 5, 28), Vector3(1, 12, 9))
	for i in 6:
		var a := TAU * i / 6.0 + 0.52
		post(Vector3(cos(a) * (R - 1.4), 0, sin(a) * (R - 1.4)), 0, Color(0.8, 0.88, 1.0))
	bench(Vector3(-13, 0, 16.5), 140)
	bench(Vector3(13, 0, 16.5), -140)
	# детская площадка: всё, что от неё осталось
	for sx in [-1.2, 1.2]:
		cyl(Vector3(-17 + sx, 1.3, -6), 0.07, 2.6, "red", {"seg": 6})
	box(Vector3(-17, 2.6, -6), Vector3(2.6, 0.1, 0.1), "red", {"col": false})
	box(Vector3(-17, 0.6, -6), Vector3(0.7, 0.06, 0.3), "wood", {"col": false})
	box(Vector3(17, 0.2, -8), Vector3(3.0, 0.4, 3.0), "wood")
	box(Vector3(17, 0.42, -8), Vector3(2.6, 0.04, 2.6), "sand", {"col": false})
	if not won:
		for it in [["plums", Vector3(-16, 0.8, 9)], ["plums", Vector3(16, 0.8, 9)], ["shawa", Vector3(-19, 0.8, -3)], ["kvass", Vector3(19, 0.8, -3)], ["doshik", Vector3(0, 0.8, 19.5)]]:
			pickup(it[0], it[1])
		for p in [Vector3(-12, 0, 15), Vector3(12, 0, 15), Vector3(-20, 0, 4), Vector3(20, 0, 4)]:
			crate(p, [])


func _boss() -> void:
	boss = FogBoss.new()
	add_child(boss)
	boss.global_position = Vector3(0, 9.0, -10)
	boss.home = boss.global_position
	boss.arena = Vector3.ZERO
	boss.make_head(self, Vector3(0, 9.5, -27))
	boss.palm.visible = false
	trigger(Vector3(0, 1.5, 17.5), Vector3(9, 2.5, 1.5), _boss_intro)


func _drun() -> void:
	npc("drun", Vector3(0, 0, 6), 180, {"anim": "Dance", "mark": "!", "look": false, "talk": func():
		await say([["drun", "Ч! Ты это сделал! Тридцать второе августа, ноль-ноль — и ни тумана, ни пакостей. Ам-ам-ам!"]])
		var c: int = await G.ui.choose("drun", "Что дальше, Ч?", ["Сразиться с ФОГом ещё раз", "Вернуться в Мурино", "Итоги", "Посидим"])
		if c == 0:
			G.set_flag("f_boss", false)
			G.set_flag("f_met", false)
			G.travel("final", "yard")
		elif c == 1:
			G.travel("murino", "lobby")
		elif c == 2:
			Menus.ending(G.ui, G.has("btn5"))
		else:
			await say([["drun", "Посидим. Заслужил."]])})


func begin(cp_name: String) -> void:
	if won:
		G.goal("Туман ушёл. Поговори с Друном во дворе", Vector3(0, 0, 6))
		return
	G.goal("Выйди во двор", Vector3(0, 0, 30))
	if cp_name == "start" and not G.flag("f_seen"):
		G.set_flag("f_seen")
		title_card()
		await G.wait(1.2)
		await cut(func(): await say([["lift", "*дзынь* Первый этаж. Двери открываются. Дальше — сам."],
			["phone", "*бзззз* Друн: «Ч! Ты внизу? Он во дворе. Он везде. В автомате — вкусности, закупись. И кричи „ам-ам-ам“, когда он вдохнёт!»"],
			["ch", "23:59. За дверью — только туман. Ну, посидим…"]]))


func _boss_intro() -> void:
	yard_gate = barrier(Vector3(0, 3, R + 1.4), Vector3(8.4, 6, 0.4), Color(0.8, 0.84, 0.92, 0.5))
	await cut(func():
		Snd.music("boss")
		G.cam.shot(Vector3(0, 2.2, 12), Vector3(0, 9, -24), 62.0)
		boss.palm.visible = true
		boss.rise_up()
		Snd.sfx("roar", 0.0, 0.6)
		G.cam.shake(0.6)
		await G.wait(2.2)
		if not G.flag("f_met"):
			G.set_flag("f_met")
			await say([["fog", "Ч-ч-ч…"], ["fog", "Никто не уезжает из Мурино. Мурино — это я."],
				["ch", "Ты — сырость над болотом. А я прошёл Молочное, Мытищи, Баньку и Жмурино. Я даже помылся!"],
				["fog", "Тогда оставайся чистым. Навсегда."], ["ch", "АМ-АМ-АМ!"]])
		Snd.sfx("roar", 0.0, 0.8)
		G.cam.shake(1.0)
		G.ui.big_title("ФОГ", "ФИНАЛЬНЫЙ БОСС")
		await G.wait(1.4)
		G.cam.end_shot())
	boss.on_defeat = _boss_dead
	boss.start()
	G.goal("Победи ФОГа. Бей по ладони, пока она застряла в асфальте!")
	G.toast("Красный круг — беги. Кольца тумана перепрыгивай. ФОГ вдыхает — кричи «АМ-АМ-АМ»: %s" % Inp.hint("ult"), "")


func test_boss() -> void:
	G.player.place(Vector3(0, 0.1, 17.5), 0.0)


func _boss_dead() -> void:
	G.set_flag("f_boss")
	Story.mark_done("final")
	barrier_off(yard_gate)
	won = true
	await cut(func():
		G.cam.shot(Vector3(0, 2.4, 14), Vector3(0, 6, -14), 55.0)
		await G.wait(1.2)
		await say([["fog", "Ч-ч-ч… Ты… просто… ветер…"], ["ch", "Я не ветер. Я — Ч. И я приехал на первый этаж."],
			[{"n": ""}, "Туман редеет. Над Мурино впервые за лето видно звёзды."]])
		clock.text = "00:00"
		clock.modulate = Color(GREEN.r * 3.0, GREEN.g * 3.0, GREEN.b * 3.0)
		Snd.sfx("win", 0.0)
		Snd.music("win")
		G.cam.shot(Vector3(0, 2.6, 6), Vector3(0, 9.4, 45), 50.0, 1.3)
		await G.wait(2.2)
		await say([["phone", "*бзззз* Друн: «Ч! Ноль-ноль! Тридцать второе августа! Ты успел! Ам-ам-ам!»"],
			["phone", "Дод: «Посидим?» Брал: «Дай хотя бы хлеба!»"], ["ch", "Посидим. Только сначала — помоюсь."]])
		if G.has("btn5"):
			await say([["lift", "*дзынь* Кнопка «Ж» встала на место. На табло — «1 ЭТАЖ». Ливт починен."], ["ch", "Что за бизнес… Работает!"]])
		G.cam.end_shot())
	G.checkpoint("yard", true)
	G.goal("Туман ушёл. Поговори с Друном во дворе", Vector3(0, 0, 6))
	_drun()
	Menus.ending(G.ui, G.has("btn5"))
