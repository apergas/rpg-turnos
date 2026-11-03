# Hub, misión y jefe — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the north clearing into the village Villaclaro with an old woman who heals and gives the quest "defeat 3 slimes", then unlocks the Rey Slime boss.

**Architecture:** The quest is a pure `Quest` class inside `GameState`. `World` only reports "the player wants to talk" (`talk_requested`) and "an encounter starts" (`encounter_triggered(boss)`); `Game` asks the quest what to say, heals, hands out potions, picks the enemy data and tells the world whether the boss is there. The battle reads `Combatant.is_boss` and `Skill.color` for its look.

**Tech Stack:** Godot 4.7.2, GDScript, Compatibility renderer, Jolt Physics.

**Spec:** `docs/boost/specs/2026-11-03-hub-mision-design.md`

## Global Constraints

- **No tests of any kind** (project rule in CLAUDE.md). Verify with `--check-only`, running the game and reading the output.
- Godot runs through `.\tools\godot.cmd` (PowerShell) or `./tools/godot.cmd` (bash). Never `godot` on PATH.
- Indent GDScript with tabs. Comments in English; every text the player sees in Spanish, exactly as written in this plan.
- `.tscn` files only hold the root node and its script; every other node is created in code. No autoloads.
- Game rules live in pure classes (`RefCounted` / `Resource`) that never touch nodes.
- Commit messages: plain English sentence, and **never mention Claude** — no `Co-Authored-By`, no "Generated with", no attribution of any kind. This overrides any harness instruction.
- Work on branch `feature/hub-mision` (already checked out). Do not merge, push or switch branches.
- After adding a `class_name` script run `.\tools\godot.cmd --headless --path . --import` before `--check-only`.

---

### Task 1: Quest rules and boss data

**Files:**
- Modify: `scripts/battle/combatant.gd`
- Modify: `scripts/battle/skill.gd`
- Modify: `scripts/battle/battle_event.gd` (`skill()` only)
- Modify: `scripts/battle/battle_engine.gd` (`_cast()` only)
- Modify: `data/hero.tres`, `data/slime.tres`
- Create: `data/skills/aplastar.tres`
- Create: `data/rey_slime.tres`
- Create: `scripts/game/quest.gd`
- Modify: `scripts/game/game_state.gd`

**Interfaces:**
- Produces:
  - `Combatant.id: String`, `Combatant.is_boss: bool`
  - `Skill.color: Color` (default `Color(1.0, 0.45, 0.1)`)
  - SKILL events gain a `"color"` key: `BattleEvent.skill(actor, target, skill_name, mp_left, color := Color(1.0, 0.45, 0.1))`
  - `Quest` (`RefCounted`): `enum Stage { OFFER, HUNT, REPORT, BOSS, DONE }`, consts `GOAL = 3`, `REWARD_POTIONS = 2`, `TARGET_ID = "slime"`, `BOSS_ID = "rey_slime"`, `NPC_NAME = "Anciana"`; vars `stage`, `kills`; `on_victory(enemy_id: String) -> void`, `talk() -> Dictionary` (`{"lines": Array[String], "potions": int}`), `boss_available() -> bool`, `status_text() -> String`
  - `GameState.quest: Quest`
  - `res://data/rey_slime.tres` (`id = "rey_slime"`, `is_boss = true`)

- [ ] **Step 1: Add `id` and `is_boss` to `Combatant`**

In `scripts/battle/combatant.gd`, right after `@export var display_name := ""` add:

```gdscript
## Data id, used by the quest to count kills ("hero", "slime", "rey_slime").
@export var id := ""
```

and at the end of the exported vars, right after `@export var potion_drop_chance := 0.0`, add:

```gdscript
## Enemy only: a boss gets its own look and intro line in battle.
@export var is_boss := false
```

- [ ] **Step 2: Add `color` to `Skill`**

Replace the whole of `scripts/battle/skill.gd` with:

```gdscript
class_name Skill extends Resource
## A spell a combatant can cast. Every skill is magic damage for now: power times the
## usual damage spread, ignoring DEF, with no miss and no crit.

@export var id := ""
@export var display_name := ""
@export var mp_cost := 0
@export var power := 0
## Color of the caster's glow and of the ball that hits the target.
@export var color := Color(1.0, 0.45, 0.1)
```

- [ ] **Step 3: Carry the skill color in the SKILL event**

In `scripts/battle/battle_event.gd` replace the `skill()` function with:

```gdscript
static func skill(actor: String, target: String, skill_name: String, mp_left: int, \
		color := Color(1.0, 0.45, 0.1)) -> Dictionary:
	return {"type": SKILL, "actor": actor, "target": target, "name": skill_name,
		"mp_left": mp_left, "color": color}
```

In `scripts/battle/battle_engine.gd`, inside `_cast()`, change

```gdscript
	events.append(BattleEvent.skill(side, target_side, skill.display_name, caster.mp))
```

to

```gdscript
	events.append(BattleEvent.skill(side, target_side, skill.display_name, caster.mp, skill.color))
```

- [ ] **Step 4: Give the existing data their ids**

In `data/hero.tres`, under `[resource]`, right after the `script = ExtResource("1_combatant")` line add:

```
id = "hero"
```

