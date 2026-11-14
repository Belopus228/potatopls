extends RefCounted
## Финал: парадная -> двор -> ФОГ -> титры -> Друн -> обратно в Мурино.


func run(t) -> void:
	G.save = G.new_save()
	G.save["inv"] = {"phone": 1, "spray": 1, "am": 1, "kicks": 1, "chain": 3, "doshik": 2, "shawa": 1, "tasty": 3, "kvass": 2, "btn1": 1, "btn2": 1, "btn3": 1, "btn4": 1, "btn5": 1}
	G.save["money"] = 80
	G.save["flags"] = {"m_boss": true, "m_drun": true, "m_seen": true}
	await t.start("final", "start", false)
	await t.flush()
	var L = G.level
	t.say(t.state())
	t.ok(G.flag("f_seen") and not L.won, "финал начался в парадной")
	t.tp(4.2, 0.1, 39, -PI * 0.5)
	await t.sim(0.3)
	t.ok(G.player.near != null and String(G.player.near["label"]) == "Автомат с вкусностями", "автомат с вкусностями рядом")
	await t.walk(Vector3(0, 0, 33.7), 8.0, 0.4)
	G.player.face(Vector3(0, 0, 32))
	await t.sim(0.3)
	await t.use()
	await t.sim(0.8)
	var out: bool = await t.walk(Vector3(0, 0, 26), 8.0)
	t.ok(out, "вышел во двор: " + str(G.player.global_position))
	await t.walk(Vector3(0, 0, 17.5), 8.0)
	await t.sim(0.5)
	await t.flush()
	t.ok(L.boss.active and G.flag("f_met"), "бой с ФОГом начался")
	var blocked: bool = not await t.walk(Vector3(0, 0, 27), 2.5)
	t.ok(blocked, "двор закрыт туманом")
	var won: bool = await t.fight(240.0)
	t.say("бой с ФОГом: %s, игрок hp %d, у ФОГа %d" % ["победа" if won else "нет", int(G.player.hp), int(L.boss.hp) if is_instance_valid(L.boss) else 0])
	if not won:
		G.player.revive()
		t.kill_all()
	await t.sim(3.0)
	await t.until(func(): return G.ui.panel_kind == "ending", 20.0)
	t.ok(G.flag("f_boss") and G.ui.panel_kind == "ending", "ФОГ побеждён, показаны титры")
	t.ok(L.clock.text == "00:00", "на часах 00:00")
	G.ui.close_panel()
	G.set_mode("play")
	await t.flush()
	G.player.revive()
	await t.walk(Vector3(0, 0, 8.4), 12.0)
	G.player.face(Vector3(0, 0, 6))
	await t.sim(0.3)
	t.ok(G.player.near != null and String(G.player.near["label"]) == "Поговорить", "Друн ждёт во дворе")
	G.ui.auto_choice = [1]
	await t.use()
	await t.until(func(): return not G.loading and G.level != null and G.level.id == "murino", 30.0)
	await t.flush()
	t.ok(G.level.id == "murino", "вернулся в Мурино: " + t.state())
