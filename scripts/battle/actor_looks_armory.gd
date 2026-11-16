class_name ActorLooksArmory extends RefCounted
## Data only: the armeros, each in the style of its place (3.10.0, M-124), kept apart from
## ActorLooks so that file does not grow. Each entry has the shape of ActorLooks.LOOKS (a KayKit
## person with a "scene"); ActorLooks.entry() reads them. What they wear and carry beyond the
## model's own pieces is SmithDress's ("hammer", "apron", "miner_cap") and MistDress's ("hood").
## Each hammer's head is the metal its counter sells: copper in Villaclaro, iron in the forest,
## steel in the mine, platinum in the castle, then the Caravana's jade, orichalcum, adamantite and
## stellar (CampLook.ARMORERS picks the Caravana's for its tramo). Brumaclara's Herrero de cristal
## is ActorLooksV3's MIST_SMITH. The colours are starting values tuned with close frames. Never
## touches nodes.

const Look = ActorLooks.Look

## A Mage whose hands hold only what SmithDress gives it: its spellbooks, wand and staff hidden.
const MAGE_EMPTY_HANDS := [
	"Rig/Skeleton3D/handslot_l/Spellbook",
	"Rig/Skeleton3D/handslot_l/Spellbook_open",
	"Rig/Skeleton3D/handslot_r/1H_Wand",
	"Rig/Skeleton3D/handslot_r/2H_Staff",
]
## A Knight in its helmet with empty hands (ActorLooks.PERSON_HIDE without the helmet).
const HELMED_HIDE := [
	"Rig/Skeleton3D/handslot_l/1H_Sword_Offhand",
	"Rig/Skeleton3D/handslot_l/Badge_Shield",
	"Rig/Skeleton3D/handslot_l/Rectangle_Shield",
	"Rig/Skeleton3D/handslot_l/Round_Shield",
	"Rig/Skeleton3D/handslot_l/Spike_Shield",
	"Rig/Skeleton3D/handslot_r/1H_Sword",
	"Rig/Skeleton3D/handslot_r/2H_Sword",
]
## The skins of the arms (ActorLooks' light and dark ones).
const SKIN_LIGHT := ActorLooks.HERO_SKIN
const SKIN_DARK := ActorLooks.SKIN_DARK
## The hammers' heads: the metal each counter sells, each told apart (iron dark, steel blue grey,
## platinum near white, stellar sky blue).
const COPPER := Color(0.85, 0.5, 0.3)
const IRON := Color(0.32, 0.32, 0.36)
const STEEL := Color(0.52, 0.58, 0.68)
const PLATINUM := Color(0.97, 0.97, 0.95)
const JADE := Color(0.35, 0.75, 0.5)
const ORICHALCUM := Color(1.0, 0.7, 0.35)
const ADAMANTITE := Color(0.45, 0.4, 0.62)
const STELLAR := Color(0.5, 0.72, 1.0)
## The aprons' leather, darker than the hammers' wooden handles.
const LEATHER := Color(0.35, 0.22, 0.14)
## The city's bronze armour (its body, arms and helmet).
const BRONZE := Color(1.6, 1.15, 0.6)

