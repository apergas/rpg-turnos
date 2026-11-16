class_name BattleFlow extends Node
## Node, a piece of Game: a battle on top of the map. When the hero touches a group of
## monsters (World.contact_enemies(), its formation) or the zone's boss (first, for the boss of a
## land that closes behind it, the question of ClosingLands.warning()), it fades to black,
## puts a BattleScene over the frozen map and, once it is over, plays back what happened:
## a victory's rewards (BattleRewards.after_victory(): gold, medals, quests, a boss's flag,
## notice, cutscene and first prize, the families), a fled group left half see-through, a
## defeat's way back to the village with half the gold; then the boss's cutscene or its
## notice, the missions done, the ending when it is due, and the save. Also says whether the
## zone's boss is on the map (update_boss()). Gets the session in setup(); never stores Game
## or a World.

## A battle starts (on autoplay the quiet clock starts over).
signal battle_started
## A battle was won (on autoplay: the common enemies counted and the medals printed).
signal enemies_beaten(enemies: Array[Combatant], medals_won: int)
## A battle was lost, before the hero goes back to the village (on autoplay it is printed).
signal battle_lost(zone_id: String)
## A battle with the postgame boss (the Eco de la Niebla) is over.
signal echo_fought(won: bool)
## --autoplay-save: the first save after a won battle was printed; Game goes back to the title.
signal quit_requested

const BATTLE_SCENE := preload("res://scenes/battle/battle_scene.tscn")

## Autoplay meets the postgame boss (only --autoplay-zone=eco; Game sets it).
var echo_wanted := false
## The chance of a medal drop on the medal tour (AutoplayStarts.MEDAL_TOUR_CHANCE; Game sets
## it); 0 for the part's own (Medals.drop_chance()).
var medal_chance := 0.0
## --autoplay-save on a new game: print the first save after a won battle and quit (Game sets it).
var print_save := false
## await play_scene.call(scene_id): a boss's cutscene (StoryFlow).
var play_scene: Callable
## await finish_game.call(): the v1's ending and credits (StoryFlow).
var finish_game: Callable
## await finish_part.call(part): the ending of the v2 (2) or of the v3 (3) and its credits
## (StoryFlow).
var finish_part: Callable
## go_to_town.call(): a beaten hero back to the last village (ZoneTravel).
var go_to_town: Callable
## await after_battle.call(outcome): the autoplay's next move (GameAutoplay); not set
## without autoplay.
var after_battle: Callable

var _ctx: SessionContext


func setup(ctx: SessionContext) -> void:
	_ctx = ctx


## The boss of the current map (BattleRewards.boss_id()), or its postgame boss once the game
## is finished.
func boss_id() -> String:
	return BattleRewards.boss_id(_ctx.zone, _ctx.state)


## The boss of the current map is due (BattleRewards.boss_wanted()); the postgame boss is,
## off autoplay, always; on autoplay only on --autoplay-zone=eco.
func boss_wanted() -> bool:
	return BattleRewards.boss_wanted(_ctx.zone, _ctx.state,
		not RunFlags.autoplay() or echo_wanted)


## The zone's boss is on the map until beaten: the Rey Slime only while the quest asks
## for it; on autoplay only from the zone's autoplay_boss_level on, and only while the
## hero has AutoplayStarts.AUTOPLAY_BOSS_HP of his max HP and AUTOPLAY_BOSS_MP of his max MP
## (a worn-out hero fights on, or rests, first).
func update_boss() -> void:
	if boss_id() == "":
		return
	var strong_enough := not RunFlags.autoplay() \
		or (_ctx.state.hero.level >= _ctx.zone.autoplay_boss_level \
		and AutoplayStarts.rested_for_boss(_ctx.state.hero))
	_ctx.world.set_boss_present(boss_wanted() and strong_enough)


