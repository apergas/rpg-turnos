class_name DungeonMap extends Node3D
## The cells of a dungeon floor (ZoneData.layout), built when it enters the tree: a dark
## floor in chunks, a rock block with a box collider for every rock cell next to the
## floor (the buried ones are drawn in one MultiMesh, with no collider), torches on the
## walls with a flickering point light, the stairs (a flight going up, a dark pit going
## down, with a sign), iron gates on the door cells, the lever and the key. World tells
## it the world flags (set_flags(): gates open, lever pulled, key taken) and, every
## frame, where the camera and the hero are (see_through()): the rock blocks between them
## turn see-through. Set zone before add_child.

## Height of the rock blocks.
const WALL_HEIGHT := 3.0
## The floor is drawn in squares of this many cells, so each torch only lights a few.
const FLOOR_CHUNK := 3
const FLOOR_COLOR := Color(0.36, 0.32, 0.28)
## Rock blocks get one of these shades (picked by cell, so the walls are not flat).
const ROCK_SHADES := [1.0, 0.88, 1.1]
## Opacity of a block between the camera and the hero.
const SEE_THROUGH_ALPHA := 0.3
## The camera-to-hero lines are checked at these heights above the hero's feet, against
## each block grown by SEE_THROUGH_MARGIN (the hero's body is wider than a line).
const SEE_THROUGH_HEIGHTS := [0.3, 1.6]
const SEE_THROUGH_MARGIN := 0.6
## Torches: a bracket on the wall with a flame; its light hangs out from the wall.
const TORCH_HEIGHT := 2.1
const TORCH_COLOR := Color(1.0, 0.62, 0.3)
const TORCH_ENERGY := 2.5
const TORCH_RANGE := 8.0
const FLAME_COLOR := Color(1.0, 0.7, 0.25)
## How much the torch lights waver (share of their energy) and how fast.
const FLICKER := 0.12
const FLICKER_SPEED := 9.0
const IRON := Color(0.2, 0.2, 0.23)
const WOOD := Color(0.36, 0.22, 0.1)
const STONE := Color(0.45, 0.43, 0.42)
const KEY_GOLD := Color(1.0, 0.8, 0.25)
## Angle (degrees about X) of the lever's handle: up (waiting) and pulled down.
const LEVER_UP := -40.0
const LEVER_DOWN := 40.0

var zone: ZoneData

## cell -> MeshInstance3D of each rock block next to the floor (the ones that can fade).
var _blocks := {}
var _rock_materials: Array[StandardMaterial3D] = []
var _clear_material: StandardMaterial3D
var _faded: Array[MeshInstance3D] = []
var _lights: Array[OmniLight3D] = []
var _time := 0.0
## Gate bodies (their collider goes away when the doors open), the lever's handle pivot
## and the key's root.
var _gates: Array[StaticBody3D] = []
var _lever: Node3D
var _key: Node3D


func _ready() -> void:
	for shade in ROCK_SHADES:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = zone.rock_color * shade
		mat.roughness = 1.0
		_rock_materials.append(mat)
	_clear_material = StandardMaterial3D.new()
	_clear_material.albedo_color = Color(zone.rock_color, SEE_THROUGH_ALPHA)
	_clear_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_clear_material.roughness = 1.0
	_add_floor()
	_add_rock()
	for cell in zone.find_cells(ZoneData.TORCH):
		_add_torch(cell)
	for cell in zone.find_cells(ZoneData.STAIRS_UP):
		_add_stairs(cell, true)
	for cell in zone.find_cells(ZoneData.STAIRS_DOWN):
		_add_stairs(cell, false)
	for cell in zone.find_cells(ZoneData.DOOR):
		_add_gate(cell)
	for cell in zone.find_cells(ZoneData.LEVER):
		_add_lever(cell)
	for cell in zone.find_cells(ZoneData.KEY):
		_add_key(cell)


func _process(delta: float) -> void:
	_time += delta
	for i in _lights.size():
		var wave := sin(_time * FLICKER_SPEED + i * 1.7) * 0.6 + sin(_time * 23.0 + i) * 0.4
		_lights[i].light_energy = TORCH_ENERGY * (1.0 + FLICKER * wave)
	if _key and _key.visible:
		_key.rotation.y += delta * 1.5


