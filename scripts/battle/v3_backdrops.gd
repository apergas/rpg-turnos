class_name V3Backdrops extends RefCounted
## Constructor: the battle backdrops of the v3's lands (3.0.0: "cienaga"; 3.1.0: "cuevas";
## 3.2.0: "ruinas"), kept apart from BattleStage so it does not grow. BattleStage.build() hands
## them over after the zone's sky, sun, fog and black sun. "cienaga" is olive marsh ground with
## pools of still dark water behind and beside the fighters, the boardwalk under them, dead
## mossy trees, reeds, a fallen log, the meadow's rocks and the dark hills behind. "cuevas" is
## the mine's cave in the Cuevas' colours (their floor and rock), with glowing crystal clusters
## on the walls behind and beside the fighters and a cold light on them from the camera's side
## instead of the hero's lantern.
## "ruinas" is an island of old flagstones floating over the void: its rocky root under
## it, broken columns and blocks behind and beside the fighters, smaller islands far away and
## the sea of mist far below (the zone's haze); the black sun is the zone's.
## Static only, keeps no state.

const CIENAGA := "cienaga"
## The still water of the pools.
const POND := Color(0.04, 0.07, 0.12)
## [centre, radius] of the pools: behind and beside the fighters, never under them.
const CIENAGA_PONDS := [[Vector3(-9, 0, -11), 4.0], [Vector3(8, 0, -15), 5.0],
	[Vector3(-14, 0, -4), 3.0], [Vector3(12, 0, -4), 2.5]]
## [Decor id, position, yaw in degrees, scale] (BattleStage.add_decor_pieces()), out of the
## fighters' ellipse and the camera's way.
const CIENAGA_DECOR := [
	["dead_tree", Vector3(6, 0, -14), 20.0, 1.0],
	["dead_tree", Vector3(11, 0, -9), 140.0, 1.2],
	["dead_tree", Vector3(-13, 0, -17), 70.0, 1.1],
	["dead_tree", Vector3(15, 0, -19), 200.0, 1.0],
	["reeds", Vector3(-4.5, 0, -6), 0.0, 1.0],
	["reeds", Vector3(5, 0, -5), 60.0, 1.0],
	["reeds", Vector3(-7.5, 0, -2), 120.0, 0.9],
	["reeds", Vector3(9, 0, -11), 30.0, 1.1],
	["log", Vector3(6.5, 0, -0.5), 30.0, 1.0],
	["stump_tall", Vector3(-6, 0, 1), 0.0, 1.0],
]
const CUEVAS := "cuevas"
## The crystal clusters ([foot of the wall, out from it, shade]) on the faces of
## BattleStage.CAVE_BLOCKS, behind and beside the fighters.
const CUEVAS_CLUSTERS := [
	[Vector3(-7, 0, -8), Vector3(0, 0, 1), 0], [Vector3(4.5, 0, -9), Vector3(0, 0, 1), 1],
	[Vector3(-8, 0, -3.5), Vector3(1, 0, 0), 1], [Vector3(9, 0, -2.5), Vector3(-1, 0, 0), 0],
]
## The crystals' cold light on the fighters from the camera's side (the Cuevas have no
## lantern).
const CUEVAS_GLOW := Color(0.65, 0.78, 1.0)
const CUEVAS_GLOW_ENERGY := 1.1
const CUEVAS_GLOW_RANGE := 12.0
const CUEVAS_GLOW_POS := Vector3(0.5, 3.0, 3.5)
const RUINAS := "ruinas"
## The fighters' island: a slab (its top at y 0) and how deep its root hangs.
const RUINAS_PLATFORM := Vector3(22, 0.6, 18)
const RUINAS_PLATFORM_CENTER := Vector3(0, -0.3, -2)
const RUINAS_ROOT := 9.0
## The far islands: [the centre of their top, radius], behind and beside the fighters.
const RUINAS_ISLANDS := [
	[Vector3(-17, -2, -22), 4.0], [Vector3(15, -4, -28), 5.5], [Vector3(-3, -7, -40), 7.0],
	[Vector3(27, -1, -12), 3.0], [Vector3(-28, -5, -10), 3.5],
]
## How far below the sea of mist lies.
const RUINAS_VOID_DEPTH := 30.0
## [Decor id, position, yaw in degrees, scale] (BattleStage.add_decor_pieces()): broken columns
## and blocks on the island, out of the fighters' ellipse and the camera's way.
const RUINAS_DECOR := [
	["column_broken", Vector3(-6, 0, -7), 20.0, 1.2],
	["column", Vector3(7, 0, -8.5), 0.0, 1.3],
	["column_broken", Vector3(9, 0, -2), 140.0, 1.0],
	["ruin_block", Vector3(-8, 0, -2), 30.0, 1.0],
	["column", Vector3(-10, 0, -9), 0.0, 1.2],
	["ruin_block", Vector3(4, 0, -9.5), 75.0, 0.9],
]


