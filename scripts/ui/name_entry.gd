class_name NameEntry extends Control
## The hero's name, asked when a new game starts: a window with the name typed so far
## and an on-screen keyboard (a grid of letters for the mouse and touch, moved through
## with the arrow keys), plus typing straight from the keyboard. At most
## StoryState.MAX_NAME_LENGTH letters; left empty it is StoryState.DEFAULT_NAME. The first
## letter comes in capitals and the rest in small letters ("Aa" switches). Enter accepts,
## Backspace deletes, Esc goes back. Emits accepted(name) or cancelled.

signal accepted(hero_name: String)
signal cancelled

const FONT_SIZE := 26
const NAME_SIZE := 44
const HINT_COLOR := Color(0.7, 0.72, 0.8)
const KEY_SIZE := Vector2(58, 50)
const COLUMNS := 8
## Phone: wider and shorter, so the grid and its buttons fit a landscape screen.
const TOUCH_COLUMNS := 11
## The grid, in capitals (lower-cased when the case is switched).
const LETTERS := "ABCDEFGHIJKLMNÑOPQRSTUVWXYZÁÉÍÓÚ"
## --autoplay: seconds between two key presses of demo().
const DEMO_STEP := 0.15

var _audio: AudioDirector
## The name already typed when it opens (Volver from the difficulty); set before add_child.
var preset := ""
var _typed := ""
var _upper := true
var _name_label: Label
var _keys: Array[Button] = []
var _case_button: Button
var _accept_button: Button
var _quiet_focus := false
var _done := false


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
	box.add_theme_constant_override("separation", 10)
	window.add_child(box)
	box.add_child(_label("¿Cómo te llamas?", UiTokens.color(&"text-accent"), FONT_SIZE))
	_name_label = _label("", Color.WHITE, NAME_SIZE)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_name_label)
	var hint := "Toca las letras" if Device.is_touch() else "Escribe o toca las letras"
	box.add_child(_label("%s (máximo %d)." % [hint, StoryState.MAX_NAME_LENGTH],
		HINT_COLOR, 20))
	var grid := GridContainer.new()
	grid.columns = TOUCH_COLUMNS if Device.is_touch() else COLUMNS
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	box.add_child(grid)
	for letter in LETTERS:
		var key := _button(letter)
		key.theme_type_variation = UiTheme.KEY
		key.remove_theme_font_size_override("font_size")
		key.custom_minimum_size = KEY_SIZE
		key.pressed.connect(func() -> void: _add(key.text))
		grid.add_child(key)
		_keys.append(key)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	_case_button = _button("Aa")
	_case_button.pressed.connect(func() -> void: _set_upper(not _upper))
	row.add_child(_case_button)
	var erase := _button("Borrar")
	erase.pressed.connect(_erase)
	row.add_child(erase)
	var back := _button("Volver")
	back.pressed.connect(_cancel)
	row.add_child(back)
	_accept_button = _button("Aceptar")
	_accept_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_accept_button.pressed.connect(_accept)
	row.add_child(_accept_button)
	UiTheme.add_cursor(window)
	if preset != "":
		_typed = preset
	_refresh()
	_quiet_focus = true
	_keys[0].grab_focus()
	_quiet_focus = false


## Keys typed straight from the keyboard: letters, Backspace, Enter and Esc. The arrow
## keys and Space go on to the grid (focus and press).
func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if _done or key == null or not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_ENTER, KEY_KP_ENTER:
			_accept()
		KEY_BACKSPACE:
			_erase()
		KEY_ESCAPE:
			_cancel()
		_:
			var typed := String.chr(key.unicode) if key.unicode > 0 else ""
			if typed == "" or typed.to_upper() == typed.to_lower():
				return
			# Typed letters follow the grid's case: a capital first, then small ones.
			_add(typed.to_upper() if _upper else typed.to_lower())
	get_viewport().set_input_as_handled()


## --autoplay: types hero_name on the grid key by key (switching the case when needed)
## and accepts it.
func demo(hero_name: String) -> void:
	for letter in hero_name:
		var wanted_upper := letter == letter.to_upper()
		if wanted_upper != _upper:
			await _demo_press(_case_button)
		for key in _keys:
			if key.text == letter:
				await _demo_press(key)
				break
	await _demo_press(_accept_button)


func _demo_press(button: Button) -> void:
	button.grab_focus()
	await get_tree().create_timer(DEMO_STEP).timeout
	button.pressed.emit()


func _add(letter: String) -> void:
	if _done or _typed.length() >= StoryState.MAX_NAME_LENGTH:
		return
	_sfx(SfxLibrary.CURSOR)
	_typed += letter
	if _typed.length() == 1:
		_set_upper(false)
	_refresh()


func _erase() -> void:
	if _done or _typed == "":
		return
	_sfx(SfxLibrary.CANCEL)
	_typed = _typed.left(-1)
	if _typed == "":
		_set_upper(true)
	_refresh()


func _accept() -> void:
	if _done:
		return
	_done = true
	_sfx(SfxLibrary.ACCEPT)
	var hero_name := StoryState.clean_name(_typed)
	if OS.get_cmdline_user_args().has("--autoplay"):
		print("Nombre: %s" % hero_name)
	accepted.emit(hero_name)


func _cancel() -> void:
	if _done:
		return
	_done = true
	_sfx(SfxLibrary.CANCEL)
	cancelled.emit()


func _set_upper(upper: bool) -> void:
	_upper = upper
	for key in _keys:
		key.text = key.text.to_upper() if upper else key.text.to_lower()


## The name typed with a cursor on the free places, or the default name in grey.
func _refresh() -> void:
	if _typed == "":
		_name_label.text = StoryState.DEFAULT_NAME
		_name_label.modulate = Color(1, 1, 1, 0.45)
		return
	_name_label.modulate = Color.WHITE
	_name_label.text = _typed + "_".repeat(StoryState.MAX_NAME_LENGTH - _typed.length())


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	UiTheme.menu_row(button)
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	button.focus_entered.connect(func() -> void:
		if not _quiet_focus:
			_sfx(SfxLibrary.CURSOR))
	return button


func _label(text: String, color: Color, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _sfx(id: String) -> void:
	if _audio:
		_audio.play_sfx(id)
