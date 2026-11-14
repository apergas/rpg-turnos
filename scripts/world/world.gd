class_name World extends Node3D
## One map of the world, built from `zone` (a ZoneData, set before add_child; the
## meadow if none): field, village, figures, boss, chests, exits, player, follow camera,
## status window and the groups of monsters walking on it (MonsterGroups, MonsterRoam): touching one starts its battle (encounter_triggered(false), contact_enemies(), end_contact()). A click or tap on the ground (held and dragged
## too) walks the player there, with a marker on the spot. Next to a figure or a closed
## chest (the nearest one in reach) Enter / Space talks to the old woman
## (talk_requested) or to a villager (npc_requested), opens the shop (shop_requested),
## asks for a room (inn_requested) or opens the chest (chest_opened); a click or tap on
## one of them walks there and does it on arrival. With the boss present, walking into
## it starts the boss battle. Walking into an open exit (or onto the stairs of a dungeon
## floor) emits exit_requested; a closed one (its world flag not set: set_world_flags())
## shows its fog and its notice. With set_portal(true) the zone's portal_pos holds the
## return portal of an Ala de viaje, used like a figure (portal_used); set_return_mark()
## shows on the ground the spot it leads back to. Under the status window a MapSquare shows
## what has been seen of the zone (set_explored()); a tap on it emits map_requested. A dungeon floor (ZoneData.layout) is a
## DungeonMap: its
## rock blocks turn see-through between the camera and the hero, the hero carries a
## lantern underground, and next to the lever, the key or a locked gate Enter / Space
## pulls it (lever_pulled), takes it (key_taken) or tries the gate (door_used).
## The zone's particles (ZoneParticles) float around the hero.
## Battles and exits freeze the player until set_active(true) (or until Game frees
## the map). A "!" or "?" floats over a figure with something about a quest, and a figure a
## quest has not brought out is not on the map (set_quest_view()). Run on its own
## (res://scenes/world/world.tscn) it prints each group touched (and takes it off), each talk, shop, inn, chest and exit
## and goes on.

signal encounter_triggered(boss: bool)
signal talk_requested
## The player talked to the villager zone.npcs[index] (kind "npc") or read the board (kind
## "board").
signal npc_requested(index: int)
## The player asked the merchant of shop_id (a Shop.SHOPS key) to trade.
signal shop_requested(shop_id: String)
## The player talked to the innkeeper of inn_id (an Inn.INNS key).
signal inn_requested(inn_id: String)
## The player asked to open a closed chest (a Chests.CHESTS key); Game opens it in the
## GameState and calls set_chest_open().
signal chest_opened(chest_id: String)
## The player drank (or tried to) from the well id, which fills kind (Wells.HP or Wells.MP).
signal well_requested(id: String, kind: String)
## The player walked into (true) or out of (false) the village clearing.
signal village_changed(inside: bool)
## The player walked into an open exit: Game loads zone_id at its entry entry_id.
signal exit_requested(zone_id: String, entry_id: String)
## The player used the return portal: Game takes them back.
signal portal_used
## Dungeon floors: the player pulled the lever, took the key or tried a locked gate.
signal lever_pulled
signal key_taken
signal door_used
## Every STEP_DISTANCE metres walked (two steps of the hero; the game's step count).
signal stepped
## The player tapped the map square: Game opens the pause menu's Mapa page.
signal map_requested

