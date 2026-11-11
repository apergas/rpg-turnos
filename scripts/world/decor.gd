class_name Decor extends RefCounted
## Pure: where the Kenney decoration of a zone goes (NatureModels draws it, WorldStage builds
## it). Pieces placed by hand (ZoneData.decor) and scattered with the zone's seed
## (ZoneData.decor_scatter, open maps only). Each piece is {"id", "pos", "yaw" (radians),
## "scale", "scattered"}. A scattered piece keeps off everything WorldStage.decor_blocker()
## names and off the other pieces; a placed one is where the zone says, and problems() tells
## what it is on that it should not be.

## id → its footprint radius at scale 1 (metres), its collider ("" none, "box" fitted to the
## mesh, "cylinder" of that radius), the length of one piece of a run (fences) and whether a
## flame burns on it.
const KINDS := {
	"flowers": {"radius": 0.5, "collider": ""},
	"mushrooms_red": {"radius": 0.4, "collider": ""},
	"mushrooms_tan": {"radius": 0.4, "collider": ""},
	"fern": {"radius": 0.5, "collider": ""},
	"leafy": {"radius": 0.7, "collider": ""},
	"row_wheat": {"radius": 1.6, "collider": "", "length": 3.0},
	"row_corn": {"radius": 1.6, "collider": "", "length": 3.0},
	"row_pumpkin": {"radius": 1.6, "collider": "", "length": 3.0},
	"fence_gate": {"radius": 1.5, "collider": "", "length": 3.0},
	"stump": {"radius": 0.55, "collider": "cylinder"},
	"stump_tall": {"radius": 0.6, "collider": "cylinder"},
	"log": {"radius": 1.5, "collider": "box"},
	"log_stack": {"radius": 1.1, "collider": "box"},
	"pot": {"radius": 0.8, "collider": "cylinder"},
	"fence": {"radius": 1.5, "collider": "box", "length": 3.0},
	"campfire": {"radius": 0.9, "collider": "cylinder", "flame": true},
	# The desert (2.1.0): cacti and dry scrub scattered over the sand, the ruin's pieces.
	"cactus": {"radius": 0.45, "collider": "cylinder"},
	"cactus_tall": {"radius": 0.55, "collider": "cylinder"},
	"scrub": {"radius": 0.5, "collider": ""},
	"column": {"radius": 0.7, "collider": "cylinder"},
	"column_broken": {"radius": 0.7, "collider": "cylinder"},
	"ruin_block": {"radius": 0.9, "collider": "box"},
	# The mountain (2.2.0): pines and tall stones in its rooms, flat stones in the snow.
	"pine": {"radius": 0.6, "collider": "cylinder"},
	"pine_small": {"radius": 0.5, "collider": "cylinder"},
	"rock_tall": {"radius": 1.1, "collider": "box"},
	"snow_stones": {"radius": 0.9, "collider": ""},
	# The abandoned city (2.3.0): ruins in its squares and streets (only placed by hand).
	"city_column": {"radius": 0.7, "collider": "cylinder"},
	"city_column_broken": {"radius": 0.7, "collider": "cylinder"},
	"city_block": {"radius": 0.9, "collider": "box"},
	"fallen_head": {"radius": 1.0, "collider": "box"},
	"obelisk": {"radius": 0.7, "collider": "box"},
	"rubble": {"radius": 1.0, "collider": ""},
}
## Scattered pieces keep this far from each other and from every placed piece.
const SCATTER_GAP := 1.2
const SCATTER_SCALE := Vector2(0.85, 1.15)
## Scattered pieces stay this far inside the walls.
const WALL_INSET := 1.0

static var _placed_zone := ""
static var _placed: Array[Dictionary] = []
static var _scatter_zone := ""
static var _scatter: Array[Dictionary] = []
## Coarse grids (GRID_CELL metres) of the placed pieces and of the solid ones (placed and
## scattered), built once per zone: cell → [Vector3(x, z, radius)].
const GRID_CELL := 4.0
static var _placed_grid_zone := ""
static var _placed_grid: Dictionary = {}
static var _placed_reach := 0.0
static var _solid_grid_zone := ""
static var _solid_grid: Dictionary = {}
static var _solid_reach := 0.0


static func is_solid(id: String) -> bool:
	return KINDS[id].collider != ""


static func radius(piece: Dictionary) -> float:
	return KINDS[piece.id].radius * piece.scale


## The pieces zone places by hand, runs laid out one piece after another.
static func placed(zone: ZoneData) -> Array[Dictionary]:
	if _placed_zone == zone.id:
		return _placed
	var pieces: Array[Dictionary] = []
	for entry: Array in zone.decor:
		var id: String = entry[2]
		var yaw := deg_to_rad(entry[1])
		var count: int = entry[3] if entry.size() > 3 else 1
		var step := Vector3(cos(yaw), 0.0, -sin(yaw)) * float(KINDS[id].get("length", 0.0))
		for i in count:
			pieces.append({"id": id, "pos": entry[0] + step * i, "yaw": yaw, "scale": 1.0,
				"scattered": false})
	_placed_zone = zone.id
	_placed = pieces
	return pieces


