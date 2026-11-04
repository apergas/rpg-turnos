class_name Chests extends RefCounted
## The treasure chests of the meadow: where each one stands and what it holds (gold, an
## item or a piece of equipment). Two lie next to Player.AUTOPLAY_ROUTE, two off it, all
## away from the path. Pure: open() changes a GameState and returns the message.

## id -> {"pos": Vector3, "yaw": degrees (the lid opens toward -Z turned by yaw), and one
## of "gold": int, "item": Inventory id, "equipment": Equipment id}.
const CHESTS := {
	"pradera_este": {"pos": Vector3(13.1, 0, 12.7), "yaw": 30.0, "gold": 25},
	"pradera_oeste": {"pos": Vector3(-11.1, 0, 1.3), "yaw": -150.0,
		"equipment": Equipment.WOODEN_SHIELD},
	"rocas_oeste": {"pos": Vector3(-25, 0, -9), "yaw": -90.0, "gold": 40},
	"rocas_este": {"pos": Vector3(21.5, 0, -8.5), "yaw": 120.0, "item": Inventory.ETHER},
}


## Opens chest id for state: gives what it holds and marks it opened. Equipment goes on
## at once if its slot is empty, else into the bag. Returns {"opened": bool (false if it
## was already open), "text": String}.
static func open(state: GameState, id: String) -> Dictionary:
	if id in state.opened_chests or not CHESTS.has(id):
		return {"opened": false, "text": ""}
	state.opened_chests.append(id)
	var chest: Dictionary = CHESTS[id]
	if chest.has("gold"):
		state.gold += chest.gold
		return {"opened": true, "text": "¡Encuentras %d monedas de oro!" % chest.gold}
	if chest.has("item"):
		state.inventory.add(chest.item)
		return {"opened": true, "text": "¡Encuentras %s %s!" % [
			Inventory.article(chest.item), Inventory.display_name(chest.item)]}
	var piece: String = chest.equipment
	var text := "¡Encuentras %s %s!" % [Equipment.article(piece), Equipment.display_name(piece)]
	state.bag_equipment.append(piece)
	if state.loadout.worn(Equipment.slot(piece)) == "":
		state.equip(piece)
		text += " Te %s equipas." % Equipment.pronoun(piece)
	return {"opened": true, "text": text}
