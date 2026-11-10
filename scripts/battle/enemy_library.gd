class_name EnemyLibrary extends RefCounted
## Every enemy of the game by data id (data/enemies/<id>.tres) and the figure it is drawn
## with. ZoneData formations and bosses name enemies by these ids. Pure: no nodes.

const ENEMIES := {
	"slime": preload("res://data/enemies/slime.tres"),
	"bat": preload("res://data/enemies/bat.tres"),
	"mushroom": preload("res://data/enemies/mushroom.tres"),
	"rey_slime": preload("res://data/enemies/rey_slime.tres"),
	"lobo": preload("res://data/enemies/lobo.tres"),
	"duende": preload("res://data/enemies/duende.tres"),
	"planta": preload("res://data/enemies/planta.tres"),
	"bruja": preload("res://data/enemies/bruja.tres"),
	"golem_barro": preload("res://data/enemies/golem_barro.tres"),
	"arana": preload("res://data/enemies/arana.tres"),
	"espectro": preload("res://data/enemies/espectro.tres"),
	"golem_piedra": preload("res://data/enemies/golem_piedra.tres"),
	"esqueleto_guerrero": preload("res://data/enemies/esqueleto_guerrero.tres"),
	"esqueleto_picaro": preload("res://data/enemies/esqueleto_picaro.tres"),
	"esqueleto_mago": preload("res://data/enemies/esqueleto_mago.tres"),
	"senor_niebla": preload("res://data/enemies/senor_niebla.tres"),
	"slime_metal": preload("res://data/enemies/slime_metal.tres"),
	# The color variants of 1.6.0.
	"slime_rojo": preload("res://data/enemies/slime_rojo.tres"),
	"seta_venenosa": preload("res://data/enemies/seta_venenosa.tres"),
	"hongo_cueva": preload("res://data/enemies/hongo_cueva.tres"),
	"murcielago_cripta": preload("res://data/enemies/murcielago_cripta.tres"),
	"espectro_escarcha": preload("res://data/enemies/espectro_escarcha.tres"),
	# The boss after the ending, in the throne room. Not in the bestiary (Bestiary.FAMILIES).
	"eco_niebla": preload("res://data/enemies/eco_niebla.tres"),
}
## Figure of each enemy id; any other id is a slime.
const LOOKS := {
	"slime": BattleActor.Look.SLIME,
	"bat": BattleActor.Look.BAT,
	"mushroom": BattleActor.Look.MUSHROOM,
	"rey_slime": BattleActor.Look.KING_SLIME,
	"lobo": BattleActor.Look.WOLF,
	"duende": BattleActor.Look.GOBLIN,
	"planta": BattleActor.Look.PLANT,
	"bruja": BattleActor.Look.WITCH,
	"golem_barro": BattleActor.Look.MUD_GOLEM,
	"arana": BattleActor.Look.SPIDER,
	"espectro": BattleActor.Look.SPECTER,
	"golem_piedra": BattleActor.Look.STONE_GOLEM,
	"esqueleto_guerrero": BattleActor.Look.SKELETON_WARRIOR,
	"esqueleto_picaro": BattleActor.Look.SKELETON_ROGUE,
	"esqueleto_mago": BattleActor.Look.SKELETON_MAGE,
	"senor_niebla": BattleActor.Look.FOG_LORD,
	"slime_metal": BattleActor.Look.METAL_SLIME,
	"slime_rojo": BattleActor.Look.RED_SLIME,
	"seta_venenosa": BattleActor.Look.POISON_MUSHROOM,
	"hongo_cueva": BattleActor.Look.CAVE_MUSHROOM,
	"murcielago_cripta": BattleActor.Look.CRYPT_BAT,
	"espectro_escarcha": BattleActor.Look.FROST_SPECTER,
	"eco_niebla": BattleActor.Look.FOG_ECHO,
	# The creatures that fight beside the hero (data in Allies, not in ENEMIES).
	"gallina": BattleActor.Look.CHICKEN,
	"lobezno": BattleActor.Look.WOLF_CUB,
	"golem_pequeno": BattleActor.Look.MINI_GOLEM,
	"esqueleto_leal": BattleActor.Look.LOYAL_SKELETON,
}


## The data of enemy id (not duplicated: BattleScene does it), or null.
## Where enemy_id lives: the names of the zones whose encounters, rare enemy or boss bring
## it, each once, in ZoneData.IDS order ("Mina abandonada" once for its three floors).
static func zone_names(enemy_id: String) -> Array[String]:
	var names: Array[String] = []
	for zone_id in ZoneData.IDS:
		var zone := ZoneData.by_id(zone_id)
		if _lives_in(zone, enemy_id) and not names.has(zone.display_name):
			names.append(zone.display_name)
	return names


static func _lives_in(zone: ZoneData, enemy_id: String) -> bool:
	if zone.boss_id == enemy_id or zone.rare_enemy == enemy_id:
		return true
	for formation: Array in zone.formations + zone.start_formations:
		if formation.has(enemy_id):
			return true
	return false


static func data(enemy_id: String) -> Combatant:
	return ENEMIES.get(enemy_id) as Combatant


static func look(enemy_id: String) -> BattleActor.Look:
	return LOOKS.get(enemy_id, BattleActor.Look.SLIME)


## Turns lists of ids into lists of enemy data (a formation, as EncounterTable picks it).
static func formation(ids: Array) -> Array[Combatant]:
	var picked: Array[Combatant] = []
	for enemy_id: String in ids:
		picked.append(data(enemy_id))
	return picked
