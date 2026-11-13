class_name UiTheme extends RefCounted
## Villaclaro's Theme, built in code from UiTokens (the design system, M-62). apply() puts it on
## the default theme, the only one that reaches controls under a CanvasLayer: every type gets the
## ui font at body size, then build() is merged on top. A window is a PanelContainer with no
## overrides; a menu row is a Button through menu_row(); labels pick a type variation. Rebuilt
## when high contrast changes (the whole tree is told, so variations follow at once).

const TITLE := &"TitleLabel"
const SECTION := &"SectionLabel"
const SMALL := &"SmallLabel"
const CAPTION := &"CaptionLabel"
const NOTE := &"NoteLabel"
const REASON := &"ReasonLabel"
const MONEY := &"MoneyLabel"
const POSITIVE := &"PositiveLabel"
const NEGATIVE := &"NegativeLabel"
const BADGE := &"BadgeLabel"
const MICRO := &"MicroLabel"
const OUTLINED := &"OutlinedLabel"
const DISPLAY := &"DisplayLabel"
const DISPLAY_SUB := &"DisplaySubLabel"
const WINDOW_MAP := &"MapWindow"
const CARD := &"CardWindow"
const SELECTED_ROW := &"SelectedRow"
const SELECTOR := &"SelectorButton"
const KEY := &"KeyButton"
const CARD_HIT := &"CardHitButton"
const MENU_BUTTON := &"MenuButtonWindow"
const ACTION_BUTTON := &"ActionButton"

static var _applied := false
static var _high_contrast := false
## Style or "path:weight" -> Font (one FontVariation each, shared).
static var _fonts := {}


## Puts the theme on (again only if high_contrast changed). DisplaySettings.apply() calls it.
static func apply(window: Window, high_contrast := false) -> void:
	if _applied and high_contrast == _high_contrast:
		return
	var again := _applied
	_applied = true
	_high_contrast = high_contrast
	UiTokens.high_contrast = high_contrast
	var theme := ThemeDB.get_default_theme()
	var ui := font_for(&"body")
	theme.default_font = ui
	theme.default_font_size = UiTokens.TYPE_BODY_SIZE
	for type in theme.get_font_type_list():
		theme.set_font(&"font", type, ui)
	for type in theme.get_font_size_type_list():
		theme.set_font_size(&"font_size", type, UiTokens.TYPE_BODY_SIZE)
	theme.merge_with(build())
	if again and window:
		window.propagate_notification(Control.NOTIFICATION_THEME_CHANGED)


## The scenes that run on their own (no title before them) put the theme on once.
static func ensure(window: Window) -> void:
	if not _applied:
		apply(window)


static func build() -> Theme:
	var theme := Theme.new()
	theme.set_stylebox(&"panel", &"PanelContainer", window_style())
	_variation(theme, WINDOW_MAP, &"PanelContainer")
	theme.set_stylebox(&"panel", WINDOW_MAP, map_style())
	_variation(theme, CARD, &"PanelContainer")
	var card := window_style()
	card.set_corner_radius_all(UiTokens.RADIUS_L)
	theme.set_stylebox(&"panel", CARD, card)
	_variation(theme, SELECTED_ROW, &"Panel")
	theme.set_stylebox(&"panel", SELECTED_ROW, selected_style())
	_rows(theme)
	_buttons(theme)
	_labels(theme)
	_sliders(theme)
	return theme


## A window: surface-window, white frame, soft shadow.
static func window_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = UiTokens.color(&"surface-window")
	style.border_color = UiTokens.color(&"border-window")
	style.set_border_width_all(UiTokens.BORDER_3)
	style.set_corner_radius_all(UiTokens.RADIUS_M)
	style.content_margin_left = UiTokens.SPACE_4
	style.content_margin_right = UiTokens.SPACE_4
	style.content_margin_top = UiTokens.SPACE_3
	style.content_margin_bottom = UiTokens.SPACE_3
	style.shadow_color = UiTokens.SHADOW_COLOR
	style.shadow_size = UiTokens.SHADOW_SIZE
	style.shadow_offset = UiTokens.SHADOW_OFFSET
	return style


static func map_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = UiTokens.color(&"surface-map")
	style.border_color = UiTokens.color(&"border-map")
	style.set_border_width_all(UiTokens.BORDER_2)
	style.set_corner_radius_all(UiTokens.RADIUS_S)
	return style


