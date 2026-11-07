class_name Equipment extends RefCounted
## The equipment catalog: every weapon, armor, shield and accessory, with its slot, bonus
## (ATK for a weapon, DEF for armor and shields, VEL for an accessory), price in gold, the
## zone whose shop sells it (0: no shop, the starting gear; -1: never sold, a quest's
## reward), the mesh the hero shows for it (a handslot mesh of Knight.glb, STICK_MESH built
## in code, or "" for none) and, on some accessories, the status it keeps away ("immune").
## Pure: no nodes.

const WEAPON := "weapon"
const ARMOR := "armor"
const SHIELD := "shield"
const ACCESSORY := "accessory"
const HELMET := "helmet"
## Slot order of every list (status, Equipo page, shop comparison).
const SLOTS: Array[String] = [WEAPON, HELMET, ARMOR, SHIELD, ACCESSORY]
const SLOT_NAMES := {WEAPON: "Arma", HELMET: "Casco", ARMOR: "Armadura", SHIELD: "Escudo",
	ACCESSORY: "Accesorio"}

const STICK := "palo"
const CLOTHES := "ropa"
const COPPER_SWORD := "espada_cobre"
const LEATHER_MAIL := "cota_cuero"
const WOODEN_SHIELD := "escudo_madera"
const POISON_RING := "anillo_antiveneno"
const SPEED_AMULET := "amuleto_velocidad"
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
	"casco_cobre": {"name": "Casco de cobre", "article": "un", "slot": HELMET, "bonus": 2,
		"price": 20, "zone": 1, "mesh": "", "tint": Color(1.4, 0.58, 0.18)},
	"casco_hierro": {"name": "Casco de hierro", "article": "un", "slot": HELMET, "bonus": 3,
		"price": 70, "zone": 2, "mesh": "", "tint": Color(0.7, 0.7, 0.72)},
	"casco_acero": {"name": "Casco de acero", "article": "un", "slot": HELMET, "bonus": 5,
		"price": 180, "zone": 3, "mesh": "", "tint": Color(0.95, 0.97, 1.0)},
	"casco_platino": {"name": "Casco de platino", "article": "un", "slot": HELMET, "bonus": 7,
		"price": 260, "zone": 4, "mesh": "", "tint": Color(0.85, 0.9, 1.2)},
	POISON_RING: {"name": "Anillo antiveneno", "article": "un", "slot": ACCESSORY,
		"bonus": 0, "price": 0, "zone": -1, "mesh": "", "immune": "poison"},
	SPEED_AMULET: {"name": "Amuleto de velocidad", "article": "un", "slot": ACCESSORY,
		"bonus": 3, "price": 0, "zone": -1, "mesh": ""},
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


## The color a helmet tints the model's helmet mesh with.
static func helmet_tint(id: String) -> Color:
	return EQUIPMENT[id].get("tint", Color.WHITE) if EQUIPMENT.has(id) else Color.WHITE


## "ATK" for weapons, "VEL" for accessories, "DEF" for the rest.
static func stat_name(id: String) -> String:
	match slot(id):
		WEAPON:
			return "ATK"
		ACCESSORY:
			return "VEL"
	return "DEF"


## The status this piece keeps away ("" for none).
static func immunity(id: String) -> String:
	return EQUIPMENT[id].get("immune", "") if EQUIPMENT.has(id) else ""


## What a piece gives, for the Equipo page: "ATK +6", "VEL +3", "Inmune al veneno".
static func effect_text(id: String) -> String:
	if immunity(id) == "poison":
		return "Inmune al veneno"
	return "%s +%d" % [stat_name(id), bonus(id)]


## The ids sold in a zone, in catalog order.
static func of_zone(zone: int) -> Array[String]:
	var ids: Array[String] = []
	for id: String in EQUIPMENT:
		if EQUIPMENT[id].zone == zone:
			ids.append(id)
	return ids
