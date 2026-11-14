extends RefCounted
## Общага: от звонка до выхода в Мурино (без пеших переходов — проверяется сценарий).


func run(t) -> void:
	await t.start("dorm")
	var L = G.level
	t.ok(G.flag("d_call") and G.has("phone"), "вступление прошло, телефон выдан")
	t.ok(String(G.ui.hud.goal_lbl.text).begins_with("Выйди"), "первая цель: " + G.ui.hud.goal_lbl.text)
	t.say(t.state())
	t.ok(G.player.is_on_floor(), "стою в комнате: y=%.2f" % G.player.global_position.y)
	# цифры кода: ни окно, ни мебель не должны закрывать их (раньше рама окна стояла прямо на цифре)
	var covered: Array = []
	for dp in L.digit_pos:
		var zone := AABB(dp - Vector3(0.8, 1.25, 0.7), Vector3(1.6, 2.2, 1.4))
		for n in L.get_children():
			if n is Node3D and n.has_meta("prop"):
				var box: AABB = (n as Node3D).global_transform * Level.prop_aabb(String(n.get_meta("prop")))
				if box.intersects(zone):
					covered.append("%s у цифры %s" % [n.get_meta("prop"), str(dp)])
	t.ok(L.digit_pos.size() == 3 and covered.is_empty(), "три цифры кода ничем не закрыты" if covered.is_empty() else "цифры закрыты: " + str(covered))
	# крысы: сквозь стену героя не видят; увидев — догоняют через дверь, а не бьются в стену
	t.tp(-9, 0.1, 0, -PI * 0.5)
	await t.sim(3.0)
	var woke := 0
	for e in G.ents:
		if not e.boss and e.aggro:
			woke += 1
	t.ok(woke == 0, "из коридора между дверями крысы в комнатах героя не видят (проснулось %d)" % woke)
	t.tp(-5, 0.1, -2.7, 0)
	await t.sim(0.7)
	woke = 0
	for e in G.ents:
		if not e.boss and e.aggro:
			woke += 1
	t.ok(woke >= 2, "в дверях комнаты 3 крысы замечают героя (проснулось %d)" % woke)
	G.opts["god"] = "1"
	await t.walk(Vector3(-5, 0.1, 0), 4.0, 0.5)
	await t.walk(Vector3(-11, 0.1, 0.4), 6.0, 0.5)
	var came := false
	var outside := 0
	for i in 480:
		await t.sim(1.0 / 60.0)
		for e in G.ents:
			if e.boss or e.dead:
				continue
			var ep: Vector3 = e.global_position
			if absf(ep.z) < 1.5 and ep.x < -6.5 and e.flat_dist(G.player.global_position) < 3.5:
				came = true
			if ep.y > -1.0 and (ep.x < -28.0 or ep.x > 26.0 or absf(ep.z) > 7.6):
				outside += 1
		if came:
			break
	G.opts.erase("god")
	t.ok(came and outside == 0, "крыса вышла за героем в коридор через дверь; за стенами никого" if came and outside == 0 else "крыса не дошла (%s), за стенами %d" % [str(came), outside])
	for e in G.ents.duplicate():
		if is_instance_valid(e) and not e.boss and not e.dead and e.global_position.y > -1.0:
			e.hurt(999999.0, G.player.global_position, 0.0, "melee")
	G.player.revive()
	await t.sim(0.3)
	# вахтёрша -> Брал -> записка
	await L.vaht.talk()
	t.ok(G.flag("d_vaht"), "вахтёрша не выпускает")
	await L.bral.talk()
	t.ok(G.count("doshik") == 2 and G.flag("d_bral"), "Брал дал дошики")
	t.tp(11, 0.1, 3.0)
	await t.sim(0.8)
	await t.flush()
	t.ok(G.has("note_dorm"), "записка подобрана; цель: " + G.ui.hud.goal_lbl.text)
	# замок
	t.tp(18.2, 0.1, 0.4, PI)
	await t.sim(0.3)
	t.ok(G.player.near != null and String(G.player.near["label"]) == "Кодовый замок", "рядом замок")
	G.ui.auto_choice = ["000"]
	await L._keypad()
	t.ok(not L.base_door.is_open, "неверный код не открывает")
	G.ui.auto_choice = [L.code]
	await L._keypad()
	t.ok(L.base_door.is_open and G.flag("d_open"), "код %s открыл подвал" % L.code)
	# пешком вниз по лестнице
	t.tp(19, 0.1, 0.6, PI)
	var down: bool = await t.walk(Vector3(19, -4, 11.4), 12.0)
	t.ok(down and G.player.global_position.y < -3.5, "спустился по лестнице: y=%.2f" % G.player.global_position.y)
	# босс
	t.kill_all()
	t.tp(-4.5, -3.9, 10, PI * 0.5)
	await t.sim(0.5)
	await t.flush()
	t.ok(L.boss.active and not L.gate.disabled, "бой с Королём начался")
	var hp0: float = L.boss.hp
	var won: bool = await t.fight(150.0)
	t.say("бой: %s, hp босса %d -> %d, игрок hp %d" % ["победа" if won else "нет", int(hp0), int(L.boss.hp) if is_instance_valid(L.boss) else 0, int(G.player.hp)])
	if not won:
		G.player.revive()
		t.kill_all()
	await t.sim(3.0)
	await t.flush()
	t.ok(G.flag("d_boss") and G.has("key_dorm") and G.has("chain"), "Король побеждён, ключ и цепь получены")
	# выход
	t.tp(-26.6, 0.1, 0, PI * 0.5)
	await t.sim(0.3)
	t.ok(G.player.near != null and String(G.player.near["label"]) == "Выйти на улицу", "рядом выход")
	await t.use()
	await t.until(func(): return G.level != null and G.level.id != "dorm" and not G.loading, 20.0)
	t.ok(G.level.id == "murino", "переехали в Мурино: " + G.level.id)
	t.say(t.state())
