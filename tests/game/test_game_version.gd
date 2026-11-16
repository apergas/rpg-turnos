extends GutTest
## GameVersion: how a published version compares with this build's (WebUpdate's «Buscar
## actualizaciones»), number by number.


func test_a_greater_number_is_newer_number_by_number() -> void:
	assert_eq(GameVersion.check("3.10.0", "3.9.2"), GameVersion.Check.NEWER)
	assert_eq(GameVersion.check("4.0.0", "3.99.99"), GameVersion.Check.NEWER)
	assert_eq(GameVersion.check("3.9.1", "3.9.0"), GameVersion.Check.NEWER)


func test_the_same_or_an_older_version_is_the_latest() -> void:
	assert_eq(GameVersion.check("3.9.0", "3.9.0"), GameVersion.Check.LATEST)
	assert_eq(GameVersion.check("3.8.2", "3.9.0"), GameVersion.Check.LATEST)
	assert_eq(GameVersion.check("2.99.0", "3.0.0"), GameVersion.Check.LATEST)


func test_spaces_around_the_version_are_ignored() -> void:
	assert_eq(GameVersion.check(" 3.10.0\n", "3.9.0"), GameVersion.Check.NEWER)


func test_a_version_that_cannot_be_read_is_unknown() -> void:
	for text in ["", "3.9", "3.9.0.1", "3.x.0", "3.-1.0", "v3.9.0", "3..0"]:
		assert_eq(GameVersion.check(text, "3.9.0"), GameVersion.Check.UNKNOWN, text)
	assert_eq(GameVersion.check("3.9.0", "nada"), GameVersion.Check.UNKNOWN)


func test_parse_gives_three_numbers_or_none() -> void:
	assert_eq(str(GameVersion.parse("3.10.0")), "[3, 10, 0]")
	assert_true(GameVersion.parse("3.10").is_empty())


func test_current_is_the_project_version_and_reads_as_three_numbers() -> void:
	assert_eq(GameVersion.current(),
		str(ProjectSettings.get_setting("application/config/version")))
	assert_eq(GameVersion.parse(GameVersion.current()).size(), 3)
