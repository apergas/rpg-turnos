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


## What this figure says about a quest now, and what that does: a report it was waiting for
## (paid at once), a sought figure found, a new offer (taken), else its waiting lines.
## Returns {"lines": Array[String], "done": title of the quest finished or ""}, or {} when
## it has nothing to say about any.
func talk(state: GameState, zone_id: String, figure: String) -> Dictionary:
	if figure in reports_here(zone_id, state.inventory):
		for id: String in QUESTS:
			var quest := data(id)
			if quest.turn_in_zone == zone_id and quest.turn_in == figure \
					and _is_ready(quest, state.inventory):
				var lines: Array[String] = quest.done_lines.duplicate()
				lines.append_array(_finish(state, quest))
				return {"lines": lines, "done": quest.title}
	for id: String in QUESTS:
		var quest := data(id)
		if quest.kind == QuestData.Kind.FIND and quest.target_zone == zone_id \
				and quest.target == figure and stage(id) == Stage.ACTIVE:
			_stages[id] = Stage.REPORT
			return {"lines": quest.found_lines.duplicate(), "done": ""}
	for id: String in QUESTS:
		var quest := data(id)
		if quest.zone == zone_id and quest.giver == figure and _offered(quest, state.world_flags):
			accept(state, id)
			return {"lines": quest.offer_lines.duplicate(), "done": ""}
	for id: String in QUESTS:
		var quest := data(id)
		if quest.turn_in_zone == zone_id and quest.turn_in == figure and is_active(id) \
				and not quest.wait_lines.is_empty():
			var lines: Array[String] = quest.wait_lines.duplicate()
			if quest.goal > 1 and quest.kind in [QuestData.Kind.HUNT, QuestData.Kind.GATHER]:
				lines.append(PROGRESS_LINE % [_progress(quest, state.inventory), quest.goal])
			return {"lines": lines, "done": ""}
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


## Every mission of the game, the village quest included (the Colección's "n/7").
static func total_count() -> int:
	return QUESTS.size() + 1


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
