class_name QuestLog extends RefCounted
## Every mission: the village quest (Quest) first, then the side quests of QUESTS, each with
## its stage and its count. Says what a figure has to say about them, which marks to show
## and what the mission lines and the Diario read. Pure: Game passes it the GameState,
## shows what it returns and saves to_dict(). A quest never gates anything: the story goes
## on whether or not it is taken or finished.

enum Stage { OPEN, ACTIVE, REPORT, DONE }

const QUESTS := {
	"carta": preload("res://data/quests/carta.tres"),
	"setas": preload("res://data/quests/setas.tres"),
	"lobos": preload("res://data/quests/lobos.tres"),
	"gato": preload("res://data/quests/gato.tres"),
	"slime_metal": preload("res://data/quests/slime_metal.tres"),
	"explorador": preload("res://data/quests/explorador.tres"),
	"aranas": preload("res://data/quests/aranas.tres"),
	"olla": preload("res://data/quests/olla.tres"),
	"pieles_mono": preload("res://data/quests/pieles_mono.tres"),
	"explorador_perdido": preload("res://data/quests/explorador_perdido.tres"),
	"escorpiones": preload("res://data/quests/escorpiones.tres"),
	"cantimplora": preload("res://data/quests/cantimplora.tres"),
	"cabras": preload("res://data/quests/cabras.tres"),
	"cristales_hielo": preload("res://data/quests/cristales_hielo.tres"),
	"centinelas": preload("res://data/quests/centinelas.tres"),
	"superviviente": preload("res://data/quests/superviviente.tres"),
}
const VILLAGE_ZONE := "pradera"
## Ends the waiting lines of a HUNT or GATHER of several, so the progress is said aloud.
const PROGRESS_LINE := "Llevas %d de %d."
const STATUS_PREFIX := "Misión: "
## Most mission lines shown at once; the rest are in the Diario.
const MAX_STATUS_LINES := 3
const MORE_LINES := "y %d más en el Diario"
const NEW_MARK := "!"
const REPORT_MARK := "?"
## What talk() did: delivered every report waiting, met a sought figure, made an offer or
## said a waiting line.
const TALK_REPORT := "report"
const TALK_FOUND := "found"
const TALK_OFFER := "offer"
const TALK_WAIT := "wait"
## The notice of several missions finished at once on a phone (one line of 300 px).
const DONE_MANY_TEXT := "Misiones cumplidas: %d"
## The v2's flags in the order a game sets them: a turn-in figure that needs a flag earlier
## than its quest's is always there when the quest can be finished (problems()).
const FLAG_ORDER := ["caravana_vista", "caravana", "companero", "jaguar_sombrio",
	"gusano_dunas", "grifo_cumbre", "guardian_ciudad", "devorador_portal"]

## The village quest, the same object as GameState.quest.
var village: Quest
## id -> Stage (OPEN if missing) and id -> enemies defeated (HUNT).
var _stages := {}
var _counts := {}


func _init(p_village: Quest) -> void:
	village = p_village


static func data(id: String) -> QuestData:
	return QUESTS[id] as QuestData


## What show_mission_done() says about a quest with this title.
static func done_text(title: String) -> String:
	return "%s: %s" % [Quest.DONE_TEXT, title]


## What show_mission_done() says on a phone when several quests end at once.
static func done_count_text(count: int) -> String:
	return DONE_MANY_TEXT % count


func stage(id: String) -> Stage:
	return _stages.get(id, Stage.OPEN)


func count(id: String) -> int:
	return _counts.get(id, 0)


func is_active(id: String) -> bool:
	return stage(id) == Stage.ACTIVE or stage(id) == Stage.REPORT


## Takes the quest; a DELIVER hands over what is to be delivered.
func accept(state: GameState, id: String) -> void:
	_stages[id] = Stage.ACTIVE
	var key := data(id).key_item
	if key != "" and not key in state.key_items:
		state.key_items.append(key)


