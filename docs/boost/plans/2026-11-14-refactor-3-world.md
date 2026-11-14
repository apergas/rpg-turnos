# Refactor 3: trocear `World` (M-71) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Split `scripts/world/world.gd` (1.839 lines, 97 functions, 81 variables) into six pieces (`MapHud`, `MapProps`, `MapFigures`, `MapMonsters`, `AutoplayHunter` and `MapUses`). `World`'s public API (its signals and public methods) stays the same, and nothing in the game changes.

**Architecture:** `World` stays the map scene. It builds the zone (`WorldStage.build`), the dungeon, the player, the camera, the lantern and the particles. It keeps the freeze state (`_waiting`, `_talking`, `_taps_from_ms`), the boss, the steps, the village check, the simulation clock `_sim_ms` and the world flags. Every public method that moved becomes a one-line façade.

- The pieces are children of `World`, created in code. They never store `World`. They get what they need through `setup()` (the zone, the player, the camera and, for `MapUses` and `AutoplayHunter`, the sibling pieces they read) and report back with signals, which `World` re-emits under its own unchanged signals.
- `World._physics_process` calls each piece's `step()` in today's order. No piece has `_process` or `_physics_process`.

**Tech Stack:** Godot 4.7.2, GDScript, Compatibility renderer. Code only: no `.tscn` changes.

## Global Constraints

- **Nothing in the game changes:** no rules, texts, balance, look, save format (version 14) or autoplay output (the same `Zona:`, `Escena:`, `Lugar:`, `Grupos: n`... lines).
- **NO TESTS OF ANY KIND.** `CLAUDE.md` forbids them and overrides the skill's TDD steps. Check by hand:
  - `--import`;
  - `--check-only` on each changed script;
  - the autoplay runs named in each task, compared with the reference;
  - screenshots and frames for visuals.
- **Every Godot run sets `APPDATA` inline to the literal scratch path** `C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor`. Never write `$APPDATA` in `rm`, `mv` or `cp`.
  - Reference logs: `C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/` (plan 1 recorded all of them: `v1.log`, `v2.log`, `medallas.log`, `eco.log`, `save.log`, `zone_jungla.log` (the jungla run, 40000 frames) and the frames of the start of the v1 in `movie/`).
  - This plan's logs: `C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/`.
- **Commands run from Git Bash** in `C:/Users/peixe/Documents/rpg-turnos`, with `./tools/godot.cmd` (the Godot 4.7.2 console wrapper).
- **The known Jolt warning is the only accepted noise:** `WARNING: Jolt Physics job system exceeded the maximum number of jobs`. Any other `ERROR` or `WARNING` is a real problem.
- **Move code, don't rewrite it.** Cut and paste functions as they are, and change only the accesses:
  - `zone.` becomes `_zone.`;
  - the owner's variables become the piece's own, or a getter of the piece that owns them;
  - the owner's signals become the piece's signals.
  - A bug found while moving gets its own commit, never mixed in with the move.
- **One task = one piece = one commit,** with the whole game working after each.
- **`CLAUDE.md` *Layout* is updated in the same commit as the code.**
- **Branch:** `feature/refactor-3-world`, from `develop` (plans 1 and 2 already merged).
  - Merge back with `git merge --no-ff`.
  - Commit messages are in English, with no `Co-Authored-By` and no attribution of any kind.
  - Never push.
- **What plans 1 and 2 leave behind:**
  - `World` reads its flag with `RunFlags.autoplay()`, not `OS.get_cmdline_user_args()`. Every new piece sets `_autoplay = RunFlags.autoplay()` in its `setup()`.
  - Plan 1 may have wrapped autoplay code in `#region Autoplay` / `#endregion`. A region moves with the code it wraps. A region left empty in `World` is deleted.
  - `BattleActor.Look` still works through plan 2's alias (`const Look = ActorLooks.Look`). Copy the type hint of `_add_figure(look: ...)` exactly as plan 2 left it.
- **Line numbers are never used:** functions and members are named by their current name. Plans 1 and 2 shifted the lines.
- **Comments:** each moved function keeps its `##` doc comment. Each new file starts with a `##` header that says what it holds and that it is owned by `World` and never stores it.

## Decisions this plan fixes

### Who owns each of `World`'s 81 variables

"Getter" is how the other pieces read it. Nobody keeps a second copy. The `flags` Dictionary is the one exception, and it follows the existing pattern: `World` writes it, and it hands the same Dictionary object down through `set_flags()`, as `World.set_world_flags()` already does with `MonsterRoam` and `DungeonMap`.

| Variable | Owner | How others read it |
|---|---|---|
| `zone`, `boss_id` | `World` (public, set before `add_child`) | passed to each `setup()` |
| `_rng` | `MapMonsters` (seeded in its `setup()`) | — |
| `_grass`, `_particles`, `_camera_spot`, `_dungeon` | `World` | `_dungeon` passed to `MapUses.setup()` |
| `_player`, `_camera` | `World` | passed to `setup()` (`_camera` only to `MapUses`) |
| `_boss`, `_boss_present`, `_boss_armed` | `World` | — (the boss figure is built by `MapFigures.add_figure()`) |
| `_flags` | `World` (single writer) | `set_flags(flags)` on `MapProps`, `MapMonsters` and `MapUses`; an argument of `MapHud.refresh_map_marks()` |
| `_autoplay` | `World` (`ask()`, the hunt condition), plus one each in `MapHud`, `MapMonsters` and `MapUses` | each sets it from `RunFlags.autoplay()`: a read-only run flag, not state |
| `_waiting`, `_talking`, `_taps_from_ms` | `World` | — |
| `_audio`, `_in_village`, `_step_m`, `_sim_ms` | `World` | `_sim_ms` is passed as `int(_sim_ms)` to `MapMonsters.calm()` / `check_contact()` / `set_repel()` and `AutoplayHunter.step()` |
| `_ui` | gone: `MapHud` **is** the `CanvasLayer` | `World` adds `ChoiceWindow` to `_hud` |
| `_status_column`, `_name_label`, `_hp_bar`, `_mp_bar`, `_exp_bar`, `_gold_label`, `_mission_box`, `_missions`, `_mission_done_serial`, `_mission_done`, `_map_square`, `_has_explored`, `_notice`, `_notice_word`, `_notice_tween`, `_notice_window`, `_place_label`, `_hint_window`, `_hint`, `_banner`, `_banner_tween`, `_banner_shown`, `_prompt`, `_prompt_box`, `_prompt_key`, `_prompt_cap`, `_use_button` | `MapHud` | through `MapHud` methods only |
| `_pad` | `MapHud` | getter `MapHud.pad: TouchPad` (null off a phone) |
| `_dialogue` | `MapHud` | getter `MapHud.dialogue: DialogueBox` |
| `_chest_lids`, `_open_chests` | `MapProps` | `MapProps.closed_chests() -> Array[String]` |
| `_well_waters` | `MapProps` | — |
| `_dry_wells` | `MapProps` | getter `MapProps.dry_wells: Array[String]` |
| `_fogs`, `_arches` | `MapProps` | — |
| `_portal` | `MapProps` | `MapProps.has_portal() -> bool` |
| `_return_mark`, `_marker` | `MapProps` | — |
| `_figures` (name → body) | `MapFigures` | `figure_node()` / `figure_turn()` / `figure_actor()` |
| `_quest_marks` | `MapFigures` | `MapFigures.has_mark(figure_name) -> bool` |
| `_hidden_figures` | `MapFigures` | getter `MapFigures.hidden: Array[String]` |
| `_mark_labels` | `MapFigures` | — |
| `_figure_signs` | `MapFigures` | getter `MapFigures.signs: Array[Label3D]` |
| `_groups` | `MapMonsters` | getter `MapMonsters.groups: Array[Dictionary]` (`AutoplayHunter`) |
| `_shy`, `_contact`, `_calm_until_ms`, `_refill_ms` | `MapMonsters` | — |
| `_repelled` | `MapMonsters` | `MapMonsters.is_repelled() -> bool` |
| `debug_no_groups` (static) | `MapMonsters` | `World.debug_no_groups` stays as a static alias (Game and DebugPanel read it) |
| `_hunt_on`, `_hunt_until_ms`, `_hunt_skip` | `AutoplayHunter` | `AutoplayHunter.is_on() -> bool` |
| `_exits`, `_exits_armed` | `MapUses` | — |
| `_was_near`, `_use_on_arrival`, `_autoplay_talked`, `_signs_under_prompt` | `MapUses` | — |

The table lists 81 variables, all of them. The pieces add six variables to `World`: `_hud`, `_props`, `_figures` (the dictionary of that name moved into `MapFigures`), `_monsters`, `_hunter` and `_uses`.

### Who reads whom

The graph has no cycles:

- `MapUses` reads `MapHud`, `MapFigures` and `MapProps`.
- `AutoplayHunter` reads `MapMonsters`.
- No piece reads `World`. The only exception is `MapHud`'s use of `World.PROMPTS` in Tasks 1 to 5, and Task 6 removes it.

### Departures from the spec's table, and why

- **`_trigger` stays in `World`.** It writes `_waiting` and `_boss_armed` and emits `encounter_triggered`, all of which belong to `World`.
- **`_paint_prompt_cap` goes to `MapHud`, not `MapUses`.** The prompt's nodes are built by `_build_ui` in a fixed draw order. `MapHud` owns the nodes, and `MapUses` decides what they say and when (`MapHud.show_prompt(text, key_name)`).
- **`_is_open` becomes `static func is_open(exit, flags)` on `MapProps`.** `MapProps.set_flags()` (the fog) needs it before `MapUses` exists (Task 2), and `MapUses.check_exits()` calls it.
- **`_check_exits` becomes `MapUses.check_exits(pos) -> Dictionary`.** It returns the open exit walked into (`{}` for none) instead of freezing the map itself. `World._take_exit(exit)` does the same five lines that ended `_check_exits` before, in the same order.
- **`_check_groups` becomes `MapMonsters.check_contact(pos, now_ms) -> bool`.** It sets the contact and returns true. `World` then calls `_trigger(false)`, the same order as before.
- **`_flat_distance` is copied, not shared.** The codebase already does this: `MonsterGroups._flat`, `MonsterRoam._flat` and `World._flat_distance` are each a private one-liner. Each piece that measures gets its own `static func _flat_distance`.

### The order inside `World._physics_process` (fixed; every task keeps it)

1. `_sim_ms += delta * 1000.0`
2. pad → `_player.stick_direction` (and `_uses.drop_errand()` while the stick is held)
3. `Vegetation.set_pusher`
4. `ZoneParticles.follow`
5. `_hud.step(hero_pos, last_step_m)` (map square, then the phone hint)
6. `_props.show_marker(_player.move_target)`
7. `_dungeon.see_through`
8. `_monsters.move_groups(delta)`
9. `return` while `_waiting or _talking`
10. `_monsters.tick_refill(delta)`
11. village check → `village_changed`
12. `_play_steps()`
13. `_uses.check_exits(pos)` → `_take_exit()` and `return`
14. boss check → `_trigger(true)` and `return`
15. `_monsters.check_contact(pos, int(_sim_ms))` → `_trigger(false)` and `return`
16. `_hunter.step(pos, int(_sim_ms))` (autoplay, hunting, no Incienso)
17. `_uses.step(pos)` (prompt, tap errand, autoplay talk)

### Build order inside `World._ready()` (fixed)

Each piece is created with `.new()` and `setup()` early, so that `set_world_flags({})` and the other early calls reach them all. Each piece is then added to the tree at the point where its nodes used to be built, so the node order stays the same as today. The final `_ready()` is in Task 6, Step 3.

---

### Task 1: `MapHud` (the 2D layer)

**Files:**
- Create: `scripts/world/map_hud.gd` (and its `.gd.uid`, written by `--import`)
- Modify: `scripts/world/world.gd`
- Modify: `CLAUDE.md`

**Interfaces:**
- Consumes: `RunFlags.autoplay()` (plan 1).
- Produces:
  - `class_name MapHud extends CanvasLayer`
  - `signal map_pressed`, `signal tapped(screen: Vector2)`, `signal pinched(ratio: float)`, `signal use_pressed`
  - `var pad: TouchPad` (getter), `var dialogue: DialogueBox` (getter)
  - `const BANNER_FADE := 0.5` (`World.BANNER_FADE` aliases it)
  - `func setup(zone: ZoneData) -> void`
  - `func step(hero_pos: Vector3, last_step_m: float) -> void`
  - `func reset_pad() -> void`
  - `func show_prompt(text: String, key_name: String) -> Rect2`, `func hide_prompt() -> void`, `func prompt_showing() -> bool`
  - `func show_banner_once() -> void`
  - `func begin_cutscene() -> void`, `func end_cutscene() -> void`
  - `func set_explored(map: ExploredMap) -> void`, `func refresh_map_marks(flags: Dictionary, dry_wells: Array[String]) -> void`
  - `func refresh_status(hero: Combatant, _potions: int, gold: int, missions: Array[String] = []) -> void`
  - `func set_status_shown(on: bool) -> void`
  - `func show_mission_done(text: String) -> void`
  - `func show_notice(text: String, word := "Aviso", tone := &"text-info") -> void`
  - `func show_touch_hint(text: String) -> void`

- [ ] **Step 1: Check the references on `develop` (before branching)**

  Plan 1 recorded every reference this plan compares with. Make this plan's scratch folder and check them:

```bash
cd C:/Users/peixe/Documents/rpg-turnos
git checkout develop
git status --short
mkdir -p C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3
ls C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/ C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/movie
```

  Expected:
  - `git status --short` prints nothing.
  - The listing shows `v1.log`, `v2.log`, `medallas.log`, `eco.log`, `save.log`, `zone_jungla.log` and `movie`, which holds 12 PNGs (`f00000000.png` to `f00000550.png`, every 50th frame).

