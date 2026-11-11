class_name JournalPage extends VBoxContainer
## The Diario of the pause menu: "Qué hacer ahora" (the story's next step), the missions in
## progress with what each one asks, the missions finished and the Colección (story, missions,
## bestiary, families, chests and small medals, each count on its own line). Only reads a GameState:
## call
## fill() each time it opens.

## A little smaller than the other pages: seven missions must fit a 720 p window.
const HEADING_SIZE := 22
const ENTRY_SIZE := 20
const TEXT_SIZE := UiStyle.TEXT_SIZE
const TITLE_COLOR := UiStyle.TITLE_COLOR
const GREY := UiStyle.GREY
## Long lines wrap past this width.
const TEXT_WIDTH := 720.0


func _ready() -> void:
	add_theme_constant_override("separation", 0)


func fill(state: GameState) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var journal := state.quests.journal(state.inventory)
	_heading("Qué hacer ahora")
	_line(state.main_goal(), Color.WHITE, ENTRY_SIZE)
	_heading("En curso")
	if journal.active.is_empty():
		_line("Nada por ahora.", GREY, ENTRY_SIZE)
	for entry: Dictionary in journal.active:
		_line(entry.title, Color.WHITE, ENTRY_SIZE)
		_line(entry.text, GREY, TEXT_SIZE)
	_heading("Cumplidas")
	if journal.done.is_empty():
		_line("Ninguna todavía.", GREY, ENTRY_SIZE)
	else:
		_line(", ".join(journal.done), Color.WHITE, TEXT_SIZE)
	_heading("Colección")
	for line in collection_lines(state):
		_line(line, Color.WHITE, ENTRY_SIZE)


## The Colección: each count on its own line, never a total percentage.
static func collection_lines(state: GameState) -> Array[String]:
	return [
		"Historia: %s" % ("terminada" if state.is_finished() else "sin terminar"),
		"Misiones: %d/%d" % [state.quests_done(), QuestLog.total_count()],
		"Bestiario: %d/%d" % [Bestiary.seen_count(state), Bestiary.total_count(state)],
		"Familias: %d/%d" % [Bestiary.complete_count(state), Bestiary.FAMILIES.size()],
		"Cofres: %d/%d" % [state.opened_chests.size(), Chests.CHESTS.size()],
		"Medallas: %d/%d" % [state.medals.size(), Medals.MEDALS.size()],
	]


func _heading(text: String) -> void:
	_line(text, TITLE_COLOR, HEADING_SIZE)


func _line(text: String, color: Color, font_size: int) -> void:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	add_child(label)
	BattleHud.fit_label(label, text, TEXT_WIDTH)