## A group of monsters touched on the map, or the zone's boss (boss): the battle on top of
## the frozen map, then everything that follows it.
func on_encounter(boss: bool) -> void:
	if _ctx.busy:
		return
	_ctx.set_busy.call(true)
	if boss:
		var agreed: bool = await _boss_agreed()
		if not agreed:
			return
	battle_started.emit()
	_ctx.state.battles += 1
	var enemies: Array[Combatant] = []
	if boss:
		enemies.append(EnemyLibrary.data(boss_id()))
	else:
		enemies = _ctx.world.contact_enemies()
	if not boss:
		var kept := _ctx.state.give_metal_slime_hp(enemies)
		if RunFlags.autoplay() and kept > 0:
			print("Slime de Metal con PV %d" % kept)
	BattleRewards.note_enemies(_ctx.state, enemies, false)
	var echo := boss and boss_id() == _ctx.zone.postgame_boss_id
	await _ctx.fade.call(1.0)
	_ctx.world.set_active(false)
	var track := MusicLibrary.BATTLE
	if boss:
		track = MusicLibrary.ALBOR if boss_id() == StoryState.V3_FINAL_BOSS else MusicLibrary.BOSS
	_ctx.audio.play_music(track)  # under black: building a new track stalls nobody
	_ctx.audio.stop_ambient()
	var battle: BattleScene = BATTLE_SCENE.instantiate()
	battle.setup(_ctx.state.hero, enemies, _ctx.state.inventory)
	battle.set_audio(_ctx.audio)
	battle.set_equipment(_ctx.state.loadout.worn(Equipment.WEAPON),
		_ctx.state.loadout.worn(Equipment.SHIELD), _ctx.state.loadout.worn(Equipment.HELMET))
	battle.gold_lost = _ctx.state.defeat_gold_loss()
	battle.char_time = _ctx.options.char_time()
	battle.time_scale = _ctx.options.combat_scale()
	battle.camera_shake = _ctx.options.camera_shake
	_ctx.state.sync_level_cap()
	battle.difficulty = _ctx.state.difficulty
	battle.zone = _ctx.zone
	battle.quest_items = _ctx.state.quests.wanted_items(_ctx.state)
	battle.medals_carried = _ctx.state.medals.size()
	battle.medal_chance = medal_chance if medal_chance > 0.0 \
		else Medals.drop_chance(_ctx.state.part())
	if _ctx.state.ally_id != "":
		battle.ally_step = _ctx.state.ally_step()
		battle.ally = Allies.data(_ctx.state.ally_id, battle.ally_step)
	add_child(battle)
	await _ctx.fade.call(0.0)
	var outcome: int = await battle.finished
	# A call for help adds enemies during the fight.
	BattleRewards.note_enemies(_ctx.state, battle.engine.enemies, false)
	var won := outcome == BattleEngine.State.WON
	if echo:
		echo_fought.emit(won)
	if won or outcome == BattleEngine.State.LOST:
		Wells.on_battle(_ctx.state)
		_ctx.world.set_dry_wells(Wells.dry_ids(_ctx.state))
	await _ctx.fade.call(1.0)
	if not boss:
		# Under black: a beaten group leaves the map, one fled from stays half see-through.
		_ctx.world.end_contact(outcome)
	if _ctx.state.keep_metal_slime_hp(battle.engine.enemies, outcome) > 0:
		if RunFlags.autoplay():
			print("Slime de Metal: PV %d guardados" % _ctx.state.metal_slime_hp)
		_ctx.autosave.call(false)  # a fled battle saves nothing else: quitting now must not lose them
	var notice := ""
	var reward_lines: Array[String] = []
	var scene := ""
	var mission_done := false
	var finished_quests: Array[Dictionary] = []
	var family_lines: Array[String] = []
	var ending := 0
	if won:
		var rewards := BattleRewards.after_victory(_ctx.state, _ctx.zone,
			battle.engine.enemies, battle.engine.gold_won, battle.engine.medals_won, boss)
		notice = rewards.notice
		reward_lines.assign(rewards.reward_lines)
		scene = rewards.scene
		mission_done = rewards.mission_done
		finished_quests.assign(rewards.finished_quests)
		family_lines.assign(rewards.family_lines)
		ending = rewards.ending
		enemies_beaten.emit(battle.engine.enemies, battle.engine.medals_won)
	elif outcome == BattleEngine.State.LOST:
		battle_lost.emit(_ctx.zone.id)
		_ctx.state.gold -= battle.gold_lost
		_ctx.state.heal_full()
		go_to_town.call()
		notice = "Has vuelto %s." % ZoneTravel.to_place(_ctx.zone.village_name)
	battle.queue_free()
	_ctx.world.set_world_flags(_ctx.state.world_flags)
	update_boss()
	_ctx.refresh_status.call()
	_ctx.world.set_active(true)
	# Frozen until the fade is over: an exit or an encounter while Game is busy would be
	# ignored and leave the map waiting forever.
	_ctx.world.freeze(true)
	_ctx.play_map_music.call()
	if scene != "":
		# Under black: no status window or map square while the map fades in.
		_ctx.world.begin_cutscene()
	await _ctx.fade.call(0.0)
	if scene != "":
		# The boss's cutscene says what the notice would (the fragment, the open road).
		await play_scene.call(scene)
	else:
		await _ctx.world.freeze(false)
		if not reward_lines.is_empty():
			await _ctx.world.show_dialogue("", reward_lines)
		elif notice != "":
			_ctx.world.show_notice(notice, "Premio", &"text-positive")
	if not family_lines.is_empty():
		_ctx.audio.play_sfx(SfxLibrary.LEVEL_UP)
		await _ctx.world.show_dialogue("", family_lines)
	if mission_done:
		_ctx.world.show_mission_done(QuestLog.done_text(Quest.TITLE))
	for finished: Dictionary in finished_quests:
		_ctx.world.show_mission_done(QuestLog.done_text(finished.title))
		_ctx.world.show_notice(" ".join(finished.lines), "Misión cumplida", &"text-positive")
	if ending == 2:
		await finish_part.call(ending)
		return
	if ending == 3:
		# The game goes on in Brumaclara; on autoplay the run prints the v3's numbers and ends.
		await finish_part.call(ending)
		if after_battle.is_valid():
			await after_battle.call(outcome)
		return
	if won and _ctx.state.is_finished() and not _ctx.state.story.finished:
		await finish_game.call()
		return
	if outcome == BattleEngine.State.LOST:
		_ctx.autosave.call(false)  # the gold lost sticks: going back to the title can't undo it
	if won:
		var data: Dictionary = _ctx.autosave.call(not boss and finished_quests.is_empty())  # keep its reward readable
		if print_save and not data.is_empty():
			print("Guardado: %s" % CreditsData.summary(data))
			quit_requested.emit()
			return
	_ctx.set_busy.call(false)
	if after_battle.is_valid():
		await after_battle.call(outcome)


## The boss of a land that closes behind it, with something of it still missing: true to fight
## now (always if ClosingLands.warning() has nothing to say; on autoplay World.ask() takes
## "Luchar ahora"). "Volver" gives the map back (set_active() ends the encounter's wait and
## calms the groups); the boss waits until the hero has walked away from it, as after a battle.
func _boss_agreed() -> bool:
	var warning := ClosingLands.warning(_ctx.state, boss_id())
	if warning == "":
		return true
	var answer: int = await _ctx.world.ask(warning, ClosingLands.ANSWERS, ClosingLands.GO_BACK)
	if answer != ClosingLands.GO_BACK:
		return true
	_ctx.set_busy.call(false)
	_ctx.world.set_active(true)
	return false
