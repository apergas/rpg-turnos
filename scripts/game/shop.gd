class_name Shop extends RefCounted
## Shop rules: what each shop sells, buying, selling at half price and comparing a piece
## of equipment with what the hero wears. Pure: works on a GameState, never touches
## nodes. buy() and sell() return {"ok": bool, "text": String} with the message to show.

const VILLACLARO := "villaclaro"
const BOSQUE := "bosque"
const MINA := "mina"
const CASTILLO := "castillo"
## The Caravana's merchant (the v2): one figure, a shop per tramo (caravan_shop()).
const CARAVAN_SHOP := "caravana"
## The Jefe de caravana's choice of companion (the v2): three "creatures" at no cost.
const COMPANIONS_SHOP := "companeros"
## shop id -> keeper's name, equipment and items (Inventory ids) on sale, in list order.
## Zone 1 sells no Éter (it comes with the zone 2 shop); the Ala de viaje, the Incienso and the
## Despertador are sold everywhere; the Pluma de fénix from the forest on.
const SHOPS := {
	VILLACLARO: {
		"keeper": "Mercader",
		"equipment": [Equipment.COPPER_SWORD, Equipment.LEATHER_MAIL, Equipment.WOODEN_SHIELD,
			"casco_cobre"],
		"items": [Inventory.POTION, Inventory.ANTIDOTE, Inventory.ALARM, Inventory.WING,
			Inventory.INCENSE],
	},
	BOSQUE: {
		"keeper": "Mercader",
		"equipment": ["espada_hierro", "cota_malla", "escudo_hierro", "casco_hierro"],
		"items": [Inventory.POTION, Inventory.ANTIDOTE, Inventory.ETHER, Inventory.ALARM,
			Inventory.PHOENIX, Inventory.WING, Inventory.INCENSE],
	},
	MINA: {
		"keeper": "Herrero",
		"equipment": ["espada_acero", "armadura_acero", "escudo_acero", "casco_acero"],
		"items": [Inventory.POTION, Inventory.ANTIDOTE, Inventory.ETHER, Inventory.ALARM,
			Inventory.PHOENIX, Inventory.WING, Inventory.INCENSE],
	},
	CASTILLO: {
		"keeper": "Mercader",
		"equipment": ["espada_platino", "armadura_platino", "escudo_platino", "casco_platino"],
		"items": [Inventory.POTION, Inventory.ANTIDOTE, Inventory.ETHER, Inventory.ALARM,
			Inventory.PHOENIX, Inventory.WING, Inventory.INCENSE],
	},
	# The tamers: they sell one creature each. gear_shop: the shop whose gear autoplay
	# buys first.
	"domadora_villaclaro": {"keeper": "Domadora", "equipment": [], "items": [],
		"ally": "gallina", "gear_shop": VILLACLARO},
	"domadora_bosque": {"keeper": "Domadora", "equipment": [], "items": [],
		"ally": "lobezno", "gear_shop": BOSQUE},
	"domadora_mina": {"keeper": "Domadora", "equipment": [], "items": [],
		"ally": "golem_pequeno", "gear_shop": MINA},
	"domadora_castillo": {"keeper": "Domadora", "equipment": [], "items": [],
		"ally": "esqueleto_leal", "gear_shop": CASTILLO},
	# The Caravana's merchant, tramo 1 (the jungle): the jade gear comes with its task and the
	# big potions now; caravana_2..4 come with the zones of 2.1.0-2.3.0.
	"caravana_1": {
		"keeper": "Mercader",
		"equipment": [],
		"items": [Inventory.BIG_POTION, Inventory.BIG_ETHER, Inventory.ANTIDOTE,
			Inventory.WING, Inventory.INCENSE, Inventory.PHOENIX, Inventory.ALARM],
	},
	COMPANIONS_SHOP: {"keeper": "Jefe de caravana", "equipment": [], "items": [],
		"allies": Allies.COMPANIONS},
}
const NO_GOLD := "Falta oro"
const WORN := "Lo llevas puesto"
const NOT_FOR_SALE := "No se vende"
## What the starting gear sells for: it is worth almost nothing, but it clears the bag.
const STARTING_GEAR_PRICE := 1
const NOT_CARRIED := "No lo llevas"
const HAS_IT := "Ya la tienes"
const HAS_BETTER := "Ya tienes una mejor"
## Shown on the other companions once one has been chosen.
const HAS_COMPANION := "Ya tienes compañero"
## Potions --autoplay keeps in stock once it has the shop's equipment.
const AUTOPLAY_POTIONS := 3
## The ×5 button of consumables.
const BULK := 5


