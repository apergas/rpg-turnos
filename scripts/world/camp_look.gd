class_name CampLook extends RefCounted
## The caravan's camp (the Caravana) dressed for the land it is camped next to (2.4.0): the
## same layout (tents, figures, exits, entries, wells, the campfire, the autoplay route), the
## look of that land: its ground, hills, sky, light and fog, its grass, trees and Kenney
## decoration, its particles and its ambient sound (the music stays the caravan's), and its
## Armero dressed like the smiths of that land (ARMORERS, 3.10.0); by the calmed portal, the
## v3's mist while Brumaclara needs help. Once the v3 is over
## (StoryState.world_open(), 3.8.2) the four lands open again round the camp, each through its
## own arch (OPEN_EXITS). Pure: dressed() returns a copy of the zone; ZoneTravel builds the
## Caravana from it.

const ZONE := "caravana"
## Copied from the land's own zone (LOOKS "from").
const COPIED := ["hill_color", "sky_top", "haze", "fog_density", "sun_color", "sun_energy",
	"decor_green", "particles", "ambient"]
## tramo -> the land ("from"), which of its fields is the camp's ground ("ground":
## ground_color on an open map, floor_color on a floor of cells), and the camp's own trees,
## grass and scattered decoration (kept to the camp's edges by tree_rise_inset and by
## WorldStage.decor_blocker(): never on a tent, a figure, a well, an exit or the route).
## "calm": the v2 finished, the portal calm (CALM over the copied look).
const LOOKS := {
	1: {"from": "jungla", "ground": "ground_color", "has_grass": true, "grass": true,
		"decor": [[Vector3(-2.5, 0, 11.5), 20.0, "leafy"], [Vector3(0.5, 0, 12), 0.0, "fern"],
			[Vector3(3, 0, 11.5), 80.0, "leafy"], [Vector3(8.5, 0, 6.5), 40.0, "leafy"],
			[Vector3(-9, 0, 7), 150.0, "leafy"], [Vector3(-8, 0, 2.2), 0.0, "fern"],
			[Vector3(-1.5, 0, -3), 10.0, "mushrooms_red"]],
		"tree_models": ["palm_A", "palm_B"], "clump_model": "palms_clump",
		"tree_scale": Vector2(0.95, 1.08), "tree_tries": 260, "bush_tries": 80,
		"decor_scatter": {"fern": 40, "leafy": 24, "mushrooms_red": 6}},
	2: {"from": "desierto", "ground": "ground_color", "has_grass": false,
		"decor": [[Vector3(-2.5, 0, 11.5), 0.0, "cactus_tall"], [Vector3(3, 0, 11.5), 0.0, "cactus"],
			[Vector3(0.5, 0, 12), 60.0, "scrub"], [Vector3(8.5, 0, 6.5), 0.0, "cactus_tall"],
			[Vector3(-9, 0, 7), 0.0, "cactus"], [Vector3(-8, 0, 2.2), 30.0, "cactus"],
			[Vector3(-1.5, 0, -3), 200.0, "scrub"]],
		"tree_models": ["palm_A", "palm_B"], "clump_model": "palms_clump",
		"tree_scale": Vector2(0.95, 1.08), "tree_tries": 40, "bush_tries": 0,
		"decor_scatter": {"cactus": 10, "cactus_tall": 5, "scrub": 14}},
	3: {"from": "montana_1", "ground": "floor_color", "has_grass": false, "tree_tries": 0,
		"decor": [[Vector3(-2.5, 0, 11.5), 0.0, "pine"], [Vector3(3, 0, 11.5), 0.0, "pine_small"],
			[Vector3(0.5, 0, 12), 60.0, "snow_stones"], [Vector3(8.5, 0, 6.5), 0.0, "pine"],
			[Vector3(-9, 0, 7), 0.0, "pine_small"], [Vector3(-8, 0, 2.2), 30.0, "rock_tall"],
			[Vector3(-1.5, 0, -3), 200.0, "snow_stones"]],
		"bush_tries": 0,
		"decor_scatter": {"pine": 14, "pine_small": 10, "snow_stones": 10, "rock_tall": 3}},
	4: {"from": "ciudad_1", "ground": "floor_color", "has_grass": false, "tree_tries": 0,
		"decor": [[Vector3(-2.5, 0, 11.5), 0.0, "city_column_broken"], [Vector3(3, 0, 11.5), 40.0, "city_block"],
			[Vector3(0.5, 0, 12), 60.0, "rubble"], [Vector3(8.5, 0, 6.5), 90.0, "city_column"],
			[Vector3(-9, 0, 7), 0.0, "city_block"], [Vector3(-8, 0, 2.2), 30.0, "city_column_broken"],
			[Vector3(-1.5, 0, -3), 200.0, "rubble"]],
		"bush_tries": 0,
		"decor_scatter": {"stump_tall": 8, "city_block": 4, "city_column_broken": 3,
			"rubble": 8}},
	5: {"from": "ciudad_1", "ground": "floor_color", "has_grass": false, "tree_tries": 0,
		"decor": [[Vector3(-2.5, 0, 11.5), 0.0, "city_column_broken"], [Vector3(3, 0, 11.5), 40.0, "city_block"],
			[Vector3(0.5, 0, 12), 60.0, "rubble"], [Vector3(8.5, 0, 6.5), 90.0, "city_column"],
			[Vector3(-9, 0, 7), 0.0, "city_block"], [Vector3(-8, 0, 2.2), 30.0, "city_column_broken"],
			[Vector3(-1.5, 0, -3), 200.0, "rubble"]],
		"bush_tries": 0, "calm": true,
		"decor_scatter": {"stump_tall": 8, "city_block": 4, "city_column_broken": 3,
			"rubble": 8}},
}
## The camp by the calmed portal: a softer, clearer sky than the city's, no ash.
const CALM := {"sky_top": Color(0.42, 0.36, 0.48), "haze": Color(0.78, 0.6, 0.55),
	"fog_density": 0.006, "sun_energy": 0.8, "particles": ""}
