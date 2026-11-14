extends Level
## Полигон для проверки механик (в игру не входит): ровная площадка, враги, NPC, ящики, магазин.


func build() -> void:
	title = "ПОЛИГОН"
	chapter = "ТЕСТ"
	set_env(String(G.opts.get("env", "day")))
	slab(-40, -40, 40, 40, 0.0, "grass", 1.0)
	slab(-6, -40, 6, 40, 0.02, "asphalt", 0.05, {"col": false})
	wall(-12, -20, 12, -20, 0, 3, ["plaster_green", "plaster", 1.2])
	wall(-12, -20, -12, -10, 0, 3, "brick")
	wall_gaps(12, -20, 12, -6, 0, 3, "panel", [[7.0, 1.4]])
	stairs(Vector3(16, 0, -4), Vector3(16, 3, -10), 3.0, "concrete")
	slab(13, -16, 19, -10, 3.0, "concrete", 0.4)
	ramp(Vector3(-16, 0, -4), Vector3(-16, 2, -9), 3.0, "wood")
	building(Vector3(0, 0, -40), Vector3(40, 30, 10), "facade_panel")
	building(Vector3(-34, 0, -10), Vector3(10, 18, 30), "facade_brick")
	building(Vector3(34, 0, -10), Vector3(10, 24, 30), "facade_new")
	prop("home/Bed_Bunk", Vector3(-9, 0, -17), 0.0)
	prop("home/Table_RoundSmall", Vector3(-6, 0, -17), 0.0)
	prop("home/Chair_1", Vector3(-4.5, 0, -17), 0.0)
	prop("home/Kitchen_Fridge", Vector3(-2.5, 0, -18.8), 0.0)
	prop("home/Couch_Medium1", Vector3(1, 0, -18.5), 0.0)
	prop("village/Well", Vector3(8, 0, 6), 0.0)
	prop("bld/House1", Vector3(-22, 0, 10), 90.0, 2.4)
	scatter(["nature/BirchTree_1", "nature/BirchTree_2", "nature/PineTree_1", "nature/CommonTree_1"], Vector3(22, 0, 16), 14.0, 12, {"sc": [0.9, 1.3]})
	scatter(["nature/Grass", "nature/Flowers", "nature/Bush_1"], Vector3(22, 0, 16), 14.0, 20)
	post(Vector3(7, 0, 0), 0.0)
	txt("ПОЛИГОН", Vector3(0, 4.5, -19.8), 0.0, 1.4, {"col": Color(0.4, 0.9, 1.0), "glow": 2.0})
	board("ВАХТА", Vector3(-6, 2.4, -19.8), 0.0, 2.0, 0.6, {"col": UI.Y})
	lamp(Vector3(0, 2.5, -17), Color(1, 0.85, 0.6), 2.5, 9.0)
	cp("start", Vector3(0, 0.1, 6), 0.0)
	npc("drun", Vector3(3, 0, 2), 180.0, {"mark": "!", "talk": func():
		await say([["drun", "Ч! Живой! Ам-ам-ам, как я рад."], ["ch", "Что за бизнес?"]])
		var c: int = await G.ui.choose("drun", "Купишь что-нибудь?", ["Давай", "Потом"])
		if c == 0:
			Menus.shop(G.ui, "ЛАРЁК", "Всё свежее, почти.", ["bread", "doshik", "shawa", "chain", "tasty"])
			await G.ui.panel_closed
		})
	npc("bral", Vector3(-3, 0, 2), 180.0, {"anim": "Squat", "talk": func(): await say([["bral", "Дай хотя бы хлеба."]])})
	npc("vahter", Vector3(-6, 0, 2), 180.0, {"talk": func(): await say([["vahter", "Куда?! После одиннадцати не выпускаю!"]])})
	crate(Vector3(5, 0, -3), [["cash", 12], ["doshik", 1]], {"cross": true})
	crate(Vector3(6.2, 0, -3), [["spray", 1]])
	pickup("am", Vector3(-2, 0.6, -2))
	pickup("kicks", Vector3(-3, 0.6, -2))
	pickup("phone", Vector3(-4, 0.6, -2))
	cash(Vector3(2, 0.6, -2), 40)
	var kinds: Array = String(G.opts.get("enemies", "rat,rat,imp,spider,gopnik")).split(",", false)
	var i := 0
	for k in kinds:
		enemy(k, Vector3(-6 + i * 3.0, 0.2, -10))
		i += 1
	door(Vector3(12, 0, -13), 90.0, {"label": "Открыть дверь"})
	G.goal("Проверь всё", Vector3(16, 3, -13))


func begin(_cp: String) -> void:
	title_card()
