class_name Combatant extends Resource
## Stats of one fighter. Battles work on duplicates, so the .tres files never change.

@export var display_name := ""
@export var level := 1
@export var max_hp := 1
@export var hp := 1
@export var max_mp := 0
@export var mp := 0
@export var attack := 1
@export var defense := 0
@export var speed := 1
@export var skills: Array[Skill] = []
## EXP the winner gets for defeating this fighter.
@export var exp_reward := 0
## EXP accumulated so far (only meaningful for the hero). Not called `exp`, which
## would shadow the built-in exp() function.
@export var experience := 0
## Enemy only: weights of the action it picks each round. Keys are "attack",
## "stagger" (loses the turn) or the id of one of its skills. Empty means always attack.
@export var ai_weights := {}
## Enemy only: chance of leaving a potion when defeated.
@export var potion_drop_chance := 0.0


func is_alive() -> bool:
	return hp > 0


func find_skill(id: String) -> Skill:
	for skill in skills:
		if skill.id == id:
			return skill
	return null
