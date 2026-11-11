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
			var replaced := _replace(hero, skill)
			hero.skills.append(skill)
			events.append(BattleEvent.learn(skill.display_name, replaced))
	return events


## Gives the hero every spell of `learn` up to their level (after loading a game).
static func sync_skills(hero: Combatant) -> void:
	var levels := hero.learn.keys()
	levels.sort()
	for level: int in levels:
		var skill: Skill = hero.learn[level]
		if level <= hero.level and hero.find_skill(skill.id) == null:
			_replace(hero, skill)
			hero.skills.append(skill)


## Debug only (DebugPanel): puts the hero at level (clamped to 1..MAX_LEVEL) with that
## level's EXP, one level of GAINS up or down at a time (current HP and MP go along, as on a
## level up, and then stay within 1..max and 0..max), and with that level's spells:
## base_skills (hero.tres's) and those of `learn` up to it, replacing in order
## (sync_skills()). Seeds and equipment stay.
static func set_level(hero: Combatant, level: int, base_skills: Array[Skill]) -> void:
	level = clampi(level, 1, MAX_LEVEL)
	while hero.level != level:
		var step := 1 if level > hero.level else -1
		hero.level += step
		hero.max_hp += GAINS.max_hp * step
		hero.hp += GAINS.max_hp * step
		hero.max_mp += GAINS.max_mp * step
		hero.mp += GAINS.max_mp * step
		hero.attack += GAINS.attack * step
		hero.defense += GAINS.defense * step
		hero.speed += GAINS.speed * step
	hero.hp = clampi(hero.hp, 1, hero.max_hp)
	hero.mp = clampi(hero.mp, 0, hero.max_mp)
	hero.experience = EXP_TABLE[level - 1]
	hero.skills = base_skills.duplicate()
	sync_skills(hero)


## Removes the spell skill replaces from the hero; returns its name ("" if none).
static func _replace(hero: Combatant, skill: Skill) -> String:
	var old: Skill = hero.find_skill(skill.replaces) if skill.replaces != "" else null
	if old == null:
		return ""
	hero.skills.erase(old)
	return old.display_name


## Total EXP needed for the next level, or -1 at MAX_LEVEL.
static func exp_for_next(level: int) -> int:
	return EXP_TABLE[level] if level < MAX_LEVEL else -1


## "EXP 44/62" ("EXP 3600" at MAX_LEVEL).
static func exp_text(hero: Combatant) -> String:
	var next := exp_for_next(hero.level)
	return "EXP %d" % hero.experience if next < 0 else "EXP %d/%d" % [hero.experience, next]


## How far along the current level the hero is, 0..1 (full at MAX_LEVEL).
static func exp_ratio(hero: Combatant) -> float:
	var next := exp_for_next(hero.level)
	if next < 0:
		return 1.0
	var start: int = EXP_TABLE[hero.level - 1]
	return clampf(float(hero.experience - start) / (next - start), 0.0, 1.0)
