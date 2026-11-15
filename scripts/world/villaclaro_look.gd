class_name VillaclaroLook extends RefCounted
## Villaclaro's meadow dressed for the part of the game (3.2.0), as CampLook dresses the
## Caravana: in the part 3 (the visit for the Amuleto del Alba) the Niebla that escapes through
## the portal is back on its roads (mist drifting at the hero's feet, a thicker and greyer haze,
## a duller sky) and the village is not the last one visited (no town entry: the Ala de viaje and
## a defeat still lead to the last village visited: the Caravana or Brumaclara). Its exits
## (the north road to the Caravana instead of the forest's) come with their needs / gone flags. Pure: dressed() returns a copy of the zone;
## ZoneTravel builds the meadow from it.

const ZONE := "pradera"
## The fields the part 3 changes.
const V3_MIST := {"sky_top": Color(0.4, 0.48, 0.7), "haze": Color(0.66, 0.68, 0.76),
	"fog_density": 0.018, "particles": ZoneParticles.BRUMA, "town_entry": ""}


## A copy of the meadow dressed for part (GameState.part()); zone itself in the v1 (the v2
## never comes back here).
static func dressed(zone: ZoneData, part: int) -> ZoneData:
	if part != 3:
		return zone
	var meadow := zone.duplicate() as ZoneData
	meadow.look_key = "v3"
	for field: String in V3_MIST:
		meadow.set(field, V3_MIST[field])
	return meadow
