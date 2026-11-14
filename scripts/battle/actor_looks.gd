class_name ActorLooks extends RefCounted
## Data only: every figure a BattleActor can be (enum Look) and what each is made of
## (LOOKS; the v3's figures are in ActorLooksV3.LOOKS: entry() reads both), with the KayKit models, weapons, head textures, colours and animation tables
## the entries name. Read by BattleActor, CreatureBuilder and CharacterBuilder; never
## touches nodes. BattleActor.Look is this enum (const Look = ActorLooks.Look).

enum Look { HERO, SLIME, VILLAGER, KING_SLIME, BAT, MUSHROOM, MERCHANT, INNKEEPER, WOLF,
	GOBLIN, PLANT, WITCH, MUD_GOLEM, STONE_GOLEM, SPIDER, SPECTER, SKELETON_WARRIOR,
	SKELETON_ROGUE, SKELETON_MAGE, FOG_LORD, FARMER, METAL_SLIME, BOARD, CAT, CHILD,
	CHICKEN, WOLF_CUB, MINI_GOLEM, LOYAL_SKELETON, TAMER, FOG_ECHO, RED_SLIME,
	POISON_MUSHROOM, CAVE_MUSHROOM, CRYPT_BAT, FROST_SPECTER, COLLECTOR, BRENA, TADEO, ULMA, FROG,
	SNAKE, MONKEY, TRAP_PLANT, TROPICAL_MUSHROOM, CARAVAN_CHIEF, HEALER, JAGUAR,
	SCORPION, SAND_SLIME, VULTURE, SAND_GOLEM, MUMMY, CANTEEN, SAND_WORM, SNOW_WOLF, ICE_GOLEM,
	SUMMIT_SPIRIT, ICE_BAT, GOAT, GRIFFIN, HOLLOW_ARMOR, GARGOYLE, SHADOW, SENTINEL, RUIN_RAT, CITY_GUARDIAN,
	PORTAL_DEVOURER, CARAVAN_MERCHANT, TRAVELLER_F, TRAVELLER_M, EXPLORER, SURVIVOR, POT, CARAVAN_COLLECTOR,
	ORVALLA, NEBLI, MIST_VILLAGER_M, MIST_VILLAGER_F, MIST_HEALER, MUD_TOAD, LEECH, WISP,
	WALKING_REED, MIST_CAIMAN }