- [ ] **Step 2: Create the branch**

```bash
git checkout -b feature/refactor-3-world develop
```

  Expected: `Switched to a new branch 'feature/refactor-3-world'`.

- [ ] **Step 3: Create `scripts/world/map_hud.gd` with this skeleton**

```gdscript
class_name MapHud extends CanvasLayer
## The map's 2D layer (UiTokens.LAYER_HUD): the status window (name, PV, PM, EXP, gold and
## the missions), the place line and the MapSquare under it, the notice window, the place's
## banner, the prompt with its keycap (MapUses says what it reads), on a phone the TouchPad
## and the use button, the phone's walking hint and the DialogueBox. Owned by World, which
## calls setup() before add_child; it builds itself in _ready() and never stores World.

## The map square was tapped (World emits map_requested unless the map is frozen).
signal map_pressed
## Phones: a short touch on the map (TouchPad.tapped), a pinch, the use button.
signal tapped(screen: Vector2)
signal pinched(ratio: float)
signal use_pressed

const NOTICE_TIME := 4.0
## Fade in and out of the notice window.
const NOTICE_FADE := 0.2
## Seconds "Misión cumplida" stays in the status window.
const MISSION_DONE_TIME := 4.0
## The notice window, top centre (clear of the status window and the ☰ button).
const NOTICE_MAX_WIDTH := float(UiTokens.WINDOW_W_XL)
const UI_EDGE := float(UiTokens.SPACE_6)
## Phone: the mission line wraps here and the bars narrow to fit.
const TOUCH_MISSION_WIDTH := 300.0
## The use button of the phone interface.
const USE_BUTTON_SIZE := Vector2(180, 72)
## The phone's walking hint: wraps here and sits over the use button's row.
const TOUCH_HINT_WIDTH := float(UiTokens.WINDOW_W_L)
## The place's name, big, the first time the map is the player's (World.freeze(false)).
const BANNER_TOP := 110.0
const BANNER_FADE := 0.5
const BANNER_TIME := 2.5
## Mission lines wrap past this width, so the status window stays at the side of the screen.
const MISSION_WIDTH := 420.0

## Phones: the pad that reads the fingers (null off a phone). World feeds it input and
## reads its direction.
var pad: TouchPad:
	get:
		return _pad
## The dialogue window (World.show_dialogue(), say_lines(), set_audio()).
var dialogue: DialogueBox:
	get:
		return _dialogue

var _zone: ZoneData
var _autoplay := false
## The status window and the map square under it: a cutscene hides them together.
var _status_column: VBoxContainer
var _name_label: Label
var _hp_bar: StatBar
var _mp_bar: StatBar
var _exp_bar: StatBar
var _gold_label: Label
var _mission_box: VBoxContainer
## The lines of the status window, and the serial that lets "Misión cumplida" put them back.
var _missions: Array[String] = []
var _mission_done_serial := 0
var _mission_done := false
var _map_square: MapSquare
var _has_explored := false
var _notice: Label
var _notice_word: Label
var _notice_tween: Tween
var _notice_window: PanelContainer
var _place_label: Label
var _hint_window: PanelContainer
var _hint: Label
var _banner: VBoxContainer
var _banner_tween: Tween
var _banner_shown := false
var _prompt: Label
var _prompt_box: VBoxContainer
var _prompt_key: Label
var _prompt_cap: StyleBoxFlat
## Phones: the button that replaces the prompt, and the pad that reads the fingers.
var _use_button: Button
var _pad: TouchPad
var _dialogue: DialogueBox


func setup(zone: ZoneData) -> void:
	_zone = zone
	_autoplay = RunFlags.autoplay()
	layer = UiTokens.LAYER_HUD


func _ready() -> void:
	_build_ui()
	_place_label.text = _zone.map_label()


## Every physics tick (World): the hero's marker on the map square, and the phone's hint
## goes once the hero walks.
func step(hero_pos: Vector3, last_step_m: float) -> void:
	_map_square.follow(hero_pos)
	if _hint_window and _hint_window.visible and last_step_m > 0.0:
		_hint_window.hide()


## Forgets the fingers on the map (a window, a battle or a cutscene took over).
func reset_pad() -> void:
	if _pad:
		_pad.reset()


## Shows the prompt (desktop: the text and the accept key's keycap) or the phone's use
## button, and returns the screen rect it covers (MapUses hides the figure signs under it).
func show_prompt(text: String, key_name: String) -> Rect2:
	if _use_button:
		_use_button.text = text
		_use_button.show()
		return _use_button.get_global_rect()
	_prompt.text = text
	_prompt_key.text = key_name
	_paint_prompt_cap()
	_prompt_box.show()
	return _prompt_box.get_global_rect()


func hide_prompt() -> void:
	_prompt_box.hide()
	if _use_button:
		_use_button.hide()


func prompt_showing() -> bool:
	return _use_button.visible if _use_button else _prompt_box.visible


## The place's banner, the first time the map is the player's (World.freeze(false)).
func show_banner_once() -> void:
	if _banner_shown:
		return
	_banner_shown = true
	_show_banner()


## A cutscene: the status window, the map square, the place line, the hint, the notice and
## the banner go.
func begin_cutscene() -> void:
	_status_column.hide()
	_map_square.hide()
	_place_label.hide()
	if _hint_window:
		_hint_window.hide()
	_notice_window.hide()
	if _banner_tween:
		_banner_tween.kill()
	_banner.hide()


func end_cutscene() -> void:
	_status_column.show()
	_map_square.show()
	_place_label.show()


## What has been seen of this zone, for the map square.
func set_explored(map: ExploredMap) -> void:
	_map_square.set_map(map)
	_has_explored = true
```

  `show_prompt()` joins the two halves of the old `World._show_prompt()`. On a phone it now receives the key name too, which `World` computes with `_action_key_name()`. That function only reads `InputMap` and has no side effect. The other new functions are the lines they replace in `World`, listed in Step 5.

