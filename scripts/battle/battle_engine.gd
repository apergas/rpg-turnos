class_name BattleEngine extends RefCounted
## Pure turn-based battle rules (Dragon Quest style rounds): the hero against one or more
## enemies. Resolves one round at a time and returns the events that happened; never
## touches nodes. Mutates the Combatants and the Inventory it is given: the hero and the
## inventory belong to the session, the enemies are duplicates of their data files.
##
## Commands are dictionaries built with cmd_attack(target), cmd_skill(skill, target),
## cmd_item(id), cmd_defend(), cmd_flee() and cmd_none() (the hero is asleep). Each enemy
## picks its own command when its turn comes, from its ai_weights. Fighters are ints:
## BattleEvent.HERO or an index into `enemies`. An enemy that picks "charge" spends its
## turn gathering strength and its next turn is a blow of CHARGE_MULT times the damage
## that never misses or crits (Defender still halves it).

enum State { ONGOING, WON, LOST, FLED }

const CMD_ATTACK := "attack"
const CMD_SKILL := "skill"
const CMD_ITEM := "item"
const CMD_DEFEND := "defend"
const CMD_FLEE := "flee"
const CMD_NONE := "none"
const CMD_STAGGER := "stagger"
const CMD_CALL := "call"
const CMD_CHARGE := "charge"

const POISON := "poison"
const SLEEP := "sleep"
const SILENCE := "silence"

const MISS_CHANCE := 0.05
const CRIT_CHANCE := 1.0 / 16.0
const CRIT_MULT := 1.5
const DAMAGE_SPREAD := Vector2(0.875, 1.125)
const INITIATIVE_SPREAD := Vector2(0.5, 1.5)
const WEAK_MULT := 1.5
const RESIST_MULT := 0.5
## Poison takes this share of max HP at the end of each round.
const POISON_SHARE := 0.08
## Chance of waking up at the end of each round.
const WAKE_CHANCE := 0.5
const SILENCE_ROUNDS := 3
## Flee chance: clamp(FLEE_BASE + (hero speed - mean enemy speed) * FLEE_PER_SPEED).
const FLEE_BASE := 0.5
const FLEE_PER_SPEED := 0.05
const FLEE_MIN := 0.2
const FLEE_MAX := 0.95
## An enemy with `help` calls it below this share of max HP, once per battle.
const HELP_HP_RATIO := 0.5
## Most enemies standing at once (a call for help needs a free place).
const MAX_ENEMIES := 2
## Damage of the blow that follows a charge.
const CHARGE_MULT := 2.0

var hero: Combatant
var enemies: Array[Combatant] = []
var inventory: Inventory
var state := State.ONGOING
## Rewards of a won battle (already given to the hero and the inventory; the gold is
## for the caller to keep).
var exp_won := 0
var gold_won := 0
var drops_won: Array[String] = []

var _rng: RandomNumberGenerator
var _defending := false
## Enemy indexes that already called for help / already cast their rescue heal.
var _called := {}
var _rescued := {}
## Enemy indexes that charged: their next turn is the charged blow.
var _charged := {}


func _init(p_hero: Combatant, p_enemies: Array[Combatant], rng: RandomNumberGenerator, \
		p_inventory: Inventory) -> void:
	hero = p_hero
	enemies = p_enemies
	_rng = rng
	inventory = p_inventory


static func cmd_attack(target: int) -> Dictionary:
	return {"type": CMD_ATTACK, "target": target}


## target: the enemy index for a one-target damage spell; ignored otherwise.
static func cmd_skill(skill: Skill, target := 0) -> Dictionary:
	return {"type": CMD_SKILL, "skill": skill, "target": target}


static func cmd_item(id: String) -> Dictionary:
	return {"type": CMD_ITEM, "item": id}


static func cmd_defend() -> Dictionary:
	return {"type": CMD_DEFEND}


static func cmd_flee() -> Dictionary:
	return {"type": CMD_FLEE}


## The hero's command while asleep: does nothing.
static func cmd_none() -> Dictionary:
	return {"type": CMD_NONE}


## Indexes of the enemies still standing, in order.
func alive_enemies() -> Array[int]:
	var alive: Array[int] = []
	for i in enemies.size():
		if enemies[i].is_alive():
			alive.append(i)
	return alive


## True while enemy who has charged and its blow is still to come.
func is_charged(who: int) -> bool:
	return _charged.has(who)


func has_boss() -> bool:
	for enemy in enemies:
		if enemy.is_boss:
			return true
	return false


