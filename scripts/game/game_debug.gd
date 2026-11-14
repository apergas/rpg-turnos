class_name GameDebug extends Node
## Node, a piece of Game, only with --debug on the command line (never otherwise; the web
## can't pass it; autoplay never uses it): owns the DebugPanel (F1 on the map opens it) and
## does what its buttons ask at once on the state and the map (_on_debug(): level, gold,
## items, heal, monster groups off and on, a boss beaten, the village quest's next stage, a
## save to the slot in use), printed as "Depuración: ..." and said on the panel; Ir a goes
## on under black (_debug_go()). While the panel is open Game is busy and the status window
## hides. Handed ZoneTravel, BattleFlow and StoryFlow in setup(), and uses only their public
## functions; never stores Game or a World.

const HERO_DATA := preload("res://data/hero.tres")

var _ctx: SessionContext
var _travel: ZoneTravel
var _battle: BattleFlow
var _story: StoryFlow
var _panel: DebugPanel


func setup(ctx: SessionContext, travel: ZoneTravel, battle: BattleFlow,
		story: StoryFlow) -> void:
	_ctx = ctx
	_travel = travel
	_battle = battle
	_story = story


## The panel over the pause menu, under the fade.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var layer := CanvasLayer.new()
	layer.layer = UiTokens.LAYER_DEBUG
	add_child(layer)
	_panel = DebugPanel.new()
	_panel.setup(_ctx.state)
	layer.add_child(_panel)
	_panel.action_chosen.connect(_on_debug)
	_panel.open_changed.connect(func(is_open: bool) -> void:
		_ctx.set_busy.call(is_open)
		_ctx.world.set_status_shown(not is_open))


## The panel only opens on the map with nothing else going on (Game._set_busy()).
func set_available(on: bool) -> void:
	if _panel:
		_panel.available = on


## What a DebugPanel button asks: done at once on the state and the map, printed as
## "Depuración: ..." and said on the panel. Ir a goes on under black (_debug_go()).
func _on_debug(action: String, arg: String) -> void:
	var text := ""
	match action:
		DebugPanel.ZONE:
			_debug_go(arg)
			return
		DebugPanel.LEVEL:
			Leveling.set_level(_ctx.state.hero, _ctx.state.hero.level + int(arg), HERO_DATA.skills)
			var spells := PackedStringArray()
			for skill in _ctx.state.hero.skills:
				spells.append(skill.display_name)
			text = "nivel %d (PV %d/%d, PM %d/%d, EXP %d; hechizos: %s)" % [_ctx.state.hero.level,
				_ctx.state.hero.hp, _ctx.state.hero.max_hp, _ctx.state.hero.mp, _ctx.state.hero.max_mp,
				_ctx.state.hero.experience, ", ".join(spells)]
		DebugPanel.GOLD:
			_ctx.state.gold += int(arg)
			text = "+%s G (%d G)" % [arg, _ctx.state.gold]
		DebugPanel.ITEMS:
			for id in Inventory.IDS:
				_ctx.state.inventory.add(id)
			text = "+1 de cada objeto (%d objetos)" % Inventory.IDS.size()
		DebugPanel.HEAL:
			_ctx.state.heal_full()
			text = "PV y PM llenos"
		DebugPanel.MONSTERS:
			World.debug_no_groups = not World.debug_no_groups
			if World.debug_no_groups:
				_ctx.world.clear_groups()
				text = "grupos quitados (quedan %d)" % _ctx.world.group_count()
			else:
				_travel.respawn_groups()
				text = "grupos puestos (%d)" % _ctx.world.group_count()
		DebugPanel.BOSS:
			var boss := EnemyLibrary.data(arg)
			var item := _ctx.state.on_boss_defeated(boss)
			if arg == Quest.BOSS_ID:
				_ctx.state.quest.stage = Quest.Stage.DONE  # as its real victory does
			if Bestiary.has(arg):
				# As --autoplay-zone does: beaten in the bestiary too, and a family may be complete.
				_ctx.state.see_enemy(arg)
				_ctx.state.defeat_enemy(arg)
			_ctx.state.story.mark_seen_for_flags(_ctx.state.world_flags)
			_ctx.world.set_world_flags(_ctx.state.world_flags)
			text = "%s %s" % [boss.display_name, "vencida" if boss.female else "vencido"]
			if item != "":
				text += " (+%s)" % Inventory.KEY_ITEMS[item]
			for line in BattleRewards.family_rewards(_ctx.state):
				text += " · " + line
		DebugPanel.QUEST:
			_ctx.state.quest.skip_stage()
			text = "misión de la aldea: %s" % DebugPanel.STAGE_NAMES[_ctx.state.quest.stage]
		DebugPanel.SAVE:
			var data := SaveData.from_state(_ctx.state, _ctx.world.player_position(), _ctx.play_time)
			text = "guardado en la ranura %d" % _ctx.slot if SaveStore.save_game(_ctx.slot, data) \
				else "no se pudo guardar"
	_battle.update_boss()
	_ctx.refresh_status.call()
	print("Depuración: %s" % text)
	_panel.show_result(text)


## DebugPanel's Ir a (the panel is already shut): under black to zone_id's start entry, as
## through an exit, with no autosave.
func _debug_go(zone_id: String) -> void:
	if _ctx.busy:
		return
	_ctx.set_busy.call(true)
	_ctx.world.freeze(true)
	await _ctx.fade.call(1.0)
	_travel.switch_zone(zone_id, "")
	_ctx.play_map_music.call()
	await _ctx.fade.call(0.0)
	await _ctx.world.freeze(false)
	print("Depuración: a %s" % _ctx.zone.map_label())
	_ctx.set_busy.call(false)
	_story.check_village_scene()
