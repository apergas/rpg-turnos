class_name BattleHud extends Control
## Dragon Quest style battle UI: hero status (top left), command menu and message
## window (bottom). The menu lists "Atacar", the hero's first skill and the potion;
## the last two are disabled without enough MP or potions. Up / down move between
## commands, Enter / Space or a click choose one. show_message() can be awaited: it
## types the text out and returns when the player advances (click, Enter, Space) or
## after a short auto-advance.

signal command_chosen(cmd: Dictionary)

const CHAR_TIME := 0.025
const AUTO_ADVANCE := 0.6
const FONT_SIZE := 24

var _name_label: Label
var _hp_label: Label
var _hp_bar: ProgressBar
var _mp_label: Label
var _menu: PanelContainer
var _attack_button: Button
var _skill_button: Button
var _item_button: Button
var _message: Label
var _hero: Combatant
var _potions := 0
var _hp_fill := StyleBoxFlat.new()
var _menu_active := false
var _advance_requested := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_status()
	_build_bottom()
	hide_menu()


func set_hero(c: Combatant, potions: int) -> void:
	_hero = c
	_potions = potions
	update_level(c.level)
	update_hp(c.hp, c.max_hp)
	update_mp(c.mp, c.max_mp)


func update_level(level: int) -> void:
	_name_label.text = "%s  Nv %d" % [_hero.display_name, level]


func update_hp(hp: int, max_hp: int) -> void:
	_hp_label.text = "PV %d / %d" % [hp, max_hp]
	_hp_bar.max_value = max_hp
	_hp_bar.value = hp
	var ratio := float(hp) / maxf(1.0, max_hp)
	if ratio <= 0.25:
		_hp_fill.bg_color = Color(0.85, 0.15, 0.15)
	elif ratio <= 0.5:
		_hp_fill.bg_color = Color(0.9, 0.8, 0.15)
	else:
		_hp_fill.bg_color = Color(0.2, 0.75, 0.25)


func update_mp(mp: int, max_mp: int) -> void:
	_mp_label.text = "PM %d / %d" % [mp, max_mp]


func set_potions(n: int) -> void:
	_potions = n


## The menu keeps its layout slot (only fades out) so the message window never resizes.
func show_menu() -> void:
	_menu_active = true
	_menu.modulate.a = 1.0
	_set_enabled(_attack_button, true)
	var skill := _skill()
	_skill_button.visible = skill != null
	if skill != null:
		_skill_button.text = "%s (%d PM)" % [skill.display_name, skill.mp_cost]
		_set_enabled(_skill_button, _hero.mp >= skill.mp_cost)
	_item_button.text = "%s ×%d" % [Inventory.display_name(Inventory.POTION), _potions]
	_set_enabled(_item_button, _potions > 0)
	_message.text = "¿Qué hará %s?" % _hero.display_name
	_message.visible_characters = -1
	_attack_button.grab_focus()


func hide_menu() -> void:
	_menu_active = false
	_menu.modulate.a = 0.0
	for button in [_attack_button, _skill_button, _item_button]:
		_set_enabled(button, false)


func show_message(text: String) -> void:
	_message.text = text
	_message.visible_characters = 0
	_advance_requested = false
	var total := _message.get_total_character_count()
	var shown := 0.0
	while _message.visible_characters < total and not _advance_requested:
		await get_tree().process_frame
		shown += get_process_delta_time() / CHAR_TIME
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
	style.set_content_margin_all(16)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel


## While the menu is open the focused button handles Enter / Space itself.
func _unhandled_input(event: InputEvent) -> void:
	if _menu_active:
		return
	var mouse := event as InputEventMouseButton
	var click := mouse != null and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT
	if click or event.is_action_pressed("ui_accept"):
		_advance_requested = true


func _build_status() -> void:
	var panel := make_window()
	panel.position = Vector2(24, 24)
	panel.custom_minimum_size = Vector2(240, 0)
	add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	_name_label = _label()
	box.add_child(_name_label)
	_hp_label = _label()
	box.add_child(_hp_label)
	_hp_bar = ProgressBar.new()
	_hp_bar.show_percentage = false
	_hp_bar.custom_minimum_size = Vector2(0, 10)
	_hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hp_bar.add_theme_stylebox_override("fill", _hp_fill)
	box.add_child(_hp_bar)
	_mp_label = _label()
	box.add_child(_mp_label)


func _build_bottom() -> void:
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	row.offset_left = 24
	row.offset_right = -24
	row.offset_top = -200
	row.offset_bottom = -24
	row.add_theme_constant_override("separation", 16)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)

	_menu = make_window()
	_menu.custom_minimum_size = Vector2(220, 0)
	row.add_child(_menu)
	var commands := VBoxContainer.new()
	commands.add_theme_constant_override("separation", 0)
	_menu.add_child(commands)
	_attack_button = _command_button("Atacar")
	_attack_button.pressed.connect(func() -> void: _choose(BattleEngine.cmd_attack()))
	commands.add_child(_attack_button)
	_skill_button = _command_button("")
	_skill_button.pressed.connect(func() -> void: _choose(BattleEngine.cmd_skill(_skill())))
	commands.add_child(_skill_button)
	_item_button = _command_button("")
	_item_button.pressed.connect(func() -> void: _choose(BattleEngine.cmd_item(Inventory.POTION)))
	commands.add_child(_item_button)

	var message_window := make_window()
	message_window.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(message_window)
	_message = _label()
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	message_window.add_child(_message)


func _command_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.flat = true
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	return button


## Disabled buttons also leave the focus chain (so up / down skip them) and let mouse
## clicks through (so a click over the hidden menu still advances messages).
func _set_enabled(button: Button, enabled: bool) -> void:
	button.disabled = not enabled
	button.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
	if not enabled:
		button.release_focus()


func _skill() -> Skill:
	if _hero == null or _hero.skills.is_empty():
		return null
	return _hero.skills[0]


func _label() -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", Color.WHITE)
	return label


func _choose(cmd: Dictionary) -> void:
	if not _menu_active:
		return
	hide_menu()
	command_chosen.emit(cmd)
