class_name TitleScreen extends Node
## Main scene. Shows the game's name over the meadow seen from a slowly drifting
## top-down camera, with "Nueva partida", "Continuar" (disabled without a save) and
## "Opciones" (keyboard, mouse and touch). Owns the only AudioDirector and the options,
## and creates a Game for the new or loaded session (new_game / continue_game); a new
## game first asks the hero's name (NameEntry, over the meadow). When the Game emits
## quit_to_title it frees it and shows the title again. There are three save slots
## (SaveStore, SlotList): "Continuar" opens the list and only lets usable saves be picked
## (it is disabled when none is; a finished one offers "Continuar" or "Volver"); "Nueva partida" goes straight to the name when every slot is
## empty (slot 1), else asks for a slot and asks again before replacing a save that works.
## The old single save.json moves to slot 1 the first time (SaveStore.migrate_legacy()).
## With `-- --autoplay` the name entry types AUTOPLAY_NAME by itself and the new game
## starts at once, without the menu. With `--autoplay-save` too, going back to the title
## loads the save straight away.

signal new_game
signal continue_game

const GAME_SCENE := preload("res://scenes/game/game.tscn")
## The name the autoplay types (an accent, to try the grid's last row).
const AUTOPLAY_NAME := "Rocío"
const TITLE_TEXT := "Villaclaro"
const SUBTITLE_TEXT := "La Niebla del Norte"
const FADE_TIME := 0.4
const UPDATE_CHECK_TIME := 1.0
const UPDATE_WIDTH := 300
const UPDATE_TEXT := "Hay una versión nueva. Recargar"
## Where the menu's room starts under the title: the subtitle's bottom (measured: 227 on a
## desktop, 110 on a phone) plus SPACE_2.
const MENU_TOP := 235
## On a phone the title moves up, so the menu fits under its subtitle.
const TOUCH_MENU_TOP := 118
const TOUCH_TITLE_TOP := 8
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
var _fullscreen_button: Button
var _options_window: PanelContainer
var _options_backdrop: Control
var _options_panel: OptionsPanel
var _transfer: SaveTransfer
var _slot_window: PanelContainer
var _slot_list: SlotList
## The slot of the game being started or played.
var _game_slot := 1
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
var _update_wait := 0.0
var _update_window: PanelContainer


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_autoplay = args.has("--autoplay")
	_autoplay_save = _autoplay and args.has("--autoplay-save")
	_options = SaveStore.load_options()
	DisplaySettings.apply(get_window(), _options)
	if Device.is_touch():
		# A child of the title itself, which stays while the Game comes and goes.
		var hint_layer := CanvasLayer.new()
		hint_layer.layer = UiTokens.LAYER_SYSTEM
		hint_layer.add_child(RotateHint.new())
		add_child(hint_layer)
	KeyMap.apply(_options.keys)
	_audio = AudioDirector.new()
	add_child(_audio)
	_transfer = SaveTransfer.new()
	add_child(_transfer)
	_audio.set_volumes(_options.music_volume, _options.sfx_volume)
	WebUpdate.watch()
	_build_fade()
	new_game.connect(_on_new_game)
	continue_game.connect(func() -> void: _open_slots(SlotList.Mode.LOAD))
	SaveStore.migrate_legacy()
	_open_title()
	if _autoplay:
		_open_name_entry()


## The fullscreen row shows only while the window is not fullscreen; the focus leaves it
## before it hides.
func _sync_fullscreen_row() -> void:
	if _fullscreen_button == null:
		return
	var wanted := get_window().mode != Window.MODE_FULLSCREEN
	if _fullscreen_button.visible == wanted:
		return
	if not wanted and _fullscreen_button.has_focus():
		_focus(_options_button)
	_fullscreen_button.visible = wanted


func _process(delta: float) -> void:
	if _camera == null:
		return
	_sync_fullscreen_row()
	_update_wait -= delta
	if _update_wait <= 0.0 and _update_window == null:
		_update_wait = UPDATE_CHECK_TIME
		if WebUpdate.is_ready():
			_show_update_notice()
	if _update_window != null:
		_update_window.visible = _menu_window.visible
	_drift += delta * DRIFT_SPEED
	var focus := DRIFT_CENTER + Vector3(sin(_drift) * DRIFT_RADIUS.x, 0.0,
		cos(_drift * 0.7) * DRIFT_RADIUS.y)
	var pitch := deg_to_rad(PITCH_DEG)
	_camera.global_position = focus + Vector3(0.0, sin(pitch), cos(pitch)) * DISTANCE
	_camera.look_at(focus, Vector3.UP)


func _unhandled_input(event: InputEvent) -> void:
	if _slot_window and _slot_window.visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_slot_list.back()
		return
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
	_update_window = null
	_options_window = null
	_options_backdrop = null
	_options_panel = null
	_slot_window = null
	_slot_list = null
	_name_entry = null
	_difficulty_window = null
	_title_label = null
	_menu_window = null
	_continue_button = null
	_options_button = null
	_fullscreen_button = null


