class_name Allies extends RefCounted
## The caravan's companions and the creatures the Domadora of each village sells: a fighter that acts by itself in
## battle. Only one at a time; a new one replaces the old one with nothing paid back, and
## one of a lower tier can't be bought. Pure: no nodes.

const CREATURES := {
	"gallina": {"article": "una", "tier": 1, "price": 55,
		"data": preload("res://data/allies/gallina.tres")},
	"lobezno": {"article": "un", "tier": 2, "price": 190,
		"data": preload("res://data/allies/lobezno.tres")},
	"golem_pequeno": {"article": "un", "tier": 3, "price": 490,
		"data": preload("res://data/allies/golem_pequeno.tres")},
	"esqueleto_leal": {"article": "un", "tier": 4, "price": 750,
		"data": preload("res://data/allies/esqueleto_leal.tres")},
	# The caravan's companions (the v2): chosen once from the Jefe de caravana, free, never
	# replaced. Their numbers grow with the tramo (GROWTH).
	"brena": {"article": "", "tier": 5, "price": 0, "companion": true,
		"line": "Guerrera. Golpea fuerte, pero es lenta.",
		"data": preload("res://data/allies/brena.tres")},
	"tadeo": {"article": "", "tier": 5, "price": 0, "companion": true,
		"line": "Explorador. Rápido: suele golpear el primero.",
		"data": preload("res://data/allies/tadeo.tres")},
	"ulma": {"article": "", "tier": 5, "price": 0, "companion": true,
		"line": "Escudera. Aguanta mucho sin caer.",
		"data": preload("res://data/allies/ulma.tres")},
}
## The companions, in the order the Jefe de caravana shows them.
const COMPANIONS: Array[String] = ["brena", "tadeo", "ulma"]
## What each tramo after the first adds to a companion's numbers.
const GROWTH := {
	"brena": {"max_hp": 40, "attack": 12, "defense": 6, "speed": 2},
	"tadeo": {"max_hp": 35, "attack": 10, "defense": 5, "speed": 4},
	"ulma": {"max_hp": 55, "attack": 8, "defense": 10, "speed": 1},
}
## What the companion says the first time the hero reaches each land of the caravan:
## zone id -> companion id -> line (2.4.0). Remembered with the world flag ARRIVAL_PREFIX
## + zone id.
const ARRIVALS := {
	"jungla": {
		"brena": "Qué calor. Si algo se mueve entre las hojas, le pego. Si no se mueve, también.",
		"tadeo": "Huele a lluvia, a flores y a algo que nos quiere comer. Por ese orden.",
		"ulma": "Mantente detrás de mi escudo. Y no toques las ranas azules: no son caramelos.",
	},
	"desierto": {
		"brena": "Arena en las botas, arena en el pelo... Hasta en el desayuno había arena.",
		"tadeo": "Si ves un lago a lo lejos, no corras. Es mentira. Lo sé por experiencia.",
		"ulma": "Mi escudo quema al sol. Ahora sirve también de sartén.",
	},
	"montana_1": {
		"brena": "¡Por fin fresquito! En la jungla sudaba hasta la espada.",
		"tadeo": "Me castañetean los dientes. No es miedo: es ritmo.",
		"ulma": "He traído dos mantas. Una es para mí y la otra también.",
	},
	"ciudad_1": {
		"brena": "Qué silencio. No me gustan los sitios donde nadie se queja.",
		"tadeo": "Mira esas casas. Seguro que alguna tenía una despensa llena.",
		"ulma": "Esqueletos de guardia. Ponte detrás de mí y no hagas ruido.",
	},
}
const ARRIVAL_PREFIX := "llegada_"
## Each arrival zone's tramo boss: a save past it has heard (or skipped) that line.
const ARRIVAL_BOSSES := {"jungla": "jaguar_sombrio", "desierto": "gusano_dunas",
	"montana_1": "grifo_cumbre", "ciudad_1": "guardian_ciudad"}
## The upper floors count as their land's arrival zone.
const ARRIVAL_REGIONS := {"montana_2": "montana_1", "ciudad_2": "ciudad_1"}


static func is_companion(id: String) -> bool:
	return CREATURES.has(id) and CREATURES[id].get("companion", false)


## "Compañero" or "Criatura": how the menus name what fights beside the hero.
static func kind_name(id: String) -> String:
	return "Compañero" if is_companion(id) else "Criatura"


## The companion's line in the Compañeros list ("" for a creature).
static func line(id: String) -> String:
	return CREATURES[id].get("line", "")


static func exists(id: String) -> bool:
	return CREATURES.has(id)


static func display_name(id: String) -> String:
	return (CREATURES[id].data as Combatant).display_name if CREATURES.has(id) else ""


static func article(id: String) -> String:
	return CREATURES[id].article


static func price(id: String) -> int:
	return CREATURES[id].price


## 0 for "" (no creature).
static func tier(id: String) -> int:
	return CREATURES[id].tier if CREATURES.has(id) else 0


## A fresh copy, with its life full: it comes back healed for every battle. A companion
## gets GROWTH once for every tramo after the first (tramo 0 or 1: its own numbers).
static func data(id: String, tramo := 1) -> Combatant:
	var copy := (CREATURES[id].data as Combatant).duplicate() as Combatant
	if is_companion(id):
		var steps := maxi(tramo - 1, 0)
		var growth: Dictionary = GROWTH[id]
		copy.max_hp += growth.max_hp * steps
		copy.attack += growth.attack * steps
		copy.defense += growth.defense * steps
		copy.speed += growth.speed * steps
	copy.hp = copy.max_hp
	return copy


static func stats_text(id: String) -> String:
	var c: Combatant = CREATURES[id].data
	return "PV %d  ATK %d  DEF %d" % [c.max_hp, c.attack, c.defense]


## The companion's line on first reaching zone_id ("" for none: no companion, or not an
## arrival zone).
static func arrival_line(id: String, zone_id: String) -> String:
	return ARRIVALS.get(zone_id, {}).get(id, "")


static func arrival_flag(zone_id: String) -> String:
	return ARRIVAL_PREFIX + zone_id


## A loaded game: the arrival lines of the lands already left behind (their boss beaten)
## and of the land it stands in are taken as heard, so loading in the jungle never says
## "first time here". Works on GameState.world_flags.
static func mark_arrivals(flags: Dictionary, zone_id: String) -> void:
	for zone: String in ARRIVAL_BOSSES:
		if flags.get(ARRIVAL_BOSSES[zone], false):
			flags[arrival_flag(zone)] = true
	var here: String = ARRIVAL_REGIONS.get(zone_id, zone_id)
	if ARRIVALS.has(here):
		flags[arrival_flag(here)] = true
