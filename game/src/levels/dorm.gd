extends Level
## ГЛАВА 1 — ОБЩАГА. Звонок Друна, вахтёрша, записка коменданта, три цифры на стенах,
## подвал с кодовым замком и Крысиный Король.

const RX := [-21.0, -13.0, -5.0, 3.0, 11.0, 19.0]      # центры комнат по X (комнаты 8×6)
const WALL := ["plaster_green", "plaster", 1.3]
const GRAFFITI := [
	["ЧТО ЗА\nБИЗНЕС?", Color(1.0, 0.82, 0.12)], ["АМ АМ\nАМ", Color(1.0, 0.35, 0.3)], ["ХАМАМ", Color(0.45, 0.85, 1.0)], ["Я ПОМЫЛСЯ", Color(0.6, 1.0, 0.7)],
	["СЛИВЫ!", Color(0.8, 0.5, 1.0)], ["ПОСИДИМ", Color(1.0, 0.7, 0.4)], ["СКОЛЬКО-\nСКОЛЬКО?", Color(1.0, 0.82, 0.12)], ["ПЛАКИ-\nПЛАКИ", Color(0.6, 0.8, 1.0)],
	["БУРМАЛДА", Color(1.0, 0.4, 0.7)], ["ДАЙ ХОТЯ\nБЫ ХЛЕБА", Color(0.9, 0.9, 0.9)], ["МУРИНО —\nЭТО НЕ\nЖМУРИНО!", Color(0.4, 0.9, 1.0)], ["ФОГ\nИДЁТ", Color(0.8, 0.85, 0.95)],
]

var code := ""
var base_door: Door
var exit_door: Door
var boss: RatKing
var gate: CollisionShape3D
var bral: Npc
var vaht: Npc
var hinted_fight := false
var digit_pos: Array = []          # где нарисованы цифры кода (для проверки, что их ничто не закрывает)


func build() -> void:
	title = "ОБЩАГА"
	chapter = "ГЛАВА 1"
	music = "dorm"
	set_env("indoor")
	if not G.save["flags"].has("dorm_code"):
		var digs := [1, 2, 3, 4, 5, 6, 7, 8, 9]
		digs.shuffle()
		G.save["flags"]["dorm_code"] = "%d%d%d" % [digs[0], digs[1], digs[2]]
	code = String(G.save["flags"]["dorm_code"])
	_shell()
	_rooms()
	_basement()
	_people()
	cp("start", Vector3(-22.4, 0.05, -4.2), 180)
	cp("base", Vector3(19, 0.05, 0.4), 180)
	cp("boss", Vector3(1.5, -3.95, 10), 90)
	cp("after", Vector3(-6, -3.95, 10), -90)


# ---------- коробка здания ----------

