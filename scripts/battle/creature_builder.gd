class_name CreatureBuilder extends RefCounted
## Constructor: the BattleActor figures built in code (the slimes, the bat, the mushroom,
## the wolf, the golems, the spider, the specter, the plant, the creatures that fight beside
## the hero...), each from its ActorLooks.LOOKS entry. Static only, keeps no state: each
## build_x(actor, data) hangs its meshes under actor.body() through the actor's builder
## methods (add_mesh, add_blob, add_ghost) and names its moving parts with add_wing,
## set_sway, set_jaw and set_hover, never the actor's private members.

const Look = ActorLooks.Look

## The Devorador del portal: the side profile of its mass (lathed around +Y), its eyelid's
## angle half closed, its lumps ([degrees from the front, height, size]) and its mouths round
## the mass ([degrees from the front, height]).
const DEVOURER_PROFILE: Array[Vector2] = [
	Vector2(0.0, 0.0), Vector2(1.25, 0.1), Vector2(1.45, 0.7), Vector2(1.3, 1.6),
	Vector2(1.0, 2.4), Vector2(0.55, 3.0), Vector2(0.0, 3.2),
]
const EYELID_HALF := 0.0
const DEVOURER_LUMPS := [[180.0, 1.5, 0.7], [105.0, 2.3, 0.5], [-105.0, 2.3, 0.5],
	[160.0, 0.45, 0.45], [-160.0, 0.45, 0.45], [60.0, 0.35, 0.35], [-60.0, 0.35, 0.35]]
const DEVOURER_MOUTHS := [[38.0, 1.0], [-38.0, 1.0], [82.0, 1.9], [-82.0, 1.9],
	[140.0, 1.2], [-140.0, 1.2]]
## The trees' shader, for the pot's vertex colours (NatureModels meshes have no material).
const TREE_SHADER := preload("res://shaders/tree.gdshader")
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


## Builds the figure of a look without a KayKit scene: picks its build_x from actor.look.
static func build(actor: BattleActor, data: Dictionary) -> void:
	var look: int = actor.look
	if look in [Look.BAT, Look.CRYPT_BAT, Look.VULTURE, Look.ICE_BAT]:
		build_bat(actor, data)
	elif look in [Look.MUSHROOM, Look.POISON_MUSHROOM, Look.CAVE_MUSHROOM,
			Look.TROPICAL_MUSHROOM]:
		build_mushroom(actor, data)
	elif look in [Look.WOLF, Look.WOLF_CUB, Look.JAGUAR, Look.SNOW_WOLF]:
		build_wolf(actor, data)
	elif look == Look.CHICKEN:
		build_chicken(actor, data)
	elif look == Look.GOBLIN:
		build_goblin(actor, data)
	elif look == Look.PLANT or look == Look.TRAP_PLANT:
		build_plant(actor, data)
	elif look == Look.FROG:
		build_frog(actor, data)
	elif look == Look.SNAKE:
		build_snake(actor, data)
	elif look == Look.MONKEY:
		build_monkey(actor, data)
	elif look in [Look.MUD_GOLEM, Look.STONE_GOLEM, Look.MINI_GOLEM, Look.SAND_GOLEM,
			Look.ICE_GOLEM]:
		build_golem(actor, data)
	elif look == Look.SPIDER:
		build_spider(actor, data)
	elif look in [Look.SPECTER, Look.FROST_SPECTER, Look.SUMMIT_SPIRIT, Look.SHADOW]:
		build_specter(actor, data)
	elif look == Look.GOAT:
		build_goat(actor, data)
	elif look == Look.GRIFFIN:
		build_griffin(actor, data)
	elif look == Look.GARGOYLE:
		build_gargoyle(actor, data)
	elif look == Look.RUIN_RAT:
		build_rat(actor, data)
	elif look == Look.PORTAL_DEVOURER:
		build_devourer(actor, data)
	elif look == Look.SCORPION:
		build_scorpion(actor, data)
	elif look == Look.SAND_WORM:
		build_worm(actor, data)
	elif look == Look.CANTEEN:
		build_canteen(actor, data)
	elif look == Look.POT:
		build_pot(actor, data)
	elif look == Look.BOARD:
		build_board(actor, data)
	elif look == Look.CAT:
		build_cat(actor, data)
	else:
		build_slime(actor, data)


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


