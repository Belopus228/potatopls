class_name Menus
extends RefCounted
## Меню и окна: главное, пауза, настройки, управление, главы, поражение, рюкзак, магазин.

const QUAL := ["Низкая", "Средняя", "Высокая"]


static func main(ui: UI) -> void:
	var root := ui.open_raw("main")
	var vb := VBoxContainer.new()
	vb.position = Vector2(84, 110)
	vb.add_theme_constant_override("separation", 10)
	root.add_child(vb)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 0)
	vb.add_child(hb)
	for part in [["МЕЛЛ", Color.WHITE], ["СТРОЙНОСТЬ", UI.Y], [" 3D", Color.WHITE]]:
		var l := UI.label(part[0], 70, part[1], true)
		l.add_theme_constant_override("outline_size", 12)
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
		hb.add_child(l)
	var sub := UI.label("ФАНАТСКАЯ ПАРОДИЯ  ·  МУРИНО  ·  МОЛОЧНОЕ  ·  МЫТИЩИ  ·  БАНЬКА  ·  ЖМУРИНО", 16, Color(1, 1, 1, 0.75), true)
	vb.add_child(sub)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 18)
	vb.add_child(gap)
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(340, 0)
	col.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	col.add_theme_constant_override("separation", 10)
	vb.add_child(col)
	if G.has_save():
		ui.button(col, "ПРОДОЛЖИТЬ", func(): G.continue_game())
		ui.button(col, "НОВАЯ ИГРА", func(): confirm(ui, "Начать заново?", "Старое сохранение сотрётся.", func(): G.new_game(), func(): main(ui)))
	else:
		ui.button(col, "НОВАЯ ИГРА", func(): G.new_game())
	if (G.save.get("done", []) as Array).size() > 0:
		ui.button(col, "ГЛАВЫ", func(): chapters(ui))
	ui.button(col, "НАСТРОЙКИ", func(): settings(ui, func(): main(ui)))
	ui.button(col, "УПРАВЛЕНИЕ", func(): help(ui, func(): main(ui)))
	if not G.web and not G.mobile:
		ui.button(col, "ВЫХОД", func(): G.get_tree().quit())
	for c in col.get_children():
		(c as Button).alignment = HORIZONTAL_ALIGNMENT_LEFT
	ui.focus_first(col)
	var ver := UI.label("версия %s · Godot %s" % [G.VERSION, Engine.get_version_info()["string"].get_slice(" ", 0)], 14, Color(1, 1, 1, 0.5))
	ver.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	ver.position = Vector2(-260, -34)
	root.add_child(ver)


static func confirm(ui: UI, title: String, text: String, yes: Callable, no: Callable) -> void:
	var vb := ui.open_panel("confirm", title, 460)
	var l := UI.label(text, 20)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(l)
	ui.button(vb, "ДА", yes)
	ui.button(vb, "НЕТ", no)
	ui.focus_first(vb)


static func pause(ui: UI) -> void:
	G.set_mode("pause")
	var vb := ui.open_panel("pause", "ПАУЗА", 460)
	ui.button(vb, "ПРОДОЛЖИТЬ", func(): resume(ui))
	if G.level and G.level.tutor_on:
		ui.button(vb, "ПРОПУСТИТЬ ОБУЧЕНИЕ", func():
			G.level.tutor_skip()
			resume(ui))
	ui.button(vb, "С КОНТРОЛЬНОЙ ТОЧКИ", func(): G.retry())
	ui.button(vb, "НАСТРОЙКИ", func(): settings(ui, func(): pause(ui)))
	ui.button(vb, "УПРАВЛЕНИЕ", func(): help(ui, func(): pause(ui)))
	ui.button(vb, "В ГЛАВНОЕ МЕНЮ", func():
		G.write_save()
		G.go("menu"))
	var st := UI.label("Время: %s   ·   Побеждено: %d   ·   Падений: %d" % [G.fmt_time(float(G.save["time"])), int(G.save["kills"]), int(G.save["deaths"])], 15, Color(1, 1, 1, 0.6))
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(st)
	ui.focus_first(vb)


static func resume(ui: UI) -> void:
	ui.close_panel()
	G.set_mode("play")


static func _row(vb: VBoxContainer, text: String) -> HBoxContainer:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	var l := UI.label(text, 20)
	l.custom_minimum_size = Vector2(250, 0)
	hb.add_child(l)
	vb.add_child(hb)
	return hb


