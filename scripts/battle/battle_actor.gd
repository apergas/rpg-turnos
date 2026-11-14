class_name BattleActor extends Node3D
## 3D figure of a fighter or a villager. The hero, the villagers, the witch and the
## skeletons are KayKit models with their own animations (the skeletons get their
## weapons from KayKit too, and the Señor de la Niebla a purple aura and the Eco de la Niebla a pale cyan one); the slimes, the
## bat, the mushroom, the wolf,
## the goblin, the carnivorous plant, the golems, the spider, the specter and the
## creatures that fight beside the hero are low-poly figures built in code (see LOOKS).
## The jungle's frog, snake, monkey, trap plant and tropical mushroom (the v2) come after.
## Five of them are color variants of those (RED_SLIME, POISON_MUSHROOM, CAVE_MUSHROOM, CRYPT_BAT, FROST_SPECTER), built by the same functions.
## Set look before add_child. The figure faces -Z, so look_at() the opponent. Every
## play_* can be awaited: it returns when its animation and its tween are done.

## Every figure a BattleActor can be: the enum lives in ActorLooks, and BattleActor.Look.X
## keeps working through this alias.
const Look = ActorLooks.Look
## What floats under a damage number: nothing, "¡Débil!" or "¡Resiste!".
enum Tag { NONE, WEAK, RESIST }
## Damage numbers: font px of a normal number and a critical one, and the world height each
## drew at before the design system (pixel_size = old height / font px).
const NUMBER_FONT := 48
const NUMBER_CRIT_FONT := 62
const NUMBER_WORLD := 0.32
const NUMBER_CRIT_WORLD := 0.48
const TAG_WORLD := 0.2
## Bones the weapons hang from, under the model's Rig/Skeleton3D.
const SKELETON_PATH := "Rig/Skeleton3D"
const FOG_AURA_ALPHA := 0.2
const FOG_AURA_PHASE_ALPHA := 0.38
## The Devorador del portal's second phase (_devourer_wakes()): the share its mass grows by
## and its eyelid's open angle.
const DEVOURER_GROWTH := 1.25
const EYELID_OPEN := 75.0
## The AnimationPlayer inside a KayKit character scene.
const ANIM_PLAYER_PATH := "AnimationPlayer"
const BLEND_TIME := 0.15
## One-shot animations (attack, spell, hit, dodge, death, cheer) play this much faster.
const ACTION_SPEED := 1.3
## The run cycle covers ~1 m/s at this scale; sped up so the feet keep closer pace with
## the 5 m/s of the map.
const WALK_SPEED := 1.8
## Strength of the additive flash on hits, spells and heals.
const FLASH_ALPHA := 0.6
## The soft glow over a figure being aimed at (set_highlight()).
const HIGHLIGHT_COLOR := Color(1.0, 0.95, 0.6)
const HIGHLIGHT_ALPHA := 0.22
## Angle (radians about X) of the plant's upper jaw: resting, and wide open to bite.
const JAW_REST := 0.3
const JAW_OPEN := 0.95
## The map hero's rim of light (set_map_readable()): one material for him, as an overlay.
const RIM_SHADER := preload("res://shaders/hero_rim.gdshader")
## Hand slots of the KayKit characters (BoneAttachment3D nodes).
const HELMET_PATH := "Rig/Skeleton3D/head/Knight_Helmet"
const HAND_R := "Rig/Skeleton3D/handslot_r"
const HAND_L := "Rig/Skeleton3D/handslot_l"
## The wooden stick built in code for Equipment.STICK_MESH: along the hand's +Y like the
## Knight's swords, grip at the hand.
const STICK_COLOR := Color(0.45, 0.3, 0.16)
const STICK_RADIUS := 0.07
const STICK_LENGTH := 1.3
## The Yelmo de bruma's horns (Equipment.has_horns()), built in code under the Knight's
## helmet mesh, in its own space (about 1.14 wide, brim at y -0.1, top at 1.25): bone
## colored, each from the side of the helmet out and then up, in HORN_SEGMENTS tapering
## pieces, every one bent HORN_BEND degrees more toward the top.
const HORN_COLOR := Color(0.9, 0.84, 0.68)
const HORN_ROOT := Vector3(0.5, 0.75, 0.05)
const HORN_SEGMENTS := 3
const HORN_SEGMENT_LENGTH := 0.22
const HORN_RADIUS := 0.11
## Degrees about Z of the first piece: almost flat, pointing out of the helmet.
const HORN_START_ANGLE := 75.0
const HORN_BEND := 35.0
const STICK_CENTER := 0.45

@export var look := Look.HERO

