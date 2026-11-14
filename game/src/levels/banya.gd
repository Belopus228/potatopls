extends Level
## ГЛАВА 5 — БАНЬКА. Заснеженный полустанок, двор Пра Дода, лес с дровами (вырубка, берлога, старая сосна),
## озеро с тонким льдом и островом, баня: предбанник, мыльня с паром и парилка с Банником.

const STEAM := Vector3(0, 0, -62)
const ISLE := Vector3(38, 0, 10)
const ICE_PATH := [Vector3(13, 0, 12), Vector3(20, 0, 16), Vector3(25, 0, 9), Vector3(30, 0, 14), Vector3(33.5, 0, 10.5)]
const ICE_PATH2 := [Vector3(42, 0, 13), Vector3(46, 0, 20), Vector3(50, 0, 28)]

var pra: Npc
var boss: Bannik
var hall_gate := {}
var ice_safe := Vector3(13, 0.1, 12)
var ice_t := 0.0
var snow_fx: CPUParticles3D


func build() -> void:
	title = "БАНЬКА"
	chapter = "ГЛАВА 5"
	music = "banya"
	steps = "snow"
	set_env("snow")
	_ground()
	_yard()
	_forest()
	_lake()
	_bath()
	_people()
	cp("start", Vector3(0, 1.0, 72.5), 0)
	cp("yard", Vector3(0, 0.1, 30), 0)
	cp("bath", Vector3(0, 0.1, -33), 0)
	snow_fx = Fx.emitter(Color(1, 1, 1, 0.9), 260, 4.5, 0.07, Vector3(0.2, -1, 0.1), 3.0, 25.0, Vector3(0, -1.0, 0), Vector3(20, 0.5, 20))
	add_child(snow_fx)
	tick(_weather)


func _weather(dt: float) -> void:
	var p := G.player
	if p == null:
		return
	var pp := p.global_position
	var inside: bool = absf(pp.x) < 16.0 and pp.z < -30.0 and pp.z > -77.0
	snow_fx.emitting = not inside
	snow_fx.global_position = pp + Vector3(0, 9, 0)
	if G.mode != "play" or p.dead:
		return
	# тонкий лёд
	if pp.x > 14.5 and pp.x < 58.0 and pp.z > -18.0 and pp.z < 40.0 and pp.y < 0.6:
		if _ice_ok(pp):
			ice_safe = pp
			ice_t = 0.0
		else:
			if ice_t == 0.0:
				Snd.sfx("crate", -3.0, 1.6)
				G.toast("Лёд трещит! Назад, к вешкам!", "small")
			ice_t += dt
			if ice_t > 0.9:
				ice_t = 0.0
				Snd.sfx("break", 0.0, 0.7)
				Fx.burst(self, pp + Vector3(0, 0.3, 0), Color(0.7, 0.85, 1.0), 16, 6.0)
				p.hurt(12.0, pp, 0.0, true)
				if not p.dead:
					p.place(ice_safe + Vector3(0, 0.1, 0), p.yaw)
					G.toast("Купель. Бесплатная. Иди по вешкам", "small")
	else:
		ice_t = 0.0


func _seg_dist(p: Vector3, a: Vector3, b: Vector3) -> float:
	var ab := Vector2(b.x - a.x, b.z - a.z)
	var ap := Vector2(p.x - a.x, p.z - a.z)
	var f := clampf(ap.dot(ab) / maxf(ab.length_squared(), 0.001), 0.0, 1.0)
	return (ap - ab * f).length()


func _ice_ok(p: Vector3) -> bool:
	if Vector2(p.x - ISLE.x, p.z - ISLE.z).length() < 6.2:
		return true
	if Vector2(p.x - 17.5, p.z - 23.0).length() < 3.4 or Vector2(p.x - 50.0, p.z - 29.5).length() < 3.0:
		return true
	for i in ICE_PATH.size() - 1:
		if _seg_dist(p, ICE_PATH[i], ICE_PATH[i + 1]) < 2.3:
			return true
	for i in ICE_PATH2.size() - 1:
		if _seg_dist(p, ICE_PATH2[i], ICE_PATH2[i + 1]) < 2.3:
			return true
	return _seg_dist(p, Vector3(16, 0, 14), Vector3(17.5, 0, 22)) < 2.3