## The shop of the highest tramo up to `tramo` that exists in SHOPS.
static func caravan_shop(tramo: int) -> String:
	for t in range(clampi(tramo, 1, 4), 0, -1):
		var id := "%s_%d" % [CARAVAN_SHOP, t]
		if SHOPS.has(id):
			return id
	return "%s_1" % CARAVAN_SHOP


static func keeper(shop_id: String) -> String:
	return SHOPS[shop_id].keeper


static func sells_ally(shop_id: String) -> bool:
	# The Caravana's figure id (CARAVAN_SHOP) is not a key: it picks one per tramo.
	return SHOPS.has(shop_id) and (SHOPS[shop_id].has("ally") or SHOPS[shop_id].has("allies"))


## The creatures on sale: the tamer's one, or the companions' list.
static func allies_of(shop_id: String) -> Array:
	if SHOPS[shop_id].has("allies"):
		return SHOPS[shop_id].allies
	return [SHOPS[shop_id].ally] if SHOPS[shop_id].has("ally") else []


static func is_ally(id: String) -> bool:
	return Allies.exists(id)


## Every id on sale: equipment first, then items, then the creature of a tamer.
static func stock(shop_id: String) -> Array[String]:
	var ids: Array[String] = []
	ids.assign(SHOPS[shop_id].equipment + SHOPS[shop_id].items)
	if sells_ally(shop_id):
		ids.append_array(allies_of(shop_id))
	return ids


static func is_equipment(id: String) -> bool:
	return Equipment.exists(id)


static func display_name(id: String) -> String:
	if is_ally(id):
		return Allies.display_name(id)
	return Equipment.display_name(id) if is_equipment(id) else Inventory.display_name(id)


static func article(id: String) -> String:
	if is_ally(id):
		return Allies.article(id)
	return Equipment.article(id) if is_equipment(id) else Inventory.article(id)


static func price(id: String) -> int:
	if is_ally(id):
		return Allies.price(id)
	return Equipment.price(id) if is_equipment(id) else int(Inventory.ITEMS[id].price)


## What the shop pays for id: half its price, rounded down. The starting gear (zone 0)
## has no price but sells for STARTING_GEAR_PRICE; quest rewards can't be sold.
static func sell_price(id: String) -> int:
	if is_equipment(id) and Equipment.EQUIPMENT[id].zone == 0:
		return STARTING_GEAR_PRICE
	return floori(price(id) / 2.0)


## Why state can't buy id now ("" if it can).
static func buy_problem(state: GameState, id: String) -> String:
	if is_ally(id):
		if Allies.is_companion(id):
			return HAS_COMPANION if Allies.is_companion(state.ally_id) else ""
		if state.ally_id == id:
			return HAS_IT
		if Allies.tier(state.ally_id) > Allies.tier(id):
			return HAS_BETTER
	return NO_GOLD if state.gold < price(id) else ""


static func can_buy(state: GameState, id: String) -> bool:
	return buy_problem(state, id) == ""


## Pays and puts the piece in the bag (equipment) or the inventory (items).
static func buy(state: GameState, id: String) -> Dictionary:
	var why := buy_problem(state, id)
	if why != "":
		return {"ok": false, "text": "%s." % why}
	state.gold -= price(id)
	if is_ally(id):
		state.ally_id = id
		if Allies.is_companion(id):
			return {"ok": true, "text": "%s se une a ti." % Allies.display_name(id)}
	elif is_equipment(id):
		state.bag_equipment.append(id)
	else:
		state.inventory.add(id)
	return {"ok": true, "text": "Compras %s %s por %d G." % [article(id), display_name(id),
		price(id)]}


static func can_buy_bulk(state: GameState, id: String) -> bool:
	return not is_equipment(id) and state.gold >= price(id) * BULK


static func buy_bulk(state: GameState, id: String) -> Dictionary:
	if not can_buy_bulk(state, id):
		return {"ok": false, "text": "%s." % NO_GOLD}
	state.gold -= price(id) * BULK
	state.inventory.add(id, BULK)
	return {"ok": true, "text": "Compras %s ×%d por %d G." % [display_name(id), BULK,
		price(id) * BULK]}


