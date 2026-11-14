extends RefCounted
## Служебное: бой бота с боссом и сводка (для баланса). Запуск: --test=_boss --boss=dark|rat|…


func run(t) -> void:
	var which := String(G.opts.get("boss", "rat"))
	var setups := {
		"rat": ["dorm", "boss", Vector3(-4.5, -3.9, 10), {"spray": 1, "doshik": 2}],
		"dark": ["murino", "roof", Vector3(0, 90.1, 70.5), {"spray": 1, "am": 1, "chain": 1, "doshik": 2, "shawa": 1}],
		"mother": ["milk", "pit", Vector3.ZERO, {"spray": 1, "am": 1, "kicks": 1, "chain": 1, "tasty": 1, "doshik": 2, "milk": 2}],
		"moidodyr": ["myt", "palace", Vector3.ZERO, {"spray": 1, "am": 1, "kicks": 1, "chain": 2, "tasty": 1, "doshik": 2, "milk": 2}],
		"bannik": ["banya", "lake", Vector3.ZERO, {"spray": 1, "am": 1, "kicks": 1, "chain": 2, "tasty": 2, "doshik": 2, "kvass": 1}],
		"concierge": ["jmur", "boss", Vector3.ZERO, {"spray": 1, "am": 1, "kicks": 1, "chain": 3, "tasty": 2, "doshik": 2, "kvass": 1}],
		"fog": ["final", "start", Vector3.ZERO, {"spray": 1, "am": 1, "kicks": 1, "chain": 3, "tasty": 3, "doshik": 2, "kvass": 2}],
	}
	var s: Array = setups[which]
	G.save = G.new_save()
	for k in s[3]:
		G.save["inv"][k] = s[3][k]
	G.save["money"] = 40
	await t.start(String(s[0]), String(s[1]), false)
	G.player.revive()
	t.kill_all()
	if s[2] != Vector3.ZERO:
		t.tp(s[2].x, s[2].y, s[2].z, 0)
	if G.level.has_method("test_boss"):
		await G.level.call("test_boss")
	await t.sim(0.6)
	await t.flush()
	var b: Enemy = null
	for e in G.ents:
		if e.boss:
			b = e
	if b == null or not b.active:
		t.ok(false, "босс не начал бой")
		return
	var hp0: float = G.player.hp
	var t0 := Time.get_ticks_msec()
	var f0 := Engine.get_physics_frames()
	var won: bool = await t.fight(240.0)
	var sec := (Engine.get_physics_frames() - f0) / 60.0
	t.say("БОСС %s: %s за %.0f с игрового времени; у игрока %d/%d hp, еды осталось %d, смертей %d; у босса %d/%d" % [which, "ПОБЕДА" if won else "ПОРАЖЕНИЕ", sec, int(G.player.hp), int(G.player.hp_max), G.player.food_count(), int(G.save["deaths"]), int(b.hp) if is_instance_valid(b) else 0, int(b.hp_max) if is_instance_valid(b) else 0])
	t.ok(true, "бой проведён")
