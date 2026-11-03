class_name Skill extends Resource
## A spell a combatant can cast. Every skill is magic damage for now: power times the
## usual damage spread, ignoring DEF, with no miss and no crit.

@export var id := ""
@export var display_name := ""
@export var mp_cost := 0
@export var power := 0
## Color of the caster's glow and of the ball that hits the target.
@export var color := Color(1.0, 0.45, 0.1)
