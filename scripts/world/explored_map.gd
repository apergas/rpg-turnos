class_name ExploredMap extends RefCounted
## What the hero has seen of one zone, as a coarse grid of CELL-metre cells (on a dungeon
## floor, its own cells). GameState keeps one per zone and SaveData saves them. reveal() is
## called every physics tick and only does work when the hero enters another cell. Pure:
## never touches nodes.

const CELL := ZoneData.CELL
## How far the hero sees, in metres: about what the camera shows around them on an open
## map; on a dungeon floor only the nearby cells, so its corridors unfold.
const REVEAL_FIELD := 9.0
const REVEAL_DUNGEON := 6.0
## Colors of the seen cells on the map square.
const FIELD_COLOR := Color(0.3, 0.55, 0.26)
const PATH_COLOR := Color(0.78, 0.68, 0.48)
const ROCK_COLOR := Color(0.16, 0.15, 0.17)
const FLOOR_COLOR := Color(0.62, 0.6, 0.58)
const STAIRS_COLOR := Color(1.0, 0.8, 0.25)
const DOOR_COLOR := Color(0.55, 0.32, 0.16)

var zone: ZoneData
var size: Vector2i
## One byte per cell, row by row: 1 once seen.
var cells: PackedByteArray

var _last_cell := Vector2i(-1, -1)


## saved: the cells of an earlier visit (ignored if they don't fit this zone's grid).
func _init(p_zone: ZoneData, saved := PackedByteArray()) -> void:
	zone = p_zone
	if zone.is_dungeon():
		size = zone.grid_size()
	else:
		size = Vector2i(ceili(zone.half_size.x * 2.0 / CELL), ceili(zone.half_size.y * 2.0 / CELL))
	if saved.size() == size.x * size.y:
		cells = saved
	else:
		cells = PackedByteArray()
		cells.resize(size.x * size.y)


func is_seen(cell: Vector2i) -> bool:
	return cells[cell.y * size.x + cell.x] != 0


func any_seen() -> bool:
	return cells.has(1)


## pos in grid units (cell (2, 3) spans 2..3 and 3..4), for the hero's marker.
func grid_point(pos: Vector3) -> Vector2:
	if zone.is_dungeon():
		return Vector2(pos.x / CELL + size.x / 2.0, pos.z / CELL + size.y / 2.0)
	return Vector2((pos.x + zone.half_size.x) / CELL, (pos.z + zone.half_size.y) / CELL)


## Marks what the hero sees from pos. Returns the cells seen for the first time; empty, at
## once, while the hero stays in the same cell.
func reveal(pos: Vector3) -> Array[Vector2i]:
	var fresh: Array[Vector2i] = []
	var point := grid_point(pos)
	var here := Vector2i(floori(point.x), floori(point.y))
	if here == _last_cell:
		return fresh
	_last_cell = here
	var radius := (REVEAL_DUNGEON if zone.is_dungeon() else REVEAL_FIELD) / CELL
	var reach := ceili(radius)
	for y in range(maxi(here.y - reach, 0), mini(here.y + reach + 1, size.y)):
		for x in range(maxi(here.x - reach, 0), mini(here.x + reach + 1, size.x)):
			var center := Vector2(x + 0.5, y + 0.5)
			var i := y * size.x + x
			if cells[i] == 0 and center.distance_to(point) <= radius:
				cells[i] = 1
				fresh.append(Vector2i(x, y))
	return fresh


## The color of a cell once seen.
func color_of(cell: Vector2i) -> Color:
	if not zone.is_dungeon():
		var pos := Vector3((cell.x + 0.5) * CELL - zone.half_size.x, 0.0,
			(cell.y + 0.5) * CELL - zone.half_size.y)
		return PATH_COLOR if WorldStage.is_on_path(zone, pos) else FIELD_COLOR
	match zone.cell_char(cell):
		ZoneData.ROCK:
			return ROCK_COLOR
		ZoneData.STAIRS_UP, ZoneData.STAIRS_DOWN:
			return STAIRS_COLOR
		ZoneData.DOOR:
			return DOOR_COLOR
	return FLOOR_COLOR
