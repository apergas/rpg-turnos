class_name BattleScene extends Node3D
## One battle against one or two enemies: builds the stage, actors, camera, target arrow
## and UI, asks the HUD for the hero's command, lets BattleEngine resolve the round and
## plays the events back. Call setup() before adding it to the tree; it emits
## finished(outcome) (a BattleEngine.State: WON, LOST or FLED) when it is over.
## With `-- --autoplay` BattleAutoplay picks the commands (shown on the HUD with
## BattleHud.demo()); to show Huir and Defender it flees from one normal battle out of
## AUTOPLAY_EVERY and defends in the first round of another one. It prints every battle
## message and continues on its own. After the enemies appear the engine rolls the
## surprise (BattleEngine.roll_ambush()): it is said before the first menu, and an enemy
## surprise plays its round first. With set_audio() it plays the sound effects and
## the victory or defeat music; without it the battle is silent.
## Run on its own (res://scenes/battle/battle_scene.tscn) it sets up a test battle: a
## poisoned hero of STANDALONE_LEVEL with potions and an antidote against a Slime and a
## Murciélago, and quits when it ends.

signal finished(outcome: int)

const ACTOR_SCENE := preload("res://scenes/battle/battle_actor.tscn")
const HUD_SCENE := preload("res://scenes/ui/battle_hud.tscn")
const RESULT_SCENE := preload("res://scenes/ui/battle_result.tscn")

const HERO_POS := Vector3(-1.0, 0, 1.8)
const ENEMY_POS := Vector3(0.6, 0, -2.4)
## Where the creature stands, beside the hero.
const ALLY_POS := Vector3(2.2, 0, 1.8)
## With two enemies, each stands this far to one side of ENEMY_POS.
const PAIR_OFFSET := Vector3(1.5, 0, 0)
const CAMERA_POS := Vector3(0.8, 2.6, 6.0)
const CAMERA_FOV := 50.0
## How far the camera moves toward the target during an attack (0..1).
const CAMERA_FOCUS := 0.18
## How far over a figure's top its life bar floats; the target arrow goes above the bar.
const BAR_GAP := 0.15
const ARROW_GAP := 0.5
const ARROW_COLOR := Color(1.0, 0.9, 0.3)
## A click this close (pixels) to an enemy aims at it.
const PICK_RADIUS := 120.0
const MP_COLOR := StatBar.MP
const DEFEND_COLOR := Color(0.6, 0.8, 1.0)
## Glow of an enemy gathering strength for a charged blow.
const CHARGE_COLOR := Color(1.0, 0.55, 0.15)
## Glow of the hero when the Despertador works.
const WAKE_COLOR := Color(1.0, 0.85, 0.35)
const STATUS_COLORS := {
	BattleEngine.POISON: Color(0.6, 0.2, 0.8),
	BattleEngine.SLEEP: Color(0.35, 0.45, 1.0),
	BattleEngine.SILENCE: Color(0.6, 0.6, 0.65),
	BattleEngine.STUN: Color(1.0, 0.85, 0.3),
}
const STANDALONE_LEVEL := 3
## Autoplay flees from normal battle number AUTOPLAY_EVERY, 2 × AUTOPLAY_EVERY... and
## defends in the first round of battle AUTOPLAY_DEFEND_AT, AUTOPLAY_DEFEND_AT +
## AUTOPLAY_EVERY...
const AUTOPLAY_EVERY := 5
const AUTOPLAY_DEFEND_AT := 2

## Normal battles started on autoplay in this run (for the flee and defend rules).
static var _autoplay_battles := 0

var engine: BattleEngine
var hero: Combatant
var enemies: Array[Combatant] = []
var inventory: Inventory
## Seconds per typed character of the messages (the text speed option).
var char_time := BattleHud.CHAR_TIME
## Gold the hero loses if defeated (Game takes it away; the battle only says so).
var gold_lost := 0
## How fast the battle runs (GameOptions.combat_scale()); the map is frozen meanwhile.
var time_scale := 1.0
## False: critical hits and big blows don't shake the camera.
var camera_shake := true
## A Difficulty id: the multipliers of this battle's engine.
var difficulty := Difficulty.NORMAL
## Zone the battle is fought in: its sky, light and backdrop (null: the meadow's). Set
## before adding it to the tree.
var zone: ZoneData
## The creature at the hero's side (null: none). Set it before adding the scene; it is
## already a copy with its life full.
var ally: Combatant
## Quest item -> how many its quest asks for (Game: QuestLog.wanted_items()); set before
## adding it. Empty: no quest item drops.
var quest_items := {}
## Small medals carried and the chance a common enemy leaves one (Game; set before adding
## it). -1: no medal drops (the battle run on its own).
var medals_carried := -1
var medal_chance := Medals.DROP_CHANCE

