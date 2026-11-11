class_name CampLook extends RefCounted
## The caravan's camp (the Caravana) dressed for the land it is camped next to (2.4.0): the
## same layout (tents, figures, exits, entries, wells, the campfire, the autoplay route), the
## look of that land: its ground, hills, sky, light and fog, its grass, trees and Kenney
## decoration, its particles and its ambient sound (the music stays the caravan's). Pure:
## dressed() returns a copy of the zone; Game builds the Caravana from it.

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
		"tree_models": ["palm_A", "palm_B"], "clump_model": "palms_clump",
		"tree_scale": Vector2(0.95, 1.08), "tree_tries": 260, "bush_tries": 80,
		"decor_scatter": {"fern": 40, "leafy": 24, "mushrooms_red": 6}},
	2: {"from": "desierto", "ground": "ground_color", "has_grass": false,
		"tree_models": ["palm_A", "palm_B"], "clump_model": "palms_clump",
		"tree_scale": Vector2(0.95, 1.08), "tree_tries": 40, "bush_tries": 0,
		"decor_scatter": {"cactus": 10, "cactus_tall": 5, "scrub": 14}},
	3: {"from": "montana_1", "ground": "floor_color", "has_grass": false, "tree_tries": 0,
		"bush_tries": 0,
		"decor_scatter": {"pine": 14, "pine_small": 10, "snow_stones": 10, "rock_tall": 3}},
	4: {"from": "ciudad_1", "ground": "floor_color", "has_grass": false, "tree_tries": 0,
		"bush_tries": 0,
		"decor_scatter": {"stump_tall": 8, "city_block": 4, "city_column_broken": 3,
			"rubble": 8}},
	5: {"from": "ciudad_1", "ground": "floor_color", "has_grass": false, "tree_tries": 0,
		"bush_tries": 0, "calm": true,
		"decor_scatter": {"stump_tall": 8, "city_block": 4, "city_column_broken": 3,
			"rubble": 8}},
}
## The camp by the calmed portal: a softer, clearer sky than the city's, no ash.
const CALM := {"sky_top": Color(0.42, 0.36, 0.48), "haze": Color(0.78, 0.6, 0.55),
	"fog_density": 0.006, "sun_energy": 0.8, "particles": ""}


## A copy of the Caravana dressed for tramo (GameState.tramo()); zone itself for a tramo
## with no look (0: never in the camp).
static func dressed(zone: ZoneData, tramo: int) -> ZoneData:
	if not LOOKS.has(tramo):
		return zone
	var look: Dictionary = LOOKS[tramo]
	var land := ZoneData.by_id(look.from)
	var camp := zone.duplicate() as ZoneData
	camp.look_key = "tramo%d" % tramo
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
	if look.has("tree_models"):
		# A fresh array: duplicate() is shallow, so assign() on the copy's would change the
		# cached Caravana's own.
		var models: Array[String] = []
		models.assign(look.tree_models)
		camp.tree_models = models
	if look.get("calm", false):
		for field: String in CALM:
			camp.set(field, CALM[field])
	return camp
