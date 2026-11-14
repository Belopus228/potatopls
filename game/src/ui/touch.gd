class_name TouchPad
extends Control
## Сенсорное управление: слева — стик (до упора — бег), справа — камера и кнопки.
## Мультитач обрабатывается вручную: каждая кнопка держит свой палец.

const BTN := [
	# действие, подпись, смещение от правого нижнего угла, радиус
	["attack", "УДАР", Vector2(-110, -120), 58.0],
	["jump", "ПРЫЖОК", Vector2(-230, -70), 46.0],
	["dodge", "КАТ", Vector2(-60, -235), 44.0],
	["throw", "₽", Vector2(-175, -215), 40.0],
	["interact", "E", Vector2(-290, -165), 40.0],
	["gadget", "ПШИК", Vector2(-270, -265), 38.0],
	["ult", "АМ!", Vector2(-150, -310), 40.0],
	["item", "ЕДА", Vector2(-380, -70), 36.0],
]
const TOP := [["pause", "II", Vector2(-50, 150), 28.0], ["inv", "РЮКЗАК", Vector2(-130, 150), 34.0]]

var stick_id := -1
var stick_origin := Vector2.ZERO
var stick_pos := Vector2.ZERO
var look_id := -1
var held := {}                    # палец -> действие


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS


func _btn_pos(b: Array) -> Vector2:
	var off: Vector2 = b[2]
	return Vector2(size.x + off.x, (size.y + off.y) if off.y < 0 else off.y)


func _visible_btn(a: String) -> bool:
	if a == "gadget":
		return G.has("spray")
	if a == "ult":
		return G.has("am")
	if a == "interact":
		return G.player != null and G.player.near != null
	if a == "item":
		return G.player != null and G.player.food_count() > 0
	return true


func _hit_btn(p: Vector2) -> String:
	for b in BTN + TOP:
		if _visible_btn(b[0]) and p.distance_to(_btn_pos(b)) < float(b[3]) + 10.0:
			return b[0]
	return ""


func _input(e: InputEvent) -> void:
	if not visible or not G.touch:
		return
	if G.mode != "play":
		if not held.is_empty() or stick_id >= 0:
			_reset()
		return
	if e is InputEventScreenTouch:
		var t := e as InputEventScreenTouch
		var p: Vector2 = get_global_transform().affine_inverse() * t.position
		if t.pressed:
			var a := _hit_btn(p)
			if a != "":
				held[t.index] = a
				Inp.press(a)
			elif p.x < size.x * 0.45 and stick_id < 0:
				stick_id = t.index
				stick_origin = p
				stick_pos = p
			elif look_id < 0:
				look_id = t.index
		else:
			if held.has(t.index):
				Inp.release(held[t.index])
				held.erase(t.index)
			if t.index == stick_id:
				stick_id = -1
				Inp.touch_move = Vector2.ZERO
				Inp.touch_run = false
			if t.index == look_id:
				look_id = -1
		queue_redraw()
	elif e is InputEventScreenDrag:
		var d := e as InputEventScreenDrag
		if d.index == stick_id:
			stick_pos = get_global_transform().affine_inverse() * d.position
			var v := (stick_pos - stick_origin) / 80.0
			Inp.touch_run = v.length() > 0.95
			Inp.touch_move = v.limit_length(1.0)
			queue_redraw()
		elif d.index == look_id:
			Inp.look += d.relative * 1.6


func _reset() -> void:
	for id in held:
		Inp.release(held[id])
	held.clear()
	stick_id = -1
	look_id = -1
	Inp.touch_move = Vector2.ZERO
	Inp.touch_run = false
	queue_redraw()


func _process(_dt: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	if not G.touch or G.mode != "play":
		return
	var f := UI.font_big()
	# стик
	var base := stick_origin if stick_id >= 0 else Vector2(150, size.y - 150)
	draw_circle(base, 78.0, Color(1, 1, 1, 0.08))
	draw_arc(base, 78.0, 0, TAU, 40, Color(1, 1, 1, 0.3), 3.0, true)
	var knob := base + ((stick_pos - stick_origin).limit_length(80.0) if stick_id >= 0 else Vector2.ZERO)
	draw_circle(knob, 34.0, Color(1.0, 0.82, 0.12, 0.75 if Inp.touch_run else 0.45))
	for b in BTN + TOP:
		var a: String = b[0]
		if not _visible_btn(a):
			continue
		var c := _btn_pos(b)
		var r: float = b[3]
		var on := held.values().has(a)
		var ready := true
		if a == "ult" and G.player:
			ready = G.player.rage >= 100.0
		draw_circle(c, r, Color(1.0, 0.82, 0.12, 0.85) if on else Color(0.05, 0.05, 0.08, 0.55 if ready else 0.3))
		draw_arc(c, r, 0, TAU, 36, Color(1.0, 0.82, 0.12, 0.9 if ready else 0.3), 3.0, true)
		var txt: String = b[1]
		var fs := int(clampf(r * 0.5, 13.0, 26.0)) if txt.length() > 2 else int(r * 0.8)
		if txt.length() > 4:
			fs = int(r * 0.36)
		var use_f: Font = UI.font_bold() if txt == "₽" else f
		var w := use_f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(use_f, c + Vector2(-w * 0.5, fs * 0.36), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.07, 0.07, 0.09) if on else Color(1, 1, 1, 0.95 if ready else 0.4))
