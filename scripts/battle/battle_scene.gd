extends Node3D
## Battle screen: builds the stage, actors, camera and UI, asks the HUD for the
## hero's order, lets BattleEngine resolve the round and plays the events back.
## Run with `-- --autoplay` to pick "Atacar" automatically and restart after each battle.

const HERO_DATA := preload("res://data/hero.tres")
const SLIME_DATA := preload("res://data/slime.tres")
const ACTOR_SCENE := preload("res://scenes/battle/battle_actor.tscn")
const HUD_SCENE := preload("res://scenes/ui/battle_hud.tscn")
const RESULT_SCENE := preload("res://scenes/ui/battle_result.tscn")

const HERO_POS := Vector3(-1.0, 0, 1.8)
const ENEMY_POS := Vector3(0.6, 0, -2.4)
const CAMERA_POS := Vector3(0.8, 2.6, 6.0)
const CAMERA_FOV := 50.0
## How far the camera moves toward the target during an attack (0..1).
const CAMERA_FOCUS := 0.18

var engine: BattleEngine
var hero: Combatant
var enemy: Combatant

var _rng := RandomNumberGenerator.new()
var _autoplay := false
var _hero_actor: BattleActor
var _enemy_actor: BattleActor
var _camera: Camera3D
var _camera_home: Vector3
var _cam_tween: Tween
var _shake_tween: Tween
var _hud: BattleHud
var _result: BattleResult


func _ready() -> void:
	_rng.randomize()
	_autoplay = OS.get_cmdline_user_args().has("--autoplay")
	BattleStage.build(self)
	_hero_actor = _spawn_actor(BattleActor.Look.HERO, HERO_POS, ENEMY_POS)
	_enemy_actor = _spawn_actor(BattleActor.Look.SLIME, ENEMY_POS, HERO_POS)
	_build_camera()
	var ui := CanvasLayer.new()
	add_child(ui)
	_hud = HUD_SCENE.instantiate() as BattleHud
	ui.add_child(_hud)
	_hud.command_chosen.connect(_on_command_chosen)
	_result = RESULT_SCENE.instantiate() as BattleResult
	ui.add_child(_result)
	_result.retry_requested.connect(_start_battle)
	_start_battle()


func _start_battle() -> void:
	var carried_exp := hero.experience if hero else 0
	hero = HERO_DATA.duplicate() as Combatant
	hero.experience = carried_exp
	enemy = SLIME_DATA.duplicate() as Combatant
	engine = BattleEngine.new(hero, enemy, _rng)
	_hero_actor.reset()
	_enemy_actor.reset()
	_hud.set_hero(hero)
	await _hud.show_message("¡Un %s salvaje aparece!" % enemy.display_name)
	_ask_command()


func _ask_command() -> void:
	if _autoplay:
		await get_tree().create_timer(0.4).timeout
		_on_command_chosen(BattleEngine.CMD_ATTACK)
	else:
		_hud.show_menu()


func _on_command_chosen(cmd: String) -> void:
	_hud.hide_menu()
	for event in engine.resolve_round(cmd):
		await _play_event(event)
	if engine.state == BattleEngine.State.ONGOING:
		_ask_command()
	elif _autoplay:
		await get_tree().create_timer(2.0).timeout
		_result.hide()
		_start_battle()


func _play_event(event: Dictionary) -> void:
	match event.type:
		BattleEvent.ATTACK:
			var target := _actor(event.target)
			await _hud.show_message("¡%s ataca!" % _fighter(event.actor).display_name)
			_focus_camera(target)
			await _actor(event.actor).play_attack(target.global_position)
		BattleEvent.MISS:
			await _actor(event.target).play_dodge()
			_reset_camera()
			await _hud.show_message("¡Pero falla!")
		BattleEvent.DAMAGE:
			if event.crit:
				_shake_camera()
			await _actor(event.target).play_hit(event.amount, event.crit)
			_reset_camera()
			if event.target == BattleEvent.HERO:
				_hud.update_hp(event.hp_left, hero.max_hp)
			if event.crit:
				await _hud.show_message("¡Golpe crítico!")
			await _hud.show_message("¡%s recibe %d de daño!" % [
				_fighter(event.target).display_name, event.amount])
		BattleEvent.DEFEATED:
			await _actor(event.target).play_defeat()
			if event.target == BattleEvent.ENEMY:
				await _hud.show_message("¡%s ha sido derrotado!" % enemy.display_name)
			else:
				await _hud.show_message("¡Has sido derrotado...!")
		BattleEvent.VICTORY:
			await _hud.show_message("¡Has ganado! Obtienes %d EXP." % event.exp)
			_result.show_victory(event.exp, hero.experience)
		BattleEvent.DEFEAT:
			_result.show_defeat()


func _spawn_actor(look: BattleActor.Look, pos: Vector3, facing: Vector3) -> BattleActor:
	var actor: BattleActor = ACTOR_SCENE.instantiate()
	actor.look = look
	add_child(actor)
	actor.position = pos
	actor.look_at(facing, Vector3.UP)
	return actor


func _build_camera() -> void:
	_camera = Camera3D.new()
	_camera.fov = CAMERA_FOV
	add_child(_camera)
	_camera.position = CAMERA_POS
	_camera.look_at(ENEMY_POS.lerp(HERO_POS, 0.35) + Vector3(0, 0.8, 0), Vector3.UP)
	_camera.current = true
	_camera_home = _camera.global_position


func _focus_camera(target: Node3D) -> void:
	var goal := _camera_home.lerp(target.global_position + Vector3(0, 1, 0), CAMERA_FOCUS)
	_new_cam_tween().tween_property(_camera, "global_position", goal, 0.25) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _reset_camera() -> void:
	_new_cam_tween().tween_property(_camera, "global_position", _camera_home, 0.3) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _shake_camera() -> void:
	if _shake_tween:
		_shake_tween.kill()
	var t := create_tween()
	_shake_tween = t
	for i in 6:
		t.tween_property(_camera, "h_offset", randf_range(-0.12, 0.12), 0.04)
		t.parallel().tween_property(_camera, "v_offset", randf_range(-0.08, 0.08), 0.04)
	t.tween_property(_camera, "h_offset", 0.0, 0.04)
	t.parallel().tween_property(_camera, "v_offset", 0.0, 0.04)


## Only one camera position tween at a time, otherwise two tweens fight over it.
func _new_cam_tween() -> Tween:
	if _cam_tween:
		_cam_tween.kill()
	_cam_tween = create_tween()
	return _cam_tween


func _actor(side: String) -> BattleActor:
	return _hero_actor if side == BattleEvent.HERO else _enemy_actor


func _fighter(side: String) -> Combatant:
	return hero if side == BattleEvent.HERO else enemy
