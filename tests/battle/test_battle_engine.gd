extends GutTest
## BattleEngine: damage and its spread, defending, the hero's spells growing with his level
## (3.5.0), weaknesses, items before a faster enemy (3.5.0), fleeing, surprises, poison, silence,
## immunity, the Pluma de fénix, a boss's phase, the difficulty, medals and quest items. Every
## roll goes through a seeded generator; a test asserts what holds for every roll (bounds over
## SEEDS seeds, or a rigged fight), never one seed's numbers.

const Fx := preload("res://tests/fixtures.gd")
const SEEDS := 200


func test_a_blow_hurts_within_the_spread_and_a_crit_ignores_defense() -> void:
	var hits := 0
	for s in SEEDS:
		var events := Fx.engine(Fx.fighter("hero", 100, 40), Fx.fighter("foe", 9999, 1, 20), s) \
			.resolve_round(BattleEngine.cmd_attack(0))
		for hit in Fx.hits_on(events, 0):
			hits += 1
			if hit.crit:
				# 40 x CRIT_MULT 1.5 = 60, DEF ignored, x 0.875..1.125
				assert_between(hit.amount, 52, 68, "crit, seed %d" % s)
			else:
				# 40 - 20 / 2 = 30, x 0.875..1.125
				assert_between(hit.amount, 26, 34, "hit, seed %d" % s)
	assert_gt(hits, 150, "MISS_CHANCE is 5 %")


func test_defending_halves_the_blows_taken() -> void:
	var worst_defending := 0
	var worst_open := 0
	for s in SEEDS:
		for defend in [true, false]:
			var foe := Fx.fighter("foe", 9999, 50, 0, 1)
			foe.ai_weights = {BattleEngine.CMD_ATTACK: 1.0}
			var cmd := BattleEngine.cmd_defend() if defend else BattleEngine.cmd_attack(0)
			var events := Fx.engine(Fx.fighter("hero", 9999, 1, 0, 1), foe, s).resolve_round(cmd)
			for hit in Fx.hits_on(events, BattleEvent.HERO):
				if defend:
					worst_defending = maxi(worst_defending, hit.amount)
				else:
					worst_open = maxi(worst_open, hit.amount)
	# A blow of 50 does 44-56, a crit 66-84; halved and rounded up, 42 at most.
	assert_between(worst_defending, 1, 42)
	assert_gt(worst_open, 42)


func test_a_hero_spell_grows_three_percent_a_level_past_the_one_that_taught_it() -> void:
	var fire := Fx.skill("fuego", Skill.DAMAGE, 100, Skill.FIRE)
	var hero := Fx.fighter("hero")
	hero.learn = {7: fire}
	hero.level = 11
	var engine := Fx.engine(hero, Fx.fighter())
	assert_almost_eq(engine.spell_power(BattleEvent.HERO, fire), 112.0, 0.001)
	hero.level = 5
	assert_almost_eq(engine.spell_power(BattleEvent.HERO, fire), 100.0, 0.001,
		"below the level that teaches it: never less")


func test_the_heros_own_spells_grow_from_the_level_that_taught_them() -> void:
	var hero := Fx.new_state().hero
	hero.level = 21
	var engine := Fx.engine(hero, Fx.fighter())
	var ascuas: Skill = Fx.HERO.skills[0]
	var llamarada: Skill = Fx.HERO.learn[7]
	assert_almost_eq(engine.spell_power(BattleEvent.HERO, ascuas), ascuas.power * 1.6, 0.001,
		"Ascuas, from level 1: 20 levels")
	assert_almost_eq(engine.spell_power(BattleEvent.HERO, llamarada), llamarada.power * 1.42,
		0.001, "Llamarada, from level 7: 14 levels")


func test_an_enemys_spell_never_grows() -> void:
	var fire := Fx.skill("fuego", Skill.DAMAGE, 100, Skill.FIRE)
	var foe := Fx.fighter("foe")
	foe.level = 50
	assert_eq(Fx.engine(Fx.fighter("hero"), foe).spell_power(0, fire), 100.0)


func test_a_weakness_takes_half_again_and_a_resistance_half() -> void:
	var fire := Fx.skill("fuego", Skill.DAMAGE, 100, Skill.FIRE)
	for s in 50:
		var weak := Fx.fighter("weak", 9999)
		weak.weak.append(Skill.FIRE)
		var hit: Dictionary = Fx.hits_on(Fx.engine(Fx.fighter("hero"), weak, s).resolve_round(
			BattleEngine.cmd_skill(fire, 0)), 0)[0]
		assert_eq(hit.affinity, BattleEvent.WEAK)
		assert_between(hit.amount, 131, 169, "150 x the spread")
		var tough := Fx.fighter("tough", 9999)
		tough.resist.append(Skill.FIRE)
		hit = Fx.hits_on(Fx.engine(Fx.fighter("hero"), tough, s).resolve_round(
			BattleEngine.cmd_skill(fire, 0)), 0)[0]
		assert_eq(hit.affinity, BattleEvent.RESIST)
		assert_between(hit.amount, 44, 56, "50 x the spread")


