extends SceneTree
## Development tool: writes scripts/ui/ui_tokens.gd and docs/boost/design-system/tokens.css
## from docs/boost/design-system/tokens.json.
## Run: godot --headless --path . --script res://scripts/tools/gen_ui_tokens.gd
## With `-- --check` it writes nothing: exit 1 if either file is not what the generator would
## write, if a token of tokens.json is not documented in 2-fundamentos.md or components/*.md,
## or if components/bundle.css uses a var(--x) that tokens.css does not define; 0 otherwise.
## Excluded from the export. It uses no game class (a --script run compiles before them).

const TOKENS_PATH := "res://docs/boost/design-system/tokens.json"
const OUTPUT_PATH := "res://scripts/ui/ui_tokens.gd"
const CSS_PATH := "res://docs/boost/design-system/tokens.css"
const FUNDAMENTALS_DOC := "res://docs/boost/design-system/2-fundamentos.md"
const COMPONENTS_DIR := "res://docs/boost/design-system/components"
const BUNDLE_PATH := "res://docs/boost/design-system/components/bundle.css"
const THEME_GAME := "juego"
const THEME_CONTRAST := "alto-contraste"
const REGENERATE_HINT := "Regenera con: godot --headless --path . --script res://scripts/tools/gen_ui_tokens.gd"

## Constant groups after the colours: JSON section, comment line, name prefix of each token.
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

var _palette: Dictionary = {}


func _init() -> void:
	# A runtime error below (a bad tokens.json) would hang a --script run; this deferred
	# quit(1) ends it, and the quit(code) of a normal run replaces it.
	quit(1)
	var json: Variant = JSON.parse_string(FileAccess.get_file_as_string(TOKENS_PATH))
	if not json is Dictionary:
		printerr("gen_ui_tokens: no se pudo leer %s" % TOKENS_PATH)
		return
	var gd_text := _build(json)
	var css_text := _build_css(json)
	if "--check" in OS.get_cmdline_user_args():
		quit(_check(json, gd_text, css_text))
		return
	if _write(OUTPUT_PATH, gd_text) and _write(CSS_PATH, css_text):
		quit(0)


