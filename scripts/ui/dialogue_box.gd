class_name DialogueBox extends Control
## Dialogue window at the bottom of the world map, as wide as the longest line it will
## say (up to MAX_WIDTH, then lines wrap). say() shows one line at a time and
## returns once the last one is dismissed with Enter / Space or a click. With
## `-- --autoplay` the lines advance by themselves and are printed.

signal _advanced

const FONT_SIZE := 24
const SPEAKER_COLOR := Color(1.0, 0.85, 0.3)
const AUTOPLAY_DELAY := 0.8
const MAX_WIDTH := 1000.0
const BOTTOM := 24.0

var _autoplay := false
var _listening := false
var _speaker: Label
var _line: Label
var _audio: AudioDirector


func _ready() -> void:
	_autoplay = OS.get_cmdline_user_args().has("--autoplay")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := BattleHud.make_window()
	panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	panel.offset_left = 0
	panel.offset_right = 0
	panel.offset_top = -BOTTOM
	panel.offset_bottom = -BOTTOM
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	_speaker = _label(SPEAKER_COLOR)
	box.add_child(_speaker)
	_line = _label(Color.WHITE)
	box.add_child(_line)
	hide()


## Plays the dialogue sound when a dialogue opens. Without it the box is silent.
func set_audio(audio: AudioDirector) -> void:
	_audio = audio


## An empty speaker is the narrator: no name over the lines.
func say(speaker: String, lines: Array[String]) -> void:
	_speaker.text = speaker
	_speaker.visible = speaker != ""
	_fit_to(lines)
	show()
	if _audio:
		_audio.play_sfx(SfxLibrary.DIALOGUE)
	for text in lines:
		_line.text = text
		if _autoplay:
			print("%s: %s" % [speaker if speaker != "" else "Narración", text])
			await get_tree().create_timer(AUTOPLAY_DELAY).timeout
		else:
			# Skip a frame so the key press that opened or advanced the dialogue is not reused.
			await get_tree().process_frame
			_listening = true
			await _advanced
			_listening = false
	hide()


func _unhandled_input(event: InputEvent) -> void:
	if not _listening:
		return
	var accept := event.is_action_pressed("ui_accept") and not event.is_echo()
	var click: bool = event is InputEventMouseButton and event.pressed \
		and event.button_index == MOUSE_BUTTON_LEFT
	if accept or click:
		get_viewport().set_input_as_handled()
		_advanced.emit()


## The box keeps one width through the whole dialogue: that of its longest line.
func _fit_to(lines: Array[String]) -> void:
	var longest := ""
	var width := 0.0
	for text in lines:
		var line_width := BattleHud.text_width(_line, text)
		if line_width > width:
			longest = text
			width = line_width
	BattleHud.fit_label(_line, longest, MAX_WIDTH)
	_line.custom_minimum_size.x = minf(width, MAX_WIDTH)


func _label(color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", color)
	return label