## Opens the gates once zone.door_flag is set, pulls the lever once zone.lever_flag is
## and hides the key once it was taken (its id is a flag).
func set_flags(flags: Dictionary) -> void:
	var open: bool = zone.door_flag != "" and flags.get(zone.door_flag, false)
	for gate in _gates:
		gate.visible = not open
		gate.process_mode = Node.PROCESS_MODE_DISABLED if open else Node.PROCESS_MODE_INHERIT
	if _lever:
		var pulled: bool = zone.lever_flag != "" and flags.get(zone.lever_flag, false)
		_lever.rotation_degrees.x = LEVER_DOWN if pulled else LEVER_UP
	if _key:
		_key.visible = not (zone.floor_key != "" and flags.get(zone.floor_key, false))


## Pulls the lever down with a short swing (the flag change follows in set_flags()).
func pull_lever() -> void:
	if _lever:
		_lever.create_tween().tween_property(_lever, "rotation_degrees:x", LEVER_DOWN, 0.3) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Makes see-through the rock blocks that hide the hero (standing at target) from the
## camera, and solid again the rest. Only the blocks of the two rows south of the hero
## (toward the camera) and one column to each side can be in the way.
func see_through(camera_pos: Vector3, target: Vector3) -> void:
	var hidden: Array[MeshInstance3D] = []
	var cell := zone.cell_at(target)
	for dy in [0, 1, 2]:
		for dx in [-1, 0, 1]:
			var block: MeshInstance3D = _blocks.get(cell + Vector2i(dx, dy))
			if block and _blocks_view(block, camera_pos, target):
				hidden.append(block)
	for block in _faded:
		if not block in hidden:
			block.material_override = _rock_materials[_shade(zone.cell_at(block.position))]
	for block in hidden:
		block.material_override = _clear_material
	_faded = hidden


func _blocks_view(block: MeshInstance3D, camera_pos: Vector3, target: Vector3) -> bool:
	var grow := Vector3(SEE_THROUGH_MARGIN, 0, SEE_THROUGH_MARGIN)
	var half := Vector3(ZoneData.CELL, WALL_HEIGHT, ZoneData.CELL) / 2.0 + grow
	var box := AABB(block.position - half, half * 2.0)
	for height in SEE_THROUGH_HEIGHTS:
		if box.intersects_segment(camera_pos, target + Vector3(0, height, 0)):
			return true
	return false


func _shade(cell: Vector2i) -> int:
	return absi(cell.x * 7 + cell.y * 13) % ROCK_SHADES.size()


## The floor under the whole grid, in FLOOR_CHUNK × FLOOR_CHUNK squares.
func _add_floor() -> void:
	var size := zone.grid_size()
	var chunk := ZoneData.CELL * FLOOR_CHUNK
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(chunk, chunk)
	for y in range(0, size.y, FLOOR_CHUNK):
		for x in range(0, size.x, FLOOR_CHUNK):
			var corner := zone.cell_center(Vector2i(x, y)) - Vector3(ZoneData.CELL, 0, ZoneData.CELL) / 2.0
			BattleStage.add_mesh(self, mesh, FLOOR_COLOR, corner + Vector3(chunk, 0, chunk) / 2.0)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	shape.shape = WorldBoundaryShape3D.new()
	body.add_child(shape)
	add_child(body)


