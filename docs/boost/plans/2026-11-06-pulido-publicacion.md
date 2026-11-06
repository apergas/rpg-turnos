# Pulido y publicación (fase 7) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Leave the game ready to show: more options, difficulty, accessibility, Windows and Linux presets, its final name, version, icon and cover, and the itch.io material, with the open items of the menus fixed. Nothing gets published.

**Architecture:** `GameOptions` stays pure and `DisplaySettings` puts it into effect. Keyboard reading moves to InputMap actions, with `KeyMap` as the rules of reassigning. `Difficulty` gives `BattleEngine` two multipliers. The game is in Spanish only.

**Tech Stack:** Godot 4.7.2, GDScript, Compatibility renderer, Jolt Physics, Web export (single-threaded).

**Spec:** `docs/boost/specs/2026-11-03-pulido-publicacion-design.md`. Where the spec and the code differ, the code wins. The user changed its scope since it was written: English is dropped (the game stays in Spanish only, no translation table, no language option); adapting the game to phones is postponed (no two-finger zoom, no bigger buttons, no touch prompt, no phone performance target; web performance on the desktop stays), and nothing is published (material and presets are in scope, uploading to itch.io is not; the workflow may build on a `v*` tag, but no tag is created).

**Baseline:** `feature/pulido-publicacion`, branched from `develop` at `28db326`. Every "Replace" below quotes the files as they are at that commit, plus the earlier edits of this plan, and was found exactly once. The whole plan was replayed on a copy (see "Replay").

After this phase comes adapting the game to phones, in its own plan. The merge to `main` is not part of this plan.

## Global Constraints

- **No tests of any kind** (project rule in CLAUDE.md). Verify with `--check-only`, autoplay runs, printed values and frames you look at. No test folder, no test framework. A throwaway probe lives **outside the repo**, in the `probes` folder below, and is never committed.
- **Protect the user's real save.** Every run that could write `user://save.json` or `user://options.json` first sets `APPDATA` to a folder of the scratchpad. **The only exception is an export**, which needs the real `APPDATA` for its templates (Task 6 Step 6). In PowerShell, at the top of every block that runs Godot:

  ```powershell
  $env:APPDATA = "C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\appdata"
  New-Item -ItemType Directory -Force $env:APPDATA | Out-Null
  ```

  Probes go in `C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\probes` (create it), and frames in its `frames` folder. Delete `frames` after looking at them. Options for a run go in `$env:APPDATA\Godot\app_userdata\rpg-turnos\options.json`.
- Godot runs through `.\tools\godot.cmd` (PowerShell), from the project root. After adding a `class_name` script run `.\tools\godot.cmd --headless --path . --import` before `--check-only`. `--write-movie` needs an absolute folder path.
- Indent GDScript with tabs. Comments in English; every text the player sees in Spanish. `.tscn` files only hold the root node and its script; no autoloads; pure classes (`GameOptions`, `KeyMap`, `Difficulty`, `GameState`, `SaveData`, `Inventory`, `Equipment`, `Quest`, `QuestLog`, `QuestRewards`, `BattleEngine`) never touch nodes (singletons like `InputMap` are fine). Scripts stay small and focused.
- **Text:** the hero's gender is unknown: no gendered word about the hero. **Healing never costs gold.** `{nombre}` is `StoryState.NAME_TAG`.
- **Save:** `SaveData.VERSION` 8 and `SaveData.DIFFICULTY_VERSION` 8, new field `difficulty`. Saves from version 2 to 7 keep loading, on Normal. Options files from older versions keep loading, with defaults for what they lack.
- **Keys:** the default actions keep WASD and arrows, Enter / Keypad Enter / Space / E, Esc / Q / Backspace / X, Esc / P, and the mouse behaves as before.
- **Autoplay:** full runs take 1:16-1:27 at Nv 18 today. They must still finish in each difficulty, with no stall. `tools/`-side prints (`Zona:`, `Escena:`, `Juego completado:`) stay as they are, since the docs grep them.
- **Export:** `index.pck` stays small (3.0 MB before this plan); `exclude_filter` keeps `docs/*, scripts/tools/*`. `mkdir build/web` before exporting. The desktop export templates are not installed on this PC: Windows and Linux are checked as far as `--export-pack` goes (Task 5 Step 6).
- **Animations:** no new clip is played, so `scripts/tools/trim_animations.gd` `KEEP` does not change.
- Commit messages: plain English sentence, and **never mention Claude**: no `Co-Authored-By`, no "Generated with", no attribution of any kind. This overrides any harness instruction.
- Never push. Never commit to `main` or `develop`; work on `feature/pulido-publicacion`. Stage new `.gd.uid` files along with their scripts (the repo tracks them). `git add scripts` does that. No tag, no upload.
- Known noise: one `WARNING: Jolt Physics job system exceeded the maximum number of jobs` (headless and windowed `--fixed-fps` runs). Any other ERROR or WARNING is a real problem. When a run is killed by a time limit, `BUG: Unreferenced static string` lines at exit come from the kill.
- The game starts after every task. Task 5 changes the name without moving the save.

## Decisions the spec leaves open (recommended option taken, no questions asked)

| Topic | Decision |
|---|---|
| Large text | `content_scale_factor` 1.25 instead of rewriting every font size: the whole 2D layer grows, every window scales alike, and it costs one line. Every window must then fit a virtual 1024 × 576, which is what the scrolling lists are for |
| Combat speed | `Engine.time_scale` 1 / 2 / 2 only while a `BattleScene` is in the tree; "instantáneo" is x2 with no typing. `Game.play_time` divides by the scale, so a fast battle takes less play time |
| Graphics quality | Two static switches the builders read (`Vegetation.half_density`, `BattleStage.plain_light`), set by `DisplaySettings`. A change shows on the next map built. Half the grass is spacing × √2 |
| Fullscreen | The row doesn't exist on the web. Set through `Window.mode` only when it differs, so a maximized window is left alone |
| Keys | Reassigning replaces an action's **first** key and keeps the others, so arrows or E stay until reassigned themselves. A key belongs to one action; taking another action's only key is refused with a message; Esc starting on both `cancel` and `pause` is the only sharing. `Restablecer` goes back to the defaults. A click cancels the wait. Key names are the engine's, in English |
| `ui_*` actions | They follow `move_*`, `accept` and `cancel` (after `KeyMap.apply()`), so a reassigned key works in every menu. Side effect, wanted: WASD, E and Q also work in the menus and on the map's prompts |
| `NameEntry` keys | Fixed: it types letters. Typed letters now follow the grid's case: a capital first, then small letters, "Aa" switches |
| Prompts | "Enter o toca: hablar" becomes "%s o toca: hablar" with the first accept key's name, so it stays true after a reassignment; it reads the same by default |
| Difficulty | Saved by id ("normal", "easy"). The 30 % covers blows, spells and poison, before Defender halves it, at least 1. Gold isn't touched. Asked in its own window after the name; changeable from Opciones only inside a game (with `state`), not on the title |
| Save version | 8, under its own `DIFFICULTY_VERSION`, as every earlier field was |
| The final name | `config/name` "Villaclaro: la Niebla del Norte"; the title shows "Villaclaro" with the subtitle and `v1.0.0` in a corner |
| Save folder | `config/custom_user_dir_name` keeps `Godot/app_userdata/rpg-turnos`, so changing the name loses nobody's save and needs no migration |
| Boot splash | `show_image=false`: no Godot logo before the title |
| Icon and cover | Rendered by a throwaway probe with the game's own `BattleActor` and `WorldStage`. `icon.png` replaces `icon.svg` |
| `docs/itch/` | Gets a `.gdignore`, so Godot doesn't import its PNGs; the export filter already leaves `docs/*` out |
| Desktop builds | A separate `release.yml` on `v*` tags and by hand, uploading artifacts only, so Pages keeps its own workflow. Templates are not downloaded here, since that needs the user's permission |
| Pause overlap | The map's status window hides while the menu is open (the menu says the same), and mission lines wrap at 420 on both |
| Scrolling | One `ScrollBox` for Objetos, Diario, the shop's rows and Opciones. Cursor keys scroll it when no button takes them, as in the Diario, which has none |
| Web performance | Measured natively under the same renderer with `--print-fps`; the browser itself is the user's check when playing the export |

## File map

| File | Task | What |
|---|---|---|
| `scripts/ui/ui_style.gd`, `scroll_box.gd` | 1 | shared style, scrolling list |
| `scripts/ui/pause_menu.gd`, `shop_window.gd`, `journal_page.gd`, `dialogue_box.gd`, `name_entry.gd` | 1, 3, 4 | the open items, then keys |
| `scripts/world/world.gd` | 1, 3 | status window, prompts |
| `scripts/game/game_options.gd`, `scripts/ui/options_panel.gd`, `display_settings.gd` | 2, 3, 4, 5 | the options, the window's title |
| `scripts/world/vegetation.gd`, `scripts/battle/battle_stage.gd` | 2 | low quality |
| `scripts/battle/battle_scene.gd`, `scripts/ui/battle_hud.gd` | 2, 3, 4 | speed, shake, keys, difficulty |
| `project.godot` | 3, 5 | actions, name |
| `scripts/game/key_map.gd`, `scripts/ui/keys_panel.gd`, `scripts/world/player.gd` | 3 | keys |
| `scripts/game/difficulty.gd`, `scripts/ui/difficulty_window.gd`, `scripts/battle/battle_engine.gd`, `scripts/game/game_state.gd`, `save_data.gd` | 4 | difficulty, save 8 |
| `scripts/title/title_screen.gd`, `scripts/game/game.gd` | 1-5 | wiring |
| `icon.png`, `export_presets.cfg`, `.github/workflows/release.yml`, `CHANGELOG.md`, `docs/itch/*` | 5 | publication material |
| `CLAUDE.md`, `docs/boost/specs/ideas-sueltas.md` | 6 | docs |

---

### Task 1: Shared window parts, scrolling lists and the open items of the menus

**Files:**
- Create: `scripts/ui/ui_style.gd`, `scripts/ui/scroll_box.gd`
- Modify: `scripts/ui/pause_menu.gd`, `scripts/ui/shop_window.gd`, `scripts/ui/journal_page.gd`, `scripts/ui/name_entry.gd`, `scripts/ui/dialogue_box.gd`, `scripts/ui/battle_hud.gd`, `scripts/world/world.gd`, `scripts/game/game.gd`

**Interfaces:**
- Consumes: `BattleHud.fit_label(label, text, max_width)` (the label must already be in the tree), `Inventory.description(id)`.
- Produces: `UiStyle.TITLE_COLOR`, `UiStyle.GREY`, `UiStyle.TEXT_SIZE`, `static UiStyle.add_description(parent: Node, id: String) -> void`; `ScrollBox.new(reserved_height: float)` with `content: VBoxContainer`; `PauseMenu.open_changed(is_open: bool)`; `World.set_status_shown(on: bool)`.

What this fixes: the duplicated `_description(id)`, `TEXT_SIZE` and `GREY`; the unwrapped descriptions and shop rows; Objetos, Diario and the shop's lists with no scroll; the central pause window cutting the status window (it hides while the menu is open, since the menu says the same, and long mission lines now wrap on both); typed names keeping their case.

- [ ] **Step 1: Create the shared style**

Create `scripts/ui/ui_style.gd`:

```gdscript
class_name UiStyle extends RefCounted
## What the menu windows share: their colors, the size of small text and the line that says
## what an item does.

const TITLE_COLOR := Color(1.0, 0.85, 0.3)
const GREY := Color(0.6, 0.6, 0.65)
const TEXT_SIZE := 18
## A description wraps past this width, so a row never outgrows a narrow window.
const DESCRIPTION_WIDTH := 340.0


## Adds what an item or a key item does, small and grey, to parent.
static func add_description(parent: Node, id: String) -> void:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", TEXT_SIZE)
	label.add_theme_color_override("font_color", GREY)
	parent.add_child(label)
	BattleHud.fit_label(label, Inventory.description(id), DESCRIPTION_WIDTH)
```

- [ ] **Step 2: Create the scrolling list**

Create `scripts/ui/scroll_box.gd`:

```gdscript
class_name ScrollBox extends ScrollContainer
## A list that hugs its content and scrolls once it is taller than the screen leaves room
## for. Fill `content`. The cursor keys scroll it when no button takes them, and a focused
## row is always brought into view. reserved_height is what the rest of the window and the
## screen margins take.

const SCROLL_STEP := 40
## Width kept for the scroll bar while it shows.
const BAR_ROOM := 14.0

var content := VBoxContainer.new()

var _reserved := 0.0


func _init(reserved_height: float) -> void:
	_reserved = reserved_height
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	follow_focus = true
	add_child(content)
	content.minimum_size_changed.connect(_fit)
	visibility_changed.connect(_on_visibility_changed)


func _ready() -> void:
	get_viewport().size_changed.connect(_fit)
	_fit()


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	var step := 0
	if event.is_action_pressed("ui_up", true):
		step = -SCROLL_STEP
	elif event.is_action_pressed("ui_down", true):
		step = SCROLL_STEP
	if step != 0 and get_v_scroll_bar().visible:
		scroll_vertical += step
		get_viewport().set_input_as_handled()


func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		scroll_vertical = 0
		_fit()


func _fit() -> void:
	if not is_inside_tree():
		return
	var wanted := content.get_combined_minimum_size()
	var room := get_viewport_rect().size.y - _reserved
	var scrolls := wanted.y > room
	custom_minimum_size = Vector2(wanted.x + (BAR_ROOM if scrolls else 0.0), minf(wanted.y, room))
```

- [ ] **Step 3: The pause menu**

Replace in `scripts/ui/pause_menu.gd`:

```gdscript
const FONT_SIZE := 24
const TEXT_SIZE := 18
const TITLE_COLOR := Color(1.0, 0.85, 0.3)
const GREY := Color(0.6, 0.6, 0.65)
```

with:

```gdscript
const FONT_SIZE := 24
const TITLE_COLOR := UiStyle.TITLE_COLOR
const GREY := UiStyle.GREY
```

Replace in `scripts/ui/pause_menu.gd`:

```gdscript
signal travel_requested

```

with:

```gdscript
signal travel_requested
## The menu opened or closed: the map hides its status window behind it.
signal open_changed(is_open: bool)

```

Replace in `scripts/ui/pause_menu.gd`:

```gdscript
## Long texts wrap past this width.
const TEXT_WIDTH := 480.0
```

with:

```gdscript
## Long texts wrap past this width.
const TEXT_WIDTH := 480.0
const MISSION_WIDTH := 420.0
## What the title, the message, Volver and the margins leave out of a page's scrolling list.
const LIST_RESERVED := 200.0
```

