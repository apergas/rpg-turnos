extends GutTest
## Chests: each opens once, gold to the purse, items to the bag, a piece put on when its slot is
## empty, and how many chests each part has (13, 25, 37).

const Fx := preload("res://tests/fixtures.gd")


func _first_with(key: String) -> String:
	for id: String in Chests.CHESTS:
		if Chests.CHESTS[id].has(key):
			return id
	return ""


func test_a_chest_opens_once() -> void:
	var state := Fx.new_state()
	var id := _first_with("gold")
	var gold: int = Chests.CHESTS[id].gold
	assert_true(Chests.open(state, id).opened)
	assert_eq(state.gold, GameState.START_GOLD + gold)
	assert_false(Chests.open(state, id).opened)
	assert_eq(state.gold, GameState.START_GOLD + gold)


func test_an_item_from_a_chest_goes_to_the_bag() -> void:
	var state := Fx.new_state()
	var id := _first_with("item")
	var item: String = Chests.CHESTS[id].item
	var before := state.inventory.count(item)
	Chests.open(state, id)
	assert_eq(state.inventory.count(item), before + 1)


func test_a_piece_from_a_chest_goes_on_when_its_slot_is_empty() -> void:
	var state := Fx.new_state()
	var result := Chests.open(state, "pradera_oeste")
	assert_eq(state.loadout.worn(Equipment.SHIELD), Equipment.WOODEN_SHIELD)
	assert_string_contains(result.text, "Te lo equipas")
	assert_true(state.bag_equipment.is_empty())


func test_each_part_adds_its_chests() -> void:
	assert_eq(Chests.total(Fx.state_in_part(1)), 13)
	assert_eq(Chests.total(Fx.state_in_part(2)), 25)
	assert_eq(Chests.total(Fx.state_in_part(3)), 37)
	var state := Fx.state_in_part(1)
	state.opened_chests.append(Chests.of_zone("jungla")[0])
	assert_eq(Chests.opened_count(state), 0, "a chest of a part not reached yet does not count")
