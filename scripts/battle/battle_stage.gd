class_name BattleStage extends RefCounted
## Builds the battle backdrop of a zone (ZoneData.backdrop): sky, sun and fog of the
## zone, grass field with tall grass (Vegetation) around the fighters, dirt path,
## low-poly rocks, trees and bushes, and distant hills. "pradera" is the open meadow;
## "bosque" closes a ring of trees around the fighters on darker ground; "mina" is a
## cave: rock floor, a wall of rock blocks and boulders behind and beside the fighters,
## stalagmites and two torches, in the dark of an underground zone. "castillo" is a
## castle yard: flagstones, KayKit wall pieces with towers behind and beside the
## fighters, banks of mist and two torches (and the hero's lantern indoors). "desierto" is
## sand with a darker track, palms far behind, dunes and the Kenney cacti, scrub and a
## broken column. "montana" is snow with a grey track, white peaks and the Kenney pines, tall
## stones and snowy cliffs. The environment, the mesh and model helpers and the rock and tree models
## are shared with WorldStage.

const GRASS := Color(0.32, 0.55, 0.22)
const DIRT := Color(0.62, 0.5, 0.34)
const HILL := Color(0.27, 0.47, 0.22)

## KayKit Medieval Hexagon rocks A to E (index used by the ROCKS tables).
const ROCK_SCENES: Array[PackedScene] = [
	preload("res://assets/medieval/rock_single_A.gltf"),
	preload("res://assets/medieval/rock_single_B.gltf"),
	preload("res://assets/medieval/rock_single_C.gltf"),
	preload("res://assets/medieval/rock_single_D.gltf"),
	preload("res://assets/medieval/rock_single_E.gltf"),
]
## Half the widest side of each rock model at scale 1 (measured AABBs), in metres.
const ROCK_RADII: Array[float] = [0.15, 0.145, 0.175, 0.145, 0.245]
## Single tree A, single tree B, clump of trees A and clump of trees B (index used by the
## TREES tables; the clump B, index 3, only by FOREST_TREES).
const FOREST_TREE_SCENES: Array[PackedScene] = [
	preload("res://assets/medieval/tree_single_A.gltf"),
	preload("res://assets/medieval/tree_single_B.gltf"),
	preload("res://assets/medieval/trees_A_medium.gltf"),
	preload("res://assets/medieval/trees_B_medium.gltf"),
]
## [position, rock model, scale, yaw in degrees] of each rock.
const ROCKS := [
	[Vector3(-5.5, 0, -6.0), 2, 7.0, 30.0],
	[Vector3(4.5, 0, -8.0), 4, 8.0, 110.0],
	[Vector3(6.5, 0, -2.5), 1, 5.0, 200.0],
	[Vector3(-7.0, 0, -12.0), 4, 10.0, 250.0],
	[Vector3(2.5, 0, -4.5), 0, 4.0, 80.0],
]
## [position, tree model, scale, yaw in degrees] of each tree, behind the fighters.
const TREES := [
	[Vector3(-10, 0, -15), 0, 4.0, 20.0],
	[Vector3(-14, 0, -7), 1, 4.2, 70.0],
	[Vector3(11, 0, -17), 2, 4.0, 0.0],
	[Vector3(15, 0, -8), 0, 3.8, 140.0],
	[Vector3(-4, 0, -21), 2, 4.5, 200.0],
	[Vector3(4, 0, -24), 1, 4.4, 300.0],
	[Vector3(-18, 0, -18), 2, 4.0, 90.0],
]
## [position, scale] of each bush.
const BUSHES := [
	[Vector3(-4.5, 0, -3.5), 0.9],
	[Vector3(5.0, 0, -5.5), 0.8],
	[Vector3(-8.5, 0, -9.0), 1.1],
	[Vector3(8.5, 0, -11.0), 1.0],
	[Vector3(1.0, 0, -12.5), 0.9],
	[Vector3(-6.0, 0, 1.0), 0.8],
]
## [position, scale] of each hill (unit spheres, half buried).
const HILLS := [
	[Vector3(-26, -4, -48), Vector3(22, 9, 22)],
	[Vector3(18, -5, -55), Vector3(28, 10, 20)],
	[Vector3(48, -6, -25), Vector3(20, 8, 20)],
	[Vector3(-50, -5, -15), Vector3(20, 8, 24)],
]
## Tall grass around the fighters; none in the ellipse where they stand and the camera
## looks, on the path strip or in the rocks. Nobody walks here, so it is never pushed.
const GRASS_AREA := Rect2(-20, -24, 40, 34)
const GRASS_SEED := 11
const CLEAR_CENTER := Vector2(0.0, -0.3)
const CLEAR_RADII := Vector2(4.0, 5.5)
## The path plane: centre, size and yaw as built in build(), plus the grass margin.
const PATH_CENTER := Vector3(-0.2, 0.0, -0.3)
const PATH_SIZE := Vector2(2.6, 30.0)
const PATH_YAW_DEG := -21.0
const GRASS_MARGIN := 0.3
## The forest backdrop: ground, grass tips and the ring of trees (same entries as TREES)
## that stands close behind and beside the fighters, out of the camera's way.
const FOREST_GROUND := Color(0.2, 0.38, 0.14)
const FOREST_TIPS := [Color(0.16, 0.42, 0.1), Color(0.3, 0.55, 0.14)]
const FOREST_TREES := [
	[Vector3(-7.5, 0, -6), 0, 4.2, 20.0],
	[Vector3(-9, 0, -1), 1, 4.0, 70.0],
	[Vector3(7.5, 0, -7), 1, 4.4, 160.0],
	[Vector3(9.5, 0, -1.5), 0, 3.9, 240.0],
	[Vector3(-4, 0, -11), 2, 4.6, 200.0],
	[Vector3(3.5, 0, -12), 3, 4.4, 300.0],
	[Vector3(-11, 0, -10), 3, 4.2, 90.0],
	[Vector3(11, 0, -11), 2, 4.0, 10.0],
	[Vector3(-1, 0, -17), 3, 4.8, 130.0],
	[Vector3(-13, 0, 3), 2, 4.0, 45.0],
	[Vector3(13, 0, 3.5), 3, 4.0, 280.0],
]

