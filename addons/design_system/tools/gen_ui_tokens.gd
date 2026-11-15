extends SceneTree
## Development tool of the design system core: writes the game's generated UiTokens script and
## its tokens.css from the core's base tokens plus the game's tokens.json, at the paths
## res://design_system.json gives.
## Run: godot --headless --path . --script res://addons/design_system/tools/gen_ui_tokens.gd
## With `-- --check` it writes nothing: exit 1 if either generated file is not what it would
## write, if a core token is not written as `name` in the core's docs (2-fundamentos.md or
## components/*.md) or a game token or override in the game's, or if a bundle.css uses a
## var(--x) it may not; 0 otherwise. A game token named like a core one, or an override of a
## token the core lacks, fails every mode.
## With `-- --files` it only prints the paths the pre-commit hook watches, one per line:
## "ds-file: <source|generated|docs> <path>".
## Excluded from the export. It uses no game class (a --script run compiles before them).

const CONFIG_PATH := "res://design_system.json"
const TOOL_PATH := "addons/design_system/tools/gen_ui_tokens.gd"
const REGENERATE_HINT := "Regenera con: godot --headless --path . --script res://addons/design_system/tools/gen_ui_tokens.gd"
const FUNDAMENTALS := "2-fundamentos.md"

## Constant groups after the colours: JSON section, comment line.
const SIMPLE_GROUPS := [
	["spacing", "# spacing"],
	["radius", "# radius"],
	["border", "# border"],
	["outline", "# outline"],
	["size", "# size"],
	["layer", "# layer"],
	["opacity", "# opacity"],
]

## JSON sections whose tokens tokens.css writes with their value as it is.
const CSS_GROUPS := ["spacing", "radius", "border", "outline", "size", "opacity", "layer"]

## Every section that holds a "tokens" list, in either layer.
const TOKEN_SECTIONS := ["color", "spacing", "radius", "border", "outline", "size", "layer", "opacity", "shadow"]

var _config := {}
var _palette := {}
## Ids of the game's two themes (color.themes, by "role").
var _theme_normal := ""
var _theme_contrast := ""
## Token names of the core (base.json) and of the game (its own tokens and its overrides).
var _core_names: PackedStringArray = []
var _game_names: PackedStringArray = []
## The CSS variables the core's bundle.css may use: the core's tokens and font families.
var _core_css: PackedStringArray = []
var _errors: PackedStringArray = []


func _init() -> void:
	# A runtime error below (a bad JSON) would hang a --script run; this deferred quit(1) ends
	# it, and the quit(code) of a normal run replaces it.
	quit(1)
	var config: Variant = _read_json(CONFIG_PATH)
	if not config is Dictionary:
		return
	_config = config
	var args := OS.get_cmdline_user_args()
	if "--files" in args:
		_print_files()
		quit(0)
		return
	var base: Variant = _read_json(_config["base"])
	var game: Variant = _read_json(_config["tokens"])
	if not base is Dictionary or not game is Dictionary:
		return
	var json := _merge(base, game)
	if not _errors.is_empty():
		for error in _errors:
			printerr("gen_ui_tokens: %s" % error)
		return
	var gd_text := _build(json)
	var css_text := _build_css(json)
	if "--check" in args:
		quit(_check(gd_text, css_text))
		return
	if _write(_config["gd_out"], gd_text) and _write(_config["css_out"], css_text):
		quit(0)


func _read_json(path: String) -> Variant:
	var json: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not json is Dictionary:
		printerr("gen_ui_tokens: no se pudo leer %s" % path)
	return json


## The paths the hook watches: the sources, the generated files and the docs folders.
func _print_files() -> void:
	for path: String in [_config["base"], _config["tokens"], CONFIG_PATH]:
		print("ds-file: source %s" % _plain(path))
	for key: String in ["gd_out", "css_out"]:
		print("ds-file: generated %s" % _plain(_config[key]))
	for dir_path: String in _config["docs"]:
		print("ds-file: docs %s" % _plain(dir_path))


