class_name NgPlus extends RefCounted
## The Partida nueva + (M-35): a finished game starts the story again with the hero as he
## is (begin()): his level, EXP, stats and spells, the equipment worn and the bag, the gold
## and the items (not the key items), the creature, the bestiary, the medals and the
## Coleccionista's prizes, his name and the difficulty. Everything else starts again: the
## story and its chapter, every quest, the chests, the world flags (but the prizes already
## given: the bestiary families' and the Eco de la Niebla's), the key items, the portal, the
## wells, the map explored and the numbers of the credits, in the hero's house. In it every
## enemy is stronger (scaled()): HP, ATK and DEF times stat_mult(), EXP and gold times
## reward_mult(); spells hurt by their power, as always. Pure: a GameState and copies of the
## enemy data, no nodes.

## HP, ATK and DEF of the enemies of each zone (ZoneData.number: 1 meadow, 2 forest, 3 mine,
## 4 castle) in the first Partida nueva +. Starting values 1 + (4 - zone) × 0.6, so the
## meadow is a challenge for a hero who finished the game; tuned with the autoplay (1.8.0).
const ZONE_MULT := {1: 2.8, 2: 2.2, 3: 1.6, 4: 1.0}
## What each further round adds to every zone's multiplier.
const CYCLE_STEP := 0.3
## EXP and gold of every enemy in a Partida nueva + (the EXP only helps below Lv 20).
const REWARD_MULT := 1.5
## World flags a new round keeps besides the bestiary families' (Bestiary.FLAG_PREFIX): the
## prizes already given, so none comes twice (the Eco de la Niebla's Yelmo de bruma).
const KEPT_FLAGS: Array[String] = ["eco_niebla"]
## Where a new round starts (the hero's house: its start entry).
const START_ZONE := "pradera"


## How much stronger the enemies of zone_number are in round ng_plus (1.0 in a first game).
static func stat_mult(ng_plus: int, zone_number: int) -> float:
	if ng_plus <= 0:
		return 1.0
	return float(ZONE_MULT.get(zone_number, 1.0)) + (ng_plus - 1) * CYCLE_STEP


## How much more EXP and gold the enemies give in round ng_plus (1.0 in a first game).
static func reward_mult(ng_plus: int) -> float:
	return REWARD_MULT if ng_plus > 0 else 1.0


## The enemies of a battle in round ng_plus of zone_number: stronger copies (the data, the
## one it calls for help and the boss's next phase are never changed). A first game gets
## enemies back as it is.
static func scaled(enemies: Array[Combatant], ng_plus: int,
		zone_number: int) -> Array[Combatant]:
	if ng_plus <= 0:
		return enemies
	var stats := stat_mult(ng_plus, zone_number)
	var rewards := reward_mult(ng_plus)
	var copies: Array[Combatant] = []
	for enemy in enemies:
		copies.append(_scaled_copy(enemy, stats, rewards))
	return copies


## value times mult, rounded.
static func scale_value(value: int, mult: float) -> int:
	return roundi(value * mult)


## Starts a new round on a finished game: what stays and what starts again (see the header).
static func begin(state: GameState) -> void:
	state.ng_plus += 1
	var flags := {}
	for flag: String in state.world_flags:
		if flag.begins_with(Bestiary.FLAG_PREFIX) or flag in KEPT_FLAGS:
			flags[flag] = state.world_flags[flag]
	state.world_flags = flags
	state.key_items.clear()
	state.opened_chests.clear()
	state.quest = Quest.new()
	state.quests = QuestLog.new(state.quest)
	state.story = StoryState.new()
	state.well_charge = {}
	state.explored = {}
	state.close_portal()
	state.zone_id = START_ZONE
	state.town_zone = START_ZONE
	state.repel_m = 0.0
	state.metal_slime_hp = 0
	state.battles = 0
	state.steps = 0
	state.gold_earned = 0
	state.heal_full()


static func _scaled_copy(enemy: Combatant, stats: float, rewards: float) -> Combatant:
	var copy := enemy.duplicate() as Combatant
	copy.max_hp = scale_value(copy.max_hp, stats)
	copy.hp = scale_value(copy.hp, stats)
	copy.attack = scale_value(copy.attack, stats)
	copy.defense = scale_value(copy.defense, stats)
	copy.exp_reward = scale_value(copy.exp_reward, rewards)
	copy.gold_reward = scale_value(copy.gold_reward, rewards)
	if copy.help != null:
		copy.help = _scaled_copy(copy.help, stats, rewards)
	if copy.next_phase != null:
		copy.next_phase = _scaled_copy(copy.next_phase, stats, rewards)
	return copy
