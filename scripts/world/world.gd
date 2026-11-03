class_name World extends Node3D
## World map: field, village, player, follow camera, status window and random
## encounters. A click or tap on the ground (held and dragged too) walks the player
## there, with a marker on the spot. Next to the old woman Enter / Space asks to talk
## (talk_requested); a click or tap on her walks there and talks on arrival. With the
## Rey Slime present, walking into it starts the boss battle. Encounters emit
## encounter_triggered(boss) and freeze the player until set_active(true). Run on its
## own (res://scenes/world/world.tscn) it prints each encounter and goes on.

signal encounter_triggered(boss: bool)
signal talk_requested
## The player walked into (true) or out of (false) the village clearing.
signal village_changed(inside: bool)

const PLAYER_SCENE := preload("res://scenes/world/player.tscn")
const ACTOR_SCENE := preload("res://scenes/battle/battle_actor.tscn")
const HERO_DATA := preload("res://data/hero.tres")
const NOTICE_TIME := 2.0
const FONT_SIZE := 24
## How close the player must be to talk to the old woman / to run into the boss.
const TALK_RADIUS := 2.5
const BOSS_RADIUS := 2.5
## A click or tap this close to the old woman means "go and talk to her".
const NPC_TAP_RADIUS := 1.2
const PROMPT_TEXT := "Enter o toca: hablar"
const MARKER_COLOR := Color(1.0, 0.9, 0.4)
## Meters walked between two footstep sounds.
const STEP_DISTANCE := 1.6

var _rng := RandomNumberGenerator.new()
var _meter: EncounterMeter
var _grass: ShaderMaterial
var _player: Player
var _camera: FollowCamera
var _npc: StaticBody3D
var _boss: StaticBody3D
var _boss_present := false
var _ui: CanvasLayer
var _name_label: Label
var _hp_label: Label
var _mp_label: Label
var _exp_label: Label
var _potion_label: Label
var _quest_label: Label
var _notice: Label
var _prompt: Label
var _dialogue: DialogueBox
var _autoplay := false
var _waiting := false
var _talking := false
var _was_near := false
## Set by a click or tap on the old woman: talk as soon as she is in reach.
var _talk_on_arrival := false
var _marker: MeshInstance3D
var _audio: AudioDirector
var _in_village := false
var _step_m := 0.0


func _ready() -> void:
	_rng.randomize()
	_autoplay = OS.get_cmdline_user_args().has("--autoplay")
	_meter = EncounterMeter.new(_rng)
	_grass = WorldStage.build(self)
	_npc = _add_figure(BattleActor.Look.VILLAGER, WorldStage.NPC_POS, 0.4, 1.8)
	_boss = _add_figure(BattleActor.Look.KING_SLIME, WorldStage.BOSS_POS, 1.0, 2.0)
	set_boss_present(false)
	_player = PLAYER_SCENE.instantiate()
	add_child(_player)
	_camera = FollowCamera.new()
	add_child(_camera)
	_camera.target = _player
	_marker = _build_marker()
	_build_ui()
	respawn()
	_camera.current = true
	if get_parent() == get_tree().root:
		refresh_status(HERO_DATA, Inventory.START_POTIONS)
		encounter_triggered.connect(_on_standalone_encounter)
		talk_requested.connect(_on_standalone_talk)


func _physics_process(_delta: float) -> void:
	Vegetation.set_pusher(_grass, _player.global_position)
	_marker.visible = _player.move_target != null
	if _marker.visible:
		_marker.position = _player.move_target
	if _waiting or _talking:
		return
	var pos := _player.global_position
	var inside := _is_in_village(pos)
	if inside != _in_village:
		_in_village = inside
		village_changed.emit(inside)
	_play_steps()
	if _boss_present and _flat_distance(pos, WorldStage.BOSS_POS) <= BOSS_RADIUS:
		_trigger(true)
		return
	var in_grass := not WorldStage.is_on_path(pos)
	if _meter.advance(_player.last_step_m, in_grass):
		_trigger(false)
		return
	var near := _flat_distance(pos, WorldStage.NPC_POS) <= TALK_RADIUS
	_prompt.visible = near
	if near and _talk_on_arrival:
		_talk_on_arrival = false
		_player.move_target = null
		talk_requested.emit()
	elif near and not _was_near and _autoplay:
		talk_requested.emit()
	_was_near = near


func _unhandled_input(event: InputEvent) -> void:
	if _waiting or _talking:
		return
	if _prompt.visible and event.is_action_pressed("ui_accept") and not event.is_echo():
		get_viewport().set_input_as_handled()
		talk_requested.emit()
		return
	var point: Variant = _pointer_on_ground(event)
	if point == null:
		return
	get_viewport().set_input_as_handled()
	if event is InputEventMouseButton:
		_talk_on_arrival = _flat_distance(point, WorldStage.NPC_POS) <= NPC_TAP_RADIUS
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
	var ground := Plane(Vector3.UP, 0.0)
	return ground.intersects_ray(_camera.project_ray_origin(screen),
		_camera.project_ray_normal(screen))


