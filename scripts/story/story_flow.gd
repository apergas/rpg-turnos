class_name StoryFlow extends Node
## Node, a piece of Game: the story played on the map. Each cutscene of data/cutscenes/
## through its CutscenePlayer (play_scene(), marked seen), the prologue of a new game
## (play_prologue()), the first visit's scene of each village (check_village_scene();
## Villaclaro's in the v3 is V3Flow's), the companion's line the first time a land of the
## caravan is reached (check_arrival_line()), and the three endings: the v1's credits
## (finish_game()), the v2's screen beyond the portal and its credits, after which the game
## goes on in the Caravana (finish_v2()), and the v3's question, final scene and credits, after
## which it goes on in Brumaclara en fiesta (finish_v3(), 3.3.0); BattleFlow asks for the last two
## through finish_part(). Gets the session in setup(); never stores Game or a World.

## The v1's ending is over, or the v2's on autoplay: Game goes back to the title.
signal quit_requested
## Autoplay: the v1's credits rolled (GameAutoplay prints the numbers of the run).
signal game_completed(time_text: String)
## Autoplay: the v2's credits rolled (CreditsData.v2_numbers()).
signal v2_completed(numbers: Dictionary)

const CUTSCENE_PATH := "res://data/cutscenes/%s.tres"
const LOAD_FAILED_NOTICE := "No se pudo cargar la partida. Empiezas de nuevo."
## After the v2's credits the game goes on in the Caravana, by the campfire (3.0.0), and the
## Jefe de caravana says this.
const CAMPFIRE_ENTRY := "hoguera"
const PORTAL_STILL_LINE := "El portal se ha quedado quieto. Si quieres ver qué hay al otro lado, ya sabes dónde está."

## The save could not be read: the new game says so after the prologue (Game sets it).
var load_failed := false
## switch_zone.call(zone_id, entry_id): builds a map under black (ZoneTravel).
var switch_zone: Callable
## await choose_companion.call(): the Jefe de caravana's choice (CaravanFlow).
var choose_companion: Callable
## show_touch_hint.call(): the phone's first walking line (Game).
var show_touch_hint: Callable

var _ctx: SessionContext
var _cutscenes: CutscenePlayer


func setup(ctx: SessionContext) -> void:
	_ctx = ctx


func _ready() -> void:
	_build_cutscenes()


func _build_cutscenes() -> void:
	_cutscenes = CutscenePlayer.new()
	_cutscenes.audio = _ctx.audio
	_cutscenes.fade = _ctx.fade
	_cutscenes.set_flag = _scene_flag
	_cutscenes.travel = _scene_travel
	add_child(_cutscenes)


## The companion's line the first time the hero reaches a land of the caravan
## (Allies.ARRIVALS), once the place's name is up; remembered with its llegada_<zone> flag.
## Nothing without a companion. The caller is busy.
func check_arrival_line() -> void:
	var line := Allies.arrival_line(_ctx.state.ally_id, _ctx.zone.id)
	var flag := Allies.arrival_flag(_ctx.zone.id)
	if line == "" or _ctx.state.has_flag(flag):
		return
	_ctx.state.world_flags[flag] = true
	_ctx.world.freeze(true)
	await get_tree().create_timer(World.BANNER_FADE).timeout
	if RunFlags.autoplay():
		print("Compañero: %s" % line)
	await _ctx.world.show_dialogue(Allies.display_name(_ctx.state.ally_id), [line])


## Plays the cutscene of this zone's village if the hero is inside it and has not seen
## it yet (only when nothing else is going on); autosaves after it.
func check_village_scene() -> void:
	if _ctx.busy or not _ctx.world.in_village():
		return
	var scene := _ctx.state.story.scene_on_village(_ctx.zone.id)
	if scene == "":
		scene = CaravanFlow.arrival_scene(_ctx.state, _ctx.zone.id)
	if scene == "":
		scene = V3Flow.arrival_scene(_ctx.state, _ctx.zone.id)
	if scene == "":
		return
	_ctx.set_busy.call(true)
	await play_scene(scene)
	if scene == "caravana_campamento":
		await choose_companion.call()
	_ctx.autosave.call(false)
	_ctx.set_busy.call(false)


