class_name Equipment extends RefCounted
## The equipment catalog: every weapon, helmet, armor, shield, ring and amulet, with its
## slot, bonus (ATK for a weapon, VEL for a ring or an amulet, DEF for the rest), price in
## gold, the zone whose shop sells it (0: no shop, the starting gear; -1: never sold, a
## quest's or a bestiary family's reward, a boss's prize or the Coleccionista's), the mesh the hero
## shows for it
## (a handslot mesh of Knight.glb, STICK_MESH built in code, or "" for none) and, on some
## rings and amulets, the status it keeps away ("immune"). A piece that is not a weapon may
## also add "attack" (extra_attack()); a helmet may show "horns" (has_horns()); a helmet or a
## weapon may have a "tint" for its mesh (tint()).
## Pure: no nodes.

const WEAPON := "weapon"
const ARMOR := "armor"
const SHIELD := "shield"
const HELMET := "helmet"
## The two accessory slots (one "accessory" slot until 1.6.0: SaveData.RING_VERSION).
const RING := "ring"
const AMULET := "amulet"
## Slot order of every list (status, Equipo page, shop comparison).
const SLOTS: Array[String] = [WEAPON, HELMET, ARMOR, SHIELD, RING, AMULET]
const SLOT_NAMES := {WEAPON: "Arma", HELMET: "Casco", ARMOR: "Armadura", SHIELD: "Escudo",
	RING: "Anillo", AMULET: "Amuleto"}
## The slots whose bonus is VEL and whose pieces are never compared on the Equipo page.
const ACCESSORY_SLOTS: Array[String] = [RING, AMULET]

const STICK := "palo"
const CLOTHES := "ropa"
const COPPER_SWORD := "espada_cobre"
const LEATHER_MAIL := "cota_cuero"
const WOODEN_SHIELD := "escudo_madera"
const POISON_RING := "anillo_antiveneno"
const SPEED_AMULET := "amuleto_velocidad"
## The Eco de la Niebla's prize: the one helmet that adds ATK too, with horns.
const MIST_HELM := "yelmo_bruma"
## The prizes of the bestiary's families (Bestiary.FAMILIES): never sold.
const CRYSTAL_RING := "anillo_cristal"
const SAP_RING := "anillo_savia"
const FANG_AMULET := "amuleto_colmillo"
const BONE_AMULET := "amuleto_hueso"
const DAWN_SWORD := "espada_alba"
## The Coleccionista's prizes (Medals.PRIZES): never sold.
const MEDAL_SHIELD := "escudo_medallas"
const MEDAL_MAIL := "cota_medallas"
const MEDAL_AMULET := "amuleto_medallas"
## What effect_text() says of each status a piece keeps away.
const IMMUNE_TEXTS := {"poison": "Inmune al veneno", "sleep": "Inmune al sueño",
	"silence": "Inmune al silencio"}
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
	# The caravan, stage 1 (the jungle): jade, the platinum meshes tinted green.
	"espada_jade": {"name": "Espada de jade", "article": "una", "slot": WEAPON,
		"bonus": 38, "price": 900, "zone": 5, "mesh": "2H_Sword", "tint": Color(0.55, 1.0, 0.65)},
	"armadura_jade": {"name": "Armadura de jade", "article": "una", "slot": ARMOR,
		"bonus": 28, "price": 750, "zone": 5, "mesh": ""},
	"escudo_jade": {"name": "Escudo de jade", "article": "un", "slot": SHIELD,
		"bonus": 13, "price": 420, "zone": 5, "mesh": "Spike_Shield",
		"tint": Color(0.55, 1.0, 0.65)},
	"casco_jade": {"name": "Casco de jade", "article": "un", "slot": HELMET, "bonus": 9,
		"price": 330, "zone": 5, "mesh": "", "tint": Color(0.5, 1.05, 0.62)},
	# The caravan, tramo 2 (the desert): orichalcum, the platinum meshes tinted reddish gold.
	"espada_oricalco": {"name": "Espada de oricalco", "article": "una", "slot": WEAPON,
		"bonus": 48, "price": 1300, "zone": 6, "mesh": "2H_Sword",
		"tint": Color(1.15, 0.72, 0.42)},
	"armadura_oricalco": {"name": "Armadura de oricalco", "article": "una", "slot": ARMOR,
		"bonus": 35, "price": 1100, "zone": 6, "mesh": ""},
	"escudo_oricalco": {"name": "Escudo de oricalco", "article": "un", "slot": SHIELD,
		"bonus": 16, "price": 600, "zone": 6, "mesh": "Spike_Shield",
		"tint": Color(1.15, 0.72, 0.42)},
	"casco_oricalco": {"name": "Casco de oricalco", "article": "un", "slot": HELMET,
		"bonus": 11, "price": 480, "zone": 6, "mesh": "", "tint": Color(1.15, 0.74, 0.45)},
	# The caravan, tramo 3 (the mountain): adamantite, the platinum meshes tinted violet steel.
	"espada_adamantita": {"name": "Espada de adamantita", "article": "una", "slot": WEAPON,
		"bonus": 60, "price": 1750, "zone": 7, "mesh": "2H_Sword",
		"tint": Color(0.72, 0.66, 1.1)},
	"armadura_adamantita": {"name": "Armadura de adamantita", "article": "una", "slot": ARMOR,
		"bonus": 44, "price": 1450, "zone": 7, "mesh": ""},
	"escudo_adamantita": {"name": "Escudo de adamantita", "article": "un", "slot": SHIELD,
		"bonus": 20, "price": 800, "zone": 7, "mesh": "Spike_Shield",
		"tint": Color(0.72, 0.66, 1.1)},
	"casco_adamantita": {"name": "Casco de adamantita", "article": "un", "slot": HELMET,
		"bonus": 14, "price": 640, "zone": 7, "mesh": "", "tint": Color(0.74, 0.68, 1.12)},
	# The Eco de la Niebla's prize (the first time only): DEF like any helmet, plus ATK,
	# dark grey with a blue cast and two bone horns (BattleActor builds them).
	MIST_HELM: {"name": "Yelmo de bruma", "article": "un", "slot": HELMET, "bonus": 8,
		"price": 0, "zone": -1, "mesh": "", "tint": Color(0.42, 0.47, 0.6), "attack": 5,
		"horns": true},
	POISON_RING: {"name": "Anillo antiveneno", "article": "un", "slot": RING,
		"bonus": 0, "price": 0, "zone": -1, "mesh": "", "immune": "poison"},
	SPEED_AMULET: {"name": "Amuleto de velocidad", "article": "un", "slot": AMULET,
		"bonus": 3, "price": 0, "zone": -1, "mesh": ""},
	# The bestiary families' prizes (Bestiary): VEL and ATK, or a status kept away.
	CRYSTAL_RING: {"name": "Anillo de cristal", "article": "un", "slot": RING, "bonus": 2,
		"price": 0, "zone": -1, "mesh": "", "attack": 2},
	SAP_RING: {"name": "Anillo de savia", "article": "un", "slot": RING, "bonus": 0,
		"price": 0, "zone": -1, "mesh": "", "immune": "sleep"},
	FANG_AMULET: {"name": "Amuleto de colmillo", "article": "un", "slot": AMULET, "bonus": 1,
		"price": 0, "zone": -1, "mesh": "", "attack": 4},
	BONE_AMULET: {"name": "Amuleto de hueso", "article": "un", "slot": AMULET, "bonus": 0,
		"price": 0, "zone": -1, "mesh": "", "immune": "silence"},
	# The Jefes family's prize: the best sword, a two-handed one tinted pale gold.
	DAWN_SWORD: {"name": "Espada del alba", "article": "una", "slot": WEAPON, "bonus": 34,
		"price": 0, "zone": -1, "mesh": "2H_Sword", "tint": Color(1.35, 1.15, 0.6)},
	# The Coleccionista's prizes (Medals): the platinum shield's mesh in gold, a mail no
	# figure shows (no armor has a mesh) and an amulet that adds ATK too.
	MEDAL_SHIELD: {"name": "Escudo de medallas", "article": "un", "slot": SHIELD, "bonus": 12,
		"price": 0, "zone": -1, "mesh": "Spike_Shield", "tint": Color(1.4, 1.1, 0.45)},
	MEDAL_MAIL: {"name": "Cota de medallas", "article": "una", "slot": ARMOR, "bonus": 25,
		"price": 0, "zone": -1, "mesh": ""},
	MEDAL_AMULET: {"name": "Amuleto de medallas", "article": "un", "slot": AMULET, "bonus": 4,
		"price": 0, "zone": -1, "mesh": "", "attack": 3},
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