## Why the hero can't use cmd right now ("" if he can).
func problem(cmd: Dictionary) -> String:
	match cmd.type:
		CMD_SKILL:
			var skill: Skill = cmd.skill
			if hero.status.has(SILENCE):
				return "Silencio"
			if hero.mp < skill.mp_cost:
				return "Faltan PM"
			if skill.kind == Skill.HEAL and hero.hp >= hero.max_hp:
				return "PV al máximo"
		CMD_ITEM:
			return inventory.problem(cmd.item, hero, true)
	return ""


func can_use(cmd: Dictionary) -> bool:
	return problem(cmd) == ""


func flee_chance() -> float:
	var total := 0.0
	var alive := alive_enemies()
	for i in alive:
		total += enemies[i].speed
	var mean := total / maxf(1.0, alive.size())
	return clampf(FLEE_BASE + (hero.speed - mean) * FLEE_PER_SPEED, FLEE_MIN, FLEE_MAX)


## Resolves a full round with the hero's command and the enemies' own choices. Returns
## an empty array once the battle is over. Fleeing from a boss only returns NO_ESCAPE:
## no turn passes.
func resolve_round(hero_cmd: Dictionary) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if state != State.ONGOING:
		return events
	if hero_cmd.type == CMD_FLEE and has_boss():
		events.append(BattleEvent.no_escape())
		return events
	assert(can_use(hero_cmd), "Hero can't use command: %s" % hero_cmd)
	_defending = hero_cmd.type == CMD_DEFEND
	for who in _turn_order(hero_cmd):
		if state != State.ONGOING:
			break
		var fighter := _fighter(who)
		if not fighter.is_alive():
			continue
		if fighter.status.has(SLEEP):
			events.append(BattleEvent.asleep(who))
			continue
		var cmd := hero_cmd if who == BattleEvent.HERO else _enemy_command(who)
		_act(who, cmd, events)
		_update_state()
	if state == State.ONGOING:
		_end_of_round(events)
		_update_state()
	_defending = false
	match state:
		State.WON:
			_win(events)
		State.LOST:
			events.append(BattleEvent.defeat())
	if state != State.ONGOING:
		hero.status.clear()
		for enemy in enemies:
			enemy.status.clear()
	return events


## Strikes the charged blow if it charged last turn; casts its rescue heal (once, below
## rescue_heal_ratio, not silenced) or calls for help when it can; otherwise a weighted
## pick from its ai_weights. A skill it can't afford (or can't cast, silenced) becomes an
## attack.
func _enemy_command(who: int) -> Dictionary:
	var enemy := enemies[who]
	if _charged.has(who):
		return {"type": CMD_ATTACK, "target": BattleEvent.HERO, "charged": true}
	if enemy.rescue_heal != null and not _rescued.has(who) \
			and enemy.hp < enemy.max_hp * enemy.rescue_heal_ratio \
			and not enemy.status.has(SILENCE):
		_rescued[who] = true
		return cmd_skill(enemy.rescue_heal, who)
	if enemy.help != null and not _called.has(who) \
			and enemy.hp < enemy.max_hp * HELP_HP_RATIO \
			and alive_enemies().size() < MAX_ENEMIES:
		return {"type": CMD_CALL}
	var weights: Dictionary = enemy.ai_weights
	if weights.is_empty():
		return cmd_attack(BattleEvent.HERO)
	var total := 0.0
	for weight in weights.values():
		total += weight
	var roll := _rng.randf() * total
	var choice: String = weights.keys().back()
	for key in weights:
		roll -= weights[key]
		if roll < 0.0:
			choice = key
			break
	match choice:
		CMD_ATTACK:
			return cmd_attack(BattleEvent.HERO)
		CMD_STAGGER:
			return {"type": CMD_STAGGER}
		CMD_CHARGE:
			return {"type": CMD_CHARGE}
	var skill := enemy.find_skill(choice)
	if skill != null and enemy.mp >= skill.mp_cost and not enemy.status.has(SILENCE):
		return cmd_skill(skill, BattleEvent.HERO)
	return cmd_attack(BattleEvent.HERO)


## Everyone standing, fastest roll first (the hero wins ties). Defending or fleeing,
## the hero goes first.
func _turn_order(hero_cmd: Dictionary) -> Array[int]:
	var rolls := []
	rolls.append([_initiative(hero), BattleEvent.HERO])
	for i in alive_enemies():
		rolls.append([_initiative(enemies[i]), i])
	rolls.sort_custom(func(a: Array, b: Array) -> bool:
		return a[0] > b[0] or (a[0] == b[0] and a[1] == BattleEvent.HERO))
	var order: Array[int] = []
	for roll in rolls:
		order.append(roll[1])
	if hero_cmd.type in [CMD_DEFEND, CMD_FLEE]:
		order.erase(BattleEvent.HERO)
		order.push_front(BattleEvent.HERO)
	return order