## Plays data/cutscenes/<scene_id>.tres on the current map and marks it seen. The
## caller is busy; the map is the player's again when it returns.
func play_scene(scene_id: String) -> void:
	var scene := load(CUTSCENE_PATH % scene_id) as Cutscene
	_ctx.state.story.mark_seen(scene_id)
	_cutscenes.world = _ctx.world
	_cutscenes.hero_name = _ctx.state.hero.display_name
	_cutscenes.companion_name = Allies.display_name(_ctx.state.ally_id) if _ctx.state.ally_id != "" else ""
	await _cutscenes.play(scene)
	_ctx.audio.play_ambient(_ctx.zone.ambient)  # a "music" step silenced it
	_ctx.refresh_status.call()


## A new game: the prologue (it fades in from black), then the slimes quest is on. A
## save that could not be read also lands here, and says so now the map is visible.
func play_prologue() -> void:
	await play_scene("prologo")
	_ctx.state.quest.start()
	_ctx.refresh_status.call()
	_ctx.autosave.call(false)
	_ctx.set_busy.call(false)
	show_touch_hint.call()
	if load_failed:
		_ctx.world.show_notice(LOAD_FAILED_NOTICE, "Cuidado", &"text-danger")


## After the ending: the save is marked finished (the hero is back in Villaclaro), the
## credits roll with the numbers of the game and Game goes back to the title. They cover
## everything, and Game stays busy, so no status window, map square, ☰ or prompt shows.
func finish_game() -> void:
	_ctx.state.story.finished = true
	_ctx.world.freeze(true)
	_ctx.autosave.call(false)
	var time_text := CreditsData.clock(_ctx.play_time)
	_ctx.audio.play_music(MusicLibrary.TITLE)
	_ctx.audio.stop_ambient()
	var layer := CanvasLayer.new()
	layer.layer = UiTokens.LAYER_OVERLAY
	add_child(layer)
	var credits := CreditsScreen.new()
	layer.add_child(credits)
	await _ctx.fade.call(0.0)
	await credits.run(CreditsData.credits_sections(_ctx.state, time_text))
	if RunFlags.autoplay():
		game_completed.emit(time_text)
	quit_requested.emit()


## After the v2's ending (the cruce scene ends under black): the game is finished in the v2
## and saved in the Caravana, by the campfire; then the screen beyond the portal, the v2's
## credits and "Continuará". The game goes on there: from black, the Jefe de caravana points at
## the calmed portal (the way to the v3, 3.0.0). On autoplay Game goes back to the title as
## before: the v2's run ends with its credits. Game stays busy until the Jefe has spoken, so no
## window, ☰ or prompt shows over the screens.
func finish_v2() -> void:
	MusicLibrary.build(MusicLibrary.BEYOND)  # under black
	_ctx.state.story.finished_v2 = true
	switch_zone.call("caravana", CAMPFIRE_ENTRY)
	_ctx.world.freeze(true)
	_ctx.autosave.call(false)
	var numbers := CreditsData.v2_numbers(_ctx.state, _ctx.play_time)
	_ctx.world.set_active(false)
	_ctx.audio.stop_ambient()
	_ctx.audio.play_music(MusicLibrary.BEYOND)
	var beyond := BeyondScreen.new()
	beyond.setup(_ctx.state.loadout.worn(Equipment.WEAPON), _ctx.state.loadout.worn(Equipment.SHIELD),
		_ctx.state.loadout.worn(Equipment.HELMET), _ctx.state.ally_id)
	add_child(beyond)
	await _ctx.fade.call(0.0)
	await beyond.run()
	await _ctx.fade.call(1.0)
	beyond.queue_free()
	var layer := CanvasLayer.new()
	layer.layer = UiTokens.LAYER_OVERLAY
	add_child(layer)
	var credits := CreditsScreen.new()
	credits.end_text = CreditsScreen.TO_BE_CONTINUED
	layer.add_child(credits)
	await _ctx.fade.call(0.0)
	await credits.run(CreditsData.v2_credits_sections(_ctx.state, numbers))
	if RunFlags.autoplay():
		v2_completed.emit(numbers)
		quit_requested.emit()
		return
	await _ctx.fade.call(1.0)
	layer.queue_free()
	_ctx.world.set_active(true)
	_ctx.world.freeze(true)
	_ctx.play_map_music.call()
	await _ctx.fade.call(0.0)
	await _ctx.world.show_dialogue(CaravanFlow.CARAVAN_CHIEF, [PORTAL_STILL_LINE])
	_ctx.set_busy.call(false)


