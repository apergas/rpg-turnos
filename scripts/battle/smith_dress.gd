class_name SmithDress extends RefCounted
## Constructor: what the armeros carry and wear to look like the smiths of their place (3.10.0,
## M-124), on the KayKit model CharacterBuilder.build() has just made from their ActorLooksArmory
## entry: the hammer in the right hand (LOOKS "hammer": the colour of its head, the metal its
## counter sells), a leather apron on the belly ("apron": its colour; a Knight only) and the
## mine's cap with its lamp ("miner_cap": the cap's colour). Each piece hangs from a bone or a
## hand slot so it follows every animation; the lamp glows on its own (unshaded, like the
## Armadura's ember): nothing here makes a light. Static only, keeps no state: it writes into the
## actor through its builder methods (add_mesh, add_blob) and CharacterBuilder.hang_on_bone().

## The hammer, in the right hand's slot (BattleActor.HAND_R; the hand's +Y runs along what it
## holds, like the Knight's swords and the hero's stick): a wooden handle (CharacterBuilder's
## STICK_COLOR) gripped near its foot and the head across its top. Both hang from a pivot turned
## HAMMER_ROT so the handle stands up from the fist in the idle pose (along the hand's +Y it
## pointed forward, like a sword). In the model's units; tuned with close frames.
const HAMMER_HANDLE_RADIUS := 0.05
const HAMMER_HANDLE_LENGTH := 0.75
const HAMMER_HANDLE_CENTER := 0.25
const HAMMER_HEAD_SIZE := Vector3(0.34, 0.17, 0.17)
const HAMMER_HEAD_AT := 0.62
const HAMMER_ROUGHNESS := 0.5
const HAMMER_ROT := Vector3(0, 0, 90)
## The apron: a thin board of leather on the hips bone (it turns less than the chest in the idle
## pose), in front of the belly down to the thighs, placed in the rig's rest pose (the Knight
## faces +Z there). Tuned with close frames.
const APRON_BONE := "hips"
const APRON_SIZE := Vector3(0.52, 0.64, 0.04)
const APRON_AT := Vector3(0, 0.64, 0.39)
## The mine's cap: a faceted dome over the head, in the head bone's space (the Knight faces +Z
## there, like the hair pieces), and on its front the lamp, a small yellow ball. Tuned with close
## frames; its top stays below the look's "top", where the name sign hangs.
const CAP_PROFILE: Array[Vector2] = [Vector2(0, 0.0), Vector2(0.52, 0.0), Vector2(0.54, 0.25),
	Vector2(0.46, 0.65), Vector2(0.26, 0.92), Vector2(0, 1.0)]
const CAP_POS := Vector3(0, 0.7, 0.0)
const CAP_SCALE := Vector3(1.2, 0.55, 1.25)
const LAMP_RADIUS := 0.09
const LAMP_AT := Vector3(0, 0.85, 0.68)
const LAMP_COLOR := Color(1.0, 0.85, 0.4)


## Gives actor's model what data (its LOOKS entry) asks for of the pieces above; a look that asks
## for none is left as it is.
static func dress(actor: BattleActor, model: Node3D, data: Dictionary) -> void:
	if data.has("hammer"):
		_add_hammer(actor, model.get_node(BattleActor.HAND_R) as Node3D, data.hammer)
	if data.has("apron"):
		var apron := BoxMesh.new()
		apron.size = APRON_SIZE
		var bones := model.get_node(CharacterBuilder.SKELETON_PATH) as Skeleton3D
		CharacterBuilder.hang_on_bone(actor, bones, APRON_BONE, apron, data.apron,
			Transform3D(Basis.IDENTITY, APRON_AT))
	if data.has("miner_cap"):
		_add_cap(actor, model.get_node(MistDress.HEAD_SLOT) as Node3D, data.miner_cap)


## The wooden handle along the hand, then the head across its top in the metal's colour.
static func _add_hammer(actor: BattleActor, hand: Node3D, metal: Color) -> void:
	var pivot := Node3D.new()
	pivot.rotation_degrees = HAMMER_ROT
	hand.add_child(pivot)
	actor.add_mesh(pivot, LowPoly.cylinder(HAMMER_HANDLE_RADIUS, HAMMER_HANDLE_LENGTH),
		CharacterBuilder.STICK_COLOR, Vector3(0, HAMMER_HANDLE_CENTER, 0))
	var head := BoxMesh.new()
	head.size = HAMMER_HEAD_SIZE
	actor.add_mesh(pivot, head, metal, Vector3(0, HAMMER_HEAD_AT, 0), HAMMER_ROUGHNESS)


## The dome and its lamp, which glows unshaded.
static func _add_cap(actor: BattleActor, head: Node3D, color: Color) -> void:
	actor.add_blob(head, CAP_PROFILE, ActorLooks.HAIR_SEGMENTS, color, CAP_POS, Vector3.ZERO,
		CAP_SCALE)
	actor.add_mesh(head, LowPoly.sphere(LAMP_RADIUS), LAMP_COLOR, LAMP_AT)
	var lamp := (head.get_child(-1) as MeshInstance3D).material_override as StandardMaterial3D
	lamp.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
