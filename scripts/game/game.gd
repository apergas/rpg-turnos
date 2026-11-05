class_name Game extends Node
## One play session, created by TitleScreen (setup() before add_child). Owns the
## GameState and the map of the current zone (a World built from its ZoneData), and puts
## a battle on top of the map when an encounter starts (the enemies come from
## EncounterTable with the zone's formations, or the zone's boss). The map stays while
## battles come and go, so the hero's position, the camera and the encounter grace
## survive them; walking into an open exit fades to black, frees the map and builds the
## next zone at the exit's entry (GameState.zone_id). A victory adds the gold and counts
## every enemy defeated for the quest; a boss also sets its world flag (the Rey Slime
## lifts the fog of the meadow's north exit) and gives its key item. Fleeing just goes
## back to the map; a defeat takes half the gold (GameState.defeat_gold_loss()), heals the
## hero and sends them to the last village visited (GameState.town_zone), EXP kept, like
## the Ala de viaje used from the pause menu, which also leaves a portal in that village
## that leads back once (GameState.open_portal(); a second Ala replaces it, a defeat leaves
## it open). Talking to the old woman heals, moves the
## quest on and, once the slimes are reported, brings out the Rey Slime; the other
## villagers say their ZoneData lines. The merchant opens the ShopWindow; the innkeeper
## offers a free night (Inn.stay(): fade to black, full HP and MP, autosave); a chest gives
## what it holds (Chests.open()) and stays open. The hero's figure on the map and in
## battle shows the weapon and shield worn. On a dungeon floor the lever sets its world
## flag (and opens the gates it works), the key goes to the key items (and its flag is
## set, so it stays taken) and a locked gate opens with the key, which is used up; all
## three autosave silently. Picks the zone's music (map, village, battle,
## boss), autosaves after talking, after every won battle, after shopping, (silently)
## after opening a chest, after a defeat and after every change of zone, and opens the
## pause menu. Emits quit_to_title when the player goes back to the title.
## The story (GameState.story): a new game opens with the prologue in the hero's house
## (data/cutscenes/prologo.tres, which starts the slimes quest); each boss beaten plays
## its cutscene (StoryState.AFTER_BOSS) and the first visit to each village its own
## (StoryState.ON_VILLAGE), through the CutscenePlayer; the villagers' lines follow the
## chapter. Beating the Señor de la Niebla (GameState.FINAL_BOSS) plays the ending (back
## to Villaclaro), marks the save as finished (story.finished) and rolls the credits with
## the numbers of the game (CreditsScreen); then it goes back to the title. A finished
## save loads in Villaclaro and the world can still be walked.
## On autoplay it prints the gold and the equipment each time they change, the level and
## the play time on every change of zone and, after the credits, the play time of the
## whole run (TitleScreen then quits). After a won battle, when the hero needs rest
## (GameState.needs_rest()) away from a village, it flies back with an Ala de viaje, sleeps
## at the inn, restocks at the shop and goes back through the portal; after a defeat it
## sleeps and restocks too.
## Run on its own (res://scenes/game/game.tscn) it starts a new game with its own
## AudioDirector and default options.
##
## `-- --autoplay --autoplay-save`: after the first autosave that follows a won battle
## it prints the saved values ("Guardado: ...") and goes back to the title, which loads
## the save at once; the loaded game prints the same values ("Cargado: ...").
## `-- --autoplay --autoplay-menu`: MENU_TOUR_DELAY seconds into the map (still inside
## the encounter grace) it shows every page of the pause menu (PauseMenu.tour()), to
## record frames of it.
## `-- --autoplay --autoplay-zone=<id>`: a new game that starts in that zone with the
## level, gold, gear and progress AUTOPLAY_ZONES gives it.

signal quit_to_title

