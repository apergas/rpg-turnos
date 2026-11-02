class_name Combatant extends Resource
## Stats of one fighter. Battles work on duplicates, so the .tres files never change.

@export var display_name := ""
@export var max_hp := 1
@export var hp := 1
@export var attack := 1
@export var defense := 0
@export var speed := 1
## EXP the winner gets for defeating this fighter.
@export var exp_reward := 0
## EXP accumulated so far (only meaningful for the hero). Not called `exp`, which
## would shadow the built-in exp() function.
@export var experience := 0


func is_alive() -> bool:
	return hp > 0
