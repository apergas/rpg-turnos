class_name EncounterTable extends RefCounted
## Which enemies a random encounter brings, from the zone's ZoneData: within
## start_radius of start_pos only start_formations come (slimes near the meadow's spawn,
## one enemy at a time at the forest's entry); elsewhere every formation of the zone has
## the same weight. The zone's rare enemy comes instead, alone, now and then, if a quest
## wants it. Pure: no nodes.


static func near_start(zone: ZoneData, pos: Vector3) -> bool:
	return not zone.start_formations.is_empty() and Vector2(pos.x, pos.z).distance_to(
		Vector2(zone.start_pos.x, zone.start_pos.z)) < zone.start_radius


## The enemy data of one encounter at pos in zone (not duplicated: BattleScene does it).
static func pick(zone: ZoneData, pos: Vector3, rng: RandomNumberGenerator,
		wanted: Array[String] = []) -> Array[Combatant]:
	if zone.rare_enemy in wanted and rng.randf() < zone.rare_chance:
		return EnemyLibrary.formation([zone.rare_enemy])
	var formations: Array = zone.start_formations if near_start(zone, pos) else zone.formations
	return EnemyLibrary.formation(formations[rng.randi_range(0, formations.size() - 1)])
