extends RefCounted
## Банька: Пра Дод -> три охапки дров -> веник на острове (тонкий лёд) -> баня -> Банник -> сани.


func run(t) -> void:
	G.save = G.new_save()
	G.save["inv"] = {"phone": 1, "spray": 1, "am": 1, "kicks": 1, "chain": 2, "doshik": 2, "shawa": 1, "tasty": 2, "kvass": 1}
	G.save["money"] = 30
	await t.start("banya", "start", false)
	var L = G.level
	t.say(t.state())
	t.kill_all()
	var down: bool = await t.walk(Vector3(0, 0, 62), 10.0)
	down = await t.walk(Vector3(0, 0, 24), 16.0) and down
	t.ok(down, "дошёл до двора Пра Дода")
	t.tp(0, 0.1, -28.4, 0)
	await t.sim(0.3)
	t.ok(G.player.near != null and String(G.player.near["label"]) == "Войти в баню", "у двери бани")
	await t.use()
	await t.sim(0.6)
	var blocked: bool = not await t.walk(Vector3(0, 0, -33), 2.5)
	t.ok(blocked, "нетопленая баня заперта")
	await L.pra.talk()
	t.ok(G.flag("bn_talk"), "Пра Дод дал задание")
	# дрова: пешком по тропам
	t.tp(-2, 0.1, 10, PI * 0.5)
	var w: bool = await t.walk(Vector3(-22, 0, 14), 14.0)
	t.kill_all()
	w = await t.walk(Vector3(-38, 0, 40), 20.0, 0.6) and w
	await t.sim(0.4)
	t.ok(w and G.flag("bn_w1"), "дрова с вырубки: " + str(G.player.global_position))
	t.kill_all()
	w = await t.walk(Vector3(-22, 0, 14), 20.0)
	w = await t.walk(Vector3(-45, 0, 4), 18.0, 0.6) and w
	await t.sim(0.4)
	t.ok(w and G.flag("bn_w2"), "дрова от берлоги")
	t.kill_all()
	w = await t.walk(Vector3(-22, 0, 14), 18.0)
	w = await t.walk(Vector3(-29, 0, -21), 24.0, 0.6) and w
	await t.sim(0.4)
	t.ok(w and G.count("wood") == 3, "дрова из-под старой сосны: всего %d" % G.count("wood"))
	# тонкий лёд: шаг в сторону — купель
	t.kill_all()
	t.tp(13, 0.1, 12, -PI * 0.5)
	await t.sim(0.3)
	var hp0: float = G.player.hp
	await t.walk(Vector3(22, 0, 2), 6.0)
	await t.sim(1.2)
	t.ok(G.player.hp < hp0, "сошёл с вешек — провалился: hp %d -> %d, вернуло в %s" % [int(hp0), int(G.player.hp), str(G.player.global_position)])
	G.player.revive()
	t.tp(13, 0.1, 12, -PI * 0.5)
	hp0 = G.player.hp
	var ice := true
	for pt in L.ICE_PATH:
		ice = await t.walk(pt, 8.0, 0.6) and ice
	t.kill_all()
	ice = await t.walk(L.ISLE + Vector3(0.6, 0, 0.8), 8.0, 0.5) and ice
	await t.sim(0.4)
	t.ok(ice and G.has("broom") and G.player.hp >= hp0, "по вешкам дошёл до острова и взял веник (hp %d)" % int(G.player.hp))
	for i in range(L.ICE_PATH.size() - 1, -1, -1):
		await t.walk(L.ICE_PATH[i], 8.0, 0.6)
	t.ok(G.player.global_position.x < 15.0 and G.player.hp >= hp0, "вернулся на берег сухим")
	await L.pra.talk()
	t.ok(G.flag("bn_fire") and G.count("wood") == 0 and not G.has("broom"), "баня затоплена")
	t.tp(0, 0.1, -28.4, 0)
	await t.sim(0.3)
	await t.use()
	await t.sim(0.8)
	var inb: bool = await t.walk(Vector3(0, 0, -36), 8.0)
	t.ok(inb, "вошёл в предбанник")
	hp0 = G.player.hp
	var st: bool = await t.walk(Vector3(0, 0, -51.5), 20.0)
	await t.sim(0.5)
	await t.flush()
	t.ok(st and L.boss.active, "прошёл мыльню (hp %d -> %d), бой с Банником начался; pos %s" % [int(hp0), int(G.player.hp), str(G.player.global_position)])
	G.player.revive()
	var won: bool = await t.fight(220.0)
	t.say("бой с Банником: %s, игрок hp %d" % ["победа" if won else "нет", int(G.player.hp)])
	if not won:
		G.player.revive()
		t.kill_all()
	await t.sim(3.0)
	await t.flush()
	t.ok(G.flag("bn_boss") and G.has("btn3"), "Банник побеждён, кнопка «Т» получена")
	G.player.revive()
	var outb: bool = await t.walk(Vector3(0, 0, -45), 20.0)
	outb = await t.walk(Vector3(0, 0, -27), 20.0) and outb
	t.ok(outb, "вышел из бани")
	t.tp(5.2, 0.1, -23.6, PI)
	await t.sim(0.3)
	await t.use()
	await t.flush()
	t.ok(G.player.global_position.z > 50.0, "сани довезли до полустанка")
	t.say(t.state())
