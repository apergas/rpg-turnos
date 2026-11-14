class_name CreditsData extends RefCounted
## Rule: what the credits say, from a GameState: the v1's sections (credits_sections()), the
## v2's (v2_credits_sections(), with v2_numbers()), the "h:mm:ss" text of a time (clock())
## and the one-line JSON of a save for --autoplay-save (summary()). Never touches nodes.

## The author shown in the credits.
const AUTHOR := "apergas"


## The credits: who made the game, with what, and the numbers of this game.
static func credits_sections(state: GameState, time_text: String) -> Array:
	var numbers: Array[String] = [
		"Tiempo de juego: %s" % time_text,
		"Combates: %d" % state.battles,
		"Pasos: %d" % state.steps,
		"Oro ganado: %d G" % state.gold_earned,
		"Misiones cumplidas: %d" % state.quests_done(),
		"Nivel: %d" % state.hero.level,
	]
	return [
		["Villaclaro", ["La historia de %s" % state.hero.display_name]],
		["Creado por", [AUTHOR]],
		["Motor", ["Godot Engine 4.7"]],
		["Modelos 3D", ["KayKit, de Kay Lousberg (CC0)"]],
		["Música y sonido", ["Generados por el propio juego"]],
		["Tu partida", numbers],
		["Gracias por jugar", []],
	]


## The v2's time and battles: since the hero left with the caravan (story.v2_start), or the
## whole game's for a save that was already in the caravan before 2.3.0 ("since" false).
static func v2_numbers(state: GameState, play_time: float) -> Dictionary:
	var start: Array = state.story.v2_start
	var since := not start.is_empty()
	return {
		"time": clock(play_time - (float(start[0]) if since else 0.0)),
		"battles": state.battles - (int(start[1]) if since else 0),
		"since": since,
	}


## The v2's credits: the caravan's story, this journey's numbers, who made the game.
static func v2_credits_sections(state: GameState, numbers: Dictionary) -> Array:
	var journey: Array[String] = []
	if state.ally_id != "":
		journey.append("Compañero: %s" % Allies.display_name(state.ally_id))
	journey.append(("Tiempo en la caravana: %s" if numbers.since else "Tiempo de juego: %s")
		% numbers.time)
	journey.append(("Combates en la caravana: %d" if numbers.since else "Combates: %d")
		% numbers.battles)
	journey.append("Misiones de la caravana: %d/%d" % [state.quests.done_of(true),
		QuestLog.total_of(true)])
	journey.append("Nivel: %d" % state.hero.level)
	return [
		["La caravana del portal", ["La historia de %s" % state.hero.display_name]],
		["Tu viaje", journey],
		["Creado por", [AUTHOR]],
		["Motor", ["Godot Engine 4.7"]],
		["Modelos 3D", ["KayKit, de Kay Lousberg (CC0)", "Nature Kit, de Kenney (CC0)"]],
		["Música y sonido", ["Generados por el propio juego"]],
		["Gracias por jugar", []],
	]


## Seconds as "h:mm:ss".
static func clock(seconds: float) -> String:
	return "%d:%02d:%02d" % [floori(seconds / 3600.0), floori(seconds / 60.0) % 60,
		floori(seconds) % 60]


## One line with every saved value, keys sorted, for --autoplay-save.
static func summary(data: Dictionary) -> String:
	return JSON.stringify(data, "", true)