func _shell() -> void:
	# полы первого этажа (над подвалом — они же его потолок)
	slab(-29, -8, 27, 1.6, 0.0, "wood", 0.5)
	slab(-29, 1.6, 15, 8, 0.0, "wood", 0.5)
	slab(15, 1.6, 23, 3.4, 0.0, "wood", 0.5)
	slab(-28, -1.6, 26, 1.6, 0.012, "lino", 0.02, {"col": false})
	# коридор: стены с проёмами в комнаты
	var gn: Array = []
	for x in RX:
		gn.append([x + 25.0, 1.3])
	wall_gaps(-25, -1.6, 23, -1.6, 0, 3.0, WALL, gn)
	wall_gaps(-25, 1.6, 23, 1.6, 0, 3.0, WALL, gn)
	for x in [-25.0, -17.0, -9.0, -1.0, 7.0, 15.0, 23.0]:
		wall(x, -7.6, x, -1.6, 0, 3.0, WALL)
		if x < 15.0:
			wall(x, 1.6, x, 7.6, 0, 3.0, WALL)
	wall(-25, -7.6, 23, -7.6, 0, 3.0, WALL)
	wall(-25, 7.6, 15, 7.6, 0, 3.0, WALL)
	# западный тамбур с выходом
	wall(-28, -1.6, -25, -1.6, 0, 3.0, WALL)
	wall(-28, 1.6, -25, 1.6, 0, 3.0, WALL)
	wall_gaps(-28, -1.6, -28, 1.6, 0, 3.0, WALL, [[1.6, 1.5]])
	# восточный торец
	wall(23, -1.6, 26, -1.6, 0, 3.0, WALL)
	wall(23, 1.6, 26, 1.6, 0, 3.0, WALL)
	wall(26, -1.6, 26, 1.6, 0, 3.0, WALL)
	prop("home/Window_Large1", Vector3(25.85, 1.1, 0), -90)
	box(Vector3(25.9, 1.55, 0), Vector3(0.05, 0.8, 0.85), Mats.glow(Color(0.25, 0.35, 0.6), 1.2), {"col": false})
	# потолок (виден только изнутри)
	ceiling(-28, -7.6, 26, 7.6, 3.0)
	# свет в коридоре и номера комнат
	for i in 7:
		ceil_lamp(Vector3(-24.0 + i * 8.0, 3.0, 0), Color(1.0, 0.92, 0.75), 1.9, 8.5)
	var names := ["1 · Ч", "2 · БРАЛ", "3", "УМЫВАЛЬНАЯ", "5", "КЛАДОВКА"]
	var names_s := ["ВАХТА", "ЛАРЁК ТЕМЩИКА", "КАЧАЛКА", "ПОСИДИМ", "КУХНЯ", "ПОДВАЛ"]
	for i in 6:
		board(names[i], Vector3(RX[i], 2.5, -1.44), 0, 1.5 if names[i].length() > 3 else 0.7, 0.34, {"col": UI.Y})
		board(names_s[i], Vector3(RX[i], 2.5, 1.44), 180, 2.2 if names_s[i].length() > 8 else 1.5, 0.34, {"col": UI.Y})
	# надписи на стенах коридора
	var gi := 0
	for x in [-17.0, -9.0, -1.0, 7.0, 15.0]:
		var g1: Array = GRAFFITI[gi % GRAFFITI.size()]
		var g2: Array = GRAFFITI[(gi + 1) % GRAFFITI.size()]
		gi += 2
		txt(g1[0], Vector3(x, 1.75, -1.45), 0, 0.3, {"col": g1[1], "outline": 6})
		txt(g2[0], Vector3(x, 1.75, 1.45), 180, 0.3, {"col": g2[1], "outline": 6})
	txt(GRAFFITI[10][0], Vector3(-27.85, 2.45, 0), 90, 0.22, {"col": GRAFFITI[10][1], "outline": 6})
	txt(GRAFFITI[11][0], Vector3(25.8, 2.55, 0), -90, 0.3, {"col": GRAFFITI[11][1], "outline": 6})
	board("ВЫХОД", Vector3(-27.82, 2.72, 0), 90, 1.3, 0.34, {"col": Color(0.5, 1.0, 0.5), "glow": 1.0})


func _digit(n: int, pos: Vector3, yaw: float, col: Color) -> void:
	digit_pos.append(pos)
	txt(code[n], pos, yaw, 1.3, {"col": col, "outline": 14})
	txt("•".repeat(n + 1), pos + Vector3(0, -0.85, 0), yaw, 0.5, {"col": col, "outline": 10})


## win_dx — сдвиг окна вдоль дальней стены: в комнатах с цифрой окно уходит вбок, иначе рама закрывает цифру.
func _bedroom(cx: float, north: bool, variant: int, win_dx := 0.0) -> void:
	var s := -1.0 if north else 1.0             # к дальней стене
	var back := s * 7.6
	var ry := 0.0 if north else 180.0
	if variant == 0:
		prop("home/Bed_Single", Vector3(cx - 2.9, 0, s * 5.4), 0)
		prop("home/NightStand_1", Vector3(cx - 3.2, 0, s * 3.9), 0)
	else:
		prop("home/Bed_Bunk", Vector3(cx - 2.9, 0, s * 5.5), 0)
	prop("home/Table_RoundSmall", Vector3(cx + 2.4, 0, s * 6.3), 0)
	prop("home/Chair_1", Vector3(cx + 1.4, 0, s * 6.2), 90)
	prop("home/Drawer_1", Vector3(cx + 2.9, 0, s * 3.4), -90)
	prop("home/Carpet_1", Vector3(cx, 0.02, s * 4.6), 90)
	prop("home/Window_Small1", Vector3(cx + win_dx, 1.3, back - s * 0.16), ry)
	box(Vector3(cx + win_dx, 1.6, back - s * 0.14), Vector3(0.42, 0.55, 0.04), Mats.glow(Color(0.2, 0.3, 0.55), 1.0), {"col": false})
	ceil_lamp(Vector3(cx, 3.0, s * 4.6), Color(1.0, 0.88, 0.66), 1.8, 7.5)


