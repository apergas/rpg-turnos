extends GutTest
## EncounterMeter: a zone's moving groups keep away from a hero LEVEL_GAP levels past its
## exit_level.


func test_the_groups_keep_away_four_levels_past_the_exit_level() -> void:
	assert_false(EncounterMeter.is_shy(13, 10))
	assert_true(EncounterMeter.is_shy(14, 10))
	assert_eq(EncounterMeter.level_rate(14, 10), EncounterMeter.CALM_RATE)
	assert_eq(EncounterMeter.level_rate(13, 10), 1.0)


func test_a_zone_without_an_exit_level_never_calms() -> void:
	assert_false(EncounterMeter.is_shy(60, 0))
	assert_eq(EncounterMeter.level_rate(60, 0), 1.0)
