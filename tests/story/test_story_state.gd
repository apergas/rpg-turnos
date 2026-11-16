extends GutTest
## StoryState: the part, the tramo and the etapa from the flags (never saved), the chapter, what
## Orvalla adds, the hero's name, the scenes played once, older saves' scenes and the story
## through the save.

const Fx := preload("res://tests/fixtures.gd")


func test_the_part_follows_the_caravan_and_brumaclara_flags() -> void:
	assert_eq(StoryState.part({}), 1)
	assert_eq(StoryState.part(Fx.PART_2), 2)
	assert_eq(StoryState.part(Fx.PART_3), 3)


func test_the_tramo_counts_the_caravans_bosses_in_order() -> void:
	assert_eq(StoryState.tramo({}), 0)
	var flags := Fx.PART_2.duplicate()
	assert_eq(StoryState.tramo(flags), 1)
	flags["gusano_dunas"] = true
	assert_eq(StoryState.tramo(flags), 1, "out of order: the Jaguar comes first")
	flags["jaguar_sombrio"] = true
	assert_eq(StoryState.tramo(flags), 3)
	flags["grifo_cumbre"] = true
	flags["guardian_ciudad"] = true
	assert_eq(StoryState.tramo(flags), 4, "never past 4 before the Devorador")
	flags["devorador_portal"] = true
	assert_eq(StoryState.tramo(flags), 5)


func test_the_etapa_counts_brumaclaras_bosses() -> void:
	assert_eq(StoryState.etapa(Fx.PART_2), 0)
	var flags := Fx.PART_3.duplicate()
	assert_eq(StoryState.etapa(flags), 1)
	for boss in StoryState.V3_BOSSES:
		flags[boss] = true
	assert_eq(StoryState.etapa(flags), 4)
	flags[StoryState.V3_FINAL_BOSS] = true
	assert_eq(StoryState.etapa(flags), 5, "the epilogue")


func test_the_chapter_follows_the_scenes_and_the_bosses() -> void:
	var story := StoryState.new()
	assert_eq(story.chapter({}), StoryState.Chapter.PROLOGUE)
	story.mark_seen("prologo")
	assert_eq(story.chapter({}), StoryState.Chapter.MEADOW)
	assert_eq(story.chapter({"rey_slime": true, "bruja": true}), StoryState.Chapter.MINE)
	assert_eq(story.chapter(Fx.PART_2), StoryState.Chapter.CARAVAN)
	assert_eq(story.chapter(Fx.PART_3), StoryState.Chapter.BRUMACLARA)
	var end := Fx.PART_3.duplicate()
	end[StoryState.V3_FINAL_BOSS] = true
	assert_eq(story.chapter(end), StoryState.Chapter.V3_END)


func test_orvalla_points_at_the_v3s_next_step() -> void:
	var flags := Fx.PART_3.duplicate()
	assert_eq(StoryState.keeper_line(flags), "")
	flags["garza_legamo"] = true
	flags["coloso_cuarzo"] = true
	assert_eq(StoryState.keeper_line(flags), StoryState.V3_AMULET_LINE)
	flags[StoryState.AMULET_FLAG] = true
	assert_eq(StoryState.keeper_line(flags), StoryState.V3_RUINS_LINE)
	flags["vigia_bruma"] = true
	assert_eq(StoryState.keeper_line(flags), StoryState.V3_SOURCE_LINE)
	flags[StoryState.V3_FINAL_BOSS] = true
	assert_eq(StoryState.keeper_line(flags), "")


func test_a_typed_name_is_trimmed_cut_to_eight_and_never_empty() -> void:
	assert_eq(StoryState.clean_name("  Rocío  "), "Rocío")
	assert_eq(StoryState.clean_name("Maximiliano"), "Maximili")
	assert_eq(StoryState.clean_name("   "), StoryState.DEFAULT_NAME)
	assert_eq(StoryState.fill("Hola, {nombre}.", "Rocío"), "Hola, Rocío.")


func test_a_scene_plays_once() -> void:
	var story := StoryState.new()
	assert_eq(story.scene_after_boss("bruja"), "bruja")
	story.mark_seen("bruja")
	assert_eq(story.scene_after_boss("bruja"), "")
	assert_eq(story.scene_after_boss("slime"), "", "not a boss with a scene")
	assert_eq(story.scene_on_village("brumaclara"), "brumaclara_llega")


func test_an_older_save_gets_the_scenes_its_flags_left_behind() -> void:
	var story := StoryState.new()
	story.mark_seen_for_flags(Fx.PART_3)
	assert_true(story.finished)
	assert_true(story.finished_v2)
	assert_false(story.finished_v3)
	for id in ["prologo", "final", "castillo", "caravana_parte", "caravana_campamento", "cruce",
			"brumaclara_llega"]:
		assert_true(story.has_seen(id), id)


func test_the_story_goes_to_the_save_and_back() -> void:
	var story := StoryState.new()
	story.mark_seen("prologo")
	story.v2_start = [120.5, 30]
	var saved := Fx.round_trip(story.to_dict())
	(saved.seen as Array).append("escena_inventada")
	var copy := StoryState.new()
	copy.set_from(saved)
	assert_eq(copy.seen.size(), 1, "unknown scenes are dropped")
	assert_eq(copy.v2_start[0], 120.5)
	assert_true(copy.v2_start[1] is int)
	assert_eq(copy.v2_start[1], 30)
