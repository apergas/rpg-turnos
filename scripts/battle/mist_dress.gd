class_name MistDress extends RefCounted
## Constructor: what makes Brumaclara's people look like people of the Niebla (3.8.0), on the
## KayKit Knight that CharacterBuilder.build() has just made from their ActorLooksV3 entry: the
## hood (LOOKS "hood": its colour; a look asks for "hair" or "hood", never both), the crystal
## pendant on the chest ("pendant": true), what one carries ("carry": CARRY_LANTERN, Orvalla's
## lantern in the right hand, or CARRY_BOWL, the Curandera's bowl of mist water in the left)
## and the Herrero's crystal arms ("crystal_arms": true). The hood is a smooth cowl, the other
## pieces are faceted like the hair; each hangs from a bone so it follows every animation and,
## when it glows, glows on its own (emission): nothing here makes a light. Static only, keeps
## no state: it writes into the actor through its builder methods (add_blob, add_mesh) and
## CharacterBuilder.hang_on_bone().

## The head bone's attachment of the Knight (the hair pieces hang from it too).
const HEAD_SLOT := "Rig/Skeleton3D/head"
## The hood, in the head bone's space (the Knight faces +Z there, before the turn): a smooth
## cowl (HOOD_SEGMENTS sides, finer than the hair pieces) whose axis points forward (HOOD_TURN
## lays the lathe's Y along +Z), closed at the back, covering the top, the sides and the back of
## the head down to the neck and open at the front, where a band along its edge (the rim,
## HOOD_RIM_LIGHTEN lighter) frames the face; a soft point (the tip) leans back off the top; a
## darker flap closes the nape; a brow fold over the forehead hides the head's own fringe. Tuned
## with close frames; its top stays below the look's "top", where the name sign hangs.
const HOOD_SEGMENTS := 16
const HOOD_PROFILE: Array[Vector2] = [Vector2(0, 0.0), Vector2(0.3, 0.08), Vector2(0.55, 0.28),
	Vector2(0.68, 0.55), Vector2(0.66, 0.8), Vector2(0.54, 1.0)]
const HOOD_POS := Vector3(0, 0.56, -0.55)
const HOOD_TURN := Vector3(90, 0, 0)
const HOOD_SCALE := Vector3(1.0, 1.0, 0.95)
const HOOD_RIM_LIGHTEN := 0.2
## The rim: a thin band along the cowl's last stretch, a hair outside it and ending in a lip, on
## the same axis, so it is the opening's own edge. Its first point starts just inside the cowl
## on purpose, so no seam shows where the band begins.
const RIM_PROFILE: Array[Vector2] = [Vector2(0.617, 0.86), Vector2(0.552, 1.0),
	Vector2(0.49, 1.0)]
const BROW_PROFILE: Array[Vector2] = [Vector2(0, 0.0), Vector2(0.52, 0.06), Vector2(0.62, 0.4),
	Vector2(0.56, 0.75), Vector2(0.36, 0.98), Vector2(0, 1.05)]
const BROW_POS := Vector3(0, 0.66, -0.02)
const BROW_SCALE := Vector3(0.92, 0.5, 0.97)
const NAPE_PROFILE: Array[Vector2] = [Vector2(0, 0.0), Vector2(0.5, 0.12), Vector2(0.44, 0.7),
	Vector2(0, 1.0)]
const NAPE_POS := Vector3(0, 0.22, -0.4)
const NAPE_TURN := Vector3(180, 0, 0)
const NAPE_SCALE := Vector3(0.9, 0.4, 0.45)
const NAPE_DARKEN := 0.15
const TIP_PROFILE: Array[Vector2] = [Vector2(0, 0.0), Vector2(0.2, 0.12), Vector2(0.12, 0.45),
	Vector2(0, 0.7)]