func test_an_item_goes_before_a_faster_enemy() -> void:
	var hero := Fx.fighter("hero", 100, 10, 0, 1)
	hero.hp = 50
	var bag := Inventory.new()
	bag.add(Inventory.POTION)
	var events := Fx.engine(hero, Fx.fighter("fast", 100, 1, 0, 999), 3, bag) \
		.resolve_round(BattleEngine.cmd_item(Inventory.POTION))
	assert_eq(events[0].type, BattleEvent.ITEM)
	assert_eq(hero.hp, 80)
	assert_eq(bag.count(Inventory.POTION), 0)


func test_a_blow_waits_for_a_faster_enemy() -> void:
	var events := Fx.engine(Fx.fighter("hero", 100, 10, 0, 1), Fx.fighter("fast", 100, 1, 0, 999)) \
		.resolve_round(BattleEngine.cmd_attack(0))
	assert_eq(events[0].type, BattleEvent.STAGGER)


func test_the_flee_chance_follows_the_speed_within_its_limits() -> void:
	var even := Fx.engine(Fx.fighter("hero", 100, 10, 0, 8), Fx.fighter("foe", 100, 1, 0, 8))
	assert_almost_eq(even.flee_chance(), BattleEngine.FLEE_BASE, 0.0001)
	var faster := Fx.engine(Fx.fighter("hero", 100, 10, 0, 12), Fx.fighter("foe", 100, 1, 0, 8))
	assert_almost_eq(faster.flee_chance(), 0.7, 0.0001)
	var fastest := Fx.engine(Fx.fighter("hero", 100, 10, 0, 100), Fx.fighter("foe", 100, 1, 0, 0))
	assert_almost_eq(fastest.flee_chance(), BattleEngine.FLEE_MAX, 0.0001)
	var slowest := Fx.engine(Fx.fighter("hero", 100, 10, 0, 0), Fx.fighter("foe", 100, 1, 0, 100))
	assert_almost_eq(slowest.flee_chance(), BattleEngine.FLEE_MIN, 0.0001)


func test_no_fleeing_and_no_surprise_against_a_boss() -> void:
	for s in 50:
		var boss := Fx.fighter("boss")
		boss.is_boss = true
		var engine := Fx.engine(Fx.fighter("hero"), boss, s)
		assert_eq(engine.problem(BattleEngine.cmd_flee()), BattleEngine.NO_ESCAPE_REASON)
		assert_eq(engine.roll_ambush(), BattleEngine.Ambush.NONE)


func test_no_surprise_with_the_metal_slime() -> void:
	for s in 50:
		var engine := Fx.engine(Fx.fighter("hero"), Fx.fighter(EnemyLibrary.METAL_SLIME), s)
		assert_eq(engine.roll_ambush(), BattleEngine.Ambush.NONE)


func test_poison_takes_eight_percent_at_the_end_of_the_round() -> void:
	var venom := Fx.skill("veneno", Skill.STATUS, 0, "", BattleEngine.POISON, 1.0)
	var hero := Fx.fighter("hero", 100)
	var ticks := Fx.of_type(Fx.engine(hero, Fx.caster(venom)).resolve_round(
		BattleEngine.cmd_defend()), BattleEvent.STATUS_TICK)
	assert_true(hero.status.has(BattleEngine.POISON))
	assert_eq(ticks.size(), 1)
	assert_eq(ticks[0].amount, 8)
	assert_eq(hero.hp, 92)


func test_easy_takes_less_poison() -> void:
	var venom := Fx.skill("veneno", Skill.STATUS, 0, "", BattleEngine.POISON, 1.0)
	var hero := Fx.fighter("hero", 100)
	var engine := Fx.engine(hero, Fx.caster(venom))
	engine.damage_mult = Difficulty.damage_mult(Difficulty.EASY)
	engine.resolve_round(BattleEngine.cmd_defend())
	assert_eq(hero.hp, 94, "8 x 0.7 = 5.6, rounded to 6")


func test_gear_that_keeps_poison_away_says_so() -> void:
	var venom := Fx.skill("veneno", Skill.STATUS, 0, "", BattleEngine.POISON, 1.0)
	var hero := Fx.fighter("hero", 100)
	hero.equip_immune.append(BattleEngine.POISON)
	var events := Fx.engine(hero, Fx.caster(venom)).resolve_round(BattleEngine.cmd_defend())
	assert_eq(Fx.of_type(events, BattleEvent.IMMUNE).size(), 1)
	assert_false(hero.status.has(BattleEngine.POISON))
	assert_eq(hero.hp, 100)


func test_silence_lasts_three_whole_rounds() -> void:
	var hush := Fx.skill("mudez", Skill.STATUS, 0, "", BattleEngine.SILENCE, 1.0, 5)
	var foe := Fx.caster(hush)
	foe.mp = 5  # one cast, then blows of 1
	var fire := Fx.skill("fuego", Skill.DAMAGE, 1)
	var engine := Fx.engine(Fx.fighter("hero", 9999), foe)
	for i in BattleEngine.SILENCE_ROUNDS:
		engine.resolve_round(BattleEngine.cmd_defend())
		assert_eq(engine.problem(BattleEngine.cmd_skill(fire, 0)), "Silencio",
			"after round %d" % (i + 1))
	engine.resolve_round(BattleEngine.cmd_defend())
	assert_eq(engine.problem(BattleEngine.cmd_skill(fire, 0)), "")


