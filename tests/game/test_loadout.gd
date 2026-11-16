extends GutTest
## Loadout and Equipment: what a new game wears, the bonuses (ATK of the weapon and the extra ATK
## of other pieces, DEF, VEL of the ring and the amulet), the statuses kept away and the slots
## through the save.


func test_a_new_game_wears_the_stick_and_the_clothes() -> void:
	var loadout := Loadout.new()
	assert_eq(loadout.worn(Equipment.WEAPON), Equipment.STICK)
	assert_eq(loadout.worn(Equipment.ARMOR), Equipment.CLOTHES)
	assert_eq(loadout.attack_bonus(), Equipment.bonus(Equipment.STICK))
	assert_eq(loadout.defense_bonus(), Equipment.bonus(Equipment.CLOTHES))
	assert_eq(loadout.speed_bonus(), 0)
	assert_true(loadout.immunities().is_empty())


func test_the_mist_helm_adds_attack_besides_its_defense() -> void:
	var loadout := Loadout.new()
	loadout.equip(Equipment.MIST_HELM)
	assert_gt(Equipment.extra_attack(Equipment.MIST_HELM), 0)
	assert_eq(loadout.attack_bonus(),
		Equipment.bonus(Equipment.STICK) + Equipment.extra_attack(Equipment.MIST_HELM))
	assert_eq(loadout.defense_bonus(), Equipment.bonus(Equipment.CLOTHES)
		+ Equipment.bonus(Equipment.MIST_HELM) + Equipment.extra_defense(Equipment.MIST_HELM))


func test_the_collectors_ring_and_amulet_add_speed_and_keep_three_statuses_away() -> void:
	var loadout := Loadout.new()
	loadout.equip("anillo_coleccionista")
	loadout.equip("amuleto_coleccionista")
	assert_eq(loadout.speed_bonus(),
		Equipment.bonus("anillo_coleccionista") + Equipment.bonus("amuleto_coleccionista"))
	var immune := loadout.immunities()
	for status in [BattleEngine.POISON, BattleEngine.SLEEP, BattleEngine.SILENCE]:
		assert_has(immune, status)
	assert_eq(loadout.attack_bonus(), Equipment.bonus(Equipment.STICK) + 12)
	assert_eq(loadout.defense_bonus(), Equipment.bonus(Equipment.CLOTHES) + 12)


func test_putting_a_piece_on_gives_back_what_was_there() -> void:
	var loadout := Loadout.new()
	assert_eq(loadout.equip(Equipment.COPPER_SWORD), Equipment.STICK)
	assert_true(loadout.is_worn(Equipment.COPPER_SWORD))
	assert_eq(loadout.equip(Equipment.WOODEN_SHIELD), "", "the shield slot was empty")
	assert_eq(loadout.unequip(Equipment.SHIELD), Equipment.WOODEN_SHIELD)
	assert_eq(loadout.worn(Equipment.SHIELD), "")


func test_the_slots_go_to_the_save_and_back() -> void:
	var loadout := Loadout.new()
	loadout.equip(Equipment.COPPER_SWORD)
	var saved := loadout.to_dict()
	saved["inventado"] = Equipment.STICK
	var copy := Loadout.new()
	copy.set_slots(saved)
	assert_eq(copy.worn(Equipment.WEAPON), Equipment.COPPER_SWORD)
	assert_false(copy.to_dict().has("inventado"), "unknown slots are ignored")
