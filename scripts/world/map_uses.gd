class_name MapUses extends Node
## What the hero can use on a map and how: the nearest thing in reach (a figure, a closed
## chest, a well, the return portal, and on a dungeon floor the lever, the key and the
## gates), the prompt that names it (MapHud shows it; the figure signs under it hide), a
## click or tap on one (walk there and use it on arrival), autoplay's talks (each villager
## once per visit) and the exits walked into. Each use is a signal, which World re-emits
## under the same name. Owned by World, which calls step() and check_exits() in its physics
## tick; never stores World.

signal talk_requested
signal npc_requested(index: int)
## A tienda (counter Shop.ITEMS_COUNTER) or an armero (Shop.ARMORY_COUNTER) of shop_id.
signal shop_requested(shop_id: String, counter: String)
signal inn_requested(inn_id: String)
signal chest_opened(chest_id: String)
signal well_requested(id: String, kind: String)
signal lever_pulled
signal key_taken
signal door_used
signal portal_used

## How close the player must be to talk to a figure / to open a chest / to drink / to take
## an exit.
const TALK_RADIUS := 2.5
const CHEST_RADIUS := 1.8
const WELL_RADIUS := 2.2
const EXIT_RADIUS := 1.2
## After arriving (or after a closed exit's notice) exits wait until the player is this
## much farther than EXIT_RADIUS from all of them.
const EXIT_REARM := 0.8
## How close the player must be to a lever, a key or a gate (its centre) to use it.
const MECHANISM_RADIUS := 2.2
## A click or tap this close to a figure or a chest means "go there and use it".
const NPC_TAP_RADIUS := 1.2
## A tap on a figure is measured at this height, so its feet and its head both count.
const TAP_HEIGHT := 0.9
## Height of a figure's head and hat, the other height a tap on one is measured at.
const FIGURE_TOP_TAP_HEIGHT := 2.2
## Narrow: the head is slim, and a wider circle up there takes taps on the ground behind it.
const FIGURE_TOP_TAP_RADIUS := 0.7
## Kinds of the things the player can use on the map, and their prompts.
const TALK := "talk"
const NPC := "npc"
const SHOP := "shop"
const ARMORY := "armory"
const INN := "inn"
const CHEST := "chest"
const WELL := "well"
const LEVER := "lever"
const KEY := "key"
const DOOR := "door"
const PORTAL := "portal"
const BOARD := "board"
const ITEM := "item"
## Between the verb and who it is done with: "Hablar · Granjero".
const PROMPT_JOIN := " · "
const PROMPTS := {
	TALK: "Hablar",
	NPC: "Hablar",
	SHOP: "Comprar",
	ARMORY: "Comprar",
	INN: "Descansar",
	CHEST: "Abrir",
	WELL: "Beber",
	LEVER: "Tirar",
	KEY: "Coger",
	DOOR: "Abrir",
	PORTAL: "Volver",
	BOARD: "Leer",
	ITEM: "Coger",
}
## ZoneData.npcs kinds -> use kinds.
const NPC_KINDS := {"quest": TALK, "npc": NPC, "shop": SHOP, "armory": ARMORY, "inn": INN,
	"board": BOARD, "item": ITEM}

var _zone: ZoneData
var _player: Player
var _camera: FollowCamera
var _hud: MapHud
var _figures: MapFigures
var _props: MapProps
## The cells of a dungeon floor (null on an open map): its lever, key and gates.
var _dungeon: DungeonMap
var _autoplay := false
## The world flags (World.set_world_flags(); the same Dictionary).
var _flags := {}
## ZoneData.all_exits(): the arches and, on a dungeon floor, the stairs.
var _exits: Array = []
var _exits_armed := false
## What was in reach last frame ({} for nothing), so autoplay acts once per approach.
var _was_near := {}
## Set by a click or tap on a figure or chest: use it as soon as it is in reach.
var _use_on_arrival := {}
## Autoplay only: npc indexes already talked to on this map.
var _autoplay_talked := {}
## The figure signs the prompt is covering right now (hidden until it goes).
var _signs_under_prompt: Array[Label3D] = []


func setup(zone: ZoneData, player: Player, camera: FollowCamera, hud: MapHud,
		figures: MapFigures, props: MapProps, dungeon: DungeonMap) -> void:
	_zone = zone
	_player = player
	_camera = camera
	_hud = hud
	_figures = figures
	_props = props
	_dungeon = dungeon
	_autoplay = RunFlags.autoplay()
	_exits = _zone.all_exits()


