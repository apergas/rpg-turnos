extends GutTest
## Wells: one fills the HP, the other the MP, then it stays dry for RECHARGE_BATTLES battles; a
## full hero uses nothing.

const Fx := preload("res://tests/fixtures.gd")


func test_a_well_fills_the_hp_and_then_stays_dry_for_ten_battles() -> void:
	var state := Fx.new_state()
	state.hero.hp = 1
	assert_eq(Wells.drink(state, "pozo", Wells.HP), Wells.HP_TEXT)
	assert_eq(state.hero.hp, state.hero.max_hp)
	state.hero.hp = 1
	assert_eq(Wells.drink(state, "pozo", Wells.HP), Wells.DRY_TEXT)
	assert_eq(state.hero.hp, 1)
	for i in Wells.RECHARGE_BATTLES - 1:
		Wells.on_battle(state)
	assert_true(Wells.is_dry(state, "pozo"))
	Wells.on_battle(state)
	assert_false(Wells.is_dry(state, "pozo"))
	assert_true(Wells.dry_ids(state).is_empty())


func test_the_mp_well_fills_the_mp() -> void:
	var state := Fx.new_state()
	state.hero.mp = 0
	assert_eq(Wells.drink(state, "pozo", Wells.MP), Wells.MP_TEXT)
	assert_eq(state.hero.mp, state.hero.max_mp)


func test_a_full_hero_does_not_dry_the_well() -> void:
	var state := Fx.new_state()
	assert_eq(Wells.drink(state, "pozo", Wells.MP), Wells.FULL_TEXT)
	assert_false(Wells.is_dry(state, "pozo"))