var _rng := RandomNumberGenerator.new()
var _autoplay := false
var _autoplay_flee := false
var _autoplay_defend := false
var _bot := BattleAutoplay.new()
var _done := false
var _new_level := 0
## Color of the last spell cast, used for the hit that follows it.
var _spell_color := BattleActor.FIRE_COLOR
var _hero_actor: BattleActor
var _ally_actor: BattleActor
var _enemy_actors: Array[BattleActor] = []
var _arrow: MeshInstance3D
var _arrow_tween: Tween
var _camera: Camera3D
var _camera_home: Vector3
var _cam_tween: Tween
var _shake_tween: Tween
var _hud: BattleHud
var _result: BattleResult
var _audio: AudioDirector
## Equipment ids the hero's figure shows (set_equipment()).
var _weapon_id := Equipment.STICK
var _shield_id := ""
var _helmet_id := ""


## The hero and the inventory are used as is, so HP, MP, EXP and items stay with the
## caller; the enemy data is duplicated so the .tres files never change. Two enemies of
## the same kind keep the same name: the arrow, the glow and the bar tell them apart.
func setup(hero_ref: Combatant, enemy_data: Array[Combatant], inv: Inventory) -> void:
	hero = hero_ref
	inventory = inv
	enemies.clear()
	for data in enemy_data:
		enemies.append(data.duplicate() as Combatant)


## Call before adding it to the tree, like setup().
func set_audio(audio: AudioDirector) -> void:
	_audio = audio


## The weapon, shield and helmet the hero's figure shows (Equipment ids, "" for none).
## Call before adding it to the tree; without it the hero holds the starting Palo.
func set_equipment(weapon_id: String, shield_id: String, helmet_id := "") -> void:
	_weapon_id = weapon_id
	_shield_id = shield_id
	_helmet_id = helmet_id


func _ready() -> void:
	if hero == null and get_parent() == get_tree().root:
		_setup_standalone()
	assert(hero != null and not enemies.is_empty() and inventory != null,
		"Call setup() before adding BattleScene to the tree")
	_rng.randomize()
	_autoplay = OS.get_cmdline_user_args().has("--autoplay")
	Engine.time_scale = time_scale
	BattleStage.build(self, zone)
	_hero_actor = _spawn_actor(BattleActor.Look.HERO, HERO_POS, ENEMY_POS)
	_hero_actor.set_equipment(_weapon_id, _shield_id, _helmet_id)
	if ally != null:
		_ally_actor = _spawn_actor(EnemyLibrary.look(ally.id), ALLY_POS, ENEMY_POS)
	for i in enemies.size():
		_enemy_actors.append(_spawn_actor(EnemyLibrary.look(enemies[i].id),
			_slot(i, enemies.size()), HERO_POS))
	_build_camera()
	_build_arrow()
	var ui := CanvasLayer.new()
	add_child(ui)
	_hud = HUD_SCENE.instantiate() as BattleHud
	ui.add_child(_hud)
	_hud.command_chosen.connect(_on_command_chosen)
	_hud.target_changed.connect(_show_arrow)
	_hud.pick_target = _pick_target
	_hud.char_time = char_time
	_hud.set_audio(_audio)
	_result = RESULT_SCENE.instantiate() as BattleResult
	ui.add_child(_result)
	_result.continue_requested.connect(_finish)
	engine = BattleEngine.new(hero, enemies, _rng, inventory)
	engine.damage_mult = Difficulty.damage_mult(difficulty)
	engine.exp_mult = Difficulty.exp_mult(difficulty)
	engine.ally = ally
	engine.quest_items = quest_items
	engine.medals_carried = medals_carried
	engine.medal_chance = medal_chance
	_hud.set_engine(engine)
	if ally != null:
		_hud.show_ally(ally)
	for i in _enemy_actors.size():
		var foe := engine.enemies[i]
		_hud.add_enemy_bar(foe.display_name)
		if foe.hp < foe.max_hp:
			# A Slime de Metal that kept its HP from the last battle.
			_hud.set_enemy_life(i, float(foe.hp) / foe.max_hp)
	if _autoplay and not engine.has_boss():
		_autoplay_battles += 1
		_autoplay_flee = _autoplay_battles % AUTOPLAY_EVERY == 0
		_autoplay_defend = _autoplay_battles % AUTOPLAY_EVERY == AUTOPLAY_DEFEND_AT
	await _say(_intro_text())
	await _play_ambush()