## Counts one enemy of a won battle. Returns {title, lines} of each quest that ended on the
## spot (no one to report to), already paid.
func on_victory(state: GameState, enemy_id: String) -> Array[Dictionary]:
	var finished: Array[Dictionary] = []
	for id: String in QUESTS:
		var quest := data(id)
		if quest.kind != QuestData.Kind.HUNT or quest.target != enemy_id \
				or stage(id) != Stage.ACTIVE:
			continue
		_counts[id] = count(id) + 1
		if count(id) < quest.goal:
			continue
		_stages[id] = Stage.REPORT
		if quest.turn_in == "":
			finished.append({"title": quest.title, "lines": _finish(state, quest)})
	return finished


## The enemies some active quest is hunting (a rare one only comes for them).
func wanted_enemies() -> Array[String]:
	var wanted: Array[String] = []
	for id: String in QUESTS:
		if stage(id) == Stage.ACTIVE and data(id).kind == QuestData.Kind.HUNT:
			wanted.append(data(id).target)
	return wanted


## The enemies a finished hunt was after: a rare one still comes for them, though seldom.
func hunted_enemies() -> Array[String]:
	var hunted: Array[String] = []
	for id: String in QUESTS:
		if stage(id) == Stage.DONE and data(id).kind == QuestData.Kind.HUNT:
			hunted.append(data(id).target)
	return hunted


## Quest item -> how many a GATHER quest asks for, while the quest is taken or can be offered
## now and the bag holds fewer: those always drop in battle, the others never
## (BattleEngine.quest_items). Before reading the board a monkey still leaves its skin.
func wanted_items(state: GameState) -> Dictionary:
	var wanted := {}
	for id: String in QUESTS:
		var quest := data(id)
		if quest.kind != QuestData.Kind.GATHER:
			continue
		if stage(id) != Stage.ACTIVE and not _offered(quest, state.world_flags):
			continue
		if state.inventory.count(quest.target) < quest.goal:
			wanted[quest.target] = quest.goal
	return wanted


## What this figure says about the quests now, and what that does: every report it was
## waiting for, one after another, each with its payment (in QUESTS order); else a sought
## figure found, a new offer (taken), or the waiting lines of its first quest under way
## (short_wait: only the first line, the Jefe de caravana's rule). Returns {} when it has
## nothing to say about any, else {"lines": Array[String], "done": the titles finished,
## "kind": TALK_REPORT, TALK_FOUND, TALK_OFFER or TALK_WAIT}.
func talk(state: GameState, zone_id: String, figure: String, short_wait := false) -> Dictionary:
	var lines: Array[String] = []
	var done: Array[String] = []
	for id: String in QUESTS:
		var quest := data(id)
		if quest.turn_in_zone == zone_id and quest.turn_in == figure \
				and _is_ready(quest, state.inventory):
			lines.append_array(quest.done_lines)
			lines.append_array(_finish(state, quest))
			done.append(quest.title)
	if not done.is_empty():
		return {"lines": lines, "done": done, "kind": TALK_REPORT}
	for id: String in QUESTS:
		var quest := data(id)
		if quest.kind == QuestData.Kind.FIND and quest.target_zone == zone_id \
				and quest.target == figure and stage(id) == Stage.ACTIVE:
			_stages[id] = Stage.REPORT
			lines.assign(quest.found_lines)
			return {"lines": lines, "done": done, "kind": TALK_FOUND}
	for id: String in QUESTS:
		var quest := data(id)
		if quest.zone == zone_id and quest.giver == figure and _offered(quest, state.world_flags):
			accept(state, id)
			lines.assign(quest.offer_lines)
			return {"lines": lines, "done": done, "kind": TALK_OFFER}
	for id: String in QUESTS:
		var quest := data(id)
		if quest.turn_in_zone == zone_id and quest.turn_in == figure and is_active(id) \
				and not quest.wait_lines.is_empty():
			if short_wait:
				lines.append(quest.wait_lines[0])
			else:
				lines.assign(quest.wait_lines)
			if quest.goal > 1 and quest.kind in [QuestData.Kind.HUNT, QuestData.Kind.GATHER]:
				lines.append(PROGRESS_LINE % [_progress(quest, state.inventory), quest.goal])
			return {"lines": lines, "done": done, "kind": TALK_WAIT}
	return {}


## True if the quest may be offered now: still OPEN and its needs flag set.
func _offered(quest: QuestData, flags: Dictionary) -> bool:
	return stage(quest.id) == Stage.OPEN and (quest.needs == "" or flags.get(quest.needs, false))


