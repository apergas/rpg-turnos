# Prototipo de combate por turnos — plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Este proyecto NO lleva tests** (ver `CLAUDE.md`, sección "No tests — ever"). Ignora cualquier paso de TDD de los skills: no crees `tests/`, scripts de test ni frameworks. Cada tarea se verifica con `--import`, `--check-only` y, al final, ejecutando el juego.

**Goal:** Un combate jugable por rondas, héroe contra slime, en 3D con cámara en tercera persona diagonal y una sola acción ("Atacar").

**Architecture:** `BattleEngine` (GDScript puro, `RefCounted`) resuelve cada ronda y devuelve una lista de eventos; `BattleScene` (3D) construye el escenario con primitivas y reproduce esos eventos con tweens, mensajes y cámara. La UI (`BattleHud`, `BattleResult`) se construye por código dentro de escenas mínimas.

**Tech Stack:** Godot 4.7.2, GDScript, renderizador Forward+, Jolt Physics. Todo escrito como texto (sin editor).

Spec: `docs/boost/specs/2026-11-02-combate-prototipo-design.md`.

## Global Constraints

- Godot **4.7.2**; ejecutable vía `.\tools\godot.cmd` (no está en el PATH).
- Renderizador **Forward+** (por defecto; no poner `gl_compatibility`), física 3D **Jolt Physics**, driver Windows `d3d12`.
- Ventana base **1280×720**, stretch `canvas_items`, aspect `expand`.
- **Sin tests unitarios ni automatizados, en ningún momento.**
- Escenas y scripts se escriben como texto; `.godot/` nunca se edita a mano.
- Tras crear un script con `class_name` nuevo: `.\tools\godot.cmd --headless --path . --import`.
- Commitear los `.uid` generados junto a sus scripts.
- Gitflow: trabajar en `feature/combate-prototipo` (ya existe); nunca commitear directamente en `main` ni `develop`; merge final a `develop` con `--no-ff`.
- Mensajes de commit terminan con `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Textos visibles en español; comentarios de código en inglés (como en `godot-example`).
- Estadísticas: Héroe PV 30 / ATQ 12 / DEF 6 / VEL 8; Slime PV 24 / ATQ 7 / DEF 3 / VEL 5 / EXP 4.
- Reglas: iniciativa `speed × randf_range(0.5, 1.5)` (empate → héroe); fallo 5 %; crítico 1/16 (×1,5, ignora DEF); daño normal `max(1, ATQ − DEF/2) × randf_range(0.875, 1.125)` redondeado; daño mínimo 1; PV nunca < 0.

Todos los comandos se ejecutan en PowerShell desde `C:\Users\peixe\Documents\rpg-turnos`.

## Mapa de archivos

| Archivo | Responsabilidad |
|---|---|
| `project.godot`, `icon.svg` | Configuración del proyecto |
| `.mcp.json`, `tools/` (git-ignorados) | Wrapper de Godot, Node portable y MCP de Godot copiados de `godot-example` |
| `scripts/battle/combatant.gd` | `Combatant`: estadísticas de un luchador |
| `data/hero.tres`, `data/slime.tres` | Estadísticas iniciales |
| `scripts/battle/battle_event.gd` | `BattleEvent`: tipos y constructores de eventos |
| `scripts/battle/battle_engine.gd` | `BattleEngine`: reglas y resolución de rondas |
| `scenes/battle/battle_actor.tscn` + `scripts/battle/battle_actor.gd` | `BattleActor`: combatiente 3D con primitivas y animaciones |
| `scenes/ui/battle_hud.tscn` + `scripts/ui/battle_hud.gd` | `BattleHud`: estado del héroe, menú, mensajes |
| `scenes/ui/battle_result.tscn` + `scripts/ui/battle_result.gd` | `BattleResult`: victoria/derrota y "Luchar otra vez" |
| `scripts/battle/battle_stage.gd` | `BattleStage`: cielo, luz, suelo, camino, rocas y colinas (helper estático; no estaba en el spec, separa el escenario de la lógica de la escena) |
| `scenes/battle/battle_scene.tscn` + `scripts/battle/battle_scene.gd` | Escena principal: cámara, actores, UI y reproducción de eventos |
| `CLAUDE.md` | Documentación del proyecto |

---

### Task 1: Proyecto Godot y tooling

**Files:**
- Create: `project.godot`, `icon.svg` (copia), `.mcp.json`, `tools/` (copia, git-ignorado)
- Modify: `CLAUDE.md`

**Interfaces:**
- Produces: proyecto Godot que importa sin errores; `.\tools\godot.cmd` funcional.

- [ ] **Step 1: Copiar tooling e icono desde godot-example**

```powershell
Copy-Item -Recurse ..\godot-example\tools .\tools
Copy-Item ..\godot-example\icon.svg .\icon.svg
Remove-Item .\tools\serve_web.ps1
```

(`tools/` y `.mcp.json` ya están en `.gitignore`.)

- [ ] **Step 2: Crear `.mcp.json`**

```json
{
  "mcpServers": {
	"godot": {
	  "command": "C:/Users/peixe/Documents/rpg-turnos/tools/node/node.exe",
	  "args": ["C:/Users/peixe/Documents/rpg-turnos/tools/godot-mcp/build/index.js"],
	  "env": {
		"GODOT_PATH": "C:/Users/peixe/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"
	  }
	}
  }
}
```

- [ ] **Step 3: Crear `project.godot`** (sin `run/main_scene` todavía; se añade en la Task 5)

```ini
; Engine configuration file.
; It's best edited using the editor UI and not directly,
; since the parameters that go here are not all obvious.
;
; Format:
;   [section] ; section goes between []
;   param=value ; assign values to parameters

