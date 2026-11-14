extends Node
## Тестовый мост. Запуск сценариев: godot --headless --fixed-fps 60 --path game -- --test=имя[,имя2] --nosave
## В web-сборке из страницы можно выполнить кусок GDScript: window.gdCall("return G.mode"); ответ — в window.gdOut.

var oks := 0
var fails := 0
var running := false
var _cb: JavaScriptObject
var _win: JavaScriptObject


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.has_feature("web"):
		_cb = JavaScriptBridge.create_callback(_js_call)
		_win = JavaScriptBridge.get_interface("window")
		_win.gdCall = _cb
		JavaScriptBridge.eval("window.gdReady = true", true)


func _js_call(args: Array) -> void:
	var res: Variant = eval_src(str(args[0]))
	JavaScriptBridge.eval("window.gdOut = " + JSON.stringify(str(res)), true)


## Выполнить текст как тело функции GDScript (доступны G, T, Inp, Snd и все классы игры).
func eval_src(src: String) -> Variant:
	var body := ""
	for ln in src.split("\n"):
		body += "\t" + ln + "\n"
	var s := GDScript.new()
	s.source_code = "extends RefCounted\nfunc run():\n" + body + "\treturn null\n"
	if s.reload() != OK:
		return "ОШИБКА КОМПИЛЯЦИИ"
	var o: Variant = s.new()
	return o.run()


func say(msg: String) -> void:
	print("[T] ", msg)


func ok(c: bool, msg: String) -> bool:
	if c:
		oks += 1
		print("[T] ok: ", msg)
	else:
		fails += 1
		print("[T] !! ПРОВАЛ: ", msg)
	return c


func run_test(names: String) -> void:
	running = true
	G.ui.auto_skip = true
	for n in names.split(","):
		var path := "res://tests/%s.gd" % n
		if not ResourceLoader.exists(path):
			ok(false, "нет сценария " + n)
			continue
		say("=== " + n)
		var o: Variant = (load(path) as GDScript).new()
		await o.run(self)
	print("[T] ИТОГ: ok %d, провалов %d" % [oks, fails])
	get_tree().quit(1 if fails > 0 else 0)


func sim(sec: float) -> void:
	for i in maxi(1, int(sec * 60.0)):
		await get_tree().physics_frame


func until(f: Callable, max_sec := 10.0) -> bool:
	var n := int(max_sec * 60.0)
	for i in n:
		if f.call():
			return true
		await get_tree().physics_frame
	return bool(f.call())


## Загрузить уровень и дождаться, когда можно играть.
func start(lv: String, cp := "start", fresh := true) -> void:
	if fresh:
		G.save = G.new_save()
	G.loading = false
	G.go(lv, cp)
	await until(func(): return not G.loading and G.level != null and G.level.id == lv, 30.0)
	await flush()


## Дождаться конца сценок и диалогов.
func flush(max_sec := 20.0) -> bool:
	return await until(func(): return G.mode == "play" and G.in_script == 0 and not G.loading, max_sec)


func tp(x: float, y: float, z: float, yaw := 0.0) -> void:
	G.player.place(Vector3(x, y, z), yaw)
	G.cam.snap()


func state() -> String:
	var p := G.player
	return "[%s] mode=%s hp=%d ₽%d pos=(%.1f, %.1f, %.1f) inv=%s цель=\"%s\"" % [G.level.id if G.level else "-", G.mode, int(p.hp), G.money(), p.global_position.x, p.global_position.y, p.global_position.z, str(G.save["inv"]), G.ui.hud.goal_lbl.text]


func use() -> void:
	await sim(0.1)
	Inp.press("interact")
	await sim(0.05)
	Inp.release("interact")
	await sim(0.15)


## Идти пешком к точке (через ввод, как игрок). Возвращает, дошёл ли.
func walk(to: Vector3, max_sec := 14.0, tol := 0.8) -> bool:
	var p := G.player
	var n := int(max_sec * 60.0)
	var stuck := 0.0
	var side := 0.0
	var last := p.global_position
	for i in n:
		var d := to - p.global_position
		d.y = 0.0
		if d.length() < tol:
			break
		var dir := d.normalized()
		if side > 0.0:
			side -= 1.0 / 60.0
			dir = dir.rotated(Vector3.UP, 1.3)
		var loc := dir.rotated(Vector3.UP, -G.cam.yaw)
		Inp.touch_move = Vector2(loc.x, loc.z)
		Inp.touch_run = d.length() > 4.0
		if i % 30 == 29:
			if p.global_position.distance_to(last) < 0.25 and G.mode == "play":
				stuck += 1.0
				side = 0.7
				if stuck > 2.0:
					Inp.press("jump")
			else:
				stuck = 0.0
				Inp.release("jump")
			last = p.global_position
		await get_tree().physics_frame
	Inp.touch_move = Vector2.ZERO
	Inp.touch_run = false
	Inp.release("jump")
	var fd := to - p.global_position
	fd.y = 0.0
	return fd.length() < tol + 0.3


