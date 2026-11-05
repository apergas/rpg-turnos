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
## portal open and nothing explored.

const VERSION := 5
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
	state.loadout.set_slots(data.get("loadout", state.loadout.to_dict()))
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
	var pos: Array = data.position
	return {"valid": true, "position": Vector3(pos[0], 0.0, pos[1]),
		"play_time": float(data.play_time)}


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
	var hero: Variant = data.get("hero")
	if not hero is Dictionary:
		return false
	for field in HERO_FIELDS:
		if not (hero as Dictionary).get(field) is float:
			return false
	var inventory: Variant = data.get("inventory")
	if not inventory is Dictionary:
		return false
	for count: Variant in (inventory as Dictionary).values():
		if not count is float:
			return false
	var quest: Variant = data.get("quest")
	if not (quest is Dictionary and quest.get("stage") is float and quest.get("kills") is float):
		return false
	if not data.get("gold") is float:
		return false
	var pos: Variant = data.get("position")
	if not (pos is Array and pos.size() == 2 and pos[0] is float and pos[1] is float):
		return false
	return data.get("play_time") is float


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
		var id: Variant = (loadout as Dictionary).get(slot)
		if not id is String or (id != "" and Equipment.slot(id) != slot):
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
