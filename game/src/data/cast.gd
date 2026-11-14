class_name Cast
extends RefCounted
## Действующие лица: имя, портрет для диалогов и внешний вид (модель + перекраска по именам материалов).

const SKIN := Color("e7bb9b")
const SKIN_D := Color("d7a787")
const HAIR_DARK := Color("1d1511")

## облики героя
const SKINS := {
	"casual": {"rig": "men", "body": "casual", "colors": {"White": Color("f2f2ee"), "LightBlue": Color("17181d"), "Red_Dark": Color("e9e9e6"), "LightBrown": Color("b9b9b6"), "Skin": SKIN, "Skin_Darker": SKIN_D, "Hair": HAIR_DARK, "Eyebrows": HAIR_DARK}},
	"suit": {"rig": "men", "body": "suit", "colors": {"Suit": Color("15161b"), "White": Color("f4f4f0"), "Tie": Color("c9a227"), "Black": Color("0c0c0e"), "Skin": SKIN, "Hair": HAIR_DARK, "Eyebrows": HAIR_DARK}},
	"hoodie": {"rig": "men", "body": "hoodie", "colors": {"Purple": Color("e8e8e4"), "LightBlue": Color("15161a"), "White": Color("d8d8d8"), "Skin": SKIN, "Hair": HAIR_DARK, "Eyebrows": HAIR_DARK}},
	"beach": {"rig": "men", "body": "beach", "colors": {"White": Color("f0f0ec"), "Red_Dark": Color("c9a227"), "Skin": SKIN, "Hair": HAIR_DARK, "Eyebrows": HAIR_DARK}},
}

