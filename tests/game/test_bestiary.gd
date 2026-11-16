extends GutTest
## Bestiary: the families and cards of each part, a family completed by beating (not seeing)
## every enemy of it, and its prize given once.

const Fx := preload("res://tests/fixtures.gd")


func test_each_part_adds_its_families() -> void:
	assert_eq(Bestiary.families(Fx.state_in_part(1)).size(), 5)
	assert_eq(Bestiary.families(Fx.state_in_part(2)).size(), 9)
	assert_eq(Bestiary.families(Fx.state_in_part(3)).size(), 13)


func test_each_part_adds_its_cards() -> void:
	assert_eq(Bestiary.total_count(Fx.state_in_part(1)), 22)
	assert_eq(Bestiary.total_count(Fx.state_in_part(2)), 47)
	assert_eq(Bestiary.total_count(Fx.state_in_part(3)), 71)


func test_a_family_beaten_whole_gives_its_prize_once() -> void:
	var state := Fx.state_in_part(1)
	for id: String in Bestiary.family("plantas").enemies:
		state.defeat_enemy(id)
	assert_true(Bestiary.is_complete(state, "plantas"))
	assert_eq(Bestiary.new_rewards(state).size(), 1)
	assert_has(Bestiary.new_rewards(state), "plantas")
	assert_string_contains(Bestiary.give(state, "plantas"), "Plantas")
	assert_eq(state.loadout.worn(Equipment.RING), Equipment.SAP_RING)
	assert_true(Bestiary.new_rewards(state).is_empty())


func test_only_beaten_enemies_complete_a_family() -> void:
	var state := Fx.state_in_part(1)
	for id: String in Bestiary.family("plantas").enemies:
		state.see_enemy(id)
	assert_false(Bestiary.is_complete(state, "plantas"))
	assert_eq(Bestiary.beaten_count(state, "plantas"), 0)


func test_the_eco_de_la_niebla_has_no_card() -> void:
	assert_false(Bestiary.has("eco_niebla"))
	assert_eq(Bestiary.family_of("eco_niebla"), "")
	assert_eq(Bestiary.family_of(EnemyLibrary.METAL_SLIME), "magicas")
	assert_true(Bestiary.has("eco_albor"))