func _ground() -> void:
	slab(-80, -100, 80, 95, 0.0, "snow", 1.0)
	arrival(Vector3(0, 0.9, 74), "ПОЛУСТАНОК «БАНЬКА»", {"col": Color(0.45, 0.2, 0.16), "mat": "planks"})
	slab(-2.2, -30, 2.2, 67, 0.03, "dirt", 0.06, {"col": false})
	blocker(Vector3(-60, 4, -10), Vector3(1, 12, 200))
	blocker(Vector3(60, 4, -10), Vector3(1, 12, 200))
	blocker(Vector3(0, 4, -84), Vector3(130, 12, 1))
	for rc in [Rect2(-78, -90, 17, 170), Rect2(61, -90, 17, 170), Rect2(-60, -98, 120, 13)]:
		scatter(["nature/PineTree_Snow_1", "nature/PineTree_Snow_2", "nature/PineTree_Snow_3", "nature/PineTree_Snow_4"], Vector3.ZERO, 1.0, 44, {"sc": [2.6, 3.8], "rect": rc, "col": "none"})


func _yard() -> void:
	# двор Пра Дода
	hut(Vector3(-9.5, 0, 22), Vector3(8, 3.2, 7), {"door": "e", "lit": true})
	lamp(Vector3(-4.6, 2.4, 22), Color(1.0, 0.75, 0.45), 2.2, 9.0)
	for i in 3:
		for j in 2:
			var lg := cyl(Vector3(-13.0 + i * 0.5, 0.25 + j * 0.46, 16.6), 0.23, 2.2, "wood_dark", {"col": false, "seg": 8})
			lg.rotation.x = PI * 0.5
	blocker(Vector3(-12.5, 0.5, 16.6), Vector3(1.8, 1.0, 2.4))
	prop("village/Well", Vector3(6.5, 0, 24), 0, 1.0, {"h": 2.4})
	fence(-16, 28, -3.5, 28)
	fence(-16, 14, -16, 28)
	bench(Vector3(-3.4, 0, 18.5), 90)
	board("БАНЯ ПРА ДОДА\nс 1889 года. Без веника не входить", Vector3(3.6, 1.9, 33), 0, 4.4, 1.1, {"col": Color(0.95, 0.9, 0.8), "bg": Color(0.3, 0.2, 0.14)})
	for sx in [-1.9, 1.9]:
		cyl(Vector3(3.6 + sx, 0.9, 33), 0.07, 1.8, "wood_dark")
	# указатели
	board("← ЛЕС (дрова)", Vector3(-3.2, 1.6, 8), 0, 2.6, 0.5, {"col": Color(0.95, 0.9, 0.8), "bg": Color(0.3, 0.2, 0.14)})
	cyl(Vector3(-3.2, 0.8, 8), 0.06, 1.6, "wood_dark")
	board("ОЗЕРО (веник) →", Vector3(3.2, 1.6, 8), 0, 2.8, 0.5, {"col": Color(0.95, 0.9, 0.8), "bg": Color(0.3, 0.2, 0.14)})
	cyl(Vector3(3.2, 0.8, 8), 0.06, 1.6, "wood_dark")
	# сани обратно к полустанку
	box(Vector3(5.2, 0.4, -26), Vector3(1.3, 0.3, 2.6), "wood")
	for sx in [-0.6, 0.6]:
		box(Vector3(5.2 + sx, 0.12, -26), Vector3(0.08, 0.1, 3.2), "metal_dark", {"col": false})
	box(Vector3(5.2, 0.85, -27.2), Vector3(1.3, 0.7, 0.1), "wood", {"col": false})
	interact(Vector3(5.2, 0.8, -24.4), 2.4, "Сани до полустанка", func():
		await cut(func():
			await G.ui.fade_to(1.0, 0.4)
			G.player.place(Vector3(0, 0.1, 62), PI)
			G.cam.snap()
			G.checkpoint("yard", true)
			await G.wait(0.5)
			await G.ui.fade_to(0.0, 0.4))
		_goal(), {"cond": func(): return G.flag("bn_boss")})
	scatter(["nature/PineTree_Snow_1", "nature/PineTree_Snow_3", "nature/BirchTree_Snow_1", "nature/BirchTree_Snow_2", "nature/CommonTree_Snow_1"], Vector3.ZERO, 1.0, 26,
		{"sc": [2.4, 3.4], "rect": Rect2(-14, 34, 28, 30), "avoid_rects": [Rect2(-4.5, 30, 9, 40)]})
	for p in [Vector3(-6, 0.3, 50), Vector3(7, 0.3, 44)]:
		enemy("snowblob", p)
	crate(Vector3(9, 0, 56), [["cash", 10], ["bread", 1]])


