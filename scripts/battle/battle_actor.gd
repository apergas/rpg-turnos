class_name BattleActor extends Node3D
## 3D figure of a fighter or a villager. The hero, the villagers, the witch and the
## skeletons are KayKit models with their own animations (the skeletons get their
## weapons from KayKit too, and the Señor de la Niebla a purple aura and the Eco de la Niebla a pale cyan one); the slimes, the
## bat, the mushroom, the wolf,
## the goblin, the carnivorous plant, the golems, the spider, the specter and the
## creatures that fight beside the hero are low-poly figures built in code (see LOOKS).
## Five of them are color variants of those (RED_SLIME, POISON_MUSHROOM, CAVE_MUSHROOM, CRYPT_BAT, FROST_SPECTER), built by the same functions.
## Set look before add_child. The figure faces -Z, so look_at() the opponent. Every
## play_* can be awaited: it returns when its animation and its tween are done.

enum Look { HERO, SLIME, VILLAGER, KING_SLIME, BAT, MUSHROOM, MERCHANT, INNKEEPER, WOLF,
	GOBLIN, PLANT, WITCH, MUD_GOLEM, STONE_GOLEM, SPIDER, SPECTER, SKELETON_WARRIOR,
	SKELETON_ROGUE, SKELETON_MAGE, FOG_LORD, FARMER, METAL_SLIME, BOARD, CAT, CHILD,
	CHICKEN, WOLF_CUB, MINI_GOLEM, LOYAL_SKELETON, TAMER, FOG_ECHO, RED_SLIME,
	POISON_MUSHROOM, CAVE_MUSHROOM, CRYPT_BAT, FROST_SPECTER }