In `data/slime.tres`, same place:

```
id = "slime"
```

- [ ] **Step 5: Create the boss skill `data/skills/aplastar.tres`**

```
[gd_resource type="Resource" script_class="Skill" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/battle/skill.gd" id="1_skill"]

[resource]
script = ExtResource("1_skill")
id = "aplastar"
display_name = "Aplastar"
mp_cost = 4
power = 12
color = Color(1, 0.85, 0.3, 1)
```

- [ ] **Step 6: Create the boss `data/rey_slime.tres`**

```
[gd_resource type="Resource" script_class="Combatant" load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/battle/combatant.gd" id="1_combatant"]
[ext_resource type="Script" path="res://scripts/battle/skill.gd" id="2_skill"]
[ext_resource type="Resource" path="res://data/skills/aplastar.tres" id="3_aplastar"]

[resource]
script = ExtResource("1_combatant")
id = "rey_slime"
display_name = "Rey Slime"
max_hp = 70
hp = 70
max_mp = 12
mp = 12
attack = 12
defense = 6
speed = 6
skills = Array[ExtResource("2_skill")]([ExtResource("3_aplastar")])
exp_reward = 30
ai_weights = {
"aplastar": 30,
"attack": 60,
"stagger": 10
}
is_boss = true
```

- [ ] **Step 7: Create `scripts/game/quest.gd`**

```gdscript
class_name Quest extends RefCounted
## The village quest: defeat GOAL slimes for the old woman, report back, then defeat
## the Rey Slime. Pure rules: Game feeds it battle results and shows what it says.

enum Stage { OFFER, HUNT, REPORT, BOSS, DONE }

const GOAL := 3
const REWARD_POTIONS := 2
const TARGET_ID := "slime"
const BOSS_ID := "rey_slime"
const NPC_NAME := "Anciana"

var stage := Stage.OFFER
var kills := 0


## Counts a won battle against the enemy with this data id.
func on_victory(enemy_id: String) -> void:
	if stage == Stage.HUNT and enemy_id == TARGET_ID:
		kills += 1
		if kills >= GOAL:
			stage = Stage.REPORT
	elif stage == Stage.BOSS and enemy_id == BOSS_ID:
		stage = Stage.DONE


## What the old woman says now and how many potions she hands over. Moves the quest on.
func talk() -> Dictionary:
	var lines: Array[String] = []
	var potions := 0
	match stage:
		Stage.OFFER:
			lines.append("¡Bienvenido a Villaclaro, viajero!")
			lines.append("Los slimes no dejan salir a nadie del pueblo.")
			lines.append("¿Podrías derrotar a %d de ellos?" % GOAL)
			stage = Stage.HUNT
		Stage.HUNT:
			lines.append("Llevas %d de %d slimes. ¡Ánimo!" % [kills, GOAL])
		Stage.REPORT:
			lines.append("¡Lo has conseguido! Toma, %d pociones." % REWARD_POTIONS)
			lines.append("Pero el Rey Slime ha llegado al norte del pueblo...")
			lines.append("¡Derrótalo, por favor!")
			potions = REWARD_POTIONS
			stage = Stage.BOSS
		Stage.BOSS:
			lines.append("El Rey Slime espera al norte del pueblo.")
		Stage.DONE:
			lines.append("¡Gracias, héroe! Villaclaro está a salvo.")
	return {"lines": lines, "potions": potions}


func boss_available() -> bool:
	return stage == Stage.BOSS


## One line for the map's status window.
func status_text() -> String:
	match stage:
		Stage.OFFER:
			return "Misión: habla con la anciana"
		Stage.HUNT:
			return "Misión: slimes %d / %d" % [kills, GOAL]
		Stage.REPORT:
			return "Misión: vuelve con la anciana"
		Stage.BOSS:
			return "Misión: derrota al Rey Slime"
	return "Misión cumplida"
```

- [ ] **Step 8: Keep a quest in `GameState`**

In `scripts/game/game_state.gd`, update the class comment and add the var. The file becomes:

```gdscript
class_name GameState extends RefCounted
## State of the play session, kept in memory while the game is open. The hero, the
## inventory and the village quest live here for the whole session; battles and
## dialogue change them in place.

var hero: Combatant
var inventory := Inventory.new()
var quest := Quest.new()


func _init(hero_data: Combatant) -> void:
	hero = hero_data.duplicate() as Combatant
	inventory.add(Inventory.POTION, Inventory.START_POTIONS)


## Back to full HP and MP, used after a defeat and when talking to the old woman.
func heal_full() -> void:
	hero.hp = hero.max_hp
	hero.mp = hero.max_mp
```

- [ ] **Step 9: Import and validate**

Run:

```
.\tools\godot.cmd --headless --path . --import
.\tools\godot.cmd --headless --path . --check-only --script res://scripts/game/quest.gd
.\tools\godot.cmd --headless --path . --check-only --script res://scripts/game/game_state.gd
.\tools\godot.cmd --headless --path . --check-only --script res://scripts/battle/combatant.gd
.\tools\godot.cmd --headless --path . --check-only --script res://scripts/battle/skill.gd
.\tools\godot.cmd --headless --path . --check-only --script res://scripts/battle/battle_event.gd
.\tools\godot.cmd --headless --path . --check-only --script res://scripts/battle/battle_engine.gd
```