const LOOKS := {
	# Villaclaro's Armera, a good witch of the meadow: the Mage with its pointed hat and robe in a
	# night blue grey (not the Mercader's green, the Coleccionista's purple or the Bruja's violet)
	# and a copper hammer.
	Look.ARMORER_VILLACLARO: {
		"scene": ActorLooks.MAGE, "scale": ActorLooks.CHARACTER_SCALE, "top": 2.2,
		"hide": MAGE_EMPTY_HANDS, "tint": Color(0.44, 0.5, 0.62), "hammer": COPPER,
		"anims": ActorLooks.CHARACTER_ANIMS,
	},
	# The forest village's Armero, a woodsman: a red beard, leaf-green leather, a moss cape, a
	# leather apron and an iron hammer.
	Look.ARMORER_FOREST: {
		"scene": ActorLooks.KNIGHT, "scale": ActorLooks.CHARACTER_SCALE, "top": 1.9,
		"hide": ActorLooks.PERSON_HIDE, "head_texture": ActorLooks.HEAD_RED,
		"hair": {"style": "beard", "color": ActorLooks.HAIR_RED},
		"mesh_tints": {"Knight_ArmLeft": SKIN_LIGHT, "Knight_ArmRight": SKIN_LIGHT,
			"Knight_Body": Color(0.7, 1.2, 0.55), "Knight_LegLeft": Color(0.7, 0.5, 0.35),
			"Knight_LegRight": Color(0.7, 0.5, 0.35)},
		"cape": Color(0.22, 0.38, 0.18), "apron": LEATHER, "hammer": IRON,
		"anims": ActorLooks.CHARACTER_ANIMS,
	},
	# The mine's Herrero, a miner: a brass cap with its lamp, a brown beard, sooty clothes, a
	# leather apron and a steel hammer.
	Look.ARMORER_MINE: {
		"scene": ActorLooks.KNIGHT, "scale": ActorLooks.CHARACTER_SCALE, "top": 2.0,
		"hide": ActorLooks.PERSON_HIDE, "head_texture": ActorLooks.HEAD_BROWN_DARK,
		"hair": {"style": "beard", "color": ActorLooks.HAIR_BROWN},
		"mesh_tints": {"Knight_ArmLeft": SKIN_DARK, "Knight_ArmRight": SKIN_DARK,
			"Knight_Body": Color(0.75, 0.7, 0.65), "Knight_LegLeft": Color(0.45, 0.42, 0.4),
			"Knight_LegRight": Color(0.45, 0.42, 0.4)},
		"hide_cape": true, "apron": LEATHER, "miner_cap": Color(0.95, 0.75, 0.3),
		"hammer": STEEL, "anims": ActorLooks.CHARACTER_ANIMS,
	},
	# The castle camp's Armero, the king's: the Knight in its own armour and helmet, a crimson cape
	# and a platinum hammer.
	Look.ARMORER_CASTLE: {
		"scene": ActorLooks.KNIGHT, "scale": ActorLooks.CHARACTER_SCALE, "top": 2.0,
		"hide": HELMED_HIDE, "cape": Color(0.55, 0.12, 0.15), "hammer": PLATINUM,
		"anims": ActorLooks.CHARACTER_ANIMS,
	},
	# The Caravana's Armero by the jungle: leaf green and khaki, sleeves rolled up (the dark skin
	# on the arms), no cape, a leather apron and a jade hammer.
	Look.ARMORER_JUNGLE: {
		"scene": ActorLooks.KNIGHT, "scale": ActorLooks.CHARACTER_SCALE, "top": 1.9,
		"hide": ActorLooks.PERSON_HIDE, "head_texture": ActorLooks.HEAD_BROWN_DARK,
		"mesh_tints": {"Knight_ArmLeft": SKIN_DARK, "Knight_ArmRight": SKIN_DARK,
			"Knight_Body": Color(0.5, 1.2, 0.6), "Knight_LegLeft": Color(1.1, 0.95, 0.6),
			"Knight_LegRight": Color(1.1, 0.95, 0.6)},
		"hide_cape": true, "apron": LEATHER, "hammer": JADE,
		"anims": ActorLooks.CHARACTER_ANIMS,
	},
	# By the desert: sand robes, a sand hood (MistDress's) and cape, an orichalcum hammer.
	Look.ARMORER_DESERT: {
		"scene": ActorLooks.KNIGHT, "scale": ActorLooks.CHARACTER_SCALE, "top": 1.9,
		"hide": ActorLooks.PERSON_HIDE, "head_texture": ActorLooks.HEAD_BLACK_DARK,
		"hood": Color(0.92, 0.82, 0.58),
		"mesh_tints": {"Knight_ArmLeft": SKIN_DARK, "Knight_ArmRight": SKIN_DARK,
			"Knight_Body": Color(1.9, 1.6, 1.05), "Knight_LegLeft": Color(1.5, 1.3, 0.9),
			"Knight_LegRight": Color(1.5, 1.3, 0.9)},
		"cape": Color(0.85, 0.68, 0.42), "hammer": ORICHALCUM,
		"anims": ActorLooks.CHARACTER_ANIMS,
	},
	# By the mountain: brown furs, a white fur hood and a pale cape, an adamantite hammer.
	Look.ARMORER_MOUNTAIN: {
		"scene": ActorLooks.KNIGHT, "scale": ActorLooks.CHARACTER_SCALE, "top": 1.9,
		"hide": ActorLooks.PERSON_HIDE, "head_texture": ActorLooks.HEAD_GREY,
		"hood": Color(0.88, 0.88, 0.9),
		"mesh_tints": {"Knight_ArmLeft": SKIN_LIGHT, "Knight_ArmRight": SKIN_LIGHT,
			"Knight_Body": Color(0.85, 0.62, 0.45), "Knight_LegLeft": Color(0.55, 0.45, 0.38),
			"Knight_LegRight": Color(0.55, 0.45, 0.38)},
		"cape": Color(0.78, 0.78, 0.82), "hammer": ADAMANTITE,
		"anims": ActorLooks.CHARACTER_ANIMS,
	},
	# By the ruined city, then by the calmed portal and in the v3: bronze armour and helmet, an ash
	# cape, a leather apron and a stellar hammer.
	Look.ARMORER_CITY: {
		"scene": ActorLooks.KNIGHT, "scale": ActorLooks.CHARACTER_SCALE, "top": 2.0,
		"hide": HELMED_HIDE,
		"mesh_tints": {"Knight_ArmLeft": BRONZE, "Knight_ArmRight": BRONZE, "Knight_Body": BRONZE,
			"Knight_LegLeft": Color(0.8, 0.6, 0.4), "Knight_LegRight": Color(0.8, 0.6, 0.4),
			"head/Knight_Helmet": BRONZE},
		"cape": Color(0.32, 0.3, 0.3), "apron": LEATHER, "hammer": STELLAR,
		"anims": ActorLooks.CHARACTER_ANIMS,
	},
}