static func _cycle(ui: UI, hb: HBoxContainer, names: Array, cur: int, cb: Callable) -> void:
	var b := Button.new()
	b.text = names[cur]
	b.custom_minimum_size = Vector2(230, 44)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var state := [cur]
	b.pressed.connect(func():
		state[0] = (state[0] + 1) % names.size()
		b.text = names[state[0]]
		Snd.sfx("ui", -6.0)
		cb.call(state[0]))
	hb.add_child(b)


static func _slider(hb: HBoxContainer, lo: float, hi: float, cur: float, cb: Callable) -> void:
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = 0.05
	s.value = cur
	s.custom_minimum_size = Vector2(230, 36)
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.value_changed.connect(func(v: float): cb.call(v))
	hb.add_child(s)


static func settings(ui: UI, back: Callable) -> void:
	var vb := ui.open_panel("settings", "НАСТРОЙКИ", 580)
	var S := G.settings
	_cycle(ui, _row(vb, "Графика"), QUAL, G.quality, func(i: int):
		S["q"] = i
		G.quality = i
		G.apply_settings())
	_slider(_row(vb, "Чувствительность камеры"), 0.3, 2.5, float(S["sens"]), func(v: float): S["sens"] = v)
	_slider(_row(vb, "Музыка"), 0.0, 1.0, float(S["music"]), func(v: float):
		S["music"] = v
		Snd.set_volumes(v, float(S["sfx"])))
	_slider(_row(vb, "Звуки"), 0.0, 1.0, float(S["sfx"]), func(v: float):
		S["sfx"] = v
		Snd.set_volumes(float(S["music"]), v))
	var vn := Snd.voice_count()
	_cycle(ui, _row(vb, "Озвучка реплик" if vn > 0 else "Озвучка (записей пока нет)"), ["Выкл", "Вкл"], 1 if S.get("voice", true) else 0, func(i: int):
		S["voice"] = i == 1
		Snd.set_voice(i == 1, float(S.get("voice_vol", 1.0))))
	_slider(_row(vb, "Громкость голосов"), 0.0, 1.0, float(S.get("voice_vol", 1.0)), func(v: float):
		S["voice_vol"] = v
		Snd.set_voice(bool(S.get("voice", true)), v))
	_cycle(ui, _row(vb, "Инверсия камеры по вертикали"), ["Выкл", "Вкл"], 1 if S["inv_y"] else 0, func(i: int): S["inv_y"] = i == 1)
	_cycle(ui, _row(vb, "Тряска камеры"), ["Выкл", "Вкл"], 1 if S["shake"] else 0, func(i: int): S["shake"] = i == 1)
	_cycle(ui, _row(vb, "Сенсорные кнопки"), ["Авто", "Вкл", "Выкл"], {-1: 0, 1: 1, 0: 2}[int(S["touch"])], func(i: int):
		S["touch"] = [-1, 1, 0][i]
		G.touch = (G.mobile or DisplayServer.is_touchscreen_available()) if i == 0 else i == 1
		ui.apply_settings())
	_cycle(ui, _row(vb, "Счётчик кадров"), ["Выкл", "Вкл"], 1 if S.get("fps", false) else 0, func(i: int): S["fps"] = i == 1)
	if not G.web and not G.mobile:
		var fs := DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]
		_cycle(ui, _row(vb, "Полный экран"), ["Выкл", "Вкл"], 1 if fs else 0, func(i: int):
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if i == 1 else DisplayServer.WINDOW_MODE_WINDOWED))
	ui.button(vb, "НАЗАД", func():
		G.write_settings()
		back.call())
	ui.focus_first(vb)


