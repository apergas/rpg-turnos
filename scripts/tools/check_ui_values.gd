extends SceneTree
## Development tool: finds UI values written by hand that must come from UiTokens / UiTheme.
## Run: godot --headless --path . --script res://scripts/tools/check_ui_values.gd
## Prints `path:line: reason` for each hit and exits 1; exits 0 when clean.
## Excluded from the export. It uses no game class (a --script run compiles before them).

const ROOT := "res://scripts"
const TOKENS_FILE := "res://scripts/ui/ui_tokens.gd"
const COLOR_DIRS: Array[String] = ["res://scripts/ui/", "res://scripts/title/"]

var _color_literal := RegEx.new()
var _font_size_literal := RegEx.new()
var _font_size_assign := RegEx.new()
var _hits := 0


func _init() -> void:
	_color_literal.compile("\\bColor\\(")
	_font_size_literal.compile("add_theme_font_size_override\\(\\s*[^,]+,\\s*-?\\d")
	_font_size_assign.compile("\\bfont_size\\s*=\\s*-?\\d")
	_scan(ROOT)
	if _hits == 0:
		print("Valores de interfaz: sin valores a mano")
	quit(1 if _hits > 0 else 0)


func _scan(dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	for sub in dir.get_directories():
		_scan("%s/%s" % [dir_path, sub])
	for file_name in dir.get_files():
		if file_name.ends_with(".gd"):
			_check_file("%s/%s" % [dir_path, file_name])


func _check_file(path: String) -> void:
	var lines := FileAccess.get_file_as_string(path).split("\n")
	var colors_forbidden := path != TOKENS_FILE and _in_color_dirs(path)
	for i in lines.size():
		var line := lines[i]
		if line.strip_edges().begins_with("#"):
			continue
		var has_color := _color_literal.search(line) != null
		if colors_forbidden and has_color:
			_report(path, i + 1, "Color( a mano: usa UiTokens.color()")
		if has_color and line.contains("add_theme_color_override("):
			_report(path, i + 1, "add_theme_color_override con Color( a mano")
		if _font_size_literal.search(line) or _font_size_assign.search(line):
			_report(path, i + 1, "tamaño de letra literal: usa UiTokens.TYPE")


func _in_color_dirs(path: String) -> bool:
	for dir in COLOR_DIRS:
		if path.begins_with(dir):
			return true
	return false


func _report(path: String, line: int, reason: String) -> void:
	_hits += 1
	printerr("%s:%d: %s" % [path.trim_prefix("res://"), line, reason])