const FIRE_COLOR := Color(1.0, 0.45, 0.1)
const HEAL_COLOR := Color(0.3, 1.0, 0.4)
## Color of the "¡Débil!" / "¡Resiste!" line under a damage number.
const TAG_COLOR := Color(1.0, 0.6, 0.2)
const GOLD := Color(1.0, 0.8, 0.2)
const KNIGHT := preload("res://assets/characters/Knight.glb")
const MAGE := preload("res://assets/characters/Mage.glb")
const SKELETON_WARRIOR := preload("res://assets/characters/Skeleton_Warrior.glb")
const SKELETON_ROGUE := preload("res://assets/characters/Skeleton_Rogue.glb")
const SKELETON_MAGE := preload("res://assets/characters/Skeleton_Mage.glb")
## The skeletons' weapons (separate KayKit models, held on the hand bones).
const SKELETON_BLADE := preload("res://assets/characters/Skeleton_Blade.gltf")
const SKELETON_STAFF := preload("res://assets/characters/Skeleton_Staff.gltf")
const SKELETON_SHIELD := preload("res://assets/characters/Skeleton_Shield_Small_A.gltf")
## Bones the weapons hang from, under the model's Rig/Skeleton3D.
const SKELETON_PATH := "Rig/Skeleton3D"
const RIGHT_HAND_BONE := "handslot.r"
const LEFT_HAND_BONE := "handslot.l"
## The Señor de la Niebla's aura: a see-through purple ball around him; in his second
## phase (play_phase()) it grows and thickens.
const FOG_AURA_COLOR := Color(0.55, 0.25, 0.85)
## The Eco de la Niebla's aura: pale cyan, what is left of the Señor's fog.
const ECHO_AURA_COLOR := Color(0.45, 0.85, 0.9)
const FOG_AURA_ALPHA := 0.2
const FOG_AURA_PHASE_ALPHA := 0.38
## KayKit characters are 2.47 units tall (helmet included); 0.65 makes the hero 1.6 m.
const CHARACTER_SCALE := 0.65
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
## Animation played for each role, the same for both KayKit characters.
const CHARACTER_ANIMS := {
	"idle": "Idle",
	"walk": "Running_A",
	"attack": "1H_Melee_Attack_Slice_Diagonal",
	"cast": "Spellcast_Shoot",
	"hit": "Hit_A",
	"dodge": "Dodge_Backward",
	"death": "Death_A",
	"cheer": "Cheer",
}
## The skeletons' animations: the same roles with their own walk, hit and fall.
const SKELETON_ANIMS := {
	"idle": "Idle",
	"walk": "Walking_D_Skeletons",
	"attack": "1H_Melee_Attack_Slice_Diagonal",
	"cast": "Spellcast_Shoot",
	"hit": "Hit_B",
	"dodge": "Dodge_Backward",
	"death": "Death_C_Skeletons",
	"cheer": "Taunt",
}
## The rogue strikes with a blade in each hand.
const ROGUE_ANIMS := {
	"idle": "Idle",
	"walk": "Walking_D_Skeletons",
	"attack": "Dualwield_Melee_Attack_Stab",
	"cast": "Spellcast_Shoot",
	"hit": "Hit_B",
	"dodge": "Dodge_Backward",
	"death": "Death_C_Skeletons",
	"cheer": "Taunt",
}
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
## Angle (radians about X) of the plant's upper jaw: resting, and wide open to bite.
const JAW_REST := 0.3
const JAW_OPEN := 0.95
## The hero as a person, not a suit of steel: the KayKit Knight's helmet is hidden and its
## armor meshes (one grey palette cell) are tinted bare arms, a blue tunic and leather
## legs. Multiplied over a grey that peaks near 0.42 linear, hence the values above 1.
const HERO_SKIN := Color(1.75, 1.28, 1.02)
## The Knight's atlas with the hair cell brown: the head's hair and skin share one mesh.
const HERO_HEAD_TEXTURE := preload("res://assets/characters/hero_head_texture.png")
const HERO_TUNIC := Color(0.75, 1.0, 1.7)
const HERO_LEGS := Color(0.95, 0.75, 0.6)
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
## Everything that changes between looks. Characters: scene, scale, top (height of the
## damage numbers), hide (prop nodes of the model to hide), anims and, optional, tint
## (multiplies every imported material: the merchant is a green Mage, the innkeeper an
## orange one), mesh_tints (mesh under the skeleton -> tint, the hero), and optional props (hand bone -> weapon model, for the skeletons) and
## aura (the Señor de la Niebla); the hero hides
## every hand mesh and shows only those of its equipment (set_equipment()). Slimes: color,
## scale (the whole blob, eyes and crown included), top and crown. Bat: color, wing
## color, top and fly (height it hovers at). Mushroom: cap and stem colors, scale and top.
## Wolf: fur, dark and eye colors, scale and top. Goblin: color, hat color, scale and top.
## Plant: stem, leaf, head and inner (mouth) colors, scale and top. Golems: color, dark
## color (legs and arms), eye color, scale and top. Spider: color, leg color, eye color,
## scale and top. Specter: color, aura color, scale, top and fly (height it floats at).
const LOOKS := {
	Look.HERO: {
		"scene": KNIGHT,
		"scale": CHARACTER_SCALE,
		"top": 1.9,
		"hide": [
			"Rig/Skeleton3D/head/Knight_Helmet",
			"Rig/Skeleton3D/handslot_l/1H_Sword_Offhand",
			"Rig/Skeleton3D/handslot_l/Badge_Shield",
			"Rig/Skeleton3D/handslot_l/Rectangle_Shield",
			"Rig/Skeleton3D/handslot_l/Round_Shield",
			"Rig/Skeleton3D/handslot_l/Spike_Shield",
			"Rig/Skeleton3D/handslot_r/1H_Sword",
			"Rig/Skeleton3D/handslot_r/2H_Sword",
		],
		"mesh_tints": {
			"Knight_ArmLeft": HERO_SKIN,
			"Knight_ArmRight": HERO_SKIN,
			"Knight_Body": HERO_TUNIC,
			"Knight_LegLeft": HERO_LEGS,
			"Knight_LegRight": HERO_LEGS,
		},
		"anims": CHARACTER_ANIMS,
	},
	Look.VILLAGER: {
		"scene": MAGE,
		"scale": CHARACTER_SCALE,
		"top": 2.2,
		"hide": [
			"Rig/Skeleton3D/handslot_l/Spellbook",
			"Rig/Skeleton3D/handslot_l/Spellbook_open",
			"Rig/Skeleton3D/handslot_r/1H_Wand",
		],
		"anims": CHARACTER_ANIMS,
	},
	Look.MERCHANT: {
		"scene": MAGE,
		"scale": CHARACTER_SCALE,
		"top": 2.2,
		"hide": [
			"Rig/Skeleton3D/handslot_l/Spellbook",
			"Rig/Skeleton3D/handslot_l/Spellbook_open",
			"Rig/Skeleton3D/handslot_r/1H_Wand",
		],
		"anims": CHARACTER_ANIMS,
		"tint": Color(0.75, 1.0, 0.65),
	},
	Look.TAMER: {
		"scene": MAGE,
		"scale": CHARACTER_SCALE,
		"top": 2.2,
		"hide": [
			"Rig/Skeleton3D/handslot_l/Spellbook",
			"Rig/Skeleton3D/handslot_l/Spellbook_open",
			"Rig/Skeleton3D/handslot_r/1H_Wand",
		],
		"anims": CHARACTER_ANIMS,
		"tint": Color(0.35, 0.75, 0.65),
	},
	Look.INNKEEPER: {
		"scene": MAGE,
		"scale": CHARACTER_SCALE,
		"top": 2.2,
		"hide": [
			"Rig/Skeleton3D/handslot_l/Spellbook",
			"Rig/Skeleton3D/handslot_l/Spellbook_open",
			"Rig/Skeleton3D/handslot_r/1H_Wand",
		],
		"anims": CHARACTER_ANIMS,
		"tint": Color(1.0, 0.75, 0.5),
	},
	Look.FARMER: {
		"scene": MAGE,
		"scale": CHARACTER_SCALE,
		"top": 2.2,
		"hide": [
			"Rig/Skeleton3D/handslot_l/Spellbook",
			"Rig/Skeleton3D/handslot_l/Spellbook_open",
			"Rig/Skeleton3D/handslot_r/1H_Wand",
		],
		"anims": CHARACTER_ANIMS,
		"tint": Color(0.65, 0.8, 1.0),
	},
	# The Niña of the forest village: a small Mage in pink.
	Look.CHILD: {
		"scene": MAGE,
		"scale": 0.48,
		"top": 1.7,
		"hide": [
			"Rig/Skeleton3D/handslot_l/Spellbook",
			"Rig/Skeleton3D/handslot_l/Spellbook_open",
			"Rig/Skeleton3D/handslot_r/1H_Wand",
		],
		"anims": CHARACTER_ANIMS,
		"tint": Color(1.0, 0.72, 0.8),
	},
	# A notice board: it stands still.
	Look.BOARD: {
		"color": Color(0.56, 0.38, 0.2),
		"dark_color": Color(0.36, 0.22, 0.1),
		"paper_color": Color(0.93, 0.89, 0.75),
		"top": 1.9,
	},
	Look.CAT: {
		"color": Color(0.85, 0.55, 0.25),
		"dark_color": Color(0.62, 0.36, 0.14),
		"eye_color": Color(0.2, 0.75, 0.3),
		"scale": 1.2,
		"top": 1.2,
	},
	Look.SLIME: {
		"color": Color(0.55, 0.3, 0.85),
		"scale": 1.0,
		"top": 1.3,
		"crown": false,
	},
	Look.KING_SLIME: {
		"color": Color(0.3, 0.45, 0.9),
		"scale": 1.6,
		"top": 2.1,
		"crown": true,
	},
	Look.METAL_SLIME: {
		"color": Color(0.78, 0.82, 0.88),
		"scale": 0.8,
		"top": 1.1,
		"crown": false,
	},
	# The color variants of 1.6.0: the same figures as the slime, the mushroom, the bat and
	# the specter, in other colors.
	Look.RED_SLIME: {
		"color": Color(0.85, 0.2, 0.18),
		"scale": 1.0,
		"top": 1.3,
		"crown": false,
	},
	Look.BAT: {
		"color": Color(0.32, 0.22, 0.42),
		"wing_color": Color(0.2, 0.13, 0.28),
		"top": 2.0,
		"fly": 1.1,
	},
	Look.CRYPT_BAT: {
		"color": Color(0.45, 0.1, 0.12),
		"wing_color": Color(0.3, 0.05, 0.08),
		"top": 2.0,
		"fly": 1.1,
	},
	Look.MUSHROOM: {
		"cap_color": Color(0.85, 0.2, 0.15),
		"stem_color": Color(0.95, 0.9, 0.78),
		"scale": 1.4,
		"top": 1.6,
	},
	Look.POISON_MUSHROOM: {
		"cap_color": Color(0.55, 0.22, 0.72),
		"stem_color": Color(0.9, 0.86, 0.8),
		"scale": 1.4,
		"top": 1.6,
	},
	# The cave mushroom: pale blue and 1.2 times the size of the Seta saltarina.
	Look.CAVE_MUSHROOM: {
		"cap_color": Color(0.62, 0.8, 0.98),
		"stem_color": Color(0.85, 0.9, 0.95),
		"scale": 1.4 * 1.2,
		"top": 1.6 * 1.2,
	},
	Look.WOLF: {
		"color": Color(0.45, 0.45, 0.52),
		"dark_color": Color(0.26, 0.26, 0.32),
		"eye_color": Color(1.0, 0.8, 0.2),
		"scale": 1.15,
		"top": 1.5,
	},
	# The creatures that fight beside the hero.
	Look.WOLF_CUB: {
		"color": Color(0.45, 0.45, 0.52),
		"dark_color": Color(0.26, 0.26, 0.32),
		"eye_color": Color(1.0, 0.8, 0.2),
		"scale": 1.15 * 0.7,
		"top": 1.5 * 0.7,
	},
	Look.MINI_GOLEM: {
		"color": Color(0.72, 0.55, 0.38),
		"dark_color": Color(0.55, 0.4, 0.26),
		"eye_color": Color(1.0, 0.85, 0.3),
		"scale": 0.7,
		"top": 2.0 * 0.7,
	},
	Look.LOYAL_SKELETON: {
		"scene": SKELETON_WARRIOR,
		"scale": CHARACTER_SCALE,
		"top": 1.9,
		"hide": [],
		"anims": SKELETON_ANIMS,
		"props": {RIGHT_HAND_BONE: SKELETON_BLADE, LEFT_HAND_BONE: SKELETON_SHIELD},
		"tint": Color(0.75, 0.9, 1.0),
	},
	Look.CHICKEN: {
		"color": Color(0.97, 0.97, 0.94),
		"comb_color": Color(0.85, 0.12, 0.1),
		"beak_color": Color(1.0, 0.6, 0.15),
		"leg_color": Color(0.95, 0.6, 0.2),
		"scale": 0.8,
		"top": 0.9,
	},
	Look.GOBLIN: {
		"color": Color(0.4, 0.68, 0.25),
		"hat_color": Color(0.62, 0.16, 0.12),
		"scale": 0.8,
		"top": 1.5,
	},
	Look.PLANT: {
		"stem_color": Color(0.25, 0.55, 0.2),
		"leaf_color": Color(0.16, 0.42, 0.14),
		"head_color": Color(0.72, 0.18, 0.32),
		"inner_color": Color(0.35, 0.05, 0.1),
		"scale": 1.25,
		"top": 1.9,
	},
	# The witch: the Mage in dark purple, a little taller than the villagers.
	Look.WITCH: {
		"scene": MAGE,
		"scale": 0.75,
		"top": 2.4,
		"hide": [
			"Rig/Skeleton3D/handslot_l/Spellbook",
			"Rig/Skeleton3D/handslot_l/Spellbook_open",
		],
		"anims": CHARACTER_ANIMS,
		"tint": Color(0.55, 0.32, 0.75),
	},
	Look.MUD_GOLEM: {
		"color": Color(0.5, 0.34, 0.2),
		"dark_color": Color(0.36, 0.24, 0.14),
		"eye_color": Color(1.0, 0.85, 0.3),
		"scale": 1.0,
		"top": 2.0,
	},
	# The boss: bigger, grey stone with glowing blue eyes.
	Look.STONE_GOLEM: {
		"color": Color(0.55, 0.55, 0.58),
		"dark_color": Color(0.38, 0.38, 0.42),
		"eye_color": Color(0.4, 0.85, 1.0),
		"scale": 1.55,
		"top": 3.1,
	},
	Look.SPIDER: {
		"color": Color(0.22, 0.18, 0.24),
		"leg_color": Color(0.14, 0.11, 0.15),
		"eye_color": Color(1.0, 0.2, 0.15),
		"scale": 1.1,
		"top": 1.2,
	},
	Look.SPECTER: {
		"color": Color(0.75, 0.85, 1.0),
		"aura_color": Color(0.3, 0.55, 1.0),
		"scale": 1.0,
		"top": 2.3,
		"fly": 0.5,
	},
	Look.FROST_SPECTER: {
		"color": Color(0.82, 0.95, 1.0),
		"aura_color": Color(0.55, 0.9, 1.0),
		"scale": 1.0,
		"top": 2.3,
		"fly": 0.5,
	},
	Look.SKELETON_WARRIOR: {
		"scene": SKELETON_WARRIOR,
		"scale": CHARACTER_SCALE,
		"top": 1.9,
		"hide": [],
		"anims": SKELETON_ANIMS,
		"props": {RIGHT_HAND_BONE: SKELETON_BLADE, LEFT_HAND_BONE: SKELETON_SHIELD},
	},
	Look.SKELETON_ROGUE: {
		"scene": SKELETON_ROGUE,
		"scale": CHARACTER_SCALE,
		"top": 1.9,
		"hide": [],
		"anims": ROGUE_ANIMS,
		"props": {RIGHT_HAND_BONE: SKELETON_BLADE, LEFT_HAND_BONE: SKELETON_BLADE},
	},
	Look.SKELETON_MAGE: {
		"scene": SKELETON_MAGE,
		"scale": CHARACTER_SCALE,
		"top": 2.0,
		"hide": [],
		"anims": SKELETON_ANIMS,
		"props": {RIGHT_HAND_BONE: SKELETON_STAFF},
	},
	# The final boss: the skeleton mage at 1.6 times the size, tinted dusky violet, in
	# a purple aura.
	Look.FOG_LORD: {
		"scene": SKELETON_MAGE,
		"scale": CHARACTER_SCALE * 1.6,
		"top": 3.2,
		"hide": [],
		"anims": SKELETON_ANIMS,
		"props": {RIGHT_HAND_BONE: SKELETON_STAFF},
		"tint": Color(0.78, 0.7, 0.95),
		"aura": FOG_AURA_COLOR,
	},
	# The boss after the ending: the skeleton warrior at 1.6 times the size, ash grey with
	# a blue cast, in a pale cyan aura.
	Look.FOG_ECHO: {
		"scene": SKELETON_WARRIOR,
		"scale": CHARACTER_SCALE * 1.6,
		"top": 3.1,
		"hide": [],
		"anims": SKELETON_ANIMS,
		"props": {RIGHT_HAND_BONE: SKELETON_BLADE, LEFT_HAND_BONE: SKELETON_SHIELD},
		"tint": Color(0.62, 0.72, 0.82),
		"aura": ECHO_AURA_COLOR,
	},
}

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


