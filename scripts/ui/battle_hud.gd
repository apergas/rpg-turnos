class_name BattleHud extends Control
## Dragon Quest style battle UI: hero status (top left: name, level and status badges,
## PV and PM bars), command window and message window (bottom; the message window fits
## its text, BattleHud.fit_label()). Main menu: Atacar,
## Hechizos, Objetos, Defender, Huir; Hechizos and Objetos open a list where a row that
## can't be used is grey and says why. With two enemies standing, Atacar and one-target
## spells ask for the target: target_changed tells the scene where to put the arrow.
## Keyboard: W / S or up / down move, A / D or left / right change the target,
## Enter / Space / E accept, Esc / Q / Backspace / X go back. Mouse and touch: click a
## row; click an enemy to aim and click it again to confirm; a click anywhere else goes
## back. Choices are ignored for MENU_GUARD seconds after the menu opens, so a press
## meant to skip a message never picks a command. show_message() can be awaited: it
## types the text out (char_time seconds per character) and returns when the player
## advances (click, Enter, Space, E) or after a short auto-advance. With set_audio()
## moving, choosing and going back make a sound.

signal command_chosen(cmd: Dictionary)
## Enemy index the target arrow points at, or -1 to hide it.
signal target_changed(index: int)

enum Page { NONE, MAIN, SPELLS, ITEMS, TARGET }

const CHAR_TIME := 0.025
const AUTO_ADVANCE := 0.6
const MENU_GUARD := 0.3
const FONT_SIZE := 24
const BADGE_FONT_SIZE := 16
## Least width of the command window (a longer row widens it).
const MENU_WIDTH := 240.0
## Margin of the windows to the screen edges and gap between them.
const EDGE := 24.0
const GAP := 16.0
## The thin bar over an enemy: its life left, no number.
const ENEMY_BAR_SIZE := Vector2(96, 8)
const ENEMY_BAR_BACK := Color(0.0, 0.0, 0.0, 0.7)
## Inner margins of every window: modest, the window hugs what it holds.
const WINDOW_MARGIN := Vector2(14, 10)
## Seconds each step of demo() stays on screen.
const DEMO_STEP := 0.35
const MAIN_ROWS: Array[String] = ["Atacar", "Hechizos", "Objetos", "Defender", "Huir"]
## Main menu row of each command type.
const MAIN_ROW_OF := {
	BattleEngine.CMD_ATTACK: 0,
	BattleEngine.CMD_SKILL: 1,
	BattleEngine.CMD_ITEM: 2,
	BattleEngine.CMD_DEFEND: 3,
	BattleEngine.CMD_FLEE: 4,
}
## Badge text and color of each status, shown next to the PV.
const BADGES := {
	BattleEngine.POISON: ["Veneno", Color(0.5, 0.2, 0.65)],
	BattleEngine.SLEEP: ["Sueño", Color(0.2, 0.35, 0.8)],
	BattleEngine.SILENCE: ["Silencio", Color(0.4, 0.4, 0.45)],
}

## Returns the enemy index under a screen point, or -1. Set by BattleScene.
var pick_target: Callable
## Seconds per typed character (the text speed option); 0.0 shows the message at once.
var char_time := CHAR_TIME

var _engine: BattleEngine
var _name_label: Label
var _badges: HBoxContainer
var _hp_bar: StatBar
var _mp_bar: StatBar
var _menu: PanelContainer
var _list: VBoxContainer
var _message: Label
var _audio: AudioDirector
## The enemies' bars, by enemy index: [background ColorRect, its red fill ColorRect].
var _enemy_bars: Array = []
var _page := Page.NONE
## Buttons of the open list and the one under the cursor.
var _rows: Array[Button] = []
var _cursor := 0
## Row of the main menu to go back to from a list.
var _main_cursor := 0
## Command waiting for its target, the page to go back to, the enemies to choose from
## and the one aimed at.
var _pending := {}
var _target_back := Page.MAIN
var _target_back_cursor := 0
var _targets: Array[int] = []
var _target_i := 0
var _menu_opened_ms := 0
var _advance_requested := false
## True while the code moves the cursor itself, so that move makes no sound.
var _quiet_focus := false
## Phone: the row that goes back (-1 when the page has none).
var _back_row := -1


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_status()
	_build_bottom()
	hide_menu()


