class_name V3Backdrops extends RefCounted
## Constructor: the battle backdrops of the v3's lands (3.0.0: "cienaga"; 3.1.0: "cuevas"), kept
## apart from BattleStage so it does not grow. BattleStage.build() hands them over after the zone's
## sky, sun, fog and black sun. "cienaga" is olive marsh ground with pools of still dark water
## behind and beside the fighters, the boardwalk under them, dead mossy trees, reeds, a fallen
## log, the meadow's rocks and the dark hills behind. "cuevas" is the mine's cave in the Cuevas'
## colours (their floor and rock), with glowing crystal clusters on the walls behind and beside
## the fighters and a cold light on them from the camera's side instead of the hero's lantern.
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


static func has(backdrop: String) -> bool:
	return backdrop in [CIENAGA, CUEVAS]


static func build(root: Node3D, zone: ZoneData) -> void:
	if zone.backdrop == CUEVAS:
		_build_cuevas(root, zone)
	else:
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