## "res://a/b" -> "a/b": the path as git and the docs write it.
func _plain(path: String) -> String:
	return path.trim_prefix("res://")


func _write(path: String, text: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		printerr("gen_ui_tokens: no se pudo escribir %s" % path)
		return false
	file.store_string(text)
	file.close()
	print("gen_ui_tokens: escrito %s" % path)
	return true


#region Merge

## base.json and the game's tokens.json as one tokens.json of a single layer: per section the
## core's tokens first (with the game's "overrides" applied), then the game's. A clash goes to
## _errors.
func _merge(base: Dictionary, game: Dictionary) -> Dictionary:
	if not _read_themes(game):
		return {}
	var merged := {}
	var core := {}
	for section: String in TOKEN_SECTIONS:
		var tokens: Array = []
		for token: Dictionary in _section_tokens(base, section):
			var own := token.duplicate(true)
			if section == "color":
				own["value"] = _theme_value(own["value"])
			tokens.append(own)
			core[own["name"]] = own
		merged[section] = {"tokens": tokens}
	var base_type: Dictionary = base["type"]
	var groups: Array = base_type["groups"].duplicate(true)
	for group: Dictionary in groups:
		for style: Dictionary in group["styles"]:
			core[style["name"]] = style
	_core_names = PackedStringArray(core.keys())
	var families: Dictionary = base_type["families"].duplicate()
	for family: String in families:
		_core_css.append("font-%s" % family)
	_core_css.append_array(_core_names)
	_apply_overrides(game, core)
	for section: String in TOKEN_SECTIONS:
		for token: Dictionary in _section_tokens(game, section):
			if _no_clash(token["name"], core):
				merged[section]["tokens"].append(token)
				_game_names.append(token["name"])
	var game_type: Dictionary = game.get("type", {})
	for group: Dictionary in game_type.get("groups", []):
		for style: Dictionary in group["styles"]:
			if _no_clash(style["name"], core):
				_game_names.append(style["name"])
		groups.append(group)
	var game_families: Dictionary = game_type.get("families", {})
	for family: String in game_families:
		if not families.has(family):
			_errors.append("type.families: la familia «%s» no está en el núcleo" % family)
		families[family] = game_families[family]
	merged["type"] = {"fonts": game_type.get("fonts", []), "families": families, "groups": groups}
	return merged


## The ids of the game's normal and high-contrast themes; false (and an error) if one is missing.
func _read_themes(game: Dictionary) -> bool:
	for theme: Dictionary in game["color"]["themes"]:
		match theme.get("role", ""):
			"normal":
				_theme_normal = theme["id"]
			"contrast":
				_theme_contrast = theme["id"]
	if _theme_normal.is_empty() or _theme_contrast.is_empty():
		_errors.append("color.themes de %s necesita un tema con \"role\": \"normal\" y otro con \"role\": \"contrast\"" % _plain(_config["tokens"]))
		return false
	return true


## A core colour value with the game's theme ids: {"normal": a, "contrast": b} -> {id: a, id: b}.
func _theme_value(value: Variant) -> Variant:
	if value is Dictionary:
		return {_theme_normal: value["normal"], _theme_contrast: value["contrast"]}
	return value


func _section_tokens(json: Dictionary, section: String) -> Array:
	if json.has(section):
		return json[section]["tokens"]
	return []


## The game's "overrides": each names a core token and gives the fields it replaces.
func _apply_overrides(game: Dictionary, core: Dictionary) -> void:
	for entry: Dictionary in game.get("overrides", []):
		var token_name: String = entry["name"]
		if not core.has(token_name):
			_errors.append("override de un token que el núcleo no tiene: %s" % token_name)
			continue
		var token: Dictionary = core[token_name]
		for field: String in entry:
			if field != "name":
				token[field] = entry[field]
		_game_names.append(token_name)


## false (and an error) if a game token takes the name of a core token.
func _no_clash(token_name: String, core: Dictionary) -> bool:
	if core.has(token_name):
		_errors.append("el token «%s» del juego pisa uno del núcleo: dale su valor en \"overrides\"" % token_name)
		return false
	return true

#endregion


#region Check

## All the checks of --check; 0 if every one passes, else 1 (each failure is printed).
func _check(gd_text: String, css_text: String) -> int:
	var failed := 0
	failed += _compare(_config["gd_out"], gd_text)
	failed += _compare(_config["css_out"], css_text)
	var docs: Array = _config["docs"]
	failed += _check_documented(_core_names, docs.slice(0, 1), "del núcleo")
	failed += _check_documented(_game_names, docs.slice(1), "del juego")
	failed += _check_css_vars(css_text)
	if failed == 0:
		print("gen_ui_tokens: %s y %s al día, tokens documentados, variables CSS resueltas" % [
			String(_config["gd_out"]).get_file(), String(_config["css_out"]).get_file()])
	return 1 if failed > 0 else 0


## 0 if the file is `text`, else 1 and the first differing line.
func _compare(path: String, text: String) -> int:
	var current := FileAccess.get_file_as_string(path)
	if current == text:
		return 0
	var have := current.split("\n")
	var want := text.split("\n")
	for i in maxi(have.size(), want.size()):
		var a := have[i] if i < have.size() else "<fin del archivo>"
		var b := want[i] if i < want.size() else "<fin del archivo>"
		if a != b:
			printerr("%s:%d: distinto del generado. Tiene: %s | Debería: %s" % [_plain(path), i + 1, a, b])
			break
	printerr(REGENERATE_HINT)
	return 1


## 1 if some name is not written as `name` in the 2-fundamentos.md or components/*.md of `dirs`.
func _check_documented(names: PackedStringArray, dirs: Array, layer_name: String) -> int:
	var docs := ""
	var where: PackedStringArray = []
	for dir_path: String in dirs:
		docs += _docs_text(dir_path)
		where.append(_plain(dir_path))
	var missing: PackedStringArray = []
	for token_name in names:
		if not docs.contains("`%s`" % token_name):
			missing.append(token_name)
	if missing.is_empty():
		return 0
	printerr("Tokens %s sin documentar en 2-fundamentos.md ni components/*.md de %s (%d): %s" % [
		layer_name, ", ".join(where), missing.size(), ", ".join(missing)])
	return 1


func _docs_text(dir_path: String) -> String:
	var text := FileAccess.get_file_as_string("%s/%s" % [dir_path, FUNDAMENTALS])
	var components := "%s/components" % dir_path
	var dir := DirAccess.open(components)
	if dir != null:
		for file_name in dir.get_files():
			if file_name.ends_with(".md"):
				text += "\n" + FileAccess.get_file_as_string("%s/%s" % [components, file_name])
	return text


## 1 if a bundle.css uses a var(--x) that `css_text` does not define; the first bundle is the
## core's, which may use only the core's variables.
func _check_css_vars(css_text: String) -> int:
	var used := RegEx.new()
	used.compile("var\\(--([\\w-]+)")
	var bundles: Array = _config["bundles"]
	var failed := 0
	for i in bundles.size():
		var path: String = bundles[i]
		var missing: PackedStringArray = []
		var outside: PackedStringArray = []
		for hit in used.search_all(FileAccess.get_file_as_string(path)):
			var token_name := hit.get_string(1)
			if not css_text.contains("\t--%s:" % token_name):
				if not token_name in missing:
					missing.append(token_name)
			elif i == 0 and not token_name in _core_css and not token_name in outside:
				outside.append(token_name)
		if not missing.is_empty():
			printerr("%s usa variables que %s no define: %s" % [
				_plain(path), _plain(_config["css_out"]), ", ".join(missing)])
			failed = 1
		if not outside.is_empty():
			printerr("%s es el del núcleo y usa variables del juego: %s" % [_plain(path), ", ".join(outside)])
			failed = 1
	return failed

#endregion


#region Build

## ui_tokens.gd in member order: doc comment, constants, static var, static funcs.
func _build(json: Dictionary) -> String:
	var normal := _const_name(_theme_normal)
	var contrast := _const_name(_theme_contrast)
	var out: PackedStringArray = []
	out.append("class_name UiTokens extends RefCounted")
	out.append("## Generated by %s from %s and %s. Never edit it by hand: change tokens.json and regenerate." % [
		TOOL_PATH, _plain(_config["tokens"]), _plain(_config["base"])])
	out.append("")
	_add_colors(out, json["color"]["tokens"])
	for group: Array in SIMPLE_GROUPS:
		_add_simple_group(out, json[group[0]]["tokens"], group[1])
	var rows := _add_type_constants(out, json["type"])
	_add_type_table(out, json["type"], rows)
	_add_shadow(out, json["shadow"]["tokens"][0])
	out.append("")
	out.append("## true con el tema de alto contraste (la opción del juego); DsTheme.build() la lee.")
	out.append("static var high_contrast := false")
	out.append("")
	out.append("")
	out.append("## Color de un token por su nombre: UiTokens.color(&\"text-accent\").")
	out.append("static func color(token: StringName) -> Color:")
	out.append("\tif high_contrast and %s.has(token):" % contrast)
	out.append("\t\treturn %s[token]" % contrast)
	out.append("\treturn %s[token]" % normal)
	out.append("")
	out.append("")
	out.append("## Size in px of a type style (\"body\" -> 24).")
	out.append("static func type_size(style: StringName) -> int:")
	out.append("\treturn TYPE[style][0]")
	return "\n".join(out) + "\n"


## tokens.css: the custom properties the bundle.css files read. The normal theme's colours in
## :root, the ones that differ in high contrast under [data-theme="<its id>"].
func _build_css(json: Dictionary) -> String:
	var out: PackedStringArray = []
	out.append("/* Generado por %s desde %s y %s. No se edita a mano: cambia tokens.json y regenera. */" % [
		TOOL_PATH, _plain(_config["tokens"]), _plain(_config["base"])])
	out.append(":root {")
	var contrast: PackedStringArray = []
	_fill_palette(json["color"]["tokens"])
	for token: Dictionary in json["color"]["tokens"]:
		var in_game := _resolve(token["value"], _theme_normal)
		out.append("\t--%s: %s;" % [token["name"], in_game])
		var in_contrast := _resolve(token["value"], _theme_contrast)
		if in_contrast != in_game:
			contrast.append("\t--%s: %s;" % [token["name"], in_contrast])
	for section: String in CSS_GROUPS:
		for token: Dictionary in json[section]["tokens"]:
			out.append("\t--%s: %s;" % [token["name"], token["value"]])
	out.append("\t--shadow-window: %s;" % json["shadow"]["tokens"][0]["value"])
	var families: Dictionary = json["type"]["families"]
	for family: String in families:
		out.append("\t--font-%s: %s;" % [family, families[family]])
	out.append("}")
	out.append("")
	out.append("[data-theme=\"%s\"] {" % _theme_contrast)
	out.append_array(contrast)
	out.append("}")
	return "\n".join(out) + "\n"


func _fill_palette(tokens: Array) -> void:
	_palette.clear()
	for token: Dictionary in tokens:
		_palette[token["name"]] = token["value"]


func _add_colors(out: PackedStringArray, tokens: Array) -> void:
	_fill_palette(tokens)
	var game: PackedStringArray = []
	var contrast: PackedStringArray = []
	for token: Dictionary in tokens:
		var token_name: String = token["name"]
		var in_game := _resolve(token["value"], _theme_normal)
		game.append("\t&\"%s\": Color(\"%s\")," % [token_name, in_game])
		var in_contrast := _resolve(token["value"], _theme_contrast)
		if in_contrast != in_game:
			contrast.append("\t&\"%s\": Color(\"%s\")," % [token_name, in_contrast])
	out.append("const %s := {" % _const_name(_theme_normal))
	out.append_array(game)
	out.append("}")
	out.append("")
	out.append("const %s := {" % _const_name(_theme_contrast))
	out.append_array(contrast)
	out.append("}")
	out.append("")


## The hex of a token value for one theme; `{name}` references are followed.
func _resolve(value: Variant, theme: String) -> String:
	var text: String = value[theme] if value is Dictionary else value
	if text.begins_with("{") and text.ends_with("}"):
		return _resolve(_palette[text.substr(1, text.length() - 2)], theme)
	return text


func _add_simple_group(out: PackedStringArray, tokens: Array, comment: String) -> void:
	out.append(comment)
	for token: Dictionary in tokens:
		out.append("const %s := %s" % [_const_name(token["name"]), _number(token["value"])])
	out.append("")


## Writes the TYPE_* constants and the font paths (empty for a family the game gives no font);
## returns the rows of the TYPE table.
func _add_type_constants(out: PackedStringArray, type: Dictionary) -> PackedStringArray:
	var rows: PackedStringArray = []
	out.append("# Tipografía: tamaño en px y peso (wght) de cada estilo.")
	for group: Dictionary in type["groups"]:
		for style: Dictionary in group["styles"]:
			var base := "TYPE_%s" % _const_name(style["name"])
			out.append("const %s_SIZE := %s" % [base, _number(style["fontSize"])])
			out.append("const %s_WEIGHT := %d" % [base, int(style["fontWeight"])])
			rows.append("\t&\"%s\": [%s, %d, FAMILY_%s, %s]," % [
				style["name"], _number(style["fontSize"]), int(style["fontWeight"]),
				String(group["family"]).to_upper(), _float(style["lineHeight"])])
	out.append("")
	var fonts: Array = type["fonts"]
	for family: String in type["families"]:
		var path := ""
		for font: Dictionary in fonts:
			if font["role"] == family:
				path = font["godot_path"]
		out.append("const FONT_%s_PATH := \"%s\"" % [family.to_upper(), path])
	return rows


func _add_type_table(out: PackedStringArray, type: Dictionary, rows: PackedStringArray) -> void:
	out.append("")
	for family: String in type["families"]:
		out.append("const FAMILY_%s := &\"%s\"" % [family.to_upper(), family])
	out.append("## Type style -> [size px, weight (wght), family, line height] (tokens.json, type.groups).")
	out.append("const TYPE := {")
	out.append_array(rows)
	out.append("}")


func _add_shadow(out: PackedStringArray, token: Dictionary) -> void:
	var css: String = token["value"]
	var color := ""
	for part in css.split(" "):
		if part.begins_with("#"):
			color = part
	var godot: Dictionary = token["godot"]
	var offset: Array = godot["offset"]
	out.append("")
	out.append("## %s (tokens.json: \"%s\"; in Godot shadow_size %d, offset (%d, %d))." % [
		token["name"], css, int(godot["size"]), int(offset[0]), int(offset[1])])
	out.append("const SHADOW_COLOR := Color(\"%s\")" % color)
	out.append("const SHADOW_SIZE := %d" % int(godot["size"]))
	out.append("const SHADOW_OFFSET := Vector2(%d, %d)" % [int(offset[0]), int(offset[1])])


## "space-1" -> "SPACE_1", "alto-contraste" -> "ALTO_CONTRASTE".
func _const_name(token_name: String) -> String:
	return token_name.replace("-", "_").to_upper()


## "56px" -> "56", "0.9" -> "0.9", "1" -> "1": px stripped, an integer unless it has a point.
func _number(value: String) -> String:
	var plain := value.trim_suffix("px")
	if plain.contains("."):
		return plain
	return str(int(plain))


## A JSON number as GDScript float text ("1.0", "1.05").
func _float(value: float) -> String:
	return str(value)

#endregion
