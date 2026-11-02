# Progresión de combate — plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Este proyecto NO lleva tests** (ver `CLAUDE.md`, sección "No tests — ever"). Ignora cualquier paso de TDD de los skills: no crees `tests/`, scripts de test ni frameworks. Cada tarea se verifica con `--import`, `--check-only`, ejecutando el juego en autoplay, leyendo la salida y revisando fotogramas.

**Goal:** Niveles con subida de stats, PM y el hechizo Llama, pociones en un inventario persistente con botín, y un enemigo que elige su acción según pesos de sus datos.

**Architecture:** Las reglas nuevas son puras: `Skill` (Resource), `Inventory` y `Leveling` (RefCounted). `BattleEngine` recibe comandos como diccionarios y emite eventos nuevos que `BattleScene` reproduce. `GameState` guarda el inventario y `Game` lo pasa al combate y al mapa.

**Tech Stack:** Godot 4.7.2, GDScript, Forward+, Jolt Physics. Todo escrito como texto (sin editor).

Spec: `docs/boost/specs/2026-11-02-progresion-combate-design.md`.

## Global Constraints

- Godot **4.7.2**; ejecutable vía `.\tools\godot.cmd` (no está en el PATH).
- **Sin tests unitarios ni automatizados, en ningún momento.**
- Escenas y scripts se escriben como texto; `.godot/` nunca se edita a mano. Los `.tscn` solo llevan el nodo raíz y su script.
- Tras crear un script con `class_name` nuevo: `.\tools\godot.cmd --headless --path . --import`. Commitear los `.uid` generados junto a sus scripts.
- Gitflow: trabajar en `feature/progresion-combate` (ya existe); nunca commitear en `main` ni `develop`.
- Mensajes de commit **sin ninguna mención a Claude**: nada de `Co-Authored-By`, "Generated with Claude Code" ni atribución similar.
- Textos visibles en español; comentarios de código en inglés. Indentación con tabuladores.
- Sin autoloads: el estado lo tiene `Game` y lo pasa explícitamente.
- Las reglas (`BattleEngine`, `Leveling`, `Inventory`, `GameState`) nunca tocan nodos.
- Valores: Llama 3 PM, potencia 16 (daño `16 × randf_range(0.875, 1.125)`, sin DEF, sin fallo, sin crítico); héroe nivel 1 con 6/6 PM; tabla de EXP `[0, 10, 25, 45, 70, 100, 135, 175, 220, 270]`, tope nivel 10; por nivel `+5 PV máx., +2 PM máx., +2 ATK, +1 DEF, +1 VEL` y los PV/PM actuales suben lo mismo; 3 pociones al empezar, curan 25 PV, solo en combate; slime `ai_weights = {"attack": 80, "stagger": 20}`, `potion_drop_chance = 0.25`; derrota → PV y PM completos, se conservan pociones y EXP.

Todos los comandos se ejecutan en PowerShell desde `C:\Users\peixe\Documents\rpg-turnos`.

## Mapa de archivos

| Archivo | Tarea | Responsabilidad |
|---|---|---|
| `scripts/battle/skill.gd` | 1 | `Skill`: datos de un hechizo |
| `data/skills/llama.tres` | 1 | La Llama |
| `scripts/battle/combatant.gd` | 1 | (mod.) nivel, PM, skills, IA, botín |
| `data/hero.tres`, `data/slime.tres` | 1 | (mod.) datos nuevos |
| `scripts/battle/battle_event.gd` | 1 | (mod.) eventos nuevos, `damage(..., magic)` |
| `scripts/game/inventory.gd` | 1 | `Inventory`: objetos `id → cantidad` |
| `scripts/game/leveling.gd` | 1 | `Leveling`: tabla de EXP y subidas |
| `scripts/game/game_state.gd` | 1 | (mod.) inventario, `heal_full()` con PM |
| `scripts/battle/battle_engine.gd` | 2 | (mod.) comandos, hechizos, objetos, IA, nivel y botín |
| `scripts/ui/battle_result.gd` | 2 | (mod.) nivel y poción en la victoria |
| `scripts/battle/battle_scene.gd` | 2, 3 | (mod.) inventario, eventos nuevos, autoplay, mensajes impresos |
| `scripts/ui/battle_hud.gd` | 2, 3 | (mod.) comandos como diccionario; menú de tres botones, PM y nivel |
| `scripts/game/game.gd` | 2, 4 | (mod.) pasa el inventario |
| `scripts/battle/battle_actor.gd` | 3 | (mod.) `play_cast`, `play_burn`, `play_heal`, `play_stagger` |
| `scripts/world/world.gd` | 4 | (mod.) estado con Nv, PM, EXP siguiente y pociones |
| `CLAUDE.md` | 4 | (mod.) Layout al día |

---

### Task 1: Datos y reglas puras

**Files:**
- Create: `scripts/battle/skill.gd`, `data/skills/llama.tres`, `scripts/game/inventory.gd`, `scripts/game/leveling.gd`
- Modify: `scripts/battle/combatant.gd`, `data/hero.tres`, `data/slime.tres`, `scripts/battle/battle_event.gd`, `scripts/game/game_state.gd`

**Interfaces:**
- Produces:
  - `Skill` con `id: String`, `display_name: String`, `mp_cost: int`, `power: int`.
  - `Combatant` con `level`, `max_mp`, `mp`, `skills: Array[Skill]`, `ai_weights: Dictionary`, `potion_drop_chance: float` y `find_skill(id: String) -> Skill`.
  - `Inventory` con `POTION`, `POTION_HEAL`, `START_POTIONS`, `static display_name(id) -> String`, `count(id) -> int`, `add(id, n := 1)` y `take(id) -> bool`.
  - `Leveling` con `MAX_LEVEL`, `EXP_TABLE`, `GAINS`, `static apply(hero) -> Array[Dictionary]` y `static exp_for_next(level) -> int`.
  - `BattleEvent` con `SKILL`, `ITEM`, `HEAL`, `STAGGER`, `LEVEL_UP` y `DROP`, más sus constructores. `damage(target, amount, crit, hp_left, magic := false)`.
  - `GameState.inventory: Inventory`.

- [ ] **Step 1: Crear `scripts/battle/skill.gd`**

```gdscript
class_name Skill extends Resource
## A spell a combatant can cast. Every skill is magic damage for now: power times the
## usual damage spread, ignoring DEF, with no miss and no crit.

@export var id := ""
@export var display_name := ""
@export var mp_cost := 0
@export var power := 0
```

