extends RefCounted
## Обучение в начале игры: каждый шаг засчитывается своим действием, дверь комнаты до конца заперта,
## обучение можно пропустить.


func _step(t, L, want: int, what: String) -> void:
	await t.until(func(): return L.tutor_i >= want or not L.tutor_on, 3.0)
	t.ok(L.tutor_i == want or (want == 8 and not L.tutor_on), "шаг %d: %s (сейчас шаг %d)" % [want, what, L.tutor_i + 1])


func run(t) -> void:
	G.opts["tutor"] = "1"
	await t.start("dorm")
	var L = G.level
	var p: Player = G.player
	var hud = G.ui.hud
	await t.sim(0.2)
	t.ok(L.tutor_on and L.tutor_i == 0 and hud.tutor_box.visible, "после звонка началось обучение: %s" % hud.tutor_title.text)
	t.ok(G.ui.root.get_global_rect().encloses(hud.tutor_box.get_global_rect()) and hud.tutor_box.size.y < 200.0, "панель обучения на экране: %s" % str(hud.tutor_box.get_global_rect()))
	L.room_door.use()
	await t.sim(0.2)
	t.ok(not L.room_door.is_open, "дверь комнаты заперта, пока идёт обучение")
	# 1. камера
	for i in 12:
		Inp.look = Vector2(40, 0)
		await t.sim(1.0 / 60.0)
	await _step(t, L, 1, "осмотрелся")
	# 2. ходьба
	await t.walk(Vector3(-19.0, 0, -3.2), 6.0, 0.4)
	await t.walk(Vector3(-22.5, 0, -3.6), 6.0, 0.4)
	await _step(t, L, 2, "прошёлся")
	# 3. бег
	Inp.press("sprint")
	await t.walk(Vector3(-18.6, 0, -3.4), 5.0, 0.4)
	await t.walk(Vector3(-23.2, 0, -3.8), 5.0, 0.4)
	await t.walk(Vector3(-19.0, 0, -3.4), 5.0, 0.4)
	Inp.release("sprint")
	await _step(t, L, 3, "пробежался")
	# 4. прыжок
	Inp.press("jump")
	await t.sim(0.1)
	Inp.release("jump")
	await _step(t, L, 4, "прыгнул")
	await t.until(func(): return p.is_on_floor(), 2.0)
	# 5. перекат
	Inp.press("dodge")
	await t.sim(0.1)
	Inp.release("dodge")
	await _step(t, L, 5, "перекатился")
	await t.sim(0.8)
	# 6. ящик
	t.ok(is_instance_valid(L.tut_crate), "появился ящик для ударов")
	var cpos: Vector3 = L.tut_crate.global_position
	await t.walk(cpos + Vector3(-1.25, 0, 0.3), 6.0, 0.35)
	p.face(cpos)
	for i in 6:
		if not is_instance_valid(L.tut_crate) or L.tut_crate.dead:
			break
		Inp.press("attack")
		await t.sim(0.08)
		Inp.release("attack")
		await t.sim(0.2)
	await _step(t, L, 6, "ящик разбит серией")
	# 7. деньги и бросок
	await t.sim(0.8)
	await t.walk(cpos, 4.0, 0.3)
	await t.sim(0.6)
	t.ok(G.money() >= 2, "деньги из ящика подобраны: %d ₽" % G.money())
	Inp.press("throw")
	await t.sim(0.1)
	Inp.release("throw")
	await _step(t, L, 7, "швырнул котлету")
	await t.sim(0.8)
	# 8. дверь
	await t.walk(Vector3(-21, 0, -2.9), 6.0, 0.4)
	p.face(Vector3(-21, 0, -1.6))
	await t.sim(0.3)
	t.ok(p.near != null and String(p.near["label"]) == "Открыть дверь" and hud.prompt.visible, "у двери видна подсказка действия")
	t.ok(hud.marks.items.size() >= 1, "над дверью нарисован значок действия (%d)" % hud.marks.items.size())
	await t.use()
	await t.sim(1.2)
	t.ok(L.room_door.is_open and not L.tutor_on and G.flag("d_tutor") and not hud.tutor_box.visible, "дверь открыта, обучение пройдено, панель убрана")
	# пропуск обучения
	G.save = G.new_save()
	await t.start("dorm")
	L = G.level
	await t.sim(0.2)
	t.ok(L.tutor_on, "новая игра: обучение снова идёт")
	L.tutor_skip()
	await t.sim(0.2)
	L.room_door.use()
	await t.sim(0.6)
	t.ok(not L.tutor_on and not G.ui.hud.tutor_box.visible and L.room_door.is_open, "обучение пропущено: панели нет, дверь открывается")
	G.opts.erase("tutor")
