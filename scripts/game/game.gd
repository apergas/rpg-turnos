class_name Game extends Node
## One play session, created by TitleScreen (setup() before add_child). Owns the
## GameState and the map of the current zone (a World built from its ZoneData), and puts
## a battle on top of the map when the hero touches a group of monsters on it (its
## formation, World.contact_enemies()) or the zone's boss. The map stays while battles
## come and go, so the hero's position, the camera and the groups survive them; walking
## into an open exit fades to black, frees the map and builds the next zone at the exit's
## entry (GameState.zone_id), every group back. A victory adds the gold and counts
## every enemy defeated for the quest; a boss also sets its world flag (the Rey Slime
## lifts the fog of the meadow's north exit) and gives its key item. Fleeing just goes
## back to the map; a defeat takes half the gold (GameState.defeat_gold_loss()), heals the
## hero and sends them to the last village visited (GameState.town_zone), EXP kept, like
## the Ala de viaje used from the pause menu, which also leaves a portal in that village
## that leads back once (GameState.open_portal(); a second Ala replaces it, a defeat leaves
## it open). Talking to the old woman heals, moves the
## quest on and, once the slimes are reported, brings out the Rey Slime; the other
## villagers say their ZoneData lines. The Coleccionista of Villaclaro trades the small medals for
## prizes (Medals.talk()); a battle's medal drops go to GameState.medals (Medals.take()).
## The merchant opens the ShopWindow; the innkeeper
## offers a free night (Inn.stay(): fade to black, full HP and MP, autosave); a chest gives
## what it holds (Chests.open()) and stays open. The hero's figure on the map and in
## battle shows the weapon and shield worn. On a dungeon floor the lever sets its world
## flag (and opens the gates it works), the key goes to the key items (and its flag is
## set, so it stays taken) and a locked gate opens with the key, which is used up; all
## three autosave silently. Picks the zone's music (map, village, battle,
## boss), autosaves after talking, after every won battle, after shopping, (silently)
## after opening a chest, after a defeat and after every change of zone, and opens the
## pause menu. Emits quit_to_title when the player goes back to the title.
## With `--debug` on the command line (never otherwise) it owns a DebugPanel: F1 on the map
## opens it, and Game does what its buttons ask (_on_debug(), printed as "Depuración: ...").
## The story (GameState.story): a new game opens with the prologue in the hero's house
## (data/cutscenes/prologo.tres, which starts the slimes quest); each boss beaten plays
## its cutscene (StoryState.AFTER_BOSS) and the first visit to each village its own
## (StoryState.ON_VILLAGE), through the CutscenePlayer; the villagers' lines follow the
## chapter. Beating the Señor de la Niebla (GameState.FINAL_BOSS) plays the ending (back
## to Villaclaro), marks the save as finished (story.finished) and StoryFlow rolls the credits with
## the numbers of the game (CreditsScreen); then it goes back to the title. A finished
## save loads in Villaclaro and the world can still be walked.
## Each bestiary family beaten whole (Bestiary) gives its prize once, after the battle that completes it or when a game is loaded, in the dialogue window.
## The side quests (GameState.quests): a villager or a board asks the QuestLog first (a
## report, a figure found, a new offer) and says its chapter lines if it has nothing about
## any; the map shows the marks and the sought figures it says. Each finished quest shows
## for a few seconds (World.show_mission_done()) and no quest holds anything back. On
## autoplay it reads and talks like a player on its route, uses the seeds at once and flies
## back to report to whoever is waiting in the last village.
## On autoplay it prints the gold and the equipment each time they change, the level and
## the play time on every change of zone and, after the credits, the play time of the
## whole run (TitleScreen then quits). After a won battle, when the hero needs rest
## (GameState.needs_rest()) or the map has no group left (_needs_groups()) away from a
## village, it flies back with an Ala de viaje, sleeps at the inn, restocks at the shop
## and goes back through the portal; after a defeat it
## sleeps and restocks too. With no Ala de viaje an empty map gets its groups back at once.
## Run on its own (res://scenes/game/game.tscn) it starts a new game with its own
## AudioDirector and default options.
##
## `-- --autoplay --autoplay-save`: after the first autosave that follows a won battle
## it prints the saved values ("Guardado: ...") and goes back to the title, which loads
## the save at once; the loaded game prints the same values ("Cargado: ...").
## `-- --autoplay --autoplay-menu`: MENU_TOUR_DELAY seconds into the map (before any group
## is in reach) it shows every page of the pause menu (PauseMenu.tour()), to
## record frames of it.
## `-- --autoplay --autoplay-zone=<id>`: a new game that starts in that zone with the
## level, gold, gear and progress AUTOPLAY_ZONES gives it.
## `-- --autoplay --autoplay-zone=ciudad` / `portal`: the v2's last stretch: Lv 35 at the city's
## first floor (the Grifo beaten), or Lv 38 at the portal quarter (the Guardián beaten, its
## key); they play on to the Devorador, the ending, the v2's credits and "Continuará".
## `-- --autoplay --autoplay-zone=medallas`: the finished game of ECHO_START in Villaclaro;
## it hunts the meadow's groups until it carries every medal dropped (MEDAL_TOUR_CHANCE),
## then talks to the Coleccionista and prints "Medallas: n/12 · premios n/5".
## `-- --autoplay --autoplay-zone=eco`: a finished game in the throne room at Lv 20 that
## fights the Eco de la Niebla again and again, printing each result.
## `-- --autoplay --autoplay-easy`: a new game on Fácil.

