class_name Inventory extends RefCounted
## Items the hero carries, as id -> count. GameState keeps one for the whole session.
## ITEMS describes every item; use() applies one to a Combatant and is shared by the
## battle (BattleEngine) and the pause menu.

const POTION := "potion"
const ETHER := "ether"
const ANTIDOTE := "antidote"
const WING := "wing"
const SETA := "seta"
const SEED_ATTACK := "semilla_fuerza"
const SEED_DEFENSE := "semilla_defensa"
const SEED_SPEED := "semilla_agilidad"
const START_POTIONS := 3
## What a seed adds to its stat, for good.
const SEED_BONUS := 2
const SEEDS: Array[String] = [SEED_ATTACK, SEED_DEFENSE, SEED_SPEED]
## name and article (for "una Poción"); effect "hp" (heals value HP), "mp" (restores
## value MP), "cure" (removes the status named by value), "travel" (the Ala de viaje:
## Game takes the hero to the last village visited and leaves a portal there that leads
## back once), "seed" (adds SEED_BONUS to the Combatant field named by value) or "quest"
## (of no use: someone is asking for it); price in gold (Shop sells at it and
## buys back at half); battle / field: usable in battle / from the pause menu; text: what
## it does, shown in the shop, in Objetos and in battle.
const ITEMS := {
	POTION: {"name": "Poción", "article": "una", "effect": "hp", "value": 30, "price": 8,
		"battle": true, "field": true, "text": "Recupera 30 PV."},
	ETHER: {"name": "Éter", "article": "un", "effect": "mp", "value": 15, "price": 30,
		"battle": true, "field": true, "text": "Recupera 15 PM."},
	ANTIDOTE: {"name": "Antídoto", "article": "un", "effect": "cure", "value": "poison",
		"price": 10, "battle": true, "field": false, "text": "Cura el veneno."},
	WING: {"name": "Ala de viaje", "article": "un", "effect": "travel", "value": 0,
		"price": 25, "battle": false, "field": true,
		"text": "Te lleva al último pueblo y deja un portal para volver una vez."},
	SETA: {"name": "Seta", "article": "una", "effect": "quest", "value": 0, "price": 4,
		"battle": false, "field": false,
		"text": "De las que saltan. Alguien de Villaclaro las anda buscando."},
	SEED_ATTACK: {"name": "Semilla de fuerza", "article": "una", "effect": "seed",
		"value": "attack", "price": 0, "battle": false, "field": true,
		"text": "Sube el ATK en 2 para siempre."},
	SEED_DEFENSE: {"name": "Semilla de defensa", "article": "una", "effect": "seed",
		"value": "defense", "price": 0, "battle": false, "field": true,
		"text": "Sube la DEF en 2 para siempre."},
	SEED_SPEED: {"name": "Semilla de agilidad", "article": "una", "effect": "seed",
		"value": "speed", "price": 0, "battle": false, "field": true,
		"text": "Sube la VEL en 2 para siempre."},
}
## Order of the item lists.
const IDS: Array[String] = [POTION, ETHER, ANTIDOTE, WING, SEED_ATTACK, SEED_DEFENSE,
	SEED_SPEED, SETA]
## Why an Ala de viaje can't be used in a village.
const IN_TOWN := "Ya estás en un pueblo"
## Why a "quest" item can't be used.
const QUEST_ITEM := "Para una misión"
## The stat a seed raises, as the status windows name it.
const SEED_STATS := {"attack": "ATK", "defense": "DEF", "speed": "VEL"}
## Key items (GameState.key_items): never used up, sold or dropped; id -> name.
const KEY_ITEMS := {
	"fragmento_bosque": "Fragmento del amuleto (1/3)",
	"fragmento_mina": "Fragmento del amuleto (2/3)",
	"fragmento_castillo": "Fragmento del amuleto (3/3)",
	"llave_mina": "Llave de la mina",
	"carta_granjero": "Carta del Granjero",
}
## What each key item is, for Objetos.
const KEY_TEXTS := {
	"fragmento_bosque": "Un trozo del Amuleto del Alba. Lo guardaba la Bruja del bosque.",
	"fragmento_mina": "Un trozo del Amuleto del Alba. Lo guardaba el Golem de piedra.",
	"fragmento_castillo": "El último trozo del Amuleto del Alba. Lo guardaba el Señor de la Niebla.",
	"llave_mina": "Abre la reja de la tercera planta de la mina.",
	"carta_granjero": "Para la Leñadora, en la aldea del bosque. Huele un poco a gallina.",
}

var _items := {}


static func display_name(id: String) -> String:
	return ITEMS[id].name if ITEMS.has(id) else id


static func article(id: String) -> String:
	return ITEMS[id].article if ITEMS.has(id) else "un"


## "ATK", "DEF" or "VEL" for a seed.
static func seed_stat(id: String) -> String:
	return SEED_STATS.get(ITEMS[id].value, "") if ITEMS.has(id) else ""


## What an item or a key item does, in a short sentence.
static func description(id: String) -> String:
	return ITEMS[id].text if ITEMS.has(id) else KEY_TEXTS.get(id, "")


func count(id: String) -> int:
	return _items.get(id, 0)


func add(id: String, n := 1) -> void:
	_items[id] = count(id) + n


## Removes one; false if there was none.
func take(id: String) -> bool:
	if count(id) <= 0:
		return false
	_items[id] = count(id) - 1
	return true


## Why the item can't be used on c now, in battle or from the menu ("" if it can).
func problem(id: String, c: Combatant, in_battle: bool) -> String:
	if count(id) <= 0:
		return "No te quedan"
	var item: Dictionary = ITEMS[id]
	if item.effect == "quest":
		return QUEST_ITEM
	if in_battle and not item.battle:
		return "Fuera de combate"
	if not in_battle and not item.field:
		return "Solo en combate"
	match item.effect:
		"hp":
			if c.hp >= c.max_hp:
				return "PV al máximo"
		"mp":
			if c.mp >= c.max_mp:
				return "PM al máximo"
		"cure":
			if not c.status.has(item.value):
				return "No hace falta"
	return ""


## Takes one and applies it to c. Returns {"used": bool, "effect": String, "amount":
## int (HP or MP recovered), "status": String (cured), "reason": String (why not)}. A
## "travel" item only gets used up: the caller does the trip.
func use(id: String, c: Combatant, in_battle: bool) -> Dictionary:
	var reason := problem(id, c, in_battle)
	if reason != "":
		return {"used": false, "effect": "", "amount": 0, "status": "", "reason": reason}
	take(id)
	var item: Dictionary = ITEMS[id]
	var result := {"used": true, "effect": item.effect, "amount": 0, "status": "",
		"reason": ""}
	match item.effect:
		"hp":
			result.amount = mini(item.value, c.max_hp - c.hp)
			c.hp += result.amount
		"mp":
			result.amount = mini(item.value, c.max_mp - c.mp)
			c.mp += result.amount
		"cure":
			c.status.erase(item.value)
			result.status = item.value
		"seed":
			c.set(item.value, int(c.get(item.value)) + SEED_BONUS)
			result.amount = SEED_BONUS
	return result


## Copy of the items as id -> count, for the save game.
func to_dict() -> Dictionary:
	return _items.duplicate()


## Replaces every item with these (id -> count), when a game is loaded.
func set_items(items: Dictionary) -> void:
	_items = items.duplicate()
