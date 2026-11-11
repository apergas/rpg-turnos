class_name PauseMenu extends Control
## Pause menu of the world map. Esc or P, or the ☰ button in the top right corner
## (mouse and touch), open it while `available`; it pauses the tree until it closes.
## Main page: two windows side by side. The hero's ("Héroe Nv X", the pages of
## HERO_PAGES and the missions under way) and the system's (Guardar, Opciones, Volver al
## título, Cerrar). Other pages: Estado (hero stats, gold, spells), Objetos (items usable
## outside battle, the Ala de viaje too, and the key items, each with what it does, and the
## small medals, "Medalla pequeña ×n"),
## Equipo (the six slots; choosing one lists the pieces of that slot in the bag, with
## the comparison, and Quitar), Diario (JournalPage: what to do now, the missions in progress
## and the finished ones), Opciones (OptionsPanel) and a confirmation before going
## back to the title. Esc goes back one page. Keeps running while paused. Call setup()
## before adding it to the tree.

signal save_requested
signal title_requested
## The hero, the inventory or the equipment changed, so the map can refresh.
signal state_changed
## An Ala de viaje was used (the menu closes): Game takes the hero to the last village and
## leaves the portal back.
signal travel_requested
## The menu opened or closed: the map hides its status window behind it.
signal open_changed(is_open: bool)

const FONT_SIZE := 24
const TITLE_COLOR := UiStyle.TITLE_COLOR
const GREY := UiStyle.GREY
## Rows of the hero's window: text and page. A new page only needs its row here.
const HERO_PAGES := [["Estado", "status"], ["Hechizos", "spells"], ["Objetos", "items"], ["Equipo", "equipment"],
	["Mapa", "map"], ["Diario", "journal"], ["Bestiario", "bestiary"]]
## The Mapa page: the side of its map, and what its title, Volver and the margins leave
## out of the screen's height.
## Side of the portrait on a bestiary card's page (the PNGs are 128 px).
const ENTRY_PICTURE := 128.0
const MAP_PAGE_SIDE := 360.0
const MAP_PAGE_RESERVED := 150.0
const MAP_LEGEND_SWATCH := 12.0
## On a phone the hero's rows go in this many columns: one per row doesn't fit the height.
const TOUCH_HERO_COLUMNS := 3
## Long texts wrap past this width.
const TEXT_WIDTH := 480.0
const MISSION_WIDTH := 420.0
const MESSAGE_WIDTH := 240.0
## What the title, the message, Volver and the margins leave out of a page's scrolling list.
const LIST_RESERVED := 245.0
const STATUS_BAR_WIDTH := 300.0
const MENU_BUTTON_SIZE := Vector2(64, 64)
const MENU_BUTTON_MARGIN := 24.0
## Seconds each page stays open in tour().
const TOUR_STEP := 1.5

## Says whether the hero is inside a village now (an Ala can't be used there). Set by
## Game.
var in_village: Callable

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
var _main_row: HBoxContainer
var _hero_label: Label
var _mission_box: VBoxContainer
var _main_message: Label
var _hp_bar: StatBar
var _mp_bar: StatBar
var _exp_bar: StatBar
var _stats_label: Label
var _gold_label: Label
## Estado's right column: each spell, its MP and what it does.
var _spells_box: VBoxContainer
var _ally_label: Label
var _items_box: VBoxContainer
var _items_message: Label
var _equip_box: VBoxContainer
## ATK / DEF / VEL under the list of slots, outside the part that scrolls.
var _equip_stats: Label
var _equip_message: Label
## Slot whose pieces the Equipo page lists ("" for the list of the three slots).
var _equip_slot := ""
var _journal: JournalPage
var _bestiary: BestiaryPage
var _bestiary_button: Button
var _entry_picture: TextureRect
var _entry_name: Label
var _entry_lines: VBoxContainer
var _entry_id := ""
var _spell_hp: StatBar
var _spell_mp: StatBar
var _cast_box: VBoxContainer
var _spells_message: Label
## Where the hero stands on the map now. Set by Game.
var hero_position: Callable
var _map_title: Label
var _map_holder: HBoxContainer
## The menu was opened on the Mapa page (a tap on the map square): Volver closes it.
var _map_only := false
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
	_shade.gui_input.connect(func(event: InputEvent) -> void:
		if UiStyle.is_outside_tap(event):
			_go_back())
	add_child(_shade)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_window = BattleHud.make_window()
	_window.hide()
	center.add_child(_window)
	var stack := VBoxContainer.new()
	_window.add_child(stack)
	_build_main(center)
	_build_status(stack)
	_build_spells(stack)
	_build_items(stack)
	_build_equipment(stack)
	_build_map(stack)
	_build_journal(stack)
	_build_bestiary(stack)
	_build_bestiary_entry(stack)
	_build_options(stack)
	_build_confirm(stack)
	available = available


