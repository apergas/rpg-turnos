class_name MapHud extends CanvasLayer
## The map's 2D layer (UiTokens.LAYER_HUD): the status window (name, PV, PM, EXP, gold and
## the missions), the place line and the MapSquare under it, the notice window, the place's
## banner, the prompt with its keycap (MapUses says what it reads), on a phone the TouchPad
## and the use button, the phone's walking hint and the DialogueBox. Owned by World, which
## calls setup() before add_child; it builds itself in _ready() and never stores World.

## The map square was tapped (World emits map_requested unless the map is frozen).
signal map_pressed
## Phones: a short touch on the map (TouchPad.tapped), a pinch, the use button.
signal tapped(screen: Vector2)
signal pinched(ratio: float)
signal use_pressed

const NOTICE_TIME := 4.0
## Fade in and out of the notice window.
const NOTICE_FADE := 0.2
## Seconds "Misión cumplida" stays in the status window.
const MISSION_DONE_TIME := 4.0
## The notice window, top centre (clear of the status window and the ☰ button).
const NOTICE_MAX_WIDTH := float(UiTokens.WINDOW_W_XL)
const UI_EDGE := float(UiTokens.SPACE_6)
## Phone: the mission line wraps here and the bars narrow to fit.
const TOUCH_MISSION_WIDTH := 300.0
## The use button of the phone interface.
const USE_BUTTON_SIZE := Vector2(180, 72)
## The phone's walking hint: wraps here and sits over the use button's row.
const TOUCH_HINT_WIDTH := float(UiTokens.WINDOW_W_L)
## The place's name, big, the first time the map is the player's (World.freeze(false)).
const BANNER_TOP := 110.0
const BANNER_FADE := 0.5
const BANNER_TIME := 2.5
## Mission lines wrap past this width, so the status window stays at the side of the screen.
const MISSION_WIDTH := 420.0

## Phones: the pad that reads the fingers (null off a phone). World feeds it input and
## reads its direction.
var pad: TouchPad:
	get:
		return _pad
## The dialogue window (World.show_dialogue(), say_lines(), set_audio()).
var dialogue: DialogueBox:
	get:
		return _dialogue

var _zone: ZoneData
var _autoplay := false
## The status window and the map square under it: a cutscene hides them together.
var _status_column: VBoxContainer
var _name_label: Label
var _hp_bar: StatBar
var _mp_bar: StatBar
var _exp_bar: StatBar
var _gold_label: Label
var _mission_box: VBoxContainer
## The lines of the status window, and the serial that lets "Misión cumplida" put them back.
var _missions: Array[String] = []
var _mission_done_serial := 0
var _mission_done := false
var _map_square: MapSquare
var _has_explored := false
var _notice: Label
var _notice_word: Label
var _notice_tween: Tween
var _notice_window: PanelContainer
var _place_label: Label
var _hint_window: PanelContainer
var _hint: Label
var _banner: VBoxContainer
var _banner_tween: Tween
var _banner_shown := false
var _prompt: Label
var _prompt_box: VBoxContainer
var _prompt_key: Label
var _prompt_cap: StyleBoxFlat
## Phones: the button that replaces the prompt, and the pad that reads the fingers.
var _use_button: Button
var _pad: TouchPad
var _dialogue: DialogueBox


func setup(zone: ZoneData) -> void:
	_zone = zone
	_autoplay = RunFlags.autoplay()
	layer = UiTokens.LAYER_HUD


func _ready() -> void:
	_build_ui()
	_place_label.text = _zone.map_label()


## Every physics tick (World): the hero's marker on the map square, and the phone's hint
## goes once the hero walks.
func step(hero_pos: Vector3, last_step_m: float) -> void:
	_map_square.follow(hero_pos)
	if _hint_window and _hint_window.visible and last_step_m > 0.0:
		_hint_window.hide()


## Forgets the fingers on the map (a window, a battle or a cutscene took over).
func reset_pad() -> void:
	if _pad:
		_pad.reset()


## Shows the prompt (desktop: the text and the accept key's keycap) or the phone's use
## button, and returns the screen rect it covers (MapUses hides the figure signs under it).
func show_prompt(text: String, key_name: String) -> Rect2:
	if _use_button:
		_use_button.text = text
		_use_button.show()
		return _use_button.get_global_rect()
	_prompt.text = text
	_prompt_key.text = key_name
	_paint_prompt_cap()
	_prompt_box.show()
	return _prompt_box.get_global_rect()


