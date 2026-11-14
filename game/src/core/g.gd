extends Node
## Глобальное состояние: сохранение, флаги, инвентарь, деньги, смена уровней и режимов игры.

signal mode_changed(m: String)

const SAVE_PATH := "user://save.json"
const SET_PATH := "user://settings.json"
const VERSION := "2.0"

## boot — запуск, menu — главное меню, play — игра, cut — сценка/диалог, pause — пауза, panel — окно (магазин, головоломка), dead — экран поражения
var mode := "boot"
var main: Node
var world: Node3D
var level: Level
var player: Player
var cam: CamRig
var ui: UI
var opts := {}                 # параметры запуска: --lv=murino --cp=roof --god  (в браузере: ?lv=murino&cp=roof&god)
var save := {}
var settings := {"q": -1, "sens": 1.0, "inv_y": false, "music": 0.7, "sfx": 0.9, "shake": true, "touch": -1, "fps": false}
var in_script := 0
var touch := false
var web := false
var mobile := false
var loading := false
var ents: Array = []           # существа, которых можно бить
var breakables: Array = []     # ящики
var quality := 2


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	web = OS.has_feature("web")
	mobile = OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")
	_parse_opts()
	load_settings()
	touch = (mobile or DisplayServer.is_touchscreen_available()) if int(settings["touch"]) < 0 else int(settings["touch"]) == 1
	if opts.has("touch"):
		touch = true
	save = new_save()
	load_save()


func _parse_opts() -> void:
	var parts: PackedStringArray = OS.get_cmdline_user_args()
	if web:
		var q := str(JavaScriptBridge.eval("location.search", true))
		parts = q.trim_prefix("?").split("&", false)
	for raw in parts:
		var kv := raw.trim_prefix("--")
		var i := kv.find("=")
		if i < 0:
			opts[kv] = "1"
		else:
			opts[kv.substr(0, i)] = kv.substr(i + 1).uri_decode()


# ---------- сохранение ----------

func new_save() -> Dictionary:
	return {"v": 2, "lv": "", "cp": "start", "flags": {}, "inv": {}, "money": 0, "hp": 100.0, "time": 0.0, "kills": 0, "deaths": 0, "earned": 0, "skin": "casual", "done": []}


func has_save() -> bool:
	return String(save.get("lv", "")) != ""


func load_save() -> void:
	if opts.has("nosave") or not FileAccess.file_exists(SAVE_PATH):
		return
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if d is Dictionary and int(d.get("v", 0)) == 2:
		var base := new_save()
		for k in d:
			base[k] = d[k]
		save = base


func write_save() -> void:
	if opts.has("nosave"):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(save))
		f.close()


func load_settings() -> void:
	if FileAccess.file_exists(SET_PATH) and not opts.has("nosave"):
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(SET_PATH))
		if d is Dictionary:
			for k in d:
				settings[k] = d[k]
	quality = int(settings["q"])
	if quality < 0:
		quality = 0 if mobile else (1 if web else 2)
	if opts.has("q"):
		quality = clampi(int(opts["q"]), 0, 2)


func write_settings() -> void:
	if opts.has("nosave"):
		return
	var f := FileAccess.open(SET_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(settings))
		f.close()


func apply_settings() -> void:
	Snd.set_volumes(float(settings["music"]), float(settings["sfx"]))
	var vp := get_viewport()
	vp.msaa_3d = [Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X][quality]
	vp.scaling_3d_scale = [0.7, 0.9, 1.0][quality]
	if level:
		level.apply_quality()
	if ui:
		ui.apply_settings()


# ---------- флаги, вещи, деньги ----------

func flag(k: String) -> bool:
	return bool(save["flags"].get(k, false))


func set_flag(k: String, v := true) -> void:
	save["flags"][k] = v


func count(id: String) -> int:
	return int(save["inv"].get(id, 0))


func has(id: String) -> bool:
	return count(id) > 0


func give(id: String, n := 1, quiet := false) -> void:
	save["inv"][id] = count(id) + n
	var d: Dictionary = Items.DEFS.get(id, {})
	if id == "tasty" and player:
		player.hp = minf(player.hp + 20.0, max_hp())
	if not quiet and ui:
		var txt := String(d.get("name", id))
		if n > 1:
			txt += " ×%d" % n
		ui.toast("+ " + txt, "item", String(d.get("desc", "")) if d.get("kind", "") != "food" else "")
		Snd.sfx("item")


func take(id: String, n := 1) -> bool:
	if count(id) < n:
		return false
	save["inv"][id] = count(id) - n
	if int(save["inv"][id]) <= 0:
		save["inv"].erase(id)
	return true


func money() -> int:
	return int(save["money"])


func pay(n: int) -> void:
	save["money"] = money() + n
	save["earned"] = int(save["earned"]) + n
	if ui:
		ui.hud.money_pop(n)


