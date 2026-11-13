class_name StatBar extends Control
## One datum of the hero as a bar with its text on top ("PV 42/42"). HP, MP and EXP are the
## names of the tokens that colour it (PV red, PM blue, EXP green). It draws
## itself and redraws only when its value changes, so a dozen of them cost nothing.

const HP := &"stat-hp"
const MP := &"stat-mp"
const EXP := &"stat-exp"
const BAR_SIZE := Vector2(UiTokens.BAR_WIDTH, UiTokens.BAR_HEIGHT)
## Below this share of its bar the HP is critical: red text and a fill that pulses.
const CRITICAL_RATIO := 0.25
## Seconds of one pulse (the fill's alpha goes 1.0 -> 0.6 -> 1.0).
const CRITICAL_PULSE := 1.0
const PULSE_LOW := 0.6

var _token: StringName
var _text := ""
var _ratio := 0.0


func _init(token: StringName, width := float(UiTokens.BAR_WIDTH)) -> void:
	_token = token
	custom_minimum_size = Vector2(width, BAR_SIZE.y)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)


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
	# Only a critical HP bar needs a repaint every frame.
	set_process(_is_critical())
	queue_redraw()


func _is_critical() -> bool:
	return _token == HP and _ratio < CRITICAL_RATIO


func _process(_delta: float) -> void:
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), UiTokens.color(&"surface-track"))
	var fill := UiTokens.color(_token)
	var critical := _is_critical()
	if critical:
		var phase := 0.5 + 0.5 * cos(Time.get_ticks_msec() / 1000.0 / CRITICAL_PULSE * TAU)
		fill.a = lerpf(PULSE_LOW, 1.0, phase)
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * clampf(_ratio, 0.0, 1.0), size.y)), fill)
	var font := UiTheme.font_for(&"label")
	var font_size := UiTokens.TYPE_LABEL_SIZE
	var at := Vector2(8, (size.y + font.get_ascent(font_size) - font.get_descent(font_size)) / 2.0)
	draw_string_outline(font, at, _text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size,
		UiTokens.OUTLINE_S, UiTokens.color(&"text-outline"))
	draw_string(font, at, _text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size,
		UiTokens.color(&"text-danger" if critical else &"text-on-fill"))
