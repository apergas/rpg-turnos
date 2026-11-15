class_name GameAutoplay extends Node
## Node, a piece of Game, only with --autoplay: the self-playing run. Starts a new game in
## the zone of --autoplay-zone=<id> with AutoplayStarts' state (apply_start()) and plays it
## as a player would: after a won battle it flies back to the last village with an Ala de
## viaje when the hero needs rest, is too worn for the boss, has a report waiting or has no
## group left (retreat(): the inn (or the wells, with no inn open), the shop, the figures with a
## mark and, in Brumaclara, an errand through the portal to the Caravana's Mercader for the
## etapa's gear, restock(), then the portal back); after a v3 boss whose scene brings the hero
## home it restocks there; after a defeat it restocks; an empty map, or one quiet for
## AutoplayStarts.AUTOPLAY_STALL_S, gets its groups back (step()); and it runs the medal tour
## of --autoplay-zone=medallas. It prints what a reader of the log follows: each zone, each
## change of mission line, gold or gear, each defeat, the Eco's results and the numbers after
## the credits, or where the v3 that exists ends. Uses only the public functions of ZoneTravel and FigureTalk (use_pieces())
## and the rules; never stores Game or a World.

## The medal tour is over: Game goes back to the title (which quits on autoplay).
signal quit_requested

## --autoplay-zone=eco: BattleFlow brings out the Eco de la Niebla (Game passes it on).
var echo := false
## A start of AutoplayStarts.V2_STARTS: CaravanFlow leaves with the caravan (Game passes it on).
var plays_v2 := false
## --autoplay-zone=medallas: the tour is on.
var medal_tour := false
## --autoplay-companion=<id> (AutoplayStarts.companion()).
var companion := AutoplayStarts.DEFAULT_COMPANION

var _ctx: SessionContext
var _travel: ZoneTravel
var _talk: FigureTalk
## Seconds since the last battle or change of map (AutoplayStarts.AUTOPLAY_STALL_S).
var _quiet_s := 0.0
## Defeats so far (each prints "Derrota en <zone> (n)"; the credits say the total).
var _defeats := 0
## --autoplay-zone=eco: fights with the Eco and how many were won, printed after each.
var _echo_fights := 0
var _echo_wins := 0
## Common enemies beaten in won battles (the credits print it with the medals, to tune
## Medals.DROP_CHANCE).
var _common_beaten := 0
var _last_missions: Array[String] = []
var _last_gear_text := ""


func setup(ctx: SessionContext) -> void:
	_ctx = ctx
	companion = AutoplayStarts.companion()


func use_pieces(travel: ZoneTravel, talk: FigureTalk) -> void:
	_travel = travel
	_talk = talk


## --autoplay-zone=<id>: starts the new game in that zone with AutoplayStarts.AUTOPLAY_ZONES'
## state. Called by Game before the first map is built.
func apply_start() -> void:
	var start_id := RunFlags.autoplay_zone()
	if start_id == "":
		return
	var state := _ctx.state
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
		state.ally_id = companion
	var items: Dictionary = start.get("items", {})
	for id: String in items:
		state.inventory.add(id, items[id])
	echo = start_id == AutoplayStarts.ECHO_START
	plays_v2 = start_id in AutoplayStarts.V2_STARTS
	medal_tour = start_id == AutoplayStarts.MEDAL_TOUR
	state.story.mark_seen_for_flags(state.world_flags)
	if state.has_flag(StoryState.V3_FLAG):
		state.story.v3_start = [0.0, 0]  # a start inside the v3 counts its numbers from here
	if start.get("finished", false):
		state.story.finished = true
	state.sync_level_cap()
	print("Zona de inicio: %s (Nv %d)" % [zone_id, state.hero.level])