const PLAYER_SCENE := preload("res://scenes/world/player.tscn")
const HERO_DATA := preload("res://data/hero.tres")
const BANNER_FADE := MapHud.BANNER_FADE
## How close the player must be to talk to a figure / to open a chest / to run into the
## boss / to take an exit.
const TALK_RADIUS := 2.5
const CHEST_RADIUS := 1.8
const WELL_RADIUS := 2.2
const BOSS_RADIUS := 2.5
## After a boss battle the boss waits until the hero has been this far from it (a boss
## fought again and again, the Eco de la Niebla, must not start over at once).
const BOSS_REARM_RADIUS := 5.0
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
## Taps on the map are ignored this long after a dialogue or a window closes.
const TAP_GUARD_MS := 400
## Kinds of the things the player can use on the map, and their prompts.
const TALK := "talk"
const NPC := "npc"
const SHOP := "shop"
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
const NPC_KINDS := {"quest": TALK, "npc": NPC, "shop": SHOP, "inn": INN, "board": BOARD, "item": ITEM}
## Meters walked between two footstep sounds.
const STEP_DISTANCE := 1.6
## Underground the hero carries a lantern: a warm light over the head.
const LANTERN_COLOR := Color(1.0, 0.85, 0.65)
const LANTERN_ENERGY := 2.0
const LANTERN_RANGE := 10.0
const LANTERN_HEIGHT := 2.4
## Autoplay: below the zone's autoplay_boss_level the hero leaves the route for the
## nearest group this close that can start a battle, gives up after AUTOPLAY_HUNT_MS (or
## stuck on the way, Player.take_failed_hunt()) and leaves that one alone for
## AUTOPLAY_HUNT_RETRY_MS.
const AUTOPLAY_HUNT_RADIUS := 60.0
const AUTOPLAY_HUNT_RADIUS_CAVE := 12.0  # walls: a straight line to a far group fails
const AUTOPLAY_HUNT_MS := 15000
const AUTOPLAY_HUNT_RETRY_MS := 20000

## The map to build; set before add_child.
var zone: ZoneData
## The boss to stand at zone.boss_pos (EnemyLibrary id); set before add_child. "" takes
## zone.boss_id. Game passes the Eco de la Niebla once the game is finished.
var boss_id := ""

var _hud: MapHud
var _props: MapProps
var _monsters: MapMonsters

var _grass: ShaderMaterial
var _player: Player
var _camera: FollowCamera
var _boss: StaticBody3D
## The figures (npcs and the boss), their signs and quest marks.
var _figures: MapFigures
## What a cutscene's camera looks at (camera_to); null until the first one.
var _camera_spot: Node3D
## ZoneData.all_exits(): the arches and, on a dungeon floor, the stairs.
var _exits: Array = []
## The cells of a dungeon floor (null on an open map).
var _dungeon: DungeonMap
var _flags := {}
var _exits_armed := false
var _boss_present := false
## False from a boss battle until the hero walks BOSS_REARM_RADIUS away from the boss.
var _boss_armed := true
var _autoplay := false
var _waiting := false
var _talking := false
## What was in reach last frame ({} for nothing), so autoplay acts once per approach.
var _was_near := {}
## Set by a click or tap on a figure or chest: use it as soon as it is in reach.
var _use_on_arrival := {}
## Taps on the map count from this time on (Time.get_ticks_msec()).
var _taps_from_ms := 0
## Autoplay only: npc indexes already talked to on this map.
var _autoplay_talked := {}
var _audio: AudioDirector
var _in_village := false
var _step_m := 0.0
## The figure signs the prompt is covering right now (hidden until it goes).
var _signs_under_prompt: Array[Label3D] = []
## The zone's ZoneParticles (null: none, or low quality), carried with the hero.
var _particles: Node3D
## Autoplay: hunt groups (Game: below the zone's autoplay_boss_level), until when the one
## hunted now is followed, and group instance id -> the time until which it is left alone.
var _hunt_on := false
var _hunt_until_ms := 0
## Time of the simulation in ms (the hunt's timers count it, so a run with --fixed-fps keeps them).
var _sim_ms := 0.0
var _hunt_skip := {}
## DebugPanel's Monstruos (MapMonsters.debug_no_groups): Game and DebugPanel use this name.
static var debug_no_groups: bool:
	get:
		return MapMonsters.debug_no_groups
	set(value):
		MapMonsters.debug_no_groups = value


