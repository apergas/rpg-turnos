class_name BattleAutoplay extends RefCounted
## Picks the hero's commands for `--autoplay` (and for balance checks) with common
## sense: below HEAL_RATIO of max HP it heals (Curar if it can, else a potion) and, with
## no way to heal, defends below DEFEND_RATIO (never twice in a row); it defends while an
## enemy has charged (its blow comes next and Defender halves it); it cures poison
## with an antidote and refills MP with an ether when it can't heal anymore. Otherwise it
## aims at the enemy with the least HP and casts the spell that hurts most (weaknesses
## count) only when it beats an attack by SPELL_MARGIN, keeping MP for two heals.
## Pure: reads the engine, never touches nodes. Fleeing is the battle scene's choice.

const HEAL_RATIO := 0.4
const DEFEND_RATIO := 0.25
const SPELL_MARGIN := 1.5

var _last_type := ""


func choose(engine: BattleEngine) -> Dictionary:
	var cmd := _pick(engine)
	_last_type = cmd.type
	return cmd


func _pick(engine: BattleEngine) -> Dictionary:
	var hero := engine.hero
	if hero.status.has(BattleEngine.SLEEP):
		return BattleEngine.cmd_none()
	var heal_skill := _heal_skill(hero)
	if hero.hp < hero.max_hp * HEAL_RATIO:
		if heal_skill != null and engine.can_use(BattleEngine.cmd_skill(heal_skill)):
			return BattleEngine.cmd_skill(heal_skill)
		var potion := BattleEngine.cmd_item(Inventory.best_potion(engine.inventory))
		if engine.can_use(potion):
			return potion
		if hero.hp < hero.max_hp * DEFEND_RATIO and _last_type != BattleEngine.CMD_DEFEND:
			return BattleEngine.cmd_defend()
	for i in engine.alive_enemies():
		if engine.is_charged(i):
			return BattleEngine.cmd_defend()
	var antidote := BattleEngine.cmd_item(Inventory.ANTIDOTE)
	if engine.can_use(antidote):
		return antidote
	var ether_id := Inventory.BIG_ETHER if engine.inventory.count(Inventory.BIG_ETHER) > 0 \
		else Inventory.ETHER
	var ether := BattleEngine.cmd_item(ether_id)
	if heal_skill != null and hero.mp < heal_skill.mp_cost and engine.can_use(ether):
		return ether
	var target := _weakest(engine)
	var reserve := heal_skill.mp_cost * 2 if heal_skill != null else 0
	var hit := maxf(1.0, hero.total_attack() - engine.enemies[target].total_defense() / 2.0)
	var best: Skill = null
	var best_damage := hit * SPELL_MARGIN
	for skill in hero.skills:
		if skill.kind != Skill.DAMAGE or hero.mp - skill.mp_cost < reserve:
			continue
		if not engine.can_use(BattleEngine.cmd_skill(skill, target)):
			continue
		var damage := _spell_damage(engine, skill, target)
		if damage > best_damage and engine.enemies[target].hp > hit:
			best = skill
			best_damage = damage
	if best != null:
		return BattleEngine.cmd_skill(best, target)
	return BattleEngine.cmd_attack(target)


## The strongest heal spell the hero knows, or null.
static func _heal_skill(hero: Combatant) -> Skill:
	var best: Skill = null
	for skill in hero.skills:
		if skill.kind == Skill.HEAL and (best == null or skill.power > best.power):
			best = skill
	return best


## The standing enemy with the least HP.
static func _weakest(engine: BattleEngine) -> int:
	var alive := engine.alive_enemies()
	var best: int = alive[0]
	for i in alive:
		if engine.enemies[i].hp < engine.enemies[best].hp:
			best = i
	return best


## Expected damage of a spell: on the target, or on every enemy for ALL spells.
static func _spell_damage(engine: BattleEngine, skill: Skill, target: int) -> float:
	var targets: Array[int] = [target]
	if skill.targets == Skill.ALL:
		targets = engine.alive_enemies()
	var total := 0.0
	for i in targets:
		var enemy := engine.enemies[i]
		var mult := 1.0
		if skill.element != "" and skill.element in enemy.weak:
			mult = BattleEngine.WEAK_MULT
		elif skill.element != "" and skill.element in enemy.resist:
			mult = BattleEngine.RESIST_MULT
		total += minf(skill.power * mult, enemy.hp)
	return total
