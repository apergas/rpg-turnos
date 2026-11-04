class_name ZoneData extends Resource
## Everything one map of the world is built from (data/zones/<id>.tres): the field and
## its walls, ground and grass, the dirt path and the safe discs, the village, buildings,
## rocks, trees and bushes, the entries and exits, the figures, the boss, the encounter
## formations and pace, the music, the light and the battle backdrop. WorldStage builds
## the map from it, World runs it and Game switches between zones. Pure data plus a few
## lookups: never touches nodes.
##
## Positions are Vector3 on the ground (y = 0). Yaws are degrees about Y, 0 = facing -Z
## for figures and entries, +Z for building doors (as the models come).

## Every zone, in world order (save validation and --autoplay-zone check against it).
const IDS: Array[String] = ["pradera", "bosque"]

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

@export_group("Autoplay")
## Points walked in a loop by --autoplay (clear of trees, rocks and buildings).
@export var autoplay_route: Array[Vector3] = []
## On autoplay the boss only comes out from this level on.
@export var autoplay_boss_level := 1


## The zone with this id (data/zones/<id>.tres), or null if there is none.
static func by_id(zone_id: String) -> ZoneData:
	if not zone_id in IDS:
		return null
	return load("res://data/zones/%s.tres" % zone_id) as ZoneData


## Where entry_id puts the player: [position, yaw in degrees]. Unknown ids give the
## start entry.
func entry(entry_id: String) -> Array:
	return entries.get(entry_id, entries[start_entry])


## The exit with that id, or an empty Dictionary.
func exit_by_id(exit_id: String) -> Dictionary:
	for exit: Dictionary in exits:
		if exit.id == exit_id:
			return exit
	return {}
