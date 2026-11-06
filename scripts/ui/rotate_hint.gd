class_name RotateHint extends Control
## On a phone held upright, covers everything with a request to turn it: the windows and the
## battle are only laid out for landscape. Takes every touch while it shows.

const FONT_SIZE := 40


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var back := ColorRect.new()
	back.color = Color(0.05, 0.05, 0.1)
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(back)
	var label := Label.new()
	label.text = "Gira el móvil"
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(label)
	get_viewport().size_changed.connect(_fit)
	_fit()


func _fit() -> void:
	var window := get_window().size
	visible = window.y > window.x