## The camp by the calmed portal while the v3 is on (Brumaclara's etapas 1 to 4; 3.0.0): the
## mist that comes through the portal, knee-deep, and a greyer haze. The Eco de Albor beaten,
## the calm look comes back.
const V3_MIST := {"haze": Color(0.62, 0.62, 0.72), "fog_density": 0.02,
	"particles": ZoneParticles.BRUMA}
## The camp once the v3 is over (open): the four lands open again, each through its own arch
## between the tents (the portal keeps the north, Villaclaro the east), with its entry in front
## of it for the way back. The road to Villaclaro now ends at the meadow's south
## (VillaclaroLook.OPEN_ENTRIES). ZoneData.reopen_exits() applies them.
const OPEN_EXITS := {
	"jungla": {"pos": Vector3(-14, 0, -8), "yaw": 60.0},
	"desierto": {"pos": Vector3(-14, 0, 8), "yaw": 120.0},
	"montana": {"pos": Vector3(14, 0, 8), "yaw": -120.0},
	"ciudad": {"pos": Vector3(0, 0, 17), "yaw": 180.0},
	"villaclaro": {"entry": "caravana"},
}
const OPEN_ENTRIES := {
	"jungla": [Vector3(-11.4, 0, -6.5), -120.0],
	"desierto": [Vector3(-11.4, 0, 6.5), -60.0],
	"montana": [Vector3(11.4, 0, 6.5), 60.0],
	"ciudad": [Vector3(0, 0, 14), 0.0],
}
## The calm camp's hand-placed pieces that stay once it is open (LOOKS[5]'s others would stand
## on the new roads, in front of the desert's, the mountain's and the city's arches).
const OPEN_DECOR := [[Vector3(-8, 0, 2.2), 30.0, "city_column_broken"],
	[Vector3(-1.5, 0, -3), 200.0, "rubble"]]
## The Armero for each tramo (3.10.0, M-124): the ActorLooks.Look name of the smith of that land
## (ActorLooksArmory): the jungle's, the desert's, the mountain's, then the city's, also by the
## calmed portal and in the v3. data/zones/caravana.tres holds the tramo 1's.
const ARMORERS := {1: "ARMORER_JUNGLE", 2: "ARMORER_DESERT", 3: "ARMORER_MOUNTAIN",
	4: "ARMORER_CITY", 5: "ARMORER_CITY"}


## A copy of the Caravana dressed for tramo (GameState.tramo()), by the calmed portal for the
## v3's etapa (GameState.etapa()) and, once the v3 is over, open (StoryState.world_open():
## OPEN_EXITS, OPEN_DECOR); zone itself for a tramo with no look (0: never in the camp).
static func dressed(zone: ZoneData, tramo: int, etapa := 0, open := false) -> ZoneData:
	if not LOOKS.has(tramo):
		return zone
	var look: Dictionary = LOOKS[tramo]
	var land := ZoneData.by_id(look.from)
	var camp := zone.duplicate() as ZoneData
	camp.look_key = "tramo%d" % tramo
	_dress_armorer(camp, ARMORERS[tramo])
	for field: String in COPIED:
		camp.set(field, land.get(field))
	camp.ground_color = land.get(look.ground)
	camp.has_grass = look.has_grass
	if look.get("grass", false):
		camp.grass_tips = land.grass_tips
	for field: String in ["clump_model", "tree_scale", "tree_tries", "bush_tries"]:
		if look.has(field):
			camp.set(field, look[field])
	if look.has("decor_scatter"):
		camp.decor_scatter = (look.decor_scatter as Dictionary).duplicate()
	if look.has("decor"):
		# The camp's own pieces after the Caravana's (campfire, log stack), by hand.
		var placed: Array = zone.decor.duplicate()
		placed.append_array(look.decor)
		camp.decor = placed
	if look.has("tree_models"):
		# A fresh array: duplicate() is shallow, so assign() on the copy's would change the
		# cached Caravana's own.
		var models: Array[String] = []
		models.assign(look.tree_models)
		camp.tree_models = models
	if look.get("calm", false):
		for field: String in CALM:
			camp.set(field, CALM[field])
		if etapa >= 1 and etapa <= 4:
			camp.look_key += "_v3"
			for field: String in V3_MIST:
				camp.set(field, V3_MIST[field])
	if open:
		var kept: Array = zone.decor.duplicate()
		kept.append_array(OPEN_DECOR)
		camp.decor = kept
		camp.reopen_exits(OPEN_EXITS, OPEN_ENTRIES)
	return camp


## Gives the camp's "armory" figure look_name, on a fresh copy of the figures: duplicate() is
## shallow, so changing the copy's own would change the cached Caravana's.
static func _dress_armorer(camp: ZoneData, look_name: String) -> void:
	var figures: Array = []
	for npc: Dictionary in camp.npcs:
		var figure: Dictionary = npc.duplicate()
		if figure.get("kind", "") == "armory":
			figure.look = look_name
		figures.append(figure)
	camp.npcs = figures
