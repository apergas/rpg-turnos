class_name StoryState extends RefCounted
## Where the story is: the cutscenes already seen and whether the ending was reached.
## The chapter follows from them and the world flags (the bosses beaten): 0 prologue,
## 1 meadow, 2 forest, 3 mine, 4 castle, 5 the end. Says which cutscene comes after a
## boss or on reaching a village, and the next step of the story in one line. Pure: Game
## asks it and plays the cutscenes (data/cutscenes/<id>.tres).

enum Chapter { PROLOGUE, MEADOW, FOREST, MINE, CASTLE, END }

const DEFAULT_NAME := "Héroe"
const MAX_NAME_LENGTH := 8
## Replaced by the hero's name in every story line.
const NAME_TAG := "{nombre}"
## Every cutscene, in story order.
const SCENES: Array[String] = ["prologo", "rey_slime", "aldea_bosque", "bruja", "mina",
	"golem", "castillo", "final"]
## The cutscene that follows beating each boss (its world flag).
const AFTER_BOSS := {
	"rey_slime": "rey_slime",
	"bruja": "bruja",
	"golem_piedra": "golem",
	"senor_niebla": "final",
}
## The cutscene of the first visit to each zone's village.
const ON_VILLAGE := {
	"bosque": "aldea_bosque",
	"mina_1": "mina",
	"castillo_patio": "castillo",
}
## The boss whose flag ends each chapter, from the meadow on.
const CHAPTER_BOSSES: Array[String] = ["rey_slime", "bruja", "golem_piedra", "senor_niebla"]
## The next step of the story, by chapter: GameState.main_goal() once the village quest
## is done.
const GOALS := {
	Chapter.PROLOGUE: "Objetivo: habla con la Abuela Rosa",
	Chapter.MEADOW: "Objetivo: ayuda a la Abuela Rosa",
	Chapter.FOREST: "Objetivo: vence a la Bruja del bosque",
	Chapter.MINE: "Objetivo: vence al Golem de la mina",
	Chapter.CASTLE: "Objetivo: vence al Señor de la Niebla",
	Chapter.END: "Villaclaro está en paz",
}

## Cutscene ids already played (SCENES entries), in the order they were seen.
var seen: Array[String] = []
## True once the ending and the credits were reached: the save is a finished game.
var finished := false


## The chapter now, from the cutscenes seen and the world flags (GameState.world_flags).
func chapter(flags: Dictionary) -> Chapter:
	if not has_seen("prologo"):
		return Chapter.PROLOGUE
	var reached := Chapter.MEADOW
	for boss in CHAPTER_BOSSES:
		if not flags.get(boss, false):
			break
		reached = (reached + 1) as Chapter
	return reached


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
	finished = flags.get("senor_niebla", false)


## The next step of the story in one line.
func goal_text(flags: Dictionary) -> String:
	return GOALS[chapter(flags)]


func to_dict() -> Dictionary:
	return {"seen": seen.duplicate(), "finished": finished}


## Loads what to_dict() wrote; unknown scene ids are dropped.
func set_from(data: Dictionary) -> void:
	seen.clear()
	for id: Variant in data.get("seen", []):
		if id is String and id in SCENES:
			mark_seen(id)
	finished = bool(data.get("finished", false))


## text with NAME_TAG replaced by name.
static func fill(text: String, hero_name: String) -> String:
	return text.replace(NAME_TAG, hero_name)


## A name typed by the player made valid: spaces trimmed, at most MAX_NAME_LENGTH
## characters, DEFAULT_NAME when empty.
static func clean_name(typed: String) -> String:
	var hero_name := typed.strip_edges().left(MAX_NAME_LENGTH)
	return DEFAULT_NAME if hero_name == "" else hero_name
