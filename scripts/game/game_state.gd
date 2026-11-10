class_name GameState extends RefCounted
## State of the play session, kept in memory while the game is open. The hero, the
## inventory, the gold, the equipment, the village quest, the progress through the
## world and the story live here for the whole session; battles, shops, chests, exits,
## dialogue and cutscenes change them in place. The hero's name is hero.display_name.

const START_GOLD := 50
## The last boss: its world flag marks the game as finished.
const FINAL_BOSS := "senor_niebla"
## The autoplay retreat: below this share of max HP the hero needs rest.
const REST_HP_RATIO := 0.3

var hero: Combatant
var inventory := Inventory.new()
var quest := Quest.new()
## Every mission: the village quest above and the side quests.
var quests := QuestLog.new(quest)
var gold := START_GOLD
## What the hero wears; its bonuses are copied into the hero by refresh_equipment().
var loadout := Loadout.new()
## Equipment carried but not worn (Equipment ids; the same id may appear more than once).
var bag_equipment: Array[String] = []
## Ids of the chests already opened (Chests.CHESTS keys).
var opened_chests: Array[String] = []
## Enemy ids met in battle (EnemyLibrary ids), for the bestiary.
var seen_enemies: Array[String] = []
## Enemy ids beaten in a won battle (EnemyLibrary ids), for the bestiary's cards.
var defeated_enemies: Array[String] = []
## Dry wells: well id -> battles left until it is full again (absent: full).
var well_charge := {}
## The creature fighting beside the hero (Allies id, "" for none).
var ally_id := ""
## The HP the Slime de Metal had when it last got away (it ran, or the hero fled): its next
## battle starts with them. 0: none (it was beaten, or never fought). Saved.
var metal_slime_hp := 0
## Progress through the world: flag -> true. A boss sets its enemy id when defeated
## ("rey_slime" lifts the fog of the meadow's north exit); ZoneData exits name the flag
## that opens them.
var world_flags := {}
## Key items carried (Inventory.KEY_ITEMS ids), in the order they were found.
var key_items: Array[String] = []
## ZoneData id of the map the hero is on.
var zone_id := "pradera"
## ZoneData id of the last village visited: the Ala de viaje and a defeat lead to its
## town entry.
var town_zone := "pradera"
## The story: cutscenes seen, the ending reached; the chapter follows from it and the
## world flags (chapter()).
var story := StoryState.new()
## Numbers of the whole game for the credits: battles fought, steps walked and gold won
## (in battle and from chests).
var battles := 0
var steps := 0
var gold_earned := 0
## The open return portal of an Ala de viaje: the village it stands in ("" while none is
## open) and the zone and spot it leads back to, once.
var portal_town := ""
var portal_zone := ""
var portal_pos := Vector3.ZERO
## What the hero has seen of each zone: zone id -> ExploredMap (explored_map()).
var explored := {}
## A Difficulty id, chosen for each game.
var difficulty := Difficulty.NORMAL


func _init(hero_data: Combatant) -> void:
	hero = hero_data.duplicate() as Combatant
	# Its own list: learning a spell must never change the one in hero.tres.
	hero.skills = hero_data.skills.duplicate()
	inventory.add(Inventory.POTION, Inventory.START_POTIONS)
	refresh_equipment()


## Back to full HP and MP, used after a defeat and when talking to the old woman.
func heal_full() -> void:
	hero.hp = hero.max_hp
	hero.mp = hero.max_mp


## The Slime de Metal of a battle about to start gets metal_slime_hp: enemies holds data,
## so it is replaced by a copy. Returns the HP it starts with (0: none kept).
func give_metal_slime_hp(enemies: Array[Combatant]) -> int:
	if metal_slime_hp <= 0:
		return 0
	for i in enemies.size():
		if enemies[i].id == EnemyLibrary.METAL_SLIME:
			var metal := enemies[i].duplicate() as Combatant
			metal.hp = mini(metal_slime_hp, metal.max_hp)
			enemies[i] = metal
			return metal.hp
	return 0


## After a battle (outcome: BattleEngine.State) with the Slime de Metal: beaten, it forgets
## its HP; still standing after a FLED one (it ran, or the hero did), it keeps them for the
## next (full HP: nothing to keep). Returns the HP kept now (0: none).
func keep_metal_slime_hp(enemies: Array[Combatant], outcome: int) -> int:
	for enemy in enemies:
		if enemy.id != EnemyLibrary.METAL_SLIME:
			continue
		if outcome == BattleEngine.State.WON:
			metal_slime_hp = 0
		elif outcome == BattleEngine.State.FLED and enemy.is_alive():
			metal_slime_hp = enemy.hp if enemy.hp < enemy.max_hp else 0
			return metal_slime_hp
		return 0
	return 0


## The next thing the story asks: the village quest while it lasts, then the chapter's goal.
func main_goal() -> String:
	var line := quest.status_text()
	return line if line != "" else story.goal_text(world_flags, zone_id)


