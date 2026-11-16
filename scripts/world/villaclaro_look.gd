class_name VillaclaroLook extends RefCounted
## Villaclaro's meadow dressed for the part of the game (3.2.0), as CampLook dresses the
## Caravana: in the part 3 (the visit for the Amuleto del Alba) the Niebla that escapes through
## the portal is back on its roads (mist drifting at the hero's feet, a thicker and greyer haze,
## a duller sky) and the village is not the last one visited (no town entry: the Ala de viaje and
## a defeat still lead to the last village visited: the Caravana or Brumaclara). Its exits
## (the north road to the Caravana instead of the forest's) come with their needs / gone flags.
## Once the v3 is over (StoryState.world_open(), 3.8.2) the mist has gone, as from the Caravana,
## the forest's road is open again in the north, as in the v1, and the Caravana's comes in from
## the south, at the end of the path (OPEN_EXITS). Pure: dressed() returns a copy of the zone;
## ZoneTravel builds the meadow from it.

const ZONE := "pradera"
## The fields the part 3 changes.
const V3_MIST := {"sky_top": Color(0.4, 0.48, 0.7), "haze": Color(0.66, 0.68, 0.76),
	"fog_density": 0.018, "particles": ZoneParticles.BRUMA, "town_entry": ""}
## The fields the part 3 changes once the v3 is over (open): only the town entry, as before it.
const OPEN := {"town_entry": ""}
## Once the v3 is over: the Caravana's road at the south end of the path, with its entry in
## front of it (the camp's road to Villaclaro leads there: CampLook.OPEN_EXITS); the forest's
## keeps the north. ZoneData.reopen_exits() applies them.
const OPEN_EXITS := {"caravana": {"pos": Vector3(0, 0, 28.6), "yaw": 180.0}}
const OPEN_ENTRIES := {"caravana": [Vector3(0, 0, 25.5), 0.0]}


## A copy of the meadow dressed for part (GameState.part()) and, once the v3 is over, open
## (StoryState.world_open()); zone itself in the v1 (the v2 never comes back here).
static func dressed(zone: ZoneData, part: int, open := false) -> ZoneData:
	if part != 3:
		return zone
	var meadow := zone.duplicate() as ZoneData
	meadow.look_key = "v3"
	var fields: Dictionary = OPEN if open else V3_MIST
	for field: String in fields:
		meadow.set(field, fields[field])
	if open:
		meadow.reopen_exits(OPEN_EXITS, OPEN_ENTRIES)
	return meadow
