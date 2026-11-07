class_name WorldStage extends RefCounted
## Builds one map of the world from its ZoneData: the sky and light of the zone, the
## ground, a field of tall grass (Vegetation) with a bare dirt path and safe discs,
## low-poly buildings and rocks with hand-made colliders, trees (denser toward the walls,
## with trunk colliders) and bushes scattered with fixed seeds, invisible walls and hills
## outside. Exits, figures and chests are World's. A dungeon floor only gets its sky and
## light and its buildings (the castle camp's tents) here: its cells are a DungeonMap,
## which World adds. Every query takes the zone.

## The Medieval Hexagon buildings are miniatures (a house is 0.8 m wide, 0.9 m tall).
const BUILDING_SCALE := 3.5
const TREE_SHADER := preload("res://shaders/tree.gdshader")
## Models named by ZoneData (buildings, tree_models, clump_model).
const MODELS := {
	"house_A_red": preload("res://assets/medieval/building_home_A_red.gltf"),
	"house_B_red": preload("res://assets/medieval/building_home_B_red.gltf"),
	"well_red": preload("res://assets/medieval/building_well_red.gltf"),
	"house_A_green": preload("res://assets/medieval/building_home_A_green.gltf"),
	"house_B_green": preload("res://assets/medieval/building_home_B_green.gltf"),
	"market_green": preload("res://assets/medieval/building_market_green.gltf"),
	"tavern_green": preload("res://assets/medieval/building_tavern_green.gltf"),
	"well_green": preload("res://assets/medieval/building_well_green.gltf"),
	"tree_A": preload("res://assets/medieval/tree_single_A.gltf"),
	"tree_B": preload("res://assets/medieval/tree_single_B.gltf"),
	"trees_A": preload("res://assets/medieval/trees_A_medium.gltf"),
	"trees_B": preload("res://assets/medieval/trees_B_medium.gltf"),
	"tent": preload("res://assets/medieval/tent.gltf"),
}
## Buildings drawn at another scale than BUILDING_SCALE (the tent is a tiny prop).
const MODEL_SCALES := {"tent": 6.0}
## Half the widest side of each building at BUILDING_SCALE (measured AABBs), in metres.
const BUILDING_RADIUS := {
	"house_A_red": 1.5, "house_B_red": 1.9, "well_red": 1.3,
	"house_A_green": 1.5, "house_B_green": 1.9, "well_green": 1.3,
	"market_green": 3.2, "tavern_green": 2.4, "tent": 1.6,
}
## Tall grass keeps this far from the path and the safe discs, the rocks and the chests.
const GRASS_PATH_MARGIN := 0.3
const GRASS_ROCK_MARGIN := 0.2
const GRASS_BUILDING_MARGIN := 0.4
const CHEST_GRASS_MARGIN := 1.0
const FIGURE_GRASS_MARGIN := 1.0
## Trees keep this far from the path, the autoplay route, the rocks, the buildings, the
## chests and the exits; bushes from the path, the rocks and the chests.
const TREE_PATH_MARGIN := 3.0
const TREE_ROUTE_MARGIN := 2.5
const TREE_ROCK_MARGIN := 1.5
const TREE_BUILDING_MARGIN := 2.5
const CHEST_TREE_MARGIN := 2.2
const TREE_EXIT_MARGIN := 3.5
const BUSH_PATH_MARGIN := 0.8
const BUSH_ROCK_MARGIN := 0.6
const CHEST_BUSH_MARGIN := 1.2
const BUSH_SCALE := Vector2(0.7, 1.2)
## Colliders (only inside the walls): a trunk for single trees, a wider one for clumps.
const TRUNK_RADIUS := 0.35
const CLUMP_RADIUS := 2.0
const TREE_COLLIDER_HEIGHT := 3.0

## _near_chest()'s cache: the zone id and its chests' spots on the ground.
static var _chest_zone := ""
static var _chest_spots: Array[Vector2] = []