func _ready() -> void:
	UiTheme.ensure(get_window())
	if zone == null:
		zone = ZoneData.by_id("pradera")
	_autoplay = RunFlags.autoplay()
	_grass = WorldStage.build(self, zone)
	if zone.is_dungeon():
		_dungeon = DungeonMap.new()
		_dungeon.zone = zone
		add_child(_dungeon)
	_hud = MapHud.new()
	_hud.setup(zone)
	_player = PLAYER_SCENE.instantiate()
	_figures = MapFigures.new()
	_figures.setup(zone, _player)
	_monsters = MapMonsters.new()
	_monsters.setup(zone, _player)
	_monsters.groups_reset.connect(func() -> void: _hunt_skip.clear())
	add_child(_figures)
	_figures.build()
	if boss_id == "":
		boss_id = zone.boss_id
	if boss_id != "":
		_boss = _figures.add_figure(EnemyLibrary.look(boss_id), zone.boss_pos, 180.0, 1.0, 2.0)
	_props = MapProps.new()
	_props.setup(zone)
	add_child(_props)
	_props.build()
	_exits = zone.all_exits()
	set_boss_present(false)
	set_world_flags({})
	_player.route = zone.autoplay_route
	add_child(_player)
	if zone.underground:
		var lantern := OmniLight3D.new()
		lantern.light_color = LANTERN_COLOR
		lantern.light_energy = LANTERN_ENERGY
		lantern.omni_range = LANTERN_RANGE
		lantern.position.y = LANTERN_HEIGHT
		_player.add_child(lantern)
	_particles = ZoneParticles.build(zone.particles)
	if _particles:
		add_child(_particles)
	_camera = FollowCamera.new()
	add_child(_camera)
	_camera.target = _player
	_props.build_marker()
	_hud.map_pressed.connect(_on_map_pressed)
	_hud.tapped.connect(_on_tapped)
	_hud.pinched.connect(_camera.zoom_by)
	_hud.use_pressed.connect(func() -> void: _use(_nearest_use(_player.global_position)))
	add_child(_hud)
	set_explored(ExploredMap.new(zone))
	add_child(_monsters)
	place_at_entry(zone.start_entry)
	respawn_groups()
	_camera.current = true
	if get_parent() == get_tree().root:
		_connect_standalone()


func _physics_process(delta: float) -> void:
	_sim_ms += delta * 1000.0
	var pad := _hud.pad
	if pad:
		_player.stick_direction = pad.direction
		if pad.direction != Vector2.ZERO:
			_use_on_arrival = {}  # walking off by hand drops the tap's errand
	if _grass:
		Vegetation.set_pusher(_grass, _player.global_position)
	if _particles:
		ZoneParticles.follow(_particles, _player.global_position)
	_hud.step(_player.global_position, _player.last_step_m)
	_props.show_marker(_player.move_target)
	if _dungeon:
		_dungeon.see_through(_camera.global_position, _player.global_position)
	_monsters.move_groups(delta)
	if _waiting or _talking:
		return
	_monsters.tick_refill(delta)
	var pos := _player.global_position
	var inside := _is_in_village(pos)
	if inside != _in_village:
		_in_village = inside
		village_changed.emit(inside)
	_play_steps()
	if _check_exits(pos):
		return
	if _boss_present:
		var boss_distance := _flat_distance(pos, zone.boss_pos)
		if not _boss_armed:
			_boss_armed = boss_distance > BOSS_REARM_RADIUS
		elif boss_distance <= BOSS_RADIUS:
			_trigger(true)
			return
	if _monsters.check_contact(pos, int(_sim_ms)):
		_trigger(false)
		return
	if _autoplay and _hunt_on and not _monsters.is_repelled():
		_update_hunt(pos)
	var near := _nearest_use(pos)
	if near.is_empty():
		_hide_prompt()
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
				or _figures.has_mark(zone.npcs[near.index].name):
			_autoplay_talked[near.index] = true
			_use(near)
	_was_near = near


func _unhandled_input(event: InputEvent) -> void:
	if _waiting or _talking:
		return
	if _prompt_showing() and event.is_action_pressed("ui_accept") and not event.is_echo():
		get_viewport().set_input_as_handled()
		_use(_nearest_use(_player.global_position))
		return
	var pad := _hud.pad
	if pad:
		if pad.handle(event):
			get_viewport().set_input_as_handled()
		return  # the mouse events left are the touches again
	var point: Variant = _pointer_on_ground(event)
	if point == null or Time.get_ticks_msec() < _taps_from_ms:
		return
	get_viewport().set_input_as_handled()
	if event is InputEventMouseButton:
		_use_on_arrival = _tapped_use((event as InputEventMouseButton).position)
	_player.move_to(point)


