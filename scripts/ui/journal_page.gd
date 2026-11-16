class_name JournalPage extends VBoxContainer
## The Diario of the pause menu: "Qué hacer ahora" (the story's next step), the missions in
## progress with what each one asks, the missions finished, the lost ones (taken, and no longer
## possible: QuestLog.is_lost()), the key items with what each is (and the small medals) and the
## Colección (story, missions, bestiary, families, chests and small medals, each count on its own
## line). Only reads a GameState: call fill() each time it opens.

## Long lines wrap past this width.
const TEXT_WIDTH := 720.0


func _ready() -> void:
	add_theme_constant_override("separation", 0)


func fill(state: GameState) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var journal := state.quests.journal(state.inventory, state.world_flags)
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
	if not journal.lost.is_empty():
		_heading("Perdidas")
		_line(", ".join(journal.lost), UiTheme.NOTE)
	_key_items(state)
	_heading("Colección")
	for line in collection_lines(state):
		_line(line, UiTheme.SMALL)


## The Colección: each count on its own line, never a total percentage. From the caravan on,
## the story and the missions of each part.
static func collection_lines(state: GameState) -> Array[String]:
	var part := state.part()
	var lines: Array[String] = []
	if part == 1:
		lines.append("Historia: %s" % ("terminada" if state.is_finished() else "sin terminar"))
		lines.append("Misiones: %d/%d" % [state.quests.done_of(1), QuestLog.total_of(1)])
	else:
		lines.append("Historia de Villaclaro: terminada")
		lines.append("La caravana: %s" % ("terminada" if state.is_finished_v2() else "en camino"))
		if part == 3:
			lines.append("Brumaclara: %s" % ("terminada" if state.story.finished_v3 else "en camino"))
		lines.append("Misiones de Villaclaro: %d/%d" % [state.quests.done_of(1), QuestLog.total_of(1)])
		lines.append("Misiones de la caravana: %d/%d" % [state.quests.done_of(2), QuestLog.total_of(2)])
		if part == 3:
			lines.append("Misiones de Brumaclara: %d/%d" % [state.quests.done_of(3), QuestLog.total_of(3)])
	lines.append_array([
		"Bestiario: %d/%d" % [Bestiary.seen_count(state), Bestiary.total_count(state)],
		"Familias: %d/%d" % [Bestiary.complete_count(state), Bestiary.families(state).size()],
		"Cofres: %d/%d" % [Chests.opened_count(state), Chests.total(state)],
		"Medallas: %d/%d" % [state.medals.size(), Medals.MEDALS.size()],
	])
	return lines


## «Objetos clave»: each key item carried, in the order they came, with what it is, and the
## small medals (counted, never used); nothing when there are none.
func _key_items(state: GameState) -> void:
	if state.key_items.is_empty() and state.medals.is_empty():
		return
	_heading("Objetos clave")
	for id in state.key_items:
		_line(Inventory.KEY_ITEMS[id], UiTheme.SMALL)
		UiStyle.add_small_text(self, Inventory.description(id))
	if not state.medals.is_empty():
		_line("%s ×%d" % [Inventory.MEDAL_NAME, state.medals.size()], UiTheme.SMALL)
		UiStyle.add_small_text(self, Inventory.description(Inventory.MEDAL))


func _heading(text: String) -> void:
	_line(text, UiTheme.SECTION)


func _line(text: String, variation: StringName) -> void:
	var label := Label.new()
	label.theme_type_variation = variation
	add_child(label)
	BattleHud.fit_label(label, text, TEXT_WIDTH)