func hide_prompt() -> void:
	_prompt_box.hide()
	if _use_button:
		_use_button.hide()


func prompt_showing() -> bool:
	return _use_button.visible if _use_button else _prompt_box.visible


## The place's banner, the first time the map is the player's (World.freeze(false)).
func show_banner_once() -> void:
	if _banner_shown:
		return
	_banner_shown = true
	_show_banner()


## A cutscene: the status window, the map square, the place line, the hint, the notice and
## the banner go.
func begin_cutscene() -> void:
	_status_column.hide()
	_map_square.hide()
	_place_label.hide()
	if _hint_window:
		_hint_window.hide()
	_notice_window.hide()
	if _banner_tween:
		_banner_tween.kill()
	_banner.hide()


func end_cutscene() -> void:
	_status_column.show()
	_map_square.show()
	_place_label.show()


## What has been seen of this zone, for the map square.
func set_explored(map: ExploredMap) -> void:
	_map_square.set_map(map)
	_has_explored = true


## The map square's points of interest (MapMarks): they follow the dry wells and, on a
## dungeon floor, the lever, the gates and the key.
func refresh_map_marks(flags: Dictionary, dry_wells: Array[String]) -> void:
	if not _has_explored:
		return
	_map_square.set_marks(MapMarks.of_zone(_zone, flags, dry_wells))


## The pause menu covers the middle of the screen and says the same as the status window,
## which goes away behind it (with the map square).
func set_status_shown(on: bool) -> void:
	reset_pad()  # a finger's release is lost while the tree is paused
	_status_column.visible = on
	_map_square.visible = on
	_place_label.visible = on


func refresh_status(hero: Combatant, _potions: int, gold: int, missions: Array[String] = []) -> void:
	_name_label.text = StatBar.hero_title(hero)
	_hp_bar.show_hp(hero.hp, hero.max_hp)
	_mp_bar.show_mp(hero.mp, hero.max_mp)
	_exp_bar.show_exp(hero)
	_gold_label.text = "%d G" % gold
	_missions = missions
	if not _mission_done:
		_show_missions(missions)


## Puts "Misión cumplida" (or text) in the mission list for a few seconds, then the
## missions under way come back.
func show_mission_done(text: String) -> void:
	_mission_done_serial += 1
	var serial := _mission_done_serial
	_mission_done = true
	var lines: Array[String] = [text]
	_show_missions(lines, true)
	if _autoplay:
		print(text)
	await get_tree().create_timer(MISSION_DONE_TIME).timeout
	if serial == _mission_done_serial:
		_mission_done = false
		_show_missions(_missions)


func _show_missions(lines: Array[String], done := false) -> void:
	for child in _mission_box.get_children():
		_mission_box.remove_child(child)
		child.queue_free()
	var shown := lines.slice(0, 1) if Device.is_touch() else lines
	var width := TOUCH_MISSION_WIDTH if Device.is_touch() else MISSION_WIDTH
	for line in shown:
		var label := Label.new()
		label.theme_type_variation = UiTheme.CAPTION
		if done:
			UiTheme.style_label(label, &"caption", &"text-positive")
		_mission_box.add_child(label)
		BattleHud.fit_label(label, line, width)


## Shows a short line in its own window for NOTICE_TIME seconds (a newer one replaces it),
## under a small tone word ("Guardado", "Cerrado"...) in the colour of `tone`. Only the text is printed.
func show_notice(text: String, word := "Aviso", tone := &"text-info") -> void:
	_notice_word.text = word
	UiTheme.style_label(_notice_word, &"label", tone)
	BattleHud.fit_label(_notice, text, NOTICE_MAX_WIDTH)
	_notice_window.show()
	if _autoplay:
		print(text)
	# One tween owned by the map: a newer notice kills it, and it dies with the map.
	if _notice_tween:
		_notice_tween.kill()
	_notice_window.modulate.a = 0.0
	_notice_tween = create_tween()
	_notice_tween.tween_property(_notice_window, "modulate:a", 1.0, NOTICE_FADE)
	_notice_tween.tween_interval(NOTICE_TIME - 2.0 * NOTICE_FADE)
	_notice_tween.tween_property(_notice_window, "modulate:a", 0.0, NOTICE_FADE)
	_notice_tween.tween_callback(_notice_window.hide)


