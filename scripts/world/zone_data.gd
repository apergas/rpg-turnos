class_name ZoneData extends Resource
## Everything one map of the world is built from (data/zones/<id>.tres): the field and
## its walls, ground and grass, the dirt path and the safe discs, the village, buildings,
## rocks, trees and bushes, the entries and exits, the figures, the boss, the encounter
## formations and pace, the music, the light and the battle backdrop. WorldStage builds
## the map from it, World runs it and Game switches between zones. A dungeon floor (the
## mine, the castle) is drawn instead as a grid of CELL metres (layout, see "Dungeon"):
## DungeonMap builds it and the lookups below answer about its cells. Pure data plus a few lookups:
## never touches nodes.
##
## Positions are Vector3 on the ground (y = 0). Yaws are degrees about Y, 0 = facing -Z
## for figures and entries, +Z for building doors (as the models come).

## Every zone, in world order (save validation and --autoplay-zone check against it).
const IDS: Array[String] = ["pradera", "bosque", "mina_1", "mina_2", "mina_3",
	"castillo_patio", "castillo_trono"]
## Side of a dungeon cell, in metres.
const CELL := 4.0
## Dungeon cells: rock (a wall in a castle), floor, stairs up and down, chest, lever,
## locked door, key, floor with a torch on its wall and the throne. Anything else is
## floor.
const ROCK := "#"
const STAIRS_UP := "S"
const STAIRS_DOWN := "B"
const CHEST_CELL := "C"
const LEVER := "L"
const DOOR := "D"
const KEY := "K"
const TORCH := "T"
const THRONE := "R"
## Within this distance of a stair cell's centre the stair room is safe (no encounters).
const STAIRS_SAFE_RADIUS := 6.0

@export var id := ""
## Name shown on the exit signs that lead here and in notices ("la pradera").
@export var display_name := ""
## Zone number of the "Equilibrio" tables (1 meadow, 2 forest...).
@export var number := 1

@export_group("Field")
## Half the walkable field along X and Z: invisible walls stand at ±x and ±z.
@export var half_size := Vector2(30, 30)
## Grass, trees and the ground reach this far past the walls, so the edge never looks bare.
@export var outer_margin := 6.0
@export var ground_color := Color(0.08, 0.22, 0.05)
@export var has_grass := true
## Two tip greens of the tall grass (sRGB); every tuft gets a mix of them.
@export var grass_tips := PackedColorArray([Color(0.22, 0.55, 0.12), Color(0.42, 0.72, 0.16)])
@export var grass_seed := 7
## [position, scale] of each hill (unit spheres, half buried) around the field.
@export var hills: Array = []

@export_group("Path and safe ground")
## Corners of the dirt path (no grass, no encounters).
@export var path_points: Array[Vector3] = []
@export var path_half_width := 1.5
## [centre, radius] of each round patch of bare dirt (no grass, no encounters): the
## spawn area, the village clearing, the boss's clearing...
@export var safe_discs: Array = []
## The village: inside this circle World emits village_changed(true) and the village
## music plays. village_radius 0 means the zone has no village.
@export var village_name := ""
@export var village_pos := Vector3.ZERO
@export var village_radius := 0.0

@export_group("Props")
## [position, yaw, WorldStage.MODELS key] of each building (box collider fitted to it).
@export var buildings: Array = []
## [position, rock model (BattleStage.ROCK_SCENES index), scale, yaw] of each rock.
@export var rocks: Array = []
## Trees: tree_tries random spots over the field plus outer_margin, with a fixed seed. A
## spot is kept with a chance that rises from tree_center_chance (inset tree_rise_inset
## or more from the nearest wall) to 1 at the wall, and only if it is clear of the path,
## the safe discs, the glades, the exits, the autoplay route, the rocks, the buildings,
## the chests and the other trees. Within tree_clump_inset of a wall (or outside) trees
## are clumps.
@export var tree_seed := 23
@export var tree_tries := 600
@export var tree_center_chance := 0.05
@export var tree_rise_inset := 22.0
@export var tree_clump_inset := 3.0
@export var tree_spacing := 3.2
@export var tree_scale := Vector2(3.6, 4.4)
## WorldStage.MODELS keys: single trees (each kept spot picks one of the first two) and
## the clump.
@export var tree_models: Array[String] = ["tree_A", "tree_B"]
@export var clump_model := "trees_A"
## [centre, radius] of each glade: no trees, but grass and encounters.
@export var glades: Array = []
@export var bush_seed := 31
@export var bush_tries := 220