func _wood(flag: String, pos: Vector3) -> void:
	for i in 3:
		var lg := cyl(pos + Vector3(-0.3 + i * 0.3, 0.2, 0.9), 0.18, 1.3, "wood", {"col": false, "seg": 8})
		lg.rotation.z = PI * 0.5
	if not G.flag(flag) and not G.flag("bn_fire"):
		pickup("wood", pos + Vector3(0, 0.7, 0), 1, {"on_take": func():
			G.set_flag(flag)
			_goal()})


func _forest() -> void:
	var avoid: Array = [[Vector3(-38, 0, 40), 8.0], [Vector3(-46, 0, 4), 8.0], [Vector3(-30, 0, -22), 7.0]]
	for seg in [[Vector3(-2, 0, 10), Vector3(-22, 0, 14)], [Vector3(-22, 0, 14), Vector3(-38, 0, 40)], [Vector3(-22, 0, 14), Vector3(-46, 0, 4)], [Vector3(-22, 0, 14), Vector3(-30, 0, -22)]]:
		var a: Vector3 = seg[0]
		var b: Vector3 = seg[1]
		var d := b - a
		box((a + b) * 0.5 + Vector3(0, 0.04, 0), Vector3(2.6, 0.06, d.length() + 1.5), "dirt", {"yaw": rad_to_deg(atan2(d.x, d.z)), "col": false})
		for f in [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]:
			avoid.append([a + d * f, 3.6])
	scatter(["nature/PineTree_Snow_1", "nature/PineTree_Snow_2", "nature/PineTree_Snow_3", "nature/PineTree_Snow_5", "nature/BirchTree_Snow_1", "nature/CommonTree_Snow_2", "nature/BirchTree_Dead_Snow_1"], Vector3.ZERO, 1.0, 130,
		{"sc": [2.3, 3.6], "rect": Rect2(-59, -34, 43, 96), "avoid": avoid})
	scatter(["nature/Bush_Snow_1", "nature/Bush_Snow_2", "nature/Rock_Snow_1", "nature/Rock_Snow_3", "nature/TreeStump_Snow", "nature/WoodLog_Snow"], Vector3.ZERO, 1.0, 46,
		{"sc": [0.8, 1.4], "rect": Rect2(-59, -34, 43, 96), "avoid": avoid, "col": "none"})
	# вырубка
	for p in [Vector3(-41, 0, 43), Vector3(-35, 0, 37), Vector3(-42, 0, 36), Vector3(-34, 0, 44)]:
		prop("nature/TreeStump_Snow", p, rng.randf() * 360.0, 1.0, {"h": 0.6})
	prop("nature/WoodLog_Snow", Vector3(-39, 0, 45.5), 20, 1.0, {"w": 3.0})
	_wood("bn_w1", Vector3(-38, 0, 40))
	for p in [Vector3(-36, 0.3, 42), Vector3(-41, 0.3, 39), Vector3(-34, 0.3, 36)]:
		enemy("wolf", p)
	# берлога
	for a in [[Vector3(-50, 0, 2), 3.2], [Vector3(-48.5, 0, 8), 2.8], [Vector3(-50.5, 0, 5.4), 3.6]]:
		prop("nature/Rock_Snow_%d" % (1 + rng.randi() % 6), a[0], rng.randf() * 360.0, 1.0, {"h": a[1]})
	txt("БЕРЛОГА", Vector3(-49, 3.9, 5), 90, 0.4, {"col": Color(0.9, 0.5, 0.4), "outline": 8})
	_wood("bn_w2", Vector3(-45, 0, 4))
	enemy("steamer", Vector3(-44, 0.3, 6))
	for p in [Vector3(-42, 0.3, 1), Vector3(-43, 0.3, 9)]:
		enemy("snowblob", p)
	# старая сосна
	prop("nature/PineTree_Snow_2", Vector3(-31.5, 0, -24), 0, 5.6, {"col": "trunk", "r": 0.7})
	txt("СТАРАЯ СОСНА", Vector3(-31.5, 3.0, -22.6), 0, 0.3, {"col": Color(0.9, 0.9, 0.8), "outline": 8})
	_wood("bn_w3", Vector3(-29, 0, -21))
	for p in [Vector3(-27, 0.3, -19), Vector3(-32, 0.3, -18), Vector3(-26, 0.3, -24)]:
		enemy("snowblob", p)
	enemy("wolf", Vector3(-30, 0.3, -15))
	crate(Vector3(-54, 0, -28), [["cash", 22], ["plums", 1]])
	crate(Vector3(-52, 0, 52), [["cash", 14], ["doshik", 1]])