signal quit_to_title

const HERO_DATA := preload("res://data/hero.tres")
const BATTLE_SCENE := preload("res://scenes/battle/battle_scene.tscn")
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
var _talk: FigureTalk

var _fade: ColorRect
var _pause: PauseMenu
var _audio: AudioDirector
var _options: GameOptions
var _save := {}
## The name typed on the NameEntry for a new game ("" for the default).
var _hero_name := ""
## The difficulty chosen for a new game.
var _difficulty := Difficulty.NORMAL
## Autoplay: seconds since the last battle or change of map (AUTOPLAY_STALL_S).
var _quiet_s := 0.0
var _leaving := false
var _autoplay := false
var _autoplay_save := false
var _autoplay_menu := false
## --autoplay-companion=<id>: the companion autoplay chooses at the Caravana (Brena if none).
var _autoplay_companion := "brena"
## --autoplay-zone=caravana / jungla: autoplay leaves with the caravan and plays the v2.
var _autoplay_v2 := false
var _last_missions: Array[String] = []
var _last_gear_text := ""
## The save slot this game writes to (SaveStore; ignored on autoplay runs).
var _slot := 1
## Autoplay: defeats so far (each prints "Derrota en <zone> (n)"; the credits say the total).
var _defeats := 0
## --autoplay-zone=eco: autoplay goes for the Eco de la Niebla (never on any other run).
var _autoplay_echo := false
## --autoplay-zone=eco: fights with the Eco and how many were won, printed after each.
var _echo_fights := 0
var _echo_wins := 0
## --autoplay-zone=medallas: the tour is on.
var _medal_tour := false
## Autoplay: common enemies beaten in won battles (the credits print it with the medals, to
## tune Medals.DROP_CHANCE).
var _common_beaten := 0
var _shop: ShopWindow
## The development panel, only with --debug (null otherwise).
var _debug: DebugPanel


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
	_autoplay = RunFlags.autoplay()
	_autoplay_save = RunFlags.autoplay_save()
	_autoplay_menu = RunFlags.autoplay_menu()
	_autoplay_companion = AutoplayStarts.companion()
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
			if _autoplay_save:
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
	if _save.is_empty() and _autoplay:
		_apply_autoplay_zone()
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
	if _autoplay_menu:
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
	if _autoplay_menu:
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
		if _medal_tour:
			print("Medallas: a cazar en %s" % _ctx.zone.id)
			get_tree().create_timer(AutoplayStarts.MEDAL_TOUR_TIME).timeout.connect(_on_medal_tour_timeout)


## The first time a phone reaches the map (never on autoplay): how to walk, once for good.
func _show_touch_hint() -> void:
	if not Device.is_touch() or _autoplay or _options.touch_hint_seen:
		return
	_options.touch_hint_seen = true
	SaveStore.save_options(_options)
	_ctx.world.show_touch_hint(TOUCH_HINT)