- [ ] **Step 4: Move these members from `world.gd` into `map_hud.gd`, as they are**

  **Constants:** `NOTICE_TIME`, `NOTICE_FADE`, `MISSION_DONE_TIME`, `NOTICE_MAX_WIDTH`, `UI_EDGE`, `TOUCH_MISSION_WIDTH`, `USE_BUTTON_SIZE`, `TOUCH_HINT_WIDTH`, `BANNER_TOP`, `BANNER_FADE`, `BANNER_TIME` and `MISSION_WIDTH`. They are already in the skeleton, so delete them from `World`. The exception is `BANNER_FADE`, which `Game` reads: `World` keeps `const BANNER_FADE := MapHud.BANNER_FADE`.

  **Variables:** the ones in the skeleton. Delete `_ui` and each of them from `World`.

  **Functions moved verbatim:**
  - `_build_banner`
  - `_show_banner` (`zone.` → `_zone.`; `_autoplay` is the piece's own)
  - `_label`
  - `_paint_prompt_cap`
  - `refresh_status`
  - `show_mission_done`
  - `_show_missions`
  - `show_notice`
  - `show_touch_hint` (`_ui.add_child(` → `add_child(`)

  **`_refresh_map_marks`** becomes public, with its inputs as arguments:

```gdscript
## The map square's points of interest (MapMarks): they follow the dry wells and, on a
## dungeon floor, the lever, the gates and the key.
func refresh_map_marks(flags: Dictionary, dry_wells: Array[String]) -> void:
	if not _has_explored:
		return
	_map_square.set_marks(MapMarks.of_zone(_zone, flags, dry_wells))
```

  **`set_status_shown`**, with `_reset_pad()` → `reset_pad()`.

  **`_build_ui`**, with these changes only:
  - Delete its first three lines (`_ui = CanvasLayer.new()`, `_ui.layer = UiTokens.LAYER_HUD`, `add_child(_ui)`).
  - Every `_ui.add_child(` → `add_child(`.
  - The map square's lambda (`_map_square.pressed.connect(func() -> void: if not _talking and not _waiting: map_requested.emit())`) → `_map_square.pressed.connect(map_pressed.emit)`. The check moves to `World._on_map_pressed()` (Step 5).
  - `_prompt.text = PROMPTS[TALK]` → `_prompt.text = World.PROMPTS[World.TALK]`. The text sizes the box for `PRESET_MODE_MINSIZE`, so it must stay. Task 6 changes it to `MapUses.PROMPTS[MapUses.TALK]`.

  **`_build_touch_controls`**, with these changes only:
  - `_ui.add_child(` → `add_child(`
  - `_ui.move_child(_pad, 0)` → `move_child(_pad, 0)`
  - `_pad.tapped.connect(_on_tapped)` → `_pad.tapped.connect(tapped.emit)`
  - `_pad.pinched.connect(_camera.zoom_by)` → `_pad.pinched.connect(pinched.emit)`
  - `_use_button.pressed.connect(func() -> void: _use(_nearest_use(_player.global_position)))` → `_use_button.pressed.connect(use_pressed.emit)`

- [ ] **Step 5: Leave the façades and wire `MapHud` in `world.gd`**

  Add `var _hud: MapHud` next to the other piece variables (after `boss_id`), and `const BANNER_FADE := MapHud.BANNER_FADE` where `BANNER_FADE` was.

  **Façades.** Replace the bodies of the public functions that moved:

```gdscript
func refresh_status(hero: Combatant, potions: int, gold: int, missions: Array[String] = []) -> void:
	_hud.refresh_status(hero, potions, gold, missions)


func set_status_shown(on: bool) -> void:
	_hud.set_status_shown(on)


func show_mission_done(text: String) -> void:
	_hud.show_mission_done(text)


func show_notice(text: String, word := "Aviso", tone := &"text-info") -> void:
	_hud.show_notice(text, word, tone)


func show_touch_hint(text: String) -> void:
	_hud.show_touch_hint(text)


func set_explored(map: ExploredMap) -> void:
	_hud.set_explored(map)
	_refresh_map_marks()


func _refresh_map_marks() -> void:
	_hud.refresh_map_marks(_flags, _dry_wells)


func _reset_pad() -> void:
	_hud.reset_pad()


## The map square was tapped: the Mapa page, unless a window or a battle holds the map.
func _on_map_pressed() -> void:
	if not _talking and not _waiting:
		map_requested.emit()
```

  Each façade keeps the doc comment of the function it replaces. `show_mission_done` is not awaited anywhere (`grep -rn "await.*show_mission_done" scripts` prints nothing), so a non-awaiting façade is safe.

  **Inside `World`, change these lines:**

  - `_physics_process`: replace the pad block and the two HUD lines with the following. `_use_on_arrival` stays in `World` until Task 6, and the marker until Task 2.

```gdscript
	var pad := _hud.pad
	if pad:
		_player.stick_direction = pad.direction
		if pad.direction != Vector2.ZERO:
			_use_on_arrival = {}  # walking off by hand drops the tap's errand
	if _grass:
		Vegetation.set_pusher(_grass, _player.global_position)
	if _particles:
		ZoneParticles.follow(_particles, _player.global_position)
	_hud.step(_player.global_position, _player.last_step_m)
```

  - `_unhandled_input`: `if _pad:` / `if _pad.handle(event):` → `var pad := _hud.pad`, `if pad:`, `if pad.handle(event):`.
  - `_show_prompt`:

```gdscript
func _show_prompt(near: Dictionary) -> void:
	_clear_signs_under(_hud.show_prompt(_prompt_text(near), _action_key_name()))
```

  - `_hide_prompt`: the body becomes `_restore_signs()` then `_hud.hide_prompt()`.
  - `_prompt_showing`: the body becomes `return _hud.prompt_showing()`.
  - `set_active`: `_ui.visible = active` → `_hud.visible = active`.
  - `set_audio`: `_dialogue.set_audio(audio)` → `_hud.dialogue.set_audio(audio)`.
  - `show_dialogue`: `await _dialogue.say(speaker, lines)` → `await _hud.dialogue.say(speaker, lines)`.
  - `say_lines`: the same change as `show_dialogue`.
  - `ask`: `_ui.add_child(window)` → `_hud.add_child(window)`.
  - `freeze`: the last three lines (`if not _banner_shown and not _player.scripted:` ... `_show_banner()`) become:

```gdscript
	if not _player.scripted:
		_hud.show_banner_once()
```

  - `begin_cutscene`: replace the lines from `_status_column.hide()` to `_banner.hide()` with `_hud.begin_cutscene()`. Everything else stays in the same order.
  - `end_cutscene`: replace `_status_column.show()`, `_map_square.show()` and `_place_label.show()` with `_hud.end_cutscene()`.

  **Wiring in `_ready()`.**
  1. Right after the dungeon block, create the piece:

```gdscript
	_hud = MapHud.new()
	_hud.setup(zone)
```

     It must exist this early: `set_world_flags({})` further down reaches `_refresh_map_marks()`, which returns at once while nothing is explored.
  2. Replace the two lines `_build_ui()` and `_place_label.text = zone.map_label()` (right after `_marker = _build_marker()`) with:

```gdscript
	_hud.map_pressed.connect(_on_map_pressed)
	_hud.tapped.connect(_on_tapped)
	_hud.pinched.connect(_camera.zoom_by)
	_hud.use_pressed.connect(func() -> void: _use(_nearest_use(_player.global_position)))
	add_child(_hud)
```

- [ ] **Step 6: Import and validate**

```bash
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --import 2>&1 | grep -E "ERROR|Parse Error|SCRIPT ERROR"
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --check-only --script res://scripts/world/map_hud.gd
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --check-only --script res://scripts/world/world.gd
ls scripts/world/map_hud.gd.uid
```

  Expected:
  - The `grep` prints nothing.
  - Each `--check-only` prints only the `Godot Engine v4.7.2...` banner line, with no `Parse Error` or `SCRIPT ERROR`.
  - The `.uid` file exists.
  - `grep -nE '\b_(ui|dialogue|map_square|notice|notice_word|notice_window|notice_tween|banner|banner_tween|banner_shown|hint|hint_window|prompt|prompt_box|prompt_key|prompt_cap|use_button|pad|status_column|name_label|gold_label|mission_box|missions|has_explored)\b' scripts/world/world.gd` prints nothing.

- [ ] **Step 7: The v1 run, compared with the reference**

```bash
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --fixed-fps 10 --quit-after 150000 -- --autoplay > C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/v1.log 2>&1
grep -E '^(Zona|Escena|Lugar|Compañero|Pregunta|Misión cumplida|Juego completado|Medallas|Eco de la Niebla)' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/v1.log > C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/v1.ref.m
grep -E '^(Zona|Escena|Lugar|Compañero|Pregunta|Misión cumplida|Juego completado|Medallas|Eco de la Niebla)' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/v1.log > C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/v1.new.m
diff C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/v1.ref.m C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/v1.new.m
grep -E 'ERROR|WARNING' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/v1.log
grep -c '^Partida guardada.$' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/v1.log
```

  Expected:
  - **Milestones.** The `Zona:`, `Escena:` and `Lugar:` lines are the same and in the same order. The `Juego completado:` line has the same level (Nv 18), and its play time is within about 5 minutes of the reference. `Misión cumplida` lines may differ in number within the usual spread (4 to 6 missions). This is the only difference `diff` may show.
  - **Errors.** The `ERROR|WARNING` grep prints at most the known Jolt warning.
  - **Notices.** The `Partida guardada.` count is above 0: notices still print.
  - **If the milestones differ:** run it once more. If they differ twice, stop and follow the guide's *Cuándo parar*: `git reset --hard` to the previous commit on this branch, then rethink the piece.

- [ ] **Step 8: Frames and the phone, by eye**

```bash
mkdir -p C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/hud-frames
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --path . --write-movie C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/hud-frames/f.png --fixed-fps 10 --quit-after 600 -- --autoplay
```

  Open the same frame numbers in `ref/movie/` and `p3/hud-frames/` (for example `f00000100.png`, `f00000300.png` and `f00000550.png`) with the Read tool. Expected:
  - the status window in the top left, with the name, PV, PM, EXP, gold and the missions;
  - the place line and the map square under it;
  - a notice window at the top centre;
  - the "Pradera de Villaclaro" banner on the first frames on the map;
  - the prompt and its keycap near a figure.

  The layout is the same, and the content varies only as much as the reference does.

  Then the phone layout by hand:

```bash
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --path . --resolution 740x360 -- --touch
```

  Start a new game and check:
  - a drag walks (the stick is drawn);
  - a tap on the ground walks there with the ring;
  - a pinch is not possible with the mouse, so skip it;
  - the "Hablar · ..." use button shows next to a figure and works;
  - the walking hint shows and goes on the first steps;
  - a tap on the map square opens the Mapa page;
  - the ☰ menu hides the status window and the square.

  Then close the window and delete the frames:

```bash
rm -r C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/hud-frames
```

- [ ] **Step 9: Update `CLAUDE.md` *Layout***

  - In the `scenes/world/world.tscn + scripts/world/world.gd (World)` bullet, replace each text on the left with the text on the right, exactly:
    - `` (`_build_touch_controls()`; its taps walk like clicks `` → `` (`MapHud._build_touch_controls()`; its taps walk like clicks ``
    - `` (`_show_banner()`, printed on autoplay as `Lugar: ...` `` → `` (`MapHud._show_banner()`, printed on autoplay as `Lugar: ...` ``
    - `` `_refresh_map_marks()` after `set_explored()` `` → `` `MapHud.refresh_map_marks()` after `set_explored()` ``
  - Right after the end of that bullet, add this new bullet:

```markdown
- `scripts/world/map_hud.gd` (`MapHud`, `CanvasLayer`, `UiTokens.LAYER_HUD`) — the map's 2D layer, owned by `World` (refactor M-71): `setup(zone)` before `add_child`, it builds itself in `_ready()` (`_build_ui()`, `_build_banner()`, on a phone `_build_touch_controls()`). It holds the status window, the place line and the `MapSquare`, the notice window, the banner, the prompt and its keycap (`show_prompt(text, key_name)` returns the rect it covers, `hide_prompt()`, `prompt_showing()`), the phone's `TouchPad` (`pad`) and use button, the walking hint and the `DialogueBox` (`dialogue`). `step(hero_pos, last_step_m)` every physics tick, `reset_pad()`, `show_banner_once()`, `begin_cutscene()` / `end_cutscene()`, `set_explored()`, `refresh_map_marks(flags, dry_wells)`. Signals `map_pressed`, `tapped(screen)`, `pinched(ratio)`, `use_pressed`, which `World` turns into `map_requested`, a walk, a zoom and a use. `World.refresh_status()`, `set_status_shown()`, `show_mission_done()`, `show_notice()` and `show_touch_hint()` are façades of it; `World.BANNER_FADE` is `MapHud.BANNER_FADE`.
```

- [ ] **Step 10: Commit**

```bash
git add scripts/world/map_hud.gd scripts/world/map_hud.gd.uid scripts/world/world.gd CLAUDE.md
git commit -m "Move the map's 2D layer from World into MapHud"
git status --short
```

  Expected: one commit, and `git status --short` prints nothing.

---

### Task 2: `MapProps` (exits, portal, wells, chests, the walk marker)

**Files:**
- Create: `scripts/world/map_props.gd`
- Modify: `scripts/world/world.gd`
- Modify: `CLAUDE.md`

**Interfaces:**
- Consumes: `MapHud.refresh_map_marks(flags, dry_wells)` (Task 1).
- Produces:
  - `class_name MapProps extends Node3D`
  - `func setup(zone: ZoneData) -> void`, `func build() -> void`, `func build_marker() -> void`, `func show_marker(target: Variant) -> void`
  - `func set_flags(flags: Dictionary) -> void`, `static func is_open(exit: Dictionary, flags: Dictionary) -> bool`
  - `func set_portal(on: bool) -> void`, `func set_return_mark(on: bool, pos: Vector3) -> void`, `func has_portal() -> bool`
  - `func set_dry_wells(dry: Array[String]) -> void`, `var dry_wells: Array[String]` (getter), `func well_kind(id: String) -> String`
  - `static func build_chest(root: Node3D, chest: Dictionary) -> Node3D`, `func set_chest_open(chest_id: String, open: bool, instant := false) -> void`, `func closed_chests() -> Array[String]`

- [ ] **Step 1: Create `scripts/world/map_props.gd` with this skeleton**

```gdscript
class_name MapProps extends Node3D
## The things that stand on a map and change with the game: the exits (arch, sign and the
## fog bank of a closed one), the Ala de viaje's return portal and the ring of the spot it
## leads back to, the wells (their water and light hidden while dry), the chests (a lid on
## a hinge) and the ring on the spot the player walks to. Owned by World, which calls
## setup(), adds it and then build(); never stores World.

## Chest model: wooden box with a gold band and a lid hinged at the back.
const CHEST_SIZE := Vector3(0.9, 0.45, 0.6)
const CHEST_LID_HEIGHT := 0.2
const CHEST_WOOD := Color(0.5, 0.3, 0.14)
const CHEST_BAND := Color(1.0, 0.78, 0.2)
## Angle of an open lid (degrees about X: the front edge swings up and back).
const CHEST_OPEN_ANGLE := 110.0
## Wells: a collider the hero walks around, and a disc of coloured water with a light.
const WELL_COLLIDER := 1.3
const WATER_HP := Color(1.0, 0.25, 0.25)
const WATER_MP := Color(0.25, 0.5, 1.0)
const WATER_RADIUS := 0.95
const WATER_HEIGHT := 1.2
## Exit arch: two posts and a beam of dark wood, a sign board with the exit's label
## (always facing the camera, south) and, while closed, a bank of fog.
const ARCH_WOOD := Color(0.36, 0.22, 0.1)
const ARCH_WIDTH := 3.6
const ARCH_HEIGHT := 3.0
const SIGN_COLOR := Color(0.62, 0.45, 0.25)
const FOG_COLOR := Color(0.92, 0.93, 0.97, 0.6)

## The wells that are dry now (World.set_dry_wells()); the map square's marks follow them.
var dry_wells: Array[String]:
	get:
		return _dry_wells

var _zone: ZoneData
## chest id -> lid pivot (rotation.x opens it); a chest in _open_chests is open.
var _chest_lids := {}
var _open_chests: Array[String] = []
## Well id -> its water and light, hidden while it is dry.
var _well_waters := {}
var _dry_wells: Array[String] = []
## exit id -> fog bank shown while the exit is closed.
var _fogs := {}
## exit id -> its root (arch, sign and fog): hidden while the exit is not present
## (ZoneData.is_present()).
var _arches := {}
## The return portal and the mark of the spot it leads back to (null while not on this map).
var _portal: Node3D
var _return_mark: Node3D
var _marker: MeshInstance3D


func setup(zone: ZoneData) -> void:
	_zone = zone


## The zone's chests, wells and exit arches (the stairs of a dungeon floor have none).
func build() -> void:
	for id in Chests.of_zone(_zone.id):
		_chest_lids[id] = build_chest(self, Chests.CHESTS[id])
	for well: Dictionary in _zone.wells:
		_build_well(well)
	for exit: Dictionary in _zone.all_exits():
		if not exit.get("stairs", false):
			_fogs[exit.id] = _build_exit(exit)


## The world flags: an exit not present hides, a closed one shows its fog.
func set_flags(flags: Dictionary) -> void:
	for exit: Dictionary in _zone.exits:
		var present := ZoneData.is_present(exit, flags)
		(_arches[exit.id] as Node3D).visible = present
		(_fogs[exit.id] as Node3D).visible = present and not is_open(exit, flags)


static func is_open(exit: Dictionary, flags: Dictionary) -> bool:
	return exit.lock == "" or flags.get(exit.lock, false)


func has_portal() -> bool:
	return _portal != null


## The chests of this zone not opened yet, in the order they were built.
func closed_chests() -> Array[String]:
	var closed: Array[String] = []
	for id in _chest_lids:
		if not _open_chests.has(id):
			closed.append(id)
	return closed


## The ring on the spot the player walks to (Player.move_target, null for none).
func show_marker(target: Variant) -> void:
	_marker.visible = target != null
	if _marker.visible:
		_marker.position = target
```

  `build()` is the three loops of `World._ready()`. `World` keeps its own `_exits = zone.all_exits()` until Task 6. `all_exits()` is pure, so calling it twice gives the same list.

  The other new functions are taken from these old lines:
  - `set_flags()` is the exits loop of `World.set_world_flags()`;
  - `is_open()` is `World._is_open()` with the flags passed in;
  - `closed_chests()` is the chest loop of `World._uses()`;
  - `show_marker()` is the two marker lines of `World._physics_process()`.

- [ ] **Step 2: Move these members from `world.gd` into `map_props.gd`, as they are**

  **Constants:** the ones in the skeleton (`CHEST_SIZE`, `CHEST_LID_HEIGHT`, `CHEST_WOOD`, `CHEST_BAND`, `CHEST_OPEN_ANGLE`, `WELL_COLLIDER`, `WATER_HP`, `WATER_MP`, `WATER_RADIUS`, `WATER_HEIGHT`, `ARCH_WOOD`, `ARCH_WIDTH`, `ARCH_HEIGHT`, `SIGN_COLOR` and `FOG_COLOR`). Delete them, and the stray comment line `## Marks on the map square.`, from `World`.

  **Variables:** `_chest_lids`, `_open_chests`, `_well_waters`, `_dry_wells`, `_fogs`, `_arches`, `_portal`, `_return_mark` and `_marker`. Delete them from `World`.

  **Functions:**
  - `_build_exit`, verbatim. It already writes `_arches[exit.id] = root`, and its `add_child(root)` now adds the arch to `MapProps`.
  - `_build_portal`, verbatim.
  - `set_portal`, with `zone.portal_pos` → `_zone.portal_pos`.
  - `set_return_mark`, verbatim.
  - `_build_well`, with `zone.id` → `_zone.id`.
  - `_well_kind` → `well_kind` (public), with `zone.wells` → `_zone.wells`.
  - `build_chest` (static), verbatim.
  - `set_chest_open`, verbatim.
  - `set_dry_wells`, without its last line `_refresh_map_marks()`, which stays in `World`'s façade.
  - `_build_marker` becomes `build_marker() -> void`. The body is the same, but its last line is `_marker = marker` instead of `return marker`, and `add_child(marker)` adds the marker to `MapProps`.

  Delete `World._is_open`.

- [ ] **Step 3: Leave the façades and wire `MapProps` in `world.gd`**

  Add `var _props: MapProps`. The façades keep their doc comments:

```gdscript
func set_portal(on: bool) -> void:
	_props.set_portal(on)


func set_return_mark(on: bool, pos: Vector3) -> void:
	_props.set_return_mark(on, pos)


func set_dry_wells(dry: Array[String]) -> void:
	_props.set_dry_wells(dry)
	_refresh_map_marks()


func set_chest_open(chest_id: String, open: bool, instant := false) -> void:
	_props.set_chest_open(chest_id, open, instant)


static func build_chest(root: Node3D, chest: Dictionary) -> Node3D:
	return MapProps.build_chest(root, chest)
```

  **Inside `World`, change these lines:**

  - `_refresh_map_marks`: `_hud.refresh_map_marks(_flags, _dry_wells)` → `_hud.refresh_map_marks(_flags, _props.dry_wells)`.
  - `set_world_flags`: replace its `for exit: Dictionary in zone.exits:` loop with `_props.set_flags(flags)`. The order stays: groups, then props, then dungeon, then marks.
  - `_physics_process`: replace the two marker lines (`_marker.visible = _player.move_target != null` and the `if _marker.visible:` block) with `_props.show_marker(_player.move_target)`.
  - `_check_exits`: `if not _is_open(nearest):` → `if not MapProps.is_open(nearest, _flags):`.
  - `_uses`:
    - `for id in _chest_lids:` / `if not _open_chests.has(id):` → `for id in _props.closed_chests():`, with the `uses.append` block one indent less;
    - `if _portal != null:` → `if _props.has_portal():`.
  - `_use`: `_well_kind(use.id)` → `_props.well_kind(use.id)`.

  **Wiring in `_ready()`.**
  1. Replace the three loops (`for id in Chests.of_zone(zone.id):`, `for well ... _build_well(well)`, `for exit ... _fogs[exit.id] = _build_exit(exit)`) with the following. The line `_exits = zone.all_exits()` stays between them.

```gdscript
	_props = MapProps.new()
	_props.setup(zone)
	add_child(_props)
	_props.build()
	_exits = zone.all_exits()
```

  2. `_marker = _build_marker()` → `_props.build_marker()`. It sits at the same point, after the camera and before the HUD.

  `_props` must exist before `set_world_flags({})`, and it does, since that call comes after this block.

- [ ] **Step 4: Import and validate**

```bash
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --import 2>&1 | grep -E "ERROR|Parse Error|SCRIPT ERROR"
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --check-only --script res://scripts/world/map_props.gd
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --check-only --script res://scripts/world/world.gd
```

  Expected:
  - The `grep` prints nothing.
  - Each `--check-only` prints only the engine banner line.
  - `grep -nE '\b_(chest_lids|open_chests|well_waters|dry_wells|fogs|arches|return_mark|marker|portal)\b' scripts/world/world.gd` prints nothing.

- [ ] **Step 5: The v1 and jungla runs, compared with the reference**

```bash
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --fixed-fps 10 --quit-after 150000 -- --autoplay > C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/v1.log 2>&1
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --fixed-fps 10 --quit-after 40000 -- --autoplay --autoplay-zone=jungla > C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/jungla.log 2>&1
grep -E '^(Zona|Escena|Lugar|Compañero|Pregunta|Misión cumplida|Juego completado|Medallas|Eco de la Niebla)' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/v1.log > C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/v1.new.m
diff C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/v1.ref.m C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/v1.new.m
grep -E '^(Zona|Escena|Lugar|Compañero|Pregunta|Misión cumplida|Juego completado|Medallas|Eco de la Niebla)' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/zone_jungla.log > C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/jungla.ref.m
grep -E '^(Zona|Escena|Lugar|Compañero|Pregunta|Misión cumplida|Juego completado|Medallas|Eco de la Niebla)' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/jungla.log > C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/jungla.new.m
diff C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/jungla.ref.m C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/jungla.new.m
grep -E 'ERROR|WARNING' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/v1.log C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/jungla.log
grep -cE 'Retirada al pueblo|El portal te devuelve' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/v1.log
grep -cE '^¡Encuentras|^Abres la reja|^Has encontrado|G\.$' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/v1.log
```

  Expected:
  - **v1 milestones,** as in Task 1 Step 7: the same `Zona:`, `Escena:` and `Lugar:` sequence; `Juego completado: Nv 18` with the time within about 5 minutes; `Misión cumplida` within its usual spread.
  - **Jungla milestones:** the same `Zona:` / `Lugar:` / `Compañero:` / `Escena: jaguar` sequence.
  - **Errors:** only the Jolt warning.
  - **The portal** (`Retirada al pueblo` / `El portal te devuelve`): a count above 0 whenever `ref/v1.log` has one too (check with the same grep on it).
  - **Chests:** the chest lines found are about as many as in the reference (the same grep on `ref/v1.log`).

  If the milestones differ twice, stop as in Task 1 Step 7.

- [ ] **Step 6: Frames, by eye (arches, fog, chests, wells, portal)**

```bash
mkdir -p C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/props-frames
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --path . --write-movie C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/props-frames/f.png --fixed-fps 10 --quit-after 600 -- --autoplay
```

  Compare a few frames with the same numbers in `ref/movie/`. Expected:
  - the village's wells, with their red or blue water;
  - the 25 G chest near the route, with its lid opening when it is used;
  - the north exit's arch with its sign and its fog bank;
  - the walk marker ring where the hero heads.

  Then delete the frames:

```bash
rm -r C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/props-frames
```

- [ ] **Step 7: Update `CLAUDE.md` *Layout***

  - In the World bullet, replace each text on the left with the text on the right:
    - `` its wells (`_build_well()`: `` → `` its wells (`MapProps._build_well()`: ``
    - `` (`_arches`, `set_world_flags()`) `` → `` (`MapProps._arches`, `set_world_flags()`) ``
  - In the 2.5.0 bullet, `` `World._build_portal()` `` → `` `MapProps._build_portal()` ``.
  - Add this bullet right after the `MapHud` bullet:

```markdown
- `scripts/world/map_props.gd` (`MapProps`, `Node3D`) — the props of a map that change with the game, owned by `World` (refactor M-71): `setup(zone)`, then `build()` (the chests, the wells and the exit arches with their sign and fog) and `build_marker()` (the walk ring; `show_marker(target)` every physics tick). `set_flags(flags)` (an exit not present hides, a closed one shows its fog; `static is_open(exit, flags)`), `set_portal()` / `set_return_mark()` / `has_portal()` (the Ala's `TravelPortal`), `set_dry_wells()` / `dry_wells` / `well_kind()`, `static build_chest()`, `set_chest_open()`, `closed_chests()`. `World.set_portal()`, `set_return_mark()`, `set_dry_wells()`, `set_chest_open()` and `build_chest()` are façades of it.
```

- [ ] **Step 8: Commit**

```bash
git add scripts/world/map_props.gd scripts/world/map_props.gd.uid scripts/world/world.gd CLAUDE.md
git commit -m "Move exits, portal, wells, chests and the walk marker from World into MapProps"
git status --short
```

  Expected: one commit, and the working tree is clean.

---

### Task 3: `MapFigures` (figures, signs, quest marks)

**Files:**
- Create: `scripts/world/map_figures.gd`
- Modify: `scripts/world/world.gd`
- Modify: `CLAUDE.md`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces:
  - `class_name MapFigures extends Node3D`
  - `func setup(zone: ZoneData, player: Player) -> void`, `func build() -> void`
  - `func add_figure(look: BattleActor.Look, pos: Vector3, yaw_deg: float, radius: float, height: float) -> StaticBody3D` (copy the `look` type hint exactly as plan 2 left it)
  - `func set_quest_view(marks: Dictionary, hidden_names: Array[String]) -> void`, `func show_marks() -> void`, `func has_mark(figure_name: String) -> bool`
  - `var hidden: Array[String]` (getter), `var signs: Array[Label3D]` (getter), `func set_signs_shown(on: bool) -> void`
  - `func figure_node(who: String) -> Node3D`, `func figure_turn(who: String) -> Node3D`, `func figure_actor(who: String) -> BattleActor`, `func reset_figures() -> void`
  - `func npc_lines(index: int, chapter: int) -> Array[String]`

- [ ] **Step 1: Create `scripts/world/map_figures.gd` with this skeleton**

```gdscript
class_name MapFigures extends Node3D
## The figures of a map (ZoneData.npcs, and the boss World asks for with add_figure()):
## each a BattleActor on a cylinder collider, with its sign ("Tienda", "Posada",
## "Criaturas") and the "!" or "?" of the quests over it; the figures a quest has not
## brought out are off the map. Cutscenes find and move them here (figure_node(),
## figure_turn(), figure_actor(), reset_figures()). Owned by World, which calls setup(),
## adds it and then build(); never stores World.

const ACTOR_SCENE := preload("res://scenes/battle/battle_actor.tscn")
## The "!" and "?" of the quests: over the figure, bobbing.
const QUEST_MARK_GAP := 0.35
const QUEST_MARK_BOB := 0.12
## A quest mark over a figure with a sign ("Posada") goes above the sign.
const FIGURE_SIGN_RISE := 0.65
const FIGURE_SIGN_GAP := 0.25
const FIGURE_SIGN_PIXEL := 0.012

## The figures that are not on the map now (set_quest_view()): nothing to use there.
var hidden: Array[String]:
	get:
		return _hidden_figures
## The signs over the figures (MapUses hides the ones under the prompt).
var signs: Array[Label3D]:
	get:
		return _figure_signs

var _zone: ZoneData
var _player: Player
## ZoneData.npcs "name" -> its figure (a StaticBody3D with the BattleActor under it).
var _figures := {}
## Figure name -> "!" or "?", the figures that are not on the map, and the labels so far.
var _quest_marks := {}
var _hidden_figures: Array[String] = []
var _mark_labels := {}
var _figure_signs: Array[Label3D] = []


func setup(zone: ZoneData, player: Player) -> void:
	_zone = zone
	_player = player


## A figure and its sign for every ZoneData.npcs entry.
func build() -> void:
	for npc: Dictionary in _zone.npcs:
		_figures[npc.name] = add_figure(BattleActor.Look[npc.look], npc.pos, npc.yaw, 0.4,
			1.8)
		_add_figure_sign(npc)


func has_mark(figure_name: String) -> bool:
	return _quest_marks.has(figure_name)


## Every figure sign shown (true) or hidden (false): cutscenes hide them.
func set_signs_shown(on: bool) -> void:
	for label in _figure_signs:
		label.visible = on
```

  The new functions come from these old lines:
  - `build()` is the npc loop of `World._ready()`;
  - `has_mark()` is the `_quest_marks.has(...)` test of `World._physics_process()`;
  - `set_signs_shown()` is the `for label in _figure_signs: label.hide()` and `label.show()` loops of `begin_cutscene()` and `end_cutscene()`.

- [ ] **Step 2: Move these members from `world.gd` into `map_figures.gd`, as they are**

  **Constants:** `QUEST_MARK_GAP`, `QUEST_MARK_BOB`, `FIGURE_SIGN_RISE`, `FIGURE_SIGN_GAP` and `FIGURE_SIGN_PIXEL`. `ACTOR_SCENE` is copied, because `World._add_group` still uses it until Task 4.

  **Variables:** `_figures` (the dictionary), `_quest_marks`, `_hidden_figures`, `_mark_labels` and `_figure_signs`.

  **Functions:**
  - `_add_figure` becomes `add_figure`, verbatim. Its `add_child(body)` now adds the figure to `MapFigures`.
  - `_add_figure_sign`, verbatim.
  - `_figure_sign_text` (static), verbatim.
  - `_build_mark`, with `zone.npcs` → `_zone.npcs`.
  - `set_quest_view`, with `zone.npcs` → `_zone.npcs`, and its last line `_show_quest_marks()` → `show_marks()`.
  - `_show_quest_marks` becomes `show_marks`, with `zone.npcs` → `_zone.npcs`.
  - `figure_node`, `figure_turn` and `figure_actor`, verbatim (`_player` is the piece's own).
  - `reset_figures`, with `zone.npcs` → `_zone.npcs`.
  - `npc_lines`, with `zone.npcs` → `_zone.npcs`.

- [ ] **Step 3: Leave the façades and wire `MapFigures` in `world.gd`**

  Add `var _figures: MapFigures`. The dictionary of that name is gone from `World`. The façades keep their doc comments:

```gdscript
func npc_lines(index: int, chapter: int) -> Array[String]:
	return _figures.npc_lines(index, chapter)


func figure_node(who: String) -> Node3D:
	return _figures.figure_node(who)


func figure_turn(who: String) -> Node3D:
	return _figures.figure_turn(who)


func figure_actor(who: String) -> BattleActor:
	return _figures.figure_actor(who)


func reset_figures() -> void:
	_figures.reset_figures()


func set_quest_view(marks: Dictionary, hidden_names: Array[String]) -> void:
	_figures.set_quest_view(marks, hidden_names)
```

  **Inside `World`, change these lines:**

  - `_physics_process`: `or _quest_marks.has(zone.npcs[near.index].name):` → `or _figures.has_mark(zone.npcs[near.index].name):`.
  - `_uses`: `if _hidden_figures.has(npc.name):` → `if _figures.hidden.has(npc.name):`.
  - `_clear_signs_under`: `for label in _figure_signs:` → `for label in _figures.signs:`.
  - `begin_cutscene`: `_show_quest_marks()` → `_figures.show_marks()`, and the `for label in _figure_signs: label.hide()` loop → `_figures.set_signs_shown(false)`. The order stays: `_hud.begin_cutscene()`, `_figures.show_marks()`, `_signs_under_prompt.clear()`, `_figures.set_signs_shown(false)`.
  - `end_cutscene`: `_show_quest_marks()` → `_figures.show_marks()`, and the `label.show()` loop → `_figures.set_signs_shown(true)`.

  **Wiring in `_ready()`.**
  1. Move `_player = PLAYER_SCENE.instantiate()` up to right after `_hud.setup(zone)`, because `MapFigures` needs the player. `_player.route = zone.autoplay_route` and `add_child(_player)` stay where they are: an instantiated scene does nothing until it enters the tree.
  2. Replace the npc loop (`for npc: Dictionary in zone.npcs:` with its two lines) with:

```gdscript
	_figures = MapFigures.new()
	_figures.setup(zone, _player)
	add_child(_figures)
	_figures.build()
```

  3. The boss: `_boss = _add_figure(EnemyLibrary.look(boss_id), zone.boss_pos, 180.0, 1.0, 2.0)` → `_boss = _figures.add_figure(EnemyLibrary.look(boss_id), zone.boss_pos, 180.0, 1.0, 2.0)`.

- [ ] **Step 4: Import and validate**

```bash
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --import 2>&1 | grep -E "ERROR|Parse Error|SCRIPT ERROR"
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --check-only --script res://scripts/world/map_figures.gd
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --check-only --script res://scripts/world/world.gd
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --check-only --script res://scripts/story/cutscene_player.gd
```

  Expected:
  - The `grep` prints nothing.
  - Each `--check-only` prints only the engine banner line.
  - `grep -nE '\b_(quest_marks|hidden_figures|mark_labels|figure_signs|add_figure|show_quest_marks)\b' scripts/world/world.gd` prints nothing.

- [ ] **Step 5: The v1 and jungla runs, compared with the reference**

  Run the same seven commands as Task 2 Step 5: the two runs, the two milestone extracts with their `diff`, and the `ERROR|WARNING` grep. Then:

```bash
grep -c '^Escena: ' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/v1.log
grep -c '^Escena: ' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/v1.log
```

  Expected:
  - The milestones are as in Task 2 Step 5, and there is only the Jolt warning.
  - Both `Escena:` counts are the same: every cutscene finds and moves its figures.

- [ ] **Step 6: Frames, by eye (signs and marks)**

```bash
mkdir -p C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/fig-frames
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --path . --write-movie C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/fig-frames/f.png --fixed-fps 10 --quit-after 600 -- --autoplay
```

  Expected:
  - "Tienda", "Posada" and "Criaturas" over the merchant, the innkeeper and the Domadora;
  - a yellow "!" or "?" bobbing over the Abuela Rosa;
  - neither of them during the prologue's frames;
  - the same figures in the same places as `ref/movie/`.

  Then delete the frames:

```bash
rm -r C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/fig-frames
```

- [ ] **Step 7: Update `CLAUDE.md` *Layout***

  - In the World bullet, `` "Criaturas", `_add_figure_sign()`, `` → `` "Criaturas", `MapFigures._add_figure_sign()`, ``.
  - Add this bullet after the `MapProps` one:

```markdown
- `scripts/world/map_figures.gd` (`MapFigures`, `Node3D`) — the figures of a map, owned by `World` (refactor M-71): `setup(zone, player)`, then `build()` (a `BattleActor` on a cylinder collider for each `ZoneData.npcs` entry, with its sign, `_add_figure_sign()`); `add_figure()` also builds the boss for `World`. `set_quest_view(marks, hidden_names)`, `show_marks()` (the "!" / "?" labels, none during a cutscene), `has_mark()`, `hidden`, `signs`, `set_signs_shown()`, `figure_node()` / `figure_turn()` / `figure_actor()` / `reset_figures()` (cutscenes), `npc_lines(index, chapter)`. `World`'s methods of those names are façades of it.
```

- [ ] **Step 8: Commit**

```bash
git add scripts/world/map_figures.gd scripts/world/map_figures.gd.uid scripts/world/world.gd CLAUDE.md
git commit -m "Move the map's figures, signs and quest marks from World into MapFigures"
git status --short
```

  Expected: one commit, and the working tree is clean.

---

### Task 4: `MapMonsters` (the groups of monsters)

**Files:**
- Create: `scripts/world/map_monsters.gd`
- Modify: `scripts/world/world.gd`
- Modify: `CLAUDE.md`

**Interfaces:**
- Consumes: `RunFlags.autoplay()`.
- Produces:
  - `class_name MapMonsters extends Node3D`
  - `signal groups_reset` (the groups were replaced or cleared: forget the hunt's skips)
  - `static var debug_no_groups := false`
  - `var groups: Array[Dictionary]` (getter)
  - `func setup(zone: ZoneData, player: Player) -> void`, `func set_flags(flags: Dictionary) -> void`
  - `func respawn_groups(avoid: Array[Vector3] = []) -> void`, `func group_count() -> int`, `func clear_groups() -> void`
  - `func add_rare(enemy_id: String) -> void`, `func has_rare() -> bool`
  - `func move_groups(delta: float) -> void`, `func tick_refill(delta: float) -> void`
  - `func check_contact(pos: Vector3, now_ms: int) -> bool`, `func calm(now_ms: int) -> void`
  - `func contact_enemies() -> Array[Combatant]`, `func end_contact(outcome: int) -> void`
  - `func group_index(node: Node3D) -> int`
  - `func set_shy(on: bool) -> void`, `func set_repel(on: bool, now_ms: int) -> void`, `func is_repelled() -> bool`

- [ ] **Step 1: Create `scripts/world/map_monsters.gd` with this skeleton**

```gdscript
class_name MapMonsters extends Node3D
## The groups of monsters walking on a map (MonsterGroups, MonsterRoam): placed, moved
## every physics tick near the hero, touched (check_contact(): World then starts the
## battle), taken off when beaten, faded while fled from or while an Incienso burns, and
## brought back one at a time (tick_refill()); on a dungeon floor also the Slime de Metal
## (add_rare()). Owned by World, which calls setup() and the per-tick functions in its own
## order; never stores World. On autoplay it prints "Grupos: n", "Grupo vencido (quedan n)"
## and "Grupo repuesto (n)".

## The groups were replaced or cleared (AutoplayHunter forgets the groups it left alone).
signal groups_reset

const ACTOR_SCENE := preload("res://scenes/battle/battle_actor.tscn")
## Groups of monsters farther than this from the hero neither move nor animate.
const GROUP_ANIMATE_RADIUS := 30.0
## Seconds between two hops of a slime walking on the map.
const HOP_TIME := 0.45
## Seconds of play on this map between two groups coming back while it has fewer than
## zone.monster_count, and the fade they come in with.
const REFILL_S := 45.0
const REFILL_FADE := 0.5

## DebugPanel's Monstruos: while set, no map puts any group of monsters or rare enemy
## (_add_group(), add_rare()). It lasts for the run; only DebugPanel changes it (through
## World.debug_no_groups).
static var debug_no_groups := false

## The groups on the map (AutoplayHunter reads them).
var groups: Array[Dictionary]:
	get:
		return _groups

var _zone: ZoneData
var _player: Player
var _autoplay := false
var _rng := RandomNumberGenerator.new()
## The world flags (World.set_world_flags(); the same Dictionary): an open gate is floor.
var _flags := {}
## The groups of monsters on the map (MonsterGroups), each {"node": Node3D (no collider),
## "actor": BattleActor (its first enemy's figure), "roam": MonsterRoam, "enemies":
## Array[Combatant] (the formation, data), "armed": bool (false: fled from, it starts no
## battle yet), "rare": bool (the Slime de Metal), "hop": seconds to its next hop}.
var _groups: Array[Dictionary] = []
## The hero is EncounterMeter.LEVEL_GAP levels past the zone: the moving groups keep away.
var _shy := false
## Index in _groups of the group whose battle is on (-1: none, or the boss's).
var _contact := -1
## No group starts a battle before this time (World's _sim_ms; calm()).
var _calm_until_ms := 0
## Simulation ms counted toward the next group coming back (tick_refill()).
var _refill_ms := 0.0
## True while an Incienso keeps the monsters away (Game counts its metres).
var _repelled := false


func setup(zone: ZoneData, player: Player) -> void:
	_zone = zone
	_player = player
	_autoplay = RunFlags.autoplay()
	# The groups are placed with the zone and the clock: never twice the same.
	_rng.seed = hash(zone.id) ^ Time.get_ticks_usec()


## The world flags: each group's MonsterRoam walks only on what is floor now.
func set_flags(flags: Dictionary) -> void:
	_flags = flags
	for group in _groups:
		(group.roam as MonsterRoam).set_flags(flags)


func is_repelled() -> bool:
	return _repelled


static func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))
```

  `set_flags()` is the groups loop of `World.set_world_flags()`. `_flags` is the same Dictionary `World` holds, handed down as it already is to `MonsterRoam` (see *Decisions*).

- [ ] **Step 2: Move these members from `world.gd` into `map_monsters.gd`**

  **Constants:** `GROUP_ANIMATE_RADIUS`, `HOP_TIME`, `REFILL_S` and `REFILL_FADE`. Delete `ACTOR_SCENE` from `World` too: after this task nothing there uses it.

  **Variables:** `_rng`, `_groups`, `_shy`, `_contact`, `_calm_until_ms`, `_refill_ms`, `_repelled` and `static var debug_no_groups`. Also delete the `_rng.seed = ...` line and its comment from `World._ready()`.

  **Functions verbatim** (`zone.` → `_zone.`; `_player`, `_autoplay` and `_rng` are the piece's own):
  - `respawn_groups`: its line `_hunt_skip.clear()` → `groups_reset.emit()`, in the same place.
  - `group_count`
  - `clear_groups`: its line `_hunt_skip.clear()` → `groups_reset.emit()`.
  - `add_rare`
  - `has_rare`
  - `_add_group`: `add_child(node)` now adds the group to `MapMonsters`.
  - `_fade_group`
  - `contact_enemies`
  - `end_contact`

  **Functions renamed** (the bodies are verbatim unless said otherwise):
  - `_tick_refill` → `tick_refill`.
  - `_move_groups` → `move_groups`.
  - `_group_index` → `group_index`.
  - `set_monsters_shy(on)` → `set_shy(on)`, the same body.
  - `_calm()` → `calm(now_ms: int)`, whose body is `_calm_until_ms = now_ms + MonsterGroups.CALM_MS`.
  - `_check_groups(pos)` → `check_contact(pos: Vector3, now_ms: int) -> bool`:
    - its first line becomes `var calm := now_ms < _calm_until_ms`;
    - inside the `if d <= MonsterGroups.CONTACT_RADIUS ...` block, keep `_contact = i` and `return true` and delete `_trigger(false)`, which `World` now calls.
  - `set_repel(on)` → `set_repel(on: bool, now_ms: int)`, with its last `_calm()` → `calm(now_ms)`.

- [ ] **Step 3: Leave the façades and wire `MapMonsters` in `world.gd`**

  Add `var _monsters: MapMonsters`. Replace `World`'s `static var debug_no_groups := false` with the alias, because `Game` and `DebugPanel` read and write `World.debug_no_groups` (verified in Godot 4.7.2: a static var with a getter and a setter that forward to another class's static var works, and both read and write the same value):

```gdscript
## DebugPanel's Monstruos (MapMonsters.debug_no_groups): Game and DebugPanel use this name.
static var debug_no_groups: bool:
	get:
		return MapMonsters.debug_no_groups
	set(value):
		MapMonsters.debug_no_groups = value
```

  The façades keep their doc comments:

```gdscript
func set_monsters_shy(on: bool) -> void:
	_monsters.set_shy(on)


func set_repel(on: bool) -> void:
	_monsters.set_repel(on, int(_sim_ms))


func respawn_groups(avoid: Array[Vector3] = []) -> void:
	_monsters.respawn_groups(avoid)


func group_count() -> int:
	return _monsters.group_count()


func clear_groups() -> void:
	_monsters.clear_groups()


func add_rare(enemy_id: String) -> void:
	_monsters.add_rare(enemy_id)


func has_rare() -> bool:
	return _monsters.has_rare()


func contact_enemies() -> Array[Combatant]:
	return _monsters.contact_enemies()


func end_contact(outcome: int) -> void:
	_monsters.end_contact(outcome)


## No group starts a battle for MonsterGroups.CALM_MS from now.
func _calm() -> void:
	_monsters.calm(int(_sim_ms))
```

  `World` keeps `_calm()` as a private helper, so `set_active`, `place_player` and `end_cutscene` stay as they are.

  **Inside `World`, change these lines:**

  - `set_world_flags`: the groups loop → `_monsters.set_flags(flags)`.
  - `_physics_process`:
    - `_move_groups(delta)` → `_monsters.move_groups(delta)`;
    - `_tick_refill(delta)` → `_monsters.tick_refill(delta)`;
    - `if _check_groups(pos): return` becomes the block below;
    - `if _autoplay and _hunt_on and not _repelled:` → `if _autoplay and _hunt_on and not _monsters.is_repelled():`.

```gdscript
	if _monsters.check_contact(pos, int(_sim_ms)):
		_trigger(false)
		return
```

  - `_update_hunt`, which stays in `World` until Task 5:
    - `_group_index(current)` → `_monsters.group_index(current)`;
    - `_groups[index].armed` → `_monsters.groups[index].armed`;
    - `for group in _groups:` → `for group in _monsters.groups:`.

  **Wiring in `_ready()`.**
  1. Right after `_figures.setup(zone, _player)`, create the piece. It must exist before `set_world_flags({})` and `place_at_entry()`:

```gdscript
	_monsters = MapMonsters.new()
	_monsters.setup(zone, _player)
	_monsters.groups_reset.connect(func() -> void: _hunt_skip.clear())
```

  2. Add `add_child(_monsters)` right before `place_at_entry(zone.start_entry)`, after `add_child(_hud)` and `set_explored(...)`. The group nodes then come after the HUD in the tree, as they did when they were `World`'s last children.

- [ ] **Step 4: Import and validate**

```bash
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --import 2>&1 | grep -E "ERROR|Parse Error|SCRIPT ERROR"
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --check-only --script res://scripts/world/map_monsters.gd
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --check-only --script res://scripts/world/world.gd
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --check-only --script res://scripts/game/game.gd
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --check-only --script res://scripts/ui/debug_panel.gd
```

  Expected:
  - The `grep` prints nothing.
  - Each `--check-only` prints only the engine banner line.
  - `grep -nE '\b_(groups|shy|contact|calm_until_ms|refill_ms|repelled|rng)\b|ACTOR_SCENE' scripts/world/world.gd` prints nothing (`_monsters.groups` does not match).

- [ ] **Step 5: The v1 and medallas runs, compared with the reference**

```bash
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --fixed-fps 10 --quit-after 150000 -- --autoplay > C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/v1.log 2>&1
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --fixed-fps 10 --quit-after 60000 -- --autoplay --autoplay-zone=medallas > C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/medallas.log 2>&1
grep -E '^(Zona|Escena|Lugar|Compañero|Pregunta|Misión cumplida|Juego completado|Medallas|Eco de la Niebla)' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/v1.log > C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/v1.new.m
diff C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/v1.ref.m C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/v1.new.m
grep -E '^Medallas' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/medallas.log
grep -E 'ERROR|WARNING' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/v1.log C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/medallas.log
for f in ref/v1.log p3/v1.log; do echo "$f"; grep -cE '^Grupos: [0-9]+' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/$f; grep -cE '^Grupo vencido \(quedan [0-9]+\)' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/$f; grep -cE '^Grupo repuesto \([0-9]+\)' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/$f; grep -c 'Slime de Metal en el mapa' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/$f; done
grep -E '^Grupos: ' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/v1.log | head -3
```

  Expected:
  - **v1 milestones** as in Task 1 Step 7.
  - **Medallas:** `Medallas: 12/12 · premios 5/5`.
  - **Errors:** only the Jolt warning.
  - **Counts:** each of the four counts is above 0 in both logs and of the same order. The Slime de Metal appears on the mine floors while its quest is on.
  - **First `Grupos:` lines:** `Grupos: 16` on the meadow, as in `ref/v1.log`.

- [ ] **Step 6: The debug alias, by hand**

```bash
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --path . -- --debug
```

  On the map, press F1, then Monstruos → "Quitar grupos". Expected:
  - the console prints a `Depuración: ...` line;
  - the groups go;
  - the button now reads "Poner grupos".

  Press it again. Expected: the groups come back (another `Depuración:` line). Close the game.

- [ ] **Step 7: Update `CLAUDE.md` *Layout***

  - In the 2.5.0 bullet, replace each text on the left with the text on the right:
    - `` `World._tick_refill()` every `REFILL_S` 45 s `` → `` `MapMonsters.tick_refill()` every `REFILL_S` 45 s ``
    - `` `_add_group()` returns the group `` → `` `MapMonsters._add_group()` returns the group ``
  - In the World bullet:
    - `` (`_add_group()` and `add_rare()` put nothing while it is set `` → `` (`MapMonsters._add_group()` and `add_rare()` put nothing while it is set; `World.debug_no_groups` is an alias of `MapMonsters.debug_no_groups` ``
    - `` a placing or a cutscene (`_calm()`) `` → `` a placing or a cutscene (`MapMonsters.calm()`) ``
  - Add this bullet after the `MapFigures` one:

```markdown
- `scripts/world/map_monsters.gd` (`MapMonsters`, `Node3D`) — the groups of monsters of a map, owned by `World` (refactor M-71): `setup(zone, player)` (seeds its own `_rng`), `set_flags()`, `respawn_groups()` / `group_count()` / `clear_groups()` (signal `groups_reset`), `add_rare()` / `has_rare()`, and the per-tick calls `World` makes in order: `move_groups(delta)`, `tick_refill(delta)`, `check_contact(pos, now_ms)` (true: `World._trigger(false)`). Also `calm(now_ms)`, `contact_enemies()` / `end_contact()`, `group_index()`, `groups`, `set_shy()`, `set_repel(on, now_ms)` / `is_repelled()`, and `static var debug_no_groups`. The clock is `World._sim_ms`, passed as `int`. `World`'s methods of those names, and `set_monsters_shy()`, are façades of it.
```

- [ ] **Step 8: Commit**

```bash
git add scripts/world/map_monsters.gd scripts/world/map_monsters.gd.uid scripts/world/world.gd CLAUDE.md
git commit -m "Move the groups of monsters from World into MapMonsters"
git status --short
```

  Expected: one commit, and the working tree is clean.

---

### Task 5: `AutoplayHunter` (the autoplay's hunt for groups)

**Files:**
- Create: `scripts/world/autoplay_hunter.gd`
- Modify: `scripts/world/world.gd`
- Modify: `CLAUDE.md`

**Interfaces:**
- Consumes: `MapMonsters.groups`, `MapMonsters.group_index(node)` and `MapMonsters.groups_reset` (Task 4).
- Produces:
  - `class_name AutoplayHunter extends RefCounted`
  - `func setup(zone: ZoneData, player: Player, monsters: MapMonsters) -> void`
  - `func is_on() -> bool`, `func set_on(on: bool) -> void`, `func forget() -> void`
  - `func step(pos: Vector3, now: int) -> void`

- [ ] **Step 1: Create `scripts/world/autoplay_hunter.gd` with this skeleton**

```gdscript
class_name AutoplayHunter extends RefCounted
## Autoplay only: below the zone's autoplay_boss_level (Game: set_on()) the hero leaves the
## route for the nearest group that can start a battle (Player.hunt()), gives up after
## AUTOPLAY_HUNT_MS (or stuck on the way, Player.take_failed_hunt()) and leaves that one
## alone for AUTOPLAY_HUNT_RETRY_MS. Its timers count World's _sim_ms, the simulation's own
## clock, so a run with --fixed-fps keeps them. Owned by World, which calls step() in its
## physics tick; it reads the groups of MapMonsters and never stores World.

const AUTOPLAY_HUNT_RADIUS := 60.0
const AUTOPLAY_HUNT_RADIUS_CAVE := 12.0  # walls: a straight line to a far group fails
const AUTOPLAY_HUNT_MS := 15000
const AUTOPLAY_HUNT_RETRY_MS := 20000

var _zone: ZoneData
var _player: Player
var _monsters: MapMonsters
## Hunt groups (Game: below the zone's autoplay_boss_level), until when the one hunted now
## is followed, and group instance id -> the time until which it is left alone.
var _hunt_on := false
var _hunt_until_ms := 0
var _hunt_skip := {}


func setup(zone: ZoneData, player: Player, monsters: MapMonsters) -> void:
	_zone = zone
	_player = player
	_monsters = monsters


func is_on() -> bool:
	return _hunt_on


## The groups were replaced or cleared (MapMonsters.groups_reset).
func forget() -> void:
	_hunt_skip.clear()


static func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))
```

  Plan 1 may already have put `set_autoplay_hunt` and `_update_hunt` in `World` under `#region Autoplay`. The whole of this file is autoplay, so it needs no region.

- [ ] **Step 2: Move these members from `world.gd` into `autoplay_hunter.gd`**

  **Constants:** `AUTOPLAY_HUNT_RADIUS`, `AUTOPLAY_HUNT_RADIUS_CAVE`, `AUTOPLAY_HUNT_MS` and `AUTOPLAY_HUNT_RETRY_MS`, with the comment block above them.

  **Variables:** `_hunt_on`, `_hunt_until_ms` and `_hunt_skip`.

  **Functions:**
  - `set_autoplay_hunt(on)` → `set_on(on: bool)`, the same body (`_hunt_on = on`; `if not on: _player.stop_hunt()`).
  - `_update_hunt(pos)` → `step(pos: Vector3, now: int)`:
    - delete its first line `var now := int(_sim_ms)`, since `now` is now the argument;
    - `_monsters.group_index(current)` and `_monsters.groups` stay as Task 4 wrote them;
    - `zone.is_dungeon()` → `_zone.is_dungeon()`.

- [ ] **Step 3: Leave the façade and wire `AutoplayHunter` in `world.gd`**

  Add `var _hunter: AutoplayHunter`. The façade keeps its doc comment:

```gdscript
func set_autoplay_hunt(on: bool) -> void:
	_hunter.set_on(on)
```

  **Inside `World`:** in `_physics_process`, the hunt block becomes:

```gdscript
	if _autoplay and _hunter.is_on() and not _monsters.is_repelled():
		_hunter.step(pos, int(_sim_ms))
```

  **Wiring in `_ready()`:** replace `_monsters.groups_reset.connect(func() -> void: _hunt_skip.clear())` with:

```gdscript
	_hunter = AutoplayHunter.new()
	_hunter.setup(zone, _player, _monsters)
	_monsters.groups_reset.connect(_hunter.forget)
```

  `_connect_standalone()` keeps calling `set_autoplay_hunt(true)`, the façade.

- [ ] **Step 4: Import and validate**

```bash
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --import 2>&1 | grep -E "ERROR|Parse Error|SCRIPT ERROR"
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --check-only --script res://scripts/world/autoplay_hunter.gd
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --check-only --script res://scripts/world/world.gd
```

  Expected:
  - The `grep` prints nothing.
  - Each `--check-only` prints only the engine banner line.
  - `grep -n "_hunt_\|AUTOPLAY_HUNT\|_update_hunt" scripts/world/world.gd` prints nothing.

- [ ] **Step 5: The v1 and medallas runs, compared with the reference**

  Run the same eight commands as Task 4 Step 5: the two runs, the milestone extract and `diff`, the `Medallas` grep, the `ERROR|WARNING` grep, the counts loop and the `Grupos:` head.

  Expected, as in Task 4 Step 5:
  - the same milestones;
  - `Medallas: 12/12 · premios 5/5`;
  - only the Jolt warning;
  - the four counts above 0.

  The hunt in particular: `Grupo vencido` is counted in the hundreds on v1, as in the reference, and medallas reaches 12/12 within its `MEDAL_TOUR_TIME`.

- [ ] **Step 6: Update `CLAUDE.md` *Layout***

  - In the World bullet, `` these timers and the calm after a battle count `_sim_ms`, `` → `` these timers (`AutoplayHunter`) and the calm after a battle (`MapMonsters.calm()`) count `World._sim_ms`, ``.
  - Add this bullet after the `MapMonsters` one:

```markdown
- `scripts/world/autoplay_hunter.gd` (`AutoplayHunter`, `RefCounted`) — autoplay only: the hunt for groups, owned by `World` (refactor M-71): `setup(zone, player, monsters)`, `set_on()` (what `World.set_autoplay_hunt()` calls), `is_on()`, `forget()` (on `MapMonsters.groups_reset`), `step(pos, now)` each physics tick while hunting and no Incienso burns (`AUTOPLAY_HUNT_RADIUS` 60 m, `_CAVE` 12 m, `AUTOPLAY_HUNT_MS` 15 s, `AUTOPLAY_HUNT_RETRY_MS` 20 s on `World._sim_ms`).
```

- [ ] **Step 7: Commit**

```bash
git add scripts/world/autoplay_hunter.gd scripts/world/autoplay_hunter.gd.uid scripts/world/world.gd CLAUDE.md
git commit -m "Move the autoplay hunt for groups from World into AutoplayHunter"
git status --short
```

  Expected: one commit, and the working tree is clean.

---

### Task 6: `MapUses` (prompts, uses, taps and exits)

**Files:**
- Create: `scripts/world/map_uses.gd`
- Modify: `scripts/world/world.gd`
- Modify: `scripts/world/map_hud.gd` (the prompt's sizing text)
- Modify: `CLAUDE.md`

**Interfaces:**
- Consumes:
  - from `MapHud`: `show_prompt(text, key_name) -> Rect2`, `hide_prompt()`, `prompt_showing()`, `show_notice()`;
  - from `MapFigures`: `hidden`, `signs`, `has_mark()`;
  - from `MapProps`: `closed_chests()`, `has_portal()`, `well_kind()`, `MapProps.is_open()`.
- Produces:
  - `class_name MapUses extends Node`
  - signals `talk_requested`, `npc_requested(index: int)`, `shop_requested(shop_id: String)`, `inn_requested(inn_id: String)`, `chest_opened(chest_id: String)`, `well_requested(id: String, kind: String)`, `lever_pulled`, `key_taken`, `door_used`, `portal_used`
  - the constants `TALK`, `NPC`, `SHOP`, `INN`, `CHEST`, `WELL`, `LEVER`, `KEY`, `DOOR`, `PORTAL`, `BOARD`, `ITEM`, `PROMPTS` and `NPC_KINDS`
  - `func setup(zone: ZoneData, player: Player, camera: FollowCamera, hud: MapHud, figures: MapFigures, props: MapProps, dungeon: DungeonMap) -> void`
  - `func set_flags(flags: Dictionary) -> void`
  - `func step(pos: Vector3) -> void`, `func check_exits(pos: Vector3) -> Dictionary`
  - `func use_nearest() -> void`, `func aim_at(screen: Vector2) -> void`, `func drop_errand() -> void`
  - `func hide_prompt() -> void`, `func prompt_showing() -> bool`
  - `func forget_near() -> void`, `func disarm_exits() -> void`, `func forget_covered_signs() -> void`

- [ ] **Step 1: Create `scripts/world/map_uses.gd` with this skeleton**

```gdscript
class_name MapUses extends Node
## What the hero can use on a map and how: the nearest thing in reach (a figure, a closed
## chest, a well, the return portal, and on a dungeon floor the lever, the key and the
## gates), the prompt that names it (MapHud shows it; the figure signs under it hide), a
## click or tap on one (walk there and use it on arrival), autoplay's talks (each villager
## once per visit) and the exits walked into. Each use is a signal, which World re-emits
## under the same name. Owned by World, which calls step() and check_exits() in its physics
## tick; never stores World.

signal talk_requested
signal npc_requested(index: int)
signal shop_requested(shop_id: String)
signal inn_requested(inn_id: String)
signal chest_opened(chest_id: String)
signal well_requested(id: String, kind: String)
signal lever_pulled
signal key_taken
signal door_used
signal portal_used

## How close the player must be to talk to a figure / to open a chest / to drink / to take
## an exit.
const TALK_RADIUS := 2.5
const CHEST_RADIUS := 1.8
const WELL_RADIUS := 2.2
const EXIT_RADIUS := 1.2
## After arriving (or after a closed exit's notice) exits wait until the player is this
## much farther than EXIT_RADIUS from all of them.
const EXIT_REARM := 0.8
## How close the player must be to a lever, a key or a gate (its centre) to use it.
const MECHANISM_RADIUS := 2.2
## A click or tap this close to a figure or a chest means "go there and use it".
const NPC_TAP_RADIUS := 1.2
## A tap on a figure is measured at this height, so its feet and its head both count.
const TAP_HEIGHT := 0.9
## Height of a figure's head and hat, the other height a tap on one is measured at.
const FIGURE_TOP_TAP_HEIGHT := 2.2
## Narrow: the head is slim, and a wider circle up there takes taps on the ground behind it.
const FIGURE_TOP_TAP_RADIUS := 0.7
## Kinds of the things the player can use on the map, and their prompts.
const TALK := "talk"
const NPC := "npc"
const SHOP := "shop"
const INN := "inn"
const CHEST := "chest"
const WELL := "well"
const LEVER := "lever"
const KEY := "key"
const DOOR := "door"
const PORTAL := "portal"
const BOARD := "board"
const ITEM := "item"
## Between the verb and who it is done with: "Hablar · Granjero".
const PROMPT_JOIN := " · "
const PROMPTS := {
	TALK: "Hablar",
	NPC: "Hablar",
	SHOP: "Comprar",
	INN: "Descansar",
	CHEST: "Abrir",
	WELL: "Beber",
	LEVER: "Tirar",
	KEY: "Coger",
	DOOR: "Abrir",
	PORTAL: "Volver",
	BOARD: "Leer",
	ITEM: "Coger",
}
## ZoneData.npcs kinds -> use kinds.
const NPC_KINDS := {"quest": TALK, "npc": NPC, "shop": SHOP, "inn": INN, "board": BOARD, "item": ITEM}

var _zone: ZoneData
var _player: Player
var _camera: FollowCamera
var _hud: MapHud
var _figures: MapFigures
var _props: MapProps
## The cells of a dungeon floor (null on an open map): its lever, key and gates.
var _dungeon: DungeonMap
var _autoplay := false
## The world flags (World.set_world_flags(); the same Dictionary).
var _flags := {}
## ZoneData.all_exits(): the arches and, on a dungeon floor, the stairs.
var _exits: Array = []
var _exits_armed := false
## What was in reach last frame ({} for nothing), so autoplay acts once per approach.
var _was_near := {}
## Set by a click or tap on a figure or chest: use it as soon as it is in reach.
var _use_on_arrival := {}
## Autoplay only: npc indexes already talked to on this map.
var _autoplay_talked := {}
## The figure signs the prompt is covering right now (hidden until it goes).
var _signs_under_prompt: Array[Label3D] = []


func setup(zone: ZoneData, player: Player, camera: FollowCamera, hud: MapHud,
		figures: MapFigures, props: MapProps, dungeon: DungeonMap) -> void:
	_zone = zone
	_player = player
	_camera = camera
	_hud = hud
	_figures = figures
	_props = props
	_dungeon = dungeon
	_autoplay = RunFlags.autoplay()
	_exits = zone.all_exits()


func set_flags(flags: Dictionary) -> void:
	_flags = flags


## Every physics tick (World), last: the prompt for what is in reach, the use a tap asked
## for once it is in reach, and autoplay's uses.
func step(pos: Vector3) -> void:
	var near := _nearest_use(pos)
	if near.is_empty():
		hide_prompt()
	else:
		_show_prompt(near)
	if not _use_on_arrival.is_empty() and _in_reach(_use_on_arrival):
		var errand := _use_on_arrival
		_use_on_arrival = {}
		_player.move_target = null
		_use(errand)
	elif not near.is_empty() and near != _was_near and _autoplay and near.kind != PORTAL:
		# Autoplay talks to each villager once per visit to the zone, and again when a
		# mark over it says there is something new.
		var chats: bool = near.kind in [NPC, BOARD, ITEM]
		if not chats or not _autoplay_talked.has(near.index) \
				or _figures.has_mark(_zone.npcs[near.index].name):
			_autoplay_talked[near.index] = true
			_use(near)
	_was_near = near


## Enter, Space or the phone's use button: uses what is nearest now.
func use_nearest() -> void:
	_use(_nearest_use(_player.global_position))


## A click or tap at a screen point: what is there is used once the hero reaches it.
func aim_at(screen: Vector2) -> void:
	_use_on_arrival = _tapped_use(screen)


## The tap's errand is dropped (the hero walks off by hand, a placing, a cutscene).
func drop_errand() -> void:
	_use_on_arrival = {}


## What was in reach is forgotten (a placing, the end of a cutscene): autoplay may act again.
func forget_near() -> void:
	_was_near = {}


## The exits wait until the hero steps away from them (a placing).
func disarm_exits() -> void:
	_exits_armed = false


## A cutscene hides every figure sign itself: none is waiting for the prompt to go.
func forget_covered_signs() -> void:
	_signs_under_prompt.clear()


static func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))
```

  `step()` is the tail of `World._physics_process()`, from `var near := _nearest_use(pos)` to `_was_near = near`. Only the accesses changed: `_quest_marks.has(...)` became `_figures.has_mark(...)` in Task 3, and `zone.` became `_zone.`. The other one-line functions are the lines named in Step 3.

- [ ] **Step 2: Move these members from `world.gd` into `map_uses.gd`**

  **Constants:** the ones in the skeleton (`TALK_RADIUS`, `CHEST_RADIUS`, `WELL_RADIUS`, `EXIT_RADIUS`, `EXIT_REARM`, `MECHANISM_RADIUS`, `NPC_TAP_RADIUS`, `TAP_HEIGHT`, `FIGURE_TOP_TAP_HEIGHT`, `FIGURE_TOP_TAP_RADIUS`, the twelve kinds, `PROMPT_JOIN`, `PROMPTS` and `NPC_KINDS`). Delete them from `World`, together with the "How close the player must be ..." comment block. `World` keeps `BOSS_RADIUS`, `BOSS_REARM_RADIUS` and `TAP_GUARD_MS`, with a comment of their own:

```gdscript
## How close the player must be to run into the boss.
const BOSS_RADIUS := 2.5
```

  **Variables:** `_exits`, `_exits_armed`, `_was_near`, `_use_on_arrival`, `_autoplay_talked` and `_signs_under_prompt`. Also delete the line `_exits = zone.all_exits()` from `World._ready()`.

  **Functions verbatim** (`zone.` → `_zone.`; `_player`, `_camera`, `_flags` and `_dungeon` are the piece's own):
  - `_prompt_text`
  - `_show_prompt` (as Task 1 left it: `_clear_signs_under(_hud.show_prompt(...))`)
  - `_clear_signs_under` (`_figures.signs`, as Task 3 left it)
  - `_restore_signs`
  - `_action_key_name`
  - `_nearest_use`
  - `_tapped_use`
  - `_in_reach`
  - `_uses` (with `_figures.hidden`, `_props.closed_chests()` and `_props.has_portal()` from Tasks 2 and 3)
  - `_use` (each `X.emit(...)` is now the piece's own signal; `_props.well_kind(use.id)` stays)

  **Functions renamed:**
  - `_hide_prompt` → `hide_prompt`. Its body stays: `_restore_signs()`, then `_hud.hide_prompt()`.
  - `_prompt_showing` → `prompt_showing`. Its body stays: `return _hud.prompt_showing()`.
  - `_check_exits(pos) -> bool` → `check_exits(pos: Vector3) -> Dictionary`:
    - each `return false` → `return {}`;
    - `show_notice(nearest.lock_text, "Cerrado")` → `_hud.show_notice(nearest.lock_text, "Cerrado")`, which is what `World.show_notice()` did;
    - its last six lines (`_waiting = true`, `_player.input_enabled = false`, `_hide_prompt()`, `_reset_pad()`, `exit_requested.emit(...)`, `return true`) become the single line `return nearest`. Those lines move to `World._take_exit()` (Step 3).

  The function then reads:

```gdscript
## The open exit the player walked into ({} for none; World then freezes the map and emits
## exit_requested), or a closed one's notice once per approach. Exits only count once the
## player has stepped away from all of them since arriving.
func check_exits(pos: Vector3) -> Dictionary:
	var nearest := {}
	var nearest_d := INF
	for exit: Dictionary in _exits:
		if not ZoneData.is_present(exit, _flags):
			continue
		var d := _flat_distance(pos, exit.pos)
		if d < nearest_d:
			nearest = exit
			nearest_d = d
	if nearest.is_empty():
		return {}
	if not _exits_armed:
		_exits_armed = nearest_d > EXIT_RADIUS + EXIT_REARM
		return {}
	if nearest_d > EXIT_RADIUS:
		return {}
	_exits_armed = false
	if not MapProps.is_open(nearest, _flags):
		_hud.show_notice(nearest.lock_text, "Cerrado")
		return {}
	return nearest
```

  **In `scripts/world/map_hud.gd`:** in `_build_ui`, `_prompt.text = World.PROMPTS[World.TALK]` → `_prompt.text = MapUses.PROMPTS[MapUses.TALK]`.

- [ ] **Step 3: Wire `MapUses` in `world.gd` and leave `World` as the map scene**

  Add `var _uses: MapUses`. Then add these functions to `World`:

```gdscript
## The hero walked into an open exit (MapUses.check_exits()): the map waits for Game.
func _take_exit(exit: Dictionary) -> void:
	_waiting = true
	_player.input_enabled = false
	_uses.hide_prompt()
	_reset_pad()
	exit_requested.emit(exit.to, exit.entry)


## The uses of MapUses go out under World's own signals: Game connects to those.
func _forward_use_signals() -> void:
	_uses.talk_requested.connect(talk_requested.emit)
	_uses.npc_requested.connect(npc_requested.emit)
	_uses.shop_requested.connect(shop_requested.emit)
	_uses.inn_requested.connect(inn_requested.emit)
	_uses.chest_opened.connect(chest_opened.emit)
	_uses.well_requested.connect(well_requested.emit)
	_uses.lever_pulled.connect(lever_pulled.emit)
	_uses.key_taken.connect(key_taken.emit)
	_uses.door_used.connect(door_used.emit)
	_uses.portal_used.connect(portal_used.emit)
```

  Each re-emit runs synchronously inside `MapUses._use()`, as the old `emit` did, so `Game`'s handlers run at the same moment as before.

  **Inside `World`, change these lines:**

  - `set_world_flags`: after `_props.set_flags(flags)`, add `_uses.set_flags(flags)`.
  - `_unhandled_input`:
    - `_prompt_showing()` → `_uses.prompt_showing()`;
    - `_use(_nearest_use(_player.global_position))` → `_uses.use_nearest()`;
    - `_use_on_arrival = _tapped_use((event as InputEventMouseButton).position)` → `_uses.aim_at((event as InputEventMouseButton).position)`.
  - `_on_tapped`: `_use_on_arrival = _tapped_use(screen)` → `_uses.aim_at(screen)`.
  - `place_player`:
    - `_was_near = {}` → `_uses.forget_near()`;
    - `_use_on_arrival = {}` → `_uses.drop_errand()`;
    - `_exits_armed = false` → `_uses.disarm_exits()`;
    - the order of the lines stays.
  - `freeze`: `_hide_prompt()` → `_uses.hide_prompt()`.
  - `_trigger`: `_hide_prompt()` → `_uses.hide_prompt()`.
  - `begin_cutscene`:
    - `_use_on_arrival = {}` → `_uses.drop_errand()`;
    - `_signs_under_prompt.clear()` → `_uses.forget_covered_signs()`.
  - `end_cutscene`: `_was_near = {}` → `_uses.forget_near()`.
  - Delete `World._check_exits` and every function moved in Step 2.

  **`_physics_process` becomes exactly this** (the fixed order of *Decisions*):

```gdscript
func _physics_process(delta: float) -> void:
	_sim_ms += delta * 1000.0
	var pad := _hud.pad
	if pad:
		_player.stick_direction = pad.direction
		if pad.direction != Vector2.ZERO:
			_uses.drop_errand()  # walking off by hand drops the tap's errand
	if _grass:
		Vegetation.set_pusher(_grass, _player.global_position)
	if _particles:
		ZoneParticles.follow(_particles, _player.global_position)
	_hud.step(_player.global_position, _player.last_step_m)
	_props.show_marker(_player.move_target)
	if _dungeon:
		_dungeon.see_through(_camera.global_position, _player.global_position)
	_monsters.move_groups(delta)
	if _waiting or _talking:
		return
	_monsters.tick_refill(delta)
	var pos := _player.global_position
	var inside := _is_in_village(pos)
	if inside != _in_village:
		_in_village = inside
		village_changed.emit(inside)
	_play_steps()
	var exit := _uses.check_exits(pos)
	if not exit.is_empty():
		_take_exit(exit)
		return
	if _boss_present:
		var boss_distance := _flat_distance(pos, zone.boss_pos)
		if not _boss_armed:
			_boss_armed = boss_distance > BOSS_REARM_RADIUS
		elif boss_distance <= BOSS_RADIUS:
			_trigger(true)
			return
	if _monsters.check_contact(pos, int(_sim_ms)):
		_trigger(false)
		return
	if _autoplay and _hunter.is_on() and not _monsters.is_repelled():
		_hunter.step(pos, int(_sim_ms))
	_uses.step(pos)
```

  If plan 1 wrapped the hunt line in `#region Autoplay` / `#endregion`, keep the region around it.

  **`_ready()` becomes exactly this.** Lines that plan 1 changed keep plan 1's form: keep the `_autoplay` line exactly as plan 1 left it, which is `RunFlags.autoplay()`.

```gdscript
func _ready() -> void:
	UiTheme.ensure(get_window())
	if zone == null:
		zone = ZoneData.by_id("pradera")
	_autoplay = RunFlags.autoplay()
	_grass = WorldStage.build(self, zone)
	if zone.is_dungeon():
		_dungeon = DungeonMap.new()
		_dungeon.zone = zone
		add_child(_dungeon)
	# Every piece exists from here on (set_world_flags() below reaches them all); each is
	# added to the tree where its nodes used to be built, so the node order is unchanged.
	_hud = MapHud.new()
	_hud.setup(zone)
	_player = PLAYER_SCENE.instantiate()
	_camera = FollowCamera.new()
	_figures = MapFigures.new()
	_figures.setup(zone, _player)
	_monsters = MapMonsters.new()
	_monsters.setup(zone, _player)
	_hunter = AutoplayHunter.new()
	_hunter.setup(zone, _player, _monsters)
	_monsters.groups_reset.connect(_hunter.forget)
	_props = MapProps.new()
	_props.setup(zone)
	_uses = MapUses.new()
	_uses.setup(zone, _player, _camera, _hud, _figures, _props, _dungeon)
	_forward_use_signals()
	add_child(_figures)
	_figures.build()
	if boss_id == "":
		boss_id = zone.boss_id
	if boss_id != "":
		_boss = _figures.add_figure(EnemyLibrary.look(boss_id), zone.boss_pos, 180.0, 1.0, 2.0)
	add_child(_props)
	_props.build()
	set_boss_present(false)
	set_world_flags({})
	_player.route = zone.autoplay_route
	add_child(_player)
	if zone.underground:
		var lantern := OmniLight3D.new()
		lantern.light_color = LANTERN_COLOR
		lantern.light_energy = LANTERN_ENERGY
		lantern.omni_range = LANTERN_RANGE
		lantern.position.y = LANTERN_HEIGHT
		_player.add_child(lantern)
	_particles = ZoneParticles.build(zone.particles)
	if _particles:
		add_child(_particles)
	add_child(_camera)
	_camera.target = _player
	_props.build_marker()
	_hud.map_pressed.connect(_on_map_pressed)
	_hud.tapped.connect(_on_tapped)
	_hud.pinched.connect(_camera.zoom_by)
	_hud.use_pressed.connect(_uses.use_nearest)
	add_child(_hud)
	add_child(_uses)
	set_explored(ExploredMap.new(zone))
	add_child(_monsters)
	place_at_entry(zone.start_entry)
	respawn_groups()
	_camera.current = true
	if get_parent() == get_tree().root:
		_connect_standalone()
```

  The only change from what Tasks 1 to 5 built is the creation of `_camera`: it moves up with the other `.new()` calls, because `MapUses` needs it. Its `add_child` stays where the old `_camera = FollowCamera.new()` was. Compare with the old `_ready()`: every `add_child` happens in the same relative order. `_uses` is a plain `Node`, added right after the HUD, and it has no children.

  **Update the header comment** at the top of `world.gd`. Keep the existing lines, and add this paragraph after them:

```gdscript
## Its jobs are split into pieces it owns and calls in a fixed order from _physics_process:
## MapHud (the 2D layer), MapProps (exits, portal, wells, chests, the walk marker),
## MapFigures (figures, signs, quest marks), MapMonsters (the groups), AutoplayHunter (the
## autoplay's hunt) and MapUses (what is in reach, taps, exits). Its public methods are
## façades of them and its signals are unchanged.
```

- [ ] **Step 4: Import and validate**

```bash
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --import 2>&1 | grep -E "ERROR|Parse Error|SCRIPT ERROR"
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --check-only --script res://scripts/world/map_uses.gd
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --check-only --script res://scripts/world/map_hud.gd
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --check-only --script res://scripts/world/world.gd
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --check-only --script res://scripts/game/game.gd
wc -l scripts/world/world.gd scripts/world/map_hud.gd scripts/world/map_props.gd scripts/world/map_figures.gd scripts/world/map_monsters.gd scripts/world/autoplay_hunter.gd scripts/world/map_uses.gd
grep -n "^func \|^static func " scripts/world/world.gd | wc -l
```

  Expected:
  - The `grep` prints nothing.
  - Each `--check-only` prints only the engine banner line.
  - `world.gd` is about 700 lines. The target is a guide: a piece too many is better than a piece half done.
  - `grep -nE 'World\.PROMPTS|\b_(was_near|use_on_arrival|exits|exits_armed|signs_under_prompt|autoplay_talked)\b' scripts/world/*.gd` lists only lines in `map_uses.gd`.
  - `World`'s public API is unchanged. Check with:

```bash
git diff develop -- scripts/world/world.gd | grep -E '^[-+](signal |func [a-z]|static func [a-z]|static var [a-z]|var [a-z])'
```

    Every `-` line of a public `func` or `signal` must have a matching `+` line with the same signature. `debug_no_groups` changes its form but keeps its name and type.

- [ ] **Step 5: The v1 and jungla runs, plus the map scene run alone**

  Run the same seven commands as Task 2 Step 5, then:

```bash
grep -cE '^¡Tiras de la palanca|^¡Encuentras la Llave de la mina|^Abres la reja' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/v1.log
grep -cE '^¡Tiras de la palanca|^¡Encuentras la Llave de la mina|^Abres la reja' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/v1.log
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --fixed-fps 10 --quit-after 3000 res://scenes/world/world.tscn -- --autoplay > C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/world-alone.log 2>&1
grep -E '^(Grupos|Encuentro en|Tienda|Posada|Cofre|Pozo|Salida)' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/world-alone.log | head
grep -E 'ERROR|WARNING' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/world-alone.log
```

  Expected:
  - The v1 and jungla milestones are as in Task 2 Step 5, with only the Jolt warning.
  - The lever, key and gate count is 3 in both logs (one of each on the mine floors).
  - The map run alone prints `Grupos: 16` and then `Encuentro en ...` lines (and `Tienda:`, `Posada:` or `Cofre:` as the route passes them), with no errors. This shows the re-emitted signals reach their listeners.

- [ ] **Step 6: Frames and the phone, by eye**

```bash
mkdir -p C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/uses-frames
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --path . --write-movie C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/uses-frames/f.png --fixed-fps 10 --quit-after 600 -- --autoplay
```

  Expected:
  - the prompt "Hablar · Abuela Rosa" with its keycap near her;
  - a figure sign under the prompt hides while the prompt shows;
  - the same as `ref/movie/` otherwise.

  Then the phone by hand:

```bash
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --path . --resolution 740x360 -- --touch
```

  Check on a new game:
  - a tap on the merchant walks there and opens the shop on arrival;
  - the use button reads "Comprar · Mercader" and opens it;
  - a tap on a chest walks there and opens it;
  - walking into the north exit's fog shows "Cerrado" with its text.

  Then on desktop, `./tools/godot.cmd --path .` with the same `APPDATA`. Check that Enter next to a figure talks, and a click on a figure walks there and talks.

  Delete the frames afterwards:

```bash
rm -r C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/uses-frames
```

- [ ] **Step 7: Update `CLAUDE.md` *Layout***

  - In the World bullet, replace each text on the left with the text on the right:
    - `` (the verb and, for a figure, its name, `_prompt_text()`: `` → `` (the verb and, for a figure, its name, `MapUses._prompt_text()`: ``
    - `` "Hablar" / "Comprar" / "Abrir"..., `_use_button`, that does what Enter does) `` → `` "Hablar" / "Comprar" / "Abrir"..., `MapHud._use_button`, that does what Enter does) ``
    - `` with the accept key's name (`_action_key_name()`: `` → `` with the accept key's name (`MapUses._action_key_name()`: ``
  - At the start of the World bullet, right after `` `scenes/world/world.tscn` + `scripts/world/world.gd` (`World`) — ``, insert this sentence: `the map scene: it builds the zone, the dungeon, the player, the camera, the lantern and the particles, keeps the freeze state, the boss, the steps, the village check and the clock `_sim_ms`, and calls its pieces in a fixed order from `_physics_process` (`MapHud`, `MapProps`, `MapFigures`, `MapMonsters`, `AutoplayHunter`, `MapUses`, below; refactor M-71); every public method of the pieces' jobs stays here as a façade and its signals are unchanged. `
  - Add this bullet after the `AutoplayHunter` one:

```markdown
- `scripts/world/map_uses.gd` (`MapUses`, `Node`) — what the hero can use on a map, owned by `World` (refactor M-71): `setup(zone, player, camera, hud, figures, props, dungeon)`, `set_flags()`, `step(pos)` (last in `World`'s tick: the prompt for the nearest use, a tap's errand once in reach, autoplay's talks once per approach), `check_exits(pos)` (the open exit walked into, `{}` for none; a closed one's notice), `use_nearest()` (Enter, the use button), `aim_at(screen)` (a click or tap), `drop_errand()`, `forget_near()`, `disarm_exits()`, `forget_covered_signs()`, `hide_prompt()` / `prompt_showing()`. `PROMPTS`, `NPC_KINDS` and the radii live here. Its signals (`talk_requested`, `npc_requested`, `shop_requested`, `inn_requested`, `chest_opened`, `well_requested`, `lever_pulled`, `key_taken`, `door_used`, `portal_used`) are re-emitted by `World` under the same names (`_forward_use_signals()`).
```

- [ ] **Step 8: Commit**

```bash
git add scripts/world/map_uses.gd scripts/world/map_uses.gd.uid scripts/world/map_hud.gd scripts/world/world.gd CLAUDE.md
git commit -m "Move prompts, uses, taps and exits from World into MapUses"
git status --short
```

  Expected: one commit, and the working tree is clean.

---

### Task 7: Last checks, the master document and the merge

**Files:**
- Modify: `docs/boost/documento-maestro.md`

**Interfaces:**
- Consumes: Tasks 1-6.
- Produces: `develop` with M-71 done. Plan 4 relies on every `World` method and signal that `Game` calls today.

- [ ] **Step 1: The runs that cross every piece**

```bash
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --fixed-fps 10 --quit-after 40000 -- --autoplay --autoplay-zone=eco > C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/eco.log 2>&1
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --fixed-fps 10 --quit-after 6000 -- --autoplay --autoplay-save > C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/save.log 2>&1
grep -E '^Eco de la Niebla' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/eco.log | head -3
grep -E '^Eco de la Niebla' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/eco.log | head -3
grep -E '^(Guardado|Cargado): ' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/save.log | sed -E 's/^(Guardado|Cargado): //' | uniq | wc -l
grep -E 'ERROR|WARNING' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/eco.log C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/p3/save.log
```

  Expected:
  - **Eco:** `Eco de la Niebla: victoria/derrota (n de m ganados)` lines, as in the reference. The boss waits `BOSS_REARM_RADIUS` between fights, so none starts over at once.
  - **Save round trip:** the `uniq | wc -l` prints `1`, which means `Guardado:` and `Cargado:` are identical.
  - **Errors:** only the Jolt warning.

  Then delete the scratch save. It is a literal path, never `$APPDATA`:

```bash
rm -f "C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/Godot/app_userdata/rpg-turnos/save_autoplay.json"
```

- [ ] **Step 2: Update `docs/boost/documento-maestro.md`**

  - **If the master table already has an M-71 row** (plans 1 and 2 split the refactor row per M-id), change its *Estado* from `spec` to `hecho`.
  - **If the table still has the single row** `| Sin versión · M-70 a M-74 | Refactor de arquitectura ... | spec |`, replace it with these five rows. Keep the spec and guide links on the first one, and set M-72 to M-74 to the state plans 1 and 2 reached (`hecho` once merged):

```markdown
| Sin versión · M-70 | Refactor: trocear `Game` ([spec](specs/2026-11-14-refactor-arquitectura-design.md) · [guía](specs/2026-11-14-refactor-arquitectura-guia.md)) | spec |
| Sin versión · M-71 | Refactor: trocear `World` en `MapHud`, `MapProps`, `MapFigures`, `MapMonsters`, `AutoplayHunter` y `MapUses` ([plan](plans/2026-11-14-refactor-3-world.md)) | hecho |
| Sin versión · M-72 | Refactor: trocear `BattleActor` ([plan](plans/2026-11-14-refactor-2-battle-actor.md)) | hecho |
| Sin versión · M-73 | Refactor: los constructores con su etiqueta `## Constructor:` ([plan](plans/2026-11-14-refactor-1-runflags-builders.md)) | hecho |
| Sin versión · M-74 | Refactor: `RunFlags` y el piloto automático en un solo sitio ([plan](plans/2026-11-14-refactor-1-runflags-builders.md)) | hecho |
```

  Then check:

```bash
grep -n "M-71" docs/boost/documento-maestro.md
```

  Expected: one row, ending in `| hecho |`.

- [ ] **Step 3: Commit and merge into `develop`**

```bash
git add docs/boost/documento-maestro.md
git commit -m "Mark M-71 (World split) as done in the master document"
git checkout develop
git merge --no-ff feature/refactor-3-world -m "Merge feature/refactor-3-world into develop"
git log --oneline -9
git status --short
```

  Expected:
  - The log shows the merge commit on top of the seven commits of this plan (six pieces and the master document).
  - The working tree is clean.
  - Nothing is pushed.
