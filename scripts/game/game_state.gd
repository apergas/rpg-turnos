class_name GameState extends RefCounted
## State of the play session, kept in memory while the game is open. The hero, the
## inventory, the gold, the equipment, the village quest and the progress through the
## world live here for the whole session; battles, shops, chests, exits and dialogue
## change them in place.

const START_GOLD := 50
## The last boss: its world flag marks the game as finished.
const FINAL_BOSS := "senor_niebla"

var hero: Combatant
var inventory := Inventory.new()
var quest := Quest.new()
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


## Uses an item outside battle, from the pause menu; see Inventory.use().
func use_item(id: String) -> Dictionary:
	return inventory.use(id, hero, false)


## Copies the loadout's bonuses into the hero (battles read total_attack/defense()).
func refresh_equipment() -> void:
	hero.equip_attack = loadout.attack_bonus()
	hero.equip_defense = loadout.defense_bonus()


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


func has_flag(flag: String) -> bool:
	return flag == "" or world_flags.get(flag, false)


## True once the Señor de la Niebla is beaten: the adventure is over (the ending itself
## comes with the story).
func is_finished() -> bool:
	return has_flag(FINAL_BOSS)


## Gold lost on a defeat: half of what is carried, rounded down (gold - lost remains).
func defeat_gold_loss() -> int:
	return floori(gold / 2.0)
