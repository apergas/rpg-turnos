class_name BattleEvent extends RefCounted
## Event dictionaries produced by BattleEngine and played back by the battle scene.
## Every event has a "type"; sides are HERO or ENEMY.

const ATTACK := "attack"
const MISS := "miss"
const DAMAGE := "damage"
const DEFEATED := "defeated"
const VICTORY := "victory"
const DEFEAT := "defeat"

const HERO := "hero"
const ENEMY := "enemy"


static func attack(actor: String, target: String) -> Dictionary:
	return {"type": ATTACK, "actor": actor, "target": target}


static func miss(actor: String, target: String) -> Dictionary:
	return {"type": MISS, "actor": actor, "target": target}


static func damage(target: String, amount: int, crit: bool, hp_left: int) -> Dictionary:
	return {"type": DAMAGE, "target": target, "amount": amount, "crit": crit, "hp_left": hp_left}


static func defeated(target: String) -> Dictionary:
	return {"type": DEFEATED, "target": target}


static func victory(amount: int) -> Dictionary:
	return {"type": VICTORY, "exp": amount}


static func defeat() -> Dictionary:
	return {"type": DEFEAT}
