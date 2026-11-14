class_name Poses
extends RefCounted
## Дополнительные клипы для людей, которых нет в наборе Quaternius: сидеть, на корточках,
## прыжок, падение, крик, танец, победа, телефон. Позы задаются направлениями костей в
## пространстве модели (+Z — вперёд, +X — влево, +Y — вверх) и превращаются в обычные Animation.

const POS_BONES := ["Body", "Foot.L", "Foot.R"]

# --- позы ---
const SIT := {
	"body": Vector3(0, -0.39, -0.06), "flat": true,
	"rot": {"Chest": Vector3(6, 0, 0)},
	"aim": {
		"UpperLeg.L": Vector3(0.16, -0.06, 1), "UpperLeg.R": Vector3(-0.16, -0.06, 1),
		"LowerLeg.L": Vector3(0.02, -1, 0.1), "LowerLeg.R": Vector3(-0.02, -1, 0.1),
		"UpperArm.L": Vector3(0.2, -0.95, 0.2), "UpperArm.R": Vector3(-0.2, -0.95, 0.2),
		"LowerArm.L": Vector3(-0.04, -0.4, 0.92), "LowerArm.R": Vector3(0.04, -0.4, 0.92),
	},
}
const SIT_B := {
	"body": Vector3(0, -0.395, -0.06), "flat": true,
	"rot": {"Chest": Vector3(8.5, 0, 0), "Head": Vector3(3, 0, 0)},
	"aim": {
		"UpperLeg.L": Vector3(0.16, -0.06, 1), "UpperLeg.R": Vector3(-0.16, -0.06, 1),
		"LowerLeg.L": Vector3(0.02, -1, 0.1), "LowerLeg.R": Vector3(-0.02, -1, 0.1),
		"UpperArm.L": Vector3(0.2, -0.95, 0.22), "UpperArm.R": Vector3(-0.2, -0.95, 0.22),
		"LowerArm.L": Vector3(-0.04, -0.42, 0.92), "LowerArm.R": Vector3(0.04, -0.42, 0.92),
	},
}
# «посидим» в баньке: руки раскинуты по спинке лавки
const STEAM := {
	"body": Vector3(0, -0.39, -0.1), "flat": true,
	"rot": {"Chest": Vector3(-8, 0, 0), "Head": Vector3(-10, 0, 0)},
	"aim": {
		"UpperLeg.L": Vector3(0.3, -0.05, 1), "UpperLeg.R": Vector3(-0.3, -0.05, 1),
		"LowerLeg.L": Vector3(0.05, -1, 0.25), "LowerLeg.R": Vector3(-0.05, -1, 0.25),
		"UpperArm.L": Vector3(1, 0.05, -0.15), "UpperArm.R": Vector3(-1, 0.05, -0.15),
		"LowerArm.L": Vector3(1, -0.2, 0.1), "LowerArm.R": Vector3(-1, -0.2, 0.1),
	},
}
const STEAM_B := {
	"body": Vector3(0, -0.395, -0.1), "flat": true,
	"rot": {"Chest": Vector3(-6, 0, 0), "Head": Vector3(-14, 0, 0)},
	"aim": {
		"UpperLeg.L": Vector3(0.3, -0.05, 1), "UpperLeg.R": Vector3(-0.3, -0.05, 1),
		"LowerLeg.L": Vector3(0.05, -1, 0.25), "LowerLeg.R": Vector3(-0.05, -1, 0.25),
		"UpperArm.L": Vector3(1, 0.07, -0.15), "UpperArm.R": Vector3(-1, 0.07, -0.15),
		"LowerArm.L": Vector3(1, -0.2, 0.1), "LowerArm.R": Vector3(-1, -0.2, 0.1),
	},
}
# на корточках
const SQUAT := {
	"body": Vector3(0, -0.5, -0.12), "flat": true,
	"rot": {"Body": Vector3(18, 0, 0), "Head": Vector3(-12, 0, 0)},
	"aim": {
		"UpperLeg.L": Vector3(0.42, 0.3, 0.9), "UpperLeg.R": Vector3(-0.42, 0.3, 0.9),
		"LowerLeg.L": Vector3(-0.12, -1, -0.42), "LowerLeg.R": Vector3(0.12, -1, -0.42),
		"UpperArm.L": Vector3(0.3, -0.3, 0.9), "UpperArm.R": Vector3(-0.3, -0.3, 0.9),
		"LowerArm.L": Vector3(-0.35, -0.25, 0.9), "LowerArm.R": Vector3(0.35, -0.25, 0.9),
	},
}
const SQUAT_B := {
	"body": Vector3(0, -0.51, -0.12), "flat": true,
	"rot": {"Body": Vector3(20, 0, 0), "Head": Vector3(-14, 4, 0)},
	"aim": {
		"UpperLeg.L": Vector3(0.42, 0.3, 0.9), "UpperLeg.R": Vector3(-0.42, 0.3, 0.9),
		"LowerLeg.L": Vector3(-0.12, -1, -0.42), "LowerLeg.R": Vector3(0.12, -1, -0.42),
		"UpperArm.L": Vector3(0.3, -0.32, 0.9), "UpperArm.R": Vector3(-0.3, -0.32, 0.9),
		"LowerArm.L": Vector3(-0.35, -0.27, 0.9), "LowerArm.R": Vector3(0.35, -0.27, 0.9),
	},
}
const JUMP_A := {      # толчок
	"body": Vector3(0, -0.12, 0),
	"rot": {"Body": Vector3(10, 0, 0)},
	"aim": {
		"UpperLeg.L": Vector3(0.12, -0.85, 0.5), "UpperLeg.R": Vector3(-0.12, -0.85, 0.5),
		"LowerLeg.L": Vector3(0.05, -0.85, -0.5), "LowerLeg.R": Vector3(-0.05, -0.85, -0.5),
		"UpperArm.L": Vector3(0.35, -0.8, -0.45), "UpperArm.R": Vector3(-0.35, -0.8, -0.45),
		"LowerArm.L": Vector3(0.2, -0.9, -0.2), "LowerArm.R": Vector3(-0.2, -0.9, -0.2),
	},
}
const JUMP_B := {      # взлёт
	"body": Vector3(0, 0.02, 0),
	"rot": {"Body": Vector3(-4, 0, 0), "Head": Vector3(-8, 0, 0)},
	"aim": {
		"UpperLeg.L": Vector3(0.1, -0.8, 0.6), "UpperLeg.R": Vector3(-0.1, -1, -0.15),
		"LowerLeg.L": Vector3(0.05, -0.75, -0.65), "LowerLeg.R": Vector3(-0.05, -0.95, -0.3),
		"UpperArm.L": Vector3(0.8, 0.5, 0.25), "UpperArm.R": Vector3(-0.8, 0.5, 0.25),
		"LowerArm.L": Vector3(0.6, 0.8, 0.15), "LowerArm.R": Vector3(-0.6, 0.8, 0.15),
	},
}
const FALL_A := {
	"rot": {"Body": Vector3(6, 0, 0)},
	"aim": {
		"UpperLeg.L": Vector3(0.28, -0.92, 0.25), "UpperLeg.R": Vector3(-0.28, -0.95, 0.0),
		"LowerLeg.L": Vector3(0.12, -0.9, -0.4), "LowerLeg.R": Vector3(-0.12, -0.92, -0.35),
		"UpperArm.L": Vector3(0.9, 0.4, 0.1), "UpperArm.R": Vector3(-0.9, 0.3, 0.1),
		"LowerArm.L": Vector3(0.85, 0.55, 0.15), "LowerArm.R": Vector3(-0.88, 0.5, 0.15),
	},
}
const FALL_B := {
	"rot": {"Body": Vector3(8, 0, 0)},
	"aim": {
		"UpperLeg.L": Vector3(0.28, -0.95, 0.05), "UpperLeg.R": Vector3(-0.28, -0.92, 0.22),
		"LowerLeg.L": Vector3(0.12, -0.92, -0.35), "LowerLeg.R": Vector3(-0.12, -0.9, -0.4),
		"UpperArm.L": Vector3(0.9, 0.28, 0.1), "UpperArm.R": Vector3(-0.9, 0.42, 0.1),
		"LowerArm.L": Vector3(0.88, 0.48, 0.15), "LowerArm.R": Vector3(-0.85, 0.57, 0.15),
	},
}
const SHOUT_A := {     # «АМ-АМ-АМ»
	"body": Vector3(0, -0.06, 0),
	"rot": {"Body": Vector3(-10, 0, 0), "Head": Vector3(-16, 0, 0)},
	"aim": {
		"UpperLeg.L": Vector3(0.32, -0.95, 0.05), "UpperLeg.R": Vector3(-0.32, -0.95, 0.05),
		"LowerLeg.L": Vector3(0.1, -1, -0.1), "LowerLeg.R": Vector3(-0.1, -1, -0.1),
		"UpperArm.L": Vector3(0.7, -0.68, -0.12), "UpperArm.R": Vector3(-0.7, -0.68, -0.12),
		"LowerArm.L": Vector3(0.5, -0.3, 0.82), "LowerArm.R": Vector3(-0.5, -0.3, 0.82),
	},
}
const SHOUT_B := {
	"body": Vector3(0, -0.03, 0),
	"rot": {"Body": Vector3(-14, 0, 0), "Head": Vector3(-22, 0, 0)},
	"aim": {
		"UpperLeg.L": Vector3(0.32, -0.95, 0.05), "UpperLeg.R": Vector3(-0.32, -0.95, 0.05),
		"LowerLeg.L": Vector3(0.1, -1, -0.1), "LowerLeg.R": Vector3(-0.1, -1, -0.1),
		"UpperArm.L": Vector3(0.75, -0.6, -0.15), "UpperArm.R": Vector3(-0.75, -0.6, -0.15),
		"LowerArm.L": Vector3(0.55, -0.2, 0.82), "LowerArm.R": Vector3(-0.55, -0.2, 0.82),
	},
}
const DANCE_A := {
	"body": Vector3(0.06, -0.06, 0),
	"rot": {"Body": Vector3(0, 10, -5), "Head": Vector3(0, -8, 4)},
	"aim": {
		"UpperLeg.L": Vector3(0.2, -0.97, 0.12), "UpperLeg.R": Vector3(-0.22, -0.95, 0.2),
		"LowerLeg.L": Vector3(0.05, -1, -0.1), "LowerLeg.R": Vector3(-0.1, -0.9, -0.4),
		"UpperArm.L": Vector3(0.7, 0.55, 0.3), "UpperArm.R": Vector3(-0.6, -0.6, 0.45),
		"LowerArm.L": Vector3(0.2, 0.95, 0.3), "LowerArm.R": Vector3(-0.2, 0.3, 0.95),
	},
}
const DANCE_B := {
	"body": Vector3(-0.06, -0.06, 0),
	"rot": {"Body": Vector3(0, -10, 5), "Head": Vector3(0, 8, -4)},
	"aim": {
		"UpperLeg.L": Vector3(0.22, -0.95, 0.2), "UpperLeg.R": Vector3(-0.2, -0.97, 0.12),
		"LowerLeg.L": Vector3(0.1, -0.9, -0.4), "LowerLeg.R": Vector3(-0.05, -1, -0.1),
		"UpperArm.L": Vector3(0.6, -0.6, 0.45), "UpperArm.R": Vector3(-0.7, 0.55, 0.3),
		"LowerArm.L": Vector3(0.2, 0.3, 0.95), "LowerArm.R": Vector3(-0.2, 0.95, 0.3),
	},
}
const DANCE_M := {
	"body": Vector3(0, -0.01, 0),
	"aim": {
		"UpperLeg.L": Vector3(0.2, -0.98, 0.08), "UpperLeg.R": Vector3(-0.2, -0.98, 0.08),
		"LowerLeg.L": Vector3(0.06, -1, -0.12), "LowerLeg.R": Vector3(-0.06, -1, -0.12),
		"UpperArm.L": Vector3(0.75, -0.1, 0.4), "UpperArm.R": Vector3(-0.75, -0.1, 0.4),
		"LowerArm.L": Vector3(0.25, 0.7, 0.65), "LowerArm.R": Vector3(-0.25, 0.7, 0.65),
	},
}
const CHEER_A := {
	"body": Vector3(0, -0.07, 0),
	"aim": {
		"UpperLeg.L": Vector3(0.15, -0.95, 0.25), "UpperLeg.R": Vector3(-0.15, -0.95, 0.25),
		"LowerLeg.L": Vector3(0.05, -0.92, -0.38), "LowerLeg.R": Vector3(-0.05, -0.92, -0.38),
		"UpperArm.L": Vector3(0.55, 0.75, 0.2), "UpperArm.R": Vector3(-0.55, 0.75, 0.2),
		"LowerArm.L": Vector3(0.35, 0.9, 0.1), "LowerArm.R": Vector3(-0.35, 0.9, 0.1),
	},
}
const CHEER_B := {
	"body": Vector3(0, 0.05, 0),
	"rot": {"Head": Vector3(-10, 0, 0)},
	"aim": {
		"UpperLeg.L": Vector3(0.14, -1, 0.04), "UpperLeg.R": Vector3(-0.14, -1, 0.04),
		"LowerLeg.L": Vector3(0.05, -1, -0.08), "LowerLeg.R": Vector3(-0.05, -1, -0.08),
		"UpperArm.L": Vector3(0.4, 0.9, 0.1), "UpperArm.R": Vector3(-0.4, 0.9, 0.1),
		"LowerArm.L": Vector3(0.2, 1, 0.05), "LowerArm.R": Vector3(-0.2, 1, 0.05),
	},
}
const PHONE := {       # телефон у правого уха
	"rot": {"Head": Vector3(0, 0, 6)},
	"aim": {
		"UpperArm.R": Vector3(-0.55, -0.6, 0.6), "LowerArm.R": Vector3(0.25, 0.95, -0.1),
	},
}
const PHONE_B := {
	"rot": {"Head": Vector3(3, 6, 6), "Chest": Vector3(2, 0, 0)},
	"aim": {
		"UpperArm.R": Vector3(-0.55, -0.62, 0.6), "LowerArm.R": Vector3(0.25, 0.95, -0.08),
	},
}


