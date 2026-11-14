class_name CreatureBuilder extends RefCounted
## Constructor: the BattleActor figures built in code (the slimes, the bat, the mushroom,
## the wolf, the golems, the spider, the specter, the plant, the creatures that fight beside
## the hero...), each from its ActorLooks.LOOKS entry. Static only, keeps no state: each
## build_x(actor, data) hangs its meshes under actor.body() through the actor's builder
## methods (add_mesh, add_blob, add_ghost) and names its moving parts with add_wing,
## set_sway, set_jaw and set_hover, never the actor's private members.

## The Rey Slime's crown.
const GOLD := Color(1.0, 0.8, 0.2)
## Side profile of a slime (x = radius, y = height), bottom to top: a drop with a tip.
const SLIME_PROFILE: Array[Vector2] = [
	Vector2(0.0, 0.0), Vector2(0.48, 0.0), Vector2(0.62, 0.18), Vector2(0.58, 0.42),
	Vector2(0.44, 0.64), Vector2(0.24, 0.8), Vector2(0.08, 0.9), Vector2(0.0, 0.98),
]
const SLIME_SEGMENTS := 9
## Side profiles of the wolf's body (tail to chest) and head (neck to snout), lathed
## around +Y and laid along -Z, and of a leg.
const WOLF_BODY_PROFILE: Array[Vector2] = [
	Vector2(0.0, 0.0), Vector2(0.18, 0.05), Vector2(0.27, 0.3), Vector2(0.3, 0.7),
	Vector2(0.26, 1.0), Vector2(0.0, 1.1),
]
const WOLF_HEAD_PROFILE: Array[Vector2] = [
	Vector2(0.0, 0.0), Vector2(0.2, 0.02), Vector2(0.22, 0.18), Vector2(0.14, 0.4),
	Vector2(0.05, 0.55), Vector2(0.0, 0.56),
]
const LEG_PROFILE: Array[Vector2] = [
	Vector2(0.0, 0.0), Vector2(0.07, 0.0), Vector2(0.08, 0.3), Vector2(0.06, 0.55),
	Vector2(0.0, 0.56),
]
## Side profiles (lathed around +Y) of a golem's chunk (4 sides: a faceted block), of the
## spider's abdomen and of the specter (a drop with its tip down).
const BLOCK_PROFILE: Array[Vector2] = [
	Vector2(0.0, 0.0), Vector2(0.42, 0.0), Vector2(0.5, 0.15), Vector2(0.5, 0.75),
	Vector2(0.4, 0.95), Vector2(0.0, 1.0),
]
const ABDOMEN_PROFILE: Array[Vector2] = [
	Vector2(0.0, 0.0), Vector2(0.22, 0.04), Vector2(0.36, 0.25), Vector2(0.34, 0.5),
	Vector2(0.2, 0.68), Vector2(0.0, 0.72),
]
const SPECTER_PROFILE: Array[Vector2] = [
	Vector2(0.0, 0.0), Vector2(0.14, 0.18), Vector2(0.34, 0.42), Vector2(0.42, 0.68),
	Vector2(0.36, 0.92), Vector2(0.18, 1.06), Vector2(0.0, 1.1),
]
## Opacity of the specter's body and of its aura.
const SPECTER_ALPHA := 0.6
const AURA_ALPHA := 0.22


