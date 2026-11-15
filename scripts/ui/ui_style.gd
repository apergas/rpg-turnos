class_name UiStyle extends RefCounted
## Constructor: static; adds the shared small labels to the controls it is given and keeps no state.
## What the menu windows share: their colors, the size of small text and the line that says
## what an item does.

## A description wraps past this width, so a row never outgrows a narrow window.
const DESCRIPTION_WIDTH := float(UiTokens.WINDOW_W_M)
const TOUCH_DESCRIPTION_WIDTH := float(UiTokens.WINDOW_W_S)


## Adds what an item or a key item does, small and grey, to parent.
static func add_description(parent: Node, id: String) -> void:
	add_small_text(parent, Inventory.description(id))


## A line of small grey text under a row, wrapped so it never outgrows a narrow window.
static func add_small_text(parent: Node, text: String) -> void:
	var label := Label.new()
	label.theme_type_variation = UiTheme.CAPTION
	parent.add_child(label)
	BattleHud.fit_label(label, text,
		TOUCH_DESCRIPTION_WIDTH if Device.is_touch() else DESCRIPTION_WIDTH)


## A finger or the left button lifted on a backdrop. The release only reaches the control
## the press began on, so a drag that started in a list never closes anything. A press swallowed before the GUI (Teclas waiting
## for a key) leaves its release to the swallower, so it never gets here.
static func is_outside_tap(event: InputEvent) -> bool:
	var mouse := event as InputEventMouseButton
	return mouse != null and not mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT
