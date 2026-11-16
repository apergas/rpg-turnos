extends GutTest
## SaveData: a played game through JSON and back, every save version since 2 (migrated as its
## header says), what loading fixes (retired items, EXP past the cap, the Slime de Metal's HP,
## the old accessory slot, the Coleccionista's old table), what it refuses, importing and the
## slot's line.

const Fx := preload("res://tests/fixtures.gd")
## A save edited by hand, or broken: [what changes, its new value]. Each is refused.
const BROKEN := [
	["version", 1.0], ["version", SaveData.VERSION + 1.0], ["hero.hp", 0.0], ["hero.level", 61.0],
	["hero.level", 25.0], ["hero.mp", 999.0], ["gold", -5.0], ["zone", "jungla"],
	["zone", "atlantida"], ["ally", "brena"], ["medals", ["pradera_casa", "pradera_casa"]],
	["medal_prizes", 1.0], ["key_items", ["llave_inventada"]], ["chests", ["cofre_inventado"]],
	["quests", {"juncos": {"stage": 1.0, "count": 0.0}}], ["name", " Rocío"],
	["flags", ["caravana", "brumaclara"]], ["difficulty", "imposible"]]


## A game of the part 1 with something in every field.
func _played_state() -> GameState:
	var state := Fx.new_state()
	Leveling.set_level(state.hero, 12, Fx.HERO.skills)
	state.hero.hp = 40
	state.gold = 345
	state.inventory.add(Inventory.ETHER, 2)
	state.bag_equipment.append(Equipment.COPPER_SWORD)
	state.opened_chests.append(Chests.of_zone("pradera")[0])
	state.world_flags = {"rey_slime": true}
	state.key_items.append("fragmento_bosque")
	state.zone_id = "bosque"
	state.town_zone = "bosque"
	state.quest.stage = Quest.Stage.DONE
	state.quests.accept(state, "lobos")
	state.quests.on_victory(state, "lobo")
	state.medals.append(Medals.MEDALS[0])
	state.collector_met = true
	state.defeat_enemy("slime")
	state.well_charge = {"pozo_bosque": 4}
	state.ally_id = "gallina"
	state.difficulty = Difficulty.EASY
	state.story.mark_seen("prologo")
	state.battles = 30
	state.steps = 1200
	state.gold_earned = 500
	return state


## A game of the part 3 in the Ciénaga, with Brena.
func _part_3_state() -> GameState:
	var state := Fx.state_in_part(3)
	Leveling.set_level(state.hero, 45, Fx.HERO.skills)
	state.zone_id = "cienaga"
	state.town_zone = "brumaclara"
	state.ally_id = "brena"
	state.story.mark_seen_for_flags(state.world_flags)
	state.story.v3_start = [100.0, 5]
	return state


func test_a_played_game_comes_back_the_same_through_json() -> void:
	var saved := SaveData.from_state(_played_state(), Vector3(3, 0, -4), 3725.0)
	var state := Fx.new_state()
	var result := SaveData.apply(state, Fx.round_trip(saved))
	assert_true(result.valid)
	assert_eq(result.position, Vector3(3, 0, -4))
	assert_eq(result.play_time, 3725.0)
	assert_eq_deep(SaveData.from_state(state, result.position, result.play_time), saved)
	assert_not_null(state.hero.find_skill("rayo"), "the spells come back from the level")


func test_a_brumaclara_game_comes_back_the_same_through_json() -> void:
	var saved := SaveData.from_state(_part_3_state(), Vector3(-2, 0, 5), 9000.0)
	var state := Fx.new_state()
	var result := SaveData.apply(state, Fx.round_trip(saved))
	assert_true(result.valid)
	assert_eq(state.part(), 3)
	assert_eq(state.hero.level_cap, Leveling.MAX_LEVEL)
	assert_eq_deep(SaveData.from_state(state, result.position, result.play_time), saved)


# 3.8.2 (M-114): the versions 2 to 8 load only with the 3.8.2's fix (data.get("ally", "")).
func test_a_save_of_every_version_since_2_loads(
		version = use_parameters(range(SaveData.OLDEST_VERSION, SaveData.VERSION + 1))) -> void:
	var data := Fx.round_trip(Fx.older_save(Fx.fresh_save(), version))
	var state := Fx.new_state()
	assert_true(SaveData.apply(state, data).valid, "version %d" % version)
	assert_eq(state.hero.level, 1)
	assert_eq(state.zone_id, "pradera")
	assert_eq(state.difficulty, Difficulty.NORMAL)


# 3.8.2 (M-114): a version 8 save.
func test_a_save_from_before_the_bestiary_has_seen_what_its_bosses_guarded() -> void:
	var meadow := ZoneData.by_id("pradera")
	assert_eq(meadow.boss_id, "rey_slime")
	var data := Fx.older_save(Fx.fresh_save(), SaveData.DIFFICULTY_VERSION)
	data.flags = ["rey_slime"]
	data.quest.stage = float(Quest.Stage.DONE)
	var state := Fx.new_state()
	assert_true(SaveData.apply(state, Fx.round_trip(data)).valid)
	assert_has(state.seen_enemies, "rey_slime")
	for formation: Array in meadow.formations:
		for id: String in formation:
			assert_has(state.seen_enemies, id)
	assert_eq(state.defeated_enemies.size(), state.seen_enemies.size(),
		"before the cards every enemy seen counts as beaten")