func _initiative(c: Combatant) -> float:
	return c.speed * _rng.randf_range(INITIATIVE_SPREAD.x, INITIATIVE_SPREAD.y)


func _act(who: int, cmd: Dictionary, events: Array[Dictionary]) -> void:
	match cmd.type:
		CMD_ATTACK:
			_attack(who, _living_target(cmd.target), events, cmd.get("charged", false))
		CMD_SKILL:
			_cast(who, cmd, events)
		CMD_ITEM:
			_use_item(who, cmd.item, events)
		CMD_DEFEND:
			events.append(BattleEvent.defend(who))
		CMD_FLEE:
			if _rng.randf() < flee_chance():
				state = State.FLED
				events.append(BattleEvent.flee_ok())
			else:
				events.append(BattleEvent.flee_fail())
		CMD_STAGGER:
			events.append(BattleEvent.stagger(who))
		CMD_CHARGE:
			_charged[who] = true
			events.append(BattleEvent.charge(who))
		CMD_CALL:
			_called[who] = true
			enemies.append(enemies[who].help.duplicate() as Combatant)
			events.append(BattleEvent.call_help(who, enemies.size() - 1))


## The hero, or the enemy if it still stands, or else the first enemy standing.
func _living_target(target: int) -> int:
	if target == BattleEvent.HERO or _fighter(target).is_alive():
		return target
	return alive_enemies()[0]


## A charged blow (after a charge) never misses or crits and does CHARGE_MULT damage.
func _attack(who: int, target: int, events: Array[Dictionary], charged := false) -> void:
	events.append(BattleEvent.attack(who, target, charged))
	var attacker := _fighter(who)
	if charged:
		_charged.erase(who)
		var amount := roundi(_roll_damage(attacker, _fighter(target), false) * CHARGE_MULT)
		_hurt(target, amount, false, false, "", events)
		return
	if _rng.randf() < MISS_CHANCE:
		events.append(BattleEvent.miss(who, target))
		return
	var crit := _rng.randf() < CRIT_CHANCE
	_hurt(target, _roll_damage(attacker, _fighter(target), crit), crit, false, "", events)
	if attacker.attack_status != "" and _rng.randf() < attacker.attack_status_chance:
		_add_status(target, attacker.attack_status, events)


## Spells pay their MP and never miss or crit. Damage ignores DEF and follows the
## element; a heal restores power HP to the caster.
func _cast(who: int, cmd: Dictionary, events: Array[Dictionary]) -> void:
	var caster := _fighter(who)
	var skill: Skill = cmd.skill
	caster.mp -= skill.mp_cost
	var targets := _skill_targets(who, skill, cmd.target)
	events.append(BattleEvent.skill(who, targets, skill.display_name, caster.mp, skill.color))
	if skill.kind == Skill.HEAL:
		var amount := mini(skill.power, caster.max_hp - caster.hp)
		caster.hp += amount
		events.append(BattleEvent.heal(who, amount, caster.hp))
		return
	for target in targets:
		if not _fighter(target).is_alive():
			continue
		if skill.kind == Skill.DAMAGE:
			var affinity := _affinity(_fighter(target), skill.element)
			var mult := WEAK_MULT if affinity == BattleEvent.WEAK \
				else RESIST_MULT if affinity == BattleEvent.RESIST else 1.0
			var amount := maxi(1, roundi(skill.power * mult \
				* _rng.randf_range(DAMAGE_SPREAD.x, DAMAGE_SPREAD.y)))
			_hurt(target, amount, false, true, affinity, events)
		if skill.status != "" and _rng.randf() < skill.status_chance:
			_add_status(target, skill.status, events)
		elif skill.kind == Skill.STATUS:
			events.append(BattleEvent.miss(who, target))


func _skill_targets(who: int, skill: Skill, target: int) -> Array[int]:
	var targets: Array[int] = []
	if skill.kind == Skill.HEAL:
		targets.append(who)
	elif who != BattleEvent.HERO:
		targets.append(BattleEvent.HERO)
	elif skill.targets == Skill.ALL:
		targets = alive_enemies()
	else:
		targets.append(_living_target(target))
	return targets


