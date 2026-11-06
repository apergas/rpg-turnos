class_name Loadout extends RefCounted
## What the hero wears: one Equipment id per slot ("" for an empty slot). Starts with the
## Palo and the Ropa and no shield. Pure: no nodes; GameState copies the bonuses into the
## hero (Combatant.equip_attack / equip_defense).

var _slots := {
	Equipment.WEAPON: Equipment.STICK,
	Equipment.ARMOR: Equipment.CLOTHES,
	Equipment.SHIELD: "",
	Equipment.ACCESSORY: "",
	Equipment.HELMET: "",
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


func attack_bonus() -> int:
	return Equipment.bonus(worn(Equipment.WEAPON))


func defense_bonus() -> int:
	return Equipment.bonus(worn(Equipment.ARMOR)) + Equipment.bonus(worn(Equipment.SHIELD)) \
		+ Equipment.bonus(worn(Equipment.HELMET))


func speed_bonus() -> int:
	return Equipment.bonus(worn(Equipment.ACCESSORY))


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
