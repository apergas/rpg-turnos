class_name Loadout extends RefCounted
## What the hero wears: one Equipment id per slot ("" for an empty slot). Starts with the
## Palo and the Ropa and nothing else. Pure: no nodes; GameState copies the bonuses into the
## hero (Combatant.equip_attack / equip_defense).

var _slots := {
	Equipment.WEAPON: Equipment.STICK,
	Equipment.ARMOR: Equipment.CLOTHES,
	Equipment.SHIELD: "",
	Equipment.HELMET: "",
	Equipment.RING: "",
	Equipment.AMULET: "",
}


## The id worn in slot ("" if empty).
func worn(slot: String) -> String:
	return _slots.get(slot, "")


func is_worn(id: String) -> bool:
	return id != "" and worn(Equipment.slot(id)) == id


## Puts id on in its slot and returns what was there ("" if it was empty).
func equip(id: String) -> String:
	var slot := Equipment.slot(id)
	var removed: String = _slots[slot]
	_slots[slot] = id
	return removed


## Empties slot and returns what was there ("" if it was already empty).
func unequip(slot: String) -> String:
	var removed: String = _slots[slot]
	_slots[slot] = ""
	return removed


## The weapon's ATK plus the extra ATK of every other piece worn (Equipment.extra_attack()).
func attack_bonus() -> int:
	var total := Equipment.bonus(worn(Equipment.WEAPON))
	for slot in Equipment.SLOTS:
		total += Equipment.extra_attack(worn(slot))
	return total


## The armor's, shield's and helmet's DEF plus the extra DEF of every piece worn
## (Equipment.extra_defense(): the Amuleto del vigía).
func defense_bonus() -> int:
	var total := Equipment.bonus(worn(Equipment.ARMOR)) + Equipment.bonus(worn(Equipment.SHIELD)) \
		+ Equipment.bonus(worn(Equipment.HELMET))
	for slot in Equipment.SLOTS:
		total += Equipment.extra_defense(worn(slot))
	return total


## The VEL of the ring and the amulet.
func speed_bonus() -> int:
	var total := 0
	for slot in Equipment.ACCESSORY_SLOTS:
		total += Equipment.bonus(worn(slot))
	return total


## The status effects what is worn keeps away.
func immunities() -> Array[String]:
	var immune: Array[String] = []
	for slot in Equipment.SLOTS:
		var status := Equipment.immunity(worn(slot))
		if status != "":
			immune.append(status)
	return immune


## Copy as slot -> id, for the save game.
func to_dict() -> Dictionary:
	return _slots.duplicate()


## Replaces every slot (slot -> id), when a game is loaded. Unknown slots are ignored.
func set_slots(slots: Dictionary) -> void:
	for slot in Equipment.SLOTS:
		_slots[slot] = slots.get(slot, "")
