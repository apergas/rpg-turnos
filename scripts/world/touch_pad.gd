class_name TouchPad extends Control
## Turns fingers on the map into what the hero does. A short touch is a tap. A touch that
## slides past DEAD_ZONE becomes a stick that floats where the finger came down. A second
## finger cancels both and pinches. Draws the stick. Fed by World; touches on a window or
## button never get here.

signal tapped(screen: Vector2)
## The fingers' distance now over before: above 1 they are spreading.
signal pinched(ratio: float)

const DEAD_ZONE := 24.0
const RADIUS := 90.0
const RING_COLOR := Color(1, 1, 1, 0.35)
const KNOB_COLOR := Color(1, 1, 1, 0.6)
const KNOB_RADIUS := 34.0

## Where the stick points, screen axes, length 0..1.
var direction := Vector2.ZERO

var _touches := {}
var _origin := Vector2.ZERO
var _finger := Vector2.ZERO
var _sliding := false
## The first finger's touch can still become a tap.
var _can_tap := false
var _pinch_length := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Returns true when event was a touch this pad used.
func handle(event: InputEvent) -> bool:
	var touch := event as InputEventScreenTouch
	if touch != null:
		_on_touch(touch)
		return true
	var drag := event as InputEventScreenDrag
	if drag != null and _touches.has(drag.index):
		_on_drag(drag)
		return true
	return false


## Forgets every finger: a battle or a window took over.
func reset() -> void:
	_touches.clear()
	direction = Vector2.ZERO
	_sliding = false
	_can_tap = false
	_pinch_length = 0.0
	queue_redraw()


func _on_touch(touch: InputEventScreenTouch) -> void:
	if touch.canceled:
		reset()  # the system took the finger: no tap
		return
	if touch.pressed:
		if _touches.has(touch.index):
			reset()  # its release got lost on the way
		_touches[touch.index] = touch.position
		if _touches.size() == 1:
			_origin = touch.position
			_finger = touch.position
			_can_tap = true
		else:
			direction = Vector2.ZERO
			_sliding = false
			_can_tap = false
			_pinch_length = _touch_spread()
		queue_redraw()
		return
	_touches.erase(touch.index)
	if _touches.is_empty():
		var tap := _can_tap
		reset()
		if tap:
			tapped.emit(touch.position)
	else:
		_pinch_length = 0.0


func _on_drag(drag: InputEventScreenDrag) -> void:
	_touches[drag.index] = drag.position
	if _touches.size() >= 2:
		var spread := _touch_spread()
		if _pinch_length > 0.0 and spread > 0.0:
			pinched.emit(spread / _pinch_length)
		_pinch_length = spread
		return
	if not _can_tap and not _sliding:
		return  # what is left of a pinch: no stick until every finger lifts
	_finger = drag.position
	var offset := _finger - _origin
	if not _sliding and offset.length() < DEAD_ZONE:
		return
	_sliding = true
	_can_tap = false
	direction = offset.limit_length(RADIUS) / RADIUS
	queue_redraw()


func _touch_spread() -> float:
	var points: Array = _touches.values()
	return (points[0] as Vector2).distance_to(points[1]) if points.size() >= 2 else 0.0


func _draw() -> void:
	if not _sliding:
		return
	draw_arc(_origin, RADIUS, 0.0, TAU, 48, RING_COLOR, 4.0, true)
	draw_circle(_origin + direction * RADIUS, KNOB_RADIUS, KNOB_COLOR)
