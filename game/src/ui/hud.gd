class_name Hud
extends Control
## Экран в игре: здоровье, выносливость, ярость, дихлофос, деньги, еда, цель с меткой, подсказка действия, полоса босса.

var hp_bar: Bar
var st_bar: Bar
var rage_bar: Bar
var spray_bar: Bar
var money_lbl: Label
var food_lbl: Label
var goal_box: PanelContainer
var goal_lbl: Label
var goal_pos: Variant = null
var marker: Control
var marker_lbl: Label
var prompt: PanelContainer
var prompt_lbl: Label
var boss_box: VBoxContainer
var boss_lbl: Label
var boss_bar: Bar
var boss: Enemy
var hints: Label
var flash: ColorRect
var _money_shown := -1
var _prompt_ok := true
var fps_lbl: Label
var marks: Marks
var tutor_box: PanelContainer
var tutor_title: Label
var tutor_text: RichTextLabel
var tutor_bar: Bar
var tutor_hint: Label
var _tutor_tw: Tween


class Bar:
	extends Control
	var v := 1.0
	var col := Color(0.9, 0.2, 0.2)
	var text := ""
	var radius := 8
	var ghost := 1.0

	func _process(dt: float) -> void:
		if ghost > v:
			ghost = maxf(v, ghost - dt * 0.5)
			queue_redraw()
		elif ghost < v:
			ghost = v

	func set_v(nv: float, t := "") -> void:
		nv = clampf(nv, 0.0, 1.0)
		if absf(nv - v) > 0.0005 or t != text:
			v = nv
			text = t
			queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_style_box(UI.sb(Color(0, 0, 0, 0.6), radius), r)
		if ghost > v + 0.002:
			draw_style_box(UI.sb(Color(1, 1, 1, 0.55), radius), Rect2(2, 2, maxf(0.0, (size.x - 4) * ghost), size.y - 4))
		if v > 0.003:
			draw_style_box(UI.sb(col, radius), Rect2(2, 2, maxf(float(radius), (size.x - 4) * v), size.y - 4))
		if text != "":
			var f := UI.font_bold()
			var fs := int(size.y * 0.7)
			var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			draw_string_outline(f, Vector2((size.x - w) * 0.5, size.y * 0.76), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color(0, 0, 0, 0.8))
			draw_string(f, Vector2((size.x - w) * 0.5, size.y * 0.76), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)


## Значки над тем, с чем можно взаимодействовать: маленький — «тут что-то есть», большой жёлтый — «жми сейчас».
class Marks:
	extends Control
	var items: Array = []

	func _draw() -> void:
		var f := UI.font_bold()
		var pulse := sin(Time.get_ticks_msec() * 0.008) * 1.6
		for it in items:
			var c: Vector2 = it["pos"]
			var on: bool = it["on"]
			var a: float = it["a"]
			var r := (17.0 + pulse) if on else 10.5
			if on:
				draw_arc(c, r + 5.5, 0, TAU, 28, Color(1.0, 0.85, 0.2, 0.42 * a), 2.5, true)
			draw_circle(c, r + 3.0, Color(0, 0, 0, 0.52 * a))
			draw_circle(c, r, Color(1.0, 0.82, 0.12, a) if on else Color(0.1, 0.1, 0.13, 0.85 * a))
			draw_arc(c, r, 0, TAU, 28, Color(1.0, 0.82, 0.12, a), 2.0, true)
			var t: String = it["key"]
			var fs := 20 if on else 12
			var w := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			draw_string(f, c + Vector2(-w * 0.5, fs * 0.36), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.07, 0.07, 0.09, a) if on else Color(1, 1, 1, a))

	func _process(_dt: float) -> void:
		if not items.is_empty():
			queue_redraw()


func _bar(pos: Vector2, sz: Vector2, col: Color, r := 8) -> Bar:
	var b := Bar.new()
	b.position = pos
	b.size = sz
	b.col = col
	b.radius = r
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(b)
	return b


