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
## A keeper's own lines (the Caravana's Curandera): inn id -> {"rest", "full"}. The other
## inns say REST and FULL.
const LINES := {
	"caravana": {
		"rest": "Túmbate un rato. Esto no duele... casi nada.",
		"full": "Estás más sano que una pera. Vuelve cuando te duela algo.",
	},
}


static func keeper(inn_id: String) -> String:
	return INNS[inn_id]


## What the keeper of inn_id says before a night.
static func rest_line(inn_id: String) -> String:
	return LINES.get(inn_id, {}).get("rest", REST)


## What the keeper of inn_id says to someone with full HP and MP.
static func full_line(inn_id: String) -> String:
	return LINES.get(inn_id, {}).get("full", FULL)


static func is_rested(state: GameState) -> bool:
	return state.hero.hp >= state.hero.max_hp and state.hero.mp >= state.hero.max_mp


## Heals the hero.
static func stay(state: GameState) -> void:
	state.heal_full()
