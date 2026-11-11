class_name Inventory extends RefCounted
## Items the hero carries, as id -> count. GameState keeps one for the whole session.
## ITEMS describes every item; use() applies one to a Combatant and is shared by the
## battle (BattleEngine) and the pause menu.

const POTION := "potion"
const ETHER := "ether"
const BIG_POTION := "pocion_grande"
const BIG_ETHER := "eter_grande"
const ANTIDOTE := "antidote"
const WING := "wing"
const INCENSE := "incienso"
const PHOENIX := "pluma_fenix"
const ALARM := "despertador"
const SETA := "seta"
## The jungle's quest item (pieles_mono), dropped by the Mono aullador.
const PIEL_MONO := "piel_mono"
const SEED_ATTACK := "semilla_fuerza"
const SEED_DEFENSE := "semilla_defensa"
const SEED_SPEED := "semilla_agilidad"
## The small medals are not an item: GameState.medals counts them. These are the name and
## the key text (KEY_TEXTS) the pause menu's Objetos shows for them.
const MEDAL := "medalla_pequena"
const MEDAL_NAME := "Medalla pequeña"
const START_POTIONS := 3
## What a seed adds to its stat, for good.
const SEED_BONUS := 2
const SEEDS: Array[String] = [SEED_ATTACK, SEED_DEFENSE, SEED_SPEED]
## Effect of the Pluma de fénix: if the hero falls in battle it burns by itself and he
## rises with value of his max HP (BattleEngine), once per battle. Never used by hand.
const EFFECT_REVIVE := "revive"
## Why an item that works by itself can't be used by hand.
const AUTO_USE := "Se usa sola"
## Effect of the Despertador: in battle, the hero can't fall asleep until it ends
## (BattleEngine keeps the guard; it is gone with the battle).
const EFFECT_WAKE_GUARD := "wake_guard"
## name and article (for "una Poción"); effect "hp" (heals value HP), "mp" (restores
## value MP), "cure" (removes the status named by value), "travel" (the Ala de viaje:
## Game takes the hero to the last village visited and leaves a portal there that leads
## back once), "repel" (the Incienso: for value metres touching a group of monsters starts no battle; GameState
## counts them), "seed" (adds SEED_BONUS to the Combatant field named by value),
## "revive" (EFFECT_REVIVE: the Pluma de fénix, used by itself when the hero falls in battle,
## value is the share of max HP he rises with), "wake_guard" (EFFECT_WAKE_GUARD: the
## Despertador, no sleep for the rest of the battle) or "quest"
## (of no use: someone is asking for it); price in gold (Shop sells at it and
## buys back at half); battle / field: usable in battle / from the pause menu; text: what
## it does, shown in the shop, in Objetos and in battle.
const ITEMS := {
	POTION: {"name": "Poción", "article": "una", "effect": "hp", "value": 30, "price": 8,
		"battle": true, "field": true, "text": "Recupera 30 PV."},
	ETHER: {"name": "Éter", "article": "un", "effect": "mp", "value": 15, "price": 30,
		"battle": true, "field": true, "text": "Recupera 15 PM."},
	BIG_POTION: {"name": "Poción grande", "article": "una", "effect": "hp", "value": 100,
		"price": 40, "battle": true, "field": true, "text": "Recupera 100 PV."},
	BIG_ETHER: {"name": "Éter grande", "article": "un", "effect": "mp", "value": 40,
		"price": 90, "battle": true, "field": true, "text": "Recupera 40 PM."},
	ANTIDOTE: {"name": "Antídoto", "article": "un", "effect": "cure", "value": "poison",
		"price": 10, "battle": true, "field": false, "text": "Cura el veneno."},
	ALARM: {"name": "Despertador", "article": "un", "effect": EFFECT_WAKE_GUARD, "value": 0,
		"price": 12, "battle": true, "field": false,
		"text": "Evita el sueño hasta el final del combate."},
	PHOENIX: {"name": "Pluma de fénix", "article": "una", "effect": EFFECT_REVIVE,
		"value": 0.5, "price": 150, "battle": false, "field": false,
		"text": "Si caes en combate, te levanta con la mitad de PV."},
	WING: {"name": "Ala de viaje", "article": "un", "effect": "travel", "value": 0,
		"price": 25, "battle": false, "field": true,
		"text": "Te lleva al último lugar seguro y deja un portal para volver una vez."},
	INCENSE: {"name": "Incienso", "article": "un", "effect": "repel", "value": 200,
		"price": 20, "battle": false, "field": true,
		"text": "Los monstruos no te atacan durante 200 m."},
	SETA: {"name": "Seta", "article": "una", "effect": "quest", "value": 0, "price": 0,
		"battle": false, "field": false,
		"text": "De las que saltan. Alguien de Villaclaro las anda buscando."},
	PIEL_MONO: {"name": "Piel de mono", "article": "una", "effect": "quest", "value": 0,
		"price": 0, "battle": false, "field": false,
		"text": "Suave y con rayas. Alguien de la caravana las anda buscando."},
	SEED_ATTACK: {"name": "Semilla de fuerza", "article": "una", "effect": "seed",
		"value": "attack", "price": 0, "battle": false, "field": true,
		"text": "Sube el ATK en 2 para siempre."},
	SEED_DEFENSE: {"name": "Semilla de defensa", "article": "una", "effect": "seed",
		"value": "defense", "price": 0, "battle": false, "field": true,
		"text": "Sube la DEF en 2 para siempre."},
	SEED_SPEED: {"name": "Semilla de agilidad", "article": "una", "effect": "seed",
		"value": "speed", "price": 0, "battle": false, "field": true,
		"text": "Sube la VEL en 2 para siempre."},
}
## Order of the item lists.
const IDS: Array[String] = [POTION, ETHER, BIG_POTION, BIG_ETHER, ANTIDOTE, ALARM, PHOENIX, WING,
	INCENSE, SEED_ATTACK, SEED_DEFENSE, SEED_SPEED, SETA, PIEL_MONO]