static func build_slime(actor: BattleActor, data: Dictionary) -> void:
	var color: Color = data.color
	var blob := Node3D.new()
	blob.scale = Vector3.ONE * data.scale
	actor.body().add_child(blob)
	actor.add_mesh(blob, LowPoly.blob(SLIME_PROFILE, SLIME_SEGMENTS), color, Vector3.ZERO, 0.6)
	for x in [-0.2, 0.2]:
		actor.add_mesh(blob, LowPoly.sphere(0.12), Color.WHITE, Vector3(x, 0.5, -0.44))  # eye
		actor.add_mesh(blob, LowPoly.sphere(0.055), Color(0.05, 0.05, 0.05), Vector3(x, 0.5, -0.55))  # pupil
	if data.crown:
		var band := LowPoly.cylinder(0.27, 0.14)
		band.top_radius = 0.22
		actor.add_mesh(blob, band, GOLD, Vector3(0, 0.86, 0), 0.4)
		for i in 5:
			var angle := TAU * i / 5.0
			actor.add_mesh(blob, LowPoly.cone(0.06, 0.16), GOLD,
				Vector3(cos(angle) * 0.19, 1.01, sin(angle) * 0.19), 0.4)  # spike


## A notice board on two posts, with its papers on the side it faces (-Z).
static func build_board(actor: BattleActor, data: Dictionary) -> void:
	var post := BoxMesh.new()
	post.size = Vector3(0.12, 1.7, 0.12)
	for x in [-0.6, 0.6]:
		actor.add_mesh(actor.body(), post, data.dark_color, Vector3(x, 0.85, 0))
	var board := BoxMesh.new()
	board.size = Vector3(1.5, 0.9, 0.08)
	actor.add_mesh(actor.body(), board, data.color, Vector3(0, 1.3, 0))
	var paper := BoxMesh.new()
	paper.size = Vector3(0.32, 0.4, 0.01)
	for spot in [Vector3(-0.42, 1.32, -0.05), Vector3(0.02, 1.26, -0.05),
			Vector3(0.44, 1.36, -0.05)]:
		actor.add_mesh(actor.body(), paper, data.paper_color, spot)


## A sitting cat: a rounded body, a head with pointed ears and eyes, and a tail.
static func build_cat(actor: BattleActor, data: Dictionary) -> void:
	var root := Node3D.new()
	root.scale = Vector3.ONE * data.scale
	actor.body().add_child(root)
	actor.add_blob(root, SLIME_PROFILE, SLIME_SEGMENTS, data.color, Vector3.ZERO, Vector3.ZERO,
		Vector3(0.5, 0.6, 0.65))
	actor.add_mesh(root, LowPoly.sphere(0.2), data.color, Vector3(0, 0.62, -0.1))
	for x in [-0.11, 0.11]:
		actor.add_mesh(root, LowPoly.cone(0.07, 0.16), data.dark_color, Vector3(x, 0.84, -0.1))  # ear
		actor.add_mesh(root, LowPoly.sphere(0.04), data.eye_color, Vector3(x * 0.8, 0.66, -0.28))  # eye
	actor.add_mesh(root, LowPoly.cylinder(0.04, 0.5), data.dark_color, Vector3(0, 0.22, 0.4))  # tail
	(root.get_child(-1) as Node3D).rotation_degrees.x = 60.0


## A bat: round body with ears and eyes, hovering at data.fly, with two wings on pivots
## that the idle loop flaps.
static func build_bat(actor: BattleActor, data: Dictionary) -> void:
	var color: Color = data.color
	var root := Node3D.new()
	root.position.y = data.fly
	actor.body().add_child(root)
	actor.add_mesh(root, LowPoly.sphere(0.32), color, Vector3.ZERO, 0.7)
	if data.has("beak_color"):  # the Buitre: a ruff, a bald head on it and a hooked beak
		actor.add_mesh(root, LowPoly.sphere(0.2), data.ruff_color, Vector3(0, 0.2, -0.16))
		actor.add_mesh(root, LowPoly.sphere(0.12), data.head_color, Vector3(0, 0.36, -0.34))
		actor.add_mesh(root, LowPoly.cone(0.05, 0.16), data.beak_color, Vector3(0, 0.33, -0.48))
		(root.get_child(-1) as Node3D).rotation_degrees.x = -100.0
		for x in [-0.06, 0.06]:
			actor.add_mesh(root, LowPoly.sphere(0.025), Color(0.05, 0.05, 0.05), Vector3(x, 0.4, -0.43))
	else:
		for x in [-0.14, 0.14]:
			actor.add_mesh(root, LowPoly.cone(0.08, 0.22), color, Vector3(x, 0.36, 0))  # ear
			actor.add_mesh(root, LowPoly.sphere(0.08), Color(1.0, 0.85, 0.3),
				Vector3(x * 0.9, 0.08, -0.27))  # eye
			actor.add_mesh(root, LowPoly.sphere(0.035), Color(0.05, 0.05, 0.05),
				Vector3(x * 0.9, 0.08, -0.34))  # pupil
	for side in [-1.0, 1.0]:
		var pivot := Node3D.new()
		pivot.position = Vector3(0.22 * side, 0.05, 0)
		root.add_child(pivot)
		var wing := BoxMesh.new()
		wing.size = data.get("wing_size", Vector3(0.75, 0.04, 0.42))
		actor.add_mesh(pivot, wing, data.wing_color, Vector3(wing.size.x / 2.0 * side, 0, 0.05))
		actor.add_wing(pivot)


