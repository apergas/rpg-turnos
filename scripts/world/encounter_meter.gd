class_name EncounterMeter extends RefCounted
## What is left of the random encounters (gone in 1.7.0: the monsters are on the map,
## MonsterGroups): Dragon Quest's rule that the weak keep away from a strong hero. A hero
## LEVEL_GAP levels past a zone's exit_level gets level_rate() CALM_RATE, and then the
## zone's moving groups keep away from him (is_shy(), MonsterRoam). Pure.

const LEVEL_GAP := 4
const CALM_RATE := 0.5


## 1.0, or CALM_RATE for a hero of hero_level LEVEL_GAP levels past exit_level.
static func level_rate(hero_level: int, exit_level: int) -> float:
	return CALM_RATE if exit_level > 0 and hero_level >= exit_level + LEVEL_GAP else 1.0


## True when the zone's moving groups keep away from the hero (level_rate() below 1).
static func is_shy(hero_level: int, exit_level: int) -> bool:
	return level_rate(hero_level, exit_level) < 1.0
