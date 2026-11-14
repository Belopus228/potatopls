class_name UI
extends CanvasLayer
## Весь интерфейс: HUD, диалоги, подсказки, заголовки, меню и окна, затемнение экрана.

signal advanced
signal chosen(i: int)
signal panel_closed

const Y := Color("ffd21f")
const DARK := Color(0.06, 0.06, 0.09, 0.9)

static var _f_big: FontVariation
static var _f_text: Font
static var _f_bold: Font

var root: Control
var hud: Hud
var touch_pad: TouchPad
var fade: ColorRect
var fade_lbl: Label
var toasts: VBoxContainer
var title_box: VBoxContainer
var big_lbl: Label
var dlg: PanelContainer
var dlg_face: TextureRect
var dlg_face_box: Panel
var dlg_initial: Label
var dlg_name: Label
var dlg_text: Label
var dlg_more: Label
var choice_box: VBoxContainer
var panel: Control
var panel_kind := ""
var auto_skip := false            # тесты: диалоги пролетают мгновенно
var auto_choice: Array = []       # тесты: очередь ответов для choose()
var said: Array = []
var _typing := 0.0
var _choosing := false
var _faces := {}
var _title_tw: Tween
var _big_tw: Tween


static func font_big() -> Font:
	if _f_big == null:
		_f_big = FontVariation.new()
		_f_big.base_font = load("res://assets/fonts/RussoOne-Regular.ttf")
		_f_big.fallbacks = [load("res://assets/fonts/Play-Bold.ttf")]
	return _f_big


static func font_text() -> Font:
	if _f_text == null:
		_f_text = load("res://assets/fonts/Play-Regular.ttf")
	return _f_text


static func font_bold() -> Font:
	if _f_bold == null:
		_f_bold = load("res://assets/fonts/Play-Bold.ttf")
	return _f_bold


static func sb(col: Color, radius := 10, border := Color(0, 0, 0, 0), bw := 0, pad := 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = col
	s.set_corner_radius_all(radius)
	if bw > 0:
		s.set_border_width_all(bw)
		s.border_color = border
	if pad > 0:
		s.set_content_margin_all(pad)
	return s


static var _round: ShaderMaterial

## Материал, обрезающий картинку по кругу (портреты).
static func round_mat() -> ShaderMaterial:
	if _round == null:
		var sh := Shader.new()
		sh.code = "shader_type canvas_item;\nvoid fragment() {\n\tfloat d = distance(UV, vec2(0.5));\n\tCOLOR.a *= 1.0 - smoothstep(0.48, 0.5, d);\n}\n"
		_round = ShaderMaterial.new()
		_round.shader = sh
	return _round


static func label(text: String, size := 20, col := Color.WHITE, big := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font_big() if big else font_text())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	l.add_theme_constant_override("shadow_offset_y", 2)
	return l


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = _make_theme()
	add_child(root)
	hud = Hud.new()
	root.add_child(hud)
	touch_pad = TouchPad.new()
	root.add_child(touch_pad)
	_build_dialog()
	_build_misc()
	apply_settings()


func _make_theme() -> Theme:
	var th := Theme.new()
	th.default_font = font_text()
	th.default_font_size = 20
	th.set_stylebox("normal", "Button", sb(Color(0.09, 0.09, 0.12, 0.92), 10, Color(1, 1, 1, 0.14), 2, 10))
	th.set_stylebox("hover", "Button", sb(Y, 10, Y, 2, 10))
	th.set_stylebox("pressed", "Button", sb(Color("e0b400"), 10, Y, 2, 10))
	th.set_stylebox("disabled", "Button", sb(Color(0.09, 0.09, 0.12, 0.5), 10, Color(1, 1, 1, 0.05), 2, 10))
	th.set_stylebox("focus", "Button", sb(Color(0, 0, 0, 0), 10, Y, 3, 10))
	th.set_color("font_color", "Button", Color.WHITE)
	th.set_color("font_hover_color", "Button", Color(0.07, 0.07, 0.09))
	th.set_color("font_pressed_color", "Button", Color(0.07, 0.07, 0.09))
	th.set_color("font_focus_color", "Button", Color.WHITE)
	th.set_color("font_disabled_color", "Button", Color(1, 1, 1, 0.35))
	th.set_font("font", "Button", font_big())
	th.set_font_size("font_size", "Button", 22)
	th.set_stylebox("panel", "PanelContainer", sb(DARK, 16, Color(1, 1, 1, 0.1), 2, 22))
	th.set_stylebox("panel", "Panel", sb(DARK, 12))
	th.set_stylebox("slider", "HSlider", sb(Color(1, 1, 1, 0.18), 4))
	th.set_stylebox("grabber_area", "HSlider", sb(Y, 4))
	th.set_stylebox("grabber_area_highlight", "HSlider", sb(Y, 4))
	return th


func apply_settings() -> void:
	if touch_pad:
		touch_pad.visible = G.touch
	if hud:
		hud.refresh_hints()


func wants_mouse() -> bool:
	return _choosing or panel != null


# ---------- затемнение, заголовки, подсказки ----------

func _build_misc() -> void:
	toasts = VBoxContainer.new()
	toasts.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toasts.position = Vector2(-260, 96)
	toasts.custom_minimum_size = Vector2(520, 0)
	toasts.alignment = BoxContainer.ALIGNMENT_BEGIN
	toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toasts.add_theme_constant_override("separation", 8)
	root.add_child(toasts)
	title_box = VBoxContainer.new()
	title_box.set_anchors_preset(Control.PRESET_CENTER)
	title_box.position = Vector2(-500, -190)
	title_box.custom_minimum_size = Vector2(1000, 0)
	title_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_box.modulate.a = 0.0
	root.add_child(title_box)
	big_lbl = label("", 84, Y, true)
	big_lbl.set_anchors_preset(Control.PRESET_CENTER)
	big_lbl.position = Vector2(-500, -60)
	big_lbl.custom_minimum_size = Vector2(1000, 0)
	big_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	big_lbl.add_theme_constant_override("outline_size", 16)
	big_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	big_lbl.modulate.a = 0.0
	big_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(big_lbl)
	fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 1)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(fade)
	fade_lbl = label("ЗАГРУЗКА ВКУСНОСТЕЙ…", 20, Color(1, 1, 1, 0.8), true)
	fade_lbl.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	fade_lbl.position = Vector2(-330, -56)
	fade.add_child(fade_lbl)