## Height of the floating damage numbers.
var _top := 2.0
## Visual root moved and scaled by the tweens; the actor node itself stays put.
var _body: Node3D
## Every mesh of the figure, for the flash overlay.
var _meshes: Array[MeshInstance3D] = []
## Slime materials only (faded on defeat); the KayKit materials are left as imported.
var _materials: Array[StandardMaterial3D] = []
var _flash: StandardMaterial3D
var _highlight: StandardMaterial3D
var _highlighted := false
## The map hero only: the overlay every mesh shows when no flash or highlight is on (null
## for every other figure, and in battle).
var _map_overlay: ShaderMaterial
## Characters only; null for slimes.
var _anim: AnimationPlayer
var _anims: Dictionary = {}
var _idle_tween: Tween
## Bat only: the two wing pivots, flapped by the idle loop.
var _wings: Array[Node3D] = []
## Characters only: the imported model (its hand slots hold the equipment meshes).
var _model: Node3D
## The Yelmo de bruma's horns, under the helmet mesh (null until a horned helmet is worn).
var _horns: Node3D
## Plant only: the upper jaw's pivot (opens to bite) and the node its idle sway turns.
var _jaw: Node3D
var _sway: Node3D
## Specter only: the node its idle loop floats up and down, and its see-through
## materials with their resting opacity ([material, alpha]).
var _hover: Node3D
var _ghosts: Array = []
## Figures with an aura (the Señor de la Niebla, the Eco): its ball (null for the rest).
var _aura: MeshInstance3D
## Devourer only: the node that grows in its second phase and the pivot of its eyelid.
var _devourer: Node3D
var _eyelid: Node3D


func _ready() -> void:
	_body = Node3D.new()
	add_child(_body)
	var data: Dictionary = ActorLooks.LOOKS[look]
	_top = data.top
	if data.has("scene"):
		_build_character(data)
	else:
		CreatureBuilder.build(self, data)
	for node in _body.find_children("*", "MeshInstance3D", true, false):
		_meshes.append(node as MeshInstance3D)
	_flash = StandardMaterial3D.new()
	_flash.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_flash.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_flash.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_highlight = _flash.duplicate() as StandardMaterial3D
	_highlight.albedo_color = Color(HIGHLIGHT_COLOR, HIGHLIGHT_ALPHA)
	reset()


## Back to the starting pose: visible, opaque, no flash, idle animation running.
func reset() -> void:
	show()
	_body.position = Vector3.ZERO
	_body.rotation = Vector3.ZERO
	_body.scale = Vector3.ONE
	_set_flash(false)
	for mat in _materials:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
		mat.albedo_color.a = 1.0
	_set_alpha(1.0)
	if _anim:
		_anim.play(_anims.idle, 0.0)
	else:
		_start_idle()


## Map only: the walk (run) cycle while on is true, else the idle one. Slimes ignore it.
func set_walking(on: bool) -> void:
	if _anim == null:
		return
	var anim_name: String = _anims.walk if on else _anims.idle
	if _anim.current_animation != anim_name:
		_anim.play(anim_name, BLEND_TIME, WALK_SPEED if on else 1.0)


## Map only: half see-through (a group that can't start a battle now: fled from, or an
## Incienso burning), or whole again. Every mesh of the figure.
func set_faded(on: bool) -> void:
	for mi in _meshes:
		mi.transparency = 1.0 - UiTokens.OPACITY_FADED if on else 0.0


## A group coming back on the map: every mesh from invisible to solid in seconds.
func play_fade_in(seconds: float) -> void:
	for mi in _meshes:
		mi.transparency = 1.0
	var t := create_tween().set_parallel()
	for mi in _meshes:
		t.tween_property(mi, "transparency", 0.0, seconds)


## Map hero only (Player): a soft rim of light and a faint light of his own on every mesh
## (RIM_SHADER through material_overlay, so the Knight's shared materials never change), so
## he reads on a tree's shadow. Never in battle, never on the companions or the figures.
func set_map_readable(on: bool) -> void:
	# The dummy renderer of --headless runs errors on shader overlays: no rim there.
	if DisplayServer.get_name() == "headless":
		return
	if on and _map_overlay == null:
		_map_overlay = ShaderMaterial.new()
		_map_overlay.shader = RIM_SHADER
	elif not on:
		_map_overlay = null
	_apply_map_overlay()


## Puts the map overlay on every mesh of the figure, the hidden ones too (hand meshes,
## helmet, horns), unless a flash or the highlight is showing.
func _apply_map_overlay() -> void:
	for node in _body.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi.material_overlay != _flash or _flash == null:
			mi.material_overlay = _map_overlay


## Map only: true for the figures that hop as they walk (the slimes).
func hops() -> bool:
	return look in [Look.SLIME, Look.RED_SLIME, Look.METAL_SLIME, Look.SAND_SLIME]


## Map only: one small hop (a slime walking); not awaited.
func play_hop() -> void:
	_hop()