func _ready() -> void:
	_body = Node3D.new()
	add_child(_body)
	var data: Dictionary = LOOKS[look]
	_top = data.top
	if data.has("scene"):
		_build_character(data)
	elif look in [Look.BAT, Look.CRYPT_BAT]:
		_build_bat(data)
	elif look in [Look.MUSHROOM, Look.POISON_MUSHROOM, Look.CAVE_MUSHROOM]:
		_build_mushroom(data)
	elif look == Look.WOLF or look == Look.WOLF_CUB:
		_build_wolf(data)
	elif look == Look.CHICKEN:
		_build_chicken(data)
	elif look == Look.GOBLIN:
		_build_goblin(data)
	elif look == Look.PLANT:
		_build_plant(data)
	elif look in [Look.MUD_GOLEM, Look.STONE_GOLEM, Look.MINI_GOLEM]:
		_build_golem(data)
	elif look == Look.SPIDER:
		_build_spider(data)
	elif look in [Look.SPECTER, Look.FROST_SPECTER]:
		_build_specter(data)
	elif look == Look.BOARD:
		_build_board(data)
	elif look == Look.CAT:
		_build_cat(data)
	else:
		_build_slime(data)
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


## Hero only: shows the hand meshes of the weapon and shield worn (Equipment ids, ""
## for none) and hides the rest. A helmet shows the model's helmet mesh tinted with its
## color, with horns for the Yelmo de bruma. Armor does not change the model. Others ignore it.
func set_equipment(weapon_id: String, shield_id: String, helmet_id := "") -> void:
	if look != Look.HERO or _model == null:
		return
	var shown := {HAND_R: Equipment.mesh(weapon_id), HAND_L: Equipment.mesh(shield_id)}
	for hand: String in shown:
		for child in _model.get_node(hand).get_children():
			(child as Node3D).visible = child.name == shown[hand] and shown[hand] != ""
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
## ("¡Débil!", "¡Resiste!") floats under the number.
func play_hit(amount: int, crit: bool, tag := "") -> void:
	_spawn_number(amount, crit, Color.WHITE, tag)
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
func play_cast(color := FIRE_COLOR) -> void:
	_set_flash(true, color)
	var timer := _start("cast")
	if timer:
		await timer.timeout
	else:
		await _hop()
	_set_flash(false)
	await _end(timer)


