class_name ZoneTravel extends Node
## Node, a piece of Game: the change of map. Builds the next zone's World (switch_zone(),
## which hands it to Game through world_replaced), walks through an open exit (on_exit()),
## flies to the last village with the Ala de viaje and opens its portal back
## (on_travel_requested()), takes that portal back once (on_portal()), sends a beaten hero to
## the village (go_to_town()) and puts the groups and the Slime de Metal back on the map
## (respawn_groups(), spawn_rare()). Gets the session in setup(); never stores Game or a
## World (the current map is SessionContext.world).

## A new map was built (zone and boss set, not in the tree yet): Game frees the old one,
## puts this one first in the tree, sets SessionContext.world, freezes it, gives it the
## audio and connects its signals, before anything else touches it.
signal world_replaced(world: World)
## switch_zone() is over (on autoplay it prints "Zona: ..." and starts its quiet clock over).
signal zone_switched(zone_id: String)
## After a trip, whether the hero stands inside the village (as World.village_changed).
signal village_checked(inside: bool)
## The return portal was taken (on autoplay the quiet clock starts over).
signal portal_taken

const WORLD_SCENE := preload("res://scenes/world/world.tscn")
const PORTAL_OPEN_NOTICE := "Vuelas %s. El portal te espera para volver."
const PORTAL_REPLACED_NOTICE := "Vuelas %s. El portal anterior se ha cerrado."
const PORTAL_BACK_NOTICE := "El portal te devuelve y se cierra tras de ti."

## await check_arrival_line.call(): the companion's line on reaching a land (StoryFlow).
var check_arrival_line: Callable
## check_village_scene.call(): the village's first-visit cutscene (StoryFlow).
var check_village_scene: Callable
## update_boss.call(): shows or hides the zone's boss (BattleFlow).
var update_boss: Callable

var _ctx: SessionContext
var _rng := RandomNumberGenerator.new()


func setup(ctx: SessionContext) -> void:
	_ctx = ctx
	_rng.randomize()


## Frees the current map and builds zone_id with the player at entry_id ("" for the
## zone's start entry). No fade: callers fade around it. The new map starts frozen
## (World.freeze()), so nothing on it can fire while Game is still busy fading in;
## every caller unfreezes it once the fade is over.
func switch_zone(zone_id: String, entry_id: String) -> void:
	var zone := ZoneData.by_id(zone_id)
	if zone_id == CampLook.ZONE:
		zone = CampLook.dressed(zone, _ctx.state.tramo())  # the land it camps by (2.4.0)
	elif zone_id == BrumaclaraLook.ZONE:
		zone = BrumaclaraLook.dressed(zone, _ctx.state.etapa())  # what each boss brings back (3.0.0)
	_ctx.state.zone_id = zone_id
	var world: World = WORLD_SCENE.instantiate()
	world.zone = zone
	world.boss_id = BattleRewards.boss_id(zone, _ctx.state)
	world_replaced.emit(world)
	_ctx.world.set_dry_wells(Wells.dry_ids(_ctx.state))
	if entry_id != "":
		_ctx.world.place_at_entry(entry_id)
	for id in _ctx.state.opened_chests:
		_ctx.world.set_chest_open(id, true, true)
	_ctx.world.set_explored(_ctx.state.explored_map(zone_id))
	_ctx.world.set_world_flags(_ctx.state.world_flags)
	show_portal()
	update_boss.call()
	spawn_rare()
	_ctx.refresh_status.call()
	MusicLibrary.build(zone.music)
	AmbientLibrary.prepare(zone.ambient)  # under black, like the music
	if _ctx.world.in_village():
		village_checked.emit(true)
	zone_switched.emit(zone_id)


## Puts the player at the town entry of the last village visited, switching zones if
## needed (no fade: the caller is already under black). The groups of the map come back
## either way.
func go_to_town() -> void:
	var town := ZoneData.by_id(_ctx.state.town_zone)
	if _ctx.state.town_zone != _ctx.state.zone_id:
		switch_zone(_ctx.state.town_zone, town.town_entry)
	else:
		_ctx.world.place_at_entry(town.town_entry)
		respawn_groups()
		village_checked.emit(_ctx.world.in_village())