func test_a_retired_item_is_sold_on_loading() -> void:
	var data := Fx.fresh_save()
	data.inventory["incienso"] = 3.0
	var state := Fx.new_state()
	assert_true(SaveData.apply(state, data).valid)
	assert_eq(state.inventory.count("incienso"), 0)
	assert_eq(state.gold, GameState.START_GOLD + 3 * int(SaveData.RETIRED_ITEMS.incienso))


# 3.10.0 (M-126): the retired items' gold came in after whole() had capped the gold (found by
# the 3.9.0 tests), so a file edited by hand could end past MAX_NUMBER.
func test_the_gold_of_retired_items_stays_within_the_cap() -> void:
	var data := Fx.fresh_save()
	data.gold = float(SaveData.MAX_NUMBER)
	data.inventory["incienso"] = 3.0
	var state := Fx.new_state()
	assert_true(SaveData.apply(state, data).valid)
	assert_eq(state.inventory.count("incienso"), 0)
	assert_eq(state.gold, SaveData.MAX_NUMBER)


func test_exp_past_the_cap_is_clamped_on_loading() -> void:
	var data := Fx.fresh_save()
	data.hero.level = 20.0
	data.hero.experience = 9999.0
	var state := Fx.new_state()
	assert_true(SaveData.apply(state, data).valid)
	assert_eq(state.hero.experience, Leveling.EXP_TABLE[19])


# 3.10.0 (M-125): the v3's cap went from 60 down to 55; a 3.8.0-3.9.0 hero of 56 to 60 still
# loads, at 55 with a 55's numbers and EXP.
func test_a_hero_past_the_top_from_before_3_10_loads_at_the_top(
		level = use_parameters(range(Leveling.MAX_LEVEL + 1, SaveData.OLD_MAX_LEVEL + 1))) -> void:
	var top := _part_3_state()
	Leveling.set_level(top.hero, Leveling.MAX_LEVEL, Fx.HERO.skills)
	var at_top := Fx.round_trip(SaveData.from_state(top, Vector3(-2, 0, 5), 9000.0))
	var data := at_top.duplicate(true)
	var extra: int = level - Leveling.MAX_LEVEL
	data.hero.level = float(level)
	data.hero.experience = 75100.0
	data.hero.hp += extra * Leveling.GAINS.max_hp
	data.hero.mp += extra * Leveling.GAINS.max_mp
	for field: String in Leveling.GAINS:
		data.hero[field] += extra * Leveling.GAINS[field]
	# The slot says the level it loads at.
	assert_string_contains(SaveData.summary_line(data), "· Nv %d ·" % Leveling.MAX_LEVEL)
	var state := Fx.new_state()
	assert_true(SaveData.apply(state, data).valid, "level %d" % level)
	assert_eq(state.hero.level, Leveling.MAX_LEVEL)
	assert_true(Leveling.at_max(state.hero), "with the aura")
	var again := Fx.round_trip(SaveData.from_state(state, Vector3(-2, 0, 5), 9000.0))
	assert_eq_deep(again.hero, at_top.hero)


func test_the_metal_slimes_hp_is_cut_to_its_maximum() -> void:
	var data := Fx.fresh_save()
	data.metal_slime_hp = 999.0
	var state := Fx.new_state()
	assert_true(SaveData.apply(state, data).valid)
	assert_eq(state.metal_slime_hp, EnemyLibrary.data(EnemyLibrary.METAL_SLIME).max_hp)


func test_the_one_accessory_of_an_older_save_goes_to_its_own_slot() -> void:
	var data := Fx.older_save(Fx.fresh_save(), SaveData.RING_VERSION - 1)
	data.loadout[SaveData.OLD_ACCESSORY] = Equipment.POISON_RING
	var state := Fx.new_state()
	assert_true(SaveData.apply(state, Fx.round_trip(data)).valid)
	assert_eq(state.loadout.worn(Equipment.slot(Equipment.POISON_RING)), Equipment.POISON_RING)
	assert_eq(state.loadout.worn(Equipment.AMULET), "")


func test_the_collectors_count_of_the_old_table_starts_again() -> void:
	var data := Fx.older_save(Fx.fresh_save(), SaveData.MEDAL_PRIZES_VERSION - 1)
	data.medals = Medals.MEDALS.slice(0, 4)
	data.medal_prizes = 2.0
	var state := Fx.new_state()
	assert_true(SaveData.apply(state, Fx.round_trip(data)).valid)
	assert_eq(state.medals.size(), 4)
	assert_eq(state.medal_prizes, 0)


func test_a_broken_or_impossible_save_is_refused(case = use_parameters(BROKEN)) -> void:
	var data := Fx.fresh_save()
	Fx.set_at(data, case[0], case[1])
	assert_false(SaveData.is_valid(data), "%s = %s" % [case[0], case[1]])