func _process(delta: float) -> void:
	_ctx.play_time += delta / Engine.time_scale  # a fast battle takes less play time, not more
	if _autoplay and not _ctx.busy and _ctx.world != null and not _ctx.world.in_village():
		_quiet_s += delta
		if _quiet_s > AutoplayStarts.AUTOPLAY_STALL_S and _autoplay_hunts():
			_quiet_s = 0.0
			print("Grupos repuestos (partida automática, sin combates)")
			_travel.respawn_groups()
		elif _quiet_s > AutoplayStarts.AUTOPLAY_STALL_S and _boss_needs_rest() \
				and state.inventory.count(Inventory.WING) > 0:
			# At the boss's level but too worn for it, with no battle coming that would bring
			# the retreat: one Ala, made here (the quiet clock starts over).
			_quiet_s = 0.0
			_autoplay_retreat()


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
	_talk = FigureTalk.new()


## The pieces set up, wired and added, where Game used to build what they hold (node
## order matters for input and processing). Callables are what a piece awaits from another
## one; signals are what it only reports.
func _add_pieces(load_failed: bool) -> void:
	_travel.setup(_ctx)
	_travel.check_arrival_line = _story.check_arrival_line
	_travel.check_village_scene = _story.check_village_scene
	_travel.update_boss = _update_boss
	_travel.world_replaced.connect(_on_world_replaced)
	_travel.zone_switched.connect(_on_zone_switched)
	_travel.village_checked.connect(_on_village_changed)
	_travel.portal_taken.connect(_on_portal_taken)
	add_child(_travel)
	_story.setup(_ctx)
	_story.load_failed = load_failed
	_story.switch_zone = _travel.switch_zone
	_story.choose_companion = _caravan.choose_companion
	_story.show_touch_hint = _show_touch_hint
	_story.quit_requested.connect(func() -> void: quit_to_title.emit())
	_story.game_completed.connect(_on_game_completed)
	_story.v2_completed.connect(_on_v2_completed)
	add_child(_story)
	_caravan.setup(_ctx, _shop)
	_caravan.play_scene = _story.play_scene
	_caravan.switch_zone = _travel.switch_zone
	_caravan.autoplay_companion = _autoplay_companion
	_caravan.autoplay_leaves = _autoplay_v2
	add_child(_caravan)
	_talk.setup(_ctx, _shop)
	_talk.update_boss = _update_boss
	_talk.choose_companion = _caravan.choose_companion
	_talk.ask_departure = _caravan.ask_departure
	_talk.check_village_scene = _story.check_village_scene
	_talk.respawn_groups = _travel.respawn_groups
	_talk.spawn_rare = _travel.spawn_rare
	add_child(_talk)


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
	world.encounter_triggered.connect(_on_encounter)
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


## A map was built: autoplay's quiet clock starts over, and on autoplay the zone is printed.
func _on_zone_switched(zone_id: String) -> void:
	_quiet_s = 0.0
	if RunFlags.autoplay():
		print("Zona: %s (Nv %d, %s)" % [zone_id, state.hero.level,
			CreditsData.clock(_ctx.play_time)])


## The return portal was taken: autoplay's quiet clock starts over.
func _on_portal_taken() -> void:
	_quiet_s = 0.0


## Autoplay: the numbers of the whole run after the v1's credits.
func _on_game_completed(time_text: String) -> void:
	print("Juego completado: Nv %d, tiempo de juego %s, misiones %d" % [state.hero.level,
		time_text, state.quests_done()])
	print("Familias completas: %d/%d" % [Bestiary.complete_count(state),
		Bestiary.families(state).size()])
	print("Derrotas: %d" % _defeats)
	print("Medallas: %d/%d (enemigos comunes vencidos: %d)" % [state.medals.size(),
		Medals.MEDALS.size(), _common_beaten])


## Autoplay: the numbers of the v2 after its credits.
func _on_v2_completed(numbers: Dictionary) -> void:
	print("Juego completado (v2): Nv %d, tiempo en la caravana %s, tiempo de juego %s, misiones de la caravana %d/%d"
		% [state.hero.level, numbers.time, CreditsData.clock(_ctx.play_time),
		state.quests.done_of(true), QuestLog.total_of(true)])
	print("Familias completas: %d/%d" % [Bestiary.complete_count(state),
		Bestiary.families(state).size()])
	print("Derrotas: %d" % _defeats)
	print("Medallas: %d/%d (enemigos comunes vencidos: %d)" % [state.medals.size(),
		Medals.MEDALS.size(), _common_beaten])


