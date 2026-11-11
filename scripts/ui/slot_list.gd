class_name SlotList extends VBoxContainer
## The save slots on the title screen, as pages inside one of the title's windows. The list
## has a row per slot: "Ranura n" and, under it, SaveData.summary_line() of its save
## (" · terminada" once the game is finished: the v1's or, in the caravan, the v2's), "Vacía" or "Partida dañada". LOAD
## (Continuar) only lets usable saves be picked; NEW (Nueva partida) takes any slot and
## asks first, focus on "No", when it holds a usable save. On a finished game
## (SaveData.is_finished()) LOAD opens a page with "Continuar" and "Partida nueva +", which asks
## first, focus on "No", and emits ng_plus_chosen(slot). Emits chosen(slot) once a slot is
## settled and closed on Volver. back() is what Esc and a tap outside do. MANAGE (the title's
## Opciones, Exportar o importar partida) opens a page per slot with Exportar and Importar,
## and emits changed when an import filled the slot.

signal chosen(slot: int)
signal closed
## A slot was filled from a file (MANAGE).
signal changed
## A finished game's slot asks for a Partida nueva + on it (LOAD).
signal ng_plus_chosen(slot: int)

enum Mode { LOAD, NEW, MANAGE }

const FONT_SIZE := 24
const TITLES := {Mode.LOAD: "Continuar", Mode.NEW: "Nueva partida",
	Mode.MANAGE: "Exportar o importar"}
const SLOT_TEXT := "Ranura %d"
const EMPTY_TEXT := "Vacía"
const DAMAGED_TEXT := "Partida dañada"
const FINISHED_TEXT := " · terminada"
const NEW_CONFIRM := "La partida de la ranura %d se borrará.\n¿Empezar una nueva?"
const NEW_YES := "Sí, empezar de nuevo"
const IMPORT_CONFIRM := "La partida de la ranura %d se sustituirá\npor la del archivo. ¿Seguir?"
const IMPORT_YES := "Sí, sustituir"
## LOAD on a finished game: its page and the question before a Partida nueva +.
const CYCLE_CONTINUE := "Continuar"
const NG_PLUS := "Partida nueva +"
const NG_PLUS_CONFIRM := "Empiezas de nuevo la historia con tu héroe,\nsu equipo y su oro. Los monstruos serán\nmás fuertes. ¿Seguro?"
const NG_PLUS_YES := "Sí, Partida nueva +"
const IMPORTED_TEXT := "Partida importada en la ranura %d."
const SAVE_FAILED_TEXT := "No se pudo guardar la partida."
## Messages wrap past this width.
const MESSAGE_WIDTH := 360.0

var mode := Mode.LOAD
var _audio: AudioDirector
var _transfer: SaveTransfer
var _detail_line: Label
var _export_button: Button
var _import_button: Button
var _message: Label
## SaveStore.slot_info() of each slot, read by open() and after a change.
var _infos: Array[Dictionary] = []
var _pages := {}
var _page := ""
## The slot last chosen in the list.
var _slot := 1
## A file window is open: rows and back() wait.
var _busy := false
var _quiet_focus := false
var _title: Label
var _rows: Array[Button] = []
var _list_back: Button
var _confirm_text: Label
var _confirm_yes: Button
var _confirm_no: Button
var _confirm_action: Callable
## The page "No" goes back to.
var _confirm_back := "list"
## The finished game's page: its line and "Continuar" (focused first).
var _cycle_line: Label
var _cycle_continue: Button


func setup(audio: AudioDirector, transfer: SaveTransfer = null) -> void:
	_audio = audio
	_transfer = transfer


