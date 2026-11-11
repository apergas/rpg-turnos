class_name Bestiary extends RefCounted
## The bestiary's families: every enemy with a card belongs to one (the Eco de la Niebla
## has none and never counts). A family is complete once every enemy of it has been beaten
## (GameState.defeated_enemies, not only seen); its prize, a piece of equipment of its own,
## is given once (give()) and marked with the world flag "familia_<id>", so the save needs
## no field of its own. Pure: reads and changes a GameState, no nodes.

const FLAG_PREFIX := "familia_"
## In the album's order: id, name, the enemies in order and the prize (an Equipment id).
const FAMILIES: Array[Dictionary] = [
	{"id": "magicas", "name": "Criaturas mágicas",
		"enemies": ["slime", "slime_rojo", "duende", "golem_barro", "slime_metal"],
		"reward": Equipment.CRYSTAL_RING},
	{"id": "plantas", "name": "Plantas",
		"enemies": ["mushroom", "planta", "seta_venenosa", "hongo_cueva"],
		"reward": Equipment.SAP_RING},
	{"id": "bestias", "name": "Bestias",
		"enemies": ["bat", "lobo", "arana", "murcielago_cripta"],
		"reward": Equipment.FANG_AMULET},
	{"id": "muertos", "name": "Muertos vivientes",
		"enemies": ["espectro", "espectro_escarcha", "esqueleto_guerrero", "esqueleto_picaro",
			"esqueleto_mago"],
		"reward": Equipment.BONE_AMULET},
	{"id": "jefes", "name": "Jefes",
		"enemies": ["rey_slime", "bruja", "golem_piedra", "senor_niebla"],
		"reward": Equipment.DAWN_SWORD},
]

## The v2's enemies (the caravan), in album order, with no family until 2.3.0: the album
## shows them under "La caravana" and they give no prize yet.
const V2_ENEMIES: Array[String] = ["rana_dardo", "serpiente_liana", "mono_aullador",
	"planta_trampa", "seta_tropical", "jaguar_sombrio", "escorpion", "slime_arena", "buitre",
	"golem_arena", "momia", "gusano_dunas", "lobo_nieves", "golem_hielo", "espiritu_cumbre",
	"murcielago_hielo", "cabra_montesa", "grifo_cumbre"]


## Every enemy with a card, family by family (22).
static func all_ids() -> Array[String]:
	var ids: Array[String] = []
	for entry in FAMILIES:
		for id: String in entry.enemies:
			ids.append(id)
	return ids


## True if enemy_id has a card (and so counts as seen and beaten).
static func has(enemy_id: String) -> bool:
	return family_of(enemy_id) != "" or V2_ENEMIES.has(enemy_id)


## How many enemies the bestiary counts: the families' (22) and, on a caravan game, the v2's.
static func total_count(state: GameState) -> int:
	return all_ids().size() + (V2_ENEMIES.size() if state.in_caravan() else 0)


## The family with family_id ({} if none).
static func family(family_id: String) -> Dictionary:
	for entry in FAMILIES:
		if entry.id == family_id:
			return entry
	return {}


## The id of enemy_id's family ("" for none: the Eco de la Niebla).
static func family_of(enemy_id: String) -> String:
	for entry in FAMILIES:
		if (entry.enemies as Array).has(enemy_id):
			return entry.id
	return ""


## The world flag that says family_id's prize has been given.
static func flag(family_id: String) -> String:
	return FLAG_PREFIX + family_id


## How many enemies of family_id have been beaten.
static func beaten_count(state: GameState, family_id: String) -> int:
	var beaten := 0
	for id: String in family(family_id).get("enemies", []):
		if state.defeated_enemies.has(id):
			beaten += 1
	return beaten


static func is_complete(state: GameState, family_id: String) -> bool:
	var entry := family(family_id)
	return not entry.is_empty() and beaten_count(state, family_id) == entry.enemies.size()


## The families complete whose prize has not been given yet, in album order.
static func new_rewards(state: GameState) -> Array[String]:
	var ids: Array[String] = []
	for entry in FAMILIES:
		if is_complete(state, entry.id) and not state.has_flag(flag(entry.id)):
			ids.append(entry.id)
	return ids


## Gives family_id's prize once: sets its flag and puts the piece on if its slot is empty,
## else into the bag (QuestRewards.give_piece()). Returns the line that says so: "¡Has
## completado la familia Plantas del bestiario! Recibes un Anillo de savia. Te lo equipas."
static func give(state: GameState, family_id: String) -> String:
	var entry := family(family_id)
	state.world_flags[flag(family_id)] = true
	return "¡Has completado la familia %s del bestiario! %s" % [entry.name,
		QuestRewards.give_piece(state, entry.reward)]


## How many families are complete.
static func complete_count(state: GameState) -> int:
	var complete := 0
	for entry in FAMILIES:
		if is_complete(state, entry.id):
			complete += 1
	return complete


## How many enemies with a card have been seen (the v2's only on a caravan game).
static func seen_count(state: GameState) -> int:
	var seen := 0
	var ids := all_ids()
	if state.in_caravan():
		ids.append_array(V2_ENEMIES)
	for id in ids:
		if state.seen_enemies.has(id):
			seen += 1
	return seen