func _rooms() -> void:
	# 1 — комната Ч
	_bedroom(-21, true, 0)
	txt("ЧТО ЗА\nБИЗНЕС?", Vector3(-24.84, 1.9, -4.6), 90, 0.32, {"col": UI.Y, "outline": 6})
	prop("home/Houseplant_8", Vector3(-17.6, 0, -2.3), 0)
	# 2 — Брал
	_bedroom(-13, true, 1)
	# 3 — первая цифра
	_bedroom(-5, true, 1, 2.5)
	_digit(0, Vector3(-5, 1.9, -7.44), 0, Color(1.0, 0.35, 0.3))
	enemy("rat", Vector3(-6.5, 0.2, -4.5))
	enemy("rat", Vector3(-3.5, 0.2, -5.5))
	# 4 — умывальная
	slab(-1, -7.6, 7, -1.6, 0.012, "tiles", 0.02, {"col": false})
	for i in 3:
		prop("home/Bathroom_Sink", Vector3(0.6 + i * 1.5, 0, -7.1), 0)
		prop("home/Bathroom_Mirror1", Vector3(0.6 + i * 1.5, 1.25, -7.42), 0)
	prop("home/Bathroom_WashingMachine", Vector3(6.3, 0, -6.9), 0)
	prop("home/Bathroom_WashingMachine", Vector3(6.3, 0, -5.9), -90)
	prop("home/Bathroom_Towel", Vector3(-0.8, 1.3, -4.5), 90)
	txt("Я ПОМЫЛСЯ", Vector3(3, 2.3, -7.44), 0, 0.3, {"col": Color(0.3, 0.6, 0.9), "outline": 4})
	ceil_lamp(Vector3(3, 3.0, -4.6), Color(0.85, 0.95, 1.0), 2.0, 7.5)
	crate(Vector3(5.6, 0, -3.0), [["spray", 1]], {"cross": true, "on_break": func():
		G.toast("Дихлофос! Зажми %s — облако. Крысы его не выносят." % Inp.hint("gadget"), "big")
		G.ui.hud.refresh_hints()})
	enemy("rat", Vector3(1.5, 0.2, -4.0))
	trigger(Vector3(3, 1, -2.2), Vector3(1.0, 1.5, 0.8), func():
		if not G.has("spray"):
			G.toast("В ящике с красным крестом — дихлофос. Разбей его!", ""))
	# 5 — вторая цифра
	_bedroom(11, true, 0, 2.5)
	_digit(1, Vector3(11, 1.9, -7.44), 0, Color(0.45, 0.85, 1.0))
	crate(Vector3(13.6, 0, -3.0), [["cash", 14]])
	# 6 — кладовка
	prop("home/Shelf_Large", Vector3(19, 0, -7.2), 0)
	prop("home/Shelf_2", Vector3(22.5, 0, -5.0), -90)
	crate(Vector3(16.4, 0, -6.4), [["doshik", 1], ["cash", 6]])
	crate(Vector3(17.6, 0, -6.6), [["bread", 2]])
	crate(Vector3(21.6, 0, -3.0), [["tasty", 1]], {"prop": "plat/Cube_Crate", "hp": 30.0})
	crate(Vector3(21.8, 0, -6.6), [["cash", 18]])
	ceil_lamp(Vector3(19, 3.0, -4.6), Color(1.0, 0.8, 0.5), 1.5, 7.0)
	for p in [Vector3(18, 0.2, -4.2), Vector3(20, 0.2, -5.2), Vector3(19.5, 0.2, -3.2)]:
		enemy("rat", p)
	# вахта
	prop("home/Drawer_2", Vector3(-21, 0, 3.3), 0)
	prop("home/Chair_2", Vector3(-21, 0, 4.4), 180)
	prop("home/Bookshelf", Vector3(-23.6, 0, 7.2), 180)
	prop("home/Houseplant_6", Vector3(-17.8, 0, 6.8), 0)
	ceil_lamp(Vector3(-21, 3.0, 4.6), Color(1.0, 0.9, 0.7), 1.9, 7.5)
	txt("ПОСЛЕ 23:00\nНЕ ВЫПУСКАЮ", Vector3(-21, 2.0, 7.44), 180, 0.26, {"col": Color(1, 0.4, 0.35), "outline": 4})
	# ларёк Темщика
	box(Vector3(-13, 0.55, 3.4), Vector3(3.4, 1.1, 0.7), "wood_dark")
	prop("home/Shelf_Large", Vector3(-13, 0, 7.2), 180)
	prop("home/Kitchen_Fridge", Vector3(-10.0, 0, 6.9), 180)
	txt("ЛАРЁК", Vector3(-13, 2.2, 7.44), 180, 0.42, {"col": Color(1, 0.4, 0.3), "glow": 1.2})
	ceil_lamp(Vector3(-13, 3.0, 4.6), Color(1.0, 0.75, 0.55), 2.0, 7.5)
	# качалка — третья цифра
	prop("home/Carpet_2", Vector3(-5, 0.02, 4.6), 0)
	prop("home/Stool", Vector3(-7.6, 0, 6.6), 0)
	box(Vector3(-2.7, 0.3, 5.9), Vector3(2.0, 0.25, 0.6), "metal_dark")
	cyl(Vector3(-3.8, 0.75, 5.9), 0.38, 0.12, "black", {"col": false}).rotation.z = PI * 0.5
	cyl(Vector3(-1.6, 0.75, 5.9), 0.38, 0.12, "black", {"col": false}).rotation.z = PI * 0.5
	box(Vector3(-2.7, 0.75, 5.9), Vector3(2.4, 0.06, 0.06), "metal", {"col": false})
	_digit(2, Vector3(-5, 1.9, 7.44), 180, Color(0.6, 1.0, 0.6))
	txt("АМ АМ\nАМ", Vector3(-8.84, 1.9, 4.6), 90, 0.34, {"col": Color(1.0, 0.35, 0.3), "outline": 6})
	ceil_lamp(Vector3(-5, 3.0, 4.6), Color(1.0, 0.88, 0.66), 1.8, 7.5)
	enemy("rat", Vector3(-5, 0.2, 5.4))
	# комната отдыха
	prop("home/Couch_Medium1", Vector3(3, 0, 6.9), 180)
	prop("home/Table_RoundSmall2", Vector3(3, 0, 4.6), 0)
	prop("cyber/TV_1", Vector3(3, 0.0, 2.1), 0, 1.0, {"h": 1.0})
	prop("home/Light_Floor1", Vector3(6.4, 0, 7.0), 0)
	prop("home/Carpet_Round", Vector3(3, 0.02, 4.9), 0)
	txt("ПОСИДИМ", Vector3(3, 2.3, 7.44), 180, 0.34, {"col": Color(1.0, 0.7, 0.4), "outline": 6})
	lamp(Vector3(3, 1.2, 2.6), Color(0.5, 0.7, 1.0), 1.4, 5.0)
	ceil_lamp(Vector3(3, 3.0, 4.9), Color(1.0, 0.85, 0.6), 1.5, 7.0)
	# кухня
	slab(7, 1.6, 15, 7.6, 0.012, "tiles_green", 0.02, {"col": false})
	var kx := 7.7
	for k in ["home/Kitchen_Fridge", "home/Kitchen_Oven", "home/Kitchen_Sink", "home/Kitchen_2Drawers", "home/Kitchen_Oven_Large", "home/Kitchen_Cabinet1"]:
		prop(k, Vector3(kx, 0, 7.05), 180)
		kx += 0.75 if k != "home/Kitchen_Fridge" else 0.85
	prop("home/Table_RoundLarge", Vector3(11, 0, 4.2), 0)
	prop("home/Chair_3", Vector3(11, 0, 3.2), 0)
	prop("home/Chair_3", Vector3(12.6, 0, 4.2), -90)
	prop("home/Trashcan_Small1", Vector3(14.5, 0, 7.0), 0)
	txt("НЕ КОРМИТЬ\nКРЫС!", Vector3(14.84, 1.9, 4.6), -90, 0.3, {"col": Color(1.0, 0.3, 0.25), "outline": 6})
	ceil_lamp(Vector3(11, 3.0, 4.6), Color(0.9, 1.0, 0.9), 2.0, 7.5)
	for p in [Vector3(9, 0.2, 5.6), Vector3(13, 0.2, 5.8), Vector3(12.8, 0.2, 2.6)]:
		enemy("rat", p)
	if not G.has("note_dorm") and not G.flag("d_open"):
		pickup("note_dorm", Vector3(11, 0.95, 4.2), 1, {"on_take": _note_taken})
	# крысы в коридоре
	enemy("rat", Vector3(9, 0.2, 0.3))
	enemy("rat", Vector3(16, 0.2, -0.4))


