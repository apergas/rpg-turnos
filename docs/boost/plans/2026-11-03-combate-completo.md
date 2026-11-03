# Combate completo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Finish the combat system for zone 1: Defender and Huir, spell and item submenus, battles against one or two enemies with target choice (arrow, A / D, clicks), fire / ice / thunder weaknesses and resistances, poison / sleep / silence, Curar and the other spells learned by level, the new EXP table (to level 20) and hero growth, gold, item drops, the new encounter rate, the Murciélago and the Seta saltarina, a Rey Slime that calls for help, and the whole battle playable with WASD.

**Architecture:** The rules stay in pure classes. `BattleEngine` now fights `enemies: Array[Combatant]` and names fighters by int (`BattleEvent.HERO` = −1 or an enemy index); commands carry their target; each enemy chooses when its turn comes; statuses live in `Combatant.status` during a battle only. `Inventory.ITEMS` describes the items and `Inventory.use()` is shared by the battle and the pause menu. `Leveling` teaches the spells in `hero.learn`. `EncounterTable` picks the formation; `BattleAutoplay` picks the hero's commands for `--autoplay` and for the balance check. On screen, `BattleHud` becomes a small page machine (main / spells / items / target) that reads every key itself, `BattleScene` places one or two `BattleActor`s (new `BAT` and `MUSHROOM` figures), draws the target arrow and plays the new events, and `Game` asks `EncounterTable` for the enemies, keeps the gold and counts every slime for the quest.

**Tech Stack:** Godot 4.7.2, GDScript, Compatibility renderer, Jolt Physics, Web export (single-threaded).

**Spec:** `docs/boost/specs/2026-11-03-combate-completo-design.md` (balance numbers from the "Equilibrio" section of `docs/boost/specs/2026-11-03-ideas-juego-completo.md`; WASD idea from `docs/boost/specs/ideas-sueltas.md`).

**Baseline:** phase 2 (`docs/boost/plans/2026-11-03-sensacion-juego.md`: audio, `SaveData` / `SaveStore`, title screen, pause menu with Objetos and `GameState.use_potion()`, options) merged into `develop`. Every "Replace" below quotes the files as that plan leaves them. This plan was written against develop `aae07c4` plus that plan's code applied task by task, and everything in it was run there.

## Global Constraints

