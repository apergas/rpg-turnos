class_name FollowCamera extends Camera3D
## Top-down camera for the world map: high above the target and south of it, looking
## north at a fixed angle, following it smoothly. The mouse wheel zooms between
## MIN_DISTANCE and MAX_DISTANCE. It never turns.

## Degrees below the horizon the camera looks down.
const PITCH_DEG := 55.0
## Distance from the point it looks at, in meters.
const DISTANCE := 14.0
const MIN_DISTANCE := 9.0
const MAX_DISTANCE := 20.0
const ZOOM_STEP := 1.5
## Fraction of the remaining zoom covered per second (exponential smoothing).
const ZOOM_RATE := 8.0
## Fraction of the remaining distance covered per second (exponential smoothing).
const FOLLOW_RATE := 6.0
const LOOK_HEIGHT := 1.0
const FOV := 45.0

var target: Node3D
## Current distance; moves toward the zoom goal.
var distance := DISTANCE

var _zoom_goal := DISTANCE
## The zoom chosen by the player while a cutscene shows a point (-1: none).
var _saved_zoom := -1.0


func _ready() -> void:
	fov = FOV


func _unhandled_input(event: InputEvent) -> void:
	var wheel := event as InputEventMouseButton
	if wheel == null or not wheel.pressed:
		return
	if wheel.button_index == MOUSE_BUTTON_WHEEL_UP:
		_zoom_goal -= ZOOM_STEP
	elif wheel.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_zoom_goal += ZOOM_STEP
	else:
		return
	_zoom_goal = clampf(_zoom_goal, MIN_DISTANCE, MAX_DISTANCE)


## Two fingers: spreading them brings the camera closer.
func zoom_by(ratio: float) -> void:
	if ratio > 0.0:
		_zoom_goal = clampf(_zoom_goal / ratio, MIN_DISTANCE, MAX_DISTANCE)


# Same tick as the player's movement, so the follow does not stutter.
func _physics_process(delta: float) -> void:
	if target == null:
		return
	distance = lerpf(distance, _zoom_goal, minf(1.0, ZOOM_RATE * delta))
	global_position = global_position.lerp(_goal_position(), minf(1.0, FOLLOW_RATE * delta))
	look_at(_focus(), Vector3.UP)


## Cutscenes: glides to look at spot from at_distance metres (any distance), keeping the
## player's zoom for follow().
func show_point(spot: Node3D, at_distance: float) -> void:
	if _saved_zoom < 0.0:
		_saved_zoom = _zoom_goal
	target = spot
	_zoom_goal = at_distance


## Follows new_target again with the player's zoom.
func follow(new_target: Node3D) -> void:
	target = new_target
	if _saved_zoom >= 0.0:
		_zoom_goal = _saved_zoom
		_saved_zoom = -1.0


## Jumps to the follow position and zoom without smoothing (start and respawn).
func snap() -> void:
	distance = _zoom_goal
	global_position = _goal_position()
	look_at(_focus(), Vector3.UP)


func _focus() -> Vector3:
	return target.global_position + Vector3.UP * LOOK_HEIGHT


func _goal_position() -> Vector3:
	var pitch := deg_to_rad(PITCH_DEG)
	return _focus() + Vector3(0.0, sin(pitch), cos(pitch)) * distance