const CAST := {
	"ch": {"name": "Ч", "face": "ch", "col": Color("ffd21f")},
	"phone": {"name": "Бурмалфон", "col": Color("8fd0ff")},
	"lift": {"name": "Ливт", "col": Color("9ad0ff")},
	"drun": {"name": "Друн", "face": "drun", "col": Color("7fb0ff"),
		"look": {"rig": "men", "body": "hoodie", "colors": {"Purple": Color("2f62c8"), "LightBlue": Color("202228"), "White": Color("e6e6e6"), "Skin": Color("e2b292"), "Hair": Color("3a2a1c"), "Eyebrows": Color("3a2a1c")}}},
	"dark": {"name": "Тёмный Друн", "face": "dark", "col": Color("b07cff"),
		"look": {"rig": "men", "body": "hoodie", "colors": {"Purple": Color("0b0a10"), "LightBlue": Color("08080b"), "White": Color("1a1722"), "Skin": Color("8c7a8c"), "Hair": Color("050506"), "Eyebrows": Color("050506"), "Eye": Color("c9a0ff")}}},
	"bral": {"name": "Брал", "face": "bral", "col": Color("c8e08a"),
		"look": {"rig": "men", "body": "adventurer", "colors": {"Green": Color("6a6f78"), "LightGreen": Color("7d8490"), "Brown": Color("4a4a52"), "Brown2": Color("3a3a40"), "Skin": Color("e0b090"), "Hair": Color("5a3a22"), "Eyebrows": Color("5a3a22")}}},
	"dod": {"name": "Дод", "face": "dod", "col": Color("ffb37a"),
		"look": {"rig": "men", "body": "beach", "colors": {"White": Color("f0e9d8"), "Red_Dark": Color("2f6fb5"), "Skin": Color("eab79a"), "Hair": Color("6b4a2a"), "Eyebrows": Color("6b4a2a")}}},
	"pradod": {"name": "Пра Дод", "col": Color("e8e0c8"),
		"look": {"rig": "men", "body": "king", "colors": {"Metal": Color("7a5a3a"), "Metal_Dark": Color("5a4028"), "Blue": Color("8a6a48"), "Beige": Color("e8dcc0"), "DarkBrown": Color("4a3626"), "Gold": Color("b08a50"), "Skin": Color("dba88a"), "Hair_White": Color("f0f0f0")}}},
	"temshik": {"name": "Темщик", "col": Color("ff7a6a"),
		"look": {"rig": "men", "body": "punk", "colors": {"Black": Color("15151a"), "LightBlue": Color("1c1c22"), "White": Color("e8e8e8"), "Red_Dark": Color("b01818"), "Red": Color("b01818"), "Skin": Color("d8a888")}}},
	"vahter": {"name": "Вахтёрша", "col": Color("d8a8e8"),
		"look": {"rig": "women", "body": "formal", "colors": {"LimeGreen": Color("6a4a7a"), "Red": Color("9a9aa2"), "Brown": Color("4a4040"), "Skin": Color("e0b8a0"), "Gold": Color("c0a060")}}},
	"komendant": {"name": "Комендант", "col": Color("c8c8c8"),
		"look": {"rig": "men", "body": "suit", "colors": {"Suit": Color("5a5648"), "White": Color("d8d8c8"), "Tie": Color("6a2020"), "Black": Color("2a2620"), "Skin": Color("dcae90"), "Hair": Color("8a8a8a"), "Eyebrows": Color("8a8a8a")}}},
	"ashot": {"name": "Ашот", "col": Color("ffcf8a"),
		"look": {"rig": "men", "body": "worker", "colors": {"Worker_Yellow": Color("f2f2f2"), "Worker_Vest": Color("f2f2f2"), "Brown": Color("2a2a30"), "Brown2": Color("2a2a30"), "LightBrown": Color("f2f2f2"), "Grey": Color("1c1c20"), "Black": Color("1c1c20"), "Skin": Color("c89070"), "Moustache": Color("1a1410"), "Eyebrows": Color("1a1410")}}},
	"courier": {"name": "Курьер", "col": Color("ffe14a"),
		"look": {"rig": "men", "body": "worker", "colors": {"Worker_Yellow": Color("ffd21f"), "Worker_Vest": Color("ffd21f"), "Brown": Color("ffd21f"), "Brown2": Color("e0b810"), "LightBrown": Color("1c1c20"), "Grey": Color("1c1c20"), "Black": Color("1c1c20"), "Skin": Color("dcb090"), "Moustache": Color("3a2a1a"), "Eyebrows": Color("3a2a1a")}}},
	"mashinist": {"name": "Машинист", "col": Color("9ab8e8"),
		"look": {"rig": "men", "body": "swat", "colors": {"Swat": Color("2a4a8a"), "Swat_Black": Color("1a2a4a"), "Visor": Color("202028"), "Skin": Color("dcb090")}}},
	"konduktor": {"name": "Кондукторша", "col": Color("ffb0c8"),
		"look": {"rig": "women", "body": "worker", "colors": {"Worker_Vest": Color("c83a5a"), "Worker_Yellow": Color("3a5ac8"), "White": Color("f0f0f0"), "Black": Color("2a2a30"), "Brown2": Color("3a3a5a"), "Brown_02": Color("3a3a5a"), "Skin": Color("e2b8a0")}}},
	"ded": {"name": "Дед", "col": Color("d8c8a0"),
		"look": {"rig": "men", "body": "farmer", "colors": {"LightBlue": Color("4a5a78"), "Beige": Color("e0d8c0"), "Brown": Color("7a6040"), "Brown2": Color("5a4630"), "Red": Color("a03028"), "Skin": Color("d8a888"), "Eyebrows": Color("d0d0d0")}}},
	"milkmaid": {"name": "Молочница", "col": Color("f0f0ff"),
		"look": {"rig": "women", "body": "casual", "colors": {"White": Color("f6f6ff"), "Grey": Color("6a8ac8"), "Orange": Color("3a5aa8"), "Hair_Blond": Color("d8b060"), "Hair_Brown": Color("d8b060"), "Skin": Color("eabfa5")}}},
	"rybak": {"name": "Рыбак", "col": Color("a8c8a0"),
		"look": {"rig": "men", "body": "adventurer", "colors": {"Green": Color("4a5a3a"), "LightGreen": Color("5a6a48"), "Brown": Color("6a5a40"), "Brown2": Color("4a4030"), "Skin": Color("d8a888"), "Hair": Color("7a7a7a"), "Eyebrows": Color("7a7a7a")}}},
	"banshica": {"name": "Банщица", "col": Color("a0e0f0"),
		"look": {"rig": "women", "body": "suit", "colors": {"Black": Color("f4f8fa"), "White": Color("ffffff"), "Hair_Blond": Color("c8d8e0"), "Hair_Brown": Color("c8d8e0"), "Brown": Color("e0e8ec"), "Skin": Color("eac0a8")}}},
	"clean_guard": {"name": "Вахтёр чистоты", "col": Color("c8f0ff"),
		"look": {"rig": "men", "body": "astronaut", "colors": {"SciFi_Main": Color("f2f6f8"), "SciFi_MainDark": Color("c8d8e0"), "SciFi_Light": Color("ffffff"), "SciFi_Light_Accent": Color("58b8e8"), "Grey": Color("8898a0")}}},
	"seller": {"name": "Продавщица", "col": Color("b0e8c0"),
		"look": {"rig": "women", "body": "worker", "colors": {"Worker_Vest": Color("f4f8fa"), "Worker_Yellow": Color("58b8e8"), "White": Color("ffffff"), "Black": Color("d8e0e4"), "Brown2": Color("c8d8e0"), "Brown_02": Color("c8d8e0"), "Skin": Color("eac0a8")}}},
	"controller": {"name": "Контролёр", "col": Color("ff9a6a"),
		"look": {"rig": "men", "body": "swat", "colors": {"Swat": Color("7a2a2a"), "Swat_Black": Color("2a1a1a"), "Visor": Color("ffcf40"), "Skin": Color("dcb090")}}},
	"fog": {"name": "ФОГ", "face": "pale", "col": Color("e8ecf4")},
	"rat_king": {"name": "Крысиный Король", "col": Color("d0a070")},
	"mother": {"name": "Паучья Матка", "col": Color("e08080")},
	"moidodyr": {"name": "Мойдодыр", "col": Color("9ad8ff")},
	"bannik": {"name": "Банник", "col": Color("ffb090")},
	"concierge": {"name": "Консьерж", "col": Color("a0f0c0")},
	"croupier": {"name": "Крупье", "col": Color("ff6a7a")},
}


static func name_of(id: String) -> String:
	return String(CAST.get(id, {}).get("name", id))


static func look_of(id: String) -> Dictionary:
	return CAST.get(id, {}).get("look", SKINS["casual"])
