class_name SaveData extends RefCounted
## Turns the session into a Dictionary that SaveStore writes as JSON, and back. Pure:
## no nodes, no files. JSON reads every number as a float, so apply() converts them.
## VERSION goes in every save so a later format can migrate older files. Version 2 (full
## combat) adds the gold and changes how the hero grows, so version 1 saves are refused.
## The spells are not saved: Leveling.sync_skills() gives them back from the level.
## Version 3 (economy and equipment) adds the loadout, the equipment in the bag and the
## opened chests; a version 2 save still loads, with the starting gear, an empty bag and
## every chest closed. Version 4 (the world of zones) adds the zone the hero is on, the
## world flags, the key items and the last village visited; a version 2 or 3 save still
## loads on the meadow (its position is a meadow one), with the "rey_slime" flag set if
## its quest was already done, no key items and Villaclaro as the last village. Version 5
## (the interface pass) adds the open return portal of the Ala de viaje and what has been
## explored of each zone (its ExploredMap cells in base64); an older save loads with no
## portal open and nothing explored. STORY_VERSION (the story) adds the hero's name, the
## story (cutscenes seen, the ending reached) and the numbers for the credits; an older save
## gets the default name, the cutscenes its world flags have left behind marked seen
## (StoryState.mark_seen_for_flags()) and the numbers at 0. QUESTS_VERSION (the side quests)
## adds the accessory slot to the loadout and the side quests' progress; an older save gets
## the slot empty and no side quest taken. DIFFICULTY_VERSION (phase 7) adds the difficulty;
## an older save plays on Normal. EVOLUTION_VERSION (1.1.0) adds the helmet slot, the
## enemies seen, the wells' charge and the creature; an older save gets the slot empty,
## the bosses it has beaten and the common enemies of their zones seen (and the Slime de Metal if its quest is done), every well full and no creature. DEFEATED_VERSION (1.3.0) adds the enemies beaten; in an older save every enemy seen counts as beaten.
## RING_VERSION (1.6.0) splits the accessory slot into the ring and the amulet; in an older save the accessory worn goes to the slot its piece belongs to, the other one empty.

const VERSION := 11
## First version with the story's fields.
const STORY_VERSION := 6
## First version with the accessory slot and the side quests.
const QUESTS_VERSION := 7
## First version with the difficulty.
const DIFFICULTY_VERSION := 8
## First version with the helmet slot, the bestiary, the wells and the creature.
const EVOLUTION_VERSION := 9
## First version with the enemies beaten.
const DEFEATED_VERSION := 10
## First version with the ring and the amulet slots instead of the accessory one.
const RING_VERSION := 11
## The one accessory slot of the saves from QUESTS_VERSION to before RING_VERSION.
const OLD_ACCESSORY := "accessory"
## Oldest version apply() still reads.
const OLDEST_VERSION := 2
## Combatant fields of the hero that change while playing (the rest come from hero.tres).
const HERO_FIELDS: Array[String] = ["level", "experience", "hp", "max_hp", "mp", "max_mp",
	"attack", "defense", "speed"]


