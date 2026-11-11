class_name Combatant extends Resource
## Stats of one fighter. Battles work on duplicates of the enemy data, so the .tres
## files never change; the hero is a duplicate of hero.tres that lives the whole session.

@export var display_name := ""
## Data id: the quest counts kills by it and the battle picks the enemy's figure by it
## ("hero" or an EnemyLibrary.ENEMIES key).
@export var id := ""
## Feminine name ("la Seta saltarina"): the battle messages use la / una / -a.
@export var female := false
@export var level := 1
@export var max_hp := 1
@export var hp := 1
@export var max_mp := 0
@export var mp := 0
## Base attack and defense (the hero's grow with each level). Battles use
## total_attack() / total_defense(), which add the equipment bonuses.
@export var attack := 1
@export var defense := 0
## Hero only: bonuses of the equipment worn, copied from the Loadout by
## GameState.refresh_equipment() (never saved: the loadout is).
@export var equip_attack := 0
@export var equip_defense := 0
@export var equip_speed := 0
## Hero only: status effects the equipment keeps away.
@export var equip_immune: Array[String] = []
@export var speed := 1
@export var skills: Array[Skill] = []
## Hero only: spell learned on reaching each level (level -> Skill).
@export var learn := {}
## EXP and gold the winner gets for defeating this fighter.
@export var exp_reward := 0
@export var gold_reward := 0
## EXP accumulated so far (only meaningful for the hero). Not called `exp`, which
## would shadow the built-in exp() function.
@export var experience := 0
## Enemy only: weights of the action it picks each round. Keys are "attack",
## "stagger" (loses the turn), "charge" (gathers strength: its next turn is a blow of
## BattleEngine.CHARGE_MULT damage) or the id of one of its skills. Empty means always
## attack.
@export var ai_weights := {}
## Enemy only: elements ("fire", "ice", "thunder") that hurt it ×1.5 / ×0.5.
@export var weak: Array[String] = []
@export var resist: Array[String] = []
## Enemy only: chance (0..1) of leaving each item (Inventory id) when defeated.
@export var drops := {}
## Enemy only: status its plain attack may cause on a hit ("poison", ...) and the chance.
@export var attack_status := ""
@export var attack_status_chance := 0.0
## Enemy only: the fighter it calls, once per battle, below half HP (null: never).
@export var help: Combatant
## Enemy only: a heal it casts once per battle, as soon as its HP falls below
## rescue_heal_ratio of the maximum on one of its turns (null: never).
@export var rescue_heal: Skill
@export var rescue_heal_ratio := 0.4
## Boss only: the key item (Inventory.KEY_ITEMS id) the hero gets for defeating it.
@export var key_item := ""
## Boss only: an Equipment id given the first time it is beaten, never again (the Eco de
## la Niebla's Yelmo de bruma; "" for none). Game puts it on (QuestRewards.wear_prize()).
@export var reward_equipment := ""
## Boss only: the stats it rises with the first time its HP reaches 0 (the Señor de la
## Niebla's second phase; null: none). BattleEngine copies its HP, MP, attack, defense,
## speed, skills and ai_weights into the fighter, which stays the same enemy.
@export var next_phase: Combatant
## Said when a boss rises in this phase (set on the next_phase resource): "¡El ojo del
## Devorador se abre!". "" for the fog's line (the Señor de la Niebla).
@export var phase_line := ""
## Enemy only: a boss gets its own look and intro line, and the hero can't flee.
@export var is_boss := false
## Enemy only, on the map (MonsterRoam): how far from its spot the figure of a group it
## leads walks (metres; 0: it stands still) and how fast (metres per second).
@export var map_roam := 0.0
@export var map_speed := 1.5

## Status effects during a battle: status -> rounds left (-1: until cured or the battle
## ends). Never saved; BattleEngine clears it when the battle ends.
var status := {}
## The highest level the hero can reach now: Leveling.V1_MAX_LEVEL until the caravan.
## Never saved; GameState.sync_level_cap() sets it.
var level_cap := Leveling.V1_MAX_LEVEL


func is_alive() -> bool:
	return hp > 0


func total_attack() -> int:
	return attack + equip_attack


func total_defense() -> int:
	return defense + equip_defense


func total_speed() -> int:
	return speed + equip_speed


func is_immune(status_id: String) -> bool:
	return status_id in equip_immune


func find_skill(skill_id: String) -> Skill:
	for skill in skills:
		if skill.id == skill_id:
			return skill
	return null
