class_name CharacterBuilder extends RefCounted
## Constructor: the BattleActor figures that are KayKit models (the hero, the villagers, the
## witch, the skeletons, the caravan's people, the companions...), from their
## ActorLooks.LOOKS entry: the model turned to face -Z with its props hidden, weapons on
## bones, tints, head texture, cape, hair pieces, the Momia's wraps, the Armadura's ember,
## an aura or a corona of light and the hero's stick. Static only, keeps no state: it writes
## into the actor through its builder methods (set_model, set_aura, set_animations,
## add_mesh...).

## Resting opacity of an aura (LOOKS "aura": the Señor de la Niebla, the Eco).
const FOG_AURA_ALPHA := 0.2
## The corona of light over the head (LOOKS "corona": the Eco de Albor, Albor; 3.3.0): a flat
## upright ring behind the head, CORONA_RADIUS wide and CORONA_THICKNESS thick, CORONA_LIFT over
## the head bone and CORONA_BACK behind it (in the model's own units), at CORONA_ALPHA. It is
## the figure's aura: the Eco's second phase (BattleActor.play_phase()) swells it and dims it
## to the aura's phase opacity.
const CORONA_RADIUS := 0.45
const CORONA_THICKNESS := 0.07
const CORONA_LIFT := 1.0
const CORONA_BACK := 0.35
const CORONA_ALPHA := 0.85
## Bones the weapons hang from, under the model's Rig/Skeleton3D.
const SKELETON_PATH := "Rig/Skeleton3D"
## The AnimationPlayer inside a KayKit character scene.
const ANIM_PLAYER_PATH := "AnimationPlayer"
## The wooden stick built in code for Equipment.STICK_MESH: along the hand's +Y like the
## Knight's swords, grip at the hand.
const STICK_COLOR := Color(0.45, 0.3, 0.16)
const STICK_RADIUS := 0.07
const STICK_LENGTH := 1.3
const STICK_CENTER := 0.45


## Builds the KayKit figure of data (a LOOKS entry with a "scene") on actor.
static func build(actor: BattleActor, data: Dictionary) -> void:
	var model: Node3D = (data.scene as PackedScene).instantiate()
	model.scale = Vector3.ONE * data.scale
	# KayKit characters face +Z; turned around they face -Z like every BattleActor.
	model.rotation.y = PI
	actor.body().add_child(model)
	actor.set_model(model)
	for path in data.hide:
		(model.get_node(path) as Node3D).hide()
	var bones := model.get_node_or_null(SKELETON_PATH) as Skeleton3D
	for bone: String in data.get("props", {}):
		var slot := BoneAttachment3D.new()
		slot.bone_name = bone
		bones.add_child(slot)
		slot.add_child((data.props[bone] as PackedScene).instantiate())
	if data.has("tint"):
		tint(model, data.tint)
	var mesh_tints: Dictionary = data.get("mesh_tints", {})
	for mesh_name: String in mesh_tints:
		tint_mesh(bones.get_node(mesh_name) as MeshInstance3D, mesh_tints[mesh_name])
	if data.has("neck_glow"):
		# The Armadura hueca: an ember where its head should be, on the head bone.
		var slot := BoneAttachment3D.new()
		slot.bone_name = "head"
		bones.add_child(slot)
		actor.add_mesh(slot, LowPoly.sphere(0.13), data.neck_glow, Vector3(0, 0.0, 0))
		var ember := (slot.get_child(-1) as MeshInstance3D).material_override as StandardMaterial3D
		ember.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if data.has("wrap_color"):
		_add_mummy_wraps(actor, bones, data.wrap_color)
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
		_add_hair(actor, model, data.hair)
	if data.has("aura"):
		actor.add_ghost(actor.body(), LowPoly.sphere(0.5), data.aura, FOG_AURA_ALPHA, Vector3(0, actor.top_height() * 0.45, 0),
			Vector3(2.2, 3.2, 2.2))
		actor.set_aura(actor.body().get_child(-1) as MeshInstance3D)
	if data.has("corona"):
		var crown := BoneAttachment3D.new()
		crown.bone_name = "head"
		bones.add_child(crown)
		var ring := TorusMesh.new()
		ring.inner_radius = CORONA_RADIUS - CORONA_THICKNESS
		ring.outer_radius = CORONA_RADIUS
		ring.rings = 16
		ring.ring_segments = 6
		actor.add_ghost(crown, ring, data.corona, CORONA_ALPHA, Vector3(0, CORONA_LIFT, -CORONA_BACK),
			Vector3.ONE)
		(crown.get_child(-1) as Node3D).rotation_degrees.x = 90.0
		actor.set_aura(crown.get_child(-1) as MeshInstance3D)
	if actor.look == ActorLooks.Look.HERO:
		var stick := LowPoly.cylinder(STICK_RADIUS, STICK_LENGTH)
		stick.top_radius = STICK_RADIUS * 0.7
		actor.add_mesh(model.get_node(BattleActor.HAND_R), stick, STICK_COLOR, Vector3(0, STICK_CENTER, 0))
		var mi := model.get_node(BattleActor.HAND_R).get_child(-1) as MeshInstance3D
		mi.name = Equipment.STICK_MESH
		# The starting gear until set_equipment() says otherwise.
		actor.set_equipment(Equipment.STICK, "")
	var anim := model.get_node(ANIM_PLAYER_PATH) as AnimationPlayer
	# The imported animations do not loop; idle and walk must.
	for role in ["idle", "walk"]:
		anim.get_animation(data.anims[role]).loop_mode = Animation.LOOP_LINEAR
	actor.set_animations(anim, data.anims)