const HERO_DATA := preload("res://data/hero.tres")
const BATTLE_SCENE := preload("res://scenes/battle/battle_scene.tscn")
const WORLD_SCENE := preload("res://scenes/world/world.tscn")
const CUTSCENE_PATH := "res://data/cutscenes/%s.tres"
## The author shown in the credits.
const AUTHOR := "apergas"
const FADE_TIME := 0.3
const HEAL_LINE := "Descansas un momento. PV y PM recuperados."
const SAVED_NOTICE := "Partida guardada."
const LOAD_FAILED_NOTICE := "No se pudo cargar la partida. Empiezas de nuevo."
## Notice after beating a boss (by id); other bosses announce their key item.
const BOSS_NOTICES := {
	"rey_slime": "¡Villaclaro está a salvo! La niebla del norte se disipa...",
	"senor_niebla": "¡Consigues el último Fragmento del amuleto! La niebla se levanta.",
}
const KEY_ITEM_NOTICE := "¡Consigues un %s!"
const LEVER_NOTICE := "¡Tiras de la palanca! Se oye cómo se abre una reja."
const KEY_NOTICE := "¡Encuentras la %s!"
const DOOR_NOTICE := "Abres la puerta con la %s."
const PORTAL_OPEN_NOTICE := "Vuelas %s. El portal te espera para volver."
const PORTAL_REPLACED_NOTICE := "Vuelas %s. El portal anterior se ha cerrado."
const PORTAL_BACK_NOTICE := "El portal te devuelve y se cierra tras de ti."
const MENU_TOUR_DELAY := 1.0
## Seconds of black while the hero sleeps at the inn.
const INN_NIGHT_TIME := 0.8
## On autoplay the hero only stops at an inn below this share of max HP or MP.
const AUTOPLAY_INN_RATIO := 0.5
## On autoplay the boss only comes out while the hero has these shares of max HP and MP.
const AUTOPLAY_BOSS_HP := 0.7
const AUTOPLAY_BOSS_MP := 0.4
## --autoplay-zone=<id>: what a new game starting in each zone gets, as planned when
## arriving there (zone 1 done: Lv 5, its shop's gear, the Rey Slime beaten).
const AUTOPLAY_ZONES := {
	"bosque": {
		"experience": 136,
		"gold": 150,
		"gear": [Equipment.COPPER_SWORD, Equipment.LEATHER_MAIL, Equipment.WOODEN_SHIELD],
		"flags": ["rey_slime"],
		"quest_done": true,
	},
	# Zone 2 done: Lv 9 with the Bruja's EXP, the forest gear and the first fragment.
	"mina_1": {
		"experience": 541,
		"gold": 250,
		"gear": ["espada_hierro", "cota_malla", "escudo_hierro"],
		"flags": ["rey_slime", "bruja"],
		"key_items": ["fragmento_bosque"],
		"quest_done": true,
	},
	# Ready for the Golem: Lv 13, the mine's gear, the gates of floors 2 and 3 open.
	"mina_3": {
		"experience": 1073,
		"gold": 100,
		"gear": ["espada_acero", "armadura_acero", "escudo_acero"],
		"flags": ["rey_slime", "bruja", "mina_palanca", "llave_mina", "mina_puerta"],
		"key_items": ["fragmento_bosque"],
		"quest_done": true,
		"town": "mina_1",
	},
	# Zone 3 done: Lv 13 with the Golem's EXP and gold, the mine's gear and two fragments.
	"castillo_patio": {
		"experience": 1373,
		"gold": 600,
		"gear": ["espada_acero", "armadura_acero", "escudo_acero"],
		"flags": ["rey_slime", "bruja", "mina_palanca", "llave_mina", "mina_puerta",
			"golem_piedra"],
		"key_items": ["fragmento_bosque", "fragmento_mina"],
		"quest_done": true,
		"town": "mina_1",
	},
	# Ready for the Señor de la Niebla: Lv 17 with the castle's gear.
	"castillo_trono": {
		"experience": 2244,
		"gold": 300,
		"gear": ["espada_platino", "armadura_platino", "escudo_platino"],
		"flags": ["rey_slime", "bruja", "mina_palanca", "llave_mina", "mina_puerta",
			"golem_piedra"],
		"key_items": ["fragmento_bosque", "fragmento_mina"],
		"quest_done": true,
		"town": "castillo_patio",
	},
}

var state: GameState
## Seconds played, saved with the game; stops while paused.
var play_time := 0.0

var _world: World
var _zone: ZoneData
var _fade: ColorRect
var _pause: PauseMenu
var _audio: AudioDirector
var _options: GameOptions
var _save := {}
## The name typed on the NameEntry for a new game ("" for the default).
var _hero_name := ""
var _cutscenes: CutscenePlayer
var _busy := false
var _leaving := false
var _autoplay := false
var _autoplay_save := false
var _autoplay_menu := false
var _last_missions: Array[String] = []
var _last_gear_text := ""
var _shop: ShopWindow
## Something was bought, sold or equipped since the shop opened.
var _shop_changed := false
var _rng := RandomNumberGenerator.new()