- [ ] **Step 2: Crear `data/skills/llama.tres`**

```
[gd_resource type="Resource" script_class="Skill" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/battle/skill.gd" id="1_skill"]

[resource]
script = ExtResource("1_skill")
id = "llama"
display_name = "Llama"
mp_cost = 3
power = 16
```

- [ ] **Step 3: Reescribir `scripts/battle/combatant.gd`**

```gdscript
class_name Combatant extends Resource
## Stats of one fighter. Battles work on duplicates, so the .tres files never change.

@export var display_name := ""
@export var level := 1
@export var max_hp := 1
@export var hp := 1
@export var max_mp := 0
@export var mp := 0
@export var attack := 1
@export var defense := 0
@export var speed := 1
@export var skills: Array[Skill] = []
## EXP the winner gets for defeating this fighter.
@export var exp_reward := 0
## EXP accumulated so far (only meaningful for the hero). Not called `exp`, which
## would shadow the built-in exp() function.
@export var experience := 0
## Enemy only: weights of the action it picks each round. Keys are "attack",
## "stagger" (loses the turn) or the id of one of its skills. Empty means always attack.
@export var ai_weights := {}
## Enemy only: chance of leaving a potion when defeated.
@export var potion_drop_chance := 0.0


func is_alive() -> bool:
	return hp > 0


func find_skill(id: String) -> Skill:
	for skill in skills:
		if skill.id == id:
			return skill
	return null
```

- [ ] **Step 4: Reescribir `data/hero.tres`**

```
[gd_resource type="Resource" script_class="Combatant" load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/battle/combatant.gd" id="1_combatant"]
[ext_resource type="Script" path="res://scripts/battle/skill.gd" id="2_skill"]
[ext_resource type="Resource" path="res://data/skills/llama.tres" id="3_llama"]

[resource]
script = ExtResource("1_combatant")
display_name = "Héroe"
level = 1
max_hp = 30
hp = 30
max_mp = 6
mp = 6
attack = 12
defense = 6
speed = 8
skills = Array[ExtResource("2_skill")]([ExtResource("3_llama")])
```

- [ ] **Step 5: Reescribir `data/slime.tres`**

```
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
ai_weights = {
"attack": 80,
"stagger": 20
}
potion_drop_chance = 0.25
```

- [ ] **Step 6: Reescribir `scripts/battle/battle_event.gd`**

```gdscript
class_name BattleEvent extends RefCounted
## Event dictionaries produced by BattleEngine (and Leveling) and played back by the
## battle scene. Every event has a "type"; sides are HERO or ENEMY.

const ATTACK := "attack"
const MISS := "miss"
const DAMAGE := "damage"
const DEFEATED := "defeated"
const VICTORY := "victory"
const DEFEAT := "defeat"
const SKILL := "skill"
const ITEM := "item"
const HEAL := "heal"
const STAGGER := "stagger"
const LEVEL_UP := "level_up"
const DROP := "drop"

const HERO := "hero"
const ENEMY := "enemy"


static func attack(actor: String, target: String) -> Dictionary:
	return {"type": ATTACK, "actor": actor, "target": target}


static func miss(actor: String, target: String) -> Dictionary:
	return {"type": MISS, "actor": actor, "target": target}


## magic is true for spell damage (played back with the fire animation).
static func damage(target: String, amount: int, crit: bool, hp_left: int, \
		magic := false) -> Dictionary:
	return {"type": DAMAGE, "target": target, "amount": amount, "crit": crit,
		"hp_left": hp_left, "magic": magic}


static func defeated(target: String) -> Dictionary:
	return {"type": DEFEATED, "target": target}


static func victory(amount: int) -> Dictionary:
	return {"type": VICTORY, "exp": amount}


static func defeat() -> Dictionary:
	return {"type": DEFEAT}


static func skill(actor: String, target: String, skill_name: String, mp_left: int) -> Dictionary:
	return {"type": SKILL, "actor": actor, "target": target, "name": skill_name,
		"mp_left": mp_left}


static func item(actor: String, item_name: String) -> Dictionary:
	return {"type": ITEM, "actor": actor, "name": item_name}


static func heal(target: String, amount: int, hp_left: int) -> Dictionary:
	return {"type": HEAL, "target": target, "amount": amount, "hp_left": hp_left}


static func stagger(actor: String) -> Dictionary:
	return {"type": STAGGER, "actor": actor}


## gains holds the stat increases of one level (see Leveling.GAINS).
static func level_up(level: int, gains: Dictionary) -> Dictionary:
	return {"type": LEVEL_UP, "level": level, "gains": gains}


static func drop(item_id: String) -> Dictionary:
	return {"type": DROP, "item": item_id}
```

- [ ] **Step 7: Crear `scripts/game/inventory.gd`**

```gdscript
class_name Inventory extends RefCounted
## Items the hero carries, as id -> count. GameState keeps one for the whole session.
## The potion is the only item for now: it heals POTION_HEAL HP and is used in battle.

const POTION := "potion"
const POTION_HEAL := 25
const START_POTIONS := 3
const NAMES := {POTION: "Poción"}

var _items := {}


static func display_name(id: String) -> String:
	return NAMES.get(id, id)


func count(id: String) -> int:
	return _items.get(id, 0)


func add(id: String, n := 1) -> void:
	_items[id] = count(id) + n


## Removes one; false if there was none.
func take(id: String) -> bool:
	if count(id) <= 0:
		return false
	_items[id] = count(id) - 1
	return true
```

- [ ] **Step 8: Crear `scripts/game/leveling.gd`**

```gdscript
class_name Leveling extends RefCounted
## Pure level-up rules: fixed EXP table and fixed gains per level. Current HP and MP
## go up by the same amount as their maximum, so a level up is not a full heal.

const MAX_LEVEL := 10
## EXP_TABLE[i] is the total EXP needed to reach level i + 1.
const EXP_TABLE := [0, 10, 25, 45, 70, 100, 135, 175, 220, 270]
const GAINS := {"max_hp": 5, "max_mp": 2, "attack": 2, "defense": 1, "speed": 1}


## Raises every level the hero's EXP allows and returns one LEVEL_UP event per level.
static func apply(hero: Combatant) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	while hero.level < MAX_LEVEL and hero.experience >= EXP_TABLE[hero.level]:
		hero.level += 1
		hero.max_hp += GAINS.max_hp
		hero.hp += GAINS.max_hp
		hero.max_mp += GAINS.max_mp
		hero.mp += GAINS.max_mp
		hero.attack += GAINS.attack
		hero.defense += GAINS.defense
		hero.speed += GAINS.speed
		events.append(BattleEvent.level_up(hero.level, GAINS))
	return events


## Total EXP needed for the next level, or -1 at MAX_LEVEL.
static func exp_for_next(level: int) -> int:
	return EXP_TABLE[level] if level < MAX_LEVEL else -1
```

