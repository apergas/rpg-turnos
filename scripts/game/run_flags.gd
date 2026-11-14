class_name RunFlags extends RefCounted
## The flags given after `--` on the command line (`godot --path . -- --autoplay ...`), read
## once from OS.get_cmdline_user_args() and kept in a static var. The only script of the game
## that reads the command line (the offline tools of scripts/tools/ read their own). The web
## build gets none, so every flag is off there. The autoplay sub-flags (save, menu, easy)
## only count with --autoplay.

const AUTOPLAY := "--autoplay"
const AUTOPLAY_SAVE := "--autoplay-save"
const AUTOPLAY_MENU := "--autoplay-menu"
const AUTOPLAY_EASY := "--autoplay-easy"
const AUTOPLAY_ZONE := "--autoplay-zone="
const AUTOPLAY_COMPANION := "--autoplay-companion="
const DEBUG := "--debug"
const TOUCH := "--touch"

static var _args := PackedStringArray()
static var _read := false


## --autoplay: a new game that plays by itself (no title menu, its own save file).
static func autoplay() -> bool:
	return _has(AUTOPLAY)


## --autoplay-save (with --autoplay): prints the save written and the save loaded.
static func autoplay_save() -> bool:
	return autoplay() and _has(AUTOPLAY_SAVE)


## --autoplay-menu (with --autoplay): tours the pause menu once the map is up.
static func autoplay_menu() -> bool:
	return autoplay() and _has(AUTOPLAY_MENU)


## --autoplay-easy (with --autoplay): the new game is on Fácil.
static func autoplay_easy() -> bool:
	return autoplay() and _has(AUTOPLAY_EASY)


## --autoplay-zone=<id>: the start Game uses for a new autoplay game ("" when absent).
static func autoplay_zone() -> String:
	return _value(AUTOPLAY_ZONE)


## --autoplay-companion=<id>: the companion of an autoplay start ("" when absent; Game keeps
## its own default and checks the id).
static func autoplay_companion() -> String:
	return _value(AUTOPLAY_COMPANION)


## --debug: Game builds its DebugPanel (F1 on the map).
static func debug() -> bool:
	return _has(DEBUG)


## --touch: the desktop fakes a phone (Device.is_touch()), the mouse acting as a finger.
static func touch() -> bool:
	return _has(TOUCH)


static func _all() -> PackedStringArray:
	if not _read:
		_args = OS.get_cmdline_user_args()
		_read = true
	return _args


static func _has(flag: String) -> bool:
	return _all().has(flag)


## The text after prefix of the first argument that starts with it, or "".
static func _value(prefix: String) -> String:
	for arg in _all():
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix)
	return ""
