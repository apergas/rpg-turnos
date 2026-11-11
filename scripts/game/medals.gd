class_name Medals extends RefCounted
## The twelve small medals hidden in the world (M-34), three per region: in a corner, behind
## a house, at the back of a glade, at the end of a dead-end corridor of the mine. Each lies
## off the path and away from the autoplay route; the map shows it only to a hero close by
## (World) and never on the map square. The Coleccionista of Villaclaro counts them (they are
## never spent) and gives PRIZES as their number grows. GameState.medals remembers the ones
## taken, by id, also across a Partida nueva +. Pure: works on a GameState, no nodes.

## id -> {"zone": ZoneData id, "pos": Vector3 on the ground}. Ids are unique across zones
## (the save lists the ones taken).
const MEDALS := {
	# The meadow: behind the west house of Villaclaro, the south-west corner and, to the
	# east, behind the rocks.
	"pradera_casa": {"zone": "pradera", "pos": Vector3(-8, 0, -29)},
	"pradera_rincon": {"zone": "pradera", "pos": Vector3(-28, 0, 26)},
	"pradera_rocas": {"zone": "pradera", "pos": Vector3(29, 0, 6)},
	# The forest: the back of the south and west glades, and the south-west corner.
	"bosque_claro_sur": {"zone": "bosque", "pos": Vector3(22, 0, 21)},
	"bosque_claro_oeste": {"zone": "bosque", "pos": Vector3(-26, 0, -25)},
	"bosque_rincon": {"zone": "bosque", "pos": Vector3(-25, 0, 36)},
	# The mine: the end of a dead-end corridor of each floor, out of every room (cells
	# (1, 7), (1, 11) and (9, 11)).
	"mina_1_fondo": {"zone": "mina_1", "pos": Vector3(-25, 0, 5)},
	"mina_2_fondo": {"zone": "mina_2", "pos": Vector3(-25, 0, 20)},
	"mina_3_fondo": {"zone": "mina_3", "pos": Vector3(9, 0, 20)},
	# The castle: the north-west and south-east corners of the courtyard, by their torches,
	# and the nook north-east of the throne.
	"castillo_patio_oeste": {"zone": "castillo_patio", "pos": Vector3(-28, 0, -24)},
	"castillo_patio_este": {"zone": "castillo_patio", "pos": Vector3(28, 0, 8)},
	"castillo_trono_rincon": {"zone": "castillo_trono", "pos": Vector3(20, 0, -17)},
}
## Said in the dialogue window when one is taken (taken so far / all of them).
const FOUND_TEXT := "¡Encuentras una Medalla pequeña! (%d/%d)"
## The figure that counts the medals (ZoneData.npcs of Villaclaro) and where he stands.
const COLLECTOR := "Coleccionista"
const COLLECTOR_ZONE := "pradera"
## What he says: the first time; before each prize; how many are carried and how many the
## next prize asks (none yet, one, several); once all five prizes are given ({nombre}: the
## hero's name, Game fills it in).
const INTRO := "Colecciono medallas pequeñas. Hay doce escondidas por el mundo. Tráemelas y te daré premios."
const PRIZE_LINE := "¡%d medallas! Esto es para ti."
const NONE_LINE := "Aún no llevas ninguna. Con %d te daré algo bueno."
const ONE_LINE := "Llevas 1 medalla. Con %d te daré algo bueno."
const NEXT_LINE := "Llevas %d medallas. Con %d te daré algo bueno."
const ALL_LINE := "¡Las doce! Ya no me queda nada que darte, {nombre}. Gracias."
## What the Coleccionista gives, in order, once the hero carries "medals" of them: "items"
## (Inventory id -> amount) or "equipment" (an Equipment id, never sold).
const PRIZES: Array[Dictionary] = [
	{"medals": 2, "items": {Inventory.PHOENIX: 2}},
	{"medals": 4, "items": {Inventory.SEED_ATTACK: 1, Inventory.SEED_SPEED: 1}},
	{"medals": 6, "equipment": Equipment.MEDAL_SHIELD},
	{"medals": 9, "equipment": Equipment.MEDAL_MAIL},
	{"medals": 12, "equipment": Equipment.MEDAL_AMULET},
]

