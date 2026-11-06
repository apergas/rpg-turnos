class_name UiStyle extends RefCounted
## What the menu windows share: their colors, the size of small text and the line that says
## what an item does.

const TITLE_COLOR := Color(1.0, 0.85, 0.3)
const GREY := Color(0.6, 0.6, 0.65)
const TEXT_SIZE := 18
## A description wraps past this width, so a row never outgrows a narrow window.
const DESCRIPTION_WIDTH := 340.0
const TOUCH_DESCRIPTION_WIDTH := 240.0


## Adds what an item or a key item does, small and grey, to parent.
static func add_description(parent: Node, id: String) -> void:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", TEXT_SIZE)
	label.add_theme_color_override("font_color", GREY)
	parent.add_child(label)
	BattleHud.fit_label(label, Inventory.description(id),
		TOUCH_DESCRIPTION_WIDTH if Device.is_touch() else DESCRIPTION_WIDTH)


## A finger or the left button lifted on a backdrop. The release only reaches the control
## the press began on, so a drag that started in a list never closes anything.
static func is_outside_tap(event: InputEvent) -> bool:
	var mouse := event as InputEventMouseButton
	return mouse != null and not mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT


## Least width of a button on a phone, so "Sí" or "Usar" are not a sliver.
const TOUCH_BUTTON_WIDTH := 120.0


## On a phone, makes a menu row big enough for a finger. Flat rows need it: the phone's button
## theme does not draw their "normal" style, so it does not give them any height.
static func fit_finger(button: Button) -> void:
	if Device.is_touch():
		button.custom_minimum_size = Vector2(TOUCH_BUTTON_WIDTH, DisplaySettings.TOUCH_BUTTON_HEIGHT)
