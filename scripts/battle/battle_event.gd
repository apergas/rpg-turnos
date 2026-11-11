class_name BattleEvent extends RefCounted
## Event dictionaries produced by BattleEngine (and Leveling) and played back by the
## battle scene. Every event has a "type". Fighters are ints: HERO (-1) or the index of
## an enemy in BattleEngine.enemies (0, 1, ...).

const ATTACK := "attack"
const MISS := "miss"
const DAMAGE := "damage"
const DEFEATED := "defeated"
const VICTORY := "victory"
const GOLD := "gold"
const DEFEAT := "defeat"
const SKILL := "skill"
const ITEM := "item"
const HEAL := "heal"
const MP_HEAL := "mp_heal"
const STAGGER := "stagger"
const LEVEL_UP := "level_up"
const LEARN := "learn"
const DROP := "drop"
const DEFEND := "defend"
const FLEE_OK := "flee_ok"
const FLEE_FAIL := "flee_fail"
const STATUS_ON := "status_on"
const STATUS_TICK := "status_tick"
const STATUS_OFF := "status_off"
const ASLEEP := "asleep"
const STUNNED := "stunned"
const CALL_HELP := "call_help"
const CHARGE := "charge"
const PHASE := "phase"
const ENEMY_FLEE := "enemy_flee"
const REVIVE := "revive"
const WAKE_GUARD := "wake_guard"
const NO_SLEEP := "no_sleep"
const IMMUNE := "immune"

const HERO := -1
## The creature fighting beside the hero.
const ALLY := -2
## Values of DAMAGE "affinity": the target is weak to / resists the spell's element.
const WEAK := "weak"
const RESIST := "resist"


## charged: the blow after a charge (CHARGE_MULT damage, never misses).
static func attack(actor: int, target: int, charged := false) -> Dictionary:
	return {"type": ATTACK, "actor": actor, "target": target, "charged": charged}


static func miss(actor: int, target: int) -> Dictionary:
	return {"type": MISS, "actor": actor, "target": target}


## magic is true for spell damage (played back with the spell's ball); affinity is "",
## WEAK or RESIST.
static func damage(target: int, amount: int, crit: bool, hp_left: int, magic := false, \
		affinity := "") -> Dictionary:
	return {"type": DAMAGE, "target": target, "amount": amount, "crit": crit,
		"hp_left": hp_left, "magic": magic, "affinity": affinity}


static func defeated(target: int) -> Dictionary:
	return {"type": DEFEATED, "target": target}


static func victory(amount: int) -> Dictionary:
	return {"type": VICTORY, "exp": amount}


static func gold(amount: int) -> Dictionary:
	return {"type": GOLD, "amount": amount}


static func defeat() -> Dictionary:
	return {"type": DEFEAT}


## targets: every fighter the spell aims at (the caster itself for a heal).
static func skill(actor: int, targets: Array[int], skill_name: String, mp_left: int, \
		color := Color(1.0, 0.45, 0.1)) -> Dictionary:
	return {"type": SKILL, "actor": actor, "targets": targets, "name": skill_name,
		"mp_left": mp_left, "color": color}


static func item(actor: int, item_id: String) -> Dictionary:
	return {"type": ITEM, "actor": actor, "item": item_id}


static func heal(target: int, amount: int, hp_left: int) -> Dictionary:
	return {"type": HEAL, "target": target, "amount": amount, "hp_left": hp_left}


static func mp_heal(target: int, amount: int, mp_left: int) -> Dictionary:
	return {"type": MP_HEAL, "target": target, "amount": amount, "mp_left": mp_left}


static func stagger(actor: int) -> Dictionary:
	return {"type": STAGGER, "actor": actor}


## gains holds the stat increases of one level (see Leveling.GAINS); hp, max_hp, mp and
## max_mp are the hero's values right after that level, so several level ups in a row
## each show their own numbers.
static func level_up(level: int, gains: Dictionary, hero: Combatant) -> Dictionary:
	return {"type": LEVEL_UP, "level": level, "gains": gains, "hp": hero.hp,
		"max_hp": hero.max_hp, "mp": hero.mp, "max_mp": hero.max_mp}


static func learn(skill_name: String, replaced_name := "") -> Dictionary:
	return {"type": LEARN, "name": skill_name, "replaced": replaced_name}


## owner: the enemy that left it. progress: "(n/m)" for a quest item ("" for the rest).
static func drop(item_id: String, owner: int, progress := "") -> Dictionary:
	return {"type": DROP, "item": item_id, "owner": owner, "progress": progress}


static func defend(actor: int) -> Dictionary:
	return {"type": DEFEND, "actor": actor}


static func flee_ok() -> Dictionary:
	return {"type": FLEE_OK}


static func flee_fail() -> Dictionary:
	return {"type": FLEE_FAIL}


static func status_on(target: int, status: String) -> Dictionary:
	return {"type": STATUS_ON, "target": target, "status": status}


## Damage of a status at the end of the round (poison).
static func status_tick(target: int, status: String, amount: int, hp_left: int) -> Dictionary:
	return {"type": STATUS_TICK, "target": target, "status": status, "amount": amount,
		"hp_left": hp_left}


static func status_off(target: int, status: String) -> Dictionary:
	return {"type": STATUS_OFF, "target": target, "status": status}


## The fighter is asleep and loses its turn.
static func asleep(actor: int) -> Dictionary:
	return {"type": ASLEEP, "actor": actor}


## The fighter is still stunned by a blow and loses its turn.
static func stunned(actor: int) -> Dictionary:
	return {"type": STUNNED, "actor": actor}


## helper: index of the new enemy in BattleEngine.enemies.
static func call_help(actor: int, helper: int) -> Dictionary:
	return {"type": CALL_HELP, "actor": actor, "helper": helper}


## The enemy gathers strength: its next turn is a charged blow.
static func charge(actor: int) -> Dictionary:
	return {"type": CHARGE, "actor": actor}


## The enemy runs away: the battle is over, with nothing won.
static func enemy_flee(actor: int) -> Dictionary:
	return {"type": ENEMY_FLEE, "actor": actor}


## A boss reached 0 HP and rises in its next phase with hp_left HP, saying line ("" for the
## fog's).
static func phase(target: int, hp_left: int, line := "") -> Dictionary:
	return {"type": PHASE, "target": target, "hp_left": hp_left, "line": line}


## The Pluma de fénix burnt: the fighter (the hero) rises with hp_left HP, cured.
static func revive(target: int, hp_left: int) -> Dictionary:
	return {"type": REVIVE, "target": target, "hp_left": hp_left}


## The Despertador worked: the fighter (the hero) can't fall asleep until the battle ends.
static func wake_guard(target: int) -> Dictionary:
	return {"type": WAKE_GUARD, "target": target}


## A sleep spell or blow found the fighter guarded by the Despertador: it fails.
static func no_sleep(target: int) -> Dictionary:
	return {"type": NO_SLEEP, "target": target}


## A status found the fighter immune through what it wears (poison or silence; sleep says
## no_sleep()): it fails.
static func immune(target: int, status: String) -> Dictionary:
	return {"type": IMMUNE, "target": target, "status": status}