## The jungle backdrop: dark wet ground, tall bright grass and the same close ring of trees
## as palms (PalmModels, the map's), scaled by the jungle's tree_scale over the forest's
## (about 1.0 / 2.9, since a KayKit tree is a third of a palm's size in the table above),
## with the bushes doubled.
const JUNGLE_GROUND := Color(0.12, 0.24, 0.07)
const JUNGLE_TIPS := [Color(0.1, 0.45, 0.08), Color(0.26, 0.6, 0.12)]
const JUNGLE_PALM_RATIO := 0.354
const JUNGLE_PALMS := ["palm_A", "palm_B"]

## The desert backdrop: sand, a darker trodden track, the rocks, two palms and a clump far
## behind (PalmModels, the map's), dunes for hills and the Kenney cacti, scrub and a broken
## column of BACKDROP_DECOR; no tall grass and no bushes.
const DESERT_GROUND := Color(0.56, 0.44, 0.28)
const DESERT_PATH := Color(0.42, 0.32, 0.2)
const DESERT_HILL := Color(0.58, 0.45, 0.29)
## [position, PalmModels id, scale, yaw in degrees].
const DESERT_PALMS := [
	[Vector3(-11, 0, -16), "palm_A", 1.4, 20.0],
	[Vector3(12, 0, -19), "palm_B", 1.45, 200.0],
	[Vector3(-17, 0, -10), "palms_clump", 1.4, 90.0],
]


## The mountain backdrop: snow, a trodden track of grey stone, the KayKit rocks, white peaks
## for hills, and the Kenney pines, tall stones and snowy cliffs (the map's rock block) of
## BACKDROP_DECOR; no tall grass and no bushes.
const MOUNTAIN_GROUND := Color(0.8, 0.83, 0.88)
const MOUNTAIN_PATH := Color(0.5, 0.51, 0.54)
const MOUNTAIN_HILL := Color(0.84, 0.87, 0.92)

