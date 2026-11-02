# Mundo y bucle de exploración — plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Este proyecto NO lleva tests** (ver `CLAUDE.md`, sección "No tests — ever"). Ignora cualquier paso de TDD de los skills: no crees `tests/`, scripts de test ni frameworks. Cada tarea se verifica con `--import`, `--check-only`, ejecutando el juego y revisando fotogramas.

**Goal:** El héroe anda por un campo 3D en tercera persona, en la hierba salta un encuentro aleatorio con el combate existente y al terminar se vuelve al mapa con PV y EXP conservados (al perder, al inicio y curado).

**Architecture:** `Game` (escena principal) tiene un `GameState` puro y un `World` que nunca se destruye; al saltar un encuentro pausa y oculta el mapa, crea un `BattleScene` encima con el `Combatant` del héroe y lo libera al recibir `finished(won)`. Las reglas nuevas (`GameState`, `EncounterMeter`) son `RefCounted` y no tocan nodos; escenario y UI se crean por código como hasta ahora.

**Tech Stack:** Godot 4.7.2, GDScript, Forward+, Jolt Physics. Todo escrito como texto (sin editor).

Spec: `docs/boost/specs/2026-11-02-mundo-exploracion-design.md`.

## Global Constraints

- Godot **4.7.2**; ejecutable vía `.\tools\godot.cmd` (no está en el PATH).
- Renderizador **Forward+**, física 3D **Jolt Physics**, ventana base **1280×720**.
- **Sin tests unitarios ni automatizados, en ningún momento.**
- Escenas y scripts se escriben como texto; `.godot/` nunca se edita a mano. Los `.tscn` solo llevan el nodo raíz y su script.
- Tras crear un script con `class_name` nuevo: `.\tools\godot.cmd --headless --path . --import`. Commitear los `.uid` generados junto a sus scripts.
- Gitflow: trabajar en `feature/mundo-exploracion` (ya existe); nunca commitear en `main` ni `develop`; merge final a `develop` con `--no-ff`.
- Mensajes de commit **sin ninguna mención a Claude**: nada de `Co-Authored-By`, "Generated with Claude Code" ni atribución similar.
- Textos visibles en español; comentarios de código en inglés. Indentación con tabuladores.
- Sin autoloads: el estado lo tiene `Game` y lo pasa explícitamente.
- Reglas de este paso: velocidad 5 m/s; cámara a 6 m y 3,5 m de altura, Q/E giran; gracia de encuentros 5 m; 8 % por metro en hierba; el camino es seguro; enemigo siempre `slime.tres`; PV persisten; derrota → `SPAWN_POS` con PV completos y la misma EXP.

Todos los comandos se ejecutan en PowerShell desde `C:\Users\peixe\Documents\rpg-turnos`.

## Mapa de archivos

| Archivo | Responsabilidad |
|---|---|
| `scripts/game/game_state.gd` | `GameState`: héroe persistente, `heal_full()` |
| `scripts/world/encounter_meter.gd` | `EncounterMeter`: regla de encuentros por metros en hierba |
| `scripts/battle/battle_stage.gd` | (mod.) `build_environment()`, `add_mesh()`, `unit_sphere()` públicos |
| `scripts/ui/battle_result.gd` | (mod.) botón "Continuar", señal `continue_requested` |
| `scripts/battle/battle_scene.gd` | (mod.) `class_name BattleScene`, `setup()`, señal `finished(won)`, un solo combate |
| `scenes/game/game.tscn` + `scripts/game/game.gd` | Escena principal: estado, mapa, combate encima, fundidos |
| `scripts/world/world_stage.gd` | `WorldStage`: campo, camino, claro, rocas, muros, colinas; `is_on_path()` |
| `scripts/world/follow_camera.gd` | `FollowCamera`: cámara en 3ª persona, Q/E |
| `scenes/world/player.tscn` + `scripts/world/player.gd` | `Player`: movimiento, modelo `BattleActor`, autoplay por ruta |
| `scenes/world/world.tscn` + `scripts/world/world.gd` | `World`: mapa, encuentros, estado en pantalla, `set_active`/`respawn` |
| `project.godot` | (mod.) `run/main_scene` → `game.tscn` |
| `CLAUDE.md` | (mod.) layout, comandos y convenciones |

---

### Task 1: Reglas puras (GameState y EncounterMeter)

**Files:**
- Create: `scripts/game/game_state.gd`, `scripts/world/encounter_meter.gd`

**Interfaces:**
- Consumes: `Combatant` (`scripts/battle/combatant.gd`: `display_name`, `max_hp`, `hp`, `experience`, ...).
- Produces:
  - `class_name GameState extends RefCounted`: `_init(hero_data: Combatant)`, `var hero: Combatant`, `heal_full() -> void`.
  - `class_name EncounterMeter extends RefCounted`: `const GRACE_M := 5.0`, `const CHANCE_PER_M := 0.08`, `_init(rng: RandomNumberGenerator)`, `advance(meters: float, in_grass: bool) -> bool`, `reset() -> void`.

- [ ] **Step 1: Crear `scripts/game/game_state.gd`**

```gdscript
class_name GameState extends RefCounted
## State of the play session, kept in memory while the game is open. The hero lives
## here for the whole session and battles change it in place (HP, EXP).

var hero: Combatant


func _init(hero_data: Combatant) -> void:
	hero = hero_data.duplicate() as Combatant


## Back to full HP, used after a defeat.
func heal_full() -> void:
	hero.hp = hero.max_hp
```

- [ ] **Step 2: Crear `scripts/world/encounter_meter.gd`**

