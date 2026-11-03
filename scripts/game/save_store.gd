class_name SaveStore extends RefCounted
## Reads and writes the save game and the options as JSON under user://. On the web
## Godot keeps user:// in the browser (IndexedDB), and a file is stored when it is
## closed. Runs with `-- --autoplay` use their own save file, so they never overwrite
## the player's game.

const SAVE_PATH := "user://save.json"
const AUTOPLAY_SAVE_PATH := "user://save_autoplay.json"
const OPTIONS_PATH := "user://options.json"


static func save_path() -> String:
	if OS.get_cmdline_user_args().has("--autoplay"):
		return AUTOPLAY_SAVE_PATH
	return SAVE_PATH


static func has_save() -> bool:
	return FileAccess.file_exists(save_path())


## True if the file was written.
static func save_game(data: Dictionary) -> bool:
	return _write(save_path(), data)


## The saved Dictionary, or an empty one if there is no save or it can't be read.
static func load_game() -> Dictionary:
	return _read(save_path())


static func save_options(options: GameOptions) -> bool:
	return _write(OPTIONS_PATH, options.to_dict())


## Saved options, or the defaults.
static func load_options() -> GameOptions:
	return GameOptions.from_dict(_read(OPTIONS_PATH))


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
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
