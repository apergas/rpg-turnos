extends GutTest
## The data of data/ and of the rules' tables point at things that exist: what each zone holds
## (enemies, exits, shops, inns), what each quest, chest and shop names, what each enemy does and
## drops, the bestiary's families, the Coleccionista's prizes, the scenes, the key items' texts
## and the hero's spells. A typo here is only seen by the autoplay if its route passes by.

const Fx := preload("res://tests/fixtures.gd")
## What an enemy's ai_weights may name besides its own skills.
const ORDERS := [BattleEngine.CMD_ATTACK, BattleEngine.CMD_STAGGER, BattleEngine.CMD_CHARGE,
	BattleEngine.CMD_ESCAPE]
## Each place's armero and the look that gives it the style of its place (3.10.0, M-124). The
## Caravana's is its tramo 1's: CampLook dresses it for the others (tests/world/test_camp_look.gd).
const ARMORERS := {"pradera": "ARMORER_VILLACLARO", "bosque": "ARMORER_FOREST",
	"mina_1": "ARMORER_MINE", "castillo_patio": "ARMORER_CASTLE", "caravana": "ARMORER_JUNGLE",
	"brumaclara": "MIST_SMITH"}


static func _sorted(ids: Array) -> String:
	var copy := ids.duplicate()
	copy.sort()
	return str(copy)


func test_no_quest_can_get_stuck() -> void:
	var problems := QuestLog.problems()
	assert_eq(problems.size(), 0, "\n".join(problems))


func test_every_enemy_a_zone_names_exists() -> void:
	for zone_id in ZoneData.IDS:
		var zone := ZoneData.by_id(zone_id)
		var ids: Array = [zone.boss_id, zone.postgame_boss_id, zone.rare_enemy]
		for formation: Array in zone.formations + zone.start_formations:
			ids.append_array(formation)
		for id: String in ids:
			if id != "":
				assert_true(EnemyLibrary.ENEMIES.has(id), "%s: %s" % [zone_id, id])


func test_every_exit_leads_to_a_zone_and_an_entry_of_it() -> void:
	for zone_id in ZoneData.IDS:
		for exit: Dictionary in ZoneData.by_id(zone_id).all_exits():
			var to: String = exit.get("to", "")
			assert_has(ZoneData.IDS, to, "%s -> %s" % [zone_id, to])
			if not to in ZoneData.IDS:
				continue
			var target := ZoneData.by_id(to)
			var entry: String = exit.get("entry", "")
			var known := entry == "" or target.entries.has(entry) or entry == target.start_entry \
				or (target.is_dungeon() and entry in [ZoneData.STAIRS_UP, ZoneData.STAIRS_DOWN])
			assert_true(known, "%s -> %s: entry %s" % [zone_id, to, entry])


func test_every_shop_and_inn_figure_opens_one_that_exists() -> void:
	for zone_id in ZoneData.IDS:
		for npc: Dictionary in ZoneData.by_id(zone_id).npcs:
			var kind: String = npc.get("kind", "npc")
			var id: String = npc.get("id", "")
			var where := "%s: %s" % [zone_id, npc.get("name", "")]
			if kind in ["shop", "armory"]:
				assert_true(Shop.SHOPS.has(id) or id in [Shop.CARAVAN_SHOP, Shop.SMITH_SHOP], where)
			elif kind == "inn":
				assert_true(Inn.INNS.has(id), where)