```gdscript
class_name EncounterMeter extends RefCounted
## Random encounter rule. Only meters walked on grass count. After reset() the first
## GRACE_M meters are free; after that every full meter has CHANCE_PER_M of a battle.

const GRACE_M := 5.0
const CHANCE_PER_M := 0.08

var _rng: RandomNumberGenerator
var _grace := GRACE_M
## Meters walked past the grace that have not been rolled yet (always < 1).
var _walked := 0.0


func _init(rng: RandomNumberGenerator) -> void:
	_rng = rng


## Gives the grace distance again (start, back from a battle, respawn).
func reset() -> void:
	_grace = GRACE_M
	_walked = 0.0


## Adds the meters walked this frame. Returns true when a battle starts.
func advance(meters: float, in_grass: bool) -> bool:
	if not in_grass or meters <= 0.0:
		return false
	if _grace > 0.0:
		var used := minf(_grace, meters)
		_grace -= used
		meters -= used
	_walked += meters
	while _walked >= 1.0:
		_walked -= 1.0
		if _rng.randf() < CHANCE_PER_M:
			reset()
			return true
	return false
```

- [ ] **Step 3: Importar y validar**

Run: `.\tools\godot.cmd --headless --path . --import`
Run: `.\tools\godot.cmd --headless --path . --check-only --script res://scripts/game/game_state.gd`
Run: `.\tools\godot.cmd --headless --path . --check-only --script res://scripts/world/encounter_meter.gd`
Expected: sin `ERROR` / `SCRIPT ERROR` / `Parse Error`; aparecen los `.uid` de ambos scripts.

- [ ] **Step 4: Commit**

```powershell
git add scripts/game/game_state.gd scripts/game/game_state.gd.uid scripts/world/encounter_meter.gd scripts/world/encounter_meter.gd.uid
git commit -m "Add game state and random encounter rule"
```

---

### Task 2: Combate reutilizable y Game mínimo

**Files:**
- Modify: `scripts/battle/battle_stage.gd` (reescritura completa), `scripts/ui/battle_result.gd` (reescritura completa), `scripts/battle/battle_scene.gd` (reescritura completa), `project.godot`
- Create: `scripts/game/game.gd`, `scenes/game/game.tscn`

**Interfaces:**
- Consumes: `GameState` (Task 1); `BattleEngine`, `BattleEvent`, `BattleActor`, `BattleHud` (existentes, sin cambios).
- Produces:
  - `BattleStage`: `static build(root: Node3D)`, `static build_environment(root: Node3D)`, `static add_mesh(root: Node3D, mesh: Mesh, color: Color, pos: Vector3, scl := Vector3.ONE, rot_deg := Vector3.ZERO) -> MeshInstance3D`, `static unit_sphere() -> SphereMesh`; constantes `GRASS`, `DIRT`, `ROCK`, `HILL`, `HAZE`.
  - `class_name BattleResult`: `signal continue_requested`, `show_victory(exp_gained, total_exp)`, `show_defeat()`.
  - `class_name BattleScene extends Node3D`: `signal finished(won: bool)`, `setup(hero_ref: Combatant, enemy_data: Combatant) -> void` (llamar antes de `add_child`; el héroe se usa tal cual, el enemigo se duplica).
  - `scenes/game/game.tscn` como escena principal (en esta tarea solo encadena combates; la Task 4 lo amplía).

- [ ] **Step 1: Reescribir `scripts/battle/battle_stage.gd`** (mismo escenario; se hacen públicos el entorno y los helpers de malla para que `WorldStage` los reutilice)

```gdscript
class_name BattleStage extends RefCounted
## Builds the battle backdrop from primitives: sky, warm sun, fog, grass field,
## dirt path, rocks and distant hills. The environment and mesh helpers are shared
## with WorldStage.

const GRASS := Color(0.32, 0.55, 0.22)
const DIRT := Color(0.62, 0.5, 0.34)
const ROCK := Color(0.5, 0.5, 0.52)
const HILL := Color(0.27, 0.47, 0.22)
const HAZE := Color(0.78, 0.84, 0.92)

## [position, scale] of each rock (unit spheres).
const ROCKS := [
	[Vector3(-5.5, 0.3, -6.0), Vector3(1.2, 0.8, 1.0)],
	[Vector3(4.5, 0.4, -8.0), Vector3(1.6, 1.1, 1.3)],
	[Vector3(6.5, 0.2, -2.5), Vector3(0.8, 0.5, 0.7)],
	[Vector3(-7.0, 0.5, -12.0), Vector3(2.0, 1.4, 1.6)],
	[Vector3(2.5, 0.15, -4.5), Vector3(0.5, 0.35, 0.45)],
]
## [position, scale] of each hill (unit spheres, half buried).
const HILLS := [
	[Vector3(-26, -4, -48), Vector3(22, 9, 22)],
	[Vector3(18, -5, -55), Vector3(28, 10, 20)],
	[Vector3(48, -6, -25), Vector3(20, 8, 20)],
	[Vector3(-50, -5, -15), Vector3(20, 8, 24)],
]


static func build(root: Node3D) -> void:
	build_environment(root)
	var ground := PlaneMesh.new()
	ground.size = Vector2(160, 160)
	add_mesh(root, ground, GRASS, Vector3.ZERO)
	var path := PlaneMesh.new()
	path.size = Vector2(2.6, 30)
	add_mesh(root, path, DIRT, Vector3(-0.2, 0.01, -0.3), Vector3.ONE, Vector3(0, -21, 0))
	for rock in ROCKS:
		add_mesh(root, unit_sphere(), ROCK, rock[0], rock[1])
	for hill in HILLS:
		add_mesh(root, unit_sphere(), HILL, hill[0], hill[1])


## Sky, tonemap, fog and the warm sun shared by every outdoor scene.
static func build_environment(root: Node3D) -> void:
	_add_environment(root)
	_add_sun(root)


static func add_mesh(root: Node3D, mesh: Mesh, color: Color, pos: Vector3, \
		scl := Vector3.ONE, rot_deg := Vector3.ZERO) -> MeshInstance3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 1.0
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.scale = scl
	mi.rotation_degrees = rot_deg
	root.add_child(mi)
	return mi


static func unit_sphere() -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	return mesh


static func _add_environment(root: Node3D) -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.32, 0.52, 0.88)
	sky_material.sky_horizon_color = HAZE
	sky_material.ground_horizon_color = HAZE
	sky_material.ground_bottom_color = Color(0.3, 0.4, 0.3)
	var sky := Sky.new()
	sky.sky_material = sky_material
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.ssao_enabled = true
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.fog_enabled = true
	env.fog_light_color = HAZE
	env.fog_density = 0.008
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	root.add_child(world_env)


static func _add_sun(root: Node3D) -> void:
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.9, 0.75)
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	sun.rotation_degrees = Vector3(-40, 35, 0)
	root.add_child(sun)
```