func _ready() -> void:
	add_theme_constant_override("separation", 8)
	_title = _label("", UiStyle.TITLE_COLOR)
	add_child(_title)
	var list := _page_box("list")
	for slot in range(1, SaveStore.SLOT_COUNT + 1):
		var row := _button("")
		row.pressed.connect(_on_row.bind(slot))
		list.add_child(row)
		_rows.append(row)
	_list_back = _button("Volver")
	_list_back.pressed.connect(back)
	list.add_child(_list_back)
	var confirm := _page_box("confirm")
	_confirm_text = _label("", Color.WHITE)
	confirm.add_child(_confirm_text)
	_confirm_yes = _button("")
	_confirm_yes.pressed.connect(func() -> void: _confirm_action.call())
	confirm.add_child(_confirm_yes)
	_confirm_no = _button("No")
	_confirm_no.pressed.connect(back)
	confirm.add_child(_confirm_no)
	var actions := _page_box("actions")
	_detail_line = _label("", Color.WHITE)
	_detail_line.add_theme_font_size_override("font_size", UiStyle.TEXT_SIZE)
	actions.add_child(_detail_line)
	_export_button = _button("Exportar")
	_export_button.pressed.connect(_on_export)
	actions.add_child(_export_button)
	_import_button = _button("Importar")
	_import_button.pressed.connect(_on_import)
	actions.add_child(_import_button)
	var actions_back := _button("Volver")
	actions_back.pressed.connect(back)
	actions.add_child(actions_back)
	_message = _label(" ", Color.WHITE)
	_message.add_theme_font_size_override("font_size", UiStyle.TEXT_SIZE)
	_message.custom_minimum_size.x = MESSAGE_WIDTH
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	actions.add_child(_message)
	var cycle := _page_box("cycle")
	_cycle_line = _label("", Color.WHITE)
	_cycle_line.add_theme_font_size_override("font_size", UiStyle.TEXT_SIZE)
	cycle.add_child(_cycle_line)
	_cycle_continue = _button(CYCLE_CONTINUE)
	_cycle_continue.pressed.connect(func() -> void: chosen.emit(_slot))
	cycle.add_child(_cycle_continue)
	var plus := _button(NG_PLUS)
	plus.pressed.connect(func() -> void:
		_ask(NG_PLUS_CONFIRM, NG_PLUS_YES, func() -> void: ng_plus_chosen.emit(_slot)))
	cycle.add_child(plus)
	var cycle_back := _button("Volver")
	cycle_back.pressed.connect(back)
	cycle.add_child(cycle_back)


## Shows the slots for p_mode, read again from the files (a game may have saved since).
func open(p_mode: Mode) -> void:
	mode = p_mode
	_busy = false
	_refresh()
	_show("list")
	_focus_row(1)


## Esc, No, Volver or a tap outside: one page back; from the list, closed.
func back() -> void:
	if _busy:
		return
	_sfx(SfxLibrary.CANCEL)
	match _page:
		"list":
			closed.emit()
		"confirm":
			_show(_confirm_back)
			_focus_page(_confirm_back)
		_:
			_show("list")
			_focus_row(_slot)


func _refresh() -> void:
	_infos.clear()
	for slot in range(1, SaveStore.SLOT_COUNT + 1):
		var info := SaveStore.slot_info(slot)
		_infos.append(info)
		var row := _rows[slot - 1]
		row.text = "%s\n%s" % [SLOT_TEXT % slot, _detail(info)]
		row.disabled = mode == Mode.LOAD and info.kind != SaveStore.SlotKind.USABLE


static func _detail(info: Dictionary) -> String:
	match info.kind:
		SaveStore.SlotKind.EMPTY:
			return EMPTY_TEXT
		SaveStore.SlotKind.DAMAGED:
			return DAMAGED_TEXT
	var save: Dictionary = info.save
	var text := SaveData.summary_line(save)
	var story: Variant = save.get("story")
	if SaveData.is_finished_v2(save) or (story is Dictionary
			and story.get("finished", false) == true and not SaveData.is_caravan(save)):
		text += FINISHED_TEXT
	return text