## Hero only: shows the hand meshes of the weapon and shield worn (Equipment ids, ""
## for none) and hides the rest. A helmet shows the model's helmet mesh tinted with its
## color, with horns for the Yelmo de bruma. The weapon's mesh takes its Equipment.tint() (the
## Espada del alba is pale gold); the shield's mesh takes its Equipment.tint() too (the Escudo
## de medallas is gold). Armor does not change the model. Others ignore it.
func set_equipment(weapon_id: String, shield_id: String, helmet_id := "") -> void:
	if look != Look.HERO or _model == null:
		return
	var shown := {HAND_R: Equipment.mesh(weapon_id), HAND_L: Equipment.mesh(shield_id)}
	for hand: String in shown:
		for child in _model.get_node(hand).get_children():
			(child as Node3D).visible = child.name == shown[hand] and shown[hand] != ""
	# The weapon's own tint (the Espada del alba): every hand mesh back to its imported
	# materials first, so a tint never stays on the next weapon that uses the mesh.
	var right := _model.get_node(HAND_R)
	for node in right.find_children("*", "MeshInstance3D", true, false):
		if node.name != Equipment.STICK_MESH:
			for i in (node as MeshInstance3D).mesh.get_surface_count():
				(node as MeshInstance3D).set_surface_override_material(i, null)
	var weapon_tint := Equipment.tint(weapon_id)
	var weapon_mesh := Equipment.mesh(weapon_id)
	if weapon_tint != Color.WHITE and weapon_mesh != "" and right.has_node(weapon_mesh):
		var weapon := right.get_node(weapon_mesh)
		if weapon is MeshInstance3D:
			_tint_mesh(weapon as MeshInstance3D, weapon_tint)
		else:
			_tint(weapon as Node3D, weapon_tint)
	# The shield's own tint (the Escudo de medallas is gold), the same way.
	var left := _model.get_node(HAND_L)
	for node in left.find_children("*", "MeshInstance3D", true, false):
		for i in (node as MeshInstance3D).mesh.get_surface_count():
			(node as MeshInstance3D).set_surface_override_material(i, null)
	var shield_tint := Equipment.tint(shield_id)
	var shield_mesh := Equipment.mesh(shield_id)
	if shield_tint != Color.WHITE and shield_mesh != "" and left.has_node(shield_mesh):
		var shield := left.get_node(shield_mesh)
		if shield is MeshInstance3D:
			_tint_mesh(shield as MeshInstance3D, shield_tint)
		else:
			_tint(shield as Node3D, shield_tint)
	var helmet := _model.get_node(HELMET_PATH) as MeshInstance3D
	helmet.visible = helmet_id != ""
	if Equipment.has_horns(helmet_id) and _horns == null:
		_horns = _build_horns(helmet)
	if _horns:
		_horns.visible = Equipment.has_horns(helmet_id)
	if helmet_id != "":
		# Drop the previous tint first, or _tint_mesh() would multiply onto it.
		for i in helmet.mesh.get_surface_count():
			helmet.set_surface_override_material(i, null)
		_tint_mesh(helmet, Equipment.helmet_tint(helmet_id))
	# The hand meshes, the helmet and the horns may have changed: the rim goes on them again.
	if _map_overlay != null:
		_apply_map_overlay()


## The two horns of the Yelmo de bruma, built once under the helmet mesh. Their meshes
## join _meshes, so a hit flashes them with the rest of the hero.
func _build_horns(helmet: MeshInstance3D) -> Node3D:
	var horns := Node3D.new()
	horns.name = "Horns"
	var mat := StandardMaterial3D.new()
	mat.albedo_color = HORN_COLOR
	mat.roughness = 0.6
	for side: float in [1.0, -1.0]:
		# A turn of -angle about Z points +Y toward +X: the right horn goes out to +X.
		var joint := Node3D.new()
		joint.position = Vector3(HORN_ROOT.x * side, HORN_ROOT.y, HORN_ROOT.z)
		joint.rotation_degrees.z = -HORN_START_ANGLE * side
		horns.add_child(joint)
		var radius := HORN_RADIUS
		for i in HORN_SEGMENTS:
			var next_radius := HORN_RADIUS * (HORN_SEGMENTS - 1 - i) / HORN_SEGMENTS
			var mesh := CylinderMesh.new()
			mesh.bottom_radius = radius
			mesh.top_radius = next_radius
			mesh.height = HORN_SEGMENT_LENGTH
			mesh.radial_segments = 6
			mesh.rings = 1
			var mi := MeshInstance3D.new()
			mi.mesh = mesh
			mi.material_override = mat
			mi.position.y = HORN_SEGMENT_LENGTH / 2.0
			joint.add_child(mi)
			_meshes.append(mi)
			var next := Node3D.new()
			next.position.y = HORN_SEGMENT_LENGTH
			next.rotation_degrees.z = HORN_BEND * side
			joint.add_child(next)
			joint = next
			radius = next_radius
	helmet.add_child(horns)
	return horns


