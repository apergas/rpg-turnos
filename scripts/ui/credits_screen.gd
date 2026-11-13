class_name CreditsScreen extends Control
## The credits after the ending: on black, the sections given to run() roll up from
## the bottom of the screen (a heading in gold, its lines in white); then "Fin" (the v1) or
## "Continuará" (the v2: set end_text to TO_BE_CONTINUED before add_child) fades in
## and waits for Enter / Space / a click or tap. Holding Enter, Space or a click while
## they roll makes them go SPEED_UP times faster. With `-- --autoplay` every line is
## printed and "Fin" leaves by itself after AUTOPLAY_END seconds.

signal _advanced

## Pixels per second the credits roll up, and how much faster while held.
const SCROLL_SPEED := 70.0
const SPEED_UP := 5.0
const SECTION_GAP := UiTokens.SPACE_12
const END_FADE := 1.2
const AUTOPLAY_END := 2.0
## What fades in after the credits: "Fin" for the v1, TO_BE_CONTINUED for the v2 (set before
## add_child).
const TO_BE_CONTINUED := "Continuará"
var end_text := "Fin"

var _column: VBoxContainer
var _end: Label
var _rolling := false
var _waiting := false
var _autoplay := false


func _ready() -> void:
	_autoplay = OS.get_cmdline_user_args().has("--autoplay")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var black := ColorRect.new()
	black.color = UiTokens.color(&"surface-window-solid")
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(black)
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_column = VBoxContainer.new()
	_column.add_theme_constant_override("separation", UiTokens.SPACE_1)
	_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_column)
	_column.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_end = _label(end_text, &"display-l", &"text-display", UiTokens.OUTLINE_L, &"text-outline-warm")
	_end.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_end.modulate.a = 0.0
	add_child(_end)
	_end.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## Rolls sections ([heading, [lines...]] each) and returns once "Fin" is dismissed.
func run(sections: Array) -> void:
	for section: Array in sections:
		_column.add_child(_label(section[0], &"title-m", &"text-accent"))
		if _autoplay:
			print("Créditos: %s" % section[0])
		for line: String in section[1]:
			_column.add_child(_label(line, &"title-s", &"text-primary"))
			if _autoplay:
				print("  %s" % line)
		var gap := Control.new()
		gap.custom_minimum_size.y = SECTION_GAP
		_column.add_child(gap)
	await get_tree().process_frame
	_column.position.y = size.y
	_rolling = true
	while _column.position.y + _column.size.y > 0.0:
		await get_tree().process_frame
	_rolling = false
	var tween := create_tween()
	tween.tween_property(_end, "modulate:a", 1.0, END_FADE)
	await tween.finished
	if _autoplay:
		print(end_text)
		await get_tree().create_timer(AUTOPLAY_END).timeout
		return
	_waiting = true
	await _advanced
	_waiting = false


func _process(delta: float) -> void:
	if not _rolling:
		return
	var held := Input.is_action_pressed("ui_accept") \
		or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	_column.position.y -= SCROLL_SPEED * delta * (SPEED_UP if held else 1.0)


func _gui_input(event: InputEvent) -> void:
	var click: bool = event is InputEventMouseButton and event.pressed \
		and event.button_index == MOUSE_BUTTON_LEFT
	if _waiting and click:
		accept_event()
		_advanced.emit()


func _unhandled_input(event: InputEvent) -> void:
	if _waiting and event.is_action_pressed("ui_accept") and not event.is_echo():
		get_viewport().set_input_as_handled()
		_advanced.emit()


func _label(text: String, style: StringName, color: StringName, outline := 0,
		outline_color := &"text-outline") -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiTheme.style_label(label, style, color, outline, outline_color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
