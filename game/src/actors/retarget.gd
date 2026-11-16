class_name Retarget
extends RefCounted
## Перенос анимаций человеческого скелета Quaternius (CharacterArmature) на скелет Меллстроя (GTA/Bip01).
## Выравнивает позу покоя по эталонному кадру Idle_Neutral в пространстве Model и запекает клипы один раз при старте.

const SRC_SCENE := "res://assets/chars/men/casual.glb"
const SAMPLE_FPS := 30.0

## Топологический порядок костей (родитель строго раньше потомка): [кость_источника, кость_меллстроя].
const BONE_MAP := [
	["Hips", " Pelvis_01"],
	["Torso", " Spine_02"],
	["Chest", " Spine1_03"],
	["Neck", " Neck_04"],
	["Head", " Head_00"],
	["Shoulder.L", "Bip01 L Clavicle_08"],
	["UpperArm.L", " L UpperArm_09"],
	["LowerArm.L", " L ForeArm_010"],
	["Wrist.L", " L Hand_011"],
	["Middle1.L", " L Finger_012"],
	["Middle2.L", "L Finger01_013"],
	["Shoulder.R", "Bip01 R Clavicle_014"],
	["UpperArm.R", " R UpperArm_015"],
	["LowerArm.R", " R ForeArm_016"],
	["Wrist.R", " R Hand_017"],
	["Middle1.R", " R Finger_018"],
	["Middle2.R", "R Finger01_019"],
	["UpperLeg.L", " L Thigh_023"],
	["LowerLeg.L", " L Calf_024"],
	["Foot.L", " L Foot_025"],
	["UpperLeg.R", " R Thigh_027"],
	["LowerLeg.R", " R Calf_028"],
	["Foot.R", " R Foot_029"],
]

## Сегменты конечностей для выравнивания эталонной A-позы Меллстроя под Idle_Neutral:
## [кость_меллстроя, потомок_меллстроя, кость_источника, потомок_источника].
const LIMB_ALIGN := [
	[" L UpperArm_09", " L ForeArm_010", "UpperArm.L", "LowerArm.L"],
	[" L ForeArm_010", " L Hand_011", "LowerArm.L", "Wrist.L"],
	[" L Hand_011", " L Finger_012", "Wrist.L", "Middle1.L"],
	[" R UpperArm_015", " R ForeArm_016", "UpperArm.R", "LowerArm.R"],
	[" R ForeArm_016", " R Hand_011_R", "LowerArm.R", "Wrist.R"],
	[" R Hand_017", " R Finger_018", "Wrist.R", "Middle1.R"],
	[" L Thigh_023", " L Calf_024", "UpperLeg.L", "LowerLeg.L"],
	[" L Calf_024", " L Foot_025", "LowerLeg.L", "Foot.L"],
	[" R Thigh_027", " R Calf_028", "UpperLeg.R", "LowerLeg.R"],
	[" R Calf_028", " R Foot_029", "LowerLeg.R", "Foot.R"],
]

## Канонические псевдонимы костей для Model.attach() (шапки, цепи, предметы в руках).
const ATTACH_ALIASES := {
	"Head": " Head_00",
	"Neck": " Neck_04",
	"Chest": " Spine1_03",
	"Torso": " Spine_02",
	"Hips": " Pelvis_01",
	"Wrist.R": " R Hand_017",
	"Wrist.L": " L Hand_011",
	"Hand.R": " R Hand_017",
	"Hand.L": " L Hand_011",
}


