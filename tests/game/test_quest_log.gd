extends GutTest
## QuestLog and Quest: a quest offered only in its own part and before its gone flag, hunting,
## gathering and reporting, the village quest, the missions of each part, the marks over the
## figures and the quests through the save. Marked 3.8.2: the caravan's quests close with their
## land, a quest that can't be finished is lost, counts read "n/m" and, once the v3 is over, no
## quest is lost and every quest never taken is offered again.

const Fx := preload("res://tests/fixtures.gd")
## The caravan's quests and the boss of their land (3.8.2, M-112).
const CARAVAN_GONE := {"explorador_perdido": "jaguar_sombrio", "pieles_mono": "jaguar_sombrio",
	"escorpiones": "gusano_dunas", "cantimplora": "gusano_dunas", "cabras": "grifo_cumbre",
	"cristales_hielo": "grifo_cumbre", "centinelas": "devorador_portal",
	"superviviente": "devorador_portal"}
## The flags the v3's ending sets (StoryState.world_open()).
const V3_OVER := {"brumaclara": true, "albor_liberado": true}


func test_a_quest_is_offered_in_its_own_part() -> void:
	var state := Fx.state_in_part(1)
	var said := state.quests.talk(state, "pradera", "Tablón")
	assert_eq(said.kind, QuestLog.TALK_OFFER)
	assert_eq(state.quests.stage("setas"), QuestLog.Stage.ACTIVE)


func test_the_meadow_of_the_v3_offers_none_of_the_v1s() -> void:
	var state := Fx.state_in_part(3)
	assert_eq_deep(state.quests.talk(state, "pradera", "Tablón"), {})
	assert_eq(state.quests.stage("setas"), QuestLog.Stage.OPEN)
	assert_false(state.quests.markers("pradera", state.inventory, state.world_flags)
		.has("Tablón"))


func test_a_quest_is_no_longer_offered_after_its_gone_flag() -> void:
	var state := Fx.state_in_part(3)
	state.quests.talk(state, "brumaclara", "Tablón")
	assert_eq(state.quests.stage("juncos"), QuestLog.Stage.ACTIVE, "offered in Brumaclara")
	state = Fx.state_in_part(3)
	state.world_flags["garza_legamo"] = true
	state.quests.talk(state, "brumaclara", "Tablón")
	assert_eq(state.quests.stage("juncos"), QuestLog.Stage.OPEN, "gone with the Garza")
	assert_eq(state.quests.stage("geodas"), QuestLog.Stage.ACTIVE, "the next one instead")


func test_a_hunt_counts_its_kills_and_pays_on_the_report() -> void:
	var state := Fx.state_in_part(1)
	state.quests.accept(state, "lobos")
	assert_has(state.quests.wanted_enemies(), "lobo")
	for i in 4:
		state.quests.on_victory(state, "lobo")
	assert_eq(state.quests.stage("lobos"), QuestLog.Stage.ACTIVE)
	assert_eq(state.quests.count("lobos"), 4)
	state.quests.on_victory(state, "lobo")
	assert_eq(state.quests.stage("lobos"), QuestLog.Stage.REPORT)
	var said := state.quests.talk(state, "bosque", "Leñadora")
	assert_eq(said.kind, QuestLog.TALK_REPORT)
	assert_eq(state.quests.stage("lobos"), QuestLog.Stage.DONE)
	assert_eq(state.gold, GameState.START_GOLD + QuestLog.data("lobos").reward_gold)
	assert_eq(state.loadout.worn(Equipment.RING), QuestLog.data("lobos").reward_equipment)
	assert_has(state.quests.hunted_enemies(), "lobo")


func test_a_gather_hands_over_only_what_it_asked_for() -> void:
	var state := Fx.state_in_part(1)
	state.quests.accept(state, "setas")
	var quest := QuestLog.data("setas")
	state.inventory.add(quest.target, quest.goal + 1)
	var said := state.quests.talk(state, quest.turn_in_zone, quest.turn_in)
	assert_eq(said.kind, QuestLog.TALK_REPORT)
	assert_eq(state.inventory.count(quest.target), 1)
	assert_eq(state.quests.stage("setas"), QuestLog.Stage.DONE)


