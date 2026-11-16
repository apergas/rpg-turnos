extends GutTest
## Leveling: the EXP table, the gains, the spells learned and replaced, and the caps of each part
## (20, 40, 55; 60 from 3.8.0 to 3.9.0) with the EXP clamped at a cap (before 3.8.0 a v3 hero lost
## every point past 44600), and a hero of an older save past the top brought down to it.

const Fx := preload("res://tests/fixtures.gd")


func test_exp_raises_every_level_it_reaches_and_teaches_its_spells() -> void:
	var hero := Fx.new_state().hero
	hero.experience = Leveling.EXP_TABLE[2]
	var events := Leveling.apply(hero)
	assert_eq(hero.level, 3)
	assert_eq(Fx.of_type(events, BattleEvent.LEVEL_UP).size(), 2)
	assert_eq(Fx.of_type(events, BattleEvent.LEARN).size(), 1)
	assert_not_null(hero.find_skill("curar"))
	assert_eq(hero.max_hp, Fx.HERO.max_hp + 2 * Leveling.GAINS.max_hp)
	assert_eq(hero.hp, hero.max_hp, "the HP go up with the maximum")
	assert_eq(hero.attack, Fx.HERO.attack + 2 * Leveling.GAINS.attack)


func test_a_spell_that_replaces_another_takes_its_place() -> void:
	var hero := Fx.new_state().hero
	hero.experience = Leveling.EXP_TABLE[6]
	var learned := Fx.of_type(Leveling.apply(hero), BattleEvent.LEARN)
	assert_eq(hero.level, 7)
	assert_not_null(hero.find_skill("llamarada"))
	assert_null(hero.find_skill("llama"), "Llamarada replaces Ascuas")
	assert_eq(learned.back().replaced, "Ascuas")


func test_the_v1_hero_stops_at_20_with_the_exp_clamped() -> void:
	var hero := Fx.state_in_part(1).hero
	hero.experience = 999999
	Leveling.apply(hero)
	assert_eq(hero.level, Leveling.V1_MAX_LEVEL)
	assert_eq(hero.experience, Leveling.EXP_TABLE[Leveling.V1_MAX_LEVEL - 1])
	assert_eq(Leveling.exp_text(hero), "EXP %d" % hero.experience)
	assert_eq(Leveling.exp_for_next(hero.level, hero.level_cap), -1)


func test_the_caravans_hero_stops_at_40() -> void:
	var hero := Fx.state_in_part(2).hero
	hero.experience = 999999
	Leveling.apply(hero)
	assert_eq(hero.level, Leveling.V2_MAX_LEVEL)
	assert_eq(hero.experience, Leveling.EXP_TABLE[Leveling.V2_MAX_LEVEL - 1])
	assert_false(Leveling.at_max(hero), "40 is not the game's top")


func test_brumaclaras_hero_reaches_55_the_top() -> void:
	var hero := Fx.state_in_part(3).hero
	hero.experience = 999999
	Leveling.apply(hero)
	assert_eq(hero.level, Leveling.MAX_LEVEL)
	assert_eq(hero.experience, Leveling.EXP_TABLE[Leveling.MAX_LEVEL - 1])
	assert_true(Leveling.at_max(hero))


func test_lifting_the_cap_goes_on_from_the_threshold() -> void:
	var state := Fx.state_in_part(1)
	state.hero.experience = 999999
	Leveling.apply(state.hero)
	state.world_flags = Fx.PART_2.duplicate()
	state.sync_level_cap()
	state.hero.experience += 600
	Leveling.apply(state.hero)
	assert_eq(state.hero.level, 21, "3600 + 600 reaches 4150, not 4750")


func test_the_exp_table_has_one_entry_per_level_and_always_grows() -> void:
	assert_eq(Leveling.EXP_TABLE.size(), Leveling.MAX_LEVEL)
	assert_eq(Leveling.EXP_TABLE[0], 0)
	for i in range(1, Leveling.EXP_TABLE.size()):
		assert_gt(Leveling.EXP_TABLE[i], Leveling.EXP_TABLE[i - 1], "level %d" % (i + 1))