## A mountain goat: a stocky body on four thin legs, a wedge head tilted down with a pale
## muzzle and a beard, and two thick horns curling back and down, facing -Z. About 1.5 m
## tall at its scale.
static func build_goat(actor: BattleActor, data: Dictionary) -> void:
	var root := Node3D.new()
	root.scale = Vector3.ONE * data.scale
	actor.body().add_child(root)
	actor.add_blob(root, WOLF_BODY_PROFILE, 6, data.color, Vector3(0, 0.7, 0.45),
		Vector3(-90, 0, 0), Vector3(1.15, 1.0, 1.1))  # body
	actor.add_mesh(root, LowPoly.sphere(0.2), data.belly_color, Vector3(0, 0.58, 0.05))  # belly
	actor.add_mesh(root, LowPoly.cylinder(0.14, 0.5), data.color, Vector3(0, 1.0, -0.32))  # neck
	(root.get_child(-1) as Node3D).rotation_degrees.x = -35.0
	actor.add_blob(root, WOLF_HEAD_PROFILE, 5, data.color, Vector3(0, 1.12, -0.5),
		Vector3(-115, 0, 0), Vector3(0.9, 0.9, 0.9))  # head, tilted down
	actor.add_mesh(root, LowPoly.sphere(0.08), data.belly_color, Vector3(0, 0.98, -0.84))  # muzzle
	actor.add_mesh(root, LowPoly.cone(0.05, 0.18), data.belly_color, Vector3(0, 0.84, -0.78))  # beard
	(root.get_child(-1) as Node3D).rotation_degrees.x = 180.0
	for side in [-1.0, 1.0]:
		actor.add_mesh(root, LowPoly.sphere(0.035), data.eye_color, Vector3(side * 0.1, 1.17, -0.68))
		for i in 7:  # a horn: shrinking balls rising from the head, curling back and down
			var t := i / 6.0
			actor.add_mesh(root, LowPoly.sphere(0.085 - t * 0.05), data.horn_color,
				Vector3(side * (0.1 + t * 0.08), 1.2 + 0.2 * sin(t * PI) - 0.1 * t,
					-0.5 + t * 0.55))
	for x in [-0.16, 0.16]:
		for z in [-0.25, 0.35]:
			actor.add_blob(root, LEG_PROFILE, 4, data.dark_color, Vector3(x, 0.0, z), Vector3.ZERO,
				Vector3(0.8, 1.15, 0.8))
	actor.add_mesh(root, LowPoly.cone(0.05, 0.15), data.color, Vector3(0, 0.85, 0.72))  # tail
	(root.get_child(-1) as Node3D).rotation_degrees.x = 40.0


