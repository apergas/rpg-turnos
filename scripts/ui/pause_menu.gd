class_name PauseMenu extends Control
## Pause menu of the world map. Esc or P, or the ☰ button in the top right corner
## (mouse and touch), open it while `available`; it pauses the tree until it closes.
## Pages: main list (Estado, Objetos, Equipo, Guardar, Opciones, Volver al título,
## Cerrar), Estado (hero stats, gold, spells), Objetos (items usable outside battle),
## Equipo (the three slots; choosing one lists the pieces of that slot in the bag, with
## the comparison, and Quitar), Opciones (OptionsPanel) and a confirmation before going
## back to the title. Esc goes back one page. Keeps running while paused. Call setup()
## before adding it to the tree.

signal save_requested
signal title_requested
## The hero, the inventory or the equipment changed, so the map can refresh.
signal state_changed

const FONT_SIZE := 24
const TITLE_COLOR := Color(1.0, 0.85, 0.3)
const MENU_BUTTON_SIZE := Vector2(64, 64)
const MENU_BUTTON_MARGIN := 24.0
## Seconds each page stays open in tour().
const TOUR_STEP := 1.5

## False while a battle, a dialogue or a fade is on: the menu can't open.
var available := false:
	set(value):
		available = value
		if _menu_button:
			_menu_button.visible = value and not is_open()

var _state: GameState
var _options: GameOptions
var _audio: AudioDirector
var _menu_button: Button
var _shade: ColorRect
var _window: PanelContainer
var _pages: Dictionary = {}
var _main_message: Label
var _status_label: Label
var _items_box: VBoxContainer
var _items_message: Label
var _equip_box: VBoxContainer
var _equip_message: Label
## Slot whose pieces the Equipo page lists ("" for the list of the three slots).
var _equip_slot := ""
var _options_panel: OptionsPanel
var _page := ""
## True while the code moves the focus itself, so that move makes no sound.
var _quiet_focus := false


func setup(state: GameState, options: GameOptions, audio: AudioDirector) -> void:
	_state = state
	_options = options
	_audio = audio


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_menu_button()
	_shade = ColorRect.new()
	_shade.color = Color(0, 0, 0, 0.5)
	_shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shade.hide()
	add_child(_shade)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_window = BattleHud.make_window()
	_window.custom_minimum_size = Vector2(520, 0)
	_window.hide()
	center.add_child(_window)
	var stack := VBoxContainer.new()
	_window.add_child(stack)
	_build_main(stack)
	_build_status(stack)
	_build_items(stack)
	_build_equipment(stack)
	_build_options(stack)
	_build_confirm(stack)
	available = available


func is_open() -> bool:
	return _page != ""


func open() -> void:
	if is_open() or not available:
		return
	get_tree().paused = true
	_shade.show()
	_window.show()
	_menu_button.hide()
	_main_message.text = ""
	_sfx(SfxLibrary.ACCEPT)
	_show_page("main")


func close() -> void:
	if not is_open():
		return
	_page = ""
	_shade.hide()
	_window.hide()
	_sfx(SfxLibrary.CANCEL)
	get_tree().paused = false
	available = available


## Game calls it after save_requested with whether the file was written.
func show_save_result(ok: bool) -> void:
	_main_message.text = "Partida guardada." if ok else "No se pudo guardar."
	_sfx(SfxLibrary.SAVE if ok else SfxLibrary.CANCEL)


## Shows the ☰ button for TOUR_STEP seconds, then opens the menu (even if not
## available), shows every page for TOUR_STEP seconds and closes it. Used by
## `--autoplay-menu` to record frames of the menu; prints each page.
func tour() -> void:
	var was_available := available
	available = true
	await get_tree().create_timer(TOUR_STEP, true).timeout
	open()
	for page in ["main", "status", "items", "equipment", "options"]:
		_show_page(page)
		print("Menú: %s" % page)
		await get_tree().create_timer(TOUR_STEP, true).timeout
	close()
	available = was_available


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.physical_keycode != KEY_ESCAPE and key.physical_keycode != KEY_P:
		return
	if not is_open():
		if available:
			get_viewport().set_input_as_handled()
			open()
		return
	get_viewport().set_input_as_handled()
	match _page:
		"main":
			close()
		"options":
			_options_panel.back()
		"equipment":
			if _equip_slot != "":
				_sfx(SfxLibrary.CANCEL)
				_choose_slot("")
			else:
				_back_to_main()
		_:
			_back_to_main()