func set_audio(audio: AudioDirector) -> void:
	_audio = audio


## The battle to show and command; also fills the status window.
func set_engine(engine: BattleEngine) -> void:
	_engine = engine
	var hero := engine.hero
	update_level(hero.level)
	update_hp(hero.hp, hero.max_hp)
	update_mp(hero.mp, hero.max_mp)
	update_status(hero.status)


func update_level(level: int) -> void:
	_name_label.text = "%s lvl %d" % [_engine.hero.display_name, level]


func update_hp(hp: int, max_hp: int) -> void:
	_hp_bar.show_hp(hp, max_hp)


func update_mp(mp: int, max_mp: int) -> void:
	_mp_bar.show_mp(mp, max_mp)


## Adds the bar of the next enemy, full. BattleScene places it every frame (it follows the
## figure on screen) and sets its life as the events play back.
func add_enemy_bar() -> void:
	var back := ColorRect.new()
	back.color = ENEMY_BAR_BACK
	back.size = ENEMY_BAR_SIZE
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(back)
	move_child(back, 0)  # under every window
	var fill := ColorRect.new()
	fill.color = StatBar.HP
	fill.position = Vector2.ONE
	fill.size = ENEMY_BAR_SIZE - Vector2(2, 2)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.add_child(fill)
	_enemy_bars.append([back, fill])


## Centers enemy i's bar on a screen point.
func place_enemy_bar(i: int, screen: Vector2) -> void:
	var back: ColorRect = _enemy_bars[i][0]
	back.position = (screen - ENEMY_BAR_SIZE / 2.0).round()


## Shows how much life enemy i has left, 0..1.
func set_enemy_life(i: int, ratio: float) -> void:
	var fill: ColorRect = _enemy_bars[i][1]
	fill.size.x = (ENEMY_BAR_SIZE.x - 2.0) * clampf(ratio, 0.0, 1.0)


## A fallen enemy's bar goes away.
func hide_enemy_bar(i: int) -> void:
	(_enemy_bars[i][0] as ColorRect).hide()


## One colored badge per status the hero has.
func update_status(status: Dictionary) -> void:
	for child in _badges.get_children():
		child.queue_free()
	for id: String in BADGES:
		if status.has(id):
			_badges.add_child(_badge(BADGES[id][0], BADGES[id][1]))


## Opens the main menu. The menu keeps its layout slot while hidden (it only fades out),
## so the message window never resizes.
func show_menu() -> void:
	_menu_opened_ms = Time.get_ticks_msec()
	_menu.modulate.a = 1.0
	_main_cursor = 0
	_open(Page.MAIN, 0)


func hide_menu() -> void:
	if _page == Page.TARGET:
		target_changed.emit(-1)
	_page = Page.NONE
	_menu.modulate.a = 0.0
	for row in _rows:
		_set_enabled(row, false)


## Autoplay: walks the menus to cmd as a player would (main row, list row, target) with
## a short pause on each step, then closes the menu without emitting anything.
func demo(cmd: Dictionary) -> void:
	if not MAIN_ROW_OF.has(cmd.type):
		return
	show_menu()
	_set_cursor(MAIN_ROW_OF[cmd.type])
	await get_tree().create_timer(DEMO_STEP).timeout
	var back := Page.MAIN
	if cmd.type == BattleEngine.CMD_SKILL:
		_main_cursor = _cursor
		_open(Page.SPELLS, _engine.hero.skills.find(cmd.skill))
		back = Page.SPELLS
		await get_tree().create_timer(DEMO_STEP).timeout
	elif cmd.type == BattleEngine.CMD_ITEM:
		_main_cursor = _cursor
		_open(Page.ITEMS, _item_ids().find(cmd.item))
		await get_tree().create_timer(DEMO_STEP).timeout
	if _needs_target(cmd):
		_ask_target(cmd, back)
		_aim_at(_targets.find(cmd.target))
		await get_tree().create_timer(DEMO_STEP * 2.0).timeout
	hide_menu()


