class_name StoryState extends RefCounted
## Where the story is: the cutscenes already seen and whether the ending was reached.
## The chapter follows from them and the world flags (the bosses beaten): 0 prologue,
## 1 meadow, 2 forest, 3 mine, 4 castle, 5 the end; in the v2 (the caravan) 6 jungle, 7 desert,
## 8 mountain, 9 the abandoned city, 10 the v2's end (the portal calm); in the v3 (Brumaclara)
## 10 + its etapa: 11 the Ciénaga, 12 the Cuevas, 13 the Ruinas, 14 the Fuente, 15 the v3's
## end. Says which cutscene comes after a boss or on reaching a village, and the next step of
## the story in one line. Pure: Game asks it and plays the cutscenes (data/cutscenes/<id>.tres).

enum Chapter { PROLOGUE, MEADOW, FOREST, MINE, CASTLE, END, CARAVAN, DESERT, MOUNTAIN, CITY,
	V2_END, BRUMACLARA, CUEVAS, RUINAS, FUENTE, V3_END }

const DEFAULT_NAME := "Héroe"
const MAX_NAME_LENGTH := 8
## Replaced by the hero's name in every story line.
const NAME_TAG := "{nombre}"
## Every cutscene, in story order.
const SCENES: Array[String] = ["prologo", "rey_slime", "aldea_bosque", "bruja", "mina",
	"golem", "castillo", "final", "caravana_llega", "caravana_parte", "caravana_campamento",
	"jaguar", "gusano", "grifo", "guardian", "cruce", "brumaclara_llega", "garza",
	"recuerdo_albor", "amuleto", "vigia", "albor", "final_v3_liberado", "final_v3_vencido"]
## The cutscene that follows beating each boss (its world flag).
const AFTER_BOSS := {
	"rey_slime": "rey_slime",
	"bruja": "bruja",
	"golem_piedra": "golem",
	"senor_niebla": "final",
	"jaguar_sombrio": "jaguar",
	"gusano_dunas": "gusano",
	"grifo_cumbre": "grifo",
	"guardian_ciudad": "guardian",
	"garza_legamo": "garza",
	"coloso_cuarzo": "recuerdo_albor",
	"vigia_bruma": "vigia",
	"eco_albor": "albor",
	"devorador_portal": "cruce",
}
## The cutscene of the first visit to each zone's village.
const ON_VILLAGE := {
	"bosque": "aldea_bosque",
	"mina_1": "mina",
	"castillo_patio": "castillo",
	"caravana": "caravana_campamento",
	"brumaclara": "brumaclara_llega",
}
## The boss whose flag ends each chapter, from the meadow on.
const CHAPTER_BOSSES: Array[String] = ["rey_slime", "bruja", "golem_piedra", "senor_niebla"]
## The v2 (the caravan): its flag is set when the hero leaves Villaclaro with it, and the
## companion's once one is chosen.
const CARAVAN_FLAG := "caravana"
const COMPANION_FLAG := "companero"
## The v2 zone bosses, one per tramo, and the last boss behind the portal.
const V2_BOSSES: Array[String] = ["jaguar_sombrio", "gusano_dunas", "grifo_cumbre",
	"guardian_ciudad"]
