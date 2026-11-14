class_name ActorLooksV3 extends RefCounted
## Data only: the figures of the v3 (Brumaclara and its lands; 3.0.0), kept apart from
## ActorLooks so that file does not grow. Each entry has the shape of ActorLooks.LOOKS (a
## KayKit person has a "scene", a figure built in code is built by MistCreatureBuilder);
## ActorLooks.entry() reads them. "gentle": true bounces slowly when idle. Never touches nodes.

const Look = ActorLooks.Look

const LOOKS := {
	# Brumaclara's people (3.0.0): Knights without helmet, like the caravan's, in the grey
	# blues of the mist.
	# Orvalla, the lighthouse keeper: grey hair in a bun, a long dark-blue cape.
	Look.ORVALLA: {
		"scene": ActorLooks.KNIGHT, "scale": ActorLooks.CHARACTER_SCALE, "top": 1.9,
		"hide": ActorLooks.PERSON_HIDE, "head_texture": ActorLooks.HEAD_GREY,
		"hair": {"style": "bun", "color": ActorLooks.HAIR_GREY},
		"mesh_tints": {"Knight_ArmLeft": ActorLooks.HERO_SKIN, "Knight_ArmRight": ActorLooks.HERO_SKIN,
			"Knight_Body": Color(0.55, 0.7, 1.3), "Knight_LegLeft": Color(0.6, 0.6, 0.75),
			"Knight_LegRight": Color(0.6, 0.6, 0.75)},
		"cape": Color(0.2, 0.24, 0.4), "anims": ActorLooks.CHARACTER_ANIMS,
	},
	# Neblí, a child of Brumaclara who has never seen the sun.
	Look.NEBLI: {
		"scene": ActorLooks.KNIGHT, "scale": ActorLooks.CHARACTER_SCALE * 0.7, "top": 1.4,
		"hide": ActorLooks.PERSON_HIDE, "head_texture": ActorLooks.HEAD_BLOND,
		"hair": {"style": "tail", "color": ActorLooks.HAIR_BLOND},
		"mesh_tints": {"Knight_ArmLeft": ActorLooks.SKIN_PALE, "Knight_ArmRight": ActorLooks.SKIN_PALE,
			"Knight_Body": Color(0.9, 1.1, 1.6), "Knight_LegLeft": Color(0.8, 0.8, 0.9),
			"Knight_LegRight": Color(0.8, 0.8, 0.9)},
		"hide_cape": true, "anims": ActorLooks.CHARACTER_ANIMS,
	},
	Look.MIST_VILLAGER_M: {
		"scene": ActorLooks.KNIGHT, "scale": ActorLooks.CHARACTER_SCALE, "top": 1.9,
		"hide": ActorLooks.PERSON_HIDE, "head_texture": ActorLooks.HEAD_BROWN_DARK,
		"mesh_tints": {"Knight_ArmLeft": ActorLooks.SKIN_DARK, "Knight_ArmRight": ActorLooks.SKIN_DARK,
			"Knight_Body": Color(0.7, 0.75, 1.0), "Knight_LegLeft": Color(0.55, 0.55, 0.65),
			"Knight_LegRight": Color(0.55, 0.55, 0.65)},
		"cape": Color(0.3, 0.32, 0.42), "anims": ActorLooks.CHARACTER_ANIMS,
	},
	Look.MIST_VILLAGER_F: {
		"scene": ActorLooks.KNIGHT, "scale": ActorLooks.CHARACTER_SCALE, "top": 1.9,
		"hide": ActorLooks.PERSON_HIDE, "head_texture": ActorLooks.HEAD_RED,
		"hair": {"style": "bun", "color": ActorLooks.HAIR_RED},
		"mesh_tints": {"Knight_ArmLeft": ActorLooks.HERO_SKIN, "Knight_ArmRight": ActorLooks.HERO_SKIN,
			"Knight_Body": Color(1.0, 0.8, 1.3), "Knight_LegLeft": Color(0.7, 0.65, 0.8),
			"Knight_LegRight": Color(0.7, 0.65, 0.8)},
		"hide_cape": true, "anims": ActorLooks.CHARACTER_ANIMS,
	},
	# Brumaclara's Curandera (the inn, from the Garza on): white and pale blue.
	Look.MIST_HEALER: {
		"scene": ActorLooks.KNIGHT, "scale": ActorLooks.CHARACTER_SCALE, "top": 1.9,
		"hide": ActorLooks.PERSON_HIDE, "head_texture": ActorLooks.HEAD_BROWN_PALE,
		"hair": {"style": "tail", "color": ActorLooks.HAIR_BROWN},
		"mesh_tints": {"Knight_ArmLeft": ActorLooks.SKIN_PALE, "Knight_ArmRight": ActorLooks.SKIN_PALE,
			"Knight_Body": Color(1.6, 1.7, 2.0), "Knight_LegLeft": Color(0.9, 1.0, 1.2),
			"Knight_LegRight": Color(0.9, 1.0, 1.2)},
		"cape": Color(0.4, 0.55, 0.7), "anims": ActorLooks.CHARACTER_ANIMS,
	},
}
