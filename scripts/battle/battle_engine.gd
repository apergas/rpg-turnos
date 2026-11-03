class_name BattleEngine extends RefCounted
## Pure turn-based battle rules (Dragon Quest style rounds). Resolves one round at a
## time and returns the events that happened; never touches nodes. Mutates the
## Combatants and the Inventory it is given: the hero and the inventory belong to the
## session, the enemy is a duplicate of its data file.
##
## Commands are dictionaries built with cmd_attack(), cmd_skill() and cmd_item(). The
## enemy picks its own command each round from its ai_weights.

enum State { ONGOING, WON, LOST }

const CMD_ATTACK := "attack"
const CMD_SKILL := "skill"
const CMD_ITEM := "item"
const CMD_STAGGER := "stagger"

const MISS_CHANCE := 0.05
const CRIT_CHANCE := 1.0 / 16.0
const CRIT_MULT := 1.5
const DAMAGE_SPREAD := Vector2(0.875, 1.125)
const INITIATIVE_SPREAD := Vector2(0.5, 1.5)

var hero: Combatant
var enemy: Combatant
var inventory: Inventory
var state := State.ONGOING

var _rng: RandomNumberGenerator


func _init(p_hero: Combatant, p_enemy: Combatant, rng: RandomNumberGenerator, \
		p_inventory: Inventory) -> void:
	hero = p_hero
	enemy = p_enemy
	_rng = rng
	inventory = p_inventory


static func cmd_attack() -> Dictionary:
	return {"type": CMD_ATTACK}


static func cmd_skill(skill: Skill) -> Dictionary:
	return {"type": CMD_SKILL, "skill": skill}


static func cmd_item(id: String) -> Dictionary:
	return {"type": CMD_ITEM, "item": id}


## True if the hero can use the command right now (enough MP; item in stock and HP to
## heal).
func can_use(cmd: Dictionary) -> bool:
	match cmd.type:
		CMD_ATTACK:
			return true
		CMD_SKILL:
			return hero.mp >= (cmd.skill as Skill).mp_cost
		CMD_ITEM:
			return inventory.count(cmd.item) > 0 and hero.hp < hero.max_hp
	return false


## Resolves a full round with the hero's command and the enemy's own choice.
## Returns an empty array once the battle is over.
func resolve_round(hero_cmd: Dictionary) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if state != State.ONGOING:
		return events
	assert(can_use(hero_cmd), "Hero can't use command: %s" % hero_cmd)
	var commands := {BattleEvent.HERO: hero_cmd, BattleEvent.ENEMY: _enemy_command()}
	for side in _turn_order():
		if not _fighter(side).is_alive():
			continue
		_act(side, commands[side], events)
		if not hero.is_alive() or not enemy.is_alive():
			break
	if not enemy.is_alive():
		state = State.WON
		hero.experience += enemy.exp_reward
		events.append(BattleEvent.victory(enemy.exp_reward))
		events.append_array(Leveling.apply(hero))
		if _rng.randf() < enemy.potion_drop_chance:
			inventory.add(Inventory.POTION)
			events.append(BattleEvent.drop(Inventory.POTION))
	elif not hero.is_alive():
		state = State.LOST
		events.append(BattleEvent.defeat())
	return events


## Weighted pick from the enemy's ai_weights; a skill it can't afford becomes an attack.
func _enemy_command() -> Dictionary:
	var weights: Dictionary = enemy.ai_weights
	if weights.is_empty():
		return cmd_attack()
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
			return cmd_attack()
		CMD_STAGGER:
			return {"type": CMD_STAGGER}
	var skill := enemy.find_skill(choice)
	if skill != null and enemy.mp >= skill.mp_cost:
		return cmd_skill(skill)
	return cmd_attack()


func _turn_order() -> Array[String]:
	var hero_roll := hero.speed * _rng.randf_range(INITIATIVE_SPREAD.x, INITIATIVE_SPREAD.y)
	var enemy_roll := enemy.speed * _rng.randf_range(INITIATIVE_SPREAD.x, INITIATIVE_SPREAD.y)
	if hero_roll >= enemy_roll:
		return [BattleEvent.HERO, BattleEvent.ENEMY]
	return [BattleEvent.ENEMY, BattleEvent.HERO]


func _act(side: String, cmd: Dictionary, events: Array[Dictionary]) -> void:
	var target_side := _other(side)
	match cmd.type:
		CMD_ATTACK:
			_attack(side, target_side, events)
		CMD_SKILL:
			_cast(side, target_side, cmd.skill, events)
		CMD_ITEM:
			_use_item(side, cmd.item, events)
		CMD_STAGGER:
			events.append(BattleEvent.stagger(side))


func _attack(side: String, target_side: String, events: Array[Dictionary]) -> void:
	events.append(BattleEvent.attack(side, target_side))
	if _rng.randf() < MISS_CHANCE:
		events.append(BattleEvent.miss(side, target_side))
		return
	var crit := _rng.randf() < CRIT_CHANCE
	var amount := _roll_damage(_fighter(side), _fighter(target_side), crit)
	_hurt(target_side, amount, crit, false, events)


## Spells pay their MP, ignore DEF and never miss or crit.
func _cast(side: String, target_side: String, skill: Skill, events: Array[Dictionary]) -> void:
	var caster := _fighter(side)
	caster.mp -= skill.mp_cost
	events.append(BattleEvent.skill(side, target_side, skill.display_name, caster.mp, skill.color))
	var amount := maxi(1, roundi(skill.power * _rng.randf_range(DAMAGE_SPREAD.x, DAMAGE_SPREAD.y)))
	_hurt(target_side, amount, false, true, events)


## The potion is the only item: it heals POTION_HEAL HP without going over the max.
func _use_item(side: String, id: String, events: Array[Dictionary]) -> void:
	var user := _fighter(side)
	inventory.take(id)
	events.append(BattleEvent.item(side, Inventory.display_name(id)))
	var amount := mini(Inventory.POTION_HEAL, user.max_hp - user.hp)
	user.hp += amount
	events.append(BattleEvent.heal(side, amount, user.hp))


func _hurt(target_side: String, amount: int, crit: bool, magic: bool, \
		events: Array[Dictionary]) -> void:
	var target := _fighter(target_side)
	target.hp = maxi(target.hp - amount, 0)
	events.append(BattleEvent.damage(target_side, amount, crit, target.hp, magic))
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
