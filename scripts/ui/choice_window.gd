class_name ChoiceWindow extends Control
## A question over the map with a button per answer: await ask() returns the index chosen.
## Keys (↑ / ↓, Enter, Esc), mouse and touch. Esc and a tap outside the window choose the
## last option, which callers always make the one that changes nothing ("No", "Aún no").
## The focus starts on `focus`, so a quick Enter never takes a step that can't be undone.

signal answered(index: int)

const WIDTH := 460
## On a phone the window is narrower so it fits 740 px (370 virtual at scale 1.6 with large text).
const TOUCH_WIDTH := 300

var _options := 0
## The first answer given; kept so one that comes before ask() awaits it is not lost.
var _answer := -1


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


## Shows the question with one button per option and waits for the answer.
func ask(question: String, options: Array[String], focus := 0) -> int:
	_options = options.size()
	size = get_viewport_rect().size  # under a CanvasLayer the anchors have no parent to follow
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.35)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.gui_input.connect(func(event: InputEvent) -> void:
		if UiStyle.is_outside_tap(event):
			_give(_options - 1))
	add_child(shade)
	var window := BattleHud.make_window()
	add_child(window)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10 if not Device.is_touch() else 4)
	window.add_child(box)
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = TOUCH_WIDTH if Device.is_touch() else WIDTH
	label.text = question
	box.add_child(label)
	var buttons: Array[Button] = []
	for i in options.size():
		var button := Button.new()
		button.text = options[i]
		UiStyle.fit_finger(button)
		button.pressed.connect(func() -> void: _give(i))
		box.add_child(button)
		buttons.append(button)
	await get_tree().process_frame
	window.position = (size - window.size) / 2.0
	buttons[focus].grab_focus()
	var chosen := _answer
	if chosen < 0:
		chosen = await answered
	queue_free()
	return chosen


func _unhandled_input(event: InputEvent) -> void:
	if _options > 0 and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_give(_options - 1)


func _give(index: int) -> void:
	if _answer >= 0:
		return
	_answer = index
	answered.emit(index)
