extends Node
## Root scene. Owns the GameState and, for now, runs battles back to back; the world
## map is added later. A lost battle heals the hero; HP otherwise carries over.

const HERO_DATA := preload("res://data/hero.tres")
const SLIME_DATA := preload("res://data/slime.tres")
const BATTLE_SCENE := preload("res://scenes/battle/battle_scene.tscn")

var state: GameState


func _ready() -> void:
	state = GameState.new(HERO_DATA)
	while true:
		var won := await _run_battle()
		if not won:
			state.heal_full()


func _run_battle() -> bool:
	var battle: BattleScene = BATTLE_SCENE.instantiate()
	battle.setup(state.hero, SLIME_DATA)
	add_child(battle)
	var won: bool = await battle.finished
	battle.queue_free()
	return won