func spend(n: int) -> bool:
	if money() < n:
		return false
	save["money"] = money() - n
	return true


func max_hp() -> float:
	return 100.0 + 20.0 * count("tasty")


func dmg_mult() -> float:
	return 1.0 + 0.25 * count("chain")


# ---------- режимы ----------

func set_mode(m: String) -> void:
	if mode == m:
		return
	mode = m
	get_tree().paused = (m == "pause")
	_update_mouse()
	mode_changed.emit(m)


func _update_mouse() -> void:
	if touch:
		return
	if mode == "play" or (mode == "cut" and not ui.wants_mouse()):
		if not web:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _input(e: InputEvent) -> void:
	# в браузере захват мыши возможен только из обработчика нажатия
	if web and not touch and mode == "play" and e is InputEventMouseButton and e.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func cut_begin() -> void:
	in_script += 1
	if mode == "play":
		set_mode("cut")


func cut_end() -> void:
	in_script = maxi(0, in_script - 1)
	if in_script == 0 and mode == "cut":
		set_mode("play")


func wait(t: float) -> void:
	await get_tree().create_timer(t, false).timeout


func frames(n := 1) -> void:
	for i in n:
		await get_tree().physics_frame


func playing() -> bool:
	return mode == "play"


# ---------- уровни ----------

func boot() -> void:
	apply_settings()
	if opts.has("skip"):
		ui.auto_skip = true
	if opts.has("test"):
		T.run_test(String(opts["test"]))
		return
	if opts.has("lv"):
		if not has_save() or opts.has("fresh"):
			save = new_save()
		go(String(opts["lv"]), String(opts.get("cp", "start")))
	else:
		go("menu")


func new_game() -> void:
	save = new_save()
	go("dorm", "start")


func continue_game() -> void:
	go(String(save["lv"]), String(save["cp"]))


func go(lv: String, cp := "start") -> void:
	if loading:
		return
	loading = true
	mode = "cut"
	get_tree().paused = false
	_update_mouse()
	mode_changed.emit(mode)
	Inp.release_all()
	in_script = 0
	await ui.fade_to(1.0, 0.3, true)
	ui.close_all()
	if level:
		level.queue_free()
		level = null
	for e in ents.duplicate():
		if is_instance_valid(e):
			e.queue_free()
	ents.clear()
	breakables.clear()
	await get_tree().process_frame
	await get_tree().process_frame
	var lvl: Level = (load("res://src/levels/%s.gd" % lv) as GDScript).new()
	lvl.id = lv
	lvl.name = "Level_" + lv
	world.add_child(lvl)
	level = lvl
	ui.hud.visible = lv != "menu"
	ui.hud.set_goal("", null)
	ui.hud.set_boss(null)
	lvl.setup()
	var c: Array = lvl.cps.get(cp, lvl.cps.get("start", [Vector3.ZERO, 0.0]))
	player.revive()
	player.place(c[0], c[1])
	if save.has("hp_keep") and lv != "menu":
		player.hp = clampf(float(save["hp_keep"]), 20.0, max_hp())
		save.erase("hp_keep")
	cam.snap()
	if lv != "menu":
		save["lv"] = lv
		save["cp"] = cp if lvl.cps.has(cp) else "start"
		write_save()
	Snd.music(lvl.music)
	await get_tree().process_frame
	await get_tree().process_frame
	await ui.fade_to(0.0, 0.4)
	loading = false
	set_mode("menu" if lv == "menu" else "play")
	lvl.begin(cp)


## Переезд между уровнями с сохранением здоровья.
func travel(lv: String, cp := "start") -> void:
	save["hp_keep"] = player.hp
	go(lv, cp)


func checkpoint(cp: String, quiet := false) -> void:
	if level == null or level.id == "menu":
		return
	save["lv"] = level.id
	save["cp"] = cp
	write_save()
	if not quiet:
		ui.toast("Сохранено", "small")


func on_player_dead() -> void:
	save["deaths"] = int(save["deaths"]) + 1
	Snd.music("")
	Snd.sfx("lose")
	await wait(1.6)
	if player.dead and not loading:
		set_mode("dead")
		ui.show_death()


func retry() -> void:
	go(String(save["lv"]), String(save["cp"]))


func _process(dt: float) -> void:
	if mode == "play" or mode == "cut":
		save["time"] = float(save["time"]) + dt


func toast(t: String, kind := "", sub := "") -> void:
	if ui:
		ui.toast(t, kind, sub)


func goal(t: String, pos: Variant = null) -> void:
	if ui:
		ui.hud.set_goal(t, pos)


func fmt_time(sec: float) -> String:
	var s := int(sec)
	return "%02d:%02d" % [s / 60, s % 60] if s < 3600 else "%d:%02d:%02d" % [s / 3600, (s / 60) % 60, s % 60]