static func has(backdrop: String) -> bool:
	return backdrop in [CIENAGA, CUEVAS, RUINAS]


static func build(root: Node3D, zone: ZoneData) -> void:
	match zone.backdrop:
		CUEVAS:
			_build_cuevas(root, zone)
		RUINAS:
			_build_ruinas(root, zone)
		_:
			_build_cienaga(root, zone)


static func _build_cienaga(root: Node3D, zone: ZoneData) -> void:
	var ground := PlaneMesh.new()
	ground.size = Vector2(160, 160)
	BattleStage.add_mesh(root, ground, zone.ground_color, Vector3.ZERO)
	for pond: Array in CIENAGA_PONDS:
		BattleStage.add_mesh(root, LowPoly.disc(pond[1]), POND, pond[0] + Vector3(0, 0.01, 0))
	var path := PlaneMesh.new()
	path.size = BattleStage.PATH_SIZE
	BattleStage.add_mesh(root, path, zone.path_color, BattleStage.PATH_CENTER + Vector3(0, 0.012, 0),
		Vector3.ONE, Vector3(0, BattleStage.PATH_YAW_DEG, 0))
	for rock in BattleStage.ROCKS:
		BattleStage.add_model(root, BattleStage.ROCK_SCENES[rock[1]], rock[0], rock[2], rock[3])
	for hill in BattleStage.HILLS:
		BattleStage.add_mesh(root, BattleStage.unit_sphere(), zone.hill_color, hill[0], hill[1])
	BattleStage.add_decor_pieces(root, CIENAGA_DECOR, zone.decor_green)


static func _build_cuevas(root: Node3D, zone: ZoneData) -> void:
	var ground := PlaneMesh.new()
	ground.size = Vector2(60, 60)
	BattleStage.add_mesh(root, ground, zone.floor_color, Vector3.ZERO)
	for block: Array in BattleStage.CAVE_BLOCKS:
		var box := BoxMesh.new()
		box.size = block[1]
		BattleStage.add_mesh(root, box, zone.rock_color, block[0])
	for rock: Array in BattleStage.CAVE_ROCKS:
		BattleStage.add_model(root, BattleStage.ROCK_SCENES[rock[1]], rock[0], rock[2], rock[3])
	for spike: Array in BattleStage.STALAGMITES:
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = spike[1]
		cone.height = spike[2]
		cone.radial_segments = 6
		BattleStage.add_mesh(root, cone, zone.rock_color.lightened(0.15),
			spike[0] + Vector3(0, spike[2] / 2.0, 0))
	for cluster: Array in CUEVAS_CLUSTERS:
		Crystals.add_cluster(root, cluster[0], cluster[1], cluster[2])
	var glow := OmniLight3D.new()
	glow.light_color = CUEVAS_GLOW
	glow.light_energy = CUEVAS_GLOW_ENERGY
	glow.omni_range = CUEVAS_GLOW_RANGE
	glow.position = CUEVAS_GLOW_POS
	root.add_child(glow)


static func _build_ruinas(root: Node3D, zone: ZoneData) -> void:
	var slab := BoxMesh.new()
	slab.size = RUINAS_PLATFORM
	BattleStage.add_mesh(root, slab, zone.floor_color, RUINAS_PLATFORM_CENTER)
	var under := RUINAS_PLATFORM_CENTER + Vector3(0, -RUINAS_PLATFORM.y / 2.0 - RUINAS_ROOT / 2.0, 0)
	BattleStage.add_mesh(root, FloatingIslands.root_mesh(RUINAS_PLATFORM.x / 2.0, RUINAS_ROOT),
		zone.rock_color, under)
	for island: Array in RUINAS_ISLANDS:
		_add_island(root, zone, island[0], island[1])
	var sea := PlaneMesh.new()
	sea.size = Vector2(400, 400)
	BattleStage.add_mesh(root, sea, zone.haze, Vector3(0, -RUINAS_VOID_DEPTH, 0))
	BattleStage.add_decor_pieces(root, RUINAS_DECOR, zone.decor_green)


## A far island: a round slab whose top is at top, and its root under it.
static func _add_island(root: Node3D, zone: ZoneData, top: Vector3, radius: float) -> void:
	BattleStage.add_mesh(root, LowPoly.cylinder(radius, 0.5), zone.floor_color,
		top + Vector3(0, -0.25, 0))
	BattleStage.add_mesh(root, FloatingIslands.root_mesh(radius, radius * 1.2), zone.rock_color,
		top + Vector3(0, -0.5 - radius * 0.6, 0))