# ---------- подвал ----------

func _basement() -> void:
	# лестничная клетка
	wall(15, 1.6, 15, 3.0, 0, 3.0, WALL)
	wall_gaps(15, 1.6, 15, 12.4, -4, 7.0, "brick", [[10.0, 2.2, 2.6]])
	wall(23, 1.6, 23, 12.4, -4, 7.0, "brick")
	wall(15, 12.4, 23, 12.4, -4, 7.0, "brick")
	stairs(Vector3(19, 0, 3.4), Vector3(19, -4, 10.6), 2.6, "concrete")
	box(Vector3(17.55, -1.3, 7.0), Vector3(0.12, 5.4, 7.4), "concrete_dark")
	box(Vector3(20.45, -1.3, 7.0), Vector3(0.12, 5.4, 7.4), "concrete_dark")
	ceil_lamp(Vector3(19, 2.9, 6.5), Color(1.0, 0.6, 0.3), 1.6, 9.0)
	txt("ПОДВАЛ", Vector3(19, 1.6, 12.24), 180, 0.5, {"col": Color(1, 0.75, 0.2), "outline": 8})
	# пол и стены подвала
	slab(-24.5, 1.5, 23.5, 18.5, -4.0, "concrete_dark", 0.5)
	slab(-25, 8, 23.6, 18.6, -0.1, "concrete_dark", 0.5)
	# потолок одним материалом и плоские балки на нём: ровная плита в свете ламп читалась как закатное небо.
	# Балки тоньше зазора камеры (0.12), чтобы она в них не въезжала
	ceiling(-24.5, 1.5, 15, 8.05, -0.6, "concrete_dark")
	for x in [-20.0, -16.0, -12.0, -8.0, 1.0, 6.5, 12.0]:
		box(Vector3(x, -0.63, 10), Vector3(0.5, 0.06, 15.8), "black", {"col": false})
	for z in [6.0, 14.0]:
		box(Vector3(-4.5, -0.63, z), Vector3(38.6, 0.06, 0.4), "black", {"col": false})
	wall(-24, 2, 15, 2, -4, 3.4, "brick")
	wall(-24, 18, 15, 18, -4, 3.4, "brick")
	wall(-24, 2, -24, 18, -4, 3.4, "brick")
	wall_gaps(15, 12.4, 15, 18, -4, 3.4, "brick", [])
	wall_gaps(-2, 2, -2, 18, -4, 3.4, "brick", [[8.0, 3.2, 2.8]])
	# склад: перегородки, трубы, ящики, крысы
	wall(4, 2, 4, 8, -4, 3.4, "brick")
	wall(9, 12, 9, 18, -4, 3.4, "brick")
	for z in [4.0, 16.0]:
		cyl(Vector3(6.5, -1.0, z), 0.16, 17.0, "rust", {"col": false}).rotation.z = PI * 0.5
	for p in [Vector3(12.5, -4, 4.0), Vector3(6.5, -4, 15.5), Vector3(0.5, -4, 4.0)]:
		crate(p, [["cash", 8]])
	crate(Vector3(11.5, -4, 16.5), [["doshik", 1]])
	prop("dung/Barrel", Vector3(13.6, -4, 16.8), 0)
	prop("dung/Barrel", Vector3(1.2, -4, 16.6), 0)
	for p in [Vector3(11, -3.8, 6), Vector3(7, -3.8, 11), Vector3(2, -3.8, 14), Vector3(1, -3.8, 6), Vector3(12, -3.8, 14)]:
		enemy("rat", p)
	enemy("rat_big", Vector3(3, -3.8, 10))
	lamp(Vector3(11, -1.7, 10), Color(1.0, 0.6, 0.3), 1.9, 10.0)
	lamp(Vector3(3, -1.7, 10), Color(1.0, 0.6, 0.3), 1.9, 10.0)
	txt("ТРОННЫЙ\nЗАЛ", Vector3(-1.84, -1.4, 10), 90, 0.42, {"col": Color(0.5, 0.9, 0.4), "outline": 8})
	# тронный зал
	for p in [Vector3(-8, -4, 6.5), Vector3(-18, -4, 6.5), Vector3(-8, -4, 13.5), Vector3(-18, -4, 13.5)]:
		prop("dung/Column", p, 0, 1.0, {"h": 3.4})
	for p in [Vector3(-13, -1.6, 4), Vector3(-13, -1.6, 16), Vector3(-21, -1.6, 10), Vector3(-5, -1.6, 10)]:
		lamp(p, Color(0.6, 1.0, 0.5), 2.2, 11.0)
	prop("home/Couch_Large1", Vector3(-22.6, -4, 10), 90)
	prop("rpg/Gold_Ingots", Vector3(-22.4, -4, 7.6), 30, 1.0, {"h": 0.5})
	prop("dung/Bones", Vector3(-20.5, -4, 12.4), 0, 1.0, {"w": 1.2})
	gate = blocker(Vector3(-2, -2.3, 10), Vector3(0.4, 3.4, 3.4))
	gate.disabled = true
	if not G.flag("d_boss"):
		boss = RatKing.new()
		add_child(boss)
		boss.global_position = Vector3(-20, -3.9, 10)
		boss.home = boss.global_position
		boss.arena = Vector3(-13, -4, 10)
		boss.arena_r = 7.5
		boss.set_yaw(-PI * 0.5)
		boss.on_defeat = _boss_dead
		trigger(Vector3(-5.5, -3, 10), Vector3(1.5, 2, 4), _boss_intro)
	cp_zone("boss", Vector3(1.5, -3, 10), Vector3(1.5, 2, 3))


