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


## The missions under way, for the map's status window and the pause menu; never empty:
## with none in progress, the story's next step. The one place that reads them.
func current_missions() -> Array[String]:
	var missions := quests.status_lines(inventory)
	if missions.is_empty():
		missions.append(story.goal_text(world_flags))
	return missions


## Uses an item outside battle, from the pause menu; see Inventory.use().
func use_item(id: String) -> Dictionary:
	return inventory.use(id, hero, false)


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