## Swings (characters) and lunges toward the target and steps back; the plant opens
## its jaws wide on the way and snaps them shut.
func play_attack(target_pos: Vector3) -> void:
	var timer := _start("attack")
	var base := global_position
	var dir := target_pos - base
	dir.y = 0.0
	var lunge := dir.normalized() * minf(1.2, dir.length() * 0.4)
	if _jaw:
		var bite := create_tween()
		bite.tween_property(_jaw, "rotation:x", JAW_OPEN, 0.15)
		bite.tween_property(_jaw, "rotation:x", 0.0, 0.08)
		bite.tween_interval(0.12)
		bite.tween_property(_jaw, "rotation:x", JAW_REST, 0.15)
	var t := create_tween()
	if timer:
		t.tween_interval(0.15)  # the swing winds up before the step
	t.tween_property(_body, "global_position", base + lunge, 0.15) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(_body, "global_position", base, 0.2) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await t.finished
	await _end(timer)


## Height of the top of the figure (where the damage numbers start).
func top_height() -> float:
	return _top


## Hit animation, white flash, small knockback and a floating damage number; tag
## (weak, resist) floats under the number and a crit adds "¡Crítico!".
func play_hit(amount: int, crit: bool, tag := Tag.NONE, number := &"text-primary") -> void:
	_spawn_number(amount, crit, number, tag)
	var timer := _start("hit")
	var base := global_position
	var knockback := global_basis.z.normalized() * (0.5 if crit else 0.3)
	_set_flash(true)
	var t := create_tween()
	t.tween_property(_body, "global_position", base + knockback, 0.08)
	t.tween_callback(_set_flash.bind(false))
	t.tween_property(_body, "global_position", base, 0.15)
	await t.finished
	await _end(timer)


## Jumps back when an attack misses.
func play_dodge() -> void:
	var timer := _start("dodge")
	var base := global_position
	var back := global_basis.z.normalized() * 0.6
	var t := create_tween()
	t.tween_property(_body, "global_position", base + back, 0.1) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(_body, "global_position", base, 0.15)
	await t.finished
	await _end(timer)


## Characters fall with the death animation and stay down. Slimes squash, shrink and
## fade out, then hide.
func play_defeat() -> void:
	if _anim:
		var timer := _start("death")
		if _aura:
			create_tween().tween_method(_set_alpha, 1.0, 0.0, timer.time_left)
		await timer.timeout
		return
	if _idle_tween:
		_idle_tween.kill()
	for mat in _materials:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var t := create_tween()
	t.tween_property(_body, "scale", Vector3(1.25, 0.3, 1.25), 0.2)
	t.tween_property(_body, "scale", Vector3(0.05, 0.05, 0.05), 0.35)
	t.parallel().tween_method(_set_alpha, 1.0, 0.0, 0.35)
	await t.finished
	hide()


## Glow in the spell's color with the cast animation (characters) or a small hop
## (slimes), before a spell.
func play_cast(color := UiTokens.color(&"element-fire")) -> void:
	_set_flash(true, color)
	var timer := _start("cast")
	if timer:
		await timer.timeout
	else:
		await _hop()
	_set_flash(false)
	await _end(timer)


## A ball in the spell's color grows on the actor and fades while the hit plays.
func play_burn(amount: int, color := UiTokens.color(&"element-fire"), tag := Tag.NONE,
		number := &"text-primary") -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	var ball := MeshInstance3D.new()
	ball.mesh = LowPoly.sphere(0.5)
	ball.material_override = mat
	ball.position = Vector3(0, _top * 0.45, 0)
	ball.scale = Vector3.ONE * 0.2
	add_child(ball)
	var t := create_tween()
	t.tween_property(ball, "scale", Vector3.ONE * 1.6, 0.3) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.3).set_delay(0.1)
	t.tween_callback(ball.queue_free)
	await play_hit(amount, false, tag, number)
	if t.is_running():
		await t.finished


## Glow and a number going up, green by default (HP); an MP heal passes its own color.
func play_heal(amount: int, color := UiTokens.color(&"element-heal"),
		number := &"element-heal") -> void:
	_spawn_number(amount, false, number)
	_set_flash(true, color)
	await get_tree().create_timer(0.35).timeout
	_set_flash(false)


## Glow in a status color (poison, sleep, defend...); amount > 0 also floats a number of
## that color (poison damage, the only damaging status), whose token the caller names.
func play_status(color: Color, amount := 0, number := &"text-primary") -> void:
	if amount > 0:
		_spawn_number(amount, false, number)
	_set_flash(true, color)
	await get_tree().create_timer(0.35).timeout
	_set_flash(false)


