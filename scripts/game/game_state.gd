class_name GameState extends RefCounted
## State of the play session, kept in memory while the game is open. The hero, the
## inventory, the gold and the village quest live here for the whole session; battles
## and dialogue change them in place.

var hero: Combatant
var inventory := Inventory.new()
var quest := Quest.new()
## Gold won in battle (shops come in a later phase).
var gold := 0


func _init(hero_data: Combatant) -> void:
	hero = hero_data.duplicate() as Combatant
	# Its own list: learning a spell must never change the one in hero.tres.
	hero.skills = hero_data.skills.duplicate()
	inventory.add(Inventory.POTION, Inventory.START_POTIONS)


## Back to full HP and MP, used after a defeat and when talking to the old woman.
func heal_full() -> void:
	hero.hp = hero.max_hp
	hero.mp = hero.max_mp


## Uses an item outside battle, from the pause menu; see Inventory.use().
func use_item(id: String) -> Dictionary:
	return inventory.use(id, hero, false)
