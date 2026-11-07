class_name Wells extends RefCounted
## The wells of the maps: one fills the HP, the other the MP, then it stays dry until
## RECHARGE_BATTLES battles have been won or lost. Pure: works on a GameState.

const RECHARGE_BATTLES := 10
const HP := "hp"
const MP := "mp"
const DRY_TEXT := "El pozo está seco. Volverá a llenarse."
const FULL_TEXT := "Se te ve en forma."
const HP_TEXT := "Bebes del pozo. PV al máximo."
const MP_TEXT := "Bebes del pozo. PM al máximo."


static func is_dry(state: GameState, id: String) -> bool:
	return state.well_charge.get(id, 0) > 0


## Drinks from the well and returns what to say. A dry well or a full hero uses nothing.
static func drink(state: GameState, id: String, kind: String) -> String:
	if is_dry(state, id):
		return DRY_TEXT
	var hero := state.hero
	if kind == HP:
		if hero.hp >= hero.max_hp:
			return FULL_TEXT
		hero.hp = hero.max_hp
	else:
		if hero.mp >= hero.max_mp:
			return FULL_TEXT
		hero.mp = hero.max_mp
	state.well_charge[id] = RECHARGE_BATTLES
	return HP_TEXT if kind == HP else MP_TEXT


## A battle was won or lost: every dry well is one battle closer to full.
static func on_battle(state: GameState) -> void:
	for id: String in state.well_charge.keys():
		state.well_charge[id] -= 1
		if state.well_charge[id] <= 0:
			state.well_charge.erase(id)


static func dry_ids(state: GameState) -> Array[String]:
	var ids: Array[String] = []
	ids.assign(state.well_charge.keys())
	return ids
