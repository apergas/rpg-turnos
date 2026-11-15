class_name MistCreatureBuilder extends RefCounted
## Constructor: the v3's figures built in code (3.0.0), from their ActorLooksV3 entry, so
## CreatureBuilder does not grow: the variants of older figures (the Sapo de légamo is the
## frog, the Sanguijuela the snake, the Junco andante the plant, in their own colours) and the
## new ones: the Fuego fatuo, the Caimán de bruma and the Garza de légamo. Static only, keeps no
## state: like CreatureBuilder, each build_x(actor, data) hangs its meshes under actor.body()
## through the actor's builder methods. build() says whether the look was one of its own.

const Look = ActorLooks.Look
## Side profile of the Fuego fatuo's flame (lathed around +Y): round below, a tip above.
const FLAME_PROFILE: Array[Vector2] = [
	Vector2(0.0, 0.0), Vector2(0.3, 0.1), Vector2(0.36, 0.35), Vector2(0.26, 0.65),
	Vector2(0.1, 0.95), Vector2(0.0, 1.15),
]
## Opacity of the flame, and of its bright core.
const FLAME_ALPHA := 0.55
const CORE_ALPHA := 0.9
## The opacity of the lamp in the Garza's crop.
const LAMP_ALPHA := 0.9
## The opacity of the crystals growing on the Cuevas' figures (_add_shards()).
const SHARD_ALPHA := 0.8


## Builds the figure of a look of the v3 and returns true; false (nothing built) for any other.
static func build(actor: BattleActor, data: Dictionary) -> bool:
	var look: int = actor.look
	if look == Look.MUD_TOAD:
		CreatureBuilder.build_frog(actor, data)
	elif look == Look.LEECH:
		CreatureBuilder.build_snake(actor, data)
	elif look == Look.WALKING_REED:
		CreatureBuilder.build_plant(actor, data)
	elif look == Look.WISP:
		build_wisp(actor, data)
	elif look == Look.MIST_CAIMAN:
		build_caiman(actor, data)
	elif look == Look.SILT_HERON:
		build_heron(actor, data)
	elif look == Look.CRYSTAL_BAT:
		CreatureBuilder.build_bat(actor, data)
		_add_shards(actor, data)
	elif look == Look.CRYSTAL_SLIME:
		CreatureBuilder.build_slime(actor, data)
		_add_shards(actor, data)
	elif look == Look.QUARTZ_GOLEM:
		CreatureBuilder.build_golem(actor, data)
		_add_shards(actor, data)
	elif look == Look.CRYSTAL_SPIDER:
		CreatureBuilder.build_spider(actor, data)
		_add_shards(actor, data)
	elif look == Look.GEODE_MOLE:
		build_mole(actor, data)
	else:
		return false
	return true


## A will-o'-the-wisp: a see-through blue flame floating over the ground (it floats like the
## specter), a bright core, a soft glow round it and two dark eyes, facing -Z. About 2 m tall.
static func build_wisp(actor: BattleActor, data: Dictionary) -> void:
	var hover := Node3D.new()
	hover.position.y = data.fly
	hover.scale = Vector3.ONE * data.scale
	actor.body().add_child(hover)
	actor.set_hover(hover)
	actor.add_ghost(hover, LowPoly.blob(FLAME_PROFILE, 7), data.color, FLAME_ALPHA, Vector3.ZERO,
		Vector3.ONE)
	actor.add_ghost(hover, LowPoly.sphere(0.2), data.core_color, CORE_ALPHA, Vector3(0, 0.3, 0),
		Vector3.ONE)
	actor.add_ghost(hover, LowPoly.sphere(0.5), data.color, CreatureBuilder.AURA_ALPHA,
		Vector3(0, 0.4, 0), Vector3(1.3, 1.5, 1.3))
	for x in [-0.09, 0.09]:
		actor.add_mesh(hover, LowPoly.sphere(0.05), Color(0.02, 0.03, 0.1), Vector3(x, 0.42, -0.31))


## A mist caiman: a long low body and a long flat snout along -Z, a tail behind, a ridge of
## dark scutes on its back, eye bumps, four splayed legs and a flat ghost of mist round it.
## About 0.7 m tall and 4 m long at its scale.
static func build_caiman(actor: BattleActor, data: Dictionary) -> void:
	var root := Node3D.new()
	root.scale = Vector3.ONE * data.scale
	actor.body().add_child(root)
	actor.add_blob(root, CreatureBuilder.WOLF_BODY_PROFILE, 6, data.color, Vector3(0, 0.32, 0.9),
		Vector3(-90, 0, 0), Vector3(1.5, 1.7, 0.75))  # body, from the tail end to the chest
	actor.add_blob(root, CreatureBuilder.WOLF_HEAD_PROFILE, 5, data.color, Vector3(0, 0.3, -0.95),
		Vector3(-90, 0, 0), Vector3(1.3, 1.9, 0.65))  # the long flat snout
	actor.add_mesh(root, LowPoly.cone(0.22, 1.3), data.color, Vector3(0, 0.26, 1.5))  # tail
	(root.get_child(-1) as Node3D).rotation_degrees.x = 90.0
	for i in 5:  # the ridge of scutes along the back
		actor.add_mesh(root, LowPoly.cone(0.08, 0.2), data.dark_color, Vector3(0, 0.62, 0.7 - i * 0.32))
	for side in [-1.0, 1.0]:
		actor.add_mesh(root, LowPoly.sphere(0.08), data.eye_color, Vector3(side * 0.17, 0.5, -1.0))
		for z in [0.45, -0.55]:
			actor.add_blob(root, CreatureBuilder.LEG_PROFILE, 4, data.dark_color,
				Vector3(side * 0.42, 0.0, z), Vector3(0, 0, side * 50.0), Vector3(1.5, 0.6, 1.5))
	actor.add_ghost(root, LowPoly.sphere(1.0), data.mist_color, CreatureBuilder.AURA_ALPHA,
		Vector3(0, 0.15, 0.1), Vector3(1.3, 0.35, 2.3))  # the mist it drags


