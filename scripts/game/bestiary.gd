class_name Bestiary extends RefCounted
## The bestiary's families (five, nine on a caravan game): every enemy with a card belongs to one (the Eco de la Niebla
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

## The v2's families (2.3.0): the enemies of the caravan's four lands and its bosses. They
## only count on a caravan game (families()); their prizes follow the same rule.
const V2_FAMILIES: Array[Dictionary] = [
	{"id": "fieras", "name": "Fieras salvajes",
		"enemies": ["rana_dardo", "serpiente_liana", "mono_aullador", "escorpion", "buitre",
			"lobo_nieves", "cabra_montesa", "rata_ruinas"],
		"reward": Equipment.CLAW_RING},
	{"id": "bichos", "name": "Plantas y bichos de la arena",
		"enemies": ["planta_trampa", "seta_tropical", "slime_arena", "murcielago_hielo"],
		"reward": Equipment.OASIS_AMULET},
	{"id": "constructos", "name": "Constructos y almas",
		"enemies": ["golem_arena", "golem_hielo", "espiritu_cumbre", "armadura_hueca",
			"gargola", "sombra", "esqueleto_centinela", "momia"],
		"reward": Equipment.WATCH_AMULET},
	{"id": "jefes_caravana", "name": "Jefes de la caravana",
		"enemies": ["jaguar_sombrio", "gusano_dunas", "grifo_cumbre", "guardian_ciudad",
			"devorador_portal"],
		"reward": Equipment.PORTAL_SWORD},
]
## Every v2 enemy with a card, family by family (25).
const V2_ENEMIES: Array[String] = ["rana_dardo", "serpiente_liana", "mono_aullador",
	"escorpion", "buitre", "lobo_nieves", "cabra_montesa", "rata_ruinas", "planta_trampa",
	"seta_tropical", "slime_arena", "murcielago_hielo", "golem_arena", "golem_hielo",
	"espiritu_cumbre", "armadura_hueca", "gargola", "sombra", "esqueleto_centinela", "momia",
	"jaguar_sombrio", "gusano_dunas", "grifo_cumbre", "guardian_ciudad", "devorador_portal"]


## The families that count in this game: the v1's, and the v2's on a caravan game.
static func families(state: GameState) -> Array[Dictionary]:
	var all: Array[Dictionary] = FAMILIES.duplicate()
	if state.in_caravan():
		all.append_array(V2_FAMILIES)
	return all


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


## How many enemies the bestiary counts: the families' (22) and, on a caravan game, the v2's (25: 47 in all).
static func total_count(state: GameState) -> int:
	return all_ids().size() + (V2_ENEMIES.size() if state.in_caravan() else 0)


## The family with family_id ({} if none), the v2's too.
static func family(family_id: String) -> Dictionary:
	for entry in FAMILIES + V2_FAMILIES:
		if entry.id == family_id:
			return entry
	return {}


## The id of enemy_id's family ("" for none: the Eco de la Niebla).
static func family_of(enemy_id: String) -> String:
	for entry in FAMILIES + V2_FAMILIES:
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
	for entry in families(state):
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
	for entry in families(state):
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
