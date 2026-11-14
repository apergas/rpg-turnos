# Refactor 4 (M-70): split `Game` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn `scripts/game/game.gd` (1,840 lines) into a session coordinator under 600 lines, with `SessionContext` and ten pieces (`ZoneTravel`, `BattleFlow`, `BattleRewards`, `FigureTalk`, `CaravanFlow`, `StoryFlow`, `CreditsData`, `GameAutoplay`, `AutoplayStarts`, `GameDebug`), without changing anything in the game; then run the guide's final pass (step 6).

**Architecture:** Code is moved, not rewritten. `Game` keeps `setup()`, `_ready()`, `_exit_tree()`, `_process()`, the state, the fade, the saving, `_set_busy()`, `_refresh_status()`, the pause menu and the shop window, and wires its pieces. Each Node piece is a child of `Game` (never of the `World`) and gets a `SessionContext` in `setup()`. A piece never stores `Game`. When it needs another piece to do something and must wait for it, it calls a public `Callable` field that `Game` wires (the pattern `CutscenePlayer` already uses for `fade`, `set_flag` and `travel`). When it only reports, it emits a signal that `Game` connects. Only `GameAutoplay` and `GameDebug` get other pieces, and they use only their public functions.

**Tech Stack:** Godot 4.7.2, GDScript, Compatibility renderer. Work is done from the command line (`tools\godot.cmd`), never from the editor.

## Global Constraints

- Plans 1-3 are merged into `develop` before this plan starts.
  - `RunFlags` (`scripts/game/run_flags.gd`) exists with `autoplay()`, `autoplay_save()`, `autoplay_menu()`, `autoplay_easy()`, `autoplay_zone()`, `autoplay_companion()`, `debug()` and `touch()`.
  - `World`'s public API (signals, public methods, `World.debug_no_groups`, `World.BANNER_FADE`, `World.STEP_DISTANCE`) is unchanged.
- Behaviour must not change: no rules, texts, balance, save format (version 14) or autoplay output.
- **NO TESTS OF ANY KIND** (`CLAUDE.md`, *No tests — ever*). Each task is checked by hand:
  - `--import`;
  - `--check-only` on each changed script;
  - the autoplay runs of the *Checks* section, compared with the reference;
  - screenshots where something is visual.
- Every Godot run sets `APPDATA` inline to the literal scratch path `C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor`. Never use `$APPDATA` in `rm`, `mv` or `cp`.
- One task = one piece = one commit, and the game works after each.
  - Branch `feature/refactor-4-game` from `develop`, merged back with `git merge --no-ff`.
  - Commit messages in English, with no `Co-Authored-By` and no attribution of any kind.
  - Never push.
- `CLAUDE.md` *Layout* is updated in the same commit as the code.
- Conventions of the repo:
  - `.tscn` files stay as they are;
  - no autoloads;
  - UI colours and sizes only from `UiTokens` / `UiTheme`;
  - every new script has a `class_name` and a `##` header that starts with its kind (`Rule:`, `Node, a piece of Game:`).