## --autoplay-zone=<id>: starts the new game in that zone with AUTOPLAY_ZONES' state.
func _apply_autoplay_zone() -> void:
	var start_id := RunFlags.autoplay_zone()
	if start_id == "":
		return
	var start: Dictionary = AutoplayStarts.AUTOPLAY_ZONES.get(start_id, {})
	var zone_id: String = start.get("zone", start_id)
	if not zone_id in ZoneData.IDS:
		push_error("Unknown zone for --autoplay-zone: %s" % start_id)
		return
	state.zone_id = zone_id
	if start.is_empty():
		return
	state.hero.experience = start.experience
	Leveling.apply(state.hero)
	state.heal_full()
	state.gold = start.gold
	for id: String in start.gear:
		state.bag_equipment.append(id)
		state.equip(id)
	for flag: String in start.flags:
		state.world_flags[flag] = true
		if Bestiary.has(flag):
			# A boss of the flags was beaten on the way: the bestiary says so too.
			state.defeat_enemy(flag)
	for id: String in start.get("key_items", []):
		state.key_items.append(id)
	state.town_zone = start.get("town", state.town_zone)
	if start.quest_done:
		state.quest.stage = Quest.Stage.DONE
	# The v2's level cap needs the "caravana" flag, set just above: levels again.
	# (the first pass at the v1 cap clamped the EXP: give it back).
	state.sync_level_cap()
	state.hero.experience = start.experience
	Leveling.apply(state.hero)
	state.heal_full()
	state.ally_id = start.get("ally", "")
	if Allies.is_companion(state.ally_id):
		state.ally_id = _autoplay_companion
	var items: Dictionary = start.get("items", {})
	for id: String in items:
		state.inventory.add(id, items[id])
	_autoplay_echo = start_id == AutoplayStarts.ECHO_START
	_autoplay_v2 = start_id in AutoplayStarts.V2_STARTS
	_medal_tour = start_id == AutoplayStarts.MEDAL_TOUR
	state.story.mark_seen_for_flags(state.world_flags)
	if start.get("finished", false):
		state.story.finished = true
	state.sync_level_cap()
	print("Zona de inicio: %s (Nv %d)" % [zone_id, state.hero.level])


