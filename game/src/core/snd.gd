extends Node
## Звук: музыка с плавной сменой, пул коротких эффектов. Файлы ищутся в assets/audio; если файла нет — молчим.

const MUSIC_DIR := "res://assets/audio/music/"
const SFX_DIR := "res://assets/audio/sfx/"
const VOICE_DIR := "res://assets/audio/voice/"   # озвучка реплик: <ключ>.mp3, ключ — voice_key(кто, текст)

## дорожки, под которые музыка боя не включается: у них своё настроение
const NO_FIGHT := ["", "menu", "win", "boss", "boss2"]

var _mus: Array[AudioStreamPlayer] = []
var _cur := 0
var cur_music := ""             # что звучит сейчас
var base_music := ""            # что попросила игра (музыка места или босса)
var fight := false              # идёт драка: поверх музыки места звучит музыка боя
var step_kind := ""             # по чему идём: "", wood, grass, snow, carpet — выбирает звук шага
var _pos := {}                  # дорожка -> [секунда, когда прервали]: вернёмся на то же место
var _variants := {}             # имя звука -> сколько у него вариантов (hit_1, hit_2, …)
var _last_var := {}
var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _cache := {}
var _last := {}                 # имя -> время последнего запуска (чтобы не клеить одинаковые звуки в один кадр)
var music_vol := 0.7
var sfx_vol := 0.9
var played := {}                # для тестов: какие звуки запрашивались
var voice_on := true
var voice_vol := 1.0
var _voice: AudioStreamPlayer
var _duck := 0.0                # насколько приглушена музыка под голос, дБ
var _voice_n := -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus in ["Music", "SFX", "Voice"]:
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
	_voice = AudioStreamPlayer.new()
	_voice.bus = "Voice"
	add_child(_voice)


func set_volumes(m: float, s: float) -> void:
	music_vol = m
	sfx_vol = s
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(maxf(m, 0.0001)) + _duck)
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


## Музыка места или босса ("" — тишина). Если идёт драка, звучит музыка боя, а эта включится после неё.
func music(nm: String, fade := 1.2) -> void:
	base_music = nm
	if nm in NO_FIGHT:
		fight = false
	_switch(_want(), fade)


## Драка началась или кончилась: музыка места уступает музыке боя и потом возвращается на то же место.
func set_fight(on: bool) -> void:
	if fight == on:
		return
	fight = on
	_switch(_want(), 0.7 if on else 1.6)


func _want() -> String:
	if fight and not (base_music in NO_FIGHT) and _stream(MUSIC_DIR, "fight") != null:
		return "fight"
	return base_music


func _switch(nm: String, fade: float) -> void:
	if nm == cur_music:
		return
	var old := _mus[_cur]
	if cur_music != "" and old.playing:
		_pos[cur_music] = [old.get_playback_position(), Time.get_ticks_msec()]
	cur_music = nm
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
	elif st is AudioStreamMP3:
		(st as AudioStreamMP3).loop = true
	neu.stream = st
	neu.volume_db = -40.0
	# к музыке места возвращаемся туда, где её прервала драка (если прошло не больше двух минут)
	var from := 0.0
	if _pos.has(nm) and Time.get_ticks_msec() - int(_pos[nm][1]) < 120000 and nm != "fight":
		from = fmod(float(_pos[nm][0]), maxf(st.get_length() - 0.5, 1.0))
	neu.play(from)
	create_tween().tween_property(neu, "volume_db", 0.0, fade)


func sfx(nm: String, vol_db := 0.0, pitch := 1.0, vary := 0.06) -> void:
	played[nm] = int(played.get(nm, 0)) + 1
	var now := Time.get_ticks_msec()
	if _last.has(nm) and now - int(_last[nm]) < 45:
		return
	_last[nm] = now
	var st := _pick(nm)
	if st == null:
		return
	var p := _pool[_next]
	_next = (_next + 1) % _pool.size()
	p.stream = st
	p.volume_db = vol_db
	p.pitch_scale = maxf(0.2, pitch + randf_range(-vary, vary))
	p.play()


## Запись для звука: шаг зависит от поверхности, у частых звуков несколько вариантов (hit_1, hit_2, …) — берётся
## случайный, но не тот же, что в прошлый раз.
func _pick(nm: String) -> AudioStream:
	if nm == "step" and step_kind != "" and _stream(SFX_DIR, "step_" + step_kind + "_1") != null:
		nm = "step_" + step_kind
	if not _variants.has(nm):
		var n := 0
		while _stream(SFX_DIR, "%s_%d" % [nm, n + 1]) != null:
			n += 1
		_variants[nm] = n
	var cnt: int = _variants[nm]
	if cnt == 0:
		return _stream(SFX_DIR, nm)
	var i := randi() % cnt
	if cnt > 1 and i == int(_last_var.get(nm, -1)):
		i = (i + 1) % cnt
	_last_var[nm] = i
	return _stream(SFX_DIR, "%s_%d" % [nm, i + 1])


func has_music(nm: String) -> bool:
	return _stream(MUSIC_DIR, nm) != null


## Есть ли запись для звука (одна или варианты).
func has_sfx(nm: String) -> bool:
	return _stream(SFX_DIR, nm) != null or _stream(SFX_DIR, nm + "_1") != null


## Короткий «голос» в диалоге: один и тот же звук с разной высотой.
func blip(pitch := 1.0) -> void:
	sfx("blip", -8.0, pitch, 0.12)


# ---------- озвучка реплик ----------

## Ключ реплики: по нему ищется запись. Тот же расчёт — в tools/voice/extract_lines.py.
static func voice_key(who: Variant, text: String) -> String:
	var w := String((who as Dictionary).get("n", "")) if who is Dictionary else String(who)
	return (w + "|" + text).md5_text().substr(0, 12)


## Сколько реплик озвучено (файлов в папке озвучки).
func voice_count() -> int:
	if _voice_n < 0:
		var seen := {}
		for f in DirAccess.get_files_at(VOICE_DIR):
			if f.ends_with(".mp3") or f.ends_with(".mp3.import") or f.ends_with(".mp3.remap"):
				seen[f.get_slice(".", 0)] = true
		_voice_n = seen.size()
	return _voice_n


func set_voice(on: bool, vol: float) -> void:
	voice_on = on
	voice_vol = vol
	var i := AudioServer.get_bus_index("Voice")
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(vol, 0.0001)))
	AudioServer.set_bus_mute(i, vol <= 0.001)
	if not on:
		voice_stop()


## Произнести реплику, если она озвучена и озвучка включена. Возвращает длину записи (0 — записи нет).
func voice(who: Variant, text: String) -> float:
	voice_stop()
	if not voice_on:
		return 0.0
	var path := VOICE_DIR + voice_key(who, text) + ".mp3"
	if not ResourceLoader.exists(path):
		return 0.0
	var st: AudioStream = load(path)
	if st == null:
		return 0.0
	_voice.stream = st
	_voice.play()
	return st.get_length()


func voice_stop() -> void:
	if _voice and _voice.playing:
		_voice.stop()


func voice_playing() -> bool:
	return _voice != null and _voice.playing


func _process(dt: float) -> void:
	# музыка тише, пока звучит голос
	var want := -8.0 if voice_playing() else 0.0
	if absf(_duck - want) > 0.05:
		_duck = move_toward(_duck, want, dt * 30.0)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(maxf(music_vol, 0.0001)) + _duck)