func test_every_quest_names_what_exists() -> void:
	for id: String in QuestLog.QUESTS:
		var quest := QuestLog.data(id)
		var where := "quest %s" % id
		assert_eq(quest.id, id, where)
		assert_has(ZoneData.IDS, quest.zone, where)
		if quest.turn_in_zone != "":
			assert_has(ZoneData.IDS, quest.turn_in_zone, where)
		match quest.kind:
			QuestData.Kind.HUNT:
				assert_true(EnemyLibrary.ENEMIES.has(quest.target), where)
			QuestData.Kind.GATHER:
				assert_true(Inventory.is_quest_item(quest.target), where)
			QuestData.Kind.DELIVER:
				assert_true(Inventory.KEY_ITEMS.has(quest.key_item), where)
			QuestData.Kind.FIND:
				assert_has(ZoneData.IDS, quest.target_zone, where)
		if quest.reward_equipment != "":
			assert_true(Equipment.exists(quest.reward_equipment), where)
		for item: String in quest.reward_items:
			assert_true(Inventory.ITEMS.has(item), where)
		if quest.kind in [QuestData.Kind.HUNT, QuestData.Kind.GATHER] and quest.goal > 1:
			assert_string_contains(quest.status, "%d", where)


func test_every_chest_holds_something_that_exists_in_a_known_zone() -> void:
	for id: String in Chests.CHESTS:
		var chest: Dictionary = Chests.CHESTS[id]
		assert_has(ZoneData.IDS, chest.zone, id)
		if chest.has("item"):
			assert_true(Inventory.ITEMS.has(chest.item), id)
		elif chest.has("equipment"):
			assert_true(Equipment.exists(chest.equipment), id)
		else:
			assert_gt(int(chest.get("gold", 0)), 0, id)


func test_every_shop_sells_things_that_exist_and_have_a_price() -> void:
	for shop_id: String in Shop.SHOPS:
		var shop: Dictionary = Shop.SHOPS[shop_id]
		for id: String in shop.equipment:
			assert_true(Equipment.exists(id) and Equipment.price(id) > 0, "%s: %s" % [shop_id, id])
		for id: String in shop.items:
			assert_true(Inventory.ITEMS.has(id) and int(Inventory.ITEMS[id].price) > 0,
				"%s: %s" % [shop_id, id])
		for id: String in Shop.allies_of(shop_id):
			assert_true(Allies.exists(id), "%s: %s" % [shop_id, id])
	assert_eq(_sorted(Shop.allies_of(Shop.COMPANIONS_SHOP)), _sorted(Allies.COMPANIONS))


func test_every_piece_with_a_shop_is_sold_in_one() -> void:
	var sold := {}
	for shop_id: String in Shop.SHOPS:
		for id: String in Shop.SHOPS[shop_id].equipment:
			sold[id] = true
	for id: String in Equipment.EQUIPMENT:
		if int(Equipment.EQUIPMENT[id].zone) > 0:
			assert_true(sold.has(id), id)


func test_every_enemy_acts_drops_and_rewards_with_what_exists() -> void:
	for id: String in EnemyLibrary.ENEMIES:
		var enemy := EnemyLibrary.data(id)
		assert_eq(enemy.id, id, "the data's id is its key")
		var forms: Array[Combatant] = [enemy]
		if enemy.next_phase != null:
			forms.append(enemy.next_phase)
		for form in forms:
			for order: String in form.ai_weights:
				assert_true(order in ORDERS or form.find_skill(order) != null,
					"%s: «%s» is no order and no skill of its own" % [id, order])
		for item: String in enemy.drops:
			assert_true(Inventory.ITEMS.has(item), "%s drops %s" % [id, item])
		if enemy.key_item != "":
			assert_true(Inventory.KEY_ITEMS.has(enemy.key_item), id)
		if enemy.reward_equipment != "":
			assert_true(Equipment.exists(enemy.reward_equipment), id)
		if enemy.help != null:
			assert_true(EnemyLibrary.ENEMIES.has(enemy.help.id),
				"%s calls %s" % [id, enemy.help.id])