## A ball in the spell's color grows on the actor and fades while the hit plays.
func play_burn(amount: int, color := FIRE_COLOR, tag := "") -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	var ball := MeshInstance3D.new()
	ball.mesh = _sphere(0.5)
	ball.material_override = mat
	ball.position = Vector3(0, _top * 0.45, 0)
	ball.scale = Vector3.ONE * 0.2
	add_child(ball)
	var t := create_tween()
	t.tween_property(ball, "scale", Vector3.ONE * 1.6, 0.3) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.3).set_delay(0.1)
	t.tween_callback(ball.queue_free)
	await play_hit(amount, false, tag)
	if t.is_running():
		await t.finished


## Glow and a number going up, green by default (HP); an MP heal passes its own color.
func play_heal(amount: int, color := HEAL_COLOR) -> void:
	_spawn_number(amount, false, color)
	_set_flash(true, color)
	await get_tree().create_timer(0.35).timeout
	_set_flash(false)


## Glow in a status color (poison, sleep, defend...); amount > 0 also floats a number of
## that color (poison damage).
func play_status(color: Color, amount := 0) -> void:
	if amount > 0:
		_spawn_number(amount, false, color)
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
	_set_flash(true, FOG_AURA_COLOR)
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
	if look == Look.HERO:
		var head := bones.get_node("Knight_Head") as MeshInstance3D
		var head_material := head.get_active_material(0).duplicate() as BaseMaterial3D
		head_material.albedo_texture = HERO_HEAD_TEXTURE
		head.set_surface_override_material(0, head_material)
	if data.has("aura"):
		_add_ghost(_body, _sphere(0.5), data.aura, FOG_AURA_ALPHA, Vector3(0, _top * 0.45, 0),
			Vector3(2.2, 3.2, 2.2))
		_aura = _body.get_child(-1) as MeshInstance3D
	if look == Look.HERO:
		var stick := _cylinder(STICK_RADIUS, STICK_LENGTH)
		stick.top_radius = STICK_RADIUS * 0.7
		_add_mesh(model.get_node(HAND_R), stick, STICK_COLOR, Vector3(0, STICK_CENTER, 0))
		var mi := model.get_node(HAND_R).get_child(-1) as MeshInstance3D
		mi.name = Equipment.STICK_MESH
		# The starting gear until set_equipment() says otherwise.
		set_equipment(Equipment.STICK, "")
	_anims = data.anims
	_anim = model.get_node(ANIM_PLAYER_PATH) as AnimationPlayer
	# The imported animations do not loop; idle and walk must.
	for role in ["idle", "walk"]:
		_anim.get_animation(_anims[role]).loop_mode = Animation.LOOP_LINEAR


