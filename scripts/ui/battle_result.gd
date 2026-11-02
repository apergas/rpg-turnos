class_name BattleResult extends Control
## End-of-battle overlay: victory or defeat text and a "Continuar" button.
## Starts hidden; the button hides it and emits continue_requested.

signal continue_requested

var _title: Label
var _detail: Label
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
	panel.custom_minimum_size = Vector2(420, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)
	_title = _label(40)
	box.add_child(_title)
	_detail = _label(24)
	box.add_child(_detail)
	_continue = Button.new()
	_continue.text = "Continuar"
	_continue.add_theme_font_size_override("font_size", 24)
	_continue.pressed.connect(_on_continue_pressed)
	box.add_child(_continue)
	hide()


func show_victory(exp_gained: int, total_exp: int) -> void:
	_title.text = "¡Victoria!"
	_detail.text = "+%d EXP  (total: %d)" % [exp_gained, total_exp]
	_open()


func show_defeat() -> void:
	_title.text = "Has sido derrotado"
	_detail.text = "Volverás al inicio."
	_open()


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