## audio and options come from the title screen; save is the Dictionary read by
## SaveStore.load_game(), empty for a new game, which gets hero_name.
func setup(audio: AudioDirector, options: GameOptions, save: Dictionary,
		hero_name := "") -> void:
	_audio = audio
	_options = options
	_save = save
	_hero_name = hero_name


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_autoplay = args.has("--autoplay")
	_autoplay_save = _autoplay and args.has("--autoplay-save")
	_autoplay_menu = _autoplay and args.has("--autoplay-menu")
	_rng.randomize()
	if _options == null:
		_options = GameOptions.new()
	if _audio == null:
		_audio = AudioDirector.new()
		add_child(_audio)
		_audio.set_volumes(_options.music_volume, _options.sfx_volume)
	state = GameState.new(HERO_DATA)
	var load_failed := false
	var start_pos: Variant = null
	if not _save.is_empty():
		var info := SaveData.apply(state, _save)
		if info.valid:
			start_pos = info.position
			play_time = info.play_time
			if _autoplay_save:
				print("Cargado: %s" % _summary(SaveData.from_state(state, info.position,
					info.play_time)))
		else:
			load_failed = true
	if _save.is_empty() or load_failed:
		state.hero.display_name = StoryState.clean_name(_hero_name)
	if _save.is_empty() and _autoplay:
		_apply_autoplay_zone(args)
	_build_shop()
	_build_fade()
	_build_pause()
	_build_cutscenes()
	if _autoplay_menu:
		# The tour of the pause menu needs the map, not a scene.
		state.story.mark_seen("prologo")
	# Busy until the map is ready (no ☰ either): arriving inside a village must not start its
	# cutscene yet.
	_set_busy(true)
	_switch_zone(state.zone_id, "")
	if start_pos != null:
		_world.place_player(start_pos)
	var prologue := state.chapter() == StoryState.Chapter.PROLOGUE
	if prologue:
		# Under black: the prologue fades in by itself.
		_fade.color.a = 1.0
		_play_prologue.call_deferred()
	# Synthesize the tracks played later now, under black, so no first play stalls.
	for id in [MusicLibrary.VILLAGE, MusicLibrary.VICTORY, MusicLibrary.DEFEAT]:
		MusicLibrary.build(id)
	_play_map_music()
	if _autoplay_menu:
		get_tree().create_timer(MENU_TOUR_DELAY).timeout.connect(_pause.tour)
	if not prologue:
		await _world.freeze(false)
		_set_busy(false)
		_check_village_scene()


func _process(delta: float) -> void:
	play_time += delta


## --autoplay-zone=<id>: starts the new game in that zone with AUTOPLAY_ZONES' state.
func _apply_autoplay_zone(args: PackedStringArray) -> void:
	for arg in args:
		if not arg.begins_with("--autoplay-zone="):
			continue
		var zone_id := arg.trim_prefix("--autoplay-zone=")
		if not zone_id in ZoneData.IDS:
			push_error("Unknown zone for --autoplay-zone: %s" % zone_id)
			return
		state.zone_id = zone_id
		var start: Dictionary = AUTOPLAY_ZONES.get(zone_id, {})
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
		for id: String in start.get("key_items", []):
			state.key_items.append(id)
		state.town_zone = start.get("town", state.town_zone)
		if start.quest_done:
			state.quest.stage = Quest.Stage.DONE
		state.story.mark_seen_for_flags(state.world_flags)
		print("Zona de inicio: %s (Nv %d)" % [zone_id, state.hero.level])