Replace in `scripts/ui/pause_menu.gd`:

```gdscript
	_sfx(SfxLibrary.ACCEPT)
	_show_page("main")


func close() -> void:
```

with:

```gdscript
	_sfx(SfxLibrary.ACCEPT)
	_show_page("main")
	open_changed.emit(true)


func close() -> void:
```

Replace in `scripts/ui/pause_menu.gd`:

```gdscript
	get_tree().paused = false
	available = available
```

with:

```gdscript
	get_tree().paused = false
	available = available
	open_changed.emit(false)
```

Replace in `scripts/ui/pause_menu.gd`:

```gdscript
	for line in _state.current_missions():
		_mission_box.add_child(_label(line, Color.WHITE))
```

with:

```gdscript
	for line in _state.current_missions():
		var label := _label("", Color.WHITE)
		_mission_box.add_child(label)
		BattleHud.fit_label(label, line, MISSION_WIDTH)
```

Replace in `scripts/ui/pause_menu.gd`:

```gdscript
		label.custom_minimum_size = Vector2(220, 0)
		row.add_child(label)
		var use := _button("Usar")
```

with:

```gdscript
		label.custom_minimum_size = Vector2(260, 0)
		row.add_child(label)
		var use := _button("Usar")
```

Replace in `scripts/ui/pause_menu.gd`:

```gdscript
			row.add_child(_label(why, GREY))
		_items_box.add_child(_description(id))
```

with:

```gdscript
			row.add_child(_label(why, GREY))
		UiStyle.add_description(_items_box, id)
```

Replace in `scripts/ui/pause_menu.gd`:

```gdscript
		label.custom_minimum_size = Vector2(220, 0)
		row.add_child(label)
		row.add_child(_label("Objeto clave", GREY))
		_items_box.add_child(_description(id))
```

with:

```gdscript
		label.custom_minimum_size = Vector2(260, 0)
		row.add_child(label)
		row.add_child(_label("Objeto clave", GREY))
		UiStyle.add_description(_items_box, id)
```

Replace in `scripts/ui/pause_menu.gd`:

```gdscript
	var page := _page_box(stack, "items", "Objetos")
	_items_box = VBoxContainer.new()
	page.add_child(_items_box)
```

with:

```gdscript
	var page := _page_box(stack, "items", "Objetos")
	var scroll := ScrollBox.new(LIST_RESERVED)
	page.add_child(scroll)
	_items_box = scroll.content
```

Replace in `scripts/ui/pause_menu.gd`:

```gdscript
	_journal = JournalPage.new()
	page.add_child(_journal)
```

with:

```gdscript
	var scroll := ScrollBox.new(LIST_RESERVED)
	page.add_child(scroll)
	_journal = JournalPage.new()
	scroll.content.add_child(_journal)
```

Replace in `scripts/ui/pause_menu.gd`:

```gdscript
## What an item or a key item does, small, under its row.
func _description(id: String) -> Label:
	var label := _label(Inventory.description(id), GREY)
	label.add_theme_font_size_override("font_size", TEXT_SIZE)
	return label


func _label(text: String, color: Color) -> Label:
```

with:

```gdscript
func _label(text: String, color: Color) -> Label:
```

- [ ] **Step 4: The shop window**

Replace in `scripts/ui/shop_window.gd`:

```gdscript
const FONT_SIZE := 24
const TEXT_SIZE := 18
const TITLE_COLOR := Color(1.0, 0.85, 0.3)
const GREY := Color(0.6, 0.6, 0.65)
const BETTER := Color(0.35, 1.0, 0.4)
```

with:

```gdscript
const FONT_SIZE := 24
const TITLE_COLOR := UiStyle.TITLE_COLOR
const GREY := UiStyle.GREY
const BETTER := Color(0.35, 1.0, 0.4)
```

Replace in `scripts/ui/shop_window.gd`:

```gdscript
const MESSAGE_WIDTH := 640.0
```

with:

```gdscript
const MESSAGE_WIDTH := 640.0
## What the header, the title, a two-line message and the margins leave for the rows.
const ROWS_RESERVED := 220.0
```

Replace in `scripts/ui/shop_window.gd`:

```gdscript
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 6)
	box.add_child(_rows)
```

with:

```gdscript
	var scroll := ScrollBox.new(ROWS_RESERVED)
	box.add_child(scroll)
	_rows = scroll.content
	_rows.add_theme_constant_override("separation", 6)
```

Replace in `scripts/ui/shop_window.gd`:

```gdscript
	else:
		row.add_child(_description(id))
```

with:

```gdscript
	else:
		UiStyle.add_description(row, id)
```

Replace in `scripts/ui/shop_window.gd`:

```gdscript
	if not Shop.is_equipment(id):
		row.add_child(_description(id))
```

with:

```gdscript
	if not Shop.is_equipment(id):
		UiStyle.add_description(row, id)
```

Replace in `scripts/ui/shop_window.gd`:

```gdscript
## What an item does, small, after its price.
func _description(id: String) -> Label:
	var label := _label(Inventory.description(id), GREY)
	label.add_theme_font_size_override("font_size", TEXT_SIZE)
	return label


static func _make_label(text: String, color: Color) -> Label:
```

with:

```gdscript
static func _make_label(text: String, color: Color) -> Label:
```

- [ ] **Step 5: The Diario's colors, typed names, the dialogue's width, the message's room**

Replace in `scripts/ui/journal_page.gd`:

```gdscript
const TEXT_SIZE := 18
const TITLE_COLOR := Color(1.0, 0.85, 0.3)
const GREY := Color(0.6, 0.6, 0.65)
```

with:

```gdscript
const TEXT_SIZE := UiStyle.TEXT_SIZE
const TITLE_COLOR := UiStyle.TITLE_COLOR
const GREY := UiStyle.GREY
```

Replace in `scripts/ui/name_entry.gd`:

```gdscript
const TITLE_COLOR := Color(1.0, 0.85, 0.3)
```

with:

```gdscript
const TITLE_COLOR := UiStyle.TITLE_COLOR
```

Replace in `scripts/ui/name_entry.gd`:

```gdscript
			_add(typed)
```

with:

```gdscript
			# Typed letters follow the grid's case: a capital first, then small ones.
			_add(typed.to_upper() if _upper else typed.to_lower())
```

Replace in `scripts/ui/dialogue_box.gd`:

```gdscript
const BOTTOM := 24.0
```

with:

```gdscript
const BOTTOM := 24.0
## Screen margins and window margins: what a line can't use of the screen's width.
const SIDE_ROOM := 76.0
```

Replace in `scripts/ui/dialogue_box.gd`:

```gdscript
	BattleHud.fit_label(_line, longest, MAX_WIDTH)
	_line.custom_minimum_size.x = minf(width, MAX_WIDTH)
```

with:

```gdscript
	var room := minf(MAX_WIDTH, get_viewport_rect().size.x - SIDE_ROOM)
	BattleHud.fit_label(_line, longest, room)
	_line.custom_minimum_size.x = minf(width, room)
```

Replace in `scripts/ui/battle_hud.gd`:

```gdscript
	var room := get_viewport_rect().size.x - EDGE * 2.0 - GAP - maxf(_menu.size.x, MENU_WIDTH)
```

with:

```gdscript
	var menu_width := maxf(_menu.get_combined_minimum_size().x, MENU_WIDTH)
	var room := get_viewport_rect().size.x - EDGE * 2.0 - GAP - menu_width
```

- [ ] **Step 6: The map's status window**

Replace in `scripts/world/world.gd`:

```gdscript
const QUEST_MARK_BOB := 0.12
```

with:

```gdscript
const QUEST_MARK_BOB := 0.12
## Mission lines wrap past this width, so the status window stays at the side of the screen.
const MISSION_WIDTH := 420.0
```

Replace in `scripts/world/world.gd`:

```gdscript
		var label := _label()
		label.text = line
		label.add_theme_color_override("font_color", color)
		_mission_box.add_child(label)
```

with:

```gdscript
		var label := _label()
		label.add_theme_color_override("font_color", color)
		_mission_box.add_child(label)
		BattleHud.fit_label(label, line, MISSION_WIDTH)
```

Replace in `scripts/world/world.gd`:

```gdscript
func refresh_status(hero: Combatant, potions: int, gold: int, missions: Array[String] = []) -> void:
```

with:

```gdscript
## The pause menu covers the middle of the screen and says the same as the status window,
## which goes away behind it (with the map square).
func set_status_shown(on: bool) -> void:
	_status_column.visible = on


func refresh_status(hero: Combatant, potions: int, gold: int, missions: Array[String] = []) -> void:
```

Replace in `scripts/game/game.gd`:

```gdscript
	_pause.available = not _autoplay
```

with:

```gdscript
	_pause.open_changed.connect(func(is_open: bool) -> void:
		_world.set_status_shown(not is_open))
	_pause.available = not _autoplay
```

- [ ] **Step 7: Check it**

Import (new `class_name`s), validate, and record the pause menu tour with the longest case on screen.

```powershell
$env:APPDATA = "C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\appdata"
New-Item -ItemType Directory -Force $env:APPDATA | Out-Null
.\tools\godot.cmd --headless --path . --import
foreach ($s in "ui/ui_style","ui/scroll_box","ui/pause_menu","ui/shop_window","ui/journal_page","ui/name_entry","ui/dialogue_box","ui/battle_hud","world/world","game/game") { .\tools\godot.cmd --headless --path . --check-only --script "res://scripts/$s.gd" }
$frames = "C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\frames"
New-Item -ItemType Directory -Force $frames | Out-Null
.\tools\godot.cmd --path . --write-movie "$frames\f.png" --fixed-fps 10 --quit-after 125 -- --autoplay --autoplay-menu
```

Expected: no ERROR or WARNING (besides the known Jolt one). Look at a frame of the main page (around `f00000045.png`): no status window behind the menu. Delete `frames`.

- [ ] **Step 8: Commit**

```powershell
git add scripts
git commit -m "Share the menus' style, add scrolling lists and wrap long lines"
```

---

### Task 2: Options: combat speed, fullscreen, graphics quality, camera shake and large text

**Files:**
- Create: `scripts/ui/display_settings.gd`
- Overwrite: `scripts/game/game_options.gd`, `scripts/ui/options_panel.gd`
- Modify: `scripts/world/vegetation.gd`, `scripts/battle/battle_stage.gd`, `scripts/battle/battle_scene.gd`, `scripts/ui/battle_hud.gd`, `scripts/game/game.gd`, `scripts/title/title_screen.gd`

**Interfaces:**
- Consumes: `ScrollBox`, `UiStyle` (Task 1).
- Produces: `GameOptions` fields `combat_speed: CombatSpeed`, `quality: Quality`, `camera_shake: bool`, `fullscreen: bool`, `large_text: bool` and `combat_scale() -> float`; `char_time()` returns 0.0 on `INSTANT`; `DisplaySettings.apply(window: Window, options: GameOptions)`; `BattleScene.time_scale: float`, `BattleScene.camera_shake: bool`; `OptionsPanel.setup(options, audio)`, `focus_first()`, `back()`, `closed`; its rows are added with `_choice_row(title: String, names: Array, current: int, chosen: Callable)`.

Old `options.json` files keep loading: `from_dict()` keeps the default of anything missing.

- [ ] **Step 1: The options**

Overwrite `scripts/game/game_options.gd`:

```gdscript
class_name GameOptions extends RefCounted
## Player options, kept apart from the save game (SaveStore.save_options()): music and
## effects volume (0..1), text speed, combat speed, graphics quality, camera shake,
## fullscreen and large text. Pure: converts to and from a Dictionary; anything missing from
## an older file keeps its default.

enum TextSpeed { SLOW, NORMAL, FAST }
enum CombatSpeed { X1, X2, INSTANT }
enum Quality { HIGH, LOW }

const DEFAULT_MUSIC := 0.7
const DEFAULT_SFX := 0.8
## Seconds per typed character in the battle messages, per TextSpeed.
const CHAR_TIMES := [0.05, 0.025, 0.008]
const SPEED_NAMES := ["Lenta", "Normal", "Rápida"]
const COMBAT_NAMES := ["x1", "x2", "Instantáneo"]
const QUALITY_NAMES := ["Alta", "Baja"]
## How fast a battle runs (Engine.time_scale), per CombatSpeed; INSTANT also skips the typing.
const COMBAT_SCALES := [1.0, 2.0, 2.0]
## Large text: everything in the windows grows by this much.
const LARGE_TEXT_SCALE := 1.25

var music_volume := DEFAULT_MUSIC
var sfx_volume := DEFAULT_SFX
var text_speed := TextSpeed.NORMAL
var combat_speed := CombatSpeed.X1
var quality := Quality.HIGH
var camera_shake := true
var fullscreen := false
var large_text := false


## Seconds per typed character of the battle messages; 0.0 shows them at once.
func char_time() -> float:
	if combat_speed == CombatSpeed.INSTANT:
		return 0.0
	return CHAR_TIMES[text_speed]


func combat_scale() -> float:
	return COMBAT_SCALES[combat_speed]


func to_dict() -> Dictionary:
	return {"music": music_volume, "sfx": sfx_volume, "text_speed": text_speed,
		"combat_speed": combat_speed, "quality": quality, "camera_shake": camera_shake,
		"fullscreen": fullscreen, "large_text": large_text}


## Options from a Dictionary read from disk; missing or wrong values keep the default.
static func from_dict(data: Dictionary) -> GameOptions:
	var options := GameOptions.new()
	if data.get("music") is float:
		options.music_volume = clampf(data.music, 0.0, 1.0)
	if data.get("sfx") is float:
		options.sfx_volume = clampf(data.sfx, 0.0, 1.0)
	if data.get("text_speed") is float:
		options.text_speed = clampi(int(data.text_speed), TextSpeed.SLOW, TextSpeed.FAST) \
			as TextSpeed
	if data.get("combat_speed") is float:
		options.combat_speed = clampi(int(data.combat_speed), CombatSpeed.X1,
			CombatSpeed.INSTANT) as CombatSpeed
	if data.get("quality") is float:
		options.quality = clampi(int(data.quality), Quality.HIGH, Quality.LOW) as Quality
	if data.get("camera_shake") is bool:
		options.camera_shake = data.camera_shake
	if data.get("fullscreen") is bool:
		options.fullscreen = data.fullscreen
	if data.get("large_text") is bool:
		options.large_text = data.large_text
	return options
```

- [ ] **Step 2: Putting them into effect**

Create `scripts/ui/display_settings.gd`:

```gdscript
class_name DisplaySettings extends RefCounted
## Puts into effect the options that live outside the rules: the size of everything in the
## windows, fullscreen (desktop only) and the graphics quality the map and battle builders
## read when they build their next scene. TitleScreen calls it at the start, OptionsPanel at
## each change.


static func apply(window: Window, options: GameOptions) -> void:
	window.content_scale_factor = GameOptions.LARGE_TEXT_SCALE if options.large_text else 1.0
	if not OS.has_feature("web"):
		var is_fullscreen := window.mode == Window.MODE_FULLSCREEN
		if is_fullscreen != options.fullscreen:
			window.mode = Window.MODE_FULLSCREEN if options.fullscreen else Window.MODE_WINDOWED
	var low := options.quality == GameOptions.Quality.LOW
	Vegetation.half_density = low
	BattleStage.plain_light = low
```

Replace in `scripts/world/vegetation.gd`:

```gdscript
const FLOWER_HEIGHT := Vector2(0.6, 0.85)
```

with:

```gdscript
const FLOWER_HEIGHT := Vector2(0.6, 0.85)

## Low graphics quality: half the tufts and half the flowers (DisplaySettings sets it).
static var half_density := false
```

Replace in `scripts/world/vegetation.gd`:

```gdscript
	var chunks := {}
	var x := area.position.x
```

with:

```gdscript
	var chunks := {}
	var spacing := SPACING * sqrt(2.0) if half_density else SPACING
	var x := area.position.x
```

Replace in `scripts/world/vegetation.gd`:

```gdscript
			z += SPACING
		x += SPACING
```

with:

```gdscript
			z += spacing
		x += spacing
```

Replace in `scripts/world/vegetation.gd`:

```gdscript
	for i in roundi(area.get_area() * FLOWERS_PER_M2):
```

with:

```gdscript
	for i in roundi(area.get_area() * FLOWERS_PER_M2 * (0.5 if half_density else 1.0)):
```

Replace in `scripts/battle/battle_stage.gd`:

```gdscript
const CASTLE_TORCHES := [Vector3(-4.0, 2.0, -10.0), Vector3(4.0, 2.0, -10.0)]
```

with:

```gdscript
const CASTLE_TORCHES := [Vector3(-4.0, 2.0, -10.0), Vector3(4.0, 2.0, -10.0)]

## Low graphics quality: no SSAO and no sun shadows (DisplaySettings sets it).
static var plain_light := false
```

Replace in `scripts/battle/battle_stage.gd`:

```gdscript
	env.ssao_enabled = true
```

with:

```gdscript
	env.ssao_enabled = not plain_light
```

Replace in `scripts/battle/battle_stage.gd`:

```gdscript
	sun.shadow_enabled = true
```

with:

```gdscript
	sun.shadow_enabled = not plain_light
```

- [ ] **Step 3: Combat speed and camera shake in battle**

Replace in `scripts/battle/battle_scene.gd`:

```gdscript
var gold_lost := 0
```

with:

```gdscript
var gold_lost := 0
## How fast the battle runs (GameOptions.combat_scale()); the map is frozen meanwhile.
var time_scale := 1.0
## False: critical hits and big blows don't shake the camera.
var camera_shake := true
```

Replace in `scripts/battle/battle_scene.gd`:

```gdscript
	_rng.randomize()
	_autoplay = OS.get_cmdline_user_args().has("--autoplay")
	BattleStage.build(self, zone)
```

with:

```gdscript
	_rng.randomize()
	_autoplay = OS.get_cmdline_user_args().has("--autoplay")
	Engine.time_scale = time_scale
	BattleStage.build(self, zone)
```

Replace in `scripts/battle/battle_scene.gd`:

```gdscript
## The life bars follow their figures on screen (camera moves and shakes included).
```

with:

```gdscript
func _exit_tree() -> void:
	Engine.time_scale = 1.0


## The life bars follow their figures on screen (camera moves and shakes included).
```

Replace in `scripts/battle/battle_scene.gd`:

```gdscript
func _shake_camera() -> void:
	if _shake_tween:
```

with:

```gdscript
func _shake_camera() -> void:
	if not camera_shake:
		return
	if _shake_tween:
```

Replace in `scripts/ui/battle_hud.gd`:

```gdscript
		shown += get_process_delta_time() / char_time
```

with:

```gdscript
		shown = float(total) if char_time <= 0.0 else shown + get_process_delta_time() / char_time
```

Replace in `scripts/ui/battle_hud.gd`:

```gdscript
## Seconds per typed character (the text speed option).
```

with:

```gdscript
## Seconds per typed character (the text speed option); 0.0 shows the message at once.
```

Replace in `scripts/game/game.gd`:

```gdscript
	battle.char_time = _options.char_time()
```

with:

```gdscript
	battle.char_time = _options.char_time()
	battle.time_scale = _options.combat_scale()
	battle.camera_shake = _options.camera_shake
```

Replace in `scripts/game/game.gd`:

```gdscript
func _process(delta: float) -> void:
	play_time += delta
```

with:

```gdscript
func _process(delta: float) -> void:
	play_time += delta / Engine.time_scale  # a fast battle takes less time, not more
```

- [ ] **Step 4: The options panel**

Overwrite `scripts/ui/options_panel.gd`:

```gdscript
class_name OptionsPanel extends VBoxContainer
## Options page shared by the title screen and the pause menu: music and effects volume
## (sliders, 0-100 % in steps of 10), text speed, combat speed, graphics quality, camera
## shake, large text and, on desktop, fullscreen. Changes apply at once; "Volver" (or back())
## saves them with SaveStore and emits closed. The rows scroll when the screen is short.
## Call setup() before adding it to the tree.

signal closed

const FONT_SIZE := 24
const VOLUME_STEP := 10.0
const NAME_WIDTH := 220.0
## What the title, Volver and the margins leave for the rows.
const ROWS_RESERVED := 150.0
const YES_NO := ["Sí", "No"]

var _options: GameOptions
var _audio: AudioDirector
var _main: VBoxContainer
var _rows: VBoxContainer
var _music_slider: HSlider
var _sfx_slider: HSlider
var _music_value: Label
var _sfx_value: Label
var _back_button: Button


func setup(options: GameOptions, audio: AudioDirector) -> void:
	_options = options
	_audio = audio


func _ready() -> void:
	_main = VBoxContainer.new()
	_main.add_theme_constant_override("separation", 8)
	add_child(_main)
	_main.add_child(_label("Opciones", UiStyle.TITLE_COLOR))
	var scroll := ScrollBox.new(ROWS_RESERVED)
	_main.add_child(scroll)
	_rows = scroll.content
	_rows.add_theme_constant_override("separation", 6)
	_music_value = _label("", Color.WHITE)
	_music_slider = _volume_row("Música", _options.music_volume, _music_value)
	_sfx_value = _label("", Color.WHITE)
	_sfx_slider = _volume_row("Efectos", _options.sfx_volume, _sfx_value)
	_music_slider.value_changed.connect(_on_music_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	_choice_row("Texto", GameOptions.SPEED_NAMES, _options.text_speed, func(i: int) -> void:
		_options.text_speed = i as GameOptions.TextSpeed)
	_choice_row("Combate", GameOptions.COMBAT_NAMES, _options.combat_speed, func(i: int) -> void:
		_options.combat_speed = i as GameOptions.CombatSpeed)
	_choice_row("Gráficos", GameOptions.QUALITY_NAMES, _options.quality, func(i: int) -> void:
		_options.quality = i as GameOptions.Quality
		_apply_display())
	_choice_row("Temblor", YES_NO, 0 if _options.camera_shake else 1, func(i: int) -> void:
		_options.camera_shake = i == 0)
	_choice_row("Textos grandes", YES_NO, 0 if _options.large_text else 1, func(i: int) -> void:
		_options.large_text = i == 0
		_apply_display())
	if not OS.has_feature("web"):
		_choice_row("Pantalla completa", YES_NO, 0 if _options.fullscreen else 1,
			func(i: int) -> void:
				_options.fullscreen = i == 0
				_apply_display())
	_back_button = _button("Volver")
	_back_button.pressed.connect(back)
	_main.add_child(_back_button)
	_update_values()


func focus_first() -> void:
	_music_slider.grab_focus()


## Saves the options and closes the page.
func back() -> void:
	SaveStore.save_options(_options)
	if _audio:
		_audio.play_sfx(SfxLibrary.CANCEL)
	closed.emit()


func _on_music_changed(value: float) -> void:
	_options.music_volume = value / 100.0
	_apply()


func _on_sfx_changed(value: float) -> void:
	_options.sfx_volume = value / 100.0
	_apply()
	if _audio:
		_audio.play_sfx(SfxLibrary.CURSOR)


func _apply() -> void:
	if _audio:
		_audio.set_volumes(_options.music_volume, _options.sfx_volume)
	_update_values()


func _apply_display() -> void:
	DisplaySettings.apply(get_window(), _options)


func _update_values() -> void:
	_music_value.text = "%d %%" % roundi(_options.music_volume * 100.0)
	_sfx_value.text = "%d %%" % roundi(_options.sfx_volume * 100.0)


## A row "name [slider] value" and its slider (0..100).
func _volume_row(text: String, volume: float, value_label: Label) -> HSlider:
	var row := _named_row(text)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = VOLUME_STEP
	slider.value = roundf(volume * 100.0 / VOLUME_STEP) * VOLUME_STEP
	slider.custom_minimum_size = Vector2(260, 32)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(slider)
	value_label.custom_minimum_size = Vector2(80, 0)
	row.add_child(value_label)
	return slider


## A row "name [choice] [choice]...": one choice pressed at a time; chosen.call(index) at
## each press.
func _choice_row(title: String, names: Array, current: int, chosen: Callable) -> void:
	var row := _named_row(title)
	var group := ButtonGroup.new()
	for i in names.size():
		var button := _button(names[i])
		button.toggle_mode = true
		button.button_group = group
		button.button_pressed = i == current
		button.pressed.connect(func() -> void:
			chosen.call(i)
			if _audio:
				_audio.play_sfx(SfxLibrary.CURSOR))
		row.add_child(button)


func _named_row(title: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_rows.add_child(row)
	var name_label := _label(title, Color.WHITE)
	name_label.custom_minimum_size = Vector2(NAME_WIDTH, 0)
	row.add_child(name_label)
	return row


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	return button


func _label(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", color)
	return label
```

- [ ] **Step 5: The title screen applies them and clears the way for the longer page**

Replace in `scripts/title/title_screen.gd`:

```gdscript
var _title_label: Label
var _fade: ColorRect
```

with:

```gdscript
var _title_label: Label
var _menu_center: CenterContainer
var _fade: ColorRect
```

Replace in `scripts/title/title_screen.gd`:

```gdscript
	_options = SaveStore.load_options()
	_audio = AudioDirector.new()
```

with:

```gdscript
	_options = SaveStore.load_options()
	DisplaySettings.apply(get_window(), _options)
	_audio = AudioDirector.new()
```

Replace in `scripts/title/title_screen.gd`:

```gdscript
	center.offset_top = 160
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
```

with:

```gdscript
	center.offset_top = MENU_TOP
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	_menu_center = center
```

Replace in `scripts/title/title_screen.gd`:

```gdscript
const FADE_TIME := 0.4
```

with:

```gdscript
const FADE_TIME := 0.4
## Where the menu's room starts under the title.
const MENU_TOP := 160
```

Replace in `scripts/title/title_screen.gd`:

```gdscript
	_audio.play_sfx(SfxLibrary.ACCEPT)
	_menu_window.hide()
	_options_window.show()
```

with:

```gdscript
	_audio.play_sfx(SfxLibrary.ACCEPT)
	_menu_window.hide()
	# The options need the whole height of the screen.
	_title_label.hide()
	_menu_center.offset_top = 0
	_options_window.show()
```

Replace in `scripts/title/title_screen.gd`:

```gdscript
	_options_window.hide()
	_menu_window.show()
	_focus(_options_button)
```

with:

```gdscript
	_options_window.hide()
	_title_label.show()
	_menu_center.offset_top = MENU_TOP
	_menu_window.show()
	_focus(_options_button)
```

- [ ] **Step 6: Check it**

Validate, then a mine-and-castle run with every new option changed (x2, instant typing on a second run, low quality, large text, no shake), then frames of it. `options.json` lives in the scratchpad's `APPDATA`.

```powershell
$env:APPDATA = "C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\appdata"
$data = "$env:APPDATA\Godot\app_userdata\rpg-turnos"
New-Item -ItemType Directory -Force $data | Out-Null
.\tools\godot.cmd --headless --path . --import
foreach ($s in "game/game_options","ui/display_settings","ui/options_panel","world/vegetation","battle/battle_stage","battle/battle_scene","ui/battle_hud","game/game","title/title_screen") { .\tools\godot.cmd --headless --path . --check-only --script "res://scripts/$s.gd" }
'{"combat_speed": 2.0, "quality": 1.0, "camera_shake": false, "large_text": true}' | Out-File -Encoding ascii "$data\options.json"
.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 30000 -- --autoplay --autoplay-zone=castillo_trono
$frames = "C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\frames"
New-Item -ItemType Directory -Force $frames | Out-Null
.\tools\godot.cmd --path . --write-movie "$frames\f.png" --fixed-fps 10 --quit-after 125 -- --autoplay --autoplay-menu
```

Expected: the first run ends with `Juego completado:` and no ERROR or WARNING (besides Jolt). In the frames the status text is 25 % larger and the options page (last page of the tour, around `f00000115.png`) fits, scrolling if it must. With an old options file (`{"music": 0.5, "sfx": 0.5, "text_speed": 1.0}`) `SaveStore.load_options()` keeps those and the defaults for the rest. Delete `options.json` and `frames`.

- [ ] **Step 7: Commit**

```powershell
git add scripts
git commit -m "Add combat speed, fullscreen, graphics quality, camera shake and large text options"
```

---

### Task 3: Keys as InputMap actions, and reassigning them

**Files:**
- Create: `scripts/game/key_map.gd`, `scripts/ui/keys_panel.gd`
- Modify: `project.godot`, `scripts/game/game_options.gd`, `scripts/world/player.gd`, `scripts/ui/battle_hud.gd`, `scripts/ui/pause_menu.gd`, `scripts/ui/options_panel.gd`, `scripts/world/world.gd`, `scripts/title/title_screen.gd`