func _pole(p: Vector3) -> void:
	cyl(p + Vector3(0, 0.9, 0), 0.05, 1.8, "wood_dark", {"col": false, "seg": 6})
	box(p + Vector3(0.25, 1.6, 0), Vector3(0.5, 0.3, 0.03), "red", {"col": false})


func _lake() -> void:
	slab(14.5, -18, 58, 40, 0.03, "ice", 0.06, {"col": false})
	slab(2.2, 10.8, 14.5, 13.2, 0.03, "dirt", 0.06, {"col": false})
	board("ЛЁД ТОНКИЙ!\nИДИ ПО ВЕШКАМ", Vector3(12.4, 1.6, 15.0), -90, 2.6, 0.9, {"col": Color(1.0, 0.85, 0.2), "bg": Color(0.5, 0.1, 0.08)})
	cyl(Vector3(12.4, 0.8, 15.0), 0.06, 1.6, "wood_dark")
	for path in [ICE_PATH, ICE_PATH2]:
		for i in path.size() - 1:
			var a: Vector3 = path[i]
			var b: Vector3 = path[i + 1]
			var d := b - a
			var n := Vector3(-d.z, 0, d.x).normalized()
			var cnt := maxi(2, int(d.length() / 2.6))
			for j in cnt + 1:
				var pt := a + d * (float(j) / cnt)
				_pole(pt + n * 1.5)
				_pole(pt - n * 1.5)
	# остров
	cyl(ISLE + Vector3(0, 0.05, 0), 5.6, 0.1, "snow", {"seg": 18, "col": false})
	prop("nature/CommonTree_Snow_1", ISLE + Vector3(-1.5, 0, -1.5), 0, 3.6)
	txt("ДУБ", ISLE + Vector3(-1.5, 3.2, -0.2), 0, 0.3, {"col": Color(0.9, 0.9, 0.8), "outline": 8})
	prop("nature/Rock_Snow_2", ISLE + Vector3(2.6, 0, -2.4), 40, 1.0, {"h": 1.2})
	if not G.has("broom") and not G.flag("bn_fire"):
		pickup("broom", ISLE + Vector3(0.6, 0.8, 0.8), 1, {"on_take": func(): _goal()})
	for p in [ISLE + Vector3(2.5, 0.3, 2), ISLE + Vector3(-2, 0.3, 2.8)]:
		enemy("snowblob", p, {"sight": 5.0})
	# прорубь с кладом
	cyl(Vector3(50, 0.05, 31), 1.0, 0.04, "water", {"col": false, "seg": 14})
	if not G.flag("bn_stash"):
		crate(Vector3(51, 0, 28.6), [["chain", 1], ["cash", 25]], {"on_break": func(): G.set_flag("bn_stash")})
	# лунка рыбака
	cyl(Vector3(18.6, 0.05, 24.2), 0.5, 0.04, "water", {"col": false, "seg": 12})
	box(Vector3(17.5, 0.2, 23), Vector3(0.5, 0.4, 0.5), "wood")
	scatter(["nature/PineTree_Snow_1", "nature/PineTree_Snow_3", "nature/BirchTree_Snow_3"], Vector3.ZERO, 1.0, 26, {"sc": [2.4, 3.4], "rect": Rect2(14, 41, 45, 26)})
	scatter(["nature/PineTree_Snow_1", "nature/PineTree_Snow_3", "nature/BirchTree_Snow_3"], Vector3.ZERO, 1.0, 22, {"sc": [2.4, 3.4], "rect": Rect2(18, -34, 41, 15)})
	scatter(["nature/PineTree_Snow_4", "nature/BirchTree_Snow_2"], Vector3.ZERO, 1.0, 8, {"sc": [2.4, 3.2], "rect": Rect2(5, -16, 8, 22)})
	for p in [Vector3(30, 0.3, 48), Vector3(40, 0.3, 46)]:
		enemy("wolf", p)


