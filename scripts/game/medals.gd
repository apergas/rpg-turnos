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
## What the Coleccionista gives, in order, once the hero carries "medals" of them: "items"
## (Inventory id -> amount) or "equipment" (an Equipment id, never sold).
const PRIZES: Array[Dictionary] = [
	{"medals": 2, "items": {Inventory.PHOENIX: 2}},
	{"medals": 4, "items": {Inventory.SEED_ATTACK: 1, Inventory.SEED_SPEED: 1}},
	{"medals": 6, "equipment": Equipment.MEDAL_SHIELD},
	{"medals": 9, "equipment": Equipment.MEDAL_MAIL},
	{"medals": 12, "equipment": Equipment.MEDAL_AMULET},
]


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
