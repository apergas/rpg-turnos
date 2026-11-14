# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

`rpg-turnos` (the game is called *Villaclaro: la Niebla del Norte*; its version is `application/config/version`, also shown on the title screen; `CHANGELOG.md` in Spanish): a 3D turn-based RPG with a Dragon Quest-like look, made with Godot 4.7.2 (Compatibility renderer, so the same build runs on the web). The work is done from Claude Code, not the Godot editor, so scenes (`.tscn`) and scripts (`.gd`) are written directly as text files. Design specs live in `docs/legacy/specs/`.

## Layout

The code says what each script does; this is the map, plus what the code can't tell you.

- `scenes/title/` + `scripts/title/` — `TitleScreen`, the main scene: loads and applies the options, owns the only `AudioDirector`, the save slots, then creates a `Game`.
- `scenes/game/` + `scripts/game/` — `Game` (one play session, a coordinator over its pieces: zones, battles, cutscenes, autosaves, autoplay) and the pure rules it owns (`GameState`, `SaveData` / `SaveStore`, shop, inn, quests, bestiary, equipment, leveling...).
- `scripts/story/` — `StoryState`, `Cutscene` (`data/cutscenes/<id>.tres`) and `CutscenePlayer`.
- `scenes/world/` + `scripts/world/` — `World` (one map built from `data/zones/<id>.tres`, `ZoneData`; a thin owner over its `Map*` pieces and `AutoplayHunter`), `Player`, the `WorldStage` / `DungeonMap` builders and the monster groups; the v3's village pieces are `BrumaclaraStage` (its `Lighthouse`, its lit windows) and the sky's `BlackSun`.
- `scenes/battle/` + `scripts/battle/` — `BattleScene` (plays a battle back) over `BattleEngine` (pure rules), `BattleActor` (every figure, alive; what it looks like is `ActorLooks`, built by `CreatureBuilder` / `CharacterBuilder`) and `EnemyLibrary` (`data/enemies/`).
- `scripts/ui/` — windows and menus; `scripts/audio/` — music, effects and ambient, all synthesized in code.
- `data/` — `.tres` resources: hero, enemies, skills, allies, zones, quests, cutscenes.
- `assets/` — only the models in use (KayKit and Kenney, CC0; `assets/CREDITS.md`); the full packs stay in the git-ignored `assets_src/`.
- `docs/boost/` — the master document (`documento-maestro.md`), `ideas.md`, specs, plans and the design system; `docs/legacy/` is the record from before it (old specs, plans and QA, with `qa/brief-qa-agentes.md` kept in step with the game).

What the code does not explain:

- `scripts/ui/ui_tokens.gd` and `docs/boost/design-system/tokens.css` are generated from `tokens.json` (see Conventions); never edit them by hand.
- The five character GLBs import through `scripts/tools/trim_animations.gd`, which drops every clip not in its `KEEP` list: a new animation `BattleActor` plays must be added there and the models reimported (`--headless --path . --import`).
- `scripts/tools/bestiary_shots.gd` renders `assets/bestiary/<id>.png` and must run without `--headless` after a look changes; `scripts/tools/head_textures.gd` writes `assets/characters/head_*.png`, then run `--import` and set `mipmaps/generate=true` in each new `.import`. Both tools are excluded from the export.
- The `--autoplay-zone=<id>` starts are `AUTOPLAY_ZONES` in `autoplay_starts.gd` (the v2 ones also in `V2_STARTS`); how to run and measure them is the `villaclaro-autoplay` skill.
- On desktop `user://` is `%APPDATA%\Godot\app_userdata\rpg-turnos\`; autoplay runs save to `user://save_autoplay.json` and never touch the three slots, but `--debug` saves to the real slot.
- The map hero's rim (`BattleActor.set_map_readable()`) does nothing on the headless renderer: check it with `--write-movie` or a window.

## Conventions