## Every frame (Game._process(), after the play time): away from a village and with nothing
## going on, a map quiet for AUTOPLAY_STALL_S gets its groups back while the hero still has
## levels to win; at the boss's level but too worn for it, one Ala is made here.
func step(delta: float) -> void:
	if _ctx.busy or _ctx.world == null or _ctx.world.in_village():
		return
	_quiet_s += delta
	if _quiet_s > AutoplayStarts.AUTOPLAY_STALL_S and hunts():
		_quiet_s = 0.0
		print("Grupos repuestos (partida automática, sin combates)")
		_travel.respawn_groups()
	elif _quiet_s > AutoplayStarts.AUTOPLAY_STALL_S and boss_needs_rest() \
			and _ctx.state.inventory.count(Inventory.WING) > 0:
		# At the boss's level but too worn for it, with no battle coming that would bring
		# the retreat: one Ala, made here (the quiet clock starts over).
		_quiet_s = 0.0
		retreat()


## A battle started, a map was built or the portal was taken: the quiet clock starts over.
func reset_quiet() -> void:
	_quiet_s = 0.0


## What follows a battle once the map is the player's again (BattleFlow awaits it): the end
## of the medal tour, the retreat, the groups back, or a restock after a defeat.
func after_battle(outcome: int) -> void:
	var won := outcome == BattleEngine.State.WON
	if won and _ctx.state.part() == 3 and not StoryState.v3_way_on(_ctx.state.world_flags):
		# The last zone of the v3 there is so far is behind (3.1.0: the Coloso): the hero goes
		# back to Brumaclara for the reports and offers, and the run ends.
		if not _ctx.world.in_village() and _ctx.state.inventory.count(Inventory.WING) > 0:
			await fly_home()
		if _ctx.world.in_village():
			await restock()
		print_v3_so_far()
		quit_requested.emit()
		return
	if won and _ctx.state.part() == 3 and _ctx.world.in_village():
		# A boss scene of the v3 brought the hero home (the Garza's): the inn, the reports and
		# offers and the Caravana's gear before the next land, as a player would.
		await restock()
		return
	if medal_tour and won and _ctx.state.medals.size() >= Medals.MEDALS.size():
		await finish_medal_tour()
		return
	if won and wants_retreat():
		await retreat()
	elif won and needs_groups():
		# No Ala de viaje (or in a village): the groups come back as if it had flown away
		# and back. Only the autoplay does this.
		print("Grupos repuestos (partida automática)")
		_travel.respawn_groups()
	elif outcome == BattleEngine.State.LOST:
		await restock()


## A map was built (ZoneTravel.zone_switched): the zone, the level and the play time.
func on_zone_switched(zone_id: String) -> void:
	_quiet_s = 0.0
	print("Zona: %s (Nv %d, %s)" % [zone_id, _ctx.state.hero.level,
		CreditsData.clock(_ctx.play_time)])


## A won battle: the common enemies beaten and the medals carried.
func on_enemies_beaten(enemies: Array[Combatant], medals_won: int) -> void:
	for enemy in enemies:
		if not enemy.is_boss:
			_common_beaten += 1
	if medals_won > 0:
		print("Medalla: %d/%d" % [_ctx.state.medals.size(), Medals.MEDALS.size()])


## A lost battle, before the hero goes back to the village.
func on_battle_lost(zone_id: String) -> void:
	_defeats += 1
	print("Derrota en %s (%d)" % [zone_id, _defeats])


## A battle with the Eco de la Niebla is over.
func on_echo_fought(won: bool) -> void:
	_echo_fights += 1
	_echo_wins += 1 if won else 0
	print("Eco de la Niebla: %s (%d de %d ganados)" % ["victoria" if won else "derrota",
		_echo_wins, _echo_fights])


## Each new mission line and each change of gold or equipment (Game._refresh_status()).
func note_status(missions: Array[String]) -> void:
	if missions != _last_missions:
		print(" · ".join(missions))
	_last_missions = missions
	var state := _ctx.state
	var loadout := state.loadout
	var worn := PackedStringArray()
	for slot in Equipment.SLOTS:
		if loadout.worn(slot) != "":
			worn.append(Equipment.display_name(loadout.worn(slot)))
	var gear_text := "Oro %d G · Equipo: %s · ATK %d DEF %d VEL %d" % [state.gold,
		", ".join(worn), state.hero.total_attack(), state.hero.total_defense(),
		state.hero.total_speed()]
	if gear_text != _last_gear_text:
		print(gear_text)
	_last_gear_text = gear_text


