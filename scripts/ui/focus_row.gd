class_name FocusRow extends HBoxContainer
## An option row (name, selector or slider) that paints the chosen-row background, UiTheme's
## selected_style(), under itself while something inside it has the focus (design system, M-63).
## MenuCursor draws the ▶ over it.


func _ready() -> void:
	get_viewport().gui_focus_changed.connect(func(_control: Control) -> void: queue_redraw())


func _draw() -> void:
	var holder := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	if holder != null and is_ancestor_of(holder):
		draw_style_box(UiTheme.selected_style(), Rect2(Vector2.ZERO, size))


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		queue_redraw()
