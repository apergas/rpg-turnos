class_name JournalPage extends VBoxContainer
## The Diario of the pause menu: "Qué hacer ahora" (the story's next step), the missions in
## progress with what each one asks, the missions finished and the Colección (story, missions,
## bestiary, families, chests and small medals, each count on its own line). Only reads a GameState:
## call
## fill() each time it opens.

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
	_line(state.main_goal(), UiTheme.SMALL)
	_heading("En curso")
	if journal.active.is_empty():
		_line("Nada por ahora.", UiTheme.CAPTION)
	for entry: Dictionary in journal.active:
		_line(entry.title, UiTheme.SMALL)
		_line(entry.text, UiTheme.CAPTION)
	_heading("Cumplidas")
	if journal.done.is_empty():
		_line("Ninguna todavía.", UiTheme.CAPTION)
	else:
		_line(", ".join(journal.done), UiTheme.NOTE)
	_heading("Colección")
	for line in collection_lines(state):
		_line(line, UiTheme.SMALL)


## The Colección: each count on its own line, never a total percentage.
static func collection_lines(state: GameState) -> Array[String]:
	var missions: Array[String] = ["Misiones: %d/%d" % [state.quests.done_of(false),
		QuestLog.total_of(false)]]
	if state.in_caravan():
		missions = ["Misiones de Villaclaro: %d/%d" % [state.quests.done_of(false),
			QuestLog.total_of(false)],
			"Misiones de la caravana: %d/%d" % [state.quests.done_of(true),
			QuestLog.total_of(true)]]
	var lines: Array[String] = ["Historia: %s" % ("terminada" if state.is_finished() else "sin terminar")]
	if state.in_caravan():
		lines = ["Historia de Villaclaro: terminada",
			"La caravana: %s" % ("terminada" if state.is_finished_v2() else "en camino")]
	lines.append_array(missions)
	lines.append_array([
		"Bestiario: %d/%d" % [Bestiary.seen_count(state), Bestiary.total_count(state)],
		"Familias: %d/%d" % [Bestiary.complete_count(state), Bestiary.families(state).size()],
		"Cofres: %d/%d" % [Chests.opened_count(state), Chests.total(state)],
		"Medallas: %d/%d" % [state.medals.size(), Medals.MEDALS.size()],
	])
	return lines


func _heading(text: String) -> void:
	_line(text, UiTheme.SECTION)


func _line(text: String, variation: StringName) -> void:
	var label := Label.new()
	label.theme_type_variation = variation
	add_child(label)
	BattleHud.fit_label(label, text, TEXT_WIDTH)
