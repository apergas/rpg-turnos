class_name OptionsPanel extends VBoxContainer
## Options page shared by the title screen and the pause menu: music and effects volume
## (sliders, 0-100 % in steps of 10) and text speed (Lenta / Normal / Rápida). Changes
## apply at once; "Volver" (or back()) saves them with SaveStore and emits closed. Call
## setup() before adding it to the tree.

signal closed

const FONT_SIZE := 24
const VOLUME_STEP := 10.0

var _options: GameOptions
var _audio: AudioDirector
var _music_slider: HSlider
var _sfx_slider: HSlider
var _music_value: Label
var _sfx_value: Label
var _speed_buttons: Array[Button] = []
var _back_button: Button


func setup(options: GameOptions, audio: AudioDirector) -> void:
	_options = options
	_audio = audio


func _ready() -> void:
	add_theme_constant_override("separation", 12)
	add_child(_label("Opciones", Color(1.0, 0.85, 0.3)))
	_music_value = _label("", Color.WHITE)
	_music_slider = _volume_row("Música", _options.music_volume, _music_value)
	_sfx_value = _label("", Color.WHITE)
	_sfx_slider = _volume_row("Efectos", _options.sfx_volume, _sfx_value)
	_music_slider.value_changed.connect(_on_music_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	var speed_row := HBoxContainer.new()
	speed_row.add_theme_constant_override("separation", 8)
	add_child(speed_row)
	var speed_label := _label("Texto", Color.WHITE)
	speed_label.custom_minimum_size = Vector2(120, 0)
	speed_row.add_child(speed_label)
	var group := ButtonGroup.new()
	for i in GameOptions.SPEED_NAMES.size():
		var button := _button(GameOptions.SPEED_NAMES[i])
		button.toggle_mode = true
		button.button_group = group
		button.button_pressed = i == _options.text_speed
		button.pressed.connect(_on_speed_chosen.bind(i))
		speed_row.add_child(button)
		_speed_buttons.append(button)
	_back_button = _button("Volver")
	_back_button.pressed.connect(back)
	add_child(_back_button)
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


func _on_speed_chosen(speed: int) -> void:
	_options.text_speed = speed as GameOptions.TextSpeed
	if _audio:
		_audio.play_sfx(SfxLibrary.CURSOR)


func _apply() -> void:
	if _audio:
		_audio.set_volumes(_options.music_volume, _options.sfx_volume)
	_update_values()


func _update_values() -> void:
	_music_value.text = "%d %%" % roundi(_options.music_volume * 100.0)
	_sfx_value.text = "%d %%" % roundi(_options.sfx_volume * 100.0)


## A row "name [slider] value" and its slider (0..100).
func _volume_row(text: String, volume: float, value_label: Label) -> HSlider:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	add_child(row)
	var name_label := _label(text, Color.WHITE)
	name_label.custom_minimum_size = Vector2(120, 0)
	row.add_child(name_label)
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