## The mine backdrop: rock floor, the blocks of the cave wall ([position, size]), the
## boulders (same entries as ROCKS), the stalagmites ([position, radius, height]) and
## the two torches ([position of the flame]).
const CAVE_FLOOR := Color(0.27, 0.24, 0.22)
const CAVE_ROCK := Color(0.33, 0.29, 0.26)
const CAVE_BLOCKS := [
	[Vector3(-8, 2, -10), Vector3(6, 4, 4)], [Vector3(-2, 2.5, -12), Vector3(6, 5, 4)],
	[Vector3(4, 2, -11), Vector3(6, 4, 4)], [Vector3(10, 2.5, -9), Vector3(6, 5, 4)],
	[Vector3(-10, 2, -4), Vector3(4, 4, 6)], [Vector3(11, 2, -3), Vector3(4, 4, 6)],
	[Vector3(-11, 2, 3), Vector3(4, 4, 6)], [Vector3(12, 2, 4), Vector3(4, 4, 6)],
	[Vector3(0, 4.5, -16), Vector3(30, 9, 4)],
]
const CAVE_ROCKS := [
	[Vector3(-6.0, 0, -7.0), 2, 9.0, 30.0],
	[Vector3(6.5, 0, -6.5), 4, 8.0, 110.0],
	[Vector3(-7.5, 0, 0.5), 1, 7.0, 200.0],
	[Vector3(8.0, 0, 1.0), 0, 8.0, 80.0],
]
const STALAGMITES := [
	[Vector3(-4.5, 0, -5.5), 0.35, 1.6], [Vector3(4.0, 0, -7.5), 0.45, 2.2],
	[Vector3(-3.0, 0, -8.5), 0.3, 1.2], [Vector3(5.5, 0, -2.5), 0.3, 1.1],
	[Vector3(-5.5, 0, 2.5), 0.25, 0.9],
]
const CAVE_TORCHES := [Vector3(-3.5, 2.4, -9.8), Vector3(5.0, 2.4, -8.8)]
## The castle backdrop: flagstones, the wall pieces ([position, yaw]) at
## DungeonMap.WALL_SCALE, the towers ([position, height]), the mist banks ([position,
## scale]) and the two torches on the back wall.
const CASTLE_FLOOR := Color(0.42, 0.41, 0.44)
const CASTLE_STONE := Color(0.5, 0.49, 0.53)
const CASTLE_WALLS := [
	[Vector3(-10, 0, -11), 0.0], [Vector3(-6, 0, -11), 0.0], [Vector3(-2, 0, -11), 0.0],
	[Vector3(2, 0, -11), 0.0], [Vector3(6, 0, -11), 0.0], [Vector3(10, 0, -11), 0.0],
	[Vector3(-12, 0, -7), 90.0], [Vector3(-12, 0, -3), 90.0], [Vector3(-12, 0, 1), 90.0],
	[Vector3(13, 0, -7), 90.0], [Vector3(13, 0, -3), 90.0], [Vector3(13, 0, 1), 90.0],
]
const CASTLE_TOWERS := [
	[Vector3(-14, 0, -11), 5.0], [Vector3(14, 0, -11), 5.0], [Vector3(0, 0, -16), 9.0],
]
const CASTLE_MIST := [
	[Vector3(-6, 0.3, -6), Vector3(5, 0.5, 3)], [Vector3(6, 0.3, -7), Vector3(6, 0.5, 3)],
	[Vector3(-8, 0.3, 1), Vector3(4, 0.5, 4)], [Vector3(9, 0.3, 0), Vector3(4, 0.5, 4)],
]
const LOW_SHADOW_DISTANCE := 35.0
const CASTLE_TORCHES := [Vector3(-4.0, 2.0, -10.0), Vector3(4.0, 2.0, -10.0)]

## Low graphics quality: no SSAO and cheap, short sun shadows (DisplaySettings sets it). The
## shadows stay on: under Compatibility a sun without them lights everything darker and greyer.
static var plain_light := false


