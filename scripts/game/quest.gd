class_name Quest extends RefCounted
## The village quest, chapter 1 of the story: defeat GOAL slimes for the Abuela Rosa,
## report back, then defeat the Rey Slime. The prologue starts it (start()). Pure rules:
## Game feeds it battle results and shows what it says (its lines hold
## StoryState.NAME_TAG for the hero's name).

enum Stage { OFFER, HUNT, REPORT, BOSS, DONE }

const GOAL := 3
const REWARD_POTIONS := 2
const TARGET_ID := "slime"
const BOSS_ID := "rey_slime"
const NPC_NAME := "Abuela Rosa"
## Its name in the Diario and in "Misión cumplida: ...".
const TITLE := "Los slimes de Villaclaro"
## Shown for a few seconds when a quest ends (QuestLog.done_text()); a finished quest is not
## listed any more.
const DONE_TEXT := "Misión cumplida"

var stage := Stage.OFFER
var kills := 0


## The prologue's request: the hunt begins without a first talk.
func start() -> void:
	if stage == Stage.OFFER:
		stage = Stage.HUNT


## Counts one enemy with this data id defeated in a won battle (Game calls it for every
## enemy of the battle).
func on_victory(enemy_id: String) -> void:
	if stage == Stage.HUNT and enemy_id == TARGET_ID:
		kills += 1
		if kills >= GOAL:
			stage = Stage.REPORT
	elif stage == Stage.BOSS and enemy_id == BOSS_ID:
		stage = Stage.DONE


## What the old woman says now and how many potions she hands over. Moves the quest on.
func talk() -> Dictionary:
	var lines: Array[String] = []
	var potions := 0
	match stage:
		Stage.OFFER:
			lines.append("¡{nombre}! Los slimes no dejan salir a nadie del pueblo.")
			lines.append("Primero demuestra que puedes con ellos: derrota a %d." % GOAL)
			stage = Stage.HUNT
		Stage.HUNT:
			lines.append("Llevas %d de %d slimes. ¡Ánimo, {nombre}!" % [kills, GOAL])
		Stage.REPORT:
			lines.append("¡Lo has conseguido! Toma, %d pociones." % REWARD_POTIONS)
			lines.append("Pero mira al norte del pueblo... ¡ha llegado el Rey Slime!")
			lines.append("Es grande y pesado. Si te cuesta, entrena un poco más por la pradera y vuelve a por él.")
			potions = REWARD_POTIONS
			stage = Stage.BOSS
		Stage.BOSS:
			lines.append("El Rey Slime espera al norte del pueblo. Si ves que puede contigo, entrena un poco antes.")
		Stage.DONE:
			lines.append("¡Gracias, {nombre}! Villaclaro está a salvo.")
	return {"lines": lines, "potions": potions}


func boss_available() -> bool:
	return stage == Stage.BOSS


## One line for the mission lists ("" once it is done).
func status_text() -> String:
	match stage:
		Stage.OFFER:
			return "Misión: habla con la Abuela Rosa"
		Stage.HUNT:
			return "Misión: slimes %d / %d" % [kills, GOAL]
		Stage.REPORT:
			return "Misión: vuelve con la Abuela Rosa"
		Stage.BOSS:
			return "Misión: derrota al Rey Slime"
	return ""
