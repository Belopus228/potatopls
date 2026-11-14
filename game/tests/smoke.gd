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
	G.ui.auto_choice = [1]
	await t.use()
	await t.flush()
	t.ok(G.ui.said.has("Что за бизнес?"), "диалог прошёл (%d реплик)" % G.ui.said.size())
	t.say(t.state())
	# звук: каждая дорожка и каждый эффект, которые просит код, должны существовать и грузиться
	var miss: Array = []
	for m in ["menu", "dorm", "murino", "milk", "myt", "banya", "jmur", "fog", "boss", "win"]:
		var st: AudioStream = Snd._stream(Snd.MUSIC_DIR, m)
		if st == null or st.get_length() < 10.0:
			miss.append("music/" + m)
	for x in ["item", "land", "jump", "step", "swing", "hit", "hit_big", "roll", "hurt", "deny", "throw", "spray", "am", "eat", "alert", "dash", "shoot", "die", "coin", "crate",
			"break", "door", "ui", "blip", "lose", "open", "boss_die", "roar", "crash", "phone", "unlock", "win", "lift"]:
		if Snd._stream(Snd.SFX_DIR, x) == null:
			miss.append("sfx/" + x)
	t.ok(miss.is_empty(), "музыка и звуки на месте: 10 дорожек, 33 эффекта" if miss.is_empty() else "нет звуков: " + str(miss))
