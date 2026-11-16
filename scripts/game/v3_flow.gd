class_name V3Flow extends Node
## Node, a piece of Game: the v3 (Brumaclara, 3.0.0). The first time the hero stands in
## Brumaclara (through the Caravana's portal) the part 3 begins: on_zone_switched() sets its
## flag and the start of its numbers (story.v3_start) before the trip's autosave, so that save
## is already one of the part 3 (Brumaclara is only valid there) with the level cap at 60. The
## arrival cutscene follows as the village's first-visit scene (StoryFlow), and so does the
## Abuela Rosa's in Villaclaro (arrival_scene(), 3.2.0). The v3's ending is StoryFlow's
## (finish_v3(), 3.3.0). Gets the session in setup(); never stores Game or a World.

var _ctx: SessionContext


func setup(ctx: SessionContext) -> void:
	_ctx = ctx


## The village scene of Villaclaro in the part 3 (StoryFlow.check_village_scene(), like
## CaravanFlow.arrival_scene() in the v1): StoryState.AMULET_SCENE the first time the hero
## stands there with the Coloso beaten, "" otherwise.
static func arrival_scene(state: GameState, zone_id: String) -> String:
	if zone_id == VillaclaroLook.ZONE and state.part() == 3 \
			and state.has_flag(StoryState.V3_BOSSES[1]) \
			and not state.story.has_seen(StoryState.AMULET_SCENE):
		return StoryState.AMULET_SCENE
	return ""


## ZoneTravel.zone_switched: Brumaclara for the first time starts the v3.
func on_zone_switched(zone_id: String) -> void:
	if zone_id != BrumaclaraLook.ZONE or _ctx.state.has_flag(StoryState.V3_FLAG):
		return
	_ctx.state.world_flags[StoryState.V3_FLAG] = true
	_ctx.state.story.v3_start = [_ctx.play_time, _ctx.state.battles]
	_ctx.world.set_world_flags(_ctx.state.world_flags)
	_ctx.refresh_status.call()  # the level cap and the goal of the part 3