const V2_FINAL_BOSS := "devorador_portal"
## The v3 (Brumaclara, 3.0.0): its flag is set the first time the hero stands in Brumaclara
## (V3Flow). Its zone bosses, one per etapa, and the last one, at the Fuente.
const V3_FLAG := "brumaclara"
const V3_BOSSES: Array[String] = ["garza_legamo", "coloso_cuarzo", "vigia_bruma"]
const V3_FINAL_BOSS := "eco_albor"
## The v3's two endings (3.3.0): the flag each final scene sets with its "flag" step (Albor freed
## with the amulet, or the Eco beaten). Brumaclara afterwards (BrumaclaraLook), the goal and the
## credits follow them.
const ALBOR_FREED := "albor_liberado"
const ALBOR_BEATEN := "albor_vencido"
## The question after the albor scene (StoryFlow.finish_v3(), World.ask() with cancel false: Esc
## and a tap outside do nothing, an answer must be chosen) and the final scene of each answer, in
## the same order.
const ENDING_QUESTION := "El Amuleto del Alba brilla en tu mano. ¿Qué haces?"
const ENDING_OPTIONS: Array[String] = ["Devolver el amuleto", "Acabar con el Eco"]
const ENDING_SCENES: Array[String] = ["final_v3_liberado", "final_v3_vencido"]
## What the v3's credits and the goal say once it is over, by the ending (ending_text()).
const V3_FREED_TEXT := "Albor guarda la Fuente"
const V3_BEATEN_TEXT := "La Niebla ha vuelto a su sitio"
## What Orvalla says when the game goes on in Brumaclara after the v3's credits.
const V3_AFTER_END_LINE := "La fiesta va para largo, {nombre}. Quédate lo que quieras: aquí ya no se apaga ninguna luz."
## The Amuleto del Alba (3.2.0): the key item and the flag the Abuela Rosa's scene gives
## (StoryFlow), which opens the way up to the Ruinas.
const AMULET_FLAG := "amuleto_recuperado"
## The Abuela Rosa's story of the amulet (data/cutscenes/amuleto.tres): Villaclaro's village
## scene in the part 3 (V3Flow.arrival_scene()); its "flag" step gives the amulet.
const AMULET_SCENE := "amuleto"
## Brumaclara's lighthouse keeper: she says how the v3 goes on, and every mission of the v3 is
## handed to her (as the v2's are to the Jefe de caravana).
const V3_KEEPER := "Orvalla"
## What Orvalla adds besides (keeper_line()): the Coloso beaten, the amulet to fetch from
## Villaclaro; the amulet here, the way up to the Ruinas (3.2.0).
const V3_AMULET_LINE := "Un amuleto partido en tres... El Jefe de vuestra caravana dice que conoce un atajo a tu pueblo. Ve a buscarlo, {nombre}."
const V3_RUINS_LINE := "Con ese amuleto la bruma del faro se aparta. Por ahí se sube a las Ruinas."
## And the Vigía beaten (3.3.0): the way to the Fuente.
const V3_SOURCE_LINE := "El camino de la Fuente sale del faro. Con el Sello de Albor, la bruma te deja pasar."
## The mine's flags (ZoneData lever_flag, floor_key, door_flag of its floors).
const MINE_LEVER := "mina_palanca"
const MINE_KEY := "llave_mina"
const MINE_DOOR := "mina_puerta"
## The mountain's flag (ZoneData lever_flag and door_flag of its first floor).
const MOUNTAIN_LEVER := "montana_palanca"
## The mountain chapter's goal, step by step: what goal_text() says there.
const MOUNTAIN_GOALS := {
	"climb": "Objetivo: sube a la cumbre",
	"lever": "Objetivo: busca la palanca que abre la reja",
	"summit": "Objetivo: vence al Grifo de la cumbre",
}
## The city's flags: the Guardián beaten (his world flag) and the gate of the portal quarter
## open (ZoneData door_flag of ciudad_2).
const CITY_GUARDIAN := "guardian_ciudad"
const CITY_GATE := "ciudad_reja"
## The city chapter's goal, step by step: what goal_text() says there.
const CITY_GOALS := {
	"enter": "Objetivo: entra en la ciudad abandonada",
	"guardian": "Objetivo: vence al Guardián de la ciudad",
	"gate": "Objetivo: abre la reja del barrio del portal",
	"devourer": "Objetivo: vence al Devorador del portal",
}
## Replaced by the companion's name in a cutscene (CutscenePlayer): in figure names, speakers
## and lines.
const COMPANION_TAG := "{compañero}"
## The mine chapter's goal, step by step: what goal_text() says there.
const MINE_GOALS := {
	"enter": "Objetivo: entra en la mina, al norte del bosque",
	"floor_2": "Objetivo: baja a la segunda planta",
	"lever": "Objetivo: busca la palanca",
	"floor_3": "Objetivo: baja a la tercera planta",
	"key": "Objetivo: busca la llave de la reja",
	"golem": "Objetivo: vence al Golem de piedra",
}
## The Cuevas' flag (ZoneData lever_flag and door_flag of their first floor, 3.1.0).
const CUEVAS_LEVER := "cuevas_palanca"
## The Cuevas chapter's goal, floor by floor: what goal_text() says there.
const CUEVAS_GOALS := {
	"enter": "Objetivo: busca los cristales en las Cuevas",
	"lever": "Objetivo: busca el mecanismo de la reja de cristal",
	"down": "Objetivo: baja a la segunda planta de las Cuevas",
	"colossus": "Objetivo: vence al Coloso de cuarzo",
}
## The Ruinas chapter's goal, step by step (3.2.0): the amulet first, then floor by floor.
const RUINAS_GOALS := {
	"amulet": "Objetivo: vuelve a Villaclaro a por el Amuleto del Alba",
	"climb": "Objetivo: sube a las Ruinas flotantes",
	"bridges": "Objetivo: cruza los puentes hasta la escalera",
	"watcher": "Objetivo: vence al Vigía de la bruma",
}
## The next step of the story, by chapter: GameState.main_goal() once the village quest
## is done. The mine, mountain, city, Cuevas and Ruinas chapters are answered by their own
## tables.
const GOALS := {
	Chapter.PROLOGUE: "Objetivo: habla con la Abuela Rosa",
	Chapter.MEADOW: "Objetivo: ayuda a la Abuela Rosa",
	Chapter.FOREST: "Objetivo: vence a la Bruja del bosque",
	Chapter.CASTLE: "Objetivo: vence al Señor de la Niebla",
	Chapter.END: "Villaclaro está en paz",
	Chapter.CARAVAN: "Objetivo: cruza la jungla y vence a su guardián",
	Chapter.DESERT: "Objetivo: atraviesa el desierto",
	Chapter.MOUNTAIN: "Objetivo: sube a la cumbre",
	Chapter.CITY: "Objetivo: entra en la ciudad abandonada",
	Chapter.V2_END: "Objetivo: cruza el portal",
	Chapter.BRUMACLARA: "Objetivo: atraviesa la Ciénaga y devuelve la luz al faro",
	Chapter.CUEVAS: "Objetivo: busca los cristales en las Cuevas",
	Chapter.RUINAS: "Objetivo: sube a las Ruinas flotantes",
	Chapter.FUENTE: "Objetivo: llega a la Fuente de la Niebla",
}