func is_open() -> bool:
	return _page != ""


func open() -> void:
	if is_open() or not available:
		return
	_map_only = false
	get_tree().paused = true
	_shade.show()
	_menu_button.hide()
	_set_line(_main_message, "")
	_sfx(SfxLibrary.ACCEPT)
	_show_page("main")
	open_changed.emit(true)


## Opens the menu straight on its Mapa page (a tap on the map square); Volver closes it.
func open_map() -> void:
	if is_open() or not available:
		return
	open()
	_map_only = true
	_show_page("map")


func close() -> void:
	if not is_open():
		return
	_page = ""
	_shade.hide()
	_window.hide()
	_main_row.hide()
	_sfx(SfxLibrary.CANCEL)
	get_tree().paused = false
	available = available
	open_changed.emit(false)


## Game calls it after save_requested with whether the file was written.
func show_save_result(ok: bool) -> void:
	_set_line(_main_message, "Partida guardada." if ok else "No se pudo guardar.")
	_sfx(SfxLibrary.SAVE if ok else SfxLibrary.CANCEL)


## Shows the ☰ button for TOUR_STEP seconds, then opens the menu (even if not
## available), shows every page for TOUR_STEP seconds and closes it. Used by
## `--autoplay-menu` to record frames of the menu; prints each page.
func tour() -> void:
	var was_available := available
	available = true
	await get_tree().create_timer(TOUR_STEP, true).timeout
	open()
	for page in ["main", "status", "spells", "items", "equipment", "map", "journal", "bestiary", "options"]:
		_show_page(page)
		print("Menú: %s" % page)
		await get_tree().create_timer(TOUR_STEP, true).timeout
	close()
	available = was_available


func _unhandled_input(event: InputEvent) -> void:
	if not is_open():
		if available and event.is_action_pressed(KeyMap.PAUSE):
			get_viewport().set_input_as_handled()
			open()
		return
	if not (event.is_action_pressed(KeyMap.PAUSE) or event.is_action_pressed(KeyMap.CANCEL)):
		return
	get_viewport().set_input_as_handled()
	_go_back()


## What Esc, Q or a tap outside the windows does on the current page.
func _go_back() -> void:
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
		"bestiary_entry":
			_back_to_bestiary()
		"map":
			if _map_only:
				close()
			else:
				_back_to_main()
		_:
			_back_to_main()


func _show_page(page: String) -> void:
	_page = page
	for name: String in _pages:
		(_pages[name] as Control).visible = name == page
	_window.visible = page != "main"
	match page:
		"main":
			_fill_main()
		"status":
			_fill_status()
		"spells":
			_set_line(_spells_message, "")
			_fill_spells()
		"items":
			_set_line(_items_message, "")
			_fill_items()
		"equipment":
			_equip_slot = ""
			_set_line(_equip_message, "")
			_fill_equipment()
		"map":
			_fill_map()
		"journal":
			_journal.fill(_state)
		"bestiary":
			_bestiary.fill(_state)
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


## The hero's name and level and the missions under way (they can change between visits).
func _fill_main() -> void:
	_hero_label.text = StatBar.hero_title(_state.hero)
	_bestiary_button.text = BestiaryPage.count_text(_state)
	for child in _mission_box.get_children():
		_mission_box.remove_child(child)
		child.queue_free()
	for line in _state.current_missions():
		var label := _label("", Color.WHITE)
		_mission_box.add_child(label)
		BattleHud.fit_label(label, line, MISSION_WIDTH)


