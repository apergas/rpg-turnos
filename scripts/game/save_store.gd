class_name SaveStore extends RefCounted
## Reads and writes the save game and the options as JSON under user://. On the web
## Godot keeps user:// in the browser (IndexedDB), and a file is stored when it is
## closed. Three slots, user://save_1.json to save_3.json; the single save.json of 1.2 and
## older moves to slot 1 the first time the title opens (migrate_legacy(); on the web, if the
## removal of the old file did not reach IndexedDB, slot 1 already exists on reload and it is
## not copied again). Runs with `-- --autoplay` use their own save file, so they never
## overwrite the player's game.

## Number of save slots on the title screen.
const SLOT_COUNT := 3
## Slot n's file (n from 1 to SLOT_COUNT).
const SLOT_PATH := "user://save_%d.json"
## The single save of 1.2 and older: migrate_legacy() moves it to slot 1.
const LEGACY_SAVE_PATH := "user://save.json"
const AUTOPLAY_SAVE_PATH := "user://save_autoplay.json"
const OPTIONS_PATH := "user://options.json"

## What a slot holds.
enum SlotKind { EMPTY, DAMAGED, USABLE }


## The file of slot (autoplay runs always use their own, whatever the slot).
static func save_path(slot: int) -> String:
	if OS.get_cmdline_user_args().has("--autoplay"):
		return AUTOPLAY_SAVE_PATH
	return SLOT_PATH % clampi(slot, 1, SLOT_COUNT)


static func has_save(slot: int) -> bool:
	return FileAccess.file_exists(save_path(slot))


## True if the file was written.
static func save_game(slot: int, data: Dictionary) -> bool:
	return _write(save_path(slot), data)


## The saved Dictionary, or an empty one if there is no save or it can't be read.
static func load_game(slot: int) -> Dictionary:
	return _read(save_path(slot))


## The file's text as it is (what Exportar copies), "" if there is none.
static func slot_text(slot: int) -> String:
	if not has_save(slot):
		return ""
	return FileAccess.get_file_as_string(save_path(slot))


## {"kind": SlotKind, "save": the Dictionary, empty unless USABLE}.
static func slot_info(slot: int) -> Dictionary:
	if not has_save(slot):
		return {"kind": SlotKind.EMPTY, "save": {}}
	var save := load_game(slot)
	if not SaveData.is_valid(save):
		return {"kind": SlotKind.DAMAGED, "save": {}}
	return {"kind": SlotKind.USABLE, "save": save}


## True if some slot holds a save Continuar can load.
static func any_usable() -> bool:
	for slot in range(1, SLOT_COUNT + 1):
		if slot_info(slot).kind == SlotKind.USABLE:
			return true
	return false


## True if no slot has a file at all.
static func all_empty() -> bool:
	for slot in range(1, SLOT_COUNT + 1):
		if has_save(slot):
			return false
	return true


## Moves the save of 1.2 and older to slot 1 as it is (a damaged file stays damaged), once:
## never on autoplay runs, and never over a slot 1 that already has a file.
static func migrate_legacy() -> void:
	if OS.get_cmdline_user_args().has("--autoplay"):
		return
	var slot_1 := SLOT_PATH % 1
	if not FileAccess.file_exists(LEGACY_SAVE_PATH) or FileAccess.file_exists(slot_1):
		return
	var text := FileAccess.get_file_as_string(LEGACY_SAVE_PATH)
	var file := FileAccess.open(slot_1, FileAccess.WRITE)
	if file == null:
		push_warning("No se pudo pasar la partida a la ranura 1 (error %d)"
			% FileAccess.get_open_error())
		return
	var ok := file.store_string(text)
	file.close()
	if ok:
		DirAccess.remove_absolute(LEGACY_SAVE_PATH)


static func save_options(options: GameOptions) -> bool:
	return _write(OPTIONS_PATH, options.to_dict())


## Saved options, or the defaults.
static func load_options() -> GameOptions:
	var data := _read(OPTIONS_PATH)
	var options := GameOptions.from_dict(data)
	if Device.is_touch() and not data.has("quality"):
		options.quality = GameOptions.Quality.LOW
	return options


static func _write(path: String, data: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("No se pudo guardar %s (error %d)" % [path, FileAccess.get_open_error()])
		return false
	var ok := file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return ok


static func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return {}
	return json.data if json.data is Dictionary else {}