func _ready() -> void:
	# именно «…and_offsets»: узел уже в дереве, и set_anchors_preset оставил бы ему прежний нулевой размер —
	# тогда всё, что привязано к правому и нижнему краю (цель, подсказки, полоса босса, сенсорные кнопки), уезжает за экран
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# портрет
	var pf := Panel.new()
	pf.position = Vector2(22, 18)
	pf.size = Vector2(84, 84)
	pf.add_theme_stylebox_override("panel", UI.sb(UI.Y, 42))
	pf.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pf)
	var face := TextureRect.new()
	face.position = Vector2(4, 4)
	face.size = Vector2(76, 76)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists("res://assets/faces/ch.jpg"):
		face.texture = load("res://assets/faces/ch.jpg")
	face.material = UI.round_mat()
	pf.add_child(face)
	hp_bar = _bar(Vector2(118, 22), Vector2(300, 26), Color(0.9, 0.22, 0.2), 10)
	st_bar = _bar(Vector2(118, 54), Vector2(190, 12), Color(0.3, 0.85, 0.35), 6)
	rage_bar = _bar(Vector2(118, 72), Vector2(150, 12), Color(1.0, 0.82, 0.12), 6)
	spray_bar = _bar(Vector2(274, 72), Vector2(110, 12), Color(0.45, 0.85, 1.0), 6)
	money_lbl = UI.label("₽ 0", 26, Color(0.65, 1.0, 0.6))
	money_lbl.add_theme_font_override("font", UI.font_bold())
	money_lbl.position = Vector2(120, 92)
	add_child(money_lbl)
	food_lbl = UI.label("", 18, Color(1, 1, 1, 0.85))
	food_lbl.position = Vector2(250, 98)
	add_child(food_lbl)
	# цель
	goal_box = PanelContainer.new()
	goal_box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	goal_box.custom_minimum_size = Vector2(360, 0)
	goal_box.position = Vector2(-382, 18)
	var gsb := UI.sb(Color(0.05, 0.05, 0.08, 0.84), 8, UI.Y, 0, 12)
	gsb.border_width_left = 5
	gsb.border_color = UI.Y
	goal_box.add_theme_stylebox_override("panel", gsb)
	goal_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(goal_box)
	var gv := VBoxContainer.new()
	gv.add_theme_constant_override("separation", 2)
	goal_box.add_child(gv)
	gv.add_child(UI.label("ЦЕЛЬ", 15, UI.Y, true))
	goal_lbl = UI.label("", 19)
	goal_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	goal_lbl.custom_minimum_size = Vector2(330, 0)
	gv.add_child(goal_lbl)
	goal_box.visible = false
	# метка цели
	marker = Control.new()
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.visible = false
	add_child(marker)
	var dia := Polygon2D.new()
	dia.polygon = PackedVector2Array([Vector2(0, -15), Vector2(12, 0), Vector2(0, 15), Vector2(-12, 0)])
	dia.color = UI.Y
	marker.add_child(dia)
	var dia2 := Polygon2D.new()
	dia2.polygon = PackedVector2Array([Vector2(0, -7), Vector2(5.5, 0), Vector2(0, 7), Vector2(-5.5, 0)])
	dia2.color = Color(0.1, 0.1, 0.12)
	marker.add_child(dia2)
	marker_lbl = UI.label("", 16, Color.WHITE)
	marker_lbl.add_theme_font_override("font", UI.font_bold())
	marker_lbl.position = Vector2(-40, 16)
	marker_lbl.custom_minimum_size = Vector2(80, 0)
	marker_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	marker.add_child(marker_lbl)
	# значки над предметами и людьми, с которыми можно взаимодействовать
	marks = Marks.new()
	marks.set_anchors_preset(Control.PRESET_FULL_RECT)
	marks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(marks)
	# обучение: текущий шаг
	tutor_box = PanelContainer.new()
	tutor_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	tutor_box.position = Vector2(-300, 100)
	tutor_box.custom_minimum_size = Vector2(600, 0)
	tutor_box.add_theme_stylebox_override("panel", UI.sb(Color(0.05, 0.05, 0.08, 0.92), 12, UI.Y, 2, 14))
	tutor_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 6)
	tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tutor_box.add_child(tv)
	tutor_title = UI.label("", 15, UI.Y, true)
	tutor_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tv.add_child(tutor_title)
	tutor_text = RichTextLabel.new()
	tutor_text.bbcode_enabled = true
	tutor_text.fit_content = true
	tutor_text.scroll_active = false
	tutor_text.custom_minimum_size = Vector2(570, 0)
	tutor_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tutor_text.add_theme_font_override("normal_font", UI.font_text())
	tutor_text.add_theme_font_override("bold_font", UI.font_bold())
	tutor_text.add_theme_font_size_override("normal_font_size", 23)
	tutor_text.add_theme_font_size_override("bold_font_size", 23)
	tv.add_child(tutor_text)
	tutor_bar = Bar.new()
	tutor_bar.custom_minimum_size = Vector2(570, 8)
	tutor_bar.col = Color(0.35, 0.9, 0.45)
	tutor_bar.radius = 4
	tutor_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tv.add_child(tutor_bar)
	tutor_hint = UI.label("", 13, Color(1, 1, 1, 0.55))
	tutor_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tv.add_child(tutor_hint)
	tutor_box.visible = false
	add_child(tutor_box)
	# подсказка действия
	prompt = PanelContainer.new()
	prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt.position = Vector2(-150, -150)
	prompt.custom_minimum_size = Vector2(300, 0)
	prompt.add_theme_stylebox_override("panel", UI.sb(Color(0.05, 0.05, 0.08, 0.86), 10, UI.Y, 2, 10))
	prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_lbl = UI.label("", 22, Color.WHITE, true)
	prompt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_child(prompt_lbl)
	prompt.visible = false
	add_child(prompt)
	# босс
	boss_box = VBoxContainer.new()
	boss_box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	boss_box.position = Vector2(-330, -92)
	boss_box.custom_minimum_size = Vector2(660, 0)
	boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_lbl = UI.label("", 26, Color.WHITE, true)
	boss_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_box.add_child(boss_lbl)
	boss_bar = Bar.new()
	boss_bar.custom_minimum_size = Vector2(660, 20)
	boss_bar.col = Color(0.88, 0.16, 0.3)
	boss_bar.radius = 8
	boss_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_box.add_child(boss_bar)
	boss_box.visible = false
	add_child(boss_box)
	# подсказки по управлению
	hints = UI.label("", 15, Color(1, 1, 1, 0.62))
	hints.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	hints.position = Vector2(20, -50)
	hints.custom_minimum_size = Vector2(700, 0)
	hints.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hints.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(hints)
	flash = ColorRect.new()
	flash.color = Color(0.9, 0.05, 0.05, 0.0)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	fps_lbl = UI.label("", 14, Color(1, 1, 1, 0.6))
	fps_lbl.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	fps_lbl.position = Vector2(-90, -24)
	add_child(fps_lbl)
	refresh_hints()