func _write(path: String, text: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		printerr("gen_ui_tokens: no se pudo escribir %s" % path)
		return false
	file.store_string(text)
	file.close()
	print("gen_ui_tokens: escrito %s" % path)
	return true


## All the checks of --check; 0 if every one passes, else 1 (each failure is printed).
func _check(json: Dictionary, gd_text: String, css_text: String) -> int:
	var failed := 0
	failed += _compare(OUTPUT_PATH, gd_text)
	failed += _compare(CSS_PATH, css_text)
	failed += _check_documented(json)
	failed += _check_css_vars(css_text)
	if failed == 0:
		print("gen_ui_tokens: ui_tokens.gd y tokens.css al día, tokens documentados, variables CSS resueltas")
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
			printerr("%s:%d: distinto del generado. Tiene: %s | Debería: %s" % [path.trim_prefix("res://"), i + 1, a, b])
			break
	printerr(REGENERATE_HINT)
	return 1


## 1 if some token of tokens.json is not written as `name` in 2-fundamentos.md or components/*.md.
func _check_documented(json: Dictionary) -> int:
	var docs := FileAccess.get_file_as_string(FUNDAMENTALS_DOC)
	var dir := DirAccess.open(COMPONENTS_DIR)
	for file_name in dir.get_files():
		if file_name.ends_with(".md"):
			docs += "\n" + FileAccess.get_file_as_string("%s/%s" % [COMPONENTS_DIR, file_name])
	var missing: PackedStringArray = []
	for token_name in _token_names(json):
		if not docs.contains("`%s`" % token_name):
			missing.append(token_name)
	if missing.is_empty():
		return 0
	printerr("Tokens sin documentar en 2-fundamentos.md ni en components/*.md (%d): %s" % [missing.size(), ", ".join(missing)])
	return 1


## Every token name of tokens.json: colours, scales, shadow and type styles.
func _token_names(json: Dictionary) -> PackedStringArray:
	var names: PackedStringArray = []
	for token: Dictionary in json["color"]["tokens"]:
		names.append(token["name"])
	for section: String in CSS_GROUPS + ["shadow"]:
		for token: Dictionary in json[section]["tokens"]:
			names.append(token["name"])
	for group: Dictionary in json["type"]["groups"]:
		for style: Dictionary in group["styles"]:
			names.append(style["name"])
	return names


## 1 if components/bundle.css uses a var(--x) that `css_text` does not define.
func _check_css_vars(css_text: String) -> int:
	var used := RegEx.new()
	used.compile("var\\(--([\\w-]+)")
	var bundle := FileAccess.get_file_as_string(BUNDLE_PATH)
	var missing: PackedStringArray = []
	for hit in used.search_all(bundle):
		var token_name := hit.get_string(1)
		if not css_text.contains("\t--%s:" % token_name) and not token_name in missing:
			missing.append(token_name)
	if missing.is_empty():
		return 0
	printerr("components/bundle.css usa variables que tokens.css no define: %s" % ", ".join(missing))
	return 1


## ui_tokens.gd in member order: doc comment, constants, static var, static funcs.
func _build(json: Dictionary) -> String:
	var out: PackedStringArray = []
	out.append("class_name UiTokens extends RefCounted")
	out.append("## Generated by scripts/tools/gen_ui_tokens.gd from docs/boost/design-system/tokens.json. Never edit it by hand: change tokens.json and regenerate.")
	out.append("")
	_add_colors(out, json["color"]["tokens"])
	for group: Array in SIMPLE_GROUPS:
		_add_simple_group(out, json[group[0]]["tokens"], group[1])
	var rows := _add_type_constants(out, json["type"])
	_add_type_table(out, json["type"], rows)
	_add_shadow(out, json["shadow"]["tokens"][0])
	out.append("")
	out.append("## true con la opción «Alto contraste» (GameOptions); UiTheme.build() la lee.")
	out.append("static var high_contrast := false")
	out.append("")
	out.append("")
	out.append("## Color de un token por su nombre: UiTokens.color(&\"text-accent\").")
	out.append("static func color(token: StringName) -> Color:")
	out.append("\tif high_contrast and ALTO_CONTRASTE.has(token):")
	out.append("\t\treturn ALTO_CONTRASTE[token]")
	out.append("\treturn JUEGO[token]")
	out.append("")
	out.append("")
	out.append("## Size in px of a type style (\"body\" -> 24).")
	out.append("static func type_size(style: StringName) -> int:")
	out.append("\treturn TYPE[style][0]")
	return "\n".join(out) + "\n"


## tokens.css: the custom properties components/bundle.css reads. The game theme's colours in
## :root, the ones that differ in high contrast under [data-theme="alto-contraste"].
func _build_css(json: Dictionary) -> String:
	var out: PackedStringArray = []
	out.append("/* Generado por scripts/tools/gen_ui_tokens.gd desde tokens.json. No se edita a mano: cambia tokens.json y regenera. */")
	out.append(":root {")
	var contrast: PackedStringArray = []
	_fill_palette(json["color"]["tokens"])
	for token: Dictionary in json["color"]["tokens"]:
		var in_game := _resolve(token["value"], THEME_GAME)
		out.append("\t--%s: %s;" % [token["name"], in_game])
		var in_contrast := _resolve(token["value"], THEME_CONTRAST)
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
	out.append("[data-theme=\"%s\"] {" % THEME_CONTRAST)
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
		var name: String = token["name"]
		var in_game := _resolve(token["value"], THEME_GAME)
		game.append("\t&\"%s\": Color(\"%s\")," % [name, in_game])
		var in_contrast := _resolve(token["value"], THEME_CONTRAST)
		if in_contrast != in_game:
			contrast.append("\t&\"%s\": Color(\"%s\")," % [name, in_contrast])
	out.append("const JUEGO := {")
	out.append_array(game)
	out.append("}")
	out.append("")
	out.append("const ALTO_CONTRASTE := {")
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


## Writes the TYPE_* constants and the font paths; returns the rows of the TYPE table.
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
	for font: Dictionary in type["fonts"]:
		out.append("const FONT_%s_PATH := \"%s\"" % [String(font["role"]).to_upper(), font["godot_path"]])
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


## "space-1" -> "SPACE_1".
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
