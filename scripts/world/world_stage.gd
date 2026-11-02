class_name WorldStage extends RefCounted
## Builds the world map from primitives: a 60 x 60 m grass field with a dirt path
## from the spawn point (south) to an empty clearing (north), rocks and invisible
## walls with collision, and hills outside the field. Same sky and sun as battles.

const FIELD_HALF := 30.0
const SPAWN_POS := Vector3(0, 0, 26)
const SPAWN_RADIUS := 4.0
const CLEARING_POS := Vector3(0, 0, -22)
const CLEARING_RADIUS := 8.0
const PATH_HALF_WIDTH := 1.5
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


static func build(root: Node3D) -> void:
	BattleStage.build_environment(root)
	_add_ground(root)
	_add_path(root)
	for rock in ROCKS:
		_add_rock(root, rock[0], rock[1])
	for hill in HILLS:
		BattleStage.add_mesh(root, BattleStage.unit_sphere(), BattleStage.HILL, hill[0], hill[1])
	_add_walls(root)


## True on the dirt path, the clearing and around the spawn point: no encounters there.
static func is_on_path(pos: Vector3) -> bool:
	var p := Vector2(pos.x, pos.z)
	if p.distance_to(Vector2(SPAWN_POS.x, SPAWN_POS.z)) < SPAWN_RADIUS:
		return true
	if p.distance_to(Vector2(CLEARING_POS.x, CLEARING_POS.z)) < CLEARING_RADIUS:
		return true
	for i in PATH_POINTS.size() - 1:
		var a := Vector2(PATH_POINTS[i].x, PATH_POINTS[i].z)
		var b := Vector2(PATH_POINTS[i + 1].x, PATH_POINTS[i + 1].z)
		if p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b)) < PATH_HALF_WIDTH:
			return true
	return false


static func _add_ground(root: Node3D) -> void:
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(160, 160)
	BattleStage.add_mesh(root, mesh, BattleStage.GRASS, Vector3.ZERO)
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
		# Each strip runs half a width past both ends so the corners stay covered.
		mesh.size = Vector2(PATH_HALF_WIDTH * 2.0, d.length() + PATH_HALF_WIDTH * 2.0)
		var mid := (a + b) / 2.0 + Vector3(0, 0.01, 0)
		var yaw := rad_to_deg(atan2(d.x, d.z))
		BattleStage.add_mesh(root, mesh, BattleStage.DIRT, mid, Vector3.ONE, Vector3(0, yaw, 0))
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