func _fill_status() -> void:
	var hero := _state.hero
	_hp_bar.show_hp(hero.hp, hero.max_hp)
	_mp_bar.show_mp(hero.mp, hero.max_mp)
	_exp_bar.show_exp(hero)
	_stats_label.text = "ATK %d   DEF %d   VEL %d" % [hero.total_attack(),
		hero.total_defense(), hero.total_speed()]
	_gold_label.text = "%d G" % _state.gold
	for child in _spells_box.get_children():
		_spells_box.remove_child(child)
		child.queue_free()
	_spells_box.add_child(_label("Hechizos", TITLE_COLOR))
	for skill in hero.skills:
		_spells_box.add_child(_label("%s  %d PM" % [skill.display_name, skill.mp_cost],
			Color.WHITE))
		UiStyle.add_small_text(_spells_box, skill.description)
	_ally_label.visible = _state.ally_id != ""
	if _state.ally_id != "":
		BattleHud.fit_label(_ally_label, "Criatura: %s" % Allies.display_name(_state.ally_id),
			TEXT_WIDTH)


## The message lines always keep their place, so a message never moves the buttons.
func _set_line(label: Label, text: String) -> void:
	label.text = text


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
		label.custom_minimum_size = Vector2(260, 0)
		row.add_child(label)
		var use := _button("Usar")
		var why := _use_problem(id)
		use.disabled = why != ""
		use.pressed.connect(_on_use_item.bind(id))
		row.add_child(use)
		if why != "":
			row.add_child(_label(why, GREY))
		UiStyle.add_description(_items_box, id)
	for id in _state.key_items:
		any = true
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		_items_box.add_child(row)
		var label := _label(Inventory.KEY_ITEMS[id], TITLE_COLOR)
		label.custom_minimum_size = Vector2(260, 0)
		row.add_child(label)
		row.add_child(_label("Objeto clave", GREY))
		UiStyle.add_description(_items_box, id)
	if not _state.medals.is_empty():
		# The small medals: counted, never used (the Coleccionista only counts them).
		any = true
		var medal_row := HBoxContainer.new()
		medal_row.add_theme_constant_override("separation", 16)
		_items_box.add_child(medal_row)
		var medal_label := _label("%s ×%d" % [Inventory.MEDAL_NAME, _state.medals.size()],
			TITLE_COLOR)
		medal_label.custom_minimum_size = Vector2(260, 0)
		medal_row.add_child(medal_label)
		medal_row.add_child(_label("Objeto clave", GREY))
		UiStyle.add_description(_items_box, Inventory.MEDAL)
	if not any:
		_items_box.add_child(_label("No llevas objetos.", Color.WHITE))


## Why an item can't be used from the menu now ("" if it can).
func _use_problem(id: String) -> String:
	if id == Inventory.WING and in_village.is_valid() and in_village.call():
		return Inventory.IN_TOWN
	return _state.inventory.problem(id, _state.hero, false)


func _on_use_item(id: String) -> void:
	var result := _state.use_item(id)
	if not result.used:
		return
	if result.effect == "travel":
		close()
		travel_requested.emit()
		return
	_sfx(SfxLibrary.HEAL)
	_fill_items()
	_set_line(_items_message, _use_text(id, result))
	state_changed.emit()
	_quiet_focus = true
	var first := _first_button(_pages["items"])
	if first:
		first.grab_focus()
	_quiet_focus = false


## What the menu says after using an item (Inventory.use()'s result).
func _use_text(id: String, result: Dictionary) -> String:
	match result.effect:
		"mp":
			return "Recuperas %d PM." % result.amount
		"seed":
			return "¡%s +%d para siempre!" % [Inventory.seed_stat(id), result.amount]
		"repel":
			return "Los monstruos no te atacan durante %d m." % Inventory.ITEMS[id].value
	return "Recuperas %d PV." % result.amount


