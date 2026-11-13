class_name DifficultyWindow extends Control
## Asked after the hero's name when a new game starts: Normal or Fácil, each with what it
## means, and Volver. It can be changed later from Opciones in the pause menu. Emits
## chosen(id) or cancelled. Keyboard, mouse and touch.

signal chosen(id: String)
signal cancelled

const FONT_SIZE := 26

var _audio: AudioDirector


## Cursor and accept sounds; without it the window is silent.
func setup(audio: AudioDirector) -> void:
	_audio = audio


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var window := BattleHud.make_window()
	center.add_child(window)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	window.add_child(box)
	var title := _label("¿Qué dificultad prefieres?", UiTokens.color(&"text-accent"), FONT_SIZE)
	box.add_child(title)
	var first: Button = null
	for id in Difficulty.IDS:
		var button := _button(Difficulty.NAMES[id])
		button.pressed.connect(_choose.bind(id))
		box.add_child(button)
		box.add_child(_label(Difficulty.TEXTS[id], UiTokens.color(&"text-secondary"), UiTokens.TYPE_CAPTION_SIZE))
		if first == null:
			first = button
	var back := _button("Volver")
	back.pressed.connect(_cancel)
	box.add_child(back)
	first.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		_cancel()


func _choose(id: String) -> void:
	if _audio:
		_audio.play_sfx(SfxLibrary.ACCEPT)
	chosen.emit(id)


func _cancel() -> void:
	if _audio:
		_audio.play_sfx(SfxLibrary.CANCEL)
	cancelled.emit()


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.flat = true
	UiStyle.fit_finger(button)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	return button


func _label(text: String, color: Color, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label
