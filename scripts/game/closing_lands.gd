class_name ClosingLands extends RefCounted
## The lands that close for good behind their boss. A village exit whose "gone" flag is a boss
## (an EnemyLibrary id) leads into one: that exit's zone and every zone reached from it by exits
## and stairs, never back through the village. From the zones' data: the v2's jungle, desert,
## mountain and city (the Caravana's exits) and the v3's Ciénaga, Cuevas and Ruinas
## (Brumaclara's). The v1 closes on leaving with the caravan, not behind a boss, and the Fuente
## never closes. QuestLog.is_lost() asks which lands are closed; BattleFlow asks warning() before
## the boss of one; GameState closes an Ala de viaje's portal into a land that has just closed.
## Pure: reads ZoneData and the GameState or flags it is given, changes nothing.

## The question before the boss: what is missing (warning()), then "Luchar ahora" first (what
## World.ask() takes on autoplay) and "Volver" last (the focus, Esc and a tap outside).
const WARNING := "Al vencerlo, esta tierra se cerrará. %s: %s."
const ANSWERS: Array[String] = ["Luchar ahora", "Volver"]
const GO_BACK := 1
## What missing() counts, in the order the warning says it: [one, several].
const WORDS := {"chests": ["cofre", "cofres"], "beasts": ["bestia", "bestias"],
	"quests": ["misión", "misiones"]}

## Boss id -> the zones of its land, found once from the zones' data (_all()): a memo of data
## that never changes, not game state.
static var _lands := {}


## The zones of the land that closes behind boss_id, [] if none does.
static func zones_of(boss_id: String) -> Array[String]:
	var zones: Array[String] = []
	zones.assign(_all().get(boss_id, []))
	return zones


## True if zone_id is in a land whose boss these flags say is beaten.
static func is_closed(zone_id: String, flags: Dictionary) -> bool:
	var lands := _all()
	for boss: String in lands:
		if flags.get(boss, false) and zone_id in lands[boss]:
			return true
	return false


## What the land of boss_id still hides from state: {"chests": its zones' chests still shut,
## "beasts": the bestiary's enemies of its zones (groups, the rare one, another boss) never
## beaten that live in no other open zone of this part (there they can still be beaten; a closed
## land is no such place), boss_id left out; "quests": the taken quests its victory would leave
## lost (QuestLog.lost_with())}. All 0 when no land closes behind it.
static func missing(state: GameState, boss_id: String) -> Dictionary:
	var left := {"chests": 0, "beasts": 0, "quests": 0}
	var land := zones_of(boss_id)
	if land.is_empty():
		return left
	var elsewhere := {}
	for zone_id in ZoneData.zones_of_part(state.part()):
		if not zone_id in land and not is_closed(zone_id, state.world_flags):
			for id in _enemies(zone_id):
				elsewhere[id] = true
	var beasts := {}
	for zone_id in land:
		for id in Chests.of_zone(zone_id):
			if not id in state.opened_chests:
				left.chests += 1
		for id in _enemies(zone_id):
			if id != boss_id and Bestiary.has(id) and not id in state.defeated_enemies \
					and not elsewhere.has(id):
				beasts[id] = true
	left.beasts = beasts.size()
	left.quests = state.quests.lost_with(boss_id, state.world_flags, state.inventory).size()
	return left


## The question before boss_id's battle: "" if no land closes behind it or nothing of it is
## missing; else WARNING with what is ("Te faltan: 2 cofres, 1 bestia, 1 misión.", or
## "Te falta: 1 cofre." for a single one).
static func warning(state: GameState, boss_id: String) -> String:
	var left := missing(state, boss_id)
	var parts: Array[String] = []
	for key: String in WORDS:
		var count: int = left[key]
		if count > 0:
			parts.append("%d %s" % [count, WORDS[key][0] if count == 1 else WORDS[key][1]])
	if parts.is_empty():
		return ""
	var verb := "Te falta" if parts.size() == 1 and parts[0].begins_with("1 ") else "Te faltan"
	return WARNING % [verb, ", ".join(parts)]


## The enemies a zone's map holds: its groups' formations, its rare one and its boss.
static func _enemies(zone_id: String) -> Array[String]:
	var zone := ZoneData.by_id(zone_id)
	var ids: Array[String] = []
	for formation: Array in zone.formations + zone.start_formations:
		for id: String in formation:
			ids.append(id)
	for id: String in [zone.rare_enemy, zone.boss_id]:
		if id != "":
			ids.append(id)
	return ids


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
