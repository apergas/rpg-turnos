class_name WorldStage extends RefCounted
## Builds the world map: a 60 x 60 m field of tall grass (Vegetation) with a bare dirt
## path from the spawn point (south) to the village of Villaclaro in a clearing
## (north), low-poly houses, well and rocks with hand-made colliders, trees (denser
## toward the edges, with trunk colliders) and bushes scattered with fixed seeds,
## invisible walls, and hills outside the field. Same sky and sun as battles.

const FIELD_HALF := 30.0
const SPAWN_POS := Vector3(0, 0, 26)
const SPAWN_RADIUS := 4.0
const CLEARING_POS := Vector3(0, 0, -22)
const CLEARING_RADIUS := 8.0
const PATH_HALF_WIDTH := 1.5
## Tall grass covers this area (a bit past the invisible walls so the edge never looks
## bare), except the path and clearing (plus GRASS_PATH_MARGIN) and the rocks.
const GRASS_AREA := Rect2(-36, -36, 72, 72)
const GRASS_SEED := 7
const GRASS_PATH_MARGIN := 0.3
const GRASS_ROCK_MARGIN := 0.2
## Floor under the tall grass: darker than the battle field so gaps read as shade.
const GRASS_FLOOR := Color(0.08, 0.22, 0.05)
## Where the old woman stands and where the Rey Slime waits once the quest unlocks it.
const NPC_POS := Vector3(-2.5, 0, -20)
const BOSS_POS := Vector3(0, 0, -27.5)
const HOUSE_A := preload("res://assets/medieval/building_home_A_red.gltf")
const HOUSE_B := preload("res://assets/medieval/building_home_B_red.gltf")
const WELL := preload("res://assets/medieval/building_well_red.gltf")
## The Medieval Hexagon buildings are miniatures (a house is 0.8 m wide, 0.9 m tall).
const BUILDING_SCALE := 3.5
## [position, yaw in degrees, model] of each village house. The door is on the model's
## +Z side; the yaw turns it to the clearing.
const HOUSES := [
	[Vector3(-5.5, 0, -25), 60.0, HOUSE_A],
	[Vector3(5.5, 0, -25), -60.0, HOUSE_B],
]
const WELL_POS := Vector3(4.5, 0, -19)
## Corners of the dirt path, from the spawn point to the clearing.
const PATH_POINTS: Array[Vector3] = [
	Vector3(0, 0, 26),
	Vector3(3, 0, 12),
	Vector3(-2, 0, 0),
	Vector3(2, 0, -12),
	Vector3(0, 0, -22),
]
## [position, rock model (BattleStage.ROCK_SCENES), scale, yaw in degrees] of each
## rock, kept off the path and off the autoplay route.
const ROCKS := [
	[Vector3(-20, 0, -16), 2, 8.0, 15.0],
	[Vector3(-22, 0, 14), 4, 9.0, 60.0],
	[Vector3(18, 0, -18), 3, 9.0, 130.0],
	[Vector3(22, 0, 16), 4, 10.0, 200.0],
	[Vector3(-10, 0, -18), 1, 8.0, 290.0],
	[Vector3(12, 0, -20), 2, 9.0, 80.0],
	[Vector3(-12, 0, 23), 0, 10.0, 170.0],
	[Vector3(24, 0, 0), 3, 10.0, 240.0],
	[Vector3(-24, 0, -2), 2, 10.0, 320.0],
	[Vector3(7, 0, -15), 1, 7.0, 45.0],
]
## Trees: TREE_TRIES random spots over a square of TREE_AREA_HALF with a fixed seed. A
## spot is kept with a chance that rises from TREE_CENTER_CHANCE (up to TREE_RISE_FROM
## from the centre) to 1 at the field's edge, and only if it is clear of the path, the
## autoplay route, the rocks and the other trees.
const TREE_SEED := 23
const TREE_TRIES := 600
const TREE_AREA_HALF := 36.0
const TREE_CENTER_CHANCE := 0.05
const TREE_RISE_FROM := 8.0
const TREE_SPACING := 3.2
const TREE_PATH_MARGIN := 3.0
const TREE_ROUTE_MARGIN := 2.5
const TREE_ROCK_MARGIN := 1.5
const TREE_SCALE := Vector2(3.6, 4.4)
## Past this distance from the centre (largest of |x| and |z|) trees are clumps.
const CLUMP_FROM := 27.0
## Colliders (only inside the walls): a trunk for single trees, a wider one for clumps.
const TRUNK_RADIUS := 0.35
const CLUMP_RADIUS := 2.0
const TREE_COLLIDER_HEIGHT := 3.0
## Bushes: BUSH_TRIES random spots inside the walls with a fixed seed, kept off the path
## and the rocks. They have no collider; the hero walks through them like the grass.
const BUSH_SEED := 31
const BUSH_TRIES := 220
const BUSH_SCALE := Vector2(0.7, 1.2)
const BUSH_PATH_MARGIN := 0.8
const BUSH_ROCK_MARGIN := 0.6
## [position, scale] of each hill (unit spheres, half buried) around the field.
const HILLS := [
	[Vector3(-40, -5, -42), Vector3(22, 10, 22)],
	[Vector3(0, -6, -54), Vector3(28, 11, 20)],
	[Vector3(40, -5, -40), Vector3(22, 9, 22)],
	[Vector3(54, -6, 0), Vector3(20, 10, 28)],
	[Vector3(42, -5, 42), Vector3(22, 9, 22)],
	[Vector3(0, -6, 56), Vector3(28, 10, 20)],
	[Vector3(-42, -5, 42), Vector3(22, 10, 22)],
	[Vector3(-54, -6, 0), Vector3(20, 9, 28)],
]


