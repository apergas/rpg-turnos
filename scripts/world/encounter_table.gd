class_name EncounterTable extends RefCounted
## Which enemies a random encounter brings, from the zone's ZoneData: within
## start_radius of start_pos only start_formations come (slimes near the meadow's spawn,
## one enemy at a time at the forest's entry); elsewhere every formation of the zone has
## the same weight. The zone's rare enemy comes instead, alone, now and then: at the zone's
## rare_chance while a quest wants it, at RARE_AFTER_QUEST once a quest has hunted it (so
## the bestiary can still be completed), never before its quest is taken. Pure: no nodes.

## The rare enemy's chance once the quest that hunted it is done.
const RARE_AFTER_QUEST := 0.05


static func near_start(zone: ZoneData, pos: Vector3) -> bool:
	return not zone.start_formations.is_empty() and Vector2(pos.x, pos.z).distance_to(
		Vector2(zone.start_pos.x, zone.start_pos.z)) < zone.start_radius


## How often the zone's rare enemy comes now (0..1).
static func rare_chance(zone: ZoneData, wanted: Array[String], hunted: Array[String]) -> float:
	if zone.rare_enemy == "":
		return 0.0
	if zone.rare_enemy in wanted:
		return zone.rare_chance
	if zone.rare_enemy in hunted:
		return RARE_AFTER_QUEST
	return 0.0


## The enemy data of one encounter at pos in zone (not duplicated: BattleScene does it).
## wanted: the enemies an active quest hunts; hunted: those a finished quest hunted.
static func pick(zone: ZoneData, pos: Vector3, rng: RandomNumberGenerator,
		wanted: Array[String] = [], hunted: Array[String] = []) -> Array[Combatant]:
	var chance := rare_chance(zone, wanted, hunted)
	if chance > 0.0 and rng.randf() < chance:
		return EnemyLibrary.formation([zone.rare_enemy])
	var formations: Array = zone.start_formations if near_start(zone, pos) else zone.formations
	return EnemyLibrary.formation(formations[rng.randi_range(0, formations.size() - 1)])


## The enemy data of the group standing at pos on the map being built (not duplicated:
## BattleScene does it): start_formations near the zone's start, else any formation of the
## zone, every one with the same weight.
static func pick_group(zone: ZoneData, pos: Vector3, rng: RandomNumberGenerator) -> Array[Combatant]:
	var formations: Array = zone.start_formations if near_start(zone, pos) else zone.formations
	return EnemyLibrary.formation(formations[rng.randi_range(0, formations.size() - 1)])