## Frees the current map and builds zone_id with the player at entry_id ("" for the
## zone's start entry). No fade: callers fade around it. The new map starts frozen
## (World.freeze()), so nothing on it can fire while Game is still busy fading in;
## every caller unfreezes it once the fade is over.
func _switch_zone(zone_id: String, entry_id: String) -> void:
	if _world:
		remove_child(_world)
		_world.queue_free()
	_zone = ZoneData.by_id(zone_id)
	state.zone_id = zone_id
	_world = WORLD_SCENE.instantiate()
	_world.zone = _zone
	add_child(_world)
	move_child(_world, 0)
	_world.freeze(true)
	_world.set_audio(_audio)
	_world.encounter_triggered.connect(_on_encounter)
	_world.talk_requested.connect(_on_talk)
	_world.npc_requested.connect(_on_npc)
	_world.shop_requested.connect(_on_shop)
	_world.inn_requested.connect(_on_inn)
	_world.chest_opened.connect(_on_chest)
	_world.exit_requested.connect(_on_exit)
	_world.portal_used.connect(_on_portal)
	_world.lever_pulled.connect(_on_lever)
	_world.key_taken.connect(_on_key)
	_world.door_used.connect(_on_door)
	_world.village_changed.connect(_on_village_changed)
	_world.stepped.connect(func() -> void: state.steps += 2)
	if entry_id != "":
		_world.place_at_entry(entry_id)
	for id in state.opened_chests:
		_world.set_chest_open(id, true, true)
	_world.set_explored(state.explored_map(zone_id))
	_world.set_world_flags(state.world_flags)
	_show_portal()
	_update_boss()
	_refresh_status()
	MusicLibrary.build(_zone.music)
	if _world.in_village():
		_on_village_changed(true)
	if _autoplay:
		print("Zona: %s (Nv %d, %s)" % [zone_id, state.hero.level, _clock(play_time)])


func _on_encounter(boss: bool) -> void:
	if _busy:
		return
	_set_busy(true)
	state.battles += 1
	var enemies: Array[Combatant] = []
	if boss:
		enemies.append(EnemyLibrary.data(_zone.boss_id))
	else:
		enemies = EncounterTable.pick(_zone, _world.player_position(), _rng)
	await _fade_to(1.0)
	_world.set_active(false)
	_audio.play_music(MusicLibrary.BOSS if boss else MusicLibrary.BATTLE)
	var battle: BattleScene = BATTLE_SCENE.instantiate()
	battle.setup(state.hero, enemies, state.inventory)
	battle.set_audio(_audio)
	battle.set_equipment(state.loadout.worn(Equipment.WEAPON),
		state.loadout.worn(Equipment.SHIELD))
	battle.gold_lost = state.defeat_gold_loss()
	battle.char_time = _options.char_time()
	battle.zone = _zone
	add_child(battle)
	await _fade_to(0.0)
	var outcome: int = await battle.finished
	var won := outcome == BattleEngine.State.WON
	await _fade_to(1.0)
	var notice := ""
	var scene := ""
	var mission_done := false
	if won:
		state.gold += battle.engine.gold_won
		state.gold_earned += battle.engine.gold_won
		var quest_was_on := state.quest.stage != Quest.Stage.DONE
		for enemy in battle.engine.enemies:
			state.quest.on_victory(enemy.id)
			if enemy.is_boss:
				notice = _boss_notice(enemy)
				scene = state.story.scene_after_boss(enemy.id)
		mission_done = quest_was_on and state.quest.stage == Quest.Stage.DONE
	elif outcome == BattleEngine.State.LOST:
		state.gold -= battle.gold_lost
		state.heal_full()
		_go_to_town()
		notice = "Has vuelto %s." % _to_place(_zone.village_name)
	battle.queue_free()
	_world.set_world_flags(state.world_flags)
	_update_boss()
	_refresh_status()
	_world.set_active(true)
	# Frozen until the fade is over: an exit or an encounter while Game is busy would be
	# ignored and leave the map waiting forever.
	_world.freeze(true)
	_play_map_music()
	if scene != "":
		# Under black: no status window or map square while the map fades in.
		_world.begin_cutscene()
	await _fade_to(0.0)
	if scene != "":
		# The boss's cutscene says what the notice would (the fragment, the open road).
		await _play_scene(scene)
	else:
		await _world.freeze(false)
		if notice != "":
			_world.show_notice(notice)
	if mission_done:
		_world.show_mission_done(Quest.DONE_TEXT)
	if won and state.is_finished() and not state.story.finished:
		await _finish_game()
		return
	if outcome == BattleEngine.State.LOST:
		_autosave(false)  # the gold lost sticks: going back to the title can't undo it
	if won:
		var data := _autosave(not boss)
		if _autoplay_save and _save.is_empty() and not data.is_empty():
			print("Guardado: %s" % _summary(data))
			quit_to_title.emit()
			return
	_set_busy(false)
	if _autoplay and won and _wants_retreat():
		state.inventory.take(Inventory.WING)
		print("Retirada al pueblo (PV %d/%d, PM %d, pociones %d)" % [state.hero.hp,
			state.hero.max_hp, state.hero.mp, state.inventory.count(Inventory.POTION)])
		await _on_travel_requested()
		await _autoplay_restock()
		await _on_portal()
	elif _autoplay and outcome == BattleEngine.State.LOST:
		await _autoplay_restock()


