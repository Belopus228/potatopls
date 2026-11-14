extends Node
## Звук: музыка с плавной сменой, пул коротких эффектов. Файлы ищутся в assets/audio; если файла нет — молчим.

const MUSIC_DIR := "res://assets/audio/music/"
const SFX_DIR := "res://assets/audio/sfx/"

var _mus: Array[AudioStreamPlayer] = []
var _cur := 0
var cur_music := ""
var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _cache := {}
var _last := {}                 # имя -> время последнего запуска (чтобы не клеить одинаковые звуки в один кадр)
var music_vol := 0.7
var sfx_vol := 0.9
var played := {}                # для тестов: какие звуки запрашивались


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.bus = "Music"
		p.volume_db = -60.0
		add_child(p)
		_mus.append(p)
	for i in 14:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pool.append(p)


func set_volumes(m: float, s: float) -> void:
	music_vol = m
	sfx_vol = s
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(maxf(m, 0.0001)))
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), m <= 0.001)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(maxf(s, 0.0001)))
	AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"), s <= 0.001)


func _stream(dir: String, nm: String) -> AudioStream:
	var key := dir + nm
	if _cache.has(key):
		return _cache[key]
	var st: AudioStream = null
	for ext in [".ogg", ".wav", ".mp3"]:
		if ResourceLoader.exists(key + ext):
			st = load(key + ext)
			break
	_cache[key] = st
	return st


## Сменить музыку ("" — тишина).
func music(nm: String, fade := 1.2) -> void:
	if nm == cur_music:
		return
	cur_music = nm
	var old := _mus[_cur]
	_cur = 1 - _cur
	var neu := _mus[_cur]
	var tw := create_tween().set_parallel(true)
	tw.tween_property(old, "volume_db", -60.0, fade)
	tw.chain().tween_callback(old.stop)
	if nm == "":
		return
	var st := _stream(MUSIC_DIR, nm)
	if st == null:
		return
	if st is AudioStreamOggVorbis:
		(st as AudioStreamOggVorbis).loop = true
	neu.stream = st
	neu.volume_db = -40.0
	neu.play()
	create_tween().tween_property(neu, "volume_db", 0.0, fade)


func sfx(nm: String, vol_db := 0.0, pitch := 1.0, vary := 0.06) -> void:
	played[nm] = int(played.get(nm, 0)) + 1
	var now := Time.get_ticks_msec()
	if _last.has(nm) and now - int(_last[nm]) < 45:
		return
	_last[nm] = now
	var st := _stream(SFX_DIR, nm)
	if st == null:
		return
	var p := _pool[_next]
	_next = (_next + 1) % _pool.size()
	p.stream = st
	p.volume_db = vol_db
	p.pitch_scale = maxf(0.2, pitch + randf_range(-vary, vary))
	p.play()


## Короткий «голос» в диалоге: один и тот же звук с разной высотой.
func blip(pitch := 1.0) -> void:
	sfx("blip", -8.0, pitch, 0.12)