## Where a left click, a drag with the left button held, or a tap (the engine turns
## touches into mouse events) hits the ground plane; null for any other event.
func _pointer_on_ground(event: InputEvent) -> Variant:
	var screen: Vector2
	var button := event as InputEventMouseButton
	var motion := event as InputEventMouseMotion
	if button != null and button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
		screen = button.position
	elif motion != null and motion.button_mask & MOUSE_BUTTON_MASK_LEFT:
		screen = motion.position
	else:
		return null
	return _ground_point(screen)


## Where the camera's line through a screen point meets the ground plane.
func _ground_point(screen: Vector2) -> Variant:
	var ground := Plane(Vector3.UP, 0.0)
	return ground.intersects_ray(_camera.project_ray_origin(screen),
		_camera.project_ray_normal(screen))


## A tap on the ground (phones): walk there, and use what is there once in reach.
func _on_tapped(screen: Vector2) -> void:
	if Time.get_ticks_msec() < _taps_from_ms:
		return
	var point: Variant = _ground_point(screen)
	if point == null:
		return
	_use_on_arrival = _tapped_use(screen)
	_player.move_to(point)


## Shows what is in reach: the prompt, or on phones the use button.
## What the prompt (or the phone's use button) says: the verb and, for a figure, its name.
func _prompt_text(use: Dictionary) -> String:
	var text: String = PROMPTS[use.kind]
	if use.index >= 0:
		text += PROMPT_JOIN + String(zone.npcs[use.index].name)
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


func _hide_prompt() -> void:
	_restore_signs()
	_hud.hide_prompt()


func _prompt_showing() -> bool:
	return _hud.prompt_showing()


## Forgets the fingers on the map (a window, a battle or a cutscene took over).
func _reset_pad() -> void:
	_hud.reset_pad()


## The map square was tapped: the Mapa page, unless a window or a battle holds the map.
func _on_map_pressed() -> void:
	if not _talking and not _waiting:
		map_requested.emit()


## Hidden and frozen while a battle is on top; back on, no group starts a battle for MonsterGroups.CALM_MS.
func set_active(active: bool) -> void:
	process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	visible = active
	_hud.visible = active
	_camera.current = active
	_reset_pad()
	if active:
		_calm()
		_waiting = false
		_player.input_enabled = true


## Puts the player at one of the zone's entries (ZoneData.entry()).
func place_at_entry(entry_id: String) -> void:
	var entry := zone.entry(entry_id)
	place_player(entry[0], entry[1])


## Puts the player at pos facing yaw_deg (0 faces north; a loaded game faces north),
## with the groups calm for a moment (_calm()) and the exits waiting until the player steps
## away from them. in_village() is right at once; village_changed is not emitted.
func place_player(pos: Vector3, yaw_deg := 0.0) -> void:
	_player.place(pos, deg_to_rad(yaw_deg))
	_camera.snap()
	if _particles:
		ZoneParticles.follow(_particles, _player.global_position, true)
	_calm()
	_was_near = {}
	_use_on_arrival = {}
	_step_m = 0.0
	_exits_armed = false
	_in_village = _is_in_village(pos)


func player_position() -> Vector3:
	return _player.global_position


func in_village() -> bool:
	return _in_village


## Footsteps, encounter and dialogue sounds. Without it the map is silent.
func set_audio(audio: AudioDirector) -> void:
	_audio = audio
	_hud.dialogue.set_audio(audio)


## Shows or removes the zone's boss; when absent it has no collision.
func set_boss_present(present: bool) -> void:
	if _boss == null:
		return
	_boss_present = present
	_boss.visible = present
	_boss.process_mode = Node.PROCESS_MODE_INHERIT if present else Node.PROCESS_MODE_DISABLED


