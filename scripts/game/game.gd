class_name Game extends Node
## One play session, created by TitleScreen (setup() before add_child); run on its own
## (res://scenes/game/game.tscn) it starts a new game with its own AudioDirector and default
## options. A coordinator: it owns the GameState, the current map (in its SessionContext,
## which it passes to every piece), the fade, the saving (_autosave(), the pause menu's
## Guardar), the busy flag (_set_busy(): the pause menu and the debug panel only open on the
## map with nothing else going on), the map's status (_refresh_status()), the map music, the
## pause menu and the ShopWindow; it loads a save or starts a new game (the prologue), and
## emits quit_to_title when the player goes back to the title or an ending is over.
## Each job of the session is a piece, a child Node wired in _add_pieces(): ZoneTravel (the
## change of map, exits, the Ala and its portal), StoryFlow (the cutscenes and the endings),
## CaravanFlow (the v2's departure and companion), V3Flow (the v3's start in Brumaclara), FigureTalk (figures, shops, inns, wells,
## chests, the lever, the key, the gates), BattleFlow (the battles and the boss on the map),
## GameAutoplay (only with --autoplay) and GameDebug (only with --debug). What a piece awaits
## from another is a Callable Game wires; what it reports is a signal Game connects.
##
## `-- --autoplay --autoplay-save`: the first save after a won battle is printed
## ("Guardado: ...") and the title loads it at once ("Cargado: ...", printed here).
## `-- --autoplay --autoplay-menu`: MENU_TOUR_DELAY seconds into the map it shows every page
## of the pause menu (PauseMenu.tour()), to record frames of it.
## The other autoplay starts are in AutoplayStarts and GameAutoplay.

signal quit_to_title

const HERO_DATA := preload("res://data/hero.tres")
const FADE_TIME := 0.3
const TOUCH_HINT := "Toca el suelo para ir allí, o arrastra el dedo para andar."
const REPEL_END_NOTICE := "El incienso se ha consumido."
const SAVED_NOTICE := "Partida guardada."
const MENU_TOUR_DELAY := 1.0

var state: GameState
var _ctx: SessionContext
var _travel: ZoneTravel
var _story: StoryFlow
var _caravan: CaravanFlow
var _v3: V3Flow
var _talk: FigureTalk
var _battle: BattleFlow

var _fade: ColorRect
var _pause: PauseMenu
var _audio: AudioDirector
var _options: GameOptions
var _save := {}
## The name typed on the NameEntry for a new game ("" for the default).
var _hero_name := ""
## The difficulty chosen for a new game.
var _difficulty := Difficulty.NORMAL
var _leaving := false
## The save slot this game writes to (SaveStore; ignored on autoplay runs).
var _slot := 1
var _shop: ShopWindow
## The self-playing run, only with --autoplay (null otherwise).
var _autopilot: GameAutoplay
## The development piece, only with --debug (null otherwise).
var _debug: GameDebug


## audio and options come from the title screen; save is the Dictionary read by
## SaveStore.load_game(), empty for a new game, which gets hero_name and difficulty; slot is
## the save slot it writes to.
func setup(audio: AudioDirector, options: GameOptions, save: Dictionary,
		hero_name := "", difficulty := Difficulty.NORMAL, slot := 1) -> void:
	_slot = slot
	_audio = audio
	_options = options
	_save = save
	_hero_name = hero_name
	_difficulty = difficulty