## What can be offered for sale, in list order: the equipment worn (it can't be sold, but
## is listed), the equipment in the bag (one row per id) and the items carried.
static func sell_list(state: GameState) -> Array[String]:
	var ids: Array[String] = []
	for slot in Equipment.SLOTS:
		var worn := state.loadout.worn(slot)
		if worn != "":
			ids.append(worn)
	for id: String in Equipment.EQUIPMENT:
		if id in state.bag_equipment and not ids.has(id):
			ids.append(id)
	for id in Inventory.IDS:
		if state.inventory.count(id) > 0:
			ids.append(id)
	return ids


## How many of id the hero carries that could be sold (the worn one does not count).
static func sell_count(state: GameState, id: String) -> int:
	if is_equipment(id):
		return state.bag_equipment.count(id)
	return state.inventory.count(id)


## Why id can't be sold ("" if it can): worn and none in the bag, or not for sale.
static func sell_problem(state: GameState, id: String) -> String:
	if sell_count(state, id) <= 0:
		return WORN if state.loadout.is_worn(id) else NOT_CARRIED
	if sell_price(id) <= 0:
		return NOT_FOR_SALE
	return ""


static func sell(state: GameState, id: String) -> Dictionary:
	var why := sell_problem(state, id)
	if why != "":
		return {"ok": false, "text": "%s." % why}
	if is_equipment(id):
		state.bag_equipment.erase(id)
	else:
		state.inventory.take(id)
	state.gold += sell_price(id)
	return {"ok": true, "text": "Vendes %s %s por %d G." % [article(id), display_name(id),
		sell_price(id)]}


## Compares a piece with what is worn in its slot: {"stat": "ATK" / "DEF", "worn": id
## worn ("" if none), "bonus": the piece's bonus, "diff": bonus minus the worn one's}.
## Empty for items.
static func compare(state: GameState, id: String) -> Dictionary:
	if not is_equipment(id):
		return {}
	var worn := state.loadout.worn(Equipment.slot(id))
	return {"stat": Equipment.stat_name(id), "worn": worn, "bonus": Equipment.bonus(id),
		"diff": Equipment.bonus(id) - Equipment.bonus(worn)}


## For --autoplay: one Ala de viaje if none is carried (the autoplay retreat flies back
## with it), then the equipment of the shop that beats what is worn and is not in the bag
## yet, in slot order, as long as the gold lasts. Once there is no such piece left (bought
## or not), or with no potions at all, potions up to AUTOPLAY_POTIONS. In Villaclaro the first 50 G must go on the
## gear and the village is close by, so there the Ala waits until the gear is bought.
static func autoplay_picks(state: GameState, shop_id: String) -> Array[String]:
	var picks: Array[String] = []
	if sells_ally(shop_id):
		for ally: String in allies_of(shop_id):
			if Allies.is_companion(ally):
				return picks  # Game chooses the companion on autoplay (Task 8), not the shop
			if can_buy(state, ally) and not _gear_pending(state, shop_id):
				picks.append(ally)
		return picks
	var gold := state.gold
	var upgrades := 0
	var wants_wing := state.inventory.count(Inventory.WING) == 0
	if wants_wing and shop_id != VILLACLARO and gold >= price(Inventory.WING):
		picks.append(Inventory.WING)
		gold -= price(Inventory.WING)
		wants_wing = false
	for id: String in SHOPS[shop_id].equipment:
		if compare(state, id).diff <= 0 or id in state.bag_equipment:
			continue
		upgrades += 1
		if gold >= price(id):
			picks.append(id)
			gold -= price(id)
	var potion_id := Inventory.BIG_POTION if Inventory.BIG_POTION in SHOPS[shop_id].items \
		else Inventory.POTION
	var potions := state.inventory.count(potion_id)
	if upgrades > 0 and potions > 0:
		return picks
	if upgrades == 0 and wants_wing and gold >= price(Inventory.WING):
		picks.append(Inventory.WING)
		gold -= price(Inventory.WING)
	while potions < AUTOPLAY_POTIONS and gold >= price(potion_id):
		picks.append(potion_id)
		gold -= price(potion_id)
		potions += 1
	return picks


## True while the village's shop still has an upgrade not bought (even if unaffordable).
static func _gear_pending(state: GameState, shop_id: String) -> bool:
	for id: String in SHOPS[SHOPS[shop_id].gear_shop].equipment:
		if compare(state, id).diff > 0 and not id in state.bag_equipment:
			return true
	return false