func _on_row(slot: int) -> void:
	if _busy:
		return
	_slot = slot
	var usable: bool = _infos[slot - 1].kind == SaveStore.SlotKind.USABLE
	match mode:
		Mode.LOAD:
			if SaveData.is_finished(_infos[slot - 1].save):
				_show_cycle()
			else:
				chosen.emit(slot)
		Mode.NEW:
			if usable:
				_ask(NEW_CONFIRM % slot, NEW_YES, func() -> void: chosen.emit(slot))
			else:
				chosen.emit(slot)
		Mode.MANAGE:
			_sfx(SfxLibrary.ACCEPT)
			_show_actions("")
			_focus_page("actions")


## A question with "No" focused; yes runs action, "No" goes back to the page it came from.
func _ask(text: String, yes_text: String, action: Callable) -> void:
	_sfx(SfxLibrary.ACCEPT)
	_confirm_back = _page
	_confirm_text.text = text
	_confirm_yes.text = yes_text
	_confirm_action = action
	_show("confirm")
	_focus(_confirm_no)


func _show(page: String) -> void:
	_page = page
	for page_name: String in _pages:
		(_pages[page_name] as Control).visible = page_name == page
	if page == "list":
		_title.text = TITLES[mode]


func _focus_page(page: String) -> void:
	if page == "list":
		_focus_row(_slot)
	elif page == "actions":
		_focus(_import_button if _export_button.disabled else _export_button)
	elif page == "cycle":
		_focus(_cycle_continue)


## A finished game: "Continuar" (the game as it is, the world after the ending) or
## "Partida nueva +" (asked first, focus on "No"); "Continuar" is focused.
func _show_cycle() -> void:
	_sfx(SfxLibrary.ACCEPT)
	_title.text = SLOT_TEXT % _slot
	_cycle_line.text = _detail(_infos[_slot - 1])
	_show("cycle")
	_focus(_cycle_continue)


## The chosen slot's page: its line, Exportar only with a usable save, and message.
func _show_actions(message: String) -> void:
	var info: Dictionary = _infos[_slot - 1]
	_title.text = SLOT_TEXT % _slot
	_detail_line.text = _detail(info)
	_export_button.disabled = info.kind != SaveStore.SlotKind.USABLE
	_message.text = message if message != "" else " "
	_show("actions")


func _on_export() -> void:
	if _busy:
		return
	_busy = true
	_sfx(SfxLibrary.ACCEPT)
	var text := await _transfer.export_text(_slot, SaveStore.slot_text(_slot))
	_busy = false
	if text != "":
		_message.text = text


func _on_import() -> void:
	if _busy:
		return
	_busy = true
	_sfx(SfxLibrary.ACCEPT)
	var file: Dictionary = await _transfer.import_text()
	_busy = false
	if not file.picked:
		return
	var result := SaveData.from_json(file.text)
	if not result.ok:
		_message.text = result.text
		return
	if _infos[_slot - 1].kind == SaveStore.SlotKind.USABLE:
		_ask(IMPORT_CONFIRM % _slot, IMPORT_YES, _write_import.bind(result.save))
	else:
		_write_import(result.save)


func _write_import(save: Dictionary) -> void:
	var ok := SaveStore.save_game(_slot, save)
	_refresh()
	_show_actions(IMPORTED_TEXT % _slot if ok else SAVE_FAILED_TEXT)
	_focus_page("actions")
	if ok:
		changed.emit()


## slot's row if it can be chosen, else the first one that can, else Volver.
func _focus_row(slot: int) -> void:
	var row := _rows[slot - 1]
	if row.disabled:
		row = _list_back
		for other in _rows:
			if not other.disabled:
				row = other
				break
	_focus(row)


func _page_box(page_name: String) -> VBoxContainer:
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 8)
	page.hide()
	add_child(page)
	_pages[page_name] = page
	return page


func _focus(button: Button) -> void:
	_quiet_focus = true
	button.grab_focus()
	_quiet_focus = false


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.flat = true
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	UiStyle.fit_finger(button)
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