## The six slots with what is worn ("Arma: Palo  ATK +2") and the totals; with a slot
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
				else "%s  %s" % [Equipment.display_name(worn), Equipment.effect_text(worn)]]
			var button := _button(text)
			button.pressed.connect(_choose_slot.bind(slot))
			_equip_box.add_child(button)
		_equip_stats.text = "ATK %d   DEF %d   VEL %d" % [hero.total_attack(),
			hero.total_defense(), hero.total_speed()]
		_equip_stats.show()
		_focus_first_in(_equip_box)
		return
	_equip_stats.hide()
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
		button.custom_minimum_size.x = 260.0
		button.pressed.connect(_on_equip.bind(id))
		row.add_child(button)
		row.add_child(_label(Equipment.effect_text(id), Color.WHITE))
		if not _equip_slot in Equipment.ACCESSORY_SLOTS:
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
	_set_line(_equip_message, "")
	_fill_equipment()


func _on_equip(id: String) -> void:
	if not _state.equip(id):
		return
	_sfx(SfxLibrary.ACCEPT)
	_equip_slot = ""
	_fill_equipment()
	_set_line(_equip_message, "Te equipas %s %s." % [Equipment.article(id),
		Equipment.display_name(id)])
	state_changed.emit()


func _on_unequip() -> void:
	var worn := _state.loadout.worn(_equip_slot)
	_state.unequip(_equip_slot)
	_sfx(SfxLibrary.CANCEL)
	_equip_slot = ""
	_fill_equipment()
	_set_line(_equip_message, "Te quitas %s %s." % [Equipment.article(worn),
		Equipment.display_name(worn)])
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


## The main page: the hero's window on the left, the system's on the right.
func _build_main(center: CenterContainer) -> void:
	_main_row = HBoxContainer.new()
	_main_row.add_theme_constant_override("separation", 16)
	_main_row.hide()
	center.add_child(_main_row)
	_pages["main"] = _main_row
	var hero_box := _main_window()
	_hero_label = _label("", TITLE_COLOR)
	hero_box.add_child(_hero_label)
	var rows: Container = hero_box
	if Device.is_touch():
		var grid := GridContainer.new()
		grid.columns = TOUCH_HERO_COLUMNS
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 6)
		hero_box.add_child(grid)
		rows = grid
	for entry: Array in HERO_PAGES:
		var button := _button(entry[0])
		button.pressed.connect(_open_page.bind(entry[1]))
		rows.add_child(button)
		if entry[1] == "bestiary":
			_bestiary_button = button
	hero_box.add_child(_label("Misiones", TITLE_COLOR))
	_mission_box = VBoxContainer.new()
	_mission_box.add_theme_constant_override("separation", 0)
	hero_box.add_child(_mission_box)
	var system_box := _main_window()
	var entries := [
		["Guardar", func() -> void: save_requested.emit()],
		["Opciones", func() -> void: _open_page("options")],
		["Volver al título", func() -> void: _open_page("confirm")],
		["Cerrar", close],
	]
	for entry: Array in entries:
		var button := _button(entry[0])
		button.pressed.connect(entry[1])
		system_box.add_child(button)
	_main_message = _label("", Color.WHITE)
	_main_message.custom_minimum_size.x = MESSAGE_WIDTH
	system_box.add_child(_main_message)


## One of the main page's two windows, top aligned; returns the box to fill.
func _main_window() -> VBoxContainer:
	var window := BattleHud.make_window()
	window.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_main_row.add_child(window)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	window.add_child(box)
	return box


func _build_status(stack: VBoxContainer) -> void:
	var page := _page_box(stack, "status", "Estado")
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 24)
	page.add_child(columns)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 8)
	columns.add_child(left)
	_hp_bar = StatBar.new(StatBar.HP, STATUS_BAR_WIDTH)
	left.add_child(_hp_bar)
	_mp_bar = StatBar.new(StatBar.MP, STATUS_BAR_WIDTH)
	left.add_child(_mp_bar)
	_exp_bar = StatBar.new(StatBar.EXP, STATUS_BAR_WIDTH)
	left.add_child(_exp_bar)
	_stats_label = _label("", Color.WHITE)
	left.add_child(_stats_label)
	_gold_label = _label("", StatBar.GOLD)
	left.add_child(_gold_label)
	_ally_label = _label("", Color.WHITE)
	left.add_child(_ally_label)
	_spells_box = VBoxContainer.new()
	_spells_box.add_theme_constant_override("separation", 2)
	columns.add_child(_spells_box)
	page.add_child(_back_button())