## The world progress (GameState.world_flags): which exits are open (their fog hides),
## what the villagers say and, on a dungeon floor, the gates, the lever and the key.
func set_world_flags(flags: Dictionary) -> void:
	_flags = flags
	_monsters.set_flags(flags)
	_props.set_flags(flags)
	if _dungeon:
		_dungeon.set_flags(flags)
	_refresh_map_marks()


## What has been seen of this zone, for the map square (Game passes GameState's; run on
## its own the map keeps its own).
func set_explored(map: ExploredMap) -> void:
	_hud.set_explored(map)
	_refresh_map_marks()


## The map square's points of interest (MapMarks): they follow the dry wells and, on a
## dungeon floor, the lever, the gates and the key.
func _refresh_map_marks() -> void:
	_hud.refresh_map_marks(_flags, _props.dry_wells)


## The hero is EncounterMeter.LEVEL_GAP levels past the zone (EncounterMeter.is_shy()): the
## groups that move keep away from him; the still ones stay. They can still be touched.
func set_monsters_shy(on: bool) -> void:
	_monsters.set_shy(on)


## An Incienso burning: touching a group starts no battle and every group shows half
## see-through (the boss still waits where it is).
func set_repel(on: bool) -> void:
	_monsters.set_repel(on, int(_sim_ms))


## Autoplay: hunt the groups (Game: while the hero is below the zone's autoplay_boss_level).
func set_autoplay_hunt(on: bool) -> void:
	_hunt_on = on
	if not on:
		_player.stop_hunt()


## Every group of the zone again (MonsterGroups.groups()), in new places, none within
## MonsterGroups.ENTRY_GAP of avoid (where the hero stands). On autoplay prints "Grupos: n".
func respawn_groups(avoid: Array[Vector3] = []) -> void:
	_monsters.respawn_groups(avoid)


## How many groups are on the map (the rare enemy apart).
func group_count() -> int:
	return _monsters.group_count()


## Debug only (DebugPanel's Monstruos): every group off the map, the rare one too. While
## debug_no_groups is set none comes back.
func clear_groups() -> void:
	_monsters.clear_groups()


## Puts the zone's rare enemy (the Slime de Metal) on this dungeon floor, away from the hero
## (MonsterGroups.rare_spot()), unless one is here already. It wanders the whole floor
## (MonsterRoam WANDER) and is touched like a group.
func add_rare(enemy_id: String) -> void:
	_monsters.add_rare(enemy_id)


func has_rare() -> bool:
	return _monsters.has_rare()


## The enemies of the group whose battle is starting (its formation, data: BattleScene
## duplicates them); empty for the boss's battle.
func contact_enemies() -> Array[Combatant]:
	return _monsters.contact_enemies()


## After the battle of the group touched (outcome: BattleEngine.State): WON takes it off the
## map ("Grupo vencido (quedan n)" on autoplay; another comes back later, MapMonsters.tick_refill()),
## FLED leaves it half see-through, starting no battle until the hero is MonsterGroups.REARM_RADIUS away;
## LOST changes nothing (Game sends the hero back and the groups come back with the map).
func end_contact(outcome: int) -> void:
	_monsters.end_contact(outcome)


## No group starts a battle for MonsterGroups.CALM_MS from now.
func _calm() -> void:
	_monsters.calm(int(_sim_ms))


## Autoplay: leaves the route for the nearest group within AUTOPLAY_HUNT_RADIUS that can
## start a battle, and goes back to it once that one is gone or fled from, after
## AUTOPLAY_HUNT_MS, or when the hero got stuck on the way (that one is then left alone for
## AUTOPLAY_HUNT_RETRY_MS).
func _update_hunt(pos: Vector3) -> void:
	var now := int(_sim_ms)
	var failed := _player.take_failed_hunt()
	if failed != 0:
		_hunt_skip[failed] = now + AUTOPLAY_HUNT_RETRY_MS
	if _player.is_hunting():
		var current := _player.hunting()
		var index := _monsters.group_index(current) if current != null else -1
		if index < 0 or not _monsters.groups[index].armed:
			_player.stop_hunt()
		elif now > _hunt_until_ms:
			_hunt_skip[current.get_instance_id()] = now + AUTOPLAY_HUNT_RETRY_MS
			_player.stop_hunt()
		return
	var best: Node3D = null
	var best_d := AUTOPLAY_HUNT_RADIUS_CAVE if zone.is_dungeon() else AUTOPLAY_HUNT_RADIUS
	for group in _monsters.groups:
		var node: Node3D = group.node
		if not group.armed or now < int(_hunt_skip.get(node.get_instance_id(), 0)):
			continue
		var d := _flat_distance(pos, node.position)
		if d < best_d:
			best = node
			best_d = d
	if best != null:
		_player.hunt(best)
		_hunt_until_ms = now + AUTOPLAY_HUNT_MS


