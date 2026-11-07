class_name OptionsPanel extends VBoxContainer
## Options page shared by the title screen and the pause menu: music and effects volume
## (sliders, 0-100 % in steps of 10), text speed, combat speed, graphics quality, camera
## shake, large text, fullscreen (on desktop through the options; in a browser, except on iPhone
## and iPad, it sets the window's mode directly) and Teclas (KeysPanel). Changes apply at once;
## "Volver" (or back()) saves them with SaveStore and emits closed. The rows scroll when the
## screen is short. From the pause menu (with state) it also changes the game's difficulty.
## Call setup() before adding it to the tree.

signal closed

const FONT_SIZE := 24
const VOLUME_STEP := 10.0
const NAME_WIDTH := 220.0
## What the title, Volver and the margins leave for the rows.
const ROWS_RESERVED := 150.0
const YES_NO := ["Sí", "No"]

var _options: GameOptions
var _audio: AudioDirector
var _state: GameState
## On the web, the Sí / No of the fullscreen row (empty elsewhere): the browser can leave
## fullscreen on its own, so the row is set again each time the page shows.
var _web_fullscreen: Array[Button] = []
var _main: VBoxContainer
var _rows: VBoxContainer
var _music_slider: HSlider
var _sfx_slider: HSlider
var _music_value: Label
var _sfx_value: Label
var _back_button: Button
var _keys_button: Button
var _keys_panel: KeysPanel


## state: the game under way, whose difficulty can change here (null on the title screen).
func setup(options: GameOptions, audio: AudioDirector, state: GameState = null) -> void:
	_options = options
	_audio = audio
	_state = state