- [ ] **Step 2: Reescribir `scripts/ui/battle_result.gd`** ("Continuar" en lugar de "Luchar otra vez")

```gdscript
class_name BattleResult extends Control
## End-of-battle overlay: victory or defeat text and a "Continuar" button.
## Starts hidden; the button hides it and emits continue_requested.

signal continue_requested

var _title: Label
var _detail: Label
var _continue: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.55)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := BattleHud.make_window()
	panel.custom_minimum_size = Vector2(420, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)
	_title = _label(40)
	box.add_child(_title)
	_detail = _label(24)
	box.add_child(_detail)
	_continue = Button.new()
	_continue.text = "Continuar"
	_continue.add_theme_font_size_override("font_size", 24)
	_continue.pressed.connect(_on_continue_pressed)
	box.add_child(_continue)
	hide()


func show_victory(exp_gained: int, total_exp: int) -> void:
	_title.text = "¡Victoria!"
	_detail.text = "+%d EXP  (total: %d)" % [exp_gained, total_exp]
	_open()


func show_defeat() -> void:
	_title.text = "Has sido derrotado"
	_detail.text = "Volverás al inicio."
	_open()


func _open() -> void:
	show()
	_continue.disabled = true
	await get_tree().create_timer(0.3).timeout
	_continue.disabled = false
	_continue.grab_focus()


func _label(size: int) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color.WHITE)
	return label


func _on_continue_pressed() -> void:
	hide()
	continue_requested.emit()
```

- [ ] **Step 3: Reescribir `scripts/battle/battle_scene.gd`** (un solo combate con `setup()` y `finished`; la reproducción de eventos y la cámara no cambian)

```gdscript
class_name BattleScene extends Node3D
## One battle: builds the stage, actors, camera and UI, asks the HUD for the hero's
## order, lets BattleEngine resolve the round and plays the events back. Call setup()
## before adding it to the tree; it emits finished(won) when the player continues.
## With `-- --autoplay` it picks "Atacar" by itself and continues on its own.

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

var engine: BattleEngine
var hero: Combatant
var enemy: Combatant

var _rng := RandomNumberGenerator.new()
var _autoplay := false
var _done := false
var _hero_actor: BattleActor
var _enemy_actor: BattleActor
var _camera: Camera3D
var _camera_home: Vector3
var _cam_tween: Tween
var _shake_tween: Tween
var _hud: BattleHud
var _result: BattleResult


## The hero is used as is, so HP and EXP changes stay with the caller; the enemy
## data is duplicated so the .tres file never changes.
func setup(hero_ref: Combatant, enemy_data: Combatant) -> void:
	hero = hero_ref
	enemy = enemy_data.duplicate() as Combatant


func _ready() -> void:
	assert(hero != null and enemy != null, "Call setup() before adding BattleScene to the tree")
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
	_result.continue_requested.connect(_finish)
	engine = BattleEngine.new(hero, enemy, _rng)
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
		_finish()


## Emits finished once, whether the player pressed "Continuar" or autoplay did.
func _finish() -> void:
	if _done:
		return
	_done = true
	finished.emit(engine.state == BattleEngine.State.WON)


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
```

- [ ] **Step 4: Crear `scripts/game/game.gd`** (forma mínima: encadena combates; la Task 4 lo sustituye por la versión con mapa)

```gdscript
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
```

- [ ] **Step 5: Crear `scenes/game/game.tscn`**

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/game/game.gd" id="1_game"]

[node name="Game" type="Node"]
script = ExtResource("1_game")
```

- [ ] **Step 6: Cambiar la escena principal en `project.godot`**

Sustituir la línea `run/main_scene="res://scenes/battle/battle_scene.tscn"` por:

```ini
run/main_scene="res://scenes/game/game.tscn"
```

- [ ] **Step 7: Importar y validar**

Run: `.\tools\godot.cmd --headless --path . --import`
Run: `.\tools\godot.cmd --headless --path . --check-only --script res://scripts/battle/battle_stage.gd`
Run: `.\tools\godot.cmd --headless --path . --check-only --script res://scripts/ui/battle_result.gd`
Run: `.\tools\godot.cmd --headless --path . --check-only --script res://scripts/battle/battle_scene.gd`
Run: `.\tools\godot.cmd --headless --path . --check-only --script res://scripts/game/game.gd`
Expected: sin `ERROR` / `SCRIPT ERROR` / `Parse Error`.

- [ ] **Step 8: Ejecutar en autoplay y revisar la salida**

Run: `.\tools\godot.cmd --path . --quit-after 2400 -- --autoplay`
Expected: se abre la ventana, se encadenan varios combates sin intervención; en la consola no hay `ERROR`, `SCRIPT ERROR` ni `WARNING`.

- [ ] **Step 9: Grabar fotogramas y revisarlos**

