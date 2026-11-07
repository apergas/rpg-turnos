class_name Player extends CharacterBody3D
## Hero on the world map. Moves with WASD / arrows in screen axes (the top-down camera
## never turns: up is north, -Z), or walks to a point given by move_to() (a click or
## tap on the ground; keys cancel it). Turns smoothly toward where it walks and plays
## the walk animation while moving, the idle one when stopped. Its model is a
## BattleActor.
## With `-- --autoplay` it walks `route` (the zone's autoplay route) in a loop instead
## of reading keys.

const ACTOR_SCENE := preload("res://scenes/battle/battle_actor.tscn")
const SPEED := 5.0
## How fast the model turns toward the walking direction (radians per second, roughly).
const TURN_SPEED := 10.0
const ROUTE_REACHED := 0.6
## How close to a move_to() point counts as arrived.
const TARGET_REACHED := 0.3
## A move_to() walk gives up after this many frames moving under a quarter of SPEED
## (walking into a rock or a wall).
const STUCK_FRAMES := 12

var input_enabled := true
## A cutscene moves the player (CutscenePlayer tweens its position): no physics, no
## keys, no route and no animation of its own meanwhile.
var scripted := false
## Points walked in a loop on --autoplay (ZoneData.autoplay_route); set by World.
var route: Array[Vector3] = []
## Horizontal meters moved during the last physics frame.
var last_step_m := 0.0
## Point being walked to after a click or tap (y = 0); null when there is none.
var move_target: Variant = null
## Where the touch stick points (screen axes, set by World); keys win over it.
var stick_direction := Vector2.ZERO

var _model: BattleActor
var _autoplay := false
var _route_index := 0
## Set after a return through the portal: until the first route point is reached, a hero
## stuck on the way to it (a wall in between) skips to the next one.
var _skip_blocked_point := false
var _stuck_frames := 0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready() -> void:
	_autoplay = OS.get_cmdline_user_args().has("--autoplay")
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.6
	var shape := CollisionShape3D.new()
	shape.shape = capsule
	shape.position = Vector3(0, 0.8, 0)
	add_child(shape)
	_model = ACTOR_SCENE.instantiate()
	_model.look = BattleActor.Look.HERO
	add_child(_model)


## The hero's figure, for cutscenes (walking animation, turning, cheering).
func model() -> BattleActor:
	return _model


## Shows the weapon, shield and helmet worn on the model (Equipment ids, "" for none).
func set_equipment(weapon_id: String, shield_id: String, helmet_id := "") -> void:
	_model.set_equipment(weapon_id, shield_id, helmet_id)


## Puts the player at pos with the model turned to facing_yaw (0 faces -Z).
func place(pos: Vector3, facing_yaw: float) -> void:
	global_position = pos
	velocity = Vector3.ZERO
	_model.rotation.y = facing_yaw
	last_step_m = 0.0
	move_target = null
	_skip_blocked_point = false
	_route_index = _nearest_route_point(pos)


## Walks to point (only its X and Z count) until it arrives, gets stuck or a key is
## pressed.
func move_to(point: Vector3) -> void:
	move_target = Vector3(point.x, 0.0, point.z)
	_stuck_frames = 0


func _physics_process(delta: float) -> void:
	if scripted:
		last_step_m = 0.0
		return
	if not input_enabled:
		move_target = null
	var dir := _wanted_direction() if input_enabled else Vector3.ZERO
	velocity.x = dir.x * SPEED
	velocity.z = dir.z * SPEED
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= _gravity * delta
	var before := global_position
	move_and_slide()
	var moved := global_position - before
	moved.y = 0.0
	last_step_m = moved.length()
	if move_target != null and dir != Vector3.ZERO:
		_stuck_frames = _stuck_frames + 1 if last_step_m < SPEED * delta * 0.25 else 0
		if _stuck_frames > STUCK_FRAMES:
			move_target = null
	elif _autoplay and _skip_blocked_point and dir != Vector3.ZERO:
		# Placed back by the portal, the nearest route point can be behind a wall.
		_stuck_frames = _stuck_frames + 1 if last_step_m < SPEED * delta * 0.25 else 0
		if _stuck_frames > STUCK_FRAMES:
			_stuck_frames = 0
			_route_index = (_route_index + 1) % route.size()
	if dir != Vector3.ZERO:
		var target_yaw := atan2(-dir.x, -dir.z)  # the model faces -Z
		_model.rotation.y = lerp_angle(_model.rotation.y, target_yaw, minf(1.0, TURN_SPEED * delta))
	_model.set_walking(dir != Vector3.ZERO)


func _wanted_direction() -> Vector3:
	if _autoplay:
		return _route_direction()
	var keys := Input.get_vector(KeyMap.MOVE_LEFT, KeyMap.MOVE_RIGHT, KeyMap.MOVE_UP,
		KeyMap.MOVE_DOWN)
	if keys == Vector2.ZERO:
		keys = stick_direction
	if keys == Vector2.ZERO:
		return _target_direction()
	move_target = null
	# The camera sits south of the player looking north: screen up is -Z, right is +X.
	return Vector3(keys.x, 0.0, keys.y)


func _target_direction() -> Vector3:
	if move_target == null:
		return Vector3.ZERO
	var to_goal: Vector3 = move_target - global_position
	to_goal.y = 0.0
	if to_goal.length() < TARGET_REACHED:
		move_target = null
		return Vector3.ZERO
	return to_goal.normalized()


func _route_direction() -> Vector3:
	if route.is_empty():
		return Vector3.ZERO
	var to_goal := route[_route_index] - global_position
	to_goal.y = 0.0
	if to_goal.length() < ROUTE_REACHED:
		_route_index = (_route_index + 1) % route.size()
		_skip_blocked_point = false
		return Vector3.ZERO
	return to_goal.normalized()


## Arms the skip of a route point the hero can't reach (see _skip_blocked_point).
func arm_blocked_point_skip() -> void:
	_skip_blocked_point = true


## The route point to walk to first after being placed at pos: the nearest one.
func _nearest_route_point(pos: Vector3) -> int:
	var best := 0
	for i in route.size():
		if pos.distance_to(route[i]) < pos.distance_to(route[best]):
			best = i
	return best
