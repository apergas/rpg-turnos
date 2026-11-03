class_name Leveling extends RefCounted
## Pure level-up rules: fixed EXP table up to MAX_LEVEL and fixed gains per level.
## Current HP and MP go up by the same amount as their maximum, so a level up is not a
## full heal. Reaching a level listed in the hero's `learn` teaches that spell.

const MAX_LEVEL := 20
## EXP_TABLE[i] is the total EXP needed to reach level i + 1.
const EXP_TABLE := [0, 12, 35, 62, 96, 180, 260, 340, 421, 580, 740, 900, 1073, 1550,
	1780, 2010, 2244, 2650, 3100, 3600]
const GAINS := {"max_hp": 6, "max_mp": 3, "attack": 2, "defense": 1, "speed": 1}


## Raises every level the hero's EXP allows. Returns one LEVEL_UP event per level, each
## followed by a LEARN event when that level teaches a spell.
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
		var skill: Skill = hero.learn.get(hero.level)
		if skill != null and hero.find_skill(skill.id) == null:
			hero.skills.append(skill)
			events.append(BattleEvent.learn(skill.display_name))
	return events


## Gives the hero every spell of `learn` up to their level (after loading a game).
static func sync_skills(hero: Combatant) -> void:
	var levels := hero.learn.keys()
	levels.sort()
	for level: int in levels:
		var skill: Skill = hero.learn[level]
		if level <= hero.level and hero.find_skill(skill.id) == null:
			hero.skills.append(skill)


## Total EXP needed for the next level, or -1 at MAX_LEVEL.
static func exp_for_next(level: int) -> int:
	return EXP_TABLE[level] if level < MAX_LEVEL else -1
