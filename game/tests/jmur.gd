extends RefCounted
## Жмурино: сторож -> три склепа (засада, код 1989, ключ из Жирного Жмура) -> лампады -> Консьерж -> казино.


func run(t) -> void:
	G.save = G.new_save()
	G.save["inv"] = {"phone": 1, "spray": 1, "am": 1, "kicks": 1, "chain": 3, "doshik": 2, "shawa": 1, "tasty": 2, "kvass": 1}
	G.save["money"] = 80
	await t.start("jmur", "start", false)
	var L = G.level
	t.say(t.state())
	t.kill_all()
	var down: bool = await t.walk(Vector3(0, 0, 62), 10.0)
	down = await t.walk(Vector3(0, 0, 44), 12.0) and down
	t.ok(down, "от платформы до ворот кладбища")
	await L.keeper.talk()
	t.ok(G.flag("jm_talk"), "сторож рассказал про свечи")
	# казино: фишка за ларьком и игра
	t.tp(-15.6, 0.1, 57.5, 0)
	await t.walk(Vector3(-15.6, 0, 55.2), 5.0, 0.4)
	await t.sim(0.4)
	t.ok(G.count("chip") == 1, "фишка за ларьком")
	t.tp(4, 0.1, 52, -PI * 0.5)
	var toc: bool = await t.walk(Vector3(28, 0, 52), 14.0)
	toc = await t.walk(Vector3(41, 0, 52), 10.0) and toc
	t.ok(toc, "вошёл в казино: " + str(G.player.global_position))
	G.ui.auto_choice = [0]
	await L._talk_croupier()
	await t.flush()
	t.ok(G.flag("jm_casino") and G.has("btn5") and G.count("chip") == 0, "выиграл кнопку «Ж» в напёрстки")
	# через ворота на кладбище, склеп Купца
	t.tp(0, 0.1, 44, 0)
	var inc: bool = await t.walk(Vector3(0, 0, 30), 10.0)
	t.kill_all()
	inc = await t.walk(Vector3(0, 0, 20), 8.0) and inc
	inc = await t.walk(L.C1 + Vector3(8, 0, 0), 20.0) and inc
	t.kill_all()
	inc = await t.walk(L.C1 + Vector3(1, 0, 0), 10.0) and inc
	await t.sim(0.6)
	t.ok(inc and G.ents.size() >= 3, "вошёл в склеп Купца — засада: врагов %d" % G.ents.size())
	var won: bool = await t.fight(70.0)
	await t.sim(0.6)
	won = await t.fight(70.0) and won
	await t.sim(0.6)
	if not G.flag("jm_k1"):
		G.player.revive()
		t.kill_all()
		await t.sim(0.5)
		t.kill_all()
		await t.sim(0.5)
	G.player.revive()
	await t.walk(L.C1 + Vector3(5.5, 0, 0), 12.0)
	await t.walk(L.C1 + Vector3(0.4, 0, 0), 8.0, 0.4)
	await t.sim(0.5)
	t.ok(G.flag("jm_c1") and G.count("candle") == 1, "свеча Купца (бот: %s)" % won)
	# склеп Поэта: неверный код, потом верный
	t.kill_all()
	t.tp(L.C2.x - 5.6, 0.1, L.C2.z, -PI * 0.5)
	await t.sim(0.3)
	G.ui.auto_choice = ["1234"]
	await t.use()
	await t.flush()
	t.ok(not G.flag("jm_poet"), "неверный код не открывает")
	var blocked: bool = not await t.walk(L.C2 + Vector3(-0.4, 0, 0), 2.5, 0.5)
	t.ok(blocked, "плита склепа Поэта на месте")
	t.tp(L.C2.x - 5.6, 0.1, L.C2.z, -PI * 0.5)
	await t.sim(0.3)
	G.ui.auto_choice = ["1989"]
	await t.use()
	await t.flush()
	t.ok(G.flag("jm_poet"), "код 1989 открыл склеп Поэта")
	await t.walk(L.C2 + Vector3(-0.4, 0, 0), 8.0, 0.4)
	await t.sim(0.5)
	t.ok(G.flag("jm_c2") and G.count("candle") == 2, "свеча Поэта")
	# Жирный Жмур и склеп Управдома
	t.tp(L.C3.x + 5.6, 0.1, L.C3.z, PI * 0.5)
	await t.sim(0.3)
	await t.use()
	await t.sim(0.6)
	blocked = not await t.walk(L.C3 + Vector3(1, 0, 0), 2.5, 0.5)
	t.ok(blocked, "склеп Управдома заперт без ключа")
	t.tp(L.FAT.x - 6, 0.1, L.FAT.z, -PI * 0.5)
	await t.sim(0.5)
	won = await t.fight(60.0)
	if not G.flag("jm_key") and G.ents.size() > 0:
		t.kill_all()
	await t.sim(1.5)
	await t.walk(L.FAT, 8.0, 0.5)
	for i in 6:
		if G.has("key_crypt"):
			break
		for pk in G.level.get_children():
			if pk is Pickup and pk.item == "key_crypt":
				await t.walk(pk.global_position, 6.0, 0.4)
		await t.sim(0.3)
	t.ok(G.has("key_crypt"), "ключ от склепа выпал из Жирного Жмура (бот: %s)" % won)
	G.player.revive()
	t.tp(L.C3.x + 5.6, 0.1, L.C3.z, PI * 0.5)
	await t.sim(0.3)
	await t.use()
	await t.sim(0.8)
	t.kill_all()
	await t.walk(L.C3 + Vector3(0.4, 0, 0), 8.0, 0.4)
	await t.sim(0.5)
	t.ok(G.flag("jm_c3") and G.count("candle") == 3, "свеча Управдома: всего %d" % G.count("candle"))
	# лампады и парадная
	t.kill_all()
	t.tp(0, 0.1, -16, 0)
	var toy: bool = await t.walk(Vector3(0, 0, -26), 8.0)
	t.kill_all()
	toy = await t.walk(Vector3(0, 0, -33.4), 8.0) and toy
	await t.sim(0.3)
	t.ok(toy and G.player.near != null and String(G.player.near["label"]) == "Зажечь лампады", "у лампад: " + str(G.player.global_position))
	await t.use()
	await t.flush()
	t.ok(G.flag("jm_door") and G.count("candle") == 0, "лампады горят, дверь открыта")
	var inl: bool = await t.walk(Vector3(0, 0, -41), 10.0)
	await t.sim(0.5)
	await t.flush()
	t.ok(inl and L.boss.active, "бой с Консьержем начался")
	won = await t.fight(220.0)
	t.say("бой с Консьержем: %s, игрок hp %d" % ["победа" if won else "нет", int(G.player.hp)])
	if not won:
		G.player.revive()
		t.kill_all()
	await t.sim(3.0)
	await t.flush()
	t.ok(G.flag("jm_boss") and G.has("btn4"), "Консьерж побеждён, кнопка «А» получена")
	G.player.revive()
	t.kill_all()
	var outl: bool = await t.walk(Vector3(0, 0, -38), 20.0)
	outl = await t.walk(Vector3(0, 0, -30), 8.0) and outl
	t.ok(outl, "вышел из парадной")
	t.tp(14.4, 0.1, -33, -PI * 0.5)
	await t.sim(0.3)
	await t.use()
	await t.flush()
	t.ok(G.player.global_position.z > 50.0, "ритуал-такси довезло до станции")
	t.say(t.state())