```powershell
$frames = "$env:TEMP\rpg-turnos-frames"
Remove-Item -Recurse -Force $frames -ErrorAction SilentlyContinue
New-Item -ItemType Directory $frames | Out-Null
.\tools\godot.cmd --path . --resolution 640x360 --write-movie "$frames\f.png" --fixed-fps 10 --quit-after 600 -- --autoplay
```

Abrir con Read fotogramas repartidos y comprobar:
- El overlay del resultado dice "¡Victoria!" y el botón es "Continuar".
- Tras el primer combate empieza otro y el panel del héroe arranca con los PV que le quedaron (menos de 30 si recibió daño), no con 30.
- Mismo aspecto que antes (cielo, escenario, actores).

Al terminar: `Remove-Item -Recurse -Force $frames`.

- [ ] **Step 10: Commit**

```powershell
git add scripts/battle/battle_stage.gd scripts/ui/battle_result.gd scripts/battle/battle_scene.gd scripts/game/game.gd scripts/game/game.gd.uid scenes/game/game.tscn project.godot
git commit -m "Make the battle scene reusable and chain battles from a game root"
```

(Si `--import` regenera el `.uid` de `battle_scene.gd`, añadirlo también.)

---

### Task 3: Mundo andable (escenario, jugador, cámara y encuentros)

**Files:**
- Create: `scripts/world/world_stage.gd`, `scripts/world/follow_camera.gd`, `scripts/world/player.gd`, `scenes/world/player.tscn`, `scripts/world/world.gd`, `scenes/world/world.tscn`

**Interfaces:**
- Consumes: `BattleStage.build_environment/add_mesh/unit_sphere`, constantes `GRASS`, `DIRT`, `ROCK`, `HILL` (Task 2); `EncounterMeter` (Task 1); `BattleActor` (`look`, `Look.HERO`; el modelo mira a −Z); `BattleHud.make_window()`; `Combatant`.
- Produces:
  - `class_name WorldStage extends RefCounted`: `static build(root: Node3D)`, `static is_on_path(pos: Vector3) -> bool`, `const SPAWN_POS := Vector3(0, 0, 26)`, `const CLEARING_POS := Vector3(0, 0, -22)`.
  - `class_name FollowCamera extends Camera3D`: `var target: Node3D`, `var yaw: float`, `snap() -> void`.
  - `class_name Player extends CharacterBody3D`: `var camera: FollowCamera`, `var input_enabled: bool`, `var last_step_m: float`, `place(pos: Vector3, facing_yaw: float) -> void`.
  - `class_name World extends Node3D`: `signal encounter_triggered`, `set_active(active: bool) -> void`, `respawn() -> void`, `refresh_status(hero: Combatant) -> void`, `show_notice(text: String) -> void`. Al emitir `encounter_triggered` congela al jugador hasta `set_active(true)`. Si se ejecuta sola (padre = raíz del árbol), imprime cada encuentro y sigue.

- [ ] **Step 1: Crear `scripts/world/world_stage.gd`**