static func build_mellstroy_lib(src_lib: AnimationLibrary, dst_model: Node3D, dst_skel: Skeleton3D, dst_root: Node) -> AnimationLibrary:
	var out := AnimationLibrary.new()
	if src_lib == null or dst_skel == null or not ResourceLoader.exists(SRC_SCENE):
		return out

	var src_model := Node3D.new()
	var src_scene: Node3D = (load(SRC_SCENE) as PackedScene).instantiate()
	src_scene.rotation.y = PI
	src_model.add_child(src_scene)
	var src_skel := _find_skel(src_scene)
	if src_skel == null:
		src_model.free()
		return out

	var xf_src := _xf_to(src_skel, src_model)
	var b_src := xf_src.basis.orthonormalized()
	var xf_dst := _xf_to(dst_skel, dst_model)
	var xf_dst_inv := xf_dst.affine_inverse()
	var b_dst := xf_dst.basis.orthonormalized()
	var b_dst_inv := b_dst.transposed()

	# 1. Эталонная симметричная поза источника (Idle_Neutral, t = 0)
	src_skel.reset_bone_poses()
	var ref_name := "Idle_Neutral" if src_lib.has_animation("Idle_Neutral") else ("Idle" if src_lib.has_animation("Idle") else "")
	if ref_name != "":
		_eval_anim_on_skel(src_skel, src_scene, src_lib.get_animation(ref_name), 0.0)

	var pairs: Array = []
	for row in BONE_MAP:
		var si := src_skel.find_bone(row[0])
		var di := dst_skel.find_bone(row[1])
		if si < 0 or di < 0:
			continue
		var s_gp := _g(src_skel, si)
		var s_rot_m := (b_src * s_gp.basis.orthonormalized()).orthonormalized()
		pairs.append({
			"si": si,
			"di": di,
			"dname": String(row[1]),
			"par": dst_skel.get_bone_parent(di),
			"s_ref_inv": s_rot_m.transposed(),
		})

	var src_hips_i := src_skel.find_bone("Hips")
	var dst_pelvis_i := dst_skel.find_bone(" Pelvis_01")
	var src_hips_ref_m := xf_src * _g(src_skel, src_hips_i).origin if src_hips_i >= 0 else Vector3(0.0, 0.885, 0.0)

	# 2. Выравниваем эталонную позу Меллстроя под направления сегментов Idle_Neutral
	dst_skel.reset_bone_poses()
	var dst_pelvis_rest_m := xf_dst * _g(dst_skel, dst_pelvis_i).origin if dst_pelvis_i >= 0 else Vector3(0.0, 0.97, 0.0)
	var leg_scale := dst_pelvis_rest_m.y / maxf(0.5, src_hips_ref_m.y)

	for al in LIMB_ALIGN:
		var d_child_name := " R Hand_017" if String(al[1]) == " R Hand_011_R" else String(al[1])
		var di := dst_skel.find_bone(al[0])
		var dci := dst_skel.find_bone(d_child_name)
		var si := src_skel.find_bone(al[2])
		var sci := src_skel.find_bone(al[3])
		if di < 0 or dci < 0 or si < 0 or sci < 0:
			continue
		var s_p0 := xf_src * _g(src_skel, si).origin
		var s_p1 := xf_src * _g(src_skel, sci).origin
		var d_p0 := xf_dst * _g(dst_skel, di).origin
		var d_p1 := xf_dst * _g(dst_skel, dci).origin
		var s_dir := s_p1 - s_p0
		var d_dir := d_p1 - d_p0
		if s_dir.length_squared() < 1e-6 or d_dir.length_squared() < 1e-6:
			continue
		var swing := Basis(Quaternion(d_dir.normalized(), s_dir.normalized()))
		var cur_rot_m := (b_dst * _g(dst_skel, di).basis.orthonormalized()).orthonormalized()
		var aligned_rot_m := (swing * cur_rot_m).orthonormalized()
		_set_bone_rot_m(dst_skel, di, dst_skel.get_bone_parent(di), b_dst_inv, aligned_rot_m)

	for p in pairs:
		var di: int = p["di"]
		p["d_ref"] = (b_dst * _g(dst_skel, di).basis.orthonormalized()).orthonormalized()

	dst_skel.reset_bone_poses()
	var skel_path := String(dst_root.get_path_to(dst_skel))

	# 3. Запекаем все клипы из src_lib
	for anim_name in src_lib.get_animation_list():
		var src_anim := src_lib.get_animation(anim_name)
		if src_anim == null:
			continue
		var dst_anim := _bake_clip(
			src_anim, src_skel, src_scene, dst_skel, skel_path, pairs,
			xf_src, b_src, xf_dst_inv, b_dst_inv,
			src_hips_i, dst_pelvis_i, src_hips_ref_m, dst_pelvis_rest_m, leg_scale
		)
		out.add_animation(anim_name, dst_anim)

	dst_skel.reset_bone_poses()
	src_model.free()
	return out


