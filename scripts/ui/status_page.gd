class_name StatusPage extends HBoxContainer
## The pause menu's Estado, its content: on the left the hero's PV, PM and EXP bars,
## ATK · DEF · VEL, the gold and the companion or creature with its numbers under its name; on
## the right the spells, each with its PM and what it does. PauseMenu puts it in a ScrollBox
## (3.8.2), so with large text on a phone the page scrolls and Volver stays on screen. Only reads
## a GameState: call fill() each time it opens.

var _hp_bar: StatBar
var _mp_bar: StatBar
var _exp_bar: StatBar
var _stats_label: Label
var _gold_label: Label
var _ally_label: Label
## Under the companion's name: its numbers now, in small text.
var _ally_stats: Label
## The right column: each spell, its PM and what it does.
var _spells_box: VBoxContainer


func _ready() -> void:
	add_theme_constant_override("separation", UiTokens.SPACE_6)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", UiTokens.SPACE_2)
	add_child(left)
	_hp_bar = StatBar.new(StatBar.HP, PauseMenu.STATUS_BAR_WIDTH)
	left.add_child(_hp_bar)
	_mp_bar = StatBar.new(StatBar.MP, PauseMenu.STATUS_BAR_WIDTH)
	left.add_child(_mp_bar)
	_exp_bar = StatBar.new(StatBar.EXP, PauseMenu.STATUS_BAR_WIDTH)
	left.add_child(_exp_bar)
	_stats_label = _label("")
	left.add_child(_stats_label)
	_gold_label = _label("", UiTheme.MONEY)
	left.add_child(_gold_label)
	_ally_label = _label("")
	left.add_child(_ally_label)
	_ally_stats = _label("", UiTheme.CAPTION)
	left.add_child(_ally_stats)
	_spells_box = VBoxContainer.new()
	_spells_box.add_theme_constant_override("separation", 0)
	add_child(_spells_box)


func fill(state: GameState) -> void:
	var hero := state.hero
	_hp_bar.show_hp(hero.hp, hero.max_hp)
	_mp_bar.show_mp(hero.mp, hero.max_mp)
	_exp_bar.show_exp(hero)
	_stats_label.text = "ATK %d   DEF %d   VEL %d" % [hero.total_attack(),
		hero.total_defense(), hero.total_speed()]
	_gold_label.text = "%d G" % state.gold
	for child in _spells_box.get_children():
		_spells_box.remove_child(child)
		child.queue_free()
	_spells_box.add_child(_label("Hechizos", UiTheme.TITLE))
	for skill in hero.skills:
		_spells_box.add_child(_label("%s  %d PM" % [skill.display_name, skill.mp_cost]))
		UiStyle.add_small_text(_spells_box, skill.description)
	_ally_label.visible = state.ally_id != ""
	_ally_stats.visible = _ally_label.visible
	if state.ally_id != "":
		var id := state.ally_id
		BattleHud.fit_label(_ally_label, "%s: %s" % [Allies.kind_name(id), Allies.display_name(id)],
			PauseMenu.TEXT_WIDTH)
		BattleHud.fit_label(_ally_stats, Allies.stats_text(id, state.ally_step()),
			PauseMenu.TEXT_WIDTH)


func _label(text: String, variation := &"") -> Label:
	var label := Label.new()
	label.text = text
	if variation != &"":
		label.theme_type_variation = variation
	return label
