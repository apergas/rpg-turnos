class_name Game extends Node
## One play session, created by TitleScreen (setup() before add_child). Owns the
## GameState and the world map, and puts a battle on top of the map when an encounter
## starts (the enemies come from EncounterTable, or the Rey Slime). The map is never
## freed, so the hero's position, the camera and the encounter grace survive the battle.
## A victory adds the gold and counts every enemy defeated for the quest; fleeing just
## goes back to the map; a defeat takes half the gold (GameState.defeat_gold_loss()),
## heals the hero and sends them back to the spawn point, EXP kept. Talking to the old
## woman heals, moves the quest on and, once the slimes are reported, brings out the Rey
## Slime. A chest gives what it holds (Chests.open()) and stays open. The hero's figure
## on the map and in battle shows the weapon and shield worn. Picks the music (map,
## village, battle, boss), autosaves after talking, after every won battle and
## (silently) after opening a chest, and opens the pause menu. Emits quit_to_title when
## the player goes back to the title.
## On autoplay it prints the gold and the equipment each time they change.
## Run on its own (res://scenes/game/game.tscn) it starts a new game with its own
## AudioDirector and default options.
##
## `-- --autoplay --autoplay-save`: after the first autosave that follows a won battle
## it prints the saved values ("Guardado: ...") and goes back to the title, which loads
## the save at once; the loaded game prints the same values ("Cargado: ...").
## `-- --autoplay --autoplay-menu`: MENU_TOUR_DELAY seconds into the map (still inside
## the encounter grace) it shows every page of the pause menu (PauseMenu.tour()), to
## record frames of it.

signal quit_to_title

const HERO_DATA := preload("res://data/hero.tres")
const BOSS_DATA := preload("res://data/rey_slime.tres")
## The map is zone 1 of EncounterTable (the meadow).
const ZONE := 1
const BATTLE_SCENE := preload("res://scenes/battle/battle_scene.tscn")
const WORLD_SCENE := preload("res://scenes/world/world.tscn")
const FADE_TIME := 0.3
const HEAL_LINE := "Descansas un momento. PV y PM recuperados."
const SAFE_NOTICE := "¡Villaclaro está a salvo!"
const SAVED_NOTICE := "Partida guardada."
const LOAD_FAILED_NOTICE := "No se pudo cargar la partida. Empiezas de nuevo."
const MENU_TOUR_DELAY := 1.0
## On autoplay the Rey Slime only comes out from this level on, so the run first fights
## around the meadow (at lower levels it would lose to the boss over and over).
const AUTOPLAY_BOSS_LEVEL := 5

var state: GameState
## Seconds played, saved with the game; stops while paused.
var play_time := 0.0

var _world: World
var _fade: ColorRect
var _pause: PauseMenu
var _audio: AudioDirector
var _options: GameOptions
var _save := {}
var _busy := false
var _leaving := false
var _autoplay := false
var _autoplay_save := false
var _autoplay_menu := false
var _last_quest_text := ""
var _last_gear_text := ""
var _rng := RandomNumberGenerator.new()


## audio and options come from the title screen; save is the Dictionary read by
## SaveStore.load_game(), empty for a new game.
func setup(audio: AudioDirector, options: GameOptions, save: Dictionary) -> void:
	_audio = audio
	_options = options
	_save = save


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
	_world = WORLD_SCENE.instantiate()
	add_child(_world)
	_world.set_audio(_audio)
	_world.encounter_triggered.connect(_on_encounter)
	_world.talk_requested.connect(_on_talk)
	_world.chest_opened.connect(_on_chest)
	_world.village_changed.connect(func(_inside: bool) -> void: _play_map_music())
	var load_failed := false
	if not _save.is_empty():
		var info := SaveData.apply(state, _save)
		if info.valid:
			_world.place_player(info.position)
			play_time = info.play_time
			if _autoplay_save:
				print("Cargado: %s" % _summary(SaveData.from_state(state, info.position,
					info.play_time)))
		else:
			load_failed = true
	for id in state.opened_chests:
		_world.set_chest_open(id, true, true)
	_update_boss()
	_refresh_status()
	_build_fade()
	_build_pause()
	# Synthesize the tracks played later now, under black, so no first play stalls.
	for id in [MusicLibrary.VILLAGE, MusicLibrary.VICTORY, MusicLibrary.DEFEAT]:
		MusicLibrary.build(id)
	_play_map_music()
	if load_failed:
		if _autoplay:
			print(LOAD_FAILED_NOTICE)
		_world.show_notice(LOAD_FAILED_NOTICE)
	if _autoplay_menu:
		get_tree().create_timer(MENU_TOUR_DELAY).timeout.connect(_pause.tour)


