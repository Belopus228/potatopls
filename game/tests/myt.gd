extends RefCounted
## Мытищи: вахтёр -> три куска мыла (прачечная, крыша склада, фонтан) -> помывочная -> проспект -> Мойдодыр.


func run(t) -> void:
	G.save = G.new_save()
	G.save["inv"] = {"phone": 1, "spray": 1, "am": 1, "kicks": 1, "chain": 2, "doshik": 2, "shawa": 2, "tasty": 1}
	G.save["money"] = 30
	await t.start("myt", "start", false)
	var L = G.level
	t.say(t.state())
	t.kill_all()
	var down: bool = await t.walk(Vector3(0, 0, 62), 10.0)
	down = await t.walk(Vector3(-8, 0, 40), 12.0) and down
	down = await t.walk(Vector3(0, 0, 14), 14.0) and down
	t.ok(down, "от платформы до санпропускника: " + str(G.player.global_position))
	var blocked: bool = not await t.walk(Vector3(0, 0, 6), 3.0)
	t.ok(blocked, "без пропуска не пускают")
	await L.guard_npc.talk()
	t.ok(G.flag("my_talk"), "вахтёр рассказал про мыло")
	# прачечная
	t.tp(-18, 0.1, 53, PI * 0.5)
	var inl: bool = await t.walk(Vector3(-30, 0, 53), 10.0)
	await t.sim(0.5)
	t.ok(inl and G.ents.size() >= 4, "в прачечной началась драка: врагов %d" % G.ents.size())
	var won: bool = await t.fight(70.0)
	await t.sim(0.5)
	won = await t.fight(70.0) and won
	await t.sim(0.5)
	if not G.flag("my_l"):
		G.player.revive()
		t.kill_all()
		await t.sim(0.5)
		t.kill_all()
		await t.sim(0.5)
	G.player.revive()
	await t.walk(Vector3(-43.5, 0, 55.0), 10.0)
	await t.walk(Vector3(-43.5, 0, 53.0), 5.0, 0.4)
	await t.sim(0.5)
	t.ok(G.flag("my_s1") and G.count("soap") == 1, "мыло из прачечной (бот: %s)" % won)
	# склад: по ящикам на крышу
	t.kill_all()
	t.tp(22.9, 0.1, 63.6, 0)
	var up := true
	for i in 7:
		G.player.face(Vector3(22.9, 0, 61.0 - i * 2.0))
		Inp.touch_move = Vector2(0, -1)
		Inp.press("jump")
		await t.sim(0.12)
		Inp.release("jump")
		await t.sim(0.55)
		Inp.touch_move = Vector2.ZERO
		await t.sim(0.15)
	Inp.touch_move = Vector2.ZERO
	t.say("после ящиков: " + str(G.player.global_position))
	up = G.player.global_position.y > 6.0
	t.ok(up, "забрался по ящикам: y=%.1f" % G.player.global_position.y)
	if not up:
		t.tp(26, 7.2, 49, 0)
	t.kill_all()
	await t.walk(Vector3(40.5, 7, 52), 12.0, 0.5)
	await t.sim(0.5)
	t.ok(G.flag("my_s2") and G.count("soap") == 2, "мыло с крыши склада")
	# фонтан
	t.tp(6.6, 0.1, 50.4, PI)
	await t.sim(0.3)
	await t.use()
	await t.flush()
	t.ok(G.flag("my_fountain"), "фонтан перекрыт")
	await t.sim(1.0)
	await t.walk(Vector3(3.2, 0, 46.6), 8.0, 0.4)
	await t.sim(0.5)
	t.ok(G.count("soap") == 3, "мыло из фонтана: %d" % G.count("soap"))
	# помывочная: пройти сквозь души пешком (перекатом)
	t.tp(-14, 0.1, 21.5, PI * 0.5)
	var hp0: float = G.player.hp
	var thru: bool = await t.walk(Vector3(-43, 0, 21.5), 30.0)
	thru = await t.walk(Vector3(-43, 0, 28.5), 8.0) and thru
	thru = await t.walk(Vector3(-20.5, 0, 28.8), 30.0) and thru
	t.ok(thru, "прошёл душевые: hp %d -> %d, pos %s" % [int(hp0), int(G.player.hp), str(G.player.global_position)])
	G.player.revive()
	if not thru:
		t.tp(-20.5, 0.1, 28.8, 0)
	await L.bath.talk()
	t.ok(G.has("pass_clean") and G.count("soap") == 0, "пропуск «Чистые руки» получен")
	var outb: bool = await t.walk(Vector3(-12, 0, 28.5), 8.0)
	t.ok(outb, "вышел через выход помывочной")
	await L.guard_npc.talk()
	t.ok(G.flag("my_gate"), "вахтёр пропустил")
	t.tp(0, 0.1, 13, 0)
	var pr: bool = await t.walk(Vector3(0, 0, -18), 16.0)
	t.ok(pr, "прошёл санпропускник на проспект")
	t.kill_all()
	await t.walk(Vector3(0, 0, -23), 5.0)
	await t.sim(0.6)
	t.ok(not L.patrol_gate.is_empty() and G.ents.size() >= 4, "патруль чистоты: врагов %d" % G.ents.size())
	won = await t.fight(80.0)
	await t.sim(0.5)
	if not G.flag("my_patrol"):
		G.player.revive()
		t.kill_all()
		await t.sim(0.5)
	G.player.revive()
	t.ok(G.flag("my_patrol"), "патруль разбит (бот: %s)" % won)
	var topal: bool = await t.walk(Vector3(0, 0, -48), 12.0)
	topal = await t.walk(Vector3(0, 0, -55), 6.0) and topal
	await t.sim(0.5)
	await t.flush()
	t.ok(topal and L.boss.active, "бой с Мойдодыром начался")
	won = await t.fight(220.0)
	t.say("бой с Мойдодыром: %s, игрок hp %d" % ["победа" if won else "нет", int(G.player.hp)])
	if not won:
		G.player.revive()
		t.kill_all()
	await t.sim(3.0)
	await t.flush()
	t.ok(G.flag("my_boss") and G.has("btn2"), "Мойдодыр побеждён, кнопка «Э» получена")
	var outp: bool = await t.walk(Vector3(0, 0, -47), 20.0)
	t.tp(8.8, 0.1, -45, -PI * 0.5)
	await t.sim(0.3)
	await t.use()
	await t.flush()
	t.ok(outp and G.player.global_position.z > 50.0, "маршрутка довезла до вокзала: " + str(G.player.global_position))
	t.say(t.state())