func _bath() -> void:
	# сруб бани: x -16..16, z -76..-30
	slab(-16, -76, 16, -30, 0.05, "planks", 0.1, {"col": false})
	wall_gaps(-16, -30, 16, -30, 0, 5.0, "logs", [[16.0, 2.6, 2.7]], 0.5)
	wall(-16, -76, 16, -76, 0, 5.0, "logs", 0.5)
	wall(-16, -76, -16, -30, 0, 5.0, "logs", 0.5)
	wall(16, -76, 16, -30, 0, 5.0, "logs", 0.5)
	wall_gaps(-16, -40, 16, -40, 0, 5.0, "logs", [[16.0, 2.6, 2.7]], 0.4)
	wall_gaps(-16, -48, 16, -48, 0, 5.0, "logs", [[16.0, 3.4, 3.2]], 0.4)
	ceiling(-16, -76, 16, -30, 5.0, "wood_dark")
	for sg in [-1.0, 1.0]:
		ramp(Vector3(sg * 17.5, 4.9, -53), Vector3(0, 10.0, -53), 48.0, "roof", 0.2)
	cyl(Vector3(9, 9.0, -60), 0.7, 5.0, "brick")
	var smoke := Fx.emitter(Color(0.75, 0.75, 0.78, 0.5), 30, 4.0, 0.9, Vector3(0.15, 1, 0), 1.6, 12.0, Vector3(0, 0.4, 0))
	smoke.position = Vector3(9, 11.6, -60)
	smoke.emitting = G.flag("bn_fire")
	smoke.name = "Smoke"
	add_child(smoke)
	txt("БАНЯ", Vector3(0, 3.9, -29.7), 0, 0.8, {"col": Color(1.0, 0.8, 0.5), "outline": 10})
	door(Vector3(0, 0, -30), 0, {"w": 2.6, "h": 2.7, "label": "Войти в баню", "mat": "wood_dark",
		"locked": func(): return "" if G.flag("bn_fire") else "Баня не топлена. Пра Дод без дров и веника не пустит",
		"on_open": func():
			if String(G.save["cp"]) != "bath":
				G.checkpoint("bath")})
	# предбанник
	ceil_lamp(Vector3(-7, 4.95, -35), Color(1.0, 0.8, 0.5), 2.2, 10.0)
	ceil_lamp(Vector3(7, 4.95, -35), Color(1.0, 0.8, 0.5), 2.2, 10.0)
	box(Vector3(-10, 0.45, -36), Vector3(3.0, 0.9, 1.4), "wood")
	cyl(Vector3(-10, 1.25, -36), 0.3, 0.7, "gold", {"col": false, "seg": 10})
	bench(Vector3(-10, 0, -38.4), 0)
	bench(Vector3(10, 0, -38.8), 0)
	for i in 4:
		box(Vector3(14.6, 2.2, -32 - i * 1.6), Vector3(0.1, 1.2, 0.8), Color(0.2, 0.45, 0.2), {"col": false})
	txt("ПОСИДИМ?", Vector3(-15.6, 3.2, -35), 90, 0.5, {"col": Color(1.0, 0.85, 0.6), "outline": 8})
	# мыльня: пар из щелей
	ceil_lamp(Vector3(0, 4.95, -44), Color(1.0, 0.7, 0.5), 2.0, 9.0)
	for i in 3:
		hazard(Vector3(0, 1.6, -42 - i * 2.0), Vector3(31.0, 3.2, 0.7), {"phase": i * 0.8, "on": 1.0, "off": 1.5, "dmg": 9.0, "col": Color(1.0, 0.85, 0.8, 0.5), "push": Vector3(0, 0, 1)})
	txt("МЫЛЬНЯ. ОСТОРОЖНО: ПАР", Vector3(0, 3.4, -40.25), 0, 0.3, {"col": Color(1.0, 0.6, 0.4), "outline": 8})
	# парилка
	for p in [Vector3(-9, 4.95, -56), Vector3(9, 4.95, -56), Vector3(-9, 4.95, -68), Vector3(9, 4.95, -68)]:
		ceil_lamp(p, Color(1.0, 0.6, 0.35), 2.4, 12.0)
	for sx in [-1.0, 1.0]:
		box(Vector3(sx * 14.6, 0.5, -62), Vector3(2.2, 1.0, 24), "wood")
		box(Vector3(sx * 15.2, 1.4, -62), Vector3(1.2, 0.8, 24), "wood")
	box(Vector3(0, 1.0, -74.2), Vector3(5.0, 2.0, 2.6), "brick")
	for i in 7:
		cyl(Vector3(-1.8 + i * 0.6, 2.2, -74.0 + (i % 2) * 0.5), 0.36, 0.5, Color(0.25, 0.22, 0.22), {"col": false, "seg": 7})
	lamp(Vector3(0, 2.8, -72.4), Color(1.0, 0.4, 0.15), 3.0, 10.0)
	for sx in [-1.0, 1.0]:
		cyl(Vector3(sx * 10.5, 0.45, -51.5), 1.5, 0.9, "wood_dark", {"seg": 12})
		cyl(Vector3(sx * 10.5, 0.92, -51.5), 1.3, 0.04, "water", {"col": false, "seg": 12})
	if not G.flag("bn_boss"):
		boss = Bannik.new()
		add_child(boss)
		boss.global_position = Vector3(0, 0.2, -69)
		boss.home = boss.global_position
		boss.arena = STEAM
		boss.set_yaw(PI)
		boss.model.play("Wave", 0.0)
		trigger(Vector3(0, 1.5, -51.0), Vector3(5, 2.5, 1.8), _boss_intro)