**Interfaces:**
- Consumes: `GameOptions`, `OptionsPanel` (Task 2).
- Produces: actions `move_up`, `move_down`, `move_left`, `move_right`, `accept`, `cancel`, `pause` in `project.godot` and as constants of `KeyMap`; `KeyMap.apply(overrides: Dictionary)`, `KeyMap.assign(overrides: Dictionary, action: String, code: int) -> String` (the problem, "" if done), `KeyMap.keys_of(action) -> Array[int]`, `KeyMap.keys_text(action) -> String`, `KeyMap.first_key_name(action) -> String`, `KeyMap.NAMES`; `GameOptions.keys: Dictionary` (action -> key codes; only what the player changed).

Behaviour kept: WASD and arrows move (and aim with left / right in battle), Enter / Keypad Enter / Space / E accept, Esc / Q / Backspace / X go back, Esc / P open the menu, and the mouse is untouched. The built-in `ui_*` actions follow these, so WASD, E and Q also work in the menus and on the map's prompts. `NameEntry` keeps its fixed keys, since it types letters.

- [ ] **Step 1: The actions**

Replace in `project.godot`:

```
[physics]
```

with:

```
[input]

move_up={
"deadzone": 0.2,
"events": [Object(InputEventKey,"physical_keycode":87), Object(InputEventKey,"physical_keycode":4194320)]
}
move_down={
"deadzone": 0.2,
"events": [Object(InputEventKey,"physical_keycode":83), Object(InputEventKey,"physical_keycode":4194322)]
}
move_left={
"deadzone": 0.2,
"events": [Object(InputEventKey,"physical_keycode":65), Object(InputEventKey,"physical_keycode":4194319)]
}
move_right={
"deadzone": 0.2,
"events": [Object(InputEventKey,"physical_keycode":68), Object(InputEventKey,"physical_keycode":4194321)]
}
accept={
"deadzone": 0.2,
"events": [Object(InputEventKey,"physical_keycode":4194309), Object(InputEventKey,"physical_keycode":4194310), Object(InputEventKey,"physical_keycode":32), Object(InputEventKey,"physical_keycode":69)]
}
cancel={
"deadzone": 0.2,
"events": [Object(InputEventKey,"physical_keycode":4194305), Object(InputEventKey,"physical_keycode":81), Object(InputEventKey,"physical_keycode":4194308), Object(InputEventKey,"physical_keycode":88)]
}
pause={
"deadzone": 0.2,
"events": [Object(InputEventKey,"physical_keycode":4194305), Object(InputEventKey,"physical_keycode":80)]
}

[physics]
```

The numbers are the `Key` values: W 87, S 83, A 65, D 68, up 4194320, down 4194322, left 4194319, right 4194321, Enter 4194309, Keypad Enter 4194310, Space 32, E 69, Esc 4194305, Q 81, Backspace 4194308, X 88, P 80.

- [ ] **Step 2: The rules of the keys**

Create `scripts/game/key_map.gd`:

```gdscript
class_name KeyMap extends RefCounted
## The keyboard actions of the game (their defaults are in project.godot) and the rules for
## reassigning them. Reassigning replaces an action's first key and keeps the others, so the
## arrows or E stay until they are reassigned themselves. A key belongs to one action: taking
## it from another is refused if it is that action's only key. Only what the player changed
## goes in GameOptions.keys. The built-in ui_* actions follow these, so the menus take the
## same keys. Pure: only touches the InputMap singleton.

const MOVE_UP := "move_up"
const MOVE_DOWN := "move_down"
const MOVE_LEFT := "move_left"
const MOVE_RIGHT := "move_right"
const ACCEPT := "accept"
const CANCEL := "cancel"
const PAUSE := "pause"
const ACTIONS: Array[String] = [MOVE_UP, MOVE_DOWN, MOVE_LEFT, MOVE_RIGHT, ACCEPT, CANCEL, PAUSE]
## What the Teclas page calls each action.
const NAMES := {MOVE_UP: "Arriba", MOVE_DOWN: "Abajo", MOVE_LEFT: "Izquierda",
	MOVE_RIGHT: "Derecha", ACCEPT: "Aceptar", CANCEL: "Cancelar", PAUSE: "Pausa"}
## The built-in action that follows each one.
const UI_ACTIONS := {MOVE_UP: "ui_up", MOVE_DOWN: "ui_down", MOVE_LEFT: "ui_left",
	MOVE_RIGHT: "ui_right", ACCEPT: "ui_accept", CANCEL: "ui_cancel"}
const ONLY_KEY := "Esa tecla es la única de «%s»."


## The project's keys, with the player's changes over them.
static func apply(overrides: Dictionary) -> void:
	InputMap.load_from_project_settings()
	for action: String in overrides:
		_set_keys(action, overrides[action])
	_follow_in_menus()


## Gives code to action in overrides and on the InputMap. Returns why it can't ("" if done).
static func assign(overrides: Dictionary, action: String, code: int) -> String:
	for other in ACTIONS:
		if other != action and keys_of(other) == [code]:
			return ONLY_KEY % NAMES[other]
	for other in ACTIONS:
		var keys := keys_of(other)
		if other != action and code in keys:
			keys.erase(code)
			overrides[other] = keys
			_set_keys(other, keys)
	var mine := keys_of(action)
	if code in mine:
		mine.erase(code)
		mine.push_front(code)
	else:
		mine[0] = code
	overrides[action] = mine
	_set_keys(action, mine)
	_follow_in_menus()
	return ""


## The key codes of action, first one first.
static func keys_of(action: String) -> Array[int]:
	var codes: Array[int] = []
	for event in InputMap.action_get_events(action):
		var key := event as InputEventKey
		if key != null:
			codes.append(int(key.physical_keycode))
	return codes


## "W, Up", for the Teclas page.
static func keys_text(action: String) -> String:
	var names := PackedStringArray()
	for code in keys_of(action):
		names.append(OS.get_keycode_string(code))
	return ", ".join(names)


## The name of the first key of action, for the map's prompts.
static func first_key_name(action: String) -> String:
	var codes := keys_of(action)
	return OS.get_keycode_string(codes[0]) if not codes.is_empty() else ""


static func _set_keys(action: String, codes: Array) -> void:
	InputMap.action_erase_events(action)
	for code: Variant in codes:
		var event := InputEventKey.new()
		event.physical_keycode = int(code) as Key
		InputMap.action_add_event(action, event)


static func _follow_in_menus() -> void:
	for action: String in UI_ACTIONS:
		var ui: String = UI_ACTIONS[action]
		for event in InputMap.action_get_events(ui):
			if event is InputEventKey:
				InputMap.action_erase_event(ui, event)
		for event in InputMap.action_get_events(action):
			InputMap.action_add_event(ui, event)
```

Replace in `scripts/game/game_options.gd`:

```gdscript
var large_text := false


```

with:

```gdscript
var large_text := false
## What the player reassigned: KeyMap action -> key codes.
var keys := {}


```

Replace in `scripts/game/game_options.gd`:

```gdscript
		"fullscreen": fullscreen, "large_text": large_text}
```

with:

```gdscript
		"fullscreen": fullscreen, "large_text": large_text, "keys": keys}
```

Replace in `scripts/game/game_options.gd`:

```gdscript
		options.large_text = data.large_text
	return options
```

with:

```gdscript
		options.large_text = data.large_text
	options.keys = _valid_keys(data.get("keys"))
	return options


## Only known actions with at least one key, and every key a number.
static func _valid_keys(saved: Variant) -> Dictionary:
	var valid := {}
	if not saved is Dictionary:
		return valid
	for action: Variant in saved:
		var codes: Variant = saved[action]
		if action in KeyMap.ACTIONS and codes is Array and not codes.is_empty() \
				and codes.all(func(code: Variant) -> bool: return code is float):
			valid[action] = codes
	return valid
```

- [ ] **Step 3: The map, the battle and the pause menu read the actions**

Replace in `scripts/world/player.gd`:

```gdscript
	var keys := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		keys.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		keys.x += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		keys.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		keys.y += 1.0
	if keys == Vector2.ZERO:
```

with:

```gdscript
	var keys := Input.get_vector(KeyMap.MOVE_LEFT, KeyMap.MOVE_RIGHT, KeyMap.MOVE_UP,
		KeyMap.MOVE_DOWN)
	if keys == Vector2.ZERO:
```

Replace in `scripts/world/player.gd`:

```gdscript
	move_target = null
	keys = keys.normalized()
	# The camera sits south
```

with:

```gdscript
	move_target = null
	# The camera sits south
```

Replace in `scripts/ui/battle_hud.gd`:

```gdscript
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
```

with:

```gdscript
	var key := event as InputEventKey
	if _page == Page.NONE or key == null or not key.pressed:
		return
	if key.is_action(KeyMap.MOVE_UP):
		_move(-1)
	elif key.is_action(KeyMap.MOVE_DOWN):
		_move(1)
	elif key.is_action(KeyMap.MOVE_LEFT):
		_aim(-1)
	elif key.is_action(KeyMap.MOVE_RIGHT):
		_aim(1)
	elif key.is_action(KeyMap.ACCEPT):
		if not key.echo:
			_accept()
	elif key.is_action(KeyMap.CANCEL):
		if not key.echo:
			_back()
	else:
		return
	get_viewport().set_input_as_handled()
```

Replace in `scripts/ui/battle_hud.gd`:

```gdscript
			var key := event as InputEventKey
			var e_key := key != null and key.pressed and not key.echo \
				and key.physical_keycode == KEY_E
			if click or e_key or event.is_action_pressed("ui_accept"):
```

with:

```gdscript
			if click or event.is_action_pressed(KeyMap.ACCEPT):
```

Replace in `scripts/ui/pause_menu.gd`:

```gdscript
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.physical_keycode != KEY_ESCAPE and key.physical_keycode != KEY_P:
		return
	if not is_open():
		if available:
			get_viewport().set_input_as_handled()
			open()
		return
	get_viewport().set_input_as_handled()
```

with:

```gdscript
	if not is_open():
		if available and event.is_action_pressed(KeyMap.PAUSE):
			get_viewport().set_input_as_handled()
			open()
		return
	if not (event.is_action_pressed(KeyMap.PAUSE) or event.is_action_pressed(KeyMap.CANCEL)):
		return
	get_viewport().set_input_as_handled()
```

Replace in `scripts/title/title_screen.gd`:

```gdscript
	DisplaySettings.apply(get_window(), _options)
```

with:

```gdscript
	DisplaySettings.apply(get_window(), _options)
	KeyMap.apply(_options.keys)
```

The map's prompts name the accept key. Replace in `scripts/world/world.gd`:

```gdscript
	TALK: "Enter o toca: hablar",
	NPC: "Enter o toca: hablar",
	SHOP: "Enter o toca: comprar",
	INN: "Enter o toca: hablar",
	CHEST: "Enter o toca: abrir",
	LEVER: "Enter o toca: tirar",
	KEY: "Enter o toca: coger",
	DOOR: "Enter o toca: abrir",
	PORTAL: "Enter o toca: volver",
	BOARD: "Enter o toca: leer",
```

with:

```gdscript
	TALK: "%s o toca: hablar",
	NPC: "%s o toca: hablar",
	SHOP: "%s o toca: comprar",
	INN: "%s o toca: hablar",
	CHEST: "%s o toca: abrir",
	LEVER: "%s o toca: tirar",
	KEY: "%s o toca: coger",
	DOOR: "%s o toca: abrir",
	PORTAL: "%s o toca: volver",
	BOARD: "%s o toca: leer",
```

Replace in `scripts/world/world.gd`:

```gdscript
		_prompt.text = PROMPTS[near.kind]
```

with:

```gdscript
		_prompt.text = PROMPTS[near.kind] % KeyMap.first_key_name(KeyMap.ACCEPT)
```

Replace in `scripts/world/world.gd`:

```gdscript
	_prompt.text = PROMPTS[TALK]
```

with:

```gdscript
	_prompt.text = PROMPTS[TALK] % KeyMap.first_key_name(KeyMap.ACCEPT)
```

- [ ] **Step 4: The Teclas page**

Create `scripts/ui/keys_panel.gd`:

```gdscript
class_name KeysPanel extends VBoxContainer
## The Teclas page of the options: one row per action with its keys. Pressing a row waits
## for the new key (a click cancels), which replaces the first key of that action; a key that
## can't change hands says why. Restablecer goes back to the project's keys. The rules are
## KeyMap's. Call setup() before adding it to the tree.

signal closed

const FONT_SIZE := 24
const NAME_WIDTH := 160.0
const KEYS_WIDTH := 400.0
const WAITING := "Pulsa una tecla..."

var _options: GameOptions
var _audio: AudioDirector
var _buttons := {}
var _message: Label
## The action waiting for its new key ("" for none).
var _waiting := ""


func setup(options: GameOptions, audio: AudioDirector) -> void:
	_options = options
	_audio = audio


func _ready() -> void:
	add_theme_constant_override("separation", 6)
	add_child(_label("Teclas", UiStyle.TITLE_COLOR))
	for action in KeyMap.ACTIONS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		add_child(row)
		var name_label := _label(KeyMap.NAMES[action], Color.WHITE)
		name_label.custom_minimum_size.x = NAME_WIDTH
		row.add_child(name_label)
		var button := _button("")
		button.custom_minimum_size.x = KEYS_WIDTH
		button.pressed.connect(_listen.bind(action))
		row.add_child(button)
		_buttons[action] = button
	_message = _label("", Color.WHITE)
	_message.hide()
	add_child(_message)
	var reset := _button("Restablecer")
	reset.pressed.connect(_reset)
	add_child(reset)
	var back := _button("Volver")
	back.pressed.connect(func() -> void: closed.emit())
	add_child(back)
	_refresh()


func focus_first() -> void:
	(_buttons[KeyMap.ACTIONS[0]] as Button).grab_focus()


## Before the buttons and the menus see it, the next key press or click belongs to the row.
func _input(event: InputEvent) -> void:
	if _waiting == "":
		return
	var click: bool = event is InputEventMouseButton and event.pressed
	var key := event as InputEventKey
	if not click and (key == null or not key.pressed or key.echo):
		return
	get_viewport().set_input_as_handled()
	var action := _waiting
	_waiting = ""
	if click or key.physical_keycode == KEY_NONE:
		_refresh()
		return
	_say(KeyMap.assign(_options.keys, action, int(key.physical_keycode)))
	_refresh()
	if _audio:
		_audio.play_sfx(SfxLibrary.ACCEPT)


func _listen(action: String) -> void:
	_waiting = action
	_say("")
	(_buttons[action] as Button).text = WAITING
	if _audio:
		_audio.play_sfx(SfxLibrary.CURSOR)


func _reset() -> void:
	_options.keys.clear()
	KeyMap.apply(_options.keys)
	_say("")
	_refresh()
	if _audio:
		_audio.play_sfx(SfxLibrary.ACCEPT)


func _refresh() -> void:
	for action: String in _buttons:
		(_buttons[action] as Button).text = KeyMap.keys_text(action)


func _say(text: String) -> void:
	_message.text = text
	_message.visible = text != ""


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	return button


func _label(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", color)
	return label
```

