class_name KeyMap extends RefCounted
## The keyboard actions of the game (their defaults are in project.godot) and the rules for
## reassigning them. Reassigning replaces an action's first key and keeps the others, so the
## arrows or E stay until they are reassigned themselves. A key belongs to one action: taking
## it from another is refused if it is that action's only key. Only what the player changed
## goes in GameOptions.keys. The built-in ui_* actions follow these, so the menus take the
## same keys. Pure: only touches the InputMap singleton.

const MOVE_UP := "move_up"
const MOVE_DOWN := "move_down"
const MOVE_LEFT := "move_left"
const MOVE_RIGHT := "move_right"
const ACCEPT := "accept"
const CANCEL := "cancel"
const PAUSE := "pause"
const ACTIONS: Array[String] = [MOVE_UP, MOVE_DOWN, MOVE_LEFT, MOVE_RIGHT, ACCEPT, CANCEL, PAUSE]
## What the Teclas page calls each action.
const NAMES := {MOVE_UP: "Arriba", MOVE_DOWN: "Abajo", MOVE_LEFT: "Izquierda",
	MOVE_RIGHT: "Derecha", ACCEPT: "Aceptar", CANCEL: "Cancelar", PAUSE: "Pausa"}
## The built-in action that follows each one.
const UI_ACTIONS := {MOVE_UP: "ui_up", MOVE_DOWN: "ui_down", MOVE_LEFT: "ui_left",
	MOVE_RIGHT: "ui_right", ACCEPT: "ui_accept", CANCEL: "ui_cancel"}
const ONLY_KEY := "Esa tecla es la única de «%s»."


## The project's keys, with the player's changes over them.
static func apply(overrides: Dictionary) -> void:
	InputMap.load_from_project_settings()
	for action: String in overrides:
		_set_keys(action, overrides[action])
	_follow_in_menus()


## Gives code to action in overrides and on the InputMap. Returns why it can't ("" if done).
static func assign(overrides: Dictionary, action: String, code: int) -> String:
	for other in ACTIONS:
		if other != action and keys_of(other) == [code]:
			return ONLY_KEY % NAMES[other]
	for other in ACTIONS:
		var keys := keys_of(other)
		if other != action and code in keys:
			keys.erase(code)
			overrides[other] = keys
			_set_keys(other, keys)
	var mine := keys_of(action)
	if code in mine:
		mine.erase(code)
		mine.push_front(code)
	else:
		mine[0] = code
	overrides[action] = mine
	_set_keys(action, mine)
	_follow_in_menus()
	return ""


## The key codes of action, first one first.
static func keys_of(action: String) -> Array[int]:
	var codes: Array[int] = []
	for event in InputMap.action_get_events(action):
		var key := event as InputEventKey
		if key != null:
			codes.append(int(key.physical_keycode))
	return codes


## "W, Up", for the Teclas page.
static func keys_text(action: String) -> String:
	var names := PackedStringArray()
	for code in keys_of(action):
		names.append(_key_name(code))
	return ", ".join(names)


## What the key at that physical position says on the player's keyboard layout.
static func _key_name(code: int) -> String:
	if OS.has_feature("web") or DisplayServer.get_name() == "headless":
		return OS.get_keycode_string(code)  # the web and headless runs can't tell
	return OS.get_keycode_string(DisplayServer.keyboard_get_keycode_from_physical(code as Key))


static func _set_keys(action: String, codes: Array) -> void:
	InputMap.action_erase_events(action)
	for code: Variant in codes:
		var event := InputEventKey.new()
		event.physical_keycode = int(code) as Key
		InputMap.action_add_event(action, event)


static func _follow_in_menus() -> void:
	for action: String in UI_ACTIONS:
		var ui: String = UI_ACTIONS[action]
		for event in InputMap.action_get_events(ui):
			if event is InputEventKey:
				InputMap.action_erase_event(ui, event)
		for event in InputMap.action_get_events(action):
			InputMap.action_add_event(ui, event)
