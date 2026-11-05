class_name Cutscene extends Resource
## A short scripted scene (data/cutscenes/<id>.tres), played by CutscenePlayer. Each
## step is an Array whose first element names it:
##   ["say", speaker, [lines...]]       a dialogue ("" speaker: the narrator)
##   ["move", who, Vector3]             walks who there (straight line, walking animation)
##   ["move", who, Vector3, true]       the same, without waiting for it to arrive
##   ["approach", who, other, metres]   walks who up to that far from another figure
##   ["face", who, other or Vector3]    turns who toward another figure or a point
##   ["wait", seconds]
##   ["camera_to", Vector3, distance]   the camera glides to look at a point
##   ["camera_back"]                    the camera follows the hero again
##   ["fade_out"] / ["fade_in"]         to black and back
##   ["music", track id]                MusicLibrary id
##   ["sfx", sound id]                  SfxLibrary id
##   ["flag", name]                     sets a world flag (GameState.world_flags)
##   ["travel", zone id, entry id]      builds another map under black (Game)
##   ["cheer", [who...]]                the Cheer animation of several figures at once
## who / speaker: "hero" (the player) or a figure's ZoneData.npcs "name" on this map.
## Lines and speakers may hold StoryState.NAME_TAG.

const HERO := "hero"

@export var id := ""
@export var steps: Array = []
