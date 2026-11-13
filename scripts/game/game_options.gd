class_name GameOptions extends RefCounted
## Player options, kept apart from the save game (SaveStore.save_options()): music and
## effects volume (0..1), text speed, combat speed, graphics quality, camera shake,
## fullscreen, large text and whether the phone's walking hint was shown. Pure: converts to and from a Dictionary; anything missing from
## an older file keeps its default.

enum TextSpeed { SLOW, NORMAL, FAST }
enum CombatSpeed { X1, X2, INSTANT }
enum Quality { HIGH, LOW }

const DEFAULT_MUSIC := 0.7
const DEFAULT_SFX := 0.8
## Seconds per typed character in the battle messages, per TextSpeed.
const CHAR_TIMES := [0.05, 0.025, 0.008]
const SPEED_NAMES := ["Lenta", "Normal", "Rápida"]
const COMBAT_NAMES := ["x1", "x2", "Instantáneo"]
const QUALITY_NAMES := ["Alta", "Baja"]
## How fast a battle runs (Engine.time_scale), per CombatSpeed; INSTANT also skips the typing.
const COMBAT_SCALES := [1.0, 2.0, 2.0]
## Large text: everything in the windows grows by this much.
const LARGE_TEXT_SCALE := 1.25

var music_volume := DEFAULT_MUSIC
var sfx_volume := DEFAULT_SFX
var text_speed := TextSpeed.NORMAL
var combat_speed := CombatSpeed.X1
var quality := Quality.HIGH
var camera_shake := true
var fullscreen := false
var large_text := false
## High contrast palette of the menus (UiTokens.ALTO_CONTRASTE).
var high_contrast := false
## The phone's line on how to walk was shown once (World.show_touch_hint()).
var touch_hint_seen := false
## What the player reassigned: KeyMap action -> key codes.
var keys := {}


## Seconds per typed character of the battle messages; 0.0 shows them at once.
func char_time() -> float:
	if combat_speed == CombatSpeed.INSTANT:
		return 0.0
	return CHAR_TIMES[text_speed]


func combat_scale() -> float:
	return COMBAT_SCALES[combat_speed]


func to_dict() -> Dictionary:
	return {"music": music_volume, "sfx": sfx_volume, "text_speed": text_speed,
		"combat_speed": combat_speed, "quality": quality, "camera_shake": camera_shake,
		"fullscreen": fullscreen, "large_text": large_text, "high_contrast": high_contrast,
		"touch_hint_seen": touch_hint_seen,
		"keys": keys}


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
	if data.get("combat_speed") is float:
		options.combat_speed = clampi(int(data.combat_speed), CombatSpeed.X1,
			CombatSpeed.INSTANT) as CombatSpeed
	if data.get("quality") is float:
		options.quality = clampi(int(data.quality), Quality.HIGH, Quality.LOW) as Quality
	if data.get("camera_shake") is bool:
		options.camera_shake = data.camera_shake
	if data.get("fullscreen") is bool:
		options.fullscreen = data.fullscreen
	if data.get("large_text") is bool:
		options.large_text = data.large_text
	if data.get("high_contrast") is bool:
		options.high_contrast = data.high_contrast
	if data.get("touch_hint_seen") is bool:
		options.touch_hint_seen = data.touch_hint_seen
	options.keys = _valid_keys(data.get("keys"))
	return options


## Only known actions with at least one key, and every key a number.
static func _valid_keys(saved: Variant) -> Dictionary:
	var valid := {}
	if not saved is Dictionary:
		return valid
	for action: Variant in saved:
		var codes: Variant = saved[action]
		if action in KeyMap.ACTIONS and codes is Array and not codes.is_empty() \
				and codes.all(func(code: Variant) -> bool: return code is float):
			valid[action] = codes
	return valid