## A mushroom: pale stem with eyes and a red hemisphere cap with white spots.
static func build_mushroom(actor: BattleActor, data: Dictionary) -> void:
	var root := Node3D.new()
	root.scale = Vector3.ONE * data.scale
	actor.body().add_child(root)
	var stem := LowPoly.cylinder(0.2, 0.55)
	stem.top_radius = 0.16
	actor.add_mesh(root, stem, data.stem_color, Vector3(0, 0.275, 0))
	for x in [-0.08, 0.08]:
		actor.add_mesh(root, LowPoly.sphere(0.05), Color(0.05, 0.05, 0.05), Vector3(x, 0.32, -0.18))  # eye
	var cap := SphereMesh.new()
	cap.radius = 0.5
	cap.height = 0.42
	cap.is_hemisphere = true
	cap.radial_segments = 9
	cap.rings = 3
	actor.add_mesh(root, cap, data.cap_color, Vector3(0, 0.5, 0), 0.6)
	for i in 5:
		var angle := TAU * i / 5.0 + 0.3
		actor.add_mesh(root, LowPoly.sphere(0.07), Color.WHITE,
			Vector3(cos(angle) * 0.32, 0.83, sin(angle) * 0.32))  # spot
	actor.add_mesh(root, LowPoly.sphere(0.08), Color.WHITE, Vector3(0, 0.92, 0))  # top spot


## A wolf: a faceted body and a wedge head along -Z on four legs, with ears, yellow
## eyes and a tail.
static func build_wolf(actor: BattleActor, data: Dictionary) -> void:
	var root := Node3D.new()
	root.scale = Vector3.ONE * data.scale
	actor.body().add_child(root)
	actor.add_blob(root, WOLF_BODY_PROFILE, 6, data.color, Vector3(0, 0.62, 0.55),
		Vector3(-90, 0, 0))
	actor.add_blob(root, WOLF_HEAD_PROFILE, 5, data.color, Vector3(0, 0.82, -0.48),
		Vector3(-100, 0, 0))
	for x in [-0.1, 0.1]:
		actor.add_mesh(root, LowPoly.cone(0.06, 0.18), data.dark_color, Vector3(x, 1.06, -0.6))  # ear
		actor.add_mesh(root, LowPoly.sphere(0.045), data.eye_color, Vector3(x * 1.1, 0.92, -0.72))  # eye
		actor.add_mesh(root, LowPoly.sphere(0.022), Color(0.05, 0.05, 0.05),
			Vector3(x * 1.1, 0.92, -0.765))  # pupil
	actor.add_mesh(root, LowPoly.sphere(0.04), Color(0.05, 0.05, 0.05), Vector3(0, 0.74, -1.03))  # nose
	for x in [-0.17, 0.17]:
		for z in [-0.32, 0.34]:
			actor.add_blob(root, LEG_PROFILE, 4, data.dark_color, Vector3(x, 0.0, z))
	actor.add_mesh(root, LowPoly.cone(0.07, 0.45), data.color, Vector3(0, 0.8, 0.72))  # tail
	(root.get_child(-1) as Node3D).rotation_degrees.x = 55.0
	if data.has("spot_color"):  # the Jaguar sombrío: glowing rosettes on its back
		for spot in [Vector3(-0.12, 0.9, 0.35), Vector3(0.14, 0.92, 0.5), Vector3(0.0, 0.95, 0.1),
				Vector3(-0.16, 0.85, 0.72), Vector3(0.12, 0.88, -0.1)]:
			actor.add_mesh(root, LowPoly.sphere(0.055), data.spot_color, spot)
			var mat := (root.get_child(-1) as MeshInstance3D).material_override as StandardMaterial3D
			mat.emission_enabled = true
			mat.emission = data.spot_color * 0.6


