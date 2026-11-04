class_name EncounterTable extends RefCounted
## Which enemies a random encounter brings, per zone (only zone 1 for now: the meadow).
## Within START_RADIUS of WorldStage.SPAWN_POS only slimes come, alone or in pairs;
## elsewhere every formation of the zone has the same weight. Pure: no nodes.

const SLIME := preload("res://data/enemies/slime.tres")
const BAT := preload("res://data/enemies/bat.tres")
const MUSHROOM := preload("res://data/enemies/mushroom.tres")
const START_RADIUS := 20.0
const START_FORMATIONS := [[SLIME], [SLIME, SLIME]]
## zone -> formations (each a list of enemy data, left to right).
const ZONES := {
	1: [[SLIME], [SLIME], [BAT], [MUSHROOM], [SLIME, SLIME], [SLIME, BAT]],
}


static func near_start(pos: Vector3) -> bool:
	return Vector2(pos.x, pos.z).distance_to(
		Vector2(WorldStage.SPAWN_POS.x, WorldStage.SPAWN_POS.z)) < START_RADIUS


## The enemy data of one encounter at pos in zone (not duplicated: BattleScene does it).
static func pick(zone: int, pos: Vector3, rng: RandomNumberGenerator) -> Array[Combatant]:
	var formations: Array = START_FORMATIONS if near_start(pos) else ZONES[zone]
	var picked: Array[Combatant] = []
	picked.assign(formations[rng.randi_range(0, formations.size() - 1)])
	return picked