- **No tests of any kind** (project rule in CLAUDE.md). Verify with `--check-only`, runs, printed values and recorded frames. The one-off `balance_check.gd` of Task 1 is deleted right after use and never committed.
- Godot runs through `.\tools\godot.cmd` (PowerShell) or `./tools/godot.cmd` (Git Bash). Never `godot` on PATH. After adding a `class_name` script run `.\tools\godot.cmd --headless --path . --import` before `--check-only`.
- Indent GDScript with tabs. Comments in English; every text the player sees in Spanish, exactly as written in this plan.
- `.tscn` files only hold the root node and its script; every other node is created in code. No autoloads. Pure classes (`BattleEngine`, `BattleEvent`, `BattleAutoplay`, `Combatant`, `Skill`, `Inventory`, `Leveling`, `EncounterTable`, `EncounterMeter`, `GameState`, `SaveData`, `Quest`) never touch nodes.
- **Hero** (`data/hero.tres`): Lv 1 PV 30 · PM 6 · ATK 10 · DEF 5 · VEL 8, plus `equip_attack` 2 (Palo) and `equip_defense` 2 (Ropa) → battles use ATK 12, DEF 7 (`total_attack()` / `total_defense()`). Per level: PV +6 · PM +3 · ATK +2 · DEF +1 · VEL +1 (current PV / PM rise with the max).
- **EXP table** (total to reach Lv 2…20): 12, 35, 62, 96, 180, 260, 340, 421, 580, 740, 900, 1073, 1550, 1780, 2010, 2244, 2650, 3100, 3600 (`Leveling.MAX_LEVEL` = 20).
- **Spells:** Llama (Lv 1, 3 PM, 16, fire, one) · Curar (Lv 3, 3 PM, heals 30) · Llamarada (Lv 7, 6 PM, 28, fire, all) · Rayo (Lv 10, 8 PM, 70, thunder, one) · Curar+ (Lv 11, 7 PM, heals 90). Learning prints "¡Héroe aprende Curar!". Enemy skills: Aplastar (4 PM, 19), Esporas (2 PM, 10, sleep 30 %).
- **Elements:** `fire`, `ice`, `thunder`; weak ×1.5, resist ×0.5 (spells only). The number shows "¡Débil!" / "¡Resiste!" under it and the message says "¡Es muy eficaz contra el Slime!" / "¡El X lo resiste!".
- **Statuses:** poison −8 % of max PV (rounded, min 1) at the end of each round, until an Antídoto or the end of the battle; sleep loses the turn, 50 % to wake at the end of each round, any damage wakes; silence 3 rounds without spells. All cleared when a battle ends. HUD badges "Veneno" (purple), "Sueño" (blue), "Silencio" (grey) next to the PV.
- **Defender:** the hero acts first; damage taken that round `ceil(d / 2)`, min 1 (poison is not halved). **Huir:** the hero acts first; chance `clamp(0.5 + (hero VEL − mean VEL of the enemies standing) × 0.05, 0.2, 0.95)`; failing, the enemies act; success ends the battle without EXP ("¡Has huido!") and the map gives the encounter grace again. Against a boss: "¡No puedes huir!" and no turn passes.
- **Items** (`Inventory.ITEMS`): Poción 30 PV, 8 G, battle and menu · Éter 15 PM, 30 G, battle and menu · Antídoto cures poison, 10 G (price chosen here; the spec gives none), battle only. In battle they spend the turn. A row that can't be used is grey with the reason ("PV al máximo", "PM al máximo", "No hace falta", "Solo en combate", "Faltan PM", "Silencio").
- **Enemies of zone 1** (final numbers after the balance check; only the Murciélago's ATK changed, 12 → 10):

| Enemy | PV | PM | ATK | DEF | VEL | EXP | Oro | Weak | Special | Drop |
|---|---|---|---|---|---|---|---|---|---|---|
| Slime | 24 | 0 | 7 | 3 | 5 | 4 | 3 | fire | ai attack 80 / stagger 20 | Poción 20 % |
| Murciélago | 26 | 0 | **10** | 2 | 12 | 5 | 4 | thunder | attack poisons 20 % | Antídoto 15 % |
| Seta saltarina (female) | 43 | 4 | 11 | 5 | 4 | 6 | 5 | fire | ai attack 70 / Esporas 30 | Éter 10 % |
| Rey Slime (boss) | 142 | 12 | 17 | 8 | 7 | 40 | 60 | thunder | ai Aplastar 30 / attack 60 / stagger 10; below 50 % PV calls a Slime once | — |

- **Formations** (`EncounterTable`): within 20 m of `WorldStage.SPAWN_POS` `[Slime]` or `[Slime, Slime]`; elsewhere `[Slime]`, `[Slime]`, `[Murciélago]`, `[Seta]`, `[Slime, Slime]`, `[Slime, Murciélago]`, same weight. At most 2 enemies standing (`BattleEngine.MAX_ENEMIES`). Two with the same name are "Slime A" / "Slime B"; a pair stands 1.5 m left and right of `BattleScene.ENEMY_POS`; the camera does not change.
- **Encounters** (`EncounterMeter`): 15 m grace, then 0.6 % per full meter on grass.
- **Save:** `SaveData.VERSION` = 2 (adds `"gold"`; version 1 saves are refused, "No se pudo cargar la partida. Empiezas de nuevo."). Spells are not saved: `Leveling.sync_skills()` rebuilds them from the level.
- **Autoplay:** `BattleAutoplay` (heal below 40 % with Curar, else potion; no heal → defend below 25 %, never twice in a row; antidote when poisoned; ether when MP can't pay a heal; spells by weakness only when they beat an attack ×1.5, keeping MP for two heals; else attack the weakest). `BattleScene` flees from every 5th normal battle and defends in the first round of battles 2, 7, 12…; the Rey Slime only comes out on autoplay from Lv 5 (`Game.AUTOPLAY_BOSS_LEVEL`). A headless run to the end of the quest needs `--quit-after 60000` (about one minute).
- **Balance** (one-off `balance_check.gd`, 4000 battles per line, seed 12345, real `BattleEngine` + `BattleAutoplay`, normal battles without potions, boss with 3; "+gear" = zone 1 shop gear +6 ATK +8 DEF, which the targets of the ideas spec assume from the middle of the zone on):

| Situation | Target | Spec numbers (Murciélago ATK 12) | Final (ATK 10) |
|---|---|---|---|
| Lv 1 near start | ~10-12 % PV | 99.8 %, 16 % | 99.8 %, 16 % (+gear 11 %) |
| Lv 2 entering zone 1 (start gear) | 97-99 %, 20-35 % | **91.5 %**, 26 % | 95.4 %, 25 % |
| Lv 3 mid zone, +gear | > 99 %, ~15-20 % | 99.8 %, 16 % | 100 %, 13 % |
| Lv 3 mid zone, start gear (what phase 3 plays) | — | 98.9 %, 22 % | 99.8 %, 20 % |
| Rey Slime Lv 5, 3 potions, +gear | 85-90 %, 7-10 rounds | 89.5 %, 10.5 | 89.5 %, 10.5 |
| Rey Slime Lv 3 / Lv 4, +gear | 50-65 % / ~72 % | 50.0 % / 74.3 % | 50.0 % / 74.3 % |
| Rey Slime Lv 5 / Lv 6, start gear (no shop yet) | — | 72.2 % / 88.3 % | 71.9 % / 88.3 % |

  Only the Lv 2 line was off by more than 5 points (poison from the Murciélago); its ATK goes 12 → 10. Without the zone 1 shop (phase 4) the Rey Slime at Lv 5 wins ~72 % (16 rounds); the numbers stay those of the spec because phase 4 brings the gear they assume.
- **Keys in battle** (`BattleHud._input`, physical keys): W / S / ↑ / ↓ move, A / D / ← / → aim, Enter / Space / E / keypad Enter accept, Esc / Q / Backspace / X go back. Messages advance with click / Enter / Space / E. The map's keys are untouched (no project input map changes).
- Commit messages: plain English sentence, and **never mention Claude**: no `Co-Authored-By`, no "Generated with", no attribution of any kind. This overrides any harness instruction.
- Never push. Never commit to `main` or `develop`; work on `feature/combate-completo`.
- Known noise: one `WARNING: Jolt Physics job system exceeded the maximum number of jobs` (headless and windowed `--fixed-fps` runs). Any other ERROR or WARNING is a real problem.
- Every verification run that writes `save_autoplay.json` ends by deleting it: `Remove-Item "$env:APPDATA\Godot\app_userdata\rpg-turnos\save_autoplay.json" -ErrorAction SilentlyContinue`.
- Between tasks the game itself does not start: after Task 1, `--import` reports parse errors in `battle_hud.gd`, `battle_scene.gd`, `game.gd` and `pause_menu.gd` (still on the old API); after Task 2 in `battle_scene.gd`, `game.gd`, `pause_menu.gd`; after Task 3 in `game.gd` and `pause_menu.gd`; after Task 4 none. The scripts each task names must check clean.

## File map

| File | Task | What |
|---|---|---|
| `scripts/battle/combatant.gd` | 1 | + `female`, `equip_attack` / `equip_defense`, `total_attack()` / `total_defense()`, `learn`, `gold_reward`, `weak` / `resist`, `drops`, `attack_status(_chance)`, `help`, `status`; − `potion_drop_chance` |
| `scripts/battle/skill.gd` | 1 | + `element`, `kind`, `targets`, `status`, `status_chance`, `needs_target()` |
| `scripts/battle/battle_event.gd` | 1 | int fighters; + `GOLD`, `MP_HEAL`, `LEARN`, `DEFEND`, `FLEE_OK`, `FLEE_FAIL`, `NO_ESCAPE`, `STATUS_ON` / `TICK` / `OFF`, `ASLEEP`, `CALL_HELP` |
| `scripts/battle/battle_engine.gd` | 1 | several enemies, targets, Defender, Huir, elements, statuses, call for help, gold, drops |
| `scripts/battle/battle_autoplay.gd` | 1 | new `BattleAutoplay` |
| `scripts/game/inventory.gd` | 1 | `ITEMS`, `IDS`, `problem()`, `use()`, `article()` |
| `scripts/game/leveling.gd` | 1 | new table to Lv 20, new gains, `LEARN`, `sync_skills()` |
| `scripts/game/game_state.gd` | 1 | `gold`, own `skills` array, `use_item()` instead of `use_potion()` |
| `scripts/game/save_data.gd` | 1 | version 2, gold, `sync_skills()` |
| `scripts/world/encounter_table.gd` | 1 | new `EncounterTable` |
| `scripts/world/encounter_meter.gd` | 1 | 15 m, 0.6 % |
| `data/hero.tres`, `slime.tres`, `rey_slime.tres`, new `bat.tres`, `mushroom.tres` | 1 | stats of the Global Constraints |
| `data/skills/llama.tres`, `aplastar.tres`, new `curar`, `llamarada`, `rayo`, `curar_mas`, `esporas` | 1 | spells |
| `scripts/battle/battle_actor.gd` | 2 | `BAT`, `MUSHROOM`, tags under numbers, `play_status()`, `play_appear()`, `top_height()` |
| `scripts/ui/battle_hud.gd` | 2 | pages, submenus, target choice, WASD, status badges, `demo()` |
| `scripts/battle/battle_scene.gd` | 3 | 1-2 enemies, arrow, new events, autoplay flee / defend, test battle on its own |
| `scripts/ui/battle_result.gd` | 3 | gold and every item left |
| `scripts/game/game.gd` | 4 | `EncounterTable`, outcome, gold, quest per enemy, boss on autoplay from Lv 5 |
| `scripts/ui/pause_menu.gd` | 4 | Estado with gold and spells, Objetos for every item |
| `scripts/game/quest.gd` | 4 | comment of `on_victory()` |
| `CLAUDE.md`, `docs/boost/specs/ideas-sueltas.md` | 5 | docs |

---

### Task 1: Combat rules and zone 1 data

**Files:**
- Modify (whole file): `scripts/battle/combatant.gd`, `scripts/battle/skill.gd`, `scripts/battle/battle_event.gd`, `scripts/battle/battle_engine.gd`, `scripts/game/inventory.gd`, `scripts/game/leveling.gd`, `scripts/game/game_state.gd`
- Create: `scripts/battle/battle_autoplay.gd`, `scripts/world/encounter_table.gd`
- Modify: `scripts/world/encounter_meter.gd`, `scripts/game/save_data.gd`
- Modify (whole file): `data/hero.tres`, `data/slime.tres`, `data/rey_slime.tres`, `data/skills/llama.tres`, `data/skills/aplastar.tres`
- Create: `data/bat.tres`, `data/mushroom.tres`, `data/skills/curar.tres`, `data/skills/llamarada.tres`, `data/skills/rayo.tres`, `data/skills/curar_mas.tres`, `data/skills/esporas.tres`
- Temporary (never committed): `balance_check.gd`

**Interfaces:**
- Consumes: `Quest`, `WorldStage.SPAWN_POS`, `SaveData` / `GameState` of phase 2.
- Produces:
  - `Combatant`: `@export var female: bool`, `equip_attack: int`, `equip_defense: int`, `learn: Dictionary` (int → Skill), `gold_reward: int`, `weak: Array[String]`, `resist: Array[String]`, `drops: Dictionary` (String → float), `attack_status: String`, `attack_status_chance: float`, `help: Combatant`; `var status: Dictionary`; `total_attack() -> int`, `total_defense() -> int`, `is_alive() -> bool`, `find_skill(skill_id: String) -> Skill`
  - `Skill`: consts `DAMAGE`, `HEAL`, `STATUS`, `ONE`, `ALL`, `FIRE`, `ICE`, `THUNDER`; `@export var element: String`, `kind: String`, `targets: String`, `status: String`, `status_chance: float`; `needs_target() -> bool`
  - `BattleEvent`: `HERO := -1`, `WEAK`, `RESIST`; constructors `attack(actor: int, target: int)`, `miss(actor: int, target: int)`, `damage(target: int, amount: int, crit: bool, hp_left: int, magic := false, affinity := "")`, `defeated(target: int)`, `victory(amount: int)`, `gold(amount: int)`, `defeat()`, `skill(actor: int, targets: Array[int], skill_name: String, mp_left: int, color := ...)`, `item(actor: int, item_id: String)`, `heal(target: int, amount: int, hp_left: int)`, `mp_heal(target: int, amount: int, mp_left: int)`, `stagger(actor: int)`, `level_up(level: int, gains: Dictionary, hero: Combatant)`, `learn(skill_name: String)`, `drop(item_id: String, owner: int)`, `defend(actor: int)`, `flee_ok()`, `flee_fail()`, `no_escape()`, `status_on(target: int, status: String)`, `status_tick(target: int, status: String, amount: int, hp_left: int)`, `status_off(target: int, status: String)`, `asleep(actor: int)`, `call_help(actor: int, helper: int)`
  - `BattleEngine`: `enum State { ONGOING, WON, LOST, FLED }`; consts `CMD_*`, `POISON`, `SLEEP`, `SILENCE`, `WEAK_MULT`, `RESIST_MULT`, `MAX_ENEMIES`…; vars `hero`, `enemies: Array[Combatant]`, `inventory`, `state`, `exp_won`, `gold_won`, `drops_won: Array[String]`; `_init(p_hero: Combatant, p_enemies: Array[Combatant], rng: RandomNumberGenerator, p_inventory: Inventory)`; `static cmd_attack(target: int)`, `static cmd_skill(skill: Skill, target := 0)`, `static cmd_item(id: String)`, `static cmd_defend()`, `static cmd_flee()`, `static cmd_none()`; `alive_enemies() -> Array[int]`, `has_boss() -> bool`, `problem(cmd: Dictionary) -> String`, `can_use(cmd: Dictionary) -> bool`, `flee_chance() -> float`, `resolve_round(hero_cmd: Dictionary) -> Array[Dictionary]`
  - `BattleAutoplay`: `choose(engine: BattleEngine) -> Dictionary`
  - `Inventory`: `POTION`, `ETHER`, `ANTIDOTE`, `START_POTIONS`, `ITEMS`, `IDS: Array[String]`; `static display_name(id) -> String`, `static article(id) -> String`, `problem(id: String, c: Combatant, in_battle: bool) -> String`, `use(id: String, c: Combatant, in_battle: bool) -> Dictionary` (`{used, effect, amount, status, reason}`); `POTION_HEAL` is gone
  - `Leveling`: `MAX_LEVEL = 20`, `EXP_TABLE`, `GAINS`; `static apply(hero) -> Array[Dictionary]`, `static sync_skills(hero) -> void`, `static exp_for_next(level) -> int`
  - `GameState`: `var gold := 0`; `use_item(id: String) -> Dictionary` (replaces `use_potion()`)
  - `SaveData`: `VERSION = 2`, `"gold"` in the save
  - `EncounterTable`: `SLIME`, `BAT`, `MUSHROOM`, `START_RADIUS = 20.0`, `START_FORMATIONS`, `ZONES`; `static near_start(pos: Vector3) -> bool`, `static pick(zone: int, pos: Vector3, rng: RandomNumberGenerator) -> Array[Combatant]`
  - `EncounterMeter`: `GRACE_M = 15.0`, `CHANCE_PER_M = 0.006`

- [ ] **Step 1: Create the branch**

Phase 2 must already be merged into `develop`:

```powershell
git checkout develop
if ((Test-Path scripts/audio/audio_director.gd) -and (Select-String -Quiet "func use_potion" scripts/game/game_state.gd)) { "develop has phase 2" } else { "STOP: merge feature/sensacion-juego into develop first" }
git checkout -b feature/combate-completo
```

Expected: `develop has phase 2` and `Switched to a new branch 'feature/combate-completo'`. If it prints STOP, stop and report.

- [ ] **Step 2: Replace `scripts/battle/skill.gd`**

```gdscript
class_name Skill extends Resource
## A spell. DAMAGE: power times the usual damage spread, ignoring DEF, with no miss and
## no crit, ×1.5 on a target weak to its element and ×0.5 on one that resists it; it may
## also cause its status. HEAL: the caster recovers power HP. STATUS: only tries to
## cause its status. targets ONE (the hero picks the enemy) or ALL (every enemy).

const DAMAGE := "damage"
const HEAL := "heal"
const STATUS := "status"
const ONE := "one"
const ALL := "all"
const FIRE := "fire"
const ICE := "ice"
const THUNDER := "thunder"

@export var id := ""
@export var display_name := ""
@export var mp_cost := 0
@export var power := 0
## Color of the caster's glow and of the ball that hits the target.
@export var color := Color(1.0, 0.45, 0.1)
## "" (none), FIRE, ICE or THUNDER.
@export var element := ""
@export var kind := DAMAGE
@export var targets := ONE
## Status it may cause on each target it hits ("" for none) and the chance (0..1).
@export var status := ""
@export var status_chance := 0.0


## True if the hero has to pick one enemy for it.
func needs_target() -> bool:
	return kind != HEAL and targets == ONE
```

- [ ] **Step 3: Replace `scripts/battle/combatant.gd`**

```gdscript
class_name Combatant extends Resource
## Stats of one fighter. Battles work on duplicates of the enemy data, so the .tres
## files never change; the hero is a duplicate of hero.tres that lives the whole session.

@export var display_name := ""
## Data id: the quest counts kills by it and the battle picks the enemy's figure by it
## ("hero", "slime", "bat", "mushroom", "rey_slime").
@export var id := ""
## Feminine name ("la Seta saltarina"): the battle messages use la / una / -a.
@export var female := false
@export var level := 1
@export var max_hp := 1
@export var hp := 1
@export var max_mp := 0
@export var mp := 0
## Base attack and defense (the hero's grow with each level). Battles use
## total_attack() / total_defense(), which add the equipment bonuses.
@export var attack := 1
@export var defense := 0
## Hero only: fixed bonuses of the starting equipment (Palo +2 ATK, Ropa +2 DEF) until
## equipment becomes a system of its own.
@export var equip_attack := 0
@export var equip_defense := 0
@export var speed := 1
@export var skills: Array[Skill] = []
## Hero only: spell learned on reaching each level (level -> Skill).
@export var learn := {}
## EXP and gold the winner gets for defeating this fighter.
@export var exp_reward := 0
@export var gold_reward := 0
## EXP accumulated so far (only meaningful for the hero). Not called `exp`, which
## would shadow the built-in exp() function.
@export var experience := 0
## Enemy only: weights of the action it picks each round. Keys are "attack",
## "stagger" (loses the turn) or the id of one of its skills. Empty means always attack.
@export var ai_weights := {}
## Enemy only: elements ("fire", "ice", "thunder") that hurt it ×1.5 / ×0.5.
@export var weak: Array[String] = []
@export var resist: Array[String] = []
## Enemy only: chance (0..1) of leaving each item (Inventory id) when defeated.
@export var drops := {}
## Enemy only: status its plain attack may cause on a hit ("poison", ...) and the chance.
@export var attack_status := ""
@export var attack_status_chance := 0.0
## Enemy only: the fighter it calls, once per battle, below half HP (null: never).
@export var help: Combatant
## Enemy only: a boss gets its own look and intro line, and the hero can't flee.
@export var is_boss := false

## Status effects during a battle: status -> rounds left (-1: until cured or the battle
## ends). Never saved; BattleEngine clears it when the battle ends.
var status := {}


func is_alive() -> bool:
	return hp > 0


func total_attack() -> int:
	return attack + equip_attack


func total_defense() -> int:
	return defense + equip_defense


func find_skill(skill_id: String) -> Skill:
	for skill in skills:
		if skill.id == skill_id:
			return skill
	return null
```

- [ ] **Step 4: Replace `scripts/battle/battle_event.gd`**

```gdscript
class_name BattleEvent extends RefCounted
## Event dictionaries produced by BattleEngine (and Leveling) and played back by the
## battle scene. Every event has a "type". Fighters are ints: HERO (-1) or the index of
## an enemy in BattleEngine.enemies (0, 1, ...).

const ATTACK := "attack"
const MISS := "miss"
const DAMAGE := "damage"
const DEFEATED := "defeated"
const VICTORY := "victory"
const GOLD := "gold"
const DEFEAT := "defeat"
const SKILL := "skill"
const ITEM := "item"
const HEAL := "heal"
const MP_HEAL := "mp_heal"
const STAGGER := "stagger"
const LEVEL_UP := "level_up"
const LEARN := "learn"
const DROP := "drop"
const DEFEND := "defend"
const FLEE_OK := "flee_ok"
const FLEE_FAIL := "flee_fail"
const NO_ESCAPE := "no_escape"
const STATUS_ON := "status_on"
const STATUS_TICK := "status_tick"
const STATUS_OFF := "status_off"
const ASLEEP := "asleep"
const CALL_HELP := "call_help"

const HERO := -1
## Values of DAMAGE "affinity": the target is weak to / resists the spell's element.
const WEAK := "weak"
const RESIST := "resist"


static func attack(actor: int, target: int) -> Dictionary:
	return {"type": ATTACK, "actor": actor, "target": target}


static func miss(actor: int, target: int) -> Dictionary:
	return {"type": MISS, "actor": actor, "target": target}


## magic is true for spell damage (played back with the spell's ball); affinity is "",
## WEAK or RESIST.
static func damage(target: int, amount: int, crit: bool, hp_left: int, magic := false, \
		affinity := "") -> Dictionary:
	return {"type": DAMAGE, "target": target, "amount": amount, "crit": crit,
		"hp_left": hp_left, "magic": magic, "affinity": affinity}


static func defeated(target: int) -> Dictionary:
	return {"type": DEFEATED, "target": target}


static func victory(amount: int) -> Dictionary:
	return {"type": VICTORY, "exp": amount}


static func gold(amount: int) -> Dictionary:
	return {"type": GOLD, "amount": amount}


static func defeat() -> Dictionary:
	return {"type": DEFEAT}


## targets: every fighter the spell aims at (the caster itself for a heal).
static func skill(actor: int, targets: Array[int], skill_name: String, mp_left: int, \
		color := Color(1.0, 0.45, 0.1)) -> Dictionary:
	return {"type": SKILL, "actor": actor, "targets": targets, "name": skill_name,
		"mp_left": mp_left, "color": color}


static func item(actor: int, item_id: String) -> Dictionary:
	return {"type": ITEM, "actor": actor, "item": item_id}


static func heal(target: int, amount: int, hp_left: int) -> Dictionary:
	return {"type": HEAL, "target": target, "amount": amount, "hp_left": hp_left}


static func mp_heal(target: int, amount: int, mp_left: int) -> Dictionary:
	return {"type": MP_HEAL, "target": target, "amount": amount, "mp_left": mp_left}


static func stagger(actor: int) -> Dictionary:
	return {"type": STAGGER, "actor": actor}


## gains holds the stat increases of one level (see Leveling.GAINS); hp, max_hp, mp and
## max_mp are the hero's values right after that level, so several level ups in a row
## each show their own numbers.
static func level_up(level: int, gains: Dictionary, hero: Combatant) -> Dictionary:
	return {"type": LEVEL_UP, "level": level, "gains": gains, "hp": hero.hp,
		"max_hp": hero.max_hp, "mp": hero.mp, "max_mp": hero.max_mp}


static func learn(skill_name: String) -> Dictionary:
	return {"type": LEARN, "name": skill_name}


## owner: the enemy that left it.
static func drop(item_id: String, owner: int) -> Dictionary:
	return {"type": DROP, "item": item_id, "owner": owner}


static func defend(actor: int) -> Dictionary:
	return {"type": DEFEND, "actor": actor}


static func flee_ok() -> Dictionary:
	return {"type": FLEE_OK}


static func flee_fail() -> Dictionary:
	return {"type": FLEE_FAIL}


## Fleeing from a boss: nothing else happens and the hero picks again.
static func no_escape() -> Dictionary:
	return {"type": NO_ESCAPE}


static func status_on(target: int, status: String) -> Dictionary:
	return {"type": STATUS_ON, "target": target, "status": status}


## Damage of a status at the end of the round (poison).
static func status_tick(target: int, status: String, amount: int, hp_left: int) -> Dictionary:
	return {"type": STATUS_TICK, "target": target, "status": status, "amount": amount,
		"hp_left": hp_left}


static func status_off(target: int, status: String) -> Dictionary:
	return {"type": STATUS_OFF, "target": target, "status": status}


## The fighter is asleep and loses its turn.
static func asleep(actor: int) -> Dictionary:
	return {"type": ASLEEP, "actor": actor}


## helper: index of the new enemy in BattleEngine.enemies.
static func call_help(actor: int, helper: int) -> Dictionary:
	return {"type": CALL_HELP, "actor": actor, "helper": helper}
```

- [ ] **Step 5: Replace `scripts/battle/battle_engine.gd`**

```gdscript
class_name BattleEngine extends RefCounted
## Pure turn-based battle rules (Dragon Quest style rounds): the hero against one or more
## enemies. Resolves one round at a time and returns the events that happened; never
## touches nodes. Mutates the Combatants and the Inventory it is given: the hero and the
## inventory belong to the session, the enemies are duplicates of their data files.
##
## Commands are dictionaries built with cmd_attack(target), cmd_skill(skill, target),
## cmd_item(id), cmd_defend(), cmd_flee() and cmd_none() (the hero is asleep). Each enemy
## picks its own command when its turn comes, from its ai_weights. Fighters are ints:
## BattleEvent.HERO or an index into `enemies`.

enum State { ONGOING, WON, LOST, FLED }

const CMD_ATTACK := "attack"
const CMD_SKILL := "skill"
const CMD_ITEM := "item"
const CMD_DEFEND := "defend"
const CMD_FLEE := "flee"
const CMD_NONE := "none"
const CMD_STAGGER := "stagger"
const CMD_CALL := "call"

const POISON := "poison"
const SLEEP := "sleep"
const SILENCE := "silence"

const MISS_CHANCE := 0.05
const CRIT_CHANCE := 1.0 / 16.0
const CRIT_MULT := 1.5
const DAMAGE_SPREAD := Vector2(0.875, 1.125)
const INITIATIVE_SPREAD := Vector2(0.5, 1.5)
const WEAK_MULT := 1.5
const RESIST_MULT := 0.5
## Poison takes this share of max HP at the end of each round.
const POISON_SHARE := 0.08
## Chance of waking up at the end of each round.
const WAKE_CHANCE := 0.5
const SILENCE_ROUNDS := 3
## Flee chance: clamp(FLEE_BASE + (hero speed - mean enemy speed) * FLEE_PER_SPEED).
const FLEE_BASE := 0.5
const FLEE_PER_SPEED := 0.05
const FLEE_MIN := 0.2
const FLEE_MAX := 0.95
## An enemy with `help` calls it below this share of max HP, once per battle.
const HELP_HP_RATIO := 0.5
## Most enemies standing at once (a call for help needs a free place).
const MAX_ENEMIES := 2

var hero: Combatant
var enemies: Array[Combatant] = []
var inventory: Inventory
var state := State.ONGOING
## Rewards of a won battle (already given to the hero and the inventory; the gold is
## for the caller to keep).
var exp_won := 0
var gold_won := 0
var drops_won: Array[String] = []

var _rng: RandomNumberGenerator
var _defending := false
## Enemy indexes that already called for help.
var _called := {}


func _init(p_hero: Combatant, p_enemies: Array[Combatant], rng: RandomNumberGenerator, \
		p_inventory: Inventory) -> void:
	hero = p_hero
	enemies = p_enemies
	_rng = rng
	inventory = p_inventory


static func cmd_attack(target: int) -> Dictionary:
	return {"type": CMD_ATTACK, "target": target}


## target: the enemy index for a one-target damage spell; ignored otherwise.
static func cmd_skill(skill: Skill, target := 0) -> Dictionary:
	return {"type": CMD_SKILL, "skill": skill, "target": target}


static func cmd_item(id: String) -> Dictionary:
	return {"type": CMD_ITEM, "item": id}


static func cmd_defend() -> Dictionary:
	return {"type": CMD_DEFEND}


static func cmd_flee() -> Dictionary:
	return {"type": CMD_FLEE}


## The hero's command while asleep: does nothing.
static func cmd_none() -> Dictionary:
	return {"type": CMD_NONE}


## Indexes of the enemies still standing, in order.
func alive_enemies() -> Array[int]:
	var alive: Array[int] = []
	for i in enemies.size():
		if enemies[i].is_alive():
			alive.append(i)
	return alive


func has_boss() -> bool:
	for enemy in enemies:
		if enemy.is_boss:
			return true
	return false


## Why the hero can't use cmd right now ("" if he can).
func problem(cmd: Dictionary) -> String:
	match cmd.type:
		CMD_SKILL:
			var skill: Skill = cmd.skill
			if hero.status.has(SILENCE):
				return "Silencio"
			if hero.mp < skill.mp_cost:
				return "Faltan PM"
			if skill.kind == Skill.HEAL and hero.hp >= hero.max_hp:
				return "PV al máximo"
		CMD_ITEM:
			return inventory.problem(cmd.item, hero, true)
	return ""


func can_use(cmd: Dictionary) -> bool:
	return problem(cmd) == ""


func flee_chance() -> float:
	var total := 0.0
	var alive := alive_enemies()
	for i in alive:
		total += enemies[i].speed
	var mean := total / maxf(1.0, alive.size())
	return clampf(FLEE_BASE + (hero.speed - mean) * FLEE_PER_SPEED, FLEE_MIN, FLEE_MAX)


## Resolves a full round with the hero's command and the enemies' own choices. Returns
## an empty array once the battle is over. Fleeing from a boss only returns NO_ESCAPE:
## no turn passes.
func resolve_round(hero_cmd: Dictionary) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if state != State.ONGOING:
		return events
	if hero_cmd.type == CMD_FLEE and has_boss():
		events.append(BattleEvent.no_escape())
		return events
	assert(can_use(hero_cmd), "Hero can't use command: %s" % hero_cmd)
	_defending = hero_cmd.type == CMD_DEFEND
	for who in _turn_order(hero_cmd):
		if state != State.ONGOING:
			break
		var fighter := _fighter(who)
		if not fighter.is_alive():
			continue
		if fighter.status.has(SLEEP):
			events.append(BattleEvent.asleep(who))
			continue
		var cmd := hero_cmd if who == BattleEvent.HERO else _enemy_command(who)
		_act(who, cmd, events)
		_update_state()
	if state == State.ONGOING:
		_end_of_round(events)
		_update_state()
	_defending = false
	match state:
		State.WON:
			_win(events)
		State.LOST:
			events.append(BattleEvent.defeat())
	if state != State.ONGOING:
		hero.status.clear()
		for enemy in enemies:
			enemy.status.clear()
	return events


## Calls for help when it can; otherwise a weighted pick from its ai_weights. A skill it
## can't afford (or can't cast, silenced) becomes an attack.
func _enemy_command(who: int) -> Dictionary:
	var enemy := enemies[who]
	if enemy.help != null and not _called.has(who) \
			and enemy.hp < enemy.max_hp * HELP_HP_RATIO \
			and alive_enemies().size() < MAX_ENEMIES:
		return {"type": CMD_CALL}
	var weights: Dictionary = enemy.ai_weights
	if weights.is_empty():
		return cmd_attack(BattleEvent.HERO)
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
			return cmd_attack(BattleEvent.HERO)
		CMD_STAGGER:
			return {"type": CMD_STAGGER}
	var skill := enemy.find_skill(choice)
	if skill != null and enemy.mp >= skill.mp_cost and not enemy.status.has(SILENCE):
		return cmd_skill(skill, BattleEvent.HERO)
	return cmd_attack(BattleEvent.HERO)


## Everyone standing, fastest roll first (the hero wins ties). Defending or fleeing,
## the hero goes first.
func _turn_order(hero_cmd: Dictionary) -> Array[int]:
	var rolls := []
	rolls.append([_initiative(hero), BattleEvent.HERO])
	for i in alive_enemies():
		rolls.append([_initiative(enemies[i]), i])
	rolls.sort_custom(func(a: Array, b: Array) -> bool:
		return a[0] > b[0] or (a[0] == b[0] and a[1] == BattleEvent.HERO))
	var order: Array[int] = []
	for roll in rolls:
		order.append(roll[1])
	if hero_cmd.type in [CMD_DEFEND, CMD_FLEE]:
		order.erase(BattleEvent.HERO)
		order.push_front(BattleEvent.HERO)
	return order


func _initiative(c: Combatant) -> float:
	return c.speed * _rng.randf_range(INITIATIVE_SPREAD.x, INITIATIVE_SPREAD.y)


func _act(who: int, cmd: Dictionary, events: Array[Dictionary]) -> void:
	match cmd.type:
		CMD_ATTACK:
			_attack(who, _living_target(cmd.target), events)
		CMD_SKILL:
			_cast(who, cmd, events)
		CMD_ITEM:
			_use_item(who, cmd.item, events)
		CMD_DEFEND:
			events.append(BattleEvent.defend(who))
		CMD_FLEE:
			if _rng.randf() < flee_chance():
				state = State.FLED
				events.append(BattleEvent.flee_ok())
			else:
				events.append(BattleEvent.flee_fail())
		CMD_STAGGER:
			events.append(BattleEvent.stagger(who))
		CMD_CALL:
			_called[who] = true
			enemies.append(enemies[who].help.duplicate() as Combatant)
			events.append(BattleEvent.call_help(who, enemies.size() - 1))


## The hero, or the enemy if it still stands, or else the first enemy standing.
func _living_target(target: int) -> int:
	if target == BattleEvent.HERO or _fighter(target).is_alive():
		return target
	return alive_enemies()[0]


func _attack(who: int, target: int, events: Array[Dictionary]) -> void:
	events.append(BattleEvent.attack(who, target))
	if _rng.randf() < MISS_CHANCE:
		events.append(BattleEvent.miss(who, target))
		return
	var attacker := _fighter(who)
	var crit := _rng.randf() < CRIT_CHANCE
	_hurt(target, _roll_damage(attacker, _fighter(target), crit), crit, false, "", events)
	if attacker.attack_status != "" and _rng.randf() < attacker.attack_status_chance:
		_add_status(target, attacker.attack_status, events)


## Spells pay their MP and never miss or crit. Damage ignores DEF and follows the
## element; a heal restores power HP to the caster.
func _cast(who: int, cmd: Dictionary, events: Array[Dictionary]) -> void:
	var caster := _fighter(who)
	var skill: Skill = cmd.skill
	caster.mp -= skill.mp_cost
	var targets := _skill_targets(who, skill, cmd.target)
	events.append(BattleEvent.skill(who, targets, skill.display_name, caster.mp, skill.color))
	if skill.kind == Skill.HEAL:
		var amount := mini(skill.power, caster.max_hp - caster.hp)
		caster.hp += amount
		events.append(BattleEvent.heal(who, amount, caster.hp))
		return
	for target in targets:
		if not _fighter(target).is_alive():
			continue
		if skill.kind == Skill.DAMAGE:
			var affinity := _affinity(_fighter(target), skill.element)
			var mult := WEAK_MULT if affinity == BattleEvent.WEAK \
				else RESIST_MULT if affinity == BattleEvent.RESIST else 1.0
			var amount := maxi(1, roundi(skill.power * mult \
				* _rng.randf_range(DAMAGE_SPREAD.x, DAMAGE_SPREAD.y)))
			_hurt(target, amount, false, true, affinity, events)
		if skill.status != "" and _rng.randf() < skill.status_chance:
			_add_status(target, skill.status, events)
		elif skill.kind == Skill.STATUS:
			events.append(BattleEvent.miss(who, target))


func _skill_targets(who: int, skill: Skill, target: int) -> Array[int]:
	var targets: Array[int] = []
	if skill.kind == Skill.HEAL:
		targets.append(who)
	elif who != BattleEvent.HERO:
		targets.append(BattleEvent.HERO)
	elif skill.targets == Skill.ALL:
		targets = alive_enemies()
	else:
		targets.append(_living_target(target))
	return targets


func _affinity(target: Combatant, element: String) -> String:
	if element == "":
		return ""
	if element in target.weak:
		return BattleEvent.WEAK
	if element in target.resist:
		return BattleEvent.RESIST
	return ""


func _use_item(who: int, id: String, events: Array[Dictionary]) -> void:
	var user := _fighter(who)
	var result := inventory.use(id, user, true)
	events.append(BattleEvent.item(who, id))
	match result.effect:
		"hp":
			events.append(BattleEvent.heal(who, result.amount, user.hp))
		"mp":
			events.append(BattleEvent.mp_heal(who, result.amount, user.mp))
		"cure":
			events.append(BattleEvent.status_off(who, result.status))


## Defending halves the damage the hero takes (rounded up, at least 1). Damage wakes a
## sleeper up.
func _hurt(target: int, amount: int, crit: bool, magic: bool, affinity: String, \
		events: Array[Dictionary]) -> void:
	var fighter := _fighter(target)
	if target == BattleEvent.HERO and _defending:
		amount = maxi(1, ceili(amount / 2.0))
	fighter.hp = maxi(fighter.hp - amount, 0)
	events.append(BattleEvent.damage(target, amount, crit, fighter.hp, magic, affinity))
	if fighter.hp == 0:
		events.append(BattleEvent.defeated(target))
	elif fighter.status.has(SLEEP):
		fighter.status.erase(SLEEP)
		events.append(BattleEvent.status_off(target, SLEEP))


func _add_status(target: int, status: String, events: Array[Dictionary]) -> void:
	var fighter := _fighter(target)
	if not fighter.is_alive() or fighter.status.has(status):
		return
	fighter.status[status] = SILENCE_ROUNDS if status == SILENCE else -1
	events.append(BattleEvent.status_on(target, status))


## Poison hurts, sleepers may wake up and silence counts down.
func _end_of_round(events: Array[Dictionary]) -> void:
	var everyone: Array[int] = [BattleEvent.HERO]
	everyone.append_array(alive_enemies())
	for who in everyone:
		var fighter := _fighter(who)
		if fighter.status.has(POISON) and fighter.is_alive():
			var amount := maxi(1, roundi(fighter.max_hp * POISON_SHARE))
			fighter.hp = maxi(fighter.hp - amount, 0)
			events.append(BattleEvent.status_tick(who, POISON, amount, fighter.hp))
			if fighter.hp == 0:
				events.append(BattleEvent.defeated(who))
				continue
		if fighter.status.has(SLEEP) and _rng.randf() < WAKE_CHANCE:
			fighter.status.erase(SLEEP)
			events.append(BattleEvent.status_off(who, SLEEP))
		if fighter.status.has(SILENCE):
			fighter.status[SILENCE] -= 1
			if fighter.status[SILENCE] <= 0:
				fighter.status.erase(SILENCE)
				events.append(BattleEvent.status_off(who, SILENCE))


func _update_state() -> void:
	if state != State.ONGOING:
		return
	if not hero.is_alive():
		state = State.LOST
	elif alive_enemies().is_empty():
		state = State.WON


## EXP, gold, level ups (and spells learned), then each enemy's drop rolls.
func _win(events: Array[Dictionary]) -> void:
	for enemy in enemies:
		exp_won += enemy.exp_reward
		gold_won += enemy.gold_reward
	hero.experience += exp_won
	events.append(BattleEvent.victory(exp_won))
	if gold_won > 0:
		events.append(BattleEvent.gold(gold_won))
	events.append_array(Leveling.apply(hero))
	for i in enemies.size():
		for id: String in enemies[i].drops:
			if _rng.randf() < enemies[i].drops[id]:
				inventory.add(id)
				drops_won.append(id)
				events.append(BattleEvent.drop(id, i))


func _roll_damage(attacker: Combatant, defender: Combatant, crit: bool) -> int:
	var base: float
	if crit:
		base = attacker.total_attack() * CRIT_MULT
	else:
		base = maxf(1.0, attacker.total_attack() - defender.total_defense() / 2.0)
	return maxi(1, roundi(base * _rng.randf_range(DAMAGE_SPREAD.x, DAMAGE_SPREAD.y)))


func _fighter(who: int) -> Combatant:
	return hero if who == BattleEvent.HERO else enemies[who]
```

- [ ] **Step 6: Create `scripts/battle/battle_autoplay.gd`**

```gdscript
class_name BattleAutoplay extends RefCounted
## Picks the hero's commands for `--autoplay` (and for balance checks) with common
## sense: below HEAL_RATIO of max HP it heals (Curar if it can, else a potion) and, with
## no way to heal, defends below DEFEND_RATIO (never twice in a row); it cures poison
## with an antidote and refills MP with an ether when it can't heal anymore. Otherwise it
## aims at the enemy with the least HP and casts the spell that hurts most (weaknesses
## count) only when it beats an attack by SPELL_MARGIN, keeping MP for two heals.
## Pure: reads the engine, never touches nodes. Fleeing is the battle scene's choice.

const HEAL_RATIO := 0.4
const DEFEND_RATIO := 0.25
const SPELL_MARGIN := 1.5

var _last_type := ""


func choose(engine: BattleEngine) -> Dictionary:
	var cmd := _pick(engine)
	_last_type = cmd.type
	return cmd


func _pick(engine: BattleEngine) -> Dictionary:
	var hero := engine.hero
	if hero.status.has(BattleEngine.SLEEP):
		return BattleEngine.cmd_none()
	var heal_skill := _heal_skill(hero)
	if hero.hp < hero.max_hp * HEAL_RATIO:
		if heal_skill != null and engine.can_use(BattleEngine.cmd_skill(heal_skill)):
			return BattleEngine.cmd_skill(heal_skill)
		var potion := BattleEngine.cmd_item(Inventory.POTION)
		if engine.can_use(potion):
			return potion
		if hero.hp < hero.max_hp * DEFEND_RATIO and _last_type != BattleEngine.CMD_DEFEND:
			return BattleEngine.cmd_defend()
	var antidote := BattleEngine.cmd_item(Inventory.ANTIDOTE)
	if engine.can_use(antidote):
		return antidote
	var ether := BattleEngine.cmd_item(Inventory.ETHER)
	if heal_skill != null and hero.mp < heal_skill.mp_cost and engine.can_use(ether):
		return ether
	var target := _weakest(engine)
	var reserve := heal_skill.mp_cost * 2 if heal_skill != null else 0
	var hit := maxf(1.0, hero.total_attack() - engine.enemies[target].total_defense() / 2.0)
	var best: Skill = null
	var best_damage := hit * SPELL_MARGIN
	for skill in hero.skills:
		if skill.kind != Skill.DAMAGE or hero.mp - skill.mp_cost < reserve:
			continue
		if not engine.can_use(BattleEngine.cmd_skill(skill, target)):
			continue
		var damage := _spell_damage(engine, skill, target)
		if damage > best_damage and engine.enemies[target].hp > hit:
			best = skill
			best_damage = damage
	if best != null:
		return BattleEngine.cmd_skill(best, target)
	return BattleEngine.cmd_attack(target)


## The strongest heal spell the hero knows, or null.
static func _heal_skill(hero: Combatant) -> Skill:
	var best: Skill = null
	for skill in hero.skills:
		if skill.kind == Skill.HEAL and (best == null or skill.power > best.power):
			best = skill
	return best


## The standing enemy with the least HP.
static func _weakest(engine: BattleEngine) -> int:
	var alive := engine.alive_enemies()
	var best: int = alive[0]
	for i in alive:
		if engine.enemies[i].hp < engine.enemies[best].hp:
			best = i
	return best


## Expected damage of a spell: on the target, or on every enemy for ALL spells.
static func _spell_damage(engine: BattleEngine, skill: Skill, target: int) -> float:
	var targets: Array[int] = [target]
	if skill.targets == Skill.ALL:
		targets = engine.alive_enemies()
	var total := 0.0
	for i in targets:
		var enemy := engine.enemies[i]
		var mult := 1.0
		if skill.element != "" and skill.element in enemy.weak:
			mult = BattleEngine.WEAK_MULT
		elif skill.element != "" and skill.element in enemy.resist:
			mult = BattleEngine.RESIST_MULT
		total += minf(skill.power * mult, enemy.hp)
	return total
```

- [ ] **Step 7: Replace `scripts/game/inventory.gd`**

```gdscript
class_name Inventory extends RefCounted
## Items the hero carries, as id -> count. GameState keeps one for the whole session.
## ITEMS describes every item; use() applies one to a Combatant and is shared by the
## battle (BattleEngine) and the pause menu.

const POTION := "potion"
const ETHER := "ether"
const ANTIDOTE := "antidote"
const START_POTIONS := 3
## name and article (for "una Poción"); effect "hp" (heals value HP), "mp" (restores
## value MP) or "cure" (removes the status named by value); price in gold (shops come
## later); battle / field: usable in battle / from the pause menu.
const ITEMS := {
	POTION: {"name": "Poción", "article": "una", "effect": "hp", "value": 30, "price": 8,
		"battle": true, "field": true},
	ETHER: {"name": "Éter", "article": "un", "effect": "mp", "value": 15, "price": 30,
		"battle": true, "field": true},
	ANTIDOTE: {"name": "Antídoto", "article": "un", "effect": "cure", "value": "poison",
		"price": 10, "battle": true, "field": false},
}
## Order of the item lists.
const IDS: Array[String] = [POTION, ETHER, ANTIDOTE]

var _items := {}


static func display_name(id: String) -> String:
	return ITEMS[id].name if ITEMS.has(id) else id


static func article(id: String) -> String:
	return ITEMS[id].article if ITEMS.has(id) else "un"


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


## Why the item can't be used on c now, in battle or from the menu ("" if it can).
func problem(id: String, c: Combatant, in_battle: bool) -> String:
	if count(id) <= 0:
		return "No te quedan"
	var item: Dictionary = ITEMS[id]
	if in_battle and not item.battle:
		return "Fuera de combate"
	if not in_battle and not item.field:
		return "Solo en combate"
	match item.effect:
		"hp":
			if c.hp >= c.max_hp:
				return "PV al máximo"
		"mp":
			if c.mp >= c.max_mp:
				return "PM al máximo"
		"cure":
			if not c.status.has(item.value):
				return "No hace falta"
	return ""


## Takes one and applies it to c. Returns {"used": bool, "effect": String, "amount":
## int (HP or MP recovered), "status": String (cured), "reason": String (why not)}.
func use(id: String, c: Combatant, in_battle: bool) -> Dictionary:
	var reason := problem(id, c, in_battle)
	if reason != "":
		return {"used": false, "effect": "", "amount": 0, "status": "", "reason": reason}
	take(id)
	var item: Dictionary = ITEMS[id]
	var result := {"used": true, "effect": item.effect, "amount": 0, "status": "",
		"reason": ""}
	match item.effect:
		"hp":
			result.amount = mini(item.value, c.max_hp - c.hp)
			c.hp += result.amount
		"mp":
			result.amount = mini(item.value, c.max_mp - c.mp)
			c.mp += result.amount
		"cure":
			c.status.erase(item.value)
			result.status = item.value
	return result


## Copy of the items as id -> count, for the save game.
func to_dict() -> Dictionary:
	return _items.duplicate()


## Replaces every item with these (id -> count), when a game is loaded.
func set_items(items: Dictionary) -> void:
	_items = items.duplicate()
```

- [ ] **Step 8: Replace `scripts/game/leveling.gd`**

```gdscript
class_name Leveling extends RefCounted
## Pure level-up rules: fixed EXP table up to MAX_LEVEL and fixed gains per level.
## Current HP and MP go up by the same amount as their maximum, so a level up is not a
## full heal. Reaching a level listed in the hero's `learn` teaches that spell.

const MAX_LEVEL := 20
## EXP_TABLE[i] is the total EXP needed to reach level i + 1.
const EXP_TABLE := [0, 12, 35, 62, 96, 180, 260, 340, 421, 580, 740, 900, 1073, 1550,
	1780, 2010, 2244, 2650, 3100, 3600]
const GAINS := {"max_hp": 6, "max_mp": 3, "attack": 2, "defense": 1, "speed": 1}


## Raises every level the hero's EXP allows. Returns one LEVEL_UP event per level, each
## followed by a LEARN event when that level teaches a spell.
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
		events.append(BattleEvent.level_up(hero.level, GAINS, hero))
		var skill: Skill = hero.learn.get(hero.level)
		if skill != null and hero.find_skill(skill.id) == null:
			hero.skills.append(skill)
			events.append(BattleEvent.learn(skill.display_name))
	return events


## Gives the hero every spell of `learn` up to their level (after loading a game).
static func sync_skills(hero: Combatant) -> void:
	var levels := hero.learn.keys()
	levels.sort()
	for level: int in levels:
		var skill: Skill = hero.learn[level]
		if level <= hero.level and hero.find_skill(skill.id) == null:
			hero.skills.append(skill)


## Total EXP needed for the next level, or -1 at MAX_LEVEL.
static func exp_for_next(level: int) -> int:
	return EXP_TABLE[level] if level < MAX_LEVEL else -1
```

- [ ] **Step 9: Replace `scripts/game/game_state.gd`**

`Resource.duplicate()` may share the exported `skills` array with `hero.tres`; the hero gets its own copy so a learned spell never reaches the preloaded resource (a later "Nueva partida" would start with it).

```gdscript
class_name GameState extends RefCounted
## State of the play session, kept in memory while the game is open. The hero, the
## inventory, the gold and the village quest live here for the whole session; battles
## and dialogue change them in place.

var hero: Combatant
var inventory := Inventory.new()
var quest := Quest.new()
## Gold won in battle (shops come in a later phase).
var gold := 0


func _init(hero_data: Combatant) -> void:
	hero = hero_data.duplicate() as Combatant
	# Its own list: learning a spell must never change the one in hero.tres.
	hero.skills = hero_data.skills.duplicate()
	inventory.add(Inventory.POTION, Inventory.START_POTIONS)


## Back to full HP and MP, used after a defeat and when talking to the old woman.
func heal_full() -> void:
	hero.hp = hero.max_hp
	hero.mp = hero.max_mp


## Uses an item outside battle, from the pause menu; see Inventory.use().
func use_item(id: String) -> Dictionary:
	return inventory.use(id, hero, false)
```

- [ ] **Step 10: Edit `scripts/game/save_data.gd`**

1. Replace:

```gdscript
## VERSION goes in every save so a later format can migrate older files.

const VERSION := 1
```

with:

```gdscript
## VERSION goes in every save so a later format can migrate older files. Version 2 (full
## combat) adds the gold and changes how the hero grows, so version 1 saves are refused.
## The spells are not saved: Leveling.sync_skills() gives them back from the level.

const VERSION := 2
```

2. Replace:

```gdscript
		"quest": {"stage": state.quest.stage, "kills": state.quest.kills},
		"position": [player_pos.x, player_pos.z],
```

with:

```gdscript
		"quest": {"stage": state.quest.stage, "kills": state.quest.kills},
		"gold": state.gold,
		"position": [player_pos.x, player_pos.z],
```

3. Replace:

```gdscript
	for field in HERO_FIELDS:
		state.hero.set(field, int(data.hero[field]))
```

with:

```gdscript
	for field in HERO_FIELDS:
		state.hero.set(field, int(data.hero[field]))
	Leveling.sync_skills(state.hero)
	state.gold = int(data.gold)
```

4. Replace:

```gdscript
	var pos: Variant = data.get("position")
```

with:

```gdscript
	if not data.get("gold") is float:
		return false
	var pos: Variant = data.get("position")
```

- [ ] **Step 11: Create `scripts/world/encounter_table.gd` and edit `scripts/world/encounter_meter.gd`**

```gdscript
class_name EncounterTable extends RefCounted
## Which enemies a random encounter brings, per zone (only zone 1 for now: the meadow).
## Within START_RADIUS of WorldStage.SPAWN_POS only slimes come, alone or in pairs;
## elsewhere every formation of the zone has the same weight. Pure: no nodes.

const SLIME := preload("res://data/slime.tres")
const BAT := preload("res://data/bat.tres")
const MUSHROOM := preload("res://data/mushroom.tres")
const START_RADIUS := 20.0
const START_FORMATIONS := [[SLIME], [SLIME, SLIME]]
## zone -> formations (each a list of enemy data, left to right).
const ZONES := {
	1: [[SLIME], [SLIME], [BAT], [MUSHROOM], [SLIME, SLIME], [SLIME, BAT]],
}


static func near_start(pos: Vector3) -> bool:
	return Vector2(pos.x, pos.z).distance_to(
		Vector2(WorldStage.SPAWN_POS.x, WorldStage.SPAWN_POS.z)) < START_RADIUS


## The enemy data of one encounter at pos in zone (not duplicated: BattleScene does it).
static func pick(zone: int, pos: Vector3, rng: RandomNumberGenerator) -> Array[Combatant]:
	var formations: Array = START_FORMATIONS if near_start(pos) else ZONES[zone]
	var picked: Array[Combatant] = []
	picked.assign(formations[rng.randi_range(0, formations.size() - 1)])
	return picked
```

In `scripts/world/encounter_meter.gd`:

1. Replace:

```gdscript
const GRACE_M := 5.0
const CHANCE_PER_M := 0.08
```

with:

```gdscript
const GRACE_M := 15.0
const CHANCE_PER_M := 0.006
```

- [ ] **Step 12: Spells**

Replace `data/skills/llama.tres`:

```ini
[gd_resource type="Resource" script_class="Skill" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/battle/skill.gd" id="1_skill"]

[resource]
script = ExtResource("1_skill")
id = "llama"
display_name = "Llama"
mp_cost = 3
power = 16
color = Color(1, 0.45, 0.1, 1)
element = "fire"
kind = "damage"
targets = "one"
status = ""
status_chance = 0.0
```

Replace `data/skills/aplastar.tres`:

```ini
[gd_resource type="Resource" script_class="Skill" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/battle/skill.gd" id="1_skill"]

[resource]
script = ExtResource("1_skill")
id = "aplastar"
display_name = "Aplastar"
mp_cost = 4
power = 19
color = Color(1, 0.85, 0.3, 1)
element = ""
kind = "damage"
targets = "one"
status = ""
status_chance = 0.0
```

Create `data/skills/curar.tres`:

```ini
[gd_resource type="Resource" script_class="Skill" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/battle/skill.gd" id="1_skill"]

[resource]
script = ExtResource("1_skill")
id = "curar"
display_name = "Curar"
mp_cost = 3
power = 30
color = Color(0.3, 1, 0.4, 1)
element = ""
kind = "heal"
targets = "one"
status = ""
status_chance = 0.0
```

Create `data/skills/llamarada.tres`:

```ini
[gd_resource type="Resource" script_class="Skill" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/battle/skill.gd" id="1_skill"]

[resource]
script = ExtResource("1_skill")
id = "llamarada"
display_name = "Llamarada"
mp_cost = 6
power = 28
color = Color(1, 0.3, 0.05, 1)
element = "fire"
kind = "damage"
targets = "all"
status = ""
status_chance = 0.0
```

Create `data/skills/rayo.tres`:

```ini
[gd_resource type="Resource" script_class="Skill" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/battle/skill.gd" id="1_skill"]

[resource]
script = ExtResource("1_skill")
id = "rayo"
display_name = "Rayo"
mp_cost = 8
power = 70
color = Color(0.6, 0.85, 1, 1)
element = "thunder"
kind = "damage"
targets = "one"
status = ""
status_chance = 0.0
```

Create `data/skills/curar_mas.tres`:

```ini
[gd_resource type="Resource" script_class="Skill" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/battle/skill.gd" id="1_skill"]

[resource]
script = ExtResource("1_skill")
id = "curar_mas"
display_name = "Curar+"
mp_cost = 7
power = 90
color = Color(0.5, 1, 0.6, 1)
element = ""
kind = "heal"
targets = "one"
status = ""
status_chance = 0.0
```

Create `data/skills/esporas.tres`:

```ini
[gd_resource type="Resource" script_class="Skill" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/battle/skill.gd" id="1_skill"]

[resource]
script = ExtResource("1_skill")
id = "esporas"
display_name = "Esporas"
mp_cost = 2
power = 10
color = Color(0.75, 0.6, 0.95, 1)
element = ""
kind = "damage"
targets = "one"
status = "sleep"
status_chance = 0.3
```

- [ ] **Step 13: Hero and enemies**

Replace `data/hero.tres`:

```ini
[gd_resource type="Resource" script_class="Combatant" load_steps=8 format=3]

[ext_resource type="Script" path="res://scripts/battle/combatant.gd" id="1_combatant"]
[ext_resource type="Script" path="res://scripts/battle/skill.gd" id="2_skill"]
[ext_resource type="Resource" path="res://data/skills/llama.tres" id="3_llama"]
[ext_resource type="Resource" path="res://data/skills/curar.tres" id="4_curar"]
[ext_resource type="Resource" path="res://data/skills/llamarada.tres" id="5_llamarada"]
[ext_resource type="Resource" path="res://data/skills/rayo.tres" id="6_rayo"]
[ext_resource type="Resource" path="res://data/skills/curar_mas.tres" id="7_curar_mas"]

[resource]
script = ExtResource("1_combatant")
id = "hero"
display_name = "Héroe"
level = 1
max_hp = 30
hp = 30
max_mp = 6
mp = 6
attack = 10
defense = 5
equip_attack = 2
equip_defense = 2
speed = 8
skills = Array[ExtResource("2_skill")]([ExtResource("3_llama")])
learn = {
3: ExtResource("4_curar"),
7: ExtResource("5_llamarada"),
10: ExtResource("6_rayo"),
11: ExtResource("7_curar_mas")
}
```

Replace `data/slime.tres`:

```ini
[gd_resource type="Resource" script_class="Combatant" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/battle/combatant.gd" id="1_combatant"]

[resource]
script = ExtResource("1_combatant")
id = "slime"
display_name = "Slime"
max_hp = 24
hp = 24
attack = 7
defense = 3
speed = 5
exp_reward = 4
gold_reward = 3
ai_weights = {
"attack": 80,
"stagger": 20
}
weak = Array[String](["fire"])
drops = {
"potion": 0.2
}
```

Create `data/bat.tres`:

```ini
[gd_resource type="Resource" script_class="Combatant" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/battle/combatant.gd" id="1_combatant"]

[resource]
script = ExtResource("1_combatant")
id = "bat"
display_name = "Murciélago"
max_hp = 26
hp = 26
attack = 10
defense = 2
speed = 12
exp_reward = 5
gold_reward = 4
weak = Array[String](["thunder"])
drops = {
"antidote": 0.15
}
attack_status = "poison"
attack_status_chance = 0.2
```

Create `data/mushroom.tres`:

```ini
[gd_resource type="Resource" script_class="Combatant" load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/battle/combatant.gd" id="1_combatant"]
[ext_resource type="Script" path="res://scripts/battle/skill.gd" id="2_skill"]
[ext_resource type="Resource" path="res://data/skills/esporas.tres" id="3_esporas"]

[resource]
script = ExtResource("1_combatant")
id = "mushroom"
display_name = "Seta saltarina"
female = true
max_hp = 43
hp = 43
max_mp = 4
mp = 4
attack = 11
defense = 5
speed = 4
skills = Array[ExtResource("2_skill")]([ExtResource("3_esporas")])
exp_reward = 6
gold_reward = 5
ai_weights = {
"attack": 70,
"esporas": 30
}
weak = Array[String](["fire"])
drops = {
"ether": 0.1
}
```

Replace `data/rey_slime.tres`:

```ini
[gd_resource type="Resource" script_class="Combatant" load_steps=5 format=3]

[ext_resource type="Script" path="res://scripts/battle/combatant.gd" id="1_combatant"]
[ext_resource type="Script" path="res://scripts/battle/skill.gd" id="2_skill"]
[ext_resource type="Resource" path="res://data/skills/aplastar.tres" id="3_aplastar"]
[ext_resource type="Resource" path="res://data/slime.tres" id="4_slime"]

[resource]
script = ExtResource("1_combatant")
id = "rey_slime"
display_name = "Rey Slime"
max_hp = 142
hp = 142
max_mp = 12
mp = 12
attack = 17
defense = 8
speed = 7
skills = Array[ExtResource("2_skill")]([ExtResource("3_aplastar")])
exp_reward = 40
gold_reward = 60
ai_weights = {
"aplastar": 30,
"attack": 60,
"stagger": 10
}
weak = Array[String](["thunder"])
help = ExtResource("4_slime")
is_boss = true
```

- [ ] **Step 14: Import and check**

```powershell
.\tools\godot.cmd --headless --path . --import
foreach ($s in "battle/combatant","battle/skill","battle/battle_event","battle/battle_engine","battle/battle_autoplay","game/inventory","game/leveling","game/game_state","game/save_data","world/encounter_table","world/encounter_meter") { .\tools\godot.cmd --headless --path . --check-only --script "res://scripts/$s.gd" }
```

Expected: `--import` prints parse errors only for `battle_hud.gd`, `battle_scene.gd`, `game.gd` and `pause_menu.gd` (old API until Tasks 2-4), plus a "Failed to compile depended scripts" for a script that uses them; the eleven `--check-only` runs print no errors or warnings.

- [ ] **Step 15: One-off balance check (temporary file at the project root)**

Create `balance_check.gd`:

```gdscript
extends SceneTree
## One-off balance check for the combate completo plan (Task 1). Not committed: delete
## it after reading the output. Plays BATTLES battles per line with the real
## BattleEngine and BattleAutoplay (fixed seed) and prints the win rate, the HP lost by
## the winners (share of max HP) and the rounds. "+gear" adds the zone 1 shop equipment
## (+6 ATK, +8 DEF), which the balance targets assume from the middle of the zone on.

const HERO := preload("res://data/hero.tres")
const BOSS := preload("res://data/rey_slime.tres")
const BATTLES := 4000

var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.seed = 12345
	for gear: Array in [[0, 0], [6, 8]]:
		var tag := "+gear" if gear[0] > 0 else "start gear"
		_report("Lv1 near start, %s" % tag, 1, gear, EncounterTable.START_FORMATIONS, 0)
		for level in [2, 3, 5]:
			_report("Lv%d zone 1, %s" % [level, tag], level, gear, EncounterTable.ZONES[1], 0)
		for level in [3, 4, 5, 6]:
			_report("Lv%d Rey Slime, 3 potions, %s" % [level, tag], level, gear,
				[[BOSS]], 3)
	quit()


func _hero(level: int, gear: Array) -> Combatant:
	var hero := HERO.duplicate() as Combatant
	hero.skills = HERO.skills.duplicate()
	hero.experience = Leveling.EXP_TABLE[level - 1]
	Leveling.apply(hero)
	hero.hp = hero.max_hp
	hero.mp = hero.max_mp
	hero.equip_attack += gear[0]
	hero.equip_defense += gear[1]
	return hero


func _report(label: String, level: int, gear: Array, formations: Array, potions: int) -> void:
	var wins := 0
	var lost := 0.0
	var rounds := 0
	for n in BATTLES:
		var hero := _hero(level, gear)
		var inventory := Inventory.new()
		inventory.add(Inventory.POTION, potions)
		var enemies: Array[Combatant] = []
		for data: Combatant in formations[_rng.randi_range(0, formations.size() - 1)]:
			enemies.append(data.duplicate() as Combatant)
		var engine := BattleEngine.new(hero, enemies, _rng, inventory)
		var bot := BattleAutoplay.new()
		var played := 0
		while engine.state == BattleEngine.State.ONGOING and played < 100:
			engine.resolve_round(bot.choose(engine))
			played += 1
		if engine.state == BattleEngine.State.WON:
			wins += 1
			lost += float(hero.max_hp - hero.hp) / hero.max_hp
			rounds += played
	print("%-36s wins %5.1f %%  HP lost %3.0f %%  rounds %4.1f" % [label,
		100.0 * wins / BATTLES, 100.0 * lost / maxi(1, wins), float(rounds) / maxi(1, wins)])
```

Run it, compare, delete it:

```powershell
.\tools\godot.cmd --headless --path . --script res://balance_check.gd
Remove-Item balance_check.gd, balance_check.gd.uid -ErrorAction SilentlyContinue
```

Expected (the seed is fixed, so the numbers should match exactly; anything more than one point away means the rules differ from this plan):

```
Lv1 near start, start gear           wins  99.8 %  HP lost  16 %  rounds  2.1
Lv2 zone 1, start gear               wins  95.4 %  HP lost  25 %  rounds  2.3
Lv3 zone 1, start gear               wins  99.8 %  HP lost  20 %  rounds  2.4
Lv5 zone 1, start gear               wins 100.0 %  HP lost  17 %  rounds  2.9
Lv3 Rey Slime, 3 potions, start gear wins  12.8 %  HP lost  45 %  rounds 20.1
Lv4 Rey Slime, 3 potions, start gear wins  47.5 %  HP lost  38 %  rounds 18.6
Lv5 Rey Slime, 3 potions, start gear wins  71.9 %  HP lost  43 %  rounds 16.2
Lv6 Rey Slime, 3 potions, start gear wins  88.3 %  HP lost  45 %  rounds 14.4
Lv1 near start, +gear                wins  99.9 %  HP lost  11 %  rounds  3.0
Lv2 zone 1, +gear                    wins  99.2 %  HP lost  19 %  rounds  2.9
Lv3 zone 1, +gear                    wins 100.0 %  HP lost  13 %  rounds  2.9
Lv5 zone 1, +gear                    wins 100.0 %  HP lost   6 %  rounds  2.1
Lv3 Rey Slime, 3 potions, +gear      wins  50.0 %  HP lost  34 %  rounds 14.1
Lv4 Rey Slime, 3 potions, +gear      wins  74.3 %  HP lost  34 %  rounds 12.2
Lv5 Rey Slime, 3 potions, +gear      wins  89.5 %  HP lost  41 %  rounds 10.5
Lv6 Rey Slime, 3 potions, +gear      wins  96.3 %  HP lost  43 %  rounds  9.0
```

- [ ] **Step 16: Commit**

```powershell
git add scripts data
git status --short
git commit -m "Add the full combat rules and the zone 1 enemies"
```

`git status --short` must not list `balance_check.gd`.

---

### Task 2: Enemy figures and the battle HUD

**Files:**
- Modify: `scripts/battle/battle_actor.gd`
- Modify (whole file): `scripts/ui/battle_hud.gd`

**Interfaces:**
- Consumes: `BattleEngine` (`hero`, `inventory`, `alive_enemies()`, `problem()`, `cmd_*`, `POISON` / `SLEEP` / `SILENCE`), `Skill.needs_target()`, `Inventory.IDS` / `ITEMS` / `display_name()`, `SfxLibrary.CURSOR` / `ACCEPT` / `CANCEL`, `AudioDirector`.
- Produces:
  - `BattleActor`: `enum Look { HERO, SLIME, VILLAGER, KING_SLIME, BAT, MUSHROOM }`, `TAG_COLOR`; `top_height() -> float`, `play_hit(amount: int, crit: bool, tag := "")`, `play_burn(amount: int, color := FIRE_COLOR, tag := "")`, `play_heal(amount: int, color := HEAL_COLOR)`, `play_status(color: Color, amount := 0)`, `play_appear()`
  - `BattleHud`: `signal command_chosen(cmd: Dictionary)`, `signal target_changed(index: int)`; `enum Page { NONE, MAIN, SPELLS, ITEMS, TARGET }`; consts `CHAR_TIME`, `MENU_GUARD`, `MENU_WIDTH = 340.0`, `DEMO_STEP = 0.35`, `MAIN_ROWS`, `BADGES`; vars `pick_target: Callable`, `char_time: float`; `set_audio(audio: AudioDirector)`, `set_engine(engine: BattleEngine)`, `update_level(level: int)`, `update_hp(hp: int, max_hp: int)`, `update_mp(mp: int, max_mp: int)`, `update_status(status: Dictionary)`, `show_menu()`, `hide_menu()`, `demo(cmd: Dictionary)` (awaitable), `show_message(text: String)` (awaitable), `static make_window() -> PanelContainer`. `set_hero()` and `set_potions()` are gone.

- [ ] **Step 1: Edit `scripts/battle/battle_actor.gd`**

1. Replace:

```gdscript
## 3D figure of a fighter or a villager. The hero and the old woman are KayKit models
## with their own animations; the slimes are faceted low-poly blobs built in code (see
## LOOKS). Set look before add_child. The figure faces -Z, so look_at() the opponent.
## Every play_* can be awaited: it returns when its animation and its tween are done.

enum Look { HERO, SLIME, VILLAGER, KING_SLIME }
```

with:

```gdscript
## 3D figure of a fighter or a villager. The hero and the old woman are KayKit models
## with their own animations; the slimes, the bat and the mushroom are low-poly figures
## built in code (see LOOKS). Set look before add_child. The figure faces -Z, so
## look_at() the opponent. Every play_* can be awaited: it returns when its animation
## and its tween are done.

enum Look { HERO, SLIME, VILLAGER, KING_SLIME, BAT, MUSHROOM }
```

2. Replace:

```gdscript
const HEAL_COLOR := Color(0.3, 1.0, 0.4)
```

with:

```gdscript
const HEAL_COLOR := Color(0.3, 1.0, 0.4)
## Color of the "¡Débil!" / "¡Resiste!" line under a damage number.
const TAG_COLOR := Color(1.0, 0.6, 0.2)
```

3. Replace:

```gdscript
## damage numbers), hide (prop nodes of the model to hide) and anims. Slimes: color,
## scale (the whole blob, eyes and crown included), top and crown.
```

with:

```gdscript
## damage numbers), hide (prop nodes of the model to hide) and anims. Slimes: color,
## scale (the whole blob, eyes and crown included), top and crown. Bat: color, wing
## color, top and fly (height it hovers at). Mushroom: cap and stem colors, scale and top.
```

4. Replace:

```gdscript
		"top": 2.1,
		"crown": true,
	},
}
```

with:

```gdscript
		"top": 2.1,
		"crown": true,
	},
	Look.BAT: {
		"color": Color(0.32, 0.22, 0.42),
		"wing_color": Color(0.2, 0.13, 0.28),
		"top": 2.0,
		"fly": 1.1,
	},
	Look.MUSHROOM: {
		"cap_color": Color(0.85, 0.2, 0.15),
		"stem_color": Color(0.95, 0.9, 0.78),
		"scale": 1.4,
		"top": 1.6,
	},
}
```

5. Replace:

```gdscript
var _idle_tween: Tween
```

with:

```gdscript
var _idle_tween: Tween
## Bat only: the two wing pivots, flapped by the idle loop.
var _wings: Array[Node3D] = []
```

6. Replace:

```gdscript
	if data.has("scene"):
		_build_character(data)
	else:
		_build_slime(data)
```

with:

```gdscript
	if data.has("scene"):
		_build_character(data)
	elif look == Look.BAT:
		_build_bat(data)
	elif look == Look.MUSHROOM:
		_build_mushroom(data)
	else:
		_build_slime(data)
```

7. Replace:

```gdscript
	if _anim:
		_anim.play(_anims.idle, 0.0)
	else:
		_start_bounce()
```

with:

```gdscript
	if _anim:
		_anim.play(_anims.idle, 0.0)
	else:
		_start_idle()
```

8. Replace:

```gdscript
## Hit animation, white flash, small knockback and a floating damage number.
func play_hit(amount: int, crit: bool) -> void:
	_spawn_number(amount, crit)
```

with:

```gdscript
## Height of the top of the figure (where the damage numbers start).
func top_height() -> float:
	return _top


## Hit animation, white flash, small knockback and a floating damage number; tag
## ("¡Débil!", "¡Resiste!") floats under the number.
func play_hit(amount: int, crit: bool, tag := "") -> void:
	_spawn_number(amount, crit, Color.WHITE, tag)
```

9. Replace:

```gdscript
func play_burn(amount: int, color := FIRE_COLOR) -> void:
```

with:

```gdscript
func play_burn(amount: int, color := FIRE_COLOR, tag := "") -> void:
```

10. Replace:

```gdscript
	await play_hit(amount, false)
```

with:

```gdscript
	await play_hit(amount, false, tag)
```

11. Replace:

```gdscript
## Green glow and a green number going up.
func play_heal(amount: int) -> void:
	_spawn_number(amount, false, HEAL_COLOR)
	_set_flash(true, HEAL_COLOR)
	await get_tree().create_timer(0.35).timeout
	_set_flash(false)
```

with:

```gdscript
## Glow and a number going up, green by default (HP); an MP heal passes its own color.
func play_heal(amount: int, color := HEAL_COLOR) -> void:
	_spawn_number(amount, false, color)
	_set_flash(true, color)
	await get_tree().create_timer(0.35).timeout
	_set_flash(false)


## Glow in a status color (poison, sleep, defend...); amount > 0 also floats a number of
## that color (poison damage).
func play_status(color: Color, amount := 0) -> void:
	if amount > 0:
		_spawn_number(amount, false, color)
	_set_flash(true, color)
	await get_tree().create_timer(0.35).timeout
	_set_flash(false)


## Grows from nothing where it stands (an enemy called for help).
func play_appear() -> void:
	if _idle_tween:
		_idle_tween.kill()
	_body.scale = Vector3.ONE * 0.05
	var t := create_tween()
	t.tween_property(_body, "scale", Vector3.ONE, 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await t.finished
	_start_idle()
```

12. Replace:

```gdscript
## Squash-and-stretch loop of the slimes while they wait.
func _start_bounce() -> void:
```

with:

```gdscript
## A bat: round body with ears and eyes, hovering at data.fly, with two wings on pivots
## that the idle loop flaps.
func _build_bat(data: Dictionary) -> void:
	var color: Color = data.color
	var root := Node3D.new()
	root.position.y = data.fly
	_body.add_child(root)
	_add_mesh(root, _sphere(0.32), color, Vector3.ZERO, 0.7)
	for x in [-0.14, 0.14]:
		_add_mesh(root, _cone(0.08, 0.22), color, Vector3(x, 0.36, 0))  # ear
		_add_mesh(root, _sphere(0.08), Color(1.0, 0.85, 0.3), Vector3(x * 0.9, 0.08, -0.27))  # eye
		_add_mesh(root, _sphere(0.035), Color(0.05, 0.05, 0.05),
			Vector3(x * 0.9, 0.08, -0.34))  # pupil
	for side in [-1.0, 1.0]:
		var pivot := Node3D.new()
		pivot.position = Vector3(0.22 * side, 0.05, 0)
		root.add_child(pivot)
		var wing := BoxMesh.new()
		wing.size = Vector3(0.75, 0.04, 0.42)
		_add_mesh(pivot, wing, data.wing_color, Vector3(0.38 * side, 0, 0.05))
		_wings.append(pivot)


## A mushroom: pale stem with eyes and a red hemisphere cap with white spots.
func _build_mushroom(data: Dictionary) -> void:
	var root := Node3D.new()
	root.scale = Vector3.ONE * data.scale
	_body.add_child(root)
	var stem := _cylinder(0.2, 0.55)
	stem.top_radius = 0.16
	_add_mesh(root, stem, data.stem_color, Vector3(0, 0.275, 0))
	for x in [-0.08, 0.08]:
		_add_mesh(root, _sphere(0.05), Color(0.05, 0.05, 0.05), Vector3(x, 0.32, -0.18))  # eye
	var cap := SphereMesh.new()
	cap.radius = 0.5
	cap.height = 0.42
	cap.is_hemisphere = true
	cap.radial_segments = 9
	cap.rings = 3
	_add_mesh(root, cap, data.cap_color, Vector3(0, 0.5, 0), 0.6)
	for i in 5:
		var angle := TAU * i / 5.0 + 0.3
		_add_mesh(root, _sphere(0.07), Color.WHITE,
			Vector3(cos(angle) * 0.3, 0.75, sin(angle) * 0.3))  # spot
	_add_mesh(root, _sphere(0.08), Color.WHITE, Vector3(0, 0.92, 0))  # top spot


## The waiting loop of the figures built in code: the bat flaps, the rest squash and
## stretch.
func _start_idle() -> void:
	if _wings.is_empty():
		_start_bounce()
	else:
		_start_flap()


## Flapping wings and a slow bob up and down, for the bat.
func _start_flap() -> void:
	if _idle_tween:
		_idle_tween.kill()
	_idle_tween = create_tween().set_loops()
	for angle in [0.6, -0.4]:
		_idle_tween.tween_property(_wings[0], "rotation:z", -angle, 0.18) \
			.set_trans(Tween.TRANS_SINE)
		_idle_tween.parallel().tween_property(_wings[1], "rotation:z", angle, 0.18) \
			.set_trans(Tween.TRANS_SINE)
		_idle_tween.parallel().tween_property(_body, "position:y",
			0.08 if angle > 0.0 else 0.0, 0.18).set_trans(Tween.TRANS_SINE)


## Squash-and-stretch loop of the slimes while they wait.
func _start_bounce() -> void:
```

13. Replace:

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

with:

```gdscript
func _spawn_number(amount: int, crit: bool, color := Color.WHITE, tag := "") -> void:
	if tag != "":
		_float_label(tag, 40, TAG_COLOR, _top - 0.3)
	_float_label(str(amount), 96 if crit else 64, Color(1.0, 0.85, 0.2) if crit else color,
		_top)


## A billboard text drawn over everything that floats up from height y and fades out.
func _float_label(text: String, font_size: int, color: Color, y: float) -> void:
	var label := Label3D.new()
	label.text = text
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.pixel_size = 0.005
	label.font_size = font_size
	label.outline_size = 16
	label.modulate = color
	label.position = Vector3(0, y, 0)
	add_child(label)
	var t := label.create_tween().set_parallel()
	t.tween_property(label, "position:y", y + 0.8, 0.9)
	t.tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.3)
	t.chain().tween_callback(label.queue_free)
```

- [ ] **Step 2: Replace `scripts/ui/battle_hud.gd`**

How it works: `_open(page, cursor)` rebuilds the rows of the command window; `_input()` reads every key before the buttons do and marks it handled, so W / S and the arrows move the same cursor and the focus never jumps on its own; `_unhandled_input()` gets the clicks no row took (advance a message, aim, go back). Rows that can't be used are disabled (out of the focus chain, clicks pass through) and say why.

```gdscript
class_name BattleHud extends Control
## Dragon Quest style battle UI: hero status (top left: name and level, PV and status
## badges, PV bar, PM), command window and message window (bottom). Main menu: Atacar,
## Hechizos, Objetos, Defender, Huir; Hechizos and Objetos open a list where a row that
## can't be used is grey and says why. With two enemies standing, Atacar and one-target
## spells ask for the target: target_changed tells the scene where to put the arrow.
## Keyboard: W / S or up / down move, A / D or left / right change the target,
## Enter / Space / E accept, Esc / Q / Backspace / X go back. Mouse and touch: click a
## row; click an enemy to aim and click it again to confirm; a click anywhere else goes
## back. Choices are ignored for MENU_GUARD seconds after the menu opens, so a press
## meant to skip a message never picks a command. show_message() can be awaited: it
## types the text out (char_time seconds per character) and returns when the player
## advances (click, Enter, Space, E) or after a short auto-advance. With set_audio()
## moving, choosing and going back make a sound.

signal command_chosen(cmd: Dictionary)
## Enemy index the target arrow points at, or -1 to hide it.
signal target_changed(index: int)

enum Page { NONE, MAIN, SPELLS, ITEMS, TARGET }

const CHAR_TIME := 0.025
const AUTO_ADVANCE := 0.6
const MENU_GUARD := 0.3
const FONT_SIZE := 24
const BADGE_FONT_SIZE := 16
## Width of the command window, wide enough for every row, so the message window next
## to it keeps its size whichever list is open.
const MENU_WIDTH := 340.0
## Seconds each step of demo() stays on screen.
const DEMO_STEP := 0.35
const MAIN_ROWS: Array[String] = ["Atacar", "Hechizos", "Objetos", "Defender", "Huir"]
## Main menu row of each command type.
const MAIN_ROW_OF := {
	BattleEngine.CMD_ATTACK: 0,
	BattleEngine.CMD_SKILL: 1,
	BattleEngine.CMD_ITEM: 2,
	BattleEngine.CMD_DEFEND: 3,
	BattleEngine.CMD_FLEE: 4,
}
## Badge text and color of each status, shown next to the PV.
const BADGES := {
	BattleEngine.POISON: ["Veneno", Color(0.5, 0.2, 0.65)],
	BattleEngine.SLEEP: ["Sueño", Color(0.2, 0.35, 0.8)],
	BattleEngine.SILENCE: ["Silencio", Color(0.4, 0.4, 0.45)],
}

## Returns the enemy index under a screen point, or -1. Set by BattleScene.
var pick_target: Callable
## Seconds per typed character (the text speed option).
var char_time := CHAR_TIME

var _engine: BattleEngine
var _name_label: Label
var _hp_label: Label
var _badges: HBoxContainer
var _hp_bar: ProgressBar
var _mp_label: Label
var _menu: PanelContainer
var _list: VBoxContainer
var _message: Label
var _hp_fill := StyleBoxFlat.new()
var _audio: AudioDirector
var _page := Page.NONE
## Buttons of the open list and the one under the cursor.
var _rows: Array[Button] = []
var _cursor := 0
## Row of the main menu to go back to from a list.
var _main_cursor := 0
## Command waiting for its target, the page to go back to, the enemies to choose from
## and the one aimed at.
var _pending := {}
var _target_back := Page.MAIN
var _target_back_cursor := 0
var _targets: Array[int] = []
var _target_i := 0
var _menu_opened_ms := 0
var _advance_requested := false
## True while the code moves the cursor itself, so that move makes no sound.
var _quiet_focus := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_status()
	_build_bottom()
	hide_menu()


func set_audio(audio: AudioDirector) -> void:
	_audio = audio


## The battle to show and command; also fills the status window.
func set_engine(engine: BattleEngine) -> void:
	_engine = engine
	var hero := engine.hero
	update_level(hero.level)
	update_hp(hero.hp, hero.max_hp)
	update_mp(hero.mp, hero.max_mp)
	update_status(hero.status)


func update_level(level: int) -> void:
	_name_label.text = "%s  Nv %d" % [_engine.hero.display_name, level]


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


## One colored badge per status the hero has.
func update_status(status: Dictionary) -> void:
	for child in _badges.get_children():
		child.queue_free()
	for id: String in BADGES:
		if status.has(id):
			_badges.add_child(_badge(BADGES[id][0], BADGES[id][1]))


## Opens the main menu. The menu keeps its layout slot while hidden (it only fades out),
## so the message window never resizes.
func show_menu() -> void:
	_menu_opened_ms = Time.get_ticks_msec()
	_menu.modulate.a = 1.0
	_main_cursor = 0
	_open(Page.MAIN, 0)


func hide_menu() -> void:
	if _page == Page.TARGET:
		target_changed.emit(-1)
	_page = Page.NONE
	_menu.modulate.a = 0.0
	for row in _rows:
		_set_enabled(row, false)


## Autoplay: walks the menus to cmd as a player would (main row, list row, target) with
## a short pause on each step, then closes the menu without emitting anything.
func demo(cmd: Dictionary) -> void:
	if not MAIN_ROW_OF.has(cmd.type):
		return
	show_menu()
	_set_cursor(MAIN_ROW_OF[cmd.type])
	await get_tree().create_timer(DEMO_STEP).timeout
	var back := Page.MAIN
	if cmd.type == BattleEngine.CMD_SKILL:
		_main_cursor = _cursor
		_open(Page.SPELLS, _engine.hero.skills.find(cmd.skill))
		back = Page.SPELLS
		await get_tree().create_timer(DEMO_STEP).timeout
	elif cmd.type == BattleEngine.CMD_ITEM:
		_main_cursor = _cursor
		_open(Page.ITEMS, _item_ids().find(cmd.item))
		await get_tree().create_timer(DEMO_STEP).timeout
	if _needs_target(cmd):
		_ask_target(cmd, back)
		_aim_at(_targets.find(cmd.target))
		await get_tree().create_timer(DEMO_STEP * 2.0).timeout
	hide_menu()


func show_message(text: String) -> void:
	_message.text = text
	_message.visible_characters = 0
	_advance_requested = false
	var total := _message.get_total_character_count()
	var shown := 0.0
	while _message.visible_characters < total and not _advance_requested:
		await get_tree().process_frame
		shown += get_process_delta_time() / char_time
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


## Every key of the menus is read here, before the buttons see it, so WASD and the
## arrows behave the same and the focus never moves on its own.
func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if _page == Page.NONE or key == null or not key.pressed:
		return
	match key.physical_keycode:
		KEY_W, KEY_UP:
			_move(-1)
		KEY_S, KEY_DOWN:
			_move(1)
		KEY_A, KEY_LEFT:
			_aim(-1)
		KEY_D, KEY_RIGHT:
			_aim(1)
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_E:
			if not key.echo:
				_accept()
		KEY_ESCAPE, KEY_Q, KEY_BACKSPACE, KEY_X:
			if not key.echo:
				_back()
		_:
			return
	get_viewport().set_input_as_handled()


## Clicks that no row took: advance a message, aim or go back.
func _unhandled_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	var click := mouse != null and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT
	match _page:
		Page.NONE:
			var key := event as InputEventKey
			var e_key := key != null and key.pressed and not key.echo \
				and key.physical_keycode == KEY_E
			if click or e_key or event.is_action_pressed("ui_accept"):
				_advance_requested = true
		Page.SPELLS, Page.ITEMS:
			if click:
				_back()
		Page.TARGET:
			if not click:
				return
			var index: int = pick_target.call(mouse.position) if pick_target.is_valid() else -1
			if index >= 0 and index == _targets[_target_i]:
				_accept()
			elif index in _targets:
				_aim_at(_targets.find(index))
			else:
				_back()


## Fills the window with the rows of page and puts the cursor on row cursor.
func _open(page: Page, cursor: int) -> void:
	_page = page
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	_rows.clear()
	_cursor = 0
	match page:
		Page.MAIN:
			for text in MAIN_ROWS:
				_add_row(text, true)
			_message.text = "¿Qué hará %s?" % _engine.hero.display_name
		Page.SPELLS:
			for skill in _engine.hero.skills:
				var why := _engine.problem(BattleEngine.cmd_skill(skill))
				_add_row(_with_reason("%s  %d PM" % [skill.display_name, skill.mp_cost], why),
					why == "")
			_message.text = "¿Qué hechizo?"
		Page.ITEMS:
			for id in _item_ids():
				var why := _engine.problem(BattleEngine.cmd_item(id))
				_add_row(_with_reason("%s ×%d" % [Inventory.display_name(id),
					_engine.inventory.count(id)], why), why == "")
			if _rows.is_empty():
				_list.add_child(_label("No llevas objetos."))
			_message.text = "¿Qué objeto?"
	_message.visible_characters = -1
	_set_cursor(cursor)


## Items in stock that can be used in battle, in Inventory.IDS order.
func _item_ids() -> Array[String]:
	var ids: Array[String] = []
	for id in Inventory.IDS:
		if _engine.inventory.count(id) > 0 and Inventory.ITEMS[id].battle:
			ids.append(id)
	return ids


func _with_reason(text: String, why: String) -> String:
	return text if why == "" else "%s  (%s)" % [text, why]


func _add_row(text: String, enabled: bool) -> void:
	var button := Button.new()
	button.text = text
	button.flat = true
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	button.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.55))
	var index := _rows.size()
	button.pressed.connect(func() -> void: _press(index))
	button.focus_entered.connect(func() -> void: _on_focus(index))
	_list.add_child(button)
	_set_enabled(button, enabled)
	_rows.append(button)


## Moves the cursor to row i, or to the nearest enabled row after it (wrapping).
func _set_cursor(i: int) -> void:
	if _rows.is_empty():
		return
	for step in _rows.size():
		var row := (maxi(i, 0) + step) % _rows.size()
		if not _rows[row].disabled:
			_quiet_focus = true
			_cursor = row
			_rows[row].grab_focus()
			_quiet_focus = false
			return


func _move(delta: int) -> void:
	if _page == Page.TARGET or _rows.is_empty():
		return
	var row := _cursor
	for step in _rows.size():
		row = (row + delta + _rows.size()) % _rows.size()
		if not _rows[row].disabled:
			_rows[row].grab_focus()
			return


func _on_focus(index: int) -> void:
	_cursor = index
	if not _quiet_focus:
		_sfx(SfxLibrary.CURSOR)


func _accept() -> void:
	if _page == Page.TARGET:
		var cmd := _pending.duplicate()
		cmd.target = _targets[_target_i]
		_choose(cmd)
	elif not _rows.is_empty() and not _rows[_cursor].disabled:
		_press(_cursor)


## What a row does, on its page.
func _press(index: int) -> void:
	if _page == Page.NONE or Time.get_ticks_msec() - _menu_opened_ms < MENU_GUARD * 1000.0:
		return
	var first: int = _engine.alive_enemies()[0]
	match _page:
		Page.MAIN:
			_main_cursor = index
			match index:
				0:
					_choose_or_aim(BattleEngine.cmd_attack(first), Page.MAIN)
				1:
					_sfx(SfxLibrary.ACCEPT)
					_open(Page.SPELLS, 0)
				2:
					_sfx(SfxLibrary.ACCEPT)
					_open(Page.ITEMS, 0)
				3:
					_choose(BattleEngine.cmd_defend())
				4:
					_choose(BattleEngine.cmd_flee())
		Page.SPELLS:
			_choose_or_aim(BattleEngine.cmd_skill(_engine.hero.skills[index], first), Page.SPELLS)
		Page.ITEMS:
			_choose(BattleEngine.cmd_item(_item_ids()[index]))


## Chooses cmd, or first asks for its target when there are two enemies to pick from.
func _choose_or_aim(cmd: Dictionary, back: Page) -> void:
	if _needs_target(cmd):
		_sfx(SfxLibrary.ACCEPT)
		_ask_target(cmd, back)
	else:
		_choose(cmd)


func _needs_target(cmd: Dictionary) -> bool:
	if _engine.alive_enemies().size() < 2:
		return false
	return cmd.type == BattleEngine.CMD_ATTACK \
		or (cmd.type == BattleEngine.CMD_SKILL and (cmd.skill as Skill).needs_target())


func _ask_target(cmd: Dictionary, back: Page) -> void:
	_pending = cmd
	_target_back = back
	_target_back_cursor = _cursor
	_targets = _engine.alive_enemies()
	_page = Page.TARGET
	_message.text = "¿A quién?"
	_message.visible_characters = -1
	_aim_at(0)


func _aim(delta: int) -> void:
	if _page == Page.TARGET:
		_aim_at((_target_i + delta + _targets.size()) % _targets.size())


func _aim_at(i: int) -> void:
	_target_i = clampi(i, 0, _targets.size() - 1)
	target_changed.emit(_targets[_target_i])
	_sfx(SfxLibrary.CURSOR)


## One step back: target -> its list, list -> main menu.
func _back() -> void:
	match _page:
		Page.TARGET:
			target_changed.emit(-1)
			_sfx(SfxLibrary.CANCEL)
			_open(_target_back, _target_back_cursor)
		Page.SPELLS, Page.ITEMS:
			_sfx(SfxLibrary.CANCEL)
			_open(Page.MAIN, _main_cursor)


func _choose(cmd: Dictionary) -> void:
	if Time.get_ticks_msec() - _menu_opened_ms < MENU_GUARD * 1000.0:
		return
	hide_menu()
	_sfx(SfxLibrary.ACCEPT)
	command_chosen.emit(cmd)


func _build_status() -> void:
	var panel := make_window()
	panel.position = Vector2(24, 24)
	panel.custom_minimum_size = Vector2(240, 0)
	add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	_name_label = _label()
	box.add_child(_name_label)
	var hp_row := HBoxContainer.new()
	hp_row.add_theme_constant_override("separation", 10)
	box.add_child(hp_row)
	_hp_label = _label()
	hp_row.add_child(_hp_label)
	_badges = HBoxContainer.new()
	_badges.add_theme_constant_override("separation", 4)
	hp_row.add_child(_badges)
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
	row.offset_top = -272
	row.offset_bottom = -24
	row.add_theme_constant_override("separation", 16)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)

	_menu = make_window()
	_menu.custom_minimum_size = Vector2(MENU_WIDTH, 0)
	row.add_child(_menu)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 0)
	_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu.add_child(_list)

	var message_window := make_window()
	message_window.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(message_window)
	_message = _label()
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	message_window.add_child(_message)


## A small colored tag with the status name.
func _badge(text: String, color: Color) -> PanelContainer:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(4)
	style.content_margin_left = 6
	style.content_margin_right = 6
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", BADGE_FONT_SIZE)
	label.add_theme_color_override("font_color", Color.WHITE)
	panel.add_child(label)
	return panel


## Disabled rows also leave the focus chain and let mouse clicks through (so a click over
## the hidden menu still advances messages).
func _set_enabled(button: Button, enabled: bool) -> void:
	button.disabled = not enabled
	button.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
	if not enabled:
		button.release_focus()


func _label(text := "") -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", Color.WHITE)
	return label


func _sfx(id: String) -> void:
	if _audio:
		_audio.play_sfx(id)
```

- [ ] **Step 3: Check**

```powershell
foreach ($s in "battle/battle_actor","ui/battle_hud") { .\tools\godot.cmd --headless --path . --check-only --script "res://scripts/$s.gd" }
```

Expected: no errors or warnings (`battle_scene.gd` still fails until Task 3).

- [ ] **Step 4: Commit**

```powershell
git add scripts/battle/battle_actor.gd scripts/ui/battle_hud.gd
git commit -m "Add bat and mushroom figures and the battle submenus with target choice"
```

---

### Task 3: Battle scene with one or two enemies

**Files:**
- Modify (whole file): `scripts/battle/battle_scene.gd`
- Modify: `scripts/ui/battle_result.gd`

**Interfaces:**
- Consumes: everything of Tasks 1 and 2; `BattleStage.build()`, `MusicLibrary`, `SfxLibrary`, `GameState`, `EncounterTable.SLIME` / `BAT`.
- Produces:
  - `BattleScene`: `signal finished(outcome: int)` (a `BattleEngine.State`: `WON`, `LOST` or `FLED`); `setup(hero_ref: Combatant, enemy_data: Array[Combatant], inv: Inventory)`, `set_audio(audio)`, `char_time`, `engine`, `enemies`; consts `ENEMY_POS`, `PAIR_OFFSET = Vector3(1.5, 0, 0)`, `LOOKS`, `PICK_RADIUS = 120.0`, `AUTOPLAY_EVERY = 5`, `AUTOPLAY_DEFEND_AT = 2`, `STANDALONE_LEVEL = 3`. Run on its own (`res://scenes/battle/battle_scene.tscn`) it builds a test battle and quits at the end, printing `Fin del combate (estado N)`.
  - `BattleResult.show_victory(exp_gained: int, total_exp: int, new_level: int, gold: int, drops: Array[String])`

- [ ] **Step 1: Replace `scripts/battle/battle_scene.gd`**

Messages (all through `_say()`): "¡Aparecen Slime A y Slime B!", "¡Un Murciélago salvaje aparece!" / "¡Una Seta saltarina salvaje aparece!", "¡El Rey Slime te cierra el paso!", "¡Héroe se defiende!", "¡Has huido!", "¡No has podido huir!", "¡No puedes huir!", "¡Es muy eficaz contra el Slime!", "¡El X lo resiste!", "¡Héroe está envenenado!", "¡El veneno quita 3 PV a Héroe!", "¡Héroe ya no está envenenado!", "¡Héroe se ha dormido!", "Héroe está dormido.", "¡Héroe se despierta!", "¡Héroe ya no puede lanzar hechizos!", "¡Héroe puede volver a lanzar hechizos!", "¡El Rey Slime pide ayuda!", "¡Aparece un Slime!", "¡Héroe usa una Poción!", "¡Héroe recupera 15 PM!", "Consigues 7 monedas de oro.", "¡Héroe aprende Curar!", "¡El Slime ha dejado una Poción!", "¡Seta saltarina ha sido derrotada!".

```gdscript
class_name BattleScene extends Node3D
## One battle against one or two enemies: builds the stage, actors, camera, target arrow
## and UI, asks the HUD for the hero's command, lets BattleEngine resolve the round and
## plays the events back. Call setup() before adding it to the tree; it emits
## finished(outcome) (a BattleEngine.State: WON, LOST or FLED) when it is over.
## With `-- --autoplay` BattleAutoplay picks the commands (shown on the HUD with
## BattleHud.demo()); to show Huir and Defender it flees from one normal battle out of
## AUTOPLAY_EVERY and defends in the first round of another one. It prints every battle
## message and continues on its own. With set_audio() it plays the sound effects and
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
## With two enemies, each stands this far to one side of ENEMY_POS.
const PAIR_OFFSET := Vector3(1.5, 0, 0)
const CAMERA_POS := Vector3(0.8, 2.6, 6.0)
const CAMERA_FOV := 50.0
## How far the camera moves toward the target during an attack (0..1).
const CAMERA_FOCUS := 0.18
## Figure of each enemy data id; any other id is a slime.
const LOOKS := {
	"slime": BattleActor.Look.SLIME,
	"bat": BattleActor.Look.BAT,
	"mushroom": BattleActor.Look.MUSHROOM,
	"rey_slime": BattleActor.Look.KING_SLIME,
}
const ARROW_COLOR := Color(1.0, 0.9, 0.3)
## A click this close (pixels) to an enemy aims at it.
const PICK_RADIUS := 120.0
const MP_COLOR := Color(0.4, 0.6, 1.0)
const DEFEND_COLOR := Color(0.6, 0.8, 1.0)
const STATUS_COLORS := {
	BattleEngine.POISON: Color(0.6, 0.2, 0.8),
	BattleEngine.SLEEP: Color(0.35, 0.45, 1.0),
	BattleEngine.SILENCE: Color(0.6, 0.6, 0.65),
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


## The hero and the inventory are used as is, so HP, MP, EXP and items stay with the
## caller; the enemy data is duplicated so the .tres files never change. Two enemies
## with the same name become "Slime A" and "Slime B".
func setup(hero_ref: Combatant, enemy_data: Array[Combatant], inv: Inventory) -> void:
	hero = hero_ref
	inventory = inv
	enemies.clear()
	for data in enemy_data:
		enemies.append(data.duplicate() as Combatant)
	if enemies.size() == 2 and enemies[0].display_name == enemies[1].display_name:
		enemies[0].display_name += " A"
		enemies[1].display_name += " B"


## Call before adding it to the tree, like setup().
func set_audio(audio: AudioDirector) -> void:
	_audio = audio


func _ready() -> void:
	if hero == null and get_parent() == get_tree().root:
		_setup_standalone()
	assert(hero != null and not enemies.is_empty() and inventory != null,
		"Call setup() before adding BattleScene to the tree")
	_rng.randomize()
	_autoplay = OS.get_cmdline_user_args().has("--autoplay")
	BattleStage.build(self)
	_hero_actor = _spawn_actor(BattleActor.Look.HERO, HERO_POS, ENEMY_POS)
	for i in enemies.size():
		_enemy_actors.append(_spawn_actor(LOOKS.get(enemies[i].id, BattleActor.Look.SLIME),
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
	_hud.set_engine(engine)
	if _autoplay and not engine.has_boss():
		_autoplay_battles += 1
		_autoplay_flee = _autoplay_battles % AUTOPLAY_EVERY == 0
		_autoplay_defend = _autoplay_battles % AUTOPLAY_EVERY == AUTOPLAY_DEFEND_AT
	await _say(_intro_text())
	_ask_command()


func _setup_standalone() -> void:
	var state := GameState.new(load("res://data/hero.tres") as Combatant)
	state.hero.experience = Leveling.EXP_TABLE[STANDALONE_LEVEL - 1]
	Leveling.apply(state.hero)
	state.heal_full()
	state.hero.status[BattleEngine.POISON] = -1
	state.inventory.add(Inventory.ANTIDOTE)
	var foes: Array[Combatant] = [EncounterTable.SLIME, EncounterTable.BAT]
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
	return "¡%s %s salvaje aparece!" % ["Una" if first.female else "Un", first.display_name]


## Asleep, the hero does nothing; on autoplay the bot picks; otherwise the menu opens.
func _ask_command() -> void:
	if hero.status.has(BattleEngine.SLEEP):
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
	for event in engine.resolve_round(cmd):
		await _play_event(event)
	match engine.state:
		BattleEngine.State.ONGOING:
			_ask_command()
			return
		BattleEngine.State.FLED:
			_finish()
			return
		BattleEngine.State.WON:
			_result.show_victory(engine.exp_won, hero.experience, _new_level, engine.gold_won,
				engine.drops_won)
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
			await _say("¡%s ataca!" % _fighter(event.actor).display_name)
			_focus_camera(target)
			await _actor(event.actor).play_attack(target.global_position)
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
			if event.target == BattleEvent.HERO:
				_hud.update_hp(event.hp_left, hero.max_hp)
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
		BattleEvent.NO_ESCAPE:
			await _say("¡No puedes huir!")
		BattleEvent.STATUS_ON:
			await _play_status_on(event)
		BattleEvent.STATUS_TICK:
			_sfx(SfxLibrary.HIT)
			await _actor(event.target).play_status(STATUS_COLORS[event.status], event.amount)
			if event.target == BattleEvent.HERO:
				_hud.update_hp(event.hp_left, hero.max_hp)
			await _say("¡El veneno quita %d PV a %s!" % [event.amount,
				_fighter(event.target).display_name])
		BattleEvent.STATUS_OFF:
			await _play_status_off(event)
		BattleEvent.ASLEEP:
			await _actor(event.actor).play_status(STATUS_COLORS[BattleEngine.SLEEP])
			var sleeper := _fighter(event.actor)
			await _say("%s está dormid%s." % [sleeper.display_name, _ending(sleeper)])
		BattleEvent.CALL_HELP:
			await _play_call_help(event)
		BattleEvent.DEFEATED:
			_show_arrow(-1)
			await _actor(event.target).play_defeat()
			if event.target == BattleEvent.HERO:
				_music(MusicLibrary.DEFEAT)
				await _say("¡Has sido derrotado...!")
			else:
				var foe := _fighter(event.target)
				await _say("¡%s ha sido derrotad%s!" % [foe.display_name, _ending(foe)])
		BattleEvent.VICTORY:
			_hero_actor.play_cheer()
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
			await _say("¡%s aprende %s!" % [hero.display_name, event.name])
		BattleEvent.DROP:
			await _say("¡%s ha dejado %s %s!" % [_cap(_the(_fighter(event.owner))),
				Inventory.article(event.item), Inventory.display_name(event.item)])


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
	if event.target == BattleEvent.HERO:
		_hud.update_hp(event.hp_left, hero.max_hp)
	if event.crit:
		await _say("¡Golpe crítico!")
	var target := _fighter(event.target)
	match event.affinity:
		BattleEvent.WEAK:
			await _say("¡Es muy eficaz contra %s!" % _the(target))
		BattleEvent.RESIST:
			await _say("¡%s lo resiste!" % _cap(_the(target)))
	await _say("¡%s recibe %d de daño!" % [target.display_name, event.amount])


func _play_status_on(event: Dictionary) -> void:
	_sfx(SfxLibrary.MISS)
	await _actor(event.target).play_status(STATUS_COLORS[event.status])
	var target := _fighter(event.target)
	if event.target == BattleEvent.HERO:
		_hud.update_status(hero.status)
	match event.status:
		BattleEngine.POISON:
			await _say("¡%s está envenenad%s!" % [target.display_name, _ending(target)])
		BattleEngine.SLEEP:
			await _say("¡%s se ha dormido!" % target.display_name)
		BattleEngine.SILENCE:
			await _say("¡%s ya no puede lanzar hechizos!" % target.display_name)


func _play_status_off(event: Dictionary) -> void:
	var target := _fighter(event.target)
	if event.target == BattleEvent.HERO:
		_hud.update_status(hero.status)
	match event.status:
		BattleEngine.POISON:
			_sfx(SfxLibrary.HEAL)
			await _say("¡%s ya no está envenenad%s!" % [target.display_name, _ending(target)])
		BattleEngine.SLEEP:
			await _say("¡%s se despierta!" % target.display_name)
		BattleEngine.SILENCE:
			await _say("¡%s puede volver a lanzar hechizos!" % target.display_name)


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
	var actor := _spawn_actor(LOOKS.get(helper.id, BattleActor.Look.SLIME), _slot(1, 2),
		HERO_POS)
	_enemy_actors.append(actor)
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


## Ending of the adjectives for c: "a" (envenenada) or "o" (envenenado).
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
	if _arrow_tween:
		_arrow_tween.kill()
		_arrow_tween = null
	if index < 0 or index >= _enemy_actors.size():
		_arrow.hide()
		return
	var actor := _enemy_actors[index]
	_arrow.position = actor.position + Vector3(0, actor.top_height() + 0.1, 0)
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
	return _hero_actor if who == BattleEvent.HERO else _enemy_actors[who]


func _fighter(who: int) -> Combatant:
	return hero if who == BattleEvent.HERO else engine.enemies[who]
```

- [ ] **Step 2: Edit `scripts/ui/battle_result.gd`**

1. Replace:

```gdscript
## End-of-battle overlay: victory or defeat text and a "Continuar" button.
## Starts hidden; the button hides it and emits continue_requested.
```

with:

```gdscript
## End-of-battle overlay: victory (EXP, new level, gold, items left by the enemies) or
## defeat text and a "Continuar" button. Starts hidden; the button hides it and emits
## continue_requested.
```

2. Replace:

```gdscript
## new_level is 0 when the hero did not level up.
func show_victory(exp_gained: int, total_exp: int, new_level := 0, got_potion := false) -> void:
	_title.text = "¡Victoria!"
	var lines := PackedStringArray(["+%d EXP  (total: %d)" % [exp_gained, total_exp]])
	if new_level > 0:
		lines.append("¡Nivel %d!" % new_level)
	if got_potion:
		lines.append("+1 %s" % Inventory.display_name(Inventory.POTION))
```

with:

```gdscript
## new_level is 0 when the hero did not level up; drops holds one item id per item won.
func show_victory(exp_gained: int, total_exp: int, new_level: int, gold: int, \
		drops: Array[String]) -> void:
	_title.text = "¡Victoria!"
	var lines := PackedStringArray(["+%d EXP  (total: %d)" % [exp_gained, total_exp]])
	if new_level > 0:
		lines.append("¡Nivel %d!" % new_level)
	if gold > 0:
		lines.append("+%d G" % gold)
	for id in drops:
		lines.append("+1 %s" % Inventory.display_name(id))
```

- [ ] **Step 3: Check and run the test battle headless**

```powershell
foreach ($s in "battle/battle_scene","ui/battle_result") { .\tools\godot.cmd --headless --path . --check-only --script "res://scripts/$s.gd" }
.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 3000 res://scenes/battle/battle_scene.tscn -- --autoplay
```

Expected: no errors or warnings, then a battle like this one (random, so lines change), ending in `Fin del combate (estado 1)` (`2` if the hero lost, which is rare):

```
¡Aparecen Slime y Murciélago!
¡Murciélago ataca!
¡Héroe recibe 6 de daño!
¡Héroe usa un Antídoto!
¡Héroe ya no está envenenado!
El Slime se tambalea.
¡Héroe lanza Llama!
¡Es muy eficaz contra el Slime!
¡Slime recibe 25 de daño!
¡Slime ha sido derrotado!
...
¡Has ganado! Obtienes 9 EXP.
Consigues 7 monedas de oro.
Fin del combate (estado 1)
```

- [ ] **Step 4: Frames of the test battle**

```powershell
New-Item -ItemType Directory -Force frames | Out-Null
.\tools\godot.cmd --path . --write-movie frames\f.png --fixed-fps 10 --quit-after 400 res://scenes/battle/battle_scene.tscn -- --autoplay
```

Open the frames and check (frame numbers move a little from run to run):
1. Around frames 12-15: the main menu, five rows (Atacar, Hechizos, Objetos, Defender, Huir) inside a window that ends 24 px above the bottom edge; the "Veneno" badge next to "PV 42 / 42".
2. Around frames 16-19: the Objetos list, "Poción ×3  (PV al máximo)" in grey and "Antídoto ×1" with the cursor; "¿Qué objeto?".
3. A frame where the hero aims Llama (around frames 100-110): the Hechizos list ("Llama  3 PM", "Curar  3 PM"), "¿A quién?" and a blinking yellow arrow over the Slime (on some frames it is off).
4. The frame right after the Llama: "25" over the Slime with "¡Débil!" in orange under it.
5. Slime on the left, Murciélago (purple, flapping, hovering) on the right; nothing overlaps the hero.

Then delete the frames: `Remove-Item -Recurse frames`.

- [ ] **Step 5: Keyboard and mouse by hand**

```powershell
.\tools\godot.cmd --path . res://scenes/battle/battle_scene.tscn
```

Without `--autoplay` the test battle waits for the player. Check: W / S and ↑ / ↓ move the cursor (it wraps and skips grey rows); Enter, Space and E accept; Atacar asks "¿A quién?" with the arrow, A / D and ← / → move it, Enter attacks; Esc, Q, Backspace and X go back one step (target → list → main menu, the cursor stays where it was); clicking an enemy aims, clicking it again attacks, clicking the grass goes back; Hechizos and Objetos open their lists; Defender and Huir act at once. (Checked while writing this plan with injected key events: W/S wrap, E → target, D/A move the arrow, Enter attacks enemy 1, Space opens Hechizos, Q returns with the cursor on Hechizos.) If the agent can't press keys, say so in the report and ask the user to try it.

- [ ] **Step 6: Commit**

```powershell
git add scripts/battle/battle_scene.gd scripts/ui/battle_result.gd
git commit -m "Play battles against one or two enemies with the new events"
```

---

### Task 4: Encounters, gold, quest and items on the map

**Files:**
- Modify: `scripts/game/game.gd`, `scripts/ui/pause_menu.gd`, `scripts/game/quest.gd`

**Interfaces:**
- Consumes: `EncounterTable.pick()`, `BattleScene.setup()` / `finished(outcome)` / `engine.gold_won` / `engine.enemies`, `BattleEngine.State`, `GameState.gold` / `use_item()`, `Inventory.IDS` / `problem()`, `Combatant.total_attack()` / `total_defense()`.
- Produces: `Game.ZONE = 1`, `Game.AUTOPLAY_BOSS_LEVEL = 5`, `Game._update_boss()`; pause menu Estado shows "Oro N G" and "Hechizos: Llama, Curar"; Objetos lists every item with "Usar" (disabled with the reason in grey).

- [ ] **Step 1: Edit `scripts/game/game.gd`**

1. Replace:

```gdscript
## starts. The map is never freed, so the hero's position, the camera and the encounter
## grace survive the battle. A defeat heals the hero and sends them back to the spawn
## point; EXP is kept. Talking to the old woman heals, moves the quest on and, once the
```

with:

```gdscript
## starts (the enemies come from EncounterTable, or the Rey Slime). The map is never
## freed, so the hero's position, the camera and the encounter grace survive the battle.
## A victory adds the gold and counts every enemy defeated for the quest; fleeing just
## goes back to the map; a defeat heals the hero and sends them back to the spawn point,
## EXP and gold kept. Talking to the old woman heals, moves the quest on and, once the
```

2. Replace:

```gdscript
const SLIME_DATA := preload("res://data/slime.tres")
const BOSS_DATA := preload("res://data/rey_slime.tres")
```

with:

```gdscript
const BOSS_DATA := preload("res://data/rey_slime.tres")
## The map is zone 1 of EncounterTable (the meadow).
const ZONE := 1
```

3. Replace:

```gdscript
const MENU_TOUR_DELAY := 1.0
```

with:

```gdscript
const MENU_TOUR_DELAY := 1.0
## On autoplay the Rey Slime only comes out from this level on, so the run first fights
## around the meadow (at lower levels it would lose to the boss over and over).
const AUTOPLAY_BOSS_LEVEL := 5
```

4. Replace:

```gdscript
var _last_quest_text := ""
```

with:

```gdscript
var _last_quest_text := ""
var _rng := RandomNumberGenerator.new()
```

5. Replace:

```gdscript
	_autoplay_menu = _autoplay and args.has("--autoplay-menu")
```

with:

```gdscript
	_autoplay_menu = _autoplay and args.has("--autoplay-menu")
	_rng.randomize()
```

6. Replace:

```gdscript
	_world.set_boss_present(state.quest.boss_available())
	_refresh_status()
	_build_fade()
```

with:

```gdscript
	_update_boss()
	_refresh_status()
	_build_fade()
```

7. Replace:

```gdscript
	var enemy_data: Combatant = BOSS_DATA if boss else SLIME_DATA
	await _fade_to(1.0)
	_world.set_active(false)
	_audio.play_music(MusicLibrary.BOSS if boss else MusicLibrary.BATTLE)
	var battle: BattleScene = BATTLE_SCENE.instantiate()
	battle.setup(state.hero, enemy_data, state.inventory)
```

with:

```gdscript
	var enemies: Array[Combatant] = [BOSS_DATA]
	if not boss:
		enemies = EncounterTable.pick(ZONE, _world.player_position(), _rng)
	await _fade_to(1.0)
	_world.set_active(false)
	_audio.play_music(MusicLibrary.BOSS if boss else MusicLibrary.BATTLE)
	var battle: BattleScene = BATTLE_SCENE.instantiate()
	battle.setup(state.hero, enemies, state.inventory)
```

8. Replace:

```gdscript
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
	_play_map_music()
	await _fade_to(0.0)
	if not won:
		_world.show_notice("Has vuelto al inicio.")
```

with:

```gdscript
	var outcome: int = await battle.finished
	var won := outcome == BattleEngine.State.WON
	await _fade_to(1.0)
	if won:
		state.gold += battle.engine.gold_won
		for enemy in battle.engine.enemies:
			state.quest.on_victory(enemy.id)
	elif outcome == BattleEngine.State.LOST:
		state.heal_full()
		_world.respawn()
	battle.queue_free()
	_update_boss()
	_refresh_status()
	_world.set_active(true)
	_play_map_music()
	await _fade_to(0.0)
	if outcome == BattleEngine.State.LOST:
		_world.show_notice("Has vuelto al inicio.")
```

9. Replace:

```gdscript
	await _world.show_dialogue(Quest.NPC_NAME, lines)
	_world.set_boss_present(state.quest.boss_available())
```

with:

```gdscript
	await _world.show_dialogue(Quest.NPC_NAME, lines)
	_update_boss()
```

10. Replace:

```gdscript
## Map music, or the village one inside the clearing.
```

with:

```gdscript
## The Rey Slime is on the map while the quest asks for it (on autoplay, only from
## AUTOPLAY_BOSS_LEVEL on).
func _update_boss() -> void:
	var strong_enough := not _autoplay or state.hero.level >= AUTOPLAY_BOSS_LEVEL
	_world.set_boss_present(state.quest.boss_available() and strong_enough)


## Map music, or the village one inside the clearing.
```

- [ ] **Step 2: Edit `scripts/ui/pause_menu.gd`**

1. Replace:

```gdscript
## Estado (hero stats), Objetos (the potion can be drunk here), Opciones
```

with:

```gdscript
## Estado (hero stats, gold, spells), Objetos (items usable outside battle), Opciones
```

2. Replace:

```gdscript
## The hero or the inventory changed (a potion was drunk), so the map can refresh.
```

with:

```gdscript
## The hero or the inventory changed (an item was used), so the map can refresh.
```

3. Replace:

```gdscript
		"ATK %d   DEF %d   VEL %d" % [hero.attack, hero.defense, hero.speed],
		"EXP %d" % hero.experience,
	])
	var next := Leveling.exp_for_next(hero.level)
	if next < 0:
		lines.append("Nivel máximo")
	else:
		lines.append("Siguiente nivel: faltan %d EXP" % (next - hero.experience))
	return "\n".join(lines)


## One row per item carried: name, count and "Usar" (disabled at full HP).
```

with:

```gdscript
		"ATK %d   DEF %d   VEL %d" % [hero.total_attack(), hero.total_defense(), hero.speed],
		"EXP %d" % hero.experience,
	])
	var next := Leveling.exp_for_next(hero.level)
	if next < 0:
		lines.append("Nivel máximo")
	else:
		lines.append("Siguiente nivel: faltan %d EXP" % (next - hero.experience))
	lines.append("Oro %d G" % _state.gold)
	var spells := PackedStringArray()
	for skill in hero.skills:
		spells.append(skill.display_name)
	lines.append("Hechizos: %s" % ", ".join(spells))
	return "\n".join(lines)


## One row per item carried: name, count and "Usar" (disabled, with the reason, when it
## can't be used now).
```

4. Replace:

```gdscript
	var items := _state.inventory.to_dict()
	var any := false
	for id: String in items:
		if items[id] <= 0:
			continue
		any = true
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		_items_box.add_child(row)
		var label := _label("%s ×%d" % [Inventory.display_name(id), items[id]], Color.WHITE)
		label.custom_minimum_size = Vector2(220, 0)
		row.add_child(label)
		var use := _button("Usar")
		use.disabled = _state.hero.hp >= _state.hero.max_hp
		use.pressed.connect(_on_use_potion)
		row.add_child(use)
	if not any:
		_items_box.add_child(_label("No llevas objetos.", Color.WHITE))


func _on_use_potion() -> void:
	var healed := _state.use_potion()
	if healed <= 0:
		return
	_sfx(SfxLibrary.HEAL)
	_fill_items()
	_items_message.text = "Recuperas %d PV." % healed
```

with:

```gdscript
	var inventory := _state.inventory
	var any := false
	for id in Inventory.IDS:
		if inventory.count(id) <= 0:
			continue
		any = true
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		_items_box.add_child(row)
		var label := _label("%s ×%d" % [Inventory.display_name(id), inventory.count(id)],
			Color.WHITE)
		label.custom_minimum_size = Vector2(220, 0)
		row.add_child(label)
		var use := _button("Usar")
		var why := inventory.problem(id, _state.hero, false)
		use.disabled = why != ""
		use.pressed.connect(_on_use_item.bind(id))
		row.add_child(use)
		if why != "":
			row.add_child(_label(why, Color(0.6, 0.6, 0.65)))
	if not any:
		_items_box.add_child(_label("No llevas objetos.", Color.WHITE))


func _on_use_item(id: String) -> void:
	var result := _state.use_item(id)
	if not result.used:
		return
	_sfx(SfxLibrary.HEAL)
	_fill_items()
	_items_message.text = ("Recuperas %d PM." if result.effect == "mp" else "Recuperas %d PV.") \
		% result.amount
```

- [ ] **Step 3: Edit `scripts/game/quest.gd`**

1. Replace:

```gdscript
## Counts a won battle against the enemy with this data id.
```

with:

```gdscript
## Counts one enemy with this data id defeated in a won battle (Game calls it for every
## enemy of the battle).
```

- [ ] **Step 4: Import and check everything**

```powershell
.\tools\godot.cmd --headless --path . --import
foreach ($s in "battle/combatant","battle/skill","battle/battle_event","battle/battle_engine","battle/battle_autoplay","battle/battle_actor","battle/battle_scene","game/inventory","game/leveling","game/game_state","game/save_data","game/game","game/quest","world/encounter_table","world/encounter_meter","ui/battle_hud","ui/battle_result","ui/pause_menu","title/title_screen") { .\tools\godot.cmd --headless --path . --check-only --script "res://scripts/$s.gd" }
```

Expected: no errors or warnings anywhere (the import too).

- [ ] **Step 5: Whole quest on autoplay**

```powershell
.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 60000 -- --autoplay > run.txt 2>&1
Select-String -Path run.txt -Pattern "ERROR|WARNING|Misión"
foreach ($p in "se defiende","Has huido","No has podido huir","eficaz contra","envenenado!","se ha dormido","aprende Curar","lanza Curar","pide ayuda","monedas de oro") { "{0,-20} {1}" -f $p, (Select-String -Path run.txt -SimpleMatch $p).Count }
Remove-Item run.txt
Remove-Item "$env:APPDATA\Godot\app_userdata\rpg-turnos\save_autoplay.json" -ErrorAction SilentlyContinue
```

Expected (about one minute): only the known Jolt warning; the quest goes `Misión: habla con la anciana` → `slimes 0 / 3` → … → `vuelve con la anciana` → `derrota al Rey Slime` → `Misión cumplida` (pairs of slimes count two); and every count above 0. A run while writing this plan gave: se defiende 14, Has huido 13, No has podido huir 3, eficaz contra 27, envenenado! 7, se ha dormido 2, aprende Curar 1, lanza Curar 6, pide ayuda 1, monedas de oro 56. Poison and sleep are random: if `envenenado!` or `se ha dormido` is 0, run it once more.

- [ ] **Step 6: Save round trip**

```powershell
.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 6000 -- --autoplay --autoplay-save > run.txt 2>&1
Select-String -Path run.txt -Pattern "ERROR|WARNING|^Guardado|^Cargado"
Remove-Item run.txt
Remove-Item "$env:APPDATA\Godot\app_userdata\rpg-turnos\save_autoplay.json" -ErrorAction SilentlyContinue
```

Expected: identical `Guardado:` and `Cargado:` JSON with `"version":2` and a `"gold"` value, for example `{"gold":5,"hero":{"attack":10,"defense":5,"experience":6,"hp":23,"level":1,"max_hp":30,"max_mp":6,"mp":0,"speed":8},"inventory":{"potion":3},"play_time":43.59,"position":[-1.94,-9.41],"quest":{"kills":0,"stage":1},"version":2}` (values change per run; `attack` / `defense` are the base stats without the Palo and the Ropa). Only the known Jolt warning.

- [ ] **Step 7: Frames of the pause menu**

```powershell
New-Item -ItemType Directory -Force frames | Out-Null
.\tools\godot.cmd --path . --write-movie frames\f.png --fixed-fps 10 --quit-after 110 -- --autoplay --autoplay-menu
```

Check the Estado page (around frame 45): "ATK 12   DEF 7   VEL 8", "Oro 0 G", "Hechizos: Llama". The Objetos page (around frame 60): "Poción ×3", its "Usar" disabled and "PV al máximo" in grey next to it. Then `Remove-Item -Recurse frames` and delete `save_autoplay.json` as above.

- [ ] **Step 8: Commit**

```powershell
git add scripts/game/game.gd scripts/ui/pause_menu.gd scripts/game/quest.gd
git commit -m "Use encounter formations, gold and every item on the map"
```

---

### Task 5: Documentation, final checks and web export

**Files:**
- Modify: `CLAUDE.md`, `docs/boost/specs/ideas-sueltas.md`

**Interfaces:**
- Consumes: everything above.
- Produces: up-to-date `CLAUDE.md`; the WASD idea marked as done; a web build.

- [ ] **Step 1: Update `CLAUDE.md`**

In `CLAUDE.md` make these replacements (each old text occurs once; if phase 2 left a sentence worded differently, edit that bullet by hand so it says the same as the new text):

1. Replace:

```markdown
instantiates a `BattleScene` with `setup(state.hero, slime.tres or rey_slime.tres, state.inventory)` on top, awaits `finished(won)`, frees it and turns the map back on (victory: `quest.on_victory(enemy.id)`, a beaten boss leaves the map with "¡Villaclaro está a salvo!"; defeat: `heal_full()` and `World.respawn()`).
```

with:

```markdown
instantiates a `BattleScene` with `setup(state.hero, enemies, state.inventory)` on top (`enemies` from `EncounterTable.pick(ZONE, player position, rng)`, or `[rey_slime.tres]`), awaits `finished(outcome)` (`BattleEngine.State`), frees it and turns the map back on (victory: `state.gold += engine.gold_won` and `quest.on_victory(id)` for every enemy, a beaten boss leaves the map with "¡Villaclaro está a salvo!"; fled: nothing; defeat: `heal_full()` and `World.respawn()`). `_update_boss()` shows the Rey Slime while `quest.boss_available()` (on autoplay only from `AUTOPLAY_BOSS_LEVEL` 5).
```

2. Replace:

```markdown
`inventory: Inventory` (starts with 3 potions), `quest: Quest`, `heal_full()` (HP and MP), `use_potion()` (outside battle; returns the HP healed).
```

with:

```markdown
`inventory: Inventory` (starts with 3 potions), `quest: Quest`, `gold` (won in battle, saved; shops come in phase 4), `heal_full()` (HP and MP), `use_item(id)` (outside battle, `Inventory.use()`). The hero gets its own `skills` array, so learning a spell never touches `hero.tres`.
```

3. Replace:

```markdown
`on_victory(enemy_id)` counts slimes during `HUNT`
```

with:

```markdown
`on_victory(enemy_id)` (called for every enemy of a won battle) counts slimes during `HUNT`
```

4. Replace:

```markdown
- `scripts/game/inventory.gd` (`Inventory`, `RefCounted`) — items as `id → count`: `count()`, `add()`, `take()`, `display_name()`, `to_dict()`, `set_items()`. Only `POTION` exists (heals `POTION_HEAL` = 25 HP, in battle or from the pause menu).
- `scripts/game/leveling.gd` (`Leveling`, `RefCounted`) — fixed `EXP_TABLE` up to `MAX_LEVEL` 10 and fixed `GAINS` per level (current HP/MP rise with their max, no full heal); `apply(hero)` returns `LEVEL_UP` events, `exp_for_next(level)`.
```

with:

```markdown
- `scripts/game/inventory.gd` (`Inventory`, `RefCounted`) — items as `id → count`: `count()`, `add()`, `take()`, `to_dict()`, `set_items()`. `ITEMS` table (name, article, effect `hp` / `mp` / `cure`, value, price, usable in `battle` / `field`) in `IDS` order: `POTION` (30 PV, 8 G), `ETHER` (15 PM, 30 G), `ANTIDOTE` (cures poison, 10 G, battle only). `problem(id, combatant, in_battle)` says why it can't be used now ("" if it can: "PV al máximo", "Solo en combate", ...); `use(id, combatant, in_battle)` → `{used, effect, amount, status, reason}`, shared by `BattleEngine` and the pause menu; `display_name()`, `article()`.
- `scripts/game/leveling.gd` (`Leveling`, `RefCounted`) — fixed `EXP_TABLE` up to `MAX_LEVEL` 20 (12, 35, 62, 96, 180, ... 3600) and fixed `GAINS` per level (PV +6, PM +3, ATK +2, DEF +1, VEL +1; current HP/MP rise with their max, no full heal); `apply(hero)` returns `LEVEL_UP` events, each followed by a `LEARN` event when the hero's `learn` table teaches a spell at that level; `sync_skills(hero)` (after loading), `exp_for_next(level)`.
```

5. Replace:

```markdown
(`version` 1, hero level / EXP / HP / MP / stats, inventory, quest stage and kills, position `[x, z]`, play time); `apply(state, data)` → `{valid, position, play_time}` (state untouched when not valid; JSON numbers come back as floats); `is_valid(data)`.
```

with:

```markdown
(`version` 2, hero level / EXP / HP / MP / base stats, inventory, quest stage and kills, gold, position `[x, z]`, play time; version 1 saves are refused); `apply(state, data)` → `{valid, position, play_time}` (state untouched when not valid; JSON numbers come back as floats; spells come back with `Leveling.sync_skills()`); `is_valid(data)`.
```

6. Replace:

```markdown
- `scripts/world/encounter_meter.gd` (`EncounterMeter`, `RefCounted`) — encounter rule: 5 m grace after `reset()`, then 8 % per full meter walked on grass.
```

with:

```markdown
- `scripts/world/encounter_meter.gd` (`EncounterMeter`, `RefCounted`) — encounter rule: 15 m grace after `reset()`, then 0.6 % per full meter walked on grass (a battle every ~180 m).
- `scripts/world/encounter_table.gd` (`EncounterTable`, `RefCounted`) — which enemies come: `ZONES` (zone 1: `[Slime]`, `[Slime]`, `[Murciélago]`, `[Seta]`, `[Slime, Slime]`, `[Slime, Murciélago]`, same weight) and `START_FORMATIONS` (`[Slime]`, `[Slime, Slime]`) within `START_RADIUS` 20 m of `WorldStage.SPAWN_POS`; `pick(zone, pos, rng)`, `near_start(pos)`.
```

7. Replace:

```markdown
- `scenes/battle/battle_scene.tscn` + `scripts/battle/battle_scene.gd` (`BattleScene`) — one battle: call `setup(hero, enemy_data, inventory)`, `set_audio(audio)` and set `char_time` before adding it (hero and inventory used as is, enemy duplicated; without audio it is silent); builds stage (`BattleStage.build`), hero and slime `BattleActor`s (`KING_SLIME` and the intro "¡El … te cierra el paso!" when `enemy.is_boss`), camera and a `CanvasLayer` with `BattleHud` and `BattleResult`. Flow: HUD `command_chosen(cmd)` → `BattleEngine.resolve_round(cmd)` → `_play_event()` per event → menu again, or result overlay → "Continuar" → `finished(won)`. Every message goes through `_say()`. Effects: hit, crit, miss, fire on spell casts, potion, heal, level up, accept on "Continuar"; music: victory fanfare on the VICTORY event, defeat when the hero falls. `--autoplay` picks commands itself (potion below 40 % HP, Llama while the enemy has more than 12 HP, else Atacar), prints every message and continues by itself.
- `scripts/battle/battle_engine.gd` (`BattleEngine`, `RefCounted`) — pure round rules. Commands are dictionaries from `cmd_attack()`, `cmd_skill(skill)`, `cmd_item(id)`; `can_use(cmd)`; the enemy picks its command from `ai_weights` (`"attack"`, `"stagger"` or a skill id). Initiative `speed × randf_range(0.5, 1.5)`; attacks: 5 % miss, 1/16 crit (ignores DEF), damage `base × randf_range(0.875, 1.125)` rounded, minimum 1, where `base = max(1, ATK − DEF/2)` (crit: `ATK × 1.5`); spells pay MP and deal `power × the same spread`, ignoring DEF, no miss or crit; the potion heals 25 HP. On victory: EXP, `Leveling.apply()`, potion drop roll. Returns `Array[Dictionary]` events built by `BattleEvent` (`scripts/battle/battle_event.gd`); `state` is `ONGOING`, `WON` or `LOST`. Never touches nodes.
- `scripts/battle/combatant.gd` (`Combatant`, `Resource`) — fighter stats (`id`, level, HP, MP, ATK, DEF, speed, `skills`, EXP; enemy-only `ai_weights`, `potion_drop_chance`, `is_boss`); data in `data/hero.tres`, `data/slime.tres`, `data/rey_slime.tres`.
- `scripts/battle/skill.gd` (`Skill`, `Resource`) — spell data (`id`, `display_name`, `mp_cost`, `power`, `color` of the cast glow and hit ball); `data/skills/llama.tres`, `data/skills/aplastar.tres` (the boss's).
```

with:

```markdown
- `scenes/battle/battle_scene.tscn` + `scripts/battle/battle_scene.gd` (`BattleScene`) — one battle against one or two enemies: call `setup(hero, enemies: Array[Combatant], inventory)`, `set_audio(audio)` and set `char_time` before adding it (hero and inventory used as is, enemies duplicated, two with the same name become "Slime A" / "Slime B"; without audio it is silent); builds stage (`BattleStage.build`), the hero and one `BattleActor` per enemy (`LOOKS` by data id; a pair stands left and right of `ENEMY_POS`, `PAIR_OFFSET` 1.5 m), camera, the blinking yellow target arrow (`_show_arrow(index)`, from `BattleHud.target_changed`; `_pick_target(screen)` turns clicks into enemies) and a `CanvasLayer` with `BattleHud` and `BattleResult`. Flow: HUD `command_chosen(cmd)` (asleep: `cmd_none()`) → `BattleEngine.resolve_round(cmd)` → `_play_event()` per event → menu again, or result overlay → "Continuar" → `finished(outcome)` (fled: at once). Every message goes through `_say()` (`_the()` / `_ending()` give "el / la" and "-o / -a" from `Combatant.female`). A call for help moves the caller to the left and grows the helper on the right. Effects: hit, crit, miss, fire on spell casts, potion, heal, level up, accept on "Continuar"; music: victory fanfare on the VICTORY event, defeat when the hero falls. `--autoplay`: `BattleAutoplay` picks (shown with `BattleHud.demo()`), flees from every 5th normal battle and defends in the first round of the 2nd, 7th...; prints every message and continues by itself. Run on its own: a poisoned Lv 3 hero with 3 potions and an antidote against a Slime and a Murciélago, quits at the end ("Fin del combate (estado N)").
- `scripts/battle/battle_engine.gd` (`BattleEngine`, `RefCounted`) — pure round rules for the hero against `enemies: Array[Combatant]` (fighters are ints: `BattleEvent.HERO` = −1 or an enemy index). Commands are dictionaries from `cmd_attack(target)`, `cmd_skill(skill, target)`, `cmd_item(id)`, `cmd_defend()`, `cmd_flee()`, `cmd_none()`; `problem(cmd)` (why not: "Faltan PM", "Silencio", item reasons), `can_use(cmd)`, `alive_enemies()`, `has_boss()`, `flee_chance()`. Each enemy picks when its turn comes, from `ai_weights` (`"attack"`, `"stagger"` or a skill id), or calls its `help` once below 50 % HP while fewer than `MAX_ENEMIES` 2 stand. Initiative `speed × randf_range(0.5, 1.5)` (defending or fleeing, the hero goes first); attacks: 5 % miss, 1/16 crit (ignores DEF), damage `base × randf_range(0.875, 1.125)` rounded, minimum 1, where `base = max(1, total ATK − total DEF/2)` (crit: `ATK × 1.5`), may cause the attacker's `attack_status`; spells pay MP: damage `power × the same spread × 1.5 weak / 0.5 resist`, ignoring DEF, no miss or crit, may cause their status; heals restore `power`. Defend halves the damage taken that round (rounded up, min 1). Flee: `clamp(0.5 + (hero VEL − mean enemy VEL) × 0.05, 0.2, 0.95)`; against a boss only `NO_ESCAPE`, no turn passes. Status (`Combatant.status`): poison 8 % max HP at the end of each round; sleep loses the turn, 50 % to wake at the end of each round, damage wakes; silence 3 rounds without spells; all cleared when the battle ends. On victory: `exp_won`, `gold_won`, `Leveling.apply()`, each enemy's `drops` rolls (`drops_won`). Returns `Array[Dictionary]` events built by `BattleEvent` (`scripts/battle/battle_event.gd`); `state` is `ONGOING`, `WON`, `LOST` or `FLED`. Never touches nodes.
- `scripts/battle/battle_autoplay.gd` (`BattleAutoplay`, `RefCounted`) — pure command picker for `--autoplay` and balance checks: below 40 % HP heals (Curar, else potion), with no heal defends below 25 % (never twice in a row); antidote when poisoned, ether when MP can't pay a heal; otherwise aims at the weakest enemy and casts the spell that hurts most (weaknesses count) only when it beats an attack by ×1.5, keeping MP for two heals. `choose(engine)`.
- `scripts/battle/combatant.gd` (`Combatant`, `Resource`) — fighter stats (`id`, `female`, level, HP, MP, base `attack` / `defense` plus hero-only `equip_attack` / `equip_defense` (Palo +2, Ropa +2 until phase 4; `total_attack()` / `total_defense()`), speed, `skills`, hero-only `learn` (level → Skill), EXP; enemy-only `exp_reward`, `gold_reward`, `ai_weights`, `weak` / `resist` (elements), `drops` (item id → chance), `attack_status` / `attack_status_chance`, `help` (Combatant it calls), `is_boss`); battle-only `status` (status → rounds, −1 until cured). Data in `data/hero.tres`, `data/slime.tres`, `data/bat.tres` (Murciélago), `data/mushroom.tres` (Seta saltarina), `data/rey_slime.tres`.
- `scripts/battle/skill.gd` (`Skill`, `Resource`) — spell data (`id`, `display_name`, `mp_cost`, `power`, `color` of the cast glow and hit ball, `element` `fire` / `ice` / `thunder` / "", `kind` `damage` / `heal` / `status`, `targets` `one` / `all`, `status`, `status_chance`; `needs_target()`); `data/skills/`: `llama`, `curar`, `llamarada`, `rayo`, `curar_mas` (the hero's), `aplastar` (Rey Slime), `esporas` (Seta: sleep 30 %).
```

8. Replace:

```markdown
(`look`: `HERO` / `SLIME` / `VILLAGER` / `KING_SLIME`, set before `add_child`)
```

with:

```markdown
(`look`: `HERO` / `SLIME` / `VILLAGER` / `KING_SLIME` / `BAT` / `MUSHROOM`, set before `add_child`)
```

9. Replace:

```markdown
`SLIME` / `KING_SLIME` are faceted `LowPoly` blobs with eyes (king ×1.6 with a gold crown) that bounce while idle. Awaitable `play_attack`, `play_hit` (flash overlay + floating `Label3D` number), `play_dodge`, `play_defeat` (characters stay down, slimes fade and hide), `play_cast(color)`, `play_burn(amount, color)`, `play_heal`, `play_stagger`, `play_cheer`;
```

with:

```markdown
`SLIME` / `KING_SLIME` are faceted `LowPoly` blobs with eyes (king ×1.6 with a gold crown) that bounce while idle; `BAT` hovers at 1.1 m flapping two box wings; `MUSHROOM` is a stem with eyes and a spotted hemisphere cap (×1.4) that bounces. Awaitable `play_attack`, `play_hit(amount, crit, tag)` (flash overlay + floating `Label3D` number, `tag` "¡Débil!" / "¡Resiste!" under it), `play_dodge`, `play_defeat` (characters stay down, the rest fade and hide), `play_cast(color)`, `play_burn(amount, color, tag)`, `play_heal(amount, color)`, `play_status(color, amount)`, `play_appear()`, `play_stagger`, `play_cheer`; `top_height()`;
```

10. Replace:

```markdown
- `scenes/ui/battle_hud.tscn` + `scripts/ui/battle_hud.gd` (`BattleHud`) — hero status (name and level, PV bar, PM), command menu ("Atacar", the hero's first skill, potion; disabled without MP, or without potions or at full HP; choices are ignored for 0.3 s after the menu opens so a quick Enter never picks a command; emits `command_chosen(cmd: Dictionary)`), typed message window (`char_time` seconds per character); `await show_message(text)` returns on click / Enter / Space or after auto-advance; `set_audio()` adds cursor and accept sounds; `static make_window()` is the shared window style.
- `scenes/ui/battle_result.tscn` + `scripts/ui/battle_result.gd` (`BattleResult`) — victory overlay (EXP, new level, potion drop) or defeat overlay, with "Continuar" (`continue_requested`).
```

with:

```markdown
- `scenes/ui/battle_hud.tscn` + `scripts/ui/battle_hud.gd` (`BattleHud`) — `set_engine(engine)`; hero status (name and level, PV with status badges Veneno / Sueño / Silencio, PV bar, PM; `update_status()`), command window (`MENU_WIDTH` 340) with pages `MAIN` (Atacar · Hechizos · Objetos · Defender · Huir), `SPELLS`, `ITEMS` (rows that can't be used are grey with the reason, e.g. "Poción ×3  (PV al máximo)") and `TARGET` (with two enemies standing, Atacar and one-target spells ask "¿A quién?" and emit `target_changed(index)`, −1 hides the arrow; `pick_target: Callable` maps clicks to enemies). Keys are read in `_input()`: W / S or ↑ / ↓ move, A / D or ← / → aim, Enter / Space / E accept, Esc / Q / Backspace / X go back; a click on an enemy aims, a second click confirms, a click elsewhere goes back. Choices are ignored for 0.3 s after the menu opens so a quick Enter never picks a command; emits `command_chosen(cmd: Dictionary)`. `await demo(cmd)` walks the menus to cmd (autoplay). Typed message window (`char_time` seconds per character); `await show_message(text)` returns on click / Enter / Space / E or after auto-advance; `set_audio()` adds cursor, accept and cancel sounds; `static make_window()` is the shared window style.
- `scenes/ui/battle_result.tscn` + `scripts/ui/battle_result.gd` (`BattleResult`) — victory overlay (EXP, new level, gold, items left) or defeat overlay, with "Continuar" (`continue_requested`).
```

11. Replace:

```markdown
Estado, Objetos ("Usar" the potion),
```

with:

```markdown
Estado (stats, gold, spells), Objetos ("Usar" on every item; greyed with the reason when it can't be used outside battle now),
```

12. Replace:

```markdown
- Run the game on autoplay (no title: a new game that walks a route, fights picking commands and continues by itself; saves to `user://save_autoplay.json`): `.\tools\godot.cmd --path . -- --autoplay`
- Save round trip: `.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 3000 -- --autoplay --autoplay-save`
```

with:

```markdown
- Run the game on autoplay (no title: a new game that walks a route, fights picking commands and continues by itself; saves to `user://save_autoplay.json`): `.\tools\godot.cmd --path . -- --autoplay`
- Whole quest on autoplay, headless (about a minute; the Rey Slime comes out at Lv 5; ends with `Misión cumplida`): `.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 60000 -- --autoplay`
- One test battle (poisoned Lv 3 hero against a Slime and a Murciélago; quits when it ends; play it with the keyboard or the mouse, or add `-- --autoplay`): `.\tools\godot.cmd --path . res://scenes/battle/battle_scene.tscn`
- Save round trip: `.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 6000 -- --autoplay --autoplay-save`
```

- [ ] **Step 2: Mark the idea in `docs/boost/specs/ideas-sueltas.md`**

1. Replace:

```markdown
- **Estado:** pendiente.
```

with:

```markdown
- **Estado:** hecha en la fase 3: [diseño](2026-11-03-combate-completo-design.md) y [plan](../plans/2026-11-03-combate-completo.md).
```

- [ ] **Step 3: Check every changed script once more and run the quest**

Run Task 4 Step 4 and Step 5 again. Expected: no errors; only the known Jolt warning; `Misión cumplida`.

- [ ] **Step 4: Web export**

```powershell
.\tools\godot.cmd --headless --path . --export-release "Web" build/web/index.html
Get-ChildItem build/web
```

Expected: `index.html`, `index.js`, `index.wasm`, `index.pck` (about 3 MB), the audio worklets and icons; no ERROR (checked while writing this plan). `build/` is git-ignored. Optionally serve it (`python -m http.server 8060 --directory build/web`) and play one battle in the built-in browser pane with the keyboard.

- [ ] **Step 5: Windowed run (for the user)**

```powershell
.\tools\godot.cmd --path .
```

"Nueva partida", walk into the grass until a battle starts and play it with WASD only: W / S, Enter / E, A / D on a pair, Esc / Q to go back. If the agent can't press keys, say so in the final report and ask the user to try it once.

- [ ] **Step 6: Commit**

```powershell
git add CLAUDE.md docs/boost/specs/ideas-sueltas.md
git commit -m "Document the full combat phase"
```

Do not merge or push; report to the user, with the balance table of the Global Constraints.

---

## Self-review

Checked against `docs/boost/specs/2026-11-03-combate-completo-design.md`:

- **Main menu** Atacar · Hechizos · Objetos · Defender · Huir; Hechizos and Objetos open lists; Esc / X / a click outside go back (Task 2, `BattleHud`).
- **Keyboard:** W / S or ↑ / ↓, A / D or ← / → for the target, Enter / Space / E accept, Esc / Q / Backspace cancel (X too); mouse and touch as before (Task 2). Read in `_input()` with physical keys, so the map and the project input map are untouched.
- **Target choice** only with two enemies standing, for Atacar and one-target spells; blinking arrow; A / D or a click change it, Enter or a second click confirm (Tasks 2-3).
- **Defender** halves the damage of the round (ceil, min 1) and acts first; **Huir** with the spec formula, "¡No puedes huir!" against bosses without losing the turn, enemies act on a failure, no EXP and encounter grace on success (Task 1; the grace comes from `World.set_active(true)`).
- **Spells** Llama / Curar / Llamarada / Rayo / Curar+ with the spec levels, costs and powers, learned on level up with "¡Héroe aprende Curar!" (Tasks 1, 3).
- **Elements** fire / ice / thunder with `weak` ×1.5 and `resist` ×0.5; "¡Débil!" / "¡Resiste!" under the number and in the message (Tasks 1-3). Deviation: the message reads "¡Es muy eficaz contra el Slime!" / "¡El X lo resiste!" rather than repeating the tag.
- **Statuses** poison 8 %, sleep with 50 % to wake per round and on damage, silence 3 rounds; HUD badges next to the PV; enemies can suffer them too (the engine is symmetric), the hero has no status spells (Tasks 1-3).
- **Items** Poción 30 (8 G), Éter +15 PM, Antídoto; spend the turn in battle; usable from the pause menu where it makes sense; greyed with the reason instead of hidden (Tasks 1, 2, 4). The Antídoto price (10 G) and "battle only" are choices of this plan.
- **Progression** base 30 / 6 / 10 / 5 / 8 plus Palo +2 ATK and Ropa +2 DEF as fixed bonuses in `hero.tres` (`equip_attack` / `equip_defense`), per-level gains and the EXP table to 20 (Task 1). The hero's DEF goes from 6 to 7, as the spec says.
- **Zone 1 enemies**, gold (kept in `GameState`, saved), drops per enemy, formations with the start-area rule, Rey Slime 142 PV that calls a Slime once below 50 % (Tasks 1, 3, 4). Deviation recorded by the spec's own rule: Murciélago ATK 12 → 10 after the balance check.
- **Encounters** 15 m grace and 0.6 % per meter (Task 1).
- **Two enemies** left and right, camera unchanged (Task 3).
- **Messages** all through `_say()`, in Spanish, gendered for the Seta (Task 3).
- **Architecture:** `BattleEngine` with `Array[Combatant]` and targeted commands, the event list of the spec plus `GOLD`, `MP_HEAL`, `NO_ESCAPE` and `LEARN`; `Combatant`, `Skill`, `Inventory.ITEMS` / `use()`, `EncounterTable` as specified; pure classes never touch nodes (Task 1).
- **Autoplay** picks spells by weakness, heals with Curar, defends with low HP and no heals, flees one normal battle in five (Tasks 1, 3); it also defends in the first round of one battle in five, so Defender always shows up, and keeps the Rey Slime away until Lv 5 so the run reaches the end of the quest (Task 4).
- **Verification:** `--check-only`, full autoplay with the new messages and no ERROR / WARNING, frames of the two-enemy battle, arrow, spell list and badges, balance check with results in the Global Constraints, web export (Tasks 1-5). No tests: the balance script and frames are throwaway and never committed.
- Out of scope respected: no shops or equipment slots, no zones 2-4, no battle speed option.
