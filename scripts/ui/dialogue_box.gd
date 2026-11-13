class_name DialogueBox extends Control
## Dialogue window at the bottom of the world map, as wide as the longest line it will
## say (up to MAX_WIDTH, then lines wrap). say() shows one line at a time and
## returns once the last one is dismissed with Enter / Space or a click. With
## `-- --autoplay` the lines advance by themselves and are printed.

signal _advanced

const AUTOPLAY_DELAY := 0.8
## Seconds the continue mark is shown and hidden.
const MORE_BLINK := 0.5
const MAX_WIDTH := float(UiTokens.WINDOW_W_MAX)
const BOTTOM := float(UiTokens.SPACE_6)
## Screen margins and window margins: what a line can't use of the screen's width.
const SIDE_ROOM := float(2 * UiTokens.SPACE_6 + 2 * UiTokens.SPACE_4)

var _autoplay := false
var _listening := false
var _speaker: Label
var _line: Label
var _audio: AudioDirector
## The ▼ that says "press to go on": drawn, in its own row at the right, blinking while a line waits.
var _more: Control
var _blinking := false
## When the mark started blinking, so every new line begins with it visible.
var _blink_start := 0


func _ready() -> void:
	_autoplay = OS.get_cmdline_user_args().has("--autoplay")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)
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
	_speaker = Label.new()
	_speaker.theme_type_variation = UiTheme.TITLE
	box.add_child(_speaker)
	_line = Label.new()
	box.add_child(_line)
	_more = Control.new()
	_more.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_more.custom_minimum_size = Vector2(UiTokens.CURSOR_SIZE, UiTokens.CURSOR_SIZE)
	_more.size_flags_horizontal = Control.SIZE_SHRINK_END
	_more.draw.connect(_draw_more)
	_more.modulate.a = 0.0
	box.add_child(_more)
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
			_blink_start = Time.get_ticks_msec()
			_more.modulate.a = 1.0
			_blinking = true
			set_process(true)
			await _advanced
			_listening = false
			_blinking = false
			set_process(false)
			_more.modulate.a = 0.0
	hide()


## The mark blinks every MORE_BLINK seconds while a line waits.
func _process(_delta: float) -> void:
	if _blinking:
		_more.modulate.a = 1.0 if int((Time.get_ticks_msec() - _blink_start) / (MORE_BLINK * 1000.0)) % 2 == 0 else 0.0


func _draw_more() -> void:
	var s := float(UiTokens.CURSOR_SIZE)
	_more.draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(s, 0), Vector2(s / 2.0, s * 0.8)]),
			UiTokens.color(&"border-focus"))


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
	var room := minf(MAX_WIDTH, get_viewport_rect().size.x - SIDE_ROOM)
	BattleHud.fit_label(_line, longest, room)
	_line.custom_minimum_size.x = minf(width, room)
