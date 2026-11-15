class_name FigureTalk extends Node
## Node, a piece of Game: what the figures and the things of the map do when the hero uses
## them. The Abuela Rosa heals and moves the village quest on (on_talk()); a villager, a
## board or a thing picked up says what the QuestLog has about a quest, or its chapter lines
## (on_npc(); the Coleccionista: talk_to_collector(); the Jefe de caravana: CaravanFlow;
## Orvalla says when the v3 has no way on yet); a shop opens the ShopWindow (on_shop()) and an
## inn offers the free night (on_inn()), each after the quest waiting at its figure; a well, a chest, the lever, the key and a gate.
## Gets the session and the ShopWindow in setup(); never stores Game or a World.

const HEAL_LINE := "Descansas un momento. PV y PM recuperados."
## Seconds of black while the hero sleeps at the inn.
const INN_NIGHT_TIME := 0.8
const LEVER_NOTICE := "¡Tiras de la palanca! Se oye cómo se abre una reja."
const KEY_NOTICE := "¡Encuentras la %s!"
const DOOR_NOTICE := "Abres la reja con la %s."

## update_boss.call(): shows or hides the zone's boss (BattleFlow).
var update_boss: Callable
## await choose_companion.call(): the Jefe de caravana's choice (CaravanFlow).
var choose_companion: Callable
## await ask_departure.call(): the Jefe's questions in Villaclaro (CaravanFlow).
var ask_departure: Callable
## check_village_scene.call(): the village's first-visit cutscene (StoryFlow).
var check_village_scene: Callable
## respawn_groups.call(): every group of the map back (ZoneTravel).
var respawn_groups: Callable
## spawn_rare.call(): the Slime de Metal on this floor if due (ZoneTravel).
var spawn_rare: Callable

var _ctx: SessionContext
var _shop: ShopWindow
## Something was bought, sold or equipped since the shop opened.
var _shop_changed := false


func setup(ctx: SessionContext, shop: ShopWindow) -> void:
	_ctx = ctx
	_shop = shop
	_shop.changed.connect(func() -> void:
		_shop_changed = true
		_ctx.refresh_status.call())


## The old woman always heals; what she says and gives comes from the quest.
func on_talk() -> void:
	if _ctx.busy:
		return
	_ctx.set_busy.call(true)
	var done := _ctx.state.quest.stage == Quest.Stage.DONE
	var result := _ctx.state.quest.talk()
	var said: Array = result.lines
	if done:
		# Her quest over, the Abuela Rosa speaks of the story (her ZoneData lines).
		var story_lines := _ctx.world.npc_lines(_quest_npc(), _ctx.state.chapter())
		if not story_lines.is_empty():
			said = story_lines
	var lines: Array[String] = []
	for line: String in said:
		lines.append(StoryState.fill(line, _ctx.state.hero.display_name))
	lines.append(HEAL_LINE)
	_ctx.state.heal_full()
	if result.potions > 0:
		_ctx.state.inventory.add(Inventory.POTION, result.potions)
	_ctx.refresh_status.call()
	await _ctx.world.show_dialogue(Quest.NPC_NAME, lines)
	update_boss.call()
	_ctx.autosave.call(true)
	_ctx.set_busy.call(false)


## The index of the zone's "quest" figure (the Abuela Rosa) in ZoneData.npcs.
func _quest_npc() -> int:
	for i in _ctx.zone.npcs.size():
		if _ctx.zone.npcs[i].kind == "quest":
			return i
	return -1


## A villager or a board: what it has about a quest (the log moves the quest on and pays),
## or else its lines (World.npc_lines(): they change with the chapter).
func on_npc(index: int) -> void:
	if _ctx.busy:
		return
	_ctx.set_busy.call(true)
	var figure: String = _ctx.zone.npcs[index].name
	if figure == Medals.COLLECTOR:
		await talk_to_collector()
		_ctx.set_busy.call(false)
		return
	if figure == CaravanFlow.CARAVAN_CHIEF and _ctx.zone.id == "caravana" \
			and not _ctx.state.has_flag(StoryState.COMPANION_FLAG):
		await choose_companion.call()
		_ctx.set_busy.call(false)
		return
	if figure == CaravanFlow.CARAVAN_CHIEF and _ctx.zone.id == "pradera":
		await ask_departure.call()
		_ctx.set_busy.call(false)
		check_village_scene.call()  # the Caravana's first visit, if the hero left
		return
	# The figure the missions of its part are handed to (the v2's Jefe de caravana, the v3's
	# Orvalla): every report at once, and only one waiting line after its chapter lines.
	var receiver := figure in [CaravanFlow.CARAVAN_CHIEF, StoryState.V3_KEEPER]
	var talk := _ctx.state.quests.talk(_ctx.state, _ctx.zone.id, figure, receiver)
	var said: Array = talk.get("lines", _ctx.world.npc_lines(index, _ctx.state.chapter()))
	if receiver and talk.get("kind", "") == QuestLog.TALK_WAIT:
		# The receiver with quests under way and nothing to deliver: its chapter lines first (the
		# way on, a joke), then one waiting line.
		said = _ctx.world.npc_lines(index, _ctx.state.chapter()) + talk.lines
	if figure == StoryState.V3_KEEPER and not StoryState.v3_way_on(_ctx.state.world_flags) \
			and talk.get("kind", QuestLog.TALK_WAIT) == QuestLog.TALK_WAIT:
		said = said + [StoryState.V3_NOT_YET_LINE]  # no next land yet: she says so
	var lines: Array[String] = []
	for line: String in said:
		lines.append(StoryState.fill(line, _ctx.state.hero.display_name))
	# A thing picked up (kind "item", the cantimplora) has no voice: the narrator says it.
	var speaker := "" if _ctx.zone.npcs[index].kind == "item" else figure
	await _ctx.world.show_dialogue(speaker, lines)
	if not talk.is_empty():
		var done: Array[String] = []
		done.assign(talk.done)
		_after_quest_talk(done)
	_ctx.set_busy.call(false)