func _on_encounter(boss: bool) -> void:
	if _ctx.busy:
		return
	_set_busy(true)
	_quiet_s = 0.0
	state.battles += 1
	var enemies: Array[Combatant] = []
	if boss:
		enemies.append(EnemyLibrary.data(_boss_id()))
	else:
		enemies = _ctx.world.contact_enemies()
	if not boss:
		var kept := state.give_metal_slime_hp(enemies)
		if _autoplay and kept > 0:
			print("Slime de Metal con PV %d" % kept)
	BattleRewards.note_enemies(state, enemies, false)
	var echo := boss and _boss_id() == _ctx.zone.postgame_boss_id
	await _fade_to(1.0)
	_ctx.world.set_active(false)
	_audio.play_music(MusicLibrary.BOSS if boss else MusicLibrary.BATTLE)
	_audio.stop_ambient()
	var battle: BattleScene = BATTLE_SCENE.instantiate()
	battle.setup(state.hero, enemies, state.inventory)
	battle.set_audio(_audio)
	battle.set_equipment(state.loadout.worn(Equipment.WEAPON),
		state.loadout.worn(Equipment.SHIELD), state.loadout.worn(Equipment.HELMET))
	battle.gold_lost = state.defeat_gold_loss()
	battle.char_time = _options.char_time()
	battle.time_scale = _options.combat_scale()
	battle.camera_shake = _options.camera_shake
	state.sync_level_cap()
	battle.difficulty = state.difficulty
	battle.zone = _ctx.zone
	battle.quest_items = state.quests.wanted_items(state)
	battle.medals_carried = state.medals.size()
	battle.medal_chance = AutoplayStarts.MEDAL_TOUR_CHANCE if _medal_tour else Medals.DROP_CHANCE
	if state.ally_id != "":
		battle.ally = Allies.data(state.ally_id, state.tramo())
	add_child(battle)
	await _fade_to(0.0)
	var outcome: int = await battle.finished
	# A call for help adds enemies during the fight.
	BattleRewards.note_enemies(state, battle.engine.enemies, false)
	var won := outcome == BattleEngine.State.WON
	if _autoplay and echo:
		_echo_fights += 1
		_echo_wins += 1 if won else 0
		print("Eco de la Niebla: %s (%d de %d ganados)" % ["victoria" if won else "derrota",
			_echo_wins, _echo_fights])
	if won or outcome == BattleEngine.State.LOST:
		Wells.on_battle(state)
		_ctx.world.set_dry_wells(Wells.dry_ids(state))
	await _fade_to(1.0)
	if not boss:
		# Under black: a beaten group leaves the map, one fled from stays half see-through.
		_ctx.world.end_contact(outcome)
	if state.keep_metal_slime_hp(battle.engine.enemies, outcome) > 0:
		if _autoplay:
			print("Slime de Metal: PV %d guardados" % state.metal_slime_hp)
		_autosave(false)  # a fled battle saves nothing else: quitting now must not lose them
	var notice := ""
	var reward_lines: Array[String] = []
	var scene := ""
	var mission_done := false
	var finished_quests: Array[Dictionary] = []
	var family_lines: Array[String] = []
	var ending_v2 := false
	if won:
		var rewards := BattleRewards.after_victory(state, _ctx.zone, battle.engine.enemies,
			battle.engine.gold_won, battle.engine.medals_won, boss)
		notice = rewards.notice
		reward_lines.assign(rewards.reward_lines)
		scene = rewards.scene
		mission_done = rewards.mission_done
		finished_quests.assign(rewards.finished_quests)
		family_lines.assign(rewards.family_lines)
		ending_v2 = rewards.ending_v2
		if _autoplay:
			for enemy in battle.engine.enemies:
				if not enemy.is_boss:
					_common_beaten += 1
			if battle.engine.medals_won > 0:
				print("Medalla: %d/%d" % [state.medals.size(), Medals.MEDALS.size()])
	elif outcome == BattleEngine.State.LOST:
		if _autoplay:
			_defeats += 1
			print("Derrota en %s (%d)" % [_ctx.zone.id, _defeats])
		state.gold -= battle.gold_lost
		state.heal_full()
		_travel.go_to_town()
		notice = "Has vuelto %s." % ZoneTravel.to_place(_ctx.zone.village_name)
	battle.queue_free()
	_ctx.world.set_world_flags(state.world_flags)
	_update_boss()
	_refresh_status()
	_ctx.world.set_active(true)
	# Frozen until the fade is over: an exit or an encounter while Game is busy would be
	# ignored and leave the map waiting forever.
	_ctx.world.freeze(true)
	_play_map_music()
	if scene != "":
		# Under black: no status window or map square while the map fades in.
		_ctx.world.begin_cutscene()
	await _fade_to(0.0)
	if scene != "":
		# The boss's cutscene says what the notice would (the fragment, the open road).
		await _story.play_scene(scene)
	else:
		await _ctx.world.freeze(false)
		if not reward_lines.is_empty():
			await _ctx.world.show_dialogue("", reward_lines)
		elif notice != "":
			_ctx.world.show_notice(notice, "Premio", &"text-positive")
	if not family_lines.is_empty():
		_audio.play_sfx(SfxLibrary.LEVEL_UP)
		await _ctx.world.show_dialogue("", family_lines)
	if mission_done:
		_ctx.world.show_mission_done(QuestLog.done_text(Quest.TITLE))
	for finished: Dictionary in finished_quests:
		_ctx.world.show_mission_done(QuestLog.done_text(finished.title))
		_ctx.world.show_notice(" ".join(finished.lines), "Misión cumplida", &"text-positive")
	if ending_v2:
		await _story.finish_v2()
		return
	if won and state.is_finished() and not state.story.finished:
		await _story.finish_game()
		return
	if outcome == BattleEngine.State.LOST:
		_autosave(false)  # the gold lost sticks: going back to the title can't undo it
	if won:
		var data := _autosave(not boss and finished_quests.is_empty())  # keep its reward readable
		if _autoplay_save and _save.is_empty() and not data.is_empty():
			print("Guardado: %s" % CreditsData.summary(data))
			quit_to_title.emit()
			return
	_set_busy(false)
	if _medal_tour and won and state.medals.size() >= Medals.MEDALS.size():
		await _finish_medal_tour()
		return
	if _autoplay and won and _wants_retreat():
		await _autoplay_retreat()
	elif _autoplay and won and _needs_groups():
		# No Ala de viaje (or in a village): the groups come back as if it had flown away
		# and back. Only the autoplay does this.
		print("Grupos repuestos (partida automática)")
		_travel.respawn_groups()
	elif _autoplay and outcome == BattleEngine.State.LOST:
		await _autoplay_restock()


