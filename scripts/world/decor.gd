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
	"mushroom": {"radius": 0.3, "collider": ""},
	"mushrooms_red": {"radius": 0.4, "collider": ""},
	"mushrooms_tan": {"radius": 0.4, "collider": ""},
	"fern": {"radius": 0.5, "collider": ""},
	"leafy": {"radius": 0.7, "collider": ""},
	"row_wheat": {"radius": 1.6, "collider": "", "length": 3.0},
	"row_corn": {"radius": 1.6, "collider": "", "length": 3.0},
	"row_pumpkin": {"radius": 1.6, "collider": "", "length": 3.0},
	"row_carrot": {"radius": 1.6, "collider": "", "length": 3.0},
	"fence_gate": {"radius": 1.5, "collider": "", "length": 3.0},
	"stump": {"radius": 0.55, "collider": "cylinder"},
	"stump_tall": {"radius": 0.6, "collider": "cylinder"},
	"log": {"radius": 1.5, "collider": "box"},
	"log_stack": {"radius": 1.1, "collider": "box"},
	"pot": {"radius": 0.8, "collider": "cylinder"},
	"fence": {"radius": 1.5, "collider": "box", "length": 3.0},
	"campfire": {"radius": 0.9, "collider": "cylinder", "flame": true},
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
	if _near(placed(zone), pos, margin):
		return true
	var p := Vector2(pos.x, pos.z)
	for piece in scattered(zone):
		if is_solid(piece.id) and p.distance_to(Vector2(piece.pos.x, piece.pos.z)) \
				< radius(piece) + margin:
			return true
	return false


## True within margin of a placed piece (the trees ask only this: the scattered pieces
## already keep off the trees).
static func near_placed(zone: ZoneData, pos: Vector3, margin: float) -> bool:
	return _near(placed(zone), pos, margin)


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