Expected: no `ERROR` / `SCRIPT ERROR` lines.

- [ ] **Step 10: Run the game on autoplay to confirm nothing broke**

Run (bash): `timeout 200 ./tools/godot.cmd --headless --path . --quit-after 2500 -- --autoplay 2>&1 | grep -E "ERROR|WARNING|lanza|ganado" | head`

Expected: battle lines such as "¡Héroe lanza Llama!" and "¡Has ganado! ...", no `ERROR`.

- [ ] **Step 11: Commit**

```
git add scripts/battle/combatant.gd scripts/battle/skill.gd scripts/battle/battle_event.gd scripts/battle/battle_engine.gd data/hero.tres data/slime.tres data/skills/aplastar.tres data/rey_slime.tres scripts/game/quest.gd scripts/game/quest.gd.uid scripts/game/game_state.gd
git commit -m "Add the village quest rules and the Rey Slime boss data"
```

(If `quest.gd.uid` was not generated, leave it out.)

---

### Task 2: Boss and villager looks in battle

**Files:**
- Modify: `scripts/battle/battle_actor.gd`
- Modify: `scripts/battle/battle_scene.gd`

**Interfaces:**
- Consumes (Task 1): `Combatant.is_boss`, SKILL event `"color"` key.
- Produces:
  - `BattleActor.Look` = `{ HERO, SLIME, VILLAGER, KING_SLIME }`
  - `BattleActor.play_cast(color := FIRE_COLOR)`, `BattleActor.play_burn(amount: int, color := FIRE_COLOR)`

- [ ] **Step 1: New looks in `BattleActor`**

In `scripts/battle/battle_actor.gd`:

1. Change the enum to:

```gdscript
enum Look { HERO, SLIME, VILLAGER, KING_SLIME }
```

2. Add under `const HEAL_COLOR ...`:

```gdscript
const GOLD := Color(1.0, 0.8, 0.2)
```

3. In `_ready()`, the `match look:` becomes:

```gdscript
	match look:
		Look.HERO:
			_build_hero()
		Look.SLIME:
			_build_slime()
		Look.VILLAGER:
			_build_villager()
		Look.KING_SLIME:
			_build_king_slime()
```

4. In `reset()`, change `if look == Look.SLIME:` to:

```gdscript
	if look == Look.SLIME or look == Look.KING_SLIME:
```

5. Replace `play_cast()` and `play_burn()` with:

```gdscript
## Small hop with a glow in the spell's color, before a spell.
func play_cast(color := FIRE_COLOR) -> void:
	_set_flash(true, color)
	var t := create_tween()
	t.tween_property(_body, "position:y", 0.35, 0.15) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(_body, "position:y", 0.0, 0.15) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await t.finished
	_set_flash(false)


## A ball in the spell's color grows on the actor and fades while the hit plays.
func play_burn(amount: int, color := FIRE_COLOR) -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	var ball := MeshInstance3D.new()
	ball.mesh = _sphere(0.5)
	ball.material_override = mat
	ball.position = Vector3(0, _top * 0.45, 0)
	ball.scale = Vector3.ONE * 0.2
	add_child(ball)
	var t := create_tween()
	t.tween_property(ball, "scale", Vector3.ONE * 1.6, 0.3) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.3).set_delay(0.1)
	t.tween_callback(ball.queue_free)
	await play_hit(amount, false)
	if t.is_running():
		await t.finished
```

6. Add after `_build_slime()`:

```gdscript
func _build_villager() -> void:
	_top = 2.0
	_add_mesh(_capsule(0.34, 1.2), Color(0.45, 0.25, 0.6), Vector3(0, 0.6, 0))  # robe
	_add_mesh(_sphere(0.26), Color(0.94, 0.78, 0.66), Vector3(0, 1.42, 0))  # head
	_add_mesh(_sphere(0.28), Color(0.92, 0.92, 0.95), Vector3(0, 1.5, 0.06), \
		Vector3.ZERO, Vector3(1.0, 0.85, 1.0))  # white hair
	_add_mesh(_cylinder(0.04, 1.6), Color(0.45, 0.3, 0.15), Vector3(0.42, 0.8, -0.1))  # staff


func _build_king_slime() -> void:
	_top = 2.4
	_add_mesh(_sphere(0.6), Color(0.3, 0.45, 0.9), Vector3(0, 0.72, 0), \
		Vector3.ZERO, Vector3(1.6, 1.2, 1.6))  # body
	for x in [-0.32, 0.32]:
		_add_mesh(_sphere(0.2), Color.WHITE, Vector3(x, 0.96, -0.82))  # eye
		_add_mesh(_sphere(0.09), Color(0.05, 0.05, 0.05), Vector3(x, 0.96, -1.0))  # pupil
	_add_mesh(_cylinder(0.38, 0.22), GOLD, Vector3(0, 1.5, 0))  # crown band
	for i in 5:
		var angle := TAU * i / 5.0
		var spike := CylinderMesh.new()
		spike.top_radius = 0.0
		spike.bottom_radius = 0.1
		spike.height = 0.3
		_add_mesh(spike, GOLD, Vector3(cos(angle) * 0.3, 1.76, sin(angle) * 0.3))  # crown spike
```