func show_message(text: String) -> void:
	_set_message(text)
	_message.visible_characters = 0
	_advance_requested = false
	var total := _message.get_total_character_count()
	var shown := 0.0
	while _message.visible_characters < total and not _advance_requested:
		await get_tree().process_frame
		shown = float(total) if char_time <= 0.0 else shown + get_process_delta_time() / char_time
		_message.visible_characters = mini(total, int(shown))
	_message.visible_characters = -1
	_advance_requested = false
	var waited := 0.0
	while waited < AUTO_ADVANCE and not _advance_requested:
		await get_tree().process_frame
		waited += get_process_delta_time()
	_advance_requested = false


## Shared look of every window: dark panel with a white rounded border.
static func make_window() -> PanelContainer:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.12, 0.9)
	style.border_color = Color.WHITE
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	style.content_margin_left = WINDOW_MARGIN.x
	style.content_margin_right = WINDOW_MARGIN.x
	style.content_margin_top = WINDOW_MARGIN.y
	style.content_margin_bottom = WINDOW_MARGIN.y
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel


## Width of text on one line in label's font.
static func text_width(label: Label, text: String) -> float:
	return label.get_theme_font("font").get_multiline_string_size(text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x


## Sets the text so the window around label fits it: on one line up to max_width, wrapped
## at max_width past that. A window only follows if it has no size of its own: anchored
## with equal offsets, inside a CenterContainer or shrunk in a box.
static func fit_label(label: Label, text: String, max_width: float) -> void:
	label.text = text
	if text_width(label, text) > max_width:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size.x = max_width
	else:
		# The whole width at once, so a window that types its text doesn't grow with it.
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.custom_minimum_size.x = text_width(label, text)


## Every key of the menus is read here, before the buttons see it, so WASD and the
## arrows behave the same and the focus never moves on its own.
func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if _page == Page.NONE or key == null or not key.pressed:
		return
	if key.is_action(KeyMap.MOVE_UP):
		_move(-1)
	elif key.is_action(KeyMap.MOVE_DOWN):
		_move(1)
	elif key.is_action(KeyMap.MOVE_LEFT):
		_aim(-1)
	elif key.is_action(KeyMap.MOVE_RIGHT):
		_aim(1)
	elif key.is_action(KeyMap.ACCEPT):
		if not key.echo:
			_accept()
	elif key.is_action(KeyMap.CANCEL):
		if not key.echo:
			_back()
	else:
		return
	get_viewport().set_input_as_handled()


## Clicks that no row took: advance a message, aim or go back.
func _unhandled_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	var click := mouse != null and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT
	match _page:
		Page.NONE:
			if click or event.is_action_pressed(KeyMap.ACCEPT):
				_advance_requested = true
		Page.SPELLS, Page.ITEMS:
			# A click on a grey row (it lets clicks through) keeps the list open, so the
			# reason can be read; a click anywhere else goes back.
			if click and not _list.get_global_rect().has_point(mouse.position):
				_back()
		Page.TARGET:
			if not click:
				return
			var index: int = pick_target.call(mouse.position) if pick_target.is_valid() else -1
			if index >= 0 and index == _targets[_target_i]:
				_accept()
			elif index in _targets:
				_aim_at(_targets.find(index))
			else:
				_back()


## Fills the window with the rows of page and puts the cursor on row cursor.
func _open(page: Page, cursor: int) -> void:
	_page = page
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	_rows.clear()
	_back_row = -1
	_cursor = 0
	match page:
		Page.MAIN:
			for text in MAIN_ROWS:
				_add_row(text, true)
			_set_message("¿Qué hará %s?" % _engine.hero.display_name)
		Page.SPELLS:
			for skill in _engine.hero.skills:
				var why := _engine.problem(BattleEngine.cmd_skill(skill))
				_add_row(_with_reason("%s  %d PM" % [skill.display_name, skill.mp_cost], why),
					why == "")
			_add_back_row()
			_set_message("¿Qué hechizo?")
		Page.ITEMS:
			for id in _item_ids():
				var why := _engine.problem(BattleEngine.cmd_item(id))
				_add_row(_with_reason("%s ×%d  %s" % [Inventory.display_name(id),
					_engine.inventory.count(id), Inventory.description(id)], why), why == "")
			if _rows.is_empty():
				_list.add_child(_label("No llevas objetos."))
			_add_back_row()
			_set_message("¿Qué objeto?")
	_message.visible_characters = -1
	_set_cursor(cursor)


## Items in stock that can be used in battle, in Inventory.IDS order.
## Phone: nothing tells the player that a touch off the menu goes back, so a row does.
func _add_back_row() -> void:
	if not Device.is_touch() or _back_row >= 0:
		return
	_back_row = _rows.size()
	_add_row("Volver", true)


func _item_ids() -> Array[String]:
	var ids: Array[String] = []
	for id in Inventory.IDS:
		if _engine.inventory.count(id) > 0 and Inventory.ITEMS[id].battle:
			ids.append(id)
	return ids


func _with_reason(text: String, why: String) -> String:
	return text if why == "" else "%s  (%s)" % [text, why]


func _add_row(text: String, enabled: bool) -> void:
	var button := Button.new()
	button.text = text
	button.flat = true
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	button.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.55))
	var index := _rows.size()
	button.pressed.connect(func() -> void: _press(index))
	button.focus_entered.connect(func() -> void: _on_focus(index))
	_list.add_child(button)
	_set_enabled(button, enabled)
	_rows.append(button)


