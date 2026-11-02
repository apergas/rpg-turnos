class_name GameState extends RefCounted
## State of the play session, kept in memory while the game is open. The hero lives
## here for the whole session and battles change it in place (HP, EXP).

var hero: Combatant


func _init(hero_data: Combatant) -> void:
	hero = hero_data.duplicate() as Combatant


## Back to full HP, used after a defeat.
func heal_full() -> void:
	hero.hp = hero.max_hp