## A chicken: a white round body with a red comb and wattle, an orange beak, two thin
## legs and black eyes, facing -Z. About 0.7 m tall.
static func build_chicken(actor: BattleActor, data: Dictionary) -> void:
	var root := Node3D.new()
	root.scale = Vector3.ONE * data.scale
	actor.body().add_child(root)
	actor.add_blob(root, SLIME_PROFILE, SLIME_SEGMENTS, data.color, Vector3(0, 0.2, 0.05),
		Vector3.ZERO, Vector3(0.4, 0.55, 0.5))  # body
	actor.add_mesh(root, LowPoly.sphere(0.17), data.color, Vector3(0, 0.62, -0.18))  # head
	actor.add_mesh(root, LowPoly.cone(0.1, 0.22), data.color, Vector3(0, 0.45, 0.32))  # tail
	(root.get_child(-1) as Node3D).rotation_degrees.x = -35.0
	actor.add_mesh(root, LowPoly.cone(0.05, 0.14), data.comb_color, Vector3(0, 0.82, -0.18))  # comb
	actor.add_mesh(root, LowPoly.sphere(0.045), data.comb_color, Vector3(0, 0.5, -0.3))  # wattle
	actor.add_mesh(root, LowPoly.cone(0.05, 0.14), data.beak_color, Vector3(0, 0.62, -0.38))  # beak
	(root.get_child(-1) as Node3D).rotation_degrees.x = -90.0
	for x in [-0.08, 0.08]:
		actor.add_mesh(root, LowPoly.sphere(0.025), Color(0.05, 0.05, 0.05),
			Vector3(x * 1.2, 0.67, -0.31))  # eye
		actor.add_mesh(root, LowPoly.cylinder(0.018, 0.2), data.leg_color, Vector3(x * 1.3, 0.1, 0.0))  # leg


## A goblin: a small green slime with pointed ears and a red pointed hat.
static func build_goblin(actor: BattleActor, data: Dictionary) -> void:
	var blob := Node3D.new()
	blob.scale = Vector3.ONE * data.scale
	actor.body().add_child(blob)
	actor.add_mesh(blob, LowPoly.blob(SLIME_PROFILE, SLIME_SEGMENTS), data.color, Vector3.ZERO, 0.7)
	for side in [-1.0, 1.0]:
		actor.add_mesh(blob, LowPoly.sphere(0.11), Color.WHITE, Vector3(side * 0.19, 0.52, -0.45))  # eye
		actor.add_mesh(blob, LowPoly.sphere(0.05), Color(0.05, 0.05, 0.05),
			Vector3(side * 0.19, 0.52, -0.55))  # pupil
		actor.add_mesh(blob, LowPoly.cone(0.12, 0.5), data.color, Vector3(side * 0.66, 0.62, 0))  # ear
		(blob.get_child(-1) as Node3D).rotation_degrees.z = -70.0 * side
	var hat := LowPoly.cone(0.34, 0.6)
	hat.radial_segments = 7
	actor.add_mesh(blob, hat, data.hat_color, Vector3(0, 1.08, 0.04))
	(blob.get_child(-1) as Node3D).rotation_degrees.x = 12.0