func cp_zone(nm: String, pos: Vector3, half: Vector3) -> void:
	trigger(pos, half, func():
		if String(G.save["cp"]) != nm and not G.flag("d_boss"):
			G.checkpoint(nm))


# ---------- люди и двери ----------

func _people() -> void:
	bral = npc("bral", Vector3(-11.6, 0, -6.2), 90, {"anim": "Sit", "solid": false, "talk": _talk_bral, "mark": "" if G.flag("d_bral") else "!"})
	bral.position.y = 0.0
	npc("temshik", Vector3(-13, 0, 4.5), 180, {"mark": "₽", "label": "Купить", "talk": func():
		await say([["temshik", "Что за бизнес? Дошики, хлеб, бурмалда. Всё свежее, почти."]])
		Menus.shop(G.ui, "ЛАРЁК ТЕМЩИКА", "Сколько-сколько?", ["bread", "banana", "doshik", "energy", "tasty", "chain"])
		await G.ui.panel_closed})
	vaht = npc("vahter", Vector3(-21, 0, 4.4), 180, {"anim": "Sit", "solid": false, "look": false, "talk": _talk_vaht, "r": 3.0})
	npc({"rig": "men", "body": "beach", "colors": {"White": Color("d8d0c0"), "Red_Dark": Color("3a6a3a"), "Skin": Color("e2b292"), "Hair": Color("2a2018")}}, Vector3(3.9, 0, 6.5), 180, {"name": "Сосед", "anim": "Steam", "solid": false, "talk": func():
		await say([[{"n": "Сосед"}, "Посидим? Телек не показывает — крысы антенну сгрызли."], [{"n": "Сосед"}, "Они дихлофос не выносят. Пшикнешь — чихают и стоят как вкопанные. Тут-то их и бей."]])})
	# дверь подвала с кодовым замком
	base_door = door(Vector3(19, 0, 1.6), 0, {"w": 1.3, "label": "", "mat": "metal_dark"})
	if G.flag("d_open"):
		base_door.set_open(true, true)
	interact(Vector3(18.0, 1.1, 1.2), 2.0, "Кодовый замок", _keypad, {"cond": func(): return not base_door.is_open})
	box(Vector3(17.95, 1.3, 1.44), Vector3(0.3, 0.42, 0.08), "metal_dark", {"col": false})
	box(Vector3(17.95, 1.43, 1.39), Vector3(0.22, 0.08, 0.03), Mats.glow(Color(1.0, 0.75, 0.2), 0.9), {"col": false})
	for i in 6:
		box(Vector3(17.88 + (i % 3) * 0.07, 1.3 - (i / 3) * 0.09, 1.39), Vector3(0.045, 0.05, 0.03), "plaster", {"col": false})
	# выход
	exit_door = door(Vector3(-28, 0, 0), 90, {"w": 1.5, "label": "Выйти на улицу", "mat": "metal_dark", "dir": -1.0,
		"locked": func(): return "" if G.has("key_dorm") else "Заперто. Ключ комендант унёс в подвал.",
		"on_open": _leave})


