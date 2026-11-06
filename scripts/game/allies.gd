class_name Allies extends RefCounted
## The creatures the Domadora of each village sells: a fighter that acts by itself in
## battle. Only one at a time; a new one replaces the old one with nothing paid back, and
## one of a lower tier can't be bought. Pure: no nodes.

const CREATURES := {
	"gallina": {"article": "una", "tier": 1, "price": 70,
		"data": preload("res://data/allies/gallina.tres")},
	"lobezno": {"article": "un", "tier": 2, "price": 250,
		"data": preload("res://data/allies/lobezno.tres")},
	"golem_pequeno": {"article": "un", "tier": 3, "price": 650,
		"data": preload("res://data/allies/golem_pequeno.tres")},
	"esqueleto_leal": {"article": "un", "tier": 4, "price": 1000,
		"data": preload("res://data/allies/esqueleto_leal.tres")},
}


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


## A fresh copy, with its life full: it comes back healed for every battle.
static func data(id: String) -> Combatant:
	return (CREATURES[id].data as Combatant).duplicate() as Combatant


static func stats_text(id: String) -> String:
	var c: Combatant = CREATURES[id].data
	return "PV %d  ATK %d  DEF %d" % [c.max_hp, c.attack, c.defense]