## The Coleccionista (Medals.talk()): every prize the medals reach, at once, with a sound;
## then how many are carried. Saves silently (he has met the hero, maybe given something).
func talk_to_collector() -> void:
	var talk := Medals.talk(_ctx.state, _ctx.zone.id)
	var lines: Array[String] = []
	for line: String in talk.lines:
		lines.append(StoryState.fill(line, _ctx.state.hero.display_name))
	if talk.given > 0:
		_ctx.audio.play_sfx(SfxLibrary.LEVEL_UP)
		_ctx.refresh_status.call()
	await _ctx.world.show_dialogue(Medals.COLLECTOR, lines)
	_ctx.autosave.call(false)


## The map shows what changed (a done_flag brings a figure back: Nara, the Superviviente);
## the quests finished say so with one notice and one sound; the game is saved.
func _after_quest_talk(done: Array[String]) -> void:
	if _ctx.zone.rare_enemy in _ctx.state.quests.wanted_enemies():
		spawn_rare.call()  # its hunt was just taken: it is on this floor at once
	if RunFlags.autoplay():
		for id in Inventory.SEEDS:
			while _ctx.state.inventory.count(id) > 0:
				_ctx.state.use_item(id)
	_ctx.world.set_world_flags(_ctx.state.world_flags)
	_ctx.refresh_status.call()
	if not done.is_empty():
		_ctx.audio.play_sfx(SfxLibrary.LEVEL_UP)
		_ctx.world.show_mission_done(_done_text(done))
	_ctx.autosave.call(done.is_empty())


## "Misión cumplida: <title>"; with several, all their titles on a desktop and how many on a
## phone (its status window has one line of 300 px).
func _done_text(done: Array[String]) -> String:
	if done.size() == 1:
		return QuestLog.done_text(done[0])
	if Device.is_touch():
		return QuestLog.done_count_text(done.size())
	return QuestLog.done_text(" · ".join(done))


## The index of the figure of this kind and id (a shop's or an inn's) with something about a
## quest now: a report waiting or a new offer (QuestLog.markers(): "?" or "!"), -1 if none.
## It is heard before the shop opens or the night is offered.
func _figure_with_quest(kind: String, id: String) -> int:
	var marks := _ctx.state.quests.markers(_ctx.zone.id, _ctx.state.inventory, _ctx.state.world_flags)
	for i in _ctx.zone.npcs.size():
		var npc: Dictionary = _ctx.zone.npcs[i]
		if npc.kind == kind and npc.get("id", "") == id and marks.has(npc.name):
			return i
	return -1


## The merchant: the ShopWindow until the player leaves; autosaves if anything changed.
## On autoplay it only opens when there is something to buy.
func on_shop(shop_id: String) -> void:
	if _ctx.busy:
		return
	var waiting := _figure_with_quest("shop", shop_id)
	if waiting >= 0:
		await on_npc(waiting)  # a report or an offer at the merchant goes first (pieles_mono)
	if shop_id == Shop.CARAVAN_SHOP:
		shop_id = Shop.caravan_shop(_ctx.state.shop_step())
	if _ctx.busy or (RunFlags.autoplay() and Shop.autoplay_picks(_ctx.state, shop_id).is_empty()):
		return
	_ctx.set_busy.call(true)
	_shop_changed = false
	_ctx.world.freeze(true)
	await _shop.run(shop_id)
	await _ctx.world.freeze(false)
	_ctx.refresh_status.call()
	if _shop_changed:
		_ctx.autosave.call(true)
	_ctx.set_busy.call(false)