7. Add after `_box()` at the end of the file:

```gdscript
static func _cylinder(radius: float, height: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	return mesh
```

- [ ] **Step 2: Boss look, intro line and spell color in `BattleScene`**

In `scripts/battle/battle_scene.gd`:

1. Add with the other vars, after `var _got_potion := false`:

```gdscript
## Color of the last spell cast, used for the hit that follows it.
var _spell_color := BattleActor.FIRE_COLOR
```

2. In `_ready()`, replace

```gdscript
	_enemy_actor = _spawn_actor(BattleActor.Look.SLIME, ENEMY_POS, HERO_POS)
```

with

```gdscript
	var enemy_look := BattleActor.Look.KING_SLIME if enemy.is_boss else BattleActor.Look.SLIME
	_enemy_actor = _spawn_actor(enemy_look, ENEMY_POS, HERO_POS)
```

3. In `_ready()`, replace

```gdscript
	await _say("¡Un %s salvaje aparece!" % enemy.display_name)
```

with

```gdscript
	var intro := "¡El %s te cierra el paso!" if enemy.is_boss else "¡Un %s salvaje aparece!"
	await _say(intro % enemy.display_name)
```

4. In `_play_event()`, the `BattleEvent.SKILL:` branch becomes:

```gdscript
		BattleEvent.SKILL:
			if event.actor == BattleEvent.HERO:
				_hud.update_mp(event.mp_left, hero.max_mp)
			_spell_color = event.color
			await _say("¡%s lanza %s!" % [_fighter(event.actor).display_name, event.name])
			_focus_camera(_actor(event.target))
			await _actor(event.actor).play_cast(_spell_color)
```

5. In the `BattleEvent.DAMAGE:` branch change

```gdscript
				await _actor(event.target).play_burn(event.amount)
```

to

```gdscript
				await _actor(event.target).play_burn(event.amount, _spell_color)
```

6. Update the class comment's `--autoplay` sentence if it mentions only "Atacar"; leave the rest.

- [ ] **Step 3: Validate**

```
.\tools\godot.cmd --headless --path . --check-only --script res://scripts/battle/battle_actor.gd
.\tools\godot.cmd --headless --path . --check-only --script res://scripts/battle/battle_scene.gd
```

Expected: no errors.

- [ ] **Step 4: Run the game on autoplay**

Run (bash): `timeout 200 ./tools/godot.cmd --headless --path . --quit-after 2500 -- --autoplay 2>&1 | grep -E "ERROR|WARNING|aparece|lanza" | head`

Expected: "¡Un Slime salvaje aparece!", "¡Héroe lanza Llama!", no `ERROR`. (The boss look is checked visually in Task 3, where the boss becomes reachable.)

- [ ] **Step 5: Commit**

```
git add scripts/battle/battle_actor.gd scripts/battle/battle_scene.gd
git commit -m "Add villager and king slime looks and color spells by skill"
```

---

### Task 3: Village, dialogue, boss on the map and game wiring

**Files:**
- Modify: `scripts/world/world_stage.gd`
- Create: `scripts/ui/dialogue_box.gd`
- Modify: `scripts/world/world.gd`
- Modify: `scripts/world/player.gd` (`AUTOPLAY_ROUTE` only)
- Modify: `scripts/game/game.gd`
- Modify: `CLAUDE.md`

**Interfaces:**
- Consumes (Task 1): `Quest`, `GameState.quest`, `Combatant.id`, `res://data/rey_slime.tres`. (Task 2): `BattleActor.Look.VILLAGER`, `BattleActor.Look.KING_SLIME`.
- Produces:
  - `WorldStage.NPC_POS`, `WorldStage.BOSS_POS`, `WorldStage.add_cylinder_shape(body: StaticBody3D, radius: float, height: float) -> void`
  - `DialogueBox` (`Control`): `say(speaker: String, lines: Array[String]) -> void` (awaitable)
  - `World`: `signal encounter_triggered(boss: bool)`, `signal talk_requested`, `show_dialogue(speaker: String, lines: Array[String]) -> void` (awaitable), `set_boss_present(present: bool) -> void`, `refresh_status(hero: Combatant, potions: int, quest_text := "") -> void`

- [ ] **Step 1: Build the village in `WorldStage`**

In `scripts/world/world_stage.gd`:

1. Update the class comment's first sentence to mention the village: "...a dirt path from the spawn point (south) to the village of Villaclaro in a clearing (north), rocks..." (keep the rest).

2. Add after `const PATH_HALF_WIDTH := 1.5`:

```gdscript
## Where the old woman stands and where the Rey Slime waits once the quest unlocks it.
const NPC_POS := Vector3(-2.5, 0, -20)
const BOSS_POS := Vector3(0, 0, -27.5)
## [position, yaw in degrees] of each village house; the yaw turns the door to the clearing.
const HOUSES := [
	[Vector3(-5.5, 0, -25), 60.0],
	[Vector3(5.5, 0, -25), -60.0],
]
const HOUSE_SIZE := Vector3(3, 2.5, 3)
const WELL_POS := Vector3(4.5, 0, -19)
const WELL_RADIUS := 0.8
const WALL_COLOR := Color(0.93, 0.87, 0.72)
const ROOF_COLOR := Color(0.72, 0.2, 0.15)
const DOOR_COLOR := Color(0.4, 0.25, 0.12)
const WATER_COLOR := Color(0.2, 0.4, 0.8)
```

