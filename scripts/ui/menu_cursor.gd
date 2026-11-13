class_name MenuCursor extends Control
## The gold ▶ of the chosen row of one window (design system, M-63). It follows the focused
## control when it is inside its window: a plain menu row, or, for a selector (UiTheme.SELECTOR)
## or a slider, the option row holding it. Keys and bestiary cards draw their own frame and get
## no cursor. Drawn, not a glyph, so the web shows it the same. Put it on with
## UiTheme.add_cursor(window): the cursor is the window's last child (over the rows) and top
## level, so the window's layout ignores it. The row's background is not drawn here: a top
## level node draws over the text, so a button paints it with its focus style (UiTheme._rows())
## and an option row (FocusRow) with its own _draw(). While a finger or the mouse holds a
## button down the theme draws its pressed box instead of the focus style: then the button gets
## a backing panel behind its text.

var _target: Control
var _last_y := 0.0
var _backed: Panel


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_level = true
	size = Vector2(UiTokens.CURSOR_SIZE, UiTokens.CURSOR_SIZE)


func _ready() -> void:
	get_viewport().gui_focus_changed.connect(_on_focus)
	var focused := get_viewport().gui_get_focus_owner()
	if focused:
		_on_focus(focused)
	hide()


func _on_focus(control: Control) -> void:
	if not get_parent().is_ancestor_of(control):
		_target = null
		return
	if control is Button and (control as Button).disabled:
		# A grey row never holds the chosen mark: the focus goes on the way it was going.
		_skip_disabled.call_deferred(control as Button)
		_target = null
		return
	_target = _row_of(control)
	if _target:
		_last_y = _target.global_position.y


func _skip_disabled(grey: Button) -> void:
	if not is_instance_valid(grey) or not grey.has_focus():
		return
	var down := grey.global_position.y >= _last_y
	var next := grey.find_next_valid_focus() if down else grey.find_prev_valid_focus()
	var guard := 0
	while next is Button and (next as Button).disabled and next != grey and guard < 64:
		next = next.find_next_valid_focus() if down else next.find_prev_valid_focus()
		guard += 1
	var usable := next != null and next != grey and get_parent().is_ancestor_of(next)
	if usable and not (next is Button and (next as Button).disabled):
		next.grab_focus()


static func _row_of(control: Control) -> Control:
	if control is Range or (control is Button and control.theme_type_variation == UiTheme.SELECTOR):
		return control.get_parent() as Control
	if control is Button and control.theme_type_variation == &"":
		return control
	return null


func _process(_delta: float) -> void:
	var shown := _target != null and is_instance_valid(_target) and _target.is_visible_in_tree() \
		and _holds_focus() and _inside_scroll()
	visible = shown
	_set_backing(shown)
	if not shown:
		return
	var rect := _target.get_global_rect()
	var inset := UiTokens.SPACE_1 if Device.is_touch() else UiTokens.SPACE_2
	global_position = Vector2(rect.position.x + inset, rect.position.y + (rect.size.y - size.y) / 2.0).round()


## The chosen-row background of a button held down (a finger or the mouse is on it).
func _set_backing(shown: bool) -> void:
	var button := _target as Button if shown else null
	var wanted: Panel = null
	var held := button != null and button.get_draw_mode() in [
		BaseButton.DRAW_PRESSED, BaseButton.DRAW_HOVER_PRESSED]
	if held:
		if button.has_meta(&"focus_backing"):
			wanted = button.get_meta(&"focus_backing") as Panel
		if wanted == null:
			wanted = Panel.new()
			wanted.mouse_filter = Control.MOUSE_FILTER_IGNORE
			wanted.show_behind_parent = true
			wanted.add_theme_stylebox_override(&"panel", UiTheme.selected_style())
			wanted.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			button.add_child(wanted)
			button.set_meta(&"focus_backing", wanted)
	if _backed != null and _backed != wanted and is_instance_valid(_backed):
		_backed.hide()
	_backed = wanted
	if wanted != null:
		wanted.show()


func _holds_focus() -> bool:
	var holder := get_viewport().gui_get_focus_owner()
	return holder != null and (holder == _target or _target.is_ancestor_of(holder))


## False while the row is (partly) scrolled out of its ScrollContainer.
func _inside_scroll() -> bool:
	var node := _target.get_parent()
	while node != null and node != get_parent():
		if node is ScrollContainer:
			return (node as Control).get_global_rect().grow(1.0).encloses(_target.get_global_rect())
		node = node.get_parent()
	return true


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		queue_redraw()


func _draw() -> void:
	var s := float(UiTokens.CURSOR_SIZE)
	draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(s * 0.8, s / 2.0), Vector2(0, s)]),
		UiTokens.color(&"border-focus"))