## The Garza de légamo, the Ciénaga's boss: a huge heron on two long thin legs, a muddy body
## leaning forward with folded wings, the lamp of the lighthouse shining in its crop, an S of a
## neck, a small head with a crest and a long yellow beak, facing -Z. About 3.3 m tall at its
## scale.
static func build_heron(actor: BattleActor, data: Dictionary) -> void:
	var root := Node3D.new()
	root.scale = Vector3.ONE * data.scale
	actor.body().add_child(root)
	for x in [-0.2, 0.2]:
		actor.add_mesh(root, LowPoly.cylinder(0.05, 1.6), data.leg_color, Vector3(x, 0.8, 0.1))  # leg
		actor.add_mesh(root, LowPoly.cone(0.16, 0.06), data.leg_color, Vector3(x, 0.03, -0.05))  # foot
	actor.add_blob(root, CreatureBuilder.SLIME_PROFILE, 9, data.color, Vector3(0, 1.45, 0.25),
		Vector3(-75, 0, 0), Vector3(0.9, 1.2, 0.8))  # body, leaning forward
	actor.add_ghost(root, LowPoly.sphere(0.24), data.lamp_color, LAMP_ALPHA, Vector3(0, 1.6, -0.7),
		Vector3.ONE)  # the lamp in its crop
	for side in [-1.0, 1.0]:
		actor.add_blob(root, CreatureBuilder.SPECTER_PROFILE, 6, data.dark_color,
			Vector3(side * 0.42, 1.55, 0.35), Vector3(-100, 0, 0), Vector3(0.25, 1.3, 0.9))  # folded wing
	var segments := 7
	for i in segments:  # the neck: shrinking balls in an S, rising from the chest
		var t := float(i) / (segments - 1)
		actor.add_mesh(root, LowPoly.sphere(0.15 - t * 0.05), data.color,
			Vector3(0, 1.85 + t * 1.15, -0.85 + 0.25 * sin(t * PI) - 0.15 * t))
	actor.add_mesh(root, LowPoly.sphere(0.16), data.color, Vector3(0, 3.05, -1.05))  # head
	for x in [-0.09, 0.09]:
		actor.add_mesh(root, LowPoly.sphere(0.035), data.eye_color, Vector3(x, 3.1, -1.13))
	actor.add_mesh(root, LowPoly.cone(0.06, 0.8), data.beak_color, Vector3(0, 3.0, -1.5))  # beak
	(root.get_child(-1) as Node3D).rotation_degrees.x = -90.0
	actor.add_mesh(root, LowPoly.cone(0.03, 0.35), data.dark_color, Vector3(0, 3.25, -0.95))  # crest
	(root.get_child(-1) as Node3D).rotation_degrees.x = 30.0



## Glowing crystal points on the figure just built (its root: the last child of actor.body()):
## each [position, rotation in degrees, size] of data.shards, in data.shard_color,
## see-through and glowing like the Cuevas' walls (Crystals' mesh).
static func _add_shards(actor: BattleActor, data: Dictionary) -> void:
	var root := actor.body().get_child(actor.body().get_child_count() - 1) as Node3D
	for shard: Array in data.shards:
		actor.add_ghost(root, Crystals.mesh(), data.shard_color, SHARD_ALPHA, shard[0],
			Vector3.ONE * float(shard[2]))
		(root.get_child(-1) as Node3D).rotation_degrees = shard[1]


## A geode mole: a round grey-brown body low to the ground, a pink pointed snout along -Z, two
## tiny dark eyes, two big pale front claws, short back feet and, on its back, a grey geode
## split open with violet crystals in it. About 1.1 m tall at its scale.
static func build_mole(actor: BattleActor, data: Dictionary) -> void:
	var root := Node3D.new()
	root.scale = Vector3.ONE * data.scale
	actor.body().add_child(root)
	actor.add_blob(root, CreatureBuilder.SLIME_PROFILE, 8, data.color, Vector3(0, 0.02, 0.05),
		Vector3.ZERO, Vector3(1.05, 0.8, 1.3))  # body
	actor.add_mesh(root, LowPoly.cone(0.12, 0.34), data.snout_color, Vector3(0, 0.34, -0.72))
	(root.get_child(-1) as Node3D).rotation_degrees.x = -90.0  # snout
	for side in [-1.0, 1.0]:
		actor.add_mesh(root, LowPoly.sphere(0.035), Color(0.04, 0.03, 0.03),
			Vector3(side * 0.14, 0.5, -0.56))  # eye
		for k in 3:  # the front claws, three a side, reaching forward
			actor.add_mesh(root, LowPoly.cone(0.04, 0.22), data.claw_color,
				Vector3(side * (0.36 + k * 0.06), 0.1, -0.55))
			(root.get_child(-1) as Node3D).rotation_degrees.x = -70.0
		actor.add_mesh(root, LowPoly.sphere(0.1), data.dark_color,
			Vector3(side * 0.34, 0.06, 0.48))  # back foot
	actor.add_mesh(root, LowPoly.hemisphere(0.36, 0.5), data.shell_color,
		Vector3(0, 0.6, 0.22))  # the geode on its back
	_add_shards(actor, data)
