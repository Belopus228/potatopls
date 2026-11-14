class_name Bestiary
extends RefCounted
## Противники. ai: melee — подойти и ударить; charger — разбег; leaper — прыжок; shooter — стрельба с дистанции;
## flyer — летает и пикирует; flyer_shooter — летает и стреляет.

const GOP1 := {"rig": "men", "body": "punk", "colors": {"Black": Color("1a1a1e"), "LightBlue": Color("22242c"), "White": Color("c8c8c8"), "Red_Dark": Color("30343c"), "Red": Color("4a7a3a"), "Skin": Color("d8a888")}}
const GOP2 := {"rig": "men", "body": "hoodie", "colors": {"Purple": Color("3a3d44"), "LightBlue": Color("1c1e24"), "White": Color("d0d0d0"), "Skin": Color("d8a888"), "Hair": Color("2a2018"), "Eyebrows": Color("2a2018")}}
const ZOMBIE := {"rig": "men", "body": "casual", "colors": {"White": Color("5a6a58"), "LightBlue": Color("2a3430"), "Red_Dark": Color("2a2a2a"), "LightBrown": Color("3a3a3a"), "Skin": Color("8fb89a"), "Skin_Darker": Color("7aa086"), "Hair": Color("202a24"), "Eyebrows": Color("202a24"), "Eye": Color("e8ffb0")}}
const GUARD := {"rig": "men", "body": "swat", "colors": {"Swat": Color("3a2030"), "Swat_Black": Color("1a1016"), "Visor": Color("ff4060"), "Skin": Color("dcb090")}}