## The Kenney pieces of each battle backdrop: [Decor id, position, yaw_deg, scale], out of
## the cleared ground where the fighters stand (CLEAR_CENTER, CLEAR_RADII) and in sight.
const BACKDROP_DECOR := {
	"pradera": [["flowers", Vector3(-3.7, 0, -3.4), 20.0, 1.7],
		["flowers", Vector3(4.3, 0, -2.4), 140.0, 1.8],
		["flowers", Vector3(-4.2, 0, 0.8), 260.0, 1.5]],
	"bosque": [["mushrooms_red", Vector3(-3.7, 0, -3.4), 0.0, 1.5],
		["mushrooms_red", Vector3(4.3, 0, -1.2), 90.0, 1.4],
		["log", Vector3(-5.3, 0, -3.6), 100.0, 0.6]],
	"jungla": [["fern", Vector3(-3.7, 0, -3.4), 0.0, 1.8],
		["fern", Vector3(4.2, 0, -2.4), 70.0, 1.6],
		["fern", Vector3(-4.2, 0, 0.8), 150.0, 1.5],
		["mushrooms_red", Vector3(4.6, 0, 1.6), 200.0, 1.4]],
	"desierto": [["cactus_tall", Vector3(-4.2, 0, -3.6), 20.0, 1.0],
		["cactus", Vector3(4.4, 0, -2.2), 140.0, 1.0],
		["cactus", Vector3(-4.6, 0, 0.9), 260.0, 0.8],
		["scrub", Vector3(4.4, 0, 1.6), 0.0, 1.0],
		["column_broken", Vector3(5.6, 0, -6.5), 15.0, 1.0]],
	"montana": [["pine", Vector3(-7.5, 0, -6), 20.0, 1.0],
		["pine", Vector3(7.5, 0, -7), 160.0, 1.1],
		["pine_small", Vector3(-9, 0, -1), 70.0, 1.0],
		["pine_small", Vector3(9.5, 0, -1.5), 240.0, 1.0],
		["pine", Vector3(-4, 0, -11), 200.0, 1.2],
		["pine", Vector3(3.5, 0, -12), 300.0, 1.1],
		["rock_tall", Vector3(4.4, 0, -2.6), 140.0, 0.9],
		["snow_stones", Vector3(-4.2, 0, 0.8), 0.0, 1.0],
		["snow_rock", Vector3(-12, 2.5, -16), 0.0, 5.0],
		["snow_rock", Vector3(-7, 2.0, -18), 0.0, 4.0],
		["snow_rock", Vector3(10, 2.5, -17), 0.0, 5.0],
		["snow_rock", Vector3(15, 2.0, -12), 0.0, 4.0]],
}

## zone: whose sky, light and backdrop to use (null: the meadow's).
static func build(root: Node3D, zone: ZoneData = null) -> void:
	build_environment(root, zone)
	if zone != null and zone.backdrop == "mina":
		_build_cave(root)
		return
	if zone != null and zone.backdrop == "castillo":
		_build_castle(root, zone)
		return
	if zone != null and zone.backdrop == "desierto":
		_build_desert(root, zone)
		return
	if zone != null and zone.backdrop == "montana":
		_build_mountain(root, zone)
		return
	var jungle := zone != null and zone.backdrop == "jungla"
	var forest := jungle or (zone != null and zone.backdrop == "bosque")
	var ground := PlaneMesh.new()
	ground.size = Vector2(160, 160)
	add_mesh(root, ground, JUNGLE_GROUND if jungle else (FOREST_GROUND if forest else GRASS),
		Vector3.ZERO)
	var path := PlaneMesh.new()
	path.size = PATH_SIZE
	add_mesh(root, path, DIRT, PATH_CENTER + Vector3(0, 0.01, 0), Vector3.ONE,
		Vector3(0, PATH_YAW_DEG, 0))
	for rock in ROCKS:
		add_model(root, ROCK_SCENES[rock[1]], rock[0], rock[2], rock[3])
	if jungle:
		_add_jungle_palms(root)
	else:
		for tree in FOREST_TREES if forest else TREES:
			add_model(root, FOREST_TREE_SCENES[tree[1]], tree[0], tree[2], tree[3])
	var bushes: Array[Transform3D] = []
	for i in BUSHES.size():
		bushes.append(Transform3D(Basis(Vector3.UP, i * 0.8).scaled(Vector3.ONE * BUSHES[i][1]),
			BUSHES[i][0]))
	if jungle:
		for i in BUSHES.size():
			bushes.append(Transform3D(Basis(Vector3.UP, i * 0.8 + PI).scaled(
				Vector3.ONE * BUSHES[i][1] * 1.3), BUSHES[i][0] + Vector3(0.9, 0, 0.7)))
	LowPoly.add_multimesh(root, LowPoly.bush_mesh(), bushes)
	for hill in HILLS:
		add_mesh(root, unit_sphere(), HILL, hill[0], hill[1])
	Vegetation.build(root, GRASS_AREA, _is_grass_free, GRASS_SEED,
		PackedColorArray(JUNGLE_TIPS if jungle else FOREST_TIPS) if forest else PackedColorArray())
	_add_backdrop_decor(root, zone)