## Shows or removes the return portal at the zone's portal_pos.
func set_portal(on: bool) -> void:
	_props.set_portal(on)


## Shows or removes the mark on the ground of the spot the portal leads back to.
func set_return_mark(on: bool, pos: Vector3) -> void:
	_props.set_return_mark(on, pos)


## Swings the lever down (Game sets its flag and calls set_world_flags()).
func pull_lever() -> void:
	if _dungeon:
		_dungeon.pull_lever()


## The lines figure zone.npcs[index] says in chapter (StoryState.Chapter): its
## lines_by_chapter entry with the highest chapter not past it, else its lines.
func npc_lines(index: int, chapter: int) -> Array[String]:
	return _figures.npc_lines(index, chapter)


## Freezes the player and shows the lines one by one; returns when they are all read.
func show_dialogue(speaker: String, lines: Array[String]) -> void:
	freeze(true)
	await _hud.dialogue.say(speaker, lines)
	await freeze(false)


## A question with buttons (ChoiceWindow) over the map, frozen while it lasts; returns the
## index chosen. On autoplay it opens nothing and takes the first option.
func ask(question: String, options: Array[String], focus := 0) -> int:
	if _autoplay:
		print("Pregunta: %s -> %s" % [question, options[0]])
		return 0
	freeze(true)
	var window := ChoiceWindow.new()
	_hud.add_child(window)
	var chosen: int = await window.ask(question, options, focus)
	await freeze(false)
	return chosen


## Cutscenes: the map stops answering the player (frozen, which also hides the prompts,
## the portal's too), the status window, the map square and the notice go, and the hero
## stops where he is, not walking on his own, until end_cutscene().
func begin_cutscene() -> void:
	freeze(true)
	_player.scripted = true
	_player.move_target = null
	_reset_pad()
	_player.model().set_walking(false)
	_use_on_arrival = {}
	_hud.begin_cutscene()
	_figures.show_marks()
	_signs_under_prompt.clear()
	_figures.set_signs_shown(false)


## Puts every figure back on its spot, gives the camera back to the hero and the
## controls back to the player (the groups calm for a moment).
func end_cutscene() -> void:
	reset_figures()
	_camera.follow(_player)
	_player.scripted = false
	_hud.end_cutscene()
	_figures.show_marks()
	_figures.set_signs_shown(true)
	_calm()
	_was_near = {}
	await freeze(false)


## A dialogue inside a cutscene: like show_dialogue() but the map stays frozen.
func say_lines(speaker: String, lines: Array[String]) -> void:
	await _hud.dialogue.say(speaker, lines)


## The node a cutscene moves for who ("hero" or a figure's name; null if none here).
func figure_node(who: String) -> Node3D:
	return _figures.figure_node(who)


## The node a cutscene turns for who: the hero's model, or the figure itself.
func figure_turn(who: String) -> Node3D:
	return _figures.figure_turn(who)


## The BattleActor of who (walking and cheering), null if none here.
func figure_actor(who: String) -> BattleActor:
	return _figures.figure_actor(who)


## Every figure back on its ZoneData spot and yaw, standing still.
func reset_figures() -> void:
	_figures.reset_figures()


## The camera glides to look at point from at_distance metres (cutscenes).
func focus_camera(point: Vector3, at_distance: float) -> void:
	if _camera_spot == null:
		_camera_spot = Node3D.new()
		add_child(_camera_spot)
	_camera_spot.position = point
	_camera.show_point(_camera_spot, at_distance)