const KNIGHT := preload("res://assets/characters/Knight.glb")
const MAGE := preload("res://assets/characters/Mage.glb")
const SKELETON_WARRIOR := preload("res://assets/characters/Skeleton_Warrior.glb")
const SKELETON_ROGUE := preload("res://assets/characters/Skeleton_Rogue.glb")
const SKELETON_MAGE := preload("res://assets/characters/Skeleton_Mage.glb")
## The skeletons' weapons (separate KayKit models, held on the hand bones).
const SKELETON_BLADE := preload("res://assets/characters/Skeleton_Blade.gltf")
const SKELETON_STAFF := preload("res://assets/characters/Skeleton_Staff.gltf")
const SKELETON_SHIELD := preload("res://assets/characters/Skeleton_Shield_Small_A.gltf")
## Bones the skeletons' weapons hang from (LOOKS "props"), under the model's Rig/Skeleton3D.
const RIGHT_HAND_BONE := "handslot.r"
const LEFT_HAND_BONE := "handslot.l"
## The Señor de la Niebla's aura: a see-through purple ball around him; in his second
## phase (play_phase()) it grows and thickens.
const FOG_AURA_COLOR := Color(0.55, 0.25, 0.85)
## The Eco de la Niebla's aura: pale cyan, what is left of the Señor's fog.
const ECHO_AURA_COLOR := Color(0.45, 0.85, 0.9)
## KayKit characters are 2.47 units tall (helmet included); 0.65 makes the hero 1.6 m.
const CHARACTER_SCALE := 0.65
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
## The hero as a person, not a suit of steel: the KayKit Knight's helmet is hidden and its
## armor meshes (one grey palette cell) are tinted bare arms, a blue tunic and leather
## legs. Multiplied over a grey that peaks near 0.42 linear, hence the values above 1.
const HERO_SKIN := Color(1.75, 1.28, 1.02)
## The Knight's atlas with the hair cell brown: the head's hair and skin share one mesh.
const HERO_HEAD_TEXTURE := preload("res://assets/characters/hero_head_texture.png")
const HERO_TUNIC := Color(0.75, 1.0, 1.7)
const HERO_LEGS := Color(0.95, 0.75, 0.6)
## The caravan's people (2.4.0): the Knight without helmet like the hero, with their own head
## (scripts/tools/head_textures.gd: the hair cell recoloured, and the skin), their own
## clothes and, for some, a hair piece built in code. No hats.
const HEAD_GREY := preload("res://assets/characters/head_gris_clara.png")
const HEAD_BLACK_DARK := preload("res://assets/characters/head_negro_morena.png")
const HEAD_RED := preload("res://assets/characters/head_pelirrojo_clara.png")
const HEAD_BLOND := preload("res://assets/characters/head_rubio_clara.png")
const HEAD_BROWN_DARK := preload("res://assets/characters/head_castano_morena.png")
const HEAD_BROWN_PALE := preload("res://assets/characters/head_castano_palida.png")
## Each hair's mean colour, as head_textures.gd prints it (the flat hair pieces match it).
const HAIR_GREY := Color(0.618, 0.618, 0.598)
const HAIR_BLOND := Color(0.858, 0.698, 0.378)
const HAIR_RED := Color(0.718, 0.298, 0.128)
const HAIR_BROWN := Color(0.298, 0.188, 0.108)
## The arms of a darker and a paler skin (HERO_SKIN is the light one).
const SKIN_DARK := Color(1.37, 0.79, 0.51)
const SKIN_PALE := Color(1.75, 1.2, 0.92)
## A person's hidden parts: the helmet and every hand mesh (no weapons).
const PERSON_HIDE := [
	"Rig/Skeleton3D/head/Knight_Helmet",
	"Rig/Skeleton3D/handslot_l/1H_Sword_Offhand",
	"Rig/Skeleton3D/handslot_l/Badge_Shield",
	"Rig/Skeleton3D/handslot_l/Rectangle_Shield",
	"Rig/Skeleton3D/handslot_l/Round_Shield",
	"Rig/Skeleton3D/handslot_l/Spike_Shield",
	"Rig/Skeleton3D/handslot_r/1H_Sword",
	"Rig/Skeleton3D/handslot_r/2H_Sword",
]
## The hair pieces, in the head bone's space (the Knight faces +Z there, before the turn):
## where, turned how and scaled how. Tuned with close frames.
const HAIR_PIECES := {
	"beard": {"profile": "beard", "pos": Vector3(0, 0.22, 0.4), "rot": Vector3(180, 0, 0),
		"scale": Vector3(0.6, 0.4, 0.38)},
	"bun": {"profile": "bun", "pos": Vector3(0, 0.85, -0.3), "rot": Vector3.ZERO,
		"scale": Vector3.ONE * 0.5},
	"tail": {"profile": "tail", "pos": Vector3(0, 0.75, -0.6), "rot": Vector3(-160, 0, 0),
		"scale": Vector3(0.3, 0.7, 0.3)},
}
const HAIR_PROFILES := {
	"beard": [Vector2(0, 0.0), Vector2(0.5, 0.15), Vector2(0.45, 0.6), Vector2(0, 1.0)],
	"bun": [Vector2(0, 0.0), Vector2(0.45, 0.2), Vector2(0.5, 0.55), Vector2(0.3, 0.9),
		Vector2(0, 1.0)],
	"tail": [Vector2(0, 0.0), Vector2(0.35, 0.15), Vector2(0.28, 0.6), Vector2(0, 1.0)],
}
const HAIR_SEGMENTS := 7
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
		"head_texture": HERO_HEAD_TEXTURE,
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
	# The Coleccionista of Villaclaro: the Mage tinted purple.
	Look.COLLECTOR: {
		"scene": MAGE,
		"scale": CHARACTER_SCALE,
		"top": 2.2,
		"hide": [
			"Rig/Skeleton3D/handslot_l/Spellbook",
			"Rig/Skeleton3D/handslot_l/Spellbook_open",
			"Rig/Skeleton3D/handslot_r/1H_Wand",
		],
		"anims": CHARACTER_ANIMS,
		"tint": Color(0.75, 0.55, 1.0),
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
	# The caravan's people (2.4.0): Knights without helmet, like the hero.
	Look.CARAVAN_CHIEF: {
		"scene": KNIGHT, "scale": CHARACTER_SCALE * 1.05, "top": 2.0, "hide": PERSON_HIDE,
		"head_texture": HEAD_GREY, "hair": {"style": "beard", "color": HAIR_GREY},
		"mesh_tints": {"Knight_ArmLeft": HERO_SKIN, "Knight_ArmRight": HERO_SKIN,
			"Knight_Body": Color(1.2, 0.85, 0.55), "Knight_LegLeft": Color(0.7, 0.5, 0.35),
			"Knight_LegRight": Color(0.7, 0.5, 0.35)},
		"cape": Color(0.16, 0.32, 0.18), "anims": CHARACTER_ANIMS,
	},
	# The Coleccionista in the Caravana: a person, in the purple of his Villaclaro robes.
	Look.CARAVAN_COLLECTOR: {
		"scene": KNIGHT, "scale": CHARACTER_SCALE, "top": 1.9, "hide": PERSON_HIDE,
		"head_texture": HEAD_BROWN_PALE, "hair": {"style": "bun", "color": HAIR_BROWN},
		"mesh_tints": {"Knight_ArmLeft": SKIN_PALE, "Knight_ArmRight": SKIN_PALE,
			"Knight_Body": Color(1.3, 0.8, 1.9), "Knight_LegLeft": Color(0.75, 0.6, 0.9),
			"Knight_LegRight": Color(0.75, 0.6, 0.9)},
		"cape": Color(0.5, 0.25, 0.7), "anims": CHARACTER_ANIMS,
	},
	Look.CARAVAN_MERCHANT: {
		"scene": KNIGHT, "scale": CHARACTER_SCALE, "top": 1.9, "hide": PERSON_HIDE,
		"head_texture": HEAD_BLACK_DARK,
		"mesh_tints": {"Knight_ArmLeft": SKIN_DARK, "Knight_ArmRight": SKIN_DARK,
			"Knight_Body": Color(1.9, 1.5, 0.45), "Knight_LegLeft": Color(0.5, 0.45, 0.42),
			"Knight_LegRight": Color(0.5, 0.45, 0.42)},
		"cape": Color(0.4, 0.2, 0.5), "anims": CHARACTER_ANIMS,
	},
	Look.HEALER: {
		"scene": KNIGHT, "scale": CHARACTER_SCALE, "top": 1.9, "hide": PERSON_HIDE,
		"head_texture": HEAD_RED, "hair": {"style": "bun", "color": HAIR_RED},
		"mesh_tints": {"Knight_ArmLeft": HERO_SKIN, "Knight_ArmRight": HERO_SKIN,
			"Knight_Body": Color(2.1, 2.1, 2.0), "Knight_LegLeft": Color(1.2, 1.6, 1.1),
			"Knight_LegRight": Color(1.2, 1.6, 1.1)},
		"cape": Color(0.3, 0.6, 0.35), "anims": CHARACTER_ANIMS,
	},
	Look.TRAVELLER_F: {
		"scene": KNIGHT, "scale": CHARACTER_SCALE, "top": 1.9, "hide": PERSON_HIDE,
		"head_texture": HEAD_BLOND, "hair": {"style": "tail", "color": HAIR_BLOND},
		"mesh_tints": {"Knight_ArmLeft": HERO_SKIN, "Knight_ArmRight": HERO_SKIN,
			"Knight_Body": Color(0.5, 1.6, 1.5), "Knight_LegLeft": Color(0.9, 0.9, 0.9),
			"Knight_LegRight": Color(0.9, 0.9, 0.9)},
		"hide_cape": true, "anims": CHARACTER_ANIMS,
	},
	Look.TRAVELLER_M: {
		"scene": KNIGHT, "scale": CHARACTER_SCALE, "top": 1.9, "hide": PERSON_HIDE,
		"head_texture": HEAD_BROWN_DARK,
		"mesh_tints": {"Knight_ArmLeft": SKIN_DARK, "Knight_ArmRight": SKIN_DARK,
			"Knight_Body": Color(1.8, 0.75, 0.5), "Knight_LegLeft": Color(0.9, 0.9, 0.9),
			"Knight_LegRight": Color(0.9, 0.9, 0.9)},
		"cape": Color(0.42, 0.28, 0.16), "anims": CHARACTER_ANIMS,
	},
	Look.EXPLORER: {
		"scene": KNIGHT, "scale": CHARACTER_SCALE, "top": 1.9, "hide": PERSON_HIDE,
		"head_texture": HEAD_BLOND, "hair": {"style": "tail", "color": HAIR_BLOND},
		"mesh_tints": {"Knight_ArmLeft": HERO_SKIN, "Knight_ArmRight": HERO_SKIN,
			"Knight_Body": Color(2.0, 1.05, 0.45), "Knight_LegLeft": HERO_LEGS,
			"Knight_LegRight": HERO_LEGS},
		"hide_cape": true, "anims": CHARACTER_ANIMS,
	},
	Look.SURVIVOR: {
		"scene": KNIGHT, "scale": CHARACTER_SCALE, "top": 1.9, "hide": PERSON_HIDE,
		"head_texture": HEAD_BROWN_PALE, "hair": {"style": "beard", "color": HAIR_BROWN},
		"mesh_tints": {"Knight_ArmLeft": SKIN_PALE, "Knight_ArmRight": SKIN_PALE,
			"Knight_Body": Color(1.05, 1.0, 0.92), "Knight_LegLeft": Color(0.8, 0.8, 0.8),
			"Knight_LegRight": Color(0.8, 0.8, 0.8)},
		"hide_cape": true, "anims": CHARACTER_ANIMS,
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
	# The caravan's companions: the Knight, each with its own gear and colour.
	Look.BRENA: {
		"scene": KNIGHT,
		"scale": CHARACTER_SCALE,
		"top": 2.0,
		"hide": [
			"Rig/Skeleton3D/handslot_l/1H_Sword_Offhand",
			"Rig/Skeleton3D/handslot_l/Badge_Shield",
			"Rig/Skeleton3D/handslot_l/Rectangle_Shield",
			"Rig/Skeleton3D/handslot_l/Round_Shield",
			"Rig/Skeleton3D/handslot_l/Spike_Shield",
			"Rig/Skeleton3D/handslot_r/1H_Sword",
		],
		"anims": CHARACTER_ANIMS,
		"tint": Color(1.0, 0.62, 0.55),
	},
	Look.TADEO: {
		"scene": KNIGHT,
		"scale": CHARACTER_SCALE,
		"top": 1.9,
		"hide": [
			"Rig/Skeleton3D/head/Knight_Helmet",
			"Rig/Skeleton3D/handslot_l/Badge_Shield",
			"Rig/Skeleton3D/handslot_l/Rectangle_Shield",
			"Rig/Skeleton3D/handslot_l/Round_Shield",
			"Rig/Skeleton3D/handslot_l/Spike_Shield",
			"Rig/Skeleton3D/handslot_r/2H_Sword",
		],
		"anims": CHARACTER_ANIMS,
		"tint": Color(0.65, 0.95, 0.6),
	},
	Look.ULMA: {
		"scene": KNIGHT,
		"scale": CHARACTER_SCALE,
		"top": 2.0,
		"hide": [
			"Rig/Skeleton3D/handslot_l/1H_Sword_Offhand",
			"Rig/Skeleton3D/handslot_l/Badge_Shield",
			"Rig/Skeleton3D/handslot_l/Round_Shield",
			"Rig/Skeleton3D/handslot_l/Spike_Shield",
			"Rig/Skeleton3D/handslot_r/2H_Sword",
		],
		"anims": CHARACTER_ANIMS,
		"tint": Color(0.78, 0.8, 0.86),
	},
	# The jungle (the v2).
	Look.FROG: {
		"color": Color(0.15, 0.55, 0.95),
		"spot_color": Color(0.08, 0.08, 0.1),
		"belly_color": Color(1.0, 0.8, 0.15),
		"scale": 1.4,
		"top": 1.1,
	},
	Look.SNAKE: {
		"color": Color(0.3, 0.6, 0.15),
		"dark_color": Color(0.16, 0.36, 0.08),
		"eye_color": Color(1.0, 0.85, 0.1),
		"scale": 1.0,
		"top": 1.3,
	},
	Look.MONKEY: {
		"color": Color(0.42, 0.28, 0.16),
		"face_color": Color(0.85, 0.68, 0.5),
		"scale": 1.0,
		"top": 1.5,
	},
	# The Jaguar sombrío, the jungle's boss: a big black wolf-shaped cat with glowing rosettes.
	Look.JAGUAR: {
		"color": Color(0.1, 0.09, 0.12),
		"dark_color": Color(0.05, 0.05, 0.07),
		"eye_color": Color(0.55, 1.0, 0.3),
		"spot_color": Color(0.85, 0.65, 0.15),
		"scale": 1.75,
		"top": 2.4,
	},
	# The desert (the v2, 2.1.0).
	Look.SCORPION: {
		"color": Color(0.55, 0.3, 0.14),
		"dark_color": Color(0.38, 0.2, 0.09),
		"eye_color": Color(0.08, 0.06, 0.05),
		"sting_color": Color(0.95, 0.85, 0.45),
		"scale": 1.2,
		"top": 1.3,
	},
	Look.SAND_SLIME: {
		"color": Color(0.86, 0.68, 0.38),
		"scale": 1.0,
		"top": 1.3,
		"crown": false,
	},
	# The Buitre: the bat's builder with a bald head, a hooked beak, a ruff and broad wings.
	Look.VULTURE: {
		"color": Color(0.42, 0.3, 0.2),
		"wing_color": Color(0.3, 0.2, 0.13),
		"head_color": Color(0.85, 0.6, 0.55),
		"ruff_color": Color(0.9, 0.86, 0.78),
		"beak_color": Color(0.95, 0.8, 0.4),
		"wing_size": Vector3(1.05, 0.04, 0.5),
		"top": 2.4,
		"fly": 1.3,
	},
	Look.SAND_GOLEM: {
		"color": Color(0.72, 0.58, 0.38),
		"dark_color": Color(0.56, 0.43, 0.27),
		"eye_color": Color(1.0, 0.55, 0.15),
		"scale": 1.15,
		"top": 2.3,
	},
	# The Momia: the skeleton warrior with no helmet, wrapped in dirty linen strips built in
	# code (_add_mummy_wraps), bare-handed, its eyes a dim glow in the gap of the head wrap.
	Look.MUMMY: {
		"scene": SKELETON_WARRIOR,
		"scale": CHARACTER_SCALE,
		"top": 1.9,
		"hide": ["Rig/Skeleton3D/head/Skeleton_Warrior_Helmet", "Rig/Skeleton3D/Skeleton_Warrior_Cloak"],
		"anims": SKELETON_ANIMS,
		"props": {},
		"tint": Color(0.86, 0.82, 0.74),
		"wrap_color": Color(0.8, 0.76, 0.66),
	},
	# The Jefe de caravana's canteen (the cantimplora quest's figure): it stands still.
	Look.CANTEEN: {
		"color": Color(0.5, 0.32, 0.18),
		"cork_color": Color(0.78, 0.62, 0.4),
		"strap_color": Color(0.3, 0.2, 0.12),
		"sand_color": Color(0.56, 0.44, 0.28),
		"top": 0.8,
	},
	# The Posadera's big pot (the olla quest's figure): the refugio's Kenney pot, still.
	Look.POT: {
		"model_scale": 1.0,
		"top": 0.9,
	},
	# The Gusano de las dunas: a segmented worm rising out of a ring of sand.
	Look.SAND_WORM: {
		"color": Color(0.78, 0.55, 0.36),
		"dark_color": Color(0.62, 0.42, 0.27),
		"mouth_color": Color(0.35, 0.08, 0.1),
		"teeth_color": Color(0.96, 0.93, 0.82),
		"sand_color": Color(0.56, 0.44, 0.28),
		"scale": 1.6,
		"top": 3.4,
	},
	# The mountain (the v2, 2.2.0).
	Look.SNOW_WOLF: {
		"color": Color(0.8, 0.84, 0.9),
		"dark_color": Color(0.46, 0.52, 0.64),
		"eye_color": Color(0.35, 0.75, 1.0),
		"scale": 1.15,
		"top": 1.5,
	},
	Look.ICE_GOLEM: {
		"color": Color(0.6, 0.8, 0.95),
		"dark_color": Color(0.4, 0.58, 0.78),
		"eye_color": Color(0.2, 0.45, 1.0),
		"scale": 1.3,
		"top": 2.6,
	},
	# The Espíritu de la cumbre: the specter, deep blue and bigger, with a pale gold aura
	# (the Espectro de escarcha is the white and blue one).
	Look.SUMMIT_SPIRIT: {
		"color": Color(0.34, 0.42, 0.82),
		"aura_color": Color(1.0, 0.76, 0.28),
		"alpha": 0.9,
		"scale": 1.2,
		"top": 2.7,
		"fly": 0.6,
	},
	Look.ICE_BAT: {
		"color": Color(0.45, 0.62, 0.85),
		"wing_color": Color(0.3, 0.45, 0.7),
		"top": 2.0,
		"fly": 1.1,
	},
	Look.GOAT: {
		"color": Color(0.55, 0.47, 0.38),
		"dark_color": Color(0.36, 0.3, 0.24),
		"belly_color": Color(0.9, 0.86, 0.78),
		"horn_color": Color(0.82, 0.76, 0.62),
		"eye_color": Color(0.95, 0.75, 0.2),
		"scale": 1.1,
		"top": 1.7,
	},
	# The Grifo de la cumbre: a lion's body, an eagle's white chest and head, broad wings.
	Look.GRIFFIN: {
		"color": Color(0.78, 0.6, 0.36),
		"dark_color": Color(0.6, 0.44, 0.26),
		"feather_color": Color(0.94, 0.93, 0.9),
		"wing_color": Color(0.7, 0.55, 0.36),
		"beak_color": Color(0.95, 0.78, 0.3),
		"eye_color": Color(0.1, 0.08, 0.05),
		"scale": 1.6,
		"top": 3.1,
		"flap_time": 0.45,
	},
	Look.TRAP_PLANT: {
		"stem_color": Color(0.1, 0.42, 0.12),
		"leaf_color": Color(0.12, 0.6, 0.18),
		"head_color": Color(0.85, 0.15, 0.35),
		"inner_color": Color(0.35, 0.05, 0.1),
		"scale": 1.3,
		"top": 1.9,
	},
	Look.TROPICAL_MUSHROOM: {
		"cap_color": Color(1.0, 0.5, 0.1),
		"stem_color": Color(0.98, 0.92, 0.8),
		"scale": 1.4,
		"top": 1.6,
	},
	# The abandoned city (the v2, 2.3.0). The Armadura hueca: the Knight with no head and no
	# helmet, black, its sword and round shield, an ember glowing in its empty collar.
	Look.HOLLOW_ARMOR: {
		"scene": KNIGHT,
		"scale": CHARACTER_SCALE * 1.05,
		"top": 1.9,
		"hide": [
			"Rig/Skeleton3D/Knight_Head",
			"Rig/Skeleton3D/head/Knight_Helmet",
			"Rig/Skeleton3D/handslot_l/1H_Sword_Offhand",
			"Rig/Skeleton3D/handslot_l/Badge_Shield",
			"Rig/Skeleton3D/handslot_l/Rectangle_Shield",
			"Rig/Skeleton3D/handslot_l/Spike_Shield",
			"Rig/Skeleton3D/handslot_r/2H_Sword",
		],
		"anims": CHARACTER_ANIMS,
		"tint": Color(0.32, 0.32, 0.38),
		"neck_glow": Color(1.0, 0.3, 0.15),
	},
	Look.GARGOYLE: {
		"color": Color(0.46, 0.44, 0.46),
		"dark_color": Color(0.32, 0.3, 0.33),
		"wing_color": Color(0.38, 0.36, 0.4),
		"horn_color": Color(0.62, 0.58, 0.52),
		"eye_color": Color(1.0, 0.25, 0.15),
		"scale": 1.15,
		"top": 2.1,
		"flap_time": 0.5,
	},
	# The Sombra: the specter in black with a red aura.
	Look.SHADOW: {
		"color": Color(0.1, 0.07, 0.09),
		"aura_color": Color(0.85, 0.1, 0.08),
		"alpha": 0.8,
		"eye_color": Color(1.0, 0.85, 0.75),
		"scale": 1.1,
		"top": 2.5,
		"fly": 0.5,
	},
	# The Esqueleto centinela: the skeleton warrior, reddish.
	Look.SENTINEL: {
		"scene": SKELETON_WARRIOR,
		"scale": CHARACTER_SCALE,
		"top": 1.9,
		"hide": [],
		"anims": SKELETON_ANIMS,
		"props": {RIGHT_HAND_BONE: SKELETON_BLADE, LEFT_HAND_BONE: SKELETON_SHIELD},
		"tint": Color(0.95, 0.6, 0.52),
	},
	Look.RUIN_RAT: {
		"color": Color(0.42, 0.36, 0.32),
		"dark_color": Color(0.3, 0.25, 0.22),
		"ear_color": Color(0.85, 0.6, 0.6),
		"eye_color": Color(1.0, 0.2, 0.15),
		"scale": 1.0,
		"top": 1.1,
	},
	# The Guardián de la ciudad: the Knight at 1.8 times the size, in bronze, with its helmet
	# and the two-handed sword.
	# The Devorador del portal: a dark faceted mass with six mouths round a great eye.
	Look.PORTAL_DEVOURER: {
		"color": Color(0.13, 0.08, 0.15),
		"dark_color": Color(0.07, 0.04, 0.09),
		"lip_color": Color(0.45, 0.06, 0.1),
		"tooth_color": Color(0.92, 0.88, 0.78),
		"sclera_color": Color(0.95, 0.9, 0.85),
		"iris_color": Color(0.95, 0.2, 0.1),
		"glow_color": Color(1.0, 0.2, 0.1),
		"scale": 0.9,
		"top": 3.3,
	},
	Look.CITY_GUARDIAN: {
		"scene": KNIGHT,
		"scale": CHARACTER_SCALE * 1.8,
		"top": 3.5,
		"hide": [
			"Rig/Skeleton3D/handslot_l/1H_Sword_Offhand",
			"Rig/Skeleton3D/handslot_l/Badge_Shield",
			"Rig/Skeleton3D/handslot_l/Rectangle_Shield",
			"Rig/Skeleton3D/handslot_l/Round_Shield",
			"Rig/Skeleton3D/handslot_l/Spike_Shield",
			"Rig/Skeleton3D/handslot_r/1H_Sword",
		],
		"anims": CHARACTER_ANIMS,
		"tint": Color(1.0, 0.82, 0.38),
	},
}


## What look is made of: its LOOKS entry, or ActorLooksV3's for a figure of the v3.
static func entry(look: Look) -> Dictionary:
	return LOOKS[look] if LOOKS.has(look) else ActorLooksV3.LOOKS[look]
