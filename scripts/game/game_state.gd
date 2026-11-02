class_name GameState extends RefCounted
## State of the play session, kept in memory while the game is open. The hero and the
## inventory live here for the whole session; battles change them in place.

var hero: Combatant
var inventory := Inventory.new()


func _init(hero_data: Combatant) -> void:
	hero = hero_data.duplicate() as Combatant
	inventory.add(Inventory.POTION, Inventory.START_POTIONS)


## Back to full HP and MP, used after a defeat.
func heal_full() -> void:
	hero.hp = hero.max_hp
	hero.mp = hero.max_mp
