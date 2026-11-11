class_name World extends Node3D
## One map of the world, built from `zone` (a ZoneData, set before add_child; the
## meadow if none): field, village, figures, boss, chests, exits, player, follow camera,
## status window and the groups of monsters walking on it (MonsterGroups, MonsterRoam): touching one starts its battle (encounter_triggered(false), contact_enemies(), end_contact()). A click or tap on the ground (held and dragged
## too) walks the player there, with a marker on the spot. Next to a figure or a closed
## chest (the nearest one in reach) Enter / Space talks to the old woman
## (talk_requested) or to a villager (npc_requested), opens the shop (shop_requested),
## asks for a room (inn_requested) or opens the chest (chest_opened); a small medal (Medals) shows
## only with the hero
## close and is picked up ("Coger", medal_taken); a click or tap on
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
## The player picked up the small medal medal_id (a Medals.MEDALS key); Game takes it in
## the GameState and calls remove_medal().
signal medal_taken(medal_id: String)
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
const ACTOR_SCENE := preload("res://scenes/battle/battle_actor.tscn")
const HERO_DATA := preload("res://data/hero.tres")
## Global shader parameter the trees read; NO_HERO_POS (below the ground) leaves them whole.
const HERO_POS_PARAM := &"hero_pos"
const NO_HERO_POS := Vector3(0, -100, 0)
const NOTICE_TIME := 2.0
## Seconds "Misión cumplida" stays in the status window.
const MISSION_DONE_TIME := 4.0
## The notice window, top centre (clear of the status window and the ☰ button).
const NOTICE_MAX_WIDTH := 640.0
const UI_EDGE := 24.0
## Phone: the mission line wraps here and the bars narrow to fit.
const TOUCH_MISSION_WIDTH := 300.0
## The use button of the phone interface.
const USE_BUTTON_FONT := 28
const USE_BUTTON_SIZE := Vector2(180, 72)
## The place's line by the map square.
const PLACE_OUTLINE := 6
## The phone's walking hint: wraps here and sits over the use button's row.
const TOUCH_HINT_WIDTH := 480.0
## The place's name, big, the first time the map is the player's (World.freeze(false)).
const BANNER_TOP := 110.0
const BANNER_NAME_FONT := 48
const BANNER_FLOOR_FONT := 30
const BANNER_COLOR := Color(1.0, 0.9, 0.45)
const BANNER_FADE := 0.5
const BANNER_TIME := 2.5
const FONT_SIZE := 24
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
## The return portal: an upright glowing oval on a ring, pulsing, with its sign. The spot
## it leads back to is the same ring alone, flat on the ground.
const PORTAL_COLOR := Color(0.2, 0.45, 1.0, 0.7)
const PORTAL_SIZE := Vector3(0.95, 1.35, 0.7)
const PORTAL_PULSE := 1.08
## How close the player must be to a lever, a key or a gate (its centre) to use it.
const MECHANISM_RADIUS := 2.2
## A small medal (Medals): picked up within MEDAL_RADIUS, shown only within
## MEDAL_SEEN_RADIUS of the hero; a gold disc of MEDAL_DISC radius with a brighter core,
## blinking every MEDAL_BLINK seconds.
const MEDAL_RADIUS := 1.5
const MEDAL_SEEN_RADIUS := 7.0
const MEDAL_DISC := 0.15
const MEDAL_COLOR := Color(1.0, 0.8, 0.2)
const MEDAL_CORE_COLOR := Color(1.0, 0.97, 0.75)
const MEDAL_BLINK := 0.9
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
const MEDAL := "medal"
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
	MEDAL: "Coger",
}
## ZoneData.npcs kinds -> use kinds.
const NPC_KINDS := {"quest": TALK, "npc": NPC, "shop": SHOP, "inn": INN, "board": BOARD}
## Chest model: wooden box with a gold band and a lid hinged at the back.
const CHEST_SIZE := Vector3(0.9, 0.45, 0.6)
const CHEST_LID_HEIGHT := 0.2
const CHEST_WOOD := Color(0.5, 0.3, 0.14)
const CHEST_BAND := Color(1.0, 0.78, 0.2)
## Angle of an open lid (degrees about X: the front edge swings up and back).
const CHEST_OPEN_ANGLE := 110.0
## Wells: a collider the hero walks around, and a disc of coloured water with a light.
const WELL_COLLIDER := 1.3
const WATER_HP := Color(1.0, 0.25, 0.25)
const WATER_MP := Color(0.25, 0.5, 1.0)
const WATER_RADIUS := 0.95
const WATER_HEIGHT := 1.2
## Marks on the map square.
## Exit arch: two posts and a beam of dark wood, a sign board with the exit's label
## (always facing the camera, south) and, while closed, a bank of fog.
const ARCH_WOOD := Color(0.36, 0.22, 0.1)
const ARCH_WIDTH := 3.6
const ARCH_HEIGHT := 3.0
const SIGN_COLOR := Color(0.62, 0.45, 0.25)
const FOG_COLOR := Color(0.92, 0.93, 0.97, 0.6)
const MARKER_COLOR := Color(1.0, 0.9, 0.4)
## Meters walked between two footstep sounds.
const STEP_DISTANCE := 1.6
## Underground the hero carries a lantern: a warm light over the head.
const LANTERN_COLOR := Color(1.0, 0.85, 0.65)
const LANTERN_ENERGY := 2.0
const LANTERN_RANGE := 10.0
const LANTERN_HEIGHT := 2.4
## The "!" and "?" of the quests: over the figure, bobbing.
const QUEST_MARK_COLOR := Color(1.0, 0.85, 0.2)
const QUEST_MARK_GAP := 0.35
const QUEST_MARK_BOB := 0.12
const FIGURE_SIGN_GAP := 0.25
const FIGURE_SIGN_FONT := 48
const FIGURE_SIGN_PIXEL := 0.012
const FIGURE_SIGN_OUTLINE := 14
const FIGURE_SIGN_COLOR := Color(1.0, 0.95, 0.8)
## Mission lines wrap past this width, so the status window stays at the side of the screen.
const MISSION_WIDTH := 420.0
## Groups of monsters farther than this from the hero neither move nor animate.
const GROUP_ANIMATE_RADIUS := 30.0
## Seconds between two hops of a slime walking on the map.
const HOP_TIME := 0.45
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