## The figures of this zone with a report waiting for them.
func reports_here(zone_id: String, inventory: Inventory) -> Array[String]:
	var figures: Array[String] = []
	for id: String in QUESTS:
		var quest := data(id)
		if quest.turn_in_zone == zone_id and _is_ready(quest, inventory):
			figures.append(quest.turn_in)
	return figures


## Figure name -> mark, on this zone: "?" for a report waiting or a figure being sought, "!"
## for a new offer. "?" wins. The Abuela Rosa's are the village quest's.
func markers(zone_id: String, inventory: Inventory, flags := {}) -> Dictionary:
	var marks := {}
	for id: String in QUESTS:
		var quest := data(id)
		if quest.zone == zone_id and _offered(quest, flags):
			marks[quest.giver] = NEW_MARK
	if zone_id == VILLAGE_ZONE:
		if village.stage == Quest.Stage.OFFER:
			marks[Quest.NPC_NAME] = NEW_MARK
		elif village.stage == Quest.Stage.REPORT:
			marks[Quest.NPC_NAME] = REPORT_MARK
	for id: String in QUESTS:
		var quest := data(id)
		if quest.kind == QuestData.Kind.FIND and quest.target_zone == zone_id \
				and stage(id) == Stage.ACTIVE:
			marks[quest.target] = REPORT_MARK
	for figure in reports_here(zone_id, inventory):
		marks[figure] = REPORT_MARK
	return marks


## The sought figures of this zone that are not on the map now: only while being sought.
func hidden_figures(zone_id: String) -> Array[String]:
	var hidden: Array[String] = []
	for id: String in QUESTS:
		var quest := data(id)
		if quest.kind == QuestData.Kind.FIND and quest.target_zone == zone_id \
				and stage(id) != Stage.ACTIVE:
			hidden.append(quest.target)
	return hidden


## One line per side quest under way, leaving room for the main goal above them
## (GameState.current_missions() puts it first).
func status_lines(inventory: Inventory) -> Array[String]:
	var lines: Array[String] = []
	for id: String in QUESTS:
		if is_active(id):
			lines.append(STATUS_PREFIX + _status(data(id), inventory))
	var extra := lines.size() - (MAX_STATUS_LINES - 1)
	if extra > 0:
		lines.resize(MAX_STATUS_LINES - 1)
		lines.append(MORE_LINES % extra)
	return lines


## The missions of the v2 (the caravan's zones), the rest are the v1's (the Colección's
## "n/7" and "n/2").
static func is_v2(id: String) -> bool:
	return data(id).zone in ZoneData.V2_ZONES


## How many missions the v1 has (the village quest included) or the v2 has.
static func total_of(v2: bool) -> int:
	var total := 0 if v2 else 1
	for id: String in QUESTS:
		if is_v2(id) == v2:
			total += 1
	return total


## Missions finished of the v1 (the village quest included) or of the v2.
func done_of(v2: bool) -> int:
	var done := 1 if not v2 and village.stage == Quest.Stage.DONE else 0
	for id: String in QUESTS:
		if is_v2(id) == v2 and stage(id) == Stage.DONE:
			done += 1
	return done


## Missions finished, the village quest included: what the credits count.
func done_count() -> int:
	var done := 1 if village.stage == Quest.Stage.DONE else 0
	for id: String in QUESTS:
		if stage(id) == Stage.DONE:
			done += 1
	return done


## For the Diario: {"active": [{"title", "text"}], "done": [titles]}.
func journal(inventory: Inventory) -> Dictionary:
	var active: Array[Dictionary] = []
	var done: Array[String] = []
	var village_line := village.status_text()
	if village_line != "":
		active.append({"title": Quest.TITLE,
			"text": _sentence(village_line.trim_prefix(STATUS_PREFIX))})
	elif village.stage == Quest.Stage.DONE:
		done.append(Quest.TITLE)
	for id: String in QUESTS:
		var quest := data(id)
		if is_active(id):
			active.append({"title": quest.title, "text": _journal_text(quest, inventory)})
		elif stage(id) == Stage.DONE:
			done.append(quest.title)
	return {"active": active, "done": done}


