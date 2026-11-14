extends RefCounted
## Мурино: Друн -> курьер -> гаражи -> пропуск -> ливт -> Тёмный Друн -> станция.


func run(t) -> void:
	await t.start("murino")
	var L = G.level
	t.say(t.state())
	t.ok(G.player.is_on_floor(), "стою во дворе")
	await L.drun.talk()
	await t.flush()
	t.ok(G.has("am") and G.flag("m_drun"), "Друн научил кричать")
	await L.courier.talk()
	t.ok(G.flag("m_courier"), "курьер просит посылку; цель: " + G.ui.hud.goal_lbl.text)
	# пешком в ГСК через вход у вывески
	t.tp(0, 0.1, -24, PI)
	t.kill_all()
	var in_gsk: bool = await t.walk(Vector3(0, 0, -44), 10.0)
	t.ok(in_gsk, "вошёл в ГСК через ворота")
	var to_parcel: bool = await t.walk(Vector3(28.9, 0, -44), 12.0)
	to_parcel = await t.walk(Vector3(28.9, 0, -56.5), 8.0) and to_parcel
	to_parcel = await t.walk(Vector3(26.2, 0, -56.6), 6.0) and to_parcel
	to_parcel = await t.walk(Vector3(26.2, 0, -60.2), 6.0) and to_parcel
	t.ok(to_parcel, "дошёл до гаража с посылкой: " + str(G.player.global_position))
	G.player.face(Vector3(26, 0, -62.2))
	for i in 6:
		Inp.press("attack")
		await t.sim(0.1)
		Inp.release("attack")
		await t.sim(0.3)
	await t.sim(1.5)
	t.ok(G.has("parcel"), "посылка у меня")
	# пакостники
	t.tp(-3.5, 0.1, -45.2, PI)
	await t.sim(0.4)
	await t.flush()
	var won: bool = await t.fight(60.0)
	await t.sim(1.0)
	t.ok(G.flag("m_gop"), "пакостники побеждены (бой: %s, hp %d)" % [won, int(G.player.hp)])
	G.player.revive()
	await L.courier.talk()
	t.ok(G.has("pass_p46") and not G.has("parcel"), "пропуск получен")
	# пезд и ливт
	t.tp(0, 0.1, 61.6, 0)
	await t.sim(0.3)
	t.ok(G.player.near != null and String(G.player.near["label"]) == "Открыть «пезд»", "у двери пезда")
	await t.use()
	var inside: bool = await t.walk(Vector3(0.6, 0, 72.6), 8.0)
	t.ok(inside, "вошёл в вестибюль")
	await L._lift()
	await t.flush()
	t.ok(G.player.global_position.y > 80.0, "ливт привёз на крышу: y=%.1f" % G.player.global_position.y)
	await t.walk(Vector3(0, 90, 70.5), 6.0)
	await t.sim(0.5)
	await t.flush()
	t.ok(L.boss.active, "бой с Тёмным Друном начался")
	won = await t.fight(150.0)
	t.say("бой: %s, игрок hp %d" % ["победа" if won else "нет", int(G.player.hp)])
	if not won:
		G.player.revive()
		t.kill_all()
	await t.sim(3.0)
	await t.flush()
	t.ok(G.flag("m_boss") and G.has("kicks"), "Тёмный Друн побеждён, кроссы получены")
	t.ok(G.player.global_position.y > 80.0, "на крыше не упал")
	# вниз и на станцию
	t.tp(0, 90.1, 66.4, PI)
	await t.sim(0.3)
	await t.use()
	await t.flush()
	t.ok(G.player.global_position.y < 2.0, "ливт вниз: y=%.1f" % G.player.global_position.y)
	t.tp(52, 0.1, -24, -PI * 0.5)
	var up: bool = await t.walk(Vector3(59, 0.9, -23), 8.0)
	t.ok(up and G.player.global_position.y > 0.7, "поднялся на платформу: y=%.2f" % G.player.global_position.y)
	t.say(t.state())