## A line at the bottom until the hero first walks (phones, once: Game decides).
func show_touch_hint(text: String) -> void:
	if _hint_window == null:
		_hint_window = BattleHud.make_window()
		_hint_window.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_hint_window)
		_hint_window.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		_hint_window.grow_horizontal = Control.GROW_DIRECTION_BOTH
		_hint_window.grow_vertical = Control.GROW_DIRECTION_BEGIN
		_hint_window.offset_left = 0.0
		_hint_window.offset_right = 0.0
		_hint_window.offset_bottom = -(UI_EDGE + USE_BUTTON_SIZE.y + UiTokens.SPACE_3)
		_hint_window.offset_top = _hint_window.offset_bottom
		_hint = _label()
		_hint_window.add_child(_hint)
	BattleHud.fit_label(_hint, text, TOUCH_HINT_WIDTH)
	_hint_window.show()


func _build_ui() -> void:
	# No size of its own: the column follows the status window as it grows and shrinks.
	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_TOP_LEFT)
	column.offset_left = UI_EDGE
	column.offset_top = UI_EDGE
	column.offset_right = UI_EDGE
	column.offset_bottom = UI_EDGE
	column.add_theme_constant_override("separation", UiTokens.SPACE_2)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	_status_column = column
	var panel := BattleHud.make_window()
	column.add_child(panel)
	_map_square = MapSquare.new(MapSquare.TOUCH_SIDE if Device.is_touch() else MapSquare.SIDE)
	_map_square.clickable = true
	_map_square.pressed.connect(map_pressed.emit)
	_place_label = Label.new()
	_place_label.theme_type_variation = UiTheme.OUTLINED
	_place_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if Device.is_touch():
		# Under the menu button, top right.
		add_child(_map_square)
		_map_square.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		_map_square.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		_map_square.offset_right = -PauseMenu.MENU_BUTTON_MARGIN
		_map_square.offset_left = _map_square.offset_right - MapSquare.TOUCH_SIDE
		_map_square.offset_top = PauseMenu.MENU_BUTTON_MARGIN + PauseMenu.MENU_BUTTON_SIZE.y + UiTokens.SPACE_2
		_map_square.offset_bottom = _map_square.offset_top + MapSquare.TOUCH_SIDE
		add_child(_place_label)
		_place_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_place_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		_place_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		_place_label.offset_right = _map_square.offset_right
		_place_label.offset_left = _map_square.offset_right
		_place_label.offset_top = _map_square.offset_bottom + UiTokens.SPACE_1
		_place_label.offset_bottom = _place_label.offset_top
	else:
		column.add_child(_place_label)
		column.add_child(_map_square)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UiTokens.SPACE_1)
	panel.add_child(box)
	_name_label = Label.new()
	_name_label.theme_type_variation = UiTheme.TITLE
	box.add_child(_name_label)
	_hp_bar = StatBar.new(StatBar.HP)
	box.add_child(_hp_bar)
	_mp_bar = StatBar.new(StatBar.MP)
	box.add_child(_mp_bar)
	_exp_bar = StatBar.new(StatBar.EXP)
	box.add_child(_exp_bar)
	if Device.is_touch():
		# Estado in the pause menu says the same.
		_exp_bar.hide()
	var line := HSeparator.new()
	line.theme_type_variation = UiTheme.STATUS_LINE
	box.add_child(line)
	_gold_label = Label.new()
	_gold_label.theme_type_variation = UiTheme.MONEY
	box.add_child(_gold_label)
	_mission_box = VBoxContainer.new()
	_mission_box.add_theme_constant_override("separation", 0)
	box.add_child(_mission_box)
	_notice_window = BattleHud.make_window()
	_notice_window.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_notice_window.offset_left = 0
	_notice_window.offset_right = 0
	_notice_window.offset_top = UI_EDGE
	_notice_window.offset_bottom = UI_EDGE
	_notice_window.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_notice_window.hide()
	add_child(_notice_window)
	var notice_box := VBoxContainer.new()
	notice_box.add_theme_constant_override("separation", UiTokens.SPACE_1)
	_notice_window.add_child(notice_box)
	_notice_word = _label()
	notice_box.add_child(_notice_word)
	_notice = _label()
	notice_box.add_child(_notice)
	_build_banner()
	_prompt_box = VBoxContainer.new()
	_prompt_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_prompt_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_prompt_box)
	_prompt = Label.new()
	_prompt.theme_type_variation = UiTheme.OUTLINED
	_prompt.text = MapUses.PROMPTS[MapUses.TALK]
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_box.add_child(_prompt)
	# The key of the action, on a badge that is not a status colour.
	_prompt_key = Label.new()
	_prompt_key.theme_type_variation = UiTheme.NOTE
	_prompt_key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_key.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_prompt_key.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var key_panel := PanelContainer.new()
	var cap := StyleBoxFlat.new()
	_prompt_cap = cap
	_paint_prompt_cap()
	cap.set_border_width_all(UiTokens.BORDER_2)
	cap.set_corner_radius_all(UiTokens.RADIUS_S)
	cap.content_margin_left = UiTokens.SPACE_2
	cap.content_margin_right = UiTokens.SPACE_2
	cap.content_margin_top = UiTokens.SPACE_1
	cap.content_margin_bottom = UiTokens.SPACE_1
	key_panel.add_theme_stylebox_override(&"panel", cap)
	key_panel.custom_minimum_size = Vector2(UiTokens.ICON_M, UiTokens.ICON_M)
	key_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	key_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	key_panel.add_child(_prompt_key)
	_prompt_box.add_child(key_panel)
	_prompt_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, \
		Control.PRESET_MODE_MINSIZE, 200)
	_prompt_box.hide()
	if Device.is_touch():
		_build_touch_controls()
	_dialogue = DialogueBox.new()
	add_child(_dialogue)