## The saved game of slot; if the file exists but can't be read, a marker Dictionary that
## Game rejects, so it starts a new game with the "could not load" notice.
func _load_save(slot: int) -> Dictionary:
	var save := SaveStore.load_game(slot)
	if save.is_empty() and SaveStore.has_save(slot):
		return {"unreadable": true}
	return save


## Nueva partida: straight to the name in slot 1 when every slot is empty, else the slots.
func _on_new_game() -> void:
	if _starting or _name_entry != null:
		return
	if SaveStore.all_empty():
		_game_slot = 1
		_open_name_entry()
	else:
		_open_slots(SlotList.Mode.NEW)


func _open_slots(mode: SlotList.Mode) -> void:
	if _starting or _name_entry != null:
		return
	_audio.play_sfx(SfxLibrary.ACCEPT)
	_menu_window.hide()
	_title_label.hide()
	_options_window.hide()
	_menu_center.offset_top = 0
	_slot_window.show()
	_options_backdrop.show()
	_slot_list.open(mode)


func _hide_slots() -> void:
	_slot_window.hide()
	_options_backdrop.hide()
	_menu_center.offset_top = _menu_top()


## Volver from the slots: the menu again (Continuar may have changed).
func _close_slots() -> void:
	_hide_slots()
	_continue_button.disabled = not SaveStore.any_usable()
	_title_label.show()
	_menu_window.show()
	_focus(_continue_button if not _continue_button.disabled else _options_button)


func _on_slot_chosen(slot: int) -> void:
	_game_slot = slot
	if _slot_list.mode == SlotList.Mode.LOAD:
		_start_game(_load_save(slot), "", Difficulty.NORMAL, slot)
		return
	_hide_slots()
	_open_name_entry()


## The menu gives way to the NameEntry; its name starts a new game, Volver brings the
## menu back.
func _open_name_entry(preset := "") -> void:
	if _starting or _name_entry != null:
		return
	_audio.play_sfx(SfxLibrary.ACCEPT)
	_menu_window.hide()
	_title_label.hide()
	_name_entry = NameEntry.new()
	_name_entry.setup(_audio)
	_name_entry.preset = preset
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
	_difficulty_window.chosen.connect(func(id: String) -> void: _start_game({}, hero_name, id, _game_slot))
	_difficulty_window.cancelled.connect(_back_to_name.bind(hero_name))


## Volver from the difficulty: the name again, as it was typed.
func _back_to_name(hero_name: String) -> void:
	_difficulty_window.queue_free()
	_difficulty_window = null
	_open_name_entry(hero_name)


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
func _start_game(save: Dictionary, hero_name := "", difficulty := Difficulty.NORMAL,
		slot := 1) -> void:
	if _starting:
		return
	_starting = true
	_game_slot = slot
	if _ui:
		_audio.play_sfx(SfxLibrary.ACCEPT)
		await _fade_to(1.0)
		_close_title()
	_game = GAME_SCENE.instantiate()
	_game.setup(_audio, _options, save, hero_name, difficulty, slot)
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
		_start_game(_load_save(_game_slot), "", Difficulty.NORMAL, _game_slot)
		return
	if _autoplay:
		get_tree().quit()
		return
	_open_title()
	await _fade_to(0.0)


## In the corner away from the version: it never moves the menu.
func _show_update_notice() -> void:
	_update_window = BattleHud.make_window()
	var button := _button(UPDATE_TEXT)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.custom_minimum_size.x = UPDATE_WIDTH
	button.pressed.connect(WebUpdate.apply)
	_update_window.add_child(button)
	_ui.add_child(_update_window)
	# Grows upward from the corner, so the wrapped text never runs off the screen.
	_update_window.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_update_window.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_update_window.offset_left = 12.0
	_update_window.offset_top = -12.0
	_update_window.offset_bottom = -12.0