func _exit_tree() -> void:
	Engine.time_scale = 1.0


## The life bars follow their figures on screen (camera moves and shakes included).
func _process(_delta: float) -> void:
	for i in _enemy_actors.size():
		var actor := _enemy_actors[i]
		var over := actor.global_position + Vector3.UP * (actor.top_height() + BAR_GAP)
		_hud.place_enemy_bar(i, _camera.unproject_position(over))


func _setup_standalone() -> void:
	var state := GameState.new(load("res://data/hero.tres") as Combatant)
	state.hero.experience = Leveling.EXP_TABLE[STANDALONE_LEVEL - 1]
	Leveling.apply(state.hero)
	state.heal_full()
	state.hero.status[BattleEngine.POISON] = -1
	state.inventory.add(Inventory.ANTIDOTE)
	var foes: Array[Combatant] = [EnemyLibrary.data("slime"), EnemyLibrary.data("bat")]
	setup(state.hero, foes, state.inventory)
	finished.connect(func(outcome: int) -> void:
		print("Fin del combate (estado %d)" % outcome)
		get_tree().quit())


func _intro_text() -> String:
	var first := enemies[0]
	if first.is_boss:
		return "¡%s te cierra el paso!" % _cap(_the(first))
	if enemies.size() == 2:
		return "¡Aparecen %s y %s!" % [first.display_name, enemies[1].display_name]
	return "¡Aparece %s %s!" % ["una" if first.female else "un", first.display_name]


## The surprise roll, after the enemies appear: said, then the first menu, or the
## enemies' round first. Autoplay also prints "Sorpresa: héroe" / "Sorpresa: monstruos".
func _play_ambush() -> void:
	match engine.roll_ambush():
		BattleEngine.Ambush.HERO:
			if _autoplay:
				print("Sorpresa: héroe")
			_sfx(SfxLibrary.ACCEPT)
			await _say(_ambush_text(true))
			_ask_command()
		BattleEngine.Ambush.ENEMY:
			if _autoplay:
				print("Sorpresa: monstruos")
			_sfx(SfxLibrary.ENCOUNTER)
			_shake_camera()
			await _say(_ambush_text(false))
			await _play_round(engine.resolve_ambush_round())
		_:
			_ask_command()


## "¡Pillas desprevenido al Lobo!" / "¡El Lobo te ataca por sorpresa!", or "los
## monstruos" with two.
func _ambush_text(hero_side: bool) -> String:
	var alive := engine.alive_enemies()
	if alive.size() > 1:
		return "¡Pillas desprevenidos a los monstruos!" if hero_side \
			else "¡Los monstruos te atacan por sorpresa!"
	var foe := engine.enemies[alive[0]]
	if hero_side:
		return "¡Pillas desprevenid%s %s!" % [_ending(foe), _to(foe)]
	return "¡%s te ataca por sorpresa!" % _cap(_the(foe))


## Asleep, the hero does nothing; on autoplay the bot picks; otherwise the menu opens.
func _ask_command() -> void:
	if hero.status.has(BattleEngine.SLEEP) or hero.status.has(BattleEngine.STUN):
		await get_tree().create_timer(0.3).timeout
		_on_command_chosen(BattleEngine.cmd_none())
	elif _autoplay:
		var cmd := _autoplay_command()
		await _hud.demo(cmd)
		_on_command_chosen(cmd)
	else:
		_hud.show_menu()


func _autoplay_command() -> Dictionary:
	if _autoplay_flee:
		return BattleEngine.cmd_flee()
	if _autoplay_defend:
		_autoplay_defend = false
		return BattleEngine.cmd_defend()
	return _bot.choose(engine)


func _on_command_chosen(cmd: Dictionary) -> void:
	_hud.hide_menu()
	await _play_round(engine.resolve_round(cmd))


