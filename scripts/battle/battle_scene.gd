class_name BattleScene extends Node3D
## One battle: builds the stage, actors, camera and UI, asks the HUD for the hero's
## command, lets BattleEngine resolve the round and plays the events back. Call setup()
## before adding it to the tree; it emits finished(won) when the player continues.
## With `-- --autoplay` it picks commands by itself (_autoplay_command), prints every
## battle message and continues on its own.

signal finished(won: bool)

const ACTOR_SCENE := preload("res://scenes/battle/battle_actor.tscn")
const HUD_SCENE := preload("res://scenes/ui/battle_hud.tscn")
const RESULT_SCENE := preload("res://scenes/ui/battle_result.tscn")

const HERO_POS := Vector3(-1.0, 0, 1.8)
const ENEMY_POS := Vector3(0.6, 0, -2.4)
const CAMERA_POS := Vector3(0.8, 2.6, 6.0)
const CAMERA_FOV := 50.0
## How far the camera moves toward the target during an attack (0..1).
const CAMERA_FOCUS := 0.18
## Autoplay drinks a potion below this share of max HP.
const AUTOPLAY_POTION_RATIO := 0.4
## Autoplay casts only while the enemy has more HP than this.
const AUTOPLAY_CAST_MIN_HP := 12

var engine: BattleEngine
var hero: Combatant
var enemy: Combatant
var inventory: Inventory

var _rng := RandomNumberGenerator.new()
var _autoplay := false
var _done := false
var _new_level := 0
var _got_potion := false
## Color of the last spell cast, used for the hit that follows it.
var _spell_color := BattleActor.FIRE_COLOR
var _hero_actor: BattleActor
var _enemy_actor: BattleActor
var _camera: Camera3D
var _camera_home: Vector3
var _cam_tween: Tween
var _shake_tween: Tween
var _hud: BattleHud
var _result: BattleResult


## The hero and the inventory are used as is, so HP, MP, EXP and potions stay with the
## caller; the enemy data is duplicated so the .tres file never changes.
func setup(hero_ref: Combatant, enemy_data: Combatant, inv: Inventory) -> void:
	hero = hero_ref
	enemy = enemy_data.duplicate() as Combatant
	inventory = inv


func _ready() -> void:
	assert(hero != null and enemy != null and inventory != null,
		"Call setup() before adding BattleScene to the tree")
	_rng.randomize()
	_autoplay = OS.get_cmdline_user_args().has("--autoplay")
	BattleStage.build(self)
	_hero_actor = _spawn_actor(BattleActor.Look.HERO, HERO_POS, ENEMY_POS)
	var enemy_look := BattleActor.Look.KING_SLIME if enemy.is_boss else BattleActor.Look.SLIME
	_enemy_actor = _spawn_actor(enemy_look, ENEMY_POS, HERO_POS)
	_build_camera()
	var ui := CanvasLayer.new()
	add_child(ui)
	_hud = HUD_SCENE.instantiate() as BattleHud
	ui.add_child(_hud)
	_hud.command_chosen.connect(_on_command_chosen)
	_result = RESULT_SCENE.instantiate() as BattleResult
	ui.add_child(_result)
	_result.continue_requested.connect(_finish)
	engine = BattleEngine.new(hero, enemy, _rng, inventory)
	_hud.set_hero(hero, inventory.count(Inventory.POTION))
	var intro := "¡El %s te cierra el paso!" if enemy.is_boss else "¡Un %s salvaje aparece!"
	await _say(intro % enemy.display_name)
	_ask_command()


func _ask_command() -> void:
	if _autoplay:
		await get_tree().create_timer(0.4).timeout
		_on_command_chosen(_autoplay_command())
	else:
		_hud.show_menu()


## Potion when low on HP, Llama while the enemy is still healthy, otherwise Atacar.
func _autoplay_command() -> Dictionary:
	var potion := BattleEngine.cmd_item(Inventory.POTION)
	if hero.hp < hero.max_hp * AUTOPLAY_POTION_RATIO and engine.can_use(potion):
		return potion
	if not hero.skills.is_empty():
		var spell := BattleEngine.cmd_skill(hero.skills[0])
		if enemy.hp > AUTOPLAY_CAST_MIN_HP and engine.can_use(spell):
			return spell
	return BattleEngine.cmd_attack()