static func _bake_clip(
	src_anim: Animation,
	src_skel: Skeleton3D,
	src_root: Node,
	dst_skel: Skeleton3D,
	skel_path: String,
	pairs: Array,
	xf_src: Transform3D,
	b_src: Basis,
	xf_dst_inv: Transform3D,
	b_dst_inv: Basis,
	src_hips_i: int,
	dst_pelvis_i: int,
	src_hips_ref_m: Vector3,
	dst_pelvis_rest_m: Vector3,
	leg_scale: float
) -> Animation:
	var a := Animation.new()
	var length := maxf(0.0333, src_anim.length)
	a.length = length
	a.loop_mode = src_anim.loop_mode

	var times: Array[float] = []
	var steps := maxi(1, roundi(length * SAMPLE_FPS))
	for step_i in range(steps + 1):
		times.append(minf(length, float(step_i) * length / float(steps)))

	var pos_tr := -1
	if dst_pelvis_i >= 0 and src_hips_i >= 0:
		pos_tr = a.add_track(Animation.TYPE_POSITION_3D)
		a.track_set_path(pos_tr, NodePath(skel_path + ": Pelvis_01"))
		a.track_set_interpolation_type(pos_tr, Animation.INTERPOLATION_LINEAR)

	var rot_tracks: Array[int] = []
	var prev_quats: Array[Quaternion] = []
	for p in pairs:
		var tr := a.add_track(Animation.TYPE_ROTATION_3D)
		a.track_set_path(tr, NodePath(skel_path + ":" + String(p["dname"])))
		a.track_set_interpolation_type(tr, Animation.INTERPOLATION_LINEAR)
		rot_tracks.append(tr)
		prev_quats.append(Quaternion.IDENTITY)

	for fi in range(times.size()):
		var t: float = times[fi]
		src_skel.reset_bone_poses()
		_eval_anim_on_skel(src_skel, src_root, src_anim, t)

		if pos_tr >= 0:
			var hips_m := xf_src * _g(src_skel, src_hips_i).origin
			var delta_m := (hips_m - src_hips_ref_m) * leg_scale
			# Не даём обуви проваливаться глубоко под пол при сжатии ног
			var tgt_m := dst_pelvis_rest_m + delta_m
			tgt_m.y = maxf(0.10, tgt_m.y)
			var local_pos := xf_dst_inv * tgt_m
			dst_skel.set_bone_pose_position(dst_pelvis_i, local_pos)
			a.position_track_insert_key(pos_tr, t, local_pos)

		for pi_idx in range(pairs.size()):
			var p: Dictionary = pairs[pi_idx]
			var si: int = p["si"]
			var di: int = p["di"]
			var par: int = p["par"]
			var s_rot_m := (b_src * _g(src_skel, si).basis.orthonormalized()).orthonormalized()
			var delta_rot: Basis = s_rot_m * (p["s_ref_inv"] as Basis)
			var tgt_rot_m := (delta_rot * (p["d_ref"] as Basis)).orthonormalized()
			var q := _set_bone_rot_m(dst_skel, di, par, b_dst_inv, tgt_rot_m)
			if fi > 0 and q.dot(prev_quats[pi_idx]) < 0.0:
				q = -q
			prev_quats[pi_idx] = q
			a.rotation_track_insert_key(rot_tracks[pi_idx], t, q)

	return a


static func _set_bone_rot_m(skel: Skeleton3D, di: int, par: int, b_dst_inv: Basis, tgt_rot_m: Basis) -> Quaternion:
	var skel_basis := (b_dst_inv * tgt_rot_m).orthonormalized()
	var par_basis := _g(skel, par).basis.orthonormalized() if par >= 0 else Basis.IDENTITY
	var local_basis := (par_basis.transposed() * skel_basis).orthonormalized()
	var q := local_basis.get_rotation_quaternion().normalized()
	skel.set_bone_pose_rotation(di, q)
	return q


static func _g(skel: Skeleton3D, i: int) -> Transform3D:
	if i < 0:
		return Transform3D.IDENTITY
	var b := Basis(skel.get_bone_pose_rotation(i)).scaled(skel.get_bone_pose_scale(i))
	var t := Transform3D(b, skel.get_bone_pose_position(i))
	var par := skel.get_bone_parent(i)
	return _g(skel, par) * t if par >= 0 else t


static func _eval_anim_on_skel(skel: Skeleton3D, root: Node, anim: Animation, t: float) -> void:
	if anim == null:
		return
	for tr in range(anim.get_track_count()):
		var np := anim.track_get_path(tr)
		if np.get_subname_count() == 0:
			continue
		var target := root.get_node_or_null(NodePath(np.get_concatenated_names()))
		if target != skel:
			continue
		var bname := String(np.get_subname(0))
		var bi := skel.find_bone(bname)
		if bi < 0:
			continue
		var tt := anim.track_get_type(tr)
		if tt == Animation.TYPE_ROTATION_3D:
			skel.set_bone_pose_rotation(bi, anim.rotation_track_interpolate(tr, t))
		elif tt == Animation.TYPE_POSITION_3D:
			skel.set_bone_pose_position(bi, anim.position_track_interpolate(tr, t))
		elif tt == Animation.TYPE_SCALE_3D:
			skel.set_bone_pose_scale(bi, anim.scale_track_interpolate(tr, t))


static func _find_skel(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n
	for c in n.get_children():
		var r := _find_skel(c)
		if r != null:
			return r
	return null


static func _xf_to(n: Node3D, stop: Node) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var cur: Node = n
	while cur != null and cur != stop:
		if cur is Node3D:
			xf = (cur as Node3D).transform * xf
		cur = cur.get_parent()
	return xf