## Plays a round's events back, then asks for the next command or shows the result.
func _play_round(events: Array[Dictionary]) -> void:
	for event in events:
		await _play_event(event)
	match engine.state:
		BattleEngine.State.ONGOING:
			_ask_command()
			return
		BattleEngine.State.FLED:
			_finish()
			return
		BattleEngine.State.WON:
			_result.show_victory(engine.exp_won, hero, _new_level, engine.gold_won,
				engine.drops_won)
		BattleEngine.State.LOST:
			if gold_lost > 0:
				await _say("Pierdes %d monedas de oro." % gold_lost)
			_result.show_defeat(gold_lost)
	if _autoplay:
		await get_tree().create_timer(2.0).timeout
		if _done:  # "Continuar" was clicked during the wait
			return
		_result.hide()
		_finish()


## Emits finished once, whether the player pressed "Continuar" or autoplay did.
func _finish() -> void:
	if _done:
		return
	_done = true
	_sfx(SfxLibrary.ACCEPT)
	finished.emit(engine.state)


## Every battle message goes through here; autoplay also prints it.
func _say(text: String) -> void:
	if _autoplay:
		print(text)
	await _hud.show_message(text)


func _play_event(event: Dictionary) -> void:
	match event.type:
		BattleEvent.ATTACK:
			var target := _actor(event.target)
			if event.charged:
				await _say("¡%s descarga un golpe tremendo!" % _cap(_the(_fighter(event.actor))))
				_shake_camera()
			else:
				await _say("¡%s ataca!" % _fighter(event.actor).display_name)
			_focus_camera(target)
			await _actor(event.actor).play_attack(target.global_position)
		BattleEvent.CHARGE:
			_sfx(SfxLibrary.FIRE)
			await _actor(event.actor).play_cast(CHARGE_COLOR)
			await _say("%s acumula fuerza..." % _cap(_the(_fighter(event.actor))))
		BattleEvent.SKILL:
			if event.actor == BattleEvent.HERO:
				_hud.update_mp(event.mp_left, hero.max_mp)
			_spell_color = event.color
			_sfx(SfxLibrary.FIRE)
			await _say("¡%s lanza %s!" % [_fighter(event.actor).display_name, event.name])
			var first: int = event.targets[0]
			if first != event.actor:
				_focus_camera(_actor(first))
			await _actor(event.actor).play_cast(_spell_color)
		BattleEvent.MISS:
			_sfx(SfxLibrary.MISS)
			await _actor(event.target).play_dodge()
			_reset_camera()
			await _say("¡Pero falla!")
		BattleEvent.DAMAGE:
			await _play_damage(event)
		BattleEvent.ITEM:
			_sfx(SfxLibrary.POTION)
			await _say("¡%s usa %s %s!" % [_fighter(event.actor).display_name,
				Inventory.article(event.item), Inventory.display_name(event.item)])
		BattleEvent.HEAL:
			_sfx(SfxLibrary.HEAL)
			_reset_camera()
			await _actor(event.target).play_heal(event.amount)
			_show_life(event.target, event.hp_left)
			await _say("¡%s recupera %d PV!" % [
				_fighter(event.target).display_name, event.amount])
		BattleEvent.MP_HEAL:
			_sfx(SfxLibrary.HEAL)
			await _actor(event.target).play_heal(event.amount, MP_COLOR)
			if event.target == BattleEvent.HERO:
				_hud.update_mp(event.mp_left, hero.max_mp)
			await _say("¡%s recupera %d PM!" % [
				_fighter(event.target).display_name, event.amount])
		BattleEvent.STAGGER:
			await _actor(event.actor).play_stagger()
			await _say("%s se tambalea." % _cap(_the(_fighter(event.actor))))
		BattleEvent.DEFEND:
			_sfx(SfxLibrary.CURSOR)
			await _actor(event.actor).play_status(DEFEND_COLOR)
			await _say("¡%s se defiende!" % _fighter(event.actor).display_name)
		BattleEvent.FLEE_OK:
			_sfx(SfxLibrary.CANCEL)
			await _say("¡Has huido!")
		BattleEvent.FLEE_FAIL:
			await _say("¡No has podido huir!")
		BattleEvent.ENEMY_FLEE:
			_sfx(SfxLibrary.CANCEL)
			_show_arrow(-1)
			_hud.hide_enemy_bar(event.actor)
			await _actor(event.actor).play_dodge()
			_actor(event.actor).hide()
			await _say("¡%s huye!" % _cap(_the(_fighter(event.actor))))
		BattleEvent.STATUS_ON:
			await _play_status_on(event)
		BattleEvent.STATUS_TICK:
			_sfx(SfxLibrary.HIT)
			await _actor(event.target).play_status(STATUS_COLORS[event.status], event.amount)
			_show_life(event.target, event.hp_left)
			await _say("¡El veneno quita %d PV a %s!" % [event.amount,
				_fighter(event.target).display_name])
		BattleEvent.STATUS_OFF:
			await _play_status_off(event)
		BattleEvent.STUNNED:
			await _actor(event.actor).play_status(STATUS_COLORS[BattleEngine.STUN])
			await _say("%s aún no se recupera del golpe." % _fighter(event.actor).display_name)
		BattleEvent.ASLEEP:
			await _actor(event.actor).play_status(STATUS_COLORS[BattleEngine.SLEEP])
			var sleeper := _fighter(event.actor)
			await _say("%s duerme profundamente." % sleeper.display_name if sleeper == hero
				else "%s está dormid%s." % [sleeper.display_name, _ending(sleeper)])
		BattleEvent.CALL_HELP:
			await _play_call_help(event)
		BattleEvent.PHASE:
			var boss := _fighter(event.target)
			_sfx(SfxLibrary.ENCOUNTER)
			_shake_camera()
			await _actor(event.target).play_phase()
			_show_life(event.target, event.hp_left)
			if event.target >= 0:
				_hud.set_enemy_name(event.target, boss.display_name)
			var line: String = event.get("line", "")
			await _say(line if line != "" else "¡La niebla envuelve %s!" % _to(boss))
			await _say("¡%s se levanta con %d PV!" % [_cap(_the(boss)), event.hp_left])
		BattleEvent.REVIVE:
			_sfx(SfxLibrary.HEAL)
			_reset_camera()
			await _actor(event.target).play_heal(event.hp_left)
			_show_life(event.target, event.hp_left)
			_hud.update_status(hero.status)
			await _say("¡La Pluma de fénix arde! %s se levanta." % hero.display_name)
		BattleEvent.WAKE_GUARD:
			await _actor(event.target).play_status(WAKE_COLOR)
			await _say("%s no se dormirá en este combate." % _fighter(event.target).display_name)
		BattleEvent.NO_SLEEP:
			_sfx(SfxLibrary.MISS)
			await _actor(event.target).play_status(WAKE_COLOR)
			await _say("%s no se duerme." % _fighter(event.target).display_name)
		BattleEvent.IMMUNE:
			_sfx(SfxLibrary.MISS)
			await _actor(event.target).play_status(STATUS_COLORS[event.status])
			await _say(_immune_text(event))
		BattleEvent.DEFEATED:
			_show_arrow(-1)
			if event.target >= 0:
				_hud.hide_enemy_bar(event.target)
			await _actor(event.target).play_defeat()
			if event.target == BattleEvent.HERO:
				_music(MusicLibrary.DEFEAT)
				await _say("Has caído...")
			else:
				var foe := _fighter(event.target)
				await _say("¡%s ha sido derrotad%s!" % [foe.display_name, _ending(foe)])
		BattleEvent.VICTORY:
			_hero_actor.play_cheer()
			if ally != null and ally.hp > 0:
				_ally_actor.play_cheer()
			_music(MusicLibrary.VICTORY)
			await _say("¡Has ganado! Obtienes %d EXP." % event.exp)
		BattleEvent.GOLD:
			await _say("Consigues %d monedas de oro." % event.amount)
		BattleEvent.LEVEL_UP:
			_new_level = event.level
			_hud.update_level(event.level)
			_hud.update_hp(event.hp, event.max_hp)
			_hud.update_mp(event.mp, event.max_mp)
			_sfx(SfxLibrary.LEVEL_UP)
			await _say("¡%s sube al nivel %d!" % [hero.display_name, event.level])
			await _say(_gains_text(event.gains))
		BattleEvent.LEARN:
			_sfx(SfxLibrary.LEVEL_UP)
			var learned := "¡%s aprende %s!" % [hero.display_name, event.name]
			if event.replaced != "":
				learned += " Sustituye a %s." % event.replaced
			await _say(learned)
		BattleEvent.DROP:
			if event.item == Inventory.MEDAL:
				await _say("¡Consigues una Medalla pequeña! %s" % event.progress)
				return
			var said := "¡%s ha dejado %s %s!" % [_cap(_the(_fighter(event.owner))),
				Inventory.article(event.item), Inventory.display_name(event.item)]
			if event.get("progress", "") != "":
				said += " " + event.progress
			await _say(said)