static func add_human_clips(lib: AnimationLibrary, scene: Node3D, sk: Skeleton3D) -> void:
	var b := Builder.new(scene, sk, lib.get_animation("Idle") if lib.has_animation("Idle") else null)
	lib.add_animation("Sit", b.make(3.2, true, [[0.0, SIT], [1.6, SIT_B], [3.2, SIT]]))
	lib.add_animation("Steam", b.make(3.6, true, [[0.0, STEAM], [1.8, STEAM_B], [3.6, STEAM]]))
	lib.add_animation("Squat", b.make(3.0, true, [[0.0, SQUAT], [1.5, SQUAT_B], [3.0, SQUAT]]))
	lib.add_animation("Jump", b.make(0.34, false, [[0.0, JUMP_A], [0.16, JUMP_B], [0.34, JUMP_B]]))
	lib.add_animation("Fall", b.make(0.7, true, [[0.0, FALL_A], [0.35, FALL_B], [0.7, FALL_A]]))
	lib.add_animation("Shout", b.make(0.36, true, [[0.0, SHOUT_A], [0.18, SHOUT_B], [0.36, SHOUT_A]]))
	lib.add_animation("Dance", b.make(1.0, true, [[0.0, DANCE_A], [0.25, DANCE_M], [0.5, DANCE_B], [0.75, DANCE_M], [1.0, DANCE_A]]))
	lib.add_animation("Cheer", b.make(0.7, true, [[0.0, CHEER_A], [0.35, CHEER_B], [0.7, CHEER_A]]))
	lib.add_animation("Phone", b.make(2.4, true, [[0.0, PHONE], [1.2, PHONE_B], [2.4, PHONE]]))
	sk.reset_bone_poses()