## Every group of this map comes back (the map counts as built again: a defeat, the portal,
## a game loaded), clear of where the hero stands.
func respawn_groups() -> void:
	var avoid: Array[Vector3] = [_ctx.world.player_position()]
	_ctx.world.respawn_groups(avoid)
	spawn_rare()


## The zone's rare enemy on this map (the Slime de Metal on the mine floors): always while
## its quest is on, now and then once it is done (EncounterTable.rare_on_map()).
func spawn_rare() -> void:
	if _ctx.zone.rare_enemy == "" or _ctx.world.has_rare():
		return
	if EncounterTable.rare_on_map(_ctx.zone, _ctx.state.quests.wanted_enemies(),
			_ctx.state.quests.hunted_enemies(), _rng):
		_ctx.world.add_rare(_ctx.zone.rare_enemy)


## An open exit: fades to black, builds the next zone at the exit's entry, autosaves.
func on_exit(zone_id: String, entry_id: String) -> void:
	if _ctx.busy:
		return
	_ctx.set_busy.call(true)
	await _ctx.fade.call(1.0)
	switch_zone(zone_id, entry_id)
	_ctx.play_map_music.call()
	await _ctx.fade.call(0.0)
	await _ctx.world.freeze(false)
	await check_arrival_line.call()
	_ctx.autosave.call(false)
	_ctx.set_busy.call(false)
	check_village_scene.call()


## The Ala de viaje, used from the pause menu (it has already taken it): to the last
## village visited, with the portal back to this spot open there. The menu only opens when
## nothing is going on, so the spot is always a settled one.
func on_travel_requested() -> void:
	if _ctx.busy:
		_ctx.state.inventory.add(Inventory.WING)
		return
	_ctx.set_busy.call(true)
	# The pause menu has already unpaused the tree: without this the hero could still walk
	# into an encounter or an exit during the fade and leave the map stuck waiting.
	_ctx.world.freeze(true)
	var replaced := _ctx.state.open_portal(_ctx.world.player_position())
	await _ctx.fade.call(1.0)
	go_to_town()
	show_portal()
	_ctx.refresh_status.call()
	_ctx.play_map_music.call()
	await _ctx.fade.call(0.0)
	await _ctx.world.freeze(false)
	var place := to_place(_ctx.zone.village_name)
	_ctx.world.show_notice((PORTAL_REPLACED_NOTICE if replaced else PORTAL_OPEN_NOTICE) % place, "Viaje")
	_ctx.autosave.call(false)
	_ctx.set_busy.call(false)


## The hero used the return portal (or autoplay, once restocked): back to the spot the Ala
## was used at. It works once. The map stays frozen through the fade, like every other trip.
func on_portal() -> void:
	if _ctx.busy or not _ctx.state.has_portal():
		return
	_ctx.set_busy.call(true)
	portal_taken.emit()
	_ctx.world.freeze(true)
	await _ctx.fade.call(1.0)
	var zone_id := _ctx.state.portal_zone
	var pos := _ctx.state.portal_pos
	_ctx.state.close_portal()
	if zone_id != _ctx.zone.id:
		switch_zone(zone_id, "")
	else:
		show_portal()
	_ctx.world.place_player(pos)
	respawn_groups()
	village_checked.emit(_ctx.world.in_village())
	_ctx.refresh_status.call()
	update_boss.call()
	await _ctx.fade.call(0.0)
	await _ctx.world.freeze(false)
	_ctx.world.show_notice(PORTAL_BACK_NOTICE, "Viaje")
	_ctx.autosave.call(false)
	_ctx.set_busy.call(false)


## The portal stands in the village it was opened in and the mark on the spot it leads
## back to, whatever map is on now.
func show_portal() -> void:
	_ctx.world.set_portal(_ctx.state.portal_town == _ctx.zone.id)
	_ctx.world.set_return_mark(_ctx.state.has_portal() and _ctx.state.portal_zone == _ctx.zone.id,
		_ctx.state.portal_pos)


## "a Villaclaro", "a la aldea del bosque", "al refugio de la mina".
static func to_place(place: String) -> String:
	return "al " + place.substr(3) if place.begins_with("el ") else "a " + place