func _play_damage(event: Dictionary) -> void:
	if event.crit:
		_shake_camera()
	_sfx(SfxLibrary.CRIT if event.crit else SfxLibrary.HIT)
	var tag := ""
	match event.affinity:
		BattleEvent.WEAK:
			tag = "¡Débil!"
		BattleEvent.RESIST:
			tag = "¡Resiste!"
	if event.magic:
		await _actor(event.target).play_burn(event.amount, _spell_color, tag)
	else:
		await _actor(event.target).play_hit(event.amount, event.crit, tag)
	_reset_camera()
	_show_life(event.target, event.hp_left)
	if event.crit:
		await _say("¡Golpe crítico!")
	var target := _fighter(event.target)
	match event.affinity:
		BattleEvent.WEAK:
			await _say("¡%s es débil a esto!" % _cap(_the(target)))
		BattleEvent.RESIST:
			await _say("¡%s lo resiste!" % _cap(_the(target)))
	await _say("¡%s recibe %d de daño!" % [target.display_name, event.amount])


## The life left of a fighter as the events play it back: the hero's PV bar or the
## enemy's thin bar (the engine has already resolved the whole round, so its HP can't be
## read directly).
func _show_life(who: int, hp_left: int) -> void:
	match who:
		BattleEvent.HERO:
			_hud.update_hp(hp_left, hero.max_hp)
		BattleEvent.ALLY:
			_hud.update_ally_hp(hp_left, ally.max_hp)
		_:
			_hud.set_enemy_life(who, float(hp_left) / maxf(1.0, engine.enemies[who].max_hp))