## Background of the chosen row (MenuCursor paints it at the row's size, so no margins).
static func selected_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = UiTokens.color(&"surface-selected")
	style.set_corner_radius_all(UiTokens.RADIUS_S)
	return style


## Status badge: status is &"status-poison", &"status-sleep", &"status-silence" or &"status-stun".
static func badge_style(status: StringName) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = UiTokens.color(status)
	style.set_corner_radius_all(UiTokens.RADIUS_S)
	style.content_margin_left = UiTokens.SPACE_2
	style.content_margin_right = UiTokens.SPACE_2
	return style


## The font of a type style: family, weight and (display only) line height trimmed.
static func font_for(style: StringName) -> Font:
	if _fonts.has(style):
		return _fonts[style]
	var spec: Array = UiTokens.TYPE[style]
	var size: int = spec[0]
	var is_display: bool = spec[2] == UiTokens.FAMILY_DISPLAY
	var path := UiTokens.FONT_DISPLAY_PATH if is_display else UiTokens.FONT_UI_PATH
	var result := font(path, spec[1])
	if is_display and result is FontVariation:
		var variation := result as FontVariation
		# Own copy, so the trim of one style never reaches another that shares the weight.
		var trimmed := FontVariation.new()
		trimmed.base_font = variation.base_font
		trimmed.variation_opentype = variation.variation_opentype
		var trim := -roundi((trimmed.base_font.get_height(size) - size * float(spec[3])) / 2.0)
		trimmed.spacing_top = trim
		trimmed.spacing_bottom = trim
		result = trimmed
	_fonts[style] = result
	return result


## A variable font at a weight; the engine's own if the file is missing. Cached.
static func font(path: String, weight: int) -> Font:
	var key := "%s:%d" % [path, weight]
	if _fonts.has(key):
		return _fonts[key]
	var base: FontFile = null
	if ResourceLoader.exists(path):
		base = load(path) as FontFile
	var result: Font = ThemeDB.fallback_font
	if base != null:
		var variation := FontVariation.new()
		variation.base_font = base
		var tag := TextServerManager.get_primary_interface().name_to_tag("wght")
		variation.variation_opentype = {tag: weight}
		result = variation
	_fonts[key] = result
	return result


## Left gap of a menu row, for whoever has to leave it by hand (Opciones' rows).
static func row_indent() -> int:
	if Device.is_touch():
		return UiTokens.SPACE_1 + UiTokens.CURSOR_SIZE + UiTokens.SPACE_1
	return UiTokens.SPACE_2 + UiTokens.CURSOR_SIZE + UiTokens.SPACE_2


## Sets font, size, colour and outline of one label as overrides.
static func style_label(label: Label, style: StringName, color: StringName, outline := 0,
		outline_color := &"text-outline") -> Label:
	label.add_theme_font_override(&"font", font_for(style))
	label.add_theme_font_size_override(&"font_size", UiTokens.type_size(style))
	label.add_theme_color_override(&"font_color", UiTokens.color(color))
	if outline > 0:
		label.add_theme_constant_override(&"outline_size", outline)
		label.add_theme_color_override(&"font_outline_color", UiTokens.color(outline_color))
	return label


## Same for a Label3D. The caller adjusts pixel_size.
static func style_3d(label: Label3D, style: StringName, color: StringName, outline: int,
		outline_color := &"text-outline") -> Label3D:
	label.font = font_for(style)
	label.font_size = UiTokens.type_size(style)
	label.modulate = UiTokens.color(color)
	label.outline_size = outline
	label.outline_modulate = UiTokens.color(outline_color)
	return label


## A menu row: a Button the theme draws flat, finger-sized on a phone; the mouse moves the selection.
static func menu_row(button: Button) -> Button:
	button.flat = false
	UiStyle.fit_finger(button)
	button.mouse_entered.connect(func() -> void:
		if not button.disabled and button.focus_mode != Control.FOCUS_NONE \
				and button.is_visible_in_tree() and not button.has_focus():
			button.grab_focus())
	return button


## Filled in by MenuCursor (A4).
static func add_cursor(_window: Control) -> void:
	pass


