class_name BrumaclaraLook extends RefCounted
## Brumaclara dressed for the v3's etapa (3.0.0), as CampLook dresses the Caravana for its tramo:
## the same layout (houses, figures, exits, wells, the lighthouse), with what comes back to the
## village with each boss beaten: light in the lighthouse and in the windows (BrumaclaraStage
## draws them), the forge's fire, the market open, a lighter fog... data/zones/brumaclara.tres is
## the etapa 1, all dark. Pure: dressed() returns a copy of the zone; ZoneTravel builds Brumaclara
## from it. The figures that come back (the Curandera...) are the zone's own, by their needs flags.
## Once the v3 is over (StoryState.world_open(), 3.8.2) the Ciénaga, the Cuevas and the Ruinas
## open again, each through its own arch (OPEN_EXITS).

const ZONE := "brumaclara"
## etapa -> the fields that change from the .tres: the whole look of that etapa (an etapa with
## no entry looks like the last one before it). 2, the Garza beaten: the lighthouse lit, the
## inn and a few windows with light, a little less fog; 3, the Coloso beaten: the forge's fire
## and two more windows; 4, the Vigía beaten: the market open (its boards gone, pots out, a
## lamp on the stall) and a light in every house; 5, the Eco beaten: all of the etapa 4 and the
## square en fiesta (garlands with paper lanterns), a little less fog.
const LOOKS := {
	2: {"lighthouse_lit": true, "fog_density": 0.018,
		"window_lights": [[Vector3(8.95, 1.6, -6.2), -90.0], [Vector3(8.95, 1.6, -3.8), -90.0],
			[Vector3(-9.55, 1.5, -5.6), 90.0], [Vector3(8.6, 1.5, 11.2), 180.0]]},
	3: {"lighthouse_lit": true, "forge_lit": true, "fog_density": 0.016,
		"window_lights": [[Vector3(8.95, 1.6, -6.2), -90.0], [Vector3(8.95, 1.6, -3.8), -90.0],
			[Vector3(-9.55, 1.5, -5.6), 90.0], [Vector3(8.6, 1.5, 11.2), 180.0],
			[Vector3(-9.2, 1.5, 6.0), 90.0], [Vector3(9.55, 1.5, 6.6), -90.0]]},
	4: {"lighthouse_lit": true, "forge_lit": true, "fog_density": 0.014,
		"window_lights": [[Vector3(8.95, 1.6, -6.2), -90.0], [Vector3(8.95, 1.6, -3.8), -90.0],
			[Vector3(-9.55, 1.5, -5.6), 90.0], [Vector3(8.6, 1.5, 11.2), 180.0],
			[Vector3(-9.2, 1.5, 6.0), 90.0], [Vector3(9.55, 1.5, 6.6), -90.0],
			[Vector3(-8.3, 1.5, 11.55), 180.0], [Vector3(-9.55, 1.5, -4.2), 90.0],
			[Vector3(-7.0, 2.0, -11.7), 0.0]],
		"decor": [[Vector3(-10.4, 0, -8.4), 20.0, "pot"], [Vector3(-4.6, 0, -8.0), -30.0, "pot"],
			[Vector3(-13.5, 0, 1), 30.0, "log_stack"]]},
	5: {"lighthouse_lit": true, "forge_lit": true, "fog_density": 0.012,
		"window_lights": [[Vector3(8.95, 1.6, -6.2), -90.0], [Vector3(8.95, 1.6, -3.8), -90.0],
			[Vector3(-9.55, 1.5, -5.6), 90.0], [Vector3(8.6, 1.5, 11.2), 180.0],
			[Vector3(-9.2, 1.5, 6.0), 90.0], [Vector3(9.55, 1.5, 6.6), -90.0],
			[Vector3(-8.3, 1.5, 11.55), 180.0], [Vector3(-9.55, 1.5, -4.2), 90.0],
			[Vector3(-7.0, 2.0, -11.7), 0.0]],
		"decor": [[Vector3(-10.4, 0, -8.4), 20.0, "pot"], [Vector3(-4.6, 0, -8.0), -30.0, "pot"],
			[Vector3(-13.5, 0, 1), 30.0, "log_stack"]],
		"garlands": [[Vector3(-9.4, 3.2, -4.2), Vector3(9.4, 3.2, -4.2)],
			[Vector3(-9.4, 3.2, 5.6), Vector3(9.4, 3.2, 5.6)],
			[Vector3(-6.6, 3.0, 11.2), Vector3(6.6, 3.0, 11.2)]]},
}
## The etapa of the epilogue and what each ending adds to it: Albor freed (StoryState.ALBOR_FREED),
## a lighter sky, a warmer light and the sun peeking from behind the black one; the Eco beaten,
## Albor's statue by the well of life, where Albor stands in the other ending.
const ENDING_ETAPA := 5
const FREED := {"sun_peeks": true, "sky_top": Color(0.36, 0.3, 0.52),
	"haze": Color(0.72, 0.68, 0.78), "fog_density": 0.009, "sun_color": Color(1.0, 0.88, 0.7),
	"sun_energy": 0.6}
const BEATEN := {"statue_pos": Vector3(-3.5, 0, -2.5), "statue_yaw": 180.0}
## Brumaclara once the v3 is over (open): the Ciénaga and the Ruinas open again in the west and
## the Cuevas in the east, each through its own arch (the Fuente keeps the north road, the portal
## the south), with its entry in front of it for the way back. ZoneData.reopen_exits() applies
## them.
const OPEN_EXITS := {
	"cienaga": {"pos": Vector3(-19.5, 0, -10), "yaw": 90.0},
	"cuevas": {"pos": Vector3(19.5, 0, -10), "yaw": -90.0},
	"ruinas": {"pos": Vector3(-19.5, 0, 10), "yaw": 90.0},
}
const OPEN_ENTRIES := {
	"cienaga": [Vector3(-16, 0, -10), -90.0],
	"cuevas": [Vector3(16, 0, -10), 90.0],
	"ruinas": [Vector3(-16, 0, 10), -90.0],
}


## A copy of Brumaclara dressed for etapa (GameState.etapa()) and, in the epilogue, for its
## ending (freed: StoryState.ALBOR_FREED set) and open (StoryState.world_open(): OPEN_EXITS);
## zone itself up to the etapa 1.
static func dressed(zone: ZoneData, etapa: int, freed := false, open := false) -> ZoneData:
	var step := 0
	for e: int in LOOKS:
		if e <= etapa:
			step = maxi(step, e)
	if step == 0:
		return zone
	var town := zone.duplicate() as ZoneData
	town.look_key = "etapa%d" % step
	var look: Dictionary = LOOKS[step]
	for field: String in look:
		var value: Variant = look[field]
		# A fresh array: duplicate() is shallow, so the cached zone's own would change.
		town.set(field, (value as Array).duplicate(true) if value is Array else value)
	if step == ENDING_ETAPA:
		var ending: Dictionary = FREED if freed else BEATEN
		town.look_key += "_libre" if freed else "_estatua"
		for field: String in ending:
			town.set(field, ending[field])
	if open:
		town.reopen_exits(OPEN_EXITS, OPEN_ENTRIES)
	return town
