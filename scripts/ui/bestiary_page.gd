class_name BestiaryPage extends VBoxContainer
## The album of enemies, a card per EnemyLibrary id: portrait and name once met in battle,
## a dark silhouette and "???" until then. fill() rebuilds it from GameState.seen_enemies.

const ORDER: Array[String] = ["slime", "bat", "mushroom", "rey_slime", "lobo", "duende",
	"planta", "bruja", "golem_barro", "arana", "espectro", "slime_metal", "golem_piedra",
	"esqueleto_guerrero", "esqueleto_picaro", "esqueleto_mago", "senor_niebla"]
const COLUMNS := 6
const CARD_SIDE := 96.0
const TOUCH_CARD_SIDE := 84.0
const UNKNOWN := "???"
const SILHOUETTE := Color(0.05, 0.05, 0.1)
## What the title, the Volver row and the margins leave for the grid.
const RESERVED := 160.0

var _grid: GridContainer


func _ready() -> void:
	var scroll := ScrollBox.new(RESERVED)
	add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	scroll.content.add_child(_grid)


func fill(state: GameState) -> void:
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	for id in ORDER:
		_grid.add_child(_card(id, state.seen_enemies.has(id)))


static func count_text(state: GameState) -> String:
	var seen := 0
	for id in ORDER:
		if state.seen_enemies.has(id):
			seen += 1
	return "Bestiario %d/%d" % [seen, ORDER.size()]


func _card(id: String, seen: bool) -> Control:
	var side := TOUCH_CARD_SIDE if Device.is_touch() else CARD_SIDE
	var panel := PanelContainer.new()
	var box := VBoxContainer.new()
	panel.add_child(box)
	var picture := TextureRect.new()
	picture.texture = load("res://assets/bestiary/%s.png" % id)
	picture.custom_minimum_size = Vector2(side, side)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if not seen:
		picture.modulate = SILHOUETTE
	box.add_child(picture)
	var label := Label.new()
	label.text = EnemyLibrary.data(id).display_name if seen else UNKNOWN
	label.custom_minimum_size.x = side
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", UiStyle.TEXT_SIZE)
	box.add_child(label)
	return panel