Replace in `scripts/ui/options_panel.gd`:

```gdscript
## shake, large text and, on desktop, fullscreen. Changes apply at once; "Volver" (or back())
## saves them with SaveStore and emits closed. The rows scroll when the screen is short.
## Call setup() before adding it to the tree.
```

with:

```gdscript
## shake, large text, on desktop fullscreen, and Teclas (KeysPanel). Changes apply at once;
## "Volver" (or back()) saves them with SaveStore and emits closed. The rows scroll when the
## screen is short. Call setup() before adding it to the tree.
```

Replace in `scripts/ui/options_panel.gd`:

```gdscript
var _back_button: Button


func setup(
```

with:

```gdscript
var _back_button: Button
var _keys_button: Button
var _keys_panel: KeysPanel


func setup(
```

Replace in `scripts/ui/options_panel.gd`:

```gdscript
	_back_button = _button("Volver")
	_back_button.pressed.connect(back)
	_main.add_child(_back_button)
	_update_values()
```

with:

```gdscript
	_keys_button = _button("Teclas")
	_keys_button.pressed.connect(_open_keys)
	_rows.add_child(_keys_button)
	_back_button = _button("Volver")
	_back_button.pressed.connect(back)
	_main.add_child(_back_button)
	_keys_panel = KeysPanel.new()
	_keys_panel.setup(_options, _audio)
	_keys_panel.closed.connect(_close_keys)
	_keys_panel.hide()
	add_child(_keys_panel)
	_update_values()
```

Replace in `scripts/ui/options_panel.gd`:

```gdscript
## Saves the options and closes the page.
func back() -> void:
	SaveStore.save_options(_options)
```

with:

```gdscript
## Saves the options and closes the page (from Teclas: back to the options first).
func back() -> void:
	if _keys_panel.visible:
		_close_keys()
		return
	SaveStore.save_options(_options)
```

Replace in `scripts/ui/options_panel.gd`:

```gdscript
func _apply_display() -> void:
```

with:

```gdscript
func _open_keys() -> void:
	_main.hide()
	_keys_panel.show()
	_keys_panel.focus_first()
	if _audio:
		_audio.play_sfx(SfxLibrary.ACCEPT)


func _close_keys() -> void:
	_keys_panel.hide()
	_main.show()
	_keys_button.grab_focus()
	if _audio:
		_audio.play_sfx(SfxLibrary.CANCEL)


func _apply_display() -> void:
```

- [ ] **Step 5: Check it**

A throwaway probe outside the repo checks the defaults, the rules and that an old options file loads. Create `C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\probes\keys_probe.gd`:

```gdscript
extends SceneTree
## Throwaway check of the keys. Never committed.


func _init() -> void:
	KeyMap.apply({})
	for action in KeyMap.ACTIONS:
		print("%s: %s" % [action, KeyMap.keys_text(action)])
	print("ui_up: ", InputMap.action_get_events("ui_up").size(), " ui_accept: ",
		InputMap.action_get_events("ui_accept").size())
	var keys := {}
	print("W to cancel: '%s'" % KeyMap.assign(keys, KeyMap.CANCEL, KEY_W))
	print("cancel: %s | up: %s | keys %s" % [KeyMap.keys_text(KeyMap.CANCEL),
		KeyMap.keys_text(KeyMap.MOVE_UP), keys])
	print("Up to pause: '%s'" % KeyMap.assign(keys, KeyMap.PAUSE, KEY_UP))
	print("up: %s | pause: %s" % [KeyMap.keys_text(KeyMap.MOVE_UP), KeyMap.keys_text(KeyMap.PAUSE)])
	print("P to pause again: '%s'" % KeyMap.assign(keys, KeyMap.PAUSE, KEY_P))
	var taken := KeyMap.assign(keys, KeyMap.ACCEPT, KEY_P)
	print("P to accept: '%s', pause: %s" % [taken, KeyMap.keys_text(KeyMap.PAUSE)])
	var old := GameOptions.from_dict({"music": 0.5, "sfx": 0.5, "text_speed": 1.0})
	print("old file: ", old.to_dict())
	var bad := GameOptions.from_dict({"keys": {"move_up": [87.0], "nope": [1.0], "accept": []}})
	print("bad keys: ", bad.keys)
	KeyMap.apply({})
	print("reset up: ", KeyMap.keys_text(KeyMap.MOVE_UP))
	quit()
```

```powershell
$env:APPDATA = "C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\appdata"
.\tools\godot.cmd --headless --path . --import
foreach ($s in "game/key_map","ui/keys_panel","ui/options_panel","game/game_options","world/player","ui/battle_hud","ui/pause_menu","world/world","title/title_screen") { .\tools\godot.cmd --headless --path . --check-only --script "res://scripts/$s.gd" }
.\tools\godot.cmd --headless --path . --script "C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\probes\keys_probe.gd"
.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 3000 -- --autoplay
```

Expected from the probe: `move_up: W, Up`, `accept: Enter, Kp Enter, Space, E`, `cancel: Escape, Q, Backspace, X`, `pause: Escape, P`; `ui_up: 4 ui_accept: 4` (ui_up keeps its two joypad events); `W to cancel: ''` with `cancel: W, Q, Backspace, X | up: Up`; `Up to pause: 'Esa tecla es la única de «Arriba».'`, the lists unchanged; `P to pause again: ''`; then P goes to accept (pause still has Escape), printed as `P to accept: '', pause: Escape`; `old file` shows the defaults for what it lacks; `bad keys` keeps only `move_up`; `reset up: W, Up`. The run plays with no ERROR or WARNING (besides Jolt).

Then play it for a minute by hand if a window is available (`.\tools\godot.cmd --path .`): WASD and arrows on the map, E on a villager's prompt, WASD / Enter / Q in battle, P and Esc for the menu, Opciones → Teclas: reassign Arriba to I, walk with it, Restablecer.

- [ ] **Step 6: Commit**

```powershell
git add project.godot scripts
git commit -m "Read the keyboard through InputMap actions and let the player reassign them"
```

---

### Task 4: Difficulty Fácil / Normal

**Files:**
- Create: `scripts/game/difficulty.gd`, `scripts/ui/difficulty_window.gd`
- Modify: `scripts/battle/battle_engine.gd`, `scripts/battle/battle_scene.gd`, `scripts/game/game_state.gd`, `scripts/game/save_data.gd`, `scripts/game/game.gd`, `scripts/title/title_screen.gd`, `scripts/ui/options_panel.gd`, `scripts/ui/pause_menu.gd`

**Interfaces:**
- Consumes: `OptionsPanel._choice_row()` (Task 2), `UiStyle` (Task 1).
- Produces: `Difficulty.NORMAL`, `Difficulty.EASY`, `Difficulty.IDS`, `Difficulty.NAMES`, `Difficulty.TEXTS`, `Difficulty.damage_mult(id) -> float`, `Difficulty.exp_mult(id) -> float`; `BattleEngine.damage_mult`, `BattleEngine.exp_mult`; `GameState.difficulty: String`; save version 8 under `SaveData.DIFFICULTY_VERSION` with the field `difficulty`; `Game.setup(audio, options, save, hero_name := "", difficulty := Difficulty.NORMAL)`; `OptionsPanel.setup(options, audio, state: GameState = null)`; user argument `--autoplay-easy`.

- [ ] **Step 1: The rule**

Create `scripts/game/difficulty.gd`:

```gdscript
class_name Difficulty extends RefCounted
## The two difficulties, chosen for each game (GameState.difficulty): Fácil takes 30 % less
## damage (from blows, spells and poison) and earns 25 % more EXP. Pure.

const NORMAL := "normal"
const EASY := "easy"
const IDS: Array[String] = [NORMAL, EASY]
const NAMES := {NORMAL: "Normal", EASY: "Fácil"}
const TEXTS := {
	NORMAL: "El juego tal como se pensó.",
	EASY: "Un 30 % menos de daño recibido y un 25 % más de EXP.",
}
const EASY_DAMAGE := 0.7
const EASY_EXP := 1.25


static func damage_mult(id: String) -> float:
	return EASY_DAMAGE if id == EASY else 1.0


static func exp_mult(id: String) -> float:
	return EASY_EXP if id == EASY else 1.0
```

Replace in `scripts/battle/battle_engine.gd`:

```gdscript
var drops_won: Array[String] = []

```

with:

```gdscript
var drops_won: Array[String] = []
## The difficulty: what the hero's damage and the EXP won are multiplied by.
var damage_mult := 1.0
var exp_mult := 1.0

```

Replace in `scripts/battle/battle_engine.gd`:

```gdscript
	var fighter := _fighter(target)
	if target == BattleEvent.HERO and _defending:
		amount = maxi(1, ceili(amount / 2.0))
```

with:

```gdscript
	var fighter := _fighter(target)
	if target == BattleEvent.HERO:
		amount = _taken(amount)
	if target == BattleEvent.HERO and _defending:
		amount = maxi(1, ceili(amount / 2.0))
```

Replace in `scripts/battle/battle_engine.gd`:

```gdscript
			var amount := maxi(1, roundi(fighter.max_hp * POISON_SHARE))
			fighter.hp = maxi(fighter.hp - amount, 0)
```

with:

```gdscript
			var amount := maxi(1, roundi(fighter.max_hp * POISON_SHARE))
			if who == BattleEvent.HERO:
				amount = _taken(amount)
			fighter.hp = maxi(fighter.hp - amount, 0)
```

Replace in `scripts/battle/battle_engine.gd`:

```gdscript
	hero.experience += exp_won
```

with:

```gdscript
	exp_won = roundi(exp_won * exp_mult)
	hero.experience += exp_won
```

Replace in `scripts/battle/battle_engine.gd`:

```gdscript
func _roll_damage(attacker: Combatant, defender: Combatant, crit: bool) -> int:
```

with:

```gdscript
## What the difficulty leaves of damage to the hero, at least 1.
func _taken(amount: int) -> int:
	return maxi(1, roundi(amount * damage_mult))


func _roll_damage(attacker: Combatant, defender: Combatant, crit: bool) -> int:
```

Replace in `scripts/battle/battle_scene.gd`:

```gdscript
var camera_shake := true
```

with:

```gdscript
var camera_shake := true
## A Difficulty id: the multipliers of this battle's engine.
var difficulty := Difficulty.NORMAL
```

Replace in `scripts/battle/battle_scene.gd`:

```gdscript
	engine = BattleEngine.new(hero, enemies, _rng, inventory)
```

with:

```gdscript
	engine = BattleEngine.new(hero, enemies, _rng, inventory)
	engine.damage_mult = Difficulty.damage_mult(difficulty)
	engine.exp_mult = Difficulty.exp_mult(difficulty)
```

- [ ] **Step 2: In the state and in the save**

Replace in `scripts/game/game_state.gd`:

```gdscript
var explored := {}

```

with:

```gdscript
var explored := {}
## A Difficulty id, chosen for each game.
var difficulty := Difficulty.NORMAL

```

Replace in `scripts/game/save_data.gd`:

```gdscript
## adds the accessory slot to the loadout and the side quests' progress; an older save gets
## the slot empty and no side quest taken.

const VERSION := 7
```

with:

```gdscript
## adds the accessory slot to the loadout and the side quests' progress; an older save gets
## the slot empty and no side quest taken. DIFFICULTY_VERSION (phase 7) adds the difficulty;
## an older save plays on Normal.

const VERSION := 8
```

Replace in `scripts/game/save_data.gd`:

```gdscript
const QUESTS_VERSION := 7
```

with:

```gdscript
const QUESTS_VERSION := 7
## First version with the difficulty.
const DIFFICULTY_VERSION := 8
```

Replace in `scripts/game/save_data.gd`:

```gdscript
## Version 5 field: no portal ({}), or its village and zone are ZoneData ids and its spot
```

with:

```gdscript
## DIFFICULTY_VERSION field: a Difficulty id.
static func _valid_difficulty(data: Dictionary) -> bool:
	var difficulty: Variant = data.get("difficulty")
	return difficulty is String and difficulty in Difficulty.IDS


## Version 5 field: no portal ({}), or its village and zone are ZoneData ids and its spot
```

Replace in `scripts/game/save_data.gd`:

```gdscript
		"quests": state.quests.to_dict(),
```

with:

```gdscript
		"quests": state.quests.to_dict(),
		"difficulty": state.difficulty,
```

Replace in `scripts/game/save_data.gd`:

```gdscript
	state.quests.set_from(data.get("quests", {}))
```

with:

```gdscript
	state.quests.set_from(data.get("quests", {}))
	state.difficulty = data.get("difficulty", Difficulty.NORMAL)
```

Replace in `scripts/game/save_data.gd`:

```gdscript
	if int(data.version) >= QUESTS_VERSION and not _valid_quests(data):
		return false
```

with:

```gdscript
	if int(data.version) >= QUESTS_VERSION and not _valid_quests(data):
		return false
	if int(data.version) >= DIFFICULTY_VERSION and not _valid_difficulty(data):
		return false
```

- [ ] **Step 3: The session**

Replace in `scripts/game/game.gd`:

```gdscript
var _hero_name := ""
```

with:

```gdscript
var _hero_name := ""
## The difficulty chosen for a new game.
var _difficulty := Difficulty.NORMAL
```

Replace in `scripts/game/game.gd`:

```gdscript
## SaveStore.load_game(), empty for a new game, which gets hero_name.
func setup(audio: AudioDirector, options: GameOptions, save: Dictionary,
		hero_name := "") -> void:
	_audio = audio
	_options = options
	_save = save
	_hero_name = hero_name
```

with:

```gdscript
## SaveStore.load_game(), empty for a new game, which gets hero_name and difficulty.
func setup(audio: AudioDirector, options: GameOptions, save: Dictionary,
		hero_name := "", difficulty := Difficulty.NORMAL) -> void:
	_audio = audio
	_options = options
	_save = save
	_hero_name = hero_name
	_difficulty = difficulty
```

Replace in `scripts/game/game.gd`:

```gdscript
		state.hero.display_name = StoryState.clean_name(_hero_name)
```

with:

```gdscript
		state.hero.display_name = StoryState.clean_name(_hero_name)
		state.difficulty = _difficulty
		if _autoplay and args.has("--autoplay-easy"):
			state.difficulty = Difficulty.EASY
```

Replace in `scripts/game/game.gd`:

```gdscript
	battle.camera_shake = _options.camera_shake
```

