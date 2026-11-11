class_name EncounterTable extends RefCounted
## Which enemies a group of the map brings (MonsterGroups builds the map with pick_group()),
## from the zone's ZoneData: within start_radius of start_pos only start_formations
## (slimes near the meadow's spawn, one enemy at a time at the forest's entry); elsewhere
## every formation of the zone, with the same weight. The zone's rare enemy (the Slime de
## Metal) is not a group of these: it is on every map built while a quest wants it, on
## RARE_AFTER_QUEST of them once a quest has hunted it (so the bestiary can still be
## completed), never before its quest is taken (rare_on_map()). Pure: no nodes.

## The rare enemy's chance on each map built while a quest wants it, and once the quest
## that hunted it is done.
const RARE_WANTED := 1.0
const RARE_AFTER_QUEST := 0.05


static func near_start(zone: ZoneData, pos: Vector3) -> bool:
	return not zone.start_formations.is_empty() and Vector2(pos.x, pos.z).distance_to(
		Vector2(zone.start_pos.x, zone.start_pos.z)) < zone.start_radius


## How likely the zone's rare enemy is on a map built now (0..1).
static func rare_chance(zone: ZoneData, wanted: Array[String], hunted: Array[String]) -> float:
	if zone.rare_enemy == "":
		return 0.0
	if zone.rare_enemy in wanted:
		return RARE_WANTED
	if zone.rare_enemy in hunted:
		return RARE_AFTER_QUEST
	return 0.0


## True if the zone's rare enemy goes on the map being built (rare_chance()).
static func rare_on_map(zone: ZoneData, wanted: Array[String], hunted: Array[String],
		rng: RandomNumberGenerator) -> bool:
	var chance := rare_chance(zone, wanted, hunted)
	return chance > 0.0 and rng.randf() < chance


## The enemy data of the group standing at pos on the map being built (not duplicated:
## BattleScene does it): start_formations near the zone's start, else any formation of the
## zone, every one with the same weight.
static func pick_group(zone: ZoneData, pos: Vector3, rng: RandomNumberGenerator) -> Array[Combatant]:
	var formations: Array = zone.start_formations if near_start(zone, pos) else zone.formations
	return EnemyLibrary.formation(formations[rng.randi_range(0, formations.size() - 1)])
