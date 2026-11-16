class_name MistDress extends RefCounted
## Constructor: what makes Brumaclara's people look like people of the Niebla (3.8.0), on the
## KayKit Knight that CharacterBuilder.build() has just made from their ActorLooksV3 entry: the
## hood (LOOKS "hood": its colour; a look asks for "hair" or "hood", never both) and the
## crystal pendant on the chest ("pendant": true). Every piece is faceted like the hair, hangs
## from a bone so it follows every animation and, when it glows, glows on its own (emission):
## nothing here makes a light. Static only, keeps no state: it writes into the actor through
## its builder methods (add_blob, add_mesh) and CharacterBuilder.hang_on_bone().

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
## the same axis, so it is the opening's own edge.
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


## Dresses actor's Knight model with what data (its LOOKS entry) asks for of the pieces above;
## a look that asks for none is left as it is.
static func dress(actor: BattleActor, model: Node3D, data: Dictionary) -> void:
	var bones := model.get_node(CharacterBuilder.SKELETON_PATH) as Skeleton3D
	if data.has("hood"):
		_add_hood(actor, model.get_node(HEAD_SLOT) as Node3D, data.hood)
	if data.get("pendant", false):
		_add_pendant(actor, bones)


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


## Lights mi's own material (BattleActor.add_mesh()'s, so it still fades with the figure) in its
## colour, energy strong: it glows, it lights nothing.
static func _glow(mi: MeshInstance3D, energy: float) -> void:
	var mat := mi.material_override as StandardMaterial3D
	mat.emission_enabled = true
	mat.emission = mat.albedo_color
	mat.emission_energy_multiplier = energy
	mat.roughness = 0.3