## Autoplay: needs rest (GameState.needs_rest()), or is only kept from the zone's boss by
## its HP or MP, away from a village, with an Ala de viaje (the night at the inn is free).
func _wants_retreat() -> bool:
	return (state.needs_rest() or _boss_needs_rest()) and not _world.in_village() \
		and state.inventory.count(Inventory.WING) > 0


## Autoplay: the zone's boss is due at this level but the hero is too worn for it. MP
## doesn't come back by walking, so without a rest the boss would never show up.
func _boss_needs_rest() -> bool:
	return _boss_wanted() and state.hero.level >= _zone.autoplay_boss_level \
		and not _rested_for_boss()


func _rested_for_boss() -> bool:
	var hero := state.hero
	return hero.hp >= hero.max_hp * AUTOPLAY_BOSS_HP \
		and hero.mp >= hero.max_mp * AUTOPLAY_BOSS_MP


func _boss_wanted() -> bool:
	if _zone.boss_id == "":
		return false
	return state.quest.boss_available() if _zone.boss_id == Quest.BOSS_ID \
		else not state.has_flag(_zone.boss_id)


## Autoplay, in the village: a night at its inn and the shop's picks, as if the hero had
## walked up to the innkeeper and the merchant.
func _autoplay_restock() -> void:
	for npc: Dictionary in _zone.npcs:
		if npc.kind == "inn":
			await _on_inn(npc.id)
	for npc: Dictionary in _zone.npcs:
		if npc.kind == "shop":
			await _on_shop(npc.id)


## Sets the boss's world flag, gives its key item and says so.
func _boss_notice(boss: Combatant) -> String:
	var key_item := state.on_boss_defeated(boss)
	if BOSS_NOTICES.has(boss.id):
		return BOSS_NOTICES[boss.id]
	if key_item != "":
		return KEY_ITEM_NOTICE % Inventory.KEY_ITEMS[key_item]
	return ""


## Puts the player at the town entry of the last village visited, switching zones if
## needed (no fade: the caller is already under black).
func _go_to_town() -> void:
	var town := ZoneData.by_id(state.town_zone)
	if state.town_zone != state.zone_id:
		_switch_zone(state.town_zone, town.town_entry)
	else:
		_world.place_at_entry(town.town_entry)
		_on_village_changed(_world.in_village())


## An open exit: fades to black, builds the next zone at the exit's entry, autosaves.
func _on_exit(zone_id: String, entry_id: String) -> void:
	if _busy:
		return
	_set_busy(true)
	await _fade_to(1.0)
	_switch_zone(zone_id, entry_id)
	_play_map_music()
	await _fade_to(0.0)
	await _world.freeze(false)
	_autosave(false)
	_set_busy(false)
	_check_village_scene()


## The Ala de viaje, used from the pause menu (it has already taken it): to the last
## village visited, with the portal back to this spot open there. The menu only opens when
## nothing is going on, so the spot is always a settled one.
func _on_travel_requested() -> void:
	if _busy:
		state.inventory.add(Inventory.WING)
		return
	_set_busy(true)
	# The pause menu has already unpaused the tree: without this the hero could still walk
	# into an encounter or an exit during the fade and leave the map stuck waiting.
	_world.freeze(true)
	var replaced := state.open_portal(_world.player_position())
	await _fade_to(1.0)
	_go_to_town()
	_show_portal()
	_refresh_status()
	_play_map_music()
	await _fade_to(0.0)
	await _world.freeze(false)
	var place := _to_place(_zone.village_name)
	_world.show_notice((PORTAL_REPLACED_NOTICE if replaced else PORTAL_OPEN_NOTICE) % place)
	_autosave(false)
	_set_busy(false)


## The hero used the return portal (or autoplay, once restocked): back to the spot the Ala
## was used at. It works once. The map stays frozen through the fade, like every other trip.
func _on_portal() -> void:
	if _busy or not state.has_portal():
		return
	_set_busy(true)
	_world.freeze(true)
	await _fade_to(1.0)
	var zone_id := state.portal_zone
	var pos := state.portal_pos
	state.close_portal()
	if zone_id != _zone.id:
		_switch_zone(zone_id, "")
	else:
		_show_portal()
	_world.place_player(pos)
	_world.arm_blocked_point_skip()
	_on_village_changed(_world.in_village())
	_refresh_status()
	_update_boss()
	await _fade_to(0.0)
	await _world.freeze(false)
	_world.show_notice(PORTAL_BACK_NOTICE)
	_autosave(false)
	_set_busy(false)