## Moves the cursor to row i, or to the nearest enabled row after it (wrapping).
func _set_cursor(i: int) -> void:
	if _rows.is_empty():
		return
	for step in _rows.size():
		var row := (maxi(i, 0) + step) % _rows.size()
		if not _rows[row].disabled:
			_quiet_focus = true
			_cursor = row
			_rows[row].grab_focus()
			_quiet_focus = false
			return


func _move(delta: int) -> void:
	if _page == Page.TARGET or _rows.is_empty():
		return
	var row := _cursor
	for step in _rows.size():
		row = (row + delta + _rows.size()) % _rows.size()
		if not _rows[row].disabled:
			_rows[row].grab_focus()
			return


func _on_focus(index: int) -> void:
	_cursor = index
	if not _quiet_focus:
		_sfx(SfxLibrary.CURSOR)


func _accept() -> void:
	if _page == Page.TARGET:
		var cmd := _pending.duplicate()
		cmd.target = _targets[_target_i]
		_choose(cmd)
	elif not _rows.is_empty() and not _rows[_cursor].disabled:
		_press(_cursor)


## What a row does, on its page.
func _press(index: int) -> void:
	if _page == Page.NONE or Time.get_ticks_msec() - _menu_opened_ms < MENU_GUARD * 1000.0:
		return
	if index == _back_row and _page != Page.MAIN:
		_back()
		return
	var first: int = _engine.alive_enemies()[0]
	match _page:
		Page.MAIN:
			_main_cursor = index
			match index:
				0:
					_choose_or_aim(BattleEngine.cmd_attack(first), Page.MAIN)
				1:
					_sfx(SfxLibrary.ACCEPT)
					_open(Page.SPELLS, 0)
				2:
					_sfx(SfxLibrary.ACCEPT)
					_open(Page.ITEMS, 0)
				3:
					_choose(BattleEngine.cmd_defend())
				4:
					_choose(BattleEngine.cmd_flee())
		Page.SPELLS:
			_choose_or_aim(BattleEngine.cmd_skill(_engine.hero.skills[index], first), Page.SPELLS)
		Page.ITEMS:
			_choose(BattleEngine.cmd_item(_item_ids()[index]))


## Chooses cmd, or first asks for its target when there are two enemies to pick from.
func _choose_or_aim(cmd: Dictionary, back: Page) -> void:
	if _needs_target(cmd):
		_sfx(SfxLibrary.ACCEPT)
		_ask_target(cmd, back)
	else:
		_choose(cmd)


func _needs_target(cmd: Dictionary) -> bool:
	if _engine.alive_enemies().size() < 2:
		return false
	return cmd.type == BattleEngine.CMD_ATTACK \
		or (cmd.type == BattleEngine.CMD_SKILL and (cmd.skill as Skill).needs_target())


