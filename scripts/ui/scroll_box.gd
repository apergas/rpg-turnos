class_name ScrollBox extends ScrollContainer
## A list that hugs its content and scrolls once it is taller than the screen leaves room
## for. Fill `content`. The cursor keys scroll it when no button takes them, and a focused
## row is always brought into view. reserved_height is what the rest of the window and the
## screen margins take.

const SCROLL_STEP := 40
## Width kept for the scroll bar while it shows.
const BAR_ROOM := 14.0
## A finger that shakes this little on a row is still pressing it, not dragging the list.
const TOUCH_DEADZONE := 14

var content := VBoxContainer.new()

var _reserved := 0.0


func _init(reserved_height: float) -> void:
	_reserved = reserved_height
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	follow_focus = true
	if Device.is_touch():
		scroll_deadzone = TOUCH_DEADZONE
	add_child(content)
	content.minimum_size_changed.connect(_fit)
	visibility_changed.connect(_on_visibility_changed)


func _ready() -> void:
	get_viewport().size_changed.connect(_fit)
	_fit()


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	var step := 0
	if event.is_action_pressed("ui_up", true):
		step = -SCROLL_STEP
	elif event.is_action_pressed("ui_down", true):
		step = SCROLL_STEP
	if step != 0 and get_v_scroll_bar().visible:
		scroll_vertical += step
		get_viewport().set_input_as_handled()


func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		scroll_vertical = 0
		_fit()


func _fit() -> void:
	if not is_inside_tree():
		return
	var wanted := content.get_combined_minimum_size()
	var room := get_viewport_rect().size.y - _reserved
	var scrolls := wanted.y > room
	custom_minimum_size = Vector2(wanted.x + (BAR_ROOM if scrolls else 0.0), minf(wanted.y, room))