## The portal stands in the village it was opened in and the mark on the spot it leads
## back to, whatever map is on now.
func _show_portal() -> void:
	_world.set_portal(state.portal_town == _zone.id)
	_world.set_return_mark(state.has_portal() and state.portal_zone == _zone.id,
		state.portal_pos)


## Inside a village it becomes the last one visited; the music follows. The first
## visit plays the village's cutscene.
func _on_village_changed(inside: bool) -> void:
	if inside and _zone.town_entry != "":
		state.town_zone = _zone.id
	_play_map_music()
	if inside:
		_check_village_scene()


## Plays the cutscene of this zone's village if the hero is inside it and has not seen
## it yet (only when nothing else is going on); autosaves after it.
func _check_village_scene() -> void:
	if _busy or not _world.in_village():
		return
	var scene := state.story.scene_on_village(_zone.id)
	if scene == "":
		return
	_set_busy(true)
	await _play_scene(scene)
	_autosave(false)
	_set_busy(false)


## Plays data/cutscenes/<scene_id>.tres on the current map and marks it seen. The
## caller is busy; the map is the player's again when it returns.
func _play_scene(scene_id: String) -> void:
	var scene := load(CUTSCENE_PATH % scene_id) as Cutscene
	state.story.mark_seen(scene_id)
	_cutscenes.world = _world
	_cutscenes.hero_name = state.hero.display_name
	await _cutscenes.play(scene)
	_refresh_status()


## A new game: the prologue (it fades in from black), then the slimes quest is on. A
## save that could not be read also lands here, and says so now the map is visible.
func _play_prologue() -> void:
	await _play_scene("prologo")
	state.quest.start()
	_refresh_status()
	_autosave(false)
	_set_busy(false)
	if not _save.is_empty():
		_world.show_notice(LOAD_FAILED_NOTICE)


## After the ending: the save is marked finished (the hero is back in Villaclaro), the
## credits roll with the numbers of the game and Game goes back to the title. They cover
## everything, and Game stays busy, so no status window, map square, ☰ or prompt shows.
func _finish_game() -> void:
	state.story.finished = true
	_world.freeze(true)
	_autosave(false)
	var time_text := _clock(play_time)
	_audio.play_music(MusicLibrary.TITLE)
	var layer := CanvasLayer.new()
	layer.layer = 11
	add_child(layer)
	var credits := CreditsScreen.new()
	layer.add_child(credits)
	await _fade_to(0.0)
	await credits.run(_credits_sections(time_text))
	if _autoplay:
		print("Juego completado: Nv %d, tiempo de juego %s" % [state.hero.level, time_text])
	quit_to_title.emit()


## The credits: who made the game, with what, and the numbers of this game.
func _credits_sections(time_text: String) -> Array:
	return [
		["Villaclaro", ["La historia de %s" % state.hero.display_name]],
		["Creado por", [AUTHOR]],
		["Motor", ["Godot Engine 4.7"]],
		["Modelos 3D", ["KayKit, de Kay Lousberg (CC0)"]],
		["Música y sonido", ["Música y efectos generados por el juego"]],
		["Tu partida", [
			"Tiempo de juego: %s" % time_text,
			"Combates: %d" % state.battles,
			"Pasos: %d" % state.steps,
			"Oro ganado: %d G" % state.gold_earned,
			"Misiones cumplidas: %d" % state.quests_done(),
			"Nivel: %d" % state.hero.level,
		]],
		["Gracias por jugar", []],
	]


## What CutscenePlayer's "travel" step does: builds zone_id at entry_id under black and
## hands the new map over.
func _scene_travel(zone_id: String, entry_id: String) -> World:
	_switch_zone(zone_id, entry_id)
	return _world


## What CutscenePlayer's "flag" step does.
func _scene_flag(flag: String) -> void:
	state.world_flags[flag] = true
	_world.set_world_flags(state.world_flags)