func _build_slime(data: Dictionary) -> void:
	var color: Color = data.color
	var blob := Node3D.new()
	blob.scale = Vector3.ONE * data.scale
	_body.add_child(blob)
	_add_mesh(blob, LowPoly.blob(SLIME_PROFILE, SLIME_SEGMENTS), color, Vector3.ZERO, 0.6)
	for x in [-0.2, 0.2]:
		_add_mesh(blob, _sphere(0.12), Color.WHITE, Vector3(x, 0.5, -0.44))  # eye
		_add_mesh(blob, _sphere(0.055), Color(0.05, 0.05, 0.05), Vector3(x, 0.5, -0.55))  # pupil
	if data.crown:
		var band := _cylinder(0.27, 0.14)
		band.top_radius = 0.22
		_add_mesh(blob, band, GOLD, Vector3(0, 0.86, 0), 0.4)
		for i in 5:
			var angle := TAU * i / 5.0
			_add_mesh(blob, _cone(0.06, 0.16), GOLD,
				Vector3(cos(angle) * 0.19, 1.01, sin(angle) * 0.19), 0.4)  # spike


## A notice board on two posts, with its papers on the side it faces (-Z).
func _build_board(data: Dictionary) -> void:
	var post := BoxMesh.new()
	post.size = Vector3(0.12, 1.7, 0.12)
	for x in [-0.6, 0.6]:
		_add_mesh(_body, post, data.dark_color, Vector3(x, 0.85, 0))
	var board := BoxMesh.new()
	board.size = Vector3(1.5, 0.9, 0.08)
	_add_mesh(_body, board, data.color, Vector3(0, 1.3, 0))
	var paper := BoxMesh.new()
	paper.size = Vector3(0.32, 0.4, 0.01)
	for spot in [Vector3(-0.42, 1.32, -0.05), Vector3(0.02, 1.26, -0.05),
			Vector3(0.44, 1.36, -0.05)]:
		_add_mesh(_body, paper, data.paper_color, spot)


## A sitting cat: a rounded body, a head with pointed ears and eyes, and a tail.
func _build_cat(data: Dictionary) -> void:
	var root := Node3D.new()
	root.scale = Vector3.ONE * data.scale
	_body.add_child(root)
	_add_blob(root, SLIME_PROFILE, SLIME_SEGMENTS, data.color, Vector3.ZERO, Vector3.ZERO,
		Vector3(0.5, 0.6, 0.65))
	_add_mesh(root, _sphere(0.2), data.color, Vector3(0, 0.62, -0.1))
	for x in [-0.11, 0.11]:
		_add_mesh(root, _cone(0.07, 0.16), data.dark_color, Vector3(x, 0.84, -0.1))  # ear
		_add_mesh(root, _sphere(0.04), data.eye_color, Vector3(x * 0.8, 0.66, -0.28))  # eye
	_add_mesh(root, _cylinder(0.04, 0.5), data.dark_color, Vector3(0, 0.22, 0.4))  # tail
	(root.get_child(-1) as Node3D).rotation_degrees.x = 60.0


## A bat: round body with ears and eyes, hovering at data.fly, with two wings on pivots
## that the idle loop flaps.
func _build_bat(data: Dictionary) -> void:
	var color: Color = data.color
	var root := Node3D.new()
	root.position.y = data.fly
	_body.add_child(root)
	_add_mesh(root, _sphere(0.32), color, Vector3.ZERO, 0.7)
	for x in [-0.14, 0.14]:
		_add_mesh(root, _cone(0.08, 0.22), color, Vector3(x, 0.36, 0))  # ear
		_add_mesh(root, _sphere(0.08), Color(1.0, 0.85, 0.3), Vector3(x * 0.9, 0.08, -0.27))  # eye
		_add_mesh(root, _sphere(0.035), Color(0.05, 0.05, 0.05),
			Vector3(x * 0.9, 0.08, -0.34))  # pupil
	for side in [-1.0, 1.0]:
		var pivot := Node3D.new()
		pivot.position = Vector3(0.22 * side, 0.05, 0)
		root.add_child(pivot)
		var wing := BoxMesh.new()
		wing.size = Vector3(0.75, 0.04, 0.42)
		_add_mesh(pivot, wing, data.wing_color, Vector3(0.38 * side, 0, 0.05))
		_wings.append(pivot)


