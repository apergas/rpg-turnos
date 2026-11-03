class_name BattleEvent extends RefCounted
## Event dictionaries produced by BattleEngine (and Leveling) and played back by the
## battle scene. Every event has a "type"; sides are HERO or ENEMY.

const ATTACK := "attack"
const MISS := "miss"
const DAMAGE := "damage"
const DEFEATED := "defeated"
const VICTORY := "victory"
const DEFEAT := "defeat"
const SKILL := "skill"
const ITEM := "item"
const HEAL := "heal"
const STAGGER := "stagger"
const LEVEL_UP := "level_up"
const DROP := "drop"

const HERO := "hero"
const ENEMY := "enemy"


static func attack(actor: String, target: String) -> Dictionary:
	return {"type": ATTACK, "actor": actor, "target": target}


static func miss(actor: String, target: String) -> Dictionary:
	return {"type": MISS, "actor": actor, "target": target}


## magic is true for spell damage (played back with the fire animation).
static func damage(target: String, amount: int, crit: bool, hp_left: int, \
		magic := false) -> Dictionary:
	return {"type": DAMAGE, "target": target, "amount": amount, "crit": crit,
		"hp_left": hp_left, "magic": magic}


static func defeated(target: String) -> Dictionary:
	return {"type": DEFEATED, "target": target}


static func victory(amount: int) -> Dictionary:
	return {"type": VICTORY, "exp": amount}


static func defeat() -> Dictionary:
	return {"type": DEFEAT}


static func skill(actor: String, target: String, skill_name: String, mp_left: int, \
		color := Color(1.0, 0.45, 0.1)) -> Dictionary:
	return {"type": SKILL, "actor": actor, "target": target, "name": skill_name,
		"mp_left": mp_left, "color": color}


static func item(actor: String, item_name: String) -> Dictionary:
	return {"type": ITEM, "actor": actor, "name": item_name}


static func heal(target: String, amount: int, hp_left: int) -> Dictionary:
	return {"type": HEAL, "target": target, "amount": amount, "hp_left": hp_left}


static func stagger(actor: String) -> Dictionary:
	return {"type": STAGGER, "actor": actor}


## gains holds the stat increases of one level (see Leveling.GAINS).
static func level_up(level: int, gains: Dictionary) -> Dictionary:
	return {"type": LEVEL_UP, "level": level, "gains": gains}


static func drop(item_id: String) -> Dictionary:
	return {"type": DROP, "item": item_id}