## The innkeeper speaks; if HP or MP are missing, the hero rests at once (fade to black and
## back with HP and MP full, free) and the game saves, with no question asked. Full HP and
## MP: the keeper just remarks on it. On autoplay it only stops there below
## AUTOPLAY_INN_RATIO of max HP or MP, on GameState.needs_rest() or below the boss's
## thresholds (or a retreat for the boss would come back unhealed).
func on_inn(inn_id: String) -> void:
	if _ctx.busy:
		return
	var waiting := _figure_with_quest("inn", inn_id)
	if waiting >= 0:
		await on_npc(waiting)  # a report or an offer at the keeper goes first, as at a shop
	var hurt := _ctx.state.hero.hp < _ctx.state.hero.max_hp * AutoplayStarts.AUTOPLAY_INN_RATIO \
		or _ctx.state.hero.mp < _ctx.state.hero.max_mp * AutoplayStarts.AUTOPLAY_INN_RATIO or _ctx.state.needs_rest() \
		or not AutoplayStarts.rested_for_boss(_ctx.state.hero)
	if _ctx.busy or (RunFlags.autoplay() and not hurt):
		return
	_ctx.set_busy.call(true)
	var keeper := Inn.keeper(inn_id)
	var lines: Array[String] = [Inn.full_line(inn_id) if Inn.is_rested(_ctx.state)
		else Inn.rest_line(inn_id)]
	await _ctx.world.show_dialogue(keeper, lines)
	if Inn.is_rested(_ctx.state):
		_ctx.set_busy.call(false)
		return
	_ctx.world.freeze(true)
	Inn.stay(_ctx.state)
	await _ctx.fade.call(1.0)
	respawn_groups.call()
	_ctx.refresh_status.call()
	_ctx.audio.play_sfx(SfxLibrary.HEAL)
	await get_tree().create_timer(INN_NIGHT_TIME).timeout
	await _ctx.fade.call(0.0)
	await _ctx.world.freeze(false)
	_ctx.refresh_status.call()
	update_boss.call()
	_ctx.autosave.call(true)
	_ctx.set_busy.call(false)


## The hero used a well: drinks if it is full and the hero is not. On autoplay only a full
## well and a hero in need.
func on_well(id: String, kind: String) -> void:
	if _ctx.busy or (RunFlags.autoplay() and (Wells.is_dry(_ctx.state, id) or Inn.is_rested(_ctx.state))):
		return
	_ctx.set_busy.call(true)
	var was_dry := Wells.is_dry(_ctx.state, id)
	var text := Wells.drink(_ctx.state, id, kind)
	if not was_dry and Wells.is_dry(_ctx.state, id):
		_ctx.audio.play_sfx(SfxLibrary.HEAL)
		_ctx.refresh_status.call()
		_ctx.world.set_dry_wells(Wells.dry_ids(_ctx.state))
		_ctx.autosave.call(false)
	var lines: Array[String] = [text]
	await _ctx.world.show_dialogue("", lines)
	_ctx.set_busy.call(false)


## A closed chest: gives what it holds, opens the lid, saves without a notice and says what
## was found in the dialogue window, which waits for Enter or a tap (on autoplay it goes on
## by itself).
func on_chest(chest_id: String) -> void:
	if _ctx.busy:
		return
	var result := Chests.open(_ctx.state, chest_id)
	if not result.opened:
		return
	_ctx.set_busy.call(true)
	_ctx.state.gold_earned += Chests.CHESTS[chest_id].get("gold", 0)
	_ctx.world.set_chest_open(chest_id, true)
	_ctx.audio.play_sfx(SfxLibrary.LEVEL_UP)
	_ctx.refresh_status.call()
	_ctx.autosave.call(false)
	var lines: Array[String] = [result.text]
	await _ctx.world.show_dialogue("", lines)
	_ctx.set_busy.call(false)


## The dungeon floor's lever: sets its flag, which opens the gates it works.
func on_lever() -> void:
	if _ctx.busy or _ctx.zone.lever_flag == "":
		return
	_ctx.state.world_flags[_ctx.zone.lever_flag] = true
	_ctx.world.pull_lever()
	_ctx.audio.play_sfx(SfxLibrary.DOOR)
	_ctx.world.set_world_flags(_ctx.state.world_flags)
	_ctx.world.show_notice(LEVER_NOTICE)
	_ctx.autosave.call(false)
	_ctx.refresh_status.call()


## The key lying on the floor: into the key items; its flag keeps it taken.
func on_key() -> void:
	if _ctx.busy or _ctx.zone.floor_key == "":
		return
	_ctx.state.world_flags[_ctx.zone.floor_key] = true
	_ctx.state.key_items.append(_ctx.zone.floor_key)
	_ctx.audio.play_sfx(SfxLibrary.LEVEL_UP)
	_ctx.world.set_world_flags(_ctx.state.world_flags)
	_ctx.world.show_notice(KEY_NOTICE % Inventory.KEY_ITEMS[_ctx.zone.floor_key], "Hallazgo", &"text-positive")
	_ctx.autosave.call(false)
	_ctx.refresh_status.call()


## A closed gate: the key of the floor opens it (and is used up); otherwise its text.
func on_door() -> void:
	if _ctx.busy:
		return
	var key := _ctx.zone.door_key
	if key == "" or not key in _ctx.state.key_items:
		_ctx.world.show_notice(_ctx.zone.door_text, "Cerrado")
		return
	_ctx.state.key_items.erase(key)
	_ctx.state.world_flags[_ctx.zone.door_flag] = true
	_ctx.audio.play_sfx(SfxLibrary.DOOR)
	_ctx.world.set_world_flags(_ctx.state.world_flags)
	_ctx.world.show_notice(DOOR_NOTICE % Inventory.KEY_ITEMS[key])
	_ctx.autosave.call(false)
	_ctx.refresh_status.call()