## A block on every rock cell: the ones next to the floor (eight neighbours) one by one
## with a collider, the buried ones in a MultiMesh.
func _add_rock() -> void:
	var size := zone.grid_size()
	var box := BoxMesh.new()
	box.size = Vector3(ZoneData.CELL, WALL_HEIGHT, ZoneData.CELL)
	var body := StaticBody3D.new()
	add_child(body)
	var buried: Array[Transform3D] = []
	for y in size.y:
		for x in size.x:
			var cell := Vector2i(x, y)
			if zone.cell_char(cell) != ZoneData.ROCK:
				continue
			var pos := zone.cell_center(cell) + Vector3(0, WALL_HEIGHT / 2.0, 0)
			if not _touches_floor(cell):
				buried.append(Transform3D(Basis(), pos))
				continue
			var mi := MeshInstance3D.new()
			mi.mesh = box
			mi.material_override = _rock_materials[_shade(cell)]
			mi.position = pos
			add_child(mi)
			_blocks[cell] = mi
			var shape := CollisionShape3D.new()
			shape.shape = BoxShape3D.new()
			(shape.shape as BoxShape3D).size = box.size
			shape.position = pos
			body.add_child(shape)
	var buried_mesh := box.duplicate() as BoxMesh
	buried_mesh.material = _rock_materials[0]
	LowPoly.add_multimesh(self, buried_mesh, buried)


func _touches_floor(cell: Vector2i) -> bool:
	for dy in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			if zone.cell_char(cell + Vector2i(dx, dy)) != ZoneData.ROCK:
				return true
	return false


## The first rock neighbour of cell (north, west, east, south), as a unit step.
func _wall_side(cell: Vector2i) -> Vector2i:
	for step in [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1)]:
		if zone.cell_char(cell + step) == ZoneData.ROCK:
			return step
	return Vector2i(0, -1)


## A bracket on the cell's wall with a flame and a flickering light a little out from it.
func _add_torch(cell: Vector2i) -> void:
	var side := _wall_side(cell)
	var out := -Vector3(side.x, 0, side.y)
	var at_wall := zone.cell_center(cell) - out * (ZoneData.CELL / 2.0 - 0.12)
	var stick := BoxMesh.new()
	stick.size = Vector3(0.1, 0.5, 0.1)
	BattleStage.add_mesh(self, stick, WOOD, at_wall + out * 0.1 + Vector3(0, TORCH_HEIGHT - 0.2, 0))
	var flame := MeshInstance3D.new()
	flame.mesh = BattleStage.unit_sphere()
	flame.scale = Vector3(0.13, 0.2, 0.13)
	flame.position = at_wall + out * 0.2 + Vector3(0, TORCH_HEIGHT + 0.12, 0)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = FLAME_COLOR
	flame.material_override = mat
	flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(flame)
	var light := OmniLight3D.new()
	light.light_color = TORCH_COLOR
	light.light_energy = TORCH_ENERGY
	light.omni_range = TORCH_RANGE
	light.position = at_wall + out * 0.7 + Vector3(0, TORCH_HEIGHT + 0.2, 0)
	add_child(light)
	_lights.append(light)


## Stairs up: a flight of stone steps rising toward the cell's wall. Stairs down: a dark
## pit with the top steps going down. Both with a sign that faces the camera.
func _add_stairs(cell: Vector2i, up: bool) -> void:
	var center := zone.cell_center(cell)
	var side := _wall_side(cell)
	var toward := Vector3(side.x, 0, side.y)
	# Steps are 2.6 m wide across the way to the wall and 0.55 m deep along it.
	var along_z := side.y != 0
	if up:
		for i in 5:
			var step := BoxMesh.new()
			var height := 0.3 * (i + 1)
			step.size = Vector3(2.6, height, 0.55) if along_z else Vector3(0.55, height, 2.6)
			BattleStage.add_mesh(self, step, STONE.darkened(0.05 * i),
				center + toward * (-0.6 + i * 0.55) + Vector3(0, height / 2.0, 0))
	else:
		var pit := BoxMesh.new()
		pit.size = Vector3(2.8, 0.02, 2.8)
		BattleStage.add_mesh(self, pit, Color(0.02, 0.02, 0.02), center + Vector3(0, 0.01, 0))
		for i in 3:
			var step := BoxMesh.new()
			step.size = Vector3(2.6, 0.03, 0.5) if along_z else Vector3(0.5, 0.03, 2.6)
			BattleStage.add_mesh(self, step, STONE.darkened(0.25 + 0.2 * i),
				center - toward * (1.0 - i * 0.6) + Vector3(0, 0.03, 0))
	var label := Label3D.new()
	label.text = "Subir" if up else "Bajar"
	label.font_size = 48
	label.pixel_size = 0.008
	label.outline_size = 10
	label.modulate = Color(1.0, 0.95, 0.8)
	label.position = center + Vector3(0, 2.6, 0)
	add_child(label)


