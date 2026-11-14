class_name Props
extends RefCounted
## Правила столкновений для моделей окружения: что считать коробкой, что стволом, а что — декором без столкновений.

const NONE := ["Carpet", "Curtains", "Light_Ceiling", "Light_Chandelier", "Light_Small", "Window", "Fork", "Knife", "Spoon", "Plate", "Bathroom_Mirror", "Bathroom_Towel",
	"Bathroom_ToiletPaper", "Grass", "Flower", "Plant_", "Wheat", "Corn", "Lilypad", "Bush", "Street_", "Coin", "Gem_", "Heart", "Star", "Key", "Thunder", "Cloud",
	"Path_", "Smoke", "Door_", "Cable", "Sign_", "Light_", "Antenna", "Pickup_", "Collectible_", "Candle", "Bones", "Torch_wall", "Rope_", "Lettuce", "Pumpkin", "Carrot",
	"Tomato", "Watermelon", "Mushroom", "Apple", "Beet", "Numbers_", "Hay", "Match", "Bandages", "Battery", "Can_", "Compass", "Phone", "Knife", "WaterBottle", "Pan", "Pot",
	"Parchment", "Potion", "Ring", "Scroll", "Necklace", "Snowflake", "Crystal", "Crown", "Chalice", "Book", "Pouch", "Bag", "Bone", "FishBone", "ChickenLeg", "Glove", "Skull", "Gold_Ingots", "Padlock"]
const TRUNK := ["Tree", "Willow", "Streetlight", "TrafficLight", "Sign_Stop", "Sign_NoParking", "Sign_Triangle", "Goal_Flag", "Flag", "Ladder", "Bamboo"]


## Наборы сделаны в разном масштабе; домашняя мебель — вдвое крупнее метра.
static func base_scale(key: String) -> float:
	if key.begins_with("home/"):
		return 0.5
	return 1.0


static func col_for(key: String) -> String:
	var nm := key.get_slice("/", key.get_slice_count("/") - 1)
	for t in TRUNK:
		if nm.begins_with(t) or nm.contains(t):
			return "trunk"
	if key.begins_with("rpg/") or key.begins_with("crops/"):
		return "none"
	for n in NONE:
		if nm.begins_with(n):
			return "none"
	return "box"