const TIP_POS := Vector3(0, 0.9, -0.6)
## Leans the tip back, off the top of the head, like a hood's point falling behind.
const TIP_TURN := Vector3(-80, 0, 0)
## The crystal pendant: a small double point of light blue crystal (Crystals.COLORS[0]) on the
## chest bone, placed in the rig's rest pose (the Knight faces +Z there), with a soft glow.
const PENDANT_PROFILE: Array[Vector2] = [Vector2(0, 0.0), Vector2(0.5, 0.45), Vector2(0, 1.0)]
const PENDANT_SIDES := 6
const PENDANT_BONE := "chest"
const PENDANT_AT := Vector3(0, 0.8, 0.4)
const PENDANT_SIZE := 0.16
const PENDANT_COLOR := Color(0.45, 0.72, 1.0)
const PENDANT_GLOW := 1.2
## LOOKS "carry".
const CARRY_LANTERN := "lantern"
const CARRY_BOWL := "bowl"
## Orvalla's lantern, in the right hand's slot (BattleActor.HAND_R; the hand's +Y runs along
## what it holds, like the Knight's swords), held by a ring: under it a dark iron cap, the
## glowing yellow glass and a base, down the pivot's -Y, the pivot turned LANTERN_ROT so the
## lantern hangs upright in the idle pose. In the model's units; tuned with close frames.
const LANTERN_POS := Vector3(-0.2, 0.05, 0.0)
const LANTERN_ROT := Vector3(0, 0, 90)
const LANTERN_IRON := Color(0.16, 0.16, 0.2)
const LANTERN_GLASS := Color(1.0, 0.82, 0.4)
const LANTERN_RADIUS := 0.11
const LANTERN_RING := 0.07
const LANTERN_CAP := 0.08
const LANTERN_GLASS_HEIGHT := 0.22
const LANTERN_BASE := 0.05
const LANTERN_GLOW := 1.6
## The Curandera's bowl, in the left hand's slot (BattleActor.HAND_L): a faceted grey clay bowl
## and, in it, a disc of mist water that glows a little; the pivot turned BOWL_ROT so it sits
## level in the idle pose. Tuned with close frames.
const BOWL_POS := Vector3(0, 0.12, 0.1)
const BOWL_ROT := Vector3(0, 0, -90)
const BOWL_PROFILE: Array[Vector2] = [Vector2(0, 0.0), Vector2(0.12, 0.0), Vector2(0.2, 0.06),
	Vector2(0.24, 0.15), Vector2(0, 0.1)]
const BOWL_COLOR := Color(0.62, 0.6, 0.66)
const BOWL_WATER := Color(0.6, 0.85, 1.0)
const BOWL_WATER_RADIUS := 0.2
const BOWL_WATER_HEIGHT := 0.145
const BOWL_GLOW := 0.7
## The Herrero's arms: the Knight's two arm meshes (each the whole arm) in the glowing crystal
## of the Cuevas (Crystals.material(0)), with no skin tint.
const CRYSTAL_ARMS: Array[String] = ["Knight_ArmLeft", "Knight_ArmRight"]


## Dresses actor's Knight model with what data (its LOOKS entry) asks for of the pieces above;
## a look that asks for none is left as it is.
static func dress(actor: BattleActor, model: Node3D, data: Dictionary) -> void:
	var bones := model.get_node_or_null(CharacterBuilder.SKELETON_PATH) as Skeleton3D
	if bones == null or not (data.has("hood") or data.has("pendant") or data.has("carry")
			or data.has("crystal_arms")):
		return
	if data.has("hood"):
		_add_hood(actor, model.get_node(HEAD_SLOT) as Node3D, data.hood)
	if data.get("pendant", false):
		_add_pendant(actor, bones)
	match data.get("carry", ""):
		CARRY_LANTERN:
			_add_lantern(actor, model.get_node(BattleActor.HAND_R) as Node3D)
		CARRY_BOWL:
			_add_bowl(actor, model.get_node(BattleActor.HAND_L) as Node3D)
	if data.get("crystal_arms", false):
		for mesh_name in CRYSTAL_ARMS:
			var arm := bones.get_node(mesh_name) as MeshInstance3D
			for i in arm.mesh.get_surface_count():
				arm.set_surface_override_material(i, Crystals.material(0))