## Returns the tall grass material, so the world can bend it away from the player.
static func build(root: Node3D) -> ShaderMaterial:
	BattleStage.build_environment(root)
	_add_ground(root)
	_add_path(root)
	for rock in ROCKS:
		_add_solid_model(root, BattleStage.ROCK_SCENES[rock[1]], rock[0], rock[2], rock[3])
	_add_village(root)
	_add_trees(root)
	_add_bushes(root)
	for hill in HILLS:
		BattleStage.add_mesh(root, BattleStage.unit_sphere(), BattleStage.HILL, hill[0], hill[1])
	_add_walls(root)
	return Vegetation.build(root, GRASS_AREA, is_grass_free, GRASS_SEED)


## True on the dirt path, the clearing and around the spawn point: no encounters there.
## margin widens every one of them (the grass keeps a little off the path's edge).
static func is_on_path(pos: Vector3, margin := 0.0) -> bool:
	var p := Vector2(pos.x, pos.z)
	if p.distance_to(Vector2(SPAWN_POS.x, SPAWN_POS.z)) < SPAWN_RADIUS + margin:
		return true
	if p.distance_to(Vector2(CLEARING_POS.x, CLEARING_POS.z)) < CLEARING_RADIUS + margin:
		return true
	for i in PATH_POINTS.size() - 1:
		var a := Vector2(PATH_POINTS[i].x, PATH_POINTS[i].z)
		var b := Vector2(PATH_POINTS[i + 1].x, PATH_POINTS[i + 1].z)
		var closest := Geometry2D.get_closest_point_to_segment(p, a, b)
		if p.distance_to(closest) < PATH_HALF_WIDTH + margin:
			return true
	return false


## Where tall grass may grow: off the path and clearing (the village is inside the
## clearing) and off the rocks.
static func is_grass_free(pos: Vector3) -> bool:
	if is_on_path(pos, GRASS_PATH_MARGIN):
		return false
	return not _near_rock(pos, GRASS_ROCK_MARGIN)


## Upright cylinder collider standing on the ground, for village props and figures.
static func add_cylinder_shape(body: StaticBody3D, radius: float, height: float) -> void:
	var cylinder := CylinderShape3D.new()
	cylinder.radius = radius
	cylinder.height = height
	var shape := CollisionShape3D.new()
	shape.shape = cylinder
	shape.position = Vector3(0, height / 2.0, 0)
	body.add_child(shape)


static func _add_ground(root: Node3D) -> void:
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(160, 160)
	BattleStage.add_mesh(root, mesh, GRASS_FLOOR, Vector3.ZERO)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	shape.shape = WorldBoundaryShape3D.new()
	body.add_child(shape)
	root.add_child(body)


static func _add_path(root: Node3D) -> void:
	for i in PATH_POINTS.size() - 1:
		var a := PATH_POINTS[i]
		var b := PATH_POINTS[i + 1]
		var d := b - a
		var mesh := PlaneMesh.new()
		mesh.size = Vector2(PATH_HALF_WIDTH * 2.0, d.length())
		var mid := (a + b) / 2.0 + Vector3(0, 0.01, 0)
		var yaw := rad_to_deg(atan2(d.x, d.z))
		BattleStage.add_mesh(root, mesh, BattleStage.DIRT, mid, Vector3.ONE, Vector3(0, yaw, 0))
	# Round the inner bends so the drawn path matches is_on_path (union of capsules).
	for i in range(1, PATH_POINTS.size() - 1):
		_add_disc(root, PATH_POINTS[i], PATH_HALF_WIDTH)
	_add_disc(root, SPAWN_POS, SPAWN_RADIUS)
	_add_disc(root, CLEARING_POS, CLEARING_RADIUS)


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