## The Grifo de la cumbre: a lion's tawny body on four legs with a tufted tail, a white-
## feathered chest, an eagle's white head with a hooked golden beak and ear tufts, and two
## broad wings on pivots (the bat's wings, BattleActor.add_wing(): they beat slowly, LOOKS "flap_time"), facing -Z.
## About 3.1 m tall at its scale.
static func build_griffin(actor: BattleActor, data: Dictionary) -> void:
	var root := Node3D.new()
	root.scale = Vector3.ONE * data.scale
	actor.body().add_child(root)
	actor.add_blob(root, WOLF_BODY_PROFILE, 6, data.color, Vector3(0, 0.62, 0.55),
		Vector3(-90, 0, 0), Vector3(1.25, 1.15, 1.1))  # lion body
	for x in [-0.18, 0.18]:
		for z in [-0.3, 0.38]:
			actor.add_blob(root, LEG_PROFILE, 4, data.dark_color, Vector3(x, 0.0, z))
		actor.add_mesh(root, LowPoly.cone(0.04, 0.1), data.beak_color, Vector3(x, 0.02, -0.42))  # talons
	actor.add_mesh(root, LowPoly.sphere(0.3), data.feather_color, Vector3(0, 0.95, -0.32))  # chest
	(root.get_child(-1) as Node3D).scale = Vector3(1.0, 1.15, 0.9)
	actor.add_mesh(root, LowPoly.sphere(0.2), data.feather_color, Vector3(0, 1.3, -0.5))  # head
	actor.add_mesh(root, LowPoly.cone(0.07, 0.22), data.beak_color, Vector3(0, 1.26, -0.74))  # beak
	(root.get_child(-1) as Node3D).rotation_degrees.x = -100.0
	for x in [-0.09, 0.09]:
		actor.add_mesh(root, LowPoly.sphere(0.035), data.eye_color, Vector3(x, 1.36, -0.64))
		actor.add_mesh(root, LowPoly.cone(0.04, 0.14), data.feather_color, Vector3(x, 1.5, -0.42))  # tuft
	actor.add_mesh(root, LowPoly.cylinder(0.03, 0.6), data.color, Vector3(0, 0.75, 1.0))  # tail
	(root.get_child(-1) as Node3D).rotation_degrees.x = 60.0
	actor.add_mesh(root, LowPoly.sphere(0.08), data.dark_color, Vector3(0, 0.98, 1.24))  # tail tuft
	for side in [-1.0, 1.0]:
		var pivot := Node3D.new()
		pivot.position = Vector3(0.22 * side, 1.05, 0.1)
		root.add_child(pivot)
		var spread := Node3D.new()  # the open wing: an arm and a fan of flight feathers
		spread.rotation_degrees = Vector3(-32.0, -14.0 * side, 10.0 * side)
		pivot.add_child(spread)
		var arm := BoxMesh.new()
		arm.size = Vector3(1.25, 0.09, 0.34)
		actor.add_mesh(spread, arm, data.wing_color, Vector3(0.62 * side, 0, 0))
		for i in 6:  # feathers lighter toward the tip of the wing, side by side
			var feather := BoxMesh.new()
			var length := 0.5 + 0.1 * i
			feather.size = Vector3(0.22, 0.04, length)
			actor.add_mesh(spread, feather, data.wing_color.lerp(data.feather_color, i / 5.0),
				Vector3((0.15 + 0.2 * i) * side, -0.01, 0.17 + length / 2.0))
		actor.add_wing(pivot)


## The Gárgola: a crouching beast of stone: a hunched body on four short legs, a horned head
## with a wide snout and glowing red eyes, a pointed tail and two stone wings on pivots that
## beat slowly (the bat's wings, BattleActor.add_wing(), LOOKS "flap_time"), facing -Z. About 1.9 m tall at its
## scale.
static func build_gargoyle(actor: BattleActor, data: Dictionary) -> void:
	var root := Node3D.new()
	root.scale = Vector3.ONE * data.scale
	actor.body().add_child(root)
	actor.add_blob(root, WOLF_BODY_PROFILE, 5, data.color, Vector3(0, 0.55, 0.35),
		Vector3(-70, 0, 0), Vector3(1.3, 1.1, 1.2))  # hunched body, chest up
	for x in [-0.2, 0.2]:
		for z in [-0.15, 0.35]:
			actor.add_blob(root, LEG_PROFILE, 4, data.dark_color, Vector3(x, 0.0, z), Vector3.ZERO,
				Vector3(1.3, 0.9, 1.3))
		actor.add_mesh(root, LowPoly.cone(0.05, 0.12), data.horn_color, Vector3(x, 0.03, -0.3))  # claws
	actor.add_blob(root, WOLF_HEAD_PROFILE, 5, data.color, Vector3(0, 1.15, -0.25),
		Vector3(-100, 0, 0), Vector3(1.2, 1.0, 1.1))  # head
	for side in [-1.0, 1.0]:
		actor.add_mesh(root, LowPoly.sphere(0.05), data.eye_color, Vector3(side * 0.1, 1.24, -0.52))
		var eye := (root.get_child(-1) as MeshInstance3D).material_override as StandardMaterial3D
		eye.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		actor.add_mesh(root, LowPoly.cone(0.06, 0.32), data.horn_color, Vector3(side * 0.14, 1.42, -0.2))
		(root.get_child(-1) as Node3D).rotation_degrees = Vector3(-25, 0, side * -20)  # horn
		var pivot := Node3D.new()
		pivot.position = Vector3(0.25 * side, 0.95, 0.4)
		root.add_child(pivot)
		var sail := PrismMesh.new()  # the stone wing: a pointed sail facing the camera
		sail.size = Vector3(1.0, 0.85, 0.07)
		sail.left_to_right = 0.5 + 0.5 * side
		var spread := Node3D.new()
		spread.rotation_degrees.z = 22.0 * side
		pivot.add_child(spread)
		actor.add_mesh(spread, sail, data.wing_color, Vector3(0.5 * side, 0.45, 0.0))
		var bone := BoxMesh.new()  # the arm along the top edge
		bone.size = Vector3(0.95, 0.09, 0.1)
		actor.add_mesh(spread, bone, data.dark_color, Vector3(0.5 * side, 0.3, 0.0))
		(spread.get_child(-1) as Node3D).rotation_degrees.z = 28.0 * side
		actor.add_mesh(spread, LowPoly.cone(0.05, 0.3), data.horn_color, Vector3(1.0 * side, 0.9, 0.0))  # claw
		actor.add_wing(pivot)
	actor.add_mesh(root, LowPoly.cone(0.05, 0.6), data.dark_color, Vector3(0, 0.45, 0.95))  # tail
	(root.get_child(-1) as Node3D).rotation_degrees.x = 70.0