func begin(cp_name: String) -> void:
	G.player.hp = minf(G.player.hp, G.max_hp())
	if not G.has("phone"):
		G.give("phone", 1, true)
	if cp_name == "start" and not G.flag("d_call"):
		title_card()
		await cut(_intro)
	_refresh_goal()


func _intro() -> void:
	var p := G.player
	G.cam.shot(Vector3(-20.2, 1.5, -2.8), Vector3(-22.4, 1.15, -4.2), 46.0)
	await G.wait(1.6)
	Snd.sfx("phone", 0.0)
	p.anim_lock = "Phone"
	await say([["phone", "*бзззз* Входящий вызов: ДРУН"], ["drun", "Ч! Ты чё, спишь?! ФОГ ИДЁТ! Туман уже у вашей общаги!"], ["ch", "Друн?.. Какой ещё Фог?"],
		["drun", "Тот самый. Вали оттуда и дуй ко мне в Мурино, я у шавермы. И осторожно — крысы у вас уже с собаку!"]])
	p.anim_lock = ""
	G.cam.end_shot()
	G.set_flag("d_call")
	G.toast("%s — ходьба, %s — камера, %s — действие" % (["Стик слева", "палец справа", "кнопка E"] if G.touch else ["WASD", "мышь", "E"]), "")


