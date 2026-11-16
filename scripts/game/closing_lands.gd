class_name ClosingLands extends RefCounted
## The lands that close for good behind their boss. A village exit whose "gone" flag is a boss
## (an EnemyLibrary id) leads into one: that exit's zone and every zone reached from it by exits
## and stairs, never back through the village. From the zones' data: the v2's jungle, desert,
## mountain and city (the Caravana's exits) and the v3's Ciénaga, Cuevas and Ruinas
## (Brumaclara's). The v1 closes on leaving with the caravan, not behind a boss, and the Fuente
## never closes. Once the v3 is over (StoryState.world_open()) none is closed: every land of the
## three parts opens again (3.8.2). QuestLog.is_lost() asks which lands are closed; GameState
## closes an Ala de viaje's portal into a land that has just closed, and SaveData drops one an
## older save kept. Pure: reads ZoneData and the flags it is given, changes nothing.

## Boss id -> the zones of its land, found once from the zones' data (_all()): a memo of data
## that never changes, not game state.
static var _lands := {}


## The zones of the land that closes behind boss_id, [] if none does.
static func zones_of(boss_id: String) -> Array[String]:
	var zones: Array[String] = []
	zones.assign(_all().get(boss_id, []))
	return zones


## True if zone_id is in a land whose boss these flags say is beaten, until the v3 is over.
static func is_closed(zone_id: String, flags: Dictionary) -> bool:
	if StoryState.world_open(flags):
		return false
	var lands := _all()
	for boss: String in lands:
		if flags.get(boss, false) and zone_id in lands[boss]:
			return true
	return false


static func _all() -> Dictionary:
	if _lands.is_empty():
		_lands = _find()
	return _lands


## Every village exit whose gone flag is a boss: boss id -> its land's zones.
static func _find() -> Dictionary:
	var lands := {}
	for hub_id in ZoneData.IDS:
		for exit: Dictionary in ZoneData.by_id(hub_id).exits:
			var boss: String = exit.get("gone", "")
			if EnemyLibrary.ENEMIES.has(boss):
				lands[boss] = _reach(exit.to, hub_id)
	return lands


## start and every zone its exits and stairs lead to, without going through hub_id.
static func _reach(start: String, hub_id: String) -> Array[String]:
	var zones: Array[String] = [start]
	var i := 0
	while i < zones.size():
		var zone := ZoneData.by_id(zones[i])
		i += 1
		if zone == null:
			continue
		for exit: Dictionary in zone.all_exits():
			var to: String = exit.get("to", "")
			if to != "" and to != hub_id and not to in zones:
				zones.append(to)
	return zones
