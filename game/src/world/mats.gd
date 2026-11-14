class_name Mats
extends RefCounted
## Материалы. Текстуры лежат в assets/tex и накладываются в мировых координатах (triplanar),
## поэтому любой ящик любого размера получает ровную плитку без ручной развёртки.

const TEX_DIR := "res://assets/tex/"
## имя -> { tex, tile (метров на плитку), color (оттенок), rough, metal, emit, energy }
const DEFS := {
	"asphalt": {"tex": "asphalt", "tile": 4.0, "rough": 0.95},
	"asphalt_wet": {"tex": "asphalt", "tile": 4.0, "rough": 0.35, "color": Color(0.75, 0.78, 0.85)},
	"concrete": {"tex": "concrete", "tile": 4.0, "rough": 0.9},
	"concrete_dark": {"tex": "concrete", "tile": 4.0, "rough": 0.9, "color": Color(0.55, 0.56, 0.6)},
	"panel": {"tex": "panel", "tile": 3.0, "rough": 0.9},
	"brick": {"tex": "brick", "tile": 2.0, "rough": 0.9},
	"brick_white": {"tex": "brick", "tile": 2.0, "rough": 0.9, "color": Color(1.5, 1.6, 1.7)},
	"plaster": {"tex": "plaster", "tile": 3.0, "rough": 0.95},
	"plaster_green": {"tex": "plaster", "tile": 3.0, "rough": 0.8, "color": Color(0.42, 0.62, 0.5)},
	"plaster_blue": {"tex": "plaster", "tile": 3.0, "rough": 0.8, "color": Color(0.45, 0.58, 0.75)},
	"plaster_beige": {"tex": "plaster", "tile": 3.0, "rough": 0.95, "color": Color(0.9, 0.82, 0.66)},
	"plaster_pink": {"tex": "plaster", "tile": 3.0, "rough": 0.95, "color": Color(0.92, 0.7, 0.72)},
	"plaster_dark": {"tex": "plaster", "tile": 3.0, "rough": 0.95, "color": Color(0.3, 0.3, 0.34)},
	"ceiling": {"tex": "plaster", "tile": 3.0, "rough": 1.0, "color": Color(0.82, 0.82, 0.8)},
	"wallpaper": {"tex": "wallpaper", "tile": 2.0, "rough": 0.95},
	"wood": {"tex": "wood", "tile": 2.0, "rough": 0.7},
	"wood_dark": {"tex": "wood", "tile": 2.0, "rough": 0.7, "color": Color(0.55, 0.42, 0.35)},
	"planks": {"tex": "planks", "tile": 2.5, "rough": 0.8},
	"logs": {"tex": "logs", "tile": 2.4, "rough": 0.85},
	"lino": {"tex": "lino", "tile": 2.0, "rough": 0.5},
	"tiles": {"tex": "tiles", "tile": 1.6, "rough": 0.25},
	"tiles_blue": {"tex": "tiles", "tile": 1.6, "rough": 0.2, "color": Color(0.62, 0.84, 0.95)},
	"tiles_green": {"tex": "tiles", "tile": 1.6, "rough": 0.3, "color": Color(0.6, 0.85, 0.7)},
	"mosaic": {"tex": "mosaic", "tile": 2.0, "rough": 0.2},
	"metal": {"tex": "metal", "tile": 2.0, "rough": 0.45, "metal": 0.6},
	"metal_dark": {"tex": "metal", "tile": 2.0, "rough": 0.5, "metal": 0.6, "color": Color(0.35, 0.36, 0.4)},
	"rust": {"tex": "rust", "tile": 2.5, "rough": 0.9},
	"garage": {"tex": "garage", "tile": 3.0, "rough": 0.7, "metal": 0.3},
	"roof": {"tex": "roof", "tile": 2.0, "rough": 0.8},
	"grass": {"tex": "grass", "tile": 5.0, "rough": 1.0},
	"grass_dry": {"tex": "grass", "tile": 5.0, "rough": 1.0, "color": Color(1.1, 0.95, 0.6)},
	"dirt": {"tex": "dirt", "tile": 4.0, "rough": 1.0},
	"earth_wall": {"tex": "dirt", "tile": 3.0, "rough": 1.0, "color": Color(0.62, 0.5, 0.42)},
	"earth_floor": {"tex": "dirt", "tile": 5.0, "rough": 1.0, "color": Color(0.58, 0.47, 0.4)},
	"sand": {"tex": "dirt", "tile": 4.0, "rough": 1.0, "color": Color(1.5, 1.35, 1.0)},
	"snow": {"tex": "snow", "tile": 6.0, "rough": 0.85, "color": Color(0.84, 0.87, 0.93)},
	"clean_ground": {"tex": "concrete", "tile": 4.0, "rough": 0.95, "color": Color(0.48, 0.53, 0.6)},
	"clean_floor": {"tex": "tiles", "tile": 2.0, "rough": 0.75, "color": Color(0.48, 0.55, 0.63)},
	"clean_tiles": {"tex": "tiles", "tile": 1.6, "rough": 0.7, "color": Color(0.5, 0.6, 0.68)},
	"clean_wall": {"tex": "plaster", "tile": 3.0, "rough": 0.95, "color": Color(0.64, 0.69, 0.76)},
	"clean_white": {"color": Color(0.6, 0.65, 0.72), "rough": 0.7},
	"marble_soft": {"tex": "marble", "tile": 3.0, "rough": 0.5, "color": Color(0.6, 0.63, 0.7)},
	"mosaic_soft": {"tex": "mosaic", "tile": 5.0, "rough": 0.7, "color": Color(0.36, 0.42, 0.5)},
	"ice": {"tex": "ice", "tile": 5.0, "rough": 0.08},
	"carpet": {"tex": "carpet", "tile": 2.0, "rough": 1.0},
	"marble": {"tex": "marble", "tile": 3.0, "rough": 0.15},
	"black": {"color": Color(0.03, 0.03, 0.04), "rough": 0.9},
	"white": {"color": Color(0.92, 0.92, 0.92), "rough": 0.8},
	"red": {"color": Color(0.75, 0.12, 0.1), "rough": 0.6},
	"yellow": {"color": Color(1.0, 0.82, 0.12), "rough": 0.6},
	"gold": {"color": Color(1.0, 0.76, 0.2), "rough": 0.25, "metal": 0.9},
	"glass": {"color": Color(0.5, 0.75, 0.9, 0.35), "rough": 0.05},
	"water": {"color": Color(0.11, 0.42, 0.55, 0.82), "rough": 0.05, "metal": 0.3},
	"milk": {"color": Color(0.95, 0.95, 0.9, 0.95), "rough": 0.2},
}

