class_name MapCompanion extends Node3D
## Node, a piece of World: the creature or the companion that walks behind the hero on the map
## (M-96, 3.6.0). Only a figure: no collider, no prompt, no sign and nothing on the map square,
## so the hero, the monsters and the walls never meet it. It walks GAP metres behind the hero
## along the path he walked (a trail of his positions), stands still when he does and, too far
## behind (SNAP_DISTANCE), appears behind him at once (snap_behind(), also on every placing). It
## hides during cutscenes and while its own figure stands on the map as a character (Brumaclara
## before brumaclara_vista, the ciudad after the Devorador: MapFigures.shows()). A companion
## wears Allies.gear() as in battle (BattleActor.set_companion_gear()), never the hero's rim.
## World creates it, calls step() in its physics tick and passes on set_ally() from
## Game._refresh_status(); never stores World.

const ACTOR_SCENE := preload("res://scenes/battle/battle_actor.tscn")
## Metres behind the hero, along his path.
const GAP := 1.6
## The trail: a point of the hero's path every TRAIL_STEP metres, the newest first,
## TRAIL_POINTS at most (10 m of path).
const TRAIL_STEP := 0.25
const TRAIL_POINTS := 40
## It walks at the hero's speed (Player.SPEED), CATCH_UP times faster while it is more than LAG
## metres from its spot.
const CATCH_UP := 1.5
const LAG := 0.4
## This close to its spot it stands still.
const ARRIVED := 0.05
## Farther than this from the hero (a tight corner, a shortcut), it appears behind him.
const SNAP_DISTANCE := 8.0

var _player: Player
var _figures: MapFigures
## The figure (null: no creature, no companion).
var _actor: BattleActor
var _ally_id := ""
var _gear := {}
## The hero's path, the newest point first (flat: y = 0).
var _trail: Array[Vector3] = []
## Hidden: a cutscene is on, or its own figure stands on the map.
var _in_scene := false
var _figure_shown := false


func setup(player: Player, figures: MapFigures) -> void:
	_player = player
	_figures = figures


func _ready() -> void:
	visible = false


## The creature or companion to show (an Allies id, "" for none) and its growth step
## (GameState.ally_step()): a new one is built and put behind the hero; the same one with
## another step only changes its gear (Allies.gear()).
func set_ally(ally_id: String, step: int) -> void:
	var gear: Dictionary = Allies.gear(ally_id, step) if ally_id != "" else {}
	if ally_id == _ally_id:
		if gear != _gear and _actor != null:
			_actor.set_companion_gear(gear)
		_gear = gear
		return
	_ally_id = ally_id
	_gear = gear
	if _actor != null:
		remove_child(_actor)
		_actor.queue_free()
		_actor = null
	if ally_id != "":
		_actor = ACTOR_SCENE.instantiate()
		_actor.look = EnemyLibrary.look(ally_id)
		add_child(_actor)
		_actor.set_companion_gear(gear)  # a creature ignores it
	refresh()
	snap_behind()


## Hidden while a figure with its name stands on the map (MapFigures.shows()); World calls it
## after every change of the figures shown.
func refresh() -> void:
	_figure_shown = _ally_id != "" and _figures.shows(Allies.display_name(_ally_id))
	_update_visible()


## A cutscene: hidden until end_scene(), which puts it behind the hero where the scene left him.
func begin_scene() -> void:
	_in_scene = true
	_update_visible()


func end_scene() -> void:
	_in_scene = false
	_update_visible()
	snap_behind()


## Behind the hero at once, facing where he faces: the trail starts over, straight behind him.
func snap_behind() -> void:
	_trail.clear()
	if _actor == null:
		return
	var hero := _flat(_player.global_position)
	var yaw := _player.model().rotation.y
	var back := Vector3(sin(yaw), 0.0, cos(yaw))  # the hero's model faces -Z turned by yaw
	for i in ceili(GAP / TRAIL_STEP) + 1:
		_trail.append(hero + back * TRAIL_STEP * i)
	position = _spot() + Vector3(0.0, _player.global_position.y, 0.0)
	_actor.rotation.y = yaw
	_actor.set_walking(false)


## Every physics tick (World, before its own checks, so also while a window holds the map): a
## point of the trail every TRAIL_STEP metres the hero walks, and a step toward the spot GAP
## metres behind him; the walk cycle while it moves, the idle one once there.
func step(delta: float) -> void:
	if not visible:
		return
	if _trail.is_empty():
		snap_behind()
		return
	var hero := _flat(_player.global_position)
	if hero.distance_to(_trail[0]) >= TRAIL_STEP:
		_trail.push_front(hero)
		if _trail.size() > TRAIL_POINTS:
			_trail.pop_back()
	var here := _flat(position)
	if here.distance_to(hero) > SNAP_DISTANCE:
		snap_behind()
		return
	var to_spot := _spot() - here
	var walking := to_spot.length() > ARRIVED
	if walking:
		var speed := Player.SPEED * (CATCH_UP if to_spot.length() > LAG else 1.0)
		position = here + to_spot.limit_length(speed * delta) \
			+ Vector3(0.0, _player.global_position.y, 0.0)
		var target_yaw := atan2(-to_spot.x, -to_spot.z)  # the model faces -Z
		_actor.rotation.y = lerp_angle(_actor.rotation.y, target_yaw,
			minf(1.0, Player.TURN_SPEED * delta))
	_actor.set_walking(walking)


## The point GAP metres behind the hero along his trail (its last point if it is shorter).
func _spot() -> Vector3:
	var left := GAP
	var from := _flat(_player.global_position)
	for point in _trail:
		var d := from.distance_to(point)
		if d >= left:
			return from.move_toward(point, left)
		left -= d
		from = point
	return from


## Shown only with a figure, out of cutscenes and with its own figure off the map; coming back
## into view it appears behind the hero.
func _update_visible() -> void:
	var shown := _actor != null and not _in_scene and not _figure_shown
	if shown and not visible:
		visible = true
		snap_behind()
	visible = shown


static func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)