- [ ] **Step 9: Reescribir `scripts/game/game_state.gd`**

```gdscript
class_name GameState extends RefCounted
## State of the play session, kept in memory while the game is open. The hero and the
## inventory live here for the whole session; battles change them in place.

var hero: Combatant
var inventory := Inventory.new()


func _init(hero_data: Combatant) -> void:
	hero = hero_data.duplicate() as Combatant
	inventory.add(Inventory.POTION, Inventory.START_POTIONS)


## Back to full HP and MP, used after a defeat.
func heal_full() -> void:
	hero.hp = hero.max_hp
	hero.mp = hero.max_mp
```

- [ ] **Step 10: Importar y validar**

```powershell
.\tools\godot.cmd --headless --path . --import
foreach ($s in "scripts/battle/skill.gd","scripts/battle/combatant.gd","scripts/battle/battle_event.gd","scripts/game/inventory.gd","scripts/game/leveling.gd","scripts/game/game_state.gd") { .\tools\godot.cmd --headless --path . --check-only --script "res://$s" }
```

Expected: ningún `ERROR` ni `Parse Error`. Se crean `skill.gd.uid`, `inventory.gd.uid` y `leveling.gd.uid`.

- [ ] **Step 11: Comprobar que el juego sigue funcionando** (el motor aún no usa nada nuevo)

```powershell
.\tools\godot.cmd --path . --fixed-fps 10 --quit-after 600 -- --autoplay 2>&1 | Select-String -Pattern "ERROR|WARNING|SCRIPT"
```

Expected: ninguna línea.

- [ ] **Step 12: Commit**

```powershell
git add scripts/battle/skill.gd scripts/battle/skill.gd.uid data/skills/llama.tres scripts/battle/combatant.gd data/hero.tres data/slime.tres scripts/battle/battle_event.gd scripts/game/inventory.gd scripts/game/inventory.gd.uid scripts/game/leveling.gd scripts/game/leveling.gd.uid scripts/game/game_state.gd
git commit -m "Add skills, inventory, leveling rules and new battle events"
```

---

### Task 2: Motor con comandos, hechizo, poción, IA, nivel y botín

**Files:**
- Modify: `scripts/battle/battle_engine.gd`, `scripts/battle/battle_scene.gd`, `scripts/ui/battle_result.gd`, `scripts/ui/battle_hud.gd`, `scripts/game/game.gd`

**Interfaces:**
- Consumes (Task 1): `Skill`, `Combatant.find_skill()`, `ai_weights`, `potion_drop_chance`, `Inventory`, `Leveling.apply()`, los eventos nuevos de `BattleEvent`, `GameState.inventory`.
- Produces:
  - `BattleEngine.new(hero, enemy, rng, inventory)`.
  - `static cmd_attack()`, `cmd_skill(skill)` y `cmd_item(id)`, que devuelven un `Dictionary`.
  - `can_use(cmd) -> bool` y `resolve_round(cmd: Dictionary) -> Array[Dictionary]`.
  - `BattleScene.setup(hero, enemy_data, inventory)`.
  - `BattleHud.command_chosen(cmd: Dictionary)`.
  - `BattleResult.show_victory(exp_gained, total_exp, new_level := 0, got_potion := false)`.

En esta tarea el menú del HUD sigue teniendo solo "Atacar". El autoplay ya usa la Llama y la poción, y los eventos nuevos se muestran como mensajes; las animaciones llegan en la Task 3.

- [ ] **Step 1: Reescribir `scripts/battle/battle_engine.gd`**