func _ready() -> void:
	UiTheme.ensure(get_window())
	for line in QuestLog.problems():
		push_warning(line)
	if _options == null:
		_options = GameOptions.new()
	if _audio == null:
		_audio = AudioDirector.new()
		add_child(_audio)
		_audio.set_volumes(_options.music_volume, _options.sfx_volume)
	state = GameState.new(HERO_DATA)
	_make_context()
	_make_pieces()
	var load_failed := false
	var start_pos: Variant = null
	if not _save.is_empty():
		var info := SaveData.apply(state, _save)
		if info.valid:
			start_pos = info.position
			_ctx.play_time = info.play_time
			if RunFlags.autoplay() and RunFlags.autoplay_save():
				print("Cargado: %s" % CreditsData.summary(SaveData.from_state(state, info.position,
					info.play_time)))
			# The arrival lines of the lands already passed (and of this one) are not said
			# again on loading.
			Allies.mark_arrivals(state.world_flags, state.zone_id)
		else:
			load_failed = true
	if _save.is_empty() or load_failed:
		state.hero.display_name = StoryState.clean_name(_hero_name)
		state.difficulty = _difficulty
		if RunFlags.autoplay_easy():
			state.difficulty = Difficulty.EASY
	if _save.is_empty() and _autopilot:
		_autopilot.apply_start()
	# A loaded game (or an --autoplay-zone start) may have a family complete already: a
	# finished game gets the Espada del alba now. After the "Cargado:" line, so the save
	# round trip still compares what was saved.
	var family_lines := BattleRewards.family_rewards(state)
	_build_shop()
	_build_fade()
	_build_pause()
	if RunFlags.debug():
		_build_debug()
	_add_pieces(load_failed)
	if RunFlags.autoplay() and RunFlags.autoplay_menu():
		# The tour of the pause menu needs the map, not a scene.
		state.story.mark_seen("prologo")
	# Busy until the map is ready (no ☰ either): arriving inside a village must not start its
	# cutscene yet.
	_set_busy(true)
	_travel.switch_zone(state.zone_id, "")
	if start_pos != null:
		_ctx.world.place_player(start_pos)
		_travel.respawn_groups()
	var prologue := state.chapter() == StoryState.Chapter.PROLOGUE
	if prologue:
		# Under black: the prologue fades in by itself.
		_fade.color.a = 1.0
		_story.play_prologue.call_deferred()
	# Synthesize the tracks played later now, under black, so no first play stalls.
	for id in [MusicLibrary.VILLAGE, MusicLibrary.VICTORY, MusicLibrary.DEFEAT]:
		MusicLibrary.build(id)
	_play_map_music()
	if RunFlags.autoplay() and RunFlags.autoplay_menu():
		get_tree().create_timer(MENU_TOUR_DELAY).timeout.connect(_pause.tour)
	if not prologue:
		await _ctx.world.freeze(false)
		if not family_lines.is_empty():
			_audio.play_sfx(SfxLibrary.LEVEL_UP)
			await _ctx.world.show_dialogue("", family_lines)
			_autosave(false)
		if _save.is_empty():
			await _story.check_arrival_line()  # an --autoplay-zone start in a land (the jungle)
		_set_busy(false)
		_show_touch_hint()
		_story.check_village_scene()
		if _autopilot:
			_autopilot.start_medal_tour()


## The first time a phone reaches the map (never on autoplay): how to walk, once for good.
func _show_touch_hint() -> void:
	if not Device.is_touch() or RunFlags.autoplay() or _options.touch_hint_seen:
		return
	_options.touch_hint_seen = true
	SaveStore.save_options(_options)
	_ctx.world.show_touch_hint(TOUCH_HINT)


func _process(delta: float) -> void:
	_ctx.play_time += delta / Engine.time_scale  # a fast battle takes less play time, not more
	if _autopilot:
		_autopilot.step(delta)


## Back to the title: the map's ambient stops with the game. A Game run on its own frees its
## own AudioDirector first (it is a child), so there is nothing to stop.
func _exit_tree() -> void:
	if _audio and _audio.is_inside_tree():
		_audio.stop_ambient()


## The context the pieces share (SessionContext): built once, right after the GameState.
func _make_context() -> void:
	_ctx = SessionContext.new()
	_ctx.state = state
	_ctx.audio = _audio
	_ctx.options = _options
	_ctx.slot = _slot
	_ctx.fade = _fade_to
	_ctx.autosave = _autosave
	_ctx.set_busy = _set_busy
	_ctx.refresh_status = _refresh_status
	_ctx.play_map_music = _play_map_music


## The pieces of the session, created at once (so the pause menu and the debug panel can be
## wired to them); set up and added to the tree later, by _add_pieces().
func _make_pieces() -> void:
	_travel = ZoneTravel.new()
	_story = StoryFlow.new()
	_caravan = CaravanFlow.new()
	_v3 = V3Flow.new()
	_talk = FigureTalk.new()
	_battle = BattleFlow.new()
	if RunFlags.autoplay():
		_autopilot = GameAutoplay.new()
		_autopilot.setup(_ctx)