config_version=5

[application]

config/name="rpg-turnos"
config/version="0.1"
config/features=PackedStringArray("4.7", "Forward Plus")
config/icon="res://icon.svg"

[display]

window/size/viewport_width=1280
window/size/viewport_height=720
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"

[physics]

3d/physics_engine="Jolt Physics"

[rendering]

rendering_device/driver.windows="d3d12"
```

- [ ] **Step 4: Añadir la sección de comandos a `CLAUDE.md`** (después de "No tests — ever")

```markdown
## Commands

`godot` is not on the system PATH. Use the wrapper `tools\godot.cmd` (forwards all arguments to the Godot 4.7.2 console exe in `Downloads`). `tools/` and `.mcp.json` are local and git-ignored (copied from `godot-example`).

- Import / refresh the class cache (after adding a `class_name` script): `.\tools\godot.cmd --headless --path . --import`
- Validate a script: `.\tools\godot.cmd --headless --path . --check-only --script res://scripts/battle/battle_engine.gd`
- Run the game: `.\tools\godot.cmd --path .`
- Run the game picking "Atacar" automatically and restarting after each battle: `.\tools\godot.cmd --path . -- --autoplay`
- Record frames to check visuals (not headless; writes `f00000000.png`, `f00000001.png`, ...): `.\tools\godot.cmd --path . --write-movie <dir>\f.png --fixed-fps 10 --quit-after 300 -- --autoplay`

The `godot` MCP tools (`run_project`, `get_debug_output`, ...) need `projectPath` set to this directory.
```

- [ ] **Step 5: Verificar que el proyecto importa**

Run: `.\tools\godot.cmd --headless --path . --import`
Expected: termina sin líneas `ERROR`; aparece la carpeta `.godot/`.

Run: `.\tools\godot.cmd --headless --path . --quit-after 10`
Expected: sale sin errores (no hay escena principal; puede avisar de ello, nada más).

- [ ] **Step 6: Commit**

```powershell
git add project.godot icon.svg icon.svg.import CLAUDE.md
git commit -m "Set up the Godot 4.7 Forward+ project and tooling docs

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Datos y motor de combate

**Files:**
- Create: `scripts/battle/combatant.gd`, `scripts/battle/battle_event.gd`, `scripts/battle/battle_engine.gd`, `data/hero.tres`, `data/slime.tres`

**Interfaces:**
- Produces:
  - `class_name Combatant extends Resource` con `display_name: String`, `max_hp: int`, `hp: int`, `attack: int`, `defense: int`, `speed: int`, `exp_reward: int`, `experience: int`, `is_alive() -> bool`.
  - `class_name BattleEvent` con constantes `ATTACK, MISS, DAMAGE, DEFEATED, VICTORY, DEFEAT` (strings de tipo), `HERO := "hero"`, `ENEMY := "enemy"` y constructores estáticos `attack(actor, target)`, `miss(actor, target)`, `damage(target, amount, crit, hp_left)`, `defeated(target)`, `victory(amount)`, `defeat()` que devuelven `Dictionary`.
  - `class_name BattleEngine extends RefCounted`: `enum State { ONGOING, WON, LOST }`, `const CMD_ATTACK := "attack"`, `_init(hero: Combatant, enemy: Combatant, rng: RandomNumberGenerator)`, `var hero`, `var enemy`, `var state`, `resolve_round(hero_cmd: String) -> Array[Dictionary]`.

- [ ] **Step 1: Crear `scripts/battle/combatant.gd`**

```gdscript
class_name Combatant extends Resource
## Stats of one fighter. Battles work on duplicates, so the .tres files never change.

@export var display_name := ""
@export var max_hp := 1
@export var hp := 1
@export var attack := 1
@export var defense := 0
@export var speed := 1
## EXP the winner gets for defeating this fighter.
@export var exp_reward := 0
## EXP accumulated so far (only meaningful for the hero). Not called `exp`, which
## would shadow the built-in exp() function.
@export var experience := 0


func is_alive() -> bool:
	return hp > 0
```