- GDScript: `var x := some_callable.call(...)` does not compile (the type can't be inferred from a Variant). Keep a result with an explicit type: `var data: Dictionary = _ctx.autosave.call(false)`. `await some_callable.call(...)` works (`CutscenePlayer` does it).
- If plan 1 left `#region Autoplay` / `#endregion` markers around a function that moves, the markers do not go into the piece. An empty `#region` / `#endregion` pair left in `game.gd` is deleted.

### Rename table (moved code)

Code cut from `game.gd` into a Node piece gets these renames. Apply them with the **global perl**. Each task then lists its own **piece-local perl**.

| In `Game` | In the piece |
|---|---|
| `state` | `_ctx.state` |
| `_audio` | `_ctx.audio` |
| `_options` | `_ctx.options` |
| `_slot` | `_ctx.slot` |
| `_set_busy(x)` | `_ctx.set_busy.call(x)` |
| `await _fade_to(a)` | `await _ctx.fade.call(a)` |
| `_autosave(n)` | `_ctx.autosave.call(n)` (a kept result gets `var data: Dictionary = ...`) |
| `_refresh_status()` | `_ctx.refresh_status.call()` |
| `_play_map_music()` | `_ctx.play_map_music.call()` |
| `_autoplay` (if plan 1 kept the bool) | `RunFlags.autoplay()` |

After Tasks 1 and 5, `Game` itself already reads `_ctx.world`, `_ctx.zone`, `_ctx.busy` and `_ctx.play_time`, so moved code needs no rename for those.

**Global perl.** Run it on the scratch file that holds the cut functions (`C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/move.gd`), never on the piece's header:

```bash
perl -pi -e 's/(?<![.\w])state\b/_ctx.state/g; s/(?<![.\w])_audio\b/_ctx.audio/g; s/(?<![.\w])_options\b/_ctx.options/g; s/(?<![.\w])_slot\b/_ctx.slot/g; s/(?<![.\w])_set_busy\(/_ctx.set_busy.call(/g; s/(?<![.\w])_fade_to\(/_ctx.fade.call(/g; s/(?<![.\w])_autosave\(/_ctx.autosave.call(/g; s/(?<![.\w])_refresh_status\(\)/_ctx.refresh_status.call()/g; s/(?<![.\w])_play_map_music\(\)/_ctx.play_map_music.call()/g; s/(?<![.\w])_autoplay\b/RunFlags.autoplay()/g' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/move.gd
```

Then read `move.gd` once:

- If the perl changed a word in a comment (for example "the _ctx.state"), put the plain word back.
- Any `var x := _ctx.autosave.call(...)` becomes `var x: Dictionary = _ctx.autosave.call(...)`.

The recipe for moving a function: cut it from `game.gd`, paste it into `move.gd`, run the global perl, then the task's piece-local perl, and append `move.gd` to the piece after its skeleton.

### Checks

Task 0 writes `C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/check.sh`. Each task runs it as `bash C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/check.sh <run>`.

**What it does:**

- It runs the game headless with `--fixed-fps 10` and writes the log to `new/<run>.log`.
- It keeps the milestones, with every number turned into `N` and only the first time each line appears, because retreats repeat zones. These go to `new/<run>.m`.
- It prints the errors and warnings, without the known Jolt one.
- It diffs the `Zona`, `Escena`, `Lugar`, `Pregunta`, `Juego completado` and `Compañero` milestones against `ref/<run>.m`.
- It prints the last end lines of both logs.

**Expected every time:**

- nothing under `== errors and warnings`;
- nothing under `== milestone diff`;
- under `== end lines`, the same `Nv` in both. Times may differ by up to about 5 minutes.
- for `save`, `1` under `== save round trip`.

**If a diff shows only a last milestone missing**, it can be that the run hit `--quit-after` just before it. Run it once more. If two runs differ from the reference, stop: `git reset --hard HEAD` on this branch and rethink the piece (guide, *Cuándo parar*).

| Run | Arguments | Watch also |
|---|---|---|
| `v1` | `--quit-after 150000 -- --autoplay` | `Juego completado: Nv 18` |
| `v2` | `--quit-after 500000 -- --autoplay --autoplay-zone=caravana` (about 20 min) | `Juego completado (v2): Nv 40` |
| `caravana60` | `--quit-after 60000 -- --autoplay --autoplay-zone=caravana` | `Pregunta: ... -> Sí`, `-> Partir`, `Zona: caravana`, `Escena: caravana_campamento`, `Compañero: Brena`, `Zona: jungla` |
| `medallas` | `--quit-after 60000 -- --autoplay --autoplay-zone=medallas` | last line `Medallas: 12/12 · premios 5/5` |
| `eco` | `--quit-after 40000 -- --autoplay --autoplay-zone=eco` | at least one `Eco de la Niebla: victoria`; the line `Entre la bruma brilla algo.` once |
| `save` | `--quit-after 6000 -- --autoplay --autoplay-save` | `Guardado:` and `Cargado:` identical |
| `bosque`, `mina_1`, `mina_3`, `castillo_patio`, `castillo_trono`, `jungla` | `--quit-after 40000 -- --autoplay --autoplay-zone=<run>` | |
| `desierto`, `montana` | `--quit-after 60000 -- --autoplay --autoplay-zone=<run>` | |
| `portal` | `--quit-after 100000 -- --autoplay --autoplay-zone=portal` | `Escena: cruce`, `Juego completado (v2)` |
| `ciudad` | `--quit-after 150000 -- --autoplay --autoplay-zone=ciudad` | `Escena: guardian`, `Escena: cruce`, `Juego completado (v2)` |

Common commands, for reference (each task names its scripts):

- Import: `cd /c/Users/peixe/Documents/rpg-turnos && APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --import`. Expected: no line with `SCRIPT ERROR`, `Parse Error` or `ERROR`.
- Validate: `cd /c/Users/peixe/Documents/rpg-turnos && APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --check-only --script res://<path>.gd`. Expected: no `SCRIPT ERROR`, `Parse Error` or `ERROR`.

---

## File structure

| File | Kind | Job |
|---|---|---|
| `scripts/game/session_context.gd` | `RefCounted` (shared data, no rules) | What the pieces share: state, current map, audio, options, slot, play time, busy, five `Callable`s |
| `scripts/story/credits_data.gd` | Rule | The credits' sections and numbers, the clock text, the save summary line |
| `scripts/game/autoplay_starts.gd` | Rule (data) | `AUTOPLAY_ZONES` and the other starts, the autoplay thresholds, the chosen companion |
| `scripts/game/battle_rewards.gd` | Rule | The boss of a map, whether it shows, the bestiary notes and families, what a victory gives |
| `scripts/game/zone_travel.gd` | Node piece | Building the next map, exits, the Ala and its portal, the way back to the village, the groups |
| `scripts/story/story_flow.gd` | Node piece | Cutscenes, the prologue, the village and arrival scenes, the two endings |
| `scripts/game/caravan_flow.gd` | Node piece | The Jefe de caravana's questions and the choice of companion |
| `scripts/game/figure_talk.gd` | Node piece | Talking, shops, inns, the Coleccionista, wells, chests, the lever, the key, the gate |
| `scripts/game/battle_flow.gd` | Node piece | A battle on top of the map and what follows it |
| `scripts/game/game_autoplay.gd` | Node piece, only with `--autoplay` | The self-playing run |
| `scripts/game/game_debug.gd` | Node piece, only with `--debug` | The debug panel's actions |
| `scripts/game/game.gd` | Node (owner) | Coordinator |

### Order, and why

1. The pure classes go first (Tasks 2-4): `Game` only swaps calls.
2. Then `ZoneTravel` (Task 5), which everything else asks for maps.
3. Then `StoryFlow` (6), `CaravanFlow` (7) and `FigureTalk` (8-9).
4. Then `GameAutoplay` (10). From then on, `BattleFlow` (11) has only signals to emit and a `Callable` to await.
5. `GameDebug` (12) last, and the final pass (13).

Until a piece exists, the `Callable` fields of the pieces that are already in are wired to the `Game` method that still holds that code, and the task that moves it rewires them.

---

### Task 0: Branch, check script and extra references (no commit)

**Files:**
- Create (outside the repo): `C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/check.sh`

**Interfaces:**
- Consumes: plan 1's references in `C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/` (`v1.log`, `v2.log`, `medallas.log`, `eco.log`, `save.log`).
- Produces: `check.sh` and the `ref/<run>.m` files of every run in *Checks*.

- [ ] **Step 1: Branch**

```bash
cd /c/Users/peixe/Documents/rpg-turnos && git checkout develop && git status --short && git checkout -b feature/refactor-4-game
```

Expected: `git status --short` prints nothing, then `Switched to a new branch 'feature/refactor-4-game'`.

- [ ] **Step 2: Write `check.sh`**

```bash
#!/usr/bin/env bash
# Usage: check.sh <run> [ref|m]
#   (none) run the game into new/ and compare with ref/
#   ref    run the game into ref/ (a reference, from develop)
#   m      only rebuild ref/<run>.m from an existing ref/<run>.log
set -u
R="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor"
run="$1"
mode="${2:-new}"
out="$R/new"
if [ "$mode" = ref ] || [ "$mode" = m ]; then out="$R/ref"; fi
mkdir -p "$out"
case "$run" in
  v1) args="--quit-after 150000 -- --autoplay" ;;
  v2) args="--quit-after 500000 -- --autoplay --autoplay-zone=caravana" ;;
  caravana60) args="--quit-after 60000 -- --autoplay --autoplay-zone=caravana" ;;
  medallas) args="--quit-after 60000 -- --autoplay --autoplay-zone=medallas" ;;
  eco) args="--quit-after 40000 -- --autoplay --autoplay-zone=eco" ;;
  save) args="--quit-after 6000 -- --autoplay --autoplay-save" ;;
  bosque|mina_1|mina_3|castillo_patio|castillo_trono|jungla) args="--quit-after 40000 -- --autoplay --autoplay-zone=$run" ;;
  desierto|montana) args="--quit-after 60000 -- --autoplay --autoplay-zone=$run" ;;
  portal) args="--quit-after 100000 -- --autoplay --autoplay-zone=portal" ;;
  ciudad) args="--quit-after 150000 -- --autoplay --autoplay-zone=ciudad" ;;
  *) echo "unknown run: $run"; exit 2 ;;
esac
if [ "$mode" != m ]; then
  cd /c/Users/peixe/Documents/rpg-turnos || exit 2
  APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --fixed-fps 10 $args > "$out/$run.log" 2>&1
  rm -f "C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/Godot/app_userdata/rpg-turnos/save_autoplay.json"
fi
M='^(Zona|Escena|Lugar|Compañero|Pregunta|Misión cumplida|Juego completado|Medallas|Eco de la Niebla)'
grep -E "$M" "$out/$run.log" | sed -E 's/[0-9]+/N/g' | awk '!seen[$0]++' > "$out/$run.m"
echo "== errors and warnings"
grep -E 'ERROR|WARNING' "$out/$run.log" | grep -v 'Jolt Physics job system'
if [ "$mode" = new ]; then
  echo "== milestone diff"
  diff "$R/ref/$run.m" "$out/$run.m" | grep -E '^[<>] (Zona|Escena|Lugar|Pregunta|Juego completado|Compañero)'
  echo "== end lines"
  grep -hE '^(Juego completado|Medallas: [0-9]+/12 ·|Eco de la Niebla)' "$R/ref/$run.log" | tail -2
  grep -hE '^(Juego completado|Medallas: [0-9]+/12 ·|Eco de la Niebla)' "$out/$run.log" | tail -2
fi
if [ "$run" = save ]; then
  echo "== save round trip"
  grep -E '^(Guardado|Cargado): ' "$out/$run.log" | sed -E 's/^(Guardado|Cargado): //' | uniq | wc -l
fi
```

- [ ] **Step 3: Milestone files of plan 1's references**

```bash
ls C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/
for r in v1 v2 medallas eco save; do bash C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/check.sh $r m; done
```

Expected:

- `ls` lists at least `v1.log v2.log medallas.log eco.log save.log`.
- Each `check.sh` prints only `== errors and warnings` with nothing under it. For `save` it also prints `== save round trip` and `1`.
- If a log is missing, record it now with `check.sh <run> ref` (develop with plans 1-3 merged behaves as the original).

- [ ] **Step 4: Extra references (on this branch, still equal to develop)**

```bash
for r in caravana60 bosque mina_1 mina_3 castillo_patio castillo_trono jungla desierto montana portal ciudad; do bash C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/check.sh $r ref; done
```

Expected: for each run, `== errors and warnings` with nothing under it. About an hour of real time.

- [ ] **Step 5: Web size and menu frames of the reference**

```bash
cd /c/Users/peixe/Documents/rpg-turnos && mkdir -p build/web && APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --export-release "Web" build/web/index.html > C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/web.log 2>&1; ls -l build/web/index.pck | awk '{print $5}' > C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/pck.size; cat C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/pck.size
mkdir -p C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/menu4 && APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --path . --write-movie C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/menu4/f.png --fixed-fps 10 --quit-after 140 -- --autoplay --autoplay-menu
```

Expected:

- one number, the size of `index.pck` in bytes;
- 140 PNG frames in `ref/menu4/`.

---

### Task 1: `SessionContext`

**Files:**
- Create: `scripts/game/session_context.gd`
- Modify: `scripts/game/game.gd` (members `play_time`, `_busy`, `_world`, `_potion_count`; `_ready()`)
- Modify: `CLAUDE.md` (*Layout*, *Conventions*)

**Interfaces:**
- Produces, for every later task:

```gdscript
class_name SessionContext extends RefCounted
var state: GameState
var world: World
var zone: ZoneData            # read-only: world.zone (null before the first map)
var audio: AudioDirector
var options: GameOptions
var slot := 1
var play_time := 0.0
var busy := false
var fade: Callable            # await fade.call(alpha: float)
var autosave: Callable        # autosave.call(notice: bool) -> Dictionary
var set_busy: Callable        # set_busy.call(busy: bool)
var refresh_status: Callable  # refresh_status.call()
var play_map_music: Callable  # play_map_music.call()
func potion_count() -> int
```

- [ ] **Step 1: Create `scripts/game/session_context.gd`**

```gdscript
class_name SessionContext extends RefCounted
## What the pieces of one play session share. Game builds it in _ready() (_make_context())
## and keeps it up to date; each piece gets it in setup() and reads the current map from it
## every time (world changes on every change of zone: a piece never keeps a World of its
## own). Holds no rules.

var state: GameState
## The current map. Game sets it each time ZoneTravel builds one (Game._on_world_replaced()).
var world: World
## The current map's zone (World.zone; the Caravana's is dressed by CampLook).
var zone: ZoneData:
	get:
		return world.zone if world != null else null
var audio: AudioDirector
var options: GameOptions
## The save slot this game writes to (SaveStore; ignored on autoplay runs). Set once.
var slot := 1
## Seconds played, saved with the game; Game._process() counts it (it stops while paused).
var play_time := 0.0
## A battle, a dialogue, a fade, a menu or a scene is on. Written only by Game._set_busy().
var busy := false
## await fade.call(alpha): to black (1.0) or back (0.0).
var fade: Callable
## autosave.call(notice) -> Dictionary: writes the save (shows "Partida guardada." if
## notice); returns the saved data, empty if the file could not be written.
var autosave: Callable
## set_busy.call(busy): the pause menu and the debug panel only open when not busy.
var set_busy: Callable
## refresh_status.call(): the map's status window, quest marks and the hero's equipment.
var refresh_status: Callable
## play_map_music.call(): the zone's map or village music and its ambient.
var play_map_music: Callable


## The healing potions carried, big ones too: the map's counter and the retreat line.
func potion_count() -> int:
	return state.inventory.count(Inventory.POTION) + state.inventory.count(Inventory.BIG_POTION)
```

- [ ] **Step 2: Build it in `Game`**

In `scripts/game/game.gd`:

- Add `var _ctx: SessionContext` after `var state: GameState`.
- Delete `func _potion_count()` and its comment.
- Add this function right after `_exit_tree()`:

```gdscript
## The context the pieces share (SessionContext): built once, right after the GameState.
func _make_context() -> void:
	_ctx = SessionContext.new()
	_ctx.state = state
	_ctx.audio = _audio
	_ctx.options = _options
	_ctx.slot = _slot
	_ctx.fade = _fade_to
	_ctx.autosave = _autosave
	_ctx.set_busy = _set_busy
	_ctx.refresh_status = _refresh_status
	_ctx.play_map_music = _play_map_music
```

- In `_ready()`, right after the line `state = GameState.new(HERO_DATA)`, add `_make_context()`.

- [ ] **Step 3: Move `play_time`, `_busy` and `_world` into the context**

Delete these three members of `game.gd` and the comment lines above them:

- `var play_time := 0.0` (its comment `## Seconds played, saved with the game; stops while paused.`);
- `var _world: World`;
- `var _busy := false`.

Then run:

```bash
cd /c/Users/peixe/Documents/rpg-turnos && perl -pi -e 's/(?<![.\w])play_time\b/_ctx.play_time/g; s/(?<![.\w])_busy\b/_ctx.busy/g; s/(?<![.\w])_world\b/_ctx.world/g; s/(?<![.\w])_potion_count\(\)/_ctx.potion_count()/g' scripts/game/game.gd
grep -nP '(?<![.\w])(play_time|_busy|_world|_potion_count)\b' scripts/game/game.gd
```

Expected: the `grep` prints nothing.

- `info.play_time` and `_set_busy` are not touched.
- `_set_busy()` now reads `_ctx.busy = busy`.
- `_switch_zone()` now assigns `_ctx.world = WORLD_SCENE.instantiate()`.

- [ ] **Step 4: Import and validate**

Run the import, then validate `res://scripts/game/session_context.gd` and `res://scripts/game/game.gd` (*Checks*). Expected: no `SCRIPT ERROR` / `Parse Error` / `ERROR`.

- [ ] **Step 5: Runs**

```bash
bash C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/check.sh save
bash C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/check.sh v1
```

Expected:

- `save`: nothing under errors and the diff, and `1` under `== save round trip`.
- `v1`: nothing under errors and the diff; both end lines say `Juego completado: Nv 18`.

- [ ] **Step 6: `CLAUDE.md`**

Insert this entry right after the `scripts/game/game.gd` (`Game`) entry of *Layout*:

```markdown
- `scripts/game/session_context.gd` (`SessionContext`, `RefCounted`, M-70) — what the pieces of `Game` share, built by `Game._make_context()`: `state`, `world` (the current map; `Game` sets it each time a map is built), `zone` (read-only, `world.zone`), `audio`, `options`, `slot` (set once), `play_time` (seconds played, counted by `Game._process()`), `busy` (written only by `Game._set_busy()`), the Callables `fade` (`await fade.call(alpha)`), `autosave` (`autosave.call(notice) -> Dictionary`, empty if not written), `set_busy`, `refresh_status`, `play_map_music`, and `potion_count()`. A piece reads the map through it every time and never keeps a `World` of its own.
```

At the end of the `Game` entry, append: ` M-70: the play time, the busy flag and the current map live in its SessionContext (_ctx).`

- [ ] **Step 7: Commit**

```bash
cd /c/Users/peixe/Documents/rpg-turnos && git add scripts/game/session_context.gd scripts/game/game.gd CLAUDE.md && git commit -m "Add SessionContext and move play time, busy and the current map into it"
```

---

### Task 2: `CreditsData`

**Files:**
- Create: `scripts/story/credits_data.gd`
- Modify: `scripts/game/game.gd` (remove `AUTHOR`, `_credits_sections`, `_v2_credits_sections`, `_v2_numbers`, `_clock`, `_summary`)
- Modify: `CLAUDE.md`

**Interfaces:**
- Produces:

```gdscript
CreditsData.AUTHOR := "apergas"
static func credits_sections(state: GameState, time_text: String) -> Array
static func v2_numbers(state: GameState, play_time: float) -> Dictionary  # {time, battles, since}
static func v2_credits_sections(state: GameState, numbers: Dictionary) -> Array
static func clock(seconds: float) -> String
static func summary(data: Dictionary) -> String
```

- [ ] **Step 1: Create `scripts/story/credits_data.gd`**

The bodies are the five `Game` functions, unchanged. The only differences are the `state` / `play_time` parameters and `_clock(` → `clock(`.

```gdscript
class_name CreditsData extends RefCounted
## Rule: what the credits say, from a GameState: the v1's sections (credits_sections()), the
## v2's (v2_credits_sections(), with v2_numbers()), the "h:mm:ss" text of a time (clock())
## and the one-line JSON of a save for --autoplay-save (summary()). Never touches nodes.

## The author shown in the credits.
const AUTHOR := "apergas"


## The credits: who made the game, with what, and the numbers of this game.
static func credits_sections(state: GameState, time_text: String) -> Array:
	var numbers: Array[String] = [
		"Tiempo de juego: %s" % time_text,
		"Combates: %d" % state.battles,
		"Pasos: %d" % state.steps,
		"Oro ganado: %d G" % state.gold_earned,
		"Misiones cumplidas: %d" % state.quests_done(),
		"Nivel: %d" % state.hero.level,
	]
	return [
		["Villaclaro", ["La historia de %s" % state.hero.display_name]],
		["Creado por", [AUTHOR]],
		["Motor", ["Godot Engine 4.7"]],
		["Modelos 3D", ["KayKit, de Kay Lousberg (CC0)"]],
		["Música y sonido", ["Generados por el propio juego"]],
		["Tu partida", numbers],
		["Gracias por jugar", []],
	]


## The v2's time and battles: since the hero left with the caravan (story.v2_start), or the
## whole game's for a save that was already in the caravan before 2.3.0 ("since" false).
static func v2_numbers(state: GameState, play_time: float) -> Dictionary:
	var start: Array = state.story.v2_start
	var since := not start.is_empty()
	return {
		"time": clock(play_time - (float(start[0]) if since else 0.0)),
		"battles": state.battles - (int(start[1]) if since else 0),
		"since": since,
	}


## The v2's credits: the caravan's story, this journey's numbers, who made the game.
static func v2_credits_sections(state: GameState, numbers: Dictionary) -> Array:
	var journey: Array[String] = []
	if state.ally_id != "":
		journey.append("Compañero: %s" % Allies.display_name(state.ally_id))
	journey.append(("Tiempo en la caravana: %s" if numbers.since else "Tiempo de juego: %s")
		% numbers.time)
	journey.append(("Combates en la caravana: %d" if numbers.since else "Combates: %d")
		% numbers.battles)
	journey.append("Misiones de la caravana: %d/%d" % [state.quests.done_of(true),
		QuestLog.total_of(true)])
	journey.append("Nivel: %d" % state.hero.level)
	return [
		["La caravana del portal", ["La historia de %s" % state.hero.display_name]],
		["Tu viaje", journey],
		["Creado por", [AUTHOR]],
		["Motor", ["Godot Engine 4.7"]],
		["Modelos 3D", ["KayKit, de Kay Lousberg (CC0)", "Nature Kit, de Kenney (CC0)"]],
		["Música y sonido", ["Generados por el propio juego"]],
		["Gracias por jugar", []],
	]


## Seconds as "h:mm:ss".
static func clock(seconds: float) -> String:
	return "%d:%02d:%02d" % [floori(seconds / 3600.0), floori(seconds / 60.0) % 60,
		floori(seconds) % 60]


## One line with every saved value, keys sorted, for --autoplay-save.
static func summary(data: Dictionary) -> String:
	return JSON.stringify(data, "", true)
```

Before saving, compare each body with the one in `game.gd`. The texts must be byte for byte the same.

- [ ] **Step 2: Remove them from `Game` and point the callers to `CreditsData`**

Delete from `game.gd`:

- `const AUTHOR` and its comment;
- `_v2_numbers`, `_v2_credits_sections`, `_credits_sections`, `_clock` and `_summary`, with their comments.

Then:

```bash
cd /c/Users/peixe/Documents/rpg-turnos && perl -pi -e 's/(?<![.\w])_v2_credits_sections\(/CreditsData.v2_credits_sections(state, /g; s/(?<![.\w])_credits_sections\(/CreditsData.credits_sections(state, /g; s/(?<![.\w])_v2_numbers\(\)/CreditsData.v2_numbers(state, _ctx.play_time)/g; s/(?<![.\w])_clock\(/CreditsData.clock(/g; s/(?<![.\w])_summary\(/CreditsData.summary(/g' scripts/game/game.gd
grep -nP '(?<![.\w])(_clock|_summary|_credits_sections|_v2_credits_sections|_v2_numbers)\(|(?<![.\w])AUTHOR\b' scripts/game/game.gd
```

Expected: the `grep` prints nothing.

- [ ] **Step 3: Import and validate**

Validate `res://scripts/story/credits_data.gd` and `res://scripts/game/game.gd`. Expected: no errors.

- [ ] **Step 4: Runs**

```bash
bash C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/check.sh save
bash C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/check.sh v1
bash C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/check.sh v2
```

Expected:

- `save`: `1`.
- `v1`: no errors and an empty diff; `Juego completado: Nv 18` in both end lines.
- `v2`: no errors and an empty diff; `Juego completado (v2): Nv 40` in both end lines.

- [ ] **Step 5: `CLAUDE.md`**

```bash
cd /c/Users/peixe/Documents/rpg-turnos && perl -pi -e 's/`_credits_sections\(/`CreditsData.credits_sections(/g; s/`_v2_credits_sections\(/`CreditsData.v2_credits_sections(/g; s/`_v2_numbers\(/`CreditsData.v2_numbers(/g; s/`AUTHOR`/`CreditsData.AUTHOR`/g' CLAUDE.md
```

Insert after the `scripts/story/cutscene.gd` (`Cutscene`) entry:

```markdown
- `scripts/story/credits_data.gd` (`CreditsData`, `RefCounted`, M-70) — pure: what the credits say, from a `GameState`: `credits_sections(state, time_text)` (the v1's), `v2_numbers(state, play_time)` (`{time, battles, since}`: the v2's time and battles since `story.v2_start`), `v2_credits_sections(state, numbers)`, `clock(seconds)` ("h:mm:ss"), `summary(data)` (the one-line JSON of `--autoplay-save`) and `AUTHOR`.
```

- [ ] **Step 6: Commit**

```bash
cd /c/Users/peixe/Documents/rpg-turnos && git add scripts/story/credits_data.gd scripts/game/game.gd CLAUDE.md && git commit -m "Move the credits' sections, the clock and the save summary from Game to CreditsData"
```

---

### Task 3: `AutoplayStarts`

**Files:**
- Create: `scripts/game/autoplay_starts.gd`
- Modify: `scripts/game/game.gd` (consts `ECHO_START`, `MEDAL_TOUR`, `MEDAL_TOUR_CHANCE`, `MEDAL_TOUR_TIME`, `V2_STARTS`, `AUTOPLAY_ZONES`, `AUTOPLAY_INN_RATIO`, `AUTOPLAY_STALL_S`, `AUTOPLAY_BOSS_HP`, `AUTOPLAY_BOSS_MP`; func `_rested_for_boss`; the companion block of `_ready()`)
- Modify: `CLAUDE.md`

**Interfaces:**
- Consumes: `RunFlags.autoplay_companion() -> String` ("" when absent).
- Produces:

```gdscript
AutoplayStarts.ECHO_START / MEDAL_TOUR / MEDAL_TOUR_CHANCE / MEDAL_TOUR_TIME / V2_STARTS / AUTOPLAY_ZONES
AutoplayStarts.AUTOPLAY_INN_RATIO / AUTOPLAY_STALL_S / AUTOPLAY_BOSS_HP / AUTOPLAY_BOSS_MP
AutoplayStarts.DEFAULT_COMPANION := "brena"
static func companion() -> String
static func rested_for_boss(hero: Combatant) -> bool
```

- [ ] **Step 1: Create `scripts/game/autoplay_starts.gd`**

Write this header:

```gdscript
class_name AutoplayStarts extends RefCounted
## Rule (data): the starts of --autoplay-zone=<id> (AUTOPLAY_ZONES, ECHO_START, MEDAL_TOUR,
## V2_STARTS), the thresholds the self-playing run plays by (when it stops at an inn, when
## the boss may come out, when a quiet map gets its groups back) and the companion of
## --autoplay-companion=<id>. GameAutoplay plays them; nothing here touches nodes.

## The companion autoplay chooses at the Caravana when --autoplay-companion names none.
const DEFAULT_COMPANION := "brena"
```

Then cut from `game.gd` and paste below it, unchanged with their comments and in this order:

1. `AUTOPLAY_INN_RATIO`, `AUTOPLAY_STALL_S`, `AUTOPLAY_BOSS_HP`, `AUTOPLAY_BOSS_MP`;
2. `ECHO_START`, `MEDAL_TOUR`, `MEDAL_TOUR_CHANCE`, `MEDAL_TOUR_TIME`, `V2_STARTS`;
3. the whole `AUTOPLAY_ZONES` dictionary, from its `## --autoplay-zone=<id>:` comment to its closing `}`.

Its keys `ECHO_START:` and `MEDAL_TOUR:` now name this file's consts.

Then append:

```gdscript


## --autoplay-companion=<id>: that companion, DEFAULT_COMPANION if none is given or the id
## is not a companion (with an error that names it).
static func companion() -> String:
	var id := RunFlags.autoplay_companion()
	if id == "":
		return DEFAULT_COMPANION
	if not Allies.is_companion(id):
		push_error("Not a companion for --autoplay-companion: %s" % id)
		return DEFAULT_COMPANION
	return id


## The hero has AUTOPLAY_BOSS_HP of his max HP and AUTOPLAY_BOSS_MP of his max MP: on
## autoplay the zone's boss only comes out then.
static func rested_for_boss(hero: Combatant) -> bool:
	return hero.hp >= hero.max_hp * AUTOPLAY_BOSS_HP \
		and hero.mp >= hero.max_mp * AUTOPLAY_BOSS_MP
```

- [ ] **Step 2: Point `Game` to it**

In `_ready()`, find the lines that give `_autoplay_companion` its value from `RunFlags.autoplay_companion()`. They include an `Allies.is_companion()` check and a `push_error("Not a companion for --autoplay-companion: ...")`. Replace them with the single line `_autoplay_companion = AutoplayStarts.companion()`.

Delete `func _rested_for_boss()` and its comment. Then:

```bash
cd /c/Users/peixe/Documents/rpg-turnos && perl -pi -e 's/(?<![.\w])_rested_for_boss\(\)/AutoplayStarts.rested_for_boss(state.hero)/g; s/(?<![.\w])(ECHO_START|MEDAL_TOUR_CHANCE|MEDAL_TOUR_TIME|MEDAL_TOUR|V2_STARTS|AUTOPLAY_ZONES|AUTOPLAY_INN_RATIO|AUTOPLAY_STALL_S|AUTOPLAY_BOSS_HP|AUTOPLAY_BOSS_MP)\b/AutoplayStarts.$1/g' scripts/game/game.gd
grep -nP '(?<![.\w])(ECHO_START|MEDAL_TOUR\w*|V2_STARTS|AUTOPLAY_ZONES|AUTOPLAY_\w+_(RATIO|S|HP|MP)|_rested_for_boss)\b' scripts/game/game.gd
grep -n 'autoplay-companion' scripts/game/game.gd
```

Expected: both `grep`s print nothing.

- [ ] **Step 3: Import and validate**

Validate `res://scripts/game/autoplay_starts.gd` and `res://scripts/game/game.gd`. Expected: no errors.

- [ ] **Step 4: Runs, every start once**

```bash
for r in bosque mina_1 mina_3 castillo_patio castillo_trono eco medallas jungla desierto montana portal ciudad caravana60; do echo "### $r"; bash C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/check.sh $r; done
```

Expected for each run:

- nothing under errors and the diff;
- `medallas` ends `Medallas: 12/12 · premios 5/5`;
- `eco` has `Eco de la Niebla: victoria`.

Then check the companion flag in a window:

```bash
cd /c/Users/peixe/Documents/rpg-turnos && APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --fixed-fps 10 --quit-after 3000 -- --autoplay --autoplay-zone=jungla --autoplay-companion=tadeo 2>&1 | grep -m2 -E 'Zona de inicio|ERROR'
```

Expected: `Zona de inicio: jungla (Nv 20)` and no `ERROR`.

- [ ] **Step 5: `CLAUDE.md`**

```bash
cd /c/Users/peixe/Documents/rpg-turnos && perl -pi -e 's/`(AUTOPLAY_ZONES|ECHO_START|MEDAL_TOUR_CHANCE|MEDAL_TOUR_TIME|MEDAL_TOUR|V2_STARTS|AUTOPLAY_STALL_S|AUTOPLAY_INN_RATIO|AUTOPLAY_BOSS_HP|AUTOPLAY_BOSS_MP)`/`AutoplayStarts.$1`/g' CLAUDE.md
```

Insert after the `SessionContext` entry:

```markdown
- `scripts/game/autoplay_starts.gd` (`AutoplayStarts`, `RefCounted`, M-70) — pure data: the starts of `--autoplay-zone=<id>` (`AUTOPLAY_ZONES`, `ECHO_START`, `MEDAL_TOUR` with `MEDAL_TOUR_CHANCE` / `MEDAL_TOUR_TIME`, `V2_STARTS`), the autoplay thresholds (`AUTOPLAY_INN_RATIO`, `AUTOPLAY_STALL_S`, `AUTOPLAY_BOSS_HP`, `AUTOPLAY_BOSS_MP`; `rested_for_boss(hero)`) and `companion()` (`--autoplay-companion=<id>`, `DEFAULT_COMPANION` "brena" if none or not a companion).
```

- [ ] **Step 6: Commit**

```bash
cd /c/Users/peixe/Documents/rpg-turnos && git add scripts/game/autoplay_starts.gd scripts/game/game.gd CLAUDE.md && git commit -m "Move the autoplay starts and thresholds from Game to AutoplayStarts"
```

---

### Task 4: `BattleRewards`

**Files:**
- Create: `scripts/game/battle_rewards.gd`
- Modify: `scripts/game/game.gd` (consts `BOSS_NOTICES`, `REWARD_LINE`, `KEY_ITEM_NOTICE`; funcs `_note_enemies`, `_give_family_rewards`, `_boss_notice`; bodies of `_boss_id`, `_boss_wanted`; the won block of `_on_encounter`)
- Modify: `CLAUDE.md`

**Interfaces:**
- Produces:

```gdscript
static func boss_id(zone: ZoneData, state: GameState) -> String
static func boss_wanted(zone: ZoneData, state: GameState, postgame_allowed: bool) -> bool
static func note_enemies(state: GameState, enemies: Array[Combatant], beaten: bool) -> void
static func family_rewards(state: GameState) -> Array[String]
static func boss_notice(state: GameState, boss: Combatant) -> String
static func after_victory(state: GameState, zone: ZoneData, enemies: Array[Combatant],
		gold_won: int, medals_won: int, boss: bool) -> Dictionary
# after_victory returns {notice: String, reward_lines: Array[String], scene: String,
#   mission_done: bool, finished_quests: Array[Dictionary], family_lines: Array[String],
#   ending_v2: bool}
```

- [ ] **Step 1: Create `scripts/game/battle_rewards.gd`**

```gdscript
class_name BattleRewards extends RefCounted
## Rule: what a battle on the map means for the GameState. The boss of a map (boss_id(): the
## zone's, or its postgame boss once the game is finished) and whether it is on the map
## (boss_wanted()); the bestiary notes (note_enemies(): seen, or beaten after a won battle;
## only the enemies with a card) and the families' prizes (family_rewards()); and everything a
## victory gives (after_victory(): gold, medals, the village quest, the side quests, a boss's
## flag, key item, notice, cutscene and first-victory prize, the families). It changes the
## state and returns what to say; BattleFlow plays it back. Never touches nodes.

## Notice after beating a boss (by id); other bosses announce their key item.
const BOSS_NOTICES := {
	"rey_slime": "¡Villaclaro está a salvo! La niebla deja libre el camino del norte.",
	"senor_niebla": "¡Consigues el último Fragmento del amuleto! La niebla se levanta.",
	"eco_niebla": "El Eco de la Niebla se deshace en la bruma... por ahora.",
}
## Said before a boss's first-victory prize (Combatant.reward_equipment).
const REWARD_LINE := "Entre la bruma brilla algo."
const KEY_ITEM_NOTICE := "¡Consigues un %s!"


## The boss of this map: the zone's, or its postgame boss (ZoneData.postgame_boss_id) once
## the game is finished.
static func boss_id(zone: ZoneData, state: GameState) -> String:
	if zone.postgame_boss_id != "" and state.is_finished():
		return zone.postgame_boss_id
	return zone.boss_id


## The boss of this map is due: not beaten yet (the Rey Slime only while the quest asks for
## it). The postgame boss can always be fought again, when postgame_allowed (autoplay only
## meets it on --autoplay-zone=eco).
static func boss_wanted(zone: ZoneData, state: GameState, postgame_allowed: bool) -> bool:
	var boss := boss_id(zone, state)
	if boss == "":
		return false
	if boss == zone.postgame_boss_id:
		# It can always be fought again; autoplay only meets it on --autoplay-zone=eco.
		return postgame_allowed
	return state.quest.boss_available() if boss == Quest.BOSS_ID else not state.has_flag(boss)


## Notes enemies in the bestiary: seen, or beaten too after a won battle. Only those with a
## card (Bestiary.has()): the Eco de la Niebla never counts.
static func note_enemies(state: GameState, enemies: Array[Combatant], beaten: bool) -> void:
	for enemy in enemies:
		if not Bestiary.has(enemy.id):
			continue
		if beaten:
			state.defeat_enemy(enemy.id)
		else:
			state.see_enemy(enemy.id)


## Gives the prize of every bestiary family completed and not paid yet (Bestiary): its
## flag and its piece. Returns the lines that say so, for the dialogue window.
static func family_rewards(state: GameState) -> Array[String]:
	var lines: Array[String] = []
	for family_id in Bestiary.new_rewards(state):
		lines.append(Bestiary.give(state, family_id))
	return lines


## Sets the boss's world flag, gives its key item and says so.
static func boss_notice(state: GameState, boss: Combatant) -> String:
	var key_item := state.on_boss_defeated(boss)
	if BOSS_NOTICES.has(boss.id):
		return BOSS_NOTICES[boss.id]
	if key_item != "":
		return KEY_ITEM_NOTICE % Inventory.KEY_ITEMS[key_item]
	return ""


## A won battle: the gold, the medals dropped, the enemies beaten in the bestiary, the village
## quest and the side quests, each boss's flag, key item, notice, cutscene and first-victory
## prize, and the families completed (not after the v2's last boss the first time: its
## ending follows, and the prize comes when the game is next loaded).
static func after_victory(state: GameState, zone: ZoneData, enemies: Array[Combatant],
		gold_won: int, medals_won: int, boss: bool) -> Dictionary:
	var notice := ""
	var reward_lines: Array[String] = []
	var scene := ""
	var finished_quests: Array[Dictionary] = []
	var family_lines: Array[String] = []
	state.gold += gold_won
	state.gold_earned += gold_won
	var quest_was_on := state.quest.stage != Quest.Stage.DONE
	note_enemies(state, enemies, true)
	for n in medals_won:
		Medals.take(state, Medals.next_missing(state))
	for enemy in enemies:
		state.quest.on_victory(enemy.id)
		if enemy.is_boss:
			var first := not state.has_flag(enemy.id)
			notice = boss_notice(state, enemy)
			scene = state.story.scene_after_boss(enemy.id)
			if first and enemy.reward_equipment != "":
				reward_lines.append(REWARD_LINE)
				reward_lines.append_array(QuestRewards.wear_prize(state,
					enemy.reward_equipment))
	var mission_done := quest_was_on and state.quest.stage == Quest.Stage.DONE
	for enemy in enemies:
		finished_quests.append_array(state.quests.on_victory(state, enemy.id))
	# The enemies are noted as beaten above: a family may be complete now.
	# The v2's last boss (the first time): its ending follows. It also completes the Jefes
	# de la caravana, but no map is left to show the prize on: it comes when the game is
	# next loaded, in the Caravana (Game._ready() gives it).
	var ending_v2 := boss and boss_id(zone, state) == StoryState.V2_FINAL_BOSS \
		and not state.story.finished_v2
	if not ending_v2:
		family_lines = family_rewards(state)
	return {
		"notice": notice,
		"reward_lines": reward_lines,
		"scene": scene,
		"mission_done": mission_done,
		"finished_quests": finished_quests,
		"family_lines": family_lines,
		"ending_v2": ending_v2,
	}
```

The original block counted the common enemies and printed `Medalla: n/m` between the medals and the quest loop. That now happens after `after_victory()` (Step 2). No class it calls prints anything. Check it:

```bash
cd /c/Users/peixe/Documents/rpg-turnos && grep -n 'print(' scripts/game/quest.gd scripts/game/quest_log.gd scripts/game/bestiary.gd scripts/game/quest_rewards.gd scripts/game/medals.gd scripts/game/game_state.gd
```

Expected: no output.

- [ ] **Step 2: Use it in `Game._on_encounter()`**

In `_on_encounter()`, replace the block that begins with the line `	if won:` followed by `		state.gold += battle.engine.gold_won`. It ends with the line `			family_lines = _give_family_rewards()`, just before `	elif outcome == BattleEngine.State.LOST:`. Replace it with:

```gdscript
	if won:
		var rewards := BattleRewards.after_victory(state, _zone, battle.engine.enemies,
			battle.engine.gold_won, battle.engine.medals_won, boss)
		notice = rewards.notice
		reward_lines.assign(rewards.reward_lines)
		scene = rewards.scene
		mission_done = rewards.mission_done
		finished_quests.assign(rewards.finished_quests)
		family_lines.assign(rewards.family_lines)
		ending_v2 = rewards.ending_v2
		if _autoplay:
			for enemy in battle.engine.enemies:
				if not enemy.is_boss:
					_common_beaten += 1
			if battle.engine.medals_won > 0:
				print("Medalla: %d/%d" % [state.medals.size(), Medals.MEDALS.size()])
```

If plan 1 replaced `_autoplay` with `RunFlags.autoplay()`, write `RunFlags.autoplay()` in the line `if _autoplay:` above.

- [ ] **Step 3: Remove the rest from `Game`**

Delete from `game.gd`:

- `BOSS_NOTICES`, `REWARD_LINE` and `KEY_ITEM_NOTICE` with their comments;
- `_note_enemies`, `_give_family_rewards` and `_boss_notice` with their comments.

Replace the bodies of `_boss_id()` and `_boss_wanted()`, keeping their comments:

```gdscript
func _boss_id() -> String:
	return BattleRewards.boss_id(_zone, state)
```

```gdscript
func _boss_wanted() -> bool:
	return BattleRewards.boss_wanted(_zone, state, not RunFlags.autoplay() or _autoplay_echo)
```

Then:

```bash
cd /c/Users/peixe/Documents/rpg-turnos && perl -pi -e 's/(?<![.\w])_note_enemies\(/BattleRewards.note_enemies(state, /g; s/(?<![.\w])_give_family_rewards\(\)/BattleRewards.family_rewards(state)/g' scripts/game/game.gd
grep -nP '(?<![.\w])(_note_enemies|_give_family_rewards|_boss_notice|BOSS_NOTICES|REWARD_LINE|KEY_ITEM_NOTICE)\b' scripts/game/game.gd
```

Expected: the `grep` prints nothing.

- [ ] **Step 4: Import and validate**

Validate `res://scripts/game/battle_rewards.gd` and `res://scripts/game/game.gd`. Expected: no errors.

- [ ] **Step 5: Runs**

```bash
for r in v1 eco ciudad save; do echo "### $r"; bash C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/check.sh $r; done
grep -c 'Entre la bruma brilla algo.' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/new/eco.log
grep -c 'Medalla:' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/new/v1.log C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/v1.log
```

Expected:

- `v1`: no errors and an empty diff, `Juego completado: Nv 18`.
- `eco`: no errors and an empty diff, at least one victory, and `1` for the reward line.
- `ciudad`: no errors and an empty diff, `Juego completado (v2)`.
- `save`: `1`.
- The `Medalla:` counts: a number of the same order in both logs (the drops are random).

- [ ] **Step 6: `CLAUDE.md`**

```bash
cd /c/Users/peixe/Documents/rpg-turnos && perl -pi -e 's/`_give_family_rewards\(/`BattleRewards.family_rewards(/g; s/`_note_enemies\(/`BattleRewards.note_enemies(/g; s/`(BOSS_NOTICES|REWARD_LINE)`/`BattleRewards.$1`/g' CLAUDE.md
```

Insert after the `AutoplayStarts` entry:

```markdown
- `scripts/game/battle_rewards.gd` (`BattleRewards`, `RefCounted`, M-70) — pure: `boss_id(zone, state)` (the zone's boss, or its `postgame_boss_id` once the game is finished), `boss_wanted(zone, state, postgame_allowed)`, `note_enemies(state, enemies, beaten)` (only the enemies with a bestiary card), `family_rewards(state)` (every family newly complete: its flag, its piece and the lines), `boss_notice(state, boss)` (`BOSS_NOTICES`, `KEY_ITEM_NOTICE`), and `after_victory(state, zone, enemies, gold_won, medals_won, boss)`: everything a won battle gives, returned as `{notice, reward_lines, scene, mission_done, finished_quests, family_lines, ending_v2}` (`REWARD_LINE` before a boss's first-victory prize; no family prize after the Devorador's first fall).
```

- [ ] **Step 7: Commit**

```bash
cd /c/Users/peixe/Documents/rpg-turnos && git add scripts/game/battle_rewards.gd scripts/game/game.gd CLAUDE.md && git commit -m "Move what a victory gives, the boss rules and the bestiary notes from Game to BattleRewards"
```

---

### Task 5: `ZoneTravel`

**Files:**
- Create: `scripts/game/zone_travel.gd`
- Modify: `scripts/game/game.gd`
  - consts `WORLD_SCENE`, `PORTAL_OPEN_NOTICE`, `PORTAL_REPLACED_NOTICE`, `PORTAL_BACK_NOTICE`;
  - vars `_zone`, `_rng`;
  - funcs `_switch_zone`, `_on_exit`, `_on_travel_requested`, `_on_portal`, `_show_portal`, `_go_to_town`, `_respawn_groups`, `_spawn_rare`, `_to_place`;
  - new `_make_pieces`, `_add_pieces`, `_on_world_replaced`, `_on_zone_switched`, `_on_portal_taken`.
- Modify: `CLAUDE.md`

**Interfaces:**
- Consumes: `SessionContext` (Task 1), `BattleRewards.boss_id()` (Task 4), `CreditsData.clock()` (Task 2).
- Produces:

```gdscript
class_name ZoneTravel extends Node
signal world_replaced(world: World)
signal zone_switched(zone_id: String)
signal village_checked(inside: bool)
signal portal_taken
var check_arrival_line: Callable   # await check_arrival_line.call()
var check_village_scene: Callable  # check_village_scene.call()
var update_boss: Callable          # update_boss.call()
func setup(ctx: SessionContext) -> void
func switch_zone(zone_id: String, entry_id: String) -> void
func on_exit(zone_id: String, entry_id: String) -> void        # awaitable
func on_travel_requested() -> void                             # awaitable
func on_portal() -> void                                       # awaitable
func show_portal() -> void
func go_to_town() -> void
func respawn_groups() -> void
func spawn_rare() -> void
static func to_place(place: String) -> String
```

- Game: `_make_pieces()`, `_add_pieces()` and `_on_world_replaced(world: World)`, which later tasks extend.

- [ ] **Step 1: Create `scripts/game/zone_travel.gd` with its skeleton and `switch_zone()`**

```gdscript
class_name ZoneTravel extends Node
## Node, a piece of Game: the change of map. Builds the next zone's World (switch_zone(),
## which hands it to Game through world_replaced), walks through an open exit (on_exit()),
## flies to the last village with the Ala de viaje and opens its portal back
## (on_travel_requested()), takes that portal back once (on_portal()), sends a beaten hero to
## the village (go_to_town()) and puts the groups and the Slime de Metal back on the map
## (respawn_groups(), spawn_rare()). Gets the session in setup(); never stores Game or a
## World (the current map is SessionContext.world).

## A new map was built (zone and boss set, not in the tree yet): Game frees the old one,
## puts this one first in the tree, sets SessionContext.world, freezes it, gives it the
## audio and connects its signals, before anything else touches it.
signal world_replaced(world: World)
## switch_zone() is over (on autoplay it prints "Zona: ..." and starts its quiet clock over).
signal zone_switched(zone_id: String)
## After a trip, whether the hero stands inside the village (as World.village_changed).
signal village_checked(inside: bool)
## The return portal was taken (on autoplay the quiet clock starts over).
signal portal_taken

const WORLD_SCENE := preload("res://scenes/world/world.tscn")

## await check_arrival_line.call(): the companion's line on reaching a land (StoryFlow).
var check_arrival_line: Callable
## check_village_scene.call(): the village's first-visit cutscene (StoryFlow).
var check_village_scene: Callable
## update_boss.call(): shows or hides the zone's boss (BattleFlow).
var update_boss: Callable

var _ctx: SessionContext
var _rng := RandomNumberGenerator.new()


func setup(ctx: SessionContext) -> void:
	_ctx = ctx
	_rng.randomize()


## Frees the current map and builds zone_id with the player at entry_id ("" for the
## zone's start entry). No fade: callers fade around it. The new map starts frozen
## (World.freeze()), so nothing on it can fire while Game is still busy fading in;
## every caller unfreezes it once the fade is over.
func switch_zone(zone_id: String, entry_id: String) -> void:
	var zone := ZoneData.by_id(zone_id)
	if zone_id == CampLook.ZONE:
		zone = CampLook.dressed(zone, _ctx.state.tramo())  # the land it camps by (2.4.0)
	_ctx.state.zone_id = zone_id
	var world: World = WORLD_SCENE.instantiate()
	world.zone = zone
	world.boss_id = BattleRewards.boss_id(zone, _ctx.state)
	world_replaced.emit(world)
	_ctx.world.set_dry_wells(Wells.dry_ids(_ctx.state))
	if entry_id != "":
		_ctx.world.place_at_entry(entry_id)
	for id in _ctx.state.opened_chests:
		_ctx.world.set_chest_open(id, true, true)
	_ctx.world.set_explored(_ctx.state.explored_map(zone_id))
	_ctx.world.set_world_flags(_ctx.state.world_flags)
	show_portal()
	update_boss.call()
	spawn_rare()
	_ctx.refresh_status.call()
	MusicLibrary.build(zone.music)
	AmbientLibrary.prepare(zone.ambient)  # under black, like the music
	if _ctx.world.in_village():
		village_checked.emit(true)
	zone_switched.emit(zone_id)
```

Notes against `Game._switch_zone()`:

- The connections move to `Game._on_world_replaced()`, which also frees the old map.
- `_quiet_s = 0.0` and the `Zona:` print move to `zone_switched`.
- `_on_village_changed(true)` becomes `village_checked.emit(true)`.
- Nothing reads the old map between `ZoneData.by_id()` and the new map, so freeing it after `instantiate()` changes nothing.

Delete `_switch_zone` from `game.gd`.

- [ ] **Step 2: Move the other eight functions**

Cut these from `game.gd` into `move.gd`, with their comments: `_go_to_town`, `_respawn_groups`, `_spawn_rare`, `_on_exit`, `_on_travel_requested`, `_on_portal`, `_show_portal`, `_to_place`. Delete the four consts `WORLD_SCENE`, `PORTAL_OPEN_NOTICE`, `PORTAL_REPLACED_NOTICE` and `PORTAL_BACK_NOTICE` from `game.gd`. Put the last three in the skeleton, under `WORLD_SCENE`, with their exact texts.

Run the global perl, then this piece-local perl:

```bash
perl -pi -e 's/(?<![.\w])_(switch_zone|show_portal|go_to_town|respawn_groups|spawn_rare|to_place|on_exit|on_travel_requested|on_portal)\b/$1/g; s/(?<![.\w])_on_village_changed\(/village_checked.emit(/g; s/(?<![.\w])_check_arrival_line\(\)/check_arrival_line.call()/g; s/(?<![.\w])_check_village_scene\(\)/check_village_scene.call()/g; s/(?<![.\w])_update_boss\(\)/update_boss.call()/g' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/move.gd
```

Then by hand in `move.gd`:

- in `on_portal()`, replace `	_quiet_s = 0.0` with `	portal_taken.emit()`;
- `static func to_place(place: String) -> String:`. The perl removes only the underscore, so check that `static` is still there.
- `_zone` reads: in `game.gd` they were `_zone.`. Replace them in `move.gd` with `_ctx.zone.`:

```bash
perl -pi -e 's/(?<![.\w])_zone\b/_ctx.zone/g' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/move.gd
```

Append `move.gd` to `zone_travel.gd`.

- [ ] **Step 3: The owner's side in `Game`**

1. Delete `var _zone: ZoneData`, `var _rng := RandomNumberGenerator.new()` and the line `_rng.randomize()` in `_ready()`.
2. Add the member `var _travel: ZoneTravel` after `var _ctx: SessionContext`.
3. Add these functions after `_make_context()`:

```gdscript
## The pieces of the session, created at once (so the pause menu and the debug panel can be
## wired to them); set up and added to the tree later, by _add_pieces().
func _make_pieces() -> void:
	_travel = ZoneTravel.new()


## The pieces set up, wired and added, where Game used to build what they hold (node
## order matters for input and processing). Callables are what a piece awaits from another
## one; signals are what it only reports.
func _add_pieces() -> void:
	_travel.setup(_ctx)
	_travel.check_arrival_line = _check_arrival_line
	_travel.check_village_scene = _check_village_scene
	_travel.update_boss = _update_boss
	_travel.world_replaced.connect(_on_world_replaced)
	_travel.zone_switched.connect(_on_zone_switched)
	_travel.village_checked.connect(_on_village_changed)
	_travel.portal_taken.connect(_on_portal_taken)
	add_child(_travel)


## ZoneTravel built a new map: the old one goes, the new one is first in the tree and stays
## frozen until its caller's fade is over.
func _on_world_replaced(world: World) -> void:
	if _ctx.world:
		remove_child(_ctx.world)
		_ctx.world.queue_free()
	_ctx.world = world
	add_child(world)
	move_child(world, 0)
	world.freeze(true)
	world.set_audio(_audio)
	world.encounter_triggered.connect(_on_encounter)
	world.talk_requested.connect(_on_talk)
	world.npc_requested.connect(_on_npc)
	world.shop_requested.connect(_on_shop)
	world.inn_requested.connect(_on_inn)
	world.chest_opened.connect(_on_chest)
	world.well_requested.connect(_on_well)
	world.exit_requested.connect(_travel.on_exit)
	world.map_requested.connect(_pause.open_map)
	world.portal_used.connect(_travel.on_portal)
	world.lever_pulled.connect(_on_lever)
	world.key_taken.connect(_on_key)
	world.door_used.connect(_on_door)
	world.village_changed.connect(_on_village_changed)
	world.stepped.connect(_on_stepped)


## A map was built: autoplay's quiet clock starts over, and on autoplay the zone is printed.
func _on_zone_switched(zone_id: String) -> void:
	_quiet_s = 0.0
	if RunFlags.autoplay():
		print("Zona: %s (Nv %d, %s)" % [zone_id, state.hero.level,
			CreditsData.clock(_ctx.play_time)])


## The return portal was taken: autoplay's quiet clock starts over.
func _on_portal_taken() -> void:
	_quiet_s = 0.0
```

4. In `_ready()`:
   - call `_make_pieces()` right after `_make_context()`;
   - call `_add_pieces()` right after the line `_build_cutscenes()`.
5. In `_build_pause()`, change `_pause.travel_requested.connect(_on_travel_requested)` to `_pause.travel_requested.connect(_travel.on_travel_requested)`.
6. Point the rest of `Game` to the piece:

```bash
cd /c/Users/peixe/Documents/rpg-turnos && perl -pi -e 's/(?<![.\w])_zone\b/_ctx.zone/g; s/(?<![.\w])_switch_zone\(/_travel.switch_zone(/g; s/(?<![.\w])_respawn_groups\(\)/_travel.respawn_groups()/g; s/(?<![.\w])_spawn_rare\(\)/_travel.spawn_rare()/g; s/(?<![.\w])_go_to_town\(\)/_travel.go_to_town()/g; s/(?<![.\w])_to_place\(/ZoneTravel.to_place(/g; s/(?<![.\w])_on_portal\(\)/_travel.on_portal()/g; s/(?<![.\w])_on_travel_requested\(\)/_travel.on_travel_requested()/g' scripts/game/game.gd
grep -nP '(?<![.\w])(_zone|_rng|_switch_zone|_show_portal|_go_to_town|_respawn_groups|_spawn_rare|_to_place|_on_exit|_on_portal|_on_travel_requested|WORLD_SCENE|PORTAL_\w+)\b' scripts/game/game.gd
```

Expected: the `grep` prints nothing. `_ctx.zone` and the `_travel.` calls are preceded by `.`, so they don't match.

- [ ] **Step 4: Import and validate**

Validate `res://scripts/game/zone_travel.gd` and `res://scripts/game/game.gd`. Expected: no errors.

- [ ] **Step 5: Runs**

```bash
for r in save v1 medallas; do echo "### $r"; bash C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/check.sh $r; done
grep -cE '^Retirada al pueblo|^Derrota en' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/new/v1.log
```

Expected:

- each run: no errors and an empty diff;
- `save`: `1`;
- `v1`: `Juego completado: Nv 18`;
- `medallas`: `12/12 · premios 5/5`;
- the count is above 0, so the Ala, its portal or a defeat's way back were played.

- [ ] **Step 6: `CLAUDE.md`**

```bash
cd /c/Users/peixe/Documents/rpg-turnos && perl -pi -e 's/`_switch_zone\(/`ZoneTravel.switch_zone(/g; s/`_respawn_groups\(/`ZoneTravel.respawn_groups(/g; s/`_spawn_rare\(/`ZoneTravel.spawn_rare(/g; s/`_go_to_town\(/`ZoneTravel.go_to_town(/g; s/`_on_portal\(/`ZoneTravel.on_portal(/g; s/`_to_place\(/`ZoneTravel.to_place(/g' CLAUDE.md
```

Insert after the `BattleRewards` entry:

```markdown
- `scripts/game/zone_travel.gd` (`ZoneTravel`, `Node`, a piece of `Game`, M-70) — the change of map: `switch_zone(zone_id, entry_id)` (builds the zone's `World`, the Caravana dressed by `CampLook`, and hands it to `Game` with `world_replaced(world)` before touching it; then wells, entry, chests, explored map, flags, portal, boss (`update_boss`), the Slime de Metal, the status, the music and ambient prepared under black, `village_checked(true)` inside a village and `zone_switched(zone_id)`), `on_exit()` (an arch or stairs), `on_travel_requested()` (the Ala de viaje and its portal), `on_portal()` (the way back, `portal_taken`), `show_portal()`, `go_to_town()` (a defeat), `respawn_groups()`, `spawn_rare()` and the static `to_place(place)` ("a Villaclaro", "al refugio de la mina"). It awaits `check_arrival_line` and calls `check_village_scene` and `update_boss`, Callables `Game` wires.
```

Append to the *Conventions* list:

```markdown
- `Game` is a coordinator: each job of a session is a piece (`ZoneTravel`, `StoryFlow`, `CaravanFlow`, `FigureTalk`, `BattleFlow`, `GameAutoplay`, `GameDebug`), a `Node` child of `Game` (never of the `World`, which is freed on every change of zone, taking any `await` with it) that gets a `SessionContext` in `setup()`. A piece never stores `Game`. What it must have another piece do, and wait for, is a public `Callable` field (`await play_scene.call(id)`) that `Game` wires in `_add_pieces()`; what it only reports is a signal that `Game` connects. Only `GameAutoplay` and `GameDebug` are handed other pieces, and they use only their public functions.
```

At the end of the `Game` entry, append: ` The zone changes, exits, the Ala and its portal, the way back to the village and the groups' respawn are in ZoneTravel.`

- [ ] **Step 7: Commit**

```bash
cd /c/Users/peixe/Documents/rpg-turnos && git add scripts/game/zone_travel.gd scripts/game/game.gd CLAUDE.md && git commit -m "Move the zone changes, the Ala's portal and the groups' respawn from Game to ZoneTravel"
```

---

### Task 6: `StoryFlow`

**Files:**
- Create: `scripts/story/story_flow.gd`
- Modify: `scripts/game/game.gd`
  - consts `CUTSCENE_PATH`, `LOAD_FAILED_NOTICE`;
  - vars `_cutscenes`, `_load_failed`;
  - funcs `_play_scene`, `_play_prologue`, `_check_village_scene`, `_check_arrival_line`, `_scene_travel`, `_scene_flag`, `_finish_game`, `_finish_v2`, `_build_cutscenes`;
  - new `_on_game_completed`, `_on_v2_completed`.
- Modify: `CLAUDE.md`

**Interfaces:**
- Consumes: `ZoneTravel.switch_zone()`, `CreditsData`, `SessionContext`.
- Produces:

```gdscript
class_name StoryFlow extends Node
signal quit_requested
signal game_completed(time_text: String)   # autoplay only
signal v2_completed(numbers: Dictionary)   # autoplay only
var load_failed := false
var switch_zone: Callable       # switch_zone.call(zone_id, entry_id)
var choose_companion: Callable  # await choose_companion.call()
var show_touch_hint: Callable   # show_touch_hint.call()
func setup(ctx: SessionContext) -> void
func play_scene(scene_id: String) -> void        # awaitable
func play_prologue() -> void                     # awaitable
func check_village_scene() -> void               # awaitable
func check_arrival_line() -> void                # awaitable
func finish_game() -> void                       # awaitable
func finish_v2() -> void                         # awaitable
```

- [ ] **Step 1: Create `scripts/story/story_flow.gd`**

```gdscript
class_name StoryFlow extends Node
## Node, a piece of Game: the story played on the map. Each cutscene of data/cutscenes/
## through its CutscenePlayer (play_scene(), marked seen), the prologue of a new game
## (play_prologue()), the first visit's scene of each village (check_village_scene()), the
## companion's line the first time a land of the caravan is reached (check_arrival_line()),
## and the two endings: the v1's credits (finish_game()) and the v2's screen beyond the
## portal and its credits (finish_v2()). Gets the session in setup(); never stores Game or a
## World.

## Both endings are over: Game goes back to the title.
signal quit_requested
## Autoplay: the v1's credits rolled (GameAutoplay prints the numbers of the run).
signal game_completed(time_text: String)
## Autoplay: the v2's credits rolled (CreditsData.v2_numbers()).
signal v2_completed(numbers: Dictionary)

const CUTSCENE_PATH := "res://data/cutscenes/%s.tres"
const LOAD_FAILED_NOTICE := "No se pudo cargar la partida. Empiezas de nuevo."

## The save could not be read: the new game says so after the prologue (Game sets it).
var load_failed := false
## switch_zone.call(zone_id, entry_id): builds a map under black (ZoneTravel).
var switch_zone: Callable
## await choose_companion.call(): the Jefe de caravana's choice (CaravanFlow).
var choose_companion: Callable
## show_touch_hint.call(): the phone's first walking line (Game).
var show_touch_hint: Callable

var _ctx: SessionContext
var _cutscenes: CutscenePlayer


func setup(ctx: SessionContext) -> void:
	_ctx = ctx


func _ready() -> void:
	_build_cutscenes()


func _build_cutscenes() -> void:
	_cutscenes = CutscenePlayer.new()
	_cutscenes.audio = _ctx.audio
	_cutscenes.fade = _ctx.fade
	_cutscenes.set_flag = _scene_flag
	_cutscenes.travel = _scene_travel
	add_child(_cutscenes)
```

- [ ] **Step 2: Move the eight functions**

1. Cut from `game.gd` into `move.gd`, with their comments: `_check_arrival_line`, `_check_village_scene`, `_play_scene`, `_play_prologue`, `_finish_game`, `_finish_v2`, `_scene_travel`, `_scene_flag`.
2. Delete from `game.gd`:
   - `_build_cutscenes()` and its call in `_ready()`;
   - `const CUTSCENE_PATH` and `const LOAD_FAILED_NOTICE`;
   - `var _cutscenes: CutscenePlayer`;
   - `var _load_failed := false` and its comment;
   - the line `_load_failed = load_failed` in `_ready()`.
3. Run the global perl on `move.gd`, then:

```bash
perl -pi -e 's/(?<![.\w])_(play_scene|play_prologue|check_village_scene|check_arrival_line|finish_game|finish_v2)\b/$1/g; s/(?<![.\w])_travel\.switch_zone\(/switch_zone.call(/g; s/(?<![.\w])_choose_companion\(\)/choose_companion.call()/g; s/(?<![.\w])_show_touch_hint\(\)/show_touch_hint.call()/g; s/(?<![.\w])_load_failed\b/load_failed/g; s/(?<![.\w])quit_to_title\.emit\(\)/quit_requested.emit()/g' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/move.gd
```

4. By hand in `move.gd`:
   - In `finish_game()`, replace the whole `if RunFlags.autoplay():` block that prints `Juego completado: ...`, `Familias completas: ...`, `Derrotas: ...` and `Medallas: ... (enemigos comunes vencidos: ...)` with:

```gdscript
	if RunFlags.autoplay():
		game_completed.emit(time_text)
```

   - In `finish_v2()`, replace the `if RunFlags.autoplay():` block that prints `Juego completado (v2): ...` and the three lines after it with:

```gdscript
	if RunFlags.autoplay():
		v2_completed.emit(numbers)
```

   - Check that `finish_v2()` now reads `var numbers := CreditsData.v2_numbers(_ctx.state, _ctx.play_time)` and `switch_zone.call("caravana", "")`, and that `_scene_travel()` reads `switch_zone.call(zone_id, entry_id)` then `return _ctx.world`.
5. Append `move.gd` to `story_flow.gd`.

Keep the two print blocks just cut: they go to `Game` in Step 3.

- [ ] **Step 3: The owner's side**

1. Add `var _story: StoryFlow` after `var _travel: ZoneTravel`.
2. In `_make_pieces()`, add `_story = StoryFlow.new()`.
3. Change `func _add_pieces() -> void:` to `func _add_pieces(load_failed: bool) -> void:`. In `_ready()`, the call becomes `_add_pieces(load_failed)`, and it now stands where `_build_cutscenes()` was.
4. In `_add_pieces()`:
   - change `_travel.check_arrival_line = _check_arrival_line` to `_travel.check_arrival_line = _story.check_arrival_line`;
   - change `_travel.check_village_scene = _check_village_scene` to `_travel.check_village_scene = _story.check_village_scene`;
   - append:

```gdscript
	_story.setup(_ctx)
	_story.load_failed = load_failed
	_story.switch_zone = _travel.switch_zone
	_story.choose_companion = _choose_companion
	_story.show_touch_hint = _show_touch_hint
	_story.quit_requested.connect(func() -> void: quit_to_title.emit())
	_story.game_completed.connect(_on_game_completed)
	_story.v2_completed.connect(_on_v2_completed)
	add_child(_story)
```

5. Add these two handlers after `_on_portal_taken()`. Their print lines are the ones cut in Step 2, unchanged:

```gdscript
## Autoplay: the numbers of the whole run after the v1's credits.
func _on_game_completed(time_text: String) -> void:
	print("Juego completado: Nv %d, tiempo de juego %s, misiones %d" % [state.hero.level,
		time_text, state.quests_done()])
	print("Familias completas: %d/%d" % [Bestiary.complete_count(state),
		Bestiary.families(state).size()])
	print("Derrotas: %d" % _defeats)
	print("Medallas: %d/%d (enemigos comunes vencidos: %d)" % [state.medals.size(),
		Medals.MEDALS.size(), _common_beaten])


## Autoplay: the numbers of the v2 after its credits.
func _on_v2_completed(numbers: Dictionary) -> void:
	print("Juego completado (v2): Nv %d, tiempo en la caravana %s, tiempo de juego %s, misiones de la caravana %d/%d"
		% [state.hero.level, numbers.time, CreditsData.clock(_ctx.play_time),
		state.quests.done_of(true), QuestLog.total_of(true)])
	print("Familias completas: %d/%d" % [Bestiary.complete_count(state),
		Bestiary.families(state).size()])
	print("Derrotas: %d" % _defeats)
	print("Medallas: %d/%d (enemigos comunes vencidos: %d)" % [state.medals.size(),
		Medals.MEDALS.size(), _common_beaten])
```

6. Point the rest of `Game` to the piece:

```bash
cd /c/Users/peixe/Documents/rpg-turnos && perl -pi -e 's/(?<![.\w])_play_scene\(/_story.play_scene(/g; s/(?<![.\w])_check_village_scene\(\)/_story.check_village_scene()/g; s/(?<![.\w])_check_arrival_line\(\)/_story.check_arrival_line()/g; s/(?<![.\w])_play_prologue\.call_deferred\(\)/_story.play_prologue.call_deferred()/g; s/(?<![.\w])_finish_game\(\)/_story.finish_game()/g; s/(?<![.\w])_finish_v2\(\)/_story.finish_v2()/g' scripts/game/game.gd
grep -nP '(?<![.\w])(_play_scene|_play_prologue|_check_village_scene|_check_arrival_line|_scene_travel|_scene_flag|_finish_game|_finish_v2|_build_cutscenes|_cutscenes|_load_failed|CUTSCENE_PATH|LOAD_FAILED_NOTICE)\b' scripts/game/game.gd
```

Expected: the `grep` prints nothing.

- [ ] **Step 4: Import and validate**

Validate `res://scripts/story/story_flow.gd` and `res://scripts/game/game.gd`. Expected: no errors.

- [ ] **Step 5: Runs**

```bash
for r in v1 v2 save; do echo "### $r"; bash C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/check.sh $r; done
grep -E '^(Familias completas|Derrotas|Medallas: [0-9]+/12 \()' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/new/v1.log
```

Expected:

- each run: no errors and an empty diff; every `Escena:` line as in the reference;
- `v1`: `Juego completado: Nv 18`;
- `v2`: `Juego completado (v2): Nv 40`;
- `save`: `1`;
- the three end lines are there: `Familias completas: n/5`, `Derrotas: n`, `Medallas: n/12 (enemigos comunes vencidos: n)`.

- [ ] **Step 6: `CLAUDE.md`**

```bash
cd /c/Users/peixe/Documents/rpg-turnos && perl -pi -e 's/`_play_scene\(/`StoryFlow.play_scene(/g; s/`_play_prologue\(/`StoryFlow.play_prologue(/g; s/`_check_village_scene\(/`StoryFlow.check_village_scene(/g; s/`_check_arrival_line\(/`StoryFlow.check_arrival_line(/g; s/`_scene_travel\(/`StoryFlow._scene_travel(/g; s/`_scene_flag\(/`StoryFlow._scene_flag(/g; s/`_finish_game\(/`StoryFlow.finish_game(/g; s/`_finish_v2\(/`StoryFlow.finish_v2(/g' CLAUDE.md
```

Insert after the `CreditsData` entry:

```markdown
- `scripts/story/story_flow.gd` (`StoryFlow`, `Node`, a piece of `Game`, M-70) — the story on the map: owns the `CutscenePlayer` (`fade` from the context, `set_flag` and `travel` its own `_scene_flag()` / `_scene_travel()`), `play_scene(id)` (marks it seen, fills the hero's and the companion's names, the ambient back after it), `play_prologue()` (the slimes quest, `LOAD_FAILED_NOTICE` when a save could not be read: `load_failed`), `check_village_scene()` (the first visit's scene, the caravan's arrival in Villaclaro, then `choose_companion` after `caravana_campamento`), `check_arrival_line()`, `finish_game()` and `finish_v2()` (the credits through `CreditsData`, then `quit_requested`; on autoplay `game_completed(time_text)` / `v2_completed(numbers)` first, so the numbers are printed before the title). Callables `switch_zone`, `choose_companion`, `show_touch_hint`, wired by `Game`.
```

At the end of the `Game` entry, append: ` The cutscenes, the prologue and the endings are in StoryFlow.`

- [ ] **Step 7: Commit**

```bash
cd /c/Users/peixe/Documents/rpg-turnos && git add scripts/story/story_flow.gd scripts/game/game.gd CLAUDE.md && git commit -m "Move the cutscenes, the prologue and both endings from Game to StoryFlow"
```

---

### Task 7: `CaravanFlow`

**Files:**
- Create: `scripts/game/caravan_flow.gd`
- Modify: `scripts/game/game.gd` (consts `CARAVAN_CHIEF`, `JOIN_QUESTION`, `LEAVE_QUESTION`; funcs `_ask_departure`, `_choose_companion`)
- Modify: `scripts/story/story_flow.gd` (`check_village_scene()`)
- Modify: `CLAUDE.md`

**Interfaces:**
- Consumes: `StoryFlow.play_scene()`, `ZoneTravel.switch_zone()`, `AutoplayStarts.DEFAULT_COMPANION`.
- Produces:

```gdscript
class_name CaravanFlow extends Node
const CARAVAN_CHIEF := "Jefe de caravana"
var autoplay_companion := AutoplayStarts.DEFAULT_COMPANION
var autoplay_leaves := false
var play_scene: Callable    # await play_scene.call(scene_id)
var switch_zone: Callable   # switch_zone.call(zone_id, entry_id)
func setup(ctx: SessionContext, shop: ShopWindow) -> void
static func arrival_scene(state: GameState, zone_id: String) -> String
func ask_departure() -> void      # awaitable
func choose_companion() -> void   # awaitable
```

- [ ] **Step 1: Create `scripts/game/caravan_flow.gd`**

```gdscript
class_name CaravanFlow extends Node
## Node, a piece of Game: the caravan of the v2. Once the v1 is finished, its arrival in
## Villaclaro (arrival_scene()); the Jefe de caravana's two questions there, the farewell and
## the Caravana built under black (ask_departure()); and the choice of companion in the
## Caravana (choose_companion(): the Compañeros list, a shop at no cost). Gets the session
## and the ShopWindow in setup(); never stores Game or a World.

## The v2's Jefe de caravana: in Villaclaro once the caravan has come, then in the Caravana.
const CARAVAN_CHIEF := "Jefe de caravana"
const JOIN_QUESTION := "Cuando partamos, no volverás por aquí en mucho tiempo. ¿Te unes a la caravana?"
const LEAVE_QUESTION := "No podrás volver a Villaclaro, ni al bosque, la mina o el castillo. Las misiones que no hayas cumplido se quedan sin hacer."

## Autoplay: the companion it takes at once (--autoplay-companion; Game sets it).
var autoplay_companion := AutoplayStarts.DEFAULT_COMPANION
## Autoplay: answers the Jefe's questions Sí / Partir and leaves (only the V2_STARTS; every
## other autoplay run stays in the v1). Game sets it.
var autoplay_leaves := false
## await play_scene.call(scene_id): a cutscene (StoryFlow).
var play_scene: Callable
## switch_zone.call(zone_id, entry_id): builds a map under black (ZoneTravel).
var switch_zone: Callable

var _ctx: SessionContext
var _shop: ShopWindow


func setup(ctx: SessionContext, shop: ShopWindow) -> void:
	_ctx = ctx
	_shop = shop


## The caravan's arrival in Villaclaro: "caravana_llega" once the v1 is finished, before
## leaving with it, until seen; "" otherwise.
static func arrival_scene(state: GameState, zone_id: String) -> String:
	if zone_id == "pradera" and state.can_meet_caravan() \
			and not state.story.has_seen("caravana_llega"):
		return "caravana_llega"
	return ""
```

Cut `_ask_departure` and `_choose_companion` from `game.gd` into `move.gd`, with their comments. Delete the three consts from `game.gd`. Run the global perl, then:

```bash
perl -pi -e 's/(?<![.\w])_(ask_departure|choose_companion)\b/$1/g; s/(?<![.\w])_story\.play_scene\(/play_scene.call(/g; s/(?<![.\w])_travel\.switch_zone\(/switch_zone.call(/g; s/(?<![.\w])_autoplay_v2\b/autoplay_leaves/g; s/(?<![.\w])_autoplay_companion\b/autoplay_companion/g' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/move.gd
```

Check that `ask_departure()` begins with `	if RunFlags.autoplay() and not autoplay_leaves:`. Append `move.gd` to `caravan_flow.gd`.

- [ ] **Step 2: `StoryFlow` asks it for the arrival**

In `scripts/story/story_flow.gd`, `check_village_scene()`, replace:

```gdscript
	if scene == "" and _ctx.zone.id == "pradera" and _ctx.state.can_meet_caravan() \
			and not _ctx.state.story.has_seen("caravana_llega"):
		scene = "caravana_llega"
```

with:

```gdscript
	if scene == "":
		scene = CaravanFlow.arrival_scene(_ctx.state, _ctx.zone.id)
```

- [ ] **Step 3: The owner's side**

1. Add `var _caravan: CaravanFlow` after `var _story: StoryFlow`.
2. In `_make_pieces()`, add `_caravan = CaravanFlow.new()`.
3. In `_add_pieces()`:
   - change `_story.choose_companion = _choose_companion` to `_story.choose_companion = _caravan.choose_companion`;
   - append:

```gdscript
	_caravan.setup(_ctx, _shop)
	_caravan.play_scene = _story.play_scene
	_caravan.switch_zone = _travel.switch_zone
	_caravan.autoplay_companion = _autoplay_companion
	_caravan.autoplay_leaves = _autoplay_v2
	add_child(_caravan)
```

4. Point the rest of `Game` to the piece:

```bash
cd /c/Users/peixe/Documents/rpg-turnos && perl -pi -e 's/(?<![.\w])CARAVAN_CHIEF\b/CaravanFlow.CARAVAN_CHIEF/g; s/(?<![.\w])_choose_companion\(\)/_caravan.choose_companion()/g; s/(?<![.\w])_ask_departure\(\)/_caravan.ask_departure()/g' scripts/game/game.gd
grep -nP '(?<![.\w])(CARAVAN_CHIEF|JOIN_QUESTION|LEAVE_QUESTION|_ask_departure|_choose_companion)\b' scripts/game/game.gd
```

Expected: the `grep` prints nothing. `_on_npc()` now compares with `CaravanFlow.CARAVAN_CHIEF` and calls `_caravan.choose_companion()` / `_caravan.ask_departure()`.

- [ ] **Step 4: Import and validate**

Validate `res://scripts/game/caravan_flow.gd`, `res://scripts/story/story_flow.gd` and `res://scripts/game/game.gd`. Expected: no errors.

- [ ] **Step 5: Runs**

```bash
for r in v1 caravana60; do echo "### $r"; bash C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/check.sh $r; done
grep -E '^(Pregunta|Compañero|Escena: caravana)' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/new/caravana60.log | head
cd /c/Users/peixe/Documents/rpg-turnos && APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --fixed-fps 10 --quit-after 60000 -- --autoplay --autoplay-zone=caravana --autoplay-companion=tadeo 2>&1 | grep -m1 '^Compañero: '
```

Expected:

- both runs: no errors and an empty diff;
- `v1` has no `Pregunta:` line;
- the `grep` shows `Escena: caravana_llega`, the two `Pregunta: ... -> Sí` / `-> Partir` lines, `Escena: caravana_parte`, `Escena: caravana_campamento` and `Compañero: Brena`, in that order;
- the last command prints `Compañero: Tadeo`.

- [ ] **Step 6: `CLAUDE.md`**

```bash
cd /c/Users/peixe/Documents/rpg-turnos && perl -pi -e 's/`_ask_departure\(/`CaravanFlow.ask_departure(/g; s/`_choose_companion\(/`CaravanFlow.choose_companion(/g; s/`CARAVAN_CHIEF`/`CaravanFlow.CARAVAN_CHIEF`/g' CLAUDE.md
```

Insert after the `ZoneTravel` entry:

```markdown
- `scripts/game/caravan_flow.gd` (`CaravanFlow`, `Node`, a piece of `Game`, M-70) — the caravan of the v2: the static `arrival_scene(state, zone_id)` ("caravana_llega" in Villaclaro once the v1 is finished, until seen; `StoryFlow.check_village_scene()` asks it), `ask_departure()` (the Jefe's two questions `JOIN_QUESTION` / `LEAVE_QUESTION` with the focus on the answer that changes nothing, `caravana_parte`, `GameState.leave_for_caravan()`, `story.v2_start`, the Caravana under black) and `choose_companion()` (the `Compañeros` shop through the `ShopWindow` given in `setup()`; autoplay takes `autoplay_companion` at once); `autoplay_leaves` (only the `AutoplayStarts.V2_STARTS` answer Sí). `CARAVAN_CHIEF` "Jefe de caravana". Callables `play_scene` and `switch_zone`.
```

At the end of the `Game` entry, append: ` The Jefe de caravana's questions and the choice of companion are in CaravanFlow.`

- [ ] **Step 7: Commit**

```bash
cd /c/Users/peixe/Documents/rpg-turnos && git add scripts/game/caravan_flow.gd scripts/story/story_flow.gd scripts/game/game.gd CLAUDE.md && git commit -m "Move the caravan's questions and the choice of companion from Game to CaravanFlow"
```

---

### Task 8: `FigureTalk` (1 of 2: figures, shops and inns)

**Files:**
- Create: `scripts/game/figure_talk.gd`
- Modify: `scripts/game/game.gd`
  - consts `HEAL_LINE`, `INN_NIGHT_TIME`;
  - var `_shop_changed`;
  - funcs `_on_talk`, `_quest_npc`, `_on_npc`, `_talk_to_collector`, `_after_quest_talk`, `_done_text`, `_figure_with_quest`, `_on_shop`, `_on_inn`;
  - `_build_shop()`.
- Modify: `CLAUDE.md`

**Interfaces:**
- Consumes: `CaravanFlow.CARAVAN_CHIEF`, `CaravanFlow.choose_companion()` / `ask_departure()`, `StoryFlow.check_village_scene()`, `ZoneTravel.respawn_groups()` / `spawn_rare()`, `AutoplayStarts.AUTOPLAY_INN_RATIO` / `rested_for_boss()`.
- Produces:

```gdscript
class_name FigureTalk extends Node
var update_boss: Callable          # update_boss.call()
var choose_companion: Callable     # await choose_companion.call()
var ask_departure: Callable        # await ask_departure.call()
var check_village_scene: Callable  # check_village_scene.call()
var respawn_groups: Callable       # respawn_groups.call()
var spawn_rare: Callable           # spawn_rare.call()
func setup(ctx: SessionContext, shop: ShopWindow) -> void
func on_talk() -> void                  # awaitable
func on_npc(index: int) -> void         # awaitable
func talk_to_collector() -> void        # awaitable
func on_shop(shop_id: String) -> void   # awaitable
func on_inn(inn_id: String) -> void     # awaitable
```

- [ ] **Step 1: Create `scripts/game/figure_talk.gd`**

```gdscript
class_name FigureTalk extends Node
## Node, a piece of Game: what the figures and the things of the map do when the hero uses
## them. The Abuela Rosa heals and moves the village quest on (on_talk()); a villager, a
## board or a thing picked up says what the QuestLog has about a quest, or its chapter lines
## (on_npc(); the Coleccionista: talk_to_collector(); the Jefe de caravana: CaravanFlow); a
## shop opens the ShopWindow (on_shop()) and an inn offers the free night (on_inn()), each
## after the quest waiting at its figure; a well, a chest, the lever, the key and a gate.
## Gets the session and the ShopWindow in setup(); never stores Game or a World.

const HEAL_LINE := "Descansas un momento. PV y PM recuperados."
## Seconds of black while the hero sleeps at the inn.
const INN_NIGHT_TIME := 0.8

## update_boss.call(): shows or hides the zone's boss (BattleFlow).
var update_boss: Callable
## await choose_companion.call(): the Jefe de caravana's choice (CaravanFlow).
var choose_companion: Callable
## await ask_departure.call(): the Jefe's questions in Villaclaro (CaravanFlow).
var ask_departure: Callable
## check_village_scene.call(): the village's first-visit cutscene (StoryFlow).
var check_village_scene: Callable
## respawn_groups.call(): every group of the map back (ZoneTravel).
var respawn_groups: Callable
## spawn_rare.call(): the Slime de Metal on this floor if due (ZoneTravel).
var spawn_rare: Callable

var _ctx: SessionContext
var _shop: ShopWindow
## Something was bought, sold or equipped since the shop opened.
var _shop_changed := false


func setup(ctx: SessionContext, shop: ShopWindow) -> void:
	_ctx = ctx
	_shop = shop
	_shop.changed.connect(func() -> void:
		_shop_changed = true
		_ctx.refresh_status.call())
```

1. Cut from `game.gd` into `move.gd`, with their comments: `_on_talk`, `_quest_npc`, `_on_npc`, `_talk_to_collector`, `_after_quest_talk`, `_done_text`, `_figure_with_quest`, `_on_shop`, `_on_inn`.
2. Delete from `game.gd`: `const HEAL_LINE`; `const INN_NIGHT_TIME` and its comment; `var _shop_changed` and its comment.
3. Run the global perl, then:

```bash
perl -pi -e 's/(?<![.\w])_(on_talk|on_npc|talk_to_collector|on_shop|on_inn)\b/$1/g; s/(?<![.\w])_update_boss\(\)/update_boss.call()/g; s/(?<![.\w])_caravan\.choose_companion\(\)/choose_companion.call()/g; s/(?<![.\w])_caravan\.ask_departure\(\)/ask_departure.call()/g; s/(?<![.\w])_story\.check_village_scene\(\)/check_village_scene.call()/g; s/(?<![.\w])_travel\.respawn_groups\(\)/respawn_groups.call()/g; s/(?<![.\w])_travel\.spawn_rare\(\)/spawn_rare.call()/g' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/move.gd
grep -nP '(?<![.\w])(_caravan|_story|_travel|_world|_zone|_update_boss)\b' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/move.gd
```

Expected: the `grep` prints nothing.

In `on_inn()`, the line that computes `hurt` now reads `AutoplayStarts.AUTOPLAY_INN_RATIO` and `AutoplayStarts.rested_for_boss(_ctx.state.hero)`. Append `move.gd` to `figure_talk.gd`.

- [ ] **Step 2: The owner's side**

1. Add `var _talk: FigureTalk` after `var _caravan: CaravanFlow`.
2. In `_make_pieces()`, add `_talk = FigureTalk.new()`.
3. In `_build_shop()`, delete the `_shop.changed.connect(...)` lambda (its three lines). `FigureTalk.setup()` connects it now.
4. In `_add_pieces()`, append:

```gdscript
	_talk.setup(_ctx, _shop)
	_talk.update_boss = _update_boss
	_talk.choose_companion = _caravan.choose_companion
	_talk.ask_departure = _caravan.ask_departure
	_talk.check_village_scene = _story.check_village_scene
	_talk.respawn_groups = _travel.respawn_groups
	_talk.spawn_rare = _travel.spawn_rare
	add_child(_talk)
```

5. In `_on_world_replaced()`, connect to the piece:

```gdscript
	world.talk_requested.connect(_talk.on_talk)
	world.npc_requested.connect(_talk.on_npc)
	world.shop_requested.connect(_talk.on_shop)
	world.inn_requested.connect(_talk.on_inn)
```

6. Point the rest of `Game` (`_autoplay_restock`, `_finish_medal_tour`) to the piece:

```bash
cd /c/Users/peixe/Documents/rpg-turnos && perl -pi -e 's/(?<![.\w])_on_inn\(/_talk.on_inn(/g; s/(?<![.\w])_on_shop\(/_talk.on_shop(/g; s/(?<![.\w])_on_npc\(/_talk.on_npc(/g; s/(?<![.\w])_talk_to_collector\(\)/_talk.talk_to_collector()/g' scripts/game/game.gd
grep -nP '(?<![.\w])(_on_talk|_quest_npc|_on_npc|_talk_to_collector|_after_quest_talk|_done_text|_figure_with_quest|_on_shop|_on_inn|_shop_changed|HEAL_LINE|INN_NIGHT_TIME)\b' scripts/game/game.gd
```

Expected: the `grep` prints nothing.

- [ ] **Step 3: Import and validate**

Validate `res://scripts/game/figure_talk.gd` and `res://scripts/game/game.gd`. Expected: no errors.

- [ ] **Step 4: Runs**

```bash
for r in v1 caravana60 medallas; do echo "### $r"; bash C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/check.sh $r; done
grep -cE '^Misión cumplida' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/new/v1.log C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/v1.log
```

Expected:

- each run: no errors and an empty diff;
- `medallas`: `12/12 · premios 5/5`, which proves the Coleccionista;
- the `Misión cumplida` counts are close, within one or two (side quests vary).

Then open the shop once in a window:

```bash
cd /c/Users/peixe/Documents/rpg-turnos && APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --path . --write-movie C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/new/shop/f.png --fixed-fps 10 --quit-after 900 -- --autoplay
```

Look at the frames around the first `Comprar` the autoplay makes (the merchant of Villaclaro). The window shows "¿Comprar o vender?" and the buy page as before. Delete `C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/new/shop` afterwards.

- [ ] **Step 5: `CLAUDE.md`**

```bash
cd /c/Users/peixe/Documents/rpg-turnos && perl -pi -e 's/`_on_shop\(/`FigureTalk.on_shop(/g; s/`_on_inn\(/`FigureTalk.on_inn(/g; s/`_talk_to_collector\(/`FigureTalk.talk_to_collector(/g; s/`_after_quest_talk\(/`FigureTalk._after_quest_talk(/g; s/`_done_text\(/`FigureTalk._done_text(/g; s/`_figure_with_quest\(/`FigureTalk._figure_with_quest(/g; s/`INN_NIGHT_TIME`/`FigureTalk.INN_NIGHT_TIME`/g' CLAUDE.md
```

Insert after the `CaravanFlow` entry:

```markdown
- `scripts/game/figure_talk.gd` (`FigureTalk`, `Node`, a piece of `Game`, M-70) — what the figures do when used: `on_talk()` (the Abuela Rosa: `HEAL_LINE`, the village quest, her potions), `on_npc(index)` (the QuestLog first, else the chapter lines; the Coleccionista through `talk_to_collector()`, the Jefe de caravana through `choose_companion` / `ask_departure`), `_after_quest_talk(done)` and `_done_text(done)` (one notice for every quest delivered; the seeds used at once on autoplay), `_figure_with_quest(kind, id)`, `on_shop(shop_id)` (the `ShopWindow` given in `setup()`, autosaving when `changed`) and `on_inn(inn_id)` (the keeper's line, the free night, `INN_NIGHT_TIME`). Callables `update_boss`, `choose_companion`, `ask_departure`, `check_village_scene`, `respawn_groups`, `spawn_rare`.
```

At the end of the `Game` entry, append: ` Talking, shops, inns and the Coleccionista are in FigureTalk.`

- [ ] **Step 6: Commit**

```bash
cd /c/Users/peixe/Documents/rpg-turnos && git add scripts/game/figure_talk.gd scripts/game/game.gd CLAUDE.md && git commit -m "Move talking, shops, inns and the Coleccionista from Game to FigureTalk"
```

---

### Task 9: `FigureTalk` (2 of 2: wells, chests, lever, key, gate)

**Files:**
- Modify: `scripts/game/figure_talk.gd`
- Modify: `scripts/game/game.gd` (consts `LEVER_NOTICE`, `KEY_NOTICE`, `DOOR_NOTICE`; funcs `_on_well`, `_on_chest`, `_on_lever`, `_on_key`, `_on_door`)
- Modify: `CLAUDE.md`

**Interfaces:**
- Produces:

```gdscript
func on_well(id: String, kind: String) -> void   # awaitable
func on_chest(chest_id: String) -> void          # awaitable
func on_lever() -> void
func on_key() -> void
func on_door() -> void
```

- [ ] **Step 1: Move them**

1. Cut from `game.gd` into `move.gd`, with their comments: `_on_well`, `_on_chest`, `_on_lever`, `_on_key`, `_on_door`.
2. Move `LEVER_NOTICE`, `KEY_NOTICE` and `DOOR_NOTICE` from `game.gd` into `figure_talk.gd`, under `INN_NIGHT_TIME`, with their texts unchanged.
3. Run the global perl, then:

```bash
perl -pi -e 's/(?<![.\w])_(on_well|on_chest|on_lever|on_key|on_door)\b/$1/g' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/move.gd
```

4. Append `move.gd` to `figure_talk.gd`.

- [ ] **Step 2: The owner's side**

In `_on_world_replaced()`:

```gdscript
	world.chest_opened.connect(_talk.on_chest)
	world.well_requested.connect(_talk.on_well)
	world.lever_pulled.connect(_talk.on_lever)
	world.key_taken.connect(_talk.on_key)
	world.door_used.connect(_talk.on_door)
```

```bash
cd /c/Users/peixe/Documents/rpg-turnos && grep -nP '(?<![.\w])(_on_well|_on_chest|_on_lever|_on_key|_on_door|LEVER_NOTICE|KEY_NOTICE|DOOR_NOTICE)\b' scripts/game/game.gd
```

Expected: no output.

- [ ] **Step 3: Import and validate**

Validate `res://scripts/game/figure_talk.gd` and `res://scripts/game/game.gd`. Expected: no errors.

- [ ] **Step 4: Runs**

```bash
for r in v1 mina_1 jungla; do echo "### $r"; bash C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/check.sh $r; done
grep -cE '¡Tiras de la palanca|Encuentras la Llave de la mina|Abres la reja con la' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/new/mina_1.log
```

Expected:

- each run: no errors and an empty diff;
- the count is `3` or more: the lever, the key and the gate notices are printed on autoplay.

- [ ] **Step 5: `CLAUDE.md`**

In the `FigureTalk` entry, before ` Callables`, add: `on_well(id, kind)` (`Wells.drink()`), `on_chest(chest_id)`, `on_lever()`, `on_key()` and `on_door()` (`LEVER_NOTICE`, `KEY_NOTICE`, `DOOR_NOTICE`, each with a silent autosave);. At the end of the `Game` entry, change ` Talking, shops, inns and the Coleccionista are in FigureTalk.` to ` Talking, shops, inns, the Coleccionista, wells, chests, the lever, the key and the gates are in FigureTalk.`

- [ ] **Step 6: Commit**

```bash
cd /c/Users/peixe/Documents/rpg-turnos && git add scripts/game/figure_talk.gd scripts/game/game.gd CLAUDE.md && git commit -m "Move wells, chests, the lever, the key and the gates from Game to FigureTalk"
```

---

### Task 10: `GameAutoplay`

**Files:**
- Create: `scripts/game/game_autoplay.gd`
- Modify: `scripts/game/game.gd`
  - vars `_quiet_s`, `_autoplay_companion`, `_autoplay_v2`, `_defeats`, `_autoplay_echo`, `_echo_fights`, `_echo_wins`, `_medal_tour`, `_common_beaten`, `_last_missions`, `_last_gear_text`, and `_autoplay` / `_autoplay_save` / `_autoplay_menu` if plan 1 kept them;
  - funcs `_apply_autoplay_zone`, `_autoplay_retreat`, `_wants_retreat`, `_needs_groups`, `_autoplay_hunts`, `_boss_needs_rest`, `_autoplay_restock`, `_on_medal_tour_timeout`, `_finish_medal_tour`, `_on_zone_switched`, `_on_portal_taken`, `_on_game_completed`, `_on_v2_completed`;
  - the autoplay parts of `_process()`, `_ready()`, `_on_encounter()` and `_refresh_status()`.
- Modify: `CLAUDE.md`

**Interfaces:**
- Consumes: `ZoneTravel` (`switch_zone`, `respawn_groups`, `on_travel_requested`, `on_portal`), `FigureTalk` (`on_inn`, `on_shop`, `on_npc`, `talk_to_collector`), `BattleRewards.boss_wanted()`, `AutoplayStarts`, `CreditsData.clock()`.
- Produces:

```gdscript
class_name GameAutoplay extends Node
signal quit_requested
var echo := false
var plays_v2 := false
var medal_tour := false
var companion := AutoplayStarts.DEFAULT_COMPANION
func setup(ctx: SessionContext) -> void
func use_pieces(travel: ZoneTravel, talk: FigureTalk) -> void
func apply_start() -> void
func step(delta: float) -> void
func reset_quiet() -> void
func after_battle(outcome: int) -> void          # awaitable
func on_zone_switched(zone_id: String) -> void
func on_enemies_beaten(enemies: Array[Combatant], medals_won: int) -> void
func on_battle_lost(zone_id: String) -> void
func on_echo_fought(won: bool) -> void
func note_status(missions: Array[String]) -> void
func print_game_completed(time_text: String) -> void
func print_v2_completed(numbers: Dictionary) -> void
func start_medal_tour() -> void
func hunts() -> bool
func wants_retreat() -> bool
func needs_groups() -> bool
func boss_needs_rest() -> bool
func retreat() -> void                            # awaitable
func restock() -> void                            # awaitable
func finish_medal_tour() -> void                  # awaitable
```

- [ ] **Step 1: Create `scripts/game/game_autoplay.gd`: skeleton and the functions written in full**

```gdscript
class_name GameAutoplay extends Node
## Node, a piece of Game, only with --autoplay: the self-playing run. Starts a new game in
## the zone of --autoplay-zone=<id> with AutoplayStarts' state (apply_start()) and plays it
## as a player would: after a won battle it flies back to the last village with an Ala de
## viaje when the hero needs rest, is too worn for the boss, has a report waiting or has no
## group left (retreat(): the inn, the shop and the figures with a mark, restock(), then the
## portal back); after a defeat it restocks; an empty map, or one quiet for
## AutoplayStarts.AUTOPLAY_STALL_S, gets its groups back (step()); and it runs the medal tour
## of --autoplay-zone=medallas. It prints what a reader of the log follows: each zone, each
## change of mission line, gold or gear, each defeat, the Eco's results and the numbers after
## the credits. Uses only the public functions of ZoneTravel and FigureTalk (use_pieces())
## and the rules; never stores Game or a World.

## The medal tour is over: Game goes back to the title (which quits on autoplay).
signal quit_requested

## --autoplay-zone=eco: BattleFlow brings out the Eco de la Niebla (Game passes it on).
var echo := false
## A start of AutoplayStarts.V2_STARTS: CaravanFlow leaves with the caravan (Game passes it on).
var plays_v2 := false
## --autoplay-zone=medallas: the tour is on.
var medal_tour := false
## --autoplay-companion=<id> (AutoplayStarts.companion()).
var companion := AutoplayStarts.DEFAULT_COMPANION

var _ctx: SessionContext
var _travel: ZoneTravel
var _talk: FigureTalk
## Seconds since the last battle or change of map (AutoplayStarts.AUTOPLAY_STALL_S).
var _quiet_s := 0.0
## Defeats so far (each prints "Derrota en <zone> (n)"; the credits say the total).
var _defeats := 0
## --autoplay-zone=eco: fights with the Eco and how many were won, printed after each.
var _echo_fights := 0
var _echo_wins := 0
## Common enemies beaten in won battles (the credits print it with the medals, to tune
## Medals.DROP_CHANCE).
var _common_beaten := 0
var _last_missions: Array[String] = []
var _last_gear_text := ""


func setup(ctx: SessionContext) -> void:
	_ctx = ctx
	companion = AutoplayStarts.companion()


func use_pieces(travel: ZoneTravel, talk: FigureTalk) -> void:
	_travel = travel
	_talk = talk


## --autoplay-zone=<id>: starts the new game in that zone with AutoplayStarts.AUTOPLAY_ZONES'
## state. Called by Game before the first map is built.
func apply_start() -> void:
	var start_id := RunFlags.autoplay_zone()
	if start_id == "":
		return
	var state := _ctx.state
	var start: Dictionary = AutoplayStarts.AUTOPLAY_ZONES.get(start_id, {})
	var zone_id: String = start.get("zone", start_id)
	if not zone_id in ZoneData.IDS:
		push_error("Unknown zone for --autoplay-zone: %s" % start_id)
		return
	state.zone_id = zone_id
	if start.is_empty():
		return
	state.hero.experience = start.experience
	Leveling.apply(state.hero)
	state.heal_full()
	state.gold = start.gold
	for id: String in start.gear:
		state.bag_equipment.append(id)
		state.equip(id)
	for flag: String in start.flags:
		state.world_flags[flag] = true
		if Bestiary.has(flag):
			# A boss of the flags was beaten on the way: the bestiary says so too.
			state.defeat_enemy(flag)
	for id: String in start.get("key_items", []):
		state.key_items.append(id)
	state.town_zone = start.get("town", state.town_zone)
	if start.quest_done:
		state.quest.stage = Quest.Stage.DONE
	# The v2's level cap needs the "caravana" flag, set just above: levels again.
	# (the first pass at the v1 cap clamped the EXP: give it back).
	state.sync_level_cap()
	state.hero.experience = start.experience
	Leveling.apply(state.hero)
	state.heal_full()
	state.ally_id = start.get("ally", "")
	if Allies.is_companion(state.ally_id):
		state.ally_id = companion
	var items: Dictionary = start.get("items", {})
	for id: String in items:
		state.inventory.add(id, items[id])
	echo = start_id == AutoplayStarts.ECHO_START
	plays_v2 = start_id in AutoplayStarts.V2_STARTS
	medal_tour = start_id == AutoplayStarts.MEDAL_TOUR
	state.story.mark_seen_for_flags(state.world_flags)
	if start.get("finished", false):
		state.story.finished = true
	state.sync_level_cap()
	print("Zona de inicio: %s (Nv %d)" % [zone_id, state.hero.level])


## Every frame (Game._process(), after the play time): away from a village and with nothing
## going on, a map quiet for AUTOPLAY_STALL_S gets its groups back while the hero still has
## levels to win; at the boss's level but too worn for it, one Ala is made here.
func step(delta: float) -> void:
	if _ctx.busy or _ctx.world == null or _ctx.world.in_village():
		return
	_quiet_s += delta
	if _quiet_s > AutoplayStarts.AUTOPLAY_STALL_S and hunts():
		_quiet_s = 0.0
		print("Grupos repuestos (partida automática, sin combates)")
		_travel.respawn_groups()
	elif _quiet_s > AutoplayStarts.AUTOPLAY_STALL_S and boss_needs_rest() \
			and _ctx.state.inventory.count(Inventory.WING) > 0:
		# At the boss's level but too worn for it, with no battle coming that would bring
		# the retreat: one Ala, made here (the quiet clock starts over).
		_quiet_s = 0.0
		retreat()


## A battle started, a map was built or the portal was taken: the quiet clock starts over.
func reset_quiet() -> void:
	_quiet_s = 0.0


## What follows a battle once the map is the player's again (BattleFlow awaits it): the end
## of the medal tour, the retreat, the groups back, or a restock after a defeat.
func after_battle(outcome: int) -> void:
	var won := outcome == BattleEngine.State.WON
	if medal_tour and won and _ctx.state.medals.size() >= Medals.MEDALS.size():
		await finish_medal_tour()
		return
	if won and wants_retreat():
		await retreat()
	elif won and needs_groups():
		# No Ala de viaje (or in a village): the groups come back as if it had flown away
		# and back. Only the autoplay does this.
		print("Grupos repuestos (partida automática)")
		_travel.respawn_groups()
	elif outcome == BattleEngine.State.LOST:
		await restock()


## A map was built (ZoneTravel.zone_switched): the zone, the level and the play time.
func on_zone_switched(zone_id: String) -> void:
	_quiet_s = 0.0
	print("Zona: %s (Nv %d, %s)" % [zone_id, _ctx.state.hero.level,
		CreditsData.clock(_ctx.play_time)])


## A won battle: the common enemies beaten and the medals carried.
func on_enemies_beaten(enemies: Array[Combatant], medals_won: int) -> void:
	for enemy in enemies:
		if not enemy.is_boss:
			_common_beaten += 1
	if medals_won > 0:
		print("Medalla: %d/%d" % [_ctx.state.medals.size(), Medals.MEDALS.size()])


## A lost battle, before the hero goes back to the village.
func on_battle_lost(zone_id: String) -> void:
	_defeats += 1
	print("Derrota en %s (%d)" % [zone_id, _defeats])


## A battle with the Eco de la Niebla is over.
func on_echo_fought(won: bool) -> void:
	_echo_fights += 1
	_echo_wins += 1 if won else 0
	print("Eco de la Niebla: %s (%d de %d ganados)" % ["victoria" if won else "derrota",
		_echo_wins, _echo_fights])


## Each new mission line and each change of gold or equipment (Game._refresh_status()).
func note_status(missions: Array[String]) -> void:
	if missions != _last_missions:
		print(" · ".join(missions))
	_last_missions = missions
	var state := _ctx.state
	var loadout := state.loadout
	var worn := PackedStringArray()
	for slot in Equipment.SLOTS:
		if loadout.worn(slot) != "":
			worn.append(Equipment.display_name(loadout.worn(slot)))
	var gear_text := "Oro %d G · Equipo: %s · ATK %d DEF %d VEL %d" % [state.gold,
		", ".join(worn), state.hero.total_attack(), state.hero.total_defense(),
		state.hero.total_speed()]
	if gear_text != _last_gear_text:
		print(gear_text)
	_last_gear_text = gear_text
```

Check `print_game_completed` and `print_v2_completed` against `Game._on_game_completed()` / `_on_v2_completed()`, which are deleted in Step 3. Their print lines are the same, with `state.` → `_ctx.state.` and `_ctx.play_time` unchanged:

```gdscript


## The numbers of the whole run after the v1's credits (StoryFlow.game_completed).
func print_game_completed(time_text: String) -> void:
	var state := _ctx.state
	print("Juego completado: Nv %d, tiempo de juego %s, misiones %d" % [state.hero.level,
		time_text, state.quests_done()])
	print("Familias completas: %d/%d" % [Bestiary.complete_count(state),
		Bestiary.families(state).size()])
	print("Derrotas: %d" % _defeats)
	print("Medallas: %d/%d (enemigos comunes vencidos: %d)" % [state.medals.size(),
		Medals.MEDALS.size(), _common_beaten])


## The numbers of the v2 after its credits (StoryFlow.v2_completed).
func print_v2_completed(numbers: Dictionary) -> void:
	var state := _ctx.state
	print("Juego completado (v2): Nv %d, tiempo en la caravana %s, tiempo de juego %s, misiones de la caravana %d/%d"
		% [state.hero.level, numbers.time, CreditsData.clock(_ctx.play_time),
		state.quests.done_of(true), QuestLog.total_of(true)])
	print("Familias completas: %d/%d" % [Bestiary.complete_count(state),
		Bestiary.families(state).size()])
	print("Derrotas: %d" % _defeats)
	print("Medallas: %d/%d (enemigos comunes vencidos: %d)" % [state.medals.size(),
		Medals.MEDALS.size(), _common_beaten])


## --autoplay-zone=medallas, once the map is the player's: says where it hunts and sets the
## time limit (AutoplayStarts.MEDAL_TOUR_TIME).
func start_medal_tour() -> void:
	if not medal_tour:
		return
	print("Medallas: a cazar en %s" % _ctx.zone.id)
	get_tree().create_timer(AutoplayStarts.MEDAL_TOUR_TIME).timeout.connect(
		_on_medal_tour_timeout)
```

- [ ] **Step 2: Move the rest verbatim**

Cut from `game.gd` into `move.gd`, with their comments: `_autoplay_retreat`, `_wants_retreat`, `_needs_groups`, `_autoplay_hunts`, `_boss_needs_rest`, `_autoplay_restock`, `_on_medal_tour_timeout`, `_finish_medal_tour`. Run the global perl, then:

```bash
perl -pi -e 's/(?<![.\w])_autoplay_retreat\b/retreat/g; s/(?<![.\w])_autoplay_restock\b/restock/g; s/(?<![.\w])_autoplay_hunts\b/hunts/g; s/(?<![.\w])_(wants_retreat|needs_groups|boss_needs_rest|finish_medal_tour)\b/$1/g; s/(?<![.\w])_medal_tour\b/medal_tour/g; s/(?<![.\w])_boss_wanted\(\)/BattleRewards.boss_wanted(_ctx.zone, _ctx.state, echo)/g; s/(?<![.\w])quit_to_title\.emit\(\)/quit_requested.emit()/g' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/move.gd
grep -nP '(?<![.\w])(_autoplay\w*|_medal_tour|_boss_wanted|_world|_zone|quit_to_title)\b' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/move.gd
```

Expected: the `grep` prints nothing.

On autoplay, `Game._boss_wanted()` passed `not RunFlags.autoplay() or _autoplay_echo`, which is `echo`. `restock()` calls `_talk.on_inn/on_shop/on_npc`, and `retreat()` calls `_travel.on_travel_requested()` / `_travel.on_portal()`. Append `move.gd` to `game_autoplay.gd`.

- [ ] **Step 3: The owner's side**

1. **Members.** Delete the vars `_quiet_s`, `_autoplay_companion`, `_autoplay_v2`, `_defeats`, `_autoplay_echo`, `_echo_fights`, `_echo_wins`, `_medal_tour`, `_common_beaten`, `_last_missions` and `_last_gear_text`, with their comments. Delete the funcs `_on_zone_switched`, `_on_portal_taken`, `_on_game_completed` and `_on_v2_completed`. Add `var _autopilot: GameAutoplay` with the comment `## The self-playing run, only with --autoplay (null otherwise).`
2. **Plan 1's bools.** If `game.gd` still has `var _autoplay`, `var _autoplay_save` or `var _autoplay_menu`, delete them and the lines in `_ready()` that set them, then:

```bash
cd /c/Users/peixe/Documents/rpg-turnos && perl -pi -e 's/(?<![.\w])_autoplay_save\b/(RunFlags.autoplay() and RunFlags.autoplay_save())/g; s/(?<![.\w])_autoplay_menu\b/(RunFlags.autoplay() and RunFlags.autoplay_menu())/g; s/(?<![.\w])_autoplay\b/RunFlags.autoplay()/g' scripts/game/game.gd
```

3. **`_make_pieces()`**, append:

```gdscript
	if RunFlags.autoplay():
		_autopilot = GameAutoplay.new()
		_autopilot.setup(_ctx)
```

4. **`_ready()`:**
   - Replace the line that calls `_apply_autoplay_zone(...)` (under `if _save.is_empty() and ...autoplay...:`) with:

```gdscript
	if _save.is_empty() and _autopilot:
		_autopilot.apply_start()
```

   - Replace the last block, the one starting `if _medal_tour:` (its two lines `print("Medallas: a cazar en ...")` and the `MEDAL_TOUR_TIME` timer), with:

```gdscript
		if _autopilot:
			_autopilot.start_medal_tour()
```

   - The `_autoplay_companion = AutoplayStarts.companion()` line of Task 3 goes: `GameAutoplay.setup()` does it.

5. **`_process()`**, the whole body becomes:

```gdscript
func _process(delta: float) -> void:
	_ctx.play_time += delta / Engine.time_scale  # a fast battle takes less play time, not more
	if _autopilot:
		_autopilot.step(delta)
```

6. **`_add_pieces()`:**
   - Delete the lines `_travel.zone_switched.connect(_on_zone_switched)`, `_travel.portal_taken.connect(_on_portal_taken)`, `_story.game_completed.connect(_on_game_completed)`, `_story.v2_completed.connect(_on_v2_completed)`, `_caravan.autoplay_companion = _autoplay_companion` and `_caravan.autoplay_leaves = _autoplay_v2`.
   - Append:

```gdscript
	if _autopilot:
		_autopilot.use_pieces(_travel, _talk)
		_travel.zone_switched.connect(_autopilot.on_zone_switched)
		_travel.portal_taken.connect(_autopilot.reset_quiet)
		_story.game_completed.connect(_autopilot.print_game_completed)
		_story.v2_completed.connect(_autopilot.print_v2_completed)
		_autopilot.quit_requested.connect(func() -> void: quit_to_title.emit())
		_caravan.autoplay_companion = _autopilot.companion
		_caravan.autoplay_leaves = _autopilot.plays_v2
		add_child(_autopilot)
```

7. **`_on_encounter()`** (still in `Game`; `BattleFlow` takes it in Task 11):
   - `	_quiet_s = 0.0` → `	if _autopilot:` + `		_autopilot.reset_quiet()`.
   - The block `if ... and echo:` with `_echo_fights += 1` … `print("Eco de la Niebla: ...")` → `	if _autopilot and echo:` + `		_autopilot.on_echo_fought(won)`.
   - In the won block, the block `if ...autoplay...:` that counts `_common_beaten` and prints `Medalla:` → `		if _autopilot:` + `			_autopilot.on_enemies_beaten(battle.engine.enemies, battle.engine.medals_won)`.
   - In the lost block, the block `if ...autoplay...:` with `_defeats += 1` and `print("Derrota en ...")` → `		if _autopilot:` + `			_autopilot.on_battle_lost(_ctx.zone.id)`.
   - `battle.medal_chance = AutoplayStarts.MEDAL_TOUR_CHANCE if _medal_tour else Medals.DROP_CHANCE` → `battle.medal_chance = AutoplayStarts.MEDAL_TOUR_CHANCE if _autopilot and _autopilot.medal_tour else Medals.DROP_CHANCE`.
   - Everything after `	_set_busy(false)` at its end (the medal tour, the retreat, the groups, the restock) becomes:

```gdscript
	if _autopilot:
		await _autopilot.after_battle(outcome)
```

8. **`_boss_wanted()`** becomes `return BattleRewards.boss_wanted(_ctx.zone, state, not RunFlags.autoplay() or (_autopilot != null and _autopilot.echo))`.

9. **`_refresh_status()`:**
   - `_ctx.world.set_autoplay_hunt(...)` becomes `_ctx.world.set_autoplay_hunt(_autopilot != null and _autopilot.hunts())`.
   - Everything after `_ctx.world.set_hero_equipment(...)` (the mission print, `_last_missions`, the gear text and its print) becomes:

```gdscript
	if _autopilot:
		_autopilot.note_status(missions)
```

10. **Leftovers and empty regions:**

```bash
cd /c/Users/peixe/Documents/rpg-turnos && grep -nP '(?<![.\w])(_quiet_s|_autoplay\w*|_defeats|_echo_\w+|_medal_tour|_common_beaten|_last_missions|_last_gear_text|_wants_retreat|_needs_groups|_boss_needs_rest|_finish_medal_tour|_on_medal_tour_timeout|_on_zone_switched|_on_portal_taken|_on_game_completed|_on_v2_completed|_apply_autoplay_zone)\b' scripts/game/game.gd
grep -n '#region\|#endregion' scripts/game/game.gd
```

Expected: the first `grep` prints nothing. Delete any `#region` / `#endregion` pair the second shows with nothing left between them.

- [ ] **Step 4: Import and validate**

Validate `res://scripts/game/game_autoplay.gd` and `res://scripts/game/game.gd`. Expected: no errors.

- [ ] **Step 5: Runs, every start once**

```bash
for r in v1 save medallas eco bosque mina_1 mina_3 castillo_patio castillo_trono jungla desierto montana portal ciudad caravana60; do echo "### $r"; bash C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/check.sh $r; done
grep -cE '^(Retirada al pueblo|Grupos repuestos)' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/new/v1.log C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/v1.log
grep -c '^Oro ' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/new/v1.log C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/v1.log
```

Expected:

- each run: no errors and an empty diff; `save` prints `1`; `medallas` ends `12/12 · premios 5/5`; `eco` has a victory;
- the retreat and refill counts are of the same order (both above 0);
- the `Oro` counts are of the same order.

A game without autoplay must not print anything of the autoplay:

```bash
cd /c/Users/peixe/Documents/rpg-turnos && APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --fixed-fps 10 --quit-after 300 res://scenes/game/game.tscn 2>&1 | grep -E '^(Zona|Oro|Grupos)|ERROR'
```

Expected: no output.

- [ ] **Step 6: `CLAUDE.md`**

```bash
cd /c/Users/peixe/Documents/rpg-turnos && perl -pi -e 's/`_autoplay_restock\(/`GameAutoplay.restock(/g; s/`_wants_retreat\(/`GameAutoplay.wants_retreat(/g; s/`_needs_groups\(/`GameAutoplay.needs_groups(/g; s/`_autoplay_hunts\(/`GameAutoplay.hunts(/g; s/`_boss_needs_rest\(/`GameAutoplay.boss_needs_rest(/g; s/`_autoplay_retreat\(/`GameAutoplay.retreat(/g; s/`_autoplay_v2`/`GameAutoplay.plays_v2`/g; s/`_common_beaten`/`GameAutoplay._common_beaten`/g' CLAUDE.md
```

Insert after the `FigureTalk` entry:

```markdown
- `scripts/game/game_autoplay.gd` (`GameAutoplay`, `Node`, a piece of `Game` only with `--autoplay`, M-70) — the self-playing run: `apply_start()` (the start of `--autoplay-zone=<id>` from `AutoplayStarts.AUTOPLAY_ZONES`, before the first map; sets `echo`, `plays_v2`, `medal_tour`), `step(delta)` (called by `Game._process()`: a quiet map's groups back, or a retreat for the boss), `after_battle(outcome)` (awaited by `BattleFlow`: the medal tour's end, `retreat()`, the groups back, `restock()` after a defeat), `wants_retreat()`, `needs_groups()`, `hunts()`, `boss_needs_rest()`, `start_medal_tour()` / `finish_medal_tour()`, and the prints a reader of the log follows (`on_zone_switched()` "Zona: ...", `note_status()` the missions, gold and gear, `on_battle_lost()` "Derrota en ...", `on_echo_fought()`, `on_enemies_beaten()` "Medalla: ...", `print_game_completed()` / `print_v2_completed()` after the credits). `companion` comes from `AutoplayStarts.companion()`. It is handed `ZoneTravel` and `FigureTalk` (`use_pieces()`) and uses only their public functions.
```

At the end of the `Game` entry, append: ` The self-playing run is in GameAutoplay; Game only calls step() and passes echo, plays_v2 and companion on.`

- [ ] **Step 7: Commit**

```bash
cd /c/Users/peixe/Documents/rpg-turnos && git add scripts/game/game_autoplay.gd scripts/game/game.gd CLAUDE.md && git commit -m "Move the self-playing run from Game to GameAutoplay"
```

---

### Task 11: `BattleFlow`

**Files:**
- Create: `scripts/game/battle_flow.gd`
- Modify: `scripts/game/game.gd` (const `BATTLE_SCENE`; funcs `_on_encounter`, `_update_boss`, `_boss_id`, `_boss_wanted`)
- Modify: `CLAUDE.md`

**Interfaces:**
- Consumes: `BattleRewards`, `ZoneTravel.go_to_town()` / `to_place()`, `StoryFlow.play_scene()` / `finish_game()` / `finish_v2()`, `GameAutoplay.after_battle()` and its handlers, `CreditsData.summary()`, `AutoplayStarts.rested_for_boss()`.
- Produces:

```gdscript
class_name BattleFlow extends Node
signal battle_started
signal enemies_beaten(enemies: Array[Combatant], medals_won: int)
signal battle_lost(zone_id: String)
signal echo_fought(won: bool)
signal quit_requested
var echo_wanted := false
var medal_chance := Medals.DROP_CHANCE
var print_save := false
var play_scene: Callable     # await play_scene.call(scene_id)
var finish_game: Callable    # await finish_game.call()
var finish_v2: Callable      # await finish_v2.call()
var go_to_town: Callable     # go_to_town.call()
var after_battle: Callable   # await after_battle.call(outcome); not set without autoplay
func setup(ctx: SessionContext) -> void
func on_encounter(boss: bool) -> void   # awaitable
func update_boss() -> void
func boss_id() -> String
func boss_wanted() -> bool
```

- [ ] **Step 1: Create `scripts/game/battle_flow.gd`**

Compare `on_encounter()` line by line with `Game._on_encounter()` as left by Task 10. The only differences:

- the renames of the table;
- the autoplay calls become the signals `battle_started`, `echo_fought`, `enemies_beaten`, `battle_lost`;
- `await _autopilot.after_battle(outcome)` becomes `await after_battle.call(outcome)`;
- the `--autoplay-save` exit becomes `print_save` / `quit_requested`;
- the battle is added under this piece instead of under `Game`.

```gdscript
class_name BattleFlow extends Node
## Node, a piece of Game: a battle on top of the map. When the hero touches a group of
## monsters (World.contact_enemies(), its formation) or the zone's boss, it fades to black,
## puts a BattleScene over the frozen map and, once it is over, plays back what happened:
## a victory's rewards (BattleRewards.after_victory(): gold, medals, quests, a boss's flag,
## notice, cutscene and first prize, the families), a fled group left half see-through, a
## defeat's way back to the village with half the gold; then the boss's cutscene or its
## notice, the missions done, the ending when it is due, and the save. Also says whether the
## zone's boss is on the map (update_boss()). Gets the session in setup(); never stores Game
## or a World.

## A battle starts (on autoplay the quiet clock starts over).
signal battle_started
## A battle was won (on autoplay: the common enemies counted and the medals printed).
signal enemies_beaten(enemies: Array[Combatant], medals_won: int)
## A battle was lost, before the hero goes back to the village (on autoplay it is printed).
signal battle_lost(zone_id: String)
## A battle with the postgame boss (the Eco de la Niebla) is over.
signal echo_fought(won: bool)
## --autoplay-save: the first save after a won battle was printed; Game goes back to the title.
signal quit_requested

const BATTLE_SCENE := preload("res://scenes/battle/battle_scene.tscn")

## Autoplay meets the postgame boss (only --autoplay-zone=eco; Game sets it).
var echo_wanted := false
## The chance of a medal drop (AutoplayStarts.MEDAL_TOUR_CHANCE on the medal tour; Game sets it).
var medal_chance := Medals.DROP_CHANCE
## --autoplay-save on a new game: print the first save after a won battle and quit (Game sets it).
var print_save := false
## await play_scene.call(scene_id): a boss's cutscene (StoryFlow).
var play_scene: Callable
## await finish_game.call(): the v1's ending and credits (StoryFlow).
var finish_game: Callable
## await finish_v2.call(): the v2's ending and credits (StoryFlow).
var finish_v2: Callable
## go_to_town.call(): a beaten hero back to the last village (ZoneTravel).
var go_to_town: Callable
## await after_battle.call(outcome): the autoplay's next move (GameAutoplay); not set
## without autoplay.
var after_battle: Callable

var _ctx: SessionContext


func setup(ctx: SessionContext) -> void:
	_ctx = ctx


## The boss of the current map (BattleRewards.boss_id()).
func boss_id() -> String:
	return BattleRewards.boss_id(_ctx.zone, _ctx.state)


## The boss of the current map is due (BattleRewards.boss_wanted()); the postgame boss is,
## off autoplay, always; on autoplay only on --autoplay-zone=eco.
func boss_wanted() -> bool:
	return BattleRewards.boss_wanted(_ctx.zone, _ctx.state,
		not RunFlags.autoplay() or echo_wanted)


## The zone's boss is on the map until beaten: the Rey Slime only while the quest asks
## for it; on autoplay only from the zone's autoplay_boss_level on, and only while the
## hero has AutoplayStarts.AUTOPLAY_BOSS_HP of his max HP and AUTOPLAY_BOSS_MP of his max MP
## (a worn-out hero fights on, or rests, first).
func update_boss() -> void:
	if boss_id() == "":
		return
	var strong_enough := not RunFlags.autoplay() \
		or (_ctx.state.hero.level >= _ctx.zone.autoplay_boss_level \
		and AutoplayStarts.rested_for_boss(_ctx.state.hero))
	_ctx.world.set_boss_present(boss_wanted() and strong_enough)


## A group of monsters touched on the map, or the zone's boss (boss): the battle on top of
## the frozen map, then everything that follows it.
func on_encounter(boss: bool) -> void:
	if _ctx.busy:
		return
	_ctx.set_busy.call(true)
	battle_started.emit()
	_ctx.state.battles += 1
	var enemies: Array[Combatant] = []
	if boss:
		enemies.append(EnemyLibrary.data(boss_id()))
	else:
		enemies = _ctx.world.contact_enemies()
	if not boss:
		var kept := _ctx.state.give_metal_slime_hp(enemies)
		if RunFlags.autoplay() and kept > 0:
			print("Slime de Metal con PV %d" % kept)
	BattleRewards.note_enemies(_ctx.state, enemies, false)
	var echo := boss and boss_id() == _ctx.zone.postgame_boss_id
	await _ctx.fade.call(1.0)
	_ctx.world.set_active(false)
	_ctx.audio.play_music(MusicLibrary.BOSS if boss else MusicLibrary.BATTLE)
	_ctx.audio.stop_ambient()
	var battle: BattleScene = BATTLE_SCENE.instantiate()
	battle.setup(_ctx.state.hero, enemies, _ctx.state.inventory)
	battle.set_audio(_ctx.audio)
	battle.set_equipment(_ctx.state.loadout.worn(Equipment.WEAPON),
		_ctx.state.loadout.worn(Equipment.SHIELD), _ctx.state.loadout.worn(Equipment.HELMET))
	battle.gold_lost = _ctx.state.defeat_gold_loss()
	battle.char_time = _ctx.options.char_time()
	battle.time_scale = _ctx.options.combat_scale()
	battle.camera_shake = _ctx.options.camera_shake
	_ctx.state.sync_level_cap()
	battle.difficulty = _ctx.state.difficulty
	battle.zone = _ctx.zone
	battle.quest_items = _ctx.state.quests.wanted_items(_ctx.state)
	battle.medals_carried = _ctx.state.medals.size()
	battle.medal_chance = medal_chance
	if _ctx.state.ally_id != "":
		battle.ally = Allies.data(_ctx.state.ally_id, _ctx.state.tramo())
	add_child(battle)
	await _ctx.fade.call(0.0)
	var outcome: int = await battle.finished
	# A call for help adds enemies during the fight.
	BattleRewards.note_enemies(_ctx.state, battle.engine.enemies, false)
	var won := outcome == BattleEngine.State.WON
	if echo:
		echo_fought.emit(won)
	if won or outcome == BattleEngine.State.LOST:
		Wells.on_battle(_ctx.state)
		_ctx.world.set_dry_wells(Wells.dry_ids(_ctx.state))
	await _ctx.fade.call(1.0)
	if not boss:
		# Under black: a beaten group leaves the map, one fled from stays half see-through.
		_ctx.world.end_contact(outcome)
	if _ctx.state.keep_metal_slime_hp(battle.engine.enemies, outcome) > 0:
		if RunFlags.autoplay():
			print("Slime de Metal: PV %d guardados" % _ctx.state.metal_slime_hp)
		_ctx.autosave.call(false)  # a fled battle saves nothing else: quitting now must not lose them
	var notice := ""
	var reward_lines: Array[String] = []
	var scene := ""
	var mission_done := false
	var finished_quests: Array[Dictionary] = []
	var family_lines: Array[String] = []
	var ending_v2 := false
	if won:
		var rewards := BattleRewards.after_victory(_ctx.state, _ctx.zone,
			battle.engine.enemies, battle.engine.gold_won, battle.engine.medals_won, boss)
		notice = rewards.notice
		reward_lines.assign(rewards.reward_lines)
		scene = rewards.scene
		mission_done = rewards.mission_done
		finished_quests.assign(rewards.finished_quests)
		family_lines.assign(rewards.family_lines)
		ending_v2 = rewards.ending_v2
		enemies_beaten.emit(battle.engine.enemies, battle.engine.medals_won)
	elif outcome == BattleEngine.State.LOST:
		battle_lost.emit(_ctx.zone.id)
		_ctx.state.gold -= battle.gold_lost
		_ctx.state.heal_full()
		go_to_town.call()
		notice = "Has vuelto %s." % ZoneTravel.to_place(_ctx.zone.village_name)
	battle.queue_free()
	_ctx.world.set_world_flags(_ctx.state.world_flags)
	update_boss()
	_ctx.refresh_status.call()
	_ctx.world.set_active(true)
	# Frozen until the fade is over: an exit or an encounter while Game is busy would be
	# ignored and leave the map waiting forever.
	_ctx.world.freeze(true)
	_ctx.play_map_music.call()
	if scene != "":
		# Under black: no status window or map square while the map fades in.
		_ctx.world.begin_cutscene()
	await _ctx.fade.call(0.0)
	if scene != "":
		# The boss's cutscene says what the notice would (the fragment, the open road).
		await play_scene.call(scene)
	else:
		await _ctx.world.freeze(false)
		if not reward_lines.is_empty():
			await _ctx.world.show_dialogue("", reward_lines)
		elif notice != "":
			_ctx.world.show_notice(notice, "Premio", &"text-positive")
	if not family_lines.is_empty():
		_ctx.audio.play_sfx(SfxLibrary.LEVEL_UP)
		await _ctx.world.show_dialogue("", family_lines)
	if mission_done:
		_ctx.world.show_mission_done(QuestLog.done_text(Quest.TITLE))
	for finished: Dictionary in finished_quests:
		_ctx.world.show_mission_done(QuestLog.done_text(finished.title))
		_ctx.world.show_notice(" ".join(finished.lines), "Misión cumplida", &"text-positive")
	if ending_v2:
		await finish_v2.call()
		return
	if won and _ctx.state.is_finished() and not _ctx.state.story.finished:
		await finish_game.call()
		return
	if outcome == BattleEngine.State.LOST:
		_ctx.autosave.call(false)  # the gold lost sticks: going back to the title can't undo it
	if won:
		var data: Dictionary = _ctx.autosave.call(not boss and finished_quests.is_empty())  # keep its reward readable
		if print_save and not data.is_empty():
			print("Guardado: %s" % CreditsData.summary(data))
			quit_requested.emit()
			return
	_ctx.set_busy.call(false)
	if after_battle.is_valid():
		await after_battle.call(outcome)
```

- [ ] **Step 2: The owner's side**

1. **Delete** from `game.gd`: `const BATTLE_SCENE`, `_on_encounter`, `_update_boss`, `_boss_id`, `_boss_wanted`, with their comments.
2. **Member and creation.** Add `var _battle: BattleFlow` after `var _talk: FigureTalk`. In `_make_pieces()`, add `_battle = BattleFlow.new()` before the `if RunFlags.autoplay():` block.
3. **`_add_pieces()`:**
   - change `_travel.update_boss = _update_boss` to `_travel.update_boss = _battle.update_boss`;
   - change `_talk.update_boss = _update_boss` to `_talk.update_boss = _battle.update_boss`;
   - before the `if _autopilot:` block, add:

```gdscript
	_battle.setup(_ctx)
	_battle.play_scene = _story.play_scene
	_battle.finish_game = _story.finish_game
	_battle.finish_v2 = _story.finish_v2
	_battle.go_to_town = _travel.go_to_town
	_battle.print_save = RunFlags.autoplay() and RunFlags.autoplay_save() and _save.is_empty()
	_battle.quit_requested.connect(func() -> void: quit_to_title.emit())
	add_child(_battle)
```

   - inside the `if _autopilot:` block, before `add_child(_autopilot)`, add:

```gdscript
		_battle.echo_wanted = _autopilot.echo
		_battle.medal_chance = AutoplayStarts.MEDAL_TOUR_CHANCE if _autopilot.medal_tour \
			else Medals.DROP_CHANCE
		_battle.after_battle = _autopilot.after_battle
		_battle.battle_started.connect(_autopilot.reset_quiet)
		_battle.enemies_beaten.connect(_autopilot.on_enemies_beaten)
		_battle.battle_lost.connect(_autopilot.on_battle_lost)
		_battle.echo_fought.connect(_autopilot.on_echo_fought)
```

4. **`_on_world_replaced()`:** `world.encounter_triggered.connect(_battle.on_encounter)`.
5. **The rest of `Game`** (`_on_debug`):

```bash
cd /c/Users/peixe/Documents/rpg-turnos && perl -pi -e 's/(?<![.\w])_update_boss\(\)/_battle.update_boss()/g' scripts/game/game.gd
grep -nP '(?<![.\w])(_on_encounter|_update_boss|_boss_id|_boss_wanted|BATTLE_SCENE)\b' scripts/game/game.gd
```

Expected: the `grep` prints nothing.

**Why the battle now hangs under `BattleFlow`:** the battle is in the tree after the fade, pause and debug layers, as before, because `_add_pieces()` runs after them. So the input order does not change.

- [ ] **Step 3: Import and validate**

Validate `res://scripts/game/battle_flow.gd` and `res://scripts/game/game.gd`. Expected: no errors.

- [ ] **Step 4: Runs**

```bash
for r in save v1 eco ciudad portal mina_1; do echo "### $r"; bash C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/check.sh $r; done
grep -cE 'Slime de Metal' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/new/v1.log C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/v1.log
grep -m1 'El ojo del Devorador se abre' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/new/portal.log
```

Expected:

- each run: no errors and an empty diff; `save` prints `1`; `eco` has a victory and one `Entre la bruma brilla algo.`;
- `ciudad` and `portal` reach `Juego completado (v2)`;
- the Slime de Metal lines appear in both logs, with counts of the same order;
- the Devorador's second phase line is printed.

Then a battle in a window, checked by eye:

```bash
cd /c/Users/peixe/Documents/rpg-turnos && APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --path . --write-movie C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/new/battle/f.png --fixed-fps 10 --quit-after 600 -- --autoplay
```

The frames of the first battle show the stage, the hero and the enemies, the menu, then the victory card and the map coming back. Delete `C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/new/battle` afterwards.

- [ ] **Step 5: `CLAUDE.md`**

```bash
cd /c/Users/peixe/Documents/rpg-turnos && perl -pi -e 's/`_update_boss\(/`BattleFlow.update_boss(/g; s/`_boss_id\(/`BattleFlow.boss_id(/g' CLAUDE.md
```

Insert after the `GameAutoplay` entry:

```markdown
- `scripts/game/battle_flow.gd` (`BattleFlow`, `Node`, a piece of `Game`, M-70) — a battle on top of the map: `on_encounter(boss)` (the formation touched or `boss_id()`'s boss, the `BattleScene` added under this piece with the options, the creature and `medal_chance`; then `BattleRewards.after_victory()` or a defeat's way back (`go_to_town`, "Has vuelto ..."), the boss's cutscene (`play_scene`) or notice, the families, the missions done, `finish_v2` / `finish_game` when due, the save; `print_save` is the `--autoplay-save` exit, `quit_requested`), `update_boss()`, `boss_id()`, `boss_wanted()` (`echo_wanted`: autoplay meets the Eco only on `--autoplay-zone=eco`). Signals `battle_started`, `enemies_beaten(enemies, medals_won)`, `battle_lost(zone_id)`, `echo_fought(won)` (the autoplay's prints) and the Callable `after_battle` (`GameAutoplay.after_battle()`, awaited once the map is the player's).
```

At the end of the `Game` entry, append: ` The battles and the boss on the map are in BattleFlow.`

- [ ] **Step 6: Commit**

```bash
cd /c/Users/peixe/Documents/rpg-turnos && git add scripts/game/battle_flow.gd scripts/game/game.gd CLAUDE.md && git commit -m "Move the battle on the map and the boss's presence from Game to BattleFlow"
```

---

### Task 12: `GameDebug`

**Files:**
- Create: `scripts/game/game_debug.gd`
- Modify: `scripts/game/game.gd` (funcs `_build_debug`, `_on_debug`, `_debug_go`; var `_debug`; `_set_busy()`)
- Modify: `CLAUDE.md`

**Interfaces:**
- Consumes: `ZoneTravel.switch_zone()` / `respawn_groups()`, `BattleFlow.update_boss()`, `StoryFlow.check_village_scene()`, `BattleRewards.family_rewards()`, `World.debug_no_groups`.
- Produces:

```gdscript
class_name GameDebug extends Node
func setup(ctx: SessionContext, travel: ZoneTravel, battle: BattleFlow, story: StoryFlow) -> void
func set_available(on: bool) -> void
```

- [ ] **Step 1: Create `scripts/game/game_debug.gd`**

```gdscript
class_name GameDebug extends Node
## Node, a piece of Game, only with --debug on the command line (never otherwise; the web
## can't pass it; autoplay never uses it): owns the DebugPanel (F1 on the map opens it) and
## does what its buttons ask at once on the state and the map (_on_debug(): level, gold,
## items, heal, monster groups off and on, a boss beaten, the village quest's next stage, a
## save to the slot in use), printed as "Depuración: ..." and said on the panel; Ir a goes
## on under black (_debug_go()). While the panel is open Game is busy and the status window
## hides. Handed ZoneTravel, BattleFlow and StoryFlow in setup(), and uses only their public
## functions; never stores Game or a World.

const HERO_DATA := preload("res://data/hero.tres")

var _ctx: SessionContext
var _travel: ZoneTravel
var _battle: BattleFlow
var _story: StoryFlow
var _panel: DebugPanel


func setup(ctx: SessionContext, travel: ZoneTravel, battle: BattleFlow,
		story: StoryFlow) -> void:
	_ctx = ctx
	_travel = travel
	_battle = battle
	_story = story


## The panel over the pause menu, under the fade.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var layer := CanvasLayer.new()
	layer.layer = UiTokens.LAYER_DEBUG
	add_child(layer)
	_panel = DebugPanel.new()
	_panel.setup(_ctx.state)
	layer.add_child(_panel)
	_panel.action_chosen.connect(_on_debug)
	_panel.open_changed.connect(func(is_open: bool) -> void:
		_ctx.set_busy.call(is_open)
		_ctx.world.set_status_shown(not is_open))


## The panel only opens on the map with nothing else going on (Game._set_busy()).
func set_available(on: bool) -> void:
	if _panel:
		_panel.available = on
```

Cut `_on_debug` and `_debug_go` from `game.gd` into `move.gd`, with their comments. Run the global perl, then:

```bash
perl -pi -e 's/(?<![.\w])_debug\.show_result\(/_panel.show_result(/g' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/move.gd
grep -nP '(?<![.\w])(_debug|_world|_zone|_update_boss|_respawn_groups|_switch_zone|_check_village_scene)\b' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/move.gd
```

Expected: the `grep` prints nothing. The moved code already calls `_travel.switch_zone(...)`, `_travel.respawn_groups()`, `_battle.update_boss()`, `_story.check_village_scene()`, `BattleRewards.family_rewards(_ctx.state)` and `HERO_DATA.skills`, and the SAVE action reads `_ctx.slot` and `_ctx.play_time`.

Append `move.gd` to `game_debug.gd`.

- [ ] **Step 2: The owner's side**

1. Change `var _debug: DebugPanel` to `var _debug: GameDebug`. Its comment becomes `## The development piece, only with --debug (null otherwise).`
2. Replace `_build_debug()` with:

```gdscript
## --debug: the panel and its actions (GameDebug), where the debug panel was built.
func _build_debug() -> void:
	_debug = GameDebug.new()
	_debug.setup(_ctx, _travel, _battle, _story)
	add_child(_debug)
```

3. In `_set_busy()`, change `_debug.available = not busy` to `_debug.set_available(not busy)`.
4. Check:

```bash
cd /c/Users/peixe/Documents/rpg-turnos && grep -nP '(?<![.\w])(_on_debug|_debug_go|HERO_DATA\.skills)\b' scripts/game/game.gd; wc -l scripts/game/game.gd
```

Expected: no line from the `grep`. `wc -l` prints a number under 600 (about 430).

- [ ] **Step 3: Import and validate**

Validate `res://scripts/game/game_debug.gd` and `res://scripts/game/game.gd`. Expected: no errors.

- [ ] **Step 4: The panel, by hand**

```bash
cd /c/Users/peixe/Documents/rpg-turnos && APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --path . -- --debug
```

1. Start a new game in slot 1 (the slots are the scratch `APPDATA`'s) and wait for the map.
2. Press F1, then each button once: `Nivel +1`, `Nivel −1`, `Oro +100`, `Oro +1000`, `Objetos`, `Curar`, `Monstruos` (twice), the Rey Slime under Jefes, `Etapa siguiente`, `Guardar`, and an `Ir a` (Bosque).

Expected in the console, one line each:

- `Depuración: nivel 2 (PV ..., hechizos: ...)` and `Depuración: nivel 1 (...)`;
- `Depuración: +100 G (150 G)` and `Depuración: +1000 G (1150 G)`;
- `Depuración: +1 de cada objeto (n objetos)`;
- `Depuración: PV y PM llenos`;
- `Depuración: grupos quitados (quedan 0)` and `Depuración: grupos puestos (n)`;
- `Depuración: Rey Slime vencido (...)`;
- `Depuración: misión de la aldea: ...`;
- `Depuración: guardado en la ranura 1`;
- after the fade, `Depuración: a Bosque` (the forest's `map_label()`).

Also check that:

- the panel says each result;
- the status window hides while the panel is open;
- no `ERROR` is printed.

Close the game. Then run it once without `--debug` and check that F1 does nothing.

- [ ] **Step 5: Run**

```bash
bash C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/check.sh save
```

Expected: `1`.

- [ ] **Step 6: `CLAUDE.md`**

```bash
cd /c/Users/peixe/Documents/rpg-turnos && perl -pi -e 's/`_on_debug\(/`GameDebug._on_debug(/g; s/`_debug_go\(/`GameDebug._debug_go(/g' CLAUDE.md
```

Insert after the `BattleFlow` entry:

```markdown
- `scripts/game/game_debug.gd` (`GameDebug`, `Node`, a piece of `Game` only with `--debug`, M-70, `PROCESS_MODE_ALWAYS`) — owns the `DebugPanel` (layer `UiTokens.LAYER_DEBUG`; open: busy, status hidden) and does its actions in `_on_debug()`, each printed as `Depuración: ...`; Ir a is `_debug_go()` (under black, no autosave). `set_available(on)` from `Game._set_busy()`. Handed `ZoneTravel`, `BattleFlow` and `StoryFlow` in `setup()`.
```

At the end of the `Game` entry, append: ` The debug panel's actions are in GameDebug.`

- [ ] **Step 7: Commit**

```bash
cd /c/Users/peixe/Documents/rpg-turnos && git add scripts/game/game_debug.gd scripts/game/game.gd CLAUDE.md && git commit -m "Move the debug panel's actions from Game to GameDebug"
```

---

### Task 13: The final pass (guide step 6)

**Files:**
- Modify: `scripts/game/game.gd` (header comment only)
- Modify: `CLAUDE.md`, `CHANGELOG.md`, `docs/boost/documento-maestro.md`

**Interfaces:**
- Consumes: everything above.
- Produces: the finished refactor, merged into `develop`.

- [ ] **Step 1: `Game`'s header**

Replace the whole `##` comment at the top of `scripts/game/game.gd`, from the line after `class_name Game extends Node` down to the line before `signal quit_to_title`, with:

```gdscript
## One play session, created by TitleScreen (setup() before add_child); run on its own
## (res://scenes/game/game.tscn) it starts a new game with its own AudioDirector and default
## options. A coordinator: it owns the GameState, the current map (in its SessionContext,
## which it passes to every piece), the fade, the saving (_autosave(), the pause menu's
## Guardar), the busy flag (_set_busy(): the pause menu and the debug panel only open on the
## map with nothing else going on), the map's status (_refresh_status()), the map music, the
## pause menu and the ShopWindow; it loads a save or starts a new game (the prologue), and
## emits quit_to_title when the player goes back to the title or an ending is over.
## Each job of the session is a piece, a child Node wired in _add_pieces(): ZoneTravel (the
## change of map, exits, the Ala and its portal), StoryFlow (the cutscenes and the endings),
## CaravanFlow (the v2's departure and companion), FigureTalk (figures, shops, inns, wells,
## chests, the lever, the key, the gates), BattleFlow (the battles and the boss on the map),
## GameAutoplay (only with --autoplay) and GameDebug (only with --debug). What a piece awaits
## from another is a Callable Game wires; what it reports is a signal Game connects.
##
## `-- --autoplay --autoplay-save`: the first save after a won battle is printed
## ("Guardado: ...") and the title loads it at once ("Cargado: ...", printed here).
## `-- --autoplay --autoplay-menu`: MENU_TOUR_DELAY seconds into the map it shows every page
## of the pause menu (PauseMenu.tour()), to record frames of it.
## The other autoplay starts are in AutoplayStarts and GameAutoplay.
```

Validate `res://scripts/game/game.gd`. Expected: no errors.

- [ ] **Step 2: All the references**

```bash
for r in v1 v2 medallas eco save caravana60 bosque mina_1 mina_3 castillo_patio castillo_trono jungla desierto montana portal ciudad; do echo "### $r"; bash C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/check.sh $r; done
```

Expected for each run:

- nothing under errors and the diff;
- `v1` `Nv 18`, `v2` `Nv 40`;
- `medallas` `12/12 · premios 5/5`;
- `eco` a victory;
- `save` `1`;
- the times within about 5 minutes of the reference's.

- [ ] **Step 3: The pause menu, the phone and the portraits**

```bash
cd /c/Users/peixe/Documents/rpg-turnos && mkdir -p C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/new/menu4 && APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --path . --write-movie C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/new/menu4/f.png --fixed-fps 10 --quit-after 140 -- --autoplay --autoplay-menu
```

Open frames `f00000030.png`, `f00000045.png`, `f00000060.png`, `f00000075.png`, `f00000090.png`, `f00000105.png` and `f00000120.png` of `ref/menu4/` and `new/menu4/` side by side with the Read tool. Expected: the same pages (main, Estado, Objetos, Equipo, Diario, Opciones) with the same layout. The map behind may differ.

Phone, by hand:

```bash
cd /c/Users/peixe/Documents/rpg-turnos && APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --path . --resolution 740x360 -- --touch
```

Start a new game. Walk with the finger (the mouse), talk to the Abuela Rosa, open the shop, fight one group and open ☰. Expected: the walking hint the first time on the map, the use button, the shop, the battle and the pause menu as before, and no `ERROR` in the console.

Portraits:

```bash
cd /c/Users/peixe/Documents/rpg-turnos && APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --path . --script res://scripts/tools/bestiary_shots.gd; git status --short assets/bestiary
```

Expected: `git status` prints nothing.

- [ ] **Step 4: The web export**

```bash
cd /c/Users/peixe/Documents/rpg-turnos && mkdir -p build/web && APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --export-release "Web" build/web/index.html > C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/new/web.log 2>&1; grep -E 'ERROR|WARNING' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/new/web.log; cat C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/pck.size; ls -l build/web/index.pck | awk '{print $5}'
```

Expected:

- no `ERROR` / `WARNING` lines;
- the two sizes within 1 % of each other (eleven small new scripts).

Then serve `build/web` with any static server (for example `python -I -m http.server 8000 --directory build/web`) and open it in the browser pane. Start a new game, play the prologue and reach the map. Expected: no new errors in the browser console.

- [ ] **Step 5: `CLAUDE.md`**

1. Check that no reference to a moved name is left:

```bash
cd /c/Users/peixe/Documents/rpg-turnos && grep -nE '`_(switch_zone|respawn_groups|spawn_rare|go_to_town|on_portal|to_place|play_scene|play_prologue|check_village_scene|check_arrival_line|finish_game|finish_v2|ask_departure|choose_companion|on_shop|on_inn|talk_to_collector|autoplay_restock|wants_retreat|needs_groups|autoplay_hunts|boss_needs_rest|autoplay_retreat|update_boss|boss_id|give_family_rewards|note_enemies|credits_sections|v2_credits_sections|v2_numbers|on_debug|debug_go)\(' CLAUDE.md
```

Expected: no output.

2. In the `scripts/game/game.gd` (`Game`) entry, right after `(`Game`) — `, insert: `the session coordinator (M-70: what follows is the session as a whole; each name says which piece holds it, and the entries of the pieces follow this one): `
3. Check the *Conventions* note on scenes that are almost empty (the spec's decision):

```bash
cd /c/Users/peixe/Documents/rpg-turnos && grep -n 'almost empty' CLAUDE.md
```

If it prints nothing, append to *Conventions*:

```markdown
- Scenes stay almost empty on purpose: the work is done without the editor, and a hand-written `.tscn` with dozens of nodes is more fragile than code. The Godot equivalent of small reusable scenes here is a node class with one job, a piece (`MapHud`, `ZoneTravel`...), created in code by its owner.
```

- [ ] **Step 6: `CHANGELOG.md`**

```bash
cd /c/Users/peixe/Documents/rpg-turnos && sed -n 1,5p CHANGELOG.md
```

- If line 3 is `## Sin publicar` (plans 1-3 opened it), add this bullet at the end of that section's list.
- Otherwise, insert this section between `# Registro de cambios` and `## 2.7.0 (2026)`, with the bullet:

```markdown
## Sin publicar

Por dentro, más ordenado. El juego no cambia.

- La partida se reparte en piezas pequeñas: los viajes entre zonas, los combates, las charlas con la gente, la caravana, la historia, la partida automática y el panel de depuración. Las reglas, los textos y las partidas guardadas son los mismos de antes.
```

When adding to an existing section, add only the last line (the bullet).

- [ ] **Step 7: `docs/boost/documento-maestro.md`**

```bash
cd /c/Users/peixe/Documents/rpg-turnos && grep -n 'M-70' docs/boost/documento-maestro.md
```

Expected: one line.

- If it starts with `| Sin versión · M-70 |`, replace the whole line with the row below.
- If it is still the shared `| Sin versión · M-70 a M-74 |` row:
  - change `M-70 a M-74` in it to `M-71 a M-74`, keeping the rest of it as plans 1-3 left it;
  - insert the row below right before it.

```markdown
| Sin versión · M-70 | Trocear `Game`: `SessionContext` y las piezas `ZoneTravel`, `BattleFlow`, `BattleRewards`, `FigureTalk`, `CaravanFlow`, `StoryFlow`, `CreditsData`, `GameAutoplay`, `AutoplayStarts` y `GameDebug`; `Game` queda como coordinador de la sesión ([spec](specs/2026-11-14-refactor-arquitectura-design.md) · [guía](specs/2026-11-14-refactor-arquitectura-guia.md) · [plan](plans/2026-11-14-refactor-4-game.md)) | hecho |
```

- [ ] **Step 8: Commit and merge**

```bash
cd /c/Users/peixe/Documents/rpg-turnos && git add scripts/game/game.gd CLAUDE.md CHANGELOG.md docs/boost/documento-maestro.md && git commit -m "Finish splitting Game: header, CLAUDE.md, changelog and master document"
git checkout develop && git merge --no-ff feature/refactor-4-game -m "Merge feature/refactor-4-game into develop" && git log --oneline -3
```

Expected:

- the merge commit on top;
- `git status --short` empty, except `build/`, which is git-ignored.

Do not push. Afterwards delete these scratch folders:

- `C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/new/menu4`
- `C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/menu4`

---

## Self-review

- **Spec coverage, M-70 table:** each piece has its task.

| Piece | Task |
|---|---|
| `ZoneTravel` | 5 |
| `BattleFlow` | 11 |
| `BattleRewards` | 4 |
| `FigureTalk` | 8-9 |
| `CaravanFlow` | 7, with the caravan's arrival taken out of `check_village_scene` |
| `StoryFlow` | 6 |
| `CreditsData` | 2 |
| `GameAutoplay` | 10, with the autoplay part of `_process()` as `step()` |
| `AutoplayStarts` | 3 |
| `GameDebug` | 12 |
| `SessionContext` | 1 |
| Final pass (guide step 6) | 13 |

- **Deviations from the spec's table, kept small and stated in the files:**
  - `_note_enemies`, `_give_family_rewards`, `_boss_notice`, `_boss_id` and `_boss_wanted` are pure, so they go to `BattleRewards` as static functions. `BattleFlow` keeps `boss_id()` / `boss_wanted()` as one-line calls to them. `ZoneTravel` and `GameAutoplay` use `BattleRewards` directly instead of calling `BattleFlow`.
  - The autoplay thresholds (`AUTOPLAY_INN_RATIO`, `AUTOPLAY_STALL_S`, `AUTOPLAY_BOSS_*`, `rested_for_boss()`) and `companion()` go to `AutoplayStarts`, because `FigureTalk` and `BattleFlow` read them too.
  - `_rested_for_boss`, `_potion_count`, `_on_village_changed`, `_on_stepped`, `_show_touch_hint` and `_play_map_music` are not in the spec's table. The first two go to `AutoplayStarts` / `SessionContext`; the last four stay in `Game`.
- **Signals through `Game`:** awaited requests are `Callable` fields wired by `Game` in `_add_pieces()`; notifications are signals. The spec's example (`BattleFlow` → `StoryFlow`) is the `play_scene` Callable, because the boss's cutscene must be awaited inside the battle's sequence.
- **Type consistency:** the names in each task's *Interfaces* are the ones later tasks wire:
  - `ZoneTravel.switch_zone`, `on_exit`, `on_travel_requested`, `on_portal`, `go_to_town`, `respawn_groups`, `spawn_rare`, `to_place`;
  - `StoryFlow.play_scene`, `play_prologue`, `check_village_scene`, `check_arrival_line`, `finish_game`, `finish_v2`;
  - `CaravanFlow.CARAVAN_CHIEF`, `arrival_scene`, `ask_departure`, `choose_companion`, `autoplay_companion`, `autoplay_leaves`;
  - `FigureTalk.on_talk`, `on_npc`, `talk_to_collector`, `on_shop`, `on_inn`, `on_well`, `on_chest`, `on_lever`, `on_key`, `on_door`;
  - `BattleFlow.on_encounter`, `update_boss`, `boss_id`, `boss_wanted`, `echo_wanted`, `medal_chance`, `print_save`, `after_battle`;
  - `GameAutoplay.echo`, `plays_v2`, `medal_tour`, `companion`, `apply_start`, `step`, `after_battle`, `reset_quiet`, `on_*`, `note_status`, `print_*`, `start_medal_tour`, `hunts`;
  - `GameDebug.setup`, `set_available`.
