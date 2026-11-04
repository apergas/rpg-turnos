class_name BattleStage extends RefCounted
## Builds the battle backdrop of a zone (ZoneData.backdrop): sky, sun and fog of the
## zone, grass field with tall grass (Vegetation) around the fighters, dirt path,
## low-poly rocks, trees and bushes, and distant hills. "pradera" is the open meadow;
## "bosque" closes a ring of trees around the fighters on darker ground. The environment,
## the mesh and model helpers and the rock and tree models are shared with WorldStage.

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
## Single tree A, single tree B and a clump of trees (index used by the TREES tables).
const TREE_SCENES: Array[PackedScene] = [
	preload("res://assets/medieval/tree_single_A.gltf"),
	preload("res://assets/medieval/tree_single_B.gltf"),
	preload("res://assets/medieval/trees_A_medium.gltf"),
]
## TREE_SCENES plus the forest's clump of trees B (index 3, FOREST_TREES only).
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


## zone: whose sky, light and backdrop to use (null: the meadow's).
static func build(root: Node3D, zone: ZoneData = null) -> void:
	build_environment(root, zone)
	var forest := zone != null and zone.backdrop == "bosque"
	var ground := PlaneMesh.new()
	ground.size = Vector2(160, 160)
	add_mesh(root, ground, FOREST_GROUND if forest else GRASS, Vector3.ZERO)
	var path := PlaneMesh.new()
	path.size = PATH_SIZE
	add_mesh(root, path, DIRT, PATH_CENTER + Vector3(0, 0.01, 0), Vector3.ONE,
		Vector3(0, PATH_YAW_DEG, 0))
	for rock in ROCKS:
		add_model(root, ROCK_SCENES[rock[1]], rock[0], rock[2], rock[3])
	for tree in FOREST_TREES if forest else TREES:
		add_model(root, FOREST_TREE_SCENES[tree[1]], tree[0], tree[2], tree[3])
	var bushes: Array[Transform3D] = []
	for i in BUSHES.size():
		bushes.append(Transform3D(Basis(Vector3.UP, i * 0.8).scaled(Vector3.ONE * BUSHES[i][1]),
			BUSHES[i][0]))
	LowPoly.add_multimesh(root, LowPoly.bush_mesh(), bushes)
	for hill in HILLS:
		add_mesh(root, unit_sphere(), HILL, hill[0], hill[1])
	Vegetation.build(root, GRASS_AREA, _is_grass_free, GRASS_SEED,
		PackedColorArray(FOREST_TIPS) if forest else PackedColorArray())


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
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.ssao_enabled = true
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.fog_enabled = true
	env.fog_light_color = zone.haze
	env.fog_density = zone.fog_density
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	root.add_child(world_env)


static func _add_sun(root: Node3D, zone: ZoneData) -> void:
	var sun := DirectionalLight3D.new()
	sun.light_color = zone.sun_color
	# Tuned for the Compatibility renderer (needed for the web build); 1.3 looked
	# right under Forward+ but washes everything out here. The meadow uses 0.6.
	sun.light_energy = zone.sun_energy
	sun.shadow_enabled = true
	sun.rotation_degrees = Vector3(-40, 35, 0)
	root.add_child(sun)
