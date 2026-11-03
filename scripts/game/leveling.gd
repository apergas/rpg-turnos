class_name Leveling extends RefCounted
## Pure level-up rules: fixed EXP table and fixed gains per level. Current HP and MP
## go up by the same amount as their maximum, so a level up is not a full heal.

const MAX_LEVEL := 10
## EXP_TABLE[i] is the total EXP needed to reach level i + 1.
const EXP_TABLE := [0, 10, 25, 45, 70, 100, 135, 175, 220, 270]
const GAINS := {"max_hp": 5, "max_mp": 2, "attack": 2, "defense": 1, "speed": 1}


## Raises every level the hero's EXP allows and returns one LEVEL_UP event per level.
static func apply(hero: Combatant) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	while hero.level < MAX_LEVEL and hero.experience >= EXP_TABLE[hero.level]:
		hero.level += 1
		hero.max_hp += GAINS.max_hp
		hero.hp += GAINS.max_hp
		hero.max_mp += GAINS.max_mp
		hero.mp += GAINS.max_mp
		hero.attack += GAINS.attack
		hero.defense += GAINS.defense
		hero.speed += GAINS.speed
		events.append(BattleEvent.level_up(hero.level, GAINS, hero))
	return events


## Total EXP needed for the next level, or -1 at MAX_LEVEL.
static func exp_for_next(level: int) -> int:
	return EXP_TABLE[level] if level < MAX_LEVEL else -1