with:

```gdscript
	battle.camera_shake = _options.camera_shake
	battle.difficulty = state.difficulty
```

Replace in `scripts/game/game.gd`:

```gdscript
## `-- --autoplay --autoplay-zone=<id>`: a new game that starts in that zone with the
## level, gold, gear and progress AUTOPLAY_ZONES gives it.
```

with:

```gdscript
## `-- --autoplay --autoplay-zone=<id>`: a new game that starts in that zone with the
## level, gold, gear and progress AUTOPLAY_ZONES gives it.
## `-- --autoplay --autoplay-easy`: a new game on Fácil.
```

- [ ] **Step 4: Choosing it**

Create `scripts/ui/difficulty_window.gd`:

```gdscript
class_name DifficultyWindow extends Control
## Asked after the hero's name when a new game starts: Normal or Fácil, each with what it
## means, and Volver. It can be changed later from Opciones in the pause menu. Emits
## chosen(id) or cancelled. Keyboard, mouse and touch.

signal chosen(id: String)
signal cancelled

const FONT_SIZE := 26

var _audio: AudioDirector


## Cursor and accept sounds; without it the window is silent.
func setup(audio: AudioDirector) -> void:
	_audio = audio


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var window := BattleHud.make_window()
	center.add_child(window)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	window.add_child(box)
	var title := _label("¿Qué dificultad prefieres?", UiStyle.TITLE_COLOR, FONT_SIZE)
	box.add_child(title)
	var first: Button = null
	for id in Difficulty.IDS:
		var button := _button(Difficulty.NAMES[id])
		button.pressed.connect(_choose.bind(id))
		box.add_child(button)
		box.add_child(_label(Difficulty.TEXTS[id], UiStyle.GREY, UiStyle.TEXT_SIZE))
		if first == null:
			first = button
	var back := _button("Volver")
	back.pressed.connect(_cancel)
	box.add_child(back)
	first.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		_cancel()


func _choose(id: String) -> void:
	if _audio:
		_audio.play_sfx(SfxLibrary.ACCEPT)
	chosen.emit(id)


func _cancel() -> void:
	if _audio:
		_audio.play_sfx(SfxLibrary.CANCEL)
	cancelled.emit()


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.flat = true
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	return button


func _label(text: String, color: Color, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label
```

Replace in `scripts/title/title_screen.gd`:

```gdscript
	_name_entry.accepted.connect(func(hero_name: String) -> void: _start_game({}, hero_name))
	_name_entry.cancelled.connect(func() -> void:
		_name_entry.queue_free()
		_name_entry = null
		_title_label.show()
		_menu_window.show()
		_focus(_continue_button if not _continue_button.disabled else _options_button))
	if _autoplay:
		_name_entry.demo(AUTOPLAY_NAME)
```

with:

```gdscript
	_name_entry.accepted.connect(_on_name_accepted)
	_name_entry.cancelled.connect(_back_to_menu)
	if _autoplay:
		_name_entry.demo(AUTOPLAY_NAME)


## The name is set: the difficulty comes next (on autoplay Game picks it from the arguments).
func _on_name_accepted(hero_name: String) -> void:
	if _autoplay:
		_start_game({}, hero_name)
		return
	_close_name_entry()
	_difficulty_window = DifficultyWindow.new()
	_difficulty_window.setup(_audio)
	_ui.add_child(_difficulty_window)
	_difficulty_window.chosen.connect(func(id: String) -> void: _start_game({}, hero_name, id))
	_difficulty_window.cancelled.connect(_back_to_menu)


## Volver from the name or the difficulty: the menu again.
func _back_to_menu() -> void:
	_close_name_entry()
	if _difficulty_window != null:
		_difficulty_window.queue_free()
		_difficulty_window = null
	_title_label.show()
	_menu_window.show()
	_focus(_continue_button if not _continue_button.disabled else _options_button)


func _close_name_entry() -> void:
	if _name_entry != null:
		_name_entry.queue_free()
		_name_entry = null
```

Replace in `scripts/title/title_screen.gd`:

```gdscript
var _name_entry: NameEntry
```

with:

```gdscript
var _name_entry: NameEntry
var _difficulty_window: DifficultyWindow
```

Replace in `scripts/title/title_screen.gd`:

```gdscript
	_name_entry = null
	_title_label = null
```

with:

```gdscript
	_name_entry = null
	_difficulty_window = null
	_title_label = null
```

Replace in `scripts/title/title_screen.gd`:

```gdscript
## Fades out, swaps the title for a Game (save empty = new game with hero_name) and fades
## in.
func _start_game(save: Dictionary, hero_name := "") -> void:
```

with:

```gdscript
## Fades out, swaps the title for a Game (save empty = new game with hero_name and
## difficulty) and fades in.
func _start_game(save: Dictionary, hero_name := "", difficulty := Difficulty.NORMAL) -> void:
```

Replace in `scripts/title/title_screen.gd`:

```gdscript
	_game.setup(_audio, _options, save, hero_name)
```

with:

```gdscript
	_game.setup(_audio, _options, save, hero_name, difficulty)
```

Replace in `scripts/ui/options_panel.gd`:

```gdscript
## screen is short. Call setup() before adding it to the tree.
```

with:

```gdscript
## screen is short. From the pause menu (with state) it also changes the game's difficulty.
## Call setup() before adding it to the tree.
```

Replace in `scripts/ui/options_panel.gd`:

```gdscript
var _audio: AudioDirector
var _main: VBoxContainer
```

with:

```gdscript
var _audio: AudioDirector
var _state: GameState
var _main: VBoxContainer
```

Replace in `scripts/ui/options_panel.gd`:

```gdscript
func setup(options: GameOptions, audio: AudioDirector) -> void:
	_options = options
	_audio = audio
```

with:

```gdscript
## state: the game under way, whose difficulty can change here (null on the title screen).
func setup(options: GameOptions, audio: AudioDirector, state: GameState = null) -> void:
	_options = options
	_audio = audio
	_state = state
```

Replace in `scripts/ui/options_panel.gd`:

```gdscript
	_keys_button = _button("Teclas")
```

with:

```gdscript
	if _state != null:
		var names: Array = Difficulty.IDS.map(func(id: String) -> String:
			return Difficulty.NAMES[id])
		_choice_row("Dificultad", names, Difficulty.IDS.find(_state.difficulty),
			func(i: int) -> void: _state.difficulty = Difficulty.IDS[i])
	_keys_button = _button("Teclas")
```

Replace in `scripts/ui/pause_menu.gd`:

```gdscript
	_options_panel.setup(_options, _audio)
```

with:

```gdscript
	_options_panel.setup(_options, _audio, _state)
```

- [ ] **Step 5: Check it**

A throwaway probe compares the two difficulties as rules. Create `C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\probes\difficulty_probe.gd`:

```gdscript
extends SceneTree
## Throwaway check of the difficulty. Never committed.


func _init() -> void:
	var hero_data := load("res://data/hero.tres") as Combatant
	for id in Difficulty.IDS:
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		var state := GameState.new(hero_data)
		var foes: Array[Combatant] = [EnemyLibrary.data("slime").duplicate() as Combatant]
		var engine := BattleEngine.new(state.hero, foes, rng, state.inventory)
		engine.damage_mult = Difficulty.damage_mult(id)
		engine.exp_mult = Difficulty.exp_mult(id)
		while engine.state == BattleEngine.State.ONGOING:
			engine.resolve_round(BattleEngine.cmd_attack(0))
		print("%s: exp_won %d, 100 damage becomes %d" % [id, engine.exp_won, engine._taken(100)])
	var state := GameState.new(hero_data)
	state.difficulty = Difficulty.EASY
	var saved := SaveData.from_state(state, Vector3.ZERO, 1.0)
	var json: Dictionary = JSON.parse_string(JSON.stringify(saved))
	var loaded := GameState.new(hero_data)
	print("v8: ", SaveData.apply(loaded, json).valid, " ", loaded.difficulty)
	json.erase("difficulty")
	print("v8 without it: ", SaveData.apply(loaded, json).valid)
	json.version = 7.0
	loaded.difficulty = Difficulty.EASY
	print("v7: ", SaveData.apply(loaded, json).valid, " ", loaded.difficulty)
	quit()
```

```powershell
$env:APPDATA = "C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\appdata"
.\tools\godot.cmd --headless --path . --import
foreach ($s in "game/difficulty","ui/difficulty_window","battle/battle_engine","battle/battle_scene","game/game_state","game/save_data","game/game","title/title_screen","ui/options_panel","ui/pause_menu") { .\tools\godot.cmd --headless --path . --check-only --script "res://scripts/$s.gd" }
.\tools\godot.cmd --headless --path . --script "C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\probes\difficulty_probe.gd"
.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 6000 -- --autoplay --autoplay-save --autoplay-easy
```

Expected: the probe prints a larger `exp_won` on `easy` (`normal: exp_won 4, 100 damage becomes 100`, `easy: exp_won 5, 100 damage becomes 70`); `v8: true easy`; `v8 without it: false`; `v7: true normal`. The save run's `Guardado:` and `Cargado:` lines are identical and both hold `"difficulty":"easy"`. Delete `save_autoplay.json` from the scratchpad's data folder. By hand: Nueva partida → name → the window asks; Volver returns to the title.

- [ ] **Step 6: Commit**

```powershell
git add scripts
git commit -m "Add the Facil and Normal difficulties, saved with each game as version 8"
```

---

### Task 5: The final name, version, icon, cover, desktop presets and the itch.io material

**Files:**
- Create: `icon.png`, `CHANGELOG.md`, `docs/itch/.gdignore`, `docs/itch/descripcion.md`, `docs/itch/portada.png`, `docs/itch/captura-1.png` to `captura-5.png`, `.github/workflows/release.yml`
- Delete: `icon.svg`, `icon.svg.import`
- Modify: `project.godot`, `export_presets.cfg`, `scripts/title/title_screen.gd`, `scripts/ui/display_settings.gd`

**Interfaces:**
- Consumes: `DisplaySettings` (Task 2), `BattleActor`, `WorldStage`.
- Produces: `application/config/version` = `1.0.0`, read by the title screen; presets `Windows Desktop` and `Linux`.

**Nothing is published here:** no upload to itch.io, no tag, no push. **The save stays where it is:** `user://` hangs from the project's name on desktop, so changing `config/name` alone would lose the player's save in `%APPDATA%\Godot\app_userdata\rpg-turnos\`. `config/custom_user_dir_name` pins it to that same folder.

- [ ] **Step 1: The name and the version**

Replace in `project.godot`:

```
config/name="rpg-turnos"
config/version="0.1"
```

with:

```
config/name="Villaclaro: la Niebla del Norte"
config/version="1.0.0"
config/use_custom_user_dir=true
config/custom_user_dir_name="Godot/app_userdata/rpg-turnos"
boot_splash/show_image=false
```

Replace in `project.godot`:

```
config/icon="res://icon.svg"
```

with:

```
config/icon="res://icon.png"
```

Replace in `scripts/ui/display_settings.gd`:

```gdscript
static func apply(window: Window, options: GameOptions) -> void:
```

with:

```gdscript
static func apply(window: Window, options: GameOptions) -> void:
	window.title = ProjectSettings.get_setting("application/config/name")
```

Replace in `scripts/title/title_screen.gd`:

```gdscript
const TITLE_TEXT := "Villaclaro"
const TITLE_SIZE := 96
```

with:

```gdscript
const TITLE_TEXT := "Villaclaro"
const TITLE_SIZE := 96
const SUBTITLE_TEXT := "La Niebla del Norte"
const SUBTITLE_SIZE := 36
const VERSION_SIZE := 18
```

Replace in `scripts/title/title_screen.gd`:

```gdscript
	title.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, \
		Control.PRESET_MODE_MINSIZE, 90)
```

with:

```gdscript
	title.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, \
		Control.PRESET_MODE_MINSIZE, 90)
	var subtitle := Label.new()
	subtitle.text = SUBTITLE_TEXT
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", SUBTITLE_SIZE)
	subtitle.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))
	subtitle.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.0))
	subtitle.add_theme_constant_override("outline_size", 10)
	title.add_child(subtitle)  # it comes and goes with the title
	subtitle.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	subtitle.offset_left = 0.0
	subtitle.offset_right = 0.0
	subtitle.offset_top = 0.0
	subtitle.offset_bottom = 0.0
	subtitle.grow_horizontal = Control.GROW_DIRECTION_BOTH
	subtitle.grow_vertical = Control.GROW_DIRECTION_END
	var version := Label.new()
	version.text = "v%s" % ProjectSettings.get_setting("application/config/version")
	version.add_theme_font_size_override("font_size", VERSION_SIZE)
	version.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.0))
	version.add_theme_constant_override("outline_size", 6)
	root.add_child(version)
	version.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, \
		Control.PRESET_MODE_MINSIZE, 12)
```

- [ ] **Step 2: Desktop presets**

Replace in `export_presets.cfg`:

```
progressive_web_app/enabled=false
```

with:

```
progressive_web_app/enabled=false

[preset.1]

name="Windows Desktop"
platform="Windows Desktop"
runnable=true
advanced_options=false
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter=""
exclude_filter="docs/*, scripts/tools/*"
export_path="build/windows/Villaclaro.exe"
patches=PackedStringArray()
encryption_include_filters=""
encryption_exclude_filters=""
seed=0
encrypt_pck=false
encrypt_directory=false
script_export_mode=2

[preset.1.options]

custom_template/debug=""
custom_template/release=""
debug/export_console_wrapper=0
binary_format/embed_pck=true
texture_format/s3tc_bptc=true
texture_format/etc2_astc=false
binary_format/architecture="x86_64"
codesign/enable=false
application/modify_resources=true
application/icon="res://icon.png"
application/icon_interpolation=4
application/file_version="1.0.0.0"
application/product_version="1.0.0.0"
application/company_name="apergas"
application/product_name="Villaclaro"
application/file_description="Villaclaro: la Niebla del Norte"
application/copyright=""
application/trademarks=""

[preset.2]

name="Linux"
platform="Linux"
runnable=true
advanced_options=false
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter=""
exclude_filter="docs/*, scripts/tools/*"
export_path="build/linux/Villaclaro.x86_64"
patches=PackedStringArray()
encryption_include_filters=""
encryption_exclude_filters=""
seed=0
encrypt_pck=false
encrypt_directory=false
script_export_mode=2

[preset.2.options]