- [ ] **Step 2: Crear `scripts/battle/battle_event.gd`**

```gdscript
class_name BattleEvent extends RefCounted
## Event dictionaries produced by BattleEngine and played back by the battle scene.
## Every event has a "type"; sides are HERO or ENEMY.

const ATTACK := "attack"
const MISS := "miss"
const DAMAGE := "damage"
const DEFEATED := "defeated"
const VICTORY := "victory"
const DEFEAT := "defeat"

const HERO := "hero"
const ENEMY := "enemy"


static func attack(actor: String, target: String) -> Dictionary:
	return {"type": ATTACK, "actor": actor, "target": target}


static func miss(actor: String, target: String) -> Dictionary:
	return {"type": MISS, "actor": actor, "target": target}


static func damage(target: String, amount: int, crit: bool, hp_left: int) -> Dictionary:
	return {"type": DAMAGE, "target": target, "amount": amount, "crit": crit, "hp_left": hp_left}


static func defeated(target: String) -> Dictionary:
	return {"type": DEFEATED, "target": target}


static func victory(amount: int) -> Dictionary:
	return {"type": VICTORY, "exp": amount}


static func defeat() -> Dictionary:
	return {"type": DEFEAT}
```

- [ ] **Step 3: Crear `scripts/battle/battle_engine.gd`**

```gdscript
class_name BattleEngine extends RefCounted
## Pure turn-based battle rules (Dragon Quest style rounds). Resolves one round at a
## time and returns the events that happened; never touches nodes. Mutates the
## Combatants it is given, so callers pass duplicates of the data files.

enum State { ONGOING, WON, LOST }

const CMD_ATTACK := "attack"

const MISS_CHANCE := 0.05
const CRIT_CHANCE := 1.0 / 16.0
const CRIT_MULT := 1.5
const DAMAGE_SPREAD := Vector2(0.875, 1.125)
const INITIATIVE_SPREAD := Vector2(0.5, 1.5)

var hero: Combatant
var enemy: Combatant
var state := State.ONGOING

var _rng: RandomNumberGenerator


func _init(p_hero: Combatant, p_enemy: Combatant, rng: RandomNumberGenerator) -> void:
	hero = p_hero
	enemy = p_enemy
	_rng = rng


## Resolves a full round with the hero's command (the enemy always attacks).
## Returns an empty array once the battle is over.
func resolve_round(hero_cmd: String) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if state != State.ONGOING:
		return events
	assert(hero_cmd == CMD_ATTACK, "Unknown command: %s" % hero_cmd)
	for side in _turn_order():
		var target_side := _other(side)
		if not _fighter(side).is_alive():
			continue
		_attack(side, target_side, events)
		if not _fighter(target_side).is_alive():
			break
	if not enemy.is_alive():
		state = State.WON
		hero.experience += enemy.exp_reward
		events.append(BattleEvent.victory(enemy.exp_reward))
	elif not hero.is_alive():
		state = State.LOST
		events.append(BattleEvent.defeat())
	return events


func _turn_order() -> Array[String]:
	var hero_roll := hero.speed * _rng.randf_range(INITIATIVE_SPREAD.x, INITIATIVE_SPREAD.y)
	var enemy_roll := enemy.speed * _rng.randf_range(INITIATIVE_SPREAD.x, INITIATIVE_SPREAD.y)
	if hero_roll >= enemy_roll:
		return [BattleEvent.HERO, BattleEvent.ENEMY]
	return [BattleEvent.ENEMY, BattleEvent.HERO]


func _attack(side: String, target_side: String, events: Array[Dictionary]) -> void:
	events.append(BattleEvent.attack(side, target_side))
	if _rng.randf() < MISS_CHANCE:
		events.append(BattleEvent.miss(side, target_side))
		return
	var target := _fighter(target_side)
	var crit := _rng.randf() < CRIT_CHANCE
	var amount := _roll_damage(_fighter(side), target, crit)
	target.hp = maxi(target.hp - amount, 0)
	events.append(BattleEvent.damage(target_side, amount, crit, target.hp))
	if target.hp == 0:
		events.append(BattleEvent.defeated(target_side))


func _roll_damage(attacker: Combatant, defender: Combatant, crit: bool) -> int:
	var base: float
	if crit:
		base = attacker.attack * CRIT_MULT
	else:
		base = maxf(1.0, attacker.attack - defender.defense / 2.0)
	return maxi(1, roundi(base * _rng.randf_range(DAMAGE_SPREAD.x, DAMAGE_SPREAD.y)))


func _fighter(side: String) -> Combatant:
	return hero if side == BattleEvent.HERO else enemy


func _other(side: String) -> String:
	return BattleEvent.ENEMY if side == BattleEvent.HERO else BattleEvent.HERO
```

- [ ] **Step 4: Crear `data/hero.tres`**

