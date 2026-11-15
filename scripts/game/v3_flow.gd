class_name V3Flow extends Node
## Node, a piece of Game: the v3 (Brumaclara, 3.0.0). The first time the hero stands in
## Brumaclara (through the Caravana's portal) the part 3 begins: on_zone_switched() sets its
## flag and the start of its numbers (story.v3_start) before the trip's autosave, so that save
## is already one of the part 3 (Brumaclara is only valid there) with the level cap at 50. The
## arrival cutscene follows as the village's first-visit scene (StoryFlow). The later versions
## bring the visit to Villaclaro and the endings here. Gets the session in setup(); never stores
## Game or a World.

var _ctx: SessionContext


func setup(ctx: SessionContext) -> void:
	_ctx = ctx


## ZoneTravel.zone_switched: Brumaclara for the first time starts the v3.
func on_zone_switched(zone_id: String) -> void:
	if zone_id != BrumaclaraLook.ZONE or _ctx.state.has_flag(StoryState.V3_FLAG):
		return
	_ctx.state.world_flags[StoryState.V3_FLAG] = true
	_ctx.state.story.v3_start = [_ctx.play_time, _ctx.state.battles]
	_ctx.world.set_world_flags(_ctx.state.world_flags)
	_ctx.refresh_status.call()  # the level cap and the goal of the part 3