## Autoplay: flies back to the last village with an Ala de viaje, rests and shops there and
## comes back through the portal.
func _autoplay_retreat() -> void:
	state.inventory.take(Inventory.WING)
	print("Retirada al pueblo (PV %d/%d, PM %d, pociones %d)" % [state.hero.hp,
		state.hero.max_hp, state.hero.mp, _ctx.potion_count()])
	await _travel.on_travel_requested()
	await _autoplay_restock()
	await _travel.on_portal()


## Autoplay: needs rest (GameState.needs_rest()), is only kept from the zone's boss by its
## HP or MP, has a report waiting in the last village or has no group left to fight
## (_needs_groups(): the portal back brings them), away from a village, with an Ala de
## viaje (the night at the inn is free). The route may never pass the one who waits.
func _wants_retreat() -> bool:
	if _medal_tour:
		return false  # the medal tour never flies back: it hunts where it is
	var report := not state.quests.reports_here(state.town_zone, state.inventory).is_empty()
	return (state.needs_rest() or _boss_needs_rest() or report or _needs_groups()) \
		and not _ctx.world.in_village() and state.inventory.count(Inventory.WING) > 0


## Autoplay: no group left on this map while the hero still has levels to win before its
## boss (they only come back when the map is built again).
func _needs_groups() -> bool:
	return _ctx.world.group_count() == 0 and _autoplay_hunts()


## Autoplay: the hero goes after the groups while he has levels to win before the zone's
## boss. The medal tour hunts until it carries every medal.
func _autoplay_hunts() -> bool:
	if _medal_tour:
		return state.medals.size() < Medals.MEDALS.size()
	return state.hero.level < _ctx.zone.autoplay_boss_level


## Autoplay: the zone's boss is due at this level but the hero is too worn for it. MP
## doesn't come back by walking, so without a rest the boss would never show up.
func _boss_needs_rest() -> bool:
	return _boss_wanted() and state.hero.level >= _ctx.zone.autoplay_boss_level \
		and not AutoplayStarts.rested_for_boss(state.hero)


## The boss of the current map: the zone's, or its postgame boss (ZoneData.postgame_boss_id)
## once the game is finished.
func _boss_id() -> String:
	return BattleRewards.boss_id(_ctx.zone, state)


func _boss_wanted() -> bool:
	return BattleRewards.boss_wanted(_ctx.zone, state, not _autoplay or _autoplay_echo)


## Autoplay, in the village: a night at its inn and the shop's picks, as if the hero had
## walked up to the innkeeper and the merchant.
func _autoplay_restock() -> void:
	for npc: Dictionary in _ctx.zone.npcs:
		if npc.kind == "inn":
			await _talk.on_inn(npc.id)
	for npc: Dictionary in _ctx.zone.npcs:
		if npc.kind == "shop":
			await _talk.on_shop(npc.id)
	# On a caravan game the figures that offer a quest ("!") are visited too, or autoplay
	# would never take the v2's quests; a v1 game keeps the reports only.
	var marks := {}
	if state.in_caravan():
		marks = state.quests.markers(_ctx.zone.id, state.inventory, state.world_flags)
	for i in _ctx.zone.npcs.size():
		var npc_name: String = _ctx.zone.npcs[i].name
		if npc_name in state.quests.reports_here(_ctx.zone.id, state.inventory) \
				or marks.get(npc_name, "") == QuestLog.NEW_MARK:
			await _talk.on_npc(i)


