# Structuring Godot Code: reference

## Contents

- A piece, step by step
- A rule class
- GDScript style (Godot's official guide, as used here)
- What stays as it is

## A piece, step by step

A piece is a `Node` (or `Node3D` / `CanvasLayer`) that takes **one** job off a big owner. The job could be the fishing flow, the map HUD or the monster groups.

1. **Write the file** `scripts/<area>/<piece>.gd`, with `class_name` and its base class.
2. **Give it `setup()`** with exactly what it needs. It never receives the owner itself.
3. **Give it signals** for everything the owner must react to.
4. **The owner creates it in `_ready()`,** at the point where it used to build that job. Node order matters for drawing, input and processing.
5. **The owner connects the piece's signals.** If other code already uses the owner's public API, the owner keeps a one-line façade for each call.
6. **Run `--import`,** then `--check-only` on the piece and on the owner.
7. **Run the autoplay that crosses the change** and compare the milestone lines: `Zona:`, `Escena:`, `Juego completado`.
8. **Update `CLAUDE.md` in the same commit:** a new *Layout* entry for the piece, and one line in the owner's entry.

```gdscript
class_name FishingFlow extends Node
## Plays the fishing at a well: asks Fishing (the rule), shows the bar, reports back.
## Owned by Game; never stores Game or World.

signal caught(text: String)   # Game shows the notice and autosaves

var _state: GameState
var _world_of: Callable       # returns the current World (it changes with each zone)
var _audio: AudioDirector


func setup(state: GameState, world_of: Callable, audio: AudioDirector) -> void:
	_state = state
	_world_of = world_of
	_audio = audio


func fish(well_id: String) -> void:
	var why := Fishing.problem(_state, well_id)
	var world: World = _world_of.call()
	if why != "":
		world.show_notice(why)
		return
	await world.freeze(true)
	var hit := await FishingWindow.run_on(self)
	var result := Fishing.resolve(_state, well_id, hit)
	await world.freeze(false)
	caught.emit(result.text)
```

In `Game`:

```gdscript
_fishing = FishingFlow.new()
_fishing.setup(state, func() -> World: return _world, _audio)
add_child(_fishing)
_fishing.caught.connect(_on_caught)
```

The full map of planned pieces is in `docs/boost/specs/2026-11-14-refactor-arquitectura-design.md`, and the safe order for moving existing code is in `docs/boost/specs/2026-11-14-refactor-arquitectura-guia.md`.

## A rule class

```gdscript
class_name Fishing extends RefCounted
## Fishing rules: what a well gives and when it is empty. Pure: works on a GameState,
## never touches nodes.

const MAX_PER_WELL := 5
const EMPTY := "Ya no pican."


static func problem(state: GameState, well_id: String) -> String:
	return EMPTY if state.fish_charge.get(well_id, 0) >= MAX_PER_WELL else ""
```

The texts, numbers and thresholds live here. A random roll takes an `rng` argument, so the scene does not decide it.

## GDScript style (Godot's official guide, as used here)

- **Naming:**
  - files and functions `snake_case`;
  - `class_name` `PascalCase`;
  - constants and enum values `CONSTANT_CASE`;
  - private members start with `_`;
  - signals in the past tense or as `*_requested` (`caught`, `shop_requested`).
- **Typing:** type every function (`-> void` included), and type variables or use `:=`.
- **Member order:**
  1. `class_name` / `extends`;
  2. the `##` doc comment;
  3. signals;
  4. enums;
  5. constants;
  6. `@export` / `static var`;
  7. public vars, then private vars;
  8. `_init` / `_ready` / `_process`...;
  9. public methods;
  10. private methods.
- **Doc comments:** `##` over the class and over every non-obvious constant or method, in English.
- **Player-facing text:** Spanish. Everything else (code, comments, `CLAUDE.md`) is in English.
- **Node references:** created in code and kept in a typed var. No `$Path`, no `get_parent()` to reach the owner.

## What stays as it is

- **`.tscn` with only the root.** This is a deliberate decision: there is no editor workflow here.
- **The existing class and file names.** Moving files is out of scope; new pieces get new files.
- **No tests.** The user's rule overrides any workflow.
