# Refactor 1: reference, RunFlags and builder headers Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Capture the reference runs of the refactor (guide step 0), put every command-line read behind one class `RunFlags` and group the autoplay code of six classes in `#region Autoplay` blocks (M-74), and label the seven builder classes with `## Constructor:` plus write the three script kinds into `CLAUDE.md` (M-73). Nothing in the game changes.

**Architecture:** `RunFlags` is a static `RefCounted` that reads `OS.get_cmdline_user_args()` once into a `static var`. Every script that read the command line calls it instead. The `#region Autoplay` work only moves declarations and functions inside their own file; branches like `if _autoplay:` inside shared functions stay where they are. M-73 only touches comments and `CLAUDE.md`.

**Tech Stack:** Godot 4.7.2 (Compatibility renderer), GDScript, Git Bash on Windows, the wrapper `./tools/godot.cmd`.

**Spec:** `docs/boost/specs/2026-11-14-refactor-arquitectura-design.md` (M-73, M-74). **Guide:** `docs/boost/specs/2026-11-14-refactor-arquitectura-guia.md` (step 0, steps 1 and 2).

## Global Constraints

- Behaviour must not change: no rules, texts, balance or looks. The save format stays at version 14. Autoplay prints the same lines.
- **No tests of any kind** (`CLAUDE.md` overrides the skill's TDD steps). Verification is by hand: `--import`, `--check-only`, autoplay runs compared with the reference, screenshots.
- No `.tscn` or `project.godot` changes. No class renamed, no existing file moved. The only new file is `scripts/game/run_flags.gd` (plus the `run_flags.gd.uid` that `--import` writes next to it).
- After this plan, no script outside `scripts/game/run_flags.gd` calls `OS.get_cmdline_user_args()`, and no quoted string `"--..."` appears in `scripts/` outside it. `scripts/tools/*` stay as they are (offline tools excluded from the export).
- Every command runs in Git Bash from the repo root: start each command block with `cd /c/Users/peixe/Documents/rpg-turnos`.
- Every Godot run sets `APPDATA` inline to the literal scratch path `APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor"`. Never write `$APPDATA` in `rm`, `mv` or `cp`.
- Reference logs live in `C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/`. The logs of a later check live in `C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/<task folder>/`.
- The only accepted WARNING is `Jolt Physics job system exceeded the maximum number of jobs`. Any other `ERROR` or `WARNING` is a real problem.
- Branch `feature/refactor-1-runflags-builders` from `develop`. It is merged back with `git merge --no-ff`. One task = one commit (Task 1 commits nothing: its files live outside the repo).
- Commit messages are in English, with no `Co-Authored-By` and no attribution of any kind. Never push.
- `CLAUDE.md` is updated in the same commit as the code it describes.

### How to compare a run with the reference (used by every task)

For a log `NEW` and its reference `REF`, both full paths:

1. Errors and warnings of the new run:

   ```bash
   grep -E 'ERROR|WARNING' NEW | grep -v 'Jolt Physics job system exceeded'
   ```

   Expected: no output.

2. Milestones:

   ```bash
   diff <(grep -E '^(Zona|Escena|Lugar|Compañero|Pregunta|Misión cumplida|Juego completado|Medallas|Eco de la Niebla)' REF) <(grep -E '^(Zona|Escena|Lugar|Compañero|Pregunta|Misión cumplida|Juego completado|Medallas|Eco de la Niebla)' NEW)
   ```

   Expected: the `Zona:`, `Escena:`, `Lugar:`, `Pregunta:` and `Compañero:` lines are the same and in the same order. The runs have unseeded randomness, so these may differ, and only within the range Task 1 measured between `v1.log` and `v1b.log`:
   - the number and order of the `Misión cumplida:` lines;
   - the time on the `Juego completado` line (about 5 minutes either way);
   - the counts on the `Eco de la Niebla:` lines.

   The level on `Juego completado` must be the same, and so must the final `Medallas:` line.

If a run's milestones differ beyond that twice in a row, stop: `git reset --hard` to the task's starting commit (on the feature branch only) and rethink the step (guide, *Cuándo parar*).

---

### Task 1: The reference (guide step 0)

Nothing in the repo changes. This task records how `develop` behaves today, so every later task (and plans 2 to 4) can compare against it.

**Files:**
- Create (outside the repo): `C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/*.log`, `ref/menu/`, `ref/touch/`, `ref/phone/`

**Interfaces:**
- Consumes: nothing.
- Produces: the reference logs named below, which every later task and plans 2-4 compare against: `v1.log`, `v1b.log`, `v2.log`, `medallas.log`, `eco.log`, `save.log`, `battle.log`, `tadeo.log`, `zone_<id>.log` for each `--autoplay-zone` start, the frame folders `menu/` and `touch/`, and the phone screenshots in `phone/`.

- [ ] **Step 1: Branch and scratch folders**

```bash
cd /c/Users/peixe/Documents/rpg-turnos
git checkout develop
git status --short
git checkout -b feature/refactor-1-runflags-builders
mkdir -p "C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/menu" "C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/touch" "C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/phone"
```

Expected: `git status --short` prints nothing, or only this untracked plan file and the other refactor plans (`?? docs/boost/plans/...`). Then `Switched to a new branch 'feature/refactor-1-runflags-builders'`.

- [ ] **Step 2: Refresh the class cache**

```bash
cd /c/Users/peixe/Documents/rpg-turnos
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --import 2>&1 | grep -E 'ERROR|WARNING'
```

Expected: no output.

- [ ] **Step 3: The v1, twice (the second one measures the run-to-run variance)**

These take a few minutes each. Run them in the background (`run_in_background`) and wait for the notice; don't poll.

```bash
cd /c/Users/peixe/Documents/rpg-turnos
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --fixed-fps 10 --quit-after 150000 -- --autoplay > "C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/v1.log" 2>&1
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --fixed-fps 10 --quit-after 150000 -- --autoplay > "C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/v1b.log" 2>&1
grep -E '^Juego completado' "C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/v1.log" "C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/v1b.log"
```

Expected: one line in each, `Juego completado: Nv 18, tiempo de juego 0:5x:xx, misiones n` (Nv 18, about 0:55-1:05, 4-6 missions). Then run the milestone `diff` of *How to compare* on `v1.log` (REF) and `v1b.log` (NEW). Write down which lines differ: that is the normal variance later tasks may show.

- [ ] **Step 4: The v2 whole (about 20 minutes real time, in the background)**

```bash
cd /c/Users/peixe/Documents/rpg-turnos
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --fixed-fps 10 --quit-after 500000 -- --autoplay --autoplay-zone=caravana > "C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/v2.log" 2>&1
grep -E '^Juego completado' "C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/v2.log"
```

Expected: `Juego completado (v2): Nv 40, tiempo en la caravana h:mm:ss, tiempo de juego 1:4x:xx, misiones n/8` (Nv 40, about 1:43-1:58).

- [ ] **Step 5: Medals, Eco, the save round trip and the lone battle**

```bash
cd /c/Users/peixe/Documents/rpg-turnos
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --fixed-fps 10 --quit-after 60000 -- --autoplay --autoplay-zone=medallas > "C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/medallas.log" 2>&1
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --fixed-fps 10 --quit-after 40000 -- --autoplay --autoplay-zone=eco > "C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/eco.log" 2>&1
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --fixed-fps 10 --quit-after 6000 -- --autoplay --autoplay-save > "C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/save.log" 2>&1
rm -f "C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/Godot/app_userdata/rpg-turnos/save_autoplay.json"
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . res://scenes/battle/battle_scene.tscn -- --autoplay > "C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/battle.log" 2>&1
grep -E '^Medallas: [0-9]+/12' "C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/medallas.log" | tail -1
grep -cE '^Eco de la Niebla: victoria' "C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/eco.log"
diff <(grep '^Guardado: ' "C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/save.log" | cut -c11-) <(grep '^Cargado: ' "C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/save.log" | cut -c10-) && echo IGUALES
grep -E '^Fin del combate' "C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/battle.log"
```

Expected, in order:
- `Medallas: 12/12 · premios 5/5`;
- a number of at least 1;
- `IGUALES`;
- `Fin del combate (estado N)`, with N a number.

- [ ] **Step 6: The companion flag, and every `--autoplay-zone` start (for plans 3 and 4)**

```bash
cd /c/Users/peixe/Documents/rpg-turnos
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --fixed-fps 10 --quit-after 8000 -- --autoplay --autoplay-zone=jungla --autoplay-companion=tadeo > "C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/tadeo.log" 2>&1
grep -c 'Tadeo' "C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/tadeo.log"; grep -c 'Brena' "C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/tadeo.log"
for z in bosque:40000 mina_1:60000 mina_3:40000 castillo_patio:60000 castillo_trono:40000 jungla:40000 desierto:60000 montana:60000 ciudad:150000 portal:100000; do id=${z%%:*}; n=${z##*:}; APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --fixed-fps 10 --quit-after $n -- --autoplay --autoplay-zone=$id > "C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/zone_$id.log" 2>&1; done
grep -H '^Zona de inicio' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/zone_*.log
```

The loop takes about an hour of real time: run it in the background.

Expected:
- The first count is at least 1 and the second is `0`.
- One `Zona de inicio: <zone> (Nv n)` line per file, ten in all: bosque Nv 5, mina_1 Nv 9, mina_3 Nv 13, castillo_patio Nv 13, castillo_trono Nv 17, jungla Nv 20, desierto Nv 25, montana Nv 30, ciudad Nv 35, portal Nv 38.

Run the error `grep` of *How to compare* on every file of `ref/`. Expected: no output. If a reference already has an error, write it down: it predates the refactor and is not compared.

- [ ] **Step 7: Pause menu frames and phone frames**

```bash
cd /c/Users/peixe/Documents/rpg-turnos
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --path . --write-movie "C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/menu/f.png" --fixed-fps 10 --quit-after 140 -- --autoplay --autoplay-menu > "C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/menu.log" 2>&1
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --path . --write-movie "C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/touch/f.png" --fixed-fps 10 --quit-after 300 -- --autoplay --touch > "C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/touch.log" 2>&1
ls "C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/menu" | wc -l; ls "C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/touch" | wc -l
```

Expected: about 140 and about 300 PNG files. Open `ref/menu/f00000030.png`, `f00000060.png`, `f00000090.png`, `f00000120.png` and `ref/touch/f00000100.png`, `f00000200.png`, `f00000299.png` with the Read tool. The menu frames show pause-menu pages; the touch frames show the phone layout, with the ☰ button at the top right and the compact status window.

- [ ] **Step 8: The phone by hand**

```bash
cd /c/Users/peixe/Documents/rpg-turnos
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --path . --resolution 740x360 -- --touch
```

Start a new game with the mouse. Take a screenshot (Win+Shift+S, saved into `C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/phone/`) of each of these, then close the window:
- the title;
- the map with the use button showing (next to a villager);
- a battle menu;
- a shop;
- the pause menu.

If no person can take them in this session, note that, and rely on the `touch/` frames.

- [ ] **Step 9: The bestiary portraits, twice**

```bash
cd /c/Users/peixe/Documents/rpg-turnos
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --path . --script res://scripts/tools/bestiary_shots.gd > "C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/shots1.log" 2>&1
git status --short assets/bestiary
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --path . --script res://scripts/tools/bestiary_shots.gd > "C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/shots2.log" 2>&1
git status --short assets/bestiary
```

Expected: both `git status` print nothing, so the portraits come out the same pixel for pixel. If either lists changed PNGs, write down in `ref/NOTES.txt` that the portraits must be compared by eye (guide, point 5). Then restore them with `git checkout -- assets/bestiary` and check that `git status --short` is clean again.

- [ ] **Step 10: Notes**

Write `C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/NOTES.txt` with:
- the `develop` commit (`git rev-parse develop`);
- the `Juego completado` lines of `v1.log`, `v1b.log` and `v2.log`;
- the milestone lines that differ between `v1.log` and `v1b.log`;
- any error already present in a reference;
- whether the portraits were stable.

No commit.

---

### Task 2: `RunFlags`, the only reader of the command line (M-74, part 1)

**Files:**
- Create: `scripts/game/run_flags.gd` (and the `scripts/game/run_flags.gd.uid` that `--import` writes)
- Modify: `scripts/title/title_screen.gd` (`_ready`)
- Modify: `scripts/game/game.gd` (`_ready`, `_apply_autoplay_zone`)
- Modify: `scripts/game/device.gd` (`is_touch`)
- Modify: `scripts/ui/display_settings.gd` (`_apply_touch`)
- Modify: `scripts/game/save_store.gd` (`save_path`, `migrate_legacy`)
- Modify: `scripts/ui/name_entry.gd` (`_accept`)
- Modify: the `_ready()` of `scripts/story/cutscene_player.gd`, `scripts/story/beyond_screen.gd`, `scripts/ui/credits_screen.gd`, `scripts/battle/battle_scene.gd`, `scripts/ui/dialogue_box.gd`, `scripts/world/player.gd`, `scripts/audio/audio_director.gd`, `scripts/world/world.gd` and `scripts/ui/shop_window.gd`
- Modify: `scripts/ui/debug_panel.gd` (header comment only)
- Modify: `CLAUDE.md` (*Layout*: new entry after the `device.gd` one; *Conventions*: one new bullet)

**Interfaces:**
- Consumes: nothing.
- Produces (plans 2-4 rely on these exact names): `class_name RunFlags extends RefCounted` with `static func autoplay() -> bool`, `static func autoplay_save() -> bool`, `static func autoplay_menu() -> bool`, `static func autoplay_easy() -> bool`, `static func autoplay_zone() -> String`, `static func autoplay_companion() -> String`, `static func debug() -> bool`, `static func touch() -> bool`. `autoplay_save()`, `autoplay_menu()` and `autoplay_easy()` are false without `--autoplay`, as every caller checked before. `autoplay_zone()` and `autoplay_companion()` return the text after `=` of the first matching argument, or `""`. They don't check `--autoplay`: `Game` decides, as before.

- [ ] **Step 1: Create `scripts/game/run_flags.gd`**

```gdscript
class_name RunFlags extends RefCounted
## The flags given after `--` on the command line (`godot --path . -- --autoplay ...`), read
## once from OS.get_cmdline_user_args() and kept in a static var. The only script of the game
## that reads the command line (the offline tools of scripts/tools/ read their own). The web
## build gets none, so every flag is off there. The autoplay sub-flags (save, menu, easy)
## only count with --autoplay.

const AUTOPLAY := "--autoplay"
const AUTOPLAY_SAVE := "--autoplay-save"
const AUTOPLAY_MENU := "--autoplay-menu"
const AUTOPLAY_EASY := "--autoplay-easy"
const AUTOPLAY_ZONE := "--autoplay-zone="
const AUTOPLAY_COMPANION := "--autoplay-companion="
const DEBUG := "--debug"
const TOUCH := "--touch"

static var _args := PackedStringArray()
static var _read := false


## --autoplay: a new game that plays by itself (no title menu, its own save file).
static func autoplay() -> bool:
	return _has(AUTOPLAY)


## --autoplay-save (with --autoplay): prints the save written and the save loaded.
static func autoplay_save() -> bool:
	return autoplay() and _has(AUTOPLAY_SAVE)


## --autoplay-menu (with --autoplay): tours the pause menu once the map is up.
static func autoplay_menu() -> bool:
	return autoplay() and _has(AUTOPLAY_MENU)


## --autoplay-easy (with --autoplay): the new game is on Fácil.
static func autoplay_easy() -> bool:
	return autoplay() and _has(AUTOPLAY_EASY)


## --autoplay-zone=<id>: the start Game uses for a new autoplay game ("" when absent).
static func autoplay_zone() -> String:
	return _value(AUTOPLAY_ZONE)


## --autoplay-companion=<id>: the companion of an autoplay start ("" when absent; Game keeps
## its own default and checks the id).
static func autoplay_companion() -> String:
	return _value(AUTOPLAY_COMPANION)


## --debug: Game builds its DebugPanel (F1 on the map).
static func debug() -> bool:
	return _has(DEBUG)


## --touch: the desktop fakes a phone (Device.is_touch()), the mouse acting as a finger.
static func touch() -> bool:
	return _has(TOUCH)


static func _all() -> PackedStringArray:
	if not _read:
		_args = OS.get_cmdline_user_args()
		_read = true
	return _args


static func _has(flag: String) -> bool:
	return _all().has(flag)


## The text after prefix of the first argument that starts with it, or "".
static func _value(prefix: String) -> String:
	for arg in _all():
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix)
	return ""
```

- [ ] **Step 2: `TitleScreen._ready()`**

In `scripts/title/title_screen.gd`, replace

```gdscript
	var args := OS.get_cmdline_user_args()
	_autoplay = args.has("--autoplay")
	_autoplay_save = _autoplay and args.has("--autoplay-save")
```

with

```gdscript
	_autoplay = RunFlags.autoplay()
	_autoplay_save = RunFlags.autoplay_save()
```

- [ ] **Step 3: `Game._ready()`**

In `scripts/game/game.gd`, `_ready()`, replace

```gdscript
	var args := OS.get_cmdline_user_args()
	_autoplay = args.has("--autoplay")
	_autoplay_save = _autoplay and args.has("--autoplay-save")
	_autoplay_menu = _autoplay and args.has("--autoplay-menu")
	for arg in args:
		if arg.begins_with("--autoplay-companion="):
			var companion := arg.trim_prefix("--autoplay-companion=")
			if Allies.is_companion(companion):
				_autoplay_companion = companion
			else:
				push_error("Not a companion for --autoplay-companion: %s" % companion)
```

with

```gdscript
	_autoplay = RunFlags.autoplay()
	_autoplay_save = RunFlags.autoplay_save()
	_autoplay_menu = RunFlags.autoplay_menu()
	var companion := RunFlags.autoplay_companion()
	if companion != "":
		if Allies.is_companion(companion):
			_autoplay_companion = companion
		else:
			push_error("Not a companion for --autoplay-companion: %s" % companion)
```

In the same function, replace

```gdscript
		if _autoplay and OS.get_cmdline_user_args().has("--autoplay-easy"):
```

with

```gdscript
		if RunFlags.autoplay_easy():
```

replace

```gdscript
		_apply_autoplay_zone(args)
```

with

```gdscript
		_apply_autoplay_zone()
```

and replace

```gdscript
	if args.has("--debug"):
```

with

```gdscript
	if RunFlags.debug():
```

- [ ] **Step 4: `Game._apply_autoplay_zone()`**

Replace the whole function, from its `## --autoplay-zone=<id>: ...` comment to its last `print(...)` line, with the code below. It is the same body without the `for arg in args` loop, one tab less.

The only difference: an empty `--autoplay-zone=` (no id) used to print `Unknown zone for --autoplay-zone: ` and now does nothing. No run passes it.

```gdscript
## --autoplay-zone=<id>: starts the new game in that zone with AUTOPLAY_ZONES' state.
func _apply_autoplay_zone() -> void:
	var start_id := RunFlags.autoplay_zone()
	if start_id == "":
		return
	var start: Dictionary = AUTOPLAY_ZONES.get(start_id, {})
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
		state.ally_id = _autoplay_companion
	var items: Dictionary = start.get("items", {})
	for id: String in items:
		state.inventory.add(id, items[id])
	_autoplay_echo = start_id == ECHO_START
	_autoplay_v2 = start_id in V2_STARTS
	_medal_tour = start_id == MEDAL_TOUR
	state.story.mark_seen_for_flags(state.world_flags)
	if start.get("finished", false):
		state.story.finished = true
	state.sync_level_cap()
	print("Zona de inicio: %s (Nv %d)" % [zone_id, state.hero.level])
```

Before replacing, compare it line by line with the current function body. If the current code differs from the block above (a later commit on `develop`), keep the current lines and only remove the loop, the `continue` and one tab of indentation.

- [ ] **Step 5: `--touch` in `Device` and `DisplaySettings`**

In `scripts/game/device.gd`, `is_touch()`, and in `scripts/ui/display_settings.gd`, `_apply_touch()`, replace

```gdscript
	if OS.get_cmdline_user_args().has("--touch"):
```

with

```gdscript
	if RunFlags.touch():
```

- [ ] **Step 6: `SaveStore` and `NameEntry`**

In `scripts/game/save_store.gd`, in both `save_path()` and `migrate_legacy()`, and in `scripts/ui/name_entry.gd`, `_accept()`, replace

```gdscript
	if OS.get_cmdline_user_args().has("--autoplay"):
```

with

```gdscript
	if RunFlags.autoplay():
```

- [ ] **Step 7: The nine `_ready()` that cache `_autoplay`**

In the `_ready()` of each of these files:
- `scripts/story/cutscene_player.gd`
- `scripts/story/beyond_screen.gd`
- `scripts/ui/credits_screen.gd`
- `scripts/battle/battle_scene.gd`
- `scripts/ui/dialogue_box.gd`
- `scripts/world/player.gd`
- `scripts/audio/audio_director.gd`
- `scripts/world/world.gd`
- `scripts/ui/shop_window.gd`

replace

```gdscript
	_autoplay = OS.get_cmdline_user_args().has("--autoplay")
```

with

```gdscript
	_autoplay = RunFlags.autoplay()
```

- [ ] **Step 8: The `DebugPanel` header comment**

In `scripts/ui/debug_panel.gd`, replace the comment line

```gdscript
## (OS.get_cmdline_user_args(); the web has no way to pass it), and autoplay never uses it.
```

with

```gdscript
## (RunFlags.debug(); the web has no way to pass it), and autoplay never uses it.
```

- [ ] **Step 9: Nothing else reads the command line**

```bash
cd /c/Users/peixe/Documents/rpg-turnos
grep -rn "get_cmdline" scripts --include=*.gd | grep -v '^scripts/tools/' | grep -v '^scripts/game/run_flags.gd'
grep -rn '"--' scripts --include=*.gd | grep -v '^scripts/tools/' | grep -v '^scripts/game/run_flags.gd'
grep -rn "RunFlags\." scripts --include=*.gd | wc -l
```

Expected: the first two print nothing; the third prints `24`. The 24 matches are:
- title 2;
- game 6 in `_ready()` (`autoplay`, `autoplay_save`, `autoplay_menu`, `autoplay_companion`, `autoplay_easy`, `debug`) plus 1 in `_apply_autoplay_zone`;
- device 1, display_settings 1;
- save_store 2, name_entry 1;
- the nine `_ready()`;
- the `DebugPanel` header comment 1.

If the count is off, list the calls with `grep -rn "RunFlags\." scripts` and fix the step that missed one.

- [ ] **Step 10: Import and validate**

```bash
cd /c/Users/peixe/Documents/rpg-turnos
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --import 2>&1 | grep -E 'ERROR|WARNING'
ls scripts/game/run_flags.gd.uid
for s in game/run_flags title/title_screen game/game game/device ui/display_settings game/save_store ui/name_entry story/cutscene_player story/beyond_screen ui/credits_screen battle/battle_scene ui/dialogue_box world/player audio/audio_director world/world ui/shop_window ui/debug_panel; do echo "== $s"; APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --check-only --script res://scripts/$s.gd 2>&1 | grep -E 'ERROR|Parse Error|WARNING'; done
```

Expected: the import grep prints nothing, then `scripts/game/run_flags.gd.uid`, then only the 17 `== ...` headers, with no error line under any of them.

- [ ] **Step 11: Every reference run, once (guide table: `RunFlags`)**

Make the folder `C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/t2/`. In it, rerun every command of Task 1, steps 3 to 7, with the same arguments:
- write `t2/<same name>.log` instead of `ref/<name>.log`, and the movie frames to `t2/menu/f.png` and `t2/touch/f.png`;
- v1 only once (`t2/v1.log`);
- delete `C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/Godot/app_userdata/rpg-turnos/save_autoplay.json` after the save run, as in Task 1;
- the long runs (v2, the zone loop) in the background.

Then:
- For `v1`, `v2`, `medallas`, `eco`, `jungla` and each `zone_<id>`: run both checks of *How to compare* with REF = `ref/<name>.log` and NEW = `t2/<name>.log`. Expected as described there.
- Save: the `diff ... && echo IGUALES` of Task 1, step 5, on `t2/save.log`. Expected: `IGUALES`.
- Battle: `grep -E '^Fin del combate' t2/battle.log`. Expected: `Fin del combate (estado N)`.
- `--autoplay-companion=tadeo`: `grep -c Tadeo t2/tadeo.log` is at least 1 and `grep -c Brena t2/tadeo.log` is `0`.
- Zone starts: `grep -H '^Zona de inicio' t2/zone_*.log` gives the same ten lines as the reference.
- Frames: open `t2/menu/f00000030.png`, `f00000060.png`, `f00000090.png`, `f00000120.png` next to the same `ref/menu/` frames. Expected: the same pages. Then `t2/touch/f00000100.png`, `f00000200.png`, `f00000299.png` next to the `ref/touch/` ones. Expected: the same phone layout (☰ at the top right, compact status).

- [ ] **Step 12: `--debug` and `--touch` by hand**

```bash
cd /c/Users/peixe/Documents/rpg-turnos
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --path . -- --debug
```

Start a new game. On the map, press F1: the debug panel opens. Press "Oro +100" and "Curar", then close the window. Expected in the console: `Depuración: ...` lines, one per button.

```bash
cd /c/Users/peixe/Documents/rpg-turnos
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --path . --resolution 740x360 -- --touch
```

Expected: the same layout as the `ref/phone/` screenshots. The title is at its phone sizes, the map shows the ☰ button and the use button, and a click on the ground walks there.

- [ ] **Step 13: `CLAUDE.md`**

In *Layout*, right after the line that starts with ``- `scripts/game/device.gd` (`Device`, `RefCounted`)``, insert:

```markdown
- `scripts/game/run_flags.gd` (`RunFlags`, `RefCounted`) — the only script of the game that reads the command line (`OS.get_cmdline_user_args()`, once, kept in a `static var`; the offline tools of `scripts/tools/` read their own): `autoplay()`, `autoplay_save()`, `autoplay_menu()` and `autoplay_easy()` (these three only with `--autoplay`), `autoplay_zone()` and `autoplay_companion()` (the text after `=`, "" when absent; `Game` keeps its default companion and checks the id), `debug()`, `touch()` (`Device.is_touch()` and `DisplaySettings` ask it). The web build gets no flags.
```

In *Conventions*, after the bullet that starts with `- No autoloads:`, insert:

```markdown
- Command-line flags are read only through `RunFlags` (`RunFlags.autoplay()`, `RunFlags.touch()`...); no other script calls `OS.get_cmdline_user_args()` or spells a `"--..."` string, except the offline tools of `scripts/tools/`.
```

- [ ] **Step 14: Commit**

```bash
cd /c/Users/peixe/Documents/rpg-turnos
git add scripts/game/run_flags.gd scripts/game/run_flags.gd.uid scripts/title/title_screen.gd scripts/game/game.gd scripts/game/device.gd scripts/ui/display_settings.gd scripts/game/save_store.gd scripts/ui/name_entry.gd scripts/story/cutscene_player.gd scripts/story/beyond_screen.gd scripts/ui/credits_screen.gd scripts/battle/battle_scene.gd scripts/ui/dialogue_box.gd scripts/world/player.gd scripts/audio/audio_director.gd scripts/world/world.gd scripts/ui/shop_window.gd scripts/ui/debug_panel.gd CLAUDE.md
git status --short
git commit -m "Read the command line only through RunFlags"
```

Expected: `git status --short` before the commit shows only the staged files above (`M ` / `A `) plus untracked plan files. If `--import` changed any other file (a `.import` or `.uid`), don't stage it: restore it with `git checkout -- <file>`.

---

### Task 3: `#region Autoplay` in six classes (M-74, part 2)

Declarations and functions move inside their own file and nothing in them changes. GDScript accepts class members in any order, so this changes no behaviour.

The rule, the same for the six files:
- The autoplay-only constants and variables go in one block `#region Autoplay` … `#endregion` at the end of the member declarations: after the last class-level `var`, before the first `func` or inner `class`.
- The autoplay-only functions go in one block `#region Autoplay` … `#endregion` at the end of the file.
- Each moved line keeps its own `##` comment.
- `if _autoplay:` branches inside shared functions stay where they are.

**Files:**
- Modify: `scripts/battle/battle_scene.gd`
- Modify: `scripts/ui/shop_window.gd`
- Modify: `scripts/world/player.gd`
- Modify: `scripts/ui/dialogue_box.gd`
- Modify: `scripts/ui/credits_screen.gd`
- Modify: `scripts/ui/name_entry.gd`
- Modify: `CLAUDE.md` (*Conventions*)

**Interfaces:**
- Consumes: `RunFlags.autoplay()` (Task 2), already in these files.
- Produces: no new names. The public functions `NameEntry.demo()`, `Player.restart_route()`, `Player.hunt()`, `Player.stop_hunt()`, `Player.is_hunting()`, `Player.hunting()`, `Player.take_failed_hunt()` and the public var `Player.route` keep their names and signatures (plan 3's `AutoplayHunter` and `World` call them).

- [ ] **Step 1: `BattleScene`**

In `scripts/battle/battle_scene.gd`, cut these members (with their comments):
- `const AUTOPLAY_EVERY` and `const AUTOPLAY_DEFEND_AT`, with the three-line comment `## Autoplay flees from normal battle number AUTOPLAY_EVERY...` above them;
- `static var _autoplay_battles`, with its comment `## Normal battles started on autoplay in this run...`;
- `var _autoplay`, `var _autoplay_flee`, `var _autoplay_defend` and `var _bot`.

Paste them after `var _helmet_id := ""`, after one blank line, as:

```gdscript
#region Autoplay
## Autoplay flees from normal battle number AUTOPLAY_EVERY, 2 × AUTOPLAY_EVERY... and
## defends in the first round of battle AUTOPLAY_DEFEND_AT, AUTOPLAY_DEFEND_AT +
## AUTOPLAY_EVERY...
const AUTOPLAY_EVERY := 5
const AUTOPLAY_DEFEND_AT := 2
## Normal battles started on autoplay in this run (for the flee and defend rules).
static var _autoplay_battles := 0
var _autoplay := false
var _autoplay_flee := false
var _autoplay_defend := false
var _bot := BattleAutoplay.new()
#endregion
```

Cut `func _autoplay_command() -> Dictionary:` and its body. Paste it at the end of the file, after the last function (`_fighter`) and two blank lines, wrapped as:

```gdscript
#region Autoplay
func _autoplay_command() -> Dictionary:
	if _autoplay_flee:
		return BattleEngine.cmd_flee()
	if _autoplay_defend:
		_autoplay_defend = false
		return BattleEngine.cmd_defend()
	return _bot.choose(engine)
#endregion
```

Leave the two blank lines between functions where the cut was, as the style guide wants.

- [ ] **Step 2: `ShopWindow`**

In `scripts/ui/shop_window.gd`, cut `const AUTOPLAY_STEP` with its comment `## Seconds each step stays on screen on autoplay.`, and `var _autoplay := false`. Paste them after `var _message: Label` (the last class-level var, before the inner `class Arrow`), after one blank line:

```gdscript
#region Autoplay
## Seconds each step stays on screen on autoplay.
const AUTOPLAY_STEP := 0.7
var _autoplay := false
#endregion
```

Cut `func _autoplay_run()` with its two-line comment (`## Autoplay: shows the first page, buys and equips each pick...`), and `func _wait()`. Paste both at the end of the file, after `_sfx` and two blank lines, inside `#region Autoplay` … `#endregion`, in that order, with two blank lines between them.

- [ ] **Step 3: `Player`**

In `scripts/world/player.gd`, cut these members (with their comments):
- `const ROUTE_REACHED`;
- `var route`, with its comment `## Points walked in a loop on --autoplay ...`;
- the two-line comment `## Autoplay: the group of monsters it walks to ...` with `var _hunt`, `var _hunting` and `var _failed_hunt_id`;
- `var _autoplay` and `var _route_index`.

Paste them after `var _gravity: float = ...` (the last class-level var), after one blank line:

```gdscript
#region Autoplay
const ROUTE_REACHED := 0.6
## Points walked in a loop on --autoplay (ZoneData.autoplay_route); set by World.
var route: Array[Vector3] = []
## Autoplay: the group of monsters it walks to instead of its route (World picks it with
## hunt()), and the id of one it gave up on (stuck on the way) until World takes it.
var _hunt: Node3D = null
var _hunting := false
var _failed_hunt_id := 0
var _autoplay := false
var _route_index := 0
#endregion
```

The functions `_route_direction`, `restart_route`, `hunt`, `stop_hunt`, `is_hunting`, `hunting`, `take_failed_hunt`, `_hunt_direction` and `_nearest_route_point` are already the last ones in the file, in that order. Insert a line `#region Autoplay` right before `func _route_direction() -> Vector3:`, and a line `#endregion` after the last line of `_nearest_route_point`.

- [ ] **Step 4: `DialogueBox`**

In `scripts/ui/dialogue_box.gd`, cut `const AUTOPLAY_DELAY := 0.8` and `var _autoplay := false`. Paste them after `var _blink_start := 0` (with its comment staying above it), after one blank line:

```gdscript
#region Autoplay
## Seconds each line stays on autoplay before the next.
const AUTOPLAY_DELAY := 0.8
var _autoplay := false
#endregion
```

The `##` line above `AUTOPLAY_DELAY` is the only new comment of this task. The constant had none, and inside a region it reads better with one. No function moves: the only autoplay code left is the branch inside `say()`.

- [ ] **Step 5: `CreditsScreen`**

In `scripts/ui/credits_screen.gd`, cut `const AUTOPLAY_END := 2.0` and `var _autoplay := false`. Paste them after `var _waiting := false` (now the last var), after one blank line:

```gdscript
#region Autoplay
## Seconds "Fin" stays on autoplay before the credits leave by themselves.
const AUTOPLAY_END := 2.0
var _autoplay := false
#endregion
```

No function moves.

- [ ] **Step 6: `NameEntry`**

In `scripts/ui/name_entry.gd`, cut `const DEMO_STEP := 0.15` with its comment `## --autoplay: seconds between two key presses of demo().`. Paste it after `var _done := false`, after one blank line:

```gdscript
#region Autoplay
## --autoplay: seconds between two key presses of demo().
const DEMO_STEP := 0.15
#endregion
```

Cut `func demo(hero_name: String)` with its two-line comment (`## --autoplay: types hero_name on the grid key by key ...`), and `func _demo_press(button: Button)`. Paste both at the end of the file, after `_sfx` and two blank lines, inside `#region Autoplay` … `#endregion`, with two blank lines between them.

- [ ] **Step 7: Only lines moved**

```bash
cd /c/Users/peixe/Documents/rpg-turnos
for f in scripts/battle/battle_scene.gd scripts/ui/shop_window.gd scripts/world/player.gd scripts/ui/dialogue_box.gd scripts/ui/credits_screen.gd scripts/ui/name_entry.gd; do echo "== $f"; diff <(git show HEAD:$f | grep -v '^\s*$' | sort) <(grep -v '^\s*$' $f | sort) | grep '^[<>]'; done
```

Expected, the lines under each header (in any order):
- `battle_scene.gd`, `shop_window.gd`, `player.gd`, `name_entry.gd`: `> #region Autoplay` twice and `> #endregion` twice.
- `dialogue_box.gd` and `credits_screen.gd`: `> #region Autoplay`, `> #endregion` and their one new `> ## ...` comment line.

There is never a `<` line. A `<` line means something was lost: put it back.

- [ ] **Step 8: Validate**

```bash
cd /c/Users/peixe/Documents/rpg-turnos
for s in battle/battle_scene ui/shop_window world/player ui/dialogue_box ui/credits_screen ui/name_entry; do echo "== $s"; APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --check-only --script res://scripts/$s.gd 2>&1 | grep -E 'ERROR|Parse Error|WARNING'; done
```

Expected: only the six headers, no error line.

If the parser refuses a `const` after a `var`, leave that file's constants where they were. Put the `#region Autoplay` … `#endregion` around the moved vars only, and write the exception in the commit message. Godot 4 accepts members in any order, so this should not happen.

- [ ] **Step 9: Autoplay runs**

Make the folder `C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/t3/`.

```bash
cd /c/Users/peixe/Documents/rpg-turnos
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . res://scenes/battle/battle_scene.tscn -- --autoplay > "C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/t3/battle.log" 2>&1
grep -E '^Fin del combate' "C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/t3/battle.log"
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --fixed-fps 10 --quit-after 150000 -- --autoplay > "C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/t3/v1.log" 2>&1
grep -cE '^Nombre: Rocío$' "C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/t3/v1.log"
grep -cE '^Créditos: ' "C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/t3/v1.log"; grep -cE '^Créditos: ' "C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/v1.log"
grep -cE '^Sorpresa: |^Huyes|^Narración: ' "C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/t3/v1.log"
```

Run the v1 in the background.

Expected:
- `Fin del combate (estado N)`;
- `1` (NameEntry);
- two equal numbers (the credits' headings);
- a number above 0 (the battle and dialogue prints).

Then run both checks of *How to compare* with REF = `ref/v1.log`, NEW = `t3/v1.log`. The v1 goes through every one of the six classes: the battles, the shops, the walking route, the dialogues, the name and the credits.

- [ ] **Step 10: `CLAUDE.md`**

In *Conventions*, after the `RunFlags` bullet added in Task 2, insert:

```markdown
- The autoplay part of a class sits together: its constants and variables in a `#region Autoplay` block at the end of the members, its autoplay-only functions in a `#region Autoplay` block at the end of the file (`BattleScene`, `ShopWindow`, `Player`, `DialogueBox`, `CreditsScreen`, `NameEntry`). `if _autoplay:` branches inside shared functions stay where they are. When a class's autoplay is big it gets its own piece instead (`BattleAutoplay`). No autoplay function is ever removed: autoplay is the project's way of checking the game.
```

- [ ] **Step 11: Commit**

```bash
cd /c/Users/peixe/Documents/rpg-turnos
git add scripts/battle/battle_scene.gd scripts/ui/shop_window.gd scripts/world/player.gd scripts/ui/dialogue_box.gd scripts/ui/credits_screen.gd scripts/ui/name_entry.gd CLAUDE.md
git commit -m "Group the autoplay code of six classes in #region Autoplay blocks"
```

---

### Task 4: `## Constructor:` headers and the three script kinds (M-73)

Only comments and `CLAUDE.md` change.

**Files:**
- Modify: `scripts/world/world_stage.gd`, `scripts/battle/battle_stage.gd`, `scripts/world/vegetation.gd`, `scripts/world/zone_particles.gd`, `scripts/battle/low_poly.gd`, `scripts/ui/ui_theme.gd`, `scripts/ui/ui_style.gd` (header comment)
- Modify: `CLAUDE.md` (*Conventions*)

**Interfaces:**
- Consumes: nothing.
- Produces: the header convention plan 2 follows for `CreatureBuilder` and `CharacterBuilder`: the first line under `class_name` is `## Constructor: static; builds ...`.

- [ ] **Step 1: The seven headers**

In each file, insert one line right after the `class_name ... extends RefCounted` line (line 1). The existing `##` paragraph stays as it is, under the new line.

`scripts/world/world_stage.gd`:

```gdscript
## Constructor: static; builds the nodes of one map under the root it is given and answers where things stand on it. Its static vars are caches of the last zone's layout (trees, chests), never game state.
```

`scripts/battle/battle_stage.gd`:

```gdscript
## Constructor: static; builds the nodes of a battle backdrop and its environment under the root it is given. Its static var plain_light is a setting DisplaySettings writes, not game state.
```

`scripts/world/vegetation.gd`:

```gdscript
## Constructor: static; builds the grass and flower MultiMesh nodes under the root it is given and returns their shared material. Its static var half_density is a setting DisplaySettings writes.
```

`scripts/world/zone_particles.gd`:

```gdscript
## Constructor: static; builds the particle node of a zone for its caller and moves it with follow(). Its static vars enabled and half are settings DisplaySettings writes.
```

`scripts/battle/low_poly.gd`:

```gdscript
## Constructor: static; builds meshes and MultiMesh nodes for its caller and keeps no state.
```

`scripts/ui/ui_theme.gd`:

```gdscript
## Constructor: static; builds the game's Theme, its styleboxes and fonts, and styles the controls it is given. Its static vars cache the fonts and the theme applied, never game state.
```

`scripts/ui/ui_style.gd`:

```gdscript
## Constructor: static; adds the shared small labels and finger-sized rows to the controls it is given and keeps no state.
```

- [ ] **Step 2: Only comments changed**

```bash
cd /c/Users/peixe/Documents/rpg-turnos
git diff -U0 -- scripts | grep '^[+-]' | grep -v '^+++\|^---' | grep -v '^+## Constructor: '
git diff --stat -- scripts
```

Expected: the first command prints nothing. The second shows `7 files changed, 7 insertions(+)`.

- [ ] **Step 3: Validate and a short run**

```bash
cd /c/Users/peixe/Documents/rpg-turnos
for s in world/world_stage battle/battle_stage world/vegetation world/zone_particles battle/low_poly ui/ui_theme ui/ui_style; do echo "== $s"; APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --check-only --script res://scripts/$s.gd 2>&1 | grep -E 'ERROR|Parse Error|WARNING'; done
mkdir -p "C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/t4"
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --fixed-fps 10 --quit-after 6000 -- --autoplay > "C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/t4/short.log" 2>&1
grep -E 'ERROR|WARNING' "C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/t4/short.log" | grep -v 'Jolt Physics job system exceeded'
grep -E '^Zona: pradera' "C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/t4/short.log" | head -1
```

Expected: only the seven headers with no error line, then nothing, then `Zona: pradera (Nv 1, 0:00:00)` or the same line with another time. Comments can't change behaviour, so no long run is needed.

- [ ] **Step 4: `CLAUDE.md` *Conventions***

Replace the bullet

```markdown
- Scenes and scripts are written as text. The `.tscn` files only hold the root node and its script; every other node (stage, UI, actors) is created in code.
```

with

```markdown
- Scenes and scripts are written as text. The `.tscn` files only hold the root node and its script; every other node (stage, UI, actors) is created in code. This is on purpose: the work is done without the editor, and a hand-written `.tscn` with dozens of nodes is more fragile than code. The Godot equivalent of small reusable scenes here is a node class with one job, created in code by its owner.
```

and replace the bullet

```markdown
- Game rules live in pure classes (`RefCounted` / `Resource`) that never touch nodes; scenes only play their results back.
```

with

```markdown
- Three kinds of script:
  - **Pure rules** (`RefCounted` / `Resource`) never touch nodes; scenes only play their results back.
  - **Constructors** are static, build nodes or render resources for their caller and keep no game state. Their header starts with `## Constructor:` and says what they build: `WorldStage`, `BattleStage`, `Vegetation`, `ZoneParticles`, `LowPoly`, `UiTheme`, `UiStyle`. Their `static var`s are settings that `DisplaySettings` writes, or caches. They stay `RefCounted`, with their names and folders.
  - **Nodes** are the scenes and the live pieces their owners create.
```

- [ ] **Step 5: Commit**

```bash
cd /c/Users/peixe/Documents/rpg-turnos
git add scripts/world/world_stage.gd scripts/battle/battle_stage.gd scripts/world/vegetation.gd scripts/world/zone_particles.gd scripts/battle/low_poly.gd scripts/ui/ui_theme.gd scripts/ui/ui_style.gd CLAUDE.md
git commit -m "Label the builder classes as constructors and name the three script kinds in CLAUDE.md"
```

---

### Task 5: The master document and the merge

**Files:**
- Modify: `docs/boost/documento-maestro.md` (the refactor row)
- Add: `docs/boost/plans/2026-11-14-refactor-1-runflags-builders.md` (this plan, untracked until now)

**Interfaces:**
- Consumes: Tasks 2-4 committed.
- Produces: rows M-70, M-71 and M-72 in state `spec`, which plans 2-4 move to `hecho`.

- [ ] **Step 1: Split the refactor row**

In `docs/boost/documento-maestro.md`, replace the row

```markdown
| Sin versión · M-70 a M-74 | Refactor de arquitectura sin cambios en el juego: trocear `Game`, `World` y `BattleActor`, etiquetar los constructores y juntar el piloto automático en `RunFlags` ([spec](specs/2026-11-14-refactor-arquitectura-design.md) · [guía](specs/2026-11-14-refactor-arquitectura-guia.md)) | spec |
```

with

```markdown
| Sin versión · M-70 | Refactor de arquitectura, sin cambios en el juego: trocear `Game` ([spec](specs/2026-11-14-refactor-arquitectura-design.md) · [guía](specs/2026-11-14-refactor-arquitectura-guia.md)) | spec |
| Sin versión · M-71 | Refactor de arquitectura: trocear `World` | spec |
| Sin versión · M-72 | Refactor de arquitectura: trocear `BattleActor` | spec |
| Sin versión · M-73 | Refactor de arquitectura: los constructores llevan `## Constructor:` y `CLAUDE.md` distingue reglas puras, constructores y nodos ([plan](plans/2026-11-14-refactor-1-runflags-builders.md)) | hecho |
| Sin versión · M-74 | Refactor de arquitectura: la línea de órdenes solo se lee en `RunFlags`, y el piloto automático de cada clase va en su `#region Autoplay` ([plan](plans/2026-11-14-refactor-1-runflags-builders.md)) | hecho |
```

- [ ] **Step 2: Commit**

```bash
cd /c/Users/peixe/Documents/rpg-turnos
git add docs/boost/documento-maestro.md docs/boost/plans/2026-11-14-refactor-1-runflags-builders.md
git commit -m "Mark M-73 and M-74 done in the master document"
git log --oneline develop..HEAD
```

Expected: four commits, newest first:
- `Mark M-73 and M-74 done in the master document`;
- `Label the builder classes as constructors and name the three script kinds in CLAUDE.md`;
- `Group the autoplay code of six classes in #region Autoplay blocks`;
- `Read the command line only through RunFlags`.

- [ ] **Step 3: Merge into `develop` (no push)**

```bash
cd /c/Users/peixe/Documents/rpg-turnos
git checkout develop
git merge --no-ff feature/refactor-1-runflags-builders -m "Merge feature/refactor-1-runflags-builders into develop"
git log --oneline -1
git status --short
```

Expected: the merge commit `Merge feature/refactor-1-runflags-builders into develop`. `git status --short` shows nothing but the untracked files of the other refactor plans, if there are any. Do not push. Keep `C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/`: plans 2-4 compare against it.