## Cutscene ids already played (SCENES entries), in the order they were seen.
var seen: Array[String] = []
## True once the ending and the credits were reached: the save is a finished game.
var finished := false
## True once the v2's ending and its credits were reached (the Devorador del portal beaten).
var finished_v2 := false
## When the hero left with the caravan: [play time in seconds, battles], for the v2's credits;
## [] for a save that was already in the caravan before 2.3.0.
var v2_start: Array = []
## True once the v3's ending and its credits were reached (the Eco de Albor beaten; 3.3.0).
var finished_v3 := false
## When the hero first stood in Brumaclara: [play time in seconds, battles], for the v3's
## numbers; [] before the v3; [0, 0] for an --autoplay-zone start inside it.
var v3_start: Array = []


## The chapter now, from the cutscenes seen and the world flags (GameState.world_flags).
## In the caravan (CARAVAN_FLAG) it is CARAVAN + the v2 bosses beaten, V2_END once the
## Devorador del portal falls; in Brumaclara (V3_FLAG) V2_END + the etapa.
func chapter(flags: Dictionary) -> Chapter:
	if flags.get(V3_FLAG, false):
		return (Chapter.V2_END + etapa(flags)) as Chapter
	if flags.get(CARAVAN_FLAG, false):
		return (Chapter.CARAVAN + tramo(flags) - 1) as Chapter
	if not has_seen("prologo"):
		return Chapter.PROLOGUE
	var reached := Chapter.MEADOW
	for boss in CHAPTER_BOSSES:
		if not flags.get(boss, false):
			break
		reached = (reached + 1) as Chapter
	return reached