```gdscript
class_name WorldStage extends RefCounted
## Builds the world map from primitives: a 60 x 60 m grass field with a dirt path
## from the spawn point (south) to an empty clearing (north), rocks and invisible
## walls with collision, and hills outside the field. Same sky and sun as battles.

const FIELD_HALF := 30.0
const SPAWN_POS := Vector3(0, 0, 26)
const SPAWN_RADIUS := 4.0
const CLEARING_POS := Vector3(0, 0, -22)
const CLEARING_RADIUS := 8.0
const PATH_HALF_WIDTH := 1.5
## Corners of the dirt path, from the spawn point to the clearing.
const PATH_POINTS: Array[Vector3] = [
	Vector3(0, 0, 26),
	Vector3(3, 0, 12),
	Vector3(-2, 0, 0),
	Vector3(2, 0, -12),
	Vector3(0, 0, -22),
]
## [position, scale] of each rock (unit spheres, half buried), kept off the path
## and off the autoplay route.
const ROCKS := [
	[Vector3(-20, 0.4, -16), Vector3(1.4, 1.0, 1.2)],
	[Vector3(-22, 0.5, 14), Vector3(1.8, 1.2, 1.5)],
	[Vector3(18, 0.4, -18), Vector3(1.5, 1.0, 1.3)],
	[Vector3(22, 0.6, 16), Vector3(2.0, 1.4, 1.6)],
	[Vector3(-10, 0.3, -18), Vector3(1.0, 0.7, 0.9)],
	[Vector3(12, 0.4, -20), Vector3(1.3, 0.9, 1.1)],
	[Vector3(-12, 0.3, 23), Vector3(1.1, 0.8, 1.0)],
	[Vector3(24, 0.5, 0), Vector3(1.6, 1.1, 1.4)],
	[Vector3(-24, 0.4, -2), Vector3(1.5, 1.0, 1.2)],
	[Vector3(7, 0.3, -15), Vector3(0.9, 0.6, 0.8)],
]
## [position, scale] of each hill (unit spheres, half buried) around the field.
const HILLS := [
	[Vector3(-40, -5, -42), Vector3(22, 10, 22)],
	[Vector3(0, -6, -54), Vector3(28, 11, 20)],
	[Vector3(40, -5, -40), Vector3(22, 9, 22)],
	[Vector3(54, -6, 0), Vector3(20, 10, 28)],
	[Vector3(42, -5, 42), Vector3(22, 9, 22)],
	[Vector3(0, -6, 56), Vector3(28, 10, 20)],
	[Vector3(-42, -5, 42), Vector3(22, 10, 22)],
	[Vector3(-54, -6, 0), Vector3(20, 9, 28)],
]


static func build(root: Node3D) -> void:
	BattleStage.build_environment(root)
	_add_ground(root)
	_add_path(root)
	for rock in ROCKS:
		_add_rock(root, rock[0], rock[1])
	for hill in HILLS:
		BattleStage.add_mesh(root, BattleStage.unit_sphere(), BattleStage.HILL, hill[0], hill[1])
	_add_walls(root)


## True on the dirt path, the clearing and around the spawn point: no encounters there.
static func is_on_path(pos: Vector3) -> bool:
	var p := Vector2(pos.x, pos.z)
	if p.distance_to(Vector2(SPAWN_POS.x, SPAWN_POS.z)) < SPAWN_RADIUS:
		return true
	if p.distance_to(Vector2(CLEARING_POS.x, CLEARING_POS.z)) < CLEARING_RADIUS:
		return true
	for i in PATH_POINTS.size() - 1:
		var a := Vector2(PATH_POINTS[i].x, PATH_POINTS[i].z)
		var b := Vector2(PATH_POINTS[i + 1].x, PATH_POINTS[i + 1].z)
		if p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b)) < PATH_HALF_WIDTH:
			return true
	return false


static func _add_ground(root: Node3D) -> void:
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(160, 160)
	BattleStage.add_mesh(root, mesh, BattleStage.GRASS, Vector3.ZERO)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	shape.shape = WorldBoundaryShape3D.new()
	body.add_child(shape)
	root.add_child(body)


static func _add_path(root: Node3D) -> void:
	for i in PATH_POINTS.size() - 1:
		var a := PATH_POINTS[i]
		var b := PATH_POINTS[i + 1]
		var d := b - a
		var mesh := PlaneMesh.new()
		# Each strip runs half a width past both ends so the corners stay covered.
		mesh.size = Vector2(PATH_HALF_WIDTH * 2.0, d.length() + PATH_HALF_WIDTH * 2.0)
		var mid := (a + b) / 2.0 + Vector3(0, 0.01, 0)
		var yaw := rad_to_deg(atan2(d.x, d.z))
		BattleStage.add_mesh(root, mesh, BattleStage.DIRT, mid, Vector3.ONE, Vector3(0, yaw, 0))
	_add_disc(root, SPAWN_POS, SPAWN_RADIUS)
	_add_disc(root, CLEARING_POS, CLEARING_RADIUS)


static func _add_disc(root: Node3D, center: Vector3, radius: float) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.02
	BattleStage.add_mesh(root, mesh, BattleStage.DIRT, center + Vector3(0, 0.01, 0))


static func _add_rock(root: Node3D, pos: Vector3, scl: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	root.add_child(body)
	BattleStage.add_mesh(body, BattleStage.unit_sphere(), BattleStage.ROCK, Vector3.ZERO, scl)
	# Box collider instead of a scaled sphere: physics shapes must not be scaled.
	var box := BoxShape3D.new()
	box.size = scl * 1.6
	var shape := CollisionShape3D.new()
	shape.shape = box
	body.add_child(shape)


static func _add_walls(root: Node3D) -> void:
	var h := FIELD_HALF
	var walls := [
		[Vector3(0, 2, -h), Vector3(h * 2.0, 4, 1)],
		[Vector3(0, 2, h), Vector3(h * 2.0, 4, 1)],
		[Vector3(-h, 2, 0), Vector3(1, 4, h * 2.0)],
		[Vector3(h, 2, 0), Vector3(1, 4, h * 2.0)],
	]
	for wall in walls:
		var body := StaticBody3D.new()
		body.position = wall[0]
		var box := BoxShape3D.new()
		box.size = wall[1]
		var shape := CollisionShape3D.new()
		shape.shape = box
		body.add_child(shape)
		root.add_child(body)
```

- [ ] **Step 2: Crear `scripts/world/follow_camera.gd`**

```gdscript
class_name FollowCamera extends Camera3D
## Third-person camera behind and above a target. Follows it smoothly; Q / E turn it
## around the target. It never turns by itself when the target turns.

const DISTANCE := 6.0
const HEIGHT := 3.5
const LOOK_HEIGHT := 1.0
## Fraction of the remaining distance covered per second (exponential smoothing).
const FOLLOW_RATE := 6.0
## Radians per second while Q or E is held (about 120 degrees).
const TURN_RATE := 2.1
const FOV := 60.0

var target: Node3D
## Angle around the target; 0 puts the camera on the +Z side, looking toward -Z.
var yaw := 0.0


func _ready() -> void:
	fov = FOV


# Same tick as the player's movement, so the follow does not stutter.
func _physics_process(delta: float) -> void:
	if target == null:
		return
	var turn := 0.0
	if Input.is_physical_key_pressed(KEY_Q):
		turn -= 1.0
	if Input.is_physical_key_pressed(KEY_E):
		turn += 1.0
	yaw += turn * TURN_RATE * delta
	global_position = global_position.lerp(_goal_position(), minf(1.0, FOLLOW_RATE * delta))
	look_at(target.global_position + Vector3.UP * LOOK_HEIGHT, Vector3.UP)


## Jumps to the follow position without smoothing (start and respawn).
func snap() -> void:
	global_position = _goal_position()
	look_at(target.global_position + Vector3.UP * LOOK_HEIGHT, Vector3.UP)


func _goal_position() -> Vector3:
	var offset := Vector3(sin(yaw), 0.0, cos(yaw)) * DISTANCE
	return target.global_position + offset + Vector3.UP * HEIGHT
```

- [ ] **Step 3: Crear `scripts/world/player.gd`**