static func _variation(theme: Theme, type: StringName, base: StringName) -> void:
	theme.set_type_variation(type, base)


## Vertical padding that makes a row ROW_HEIGHT (desktop) or TOUCH_TARGET (phone) tall.
static func _row_pad() -> float:
	var height := float(UiTokens.TOUCH_TARGET if Device.is_touch() else UiTokens.ROW_HEIGHT)
	var text := font_for(&"body").get_height(UiTokens.TYPE_BODY_SIZE)
	return maxf(0.0, (height - text) / 2.0)


## An empty box with the given side margins and the row's vertical padding.
static func _empty(left: float, right: float) -> StyleBoxEmpty:
	var box := StyleBoxEmpty.new()
	box.content_margin_left = left
	box.content_margin_right = right
	box.content_margin_top = _row_pad()
	box.content_margin_bottom = _row_pad()
	return box


static func row_style() -> StyleBoxEmpty:
	var right := UiTokens.SPACE_1 if Device.is_touch() else UiTokens.SPACE_2
	return _empty(float(row_indent()), float(right))


static func _rows(theme: Theme) -> void:
	for box_name in [&"normal", &"hover", &"pressed", &"disabled"]:
		theme.set_stylebox(box_name, &"Button", row_style())
	theme.set_stylebox(&"focus", &"Button", StyleBoxEmpty.new())
	theme.set_color(&"font_color", &"Button", UiTokens.color(&"text-primary"))
	theme.set_color(&"font_hover_color", &"Button", UiTokens.color(&"text-primary"))
	theme.set_color(&"font_focus_color", &"Button", UiTokens.color(&"text-primary"))
	theme.set_color(&"font_pressed_color", &"Button", UiTokens.color(&"text-accent"))
	theme.set_color(&"font_disabled_color", &"Button", UiTokens.color(&"text-disabled"))
	theme.set_constant(&"h_separation", &"Button", UiTokens.SPACE_2)


## A frame only (no fill), so it does not matter whether the engine draws it before the text.
static func _frame() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.draw_center = false
	box.border_color = UiTokens.color(&"border-focus")
	box.set_border_width_all(UiTokens.BORDER_2)
	box.set_corner_radius_all(UiTokens.RADIUS_S)
	return box


static func _buttons(theme: Theme) -> void:
	var side := float(UiTokens.SPACE_1)
	# SELECTOR: a small tab; the chosen one is filled.
	_variation(theme, SELECTOR, &"Button")
	var plain := _empty(UiTokens.SPACE_2, UiTokens.SPACE_2)
	for box_name in [&"normal", &"hover", &"focus", &"disabled"]:
		theme.set_stylebox(box_name, SELECTOR, plain)
	var chosen := StyleBoxFlat.new()
	chosen.bg_color = UiTokens.color(&"border-focus")
	chosen.set_corner_radius_all(UiTokens.RADIUS_S)
	chosen.content_margin_left = UiTokens.SPACE_2
	chosen.content_margin_right = UiTokens.SPACE_2
	chosen.content_margin_top = _row_pad()
	chosen.content_margin_bottom = _row_pad()
	theme.set_stylebox(&"pressed", SELECTOR, chosen)
	theme.set_stylebox(&"hover_pressed", SELECTOR, chosen)
	theme.set_font(&"font", SELECTOR, font_for(&"caption"))
	theme.set_font_size(&"font_size", SELECTOR, UiTokens.TYPE_CAPTION_SIZE)
	theme.set_color(&"font_pressed_color", SELECTOR, UiTokens.color(&"surface-window-solid"))
	theme.set_color(&"font_hover_pressed_color", SELECTOR, UiTokens.color(&"surface-window-solid"))
	# KEY and CARD_HIT: no gap for the cursor; focus is a frame.
	for type in [KEY, CARD_HIT]:
		_variation(theme, type, &"Button")
		var key_box := _empty(side, side)
		for box_name in [&"normal", &"hover", &"pressed", &"disabled"]:
			theme.set_stylebox(box_name, type, key_box)
		theme.set_stylebox(&"focus", type, _frame())
	theme.set_font(&"font", KEY, font_for(&"body"))
	theme.set_font_size(&"font_size", KEY, UiTokens.TYPE_BODY_SIZE)
	# MENU_BUTTON: the hamburger, a small window.
	_variation(theme, MENU_BUTTON, &"Button")
	var menu := window_style()
	menu.set_content_margin_all(0)
	var menu_on := menu.duplicate() as StyleBoxFlat
	menu_on.bg_color = UiTokens.color(&"surface-window-solid")
	theme.set_stylebox(&"normal", MENU_BUTTON, menu)
	theme.set_stylebox(&"hover", MENU_BUTTON, menu_on)
	theme.set_stylebox(&"pressed", MENU_BUTTON, menu_on)
	theme.set_stylebox(&"focus", MENU_BUTTON, StyleBoxEmpty.new())
	# ACTION_BUTTON: a pill.
	_variation(theme, ACTION_BUTTON, &"Button")
	var pill := window_style()
	pill.set_corner_radius_all(UiTokens.RADIUS_FULL)
	pill.content_margin_top = _row_pad()
	pill.content_margin_bottom = _row_pad()
	var pill_on := pill.duplicate() as StyleBoxFlat
	pill_on.bg_color = UiTokens.color(&"surface-window-solid")
	theme.set_stylebox(&"normal", ACTION_BUTTON, pill)
	theme.set_stylebox(&"hover", ACTION_BUTTON, pill_on)
	theme.set_stylebox(&"pressed", ACTION_BUTTON, pill_on)
	theme.set_stylebox(&"focus", ACTION_BUTTON, StyleBoxEmpty.new())
	theme.set_font(&"font", ACTION_BUTTON, font_for(&"title-s"))
	theme.set_font_size(&"font_size", ACTION_BUTTON, UiTokens.TYPE_TITLE_S_SIZE)
	theme.set_color(&"font_pressed_color", ACTION_BUTTON, UiTokens.color(&"text-accent"))


