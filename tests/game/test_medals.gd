extends GutTest
## Medals: forty small medals, each taken once, a prize every four, and the Coleccionista (first
## meeting, every prize the medals reach at once, his joke in another village, the forty).

const Fx := preload("res://tests/fixtures.gd")


func test_a_medal_is_taken_once() -> void:
	var state := Fx.new_state()
	var id := Medals.next_missing(state)
	assert_eq(id, Medals.MEDALS[0])
	assert_eq(Medals.take(state, id), Medals.FOUND_TEXT % [1, Medals.MEDALS.size()])
	assert_eq(Medals.take(state, id), "")
	assert_eq(Medals.take(state, "inventada"), "")
	assert_eq(Medals.next_missing(state), Medals.MEDALS[1])


func test_a_prize_every_four_medals_up_to_ten() -> void:
	assert_eq(Medals.MEDALS.size(), 40)
	assert_eq(Medals.PRIZES.size(), 10)
	assert_eq(Medals.prizes_for(0), 0)
	assert_eq(Medals.prizes_for(3), 0)
	assert_eq(Medals.prizes_for(4), 1)
	assert_eq(Medals.prizes_for(39), 9)
	assert_eq(Medals.prizes_for(40), 10)


func test_the_collector_gives_at_once_every_prize_the_medals_reach() -> void:
	var state := Fx.new_state()
	for id in Medals.MEDALS.slice(0, 8):
		Medals.take(state, id)
	var said := Medals.talk(state, Medals.COLLECTOR_ZONE)
	assert_eq(said.given, 2)
	assert_eq(said.lines[0], Medals.INTRO)
	assert_eq(said.lines.back(), Medals.NEXT_LINE % [8, 12])
	assert_eq(state.loadout.worn(Equipment.RING), "anillo_cobre")
	assert_eq(state.loadout.worn(Equipment.AMULET), Equipment.MEDAL_AMULET)
	assert_eq(Medals.talk(state, Medals.COLLECTOR_ZONE).given, 0, "never twice")


func test_the_collector_jokes_once_in_another_village_and_thanks_at_forty() -> void:
	var state := Fx.new_state()
	Medals.talk(state, Medals.COLLECTOR_ZONE)
	assert_has(Medals.talk(state, "bosque").lines, Medals.AWAY_LINE)
	assert_does_not_have(Medals.talk(state, "bosque").lines, Medals.AWAY_LINE)
	for id in Medals.MEDALS:
		Medals.take(state, id)
	assert_eq(Medals.talk(state, "bosque").lines.back(), Medals.ALL_LINE)
	assert_eq(state.medal_prizes, Medals.PRIZES.size())


func test_medals_drop_less_often_in_later_parts() -> void:
	assert_almost_eq(Medals.drop_chance(1), 0.075, 0.0001)
	assert_almost_eq(Medals.drop_chance(2), 0.05, 0.0001)
	assert_almost_eq(Medals.drop_chance(3), 0.04, 0.0001)
	assert_almost_eq(Medals.drop_chance(9), Medals.drop_chance(1), 0.0001, "any other: the v1's")