static func from_state(state: GameState, player_pos: Vector3, play_time: float) -> Dictionary:
	var hero := {}
	for field in HERO_FIELDS:
		hero[field] = state.hero.get(field)
	var flags: Array[String] = []
	for flag: String in state.world_flags:
		if state.world_flags[flag]:
			flags.append(flag)
	flags.sort()
	var explored := {}
	for id: String in state.explored:
		var map: ExploredMap = state.explored[id]
		if map.any_seen():
			explored[id] = Marshalls.raw_to_base64(map.cells)
	return {
		"version": VERSION,
		"hero": hero,
		"inventory": state.inventory.to_dict(),
		"quest": {"stage": state.quest.stage, "kills": state.quest.kills},
		"gold": state.gold,
		"loadout": state.loadout.to_dict(),
		"bag": state.bag_equipment.duplicate(),
		"chests": state.opened_chests.duplicate(),
		"zone": state.zone_id,
		"town": state.town_zone,
		"flags": flags,
		"key_items": state.key_items.duplicate(),
		"portal": {} if not state.has_portal() else {"town": state.portal_town,
			"zone": state.portal_zone, "pos": [state.portal_pos.x, state.portal_pos.z]},
		"explored": explored,
		"name": state.hero.display_name,
		"story": state.story.to_dict(),
		"stats": {"battles": state.battles, "steps": state.steps, "gold": state.gold_earned},
		"quests": state.quests.to_dict(),
		"difficulty": state.difficulty,
		"bestiary": state.seen_enemies.duplicate(),
		"defeated": state.defeated_enemies.duplicate(),
		"wells": state.well_charge.duplicate(),
		"ally": state.ally_id,
		"position": [player_pos.x, player_pos.z],
		"play_time": play_time,
	}


## Loads data into state. Returns {"valid": bool, "position": Vector3, "play_time":
## float}; when valid is false, state is left untouched. The zone to load is then
## state.zone_id.
static func apply(state: GameState, data: Dictionary) -> Dictionary:
	if not is_valid(data):
		return {"valid": false, "position": Vector3.ZERO, "play_time": 0.0}
	for field in HERO_FIELDS:
		state.hero.set(field, int(data.hero[field]))
	Leveling.sync_skills(state.hero)
	state.gold = int(data.gold)
	state.loadout = Loadout.new()
	state.loadout.set_slots(_loadout_slots(data))
	state.bag_equipment.assign(data.get("bag", []))
	state.opened_chests.assign(data.get("chests", []))
	state.refresh_equipment()
	var items := {}
	for id: String in data.inventory:
		items[id] = int(data.inventory[id])
	state.inventory.set_items(items)
	state.quest.stage = clampi(int(data.quest.stage), Quest.Stage.OFFER, Quest.Stage.DONE) \
		as Quest.Stage
	state.quest.kills = int(data.quest.kills)
	state.world_flags = {}
	if int(data.version) >= 4:
		for flag: String in data.flags:
			state.world_flags[flag] = true
		state.key_items.assign(data.key_items)
		state.zone_id = data.zone
		state.town_zone = data.town
	else:
		# Older saves: always on the meadow; a finished quest means the Rey Slime is beaten.
		if state.quest.stage == Quest.Stage.DONE:
			state.world_flags[Quest.BOSS_ID] = true
		state.key_items.clear()
		state.zone_id = "pradera"
		state.town_zone = "pradera"
	state.close_portal()
	var portal: Dictionary = data.get("portal", {})
	if not portal.is_empty():
		state.portal_town = portal.town
		state.portal_zone = portal.zone
		state.portal_pos = Vector3(portal.pos[0], 0.0, portal.pos[1])
	state.explored = {}
	var explored: Dictionary = data.get("explored", {})
	for id: String in explored:
		state.explored[id] = ExploredMap.new(ZoneData.by_id(id),
			Marshalls.base64_to_raw(explored[id]))
	state.story = StoryState.new()
	if int(data.version) >= STORY_VERSION:
		state.hero.display_name = data.name
		state.story.set_from(data.story)
		state.battles = int(data.stats.battles)
		state.steps = int(data.stats.steps)
		state.gold_earned = int(data.stats.gold)
	else:
		# Before the story: the default name, and the cutscenes already left behind seen.
		state.hero.display_name = StoryState.DEFAULT_NAME
		state.story.mark_seen_for_flags(state.world_flags)
		state.battles = 0
		state.steps = 0
		state.gold_earned = 0
	state.quests.set_from(data.get("quests", {}))
	state.difficulty = data.get("difficulty", Difficulty.NORMAL)
	state.seen_enemies.clear()
	if int(data.version) >= EVOLUTION_VERSION:
		state.seen_enemies.assign(data.bestiary)
	else:
		_see_before_bestiary(state)
	state.defeated_enemies.clear()
	if int(data.version) >= DEFEATED_VERSION:
		state.defeated_enemies.assign(data.defeated)
	else:
		# Before the cards: every enemy seen counts as beaten.
		state.defeated_enemies.assign(state.seen_enemies)
	for id in state.defeated_enemies:
		state.see_enemy(id)
	state.well_charge = {}
	var wells: Dictionary = data.get("wells", {})
	for id: String in wells:
		state.well_charge[id] = int(wells[id])
	state.ally_id = data.get("ally", "")
	var pos: Array = data.position
	return {"valid": true, "position": Vector3(pos[0], 0.0, pos[1]),
		"play_time": float(data.play_time)}