var _rng := RandomNumberGenerator.new()
var _grass: ShaderMaterial
var _player: Player
var _camera: FollowCamera
var _boss: StaticBody3D
## ZoneData.npcs "name" -> its figure (a StaticBody3D with the BattleActor under it).
var _figures := {}
## What a cutscene's camera looks at (camera_to); null until the first one.
var _camera_spot: Node3D
## The status window and the map square under it: a cutscene hides them together.
var _status_column: VBoxContainer
## chest id -> lid pivot (rotation.x opens it); a chest in _open_chests is open.
var _chest_lids := {}
## Well id -> its water and light, hidden while it is dry.
var _well_waters := {}
var _open_chests: Array[String] = []
## Medal id -> its glint, while it lies on this map (remove_medal() takes it off).
var _medals := {}
## exit id -> fog bank shown while the exit is closed.
var _fogs := {}
## ZoneData.all_exits(): the arches and, on a dungeon floor, the stairs.
var _exits: Array = []
## The cells of a dungeon floor (null on an open map).
var _dungeon: DungeonMap
var _flags := {}
var _exits_armed := false
## The return portal and the mark of the spot it leads back to (null while not on this map).
var _portal: Node3D
var _return_mark: Node3D
var _boss_present := false
## False from a boss battle until the hero walks BOSS_REARM_RADIUS away from the boss.
var _boss_armed := true
var _ui: CanvasLayer
var _name_label: Label
var _hp_bar: StatBar
var _mp_bar: StatBar
var _exp_bar: StatBar
var _potion_label: Label
var _gold_label: Label
var _mission_box: VBoxContainer
## The lines of the status window, and the serial that lets "Misión cumplida" put them back.
var _missions: Array[String] = []
var _mission_done_serial := 0
var _mission_done := false
var _map_square: MapSquare
var _has_explored := false
## True while an Incienso keeps the monsters away (Game counts its metres).
var _repelled := false
var _dry_wells: Array[String] = []
var _notice: Label
var _notice_window: PanelContainer
var _place_label: Label
var _hint_window: PanelContainer
var _hint: Label
var _banner: VBoxContainer
var _banner_tween: Tween
var _banner_shown := false
var _notice_serial := 0
var _prompt: Label
## Phones: the button that replaces the prompt, and the pad that reads the fingers.
var _use_button: Button
var _pad: TouchPad
var _dialogue: DialogueBox
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
var _marker: MeshInstance3D
var _audio: AudioDirector
var _in_village := false
var _step_m := 0.0
## Figure name -> "!" or "?", the figures that are not on the map, and the labels so far.
var _quest_marks := {}
var _hidden_figures: Array[String] = []
var _mark_labels := {}
var _figure_signs: Array[Label3D] = []
## The groups of monsters on the map (MonsterGroups), each {"node": Node3D (no collider),
## "actor": BattleActor (its first enemy's figure), "roam": MonsterRoam, "enemies":
## Array[Combatant] (the formation, data), "armed": bool (false: fled from, it starts no
## battle yet), "rare": bool (the Slime de Metal), "hop": seconds to its next hop}.
var _groups: Array[Dictionary] = []
## The hero is EncounterMeter.LEVEL_GAP levels past the zone: the moving groups keep away.
var _shy := false
## Index in _groups of the group whose battle is on (-1: none, or the boss's).
var _contact := -1
## No group starts a battle before this time (_sim_ms; _calm()).
var _calm_until_ms := 0
## Autoplay: hunt groups (Game: below the zone's autoplay_boss_level), until when the one
## hunted now is followed, and group instance id -> the time until which it is left alone.
var _hunt_on := false
var _hunt_until_ms := 0
## Time of the simulation in ms (the hunt's timers count it, so a run with --fixed-fps keeps them).
var _sim_ms := 0.0
var _hunt_skip := {}


func _ready() -> void:
	if zone == null:
		zone = ZoneData.by_id("pradera")
	# The groups are placed with the zone and the clock: never twice the same.
	_rng.seed = hash(zone.id) ^ Time.get_ticks_usec()
	_autoplay = OS.get_cmdline_user_args().has("--autoplay")
	_grass = WorldStage.build(self, zone)
	if zone.is_dungeon():
		_dungeon = DungeonMap.new()
		_dungeon.zone = zone
		add_child(_dungeon)
	for npc: Dictionary in zone.npcs:
		_figures[npc.name] = _add_figure(BattleActor.Look[npc.look], npc.pos, npc.yaw, 0.4,
			1.8)
		_add_figure_sign(npc)
	if boss_id == "":
		boss_id = zone.boss_id
	if boss_id != "":
		_boss = _add_figure(EnemyLibrary.look(boss_id), zone.boss_pos, 180.0, 1.0, 2.0)
	for id in Chests.of_zone(zone.id):
		_chest_lids[id] = build_chest(self, Chests.CHESTS[id])
	for id in Medals.of_zone(zone.id):
		_medals[id] = _build_medal(Medals.MEDALS[id].pos)
	for well: Dictionary in zone.wells:
		_build_well(well)
	_exits = zone.all_exits()
	for exit: Dictionary in _exits:
		if not exit.get("stairs", false):
			_fogs[exit.id] = _build_exit(exit)
	set_boss_present(false)
	set_world_flags({})
	_player = PLAYER_SCENE.instantiate()
	_player.route = zone.autoplay_route
	add_child(_player)
	if zone.underground:
		var lantern := OmniLight3D.new()
		lantern.light_color = LANTERN_COLOR
		lantern.light_energy = LANTERN_ENERGY
		lantern.omni_range = LANTERN_RANGE
		lantern.position.y = LANTERN_HEIGHT
		_player.add_child(lantern)
	_camera = FollowCamera.new()
	add_child(_camera)
	_camera.target = _player
	_marker = _build_marker()
	_build_ui()
	_place_label.text = zone.map_label()
	set_explored(ExploredMap.new(zone))
	place_at_entry(zone.start_entry)
	respawn_groups()
	_camera.current = true
	if get_parent() == get_tree().root:
		_connect_standalone()