```gdscript
class_name BattleEngine extends RefCounted
## Pure turn-based battle rules (Dragon Quest style rounds). Resolves one round at a
## time and returns the events that happened; never touches nodes. Mutates the
## Combatants and the Inventory it is given: the hero and the inventory belong to the
## session, the enemy is a duplicate of its data file.
##
## Commands are dictionaries built with cmd_attack(), cmd_skill() and cmd_item(). The
## enemy picks its own command each round from its ai_weights.

enum State { ONGOING, WON, LOST }

const CMD_ATTACK := "attack"
const CMD_SKILL := "skill"
const CMD_ITEM := "item"
const CMD_STAGGER := "stagger"

const MISS_CHANCE := 0.05
const CRIT_CHANCE := 1.0 / 16.0
const CRIT_MULT := 1.5
const DAMAGE_SPREAD := Vector2(0.875, 1.125)
const INITIATIVE_SPREAD := Vector2(0.5, 1.5)

var hero: Combatant
var enemy: Combatant
var inventory: Inventory
var state := State.ONGOING

var _rng: RandomNumberGenerator


func _init(p_hero: Combatant, p_enemy: Combatant, rng: RandomNumberGenerator, \
		p_inventory: Inventory) -> void:
	hero = p_hero
	enemy = p_enemy
	_rng = rng
	inventory = p_inventory


static func cmd_attack() -> Dictionary:
	return {"type": CMD_ATTACK}


static func cmd_skill(skill: Skill) -> Dictionary:
	return {"type": CMD_SKILL, "skill": skill}


static func cmd_item(id: String) -> Dictionary:
	return {"type": CMD_ITEM, "item": id}


## True if the hero can use the command right now (enough MP, item in stock).
func can_use(cmd: Dictionary) -> bool:
	match cmd.type:
		CMD_ATTACK:
			return true
		CMD_SKILL:
			return hero.mp >= (cmd.skill as Skill).mp_cost
		CMD_ITEM:
			return inventory.count(cmd.item) > 0
	return false


## Resolves a full round with the hero's command and the enemy's own choice.
## Returns an empty array once the battle is over.
func resolve_round(hero_cmd: Dictionary) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if state != State.ONGOING:
		return events
	assert(can_use(hero_cmd), "Hero can't use command: %s" % hero_cmd)
	var commands := {BattleEvent.HERO: hero_cmd, BattleEvent.ENEMY: _enemy_command()}
	for side in _turn_order():
		if not _fighter(side).is_alive():
			continue
		_act(side, commands[side], events)
		if not hero.is_alive() or not enemy.is_alive():
			break
	if not enemy.is_alive():
		state = State.WON
		hero.experience += enemy.exp_reward
		events.append(BattleEvent.victory(enemy.exp_reward))
		events.append_array(Leveling.apply(hero))
		if _rng.randf() < enemy.potion_drop_chance:
			inventory.add(Inventory.POTION)
			events.append(BattleEvent.drop(Inventory.POTION))
	elif not hero.is_alive():
		state = State.LOST
		events.append(BattleEvent.defeat())
	return events


## Weighted pick from the enemy's ai_weights; a skill it can't afford becomes an attack.
func _enemy_command() -> Dictionary:
	var weights: Dictionary = enemy.ai_weights
	if weights.is_empty():
		return cmd_attack()
	var total := 0.0
	for weight in weights.values():
		total += weight
	var roll := _rng.randf() * total
	var choice: String = weights.keys().back()
	for key in weights:
		roll -= weights[key]
		if roll < 0.0:
			choice = key
			break
	match choice:
		CMD_ATTACK:
			return cmd_attack()
		CMD_STAGGER:
			return {"type": CMD_STAGGER}
	var skill := enemy.find_skill(choice)
	if skill != null and enemy.mp >= skill.mp_cost:
		return cmd_skill(skill)
	return cmd_attack()


func _turn_order() -> Array[String]:
	var hero_roll := hero.speed * _rng.randf_range(INITIATIVE_SPREAD.x, INITIATIVE_SPREAD.y)
	var enemy_roll := enemy.speed * _rng.randf_range(INITIATIVE_SPREAD.x, INITIATIVE_SPREAD.y)
	if hero_roll >= enemy_roll:
		return [BattleEvent.HERO, BattleEvent.ENEMY]
	return [BattleEvent.ENEMY, BattleEvent.HERO]


func _act(side: String, cmd: Dictionary, events: Array[Dictionary]) -> void:
	var target_side := _other(side)
	match cmd.type:
		CMD_ATTACK:
			_attack(side, target_side, events)
		CMD_SKILL:
			_cast(side, target_side, cmd.skill, events)
		CMD_ITEM:
			_use_item(side, cmd.item, events)
		CMD_STAGGER:
			events.append(BattleEvent.stagger(side))


func _attack(side: String, target_side: String, events: Array[Dictionary]) -> void:
	events.append(BattleEvent.attack(side, target_side))
	if _rng.randf() < MISS_CHANCE:
		events.append(BattleEvent.miss(side, target_side))
		return
	var crit := _rng.randf() < CRIT_CHANCE
	var amount := _roll_damage(_fighter(side), _fighter(target_side), crit)
	_hurt(target_side, amount, crit, false, events)


## Spells pay their MP, ignore DEF and never miss or crit.
func _cast(side: String, target_side: String, skill: Skill, events: Array[Dictionary]) -> void:
	var caster := _fighter(side)
	caster.mp -= skill.mp_cost
	events.append(BattleEvent.skill(side, target_side, skill.display_name, caster.mp))
	var amount := maxi(1, roundi(skill.power * _rng.randf_range(DAMAGE_SPREAD.x, DAMAGE_SPREAD.y)))
	_hurt(target_side, amount, false, true, events)


## The potion is the only item: it heals POTION_HEAL HP without going over the max.
func _use_item(side: String, id: String, events: Array[Dictionary]) -> void:
	var user := _fighter(side)
	inventory.take(id)
	events.append(BattleEvent.item(side, Inventory.display_name(id)))
	var amount := mini(Inventory.POTION_HEAL, user.max_hp - user.hp)
	user.hp += amount
	events.append(BattleEvent.heal(side, amount, user.hp))


func _hurt(target_side: String, amount: int, crit: bool, magic: bool, \
		events: Array[Dictionary]) -> void:
	var target := _fighter(target_side)
	target.hp = maxi(target.hp - amount, 0)
	events.append(BattleEvent.damage(target_side, amount, crit, target.hp, magic))
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

- [ ] **Step 2: En `scripts/ui/battle_hud.gd`, que el comando sea un diccionario**

Sustituir la línea `signal command_chosen(cmd: String)` por:

```gdscript
signal command_chosen(cmd: Dictionary)
```

Y sustituir la función `_on_attack_pressed` del final por:

```gdscript
func _on_attack_pressed() -> void:
	hide_menu()
	command_chosen.emit(BattleEngine.cmd_attack())
```

- [ ] **Step 3: En `scripts/ui/battle_result.gd`, sustituir `show_victory`**

```gdscript
## new_level is 0 when the hero did not level up.
func show_victory(exp_gained: int, total_exp: int, new_level := 0, got_potion := false) -> void:
	_title.text = "¡Victoria!"
	var lines := PackedStringArray(["+%d EXP  (total: %d)" % [exp_gained, total_exp]])
	if new_level > 0:
		lines.append("¡Nivel %d!" % new_level)
	if got_potion:
		lines.append("+1 %s" % Inventory.display_name(Inventory.POTION))
	_detail.text = "\n".join(lines)
	_open()
