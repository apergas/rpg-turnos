class_name TitleScreen extends Node
## Main scene. Shows the game's name over the meadow seen from a slowly drifting
## top-down camera, with "Nueva partida", "Continuar" (disabled without a save) and
## "Opciones" (keyboard, mouse and touch). Owns the only AudioDirector and the options,
## and creates a Game for the new or loaded session (new_game / continue_game); a new
## game first asks the hero's name (NameEntry, over the meadow). When the Game emits
## quit_to_title it frees it and shows the title again. A finished save shows
## "Continuar (terminada)".
## With `-- --autoplay` the name entry types AUTOPLAY_NAME by itself and the new game
## starts at once, without the menu. With `--autoplay-save` too, going back to the title
## loads the save straight away.

signal new_game
signal continue_game

const GAME_SCENE := preload("res://scenes/game/game.tscn")
## The name the autoplay types (an accent, to try the grid's last row).
const AUTOPLAY_NAME := "Rocío"
const TITLE_TEXT := "Villaclaro"
const TITLE_SIZE := 96
const SUBTITLE_TEXT := "La Niebla del Norte"
const SUBTITLE_SIZE := 36
const VERSION_SIZE := 18
const FONT_SIZE := 28
const FADE_TIME := 0.4
## Where the menu's room starts under the title.
const MENU_TOP := 160
## Drifting camera: looks down PITCH_DEG from DISTANCE m at a point that wanders over
## the field at DRIFT_SPEED (radians per second of its slow loop).
const PITCH_DEG := 55.0
const DISTANCE := 20.0
const DRIFT_SPEED := 0.05
const DRIFT_RADIUS := Vector2(10.0, 14.0)
const DRIFT_CENTER := Vector3(0, 1, 0)

var _audio: AudioDirector
var _options: GameOptions
var _backdrop: Node3D
var _camera: Camera3D
var _ui: CanvasLayer
var _menu_window: PanelContainer
var _continue_button: Button
var _options_button: Button
var _options_window: PanelContainer
var _options_panel: OptionsPanel
var _name_entry: NameEntry
var _difficulty_window: DifficultyWindow
var _title_label: Label
var _menu_center: CenterContainer
var _fade: ColorRect
var _game: Game
var _drift := 0.0
var _starting := false
var _autoplay := false
var _autoplay_save := false
var _quiet_focus := false


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_autoplay = args.has("--autoplay")
	_autoplay_save = _autoplay and args.has("--autoplay-save")
	_options = SaveStore.load_options()
	DisplaySettings.apply(get_window(), _options)
	KeyMap.apply(_options.keys)
	_audio = AudioDirector.new()
	add_child(_audio)
	_audio.set_volumes(_options.music_volume, _options.sfx_volume)
	_build_fade()
	new_game.connect(_open_name_entry)
	continue_game.connect(func() -> void: _start_game(_load_save()))
	_open_title()
	if _autoplay:
		_open_name_entry()


func _process(delta: float) -> void:
	if _camera == null:
		return
	_drift += delta * DRIFT_SPEED
	var focus := DRIFT_CENTER + Vector3(sin(_drift) * DRIFT_RADIUS.x, 0.0,
		cos(_drift * 0.7) * DRIFT_RADIUS.y)
	var pitch := deg_to_rad(PITCH_DEG)
	_camera.global_position = focus + Vector3(0.0, sin(pitch), cos(pitch)) * DISTANCE
	_camera.look_at(focus, Vector3.UP)


func _unhandled_input(event: InputEvent) -> void:
	if _options_window and _options_window.visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_options_panel.back()


## Builds the meadow, the camera and the menu, and plays the title music.
func _open_title() -> void:
	_starting = false
	_backdrop = Node3D.new()
	add_child(_backdrop)
	WorldStage.build(_backdrop, ZoneData.by_id("pradera"))
	_camera = Camera3D.new()
	_camera.fov = 45.0
	_backdrop.add_child(_camera)
	_camera.current = true
	_process(0.0)
	_build_menu()
	_audio.play_music(MusicLibrary.TITLE)


## Taken out of the tree at once, so its sky and sun never overlap the map's.
func _close_title() -> void:
	remove_child(_backdrop)
	_backdrop.queue_free()
	_backdrop = null
	_camera = null
	remove_child(_ui)
	_ui.queue_free()
	_ui = null
	_options_window = null
	_options_panel = null
	_name_entry = null
	_difficulty_window = null
	_title_label = null
	_menu_window = null
	_continue_button = null
	_options_button = null


## The saved game; if the file exists but can't be read, a marker Dictionary that Game
## rejects, so it starts a new game with the "could not load" notice.
func _load_save() -> Dictionary:
	var save := SaveStore.load_game()
	if save.is_empty() and SaveStore.has_save():
		return {"unreadable": true}
	return save


## The menu gives way to the NameEntry; its name starts a new game, Volver brings the
## menu back.
func _open_name_entry() -> void:
	if _starting or _name_entry != null:
		return
	_audio.play_sfx(SfxLibrary.ACCEPT)
	_menu_window.hide()
	_title_label.hide()
	_name_entry = NameEntry.new()
	_name_entry.setup(_audio)
	_ui.add_child(_name_entry)
	_name_entry.accepted.connect(_on_name_accepted)
	_name_entry.cancelled.connect(_back_to_menu)
	if _autoplay:
		_name_entry.demo(AUTOPLAY_NAME)