## A carnivorous plant: leaves at the foot of a stem with a round head of two jaws
## (the upper one on a pivot at the back, slightly open, with white teeth and spots).
static func build_plant(actor: BattleActor, data: Dictionary) -> void:
	var sway := Node3D.new()
	sway.scale = Vector3.ONE * data.scale
	actor.body().add_child(sway)
	actor.set_sway(sway)
	for i in 3:
		var leaf := Node3D.new()
		leaf.rotation.y = TAU * i / 3.0
		sway.add_child(leaf)
		actor.add_blob(leaf, LowPoly.BUSH_PROFILE, 5, data.leaf_color, Vector3(0, 0, 0.32),
			Vector3.ZERO, Vector3(0.45, 0.22, 0.6))
	actor.add_mesh(sway, LowPoly.cylinder(0.08, 0.95), data.stem_color, Vector3(0, 0.47, 0))
	var head := Node3D.new()
	head.position = Vector3(0, 0.98, 0)
	sway.add_child(head)
	actor.add_mesh(head, LowPoly.hemisphere(0.36, 0.24), data.head_color, Vector3.ZERO)
	(head.get_child(-1) as Node3D).rotation_degrees.x = 180.0
	actor.add_mesh(head, LowPoly.disc(0.33), data.inner_color, Vector3(0, 0.01, 0))
	var jaw := Node3D.new()
	jaw.position = Vector3(0, 0, 0.3)
	head.add_child(jaw)
	actor.set_jaw(jaw)
	actor.add_mesh(jaw, LowPoly.hemisphere(0.36, 0.3), data.head_color, Vector3(0, 0, -0.3))
	actor.add_mesh(jaw, LowPoly.disc(0.33), data.inner_color, Vector3(0, -0.01, -0.3))
	for i in 6:
		var angle := PI * (0.15 + 0.7 * i / 5.0)
		var rim := Vector3(cos(angle) * 0.3, 0, -sin(angle) * 0.3)
		actor.add_mesh(head, LowPoly.cone(0.035, 0.09), Color.WHITE, rim + Vector3(0, 0.04, 0))  # tooth
		actor.add_mesh(jaw, LowPoly.cone(0.035, 0.09), Color.WHITE, rim + Vector3(0, -0.04, -0.3))
		(jaw.get_child(-1) as Node3D).rotation_degrees.x = 180.0
	for spot in [Vector3(-0.15, 0.2, -0.45), Vector3(0.17, 0.22, -0.4), Vector3(0, 0.27, -0.2)]:
		actor.add_mesh(jaw, LowPoly.sphere(0.05), Color(1.0, 0.95, 0.8), spot)
	jaw.rotation.x = BattleActor.JAW_REST


## A golem: faceted blocks for the legs, the body, the head and two long arms, with
## glowing eyes and two loose stones on the shoulders.
static func build_golem(actor: BattleActor, data: Dictionary) -> void:
	var root := Node3D.new()
	root.scale = Vector3.ONE * data.scale
	actor.body().add_child(root)
	for x in [-0.22, 0.22]:
		actor.add_blob(root, BLOCK_PROFILE, 4, data.dark_color, Vector3(x, 0, 0), Vector3(0, 45, 0),
			Vector3(0.36, 0.42, 0.36))  # leg
	actor.add_blob(root, BLOCK_PROFILE, 4, data.color, Vector3(0, 0.38, 0), Vector3(0, 45, 0),
		Vector3(1.05, 0.72, 0.8))  # body
	actor.add_blob(root, BLOCK_PROFILE, 4, data.color, Vector3(0, 1.08, -0.06), Vector3(0, 45, 0),
		Vector3(0.5, 0.36, 0.46))  # head
	for x in [-0.12, 0.12]:
		actor.add_mesh(root, LowPoly.sphere(0.055), data.eye_color, Vector3(x, 1.24, -0.29), 0.2)  # eye
	for side in [-1.0, 1.0]:
		actor.add_blob(root, BLOCK_PROFILE, 4, data.dark_color, Vector3(side * 0.62, 0.12, -0.05),
			Vector3(0, 45, side * 8.0), Vector3(0.34, 0.86, 0.34))  # arm
		actor.add_blob(root, BLOCK_PROFILE, 4, data.color, Vector3(side * 0.42, 1.0, 0.05),
			Vector3(0, 20, 0), Vector3(0.22, 0.16, 0.22))  # loose stone


