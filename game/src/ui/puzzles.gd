class_name Puzzles
extends RefCounted
## Головоломки в окнах: кодовый замок, провода (повернуть плитки), «запомни этажи».


## Кодовый замок. Возвращает введённые цифры или "" (отмена).
static func keypad(ui: UI, title: String, digits: int, hint: String) -> String:
	if ui.auto_skip:
		return String(ui.auto_choice.pop_front()) if not ui.auto_choice.is_empty() else ""
	G.cut_begin()
	var prev := G.mode
	G.set_mode("panel")
	var vb := ui.open_panel("puzzle", title, 420)
	var h := UI.label(hint, 17, Color(1, 1, 1, 0.75))
	h.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.custom_minimum_size = Vector2(380, 0)
	vb.add_child(h)
	var disp := UI.label("_ ".repeat(digits).strip_edges(), 54, UI.Y, true)
	disp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(disp)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	var cc := CenterContainer.new()
	cc.add_child(grid)
	vb.add_child(cc)
	var st := {"val": "", "done": false, "res": ""}
	var upd := func():
		var s := ""
		for i in digits:
			s += (st["val"][i] if i < String(st["val"]).length() else "_") + " "
		disp.text = s.strip_edges()
	var finish := func(res: String):
		if st["done"]:
			return
		st["done"] = true
		st["res"] = res
		ui.close_panel()
	for k in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "C", "0", "OK"]:
		var b := Button.new()
		b.text = k
		b.custom_minimum_size = Vector2(96, 64)
		b.add_theme_font_size_override("font_size", 28)
		b.pressed.connect(func():
			Snd.sfx("ui", -6.0, 1.2)
			if k == "C":
				st["val"] = ""
			elif k == "OK":
				if String(st["val"]).length() == digits:
					finish.call(st["val"])
				return
			elif String(st["val"]).length() < digits:
				st["val"] = String(st["val"]) + k
			upd.call())
		grid.add_child(b)
	ui.button(vb, "ОТОЙТИ", func(): finish.call(""))
	ui.focus_first(grid)
	await ui.panel_closed
	G.set_mode("cut" if prev == "cut" or G.in_script > 0 else "play")
	G.cut_end()
	return String(st["res"])


## «Запомни этажи»: панель показывает последовательность, игрок повторяет. Возвращает true при успехе.
static func simon(ui: UI, title: String, hint: String, labels: Array, length: int) -> bool:
	if ui.auto_skip:
		return true
	G.cut_begin()
	G.set_mode("panel")
	var vb := ui.open_panel("puzzle", title, 460)
	var info := UI.label(hint, 17, Color(1, 1, 1, 0.8))
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.custom_minimum_size = Vector2(420, 48)
	vb.add_child(info)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	var cc := CenterContainer.new()
	cc.add_child(grid)
	vb.add_child(cc)
	var st := {"seq": [], "pos": 0, "busy": true, "done": false, "ok": false}
	var btns: Array[Button] = []
	var lit := UI.sb(UI.Y, 10, UI.Y, 2, 10)
	var flash := func(i: int, t: float):
		btns[i].add_theme_stylebox_override("normal", lit)
		btns[i].add_theme_color_override("font_color", Color(0.07, 0.07, 0.09))
		Snd.sfx("ui", -4.0, 0.8 + i * 0.07, 0.0)
		await ui.get_tree().create_timer(t).timeout
		if is_instance_valid(btns[i]):
			btns[i].remove_theme_stylebox_override("normal")
			btns[i].remove_theme_color_override("font_color")
	var play := func():
		st["busy"] = true
		st["pos"] = 0
		info.text = "Ливт показывает маршрут. Запоминай…"
		await ui.get_tree().create_timer(0.7).timeout
		for i in st["seq"]:
			if st["done"]:
				return
			await flash.call(i, 0.45)
			await ui.get_tree().create_timer(0.18).timeout
		info.text = "Теперь повтори в том же порядке."
		st["busy"] = false
	for i in labels.size():
		var b := Button.new()
		b.text = String(labels[i])
		b.custom_minimum_size = Vector2(120, 64)
		b.add_theme_font_size_override("font_size", 24)
		b.pressed.connect(func():
			if st["busy"] or st["done"]:
				return
			flash.call(i, 0.15)
			if st["seq"][st["pos"]] == i:
				st["pos"] = int(st["pos"]) + 1
				if st["pos"] >= (st["seq"] as Array).size():
					st["done"] = true
					st["ok"] = true
					ui.close_panel()
			else:
				Snd.sfx("deny", -3.0)
				info.text = "Ливт обиделся. Смотри ещё раз."
				play.call())
		btns.append(b)
		grid.add_child(b)
	for k in length:
		(st["seq"] as Array).append(randi() % labels.size())
	ui.button(vb, "ОТОЙТИ", func():
		st["done"] = true
		ui.close_panel())
	play.call()
	await ui.panel_closed
	st["done"] = true
	G.set_mode("cut")
	G.cut_end()
	return bool(st["ok"])


