extends RefCounted
## Быстрая проверка ядра: меню, загрузка полигона, ходьба, бой, подбор, диалог, магазин.


func run(t) -> void:
	await t.start("menu")
	t.ok(G.mode == "menu" and G.ui.panel_kind == "main", "главное меню открыто: mode=%s panel=%s" % [G.mode, G.ui.panel_kind])
	await t.start("arena")
	t.say(t.state())
	t.ok(G.level.id == "arena" and G.mode == "play", "полигон загружен")
	t.ok(G.player.is_on_floor(), "игрок стоит на земле, y=%.2f" % G.player.global_position.y)
	t.ok(G.ents.size() == 5, "врагов: %d" % G.ents.size())
	var p0: Vector3 = G.player.global_position
	t.ok(await t.walk(Vector3(2, 0, -2), 6.0), "дошёл до денег")
	await t.sim(0.5)
	t.ok(G.money() >= 40, "деньги подобраны: %d" % G.money())
	await t.walk(Vector3(-2, 0, -2), 5.0)
	await t.walk(Vector3(-4, 0, -2), 5.0)
	await t.sim(0.4)
	t.ok(G.has("am") and G.has("kicks") and G.has("phone"), "умения подобраны: %s" % str(G.save["inv"]))
	# бой
	var won: bool = await t.fight(90.0)
	t.ok(won, "бой выигран, hp=%d, убито %d" % [int(G.player.hp), int(G.save["kills"])])
	await t.sim(2.5)
	t.say(t.state())
	# ящики
	await t.walk(Vector3(5, 0, -1.6), 8.0)
	G.player.face(Vector3(5, 0, -3))
	for i in 8:
		Inp.press("attack")
		await t.sim(0.1)
		Inp.release("attack")
		await t.sim(0.25)
	await t.sim(1.5)
	t.ok(G.has("doshik"), "ящик разбит, дошик подобран: %s" % str(G.save["inv"]))
	# разговор
	await t.walk(Vector3(3, 0, 3.3), 8.0)
	G.player.face(Vector3(3, 0, 2))
	await t.sim(0.3)
	t.ok(G.player.near != null and String(G.player.near["label"]) == "Поговорить", "рядом NPC: %s" % (str(G.player.near["label"]) if G.player.near != null else "нет"))
	# интерфейс на экране. Панели, привязанные к правому и нижнему краю, раньше уезжали за экран:
	# у HUD и сенсорного слоя был нулевой размер, и не было видно ни цели, ни подсказки, ни кнопок на телефоне
	var vr: Rect2 = G.ui.root.get_global_rect()
	var hud = G.ui.hud
	t.ok(vr.size.x > 600.0 and hud.size == vr.size and G.ui.touch_pad.size == vr.size, "HUD и сенсорный слой во весь экран: %s / %s / %s" % [str(vr.size), str(hud.size), str(G.ui.touch_pad.size)])
	t.ok(hud.prompt.visible and vr.encloses(hud.prompt.get_global_rect()), "подсказка действия видна на экране: %s" % str(hud.prompt.get_global_rect()))
	G.goal("Проверка панели цели")
	hud.boss_box.visible = true
	await t.sim(0.1)
	t.ok(hud.goal_box.visible and vr.encloses(hud.goal_box.get_global_rect()) and hud.goal_box.get_global_rect().end.x > vr.size.x - 40.0, "панель цели на экране, в правом верхнем углу: %s" % str(hud.goal_box.get_global_rect()))
	t.ok(vr.encloses(hud.boss_box.get_global_rect()) and hud.boss_box.size.x > 300.0, "полоса босса на экране: %s" % str(hud.boss_box.get_global_rect()))
	t.ok(vr.encloses(hud.hints.get_global_rect()) and hud.hints.text != "", "подсказки по управлению на экране: %s" % str(hud.hints.get_global_rect()))
	hud.boss_box.visible = false
	G.goal("")
	# сенсорные кнопки: все на экране, касание кнопки бьёт, стик ведёт героя
	var was_touch: bool = G.touch
	G.touch = true
	G.ui.apply_settings()
	await t.sim(0.1)
	var pad = G.ui.touch_pad
	var inner := vr.grow(-12.0)
	var off: Array = []
	for bt in TouchPad.BTN + TouchPad.TOP:
		var c: Vector2 = pad._btn_pos(bt)
		if not (inner.has_point(c - Vector2(bt[3], bt[3])) and inner.has_point(c + Vector2(bt[3], bt[3]))):
			off.append(bt[0])
	t.ok(pad.visible and off.is_empty(), "сенсорные кнопки целиком на экране" if off.is_empty() else "кнопки за экраном: " + str(off))
	# события отдаём слою напрямую: без окна (--headless) Input.parse_input_event до узлов не доходит
	var tap := InputEventScreenTouch.new()
	tap.index = 0
	tap.position = pad._btn_pos(TouchPad.BTN[0])
	tap.pressed = true
	pad._input(tap)
	await t.sim(0.12)
	var hit_ok: bool = G.player.state == "attack"
	var up := InputEventScreenTouch.new()
	up.index = 0
	up.position = tap.position
	pad._input(up)
	await t.sim(0.7)
	var from: Vector3 = G.player.global_position
	var st0 := InputEventScreenTouch.new()
	st0.index = 1
	st0.position = Vector2(150, vr.size.y - 150)
	st0.pressed = true
	pad._input(st0)
	var dr := InputEventScreenDrag.new()
	dr.index = 1
	dr.position = st0.position + Vector2(70, 0)
	dr.relative = Vector2(70, 0)
	pad._input(dr)
	await t.sim(0.6)
	var moved: float = from.distance_to(G.player.global_position)
	var st1 := InputEventScreenTouch.new()
	st1.index = 1
	st1.position = dr.position
	pad._input(st1)
	await t.sim(0.2)
	t.ok(hit_ok and moved > 0.8 and Inp.touch_move == Vector2.ZERO, "касание кнопки «УДАР» бьёт, стик ведёт героя (%.1f м)" % moved)
	G.touch = was_touch
	G.ui.apply_settings()
	await t.walk(Vector3(3, 0, 3.3), 8.0)
	G.player.face(Vector3(3, 0, 2))
	await t.sim(0.3)
	G.ui.auto_choice = [1]
	await t.use()
	await t.flush()
	t.ok(G.ui.said.has("Что за бизнес?"), "диалог прошёл (%d реплик)" % G.ui.said.size())
	t.say(t.state())
	# звук: каждая дорожка и каждый эффект, которые просит код, должны существовать и грузиться
	var miss: Array = []
	for m in ["menu", "dorm", "murino", "milk", "myt", "banya", "jmur", "fog", "fight", "boss", "boss2", "win"]:
		var st: AudioStream = Snd._stream(Snd.MUSIC_DIR, m)
		if st == null or st.get_length() < 10.0:
			miss.append("music/" + m)
	for x in ["item", "land", "jump", "step", "step_wood", "step_grass", "step_snow", "swing", "hit", "hit_big", "roll", "hurt", "deny", "throw", "spray", "slime", "am", "eat", "alert", "dash", "shoot", "die", "coin", "crate",
			"break", "door", "ui", "blip", "lose", "open", "boss_die", "roar", "crash", "phone", "unlock", "win", "lift", "cups"]:
		if not Snd.has_sfx(x):
			miss.append("sfx/" + x)
	t.ok(miss.is_empty(), "музыка и звуки на месте: 12 дорожек, 38 эффектов" if miss.is_empty() else "нет звуков: " + str(miss))
	# варианты звуков чередуются: на один и тот же звук подряд приходят разные записи
	var seen := {}
	for i in 40:
		seen[Snd._pick("hit").resource_path] = true
	t.ok(seen.size() >= 3, "у удара несколько вариантов (%d из 5)" % seen.size())
	# музыка зацикливается: Snd.music ставит зацикливание на дорожке, иначе после первого круга наступала тишина
	Snd.music("")
	Snd.music("menu", 0.0)
	await t.sim(0.2)
	var ms: AudioStream = Snd._mus[Snd._cur].stream
	var looped: bool = (ms is AudioStreamOggVorbis and (ms as AudioStreamOggVorbis).loop) or (ms is AudioStreamMP3 and (ms as AudioStreamMP3).loop)
	t.ok(looped and ms.get_length() > 60.0, "музыка меню зациклена, длина %.0f с" % ms.get_length())
	# озвучка: ключ реплики считается так же, как в tools/voice/extract_lines.py; без записи реплика просто молчит
	t.ok(Snd.voice_key("drun", "Ч! Ты чё, спишь?! ФОГ ИДЁТ! Туман уже у вашей общаги!") == "c9c88f705865" and Snd.voice_key({"n": "Сосед"}, "x") == "Сосед|x".md5_text().substr(0, 12),
		"ключ озвучки совпадает со сборщиком реплик: " + Snd.voice_key("drun", "Ч! Ты чё, спишь?! ФОГ ИДЁТ! Туман уже у вашей общаги!"))
	t.ok(Snd.voice("drun", "Реплика, которой нет в игре") == 0.0 and not Snd.voice_playing() and Snd.voice_count() >= 0, "реплика без записи идёт без голоса; записей в сборке: %d" % Snd.voice_count())
	# «Удар с вертухи»: четвёртый удар серии появляется только с купленным предметом
	var seen_heavy := [false, false]
	for round in 2:
		if round == 1:
			G.give("heavy")
		await t.sim(1.0)
		for i in 9:
			Inp.press("attack")
			await t.sim(0.06)
			Inp.release("attack")
			for k in 4:
				await t.sim(0.05)
				if G.player.state == "attack" and G.player.cur_hit == G.player.HEAVY:
					seen_heavy[round] = true
	t.ok(not seen_heavy[0] and seen_heavy[1], "вертуха: без предмета её нет, с предметом идёт четвёртым ударом (%s)" % str(seen_heavy))
	t.ok(G.player.model.ap.has_animation("Kick_Left"), "у героя есть анимация вертухи")
	# модель Меллстроя: 32-костный скелет, перенесённые анимации, бросок котлеты, дихлофос на бегу, цепь и телефон
	await t.sim(0.8)
	var pm := G.player.model
	var miss_clips: Array = []
	for cname in ["Idle", "Walk", "Run", "Jump", "Jump2", "Fall", "Roll", "Punch_Right", "Punch_Left", "Kick_Right", "Kick_Left", "Throw", "Run_Shoot", "Idle_Gun_Pointing", "Shout", "Phone", "Squat", "Sit", "Steam", "Death", "HitRecieve"]:
		if not pm.ap.has_animation(cname):
			miss_clips.append(cname)
	t.ok(pm.skel != null and pm.skel.get_bone_count() == 32 and miss_clips.is_empty(),
		"модель Меллстроя: 32 кости, все анимации на месте" if miss_clips.is_empty() else "нет клипов: " + str(miss_clips))
	G.give("chain", 1, true)
	G.give("spray", 1, true)
	G.pay(10)
	await t.sim(0.05)
	var has_chain_prop: bool = G.player.chain_node != null and G.player.chain_node.visible
	G.player.anim_lock = "Phone"
	await t.sim(0.05)
	var has_phone_prop: bool = G.player.phone_node != null and G.player.phone_node.visible
	G.player.anim_lock = ""
	await t.sim(0.05)
	var hide_phone_prop: bool = G.player.phone_node != null and not G.player.phone_node.visible
	Inp.press("throw")
	await t.sim(0.08)
	Inp.release("throw")
	var throw_ok: bool = G.player.state == "throw" and G.player.model.cur == "Throw"
	await t.sim(0.45)
	Inp.press("gadget")
	Inp.press("move_up")
	await t.sim(0.2)
	var spray_can_ok: bool = G.player.can_node != null and G.player.can_node.visible
	var spray_anim_ok: bool = G.player.model.cur == "Run_Shoot"
	Inp.release("move_up")
	Inp.release("gadget")
	await t.sim(0.1)
	t.ok(has_chain_prop and has_phone_prop and hide_phone_prop and throw_ok and spray_can_ok and spray_anim_ok,
		"аксессуары и новые анимации: цепь=%s телефон=%s/%s бросок=%s баллон=%s/%s" % [str(has_chain_prop), str(has_phone_prop), str(hide_phone_prop), str(throw_ok), str(spray_can_ok), str(spray_anim_ok)])