func set_flags(flags: Dictionary) -> void:
	_flags = flags


## Every physics tick (World), last: the prompt for what is in reach, the use a tap asked
## for once it is in reach, and autoplay's uses.
func step(pos: Vector3) -> void:
	var near := _nearest_use(pos)
	if near.is_empty():
		hide_prompt()
	else:
		_show_prompt(near)
	if not _use_on_arrival.is_empty() and _in_reach(_use_on_arrival):
		var errand := _use_on_arrival
		_use_on_arrival = {}
		_player.move_target = null
		_use(errand)
	elif not near.is_empty() and near != _was_near and _autoplay and near.kind != PORTAL:
		# Autoplay talks to each villager once per visit to the zone, and again when a
		# mark over it says there is something new.
		var chats: bool = near.kind in [NPC, BOARD, ITEM]
		if not chats or not _autoplay_talked.has(near.index) \
				or _figures.has_mark(_zone.npcs[near.index].name):
			_autoplay_talked[near.index] = true
			_use(near)
	_was_near = near


## Enter, Space or the phone's use button: uses what is nearest now.
func use_nearest() -> void:
	_use(_nearest_use(_player.global_position))


## A click or tap at a screen point: what is there is used once the hero reaches it.
func aim_at(screen: Vector2) -> void:
	_use_on_arrival = _tapped_use(screen)


## The tap's errand is dropped (the hero walks off by hand, a placing, a cutscene).
func drop_errand() -> void:
	_use_on_arrival = {}


## What was in reach is forgotten (a placing, the end of a cutscene): autoplay may act again.
func forget_near() -> void:
	_was_near = {}


## The exits wait until the hero steps away from them (a placing).
func disarm_exits() -> void:
	_exits_armed = false


## A cutscene hides every figure sign itself: none is waiting for the prompt to go.
func forget_covered_signs() -> void:
	_signs_under_prompt.clear()


## What the prompt (or the phone's use button) says: the verb and, for a figure, its name.
func _prompt_text(use: Dictionary) -> String:
	var text: String = PROMPTS[use.kind]
	if use.index >= 0:
		text += PROMPT_JOIN + String(_zone.npcs[use.index].name)
	return text


func _show_prompt(near: Dictionary) -> void:
	_clear_signs_under(_hud.show_prompt(_prompt_text(near), _action_key_name()))


## Hides the figure signs that would sit under the prompt (or the use button), so the two
## never overlap; they come back with the prompt.
func _clear_signs_under(rect: Rect2) -> void:
	var area := rect.grow(8.0)
	for label in _figures.signs:
		var covered := not _camera.is_position_behind(label.global_position) \
			and area.has_point(_camera.unproject_position(label.global_position))
		if covered and label.visible:
			label.hide()
			_signs_under_prompt.append(label)
		elif not covered and label in _signs_under_prompt:
			label.show()
			_signs_under_prompt.erase(label)


func _restore_signs() -> void:
	for label in _signs_under_prompt:
		if is_instance_valid(label):
			label.show()
	_signs_under_prompt.clear()


## The key shown under the prompt: E while it is one of the accept keys, else the first one.
func _action_key_name() -> String:
	var codes := KeyMap.keys_of("accept")
	if codes.is_empty() or KEY_E in codes:
		return KeyMap.keys_text("accept") if codes.is_empty() else KeyMap.key_name(KEY_E)
	return KeyMap.key_name(codes[0])


func hide_prompt() -> void:
	_restore_signs()
	_hud.hide_prompt()


func prompt_showing() -> bool:
	return _hud.prompt_showing()


## The open exit the player walked into ({} for none; World then freezes the map and emits
## exit_requested), or a closed one's notice once per approach. Exits only count once the
## player has stepped away from all of them since arriving.
func check_exits(pos: Vector3) -> Dictionary:
	var nearest := {}
	var nearest_d := INF
	for exit: Dictionary in _exits:
		if not ZoneData.is_present(exit, _flags):
			continue
		var d := _flat_distance(pos, exit.pos)
		if d < nearest_d:
			nearest = exit
			nearest_d = d
	if nearest.is_empty():
		return {}
	if not _exits_armed:
		_exits_armed = nearest_d > EXIT_RADIUS + EXIT_REARM
		return {}
	if nearest_d > EXIT_RADIUS:
		return {}
	_exits_armed = false
	if not MapProps.is_open(nearest, _flags):
		_hud.show_notice(nearest.lock_text, "Cerrado")
		return {}
	return nearest