## Inside a village it becomes the last one visited; the music follows. The first
## visit plays the village's cutscene.
func _on_village_changed(inside: bool) -> void:
	if inside and _ctx.zone.town_entry != "":
		state.town_zone = _ctx.zone.id
	_play_map_music()
	if inside:
		_story.check_village_scene()


## --autoplay-zone=medallas: the time is up with medals still missing; it ends anyway.
func _on_medal_tour_timeout() -> void:
	if not _medal_tour:
		return
	while _ctx.busy:
		await get_tree().create_timer(1.0).timeout
	if not _medal_tour:  # the tour finished by itself while this waited
		return
	print("Medallas: tiempo agotado (%d/%d)" % [state.medals.size(), Medals.MEDALS.size()])
	await _finish_medal_tour()


## --autoplay-zone=medallas: under black to Villaclaro, the Coleccionista; then the forest
## village's (his joke); the counts printed and back to the title (which quits on autoplay).
func _finish_medal_tour() -> void:
	_medal_tour = false
	_set_busy(true)
	for zone_id in [Medals.COLLECTOR_ZONE, "bosque"]:
		await _fade_to(1.0)
		var town := ZoneData.by_id(zone_id)
		_travel.switch_zone(town.id, town.town_entry)
		_play_map_music()
		await _fade_to(0.0)
		await _ctx.world.freeze(false)
		await _talk.talk_to_collector()
	print("Medallas: %d/%d · premios %d/%d" % [state.medals.size(), Medals.MEDALS.size(),
		state.medal_prizes, Medals.PRIZES.size()])
	quit_to_title.emit()


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


## The zone's boss is on the map until beaten: the Rey Slime only while the quest asks
## for it; on autoplay only from the zone's autoplay_boss_level on, and only while the
## hero has AUTOPLAY_BOSS_HP of his max HP and AUTOPLAY_BOSS_MP of his max MP (a worn-out
## hero fights on, or rests, first).
func _update_boss() -> void:
	if _boss_id() == "":
		return
	var strong_enough := not _autoplay or (state.hero.level >= _ctx.zone.autoplay_boss_level \
		and AutoplayStarts.rested_for_boss(state.hero))
	_ctx.world.set_boss_present(_boss_wanted() and strong_enough)


## The zone's map music, or its village one inside the village, and the zone's ambient
## under it (after a battle or a cutscene that silenced it, it comes back here).
func _play_map_music() -> void:
	_audio.play_music(_ctx.zone.village_music if _ctx.world.in_village() else _ctx.zone.music)
	_audio.play_ambient(_ctx.zone.ambient)


## The pause menu (and, with --debug, the debug panel) only opens on the map with nothing
## else going on.
func _set_busy(busy: bool) -> void:
	_ctx.busy = busy
	_pause.available = not busy and not _autoplay
	if _debug:
		_debug.available = not busy


## Updates the map's status window, the quests' marks and sought figures and the hero's
## weapon and shield; on autoplay also prints each new quest line and each change of gold
## or equipment.
## Every STEP_DISTANCE metres walked: two steps for the credits, and the Incienso burns.
func _on_stepped() -> void:
	state.steps += 2
	if state.repel_m <= 0.0:
		return
	state.repel_m = maxf(0.0, state.repel_m - World.STEP_DISTANCE)
	if state.repel_m == 0.0:
		_ctx.world.set_repel(false)
		_ctx.world.show_notice(REPEL_END_NOTICE)


func _refresh_status() -> void:
	state.sync_level_cap()
	var missions := state.current_missions()
	_ctx.world.refresh_status(state.hero, _ctx.potion_count(), state.gold,
		missions)
	_ctx.world.set_monsters_shy(EncounterMeter.is_shy(state.hero.level, _ctx.zone.exit_level))
	_ctx.world.set_repel(state.repel_m > 0.0)
	_ctx.world.set_autoplay_hunt(_autoplay and _autoplay_hunts())
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
	if _autoplay and missions != _last_missions:
		print(" · ".join(missions))
	_last_missions = missions
	var worn := PackedStringArray()
	for slot in Equipment.SLOTS:
		if loadout.worn(slot) != "":
			worn.append(Equipment.display_name(loadout.worn(slot)))
	var gear_text := "Oro %d G · Equipo: %s · ATK %d DEF %d VEL %d" % [state.gold,
		", ".join(worn), state.hero.total_attack(), state.hero.total_defense(),
		state.hero.total_speed()]
	if _autoplay and gear_text != _last_gear_text:
		print(gear_text)
	_last_gear_text = gear_text


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
	_pause.available = not _autoplay