func _show_page(page: String) -> void:
	_page = page
	for name: String in _pages:
		(_pages[name] as Control).visible = name == page
	match page:
		"status":
			_status_label.text = _status_text()
		"items":
			_items_message.text = ""
			_fill_items()
		"equipment":
			_equip_slot = ""
			_equip_message.text = ""
			_fill_equipment()
	_quiet_focus = true
	if page == "options":
		_options_panel.focus_first()
	else:
		var first := _first_button(_pages[page])
		if first:
			first.grab_focus()
	_quiet_focus = false


func _back_to_main() -> void:
	_sfx(SfxLibrary.CANCEL)
	_show_page("main")


func _status_text() -> String:
	var hero := _state.hero
	var lines := PackedStringArray([
		"%s  Nivel %d" % [hero.display_name, hero.level],
		"PV %d / %d" % [hero.hp, hero.max_hp],
		"PM %d / %d" % [hero.mp, hero.max_mp],
		"ATK %d   DEF %d   VEL %d" % [hero.total_attack(), hero.total_defense(), hero.speed],
		"EXP %d" % hero.experience,
	])
	var next := Leveling.exp_for_next(hero.level)
	if next < 0:
		lines.append("Nivel máximo")
	else:
		lines.append("Siguiente nivel: faltan %d EXP" % (next - hero.experience))
	lines.append("Oro %d G" % _state.gold)
	var spells := PackedStringArray()
	for skill in hero.skills:
		spells.append(skill.display_name)
	lines.append("Hechizos: %s" % ", ".join(spells))
	return "\n".join(lines)


## One row per item carried: name, count and "Usar" (disabled, with the reason, when it
## can't be used now).
func _fill_items() -> void:
	# Removed at once (the pressed "Usar" may be one of them) and freed at the end of the frame.
	for child in _items_box.get_children():
		_items_box.remove_child(child)
		child.queue_free()
	var inventory := _state.inventory
	var any := false
	for id in Inventory.IDS:
		if inventory.count(id) <= 0:
			continue
		any = true
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		_items_box.add_child(row)
		var label := _label("%s ×%d" % [Inventory.display_name(id), inventory.count(id)],
			Color.WHITE)
		label.custom_minimum_size = Vector2(220, 0)
		row.add_child(label)
		var use := _button("Usar")
		var why := inventory.problem(id, _state.hero, false)
		use.disabled = why != ""
		use.pressed.connect(_on_use_item.bind(id))
		row.add_child(use)
		if why != "":
			row.add_child(_label(why, Color(0.6, 0.6, 0.65)))
	if not any:
		_items_box.add_child(_label("No llevas objetos.", Color.WHITE))


func _on_use_item(id: String) -> void:
	var result := _state.use_item(id)
	if not result.used:
		return
	_sfx(SfxLibrary.HEAL)
	_fill_items()
	_items_message.text = ("Recuperas %d PM." if result.effect == "mp" else "Recuperas %d PV.") \
			% result.amount
	state_changed.emit()
	_quiet_focus = true
	var first := _first_button(_pages["items"])
	if first:
		first.grab_focus()
	_quiet_focus = false