func _play_status_on(event: Dictionary) -> void:
	_sfx(SfxLibrary.MISS)
	await _actor(event.target).play_status(STATUS_COLORS[event.status])
	var target := _fighter(event.target)
	if event.target == BattleEvent.HERO:
		_hud.update_status(hero.status)
	match event.status:
		BattleEngine.POISON:
			await _say("¡%s sufre el veneno!" % target.display_name if target == hero
				else "¡%s está envenenad%s!" % [target.display_name, _ending(target)])
		BattleEngine.SLEEP:
			await _say("¡%s se ha dormido!" % target.display_name)
		BattleEngine.STUN:
			await _say("¡El golpe deja sin aliento a %s!" % target.display_name)
		BattleEngine.SILENCE:
			await _say("¡%s ya no puede lanzar hechizos!" % target.display_name)


func _play_status_off(event: Dictionary) -> void:
	var target := _fighter(event.target)
	if event.target == BattleEvent.HERO:
		_hud.update_status(hero.status)
	match event.status:
		BattleEngine.POISON:
			_sfx(SfxLibrary.HEAL)
			await _say("¡El veneno ya no afecta a %s!" % target.display_name if target == hero
				else "¡%s ya no está envenenad%s!" % [target.display_name, _ending(target)])
		BattleEngine.SLEEP:
			await _say("¡%s se despierta!" % target.display_name)
		BattleEngine.SILENCE:
			await _say("¡%s puede volver a lanzar hechizos!" % target.display_name)


## "El veneno no afecta a Rocío." / "El silencio no afecta a Rocío.".
func _immune_text(event: Dictionary) -> String:
	var what := "El silencio" if event.status == BattleEngine.SILENCE else "El veneno"
	return "%s no afecta a %s." % [what, _fighter(event.target).display_name]


