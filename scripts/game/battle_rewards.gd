class_name BattleRewards extends RefCounted
## Rule: what a battle on the map means for the GameState. The boss of a map (boss_id(): the
## zone's, or its postgame boss once the game is finished) and whether it is on the map
## (boss_wanted()); the bestiary notes (note_enemies(): seen, or beaten after a won battle;
## only the enemies with a card) and the families' prizes (family_rewards()); and everything a
## victory gives (after_victory(): gold, medals, the village quest, the side quests, a boss's
## flag, key item, notice, cutscene and first-victory prize, the families). It changes the
## state and returns what to say; BattleFlow plays it back. Never touches nodes.

## Notice after beating a boss (by id); other bosses announce their key item.
const BOSS_NOTICES := {
	"rey_slime": "¡Villaclaro está a salvo! La niebla deja libre el camino del norte.",
	"senor_niebla": "¡Consigues el último Fragmento del amuleto! La niebla se levanta.",
	"eco_niebla": "El Eco de la Niebla se deshace en la bruma... por ahora.",
}
## Said before a boss's first-victory prize (Combatant.reward_equipment).
const REWARD_LINE := "Entre la bruma brilla algo."
const KEY_ITEM_NOTICE := "¡Consigues un %s!"


## The boss of this map: the zone's, or its postgame boss (ZoneData.postgame_boss_id) once
## the game is finished.
static func boss_id(zone: ZoneData, state: GameState) -> String:
	if zone.postgame_boss_id != "" and state.is_finished():
		return zone.postgame_boss_id
	return zone.boss_id


## The boss of this map is due: not beaten yet (the Rey Slime only while the quest asks for
## it). The postgame boss can always be fought again, when postgame_allowed (autoplay only
## meets it on --autoplay-zone=eco).
static func boss_wanted(zone: ZoneData, state: GameState, postgame_allowed: bool) -> bool:
	var boss := boss_id(zone, state)
	if boss == "":
		return false
	if boss == zone.postgame_boss_id:
		# It can always be fought again; autoplay only meets it on --autoplay-zone=eco.
		return postgame_allowed
	return state.quest.boss_available() if boss == Quest.BOSS_ID else not state.has_flag(boss)


## The part whose ending follows this victory: 2 after the Devorador del portal, 3 after the Eco
## de Albor, each only the first time; 0 otherwise.
static func ending_part(state: GameState, zone: ZoneData, boss: bool) -> int:
	if not boss:
		return 0
	var id := boss_id(zone, state)
	if id == StoryState.V2_FINAL_BOSS and not state.story.finished_v2:
		return 2
	if id == StoryState.V3_FINAL_BOSS and not state.story.finished_v3:
		return 3
	return 0


## Notes enemies in the bestiary: seen, or beaten too after a won battle. Only those with a
## card (Bestiary.has()): the Eco de la Niebla never counts.
static func note_enemies(state: GameState, enemies: Array[Combatant], beaten: bool) -> void:
	for enemy in enemies:
		if not Bestiary.has(enemy.id):
			continue
		if beaten:
			state.defeat_enemy(enemy.id)
		else:
			state.see_enemy(enemy.id)


## Gives the prize of every bestiary family completed and not paid yet (Bestiary): its
## flag and its piece. Returns the lines that say so, for the dialogue window.
static func family_rewards(state: GameState) -> Array[String]:
	var lines: Array[String] = []
	for family_id in Bestiary.new_rewards(state):
		lines.append(Bestiary.give(state, family_id))
	return lines


## Sets the boss's world flag, gives its key item and says so.
static func boss_notice(state: GameState, boss: Combatant) -> String:
	var key_item := state.on_boss_defeated(boss)
	if BOSS_NOTICES.has(boss.id):
		return BOSS_NOTICES[boss.id]
	if key_item != "":
		return KEY_ITEM_NOTICE % Inventory.KEY_ITEMS[key_item]
	return ""


## A won battle: the gold, the medals dropped, the enemies beaten in the bestiary, the village
## quest and the side quests, each boss's flag, key item, notice, cutscene and first-victory
## prize, and the families completed (not after the last boss of the v2 or the v3 the first time:
## its ending follows, and the prize comes later).
static func after_victory(state: GameState, zone: ZoneData, enemies: Array[Combatant],
		gold_won: int, medals_won: int, boss: bool) -> Dictionary:
	var notice := ""
	var reward_lines: Array[String] = []
	var scene := ""
	var finished_quests: Array[Dictionary] = []
	var family_lines: Array[String] = []
	state.gold += gold_won
	state.gold_earned += gold_won
	var quest_was_on := state.quest.stage != Quest.Stage.DONE
	note_enemies(state, enemies, true)
	for n in medals_won:
		Medals.take(state, Medals.next_missing(state))
	for enemy in enemies:
		state.quest.on_victory(enemy.id)
		if enemy.is_boss:
			var first := not state.has_flag(enemy.id)
			notice = boss_notice(state, enemy)
			scene = state.story.scene_after_boss(enemy.id)
			if first and enemy.reward_equipment != "":
				reward_lines.append(REWARD_LINE)
				reward_lines.append_array(QuestRewards.wear_prize(state,
					enemy.reward_equipment))
	var mission_done := quest_was_on and state.quest.stage == Quest.Stage.DONE
	for enemy in enemies:
		finished_quests.append_array(state.quests.on_victory(state, enemy.id))
	# The enemies are noted as beaten above: a family may be complete now.
	# The last boss of the v2 or of the v3 (the first time): its part's ending follows. The v2's
	# also completes the Jefes de la caravana, but no map is left to show the prize on: it comes
	# when the game is next loaded, in the Caravana (Game._ready()); the v3's prizes come after
	# its credits, in Brumaclara (StoryFlow.finish_v3()).
	var ending := ending_part(state, zone, boss)
	if ending == 0:
		family_lines = family_rewards(state)
	return {
		"notice": notice,
		"reward_lines": reward_lines,
		"scene": scene,
		"mission_done": mission_done,
		"finished_quests": finished_quests,
		"family_lines": family_lines,
		"ending": ending,
	}