func _ask_target(cmd: Dictionary, back: Page) -> void:
	_pending = cmd
	_target_back = back
	_target_back_cursor = _cursor
	_targets = _engine.alive_enemies()
	_add_back_row()
	_page = Page.TARGET
	_set_message("¿A quién?")
	_message.visible_characters = -1
	_aim_at(0)


func _aim(delta: int) -> void:
	if _page == Page.TARGET:
		_aim_at((_target_i + delta + _targets.size()) % _targets.size())


func _aim_at(i: int) -> void:
	_target_i = clampi(i, 0, _targets.size() - 1)
	target_changed.emit(_targets[_target_i])
	_sfx(SfxLibrary.CURSOR)


## One step back: target -> its list, list -> main menu.
func _back() -> void:
	match _page:
		Page.TARGET:
			target_changed.emit(-1)
			_sfx(SfxLibrary.CANCEL)
			_open(_target_back, _target_back_cursor)
		Page.SPELLS, Page.ITEMS:
			_sfx(SfxLibrary.CANCEL)
			_open(Page.MAIN, _main_cursor)


func _choose(cmd: Dictionary) -> void:
	if Time.get_ticks_msec() - _menu_opened_ms < MENU_GUARD * 1000.0:
		return
	hide_menu()
	_sfx(SfxLibrary.ACCEPT)
	command_chosen.emit(cmd)


func _build_status() -> void:
	var panel := make_window()
	panel.position = Vector2(EDGE, EDGE)
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 10)
	box.add_child(title_row)
	_name_label = _label()
	title_row.add_child(_name_label)
	_badges = HBoxContainer.new()
	_badges.add_theme_constant_override("separation", 4)
	title_row.add_child(_badges)
	_hp_bar = StatBar.new(StatBar.HP)
	box.add_child(_hp_bar)
	_mp_bar = StatBar.new(StatBar.MP)
	box.add_child(_mp_bar)


func _build_bottom() -> void:
	var row := HBoxContainer.new()
	# No size of its own: it grows up from the bottom edge as its windows need.
	row.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	row.offset_left = EDGE
	row.offset_right = EDGE
	row.offset_top = -EDGE
	row.offset_bottom = -EDGE
	row.grow_vertical = Control.GROW_DIRECTION_BEGIN
	row.add_theme_constant_override("separation", int(GAP))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)

	_menu = make_window()
	_menu.custom_minimum_size = Vector2(MENU_WIDTH, 0)
	_menu.size_flags_vertical = Control.SIZE_SHRINK_END
	row.add_child(_menu)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 0)
	_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu.add_child(_list)

	var message_window := make_window()
	message_window.size_flags_vertical = Control.SIZE_SHRINK_END
	row.add_child(message_window)
	_message = _label()
	# Laid out with the whole text while it types, so the window doesn't grow letter by letter.
	_message.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	message_window.add_child(_message)


## Sets the message and fits its window to it, in the room the command window leaves.
func _set_message(text: String) -> void:
	var menu_width := maxf(_menu.get_combined_minimum_size().x, MENU_WIDTH)
	var room := get_viewport_rect().size.x - EDGE * 2.0 - GAP - menu_width
	fit_label(_message, text, room - WINDOW_MARGIN.x * 2.0)


## A small colored tag with the status name.
func _badge(text: String, color: Color) -> PanelContainer:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(4)
	style.content_margin_left = 6
	style.content_margin_right = 6
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", BADGE_FONT_SIZE)
	label.add_theme_color_override("font_color", Color.WHITE)
	panel.add_child(label)
	return panel


## Disabled rows also leave the focus chain and let mouse clicks through (so a click over
## the hidden menu still advances messages).
func _set_enabled(button: Button, enabled: bool) -> void:
	button.disabled = not enabled
	button.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
	if not enabled:
		button.release_focus()


func _label(text := "") -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", Color.WHITE)
	return label


func _sfx(id: String) -> void:
	if _audio:
		_audio.play_sfx(id)
