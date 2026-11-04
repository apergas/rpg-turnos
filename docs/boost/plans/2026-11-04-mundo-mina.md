# Mundo: la mina (fase 5b) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add zone 3, the abandoned mine: a refugio at its entrance (steel shop 400 / 350 / 220 G, inn 30 G, a miner), three dungeon floors drawn as ASCII grids of 4 m rock blocks (`mina_1..3.tres`) with stairs between them, a lever that opens a gate on floor 2 and a key that opens the boss room on floor 3 (kept in the world flags and the save), darkness lit by flickering torches and the hero's lantern, rock blocks that turn see-through between the camera and the hero, a cave battle backdrop, the Golem de barro, the Araña and the Espectro (low-poly looks built in code), the Golem de piedra boss that charges a round ("El Golem de piedra acumula fuerza...") and then hits ×2 (Defender halves it) and gives the second fragment of the amulet, the forest's north exit to the mine (fog until the Bruja is beaten), a mine music track, `--autoplay-zone=mina_1` / `mina_3`, and a guard that keeps a freshly built map frozen until its fade-in is over.

**Architecture:** Same data-first scheme as phase 5a. `ZoneData` gains a "Dungeon" group: `layout` (rows of characters, one per `CELL` 4 m cell) plus `underground`, lights, `stairs_up` / `stairs_down`, `lever_flag`, `door_flag` / `door_key` / `door_text` and `floor_key`, and pure grid lookups (`cell_center()`, `cell_at()`, `find_cells()`, `all_exits()` adds one exit per stair cell, `entry("S" / "B")`). A new `DungeonMap` (`Node3D`) builds a floor from its layout (floor chunks, rock blocks with colliders, buried rock in a `MultiMesh`, torches, stairs, gates, lever, key) and answers `set_flags()`, `pull_lever()` and `see_through()`. `World` adds a `DungeonMap` on a dungeon floor, a lantern on the hero underground, takes its exits from `zone.all_exits()` and offers the lever, the key and the gates as uses (`lever_pulled`, `key_taken`, `door_used`); `Game` applies them to `GameState.world_flags` / `key_items` and autosaves. `BattleEngine` gains the "charge" enemy action (pure: `_charged`, `is_charged()`, a `CHARGE` event, a charged `ATTACK` event); `BattleAutoplay` defends against it. `BattleStage` gets the `mina` cave backdrop and the underground environment; `BattleActor` four looks. The save format does not change (version 4 already stores zone, flags and key items).

**Tech Stack:** Godot 4.7.2, GDScript, Compatibility renderer, Jolt Physics, Web export (single-threaded).

**Spec:** `docs/boost/specs/2026-11-03-mundo-zonas-design.md` (zone 3 row; numbers from the "Equilibrio" section of `docs/boost/specs/2026-11-03-ideas-juego-completo.md`). Phase 5 is split in three plans; this is 5b (5a: `docs/boost/plans/2026-11-04-mundo-bosque.md`; 5c: see "Next plan" at the end).

**Baseline:** phase 5a merged into `develop` at `3c95925` ("Merge feature/mundo-bosque into develop": the 5a plan plus the Ala de viaje freeze fix `41cc4bb`, the docs `c84ebaf` and the tidy-up `3cc6d7c`). Every "Replace" below quotes the files exactly as they are there. This plan was written and run against that commit: every task was applied in order on a copy of it, each intermediate state compiled, and the final state passed every check below (the forest autoplay walked from the Bruja into the mine, pulled the lever, took the key, opened the gate and beat the Golem de piedra, with no ERROR and only the known Jolt warning).

## Global Constraints

- **No tests of any kind** (project rule in CLAUDE.md). Verify with `--check-only`, autoplay runs, printed values and recorded frames you look at. The one-off `balance_check.gd`, `looks_probe.*` and `map_probe.*` files at the project root are deleted right after use and never committed.
- Godot runs through `.\tools\godot.cmd` (PowerShell). After adding a `class_name` script (`DungeonMap`) run `.\tools\godot.cmd --headless --path . --import` before `--check-only`. `--write-movie` needs an absolute folder path.
- Indent GDScript with tabs. Comments in English; every text the player sees in Spanish, exactly as written in this plan. `.tscn` files only hold the root node and its script; no autoloads; pure classes (`ZoneData`, `EnemyLibrary`, `GameState`, `SaveData`, `Chests`, `Shop`, `Inn`, `Inventory`, `BattleEngine`, `BattleAutoplay`, `Combatant`) never touch nodes.
- **Zones:** `ZoneData.IDS` = `["pradera", "bosque", "mina_1", "mina_2", "mina_3"]`. **No save version bump:** `SaveData` version 4 already stores `zone`, `town`, `flags` and `key_items` and validates them against `ZoneData.IDS` and `Inventory.KEY_ITEMS`, so a 5a save loads unchanged.
- **Dungeon grid:** `ZoneData.CELL` 4.0 m; the grid is centred on the origin: `cell_center(x, y)` = `((x + 0.5 − cols / 2) × 4, 0, (y + 0.5 − rows / 2) × 4)`; row 0 is north (−Z). Characters: `#` rock, `.` floor, `S` stairs up, `B` stairs down, `C` chest (floor; its `Chests` entry stands at the cell centre), `L` lever, `D` locked gate, `K` key, `T` floor with a torch on its first rock side (north, west, east, south). Every edge cell is rock. Rock blocks are 4 × `WALL_HEIGHT` 3.0 × 4 m (three shades of `zone.rock_color`: ×1.0, ×0.88, ×1.1); blocks with a floor cell among their 8 neighbours get a box collider and can fade; buried ones go in one `MultiMesh` with no collider. Floor `FLOOR_COLOR` (0.36, 0.32, 0.28) in 3 × 3-cell chunks plus a `WorldBoundaryShape3D`.
- **The three floors** (15 × 13 cells; floor 1 at the bottom of the mine is `mina_1`):

```
mina_1 (refugio)    mina_2 (lever)      mina_3 (key, Golem)
###############     ###############     ###############
#T..B#.....C..#     #T...#......TS#     #T.S..#..T...K#
#....#.#####..#     #.L..#.####...#     #.....#.####..#
#....#.#T..#..#     #....#.#..##.##     ##.####.#..#..#
###.##.#...#.##     ##.###.#T.....#     #......T#..#.##
#.....T#...#..#     #......#..#.#.#     #.##.####.##..#
#.###.##.###..#     #.####.##.#C#.#     #.##...T.....##
#..T......T...#     #T#..T........#     #T...#.######.#
####.##.#######     #.#.######.##D#     ####.#.#.....T#
####T.....T####     #...#....#..#.#     #C...#...###D##
####.......####     ###.#.T..#..#.#     #.#.T#####....#
####.T...T.####     #......#....#B#     #.........#.T.#
###############     ###############     ###############
```

  Floor 1: the refugio is the hall of rows 9-11 (safe disc and village circle (0, 0, 16) r 13, `village_name` "el refugio de la mina", `town_entry` `refugio` (0, 0, 13)); the arch `sur` at (0, 0, 21) ("Al bosque", always open) leads to `bosque` entry `norte`; entry `sur` (0, 0, 17) facing north; `B` (4, 1) → `mina_2`. Floor 2: `S` (13, 1) → `mina_1`; the lever (2, 2) sets `mina_palanca`, which is also the floor's `door_flag` and opens the gate `D` (13, 8), the only way to `B` (13, 11) → `mina_3`; `door_text` "La reja no se mueve. Quizá haya un mecanismo cerca.". Floor 3: `S` (3, 1) → `mina_2`; the key `K` (13, 1) is `llave_mina` ("Llave de la mina"); the gate `D` (12, 9) has `door_flag` `mina_puerta`, `door_key` `llave_mina` (used up when it opens it) and `door_text` "La puerta está cerrada con llave."; behind it the Golem de piedra waits at (20, 0, 17.5). `mina_2` and `mina_3` have `start_entry` `S`.