func test_a_quest_item_is_wanted_while_its_quest_can_use_more() -> void:
	var state := Fx.state_in_part(1)
	assert_eq(state.quests.wanted_items(state).get(Inventory.SETA, 0), 3, "offered: setas drop")
	state.inventory.add(Inventory.SETA, 3)
	assert_false(state.quests.wanted_items(state).has(Inventory.SETA), "enough carried")
	state = Fx.state_in_part(3)
	assert_false(state.quests.wanted_items(state).has(Inventory.SETA),
		"the v1's quest is not offered in the part 3")


func test_the_village_quest_goes_from_the_slimes_to_the_rey_slime() -> void:
	var quest := Quest.new()
	quest.start()
	for i in Quest.GOAL:
		quest.on_victory(Quest.TARGET_ID)
	assert_eq(quest.stage, Quest.Stage.REPORT)
	assert_eq(quest.talk().potions, Quest.REWARD_POTIONS)
	assert_true(quest.boss_available())
	quest.on_victory(Quest.BOSS_ID)
	assert_eq(quest.stage, Quest.Stage.DONE)
	assert_eq(quest.status_text(), "")


func test_each_part_counts_its_own_missions() -> void:
	assert_eq(QuestLog.total_of(1), 9, "8 side quests and the village one")
	assert_eq(QuestLog.total_of(2), 8)
	assert_eq(QuestLog.total_of(3), 8)
	var state := Fx.state_in_part(1)
	state.quest.stage = Quest.Stage.DONE
	assert_eq(state.quests.done_of(1), 1)
	assert_eq(state.quests.done_count(), 1)


func test_the_marks_over_the_figures() -> void:
	var state := Fx.state_in_part(1)
	var marks := state.quests.markers("pradera", state.inventory, state.world_flags)
	assert_eq(marks.get("Tablón"), QuestLog.NEW_MARK)
	assert_eq(marks.get(Quest.NPC_NAME), QuestLog.NEW_MARK)
	state.quests.accept(state, "setas")
	state.inventory.add(Inventory.SETA, 3)
	marks = state.quests.markers("pradera", state.inventory, state.world_flags)
	assert_eq(marks.get(QuestLog.data("setas").turn_in), QuestLog.REPORT_MARK)


func test_the_quests_go_to_the_save_and_back() -> void:
	var state := Fx.state_in_part(1)
	state.quests.accept(state, "lobos")
	state.quests.on_victory(state, "lobo")
	var saved := Fx.round_trip(state.quests.to_dict())
	saved["inventada"] = {"stage": 1.0, "count": 0.0}
	saved["setas"] = {"stage": 9.0, "count": 0.0}
	var copy := QuestLog.new(Quest.new())
	copy.set_from(saved)
	assert_eq(copy.stage("lobos"), QuestLog.Stage.ACTIVE)
	assert_eq(copy.count("lobos"), 1)
	assert_eq(copy.stage("setas"), QuestLog.Stage.DONE, "a stage past the last is clamped")
	assert_false(copy.to_dict().has("inventada"), "unknown quests are dropped")


# 3.8.2 (M-112)
func test_the_caravans_quests_go_with_their_lands_boss() -> void:
	for id: String in CARAVAN_GONE:
		assert_eq(QuestLog.data(id).gone, CARAVAN_GONE[id], id)
	var before := Fx.state_in_part(2)
	before.quests.talk(before, "caravana", "Tablón")
	assert_eq(before.quests.stage("pieles_mono"), QuestLog.Stage.ACTIVE,
		"offered while the Jaguar stands")
	var state := Fx.state_in_part(2)
	state.world_flags["jaguar_sombrio"] = true
	state.quests.talk(state, "caravana", "Tablón")
	assert_eq(state.quests.stage("pieles_mono"), QuestLog.Stage.OPEN)


