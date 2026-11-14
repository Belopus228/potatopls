class_name Grade
extends CanvasLayer
## Цветокоррекция кадра: виньетка, чуть больше насыщенности и контраста, лёгкое зерно и дизеринг.
## Дешёвый способ сделать картинку «дороже» там, где нет постобработки: рендерер Compatibility.
## Слой ниже интерфейса (5 против 10), чтобы меню и HUD оставались чёткими.

const SHADER := """
shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;

// strength — общая сила эффекта (0 — выключено), night — доля вечернего холода
uniform float strength : hint_range(0.0, 1.0) = 1.0;
uniform float sat : hint_range(0.5, 1.5) = 1.08;
uniform float contrast : hint_range(0.5, 1.5) = 1.06;
uniform float vignette : hint_range(0.0, 1.5) = 0.55;
uniform float grain : hint_range(0.0, 0.2) = 0.018;
uniform vec3 tint = vec3(1.0, 1.0, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec3 c = textureLod(screen_tex, SCREEN_UV, 0.0).rgb;
	// насыщенность и мягкий контраст вокруг середины
	float l = dot(c, vec3(0.2126, 0.7152, 0.0722));
	c = mix(vec3(l), c, mix(1.0, sat, strength));
	c = mix(c, c * c * (3.0 - 2.0 * c), (contrast - 1.0) * 2.0 * strength);
	c *= mix(vec3(1.0), tint, strength);
	// виньетка от центра
	vec2 d = SCREEN_UV - 0.5;
	float v = 1.0 - dot(d, d) * vignette * 1.8 * strength;
	c *= clamp(v, 0.0, 1.0);
	// зерно и дизеринг: убирают полосы на градиентах неба
	float n = hash(SCREEN_UV * 1024.0 + TIME) - 0.5;
	c += n * (grain * strength + 1.0 / 255.0);
	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0);
}
"""

var rect: ColorRect
var mat: ShaderMaterial


func _ready() -> void:
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS
	rect = ColorRect.new()
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.color = Color.WHITE
	mat = ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = SHADER
	mat.shader = sh
	rect.material = mat
	add_child(rect)
	visible = false


## Настройка под сцену: ночью картинка холоднее и контрастнее, днём мягче, в интерьере — обычная.
func apply_env(env_name: String) -> void:
	var on: bool = G.quality >= 1
	visible = on
	if not on:
		return
	var p := {"sat": 1.06, "contrast": 1.05, "vignette": 0.5, "tint": Color(1, 1, 1), "grain": 0.016}
	match env_name:
		"night", "grave":
			p = {"sat": 1.12, "contrast": 1.1, "vignette": 0.85, "tint": Color(0.94, 0.97, 1.08), "grain": 0.022}
		"snow", "day", "clean":
			p = {"sat": 1.03, "contrast": 0.98, "vignette": 0.35, "tint": Color(1.02, 1.0, 0.97), "grain": 0.012}
		"indoor", "dusk":
			p = {"sat": 1.07, "contrast": 1.05, "vignette": 0.6, "tint": Color(1.03, 1.0, 0.97), "grain": 0.014}
		"fog":
			p = {"sat": 0.92, "contrast": 1.0, "vignette": 0.7, "tint": Color(0.98, 1.0, 1.04), "grain": 0.02}
	mat.set_shader_parameter("sat", p["sat"])
	mat.set_shader_parameter("contrast", p["contrast"])
	mat.set_shader_parameter("vignette", p["vignette"])
	mat.set_shader_parameter("tint", p["tint"])
	mat.set_shader_parameter("grain", p["grain"])