func fade_to(a: float, time := 0.4, loading := false) -> void:
	fade_lbl.visible = loading
	fade.mouse_filter = Control.MOUSE_FILTER_STOP if a > 0.5 else Control.MOUSE_FILTER_IGNORE
	if absf(fade.color.a - a) < 0.01:
		return
	var tw := create_tween()
	tw.tween_property(fade, "color:a", a, time)
	await tw.finished


func toast(text: String, kind := "", sub := "") -> void:
	var pc := PanelContainer.new()
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var big := kind == "big"
	pc.add_theme_stylebox_override("panel", sb(Color(0.05, 0.05, 0.08, 0.86), 10, Y if big or kind == "item" else Color(1, 1, 1, 0.12), 2, 10))
	var vb := VBoxContainer.new()
	pc.add_child(vb)
	var l := label(text, 26 if big else (17 if kind == "small" else 21), Y if big or kind == "item" else Color.WHITE, big or kind == "item")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(l)
	if sub != "":
		var l2 := label(sub, 16, Color(1, 1, 1, 0.8))
		l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vb.add_child(l2)
	toasts.add_child(pc)
	while toasts.get_child_count() > 4:
		var old := toasts.get_child(0)
		toasts.remove_child(old)
		old.queue_free()
	pc.modulate.a = 0.0
	var tw := pc.create_tween()
	tw.tween_property(pc, "modulate:a", 1.0, 0.15)
	tw.tween_interval(4.2 if sub != "" else (1.8 if kind == "small" else 2.8))
	tw.tween_property(pc, "modulate:a", 0.0, 0.3)
	tw.tween_callback(pc.queue_free)


## Заставка главы: крупное название и подпись.
func big_title(title: String, sub := "") -> void:
	for c in title_box.get_children():
		c.queue_free()
	if sub != "":
		var s := label(sub, 26, Y, true)
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_box.add_child(s)
	var t := label(title, 78, Color.WHITE, true)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_constant_override("outline_size", 14)
	t.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	title_box.add_child(t)
	if _title_tw:
		_title_tw.kill()
	_title_tw = create_tween()
	_title_tw.tween_property(title_box, "modulate:a", 1.0, 0.5)
	_title_tw.tween_interval(2.4)
	_title_tw.tween_property(title_box, "modulate:a", 0.0, 0.8)