func test_every_card_is_an_enemy_in_one_family_only() -> void:
	var seen := {}
	for entry in Bestiary.FAMILIES + Bestiary.V2_FAMILIES + Bestiary.V3_FAMILIES:
		assert_true(Equipment.exists(entry.reward), entry.id)
		for id: String in entry.enemies:
			assert_true(EnemyLibrary.ENEMIES.has(id), id)
			assert_false(seen.has(id), "%s is in two families" % id)
			seen[id] = true
	var v2 := []
	for entry in Bestiary.V2_FAMILIES:
		v2.append_array(entry.enemies)
	assert_eq(_sorted(v2), _sorted(Bestiary.V2_ENEMIES))
	var v3 := []
	for entry in Bestiary.V3_FAMILIES:
		v3.append_array(entry.enemies)
	assert_eq(_sorted(v3), _sorted(Bestiary.V3_ENEMIES))


func test_the_collectors_prizes_are_unpriced_rings_and_amulets_every_four() -> void:
	for i in Medals.PRIZES.size():
		var prize: Dictionary = Medals.PRIZES[i]
		assert_eq(int(prize.medals), 4 * (i + 1))
		assert_true(Shop.is_prize_accessory(prize.equipment), prize.equipment)
	var ids := {}
	for id in Medals.MEDALS:
		ids[id] = true
	assert_eq(ids.size(), Medals.MEDALS.size(), "every medal id once")


func test_every_scene_has_its_file_and_every_trigger_its_scene() -> void:
	for id in StoryState.SCENES:
		assert_true(ResourceLoader.exists("res://data/cutscenes/%s.tres" % id), id)
	for id: String in StoryState.AFTER_BOSS.values() + StoryState.ON_VILLAGE.values():
		assert_has(StoryState.SCENES, id)
	for boss: String in StoryState.AFTER_BOSS:
		assert_true(EnemyLibrary.ENEMIES.has(boss), boss)
	for zone_id: String in StoryState.ON_VILLAGE:
		assert_has(ZoneData.IDS, zone_id)


func test_every_key_item_has_its_text_and_every_hero_spell_its_line() -> void:
	for id: String in Inventory.KEY_ITEMS:
		assert_ne(Inventory.description(id), "", id)
	var ids: Array[String] = []
	for spell in Fx.HERO.skills:
		assert_ne(spell.description, "", spell.id)
		ids.append(spell.id)
	for level: int in Fx.HERO.learn:
		assert_between(level, 2, Leveling.MAX_LEVEL)
		var spell: Skill = Fx.HERO.learn[level]
		assert_ne(spell.description, "", spell.id)
		if spell.replaces != "":
			assert_has(ids, spell.replaces, "%s replaces a spell the hero has by then" % spell.id)
		ids.append(spell.id)


# 3.10.0 (M-125): the Fuente's groups fight the hero up to the top level and step aside at it
# (exit_level 51 + EncounterMeter.LEVEL_GAP; 56 when the top was 60).
func test_the_fuentes_groups_fight_until_the_top_level() -> void:
	var fuente := ZoneData.by_id("fuente")
	assert_false(EncounterMeter.is_shy(Leveling.MAX_LEVEL - 1, fuente.exit_level))
	assert_true(EncounterMeter.is_shy(Leveling.MAX_LEVEL, fuente.exit_level))


# 3.10.0 (M-124)
func test_every_armero_looks_like_its_place() -> void:
	var places := {}
	for zone_id in ZoneData.IDS:
		for npc: Dictionary in ZoneData.by_id(zone_id).npcs:
			var look: String = npc.get("look", "")
			if npc.get("kind", "") == "armory":
				places[zone_id] = look
			elif look.begins_with("ARMORER_") or look == "MIST_SMITH":
				fail_test("%s: %s wears an armero's look" % [zone_id, npc.get("name", "")])
	assert_eq_deep(places, ARMORERS)
	var seen := {}
	for look: String in ARMORERS.values():
		assert_true(ActorLooks.Look.has(look), look)
		assert_false(seen.has(look), "%s twice" % look)
		seen[look] = true
	assert_eq(Shop.keeper(Shop.VILLACLARO, Shop.ARMORY_COUNTER), "Armera")