# 3.8.2 (M-112)
func test_a_quest_of_an_earlier_part_is_lost_and_leaves_the_mission_lines() -> void:
	var state := Fx.state_in_part(1)
	state.quests.accept(state, "lobos")
	assert_false(state.quests.is_lost("lobos", state.world_flags, state.inventory))
	assert_eq(state.quests.status_lines(state.inventory, state.world_flags).size(), 1)
	state.world_flags = Fx.PART_2.duplicate()
	assert_true(state.quests.is_lost("lobos", state.world_flags, state.inventory))
	assert_true(state.quests.status_lines(state.inventory, state.world_flags).is_empty())
	assert_has(state.quests.journal(state.inventory, state.world_flags).lost,
		QuestLog.data("lobos").title)


# 3.8.2 (M-112)
func test_a_quest_gone_with_its_closed_land_is_lost_unless_ready() -> void:
	var state := Fx.state_in_part(3)
	state.quests.accept(state, "juncos")
	state.world_flags["garza_legamo"] = true
	assert_true(state.quests.is_lost("juncos", state.world_flags, state.inventory))
	state.inventory.add(Inventory.JUNCO_BRUMA, QuestLog.data("juncos").goal)
	assert_false(state.quests.is_lost("juncos", state.world_flags, state.inventory),
		"ready: still handed in at the village")


# 3.8.2 (M-112)
func test_the_quests_of_the_fuente_are_never_lost() -> void:
	var state := Fx.state_in_part(3)
	state.quests.accept(state, "ojos")
	state.world_flags["eco_albor"] = true
	assert_false(state.quests.is_lost("ojos", state.world_flags, state.inventory))


# 3.8.2 (M-111)
func test_once_the_v3_is_over_no_quest_is_lost() -> void:
	var state := Fx.state_in_part(3)
	state.quests.accept(state, "juncos")
	state.quests.accept(state, "lobos")
	state.world_flags["garza_legamo"] = true
	assert_true(state.quests.is_lost("juncos", state.world_flags, state.inventory))
	assert_true(state.quests.is_lost("lobos", state.world_flags, state.inventory))
	state.world_flags.merge(V3_OVER)
	assert_false(state.quests.is_lost("juncos", state.world_flags, state.inventory))
	assert_false(state.quests.is_lost("lobos", state.world_flags, state.inventory))
	assert_true(state.quests.journal(state.inventory, state.world_flags).lost.is_empty())


# 3.8.2 (M-111)
func test_once_the_v3_is_over_every_quest_never_taken_is_offered_again() -> void:
	var state := Fx.state_in_part(3)
	state.world_flags.merge(V3_OVER)
	state.world_flags["garza_legamo"] = true
	state.world_flags["jaguar_sombrio"] = true
	assert_eq(state.quests.markers("pradera", state.inventory, state.world_flags).get("Tablón"),
		QuestLog.NEW_MARK, "a v1 quest")
	state.quests.talk(state, "brumaclara", "Tablón")
	assert_eq(state.quests.stage("juncos"), QuestLog.Stage.ACTIVE, "gone, yet offered again")
	state.quests.talk(state, "caravana", "Tablón")
	assert_eq(state.quests.stage("pieles_mono"), QuestLog.Stage.ACTIVE, "a v2 quest")


# 3.8.2 (M-120)
func test_counts_read_n_slash_m_without_spaces() -> void:
	var state := Fx.state_in_part(1)
	state.quests.accept(state, "lobos")
	state.quests.on_victory(state, "lobo")
	state.quests.on_victory(state, "lobo")
	assert_has(state.quests.status_lines(state.inventory, state.world_flags),
		"Misión: lobos 2/5")
	var active: Array = state.quests.journal(state.inventory, state.world_flags).active
	assert_string_contains(active.back().text, "(2/5)")