```gdscript
class_name Player extends CharacterBody3D
## Hero on the world map. Moves with WASD / arrows relative to the camera, turns
## smoothly toward where it walks and bobs while moving. Its model is a BattleActor.
## With `-- --autoplay` it walks AUTOPLAY_ROUTE in a loop instead of reading keys.

const ACTOR_SCENE := preload("res://scenes/battle/battle_actor.tscn")
const SPEED := 5.0
## How fast the model turns toward the walking direction (radians per second, roughly).
const TURN_SPEED := 10.0
const BOB_HEIGHT := 0.08
const BOB_TIME := 0.18
## Points walked in a loop by --autoplay, mostly on grass and clear of rocks.
const AUTOPLAY_ROUTE: Array[Vector3] = [
	Vector3(8, 0, 18),
	Vector3(16, 0, 6),
	Vector3(10, 0, -6),
	Vector3(-6, 0, -4),
	Vector3(-14, 0, 8),
	Vector3(-6, 0, 18),
]
const ROUTE_REACHED := 0.6

var camera: FollowCamera
var input_enabled := true
## Horizontal meters moved during the last physics frame.
var last_step_m := 0.0

var _model: BattleActor
var _autoplay := false
var _route_index := 0
var _bob_tween: Tween
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready() -> void:
	_autoplay = OS.get_cmdline_user_args().has("--autoplay")
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.6
	var shape := CollisionShape3D.new()
	shape.shape = capsule
	shape.position = Vector3(0, 0.8, 0)
	add_child(shape)
	_model = ACTOR_SCENE.instantiate()
	_model.look = BattleActor.Look.HERO
	add_child(_model)


## Puts the player at pos with the model turned to facing_yaw (0 faces -Z).
func place(pos: Vector3, facing_yaw: float) -> void:
	global_position = pos
	velocity = Vector3.ZERO
	_model.rotation.y = facing_yaw
	last_step_m = 0.0


func _physics_process(delta: float) -> void:
	var dir := _wanted_direction() if input_enabled else Vector3.ZERO
	velocity.x = dir.x * SPEED
	velocity.z = dir.z * SPEED
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= _gravity * delta
	var before := global_position
	move_and_slide()
	var moved := global_position - before
	moved.y = 0.0
	last_step_m = moved.length()
	if dir != Vector3.ZERO:
		var target_yaw := atan2(-dir.x, -dir.z)  # the model faces -Z
		_model.rotation.y = lerp_angle(_model.rotation.y, target_yaw, minf(1.0, TURN_SPEED * delta))
	_set_bobbing(dir != Vector3.ZERO)


func _wanted_direction() -> Vector3:
	if _autoplay:
		return _route_direction()
	var keys := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		keys.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		keys.x += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		keys.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		keys.y += 1.0
	if keys == Vector2.ZERO or camera == null:
		return Vector3.ZERO
	keys = keys.normalized()
	# Screen up is away from the camera; screen right is the camera's right.
	var forward := Vector3(-sin(camera.yaw), 0.0, -cos(camera.yaw))
	var right := Vector3(cos(camera.yaw), 0.0, -sin(camera.yaw))
	return right * keys.x - forward * keys.y


func _route_direction() -> Vector3:
	var to_goal := AUTOPLAY_ROUTE[_route_index] - global_position
	to_goal.y = 0.0
	if to_goal.length() < ROUTE_REACHED:
		_route_index = (_route_index + 1) % AUTOPLAY_ROUTE.size()
		return Vector3.ZERO
	return to_goal.normalized()


func _set_bobbing(on: bool) -> void:
	if on == (_bob_tween != null):
		return
	if _bob_tween:
		_bob_tween.kill()
		_bob_tween = null
		_model.position.y = 0.0
		return
	_bob_tween = create_tween().set_loops()
	_bob_tween.tween_property(_model, "position:y", BOB_HEIGHT, BOB_TIME) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_bob_tween.tween_property(_model, "position:y", 0.0, BOB_TIME) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
```

- [ ] **Step 4: Crear `scenes/world/player.tscn`**

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/world/player.gd" id="1_player"]

[node name="Player" type="CharacterBody3D"]
script = ExtResource("1_player")
```

- [ ] **Step 5: Crear `scripts/world/world.gd`**

```gdscript
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
```

- [ ] **Step 6: Crear `scenes/world/world.tscn`**

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/world/world.gd" id="1_world"]

[node name="World" type="Node3D"]
script = ExtResource("1_world")
```

- [ ] **Step 7: Importar y validar**

Run: `.\tools\godot.cmd --headless --path . --import`
Run (uno por script): `.\tools\godot.cmd --headless --path . --check-only --script res://scripts/world/world_stage.gd` (y `follow_camera.gd`, `player.gd`, `world.gd`)
Expected: sin `ERROR` / `SCRIPT ERROR` / `Parse Error`.

- [ ] **Step 8: Ejecutar el mundo solo en autoplay y revisar la salida**

Run: `.\tools\godot.cmd --path . res://scenes/world/world.tscn --quit-after 3600 -- --autoplay`
Expected: el héroe recorre el circuito; la consola imprime varias líneas `Encuentro en (...) (en el camino: false)` (nunca `true`); no hay `ERROR`, `SCRIPT ERROR` ni `WARNING`. Si el héroe se atasca contra una roca o un muro, mover la roca o el punto de ruta y repetir.

- [ ] **Step 9: Grabar fotogramas y revisarlos**

```powershell
$frames = "$env:TEMP\rpg-turnos-frames"
Remove-Item -Recurse -Force $frames -ErrorAction SilentlyContinue
New-Item -ItemType Directory $frames | Out-Null
.\tools\godot.cmd --path . res://scenes/world/world.tscn --resolution 640x360 --write-movie "$frames\f.png" --fixed-fps 10 --quit-after 300 -- --autoplay
```