## The pieces set up, wired and added, where Game used to build what they hold (node
## order matters for input and processing). Callables are what a piece awaits from another
## one; signals are what it only reports.
func _add_pieces(load_failed: bool) -> void:
	_travel.setup(_ctx)
	_travel.check_arrival_line = _story.check_arrival_line
	_travel.check_village_scene = _story.check_village_scene
	_travel.update_boss = _battle.update_boss
	_travel.world_replaced.connect(_on_world_replaced)
	_travel.village_checked.connect(_on_village_changed)
	add_child(_travel)
	_story.setup(_ctx)
	_story.load_failed = load_failed
	_story.switch_zone = _travel.switch_zone
	_story.choose_companion = _caravan.choose_companion
	_story.show_touch_hint = _show_touch_hint
	_story.quit_requested.connect(func() -> void: quit_to_title.emit())
	add_child(_story)
	_caravan.setup(_ctx, _shop)
	_caravan.play_scene = _story.play_scene
	_caravan.switch_zone = _travel.switch_zone
	add_child(_caravan)
	_v3.setup(_ctx)
	_travel.zone_switched.connect(_v3.on_zone_switched)
	add_child(_v3)
	_talk.setup(_ctx, _shop)
	_talk.update_boss = _battle.update_boss
	_talk.choose_companion = _caravan.choose_companion
	_talk.ask_departure = _caravan.ask_departure
	_talk.check_village_scene = _story.check_village_scene
	_talk.respawn_groups = _travel.respawn_groups
	_talk.spawn_rare = _travel.spawn_rare
	add_child(_talk)
	_battle.setup(_ctx)
	_battle.play_scene = _story.play_scene
	_battle.finish_game = _story.finish_game
	_battle.finish_v2 = _story.finish_v2
	_battle.go_to_town = _travel.go_to_town
	_battle.print_save = RunFlags.autoplay() and RunFlags.autoplay_save() and _save.is_empty()
	_battle.quit_requested.connect(func() -> void: quit_to_title.emit())
	add_child(_battle)
	if _autopilot:
		_autopilot.use_pieces(_travel, _talk)
		_travel.zone_switched.connect(_autopilot.on_zone_switched)
		_travel.portal_taken.connect(_autopilot.reset_quiet)
		_story.game_completed.connect(_autopilot.print_game_completed)
		_story.v2_completed.connect(_autopilot.print_v2_completed)
		_autopilot.quit_requested.connect(func() -> void: quit_to_title.emit())
		_caravan.autoplay_companion = _autopilot.companion
		_caravan.autoplay_leaves = _autopilot.plays_v2
		_battle.echo_wanted = _autopilot.echo
		_battle.medal_chance = AutoplayStarts.MEDAL_TOUR_CHANCE if _autopilot.medal_tour \
			else Medals.DROP_CHANCE
		_battle.after_battle = _autopilot.after_battle
		_battle.battle_started.connect(_autopilot.reset_quiet)
		_battle.enemies_beaten.connect(_autopilot.on_enemies_beaten)
		_battle.battle_lost.connect(_autopilot.on_battle_lost)
		_battle.echo_fought.connect(_autopilot.on_echo_fought)
		add_child(_autopilot)


## ZoneTravel built a new map: the old one goes, the new one is first in the tree and stays
## frozen until its caller's fade is over.
func _on_world_replaced(world: World) -> void:
	if _ctx.world:
		remove_child(_ctx.world)
		_ctx.world.queue_free()
	_ctx.world = world
	add_child(world)
	move_child(world, 0)
	world.freeze(true)
	world.set_audio(_audio)
	world.encounter_triggered.connect(_battle.on_encounter)
	world.talk_requested.connect(_talk.on_talk)
	world.npc_requested.connect(_talk.on_npc)
	world.shop_requested.connect(_talk.on_shop)
	world.inn_requested.connect(_talk.on_inn)
	world.chest_opened.connect(_talk.on_chest)
	world.well_requested.connect(_talk.on_well)
	world.exit_requested.connect(_travel.on_exit)
	world.map_requested.connect(_pause.open_map)
	world.portal_used.connect(_travel.on_portal)
	world.lever_pulled.connect(_talk.on_lever)
	world.key_taken.connect(_talk.on_key)
	world.door_used.connect(_talk.on_door)
	world.village_changed.connect(_on_village_changed)
	world.stepped.connect(_on_stepped)


## Inside a village it becomes the last one visited; the music follows. The first
## visit plays the village's cutscene.
func _on_village_changed(inside: bool) -> void:
	if inside and _ctx.zone.town_entry != "":
		state.town_zone = _ctx.zone.id
	_play_map_music()
	if inside:
		_story.check_village_scene()


## Writes the save file; shows SAVED_NOTICE if notice. Returns the saved data, or an
## empty Dictionary if the file could not be written.
func _autosave(notice: bool) -> Dictionary:
	var data := SaveData.from_state(state, _ctx.world.player_position(), _ctx.play_time)
	if not SaveStore.save_game(_slot, data):
		return {}
	if notice:
		_audio.play_sfx(SfxLibrary.SAVE)
		_ctx.world.show_notice(SAVED_NOTICE, "Guardado", &"text-positive")
	return data


