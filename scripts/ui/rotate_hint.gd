class_name RotateHint extends Control
## On a phone held upright, covers everything with a request to turn it: the windows and the
## battle are only laid out for landscape. Takes every touch while it shows.

var _label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var back := ColorRect.new()
	back.color = UiTokens.color(&"surface-window-solid")
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(back)
	var label := Label.new()
	label.text = "Gira la pantalla"
	UiTheme.style_label(label, &"title-l", &"text-primary")
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(label)
	_label = label
	get_viewport().size_changed.connect(_fit)
	_fit()


func _fit() -> void:
	var window := get_window().size
	visible = window.y > window.x
	if _label == null:
		return
	# Upright, the stretch shrinks everything (about 0.35 of a landscape screen): the text is
	# made big enough to read as body text (UiTokens.TYPE_BODY_SIZE) on the screen itself.
	var factor := maxf(0.01, get_window().get_final_transform().get_scale().x)
	var font_size := maxi(UiTokens.type_size(&"title-l"), ceili(UiTokens.TYPE_BODY_SIZE / factor))
	_label.add_theme_font_size_override(&"font_size", font_size)
