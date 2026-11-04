class_name Inventory extends RefCounted
## Items the hero carries, as id -> count. GameState keeps one for the whole session.
## ITEMS describes every item; use() applies one to a Combatant and is shared by the
## battle (BattleEngine) and the pause menu.

const POTION := "potion"
const ETHER := "ether"
const ANTIDOTE := "antidote"
const WING := "wing"
const START_POTIONS := 3
## name and article (for "una Poción"); effect "hp" (heals value HP), "mp" (restores
## value MP), "cure" (removes the status named by value) or "travel" (the Ala de viaje:
## Game takes the hero to the last village visited); price in gold (Shop sells at it and
## buys back at half); battle / field: usable in battle / from the pause menu.
const ITEMS := {
	POTION: {"name": "Poción", "article": "una", "effect": "hp", "value": 30, "price": 8,
		"battle": true, "field": true},
	ETHER: {"name": "Éter", "article": "un", "effect": "mp", "value": 15, "price": 30,
		"battle": true, "field": true},
	ANTIDOTE: {"name": "Antídoto", "article": "un", "effect": "cure", "value": "poison",
		"price": 10, "battle": true, "field": false},
	WING: {"name": "Ala de viaje", "article": "un", "effect": "travel", "value": 0,
		"price": 25, "battle": false, "field": true},
}
## Order of the item lists.
const IDS: Array[String] = [POTION, ETHER, ANTIDOTE, WING]
## Key items (GameState.key_items): never used up, sold or dropped; id -> name.
const KEY_ITEMS := {
	"fragmento_bosque": "Fragmento del amuleto",
}

var _items := {}


static func display_name(id: String) -> String:
	return ITEMS[id].name if ITEMS.has(id) else id


static func article(id: String) -> String:
	return ITEMS[id].article if ITEMS.has(id) else "un"


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
	return result


## Copy of the items as id -> count, for the save game.
func to_dict() -> Dictionary:
	return _items.duplicate()


## Replaces every item with these (id -> count), when a game is loaded.
func set_items(items: Dictionary) -> void:
	_items = items.duplicate()