func test_from_level_51_each_level_asks_100_more_than_the_last() -> void:
	for i in range(51, Leveling.MAX_LEVEL):
		var step: int = Leveling.EXP_TABLE[i] - Leveling.EXP_TABLE[i - 1]
		var before: int = Leveling.EXP_TABLE[i - 1] - Leveling.EXP_TABLE[i - 2]
		assert_eq(step - before, 100, "level %d" % (i + 1))


# 3.10.0 (M-125): the v3's top went from 60 down to 55.
func test_the_exp_table_stops_at_the_top_level_55() -> void:
	assert_eq(Leveling.MAX_LEVEL, 55)
	assert_eq(Leveling.EXP_TABLE.back(), 58600)


# 3.10.0 (M-125): a hero of 56 to 60 from an older save comes down with a 55's numbers.
func test_a_hero_past_the_top_comes_down_to_it_with_that_levels_numbers() -> void:
	var top := Fx.state_in_part(3).hero
	Leveling.set_level(top, Leveling.MAX_LEVEL, Fx.HERO.skills)
	var hero := Fx.state_in_part(3).hero
	Leveling.set_level(hero, Leveling.MAX_LEVEL, Fx.HERO.skills)
	var extra := 3
	hero.level += extra
	hero.hp += extra * Leveling.GAINS.max_hp
	hero.mp += extra * Leveling.GAINS.max_mp
	for field: String in Leveling.GAINS:
		hero.set(field, hero.get(field) + extra * Leveling.GAINS[field])
	hero.experience = 999999
	Leveling.lower_to_max(hero)
	assert_eq(hero.level, Leveling.MAX_LEVEL)
	assert_eq(hero.experience, Leveling.EXP_TABLE[Leveling.MAX_LEVEL - 1])
	for field in ["max_hp", "max_mp", "attack", "defense", "speed", "hp", "mp"]:
		assert_eq(hero.get(field), top.get(field), field)
	assert_not_null(hero.find_skill("alba"), "the spells stay")
	var before := top.experience
	Leveling.lower_to_max(top)
	assert_eq(top.level, Leveling.MAX_LEVEL, "a hero at the top stays")
	assert_eq(top.experience, before)


func test_a_hand_edited_hero_with_small_numbers_comes_down_without_going_negative() -> void:
	var hero := Fx.new_state().hero
	hero.level = SaveData.OLD_MAX_LEVEL
	for field: String in Leveling.GAINS:
		hero.set(field, 1)
	hero.hp = 1
	hero.mp = 1
	Leveling.lower_to_max(hero)
	assert_eq(hero.level, Leveling.MAX_LEVEL)
	for field in ["max_hp", "max_mp", "attack", "defense", "speed", "hp"]:
		assert_gte(hero.get(field), 1, field)
	assert_gte(hero.mp, 0)


func test_set_level_clamps_and_gives_that_levels_spells() -> void:
	var hero := Fx.new_state().hero
	Leveling.set_level(hero, 99, Fx.HERO.skills)
	assert_eq(hero.level, Leveling.MAX_LEVEL)
	assert_eq(hero.experience, Leveling.EXP_TABLE[Leveling.MAX_LEVEL - 1])
	assert_eq(hero.max_hp, Fx.HERO.max_hp + (Leveling.MAX_LEVEL - 1) * Leveling.GAINS.max_hp)
	assert_not_null(hero.find_skill("alba"), "taught at 45")
	Leveling.set_level(hero, 0, Fx.HERO.skills)
	assert_eq(hero.level, 1)
	assert_eq(hero.max_hp, Fx.HERO.max_hp)
	assert_null(hero.find_skill("alba"))


func test_the_exp_line_and_bar_below_the_cap() -> void:
	var hero := Fx.new_state().hero
	hero.experience = 6
	assert_eq(Leveling.exp_text(hero), "EXP 6/12")
	assert_almost_eq(Leveling.exp_ratio(hero), 0.5, 0.0001)
