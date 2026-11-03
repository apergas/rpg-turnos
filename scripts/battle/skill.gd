class_name Skill extends Resource
## A spell. DAMAGE: power times the usual damage spread, ignoring DEF, with no miss and
## no crit, ×1.5 on a target weak to its element and ×0.5 on one that resists it; it may
## also cause its status. HEAL: the caster recovers power HP. STATUS: only tries to
## cause its status. targets ONE (the hero picks the enemy) or ALL (every enemy).

const DAMAGE := "damage"
const HEAL := "heal"
const STATUS := "status"
const ONE := "one"
const ALL := "all"
const FIRE := "fire"
const ICE := "ice"
const THUNDER := "thunder"

@export var id := ""
@export var display_name := ""
@export var mp_cost := 0
@export var power := 0
## Color of the caster's glow and of the ball that hits the target.
@export var color := Color(1.0, 0.45, 0.1)
## "" (none), FIRE, ICE or THUNDER.
@export var element := ""
@export var kind := DAMAGE
@export var targets := ONE
## Status it may cause on each target it hits ("" for none) and the chance (0..1).
@export var status := ""
@export var status_chance := 0.0


## True if the hero has to pick one enemy for it.
func needs_target() -> bool:
	return kind != HEAL and targets == ONE