## The caller steps to the left place and the helper appears on the right one.
func _play_call_help(event: Dictionary) -> void:
	var caller := _fighter(event.actor)
	_sfx(SfxLibrary.ENCOUNTER)
	await _actor(event.actor).play_cast(Color.WHITE)
	await _say("¡%s pide ayuda!" % _cap(_the(caller)))
	var t := create_tween()
	t.tween_property(_actor(event.actor), "position", _slot(0, 2), 0.3) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t.finished
	var helper := engine.enemies[event.helper]
	var actor := _spawn_actor(EnemyLibrary.look(helper.id), _slot(1, 2), HERO_POS)
	_enemy_actors.append(actor)
	_hud.add_enemy_bar(helper.display_name)
	await actor.play_appear()
	await _say("¡Aparece %s %s!" % ["una" if helper.female else "un", helper.display_name])


func _sfx(id: String) -> void:
	if _audio:
		_audio.play_sfx(id)


func _music(id: String) -> void:
	if _audio:
		_audio.play_music(id)


func _gains_text(gains: Dictionary) -> String:
	return "PV +%d  PM +%d  ATK +%d  DEF +%d  VEL +%d" % [
		gains.max_hp, gains.max_mp, gains.attack, gains.defense, gains.speed]


## "el Slime" / "la Seta saltarina"; the hero has no article.
func _the(c: Combatant) -> String:
	if c == hero:
		return c.display_name
	return ("la %s" if c.female else "el %s") % c.display_name


## "al Señor de la Niebla" / "a la Bruja del bosque".
func _to(c: Combatant) -> String:
	return ("a la %s" if c.female else "al %s") % c.display_name


## Ending of the adjectives for an enemy c: "a" (envenenada) or "o" (envenenado). The
## hero's lines avoid them: the player picks the name and the hero has no set gender.
func _ending(c: Combatant) -> String:
	return "a" if c.female else "o"


static func _cap(text: String) -> String:
	return text.left(1).to_upper() + text.substr(1)


## Where enemy i of count stands: in the middle alone, left and right as a pair.
func _slot(i: int, count: int) -> Vector3:
	if count < 2:
		return ENEMY_POS
	return ENEMY_POS + PAIR_OFFSET * (-1.0 if i == 0 else 1.0)


func _spawn_actor(look: BattleActor.Look, pos: Vector3, facing: Vector3) -> BattleActor:
	var actor: BattleActor = ACTOR_SCENE.instantiate()
	actor.look = look
	add_child(actor)
	actor.position = pos
	actor.look_at(facing, Vector3.UP)
	return actor


## Yellow cone pointing down, over the enemy being aimed at; blinks while shown.
func _build_arrow() -> void:
	var cone := CylinderMesh.new()
	cone.top_radius = 0.22
	cone.bottom_radius = 0.0
	cone.height = 0.4
	cone.radial_segments = 4
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = ARROW_COLOR
	material.no_depth_test = true
	_arrow = MeshInstance3D.new()
	_arrow.mesh = cone
	_arrow.material_override = material
	_arrow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_arrow.hide()
	add_child(_arrow)


func _show_arrow(index: int) -> void:
	for i in _enemy_actors.size():
		_enemy_actors[i].set_highlight(i == index)
	_hud.show_target_name(index)
	if _arrow_tween:
		_arrow_tween.kill()
		_arrow_tween = null
	if index < 0 or index >= _enemy_actors.size():
		_arrow.hide()
		return
	var actor := _enemy_actors[index]
	_arrow.position = actor.position + Vector3(0, actor.top_height() + ARROW_GAP, 0)
	_arrow.show()
	_arrow_tween = create_tween().set_loops()
	_arrow_tween.tween_interval(0.25)
	_arrow_tween.tween_callback(func() -> void: _arrow.visible = not _arrow.visible)


## The standing enemy nearest to a screen point within PICK_RADIUS, or -1.
func _pick_target(screen: Vector2) -> int:
	var best := -1
	var best_distance := PICK_RADIUS
	for i in engine.alive_enemies():
		var actor := _enemy_actors[i]
		var middle := actor.global_position + Vector3(0, actor.top_height() * 0.5, 0)
		var distance := _camera.unproject_position(middle).distance_to(screen)
		if distance < best_distance:
			best = i
			best_distance = distance
	return best


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
	if not camera_shake:
		return
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


func _actor(who: int) -> BattleActor:
	match who:
		BattleEvent.HERO:
			return _hero_actor
		BattleEvent.ALLY:
			return _ally_actor
	return _enemy_actors[who]


func _fighter(who: int) -> Combatant:
	match who:
		BattleEvent.HERO:
			return hero
		BattleEvent.ALLY:
			return ally
	return engine.enemies[who]
