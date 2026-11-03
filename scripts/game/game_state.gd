class_name GameState extends RefCounted
## State of the play session, kept in memory while the game is open. The hero, the
## inventory and the village quest live here for the whole session; battles and
## dialogue change them in place.

var hero: Combatant
var inventory := Inventory.new()
var quest := Quest.new()


func _init(hero_data: Combatant) -> void:
	hero = hero_data.duplicate() as Combatant
	inventory.add(Inventory.POTION, Inventory.START_POTIONS)


## Back to full HP and MP, used after a defeat and when talking to the old woman.
func heal_full() -> void:
	hero.hp = hero.max_hp
	hero.mp = hero.max_mp


## Drinks a potion outside battle. Returns the HP healed; 0 (and nothing used) without
## potions or at full HP.
func use_potion() -> int:
	if hero.hp >= hero.max_hp or not inventory.take(Inventory.POTION):
		return 0
	var healed := mini(Inventory.POTION_HEAL, hero.max_hp - hero.hp)
	hero.hp += healed
	return healed