func big_text(text: String) -> void:
	big_lbl.text = text
	if _big_tw:
		_big_tw.kill()
	big_lbl.modulate.a = 1.0
	big_lbl.scale = Vector2(0.7, 0.7)
	big_lbl.pivot_offset = Vector2(500, 50)
	_big_tw = create_tween().set_parallel(true)
	_big_tw.tween_property(big_lbl, "scale", Vector2(1.15, 1.15), 0.9).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_big_tw.tween_property(big_lbl, "modulate:a", 0.0, 0.4).set_delay(0.8)


# ---------- диалоги ----------

func _build_dialog() -> void:
	dlg = PanelContainer.new()
	dlg.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	dlg.custom_minimum_size = Vector2(900, 168)
	dlg.position = Vector2(-450, -196)
	dlg.add_theme_stylebox_override("panel", sb(Color(0.05, 0.05, 0.08, 0.93), 16, Color(1, 1, 1, 0.14), 2, 18))
	dlg.visible = false
	root.add_child(dlg)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 18)
	dlg.add_child(hb)
	dlg_face_box = Panel.new()
	dlg_face_box.custom_minimum_size = Vector2(124, 124)
	dlg_face_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dlg_face_box.add_theme_stylebox_override("panel", sb(Color(0.2, 0.2, 0.25), 62))
	hb.add_child(dlg_face_box)
	dlg_face = TextureRect.new()
	dlg_face.set_anchors_preset(Control.PRESET_FULL_RECT)
	dlg_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dlg_face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	dlg_face.material = round_mat()
	dlg_face_box.add_child(dlg_face)
	dlg_initial = label("?", 64, Color.WHITE, true)
	dlg_initial.set_anchors_preset(Control.PRESET_FULL_RECT)
	dlg_initial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dlg_initial.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dlg_face_box.add_child(dlg_initial)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(vb)
	dlg_name = label("", 24, Y, true)
	vb.add_child(dlg_name)
	dlg_text = label("", 24)
	dlg_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dlg_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dlg_text.custom_minimum_size = Vector2(700, 86)
	vb.add_child(dlg_text)
	dlg_more = label("", 15, Color(1, 1, 1, 0.55))
	dlg_more.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vb.add_child(dlg_more)
	choice_box = VBoxContainer.new()
	choice_box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	choice_box.custom_minimum_size = Vector2(520, 0)
	choice_box.position = Vector2(-260, -420)
	choice_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	choice_box.alignment = BoxContainer.ALIGNMENT_END
	choice_box.add_theme_constant_override("separation", 8)
	choice_box.visible = false
	root.add_child(choice_box)


func _face(id: String) -> Texture2D:
	if not _faces.has(id):
		var p := "res://assets/faces/%s.jpg" % id
		_faces[id] = load(p) if ResourceLoader.exists(p) else null
	return _faces[id]


func _show_line(who: Variant, text: String) -> void:
	var nm := ""
	var col := Y
	var face: Texture2D = null
	if who is Dictionary:
		nm = who.get("n", "")
		col = who.get("c", Y)
	else:
		var c: Dictionary = Cast.CAST.get(String(who), {})
		nm = c.get("name", String(who))
		col = c.get("col", Y)
		if c.has("face"):
			face = _face(c["face"])
	dlg_name.text = nm
	dlg_name.add_theme_color_override("font_color", col)
	dlg_face.texture = face
	dlg_face.visible = face != null
	dlg_initial.visible = face == null
	dlg_initial.text = nm.substr(0, 1) if nm != "" else "…"
	dlg_face_box.add_theme_stylebox_override("panel", sb(col.darkened(0.55), 62))
	dlg_text.text = text
	dlg_text.visible_characters = 0
	_typing = 0.0
	dlg_more.text = "дальше — %s" % ("касание" if G.touch else Inp.hint("interact"))
	dlg.visible = true
	hud.set_prompt_visible(false)


## Показать реплики по очереди: [["ch", "текст"], [{"n": "Имя"}, "текст"], …]
func say(lines: Array) -> void:
	G.cut_begin()
	for ln in lines:
		said.append(String(ln[1]))
		if auto_skip:
			continue
		_show_line(ln[0], ln[1])
		await advanced
	dlg.visible = false
	G.cut_end()