custom_template/debug=""
custom_template/release=""
debug/export_console_wrapper=0
binary_format/embed_pck=true
texture_format/s3tc_bptc=true
texture_format/etc2_astc=false
binary_format/architecture="x86_64"
```

Create `.github/workflows/release.yml`:

```yaml
# Exports the Windows and Linux builds on each version tag (v*) and keeps them as artifacts
# of the run. It publishes nothing: uploading to itch.io is done by hand.
name: Desktop builds

on:
  push:
    tags: ["v*"]
  workflow_dispatch:

permissions:
  contents: read

env:
  GODOT_VERSION: 4.7.2

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7

      - name: Install Godot and export templates
        run: |
          base="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable"
          curl -fsSL -o godot.zip "$base/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip"
          curl -fsSL -o templates.tpz "$base/Godot_v${GODOT_VERSION}-stable_export_templates.tpz"
          unzip -q godot.zip
          mv "Godot_v${GODOT_VERSION}-stable_linux.x86_64" godot
          templates="$HOME/.local/share/godot/export_templates/${GODOT_VERSION}.stable"
          mkdir -p "$templates"
          unzip -q templates.tpz
          mv templates/* "$templates/"
          rm -rf godot.zip templates.tpz templates

      - name: Import and export
        run: |
          ./godot --headless --path . --import
          mkdir -p build/windows build/linux
          ./godot --headless --path . --export-release "Windows Desktop" build/windows/Villaclaro.exe
          ./godot --headless --path . --export-release "Linux" build/linux/Villaclaro.x86_64
          test -f build/windows/Villaclaro.exe
          test -f build/linux/Villaclaro.x86_64

      - uses: actions/upload-artifact@v4
        with:
          name: villaclaro-windows
          path: build/windows

      - uses: actions/upload-artifact@v4
        with:
          name: villaclaro-linux
          path: build/linux
```

- [ ] **Step 3: Icon and cover, made with the game**

Create `C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\probes\art.gd`:

```gdscript
extends SceneTree
## Throwaway: renders the icon (a slime's face on green) or the cover (the hero on the meadow
## with the title) with the game's own figures and saves a PNG. Never committed.
## Arguments after `--`: icon|cover <png path>.

const ACTOR_SCENE := preload("res://scenes/battle/battle_actor.tscn")
const COVER_HERO := Vector3(0.0, 0.0, -12.0)


func _initialize() -> void:
	_make.call_deferred()


func _make() -> void:
	var args := OS.get_cmdline_user_args()
	var stage := Node3D.new()
	root.add_child(stage)
	if args[0] == "icon":
		_icon(stage)
	else:
		_cover(stage)
	for i in 40:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(args[1])
	print("saved %s" % args[1])
	quit()


func _icon(stage: Node3D) -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.4, 0.75, 0.32)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.7
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	stage.add_child(world_env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 160, 0)
	sun.light_energy = 0.8
	stage.add_child(sun)
	var slime: BattleActor = ACTOR_SCENE.instantiate()
	slime.look = BattleActor.Look.SLIME
	stage.add_child(slime)
	var middle := Vector3(0, slime.top_height() * 0.5, 0)
	var camera := Camera3D.new()
	camera.fov = 26.0
	stage.add_child(camera)
	camera.global_position = middle + Vector3(0, 0.15, -3.4)
	camera.look_at(middle, Vector3.UP)
	camera.current = true


func _cover(stage: Node3D) -> void:
	var zone := ZoneData.by_id("pradera")
	WorldStage.build(stage, zone)
	var hero: BattleActor = ACTOR_SCENE.instantiate()
	hero.look = BattleActor.Look.HERO
	stage.add_child(hero)
	hero.position = COVER_HERO
	hero.rotation_degrees.y = 180.0
	hero.set_equipment(Equipment.COPPER_SWORD, Equipment.WOODEN_SHIELD)
	var camera := Camera3D.new()
	camera.fov = 40.0
	stage.add_child(camera)
	camera.global_position = COVER_HERO + Vector3(1.4, 1.5, 4.6)
	camera.look_at(COVER_HERO + Vector3(0, 1.5, -3.0), Vector3.UP)
	camera.current = true
	var layer := CanvasLayer.new()
	stage.add_child(layer)
	var box := VBoxContainer.new()
	layer.add_child(box)
	box.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE, Control.PRESET_MODE_MINSIZE, 50)
	box.add_child(_title("Villaclaro", 190, 26))
	box.add_child(_title("La Niebla del Norte", 72, 14))


func _title(text: String, size: int, outline: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.45))
	label.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.0))
	label.add_theme_constant_override("outline_size", outline)
	return label
```

Order matters: the project needs some icon to import, and the old one goes after the new one exists.

```powershell
$env:APPDATA = "C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\appdata"
$probes = "C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\probes"
New-Item -ItemType Directory -Force docs\itch | Out-Null
New-Item -ItemType File -Force docs\itch\.gdignore | Out-Null
.\tools\godot.cmd --path . --resolution 256x256 --script "$probes\art.gd" -- icon "$PWD\icon.png"
.\tools\godot.cmd --path . --resolution 630x500 --script "$probes\art.gd" -- cover "$PWD\docs\itch\portada.png"
git rm -q icon.svg icon.svg.import
.\tools\godot.cmd --headless --path . --import
```

Look at both PNGs: `icon.png` is 256 × 256 with the slime's face filling most of it on green; `portada.png` is 630 × 500 with the hero, the meadow and the title readable. If a figure is off-centre, change `camera.global_position` in the probe and render again; the probe is not committed.

- [ ] **Step 4: Five screenshots**

```powershell
$env:APPDATA = "C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\appdata"
$frames = "C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\frames"
New-Item -ItemType Directory -Force "$frames\a", "$frames\b", "$frames\c" | Out-Null
.\tools\godot.cmd --path . --write-movie "$frames\a\f.png" --fixed-fps 10 --quit-after 30
.\tools\godot.cmd --path . --write-movie "$frames\b\f.png" --fixed-fps 10 --quit-after 1500 -- --autoplay
.\tools\godot.cmd --path . --write-movie "$frames\c\f.png" --fixed-fps 10 --quit-after 900 -- --autoplay --autoplay-zone=castillo_patio
```

Look through them and copy five to `docs/itch/`: `captura-1.png` the title (`a\f00000025.png`), `captura-2.png` the village with the status window and a dialogue, `captura-3.png` a battle with the command window open, `captura-4.png` the shop, `captura-5.png` the castle. Delete `frames` and the `save_autoplay.json` of the scratchpad's data folder.

- [ ] **Step 5: Changelog and the page's text**

Create `CHANGELOG.md`:

```markdown
# Registro de cambios

## 1.0.0 (2026)

Primera versión completa de **Villaclaro: la Niebla del Norte**.

### El juego

- Un RPG por turnos en 3D, de principio a fin: pradera, bosque, mina de tres plantas y castillo, con cuatro jefes.
- Historia con escenas, el nombre del héroe a tu elección y créditos con los números de tu partida.
- Combate con hechizos, objetos, estados, debilidades y grupos de enemigos.
- Tiendas, posadas gratis, cofres, equipo y el Ala de viaje con su portal de vuelta.
- Seis misiones secundarias, tablones de anuncios y un Diario.
- Mapa de lo explorado, música y efectos generados por el propio juego.

### Novedades de esta versión

- Dificultad Fácil o Normal, al empezar y desde Opciones.
- Opciones: velocidad de combate, pantalla completa, calidad gráfica, temblor de cámara y textos grandes.
- Teclas reasignables.
- Versiones de escritorio para Windows y Linux.
- Listas con desplazamiento y textos largos que ya no se salen de las ventanas.
```

Create `docs/itch/descripcion.md`:

```markdown
# Página de itch.io

Material para la página. Nada se ha subido: la subida la hace el usuario (a mano o con `butler` y su clave).

- **Título:** Villaclaro: la Niebla del Norte
- **Clasificación:** Game, Role Playing
- **Etiquetas:** 3D, jrpg, turn-based, low-poly, retro, singleplayer, godot
- **Plataformas:** HTML5 (`build/web`, 1280 × 720, "Click to launch"), Windows (`build/windows`), Linux (`build/linux`)
- **Portada:** `portada.png` (630 × 500)
- **Capturas:** `captura-1.png` a `captura-5.png`
- **Icono:** `icon.png`, en la raíz del proyecto (256 × 256)
- **Licencia de los modelos:** KayKit, de Kay Lousberg (CC0); ver `assets/CREDITS.md`

## Descripción en español

Otra mañana gris en Villaclaro. La niebla del norte ha vuelto a tapar el cielo y los monstruos andan despiertos. El Amuleto del Alba, lo único que la mantenía a raya, se partió en tres, y en este pueblo las rodillas más jóvenes son las tuyas.

**Villaclaro: la Niebla del Norte** es un RPG por turnos en 3D con aire de los clásicos: un pueblo, un sendero y un mundo que se abre según avanzas.

- Recorre la pradera, el bosque, la vieja mina y el Castillo de la Niebla.
- Combate por turnos con hechizos, objetos, estados y debilidades.
- Cuatro jefes, cada uno con su truco.
- Tiendas, cofres, equipo y posadas que no cuestan nada.
- Seis misiones secundarias, con tablones de anuncios y gallinas que ponen de lado.
- Dificultad Fácil o Normal, textos grandes, teclas reasignables y velocidad de combate.

Una partida dura unas dos horas. Se juega con teclado o ratón.
```


- [ ] **Step 6: Check it**

Create `C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\probes\user_dir.gd`:

```gdscript
extends SceneTree
## Throwaway: where user:// is now. Never committed.


func _init() -> void:
	print(OS.get_user_data_dir())
	quit()
```

The desktop export templates are **not installed here**: `%APPDATA%\Godot\export_templates\4.7.2.stable\` only holds the web ones, and downloading them needs the user's permission. So `--export-release` can't run for Windows or Linux on this machine; the `release.yml` workflow does that on a `v*` tag. What can be checked here is `--export-pack`, which needs no template and exercises the preset and its filter, and that the pack runs.

```powershell
$env:APPDATA = "C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\appdata"
$data = "$env:APPDATA\Godot\app_userdata\rpg-turnos"
New-Item -ItemType Directory -Force $data | Out-Null
.\tools\godot.cmd --headless --path . --script "C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\probes\user_dir.gd"
foreach ($s in "title/title_screen","ui/display_settings") { .\tools\godot.cmd --headless --path . --check-only --script "res://scripts/$s.gd" }
New-Item -ItemType Directory -Force build\windows, build\linux | Out-Null
.\tools\godot.cmd --headless --path . --export-pack "Windows Desktop" build\windows\Villaclaro.pck
.\tools\godot.cmd --headless --path . --export-pack "Linux" build\linux\Villaclaro.pck
(Get-Item build\windows\Villaclaro.pck).Length / 1MB
$pck = "$PWD\build\windows\Villaclaro.pck"
$godot = "$PWD\tools\godot.cmd"
Push-Location $env:APPDATA
& $godot --headless --main-pack $pck --fixed-fps 10 --quit-after 1200 -- --autoplay | Select-String -Pattern 'Abuela Rosa:|ERROR' | Select-Object -First 5
Pop-Location
Remove-Item -Recurse build\windows, build\linux
```

Expected: the probe prints a path ending in `/Godot/app_userdata/rpg-turnos`, so the save has not moved; both packs written, about 3 MB; run from the pack (outside the project folder) the game plays (`Abuela Rosa: ...` lines). Windows's executable, its icon and the Linux binary stay unchecked here; see "Left open".

- [ ] **Step 7: Commit**

```powershell
git add icon.png icon.png.import CHANGELOG.md docs/itch .github project.godot export_presets.cfg scripts
git commit -m "Name the game, add its icon, cover, version, desktop presets and itch.io text"
```

---

### Task 6: Review pass, documentation, full runs and web export

**Files:**
- Modify: `CLAUDE.md`, `docs/boost/specs/ideas-sueltas.md`; any text or window the review finds wrong (the data or the script it comes from)

**Interfaces:**
- Consumes: everything above.
- Produces: the branch ready for review; nothing is merged, pushed, tagged or uploaded.

- [ ] **Step 1: The windows, worst case, in both text sizes**

Create `C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\probes\tour_windows.gd`:

```gdscript
extends SceneTree
## Throwaway: the worst case of every window, as PNGs, for the review pass. Never committed.
## Arguments after `--`: <large 0|1> <output folder>.

var _out := ""
var _tag := ""


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var options := GameOptions.new()
	options.large_text = args[0] == "1"
	_out = args[1]
	_tag = "large" if options.large_text else "normal"
	DisplaySettings.apply(root, options)
	var state := _full_state()
	var layer := CanvasLayer.new()
	root.add_child(layer)
	var back := ColorRect.new()
	back.color = Color(0.25, 0.4, 0.25)
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(back)
	var menu := PauseMenu.new()
	menu.setup(state, options, null)
	menu.in_village = func() -> bool: return false
	layer.add_child(menu)
	for page in ["main", "status", "items", "equipment", "journal", "options"]:
		menu._shade.show()
		menu._show_page(page)
		await _shot("pause_" + page)
	menu._options_panel._open_keys()
	await _shot("pause_keys")
	menu.hide()
	var shop := ShopWindow.new()
	shop.setup(state, null)
	layer.add_child(shop)
	shop._shop_id = "castillo"
	shop.show()
	shop._show_page("buy")
	await _shot("shop_buy")
	shop._show_page("sell")
	await _shot("shop_sell")
	shop.hide()
	var names := NameEntry.new()
	layer.add_child(names)
	await _shot("name")
	names.hide()
	var picker := DifficultyWindow.new()
	layer.add_child(picker)
	await _shot("difficulty")
	picker.hide()
	var box := DialogueBox.new()
	layer.add_child(box)
	var lines: Array[String] = ["Solo la magia le hace daño, y se escapa en cuanto puede. Quien lo alcance se quedará con lo que lleva encima."]
	box.say("Tablón", lines)
	await _shot("dialogue")
	box.hide()
	var hud: BattleHud = load("res://scenes/ui/battle_hud.tscn").instantiate()
	layer.add_child(hud)
	var foes: Array[Combatant] = [EnemyLibrary.data("slime").duplicate() as Combatant]
	state.hero.status[BattleEngine.POISON] = -1
	state.hero.status[BattleEngine.SILENCE] = 3
	state.hero.hp = state.hero.max_hp
	hud.set_engine(BattleEngine.new(state.hero, foes, RandomNumberGenerator.new(), state.inventory))
	hud.show_menu()
	hud._open(BattleHud.Page.ITEMS, 0)
	await _shot("battle_items")
	hud._open(BattleHud.Page.SPELLS, 0)
	await _shot("battle_spells")
	hud.hide()
	quit()


## Every item, every key item, every quest under way, a level-20 hero with every spell.
func _full_state() -> GameState:
	var state := GameState.new(load("res://data/hero.tres") as Combatant)
	state.hero.display_name = "Maximiliano".left(8)
	state.hero.experience = Leveling.EXP_TABLE[Leveling.MAX_LEVEL - 1]
	Leveling.apply(state.hero)
	state.gold = 99999
	for id in Inventory.IDS:
		state.inventory.add(id, 12)
	for id: String in Inventory.KEY_ITEMS:
		state.key_items.append(id)
	for id: String in QuestLog.QUESTS:
		state.quests.accept(state, id)
	state.quest.start()
	for id: String in Equipment.EQUIPMENT:
		state.bag_equipment.append(id)
	state.equip(Equipment.POISON_RING)
	return state


func _shot(page: String) -> void:
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	var path := "%s/%s_%s.png" % [_out, _tag, page]
	root.get_texture().get_image().save_png(path)
	print(path)
```

```powershell
$env:APPDATA = "C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\appdata"
$S = "C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad"
New-Item -ItemType Directory -Force "$S\frames" | Out-Null
foreach ($large in "0","1") { .\tools\godot.cmd --path . --resolution 1280x720 --script "$S\probes\tour_windows.gd" -- $large "$S/frames" }
```

Look at all 14 windows of `large_` (the tightest) and spot-check the others: nothing cut sideways; the tall lists (Objetos, Diario, the shop's Vender, Opciones) stop inside the window and scroll. Then the map: record `--autoplay` frames with `{"large_text": true}` in `options.json` and look at the status window, a notice, a dialogue, an exit sign (`Label3D`), a battle message and the title screen. If something runs over, shorten the text or widen the window, never the font.

The Diario must also scroll with the keyboard when it is taller than the screen (left open by Task 1); fix `ScrollBox` if the focus takes the keys.

- [ ] **Step 2: The text**

Read the Spanish texts once for typos (`data/` and the strings of `scripts/`), and check nothing about the hero is gendered: no `cansado/a`, `listo/a`, `solo/a`, `bienvenido/a` and the like about the hero. The default name "Héroe" stays: it is a name the player can replace, already in the game.

- [ ] **Step 3: Documentation**

Replace in `CLAUDE.md`:

```
`rpg-turnos`: a 3D turn-based RPG with a Dragon Quest-like look, made with Godot 4.7.2
```

with:

```
`rpg-turnos` (the game is called *Villaclaro: la Niebla del Norte*; its version is `application/config/version`, also shown on the title screen; `CHANGELOG.md` in Spanish): a 3D turn-based RPG with a Dragon Quest-like look, made with Godot 4.7.2
```

Replace in `CLAUDE.md`:

```
- `scripts/game/game_options.gd` (`GameOptions`, `RefCounted`) — music and effects volume (0..1, defaults 0.7 / 0.8) and `text_speed` (`SLOW` / `NORMAL` / `FAST`, `char_time()` 0.05 / 0.025 / 0.008 s per character); `to_dict()`, `from_dict()`.
```

with:

```
- `scripts/game/game_options.gd` (`GameOptions`, `RefCounted`) — music and effects volume (0..1, defaults 0.7 / 0.8), `text_speed` (`SLOW` / `NORMAL` / `FAST`), `combat_speed` (`X1` / `X2` / `INSTANT`; `combat_scale()` is `Engine.time_scale` during a battle, `char_time()` 0.05 / 0.025 / 0.008 s per character or 0 on `INSTANT`), `quality` (`HIGH` / `LOW`), `camera_shake`, `fullscreen`, `large_text`, `keys` (only what the player reassigned); `to_dict()`, `from_dict()` (older files keep loading, anything missing keeps its default).
- `scripts/ui/display_settings.gd` (`DisplaySettings`) — `apply(window, options)`: the window title, `content_scale_factor` 1.25 for large text (everything 2D grows, so every window must fit a virtual 1024 × 576), fullscreen on desktop, and the static `Vegetation.half_density` and `BattleStage.plain_light` the builders read for low quality (half the grass, no SSAO, no sun shadows; a change shows on the next map built).
- `scripts/game/key_map.gd` (`KeyMap`, `RefCounted`) — the InputMap actions `move_up`, `move_down`, `move_left`, `move_right`, `accept`, `cancel`, `pause` (defaults in `project.godot`: WASD and arrows; Enter, Keypad Enter, Space, E; Esc, Q, Backspace, X; Esc, P); `apply(overrides)` (also makes `ui_up`... `ui_accept`, `ui_cancel` follow them, so the menus take the same keys), `assign(overrides, action, code)` (replaces the first key; a key belongs to one action; refused if it is another action's only key), `keys_of()`, `keys_text()`, `first_key_name()`. `NameEntry` keeps fixed keys, since it types letters. `scripts/ui/keys_panel.gd` (`KeysPanel`) is the Teclas page.
- `scripts/game/difficulty.gd` (`Difficulty`, `RefCounted`) — `NORMAL` / `EASY` ("normal" / "easy"), in `GameState.difficulty` and the save: Fácil takes `EASY_DAMAGE` 0.7 of the damage (blows, spells, poison; `BattleEngine.damage_mult`) and earns `EASY_EXP` 1.25 of the EXP (`exp_mult`). `scripts/ui/difficulty_window.gd` (`DifficultyWindow`) asks after the name on a new game; the pause menu's Opciones can change it.
- `scripts/ui/ui_style.gd` (`UiStyle`) — the menus' shared colors, small text size and `add_description(parent, id)` (wraps at `DESCRIPTION_WIDTH`). `scripts/ui/scroll_box.gd` (`ScrollBox`, `ScrollContainer`) — `ScrollBox.new(reserved_height)`, fill `content`: hugs it and scrolls past the room the screen leaves (Objetos, Diario, the shop's rows, Opciones).
```

Replace in `CLAUDE.md`:

```
(`SaveData`, `RefCounted`) — pure: `from_state(state, player_pos, play_time)` → `Dictionary` (`version` 7 (`QUESTS_VERSION` adds
```

with:

```
(`SaveData`, `RefCounted`) — pure: `from_state(state, player_pos, play_time)` → `Dictionary` (`version` 8 (`DIFFICULTY_VERSION` adds `difficulty`, an older save plays on Normal; `QUESTS_VERSION` adds
```

Replace in `CLAUDE.md`:

```
 — WASD / arrows in screen axes (up = −Z), or `move_to(point)`
```

with:

```
 — the `move_*` actions (WASD / arrows by default) in screen axes (up = −Z), or `move_to(point)`
```

Replace in `CLAUDE.md`:

```
 — music and effects sliders (0-100 % in steps of 10) and text speed (Lenta / Normal / Rápida), applied at once; `setup(options, audio)`,
```

with:

```
 — music and effects sliders (0-100 % in steps of 10), text speed, combat speed, graphics, shake, large text, fullscreen (not on the web), difficulty (with a `state`, from the pause menu) and Teclas, applied at once, in a `ScrollBox`; `setup(options, audio, state = null)`,
```

Replace in `CLAUDE.md`:

```
- Known noise: runs with `--fixed-fps`
```

with:

```
- A new game on Fácil on autoplay: add `--autoplay-easy`. Any option in a run: write it in `user://options.json` first, e.g. `{"large_text": true}` (with `APPDATA` pointing elsewhere, so the real one stays).
- Known noise: runs with `--fixed-fps`
```

Replace in `CLAUDE.md`:

```
Preview it with any static server on `build/web`.
```

with:

```
Preview it with any static server on `build/web`. Run `mkdir build/web` first. Desktop: the presets `Windows Desktop` and `Linux` need the desktop export templates (only the web ones are installed on this PC); `--export-pack "Windows Desktop" build/x.pck` checks a preset without them. `user://` stays at `Godot/app_userdata/rpg-turnos` (`config/custom_user_dir_name`), whatever the game's name.
```

Replace in `CLAUDE.md`:

```
`.github/workflows/pages.yml` downloads Godot 4.7.2
```

with:

```
`.github/workflows/release.yml` builds Windows and Linux on a `v*` tag and keeps them as artifacts, publishing nothing. `docs/itch/` holds the page's text, cover and screenshots; uploading to itch.io is done by hand. `.github/workflows/pages.yml` downloads Godot 4.7.2
```

Replace in `docs/boost/specs/ideas-sueltas.md`:

```
- **Estado:** aplazada a futuras versiones.
```

with:

```
- **Estado:** fuera de la fase 7 (zoom con dos dedos, botones más grandes, aviso táctil y rendimiento en un móvil medio). Es lo primero al acabarla, con su propio diseño y plan.

## Lo que no entra en la versión 1.0

- **Fecha:** 2026-11-06
- **Idea:** lo que queda fuera de la fase 7 ([plan](../plans/2026-11-06-pulido-publicacion.md)).
- **Notas:**
  - Inglés: descartado por el usuario, el juego queda solo en español.
  - Subir a itch.io: el material está en `docs/itch/`, y subirlo lo decide y lo hace el usuario.
  - Probar los ejecutables de Windows y Linux: las plantillas de escritorio no están en este PC; los genera el workflow con un tag `v*`.
  - Mando, tutoriales, bestiario, ciclo de día y noche, correr, exportar la partida y partida nueva +: siguen en `2026-11-03-ideas-juego-completo.md`, sin plan.
- **Estado:** sin decidir.
```

- [ ] **Step 4: Full runs**

Each one must end in `Juego completado:` with no stall and no ERROR or WARNING but the Jolt one. Both difficulties; then the fastest combination; then the save round trip. Headless, under a minute or two each.

```powershell
$env:APPDATA = "C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\appdata"
$data = "$env:APPDATA\Godot\app_userdata\rpg-turnos"
New-Item -ItemType Directory -Force $data | Out-Null
$runs = @(
	@{ options = '{}'; args = @("--autoplay") },
	@{ options = '{}'; args = @("--autoplay", "--autoplay-easy") },
	@{ options = '{"combat_speed": 2.0, "quality": 1.0, "camera_shake": false, "large_text": true}'; args = @("--autoplay") }
)
foreach ($run in $runs) {
	$run.options | Out-File -Encoding ascii "$data\options.json"
	Remove-Item -ErrorAction SilentlyContinue "$data\save_autoplay.json"
	.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 150000 -- @($run.args) | Select-String -Pattern 'Juego completado|ERROR|WARNING'
}
Remove-Item "$data\options.json"
Remove-Item -ErrorAction SilentlyContinue "$data\save_autoplay.json"
.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 6000 -- --autoplay --autoplay-save | Select-String -Pattern 'Guardado|Cargado|ERROR'
Remove-Item -ErrorAction SilentlyContinue "$data\save_autoplay.json"
```

Expected: `Juego completado: Nv n, tiempo de juego h:mm:ss, misiones n` three times; the Normal run at the usual Nv 18 and 1:16-1:27 (1:30 or a little over is still fine), the Easy run at about 1:00 (level for level, Fácil reaches each boss sooner), the fast one at about 0:50. `Guardado:` and `Cargado:` identical. An old save: Task 4's probe already loads version 7.

- [ ] **Step 5: Performance on the desktop**

Windowed, real time, high and then low quality; `--print-fps` prints the frames per second to the console. This measures the native build under the same Compatibility renderer the web uses; the web itself the user checks in the browser when they play the export.

```powershell
$env:APPDATA = "C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\appdata"
$data = "$env:APPDATA\Godot\app_userdata\rpg-turnos"
'{"quality": 0.0}' | Out-File -Encoding ascii "$data\options.json"
.\tools\godot.cmd --path . --print-fps --quit-after 1500 -- --autoplay | Select-String -Pattern 'FPS' | Select-Object -Last 3
'{"quality": 1.0}' | Out-File -Encoding ascii "$data\options.json"
.\tools\godot.cmd --path . --print-fps --quit-after 1500 -- --autoplay | Select-String -Pattern 'FPS' | Select-Object -Last 3
Remove-Item "$data\options.json"
Remove-Item -ErrorAction SilentlyContinue "$data\save_autoplay.json"
```

Expected: low no worse than high, both well over 30 on this PC (the replay read 75 in both, the monitor's cap). If high falls under 30 on the meadow, `Vegetation.SPACING` is the first thing to raise.

- [ ] **Step 6: Web export**

This one needs the real `APPDATA`, where the templates live, and it writes no save. In a new PowerShell session (or with `Remove-Item Env:APPDATA` first, then reopened):

```powershell
New-Item -ItemType Directory -Force build\web | Out-Null
.\tools\godot.cmd --headless --path . --export-release "Web" build/web/index.html
(Get-Item build\web\index.pck).Length / 1MB
python -c "d=open('build/web/index.pck','rb').read(); print(b'scripts/tools' in d, b'docs/itch' in d, b'portada' in d)"
```

Expected: written with no ERROR; `index.pck` about 3 MB; `False False False`: the tools and the itch.io material are out. Delete nothing else; `build/` is git-ignored.

- [ ] **Step 7: Commit**

```powershell
git add CLAUDE.md docs/boost/specs/ideas-sueltas.md docs/boost/plans/2026-11-06-pulido-publicacion.md
git add scripts data
git commit -m "Document the polish phase and finish the review of the texts"
```

Stop here: no merge, no push, no tag, no upload.

---

## Replay

The plan was replayed on a copy of `28db326`, with English included, before the user dropped it. Tasks 1 to 4 were implemented from that text. Tasks 5 and 6 were edited afterwards and not replayed without English, so an anchor can differ: the code wins.

## Left open

- **Windows and Linux executables are not built or started here**, as the spec asked: the desktop templates aren't installed, and downloading them needs the user's permission. A `v*` tag or the workflow's manual run builds them; then someone starts the `.exe` and checks its icon. `application/modify_resources` and the Linux binary are only proven by that run.
- **Playing it by hand:** reassigning keys, fullscreen, the difficulty window with the keyboard, and the web build's real FPS in a browser need a person at the machine.
- **Screenshots** are chosen by whoever runs Task 5, from the frames its Step 4 records.
- Uploading to itch.io, tagging and merging to `main` are the user's call.

## Self-review

- **Spec:** options (Task 2), difficulty (Task 4, with its own save version), accessibility: large text and shake (Task 2), keys (Task 3); Windows and Linux presets, workflow, version, changelog, name, icon, cover, itch.io text (Task 5); review pass, docs, runs, export (Task 6). The five open items: overlap, scroll, duplicates and wrapping, typed names (Task 1).
- **Not here on purpose:** English and any other language (dropped by the user), two-finger zoom, bigger buttons, touch prompt, phone performance (next plan), uploading, a tag, consoles.
