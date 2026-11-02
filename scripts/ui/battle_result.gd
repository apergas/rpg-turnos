class_name BattleResult extends Control
## End-of-battle overlay: victory or defeat text and a "Luchar otra vez" button.
## Starts hidden; the button hides it and emits retry_requested.

signal retry_requested

var _title: Label
var _detail: Label
var _retry: Button


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
	_retry = Button.new()
	_retry.text = "Luchar otra vez"
	_retry.add_theme_font_size_override("font_size", 24)
	_retry.pressed.connect(_on_retry_pressed)
	box.add_child(_retry)
	hide()


func show_victory(exp_gained: int, total_exp: int) -> void:
	_title.text = "¡Victoria!"
	_detail.text = "+%d EXP  (total: %d)" % [exp_gained, total_exp]
	_open()


func show_defeat() -> void:
	_title.text = "Has sido derrotado"
	_detail.text = "Inténtalo de nuevo."
	_open()


func _open() -> void:
	show()
	_retry.grab_focus()


func _label(size: int) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color.WHITE)
	return label


func _on_retry_pressed() -> void:
	hide()
	retry_requested.emit()