## The three slots with what is worn ("Arma: Palo  ATK +2") and the totals; with a slot
## chosen, the pieces of that slot in the bag (bonus and comparison), Quitar and Volver.
func _fill_equipment() -> void:
	for child in _equip_box.get_children():
		_equip_box.remove_child(child)
		child.queue_free()
	var hero := _state.hero
	var loadout := _state.loadout
	if _equip_slot == "":
		for slot in Equipment.SLOTS:
			var worn := loadout.worn(slot)
			var text := "%s: %s" % [Equipment.SLOT_NAMES[slot], "nada" if worn == "" \
				else "%s  %s +%d" % [Equipment.display_name(worn), Equipment.stat_name(worn),
				Equipment.bonus(worn)]]
			var button := _button(text)
			button.pressed.connect(_choose_slot.bind(slot))
			_equip_box.add_child(button)
		_equip_box.add_child(_label("ATK %d   DEF %d" % [hero.total_attack(),
			hero.total_defense()], Color.WHITE))
		_focus_first_in(_equip_box)
		return
	_equip_box.add_child(_label("%s:" % Equipment.SLOT_NAMES[_equip_slot], TITLE_COLOR))
	var listed: Array[String] = []
	for id in _state.bag_equipment:
		if Equipment.slot(id) != _equip_slot or listed.has(id):
			continue
		listed.append(id)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		_equip_box.add_child(row)
		var button := _button(Equipment.display_name(id))
		button.custom_minimum_size = Vector2(260, 0)
		button.pressed.connect(_on_equip.bind(id))
		row.add_child(button)
		row.add_child(_label("%s +%d" % [Equipment.stat_name(id), Equipment.bonus(id)],
			Color.WHITE))
		row.add_child(ShopWindow.comparison(
			Equipment.bonus(id) - Equipment.bonus(loadout.worn(_equip_slot))))
	if listed.is_empty():
		_equip_box.add_child(_label("No llevas otra pieza.", Color.WHITE))
	if loadout.worn(_equip_slot) != "":
		var remove := _button("Quitar")
		remove.pressed.connect(_on_unequip)
		_equip_box.add_child(remove)
	var back := _button("Volver")
	back.pressed.connect(func() -> void:
		_sfx(SfxLibrary.CANCEL)
		_choose_slot(""))
	_equip_box.add_child(back)
	_focus_first_in(_equip_box)


func _choose_slot(slot: String) -> void:
	if slot != "":
		_sfx(SfxLibrary.ACCEPT)
	_equip_slot = slot
	_equip_message.text = ""
	_fill_equipment()


func _on_equip(id: String) -> void:
	if not _state.equip(id):
		return
	_sfx(SfxLibrary.ACCEPT)
	_equip_slot = ""
	_fill_equipment()
	_equip_message.text = "Te equipas %s %s." % [Equipment.article(id),
		Equipment.display_name(id)]
	state_changed.emit()


func _on_unequip() -> void:
	var worn := _state.loadout.worn(_equip_slot)
	_state.unequip(_equip_slot)
	_sfx(SfxLibrary.CANCEL)
	_equip_slot = ""
	_fill_equipment()
	_equip_message.text = "Te quitas %s %s." % [Equipment.article(worn),
		Equipment.display_name(worn)]
	state_changed.emit()


func _focus_first_in(node: Node) -> void:
	_quiet_focus = true
	var first := _first_button(node)
	if first:
		first.grab_focus()
	_quiet_focus = false


func _build_menu_button() -> void:
	_menu_button = Button.new()
	_menu_button.custom_minimum_size = MENU_BUTTON_SIZE
	_menu_button.focus_mode = Control.FOCUS_NONE
	_menu_button.add_theme_stylebox_override("normal", _menu_button_style(0.75))
	_menu_button.add_theme_stylebox_override("hover", _menu_button_style(0.9))
	_menu_button.add_theme_stylebox_override("pressed", _menu_button_style(1.0))
	add_child(_menu_button)
	_menu_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_menu_button.offset_left = -MENU_BUTTON_MARGIN - MENU_BUTTON_SIZE.x
	_menu_button.offset_right = -MENU_BUTTON_MARGIN
	_menu_button.offset_top = MENU_BUTTON_MARGIN
	_menu_button.offset_bottom = MENU_BUTTON_MARGIN + MENU_BUTTON_SIZE.y
	_menu_button.pressed.connect(open)
	# The ☰ icon as three white bars (the default font has no ☰ glyph on the web).
	for i in 3:
		var bar := ColorRect.new()
		bar.color = Color.WHITE
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.position = Vector2(16, 18 + i * 12)
		bar.size = Vector2(32, 5)
		_menu_button.add_child(bar)
	_menu_button.hide()