## «Рубильники»: включи такие, чтобы сумма была ровно target. values — номиналы. Возвращает true при успехе.
static func switches(ui: UI, title: String, hint: String, values: Array, target: int, unit := "А") -> bool:
	if ui.auto_skip:
		return true
	G.cut_begin()
	G.set_mode("panel")
	var vb := ui.open_panel("puzzle", title, 480)
	var info := UI.label(hint, 17, Color(1, 1, 1, 0.8))
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.custom_minimum_size = Vector2(440, 48)
	vb.add_child(info)
	var total := UI.label("0 / %d %s" % [target, unit], 34, UI.Y, true)
	total.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(total)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	var cc := CenterContainer.new()
	cc.add_child(grid)
	vb.add_child(cc)
	var st := {"sum": 0, "ok": false}
	var lit := UI.sb(UI.Y, 10, UI.Y, 2, 10)
	for i in values.size():
		var b := Button.new()
		b.text = "%d %s" % [int(values[i]), unit]
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(130, 60)
		b.add_theme_font_size_override("font_size", 22)
		b.add_theme_stylebox_override("pressed", lit)
		b.add_theme_color_override("font_pressed_color", Color(0.07, 0.07, 0.09))
		b.toggled.connect(func(on: bool):
			st["sum"] = int(st["sum"]) + (int(values[i]) if on else -int(values[i]))
			total.text = "%d / %d %s" % [int(st["sum"]), target, unit]
			total.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5) if int(st["sum"]) == target else (Color(1.0, 0.45, 0.4) if int(st["sum"]) > target else UI.Y))
			Snd.sfx("ui", -4.0, 1.2 if on else 0.8, 0.0))
		grid.add_child(b)
	ui.button(vb, "ВКЛЮЧИТЬ", func():
		if int(st["sum"]) == target:
			st["ok"] = true
			Snd.sfx("unlock", 0.0)
			ui.close_panel()
		else:
			Snd.sfx("deny", -3.0)
			info.text = "Щёлк — и ничего. Сумма должна быть ровно %d %s." % [target, unit])
	ui.button(vb, "ОТОЙТИ", func(): ui.close_panel())
	ui.focus_first(grid)
	await ui.panel_closed
	G.set_mode("cut")
	G.cut_end()
	return bool(st["ok"])


## «Напёрстки»: фишка под одним из трёх стаканов, крупье называет перестановки — уследи. Возвращает true, если угадал.
static func cups(ui: UI, title: String, swaps: int) -> bool:
	if ui.auto_skip:
		return true
	G.cut_begin()
	G.set_mode("panel")
	var vb := ui.open_panel("puzzle", title, 480)
	var info := UI.label("Смотри внимательно…", 22, Color(1, 1, 1, 0.9))
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.custom_minimum_size = Vector2(440, 64)
	vb.add_child(info)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 10)
	vb.add_child(hb)
	var st := {"pos": randi() % 3, "busy": true, "done": false, "ok": false}
	var btns: Array[Button] = []
	var lit := UI.sb(UI.Y, 10, UI.Y, 2, 10)
	for i in 3:
		var b := Button.new()
		b.text = "СТАКАН %d" % (i + 1)
		b.custom_minimum_size = Vector2(136, 90)
		b.add_theme_font_size_override("font_size", 20)
		b.pressed.connect(func():
			if st["busy"] or st["done"]:
				return
			st["done"] = true
			st["ok"] = int(st["pos"]) == i
			Snd.sfx("win" if st["ok"] else "deny", -3.0)
			ui.close_panel())
		btns.append(b)
		hb.add_child(b)
	ui.button(vb, "ОТОЙТИ", func():
		st["done"] = true
		ui.close_panel())
	var run := func():
		var tree := ui.get_tree()
		await tree.create_timer(0.6).timeout
		if st["done"]:
			return
		info.text = "Фишка — под стаканом %d." % (int(st["pos"]) + 1)
		btns[int(st["pos"])].add_theme_stylebox_override("normal", lit)
		await tree.create_timer(1.3).timeout
		if st["done"]:
			return
		btns[int(st["pos"])].remove_theme_stylebox_override("normal")
		for k in swaps:
			var a := randi() % 3
			var b2 := (a + 1 + randi() % 2) % 3
			if int(st["pos"]) == a:
				st["pos"] = b2
			elif int(st["pos"]) == b2:
				st["pos"] = a
			info.text = "Кручу-верчу: меняю %d и %d" % [mini(a, b2) + 1, maxi(a, b2) + 1]
			Snd.sfx("ui", -4.0, 0.9 + k * 0.05, 0.0)
			await tree.create_timer(maxf(0.55, 1.05 - k * 0.07)).timeout
			if st["done"]:
				return
			info.text = "…"
			await tree.create_timer(0.16).timeout
			if st["done"]:
				return
		info.text = "Ну? Где фишка?"
		st["busy"] = false
		if is_instance_valid(btns[0]) and not G.touch:
			btns[0].grab_focus()
	run.call()
	await ui.panel_closed
	st["done"] = true
	G.set_mode("cut")
	G.cut_end()
	return bool(st["ok"])