## An iron gate across the corridor of the cell, with a collider while closed.
func _add_gate(cell: Vector2i) -> void:
	var body := StaticBody3D.new()
	body.position = zone.cell_center(cell)
	# The corridor runs between the two open sides: the gate spans the other axis.
	var open_x := zone.cell_char(cell + Vector2i(-1, 0)) != ZoneData.ROCK
	if open_x:
		body.rotation_degrees.y = 90.0
	add_child(body)
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	(shape.shape as BoxShape3D).size = Vector3(ZoneData.CELL, WALL_HEIGHT, 0.6)
	shape.position.y = WALL_HEIGHT / 2.0
	body.add_child(shape)
	var bar := BoxMesh.new()
	bar.size = Vector3(0.1, WALL_HEIGHT, 0.1)
	for i in 9:
		BattleStage.add_mesh(body, bar, IRON,
			Vector3(-1.8 + i * 0.45, WALL_HEIGHT / 2.0, 0))
	var rail := BoxMesh.new()
	rail.size = Vector3(ZoneData.CELL, 0.14, 0.14)
	for y in [0.4, 1.6, 2.8]:
		BattleStage.add_mesh(body, rail, IRON, Vector3(0, y, 0))
	_gates.append(body)


## A lever on a stone base: its handle on a pivot, up until pulled.
func _add_lever(cell: Vector2i) -> void:
	var center := zone.cell_center(cell)
	var base := BoxMesh.new()
	base.size = Vector3(0.7, 0.5, 0.5)
	BattleStage.add_mesh(self, base, STONE, center + Vector3(0, 0.25, 0))
	_lever = Node3D.new()
	_lever.position = center + Vector3(0, 0.5, 0)
	_lever.rotation_degrees.x = LEVER_UP
	add_child(_lever)
	var handle := BoxMesh.new()
	handle.size = Vector3(0.08, 0.8, 0.08)
	BattleStage.add_mesh(_lever, handle, WOOD, Vector3(0, 0.4, 0))
	BattleStage.add_mesh(_lever, BattleStage.unit_sphere(), Color(0.7, 0.15, 0.1),
		Vector3(0, 0.85, 0), Vector3.ONE * 0.1)


## A gold key turning slowly over a small stone pedestal.
func _add_key(cell: Vector2i) -> void:
	var center := zone.cell_center(cell)
	var pedestal := CylinderMesh.new()
	pedestal.top_radius = 0.35
	pedestal.bottom_radius = 0.42
	pedestal.height = 0.6
	pedestal.radial_segments = 6
	BattleStage.add_mesh(self, pedestal, STONE, center + Vector3(0, 0.3, 0))
	_key = Node3D.new()
	_key.position = center + Vector3(0, 1.1, 0)
	_key.scale = Vector3.ONE * 1.8
	add_child(_key)
	var ring := TorusMesh.new()
	ring.inner_radius = 0.08
	ring.outer_radius = 0.16
	ring.rings = 8
	ring.ring_segments = 6
	BattleStage.add_mesh(_key, ring, KEY_GOLD, Vector3(0, 0.2, 0), Vector3.ONE,
		Vector3(90, 0, 0))
	var shaft := BoxMesh.new()
	shaft.size = Vector3(0.06, 0.4, 0.06)
	BattleStage.add_mesh(_key, shaft, KEY_GOLD, Vector3(0, -0.12, 0))
	var bit := BoxMesh.new()
	bit.size = Vector3(0.14, 0.06, 0.06)
	BattleStage.add_mesh(_key, bit, KEY_GOLD, Vector3(0.07, -0.26, 0))
	var glow := OmniLight3D.new()
	glow.light_color = KEY_GOLD
	glow.light_energy = 0.8
	glow.omni_range = 2.5
	_key.add_child(glow)