func _physics_process(delta: float) -> void:
	_sim_ms += delta * 1000.0
	if _pad:
		_player.stick_direction = _pad.direction
		if _pad.direction != Vector2.ZERO:
			_use_on_arrival = {}  # walking off by hand drops the tap's errand
	if _grass:
		Vegetation.set_pusher(_grass, _player.global_position)
	RenderingServer.global_shader_parameter_set(HERO_POS_PARAM, _player.global_position)
	_map_square.follow(_player.global_position)
	_show_near_medals(_player.global_position)
	if _hint_window and _hint_window.visible and _player.last_step_m > 0.0:
		_hint_window.hide()
	_marker.visible = _player.move_target != null
	if _marker.visible:
		_marker.position = _player.move_target
	if _dungeon:
		_dungeon.see_through(_camera.global_position, _player.global_position)
	_move_groups(delta)
	if _waiting or _talking:
		return
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
	if _check_groups(pos):
		return
	if _autoplay and _hunt_on and not _repelled:
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
		var chats: bool = near.kind == NPC or near.kind == BOARD
		if not chats or not _autoplay_talked.has(near.index) \
				or _quest_marks.has(zone.npcs[near.index].name):
			_autoplay_talked[near.index] = true
			_use(near)
	_was_near = near


## The title's meadow has no hero: its trees stay whole.
func _exit_tree() -> void:
	RenderingServer.global_shader_parameter_set(HERO_POS_PARAM, NO_HERO_POS)


func _unhandled_input(event: InputEvent) -> void:
	if _waiting or _talking:
		return
	if _prompt_showing() and event.is_action_pressed("ui_accept") and not event.is_echo():
		get_viewport().set_input_as_handled()
		_use(_nearest_use(_player.global_position))
		return
	if _pad:
		if _pad.handle(event):
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
	var text := _prompt_text(near)
	if _use_button:
		_use_button.text = text
		_use_button.show()
		return
	_prompt.text = text
	_prompt.show()


func _hide_prompt() -> void:
	_prompt.hide()
	if _use_button:
		_use_button.hide()


func _prompt_showing() -> bool:
	return _use_button.visible if _use_button else _prompt.visible


## Forgets the fingers on the map (a window, a battle or a cutscene took over).
func _reset_pad() -> void:
	if _pad:
		_pad.reset()


## Hidden and frozen while a battle is on top; back on, no group starts a battle for MonsterGroups.CALM_MS.
func set_active(active: bool) -> void:
	process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	visible = active
	_ui.visible = active
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
## After a return through the portal on autoplay: lets the player skip a blocked route point.
func arm_blocked_point_skip() -> void:
	_player.arm_blocked_point_skip()


func place_player(pos: Vector3, yaw_deg := 0.0) -> void:
	_player.place(pos, deg_to_rad(yaw_deg))
	_camera.snap()
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
	_dialogue.set_audio(audio)


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
	for group in _groups:
		(group.roam as MonsterRoam).set_flags(flags)
	for exit: Dictionary in zone.exits:
		(_fogs[exit.id] as Node3D).visible = not _is_open(exit)
	if _dungeon:
		_dungeon.set_flags(flags)
	_refresh_map_marks()


## What has been seen of this zone, for the map square (Game passes GameState's; run on
## its own the map keeps its own).
func set_explored(map: ExploredMap) -> void:
	_map_square.set_map(map)
	_has_explored = true
	_refresh_map_marks()


## The map square's points of interest (MapMarks): they follow the dry wells and, on a
## dungeon floor, the lever, the gates and the key.
func _refresh_map_marks() -> void:
	if not _has_explored:
		return
	_map_square.set_marks(MapMarks.of_zone(zone, _flags, _dry_wells))


## The hero is EncounterMeter.LEVEL_GAP levels past the zone (EncounterMeter.is_shy()): the
## groups that move keep away from him; the still ones stay. They can still be touched.
func set_monsters_shy(on: bool) -> void:
	_shy = on


## An Incienso burning: touching a group starts no battle and every group shows half
## see-through (the boss still waits where it is).
func set_repel(on: bool) -> void:
	if _repelled == on:
		return
	_repelled = on
	if on:
		_player.stop_hunt()
	for group in _groups:
		_fade_group(group)
	if not on:
		_calm()


## Autoplay: hunt the groups (Game: while the hero is below the zone's autoplay_boss_level).
func set_autoplay_hunt(on: bool) -> void:
	_hunt_on = on
	if not on:
		_player.stop_hunt()


## Autoplay: walks these points, from the first, instead of the zone's autoplay_route
## (--autoplay-zone=medallas: Medals.AUTOPLAY_ROUTE). A copy: the zone's route never changes.
func set_autoplay_route(points: Array) -> void:
	var route: Array[Vector3] = []
	route.assign(points)
	_player.route = route
	_player.restart_route()


## Every group of the zone again (MonsterGroups.groups()), in new places, none within
## MonsterGroups.ENTRY_GAP of avoid (where the hero stands). On autoplay prints "Grupos: n".
func respawn_groups(avoid: Array[Vector3] = []) -> void:
	for group in _groups:
		(group.node as Node3D).queue_free()
	_groups.clear()
	_contact = -1
	_hunt_skip.clear()
	_player.stop_hunt()
	for spot: Dictionary in MonsterGroups.groups(zone, _rng, avoid):
		_add_group(spot.pos, spot.enemies, false)
	if _autoplay:
		print("Grupos: %d" % group_count())


## How many groups are on the map (the rare enemy apart).
func group_count() -> int:
	var count := 0
	for group in _groups:
		if not group.rare:
			count += 1
	return count


## Puts the zone's rare enemy (the Slime de Metal) on this dungeon floor, away from the hero
## (MonsterGroups.rare_spot()), unless one is here already. It wanders the whole floor
## (MonsterRoam WANDER) and is touched like a group.
func add_rare(enemy_id: String) -> void:
	if has_rare() or not zone.is_dungeon():
		return
	var spot: Variant = MonsterGroups.rare_spot(zone, _rng, _player.global_position)
	if spot == null:
		return
	_add_group(spot, EnemyLibrary.formation([enemy_id]), true)
	if _autoplay:
		print("%s en el mapa" % EnemyLibrary.data(enemy_id).display_name)


func has_rare() -> bool:
	for group in _groups:
		if group.rare:
			return true
	return false


## A group at pos: the figure of its first enemy (no collider: nothing bumps into it),
## facing the camera, and its MonsterRoam.
func _add_group(pos: Vector3, enemies: Array[Combatant], rare: bool) -> void:
	var node := Node3D.new()
	node.position = pos
	node.rotation_degrees.y = 180.0
	add_child(node)
	var actor: BattleActor = ACTOR_SCENE.instantiate()
	actor.look = EnemyLibrary.look(enemies[0].id)
	node.add_child(actor)
	var roam := MonsterRoam.for_leader(enemies[0], pos, _rng,
		zone if zone.is_dungeon() else null)
	roam.set_flags(_flags)
	var group := {"node": node, "actor": actor, "roam": roam, "enemies": enemies,
		"armed": true, "rare": rare, "hop": 0.0}
	_groups.append(group)
	_fade_group(group)


