class_name BestiaryPage extends VBoxContainer
## The album of enemies, a card per EnemyLibrary id: portrait and name once met in battle,
## a dark silhouette and "???" until then. fill() rebuilds it from GameState.seen_enemies.
## A card of an enemy seen is pressed (tap, or arrows and Enter) and emits card_chosen(id).

signal card_chosen(id: String)

const ELEMENT_NAMES := {Skill.FIRE: "Fuego", Skill.ICE: "Hielo", Skill.THUNDER: "Rayo"}

const ORDER: Array[String] = ["slime", "bat", "mushroom", "rey_slime", "lobo", "duende",
	"planta", "bruja", "golem_barro", "arana", "espectro", "slime_metal", "golem_piedra",
	"esqueleto_guerrero", "esqueleto_picaro", "esqueleto_mago", "senor_niebla", "slime_rojo",
	"seta_venenosa", "hongo_cueva", "murcielago_cripta", "espectro_escarcha"]
const COLUMNS := 6
const CARD_SIDE := 96.0
const TOUCH_CARD_SIDE := 84.0
const UNKNOWN := "???"
const SILHOUETTE := Color(0.05, 0.05, 0.1)
## What the title, the Volver row and the margins leave for the grid.
const RESERVED := 160.0

var _grid: GridContainer
## id -> the Button over its card, rebuilt by fill().
var _cards := {}


func _ready() -> void:
	var scroll := ScrollBox.new(RESERVED)
	add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	scroll.content.add_child(_grid)


func fill(state: GameState) -> void:
	_cards.clear()
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	for id in ORDER:
		_grid.add_child(_card(id, state.seen_enemies.has(id)))


## How many enemies of ORDER have been seen.
static func seen_count(state: GameState) -> int:
	var seen := 0
	for id in ORDER:
		if state.seen_enemies.has(id):
			seen += 1
	return seen


static func count_text(state: GameState) -> String:
	return "Bestiario %d/%d" % [seen_count(state), ORDER.size()]


## Back from a card: the focus goes to it again.
func focus_card(id: String) -> void:
	var card: Button = _cards.get(id)
	if card != null and not card.disabled:
		card.grab_focus()


## The lines of enemy id's card: where it lives, what hurts it more or less, and whether it
## has been beaten. Only reads state.
static func entry_lines(id: String, state: GameState) -> Array[String]:
	var enemy := EnemyLibrary.data(id)
	var places := EnemyLibrary.zone_names(id)
	return [
		"Vive en: %s" % (", ".join(places) if not places.is_empty() else "?"),
		"Débil a: %s" % _elements(enemy.weak),
		"Resiste: %s" % _elements(enemy.resist),
		"Vencido" if state.defeated_enemies.has(id) else "Aún no vencido",
	]


static func _elements(ids: Array[String]) -> String:
	if ids.is_empty():
		return "nada"
	var names: Array[String] = []
	for element in ids:
		names.append(ELEMENT_NAMES.get(element, element))
	return ", ".join(names)


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
	var hit := Button.new()
	hit.flat = true
	hit.disabled = not seen
	hit.focus_mode = Control.FOCUS_ALL if seen else Control.FOCUS_NONE
	hit.mouse_filter = Control.MOUSE_FILTER_STOP if seen else Control.MOUSE_FILTER_IGNORE
	hit.pressed.connect(func() -> void: card_chosen.emit(id))
	panel.add_child(hit)
	_cards[id] = hit
	return panel
