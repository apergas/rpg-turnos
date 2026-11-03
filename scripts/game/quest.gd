class_name Quest extends RefCounted
## The village quest: defeat GOAL slimes for the old woman, report back, then defeat
## the Rey Slime. Pure rules: Game feeds it battle results and shows what it says.

enum Stage { OFFER, HUNT, REPORT, BOSS, DONE }

const GOAL := 3
const REWARD_POTIONS := 2
const TARGET_ID := "slime"
const BOSS_ID := "rey_slime"
const NPC_NAME := "Anciana"

var stage := Stage.OFFER
var kills := 0


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
			lines.append("¡Bienvenido a Villaclaro, viajero!")
			lines.append("Los slimes no dejan salir a nadie del pueblo.")
			lines.append("¿Podrías derrotar a %d de ellos?" % GOAL)
			stage = Stage.HUNT
		Stage.HUNT:
			lines.append("Llevas %d de %d slimes. ¡Ánimo!" % [kills, GOAL])
		Stage.REPORT:
			lines.append("¡Lo has conseguido! Toma, %d pociones." % REWARD_POTIONS)
			lines.append("Pero el Rey Slime ha llegado al norte del pueblo...")
			lines.append("¡Derrótalo, por favor!")
			potions = REWARD_POTIONS
			stage = Stage.BOSS
		Stage.BOSS:
			lines.append("El Rey Slime espera al norte del pueblo.")
		Stage.DONE:
			lines.append("¡Gracias, héroe! Villaclaro está a salvo.")
	return {"lines": lines, "potions": potions}


func boss_available() -> bool:
	return stage == Stage.BOSS


## One line for the map's status window.
func status_text() -> String:
	match stage:
		Stage.OFFER:
			return "Misión: habla con la anciana"
		Stage.HUNT:
			return "Misión: slimes %d / %d" % [kills, GOAL]
		Stage.REPORT:
			return "Misión: vuelve con la anciana"
		Stage.BOSS:
			return "Misión: derrota al Rey Slime"
	return "Misión cumplida"