## Moves every group near the hero one physics tick (MonsterRoam), turned the way it walks,
## with the walk animation and, for a slime, a hop now and then. Groups past
## GROUP_ANIMATE_RADIUS stop moving and animating (their node stops processing).
func _move_groups(delta: float) -> void:
	var hero := _player.global_position
	for group in _groups:
		var node: Node3D = group.node
		var near := _flat_distance(hero, node.position) <= GROUP_ANIMATE_RADIUS
		var mode := Node.PROCESS_MODE_INHERIT if near else Node.PROCESS_MODE_DISABLED
		if node.process_mode != mode:
			node.process_mode = mode
		if not near:
			continue
		var roam: MonsterRoam = group.roam
		var actor: BattleActor = group.actor
		var before := node.position
		node.position = roam.step(before, delta, hero, _shy)
		actor.set_walking(roam.moving)
		if not roam.moving:
			continue
		var dir := node.position - before
		node.rotation.y = lerp_angle(node.rotation.y, atan2(-dir.x, -dir.z),
			minf(1.0, Player.TURN_SPEED * delta))
		if actor.hops():
			group["hop"] = float(group.hop) - delta
			if group.hop <= 0.0:
				group["hop"] = HOP_TIME
				actor.play_hop()


## A group shows half see-through while it can't start a battle: fled from, or an Incienso
## burning.
func _fade_group(group: Dictionary) -> void:
	(group.actor as BattleActor).set_faded(_repelled or not group.armed)


## The enemies of the group whose battle is starting (its formation, data: BattleScene
## duplicates them); empty for the boss's battle.
func contact_enemies() -> Array[Combatant]:
	var enemies: Array[Combatant] = []
	if _contact >= 0:
		enemies.assign(_groups[_contact].enemies)
	return enemies


## After the battle of the group touched (outcome: BattleEngine.State): WON takes it off the
## map until the map is built again ("Grupo vencido (quedan n)" on autoplay), FLED leaves it
## half see-through, starting no battle until the hero is MonsterGroups.REARM_RADIUS away;
## LOST changes nothing (Game sends the hero back and the groups come back with the map).
func end_contact(outcome: int) -> void:
	if _contact < 0:
		return
	var index := _contact
	_contact = -1
	var group: Dictionary = _groups[index]
	if outcome == BattleEngine.State.WON:
		_groups.remove_at(index)
		(group.node as Node3D).queue_free()
		if _autoplay:
			print("Grupo vencido (quedan %d)" % group_count())
	elif outcome == BattleEngine.State.FLED:
		group.armed = false
		_fade_group(group)


## No group starts a battle for MonsterGroups.CALM_MS from now.
func _calm() -> void:
	_calm_until_ms = int(_sim_ms) + MonsterGroups.CALM_MS


## The hero within MonsterGroups.CONTACT_RADIUS of a group starts its battle (true: the
## map waits for Game), unless it is calm (_calm()) or an Incienso burns. A group fled from
## starts none until the hero is MonsterGroups.REARM_RADIUS away from it.
func _check_groups(pos: Vector3) -> bool:
	var calm := int(_sim_ms) < _calm_until_ms
	for i in _groups.size():
		var group: Dictionary = _groups[i]
		var d := _flat_distance(pos, (group.node as Node3D).position)
		if not group.armed:
			if d > MonsterGroups.REARM_RADIUS:
				group.armed = true
				_fade_group(group)
			continue
		if d <= MonsterGroups.CONTACT_RADIUS and not calm and not _repelled:
			_contact = i
			_trigger(false)
			return true
	return false


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
		var index := _group_index(current) if current != null else -1
		if index < 0 or not _groups[index].armed:
			_player.stop_hunt()
		elif now > _hunt_until_ms:
			_hunt_skip[current.get_instance_id()] = now + AUTOPLAY_HUNT_RETRY_MS
			_player.stop_hunt()
		return
	var best: Node3D = null
	var best_d := AUTOPLAY_HUNT_RADIUS_CAVE if zone.is_dungeon() else AUTOPLAY_HUNT_RADIUS
	for group in _groups:
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


## The index in _groups of the group on node (-1 if none).
func _group_index(node: Node3D) -> int:
	for i in _groups.size():
		if _groups[i].node == node:
			return i
	return -1


## Shows or removes the return portal at the zone's portal_pos.
func set_portal(on: bool) -> void:
	if _portal != null:
		_portal.queue_free()
		_portal = null
	if on:
		_portal = _build_portal(zone.portal_pos, true)


## Shows or removes the mark on the ground of the spot the portal leads back to.
func set_return_mark(on: bool, pos: Vector3) -> void:
	if _return_mark != null:
		_return_mark.queue_free()
		_return_mark = null
	if on:
		_return_mark = _build_portal(pos, false)


## Swings the lever down (Game sets its flag and calls set_world_flags()).
func pull_lever() -> void:
	if _dungeon:
		_dungeon.pull_lever()


## The lines figure zone.npcs[index] says in chapter (StoryState.Chapter): its
## lines_by_chapter entry with the highest chapter not past it, else its lines.
func npc_lines(index: int, chapter: int) -> Array[String]:
	var npc: Dictionary = zone.npcs[index]
	var lines: Array[String] = []
	lines.assign(npc.get("lines", []))
	var by_chapter: Dictionary = npc.get("lines_by_chapter", {})
	var best := -1
	for key: int in by_chapter:
		if key <= chapter and key > best:
			best = key
			lines.assign(by_chapter[key])
	return lines


## Freezes the player and shows the lines one by one; returns when they are all read.
func show_dialogue(speaker: String, lines: Array[String]) -> void:
	freeze(true)
	await _dialogue.say(speaker, lines)
	await freeze(false)


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
	_status_column.hide()
	_map_square.hide()
	_place_label.hide()
	if _hint_window:
		_hint_window.hide()
	_notice_window.hide()
	if _banner_tween:
		_banner_tween.kill()
	_banner.hide()
	_show_quest_marks()
	for label in _figure_signs:
		label.hide()
	_show_near_medals(_player.global_position)


## Puts every figure back on its spot, gives the camera back to the hero and the
## controls back to the player (the groups calm for a moment).
func end_cutscene() -> void:
	reset_figures()
	_camera.follow(_player)
	_player.scripted = false
	_status_column.show()
	_map_square.show()
	_place_label.show()
	_show_quest_marks()
	for label in _figure_signs:
		label.show()
	_show_near_medals(_player.global_position)
	_calm()
	_was_near = {}
	await freeze(false)


