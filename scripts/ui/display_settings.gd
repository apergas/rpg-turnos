class_name DisplaySettings extends RefCounted
## Puts into effect the options that live outside the rules: the size of everything in the
## windows, fullscreen (desktop only) and the graphics quality the map and battle builders
## read when they build their next scene. TitleScreen calls it at the start, OptionsPanel at
## each change.


static func apply(window: Window, options: GameOptions) -> void:
	window.content_scale_factor = GameOptions.LARGE_TEXT_SCALE if options.large_text else 1.0
	if not OS.has_feature("web"):
		var is_fullscreen := window.mode == Window.MODE_FULLSCREEN
		if is_fullscreen != options.fullscreen:
			window.mode = Window.MODE_FULLSCREEN if options.fullscreen else Window.MODE_WINDOWED
	var low := options.quality == GameOptions.Quality.LOW
	Vegetation.half_density = low
	BattleStage.plain_light = low
