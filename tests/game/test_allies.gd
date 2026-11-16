extends GutTest
## Allies: a companion grows at each step and wears its gear from the second; a creature never
## grows; every battle gets a fresh, healed copy.


func test_a_companion_grows_each_step_and_wears_its_gear() -> void:
	var base := Allies.data("brena", 1)
	var grown := Allies.data("brena", 3)
	assert_eq(grown.max_hp, base.max_hp + 2 * int(Allies.GROWTH.brena.max_hp))
	assert_eq(grown.attack, base.attack + 2 * int(Allies.GROWTH.brena.attack))
	assert_eq(grown.equip_attack, 6, "the weapon of step 2")
	assert_eq(grown.equip_defense, 4, "the helmet of step 3")
	assert_eq(grown.hp, grown.max_hp)
	assert_eq(base.equip_attack, 0)


func test_a_creature_never_grows() -> void:
	assert_eq(Allies.data("gallina", 5).max_hp, Allies.data("gallina", 1).max_hp)
	assert_true(Allies.gear("gallina", 5).is_empty())
	assert_false(Allies.is_companion("gallina"))
	assert_eq(Allies.tier(""), 0)


func test_every_battle_gets_a_fresh_copy() -> void:
	var one := Allies.data("ulma", 4)
	one.hp = 1
	var next := Allies.data("ulma", 4)
	assert_eq(next.hp, next.max_hp)