## A dialogue inside a cutscene: like show_dialogue() but the map stays frozen.
func say_lines(speaker: String, lines: Array[String]) -> void:
	await _dialogue.say(speaker, lines)


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
	for npc: Dictionary in zone.npcs:
		var body: Node3D = _figures[npc.name]
		body.position = npc.pos
		body.rotation_degrees.y = npc.yaw
		var actor := figure_actor(npc.name)
		if actor:
			actor.set_walking(false)


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
	if not _banner_shown and not _player.scripted:
		_banner_shown = true
		_show_banner()


## What the quests show on this map (Game passes GameState.quests' answers): marks is figure
## name -> "!" or "?"; hidden_names are figures not on the map now, with no collider and
## nothing to use.
func set_quest_view(marks: Dictionary, hidden_names: Array[String]) -> void:
	_quest_marks = marks
	_hidden_figures = hidden_names
	for npc: Dictionary in zone.npcs:
		var body: StaticBody3D = _figures[npc.name]
		var shown := not hidden_names.has(npc.name)
		body.visible = shown
		body.process_mode = Node.PROCESS_MODE_INHERIT if shown else Node.PROCESS_MODE_DISABLED
	_show_quest_marks()


## One floating label per figure with a mark; none during a cutscene.
func _show_quest_marks() -> void:
	for npc: Dictionary in zone.npcs:
		var text: String = _quest_marks.get(npc.name, "")
		var label: Label3D = _mark_labels.get(npc.name)
		if label == null:
			if text == "":
				continue
			label = _build_mark(npc.name)
		label.text = text
		label.visible = text != "" and not _player.scripted


## What a figure offers, over its head: its model alone doesn't tell.
static func _figure_sign_text(npc: Dictionary) -> String:
	match npc.kind:
		"shop":
			return "Criaturas" if Shop.sells_ally(npc.id) else "Tienda"
		"inn":
			return "Posada"
	return ""


func _add_figure_sign(npc: Dictionary) -> void:
	var text := _figure_sign_text(npc)
	if text == "":
		return
	var label := Label3D.new()
	label.text = text
	label.font_size = FIGURE_SIGN_FONT
	label.pixel_size = FIGURE_SIGN_PIXEL
	label.outline_size = FIGURE_SIGN_OUTLINE
	label.modulate = FIGURE_SIGN_COLOR
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.position.y = figure_actor(npc.name).top_height() + FIGURE_SIGN_GAP
	(_figures[npc.name] as Node3D).add_child(label)
	_figure_signs.append(label)


func _build_mark(figure_name: String) -> Label3D:
	var label := Label3D.new()
	label.font_size = 96
	label.pixel_size = 0.01
	label.outline_size = 16
	label.modulate = QUEST_MARK_COLOR
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.position.y = figure_actor(figure_name).top_height() + QUEST_MARK_GAP
	(_figures[figure_name] as Node3D).add_child(label)
	_mark_labels[figure_name] = label
	var bob := label.create_tween().set_loops()
	bob.tween_property(label, "position:y", label.position.y + QUEST_MARK_BOB, 0.5) \
		.set_trans(Tween.TRANS_SINE)
	bob.tween_property(label, "position:y", label.position.y, 0.5).set_trans(Tween.TRANS_SINE)
	return label


## Shows the weapon and shield worn on the hero (Equipment ids, "" for none).
func set_hero_equipment(weapon_id: String, shield_id: String, helmet_id := "") -> void:
	_player.set_equipment(weapon_id, shield_id, helmet_id)


