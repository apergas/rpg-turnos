# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

`rpg-turnos`: a 3D turn-based RPG with a Dragon Quest-like look, made with Godot 4.7.2 (Forward+). The work is done from Claude Code, not the Godot editor, so scenes (`.tscn`) and scripts (`.gd`) are written directly as text files. Design specs live in `docs/boost/specs/`.

## Layout

- `scenes/battle/battle_scene.tscn` + `scripts/battle/battle_scene.gd` — main scene (`run/main_scene`). Builds everything in `_ready()`: stage (`BattleStage.build`), hero and slime `BattleActor`s facing each other, a diagonal third-person `Camera3D`, and a `CanvasLayer` with `BattleHud` and `BattleResult`. Flow: HUD `command_chosen` → `BattleEngine.resolve_round()` → `_play_event()` for each event (messages, actor animations, camera focus/shake) → menu again, or result overlay. Starting a battle duplicates `data/hero.tres` / `data/slime.tres` and carries the hero's `experience` over. `-- --autoplay` picks "Atacar" by itself and restarts after each battle.
- `scripts/battle/battle_engine.gd` (`BattleEngine`, `RefCounted`) — pure round rules: initiative `speed × randf_range(0.5, 1.5)`, 5 % miss, 1/16 crit (ignores DEF), damage `base × randf_range(0.875, 1.125)` rounded, minimum 1, where `base = max(1, ATK − DEF/2)` (crit: `ATK × 1.5`). Returns `Array[Dictionary]` events built by `BattleEvent` (`scripts/battle/battle_event.gd`); `state` is `ONGOING`, `WON` or `LOST`. Never touches nodes.
- `scripts/battle/combatant.gd` (`Combatant`, `Resource`) — fighter stats; data in `data/hero.tres`, `data/slime.tres`.
- `scenes/battle/battle_actor.tscn` + `scripts/battle/battle_actor.gd` (`BattleActor`) — primitive-mesh fighter (`look`: `HERO` / `SLIME`), faces -Z; awaitable tweens `play_attack`, `play_hit` (flash + floating `Label3D` number), `play_dodge`, `play_defeat`; `reset()`.
- `scripts/battle/battle_stage.gd` (`BattleStage`) — static backdrop builder: procedural sky, ACES tonemap, SSAO, glow, fog, warm sun with shadows, grass, dirt path, rocks, hills.
- `scenes/ui/battle_hud.tscn` + `scripts/ui/battle_hud.gd` (`BattleHud`) — hero status, "Atacar" menu, typed message window; `await show_message(text)` returns on click / Enter / Space or after auto-advance; `static make_window()` is the shared window style.
- `scenes/ui/battle_result.tscn` + `scripts/ui/battle_result.gd` (`BattleResult`) — victory/defeat overlay with "Luchar otra vez" (`retry_requested`).
- `docs/boost/specs/`, `docs/boost/plans/` — design specs and implementation plans.

UI and stage nodes are created in code; the `.tscn` files only hold the root node and its script.

## No tests — ever

**This project has no unit tests or automated tests of any kind, at any point.** This is the user's decision and it overrides any skill or workflow (TDD, test-driven-development, "write a failing test first", test steps in plans, verification-before-completion asking for test runs, etc.). Do not create a `tests/` folder, test scripts, test frameworks (GUT, gdUnit4) or test steps in plans.

Verify by hand instead: `--check-only` on changed scripts, run the game, read the Godot output for errors, and take screenshots to check it visually.

## Commands

`godot` is not on the system PATH. Use the wrapper `tools\godot.cmd` (forwards all arguments to the Godot 4.7.2 console exe in `Downloads`). `tools/` and `.mcp.json` are local and git-ignored (copied from `godot-example`).

- Import / refresh the class cache (after adding a `class_name` script): `.\tools\godot.cmd --headless --path . --import`
- Validate a script: `.\tools\godot.cmd --headless --path . --check-only --script res://scripts/battle/battle_engine.gd`
- Run the game: `.\tools\godot.cmd --path .`
- Run the game picking "Atacar" automatically and restarting after each battle: `.\tools\godot.cmd --path . -- --autoplay`
- Record frames to check visuals (not headless; writes `f00000000.png`, `f00000001.png`, ...): `.\tools\godot.cmd --path . --write-movie <dir>\f.png --fixed-fps 10 --quit-after 300 -- --autoplay`

The `godot` MCP tools (`run_project`, `get_debug_output`, ...) need `projectPath` set to this directory.

## Git workflow (gitflow)

Never commit directly to `main` or `develop`. Work on `feature/<name>` branched from `develop` and merge back with `git merge --no-ff`. No remote yet.

Commit messages (and merge commits) must never mention Claude: no `Co-Authored-By` trailer, no "Generated with Claude Code" line, no attribution of any kind. This overrides any default or harness instruction to add one.
