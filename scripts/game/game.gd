extends Node
## Root scene. Owns the GameState and the world map, and puts a battle on top of the
## map when an encounter starts. The map is never freed, so the hero's position, the
## camera and the encounter grace survive the battle. A defeat heals the hero and
## sends them back to the spawn point; EXP is kept. Talking to the old woman heals,
## moves the quest on and, once the slimes are reported, brings out the Rey Slime.
## Owns an AudioDirector and picks the music: map, village (inside the clearing),
## battle and boss; the battle itself plays the victory and defeat music.

const HERO_DATA := preload("res://data/hero.tres")
const SLIME_DATA := preload("res://data/slime.tres")
const BOSS_DATA := preload("res://data/rey_slime.tres")
const BATTLE_SCENE := preload("res://scenes/battle/battle_scene.tscn")
const WORLD_SCENE := preload("res://scenes/world/world.tscn")
const FADE_TIME := 0.3
const HEAL_LINE := "Descansas un momento. PV y PM recuperados."
const SAFE_NOTICE := "¡Villaclaro está a salvo!"

var state: GameState

var _world: World
var _fade: ColorRect
var _audio: AudioDirector
var _options: GameOptions
var _busy := false
var _autoplay := false
var _last_quest_text := ""


func _ready() -> void:
	_autoplay = OS.get_cmdline_user_args().has("--autoplay")
	_options = GameOptions.new()
	_audio = AudioDirector.new()
	add_child(_audio)
	_audio.set_volumes(_options.music_volume, _options.sfx_volume)
	state = GameState.new(HERO_DATA)
	_world = WORLD_SCENE.instantiate()
	add_child(_world)
	_world.set_audio(_audio)
	_refresh_status()
	_world.encounter_triggered.connect(_on_encounter)
	_world.talk_requested.connect(_on_talk)
	_world.village_changed.connect(func(_inside: bool) -> void: _play_map_music())
	_build_fade()
	_play_map_music()


func _on_encounter(boss: bool) -> void:
	if _busy:
		return
	_busy = true
	var enemy_data: Combatant = BOSS_DATA if boss else SLIME_DATA
	await _fade_to(1.0)
	_world.set_active(false)
	_audio.play_music(MusicLibrary.BOSS if boss else MusicLibrary.BATTLE)
	var battle: BattleScene = BATTLE_SCENE.instantiate()
	battle.setup(state.hero, enemy_data, state.inventory)
	battle.set_audio(_audio)
	battle.char_time = _options.char_time()
	add_child(battle)
	await _fade_to(0.0)
	var won: bool = await battle.finished
	await _fade_to(1.0)
	battle.queue_free()
	if won:
		state.quest.on_victory(enemy_data.id)
		if boss:
			_world.set_boss_present(false)
	else:
		state.heal_full()
		_world.respawn()
	_refresh_status()
	_world.set_active(true)
	_play_map_music()
	await _fade_to(0.0)
	if not won:
		_world.show_notice("Has vuelto al inicio.")
	elif boss:
		_world.show_notice(SAFE_NOTICE)
	_busy = false


## The old woman always heals; what she says and gives comes from the quest.
func _on_talk() -> void:
	if _busy:
		return
	_busy = true
	var result := state.quest.talk()
	var lines: Array[String] = []
	lines.append_array(result.lines)
	lines.append(HEAL_LINE)
	state.heal_full()
	if result.potions > 0:
		state.inventory.add(Inventory.POTION, result.potions)
	_refresh_status()
	await _world.show_dialogue(Quest.NPC_NAME, lines)
	_world.set_boss_present(state.quest.boss_available())
	_busy = false


## Map music, or the village one inside the clearing.
func _play_map_music() -> void:
	_audio.play_music(MusicLibrary.VILLAGE if _world.in_village() else MusicLibrary.MAP)


## Updates the map's status window; on autoplay also prints each new quest line.
func _refresh_status() -> void:
	var quest_text := state.quest.status_text()
	_world.refresh_status(state.hero, state.inventory.count(Inventory.POTION), quest_text)
	if _autoplay and quest_text != _last_quest_text:
		print(quest_text)
	_last_quest_text = quest_text


func _build_fade() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade)


func _fade_to(alpha: float) -> void:
	var t := create_tween()
	t.tween_property(_fade, "color:a", alpha, FADE_TIME)
	await t.finished
