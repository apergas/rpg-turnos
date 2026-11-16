extends GutTest
## Shop: buying, five at once, selling at half price, what can't be sold, the prize rings and
## amulets priced by the shop (2.4.1), companions and creatures, which shop each step opens and
## the series each one sells.

const Fx := preload("res://tests/fixtures.gd")
## The Equipment "zone" of the series each shop sells (Equipment's header: 1-4 the v1's shops,
## 5-8 the caravan's tramos, 9-12 the v3's etapas).
const SERIES := {"villaclaro": 1, "bosque": 2, "mina": 3, "castillo": 4, "caravana_1": 5,
	"caravana_2": 6, "caravana_3": 7, "caravana_4": 8, "caravana_5": 9, "caravana_6": 10,
	"brumaclara_3": 11, "brumaclara_4": 12}


func test_buying_pays_and_puts_the_piece_in_the_bag() -> void:
	var state := Fx.new_state()
	var result := Shop.buy(state, Equipment.COPPER_SWORD)
	assert_true(result.ok)
	assert_eq(result.text, "Compras una Espada de cobre por 40 G.")
	assert_eq(state.gold, GameState.START_GOLD - 40)
	assert_has(state.bag_equipment, Equipment.COPPER_SWORD)


func test_without_gold_nothing_is_bought() -> void:
	var state := Fx.new_state()
	state.gold = 39
	var result := Shop.buy(state, Equipment.COPPER_SWORD)
	assert_false(result.ok)
	assert_eq(result.text, "%s." % Shop.NO_GOLD)
	assert_eq(state.gold, 39)
	assert_true(state.bag_equipment.is_empty())


func test_five_at_once_cost_five_times_and_never_for_equipment() -> void:
	var state := Fx.new_state()
	assert_true(Shop.buy_bulk(state, Inventory.POTION).ok)
	assert_eq(state.inventory.count(Inventory.POTION), Inventory.START_POTIONS + Shop.BULK)
	assert_eq(state.gold, GameState.START_GOLD - Shop.BULK * Shop.price(Inventory.POTION))
	state.gold = 9999
	assert_false(Shop.can_buy_bulk(state, Equipment.COPPER_SWORD))


func test_selling_pays_half_rounded_down() -> void:
	var state := Fx.new_state()
	state.bag_equipment.append(Equipment.WOODEN_SHIELD)
	var result := Shop.sell(state, Equipment.WOODEN_SHIELD)
	assert_true(result.ok)
	assert_eq(result.text, "Vendes un Escudo de madera por 12 G.")
	assert_eq(state.gold, GameState.START_GOLD + 12, "25 / 2")
	assert_eq(Shop.sell_price(Inventory.POTION), 4)


func test_what_is_worn_is_not_for_sale_and_the_starting_gear_sells_for_1() -> void:
	var state := Fx.new_state()
	assert_eq(Shop.sell_problem(state, Equipment.STICK), Shop.NOT_CARRIED, "worn")
	assert_false(Shop.sell(state, Equipment.STICK).ok)
	state.bag_equipment.append(Equipment.STICK)
	assert_eq(Shop.sell_price(Equipment.STICK), Shop.STARTING_GEAR_PRICE)
	assert_true(Shop.sell(state, Equipment.STICK).ok)
	assert_eq(state.loadout.worn(Equipment.WEAPON), Equipment.STICK, "the worn one stays")


func test_seeds_and_quest_items_are_never_sold() -> void:
	var state := Fx.new_state()
	state.inventory.add(Inventory.SEED_ATTACK)
	state.inventory.add(Inventory.SETA)
	assert_false(Shop.sellable(state, Inventory.SEED_ATTACK))
	assert_false(Shop.sellable(state, Inventory.SETA))
	assert_eq(Shop.sell_problem(state, Inventory.SEED_ATTACK), Shop.NOT_FOR_SALE)
	var listed := Shop.sell_list(state)
	assert_does_not_have(listed, Inventory.SETA)
	assert_has(listed, Inventory.POTION)


