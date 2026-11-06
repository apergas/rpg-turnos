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
