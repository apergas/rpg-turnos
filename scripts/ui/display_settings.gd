class_name DisplaySettings extends RefCounted
## Puts into effect the options that live outside the rules: the size of everything in the
## windows, fullscreen (desktop only) and the graphics quality the map and battle builders
## read when they build their next scene. TitleScreen calls it at the start, OptionsPanel at
## each change.


const TOUCH_SCALE := 1.35
const TOUCH_LARGE_SCALE := 1.6
const TOUCH_3D_HIGH := 0.8
const TOUCH_3D_LOW := 0.6
const TOUCH_LOW_FPS := 30
## Height a button with a 24 font reaches on a phone.
const TOUCH_BUTTON_HEIGHT := 56.0
const BUTTON_FONT := 24.0
const BUTTON_STYLES := ["normal", "hover", "pressed", "focus", "disabled"]


static func apply(window: Window, options: GameOptions) -> void:
	window.title = ProjectSettings.get_setting("application/config/name")
	window.content_scale_factor = GameOptions.LARGE_TEXT_SCALE if options.large_text else 1.0
	if Device.is_touch():
		_apply_touch(window, options)
	if not OS.has_feature("web"):
		var is_fullscreen := window.mode == Window.MODE_FULLSCREEN
		if is_fullscreen != options.fullscreen:
			window.mode = Window.MODE_FULLSCREEN if options.fullscreen else Window.MODE_WINDOWED
	var low := options.quality == GameOptions.Quality.LOW
	Vegetation.half_density = low
	BattleStage.plain_light = low


## Phone: bigger windows, a lower 3D resolution and frame rate on low quality, taller buttons.
static func _apply_touch(window: Window, options: GameOptions) -> void:
	var low := options.quality == GameOptions.Quality.LOW
	window.content_scale_factor = TOUCH_LARGE_SCALE if options.large_text else TOUCH_SCALE
	window.scaling_3d_scale = TOUCH_3D_LOW if low else TOUCH_3D_HIGH
	Engine.max_fps = TOUCH_LOW_FPS if low else 0
	if OS.get_cmdline_user_args().has("--touch"):
		Input.emulate_touch_from_mouse = true
	if window.theme == null:
		window.theme = _touch_theme()


## A theme whose buttons are taller; the window's theme reaches every control under it.
static func _touch_theme() -> Theme:
	var theme := Theme.new()
	var default := ThemeDB.get_default_theme()
	var font := default.get_default_font()
	var text_height := font.get_height(int(BUTTON_FONT))
	for style_name: String in BUTTON_STYLES:
		var box := default.get_stylebox(style_name, "Button").duplicate() as StyleBox
		var extra := maxf(0.0, (TOUCH_BUTTON_HEIGHT - text_height) / 2.0)
		box.content_margin_top = extra
		box.content_margin_bottom = extra
		theme.set_stylebox(style_name, "Button", box)
	# No keyboard to follow, and a scroll list would clip the border anyway.
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	return theme