## A spider: a round abdomen behind a small head with red eyes, on eight bent legs
## (four a side, each a thigh going up and out and a shin going down to the ground).
static func build_spider(actor: BattleActor, data: Dictionary) -> void:
	var root := Node3D.new()
	root.scale = Vector3.ONE * data.scale
	actor.body().add_child(root)
	actor.add_blob(root, ABDOMEN_PROFILE, 7, data.color, Vector3(0, 0.42, 0.32), Vector3(-75, 0, 0),
		Vector3(1.1, 1.0, 1.0))  # abdomen
	actor.add_mesh(root, LowPoly.sphere(0.2), data.color, Vector3(0, 0.42, -0.12))  # head
	for x in [-0.07, 0.07]:
		actor.add_mesh(root, LowPoly.sphere(0.045), data.eye_color, Vector3(x, 0.5, -0.3), 0.2)  # eye
		actor.add_mesh(root, LowPoly.sphere(0.03), data.eye_color, Vector3(x * 2.0, 0.45, -0.28), 0.2)
	for side in [-1.0, 1.0]:
		for i in 4:
			var leg := Node3D.new()
			leg.position = Vector3(side * 0.14, 0.42, -0.2 + i * 0.13)
			# Each leg reaches out to +X of its pivot: the left ones are turned around.
			leg.rotation.y = deg_to_rad(40.0 - i * 27.0) * side + (PI if side < 0.0 else 0.0)
			root.add_child(leg)
			actor.add_mesh(leg, LowPoly.cylinder(0.03, 0.42), data.leg_color, Vector3(0.18, 0.13, 0))
			(leg.get_child(-1) as Node3D).rotation_degrees.z = -60.0  # thigh, up and out
			actor.add_mesh(leg, LowPoly.cylinder(0.025, 0.62), data.leg_color, Vector3(0.44, -0.12, 0))
			(leg.get_child(-1) as Node3D).rotation_degrees.z = 22.0  # shin, down to the ground


## A specter: a see-through pale drop with its tip down, floating at data.fly, with dark
## eyes and a wide blue aura around it.
static func build_specter(actor: BattleActor, data: Dictionary) -> void:
	var hover := Node3D.new()
	hover.position.y = data.fly
	hover.scale = Vector3.ONE * data.scale
	actor.body().add_child(hover)
	actor.set_hover(hover)
	actor.add_ghost(hover, LowPoly.blob(SPECTER_PROFILE, 8), data.color,
			data.get("alpha", SPECTER_ALPHA),
		Vector3.ZERO, Vector3.ONE)
	actor.add_ghost(hover, LowPoly.sphere(0.5), data.aura_color, AURA_ALPHA, Vector3(0, 0.62, 0),
		Vector3(1.5, 1.7, 1.5))
	for x in [-0.12, 0.12]:
		actor.add_mesh(hover, LowPoly.sphere(0.07), data.get("eye_color", Color(0.05, 0.05, 0.12)),
			Vector3(x, 0.8, -0.34))  # eye
	actor.add_mesh(hover, LowPoly.sphere(0.06), Color(0.05, 0.05, 0.12), Vector3(0, 0.6, -0.36))  # mouth