## The numbers of the whole run after the v1's credits (StoryFlow.game_completed).
func print_game_completed(time_text: String) -> void:
	var state := _ctx.state
	print("Juego completado: Nv %d, tiempo de juego %s, misiones %d" % [state.hero.level,
		time_text, state.quests_done()])
	_print_run_tail()


## The numbers of the v2 after its credits (StoryFlow.v2_completed).
func print_v2_completed(numbers: Dictionary) -> void:
	var state := _ctx.state
	print("Juego completado (v2): Nv %d, tiempo en la caravana %s, tiempo de juego %s, misiones de la caravana %d/%d"
		% [state.hero.level, numbers.time, CreditsData.clock(_ctx.play_time),
		state.quests.done_of(2), QuestLog.total_of(2)])
	_print_run_tail()


## The numbers of the v3 so far, once its last zone that exists is behind (3.1.0: the Coloso
## beaten): the autoplay run of the v3 ends there.
func print_v3_so_far() -> void:
	var state := _ctx.state
	var numbers := CreditsData.v3_numbers(state, _ctx.play_time)
	print("Fin de la v3 por ahora: Nv %d, tiempo en Brumaclara %s, tiempo de juego %s, misiones de Brumaclara %d/%d"
		% [state.hero.level, numbers.time, CreditsData.clock(_ctx.play_time),
		state.quests.done_of(3), QuestLog.total_of(3)])
	_print_run_tail()


## The lines every end of a run prints: families, defeats, medals.
func _print_run_tail() -> void:
	var state := _ctx.state
	print("Familias completas: %d/%d" % [Bestiary.complete_count(state),
		Bestiary.families(state).size()])
	print("Derrotas: %d" % _defeats)
	print("Medallas: %d/%d (enemigos comunes vencidos: %d)" % [state.medals.size(),
		Medals.MEDALS.size(), _common_beaten])


## --autoplay-zone=medallas, once the map is the player's: says where it hunts and sets the
## time limit (AutoplayStarts.MEDAL_TOUR_TIME).
func start_medal_tour() -> void:
	if not medal_tour:
		return
	print("Medallas: a cazar en %s" % _ctx.zone.id)
	get_tree().create_timer(AutoplayStarts.MEDAL_TOUR_TIME).timeout.connect(
		_on_medal_tour_timeout)


## Autoplay: flies back to the last village with an Ala de viaje, rests and shops there and
## comes back through the portal.
func retreat() -> void:
	await fly_home()
	await restock()
	await _travel.on_portal()


## Autoplay: uses an Ala de viaje to fly back to the last village.
func fly_home() -> void:
	_ctx.state.inventory.take(Inventory.WING)
	print("Retirada al pueblo (PV %d/%d, PM %d, pociones %d)" % [_ctx.state.hero.hp,
		_ctx.state.hero.max_hp, _ctx.state.hero.mp, _ctx.potion_count()])
	await _travel.on_travel_requested()


## Autoplay: needs rest (GameState.needs_rest()), is only kept from the zone's boss by its
## HP or MP, has a report waiting in the last village or has no group left to fight
## (needs_groups(): the portal back brings them), away from a village, with an Ala de
## viaje (the night at the inn is free). The route may never pass the one who waits.
func wants_retreat() -> bool:
	if medal_tour:
		return false  # the medal tour never flies back: it hunts where it is
	var report := not _ctx.state.quests.reports_here(_ctx.state.town_zone, _ctx.state.inventory).is_empty()
	return (_ctx.state.needs_rest() or boss_needs_rest() or report or needs_groups()) \
		and not _ctx.world.in_village() and _ctx.state.inventory.count(Inventory.WING) > 0


## Autoplay: no group left on this map while the hero still has levels to win before its
## boss (they only come back when the map is built again).
func needs_groups() -> bool:
	return _ctx.world.group_count() == 0 and hunts()


## Autoplay: the hero goes after the groups while he has levels to win before the zone's
## boss. The medal tour hunts until it carries every medal.
func hunts() -> bool:
	if medal_tour:
		return _ctx.state.medals.size() < Medals.MEDALS.size()
	return _ctx.state.hero.level < _ctx.zone.autoplay_boss_level