@export_group("Entries, exits and figures")
## entry id -> [position, yaw]: where the player appears (arriving through an exit, a
## new game, the Ala de viaje or a defeat).
@export var entries := {}
## Entry of a new game in this zone.
@export var start_entry := "inicio"
## Entry the Ala de viaje and a defeat lead to once this zone's village was visited
## ("" for a zone with no village).
@export var town_entry := ""
## Where the return portal of an Ala de viaje stands in the village.
@export var portal_pos := Vector3.ZERO
## Each exit: {"id", "pos" (trigger, inside the walls), "yaw" (the arch's facing), "to"
## (zone id), "entry" (entry id there), "label" (sign text), "lock" (GameState.world_flags
## key that opens it, "" for always open), "lock_text" (notice while it is closed)}.
@export var exits: Array = []
## Each figure: {"kind": "quest" (the old woman), "shop", "inn" or "npc", "id" (Shop /
## Inn id), "look" (BattleActor.Look name), "pos", "yaw" (0 faces -Z; 180 faces the
## camera), "name", and for "npc" "lines" and, optional, "after_flag" + "lines_after"
## (said once that world flag is set)}.
@export var npcs: Array = []
## The zone's boss (EnemyLibrary id, "" for none) and where it waits.
@export var boss_id := ""
@export var boss_pos := Vector3.ZERO

@export_group("Encounters")
## Formations of a random encounter (each a list of EnemyLibrary ids, left to right),
## every one with the same weight; within start_radius of start_pos only
## start_formations come.
@export var formations: Array = []
@export var start_formations: Array = []
@export var start_pos := Vector3.ZERO
@export var start_radius := 0.0
## EncounterMeter: free meters after each battle, then this chance per meter on grass.
@export var encounter_grace := 9.0
@export var encounter_chance := 0.01

@export_group("Look and sound")
@export var music := "map"
@export var village_music := "village"
@export var sky_top := Color(0.32, 0.52, 0.88)
@export var haze := Color(0.78, 0.84, 0.92)
@export var fog_density := 0.008
@export var sun_color := Color(1.0, 0.9, 0.75)
@export var sun_energy := 0.6
## BattleStage backdrop of the battles fought here ("pradera", "bosque").
@export var backdrop := "pradera"

@export_group("Dungeon")
## Rows of a dungeon floor, north (−Z) first, one character per CELL × CELL cell (see
## ROCK...TORCH; every edge cell must be rock). Empty for an open map. The grid is centred
## on the origin.
@export var layout: PackedStringArray = PackedStringArray()
## Underground: a black background, a dim ambient light instead of the sky and no sun;
## the torches and the hero's lantern light the floor.
@export var underground := false
@export var ambient_color := Color(0.3, 0.32, 0.45)
@export var ambient_energy := 0.5
@export var rock_color := Color(0.33, 0.29, 0.26)
@export var floor_color := Color(0.36, 0.32, 0.28)
## Castle: the rock cells are stone walls (KayKit wall pieces on the straight runs,
## square towers at corners and ends, round pillars when they stand alone) instead of
## rock blocks, and the open ground goes on past the grid.
@export var castle := false
## Banks of mist drifting low over the floor (0 for none).
@export var mist_banks := 0
## Zone ids the S and B stairs lead to (to their B and S entries).
@export var stairs_up := ""
@export var stairs_down := ""
## World flag set by pulling the L lever ("" for none).
@export var lever_flag := ""
## World flag that opens every D door; door_key (Inventory.KEY_ITEMS id, "" for none)
## opens them when the hero carries it, and is used up; door_text is said while they are
## closed.
@export var door_flag := ""
@export var door_key := ""
@export var door_text := ""
## Key item lying on the K cell (picked once: its id is also set as a world flag).
@export var floor_key := ""

@export_group("Autoplay")
## Points walked in a loop by --autoplay (clear of trees, rocks and buildings).
@export var autoplay_route: Array[Vector3] = []
## On autoplay the boss only comes out from this level on.
@export var autoplay_boss_level := 1

