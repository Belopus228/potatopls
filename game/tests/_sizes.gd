extends RefCounted
## Служебное: размеры всех моделей окружения в /tmp/prop_sizes.txt (чтобы расставлять мебель не вслепую).


func run(_t) -> void:
	var out := PackedStringArray()
	_scan("res://assets/props", out)
	out.sort()
	var f := FileAccess.open("/tmp/prop_sizes.txt", FileAccess.WRITE)
	if f:
		f.store_string("\n".join(out))
		f.close()
	print("[T] props: ", out.size())


func _scan(dir: String, out: PackedStringArray) -> void:
	for d in DirAccess.get_directories_at(dir):
		_scan(dir + "/" + d, out)
	for fn in DirAccess.get_files_at(dir):
		if not fn.ends_with(".glb"):
			continue
		var key := (dir + "/" + fn).trim_prefix("res://assets/props/").trim_suffix(".glb")
		var a := Level.prop_aabb(key)
		out.append("%s %.1f×%.1f×%.1f" % [key, a.size.x, a.size.y, a.size.z])