```ini
[gd_resource type="Resource" script_class="Combatant" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/battle/combatant.gd" id="1_combatant"]

[resource]
script = ExtResource("1_combatant")
display_name = "Héroe"
max_hp = 30
hp = 30
attack = 12
defense = 6
speed = 8
```

- [ ] **Step 5: Crear `data/slime.tres`**

```ini
[gd_resource type="Resource" script_class="Combatant" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/battle/combatant.gd" id="1_combatant"]

[resource]
script = ExtResource("1_combatant")
display_name = "Slime"
max_hp = 24
hp = 24
attack = 7
defense = 3
speed = 5
exp_reward = 4
```

- [ ] **Step 6: Importar y validar**

Run: `.\tools\godot.cmd --headless --path . --import`
Expected: sin `ERROR`; se generan los `.uid` de los tres scripts.

Run (uno por script):
`.\tools\godot.cmd --headless --path . --check-only --script res://scripts/battle/combatant.gd`
`.\tools\godot.cmd --headless --path . --check-only --script res://scripts/battle/battle_event.gd`
`.\tools\godot.cmd --headless --path . --check-only --script res://scripts/battle/battle_engine.gd`
Expected: los tres terminan sin `SCRIPT ERROR` ni `Parse Error`.

- [ ] **Step 7: Commit**

```powershell
git add scripts data
git commit -m "Add combatant data and the round-based battle engine

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Actor 3D de combate

**Files:**
- Create: `scripts/battle/battle_actor.gd`, `scenes/battle/battle_actor.tscn`

**Interfaces:**
- Produces: `class_name BattleActor extends Node3D` con `enum Look { HERO, SLIME }`, `@export var look`, y métodos que se pueden esperar con `await`: `play_attack(target_pos: Vector3)`, `play_hit(amount: int, crit: bool)`, `play_dodge()`, `play_defeat()`; más `reset()` (síncrono). La parte frontal del modelo mira a −Z (usar `look_at` hacia el rival).

- [ ] **Step 1: Crear `scripts/battle/battle_actor.gd`**

```gdscript
class_name BattleActor extends Node3D
## 3D stand-in for a combatant built from primitive meshes. The model faces -Z, so
## look_at() the opponent. Animations are tweens on the inner body and can be awaited.

enum Look { HERO, SLIME }

@export var look := Look.HERO

## Height of the floating damage numbers.
var _top := 2.0
## Visual root moved and scaled by the animations; the actor node itself stays put.
var _body: Node3D
var _materials: Array[StandardMaterial3D] = []
var _idle_tween: Tween


func _ready() -> void:
	_body = Node3D.new()
	add_child(_body)
	match look:
		Look.HERO:
			_build_hero()
		Look.SLIME:
			_build_slime()
	reset()


## Back to the starting pose: visible, opaque, no flash, idle animation running.
func reset() -> void:
	show()
	_body.position = Vector3.ZERO
	_body.scale = Vector3.ONE
	_set_flash(false)
	for mat in _materials:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
		mat.albedo_color.a = 1.0
	if look == Look.SLIME:
		_start_bounce()


## Lunges toward the target and steps back.
func play_attack(target_pos: Vector3) -> void:
	var base := global_position
	var dir := target_pos - base
	dir.y = 0.0
	var lunge := dir.normalized() * minf(1.2, dir.length() * 0.4)
	var t := create_tween()
	t.tween_property(_body, "global_position", base + lunge, 0.15) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(_body, "global_position", base, 0.2) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await t.finished


## White flash, small knockback and a floating damage number.
func play_hit(amount: int, crit: bool) -> void:
	_spawn_number(amount, crit)
	var base := global_position
	var knockback := global_basis.z.normalized() * (0.5 if crit else 0.3)
	_set_flash(true)
	var t := create_tween()
	t.tween_property(_body, "global_position", base + knockback, 0.08)
	t.tween_callback(_set_flash.bind(false))
	t.tween_property(_body, "global_position", base, 0.15)
	await t.finished


## Side step used when an attack misses.
func play_dodge() -> void:
	var base := global_position
	var side := global_basis.x.normalized() * 0.6
	var t := create_tween()
	t.tween_property(_body, "global_position", base + side, 0.1) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(_body, "global_position", base, 0.15)
	await t.finished


## Squashes, shrinks and fades out, then hides.
func play_defeat() -> void:
	if _idle_tween:
		_idle_tween.kill()
	for mat in _materials:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var t := create_tween()
	t.tween_property(_body, "scale", Vector3(1.25, 0.3, 1.25), 0.2)
	t.tween_property(_body, "scale", Vector3(0.05, 0.05, 0.05), 0.35)
	t.parallel().tween_method(_set_alpha, 1.0, 0.0, 0.35)
	await t.finished
	hide()