## The loadout of data, slot -> id. Before RING_VERSION the one accessory goes to the slot
## its piece belongs to (the Anillo antiveneno to the ring, the Amuleto de velocidad to the
## amulet) and the other slot stays empty. A save without a loadout gets the starting gear.
static func _loadout_slots(data: Dictionary) -> Dictionary:
	var slots: Dictionary = (data.get("loadout", Loadout.new().to_dict()) as Dictionary).duplicate()
	if int(data.version) < RING_VERSION:
		var piece: String = slots.get(OLD_ACCESSORY, "")
		slots.erase(OLD_ACCESSORY)
		if piece != "":
			slots[Equipment.slot(piece)] = piece
	return slots


## Before the bestiary: every boss beaten, the common enemies of the zone it guarded and the
## Slime de Metal once its quest is done have been seen.
static func _see_before_bestiary(state: GameState) -> void:
	for flag: String in state.world_flags:
		if EnemyLibrary.ENEMIES.has(flag):
			state.see_enemy(flag)
	for zone_id in ZoneData.IDS:
		var zone := ZoneData.by_id(zone_id)
		if zone.boss_id == "" or not state.has_flag(zone.boss_id):
			continue
		for formation: Array in zone.formations + zone.start_formations:
			for enemy_id: String in formation:
				state.see_enemy(enemy_id)
	if state.quests.stage("slime_metal") == QuestLog.Stage.DONE:
		state.see_enemy("slime_metal")


## True if data has a version apply() reads and every field with the right type.
static func is_valid(data: Dictionary) -> bool:
	if not (data.get("version") is float and int(data.version) >= OLDEST_VERSION \
			and int(data.version) <= VERSION):
		return false
	if int(data.version) >= 3 and not _valid_equipment(data):
		return false
	if int(data.version) >= 4 and not _valid_world(data):
		return false
	if int(data.version) >= 5 and not (_valid_portal(data) and _valid_explored(data)):
		return false
	if int(data.version) >= STORY_VERSION and not _valid_story(data):
		return false
	if int(data.version) >= QUESTS_VERSION and not _valid_quests(data):
		return false
	if int(data.version) >= DIFFICULTY_VERSION and not _valid_difficulty(data):
		return false
	if int(data.version) >= EVOLUTION_VERSION and not (_valid_enemy_ids(data.get("bestiary")) and _valid_wells(data)
			and _valid_ally(data)):
		return false
	if int(data.version) >= DEFEATED_VERSION and not _valid_enemy_ids(data.get("defeated")):
		return false
	var hero: Variant = data.get("hero")
	if not hero is Dictionary:
		return false
	for field in HERO_FIELDS:
		if not (hero as Dictionary).get(field) is float:
			return false
	if not _valid_hero_ranges(hero):
		return false
	var inventory: Variant = data.get("inventory")
	if not inventory is Dictionary:
		return false
	for count: Variant in (inventory as Dictionary).values():
		if not (count is float and count >= 0.0):
			return false
	var quest: Variant = data.get("quest")
	if not (quest is Dictionary and quest.get("stage") is float and quest.get("kills") is float
			and quest.kills >= 0.0):
		return false
	if not (data.get("gold") is float and data.gold >= 0.0):
		return false
	var pos: Variant = data.get("position")
	if not (pos is Array and pos.size() == 2 and pos[0] is float and pos[1] is float):
		return false
	return data.get("play_time") is float and data.play_time >= 0.0


