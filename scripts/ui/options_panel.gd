class_name OptionsPanel extends VBoxContainer
## Options page shared by the title screen and the pause menu: music and effects volume
## (sliders, 0-100 % in steps of 10), text speed, combat speed, graphics quality, camera
## shake, large text and, on desktop, fullscreen. Changes apply at once; "Volver" (or back())
## saves them with SaveStore and emits closed. The rows scroll when the screen is short.
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
var _main: VBoxContainer
var _rows: VBoxContainer
var _music_slider: HSlider
var _sfx_slider: HSlider
var _music_value: Label
var _sfx_value: Label
var _back_button: Button


func setup(options: GameOptions, audio: AudioDirector) -> void:
	_options = options
	_audio = audio


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
	_choice_row("Texto", GameOptions.SPEED_NAMES, _options.text_speed, func(i: int) -> void:
		_options.text_speed = i as GameOptions.TextSpeed)
	_choice_row("Combate", GameOptions.COMBAT_NAMES, _options.combat_speed, func(i: int) -> void:
		_options.combat_speed = i as GameOptions.CombatSpeed)
	_choice_row("Gráficos", GameOptions.QUALITY_NAMES, _options.quality, func(i: int) -> void:
		_options.quality = i as GameOptions.Quality
		_apply_display())
	_choice_row("Temblor", YES_NO, 0 if _options.camera_shake else 1, func(i: int) -> void:
		_options.camera_shake = i == 0)
	_choice_row("Textos grandes", YES_NO, 0 if _options.large_text else 1, func(i: int) -> void:
		_options.large_text = i == 0
		_apply_display())
	if not OS.has_feature("web"):
		_choice_row("Pantalla completa", YES_NO, 0 if _options.fullscreen else 1,
			func(i: int) -> void:
				_options.fullscreen = i == 0
				_apply_display())
	_back_button = _button("Volver")
	_back_button.pressed.connect(back)
	_main.add_child(_back_button)
	_update_values()


func focus_first() -> void:
	_music_slider.grab_focus()


## Saves the options and closes the page.
func back() -> void:
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
## each press.
func _choice_row(title: String, names: Array, current: int, chosen: Callable) -> void:
	var row := _named_row(title)
	var group := ButtonGroup.new()
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
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	return button


func _label(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", color)
	return label