```

- [ ] **Step 4: Reescribir `scripts/battle/battle_scene.gd`**

```gdscript
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
	engine = BattleEngine.new(hero, enemy, _rng, inventory)
	_hud.set_hero(hero)
	await _say("¡Un %s salvaje aparece!" % enemy.display_name)
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
			await _say("¡%s lanza %s!" % [_fighter(event.actor).display_name, event.name])
			_focus_camera(_actor(event.target))
		BattleEvent.MISS:
			await _actor(event.target).play_dodge()
			_reset_camera()
			await _say("¡Pero falla!")
		BattleEvent.DAMAGE:
			if event.crit:
				_shake_camera()
			await _actor(event.target).play_hit(event.amount, event.crit)
			_reset_camera()
			if event.target == BattleEvent.HERO:
				_hud.update_hp(event.hp_left, hero.max_hp)
			if event.crit:
				await _say("¡Golpe crítico!")
			await _say("¡%s recibe %d de daño!" % [
				_fighter(event.target).display_name, event.amount])
		BattleEvent.ITEM:
			await _say("¡%s usa una %s!" % [_fighter(event.actor).display_name, event.name])
		BattleEvent.HEAL:
			if event.target == BattleEvent.HERO:
				_hud.update_hp(event.hp_left, hero.max_hp)
			await _say("¡%s recupera %d PV!" % [
				_fighter(event.target).display_name, event.amount])
		BattleEvent.STAGGER:
			await _say("El %s se tambalea." % _fighter(event.actor).display_name)
		BattleEvent.DEFEATED:
			await _actor(event.target).play_defeat()
			if event.target == BattleEvent.ENEMY:
				await _say("¡%s ha sido derrotado!" % enemy.display_name)
			else:
				await _say("¡Has sido derrotado...!")
		BattleEvent.VICTORY:
			await _say("¡Has ganado! Obtienes %d EXP." % event.exp)
		BattleEvent.LEVEL_UP:
			_new_level = event.level
			_hud.update_hp(hero.hp, hero.max_hp)
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
```

- [ ] **Step 5: En `scripts/game/game.gd`, pasar el inventario al combate**

Sustituir `battle.setup(state.hero, SLIME_DATA)` por:

```gdscript
	battle.setup(state.hero, SLIME_DATA, state.inventory)
```

- [ ] **Step 6: Validar**

```powershell
foreach ($s in "scripts/battle/battle_engine.gd","scripts/battle/battle_scene.gd","scripts/ui/battle_result.gd","scripts/ui/battle_hud.gd","scripts/game/game.gd") { .\tools\godot.cmd --headless --path . --check-only --script "res://$s" }
```

Expected: ningún `ERROR` ni `Parse Error`.

- [ ] **Step 7: Ejecutar en autoplay y leer los mensajes**

```powershell
.\tools\godot.cmd --path . --fixed-fps 10 --quit-after 3000 -- --autoplay 2>&1 | Tee-Object -Variable out | Out-Null
$out | Select-String -Pattern "ERROR|WARNING|SCRIPT"
$out | Select-String -Pattern "lanza Llama|usa una Poción|recupera|se tambalea|sube al nivel|PV \+5|ha dejado" | Select-Object -First 30
```

Expected:
- La primera búsqueda no devuelve ninguna línea.
- La segunda muestra al menos `¡Héroe lanza Llama!`, `¡Héroe sube al nivel 2!` y `PV +5  PM +2  ATK +2  DEF +1  VEL +1`.
- Lo normal es que también salgan `El Slime se tambalea.`, `¡Héroe usa una Poción!` y `¡El Slime ha dejado una Poción!`, pero dependen del azar. Si alguno no aparece, repite una vez con `--quit-after 6000`.

- [ ] **Step 8: Commit**

```powershell
git add scripts/battle/battle_engine.gd scripts/battle/battle_scene.gd scripts/ui/battle_result.gd scripts/ui/battle_hud.gd scripts/game/game.gd
git commit -m "Resolve spells, potions, enemy choices, level ups and drops in battle"
```

---

### Task 3: Menú de comandos, PM en el HUD y animaciones nuevas

**Files:**
- Modify: `scripts/ui/battle_hud.gd`, `scripts/battle/battle_actor.gd`, `scripts/battle/battle_scene.gd`

**Interfaces:**
- Consumes (Task 2): `BattleEngine.cmd_attack()`, `cmd_skill(skill)`, `cmd_item(id)` y `BattleScene._say()`. Los eventos con `magic`, `mp_left` y `level`.
- Produces:
  - `BattleHud`: `set_hero(c: Combatant, potions: int)`, `update_mp(mp, max_mp)`, `update_level(level)`, `set_potions(n)` y `show_menu()`, que muestra tres botones.
  - `BattleActor`: `play_cast()`, `play_burn(amount)`, `play_heal(amount)` y `play_stagger()`, todas se pueden esperar con `await`.

- [ ] **Step 1: Reescribir `scripts/ui/battle_hud.gd`**

```gdscript
class_name BattleHud extends Control
## Dragon Quest style battle UI: hero status (top left), command menu and message
## window (bottom). The menu lists "Atacar", the hero's first skill and the potion;
## the last two are disabled without enough MP or potions. Up / down move between
## commands, Enter / Space or a click choose one. show_message() can be awaited: it
## types the text out and returns when the player advances (click, Enter, Space) or
## after a short auto-advance.

signal command_chosen(cmd: Dictionary)

const CHAR_TIME := 0.025
const AUTO_ADVANCE := 0.6
const FONT_SIZE := 24

var _name_label: Label
var _hp_label: Label
var _hp_bar: ProgressBar
var _mp_label: Label
var _menu: PanelContainer
var _attack_button: Button
var _skill_button: Button
var _item_button: Button
var _message: Label
var _hero: Combatant
var _potions := 0
var _hp_fill := StyleBoxFlat.new()
var _menu_active := false
var _advance_requested := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_status()
	_build_bottom()
	hide_menu()


func set_hero(c: Combatant, potions: int) -> void:
	_hero = c
	_potions = potions
	update_level(c.level)
	update_hp(c.hp, c.max_hp)
	update_mp(c.mp, c.max_mp)


func update_level(level: int) -> void:
	_name_label.text = "%s  Nv %d" % [_hero.display_name, level]


func update_hp(hp: int, max_hp: int) -> void:
	_hp_label.text = "PV %d / %d" % [hp, max_hp]
	_hp_bar.max_value = max_hp
	_hp_bar.value = hp
	var ratio := float(hp) / maxf(1.0, max_hp)
	if ratio <= 0.25:
		_hp_fill.bg_color = Color(0.85, 0.15, 0.15)
	elif ratio <= 0.5:
		_hp_fill.bg_color = Color(0.9, 0.8, 0.15)
	else:
		_hp_fill.bg_color = Color(0.2, 0.75, 0.25)


func update_mp(mp: int, max_mp: int) -> void:
	_mp_label.text = "PM %d / %d" % [mp, max_mp]


func set_potions(n: int) -> void:
	_potions = n


## The menu keeps its layout slot (only fades out) so the message window never resizes.
func show_menu() -> void:
	_menu_active = true
	_menu.modulate.a = 1.0
	_set_enabled(_attack_button, true)
	var skill := _skill()
	_skill_button.visible = skill != null
	if skill != null:
		_skill_button.text = "%s (%d PM)" % [skill.display_name, skill.mp_cost]
		_set_enabled(_skill_button, _hero.mp >= skill.mp_cost)
	_item_button.text = "%s ×%d" % [Inventory.display_name(Inventory.POTION), _potions]
	_set_enabled(_item_button, _potions > 0)
	_message.text = "¿Qué hará %s?" % _hero.display_name
	_message.visible_characters = -1
	_attack_button.grab_focus()