func _people() -> void:
	pra = npc("pradod", Vector3(-3.8, 0, 22), -90, {"talk": _talk_pra, "mark": "!" if not G.flag("bn_talk") else ""})
	npc("rybak", Vector3(17.5, 0.42, 23), -140, {"anim": "Sit", "solid": false, "look": false, "talk": func():
		await say([["rybak", "Тсс. Клюёт. Лёд тонкий — по вешкам ходи. Шаг в сторону — и купель. Бесплатная."],
			["rybak", "За островом, говорят, прорубь есть, а у проруби — клад. Но я туда не хожу. У меня клюёт."]])})
	npc("dod", Vector3(-10, 0.45, -38.3), 180, {"anim": "Sit", "solid": false, "look": false, "mark": "₽", "label": "Посидеть с Додом", "talk": func():
		await say([["dod", "О, Ч! Посидим? Квас холодный, пар горячий. Банник? Он там, за мыльней. Я к нему не хожу: он веником дерётся."]])
		Menus.shop(G.ui, "ПРЕДБАННИК", "Квас, вкусности, посидим", ["kvass", "doshik", "plums", "tasty", "energy"])
		await G.ui.panel_closed})
	trigger(Vector3(0, 1, 30), Vector3(3, 2, 2), func():
		if String(G.save["cp"]) == "start":
			G.checkpoint("yard"))


func begin(cp_name: String) -> void:
	if cp_name == "start" and not G.flag("bn_seen"):
		G.set_flag("bn_seen")
		title_card()
	_goal()


func _woods() -> int:
	return G.count("wood")


func _goal() -> void:
	if G.flag("bn_boss"):
		if G.player and G.player.global_position.z < 0.0:
			G.goal("Кнопка «Т» у тебя! Сани довезут до полустанка", Vector3(5.2, 0, -24.4))
		else:
			G.goal("Кнопка «Т» у тебя! Возвращайся на «поез» в Мурино", Vector3(3, 0.9, 76))
	elif G.flag("bn_fire"):
		G.goal("Баня затоплена. Выгони Банника из парилки", Vector3(0, 0, -30))
	elif G.flag("bn_talk"):
		if _woods() >= 3 and G.has("broom"):
			G.goal("Отнеси дрова и веник Пра Доду", Vector3(-3.8, 0, 22))
		elif _woods() < 3:
			var at := Vector3(-38, 0, 40)
			if G.flag("bn_w1"):
				at = Vector3(-45, 0, 4) if not G.flag("bn_w2") else Vector3(-29, 0, -21)
			G.goal("Дрова в лесу на западе (%d/3)%s" % [_woods(), "" if G.has("broom") else " и веник на острове"], at)
		else:
			G.goal("Дубовый веник — на острове посреди озера. Иди по вешкам!", ISLE)
	else:
		G.goal("Найди Пра Дода: его изба у бани", Vector3(-3.8, 0, 22))


