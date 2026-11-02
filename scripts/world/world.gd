class_name World extends Node3D
## World map: field, player, follow camera, status window and random encounters.
## Emits encounter_triggered and freezes the player until set_active(true). Run on
## its own (res://scenes/world/world.tscn) it only prints each encounter and goes on.

signal encounter_triggered

const PLAYER_SCENE := preload("res://scenes/world/player.tscn")
const HERO_DATA := preload("res://data/hero.tres")
const NOTICE_TIME := 2.0
const FONT_SIZE := 24

var _rng := RandomNumberGenerator.new()
var _meter: EncounterMeter
var _player: Player
var _camera: FollowCamera
var _ui: CanvasLayer
var _name_label: Label
var _hp_label: Label
var _exp_label: Label
var _notice: Label
var _waiting := false


func _ready() -> void:
	_rng.randomize()
	_meter = EncounterMeter.new(_rng)
	WorldStage.build(self)
	_player = PLAYER_SCENE.instantiate()
	add_child(_player)
	_camera = FollowCamera.new()
	add_child(_camera)
	_camera.target = _player
	_player.camera = _camera
	_build_status()
	respawn()
	_camera.current = true
	if get_parent() == get_tree().root:
		refresh_status(HERO_DATA)
		encounter_triggered.connect(_on_standalone_encounter)


func _physics_process(_delta: float) -> void:
	if _waiting:
		return
	var in_grass := not WorldStage.is_on_path(_player.global_position)
	if _meter.advance(_player.last_step_m, in_grass):
		_waiting = true
		_player.input_enabled = false
		encounter_triggered.emit()


## Hidden and frozen while a battle is on top; back on, the encounter grace restarts.
func set_active(active: bool) -> void:
	process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	visible = active
	_ui.visible = active
	if active:
		_camera.current = true
		_meter.reset()
		_waiting = false
		_player.input_enabled = true


## Back to the spawn point facing up the path, with the encounter grace restarted.
func respawn() -> void:
	_player.place(WorldStage.SPAWN_POS, 0.0)
	_camera.yaw = 0.0
	_camera.snap()
	_meter.reset()


func refresh_status(hero: Combatant) -> void:
	_name_label.text = hero.display_name
	_hp_label.text = "PV %d / %d" % [hero.hp, hero.max_hp]
	_exp_label.text = "EXP %d" % hero.experience


## Shows a short line under the status for NOTICE_TIME seconds.
func show_notice(text: String) -> void:
	_notice.text = text
	_notice.show()
	await get_tree().create_timer(NOTICE_TIME).timeout
	_notice.hide()


func _on_standalone_encounter() -> void:
	print("Encuentro en %s (en el camino: %s)" % [
		_player.global_position, WorldStage.is_on_path(_player.global_position)])
	set_active(true)


func _build_status() -> void:
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
	_exp_label = _label()
	box.add_child(_exp_label)
	_notice = _label()
	_notice.hide()
	box.add_child(_notice)


func _label() -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", Color.WHITE)
	return label