func hide_menu() -> void:
	_menu_active = false
	_menu.modulate.a = 0.0
	for button in [_attack_button, _skill_button, _item_button]:
		_set_enabled(button, false)


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


## While the menu is open the focused button handles Enter / Space itself.
func _unhandled_input(event: InputEvent) -> void:
	if _menu_active:
		return
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
	_hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hp_bar.add_theme_stylebox_override("fill", _hp_fill)
	box.add_child(_hp_bar)
	_mp_label = _label()
	box.add_child(_mp_label)


func _build_bottom() -> void:
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	row.offset_left = 24
	row.offset_right = -24
	row.offset_top = -200
	row.offset_bottom = -24
	row.add_theme_constant_override("separation", 16)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)

	_menu = make_window()
	_menu.custom_minimum_size = Vector2(220, 0)
	row.add_child(_menu)
	var commands := VBoxContainer.new()
	commands.add_theme_constant_override("separation", 0)
	_menu.add_child(commands)
	_attack_button = _command_button("Atacar")
	_attack_button.pressed.connect(func() -> void: _choose(BattleEngine.cmd_attack()))
	commands.add_child(_attack_button)
	_skill_button = _command_button("")
	_skill_button.pressed.connect(func() -> void: _choose(BattleEngine.cmd_skill(_skill())))
	commands.add_child(_skill_button)
	_item_button = _command_button("")
	_item_button.pressed.connect(func() -> void: _choose(BattleEngine.cmd_item(Inventory.POTION)))
	commands.add_child(_item_button)

	var message_window := make_window()
	message_window.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(message_window)
	_message = _label()
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	message_window.add_child(_message)


func _command_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.flat = true
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	return button


## Disabled buttons also leave the focus chain, so up / down skip them.
func _set_enabled(button: Button, enabled: bool) -> void:
	button.disabled = not enabled
	button.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
	if not enabled:
		button.release_focus()


func _skill() -> Skill:
	if _hero == null or _hero.skills.is_empty():
		return null
	return _hero.skills[0]


func _label() -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", Color.WHITE)
	return label


func _choose(cmd: Dictionary) -> void:
	if not _menu_active:
		return
	hide_menu()
	command_chosen.emit(cmd)
```

- [ ] **Step 2: Animaciones nuevas en `scripts/battle/battle_actor.gd`**

2a. Debajo de `enum Look { HERO, SLIME }`, añadir:

```gdscript

const FIRE_COLOR := Color(1.0, 0.45, 0.1)
const HEAL_COLOR := Color(0.3, 1.0, 0.4)
```

2b. Justo antes de `func _build_hero() -> void:`, añadir:

```gdscript
## Small hop with an orange glow, before a spell.
func play_cast() -> void:
	_set_flash(true, FIRE_COLOR)
	var t := create_tween()
	t.tween_property(_body, "position:y", 0.35, 0.15) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(_body, "position:y", 0.0, 0.15) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await t.finished
	_set_flash(false)


## A ball of fire grows on the actor and fades while the hit plays.
func play_burn(amount: int) -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = FIRE_COLOR
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


## Green glow and a green number going up.
func play_heal(amount: int) -> void:
	_spawn_number(amount, false, HEAL_COLOR)
	_set_flash(true, HEAL_COLOR)
	await get_tree().create_timer(0.35).timeout
	_set_flash(false)


## Wobbles side to side, for a fighter that loses its turn.
func play_stagger() -> void:
	var t := create_tween()
	for angle in [12.0, -12.0, 8.0, 0.0]:
		t.tween_property(_body, "rotation_degrees:z", angle, 0.1)
	await t.finished
```

2c. Sustituir la función `_spawn_number` entera por:

```gdscript
func _spawn_number(amount: int, crit: bool, color := Color.WHITE) -> void:
	var label := Label3D.new()
	label.text = str(amount)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.pixel_size = 0.005
	label.font_size = 96 if crit else 64
	label.outline_size = 16
	label.modulate = Color(1.0, 0.85, 0.2) if crit else color
	label.position = Vector3(0, _top, 0)
	add_child(label)
	var t := label.create_tween().set_parallel()
	t.tween_property(label, "position:y", _top + 0.8, 0.9)
	t.tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.3)
	t.chain().tween_callback(label.queue_free)
```

2d. Sustituir la función `_set_flash` entera por:

```gdscript
func _set_flash(on: bool, color := Color.WHITE) -> void:
	for mat in _materials:
		mat.emission_enabled = on
		mat.emission = color
		mat.emission_energy_multiplier = 1.5
```

- [ ] **Step 3: Usar el HUD y las animaciones nuevas en `scripts/battle/battle_scene.gd`**

3a. En `_ready()`, sustituir `_hud.set_hero(hero)` por:

```gdscript
	_hud.set_hero(hero, inventory.count(Inventory.POTION))
```

3b. Sustituir la función `_play_event` entera por:

```gdscript
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
			await _say("¡%s lanza %s!" % [_fighter(event.actor).display_name, event.name])
			_focus_camera(_actor(event.target))
			await _actor(event.actor).play_cast()
		BattleEvent.MISS:
			await _actor(event.target).play_dodge()
			_reset_camera()
			await _say("¡Pero falla!")
		BattleEvent.DAMAGE:
			if event.crit:
				_shake_camera()
			if event.magic:
				await _actor(event.target).play_burn(event.amount)
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
			await _say("¡Has ganado! Obtienes %d EXP." % event.exp)
		BattleEvent.LEVEL_UP:
			_new_level = event.level
			_hud.update_level(event.level)
			_hud.update_hp(hero.hp, hero.max_hp)
			_hud.update_mp(hero.mp, hero.max_mp)
			await _say("¡%s sube al nivel %d!" % [hero.display_name, event.level])
			await _say(_gains_text(event.gains))
		BattleEvent.DROP:
			_got_potion = true
			await _say("¡El %s ha dejado una %s!" % [
				enemy.display_name, Inventory.display_name(event.item)])
