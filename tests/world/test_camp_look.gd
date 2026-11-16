extends GutTest
## CampLook: the Caravana dressed for each tramo, here its Armero (3.10.0, M-124), who wears the
## style of the land the camp is by, on a copy: the cached Caravana keeps its own figures.

## tramo -> the Armero's look (the spec): the jungle's, the desert's, the mountain's, then the
## city's, also by the calmed portal and in the v3.
const EXPECTED := {1: "ARMORER_JUNGLE", 2: "ARMORER_DESERT", 3: "ARMORER_MOUNTAIN",
	4: "ARMORER_CITY", 5: "ARMORER_CITY"}


func _armorer(zone: ZoneData) -> Dictionary:
	for npc: Dictionary in zone.npcs:
		if npc.get("kind", "") == "armory":
			return npc
	return {}


func test_the_armero_wears_the_style_of_each_land() -> void:
	var zone := ZoneData.by_id(CampLook.ZONE)
	for tramo: int in CampLook.LOOKS:
		assert_eq(_armorer(CampLook.dressed(zone, tramo)).get("look", ""),
			EXPECTED.get(tramo, "?"), "tramo %d" % tramo)
	assert_eq(_armorer(CampLook.dressed(zone, 5, 2)).get("look", ""), "ARMORER_CITY",
		"by the calmed portal in the v3")
	assert_eq(_armorer(CampLook.dressed(zone, 5, 5, true)).get("look", ""), "ARMORER_CITY",
		"once the world is open")


func test_every_tramo_has_an_armero_look_that_exists() -> void:
	for tramo: int in CampLook.LOOKS:
		assert_true(CampLook.ARMORERS.has(tramo), "tramo %d" % tramo)
		assert_true(ActorLooks.Look.has(CampLook.ARMORERS.get(tramo, "")), "tramo %d" % tramo)


func test_dressing_the_camp_leaves_the_cached_caravana_as_it_was() -> void:
	var zone := ZoneData.by_id(CampLook.ZONE)
	var before := str(zone.npcs)
	for tramo: int in CampLook.LOOKS:
		CampLook.dressed(zone, tramo)
	assert_eq(str(zone.npcs), before)
	assert_eq(_armorer(zone).get("look", ""), "ARMORER_JUNGLE")
	var camp := CampLook.dressed(zone, 3)
	assert_eq(camp.npcs.size(), zone.npcs.size())
	for i in zone.npcs.size():
		if zone.npcs[i].get("kind", "") != "armory":
			assert_eq_deep(camp.npcs[i], zone.npcs[i])
