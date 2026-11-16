extends GutTest
## Difficulty: Fácil takes 30 % less damage and wins 25 % more EXP; anything else is Normal.


func test_easy_takes_less_damage_and_wins_more_exp() -> void:
	assert_almost_eq(Difficulty.damage_mult(Difficulty.EASY), 0.7, 0.0001)
	assert_almost_eq(Difficulty.exp_mult(Difficulty.EASY), 1.25, 0.0001)


func test_normal_and_any_other_id_change_nothing() -> void:
	for id in [Difficulty.NORMAL, "", "dificil"]:
		assert_eq(Difficulty.damage_mult(id), 1.0, id)
		assert_eq(Difficulty.exp_mult(id), 1.0, id)