## A mushroom: pale stem with eyes and a red hemisphere cap with white spots.
func _build_mushroom(data: Dictionary) -> void:
	var root := Node3D.new()
	root.scale = Vector3.ONE * data.scale
	_body.add_child(root)
	var stem := _cylinder(0.2, 0.55)
	stem.top_radius = 0.16
	_add_mesh(root, stem, data.stem_color, Vector3(0, 0.275, 0))
	for x in [-0.08, 0.08]:
		_add_mesh(root, _sphere(0.05), Color(0.05, 0.05, 0.05), Vector3(x, 0.32, -0.18))  # eye
	var cap := SphereMesh.new()
	cap.radius = 0.5
	cap.height = 0.42
	cap.is_hemisphere = true
	cap.radial_segments = 9
	cap.rings = 3
	_add_mesh(root, cap, data.cap_color, Vector3(0, 0.5, 0), 0.6)
	for i in 5:
		var angle := TAU * i / 5.0 + 0.3
		_add_mesh(root, _sphere(0.07), Color.WHITE,
			Vector3(cos(angle) * 0.32, 0.83, sin(angle) * 0.32))  # spot
	_add_mesh(root, _sphere(0.08), Color.WHITE, Vector3(0, 0.92, 0))  # top spot


## A wolf: a faceted body and a wedge head along -Z on four legs, with ears, yellow
## eyes and a tail.
func _build_wolf(data: Dictionary) -> void:
	var root := Node3D.new()
	root.scale = Vector3.ONE * data.scale
	_body.add_child(root)
	_add_blob(root, WOLF_BODY_PROFILE, 6, data.color, Vector3(0, 0.62, 0.55),
		Vector3(-90, 0, 0))
	_add_blob(root, WOLF_HEAD_PROFILE, 5, data.color, Vector3(0, 0.82, -0.48),
		Vector3(-100, 0, 0))
	for x in [-0.1, 0.1]:
		_add_mesh(root, _cone(0.06, 0.18), data.dark_color, Vector3(x, 1.06, -0.6))  # ear
		_add_mesh(root, _sphere(0.045), data.eye_color, Vector3(x * 1.1, 0.92, -0.72))  # eye
		_add_mesh(root, _sphere(0.022), Color(0.05, 0.05, 0.05),
			Vector3(x * 1.1, 0.92, -0.765))  # pupil
	_add_mesh(root, _sphere(0.04), Color(0.05, 0.05, 0.05), Vector3(0, 0.74, -1.03))  # nose
	for x in [-0.17, 0.17]:
		for z in [-0.32, 0.34]:
			_add_blob(root, LEG_PROFILE, 4, data.dark_color, Vector3(x, 0.0, z))
	_add_mesh(root, _cone(0.07, 0.45), data.color, Vector3(0, 0.8, 0.72))  # tail
	(root.get_child(-1) as Node3D).rotation_degrees.x = 55.0


## A chicken: a white round body with a red comb and wattle, an orange beak, two thin
## legs and black eyes, facing -Z. About 0.7 m tall.
func _build_chicken(data: Dictionary) -> void:
	var root := Node3D.new()
	root.scale = Vector3.ONE * data.scale
	_body.add_child(root)
	_add_blob(root, SLIME_PROFILE, SLIME_SEGMENTS, data.color, Vector3(0, 0.2, 0.05),
		Vector3.ZERO, Vector3(0.4, 0.55, 0.5))  # body
	_add_mesh(root, _sphere(0.17), data.color, Vector3(0, 0.62, -0.18))  # head
	_add_mesh(root, _cone(0.1, 0.22), data.color, Vector3(0, 0.45, 0.32))  # tail
	(root.get_child(-1) as Node3D).rotation_degrees.x = -35.0
	_add_mesh(root, _cone(0.05, 0.14), data.comb_color, Vector3(0, 0.82, -0.18))  # comb
	_add_mesh(root, _sphere(0.045), data.comb_color, Vector3(0, 0.5, -0.3))  # wattle
	_add_mesh(root, _cone(0.05, 0.14), data.beak_color, Vector3(0, 0.62, -0.38))  # beak
	(root.get_child(-1) as Node3D).rotation_degrees.x = -90.0
	for x in [-0.08, 0.08]:
		_add_mesh(root, _sphere(0.025), Color(0.05, 0.05, 0.05),
			Vector3(x * 1.2, 0.67, -0.31))  # eye
		_add_mesh(root, _cylinder(0.018, 0.2), data.leg_color, Vector3(x * 1.3, 0.1, 0.0))  # leg


## A goblin: a small green slime with pointed ears and a red pointed hat.
func _build_goblin(data: Dictionary) -> void:
	var blob := Node3D.new()
	blob.scale = Vector3.ONE * data.scale
	_body.add_child(blob)
	_add_mesh(blob, LowPoly.blob(SLIME_PROFILE, SLIME_SEGMENTS), data.color, Vector3.ZERO, 0.7)
	for side in [-1.0, 1.0]:
		_add_mesh(blob, _sphere(0.11), Color.WHITE, Vector3(side * 0.19, 0.52, -0.45))  # eye
		_add_mesh(blob, _sphere(0.05), Color(0.05, 0.05, 0.05),
			Vector3(side * 0.19, 0.52, -0.55))  # pupil
		_add_mesh(blob, _cone(0.12, 0.5), data.color, Vector3(side * 0.66, 0.62, 0))  # ear
		(blob.get_child(-1) as Node3D).rotation_degrees.z = -70.0 * side
	var hat := _cone(0.34, 0.6)
	hat.radial_segments = 7
	_add_mesh(blob, hat, data.hat_color, Vector3(0, 1.08, 0.04))
	(blob.get_child(-1) as Node3D).rotation_degrees.x = 12.0