## The pieces scattered over an open map: for each id of decor_scatter (in name order), that
## many spots rolled with decor_seed; every roll is made even for spots left out, so the
## layout stays the same whatever changes elsewhere.
static func scattered(zone: ZoneData) -> Array[Dictionary]:
	if _scatter_zone == zone.id:
		return _scatter
	var pieces: Array[Dictionary] = []
	_scatter_zone = zone.id
	_scatter = pieces
	if zone.is_dungeon():
		return pieces
	var rng := RandomNumberGenerator.new()
	rng.seed = zone.decor_seed
	var area := zone.half_size - Vector2.ONE * WALL_INSET
	var ids: Array = zone.decor_scatter.keys()
	ids.sort()
	for id: String in ids:
		for i in int(zone.decor_scatter[id]):
			var pos := Vector3(rng.randf_range(-area.x, area.x), 0.0, rng.randf_range(-area.y, area.y))
			var piece := {"id": id, "pos": pos, "yaw": rng.randf() * TAU,
				"scale": rng.randf_range(SCATTER_SCALE.x, SCATTER_SCALE.y), "scattered": true}
			if WorldStage.decor_blocker(zone, pos, radius(piece), is_solid(id)) != "":
				continue
			if _near(placed(zone), pos, radius(piece) + SCATTER_GAP) \
					or _near(pieces, pos, radius(piece) + SCATTER_GAP):
				continue
			pieces.append(piece)
	return pieces


## True within margin of a placed piece or of a scattered one with a collider: the trees,
## the bushes, the tall grass and the monster groups keep off them.
static func near_solid(zone: ZoneData, pos: Vector3, margin: float) -> bool:
	if _solid_grid_zone != zone.id:
		var pieces: Array[Dictionary] = []
		pieces.append_array(placed(zone))
		for piece in scattered(zone):
			if is_solid(piece.id):
				pieces.append(piece)
		_solid_grid = _make_grid(pieces)
		_solid_reach = _reach(pieces)
		_solid_grid_zone = zone.id
	return _grid_near(_solid_grid, _solid_reach, pos, margin)


## True within margin of a placed piece (the trees ask only this: the scattered pieces
## already keep off the trees).
static func near_placed(zone: ZoneData, pos: Vector3, margin: float) -> bool:
	if _placed_grid_zone != zone.id:
		var pieces := placed(zone)
		_placed_grid = _make_grid(pieces)
		_placed_reach = _reach(pieces)
		_placed_grid_zone = zone.id
	return _grid_near(_placed_grid, _placed_reach, pos, margin)


## One line for every placed piece of zone that is somewhere it should not be.
static func problems(zone: ZoneData) -> PackedStringArray:
	var lines := PackedStringArray()
	for piece in placed(zone):
		var what := WorldStage.decor_blocker(zone, piece.pos, radius(piece), is_solid(piece.id))
		if what != "":
			lines.append("Decoración: %s en (%.1f, %.1f) pisa %s" % [piece.id, piece.pos.x,
				piece.pos.z, what])
	return lines


static func _near(pieces: Array[Dictionary], pos: Vector3, margin: float) -> bool:
	var p := Vector2(pos.x, pos.z)
	for piece in pieces:
		if p.distance_to(Vector2(piece.pos.x, piece.pos.z)) < radius(piece) + margin:
			return true
	return false


static func _make_grid(pieces: Array[Dictionary]) -> Dictionary:
	var grid := {}
	for piece in pieces:
		var key := Vector2i(floori(piece.pos.x / GRID_CELL), floori(piece.pos.z / GRID_CELL))
		if not grid.has(key):
			grid[key] = []
		(grid[key] as Array).append(Vector3(piece.pos.x, piece.pos.z, radius(piece)))
	return grid


static func _reach(pieces: Array[Dictionary]) -> float:
	var reach := 0.0
	for piece in pieces:
		reach = maxf(reach, radius(piece))
	return reach


static func _grid_near(grid: Dictionary, reach: float, pos: Vector3, margin: float) -> bool:
	if grid.is_empty():
		return false
	var span := reach + margin
	var low := Vector2i(floori((pos.x - span) / GRID_CELL), floori((pos.z - span) / GRID_CELL))
	var high := Vector2i(floori((pos.x + span) / GRID_CELL), floori((pos.z + span) / GRID_CELL))
	var p := Vector2(pos.x, pos.z)
	for x in range(low.x, high.x + 1):
		for z in range(low.y, high.y + 1):
			var cell: Variant = grid.get(Vector2i(x, z))
			if cell == null:
				continue
			for spot: Vector3 in cell:
				if p.distance_to(Vector2(spot.x, spot.y)) < spot.z + margin:
					return true
	return false
