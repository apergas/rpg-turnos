class_name SaveData extends RefCounted
## Turns the session into a Dictionary that SaveStore writes as JSON, and back. Pure:
## no nodes, no files. JSON reads every number as a float, so apply() converts them.
## VERSION goes in every save so a later format can migrate older files. Version 2 (full
## combat) adds the gold and changes how the hero grows, so version 1 saves are refused.
## The spells are not saved: Leveling.sync_skills() gives them back from the level.
## Version 3 (economy and equipment) adds the loadout, the equipment in the bag and the
## opened chests; a version 2 save still loads, with the starting gear, an empty bag and
## every chest closed.

const VERSION := 3
## Oldest version apply() still reads.
const OLDEST_VERSION := 2
## Combatant fields of the hero that change while playing (the rest come from hero.tres).
const HERO_FIELDS: Array[String] = ["level", "experience", "hp", "max_hp", "mp", "max_mp",
	"attack", "defense", "speed"]


static func from_state(state: GameState, player_pos: Vector3, play_time: float) -> Dictionary:
	var hero := {}
	for field in HERO_FIELDS:
		hero[field] = state.hero.get(field)
	return {
		"version": VERSION,
		"hero": hero,
		"inventory": state.inventory.to_dict(),
		"quest": {"stage": state.quest.stage, "kills": state.quest.kills},
		"gold": state.gold,
		"loadout": state.loadout.to_dict(),
		"bag": state.bag_equipment.duplicate(),
		"chests": state.opened_chests.duplicate(),
		"position": [player_pos.x, player_pos.z],
		"play_time": play_time,
	}


## Loads data into state. Returns {"valid": bool, "position": Vector3, "play_time":
## float}; when valid is false, state is left untouched.
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