```

- [ ] **Step 4: Validar**

```powershell
foreach ($s in "scripts/ui/battle_hud.gd","scripts/battle/battle_actor.gd","scripts/battle/battle_scene.gd") { .\tools\godot.cmd --headless --path . --check-only --script "res://$s" }
```

Expected: ningún `ERROR` ni `Parse Error`.

- [ ] **Step 5: Autoplay sin errores**

```powershell
.\tools\godot.cmd --path . --fixed-fps 10 --quit-after 3000 -- --autoplay 2>&1 | Select-String -Pattern "ERROR|WARNING|SCRIPT"
```

Expected: ninguna línea.

- [ ] **Step 6: Grabar fotogramas y revisarlos**

```powershell
New-Item -ItemType Directory -Force "$env:TEMP\rpg-frames" | Out-Null
.\tools\godot.cmd --path . --write-movie "$env:TEMP\rpg-frames\f.png" --fixed-fps 10 --quit-after 900 -- --autoplay
```

Busca fotogramas de combate leyendo uno de cada ~20. Comprueba lo siguiente:
- El estado de arriba a la izquierda muestra "Héroe  Nv 1", PV con la barra y "PM 6 / 6". Tras una Llama baja a "PM 3 / 6".
- El mensaje "¡Héroe lanza Llama!" aparece, el héroe da un salto con brillo naranja y sobre el slime crece una bola naranja que se desvanece mientras sale el número.
- Si en los fotogramas sale una poción, hay un destello verde y un número verde sobre el héroe. Si sale un "se tambalea", el slime se balancea.
- Todos los textos caben en sus ventanas y nada se corta.

El menú no aparece en autoplay. Para verlo, ejecuta `.\tools\godot.cmd --path .`, anda por la hierba hasta que salte un combate y haz una captura. Si no puedes interactuar, apúntalo en el informe: el usuario lo comprobará a mano.

Después borra la carpeta:

```powershell
Remove-Item -Recurse -Force "$env:TEMP\rpg-frames"
```

- [ ] **Step 7: Commit**

```powershell
git add scripts/ui/battle_hud.gd scripts/battle/battle_actor.gd scripts/battle/battle_scene.gd
git commit -m "Add the command menu with spell and potion, MP in the HUD and new battle animations"
```

---

### Task 4: Estado del mapa y documentación

**Files:**
- Modify: `scripts/world/world.gd`, `scripts/game/game.gd`, `CLAUDE.md`

**Interfaces:**
- Consumes: `Leveling.exp_for_next(level)`, `Inventory.display_name()`, `Inventory.START_POTIONS`, `GameState.inventory`.
- Produces: `World.refresh_status(hero: Combatant, potions: int)`.

- [ ] **Step 1: Estado del mapa en `scripts/world/world.gd`**

1a. Sustituir el bloque de variables de etiquetas:

```gdscript
var _name_label: Label
var _hp_label: Label
var _exp_label: Label
var _notice: Label
```

por:

```gdscript
var _name_label: Label
var _hp_label: Label
var _mp_label: Label
var _exp_label: Label
var _potion_label: Label
var _notice: Label
```

1b. En `_ready()`, sustituir `refresh_status(HERO_DATA)` por:

```gdscript
		refresh_status(HERO_DATA, Inventory.START_POTIONS)
```

1c. Sustituir la función `refresh_status` entera por:

```gdscript
func refresh_status(hero: Combatant, potions: int) -> void:
	_name_label.text = "%s  Nv %d" % [hero.display_name, hero.level]
	_hp_label.text = "PV %d / %d" % [hero.hp, hero.max_hp]
	_mp_label.text = "PM %d / %d" % [hero.mp, hero.max_mp]
	var next := Leveling.exp_for_next(hero.level)
	if next < 0:
		_exp_label.text = "EXP %d" % hero.experience
	else:
		_exp_label.text = "EXP %d / %d" % [hero.experience, next]
	_potion_label.text = "%s ×%d" % [Inventory.display_name(Inventory.POTION), potions]
```

1d. En `_build_status()`, sustituir:

```gdscript
	_hp_label = _label()
	box.add_child(_hp_label)
	_exp_label = _label()
	box.add_child(_exp_label)
```

por:

```gdscript
	_hp_label = _label()
	box.add_child(_hp_label)
	_mp_label = _label()
	box.add_child(_mp_label)
	_exp_label = _label()
	box.add_child(_exp_label)
	_potion_label = _label()
	box.add_child(_potion_label)
```

- [ ] **Step 2: En `scripts/game/game.gd`, sustituir las dos llamadas `_world.refresh_status(state.hero)`** (en `_ready()` y en `_on_encounter()`) por:

```gdscript
	_world.refresh_status(state.hero, state.inventory.count(Inventory.POTION))
```

Respeta la indentación de cada sitio: un tabulador en los dos.

- [ ] **Step 3: Actualizar la sección `## Layout` de `CLAUDE.md`**

3a. Sustituir la viñeta que empieza por ``- `scenes/game/game.tscn` + `scripts/game/game.gd` `` por:

```markdown
- `scenes/game/game.tscn` + `scripts/game/game.gd` — main scene (`run/main_scene`). Owns a `GameState` and the `World`; on `World.encounter_triggered` it fades to black, `World.set_active(false)`, instantiates a `BattleScene` with `setup(state.hero, slime.tres, state.inventory)` on top, awaits `finished(won)`, frees it and turns the map back on (after a defeat: `heal_full()` and `World.respawn()`). The map is never freed, so position, camera and encounter grace survive battles.
```

3b. Sustituir la viñeta que empieza por ``- `scripts/game/game_state.gd` `` por estas tres:

```markdown
- `scripts/game/game_state.gd` (`GameState`, `RefCounted`) — session state kept in memory: the hero `Combatant` (a duplicate of `data/hero.tres` that lives the whole session; battles change its HP, MP, EXP and level in place), `inventory: Inventory` (starts with 3 potions), `heal_full()` (HP and MP).
- `scripts/game/inventory.gd` (`Inventory`, `RefCounted`) — items as `id → count`: `count()`, `add()`, `take()`, `display_name()`. Only `POTION` exists (heals `POTION_HEAL` = 25 HP, battle only).
- `scripts/game/leveling.gd` (`Leveling`, `RefCounted`) — fixed `EXP_TABLE` up to `MAX_LEVEL` 10 and fixed `GAINS` per level (current HP/MP rise with their max, no full heal); `apply(hero)` returns `LEVEL_UP` events, `exp_for_next(level)`.
```

