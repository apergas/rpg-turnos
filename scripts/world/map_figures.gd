class_name MapFigures extends Node3D
## The figures of a map (ZoneData.npcs, and the boss World asks for with add_figure()):
## each a BattleActor on a cylinder collider, with its sign ("Tienda", "Posada", "Criaturas",
## or its own "sign": "Coleccionista", "Tablón"...) and the "!" or "?" of the quests over it;
## the figures a quest has not brought out are off the map. Cutscenes find and move them here
## (figure_node(), figure_turn(), figure_actor(), reset_figures()). Owned by World, which calls
## setup(), adds it and then build(); never stores World.

const ACTOR_SCENE := preload("res://scenes/battle/battle_actor.tscn")
## The "!" and "?" of the quests: over the figure, bobbing.
const QUEST_MARK_GAP := 0.35
const QUEST_MARK_BOB := 0.12
## A quest mark over a figure with a sign ("Posada") goes above the sign.
const FIGURE_SIGN_RISE := 0.65
const FIGURE_SIGN_GAP := 0.25
const FIGURE_SIGN_PIXEL := 0.012

## The figures that are not on the map now (set_quest_view()): nothing to use there.
var hidden: Array[String]:
	get:
		return _hidden_figures
## The signs over the figures (MapUses hides the ones under the prompt).
var signs: Array[Label3D]:
	get:
		return _figure_signs

var _zone: ZoneData
var _player: Player
## ZoneData.npcs "name" -> its figure (a StaticBody3D with the BattleActor under it).
var _figures := {}
## Figure name -> "!" or "?", the figures that are not on the map, and the labels so far.
var _quest_marks := {}
var _hidden_figures: Array[String] = []
var _mark_labels := {}
var _figure_signs: Array[Label3D] = []


func setup(zone: ZoneData, player: Player) -> void:
	_zone = zone
	_player = player


## A figure and its sign for every ZoneData.npcs entry.
func build() -> void:
	for npc: Dictionary in _zone.npcs:
		_figures[npc.name] = add_figure(BattleActor.Look[npc.look], npc.pos, npc.yaw, 0.4,
			1.8)
		_add_figure_sign(npc)


func has_mark(figure_name: String) -> bool:
	return _quest_marks.has(figure_name)


## Every figure sign shown (true) or hidden (false): cutscenes hide them.
func set_signs_shown(on: bool) -> void:
	for label in _figure_signs:
		label.visible = on


## The lines figure zone.npcs[index] says in chapter (StoryState.Chapter): its
## lines_by_chapter entry with the highest chapter not past it, else its lines.
func npc_lines(index: int, chapter: int) -> Array[String]:
	var npc: Dictionary = _zone.npcs[index]
	var lines: Array[String] = []
	lines.assign(npc.get("lines", []))
	var by_chapter: Dictionary = npc.get("lines_by_chapter", {})
	var best := -1
	for key: int in by_chapter:
		if key <= chapter and key > best:
			best = key
			lines.assign(by_chapter[key])
	return lines


## The node a cutscene moves for who ("hero" or a figure's name; null if none here).
func figure_node(who: String) -> Node3D:
	if who == Cutscene.HERO:
		return _player
	return _figures.get(who)


## The node a cutscene turns for who: the hero's model, or the figure itself.
func figure_turn(who: String) -> Node3D:
	if who == Cutscene.HERO:
		return _player.model()
	return _figures.get(who)


## The BattleActor of who (walking and cheering), null if none here.
func figure_actor(who: String) -> BattleActor:
	if who == Cutscene.HERO:
		return _player.model()
	var body: Node3D = _figures.get(who)
	if body == null:
		return null
	for child in body.get_children():
		if child is BattleActor:
			return child
	return null


## Every figure back on its ZoneData spot and yaw, standing still.
func reset_figures() -> void:
	for npc: Dictionary in _zone.npcs:
		var body: Node3D = _figures[npc.name]
		body.position = npc.pos
		body.rotation_degrees.y = npc.yaw
		var actor := figure_actor(npc.name)
		if actor:
			actor.set_walking(false)


## What the quests show on this map (Game passes GameState.quests' answers): marks is figure
## name -> "!" or "?"; hidden_names are figures not on the map now, with no collider and
## nothing to use.
func set_quest_view(marks: Dictionary, hidden_names: Array[String]) -> void:
	_quest_marks = marks
	_hidden_figures = hidden_names
	for npc: Dictionary in _zone.npcs:
		var body: StaticBody3D = _figures[npc.name]
		var shown := not hidden_names.has(npc.name)
		body.visible = shown
		body.process_mode = Node.PROCESS_MODE_INHERIT if shown else Node.PROCESS_MODE_DISABLED
	show_marks()


## One floating label per figure with a mark; none during a cutscene.
func show_marks() -> void:
	for npc: Dictionary in _zone.npcs:
		var text: String = _quest_marks.get(npc.name, "")
		var label: Label3D = _mark_labels.get(npc.name)
		if label == null:
			if text == "":
				continue
			label = _build_mark(npc.name)
		label.text = text
		label.visible = text != "" and not _player.scripted


## What a figure offers, over its head: its model alone doesn't tell. Its own "sign"
## (ZoneData.npcs) first, else the shop's, the armero's or the inn's by its kind; "" for none.
static func _figure_sign_text(npc: Dictionary) -> String:
	if npc.has("sign"):
		return npc.sign
	match npc.kind:
		"shop":
			return "Criaturas" if Shop.sells_ally(npc.id) else "Tienda"
		"armory":
			return "Armero"
		"inn":
			return "Posada"
	return ""


func _add_figure_sign(npc: Dictionary) -> void:
	var text := _figure_sign_text(npc)
	if text == "":
		return
	var label := Label3D.new()
	label.text = text
	UiTheme.style_3d(label, &"display-m", &"text-display-soft", UiTokens.OUTLINE_L)
	label.pixel_size = FIGURE_SIGN_PIXEL
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.position.y = figure_actor(npc.name).top_height() + FIGURE_SIGN_GAP
	(_figures[npc.name] as Node3D).add_child(label)
	_figure_signs.append(label)


func _build_mark(figure_name: String) -> Label3D:
	var label := Label3D.new()
	UiTheme.style_3d(label, &"display-xl", &"quest-mark", UiTokens.OUTLINE_M)
	label.pixel_size = 0.01
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.position.y = figure_actor(figure_name).top_height() + QUEST_MARK_GAP
	for npc: Dictionary in _zone.npcs:
		if npc.name == figure_name and _figure_sign_text(npc) != "":
			label.position.y += FIGURE_SIGN_RISE
	(_figures[figure_name] as Node3D).add_child(label)
	_mark_labels[figure_name] = label
	var bob := label.create_tween().set_loops()
	bob.tween_property(label, "position:y", label.position.y + QUEST_MARK_BOB, 0.5) \
		.set_trans(Tween.TRANS_SINE)
	bob.tween_property(label, "position:y", label.position.y, 0.5).set_trans(Tween.TRANS_SINE)
	return label


## A figure: a BattleActor on a cylinder collider, turned yaw_deg (180 faces south,
## toward the camera).
func add_figure(look: BattleActor.Look, pos: Vector3, yaw_deg: float, radius: float, \
		height: float) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	body.rotation_degrees.y = yaw_deg
	add_child(body)
	WorldStage.add_cylinder_shape(body, radius, height)
	var actor: BattleActor = ACTOR_SCENE.instantiate()
	actor.look = look
	body.add_child(actor)
	return body
