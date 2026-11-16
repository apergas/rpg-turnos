class_name CaravanFlow extends Node
## Node, a piece of Game: the caravan of the v2. Once the v1 is finished, its arrival in
## Villaclaro (arrival_scene()); the Jefe de caravana's two questions there, the farewell and
## the Caravana built under black (ask_departure()); and the choice of companion in the
## Caravana (choose_companion(): the Compañeros list, a shop at no cost). Gets the session
## and the ShopWindow in setup(); never stores Game or a World.

## The v2's Jefe de caravana: in Villaclaro once the caravan has come, then in the Caravana.
const CARAVAN_CHIEF := "Jefe de caravana"
const JOIN_QUESTION := "Cuando partamos, no volverás por aquí en mucho tiempo. ¿Te unes a la caravana?"
const LEAVE_QUESTION := "Villaclaro quedará muy lejos: no volverás al bosque, la mina ni el castillo hasta que termines el viaje. Las misiones que dejes a medias quedarán pendientes hasta entonces."

## Autoplay: the companion it takes at once (--autoplay-companion; Game sets it).
var autoplay_companion := AutoplayStarts.DEFAULT_COMPANION
## Autoplay: answers the Jefe's questions Sí / Partir and leaves (only the V2_STARTS; every
## other autoplay run stays in the v1). Game sets it.
var autoplay_leaves := false
## await play_scene.call(scene_id): a cutscene (StoryFlow).
var play_scene: Callable
## switch_zone.call(zone_id, entry_id): builds a map under black (ZoneTravel).
var switch_zone: Callable

var _ctx: SessionContext
var _shop: ShopWindow


func setup(ctx: SessionContext, shop: ShopWindow) -> void:
	_ctx = ctx
	_shop = shop


## The caravan's arrival in Villaclaro: "caravana_llega" once the v1 is finished, before
## leaving with it, until seen; "" otherwise.
static func arrival_scene(state: GameState, zone_id: String) -> String:
	if zone_id == "pradera" and state.can_meet_caravan() \
			and not state.story.has_seen("caravana_llega"):
		return "caravana_llega"
	return ""


## The Jefe de caravana in Villaclaro: two questions (focus on the answer that changes
## nothing), then the farewell, the v1 left behind and the Caravana built under black.
func ask_departure() -> void:
	if RunFlags.autoplay() and not autoplay_leaves:
		return  # the v1 runs never leave with the caravan
	if await _ctx.world.ask(JOIN_QUESTION, ["Sí", "No"], 1) != 0:
		return
	if await _ctx.world.ask(LEAVE_QUESTION, ["Partir", "Aún no"], 1) != 0:
		return
	await play_scene.call("caravana_parte")  # ends under black
	_ctx.state.leave_for_caravan()
	_ctx.state.story.v2_start = [_ctx.play_time, _ctx.state.battles]  # the v2's credits count from here
	switch_zone.call("caravana", "")
	_ctx.play_map_music.call()
	await _ctx.fade.call(0.0)
	await _ctx.world.freeze(false)
	_ctx.autosave.call(false)


## The Jefe de caravana's choice of companion: the Compañeros list (a shop at no cost).
## Closing it without choosing leaves it for the next talk; once one is chosen, the jungle's
## exit is there. Autoplay takes --autoplay-companion=<id> (Brena if none) at once.
func choose_companion() -> void:
	if RunFlags.autoplay():
		_ctx.state.ally_id = autoplay_companion
		print("Compañero: %s" % Allies.display_name(_ctx.state.ally_id))
	else:
		_ctx.world.freeze(true)
		await _shop.run(Shop.COMPANIONS_SHOP)
		await _ctx.world.freeze(false)
	if not Allies.is_companion(_ctx.state.ally_id):
		await _ctx.world.show_dialogue(CARAVAN_CHIEF, ["Piénsalo bien. Te espero aquí, que yo no tengo prisa."])
		return
	_ctx.state.world_flags[StoryState.COMPANION_FLAG] = true
	_ctx.world.set_world_flags(_ctx.state.world_flags)
	_ctx.refresh_status.call()
	var who := Allies.display_name(_ctx.state.ally_id)
	await _ctx.world.show_dialogue(CARAVAN_CHIEF, ["%s irá contigo. La jungla está al norte." % who])
	_ctx.autosave.call(false)

