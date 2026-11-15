class_name Medals extends RefCounted
## The forty small medals (M-34; dropped in battle since 2.5.0, forty since 3.6.0): a common
## enemy beaten leaves one now and then (drop_chance() of the part, BattleEngine), the Slime de
## Metal always, a boss never. The Coleccionista, in every village (ZoneData.npcs named
## COLLECTOR; in the Caravana and Brumaclara from the start), counts them (they are never spent)
## and gives a ring or an amulet every 4 (PRIZES). GameState.medals remembers the ones carried,
## by id. Pure: works on a GameState.

## The ids, in the order they are found (a medal dropped takes the first one not carried).
## The first twelve are kept from the medals on the ground of 1.8.0-2.4.1 and the 28 of 3.6.0
## go after them, so older saves stay valid.
const MEDALS: Array[String] = ["pradera_casa", "pradera_rincon", "pradera_rocas",
	"bosque_claro_sur", "bosque_claro_oeste", "bosque_rincon", "mina_1_fondo", "mina_2_fondo",
	"mina_3_fondo", "castillo_patio_oeste", "castillo_patio_este", "castillo_trono_rincon",
	"medalla_13", "medalla_14", "medalla_15", "medalla_16", "medalla_17", "medalla_18",
	"medalla_19", "medalla_20", "medalla_21", "medalla_22", "medalla_23", "medalla_24",
	"medalla_25", "medalla_26", "medalla_27", "medalla_28", "medalla_29", "medalla_30",
	"medalla_31", "medalla_32", "medalla_33", "medalla_34", "medalla_35", "medalla_36",
	"medalla_37", "medalla_38", "medalla_39", "medalla_40"]
## Chance that a common enemy beaten leaves a medal, by part of the game (GameState.part()),
## while fewer than MEDALS are carried. Tuned in Task 5 of the 3.6.0 plan: a player by hand,
## who beats about twice the common enemies the autoplay does, carries about 12 at the end of
## the v1, 28 at the end of the v2 and the 40 near the end of the v3.
const DROP_CHANCES := {1: 0.075, 2: 0.05, 3: 0.04}
## Said in the dialogue window when one is taken (taken so far / all of them).
const FOUND_TEXT := "¡Encuentras una Medalla pequeña! (%d/%d)"
## The figure that counts the medals (ZoneData.npcs of Villaclaro) and where he stands.
const COLLECTOR := "Coleccionista"
const COLLECTOR_ZONE := "pradera"
## What he says: the first time; before each prize; how many are carried and how many the
## next prize asks (none yet, one, several); once all ten prizes are given ({nombre}: the
## hero's name, Game fills it in).
const INTRO := "Colecciono medallas pequeñas. Algunos monstruos las llevan encima, quién sabe por qué. Tráemelas y te daré premios."
const PRIZE_LINE := "¡%d medallas! Esto es para ti."
const NONE_LINE := "Aún no llevas ninguna. Con %d te daré algo bueno."
const ONE_LINE := "Llevas 1 medalla. Con %d te daré algo bueno."
const NEXT_LINE := "Llevas %d medallas. Con %d te daré algo bueno."
## His joke the first time he is met again in another village (a world flag per village).
const AWAY_LINE := "¿Que si nos hemos visto en Villaclaro? Imposible: allí vive mi hermano gemelo. ...Es broma, soy yo. Viajo mucho."
const AWAY_FLAG := "coleccionista_%s"
const ALL_LINE := "¡Las cuarenta! Ya no me queda nada que darte, {nombre}. Gracias."
## What the Coleccionista gives, in order, once the hero carries "medals" of them: always a
## ring or an amulet ("equipment", an Equipment id with no price: it sells by the shop).
const PRIZES: Array[Dictionary] = [
	{"medals": 4, "equipment": "anillo_cobre"},
	{"medals": 8, "equipment": Equipment.MEDAL_AMULET},
	{"medals": 12, "equipment": "anillo_suerte"},
	{"medals": 16, "equipment": "amuleto_bronce"},
	{"medals": 20, "equipment": "anillo_plata"},
	{"medals": 24, "equipment": "amuleto_plata"},
	{"medals": 28, "equipment": "anillo_oro"},
	{"medals": 32, "equipment": "amuleto_oro"},
	{"medals": 36, "equipment": "anillo_coleccionista"},
	{"medals": 40, "equipment": "amuleto_coleccionista"},
]

## Takes medal id for state. Returns FOUND_TEXT with the count, or "" if it was taken
## already (or does not exist).
static func take(state: GameState, id: String) -> String:
	if id in state.medals or not MEDALS.has(id):
		return ""
	state.medals.append(id)
	return FOUND_TEXT % [state.medals.size(), MEDALS.size()]


## The first medal id state does not carry ("" with all of them).
static func next_missing(state: GameState) -> String:
	for id in MEDALS:
		if not id in state.medals:
			return id
	return ""


## The chance of a medal drop in part (1 to 3; DROP_CHANCES), the v1's for any other.
static func drop_chance(part: int) -> float:
	return DROP_CHANCES.get(part, DROP_CHANCES[1])


## How many PRIZES count medals reach (the most the Coleccionista may have given).
static func prizes_for(count: int) -> int:
	var reached := 0
	for prize in PRIZES:
		if count >= int(prize.medals):
			reached += 1
	return reached


## The Coleccionista in zone_id (he stands in every village, the same man with the same
## count): INTRO the first time he is met anywhere; AWAY_LINE the first time he is met again
## in a village other than Villaclaro; then, at once, every prize the medals carried
## reach and he has not given yet (they are counted, never spent); then how many medals are
## carried and how many the next prize asks, or ALL_LINE once every prize is given. Returns
## {"lines": Array[String], "given": int (prizes given now)}.
static func talk(state: GameState, zone_id: String) -> Dictionary:
	var lines: Array[String] = []
	var away := zone_id != COLLECTOR_ZONE
	if not state.collector_met:
		state.collector_met = true
		lines.append(INTRO)
	elif away and not state.has_flag(AWAY_FLAG % zone_id):
		lines.append(AWAY_LINE)
	if away:
		state.world_flags[AWAY_FLAG % zone_id] = true
	var given := 0
	while state.medal_prizes < prizes_for(state.medals.size()):
		var prize: Dictionary = PRIZES[state.medal_prizes]
		state.medal_prizes += 1
		given += 1
		lines.append(PRIZE_LINE % prize.medals)
		lines.append_array(give_prize(state, prize))
	lines.append(ALL_LINE if state.medal_prizes >= PRIZES.size() else _next_line(state))
	return {"lines": lines, "given": given}


## Gives one prize of PRIZES: its piece on at once if its slot is empty, else into the bag
## (QuestRewards). Returns the lines that say so.
static func give_prize(state: GameState, prize: Dictionary) -> Array[String]:
	var lines: Array[String] = [QuestRewards.give_piece(state, prize.equipment)]
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