static func _add_village(root: Node3D) -> void:
	for house in HOUSES:
		_add_solid_model(root, house[2], house[0], BUILDING_SCALE, house[1])
	_add_solid_model(root, WELL, WELL_POS, BUILDING_SCALE, 0.0)


static func _add_trees(root: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = TREE_SEED
	var placed: Array[Vector2] = []
	var single_a: Array[Transform3D] = []
	var single_b: Array[Transform3D] = []
	var clumps: Array[Transform3D] = []
	for i in TREE_TRIES:
		# Every roll is made even for spots left out, so the layout stays stable.
		var pos := Vector3(rng.randf_range(-TREE_AREA_HALF, TREE_AREA_HALF), 0.0,
			rng.randf_range(-TREE_AREA_HALF, TREE_AREA_HALF))
		var roll := rng.randf()
		var yaw := rng.randf() * TAU
		var scl := rng.randf_range(TREE_SCALE.x, TREE_SCALE.y)
		var use_a := rng.randf() < 0.5
		var edge := maxf(absf(pos.x), absf(pos.z))
		var rise := clampf((edge - TREE_RISE_FROM) / (FIELD_HALF - TREE_RISE_FROM), 0.0, 1.0)
		if roll > lerpf(TREE_CENTER_CHANCE, 1.0, rise) or not _tree_fits(pos, placed):
			continue
		placed.append(Vector2(pos.x, pos.z))
		var xform := Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * scl), pos)
		var clump := edge > CLUMP_FROM
		if clump:
			clumps.append(xform)
		elif use_a:
			single_a.append(xform)
		else:
			single_b.append(xform)
		if edge < FIELD_HALF:
			var body := StaticBody3D.new()
			body.position = pos
			root.add_child(body)
			add_cylinder_shape(body, CLUMP_RADIUS if clump else TRUNK_RADIUS,
				TREE_COLLIDER_HEIGHT)
	LowPoly.add_multimesh(root, BattleStage.scene_mesh(BattleStage.TREE_SCENES[0]), single_a)
	LowPoly.add_multimesh(root, BattleStage.scene_mesh(BattleStage.TREE_SCENES[1]), single_b)
	LowPoly.add_multimesh(root, BattleStage.scene_mesh(BattleStage.TREE_SCENES[2]), clumps)


static func _tree_fits(pos: Vector3, placed: Array[Vector2]) -> bool:
	if is_on_path(pos, TREE_PATH_MARGIN) or _near_route(pos, TREE_ROUTE_MARGIN):
		return false
	if _near_rock(pos, TREE_ROCK_MARGIN):
		return false
	var p := Vector2(pos.x, pos.z)
	for other in placed:
		if p.distance_to(other) < TREE_SPACING:
			return false
	return true


static func _add_bushes(root: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = BUSH_SEED
	var bushes: Array[Transform3D] = []
	for i in BUSH_TRIES:
		var pos := Vector3(rng.randf_range(-FIELD_HALF, FIELD_HALF), 0.0,
			rng.randf_range(-FIELD_HALF, FIELD_HALF))
		var yaw := rng.randf() * TAU
		var scl := rng.randf_range(BUSH_SCALE.x, BUSH_SCALE.y)
		if is_on_path(pos, BUSH_PATH_MARGIN) or _near_rock(pos, BUSH_ROCK_MARGIN):
			continue
		bushes.append(Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * scl), pos))
	LowPoly.add_multimesh(root, LowPoly.bush_mesh(), bushes)


## True within margin of a rock's footprint.
static func _near_rock(pos: Vector3, margin: float) -> bool:
	var p := Vector2(pos.x, pos.z)
	for rock in ROCKS:
		var center := Vector2(rock[0].x, rock[0].z)
		if p.distance_to(center) < BattleStage.rock_radius(rock) + margin:
			return true
	return false


## True within margin of the loop Player walks on --autoplay, so no tree blocks it.
static func _near_route(pos: Vector3, margin: float) -> bool:
	var p := Vector2(pos.x, pos.z)
	var route := Player.AUTOPLAY_ROUTE
	for i in route.size():
		var a := Vector2(route[i].x, route[i].z)
		var next := route[(i + 1) % route.size()]
		var b := Vector2(next.x, next.z)
		if p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b)) < margin:
			return true
	return false


static func _add_walls(root: Node3D) -> void:
	var h := FIELD_HALF
	var walls := [
		[Vector3(0, 2, -h), Vector3(h * 2.0, 4, 1)],
		[Vector3(0, 2, h), Vector3(h * 2.0, 4, 1)],
		[Vector3(-h, 2, 0), Vector3(1, 4, h * 2.0)],
		[Vector3(h, 2, 0), Vector3(1, 4, h * 2.0)],
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
