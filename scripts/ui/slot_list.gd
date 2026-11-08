class_name SlotList extends VBoxContainer
## The save slots on the title screen, as pages inside one of the title's windows. The list
## has a row per slot: "Ranura n" and, under it, SaveData.summary_line() of its save
## (" · terminada" once the game is finished), "Vacía" or "Partida dañada". LOAD
## (Continuar) only lets usable saves be picked; NEW (Nueva partida) takes any slot and
## asks first, focus on "No", when it holds a usable save. Emits chosen(slot) once a slot is
## settled and closed on Volver. back() is what Esc and a tap outside do.

signal chosen(slot: int)
signal closed

enum Mode { LOAD, NEW }

const FONT_SIZE := 24
const TITLES := {Mode.LOAD: "Continuar", Mode.NEW: "Nueva partida"}
const SLOT_TEXT := "Ranura %d"
const EMPTY_TEXT := "Vacía"
const DAMAGED_TEXT := "Partida dañada"
const FINISHED_TEXT := " · terminada"
const NEW_CONFIRM := "La partida de la ranura %d se borrará.\n¿Empezar una nueva?"
const NEW_YES := "Sí, empezar de nuevo"

var mode := Mode.LOAD
var _audio: AudioDirector
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


func setup(audio: AudioDirector) -> void:
	_audio = audio


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
	if story is Dictionary and story.get("finished", false) == true:
		text += FINISHED_TEXT
	return text


func _on_row(slot: int) -> void:
	if _busy:
		return
	_slot = slot
	var usable: bool = _infos[slot - 1].kind == SaveStore.SlotKind.USABLE
	match mode:
		Mode.LOAD:
			chosen.emit(slot)
		Mode.NEW:
			if usable:
				_ask(NEW_CONFIRM % slot, NEW_YES, func() -> void: chosen.emit(slot))
			else:
				chosen.emit(slot)


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