## Numbers a played game can't reach: below zero, a level off the table, a dead hero.
static func _valid_hero_ranges(hero: Dictionary) -> bool:
	for field in HERO_FIELDS:
		if hero[field] < 0.0:
			return false
	return hero.level >= 1.0 and hero.level <= Leveling.MAX_LEVEL \
		and hero.hp >= 1.0 and hero.hp <= hero.max_hp and hero.mp <= hero.max_mp


## An Array of EnemyLibrary ids (the bestiary's seen and beaten lists).
static func _valid_enemy_ids(value: Variant) -> bool:
	if not value is Array:
		return false
	for id: Variant in value:
		if not (id is String and EnemyLibrary.ENEMIES.has(id)):
			return false
	return true


## EVOLUTION_VERSION field: the creature's id, "" for none.
static func _valid_ally(data: Dictionary) -> bool:
	var ally: Variant = data.get("ally")
	return ally is String and (ally == "" or Allies.exists(ally))


## EVOLUTION_VERSION field: a Dictionary of well ids to the battles left.
static func _valid_wells(data: Dictionary) -> bool:
	var wells: Variant = data.get("wells")
	if not wells is Dictionary:
		return false
	for id: Variant in wells:
		if not (id is String and wells[id] is float and wells[id] >= 0.0):
			return false
	return true


## DIFFICULTY_VERSION field: a Difficulty id.
static func _valid_difficulty(data: Dictionary) -> bool:
	var difficulty: Variant = data.get("difficulty")
	return difficulty is String and difficulty in Difficulty.IDS


## Version 5 field: no portal ({}), or its village and zone are ZoneData ids and its spot
## two numbers.
static func _valid_portal(data: Dictionary) -> bool:
	var portal: Variant = data.get("portal")
	if not portal is Dictionary:
		return false
	if (portal as Dictionary).is_empty():
		return true
	for key in ["town", "zone"]:
		var zone_id: Variant = portal.get(key)
		if not (zone_id is String and zone_id in ZoneData.IDS):
			return false
	var pos: Variant = portal.get("pos")
	return pos is Array and pos.size() == 2 and pos[0] is float and pos[1] is float


## Version 5 field: zone id -> a string (cells that don't fit the zone are ignored).
static func _valid_explored(data: Dictionary) -> bool:
	var explored: Variant = data.get("explored")
	if not explored is Dictionary:
		return false
	for id: Variant in explored:
		if not (id is String and id in ZoneData.IDS and explored[id] is String):
			return false
	return true


## Version 3 fields: every worn id fits its slot, every bag id is equipment and every
## chest id exists.
static func _valid_equipment(data: Dictionary) -> bool:
	var loadout: Variant = data.get("loadout")
	if not loadout is Dictionary:
		return false
	for slot in Equipment.SLOTS:
		if slot in Equipment.ACCESSORY_SLOTS and int(data.version) < RING_VERSION:
			continue
		if slot == Equipment.HELMET and int(data.version) < EVOLUTION_VERSION:
			continue
		var id: Variant = (loadout as Dictionary).get(slot)
		if not id is String or (id != "" and Equipment.slot(id) != slot):
			return false
	if int(data.version) >= QUESTS_VERSION and int(data.version) < RING_VERSION:
		# The one accessory slot: a ring or an amulet, or nothing.
		var piece: Variant = (loadout as Dictionary).get(OLD_ACCESSORY)
		if not piece is String or (piece != "" \
				and not Equipment.slot(piece) in Equipment.ACCESSORY_SLOTS):
			return false
	var bag: Variant = data.get("bag")
	if not bag is Array:
		return false
	for id: Variant in bag:
		if not (id is String and Equipment.exists(id)):
			return false
	var chests: Variant = data.get("chests")
	if not chests is Array:
		return false
	for id: Variant in chests:
		if not (id is String and Chests.CHESTS.has(id)):
			return false
	return true


