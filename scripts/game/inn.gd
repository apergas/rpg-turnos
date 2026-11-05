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
}
const OFFER := "Aquí descansar no cuesta nada. ¿Te quedas a pasar la noche?"
const MORNING := "¡Buenos días! PV y PM recuperados."


static func keeper(inn_id: String) -> String:
	return INNS[inn_id]


## Heals the hero. Returns what the keeper says.
static func stay(state: GameState) -> String:
	state.heal_full()
	return MORNING
