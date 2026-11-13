class_name DebugPanel extends Control
## Development only. Game builds it only with `--debug` on the command line
## (OS.get_cmdline_user_args(); the web has no way to pass it), and autoplay never uses it.
## F1 on the map, while `available` (nothing else going on, the tree not paused), opens it
## over everything and pauses the tree, like the pause menu; F1, Esc, Cerrar or a tap
## outside close it. Each button emits action_chosen(action, arg): Game does it, prints
## "Depuración: ..." and answers with show_result(). Ir a closes the panel first: Game takes
## the hero there under black. Every button has a name (zone_<id>, level_up, gold_100,
## boss_<id>...), so a script can press it.

signal action_chosen(action: String, arg: String)
signal open_changed(is_open: bool)

const ZONE := "zone"
const LEVEL := "level"
const GOLD := "gold"
const ITEMS := "items"
const HEAL := "heal"
const MONSTERS := "monsters"
const BOSS := "boss"
const QUEST := "quest"
const SAVE := "save"
const GOLD_STEPS: Array[int] = [100, 1000]
## Quest.Stage in words, for the status line.
const STAGE_NAMES: Array[String] = ["sin empezar", "caza", "informe", "jefe", "cumplida"]
## The rows of buttons wrap at this width (the window fits 1024 × 576 with large text, and a
## phone).
const ROW_WIDTH := 720.0
## Room the title, the two lines, Cerrar and the margins leave the scrolling list.
const LIST_RESERVED := 200.0

## False while a battle, a dialogue, a fade or a menu is on (Game._set_busy()).
var available := false

var _state: GameState
var _status: Label
var _result: Label
var _first: Button
var _level_down: Button
var _level_up: Button
var _monsters: Button
var _quest: Button
## Boss id -> its button.
var _bosses := {}


func setup(state: GameState) -> void:
	_state = state


## The bosses the story needs, in ZoneData.IDS order (each zone's boss_id; the Eco de la
## Niebla, after the ending, is not one).
static func bosses() -> Array[String]:
	var ids: Array[String] = []
	for zone_id in ZoneData.IDS:
		var boss := ZoneData.by_id(zone_id).boss_id
		if boss != "" and not boss in ids:
			ids.append(boss)
	return ids


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.5)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.gui_input.connect(func(event: InputEvent) -> void:
		if UiStyle.is_outside_tap(event):
			close())
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var window := BattleHud.make_window()
	window.mouse_filter = Control.MOUSE_FILTER_STOP  # a tap inside never closes it
	center.add_child(window)
	var stack := VBoxContainer.new()
	window.add_child(stack)
	var title := Label.new()
	title.text = "Depuración"
	title.add_theme_color_override("font_color", UiTokens.color(&"text-accent"))
	stack.add_child(title)
	_status = _line(stack)
	var list := ScrollBox.new(LIST_RESERVED)
	list.content.custom_minimum_size.x = ROW_WIDTH
	stack.add_child(list)
	_build_rows(list.content)
	_result = _line(stack)
	_button(stack, "close", "Cerrar").pressed.connect(close)
	UiTheme.add_cursor(window)
	hide()


func _build_rows(box: VBoxContainer) -> void:
	var zones := _section(box, "Ir a")
	for zone_id in ZoneData.IDS:
		var button := _action(zones, "zone_" + zone_id, ZoneData.by_id(zone_id).map_label(),
			ZONE, zone_id)
		if _first == null:
			_first = button
	var level := _section(box, "Nivel")
	_level_down = _action(level, "level_down", "−1", LEVEL, "-1")
	_level_up = _action(level, "level_up", "+1", LEVEL, "1")
	var gold := _section(box, "Oro")
	for step in GOLD_STEPS:
		_action(gold, "gold_%d" % step, "+%d G" % step, GOLD, str(step))
	_action(_section(box, "Objetos"), "items", "+1 de cada objeto", ITEMS, "")
	_action(_section(box, "Curar"), "heal", "PV y PM llenos", HEAL, "")
	_monsters = _action(_section(box, "Monstruos"), "monsters", "", MONSTERS, "")
	var boss_row := _section(box, "Jefes")
	for id in bosses():
		_bosses[id] = _action(boss_row, "boss_" + id, EnemyLibrary.data(id).display_name,
			BOSS, id)
	_quest = _action(_section(box, "Misión de la aldea"), "quest", "Etapa siguiente", QUEST,
		"")
	_action(_section(box, "Guardar"), "save", "En la ranura en curso", SAVE, "")


func is_open() -> bool:
	return visible


## Opens the panel (only while available and with the tree not paused) and pauses the tree.
func open() -> void:
	if visible or not available or get_tree().paused:
		return
	get_tree().paused = true
	_result.text = ""
	refresh()
	show()
	_first.grab_focus()
	open_changed.emit(true)


func close() -> void:
	if not visible:
		return
	hide()
	get_tree().paused = false
	open_changed.emit(false)


## Game's answer to an action: what was done (also printed), and the panel brought up to
## date.
func show_result(text: String) -> void:
	_result.text = text
	refresh()


## The status line and every button that depends on the game: the level's bounds, the
## Monstruos toggle, the bosses already beaten and the village quest once done.
func refresh() -> void:
	if _state == null:
		return
	var hero := _state.hero
	_status.text = "%s · PV %d/%d · PM %d/%d · %d G · %s · misión de la aldea: %s" % [
		StatBar.hero_title(hero), hero.hp, hero.max_hp, hero.mp, hero.max_mp, _state.gold,
		ZoneData.by_id(_state.zone_id).map_label(), STAGE_NAMES[_state.quest.stage]]
	_level_down.disabled = hero.level <= 1
	_level_up.disabled = hero.level >= Leveling.MAX_LEVEL
	_monsters.text = "Poner grupos" if World.debug_no_groups else "Quitar grupos"
	for id: String in _bosses:
		(_bosses[id] as Button).disabled = _state.has_flag(id)
	_quest.disabled = _state.quest.stage == Quest.Stage.DONE


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	var f1 := key != null and key.pressed and not key.echo and key.keycode == KEY_F1
	if not visible:
		if f1 and available:
			get_viewport().set_input_as_handled()
			open()
		return
	if f1 or event.is_action_pressed(KeyMap.CANCEL) or event.is_action_pressed(KeyMap.PAUSE):
		get_viewport().set_input_as_handled()
		close()


func _choose(action: String, arg: String) -> void:
	if action == ZONE:
		close()
	action_chosen.emit(action, arg)


## A heading and the row of buttons under it, which wraps.
func _section(box: VBoxContainer, heading: String) -> HFlowContainer:
	var label := Label.new()
	label.text = heading
	label.add_theme_font_size_override("font_size", UiTokens.TYPE_CAPTION_SIZE)
	label.add_theme_color_override("font_color", UiTokens.color(&"text-accent"))
	box.add_child(label)
	var flow := HFlowContainer.new()
	box.add_child(flow)
	return flow


func _action(parent: Control, node_name: String, text: String, action: String,
		arg: String) -> Button:
	var button := _button(parent, node_name, text)
	button.pressed.connect(_choose.bind(action, arg))
	return button


func _button(parent: Control, node_name: String, text: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	UiTheme.menu_row(button)
	parent.add_child(button)
	return button


## A line of small text as wide as the rows, wrapped.
func _line(parent: Control) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", UiTokens.TYPE_CAPTION_SIZE)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = ROW_WIDTH
	parent.add_child(label)
	return label