## Builds zone under root. Returns the tall grass material (null if the zone has no
## grass), so the world can bend it away from the player.
static func build(root: Node3D, zone: ZoneData) -> ShaderMaterial:
	BattleStage.build_environment(root, zone)
	if zone.is_dungeon():
		for building in zone.buildings:
			_add_solid_model(root, MODELS[building[2]], building[0],
				MODEL_SCALES.get(building[2], BUILDING_SCALE), building[1])
		return null
	_add_ground(root, zone)
	_add_path(root, zone)
	for rock in zone.rocks:
		_add_solid_model(root, BattleStage.ROCK_SCENES[rock[1]], rock[0], rock[2], rock[3])
	for building in zone.buildings:
		_add_solid_model(root, MODELS[building[2]], building[0],
			MODEL_SCALES.get(building[2], BUILDING_SCALE), building[1])
	_add_trees(root, zone)
	_add_bushes(root, zone)
	for hill in zone.hills:
		BattleStage.add_mesh(root, BattleStage.unit_sphere(), BattleStage.HILL, hill[0], hill[1])
	_add_walls(root, zone)
	if not zone.has_grass:
		return null
	return Vegetation.build(root, _outer_rect(zone), is_grass_free.bind(zone), zone.grass_seed,
		zone.grass_tips)


## True on the dirt path and the safe discs (and in the stair rooms of a dungeon floor):
## no encounters there. margin widens every one of them (the grass keeps a little off the
## path's edge).
static func is_on_path(zone: ZoneData, pos: Vector3, margin := 0.0) -> bool:
	if zone.is_dungeon() and zone.near_stairs(pos):
		return true
	var p := Vector2(pos.x, pos.z)
	for disc in zone.safe_discs:
		if p.distance_to(Vector2(disc[0].x, disc[0].z)) < disc[1] + margin:
			return true
	var points := zone.path_points
	for i in points.size() - 1:
		var a := Vector2(points[i].x, points[i].z)
		var b := Vector2(points[i + 1].x, points[i + 1].z)
		var closest := Geometry2D.get_closest_point_to_segment(p, a, b)
		if p.distance_to(closest) < zone.path_half_width + margin:
			return true
	return false


## Where tall grass may grow: off the path and the safe discs (the village is inside one),
## the rocks, the buildings, the chests and the figures.
static func is_grass_free(pos: Vector3, zone: ZoneData) -> bool:
	if is_on_path(zone, pos, GRASS_PATH_MARGIN) or _near_chest(zone, pos, CHEST_GRASS_MARGIN) \
			or _near_figure(zone, pos):
		return false
	return not _near_rock(zone, pos, GRASS_ROCK_MARGIN) \
		and not _near_building(zone, pos, GRASS_BUILDING_MARGIN)


## Upright cylinder collider standing on the ground, for village props and figures.
static func add_cylinder_shape(body: StaticBody3D, radius: float, height: float) -> void:
	var cylinder := CylinderShape3D.new()
	cylinder.radius = radius
	cylinder.height = height
	var shape := CollisionShape3D.new()
	shape.shape = cylinder
	shape.position = Vector3(0, height / 2.0, 0)
	body.add_child(shape)


## The field plus outer_margin on every side (position.x = min X, position.y = min Z).
static func _outer_rect(zone: ZoneData) -> Rect2:
	var half := zone.half_size + Vector2.ONE * zone.outer_margin
	return Rect2(-half, half * 2.0)


static func _add_ground(root: Node3D, zone: ZoneData) -> void:
	var mesh := PlaneMesh.new()
	mesh.size = (zone.half_size + Vector2.ONE * 50.0) * 2.0
	BattleStage.add_mesh(root, mesh, zone.ground_color, Vector3.ZERO)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	shape.shape = WorldBoundaryShape3D.new()
	body.add_child(shape)
	root.add_child(body)


static func _add_path(root: Node3D, zone: ZoneData) -> void:
	var points := zone.path_points
	for i in points.size() - 1:
		var a := points[i]
		var b := points[i + 1]
		var d := b - a
		var mesh := PlaneMesh.new()
		mesh.size = Vector2(zone.path_half_width * 2.0, d.length())
		var mid := (a + b) / 2.0 + Vector3(0, 0.01, 0)
		var yaw := rad_to_deg(atan2(d.x, d.z))
		BattleStage.add_mesh(root, mesh, BattleStage.DIRT, mid, Vector3.ONE, Vector3(0, yaw, 0))
	# Round the inner bends so the drawn path matches is_on_path (union of capsules).
	for i in range(1, points.size() - 1):
		_add_disc(root, points[i], zone.path_half_width)
	for disc in zone.safe_discs:
		_add_disc(root, disc[0], disc[1])


static func _add_disc(root: Node3D, center: Vector3, radius: float) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.02
	BattleStage.add_mesh(root, mesh, BattleStage.DIRT, center + Vector3(0, 0.01, 0))