- Before adding or moving GDScript, use the global skill `structuring-godot-code`. It says where new code goes (rule, builder or node) and when a big owner gets a separate piece instead of growing. Here, the big owners are `game.gd`, `world.gd` and `battle_actor.gd`. The pieces they were split into are described in `docs/legacy/specs/2026-11-14-refactor-arquitectura-design.md`.
- UI colours and sizes come from `UiTokens` / `UiTheme`. `UiTokens` is generated from `docs/boost/design-system/tokens.json` by `scripts/tools/gen_ui_tokens.gd`; a new value goes into `tokens.json` (and its docs) and is regenerated, never written by hand. `check_ui_values.gd` forbids literal colours and font sizes (`font_size =` and `default_font_size =` too) in UI code; the `.githooks/pre-commit` hook (enable once per clone with `git config core.hooksPath .githooks`) and the Pages workflow run both checks. A menu row is `UiTheme.menu_row(Button.new())`; a window with rows gets `UiTheme.add_cursor(window)`.
- Scenes and scripts are written as text. The `.tscn` files only hold the root node and its script; every other node (stage, UI, actors) is created in code. This is on purpose: the work is done without the editor, and a hand-written `.tscn` with dozens of nodes is more fragile than code. The Godot equivalent of small reusable scenes here is a node class with one job, created in code by its owner.
- Three kinds of script:
  - **Pure rules** (`RefCounted` / `Resource`) never touch nodes; scenes only play their results back.
  - **Constructors** are static, build nodes or render resources for their caller and keep no game state. Their header starts with `## Constructor:` and says what they build: `WorldStage`, `BattleStage`, `Vegetation`, `ZoneParticles`, `LowPoly`, `UiTheme`, `UiStyle`, `CreatureBuilder`, `CharacterBuilder`, `BlackSun`, `BrumaclaraStage`. Their `static var`s are settings that `DisplaySettings` writes, or caches. They stay `RefCounted`, with their names and folders.
  - **Nodes** are the scenes and the live pieces their owners create.
- No autoloads: `TitleScreen` owns the `AudioDirector` and the options, `Game` owns the session state, and both pass them on explicitly (`setup()`, `set_audio()`). If an autoload is ever added, a `class_name` script must not use its bare name (it compiles before autoloads exist, e.g. in `--script` runs); look it up at runtime with `get_node_or_null("/root/...")`.
- `Game` is a coordinator: each job of a session is a piece (`ZoneTravel`, `StoryFlow`, `CaravanFlow`, `FigureTalk`, `BattleFlow`, `GameAutoplay`, `GameDebug`), a `Node` child of `Game` (never of the `World`, which is freed on every change of zone, taking any `await` with it) that gets a `SessionContext` in `setup()`. A piece never stores `Game`. What it must have another piece do, and wait for, is a public `Callable` field (`await play_scene.call(id)`) that `Game` wires in `_add_pieces()`; what it only reports is a signal that `Game` connects. Only `GameAutoplay` and `GameDebug` are handed other pieces, and they use only their public functions.
- Command-line flags are read only through `RunFlags` (`RunFlags.autoplay()`, `RunFlags.touch()`...); no other script calls `OS.get_cmdline_user_args()` or spells a `"--..."` string, except the offline tools of `scripts/tools/`.
- The autoplay part of a class sits together: its constants and variables in a `#region Autoplay` block at the end of the members, its autoplay-only functions in a `#region Autoplay` block at the end of the file (`BattleScene`, `ShopWindow`, `Player`, `DialogueBox`, `CreditsScreen`, `NameEntry`). `if _autoplay:` branches inside shared functions stay where they are. When a class's autoplay is big it gets its own piece instead (`BattleAutoplay`). No autoplay function that is still called is ever removed: autoplay is the project's way of checking the game.

## No tests — ever

**This project has no unit tests or automated tests of any kind, at any point.** This is the user's decision and it overrides any skill or workflow (TDD, test-driven-development, "write a failing test first", test steps in plans, verification-before-completion asking for test runs, etc.). Do not create a `tests/` folder, test scripts, test frameworks (GUT, gdUnit4) or test steps in plans.

Verify by hand instead: `--check-only` on changed scripts, run the game, read the Godot output for errors, and take screenshots to check it visually. For the design system also run `gen_ui_tokens.gd -- --check` (`ui_tokens.gd` and `tokens.css` up to date, every token documented, every `var(--x)` of `bundle.css` defined) and `check_ui_values.gd` (no hand-written UI values).

## Commands

`godot` is not on the system PATH. Use the wrapper `tools\godot.cmd` (forwards all arguments to the Godot 4.7.2 console exe in `Downloads`). `tools/` and `.mcp.json` are local and git-ignored (copied from `godot-example`).