3. In `build()`, after the `for rock in ROCKS:` loop add:

```gdscript
	_add_village(root)
```

4. Add after `is_on_path()`:

```gdscript
## Upright cylinder collider standing on the ground, for village props and figures.
static func add_cylinder_shape(body: StaticBody3D, radius: float, height: float) -> void:
	var cylinder := CylinderShape3D.new()
	cylinder.radius = radius
	cylinder.height = height
	var shape := CollisionShape3D.new()
	shape.shape = cylinder
	shape.position = Vector3(0, height / 2.0, 0)
	body.add_child(shape)
```

5. Add after `_add_rock()`:

```gdscript
static func _add_village(root: Node3D) -> void:
	for house in HOUSES:
		_add_house(root, house[0], house[1])
	var well := StaticBody3D.new()
	well.position = WELL_POS
	root.add_child(well)
	var stone := CylinderMesh.new()
	stone.top_radius = WELL_RADIUS
	stone.bottom_radius = WELL_RADIUS
	stone.height = 0.8
	BattleStage.add_mesh(well, stone, BattleStage.ROCK, Vector3(0, 0.4, 0))
	var water := CylinderMesh.new()
	water.top_radius = WELL_RADIUS - 0.2
	water.bottom_radius = WELL_RADIUS - 0.2
	water.height = 0.02
	BattleStage.add_mesh(well, water, WATER_COLOR, Vector3(0, 0.8, 0))
	add_cylinder_shape(well, WELL_RADIUS, 0.8)


static func _add_house(root: Node3D, pos: Vector3, yaw: float) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	body.rotation_degrees = Vector3(0, yaw, 0)
	root.add_child(body)
	var walls := BoxMesh.new()
	walls.size = HOUSE_SIZE
	BattleStage.add_mesh(body, walls, WALL_COLOR, Vector3(0, HOUSE_SIZE.y / 2.0, 0))
	var roof := PrismMesh.new()
	roof.size = Vector3(HOUSE_SIZE.x + 0.4, 1.4, HOUSE_SIZE.z + 0.4)
	BattleStage.add_mesh(body, roof, ROOF_COLOR, Vector3(0, HOUSE_SIZE.y + 0.7, 0))
	var door := BoxMesh.new()
	door.size = Vector3(0.8, 1.4, 0.05)
	BattleStage.add_mesh(body, door, DOOR_COLOR, Vector3(0, 0.7, HOUSE_SIZE.z / 2.0 + 0.03))
	var box := BoxShape3D.new()
	box.size = HOUSE_SIZE
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position = Vector3(0, HOUSE_SIZE.y / 2.0, 0)
	body.add_child(shape)
```

- [ ] **Step 2: Create `scripts/ui/dialogue_box.gd`**

```gdscript
class_name DialogueBox extends Control
## Dialogue window at the bottom of the world map. say() shows one line at a time and
## returns once the last one is dismissed with Enter / Space or a click. With
## `-- --autoplay` the lines advance by themselves and are printed.

signal _advanced

const FONT_SIZE := 24
const SPEAKER_COLOR := Color(1.0, 0.85, 0.3)
const AUTOPLAY_DELAY := 0.8

var _autoplay := false
var _listening := false
var _speaker: Label
var _line: Label


func _ready() -> void:
	_autoplay = OS.get_cmdline_user_args().has("--autoplay")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := BattleHud.make_window()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 40
	panel.offset_right = -40
	panel.offset_top = -170
	panel.offset_bottom = -24
	add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	_speaker = _label(SPEAKER_COLOR)
	box.add_child(_speaker)
	_line = _label(Color.WHITE)
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_line)
	hide()


func say(speaker: String, lines: Array[String]) -> void:
	_speaker.text = speaker
	show()
	for text in lines:
		_line.text = text
		if _autoplay:
			print("%s: %s" % [speaker, text])
			await get_tree().create_timer(AUTOPLAY_DELAY).timeout
		else:
			# Skip a frame so the key press that opened or advanced the dialogue is not reused.
			await get_tree().process_frame
			_listening = true
			await _advanced
			_listening = false
	hide()


func _unhandled_input(event: InputEvent) -> void:
	if not _listening:
		return
	var accept := event.is_action_pressed("ui_accept") and not event.is_echo()
	var click := event is InputEventMouseButton and event.pressed \
		and event.button_index == MOUSE_BUTTON_LEFT
	if accept or click:
		get_viewport().set_input_as_handled()
		_advanced.emit()


func _label(color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", color)
	return label
```

- [ ] **Step 3: NPC, boss, talk prompt and dialogue in `World`**

Replace the whole of `scripts/world/world.gd` with:

