class_name FollowCamera extends Camera3D
## Third-person camera behind and above a target. Follows it smoothly; Q / E turn it
## around the target. It never turns by itself when the target turns.

const DISTANCE := 6.0
const HEIGHT := 3.5
const LOOK_HEIGHT := 1.0
## Fraction of the remaining distance covered per second (exponential smoothing).
const FOLLOW_RATE := 6.0
## Radians per second while Q or E is held (about 120 degrees).
const TURN_RATE := 2.1
const FOV := 60.0

var target: Node3D
## Angle around the target; 0 puts the camera on the +Z side, looking toward -Z.
var yaw := 0.0


func _ready() -> void:
	fov = FOV


# Same tick as the player's movement, so the follow does not stutter.
func _physics_process(delta: float) -> void:
	if target == null:
		return
	var turn := 0.0
	if Input.is_physical_key_pressed(KEY_Q):
		turn -= 1.0
	if Input.is_physical_key_pressed(KEY_E):
		turn += 1.0
	yaw += turn * TURN_RATE * delta
	global_position = global_position.lerp(_goal_position(), minf(1.0, FOLLOW_RATE * delta))
	look_at(target.global_position + Vector3.UP * LOOK_HEIGHT, Vector3.UP)


## Jumps to the follow position without smoothing (start and respawn).
func snap() -> void:
	global_position = _goal_position()
	look_at(target.global_position + Vector3.UP * LOOK_HEIGHT, Vector3.UP)


func _goal_position() -> Vector3:
	var offset := Vector3(sin(yaw), 0.0, cos(yaw)) * DISTANCE
	return target.global_position + offset + Vector3.UP * HEIGHT
