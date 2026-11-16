extends GutTest
## ClosingLands (3.8.2, M-111): the seven lands that close behind their boss, found from the
## zones' data, and how they all open again once the v3 is over.

const Fx := preload("res://tests/fixtures.gd")
## Boss -> the zones of its land, sorted (the 3.8.2 spec).
const LANDS := {"jaguar_sombrio": ["jungla"], "gusano_dunas": ["desierto"],
	"grifo_cumbre": ["montana_1", "montana_2"], "devorador_portal": ["ciudad_1", "ciudad_2"],
	"garza_legamo": ["cienaga"], "coloso_cuarzo": ["cuevas_1", "cuevas_2"],
	"vigia_bruma": ["ruinas_1", "ruinas_2"]}
## The flags the v3's ending sets (StoryState.world_open()).
const V3_OVER := {"brumaclara": true, "albor_liberado": true}


func test_seven_lands_close_behind_their_boss() -> void:
	for boss: String in LANDS:
		var zones := ClosingLands.zones_of(boss)
		zones.sort()
		assert_eq(str(zones), str(LANDS[boss]), boss)


func test_no_land_closes_behind_the_v1s_bosses_the_guardian_or_the_ecos() -> void:
	for boss in ["rey_slime", "bruja", "golem_piedra", "senor_niebla", "guardian_ciudad",
			"eco_albor", "eco_niebla"]:
		assert_true(ClosingLands.zones_of(boss).is_empty(), boss)


func test_a_land_is_closed_once_its_boss_is_beaten() -> void:
	assert_false(ClosingLands.is_closed("jungla", Fx.PART_2))
	assert_true(ClosingLands.is_closed("jungla", {"jaguar_sombrio": true}))
	assert_false(ClosingLands.is_closed("caravana", {"jaguar_sombrio": true}),
		"the village never closes")


func test_every_land_opens_again_once_the_v3_is_over() -> void:
	for boss: String in LANDS:
		var flags := {boss: true}
		for zone in LANDS[boss]:
			assert_true(ClosingLands.is_closed(zone, flags), "%s closed behind %s" % [zone, boss])
			flags.merge(V3_OVER)
			assert_false(ClosingLands.is_closed(zone, flags), "%s open again" % zone)
			flags.erase("albor_liberado")
	assert_true(ClosingLands.is_closed("jungla", {"jaguar_sombrio": true, "brumaclara": true}),
		"the v3 under way is not the v3 over")
	assert_false(ClosingLands.is_closed("jungla",
		{"jaguar_sombrio": true, "brumaclara": true, "albor_vencido": true}), "either ending")