func _on_command_chosen(cmd: Dictionary) -> void:
	_hud.hide_menu()
	for event in engine.resolve_round(cmd):
		await _play_event(event)
	match engine.state:
		BattleEngine.State.ONGOING:
			_ask_command()
			return
		BattleEngine.State.WON:
			_result.show_victory(enemy.exp_reward, hero.experience, _new_level, _got_potion)
		BattleEngine.State.LOST:
			_result.show_defeat()
	if _autoplay:
		await get_tree().create_timer(2.0).timeout
		_result.hide()
		_finish()


## Emits finished once, whether the player pressed "Continuar" or autoplay did.
func _finish() -> void:
	if _done:
		return
	_done = true
	finished.emit(engine.state == BattleEngine.State.WON)


## Every battle message goes through here; autoplay also prints it.
func _say(text: String) -> void:
	if _autoplay:
		print(text)
	await _hud.show_message(text)


func _play_event(event: Dictionary) -> void:
	match event.type:
		BattleEvent.ATTACK:
			var target := _actor(event.target)
			await _say("¡%s ataca!" % _fighter(event.actor).display_name)
			_focus_camera(target)
			await _actor(event.actor).play_attack(target.global_position)
		BattleEvent.SKILL:
			if event.actor == BattleEvent.HERO:
				_hud.update_mp(event.mp_left, hero.max_mp)
			_spell_color = event.color
			await _say("¡%s lanza %s!" % [_fighter(event.actor).display_name, event.name])
			_focus_camera(_actor(event.target))
			await _actor(event.actor).play_cast(_spell_color)
		BattleEvent.MISS:
			await _actor(event.target).play_dodge()
			_reset_camera()
			await _say("¡Pero falla!")
		BattleEvent.DAMAGE:
			if event.crit:
				_shake_camera()
			if event.magic:
				await _actor(event.target).play_burn(event.amount, _spell_color)
				_spell_color = BattleActor.FIRE_COLOR
			else:
				await _actor(event.target).play_hit(event.amount, event.crit)
			_reset_camera()
			if event.target == BattleEvent.HERO:
				_hud.update_hp(event.hp_left, hero.max_hp)
			if event.crit:
				await _say("¡Golpe crítico!")
			await _say("¡%s recibe %d de daño!" % [
				_fighter(event.target).display_name, event.amount])
		BattleEvent.ITEM:
			_hud.set_potions(inventory.count(Inventory.POTION))
			await _say("¡%s usa una %s!" % [_fighter(event.actor).display_name, event.name])
		BattleEvent.HEAL:
			await _actor(event.target).play_heal(event.amount)
			if event.target == BattleEvent.HERO:
				_hud.update_hp(event.hp_left, hero.max_hp)
			await _say("¡%s recupera %d PV!" % [
				_fighter(event.target).display_name, event.amount])
		BattleEvent.STAGGER:
			await _actor(event.actor).play_stagger()
			await _say("El %s se tambalea." % _fighter(event.actor).display_name)
		BattleEvent.DEFEATED:
			await _actor(event.target).play_defeat()
			if event.target == BattleEvent.ENEMY:
				await _say("¡%s ha sido derrotado!" % enemy.display_name)
			else:
				await _say("¡Has sido derrotado...!")
		BattleEvent.VICTORY:
			_hero_actor.play_cheer()
			await _say("¡Has ganado! Obtienes %d EXP." % event.exp)
		BattleEvent.LEVEL_UP:
			_new_level = event.level
			_hud.update_level(event.level)
			_hud.update_hp(event.hp, event.max_hp)
			_hud.update_mp(event.mp, event.max_mp)
			await _say("¡%s sube al nivel %d!" % [hero.display_name, event.level])
			await _say(_gains_text(event.gains))
		BattleEvent.DROP:
			_got_potion = true
			await _say("¡El %s ha dejado una %s!" % [
				enemy.display_name, Inventory.display_name(event.item)])


func _gains_text(gains: Dictionary) -> String:
	return "PV +%d  PM +%d  ATK +%d  DEF +%d  VEL +%d" % [
		gains.max_hp, gains.max_mp, gains.attack, gains.defense, gains.speed]


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