## The nearest thing in reach of pos that can be used: {"kind": TALK / NPC / SHOP / ARMORY / INN
## / CHEST / LEVER / KEY / DOOR, "id": shop, inn or chest id ("" otherwise), "index":
## the npc's index}, or {}.
func _nearest_use(pos: Vector3) -> Dictionary:
	var best := {}
	var best_d := INF
	for use in _uses():
		var d := _flat_distance(pos, use.pos)
		if d <= use.radius and d < best_d:
			best = {"kind": use.kind, "id": use.id, "index": use.index}
			best_d = d
	return best


## The thing a click or tap at a screen point means ({} if none): within NPC_TAP_RADIUS of it
## at TAP_HEIGHT, or, for a figure, at FIGURE_TOP_TAP_HEIGHT too.
func _tapped_use(screen: Vector2) -> Dictionary:
	var origin := _camera.project_ray_origin(screen)
	var normal := _camera.project_ray_normal(screen)
	var low: Variant = Plane(Vector3.UP, TAP_HEIGHT).intersects_ray(origin, normal)
	var high: Variant = Plane(Vector3.UP, FIGURE_TOP_TAP_HEIGHT).intersects_ray(origin, normal)
	if low == null or high == null:
		return {}
	for use in _uses():
		var on_top: bool = use.kind in NPC_KINDS.values() \
			and _flat_distance(high, use.pos) <= FIGURE_TOP_TAP_RADIUS
		if on_top or _flat_distance(low, use.pos) <= NPC_TAP_RADIUS:
			return {"kind": use.kind, "id": use.id, "index": use.index}
	return {}


## Whether a use asked for by a tap is in reach of the hero now.
func _in_reach(wanted: Dictionary) -> bool:
	for use in _uses():
		if use.kind == wanted.kind and use.id == wanted.id and use.index == wanted.index:
			return _flat_distance(_player.global_position, use.pos) <= use.radius
	return false


## Everything usable now: the zone's figures, its closed chests and, on a dungeon floor,
## the lever until pulled, the key until taken and the gates while closed.
func _uses() -> Array[Dictionary]:
	var uses: Array[Dictionary] = []
	for i in _zone.npcs.size():
		var npc: Dictionary = _zone.npcs[i]
		if _figures.hidden.has(npc.name):
			continue
		uses.append({"kind": NPC_KINDS[npc.kind], "id": npc.get("id", ""), "index": i,
			"pos": npc.pos, "radius": TALK_RADIUS})
	for id in _props.closed_chests():
		uses.append({"kind": CHEST, "id": id, "index": -1, "pos": Chests.CHESTS[id].pos,
			"radius": CHEST_RADIUS})
	if _props.has_portal():
		uses.append({"kind": PORTAL, "id": "", "index": -1, "pos": _zone.portal_pos,
			"radius": MECHANISM_RADIUS})
	for well: Dictionary in _zone.wells:
		uses.append({"kind": WELL, "id": well.id, "index": -1, "pos": well.pos,
			"radius": WELL_RADIUS})
	if _dungeon == null:
		return uses
	var mechanisms := [[ZoneData.LEVER, LEVER, _zone.lever_flag],
		[ZoneData.KEY, KEY, _zone.floor_key], [ZoneData.DOOR, DOOR, _zone.door_flag]]
	for mechanism in mechanisms:
		if mechanism[2] == "" or _flags.get(mechanism[2], false):
			continue
		for cell in _zone.find_cells(mechanism[0]):
			uses.append({"kind": mechanism[1], "id": "", "index": -1,
				"pos": _zone.cell_center(cell), "radius": MECHANISM_RADIUS})
	return uses


func _use(use: Dictionary) -> void:
	match use.get("kind", ""):
		TALK:
			talk_requested.emit()
		NPC, BOARD, ITEM:
			npc_requested.emit(use.index)
		SHOP:
			shop_requested.emit(use.id, Shop.ITEMS_COUNTER)
		ARMORY:
			shop_requested.emit(use.id, Shop.ARMORY_COUNTER)
		INN:
			inn_requested.emit(use.id)
		CHEST:
			chest_opened.emit(use.id)
		WELL:
			well_requested.emit(use.id, _props.well_kind(use.id))
		LEVER:
			lever_pulled.emit()
		KEY:
			key_taken.emit()
		DOOR:
			door_used.emit()
		PORTAL:
			portal_used.emit()


static func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))