## Why an Ala de viaje can't be used in a village.
const IN_TOWN := "Ya estás en un lugar seguro"
## Why a "quest" item can't be used.
const QUEST_ITEM := "Para una misión"
## The stat a seed raises, as the status windows name it.
const SEED_STATS := {"attack": "ATK", "defense": "DEF", "speed": "VEL"}
## Key items (GameState.key_items): never used up, sold or dropped; id -> name.
const KEY_ITEMS := {
	"fragmento_bosque": "Fragmento del amuleto (1/3)",
	"fragmento_mina": "Fragmento del amuleto (2/3)",
	"fragmento_castillo": "Fragmento del amuleto (3/3)",
	"llave_mina": "Llave de la mina",
	"carta_granjero": "Carta del Granjero",
	"insignia_jungla": "Insignia de la jungla",
}
## What each key item is, for Objetos.
const KEY_TEXTS := {
	"fragmento_bosque": "Un trozo del Amuleto del Alba. Lo guardaba la Bruja del bosque.",
	"fragmento_mina": "Un trozo del Amuleto del Alba. Lo guardaba el Golem de piedra.",
	"fragmento_castillo": "El último trozo del Amuleto del Alba. Lo guardaba el Señor de la Niebla.",
	"llave_mina": "Abre la reja de la tercera planta de la mina.",
	"carta_granjero": "Para la Leñadora, en la aldea del bosque. Huele un poco a gallina.",
	"insignia_jungla": "La llevaba el Jaguar sombrío. Abre el camino hacia el desierto.",
	MEDAL: "El Coleccionista de Villaclaro las colecciona.",
}

var _items := {}


static func display_name(id: String) -> String:
	return ITEMS[id].name if ITEMS.has(id) else id


static func article(id: String) -> String:
	return ITEMS[id].article if ITEMS.has(id) else "un"


## "ATK", "DEF" or "VEL" for a seed.
static func seed_stat(id: String) -> String:
	return SEED_STATS.get(ITEMS[id].value, "") if ITEMS.has(id) else ""


## What an item or a key item does, in a short sentence.
static func description(id: String) -> String:
	return ITEMS[id].text if ITEMS.has(id) else KEY_TEXTS.get(id, "")


## True if the battle's Objetos page lists id: the items usable in battle and the
## Pluma de fénix, shown grey ("Se usa sola").
static func listed_in_battle(id: String) -> bool:
	return ITEMS.has(id) and (ITEMS[id].battle or ITEMS[id].effect == EFFECT_REVIVE)


func count(id: String) -> int:
	return _items.get(id, 0)


func add(id: String, n := 1) -> void:
	_items[id] = count(id) + n


## Removes one; false if there was none.
func take(id: String) -> bool:
	if count(id) <= 0:
		return false
	_items[id] = count(id) - 1
	return true


## Why the item can't be used on c now, in battle or from the menu ("" if it can).
func problem(id: String, c: Combatant, in_battle: bool) -> String:
	if count(id) <= 0:
		return "No te quedan"
	var item: Dictionary = ITEMS[id]
	if item.effect == "quest":
		return QUEST_ITEM
	if item.effect == EFFECT_REVIVE:
		return AUTO_USE
	if in_battle and not item.battle:
		return "Solo fuera de combate"
	if not in_battle and not item.field:
		return "Solo en combate"
	match item.effect:
		"hp":
			if c.hp >= c.max_hp:
				return "PV al máximo"
		"mp":
			if c.mp >= c.max_mp:
				return "PM al máximo"
		"cure":
			if not c.status.has(item.value):
				return "No hace falta"
	return ""


## Takes one and applies it to c. Returns {"used": bool, "effect": String, "amount":
## int (HP or MP recovered), "status": String (cured), "reason": String (why not)}. A
## "travel" item only gets used up: the caller does the trip.
func use(id: String, c: Combatant, in_battle: bool) -> Dictionary:
	var reason := problem(id, c, in_battle)
	if reason != "":
		return {"used": false, "effect": "", "amount": 0, "status": "", "reason": reason}
	take(id)
	var item: Dictionary = ITEMS[id]
	var result := {"used": true, "effect": item.effect, "amount": 0, "status": "",
		"reason": ""}
	match item.effect:
		"hp":
			result.amount = mini(item.value, c.max_hp - c.hp)
			c.hp += result.amount
		"mp":
			result.amount = mini(item.value, c.max_mp - c.mp)
			c.mp += result.amount
		"cure":
			c.status.erase(item.value)
			result.status = item.value
		"seed":
			c.set(item.value, int(c.get(item.value)) + SEED_BONUS)
			result.amount = SEED_BONUS
	return result


## Copy of the items as id -> count, for the save game.
func to_dict() -> Dictionary:
	return _items.duplicate()


## Replaces every item with these (id -> count), when a game is loaded.
func set_items(items: Dictionary) -> void:
	_items = items.duplicate()


## The best healing potion carried: the Poción grande if there is one, else the Poción
## (also when there is none: the caller checks can_use()).
static func best_potion(inventory: Inventory) -> String:
	return BIG_POTION if inventory.count(BIG_POTION) > 0 else POTION