func _menu_button_style(alpha: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.12, alpha)
	style.border_color = Color.WHITE
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	return style


func _build_main(stack: VBoxContainer) -> void:
	var page := _page_box(stack, "main", "Menú")
	var entries := [
		["Estado", func() -> void: _open_page("status")],
		["Objetos", func() -> void: _open_page("items")],
		["Equipo", func() -> void: _open_page("equipment")],
		["Guardar", func() -> void: save_requested.emit()],
		["Opciones", func() -> void: _open_page("options")],
		["Volver al título", func() -> void: _open_page("confirm")],
		["Cerrar", close],
	]
	for entry: Array in entries:
		var button := _button(entry[0])
		button.pressed.connect(entry[1])
		page.add_child(button)
	_main_message = _label("", Color.WHITE)
	page.add_child(_main_message)


func _build_status(stack: VBoxContainer) -> void:
	var page := _page_box(stack, "status", "Estado")
	_status_label = _label("", Color.WHITE)
	page.add_child(_status_label)
	page.add_child(_back_button())


func _build_items(stack: VBoxContainer) -> void:
	var page := _page_box(stack, "items", "Objetos")
	_items_box = VBoxContainer.new()
	page.add_child(_items_box)
	_items_message = _label("", Color.WHITE)
	page.add_child(_items_message)
	page.add_child(_back_button())


func _build_equipment(stack: VBoxContainer) -> void:
	var page := _page_box(stack, "equipment", "Equipo")
	_equip_box = VBoxContainer.new()
	page.add_child(_equip_box)
	_equip_message = _label("", Color.WHITE)
	page.add_child(_equip_message)
	page.add_child(_back_button())


func _build_options(stack: VBoxContainer) -> void:
	_options_panel = OptionsPanel.new()
	_options_panel.setup(_options, _audio)
	_options_panel.closed.connect(func() -> void: _show_page("main"))
	stack.add_child(_options_panel)
	_pages["options"] = _options_panel


func _build_confirm(stack: VBoxContainer) -> void:
	var page := _page_box(stack, "confirm", "Volver al título")
	page.add_child(_label("Lo que no esté guardado se perderá.", Color.WHITE))
	var yes := _button("Sí, volver")
	yes.pressed.connect(func() -> void: title_requested.emit())
	page.add_child(yes)
	var no := _button("No")
	no.pressed.connect(_back_to_main)
	page.add_child(no)


func _open_page(page: String) -> void:
	_sfx(SfxLibrary.ACCEPT)
	_show_page(page)


## A page: a VBox with its title, registered under name and hidden.
func _page_box(stack: VBoxContainer, page_name: String, title: String) -> VBoxContainer:
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 8)
	page.hide()
	stack.add_child(page)
	page.add_child(_label(title, TITLE_COLOR))
	_pages[page_name] = page
	return page


func _back_button() -> Button:
	var button := _button("Volver")
	button.pressed.connect(_back_to_main)
	return button


func _first_button(node: Node) -> Button:
	for child in node.get_children():
		if child is Button and not (child as Button).disabled:
			return child
		var inner := _first_button(child)
		if inner:
			return inner
	return null


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.flat = true
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	button.focus_entered.connect(func() -> void:
		if not _quiet_focus:
			_sfx(SfxLibrary.CURSOR))
	return button


func _label(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", color)
	return label


func _sfx(id: String) -> void:
	if _audio:
		_audio.play_sfx(id)
