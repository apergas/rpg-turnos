class_name BattleResult extends Control
## End-of-battle overlay: victory (EXP, new level, gold, items left by the enemies) or
## defeat (the gold lost) and a "Continuar" button. Starts hidden; the button hides it
## and emits continue_requested.

signal continue_requested

var _title: Label
var _detail: VBoxContainer
var _exp_bar: StatBar
var _continue: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.55)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := BattleHud.make_window()
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	_title = _label(40)
	box.add_child(_title)
	_detail = VBoxContainer.new()
	box.add_child(_detail)
	_exp_bar = StatBar.new(StatBar.EXP)
	box.add_child(_exp_bar)
	_continue = Button.new()
	_continue.text = "Continuar"
	_continue.add_theme_font_size_override("font_size", 24)
	_continue.pressed.connect(_on_continue_pressed)
	box.add_child(_continue)
	hide()


## new_level is 0 when the hero did not level up; drops holds one item id per item won.
func show_victory(exp_gained: int, hero: Combatant, new_level: int, gold: int,
		drops: Array[String]) -> void:
	_title.text = "¡Victoria!"
	_clear_detail()
	_add_line("+%d EXP" % exp_gained, StatBar.EXP_TEXT)
	if new_level > 0:
		_add_line("¡Nivel %d!" % new_level, Color.WHITE)
	if gold > 0:
		_add_line("+%d G" % gold, StatBar.GOLD)
	for id in drops:
		_add_line("+1 %s" % Inventory.display_name(id), Color.WHITE)
	_exp_bar.show_exp(hero)
	_exp_bar.show()
	_open()


## gold_lost: the gold taken from the hero (0 shows no gold line).
func show_defeat(gold_lost := 0) -> void:
	_title.text = "Has sido derrotado"
	_clear_detail()
	if gold_lost > 0:
		_add_line("Pierdes %d G." % gold_lost, StatBar.GOLD)
	_add_line("Volverás al pueblo.", Color.WHITE)
	_exp_bar.hide()
	_open()


func _clear_detail() -> void:
	for child in _detail.get_children():
		_detail.remove_child(child)
		child.queue_free()


func _add_line(text: String, color: Color) -> void:
	var label := _label(24)
	label.text = text
	label.add_theme_color_override("font_color", color)
	_detail.add_child(label)


func _open() -> void:
	show()
	_continue.disabled = true
	await get_tree().create_timer(0.3).timeout
	_continue.disabled = false
	_continue.grab_focus()


func _label(size: int) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color.WHITE)
	return label


func _on_continue_pressed() -> void:
	hide()
	continue_requested.emit()