func test_a_prize_ring_sells_by_the_shop_it_is_sold_in() -> void:
	# Half the average price of the shop's gear, rounded down to 5 G: Villaclaro's
	# (40 + 30 + 25 + 20) / 4 / 2 = 14.4 -> 10; the castle's 1760 / 4 / 2 = 220.
	assert_eq(Shop.sell_price(Equipment.CRYSTAL_RING, Shop.VILLACLARO), 10)
	assert_eq(Shop.sell_price(Equipment.CRYSTAL_RING, Shop.CASTILLO), 220)
	for shop_id: String in Shop.SHOPS:
		var paid := Shop.sell_price(Equipment.CRYSTAL_RING, shop_id)
		assert_true(paid >= Shop.PRIZE_ACCESSORY_MIN and paid % 5 == 0,
			"%s pays %d" % [shop_id, paid])


func test_one_companion_only_and_never_a_lesser_creature() -> void:
	var state := Fx.state_in_part(2)
	state.ally_id = "tadeo"
	assert_eq(Shop.buy_problem(state, "brena"), Shop.HAS_COMPANION)
	state = Fx.new_state()
	state.gold = 9999
	state.ally_id = "esqueleto_leal"
	assert_eq(Shop.buy_problem(state, "gallina"), Shop.HAS_BETTER)
	state.ally_id = "gallina"
	assert_eq(Shop.buy_problem(state, "gallina"), Shop.HAS_IT)
	assert_eq(Shop.buy_problem(state, "lobezno"), "")


func test_a_companion_joins_for_nothing() -> void:
	var state := Fx.state_in_part(2)
	var result := Shop.buy(state, "ulma")
	assert_true(result.ok)
	assert_eq(state.ally_id, "ulma")
	assert_eq(state.gold, GameState.START_GOLD)
	assert_string_contains(result.text, "se une a ti")


func test_the_caravans_merchant_opens_the_shop_of_its_step() -> void:
	assert_eq(Shop.caravan_shop(0), "caravana_1")
	for step in range(1, 7):
		assert_eq(Shop.caravan_shop(step), "caravana_%d" % step)
	assert_eq(Shop.caravan_shop(Shop.MAX_SHOP_STEP), "caravana_6", "no shop of its own past 6")
	assert_eq(Shop.caravan_shop(99), "caravana_6")


func test_the_crystal_smith_opens_the_shop_of_the_etapa() -> void:
	assert_eq(Shop.smith_shop(1), "brumaclara_3")
	assert_eq(Shop.smith_shop(3), "brumaclara_3")
	assert_eq(Shop.smith_shop(4), "brumaclara_4")
	assert_eq(Shop.smith_shop(5), "brumaclara_4", "the epilogue keeps the last")


func test_a_figure_opens_the_shop_of_the_games_step() -> void:
	var state := Fx.state_in_part(2)
	assert_eq(Shop.resolve(Shop.CARAVAN_SHOP, state), "caravana_1")
	state.world_flags["jaguar_sombrio"] = true
	assert_eq(Shop.resolve(Shop.CARAVAN_SHOP, state), "caravana_2")
	state = Fx.state_in_part(3)
	assert_eq(Shop.resolve(Shop.CARAVAN_SHOP, state), "caravana_5")
	state.world_flags["garza_legamo"] = true
	state.world_flags["coloso_cuarzo"] = true
	assert_eq(Shop.resolve(Shop.SMITH_SHOP, state), "brumaclara_3")
	state.world_flags["vigia_bruma"] = true
	assert_eq(Shop.resolve(Shop.SMITH_SHOP, state), "brumaclara_4")
	assert_eq(Shop.resolve(Shop.BOSQUE, state), Shop.BOSQUE)


func test_each_shop_sells_the_series_of_its_step_and_never_the_phoenix() -> void:
	for shop_id: String in SERIES:
		var gear: Array = Shop.SHOPS[shop_id].equipment
		assert_eq(gear.size(), 4, shop_id)
		for id: String in gear:
			assert_eq(int(Equipment.EQUIPMENT[id].zone), SERIES[shop_id],
				"%s sells %s" % [shop_id, id])
	for shop_id: String in Shop.SHOPS:
		assert_does_not_have(Shop.SHOPS[shop_id].items, Inventory.PHOENIX, shop_id)
