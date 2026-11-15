class_name FloatingIslands extends RefCounted
## Constructor: a floor of cells open to the sky whose rock cells are a void (the Ruinas
## flotantes, 3.2.0; ZoneData.floating), built under DungeonMap instead of its floor and its rock
## blocks: an old flagstone slab on every cell that is not rock (three shades, picked by cell),
## a root of rock hanging under each slab (longer here and there, so the islands' undersides
## are uneven), a sea of mist far below with a thinner layer between it and the roots, an
## invisible wall on every rock cell next to the floor (nobody walks off an island) and the
## ground the hero walks on. root_mesh() also hangs under V3Backdrops' islands. Static only,
## keeps no state.

## A slab: a little narrower than its cell, so the joints show, and how thick.
const SLAB_GAP := 0.14
const SLAB_THICKNESS := 0.5
## The slabs' shades, times the zone's floor_color.
const SLAB_SHADES := [1.0, 0.9, 1.08]
## The roots: as wide as ROOT_RADIUS under the slab (they overlap, so an island hangs as one
## rock), a point ROOT_TIP wide at the bottom, one of ROOT_LENGTHS long (picked by cell).
const ROOT_RADIUS := 2.4
const ROOT_TIP := 0.35
const ROOT_LENGTHS := [2.5, 3.5, 5.0, 4.0, 6.5]
## The void: the sea of mist this far below the islands (the zone's haze), the see-through layer
## higher up, and how far past the grid both reach.
const VOID_DEPTH := 26.0
const MIST_DEPTH := 8.0
const MIST_ALPHA := 0.4
const VOID_MARGIN := 90.0
## The invisible walls on the rock cells next to the floor.
const WALL_HEIGHT := 3.0


static func build(root: Node3D, zone: ZoneData) -> void:
	var size := zone.grid_size()
	var slab := BoxMesh.new()
	slab.size = Vector3(ZoneData.CELL - SLAB_GAP, SLAB_THICKNESS, ZoneData.CELL - SLAB_GAP)
	var by_shade: Array = []
	for shade in SLAB_SHADES:
		var list: Array[Transform3D] = []
		by_shade.append(list)
	var roots: Array[Transform3D] = []
	var walls := StaticBody3D.new()
	root.add_child(walls)
	for y in size.y:
		for x in size.x:
			var cell := Vector2i(x, y)
			var center := zone.cell_center(cell)
			if zone.cell_char(cell) != ZoneData.ROCK:
				var pick := absi(x * 7 + y * 13)
				(by_shade[pick % SLAB_SHADES.size()] as Array).append(
					Transform3D(Basis.IDENTITY, center + Vector3(0, -SLAB_THICKNESS / 2.0, 0)))
				var length: float = ROOT_LENGTHS[pick % ROOT_LENGTHS.size()]
				roots.append(Transform3D(Basis.from_scale(Vector3(1, length, 1)),
					center + Vector3(0, -SLAB_THICKNESS - length / 2.0, 0)))
			elif _touches_floor(zone, cell):
				var shape := CollisionShape3D.new()
				shape.shape = BoxShape3D.new()
				(shape.shape as BoxShape3D).size = Vector3(ZoneData.CELL, WALL_HEIGHT, ZoneData.CELL)
				shape.position = center + Vector3(0, WALL_HEIGHT / 2.0, 0)
				walls.add_child(shape)
	for i in SLAB_SHADES.size():
		LowPoly.add_multimesh(root, slab, by_shade[i], material(zone.floor_color * SLAB_SHADES[i]))
	LowPoly.add_multimesh(root, root_mesh(ROOT_RADIUS, 1.0), roots, material(zone.rock_color))
	_add_void(root, zone)
	var ground := StaticBody3D.new()
	var plane := CollisionShape3D.new()
	plane.shape = WorldBoundaryShape3D.new()
	ground.add_child(plane)
	root.add_child(ground)


## A root of rock hanging from an island: top_radius wide at its top, narrowing to ROOT_TIP
## length below (6 sides).
static func root_mesh(top_radius: float, length: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = ROOT_TIP
	mesh.height = length
	mesh.radial_segments = 6
	mesh.rings = 1
	return mesh


static func material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	return material


## True if a cell next to cell (eight neighbours) is not rock.
static func _touches_floor(zone: ZoneData, cell: Vector2i) -> bool:
	for dy in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			if zone.cell_char(cell + Vector2i(dx, dy)) != ZoneData.ROCK:
				return true
	return false


## The sea of mist under the islands (the zone's haze, VOID_DEPTH below) and the thin layer of
## mist between it and their roots, past the grid on every side.
static func _add_void(root: Node3D, zone: ZoneData) -> void:
	var size := Vector2(zone.grid_size()) * ZoneData.CELL + Vector2.ONE * VOID_MARGIN * 2.0
	var sea := PlaneMesh.new()
	sea.size = size
	BattleStage.add_mesh(root, sea, zone.haze, Vector3(0, -VOID_DEPTH, 0))
	var layer := PlaneMesh.new()
	layer.size = size
	var mist := StandardMaterial3D.new()
	mist.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mist.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mist.albedo_color = Color(zone.haze.lightened(0.15), MIST_ALPHA)
	var mi := MeshInstance3D.new()
	mi.mesh = layer
	mi.material_override = mist
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position.y = -MIST_DEPTH
	root.add_child(mi)