## The Rata de las ruinas: a big rat: a low faceted body, a pointed head with pink ears and
## red eyes, four short legs and a long thin tail curving behind, facing -Z. About 0.8 m tall
## at its scale.
static func build_rat(actor: BattleActor, data: Dictionary) -> void:
	var root := Node3D.new()
	root.scale = Vector3.ONE * data.scale
	actor.body().add_child(root)
	actor.add_blob(root, WOLF_BODY_PROFILE, 6, data.color, Vector3(0, 0.38, 0.4),
		Vector3(-90, 0, 0), Vector3(1.05, 0.85, 0.95))  # body
	actor.add_blob(root, WOLF_HEAD_PROFILE, 5, data.color, Vector3(0, 0.45, -0.38),
		Vector3(-95, 0, 0), Vector3(0.8, 0.85, 0.95))  # pointed head
	actor.add_mesh(root, LowPoly.sphere(0.035), data.ear_color, Vector3(0, 0.43, -0.92))  # nose
	for side in [-1.0, 1.0]:
		actor.add_mesh(root, LowPoly.sphere(0.1), data.ear_color, Vector3(side * 0.14, 0.68, -0.38))
		(root.get_child(-1) as Node3D).scale = Vector3(1.0, 1.0, 0.35)  # ear
		actor.add_mesh(root, LowPoly.sphere(0.035), data.eye_color, Vector3(side * 0.09, 0.56, -0.66))
		for z in [-0.15, 0.4]:
			actor.add_blob(root, LEG_PROFILE, 4, data.dark_color, Vector3(side * 0.15, 0.0, z),
				Vector3.ZERO, Vector3(0.9, 0.55, 0.9))
	for i in 6:  # the tail: thin rods curving back and up
		var a := i * 0.25
		actor.add_mesh(root, LowPoly.cylinder(0.025 - i * 0.003, 0.22), data.ear_color.darkened(0.2),
			Vector3(0, 0.3 + sin(a) * 0.25, 0.95 + i * 0.18))
		(root.get_child(-1) as Node3D).rotation_degrees.x = 80.0 - i * 12.0