## A carnivorous plant: leaves at the foot of a stem with a round head of two jaws
## (the upper one on a pivot at the back, slightly open, with white teeth and spots).
func _build_plant(data: Dictionary) -> void:
	_sway = Node3D.new()
	_sway.scale = Vector3.ONE * data.scale
	_body.add_child(_sway)
	for i in 3:
		var leaf := Node3D.new()
		leaf.rotation.y = TAU * i / 3.0
		_sway.add_child(leaf)
		_add_blob(leaf, LowPoly.BUSH_PROFILE, 5, data.leaf_color, Vector3(0, 0, 0.32),
			Vector3.ZERO, Vector3(0.45, 0.22, 0.6))
	_add_mesh(_sway, _cylinder(0.08, 0.95), data.stem_color, Vector3(0, 0.47, 0))
	var head := Node3D.new()
	head.position = Vector3(0, 0.98, 0)
	_sway.add_child(head)
	_add_mesh(head, _hemisphere(0.36, 0.24), data.head_color, Vector3.ZERO)
	(head.get_child(-1) as Node3D).rotation_degrees.x = 180.0
	_add_mesh(head, _disc(0.33), data.inner_color, Vector3(0, 0.01, 0))
	_jaw = Node3D.new()
	_jaw.position = Vector3(0, 0, 0.3)
	head.add_child(_jaw)
	_add_mesh(_jaw, _hemisphere(0.36, 0.3), data.head_color, Vector3(0, 0, -0.3))
	_add_mesh(_jaw, _disc(0.33), data.inner_color, Vector3(0, -0.01, -0.3))
	for i in 6:
		var angle := PI * (0.15 + 0.7 * i / 5.0)
		var rim := Vector3(cos(angle) * 0.3, 0, -sin(angle) * 0.3)
		_add_mesh(head, _cone(0.035, 0.09), Color.WHITE, rim + Vector3(0, 0.04, 0))  # tooth
		_add_mesh(_jaw, _cone(0.035, 0.09), Color.WHITE, rim + Vector3(0, -0.04, -0.3))
		(_jaw.get_child(-1) as Node3D).rotation_degrees.x = 180.0
	for spot in [Vector3(-0.15, 0.2, -0.45), Vector3(0.17, 0.22, -0.4), Vector3(0, 0.27, -0.2)]:
		_add_mesh(_jaw, _sphere(0.05), Color(1.0, 0.95, 0.8), spot)
	_jaw.rotation.x = JAW_REST


## A golem: faceted blocks for the legs, the body, the head and two long arms, with
## glowing eyes and two loose stones on the shoulders.
func _build_golem(data: Dictionary) -> void:
	var root := Node3D.new()
	root.scale = Vector3.ONE * data.scale
	_body.add_child(root)
	for x in [-0.22, 0.22]:
		_add_blob(root, BLOCK_PROFILE, 4, data.dark_color, Vector3(x, 0, 0), Vector3(0, 45, 0),
			Vector3(0.36, 0.42, 0.36))  # leg
	_add_blob(root, BLOCK_PROFILE, 4, data.color, Vector3(0, 0.38, 0), Vector3(0, 45, 0),
		Vector3(1.05, 0.72, 0.8))  # body
	_add_blob(root, BLOCK_PROFILE, 4, data.color, Vector3(0, 1.08, -0.06), Vector3(0, 45, 0),
		Vector3(0.5, 0.36, 0.46))  # head
	for x in [-0.12, 0.12]:
		_add_mesh(root, _sphere(0.055), data.eye_color, Vector3(x, 1.24, -0.29), 0.2)  # eye
	for side in [-1.0, 1.0]:
		_add_blob(root, BLOCK_PROFILE, 4, data.dark_color, Vector3(side * 0.62, 0.12, -0.05),
			Vector3(0, 45, side * 8.0), Vector3(0.34, 0.86, 0.34))  # arm
		_add_blob(root, BLOCK_PROFILE, 4, data.color, Vector3(side * 0.42, 1.0, 0.05),
			Vector3(0, 20, 0), Vector3(0.22, 0.16, 0.22))  # loose stone


## A spider: a round abdomen behind a small head with red eyes, on eight bent legs
## (four a side, each a thigh going up and out and a shin going down to the ground).
func _build_spider(data: Dictionary) -> void:
	var root := Node3D.new()
	root.scale = Vector3.ONE * data.scale
	_body.add_child(root)
	_add_blob(root, ABDOMEN_PROFILE, 7, data.color, Vector3(0, 0.42, 0.32), Vector3(-75, 0, 0),
		Vector3(1.1, 1.0, 1.0))  # abdomen
	_add_mesh(root, _sphere(0.2), data.color, Vector3(0, 0.42, -0.12))  # head
	for x in [-0.07, 0.07]:
		_add_mesh(root, _sphere(0.045), data.eye_color, Vector3(x, 0.5, -0.3), 0.2)  # eye
		_add_mesh(root, _sphere(0.03), data.eye_color, Vector3(x * 2.0, 0.45, -0.28), 0.2)
	for side in [-1.0, 1.0]:
		for i in 4:
			var leg := Node3D.new()
			leg.position = Vector3(side * 0.14, 0.42, -0.2 + i * 0.13)
			# Each leg reaches out to +X of its pivot: the left ones are turned around.
			leg.rotation.y = deg_to_rad(40.0 - i * 27.0) * side + (PI if side < 0.0 else 0.0)
			root.add_child(leg)
			_add_mesh(leg, _cylinder(0.03, 0.42), data.leg_color, Vector3(0.18, 0.13, 0))
			(leg.get_child(-1) as Node3D).rotation_degrees.z = -60.0  # thigh, up and out
			_add_mesh(leg, _cylinder(0.025, 0.62), data.leg_color, Vector3(0.44, -0.12, 0))
			(leg.get_child(-1) as Node3D).rotation_degrees.z = 22.0  # shin, down to the ground