## The Kenney pieces of BACKDROP_DECOR for this backdrop, merged into one mesh, no collision.
static func _add_backdrop_decor(root: Node3D, zone: ZoneData) -> void:
	var backdrop := zone.backdrop if zone != null else "pradera"
	var green := zone.decor_green if zone != null else NatureModels.MEADOW_GREEN
	var items := []
	for piece: Array in BACKDROP_DECOR.get(backdrop, []):
		items.append({"id": piece[0], "xform": Transform3D(
			Basis(Vector3.UP, deg_to_rad(piece[2])).scaled(Vector3.ONE * piece[3]), piece[1])})
	if items.is_empty():
		return
	var instance := MeshInstance3D.new()
	instance.mesh = NatureModels.merged(items, green)
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 1.0
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	instance.mesh.surface_set_material(0, material)
	root.add_child(instance)


## The jungle's ring of trees: the forest's entries as palms.
static func _add_jungle_palms(root: Node3D) -> void:
	for i in FOREST_TREES.size():
		var tree: Array = FOREST_TREES[i]
		var palm := MeshInstance3D.new()
		palm.mesh = PalmModels.mesh(JUNGLE_PALMS[i % JUNGLE_PALMS.size()])
		palm.position = tree[0]
		palm.scale = Vector3.ONE * tree[2] * JUNGLE_PALM_RATIO
		palm.rotation_degrees = Vector3(0, tree[3], 0)
		root.add_child(palm)


## Sky, tonemap, fog and sun of zone (null: the meadow's warm daylight), shared by the
## map and its battles.
static func build_environment(root: Node3D, zone: ZoneData = null) -> void:
	if zone == null:
		zone = ZoneData.new()
	_add_environment(root, zone)
	_add_sun(root, zone)


static func add_mesh(root: Node3D, mesh: Mesh, color: Color, pos: Vector3, \
		scl := Vector3.ONE, rot_deg := Vector3.ZERO) -> MeshInstance3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 1.0
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.scale = scl
	mi.rotation_degrees = rot_deg
	root.add_child(mi)
	return mi


## An imported model (its own materials) standing at pos, scaled evenly and turned
## yaw_deg around Y.
static func add_model(root: Node3D, scene: PackedScene, pos: Vector3, scl: float, \
		yaw_deg := 0.0) -> Node3D:
	var model: Node3D = scene.instantiate()
	model.position = pos
	model.scale = Vector3.ONE * scl
	model.rotation_degrees = Vector3(0, yaw_deg, 0)
	root.add_child(model)
	return model


## The mesh of a single-mesh model (the Medieval Hexagon ones), for MultiMeshes.
static func scene_mesh(scene: PackedScene) -> Mesh:
	var model := scene.instantiate()
	var mesh := (model.get_child(0) as MeshInstance3D).mesh
	model.free()
	return mesh


## Bounds of a single-mesh model at scale 1, in its own axes.
static func model_aabb(model: Node3D) -> AABB:
	return (model.get_child(0) as MeshInstance3D).get_aabb()


## Footprint radius of a [position, rock model, scale, yaw] entry.
static func rock_radius(rock: Array) -> float:
	return ROCK_RADII[rock[1]] * rock[2]


static func unit_sphere() -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	return mesh


