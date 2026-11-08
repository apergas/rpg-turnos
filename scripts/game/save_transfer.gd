class_name SaveTransfer extends Node
## Moves a save's text between a slot and a file the player keeps. On the web the file is
## downloaded (JavaScriptBridge.download_buffer()) and picked with an <input type=file> made
## from JavaScript; elsewhere a FileDialog asks (the system's own where there is one). Only
## moves text: SaveData.from_json() decides what may come in. Owned by TitleScreen.

signal _web_answered(result: Dictionary)
signal _path_chosen(path: String)

const FILE_NAME := "villaclaro-ranura-%d.json"
const MIME := "application/json"
const FILTER := "*.json ; Partida de Villaclaro"
const EXPORT_TITLE := "Exportar partida"
const IMPORT_TITLE := "Importar partida"
## Bigger files are not saves (a whole game's save is a few tens of KB). PICK_JS repeats it.
const MAX_BYTES := 1000000
const EXPORTED_TEXT := "Partida exportada: %s"
const WRITE_FAILED_TEXT := "No se pudo escribir el archivo."
## Defines window.villaclaroPickSave(done): opens the browser's file picker and calls
## done(picked, text) once; picked is false if the player gave up, text is "" when the
## file can't be read or is too big. No "accept" filter: iOS greys out files it can't type.
const PICK_JS := """
window.villaclaroPickSave = function (done) {
	var input = document.createElement('input');
	input.type = 'file';
	var answered = false;
	function answer(picked, text) {
		if (!answered) {
			answered = true;
			done(picked, text);
		}
	}
	input.addEventListener('cancel', function () { answer(false, ''); });
	input.addEventListener('change', function () {
		var file = input.files && input.files[0];
		if (!file) { answer(false, ''); return; }
		if (file.size > 1000000) { answer(true, ''); return; }
		file.text().then(function (text) { answer(true, text); },
			function () { answer(true, ''); });
	});
	input.click();
};
"""

## Kept while the browser's picker is open: without a reference it would be freed.
var _web_callback: JavaScriptObject


## Writes text to a file the player keeps. Returns the message to show, "" if they gave up.
func export_text(slot: int, text: String) -> String:
	var file_name := FILE_NAME % slot
	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(text.to_utf8_buffer(), file_name, MIME)
		return EXPORTED_TEXT % file_name
	var path := await _ask_path(FileDialog.FILE_MODE_SAVE_FILE, file_name)
	if path == "":
		return ""
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return WRITE_FAILED_TEXT
	var ok := file.store_string(text)
	file.close()
	return EXPORTED_TEXT % path.get_file() if ok else WRITE_FAILED_TEXT


## {"picked": false} if the player gave up, else {"picked": true, "text": the file's text,
## "" when it can't be read or is too big}.
func import_text() -> Dictionary:
	if OS.has_feature("web"):
		_web_callback = JavaScriptBridge.create_callback(_on_web_file)
		JavaScriptBridge.eval(PICK_JS, true)
		var window = JavaScriptBridge.get_interface("window")
		window.villaclaroPickSave(_web_callback)
		var result: Dictionary = await _web_answered
		_web_callback = null
		return result
	var path := await _ask_path(FileDialog.FILE_MODE_OPEN_FILE, "")
	if path == "":
		return {"picked": false, "text": ""}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > MAX_BYTES:
		return {"picked": true, "text": ""}
	return {"picked": true, "text": file.get_as_text()}


func _on_web_file(args: Array) -> void:
	var picked: bool = args.size() > 0 and args[0] == true
	var text := str(args[1]) if picked and args.size() > 1 else ""
	_web_answered.emit({"picked": picked, "text": text})


## The path the player picks in a FileDialog, "" if they cancel.
func _ask_path(mode: FileDialog.FileMode, file_name: String) -> String:
	var dialog := FileDialog.new()
	dialog.file_mode = mode
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.use_native_dialog = true
	dialog.filters = PackedStringArray([FILTER])
	dialog.title = EXPORT_TITLE if mode == FileDialog.FILE_MODE_SAVE_FILE else IMPORT_TITLE
	dialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	if file_name != "":
		dialog.current_file = file_name
	dialog.file_selected.connect(func(path: String) -> void: _path_chosen.emit(path))
	dialog.canceled.connect(func() -> void: _path_chosen.emit(""))
	add_child(dialog)
	dialog.popup_centered_ratio(0.7)
	var path: String = await _path_chosen
	dialog.queue_free()
	return path
