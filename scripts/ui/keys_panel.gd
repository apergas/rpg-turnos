class_name KeysPanel extends VBoxContainer
## The Teclas page of the options: one row per action with its keys. Pressing a row waits
## for the new key (a click or Esc cancels), which replaces the first key of that action; a key that
## can't change hands says why. Restablecer goes back to the project's keys. The rules are
## KeyMap's. Call setup() before adding it to the tree.

signal closed

const FONT_SIZE := 24
const NAME_WIDTH := 160.0
const KEYS_WIDTH := 400.0
const WAITING := "Pulsa una tecla..."

var _options: GameOptions
var _audio: AudioDirector
var _buttons := {}
var _message: Label
## The action waiting for its new key ("" for none).
var _waiting := ""
var _swallow_release := false


func setup(options: GameOptions, audio: AudioDirector) -> void:
	_options = options
	_audio = audio


func _ready() -> void:
	add_theme_constant_override("separation", 6)
	add_child(_label("Teclas", UiTokens.color(&"text-accent")))
	for action in KeyMap.ACTIONS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		add_child(row)
		var name_label := _label(KeyMap.NAMES[action], Color.WHITE)
		name_label.custom_minimum_size.x = NAME_WIDTH
		row.add_child(name_label)
		var button := _button("")
		button.custom_minimum_size.x = KEYS_WIDTH
		button.pressed.connect(_listen.bind(action))
		row.add_child(button)
		_buttons[action] = button
	_message = _label("", Color.WHITE)
	_message.hide()
	add_child(_message)
	var reset := _button("Restablecer")
	reset.pressed.connect(_reset)
	add_child(reset)
	var back := _button("Volver")
	back.pressed.connect(func() -> void: closed.emit())
	add_child(back)
	_refresh()


func focus_first() -> void:
	(_buttons[KeyMap.ACTIONS[0]] as Button).grab_focus()


## Before the buttons and the menus see it, the next key press or click belongs to the row.
func _input(event: InputEvent) -> void:
	if _swallow_release and event is InputEventMouseButton and not event.pressed:
		# The release of the click that cancelled the wait must not reach a backdrop and close the page.
		_swallow_release = false
		get_viewport().set_input_as_handled()
		return
	if _waiting == "":
		return
	var click: bool = event is InputEventMouseButton and event.pressed
	_swallow_release = click
	var key := event as InputEventKey
	if not click and (key == null or not key.pressed or key.echo):
		return
	get_viewport().set_input_as_handled()
	var action := _waiting
	_waiting = ""
	if click or key.physical_keycode in [KEY_NONE, KEY_ESCAPE]:
		_refresh()
		return
	_say(KeyMap.assign(_options.keys, action, int(key.physical_keycode)))
	_refresh()
	if _audio:
		_audio.play_sfx(SfxLibrary.ACCEPT)


## Whether a row is waiting for its key, when nothing else may close the page.
func is_waiting() -> bool:
	return _waiting != ""


func _listen(action: String) -> void:
	_waiting = action
	_say("")
	(_buttons[action] as Button).text = WAITING
	if _audio:
		_audio.play_sfx(SfxLibrary.CURSOR)


func _reset() -> void:
	_options.keys.clear()
	KeyMap.apply(_options.keys)
	_say("")
	_refresh()
	if _audio:
		_audio.play_sfx(SfxLibrary.ACCEPT)


func _refresh() -> void:
	for action: String in _buttons:
		(_buttons[action] as Button).text = KeyMap.keys_text(action)


func _say(text: String) -> void:
	_message.text = text
	_message.visible = text != ""


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	UiTheme.menu_row(button)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	return button


func _label(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", color)
	return label
