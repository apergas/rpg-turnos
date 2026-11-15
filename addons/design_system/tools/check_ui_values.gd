extends SceneTree
## Development tool of the design system core: finds UI values written by hand that must come
## from UiTokens / the theme. What it scans comes from res://design_system.json: every .gd
## under scan_roots; Color( is forbidden in color_dirs, except in gd_out (the generated
## UiTokens).
## Run: godot --headless --path . --script res://addons/design_system/tools/check_ui_values.gd
## Prints `path:line: reason` for each hit and exits 1; exits 0 when clean.
## Excluded from the export. It uses no game class (a --script run compiles before them).

const CONFIG_PATH := "res://design_system.json"

var _tokens_file := ""
var _color_dirs: Array = []
var _color_literal := RegEx.new()
var _font_size_literal := RegEx.new()
var _font_size_assign := RegEx.new()
var _hits := 0


func _init() -> void:
	# A runtime error below would hang a --script run; this deferred quit(1) ends it, and
	# the quit(code) at the end replaces it.
	quit(1)
	var config: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	if not config is Dictionary:
		printerr("check_ui_values: no se pudo leer %s" % CONFIG_PATH)
		return
	_tokens_file = config["gd_out"]
	_color_dirs = config["color_dirs"]
	_color_literal.compile("\\bColor\\(")
	_font_size_literal.compile("add_theme_font_size_override\\(\\s*[^,]+,\\s*-?\\d")
	_font_size_assign.compile("(\\b|default_)font_size\\s*=\\s*-?\\d")
	for root: String in config["scan_roots"]:
		_scan(root)
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
	var colors_forbidden := path != _tokens_file and _in_color_dirs(path)
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
	for dir: String in _color_dirs:
		if path.begins_with(dir):
			return true
	return false


func _report(path: String, line: int, reason: String) -> void:
	_hits += 1
	printerr("%s:%d: %s" % [path.trim_prefix("res://"), line, reason])
