class_name Inn extends RefCounted
## Inn rules: a night never costs anything and restores all HP and MP (Game adds the fade
## to black and the autosave). Healing is free in every village; potions and Éter are
## still bought. Pure: works on a GameState, never touches nodes.

const VILLACLARO := "villaclaro"
const BOSQUE := "bosque"
const MINA := "mina"
const CASTILLO := "castillo"
## inn id -> keeper's name.
const INNS := {
	VILLACLARO: "Posadero",
	BOSQUE: "Posadera",
	MINA: "Posadero",
	CASTILLO: "Posadera",
	"caravana": "Curandera",
}
const REST := "Descansa un poco."
## What the keeper says to someone with full HP and MP (no fade, nothing to heal). Neutral:
## the hero has no set gender.
const FULL := "Se te ve en forma."


static func keeper(inn_id: String) -> String:
	return INNS[inn_id]


static func is_rested(state: GameState) -> bool:
	return state.hero.hp >= state.hero.max_hp and state.hero.mp >= state.hero.max_mp


## Heals the hero.
static func stay(state: GameState) -> void:
	state.heal_full()