## Grows from nothing where it stands (an enemy called for help).
func play_appear() -> void:
	if _idle_tween:
		_idle_tween.kill()
	_body.scale = Vector3.ONE * 0.05
	var t := create_tween()
	t.tween_property(_body, "scale", Vector3.ONE, 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await t.finished
	_start_idle()


## The fog envelops the Señor de la Niebla: a long purple glow with the spell
## animation while his aura swells and thickens (his second phase).
func play_phase() -> void:
	if look == Look.PORTAL_DEVOURER:
		await _devourer_wakes()
		return
	_set_flash(true, ActorLooks.FOG_AURA_COLOR)
	var timer := _start("cast")
	if _aura:
		var mat := _aura.material_override as StandardMaterial3D
		for ghost in _ghosts:
			if ghost[0] == mat:
				ghost[1] = FOG_AURA_PHASE_ALPHA
		var t := create_tween().set_parallel()
		t.tween_property(_aura, "scale", _aura.scale * 1.3, 0.6) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(mat, "albedo_color:a", FOG_AURA_PHASE_ALPHA, 0.6)
	await get_tree().create_timer(0.8).timeout
	_set_flash(false)
	await _end(timer)


## Wobbles side to side, for a fighter that loses its turn.
func play_stagger() -> void:
	var t := create_tween()
	for angle in [12.0, -12.0, 8.0, 0.0]:
		t.tween_property(_body, "rotation_degrees:z", angle, 0.1)
	await t.finished


## Celebrates a victory: the cheer animation (characters) or a hop (slimes).
func play_cheer() -> void:
	var timer := _start("cheer")
	if timer == null:
		await _hop()
	await _end(timer)


func _build_character(data: Dictionary) -> void:
	var model: Node3D = (data.scene as PackedScene).instantiate()
	model.scale = Vector3.ONE * data.scale
	# KayKit characters face +Z; turned around they face -Z like every BattleActor.
	model.rotation.y = PI
	_body.add_child(model)
	_model = model
	for path in data.hide:
		(model.get_node(path) as Node3D).hide()
	var bones := model.get_node_or_null(SKELETON_PATH) as Skeleton3D
	for bone: String in data.get("props", {}):
		var slot := BoneAttachment3D.new()
		slot.bone_name = bone
		bones.add_child(slot)
		slot.add_child((data.props[bone] as PackedScene).instantiate())
	if data.has("tint"):
		_tint(model, data.tint)
	var mesh_tints: Dictionary = data.get("mesh_tints", {})
	for mesh_name: String in mesh_tints:
		_tint_mesh(bones.get_node(mesh_name) as MeshInstance3D, mesh_tints[mesh_name])
	if data.has("neck_glow"):
		# The Armadura hueca: an ember where its head should be, on the head bone.
		var slot := BoneAttachment3D.new()
		slot.bone_name = "head"
		bones.add_child(slot)
		add_mesh(slot, LowPoly.sphere(0.13), data.neck_glow, Vector3(0, 0.0, 0))
		var ember := (slot.get_child(-1) as MeshInstance3D).material_override as StandardMaterial3D
		ember.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if data.has("wrap_color"):
		_add_mummy_wraps(bones, data.wrap_color)
	if data.has("head_texture"):
		# The head's hair and skin share one mesh: a copy of its material with this atlas.
		var head := bones.get_node("Knight_Head") as MeshInstance3D
		var head_material := head.get_active_material(0).duplicate() as BaseMaterial3D
		head_material.albedo_texture = data.head_texture
		head.set_surface_override_material(0, head_material)
	var cape := model.find_child("Knight_Cape", true, false) as MeshInstance3D
	if cape != null and data.get("hide_cape", false):
		cape.hide()
	elif cape != null and data.has("cape"):
		# One flat colour (the cape is one palette cell): a copy without the atlas.
		var cape_material := cape.get_active_material(0).duplicate() as BaseMaterial3D
		cape_material.albedo_texture = null
		cape_material.albedo_color = data.cape
		cape.set_surface_override_material(0, cape_material)
	if data.has("hair"):
		_add_hair(model, data.hair)
	if data.has("aura"):
		add_ghost(_body, LowPoly.sphere(0.5), data.aura, FOG_AURA_ALPHA, Vector3(0, _top * 0.45, 0),
			Vector3(2.2, 3.2, 2.2))
		_aura = _body.get_child(-1) as MeshInstance3D
	if look == Look.HERO:
		var stick := LowPoly.cylinder(STICK_RADIUS, STICK_LENGTH)
		stick.top_radius = STICK_RADIUS * 0.7
		add_mesh(model.get_node(HAND_R), stick, STICK_COLOR, Vector3(0, STICK_CENTER, 0))
		var mi := model.get_node(HAND_R).get_child(-1) as MeshInstance3D
		mi.name = Equipment.STICK_MESH
		# The starting gear until set_equipment() says otherwise.
		set_equipment(Equipment.STICK, "")
	_anims = data.anims
	_anim = model.get_node(ANIM_PLAYER_PATH) as AnimationPlayer
	# The imported animations do not loop; idle and walk must.
	for role in ["idle", "walk"]:
		_anim.get_animation(_anims[role]).loop_mode = Animation.LOOP_LINEAR


## A hair piece (ActorLooks.HAIR_PIECES: a beard, a bun or a ponytail), faceted like the slimes, in the
## hair's colour, hung from the head bone's attachment so it follows every animation.
func _add_hair(model: Node3D, hair: Dictionary) -> void:
	var head := model.get_node("Rig/Skeleton3D/head") as Node3D
	var piece: Dictionary = ActorLooks.HAIR_PIECES[hair.style]
	var profile: Array[Vector2] = []
	profile.assign(ActorLooks.HAIR_PROFILES[piece.profile])
	add_blob(head, profile, ActorLooks.HAIR_SEGMENTS, hair.color, piece.pos, piece.rot, piece.scale)


## The Momia's bandages: flat rings of linen (squashed cylinders, each a little tilted the
## other way than the last) round the head, the chest and both arms, a gap at the eyes,
## and loose strips hanging from the wrists and the hip. Each is placed in the rig's rest
## pose and hung from its bone, so it follows the animation.
func _add_mummy_wraps(bones: Skeleton3D, color: Color) -> void:
	var rings := [
		["head", Vector3(0, 1.28, 0.0), 0.0, 0.46, 0.1, 0.95],
		["head", Vector3(0, 1.62, 0.0), 6.0, 0.45, 0.1, 0.98],
		["head", Vector3(0, 1.78, 0.0), -8.0, 0.46, 0.1, 1.0],
		["head", Vector3(0, 1.93, 0.0), 8.0, 0.44, 0.1, 1.0],
		["head", Vector3(0, 2.06, 0.0), -6.0, 0.34, 0.1, 1.0],
		["chest", Vector3(0, 0.62, 0.0), 6.0, 0.42, 0.14, 0.88],
		["chest", Vector3(0, 0.78, 0.0), -8.0, 0.44, 0.14, 0.88],
		["chest", Vector3(0, 0.94, 0.0), 7.0, 0.46, 0.14, 0.88],
		["chest", Vector3(0, 1.1, 0.0), -7.0, 0.46, 0.14, 0.88],
		["chest", Vector3(0, 1.24, 0.0), 6.0, 0.4, 0.12, 0.88],
		["upperarm.l", Vector3(0.30, 1.1, 0.0), -6.0, 0.19, 0.2, 1.0],
		["upperarm.l", Vector3(0.44, 1.1, 0.0), 6.0, 0.19, 0.2, 1.0],
		["lowerarm.l", Vector3(0.56, 1.1, 0.0), -6.0, 0.19, 0.2, 1.0],
		["lowerarm.l", Vector3(0.68, 1.1, 0.0), 6.0, 0.19, 0.2, 1.0],
		["upperarm.r", Vector3(-0.30, 1.1, 0.0), -6.0, 0.19, 0.2, 1.0],
		["upperarm.r", Vector3(-0.44, 1.1, 0.0), 6.0, 0.19, 0.2, 1.0],
		["lowerarm.r", Vector3(-0.56, 1.1, 0.0), -6.0, 0.19, 0.2, 1.0],
		["lowerarm.r", Vector3(-0.68, 1.1, 0.0), 6.0, 0.19, 0.2, 1.0],
	]
	for ring: Array in rings:
		var bone: String = ring[0]
		var pos: Vector3 = ring[1]
		var tilt: float = ring[2]
		var cylinder := LowPoly.cylinder(ring[3], ring[4])
		var basis := Basis.from_euler(Vector3(deg_to_rad(tilt), 0, 0))
		if bone.begins_with("upperarm") or bone.begins_with("lowerarm"):
			basis = Basis.from_euler(Vector3(0, 0, PI / 2)) * Basis.from_euler(
				Vector3(deg_to_rad(tilt), 0, 0))
		basis = basis * Basis.from_scale(Vector3(1, 1, ring[5]))
		_hang_on_bone(bones, bone, cylinder, color, Transform3D(basis, pos))
	# Loose ends: a strip from each wrist and one from the hip.
	var strip := BoxMesh.new()
	strip.size = Vector3(0.1, 0.5, 0.02)
	for end: Array in [["wrist.l", Vector3(0.7, 0.86, 0.04)], ["wrist.r", Vector3(-0.7, 0.8, -0.04)],
			["hips", Vector3(0.2, 0.3, 0.2)]]:
		_hang_on_bone(bones, end[0], strip, color * 0.92,
			Transform3D(Basis.from_euler(Vector3(0.1, 0, 0.08)), end[1]))
	# The eyes: a dim ember in the dark of the head wrap.
	var eyes := bones.get_node("Skeleton_Warrior_Eyes") as MeshInstance3D
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color(0.2, 0.05, 0.02)
	glow.emission_enabled = true
	glow.emission = Color(1.0, 0.45, 0.12)
	glow.emission_energy_multiplier = 1.4
	eyes.set_surface_override_material(0, glow)


## One piece of the wraps, placed by a transform in the rig's rest pose and hung from a bone.
func _hang_on_bone(bones: Skeleton3D, bone: String, mesh: Mesh, color: Color,
		rig_transform: Transform3D) -> void:
	var slot := BoneAttachment3D.new()
	slot.bone_name = bone
	bones.add_child(slot)
	add_mesh(slot, mesh, color, Vector3.ZERO, 0.95)
	var mi := slot.get_child(-1) as MeshInstance3D
	mi.transform = bones.get_bone_global_rest(bones.find_bone(bone)).affine_inverse() * rig_transform


## The Devorador wakes (its second phase): a red flash while its eye opens and the whole mass
## grows by DEVOURER_GROWTH; its bar goes up with it.
func _devourer_wakes() -> void:
	_set_flash(true, ActorLooks.LOOKS[look].glow_color)
	var t := create_tween().set_parallel()
	t.tween_property(_devourer, "scale", _devourer.scale * DEVOURER_GROWTH, 0.9) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_eyelid, "rotation_degrees:x", EYELID_OPEN, 0.9)
	await t.finished
	_top *= 1.1  # the bar rises with it, still on screen
	_set_flash(false)