## QUESTS_VERSION field: quest id -> its stage and count.
static func _valid_quests(data: Dictionary) -> bool:
	var quests: Variant = data.get("quests")
	if not quests is Dictionary:
		return false
	for id: Variant in quests:
		if not (id is String and QuestLog.QUESTS.has(id)):
			return false
		var entry: Variant = quests[id]
		if not (entry is Dictionary and entry.get("stage") is float \
				and entry.get("count") is float and entry.count >= 0.0):
			return false
	return true


## STORY_VERSION fields: a name StoryState.clean_name() keeps as it is, the story's seen
## list and finished flag, and the three numbers.
static func _valid_story(data: Dictionary) -> bool:
	var hero_name: Variant = data.get("name")
	if not (hero_name is String and StoryState.clean_name(hero_name) == hero_name):
		return false
	var story: Variant = data.get("story")
	if not (story is Dictionary and story.get("seen") is Array \
			and story.get("finished") is bool):
		return false
	var stats: Variant = data.get("stats")
	if not stats is Dictionary:
		return false
	for key in ["battles", "steps", "gold"]:
		var value: Variant = (stats as Dictionary).get(key)
		if not (value is float and value >= 0.0):
			return false
	return true


## Version 4 fields: the zone and the last village are ZoneData ids, the flags are
## strings and every key item exists.
static func _valid_world(data: Dictionary) -> bool:
	for key in ["zone", "town"]:
		var zone_id: Variant = data.get(key)
		if not (zone_id is String and zone_id in ZoneData.IDS):
			return false
	var flags: Variant = data.get("flags")
	if not flags is Array:
		return false
	for flag: Variant in flags:
		if not flag is String:
			return false
	var key_items: Variant = data.get("key_items")
	if not key_items is Array:
		return false
	for id: Variant in key_items:
		if not (id is String and Inventory.KEY_ITEMS.has(id)):
			return false
	return true


## One line about a valid save for the title: "Rocío · Nv 12 · Mina · 1:05" (the hero's
## name, level, the zone's short name and the play time as h:mm). Older saves without a
## name or a zone say the default name and the meadow, as apply() would load them.
static func summary_line(data: Dictionary) -> String:
	var version := int(data.version)
	var hero_name: String = data.name if version >= STORY_VERSION else StoryState.DEFAULT_NAME
	var zone_id: String = data.zone if version >= 4 else "pradera"
	var minutes := floori(float(data.play_time) / 60.0)
	return "%s · Nv %d · %s · %d:%02d" % [hero_name, int(data.hero.level),
		ZoneData.by_id(zone_id).short_name, floori(minutes / 60.0), minutes % 60]


const IMPORT_NOT_SAVE := "Ese archivo no es una partida de Villaclaro."
const IMPORT_NEWER := "Esa partida es de una versión más nueva del juego."


## An imported file's text: {"ok": bool, "save": Dictionary, "text": why not}. Only what
## is_valid() accepts gets through.
static func from_json(text: String) -> Dictionary:
	var json := JSON.new()
	if json.parse(text) != OK or not json.data is Dictionary:
		return {"ok": false, "save": {}, "text": IMPORT_NOT_SAVE}
	var data: Dictionary = json.data
	if data.get("version") is float and int(data.version) > VERSION:
		return {"ok": false, "save": {}, "text": IMPORT_NEWER}
	if not is_valid(data):
		return {"ok": false, "save": {}, "text": IMPORT_NOT_SAVE}
	return {"ok": true, "save": data, "text": ""}
