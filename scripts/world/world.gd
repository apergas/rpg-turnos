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
## Its jobs are split into pieces it owns and calls in a fixed order from _physics_process:
## MapHud (the 2D layer), MapProps (exits, portal, wells, chests, the walk marker),
## MapFigures (figures, signs, quest marks), MapMonsters (the groups), AutoplayHunter (the
## autoplay's hunt) and MapUses (what is in reach, taps, exits). Its public methods are
## façades of them and its signals are unchanged.

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
## How close the player must be to run into the boss.
const BOSS_RADIUS := 2.5
## After a boss battle the boss waits until the hero has been this far from it (a boss
## fought again and again, the Eco de la Niebla, must not start over at once).
const BOSS_REARM_RADIUS := 5.0
## Taps on the map are ignored this long after a dialogue or a window closes.
const TAP_GUARD_MS := 400
## Meters walked between two footstep sounds.
const STEP_DISTANCE := 1.6
## Underground the hero carries a warm lantern light (not in the Cuevas: crystals light it).
const LANTERN_COLOR := Color(1.0, 0.85, 0.65)
const LANTERN_ENERGY := 2.0
const LANTERN_RANGE := 10.0
const LANTERN_HEIGHT := 2.4

## The map to build; set before add_child.
var zone: ZoneData
## The boss to stand at zone.boss_pos (EnemyLibrary id); set before add_child. "" takes
## zone.boss_id. Game passes the Eco de la Niebla once the game is finished.
var boss_id := ""

var _hud: MapHud
var _props: MapProps
var _monsters: MapMonsters
var _uses: MapUses
var _hunter: AutoplayHunter

var _grass: ShaderMaterial
var _player: Player
var _camera: FollowCamera
var _boss: StaticBody3D
## The figures (npcs and the boss), their signs and quest marks.
var _figures: MapFigures
## What a cutscene's camera looks at (camera_to); null until the first one.
var _camera_spot: Node3D
## The cells of a dungeon floor (null on an open map).
var _dungeon: DungeonMap
var _flags := {}
var _boss_present := false
## False from a boss battle until the hero walks BOSS_REARM_RADIUS away from the boss.
var _boss_armed := true
var _autoplay := false
var _waiting := false
var _talking := false
## Taps on the map count from this time on (Time.get_ticks_msec()).
var _taps_from_ms := 0
var _audio: AudioDirector
var _in_village := false
var _step_m := 0.0
## The zone's ZoneParticles (null: none, or low quality), carried with the hero.
var _particles: Node3D
## Time of the simulation in ms (the hunt's timers count it, so a run with --fixed-fps keeps them).
var _sim_ms := 0.0
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
	# Every piece exists from here on (set_world_flags() below reaches them all); each is
	# added to the tree where its nodes used to be built, so the node order is unchanged.
	_hud = MapHud.new()
	_hud.setup(zone)
	_player = PLAYER_SCENE.instantiate()
	_camera = FollowCamera.new()
	_figures = MapFigures.new()
	_figures.setup(zone, _player)
	_monsters = MapMonsters.new()
	_monsters.setup(zone, _player)
	_hunter = AutoplayHunter.new()
	_hunter.setup(zone, _player, _monsters)
	_monsters.groups_reset.connect(_hunter.forget)
	_props = MapProps.new()
	_props.setup(zone)
	_uses = MapUses.new()
	_uses.setup(zone, _player, _camera, _hud, _figures, _props, _dungeon)
	_forward_use_signals()
	add_child(_figures)
	_figures.build()
	if boss_id == "":
		boss_id = zone.boss_id
	if boss_id != "":
		_boss = _figures.add_figure(EnemyLibrary.look(boss_id), zone.boss_pos, 180.0, 1.0, 2.0)
	add_child(_props)
	_props.build()
	set_boss_present(false)
	set_world_flags({})
	_player.route = zone.autoplay_route
	add_child(_player)
	if zone.underground and not zone.crystals:
		var lantern := OmniLight3D.new()
		lantern.light_color = LANTERN_COLOR
		lantern.light_energy = LANTERN_ENERGY
		lantern.omni_range = LANTERN_RANGE
		lantern.position.y = LANTERN_HEIGHT
		_player.add_child(lantern)
	_particles = ZoneParticles.build(zone.particles)
	if _particles:
		add_child(_particles)
	add_child(_camera)
	_camera.target = _player
	_props.build_marker()
	_hud.map_pressed.connect(_on_map_pressed)
	_hud.tapped.connect(_on_tapped)
	_hud.pinched.connect(_camera.zoom_by)
	_hud.use_pressed.connect(_uses.use_nearest)
	add_child(_hud)
	add_child(_uses)
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
			_uses.drop_errand()  # walking off by hand drops the tap's errand
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
	var exit := _uses.check_exits(pos)
	if not exit.is_empty():
		_take_exit(exit)
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
	if _autoplay and _hunter.is_on() and not _monsters.is_repelled():
		_hunter.step(pos, int(_sim_ms))
	_uses.step(pos)


func _unhandled_input(event: InputEvent) -> void:
	if _waiting or _talking:
		return
	if _uses.prompt_showing() and event.is_action_pressed("ui_accept") and not event.is_echo():
		get_viewport().set_input_as_handled()
		_uses.use_nearest()
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
		_uses.aim_at((event as InputEventMouseButton).position)
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
	_uses.aim_at(screen)
	_player.move_to(point)


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
	_uses.forget_near()
	_uses.drop_errand()
	_step_m = 0.0
	_uses.disarm_exits()
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
	_uses.set_flags(flags)
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
	_hunter.set_on(on)


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
	_uses.drop_errand()
	_hud.begin_cutscene()
	_figures.show_marks()
	_uses.forget_covered_signs()
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
	_uses.forget_near()
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
		_uses.hide_prompt()
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


## The hero walked into an open exit (MapUses.check_exits()): the map waits for Game.
func _take_exit(exit: Dictionary) -> void:
	_waiting = true
	_player.input_enabled = false
	_uses.hide_prompt()
	_reset_pad()
	exit_requested.emit(exit.to, exit.entry)


## The uses of MapUses go out under World's own signals: Game connects to those.
func _forward_use_signals() -> void:
	_uses.talk_requested.connect(talk_requested.emit)
	_uses.npc_requested.connect(npc_requested.emit)
	_uses.shop_requested.connect(shop_requested.emit)
	_uses.inn_requested.connect(inn_requested.emit)
	_uses.chest_opened.connect(chest_opened.emit)
	_uses.well_requested.connect(well_requested.emit)
	_uses.lever_pulled.connect(lever_pulled.emit)
	_uses.key_taken.connect(key_taken.emit)
	_uses.door_used.connect(door_used.emit)
	_uses.portal_used.connect(portal_used.emit)


func _trigger(boss: bool) -> void:
	if boss:
		_boss_armed = false
	if _audio:
		_audio.play_sfx(SfxLibrary.ENCOUNTER)
	_waiting = true
	_player.input_enabled = false
	_uses.hide_prompt()
	_reset_pad()
	encounter_triggered.emit(boss)


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