func refresh_hints() -> void:
	if hints == null:
		return
	if G.touch:
		hints.text = ""
		return
	var parts := ["%s — удар" % Inp.hint("attack"), "%s — прыжок" % Inp.hint("jump"), "%s — перекат" % Inp.hint("dodge"), "%s — бросок" % Inp.hint("throw"), "%s — бег" % Inp.hint("sprint"), "%s — действие" % Inp.hint("interact")]
	if G.has("spray"):
		parts.append("%s — дихлофос" % Inp.hint("gadget"))
	if G.has("am"):
		parts.append("%s — ульта" % Inp.hint("ult"))
	parts.append("%s — еда" % Inp.hint("item"))
	hints.text = " · ".join(parts)


func set_goal(text: String, pos: Variant = null) -> void:
	goal_lbl.text = text
	goal_box.visible = text != ""
	goal_pos = pos


func set_boss(b: Enemy) -> void:
	boss = b
	boss_box.visible = b != null and G.mode == "play"
	if b:
		boss_lbl.text = b.title.to_upper()
		boss_bar.ghost = 1.0
	hints.visible = b == null and G.mode == "play" and not G.ui.dlg.visible


func set_prompt_visible(v: bool) -> void:
	_prompt_ok = v


## Панель обучения: заголовок («ОБУЧЕНИЕ · 2/8»), текст шага (BBCode), доля пройденного.
func tutor_show(title: String, bb: String, k: float) -> void:
	tutor_title.text = title
	var t := "[center]%s[/center]" % bb
	if tutor_text.text != t:
		tutor_text.text = t
	tutor_bar.set_v(k)
	if tutor_hint:
		tutor_hint.text = "Пауза (%s) — пропустить обучение" % Inp.hint("pause")
	tutor_box.visible = true


func tutor_hide() -> void:
	tutor_box.visible = false


## Шаг засчитан: зелёная вспышка рамки.
func tutor_ok() -> void:
	if _tutor_tw:
		_tutor_tw.kill()
	tutor_box.modulate = Color(0.55, 1.0, 0.6)
	_tutor_tw = create_tween()
	_tutor_tw.tween_property(tutor_box, "modulate", Color.WHITE, 0.4)


func money_pop(n: int) -> void:
	money_lbl.pivot_offset = Vector2(20, 16)
	var tw := money_lbl.create_tween()
	tw.tween_property(money_lbl, "scale", Vector2(1.25, 1.25), 0.07)
	tw.tween_property(money_lbl, "scale", Vector2.ONE, 0.15)
	if n >= 10:
		G.ui.toast("+ ₽ %d" % n, "small")


func damage_flash() -> void:
	flash.color.a = 0.28
	create_tween().tween_property(flash, "color:a", 0.0, 0.35)


