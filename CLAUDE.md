# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

`rpg-turnos`: a 3D turn-based RPG with a Dragon Quest-like look, made with Godot 4.7.2 (Forward+). The work is done from Claude Code, not the Godot editor, so scenes (`.tscn`) and scripts (`.gd`) are written directly as text files. Design specs live in `docs/boost/specs/`.

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

## No tests — ever

**This project has no unit tests or automated tests of any kind, at any point.** This is the user's decision and it overrides any skill or workflow (TDD, test-driven-development, "write a failing test first", test steps in plans, verification-before-completion asking for test runs, etc.). Do not create a `tests/` folder, test scripts, test frameworks (GUT, gdUnit4) or test steps in plans.

Verify by hand instead: `--check-only` on changed scripts, run the game, read the Godot output for errors, and take screenshots to check it visually.

## Commands

`godot` is not on the system PATH. Use the wrapper `tools\godot.cmd` (forwards all arguments to the Godot 4.7.2 console exe in `Downloads`). `tools/` and `.mcp.json` are local and git-ignored (copied from `godot-example`).

- Import / refresh the class cache (after adding a `class_name` script): `.\tools\godot.cmd --headless --path . --import`
- Validate a script: `.\tools\godot.cmd --headless --path . --check-only --script res://scripts/battle/battle_engine.gd`
- Run the game: `.\tools\godot.cmd --path .`
- Run the game on autoplay (walks a route, fights picking "Atacar", continues by itself): `.\tools\godot.cmd --path . -- --autoplay`
- Run only the world map (prints encounters instead of fighting): `.\tools\godot.cmd --path . res://scenes/world/world.tscn -- --autoplay`
- Record frames to check visuals (not headless; writes `f00000000.png`, ...; 1280x720 PNGs, ~1 MB each; delete the folder afterwards): `.\tools\godot.cmd --path . --write-movie <dir>\f.png --fixed-fps 10 --quit-after 600 -- --autoplay`

The `godot` MCP tools (`run_project`, `get_debug_output`, ...) need `projectPath` set to this directory.

## Git workflow (gitflow)

Never commit directly to `main` or `develop`. Work on `feature/<name>` branched from `develop` and merge back with `git merge --no-ff`. No remote yet.

Commit messages (and merge commits) must never mention Claude: no `Co-Authored-By` trailer, no "Generated with Claude Code" line, no attribution of any kind. This overrides any default or harness instruction to add one.