func _affinity(target: Combatant, element: String) -> String:
	if element == "":
		return ""
	if element in target.weak:
		return BattleEvent.WEAK
	if element in target.resist:
		return BattleEvent.RESIST
	return ""


func _use_item(who: int, id: String, events: Array[Dictionary]) -> void:
	var user := _fighter(who)
	var result := inventory.use(id, user, true)
	events.append(BattleEvent.item(who, id))
	match result.effect:
		"hp":
			events.append(BattleEvent.heal(who, result.amount, user.hp))
		"mp":
			events.append(BattleEvent.mp_heal(who, result.amount, user.mp))
		"cure":
			events.append(BattleEvent.status_off(who, result.status))


## Defending halves the damage the hero takes (rounded up, at least 1). Damage wakes a
## sleeper up.
func _hurt(target: int, amount: int, crit: bool, magic: bool, affinity: String, \
		events: Array[Dictionary]) -> void:
	var fighter := _fighter(target)
	if target == BattleEvent.HERO and _defending:
		amount = maxi(1, ceili(amount / 2.0))
	fighter.hp = maxi(fighter.hp - amount, 0)
	events.append(BattleEvent.damage(target, amount, crit, fighter.hp, magic, affinity))
	if fighter.hp == 0:
		events.append(BattleEvent.defeated(target))
	elif fighter.status.has(SLEEP):
		fighter.status.erase(SLEEP)
		events.append(BattleEvent.status_off(target, SLEEP))


func _add_status(target: int, status: String, events: Array[Dictionary]) -> void:
	var fighter := _fighter(target)
	if not fighter.is_alive() or fighter.status.has(status):
		return
	# Silence counts down at the end of every round, the one it starts in too, so it
	# gets one extra round to last SILENCE_ROUNDS whole rounds.
	fighter.status[status] = SILENCE_ROUNDS + 1 if status == SILENCE else -1
	events.append(BattleEvent.status_on(target, status))


## Poison hurts, sleepers may wake up and silence counts down.
func _end_of_round(events: Array[Dictionary]) -> void:
	var everyone: Array[int] = [BattleEvent.HERO]
	everyone.append_array(alive_enemies())
	for who in everyone:
		var fighter := _fighter(who)
		if fighter.status.has(POISON) and fighter.is_alive():
			var amount := maxi(1, roundi(fighter.max_hp * POISON_SHARE))
			fighter.hp = maxi(fighter.hp - amount, 0)
			events.append(BattleEvent.status_tick(who, POISON, amount, fighter.hp))
			if fighter.hp == 0:
				events.append(BattleEvent.defeated(who))
				continue
			if fighter.status.has(SLEEP):  # any damage wakes, poison too
				fighter.status.erase(SLEEP)
				events.append(BattleEvent.status_off(who, SLEEP))
		if fighter.status.has(SLEEP) and _rng.randf() < WAKE_CHANCE:
			fighter.status.erase(SLEEP)
			events.append(BattleEvent.status_off(who, SLEEP))
		if fighter.status.has(SILENCE):
			fighter.status[SILENCE] -= 1
			if fighter.status[SILENCE] <= 0:
				fighter.status.erase(SILENCE)
				events.append(BattleEvent.status_off(who, SILENCE))


func _update_state() -> void:
	if state != State.ONGOING:
		return
	if not hero.is_alive():
		state = State.LOST
	elif alive_enemies().is_empty():
		state = State.WON


## EXP, gold, level ups (and spells learned), then each enemy's drop rolls.
func _win(events: Array[Dictionary]) -> void:
	for enemy in enemies:
		exp_won += enemy.exp_reward
		gold_won += enemy.gold_reward
	hero.experience += exp_won
	events.append(BattleEvent.victory(exp_won))
	if gold_won > 0:
		events.append(BattleEvent.gold(gold_won))
	events.append_array(Leveling.apply(hero))
	for i in enemies.size():
		for id: String in enemies[i].drops:
			if _rng.randf() < enemies[i].drops[id]:
				inventory.add(id)
				drops_won.append(id)
				events.append(BattleEvent.drop(id, i))


func _roll_damage(attacker: Combatant, defender: Combatant, crit: bool) -> int:
	var base: float
	if crit:
		base = attacker.total_attack() * CRIT_MULT
	else:
		base = maxf(1.0, attacker.total_attack() - defender.total_defense() / 2.0)
	return maxi(1, roundi(base * _rng.randf_range(DAMAGE_SPREAD.x, DAMAGE_SPREAD.y)))


func _fighter(who: int) -> Combatant:
	return hero if who == BattleEvent.HERO else enemies[who]
