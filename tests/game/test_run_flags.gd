extends GutTest
## RunFlags: what each flag after `--` turns on. The test sets the arguments RunFlags reads once
## (its static _args and _read) and gives them back after each test, so RunFlags reads the real
## ones (none in a test run) again.


## No "-> void": GUT 9.7.1's GutTest declares after_each() without a return type, and an
## override must keep the signature it overrides.
func after_each():
	RunFlags._args = PackedStringArray()
	RunFlags._read = false


func _given(args: Array) -> void:
	RunFlags._args = PackedStringArray(args)
	RunFlags._read = true


func test_the_autoplay_sub_flags_count_only_with_autoplay() -> void:
	_given([RunFlags.AUTOPLAY_SAVE, RunFlags.AUTOPLAY_ENDING + "vencer"])
	assert_false(RunFlags.autoplay())
	assert_false(RunFlags.autoplay_save())
	assert_eq(RunFlags.autoplay_ending(), "")
	_given([RunFlags.AUTOPLAY, RunFlags.AUTOPLAY_SAVE, RunFlags.AUTOPLAY_ENDING + "vencer"])
	assert_true(RunFlags.autoplay_save())
	assert_eq(RunFlags.autoplay_ending(), "vencer")


func test_a_value_flag_gives_what_follows_its_equals_sign() -> void:
	_given([RunFlags.AUTOPLAY, RunFlags.AUTOPLAY_ZONE + "cuevas",
		RunFlags.AUTOPLAY_COMPANION + "ulma"])
	assert_eq(RunFlags.autoplay_zone(), "cuevas")
	assert_eq(RunFlags.autoplay_companion(), "ulma")
	_given([])
	assert_eq(RunFlags.autoplay_zone(), "")


func test_debug_and_touch_need_no_autoplay() -> void:
	_given([RunFlags.TOUCH, RunFlags.DEBUG])
	assert_true(RunFlags.touch())
	assert_true(RunFlags.debug())
	assert_false(RunFlags.autoplay())
