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
## The hood, in the head bone's space (the Knight faces +Z there, before the turn), like
## ActorLooks.HAIR_PIECES: a faceted dome over the head, set back so the face shows in front
## of it, and a flap over the nape a touch darker (NAPE_DARKEN). Tuned with close frames; its
## top stays below the look's "top", where the name sign hangs.
const HOOD_PROFILE: Array[Vector2] = [Vector2(0, 0.0), Vector2(0.52, 0.06), Vector2(0.62, 0.4),
	Vector2(0.56, 0.75), Vector2(0.36, 0.98), Vector2(0, 1.05)]
const HOOD_POS := Vector3(0, -0.02, -0.2)
const HOOD_SCALE := Vector3(1.0, 1.12, 0.85)
## The brow: the hood's rim, a flat dome over the forehead that hides the head's own hair.
const BROW_POS := Vector3(0, 0.64, -0.02)
const BROW_SCALE := Vector3(1.0, 0.42, 1.02)
const NAPE_PROFILE: Array[Vector2] = [Vector2(0, 0.0), Vector2(0.5, 0.12), Vector2(0.44, 0.7),
	Vector2(0, 1.0)]
const NAPE_POS := Vector3(0, 0.2, -0.5)
const NAPE_ROT := Vector3(180, 0, 0)
const NAPE_SCALE := Vector3(0.9, 0.5, 0.35)
const NAPE_DARKEN := 0.15
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


## The dome and the nape flap, in the hood's colour (the cape's, ActorLooksV3's *_CLOAK).
static func _add_hood(actor: BattleActor, head: Node3D, color: Color) -> void:
	actor.add_blob(head, HOOD_PROFILE, ActorLooks.HAIR_SEGMENTS, color, HOOD_POS, Vector3.ZERO,
		HOOD_SCALE)
	actor.add_blob(head, HOOD_PROFILE, ActorLooks.HAIR_SEGMENTS, color, BROW_POS, Vector3.ZERO,
		BROW_SCALE)
	actor.add_blob(head, NAPE_PROFILE, ActorLooks.HAIR_SEGMENTS, color.darkened(NAPE_DARKEN),
		NAPE_POS, NAPE_ROT, NAPE_SCALE)


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