## The Devorador del portal: a dark faceted mass about 3.2 m tall with lumps on it, six
## mouths round it (dark red lips, black throats and white teeth, each kind merged into one
## mesh), tentacles at its foot, and in front a great eye (white, a red iris and a slit) under
## a heavy lid, half closed until its second phase; a red light glows in front of it. Faces -Z.
static func build_devourer(actor: BattleActor, data: Dictionary) -> void:
	var devourer := Node3D.new()
	devourer.scale = Vector3.ONE * data.scale
	actor.body().add_child(devourer)
	actor.add_mesh(devourer, LowPoly.blob(DEVOURER_PROFILE, 7), data.color, Vector3.ZERO, 0.9)
	var lumps: Array[Transform3D] = []
	for lump: Array in DEVOURER_LUMPS:  # [degrees from the front, height, size]
		var a := deg_to_rad(lump[0])
		lumps.append(Transform3D(Basis.from_scale(Vector3.ONE * lump[2]),
			Vector3(sin(a) * 1.05, lump[1], -cos(a) * 1.05)))
	actor.add_mesh(devourer, LowPoly.merged(LowPoly.sphere(1.0), lumps), data.dark_color, Vector3.ZERO, 0.9)
	var lips: Array[Transform3D] = []
	var throats: Array[Transform3D] = []
	var teeth: Array[Transform3D] = []
	for mouth: Array in DEVOURER_MOUTHS:
		var a := deg_to_rad(mouth[0])
		var out := Vector3(sin(a), 0, -cos(a))
		var frame := Transform3D(Basis.looking_at(out, Vector3.UP),
			out * 1.3 + Vector3(0, mouth[1], 0))
		lips.append(frame * Transform3D(Basis.from_scale(Vector3(0.55, 0.26, 0.2)),
			Vector3.ZERO))
		throats.append(frame * Transform3D(Basis.from_scale(Vector3(0.45, 0.17, 0.12)),
			Vector3(0, 0, -0.1)))
		for x in [-0.3, -0.1, 0.1, 0.3]:
			teeth.append(frame * Transform3D(Basis(Vector3.RIGHT, PI), Vector3(x, 0.14, -0.2)))
			teeth.append(frame * Transform3D(Basis(), Vector3(x + 0.1, -0.14, -0.2)))
	actor.add_mesh(devourer, LowPoly.merged(LowPoly.sphere(1.0), lips), data.lip_color, Vector3.ZERO, 0.7)
	actor.add_mesh(devourer, LowPoly.merged(LowPoly.sphere(1.0), throats), Color(0.02, 0.0, 0.02), Vector3.ZERO)
	actor.add_mesh(devourer, LowPoly.merged(LowPoly.cone(0.06, 0.2), teeth), data.tooth_color, Vector3.ZERO, 0.5)
	var tentacles: Array[Transform3D] = []
	for i in 6:
		var a := TAU * i / 6.0 + 0.3
		var out := Vector3(sin(a), 0, -cos(a))
		tentacles.append(Transform3D(Basis.looking_at(out, Vector3.UP)
			* Basis(Vector3.RIGHT, deg_to_rad(-80.0)), out * 1.45 + Vector3(0, 0.15, 0)))
	actor.add_mesh(devourer, LowPoly.merged(LowPoly.cone(0.26, 1.5), tentacles), data.dark_color, Vector3.ZERO)
	var crown: Array[Transform3D] = []  # a crown of horns on top of the mass
	for i in 6:
		var a := TAU * i / 6.0
		var out := Vector3(sin(a), 0, -cos(a))
		crown.append(Transform3D(Basis.looking_at(out, Vector3.UP)
			* Basis(Vector3.RIGHT, deg_to_rad(-65.0)), out * 0.4 + Vector3(0, 3.0, 0)))
	actor.add_mesh(devourer, LowPoly.merged(LowPoly.cone(0.16, 0.9), crown), data.dark_color, Vector3.ZERO)
	var eye := Vector3(0, 1.75, -1.1)
	actor.add_mesh(devourer, LowPoly.sphere(0.62), data.sclera_color, eye, 0.4)
	actor.add_mesh(devourer, LowPoly.sphere(0.33), data.iris_color, eye + Vector3(0, 0, -0.48))
	var iris := (devourer.get_child(-1) as MeshInstance3D)
	(iris.material_override as StandardMaterial3D).shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	iris.scale = Vector3(1.0, 1.0, 0.4)
	actor.add_mesh(devourer, LowPoly.sphere(0.13), Color(0.02, 0.0, 0.02), eye + Vector3(0, 0, -0.56))
	(devourer.get_child(-1) as Node3D).scale = Vector3(0.4, 1.0, 0.4)  # the slit
	var eyelid := Node3D.new()
	eyelid.position = eye
	devourer.add_child(eyelid)
	actor.add_mesh(eyelid, LowPoly.hemisphere(0.7, 0.7), data.color, Vector3.ZERO, 0.9)
	eyelid.rotation_degrees.x = EYELID_HALF
	var glow := OmniLight3D.new()
	glow.light_color = data.glow_color
	glow.light_energy = 1.2
	glow.omni_range = 5.0
	glow.position = Vector3(0, 1.5, -2.2)
	devourer.add_child(glow)
	actor.set_devourer(devourer, eyelid)