## What Orvalla adds to her lines (FigureTalk) while the v3 waits on something: the amulet
## (V3_AMULET_LINE), the way up to the Ruinas once it is here (V3_RUINS_LINE), the way to the
## Fuente once the Vigía is beaten (V3_SOURCE_LINE); "" otherwise.
static func keeper_line(flags: Dictionary) -> String:
	if flags.get(V3_BOSSES[1], false) and not flags.get(AMULET_FLAG, false):
		return V3_AMULET_LINE
	if flags.get(AMULET_FLAG, false) and not flags.get(V3_BOSSES[2], false):
		return V3_RUINS_LINE
	if flags.get(V3_BOSSES[2], false) and not flags.get(V3_FINAL_BOSS, false):
		return V3_SOURCE_LINE
	return ""


## The stretch of the caravan's road (the v2): 1 + the zone bosses beaten in order, 5 once
## the Devorador del portal is beaten, 0 before the hero joins the caravan.
static func tramo(flags: Dictionary) -> int:
	if not flags.get(CARAVAN_FLAG, false):
		return 0
	if flags.get(V2_FINAL_BOSS, false):
		return 5
	var reached := 1
	for boss in V2_BOSSES:
		if not flags.get(boss, false):
			break
		reached += 1
	return mini(reached, 4)


## The stretch of the v3 (Brumaclara): 0 before it; 1 + the v3's zone bosses beaten in order
## (1 to 4); 5 once the Eco de Albor is beaten (the epilogue). Never saved: it follows from the
## flags, like the tramo.
static func etapa(flags: Dictionary) -> int:
	if not flags.get(V3_FLAG, false):
		return 0
	if flags.get(V3_FINAL_BOSS, false):
		return 5
	var reached := 1
	for boss in V3_BOSSES:
		if not flags.get(boss, false):
			break
		reached += 1
	return reached


## The part of the game these flags are in (GameState.part()): 1 the v1 (Villaclaro), 2 the v2
## (the caravan), 3 the v3 (Brumaclara).
static func part(flags: Dictionary) -> int:
	if flags.get(V3_FLAG, false):
		return 3
	return 2 if flags.get(CARAVAN_FLAG, false) else 1


## The line of the v3's ending these flags chose (the credits, the goal of its last chapter).
static func ending_text(flags: Dictionary) -> String:
	return V3_FREED_TEXT if flags.get(ALBOR_FREED, false) else V3_BEATEN_TEXT


func has_seen(scene_id: String) -> bool:
	return scene_id in seen


func mark_seen(scene_id: String) -> void:
	if not has_seen(scene_id):
		seen.append(scene_id)


## The cutscene to play after beating boss_id, "" if it has none or it was seen.
func scene_after_boss(boss_id: String) -> String:
	var id: String = AFTER_BOSS.get(boss_id, "")
	return "" if id == "" or has_seen(id) else id


## The cutscene to play on entering the village of zone_id, "" if none or seen.
func scene_on_village(zone_id: String) -> String:
	var id: String = ON_VILLAGE.get(zone_id, "")
	return "" if id == "" or has_seen(id) else id


## For saves from before the story and for --autoplay-zone starts: marks seen the
## prologue and every cutscene the world flags have already left behind (a boss's own
## scene, and the village scene of its zone).
func mark_seen_for_flags(flags: Dictionary) -> void:
	mark_seen("prologo")
	var village_of_boss := {"bruja": "aldea_bosque", "golem_piedra": "mina",
		"senor_niebla": "castillo"}
	for boss: String in AFTER_BOSS:
		if flags.get(boss, false):
			mark_seen(AFTER_BOSS[boss])
			if village_of_boss.has(boss):
				mark_seen(village_of_boss[boss])
	if flags.get(CARAVAN_FLAG, false):
		mark_seen("caravana_llega")
		mark_seen("caravana_parte")
	if flags.get(COMPANION_FLAG, false):
		mark_seen("caravana_campamento")
	if flags.get(V3_FLAG, false):
		mark_seen("brumaclara_llega")
	if flags.get(AMULET_FLAG, false):
		mark_seen(AMULET_SCENE)
	if flags.get(ALBOR_FREED, false):
		mark_seen(ENDING_SCENES[0])
	if flags.get(ALBOR_BEATEN, false):
		mark_seen(ENDING_SCENES[1])
	finished = flags.get("senor_niebla", false)
	finished_v2 = flags.get(V2_FINAL_BOSS, false)
	finished_v3 = flags.get(V3_FINAL_BOSS, false)