func test_a_refused_save_leaves_the_state_as_it_was() -> void:
	var data := Fx.fresh_save()
	data.hero.hp = 0.0
	var state := Fx.new_state()
	state.gold = 777
	assert_false(SaveData.apply(state, data).valid)
	assert_eq(state.gold, 777)


func test_importing_something_that_is_not_a_save_says_so() -> void:
	for text in ["", "no es json", "[1, 2]", "{\"version\": 16}"]:
		var result := SaveData.from_json(text)
		assert_false(result.ok, text)
		assert_eq(result.text, SaveData.IMPORT_NOT_SAVE, text)


func test_importing_a_newer_save_says_it_is_newer() -> void:
	var data := Fx.fresh_save()
	data.version = float(SaveData.VERSION + 1)
	assert_eq(SaveData.from_json(JSON.stringify(data)).text, SaveData.IMPORT_NEWER)


func test_importing_a_good_save_gives_it_back() -> void:
	var result := SaveData.from_json(JSON.stringify(
		SaveData.from_state(_played_state(), Vector3.ZERO, 10.0)))
	assert_true(result.ok)
	assert_eq(int(result.save.hero.level), 12)


func test_the_slot_line_says_name_level_place_and_time() -> void:
	var data := Fx.round_trip(SaveData.from_state(_played_state(), Vector3.ZERO, 3725.0))
	assert_eq(SaveData.summary_line(data),
		"Héroe · Nv 12 · %s · 1:02" % ZoneData.by_id("bosque").short_name)
	var v3 := Fx.round_trip(SaveData.from_state(_part_3_state(), Vector3.ZERO, 0.0))
	assert_true(SaveData.summary_line(v3).ends_with(" · v3"))


func test_the_slot_list_reads_the_part_and_the_ending_from_the_save() -> void:
	var v1 := Fx.fresh_save()
	assert_false(SaveData.is_caravan(v1))
	v1.flags = [GameState.FINAL_BOSS]
	assert_true(SaveData.is_finished(v1))
	var v3 := Fx.round_trip(SaveData.from_state(_part_3_state(), Vector3.ZERO, 0.0))
	assert_true(SaveData.is_caravan(v3))
	assert_true(SaveData.is_v3(v3))
	assert_false(SaveData.is_finished(v3), "the v1's ending does not finish a caravan game")
	assert_false(SaveData.is_finished_v3(v3))
	v3.story.finished_v3 = true
	assert_true(SaveData.is_finished_v3(v3))


func test_an_open_portal_comes_back() -> void:
	var data := Fx.fresh_save()
	data.portal = {"town": "pradera", "zone": "bosque", "pos": [1.0, 2.0]}
	var state := Fx.new_state()
	assert_true(SaveData.apply(state, data).valid)
	assert_true(state.has_portal())
	assert_eq(state.portal_pos, Vector3(1, 0, 2))


# 3.8.2 (M-116): every number of a file edited by hand stays between 0 and MAX_NUMBER.
func test_huge_numbers_are_capped_on_loading() -> void:
	var data := Fx.fresh_save()
	data.gold = 1e30
	data.inventory[Inventory.POTION] = 1e12
	data.stats.battles = 1e30
	var state := Fx.new_state()
	assert_true(SaveData.apply(state, data).valid)
	assert_eq(state.gold, SaveData.MAX_NUMBER)
	assert_eq(state.inventory.count(Inventory.POTION), SaveData.MAX_NUMBER)
	assert_eq(state.battles, SaveData.MAX_NUMBER)


# 3.8.2 (M-116)
func test_the_play_time_is_capped_too() -> void:
	var data := Fx.fresh_save()
	data.play_time = 1e30
	var result := SaveData.apply(Fx.new_state(), data)
	assert_true(result.valid)
	assert_between(result.play_time, 0.0, float(SaveData.MAX_NUMBER))


# 3.8.2 (M-116)
func test_an_explored_map_that_is_not_base64_is_refused() -> void:
	var data := Fx.fresh_save()
	data.explored = {"pradera": "esto no es base64"}
	assert_false(SaveData.is_valid(data))
	data.explored = {"pradera": Marshalls.raw_to_base64(PackedByteArray([0, 1, 1]))}
	assert_true(SaveData.is_valid(data))


# 3.8.2 (M-111, M-116)
func test_a_portal_into_another_part_is_dropped_on_loading() -> void:
	var data := Fx.fresh_save()
	data.portal = {"town": "pradera", "zone": "jungla", "pos": [1.0, 2.0]}
	var state := Fx.new_state()
	assert_true(SaveData.apply(state, data).valid)
	assert_false(state.has_portal())


# 3.8.2 (M-115)
func test_a_newer_save_is_told_apart() -> void:
	assert_true(SaveData.is_newer({"version": float(SaveData.VERSION + 1)}))
	assert_false(SaveData.is_newer(Fx.fresh_save()))
	assert_false(SaveData.is_newer({}))
