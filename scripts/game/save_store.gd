class_name SaveStore extends RefCounted
## Reads and writes the save game and the options as JSON under user://. On the web
## Godot keeps user:// in the browser (IndexedDB), and a file is stored when it is
## closed. Three slots, user://save_1.json to save_3.json; the single save.json of 1.2 and
## older moves to slot 1 the first time the title opens (migrate_legacy(); on the web, if the
## removal of the old file did not reach IndexedDB, slot 1 already exists on reload and it is
## not copied again). Runs with `-- --autoplay` use their own save file, so they never
## overwrite the player's game.
## Off the web every file is written to <file>.tmp and renamed over the old one
## (_write()); recover_writes() mends a write cut between the two.

## Number of save slots on the title screen.
const SLOT_COUNT := 3
## Slot n's file (n from 1 to SLOT_COUNT).
const SLOT_PATH := "user://save_%d.json"
## The single save of 1.2 and older: migrate_legacy() moves it to slot 1.
const LEGACY_SAVE_PATH := "user://save.json"
const AUTOPLAY_SAVE_PATH := "user://save_autoplay.json"
const OPTIONS_PATH := "user://options.json"
## What _write() adds to a file's path for the text it writes before renaming it (off the web).
const TEMP_SUFFIX := ".tmp"

## What a slot holds.
enum SlotKind { EMPTY, DAMAGED, USABLE }


## The file of slot (autoplay runs always use their own, whatever the slot).
static func save_path(slot: int) -> String:
	if RunFlags.autoplay():
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


## {"kind": SlotKind, "save": the Dictionary, empty unless USABLE, "newer": true for a DAMAGED
## file saved by a newer version (SaveData.is_newer())}.
static func slot_info(slot: int) -> Dictionary:
	if not has_save(slot):
		return {"kind": SlotKind.EMPTY, "save": {}, "newer": false}
	var save := load_game(slot)
	if not SaveData.is_valid(save):
		return {"kind": SlotKind.DAMAGED, "save": {}, "newer": SaveData.is_newer(save)}
	return {"kind": SlotKind.USABLE, "save": save, "newer": false}


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
	if RunFlags.autoplay():
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


## A rename over a file may remove the old one first (Windows): a write cut right between the
## two leaves only the .tmp, already whole, which becomes the file again. A .tmp beside its file
## was cut before the rename, maybe halfway: it stays, and the next save writes over it. A lone
## .tmp is promoted only if it parses as a Dictionary; otherwise it is removed (a crash during the
## first write to an empty slot leaves the slot empty, not damaged). Never on
## autoplay runs (their own file) nor on the web (no .tmp there). The title calls it first.
static func recover_writes() -> void:
	if RunFlags.autoplay() or OS.has_feature("web"):
		return
	var paths: Array[String] = [OPTIONS_PATH]
	for slot in range(1, SLOT_COUNT + 1):
		paths.append(SLOT_PATH % slot)
	for path in paths:
		if not FileAccess.file_exists(path) and FileAccess.file_exists(path + TEMP_SUFFIX):
			_promote_temp(path)


## Renames path's lone .tmp over it if it holds a whole JSON object, else removes it.
static func _promote_temp(path: String) -> void:
	var temp := path + TEMP_SUFFIX
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(temp)) == OK and json.data is Dictionary:
		var error := DirAccess.rename_absolute(temp, path)
		if error != OK:
			push_warning("No se pudo recuperar %s (error %d)" % [path, error])
	else:
		DirAccess.remove_absolute(temp)


static func save_options(options: GameOptions) -> bool:
	return _write(OPTIONS_PATH, options.to_dict())


## Saved options, or the defaults.
static func load_options() -> GameOptions:
	var data := _read(OPTIONS_PATH)
	var options := GameOptions.from_dict(data)
	if Device.is_touch() and not data.has("quality"):
		options.quality = GameOptions.Quality.LOW
	return options


## Off the web the text goes to path + TEMP_SUFFIX, which is closed and renamed over path, so a
## crash mid-write leaves the old file whole. On the web user:// is IndexedDB, stored when a file
## closes and not on a rename: there the file is written in place, as before 3.8.2.
static func _write(path: String, data: Dictionary) -> bool:
	var target := path if OS.has_feature("web") else path + TEMP_SUFFIX
	var file := FileAccess.open(target, FileAccess.WRITE)
	if file == null:
		push_warning("No se pudo guardar %s (error %d)" % [path, FileAccess.get_open_error()])
		return false
	var ok := file.store_string(JSON.stringify(data, "\t"))
	file.close()
	if not ok or target == path:
		return ok
	var error := DirAccess.rename_absolute(target, path)
	if error != OK:
		push_warning("No se pudo guardar %s (error %d)" % [path, error])
	return error == OK


static func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return {}
	return json.data if json.data is Dictionary else {}
