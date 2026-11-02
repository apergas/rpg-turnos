class_name BattleEngine extends RefCounted
## Pure turn-based battle rules (Dragon Quest style rounds). Resolves one round at a
## time and returns the events that happened; never touches nodes. Mutates the
## Combatants it is given, so callers pass duplicates of the data files.

enum State { ONGOING, WON, LOST }

const CMD_ATTACK := "attack"

const MISS_CHANCE := 0.05
const CRIT_CHANCE := 1.0 / 16.0
const CRIT_MULT := 1.5
const DAMAGE_SPREAD := Vector2(0.875, 1.125)
const INITIATIVE_SPREAD := Vector2(0.5, 1.5)

var hero: Combatant
var enemy: Combatant
var state := State.ONGOING

var _rng: RandomNumberGenerator


func _init(p_hero: Combatant, p_enemy: Combatant, rng: RandomNumberGenerator) -> void:
	hero = p_hero
	enemy = p_enemy
	_rng = rng


## Resolves a full round with the hero's command (the enemy always attacks).
## Returns an empty array once the battle is over.
func resolve_round(hero_cmd: String) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if state != State.ONGOING:
		return events
	assert(hero_cmd == CMD_ATTACK, "Unknown command: %s" % hero_cmd)
	for side in _turn_order():
		var target_side := _other(side)
		if not _fighter(side).is_alive():
			continue
		_attack(side, target_side, events)
		if not _fighter(target_side).is_alive():
			break
	if not enemy.is_alive():
		state = State.WON
		hero.experience += enemy.exp_reward
		events.append(BattleEvent.victory(enemy.exp_reward))
	elif not hero.is_alive():
		state = State.LOST
		events.append(BattleEvent.defeat())
	return events


func _turn_order() -> Array[String]:
	var hero_roll := hero.speed * _rng.randf_range(INITIATIVE_SPREAD.x, INITIATIVE_SPREAD.y)
	var enemy_roll := enemy.speed * _rng.randf_range(INITIATIVE_SPREAD.x, INITIATIVE_SPREAD.y)
	if hero_roll >= enemy_roll:
		return [BattleEvent.HERO, BattleEvent.ENEMY]
	return [BattleEvent.ENEMY, BattleEvent.HERO]


func _attack(side: String, target_side: String, events: Array[Dictionary]) -> void:
	events.append(BattleEvent.attack(side, target_side))
	if _rng.randf() < MISS_CHANCE:
		events.append(BattleEvent.miss(side, target_side))
		return
	var target := _fighter(target_side)
	var crit := _rng.randf() < CRIT_CHANCE
	var amount := _roll_damage(_fighter(side), target, crit)
	target.hp = maxi(target.hp - amount, 0)
	events.append(BattleEvent.damage(target_side, amount, crit, target.hp))
	if target.hp == 0:
		events.append(BattleEvent.defeated(target_side))


func _roll_damage(attacker: Combatant, defender: Combatant, crit: bool) -> int:
	var base: float
	if crit:
		base = attacker.attack * CRIT_MULT
	else:
		base = maxf(1.0, attacker.attack - defender.defense / 2.0)
	return maxi(1, roundi(base * _rng.randf_range(DAMAGE_SPREAD.x, DAMAGE_SPREAD.y)))


func _fighter(side: String) -> Combatant:
	return hero if side == BattleEvent.HERO else enemy


func _other(side: String) -> String:
	return BattleEvent.ENEMY if side == BattleEvent.HERO else BattleEvent.HERO