## The waiting loop of the figures built in code: the bat flaps, the plant sways, the
## specter floats, the rest squash and stretch (the wolf, the golems and the spider only
## breathe).
func _start_idle() -> void:
	if look in [Look.BOARD, Look.CANTEEN, Look.POT]:
		return
	if not _wings.is_empty():
		_start_flap()
	elif _sway:
		_start_sway()
	elif _hover:
		_start_float()
	else:
		var gentle := look in [Look.WOLF, Look.MUD_GOLEM, Look.STONE_GOLEM, Look.SPIDER,
			Look.CAT, Look.WOLF_CUB, Look.MINI_GOLEM, Look.SNAKE, Look.MONKEY, Look.JAGUAR,
			Look.SAND_GOLEM, Look.SCORPION, Look.SNOW_WOLF, Look.ICE_GOLEM, Look.GOAT, Look.RUIN_RAT,
			Look.PORTAL_DEVOURER]
		_start_bounce(0.4 if gentle else 1.0)


## Floating loop of the specter. Only _hover moves, so hits and dodges can move _body.
func _start_float() -> void:
	if _idle_tween:
		_idle_tween.kill()
	var fly: float = ActorLooks.LOOKS[look].fly
	_idle_tween = create_tween().set_loops()
	for y in [fly + 0.18, fly]:
		_idle_tween.tween_property(_hover, "position:y", y, 0.8) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## Flapping wings, for the bat. Only the wing pivots are tweened, so hits, attacks and