## The old woman always heals; what she says and gives comes from the quest.
func _on_talk() -> void:
	if _busy:
		return
	_set_busy(true)
	var done := state.quest.stage == Quest.Stage.DONE
	var result := state.quest.talk()
	var said: Array = result.lines
	if done:
		# Her quest over, the Abuela Rosa speaks of the story (her ZoneData lines).
		var story_lines := _world.npc_lines(_quest_npc(), state.chapter())
		if not story_lines.is_empty():
			said = story_lines
	var lines: Array[String] = []
	for line: String in said:
		lines.append(StoryState.fill(line, state.hero.display_name))
	lines.append(HEAL_LINE)
	state.heal_full()
	if result.potions > 0:
		state.inventory.add(Inventory.POTION, result.potions)
	_refresh_status()
	await _world.show_dialogue(Quest.NPC_NAME, lines)
	_update_boss()
	_autosave(true)
	_set_busy(false)


## The index of the zone's "quest" figure (the Abuela Rosa) in ZoneData.npcs.
func _quest_npc() -> int:
	for i in _zone.npcs.size():
		if _zone.npcs[i].kind == "quest":
			return i
	return -1


## A villager: says its lines (World.npc_lines(): they change with the chapter).
func _on_npc(index: int) -> void:
	if _busy:
		return
	_set_busy(true)
	var lines: Array[String] = []
	for line in _world.npc_lines(index, state.chapter()):
		lines.append(StoryState.fill(line, state.hero.display_name))
	await _world.show_dialogue(_zone.npcs[index].name, lines)
	_set_busy(false)


## The merchant: the ShopWindow until the player leaves; autosaves if anything changed.
## On autoplay it only opens when there is something to buy.
func _on_shop(shop_id: String) -> void:
	if _busy or (_autoplay and Shop.autoplay_picks(state, shop_id).is_empty()):
		return
	_set_busy(true)
	_shop_changed = false
	_world.freeze(true)
	await _shop.run(shop_id)
	await _world.freeze(false)
	_refresh_status()
	if _shop_changed:
		_autosave(true)
	_set_busy(false)


## The innkeeper: Sí fades to black and back with HP and MP full and saves (it costs
## nothing); with No, nothing happens. On autoplay it only stops there below
## AUTOPLAY_INN_RATIO of max HP or MP, on GameState.needs_rest() or below the boss's
## thresholds (or a retreat for the boss would come back unhealed).
func _on_inn(inn_id: String) -> void:
	var hurt := state.hero.hp < state.hero.max_hp * AUTOPLAY_INN_RATIO \
		or state.hero.mp < state.hero.max_mp * AUTOPLAY_INN_RATIO or state.needs_rest() \
		or not _rested_for_boss()
	if _busy or (_autoplay and not hurt):
		return
	_set_busy(true)
	_world.freeze(true)
	var lines: Array[String] = []
	var slept := false
	if await _shop.ask(Inn.keeper(inn_id), Inn.OFFER):
		slept = true
		lines.append(Inn.stay(state))
		await _fade_to(1.0)
		_refresh_status()
		_audio.play_sfx(SfxLibrary.HEAL)
		await get_tree().create_timer(INN_NIGHT_TIME).timeout
		await _fade_to(0.0)
	else:
		lines.append("Vuelve cuando quieras.")
	await _world.freeze(false)
	await _world.show_dialogue(Inn.keeper(inn_id), lines)
	_refresh_status()
	if slept:
		_update_boss()
		_autosave(true)
	_set_busy(false)


## A closed chest: gives what it holds, opens the lid and saves without a notice (the
## notice shows what was found).
func _on_chest(chest_id: String) -> void:
	if _busy:
		return
	var result := Chests.open(state, chest_id)
	if not result.opened:
		return
	state.gold_earned += Chests.CHESTS[chest_id].get("gold", 0)
	_world.set_chest_open(chest_id, true)
	_audio.play_sfx(SfxLibrary.LEVEL_UP)
	_refresh_status()
	_world.show_notice(result.text)
	_autosave(false)


## The dungeon floor's lever: sets its flag, which opens the gates it works.
func _on_lever() -> void:
	if _busy or _zone.lever_flag == "":
		return
	state.world_flags[_zone.lever_flag] = true
	_world.pull_lever()
	_audio.play_sfx(SfxLibrary.DOOR)
	_world.set_world_flags(state.world_flags)
	_world.show_notice(LEVER_NOTICE)
	_autosave(false)