## The lines of the mission lists (status window, pause menu): the main goal first, then
## the side quests. Never empty. The one place that reads them.
func current_missions() -> Array[String]:
	var missions: Array[String] = [main_goal()]
	missions.append_array(quests.status_lines(inventory))
	return missions


## The spells the hero can cast from the pause menu: the heals (Curar, Curar+).
func field_spells() -> Array[Skill]:
	var spells: Array[Skill] = []
	for skill in hero.skills:
		if skill.kind == Skill.HEAL:
			spells.append(skill)
	return spells


## Why skill can't be cast from the menu now ("" if it can).
func spell_problem(skill: Skill) -> String:
	if hero.mp < skill.mp_cost:
		return "Faltan PM"
	if hero.hp >= hero.max_hp:
		return "PV al máximo"
	return ""


## Casts a heal outside battle, as in battle: pays its MP and recovers up to its power.
## Returns the HP recovered (0: it could not be cast).
func cast_spell(skill: Skill) -> int:
	if spell_problem(skill) != "":
		return 0
	hero.mp -= skill.mp_cost
	var amount := mini(skill.power, hero.max_hp - hero.hp)
	hero.hp += amount
	return amount


## Metres an Incienso still keeps the monsters away (not saved: it ends with the session).
var repel_m := 0.0


## Uses an item outside battle, from the pause menu; see Inventory.use(). An Incienso
## starts its metres again.
func use_item(id: String) -> Dictionary:
	var result := inventory.use(id, hero, false)
	if result.used and result.effect == "repel":
		repel_m = float(Inventory.ITEMS[id].value)
	return result


## Copies the loadout's bonuses into the hero (battles read total_attack/defense()).
func refresh_equipment() -> void:
	hero.equip_attack = loadout.attack_bonus()
	hero.equip_defense = loadout.defense_bonus()
	hero.equip_speed = loadout.speed_bonus()
	hero.equip_immune = loadout.immunities()


## Puts on a piece from the bag; what it replaces goes to the bag. False if id is not
## in the bag.
func equip(id: String) -> bool:
	var index := bag_equipment.find(id)
	if index < 0:
		return false
	bag_equipment.remove_at(index)
	var removed := loadout.equip(id)
	if removed != "":
		bag_equipment.append(removed)
	refresh_equipment()
	return true


## Takes off what is worn in slot and puts it in the bag.
func unequip(slot: String) -> void:
	var removed := loadout.unequip(slot)
	if removed != "":
		bag_equipment.append(removed)
	refresh_equipment()


## Records a defeated boss: its world flag and its key item (once). Returns the key
## item id it gave ("" if none or already carried).
func on_boss_defeated(boss: Combatant) -> String:
	world_flags[boss.id] = true
	if boss.key_item == "" or boss.key_item in key_items:
		return ""
	key_items.append(boss.key_item)
	return boss.key_item


## What has been seen of a zone (nothing yet, the first time).
func explored_map(id: String) -> ExploredMap:
	if not explored.has(id):
		explored[id] = ExploredMap.new(ZoneData.by_id(id))
	return explored[id]


func has_portal() -> bool:
	return portal_town != ""


## An Ala de viaje used at pos on the current zone: the portal stands in the last village
## and leads back here. Returns true if it replaced one still open (that one closes).
func open_portal(pos: Vector3) -> bool:
	var replaced := has_portal()
	portal_town = town_zone
	portal_zone = zone_id
	portal_pos = pos
	return replaced


func close_portal() -> void:
	portal_town = ""
	portal_zone = ""
	portal_pos = Vector3.ZERO


func has_flag(flag: String) -> bool:
	return flag == "" or world_flags.get(flag, false)


## For the autoplay retreat: true when the hero is in no shape for another battle far
## from an inn: below REST_HP_RATIO of max HP, or out of potions with MP for less than
## two of his best heal spell.
func needs_rest() -> bool:
	if hero.hp < hero.max_hp * REST_HP_RATIO:
		return true
	var heal_cost := 0
	for skill in hero.skills:
		if skill.kind == Skill.HEAL:
			heal_cost = maxi(heal_cost, skill.mp_cost)
	return inventory.count(Inventory.POTION) == 0 and hero.mp < heal_cost * 2


## True once the Señor de la Niebla is beaten: the adventure is over (the ending
## cutscene and the credits follow; story.finished is set after them).
func is_finished() -> bool:
	return has_flag(FINAL_BOSS)


## The story chapter now (StoryState.Chapter).
func chapter() -> StoryState.Chapter:
	return story.chapter(world_flags)


## Quests completed, for the credits.
func quests_done() -> int:
	return quests.done_count()


## Gold lost on a defeat: half of what is carried, rounded down (gold - lost remains).
func defeat_gold_loss() -> int:
	return floori(gold / 2.0)


## An enemy beaten in a won battle: seen too.
func defeat_enemy(id: String) -> void:
	see_enemy(id)
	if not defeated_enemies.has(id):
		defeated_enemies.append(id)


func see_enemy(id: String) -> void:
	if not seen_enemies.has(id):
		seen_enemies.append(id)
