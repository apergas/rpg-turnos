class_name BestiaryPage extends VBoxContainer
## The album of enemies by family (Bestiary.FAMILIES): each family's title with how many of
## its enemies have been beaten ("Plantas 3/4"; complete, in gold and with its prize:
## "Plantas 4/4 · Anillo de savia"), and under it its cards: portrait and name once met in
## battle, a dark silhouette and "???" until then. fill() rebuilds it from the GameState.
## A card of an enemy seen is pressed (tap, or arrows and Enter) and emits card_chosen(id).

signal card_chosen(id: String)

const ELEMENT_NAMES := {Skill.FIRE: "Fuego", Skill.ICE: "Hielo", Skill.THUNDER: "Rayo"}

## Cards per row: every family fits in one (the longest has five).
const COLUMNS := 6
const CARD_SIDE := 96.0
const TOUCH_CARD_SIDE := 84.0
const UNKNOWN := "???"
const SILHOUETTE := Color(0.05, 0.05, 0.1)
## Size of a family's title.
const TITLE_SIZE := 20
## What the title, the Volver row and the margins leave for the grid.
const RESERVED := 160.0

## The families, each a title and a grid of cards, rebuilt by fill().
var _box: VBoxContainer
## id -> the Button over its card, rebuilt by fill().
var _cards := {}
## family id -> the Label of its title, rebuilt by fill().
var _titles := {}


func _ready() -> void:
	var scroll := ScrollBox.new(RESERVED)
	add_child(scroll)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 8)
	scroll.content.add_child(_box)


func fill(state: GameState) -> void:
	_cards.clear()
	_titles.clear()
	for child in _box.get_children():
		_box.remove_child(child)
		child.queue_free()
	for family in Bestiary.FAMILIES:
		var title := Label.new()
		title.text = title_text(state, family.id)
		title.add_theme_font_size_override("font_size", TITLE_SIZE)
		title.add_theme_color_override("font_color", StatBar.GOLD
			if Bestiary.is_complete(state, family.id) else UiStyle.TITLE_COLOR)
		_box.add_child(title)
		_titles[family.id] = title
		var grid := GridContainer.new()
		grid.columns = COLUMNS
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		_box.add_child(grid)
		for id: String in family.enemies:
			grid.add_child(_card(id, state.seen_enemies.has(id)))


## "Plantas 3/4" (the enemies beaten), and the prize once complete: "Plantas 4/4 · Anillo
## de savia".
static func title_text(state: GameState, family_id: String) -> String:
	var family := Bestiary.family(family_id)
	var text := "%s %d/%d" % [family.name, Bestiary.beaten_count(state, family_id),
		family.enemies.size()]
	if Bestiary.is_complete(state, family_id):
		text += " · %s" % Equipment.display_name(family.reward)
	return text


## "Bestiario 14/22": the enemies seen.
static func count_text(state: GameState) -> String:
	return "Bestiario %d/%d" % [Bestiary.seen_count(state), Bestiary.all_ids().size()]


## Back from a card: the focus goes to it again.
func focus_card(id: String) -> void:
	var card: Button = _cards.get(id)
	if card != null and not card.disabled:
		card.grab_focus()


## The lines of enemy id's card: its family, where it lives, what hurts it more or less, and
## whether it has been beaten. Only reads state.
static func entry_lines(id: String, state: GameState) -> Array[String]:
	var enemy := EnemyLibrary.data(id)
	var places := EnemyLibrary.zone_names(id)
	return [
		"Familia: %s" % Bestiary.family(Bestiary.family_of(id)).get("name", "?"),
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