## Вопрос с вариантами ответа. Возвращает номер выбранного.
func choose(who: Variant, text: String, options: Array) -> int:
	G.cut_begin()
	said.append(text)
	if auto_skip:
		var a := 0
		if not auto_choice.is_empty():
			a = auto_choice.pop_front()
		G.cut_end()
		return clampi(a, 0, options.size() - 1)
	_show_line(who, text)
	dlg_text.visible_characters = -1
	dlg_more.text = ""
	for c in choice_box.get_children():
		c.queue_free()
	var first: Button = null
	for i in options.size():
		var b := Button.new()
		b.text = String(options[i])
		b.custom_minimum_size = Vector2(520, 50)
		b.pressed.connect(func(): chosen.emit(i))
		choice_box.add_child(b)
		if first == null:
			first = b
	choice_box.visible = true
	_choosing = true
	G._update_mouse()
	if first and not G.touch:
		first.grab_focus.call_deferred()
	var res: int = await chosen
	Snd.sfx("ui", -6.0)
	_choosing = false
	choice_box.visible = false
	dlg.visible = false
	G._update_mouse()
	G.cut_end()
	return res


func _process(dt: float) -> void:
	# пока висит заставка главы или босса, подсказки уезжают под неё, а не ложатся поверх
	var want := 96.0
	if title_box.modulate.a > 0.3 and title_box.get_child_count() > 0:
		want = 328.0
	if absf(toasts.offset_top - want) > 0.5:
		var h := toasts.offset_bottom - toasts.offset_top
		toasts.offset_top = lerpf(toasts.offset_top, want, minf(1.0, dt * 14.0))
		toasts.offset_bottom = toasts.offset_top + h
	if dlg.visible and dlg_text.visible_characters >= 0:
		var total := dlg_text.get_total_character_count()
		var before := dlg_text.visible_characters
		_typing += dt * 70.0
		dlg_text.visible_characters = mini(total, int(_typing))
		if dlg_text.visible_characters >= total:
			dlg_text.visible_characters = -1
		elif dlg_text.visible_characters / 4 != before / 4:
			Snd.blip(1.0)


func _input(e: InputEvent) -> void:
	if not dlg.visible or _choosing or panel != null:
		return
	var go := false
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		go = true
	elif e is InputEventScreenTouch and e.pressed:
		go = true
	elif e.is_action_pressed("interact") or e.is_action_pressed("jump") or e.is_action_pressed("attack"):
		go = true
	if go:
		get_viewport().set_input_as_handled()
		if dlg_text.visible_characters >= 0:
			dlg_text.visible_characters = -1
		else:
			advanced.emit()


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("pause"):
		if G.mode == "play":
			Menus.pause(self)
		elif panel != null and panel_kind in ["pause", "shop", "inv", "puzzle", "help", "settings"]:
			if panel_kind in ["help", "settings"] and G.level and G.level.id == "menu":
				Menus.main(self)
			else:
				close_panel()
				if G.mode in ["pause", "panel"]:
					G.set_mode("play")
	elif e.is_action_pressed("inv"):
		if G.mode == "play":
			Menus.inventory(self)
		elif panel_kind == "inv":
			close_panel()
			G.set_mode("play")


# ---------- окна ----------

## Открыть окно по центру; возвращает контейнер, куда складывать содержимое.
func open_panel(kind: String, title: String, width := 540.0, dim := 0.6) -> VBoxContainer:
	close_panel(false)
	panel = Control.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(panel)
	root.move_child(panel, fade.get_index())
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, dim)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(bg)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(cc)
	var pc := PanelContainer.new()
	pc.custom_minimum_size = Vector2(width, 0)
	cc.add_child(pc)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	pc.add_child(vb)
	if title != "":
		var t := label(title, 34, Y, true)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(t)
	panel_kind = kind
	G._update_mouse()
	return vb


## Пустое окно во весь экран (главное меню): содержимое раскладывается вручную.
func open_raw(kind: String) -> Control:
	close_panel(false)
	panel = Control.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(panel)
	root.move_child(panel, fade.get_index())
	panel_kind = kind
	G._update_mouse()
	return panel


func close_panel(notify := true) -> void:
	if panel:
		panel.queue_free()
		panel = null
		panel_kind = ""
		if notify:
			panel_closed.emit()
		G._update_mouse()


func close_all() -> void:
	close_panel(false)
	dlg.visible = false
	choice_box.visible = false
	_choosing = false


func button(parent: Control, text: String, cb: Callable, min_h := 50.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, min_h)
	b.pressed.connect(func():
		Snd.sfx("ui", -6.0)
		cb.call())
	parent.add_child(b)
	return b


func focus_first(parent: Control) -> void:
	if G.touch:
		return
	for c in parent.get_children():
		if c is Button and not (c as Button).disabled:
			(c as Button).grab_focus.call_deferred()
			return


func show_death() -> void:
	Menus.death(self)