static func help(ui: UI, back: Callable) -> void:
	var vb := ui.open_panel("help", "УПРАВЛЕНИЕ", 720)
	var rows := [
		["Ходьба / бег", "WASD / Shift", "левый стик / нажать стик", "стик слева / до упора"],
		["Камера", "мышь или стрелки, колесо — приближение", "правый стик", "вести пальцем справа"],
		["Удар (серия из трёх)", "левая кнопка мыши или J", "X", "УДАР"],
		["Прыжок", "Пробел", "A", "ПРЫЖОК"],
		["Перекат", "C или колёсико", "B", "КАТ"],
		["Бросить котлету денег", "правая кнопка мыши или F", "RB", "₽"],
		["Действие, разговор", "E", "Y", "!"],
		["Дихлофос (держать)", "Q", "LB", "ПШИК"],
		["Ульта «АМ-АМ-АМ»", "R", "RT", "АМ!"],
		["Съесть еду", "1", "крестовина вверх", "ЕДА"],
		["Рюкзак / пауза", "Tab / Esc", "Back / Start", "РЮКЗАК / II"],
	]
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 26)
	grid.add_theme_constant_override("v_separation", 6)
	vb.add_child(grid)
	var ci := 3 if G.touch else (2 if Inp.last_device == "pad" else 1)
	for r in rows:
		grid.add_child(UI.label(r[0], 19, Color(1, 1, 1, 0.75)))
		var v := UI.label(r[ci], 19, Color.WHITE)
		v.add_theme_font_override("font", UI.font_bold())
		grid.add_child(v)
	var tip := UI.label("Жёлтая метка ведёт к цели. Перекат спасает от ударов. Копи ярость ударами — и кричи.", 16, Color(1, 1, 1, 0.6))
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(tip)
	ui.button(vb, "НАЗАД", back)
	ui.focus_first(vb)


static func chapters(ui: UI) -> void:
	var vb := ui.open_panel("chapters", "ГЛАВЫ", 480)
	var done: Array = G.save.get("done", [])
	for c in Story.CHAPTERS:
		var id: String = c[0]
		if done.has(id) or id == String(G.save.get("lv", "")):
			ui.button(vb, String(c[1]).to_upper(), func(): G.go(id, "start"))
	ui.button(vb, "НАЗАД", func(): main(ui))
	ui.focus_first(vb)


static func death(ui: UI) -> void:
	var quips := ["Плаки-плаки…", "Что за бизнес…", "Не сегодня, Ч.", "Туман ближе, чем кажется."]
	var vb := ui.open_panel("dead", "Ч ПАЛ", 460, 0.7)
	var l := UI.label(quips[randi() % quips.size()], 20, Color(1, 1, 1, 0.8))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(l)
	ui.button(vb, "С КОНТРОЛЬНОЙ ТОЧКИ", func(): G.retry())
	ui.button(vb, "В ГЛАВНОЕ МЕНЮ", func(): G.go("menu"))
	ui.focus_first(vb)


static func inventory(ui: UI) -> void:
	G.set_mode("panel")
	var vb := ui.open_panel("inv", "РЮКЗАК", 760)
	var money := UI.label("₽ %d" % G.money(), 24, Color(0.65, 1.0, 0.6))
	money.add_theme_font_override("font", UI.font_bold())
	money.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(money)
	var desc := UI.label("Наведи на вещь, чтобы прочитать описание.", 17, Color(1, 1, 1, 0.75))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(700, 50)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	vb.add_child(grid)
	var any := false
	for kind in ["gear", "food", "quest"]:
		for id in Items.DEFS:
			if Items.DEFS[id].get("kind", "") != kind or not G.has(id):
				continue
			any = true
			var d: Dictionary = Items.DEFS[id]
			var b := Button.new()
			b.text = String(d["name"]) + (" ×%d" % G.count(id) if G.count(id) > 1 else "")
			b.custom_minimum_size = Vector2(232, 44)
			b.add_theme_font_override("font", UI.font_bold())
			b.add_theme_font_size_override("font_size", 17)
			var show := func(): desc.text = String(d.get("desc", ""))
			b.focus_entered.connect(show)
			b.mouse_entered.connect(show)
			if kind == "food":
				b.pressed.connect(func():
					if G.player.hp < G.max_hp() - 0.5 or d.has("rage") or d.has("buff"):
						G.take(id)
						G.player.heal(d.get("heal", 0))
						if d.has("rage"):
							G.player.add_rage(d["rage"])
						if d.has("buff"):
							G.player.buff_t = d["buff"]
						Snd.sfx("eat", -3.0)
						inventory(ui)
					else:
						desc.text = "Ч и так здоров.")
			grid.add_child(b)
	if not any:
		vb.add_child(UI.label("Пусто. Даже хлеба нет.", 19, Color(1, 1, 1, 0.7)))
	vb.add_child(desc)
	ui.button(vb, "ЗАКРЫТЬ", func():
		ui.close_panel()
		G.set_mode("play"))
	ui.focus_first(grid if any else vb)