## For the save: only the quests already taken.
func to_dict() -> Dictionary:
	var saved := {}
	for id: String in _stages:
		saved[id] = {"stage": _stages[id], "count": count(id)}
	return saved


## Loads what to_dict() wrote (JSON numbers come back as floats); unknown ids are dropped.
func set_from(saved: Dictionary) -> void:
	_stages = {}
	_counts = {}
	for id: String in saved:
		if not QUESTS.has(id):
			continue
		_stages[id] = clampi(int(saved[id].stage), Stage.OPEN, Stage.DONE) as Stage
		_counts[id] = int(saved[id].count)


## Time to go to the turn_in figure.
func _is_ready(quest: QuestData, inventory: Inventory) -> bool:
	match stage(quest.id):
		Stage.REPORT:
			return true
		Stage.ACTIVE:
			if quest.kind == QuestData.Kind.DELIVER:
				return true
			if quest.kind == QuestData.Kind.GATHER:
				return inventory.count(quest.target) >= quest.goal
	return false


## Takes what was asked for, marks it done and pays. Returns what the payment says.
func _finish(state: GameState, quest: QuestData) -> Array[String]:
	if quest.kind == QuestData.Kind.GATHER:
		for i in quest.goal:
			state.inventory.take(quest.target)
	if quest.key_item != "":
		state.key_items.erase(quest.key_item)
	if quest.done_flag != "":
		state.world_flags[quest.done_flag] = true
	_stages[quest.id] = Stage.DONE
	return QuestRewards.give(state, quest)


## HUNT and GATHER: how many of the goal so far.
func _progress(quest: QuestData, inventory: Inventory) -> int:
	if quest.kind == QuestData.Kind.GATHER:
		return mini(inventory.count(quest.target), quest.goal)
	return count(quest.id)


func _status(quest: QuestData, inventory: Inventory) -> String:
	if _is_ready(quest, inventory) and quest.report != "":
		return quest.report
	if quest.status.contains("%d"):
		return quest.status % [_progress(quest, inventory), quest.goal]
	return quest.status


func _journal_text(quest: QuestData, inventory: Inventory) -> String:
	if _is_ready(quest, inventory) and quest.report != "":
		return _sentence(quest.report)
	if quest.goal > 1:
		return "%s (%d / %d)" % [quest.objective, _progress(quest, inventory), quest.goal]
	return quest.objective


## text with a capital and a full stop, for a mission line said in the Diario.
static func _sentence(text: String) -> String:
	return "%s%s." % [text.left(1).to_upper(), text.substr(1)]


## A WARNING line for each quest whose report could get stuck: its turn_in figure is missing
## from turn_in_zone, is not one to talk to (a shop, an inn or a board opens something
## else), or may be off the map when the quest is ready (a needs flag that may come later
## than the quest's own, or any gone flag). Game prints them when it starts; none today.
static func problems() -> Array[String]:
	var found: Array[String] = []
	for id: String in QUESTS:
		var quest := data(id)
		if quest.turn_in == "":
			continue
		var zone := ZoneData.by_id(quest.turn_in_zone)
		var figure := {}
		if zone != null:
			for npc: Dictionary in zone.npcs:
				if npc.name == quest.turn_in:
					figure = npc
		if figure.is_empty():
			found.append("Misión %s: se entrega a %s, que no está en %s" % [id, quest.turn_in,
				quest.turn_in_zone])
			continue
		# a shop or an inn hears first what waits (Game, since 2.4.0)
		if not figure.get("kind", "npc") in ["npc", "quest", "inn", "shop"]:
			found.append("Misión %s: se entrega a %s, que no es una figura con quien hablar" \
				% [id, quest.turn_in])
			continue
		var needs: String = figure.get("needs", "")
		var may_miss: bool = figure.get("gone", "") != ""
		if needs != "" and needs != quest.needs and not _comes_before(needs, quest.needs):
			may_miss = true
		if may_miss:
			found.append("Misión %s: %s puede faltar cuando la misión está lista" % [id,
				quest.turn_in])
	return found


## True if flag a is always set before flag b in a game (both in FLAG_ORDER).
static func _comes_before(a: String, b: String) -> bool:
	return a in FLAG_ORDER and b in FLAG_ORDER and FLAG_ORDER.find(a) < FLAG_ORDER.find(b)
