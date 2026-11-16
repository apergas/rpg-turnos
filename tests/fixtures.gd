extends RefCounted
## Builders shared by the tests: a new game's state and one in each part, fighters and spells
## made in code, a battle with a seeded generator, and saves as a file or an older version holds
## them. Preloaded by the tests (const Fx := preload("res://tests/fixtures.gd")), never a
## class_name: tests/ is not part of the game. Nothing here writes a file or changes a loaded
## resource.

const HERO := preload("res://data/hero.tres")
## A game of the part 2: the v1 finished, the caravan joined, the companion chosen.
const PART_2 := {"rey_slime": true, "bruja": true, "golem_piedra": true, "senor_niebla": true,
	"caravana": true, "companero": true}
## A game of the part 3 on reaching Brumaclara: the v2 finished too (SaveData._valid_caravan()
## asks for the caravan's flag and the Devorador beaten).
const PART_3 := {"rey_slime": true, "bruja": true, "golem_piedra": true, "senor_niebla": true,
	"caravana": true, "companero": true, "jaguar_sombrio": true, "gusano_dunas": true,
	"grifo_cumbre": true, "guardian_ciudad": true, "devorador_portal": true, "brumaclara": true}


## A new game's state, as Game makes it (the hero duplicated from hero.tres).
static func new_state() -> GameState:
	return GameState.new(HERO)


## A new game's state in part 1, 2 or 3: its flags and its level cap.
static func state_in_part(part: int) -> GameState:
	var state := new_state()
	match part:
		2:
			state.world_flags = PART_2.duplicate()
		3:
			state.world_flags = PART_3.duplicate()
	state.sync_level_cap()
	return state


## A fighter made in code: no skills, no gear, 99 MP, and an enemy's ai that only staggers (it
## never hurts anyone) until the test gives it another.
static func fighter(id := "dummy", hp := 100, attack := 10, defense := 0, speed := 10) \
		-> Combatant:
	var c := Combatant.new()
	c.id = id
	c.display_name = id
	c.max_hp = hp
	c.hp = hp
	c.max_mp = 99
	c.mp = 99
	c.attack = attack
	c.defense = defense
	c.speed = speed
	c.ai_weights = {BattleEngine.CMD_STAGGER: 1.0}
	return c


## A spell made in code (one target).
static func skill(id: String, kind: String, power: int, element := "", status := "", \
		chance := 0.0, cost := 0) -> Skill:
	var s := Skill.new()
	s.id = id
	s.display_name = id
	s.kind = kind
	s.power = power
	s.element = element
	s.status = status
	s.status_chance = chance
	s.mp_cost = cost
	return s


## A slow enemy with plenty of HP that casts skill every turn while its MP last (then a blow of
## 1 ATK).
static func caster(skill: Skill, hp := 9999) -> Combatant:
	var c := fighter("caster", hp, 1, 0, 1)
	var skills: Array[Skill] = [skill]
	c.skills = skills
	c.ai_weights = {skill.id: 1.0}
	return c


## A battle of hero against enemy with a generator seeded rng_seed (and an empty bag unless
## inventory is given).
static func engine(hero: Combatant, enemy: Combatant, rng_seed := 1, \
		inventory: Inventory = null) -> BattleEngine:
	var enemies: Array[Combatant] = [enemy]
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	return BattleEngine.new(hero, enemies, rng, inventory if inventory != null else Inventory.new())


## The events of this type.
static func of_type(events: Array[Dictionary], type: String) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for event in events:
		if event.type == type:
			found.append(event)
	return found


## The DAMAGE events that hit target (BattleEvent.HERO, or an enemy's index).
static func hits_on(events: Array[Dictionary], target: int) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for event in of_type(events, BattleEvent.DAMAGE):
		if event.target == target:
			found.append(event)
	return found


## data as it comes back from a file: through JSON, every number a float.
static func round_trip(data: Dictionary) -> Dictionary:
	return JSON.parse_string(JSON.stringify(data)) as Dictionary


## A new game's save of the part 1, as read from its file.
static func fresh_save() -> Dictionary:
	return round_trip(SaveData.from_state(new_state(), Vector3.ZERO, 0.0))


## A part-1 save as an older version wrote it: the fields that version did not have yet are taken
## out (SaveData's header) and its number is set.
static func older_save(data: Dictionary, version: int) -> Dictionary:
	var old := data.duplicate(true)
	old.version = float(version)
	var loadout: Dictionary = old.get("loadout", {})
	if version < SaveData.MEDALS_VERSION:
		for key in ["medals", "medal_prizes", "collector_met", "ng_plus"]:
			old.erase(key)
	if version < SaveData.METAL_SLIME_VERSION:
		old.erase("metal_slime_hp")
	if version < SaveData.RING_VERSION:
		loadout.erase(Equipment.RING)
		loadout.erase(Equipment.AMULET)
		if version >= SaveData.QUESTS_VERSION:
			loadout[SaveData.OLD_ACCESSORY] = ""
	if version < SaveData.DEFEATED_VERSION:
		old.erase("defeated")
	if version < SaveData.EVOLUTION_VERSION:
		for key in ["bestiary", "wells", "ally"]:
			old.erase(key)
		loadout.erase(Equipment.HELMET)
	if version < SaveData.DIFFICULTY_VERSION:
		old.erase("difficulty")
	if version < SaveData.QUESTS_VERSION:
		old.erase("quests")
	if version < SaveData.STORY_VERSION:
		for key in ["name", "story", "stats"]:
			old.erase(key)
	if version < 5:
		old.erase("portal")
		old.erase("explored")
	if version < 4:
		for key in ["zone", "town", "flags", "key_items"]:
			old.erase(key)
	if version < 3:
		for key in ["loadout", "bag", "chests"]:
			old.erase(key)
	return old


## Sets path ("gold", "hero.hp") of data to value.
static func set_path(data: Dictionary, path: String, value: Variant) -> void:
	var keys := path.split(".")
	var at: Dictionary = data
	for i in keys.size() - 1:
		at = at[keys[i]]
	at[keys[keys.size() - 1]] = value