## A specter: a see-through pale drop with its tip down, floating at data.fly, with dark
## eyes and a wide blue aura around it.
func _build_specter(data: Dictionary) -> void:
	_hover = Node3D.new()
	_hover.position.y = data.fly
	_hover.scale = Vector3.ONE * data.scale
	_body.add_child(_hover)
	_add_ghost(_hover, LowPoly.blob(SPECTER_PROFILE, 8), data.color, SPECTER_ALPHA,
		Vector3.ZERO, Vector3.ONE)
	_add_ghost(_hover, _sphere(0.5), data.aura_color, AURA_ALPHA, Vector3(0, 0.62, 0),
		Vector3(1.5, 1.7, 1.5))
	for x in [-0.12, 0.12]:
		_add_mesh(_hover, _sphere(0.07), Color(0.05, 0.05, 0.12), Vector3(x, 0.8, -0.34))  # eye
	_add_mesh(_hover, _sphere(0.06), Color(0.05, 0.05, 0.12), Vector3(0, 0.6, -0.36))  # mouth


## The waiting loop of the figures built in code: the bat flaps, the plant sways, the
## specter floats, the rest squash and stretch (the wolf, the golems and the spider only
## breathe).
func _start_idle() -> void:
	if look == Look.BOARD:
		return
	if not _wings.is_empty():
		_start_flap()
	elif _sway:
		_start_sway()
	elif _hover:
		_start_float()
	else:
		var gentle := look in [Look.WOLF, Look.MUD_GOLEM, Look.STONE_GOLEM, Look.SPIDER,
			Look.CAT, Look.WOLF_CUB, Look.MINI_GOLEM]
		_start_bounce(0.4 if gentle else 1.0)


## Floating loop of the specter. Only _hover moves, so hits and dodges can move _body.
func _start_float() -> void:
	if _idle_tween:
		_idle_tween.kill()
	var fly: float = LOOKS[look].fly
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
	for angle in [0.6, -0.4]:
		_idle_tween.tween_property(_wings[0], "rotation:z", -angle, 0.18) \
			.set_trans(Tween.TRANS_SINE)
		_idle_tween.parallel().tween_property(_wings[1], "rotation:z", angle, 0.18) \
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


func _spawn_number(amount: int, crit: bool, color := Color.WHITE, tag := "") -> void:
	if tag != "":
		_float_label(tag, 40, TAG_COLOR, _top - 0.3)
	_float_label(str(amount), 96 if crit else 64, Color(1.0, 0.85, 0.2) if crit else color,
		_top)


## A billboard text drawn over everything that floats up from height y and fades out.
func _float_label(text: String, font_size: int, color: Color, y: float) -> void:
	var label := Label3D.new()
	label.text = text
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.pixel_size = 0.005
	label.font_size = font_size
	label.outline_size = 16
	label.modulate = color
	label.position = Vector3(0, y, 0)
	add_child(label)
	var t := label.create_tween().set_parallel()
	t.tween_property(label, "position:y", y + 0.8, 0.9)
	t.tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.3)
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
		mi.material_overlay = _flash if on else (_highlight if _highlighted else null)


## A soft glow over the figure while the player aims at it; a flash still shows over it.
func set_highlight(on: bool) -> void:
	_highlighted = on
	for mi in _meshes:
		if mi.material_overlay != _flash:
			mi.material_overlay = _highlight if on else null


func _set_alpha(alpha: float) -> void:
	for mat in _materials:
		mat.albedo_color.a = alpha
	for ghost in _ghosts:
		(ghost[0] as StandardMaterial3D).albedo_color.a = ghost[1] * alpha


func _add_mesh(parent: Node3D, mesh: Mesh, color: Color, pos: Vector3, \
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


## A see-through glowing mesh (the specter): its opacity rests at alpha and fades with
## the rest of the figure on defeat. It casts no shadow.
func _add_ghost(parent: Node3D, mesh: Mesh, color: Color, alpha: float, pos: Vector3, \
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


## A faceted lathe (LowPoly.blob) of profile at pos, turned rot_deg and scaled scl.
func _add_blob(parent: Node3D, profile: Array[Vector2], segments: int, color: Color, \
		pos: Vector3, rot_deg := Vector3.ZERO, scl := Vector3.ONE) -> void:
	_add_mesh(parent, LowPoly.blob(profile, segments), color, pos, 0.8)
	var mi := parent.get_child(-1) as MeshInstance3D
	mi.rotation_degrees = rot_deg
	mi.scale = scl


static func _hemisphere(radius: float, height: float) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.is_hemisphere = true
	mesh.radial_segments = 9
	mesh.rings = 3
	return mesh


## A flat round lid (the inside of the plant's mouth).
static func _disc(radius: float) -> CylinderMesh:
	var mesh := _cylinder(radius, 0.02)
	mesh.radial_segments = 9
	return mesh


static func _sphere(radius: float) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 10
	mesh.rings = 5
	return mesh


static func _cylinder(radius: float, height: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 8
	return mesh


static func _cone(radius: float, height: float) -> CylinderMesh:
	var mesh := _cylinder(radius, height)
	mesh.top_radius = 0.0
	return mesh
