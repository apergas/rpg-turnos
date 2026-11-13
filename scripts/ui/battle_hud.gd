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
## Seconds of each half of the cursor's blink when the menu starts taking orders.
const READY_BLINK := 0.08
## Least width of the command window (a longer row widens it).
const MENU_WIDTH := float(UiTokens.WINDOW_W_S)
## On a phone the status window is compact: HP and MP side by side, the creature on one row.
const TOUCH_BAR_WIDTH := 170.0
const TOUCH_ALLY_BAR_WIDTH := 110.0
## With large text everything draws at 1.6, so a row of 48 is as tall on screen as 56 at 1.35.
const TOUCH_LARGE_ROW_HEIGHT := 48.0
## Margin of the windows to the screen edges and gap between them.
const EDGE := float(UiTokens.SPACE_6)
const GAP := float(UiTokens.SPACE_4)
## The thin bar over an enemy: its life left, no number.
const ENEMY_BAR_SIZE := Vector2(UiTokens.ENEMY_BAR_WIDTH, UiTokens.ENEMY_BAR_HEIGHT)
const ENEMY_NAME_GAP := 2.0
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
## Badge text and color token of each status, shown next to the PV.
const BADGES := {
	BattleEngine.POISON: ["Veneno", &"status-poison"],
	BattleEngine.SLEEP: ["Sueño", &"status-sleep"],
	BattleEngine.SILENCE: ["Silencio", &"status-silence"],
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
var _ally_name: Label
var _ally_bar: StatBar
var _menu: PanelContainer
var _list: VBoxContainer
var _message: Label
var _audio: AudioDirector
## The enemies' bars, by enemy index: [background ColorRect, its red fill ColorRect].
var _enemy_bars: Array = []
var _enemy_names: Array[Label] = []
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
## True from show_menu() to the first new key press: until then, repeats of a key held from
## before are ignored, so the cursor never moves on its own.
var _hold_echo := false
## Counts show_menu() calls, so a late "menu ready" from an older turn does nothing.
var _menu_serial := 0
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
	_name_label.text = "%s Nv %d" % [_engine.hero.display_name, level]


func update_hp(hp: int, max_hp: int) -> void:
	_hp_bar.show_hp(hp, max_hp)


func update_mp(mp: int, max_mp: int) -> void:
	_mp_bar.show_mp(mp, max_mp)


## Adds the creature's name and life under the hero's bars.
func show_ally(ally: Combatant) -> void:
	_ally_name.text = ally.display_name
	_ally_name.show()
	_ally_bar.show()
	update_ally_hp(ally.hp, ally.max_hp)


func update_ally_hp(hp: int, max_hp: int) -> void:
	_ally_bar.show_hp(hp, max_hp)


## Adds the bar of the next enemy, full. BattleScene places it every frame (it follows the
## figure on screen) and sets its life as the events play back; enemy_name shows over it
## while it is aimed at (show_target_name()).
func add_enemy_bar(enemy_name := "") -> void:
	var back := ColorRect.new()
	back.color = UiTokens.color(&"surface-track")
	back.size = ENEMY_BAR_SIZE
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(back)
	move_child(back, 0)  # under every window
	var fill := ColorRect.new()
	fill.color = UiTokens.color(&"stat-hp")
	fill.position = Vector2.ONE
	fill.size = ENEMY_BAR_SIZE - Vector2(2, 2)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.add_child(fill)
	_enemy_bars.append([back, fill])
	var label := Label.new()
	label.text = enemy_name
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTheme.style_label(label, &"label", &"text-accent", UiTokens.OUTLINE_S)
	label.hide()
	back.add_child(label)
	_enemy_names.append(label)
	_center_enemy_name(label)


## Renames enemy i (a boss that rises in its next phase under another name).
func set_enemy_name(i: int, enemy_name: String) -> void:
	_enemy_names[i].text = enemy_name
	_center_enemy_name(_enemy_names[i])


## Fits an enemy's name label to its text and centres it over the bar.
func _center_enemy_name(label: Label) -> void:
	label.size = label.get_combined_minimum_size()
	label.position = Vector2((ENEMY_BAR_SIZE.x - label.size.x) / 2.0,
		-label.size.y - ENEMY_NAME_GAP).round()


## Shows the name of enemy index over its bar, and only that one (-1: none).
func show_target_name(index: int) -> void:
	for i in _enemy_names.size():
		_enemy_names[i].visible = i == index


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
## so the message window never resizes. Once MENU_GUARD is over, a sound and a blink of
## the cursor say it takes orders.
func show_menu() -> void:
	_menu_opened_ms = Time.get_ticks_msec()
	_hold_echo = true
	_menu_serial += 1
	_menu.modulate.a = 1.0
	_main_cursor = 0
	_open(Page.MAIN, 0)
	# Real time, like the guard: a faster combat speed scales the engine's time.
	get_tree().create_timer(MENU_GUARD, true, false, true).timeout.connect(
		_on_menu_ready.bind(_menu_serial))


func _on_menu_ready(serial: int) -> void:
	if serial != _menu_serial or _page == Page.NONE or _rows.is_empty():
		return
	_sfx(SfxLibrary.CURSOR)
	var row := _rows[_cursor]
	var blink := row.create_tween()
	blink.set_ignore_time_scale(true)
	for i in 2:
		blink.tween_property(row, "modulate:a", 0.3, READY_BLINK)
		blink.tween_property(row, "modulate:a", 1.0, READY_BLINK)


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


## Shared look of every window: the theme draws the panel (design system window).
static func make_window() -> PanelContainer:
	var panel := PanelContainer.new()
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
	if key.echo and _hold_echo:
		get_viewport().set_input_as_handled()
		return
	if not key.echo:
		_hold_echo = false
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
			for i in MAIN_ROWS.size():
				var why := ""
				if i == MAIN_ROW_OF[BattleEngine.CMD_FLEE]:
					why = _engine.problem(BattleEngine.cmd_flee())
				_add_row(_with_reason(MAIN_ROWS[i], why), why == "")
			_set_message("¿Qué hará %s?" % _engine.hero.display_name)
		Page.SPELLS:
			for skill in _engine.hero.skills:
				var why := _engine.problem(BattleEngine.cmd_skill(skill))
				_add_row(_with_reason("%s  %d PM" % [skill.display_name, skill.mp_cost],
					why), why == "")
			_add_back_row()
			_set_message("¿Qué hechizo?")
		Page.ITEMS:
			for id in _item_ids():
				var why := _engine.problem(BattleEngine.cmd_item(id))
				var text := "%s ×%d" % [Inventory.display_name(id), _engine.inventory.count(id)]
				if why == "":
					text += "  %s" % Inventory.description(id)
				_add_row(_with_reason(text, why), why == "")
			if _rows.is_empty():
				_list.add_child(_label("No llevas objetos."))
			_add_back_row()
			_set_message("¿Qué objeto?")
	_message.visible_characters = -1
	_set_cursor(cursor)


## The row that goes back: nothing else tells the player a click off the menu does.
func _add_back_row() -> void:
	if _back_row >= 0:
		return
	_back_row = _rows.size()
	_add_row("Volver", true)


## Items in stock the battle lists, in Inventory.IDS order: the ones usable in battle and
## the Pluma de fénix (grey: it is used by itself).
func _item_ids() -> Array[String]:
	var ids: Array[String] = []
	for id in Inventory.IDS:
		if _engine.inventory.count(id) > 0 and Inventory.listed_in_battle(id):
			ids.append(id)
	return ids


func _with_reason(text: String, why: String) -> String:
	return text if why == "" else "%s  (%s)" % [text, why]


func _add_row(text: String, enabled: bool) -> void:
	var button := Button.new()
	button.text = text
	UiTheme.menu_row(button)
	if Device.is_touch() and get_window().content_scale_factor >= DisplaySettings.TOUCH_LARGE_SCALE:
		_shrink_row(button)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var index := _rows.size()
	button.pressed.connect(func() -> void: _press(index))
	button.focus_entered.connect(func() -> void: _on_focus(index))
	_list.add_child(button)
	_set_enabled(button, enabled)
	_rows.append(button)


## The phone's button theme pads every button to 56; with large text a row gets 48 instead.
func _shrink_row(button: Button) -> void:
	button.custom_minimum_size.y = TOUCH_LARGE_ROW_HEIGHT
	var theme := ThemeDB.get_default_theme()
	var text_height := theme.get_default_font().get_height(UiTokens.TYPE_BODY_SIZE)
	var pad := maxf(0.0, (TOUCH_LARGE_ROW_HEIGHT - text_height) / 2.0)
	for style_name: String in DisplaySettings.BUTTON_STYLES:
		var box := theme.get_stylebox(style_name, "Button").duplicate() as StyleBox
		box.content_margin_top = pad
		box.content_margin_bottom = pad
		button.add_theme_stylebox_override(style_name, box)


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
	var touch := Device.is_touch()
	if touch:
		# Only the enemies and Volver answer here, so the rest of the menu goes.
		for i in _rows.size():
			_rows[i].visible = i == _back_row
		_set_cursor(_back_row)
	_set_message("¿A quién? Toca al enemigo." if touch else "¿A quién?")
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
	box.add_theme_constant_override("separation", UiTokens.SPACE_1)
	panel.add_child(box)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", UiTokens.SPACE_2)
	box.add_child(title_row)
	_name_label = _label()
	title_row.add_child(_name_label)
	_badges = HBoxContainer.new()
	_badges.add_theme_constant_override("separation", UiTokens.SPACE_1)
	title_row.add_child(_badges)
	var touch := Device.is_touch()
	var width := TOUCH_BAR_WIDTH if touch else StatBar.BAR_SIZE.x
	_hp_bar = StatBar.new(StatBar.HP, width)
	_mp_bar = StatBar.new(StatBar.MP, width)
	var bars: Container = box
	if touch:
		bars = HBoxContainer.new()
		bars.add_theme_constant_override("separation", UiTokens.SPACE_2)
		box.add_child(bars)
	bars.add_child(_hp_bar)
	bars.add_child(_mp_bar)
	var ally_row: Container = box
	if touch:
		ally_row = HBoxContainer.new()
		ally_row.add_theme_constant_override("separation", UiTokens.SPACE_2)
		box.add_child(ally_row)
	_ally_name = _label()
	_ally_name.hide()
	ally_row.add_child(_ally_name)
	_ally_bar = StatBar.new(StatBar.HP, TOUCH_ALLY_BAR_WIDTH if touch else StatBar.BAR_SIZE.x)
	_ally_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL if touch else Control.SIZE_FILL
	_ally_bar.hide()
	ally_row.add_child(_ally_bar)


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
	UiTheme.add_cursor(_menu)

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
	fit_label(_message, text, room - UiTokens.SPACE_4 * 2.0)


## A small colored tag with the status name.
func _badge(text: String, token: StringName) -> PanelContainer:
	var style := UiTheme.badge_style(token)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var label := Label.new()
	label.text = text
	label.theme_type_variation = UiTheme.BADGE
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
	return label


func _sfx(id: String) -> void:
	if _audio:
		_audio.play_sfx(id)