## The camera follows the hero again.
func follow_camera() -> void:
	_camera.follow(_player)


## Freezes the player (no walking, prompts, encounters, exits or uses) while a dialogue
## or the shop is open. Unfreezing waits one frame, so the key that closed the window
## does not open it again; await it.
func freeze(on: bool) -> void:
	if on:
		_talking = true
		_player.input_enabled = false
		_hide_prompt()
		_reset_pad()
		return
	await get_tree().process_frame
	_player.input_enabled = true
	_talking = false
	_taps_from_ms = Time.get_ticks_msec() + TAP_GUARD_MS
	if not _player.scripted:
		_hud.show_banner_once()


## What the quests show on this map (Game passes GameState.quests' answers): marks is figure
## name -> "!" or "?"; hidden_names are figures not on the map now, with no collider and
## nothing to use.
func set_quest_view(marks: Dictionary, hidden_names: Array[String]) -> void:
	_figures.set_quest_view(marks, hidden_names)


## Shows the weapon and shield worn on the hero (Equipment ids, "" for none).
func set_hero_equipment(weapon_id: String, shield_id: String, helmet_id := "") -> void:
	_player.set_equipment(weapon_id, shield_id, helmet_id)


## Opens (lid tipped back, tweened unless instant) or closes a chest of this zone. An
## open chest can't be used any more; ids of other zones are ignored.
func set_chest_open(chest_id: String, open: bool, instant := false) -> void:
	_props.set_chest_open(chest_id, open, instant)


## The pause menu covers the middle of the screen and says the same as the status window,
## which goes away behind it (with the map square).
func set_status_shown(on: bool) -> void:
	_hud.set_status_shown(on)


func refresh_status(hero: Combatant, potions: int, gold: int, missions: Array[String] = []) -> void:
	_hud.refresh_status(hero, potions, gold, missions)


## Puts "Misión cumplida" (or text) in the mission list for a few seconds, then the
## missions under way come back.
func show_mission_done(text: String) -> void:
	_hud.show_mission_done(text)


## Shows a short line in its own window for MapHud.NOTICE_TIME seconds (a newer one replaces it),
## under a small tone word ("Guardado", "Cerrado"...) in the colour of `tone`. Only the text is printed.
func show_notice(text: String, word := "Aviso", tone := &"text-info") -> void:
	_hud.show_notice(text, word, tone)


func _trigger(boss: bool) -> void:
	if boss:
		_boss_armed = false
	if _audio:
		_audio.play_sfx(SfxLibrary.ENCOUNTER)
	_waiting = true
	_player.input_enabled = false
	_hide_prompt()
	_reset_pad()
	encounter_triggered.emit(boss)


## Takes an open exit the player walked into (true: the map waits for Game), or shows a
## closed one's notice once per approach. Exits only count once the player has stepped
## away from all of them since arriving.
func _check_exits(pos: Vector3) -> bool:
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
		return false
	if not _exits_armed:
		_exits_armed = nearest_d > EXIT_RADIUS + EXIT_REARM
		return false
	if nearest_d > EXIT_RADIUS:
		return false
	_exits_armed = false
	if not MapProps.is_open(nearest, _flags):
		show_notice(nearest.lock_text, "Cerrado")
		return false
	_waiting = true
	_player.input_enabled = false
	_hide_prompt()
	_reset_pad()
	exit_requested.emit(nearest.to, nearest.entry)
	return true