func _ready() -> void:
	_main = VBoxContainer.new()
	_main.add_theme_constant_override("separation", 8)
	add_child(_main)
	_main.add_child(_label("Opciones", UiStyle.TITLE_COLOR))
	var scroll := ScrollBox.new(ROWS_RESERVED)
	_main.add_child(scroll)
	_rows = scroll.content
	_rows.add_theme_constant_override("separation", 6)
	_music_value = _label("", Color.WHITE)
	_music_slider = _volume_row("Música", _options.music_volume, _music_value)
	_sfx_value = _label("", Color.WHITE)
	_sfx_slider = _volume_row("Efectos", _options.sfx_volume, _sfx_value)
	_music_slider.value_changed.connect(_on_music_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	_choice_row("Velocidad del texto", GameOptions.SPEED_NAMES, _options.text_speed, func(i: int) -> void:
		_options.text_speed = i as GameOptions.TextSpeed)
	_choice_row("Velocidad de combate", GameOptions.COMBAT_NAMES, _options.combat_speed, func(i: int) -> void:
		_options.combat_speed = i as GameOptions.CombatSpeed)
	_choice_row("Gráficos", GameOptions.QUALITY_NAMES, _options.quality, func(i: int) -> void:
		_options.quality = i as GameOptions.Quality
		_apply_display())
	_choice_row("Temblor de cámara", YES_NO, 0 if _options.camera_shake else 1, func(i: int) -> void:
		_options.camera_shake = i == 0)
	_choice_row("Textos grandes", YES_NO, 0 if _options.large_text else 1, func(i: int) -> void:
		_options.large_text = i == 0
		_apply_display())
	if not OS.has_feature("web"):
		_choice_row("Pantalla completa", YES_NO, 0 if _options.fullscreen else 1,
			func(i: int) -> void:
				_options.fullscreen = i == 0
				_apply_display())
	elif not (Device.is_touch() and Device.is_ios()):
		# The browser only allows fullscreen from a press, so it is set here, not by apply().
		_web_fullscreen = _choice_row("Pantalla completa", YES_NO,
			0 if get_window().mode == Window.MODE_FULLSCREEN else 1, func(i: int) -> void:
				get_window().mode = Window.MODE_FULLSCREEN if i == 0 else Window.MODE_WINDOWED)
	if _state != null:
		var names: Array = Difficulty.IDS.map(func(id: String) -> String:
			return Difficulty.NAMES[id])
		_choice_row("Dificultad", names, Difficulty.IDS.find(_state.difficulty),
			func(i: int) -> void: _state.difficulty = Difficulty.IDS[i])
	if not Device.is_touch():
		_keys_button = _button("Teclas")
		_keys_button.pressed.connect(_open_keys)
		_rows.add_child(_keys_button)
	_back_button = _button("Volver")
	_back_button.pressed.connect(back)
	_main.add_child(_back_button)
	_keys_panel = KeysPanel.new()
	_keys_panel.setup(_options, _audio)
	_keys_panel.closed.connect(_close_keys)
	_keys_panel.hide()
	add_child(_keys_panel)
	_update_values()
	visibility_changed.connect(_sync_web_fullscreen)


func focus_first() -> void:
	_music_slider.grab_focus()


## Saves the options and closes the page (from Teclas: back to the options first).
func back() -> void:
	if _keys_panel.visible and _keys_panel.is_waiting():
		return
	if _keys_panel.visible:
		_close_keys()
		return
	SaveStore.save_options(_options)
	if _audio:
		_audio.play_sfx(SfxLibrary.CANCEL)
	closed.emit()


func _on_music_changed(value: float) -> void:
	_options.music_volume = value / 100.0
	_apply()


func _on_sfx_changed(value: float) -> void:
	_options.sfx_volume = value / 100.0
	_apply()
	if _audio:
		_audio.play_sfx(SfxLibrary.CURSOR)


func _apply() -> void:
	if _audio:
		_audio.set_volumes(_options.music_volume, _options.sfx_volume)
	_update_values()


func _open_keys() -> void:
	_main.hide()
	_keys_panel.show()
	_keys_panel.focus_first()
	if _audio:
		_audio.play_sfx(SfxLibrary.ACCEPT)


func _close_keys() -> void:
	_keys_panel.hide()
	_main.show()
	if _keys_button:
		_keys_button.grab_focus()
	if _audio:
		_audio.play_sfx(SfxLibrary.CANCEL)


func _apply_display() -> void:
	DisplaySettings.apply(get_window(), _options)


func _update_values() -> void:
	_music_value.text = "%d %%" % roundi(_options.music_volume * 100.0)
	_sfx_value.text = "%d %%" % roundi(_options.sfx_volume * 100.0)


## A row "name [slider] value" and its slider (0..100).
func _volume_row(text: String, volume: float, value_label: Label) -> HSlider:
	var row := _named_row(text)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = VOLUME_STEP
	slider.value = roundf(volume * 100.0 / VOLUME_STEP) * VOLUME_STEP
	slider.custom_minimum_size = Vector2(260, 32)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(slider)
	value_label.custom_minimum_size = Vector2(80, 0)
	row.add_child(value_label)
	return slider


## A row "name [choice] [choice]...": one choice pressed at a time; chosen.call(index) at
## each press. Returns the choices' buttons.
func _choice_row(title: String, names: Array, current: int, chosen: Callable) -> Array[Button]:
	var row := _named_row(title)
	var group := ButtonGroup.new()
	var buttons: Array[Button] = []
	for i in names.size():
		var button := _button(names[i])
		button.toggle_mode = true
		button.button_group = group
		button.button_pressed = i == current
		button.pressed.connect(func() -> void:
			chosen.call(i)
			if _audio:
				_audio.play_sfx(SfxLibrary.CURSOR))
		row.add_child(button)
		buttons.append(button)
	return buttons


## Sí or No as the window is now (set_pressed_no_signal doesn't unpress the group's other
## button, so both are set).
func _sync_web_fullscreen() -> void:
	if _web_fullscreen.is_empty() or not is_visible_in_tree():
		return
	var full := get_window().mode == Window.MODE_FULLSCREEN
	_web_fullscreen[0].set_pressed_no_signal(full)
	_web_fullscreen[1].set_pressed_no_signal(not full)


func _named_row(title: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_rows.add_child(row)
	var name_label := _label(title, Color.WHITE)
	name_label.custom_minimum_size = Vector2(NAME_WIDTH, 0)
	row.add_child(name_label)
	return row


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	UiStyle.fit_finger(button)
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	return button


func _label(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", color)
	return label
