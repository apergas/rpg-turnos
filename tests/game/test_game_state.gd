extends GutTest
## GameState: the level cap of each part, the shop and the companion following the tramo and
## the etapa, the gold a defeat costs, a boss's flag and key item, the Slime de Metal's HP, the
## Ala de viaje's portal and the equipment through the bag.

const Fx := preload("res://tests/fixtures.gd")


func test_the_level_cap_is_that_of_the_part() -> void:
	assert_eq(Fx.state_in_part(1).hero.level_cap, Leveling.V1_MAX_LEVEL)
	assert_eq(Fx.state_in_part(2).hero.level_cap, Leveling.V2_MAX_LEVEL)
	assert_eq(Fx.state_in_part(3).hero.level_cap, Leveling.MAX_LEVEL)


func test_the_shop_and_the_companion_follow_the_tramo_and_the_etapa() -> void:
	var state := Fx.state_in_part(2)
	assert_eq(state.shop_step(), 1)
	state.world_flags["jaguar_sombrio"] = true
	assert_eq(state.shop_step(), 2)
	assert_eq(state.ally_step(), 2)
	state = Fx.state_in_part(3)
	assert_eq(state.etapa(), 1)
	assert_eq(state.shop_step(), 5)
	assert_eq(state.ally_step(), 6)
	state.world_flags["garza_legamo"] = true
	state.world_flags["coloso_cuarzo"] = true
	assert_eq(state.shop_step(), 7)
	state.world_flags["eco_albor"] = true
	assert_eq(state.ally_step(), 10, "5 + the epilogue's etapa 5")


func test_a_defeat_costs_half_the_gold_rounded_down() -> void:
	var state := Fx.new_state()
	state.gold = 51
	assert_eq(state.defeat_gold_loss(), 25)


func test_a_boss_gives_its_flag_and_its_key_item_once() -> void:
	var state := Fx.new_state()
	var boss := Fx.fighter("golem_piedra")
	boss.key_item = "fragmento_mina"
	assert_eq(state.on_boss_defeated(boss), "fragmento_mina")
	assert_true(state.has_flag("golem_piedra"))
	assert_eq(state.on_boss_defeated(boss), "")
	assert_eq(state.key_items.count("fragmento_mina"), 1)


func test_the_metal_slime_keeps_its_hp_only_after_getting_away() -> void:
	var state := Fx.new_state()
	var metal := EnemyLibrary.data(EnemyLibrary.METAL_SLIME).duplicate() as Combatant
	var enemies: Array[Combatant] = [metal]
	metal.hp = 7
	assert_eq(state.keep_metal_slime_hp(enemies, BattleEngine.State.FLED), 7)
	metal.hp = metal.max_hp
	assert_eq(state.keep_metal_slime_hp(enemies, BattleEngine.State.FLED), 0,
		"full HP: nothing to keep")
	state.metal_slime_hp = 7
	state.keep_metal_slime_hp(enemies, BattleEngine.State.WON)
	assert_eq(state.metal_slime_hp, 0, "beaten: forgotten")


func test_a_metal_slime_battle_starts_with_the_hp_kept_on_a_copy() -> void:
	var state := Fx.new_state()
	state.metal_slime_hp = 12
	var enemies := EnemyLibrary.formation([EnemyLibrary.METAL_SLIME])
	assert_eq(state.give_metal_slime_hp(enemies), 12)
	assert_eq(enemies[0].hp, 12)
	var data := EnemyLibrary.data(EnemyLibrary.METAL_SLIME)
	assert_eq(data.hp, data.max_hp, "the data file's copy stays whole")


func test_a_new_portal_replaces_the_open_one() -> void:
	var state := Fx.new_state()
	state.zone_id = "bosque"
	assert_false(state.open_portal(Vector3(1, 0, 2)))
	assert_true(state.has_portal())
	assert_eq(state.portal_zone, "bosque")
	assert_true(state.open_portal(Vector3(3, 0, 4)), "replaces the open one")
	state.close_portal()
	assert_false(state.has_portal())


func test_equipping_from_the_bag_swaps_through_the_bag_and_counts_in_battle() -> void:
	var state := Fx.new_state()
	assert_false(state.equip(Equipment.COPPER_SWORD), "not in the bag")
	state.bag_equipment.append(Equipment.COPPER_SWORD)
	assert_true(state.equip(Equipment.COPPER_SWORD))
	assert_eq(state.bag_equipment.size(), 1)
	assert_eq(state.bag_equipment[0], Equipment.STICK)
	assert_eq(state.hero.total_attack(),
		state.hero.attack + Equipment.bonus(Equipment.COPPER_SWORD))
	state.unequip(Equipment.WEAPON)
	assert_eq(state.hero.equip_attack, 0)
	assert_eq(state.bag_equipment.size(), 2)