## dodges can move _body freely.
func _start_flap() -> void:
	if _idle_tween:
		_idle_tween.kill()
	_idle_tween = create_tween().set_loops()
	var beat: float = ActorLooks.LOOKS[look].get("flap_time", 0.18)
	for angle in [0.6, -0.4]:
		_idle_tween.tween_property(_wings[0], "rotation:z", -angle, beat) \
			.set_trans(Tween.TRANS_SINE)
		_idle_tween.parallel().tween_property(_wings[1], "rotation:z", angle, beat) \
			.set_trans(Tween.TRANS_SINE)


## Swaying loop of the plant. Only _sway turns, so hits and the stagger can move and
## turn _body freely.
func _start_sway() -> void:
	if _idle_tween:
		_idle_tween.kill()
	_idle_tween = create_tween().set_loops()
	for angle in [0.09, -0.09]:
		_idle_tween.tween_property(_sway, "rotation:z", angle, 0.6) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## Squash-and-stretch loop of the slimes while they wait (amount 1: full; less for a
## gentler breath).
func _start_bounce(amount := 1.0) -> void:
	if _idle_tween:
		_idle_tween.kill()
	_idle_tween = create_tween().set_loops()
	_idle_tween.tween_property(_body, "scale",
		Vector3(1.0 + 0.08 * amount, 1.0 - 0.1 * amount, 1.0 + 0.08 * amount), 0.35) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_idle_tween.tween_property(_body, "scale", Vector3.ONE, 0.35) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _hop() -> void:
	var t := create_tween()
	t.tween_property(_body, "position:y", 0.35, 0.15) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(_body, "position:y", 0.0, 0.15) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await t.finished


## Plays the role's animation once at ACTION_SPEED and returns a timer that runs out
## when it ends; null for slimes, which have no animations.
func _start(role: String) -> SceneTreeTimer:
	if _anim == null:
		return null
	var anim_name: String = _anims[role]
	_anim.play(anim_name, BLEND_TIME, ACTION_SPEED)
	return get_tree().create_timer(_anim.get_animation(anim_name).length / ACTION_SPEED)


## Waits for a timer from _start() (if any) and goes back to the idle loop.
func _end(timer: SceneTreeTimer) -> void:
	if timer == null:
		return
	if timer.time_left > 0.0:
		await timer.timeout
	_anim.play(_anims.idle, BLEND_TIME)


## A damage number over the actor; color_token names its colour (a critical one is always
## text-display); tag floats under it.
func _spawn_number(amount: int, crit: bool, color_token := &"text-primary", tag := Tag.NONE) -> void:
	var tag_y := _top - 0.3
	if crit:
		_float_label("¡Crítico!", &"label", &"text-accent", TAG_WORLD, tag_y)
		tag_y -= 0.3  # a weak or resist tag goes under the crit one
	match tag:
		Tag.WEAK:
			_float_label("¡Débil!", &"label", &"element-weak", TAG_WORLD, tag_y)
		Tag.RESIST:
			_float_label("¡Resiste!", &"label", &"text-secondary", TAG_WORLD, tag_y)
	if crit:
		_float_label(str(amount), &"display-m", &"text-display", NUMBER_CRIT_WORLD, _top,
			NUMBER_CRIT_FONT)
	else:
		_float_label(str(amount), &"display-m", color_token, NUMBER_WORLD, _top, NUMBER_FONT)


