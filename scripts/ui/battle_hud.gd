class_name BattleHud extends Control
## Dragon Quest style battle UI: hero status (top left), command menu and message
## window (bottom). show_message() can be awaited: it types the text out and returns
## when the player advances (click, Enter, Space) or after a short auto-advance.

signal command_chosen(cmd: String)

const CHAR_TIME := 0.025
const AUTO_ADVANCE := 0.6
const FONT_SIZE := 24

var _name_label: Label
var _hp_label: Label
var _hp_bar: ProgressBar
var _menu: PanelContainer
var _attack_button: Button
var _message: Label
var _hero_name := ""
var _hp_fill := StyleBoxFlat.new()
var _menu_active := false
var _advance_requested := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_status()
	_build_bottom()
	hide_menu()


func set_hero(c: Combatant) -> void:
	_hero_name = c.display_name
	_name_label.text = c.display_name
	update_hp(c.hp, c.max_hp)


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


## The menu keeps its layout slot (only fades out) so the message window never resizes.
func show_menu() -> void:
	_menu_active = true
	_menu.modulate.a = 1.0
	_attack_button.disabled = false
	_message.text = "¿Qué hará %s?" % _hero_name
	_message.visible_characters = -1
	_attack_button.grab_focus()


func hide_menu() -> void:
	_menu_active = false
	_menu.modulate.a = 0.0
	_attack_button.release_focus()
	_attack_button.disabled = true


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


func _unhandled_input(event: InputEvent) -> void:
	if _menu_active and event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_on_attack_pressed()
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


func _build_bottom() -> void:
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	row.offset_left = 24
	row.offset_right = -24
	row.offset_top = -170
	row.offset_bottom = -24
	row.add_theme_constant_override("separation", 16)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)

	_menu = make_window()
	_menu.custom_minimum_size = Vector2(200, 0)
	row.add_child(_menu)
	var commands := VBoxContainer.new()
	_menu.add_child(commands)
	_attack_button = Button.new()
	_attack_button.text = "Atacar"
	_attack_button.flat = true
	_attack_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_attack_button.add_theme_font_size_override("font_size", FONT_SIZE)
	_attack_button.pressed.connect(_on_attack_pressed)
	commands.add_child(_attack_button)

	var message_window := make_window()
	message_window.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(message_window)
	_message = _label()
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	message_window.add_child(_message)


func _label() -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", Color.WHITE)
	return label


func _on_attack_pressed() -> void:
	hide_menu()
	command_chosen.emit(BattleEngine.CMD_ATTACK)