func test_the_phoenix_feather_lifts_the_hero_once_a_battle() -> void:
	var blast := Fx.skill("estallido", Skill.DAMAGE, 500)
	var hero := Fx.fighter("hero", 100)
	var bag := Inventory.new()
	bag.add(Inventory.PHOENIX, 2)
	var engine := Fx.engine(hero, Fx.caster(blast), 1, bag)
	var first := engine.resolve_round(BattleEngine.cmd_defend())
	assert_eq(Fx.of_type(first, BattleEvent.REVIVE).size(), 1)
	assert_eq(hero.hp, 50, "half his HP, rounded up")
	assert_eq(bag.count(Inventory.PHOENIX), 1)
	assert_eq(engine.state, BattleEngine.State.ONGOING)
	engine.resolve_round(BattleEngine.cmd_defend())
	assert_eq(engine.state, BattleEngine.State.LOST)
	assert_eq(bag.count(Inventory.PHOENIX), 1, "only one burns in a battle")


func test_a_boss_with_a_next_phase_rises_once_and_then_falls() -> void:
	var boss := Fx.fighter("boss", 1)
	boss.is_boss = true
	boss.next_phase = Fx.fighter("boss_2", 50)
	var bolt := Fx.skill("rayo", Skill.DAMAGE, 100)
	var engine := Fx.engine(Fx.fighter("hero", 100, 10, 0, 50), boss)
	var events := engine.resolve_round(BattleEngine.cmd_skill(bolt, 0))
	assert_eq(Fx.of_type(events, BattleEvent.PHASE).size(), 1)
	assert_eq(boss.hp, 50)
	assert_null(boss.next_phase)
	assert_eq(engine.state, BattleEngine.State.ONGOING)
	engine.resolve_round(BattleEngine.cmd_skill(bolt, 0))
	assert_eq(engine.state, BattleEngine.State.WON)


func test_easy_wins_a_quarter_more_exp_and_the_same_gold() -> void:
	var foe := Fx.fighter("foe", 1)
	foe.exp_reward = 8
	foe.gold_reward = 7
	var hero := Fx.fighter("hero")
	var engine := Fx.engine(hero, foe)
	engine.exp_mult = Difficulty.exp_mult(Difficulty.EASY)
	engine.resolve_round(BattleEngine.cmd_skill(Fx.skill("rayo", Skill.DAMAGE, 100), 0))
	assert_eq(engine.state, BattleEngine.State.WON)
	assert_eq(engine.exp_won, 10)
	assert_eq(engine.gold_won, 7)
	assert_eq(hero.experience, 10)


func test_the_metal_slime_always_leaves_a_medal_and_a_boss_never() -> void:
	var bolt := Fx.skill("rayo", Skill.DAMAGE, 100)
	var engine := Fx.engine(Fx.fighter("hero"), Fx.fighter(EnemyLibrary.METAL_SLIME, 1))
	engine.medals_carried = 0
	engine.resolve_round(BattleEngine.cmd_skill(bolt, 0))
	assert_eq(engine.medals_won, 1)
	var boss := Fx.fighter("boss", 1)
	boss.is_boss = true
	engine = Fx.engine(Fx.fighter("hero"), boss)
	engine.medals_carried = 0
	engine.medal_chance = 1.0
	engine.resolve_round(BattleEngine.cmd_skill(bolt, 0))
	assert_eq(engine.medals_won, 0)
	engine = Fx.engine(Fx.fighter("hero"), Fx.fighter(EnemyLibrary.METAL_SLIME, 1))
	engine.medals_carried = Medals.MEDALS.size()
	engine.resolve_round(BattleEngine.cmd_skill(bolt, 0))
	assert_eq(engine.medals_won, 0, "all forty carried")


func test_a_quest_item_drops_always_while_wanted_and_never_otherwise() -> void:
	var bolt := Fx.skill("rayo", Skill.DAMAGE, 100)
	var monkey := Fx.fighter("mono", 1)
	monkey.drops = {Inventory.PIEL_MONO: 0.01}
	var bag := Inventory.new()
	var engine := Fx.engine(Fx.fighter("hero"), monkey, 1, bag)
	engine.quest_items = {Inventory.PIEL_MONO: 4}
	engine.resolve_round(BattleEngine.cmd_skill(bolt, 0))
	assert_eq(bag.count(Inventory.PIEL_MONO), 1)
	var other := Fx.fighter("mono", 1)
	other.drops = {Inventory.PIEL_MONO: 1.0}
	var empty := Inventory.new()
	Fx.engine(Fx.fighter("hero"), other, 1, empty).resolve_round(
		BattleEngine.cmd_skill(bolt, 0))
	assert_eq(empty.count(Inventory.PIEL_MONO), 0, "no quest asks for it")