## An imported model on a static body, with a box collider fitted to its mesh (the
## free models bring no collision of their own).
static func _add_solid_model(root: Node3D, scene: PackedScene, pos: Vector3, scl: float, \
		yaw_deg: float) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	body.rotation_degrees = Vector3(0, yaw_deg, 0)
	root.add_child(body)
	var model := BattleStage.add_model(body, scene, Vector3.ZERO, scl)
	var bounds := BattleStage.model_aabb(model)
	var box := BoxShape3D.new()
	box.size = bounds.size * scl
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position = bounds.get_center() * scl
	body.add_child(shape)


static func _add_trees(root: Node3D, zone: ZoneData) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = zone.tree_seed
	var area := zone.half_size + Vector2.ONE * zone.outer_margin
	var placed: Array[Vector2] = []
	var single_a: Array[Transform3D] = []
	var single_b: Array[Transform3D] = []
	var clumps: Array[Transform3D] = []
	for i in zone.tree_tries:
		# Every roll is made even for spots left out, so the layout stays stable.
		var pos := Vector3(rng.randf_range(-area.x, area.x), 0.0, rng.randf_range(-area.y, area.y))
		var roll := rng.randf()
		var yaw := rng.randf() * TAU
		var scl := rng.randf_range(zone.tree_scale.x, zone.tree_scale.y)
		var use_a := rng.randf() < 0.5
		# Distance to the nearest wall (negative outside the field).
		var inset := minf(zone.half_size.x - absf(pos.x), zone.half_size.y - absf(pos.z))
		var rise := clampf(1.0 - inset / zone.tree_rise_inset, 0.0, 1.0)
		if roll > lerpf(zone.tree_center_chance, 1.0, rise) or not _tree_fits(zone, pos, placed):
			continue
		placed.append(Vector2(pos.x, pos.z))
		var xform := Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * scl), pos)
		var clump := inset < zone.tree_clump_inset
		if clump:
			clumps.append(xform)
		elif use_a:
			single_a.append(xform)
		else:
			single_b.append(xform)
		if inset > 0.0:
			var body := StaticBody3D.new()
			body.position = pos
			root.add_child(body)
			add_cylinder_shape(body, CLUMP_RADIUS if clump else TRUNK_RADIUS,
				TREE_COLLIDER_HEIGHT)
	_add_tree_kind(root, MODELS[zone.tree_models[0]], single_a)
	_add_tree_kind(root, MODELS[zone.tree_models[1]], single_b)
	_add_tree_kind(root, MODELS[zone.clump_model], clumps)


## One kind of tree, drawn with its model's texture through the shader that lets the hero
## show through (shaders/tree.gdshader).
static func _add_tree_kind(root: Node3D, scene: PackedScene, transforms: Array[Transform3D]) -> void:
	var mesh := BattleStage.scene_mesh(scene)
	var source := mesh.surface_get_material(0) as BaseMaterial3D
	var material := ShaderMaterial.new()
	material.shader = TREE_SHADER
	material.set_shader_parameter("albedo_texture", source.albedo_texture)
	material.set_shader_parameter("albedo_color", source.albedo_color)
	material.set_shader_parameter("roughness_value", source.roughness)
	LowPoly.add_multimesh(root, mesh, transforms, material)


static func _tree_fits(zone: ZoneData, pos: Vector3, placed: Array[Vector2]) -> bool:
	if is_on_path(zone, pos, TREE_PATH_MARGIN) or _near_route(zone, pos, TREE_ROUTE_MARGIN):
		return false
	if _near_rock(zone, pos, TREE_ROCK_MARGIN) or _near_chest(zone, pos, CHEST_TREE_MARGIN):
		return false
	if _near_building(zone, pos, TREE_BUILDING_MARGIN) or _near_exit(zone, pos, TREE_EXIT_MARGIN):
		return false
	var p := Vector2(pos.x, pos.z)
	for glade in zone.glades:
		if p.distance_to(Vector2(glade[0].x, glade[0].z)) < glade[1]:
			return false
	for other in placed:
		if p.distance_to(other) < zone.tree_spacing:
			return false
	return true