## Phones: the pad behind every window, and the big use button.
func _build_touch_controls() -> void:
	_pad = TouchPad.new()
	add_child(_pad)
	move_child(_pad, 0)
	_pad.tapped.connect(tapped.emit)
	_pad.pinched.connect(pinched.emit)
	_use_button = Button.new()
	_use_button.focus_mode = Control.FOCUS_NONE
	_use_button.theme_type_variation = UiTheme.ACTION_BUTTON
	_use_button.custom_minimum_size = USE_BUTTON_SIZE
	_use_button.hide()
	add_child(_use_button)
	_use_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_use_button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_use_button.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_use_button.offset_right = -UI_EDGE
	_use_button.offset_bottom = -UI_EDGE
	_use_button.offset_left = -UI_EDGE - USE_BUTTON_SIZE.x
	_use_button.offset_top = -UI_EDGE - USE_BUTTON_SIZE.y
	_use_button.pressed.connect(use_pressed.emit)


## Two lines centred near the top: the place and, under it, its floor.
func _build_banner() -> void:
	_banner = VBoxContainer.new()
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.add_theme_constant_override("separation", 0)
	add_child(_banner)
	_banner.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_banner.offset_top = BANNER_TOP
	_banner.offset_bottom = BANNER_TOP
	for variation in [UiTheme.DISPLAY, UiTheme.DISPLAY_SUB]:
		var label := Label.new()
		label.theme_type_variation = variation
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_banner.add_child(label)
	_banner.hide()


## Fades the place's name in, holds it and fades it out.
func _show_banner() -> void:
	var name_label := _banner.get_child(0) as Label
	var floor_label := _banner.get_child(1) as Label
	name_label.text = _zone.display_name
	floor_label.text = _zone.floor_name
	floor_label.visible = _zone.floor_name != ""
	if _autoplay:
		print("Lugar: %s" % _zone.banner_text())
	if _banner_tween:
		_banner_tween.kill()
	_banner.modulate.a = 0.0
	_banner.show()
	_banner_tween = create_tween()
	_banner_tween.tween_property(_banner, "modulate:a", 1.0, BANNER_FADE)
	_banner_tween.tween_interval(BANNER_TIME)
	_banner_tween.tween_property(_banner, "modulate:a", 0.0, BANNER_FADE)
	_banner_tween.tween_callback(_banner.hide)


## The keycap's colours, read again each time it shows so it follows the high contrast option.
func _paint_prompt_cap() -> void:
	_prompt_cap.bg_color = UiTokens.color(&"surface-window")
	_prompt_cap.border_color = UiTokens.color(&"border-subtle")


func _label() -> Label:
	return Label.new()
