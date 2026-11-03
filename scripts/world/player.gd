class_name Player extends CharacterBody3D
## Hero on the world map. Moves with WASD / arrows in screen axes (the top-down camera
## never turns: up is north, -Z), turns smoothly toward where it walks and bobs while
## moving. Its model is a BattleActor.
## With `-- --autoplay` it walks AUTOPLAY_ROUTE in a loop instead of reading keys.

const ACTOR_SCENE := preload("res://scenes/battle/battle_actor.tscn")
const SPEED := 5.0
## How fast the model turns toward the walking direction (radians per second, roughly).
const TURN_SPEED := 10.0
const BOB_HEIGHT := 0.08
const BOB_TIME := 0.18
## Points walked in a loop by --autoplay: mostly grass, clear of rocks, and through the
## village, next to the old woman and to where the Rey Slime appears.
const AUTOPLAY_ROUTE: Array[Vector3] = [
	Vector3(8, 0, 18),
	Vector3(16, 0, 6),
	Vector3(10, 0, -6),
	Vector3(1, 0, -14),
	Vector3(-1.5, 0, -18),
	Vector3(0, 0, -26.5),
	Vector3(2, 0, -14),
	Vector3(-6, 0, -4),
	Vector3(-14, 0, 8),
	Vector3(-6, 0, 18),
]
const ROUTE_REACHED := 0.6

var input_enabled := true
## Horizontal meters moved during the last physics frame.
var last_step_m := 0.0

var _model: BattleActor
var _autoplay := false
var _route_index := 0
var _bob_tween: Tween
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


## Puts the player at pos with the model turned to facing_yaw (0 faces -Z).
func place(pos: Vector3, facing_yaw: float) -> void:
	global_position = pos
	velocity = Vector3.ZERO
	_model.rotation.y = facing_yaw
	last_step_m = 0.0


func _physics_process(delta: float) -> void:
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
	if dir != Vector3.ZERO:
		var target_yaw := atan2(-dir.x, -dir.z)  # the model faces -Z
		_model.rotation.y = lerp_angle(_model.rotation.y, target_yaw, minf(1.0, TURN_SPEED * delta))
	_set_bobbing(dir != Vector3.ZERO)


func _wanted_direction() -> Vector3:
	if _autoplay:
		return _route_direction()
	var keys := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		keys.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		keys.x += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		keys.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		keys.y += 1.0
	if keys == Vector2.ZERO:
		return Vector3.ZERO
	keys = keys.normalized()
	# The camera sits south of the player looking north: screen up is -Z, right is +X.
	return Vector3(keys.x, 0.0, keys.y)


func _route_direction() -> Vector3:
	var to_goal := AUTOPLAY_ROUTE[_route_index] - global_position
	to_goal.y = 0.0
	if to_goal.length() < ROUTE_REACHED:
		_route_index = (_route_index + 1) % AUTOPLAY_ROUTE.size()
		return Vector3.ZERO
	return to_goal.normalized()


func _set_bobbing(on: bool) -> void:
	if on == (_bob_tween != null):
		return
	if _bob_tween:
		_bob_tween.kill()
		_bob_tween = null
		_model.position.y = 0.0
		return
	_bob_tween = create_tween().set_loops()
	_bob_tween.tween_property(_model, "position:y", BOB_HEIGHT, BOB_TIME) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_bob_tween.tween_property(_model, "position:y", 0.0, BOB_TIME) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