## A hair piece (ActorLooks.HAIR_PIECES: a beard, a bun or a ponytail), faceted like the slimes, in the
## hair's colour, hung from the head bone's attachment so it follows every animation.
static func _add_hair(actor: BattleActor, model: Node3D, hair: Dictionary) -> void:
	var head := model.get_node("Rig/Skeleton3D/head") as Node3D
	var piece: Dictionary = ActorLooks.HAIR_PIECES[hair.style]
	var profile: Array[Vector2] = []
	profile.assign(ActorLooks.HAIR_PROFILES[piece.profile])
	actor.add_blob(head, profile, ActorLooks.HAIR_SEGMENTS, hair.color, piece.pos, piece.rot, piece.scale)


## The Momia's bandages: flat rings of linen (squashed cylinders, each a little tilted the
## other way than the last) round the head, the chest and both arms, a gap at the eyes,
## and loose strips hanging from the wrists and the hip. Each is placed in the rig's rest
## pose and hung from its bone, so it follows the animation.
static func _add_mummy_wraps(actor: BattleActor, bones: Skeleton3D, color: Color) -> void:
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
		_hang_on_bone(actor, bones, bone, cylinder, color, Transform3D(basis, pos))
	# Loose ends: a strip from each wrist and one from the hip.
	var strip := BoxMesh.new()
	strip.size = Vector3(0.1, 0.5, 0.02)
	for end: Array in [["wrist.l", Vector3(0.7, 0.86, 0.04)], ["wrist.r", Vector3(-0.7, 0.8, -0.04)],
			["hips", Vector3(0.2, 0.3, 0.2)]]:
		_hang_on_bone(actor, bones, end[0], strip, color * 0.92,
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
static func _hang_on_bone(actor: BattleActor, bones: Skeleton3D, bone: String, mesh: Mesh, color: Color,
		rig_transform: Transform3D) -> void:
	var slot := BoneAttachment3D.new()
	slot.bone_name = bone
	bones.add_child(slot)
	actor.add_mesh(slot, mesh, color, Vector3.ZERO, 0.95)
	var mi := slot.get_child(-1) as MeshInstance3D
	mi.transform = bones.get_bone_global_rest(bones.find_bone(bone)).affine_inverse() * rig_transform


## Gives every mesh of an imported model copies of its materials with albedo_color
## multiplied by color (the texture is multiplied too).
static func tint(model: Node3D, color: Color) -> void:
	for node in model.find_children("*", "MeshInstance3D", true, false):
		tint_mesh(node as MeshInstance3D, color)


static func tint_mesh(mi: MeshInstance3D, color: Color) -> void:
	for i in mi.mesh.get_surface_count():
		var source := mi.get_active_material(i) as BaseMaterial3D
		if source == null:
			continue
		var tinted := source.duplicate() as BaseMaterial3D
		tinted.albedo_color = source.albedo_color * color
		# The mesh also keeps the copy in its metadata, which outlives its render instance: freed
		# first (the last mesh of a model with no one after it), the dummy renderer of --headless
		# runs reads the freed material and prints "Parameter material is null".
		mi.set_meta(&"tinted_%d" % i, tinted)
		mi.set_surface_override_material(i, tinted)
