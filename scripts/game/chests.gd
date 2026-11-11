class_name Chests extends RefCounted
## The treasure chests of every zone: where each one stands (zone and position) and what
## it holds (gold, an item or a piece of equipment). In the meadow two lie next to its
## autoplay route and two off it; the three of the forest stand in its glades, next to
## its route. All away from the paths. In the mine each stands on the C cell of its floor
## (ZoneData.cell_center()), next to the floor's route; so do the castle's (two in the
## courtyard, one in the throne room). Pure: open() changes a GameState and returns the
## message.

## id -> {"zone": ZoneData id, "pos": Vector3, "yaw": degrees (the lid opens toward -Z
## turned by yaw), and one of "gold": int, "item": Inventory id, "equipment": Equipment
## id}. Ids are unique across zones (the save lists the opened ones).
const CHESTS := {
	"pradera_este": {"zone": "pradera", "pos": Vector3(13.1, 0, 12.7), "yaw": 30.0, "gold": 25},
	"pradera_oeste": {"zone": "pradera", "pos": Vector3(-11.1, 0, 1.3), "yaw": -150.0,
		"equipment": Equipment.WOODEN_SHIELD},
	"rocas_oeste": {"zone": "pradera", "pos": Vector3(-25, 0, -9), "yaw": -90.0, "gold": 40},
	"rocas_este": {"zone": "pradera", "pos": Vector3(21.5, 0, -8.5), "yaw": 120.0,
		"item": Inventory.ETHER},
	"bosque_claro_sur": {"zone": "bosque", "pos": Vector3(17, 0, 21), "yaw": 40.0, "gold": 50},
	"bosque_claro_este": {"zone": "bosque", "pos": Vector3(18, 0, -15), "yaw": 130.0,
		"gold": 50},
	"bosque_claro_oeste": {"zone": "bosque", "pos": Vector3(-20, 0, -23), "yaw": -60.0,
		"item": Inventory.WING},
	"mina_1_cofre": {"zone": "mina_1", "pos": Vector3(16, 0, -20), "yaw": 180.0, "gold": 120},
	"mina_2_cofre": {"zone": "mina_2", "pos": Vector3(16, 0, 0), "yaw": 180.0, "gold": 120},
	"mina_3_cofre": {"zone": "mina_3", "pos": Vector3(-24, 0, 12), "yaw": -90.0,
		"item": Inventory.ETHER},
	"castillo_patio_oeste": {"zone": "castillo_patio", "pos": Vector3(-24, 0, 0),
		"yaw": 180.0, "gold": 200},
	"castillo_patio_este": {"zone": "castillo_patio", "pos": Vector3(28, 0, -24),
		"yaw": 90.0, "gold": 200},
	"castillo_trono_cofre": {"zone": "castillo_trono", "pos": Vector3(-20, 0, 8),
		"yaw": -90.0, "item": Inventory.ETHER},
	# The jungle: its three glades next to the autoplay route.
	"jungla_claro_sur": {"zone": "jungla", "pos": Vector3(19.5, 0, 23.5), "yaw": 40.0,
		"gold": 300},
	"jungla_claro_este": {"zone": "jungla", "pos": Vector3(21.5, 0, -10.5), "yaw": 130.0,
		"item": Inventory.BIG_POTION},
	"jungla_claro_oeste": {"zone": "jungla", "pos": Vector3(-23.5, 0, -18.5), "yaw": -60.0,
		"item": Inventory.BIG_ETHER},
}


## The chest ids of zone_id, in CHESTS order.
static func of_zone(zone_id: String) -> Array[String]:
	var ids: Array[String] = []
	for id: String in CHESTS:
		if CHESTS[id].zone == zone_id:
			ids.append(id)
	return ids


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