## Autoplay: the zone's boss is due at this level but the hero is too worn for it. MP
## doesn't come back by walking, so without a rest the boss would never show up.
func boss_needs_rest() -> bool:
	return BattleRewards.boss_wanted(_ctx.zone, _ctx.state, echo) and _ctx.state.hero.level >= _ctx.zone.autoplay_boss_level \
		and not AutoplayStarts.rested_for_boss(_ctx.state.hero)


## Autoplay, in the village: a night at its inn and the shop's picks, as if the hero had
## walked up to the innkeeper and the merchant.
func restock() -> void:
	var flags := _ctx.state.world_flags
	var inn := false
	for npc: Dictionary in _ctx.zone.npcs:
		if npc.kind == "inn" and ZoneData.is_present(npc, flags):
			inn = true
			await _talk.on_inn(npc.id)
	if not inn:
		for well: Dictionary in _ctx.zone.wells:
			await _talk.on_well(well.id, well.kind)
	for npc: Dictionary in _ctx.zone.npcs:
		if npc.kind == "shop" and ZoneData.is_present(npc, flags):
			await _talk.on_shop(npc.id)
	# On a caravan game the figures that offer a quest ("!") are visited too, or autoplay
	# would never take the v2's quests; a v1 game keeps the reports only.
	var marks := {}
	if _ctx.state.in_caravan():
		marks = _ctx.state.quests.markers(_ctx.zone.id, _ctx.state.inventory, _ctx.state.world_flags)
	for i in _ctx.zone.npcs.size():
		var npc_name: String = _ctx.zone.npcs[i].name
		if npc_name in _ctx.state.quests.reports_here(_ctx.zone.id, _ctx.state.inventory) \
				or marks.get(npc_name, "") == QuestLog.NEW_MARK:
			await _talk.on_npc(i)
	if _ctx.state.part() == 3 and _ctx.zone.id == BrumaclaraLook.ZONE:
		await _caravan_errand()


## Autoplay, in Brumaclara (the v3): the Caravana's Mercader, ten steps away through the
## portal, sells the gear of the etapa (Shop.caravan_shop()); while he has a piece the gold pays
## for (Shop.gear_to_buy()), the hero walks through, buys and comes back, as a player would.
## Only for the gear: the potions wait for Brumaclara's own shop, as in the 3.0.0.
func _caravan_errand() -> void:
	if not Shop.gear_to_buy(_ctx.state, Shop.caravan_shop(_ctx.state.shop_step())):
		return
	print("Recado en la Caravana")
	# The Caravana's entry from Brumaclara has the village's id; Brumaclara's from it is "portal".
	await _travel.on_exit(CampLook.ZONE, BrumaclaraLook.ZONE)
	await _talk.on_shop(Shop.CARAVAN_SHOP)
	await _travel.on_exit(BrumaclaraLook.ZONE, "portal")


## --autoplay-zone=medallas: the time is up with medals still missing; it ends anyway.
func _on_medal_tour_timeout() -> void:
	if not medal_tour:
		return
	while _ctx.busy:
		await get_tree().create_timer(1.0).timeout
	if not medal_tour:  # the tour finished by itself while this waited
		return
	print("Medallas: tiempo agotado (%d/%d)" % [_ctx.state.medals.size(), Medals.MEDALS.size()])
	await finish_medal_tour()


## --autoplay-zone=medallas: under black to Villaclaro, the Coleccionista; then the forest
## village's (his joke); the counts printed and back to the title (which quits on autoplay).
func finish_medal_tour() -> void:
	medal_tour = false
	_ctx.set_busy.call(true)
	for zone_id in [Medals.COLLECTOR_ZONE, "bosque"]:
		await _ctx.fade.call(1.0)
		var town := ZoneData.by_id(zone_id)
		_travel.switch_zone(town.id, town.town_entry)
		_ctx.play_map_music.call()
		await _ctx.fade.call(0.0)
		await _ctx.world.freeze(false)
		await _talk.talk_to_collector()
	print("Medallas: %d/%d · premios %d/%d" % [_ctx.state.medals.size(), Medals.MEDALS.size(),
		_ctx.state.medal_prizes, Medals.PRIZES.size()])
	quit_requested.emit()