## Магазин. goods: ["doshik", "bread", ["chain", 60], …]; done — вызывается при закрытии.
static func shop(ui: UI, title: String, sub: String, goods: Array) -> void:
	G.set_mode("panel")
	var vb := ui.open_panel("shop", title, 640)
	if sub != "":
		var s := UI.label(sub, 17, Color(1, 1, 1, 0.7))
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(s)
	var money := UI.label("₽ %d" % G.money(), 24, Color(0.65, 1.0, 0.6))
	money.add_theme_font_override("font", UI.font_bold())
	money.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(money)
	var desc := UI.label(" ", 16, Color(1, 1, 1, 0.75))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(590, 44)
	var btns: Array = []
	for g in goods:
		var id: String = g[0] if g is Array else g
		var d: Dictionary = Items.DEFS[id]
		var price: int = g[1] if g is Array else int(d.get("price", 10))
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 46)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_override("font", UI.font_bold())
		b.add_theme_font_size_override("font_size", 19)
		var upd := func():
			var have := G.count(id)
			b.text = "  %s — ₽ %d%s" % [String(d["name"]), price, ("   (есть: %d)" % have) if have > 0 else ""]
			b.disabled = G.money() < price or (d.get("kind", "") == "gear" and id not in ["chain", "tasty"] and have > 0)
		upd.call()
		var show := func(): desc.text = String(d.get("desc", ""))
		b.focus_entered.connect(show)
		b.mouse_entered.connect(show)
		b.pressed.connect(func():
			if G.spend(price):
				G.give(id, 1, true)
				Snd.sfx("coin", -4.0)
				money.text = "₽ %d" % G.money()
				for u in btns:
					u.call()
			else:
				Snd.sfx("deny", -5.0))
		btns.append(upd)
		vb.add_child(b)
	vb.add_child(desc)
	ui.button(vb, "УЙТИ", func():
		ui.close_panel()
		G.set_mode("play"))
	ui.focus_first(vb)


## Финальные титры: итоги прохождения. secret — собрана и запасная кнопка «Ж».
static func ending(ui: UI, secret: bool) -> void:
	G.set_mode("panel")
	var vb := ui.open_panel("ending", "ПЕРВЫЙ ЭТАЖ", 620, 0.82)
	var sub := UI.label("32 августа, 00:00. Туман ушёл. Ч приехал.", 20, Color(1, 1, 1, 0.85))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(sub)
	var t := int(G.save.get("time", 0.0))
	var time_s := "%d:%02d:%02d" % [t / 3600, (t / 60) % 60, t % 60] if t >= 3600 else "%02d:%02d" % [(t / 60) % 60, t % 60]
	var rows := [["Время", time_s], ["Побеждено пакостей", str(int(G.save.get("kills", 0)))], ["Падений", str(int(G.save.get("deaths", 0)))],
		["Заработано", "%d ₽" % int(G.save.get("earned", 0))], ["Табло ливта", "1 Э Т А Ж" if secret else "1 Э Т А _"]]
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 40)
	grid.add_theme_constant_override("v_separation", 6)
	for r in rows:
		grid.add_child(UI.label(r[0], 20, Color(1, 1, 1, 0.7)))
		var v := UI.label(r[1], 22, UI.Y, true)
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(v)
	var cc := CenterContainer.new()
	grid.custom_minimum_size = Vector2(460, 0)
	cc.add_child(grid)
	vb.add_child(cc)
	var note := UI.label("Секретная концовка: ливт починен. Навсегда. Ну, до следующего августа." if secret else "В казино «Бурмалда» в Жмурино, говорят, разыгрывают запасную кнопку «Ж»…", 17, Color(1, 1, 1, 0.75))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.custom_minimum_size = Vector2(560, 0)
	vb.add_child(note)
	var cr := UI.label("МЕЛЛСТРОЙНОСТЬ 3D · сделано на Godot 4 · модели и текстуры CC0 (см. CREDITS.md)", 14, Color(1, 1, 1, 0.5))
	cr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cr.custom_minimum_size = Vector2(560, 0)
	vb.add_child(cr)
	ui.button(vb, "ОСТАТЬСЯ ВО ДВОРЕ", func():
		ui.close_panel()
		G.set_mode("play"))
	ui.button(vb, "В МУРИНО", func():
		ui.close_panel()
		G.set_mode("play")
		G.travel("murino", "lobby"))
	ui.button(vb, "В ГЛАВНОЕ МЕНЮ", func():
		ui.close_panel()
		G.go("menu"))
	ui.focus_first(vb)