func kill_all(only_boss := false) -> int:
	var n := 0
	for e in G.ents.duplicate():
		if is_instance_valid(e) and not e.dead and (not only_boss or e.boss):
			e.guard = 1.0
			e.hittable = true
			e.hurt(999999.0, G.player.global_position, 0.0, "melee")
			n += 1
	return n


## Простой боевой бот: идёт к ближайшему врагу и бьёт; при замахе врага — перекат. Возвращает, все ли побеждены.
func fight(max_sec := 60.0) -> bool:
	var p := G.player
	var n := int(max_sec * 60.0)
	for i in n:
		if p.dead:
			break
		var tgt: Enemy = null
		var bd := 1e9
		for e in G.ents:
			if is_instance_valid(e) and not e.dead and e.active:
				var d: float = e.global_position.distance_to(p.global_position)
				if d < bd:
					bd = d
					tgt = e
		if tgt == null:
			break
		var d2 := tgt.global_position - p.global_position
		d2.y = 0.0
		var dist := d2.length() - tgt.radius
		var dir := d2.normalized()
		var loc := dir.rotated(Vector3.UP, -G.cam.yaw)
		if tgt.boss:
			var danger: bool = tgt.state in ["charge_w", "charge", "dash_w", "dash", "punch", "vanish", "kick", "tail_w", "slam_w", "slam", "leap", "dive", "spin", "sweep_w", "sweep"]
			var is_open: bool = tgt.guard >= 0.99
			var want := 0.0 if is_open else 6.0
			Inp.release("attack")
			Inp.release("dodge")
			Inp.release("jump")
			if danger and dist < 5.5 and p.state == "move" and p.st > 25.0 and i % 5 == 0:
				var sl2 := dir.rotated(Vector3.UP, PI * 0.5 * (1.0 if (i / 120) % 2 == 0 else -1.0)).rotated(Vector3.UP, -G.cam.yaw)
				Inp.touch_move = Vector2(sl2.x, sl2.z)
				Inp.press("dodge")
			elif is_open:
				Inp.touch_move = Vector2(loc.x, loc.z) if dist > 1.2 else Vector2.ZERO
				Inp.touch_run = dist > 4.0
				if dist < 2.0 and i % 9 == 0:
					Inp.press("attack")
			else:
				var away := dir.rotated(Vector3.UP, PI * 0.5 + (0.5 if dist < want else -0.5)).rotated(Vector3.UP, -G.cam.yaw)
				Inp.touch_move = Vector2(away.x, away.z)
				Inp.touch_run = false
				if G.money() >= 2 and i % 50 == 0 and dist < 12.0:
					Inp.press("throw")
				else:
					Inp.release("throw")
			# кольца по земле — перепрыгнуть
			if tgt.get("ring_on") == true and absf(Vector2(p.global_position.x - tgt.global_position.x, p.global_position.z - tgt.global_position.z).length() - float(tgt.get("ring_r"))) < 2.2 and p.is_on_floor():
				Inp.press("jump")
			if p.hp < p.hp_max * 0.45 and p.food_count() > 0 and i % 40 == 0:
				p.eat()
			if G.has("am") and p.rage >= 100.0 and dist < 7.0 and is_open:
				Inp.press("ult")
			else:
				Inp.release("ult")
			await get_tree().physics_frame
			continue
		if tgt.state in ["windup", "dash", "leap", "dive"] and dist < 4.0 and p.state == "move" and p.st > 25.0 and i % 4 == 0:
			var sl := dir.rotated(Vector3.UP, PI * 0.5).rotated(Vector3.UP, -G.cam.yaw)
			Inp.touch_move = Vector2(sl.x, sl.z)
			Inp.press("dodge")
		else:
			Inp.release("dodge")
			Inp.touch_move = Vector2(loc.x, loc.z) if dist > 1.2 else Vector2.ZERO
			Inp.touch_run = dist > 5.0
			if dist < 1.9 and i % 9 == 0:
				Inp.press("attack")
			else:
				Inp.release("attack")
		if p.hp < p.hp_max * 0.4 and p.food_count() > 0 and i % 60 == 0:
			p.eat()
		if G.has("am") and p.rage >= 100.0 and dist < 6.0:
			Inp.press("ult")
		else:
			Inp.release("ult")
		await get_tree().physics_frame
	Inp.release_all()
	Inp.touch_run = false
	return not p.dead and G.ents.filter(func(e): return is_instance_valid(e) and not e.dead and e.active).is_empty()