## The ending of a part after its last boss (BattleFlow): the v2's (2) or the v3's (3).
func finish_part(part: int) -> void:
	if part == 2:
		await finish_v2()
	else:
		await finish_v3()


## After the Eco de Albor (its albor scene ends on the Fuente; Game is busy): the question of the
## ending (on autoplay its first answer, the last with --autoplay-ending=vencer), the answer's
## final scene (its "flag" step sets ALBOR_FREED or ALBOR_BEATEN; it brings the hero to
## Brumaclara en fiesta and ends under black), the game finished in the v3 and saved there, the
## v3's credits with "Fin", then from black Orvalla's line and the prizes of the families the Eco
## completed. The game goes on in Brumaclara. Freeing Albor leaves the Amuleto del Alba in the
## Fuente (it leaves the key items).
func finish_v3() -> void:
	var choice := 0
	if RunFlags.autoplay_ending() == AutoplayStarts.BEAT_ENDING:
		choice = StoryState.ENDING_OPTIONS.size() - 1
		print("Pregunta: %s -> %s" % [StoryState.ENDING_QUESTION,
			StoryState.ENDING_OPTIONS[choice]])
	else:
		choice = await _ctx.world.ask(StoryState.ENDING_QUESTION, StoryState.ENDING_OPTIONS, 0,
			false)
	if choice == 0:
		_ctx.state.key_items.erase(StoryState.AMULET_FLAG)
	await play_scene(StoryState.ENDING_SCENES[choice])
	_ctx.state.story.finished_v3 = true
	_ctx.world.freeze(true)
	_ctx.autosave.call(false)
	var numbers := CreditsData.v3_numbers(_ctx.state, _ctx.play_time)
	_ctx.world.set_active(false)
	_ctx.audio.stop_ambient()
	_ctx.audio.play_music(MusicLibrary.TITLE)
	var layer := CanvasLayer.new()
	layer.layer = UiTokens.LAYER_OVERLAY
	add_child(layer)
	var credits := CreditsScreen.new()
	layer.add_child(credits)
	await _ctx.fade.call(0.0)
	await credits.run(CreditsData.v3_credits_sections(_ctx.state, numbers))
	await _ctx.fade.call(1.0)
	layer.queue_free()
	_ctx.world.set_active(true)
	_ctx.world.freeze(true)
	_ctx.play_map_music.call()
	await _ctx.fade.call(0.0)
	await _ctx.world.show_dialogue(StoryState.V3_KEEPER,
		[StoryState.fill(StoryState.V3_AFTER_END_LINE, _ctx.state.hero.display_name)])
	var family_lines := BattleRewards.family_rewards(_ctx.state)
	if not family_lines.is_empty():
		_ctx.audio.play_sfx(SfxLibrary.LEVEL_UP)
		await _ctx.world.show_dialogue("", family_lines)
	_ctx.refresh_status.call()
	_ctx.autosave.call(false)
	_ctx.set_busy.call(false)


## What CutscenePlayer's "travel" step does: builds zone_id at entry_id under black and
## hands the new map over.
func _scene_travel(zone_id: String, entry_id: String) -> World:
	switch_zone.call(zone_id, entry_id)
	return _ctx.world


## What CutscenePlayer's "flag" step does. A flag that is a key item's id gives the key item too
## (the Amuleto del Alba, 3.2.0).
func _scene_flag(flag: String) -> void:
	_ctx.state.world_flags[flag] = true
	if Inventory.KEY_ITEMS.has(flag) and not flag in _ctx.state.key_items:
		_ctx.state.key_items.append(flag)
	_ctx.world.set_world_flags(_ctx.state.world_flags)
	_ctx.refresh_status.call()  # a figure may come with the flag (the Jefe de caravana)