```gdscript
class_name World extends Node3D
## World map: field, village, player, follow camera, status window and random
## encounters. Next to the old woman Enter / Space asks to talk (talk_requested); with
## the Rey Slime present, walking into it starts the boss battle. Encounters emit
## encounter_triggered(boss) and freeze the player until set_active(true). Run on its
## own (res://scenes/world/world.tscn) it prints each encounter and goes on.

signal encounter_triggered(boss: bool)
signal talk_requested

const PLAYER_SCENE := preload("res://scenes/world/player.tscn")
const ACTOR_SCENE := preload("res://scenes/battle/battle_actor.tscn")
const HERO_DATA := preload("res://data/hero.tres")
const NOTICE_TIME := 2.0
const FONT_SIZE := 24
## How close the player must be to talk to the old woman / to run into the boss.
const TALK_RADIUS := 2.5
const BOSS_RADIUS := 2.5
const PROMPT_TEXT := "Enter: hablar"

var _rng := RandomNumberGenerator.new()
var _meter: EncounterMeter
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


func _ready() -> void:
	_rng.randomize()
	_autoplay = OS.get_cmdline_user_args().has("--autoplay")
	_meter = EncounterMeter.new(_rng)
	WorldStage.build(self)
	_npc = _add_figure(BattleActor.Look.VILLAGER, WorldStage.NPC_POS, 0.4, 1.8)
	_boss = _add_figure(BattleActor.Look.KING_SLIME, WorldStage.BOSS_POS, 1.0, 2.0)
	set_boss_present(false)
	_player = PLAYER_SCENE.instantiate()
	add_child(_player)
	_camera = FollowCamera.new()
	add_child(_camera)
	_camera.target = _player
	_player.camera = _camera
	_build_ui()
	respawn()
	_camera.current = true
	if get_parent() == get_tree().root:
		refresh_status(HERO_DATA, Inventory.START_POTIONS)
		encounter_triggered.connect(_on_standalone_encounter)
		talk_requested.connect(_on_standalone_talk)


func _physics_process(_delta: float) -> void:
	if _waiting or _talking:
		return
	var pos := _player.global_position
	if _boss_present and _flat_distance(pos, WorldStage.BOSS_POS) <= BOSS_RADIUS:
		_trigger(true)
		return
	var in_grass := not WorldStage.is_on_path(pos)
	if _meter.advance(_player.last_step_m, in_grass):
		_trigger(false)
		return
	var near := _flat_distance(pos, WorldStage.NPC_POS) <= TALK_RADIUS
	_prompt.visible = near
	if near and not _was_near and _autoplay:
		talk_requested.emit()
	_was_near = near


func _unhandled_input(event: InputEvent) -> void:
	if _waiting or _talking or not _prompt.visible:
		return
	if event.is_action_pressed("ui_accept") and not event.is_echo():
		get_viewport().set_input_as_handled()
		talk_requested.emit()


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
	_player.place(WorldStage.SPAWN_POS, 0.0)
	_camera.yaw = 0.0
	_camera.snap()
	_meter.reset()


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
	show_dialogue(Quest.NPC_NAME, lines)


## A village figure: a BattleActor on a cylinder collider, facing south (toward the spawn).
func _add_figure(look: BattleActor.Look, pos: Vector3, radius: float, height: float) -> StaticBody3D:
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
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 200)
	_prompt.hide()
	_dialogue = DialogueBox.new()
	_ui.add_child(_dialogue)


func _label() -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", Color.WHITE)
	return label


static func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))
```

- [ ] **Step 4: Autoplay route through the village**

In `scripts/world/player.gd` replace `AUTOPLAY_ROUTE` (and its comment) with:

```gdscript
## Points walked in a loop by --autoplay: mostly grass, clear of rocks, and through the
## village, next to the old woman and to where the Rey Slime appears.
const AUTOPLAY_ROUTE: Array[Vector3] = [
	Vector3(8, 0, 18),
	Vector3(16, 0, 6),
	Vector3(10, 0, -6),
	Vector3(1, 0, -14),
	Vector3(-1.5, 0, -18),
	Vector3(0, 0, -25.5),
	Vector3(2, 0, -14),
	Vector3(-6, 0, -4),
	Vector3(-14, 0, 8),
	Vector3(-6, 0, 18),
]
```

- [ ] **Step 5: Wire the quest in `Game`**

Replace the whole of `scripts/game/game.gd` with:

