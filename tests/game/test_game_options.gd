extends GutTest
## GameOptions: what an options file brings back (volumes kept in range, what an older file lacks
## keeps its default) and the options through the file and back. No file is written here.

const Fx := preload("res://tests/fixtures.gd")


func test_volumes_out_of_range_are_brought_back() -> void:
	var options := GameOptions.from_dict({"music": 5.0, "sfx": -1.0})
	assert_eq(options.music_volume, 1.0)
	assert_eq(options.sfx_volume, 0.0)


func test_what_an_older_file_lacks_keeps_its_default() -> void:
	assert_eq_deep(GameOptions.from_dict({}).to_dict(), GameOptions.new().to_dict())


func test_the_options_go_to_the_file_and_back() -> void:
	var options := GameOptions.new()
	options.large_text = true
	options.high_contrast = true
	options.music_volume = 0.25
	var back := GameOptions.from_dict(Fx.round_trip(options.to_dict()))
	assert_eq_deep(back.to_dict(), options.to_dict())