## find_cells() results by character.
var _cells := {}


## The zone with this id (data/zones/<id>.tres), or null if there is none.
static func by_id(zone_id: String) -> ZoneData:
	if not zone_id in IDS:
		return null
	return load("res://data/zones/%s.tres" % zone_id) as ZoneData


## Where entry_id puts the player: [position, yaw in degrees]. On a dungeon floor "S"
## and "B" are the floor cell next to those stairs, facing away from them. Unknown ids
## give the start entry.
func entry(entry_id: String) -> Array:
	if entries.has(entry_id):
		return entries[entry_id]
	if is_dungeon() and entry_id in [STAIRS_UP, STAIRS_DOWN]:
		var stairs := find_cells(entry_id)
		if not stairs.is_empty():
			return _beside(stairs[0])
	if entry_id != start_entry:
		return entry(start_entry)
	return [Vector3.ZERO, 0.0]


## The exits of ZoneData.exits plus, on a dungeon floor, one per stair cell: S leads to
## stairs_up (at its "B" entry) and B to stairs_down (at its "S" entry). Stair exits have
## "stairs": true.
func all_exits() -> Array:
	var all := exits.duplicate()
	if not is_dungeon():
		return all
	for kind in [STAIRS_UP, STAIRS_DOWN]:
		var to := stairs_up if kind == STAIRS_UP else stairs_down
		for cell in find_cells(kind):
			all.append({"id": kind, "pos": cell_center(cell), "yaw": 0.0, "to": to,
				"entry": STAIRS_DOWN if kind == STAIRS_UP else STAIRS_UP,
				"label": "Subir" if kind == STAIRS_UP else "Bajar", "lock": "",
				"lock_text": "", "stairs": true})
	return all


func is_dungeon() -> bool:
	return not layout.is_empty()


## Columns and rows of the layout.
func grid_size() -> Vector2i:
	return Vector2i(layout[0].length(), layout.size()) if is_dungeon() else Vector2i.ZERO


## Centre of a cell on the ground.
func cell_center(cell: Vector2i) -> Vector3:
	var size := grid_size()
	return Vector3((cell.x + 0.5 - size.x / 2.0) * CELL, 0.0, (cell.y + 0.5 - size.y / 2.0) * CELL)


## The cell under pos (it may be outside the grid).
func cell_at(pos: Vector3) -> Vector2i:
	var size := grid_size()
	return Vector2i(floori(pos.x / CELL + size.x / 2.0), floori(pos.z / CELL + size.y / 2.0))


## The character of a cell; ROCK outside the grid.
func cell_char(cell: Vector2i) -> String:
	var size := grid_size()
	if cell.x < 0 or cell.y < 0 or cell.x >= size.x or cell.y >= size.y:
		return ROCK
	return layout[cell.y][cell.x]


## Every cell holding character ch, row by row. Cached per character, since the layout
## never changes and World asks every frame; callers only read the array.
func find_cells(ch: String) -> Array[Vector2i]:
	if _cells.has(ch):
		return _cells[ch]
	var cells: Array[Vector2i] = []
	for y in layout.size():
		for x in layout[y].length():
			if layout[y][x] == ch:
				cells.append(Vector2i(x, y))
	_cells[ch] = cells
	return cells


## True within STAIRS_SAFE_RADIUS of a stair cell (the stair rooms have no encounters).
func near_stairs(pos: Vector3) -> bool:
	for kind in [STAIRS_UP, STAIRS_DOWN]:
		for cell in find_cells(kind):
			var center := cell_center(cell)
			if Vector2(pos.x, pos.z).distance_to(Vector2(center.x, center.z)) < STAIRS_SAFE_RADIUS:
				return true
	return false


## [position, yaw] of the first walkable cell next to cell (south, north, east, west),
## facing away from it.
func _beside(cell: Vector2i) -> Array:
	for step in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
		var ch := cell_char(cell + step)
		if ch != ROCK and ch != DOOR:
			return [cell_center(cell + step), rad_to_deg(atan2(-step.x, -step.y))]
	return [cell_center(cell), 0.0]


## The exit with that id, or an empty Dictionary.
func exit_by_id(exit_id: String) -> Dictionary:
	for exit: Dictionary in exits:
		if exit.id == exit_id:
			return exit
	return {}
