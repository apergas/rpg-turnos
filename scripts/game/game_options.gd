class_name GameOptions extends RefCounted
## Player options, kept apart from the save game (SaveStore.save_options()): music
## and effects volume (0..1) and text speed. Pure: converts to and from a Dictionary.

enum TextSpeed { SLOW, NORMAL, FAST }

const DEFAULT_MUSIC := 0.7
const DEFAULT_SFX := 0.8
## Seconds per typed character in the battle messages, per TextSpeed.
const CHAR_TIMES := [0.05, 0.025, 0.008]
const SPEED_NAMES := ["Lenta", "Normal", "Rápida"]

var music_volume := DEFAULT_MUSIC
var sfx_volume := DEFAULT_SFX
var text_speed := TextSpeed.NORMAL


func char_time() -> float:
	return CHAR_TIMES[text_speed]


func to_dict() -> Dictionary:
	return {"music": music_volume, "sfx": sfx_volume, "text_speed": text_speed}


## Options from a Dictionary read from disk; missing or wrong values keep the default.
static func from_dict(data: Dictionary) -> GameOptions:
	var options := GameOptions.new()
	if data.get("music") is float:
		options.music_volume = clampf(data.music, 0.0, 1.0)
	if data.get("sfx") is float:
		options.sfx_volume = clampf(data.sfx, 0.0, 1.0)
	if data.get("text_speed") is float:
		options.text_speed = clampi(int(data.text_speed), TextSpeed.SLOW, TextSpeed.FAST) \
			as TextSpeed
	return options