## The next step of the story in one line. In the mine chapter it follows the floor the hero
## is on (zone_id) and the mine's flags.
func goal_text(flags: Dictionary, zone_id := "") -> String:
	var now := chapter(flags)
	if now == Chapter.MINE:
		return MINE_GOALS[_mine_step(flags, zone_id)]
	if now == Chapter.MOUNTAIN:
		return MOUNTAIN_GOALS[_mountain_step(flags, zone_id)]
	if now == Chapter.CARAVAN and not flags.get(COMPANION_FLAG, false):
		return "Objetivo: habla con el Jefe de caravana"
	if now == Chapter.CITY:
		return CITY_GOALS[_city_step(flags, zone_id)]
	if now == Chapter.CUEVAS:
		return CUEVAS_GOALS[_cuevas_step(flags, zone_id)]
	if now == Chapter.RUINAS:
		return RUINAS_GOALS[_ruinas_step(flags, zone_id)]
	if now == Chapter.V3_END:
		return ending_text(flags)
	return GOALS[now]


static func _mine_step(flags: Dictionary, zone_id: String) -> String:
	if flags.get(MINE_KEY, false) or flags.get(MINE_DOOR, false):
		return "golem"
	if not zone_id.begins_with("mina_"):
		return "enter"
	if not flags.get(MINE_LEVER, false):
		return "lever" if zone_id == "mina_2" else "floor_2"
	return "key" if zone_id == "mina_3" else "floor_3"


static func _mountain_step(flags: Dictionary, zone_id: String) -> String:
	if zone_id == "montana_2":
		return "summit"
	if zone_id == "montana_1" and not flags.get(MOUNTAIN_LEVER, false):
		return "lever"
	return "climb"


static func _city_step(flags: Dictionary, zone_id: String) -> String:
	if flags.get(CITY_GATE, false):
		return "devourer"
	if flags.get(CITY_GUARDIAN, false):
		return "gate"
	if zone_id.begins_with("ciudad_"):
		return "guardian"
	return "enter"


static func _cuevas_step(flags: Dictionary, zone_id: String) -> String:
	if zone_id == "cuevas_2":
		return "colossus"
	if zone_id == "cuevas_1":
		return "down" if flags.get(CUEVAS_LEVER, false) else "lever"
	return "enter"


static func _ruinas_step(flags: Dictionary, zone_id: String) -> String:
	if not flags.get(AMULET_FLAG, false):
		return "amulet"
	if zone_id == "ruinas_2":
		return "watcher"
	return "bridges" if zone_id == "ruinas_1" else "climb"


func to_dict() -> Dictionary:
	return {"seen": seen.duplicate(), "finished": finished, "finished_v2": finished_v2,
		"v2_start": v2_start.duplicate(), "finished_v3": finished_v3,
		"v3_start": v3_start.duplicate()}


## Loads what to_dict() wrote; unknown scene ids are dropped.
func set_from(data: Dictionary) -> void:
	seen.clear()
	for id: Variant in data.get("seen", []):
		if id is String and id in SCENES:
			mark_seen(id)
	finished = bool(data.get("finished", false))
	finished_v2 = bool(data.get("finished_v2", false))
	v2_start = _start(data.get("v2_start", []))
	finished_v3 = bool(data.get("finished_v3", false))
	v3_start = _start(data.get("v3_start", []))


## A saved [play time, battles] (v2_start, v3_start) as numbers, [] if it is not one.
static func _start(value: Variant) -> Array:
	if value is Array and (value as Array).size() == 2:
		return [float(value[0]), int(value[1])]
	return []


## text with NAME_TAG replaced by name.
static func fill(text: String, hero_name: String) -> String:
	return text.replace(NAME_TAG, hero_name)


## A name typed by the player made valid: spaces trimmed, at most MAX_NAME_LENGTH
## characters, DEFAULT_NAME when empty.
static func clean_name(typed: String) -> String:
	var hero_name := typed.strip_edges().left(MAX_NAME_LENGTH)
	return DEFAULT_NAME if hero_name == "" else hero_name