3c. En la viñeta de `scenes/world/world.tscn`, sustituir `status window (name, PV, EXP)` por `status window (name and level, PV, PM, EXP / next level, potions)` y `refresh_status(hero)` por `refresh_status(hero, potions)`.

3d. Sustituir la viñeta que empieza por ``- `scenes/battle/battle_scene.tscn` `` por:

```markdown
- `scenes/battle/battle_scene.tscn` + `scripts/battle/battle_scene.gd` (`BattleScene`) — one battle: call `setup(hero, enemy_data, inventory)` before adding it (hero and inventory used as is, enemy duplicated); builds stage (`BattleStage.build`), hero and slime `BattleActor`s, camera and a `CanvasLayer` with `BattleHud` and `BattleResult`. Flow: HUD `command_chosen(cmd)` → `BattleEngine.resolve_round(cmd)` → `_play_event()` per event → menu again, or result overlay → "Continuar" → `finished(won)`. Every message goes through `_say()`. `--autoplay` picks commands itself (potion below 40 % HP, Llama while the enemy has more than 12 HP, else Atacar), prints every message and continues by itself.
```

3e. Sustituir la viñeta que empieza por ``- `scripts/battle/battle_engine.gd` `` por:

```markdown
- `scripts/battle/battle_engine.gd` (`BattleEngine`, `RefCounted`) — pure round rules. Commands are dictionaries from `cmd_attack()`, `cmd_skill(skill)`, `cmd_item(id)`; `can_use(cmd)`; the enemy picks its command from `ai_weights` (`"attack"`, `"stagger"` or a skill id). Initiative `speed × randf_range(0.5, 1.5)`; attacks: 5 % miss, 1/16 crit (ignores DEF), damage `base × randf_range(0.875, 1.125)` rounded, minimum 1, where `base = max(1, ATK − DEF/2)` (crit: `ATK × 1.5`); spells pay MP and deal `power × the same spread`, ignoring DEF, no miss or crit; the potion heals 25 HP. On victory: EXP, `Leveling.apply()`, potion drop roll. Returns `Array[Dictionary]` events built by `BattleEvent` (`scripts/battle/battle_event.gd`); `state` is `ONGOING`, `WON` or `LOST`. Never touches nodes.
```

3f. Sustituir la viñeta que empieza por ``- `scripts/battle/combatant.gd` `` por estas dos:

```markdown
- `scripts/battle/combatant.gd` (`Combatant`, `Resource`) — fighter stats (level, HP, MP, ATK, DEF, speed, `skills`, EXP; enemy-only `ai_weights`, `potion_drop_chance`); data in `data/hero.tres`, `data/slime.tres`.
- `scripts/battle/skill.gd` (`Skill`, `Resource`) — spell data (`id`, `display_name`, `mp_cost`, `power`); `data/skills/llama.tres`.
```

3g. En la viñeta de `battle_actor`, sustituir `play_attack`, `play_hit` (flash + floating `Label3D` number), `play_dodge`, `play_defeat` por: `play_attack`, `play_hit` (flash + floating `Label3D` number), `play_dodge`, `play_defeat`, `play_cast`, `play_burn`, `play_heal`, `play_stagger`.

3h. Sustituir la viñeta que empieza por ``- `scenes/ui/battle_hud.tscn` `` por:

```markdown
- `scenes/ui/battle_hud.tscn` + `scripts/ui/battle_hud.gd` (`BattleHud`) — hero status (name and level, PV bar, PM), command menu ("Atacar", the hero's first skill, potion; disabled without MP or potions; emits `command_chosen(cmd: Dictionary)`), typed message window; `await show_message(text)` returns on click / Enter / Space or after auto-advance; `static make_window()` is the shared window style.
```

3i. En la viñeta de `battle_result`, sustituir `victory/defeat overlay with "Continuar"` por `victory overlay (EXP, new level, potion drop) or defeat overlay, with "Continuar"`.

- [ ] **Step 4: Validar**

```powershell
foreach ($s in "scripts/world/world.gd","scripts/game/game.gd") { .\tools\godot.cmd --headless --path . --check-only --script "res://$s" }
```

Expected: ningún `ERROR` ni `Parse Error`.

- [ ] **Step 5: Ejecutar en autoplay**

```powershell
.\tools\godot.cmd --path . --fixed-fps 10 --quit-after 3000 -- --autoplay 2>&1 | Select-String -Pattern "ERROR|WARNING|SCRIPT"
.\tools\godot.cmd --path . res://scenes/world/world.tscn --fixed-fps 10 --quit-after 300 -- --autoplay 2>&1 | Select-String -Pattern "ERROR|WARNING|SCRIPT"
```

Expected: ninguna línea en ninguna de las dos.

- [ ] **Step 6: Grabar fotogramas del mapa y revisarlos**

```powershell
New-Item -ItemType Directory -Force "$env:TEMP\rpg-frames" | Out-Null
.\tools\godot.cmd --path . --write-movie "$env:TEMP\rpg-frames\f.png" --fixed-fps 10 --quit-after 600 -- --autoplay
```

En el primer fotograma y en uno tras volver de un combate, el estado del mapa debe mostrar `Héroe  Nv 1`, `PV 30 / 30`, `PM 6 / 6`, `EXP 0 / 10` y `Poción ×3`. Tras un combate, los PV, PM, EXP y pociones deben haber cambiado de forma coherente. La ventana debe crecer hacia abajo sin cortar nada. Después borra la carpeta:

```powershell
Remove-Item -Recurse -Force "$env:TEMP\rpg-frames"
```

- [ ] **Step 7: Commit**

```powershell
git add scripts/world/world.gd scripts/game/game.gd CLAUDE.md
git commit -m "Show level, MP, next EXP and potions on the map and document the progression rules"
```

- [ ] **Step 8: Prueba manual del usuario y merge** (solo con su visto bueno)

El usuario ejecuta `.\tools\godot.cmd --path .` y comprueba:
- El menú: "Atacar", "Llama (3 PM)" y "Poción ×N". Las flechas mueven el foco, y Enter o un clic eligen.
- Llama y Poción se desactivan cuando no hay PM o no quedan pociones.
- La subida de nivel.
- Los PM y las pociones en el mapa.

Con su OK:

```powershell
git checkout develop
git merge --no-ff feature/progresion-combate -m "Merge branch 'feature/progresion-combate' into develop"
git branch -d feature/progresion-combate
```