const DEFS := {
	"rat": {"name": "Крыса", "model": "rat", "size": 0.6, "r": 0.42, "h": 0.7, "hp": 26, "speed": 4.6, "dmg": 7, "reach": 1.2, "ai": "charger", "dash": 10.0, "sight": 10, "weak_spray": 2.6, "money": [1, 3], "windup": 0.4, "anim_k": 1.4},
	"rat_big": {"name": "Крысюк", "model": "rat", "size": 1.0, "r": 0.6, "h": 1.1, "hp": 70, "speed": 4.2, "dmg": 12, "reach": 1.6, "ai": "charger", "dash": 11.0, "sight": 11, "weak_spray": 2.2, "money": [4, 7], "windup": 0.5, "colors": {"Grey": Color("3a2a22")}},
	"imp": {"name": "Пакость", "model": "ghost", "size": 1.15, "r": 0.45, "h": 1.2, "hp": 30, "speed": 3.8, "dmg": 8, "reach": 1.5, "ai": "flyer", "fly": 0.9, "sight": 11, "money": [2, 4], "windup": 0.45},
	"spider": {"name": "Паучность", "model": "spider", "size": 0.75, "r": 0.6, "h": 0.8, "hp": 34, "speed": 4.4, "dmg": 9, "reach": 1.4, "ai": "leaper", "sight": 11, "weak_spray": 3.0, "money": [2, 4], "windup": 0.4, "anim_k": 1.5},
	"spiderling": {"name": "Паучок", "model": "spider", "size": 0.4, "r": 0.35, "h": 0.45, "hp": 12, "speed": 5.2, "dmg": 5, "reach": 1.0, "ai": "melee", "sight": 12, "weak_spray": 4.0, "money": [0, 1], "windup": 0.3, "anim_k": 1.8},
	"wasp": {"name": "Оса", "model": "wasp", "size": 0.7, "r": 0.4, "h": 0.7, "hp": 16, "speed": 5.0, "dmg": 6, "reach": 1.3, "ai": "flyer", "fly": 1.5, "sight": 12, "weak_spray": 3.5, "money": [1, 2], "windup": 0.35},
	"gopnik": {"name": "Пакостник", "human": GOP1, "r": 0.4, "h": 1.8, "hp": 55, "speed": 3.9, "dmg": 10, "reach": 1.6, "ai": "melee", "sight": 10, "money": [4, 8], "windup": 0.42, "food": 0.2},
	"gopnik2": {"name": "Пакостник", "human": GOP2, "r": 0.4, "h": 1.8, "hp": 48, "speed": 4.5, "dmg": 8, "reach": 1.6, "ai": "melee", "sight": 10, "money": [3, 7], "windup": 0.36, "food": 0.2},
	"soap": {"name": "Мыть", "model": "blob_pink", "size": 0.95, "r": 0.5, "h": 1.0, "hp": 34, "speed": 3.4, "dmg": 8, "reach": 1.4, "ai": "melee", "sight": 10, "money": [2, 4], "windup": 0.4, "colors": {"Pink_Main": Color("f6cfe2"), "Pink_Secondary": Color("ffffff")}, "puddle": true},
	"drone": {"name": "Чистильщик", "model": "drone_fly", "size": 0.9, "r": 0.5, "h": 0.9, "hp": 38, "speed": 4.0, "dmg": 8, "reach": 9.0, "ai": "flyer_shooter", "fly": 1.9, "sight": 13, "shot": "bubble", "shot_speed": 9.0, "cd": 2.2, "money": [3, 6], "colors": {"Main": Color("eef4f8"), "Main2": Color("58b8e8")}},
	"drone_walk": {"name": "Полотёр", "model": "drone_walk", "size": 1.0, "r": 0.55, "h": 1.0, "hp": 60, "speed": 4.3, "dmg": 11, "reach": 1.6, "ai": "charger", "dash": 11.0, "sight": 11, "money": [4, 7], "windup": 0.5, "colors": {"Main": Color("eef4f8"), "Main2": Color("58b8e8")}},
	"snowblob": {"name": "Снежная пакость", "model": "blob_yeti", "size": 1.0, "r": 0.5, "h": 1.0, "hp": 42, "speed": 3.6, "dmg": 9, "reach": 1.4, "ai": "melee", "sight": 10, "money": [3, 5], "windup": 0.4, "shot": "snow"},
	"wolf": {"name": "Волк", "model": "wolf", "size": 0.95, "r": 0.55, "h": 1.0, "hp": 55, "speed": 5.2, "dmg": 12, "reach": 1.6, "ai": "charger", "dash": 12.0, "sight": 13, "money": [2, 5], "windup": 0.45},
	"steamer": {"name": "Парильщик", "model": "yeti", "size": 1.9, "r": 0.6, "h": 1.9, "hp": 95, "speed": 3.3, "dmg": 16, "reach": 2.0, "ai": "melee", "sight": 10, "money": [6, 10], "windup": 0.55, "armor": true, "colors": {"Yeti_Main": Color("e89a88"), "Yeti_Secondary": Color("c87868")}, "food": 0.3},
	"skull": {"name": "Жмурик", "model": "skull", "size": 0.75, "r": 0.4, "h": 0.8, "hp": 30, "speed": 4.2, "dmg": 9, "reach": 1.3, "ai": "leaper", "sight": 11, "money": [2, 4], "windup": 0.35},
	"jmur": {"name": "Жмур", "model": "ghost_skull", "size": 1.4, "r": 0.5, "h": 1.4, "hp": 46, "speed": 3.6, "dmg": 11, "reach": 1.6, "ai": "flyer", "fly": 1.0, "sight": 12, "money": [3, 6], "windup": 0.45, "colors": {"Ghost_Main": Color("b8f0d0")}},
	"zombie": {"name": "Жилец", "human": ZOMBIE, "r": 0.4, "h": 1.8, "hp": 70, "speed": 2.4, "dmg": 13, "reach": 1.6, "ai": "melee", "sight": 9, "money": [3, 7], "windup": 0.6, "anim_k": 0.7},
	"guard": {"name": "Охранник", "human": GUARD, "r": 0.42, "h": 1.85, "hp": 85, "speed": 4.2, "dmg": 13, "reach": 1.7, "ai": "melee", "sight": 11, "money": [6, 12], "windup": 0.4, "food": 0.2},
	"mushnub": {"name": "Грибень", "model": "mushnub", "size": 0.9, "r": 0.45, "h": 0.9, "hp": 30, "speed": 3.2, "dmg": 7, "reach": 1.3, "ai": "melee", "sight": 9, "money": [1, 3], "windup": 0.4},
	"bee": {"name": "Шершень", "model": "bee", "size": 0.9, "r": 0.45, "h": 0.9, "hp": 30, "speed": 4.6, "dmg": 8, "reach": 8.0, "ai": "flyer_shooter", "fly": 1.7, "sight": 12, "shot": "sting", "shot_speed": 13.0, "cd": 2.0, "weak_spray": 3.0, "money": [2, 4]},
	"pigeon": {"name": "Голубь-пакость", "model": "pigeon", "size": 0.8, "r": 0.4, "h": 0.8, "hp": 20, "speed": 5.0, "dmg": 6, "reach": 1.3, "ai": "flyer", "fly": 1.6, "sight": 11, "money": [1, 3], "windup": 0.35},
}