func _refresh_goal() -> void:
	if G.flag("d_boss"):
		G.goal("Выйди из общаги через вахту", Vector3(-27.2, 0, 0))
	elif G.flag("d_open"):
		G.goal("Спустись в подвал и найди коменданта", Vector3(-6, -4, 10))
	elif G.has("note_dorm"):
		G.goal("Найди три цифры на стенах и введи код у двери подвала", Vector3(19, 0, 0.6))
	elif G.flag("d_bral"):
		G.goal("Найди записку коменданта на кухне", Vector3(11, 0, 3.0))
	elif G.flag("d_vaht"):
		G.goal("Спроси Брала, как выбраться (комната 2)", Vector3(-13, 0, -2.4))
	else:
		G.goal("Выйди из общаги через вахту", Vector3(-27.2, 0, 0))


func _talk_vaht() -> void:
	if G.has("key_dorm"):
		await say([["vahter", "Ключ? Ну иди, иди. И дверь за собой закрой — туман напустишь!"]])
	else:
		await say([["vahter", "Куда?! После одиннадцати не выпускаю! Ключ у коменданта, комендант в подвале. А в подвал я не пойду — там ЭТОТ, усатый."]])
		G.set_flag("d_vaht")
	_refresh_goal()


func _talk_bral() -> void:
	if G.flag("d_boss"):
		await say([["bral", "Ты завалил Короля?! Красавчик, Ч. Беги, пока туман не пришёл. Я тут… посижу."]])
	elif not G.flag("d_bral"):
		await say([["bral", "Ч, вахтёрша выход заперла. Ключ комендант унёс в подвал, а подвал на кодовом замке."],
			["bral", "Он записку на кухне оставил. Кухня в конце коридора, направо. На, держи дошики на дорожку."]])
		G.give("doshik", 2)
		G.set_flag("d_bral")
		G.set_flag("d_vaht")
		bral.set_mark("")
	else:
		await say([["bral", "Записка на кухне — в конце коридора направо. Код от подвала как-то связан с цифрами на стенах."],
			["bral", "И найди дихлофос. В умывальной вроде стоял ящик с красным крестом."]])
	_refresh_goal()


