class_name Inn extends RefCounted
## Inn rules: a night costs the inn's price and restores all HP and MP (Game adds the
## fade to black and the autosave). Villaclaro's costs 5 G (the old woman also heals
## there for free), the forest's 15 G, the mine's 30 G and the castle camp's 50 G. Pure: works
## on a GameState, never touches nodes.

const VILLACLARO := "villaclaro"
const BOSQUE := "bosque"
const MINA := "mina"
const CASTILLO := "castillo"
## inn id -> keeper's name and price of a night in gold.
const INNS := {
	VILLACLARO: {"keeper": "Posadero", "price": 5},
	BOSQUE: {"keeper": "Posadera", "price": 15},
	MINA: {"keeper": "Posadero", "price": 30},
	CASTILLO: {"keeper": "Posadera", "price": 50},
}


static func keeper(inn_id: String) -> String:
	return INNS[inn_id].keeper


static func price(inn_id: String) -> int:
	return INNS[inn_id].price


## The keeper's question, with the price.
static func offer(inn_id: String) -> String:
	return "Una noche cuesta %d G. ¿Quieres descansar?" % price(inn_id)


## Pays and heals. Returns {"ok": bool, "text": String} (the keeper's answer).
static func stay(state: GameState, inn_id: String) -> Dictionary:
	if state.gold < price(inn_id):
		return {"ok": false, "text": "No tienes oro suficiente."}
	state.gold -= price(inn_id)
	state.heal_full()
	return {"ok": true, "text": "¡Buenos días! PV y PM recuperados."}