func _talk_pra() -> void:
	if G.flag("bn_boss"):
		await say([["pradod", "Выгнал? Кхе. Ну, с лёгким паром. Теперь попарюсь. Впервые с восемьдесят девятого."]])
	elif G.flag("bn_fire"):
		await say([["pradod", "Топится. Иди, пока Банник разомлел. Как топнет — волна пойдёт: подпрыгни. А сядет отдышаться — тут и бей."]])
	elif G.flag("bn_talk") and _woods() >= 3 and G.has("broom"):
		await say([["pradod", "Три охапки. И веник — дубовый, правильный. Вот это по-нашему."],
			["pradod", "Сейчас затоплю… Кхе. Пошёл жар. Иди, пока Банник разомлел."],
			["pradod", "И запомни: он как топнет — по полу волна пойдёт, подпрыгни. А после сам сядет отдышаться — тут и бей."]])
		G.take("wood", 3)
		G.take("broom")
		G.set_flag("bn_fire")
		Snd.sfx("unlock", 0.0, 0.7)
		var sm := get_node_or_null("Smoke")
		if sm:
			(sm as CPUParticles3D).emitting = true
	elif G.flag("bn_talk"):
		await say([["pradod", "Дров пока %d из трёх. Веник %s. Дрова — в лесу на западе, веник — на острове. По вешкам иди, по вешкам." % [_woods(), "есть" if G.has("broom") else "не принёс"]]])
	else:
		await say([["pradod", "Кхе… Кто там? Ч? Знаю, знаю. Друн звонил. В восемьдесят девятом. Сказал — придёшь."],
			["ch", "Мне бы кнопку от ливта. С буквой «Т»."],
			["pradod", "Кнопка у Банника. Он в моей бане третью зиму сидит, не выгонишь. Холодную баню он не отдаст — его только жаром и выманишь."],
			["pradod", "Неси три охапки дров и дубовый веник. Дрова — в лесу на западе: на вырубке, у берлоги и под старой сосной."],
			["pradod", "Веник — на острове посреди озера. Лёд там тонкий: иди строго по вешкам."],
			["ch", "Дрова и веник. Что за бизнес… Посидим потом."]])
		G.set_flag("bn_talk")
		pra.set_mark("")
	_goal()


func _boss_intro() -> void:
	hall_gate = barrier(Vector3(0, 1.6, -48), Vector3(3.4, 3.2, 0.4), Color(1.0, 0.85, 0.8, 0.5))
	await cut(func():
		Snd.music("boss")
		G.cam.shot(Vector3(5, 2.4, -58), Vector3(0, 2.0, -69), 55.0)
		await G.wait(0.8)
		await say([["ch", "Ну и хамам… Жарко. Эй, Банник! Кнопку верни."],
			["bannik", "УХ-Х-Х. КТО ПАР ВЫПУСКАЕТ? ДВЕРЬ ЗАКРОЙ."],
			["ch", "Кнопку. С буквой «Т»."],
			["bannik", "ТЁПЛЕНЬКАЯ. МОЯ. А ТЕБЯ — ВЕНИКОМ. ПОДДАЙ-КА ПАРУ!"]])
		boss.play("Yes", 0.1, 1.0, true)
		Snd.sfx("roar", 0.0, 0.9)
		G.cam.shake(0.7)
		G.ui.big_title("БАННИК", "БОСС")
		await G.wait(1.2)
		G.cam.end_shot())
	boss.on_defeat = _boss_dead
	boss.start()
	G.goal("Победи Банника. Волну жара перепрыгивай; сел отдышаться — бей!")


func test_boss() -> void:
	G.player.place(Vector3(0, 0.1, -51.5), 0.0)


func _boss_dead() -> void:
	G.set_flag("bn_boss")
	Story.mark_done("banya")
	Snd.music(music)
	Snd.sfx("win", 0.0)
	G.pay(110)
	barrier_off(hall_gate)
	await cut(func():
		await say([["bannik", "Ух… хорошо пропарил… уважаю…"], ["ch", "Кнопка «Т». Ещё тёплая. Три есть. С лёгким паром меня."]])
		G.give("btn3"))
	G.checkpoint("bath", true)
	_goal()