## The name is set: the difficulty comes next (on autoplay Game picks it from the arguments).
func _on_name_accepted(hero_name: String) -> void:
	if _autoplay:
		_start_game({}, hero_name)
		return
	_close_name_entry()
	_difficulty_window = DifficultyWindow.new()
	_difficulty_window.setup(_audio)
	_ui.add_child(_difficulty_window)
	_difficulty_window.chosen.connect(func(id: String) -> void: _start_game({}, hero_name, id))
	_difficulty_window.cancelled.connect(_back_to_menu)


## Volver from the name or the difficulty: the menu again.
func _back_to_menu() -> void:
	_close_name_entry()
	if _difficulty_window != null:
		_difficulty_window.queue_free()
		_difficulty_window = null
	_title_label.show()
	_menu_window.show()
	_focus(_continue_button if not _continue_button.disabled else _options_button)


func _close_name_entry() -> void:
	if _name_entry != null:
		_name_entry.queue_free()
		_name_entry = null


## Fades out, swaps the title for a Game (save empty = new game with hero_name and
## difficulty) and fades in.
func _start_game(save: Dictionary, hero_name := "", difficulty := Difficulty.NORMAL) -> void:
	if _starting:
		return
	_starting = true
	if _ui:
		_audio.play_sfx(SfxLibrary.ACCEPT)
		await _fade_to(1.0)
		_close_title()
	_game = GAME_SCENE.instantiate()
	_game.setup(_audio, _options, save, hero_name, difficulty)
	_game.quit_to_title.connect(_on_quit_to_title)
	add_child(_game)
	await _fade_to(0.0)


func _on_quit_to_title() -> void:
	if _game == null:
		return
	# The tree may be paused (pause menu); the fade tween keeps running, the game stays frozen.
	await _fade_to(1.0)
	if _game == null:
		return
	var old := _game
	_game = null
	remove_child(old)
	old.queue_free()
	get_tree().paused = false
	if _autoplay_save:
		_autoplay_save = false
		_starting = false
		_start_game(_load_save())
		return
	if _autoplay:
		get_tree().quit()
		return
	_open_title()
	await _fade_to(0.0)


func _build_menu() -> void:
	_ui = CanvasLayer.new()
	add_child(_ui)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(root)
	var title := Label.new()
	title.text = TITLE_TEXT
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", TITLE_SIZE)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.45))
	title.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.0))
	title.add_theme_constant_override("outline_size", 18)
	root.add_child(title)
	_title_label = title
	title.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, \
		Control.PRESET_MODE_MINSIZE, 90)
	var subtitle := Label.new()
	subtitle.text = SUBTITLE_TEXT
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", SUBTITLE_SIZE)
	subtitle.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))
	subtitle.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.0))
	subtitle.add_theme_constant_override("outline_size", 10)
	title.add_child(subtitle)  # it comes and goes with the title
	subtitle.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	subtitle.offset_left = 0.0
	subtitle.offset_right = 0.0
	subtitle.offset_top = 0.0
	subtitle.offset_bottom = 0.0
	subtitle.grow_horizontal = Control.GROW_DIRECTION_BOTH
	subtitle.grow_vertical = Control.GROW_DIRECTION_END
	var version := Label.new()
	version.text = "v%s" % ProjectSettings.get_setting("application/config/version")
	version.add_theme_font_size_override("font_size", VERSION_SIZE)
	version.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.0))
	version.add_theme_constant_override("outline_size", 6)
	root.add_child(version)
	version.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, \n		Control.PRESET_MODE_MINSIZE, 12)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_top = MENU_TOP
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	_menu_center = center
	_menu_window = BattleHud.make_window()
	_menu_window.custom_minimum_size = Vector2(320, 0)
	center.add_child(_menu_window)
	var menu := VBoxContainer.new()
	menu.add_theme_constant_override("separation", 8)
	_menu_window.add_child(menu)
	var start := _button("Nueva partida")
	start.pressed.connect(func() -> void: new_game.emit())
	menu.add_child(start)
	_continue_button = _button("Continuar")
	_continue_button.disabled = not SaveStore.has_save()
	var story: Variant = SaveStore.load_game().get("story")
	if story is Dictionary and story.get("finished", false) == true:
		_continue_button.text = "Continuar (terminada)"
	_continue_button.pressed.connect(func() -> void: continue_game.emit())
	menu.add_child(_continue_button)
	_options_button = _button("Opciones")
	_options_button.pressed.connect(_open_options)
	menu.add_child(_options_button)
	_options_window = BattleHud.make_window()
	_options_window.hide()
	center.add_child(_options_window)
	_options_panel = OptionsPanel.new()
	_options_panel.setup(_options, _audio)
	_options_panel.closed.connect(_close_options)
	_options_window.add_child(_options_panel)
	_focus(_continue_button if not _continue_button.disabled else start)


func _open_options() -> void:
	_audio.play_sfx(SfxLibrary.ACCEPT)
	_menu_window.hide()
	# The options need the whole height of the screen.
	_title_label.hide()
	_menu_center.offset_top = 0
	_options_window.show()
	_quiet_focus = true
	_options_panel.focus_first()
	_quiet_focus = false


func _close_options() -> void:
	_options_window.hide()
	_title_label.show()
	_menu_center.offset_top = MENU_TOP
	_menu_window.show()
	_focus(_options_button)


func _focus(button: Button) -> void:
	_quiet_focus = true
	button.grab_focus()
	_quiet_focus = false


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.flat = true
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	button.focus_entered.connect(func() -> void:
		if not _quiet_focus:
			_audio.play_sfx(SfxLibrary.CURSOR))
	return button


func _build_fade() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade)


func _fade_to(alpha: float) -> void:
	var t := create_tween()
	t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_property(_fade, "color:a", alpha, FADE_TIME)
	await t.finished