static var _cache := {}


static func get_mat(key: Variant) -> Material:
	if key is Material:
		return key
	if key is Color:
		return flat(key)
	var nm := String(key)
	if _cache.has(nm):
		return _cache[nm]
	var d: Dictionary = DEFS.get(nm, {})
	var m := StandardMaterial3D.new()
	m.resource_name = nm
	var col: Color = d.get("color", Color.WHITE)
	m.albedo_color = col
	if d.has("tex"):
		var path := TEX_DIR + String(d["tex"]) + ".png"
		if ResourceLoader.exists(path):
			m.albedo_texture = load(path)
			m.uv1_triplanar = true
			m.uv1_world_triplanar = true
			var tile: float = d.get("tile", 2.0)
			m.uv1_scale = Vector3.ONE / tile
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.roughness = d.get("rough", 0.8)
	m.metallic = d.get("metal", 0.0)
	if col.a < 0.99:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if d.has("emit"):
		m.emission_enabled = true
		m.emission = d["emit"]
		m.emission_energy_multiplier = d.get("energy", 1.0)
	_cache[nm] = m
	return m


## Однотонный материал.
static func flat(col: Color, rough := 0.8, metal := 0.0) -> StandardMaterial3D:
	var key := "flat:%s:%.2f:%.2f" % [col.to_html(), rough, metal]
	if _cache.has(key):
		return _cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	m.metallic = metal
	if col.a < 0.99:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_cache[key] = m
	return m


## Светящийся материал (лампы, неон, экраны).
static func glow(col: Color, energy := 2.0) -> StandardMaterial3D:
	var key := "glow:%s:%.2f" % [col.to_html(), energy]
	if _cache.has(key):
		return _cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = energy
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED if energy <= 1.0 else BaseMaterial3D.SHADING_MODE_PER_PIXEL
	_cache[key] = m
	return m


## Материал с обычной развёрткой (фасады домов, двери): текстура + необязательное свечение из отдельной карты.
static func uv(tex: String, emit_tex := "", energy := 1.0, tint := Color.WHITE) -> StandardMaterial3D:
	var key := "uv:%s:%s:%.2f:%s" % [tex, emit_tex, energy, tint.to_html()]
	if _cache.has(key):
		return _cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = tint
	if ResourceLoader.exists(TEX_DIR + tex + ".png"):
		m.albedo_texture = load(TEX_DIR + tex + ".png")
	m.roughness = 0.85
	if emit_tex != "" and ResourceLoader.exists(TEX_DIR + emit_tex + ".png"):
		m.emission_enabled = true
		m.emission_texture = load(TEX_DIR + emit_tex + ".png")
		m.emission = Color.BLACK          # к цвету прибавляется карта свечения: горят только окна
		m.emission_energy_multiplier = energy
	_cache[key] = m
	return m