func _build_hero() -> void:
	_top = 2.1
	_add_mesh(_capsule(0.32, 1.2), Color(0.75, 0.12, 0.12), Vector3(0, 0.6, 0))  # body / tunic
	_add_mesh(_sphere(0.27), Color(0.96, 0.78, 0.62), Vector3(0, 1.45, 0))  # head
	_add_mesh(_sphere(0.29), Color(0.92, 0.62, 0.2), Vector3(0, 1.52, 0.06), \
		Vector3.ZERO, Vector3(1.0, 0.85, 1.0))  # hair, seen from behind
	_add_mesh(_box(Vector3(0.08, 0.9, 0.04)), Color(0.75, 0.75, 0.8), \
		Vector3(0.42, 0.85, -0.2), Vector3(-30, 0, 0))  # sword


func _build_slime() -> void:
	_top = 1.4
	_add_mesh(_sphere(0.6), Color(0.55, 0.3, 0.85), Vector3(0, 0.45, 0), \
		Vector3.ZERO, Vector3(1.0, 0.75, 1.0))  # body
	for x in [-0.2, 0.2]:
		_add_mesh(_sphere(0.13), Color.WHITE, Vector3(x, 0.6, -0.48))  # eye
		_add_mesh(_sphere(0.06), Color(0.05, 0.05, 0.05), Vector3(x, 0.6, -0.6))  # pupil


func _start_bounce() -> void:
	if _idle_tween:
		_idle_tween.kill()
	_idle_tween = create_tween().set_loops()
	_idle_tween.tween_property(_body, "scale", Vector3(1.08, 0.9, 1.08), 0.35) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_idle_tween.tween_property(_body, "scale", Vector3.ONE, 0.35) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _spawn_number(amount: int, crit: bool) -> void:
	var label := Label3D.new()
	label.text = str(amount)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.pixel_size = 0.005
	label.font_size = 96 if crit else 64
	label.outline_size = 16
	label.modulate = Color(1.0, 0.85, 0.2) if crit else Color.WHITE
	label.position = Vector3(0, _top, 0)
	add_child(label)
	var t := label.create_tween().set_parallel()
	t.tween_property(label, "position:y", _top + 0.8, 0.9)
	t.tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.3)
	t.chain().tween_callback(label.queue_free)


func _set_flash(on: bool) -> void:
	for mat in _materials:
		mat.emission_enabled = on
		mat.emission = Color.WHITE
		mat.emission_energy_multiplier = 1.5


func _set_alpha(alpha: float) -> void:
	for mat in _materials:
		mat.albedo_color.a = alpha


func _add_mesh(mesh: Mesh, color: Color, pos: Vector3, rot_deg := Vector3.ZERO, \
		scl := Vector3.ONE) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.8
	_materials.append(mat)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.scale = scl
	_body.add_child(mi)


static func _sphere(radius: float) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	return mesh


static func _capsule(radius: float, height: float) -> CapsuleMesh:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	return mesh


static func _box(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh
```

- [ ] **Step 2: Crear `scenes/battle/battle_actor.tscn`**

```ini
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/battle/battle_actor.gd" id="1_actor"]

[node name="BattleActor" type="Node3D"]
script = ExtResource("1_actor")
```

- [ ] **Step 3: Importar y validar**

Run: `.\tools\godot.cmd --headless --path . --import`
Run: `.\tools\godot.cmd --headless --path . --check-only --script res://scripts/battle/battle_actor.gd`
Expected: sin `ERROR` / `SCRIPT ERROR` / `Parse Error`.

- [ ] **Step 4: Commit**

```powershell
git add scripts/battle scenes/battle
git commit -m "Add primitive-based 3D battle actor with tween animations

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: HUD de combate y pantalla de resultado

**Files:**
- Create: `scripts/ui/battle_hud.gd`, `scenes/ui/battle_hud.tscn`, `scripts/ui/battle_result.gd`, `scenes/ui/battle_result.tscn`

**Interfaces:**
- Consumes: `Combatant` (Task 2), `BattleEngine.CMD_ATTACK` (Task 2).
- Produces:
  - `class_name BattleHud extends Control`: `signal command_chosen(cmd: String)`, `set_hero(c: Combatant)`, `update_hp(hp: int, max_hp: int)`, `show_menu()`, `hide_menu()`, `show_message(text: String)` (se espera con `await`; vuelve al pulsar clic/Enter/Espacio o tras el auto-avance), `static make_window() -> PanelContainer`.
  - `class_name BattleResult extends Control`: `signal retry_requested`, `show_victory(exp_gained: int, total_exp: int)`, `show_defeat()`. Empieza oculto; al pulsar el botón se oculta y emite `retry_requested`.

- [ ] **Step 1: Crear `scripts/ui/battle_hud.gd`**

```gdscript
class_name BattleHud extends Control
## Dragon Quest style battle UI: hero status (top left), command menu and message
## window (bottom). show_message() can be awaited: it types the text out and returns
## when the player advances (click, Enter, Space) or after a short auto-advance.

signal command_chosen(cmd: String)

const CHAR_TIME := 0.025
const AUTO_ADVANCE := 0.6
const FONT_SIZE := 24

var _name_label: Label
var _hp_label: Label
var _hp_bar: ProgressBar
var _menu: PanelContainer
var _attack_button: Button
var _message: Label
var _advance_requested := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_status()
	_build_bottom()
	hide_menu()


func set_hero(c: Combatant) -> void:
	_name_label.text = c.display_name
	update_hp(c.hp, c.max_hp)


func update_hp(hp: int, max_hp: int) -> void:
	_hp_label.text = "PV %d / %d" % [hp, max_hp]
	_hp_bar.max_value = max_hp
	_hp_bar.value = hp


func show_menu() -> void:
	_menu.show()
	_attack_button.grab_focus()


func hide_menu() -> void:
	_menu.hide()


func show_message(text: String) -> void:
	_message.text = text
	_message.visible_characters = 0
	_advance_requested = false
	var total := _message.get_total_character_count()
	var shown := 0.0
	while _message.visible_characters < total and not _advance_requested:
		await get_tree().process_frame
		shown += get_process_delta_time() / CHAR_TIME
		_message.visible_characters = mini(total, int(shown))
	_message.visible_characters = -1
	_advance_requested = false
	var waited := 0.0
	while waited < AUTO_ADVANCE and not _advance_requested:
		await get_tree().process_frame
		waited += get_process_delta_time()
	_advance_requested = false


## Shared look of every window: dark panel with a white rounded border.
static func make_window() -> PanelContainer:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.12, 0.9)
	style.border_color = Color.WHITE
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(16)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel


func _unhandled_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	var click := mouse != null and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT
	if click or event.is_action_pressed("ui_accept"):
		_advance_requested = true


func _build_status() -> void:
	var panel := make_window()
	panel.position = Vector2(24, 24)
	panel.custom_minimum_size = Vector2(240, 0)
	add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	_name_label = _label()
	box.add_child(_name_label)
	_hp_label = _label()
	box.add_child(_hp_label)
	_hp_bar = ProgressBar.new()
	_hp_bar.show_percentage = false
	_hp_bar.custom_minimum_size = Vector2(0, 10)
	box.add_child(_hp_bar)


func _build_bottom() -> void:
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	row.offset_left = 24
	row.offset_right = -24
	row.offset_top = -170
	row.offset_bottom = -24
	row.add_theme_constant_override("separation", 16)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)

	_menu = make_window()
	_menu.custom_minimum_size = Vector2(200, 0)
	row.add_child(_menu)
	var commands := VBoxContainer.new()
	_menu.add_child(commands)
	_attack_button = Button.new()
	_attack_button.text = "Atacar"
	_attack_button.flat = true
	_attack_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_attack_button.add_theme_font_size_override("font_size", FONT_SIZE)
	_attack_button.pressed.connect(_on_attack_pressed)
	commands.add_child(_attack_button)

	var message_window := make_window()
	message_window.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(message_window)
	_message = _label()
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	message_window.add_child(_message)


func _label() -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", Color.WHITE)
	return label


func _on_attack_pressed() -> void:
	hide_menu()
	command_chosen.emit(BattleEngine.CMD_ATTACK)
```

- [ ] **Step 2: Crear `scenes/ui/battle_hud.tscn`**

```ini
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ui/battle_hud.gd" id="1_hud"]

[node name="BattleHud" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
script = ExtResource("1_hud")
```

- [ ] **Step 3: Crear `scripts/ui/battle_result.gd`**

```gdscript
class_name BattleResult extends Control
## End-of-battle overlay: victory or defeat text and a "Luchar otra vez" button.
## Starts hidden; the button hides it and emits retry_requested.

signal retry_requested

var _title: Label
var _detail: Label
var _retry: Button


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
	_retry = Button.new()
	_retry.text = "Luchar otra vez"
	_retry.add_theme_font_size_override("font_size", 24)
	_retry.pressed.connect(_on_retry_pressed)
	box.add_child(_retry)
	hide()


func show_victory(exp_gained: int, total_exp: int) -> void:
	_title.text = "¡Victoria!"
	_detail.text = "+%d EXP  (total: %d)" % [exp_gained, total_exp]
	_open()


func show_defeat() -> void:
	_title.text = "Has sido derrotado"
	_detail.text = "Inténtalo de nuevo."
	_open()


func _open() -> void:
	show()
	_retry.grab_focus()


func _label(size: int) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color.WHITE)
	return label


func _on_retry_pressed() -> void:
	hide()
	retry_requested.emit()
```

- [ ] **Step 4: Crear `scenes/ui/battle_result.tscn`**

```ini
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ui/battle_result.gd" id="1_result"]