## --debug: the panel over the pause menu, under the fade. While it is open Game is busy (no
## ☰, no pause) and the status window and map square hide, as with the pause menu.
func _build_debug() -> void:
	var layer := CanvasLayer.new()
	layer.layer = UiTokens.LAYER_DEBUG
	add_child(layer)
	_debug = DebugPanel.new()
	_debug.setup(state)
	layer.add_child(_debug)
	_debug.action_chosen.connect(_on_debug)
	_debug.open_changed.connect(func(is_open: bool) -> void:
		_set_busy(is_open)
		_ctx.world.set_status_shown(not is_open))


## What a DebugPanel button asks: done at once on the state and the map, printed as
## "Depuración: ..." and said on the panel. Ir a goes on under black (_debug_go()).
func _on_debug(action: String, arg: String) -> void:
	var text := ""
	match action:
		DebugPanel.ZONE:
			_debug_go(arg)
			return
		DebugPanel.LEVEL:
			Leveling.set_level(state.hero, state.hero.level + int(arg), HERO_DATA.skills)
			var spells := PackedStringArray()
			for skill in state.hero.skills:
				spells.append(skill.display_name)
			text = "nivel %d (PV %d/%d, PM %d/%d, EXP %d; hechizos: %s)" % [state.hero.level,
				state.hero.hp, state.hero.max_hp, state.hero.mp, state.hero.max_mp,
				state.hero.experience, ", ".join(spells)]
		DebugPanel.GOLD:
			state.gold += int(arg)
			text = "+%s G (%d G)" % [arg, state.gold]
		DebugPanel.ITEMS:
			for id in Inventory.IDS:
				state.inventory.add(id)
			text = "+1 de cada objeto (%d objetos)" % Inventory.IDS.size()
		DebugPanel.HEAL:
			state.heal_full()
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
			var item := state.on_boss_defeated(boss)
			if arg == Quest.BOSS_ID:
				state.quest.stage = Quest.Stage.DONE  # as its real victory does
			if Bestiary.has(arg):
				# As --autoplay-zone does: beaten in the bestiary too, and a family may be complete.
				state.see_enemy(arg)
				state.defeat_enemy(arg)
			state.story.mark_seen_for_flags(state.world_flags)
			_ctx.world.set_world_flags(state.world_flags)
			text = "%s %s" % [boss.display_name, "vencida" if boss.female else "vencido"]
			if item != "":
				text += " (+%s)" % Inventory.KEY_ITEMS[item]
			for line in BattleRewards.family_rewards(state):
				text += " · " + line
		DebugPanel.QUEST:
			state.quest.skip_stage()
			text = "misión de la aldea: %s" % DebugPanel.STAGE_NAMES[state.quest.stage]
		DebugPanel.SAVE:
			var data := SaveData.from_state(state, _ctx.world.player_position(), _ctx.play_time)
			text = "guardado en la ranura %d" % _slot if SaveStore.save_game(_slot, data) \
				else "no se pudo guardar"
	_update_boss()
	_refresh_status()
	print("Depuración: %s" % text)
	_debug.show_result(text)


## DebugPanel's Ir a (the panel is already shut): under black to zone_id's start entry, as
## through an exit, with no autosave.
func _debug_go(zone_id: String) -> void:
	if _ctx.busy:
		return
	_set_busy(true)
	_ctx.world.freeze(true)
	await _fade_to(1.0)
	_travel.switch_zone(zone_id, "")
	_play_map_music()
	await _fade_to(0.0)
	await _ctx.world.freeze(false)
	print("Depuración: a %s" % _ctx.zone.map_label())
	_set_busy(false)
	_story.check_village_scene()


func _fade_to(alpha: float) -> void:
	var t := create_tween()
	t.tween_property(_fade, "color:a", alpha, FADE_TIME)
	await t.finished
