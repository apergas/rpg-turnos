class_name UiTheme extends DsTheme
## Constructor: static; Villaclaro's theme: the design system core's DsTheme plus the game's own
## part (the map window, the gold display labels, the status badges, the version label). Its
## only state is DsTheme's: the fonts and the theme applied, and DsTheme.touch, which it writes.
## The screens call everything through UiTheme (UiTheme.menu_row(), UiTheme.CAPTION...): the
## generic part comes from DsTheme. apply(), ensure() and build() keep DsTheme's signatures
## (GDScript checks a redefined static function against its parent's), tell DsTheme whether
## the game runs on a phone and hand it _extend().

## Gold labels in the display font with the warm outline: the place banner and its second line.
const DISPLAY := &"DisplayLabel"
const DISPLAY_SUB := &"DisplaySubLabel"
## The map's square: a lighter window that lets the world through.
const WINDOW_MAP := &"MapWindow"


## Puts the theme on (again only if high_contrast changed). DisplaySettings.apply() calls it.
static func apply(window: Window, high_contrast := false, extend := Callable()) -> void:
	DsTheme.touch = Device.is_touch()
	DsTheme.apply(window, high_contrast, _extend if extend.is_null() else extend)


## The scenes that run on their own (no title before them) put the theme on once.
static func ensure(window: Window, extend := Callable()) -> void:
	DsTheme.touch = Device.is_touch()
	DsTheme.ensure(window, _extend if extend.is_null() else extend)


## DsTheme's Theme with Villaclaro's part.
static func build(extend := Callable()) -> Theme:
	return DsTheme.build(_extend if extend.is_null() else extend)


static func map_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = UiTokens.color(&"surface-map")
	style.border_color = UiTokens.color(&"border-map")
	style.set_border_width_all(UiTokens.BORDER_2)
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


## The game's version ("v3.7.0") in caption, text-primary, with the warm outline, added to
## parent (a full-screen Control) in its bottom right corner, SPACE_3 in: the title screen and
## the pause menu show it the same way. A Label never takes the mouse.
static func version_label(parent: Control) -> Label:
	var label := Label.new()
	label.text = "v%s" % GameVersion.current()
	style_label(label, &"caption", &"text-primary", UiTokens.OUTLINE_S, &"text-outline-warm")
	parent.add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT,
		Control.PRESET_MODE_MINSIZE, UiTokens.SPACE_3)
	return label


## Villaclaro's part of the Theme; DsTheme.build() calls it with the Theme it builds.
static func _extend(theme: Theme) -> void:
	_variation(theme, WINDOW_MAP, &"PanelContainer")
	theme.set_stylebox(&"panel", WINDOW_MAP, map_style())
	_label(theme, DISPLAY, &"display-m", &"text-display", UiTokens.OUTLINE_L, &"text-outline-warm")
	_label(theme, DISPLAY_SUB, &"title-m", &"text-display", UiTokens.OUTLINE_L, &"text-outline-warm")
