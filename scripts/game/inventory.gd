class_name Inventory extends RefCounted
## Items the hero carries, as id -> count. GameState keeps one for the whole session.
## The potion is the only item for now: it heals POTION_HEAL HP and is used in battle.

const POTION := "potion"
const POTION_HEAL := 25
const START_POTIONS := 3
const NAMES := {POTION: "Poción"}

var _items := {}


static func display_name(id: String) -> String:
	return NAMES.get(id, id)


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


## Copy of the items as id -> count, for the save game.
func to_dict() -> Dictionary:
	return _items.duplicate()


## Replaces every item with these (id -> count), when a game is loaded.
func set_items(items: Dictionary) -> void:
	_items = items.duplicate()