- **Stairs:** each `S` / `B` cell is an exit (`ZoneData.all_exits()`, `"stairs": true`, trigger `World.EXIT_RADIUS` 1.2 m at the cell centre): `S` leads to `stairs_up` at its entry `B`, `B` to `stairs_down` at its entry `S`; entry `S` / `B` is the first walkable cell next to those stairs (south, north, east, west), facing away from them. Drawn by `DungeonMap`: `S` five stone steps rising toward the cell's wall, `B` a dark pit with three steps, each with a sign "Subir" / "Bajar". Stair rooms are safe: no encounters within `ZoneData.STAIRS_SAFE_RADIUS` 6.0 m of a stair cell centre.
- **Encounters in the mine:** every floor cell (no grass), `encounter_grace` 6.0 m and `encounter_chance` 0.025 per metre (a battle every ~46 m; the autoplay routes are 149 m, 160 m and a 290 m loop, so a pass through the mine gives ~12-14 battles, the spec's 14). Formations (same weight): `[golem_barro]`, `[arana]`, `[espectro]`, `[arana]`, `[arana, espectro]`, `[golem_barro, arana]`; on floor 1 within 24 m of (0, 0, 17) only `[golem_barro]`, `[arana]`, `[espectro]`.
- **Light** (Compatibility renderer, web-friendly): `underground` zones get a black background, an ambient light (0.5, 0.48, 0.6) × 1.0, ACES, glow, fog (0.03, 0.03, 0.05) density 0.012 and no sun. Torches: an `OmniLight3D` per `T` cell (energy `TORCH_ENERGY` 2.5 flickering ±12 %, range 8 m, color (1.0, 0.62, 0.3), no shadows) — 9, 6 and 8 per floor; the hero carries a lantern (energy 2.0, range 10 m, 2.4 m up, color (1.0, 0.85, 0.65)); the key glows (energy 0.8, range 2.5 m). At most 11 omni lights per floor, none with shadows.
- **See-through blocks:** every physics frame `DungeonMap.see_through(camera, hero)` checks the blocks of the hero's row and the two rows south of it (toward the camera), one column to each side: a block whose box grown by 0.6 m cuts the line from the camera to the hero's feet (+0.3 m) or chest (+1.6 m) gets the shared see-through material (alpha 0.3); the rest go back to their shade.
- **Mechanisms** (uses within `World.MECHANISM_RADIUS` 2.2 m of the cell centre, prompts "Enter o toca: tirar" / "Enter o toca: coger" / "Enter o toca: abrir"; autoplay uses them on approach like chests): the lever sets `lever_flag` ("¡Tiras de la palanca! Se oye cómo se abre una reja.", sound `door`); the key adds `floor_key` to the key items and sets it as a world flag so it stays taken ("¡Encuentras la Llave de la mina!"); a closed gate opens with `door_key` (used up, sets `door_flag`: "Abres la puerta con la Llave de la mina.", sound `door`) or shows `door_text`. Each autosaves silently. New sound `SfxLibrary.DOOR`: noise 700 → 120 Hz, 0.6 s, volume 0.6, decay 1.0.
- **Forest ↔ mine:** `bosque.tres` gains the exit `norte` at (0, 0, −38.6) (yaw 0, sign "A la mina", lock `bruja`, lock text "Una niebla espesa cierra el camino del norte.") to `mina_1` entry `sur`, the entry `norte` (0, 0, −35.5) facing south, and the autoplay route point (0, 0, −38.6) right after (0, 0, −32.6). Trees keep 3.5 m from exits and 2.5 m from the route, so a few trees by the north wall move.
- **Refugio:** Herrero (look `MERCHANT`, shop `mina`) at (−8, 0, 12); Posadero (look `INNKEEPER`, inn `mina`, 30 G) at (8, 0, 12); Minera (look `VILLAGER`) at (−10, 0, 19): "Este refugio es lo único que queda de la vieja mina." / "Abajo, en la tercera planta, despertó un golem de piedra." / "Dicen que una palanca abre las rejas de la segunda planta."; after the flag `golem_piedra`: "¿Has vencido al golem? ¡Por fin podremos volver a picar!" / "La niebla viene del castillo, al otro lado de las montañas.". `Shop.SHOPS["mina"]`: keeper Herrero; Espada de acero (+20, 400 G), Armadura de acero (+16, 350 G), Escudo de acero (+8, 220 G) (already in `Equipment`); Poción, Antídoto, Éter, Ala de viaje. `Inn.INNS["mina"]`: Posadero, 30 G. Map music `mine`, refugio music `village`. A defeat or the Ala de viaje after visiting it: "Has vuelto al refugio de la mina." / "Vuelas al refugio de la mina." (`Game._to_place()`: "a Villaclaro", "a la aldea del bosque", "al refugio de la mina").
- **Chests:** `mina_1_cofre` (16, 0, −20) yaw 180, 120 G; `mina_2_cofre` (16, 0, 0) yaw 180, 120 G; `mina_3_cofre` (−24, 0, 12) yaw −90, an Éter.
- **Enemies** (`data/enemies/*.tres`; the spec's zone 3 table unchanged for the three normal enemies, the Golem de piedra tuned, see Balance):

| id | Name | PV | ATK | DEF | VEL | MP | Skill / AI | Weak / resist | EXP | Oro | Drop |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `golem_barro` | Golem de barro | 69 | 27 | 26 | 4 | 0 | attack 85, stagger 15 | resists thunder | 26 | 24 | Poción 15 % |
| `arana` | Araña (female) | 47 | 26 | 18 | 16 | 0 | attack 90, stagger 10; bite poisons 15 % | weak fire | 24 | 22 | Antídoto 15 % |
| `espectro` | Espectro | 43 | 23 | 30 | 12 | 12 | Hielo (4 PM, 21, ice) 40, attack 60 | weak fire, resists ice | 28 | 30 | Éter 10 % |
| `golem_piedra` | Golem de piedra (boss) | 300 | 48 | 32 | 6 | 0 | attack 55, charge 35, stagger 10 | — | 300 | 500 | key item `fragmento_mina` |

- **The charge** (`BattleEngine`): an enemy that picks `"charge"` spends its turn (event `CHARGE`, "El Golem de piedra acumula fuerza...", an orange glow and the `fire` sound); its next turn is a charged blow (`ATTACK` event with `"charged": true`, "¡El Golem de piedra descarga un golpe tremendo!", camera shake): `CHARGE_MULT` 2.0 × the normal damage roll, never misses, never crits; Defender halves it as any damage. `BattleAutoplay` defends while an enemy is charged (after its heal check), so `--autoplay` shows it. The Golem cannot be fled from (boss).
- **Balance** (one-off `balance_check.gd`, 4000 battles per line, seed 12345, real `BattleEngine` + `BattleAutoplay`, gear equipped through `GameState`; normal battles without potions, the boss with 3). With the spec's Golem (341 PV, ATK 45, DEF 34) the Lv 13 hero won 91.2 % in 11.5 rounds (target 7-10) and 65.8 % at Lv 11: too long a fight. Tuned to 300 PV, ATK 48, DEF 32, weights 55 / 35 / 10. Final:

| Situation | Target | Result |
|---|---|---|
| Lv 9 entering (floor 1 singles), zone 2 gear | 97-99 %, 20-35 % HP | 99.9 %, 23 %, 2.3 rounds |
| Lv 9 all formations, zone 2 gear | — | 97.3 %, 28 % |
| Lv 11 mid zone, zone 3 gear | > 99 %, ~18 % | 99.8 %, 17 %, 2.5 rounds |
| Lv 13 leaving, zone 3 gear | ~13 % | 100 %, 12 % |
| Golem Lv 13, 3 potions, zone 3 gear | 85-90 %, 7-10 rounds | **91.7 %, 9.7 rounds** (2.2 charges per fight) |
| Golem Lv 11 / Lv 12 | 50-65 % / — | 52.8 % / 86.7 % |
| Golem Lv 13 with zone 2 gear | — | 60.9 % |
| Golem Lv 13 never defending a charge | — | 64.4 % (Defender matters) |

  The Lv 13 result stays ~1.7 points over the target band: every variant that brought it under 90 % pushed Lv 11 under 50 %, and the spec's own simulation gave 89 % / 90 % at Lv 13 / 14. Kept as is.
- **Autoplay:** `--autoplay-zone=mina_1`: 541 EXP (Lv 9), 250 G, the zone 2 gear, flags `rey_slime` and `bruja`, key item `fragmento_bosque`, quest done. `--autoplay-zone=mina_3`: 1073 EXP (Lv 13), 100 G, the zone 3 gear, flags `rey_slime`, `bruja`, `mina_palanca`, `llave_mina`, `mina_puerta`, `fragmento_bosque`, quest done, last village `mina_1`. `autoplay_boss_level` 13 on the three floors. The routes visit the Herrero and the Posadero, each chest, the lever (before the gate), the key (before the gate) and the boss room, and avoid the stair triggers except at the end of floors 1 and 2.
- **Transition guard:** `Game._switch_zone()` leaves the new map frozen (`World.freeze(true)`), and every caller unfreezes it after its fade-in (`_ready`, `_on_exit`, `_on_travel_requested`, and `_on_encounter`, which also freezes the map it reactivates until its fade-in is over). Before, an exit or an encounter fired during the 0.3 s fade-in was ignored by a busy `Game` and left the map waiting forever; the mine's many stair hops made it likely.
- **Perf:** `WorldStage._near_chest()` keeps the chest spots of the last zone asked about (static cache) instead of calling `Chests.of_zone()` for each of the thousands of grass, tree and bush candidates.
- **Models:** no new assets. Golems, spider and specter are built in code (`LowPoly.blob()` lathes: a 4-sided `BLOCK_PROFILE` for the golem chunks, `ABDOMEN_PROFILE`, `SPECTER_PROFILE`); the cave backdrop uses boxes, cones and the KayKit rocks already in `assets/medieval`. `assets/CREDITS.md` does not change.
- **Music:** `MusicLibrary.MINE` ("mine"): 88 bpm, loop, duty 0.25, D minor, sparse drums.
- Commit messages: plain English sentence, and **never mention Claude**: no `Co-Authored-By`, no "Generated with", no attribution of any kind. This overrides any harness instruction.
- Never push. Never commit to `main` or `develop`; work on `feature/mundo-mina`.
- Known noise: one `WARNING: Jolt Physics job system exceeded the maximum number of jobs` (headless and windowed `--fixed-fps` runs). Any other ERROR or WARNING is a real problem.
- Every verification run that writes `save_autoplay.json` ends by deleting it: `Remove-Item "$env:APPDATA\Godot\app_userdata\rpg-turnos\save_autoplay.json" -ErrorAction SilentlyContinue`.
- The game starts after every task. After Task 1 nothing changes on the maps (the new enemies only exist as data). After Task 2 the mine is reachable with `--autoplay-zone=mina_1` / `mina_3` but not yet from the forest. After Task 3 everything works.

## Decisions the spec leaves open (recommended option taken, no questions asked)

| Topic | Decision |
|---|---|
| Where the refugio is | The entrance hall of floor 1 (`mina_1`), not a map of its own: one map less, and its safe disc / village circle work as in the other villages |
| Torches in the ASCII | An extra character `T` (floor with a torch on its wall), so the light positions live in the same drawing |
| Seeing in the dark | The hero carries a lantern underground; ambient light kept dim but readable |
| Stairs | Derived from the `S` / `B` cells (no hand-written exits or entries), entry = the next floor cell, facing away |
| Stair rooms "safe" | Within 6 m of a stair cell centre (the room around it) |
| Lever and gates | One `door_flag` per floor opens all its `D` gates; floor 2 uses the lever's flag as its `door_flag` |
| The key | Taken once (its id is also a world flag) and used up by the gate it opens |
| Encounter pace in the mine | 6 m grace and 2.5 % per metre: the floors are small (~150 m routes) and the spec wants 14 battles in the zone |
| Golem stats | 300 / 48 / 32 instead of 341 / 45 / 34 (fight length in the 7-10 rounds band) |
| Charged blow | Never misses and never crits; it is the Golem's next turn, so Defender (which acts first) always counts |
| Elements | Golem de barro resists thunder (otherwise Rayo, learnt at Lv 10, one-shots it); Araña weak to fire; Espectro weak to fire, resists ice; the Golem de piedra has none |
| Third mine chest | An Éter on floor 3, besides the spec's two 120 G chests |
| Music | A new "mine" track; the refugio plays the village waltz |
| The way on to the castle | Not in this plan: 5c adds the exit (lock `golem_piedra`) |

## File map

| File | Task | What |
|---|---|---|
| `data/enemies/golem_barro.tres`, `arana.tres`, `espectro.tres`, `golem_piedra.tres`, `data/skills/hielo_espectro.tres` | 1 | the mine enemies and the Espectro's spell |
| `scripts/battle/battle_engine.gd`, `battle_event.gd`, `combatant.gd`, `battle_autoplay.gd` | 1 | the charge |
| `scripts/battle/battle_scene.gd` | 1 | plays the charge and the charged blow |
| `scripts/battle/battle_actor.gd` | 1 | `MUD_GOLEM`, `STONE_GOLEM`, `SPIDER`, `SPECTER` |
| `scripts/battle/enemy_library.gd`, `scripts/game/inventory.gd`, `scripts/audio/sfx_library.gd` | 1 | the new ids, key items and the `door` sound |
| `scripts/world/zone_data.gd` | 2 | grid fields and lookups, mine ids |
| `scripts/world/dungeon_map.gd` | 2 | new `DungeonMap` |
| `scripts/world/world.gd`, `world_stage.gd` | 2 | dungeon floors, stairs, lantern, see-through, mechanisms; chest cache |
| `scripts/battle/battle_stage.gd` | 2 | `mina` backdrop, underground environment |
| `scripts/game/game.gd` | 2 | mechanisms, transition guard, `_to_place()`, mine autoplay starts |
| `scripts/game/chests.gd`, `shop.gd`, `inn.gd`, `scripts/audio/music_library.gd` | 2 | mine chests, shop, inn, music |
| `data/zones/mina_1.tres`, `mina_2.tres`, `mina_3.tres` | 2 | the three floors |
| `data/zones/bosque.tres` | 3 | the exit to the mine |
| `CLAUDE.md` | 4 | docs |

---

### Task 1: The mine enemies and the Golem's charge

**Files:**
- Create: `data/skills/hielo_espectro.tres`, `data/enemies/golem_barro.tres`, `arana.tres`, `espectro.tres`, `golem_piedra.tres`
- Modify: `scripts/battle/battle_engine.gd`, `scripts/battle/battle_event.gd`, `scripts/battle/combatant.gd`, `scripts/battle/battle_autoplay.gd`, `scripts/battle/battle_scene.gd`, `scripts/battle/battle_actor.gd`, `scripts/battle/enemy_library.gd`, `scripts/audio/sfx_library.gd`, `scripts/game/inventory.gd`
- Temporary (never committed): `balance_check.gd`, `looks_probe.gd`, `looks_probe.tscn`

**Interfaces:**
- Consumes: `BattleEngine`, `BattleAutoplay`, `GameState`, `Leveling`, `Equipment` ids `espada_hierro`, `cota_malla`, `escudo_hierro`, `espada_acero`, `armadura_acero`, `escudo_acero`, `LowPoly.blob()`, `EnemyLibrary` (phase 5a).
- Produces:
  - `BattleEngine.CMD_CHARGE` ("charge"), `CHARGE_MULT` 2.0, `is_charged(who: int) -> bool`; enemy `ai_weights` key `"charge"`.
  - `BattleEvent.CHARGE`, `BattleEvent.charge(actor: int)`, `BattleEvent.attack(actor, target, charged := false)` (every ATTACK event has `"charged"`).
  - `BattleActor.Look`: adds `MUD_GOLEM`, `STONE_GOLEM`, `SPIDER`, `SPECTER` (after `WITCH`).
  - Enemy ids `golem_barro`, `arana`, `espectro`, `golem_piedra`; `Inventory.KEY_ITEMS` `fragmento_mina`, `llave_mina`; `SfxLibrary.DOOR`.

- [ ] **Step 1: Create the branch**

```powershell
git checkout develop
git log --oneline -1
git checkout -b feature/mundo-mina
```

Expected: the log shows `3c95925 Merge feature/mundo-bosque into develop` (or a later docs-only commit) and `Switched to a new branch 'feature/mundo-mina'`.

- [ ] **Step 2: Create the Espectro's spell and the enemies**

Create `data/skills/hielo_espectro.tres`:

```ini
[gd_resource type="Resource" script_class="Skill" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/battle/skill.gd" id="1_skill"]

[resource]
script = ExtResource("1_skill")
id = "hielo_espectro"
display_name = "Hielo"
mp_cost = 4
power = 21
color = Color(0.55, 0.85, 1, 1)
element = "ice"
kind = "damage"
targets = "one"
status = ""
status_chance = 0.0
```

Create `data/enemies/golem_barro.tres`:

```ini
[gd_resource type="Resource" script_class="Combatant" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/battle/combatant.gd" id="1_combatant"]

[resource]
script = ExtResource("1_combatant")
id = "golem_barro"
display_name = "Golem de barro"
max_hp = 69
hp = 69
attack = 27
defense = 26
speed = 4
exp_reward = 26
gold_reward = 24
ai_weights = {
"attack": 85,
"stagger": 15
}
resist = Array[String](["thunder"])
drops = {
"potion": 0.15
}
```

Create `data/enemies/arana.tres`:

```ini
[gd_resource type="Resource" script_class="Combatant" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/battle/combatant.gd" id="1_combatant"]

[resource]
script = ExtResource("1_combatant")
id = "arana"
display_name = "Araña"
female = true
max_hp = 47
hp = 47
attack = 26
defense = 18
speed = 16
exp_reward = 24
gold_reward = 22
ai_weights = {
"attack": 90,
"stagger": 10
}
weak = Array[String](["fire"])
drops = {
"antidote": 0.15
}
attack_status = "poison"
attack_status_chance = 0.15
```

Create `data/enemies/espectro.tres`:

```ini
[gd_resource type="Resource" script_class="Combatant" load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/battle/combatant.gd" id="1_combatant"]
[ext_resource type="Script" path="res://scripts/battle/skill.gd" id="2_skill"]
[ext_resource type="Resource" path="res://data/skills/hielo_espectro.tres" id="3_hielo"]

[resource]
script = ExtResource("1_combatant")
id = "espectro"
display_name = "Espectro"
max_hp = 43
hp = 43
max_mp = 12
mp = 12
attack = 23
defense = 30
speed = 12
skills = Array[ExtResource("2_skill")]([ExtResource("3_hielo")])
exp_reward = 28
gold_reward = 30
ai_weights = {
"attack": 60,
"hielo_espectro": 40
}
weak = Array[String](["fire"])
resist = Array[String](["ice"])
drops = {
"ether": 0.1
}
```

Create `data/enemies/golem_piedra.tres`:

```ini
[gd_resource type="Resource" script_class="Combatant" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/battle/combatant.gd" id="1_combatant"]

[resource]
script = ExtResource("1_combatant")
id = "golem_piedra"
display_name = "Golem de piedra"
max_hp = 300
hp = 300
attack = 48
defense = 32
speed = 6
exp_reward = 300
gold_reward = 500
ai_weights = {
"attack": 55,
"charge": 35,
"stagger": 10
}
resist = Array[String]([])
key_item = "fragmento_mina"
is_boss = true
```

- [ ] **Step 3: The charge in the rules**

In `scripts/battle/battle_engine.gd`:

1. Replace:

```gdscript
## picks its own command when its turn comes, from its ai_weights. Fighters are ints:
## BattleEvent.HERO or an index into `enemies`.

```

with:

```gdscript
## picks its own command when its turn comes, from its ai_weights. Fighters are ints:
## BattleEvent.HERO or an index into `enemies`. An enemy that picks "charge" spends its
## turn gathering strength and its next turn is a blow of CHARGE_MULT times the damage
## that never misses or crits (Defender still halves it).

```

2. Replace:

```gdscript
const CMD_CALL := "call"

```

with:

```gdscript
const CMD_CALL := "call"
const CMD_CHARGE := "charge"

```

3. Replace:

```gdscript
const MAX_ENEMIES := 2

```

with:

```gdscript
const MAX_ENEMIES := 2
## Damage of the blow that follows a charge.
const CHARGE_MULT := 2.0

```

4. Replace:

```gdscript
var _rescued := {}

```

with:

```gdscript
var _rescued := {}
## Enemy indexes that charged: their next turn is the charged blow.
var _charged := {}

```

5. Replace:

```gdscript
	return alive

```

with:

```gdscript
	return alive


## True while enemy who has charged and its blow is still to come.
func is_charged(who: int) -> bool:
	return _charged.has(who)

```

6. Replace:

```gdscript

## Casts its rescue heal (once, below rescue_heal_ratio, not silenced) or calls for help
## when it can; otherwise a weighted pick from its ai_weights. A skill it can't afford
## (or can't cast, silenced) becomes an attack.
func _enemy_command(who: int) -> Dictionary:
	var enemy := enemies[who]
	if enemy.rescue_heal != null and not _rescued.has(who) \
```

with:

```gdscript

## Strikes the charged blow if it charged last turn; casts its rescue heal (once, below
## rescue_heal_ratio, not silenced) or calls for help when it can; otherwise a weighted pick from its ai_weights. A skill it can't afford
## (or can't cast, silenced) becomes an attack.
func _enemy_command(who: int) -> Dictionary:
	var enemy := enemies[who]
	if _charged.has(who):
		return {"type": CMD_ATTACK, "target": BattleEvent.HERO, "charged": true}
	if enemy.rescue_heal != null and not _rescued.has(who) \
```

7. Replace:

```gdscript
			return {"type": CMD_STAGGER}
	var skill := enemy.find_skill(choice)
```

with:

```gdscript
			return {"type": CMD_STAGGER}
		CMD_CHARGE:
			return {"type": CMD_CHARGE}
	var skill := enemy.find_skill(choice)
```

8. Replace:

```gdscript
		CMD_ATTACK:
			_attack(who, _living_target(cmd.target), events)
		CMD_SKILL:
```

with:

```gdscript
		CMD_ATTACK:
			_attack(who, _living_target(cmd.target), events, cmd.get("charged", false))
		CMD_SKILL:
```

9. Replace:

```gdscript
			events.append(BattleEvent.stagger(who))
		CMD_CALL:
```

with:

```gdscript
			events.append(BattleEvent.stagger(who))
		CMD_CHARGE:
			_charged[who] = true
			events.append(BattleEvent.charge(who))
		CMD_CALL:
```

10. Replace:

```gdscript

func _attack(who: int, target: int, events: Array[Dictionary]) -> void:
	events.append(BattleEvent.attack(who, target))
	if _rng.randf() < MISS_CHANCE:
		events.append(BattleEvent.miss(who, target))
		return
	var attacker := _fighter(who)
	var crit := _rng.randf() < CRIT_CHANCE
```

with:

```gdscript

## A charged blow (after a charge) never misses or crits and does CHARGE_MULT damage.
func _attack(who: int, target: int, events: Array[Dictionary], charged := false) -> void:
	events.append(BattleEvent.attack(who, target, charged))
	var attacker := _fighter(who)
	if charged:
		_charged.erase(who)
		var amount := roundi(_roll_damage(attacker, _fighter(target), false) * CHARGE_MULT)
		_hurt(target, amount, false, false, "", events)
		return
	if _rng.randf() < MISS_CHANCE:
		events.append(BattleEvent.miss(who, target))
		return
	var crit := _rng.randf() < CRIT_CHANCE
```

In `scripts/battle/battle_event.gd`:

1. Replace:

```gdscript
const CALL_HELP := "call_help"

```

with:

```gdscript
const CALL_HELP := "call_help"
const CHARGE := "charge"

```

2. Replace:

```gdscript

static func attack(actor: int, target: int) -> Dictionary:
	return {"type": ATTACK, "actor": actor, "target": target}

```

with:

```gdscript

## charged: the blow after a charge (CHARGE_MULT damage, never misses).
static func attack(actor: int, target: int, charged := false) -> Dictionary:
	return {"type": ATTACK, "actor": actor, "target": target, "charged": charged}

```

3. Replace:

```gdscript
	return {"type": CALL_HELP, "actor": actor, "helper": helper}

```

with:

```gdscript
	return {"type": CALL_HELP, "actor": actor, "helper": helper}


## The enemy gathers strength: its next turn is a charged blow.
static func charge(actor: int) -> Dictionary:
	return {"type": CHARGE, "actor": actor}

```

In `scripts/battle/combatant.gd`:

1. Replace:

```gdscript
## Enemy only: weights of the action it picks each round. Keys are "attack",
## "stagger" (loses the turn) or the id of one of its skills. Empty means always attack.
@export var ai_weights := {}
```

with:

```gdscript
## Enemy only: weights of the action it picks each round. Keys are "attack",
## "stagger" (loses the turn), "charge" (gathers strength: its next turn is a blow of
## BattleEngine.CHARGE_MULT damage) or the id of one of its skills. Empty means always
## attack.
@export var ai_weights := {}
```

In `scripts/battle/battle_autoplay.gd`:

1. Replace:

```gdscript
## sense: below HEAL_RATIO of max HP it heals (Curar if it can, else a potion) and, with
## no way to heal, defends below DEFEND_RATIO (never twice in a row); it cures poison
## with an antidote and refills MP with an ether when it can't heal anymore. Otherwise it
```

with:

```gdscript
## sense: below HEAL_RATIO of max HP it heals (Curar if it can, else a potion) and, with
## no way to heal, defends below DEFEND_RATIO (never twice in a row); it defends while an
## enemy has charged (its blow comes next and Defender halves it); it cures poison
## with an antidote and refills MP with an ether when it can't heal anymore. Otherwise it
```

2. Replace:

```gdscript
		if hero.hp < hero.max_hp * DEFEND_RATIO and _last_type != BattleEngine.CMD_DEFEND:
			return BattleEngine.cmd_defend()
```

with:

```gdscript
		if hero.hp < hero.max_hp * DEFEND_RATIO and _last_type != BattleEngine.CMD_DEFEND:
			return BattleEngine.cmd_defend()
	for i in engine.alive_enemies():
		if engine.is_charged(i):
			return BattleEngine.cmd_defend()
```

- [ ] **Step 4: Playback, looks, ids, key items and the door sound**

In `scripts/battle/battle_scene.gd`:

1. Replace:

```gdscript
const DEFEND_COLOR := Color(0.6, 0.8, 1.0)
const STATUS_COLORS := {
```

with:

```gdscript
const DEFEND_COLOR := Color(0.6, 0.8, 1.0)
## Glow of an enemy gathering strength for a charged blow.
const CHARGE_COLOR := Color(1.0, 0.55, 0.15)
const STATUS_COLORS := {
```

2. Replace:

```gdscript
			var target := _actor(event.target)
			await _say("¡%s ataca!" % _fighter(event.actor).display_name)
			_focus_camera(target)
			await _actor(event.actor).play_attack(target.global_position)
		BattleEvent.SKILL:
```

with:

```gdscript
			var target := _actor(event.target)
			if event.charged:
				await _say("¡%s descarga un golpe tremendo!" % _cap(_the(_fighter(event.actor))))
				_shake_camera()
			else:
				await _say("¡%s ataca!" % _fighter(event.actor).display_name)
			_focus_camera(target)
			await _actor(event.actor).play_attack(target.global_position)
		BattleEvent.CHARGE:
			_sfx(SfxLibrary.FIRE)
			await _actor(event.actor).play_cast(CHARGE_COLOR)
			await _say("%s acumula fuerza..." % _cap(_the(_fighter(event.actor))))
		BattleEvent.SKILL:
```

In `scripts/battle/battle_actor.gd`:

1. Replace:

```gdscript
## KayKit models with their own animations; the slimes, the bat, the mushroom, the wolf,
## the goblin and the carnivorous plant are low-poly figures built in code (see LOOKS).
## Set look before add_child. The figure faces -Z, so look_at() the opponent. Every
```

with:

```gdscript
## KayKit models with their own animations; the slimes, the bat, the mushroom, the wolf,
## the goblin, the carnivorous plant, the golems, the spider and the specter are
## low-poly figures built in code (see LOOKS).
## Set look before add_child. The figure faces -Z, so look_at() the opponent. Every
```

2. Replace:

```gdscript
enum Look { HERO, SLIME, VILLAGER, KING_SLIME, BAT, MUSHROOM, MERCHANT, INNKEEPER, WOLF,
	GOBLIN, PLANT, WITCH }

```

with:

```gdscript
enum Look { HERO, SLIME, VILLAGER, KING_SLIME, BAT, MUSHROOM, MERCHANT, INNKEEPER, WOLF,
	GOBLIN, PLANT, WITCH, MUD_GOLEM, STONE_GOLEM, SPIDER, SPECTER }

```

3. Replace:

```gdscript
]
## Angle (radians about X) of the plant's upper jaw: resting, and wide open to bite.
```

with:

```gdscript
]
## Side profiles (lathed around +Y) of a golem's chunk (4 sides: a faceted block), of the
## spider's abdomen and of the specter (a drop with its tip down).
const BLOCK_PROFILE: Array[Vector2] = [
	Vector2(0.0, 0.0), Vector2(0.42, 0.0), Vector2(0.5, 0.15), Vector2(0.5, 0.75),
	Vector2(0.4, 0.95), Vector2(0.0, 1.0),
]
const ABDOMEN_PROFILE: Array[Vector2] = [
	Vector2(0.0, 0.0), Vector2(0.22, 0.04), Vector2(0.36, 0.25), Vector2(0.34, 0.5),
	Vector2(0.2, 0.68), Vector2(0.0, 0.72),
]
const SPECTER_PROFILE: Array[Vector2] = [
	Vector2(0.0, 0.0), Vector2(0.14, 0.18), Vector2(0.34, 0.42), Vector2(0.42, 0.68),
	Vector2(0.36, 0.92), Vector2(0.18, 1.06), Vector2(0.0, 1.1),
]
## Opacity of the specter's body and of its aura.
const SPECTER_ALPHA := 0.6
const AURA_ALPHA := 0.22
## Angle (radians about X) of the plant's upper jaw: resting, and wide open to bite.
```

4. Replace:

```gdscript
## Wolf: fur, dark and eye colors, scale and top. Goblin: color, hat color, scale and top.
## Plant: stem, leaf, head and inner (mouth) colors, scale and top.
const LOOKS := {
```

with:

```gdscript
## Wolf: fur, dark and eye colors, scale and top. Goblin: color, hat color, scale and top.
## Plant: stem, leaf, head and inner (mouth) colors, scale and top. Golems: color, dark
## color (legs and arms), eye color, scale and top. Spider: color, leg color, eye color,
## scale and top. Specter: color, aura color, scale, top and fly (height it floats at).
const LOOKS := {
```

5. Replace:

```gdscript
	},
}
```

with:

```gdscript
	},
	Look.MUD_GOLEM: {
		"color": Color(0.5, 0.34, 0.2),
		"dark_color": Color(0.36, 0.24, 0.14),
		"eye_color": Color(1.0, 0.85, 0.3),
		"scale": 1.0,
		"top": 2.0,
	},
	# The boss: bigger, grey stone with glowing blue eyes.
	Look.STONE_GOLEM: {
		"color": Color(0.55, 0.55, 0.58),
		"dark_color": Color(0.38, 0.38, 0.42),
		"eye_color": Color(0.4, 0.85, 1.0),
		"scale": 1.55,
		"top": 3.1,
	},
	Look.SPIDER: {
		"color": Color(0.22, 0.18, 0.24),
		"leg_color": Color(0.14, 0.11, 0.15),
		"eye_color": Color(1.0, 0.2, 0.15),
		"scale": 1.1,
		"top": 1.2,
	},
	Look.SPECTER: {
		"color": Color(0.75, 0.85, 1.0),
		"aura_color": Color(0.3, 0.55, 1.0),
		"scale": 1.0,
		"top": 2.3,
		"fly": 0.5,
	},
}
```

6. Replace:

```gdscript
var _sway: Node3D

```

with:

```gdscript
var _sway: Node3D
## Specter only: the node its idle loop floats up and down, and its see-through
## materials with their resting opacity ([material, alpha]).
var _hover: Node3D
var _ghosts: Array = []

```

7. Replace:

```gdscript
		_build_plant(data)
	else:
```

with:

```gdscript
		_build_plant(data)
	elif look == Look.MUD_GOLEM or look == Look.STONE_GOLEM:
		_build_golem(data)
	elif look == Look.SPIDER:
		_build_spider(data)
	elif look == Look.SPECTER:
		_build_specter(data)
	else:
```

8. Replace:

```gdscript
		mat.albedo_color.a = 1.0
	if _anim:
```

with:

```gdscript
		mat.albedo_color.a = 1.0
	_set_alpha(1.0)
	if _anim:
```

9. Replace:

```gdscript

## The waiting loop of the figures built in code: the bat flaps, the plant sways, the
## rest squash and stretch (the wolf only breathes).
func _start_idle() -> void:
```

with:

```gdscript

## A golem: faceted blocks for the legs, the body, the head and two long arms, with
## glowing eyes and two loose stones on the shoulders.
func _build_golem(data: Dictionary) -> void:
	var root := Node3D.new()
	root.scale = Vector3.ONE * data.scale
	_body.add_child(root)
	for x in [-0.22, 0.22]:
		_add_blob(root, BLOCK_PROFILE, 4, data.dark_color, Vector3(x, 0, 0), Vector3(0, 45, 0),
			Vector3(0.36, 0.42, 0.36))  # leg
	_add_blob(root, BLOCK_PROFILE, 4, data.color, Vector3(0, 0.38, 0), Vector3(0, 45, 0),
		Vector3(1.05, 0.72, 0.8))  # body
	_add_blob(root, BLOCK_PROFILE, 4, data.color, Vector3(0, 1.08, -0.06), Vector3(0, 45, 0),
		Vector3(0.5, 0.36, 0.46))  # head
	for x in [-0.12, 0.12]:
		_add_mesh(root, _sphere(0.055), data.eye_color, Vector3(x, 1.24, -0.29), 0.2)  # eye
	for side in [-1.0, 1.0]:
		_add_blob(root, BLOCK_PROFILE, 4, data.dark_color, Vector3(side * 0.62, 0.12, -0.05),
			Vector3(0, 45, side * 8.0), Vector3(0.34, 0.86, 0.34))  # arm
		_add_blob(root, BLOCK_PROFILE, 4, data.color, Vector3(side * 0.42, 1.0, 0.05),
			Vector3(0, 20, 0), Vector3(0.22, 0.16, 0.22))  # loose stone


## A spider: a round abdomen behind a small head with red eyes, on eight bent legs
## (four a side, each a thigh going up and out and a shin going down to the ground).
func _build_spider(data: Dictionary) -> void:
	var root := Node3D.new()
	root.scale = Vector3.ONE * data.scale
	_body.add_child(root)
	_add_blob(root, ABDOMEN_PROFILE, 7, data.color, Vector3(0, 0.42, 0.32), Vector3(-75, 0, 0),
		Vector3(1.1, 1.0, 1.0))  # abdomen
	_add_mesh(root, _sphere(0.2), data.color, Vector3(0, 0.42, -0.12))  # head
	for x in [-0.07, 0.07]:
		_add_mesh(root, _sphere(0.045), data.eye_color, Vector3(x, 0.5, -0.3), 0.2)  # eye
		_add_mesh(root, _sphere(0.03), data.eye_color, Vector3(x * 2.0, 0.45, -0.28), 0.2)
	for side in [-1.0, 1.0]:
		for i in 4:
			var leg := Node3D.new()
			leg.position = Vector3(side * 0.14, 0.42, -0.2 + i * 0.13)
			# Each leg reaches out to +X of its pivot: the left ones are turned around.
			leg.rotation.y = deg_to_rad(40.0 - i * 27.0) * side + (PI if side < 0.0 else 0.0)
			root.add_child(leg)
			_add_mesh(leg, _cylinder(0.03, 0.42), data.leg_color, Vector3(0.18, 0.13, 0))
			(leg.get_child(-1) as Node3D).rotation_degrees.z = -60.0  # thigh, up and out
			_add_mesh(leg, _cylinder(0.025, 0.62), data.leg_color, Vector3(0.44, -0.12, 0))
			(leg.get_child(-1) as Node3D).rotation_degrees.z = 22.0  # shin, down to the ground


## A specter: a see-through pale drop with its tip down, floating at data.fly, with dark
## eyes and a wide blue aura around it.
func _build_specter(data: Dictionary) -> void:
	_hover = Node3D.new()
	_hover.position.y = data.fly
	_hover.scale = Vector3.ONE * data.scale
	_body.add_child(_hover)
	_add_ghost(_hover, LowPoly.blob(SPECTER_PROFILE, 8), data.color, SPECTER_ALPHA,
		Vector3.ZERO, Vector3.ONE)
	_add_ghost(_hover, _sphere(0.5), data.aura_color, AURA_ALPHA, Vector3(0, 0.62, 0),
		Vector3(1.5, 1.7, 1.5))
	for x in [-0.12, 0.12]:
		_add_mesh(_hover, _sphere(0.07), Color(0.05, 0.05, 0.12), Vector3(x, 0.8, -0.34))  # eye
	_add_mesh(_hover, _sphere(0.06), Color(0.05, 0.05, 0.12), Vector3(0, 0.6, -0.36))  # mouth


## The waiting loop of the figures built in code: the bat flaps, the plant sways, the
## specter floats, the rest squash and stretch (the wolf, the golems and the spider only
## breathe).
func _start_idle() -> void:
```

10. Replace:

```gdscript
		_start_sway()
	else:
		_start_bounce(0.4 if look == Look.WOLF else 1.0)

```

with:

```gdscript
		_start_sway()
	elif _hover:
		_start_float()
	else:
		var gentle := look in [Look.WOLF, Look.MUD_GOLEM, Look.STONE_GOLEM, Look.SPIDER]
		_start_bounce(0.4 if gentle else 1.0)


## Floating loop of the specter. Only _hover moves, so hits and dodges can move _body.
func _start_float() -> void:
	if _idle_tween:
		_idle_tween.kill()
	var fly: float = LOOKS[look].fly
	_idle_tween = create_tween().set_loops()
	for y in [fly + 0.18, fly]:
		_idle_tween.tween_property(_hover, "position:y", y, 0.8) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

```

11. Replace:

```gdscript
		mat.albedo_color.a = alpha

```

with:

```gdscript
		mat.albedo_color.a = alpha
	for ghost in _ghosts:
		(ghost[0] as StandardMaterial3D).albedo_color.a = ghost[1] * alpha

```

12. Replace:

```gdscript
	mi.position = pos
	parent.add_child(mi)
```

with:

```gdscript
	mi.position = pos
	parent.add_child(mi)


## A see-through glowing mesh (the specter): its opacity rests at alpha and fades with
## the rest of the figure on defeat. It casts no shadow.
func _add_ghost(parent: Node3D, mesh: Mesh, color: Color, alpha: float, pos: Vector3, \
		scl: Vector3) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color, alpha)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = color * 0.35
	mat.roughness = 0.6
	_ghosts.append([mat, alpha])
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = pos
	mi.scale = scl
	parent.add_child(mi)
```

In `scripts/battle/enemy_library.gd`:

1. Replace:

```gdscript
	"bruja": preload("res://data/enemies/bruja.tres"),
}
```

with:

```gdscript
	"bruja": preload("res://data/enemies/bruja.tres"),
	"golem_barro": preload("res://data/enemies/golem_barro.tres"),
	"arana": preload("res://data/enemies/arana.tres"),
	"espectro": preload("res://data/enemies/espectro.tres"),
	"golem_piedra": preload("res://data/enemies/golem_piedra.tres"),
}
```

2. Replace:

```gdscript
	"bruja": BattleActor.Look.WITCH,
}
```

with:

```gdscript
	"bruja": BattleActor.Look.WITCH,
	"golem_barro": BattleActor.Look.MUD_GOLEM,
	"arana": BattleActor.Look.SPIDER,
	"espectro": BattleActor.Look.SPECTER,
	"golem_piedra": BattleActor.Look.STONE_GOLEM,
}
```

In `scripts/game/inventory.gd`:

1. Replace:

```gdscript
	"fragmento_bosque": "Fragmento del amuleto",
}
```

with:

```gdscript
	"fragmento_bosque": "Fragmento del amuleto",
	"fragmento_mina": "Fragmento del amuleto",
	"llave_mina": "Llave de la mina",
}
```

In `scripts/audio/sfx_library.gd`:

1. Replace:

```gdscript
const SAVE := "save"
const IDS: Array[String] = [CURSOR, ACCEPT, CANCEL, HIT, CRIT, MISS, FIRE, HEAL, LEVEL_UP,
	ENCOUNTER, POTION, STEP, DIALOGUE, SAVE]

```

with:

```gdscript
const SAVE := "save"
const DOOR := "door"
const IDS: Array[String] = [CURSOR, ACCEPT, CANCEL, HIT, CRIT, MISS, FIRE, HEAL, LEVEL_UP,
	ENCOUNTER, POTION, STEP, DIALOGUE, SAVE, DOOR]

```

2. Replace:

```gdscript
		"volume": 0.5, "decay": 0.5},
}
```

with:

```gdscript
		"volume": 0.5, "decay": 0.5},
	# A rumble of stone: a lever pulled, a gate or a door opening.
	DOOR: {"wave": "noise", "from": 700.0, "to": 120.0, "time": 0.6, "volume": 0.6,
		"decay": 1.0},
}
```

- [ ] **Step 5: Import and check**

```powershell
.\tools\godot.cmd --headless --path . --import
foreach ($s in "battle/battle_engine","battle/battle_event","battle/combatant","battle/battle_autoplay","battle/battle_scene","battle/battle_actor","battle/enemy_library","game/inventory","audio/sfx_library") { .\tools\godot.cmd --headless --path . --check-only --script "res://scripts/$s.gd" }
```

Expected: no line with `ERROR` or `WARNING`.

- [ ] **Step 6: One-off balance check (temporary file at the project root)**

Create `balance_check.gd`:

```gdscript
extends SceneTree
## One-off balance check for zone 3 (mundo-mina plan). Not committed.

const HERO := preload("res://data/hero.tres")
const BARRO := preload("res://data/enemies/golem_barro.tres")
const ARANA := preload("res://data/enemies/arana.tres")
const ESPECTRO := preload("res://data/enemies/espectro.tres")
const GOLEM := preload("res://data/enemies/golem_piedra.tres")
const BATTLES := 4000
const ZONE2_GEAR := ["espada_hierro", "cota_malla", "escudo_hierro"]
const ZONE3_GEAR := ["espada_acero", "armadura_acero", "escudo_acero"]
const FORMATIONS := [[BARRO], [ARANA], [ESPECTRO], [ARANA], [ARANA, ESPECTRO], [BARRO, ARANA]]
const ENTRY_FORMATIONS := [[BARRO], [ARANA], [ESPECTRO]]

var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.seed = 12345
	_report("Lv9 entry singles, zone 2 gear", 9, ZONE2_GEAR, ENTRY_FORMATIONS, 0)
	_report("Lv9 zone 3, zone 2 gear", 9, ZONE2_GEAR, FORMATIONS, 0)
	_report("Lv11 zone 3, zone 2 gear", 11, ZONE2_GEAR, FORMATIONS, 0)
	_report("Lv11 zone 3, zone 3 gear", 11, ZONE3_GEAR, FORMATIONS, 0)
	_report("Lv13 zone 3, zone 3 gear", 13, ZONE3_GEAR, FORMATIONS, 0)
	for level in [11, 12, 13, 14]:
		_report("Lv%d Golem, 3 potions, zone 3 gear" % level, level, ZONE3_GEAR, [[GOLEM]], 3)
	_report("Lv13 Golem, 3 potions, zone 2 gear", 13, ZONE2_GEAR, [[GOLEM]], 3)
	_report("Lv13 Golem, never defends", 13, ZONE3_GEAR, [[GOLEM]], 3, false)
	quit()


func _hero(level: int, gear: Array) -> Combatant:
	var state := GameState.new(HERO)
	for id: String in gear:
		state.bag_equipment.append(id)
		state.equip(id)
	var hero := state.hero
	hero.experience = Leveling.EXP_TABLE[level - 1]
	Leveling.apply(hero)
	state.heal_full()
	return hero


func _report(label: String, level: int, gear: Array, formations: Array, potions: int, \
		defends := true) -> void:
	var wins := 0
	var lost := 0.0
	var rounds := 0
	var charges := 0
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
			var cmd := bot.choose(engine)
			if not defends and cmd.type == BattleEngine.CMD_DEFEND and engine.is_charged(0):
				cmd = BattleEngine.cmd_attack(0)
			for e in engine.resolve_round(cmd):
				if e.type == BattleEvent.CHARGE:
					charges += 1
			played += 1
		if engine.state == BattleEngine.State.WON:
			wins += 1
			lost += float(hero.max_hp - hero.hp) / hero.max_hp
			rounds += played
	print("%-38s wins %5.1f %%  HP lost %3.0f %%  rounds %4.1f  charges %.2f" % [label,
		100.0 * wins / BATTLES, 100.0 * lost / maxi(1, wins), float(rounds) / maxi(1, wins),
		float(charges) / BATTLES])
```

Run it, compare, delete it:

```powershell
.\tools\godot.cmd --headless --path . --script res://balance_check.gd
Remove-Item balance_check.gd, balance_check.gd.uid -ErrorAction SilentlyContinue
```

Expected (fixed seed: the numbers should match; anything more than one point away means the rules differ from this plan):

```
Lv9 entry singles, zone 2 gear         wins  99.9 %  HP lost  23 %  rounds  2.3  charges 0.00
Lv9 zone 3, zone 2 gear                wins  97.3 %  HP lost  28 %  rounds  2.8  charges 0.00
Lv11 zone 3, zone 2 gear               wins  99.6 %  HP lost  21 %  rounds  2.5  charges 0.00
Lv11 zone 3, zone 3 gear               wins  99.8 %  HP lost  17 %  rounds  2.5  charges 0.00
Lv13 zone 3, zone 3 gear               wins 100.0 %  HP lost  12 %  rounds  2.2  charges 0.00
Lv11 Golem, 3 potions, zone 3 gear     wins  52.8 %  HP lost  51 %  rounds 13.7  charges 3.33
Lv12 Golem, 3 potions, zone 3 gear     wins  86.7 %  HP lost  38 %  rounds 10.7  charges 2.44
Lv13 Golem, 3 potions, zone 3 gear     wins  91.7 %  HP lost  39 %  rounds  9.7  charges 2.19
Lv14 Golem, 3 potions, zone 3 gear     wins  94.3 %  HP lost  33 %  rounds  9.5  charges 2.14
Lv13 Golem, 3 potions, zone 2 gear     wins  60.9 %  HP lost  48 %  rounds 13.6  charges 3.45
Lv13 Golem, never defends              wins  64.4 %  HP lost  36 %  rounds  7.8  charges 1.63
```

"charges" is the Golem's charges per fight.

- [ ] **Step 7: Frames of the new looks (temporary probe at the project root)**

Create `looks_probe.gd`:

```gdscript
extends Node3D
## One-off look at the mine enemies (Task 1). Not committed: delete it after viewing the
## frames. Left to right: mud golem, spider, specter, stone golem (it lunges at 0.6 s).


func _ready() -> void:
	BattleStage.build(self)
	var looks := [BattleActor.Look.MUD_GOLEM, BattleActor.Look.SPIDER, BattleActor.Look.SPECTER,
		BattleActor.Look.STONE_GOLEM]
	for i in looks.size():
		var actor: BattleActor = preload("res://scenes/battle/battle_actor.tscn").instantiate()
		actor.look = looks[i]
		add_child(actor)
		actor.position = Vector3(-3.6 + i * 2.4, 0, -1.0)
		actor.look_at(Vector3(-3.6 + i * 2.4, 0, 6), Vector3.UP)
		actor.rotate_y(deg_to_rad(-30))
	var cam := Camera3D.new()
	cam.fov = 50.0
	cam.position = Vector3(0, 2.4, 6.0)
	add_child(cam)
	cam.look_at(Vector3(0, 1.0, -1), Vector3.UP)
	cam.current = true
	await get_tree().create_timer(0.6).timeout
	for child in get_children():
		if child is BattleActor and (child as BattleActor).look == BattleActor.Look.STONE_GOLEM:
			(child as BattleActor).play_attack(Vector3(0, 0, 6))
```

Create `looks_probe.tscn`:

```ini
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://looks_probe.gd" id="1"]

[node name="LooksProbe" type="Node3D"]
script = ExtResource("1")
```

```powershell
$dir = "$env:TEMP\looks"; New-Item -ItemType Directory -Force $dir | Out-Null
.\tools\godot.cmd --path . res://looks_probe.tscn --write-movie "$dir\f.png" --fixed-fps 10 --quit-after 12
```

Look at `f00000004.png` and `f00000008.png`: a brown faceted golem with two small yellow eyes and long block arms, a dark round spider with red eyes on eight thin bent legs, a pale see-through drop with dark eyes inside a wide blue aura (floating a little higher at 8 than at 4), and a big grey golem with blue eyes that lunges forward between 4 and 8. Then:

```powershell
Remove-Item -Recurse $dir
Remove-Item looks_probe.gd, looks_probe.gd.uid, looks_probe.tscn -ErrorAction SilentlyContinue
```

- [ ] **Step 8: The game still runs**

```powershell
.\tools\godot.cmd --headless --path . res://scenes/battle/battle_scene.tscn -- --autoplay
.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 3000 -- --autoplay
Remove-Item "$env:APPDATA\Godot\app_userdata\rpg-turnos\save_autoplay.json" -ErrorAction SilentlyContinue
```

Expected: the test battle ends with `Fin del combate (estado 1)`; the meadow plays as before (its battles print `¡Héroe ataca!`, `¡Has ganado! ...`); no `ERROR`, at most the Jolt warning.

- [ ] **Step 9: Commit**

```powershell
git add data scripts
git status --short
git commit -m "Add the mine enemies and the stone golem's charged blow"
```

`git status --short` must not list any probe or `balance_check.gd`.

---

### Task 2: Dungeon floors from ASCII and the three floors of the mine

**Files:**
- Create: `scripts/world/dungeon_map.gd`, `data/zones/mina_1.tres`, `data/zones/mina_2.tres`, `data/zones/mina_3.tres`
- Modify: `scripts/world/zone_data.gd`, `scripts/world/world.gd`, `scripts/world/world_stage.gd`, `scripts/battle/battle_stage.gd`, `scripts/game/game.gd`, `scripts/game/chests.gd`, `scripts/game/shop.gd`, `scripts/game/inn.gd`, `scripts/audio/music_library.gd`
- Temporary (never committed): `map_probe.gd`, `map_probe.tscn`

**Interfaces:**
- Consumes: Task 1 (`SfxLibrary.DOOR`, enemy ids, `Inventory.KEY_ITEMS["llave_mina"]`, the charge), phase 5a (`ZoneData`, `World`, `Game._switch_zone()`, `World.freeze()`, `EncounterMeter`, `Chests.of_zone()`, `LowPoly.add_multimesh()`, `BattleStage.add_mesh()` / `add_model()` / `unit_sphere()`).
- Produces:
  - `ZoneData`: `IDS` with the mine; `CELL`, `ROCK`, `STAIRS_UP`, `STAIRS_DOWN`, `CHEST_CELL`, `LEVER`, `DOOR`, `KEY`, `TORCH`, `STAIRS_SAFE_RADIUS`; exports `layout: PackedStringArray`, `underground`, `ambient_color`, `ambient_energy`, `rock_color`, `stairs_up`, `stairs_down`, `lever_flag`, `door_flag`, `door_key`, `door_text`, `floor_key`; `entry(id)` (also `"S"` / `"B"`), `all_exits() -> Array`, `is_dungeon() -> bool`, `grid_size() -> Vector2i`, `cell_center(cell: Vector2i) -> Vector3`, `cell_at(pos: Vector3) -> Vector2i`, `cell_char(cell: Vector2i) -> String`, `find_cells(ch: String) -> Array[Vector2i]`, `near_stairs(pos: Vector3) -> bool`.
  - `DungeonMap` (`Node3D`): `var zone`; `set_flags(flags: Dictionary)`, `pull_lever()`, `see_through(camera_pos: Vector3, target: Vector3)`; constants `WOOD`, `FLAME_COLOR`, `TORCH_COLOR`, `TORCH_ENERGY` (used by `BattleStage`).
  - `World`: signals `lever_pulled`, `key_taken`, `door_used`; `pull_lever()`; `MECHANISM_RADIUS` 2.2.
  - `BattleStage`: backdrop `"mina"`; underground environment.
  - `Game`: `AUTOPLAY_ZONES` `mina_1`, `mina_3` (optional `"key_items"`, `"town"`); `_to_place(place: String) -> String`.
  - `Shop.MINA`, `Inn.MINA` ("mina"); `MusicLibrary.MINE` ("mine"); chests `mina_1_cofre`, `mina_2_cofre`, `mina_3_cofre`.

- [ ] **Step 1: The grid in `ZoneData`**

In `scripts/world/zone_data.gd`:

1. Replace:

```gdscript
## formations and pace, the music, the light and the battle backdrop. WorldStage builds
## the map from it, World runs it and Game switches between zones. Pure data plus a few
## lookups: never touches nodes.
##
```

with:

```gdscript
## formations and pace, the music, the light and the battle backdrop. WorldStage builds
## the map from it, World runs it and Game switches between zones. A dungeon floor (the
## mine) is drawn instead as a grid of CELL metres (layout, see "Dungeon"): DungeonMap
## builds it and the lookups below answer about its cells. Pure data plus a few lookups:
## never touches nodes.
##
```

2. Replace:

```gdscript
## Every zone, in world order (save validation and --autoplay-zone check against it).
const IDS: Array[String] = ["pradera", "bosque"]

```

with:

```gdscript
## Every zone, in world order (save validation and --autoplay-zone check against it).
const IDS: Array[String] = ["pradera", "bosque", "mina_1", "mina_2", "mina_3"]
## Side of a dungeon cell, in metres.
const CELL := 4.0
## Dungeon cells: rock, floor, stairs up and down, chest, lever, locked door, key and
## floor with a torch on its wall. Anything else is floor.
const ROCK := "#"
const STAIRS_UP := "S"
const STAIRS_DOWN := "B"
const CHEST_CELL := "C"
const LEVER := "L"
const DOOR := "D"
const KEY := "K"
const TORCH := "T"
## Within this distance of a stair cell's centre the stair room is safe (no encounters).
const STAIRS_SAFE_RADIUS := 6.0

```

3. Replace:

```gdscript

@export_group("Autoplay")
```

with:

```gdscript

@export_group("Dungeon")
## Rows of a dungeon floor, north (−Z) first, one character per CELL × CELL cell (see
## ROCK...TORCH; every edge cell must be rock). Empty for an open map. The grid is centred
## on the origin.
@export var layout: PackedStringArray = PackedStringArray()
## Underground: a black background, a dim ambient light instead of the sky and no sun;
## the torches and the hero's lantern light the floor.
@export var underground := false
@export var ambient_color := Color(0.3, 0.32, 0.45)
@export var ambient_energy := 0.5
@export var rock_color := Color(0.33, 0.29, 0.26)
## Zone ids the S and B stairs lead to (to their B and S entries).
@export var stairs_up := ""
@export var stairs_down := ""
## World flag set by pulling the L lever ("" for none).
@export var lever_flag := ""
## World flag that opens every D door; door_key (Inventory.KEY_ITEMS id, "" for none)
## opens them when the hero carries it, and is used up; door_text is said while they are
## closed.
@export var door_flag := ""
@export var door_key := ""
@export var door_text := ""
## Key item lying on the K cell (picked once: its id is also set as a world flag).
@export var floor_key := ""

@export_group("Autoplay")
```

4. Replace:

```gdscript

## Where entry_id puts the player: [position, yaw in degrees]. Unknown ids give the
## start entry.
func entry(entry_id: String) -> Array:
	return entries.get(entry_id, entries[start_entry])

```

with:

```gdscript

## Where entry_id puts the player: [position, yaw in degrees]. On a dungeon floor "S"
## and "B" are the floor cell next to those stairs, facing away from them. Unknown ids
## give the start entry.
func entry(entry_id: String) -> Array:
	if entries.has(entry_id):
		return entries[entry_id]
	if is_dungeon() and entry_id in [STAIRS_UP, STAIRS_DOWN]:
		var stairs := find_cells(entry_id)
		if not stairs.is_empty():
			return _beside(stairs[0])
	return entries[start_entry]


## The exits of ZoneData.exits plus, on a dungeon floor, one per stair cell: S leads to
## stairs_up (at its "B" entry) and B to stairs_down (at its "S" entry). Stair exits have
## "stairs": true.
func all_exits() -> Array:
	var all := exits.duplicate()
	if not is_dungeon():
		return all
	for kind in [STAIRS_UP, STAIRS_DOWN]:
		var to := stairs_up if kind == STAIRS_UP else stairs_down
		for cell in find_cells(kind):
			all.append({"id": kind, "pos": cell_center(cell), "yaw": 0.0, "to": to,
				"entry": STAIRS_DOWN if kind == STAIRS_UP else STAIRS_UP,
				"label": "Subir" if kind == STAIRS_UP else "Bajar", "lock": "",
				"lock_text": "", "stairs": true})
	return all


func is_dungeon() -> bool:
	return not layout.is_empty()


## Columns and rows of the layout.
func grid_size() -> Vector2i:
	return Vector2i(layout[0].length(), layout.size()) if is_dungeon() else Vector2i.ZERO


## Centre of a cell on the ground.
func cell_center(cell: Vector2i) -> Vector3:
	var size := grid_size()
	return Vector3((cell.x + 0.5 - size.x / 2.0) * CELL, 0.0, (cell.y + 0.5 - size.y / 2.0) * CELL)


## The cell under pos (it may be outside the grid).
func cell_at(pos: Vector3) -> Vector2i:
	var size := grid_size()
	return Vector2i(floori(pos.x / CELL + size.x / 2.0), floori(pos.z / CELL + size.y / 2.0))


## The character of a cell; ROCK outside the grid.
func cell_char(cell: Vector2i) -> String:
	var size := grid_size()
	if cell.x < 0 or cell.y < 0 or cell.x >= size.x or cell.y >= size.y:
		return ROCK
	return layout[cell.y][cell.x]


## Every cell holding character ch, row by row.
func find_cells(ch: String) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in layout.size():
		for x in layout[y].length():
			if layout[y][x] == ch:
				cells.append(Vector2i(x, y))
	return cells


## True within STAIRS_SAFE_RADIUS of a stair cell (the stair rooms have no encounters).
func near_stairs(pos: Vector3) -> bool:
	for kind in [STAIRS_UP, STAIRS_DOWN]:
		for cell in find_cells(kind):
			var center := cell_center(cell)
			if Vector2(pos.x, pos.z).distance_to(Vector2(center.x, center.z)) < STAIRS_SAFE_RADIUS:
				return true
	return false


## [position, yaw] of the first walkable cell next to cell (south, north, east, west),
## facing away from it.
func _beside(cell: Vector2i) -> Array:
	for step in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
		var ch := cell_char(cell + step)
		if ch != ROCK and ch != DOOR:
			return [cell_center(cell + step), rad_to_deg(atan2(-step.x, -step.y))]
	return [cell_center(cell), 0.0]

```

- [ ] **Step 2: Create `scripts/world/dungeon_map.gd`**

```gdscript
class_name DungeonMap extends Node3D
## The cells of a dungeon floor (ZoneData.layout), built when it enters the tree: a dark
## floor in chunks, a rock block with a box collider for every rock cell next to the
## floor (the buried ones are drawn in one MultiMesh, with no collider), torches on the
## walls with a flickering point light, the stairs (a flight going up, a dark pit going
## down, with a sign), iron gates on the door cells, the lever and the key. World tells
## it the world flags (set_flags(): gates open, lever pulled, key taken) and, every
## frame, where the camera and the hero are (see_through()): the rock blocks between them
## turn see-through. Set zone before add_child.

## Height of the rock blocks.
const WALL_HEIGHT := 3.0
## The floor is drawn in squares of this many cells, so each torch only lights a few.
const FLOOR_CHUNK := 3
const FLOOR_COLOR := Color(0.36, 0.32, 0.28)
## Rock blocks get one of these shades (picked by cell, so the walls are not flat).
const ROCK_SHADES := [1.0, 0.88, 1.1]
## Opacity of a block between the camera and the hero.
const SEE_THROUGH_ALPHA := 0.3
## The camera-to-hero lines are checked at these heights above the hero's feet, against
## each block grown by SEE_THROUGH_MARGIN (the hero's body is wider than a line).
const SEE_THROUGH_HEIGHTS := [0.3, 1.6]
const SEE_THROUGH_MARGIN := 0.6
## Torches: a bracket on the wall with a flame; its light hangs out from the wall.
const TORCH_HEIGHT := 2.1
const TORCH_COLOR := Color(1.0, 0.62, 0.3)
const TORCH_ENERGY := 2.5
const TORCH_RANGE := 8.0
const FLAME_COLOR := Color(1.0, 0.7, 0.25)
## How much the torch lights waver (share of their energy) and how fast.
const FLICKER := 0.12
const FLICKER_SPEED := 9.0
const IRON := Color(0.2, 0.2, 0.23)
const WOOD := Color(0.36, 0.22, 0.1)
const STONE := Color(0.45, 0.43, 0.42)
const KEY_GOLD := Color(1.0, 0.8, 0.25)
## Angle (degrees about X) of the lever's handle: up (waiting) and pulled down.
const LEVER_UP := -40.0
const LEVER_DOWN := 40.0

var zone: ZoneData

## cell -> MeshInstance3D of each rock block next to the floor (the ones that can fade).
var _blocks := {}
var _rock_materials: Array[StandardMaterial3D] = []
var _clear_material: StandardMaterial3D
var _faded: Array[MeshInstance3D] = []
var _lights: Array[OmniLight3D] = []
var _time := 0.0
## Gate bodies (their collider goes away when the doors open), the lever's handle pivot
## and the key's root.
var _gates: Array[StaticBody3D] = []
var _lever: Node3D
var _key: Node3D


func _ready() -> void:
	for shade in ROCK_SHADES:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = zone.rock_color * shade
		mat.roughness = 1.0
		_rock_materials.append(mat)
	_clear_material = StandardMaterial3D.new()
	_clear_material.albedo_color = Color(zone.rock_color, SEE_THROUGH_ALPHA)
	_clear_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_clear_material.roughness = 1.0
	_add_floor()
	_add_rock()
	for cell in zone.find_cells(ZoneData.TORCH):
		_add_torch(cell)
	for cell in zone.find_cells(ZoneData.STAIRS_UP):
		_add_stairs(cell, true)
	for cell in zone.find_cells(ZoneData.STAIRS_DOWN):
		_add_stairs(cell, false)
	for cell in zone.find_cells(ZoneData.DOOR):
		_add_gate(cell)
	for cell in zone.find_cells(ZoneData.LEVER):
		_add_lever(cell)
	for cell in zone.find_cells(ZoneData.KEY):
		_add_key(cell)


func _process(delta: float) -> void:
	_time += delta
	for i in _lights.size():
		var wave := sin(_time * FLICKER_SPEED + i * 1.7) * 0.6 + sin(_time * 23.0 + i) * 0.4
		_lights[i].light_energy = TORCH_ENERGY * (1.0 + FLICKER * wave)
	if _key and _key.visible:
		_key.rotation.y += delta * 1.5


## Opens the gates once zone.door_flag is set, pulls the lever once zone.lever_flag is
## and hides the key once it was taken (its id is a flag).
func set_flags(flags: Dictionary) -> void:
	var open: bool = zone.door_flag != "" and flags.get(zone.door_flag, false)
	for gate in _gates:
		gate.visible = not open
		gate.process_mode = Node.PROCESS_MODE_DISABLED if open else Node.PROCESS_MODE_INHERIT
	if _lever:
		var pulled: bool = zone.lever_flag != "" and flags.get(zone.lever_flag, false)
		_lever.rotation_degrees.x = LEVER_DOWN if pulled else LEVER_UP
	if _key:
		_key.visible = not (zone.floor_key != "" and flags.get(zone.floor_key, false))


## Pulls the lever down with a short swing (the flag change follows in set_flags()).
func pull_lever() -> void:
	if _lever:
		_lever.create_tween().tween_property(_lever, "rotation_degrees:x", LEVER_DOWN, 0.3) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Makes see-through the rock blocks that hide the hero (standing at target) from the
## camera, and solid again the rest. Only the blocks of the two rows south of the hero
## (toward the camera) and one column to each side can be in the way.
func see_through(camera_pos: Vector3, target: Vector3) -> void:
	var hidden: Array[MeshInstance3D] = []
	var cell := zone.cell_at(target)
	for dy in [0, 1, 2]:
		for dx in [-1, 0, 1]:
			var block: MeshInstance3D = _blocks.get(cell + Vector2i(dx, dy))
			if block and _blocks_view(block, camera_pos, target):
				hidden.append(block)
	for block in _faded:
		if not block in hidden:
			block.material_override = _rock_materials[_shade(zone.cell_at(block.position))]
	for block in hidden:
		block.material_override = _clear_material
	_faded = hidden


func _blocks_view(block: MeshInstance3D, camera_pos: Vector3, target: Vector3) -> bool:
	var grow := Vector3(SEE_THROUGH_MARGIN, 0, SEE_THROUGH_MARGIN)
	var half := Vector3(ZoneData.CELL, WALL_HEIGHT, ZoneData.CELL) / 2.0 + grow
	var box := AABB(block.position - half, half * 2.0)
	for height in SEE_THROUGH_HEIGHTS:
		if box.intersects_segment(camera_pos, target + Vector3(0, height, 0)):
			return true
	return false


func _shade(cell: Vector2i) -> int:
	return absi(cell.x * 7 + cell.y * 13) % ROCK_SHADES.size()


## The floor under the whole grid, in FLOOR_CHUNK × FLOOR_CHUNK squares.
func _add_floor() -> void:
	var size := zone.grid_size()
	var chunk := ZoneData.CELL * FLOOR_CHUNK
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(chunk, chunk)
	for y in range(0, size.y, FLOOR_CHUNK):
		for x in range(0, size.x, FLOOR_CHUNK):
			var corner := zone.cell_center(Vector2i(x, y)) - Vector3(ZoneData.CELL, 0, ZoneData.CELL) / 2.0
			BattleStage.add_mesh(self, mesh, FLOOR_COLOR, corner + Vector3(chunk, 0, chunk) / 2.0)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	shape.shape = WorldBoundaryShape3D.new()
	body.add_child(shape)
	add_child(body)


## A block on every rock cell: the ones next to the floor (eight neighbours) one by one
## with a collider, the buried ones in a MultiMesh.
func _add_rock() -> void:
	var size := zone.grid_size()
	var box := BoxMesh.new()
	box.size = Vector3(ZoneData.CELL, WALL_HEIGHT, ZoneData.CELL)
	var body := StaticBody3D.new()
	add_child(body)
	var buried: Array[Transform3D] = []
	for y in size.y:
		for x in size.x:
			var cell := Vector2i(x, y)
			if zone.cell_char(cell) != ZoneData.ROCK:
				continue
			var pos := zone.cell_center(cell) + Vector3(0, WALL_HEIGHT / 2.0, 0)
			if not _touches_floor(cell):
				buried.append(Transform3D(Basis(), pos))
				continue
			var mi := MeshInstance3D.new()
			mi.mesh = box
			mi.material_override = _rock_materials[_shade(cell)]
			mi.position = pos
			add_child(mi)
			_blocks[cell] = mi
			var shape := CollisionShape3D.new()
			shape.shape = BoxShape3D.new()
			(shape.shape as BoxShape3D).size = box.size
			shape.position = pos
			body.add_child(shape)
	var buried_mesh := box.duplicate() as BoxMesh
	buried_mesh.material = _rock_materials[0]
	LowPoly.add_multimesh(self, buried_mesh, buried)


func _touches_floor(cell: Vector2i) -> bool:
	for dy in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			if zone.cell_char(cell + Vector2i(dx, dy)) != ZoneData.ROCK:
				return true
	return false


## The first rock neighbour of cell (north, west, east, south), as a unit step.
func _wall_side(cell: Vector2i) -> Vector2i:
	for step in [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1)]:
		if zone.cell_char(cell + step) == ZoneData.ROCK:
			return step
	return Vector2i(0, -1)


## A bracket on the cell's wall with a flame and a flickering light a little out from it.
func _add_torch(cell: Vector2i) -> void:
	var side := _wall_side(cell)
	var out := -Vector3(side.x, 0, side.y)
	var at_wall := zone.cell_center(cell) - out * (ZoneData.CELL / 2.0 - 0.12)
	var stick := BoxMesh.new()
	stick.size = Vector3(0.1, 0.5, 0.1)
	BattleStage.add_mesh(self, stick, WOOD, at_wall + out * 0.1 + Vector3(0, TORCH_HEIGHT - 0.2, 0))
	var flame := MeshInstance3D.new()
	flame.mesh = BattleStage.unit_sphere()
	flame.scale = Vector3(0.13, 0.2, 0.13)
	flame.position = at_wall + out * 0.2 + Vector3(0, TORCH_HEIGHT + 0.12, 0)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = FLAME_COLOR
	flame.material_override = mat
	flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(flame)
	var light := OmniLight3D.new()
	light.light_color = TORCH_COLOR
	light.light_energy = TORCH_ENERGY
	light.omni_range = TORCH_RANGE
	light.position = at_wall + out * 0.7 + Vector3(0, TORCH_HEIGHT + 0.2, 0)
	add_child(light)
	_lights.append(light)


## Stairs up: a flight of stone steps rising toward the cell's wall. Stairs down: a dark
## pit with the top steps going down. Both with a sign that faces the camera.
func _add_stairs(cell: Vector2i, up: bool) -> void:
	var center := zone.cell_center(cell)
	var side := _wall_side(cell)
	var toward := Vector3(side.x, 0, side.y)
	# Steps are 2.6 m wide across the way to the wall and 0.55 m deep along it.
	var along_z := side.y != 0
	if up:
		for i in 5:
			var step := BoxMesh.new()
			var height := 0.3 * (i + 1)
			step.size = Vector3(2.6, height, 0.55) if along_z else Vector3(0.55, height, 2.6)
			BattleStage.add_mesh(self, step, STONE.darkened(0.05 * i),
				center + toward * (-0.6 + i * 0.55) + Vector3(0, height / 2.0, 0))
	else:
		var pit := BoxMesh.new()
		pit.size = Vector3(2.8, 0.02, 2.8)
		BattleStage.add_mesh(self, pit, Color(0.02, 0.02, 0.02), center + Vector3(0, 0.01, 0))
		for i in 3:
			var step := BoxMesh.new()
			step.size = Vector3(2.6, 0.03, 0.5) if along_z else Vector3(0.5, 0.03, 2.6)
			BattleStage.add_mesh(self, step, STONE.darkened(0.25 + 0.2 * i),
				center - toward * (1.0 - i * 0.6) + Vector3(0, 0.03, 0))
	var label := Label3D.new()
	label.text = "Subir" if up else "Bajar"
	label.font_size = 48
	label.pixel_size = 0.008
	label.outline_size = 10
	label.modulate = Color(1.0, 0.95, 0.8)
	label.position = center + Vector3(0, 2.6, 0)
	add_child(label)


## An iron gate across the corridor of the cell, with a collider while closed.
func _add_gate(cell: Vector2i) -> void:
	var body := StaticBody3D.new()
	body.position = zone.cell_center(cell)
	# The corridor runs between the two open sides: the gate spans the other axis.
	var open_x := zone.cell_char(cell + Vector2i(-1, 0)) != ZoneData.ROCK
	if open_x:
		body.rotation_degrees.y = 90.0
	add_child(body)
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	(shape.shape as BoxShape3D).size = Vector3(ZoneData.CELL, WALL_HEIGHT, 0.6)
	shape.position.y = WALL_HEIGHT / 2.0
	body.add_child(shape)
	var bar := BoxMesh.new()
	bar.size = Vector3(0.1, WALL_HEIGHT, 0.1)
	for i in 9:
		BattleStage.add_mesh(body, bar, IRON,
			Vector3(-1.8 + i * 0.45, WALL_HEIGHT / 2.0, 0))
	var rail := BoxMesh.new()
	rail.size = Vector3(ZoneData.CELL, 0.14, 0.14)
	for y in [0.4, 1.6, 2.8]:
		BattleStage.add_mesh(body, rail, IRON, Vector3(0, y, 0))
	_gates.append(body)


## A lever on a stone base: its handle on a pivot, up until pulled.
func _add_lever(cell: Vector2i) -> void:
	var center := zone.cell_center(cell)
	var base := BoxMesh.new()
	base.size = Vector3(0.7, 0.5, 0.5)
	BattleStage.add_mesh(self, base, STONE, center + Vector3(0, 0.25, 0))
	_lever = Node3D.new()
	_lever.position = center + Vector3(0, 0.5, 0)
	_lever.rotation_degrees.x = LEVER_UP
	add_child(_lever)
	var handle := BoxMesh.new()
	handle.size = Vector3(0.08, 0.8, 0.08)
	BattleStage.add_mesh(_lever, handle, WOOD, Vector3(0, 0.4, 0))
	BattleStage.add_mesh(_lever, BattleStage.unit_sphere(), Color(0.7, 0.15, 0.1),
		Vector3(0, 0.85, 0), Vector3.ONE * 0.1)


## A gold key turning slowly over a small stone pedestal.
func _add_key(cell: Vector2i) -> void:
	var center := zone.cell_center(cell)
	var pedestal := CylinderMesh.new()
	pedestal.top_radius = 0.35
	pedestal.bottom_radius = 0.42
	pedestal.height = 0.6
	pedestal.radial_segments = 6
	BattleStage.add_mesh(self, pedestal, STONE, center + Vector3(0, 0.3, 0))
	_key = Node3D.new()
	_key.position = center + Vector3(0, 1.1, 0)
	_key.scale = Vector3.ONE * 1.8
	add_child(_key)
	var ring := TorusMesh.new()
	ring.inner_radius = 0.08
	ring.outer_radius = 0.16
	ring.rings = 8
	ring.ring_segments = 6
	BattleStage.add_mesh(_key, ring, KEY_GOLD, Vector3(0, 0.2, 0), Vector3.ONE,
		Vector3(90, 0, 0))
	var shaft := BoxMesh.new()
	shaft.size = Vector3(0.06, 0.4, 0.06)
	BattleStage.add_mesh(_key, shaft, KEY_GOLD, Vector3(0, -0.12, 0))
	var bit := BoxMesh.new()
	bit.size = Vector3(0.14, 0.06, 0.06)
	BattleStage.add_mesh(_key, bit, KEY_GOLD, Vector3(0.07, -0.26, 0))
	var glow := OmniLight3D.new()
	glow.light_color = KEY_GOLD
	glow.light_energy = 0.8
	glow.omni_range = 2.5
	_key.add_child(glow)
```

- [ ] **Step 3: Dungeon floors in `World` and `WorldStage`**

In `scripts/world/world.gd`:

1. Replace:

```gdscript
## one of them walks there and does it on arrival. With the boss present, walking into
## it starts the boss battle. Walking into an open exit emits exit_requested; a closed
## one (its world flag not set: set_world_flags()) shows its fog and its notice.
## Encounters and exits freeze the player until set_active(true) (or until Game frees
```

with:

```gdscript
## one of them walks there and does it on arrival. With the boss present, walking into
## it starts the boss battle. Walking into an open exit (or onto the stairs of a dungeon
## floor) emits exit_requested; a closed one (its world flag not set: set_world_flags())
## shows its fog and its notice. A dungeon floor (ZoneData.layout) is a DungeonMap: its
## rock blocks turn see-through between the camera and the hero, the hero carries a
## lantern underground, and next to the lever, the key or a locked gate Enter / Space
## pulls it (lever_pulled), takes it (key_taken) or tries the gate (door_used).
## Encounters and exits freeze the player until set_active(true) (or until Game frees
```

2. Replace:

```gdscript
signal exit_requested(zone_id: String, entry_id: String)

```

with:

```gdscript
signal exit_requested(zone_id: String, entry_id: String)
## Dungeon floors: the player pulled the lever, took the key or tried a locked gate.
signal lever_pulled
signal key_taken
signal door_used

```

3. Replace:

```gdscript
const EXIT_REARM := 0.8
## A click or tap this close to a figure or a chest means "go there and use it".
```

with:

```gdscript
const EXIT_REARM := 0.8
## How close the player must be to a lever, a key or a gate (its centre) to use it.
const MECHANISM_RADIUS := 2.2
## A click or tap this close to a figure or a chest means "go there and use it".
```

4. Replace:

```gdscript
const CHEST := "chest"
const PROMPTS := {
```

with:

```gdscript
const CHEST := "chest"
const LEVER := "lever"
const KEY := "key"
const DOOR := "door"
const PROMPTS := {
```

5. Replace:

```gdscript
	CHEST: "Enter o toca: abrir",
}
```

with:

```gdscript
	CHEST: "Enter o toca: abrir",
	LEVER: "Enter o toca: tirar",
	KEY: "Enter o toca: coger",
	DOOR: "Enter o toca: abrir",
}
```

6. Replace:

```gdscript
const STEP_DISTANCE := 1.6

```

with:

```gdscript
const STEP_DISTANCE := 1.6
## Underground the hero carries a lantern: a warm light over the head.
const LANTERN_COLOR := Color(1.0, 0.85, 0.65)
const LANTERN_ENERGY := 2.0
const LANTERN_RANGE := 10.0
const LANTERN_HEIGHT := 2.4

```

7. Replace:

```gdscript
var _fogs := {}
var _flags := {}
```

with:

```gdscript
var _fogs := {}
## ZoneData.all_exits(): the arches and, on a dungeon floor, the stairs.
var _exits: Array = []
## The cells of a dungeon floor (null on an open map).
var _dungeon: DungeonMap
var _flags := {}
```

8. Replace:

```gdscript
	_grass = WorldStage.build(self, zone)
	for npc: Dictionary in zone.npcs:
```

with:

```gdscript
	_grass = WorldStage.build(self, zone)
	if zone.is_dungeon():
		_dungeon = DungeonMap.new()
		_dungeon.zone = zone
		add_child(_dungeon)
	for npc: Dictionary in zone.npcs:
```

9. Replace:

```gdscript
		_chest_lids[id] = build_chest(self, Chests.CHESTS[id])
	for exit: Dictionary in zone.exits:
		_fogs[exit.id] = _build_exit(exit)
	set_boss_present(false)
```

with:

```gdscript
		_chest_lids[id] = build_chest(self, Chests.CHESTS[id])
	_exits = zone.all_exits()
	for exit: Dictionary in _exits:
		if not exit.get("stairs", false):
			_fogs[exit.id] = _build_exit(exit)
	set_boss_present(false)
```

10. Replace:

```gdscript
	add_child(_player)
	_camera = FollowCamera.new()
```

with:

```gdscript
	add_child(_player)
	if zone.underground:
		var lantern := OmniLight3D.new()
		lantern.light_color = LANTERN_COLOR
		lantern.light_energy = LANTERN_ENERGY
		lantern.omni_range = LANTERN_RANGE
		lantern.position.y = LANTERN_HEIGHT
		_player.add_child(lantern)
	_camera = FollowCamera.new()
```

11. Replace:

```gdscript
		_marker.position = _player.move_target
	if _waiting or _talking:
```

with:

```gdscript
		_marker.position = _player.move_target
	if _dungeon:
		_dungeon.see_through(_camera.global_position, _player.global_position)
	if _waiting or _talking:
```

12. Replace:

```gdscript

## The world progress (GameState.world_flags): which exits are open (their fog hides)
## and what the villagers say.
func set_world_flags(flags: Dictionary) -> void:
```

with:

```gdscript

## The world progress (GameState.world_flags): which exits are open (their fog hides),
## what the villagers say and, on a dungeon floor, the gates, the lever and the key.
func set_world_flags(flags: Dictionary) -> void:
```

13. Replace:

```gdscript
		(_fogs[exit.id] as Node3D).visible = not _is_open(exit)

```

with:

```gdscript
		(_fogs[exit.id] as Node3D).visible = not _is_open(exit)
	if _dungeon:
		_dungeon.set_flags(flags)


## Swings the lever down (Game sets its flag and calls set_world_flags()).
func pull_lever() -> void:
	if _dungeon:
		_dungeon.pull_lever()

```

14. Replace:

```gdscript
	var nearest_d := INF
	for exit: Dictionary in zone.exits:
		var d := _flat_distance(pos, exit.pos)
```

with:

```gdscript
	var nearest_d := INF
	for exit: Dictionary in _exits:
		var d := _flat_distance(pos, exit.pos)
```

15. Replace:

```gdscript
## The nearest thing in reach of pos that can be used: {"kind": TALK / NPC / SHOP / INN
## / CHEST, "id": shop, inn or chest id ("" otherwise), "index": the npc's index}, or {}.
func _nearest_use(pos: Vector3) -> Dictionary:
```

with:

```gdscript
## The nearest thing in reach of pos that can be used: {"kind": TALK / NPC / SHOP / INN
## / CHEST / LEVER / KEY / DOOR, "id": shop, inn or chest id ("" otherwise), "index":
## the npc's index}, or {}.
func _nearest_use(pos: Vector3) -> Dictionary:
```

16. Replace:

```gdscript

## Everything usable now: the zone's figures and its closed chests.
func _uses() -> Array[Dictionary]:
```

with:

```gdscript

## Everything usable now: the zone's figures, its closed chests and, on a dungeon floor,
## the lever until pulled, the key until taken and the gates while closed.
func _uses() -> Array[Dictionary]:
```

17. Replace:

```gdscript
				"radius": CHEST_RADIUS})
	return uses
```

with:

```gdscript
				"radius": CHEST_RADIUS})
	if _dungeon == null:
		return uses
	var mechanisms := [[ZoneData.LEVER, LEVER, zone.lever_flag],
		[ZoneData.KEY, KEY, zone.floor_key], [ZoneData.DOOR, DOOR, zone.door_flag]]
	for mechanism in mechanisms:
		if mechanism[2] == "" or _flags.get(mechanism[2], false):
			continue
		for cell in zone.find_cells(mechanism[0]):
			uses.append({"kind": mechanism[1], "id": "", "index": -1,
				"pos": zone.cell_center(cell), "radius": MECHANISM_RADIUS})
	return uses
```

18. Replace:

```gdscript
			chest_opened.emit(use.id)

```

with:

```gdscript
			chest_opened.emit(use.id)
		LEVER:
			lever_pulled.emit()
		KEY:
			key_taken.emit()
		DOOR:
			door_used.emit()

```

19. Replace:

```gdscript
		print("Salida: %s (%s)" % [zone_id, entry_id])
		set_active(true))


```

with:

```gdscript
		print("Salida: %s (%s)" % [zone_id, entry_id])
		set_active(true))
	lever_pulled.connect(func() -> void:
		print("Palanca")
		pull_lever()
		_flags[zone.lever_flag] = true
		_flags[zone.door_flag] = true
		set_world_flags(_flags))
	key_taken.connect(func() -> void:
		print("Llave")
		_flags[zone.floor_key] = true
		set_world_flags(_flags))
	door_used.connect(func() -> void: print("Puerta"))


```

In `scripts/world/world_stage.gd`:

1. Replace:

```gdscript
## with trunk colliders) and bushes scattered with fixed seeds, invisible walls and hills
## outside. Exits, figures and chests are World's. Every query takes the zone.

```

with:

```gdscript
## with trunk colliders) and bushes scattered with fixed seeds, invisible walls and hills
## outside. Exits, figures and chests are World's. A dungeon floor only gets its sky and
## light here: its cells are a DungeonMap, which World adds. Every query takes the zone.

```

2. Replace:

```gdscript
const TREE_COLLIDER_HEIGHT := 3.0


## Builds zone under root. Returns the tall grass material (null if the zone has no
```

with:

```gdscript
const TREE_COLLIDER_HEIGHT := 3.0

## _near_chest()'s cache: the zone id and its chests' spots on the ground.
static var _chest_zone := ""
static var _chest_spots: Array[Vector2] = []


## Builds zone under root. Returns the tall grass material (null if the zone has no
```

3. Replace:

```gdscript
	BattleStage.build_environment(root, zone)
	_add_ground(root, zone)
```

with:

```gdscript
	BattleStage.build_environment(root, zone)
	if zone.is_dungeon():
		return null
	_add_ground(root, zone)
```

4. Replace:

```gdscript

## True on the dirt path and the safe discs: no encounters there. margin widens every
## one of them (the grass keeps a little off the path's edge).
static func is_on_path(zone: ZoneData, pos: Vector3, margin := 0.0) -> bool:
	var p := Vector2(pos.x, pos.z)
```

with:

```gdscript

## True on the dirt path and the safe discs (and in the stair rooms of a dungeon floor):
## no encounters there. margin widens every one of them (the grass keeps a little off the
## path's edge).
static func is_on_path(zone: ZoneData, pos: Vector3, margin := 0.0) -> bool:
	if zone.is_dungeon() and zone.near_stairs(pos):
		return true
	var p := Vector2(pos.x, pos.z)
```

5. Replace:

```gdscript

## True within margin of one of the zone's chests (Chests.CHESTS of this zone).
static func _near_chest(zone: ZoneData, pos: Vector3, margin: float) -> bool:
	var p := Vector2(pos.x, pos.z)
	for chest_id in Chests.of_zone(zone.id):
		var chest_pos: Vector3 = Chests.CHESTS[chest_id].pos
		if p.distance_to(Vector2(chest_pos.x, chest_pos.z)) < margin:
			return true
```

with:

```gdscript

## True within margin of one of the zone's chests (Chests.CHESTS of this zone). The
## chest spots of the last zone asked about are kept, so the thousands of grass, tree and
## bush candidates of a build don't look them up each time.
static func _near_chest(zone: ZoneData, pos: Vector3, margin: float) -> bool:
	if _chest_zone != zone.id:
		_chest_zone = zone.id
		_chest_spots.clear()
		for chest_id in Chests.of_zone(zone.id):
			var chest_pos: Vector3 = Chests.CHESTS[chest_id].pos
			_chest_spots.append(Vector2(chest_pos.x, chest_pos.z))
	var p := Vector2(pos.x, pos.z)
	for spot in _chest_spots:
		if p.distance_to(spot) < margin:
			return true
```

- [ ] **Step 4: The cave backdrop and the underground environment**

In `scripts/battle/battle_stage.gd`:

1. Replace:

```gdscript
## low-poly rocks, trees and bushes, and distant hills. "pradera" is the open meadow;
## "bosque" closes a ring of trees around the fighters on darker ground. The environment,
## the mesh and model helpers and the rock and tree models are shared with WorldStage.
```

with:

```gdscript
## low-poly rocks, trees and bushes, and distant hills. "pradera" is the open meadow;
## "bosque" closes a ring of trees around the fighters on darker ground; "mina" is a
## cave: rock floor, a wall of rock blocks and boulders behind and beside the fighters,
## stalagmites and two torches, in the dark of an underground zone. The environment,
## the mesh and model helpers and the rock and tree models are shared with WorldStage.
```

2. Replace:

```gdscript

## zone: whose sky, light and backdrop to use (null: the meadow's).
static func build(root: Node3D, zone: ZoneData = null) -> void:
	build_environment(root, zone)
	var forest := zone != null and zone.backdrop == "bosque"
```

with:

```gdscript

## The mine backdrop: rock floor, the blocks of the cave wall ([position, size]), the
## boulders (same entries as ROCKS), the stalagmites ([position, radius, height]) and
## the two torches ([position of the flame]).
const CAVE_FLOOR := Color(0.27, 0.24, 0.22)
const CAVE_ROCK := Color(0.33, 0.29, 0.26)
const CAVE_BLOCKS := [
	[Vector3(-8, 2, -10), Vector3(6, 4, 4)], [Vector3(-2, 2.5, -12), Vector3(6, 5, 4)],
	[Vector3(4, 2, -11), Vector3(6, 4, 4)], [Vector3(10, 2.5, -9), Vector3(6, 5, 4)],
	[Vector3(-10, 2, -4), Vector3(4, 4, 6)], [Vector3(11, 2, -3), Vector3(4, 4, 6)],
	[Vector3(-11, 2, 3), Vector3(4, 4, 6)], [Vector3(12, 2, 4), Vector3(4, 4, 6)],
	[Vector3(0, 4.5, -16), Vector3(30, 9, 4)],
]
const CAVE_ROCKS := [
	[Vector3(-6.0, 0, -7.0), 2, 9.0, 30.0],
	[Vector3(6.5, 0, -6.5), 4, 8.0, 110.0],
	[Vector3(-7.5, 0, 0.5), 1, 7.0, 200.0],
	[Vector3(8.0, 0, 1.0), 0, 8.0, 80.0],
]
const STALAGMITES := [
	[Vector3(-4.5, 0, -5.5), 0.35, 1.6], [Vector3(4.0, 0, -7.5), 0.45, 2.2],
	[Vector3(-3.0, 0, -8.5), 0.3, 1.2], [Vector3(5.5, 0, -2.5), 0.3, 1.1],
	[Vector3(-5.5, 0, 2.5), 0.25, 0.9],
]
const CAVE_TORCHES := [Vector3(-3.5, 2.4, -9.8), Vector3(5.0, 2.4, -8.8)]


## zone: whose sky, light and backdrop to use (null: the meadow's).
static func build(root: Node3D, zone: ZoneData = null) -> void:
	build_environment(root, zone)
	if zone != null and zone.backdrop == "mina":
		_build_cave(root)
		return
	var forest := zone != null and zone.backdrop == "bosque"
```

3. Replace:

```gdscript

static func _is_grass_free(pos: Vector3) -> bool:
```

with:

```gdscript

static func _build_cave(root: Node3D) -> void:
	var ground := PlaneMesh.new()
	ground.size = Vector2(60, 60)
	add_mesh(root, ground, CAVE_FLOOR, Vector3.ZERO)
	for block in CAVE_BLOCKS:
		var box := BoxMesh.new()
		box.size = block[1]
		add_mesh(root, box, CAVE_ROCK, block[0])
	for rock in CAVE_ROCKS:
		add_model(root, ROCK_SCENES[rock[1]], rock[0], rock[2], rock[3])
	for spike in STALAGMITES:
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = spike[1]
		cone.height = spike[2]
		cone.radial_segments = 6
		add_mesh(root, cone, CAVE_ROCK.lightened(0.1), spike[0] + Vector3(0, spike[2] / 2.0, 0))
	for flame_pos in CAVE_TORCHES:
		var stick := BoxMesh.new()
		stick.size = Vector3(0.1, 0.5, 0.1)
		add_mesh(root, stick, DungeonMap.WOOD, flame_pos - Vector3(0, 0.3, 0))
		var flame := MeshInstance3D.new()
		flame.mesh = unit_sphere()
		flame.scale = Vector3(0.13, 0.2, 0.13)
		flame.position = flame_pos
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = DungeonMap.FLAME_COLOR
		flame.material_override = mat
		root.add_child(flame)
		var light := OmniLight3D.new()
		light.light_color = DungeonMap.TORCH_COLOR
		light.light_energy = DungeonMap.TORCH_ENERGY
		light.omni_range = 10.0
		light.position = flame_pos + Vector3(0, 0.2, 1.0)
		root.add_child(light)
	# The fighters' own light, from the camera's side (the hero's lantern).
	var lantern := OmniLight3D.new()
	lantern.light_color = Color(1.0, 0.85, 0.65)
	lantern.light_energy = 1.2
	lantern.omni_range = 12.0
	lantern.position = Vector3(0.5, 3.0, 3.5)
	root.add_child(lantern)


static func _is_grass_free(pos: Vector3) -> bool:
```

4. Replace:

```gdscript
static func _add_environment(root: Node3D, zone: ZoneData) -> void:
	var sky_material := ProceduralSkyMaterial.new()
```

with:

```gdscript
static func _add_environment(root: Node3D, zone: ZoneData) -> void:
	if zone.underground:
		_add_dark_environment(root, zone)
		return
	var sky_material := ProceduralSkyMaterial.new()
```

5. Replace:

```gdscript

static func _add_sun(root: Node3D, zone: ZoneData) -> void:
	var sun := DirectionalLight3D.new()
```

with:

```gdscript

## Underground: a black background, a flat dim ambient light and dark fog; no sky.
static func _add_dark_environment(root: Node3D, zone: ZoneData) -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.BLACK
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = zone.ambient_color
	env.ambient_light_energy = zone.ambient_energy
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = true
	env.glow_intensity = 0.8
	env.fog_enabled = true
	env.fog_light_color = zone.haze
	env.fog_density = zone.fog_density
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	root.add_child(world_env)


static func _add_sun(root: Node3D, zone: ZoneData) -> void:
	if zone.underground:
		return
	var sun := DirectionalLight3D.new()
```

- [ ] **Step 5: `Game`: mechanisms, the transition guard and the mine autoplay starts**

In `scripts/game/game.gd`:

1. Replace:

```gdscript
## what it holds (Chests.open()) and stays open. The hero's figure on the map and in
## battle shows the weapon and shield worn. Picks the zone's music (map, village, battle,
## boss), autosaves after talking, after every won battle, after shopping, (silently)
```

with:

```gdscript
## what it holds (Chests.open()) and stays open. The hero's figure on the map and in
## battle shows the weapon and shield worn. On a dungeon floor the lever sets its world
## flag (and opens the gates it works), the key goes to the key items (and its flag is
## set, so it stays taken) and a locked gate opens with the key, which is used up; all
## three autosave silently. Picks the zone's music (map, village, battle,
## boss), autosaves after talking, after every won battle, after shopping, (silently)
```

2. Replace:

```gdscript
const KEY_ITEM_NOTICE := "¡Consigues un %s!"
const MENU_TOUR_DELAY := 1.0
```

with:

```gdscript
const KEY_ITEM_NOTICE := "¡Consigues un %s!"
const LEVER_NOTICE := "¡Tiras de la palanca! Se oye cómo se abre una reja."
const KEY_NOTICE := "¡Encuentras la %s!"
const DOOR_NOTICE := "Abres la puerta con la %s."
const MENU_TOUR_DELAY := 1.0
```

3. Replace:

```gdscript
		"quest_done": true,
	},
```

with:

```gdscript
		"quest_done": true,
	},
	# Zone 2 done: Lv 9 with the Bruja's EXP, the forest gear and the first fragment.
	"mina_1": {
		"experience": 541,
		"gold": 250,
		"gear": ["espada_hierro", "cota_malla", "escudo_hierro"],
		"flags": ["rey_slime", "bruja"],
		"key_items": ["fragmento_bosque"],
		"quest_done": true,
	},
	# Ready for the Golem: Lv 13, the mine's gear, the gates of floors 2 and 3 open.
	"mina_3": {
		"experience": 1073,
		"gold": 100,
		"gear": ["espada_acero", "armadura_acero", "escudo_acero"],
		"flags": ["rey_slime", "bruja", "mina_palanca", "llave_mina", "mina_puerta"],
		"key_items": ["fragmento_bosque"],
		"quest_done": true,
		"town": "mina_1",
	},
```

4. Replace:

```gdscript
		_world.place_player(start_pos)
	# Synthesize the tracks played later now, under black, so no first play stalls.
```

with:

```gdscript
		_world.place_player(start_pos)
	_world.freeze(false)
	# Synthesize the tracks played later now, under black, so no first play stalls.
```

5. Replace:

```gdscript
			state.world_flags[flag] = true
		if start.quest_done:
```

with:

```gdscript
			state.world_flags[flag] = true
		for id: String in start.get("key_items", []):
			state.key_items.append(id)
		state.town_zone = start.get("town", state.town_zone)
		if start.quest_done:
```

6. Replace:

```gdscript
## Frees the current map and builds zone_id with the player at entry_id ("" for the
## zone's start entry). No fade: callers fade around it.
func _switch_zone(zone_id: String, entry_id: String) -> void:
```

with:

```gdscript
## Frees the current map and builds zone_id with the player at entry_id ("" for the
## zone's start entry). No fade: callers fade around it. The new map starts frozen
## (World.freeze()), so nothing on it can fire while Game is still busy fading in;
## every caller unfreezes it once the fade is over.
func _switch_zone(zone_id: String, entry_id: String) -> void:
```

7. Replace:

```gdscript
	move_child(_world, 0)
	_world.set_audio(_audio)
```

with:

```gdscript
	move_child(_world, 0)
	_world.freeze(true)
	_world.set_audio(_audio)
```

8. Replace:

```gdscript
	_world.exit_requested.connect(_on_exit)
	_world.village_changed.connect(_on_village_changed)
```

with:

```gdscript
	_world.exit_requested.connect(_on_exit)
	_world.lever_pulled.connect(_on_lever)
	_world.key_taken.connect(_on_key)
	_world.door_used.connect(_on_door)
	_world.village_changed.connect(_on_village_changed)
```

9. Replace:

```gdscript
		_go_to_town()
		notice = "Has vuelto a %s." % _zone.village_name
	battle.queue_free()
```

with:

```gdscript
		_go_to_town()
		notice = "Has vuelto %s." % _to_place(_zone.village_name)
	battle.queue_free()
```

10. Replace:

```gdscript
	_world.set_active(true)
	_play_map_music()
	await _fade_to(0.0)
	if notice != "":
```

with:

```gdscript
	_world.set_active(true)
	# Frozen until the fade is over: an exit or an encounter while Game is busy would be
	# ignored and leave the map waiting forever.
	_world.freeze(true)
	_play_map_music()
	await _fade_to(0.0)
	await _world.freeze(false)
	if notice != "":
```

11. Replace:

```gdscript
	await _fade_to(0.0)
	_autosave(false)
```

with:

```gdscript
	await _fade_to(0.0)
	await _world.freeze(false)
	_autosave(false)
```

12. Replace:

```gdscript
	await _world.freeze(false)
	_world.show_notice("Vuelas a %s." % _zone.village_name)
	_autosave(false)
```

with:

```gdscript
	await _world.freeze(false)
	_world.show_notice("Vuelas %s." % _to_place(_zone.village_name))
	_autosave(false)
```

13. Replace:

```gdscript

## Writes the save file; shows SAVED_NOTICE if notice. Returns the saved data, or an
```

with:

```gdscript

## The dungeon floor's lever: sets its flag, which opens the gates it works.
func _on_lever() -> void:
	if _busy or _zone.lever_flag == "":
		return
	state.world_flags[_zone.lever_flag] = true
	_world.pull_lever()
	_audio.play_sfx(SfxLibrary.DOOR)
	_world.set_world_flags(state.world_flags)
	_world.show_notice(LEVER_NOTICE)
	_autosave(false)


## The key lying on the floor: into the key items; its flag keeps it taken.
func _on_key() -> void:
	if _busy or _zone.floor_key == "":
		return
	state.world_flags[_zone.floor_key] = true
	state.key_items.append(_zone.floor_key)
	_audio.play_sfx(SfxLibrary.LEVEL_UP)
	_world.set_world_flags(state.world_flags)
	_world.show_notice(KEY_NOTICE % Inventory.KEY_ITEMS[_zone.floor_key])
	_autosave(false)


## A closed gate: the key of the floor opens it (and is used up); otherwise its text.
func _on_door() -> void:
	if _busy:
		return
	var key := _zone.door_key
	if key == "" or not key in state.key_items:
		_world.show_notice(_zone.door_text)
		return
	state.key_items.erase(key)
	state.world_flags[_zone.door_flag] = true
	_audio.play_sfx(SfxLibrary.DOOR)
	_world.set_world_flags(state.world_flags)
	_world.show_notice(DOOR_NOTICE % Inventory.KEY_ITEMS[key])
	_autosave(false)


## Writes the save file; shows SAVED_NOTICE if notice. Returns the saved data, or an
```

14. Replace:

```gdscript

## One line with every saved value, keys sorted, for --autoplay-save.
```

with:

```gdscript

## "a Villaclaro", "a la aldea del bosque", "al refugio de la mina".
static func _to_place(place: String) -> String:
	return "al " + place.substr(3) if place.begins_with("el ") else "a " + place


## One line with every saved value, keys sorted, for --autoplay-save.
```

- [ ] **Step 6: Chests, shop, inn and music of the mine**

In `scripts/game/chests.gd`:

1. Replace:

```gdscript
## autoplay route and two off it; the three of the forest stand in its glades, next to
## its route. All away from the paths. Pure: open() changes a GameState and returns the
## message.
```

with:

```gdscript
## autoplay route and two off it; the three of the forest stand in its glades, next to
## its route. All away from the paths. In the mine each stands on the C cell of its floor
## (ZoneData.cell_center()), next to the floor's route. Pure: open() changes a GameState and returns the
## message.
```

2. Replace:

```gdscript
		"item": Inventory.WING},
}
```

with:

```gdscript
		"item": Inventory.WING},
	"mina_1_cofre": {"zone": "mina_1", "pos": Vector3(16, 0, -20), "yaw": 180.0, "gold": 120},
	"mina_2_cofre": {"zone": "mina_2", "pos": Vector3(16, 0, 0), "yaw": 180.0, "gold": 120},
	"mina_3_cofre": {"zone": "mina_3", "pos": Vector3(-24, 0, 12), "yaw": -90.0,
		"item": Inventory.ETHER},
}
```

In `scripts/game/shop.gd`:

1. Replace:

```gdscript
const BOSQUE := "bosque"
## shop id -> keeper's name, equipment and items (Inventory ids) on sale, in list order.
```

with:

```gdscript
const BOSQUE := "bosque"
const MINA := "mina"
## shop id -> keeper's name, equipment and items (Inventory ids) on sale, in list order.
```

2. Replace:

```gdscript
		"equipment": ["espada_hierro", "cota_malla", "escudo_hierro"],
		"items": [Inventory.POTION, Inventory.ANTIDOTE, Inventory.ETHER, Inventory.WING],
```

with:

```gdscript
		"equipment": ["espada_hierro", "cota_malla", "escudo_hierro"],
		"items": [Inventory.POTION, Inventory.ANTIDOTE, Inventory.ETHER, Inventory.WING],
	},
	MINA: {
		"keeper": "Herrero",
		"equipment": ["espada_acero", "armadura_acero", "escudo_acero"],
		"items": [Inventory.POTION, Inventory.ANTIDOTE, Inventory.ETHER, Inventory.WING],
```

In `scripts/game/inn.gd`:

1. Replace:

```gdscript
const BOSQUE := "bosque"
## inn id -> keeper's name and price of a night in gold.
```

with:

```gdscript
const BOSQUE := "bosque"
const MINA := "mina"
## inn id -> keeper's name and price of a night in gold.
```

2. Replace:

```gdscript
	BOSQUE: {"keeper": "Posadera", "price": 15},
}
```

with:

```gdscript
	BOSQUE: {"keeper": "Posadera", "price": 15},
	MINA: {"keeper": "Posadero", "price": 30},
}
```

In `scripts/audio/music_library.gd`:

1. Replace:

```gdscript
const FOREST := "forest"
const BATTLE := "battle"
```

with:

```gdscript
const FOREST := "forest"
const MINE := "mine"
const BATTLE := "battle"
```

2. Replace:

```gdscript
const DEFEAT := "defeat"
const IDS: Array[String] = [TITLE, MAP, VILLAGE, FOREST, BATTLE, BOSS, VICTORY, DEFEAT]

```

with:

```gdscript
const DEFEAT := "defeat"
const IDS: Array[String] = [TITLE, MAP, VILLAGE, FOREST, MINE, BATTLE, BOSS, VICTORY,
	DEFEAT]

```

3. Replace:

```gdscript
		"drums": ["k/4 h/4 h/2 h/2 s/4"],
	},
```

with:

```gdscript
		"drums": ["k/4 h/4 h/2 h/2 s/4"],
	},
	# Slow and in D minor, with sparse drums like dripping water.
	MINE: {
		"bpm": 88, "loop": true, "duty": 0.25,
		"lead": [
			"D5/6 F5/2 A5/8", "G5/4 F5/4 E5/8", "D5/4 E5/4 F5/6 E5/2", "C#5/12 r/4",
			"A4/6 D5/2 F5/8", "E5/4 G5/4 A#5/8", "A5/4 G5/4 F5/4 E5/4", "D5/12 r/4",
		],
		"bass": [
			"D2/4 A2/4 D2/4 A2/4", "C2/4 G2/4 C2/4 G2/4", "A#1/4 F2/4 A#1/4 F2/4",
			"A1/4 E2/4 A1/4 E2/4", "D2/4 A2/4 D2/4 A2/4", "G1/4 D2/4 G1/4 D2/4",
			"A1/4 E2/4 A1/4 C#2/4", "D2/8 A1/8",
		],
		"drums": ["k/4 r/4 h/4 r/2 h/2"],
	},
```

- [ ] **Step 7: Create the three floors**

Create `data/zones/mina_1.tres`:

```ini
[gd_resource type="Resource" script_class="ZoneData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/world/zone_data.gd" id="1_zone"]

[resource]
script = ExtResource("1_zone")
id = "mina_1"
display_name = "la mina"
number = 3
half_size = Vector2(30, 26)
ground_color = Color(0.24, 0.21, 0.19, 1)
has_grass = false
safe_discs = [[Vector3(0, 0, 16), 13.0]]
village_name = "el refugio de la mina"
village_pos = Vector3(0, 0, 16)
village_radius = 13.0
entries = {
"refugio": [Vector3(0, 0, 13), 0.0],
"sur": [Vector3(0, 0, 17), 0.0]
}
start_entry = "sur"
town_entry = "refugio"
exits = [{
"entry": "norte",
"id": "sur",
"label": "Al bosque",
"lock": "",
"lock_text": "",
"pos": Vector3(0, 0, 21),
"to": "bosque",
"yaw": 0.0
}]
npcs = [{
"id": "mina",
"kind": "shop",
"look": "MERCHANT",
"name": "Herrero",
"pos": Vector3(-8, 0, 12),
"yaw": 180.0
}, {
"id": "mina",
"kind": "inn",
"look": "INNKEEPER",
"name": "Posadero",
"pos": Vector3(8, 0, 12),
"yaw": 180.0
}, {
"after_flag": "golem_piedra",
"kind": "npc",
"lines": ["Este refugio es lo único que queda de la vieja mina.", "Abajo, en la tercera planta, despertó un golem de piedra.", "Dicen que una palanca abre las rejas de la segunda planta."],
"lines_after": ["¿Has vencido al golem? ¡Por fin podremos volver a picar!", "La niebla viene del castillo, al otro lado de las montañas."],
"look": "VILLAGER",
"name": "Minera",
"pos": Vector3(-10, 0, 19),
"yaw": 180.0
}]
formations = [["golem_barro"], ["arana"], ["espectro"], ["arana"], ["arana", "espectro"], ["golem_barro", "arana"]]
start_formations = [["golem_barro"], ["arana"], ["espectro"]]
start_pos = Vector3(0, 0, 17)
start_radius = 24.0
encounter_grace = 6.0
encounter_chance = 0.025
music = "mine"
village_music = "village"
haze = Color(0.03, 0.03, 0.05, 1)
fog_density = 0.012
backdrop = "mina"
layout = PackedStringArray("###############", "#T..B#.....C..#", "#....#.#####..#", "#....#.#T..#..#", "###.##.#...#.##", "#.....T#...#..#", "#.###.##.###..#", "#..T......T...#", "####.##.#######", "####T.....T####", "####.......####", "####.T...T.####", "###############")
underground = true
ambient_color = Color(0.5, 0.48, 0.6, 1)
ambient_energy = 1.0
rock_color = Color(0.48, 0.42, 0.37, 1)
stairs_down = "mina_2"
autoplay_route = Array[Vector3]([Vector3(0, 0, 17), Vector3(-6.5, 0, 12.5), Vector3(6.5, 0, 12.5), Vector3(0, 0, 12), Vector3(0, 0, 4), Vector3(20, 0, 4), Vector3(20, 0, -20), Vector3(16, 0, -18.5), Vector3(-4, 0, -20), Vector3(-4, 0, -4), Vector3(-16, 0, -4), Vector3(-16, 0, -12), Vector3(-12, 0, -20)])
autoplay_boss_level = 13
```

Create `data/zones/mina_2.tres`:

```ini
[gd_resource type="Resource" script_class="ZoneData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/world/zone_data.gd" id="1_zone"]

[resource]
script = ExtResource("1_zone")
id = "mina_2"
display_name = "la mina"
number = 3
half_size = Vector2(30, 26)
ground_color = Color(0.24, 0.21, 0.19, 1)
has_grass = false
formations = [["golem_barro"], ["arana"], ["espectro"], ["arana"], ["arana", "espectro"], ["golem_barro", "arana"]]
encounter_grace = 6.0
encounter_chance = 0.025
music = "mine"
village_music = "village"
haze = Color(0.03, 0.03, 0.05, 1)
fog_density = 0.012
backdrop = "mina"
layout = PackedStringArray("###############", "#T...#......TS#", "#.L..#.####...#", "#....#.#..##.##", "##.###.#T.....#", "#......#..#.#.#", "#.####.##.#C#.#", "#T#..T........#", "#.#.######.##D#", "#...#....#..#.#", "###.#.T..#..#.#", "#......#....#B#", "###############")
underground = true
ambient_color = Color(0.5, 0.48, 0.6, 1)
ambient_energy = 1.0
rock_color = Color(0.48, 0.42, 0.37, 1)
start_entry = "S"
stairs_up = "mina_1"
stairs_down = "mina_3"
lever_flag = "mina_palanca"
door_flag = "mina_palanca"
door_text = "La reja no se mueve. Quizá haya un mecanismo cerca."
autoplay_route = Array[Vector3]([Vector3(24, 0, -16), Vector3(20, 0, -16), Vector3(20, 0, -20), Vector3(-4, 0, -20), Vector3(-4, 0, -4), Vector3(-20, 0, -4), Vector3(-20, 0, -8), Vector3(-20, 0, -15), Vector3(-20, 0, -8), Vector3(-20, 0, -4), Vector3(-4, 0, -4), Vector3(-4, 0, 4), Vector3(16, 0, 4), Vector3(16, 0, 1), Vector3(16, 0, 4), Vector3(24, 0, 4), Vector3(24, 0, 10.2), Vector3(24, 0, 20)])
autoplay_boss_level = 13
```

Create `data/zones/mina_3.tres`:

```ini
[gd_resource type="Resource" script_class="ZoneData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/world/zone_data.gd" id="1_zone"]

[resource]
script = ExtResource("1_zone")
id = "mina_3"
display_name = "la mina"
number = 3
half_size = Vector2(30, 26)
ground_color = Color(0.24, 0.21, 0.19, 1)
has_grass = false
boss_id = "golem_piedra"
boss_pos = Vector3(20, 0, 17.5)
formations = [["golem_barro"], ["arana"], ["espectro"], ["arana"], ["arana", "espectro"], ["golem_barro", "arana"]]
encounter_grace = 6.0
encounter_chance = 0.025
music = "mine"
village_music = "village"
haze = Color(0.03, 0.03, 0.05, 1)
fog_density = 0.012
backdrop = "mina"
layout = PackedStringArray("###############", "#T.S..#..T...K#", "#.....#.####..#", "##.####.#..#..#", "#......T#..#.##", "#.##.####.##..#", "#.##...T.....##", "#T...#.######.#", "####.#.#.....T#", "#C...#...###D##", "#.#.T#####....#", "#.........#.T.#", "###############")
underground = true
ambient_color = Color(0.5, 0.48, 0.6, 1)
ambient_energy = 1.0
rock_color = Color(0.48, 0.42, 0.37, 1)
start_entry = "S"
stairs_up = "mina_2"
door_flag = "mina_puerta"
door_key = "llave_mina"
door_text = "La puerta está cerrada con llave."
floor_key = "llave_mina"
autoplay_route = Array[Vector3]([Vector3(-16, 0, -16), Vector3(-20, 0, -16), Vector3(-20, 0, -8), Vector3(0, 0, -8), Vector3(0, 0, -20), Vector3(23, 0, -20), Vector3(20, 0, -16), Vector3(20, 0, 0), Vector3(-4, 0, 0), Vector3(-4, 0, 12), Vector3(4, 0, 12), Vector3(4, 0, 8), Vector3(20, 0, 8), Vector3(20, 0, 10.8), Vector3(20, 0, 16), Vector3(20, 0, 8), Vector3(4, 0, 8), Vector3(4, 0, 12), Vector3(-4, 0, 12), Vector3(-4, 0, 0), Vector3(-12, 0, 0), Vector3(-12, 0, 12), Vector3(-23, 0, 12), Vector3(-12, 0, 12), Vector3(-12, 0, -8), Vector3(-20, 0, -8), Vector3(-20, 0, -16)])
autoplay_boss_level = 13
```

- [ ] **Step 8: Import and check**

```powershell
.\tools\godot.cmd --headless --path . --import
foreach ($s in "world/zone_data","world/dungeon_map","world/world","world/world_stage","battle/battle_stage","battle/battle_scene","game/game","game/chests","game/shop","game/inn","audio/music_library","title/title_screen") { .\tools\godot.cmd --headless --path . --check-only --script "res://scripts/$s.gd" }
```

Expected: no line with `ERROR` or `WARNING`.

- [ ] **Step 9: The three floors on autoplay**

```powershell
.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 24000 -- --autoplay --autoplay-zone=mina_1 > "$env:TEMP\mina.log" 2>&1
Select-String -Path "$env:TEMP\mina.log" -Pattern "ERROR|WARNING|Zona|Equipo|Encuentras|palanca|reja|Llave|Abres|sube al nivel|cierra el paso|Fragmento|Has vuelto"
Remove-Item "$env:APPDATA\Godot\app_userdata\rpg-turnos\save_autoplay.json" -ErrorAction SilentlyContinue
```

Expected, in this order (the battles in between vary): `Zona de inicio: mina_1 (Nv 9)`, `Zona: mina_1`, an `Oro 30 G · Equipo: Espada de hierro, Cota de malla, Escudo de acero · ...` line (250 − 220: the Herrero sold the Escudo de acero; the gold differs if a battle came first), `¡Encuentras 120 monedas de oro!`, `Zona: mina_2`, `¡Tiras de la palanca! Se oye cómo se abre una reja.`, `¡Encuentras 120 monedas de oro!`, `Zona: mina_3`, `¡Encuentras la Llave de la mina!`, `Abres la puerta con la Llave de la mina.`, and levels 10, 11, 12... On autoplay the hero never sleeps at the inn on the way down (it only stops there below half HP, and the route passes the inn at the start) and the floors wear it out, so `¡Has sido derrotado...!` / `Has vuelto al refugio de la mina.` followed by a new trip down (`Zona: mina_2`, `Zona: mina_3`) is expected anywhere after floor 1, also before the key (the lever, the key and the opened gate stay done across defeats); the Golem only comes out from Lv 13. No `ERROR`, at most the Jolt warning; never `La reja no se mueve` before the lever line on a first pass.

- [ ] **Step 10: The Golem de piedra on autoplay**

```powershell
foreach ($i in 1..3) {
    .\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 6000 -- --autoplay --autoplay-zone=mina_3 > "$env:TEMP\golem$i.log" 2>&1
    Select-String -Path "$env:TEMP\golem$i.log" -Pattern "ERROR|cierra el paso|acumula fuerza|golpe tremendo|se defiende|Fragmento|Encuentras|derrotado\.\.\."
}
Remove-Item "$env:APPDATA\Godot\app_userdata\rpg-turnos\save_autoplay.json" -ErrorAction SilentlyContinue
```

Expected in each run: `¡El Golem de piedra te cierra el paso!`, several `El Golem de piedra acumula fuerza...` each followed by `¡Héroe se defiende!` and `¡El Golem de piedra descarga un golpe tremendo!` (about 25-30 damage, half of a charged blow), then `¡Consigues un Fragmento del amuleto!` and `¡Encuentras un Éter!` (the chest after the boss room) in at least two of the three runs (all three won when this plan was run). No `ERROR`.

- [ ] **Step 11: Frames of the floors (temporary probe at the project root)**

Create `map_probe.gd`:

```gdscript
extends Node
## One-off look at the mine floors (Task 2). Not committed. Every 1 s (10 frames at
## --fixed-fps 10) it puts the player at the next SPOTS entry of the zone named by
## --probe-zone=<id> (mina_1 by default).

const SPOTS := {
	"mina_1": [Vector3(0, 0, 13), Vector3(0, 0, -18.6), Vector3(-12, 0, -16)],
	"mina_2": [Vector3(-20, 0, -13), Vector3(24, 0, 4.5), Vector3(24, 0, -16)],
	"mina_3": [Vector3(22, 0, -18), Vector3(20, 0, 8), Vector3(20, 0, 14)],
}


func _ready() -> void:
	var zone_id := "mina_1"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--probe-zone="):
			zone_id = arg.trim_prefix("--probe-zone=")
	var world: World = preload("res://scenes/world/world.tscn").instantiate()
	world.zone = ZoneData.by_id(zone_id)
	add_child(world)
	for spot: Vector3 in SPOTS[zone_id]:
		world.place_player(spot)
		await get_tree().create_timer(1.0).timeout
	get_tree().quit()
```

Create `map_probe.tscn`:

```ini
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://map_probe.gd" id="1"]

[node name="MapProbe" type="Node"]
script = ExtResource("1")
```

```powershell
foreach ($z in "mina_1","mina_2","mina_3") {
    $dir = "$env:TEMP\probe_$z"; New-Item -ItemType Directory -Force $dir | Out-Null
    .\tools\godot.cmd --path . res://map_probe.tscn --write-movie "$dir\f.png" --fixed-fps 10 --quit-after 40 -- --probe-zone=$z
}
```

Look at `f00000008.png`, `f00000018.png` and `f00000028.png` of each folder:
- `mina_1`: the refugio hall with the Herrero (green) and the Posadero (orange), torches on the walls and the "Al bosque" arch at the bottom; the hero right under the rock of row 2 with that block see-through (the hero's whole body visible); the stairs-down room with its dark pit and "Bajar".
- `mina_2`: the lever room (a stone base with a wooden handle, up); the corridor with the iron gate across it; the "Subir" steps.
- `mina_3`: the gold key turning over its pedestal; the gate seen from the north; the boss room.

Dark rock walls lit warm by the torches and the lantern around the hero, black beyond the grid. Then:

```powershell
foreach ($z in "mina_1","mina_2","mina_3") { Remove-Item -Recurse "$env:TEMP\probe_$z" }
Remove-Item map_probe.gd, map_probe.gd.uid, map_probe.tscn -ErrorAction SilentlyContinue
```

- [ ] **Step 12: The meadow and the forest still play**

```powershell
.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 3000 -- --autoplay
.\tools\godot.cmd --headless --path . res://scenes/world/world.tscn --fixed-fps 10 --quit-after 300 -- --autoplay
Remove-Item "$env:APPDATA\Godot\app_userdata\rpg-turnos\save_autoplay.json" -ErrorAction SilentlyContinue
```

Expected: the meadow plays as before; the map alone prints `Encuentro en (...)` lines; no `ERROR`, at most the Jolt warning.

- [ ] **Step 13: Commit**

```powershell
git add data scripts
git status --short
git commit -m "Build the mine's three floors from ASCII grids with stairs, lever, key, torches and see-through rock"
```

`git status --short` must not list any probe; `scripts/world/dungeon_map.gd.uid` is committed with its script.

---

### Task 3: The forest's way into the mine

**Files:**
- Modify: `data/zones/bosque.tres`

**Interfaces:**
- Consumes: `mina_1` and its entry `sur` (Task 2); the `bruja` world flag (phase 5a).
- Produces: forest exit `norte` → `mina_1` / `sur`; forest entry `norte`.

- [ ] **Step 1: The exit, the entry and the route point**

In `data/zones/bosque.tres`:

1. Replace:

```ini
"aldea": [Vector3(-10.4, 0, 10.5), 0.0],
"sur": [Vector3(0, 0, 35.5), 0.0]
```

with:

```ini
"aldea": [Vector3(-10.4, 0, 10.5), 0.0],
"norte": [Vector3(0, 0, -35.5), 180.0],
"sur": [Vector3(0, 0, 35.5), 0.0]
```

2. Replace:

```ini
"to": "pradera",
"yaw": 180.0
}]
npcs = [{
```

with:

```ini
"to": "pradera",
"yaw": 180.0
}, {
"entry": "sur",
"id": "norte",
"label": "A la mina",
"lock": "bruja",
"lock_text": "Una niebla espesa cierra el camino del norte.",
"pos": Vector3(0, 0, -38.6),
"to": "mina_1",
"yaw": 0.0
}]
npcs = [{
```

3. Replace:

```ini
backdrop = "bosque"
autoplay_route = Array[Vector3]([Vector3(6, 0, 30), Vector3(15.8, 0, 19.8), Vector3(8, 0, 8), Vector3(-3, 0, 10.5), Vector3(-8.9, 0, 3.9), Vector3(-13.4, 0, 4), Vector3(-11.6, 0, -1.8), Vector3(-18.8, 0, -22.2), Vector3(-6, 0, -26), Vector3(0, 0, -32.6), Vector3(8, 0, -24), Vector3(17, 0, -14), Vector3(14, 0, 0), Vector3(12, 0, 14), Vector3(2, 0, 26)])
autoplay_boss_level = 9
```

with:

```ini
backdrop = "bosque"
autoplay_route = Array[Vector3]([Vector3(6, 0, 30), Vector3(15.8, 0, 19.8), Vector3(8, 0, 8), Vector3(-3, 0, 10.5), Vector3(-8.9, 0, 3.9), Vector3(-13.4, 0, 4), Vector3(-11.6, 0, -1.8), Vector3(-18.8, 0, -22.2), Vector3(-6, 0, -26), Vector3(0, 0, -32.6), Vector3(0, 0, -38.6), Vector3(8, 0, -24), Vector3(17, 0, -14), Vector3(14, 0, 0), Vector3(12, 0, 14), Vector3(2, 0, 26)])
autoplay_boss_level = 9
```

- [ ] **Step 2: From the forest to the Golem on autoplay**

```powershell
.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 60000 -- --autoplay --autoplay-zone=bosque > "$env:TEMP\bosque.log" 2>&1
Select-String -Path "$env:TEMP\bosque.log" -Pattern "ERROR|WARNING|Zona:|niebla|Bruja del bosque te|Fragmento|palanca|Llave|Abres|Golem de piedra te|Has vuelto|sube al nivel"
Remove-Item "$env:APPDATA\Godot\app_userdata\rpg-turnos\save_autoplay.json" -ErrorAction SilentlyContinue
```

Expected: `Una niebla espesa cierra el camino del norte.` several times while the Bruja lives (the route now reaches the north exit), `¡La Bruja del bosque te cierra el paso!` at Lv 9, `¡Consigues un Fragmento del amuleto!`, then `Zona: mina_1` right after it (the route walks on through the opened exit), `Zona: mina_2`, the lever line, `Zona: mina_3`, the key, `Abres la puerta...`, and from Lv 13 `¡El Golem de piedra te cierra el paso!`. When this plan was run the autoplay hero (no inn on the way down, so the gold went to defeats and only the Escudo de acero was bought) lost to the Golem and to floor 3 a few times and beat it at Lv 17 inside the 60000 frames with the second `¡Consigues un Fragmento del amuleto!`; a run that ends before that is fine as long as it reached the Golem. No `ERROR`, at most the Jolt warning.

- [ ] **Step 3: Save round trip in the mine**

```powershell
.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 3000 -- --autoplay --autoplay-save --autoplay-zone=mina_3 > "$env:TEMP\save.log" 2>&1
Select-String -Path "$env:TEMP\save.log" -Pattern "Guardado|Cargado|ERROR"
Remove-Item "$env:APPDATA\Godot\app_userdata\rpg-turnos\save_autoplay.json" -ErrorAction SilentlyContinue
```

Expected: the `Guardado:` and `Cargado:` JSON lines are identical, with `"zone":"mina_3"`, `"town":"mina_1"` and the flags `bruja`, `llave_mina`, `mina_palanca`, `mina_puerta`, `rey_slime`.

- [ ] **Step 4: Frames of the refugio, a corridor and a mine battle**

```powershell
$dir = "$env:TEMP\mina_frames"; New-Item -ItemType Directory -Force $dir | Out-Null
.\tools\godot.cmd --path . --write-movie "$dir\f.png" --fixed-fps 10 --quit-after 160 -- --autoplay --autoplay-zone=mina_1
$dir2 = "$env:TEMP\golem_frames"; New-Item -ItemType Directory -Force $dir2 | Out-Null
.\tools\godot.cmd --path . --write-movie "$dir2\f.png" --fixed-fps 10 --quit-after 400 -- --autoplay --autoplay-zone=mina_3
Remove-Item "$env:APPDATA\Godot\app_userdata\rpg-turnos\save_autoplay.json" -ErrorAction SilentlyContinue
```

Look at `mina_frames\f00000003.png` (the refugio: figures, torches, the "Al bosque" arch), `f00000060.png` (the Herrero's window over the dark hall) and `f00000140.png` (a lit corridor with torches); in `golem_frames` find a battle frame (the cave: rock floor, a wall of rock blocks with two torches, boulders and stalagmites, the enemy lit in front). Then delete both folders.

- [ ] **Step 5: By hand**

With a save made in the forest after the Bruja (or by playing there), run `.\tools\godot.cmd --path .`, Continuar, and walk north into the mine. With the keys and with clicks: the blocks between the camera and the hero fade as you hug a south wall, the stairs take you up and down with a fade, the prompts "Enter o toca: tirar", "Enter o toca: coger" and "Enter o toca: abrir" show next to the lever, the key and a closed gate, and the gate of floor 2 says its text until the lever is pulled. Without such a save, skip this step: Steps 2-4 covered it on autoplay.

- [ ] **Step 6: Commit**

```powershell
git add data
git status --short
git commit -m "Open the forest's north exit to the mine once the witch is beaten"
```

---

### Task 4: Documentation, final checks and web export

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Update the docs**

In `CLAUDE.md`:

1. Replace:

```markdown
- `scenes/title/title.tscn` + `scripts/title/title_screen.gd` (`TitleScreen`) — main scene (`run/main_scene`). Loads the options (`SaveStore.load_options()`), owns the only `AudioDirector`, shows "Villaclaro" over the meadow (`WorldStage.build`) seen from a slowly drifting top-down camera, with Nueva partida / Continuar (disabled without a save) / Opciones (`OptionsPanel`); creates a `Game` with `setup(audio, options, save)` (empty save = new game) and frees it on `quit_to_title` (unpausing the tree). If the save file exists but can't be read, `_load_save()` passes a marker that `Game` rejects: it starts a new game with the notice "No se pudo cargar la partida. Empiezas de nuevo.". `--autoplay` skips the title and starts a new game; with `--autoplay-save` the first `quit_to_title` loads the save at once.
- `scenes/game/game.tscn` + `scripts/game/game.gd` (`Game`) — one play session, created by `TitleScreen` (run on its own it makes its own `AudioDirector` and default options). Owns a `GameState` and the `World` of the current zone: `_switch_zone(zone_id, entry_id)` frees the map and builds `ZoneData.by_id(zone_id)` ("" entry: the zone's start), connects its signals, reopens its chests, passes the world flags and places the boss. On `World.encounter_triggered(boss)` it fades to black, `World.set_active(false)`, instantiates a `BattleScene` with `setup(state.hero, enemies, state.inventory)`, `set_equipment(weapon, shield)`, `gold_lost = state.defeat_gold_loss()` and `zone` on top (`enemies` from `EncounterTable.pick(zone, player position, rng)`, or `[EnemyLibrary.data(zone.boss_id)]`), awaits `finished(outcome)` (`BattleEngine.State`), frees it and turns the map back on (victory: `state.gold += engine.gold_won` and `quest.on_victory(id)` for every enemy; a boss also calls `state.on_boss_defeated()` (world flag + key item) and shows `BOSS_NOTICES` ("¡Villaclaro está a salvo! La niebla del norte se disipa...") or "¡Consigues un Fragmento del amuleto!"; fled: nothing; defeat: loses half the gold, `heal_full()` and goes to the town entry of `state.town_zone` ("Has vuelto a <village>.")). On `World.exit_requested(zone, entry)` it fades, switches zone and autosaves silently; the pause menu's `travel_requested` (Ala de viaje) does the same to the last village ("Vuelas a <village>."; the map is frozen during the flight so nothing triggers); `World.village_changed(true)` makes the zone the last village visited. On `World.shop_requested(shop_id)` it freezes the map and awaits `ShopWindow.run(shop_id)` (on autoplay only when `Shop.autoplay_picks()` is not empty), then autosaves if anything changed; on `World.inn_requested(inn_id)` it asks `ShopWindow.ask()` and on Sí calls `Inn.stay()` (fade to black, `INN_NIGHT_TIME` 0.8 s, full HP and MP, autosave; on autoplay only below `AUTOPLAY_INN_RATIO` 0.5 of max HP and with the price); on `World.chest_opened(id)` it calls `Chests.open(state, id)`, opens the lid (`World.set_chest_open()`), shows what was found and saves without a notice; on `World.npc_requested(i)` it plays `World.npc_lines(i)`. `_refresh_status()` also shows the weapon and shield on the map hero (`World.set_hero_equipment()`) and, on autoplay, prints `Oro N G · Equipo: ... · ATK n DEF n` whenever it changes. `_update_boss()` shows the zone's boss until it is beaten (the Rey Slime only while `quest.boss_available()`; on autoplay only from the zone's `autoplay_boss_level`). On `World.talk_requested` it takes the lines and potions from `quest.talk()`, heals, and plays them with `World.show_dialogue()`, then shows the boss if `quest.boss_available()`. The map stays while battles come and go, so position, camera and encounter grace survive them. Music: the zone's `music` / `village_music` (`World.village_changed`), battle or boss (the battle plays victory / defeat). Autosaves (`SaveData.from_state()` → `SaveStore.save_game()`) after each talk and each won battle ("Partida guardada.", except after a boss, which shows its notice instead) and silently after a defeat (so the gold lost sticks), after a chest and after each change of zone, never in battle; a save is loaded with `SaveData.apply()` (its zone) and `World.place_player()`; counts `play_time` (stops while paused). Owns the `PauseMenu` (`available` only on the map with nothing else going on) and answers its `save_requested` / `title_requested` (the latter sets a `_leaving` guard, marks the game busy, hides the menu and ignores input, so the frozen map can't walk or roll an encounter during the fade) / `travel_requested`; emits `quit_to_title`. `--autoplay --autoplay-save` prints `Guardado: <json>` / `Cargado: <json>`; `--autoplay --autoplay-menu` tours the pause menu 1 s into the map; `--autoplay --autoplay-zone=<id>` starts a new game in that zone with `AUTOPLAY_ZONES` (bosque: Lv 5, 150 G, the zone 1 gear, the Rey Slime beaten).
- `scripts/game/game_state.gd` (`GameState`, `RefCounted`) — session state kept in memory: the hero `Combatant` (a duplicate of `data/hero.tres` that lives the whole session; battles change its HP, MP, EXP and level in place), `inventory: Inventory` (starts with 3 potions), `quest: Quest`, `gold` (`START_GOLD` 50), `loadout: Loadout`, `bag_equipment` (Equipment ids carried but not worn), `opened_chests` (Chests ids), `world_flags` (flag → true; a beaten boss sets its enemy id, which opens the exits locked by it), `key_items` (`Inventory.KEY_ITEMS` ids), `zone_id` (the map the hero is on) and `town_zone` (last village visited; "pradera" at first), `heal_full()` (HP and MP), `use_item(id)` (outside battle, `Inventory.use()`), `refresh_equipment()` (copies the loadout bonuses into `hero.equip_attack` / `equip_defense`), `equip(id)` (from the bag; what it replaces goes to the bag), `unequip(slot)`, `on_boss_defeated(boss)` (flag + key item, returns the item given), `has_flag(flag)` ("" is always set), `defeat_gold_loss()` (half the gold, rounded down). The hero gets its own `skills` array, so learning a spell never touches `hero.tres`.
- `scripts/game/equipment.gd` (`Equipment`, `RefCounted`) — the `EQUIPMENT` catalog (id → name, article, slot `WEAPON` / `ARMOR` / `SHIELD`, bonus (ATK for weapons, DEF for the rest), price, zone, mesh): Palo +2 and Ropa +2 (zone 0, the starting gear, worth nothing), zone 1 Espada de cobre +6 · 40 G, Cota de cuero +5 · 30 G, Escudo de madera +3 · 25 G, and zones 2-4 already listed for their shops; `display_name()`, `article()`, `pronoun()`, `slot()`, `bonus()`, `price()`, `mesh()` (a `Knight.glb` handslot mesh, `STICK_MESH` or ""), `stat_name()`, `of_zone()`, `SLOTS`, `SLOT_NAMES`.
- `scripts/game/loadout.gd` (`Loadout`, `RefCounted`) — what the hero wears, slot → id (Palo, Ropa, no shield at first): `worn(slot)`, `is_worn(id)`, `equip(id)` (returns what it took off), `unequip(slot)`, `attack_bonus()`, `defense_bonus()`, `to_dict()`, `set_slots()`.
- `scripts/game/shop.gd` (`Shop`, `RefCounted`) — pure shop rules: `SHOPS` (Villaclaro: the zone 1 gear, Poción and Antídoto; Bosque: the zone 2 gear, Poción, Antídoto, Éter and Ala de viaje), `stock()`, `price()`, `sell_price()` (half, rounded down), `buy_problem()` / `can_buy()` / `buy()`, `sell_list()` / `sell_count()` / `sell_problem()` ("Lo llevas puesto", "No vale nada") / `sell()` (each returns `{ok, text}`), `compare(state, id)` (`{stat, worn, bonus, diff}` against the piece worn in that slot), `autoplay_picks()` (upgrades first, then potions up to 3).
- `scripts/game/inn.gd` (`Inn`, `RefCounted`) — inn rules: `INNS` (Villaclaro: Posadero, 5 G; Bosque: Posadera, 15 G; the mine and castle will have 30 / 50 G), `keeper()`, `price()`, `offer()`, `stay(state, id)` → `{ok, text}` (pays and heals).
- `scripts/game/chests.gd` (`Chests`, `RefCounted`) — the chests of every zone (`CHESTS`: zone, position, yaw and contents; the meadow's 25 G, Escudo de madera, 40 G and Éter, the first two next to its autoplay route; the forest's 50 G, 50 G and an Ala de viaje in its three glades, next to its route); `of_zone(zone_id)`; `open(state, id)` → `{opened, text}` (equipment goes on at once if its slot is empty, else into the bag).
- `scripts/game/quest.gd` (`Quest`, `RefCounted`) — the village quest: stages `OFFER → HUNT → REPORT → BOSS → DONE`; `on_victory(enemy_id)` (called for every enemy of a won battle) counts slimes during `HUNT` and finishes on the boss; `talk()` returns the old woman's lines and the potions to give (2 when reporting) and moves the stage on; `boss_available()`, `status_text()`.
- `scripts/game/inventory.gd` (`Inventory`, `RefCounted`) — items as `id → count`: `count()`, `add()`, `take()`, `to_dict()`, `set_items()`. `ITEMS` table (name, article, effect `hp` / `mp` / `cure` / `travel`, value, price, usable in `battle` / `field`) in `IDS` order: `POTION` (30 PV, 8 G), `ETHER` (15 PM, 30 G), `ANTIDOTE` (cures poison, 10 G, battle only), `WING` (Ala de viaje, 25 G, outside battle: `use()` only takes it, the pause menu asks `Game` for the trip); `Shop` sells at `price` and buys back at half. `KEY_ITEMS` (id → name: `fragmento_bosque` "Fragmento del amuleto"), kept in `GameState.key_items`. `problem(id, combatant, in_battle)` says why it can't be used now ("" if it can: "PV al máximo", "Solo en combate", ...); `use(id, combatant, in_battle)` → `{used, effect, amount, status, reason}`, shared by `BattleEngine` and the pause menu; `display_name()`, `article()`.
- `scripts/game/leveling.gd` (`Leveling`, `RefCounted`) — fixed `EXP_TABLE` up to `MAX_LEVEL` 20 (12, 35, 62, 96, 180, ... 3600) and fixed `GAINS` per level (PV +6, PM +3, ATK +2, DEF +1, VEL +1; current HP/MP rise with their max, no full heal); `apply(hero)` returns `LEVEL_UP` events, each followed by a `LEARN` event when the hero's `learn` table teaches a spell at that level; `sync_skills(hero)` (after loading), `exp_for_next(level)`.
```

with:

```markdown
- `scenes/title/title.tscn` + `scripts/title/title_screen.gd` (`TitleScreen`) — main scene (`run/main_scene`). Loads the options (`SaveStore.load_options()`), owns the only `AudioDirector`, shows "Villaclaro" over the meadow (`WorldStage.build`) seen from a slowly drifting top-down camera, with Nueva partida / Continuar (disabled without a save) / Opciones (`OptionsPanel`); creates a `Game` with `setup(audio, options, save)` (empty save = new game) and frees it on `quit_to_title` (unpausing the tree). If the save file exists but can't be read, `_load_save()` passes a marker that `Game` rejects: it starts a new game with the notice "No se pudo cargar la partida. Empiezas de nuevo.". `--autoplay` skips the title and starts a new game; with `--autoplay-save` the first `quit_to_title` loads the save at once.
- `scenes/game/game.tscn` + `scripts/game/game.gd` (`Game`) — one play session, created by `TitleScreen` (run on its own it makes its own `AudioDirector` and default options). Owns a `GameState` and the `World` of the current zone: `_switch_zone(zone_id, entry_id)` frees the map and builds `ZoneData.by_id(zone_id)` ("" entry: the zone's start), connects its signals, reopens its chests, passes the world flags and places the boss. On `World.encounter_triggered(boss)` it fades to black, `World.set_active(false)`, instantiates a `BattleScene` with `setup(state.hero, enemies, state.inventory)`, `set_equipment(weapon, shield)`, `gold_lost = state.defeat_gold_loss()` and `zone` on top (`enemies` from `EncounterTable.pick(zone, player position, rng)`, or `[EnemyLibrary.data(zone.boss_id)]`), awaits `finished(outcome)` (`BattleEngine.State`), frees it and turns the map back on (victory: `state.gold += engine.gold_won` and `quest.on_victory(id)` for every enemy; a boss also calls `state.on_boss_defeated()` (world flag + key item) and shows `BOSS_NOTICES` ("¡Villaclaro está a salvo! La niebla del norte se disipa...") or "¡Consigues un Fragmento del amuleto!"; fled: nothing; defeat: loses half the gold, `heal_full()` and goes to the town entry of `state.town_zone` ("Has vuelto a Villaclaro." / "... al refugio de la mina.", `_to_place()`)). On `World.exit_requested(zone, entry)` (an arch or the stairs of a mine floor) it fades, switches zone and autosaves silently; the pause menu's `travel_requested` (Ala de viaje) does the same to the last village ("Vuelas a <village>."; the map is frozen during the flight so nothing triggers). `_switch_zone()` leaves the new map frozen (`World.freeze(true)`) and every path (exit, defeat, Ala, a battle's return) unfreezes it only after the fade-in, so nothing on it can fire while `Game` is still busy. On a mine floor `World.lever_pulled` sets `zone.lever_flag` ("¡Tiras de la palanca! Se oye cómo se abre una reja."), `World.key_taken` adds `zone.floor_key` to the key items and sets it as a flag ("¡Encuentras la Llave de la mina!"), `World.door_used` opens the gates with `zone.door_key` (used up: "Abres la puerta con la Llave de la mina.") or shows `zone.door_text`; each sets the flags on the map and autosaves silently; `World.village_changed(true)` makes the zone the last village visited. On `World.shop_requested(shop_id)` it freezes the map and awaits `ShopWindow.run(shop_id)` (on autoplay only when `Shop.autoplay_picks()` is not empty), then autosaves if anything changed; on `World.inn_requested(inn_id)` it asks `ShopWindow.ask()` and on Sí calls `Inn.stay()` (fade to black, `INN_NIGHT_TIME` 0.8 s, full HP and MP, autosave; on autoplay only below `AUTOPLAY_INN_RATIO` 0.5 of max HP and with the price); on `World.chest_opened(id)` it calls `Chests.open(state, id)`, opens the lid (`World.set_chest_open()`), shows what was found and saves without a notice; on `World.npc_requested(i)` it plays `World.npc_lines(i)`. `_refresh_status()` also shows the weapon and shield on the map hero (`World.set_hero_equipment()`) and, on autoplay, prints `Oro N G · Equipo: ... · ATK n DEF n` whenever it changes. `_update_boss()` shows the zone's boss until it is beaten (the Rey Slime only while `quest.boss_available()`; on autoplay only from the zone's `autoplay_boss_level`). On `World.talk_requested` it takes the lines and potions from `quest.talk()`, heals, and plays them with `World.show_dialogue()`, then shows the boss if `quest.boss_available()`. The map stays while battles come and go, so position, camera and encounter grace survive them. Music: the zone's `music` / `village_music` (`World.village_changed`), battle or boss (the battle plays victory / defeat). Autosaves (`SaveData.from_state()` → `SaveStore.save_game()`) after each talk and each won battle ("Partida guardada.", except after a boss, which shows its notice instead) and silently after a defeat (so the gold lost sticks), after a chest and after each change of zone, never in battle; a save is loaded with `SaveData.apply()` (its zone) and `World.place_player()`; counts `play_time` (stops while paused). Owns the `PauseMenu` (`available` only on the map with nothing else going on) and answers its `save_requested` / `title_requested` (the latter sets a `_leaving` guard, marks the game busy, hides the menu and ignores input, so the frozen map can't walk or roll an encounter during the fade) / `travel_requested`; emits `quit_to_title`. `--autoplay --autoplay-save` prints `Guardado: <json>` / `Cargado: <json>`; `--autoplay --autoplay-menu` tours the pause menu 1 s into the map; `--autoplay --autoplay-zone=<id>` starts a new game in that zone with `AUTOPLAY_ZONES` (bosque: Lv 5, 150 G, the zone 1 gear, the Rey Slime beaten; mina_1: Lv 9, 250 G, the zone 2 gear, the Bruja beaten, the first fragment; mina_3: Lv 13, 100 G, the zone 3 gear, both gates open, the refugio as last village).
- `scripts/game/game_state.gd` (`GameState`, `RefCounted`) — session state kept in memory: the hero `Combatant` (a duplicate of `data/hero.tres` that lives the whole session; battles change its HP, MP, EXP and level in place), `inventory: Inventory` (starts with 3 potions), `quest: Quest`, `gold` (`START_GOLD` 50), `loadout: Loadout`, `bag_equipment` (Equipment ids carried but not worn), `opened_chests` (Chests ids), `world_flags` (flag → true; a beaten boss sets its enemy id, which opens the exits locked by it), `key_items` (`Inventory.KEY_ITEMS` ids), `zone_id` (the map the hero is on) and `town_zone` (last village visited; "pradera" at first), `heal_full()` (HP and MP), `use_item(id)` (outside battle, `Inventory.use()`), `refresh_equipment()` (copies the loadout bonuses into `hero.equip_attack` / `equip_defense`), `equip(id)` (from the bag; what it replaces goes to the bag), `unequip(slot)`, `on_boss_defeated(boss)` (flag + key item, returns the item given), `has_flag(flag)` ("" is always set), `defeat_gold_loss()` (half the gold, rounded down). The hero gets its own `skills` array, so learning a spell never touches `hero.tres`.
- `scripts/game/equipment.gd` (`Equipment`, `RefCounted`) — the `EQUIPMENT` catalog (id → name, article, slot `WEAPON` / `ARMOR` / `SHIELD`, bonus (ATK for weapons, DEF for the rest), price, zone, mesh): Palo +2 and Ropa +2 (zone 0, the starting gear, worth nothing), zone 1 Espada de cobre +6 · 40 G, Cota de cuero +5 · 30 G, Escudo de madera +3 · 25 G, and zones 2-4 already listed for their shops; `display_name()`, `article()`, `pronoun()`, `slot()`, `bonus()`, `price()`, `mesh()` (a `Knight.glb` handslot mesh, `STICK_MESH` or ""), `stat_name()`, `of_zone()`, `SLOTS`, `SLOT_NAMES`.
- `scripts/game/loadout.gd` (`Loadout`, `RefCounted`) — what the hero wears, slot → id (Palo, Ropa, no shield at first): `worn(slot)`, `is_worn(id)`, `equip(id)` (returns what it took off), `unequip(slot)`, `attack_bonus()`, `defense_bonus()`, `to_dict()`, `set_slots()`.
- `scripts/game/shop.gd` (`Shop`, `RefCounted`) — pure shop rules: `SHOPS` (Villaclaro: the zone 1 gear, Poción and Antídoto; Bosque: the zone 2 gear, Poción, Antídoto, Éter and Ala de viaje; Mina: the Herrero, the zone 3 steel gear and the same items), `stock()`, `price()`, `sell_price()` (half, rounded down), `buy_problem()` / `can_buy()` / `buy()`, `sell_list()` / `sell_count()` / `sell_problem()` ("Lo llevas puesto", "No vale nada") / `sell()` (each returns `{ok, text}`), `compare(state, id)` (`{stat, worn, bonus, diff}` against the piece worn in that slot), `autoplay_picks()` (upgrades first, then potions up to 3).
- `scripts/game/inn.gd` (`Inn`, `RefCounted`) — inn rules: `INNS` (Villaclaro: Posadero, 5 G; Bosque: Posadera, 15 G; Mina: Posadero, 30 G; the castle will have 50 G), `keeper()`, `price()`, `offer()`, `stay(state, id)` → `{ok, text}` (pays and heals).
- `scripts/game/chests.gd` (`Chests`, `RefCounted`) — the chests of every zone (`CHESTS`: zone, position, yaw and contents; the meadow's 25 G, Escudo de madera, 40 G and Éter, the first two next to its autoplay route; the forest's 50 G, 50 G and an Ala de viaje in its three glades, next to its route; the mine's 120 G, 120 G and an Éter on the C cell of each floor); `of_zone(zone_id)`; `open(state, id)` → `{opened, text}` (equipment goes on at once if its slot is empty, else into the bag).
- `scripts/game/quest.gd` (`Quest`, `RefCounted`) — the village quest: stages `OFFER → HUNT → REPORT → BOSS → DONE`; `on_victory(enemy_id)` (called for every enemy of a won battle) counts slimes during `HUNT` and finishes on the boss; `talk()` returns the old woman's lines and the potions to give (2 when reporting) and moves the stage on; `boss_available()`, `status_text()`.
- `scripts/game/inventory.gd` (`Inventory`, `RefCounted`) — items as `id → count`: `count()`, `add()`, `take()`, `to_dict()`, `set_items()`. `ITEMS` table (name, article, effect `hp` / `mp` / `cure` / `travel`, value, price, usable in `battle` / `field`) in `IDS` order: `POTION` (30 PV, 8 G), `ETHER` (15 PM, 30 G), `ANTIDOTE` (cures poison, 10 G, battle only), `WING` (Ala de viaje, 25 G, outside battle: `use()` only takes it, the pause menu asks `Game` for the trip); `Shop` sells at `price` and buys back at half. `KEY_ITEMS` (id → name: `fragmento_bosque` and `fragmento_mina` "Fragmento del amuleto", `llave_mina` "Llave de la mina"), kept in `GameState.key_items`. `problem(id, combatant, in_battle)` says why it can't be used now ("" if it can: "PV al máximo", "Solo en combate", ...); `use(id, combatant, in_battle)` → `{used, effect, amount, status, reason}`, shared by `BattleEngine` and the pause menu; `display_name()`, `article()`.
- `scripts/game/leveling.gd` (`Leveling`, `RefCounted`) — fixed `EXP_TABLE` up to `MAX_LEVEL` 20 (12, 35, 62, 96, 180, ... 3600) and fixed `GAINS` per level (PV +6, PM +3, ATK +2, DEF +1, VEL +1; current HP/MP rise with their max, no full heal); `apply(hero)` returns `LEVEL_UP` events, each followed by a `LEARN` event when the hero's `learn` table teaches a spell at that level; `sync_skills(hero)` (after loading), `exp_for_next(level)`.
```

2. Replace:

```markdown
- `scripts/game/save_store.gd` (`SaveStore`, `RefCounted`) — JSON files: `user://save.json` (`user://save_autoplay.json` on `--autoplay` runs) and `user://options.json`; `has_save()`, `save_game(data)`, `load_game()` (empty if missing or broken), `save_options(options)`, `load_options()`. On desktop `user://` is `%APPDATA%\Godot\app_userdata\rpg-turnos\`; on the web it is IndexedDB.
- `scenes/world/world.tscn` + `scripts/world/world.gd` (`World`) — one map, built from `zone: ZoneData` (set before `add_child`; the meadow if none): `WorldStage.build(self, zone)`, the zone's figures (`zone.npcs`: `BattleActor` looks by name on cylinder colliders: the old woman `quest`, merchants `shop`, innkeepers `inn`, villagers `npc`), its boss (`EnemyLibrary.look()`), its chests (`build_chest()`: wooden box, gold band and lock, lid on a hinge; `set_chest_open(id, open, instant)`), its exits (a wooden arch turned by the exit's yaw, a sign with its label that always faces the camera, and a bank of fog while its `lock` flag is not set), `Player` (its `route` is the zone's autoplay route), `FollowCamera`, status window (name and level, PV, PM, EXP / next level, potions, "Oro N G", quest line), click or tap on the ground (held and dragged too) walks there with a ring marker, a prompt for the nearest thing in reach ("Enter o toca: hablar" within 2.5 m of the old woman, an innkeeper or a villager, "... comprar" of a merchant, "... abrir" within 1.8 m of a closed chest; a click or tap on one walks there and uses it on arrival), `DialogueBox`, encounters through `EncounterMeter` with the zone's pace (only off the path and safe discs). Emits `talk_requested`, `npc_requested(index)`, `shop_requested(shop_id)`, `inn_requested(inn_id)`, `chest_opened(chest_id)`, `village_changed(inside)` (within `zone.village_radius` of `zone.village_pos`), `exit_requested(zone_id, entry_id)` (walking within 1.2 m of an open exit; a closed one shows its `lock_text` once per approach; exits only count after stepping 2 m away from them since arriving) and `encounter_triggered(boss)` (random encounter, or walking within 2.5 m of the boss while `set_boss_present(true)`), and freezes the player until `set_active(true)`; `place_at_entry(entry_id)`, `place_player(pos, yaw_deg)`, `player_position()`, `in_village()`, `set_world_flags(flags)`, `npc_lines(index)` (`lines_after` once its `after_flag` is set), `set_audio(audio)` (footstep every 1.6 m, encounter and dialogue sounds), `refresh_status(hero, potions, gold, quest_text)`, `set_hero_equipment(weapon, shield)`, `show_notice(text)` (printed on autoplay), `await show_dialogue(speaker, lines)`, `await freeze(on)` (no walking or prompts while a window is open). On autoplay it uses whatever comes in reach once per approach (each villager once per visit). Run on its own it prints each encounter, shop, inn, chest and exit and answers talks with one line.
- `scripts/ui/dialogue_box.gd` (`DialogueBox`, `Control`) — bottom dialogue window with speaker name; `await say(speaker, lines)` advances on Enter / Space / click (autoplay: every 0.8 s, printed); `set_audio()` plays the dialogue sound when it opens.
- `scripts/world/world_stage.gd` (`WorldStage`) — static builder of any zone from its `ZoneData` (`build(root, zone)` returns the grass material, which `World` pushes away from the player each frame, or null without grass): the zone's sky and sun (`BattleStage.build_environment(root, zone)`), ground, dirt path and safe discs, buildings from `MODELS` (KayKit `building_*` at `BUILDING_SCALE` 3.5 with box colliders fitted to their meshes; `BUILDING_RADIUS` footprints), KayKit rocks with box colliders, trees scattered with the zone's seed (denser toward the walls, clumps within `tree_clump_inset` of them, kept off the path, glades, exits, autoplay route, rocks, buildings and chests, cylinder colliders inside the walls) and bushes (no collider), the trees and bushes each drawn as a `MultiMesh`; invisible walls at `half_size`, hills outside; `is_on_path(zone, pos, margin := 0.0)` (path and safe discs are safe), `is_grass_free(pos, zone)`, `add_cylinder_shape()`.
- `scripts/world/zone_data.gd` (`ZoneData`, `Resource`) — everything a map is built from, in `data/zones/<id>.tres` (`IDS`: `pradera`, `bosque`): field `half_size` and `outer_margin`, ground and grass colors, `has_grass`, hills, `path_points`, `safe_discs`, the village (`village_name`, `village_pos`, `village_radius`), `buildings`, `rocks`, tree and bush parameters, `glades`, `entries` (id → [pos, yaw]), `start_entry`, `town_entry`, `exits` (id, pos, yaw, to, entry, label, lock, lock_text), `npcs`, `boss_id` / `boss_pos`, `formations` / `start_formations` / `start_pos` / `start_radius`, `encounter_grace` / `encounter_chance`, `music` / `village_music`, sky, haze, fog and sun, `backdrop`, `autoplay_route`, `autoplay_boss_level`; `by_id(id)`, `entry(id)`, `exit_by_id(id)`. The meadow (`pradera.tres`) keeps the positions of phase 4 and gains the north exit to the forest (closed by fog until the Rey Slime is beaten); the forest (`bosque.tres`, 60 × 80 m) has the village in a clearing (houses, shop, inn, the Leñadora), three glades with chests, the Bruja del bosque's clearing to the north and the exit back south.
- `scenes/world/player.tscn` + `scripts/world/player.gd` (`Player`, `CharacterBody3D`) — WASD / arrows in screen axes (up = −Z), or `move_to(point)` (click / tap; keys cancel it, gives up when stuck; `move_target`), 5 m/s, smooth turn, walk / idle animation through `BattleActor.set_walking()`; model is a `BattleActor` (`HERO`; `set_equipment(weapon, shield)`); `last_step_m` feeds the encounter meter; `place(pos, yaw)` (autoplay goes on from the nearest route point). `--autoplay` walks `route` (the zone's `autoplay_route`) in a loop: in the meadow through the village past the old woman, the merchant, the boss spot, the north exit and the innkeeper, and past two chests; in the forest through its glades, the village and the witch's clearing.
```

with:

```markdown
- `scripts/game/save_store.gd` (`SaveStore`, `RefCounted`) — JSON files: `user://save.json` (`user://save_autoplay.json` on `--autoplay` runs) and `user://options.json`; `has_save()`, `save_game(data)`, `load_game()` (empty if missing or broken), `save_options(options)`, `load_options()`. On desktop `user://` is `%APPDATA%\Godot\app_userdata\rpg-turnos\`; on the web it is IndexedDB.
- `scenes/world/world.tscn` + `scripts/world/world.gd` (`World`) — one map, built from `zone: ZoneData` (set before `add_child`; the meadow if none): `WorldStage.build(self, zone)`, the zone's figures (`zone.npcs`: `BattleActor` looks by name on cylinder colliders: the old woman `quest`, merchants `shop`, innkeepers `inn`, villagers `npc`), its boss (`EnemyLibrary.look()`), its chests (`build_chest()`: wooden box, gold band and lock, lid on a hinge; `set_chest_open(id, open, instant)`), its exits (a wooden arch turned by the exit's yaw, a sign with its label that always faces the camera, and a bank of fog while its `lock` flag is not set), `Player` (its `route` is the zone's autoplay route), `FollowCamera`, status window (name and level, PV, PM, EXP / next level, potions, "Oro N G", quest line), click or tap on the ground (held and dragged too) walks there with a ring marker, a prompt for the nearest thing in reach ("Enter o toca: hablar" within 2.5 m of the old woman, an innkeeper or a villager, "... comprar" of a merchant, "... abrir" within 1.8 m of a closed chest; a click or tap on one walks there and uses it on arrival), `DialogueBox`, encounters through `EncounterMeter` with the zone's pace (only off the path and safe discs). A mine floor (`zone.is_dungeon()`) adds a `DungeonMap`, the hero carries a lantern (`OmniLight3D`, energy 2, range 10 m) underground, its stairs are exits (`zone.all_exits()`), and the lever, the key and the closed gates are uses within 2.2 m ("Enter o toca: tirar" / "coger" / "abrir"; `pull_lever()`). Emits `talk_requested`, `npc_requested(index)`, `shop_requested(shop_id)`, `inn_requested(inn_id)`, `chest_opened(chest_id)`, `lever_pulled`, `key_taken`, `door_used`, `village_changed(inside)` (within `zone.village_radius` of `zone.village_pos`), `exit_requested(zone_id, entry_id)` (walking within 1.2 m of an open exit; a closed one shows its `lock_text` once per approach; exits only count after stepping 2 m away from them since arriving) and `encounter_triggered(boss)` (random encounter, or walking within 2.5 m of the boss while `set_boss_present(true)`), and freezes the player until `set_active(true)`; `place_at_entry(entry_id)`, `place_player(pos, yaw_deg)`, `player_position()`, `in_village()`, `set_world_flags(flags)`, `npc_lines(index)` (`lines_after` once its `after_flag` is set), `set_audio(audio)` (footstep every 1.6 m, encounter and dialogue sounds), `refresh_status(hero, potions, gold, quest_text)`, `set_hero_equipment(weapon, shield)`, `show_notice(text)` (printed on autoplay), `await show_dialogue(speaker, lines)`, `await freeze(on)` (no walking or prompts while a window is open). On autoplay it uses whatever comes in reach once per approach (each villager once per visit). Run on its own it prints each encounter, shop, inn, chest and exit and answers talks with one line.
- `scripts/ui/dialogue_box.gd` (`DialogueBox`, `Control`) — bottom dialogue window with speaker name; `await say(speaker, lines)` advances on Enter / Space / click (autoplay: every 0.8 s, printed); `set_audio()` plays the dialogue sound when it opens.
- `scripts/world/dungeon_map.gd` (`DungeonMap`, `Node3D`) — the cells of a mine floor (`zone.layout`, set `zone` before `add_child`): floor in 3 × 3-cell chunks, a 4 × 3 × 4 m rock block with a box collider for every rock cell next to the floor (buried ones in one `MultiMesh`, no collider; three shades), torches on the `T` cells' walls (a flame and a flickering `OmniLight3D`, energy 2.5, range 8 m, no shadows), stairs (`S` steps up, `B` a dark pit, with a "Subir" / "Bajar" sign), iron gates on `D` (box collider while closed), the lever on `L` and a turning gold key on `K`; `set_flags(flags)` (gates open with `zone.door_flag`, lever down with `zone.lever_flag`, key hidden once taken), `pull_lever()`, `see_through(camera_pos, hero_pos)` (the blocks of the two rows south of the hero whose box, grown 0.6 m, cuts the camera's lines to the hero's feet or chest get a shared see-through material, alpha 0.3).
- `scripts/world/world_stage.gd` (`WorldStage`) — static builder of any zone from its `ZoneData` (`build(root, zone)` returns the grass material, which `World` pushes away from the player each frame, or null without grass; a mine floor only gets its environment, its cells are `World`'s `DungeonMap`): the zone's sky and sun (`BattleStage.build_environment(root, zone)`), ground, dirt path and safe discs, buildings from `MODELS` (KayKit `building_*` at `BUILDING_SCALE` 3.5 with box colliders fitted to their meshes; `BUILDING_RADIUS` footprints), KayKit rocks with box colliders, trees scattered with the zone's seed (denser toward the walls, clumps within `tree_clump_inset` of them, kept off the path, glades, exits, autoplay route, rocks, buildings and chests, cylinder colliders inside the walls) and bushes (no collider), the trees and bushes each drawn as a `MultiMesh`; invisible walls at `half_size`, hills outside; `is_on_path(zone, pos, margin := 0.0)` (path, safe discs and the stair rooms of a mine floor are safe), `is_grass_free(pos, zone)`, `add_cylinder_shape()`.
- `scripts/world/zone_data.gd` (`ZoneData`, `Resource`) — everything a map is built from, in `data/zones/<id>.tres` (`IDS`: `pradera`, `bosque`, `mina_1`, `mina_2`, `mina_3`): field `half_size` and `outer_margin`, ground and grass colors, `has_grass`, hills, `path_points`, `safe_discs`, the village (`village_name`, `village_pos`, `village_radius`), `buildings`, `rocks`, tree and bush parameters, `glades`, `entries` (id → [pos, yaw]), `start_entry`, `town_entry`, `exits` (id, pos, yaw, to, entry, label, lock, lock_text), `npcs`, `boss_id` / `boss_pos`, `formations` / `start_formations` / `start_pos` / `start_radius`, `encounter_grace` / `encounter_chance`, `music` / `village_music`, sky, haze, fog and sun, `backdrop`, `autoplay_route`, `autoplay_boss_level`, and for a mine floor `layout` (rows of `CELL` 4 m cells, north first: `#` rock, `.` floor, `S` stairs up, `B` stairs down, `C` chest, `L` lever, `D` locked gate, `K` key, `T` floor with a torch), `underground` (black background, `ambient_color` / `ambient_energy`, no sun), `rock_color`, `stairs_up` / `stairs_down` (zone ids), `lever_flag`, `door_flag` / `door_key` / `door_text`, `floor_key`; `by_id(id)`, `entry(id)` (`"S"` / `"B"`: the floor cell next to those stairs), `exit_by_id(id)`, `all_exits()` (plus one exit per stair cell), `is_dungeon()`, `grid_size()`, `cell_center(cell)`, `cell_at(pos)`, `cell_char(cell)`, `find_cells(ch)`, `near_stairs(pos)` (within 6 m). The meadow (`pradera.tres`) keeps the positions of phase 4 and gains the north exit to the forest (closed by fog until the Rey Slime is beaten); the forest (`bosque.tres`, 60 × 80 m) has the village in a clearing (houses, shop, inn, the Leñadora), three glades with chests, the Bruja del bosque's clearing to the north with the exit to the mine behind it (closed by fog until the Bruja is beaten) and the exit back south. The mine (`mina_1.tres`, `mina_2.tres`, `mina_3.tres`, 15 × 13 cells each, `music` "mine", `backdrop` "mina", encounters every 6 m + 2.5 % per metre): floor 1 has the refugio (Herrero, Posadero, Minera; the arch back to the forest) and the stairs down; floor 2 the lever that opens the gate in front of its stairs down; floor 3 the key that opens the Golem de piedra's room.
- `scenes/world/player.tscn` + `scripts/world/player.gd` (`Player`, `CharacterBody3D`) — WASD / arrows in screen axes (up = −Z), or `move_to(point)` (click / tap; keys cancel it, gives up when stuck; `move_target`), 5 m/s, smooth turn, walk / idle animation through `BattleActor.set_walking()`; model is a `BattleActor` (`HERO`; `set_equipment(weapon, shield)`); `last_step_m` feeds the encounter meter; `place(pos, yaw)` (autoplay goes on from the nearest route point). `--autoplay` walks `route` (the zone's `autoplay_route`) in a loop: in the meadow through the village past the old woman, the merchant, the boss spot, the north exit and the innkeeper, and past two chests; in the forest through its glades, the village and the witch's clearing.
```

3. Replace:

```markdown
- `scripts/world/encounter_table.gd` (`EncounterTable`, `RefCounted`) — which enemies come, from the zone: `pick(zone, pos, rng)` (a formation of `zone.formations`, same weight, or of `zone.start_formations` within `start_radius` of `start_pos`: slimes near the meadow's spawn, one forest enemy at a time near the forest's entry), `near_start(zone, pos)`.
- `scripts/battle/enemy_library.gd` (`EnemyLibrary`, `RefCounted`) — every enemy by id (`ENEMIES`: `data/enemies/<id>.tres`: slime, bat, mushroom, rey_slime, lobo, duende, planta, bruja) and its figure (`LOOKS`); `data(id)`, `look(id)` (slime if unknown), `formation(ids)`.
- `scenes/battle/battle_scene.tscn` + `scripts/battle/battle_scene.gd` (`BattleScene`) — one battle against one or two enemies: call `setup(hero, enemies: Array[Combatant], inventory)`, `set_audio(audio)`, `set_equipment(weapon, shield)` and set `char_time` and `gold_lost` (said as "Pierdes N monedas de oro." on a defeat) before adding it (hero and inventory used as is, enemies duplicated, two with the same name become "Slime A" / "Slime B"; without audio it is silent); builds stage (`BattleStage.build(self, zone)`; set `zone` before adding it), the hero and one `BattleActor` per enemy (`EnemyLibrary.look()` by data id; a pair stands left and right of `ENEMY_POS`, `PAIR_OFFSET` 1.5 m), camera, the blinking yellow target arrow (`_show_arrow(index)`, from `BattleHud.target_changed`; `_pick_target(screen)` turns clicks into enemies) and a `CanvasLayer` with `BattleHud` and `BattleResult`. Flow: HUD `command_chosen(cmd)` (asleep: `cmd_none()`) → `BattleEngine.resolve_round(cmd)` → `_play_event()` per event → menu again, or result overlay → "Continuar" → `finished(outcome)` (fled: at once). Every message goes through `_say()` (`_the()` / `_ending()` give "el / la" and "-o / -a" from `Combatant.female`). A call for help moves the caller to the left and grows the helper on the right. Effects: hit, crit, miss, fire on spell casts, potion, heal, level up, accept on "Continuar"; music: victory fanfare on the VICTORY event, defeat when the hero falls. `--autoplay`: `BattleAutoplay` picks (shown with `BattleHud.demo()`), flees from every 5th normal battle and defends in the first round of the 2nd, 7th...; prints every message and continues by itself. Run on its own: a poisoned Lv 3 hero with 3 potions and an antidote against a Slime and a Murciélago, quits at the end ("Fin del combate (estado N)").
- `scripts/battle/battle_engine.gd` (`BattleEngine`, `RefCounted`) — pure round rules for the hero against `enemies: Array[Combatant]` (fighters are ints: `BattleEvent.HERO` = −1 or an enemy index). Commands are dictionaries from `cmd_attack(target)`, `cmd_skill(skill, target)`, `cmd_item(id)`, `cmd_defend()`, `cmd_flee()`, `cmd_none()`; `problem(cmd)` (why not: "Faltan PM", "Silencio", item reasons), `can_use(cmd)`, `alive_enemies()`, `has_boss()`, `flee_chance()`. Each enemy picks when its turn comes, from `ai_weights` (`"attack"`, `"stagger"` or a skill id), casts its `rescue_heal` once below `rescue_heal_ratio` of max HP (the Bruja: Curar 40 PV below 40 %), or calls its `help` once below 50 % HP while fewer than `MAX_ENEMIES` 2 stand. Initiative `speed × randf_range(0.5, 1.5)` (defending or fleeing, the hero goes first); attacks: 5 % miss, 1/16 crit (ignores DEF), damage `base × randf_range(0.875, 1.125)` rounded, minimum 1, where `base = max(1, total ATK − total DEF/2)` (crit: `ATK × 1.5`), may cause the attacker's `attack_status`; spells pay MP: damage `power × the same spread × 1.5 weak / 0.5 resist`, ignoring DEF, no miss or crit, may cause their status; heals restore `power`. Defend halves the damage taken that round (rounded up, min 1). Flee: `clamp(0.5 + (hero VEL − mean enemy VEL) × 0.05, 0.2, 0.95)`; against a boss only `NO_ESCAPE`, no turn passes. Status (`Combatant.status`): poison 8 % max HP at the end of each round; sleep loses the turn, 50 % to wake at the end of each round, damage wakes; silence 3 rounds without spells; all cleared when the battle ends. On victory: `exp_won`, `gold_won`, `Leveling.apply()`, each enemy's `drops` rolls (`drops_won`). Returns `Array[Dictionary]` events built by `BattleEvent` (`scripts/battle/battle_event.gd`); `state` is `ONGOING`, `WON`, `LOST` or `FLED`. Never touches nodes.
- `scripts/battle/battle_autoplay.gd` (`BattleAutoplay`, `RefCounted`) — pure command picker for `--autoplay` and balance checks: below 40 % HP heals (Curar, else potion), with no heal defends below 25 % (never twice in a row); antidote when poisoned, ether when MP can't pay a heal; otherwise aims at the weakest enemy and casts the spell that hurts most (weaknesses count) only when it beats an attack by ×1.5, keeping MP for two heals. `choose(engine)`.
- `scripts/battle/combatant.gd` (`Combatant`, `Resource`) — fighter stats (`id`, `female`, level, HP, MP, base `attack` / `defense` plus hero-only `equip_attack` / `equip_defense` (the loadout bonuses, set by `GameState.refresh_equipment()`; `total_attack()` / `total_defense()`), speed, `skills`, hero-only `learn` (level → Skill), EXP; enemy-only `exp_reward`, `gold_reward`, `ai_weights`, `weak` / `resist` (elements), `drops` (item id → chance), `attack_status` / `attack_status_chance`, `help` (Combatant it calls), `rescue_heal` / `rescue_heal_ratio` (a heal cast once), boss-only `key_item`, `is_boss`); battle-only `status` (status → rounds, −1 until cured). Data in `data/hero.tres` and `data/enemies/*.tres` (`EnemyLibrary`); the enemies' own spells are `data/skills/llama_duende.tres`, `llamarada_bruja.tres` and `curar_bruja.tres`.
- `scripts/battle/skill.gd` (`Skill`, `Resource`) — spell data (`id`, `display_name`, `mp_cost`, `power`, `color` of the cast glow and hit ball, `element` `fire` / `ice` / `thunder` / "", `kind` `damage` / `heal` / `status`, `targets` `one` / `all`, `status`, `status_chance`; `needs_target()`); `data/skills/`: `llama`, `curar`, `llamarada`, `rayo`, `curar_mas` (the hero's), `aplastar` (Rey Slime), `esporas` (Seta: sleep 30 %).
- `scenes/battle/battle_actor.tscn` + `scripts/battle/battle_actor.gd` (`BattleActor`) — figure of a fighter or villager built from the `LOOKS` table (`look`: `HERO` / `SLIME` / `VILLAGER` / `KING_SLIME` / `BAT` / `MUSHROOM` / `MERCHANT` / `INNKEEPER` / `WOLF` / `GOBLIN` / `PLANT` / `WITCH`, set before `add_child`), faces -Z. `HERO` is KayKit `Knight.glb` (every hand mesh hidden; `set_equipment(weapon, shield)` shows the `Equipment.mesh()` of each under `handslot_r` / `handslot_l`, plus a wooden stick built in code for the Palo), `VILLAGER` is `Mage.glb`, `MERCHANT` / `INNKEEPER` the same Mage tinted green / orange (`tint`), `WITCH` the Mage at scale 0.75 tinted dark purple, wand kept (scale 0.65, turned 180°, unused props hidden, `AnimationPlayer` at `AnimationPlayer`, roles in `CHARACTER_ANIMS`: `Idle`, `Running_A`, `1H_Melee_Attack_Slice_Diagonal`, `Spellcast_Shoot`, `Hit_A`, `Dodge_Backward`, `Death_A`, `Cheer`); `SLIME` / `KING_SLIME` are faceted `LowPoly` blobs with eyes (king ×1.6 with a gold crown) that bounce while idle; `BAT` hovers at 1.1 m flapping two box wings; `MUSHROOM` is a stem with eyes and a spotted hemisphere cap (×1.4) that bounces; `WOLF` is a faceted body and wedge head on four legs (breathes); `GOBLIN` a small green slime with pointed ears and a red hat; `PLANT` a stem with leaves and a two-jaw head that sways and opens its upper jaw to bite in `play_attack`. Awaitable `play_attack`, `play_hit(amount, crit, tag)` (flash overlay + floating `Label3D` number, `tag` "¡Débil!" / "¡Resiste!" under it), `play_dodge`, `play_defeat` (characters stay down, the rest fade and hide), `play_cast(color)`, `play_burn(amount, color, tag)`, `play_heal(amount, color)`, `play_status(color, amount)`, `play_appear()`, `play_stagger`, `play_cheer`; `top_height()`; `set_walking(on)` for the map; `reset()`.
- `scripts/battle/battle_stage.gd` (`BattleStage`) — battle backdrop builder, `build(root, zone)` (tall grass around the fighters, none where they stand; KayKit rocks and trees and low-poly bushes around them; the `bosque` backdrop has darker ground and grass and `FOREST_TREES` close around); `build_environment(root, zone)` (procedural sky, ACES tonemap, SSAO, glow, the zone's fog, haze and sun with shadows), `add_mesh()`, `unit_sphere()`, `add_model(root, scene, pos, scl, yaw_deg)`, `scene_mesh(scene)`, `model_aabb(model)`, `rock_radius(rock)`, `ROCK_SCENES`, `ROCK_RADII` and `TREE_SCENES` are shared with `WorldStage`.
- `scripts/battle/low_poly.gd` (`LowPoly`) — faceted flat-shaded meshes built in code: `blob(profile, segments)` (lathe of a side profile; slimes and bushes), `bush_mesh()`, `add_multimesh(root, mesh, transforms)`.
```

with:

```markdown
- `scripts/world/encounter_table.gd` (`EncounterTable`, `RefCounted`) — which enemies come, from the zone: `pick(zone, pos, rng)` (a formation of `zone.formations`, same weight, or of `zone.start_formations` within `start_radius` of `start_pos`: slimes near the meadow's spawn, one forest enemy at a time near the forest's entry), `near_start(zone, pos)`.
- `scripts/battle/enemy_library.gd` (`EnemyLibrary`, `RefCounted`) — every enemy by id (`ENEMIES`: `data/enemies/<id>.tres`: slime, bat, mushroom, rey_slime, lobo, duende, planta, bruja, golem_barro, arana, espectro, golem_piedra) and its figure (`LOOKS`); `data(id)`, `look(id)` (slime if unknown), `formation(ids)`.
- `scenes/battle/battle_scene.tscn` + `scripts/battle/battle_scene.gd` (`BattleScene`) — one battle against one or two enemies: call `setup(hero, enemies: Array[Combatant], inventory)`, `set_audio(audio)`, `set_equipment(weapon, shield)` and set `char_time` and `gold_lost` (said as "Pierdes N monedas de oro." on a defeat) before adding it (hero and inventory used as is, enemies duplicated, two with the same name become "Slime A" / "Slime B"; without audio it is silent); builds stage (`BattleStage.build(self, zone)`; set `zone` before adding it), the hero and one `BattleActor` per enemy (`EnemyLibrary.look()` by data id; a pair stands left and right of `ENEMY_POS`, `PAIR_OFFSET` 1.5 m), camera, the blinking yellow target arrow (`_show_arrow(index)`, from `BattleHud.target_changed`; `_pick_target(screen)` turns clicks into enemies) and a `CanvasLayer` with `BattleHud` and `BattleResult`. Flow: HUD `command_chosen(cmd)` (asleep: `cmd_none()`) → `BattleEngine.resolve_round(cmd)` → `_play_event()` per event → menu again, or result overlay → "Continuar" → `finished(outcome)` (fled: at once). Every message goes through `_say()` (`_the()` / `_ending()` give "el / la" and "-o / -a" from `Combatant.female`). A call for help moves the caller to the left and grows the helper on the right. Effects: hit, crit, miss, fire on spell casts, potion, heal, level up, accept on "Continuar"; music: victory fanfare on the VICTORY event, defeat when the hero falls. `--autoplay`: `BattleAutoplay` picks (shown with `BattleHud.demo()`), flees from every 5th normal battle and defends in the first round of the 2nd, 7th...; prints every message and continues by itself. Run on its own: a poisoned Lv 3 hero with 3 potions and an antidote against a Slime and a Murciélago, quits at the end ("Fin del combate (estado N)").
- `scripts/battle/battle_engine.gd` (`BattleEngine`, `RefCounted`) — pure round rules for the hero against `enemies: Array[Combatant]` (fighters are ints: `BattleEvent.HERO` = −1 or an enemy index). Commands are dictionaries from `cmd_attack(target)`, `cmd_skill(skill, target)`, `cmd_item(id)`, `cmd_defend()`, `cmd_flee()`, `cmd_none()`; `problem(cmd)` (why not: "Faltan PM", "Silencio", item reasons), `can_use(cmd)`, `alive_enemies()`, `has_boss()`, `flee_chance()`. Each enemy picks when its turn comes, from `ai_weights` (`"attack"`, `"stagger"`, `"charge"` or a skill id; after a charge — the Golem de piedra: "El Golem de piedra acumula fuerza..." — its next turn is a blow of `CHARGE_MULT` 2× the damage that never misses or crits, which Defender halves; `is_charged(i)`), casts its `rescue_heal` once below `rescue_heal_ratio` of max HP (the Bruja: Curar 40 PV below 40 %), or calls its `help` once below 50 % HP while fewer than `MAX_ENEMIES` 2 stand. Initiative `speed × randf_range(0.5, 1.5)` (defending or fleeing, the hero goes first); attacks: 5 % miss, 1/16 crit (ignores DEF), damage `base × randf_range(0.875, 1.125)` rounded, minimum 1, where `base = max(1, total ATK − total DEF/2)` (crit: `ATK × 1.5`), may cause the attacker's `attack_status`; spells pay MP: damage `power × the same spread × 1.5 weak / 0.5 resist`, ignoring DEF, no miss or crit, may cause their status; heals restore `power`. Defend halves the damage taken that round (rounded up, min 1). Flee: `clamp(0.5 + (hero VEL − mean enemy VEL) × 0.05, 0.2, 0.95)`; against a boss only `NO_ESCAPE`, no turn passes. Status (`Combatant.status`): poison 8 % max HP at the end of each round; sleep loses the turn, 50 % to wake at the end of each round, damage wakes; silence 3 rounds without spells; all cleared when the battle ends. On victory: `exp_won`, `gold_won`, `Leveling.apply()`, each enemy's `drops` rolls (`drops_won`). Returns `Array[Dictionary]` events built by `BattleEvent` (`scripts/battle/battle_event.gd`); `state` is `ONGOING`, `WON`, `LOST` or `FLED`. Never touches nodes.
- `scripts/battle/battle_autoplay.gd` (`BattleAutoplay`, `RefCounted`) — pure command picker for `--autoplay` and balance checks: below 40 % HP heals (Curar, else potion), with no heal defends below 25 % (never twice in a row); antidote when poisoned, ether when MP can't pay a heal; otherwise aims at the weakest enemy and casts the spell that hurts most (weaknesses count) only when it beats an attack by ×1.5, keeping MP for two heals. `choose(engine)`.
- `scripts/battle/combatant.gd` (`Combatant`, `Resource`) — fighter stats (`id`, `female`, level, HP, MP, base `attack` / `defense` plus hero-only `equip_attack` / `equip_defense` (the loadout bonuses, set by `GameState.refresh_equipment()`; `total_attack()` / `total_defense()`), speed, `skills`, hero-only `learn` (level → Skill), EXP; enemy-only `exp_reward`, `gold_reward`, `ai_weights`, `weak` / `resist` (elements), `drops` (item id → chance), `attack_status` / `attack_status_chance`, `help` (Combatant it calls), `rescue_heal` / `rescue_heal_ratio` (a heal cast once), boss-only `key_item`, `is_boss`); battle-only `status` (status → rounds, −1 until cured). Data in `data/hero.tres` and `data/enemies/*.tres` (`EnemyLibrary`); the enemies' own spells are `data/skills/llama_duende.tres`, `llamarada_bruja.tres`, `curar_bruja.tres` and `hielo_espectro.tres`.
- `scripts/battle/skill.gd` (`Skill`, `Resource`) — spell data (`id`, `display_name`, `mp_cost`, `power`, `color` of the cast glow and hit ball, `element` `fire` / `ice` / `thunder` / "", `kind` `damage` / `heal` / `status`, `targets` `one` / `all`, `status`, `status_chance`; `needs_target()`); `data/skills/`: `llama`, `curar`, `llamarada`, `rayo`, `curar_mas` (the hero's), `aplastar` (Rey Slime), `esporas` (Seta: sleep 30 %).
- `scenes/battle/battle_actor.tscn` + `scripts/battle/battle_actor.gd` (`BattleActor`) — figure of a fighter or villager built from the `LOOKS` table (`look`: `HERO` / `SLIME` / `VILLAGER` / `KING_SLIME` / `BAT` / `MUSHROOM` / `MERCHANT` / `INNKEEPER` / `WOLF` / `GOBLIN` / `PLANT` / `WITCH` / `MUD_GOLEM` / `STONE_GOLEM` / `SPIDER` / `SPECTER`, set before `add_child`), faces -Z. `HERO` is KayKit `Knight.glb` (every hand mesh hidden; `set_equipment(weapon, shield)` shows the `Equipment.mesh()` of each under `handslot_r` / `handslot_l`, plus a wooden stick built in code for the Palo), `VILLAGER` is `Mage.glb`, `MERCHANT` / `INNKEEPER` the same Mage tinted green / orange (`tint`), `WITCH` the Mage at scale 0.75 tinted dark purple, wand kept (scale 0.65, turned 180°, unused props hidden, `AnimationPlayer` at `AnimationPlayer`, roles in `CHARACTER_ANIMS`: `Idle`, `Running_A`, `1H_Melee_Attack_Slice_Diagonal`, `Spellcast_Shoot`, `Hit_A`, `Dodge_Backward`, `Death_A`, `Cheer`); `SLIME` / `KING_SLIME` are faceted `LowPoly` blobs with eyes (king ×1.6 with a gold crown) that bounce while idle; `BAT` hovers at 1.1 m flapping two box wings; `MUSHROOM` is a stem with eyes and a spotted hemisphere cap (×1.4) that bounces; `WOLF` is a faceted body and wedge head on four legs (breathes); `GOBLIN` a small green slime with pointed ears and a red hat; `PLANT` a stem with leaves and a two-jaw head that sways and opens its upper jaw to bite in `play_attack`; `MUD_GOLEM` / `STONE_GOLEM` faceted blocks (legs, body, head, long arms) with glowing eyes, the stone one grey and ×1.55; `SPIDER` a round abdomen and small head with red eyes on eight bent legs; `SPECTER` a see-through pale drop with a blue aura that floats up and down (its materials fade with `play_defeat`). Awaitable `play_attack`, `play_hit(amount, crit, tag)` (flash overlay + floating `Label3D` number, `tag` "¡Débil!" / "¡Resiste!" under it), `play_dodge`, `play_defeat` (characters stay down, the rest fade and hide), `play_cast(color)`, `play_burn(amount, color, tag)`, `play_heal(amount, color)`, `play_status(color, amount)`, `play_appear()`, `play_stagger`, `play_cheer`; `top_height()`; `set_walking(on)` for the map; `reset()`.
- `scripts/battle/battle_stage.gd` (`BattleStage`) — battle backdrop builder, `build(root, zone)` (tall grass around the fighters, none where they stand; KayKit rocks and trees and low-poly bushes around them; the `bosque` backdrop has darker ground and grass and `FOREST_TREES` close around; `mina` is a cave: rock floor, `CAVE_BLOCKS` wall, boulders, stalagmites, two torches and a lantern light, no grass); `build_environment(root, zone)` (procedural sky, ACES tonemap, SSAO, glow, the zone's fog, haze and sun with shadows; an `underground` zone gets a black background, a flat ambient light and no sun), `add_mesh()`, `unit_sphere()`, `add_model(root, scene, pos, scl, yaw_deg)`, `scene_mesh(scene)`, `model_aabb(model)`, `rock_radius(rock)`, `ROCK_SCENES` and `ROCK_RADII` are shared with `WorldStage`.
- `scripts/battle/low_poly.gd` (`LowPoly`) — faceted flat-shaded meshes built in code: `blob(profile, segments)` (lathe of a side profile; slimes and bushes), `bush_mesh()`, `add_multimesh(root, mesh, transforms)`.
```

4. Replace:

```markdown
- `scripts/ui/pause_menu.gd` (`PauseMenu`, `Control`, `PROCESS_MODE_ALWAYS`) — Esc / P or the ☰ button (top right, three `ColorRect` bars) open it while `available`; sets `get_tree().paused`. Pages: main (Estado, Objetos, Equipo, Guardar, Opciones, Volver al título, Cerrar), Estado (stats, gold, spells), Objetos ("Usar" on every item; greyed with the reason when it can't be used outside battle now; the Ala de viaje closes the menu and emits `travel_requested`; then the key items, "Objeto clave"), Equipo (the three slots with what is worn and ATK / DEF; a slot lists the pieces of that slot in the bag with the comparison, Quitar and Volver), Opciones (`OptionsPanel`), confirmation before the title. Signals `save_requested` (answered with `show_save_result(ok)`), `title_requested`, `travel_requested`, `state_changed`; `tour()` for `--autoplay-menu`.
- `scripts/audio/music_library.gd` (`MusicLibrary`) — original tracks as note tables (`TRACKS`: bpm, loop, lead duty, bars of tokens like `"F#5/4"` = note / length in sixteenths, `r` rest, drums `k` / `s` / `h`): title, map, village (waltz), forest (E minor), battle, boss loop; victory and defeat don't. `build(id)` synthesizes square lead, triangle bass and noise drums into a cached `AudioStreamWAV` (22050 Hz, 16-bit mono, `LOOP_FORWARD` over the whole track); `to_stream()`, `peak()`, `clear_cache()`.
- `scripts/audio/sfx_library.gd` (`SfxLibrary`) — sfxr-style effects as parameter dictionaries (`SOUNDS`: wave, pitch slide or notes, time, volume, decay); `build(id)` cached; `clear_cache()`.
- `scripts/audio/audio_director.gd` (`AudioDirector`, `Node`, `PROCESS_MODE_ALWAYS`) — not an autoload; two music players with a 0.5 s cross-fade (`play_music(id)`, `stop_music()`), 6 effect players (`play_sfx(id)`), `set_volumes(music, sfx)`. Muted on autoplay (prints `Música: <id>`); headless and `--write-movie` runs never call `play()` (their audio drivers would leak the playbacks at exit). Empties the caches when it leaves the tree.
```

with:

```markdown
- `scripts/ui/pause_menu.gd` (`PauseMenu`, `Control`, `PROCESS_MODE_ALWAYS`) — Esc / P or the ☰ button (top right, three `ColorRect` bars) open it while `available`; sets `get_tree().paused`. Pages: main (Estado, Objetos, Equipo, Guardar, Opciones, Volver al título, Cerrar), Estado (stats, gold, spells), Objetos ("Usar" on every item; greyed with the reason when it can't be used outside battle now; the Ala de viaje closes the menu and emits `travel_requested`; then the key items, "Objeto clave"), Equipo (the three slots with what is worn and ATK / DEF; a slot lists the pieces of that slot in the bag with the comparison, Quitar and Volver), Opciones (`OptionsPanel`), confirmation before the title. Signals `save_requested` (answered with `show_save_result(ok)`), `title_requested`, `travel_requested`, `state_changed`; `tour()` for `--autoplay-menu`.
- `scripts/audio/music_library.gd` (`MusicLibrary`) — original tracks as note tables (`TRACKS`: bpm, loop, lead duty, bars of tokens like `"F#5/4"` = note / length in sixteenths, `r` rest, drums `k` / `s` / `h`): title, map, village (waltz), forest (E minor), mine (D minor, 88 bpm), battle, boss loop; victory and defeat don't. `build(id)` synthesizes square lead, triangle bass and noise drums into a cached `AudioStreamWAV` (22050 Hz, 16-bit mono, `LOOP_FORWARD` over the whole track); `to_stream()`, `peak()`, `clear_cache()`.
- `scripts/audio/sfx_library.gd` (`SfxLibrary`) — sfxr-style effects as parameter dictionaries (`SOUNDS`: wave, pitch slide or notes, time, volume, decay; `DOOR` is the rumble of the lever and the gates); `build(id)` cached; `clear_cache()`.
- `scripts/audio/audio_director.gd` (`AudioDirector`, `Node`, `PROCESS_MODE_ALWAYS`) — not an autoload; two music players with a 0.5 s cross-fade (`play_music(id)`, `stop_music()`), 6 effect players (`play_sfx(id)`), `set_volumes(music, sfx)`. Muted on autoplay (prints `Música: <id>`); headless and `--write-movie` runs never call `play()` (their audio drivers would leak the playbacks at exit). Empties the caches when it leaves the tree.
```

5. Replace:

```markdown
- Run only the world map (prints encounters, shops, inns, chests and exits instead of playing them): `.\tools\godot.cmd --path . res://scenes/world/world.tscn -- --autoplay`
- Start a new autoplay game in another zone (`--autoplay-zone=bosque`: Lv 5, 150 G, the zone 1 gear, the Rey Slime beaten; it buys the forest gear, sleeps at the inn when below half HP and fights the Bruja at Lv 9): `.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 40000 -- --autoplay --autoplay-zone=bosque`
- Record frames to check visuals (not headless; writes `f00000000.png`, ...; 1280x720 PNGs, ~1 MB each; delete the folder afterwards): `.\tools\godot.cmd --path . --write-movie <dir>\f.png --fixed-fps 10 --quit-after 600 -- --autoplay`
```

with:

```markdown
- Run only the world map (prints encounters, shops, inns, chests and exits instead of playing them): `.\tools\godot.cmd --path . res://scenes/world/world.tscn -- --autoplay`
- Start a new autoplay game in another zone (`--autoplay-zone=bosque`: Lv 5, 150 G, the zone 1 gear, the Rey Slime beaten; it buys the forest gear, sleeps at the inn when below half HP and fights the Bruja at Lv 9, then walks on into the mine): `.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 40000 -- --autoplay --autoplay-zone=bosque`. The mine: `--autoplay-zone=mina_1` (the three floors: shop, chests, lever, key, gate, Golem from Lv 13) or `--autoplay-zone=mina_3` (straight to the Golem at Lv 13).
- Record frames to check visuals (not headless; writes `f00000000.png`, ...; 1280x720 PNGs, ~1 MB each; delete the folder afterwards): `.\tools\godot.cmd --path . --write-movie <dir>\f.png --fixed-fps 10 --quit-after 600 -- --autoplay`
```

- [ ] **Step 2: Check every changed script once more**

```powershell
.\tools\godot.cmd --headless --path . --import
foreach ($s in "battle/battle_engine","battle/battle_event","battle/combatant","battle/battle_autoplay","battle/battle_scene","battle/battle_actor","battle/battle_stage","battle/enemy_library","world/zone_data","world/dungeon_map","world/world","world/world_stage","game/game","game/chests","game/shop","game/inn","game/inventory","audio/music_library","audio/sfx_library") { .\tools\godot.cmd --headless --path . --check-only --script "res://scripts/$s.gd" }
```

Expected: no line with `ERROR` or `WARNING`.

- [ ] **Step 3: Web export**

```powershell
.\tools\godot.cmd --headless --path . --export-release "Web" build/web/index.html
Get-ChildItem build\web | Select-Object Name, Length
```

Expected: no `ERROR`; `index.pck` about 3.4 MB (no new assets: it grows by a few KB of scripts and data). Serve `build/web` with any static server and walk into the mine (a save from the forest, or the forest after the Bruja): it must stay smooth with up to 11 omni lights per floor; note the FPS shown by the browser's performance tools in the commit message body if it drops under 50. `build/` is git-ignored.

- [ ] **Step 4: Commit**

```powershell
git add CLAUDE.md
git status --short
git commit -m "Document the mine phase"
```

`git status --short` must show nothing untracked.

---

## Next plan

- **5c — Castillo de la Niebla** (`docs/boost/plans/<date>-mundo-castillo.md`): an exit from `mina_3` (or from the refugio; pick the one that reads best on the map) locked by the `golem_piedra` flag with the same fog and notice, the camp before the castle (platinum shop 650 / 550 / 300 G, inn 50 G), the courtyard with fog and the throne room (`castillo_patio.tres`, `castillo_trono.tres`: reuse `ZoneData.layout` and `DungeonMap` with `#` drawn as Medieval Hexagon `wall_*` pieces where they fit and blocks elsewhere, `underground` false with a fog-heavy environment, the same see-through and transition guard), Esqueleto guerrero / pícaro / mago from KayKit Skeletons (copy from `assets_src/KayKit-Character-Pack-Skeletons-1.0`, add a `CREDITS.md` row), the Señor de la Niebla (`Skeleton_Mage` ×1.6 with a purple aura; phase 1: 200 PV, ATK 42, Rayo 40; phase 2: back to 180 PV, ATK 50, Niebla on every target for 30 and 30 % silence, no stagger) with its own simulation for 85-90 % at Lv 17, the third fragment, a `castillo` backdrop, `--autoplay-zone` starts for the castle, the full autoplay from the start to the Señor de la Niebla with the real duration measured against the ~2 hours, and the web export measured in size and FPS. Worth doing there too: an autoplay rule that walks back to the last inn (or uses an Ala de viaje) when HP is low and gold allows, since the mine showed that a long dungeon loop wears the autoplay hero out and its gold halves on every defeat.
