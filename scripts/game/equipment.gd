class_name Equipment extends RefCounted
## The equipment catalog: every weapon, armor and shield, with its slot, bonus (ATK for
## a weapon, DEF for armor and shields), price in gold, the zone whose shop sells it (0:
## no shop, the starting gear) and the mesh the hero shows for it (a handslot mesh of
## Knight.glb, STICK_MESH built in code, or "" for none). Pure: no nodes.

const WEAPON := "weapon"
const ARMOR := "armor"
const SHIELD := "shield"
## Slot order of every list (status, Equipo page, shop comparison).
const SLOTS: Array[String] = [WEAPON, ARMOR, SHIELD]
const SLOT_NAMES := {WEAPON: "Arma", ARMOR: "Armadura", SHIELD: "Escudo"}

const STICK := "palo"
const CLOTHES := "ropa"
const COPPER_SWORD := "espada_cobre"
const LEATHER_MAIL := "cota_cuero"
const WOODEN_SHIELD := "escudo_madera"
## Not a Knight.glb mesh: BattleActor builds a plain wooden stick for it.
const STICK_MESH := "stick"

const EQUIPMENT := {
	STICK: {"name": "Palo", "article": "un", "slot": WEAPON, "bonus": 2, "price": 0,
		"zone": 0, "mesh": STICK_MESH},
	CLOTHES: {"name": "Ropa", "article": "una", "slot": ARMOR, "bonus": 2, "price": 0,
		"zone": 0, "mesh": ""},
	COPPER_SWORD: {"name": "Espada de cobre", "article": "una", "slot": WEAPON, "bonus": 6,
		"price": 40, "zone": 1, "mesh": "1H_Sword"},
	LEATHER_MAIL: {"name": "Cota de cuero", "article": "una", "slot": ARMOR, "bonus": 5,
		"price": 30, "zone": 1, "mesh": ""},
	WOODEN_SHIELD: {"name": "Escudo de madera", "article": "un", "slot": SHIELD, "bonus": 3,
		"price": 25, "zone": 1, "mesh": "Round_Shield"},
	"espada_hierro": {"name": "Espada de hierro", "article": "una", "slot": WEAPON,
		"bonus": 12, "price": 150, "zone": 2, "mesh": "1H_Sword"},
	"cota_malla": {"name": "Cota de malla", "article": "una", "slot": ARMOR, "bonus": 10,
		"price": 120, "zone": 2, "mesh": ""},
	"escudo_hierro": {"name": "Escudo de hierro", "article": "un", "slot": SHIELD,
		"bonus": 5, "price": 90, "zone": 2, "mesh": "Rectangle_Shield"},
	"espada_acero": {"name": "Espada de acero", "article": "una", "slot": WEAPON,
		"bonus": 20, "price": 400, "zone": 3, "mesh": "2H_Sword"},
	"armadura_acero": {"name": "Armadura de acero", "article": "una", "slot": ARMOR,
		"bonus": 16, "price": 350, "zone": 3, "mesh": ""},
	"escudo_acero": {"name": "Escudo de acero", "article": "un", "slot": SHIELD,
		"bonus": 8, "price": 220, "zone": 3, "mesh": "Badge_Shield"},
	"espada_platino": {"name": "Espada de platino", "article": "una", "slot": WEAPON,
		"bonus": 28, "price": 650, "zone": 4, "mesh": "2H_Sword"},
	"armadura_platino": {"name": "Armadura de platino", "article": "una", "slot": ARMOR,
		"bonus": 22, "price": 550, "zone": 4, "mesh": ""},
	"escudo_platino": {"name": "Escudo de platino", "article": "un", "slot": SHIELD,
		"bonus": 10, "price": 300, "zone": 4, "mesh": "Spike_Shield"},
}


static func exists(id: String) -> bool:
	return EQUIPMENT.has(id)


static func display_name(id: String) -> String:
	return EQUIPMENT[id].name if EQUIPMENT.has(id) else id


static func article(id: String) -> String:
	return EQUIPMENT[id].article if EQUIPMENT.has(id) else "un"


## "lo" or "la", for "¿Te lo equipas ahora?".
static func pronoun(id: String) -> String:
	return "la" if article(id) == "una" else "lo"


static func slot(id: String) -> String:
	return EQUIPMENT[id].slot if EQUIPMENT.has(id) else ""


## ATK for a weapon, DEF for armor and shields; 0 for "" (nothing worn).
static func bonus(id: String) -> int:
	return EQUIPMENT[id].bonus if EQUIPMENT.has(id) else 0


static func price(id: String) -> int:
	return EQUIPMENT[id].price if EQUIPMENT.has(id) else 0


static func mesh(id: String) -> String:
	return EQUIPMENT[id].mesh if EQUIPMENT.has(id) else ""


## "ATK" for weapons, "DEF" for the rest.
static func stat_name(id: String) -> String:
	return "ATK" if slot(id) == WEAPON else "DEF"


## The ids sold in a zone, in catalog order.
static func of_zone(zone: int) -> Array[String]:
	var ids: Array[String] = []
	for id: String in EQUIPMENT:
		if EQUIPMENT[id].zone == zone:
			ids.append(id)
	return ids
