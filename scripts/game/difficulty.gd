class_name Difficulty extends RefCounted
## The two difficulties, chosen for each game (GameState.difficulty): Fácil takes 30 % less
## damage (from blows, spells and poison) and earns 25 % more EXP. Pure.

const NORMAL := "normal"
const EASY := "easy"
const IDS: Array[String] = [NORMAL, EASY]
const NAMES := {NORMAL: "Normal", EASY: "Fácil"}
const TEXTS := {
	NORMAL: "El juego tal como se pensó.",
	EASY: "Un 30 % menos de daño recibido y un 25 % más de EXP.",
}
const EASY_DAMAGE := 0.7
const EASY_EXP := 1.25


static func damage_mult(id: String) -> float:
	return EASY_DAMAGE if id == EASY else 1.0


static func exp_mult(id: String) -> float:
	return EASY_EXP if id == EASY else 1.0