func _build_map(stack: VBoxContainer) -> void:
	var page := _page_box(stack, "map", "Mapa")
	_map_title = page.get_child(0) as Label
	_map_holder = HBoxContainer.new()
	_map_holder.add_theme_constant_override("separation", 16)
	page.add_child(_map_holder)
	var back := _button("Volver")
	back.pressed.connect(_go_back)
	page.add_child(back)


## What has been seen of this zone, as big as the screen lets it, with the hero, the marks
## seen so far and their legend.
func _fill_map() -> void:
	for child in _map_holder.get_children():
		_map_holder.remove_child(child)
		child.queue_free()
	var zone := ZoneData.by_id(_state.zone_id)
	_map_title.text = "Mapa · %s" % zone.map_label()
	var side := minf(MAP_PAGE_SIDE,
		get_viewport().get_visible_rect().size.y - MAP_PAGE_RESERVED)
	var square := MapSquare.new(side)
	_map_holder.add_child(square)
	var map := _state.explored_map(_state.zone_id)
	square.set_map(map)
	var marks := MapMarks.of_zone(zone, _state.world_flags, Wells.dry_ids(_state))
	square.set_marks(marks)
	if hero_position.is_valid():
		square.show_hero(hero_position.call())
	var legend := VBoxContainer.new()
	legend.add_theme_constant_override("separation", 4)
	_map_holder.add_child(legend)
	_add_legend_row(legend, MapSquare.MARKER_COLOR, "Tú")
	for kind in MapMarks.kinds_in(MapMarks.seen(marks, map)):
		_add_legend_row(legend, MapMarks.COLORS[kind], MapMarks.NAMES[kind])