func _build_menu() -> void:
	_ui = CanvasLayer.new()
	_ui.layer = UiTokens.LAYER_HUD
	add_child(_ui)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(root)
	var title := Label.new()
	title.text = TITLE_TEXT
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# display-l on a phone held sideways, so the menu with the fullscreen row fits under it.
	UiTheme.style_label(title, &"display-l" if Device.is_touch() else &"display-xl", &"text-display",
		UiTokens.OUTLINE_XL, &"text-outline-warm")
	root.add_child(title)
	_title_label = title
	title.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, \
		Control.PRESET_MODE_MINSIZE, TOUCH_TITLE_TOP if Device.is_touch() else 90)
	var subtitle := Label.new()
	subtitle.text = SUBTITLE_TEXT
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTheme.style_label(subtitle, &"title-m" if Device.is_touch() else &"title-l", &"text-display-soft",
		UiTokens.OUTLINE_L, &"text-outline-warm")
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
	UiTheme.style_label(version, &"caption", &"text-primary", UiTokens.OUTLINE_S, &"text-outline-warm")
	root.add_child(version)
	version.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, \
		Control.PRESET_MODE_MINSIZE, UiTokens.SPACE_3)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_top = _menu_top()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	_menu_center = center
	_menu_window = BattleHud.make_window()
	_menu_window.custom_minimum_size = Vector2(320, 0)
	center.add_child(_menu_window)
	var menu := VBoxContainer.new()
	menu.add_theme_constant_override("separation", UiTokens.SPACE_2)
	_menu_window.add_child(menu)
	var start := _button("Nueva partida")
	start.pressed.connect(func() -> void: new_game.emit())
	menu.add_child(start)
	_continue_button = _button("Continuar")
	_continue_button.disabled = not SaveStore.any_usable()
	_continue_button.pressed.connect(func() -> void: continue_game.emit())
	menu.add_child(_continue_button)
	_options_button = _button("Opciones")
	_options_button.pressed.connect(_open_options)
	menu.add_child(_options_button)
	if Device.is_touch() and not Device.is_ios():
		# The browser's bar takes a quarter of the height, and fullscreen needs a press.
		# _process() shows the row whenever the window is not fullscreen: the browser can
		# leave it at any time (the back gesture).
		_fullscreen_button = _button("Pantalla completa")
		_fullscreen_button.pressed.connect(func() -> void:
			get_window().mode = Window.MODE_FULLSCREEN)
		menu.add_child(_fullscreen_button)
		_sync_fullscreen_row()
	UiTheme.add_cursor(_menu_window)
	# A tap outside the options window goes back; under the centred windows, shown only while open.
	_options_backdrop = Control.new()
	_options_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_options_backdrop.gui_input.connect(func(event: InputEvent) -> void:
		if not UiStyle.is_outside_tap(event):
			return
		if _slot_window.visible:
			_slot_list.back()
		else:
			_options_panel.back())
	_options_backdrop.hide()
	root.add_child(_options_backdrop)
	root.move_child(_options_backdrop, center.get_index())
	_options_window = BattleHud.make_window()
	_options_window.hide()
	center.add_child(_options_window)
	_options_panel = OptionsPanel.new()
	_options_panel.setup(_options, _audio)
	_options_panel.closed.connect(_close_options)
	_options_window.add_child(_options_panel)
	UiTheme.add_cursor(_options_window)
	_slot_window = BattleHud.make_window()
	_slot_window.hide()
	center.add_child(_slot_window)
	_slot_list = SlotList.new()
	_slot_list.setup(_audio, _transfer)
	_slot_list.chosen.connect(_on_slot_chosen)
	_slot_list.closed.connect(_close_slots)
	_slot_list.changed.connect(func() -> void:
		_continue_button.disabled = not SaveStore.any_usable())
	_options_panel.transfer_requested.connect(func() -> void:
		_open_slots(SlotList.Mode.MANAGE))
	_slot_window.add_child(_slot_list)
	UiTheme.add_cursor(_slot_window)
	_focus(_continue_button if not _continue_button.disabled else start)


func _open_options() -> void:
	_audio.play_sfx(SfxLibrary.ACCEPT)
	_menu_window.hide()
	# The options need the whole height of the screen.
	_title_label.hide()
	_menu_center.offset_top = 0
	_options_window.show()
	_options_backdrop.show()
	_quiet_focus = true
	_options_panel.focus_first()
	_quiet_focus = false


func _close_options() -> void:
	_options_window.hide()
	_options_backdrop.hide()
	_title_label.show()
	_menu_center.offset_top = _menu_top()
	_menu_window.show()
	_focus(_options_button)


func _focus(button: Button) -> void:
	_quiet_focus = true
	button.grab_focus()
	_quiet_focus = false


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	UiTheme.menu_row(button)
	button.add_theme_font_override(&"font", UiTheme.font_for(&"title-s"))
	button.add_theme_font_size_override(&"font_size", UiTokens.TYPE_TITLE_S_SIZE)
	# The row reserves room on the left for the cursor; the same on the right centres the text.
	for box_name in [&"normal", &"hover", &"pressed", &"hover_pressed", &"disabled"]:
		var box := UiTheme.row_style()
		box.content_margin_right = box.content_margin_left
		button.add_theme_stylebox_override(box_name, box)
	button.focus_entered.connect(func() -> void:
		if not _quiet_focus:
			_audio.play_sfx(SfxLibrary.CURSOR))
	return button


func _build_fade() -> void:
	var layer := CanvasLayer.new()
	layer.layer = UiTokens.LAYER_TITLE_FADE
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


func _menu_top() -> int:
	return TOUCH_MENU_TOP if Device.is_touch() else MENU_TOP