## The color a piece tints its mesh with (a helmet, the Espada del alba); white for none.
static func tint(id: String) -> Color:
	return EQUIPMENT[id].get("tint", Color.WHITE) if EQUIPMENT.has(id) else Color.WHITE


## The color a helmet tints the model's helmet mesh with.
static func helmet_tint(id: String) -> Color:
	return tint(id)


## "ATK" for weapons, "VEL" for rings and amulets, "DEF" for the rest.
static func stat_name(id: String) -> String:
	if slot(id) == WEAPON:
		return "ATK"
	if slot(id) in ACCESSORY_SLOTS:
		return "VEL"
	return "DEF"


## The status this piece keeps away ("" for none).
static func immunity(id: String) -> String:
	return EQUIPMENT[id].get("immune", "") if EQUIPMENT.has(id) else ""


## The ATK a piece that is not a weapon adds besides its bonus (the Yelmo de bruma, the
## Anillo de cristal, the Amuleto de colmillo); 0 for the rest.
static func extra_attack(id: String) -> int:
	return EQUIPMENT[id].get("attack", 0) if EQUIPMENT.has(id) else 0


## True for a helmet the hero wears with horns (the Yelmo de bruma).
static func has_horns(id: String) -> bool:
	return EQUIPMENT[id].get("horns", false) if EQUIPMENT.has(id) else false


## What a piece gives, for the Equipo page: "ATK +6", "VEL +2 · ATK +2", "Inmune al sueño".
static func effect_text(id: String) -> String:
	if immunity(id) != "":
		return IMMUNE_TEXTS.get(immunity(id), "Inmune")
	var text := "%s +%d" % [stat_name(id), bonus(id)]
	if extra_attack(id) > 0:
		text += " · ATK +%d" % extra_attack(id)
	return text


## The ids sold in a zone, in catalog order.
static func of_zone(zone: int) -> Array[String]:
	var ids: Array[String] = []
	for id: String in EQUIPMENT:
		if EQUIPMENT[id].zone == zone:
			ids.append(id)
	return ids
