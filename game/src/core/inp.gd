extends Node
## Ввод: действия регистрируются кодом (клавиатура, мышь, геймпад), сенсорный слой пишет сюда стик и поворот камеры.

const KEYS := {
	"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT], "move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN],
	"jump": [KEY_SPACE], "sprint": [KEY_SHIFT], "attack": [KEY_J], "throw": [KEY_F, KEY_K], "dodge": [KEY_C, KEY_L],
	"interact": [KEY_E, KEY_ENTER], "gadget": [KEY_Q], "ult": [KEY_R], "item": [KEY_1], "inv": [KEY_TAB, KEY_I], "pause": [KEY_ESCAPE, KEY_P],
}
const MOUSE := {"attack": MOUSE_BUTTON_LEFT, "throw": MOUSE_BUTTON_RIGHT, "dodge": MOUSE_BUTTON_MIDDLE}
const PAD := {
	"jump": JOY_BUTTON_A, "dodge": JOY_BUTTON_B, "attack": JOY_BUTTON_X, "interact": JOY_BUTTON_Y, "gadget": JOY_BUTTON_LEFT_SHOULDER,
	"throw": JOY_BUTTON_RIGHT_SHOULDER, "sprint": JOY_BUTTON_LEFT_STICK, "pause": JOY_BUTTON_START, "inv": JOY_BUTTON_BACK, "item": JOY_BUTTON_DPAD_UP,
}
const PAD_AXIS := {"move_left": [JOY_AXIS_LEFT_X, -1.0], "move_right": [JOY_AXIS_LEFT_X, 1.0], "move_up": [JOY_AXIS_LEFT_Y, -1.0], "move_down": [JOY_AXIS_LEFT_Y, 1.0], "ult": [JOY_AXIS_TRIGGER_RIGHT, 1.0]}

var touch_move := Vector2.ZERO      # стик сенсорного слоя (-1..1), y вниз
var touch_run := false
var look := Vector2.ZERO            # накопленный поворот камеры за кадр (мышь/тач), пиксели
var last_device := "kbm"            # kbm, pad, touch — для подсказок
var _virtual := {}                  # действия, зажатые тестом или сенсорной кнопкой


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for a in KEYS:
		_add(a)
		for k in KEYS[a]:
			var e := InputEventKey.new()
			e.physical_keycode = k
			InputMap.action_add_event(a, e)
	for a in MOUSE:
		_add(a)
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE[a]
		InputMap.action_add_event(a, e)
	for a in PAD:
		_add(a)
		var e := InputEventJoypadButton.new()
		e.button_index = PAD[a]
		InputMap.action_add_event(a, e)
	for a in PAD_AXIS:
		_add(a)
		var e := InputEventJoypadMotion.new()
		e.axis = PAD_AXIS[a][0]
		e.axis_value = PAD_AXIS[a][1]
		InputMap.action_add_event(a, e)


func _add(a: String) -> void:
	if not InputMap.has_action(a):
		InputMap.add_action(a, 0.3)


func _input(e: InputEvent) -> void:
	if e is InputEventJoypadButton or (e is InputEventJoypadMotion and absf((e as InputEventJoypadMotion).axis_value) > 0.5):
		last_device = "pad"
	elif e is InputEventScreenTouch:
		last_device = "touch"
	elif e is InputEventKey or (e is InputEventMouseButton and not G.touch):
		last_device = "kbm"


## Вектор движения: x — вправо, y — вперёд (-1..1).
func move() -> Vector2:
	var v := Vector2(Input.get_action_strength("move_right") - Input.get_action_strength("move_left"), Input.get_action_strength("move_up") - Input.get_action_strength("move_down"))
	v += Vector2(touch_move.x, -touch_move.y)
	return v.limit_length(1.0)


func stick_look() -> Vector2:
	var v := Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
	return v if v.length() > 0.18 else Vector2.ZERO


func hit(a: String) -> bool:
	return Input.is_action_just_pressed(a)


func down(a: String) -> bool:
	return Input.is_action_pressed(a)


## Нажатие «кодом» (сенсорные кнопки, тесты).
func press(a: String) -> void:
	Input.action_press(a)
	_virtual[a] = true


func release(a: String) -> void:
	Input.action_release(a)
	_virtual.erase(a)


func tap(a: String) -> void:
	press(a)
	await get_tree().physics_frame
	await get_tree().physics_frame
	release(a)


func release_all() -> void:
	for a in _virtual.keys():
		Input.action_release(a)
	_virtual.clear()
	touch_move = Vector2.ZERO


## Подсказка по управлению под текущее устройство.
func hint(a: String) -> String:
	if last_device == "touch" or G.touch:
		return {"attack": "УДАР", "jump": "ПРЫЖОК", "dodge": "ПЕРЕКАТ", "throw": "БРОСОК", "interact": "ДЕЙСТВИЕ", "gadget": "ПШИК", "ult": "АМ!", "item": "ЕДА", "sprint": "стик до упора", "inv": "РЮКЗАК", "pause": "ПАУЗА"}.get(a, a)
	if last_device == "pad":
		return {"attack": "X", "jump": "A", "dodge": "B", "throw": "RB", "interact": "Y", "gadget": "LB", "ult": "RT", "item": "крестовина вверх", "sprint": "L3", "inv": "Back", "pause": "Start"}.get(a, a)
	return {"attack": "ЛКМ", "jump": "Пробел", "dodge": "C", "throw": "ПКМ", "interact": "E", "gadget": "Q", "ult": "R", "item": "1", "sprint": "Shift", "inv": "Tab", "pause": "Esc"}.get(a, a)