## A poison dart frog: a squat faceted body, a yellow belly, black spots, two big eyes on
## top and four bent legs, facing -Z. About 0.55 m tall before the look's scale (1.4); it hops like the slimes.
static func build_frog(actor: BattleActor, data: Dictionary) -> void:
	var root := Node3D.new()
	root.scale = Vector3.ONE * data.scale
	actor.body().add_child(root)
	actor.add_blob(root, SLIME_PROFILE, SLIME_SEGMENTS, data.color, Vector3(0, 0.08, 0),
		Vector3.ZERO, Vector3(0.55, 0.38, 0.62))  # body
	actor.add_blob(root, SLIME_PROFILE, SLIME_SEGMENTS, data.belly_color, Vector3(0, 0.04, -0.12),
		Vector3.ZERO, Vector3(0.42, 0.22, 0.42))  # belly
	for spot in [Vector3(-0.14, 0.33, 0.1), Vector3(0.16, 0.3, 0.02), Vector3(0.0, 0.36, 0.22)]:
		actor.add_mesh(root, LowPoly.sphere(0.06), data.spot_color, spot)
	for x in [-0.15, 0.15]:
		actor.add_mesh(root, LowPoly.sphere(0.1), data.color, Vector3(x, 0.42, -0.2))  # eye bump
		actor.add_mesh(root, LowPoly.sphere(0.065), Color(0.05, 0.05, 0.05), Vector3(x, 0.45, -0.27))
		actor.add_blob(root, LEG_PROFILE, 4, data.color, Vector3(x * 2.0, 0.0, 0.18),
			Vector3(0, 0, 40.0 if x > 0 else -40.0), Vector3(1.2, 0.6, 1.2))  # back leg
		actor.add_blob(root, LEG_PROFILE, 4, data.color, Vector3(x * 1.6, 0.0, -0.2),
			Vector3.ZERO, Vector3(0.8, 0.5, 0.8))  # front leg


## A vine snake: a chain of shrinking green spheres coiled on the ground that rises into a
## raised neck and a wedge head with yellow eyes, facing -Z. About 1.1 m tall.
static func build_snake(actor: BattleActor, data: Dictionary) -> void:
	var root := Node3D.new()
	root.scale = Vector3.ONE * data.scale
	actor.body().add_child(root)
	var coil := 10
	for i in coil:
		var angle := TAU * i / coil * 1.3
		var radius := 0.32 - i * 0.012
		var color: Color = data.color if i % 2 == 0 else data.dark_color
		actor.add_mesh(root, LowPoly.sphere(0.13 - i * 0.004),
			color, Vector3(cos(angle) * radius, 0.12, sin(angle) * radius + 0.15))
	for i in 4:  # the neck rises toward the front
		actor.add_mesh(root, LowPoly.sphere(0.12 - i * 0.008), data.color,
			Vector3(0, 0.25 + i * 0.18, -0.05 - i * 0.07))
	actor.add_blob(root, WOLF_HEAD_PROFILE, 5, data.color, Vector3(0, 0.98, -0.32),
		Vector3(-100, 0, 0), Vector3(0.85, 0.85, 0.85))  # head
	for x in [-0.07, 0.07]:
		actor.add_mesh(root, LowPoly.sphere(0.05), data.eye_color, Vector3(x * 1.5, 1.08, -0.55))
	actor.add_mesh(root, LowPoly.cone(0.015, 0.12), Color(0.9, 0.1, 0.15), Vector3(0, 0.95, -0.6))  # tongue
	(root.get_child(-1) as Node3D).rotation_degrees.x = -90.0