class Builder:
	var sk: Skeleton3D
	var bm: Basis          # поворот: пространство скелета -> пространство модели
	var unit: float        # сколько метров в одной единице скелета
	var path: String
	var base_pos: Array[Vector3] = []      # нейтральная стойка: первый кадр Idle (поза покоя в файлах мужчин — не стойка)
	var base_rot: Array[Quaternion] = []
	var foot_rel := {}                     # стопа относительно голени в нейтральной стойке

	func _init(scene: Node3D, skel: Skeleton3D, idle: Animation) -> void:
		sk = skel
		var xf := Model._xf_to(sk, scene)
		bm = xf.basis.orthonormalized()
		unit = xf.basis.get_scale().x
		var parts: Array[String] = []
		var c: Node = sk
		while c != scene and c != null:
			parts.push_front(String(c.name))
			c = c.get_parent()
		path = "/".join(parts)
		sk.reset_bone_poses()
		if idle:
			for t in idle.get_track_count():
				var bi := sk.find_bone(String(idle.track_get_path(t)).get_slice(":", 1))
				if bi < 0:
					continue
				if idle.track_get_type(t) == Animation.TYPE_POSITION_3D:
					sk.set_bone_pose_position(bi, idle.position_track_interpolate(t, 0.0))
				elif idle.track_get_type(t) == Animation.TYPE_ROTATION_3D:
					sk.set_bone_pose_rotation(bi, idle.rotation_track_interpolate(t, 0.0))
		for i in sk.get_bone_count():
			base_pos.append(sk.get_bone_pose_position(i))
			base_rot.append(sk.get_bone_pose_rotation(i))
		for s in ["L", "R"]:
			var shin := sk.find_bone("LowerLeg." + s)
			var foot := sk.find_bone("Foot." + s)
			if shin >= 0 and foot >= 0:
				foot_rel[s] = _g(shin).affine_inverse() * _g(foot)
				foot_rel[s + "b"] = _g(foot).basis

	## Глобальная поза кости считается здесь же: вне дерева сцены Skeleton3D не пересчитывает её сам.
	func _g(i: int) -> Transform3D:
		var t := Transform3D(Basis(sk.get_bone_pose_rotation(i)), sk.get_bone_pose_position(i))
		var par := sk.get_bone_parent(i)
		return _g(par) * t if par >= 0 else t

	func _base() -> void:
		for i in sk.get_bone_count():
			sk.set_bone_pose_position(i, base_pos[i])
			sk.set_bone_pose_rotation(i, base_rot[i])

	func make(length: float, loop: bool, keys: Array) -> Animation:
		var a := Animation.new()
		a.length = length
		a.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
		var n := sk.get_bone_count()
		var rt: Array[int] = []
		for i in n:
			var t := a.add_track(Animation.TYPE_ROTATION_3D)
			a.track_set_path(t, NodePath("%s:%s" % [path, sk.get_bone_name(i)]))
			rt.append(t)
		var pt := {}
		for bn in Poses.POS_BONES:
			var t := a.add_track(Animation.TYPE_POSITION_3D)
			a.track_set_path(t, NodePath("%s:%s" % [path, bn]))
			pt[bn] = t
		for k in keys:
			_apply(k[1])
			for i in n:
				a.rotation_track_insert_key(rt[i], k[0], sk.get_bone_pose_rotation(i))
			for bn in Poses.POS_BONES:
				a.position_track_insert_key(pt[bn], k[0], sk.get_bone_pose_position(sk.find_bone(bn)))
		sk.reset_bone_poses()
		return a

	func _apply(p: Dictionary) -> void:
		_base()
		var body := sk.find_bone("Body")
		if p.has("body"):
			var par := sk.get_bone_parent(body)
			var pg := _g(par).basis.orthonormalized() if par >= 0 else Basis.IDENTITY
			var v_sk: Vector3 = (bm.inverse() * (p["body"] as Vector3)) / unit
			sk.set_bone_pose_position(body, sk.get_bone_pose_position(body) + pg.inverse() * v_sk)
		var rots: Dictionary = p.get("rot", {})
		var names := rots.keys()
		names.sort_custom(func(x, y): return sk.find_bone(x) < sk.find_bone(y))
		for bn in names:
			var e: Vector3 = rots[bn]
			var rm := Basis.from_euler(Vector3(deg_to_rad(e.x), deg_to_rad(e.y), deg_to_rad(e.z)))
			_rotate(sk.find_bone(bn), bm.inverse() * rm * bm)
		var aims: Dictionary = p.get("aim", {})
		names = aims.keys()
		names.sort_custom(func(x, y): return sk.find_bone(x) < sk.find_bone(y))
		for bn in names:
			var i := sk.find_bone(bn)
			var cur := _g(i).basis.orthonormalized().y
			var want: Vector3 = (bm.inverse() * (aims[bn] as Vector3)).normalized()
			if cur.dot(want) < 0.9999:
				_rotate(i, Basis(Quaternion(cur, want)))
		# стопы — отдельные кости (дети Root): ставим их туда, куда пришёл конец голени
		for s in ["L", "R"]:
			var shin := sk.find_bone("LowerLeg." + s)
			var foot := sk.find_bone("Foot." + s)
			if shin < 0 or foot < 0:
				continue
			var fg: Transform3D = _g(shin) * (foot_rel[s] as Transform3D)
			if p.get("flat", false):
				fg.basis = foot_rel[s + "b"]
			var par := sk.get_bone_parent(foot)
			var pg := _g(par) if par >= 0 else Transform3D.IDENTITY
			var loc := pg.affine_inverse() * fg
			sk.set_bone_pose_position(foot, loc.origin)
			sk.set_bone_pose_rotation(foot, loc.basis.orthonormalized().get_rotation_quaternion())

	func _rotate(i: int, r_sk: Basis) -> void:
		if i < 0:
			return
		var g := _g(i).basis.orthonormalized()
		var par := sk.get_bone_parent(i)
		var pg := _g(par).basis.orthonormalized() if par >= 0 else Basis.IDENTITY
		sk.set_bone_pose_rotation(i, (pg.inverse() * (r_sk * g)).orthonormalized().get_rotation_quaternion())