Abrir con Read varios fotogramas (p. ej. 5, 60, 150, 280) y comprobar:
- Héroe de espaldas al inicio, sobre el disco de tierra, con el camino delante hacia el norte.
- La cámara lo sigue por detrás y arriba; el héroe gira hacia donde anda y se balancea.
- Hierba, camino con curvas, rocas, colinas al fondo, cielo y niebla como en el combate; sombras visibles.
- Ventana de estado arriba a la izquierda con "Héroe", "PV 30 / 30" y "EXP 0".

Al terminar: `Remove-Item -Recurse -Force $frames`.

- [ ] **Step 10: Commit**

```powershell
git add scripts/world scenes/world
git commit -m "Add the walkable world map with follow camera and encounters"
```

---

### Task 4: Bucle completo (Game con mapa, combate encima y fundidos)

**Files:**
- Modify: `scripts/game/game.gd` (reescritura completa)

**Interfaces:**
- Consumes: `GameState` (Task 1); `BattleScene.setup/finished` (Task 2); `World.encounter_triggered/set_active/respawn/refresh_status/show_notice` (Task 3).
- Produces: el bucle jugable desde `run/main_scene`.

- [ ] **Step 1: Reescribir `scripts/game/game.gd`**

```gdscript
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
	_world.refresh_status(state.hero)
	_world.encounter_triggered.connect(_on_encounter)
	_build_fade()


func _on_encounter() -> void:
	if _busy:
		return
	_busy = true
	await _fade_to(1.0)
	_world.set_active(false)
	var battle: BattleScene = BATTLE_SCENE.instantiate()
	battle.setup(state.hero, SLIME_DATA)
	add_child(battle)
	await _fade_to(0.0)
	var won: bool = await battle.finished
	await _fade_to(1.0)
	battle.queue_free()
	if not won:
		state.heal_full()
		_world.respawn()
	_world.refresh_status(state.hero)
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
```

- [ ] **Step 2: Validar**

Run: `.\tools\godot.cmd --headless --path . --check-only --script res://scripts/game/game.gd`
Expected: sin `ERROR` / `SCRIPT ERROR` / `Parse Error`.

- [ ] **Step 3: Ejecutar en autoplay y revisar la salida**

Run: `.\tools\godot.cmd --path . --quit-after 9000 -- --autoplay`
Expected: el héroe anda, salta un combate, se juega solo, vuelve al mapa y sigue andando; con el tiempo pierde un combate y reaparece en el inicio. En la consola no hay `ERROR`, `SCRIPT ERROR` ni `WARNING`.

- [ ] **Step 4: Grabar fotogramas y revisarlos**

```powershell
$frames = "$env:TEMP\rpg-turnos-frames"
Remove-Item -Recurse -Force $frames -ErrorAction SilentlyContinue
New-Item -ItemType Directory $frames | Out-Null
.\tools\godot.cmd --path . --resolution 640x360 --write-movie "$frames\f.png" --fixed-fps 10 --quit-after 1500 -- --autoplay
```

Localizar con Read (búsqueda binaria por número de fotograma) y comprobar:
- Mapa con la ventana de estado → fundido a negro → combate ("¡Un Slime salvaje aparece!") sin la ventana de estado del mapa encima.
- "Continuar" → fundido → de vuelta en el mapa **en el mismo punto** donde empezó el combate, con PV/EXP actualizados en la ventana de estado.
- Si en los 150 s grabados hay una derrota: reaparición en el inicio con "PV 30 / 30", la EXP de antes y el aviso "Has vuelto al inicio.". Si no la hay, anotarlo en el informe (lo cubrirá la prueba manual).

Al terminar: `Remove-Item -Recurse -Force $frames`.

- [ ] **Step 5: Prueba manual del usuario**

Pedir al usuario que ejecute `.\tools\godot.cmd --path .` y compruebe: WASD/flechas mueven relativo a la cámara, Q/E la giran, por el camino no salen combates, en la hierba sí; tras ganar vuelve al mismo sitio con PV/EXP actualizados; tras perder vuelve al inicio curado con la EXP intacta. Recoger sus comentarios antes de cerrar la tarea.

- [ ] **Step 6: Commit**

```powershell
git add scripts/game/game.gd
git commit -m "Run battles on top of the world map with fades and respawn"
```

---

### Task 5: Documentación y merge a develop

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Sustituir la sección `## Layout` de `CLAUDE.md`** (todo desde `## Layout` hasta justo antes de `## No tests — ever`) por:

```markdown
## Layout

- `scenes/game/game.tscn` + `scripts/game/game.gd` — main scene (`run/main_scene`). Owns a `GameState` and the `World`; on `World.encounter_triggered` it fades to black, `World.set_active(false)`, instantiates a `BattleScene` with `setup(state.hero, slime.tres)` on top, awaits `finished(won)`, frees it and turns the map back on (after a defeat: `heal_full()` and `World.respawn()`). The map is never freed, so position, camera and encounter grace survive battles.
- `scripts/game/game_state.gd` (`GameState`, `RefCounted`) — session state kept in memory: the hero `Combatant` (a duplicate of `data/hero.tres` that lives the whole session; battles change its HP and EXP in place), `heal_full()`.
- `scenes/world/world.tscn` + `scripts/world/world.gd` (`World`) — world map: `WorldStage`, `Player`, `FollowCamera`, status window (name, PV, EXP), encounters through `EncounterMeter` (only off the path). Emits `encounter_triggered` and freezes the player until `set_active(true)`; `respawn()`, `refresh_status(hero)`, `show_notice(text)`. Run on its own it prints each encounter and keeps going.
- `scripts/world/world_stage.gd` (`WorldStage`) — static builder of the 60 × 60 m field: dirt path from `SPAWN_POS` (south) to an empty clearing at `CLEARING_POS` (north, reserved for the hub), rocks with box colliders, invisible walls, hills outside; `is_on_path(pos)` (path, clearing and spawn area are safe).
- `scenes/world/player.tscn` + `scripts/world/player.gd` (`Player`, `CharacterBody3D`) — WASD / arrows relative to `FollowCamera.yaw`, 5 m/s, smooth turn, bob while walking; model is a `BattleActor` (`HERO`); `last_step_m` feeds the encounter meter; `place(pos, yaw)`. `--autoplay` walks `AUTOPLAY_ROUTE` in a loop.
- `scripts/world/follow_camera.gd` (`FollowCamera`) — third-person follow (6 m back, 3.5 m up), Q / E turn it, `snap()`.
- `scripts/world/encounter_meter.gd` (`EncounterMeter`, `RefCounted`) — encounter rule: 5 m grace after `reset()`, then 8 % per full meter walked on grass.
- `scenes/battle/battle_scene.tscn` + `scripts/battle/battle_scene.gd` (`BattleScene`) — one battle: call `setup(hero, enemy_data)` before adding it (hero used as is, enemy duplicated); builds stage (`BattleStage.build`), hero and slime `BattleActor`s, camera and a `CanvasLayer` with `BattleHud` and `BattleResult`. Flow: HUD `command_chosen` → `BattleEngine.resolve_round()` → `_play_event()` per event → menu again, or result overlay → "Continuar" → `finished(won)`. `--autoplay` picks "Atacar" and continues by itself.
- `scripts/battle/battle_engine.gd` (`BattleEngine`, `RefCounted`) — pure round rules: initiative `speed × randf_range(0.5, 1.5)`, 5 % miss, 1/16 crit (ignores DEF), damage `base × randf_range(0.875, 1.125)` rounded, minimum 1, where `base = max(1, ATK − DEF/2)` (crit: `ATK × 1.5`). Returns `Array[Dictionary]` events built by `BattleEvent` (`scripts/battle/battle_event.gd`); `state` is `ONGOING`, `WON` or `LOST`. Never touches nodes.
- `scripts/battle/combatant.gd` (`Combatant`, `Resource`) — fighter stats; data in `data/hero.tres`, `data/slime.tres`.
- `scenes/battle/battle_actor.tscn` + `scripts/battle/battle_actor.gd` (`BattleActor`) — primitive-mesh fighter (`look`: `HERO` / `SLIME`, set before `add_child`), faces -Z; awaitable tweens `play_attack`, `play_hit` (flash + floating `Label3D` number), `play_dodge`, `play_defeat`; `reset()`.
- `scripts/battle/battle_stage.gd` (`BattleStage`) — battle backdrop builder; `build_environment(root)` (procedural sky, ACES tonemap, SSAO, glow, fog, warm sun with shadows), `add_mesh()` and `unit_sphere()` are shared with `WorldStage`.
- `scenes/ui/battle_hud.tscn` + `scripts/ui/battle_hud.gd` (`BattleHud`) — hero status, "Atacar" menu, typed message window; `await show_message(text)` returns on click / Enter / Space or after auto-advance; `static make_window()` is the shared window style.
- `scenes/ui/battle_result.tscn` + `scripts/ui/battle_result.gd` (`BattleResult`) — victory/defeat overlay with "Continuar" (`continue_requested`).
- `docs/boost/specs/`, `docs/boost/plans/` — design specs and implementation plans.

## Conventions

- Scenes and scripts are written as text. The `.tscn` files only hold the root node and its script; every other node (stage, UI, actors) is created in code.
- Game rules live in pure classes (`RefCounted` / `Resource`) that never touch nodes; scenes only play their results back.
- No autoloads: `Game` owns the state and passes it explicitly. If an autoload is ever added, a `class_name` script must not use its bare name (it compiles before autoloads exist, e.g. in `--script` runs); look it up at runtime with `get_node_or_null("/root/...")`.
```

- [ ] **Step 2: Actualizar la sección `## Commands` de `CLAUDE.md`**

Sustituir las líneas de "Run the game picking..." y "Record frames..." por:

```markdown
- Run the game on autoplay (walks a route, fights picking "Atacar", continues by itself): `.\tools\godot.cmd --path . -- --autoplay`
- Run only the world map (prints encounters instead of fighting): `.\tools\godot.cmd --path . res://scenes/world/world.tscn -- --autoplay`
- Record frames to check visuals (not headless; writes `f00000000.png`, ...; delete the folder afterwards): `.\tools\godot.cmd --path . --resolution 640x360 --write-movie <dir>\f.png --fixed-fps 10 --quit-after 600 -- --autoplay`
```

- [ ] **Step 3: Commit**

```powershell
git add CLAUDE.md
git commit -m "Document the world loop layout and project conventions in CLAUDE.md"
```

- [ ] **Step 4: Merge a develop** (solo con el visto bueno del usuario tras la prueba manual)

```powershell
git checkout develop
git merge --no-ff feature/mundo-exploracion -m "Merge branch 'feature/mundo-exploracion' into develop"
git branch -d feature/mundo-exploracion
git log --oneline --graph -10
```

Expected: `develop` contiene el merge; la rama feature queda borrada.

---

## Notas para la ejecución

- Mientras hay combate, mapa y combate tienen cada uno su `WorldEnvironment` (idénticos). Godot usa uno; es un aviso de configuración del editor, no sale en la consola. Si apareciera un `WARNING` en tiempo de ejecución por ello, `World.set_active(false)` debe además quitar del árbol su `WorldEnvironment` y volver a añadirlo al reactivarse.
- `--fixed-fps 10` mantiene la física correcta (6 ticks por fotograma). No bajar de 10: con menos, `max_physics_steps_per_frame` (8) recorta la simulación y el héroe anda a cámara lenta.
- Las grabaciones a 640×360 ocupan unos cientos de MB; borrar la carpeta tras revisarlas.