static func _labels(theme: Theme) -> void:
	theme.set_color(&"font_color", &"Label", UiTokens.color(&"text-primary"))
	_label(theme, TITLE, &"title-s", &"text-accent")
	_label(theme, SECTION, &"label", &"text-accent")
	_label(theme, SMALL, &"label", &"text-primary")
	_label(theme, CAPTION, &"caption", &"text-secondary")
	_label(theme, NOTE, &"caption", &"text-primary")
	_label(theme, REASON, &"caption", &"text-disabled")
	_label(theme, MONEY, &"body", &"text-money")
	_label(theme, POSITIVE, &"body", &"text-positive")
	_label(theme, NEGATIVE, &"body", &"text-negative")
	_label(theme, BADGE, &"micro", &"text-on-fill")
	_label(theme, MICRO, &"micro", &"text-secondary")
	_label(theme, OUTLINED, &"caption", &"text-primary", UiTokens.OUTLINE_M, &"text-outline")
	_label(theme, DISPLAY, &"display-m", &"text-display", UiTokens.OUTLINE_L, &"text-outline-warm")
	_label(theme, DISPLAY_SUB, &"title-m", &"text-display", UiTokens.OUTLINE_L, &"text-outline-warm")


static func _label(theme: Theme, type: StringName, style: StringName, color: StringName,
		outline := 0, outline_color := &"text-outline") -> void:
	theme.set_type_variation(type, &"Label")
	theme.set_font(&"font", type, font_for(style))
	theme.set_font_size(&"font_size", type, UiTokens.type_size(style))
	theme.set_color(&"font_color", type, UiTokens.color(color))
	if outline > 0:
		theme.set_constant(&"outline_size", type, outline)
		theme.set_color(&"font_outline_color", type, UiTokens.color(outline_color))


static func _sliders(theme: Theme) -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = UiTokens.color(&"surface-track")
	track.set_corner_radius_all(UiTokens.RADIUS_S)
	track.content_margin_top = UiTokens.SPACE_1
	track.content_margin_bottom = UiTokens.SPACE_1
	var fill := track.duplicate() as StyleBoxFlat
	fill.bg_color = UiTokens.color(&"border-focus")
	theme.set_stylebox(&"slider", &"HSlider", track)
	theme.set_stylebox(&"grabber_area", &"HSlider", fill)
	theme.set_stylebox(&"grabber_area_highlight", &"HSlider", fill)
	theme.set_stylebox(&"focus", &"HSlider", StyleBoxEmpty.new())
