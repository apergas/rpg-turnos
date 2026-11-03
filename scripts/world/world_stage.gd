class_name WorldStage extends RefCounted
## Builds the world map from primitives: a 60 x 60 m field of tall grass (Vegetation)
## with a bare dirt path from the spawn point (south) to the village of Villaclaro in a
## clearing (north), rocks and invisible walls with collision, and hills outside the
## field. Same sky and sun as battles.

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
const GRASS_FLOOR := Color(0.22, 0.4, 0.15)
## Where the old woman stands and where the Rey Slime waits once the quest unlocks it.
const NPC_POS := Vector3(-2.5, 0, -20)
const BOSS_POS := Vector3(0, 0, -27.5)
## [position, yaw in degrees] of each village house; the yaw turns the door to the clearing.
const HOUSES := [
	[Vector3(-5.5, 0, -25), 60.0],
	[Vector3(5.5, 0, -25), -60.0],
]
const HOUSE_SIZE := Vector3(3, 2.5, 3)
const WELL_POS := Vector3(4.5, 0, -19)
const WELL_RADIUS := 0.8
const WALL_COLOR := Color(0.93, 0.87, 0.72)
const ROOF_COLOR := Color(0.72, 0.2, 0.15)
const DOOR_COLOR := Color(0.4, 0.25, 0.12)
const WATER_COLOR := Color(0.2, 0.4, 0.8)
## Corners of the dirt path, from the spawn point to the clearing.
const PATH_POINTS: Array[Vector3] = [
	Vector3(0, 0, 26),
	Vector3(3, 0, 12),
	Vector3(-2, 0, 0),
	Vector3(2, 0, -12),
	Vector3(0, 0, -22),
]
## [position, scale] of each rock (unit spheres, half buried), kept off the path
## and off the autoplay route.
const ROCKS := [
	[Vector3(-20, 0.4, -16), Vector3(1.4, 1.0, 1.2)],
	[Vector3(-22, 0.5, 14), Vector3(1.8, 1.2, 1.5)],
	[Vector3(18, 0.4, -18), Vector3(1.5, 1.0, 1.3)],
	[Vector3(22, 0.6, 16), Vector3(2.0, 1.4, 1.6)],
	[Vector3(-10, 0.3, -18), Vector3(1.0, 0.7, 0.9)],
	[Vector3(12, 0.4, -20), Vector3(1.3, 0.9, 1.1)],
	[Vector3(-12, 0.3, 23), Vector3(1.1, 0.8, 1.0)],
	[Vector3(24, 0.5, 0), Vector3(1.6, 1.1, 1.4)],
	[Vector3(-24, 0.4, -2), Vector3(1.5, 1.0, 1.2)],
	[Vector3(7, 0.3, -15), Vector3(0.9, 0.6, 0.8)],
]
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
		_add_rock(root, rock[0], rock[1])
	_add_village(root)
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
	var p := Vector2(pos.x, pos.z)
	for rock in ROCKS:
		var scl: Vector3 = rock[1]
		var center := Vector2(rock[0].x, rock[0].z)
		if p.distance_to(center) < maxf(scl.x, scl.z) + GRASS_ROCK_MARGIN:
			return false
	return true


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


static func _add_rock(root: Node3D, pos: Vector3, scl: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	root.add_child(body)
	BattleStage.add_mesh(body, BattleStage.unit_sphere(), BattleStage.ROCK, Vector3.ZERO, scl)
	# Box collider instead of a scaled sphere: physics shapes must not be scaled.
	var box := BoxShape3D.new()
	box.size = scl * 1.6
	var shape := CollisionShape3D.new()
	shape.shape = box
	body.add_child(shape)


static func _add_village(root: Node3D) -> void:
	for house in HOUSES:
		_add_house(root, house[0], house[1])
	var well := StaticBody3D.new()
	well.position = WELL_POS
	root.add_child(well)
	var stone := CylinderMesh.new()
	stone.top_radius = WELL_RADIUS
	stone.bottom_radius = WELL_RADIUS
	stone.height = 0.8
	BattleStage.add_mesh(well, stone, BattleStage.ROCK, Vector3(0, 0.4, 0))
	var water := CylinderMesh.new()
	water.top_radius = WELL_RADIUS - 0.2
	water.bottom_radius = WELL_RADIUS - 0.2
	water.height = 0.02
	BattleStage.add_mesh(well, water, WATER_COLOR, Vector3(0, 0.8, 0))
	add_cylinder_shape(well, WELL_RADIUS, 0.8)


static func _add_house(root: Node3D, pos: Vector3, yaw: float) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	body.rotation_degrees = Vector3(0, yaw, 0)
	root.add_child(body)
	var walls := BoxMesh.new()
	walls.size = HOUSE_SIZE
	BattleStage.add_mesh(body, walls, WALL_COLOR, Vector3(0, HOUSE_SIZE.y / 2.0, 0))
	var roof := PrismMesh.new()
	roof.size = Vector3(HOUSE_SIZE.x + 0.4, 1.4, HOUSE_SIZE.z + 0.4)
	BattleStage.add_mesh(body, roof, ROOF_COLOR, Vector3(0, HOUSE_SIZE.y + 0.7, 0))
	var door := BoxMesh.new()
	door.size = Vector3(0.8, 1.4, 0.05)
	BattleStage.add_mesh(body, door, DOOR_COLOR, Vector3(0, 0.7, HOUSE_SIZE.z / 2.0 + 0.03))
	var box := BoxShape3D.new()
	box.size = HOUSE_SIZE
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position = Vector3(0, HOUSE_SIZE.y / 2.0, 0)
	body.add_child(shape)


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