func _add_legend_row(legend: VBoxContainer, color: Color, text: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	legend.add_child(row)
	var swatch := ColorRect.new()
	swatch.color = color
	swatch.custom_minimum_size = Vector2.ONE * MAP_LEGEND_SWATCH
	swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(swatch)
	var label := _label(text, Color.WHITE)
	label.add_theme_font_size_override("font_size", UiStyle.TEXT_SIZE)
	row.add_child(label)


const NO_SPELLS := "Aún no conoces hechizos que se puedan usar aquí."


func _build_spells(stack: VBoxContainer) -> void:
	var page := _page_box(stack, "spells", "Hechizos")
	_spell_hp = StatBar.new(StatBar.HP, STATUS_BAR_WIDTH)
	page.add_child(_spell_hp)
	_spell_mp = StatBar.new(StatBar.MP, STATUS_BAR_WIDTH)
	page.add_child(_spell_mp)
	_cast_box = VBoxContainer.new()
	_cast_box.add_theme_constant_override("separation", 8)
	page.add_child(_cast_box)
	_spells_message = _label("", Color.WHITE)
	_spells_message.custom_minimum_size.x = MESSAGE_WIDTH
	page.add_child(_spells_message)
	page.add_child(_back_button())


## The PV and PM bars and one row per heal the hero knows: name, cost and "Usar" (grey,
## with the reason, when it can't be cast now).
func _fill_spells() -> void:
	for child in _cast_box.get_children():
		_cast_box.remove_child(child)
		child.queue_free()
	var hero := _state.hero
	_spell_hp.show_hp(hero.hp, hero.max_hp)
	_spell_mp.show_mp(hero.mp, hero.max_mp)
	var spells := _state.field_spells()
	if spells.is_empty():
		_cast_box.add_child(_label(NO_SPELLS, Color.WHITE))
		return
	for skill in spells:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		_cast_box.add_child(row)
		var label := _label("%s  %d PM" % [skill.display_name, skill.mp_cost], Color.WHITE)
		label.custom_minimum_size = Vector2(260, 0)
		row.add_child(label)
		var cast := _button("Usar")
		var why := _state.spell_problem(skill)
		cast.disabled = why != ""
		cast.pressed.connect(_on_cast.bind(skill))
		row.add_child(cast)
		if why != "":
			row.add_child(_label(why, GREY))


func _on_cast(skill: Skill) -> void:
	var healed := _state.cast_spell(skill)
	if healed <= 0:
		return
	_sfx(SfxLibrary.HEAL)
	_fill_spells()
	_set_line(_spells_message, "Recuperas %d PV." % healed)
	state_changed.emit()
	_focus_first_in(_pages["spells"])


func _build_items(stack: VBoxContainer) -> void:
	var page := _page_box(stack, "items", "Objetos")
	var scroll := ScrollBox.new(LIST_RESERVED)
	page.add_child(scroll)
	_items_box = scroll.content
	_items_message = _label("", Color.WHITE)
	page.add_child(_items_message)
	page.add_child(_back_button())


func _build_equipment(stack: VBoxContainer) -> void:
	var page := _page_box(stack, "equipment", "Equipo")
	if Device.is_touch():
		# The slot's list of pieces is taller than a phone's screen.
		var scroll := ScrollBox.new(LIST_RESERVED)
		page.add_child(scroll)
		_equip_box = scroll.content
	else:
		_equip_box = VBoxContainer.new()
		page.add_child(_equip_box)
	_equip_stats = _label("", Color.WHITE)
	page.add_child(_equip_stats)
	_equip_message = _label("", Color.WHITE)
	page.add_child(_equip_message)
	page.add_child(_back_button())


func _build_journal(stack: VBoxContainer) -> void:
	var page := _page_box(stack, "journal", "Diario")
	var scroll := ScrollBox.new(LIST_RESERVED)
	page.add_child(scroll)
	_journal = JournalPage.new()
	scroll.content.add_child(_journal)
	page.add_child(_back_button())


## A bestiary card: portrait, name and BestiaryPage.entry_lines(); Volver goes back to the album.
func _build_bestiary_entry(stack: VBoxContainer) -> void:
	var page := _page_box(stack, "bestiary_entry", "Bestiario")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	page.add_child(row)
	_entry_picture = TextureRect.new()
	_entry_picture.custom_minimum_size = Vector2(ENTRY_PICTURE, ENTRY_PICTURE)
	_entry_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_entry_picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(_entry_picture)
	var text := VBoxContainer.new()
	row.add_child(text)
	_entry_name = _label("", Color.WHITE)
	text.add_child(_entry_name)
	_entry_lines = VBoxContainer.new()
	text.add_child(_entry_lines)
	var back := _button("Volver")
	back.pressed.connect(_back_to_bestiary)
	page.add_child(back)


func _open_bestiary_entry(id: String) -> void:
	_entry_id = id
	_entry_picture.texture = load("res://assets/bestiary/%s.png" % id)
	_entry_name.text = EnemyLibrary.data(id).display_name
	for child in _entry_lines.get_children():
		_entry_lines.remove_child(child)
		child.queue_free()
	for line in BestiaryPage.entry_lines(id, _state):
		var label := _label(line, Color.WHITE)
		label.add_theme_font_size_override("font_size", UiStyle.TEXT_SIZE)
		_entry_lines.add_child(label)
	_open_page("bestiary_entry")


func _back_to_bestiary() -> void:
	_sfx(SfxLibrary.CANCEL)
	_show_page("bestiary")
	_bestiary.focus_card(_entry_id)


func _build_bestiary(stack: VBoxContainer) -> void:
	var page := _page_box(stack, "bestiary", "Bestiario")
	_bestiary = BestiaryPage.new()
	_bestiary.card_chosen.connect(_open_bestiary_entry)
	page.add_child(_bestiary)
	page.add_child(_back_button())


func _build_options(stack: VBoxContainer) -> void:
	_options_panel = OptionsPanel.new()
	_options_panel.setup(_options, _audio, _state)
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
	UiStyle.fit_finger(button)
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