## The nearest thing in reach of pos that can be used: {"kind": TALK / NPC / SHOP / INN
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
	for i in zone.npcs.size():
		var npc: Dictionary = zone.npcs[i]
		if _figures.hidden.has(npc.name):
			continue
		uses.append({"kind": NPC_KINDS[npc.kind], "id": npc.get("id", ""), "index": i,
			"pos": npc.pos, "radius": TALK_RADIUS})
	for id in _props.closed_chests():
		uses.append({"kind": CHEST, "id": id, "index": -1, "pos": Chests.CHESTS[id].pos,
			"radius": CHEST_RADIUS})
	if _props.has_portal():
		uses.append({"kind": PORTAL, "id": "", "index": -1, "pos": zone.portal_pos,
			"radius": MECHANISM_RADIUS})
	for well: Dictionary in zone.wells:
		uses.append({"kind": WELL, "id": well.id, "index": -1, "pos": well.pos,
			"radius": WELL_RADIUS})
	if _dungeon == null:
		return uses
	var mechanisms := [[ZoneData.LEVER, LEVER, zone.lever_flag],
		[ZoneData.KEY, KEY, zone.floor_key], [ZoneData.DOOR, DOOR, zone.door_flag]]
	for mechanism in mechanisms:
		if mechanism[2] == "" or _flags.get(mechanism[2], false):
			continue
		for cell in zone.find_cells(mechanism[0]):
			uses.append({"kind": mechanism[1], "id": "", "index": -1,
				"pos": zone.cell_center(cell), "radius": MECHANISM_RADIUS})
	return uses


func _use(use: Dictionary) -> void:
	match use.get("kind", ""):
		TALK:
			talk_requested.emit()
		NPC, BOARD, ITEM:
			npc_requested.emit(use.index)
		SHOP:
			shop_requested.emit(use.id)
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


func _connect_standalone() -> void:
	refresh_status(HERO_DATA, Inventory.START_POTIONS, GameState.START_GOLD)
	encounter_triggered.connect(func(boss: bool) -> void:
		var ids := contact_enemies().map(func(enemy: Combatant) -> String: return enemy.id)
		print("Encuentro en %s (jefe: %s, grupo: %s)" % [_player.global_position, boss, ids])
		end_contact(BattleEngine.State.WON)
		set_active(true))
	talk_requested.connect(func() -> void:
		var lines: Array[String] = ["Hola, viajero."]
		await show_dialogue(Quest.NPC_NAME, lines))
	npc_requested.connect(func(index: int) -> void:
		await show_dialogue(zone.npcs[index].name,
			npc_lines(index, StoryState.Chapter.END)))
	shop_requested.connect(func(shop_id: String) -> void: print("Tienda: %s" % shop_id))
	inn_requested.connect(func(inn_id: String) -> void: print("Posada: %s" % inn_id))
	chest_opened.connect(func(chest_id: String) -> void:
		print("Cofre: %s" % chest_id)
		set_chest_open(chest_id, true))
	well_requested.connect(func(id: String, kind: String) -> void:
		print("Pozo: %s (%s)" % [id, kind]))
	exit_requested.connect(func(zone_id: String, entry_id: String) -> void:
		print("Salida: %s (%s)" % [zone_id, entry_id])
		set_active(true))
	lever_pulled.connect(func() -> void:
		print("Palanca")
		pull_lever()
		_flags[zone.lever_flag] = true
		_flags[zone.door_flag] = true
		set_world_flags(_flags))
	key_taken.connect(func() -> void:
		print("Llave")
		_flags[zone.floor_key] = true
		set_world_flags(_flags))
	door_used.connect(func() -> void: print("Puerta"))
	set_autoplay_hunt(true)


## Hides the water and the light of the wells in dry.
func set_dry_wells(dry: Array[String]) -> void:
	_props.set_dry_wells(dry)
	_refresh_map_marks()


## A closed chest on a box collider under root: wooden box with a gold band around it and a lid on
## a pivot at its back edge. Returns the lid pivot.
static func build_chest(root: Node3D, chest: Dictionary) -> Node3D:
	return MapProps.build_chest(root, chest)


## A line at the bottom until the hero first walks (phones, once: Game decides).
func show_touch_hint(text: String) -> void:
	_hud.show_touch_hint(text)


## A soft footstep every STEP_DISTANCE meters walked.
func _play_steps() -> void:
	_step_m += _player.last_step_m
	if _step_m < STEP_DISTANCE:
		return
	_step_m -= STEP_DISTANCE
	stepped.emit()
	if _audio:
		_audio.play_sfx(SfxLibrary.STEP)


func _is_in_village(pos: Vector3) -> bool:
	return zone.village_radius > 0.0 \
		and _flat_distance(pos, zone.village_pos) <= zone.village_radius


static func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))