## The key lying on the floor: into the key items; its flag keeps it taken.
func _on_key() -> void:
	if _busy or _zone.floor_key == "":
		return
	state.world_flags[_zone.floor_key] = true
	state.key_items.append(_zone.floor_key)
	_audio.play_sfx(SfxLibrary.LEVEL_UP)
	_world.set_world_flags(state.world_flags)
	_world.show_notice(KEY_NOTICE % Inventory.KEY_ITEMS[_zone.floor_key])
	_autosave(false)


## A closed gate: the key of the floor opens it (and is used up); otherwise its text.
func _on_door() -> void:
	if _busy:
		return
	var key := _zone.door_key
	if key == "" or not key in state.key_items:
		_world.show_notice(_zone.door_text)
		return
	state.key_items.erase(key)
	state.world_flags[_zone.door_flag] = true
	_audio.play_sfx(SfxLibrary.DOOR)
	_world.set_world_flags(state.world_flags)
	_world.show_notice(DOOR_NOTICE % Inventory.KEY_ITEMS[key])
	_autosave(false)


## Writes the save file; shows SAVED_NOTICE if notice. Returns the saved data, or an
## empty Dictionary if the file could not be written.
func _autosave(notice: bool) -> Dictionary:
	var data := SaveData.from_state(state, _world.player_position(), play_time)
	if not SaveStore.save_game(data):
		return {}
	if notice:
		_audio.play_sfx(SfxLibrary.SAVE)
		_world.show_notice(SAVED_NOTICE)
	return data


func _on_save_requested() -> void:
	var data := SaveData.from_state(state, _world.player_position(), play_time)
	_pause.show_save_result(SaveStore.save_game(data))


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
	if _zone.boss_id == "":
		return
	var strong_enough := not _autoplay or (state.hero.level >= _zone.autoplay_boss_level \
		and _rested_for_boss())
	_world.set_boss_present(_boss_wanted() and strong_enough)


## The zone's map music, or its village one inside the village.
func _play_map_music() -> void:
	_audio.play_music(_zone.village_music if _world.in_village() else _zone.music)


## The pause menu only opens on the map with nothing else going on.
func _set_busy(busy: bool) -> void:
	_busy = busy
	_pause.available = not busy and not _autoplay


## Updates the map's status window and the hero's weapon and shield; on autoplay also
## prints each new quest line and each change of gold or equipment.
func _refresh_status() -> void:
	var missions := state.current_missions()
	_world.refresh_status(state.hero, state.inventory.count(Inventory.POTION), state.gold,
		missions)
	var loadout := state.loadout
	_world.set_hero_equipment(loadout.worn(Equipment.WEAPON), loadout.worn(Equipment.SHIELD))
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


## "a Villaclaro", "a la aldea del bosque", "al refugio de la mina".
static func _to_place(place: String) -> String:
	return "al " + place.substr(3) if place.begins_with("el ") else "a " + place


## Seconds as "h:mm:ss".
static func _clock(seconds: float) -> String:
	return "%d:%02d:%02d" % [floori(seconds / 3600.0), floori(seconds / 60.0) % 60,
		floori(seconds) % 60]


## One line with every saved value, keys sorted, for --autoplay-save.
static func _summary(data: Dictionary) -> String:
	return JSON.stringify(data, "", true)


func _build_shop() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 4
	add_child(layer)
	_shop = ShopWindow.new()
	_shop.setup(state, _audio)
	layer.add_child(_shop)
	_shop.changed.connect(func() -> void:
		_shop_changed = true
		_refresh_status())


func _build_cutscenes() -> void:
	_cutscenes = CutscenePlayer.new()
	_cutscenes.audio = _audio
	_cutscenes.fade = _fade_to
	_cutscenes.set_flag = _scene_flag
	_cutscenes.travel = _scene_travel
	add_child(_cutscenes)


func _build_fade() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade)


func _build_pause() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	_pause = PauseMenu.new()
	_pause.setup(state, _options, _audio)
	layer.add_child(_pause)
	_pause.save_requested.connect(_on_save_requested)
	_pause.title_requested.connect(_on_title_requested)
	_pause.travel_requested.connect(_on_travel_requested)
	_pause.in_village = func() -> bool: return _world.in_village()
	_pause.state_changed.connect(_refresh_status)
	_pause.available = not _autoplay


func _fade_to(alpha: float) -> void:
	var t := create_tween()
	t.tween_property(_fade, "color:a", alpha, FADE_TIME)
	await t.finished
