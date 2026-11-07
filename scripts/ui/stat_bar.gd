class_name StatBar extends Control
## One datum of the hero as a bar with its text on top ("PV 42/42"), and the colors every
## window uses for the hero's data: gold golden, PV red, PM blue, EXP green. It draws
## itself and redraws only when its value changes, so a dozen of them cost nothing.

const HP := Color(0.8, 0.16, 0.16)
const MP := Color(0.2, 0.4, 0.92)
const EXP := Color(0.18, 0.62, 0.26)
const GOLD := Color(1.0, 0.8, 0.25)
## The EXP as text on a dark window (the bar's green is too dark to read there).
const EXP_TEXT := Color(0.4, 0.9, 0.48)
const BACK := Color(0.0, 0.0, 0.0, 0.55)
const BAR_SIZE := Vector2(220, 30)
const FONT_SIZE := 20
const OUTLINE := 4

var _color: Color
var _text := ""
var _ratio := 0.0


func _init(color: Color, width := BAR_SIZE.x) -> void:
	_color = color
	custom_minimum_size = Vector2(width, BAR_SIZE.y)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## "Héroe Nv 3", the name every window gives the hero.
static func hero_title(hero: Combatant) -> String:
	return "%s Nv %d" % [hero.display_name, hero.level]


func show_hp(hp: int, max_hp: int) -> void:
	_show("PV %d/%d" % [hp, max_hp], float(hp) / maxf(1.0, max_hp))


func show_mp(mp: int, max_mp: int) -> void:
	_show("PM %d/%d" % [mp, max_mp], float(mp) / maxf(1.0, max_mp))


func show_exp(hero: Combatant) -> void:
	_show(Leveling.exp_text(hero), Leveling.exp_ratio(hero))


func _show(text: String, ratio: float) -> void:
	if text == _text and is_equal_approx(ratio, _ratio):
		return
	_text = text
	_ratio = ratio
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BACK)
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * clampf(_ratio, 0.0, 1.0), size.y)), _color)
	var font := get_theme_default_font()
	var at := Vector2(8, (size.y + font.get_ascent(FONT_SIZE) - font.get_descent(FONT_SIZE)) / 2.0)
	draw_string_outline(font, at, _text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, OUTLINE,
		Color.BLACK)
	draw_string(font, at, _text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color.WHITE)