static func _build_mountain(root: Node3D, zone: ZoneData) -> void:
	var ground := PlaneMesh.new()
	ground.size = Vector2(160, 160)
	add_mesh(root, ground, MOUNTAIN_GROUND, Vector3.ZERO)
	var path := PlaneMesh.new()
	path.size = PATH_SIZE
	add_mesh(root, path, MOUNTAIN_PATH, PATH_CENTER + Vector3(0, 0.01, 0), Vector3.ONE,
		Vector3(0, PATH_YAW_DEG, 0))
	for rock in ROCKS:
		add_model(root, ROCK_SCENES[rock[1]], rock[0], rock[2], rock[3])
	for hill in HILLS:
		add_mesh(root, unit_sphere(), MOUNTAIN_HILL, hill[0], hill[1])
	_add_backdrop_decor(root, zone)


static func _build_desert(root: Node3D, zone: ZoneData) -> void:
	var ground := PlaneMesh.new()
	ground.size = Vector2(160, 160)
	add_mesh(root, ground, DESERT_GROUND, Vector3.ZERO)
	var path := PlaneMesh.new()
	path.size = PATH_SIZE
	add_mesh(root, path, DESERT_PATH, PATH_CENTER + Vector3(0, 0.01, 0), Vector3.ONE,
		Vector3(0, PATH_YAW_DEG, 0))
	for rock in ROCKS:
		add_model(root, ROCK_SCENES[rock[1]], rock[0], rock[2], rock[3])
	for palm: Array in DESERT_PALMS:
		var instance := MeshInstance3D.new()
		instance.mesh = PalmModels.mesh(palm[1])
		instance.position = palm[0]
		instance.scale = Vector3.ONE * float(palm[2])
		instance.rotation_degrees = Vector3(0, palm[3], 0)
		root.add_child(instance)
	for hill in HILLS:
		add_mesh(root, unit_sphere(), DESERT_HILL, hill[0], hill[1])
	_add_backdrop_decor(root, zone)


static func _build_cave(root: Node3D) -> void:
	var ground := PlaneMesh.new()
	ground.size = Vector2(60, 60)
	add_mesh(root, ground, CAVE_FLOOR, Vector3.ZERO)
	for block in CAVE_BLOCKS:
		var box := BoxMesh.new()
		box.size = block[1]
		add_mesh(root, box, CAVE_ROCK, block[0])
	for rock in CAVE_ROCKS:
		add_model(root, ROCK_SCENES[rock[1]], rock[0], rock[2], rock[3])
	for spike in STALAGMITES:
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = spike[1]
		cone.height = spike[2]
		cone.radial_segments = 6
		add_mesh(root, cone, CAVE_ROCK.lightened(0.1), spike[0] + Vector3(0, spike[2] / 2.0, 0))
	for flame_pos in CAVE_TORCHES:
		_add_torch(root, flame_pos)
	_add_lantern(root)


static func _build_castle(root: Node3D, zone: ZoneData) -> void:
	var ground := PlaneMesh.new()
	ground.size = Vector2(80, 80)
	add_mesh(root, ground, CASTLE_FLOOR, Vector3.ZERO)
	for wall in CASTLE_WALLS:
		add_model(root, DungeonMap.WALL_SCENE, wall[0], DungeonMap.WALL_SCALE, wall[1])
	for tower in CASTLE_TOWERS:
		var box := BoxMesh.new()
		box.size = Vector3(4, tower[1], 4)
		add_mesh(root, box, CASTLE_STONE, tower[0] + Vector3(0, tower[1] / 2.0, 0))
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = DungeonMap.MIST_COLOR
	for bank in CASTLE_MIST:
		var mist := MeshInstance3D.new()
		mist.mesh = unit_sphere()
		mist.material_override = mat
		mist.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mist.position = bank[0]
		mist.scale = bank[1]
		root.add_child(mist)
	for flame_pos in CASTLE_TORCHES:
		_add_torch(root, flame_pos)
	if zone.underground:
		_add_lantern(root)


## A torch: a stick, an unshaded flame at flame_pos and its warm light a metre out.
static func _add_torch(root: Node3D, flame_pos: Vector3) -> void:
	var stick := BoxMesh.new()
	stick.size = Vector3(0.1, 0.5, 0.1)
	add_mesh(root, stick, DungeonMap.WOOD, flame_pos - Vector3(0, 0.3, 0))
	add_flame(root, flame_pos)