## A howler monkey: a round brown body, a light face with dark eyes, long arms and a curled
## tail, sitting up, facing -Z. About 1.3 m tall.
static func build_monkey(actor: BattleActor, data: Dictionary) -> void:
	var root := Node3D.new()
	root.scale = Vector3.ONE * data.scale
	actor.body().add_child(root)
	actor.add_blob(root, SLIME_PROFILE, SLIME_SEGMENTS, data.color, Vector3(0, 0.25, 0),
		Vector3.ZERO, Vector3(0.42, 0.62, 0.4))  # body
	actor.add_mesh(root, LowPoly.sphere(0.26), data.color, Vector3(0, 1.0, -0.02))  # head
	actor.add_mesh(root, LowPoly.sphere(0.17), data.face_color, Vector3(0, 0.97, -0.17))  # face
	for x in [-0.07, 0.07]:
		actor.add_mesh(root, LowPoly.sphere(0.035), Color(0.05, 0.05, 0.05), Vector3(x, 1.03, -0.3))
		actor.add_mesh(root, LowPoly.sphere(0.07), data.color, Vector3(x * 3.4, 1.1, -0.02))  # ear
	for x in [-0.25, 0.25]:
		actor.add_mesh(root, LowPoly.cylinder(0.06, 0.7), data.color, Vector3(x, 0.52, -0.08))  # arm
		actor.add_mesh(root, LowPoly.sphere(0.08), data.face_color, Vector3(x, 0.15, -0.08))  # hand
	actor.add_mesh(root, LowPoly.cylinder(0.045, 0.7), data.color, Vector3(0, 0.45, 0.42))  # tail
	(root.get_child(-1) as Node3D).rotation_degrees.x = 60.0


## A desert scorpion: a flat body of four plates low on eight short legs, two arms with big
## pincers in front and a tail of shrinking segments curling up over its back to a pale
## stinger, facing -Z. About 1 m tall at its scale.
static func build_scorpion(actor: BattleActor, data: Dictionary) -> void:
	var root := Node3D.new()
	root.scale = Vector3.ONE * data.scale
	actor.body().add_child(root)
	for i in 4:  # the body plates, front to back
		var color: Color = data.color if i % 2 == 0 else data.dark_color
		actor.add_mesh(root, LowPoly.sphere(0.2 - i * 0.015), color, Vector3(0, 0.2, -0.18 + i * 0.17))
		(root.get_child(-1) as Node3D).scale = Vector3(1.25, 0.55, 1.0)
	for x in [-0.07, 0.07]:
		actor.add_mesh(root, LowPoly.sphere(0.03), data.eye_color, Vector3(x, 0.29, -0.36))
	for side in [-1.0, 1.0]:
		for i in 4:  # legs: thin sticks going out and down from the body
			actor.add_mesh(root, LowPoly.cylinder(0.022, 0.3), data.dark_color,
				Vector3(side * 0.34, 0.1, -0.12 + i * 0.15))
			(root.get_child(-1) as Node3D).rotation_degrees = Vector3(0, 0, side * 60.0)
		actor.add_mesh(root, LowPoly.sphere(0.06), data.color, Vector3(side * 0.22, 0.2, -0.5))  # arm
		actor.add_mesh(root, LowPoly.sphere(0.06), data.color, Vector3(side * 0.24, 0.2, -0.6))
		actor.add_mesh(root, LowPoly.sphere(0.11), data.dark_color, Vector3(side * 0.27, 0.2, -0.74))
		(root.get_child(-1) as Node3D).scale = Vector3(0.8, 0.6, 1.3)  # pincer
	var segments := 10
	var tip := Vector3.ZERO
	for i in segments:  # the tail rises from the back and curls forward over it
		var a := PI * 0.9 * i / (segments - 1)
		tip = Vector3(0, 0.25 + sin(a) * 0.55, 0.42 + cos(a) * 0.3)
		var color: Color = data.color if i % 2 == 0 else data.dark_color
		actor.add_mesh(root, LowPoly.sphere(0.1 - i * 0.006), color, tip)
	actor.add_mesh(root, LowPoly.cone(0.04, 0.16), data.sting_color, tip + Vector3(0, -0.02, -0.08))
	(root.get_child(-1) as Node3D).rotation_degrees.x = -120.0


