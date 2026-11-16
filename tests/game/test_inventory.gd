extends GutTest
## Inventory: healing up to the maximum, why an item can't be used, the Elixir, the seeds and the
## items through the save.

const Fx := preload("res://tests/fixtures.gd")


func test_a_potion_heals_30_and_never_past_the_maximum() -> void:
	var hero := Fx.fighter("hero", 100)
	hero.hp = 90
	var bag := Inventory.new()
	bag.add(Inventory.POTION, 2)
	var result := bag.use(Inventory.POTION, hero, true)
	assert_true(result.used)
	assert_eq(result.amount, 10)
	assert_eq(hero.hp, 100)
	assert_eq(bag.count(Inventory.POTION), 1)


func test_a_potion_on_full_hp_is_kept() -> void:
	var hero := Fx.fighter("hero", 100)
	var bag := Inventory.new()
	bag.add(Inventory.POTION)
	var result := bag.use(Inventory.POTION, hero, false)
	assert_false(result.used)
	assert_eq(result.reason, "PV al máximo")
	assert_eq(bag.count(Inventory.POTION), 1)


func test_why_an_item_cannot_be_used() -> void:
	var hero := Fx.fighter("hero", 100)
	var bag := Inventory.new()
	assert_eq(bag.problem(Inventory.ETHER, hero, true), "No te quedan")
	for id in [Inventory.SETA, Inventory.PHOENIX, Inventory.ANTIDOTE, Inventory.WING]:
		bag.add(id)
	assert_eq(bag.problem(Inventory.SETA, hero, true), Inventory.QUEST_ITEM)
	assert_eq(bag.problem(Inventory.PHOENIX, hero, true), Inventory.AUTO_USE)
	assert_eq(bag.problem(Inventory.ANTIDOTE, hero, false), "Solo en combate")
	assert_eq(bag.problem(Inventory.ANTIDOTE, hero, true), "No hace falta")
	assert_eq(bag.problem(Inventory.WING, hero, true), "Solo fuera de combate")
	hero.status[BattleEngine.POISON] = -1
	assert_eq(bag.problem(Inventory.ANTIDOTE, hero, true), "")


func test_the_elixir_gives_back_every_hp_and_mp() -> void:
	var hero := Fx.fighter("hero", 100)
	hero.hp = 10
	hero.mp = 0
	var bag := Inventory.new()
	bag.add(Inventory.ELIXIR)
	var result := bag.use(Inventory.ELIXIR, hero, true)
	assert_eq(result.amount, 90)
	assert_eq(result.mp, 99)
	assert_eq(hero.hp, 100)
	assert_eq(hero.mp, 99)


func test_a_seed_raises_its_stat_for_good() -> void:
	var state := Fx.new_state()
	state.inventory.add(Inventory.SEED_ATTACK)
	var before := state.hero.attack
	assert_true(state.use_item(Inventory.SEED_ATTACK).used)
	assert_eq(state.hero.attack, before + Inventory.SEED_BONUS)
	assert_eq(state.inventory.count(Inventory.SEED_ATTACK), 0)


func test_the_items_go_to_the_save_and_back() -> void:
	var bag := Inventory.new()
	bag.add(Inventory.POTION, 3)
	bag.add(Inventory.WING)
	var copy := Inventory.new()
	copy.set_items(bag.to_dict())
	assert_eq(copy.count(Inventory.POTION), 3)
	assert_eq(copy.count(Inventory.WING), 1)
	assert_false(copy.take(Inventory.ETHER), "none to take")