[node name="BattleResult" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1_result")
```

- [ ] **Step 5: Importar y validar**

Run: `.\tools\godot.cmd --headless --path . --import`
Run: `.\tools\godot.cmd --headless --path . --check-only --script res://scripts/ui/battle_hud.gd`
Run: `.\tools\godot.cmd --headless --path . --check-only --script res://scripts/ui/battle_result.gd`
Expected: sin `ERROR` / `SCRIPT ERROR` / `Parse Error`.

- [ ] **Step 6: Commit**

```powershell
git add scripts/ui scenes/ui
git commit -m "Add Dragon Quest style battle HUD and result overlay

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Escenario, escena de combate y verificación jugando

**Files:**
- Create: `scripts/battle/battle_stage.gd`, `scripts/battle/battle_scene.gd`, `scenes/battle/battle_scene.tscn`
- Modify: `project.godot` (añadir `run/main_scene`)

**Interfaces:**
- Consumes: `Combatant`, `BattleEvent`, `BattleEngine` (Task 2); `BattleActor` (Task 3); `BattleHud`, `BattleResult` (Task 4).
- Produces: `class_name BattleStage extends RefCounted` con `static build(root: Node3D)`; escena principal jugable; argumento de línea de comandos `-- --autoplay`.

- [ ] **Step 1: Crear `scripts/battle/battle_stage.gd`**

```gdscript
class_name BattleStage extends RefCounted
## Builds the battle backdrop from primitives: sky, warm sun, fog, grass field,
## dirt path, rocks and distant hills.

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
	_add_environment(root)
	_add_sun(root)
	var ground := PlaneMesh.new()
	ground.size = Vector2(160, 160)
	_add_mesh(root, ground, GRASS, Vector3.ZERO)
	var path := PlaneMesh.new()
	path.size = Vector2(2.6, 30)
	_add_mesh(root, path, DIRT, Vector3(-0.2, 0.01, -0.3), Vector3.ONE, Vector3(0, -21, 0))
	for rock in ROCKS:
		_add_mesh(root, _unit_sphere(), ROCK, rock[0], rock[1])
	for hill in HILLS:
		_add_mesh(root, _unit_sphere(), HILL, hill[0], hill[1])


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


static func _add_mesh(root: Node3D, mesh: Mesh, color: Color, pos: Vector3, \
		scl := Vector3.ONE, rot_deg := Vector3.ZERO) -> void:
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


static func _unit_sphere() -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	return mesh
```

- [ ] **Step 2: Crear `scripts/battle/battle_scene.gd`**

```gdscript
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
	create_tween().tween_property(_camera, "global_position", goal, 0.25) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _reset_camera() -> void:
	create_tween().tween_property(_camera, "global_position", _camera_home, 0.3) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _shake_camera() -> void:
	var t := create_tween()
	for i in 6:
		t.tween_property(_camera, "h_offset", randf_range(-0.12, 0.12), 0.04)
		t.parallel().tween_property(_camera, "v_offset", randf_range(-0.08, 0.08), 0.04)
	t.tween_property(_camera, "h_offset", 0.0, 0.04)
	t.parallel().tween_property(_camera, "v_offset", 0.0, 0.04)


func _actor(side: String) -> BattleActor:
	return _hero_actor if side == BattleEvent.HERO else _enemy_actor


func _fighter(side: String) -> Combatant:
	return hero if side == BattleEvent.HERO else enemy
```

- [ ] **Step 3: Crear `scenes/battle/battle_scene.tscn`**

```ini
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/battle/battle_scene.gd" id="1_scene"]

[node name="BattleScene" type="Node3D"]
script = ExtResource("1_scene")
```

- [ ] **Step 4: Fijar la escena principal en `project.godot`** (sección `[application]`, tras `config/version`)

```ini
run/main_scene="res://scenes/battle/battle_scene.tscn"
```

- [ ] **Step 5: Importar y validar**

Run: `.\tools\godot.cmd --headless --path . --import`
Run: `.\tools\godot.cmd --headless --path . --check-only --script res://scripts/battle/battle_stage.gd`
Run: `.\tools\godot.cmd --headless --path . --check-only --script res://scripts/battle/battle_scene.gd`
Expected: sin `ERROR` / `SCRIPT ERROR` / `Parse Error`.

- [ ] **Step 6: Ejecutar en autoplay y revisar la salida**

Run: `.\tools\godot.cmd --path . --quit-after 1200 -- --autoplay`
Expected: se abre la ventana, el héroe ataca solo, el combate termina, aparece el resultado y se reinicia; en la salida de consola no hay `ERROR`, `SCRIPT ERROR` ni `WARNING` nuevos. Si los hay, corregirlos antes de seguir.

- [ ] **Step 7: Grabar fotogramas y revisarlos visualmente**

```powershell
$frames = "$env:TEMP\rpg-turnos-frames"
Remove-Item -Recurse -Force $frames -ErrorAction SilentlyContinue
New-Item -ItemType Directory $frames | Out-Null
.\tools\godot.cmd --path . --write-movie "$frames\f.png" --fixed-fps 10 --quit-after 300 -- --autoplay
```

Abrir con Read varios fotogramas repartidos (p. ej. `f00000005.png`, `f00000030.png`, `f00000060.png`, `f00000100.png`, `f00000150.png`, `f00000220.png`) y comprobar:
- Héroe de espaldas en primer plano a la izquierda; slime enfrente, algo a la derecha del centro; ambos se miran.
- Cielo azul, hierba verde, camino de tierra entre ambos, rocas y colinas con niebla al fondo; sombras visibles.
- Panel de PV arriba a la izquierda; ventana de mensajes abajo con texto en español legible.
- Números de daño flotando; el slime desaparece al morir; aparece "¡Victoria!" con la EXP.

Si algo se ve mal (personaje fuera de cuadro, UI solapada, escena oscura), ajustar constantes (`HERO_POS`, `ENEMY_POS`, `CAMERA_POS`, luz) y repetir este paso.

- [ ] **Step 8: Prueba manual del usuario**

Pedir al usuario que ejecute `.\tools\godot.cmd --path .` y juegue un par de combates con el ratón y con Enter/Espacio (incluido "Luchar otra vez"). Recoger sus comentarios antes de cerrar la tarea.

- [ ] **Step 9: Commit**

```powershell
git add project.godot scripts/battle scenes/battle
git commit -m "Add the playable 3D battle scene with stage, camera and autoplay

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: Documentación y merge a develop

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Añadir la sección de layout a `CLAUDE.md`** (después de "Project")

```markdown
## Layout

- `scenes/battle/battle_scene.tscn` + `scripts/battle/battle_scene.gd` — main scene (`run/main_scene`). Builds everything in `_ready()`: stage (`BattleStage.build`), hero and slime `BattleActor`s facing each other, a diagonal third-person `Camera3D`, and a `CanvasLayer` with `BattleHud` and `BattleResult`. Flow: HUD `command_chosen` → `BattleEngine.resolve_round()` → `_play_event()` for each event (messages, actor animations, camera focus/shake) → menu again, or result overlay. Starting a battle duplicates `data/hero.tres` / `data/slime.tres` and carries the hero's `experience` over. `-- --autoplay` picks "Atacar" by itself and restarts after each battle.
- `scripts/battle/battle_engine.gd` (`BattleEngine`, `RefCounted`) — pure round rules: initiative `speed × randf_range(0.5, 1.5)`, 5 % miss, 1/16 crit (×1.5, ignores DEF), damage `max(1, ATK − DEF/2) × randf_range(0.875, 1.125)`. Returns `Array[Dictionary]` events built by `BattleEvent` (`scripts/battle/battle_event.gd`); `state` is `ONGOING`, `WON` or `LOST`. Never touches nodes.
- `scripts/battle/combatant.gd` (`Combatant`, `Resource`) — fighter stats; data in `data/hero.tres`, `data/slime.tres`.
- `scenes/battle/battle_actor.tscn` + `scripts/battle/battle_actor.gd` (`BattleActor`) — primitive-mesh fighter (`look`: `HERO` / `SLIME`), faces -Z; awaitable tweens `play_attack`, `play_hit` (flash + floating `Label3D` number), `play_dodge`, `play_defeat`; `reset()`.
- `scripts/battle/battle_stage.gd` (`BattleStage`) — static backdrop builder: procedural sky, ACES tonemap, SSAO, glow, fog, warm sun with shadows, grass, dirt path, rocks, hills.
- `scenes/ui/battle_hud.tscn` + `scripts/ui/battle_hud.gd` (`BattleHud`) — hero status, "Atacar" menu, typed message window; `await show_message(text)` returns on click / Enter / Space or after auto-advance; `static make_window()` is the shared window style.
- `scenes/ui/battle_result.tscn` + `scripts/ui/battle_result.gd` (`BattleResult`) — victory/defeat overlay with "Luchar otra vez" (`retry_requested`).
- `docs/boost/specs/`, `docs/boost/plans/` — design specs and implementation plans.

UI and stage nodes are created in code; the `.tscn` files only hold the root node and its script.
```

- [ ] **Step 2: Commit**

```powershell
git add CLAUDE.md
git commit -m "Document the battle prototype layout in CLAUDE.md

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

- [ ] **Step 3: Merge a develop**

```powershell
git checkout develop
git merge --no-ff feature/combate-prototipo -m "Merge branch 'feature/combate-prototipo' into develop

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
git branch -d feature/combate-prototipo
git log --oneline --graph -10
```

Expected: `develop` contiene el merge; la rama feature queda borrada (no hay remoto, así que no hay que borrarla en origin).
