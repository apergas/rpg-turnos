class_name JournalPage extends VBoxContainer
## The Diario of the pause menu: "Qué hacer ahora" (the story's next step), the missions in
## progress with what each one asks and the missions finished. Only reads a GameState: call
## fill() each time it opens.

## A little smaller than the other pages: seven missions must fit a 720 p window.
const HEADING_SIZE := 22
const ENTRY_SIZE := 20
const TEXT_SIZE := 18
const TITLE_COLOR := Color(1.0, 0.85, 0.3)
const GREY := Color(0.6, 0.6, 0.65)
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
	_line(state.story.goal_text(state.world_flags), Color.WHITE, ENTRY_SIZE)
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


func _heading(text: String) -> void:
	_line(text, TITLE_COLOR, HEADING_SIZE)


func _line(text: String, color: Color, font_size: int) -> void:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	add_child(label)
	BattleHud.fit_label(label, text, TEXT_WIDTH)
