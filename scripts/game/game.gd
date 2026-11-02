extends Node
## Root scene. Owns the GameState and the world map, and puts a battle on top of the
## map when an encounter starts. The map is never freed, so the hero's position, the
## camera and the encounter grace survive the battle. A defeat heals the hero and
## sends them back to the spawn point; EXP is kept.

const HERO_DATA := preload("res://data/hero.tres")
const SLIME_DATA := preload("res://data/slime.tres")
const BATTLE_SCENE := preload("res://scenes/battle/battle_scene.tscn")
const WORLD_SCENE := preload("res://scenes/world/world.tscn")
const FADE_TIME := 0.3

var state: GameState

var _world: World
var _fade: ColorRect
var _busy := false


func _ready() -> void:
	state = GameState.new(HERO_DATA)
	_world = WORLD_SCENE.instantiate()
	add_child(_world)
	_world.refresh_status(state.hero, state.inventory.count(Inventory.POTION))
	_world.encounter_triggered.connect(_on_encounter)
	_build_fade()


func _on_encounter() -> void:
	if _busy:
		return
	_busy = true
	await _fade_to(1.0)
	_world.set_active(false)
	var battle: BattleScene = BATTLE_SCENE.instantiate()
	battle.setup(state.hero, SLIME_DATA, state.inventory)
	add_child(battle)
	await _fade_to(0.0)
	var won: bool = await battle.finished
	await _fade_to(1.0)
	battle.queue_free()
	if not won:
		state.heal_full()
		_world.respawn()
	_world.refresh_status(state.hero, state.inventory.count(Inventory.POTION))
	_world.set_active(true)
	await _fade_to(0.0)
	if not won:
		_world.show_notice("Has vuelto al inicio.")
	_busy = false


func _build_fade() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade)


func _fade_to(alpha: float) -> void:
	var t := create_tween()
	t.tween_property(_fade, "color:a", alpha, FADE_TIME)
	await t.finished