static func _add_bushes(root: Node3D, zone: ZoneData) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = zone.bush_seed
	var bushes: Array[Transform3D] = []
	var half := zone.half_size
	for i in zone.bush_tries:
		var pos := Vector3(rng.randf_range(-half.x, half.x), 0.0, rng.randf_range(-half.y, half.y))
		var yaw := rng.randf() * TAU
		var scl := rng.randf_range(BUSH_SCALE.x, BUSH_SCALE.y)
		if is_on_path(zone, pos, BUSH_PATH_MARGIN) or _near_rock(zone, pos, BUSH_ROCK_MARGIN) \
				or _near_chest(zone, pos, CHEST_BUSH_MARGIN) \
				or _near_building(zone, pos, GRASS_BUILDING_MARGIN):
			continue
		bushes.append(Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * scl), pos))
	var material := ShaderMaterial.new()
	material.shader = TREE_SHADER
	material.set_shader_parameter("albedo_color", LowPoly.BUSH_COLOR)
	LowPoly.add_multimesh(root, LowPoly.bush_mesh(), bushes, material)


## True within margin of a rock's footprint.
static func _near_rock(zone: ZoneData, pos: Vector3, margin: float) -> bool:
	var p := Vector2(pos.x, pos.z)
	for rock in zone.rocks:
		if p.distance_to(Vector2(rock[0].x, rock[0].z)) < BattleStage.rock_radius(rock) + margin:
			return true
	return false


## True within margin of a building's footprint (a circle around its widest side).
static func _near_building(zone: ZoneData, pos: Vector3, margin: float) -> bool:
	var p := Vector2(pos.x, pos.z)
	for building in zone.buildings:
		var radius := BUILDING_RADIUS.get(building[2], 1.6) as float
		if p.distance_to(Vector2(building[0].x, building[0].z)) < radius + margin:
			return true
	return false


## True within FIGURE_GRASS_MARGIN of one of the zone's figures (a cat would be lost in the
## grass).
static func _near_figure(zone: ZoneData, pos: Vector3) -> bool:
	var p := Vector2(pos.x, pos.z)
	for npc: Dictionary in zone.npcs:
		if p.distance_to(Vector2(npc.pos.x, npc.pos.z)) < FIGURE_GRASS_MARGIN:
			return true
	return false


## True within margin of one of the zone's chests (Chests.CHESTS of this zone) or wells
## (zone.wells). The spots of the last zone asked about are kept, so the thousands of
## grass, tree and bush candidates of a build don't look them up each time.
static func _near_chest(zone: ZoneData, pos: Vector3, margin: float) -> bool:
	if _chest_zone != zone.id:
		_chest_zone = zone.id
		_chest_spots.clear()
		for chest_id in Chests.of_zone(zone.id):
			var chest_pos: Vector3 = Chests.CHESTS[chest_id].pos
			_chest_spots.append(Vector2(chest_pos.x, chest_pos.z))
		for well: Dictionary in zone.wells:
			_chest_spots.append(Vector2(well.pos.x, well.pos.z))
	var p := Vector2(pos.x, pos.z)
	for spot in _chest_spots:
		if p.distance_to(spot) < margin:
			return true
	return false


## True within margin of an exit's trigger (its arch stands there).
static func _near_exit(zone: ZoneData, pos: Vector3, margin: float) -> bool:
	var p := Vector2(pos.x, pos.z)
	for exit: Dictionary in zone.exits:
		if p.distance_to(Vector2(exit.pos.x, exit.pos.z)) < margin:
			return true
	return false


## True within margin of the loop Player walks on --autoplay, so no tree blocks it.
static func _near_route(zone: ZoneData, pos: Vector3, margin: float) -> bool:
	var p := Vector2(pos.x, pos.z)
	var route := zone.autoplay_route
	for i in route.size():
		var a := Vector2(route[i].x, route[i].z)
		var next := route[(i + 1) % route.size()]
		var b := Vector2(next.x, next.z)
		if p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b)) < margin:
			return true
	return false


static func _add_walls(root: Node3D, zone: ZoneData) -> void:
	var hx := zone.half_size.x
	var hz := zone.half_size.y
	var walls := [
		[Vector3(0, 2, -hz), Vector3(hx * 2.0, 4, 1)],
		[Vector3(0, 2, hz), Vector3(hx * 2.0, 4, 1)],
		[Vector3(-hx, 2, 0), Vector3(1, 4, hz * 2.0)],
		[Vector3(hx, 2, 0), Vector3(1, 4, hz * 2.0)],
	]
	for wall in walls:
		var body := StaticBody3D.new()
		body.position = wall[0]
		var box := BoxShape3D.new()
		box.size = wall[1]
		var shape := CollisionShape3D.new()
		shape.shape = box
		body.add_child(shape)
		root.add_child(body)
