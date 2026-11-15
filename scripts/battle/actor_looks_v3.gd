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
	# The Ciénaga (3.0.0). Variants of older figures, in the swamp's colours (CreatureBuilder
	# builds them: the frog, the snake, the plant), and two new ones (MistCreatureBuilder).
	# The Sapo de légamo: the Rana dardo, greyish green and 1.4 times its size.
	Look.MUD_TOAD: {
		"color": Color(0.36, 0.44, 0.3),
		"spot_color": Color(0.2, 0.24, 0.16),
		"belly_color": Color(0.62, 0.6, 0.42),
		"scale": 1.96,
		"top": 1.55,
	},
	# The Sanguijuela: the vine snake, short and purple.
	Look.LEECH: {
		"color": Color(0.42, 0.2, 0.46),
		"dark_color": Color(0.26, 0.1, 0.3),
		"eye_color": Color(0.95, 0.6, 0.2),
		"scale": 0.8,
		"top": 1.05,
	},
	# The Fuego fatuo: a blue flame that floats, with a bright core and two dark eyes.
	Look.WISP: {
		"color": Color(0.3, 0.55, 1.0),
		"core_color": Color(0.8, 0.95, 1.0),
		"fly": 0.9,
		"scale": 1.0,
		"top": 2.1,
	},
	# The Junco andante: the plant, in the ochres of the reeds.
	Look.WALKING_REED: {
		"stem_color": Color(0.62, 0.5, 0.24),
		"leaf_color": Color(0.5, 0.42, 0.2),
		"head_color": Color(0.72, 0.6, 0.32),
		"inner_color": Color(0.35, 0.28, 0.12),
		"scale": 1.25,
		"top": 1.9,
	},
	# The Caimán de bruma: long and low, grey green, a ridge of scutes, dragging a little mist.
	Look.MIST_CAIMAN: {
		"color": Color(0.3, 0.36, 0.34),
		"dark_color": Color(0.18, 0.22, 0.22),
		"eye_color": Color(0.85, 0.9, 0.4),
		"mist_color": Color(0.75, 0.85, 0.95),
		"scale": 1.1,
		"top": 1.0,
		"gentle": true,
	},
	# The Garza de légamo, the Ciénaga's boss: a huge muddy heron with the lighthouse's lamp
	# shining in its crop.
	Look.SILT_HERON: {
		"color": Color(0.5, 0.48, 0.44),
		"dark_color": Color(0.3, 0.29, 0.27),
		"leg_color": Color(0.55, 0.45, 0.25),
		"beak_color": Color(0.82, 0.66, 0.3),
		"eye_color": Color(0.95, 0.8, 0.2),
		"lamp_color": Color(1.0, 0.85, 0.45),
		"scale": 0.95,
		"top": 3.5,
		"gentle": true,
	},
	# The Cuevas de cristal (3.1.0): the bat, the slime, the golem and the spider of before
	# with glowing crystals growing on them (MistCreatureBuilder._add_shards()), and a new one,
	# the Topo de geoda.
	# The Murciélago de cristal: violet, its wings beating fast, crystals on its back.
	Look.CRYSTAL_BAT: {
		"color": Color(0.5, 0.36, 0.78),
		"wing_color": Color(0.62, 0.48, 0.95),
		"shard_color": Color(0.75, 0.6, 1.0),
		"shards": [[Vector3(0, 0.28, 0.08), Vector3(-20, 0, 0), 0.9],
			[Vector3(-0.12, 0.22, 0.14), Vector3(-25, 0, 25), 0.7],
			[Vector3(0.12, 0.22, 0.14), Vector3(-25, 0, -25), 0.7]],
		"top": 2.0,
		"fly": 1.1,
		"flap_time": 0.12,
	},
	# The Slime de cristal: crystal blue, with points growing from its top.
	Look.CRYSTAL_SLIME: {
		"color": Color(0.35, 0.62, 0.95),
		"shard_color": Color(0.7, 0.9, 1.0),
		"shards": [[Vector3(0, 0.86, 0.05), Vector3.ZERO, 0.8],
			[Vector3(-0.22, 0.62, 0.18), Vector3(-15, 0, 35), 0.6],
			[Vector3(0.24, 0.58, 0.12), Vector3(-10, 0, -35), 0.55]],
		"scale": 1.05,
		"top": 1.4,
		"crown": false,
	},
	# The Golem de cuarzo: the golem in violet quartz, three crystals on its back.
	Look.QUARTZ_GOLEM: {
		"color": Color(0.62, 0.5, 0.78),
		"dark_color": Color(0.42, 0.33, 0.56),
		"eye_color": Color(0.85, 0.6, 1.0),
		"shard_color": Color(0.82, 0.68, 1.0),
		"shards": [[Vector3(-0.3, 0.98, 0.25), Vector3(-30, 0, 30), 0.9],
			[Vector3(0.05, 1.0, 0.35), Vector3(-40, 0, 0), 1.1],
			[Vector3(0.32, 0.95, 0.22), Vector3(-30, 0, -30), 0.8]],
		"scale": 1.05,
		"top": 2.15,
		"gentle": true,
	},
	# The Araña de cristal: deep blue, crystals on its abdomen.
	Look.CRYSTAL_SPIDER: {
		"color": Color(0.24, 0.42, 0.72),
		"leg_color": Color(0.16, 0.28, 0.5),
		"eye_color": Color(0.6, 0.95, 1.0),
		"shard_color": Color(0.6, 0.85, 1.0),
		"shards": [[Vector3(0, 0.75, 0.38), Vector3(-20, 0, 0), 0.7],
			[Vector3(-0.15, 0.68, 0.48), Vector3(-30, 0, 30), 0.55],
			[Vector3(0.15, 0.68, 0.48), Vector3(-30, 0, -30), 0.55]],
		"scale": 1.15,
		"top": 1.3,
		"gentle": true,
	},
	# The Topo de geoda: a grey-brown mole with a pink snout, big claws and a split geode full
	# of violet crystals on its back.
	Look.GEODE_MOLE: {
		"color": Color(0.42, 0.36, 0.34),
		"dark_color": Color(0.28, 0.24, 0.22),
		"snout_color": Color(0.9, 0.6, 0.62),
		"claw_color": Color(0.85, 0.8, 0.7),
		"shell_color": Color(0.4, 0.4, 0.44),
		"shard_color": Color(0.78, 0.55, 1.0),
		"shards": [[Vector3(0, 0.72, 0.22), Vector3(-10, 0, 0), 0.8],
			[Vector3(-0.15, 0.68, 0.3), Vector3(-25, 0, 30), 0.6],
			[Vector3(0.16, 0.68, 0.14), Vector3(-15, 0, -30), 0.6]],
		"scale": 1.1,
		"top": 1.3,
		"gentle": true,
	},
	# The Coloso de cuarzo, the Cuevas' boss: the golem, huge and violet, a ridge of big
	# crystals on its back. Scale 1.7, not the spec's 1.9: its life bar (top + 0.15) must fit
	# the battle camera.
	Look.QUARTZ_COLOSSUS: {
		"color": Color(0.58, 0.46, 0.74),
		"dark_color": Color(0.38, 0.3, 0.52),
		"eye_color": Color(0.6, 0.95, 1.0),
		"shard_color": Color(0.75, 0.9, 1.0),
		"shards": [[Vector3(-0.32, 0.95, 0.3), Vector3(-35, 0, 35), 1.3],
			[Vector3(-0.1, 1.05, 0.38), Vector3(-45, 0, 10), 1.6],
			[Vector3(0.14, 1.02, 0.36), Vector3(-40, 0, -15), 1.4],
			[Vector3(0.36, 0.92, 0.28), Vector3(-30, 0, -40), 1.1],
			[Vector3(0.55, 1.15, 0.05), Vector3(0, 0, -50), 0.8]],
		"scale": 1.7,
		"top": 3.45,
		"gentle": true,
	},
}