## Hidden and frozen while a battle is on top; back on, the encounter grace restarts.
func set_active(active: bool) -> void:
	process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	visible = active
	_ui.visible = active
	_camera.current = active
	if active:
		_meter.reset()
		_waiting = false
		_player.input_enabled = true


## Back to the spawn point facing up the path, with the encounter grace restarted.
func respawn() -> void:
	place_player(WorldStage.SPAWN_POS)


## Puts the player at pos facing north (a loaded game), with the encounter grace
## restarted. in_village() is right at once; village_changed is not emitted.
func place_player(pos: Vector3) -> void:
	_player.place(pos, 0.0)
	_camera.snap()
	_meter.reset()
	_was_near = false
	_step_m = 0.0
	_in_village = _is_in_village(pos)


func player_position() -> Vector3:
	return _player.global_position


func in_village() -> bool:
	return _in_village


## Footsteps, encounter and dialogue sounds. Without it the map is silent.
func set_audio(audio: AudioDirector) -> void:
	_audio = audio
	_dialogue.set_audio(audio)


## Shows or removes the Rey Slime north of the village; when absent it has no collision.
func set_boss_present(present: bool) -> void:
	_boss_present = present
	_boss.visible = present
	_boss.process_mode = Node.PROCESS_MODE_INHERIT if present else Node.PROCESS_MODE_DISABLED


## Freezes the player and shows the lines one by one; returns when they are all read.
func show_dialogue(speaker: String, lines: Array[String]) -> void:
	_talking = true
	_player.input_enabled = false
	_prompt.hide()
	await _dialogue.say(speaker, lines)
	# One frame of margin so the key that closed the dialogue does not open it again.
	await get_tree().process_frame
	_player.input_enabled = true
	_talking = false


func refresh_status(hero: Combatant, potions: int, quest_text := "") -> void:
	_name_label.text = "%s  Nv %d" % [hero.display_name, hero.level]
	_hp_label.text = "PV %d / %d" % [hero.hp, hero.max_hp]
	_mp_label.text = "PM %d / %d" % [hero.mp, hero.max_mp]
	var next := Leveling.exp_for_next(hero.level)
	if next < 0:
		_exp_label.text = "EXP %d" % hero.experience
	else:
		_exp_label.text = "EXP %d / %d" % [hero.experience, next]
	_potion_label.text = "%s ×%d" % [Inventory.display_name(Inventory.POTION), potions]
	_quest_label.text = quest_text
	_quest_label.visible = quest_text != ""


## Shows a short line under the status for NOTICE_TIME seconds.
func show_notice(text: String) -> void:
	_notice.text = text
	_notice.show()
	await get_tree().create_timer(NOTICE_TIME).timeout
	_notice.hide()


func _trigger(boss: bool) -> void:
	if _audio:
		_audio.play_sfx(SfxLibrary.ENCOUNTER)
	_waiting = true
	_player.input_enabled = false
	_prompt.hide()
	encounter_triggered.emit(boss)


func _on_standalone_encounter(boss: bool) -> void:
	print("Encuentro en %s (jefe: %s, en el camino: %s)" % [
		_player.global_position, boss, WorldStage.is_on_path(_player.global_position)])
	set_active(true)


func _on_standalone_talk() -> void:
	var lines: Array[String] = ["Hola, viajero."]
	await show_dialogue(Quest.NPC_NAME, lines)


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


## A village figure: a BattleActor on a cylinder collider, facing south (toward the
## spawn).
func _add_figure(look: BattleActor.Look, pos: Vector3, radius: float, \
		height: float) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	body.rotation.y = PI
	add_child(body)
	WorldStage.add_cylinder_shape(body, radius, height)
	var actor: BattleActor = ACTOR_SCENE.instantiate()
	actor.look = look
	body.add_child(actor)
	return body


func _build_ui() -> void:
	_ui = CanvasLayer.new()
	add_child(_ui)
	var panel := BattleHud.make_window()
	panel.position = Vector2(24, 24)
	panel.custom_minimum_size = Vector2(240, 0)
	_ui.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	_name_label = _label()
	box.add_child(_name_label)
	_hp_label = _label()
	box.add_child(_hp_label)
	_mp_label = _label()
	box.add_child(_mp_label)
	_exp_label = _label()
	box.add_child(_exp_label)
	_potion_label = _label()
	box.add_child(_potion_label)
	_quest_label = _label()
	_quest_label.hide()
	box.add_child(_quest_label)
	_notice = _label()
	_notice.hide()
	box.add_child(_notice)
	_prompt = _label()
	_prompt.text = PROMPT_TEXT
	_prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	_prompt.add_theme_constant_override("outline_size", 8)
	_ui.add_child(_prompt)
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, \
		Control.PRESET_MODE_MINSIZE, 200)
	_prompt.hide()
	_dialogue = DialogueBox.new()
	_ui.add_child(_dialogue)


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
	if _audio:
		_audio.play_sfx(SfxLibrary.STEP)


static func _is_in_village(pos: Vector3) -> bool:
	return _flat_distance(pos, WorldStage.CLEARING_POS) <= WorldStage.CLEARING_RADIUS


static func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))