func _note_taken() -> void:
	G.set_flag("d_bral")
	G.set_flag("d_vaht")
	await cut(func():
		await say([[{"n": "Записка"}, "«Код от подвала я записал на стенах, чтоб не забыть. Три цифры в трёх комнатах. Точки под цифрой — её номер по порядку. — Комендант»"]]))
	_refresh_goal()


func _keypad() -> void:
	var hint := "Цифры нарисованы на стенах. Считай точки под ними: • — первая, •• — вторая, ••• — третья." if G.has("note_dorm") else "Нужен код. Комендант оставил записку на кухне."
	var c: String = await Puzzles.keypad(G.ui, "ПОДВАЛ", 3, hint)
	if c == code:
		G.set_flag("d_open")
		base_door.set_open(true)
		Snd.sfx("unlock", 0.0)
		G.toast("Подвал открыт", "big")
		G.checkpoint("base", true)
		_refresh_goal()
	elif c != "":
		Snd.sfx("deny", -3.0)
		G.toast("Неверный код", "small")


func _boss_intro() -> void:
	gate.disabled = false
	await cut(func():
		Snd.music("boss")
		G.cam.shot(Vector3(-11, -2.4, 12.5), Vector3(-19, -2.8, 10), 52.0)
		await G.wait(0.8)
		await say([["ch", "Что за бизнес… Он же размером с «Газель»!"]])
		boss.play("attack", 0.1, 0.7, true)
		Snd.sfx("roar", 0.0)
		G.cam.shake(0.6)
		G.ui.big_title("КРЫСИНЫЙ КОРОЛЬ", "БОСС")
		await G.wait(1.3)
		G.cam.end_shot())
	boss.start()
	G.goal("Победи Крысиного Короля. Уворачивайся от разгона — пусть врежется в стену!")


func _boss_dead() -> void:
	G.set_flag("d_boss")
	gate.disabled = true
	Snd.music("dorm")
	Snd.sfx("win", 0.0)
	G.pay(60)
	await cut(func():
		await G.wait(0.6)
		await say([[{"n": "Комендант (из-за трона)"}, "Он… всё? Забирай ключ, сынок. И цепь забирай — он её у меня отжал."], ["ch", "Ам-ам-ам! Ключ. И цепь золотая — вкусность. Теперь на выход."]])
		G.give("key_dorm", 1, true)
		G.give("chain"))
	G.checkpoint("after", true)
	_refresh_goal()


func _leave() -> void:
	await cut(func():
		await say([["ch", "Поехали. Мурино ждёт."]])
		Story.mark_done("dorm")
		G.travel("murino"))


func _physics_process(dt: float) -> void:
	super._physics_process(dt)
	if not hinted_fight and G.mode == "play":
		for e in G.ents:
			if is_instance_valid(e) and e.aggro and not e.boss:
				hinted_fight = true
				if G.touch:
					G.toast("УДАР — три подряд, КАТ — перекат, ₽ — бросок", "")
				else:
					G.toast("ЛКМ — удар (три подряд — серия). C — перекат. ПКМ — швырнуть котлету денег.", "")
				break