## Значки над всем, с чем можно взаимодействовать, в нескольких шагах от героя.
func _update_marks(p: Player, prompt_on: bool) -> void:
	var list: Array = []
	var cam: Camera3D = G.cam.active() if G.cam else null
	if cam and G.level and G.mode == "play":
		var key := "!" if G.touch else Inp.hint("interact")
		var space := p.get_world_3d().direct_space_state
		var cp := cam.global_position
		for it in G.level.inter:
			if it["off"] or (it.has("node") and not is_instance_valid(it["node"])):
				continue
			var ip: Vector3 = it["pos"]
			var d := ip.distance_to(p.global_position + Vector3(0, 0.9, 0))
			var far: float = maxf(6.5, float(it["r"]) * 2.6)
			if d > far or cam.is_position_behind(ip):
				continue
			if it.has("cond") and not it["cond"].call():
				continue
			var on: bool = prompt_on and p.near == it
			# сквозь стену значок не показываем (кроме того, с чем уже можно работать)
			if not on:
				var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(cp, ip, 1))
				if not hit.is_empty():
					var hitp: Vector3 = hit["position"]
					if hitp.distance_to(ip) > 0.6:
						continue
			list.append({"pos": cam.unproject_position(ip + Vector3(0, 0.35 if it.has("node") else 0.0, 0)), "on": on, "a": clampf((far - d) / 1.5, 0.0, 1.0), "key": key})
	if list.is_empty() and marks.items.is_empty():
		return
	marks.items = list
	marks.queue_redraw()


func _process(_dt: float) -> void:
	var p := G.player
	if p == null or not visible:
		return
	hp_bar.set_v(p.hp / p.hp_max, "%d / %d" % [int(ceil(p.hp)), int(p.hp_max)])
	hp_bar.size.x = 300.0 + (p.hp_max - 100.0) * 0.9
	st_bar.set_v(p.st / 100.0)
	st_bar.col = Color(0.85, 0.5, 0.2) if p.exhausted else (Color(0.3, 0.95, 0.9) if p.buff_t > 0.0 else Color(0.3, 0.85, 0.35))
	rage_bar.visible = G.has("am")
	rage_bar.set_v(p.rage / 100.0)
	rage_bar.col = Color(1.0, 0.82, 0.12) if p.rage < 100.0 else Color(1.0, 0.55 + 0.4 * absf(sin(Time.get_ticks_msec() * 0.008)), 0.1)
	spray_bar.visible = G.has("spray")
	spray_bar.set_v(p.spray)
	var m := G.money()
	if m != _money_shown:
		_money_shown = m
		money_lbl.text = "₽ %d" % m
	var fc := p.food_count()
	food_lbl.text = ("еда ×%d  [%s]" % [fc, Inp.hint("item")]) if fc > 0 and not G.touch else ("еда ×%d" % fc if fc > 0 else "")
	# подсказка действия
	var show_prompt := _prompt_ok and G.mode == "play" and p.near != null
	_prompt_ok = true
	prompt.visible = show_prompt
	if show_prompt:
		var lab := String(p.near["label"])
		if lab == "Поговорить" and p.near.has("node") and p.near["node"] is Npc:
			var nm := String((p.near["node"] as Npc).cname)
			if nm != "":
				lab = "Поговорить · " + nm
		prompt_lbl.text = lab if G.touch else "[%s]  %s" % [Inp.hint("interact"), lab]
	_update_marks(p, show_prompt)
	hints.visible = boss == null and G.mode == "play" and not G.ui.dlg.visible
	# босс
	if boss != null:
		if not is_instance_valid(boss) or boss.dead:
			set_boss(null)
		else:
			boss_box.visible = G.mode == "play"
			boss_bar.set_v(boss.hp / boss.hp_max)
	# метка цели
	var cam: Camera3D = G.cam.active() if G.cam else null
	if goal_pos != null and cam and G.mode == "play" and G.has("phone"):
		var gp: Vector3 = goal_pos
		var d := gp.distance_to(p.global_position)
		var vs := get_viewport_rect().size
		var sp := cam.unproject_position(gp + Vector3(0, 1.2, 0))
		var behind := cam.is_position_behind(gp)
		if behind:
			sp = vs - sp
			sp.y = vs.y - 60.0
		sp.x = clampf(sp.x, 40.0, vs.x - 40.0)
		sp.y = clampf(sp.y, 150.0, vs.y - 130.0)
		marker.visible = d > 3.0
		marker.position = sp
		marker_lbl.text = "%d м" % int(d)
	else:
		marker.visible = false
	if G.settings.get("fps", false) or G.opts.has("fps"):
		fps_lbl.text = "%d к/с" % Engine.get_frames_per_second()
	else:
		fps_lbl.text = ""