func _process(delta: float) -> void:
	play_time += delta


func _on_encounter(boss: bool) -> void:
	if _busy:
		return
	_set_busy(true)
	var enemies: Array[Combatant] = [BOSS_DATA]
	if not boss:
		enemies = EncounterTable.pick(ZONE, _world.player_position(), _rng)
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
	add_child(battle)
	await _fade_to(0.0)
	var outcome: int = await battle.finished
	var won := outcome == BattleEngine.State.WON
	await _fade_to(1.0)
	if won:
		state.gold += battle.engine.gold_won
		for enemy in battle.engine.enemies:
			state.quest.on_victory(enemy.id)
	elif outcome == BattleEngine.State.LOST:
		state.gold -= battle.gold_lost
		state.heal_full()
		_world.respawn()
	battle.queue_free()
	_update_boss()
	_refresh_status()
	_world.set_active(true)
	_play_map_music()
	await _fade_to(0.0)
	if outcome == BattleEngine.State.LOST:
		_world.show_notice("Has vuelto al inicio.")
	elif boss:
		_world.show_notice(SAFE_NOTICE)
	if won:
		var data := _autosave(not boss)
		if _autoplay_save and _save.is_empty() and not data.is_empty():
			print("Guardado: %s" % _summary(data))
			quit_to_title.emit()
			return
	_set_busy(false)


## The old woman always heals; what she says and gives comes from the quest.
func _on_talk() -> void:
	if _busy:
		return
	_set_busy(true)
	var result := state.quest.talk()
	var lines: Array[String] = []
	lines.append_array(result.lines)
	lines.append(HEAL_LINE)
	state.heal_full()
	if result.potions > 0:
		state.inventory.add(Inventory.POTION, result.potions)
	_refresh_status()
	await _world.show_dialogue(Quest.NPC_NAME, lines)
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
	_world.set_chest_open(chest_id, true)
	_audio.play_sfx(SfxLibrary.LEVEL_UP)
	if _autoplay:
		print(result.text)
	_refresh_status()
	_world.show_notice(result.text)
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


## The Rey Slime is on the map while the quest asks for it (on autoplay, only from
## AUTOPLAY_BOSS_LEVEL on).
func _update_boss() -> void:
	var strong_enough := not _autoplay or state.hero.level >= AUTOPLAY_BOSS_LEVEL
	_world.set_boss_present(state.quest.boss_available() and strong_enough)


## Map music, or the village one inside the clearing.
func _play_map_music() -> void:
	_audio.play_music(MusicLibrary.VILLAGE if _world.in_village() else MusicLibrary.MAP)


## The pause menu only opens on the map with nothing else going on.
func _set_busy(busy: bool) -> void:
	_busy = busy
	_pause.available = not busy and not _autoplay


## Updates the map's status window and the hero's weapon and shield; on autoplay also
## prints each new quest line and each change of gold or equipment.
func _refresh_status() -> void:
	var quest_text := state.quest.status_text()
	_world.refresh_status(state.hero, state.inventory.count(Inventory.POTION), state.gold,
		quest_text)
	var loadout := state.loadout
	_world.set_hero_equipment(loadout.worn(Equipment.WEAPON), loadout.worn(Equipment.SHIELD))
	if _autoplay and quest_text != _last_quest_text:
		print(quest_text)
	_last_quest_text = quest_text
	var worn := PackedStringArray()
	for slot in Equipment.SLOTS:
		if loadout.worn(slot) != "":
			worn.append(Equipment.display_name(loadout.worn(slot)))
	var gear_text := "Oro %d G · Equipo: %s · ATK %d DEF %d" % [state.gold, ", ".join(worn),
		state.hero.total_attack(), state.hero.total_defense()]
	if _autoplay and gear_text != _last_gear_text:
		print(gear_text)
	_last_gear_text = gear_text


## One line with every saved value, keys sorted, for --autoplay-save.
static func _summary(data: Dictionary) -> String:
	return JSON.stringify(data, "", true)


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
	_pause.state_changed.connect(_refresh_status)
	_pause.available = not _autoplay


func _fade_to(alpha: float) -> void:
	var t := create_tween()
	t.tween_property(_fade, "color:a", alpha, FADE_TIME)
	await t.finished