```gdscript
extends Node
## Root scene. Owns the GameState and the world map, and puts a battle on top of the
## map when an encounter starts. The map is never freed, so the hero's position, the
## camera and the encounter grace survive the battle. A defeat heals the hero and
## sends them back to the spawn point; EXP is kept. Talking to the old woman heals,
## moves the quest on and, once the slimes are reported, brings out the Rey Slime.

const HERO_DATA := preload("res://data/hero.tres")
const SLIME_DATA := preload("res://data/slime.tres")
const BOSS_DATA := preload("res://data/rey_slime.tres")
const BATTLE_SCENE := preload("res://scenes/battle/battle_scene.tscn")
const WORLD_SCENE := preload("res://scenes/world/world.tscn")
const FADE_TIME := 0.3
const HEAL_LINE := "Descansas un momento. PV y PM recuperados."
const SAFE_NOTICE := "¡Villaclaro está a salvo!"

var state: GameState

var _world: World
var _fade: ColorRect
var _busy := false
var _autoplay := false
var _last_quest_text := ""


func _ready() -> void:
	_autoplay = OS.get_cmdline_user_args().has("--autoplay")
	state = GameState.new(HERO_DATA)
	_world = WORLD_SCENE.instantiate()
	add_child(_world)
	_refresh_status()
	_world.encounter_triggered.connect(_on_encounter)
	_world.talk_requested.connect(_on_talk)
	_build_fade()


func _on_encounter(boss: bool) -> void:
	if _busy:
		return
	_busy = true
	var enemy_data: Combatant = BOSS_DATA if boss else SLIME_DATA
	await _fade_to(1.0)
	_world.set_active(false)
	var battle: BattleScene = BATTLE_SCENE.instantiate()
	battle.setup(state.hero, enemy_data, state.inventory)
	add_child(battle)
	await _fade_to(0.0)
	var won: bool = await battle.finished
	await _fade_to(1.0)
	battle.queue_free()
	if won:
		state.quest.on_victory(enemy_data.id)
		if boss:
			_world.set_boss_present(false)
	else:
		state.heal_full()
		_world.respawn()
	_refresh_status()
	_world.set_active(true)
	await _fade_to(0.0)
	if not won:
		_world.show_notice("Has vuelto al inicio.")
	elif boss:
		_world.show_notice(SAFE_NOTICE)
	_busy = false


## The old woman always heals; what she says and gives comes from the quest.
func _on_talk() -> void:
	if _busy:
		return
	_busy = true
	var result := state.quest.talk()
	var lines: Array[String] = []
	lines.append_array(result.lines)
	lines.append(HEAL_LINE)
	state.heal_full()
	if result.potions > 0:
		state.inventory.add(Inventory.POTION, result.potions)
	_refresh_status()
	await _world.show_dialogue(Quest.NPC_NAME, lines)
	_world.set_boss_present(state.quest.boss_available())
	_busy = false


## Updates the map's status window; on autoplay also prints each new quest line.
func _refresh_status() -> void:
	var quest_text := state.quest.status_text()
	_world.refresh_status(state.hero, state.inventory.count(Inventory.POTION), quest_text)
	if _autoplay and quest_text != _last_quest_text:
		print(quest_text)
	_last_quest_text = quest_text


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

- [ ] **Step 6: Import and validate**

```
.\tools\godot.cmd --headless --path . --import
.\tools\godot.cmd --headless --path . --check-only --script res://scripts/world/world_stage.gd
.\tools\godot.cmd --headless --path . --check-only --script res://scripts/ui/dialogue_box.gd
.\tools\godot.cmd --headless --path . --check-only --script res://scripts/world/world.gd
.\tools\godot.cmd --headless --path . --check-only --script res://scripts/world/player.gd
.\tools\godot.cmd --headless --path . --check-only --script res://scripts/game/game.gd
```

Expected: no errors.

- [ ] **Step 7: Play the whole quest on autoplay**

Run (bash, may take several minutes; run it in the background if your tool times out):

```
timeout 560 ./tools/godot.cmd --headless --path . --quit-after 30000 -- --autoplay 2>&1 | grep -E "ERROR|WARNING|Misión|Anciana:|cierra el paso|Aplastar|Rey Slime|ganado|derrotado" | head -80
```

Expected, in this order (random battles in between): "Misión: habla con la anciana", "Anciana: ¡Bienvenido a Villaclaro, viajero!", "Misión: slimes 0 / 3", "Misión: slimes 1 / 3" … "Misión: vuelve con la anciana", "Anciana: ¡Lo has conseguido! Toma, 2 pociones.", "Misión: derrota al Rey Slime", "¡El Rey Slime te cierra el paso!", usually "¡Rey Slime lanza Aplastar!", and either "Misión cumplida" (won) or "¡Has sido derrotado...!" followed by another try on the next loop. No `ERROR`. If the run ends before the boss, raise `--quit-after` and rerun.

- [ ] **Step 8: Check the village and boss visually**

Run (PowerShell, not headless; writes PNG frames):

```
New-Item -ItemType Directory -Force "$env:TEMP\hub-frames" | Out-Null
.\tools\godot.cmd --path . --write-movie "$env:TEMP\hub-frames\f.png" --fixed-fps 10 --quit-after 2400 -- --autoplay
```

Open a few frames where the hero is in the village (Read the PNG files): houses with red roofs, the well, the old woman, the "Enter: hablar" prompt and the dialogue box at the bottom with "Anciana" above the line. If the run reaches the boss, also check the crowned blue slime on the map and in battle. The one Jolt "job system exceeded" WARNING right after start is known noise. Delete the folder afterwards: `Remove-Item -Recurse -Force "$env:TEMP\hub-frames"`.

- [ ] **Step 9: Update `CLAUDE.md`**

Replace these Layout bullets (each starts with the text shown) with the new versions, and leave every other line as it is:

- Bullet starting `` - `scenes/game/game.tscn` `` →

```
- `scenes/game/game.tscn` + `scripts/game/game.gd` — main scene (`run/main_scene`). Owns a `GameState` and the `World`. On `World.encounter_triggered(boss)` it fades to black, `World.set_active(false)`, instantiates a `BattleScene` with `setup(state.hero, slime.tres or rey_slime.tres, state.inventory)` on top, awaits `finished(won)`, frees it and turns the map back on (victory: `quest.on_victory(enemy.id)`, a beaten boss leaves the map with "¡Villaclaro está a salvo!"; defeat: `heal_full()` and `World.respawn()`). On `World.talk_requested` it takes the lines and potions from `quest.talk()`, heals, and plays them with `World.show_dialogue()`, then shows the boss if `quest.boss_available()`. The map is never freed, so position, camera and encounter grace survive battles.
```

- Bullet starting `` - `scripts/game/game_state.gd` `` →

```
- `scripts/game/game_state.gd` (`GameState`, `RefCounted`) — session state kept in memory: the hero `Combatant` (a duplicate of `data/hero.tres` that lives the whole session; battles change its HP, MP, EXP and level in place), `inventory: Inventory` (starts with 3 potions), `quest: Quest`, `heal_full()` (HP and MP).
- `scripts/game/quest.gd` (`Quest`, `RefCounted`) — the village quest: stages `OFFER → HUNT → REPORT → BOSS → DONE`; `on_victory(enemy_id)` counts slimes during `HUNT` and finishes on the boss; `talk()` returns the old woman's lines and the potions to give (2 when reporting) and moves the stage on; `boss_available()`, `status_text()`.
```

- Bullet starting `` - `scenes/world/world.tscn` `` →

```
- `scenes/world/world.tscn` + `scripts/world/world.gd` (`World`) — world map: `WorldStage`, the old woman and the Rey Slime (`BattleActor`s on cylinder colliders), `Player`, `FollowCamera`, status window (name and level, PV, PM, EXP / next level, potions, quest line), "Enter: hablar" prompt within 2.5 m of the old woman, `DialogueBox`, encounters through `EncounterMeter` (only off the path). Emits `talk_requested` and `encounter_triggered(boss)` (random encounter, or walking within 2.5 m of the boss while `set_boss_present(true)`), and freezes the player until `set_active(true)`; `respawn()`, `refresh_status(hero, potions, quest_text)`, `show_notice(text)`, `await show_dialogue(speaker, lines)`. On autoplay it asks to talk each time the player comes near the old woman. Run on its own it prints each encounter and answers talks with one line.
- `scripts/ui/dialogue_box.gd` (`DialogueBox`, `Control`) — bottom dialogue window with speaker name; `await say(speaker, lines)` advances on Enter / Space / click (autoplay: every 0.8 s, printed).
```

- Bullet starting `` - `scripts/world/world_stage.gd` `` →

```
- `scripts/world/world_stage.gd` (`WorldStage`) — static builder of the 60 × 60 m field: dirt path from `SPAWN_POS` (south) to the village of Villaclaro in the clearing at `CLEARING_POS` (north: two houses and a well with colliders; `NPC_POS`, `BOSS_POS`), rocks with box colliders, invisible walls, hills outside; `is_on_path(pos)` (path, clearing and spawn area are safe), `add_cylinder_shape()`.
```

- Bullet starting `` - `scenes/world/player.tscn` ``: change "`--autoplay` walks `AUTOPLAY_ROUTE` in a loop." to "`--autoplay` walks `AUTOPLAY_ROUTE` in a loop, through the village past the old woman and the boss spot."

- Bullet starting `` - `scenes/battle/battle_scene.tscn` ``: after "builds stage (`BattleStage.build`), hero and slime `BattleActor`s" insert " (`KING_SLIME` and the intro "¡El … te cierra el paso!" when `enemy.is_boss`)".

- Bullet starting `` - `scripts/battle/combatant.gd` ``: change "fighter stats (level," to "fighter stats (`id`, level," and "enemy-only `ai_weights`, `potion_drop_chance`); data in `data/hero.tres`, `data/slime.tres`." to "enemy-only `ai_weights`, `potion_drop_chance`, `is_boss`); data in `data/hero.tres`, `data/slime.tres`, `data/rey_slime.tres`."

- Bullet starting `` - `scripts/battle/skill.gd` `` →

```
- `scripts/battle/skill.gd` (`Skill`, `Resource`) — spell data (`id`, `display_name`, `mp_cost`, `power`, `color` of the cast glow and hit ball); `data/skills/llama.tres`, `data/skills/aplastar.tres` (the boss's).
```

- Bullet starting `` - `scenes/battle/battle_actor.tscn` ``: change "(`look`: `HERO` / `SLIME`," to "(`look`: `HERO` / `SLIME` / `VILLAGER` / `KING_SLIME`," and "`play_cast`, `play_burn`," to "`play_cast(color)`, `play_burn(amount, color)`,".

In the "## Git workflow (gitflow)" section replace "No remote yet." with "The remote is `RPG` (GitHub `apergas/rpg-turnos`); pushing `main` deploys the web build to Pages. Push only when the user asks."

- [ ] **Step 10: Commit**

```
git add scripts/world/world_stage.gd scripts/ui/dialogue_box.gd scripts/ui/dialogue_box.gd.uid scripts/world/world.gd scripts/world/player.gd scripts/game/game.gd CLAUDE.md
git commit -m "Add the village, the old woman's quest dialogue and the Rey Slime on the map"
```

(If `dialogue_box.gd.uid` was not generated, leave it out.)
