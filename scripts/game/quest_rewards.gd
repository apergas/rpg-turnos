class_name QuestRewards extends RefCounted
## Pays a finished quest. Pure: works on a GameState and returns the lines that say so.
## The gold counts as gold won for the credits; a piece of equipment goes on at once if its
## slot is empty, else into the bag, like a chest's. A boss's prize is put on at once
## instead (wear_prize()).


static func give(state: GameState, quest: QuestData) -> Array[String]:
	var lines: Array[String] = []
	if quest.reward_gold > 0:
		state.gold += quest.reward_gold
		state.gold_earned += quest.reward_gold
		lines.append("Recibes %d monedas de oro." % quest.reward_gold)
	for id: String in quest.reward_items:
		var amount: int = quest.reward_items[id]
		state.inventory.add(id, amount)
		if amount > 1:
			lines.append("Recibes %s ×%d." % [Inventory.display_name(id), amount])
		else:
			lines.append("Recibes %s %s." % [Inventory.article(id), Inventory.display_name(id)])
	if quest.reward_equipment != "":
		lines.append(_give_piece(state, quest.reward_equipment))
	return lines


## A boss's first-victory prize (Combatant.reward_equipment): put on at once; what was
## worn in its slot goes to the bag. Returns the lines that say so.
static func wear_prize(state: GameState, piece: String) -> Array[String]:
	var lines: Array[String] = ["Recibes %s %s. Te %s pones." % [Equipment.article(piece),
		Equipment.display_name(piece), Equipment.pronoun(piece)]]
	var old := state.loadout.worn(Equipment.slot(piece))
	state.bag_equipment.append(piece)
	state.equip(piece)
	if old != "":
		lines.append("%s %s va a tu bolsa." % ["La" if Equipment.article(old) == "una" else "El",
			Equipment.display_name(old)])
	return lines


static func _give_piece(state: GameState, piece: String) -> String:
	var text := "Recibes %s %s." % [Equipment.article(piece), Equipment.display_name(piece)]
	state.bag_equipment.append(piece)
	if state.loadout.worn(Equipment.slot(piece)) == "":
		state.equip(piece)
		text += " Te %s equipas." % Equipment.pronoun(piece)
	else:
		text += " Está en tu bolsa."
	return text