## A torch's flame (unshaded) at flame_pos, size times as big, and, with light, its light at
## light_offset from it.
static func add_flame(root: Node3D, flame_pos: Vector3, size := 1.0,
		light_offset := Vector3(0, 0.2, 1.0), light := true) -> void:
	var flame := MeshInstance3D.new()
	flame.mesh = unit_sphere()
	flame.scale = Vector3(0.13, 0.2, 0.13) * size
	flame.position = flame_pos
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = DungeonMap.FLAME_COLOR
	flame.material_override = mat
	root.add_child(flame)
	if not light:
		return
	var lamp := OmniLight3D.new()
	lamp.light_color = DungeonMap.TORCH_COLOR
	lamp.light_energy = DungeonMap.TORCH_ENERGY
	lamp.omni_range = 10.0
	lamp.position = flame_pos + light_offset
	root.add_child(lamp)


## The fighters' own light, from the camera's side (the hero's lantern).
static func _add_lantern(root: Node3D) -> void:
	var lantern := OmniLight3D.new()
	lantern.light_color = Color(1.0, 0.85, 0.65)
	lantern.light_energy = 1.2
	lantern.omni_range = 12.0
	lantern.position = Vector3(0.5, 3.0, 3.5)
	root.add_child(lantern)


static func _is_grass_free(pos: Vector3) -> bool:
	var p := Vector2(pos.x, pos.z)
	if ((p - CLEAR_CENTER) / CLEAR_RADII).length_squared() < 1.0:
		return false
	# Into the path plane's own axes (it is turned PATH_YAW_DEG around Y).
	var local := (pos - PATH_CENTER).rotated(Vector3.UP, -deg_to_rad(PATH_YAW_DEG))
	if absf(local.x) < PATH_SIZE.x / 2.0 + GRASS_MARGIN \
			and absf(local.z) < PATH_SIZE.y / 2.0 + GRASS_MARGIN:
		return false
	for rock in ROCKS:
		if p.distance_to(Vector2(rock[0].x, rock[0].z)) < rock_radius(rock) + GRASS_MARGIN:
			return false
	return true


static func _add_environment(root: Node3D, zone: ZoneData) -> void:
	if zone.underground:
		_add_dark_environment(root, zone)
		return
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = zone.sky_top
	sky_material.sky_horizon_color = zone.haze
	sky_material.ground_horizon_color = zone.haze
	sky_material.ground_bottom_color = Color(0.3, 0.4, 0.3)
	var sky := Sky.new()
	sky.sky_material = sky_material
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	# Linear, not ACES: under the Compatibility renderer ACES lifts the midtones and clips
	# anything bright in the sun, so skin, hair and steel all turned white and trees mint.
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.ssao_enabled = not plain_light
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.fog_enabled = true
	env.fog_light_color = zone.haze
	env.fog_density = zone.fog_density
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	root.add_child(world_env)


## Underground: a black background, a flat dim ambient light and dark fog; no sky.
static func _add_dark_environment(root: Node3D, zone: ZoneData) -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.BLACK
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = zone.ambient_color
	env.ambient_light_energy = zone.ambient_energy
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = true
	env.glow_intensity = 0.8
	env.fog_enabled = true
	env.fog_light_color = zone.haze
	env.fog_density = zone.fog_density
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	root.add_child(world_env)


static func _add_sun(root: Node3D, zone: ZoneData) -> void:
	if zone.underground:
		return
	var sun := DirectionalLight3D.new()
	sun.light_color = zone.sun_color
	# Tuned for the Compatibility renderer (needed for the web build); 1.3 looked
	# right under Forward+ but washes everything out here. The meadow uses 0.6.
	sun.light_energy = zone.sun_energy
	sun.shadow_enabled = true
	if plain_light:
		sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
		sun.directional_shadow_max_distance = LOW_SHADOW_DISTANCE
	sun.rotation_degrees = Vector3(-40, 35, 0)
	root.add_child(sun)
