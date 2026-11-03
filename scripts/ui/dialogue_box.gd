class_name DialogueBox extends Control
## Dialogue window at the bottom of the world map. say() shows one line at a time and
## returns once the last one is dismissed with Enter / Space or a click. With
## `-- --autoplay` the lines advance by themselves and are printed.

signal _advanced

const FONT_SIZE := 24
const SPEAKER_COLOR := Color(1.0, 0.85, 0.3)
const AUTOPLAY_DELAY := 0.8

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
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 40
	panel.offset_right = -40
	panel.offset_top = -170
	panel.offset_bottom = -24
	add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	_speaker = _label(SPEAKER_COLOR)
	box.add_child(_speaker)
	_line = _label(Color.WHITE)
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_line)
	hide()


## Plays the dialogue sound when a dialogue opens. Without it the box is silent.
func set_audio(audio: AudioDirector) -> void:
	_audio = audio


func say(speaker: String, lines: Array[String]) -> void:
	_speaker.text = speaker
	show()
	if _audio:
		_audio.play_sfx(SfxLibrary.DIALOGUE)
	for text in lines:
		_line.text = text
		if _autoplay:
			print("%s: %s" % [speaker, text])
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


func _label(color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", color)
	return label