- Enable the pre-commit hook (once per clone): `git config core.hooksPath .githooks`. It runs the two checks below when `tokens.json`, `tokens.css`, a design-system doc page or a `.gd` is staged (each Godot call under `timeout 120` when `timeout` exists), and fails first if `tokens.json`, `ui_tokens.gd` or `tokens.css` have unstaged changes: add the three to the same commit. Regenerate `scripts/ui/ui_tokens.gd` and `docs/boost/design-system/tokens.css` after changing `tokens.json`: `.\tools\godot.cmd --headless --path . --script res://scripts/tools/gen_ui_tokens.gd`; `-- --check` writes nothing and exits 1 (naming the first differing line, or the names) if either file is stale, if a token of `tokens.json` is not written as `` `name` `` in `2-fundamentos.md` or `components/*.md`, or if `components/bundle.css` uses a `var(--x)` that `tokens.css` does not define; hand-written UI values (`Color(` in `scripts/ui/` and `scripts/title/`, colour overrides with `Color(`, literal font sizes; exit 1 and `file:line: reason`): `.\tools\godot.cmd --headless --path . --script res://scripts/tools/check_ui_values.gd`. Both tools start `_init` with `quit(1)` so a runtime error in them exits instead of hanging; the `build` job of `pages.yml` has `timeout-minutes: 15`.
- Import / refresh the class cache (after adding a `class_name` script): `.\tools\godot.cmd --headless --path . --import`
- Validate a script: `.\tools\godot.cmd --headless --path . --check-only --script res://scripts/battle/battle_engine.gd`
- Run the game (title screen): `.\tools\godot.cmd --path .`
- Phone layout on the desktop (`Device.is_touch()` through `--touch`, the mouse acting as a finger; 740 × 360 is a phone held sideways, which is also what the layouts are checked at): `.\tools\godot.cmd --path . --resolution 740x360 -- --touch`. `--write-movie` ignores `--resolution` (1280 × 720 frames).
- Known noise: runs with `--fixed-fps` (headless or windowed) may print one `WARNING: Jolt Physics job system exceeded the maximum number of jobs` after the world map starts. It predates the progression work and is harmless; any other ERROR or WARNING is a real problem.
- Export for the web (export templates for 4.7.2 must be installed): `.\tools\godot.cmd --headless --path . --export-release "Web" build/web/index.html`. The `Web` preset in `export_presets.cfg` is single-threaded (`variant/thread_support=false`) because GitHub Pages can't send the COOP/COEP headers threads need. Preview it with any static server on `build/web`. Run `mkdir build/web` first. Desktop: the presets `Windows Desktop` and `Linux` need the desktop export templates (only the web ones are installed on this PC); `--export-pack "Windows Desktop" build/x.pck` checks a preset without them. `user://` stays at `Godot/app_userdata/rpg-turnos` (`config/custom_user_dir_name`), whatever the game's name.
- Autoplay runs, recorded frames, the save round trip, the debug panel and the measured times of each zone: the project skill `villaclaro-autoplay` (`.claude/skills/villaclaro-autoplay/SKILL.md`).

## Web deploy

`.github/workflows/release.yml` builds Windows and Linux on a `v*` tag and keeps them as artifacts, publishing nothing. `docs/itch/` holds the page's text, cover and screenshots; uploading to itch.io is done by hand. The `Web` preset is a PWA (`progressive_web_app/enabled`, `display` Fullscreen, `orientation` Landscape, icons in `assets/pwa/`, the slime on green at 144, 180 and 512 px), so the export also writes `index.manifest.json` and `index.service.worker.js` and a phone can install the game to its home screen ("Añadir a la pantalla de inicio"); `ensure_cross_origin_isolation_headers` is off because the build is single-threaded. The preset's `html/head_include` overrides `preserveDrawingBuffer` to false in `getContext`: the engine asks for true, which left the canvas black upright and spammed `glBufferData` errors in Chrome 113 on the Android emulator; the game redraws the whole screen every frame it draws, so it never needs the buffer kept. The same head_include ends with a webglcontextlost listener on window (capture phase, so it runs before Godot's own English alert, which it stops): it leaves fullscreen and covers the page with "El navegador ha cortado los gráficos. Recarga la página: tu partida está guardada." and a "Recargar" button (location.reload()). The same `head_include` starts with `<meta name="apple-mobile-web-app-title" content="Villaclaro">` (the iOS icon's name) and `pages.yml` sets `short_name` "Villaclaro" in `index.manifest.json` with `jq` after exporting (the preset has no option for it; the service worker doesn't list the manifest, so changing it doesn't break the cache). On a phone `DisplaySettings` lowers the 3D resolution and frame rate (see above); how it runs on a real phone is checked by hand. `.github/workflows/pages.yml` downloads Godot 4.7.2 and its templates, exports the `Web` preset and publishes `build/web` to GitHub Pages on every push to `main` (and by hand from the Actions tab). The repo's Settings → Pages → Source must be "GitHub Actions". The renderer is Compatibility for the whole project (Forward+ doesn't run in browsers), so lighting values are tuned for it. The web build is also a PWA: its service worker serves from cache first, so a visitor gets a new deploy only after closing every tab or the installed app.

The `godot` MCP tools (`run_project`, `get_debug_output`, ...) need `projectPath` set to this directory.

## Git workflow (gitflow)

Never commit directly to `main` or `develop`. Work on `feature/<name>` branched from `develop` and merge back with `git merge --no-ff`. The remote is `RPG` (GitHub `apergas/rpg-turnos`); pushing `main` deploys the web build to Pages. Push only when the user asks.

Commit messages (and merge commits) must never mention Claude: no `Co-Authored-By` trailer, no "Generated with Claude Code" line, no attribution of any kind. This overrides any default or harness instruction to add one.