func _on_save_requested() -> void:
	var data := SaveData.from_state(state, _ctx.world.player_position(), _ctx.play_time)
	_pause.show_save_result(SaveStore.save_game(_slot, data))


## The tree stays paused (TitleScreen unpauses when it frees this game), so the map can't
## walk or roll an encounter during the fade; the menu is shut and deaf meanwhile.
func _on_title_requested() -> void:
	if _leaving:
		return
	_leaving = true
	_set_busy(true)
	_pause.hide()
	_pause.set_process_unhandled_input(false)
	quit_to_title.emit()


## The zone's map music, or its village one inside the village, and the zone's ambient
## under it (after a battle or a cutscene that silenced it, it comes back here).
func _play_map_music() -> void:
	_audio.play_music(_ctx.zone.village_music if _ctx.world.in_village() else _ctx.zone.music)
	_audio.play_ambient(_ctx.zone.ambient)


## The pause menu (and, with --debug, the debug panel) only opens on the map with nothing
## else going on.
func _set_busy(busy: bool) -> void:
	_ctx.busy = busy
	_pause.available = not busy and not RunFlags.autoplay()
	if _debug:
		_debug.set_available(not busy)


## Every STEP_DISTANCE metres walked: two steps for the credits, and the Incienso burns.
func _on_stepped() -> void:
	state.steps += 2
	if state.repel_m <= 0.0:
		return
	state.repel_m = maxf(0.0, state.repel_m - World.STEP_DISTANCE)
	if state.repel_m == 0.0:
		_ctx.world.set_repel(false)
		_ctx.world.show_notice(REPEL_END_NOTICE)


## Updates the map's status window, the quests' marks and sought figures and the hero's
## weapon and shield.
func _refresh_status() -> void:
	state.sync_level_cap()
	var missions := state.current_missions()
	_ctx.world.refresh_status(state.hero, _ctx.potion_count(), state.gold,
		missions)
	_ctx.world.set_monsters_shy(EncounterMeter.is_shy(state.hero.level, _ctx.zone.exit_level))
	_ctx.world.set_repel(state.repel_m > 0.0)
	_ctx.world.set_autoplay_hunt(_autopilot != null and _autopilot.hunts())
	var hidden := state.quests.hidden_figures(_ctx.zone.id)
	hidden.append_array(_ctx.zone.absent_figures(state.world_flags))
	# The companions not chosen never show (the figures of the cruce scene in ciudad_2).
	for id in Allies.COMPANIONS:
		if id != state.ally_id:
			hidden.append(Allies.display_name(id))
	_ctx.world.set_quest_view(state.quests.markers(_ctx.zone.id, state.inventory, state.world_flags),
		hidden)
	var loadout := state.loadout
	_ctx.world.set_hero_equipment(loadout.worn(Equipment.WEAPON), loadout.worn(Equipment.SHIELD),
		loadout.worn(Equipment.HELMET))
	if _autopilot:
		_autopilot.note_status(missions)


func _build_shop() -> void:
	var layer := CanvasLayer.new()
	layer.layer = UiTokens.LAYER_SHOP
	add_child(layer)
	_shop = ShopWindow.new()
	_shop.setup(state, _audio)
	layer.add_child(_shop)


func _build_fade() -> void:
	var layer := CanvasLayer.new()
	layer.layer = UiTokens.LAYER_FADE
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = UiTokens.color(&"black")
	_fade.color.a = 0.0
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade)


func _build_pause() -> void:
	var layer := CanvasLayer.new()
	layer.layer = UiTokens.LAYER_PAUSE
	add_child(layer)
	_pause = PauseMenu.new()
	_pause.setup(state, _options, _audio)
	layer.add_child(_pause)
	_pause.save_requested.connect(_on_save_requested)
	_pause.title_requested.connect(_on_title_requested)
	_pause.travel_requested.connect(_travel.on_travel_requested)
	_pause.in_village = func() -> bool: return _ctx.world.in_village()
	_pause.hero_position = func() -> Vector3: return _ctx.world.player_position()
	_pause.state_changed.connect(_refresh_status)
	_pause.open_changed.connect(func(is_open: bool) -> void:
		_ctx.world.set_status_shown(not is_open))
	_pause.available = not RunFlags.autoplay()


## --debug: the panel and its actions (GameDebug), where the debug panel was built.
func _build_debug() -> void:
	_debug = GameDebug.new()
	_debug.setup(_ctx, _travel, _battle, _story)
	add_child(_debug)


func _fade_to(alpha: float) -> void:
	var t := create_tween()
	t.tween_property(_fade, "color:a", alpha, FADE_TIME)
	await t.finished