## The Gusano de las dunas: a low ring of sand, a thick body of seven segments rising out
## of it and bending forward, and a round mouth ringed with teeth looking at the hero,
## facing -Z. About 3.4 m tall at its scale. It sways (BattleActor.set_sway()) like the plant.
static func build_worm(actor: BattleActor, data: Dictionary) -> void:
	actor.add_blob(actor.body(), SLIME_PROFILE, SLIME_SEGMENTS, data.sand_color, Vector3.ZERO,
		Vector3.ZERO, Vector3(1.3, 0.22, 1.3) * data.scale)  # the sand: it stays still
	var sway := Node3D.new()
	sway.scale = Vector3.ONE * data.scale
	actor.body().add_child(sway)
	actor.set_sway(sway)
	var segments := 7
	for i in segments:
		var u := float(i) / (segments - 1)
		var color: Color = data.color if i % 2 == 0 else data.dark_color
		actor.add_mesh(sway, LowPoly.sphere(0.42 - u * 0.12), color, Vector3(0, 0.15 + u * 1.55, -u * u * 0.55))
		(sway.get_child(-1) as Node3D).scale = Vector3(1.0, 0.7, 1.0)
	var head := Node3D.new()
	head.position = Vector3(0, 1.78, -0.62)
	head.rotation_degrees.x = -70.0  # its local up points forward and a little up
	sway.add_child(head)
	actor.add_mesh(head, LowPoly.sphere(0.3), data.color, Vector3.ZERO)
	actor.add_mesh(head, LowPoly.disc(0.22), data.mouth_color, Vector3(0, 0.2, 0))
	for i in 10:
		var a := TAU * i / 10.0
		actor.add_mesh(head, LowPoly.cone(0.035, 0.1), data.teeth_color,
			Vector3(cos(a) * 0.2, 0.2, sin(a) * 0.2))
		(head.get_child(-1) as Node3D).rotation = Vector3(0, -a, deg_to_rad(-140.0))


## The Jefe de caravana's canteen, half buried in the sand: a flat leather flask lying on
## its side with a cork and a strap, on a low mound. It stands still.
static func build_canteen(actor: BattleActor, data: Dictionary) -> void:
	actor.add_blob(actor.body(), SLIME_PROFILE, SLIME_SEGMENTS, data.sand_color, Vector3.ZERO,
		Vector3.ZERO, Vector3(1.0, 0.16, 1.0))  # the mound
	var flask := Node3D.new()
	flask.scale = Vector3.ONE * 2.2
	flask.position = Vector3(0, 0.38, 0)
	flask.rotation_degrees = Vector3(0, 30, 70)
	actor.body().add_child(flask)
	actor.add_mesh(flask, LowPoly.sphere(0.2), data.color, Vector3.ZERO)
	(flask.get_child(-1) as Node3D).scale = Vector3(1.0, 1.0, 0.45)
	actor.add_mesh(flask, LowPoly.cylinder(0.05, 0.1), data.cork_color, Vector3(0, 0.22, 0))
	var strap := BoxMesh.new()
	strap.size = Vector3(0.44, 0.03, 0.1)
	actor.add_mesh(flask, strap, data.strap_color, Vector3(0, 0.0, 0.0))


## The Posadera's pot: the Kenney pot of the mine's refuge (NatureModels "pot", vertex
## colours through the tree shader, as on the map), a little tipped over.
static func build_pot(actor: BattleActor, data: Dictionary) -> void:
	var mi := MeshInstance3D.new()
	# The refugio's own green (ZoneData.decor_green's default): the pot has no green part,
	# and the same key reuses NatureModels' cached mesh.
	mi.mesh = NatureModels.mesh("pot", ZoneData.by_id("mina_1").decor_green)
	var mat := ShaderMaterial.new()
	mat.shader = TREE_SHADER
	mat.set_shader_parameter("use_texture", false)
	mat.set_shader_parameter("use_vertex_color", true)
	mi.material_override = mat
	mi.scale = Vector3.ONE * float(data.model_scale)
	mi.rotation_degrees = Vector3(0, 0, 12)
	actor.body().add_child(mi)