## The cowl and its tip in the hood's colour (the cape's, ActorLooksV3's *_CLOAK), and
## the rim a little lighter.
static func _add_hood(actor: BattleActor, head: Node3D, color: Color) -> void:
	var rim := color.lightened(HOOD_RIM_LIGHTEN)
	actor.add_blob(head, HOOD_PROFILE, HOOD_SEGMENTS, color, HOOD_POS, HOOD_TURN, HOOD_SCALE)
	actor.add_blob(head, BROW_PROFILE, HOOD_SEGMENTS, color, BROW_POS, Vector3.ZERO, BROW_SCALE)
	actor.add_blob(head, NAPE_PROFILE, HOOD_SEGMENTS, color.darkened(NAPE_DARKEN), NAPE_POS,
		NAPE_TURN, NAPE_SCALE)
	actor.add_blob(head, TIP_PROFILE, HOOD_SEGMENTS, color, TIP_POS, TIP_TURN)
	actor.add_blob(head, RIM_PROFILE, HOOD_SEGMENTS, rim, HOOD_POS, HOOD_TURN, HOOD_SCALE)


static func _add_pendant(actor: BattleActor, bones: Skeleton3D) -> void:
	var stone := LowPoly.blob(PENDANT_PROFILE, PENDANT_SIDES)
	var at := Transform3D(Basis.from_scale(Vector3.ONE * PENDANT_SIZE), PENDANT_AT)
	_glow(CharacterBuilder.hang_on_bone(actor, bones, PENDANT_BONE, stone, PENDANT_COLOR, at),
		PENDANT_GLOW)


## The ring in the hand, then the cap, the glass (glowing) and the base below it.
static func _add_lantern(actor: BattleActor, hand: Node3D) -> void:
	var lantern := _pivot(hand, LANTERN_POS, LANTERN_ROT)
	var ring := TorusMesh.new()
	ring.inner_radius = LANTERN_RING * 0.7
	ring.outer_radius = LANTERN_RING
	ring.rings = 8
	ring.ring_segments = 4
	actor.add_mesh(lantern, ring, LANTERN_IRON, Vector3.ZERO)
	(lantern.get_child(-1) as Node3D).rotation_degrees.x = 90.0
	var y := -LANTERN_RING - LANTERN_CAP * 0.5
	var cap := LowPoly.cylinder(LANTERN_RADIUS, LANTERN_CAP)
	cap.top_radius = LANTERN_RADIUS * 0.3
	actor.add_mesh(lantern, cap, LANTERN_IRON, Vector3(0, y, 0))
	y -= (LANTERN_CAP + LANTERN_GLASS_HEIGHT) * 0.5
	actor.add_mesh(lantern, LowPoly.cylinder(LANTERN_RADIUS * 0.85, LANTERN_GLASS_HEIGHT),
		LANTERN_GLASS, Vector3(0, y, 0))
	_glow(lantern.get_child(-1) as MeshInstance3D, LANTERN_GLOW)
	y -= (LANTERN_GLASS_HEIGHT + LANTERN_BASE) * 0.5
	actor.add_mesh(lantern, LowPoly.cylinder(LANTERN_RADIUS, LANTERN_BASE), LANTERN_IRON,
		Vector3(0, y, 0))


## The clay bowl and its glowing water.
static func _add_bowl(actor: BattleActor, hand: Node3D) -> void:
	var bowl := _pivot(hand, BOWL_POS, BOWL_ROT)
	actor.add_blob(bowl, BOWL_PROFILE, ActorLooks.HAIR_SEGMENTS, BOWL_COLOR, Vector3.ZERO)
	actor.add_mesh(bowl, LowPoly.disc(BOWL_WATER_RADIUS), BOWL_WATER,
		Vector3(0, BOWL_WATER_HEIGHT, 0))
	_glow(bowl.get_child(-1) as MeshInstance3D, BOWL_GLOW)


## An empty node under parent at pos, turned rot_deg: what a carried piece is built in.
static func _pivot(parent: Node3D, pos: Vector3, rot_deg: Vector3) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = pos
	pivot.rotation_degrees = rot_deg
	parent.add_child(pivot)
	return pivot


## Lights mi's own material (BattleActor.add_mesh()'s, so it still fades with the figure) in its
## colour, energy strong: it glows, it lights nothing.
static func _glow(mi: MeshInstance3D, energy: float) -> void:
	var mat := mi.material_override as StandardMaterial3D
	mat.emission_enabled = true
	mat.emission = mat.albedo_color
	mat.emission_energy_multiplier = energy
	mat.roughness = 0.3