## Opens (lid tipped back, tweened unless instant) or closes a chest of this zone. An
## open chest can't be used any more; ids of other zones are ignored.
func set_chest_open(chest_id: String, open: bool, instant := false) -> void:
	if not _chest_lids.has(chest_id):
		return
	var lid: Node3D = _chest_lids[chest_id]
	var angle := deg_to_rad(CHEST_OPEN_ANGLE) if open else 0.0
	if open and not _open_chests.has(chest_id):
		_open_chests.append(chest_id)
	elif not open:
		_open_chests.erase(chest_id)
	if instant:
		lid.rotation.x = angle
	else:
		lid.create_tween().tween_property(lid, "rotation:x", angle, 0.35) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Takes a small medal off this map (taken now, or before: Game calls it for every medal of
## GameState.medals once the map is built). Ids of other zones are ignored.
func remove_medal(medal_id: String) -> void:
	if not _medals.has(medal_id):
		return
	(_medals[medal_id] as Node3D).queue_free()
	_medals.erase(medal_id)


## A medal only shows with the hero close (and never in a cutscene): it is there to be found
## by exploring.
func _show_near_medals(hero: Vector3) -> void:
	for id: String in _medals:
		var glint: Node3D = _medals[id]
		glint.visible = not _player.scripted 			and _flat_distance(hero, glint.position) <= MEDAL_SEEN_RADIUS


## The pause menu covers the middle of the screen and says the same as the status window,
## which goes away behind it (with the map square).
func set_status_shown(on: bool) -> void:
	_reset_pad()  # a finger's release is lost while the tree is paused
	_status_column.visible = on
	_map_square.visible = on
	_place_label.visible = on


func refresh_status(hero: Combatant, potions: int, gold: int, missions: Array[String] = []) -> void:
	_name_label.text = StatBar.hero_title(hero)
	_hp_bar.show_hp(hero.hp, hero.max_hp)
	_mp_bar.show_mp(hero.mp, hero.max_mp)
	_exp_bar.show_exp(hero)
	_potion_label.text = "%s ×%d" % [Inventory.display_name(Inventory.POTION), potions]
	_gold_label.text = "%d G" % gold
	_missions = missions
	if not _mission_done:
		_show_missions(missions, Color.WHITE)


## Puts "Misión cumplida" (or text) in the mission list for a few seconds, then the
## missions under way come back.
func show_mission_done(text: String) -> void:
	_mission_done_serial += 1
	var serial := _mission_done_serial
	_mission_done = true
	var lines: Array[String] = [text]
	_show_missions(lines, StatBar.GOLD)
	if _autoplay:
		print(text)
	await get_tree().create_timer(MISSION_DONE_TIME).timeout
	if serial == _mission_done_serial:
		_mission_done = false
		_show_missions(_missions, Color.WHITE)


func _show_missions(lines: Array[String], color: Color) -> void:
	for child in _mission_box.get_children():
		_mission_box.remove_child(child)
		child.queue_free()
	var shown := lines.slice(0, 1) if Device.is_touch() else lines
	var width := TOUCH_MISSION_WIDTH if Device.is_touch() else MISSION_WIDTH
	for line in shown:
		var label := _label()
		label.add_theme_color_override("font_color", color)
		_mission_box.add_child(label)
		BattleHud.fit_label(label, line, width)


## Shows a short line in its own window for NOTICE_TIME seconds (a newer one replaces it).
func show_notice(text: String) -> void:
	_notice_serial += 1
	var serial := _notice_serial
	BattleHud.fit_label(_notice, text, NOTICE_MAX_WIDTH)
	_notice_window.show()
	if _autoplay:
		print(text)
	await get_tree().create_timer(NOTICE_TIME).timeout
	if serial == _notice_serial:
		_notice_window.hide()


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


func _is_open(exit: Dictionary) -> bool:
	return exit.lock == "" or _flags.get(exit.lock, false)


## Takes an open exit the player walked into (true: the map waits for Game), or shows a
## closed one's notice once per approach. Exits only count once the player has stepped
## away from all of them since arriving.
func _check_exits(pos: Vector3) -> bool:
	var nearest := {}
	var nearest_d := INF
	for exit: Dictionary in _exits:
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
	if not _is_open(nearest):
		show_notice(nearest.lock_text)
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


## Everything usable now: the zone's figures, its closed chests, the small medals still on it and,
## on a dungeon floor,
## the lever until pulled, the key until taken and the gates while closed.
func _uses() -> Array[Dictionary]:
	var uses: Array[Dictionary] = []
	for i in zone.npcs.size():
		var npc: Dictionary = zone.npcs[i]
		if _hidden_figures.has(npc.name):
			continue
		uses.append({"kind": NPC_KINDS[npc.kind], "id": npc.get("id", ""), "index": i,
			"pos": npc.pos, "radius": TALK_RADIUS})
	for id in _chest_lids:
		if not _open_chests.has(id):
			uses.append({"kind": CHEST, "id": id, "index": -1, "pos": Chests.CHESTS[id].pos,
				"radius": CHEST_RADIUS})
	for id: String in _medals:
		uses.append({"kind": MEDAL, "id": id, "index": -1, "pos": Medals.MEDALS[id].pos,
			"radius": MEDAL_RADIUS})
	if _portal != null:
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
		NPC, BOARD:
			npc_requested.emit(use.index)
		SHOP:
			shop_requested.emit(use.id)
		INN:
			inn_requested.emit(use.id)
		CHEST:
			chest_opened.emit(use.id)
		MEDAL:
			medal_taken.emit(use.id)
		WELL:
			well_requested.emit(use.id, _well_kind(use.id))
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
	medal_taken.connect(func(medal_id: String) -> void:
		print("Medalla: %s" % medal_id)
		remove_medal(medal_id))
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


## Flat ring on the spot the player walks to. Drawn on top of everything, so the tall
## grass never hides it.
func _build_marker() -> MeshInstance3D:
	var ring := TorusMesh.new()
	ring.inner_radius = 0.3
	ring.outer_radius = 0.42
	ring.rings = 16
	ring.ring_segments = 4
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = MARKER_COLOR
	material.no_depth_test = true
	var marker := MeshInstance3D.new()
	marker.mesh = ring
	marker.material_override = material
	marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	marker.visible = false
	add_child(marker)
	return marker


## The arch of an exit (turned by its yaw) with its sign, which always faces the camera,
## and the fog bank that closes it. Returns the fog bank.
func _build_exit(exit: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.position = exit.pos
	add_child(root)
	var arch := Node3D.new()
	arch.rotation_degrees.y = exit.yaw
	root.add_child(arch)
	var post := BoxMesh.new()
	post.size = Vector3(0.3, ARCH_HEIGHT, 0.3)
	for x in [-ARCH_WIDTH / 2.0, ARCH_WIDTH / 2.0]:
		BattleStage.add_mesh(arch, post, ARCH_WOOD, Vector3(x, ARCH_HEIGHT / 2.0, 0))
	var beam := BoxMesh.new()
	beam.size = Vector3(ARCH_WIDTH + 0.6, 0.35, 0.4)
	BattleStage.add_mesh(arch, beam, ARCH_WOOD, Vector3(0, ARCH_HEIGHT, 0))
	var board := BoxMesh.new()
	board.size = Vector3(2.4, 0.55, 0.08)
	BattleStage.add_mesh(root, board, SIGN_COLOR, Vector3(0, ARCH_HEIGHT + 0.5, 0.1))
	var label := Label3D.new()
	label.text = exit.label
	label.font_size = 48
	label.pixel_size = 0.008
	label.outline_size = 10
	label.modulate = Color(1.0, 0.95, 0.8)
	label.position = Vector3(0, ARCH_HEIGHT + 0.5, 0.15)
	root.add_child(label)
	var fog := Node3D.new()
	root.add_child(fog)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = FOG_COLOR
	for puff in [Vector3(-1.2, 0.8, 0), Vector3(0, 1.1, 0.1), Vector3(1.2, 0.8, 0),
			Vector3(-0.6, 1.9, -0.1), Vector3(0.7, 2.0, 0)]:
		var mi := MeshInstance3D.new()
		mi.mesh = BattleStage.unit_sphere()
		mi.material_override = material
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = puff
		mi.scale = Vector3(1.1, 0.9, 0.7)
		fog.add_child(mi)
	return fog


## A ring on the ground at pos and, for the portal itself, a pulsing see-through oval over
## it with its sign. Nothing to bump into.
func _build_portal(pos: Vector3, full: bool) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	add_child(root)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = PORTAL_COLOR
	var ring := TorusMesh.new()
	ring.inner_radius = 0.9
	ring.outer_radius = 1.05
	ring.rings = 24
	ring.ring_segments = 6
	var base := MeshInstance3D.new()
	base.mesh = ring
	base.material_override = material
	base.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	base.position.y = 0.05
	root.add_child(base)
	if not full:
		return root
	var oval := MeshInstance3D.new()
	oval.mesh = BattleStage.unit_sphere()
	oval.material_override = material
	oval.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	oval.position.y = PORTAL_SIZE.y
	oval.scale = PORTAL_SIZE
	root.add_child(oval)
	var label := Label3D.new()
	label.text = "Portal"
	label.font_size = 48
	label.pixel_size = 0.008
	label.outline_size = 10
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position.y = PORTAL_SIZE.y * 2.0 + 0.4
	root.add_child(label)
	var pulse := root.create_tween().set_loops()
	pulse.tween_property(oval, "scale", PORTAL_SIZE * PORTAL_PULSE, 0.6) \
		.set_trans(Tween.TRANS_SINE)
	pulse.tween_property(oval, "scale", PORTAL_SIZE, 0.6).set_trans(Tween.TRANS_SINE)
	return root


## Hides the water and the light of the wells in dry.
func set_dry_wells(dry: Array[String]) -> void:
	for id: String in _well_waters:
		(_well_waters[id] as Node3D).visible = not dry.has(id)
	_dry_wells = dry
	_refresh_map_marks()


## The kind (Wells.HP or Wells.MP) of the well id of this zone.
func _well_kind(id: String) -> String:
	for well: Dictionary in zone.wells:
		if well.id == id:
			return well.kind
	return Wells.HP


## A well: its model (green in the forest village, red elsewhere) on a cylinder collider,
## with a disc of coloured water inside the rim and a light over it.
func _build_well(well: Dictionary) -> void:
	var body := StaticBody3D.new()
	body.position = well.pos
	add_child(body)
	WorldStage.add_cylinder_shape(body, WELL_COLLIDER, 2.0)
	var model_id := "well_green" if zone.id == "bosque" else "well_red"
	BattleStage.add_model(body, WorldStage.MODELS[model_id], Vector3.ZERO,
		WorldStage.BUILDING_SCALE)
	var water := Node3D.new()
	water.position.y = WATER_HEIGHT
	body.add_child(water)
	var color := WATER_HP if well.kind == Wells.HP else WATER_MP
	var disc := CylinderMesh.new()
	disc.top_radius = WATER_RADIUS
	disc.bottom_radius = WATER_RADIUS
	disc.height = 0.05
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	var mesh := MeshInstance3D.new()
	mesh.mesh = disc
	mesh.material_override = material
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	water.add_child(mesh)
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 1.5
	light.omni_range = 4.0
	light.shadow_enabled = false
	light.position.y = 0.6
	water.add_child(light)
	_well_waters[well.id] = water


## A closed chest on a box collider under root: wooden box with a gold band around it and a lid on
## a pivot at its back edge. Returns the lid pivot.
static func build_chest(root: Node3D, chest: Dictionary) -> Node3D:
	var body := StaticBody3D.new()
	body.position = chest.pos
	body.rotation_degrees.y = chest.yaw
	root.add_child(body)
	var box := BoxShape3D.new()
	box.size = CHEST_SIZE + Vector3(0, CHEST_LID_HEIGHT, 0)
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position.y = box.size.y / 2.0
	body.add_child(shape)
	var base := BoxMesh.new()
	base.size = CHEST_SIZE
	BattleStage.add_mesh(body, base, CHEST_WOOD, Vector3(0, CHEST_SIZE.y / 2.0, 0))
	var band := BoxMesh.new()
	band.size = Vector3(CHEST_SIZE.x + 0.04, 0.08, CHEST_SIZE.z + 0.04)
	BattleStage.add_mesh(body, band, CHEST_BAND, Vector3(0, CHEST_SIZE.y * 0.7, 0))
	var lid := Node3D.new()
	lid.position = Vector3(0, CHEST_SIZE.y, CHEST_SIZE.z / 2.0)
	body.add_child(lid)
	var top := BoxMesh.new()
	top.size = Vector3(CHEST_SIZE.x, CHEST_LID_HEIGHT, CHEST_SIZE.z)
	BattleStage.add_mesh(lid, top, CHEST_WOOD,
		Vector3(0, CHEST_LID_HEIGHT / 2.0, -CHEST_SIZE.z / 2.0))
	var lock := BoxMesh.new()
	lock.size = Vector3(0.14, 0.16, 0.05)
	BattleStage.add_mesh(lid, lock, CHEST_BAND, Vector3(0, 0.0, -CHEST_SIZE.z - 0.02))
	var lid_band := BoxMesh.new()
	lid_band.size = Vector3(0.1, CHEST_LID_HEIGHT + 0.02, CHEST_SIZE.z + 0.02)
	for x in [-0.3, 0.3]:
		BattleStage.add_mesh(lid, lid_band, CHEST_BAND,
			Vector3(x, CHEST_LID_HEIGHT / 2.0, -CHEST_SIZE.z / 2.0))
	return lid


## A small medal at pos: a flat gold disc on the ground with a brighter core on top, both
## unshaded (they show in the dark mine too) and blinking slowly. No collider, no sign.
func _build_medal(pos: Vector3) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	root.visible = false
	add_child(root)
	var materials: Array[StandardMaterial3D] = []
	for part in [[MEDAL_DISC, 0.06, MEDAL_COLOR], [MEDAL_DISC * 0.5, 0.08, MEDAL_CORE_COLOR]]:
		var disc := CylinderMesh.new()
		disc.top_radius = part[0]
		disc.bottom_radius = part[0]
		disc.height = 0.02
		disc.radial_segments = 16
		disc.rings = 1
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color = part[2]
		materials.append(material)
		var mesh := MeshInstance3D.new()
		mesh.mesh = disc
		mesh.material_override = material
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mesh.position.y = part[1]
		root.add_child(mesh)
	var blink := root.create_tween().set_loops()
	blink.tween_property(materials[0], "albedo_color:a", 0.35, MEDAL_BLINK)
	blink.parallel().tween_property(materials[1], "albedo_color:a", 0.35, MEDAL_BLINK)
	blink.tween_property(materials[0], "albedo_color:a", 1.0, MEDAL_BLINK)
	blink.parallel().tween_property(materials[1], "albedo_color:a", 1.0, MEDAL_BLINK)
	return root


## A figure: a BattleActor on a cylinder collider, turned yaw_deg (180 faces south,
## toward the camera).
func _add_figure(look: BattleActor.Look, pos: Vector3, yaw_deg: float, radius: float, \
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


func _build_ui() -> void:
	_ui = CanvasLayer.new()
	add_child(_ui)
	# No size of its own: the column follows the status window as it grows and shrinks.
	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_TOP_LEFT)
	column.offset_left = UI_EDGE
	column.offset_top = UI_EDGE
	column.offset_right = UI_EDGE
	column.offset_bottom = UI_EDGE
	column.add_theme_constant_override("separation", 8)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(column)
	_status_column = column
	var panel := BattleHud.make_window()
	column.add_child(panel)
	_map_square = MapSquare.new(MapSquare.TOUCH_SIDE if Device.is_touch() else MapSquare.SIDE)
	_map_square.clickable = true
	_map_square.pressed.connect(func() -> void:
		if not _talking and not _waiting:
			map_requested.emit())
	_place_label = _label()
	_place_label.add_theme_font_size_override("font_size", UiStyle.TEXT_SIZE)
	_place_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_place_label.add_theme_constant_override("outline_size", PLACE_OUTLINE)
	_place_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if Device.is_touch():
		# Under the menu button, top right.
		_ui.add_child(_map_square)
		_map_square.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		_map_square.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		_map_square.offset_right = -PauseMenu.MENU_BUTTON_MARGIN
		_map_square.offset_left = _map_square.offset_right - MapSquare.TOUCH_SIDE
		_map_square.offset_top = PauseMenu.MENU_BUTTON_MARGIN + PauseMenu.MENU_BUTTON_SIZE.y + 8.0
		_map_square.offset_bottom = _map_square.offset_top + MapSquare.TOUCH_SIDE
		_ui.add_child(_place_label)
		_place_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_place_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		_place_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		_place_label.offset_right = _map_square.offset_right
		_place_label.offset_left = _map_square.offset_right
		_place_label.offset_top = _map_square.offset_bottom + 4.0
		_place_label.offset_bottom = _place_label.offset_top
	else:
		column.add_child(_place_label)
		column.add_child(_map_square)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	_name_label = _label()
	box.add_child(_name_label)
	_hp_bar = StatBar.new(StatBar.HP)
	box.add_child(_hp_bar)
	_mp_bar = StatBar.new(StatBar.MP)
	box.add_child(_mp_bar)
	_exp_bar = StatBar.new(StatBar.EXP)
	box.add_child(_exp_bar)
	_potion_label = _label()
	box.add_child(_potion_label)
	if Device.is_touch():
		# Estado and Objetos in the pause menu say the same.
		_exp_bar.hide()
		_potion_label.hide()
	_gold_label = _label()
	_gold_label.add_theme_color_override("font_color", StatBar.GOLD)
	box.add_child(_gold_label)
	_mission_box = VBoxContainer.new()
	_mission_box.add_theme_constant_override("separation", 0)
	box.add_child(_mission_box)
	_notice_window = BattleHud.make_window()
	_notice_window.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_notice_window.offset_left = 0
	_notice_window.offset_right = 0
	_notice_window.offset_top = UI_EDGE
	_notice_window.offset_bottom = UI_EDGE
	_notice_window.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_notice_window.hide()
	_ui.add_child(_notice_window)
	_notice = _label()
	_notice_window.add_child(_notice)
	_build_banner()
	_prompt = _label()
	_prompt.text = PROMPTS[TALK]
	_prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	_prompt.add_theme_constant_override("outline_size", 8)
	_ui.add_child(_prompt)
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, \
		Control.PRESET_MODE_MINSIZE, 200)
	_prompt.hide()
	if Device.is_touch():
		_build_touch_controls()
	_dialogue = DialogueBox.new()
	_ui.add_child(_dialogue)


## Phones: the pad behind every window, and the big use button.
func _build_touch_controls() -> void:
	_pad = TouchPad.new()
	_ui.add_child(_pad)
	_ui.move_child(_pad, 0)
	_pad.tapped.connect(_on_tapped)
	_pad.pinched.connect(_camera.zoom_by)
	_use_button = Button.new()
	_use_button.focus_mode = Control.FOCUS_NONE
	_use_button.add_theme_font_size_override("font_size", USE_BUTTON_FONT)
	_use_button.custom_minimum_size = USE_BUTTON_SIZE
	_use_button.hide()
	_ui.add_child(_use_button)
	_use_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_use_button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_use_button.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_use_button.offset_right = -UI_EDGE
	_use_button.offset_bottom = -UI_EDGE
	_use_button.offset_left = -UI_EDGE - USE_BUTTON_SIZE.x
	_use_button.offset_top = -UI_EDGE - USE_BUTTON_SIZE.y
	_use_button.pressed.connect(func() -> void: _use(_nearest_use(_player.global_position)))


## A line at the bottom until the hero first walks (phones, once: Game decides).
func show_touch_hint(text: String) -> void:
	if _hint_window == null:
		_hint_window = BattleHud.make_window()
		_hint_window.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ui.add_child(_hint_window)
		_hint_window.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		_hint_window.grow_horizontal = Control.GROW_DIRECTION_BOTH
		_hint_window.grow_vertical = Control.GROW_DIRECTION_BEGIN
		_hint_window.offset_left = 0.0
		_hint_window.offset_right = 0.0
		_hint_window.offset_bottom = -(UI_EDGE + USE_BUTTON_SIZE.y + 12.0)
		_hint_window.offset_top = _hint_window.offset_bottom
		_hint = _label()
		_hint_window.add_child(_hint)
	BattleHud.fit_label(_hint, text, TOUCH_HINT_WIDTH)
	_hint_window.show()


## Two lines centred near the top: the place and, under it, its floor.
func _build_banner() -> void:
	_banner = VBoxContainer.new()
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.add_theme_constant_override("separation", 0)
	_ui.add_child(_banner)
	_banner.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_banner.offset_top = BANNER_TOP
	_banner.offset_bottom = BANNER_TOP
	for font_size in [BANNER_NAME_FONT, BANNER_FLOOR_FONT]:
		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_font_size_override("font_size", font_size)
		label.add_theme_color_override("font_color", BANNER_COLOR)
		label.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.0))
		label.add_theme_constant_override("outline_size", 12)
		_banner.add_child(label)
	_banner.hide()


## Fades the place's name in, holds it and fades it out.
func _show_banner() -> void:
	var name_label := _banner.get_child(0) as Label
	var floor_label := _banner.get_child(1) as Label
	name_label.text = zone.display_name
	floor_label.text = zone.floor_name
	floor_label.visible = zone.floor_name != ""
	if _autoplay:
		print("Lugar: %s" % zone.banner_text())
	if _banner_tween:
		_banner_tween.kill()
	_banner.modulate.a = 0.0
	_banner.show()
	_banner_tween = create_tween()
	_banner_tween.tween_property(_banner, "modulate:a", 1.0, BANNER_FADE)
	_banner_tween.tween_interval(BANNER_TIME)
	_banner_tween.tween_property(_banner, "modulate:a", 0.0, BANNER_FADE)
	_banner_tween.tween_callback(_banner.hide)


func _label() -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", Color.WHITE)
	return label


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