## A billboard text drawn over everything that floats up from height y and fades out.
## world_height is how tall a font px-height text stands in the world (pixel_size is set so).
func _float_label(text: String, style: StringName, color_token: StringName,
		world_height: float, y: float, font_size := 0) -> void:
	var label := Label3D.new()
	label.text = text
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	UiTheme.style_3d(label, style, color_token, UiTokens.OUTLINE_M)
	if font_size > 0:
		label.font_size = font_size
	label.pixel_size = world_height / float(label.font_size)
	label.position = Vector3(0, y, 0)
	add_child(label)
	var t := label.create_tween().set_parallel()
	t.tween_property(label, "position:y", y + 0.8, 0.8)
	t.tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.2)
	t.chain().tween_callback(label.queue_free)


## Gives every mesh of an imported model copies of its materials with albedo_color
## multiplied by color (the texture is multiplied too).
static func _tint(model: Node3D, color: Color) -> void:
	for node in model.find_children("*", "MeshInstance3D", true, false):
		_tint_mesh(node as MeshInstance3D, color)


static func _tint_mesh(mi: MeshInstance3D, color: Color) -> void:
	for i in mi.mesh.get_surface_count():
		var source := mi.get_active_material(i) as BaseMaterial3D
		if source == null:
			continue
		var tinted := source.duplicate() as BaseMaterial3D
		tinted.albedo_color = source.albedo_color * color
		mi.set_surface_override_material(i, tinted)


## Additive overlay on every mesh, so it works on the imported materials too. Off, the
## figure keeps its highlight if it is being aimed at.
func _set_flash(on: bool, color := Color.WHITE) -> void:
	_flash.albedo_color = Color(color, FLASH_ALPHA)
	for mi in _meshes:
		mi.material_overlay = _flash if on else (_highlight if _highlighted else _map_overlay)


## A soft glow over the figure while the player aims at it; a flash still shows over it.
func set_highlight(on: bool) -> void:
	_highlighted = on
	for mi in _meshes:
		if mi.material_overlay != _flash:
			mi.material_overlay = _highlight if on else _map_overlay


func _set_alpha(alpha: float) -> void:
	for mat in _materials:
		mat.albedo_color.a = alpha
	for ghost in _ghosts:
		(ghost[0] as StandardMaterial3D).albedo_color.a = ghost[1] * alpha


## Builders only (CreatureBuilder, CharacterBuilder): the visual root the figure hangs
## from; the tweens move and scale it, the actor node itself stays put.
func body() -> Node3D:
	return _body


## Builders only: a wing pivot the idle loop flaps (the bat, the griffin, the gargoyle).
func add_wing(pivot: Node3D) -> void:
	_wings.append(pivot)


## Builders only: the node the idle loop sways (the plant, the worm).
func set_sway(node: Node3D) -> void:
	_sway = node


## Builders only: the plant's upper jaw, which play_attack() opens to bite.
func set_jaw(node: Node3D) -> void:
	_jaw = node


## Builders only: the node the specter's idle loop floats up and down.
func set_hover(node: Node3D) -> void:
	_hover = node


## Builders only: the Devorador's mass (it grows in its second phase) and its eyelid's pivot.
func set_devourer(mass: Node3D, eyelid: Node3D) -> void:
	_devourer = mass
	_eyelid = eyelid


## Builders only: a mesh in one flat colour under parent; its material fades with the
## figure on defeat.
func add_mesh(parent: Node3D, mesh: Mesh, color: Color, pos: Vector3, \
		roughness := 0.8) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	_materials.append(mat)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)


## Builders only: a see-through glowing mesh (the specter): its opacity rests at alpha and
## fades with the rest of the figure on defeat. It casts no shadow.
func add_ghost(parent: Node3D, mesh: Mesh, color: Color, alpha: float, pos: Vector3, \
		scl: Vector3) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color, alpha)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = color * 0.35
	mat.roughness = 0.6
	_ghosts.append([mat, alpha])
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = pos
	mi.scale = scl
	parent.add_child(mi)


## Builders only: a faceted lathe (LowPoly.blob) of profile at pos, turned rot_deg and scaled scl.
func add_blob(parent: Node3D, profile: Array[Vector2], segments: int, color: Color, \
		pos: Vector3, rot_deg := Vector3.ZERO, scl := Vector3.ONE) -> void:
	add_mesh(parent, LowPoly.blob(profile, segments), color, pos, 0.8)
	var mi := parent.get_child(-1) as MeshInstance3D
	mi.rotation_degrees = rot_deg
	mi.scale = scl