## --autoplay-zone=medallas only: the points walked from the zone's start entry through its
## medals, the last one on the last medal (straight lines the hero can walk, clear of the
## exits). The zone's own autoplay_route never passes them.
const AUTOPLAY_ROUTE := {
	"pradera": [Vector3(-3, 0, -19), Vector3(-8, 0, -24), Vector3(-8, 0, -25),
		Vector3(-8, 0, -29), Vector3(-16, 0, -20), Vector3(-17, 0, 1), Vector3(-19, 0, 4),
		Vector3(-19, 0, 15), Vector3(-26, 0, 24), Vector3(-28, 0, 26), Vector3(6, 0, 26),
		Vector3(6, 0, 23), Vector3(18, 0, 18), Vector3(18, 0, 14), Vector3(25, 0, 10),
		Vector3(25, 0, 6), Vector3(28, 0, 5), Vector3(29, 0, 6)],
	"bosque": [Vector3(12, 0, 34), Vector3(21, 0, 21), Vector3(22, 0, 21), Vector3(-22, 0, 9),
		Vector3(-24, 0, -19), Vector3(-26, 0, -25), Vector3(-22, 0, -12), Vector3(-22, 0, 7),
		Vector3(-20, 0, 19), Vector3(-17, 0, 23), Vector3(-17, 0, 26), Vector3(-19, 0, 29),
		Vector3(-25, 0, 35), Vector3(-25, 0, 36)],
	"mina_1": [Vector3(-13, 0, 11), Vector3(-13, 0, 5), Vector3(-25, 0, 5)],
	"mina_2": [Vector3(19, 0, -13), Vector3(19, 0, -9), Vector3(7, 0, -6), Vector3(7, 0, 3),
		Vector3(-17, 0, 5), Vector3(-17, 0, 19), Vector3(-25, 0, 20)],
	"mina_3": [Vector3(-19, 0, -15), Vector3(-19, 0, -9), Vector3(-11, 0, -6),
		Vector3(-11, 0, 19), Vector3(9, 0, 20)],
	"castillo_patio": [Vector3(-1, 0, 1), Vector3(-13, 0, 1), Vector3(-13, 0, 3),
		Vector3(-19, 0, 3), Vector3(-21, 0, -11), Vector3(-28, 0, -22), Vector3(-28, 0, -24),
		Vector3(-19, 0, -20), Vector3(-19, 0, 3), Vector3(-11, 0, 3), Vector3(-11, 0, 1),
		Vector3(13, 0, 1), Vector3(13, 0, 3), Vector3(28, 0, 8)],
	"castillo_trono": [Vector3(20, 0, 11), Vector3(20, 0, -17)],
}


## The medal ids of zone_id, in MEDALS order.
static func of_zone(zone_id: String) -> Array[String]:
	var ids: Array[String] = []
	for id: String in MEDALS:
		if MEDALS[id].zone == zone_id:
			ids.append(id)
	return ids


## Takes medal id for state. Returns FOUND_TEXT with the count, or "" if it was taken
## already (or does not exist).
static func take(state: GameState, id: String) -> String:
	if id in state.medals or not MEDALS.has(id):
		return ""
	state.medals.append(id)
	return FOUND_TEXT % [state.medals.size(), MEDALS.size()]


## How many medals of zone_id state has taken.
static func taken_in(state: GameState, zone_id: String) -> int:
	var count := 0
	for id in of_zone(zone_id):
		if id in state.medals:
			count += 1
	return count


## How many PRIZES count medals reach (the most the Coleccionista may have given).
static func prizes_for(count: int) -> int:
	var reached := 0
	for prize in PRIZES:
		if count >= int(prize.medals):
			reached += 1
	return reached


## The Coleccionista: INTRO the first time; then, at once, every prize the medals carried
## reach and he has not given yet (they are counted, never spent); then how many medals are
## carried and how many the next prize asks, or ALL_LINE once the five are given. Returns
## {"lines": Array[String], "given": int (prizes given now)}.
static func talk(state: GameState) -> Dictionary:
	var lines: Array[String] = []
	if not state.collector_met:
		state.collector_met = true
		lines.append(INTRO)
	var given := 0
	while state.medal_prizes < prizes_for(state.medals.size()):
		var prize: Dictionary = PRIZES[state.medal_prizes]
		state.medal_prizes += 1
		given += 1
		lines.append(PRIZE_LINE % prize.medals)
		lines.append_array(give_prize(state, prize))
	lines.append(ALL_LINE if state.medal_prizes >= PRIZES.size() else _next_line(state))
	return {"lines": lines, "given": given}


## Gives one prize of PRIZES: its items into the inventory, its piece on at once if its slot
## is empty, else into the bag (QuestRewards). Returns the lines that say so.
static func give_prize(state: GameState, prize: Dictionary) -> Array[String]:
	var lines := QuestRewards.give_items(state, prize.get("items", {}))
	if prize.has("equipment"):
		lines.append(QuestRewards.give_piece(state, prize.equipment))
	return lines


## "Llevas 4 medallas. Con 6 te daré algo bueno." (the next prize not given yet).
static func _next_line(state: GameState) -> String:
	var count := state.medals.size()
	var target: int = PRIZES[state.medal_prizes].medals
	if count == 0:
		return NONE_LINE % target
	if count == 1:
		return ONE_LINE % target
	return NEXT_LINE % [count, target]
