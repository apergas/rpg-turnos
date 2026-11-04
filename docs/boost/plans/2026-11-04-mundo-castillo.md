# Mundo: el castillo (fase 5c) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add zone 4, the Castillo de la Niebla, last part of the multi-zone world: the tunnel from the Golem's room in the mine (fog until the Golem de piedra is beaten), the camp before the castle (platinum shop 650 / 550 / 300 G, inn 50 G, a soldier), the foggy courtyard and the throne room drawn as dungeon grids whose rock cells are castle walls (KayKit `wall_straight` pieces on straight runs, towers and pillars elsewhere), the Esqueleto guerrero / pícaro / mago (KayKit Skeletons with their animations and weapons), the Señor de la Niebla in two phases (the fog envelops him at 0 HP and he rises with 180 PV, ATK 46 and Niebla on every target with 30 % silence, no more staggering), the third fragment of the amulet and a "game finished" flag with a notice, a castle battle backdrop and music, `--autoplay-zone=castillo_patio` / `castillo_trono`, and an autoplay that rests and restocks by itself so a full run from a new game reaches and beats the Señor de la Niebla (measured: 1:30-1:56 of play time).

**Architecture:** Same data-first scheme as phases 5a and 5b. The castle floors are `ZoneData` dungeon grids (`layout`, 4 m cells) with two new flags: `castle` (DungeonMap draws stone walls instead of rock blocks, plus a ground plane past the grid) and `mist_banks`; a new cell `R` is the throne. `BattleEngine` gains a pure, generic second phase: a boss whose `Combatant.next_phase` is set rises once with that phase's stats instead of falling (a `PHASE` event); Niebla is an ordinary `Skill` (all targets, silence 30 %). `BattleActor` gets four looks built from KayKit Skeletons (weapons hung on `BoneAttachment3D`s of the hand bones; the boss is the Skeleton_Mage ×1.6 in a purple aura that swells in `play_phase()`). `Game` marks the game finished on the Señor's flag (`GameState.is_finished()`), and on autoplay retreats with an Ala de viaje when `GameState.needs_rest()`, restocks at the village's inn and shop after a retreat or a defeat, and only lets a boss out while the hero is healthy. The save format does not change (version 4 stores zone, flags and key items; the new ids are in `ZoneData.IDS` and `Inventory.KEY_ITEMS`).

**Tech Stack:** Godot 4.7.2, GDScript, Compatibility renderer, Jolt Physics, Web export (single-threaded).

**Spec:** `docs/boost/specs/2026-11-03-mundo-zonas-design.md` (zone 4 row and "Señor de la Niebla"; numbers from the "Equilibrio" section of `docs/boost/specs/2026-11-03-ideas-juego-completo.md`). Phase 5 is split in three plans; this is 5c, the last (5a: `docs/boost/plans/2026-11-04-mundo-bosque.md`, 5b: `docs/boost/plans/2026-11-04-mundo-mina.md`).

**Baseline:** phase 5b merged into `develop` at `fd46f92` ("Merge feature/mundo-mina into develop": the 5b plan plus `b94d49d` — `ZoneData.find_cells()` cache, the lever tween, safe entry fallback — and the docs `4e77698`). Every "Replace" below quotes the files exactly as they are there. This plan was written and run against that commit: every task was applied in order on a copy of it, each intermediate state compiled, and the final state passed every check below (four full autoplay runs from a new game beat the Señor de la Niebla in 1:30:36, 1:33:26, 1:36:44 and 1:55:30 of play time with no ERROR and only the known Jolt warning).

## Global Constraints

- **No tests of any kind** (project rule in CLAUDE.md). Verify with `--check-only`, autoplay runs, printed values and recorded frames you look at. The one-off `balance_check.gd`, `looks_probe.*` and `map_probe.*` files at the project root are deleted right after use and never committed.
- Godot runs through `.\tools\godot.cmd` (PowerShell). After copying new models into `assets/` run `.\tools\godot.cmd --headless --path . --import` before `--check-only`. `--write-movie` needs an absolute folder path.
- Indent GDScript with tabs. Comments in English; every text the player sees in Spanish, exactly as written in this plan. `.tscn` files only hold the root node and its script; no autoloads; pure classes (`ZoneData`, `EnemyLibrary`, `GameState`, `SaveData`, `Chests`, `Shop`, `Inn`, `Inventory`, `BattleEngine`, `BattleAutoplay`, `Combatant`) never touch nodes.
- **Zones:** `ZoneData.IDS` = `["pradera", "bosque", "mina_1", "mina_2", "mina_3", "castillo_patio", "castillo_trono"]`. **No save version bump** (version 4 already validates zone ids and key items against `ZoneData.IDS` / `Inventory.KEY_ITEMS`).
- **Assets** (copied unchanged from `assets_src/`, credited in `assets/CREDITS.md`): from KayKit Skeletons 1.0 `Characters/gltf/Skeleton_Warrior.glb`, `Skeleton_Rogue.glb`, `Skeleton_Mage.glb` and `Assets/gltf/Skeleton_Blade.gltf/.bin`, `Skeleton_Staff.gltf/.bin`, `Skeleton_Shield_Small_A.gltf/.bin`, `skeleton_texture.png` into `assets/characters/`; from Medieval Hexagon 1.0 `buildings/neutral/wall_straight.gltf/.bin` and `decoration/props/tent.gltf/.bin` into `assets/medieval/` (they use the `hexagons_medieval.png` already there). The skeletons have no weapons inside the .glb: `BattleActor` hangs the weapon models on new `BoneAttachment3D`s of the bones `handslot.r` / `handslot.l` under `Rig/Skeleton3D`.
- **Enemies** (`data/enemies/*.tres`; the spec's Caballero oscuro / Gárgola / Hechicero stats unchanged):

| id | Name | PV | ATK | DEF | VEL | PM | Skill / AI | Weak / resist | EXP | Oro | Drop | Look |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `esqueleto_guerrero` | Esqueleto guerrero | 73 | 36 | 38 | 12 | 0 | attack 85, stagger 15 | resists ice | 45 | 40 | Poción 15 % | `SKELETON_WARRIOR` (blade + shield) |
| `esqueleto_picaro` | Esqueleto pícaro | 61 | 34 | 32 | 18 | 0 | attack 90, stagger 10; stab poisons 15 % | weak fire | 42 | 38 | Antídoto 15 % | `SKELETON_ROGUE` (two blades) |
| `esqueleto_mago` | Esqueleto mago | 55 | 27 | 30 | 14 | 24 | Rayo (8 PM, 38, thunder) 45, attack 55 | weak fire, resists thunder | 48 | 50 | Éter 10 % | `SKELETON_MAGE` (staff) |
| `senor_niebla` | Señor de la Niebla (boss), phase 1 | 200 | 42 | 40 | 14 | 40 | Rayo (8 PM, 40, thunder) 35, attack 50, stagger 15 | — | 500 | 0 | key item `fragmento_castillo` | `FOG_LORD` |
| (`senor_niebla_2.tres`) | phase 2 (`next_phase`) | 180 | 46 | 40 | 14 | 48 | Niebla (6 PM, 30, all targets, silence 30 %) 45, attack 55, no stagger | — | — | — | — | — |

- **The second phase** (`BattleEngine._fall()`): when an enemy with a `next_phase` reaches 0 HP (a hit, a spell or poison) it is not defeated: its `next_phase` is cleared and it takes that phase's `max_hp`, `hp`, `max_mp`, `mp`, `attack`, `defense`, `speed`, `skills` and `ai_weights` (status cured, charge forgotten) and a `PHASE` event (`target`, `hp_left`) follows the damage. `BattleScene` plays it with the encounter sound, a camera shake, `BattleActor.play_phase()` (purple glow, cast animation, the aura grows ×1.3 and thickens from alpha 0.2 to 0.38) and the lines "¡La niebla envuelve al Señor de la Niebla!" / "¡El Señor de la Niebla se levanta con 180 PV!". Niebla against the lone hero is one hit of 30 ± spread ignoring DEF, then 30 % silence (3 rounds without Curar). The boss can't be fled from.
- **Balance** (one-off `balance_check.gd`, 4000 battles per line, seed 12345, real `BattleEngine` + `BattleAutoplay`, gear equipped through `GameState`; normal battles without potions, the boss with 3). With the spec's phase 2 ATK 50 the Lv 17 hero won 84.3 % (DEF 34-40 and Niebla's weight barely moved it: the losses are crits, which ignore DEF). Tuned phase 2 to ATK 46. Final:

| Situation | Target | Result |
|---|---|---|
| Lv 13 entering (camp singles), zone 3 gear | 97-99 %, 20-35 % HP | 99.9 %, 14 %, 1.6 rounds |
| Lv 13 all formations, zone 3 gear | — | 96.5 %, 18 %, 2.3 rounds |
| Lv 15 mid zone, zone 4 gear | > 99 %, ~18 % | 99.5 %, 19 %, 2.6 rounds |
| Lv 17 leaving, zone 4 gear | ~15 % | 99.9 %, 14 % |
| Señor de la Niebla Lv 17, 3 potions, zone 4 gear | 85-90 %, ~9 rounds | **87.4 %, 11.2 rounds** (reaches phase 2 in 97 %, 0.62 silences per fight) |
| Señor Lv 15 / Lv 16 / Lv 18 | (spec: 82 / 87 / 92 %) | 79.7 % / 82.5 % / 91.2 % |
| Señor Lv 17 with the zone 3 gear | — | 88.2 % |

  The fight is ~2 rounds longer than the spec's ~9: the hero spends turns on Curar+ and potions between Rayo, Niebla and crits; any change that shortens it pushes the win rate over 90 %. Kept.
- **Castle grid** (`ZoneData.castle` true): every rock cell with a floor cell among its 8 neighbours is drawn by `DungeonMap._add_castle()`: `"ew"` / `"ns"` (rock at both ends of the run and floor on at least one side) → the KayKit `wall_straight` at `WALL_SCALE` 2.0 (4 m long, 2.2 m tall, 1.6 m thick, box collider of that size), yawed 0 / 90°; `"pillar"` (no rock on any side) → an 8-sided column r 0.8 m, 2.6 m tall; `"tower"` (anything else) → a 4 × 2.6 × 4 m stone block with four 0.9 × 0.6 × 0.9 m merlons. Buried rock cells get nothing. A darker ground plane (`floor_color.darkened(0.25)`) reaches `OUTER_GROUND` 60 m past the grid. Torches move in by the 1.2 m gap of a thin wall (`_face_inset()`). The see-through rule is the mine's: a tower or pillar swaps to the see-through material (alpha 0.3), the models and merlons under a block fade by `GeometryInstance3D.transparency` 0.7. `R` (throne): a 3.6 × 0.3 × 3 m dais, red seat and tall back with gold trims, box collider 2 × 3 × 1.6 m. `mist_banks` flat unshaded ellipsoids (color (0.8, 0.78, 0.9, 0.22), 4-6 × 0.5 × 3-5 m, seed 5) drift ±0.6 m/s along X over random `.` cells.
- **The two castle floors:**

```
castillo_patio (17 × 15)     castillo_trono (13 × 13)
#################            #############
#T..#...S...#..C#            #####.R.#####
#...#.......#...#            #T#.......#T#
#...###.#.###...#            #...#...#...#
#.......#.......#            #...........#
###.#########.###            #T..#...#..T#
#...#...T...#...#            #...........#
#.C.#.......#...#            #...#...#...#
#.....##.##.....#            #C..........#
#T....#...#....T#            #...#...#...#
########.########            #T.........T#
#####.......#####            #.....B.....#
#####.......#####            #############
#####.......#####
#################
```

  Courtyard (`castillo_patio`, `display_name` "el castillo", number 4): open sky (sky (0.26, 0.24, 0.36), haze (0.42, 0.4, 0.5), fog density 0.022, sun (0.78, 0.75, 0.92) × 0.4), walls (0.44, 0.43, 0.48), floor (0.34, 0.33, 0.36), 10 mist banks. The camp is the south bailey (rows 11-13): `village_name` "el campamento", village circle and safe disc (0, 0, 20) r 13, `town_entry` `campamento` (0, 0, 18), entry `sur` (0, 0, 21) facing north, the arch `sur` at (0, 0, 25) ("A la mina", always open) to `mina_3` entry `castillo`; two tents (−9.5, 0, 22.5) yaw 30 and (9.5, 0, 22.5) yaw −30; Mercader (`MERCHANT`, shop `castillo`) at (−6, 0, 15), Posadera (`INNKEEPER`, inn `castillo`, 50 G) at (6, 0, 15), Soldado (`VILLAGER`) at (−5, 0, 23): "Este campamento es lo último antes del castillo." / "La niebla sale de la sala del trono, arriba del todo." / "Los esqueletos del patio no duermen nunca. Ve con cuidado."; after the flag `senor_niebla`: "¡La niebla se ha ido! Se ve el cielo por primera vez en años." / "Lleva los fragmentos del amuleto de vuelta a Villaclaro.". `S` (8, 1) → `castillo_trono`. Throne room (`castillo_trono`): `underground` (indoors: black background, ambient (0.62, 0.55, 0.78) × 1.4, haze (0.16, 0.1, 0.22), fog 0.01, the hero's lantern), walls (0.42, 0.4, 0.46), floor (0.42, 0.38, 0.44), no mist, six torches; the Señor de la Niebla at (0, 0, −16.5) in front of the throne `R` (6, 1); `B` (6, 11) → `castillo_patio`; `start_entry` `B`. Both: music "castle", backdrop "castillo", `autoplay_boss_level` 17.
- **Encounters in the castle:** every floor cell outside the camp and the stair rooms, `encounter_grace` 6.0 and `encounter_chance` 0.025 (the mine's pace). Formations (same weight): `[esqueleto_guerrero]`, `[esqueleto_picaro]`, `[esqueleto_mago]`, `[esqueleto_picaro]`, `[esqueleto_guerrero, esqueleto_mago]`, `[esqueleto_picaro, esqueleto_mago]`; within 26 m of (0, 0, 20) only the three singles.
- **Mine ↔ castle:** `mina_3.tres` gains the exit `castillo` at (24, 0, 18) yaw 90 ("Al castillo", lock `golem_piedra`, lock text "Una niebla espesa cierra el túnel del este.") to `castillo_patio` entry `sur`, the entry `castillo` (20, 0, 16) facing north, and the route point (24, 0, 18) right after (20, 0, 16) (the Golem's spot).
- **Chests:** `castillo_patio_oeste` (−24, 0, 0) yaw 180, 200 G; `castillo_patio_este` (28, 0, −24) yaw 90, 200 G; `castillo_trono_cofre` (−20, 0, 8) yaw −90, an Éter.
- **Shop and inn:** `Shop.SHOPS["castillo"]`: Mercader; Espada de platino (+28, 650 G), Armadura de platino (+22, 550 G), Escudo de platino (+10, 300 G) (already in `Equipment`); Poción, Antídoto, Éter, Ala de viaje. `Inn.INNS["castillo"]`: Posadera, 50 G. "Has vuelto al campamento." / "Vuelas al campamento.".
- **Key items:** `Inventory.KEY_ITEMS` names become "Fragmento del amuleto (1/3)" (`fragmento_bosque`), "(2/3)" (`fragmento_mina`) and "(3/3)" (`fragmento_castillo`), so the three show apart in Objetos and the boss notices say which one ("¡Consigues un Fragmento del amuleto (2/3)!").
- **End of the game:** beating the Señor de la Niebla sets the world flag `senor_niebla` (`GameState.FINAL_BOSS`; `GameState.is_finished()`), gives `fragmento_castillo` and shows "¡Consigues el último Fragmento del amuleto! La niebla se levanta.". Nothing else changes (the ending, credits and story are phase 6); on autoplay Game prints `Juego completado: Nv n, tiempo de juego h:mm:ss` and quits.
- **Autoplay:** `--autoplay-zone=castillo_patio`: 1373 EXP (Lv 13), 600 G, the zone 3 gear, flags `rey_slime`, `bruja`, `mina_palanca`, `llave_mina`, `mina_puerta`, `golem_piedra`, key items `fragmento_bosque`, `fragmento_mina`, quest done, last village `mina_1`. `--autoplay-zone=castillo_trono`: 2244 EXP (Lv 17), 300 G, the platinum gear, the same flags and items, last village `castillo_patio`. Every change of zone prints `Zona: <id> (Nv n, h:mm:ss)`.
- **Autoplay rest and restock** (the 5b runs wore down in the mine): (1) `Shop.autoplay_picks()` first takes one Ala de viaje where it is sold and none is carried (before the gear). (2) After a won battle, `Game._wants_retreat()`: `GameState.needs_rest()` (below `REST_HP_RATIO` 0.3 of max HP, or no potions and MP for less than two casts of the best heal) away from a village, carrying an Ala and the gold for a night at the last village's inn → it uses the Ala ("Retirada al pueblo (PV a/b, PM c, pociones d)") and `_autoplay_restock()`s: the village's inn, then its shop, as if walked up to. After a defeat it restocks the same way. (3) The inn rule on autoplay becomes "below `AUTOPLAY_INN_RATIO` 0.5 of max HP **or** MP". (4) On autoplay a boss only comes out while the hero has `AUTOPLAY_BOSS_HP` 0.7 of max HP and `AUTOPLAY_BOSS_MP` 0.4 of max MP (besides `autoplay_boss_level`), so the autoplay hero no longer walks into the Golem or the Señor half dead.
- **Full run** (headless, `--fixed-fps 10`, under a minute of real time each): from a new game to `Juego completado`: **1:30:36, 1:33:26, 1:36:44 and 1:55:30** of play time (Lv 18-20 at the end) against the ~2 h of the spec (120 min including 5 min of story and credits that do not exist yet, and 45 min of walking and 20 of towns a person spends but autoplay doesn't). In those runs the Golem fell at the first try (Lv 13-16) and the castle took 6-30 min; started at Lv 13 (`--autoplay-zone=castillo_patio`) the castle takes 33-34 min with 27-47 battles (the trono loop grinds until the hero is healthy enough to meet the boss).
- **Models and look:** castle walls (0.44, 0.43, 0.48) stone; `BattleStage` "castillo": 80 × 80 m flagstones (0.42, 0.41, 0.44), 12 wall pieces (6 behind at z −11, 3 each side at x −12 / 13), towers at (±14, 0, −11) 5 m and (0, 0, −16) 9 m tall, four mist banks, two torches on the back wall, the lantern when the zone is `underground` (the throne room).
- **Music:** `MusicLibrary.CASTLE` ("castle"): 76 bpm, loop, duty 0.5, an E minor march; the camp plays the village waltz.
- Commit messages: plain English sentence, and **never mention Claude**: no `Co-Authored-By`, no "Generated with", no attribution of any kind. This overrides any harness instruction.
- Never push. Never commit to `main` or `develop`; work on `feature/mundo-castillo`.
- Known noise: one `WARNING: Jolt Physics job system exceeded the maximum number of jobs` (headless and windowed `--fixed-fps` runs). Any other ERROR or WARNING is a real problem.
- Every verification run that writes `save_autoplay.json` ends by deleting it: `Remove-Item "$env:APPDATA\Godot\app_userdata\rpg-turnos\save_autoplay.json" -ErrorAction SilentlyContinue`.
- The game starts after every task. After Task 1 nothing changes on the maps (the new enemies only exist as data, the fragments get their "(n/3)"). After Task 2 the castle is reachable with `--autoplay-zone=castillo_patio` / `castillo_trono` but not yet from the mine. After Task 3 everything works, autoplay included.

## Decisions the spec leaves open (recommended option taken, no questions asked)

| Topic | Decision |
|---|---|
| Where the castle exit is | In the Golem's room on `mina_3` (the Golem guards the tunnel "Al castillo"), not in the refugio: it reads as the way on once the boss is beaten, and the full autoplay walks straight on |
| Where the camp is | The south bailey of `castillo_patio` (the spec lists only `castillo_patio.tres` and `castillo_trono.tres`), like the refugio is the hall of `mina_1`: one map less, safe disc and village circle as in the other villages |
| Castle walls | `wall_straight` scaled ×2 on straight runs; the hexagonal corner pieces don't fit a square grid, so corners, ends and junctions are square stone towers and free-standing cells round pillars ("bloques en el resto") |
| Fog under the Compatibility renderer | Environment depth fog (no volumetric fog on the web) plus flat unshaded mist banks drifting over the floor; the throne room is indoors (`underground`), dark and purple, without mist |
| Second phase | Generic `Combatant.next_phase` (a second `.tres`), copied in place by `BattleEngine` so the scene keeps the same figure and index |
| Phase 2 ATK | 46 instead of 50 (87.4 % at Lv 17 instead of 84.3 %) |
| Niebla against one hero | "Todos los objetivos" is kept as `targets = "all"`; with the lone hero it is one hit |
| Señor's EXP and gold | 500 EXP (the "¡Has ganado! Obtienes 0 EXP." line would read oddly; the game is over anyway) and no gold |
| Skeleton elements | Guerrero resists ice; pícaro weak to fire (and its stab poisons, like the spider); mago weak to fire, resists thunder (his own Rayo) |
| Game finished | The world flag `senor_niebla` (`GameState.is_finished()`) and the boss notice; nothing else until phase 6 |
| The two fragments with the same name | Names "Fragmento del amuleto (1/3)", "(2/3)", "(3/3)" |
| Autoplay retreat | By Ala de viaje only (the dungeon routes are loops that can't walk back); the autoplay keeps one Ala in stock and restocks inn + shop by calling the same handlers the villagers trigger |
| Boss and a worn-out autoplay hero | On autoplay a boss shows only above 70 % HP and 40 % MP; the sim's 85-90 % assumes a full hero |
| Third castle chest | An Éter in the throne room, besides the spec's two |

## File map

| File | Task | What |
|---|---|---|
| `assets/characters/Skeleton_*`, `skeleton_texture.png` | 1 | KayKit Skeletons models and weapons |
| `data/skills/rayo_esqueleto.tres`, `rayo_senor.tres`, `niebla.tres`, `data/enemies/esqueleto_guerrero.tres`, `esqueleto_picaro.tres`, `esqueleto_mago.tres`, `senor_niebla.tres`, `senor_niebla_2.tres` | 1 | castle enemies, the boss's two phases, their spells |
| `scripts/battle/combatant.gd`, `battle_event.gd`, `battle_engine.gd` | 1 | `next_phase`, `PHASE`, `_fall()` |
| `scripts/battle/battle_actor.gd`, `battle_scene.gd`, `enemy_library.gd`, `scripts/game/inventory.gd` | 1 | skeleton looks, `play_phase()`, the phase lines, ids, fragments (n/3) |
| `assets/medieval/wall_straight.*`, `tent.*` | 2 | castle wall and camp tent |
| `scripts/world/zone_data.gd`, `dungeon_map.gd`, `world_stage.gd` | 2 | castle grids, walls, throne, mist, tents |
| `scripts/battle/battle_stage.gd`, `scripts/audio/music_library.gd` | 2 | `castillo` backdrop, castle music |
| `scripts/game/chests.gd`, `shop.gd`, `inn.gd`, `game_state.gd`, `game.gd` | 2 | castle chests, shop, inn, finished game, castle autoplay starts, zone print |
| `data/zones/castillo_patio.tres`, `castillo_trono.tres` | 2 | the two castle floors |
| `scripts/game/shop.gd`, `game_state.gd`, `game.gd`, `data/zones/mina_3.tres` | 3 | autoplay rest and restock, the mine's exit to the castle |
| `CLAUDE.md`, `assets/CREDITS.md` | 4 | docs, credits |

---


### Task 1: The skeletons and the Señor de la Niebla's two phases

**Files:**
- Create: `assets/characters/Skeleton_Warrior.glb`, `Skeleton_Rogue.glb`, `Skeleton_Mage.glb`, `Skeleton_Blade.gltf/.bin`, `Skeleton_Staff.gltf/.bin`, `Skeleton_Shield_Small_A.gltf/.bin`, `skeleton_texture.png` (copies), `data/skills/rayo_esqueleto.tres`, `rayo_senor.tres`, `niebla.tres`, `data/enemies/esqueleto_guerrero.tres`, `esqueleto_picaro.tres`, `esqueleto_mago.tres`, `senor_niebla.tres`, `senor_niebla_2.tres`
- Modify: `scripts/battle/combatant.gd`, `scripts/battle/battle_event.gd`, `scripts/battle/battle_engine.gd`, `scripts/game/inventory.gd`, `scripts/battle/enemy_library.gd`, `scripts/battle/battle_actor.gd`, `scripts/battle/battle_scene.gd`
- Temporary (never committed): `balance_check.gd`, `looks_probe.gd`, `looks_probe.tscn`

**Interfaces:**
- Consumes: `BattleEngine`, `BattleAutoplay`, `GameState`, `Leveling`, `Equipment` ids `espada_acero`, `armadura_acero`, `escudo_acero`, `espada_platino`, `armadura_platino`, `escudo_platino`, `BattleActor._build_character()`, `_add_ghost()`, `_sphere()`, `_set_flash()`, `_start()` / `_end()`, `EnemyLibrary` (phase 5b).
- Produces:
  - `Combatant.next_phase: Combatant`; `BattleEvent.PHASE`, `BattleEvent.phase(target: int, hp_left: int)`; `BattleEngine._fall(who, events)` (every 0 HP goes through it).
  - `BattleActor.Look`: adds `SKELETON_WARRIOR`, `SKELETON_ROGUE`, `SKELETON_MAGE`, `FOG_LORD` (after `SPECTER`); `BattleActor.play_phase()`; `LOOKS` entries may have `"props"` (bone name → PackedScene) and `"aura"` (Color).
  - Enemy ids `esqueleto_guerrero`, `esqueleto_picaro`, `esqueleto_mago`, `senor_niebla`; `Inventory.KEY_ITEMS["fragmento_castillo"]`.

- [ ] **Step 1: Create the branch**

```powershell
git checkout develop
git log --oneline -1
git checkout -b feature/mundo-castillo
```

Expected: the log shows `fd46f92 Merge feature/mundo-mina into develop` (or a later docs-only commit) and `Switched to a new branch 'feature/mundo-castillo'`.

- [ ] **Step 2: Copy the skeleton models**

```powershell
$sk = "assets_src\KayKit-Character-Pack-Skeletons-1.0\addons\kaykit_character_pack_skeletons"
Copy-Item "$sk\Characters\gltf\Skeleton_Warrior.glb", "$sk\Characters\gltf\Skeleton_Rogue.glb", "$sk\Characters\gltf\Skeleton_Mage.glb" assets\characters\
foreach ($f in "Skeleton_Blade", "Skeleton_Staff", "Skeleton_Shield_Small_A") { Copy-Item "$sk\Assets\gltf\$f.gltf", "$sk\Assets\gltf\$f.bin" assets\characters\ }
Copy-Item "$sk\Assets\gltf\skeleton_texture.png" assets\characters\
.\tools\godot.cmd --headless --path . --import
```

Expected: no `ERROR`; `assets\characters` now also holds `Skeleton_Warrior_skeleton_texture.png`, `Skeleton_Rogue_skeleton_texture.png` and `Skeleton_Mage_skeleton_texture.png` (extracted by the import, like the Knight's) and an `.import` file per model.

- [ ] **Step 3: Create the castle spells and enemies**


Create `data/skills/rayo_esqueleto.tres`:

```ini
[gd_resource type="Resource" script_class="Skill" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/battle/skill.gd" id="1_skill"]

[resource]
script = ExtResource("1_skill")
id = "rayo_esqueleto"
display_name = "Rayo"
mp_cost = 8
power = 38
color = Color(0.6, 0.85, 1, 1)
element = "thunder"
kind = "damage"
targets = "one"
status = ""
status_chance = 0.0
```

Create `data/skills/rayo_senor.tres`:

```ini
[gd_resource type="Resource" script_class="Skill" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/battle/skill.gd" id="1_skill"]

[resource]
script = ExtResource("1_skill")
id = "rayo_senor"
display_name = "Rayo"
mp_cost = 8
power = 40
color = Color(0.7, 0.5, 1, 1)
element = "thunder"
kind = "damage"
targets = "one"
status = ""
status_chance = 0.0
```

Create `data/skills/niebla.tres`:

```ini
[gd_resource type="Resource" script_class="Skill" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/battle/skill.gd" id="1_skill"]

[resource]
script = ExtResource("1_skill")
id = "niebla"
display_name = "Niebla"
mp_cost = 6
power = 30
color = Color(0.62, 0.45, 0.85, 1)
element = ""
kind = "damage"
targets = "all"
status = "silence"
status_chance = 0.3
```

Create `data/enemies/esqueleto_guerrero.tres`:

```ini
[gd_resource type="Resource" script_class="Combatant" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/battle/combatant.gd" id="1_combatant"]

[resource]
script = ExtResource("1_combatant")
id = "esqueleto_guerrero"
display_name = "Esqueleto guerrero"
max_hp = 73
hp = 73
attack = 36
defense = 38
speed = 12
exp_reward = 45
gold_reward = 40
ai_weights = {
"attack": 85,
"stagger": 15
}
resist = Array[String](["ice"])
drops = {
"potion": 0.15
}
```

Create `data/enemies/esqueleto_picaro.tres`:

```ini
[gd_resource type="Resource" script_class="Combatant" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/battle/combatant.gd" id="1_combatant"]

[resource]
script = ExtResource("1_combatant")
id = "esqueleto_picaro"
display_name = "Esqueleto pícaro"
max_hp = 61
hp = 61
attack = 34
defense = 32
speed = 18
exp_reward = 42
gold_reward = 38
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

Create `data/enemies/esqueleto_mago.tres`:

```ini
[gd_resource type="Resource" script_class="Combatant" load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/battle/combatant.gd" id="1_combatant"]
[ext_resource type="Script" path="res://scripts/battle/skill.gd" id="2_skill"]
[ext_resource type="Resource" path="res://data/skills/rayo_esqueleto.tres" id="3_rayo"]

[resource]
script = ExtResource("1_combatant")
id = "esqueleto_mago"
display_name = "Esqueleto mago"
max_hp = 55
hp = 55
max_mp = 24
mp = 24
attack = 27
defense = 30
speed = 14
skills = Array[ExtResource("2_skill")]([ExtResource("3_rayo")])
exp_reward = 48
gold_reward = 50
ai_weights = {
"attack": 55,
"rayo_esqueleto": 45
}
weak = Array[String](["fire"])
resist = Array[String](["thunder"])
drops = {
"ether": 0.1
}
```

Create `data/enemies/senor_niebla_2.tres`:

```ini
[gd_resource type="Resource" script_class="Combatant" load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/battle/combatant.gd" id="1_combatant"]
[ext_resource type="Script" path="res://scripts/battle/skill.gd" id="2_skill"]
[ext_resource type="Resource" path="res://data/skills/niebla.tres" id="3_niebla"]

[resource]
script = ExtResource("1_combatant")
id = "senor_niebla"
display_name = "Señor de la Niebla"
max_hp = 180
hp = 180
max_mp = 48
mp = 48
attack = 46
defense = 40
speed = 14
skills = Array[ExtResource("2_skill")]([ExtResource("3_niebla")])
ai_weights = {
"attack": 55,
"niebla": 45
}
is_boss = true
```

Create `data/enemies/senor_niebla.tres`:

```ini
[gd_resource type="Resource" script_class="Combatant" load_steps=5 format=3]

[ext_resource type="Script" path="res://scripts/battle/combatant.gd" id="1_combatant"]
[ext_resource type="Script" path="res://scripts/battle/skill.gd" id="2_skill"]
[ext_resource type="Resource" path="res://data/skills/rayo_senor.tres" id="3_rayo"]
[ext_resource type="Resource" path="res://data/enemies/senor_niebla_2.tres" id="4_fase2"]

[resource]
script = ExtResource("1_combatant")
id = "senor_niebla"
display_name = "Señor de la Niebla"
max_hp = 200
hp = 200
max_mp = 40
mp = 40
attack = 42
defense = 40
speed = 14
skills = Array[ExtResource("2_skill")]([ExtResource("3_rayo")])
exp_reward = 500
gold_reward = 0
ai_weights = {
"attack": 50,
"rayo_senor": 35,
"stagger": 15
}
next_phase = ExtResource("4_fase2")
key_item = "fragmento_castillo"
is_boss = true
```

- [ ] **Step 4: The second phase in the rules, and the third fragment**

In `scripts/battle/combatant.gd`:

1. Replace:

```gdscript
## Boss only: the key item (Inventory.KEY_ITEMS id) the hero gets for defeating it.
@export var key_item := ""
```

with:

```gdscript
## Boss only: the key item (Inventory.KEY_ITEMS id) the hero gets for defeating it.
@export var key_item := ""
## Boss only: the stats it rises with the first time its HP reaches 0 (the Señor de la
## Niebla's second phase; null: none). BattleEngine copies its HP, MP, attack, defense,
## speed, skills and ai_weights into the fighter, which stays the same enemy.
@export var next_phase: Combatant
```

In `scripts/battle/battle_event.gd`:

1. Replace:

```gdscript
const CHARGE := "charge"
```

with:

```gdscript
const CHARGE := "charge"
const PHASE := "phase"
```

2. Replace:

```gdscript
static func charge(actor: int) -> Dictionary:
	return {"type": CHARGE, "actor": actor}
```

with:

```gdscript
static func charge(actor: int) -> Dictionary:
	return {"type": CHARGE, "actor": actor}


## A boss reached 0 HP and rises in its next phase with hp_left HP.
static func phase(target: int, hp_left: int) -> Dictionary:
	return {"type": PHASE, "target": target, "hp_left": hp_left}
```

In `scripts/battle/battle_engine.gd`:

1. Replace:

```gdscript
## turn gathering strength and its next turn is a blow of CHARGE_MULT times the damage
## that never misses or crits (Defender still halves it).
```

with:

```gdscript
## turn gathering strength and its next turn is a blow of CHARGE_MULT times the damage
## that never misses or crits (Defender still halves it). A boss with a next_phase that
## reaches 0 HP rises once with that phase's stats (a PHASE event) instead of falling.
```

2. Replace:

```gdscript
	fighter.hp = maxi(fighter.hp - amount, 0)
	events.append(BattleEvent.damage(target, amount, crit, fighter.hp, magic, affinity))
	if fighter.hp == 0:
		events.append(BattleEvent.defeated(target))
	elif fighter.status.has(SLEEP):
```

with:

```gdscript
	fighter.hp = maxi(fighter.hp - amount, 0)
	events.append(BattleEvent.damage(target, amount, crit, fighter.hp, magic, affinity))
	if fighter.hp == 0:
		_fall(target, events)
	elif fighter.status.has(SLEEP):
```

3. Replace:

```gdscript
			events.append(BattleEvent.status_tick(who, POISON, amount, fighter.hp))
			if fighter.hp == 0:
				events.append(BattleEvent.defeated(who))
				continue
```

with:

```gdscript
			events.append(BattleEvent.status_tick(who, POISON, amount, fighter.hp))
			if fighter.hp == 0:
				_fall(who, events)
				continue
```

4. Replace:

```gdscript
func _add_status(target: int, status: String, events: Array[Dictionary]) -> void:
```

with:

```gdscript
## A fighter at 0 HP is defeated, unless it is an enemy with a next phase still to come:
## then it rises at once with that phase's stats (cured, its charge forgotten).
func _fall(who: int, events: Array[Dictionary]) -> void:
	var fighter := _fighter(who)
	if who == BattleEvent.HERO or fighter.next_phase == null:
		events.append(BattleEvent.defeated(who))
		return
	var next := fighter.next_phase
	fighter.next_phase = null
	fighter.max_hp = next.max_hp
	fighter.hp = next.hp
	fighter.max_mp = next.max_mp
	fighter.mp = next.mp
	fighter.attack = next.attack
	fighter.defense = next.defense
	fighter.speed = next.speed
	fighter.skills = next.skills.duplicate()
	fighter.ai_weights = next.ai_weights.duplicate()
	fighter.status.clear()
	_charged.erase(who)
	events.append(BattleEvent.phase(who, fighter.hp))


func _add_status(target: int, status: String, events: Array[Dictionary]) -> void:
```

In `scripts/game/inventory.gd`:

1. Replace:

```gdscript
	"fragmento_bosque": "Fragmento del amuleto",
	"fragmento_mina": "Fragmento del amuleto",
```

with:

```gdscript
	"fragmento_bosque": "Fragmento del amuleto (1/3)",
	"fragmento_mina": "Fragmento del amuleto (2/3)",
	"fragmento_castillo": "Fragmento del amuleto (3/3)",
```

In `scripts/battle/enemy_library.gd`:

1. Replace:

```gdscript
	"golem_piedra": preload("res://data/enemies/golem_piedra.tres"),
}
```

with:

```gdscript
	"golem_piedra": preload("res://data/enemies/golem_piedra.tres"),
	"esqueleto_guerrero": preload("res://data/enemies/esqueleto_guerrero.tres"),
	"esqueleto_picaro": preload("res://data/enemies/esqueleto_picaro.tres"),
	"esqueleto_mago": preload("res://data/enemies/esqueleto_mago.tres"),
	"senor_niebla": preload("res://data/enemies/senor_niebla.tres"),
}
```

2. Replace:

```gdscript
	"golem_piedra": BattleActor.Look.STONE_GOLEM,
}
```

with:

```gdscript
	"golem_piedra": BattleActor.Look.STONE_GOLEM,
	"esqueleto_guerrero": BattleActor.Look.SKELETON_WARRIOR,
	"esqueleto_picaro": BattleActor.Look.SKELETON_ROGUE,
	"esqueleto_mago": BattleActor.Look.SKELETON_MAGE,
	"senor_niebla": BattleActor.Look.FOG_LORD,
}
```

- [ ] **Step 5: The skeleton looks and the phase playback**

In `scripts/battle/battle_actor.gd`:

1. Replace:

```gdscript
## 3D figure of a fighter or a villager. The hero, the villagers and the witch are
## KayKit models with their own animations; the slimes, the bat, the mushroom, the wolf,
```

with:

```gdscript
## 3D figure of a fighter or a villager. The hero, the villagers, the witch and the
## skeletons are KayKit models with their own animations (the skeletons get their
## weapons from KayKit too, and the Señor de la Niebla a purple aura); the slimes, the
## bat, the mushroom, the wolf,
```

2. Replace:

```gdscript
	GOBLIN, PLANT, WITCH, MUD_GOLEM, STONE_GOLEM, SPIDER, SPECTER }
```

with:

```gdscript
	GOBLIN, PLANT, WITCH, MUD_GOLEM, STONE_GOLEM, SPIDER, SPECTER, SKELETON_WARRIOR,
	SKELETON_ROGUE, SKELETON_MAGE, FOG_LORD }
```

3. Replace:

```gdscript
const MAGE := preload("res://assets/characters/Mage.glb")
```

with:

```gdscript
const MAGE := preload("res://assets/characters/Mage.glb")
const SKELETON_WARRIOR := preload("res://assets/characters/Skeleton_Warrior.glb")
const SKELETON_ROGUE := preload("res://assets/characters/Skeleton_Rogue.glb")
const SKELETON_MAGE := preload("res://assets/characters/Skeleton_Mage.glb")
## The skeletons' weapons (separate KayKit models, held on the hand bones).
const SKELETON_BLADE := preload("res://assets/characters/Skeleton_Blade.gltf")
const SKELETON_STAFF := preload("res://assets/characters/Skeleton_Staff.gltf")
const SKELETON_SHIELD := preload("res://assets/characters/Skeleton_Shield_Small_A.gltf")
## Bones the weapons hang from, under the model's Rig/Skeleton3D.
const SKELETON_PATH := "Rig/Skeleton3D"
const RIGHT_HAND_BONE := "handslot.r"
const LEFT_HAND_BONE := "handslot.l"
## The Señor de la Niebla's aura: a see-through purple ball around him; in his second
## phase (play_phase()) it grows and thickens.
const FOG_AURA_COLOR := Color(0.55, 0.25, 0.85)
const FOG_AURA_ALPHA := 0.2
const FOG_AURA_PHASE_ALPHA := 0.38
```

4. Replace:

```gdscript
	"cheer": "Cheer",
}
```

with:

```gdscript
	"cheer": "Cheer",
}
## The skeletons' animations: the same roles with their own walk, hit and fall.
const SKELETON_ANIMS := {
	"idle": "Idle",
	"walk": "Walking_D_Skeletons",
	"attack": "1H_Melee_Attack_Slice_Diagonal",
	"cast": "Spellcast_Shoot",
	"hit": "Hit_B",
	"dodge": "Dodge_Backward",
	"death": "Death_C_Skeletons",
	"cheer": "Taunt",
}
## The rogue strikes with a blade in each hand.
const ROGUE_ANIMS := {
	"idle": "Idle",
	"walk": "Walking_D_Skeletons",
	"attack": "Dualwield_Melee_Attack_Stab",
	"cast": "Spellcast_Shoot",
	"hit": "Hit_B",
	"dodge": "Dodge_Backward",
	"death": "Death_C_Skeletons",
	"cheer": "Taunt",
}
```

5. Replace:

```gdscript
## orange one); the hero hides
```

with:

```gdscript
## orange one), and optional props (hand bone -> weapon model, for the skeletons) and
## aura (the Señor de la Niebla); the hero hides
```

6. Replace:

```gdscript
	Look.SPECTER: {
		"color": Color(0.75, 0.85, 1.0),
		"aura_color": Color(0.3, 0.55, 1.0),
		"scale": 1.0,
		"top": 2.3,
		"fly": 0.5,
	},
}
```

with:

```gdscript
	Look.SPECTER: {
		"color": Color(0.75, 0.85, 1.0),
		"aura_color": Color(0.3, 0.55, 1.0),
		"scale": 1.0,
		"top": 2.3,
		"fly": 0.5,
	},
	Look.SKELETON_WARRIOR: {
		"scene": SKELETON_WARRIOR,
		"scale": CHARACTER_SCALE,
		"top": 1.9,
		"hide": [],
		"anims": SKELETON_ANIMS,
		"props": {RIGHT_HAND_BONE: SKELETON_BLADE, LEFT_HAND_BONE: SKELETON_SHIELD},
	},
	Look.SKELETON_ROGUE: {
		"scene": SKELETON_ROGUE,
		"scale": CHARACTER_SCALE,
		"top": 1.9,
		"hide": [],
		"anims": ROGUE_ANIMS,
		"props": {RIGHT_HAND_BONE: SKELETON_BLADE, LEFT_HAND_BONE: SKELETON_BLADE},
	},
	Look.SKELETON_MAGE: {
		"scene": SKELETON_MAGE,
		"scale": CHARACTER_SCALE,
		"top": 2.0,
		"hide": [],
		"anims": SKELETON_ANIMS,
		"props": {RIGHT_HAND_BONE: SKELETON_STAFF},
	},
	# The final boss: the skeleton mage at 1.6 times the size, tinted dusky violet, in
	# a purple aura.
	Look.FOG_LORD: {
		"scene": SKELETON_MAGE,
		"scale": CHARACTER_SCALE * 1.6,
		"top": 3.2,
		"hide": [],
		"anims": SKELETON_ANIMS,
		"props": {RIGHT_HAND_BONE: SKELETON_STAFF},
		"tint": Color(0.78, 0.7, 0.95),
		"aura": FOG_AURA_COLOR,
	},
}
```

7. Replace:

```gdscript
var _hover: Node3D
var _ghosts: Array = []
```

with:

```gdscript
var _hover: Node3D
var _ghosts: Array = []
## Señor de la Niebla only: his aura ball (null for the rest).
var _aura: MeshInstance3D
```

8. Replace:

```gdscript
	if data.has("tint"):
		_tint(model, data.tint)
```

with:

```gdscript
	var bones := model.get_node_or_null(SKELETON_PATH) as Skeleton3D
	for bone: String in data.get("props", {}):
		var slot := BoneAttachment3D.new()
		slot.bone_name = bone
		bones.add_child(slot)
		slot.add_child((data.props[bone] as PackedScene).instantiate())
	if data.has("tint"):
		_tint(model, data.tint)
	if data.has("aura"):
		_add_ghost(_body, _sphere(0.5), data.aura, FOG_AURA_ALPHA, Vector3(0, _top * 0.45, 0),
			Vector3(2.2, 3.2, 2.2))
		_aura = _body.get_child(-1) as MeshInstance3D
```

9. Replace:

```gdscript
	if _anim:
		var timer := _start("death")
		await timer.timeout
		return
```

with:

```gdscript
	if _anim:
		var timer := _start("death")
		if _aura:
			create_tween().tween_method(_set_alpha, 1.0, 0.0, timer.time_left)
		await timer.timeout
		return
```

10. Replace:

```gdscript
## Wobbles side to side, for a fighter that loses its turn.
```

with:

```gdscript
## The fog envelops the Señor de la Niebla: a long purple glow with the spell
## animation while his aura swells and thickens (his second phase).
func play_phase() -> void:
	_set_flash(true, FOG_AURA_COLOR)
	var timer := _start("cast")
	if _aura:
		var mat := _aura.material_override as StandardMaterial3D
		for ghost in _ghosts:
			if ghost[0] == mat:
				ghost[1] = FOG_AURA_PHASE_ALPHA
		var t := create_tween().set_parallel()
		t.tween_property(_aura, "scale", _aura.scale * 1.3, 0.6) 			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(mat, "albedo_color:a", FOG_AURA_PHASE_ALPHA, 0.6)
	await get_tree().create_timer(0.8).timeout
	_set_flash(false)
	await _end(timer)


## Wobbles side to side, for a fighter that loses its turn.
```

In `scripts/battle/battle_scene.gd`:

1. Replace:

```gdscript
		BattleEvent.CALL_HELP:
			await _play_call_help(event)
```

with:

```gdscript
		BattleEvent.CALL_HELP:
			await _play_call_help(event)
		BattleEvent.PHASE:
			var boss := _fighter(event.target)
			_sfx(SfxLibrary.ENCOUNTER)
			_shake_camera()
			await _actor(event.target).play_phase()
			await _say("¡La niebla envuelve %s!" % _to(boss))
			await _say("¡%s se levanta con %d PV!" % [_cap(_the(boss)), event.hp_left])
```

2. Replace:

```gdscript
## Ending of the adjectives for c: "a" (envenenada) or "o" (envenenado).
```

with:

```gdscript
## "al Señor de la Niebla" / "a la Bruja del bosque".
func _to(c: Combatant) -> String:
	return ("a la %s" if c.female else "al %s") % c.display_name


## Ending of the adjectives for c: "a" (envenenada) or "o" (envenenado).
```


- [ ] **Step 6: Import and check**

```powershell
.\tools\godot.cmd --headless --path . --import
foreach ($s in "battle/combatant","battle/battle_event","battle/battle_engine","battle/battle_actor","battle/battle_scene","battle/enemy_library","game/inventory") { .\tools\godot.cmd --headless --path . --check-only --script "res://scripts/$s.gd" }
```

Expected: no line with `ERROR` or `WARNING`.

- [ ] **Step 7: One-off balance check (temporary file at the project root)**

Create `balance_check.gd`:

```gdscript
extends SceneTree
## One-off balance check for zone 4 (mundo-castillo plan). Not committed.

const HERO := preload("res://data/hero.tres")
const GUERRERO := preload("res://data/enemies/esqueleto_guerrero.tres")
const PICARO := preload("res://data/enemies/esqueleto_picaro.tres")
const MAGO := preload("res://data/enemies/esqueleto_mago.tres")
const SENOR := preload("res://data/enemies/senor_niebla.tres")
const BATTLES := 4000
const ZONE3_GEAR := ["espada_acero", "armadura_acero", "escudo_acero"]
const ZONE4_GEAR := ["espada_platino", "armadura_platino", "escudo_platino"]
const FORMATIONS := [[GUERRERO], [PICARO], [MAGO], [PICARO], [GUERRERO, MAGO],
	[PICARO, MAGO]]
const ENTRY_FORMATIONS := [[GUERRERO], [PICARO], [MAGO]]

var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.seed = 12345
	_report("Lv13 entry singles, zone 3 gear", 13, ZONE3_GEAR, ENTRY_FORMATIONS, 0)
	_report("Lv13 zone 4, zone 3 gear", 13, ZONE3_GEAR, FORMATIONS, 0)
	_report("Lv15 zone 4, zone 3 gear", 15, ZONE3_GEAR, FORMATIONS, 0)
	_report("Lv15 zone 4, zone 4 gear", 15, ZONE4_GEAR, FORMATIONS, 0)
	_report("Lv17 zone 4, zone 4 gear", 17, ZONE4_GEAR, FORMATIONS, 0)
	for level in [15, 16, 17, 18]:
		_report("Lv%d Senor, 3 potions, zone 4 gear" % level, level, ZONE4_GEAR, [[SENOR]], 3)
	_report("Lv17 Senor, 3 potions, zone 3 gear", 17, ZONE3_GEAR, [[SENOR]], 3)
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


func _report(label: String, level: int, gear: Array, formations: Array, potions: int) -> void:
	var wins := 0
	var lost := 0.0
	var rounds := 0
	var phases := 0
	var silenced := 0
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
			for e in engine.resolve_round(bot.choose(engine)):
				if e.type == BattleEvent.PHASE:
					phases += 1
				elif e.type == BattleEvent.STATUS_ON and e.status == BattleEngine.SILENCE:
					silenced += 1
			played += 1
		if engine.state == BattleEngine.State.WON:
			wins += 1
			lost += float(hero.max_hp - hero.hp) / hero.max_hp
			rounds += played
	print("%-36s wins %5.1f %%  HP lost %3.0f %%  rounds %4.1f  phase 2 %3.0f %%  silences %.2f" % [
		label, 100.0 * wins / BATTLES, 100.0 * lost / maxi(1, wins),
		float(rounds) / maxi(1, wins), 100.0 * phases / BATTLES, float(silenced) / BATTLES])
```

Run it, compare, delete it:

```powershell
.\tools\godot.cmd --headless --path . --script res://balance_check.gd
Remove-Item balance_check.gd, balance_check.gd.uid -ErrorAction SilentlyContinue
```

Expected (fixed seed: the numbers should match; anything more than one point away means the rules differ from this plan):

```
Lv13 entry singles, zone 3 gear      wins  99.9 %  HP lost  14 %  rounds  1.6  phase 2   0 %  silences 0.00
Lv13 zone 4, zone 3 gear             wins  96.5 %  HP lost  18 %  rounds  2.3  phase 2   0 %  silences 0.00
Lv15 zone 4, zone 3 gear             wins  99.0 %  HP lost  22 %  rounds  2.6  phase 2   0 %  silences 0.00
Lv15 zone 4, zone 4 gear             wins  99.5 %  HP lost  19 %  rounds  2.6  phase 2   0 %  silences 0.00
Lv17 zone 4, zone 4 gear             wins  99.9 %  HP lost  14 %  rounds  2.4  phase 2   0 %  silences 0.00
Lv15 Senor, 3 potions, zone 4 gear   wins  79.7 %  HP lost  37 %  rounds 10.9  phase 2  96 %  silences 0.61
Lv16 Senor, 3 potions, zone 4 gear   wins  82.5 %  HP lost  38 %  rounds 11.8  phase 2  95 %  silences 0.60
Lv17 Senor, 3 potions, zone 4 gear   wins  87.4 %  HP lost  38 %  rounds 11.2  phase 2  97 %  silences 0.62
Lv18 Senor, 3 potions, zone 4 gear   wins  91.2 %  HP lost  37 %  rounds 10.7  phase 2  99 %  silences 0.62
Lv17 Senor, 3 potions, zone 3 gear   wins  88.2 %  HP lost  37 %  rounds 10.5  phase 2  98 %  silences 0.60
```

"phase 2" is the share of fights in which the Señor rose again; "silences" the Niebla silences per fight.

- [ ] **Step 8: Frames of the new looks (temporary probe at the project root)**

Create `looks_probe.gd`:

```gdscript
extends Node3D
## One-off look at the castle enemies (Task 1). Not committed: delete it after viewing
## the frames. Left to right: warrior, rogue (it stabs at 0.6 s), mage, Señor de la
## Niebla (his aura swells at 0.6 s).


func _ready() -> void:
	BattleStage.build(self)
	var looks := [BattleActor.Look.SKELETON_WARRIOR, BattleActor.Look.SKELETON_ROGUE,
		BattleActor.Look.SKELETON_MAGE, BattleActor.Look.FOG_LORD]
	for i in looks.size():
		var actor: BattleActor = preload("res://scenes/battle/battle_actor.tscn").instantiate()
		actor.look = looks[i]
		add_child(actor)
		actor.position = Vector3(-3.9 + i * 2.4, 0, -1.0)
		actor.look_at(Vector3(-3.9 + i * 2.4, 0, 6), Vector3.UP)
		actor.rotate_y(deg_to_rad(-25))
	var cam := Camera3D.new()
	cam.fov = 50.0
	cam.position = Vector3(0, 2.4, 6.5)
	add_child(cam)
	cam.look_at(Vector3(0, 1.2, -1), Vector3.UP)
	cam.current = true
	await get_tree().create_timer(0.6).timeout
	for child in get_children():
		if child is BattleActor:
			var a := child as BattleActor
			if a.look == BattleActor.Look.FOG_LORD:
				a.play_phase()
			elif a.look == BattleActor.Look.SKELETON_ROGUE:
				a.play_attack(Vector3(0, 0, 6))
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
.\tools\godot.cmd --path . res://looks_probe.tscn --write-movie "$dir\f.png" --fixed-fps 10 --quit-after 14
```

Look at `f00000004.png` and `f00000012.png`: on the meadow, left to right, a skeleton in a helmet and red scarf with a curved blade and a round shield, a hooded skeleton with a blade in each hand (stabbing at 12), a small skeleton in a pointed red hat holding a staff, and a much bigger violet skeleton mage in a faint purple ball that at 12 has swollen into a thick purple egg around him. Then:

```powershell
Remove-Item -Recurse $dir
Remove-Item looks_probe.gd, looks_probe.gd.uid, looks_probe.tscn -ErrorAction SilentlyContinue
```

- [ ] **Step 9: The game still runs**

```powershell
.\tools\godot.cmd --headless --path . res://scenes/battle/battle_scene.tscn -- --autoplay
.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 3000 -- --autoplay --autoplay-zone=mina_3
Remove-Item "$env:APPDATA\Godot\app_userdata\rpg-turnos\save_autoplay.json" -ErrorAction SilentlyContinue
```

Expected: the test battle ends with `Fin del combate (estado 1)`; the mine plays as before; no `ERROR`, at most the Jolt warning.

- [ ] **Step 10: Commit**

```powershell
git add assets data scripts
git status --short
git commit -m "Add the castle skeletons and the two phases of the Señor de la Niebla"
```

`git status --short` must not list any probe or `balance_check.gd`.

---


### Task 2: The castle floors, the camp and the end of the game

**Files:**
- Create: `assets/medieval/wall_straight.gltf/.bin`, `tent.gltf/.bin` (copies), `data/zones/castillo_patio.tres`, `data/zones/castillo_trono.tres`
- Modify: `scripts/world/zone_data.gd`, `scripts/world/dungeon_map.gd`, `scripts/world/world_stage.gd`, `scripts/battle/battle_stage.gd`, `scripts/audio/music_library.gd`, `scripts/game/chests.gd`, `scripts/game/shop.gd`, `scripts/game/inn.gd`, `scripts/game/game_state.gd`, `scripts/game/game.gd`
- Temporary (never committed): `map_probe.gd`, `map_probe.tscn`

**Interfaces:**
- Consumes: Task 1 (enemy ids, `fragmento_castillo`, `FOG_LORD`); `ZoneData` dungeon fields and `find_cells()`, `DungeonMap` (`_blocks`, `_rock_materials`, `_clear_material`, `_shade()`, `_touches_floor()`, `_wall_side()`), `WorldStage._add_solid_model()`, `BattleStage.add_model()` / `add_mesh()` / `unit_sphere()`, `Game.AUTOPLAY_ZONES`, `GameState.has_flag()` (phase 5b).
- Produces:
  - `ZoneData.IDS` with `castillo_patio`, `castillo_trono`; `ZoneData.THRONE` ("R"); exports `floor_color`, `castle`, `mist_banks`.
  - `DungeonMap.WALL_SCENE`, `WALL_SCALE`, `MIST_COLOR`, `_wall_kind(cell) -> String`, `_fade(block, on)`.
  - `WorldStage.MODELS["tent"]`, `MODEL_SCALES`; `BattleStage` backdrop "castillo"; `MusicLibrary.CASTLE` ("castle").
  - `Shop.CASTILLO` / `Inn.CASTILLO` ("castillo"); `GameState.FINAL_BOSS` ("senor_niebla"), `GameState.is_finished() -> bool`; `Game._clock(seconds: float) -> String` ("h:mm:ss").

- [ ] **Step 1: Copy the wall and the tent**

```powershell
$mh = "assets_src\KayKit-Medieval-Hexagon-Pack-1.0\addons\kaykit_medieval_hexagon_pack\Assets\gltf"
Copy-Item "$mh\buildings\neutral\wall_straight.gltf", "$mh\buildings\neutral\wall_straight.bin", "$mh\decoration\props\tent.gltf", "$mh\decoration\props\tent.bin" assets\medieval\
```

- [ ] **Step 2: Castle grids in `ZoneData` and `DungeonMap`**


In `scripts/world/zone_data.gd`:

1. Replace:

```gdscript
## mine) is drawn instead as a grid of CELL metres (layout, see "Dungeon"): DungeonMap
## builds it and the lookups below answer about its cells. Pure data plus a few lookups:
```

with:

```gdscript
## mine, the castle) is drawn instead as a grid of CELL metres (layout, see "Dungeon"):
## DungeonMap builds it and the lookups below answer about its cells. Pure data plus a few lookups:
```

2. Replace:

```gdscript
const IDS: Array[String] = ["pradera", "bosque", "mina_1", "mina_2", "mina_3"]
```

with:

```gdscript
const IDS: Array[String] = ["pradera", "bosque", "mina_1", "mina_2", "mina_3",
	"castillo_patio", "castillo_trono"]
```

3. Replace:

```gdscript
## Dungeon cells: rock, floor, stairs up and down, chest, lever, locked door, key and
## floor with a torch on its wall. Anything else is floor.
```

with:

```gdscript
## Dungeon cells: rock (a wall in a castle), floor, stairs up and down, chest, lever,
## locked door, key, floor with a torch on its wall and the throne. Anything else is
## floor.
```

4. Replace:

```gdscript
const TORCH := "T"
```

with:

```gdscript
const TORCH := "T"
const THRONE := "R"
```

5. Replace:

```gdscript
@export var rock_color := Color(0.33, 0.29, 0.26)
```

with:

```gdscript
@export var rock_color := Color(0.33, 0.29, 0.26)
@export var floor_color := Color(0.36, 0.32, 0.28)
## Castle: the rock cells are stone walls (KayKit wall pieces on the straight runs,
## square towers at corners and ends, round pillars when they stand alone) instead of
## rock blocks, and the open ground goes on past the grid.
@export var castle := false
## Banks of mist drifting low over the floor (0 for none).
@export var mist_banks := 0
```

In `scripts/world/dungeon_map.gd`:

1. Replace:

```gdscript
## frame, where the camera and the hero are (see_through()): the rock blocks between them
## turn see-through. Set zone before add_child.
```

with:

```gdscript
## frame, where the camera and the hero are (see_through()): the rock blocks between them
## turn see-through. In a castle (zone.castle) the rock cells are stone walls instead:
## a KayKit wall piece on each straight run, a square tower at corners and ends, a round
## pillar where one stands alone; the ground goes on past the grid, banks of mist drift
## over the floor (zone.mist_banks) and the throne cell gets a throne on a dais. Set zone
## before add_child.
```

2. Replace:

```gdscript
const FLOOR_CHUNK := 3
const FLOOR_COLOR := Color(0.36, 0.32, 0.28)
```

with:

```gdscript
const FLOOR_CHUNK := 3
```

3. Replace:

```gdscript
const LEVER_UP := -40.0
const LEVER_DOWN := 40.0
```

with:

```gdscript
const LEVER_UP := -40.0
const LEVER_DOWN := 40.0
## Castle walls: the KayKit wall piece (2 m long, 1.1 m tall, 0.8 m thick) at WALL_SCALE
## fills one cell along its run; towers fill the cell and stand TOWER_HEIGHT tall with
## four merlons; pillars are round.
const WALL_SCENE := preload("res://assets/medieval/wall_straight.gltf")
const WALL_SCALE := 2.0
const WALL_THICKNESS := 1.6
const WALL_PIECE_HEIGHT := 2.2
const TOWER_HEIGHT := 2.6
const PILLAR_RADIUS := 0.8
const THRONE_GOLD := Color(0.85, 0.65, 0.2)
const THRONE_RED := Color(0.45, 0.08, 0.12)
## Mist: flat see-through banks drifting back and forth over floor cells picked with a
## fixed seed.
const MIST_COLOR := Color(0.8, 0.78, 0.9, 0.22)
const MIST_SEED := 5
## Ground around a castle's grid: a plane this much wider on every side.
const OUTER_GROUND := 60.0
```

4. Replace:

```gdscript
var _lever_tween: Tween
var _key: Node3D
```

with:

```gdscript
var _lever_tween: Tween
var _key: Node3D
## The drifting mist banks (castle).
var _mists: Array[MeshInstance3D] = []
```

5. Replace:

```gdscript
	_add_floor()
	_add_rock()
```

with:

```gdscript
	_add_floor()
	if zone.castle:
		_add_castle()
	else:
		_add_rock()
	for cell in zone.find_cells(ZoneData.THRONE):
		_add_throne(cell)
	for i in zone.mist_banks:
		_add_mist(i)
```

6. Replace:

```gdscript
	if _key and _key.visible:
		_key.rotation.y += delta * 1.5
```

with:

```gdscript
	if _key and _key.visible:
		_key.rotation.y += delta * 1.5
	for i in _mists.size():
		_mists[i].position.x += sin(_time * 0.3 + i * 2.1) * delta * 0.6
```

7. Replace:

```gdscript
	for block in _faded:
		if not block in hidden:
			block.material_override = _rock_materials[_shade(zone.cell_at(block.position))]
	for block in hidden:
		block.material_override = _clear_material
	_faded = hidden
```

with:

```gdscript
	for block in _faded:
		if not block in hidden:
			_fade(block, false)
	for block in hidden:
		_fade(block, true)
	_faded = hidden


## A rock block, a castle tower or a pillar swaps to the see-through material; the
## meshes under it (a castle wall piece, a tower's merlons) fade by their transparency.
func _fade(block: MeshInstance3D, on: bool) -> void:
	if block.mesh != null:
		block.material_override = _clear_material if on \
			else _rock_materials[_shade(zone.cell_at(block.position))]
	for node in block.find_children("*", "GeometryInstance3D", true, false):
		(node as GeometryInstance3D).transparency = 1.0 - SEE_THROUGH_ALPHA if on else 0.0
```

8. Replace:

```gdscript
			BattleStage.add_mesh(self, mesh, FLOOR_COLOR, corner + Vector3(chunk, 0, chunk) / 2.0)
```

with:

```gdscript
			BattleStage.add_mesh(self, mesh, zone.floor_color,
				corner + Vector3(chunk, 0, chunk) / 2.0)
	if zone.castle:
		var outer := PlaneMesh.new()
		outer.size = Vector2(size) * ZoneData.CELL + Vector2.ONE * OUTER_GROUND * 2.0
		BattleStage.add_mesh(self, outer, zone.floor_color.darkened(0.25), Vector3(0, -0.02, 0))
```

9. Replace:

```gdscript
## The first rock neighbour of cell (north, west, east, south), as a unit step.
```

with:

```gdscript
## Castle walls on every rock cell next to the floor (the ones inside thick masses are
## never seen and get nothing): a wall piece where the cell runs straight, a tower at
## corners, ends and junctions, a round pillar where it stands alone. Each has its
## collider and is a see-through block (a MeshInstance3D at the cell; the wall piece's
## model hangs under it).
func _add_castle() -> void:
	var size := zone.grid_size()
	var body := StaticBody3D.new()
	add_child(body)
	for y in size.y:
		for x in size.x:
			var cell := Vector2i(x, y)
			if zone.cell_char(cell) != ZoneData.ROCK or not _touches_floor(cell):
				continue
			var block := MeshInstance3D.new()
			block.position = zone.cell_center(cell)
			add_child(block)
			_blocks[cell] = block
			var box := BoxShape3D.new()
			var shape := CollisionShape3D.new()
			shape.shape = box
			var kind := _wall_kind(cell)
			if kind == "ew" or kind == "ns":
				var yaw := 0.0 if kind == "ew" else 90.0
				BattleStage.add_model(block, WALL_SCENE, Vector3.ZERO, WALL_SCALE, yaw)
				box.size = Vector3(ZoneData.CELL, WALL_PIECE_HEIGHT, WALL_THICKNESS)
				shape.rotation_degrees.y = yaw
				shape.position = block.position + Vector3(0, WALL_PIECE_HEIGHT / 2.0, 0)
			elif kind == "pillar":
				var column := CylinderMesh.new()
				column.top_radius = PILLAR_RADIUS * 0.85
				column.bottom_radius = PILLAR_RADIUS
				column.height = TOWER_HEIGHT
				column.radial_segments = 8
				block.mesh = column
				block.material_override = _rock_materials[_shade(cell)]
				block.position.y = TOWER_HEIGHT / 2.0
				box.size = Vector3(PILLAR_RADIUS * 2.0, TOWER_HEIGHT, PILLAR_RADIUS * 2.0)
				shape.position = block.position
			else:
				var tower := BoxMesh.new()
				tower.size = Vector3(ZoneData.CELL, TOWER_HEIGHT, ZoneData.CELL)
				block.mesh = tower
				block.material_override = _rock_materials[_shade(cell)]
				block.position.y = TOWER_HEIGHT / 2.0
				var merlon := BoxMesh.new()
				merlon.size = Vector3(0.9, 0.6, 0.9)
				for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
					BattleStage.add_mesh(block, merlon, zone.rock_color * ROCK_SHADES[1],
						Vector3(corner.x * 1.55, TOWER_HEIGHT / 2.0 + 0.3, corner.y * 1.55))
				box.size = tower.size
				shape.position = block.position
			body.add_child(shape)


## How a castle rock cell is drawn: "ew" / "ns" (a straight wall running east-west /
## north-south: rock at both ends and floor on at least one side), "pillar" (no rock on
## any side) or "tower" (corners, ends, junctions).
func _wall_kind(cell: Vector2i) -> String:
	var n := zone.cell_char(cell + Vector2i(0, -1)) == ZoneData.ROCK
	var s := zone.cell_char(cell + Vector2i(0, 1)) == ZoneData.ROCK
	var w := zone.cell_char(cell + Vector2i(-1, 0)) == ZoneData.ROCK
	var e := zone.cell_char(cell + Vector2i(1, 0)) == ZoneData.ROCK
	if w and e and not (n and s):
		return "ew"
	if n and s and not (w and e):
		return "ns"
	if not (n or s or w or e):
		return "pillar"
	return "tower"


## How far in from its cell's edge the face of the castle wall on rock_cell stands, seen
## from the side step (a thin wall piece leaves a gap; towers and rock fill the cell).
func _face_inset(rock_cell: Vector2i, side: Vector2i) -> float:
	if not zone.castle:
		return 0.0
	var kind := _wall_kind(rock_cell)
	if (kind == "ew" and side.y != 0) or (kind == "ns" and side.x != 0):
		return (ZoneData.CELL - WALL_THICKNESS) / 2.0
	return 0.0


## A throne on a dais: a red seat with a tall gold-trimmed back, its back to the north.
func _add_throne(cell: Vector2i) -> void:
	var body := StaticBody3D.new()
	body.position = zone.cell_center(cell)
	add_child(body)
	var dais := BoxMesh.new()
	dais.size = Vector3(3.6, 0.3, 3.0)
	BattleStage.add_mesh(body, dais, zone.rock_color * ROCK_SHADES[2], Vector3(0, 0.15, 0))
	var seat := BoxMesh.new()
	seat.size = Vector3(1.6, 0.9, 1.2)
	BattleStage.add_mesh(body, seat, THRONE_RED, Vector3(0, 0.75, 0))
	var back := BoxMesh.new()
	back.size = Vector3(1.8, 2.8, 0.3)
	BattleStage.add_mesh(body, back, THRONE_RED, Vector3(0, 1.7, -0.6))
	var trim := BoxMesh.new()
	trim.size = Vector3(2.0, 0.2, 0.4)
	BattleStage.add_mesh(body, trim, THRONE_GOLD, Vector3(0, 3.1, -0.6))
	var post := BoxMesh.new()
	post.size = Vector3(0.2, 3.0, 0.4)
	for x in [-0.85, 0.85]:
		BattleStage.add_mesh(body, post, THRONE_GOLD, Vector3(x, 1.6, -0.6))
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	(shape.shape as BoxShape3D).size = Vector3(2.0, 3.0, 1.6)
	shape.position = Vector3(0, 1.5, -0.2)
	body.add_child(shape)


## Bank of mist number index: flat and see-through, over a floor cell picked with
## MIST_SEED.
func _add_mist(index: int) -> void:
	var floors := zone.find_cells(".")
	if floors.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = MIST_SEED + index * 7919
	var cell := floors[rng.randi_range(0, floors.size() - 1)]
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = MIST_COLOR
	var mist := MeshInstance3D.new()
	mist.mesh = BattleStage.unit_sphere()
	mist.material_override = mat
	mist.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mist.position = zone.cell_center(cell) + Vector3(rng.randf_range(-1, 1), 0.25,
		rng.randf_range(-1, 1))
	mist.scale = Vector3(rng.randf_range(4.0, 6.0), 0.5, rng.randf_range(3.0, 5.0))
	add_child(mist)
	_mists.append(mist)


## The first rock neighbour of cell (north, west, east, south), as a unit step.
```

10. Replace:

```gdscript
	var at_wall := zone.cell_center(cell) - out * (ZoneData.CELL / 2.0 - 0.12)
```

with:

```gdscript
	var inset := _face_inset(cell + side, side)
	var at_wall := zone.cell_center(cell) - out * (ZoneData.CELL / 2.0 + inset - 0.12)
```

- [ ] **Step 3: Tents on dungeon floors, the castle backdrop and the castle music**

In `scripts/world/world_stage.gd`:

1. Replace:

```gdscript
## outside. Exits, figures and chests are World's. A dungeon floor only gets its sky and
## light here: its cells are a DungeonMap, which World adds. Every query takes the zone.
```

with:

```gdscript
## outside. Exits, figures and chests are World's. A dungeon floor only gets its sky and
## light and its buildings (the castle camp's tents) here: its cells are a DungeonMap,
## which World adds. Every query takes the zone.
```

2. Replace:

```gdscript
	"trees_B": preload("res://assets/medieval/trees_B_medium.gltf"),
}
```

with:

```gdscript
	"trees_B": preload("res://assets/medieval/trees_B_medium.gltf"),
	"tent": preload("res://assets/medieval/tent.gltf"),
}
## Buildings drawn at another scale than BUILDING_SCALE (the tent is a tiny prop).
const MODEL_SCALES := {"tent": 6.0}
```

3. Replace:

```gdscript
	"market_green": 3.2, "tavern_green": 2.4,
}
```

with:

```gdscript
	"market_green": 3.2, "tavern_green": 2.4, "tent": 1.6,
}
```

4. Replace:

```gdscript
	BattleStage.build_environment(root, zone)
	if zone.is_dungeon():
		return null
```

with:

```gdscript
	BattleStage.build_environment(root, zone)
	if zone.is_dungeon():
		for building in zone.buildings:
			_add_solid_model(root, MODELS[building[2]], building[0],
				MODEL_SCALES.get(building[2], BUILDING_SCALE), building[1])
		return null
```

5. Replace:

```gdscript
		_add_solid_model(root, MODELS[building[2]], building[0], BUILDING_SCALE, building[1])
```

with:

```gdscript
		_add_solid_model(root, MODELS[building[2]], building[0],
			MODEL_SCALES.get(building[2], BUILDING_SCALE), building[1])
```

In `scripts/battle/battle_stage.gd`:

1. Replace:

```gdscript
## stalagmites and two torches, in the dark of an underground zone. The environment,
## the mesh and model helpers and the rock and tree models are shared with WorldStage.
```

with:

```gdscript
## stalagmites and two torches, in the dark of an underground zone. "castillo" is a
## castle yard: flagstones, KayKit wall pieces with towers behind and beside the
## fighters, banks of mist and two torches (and the hero's lantern indoors). The
## environment, the mesh and model helpers and the rock and tree models are shared with
## WorldStage.
```

2. Replace:

```gdscript
const CAVE_TORCHES := [Vector3(-3.5, 2.4, -9.8), Vector3(5.0, 2.4, -8.8)]
```

with:

```gdscript
const CAVE_TORCHES := [Vector3(-3.5, 2.4, -9.8), Vector3(5.0, 2.4, -8.8)]
## The castle backdrop: flagstones, the wall pieces ([position, yaw]) at
## DungeonMap.WALL_SCALE, the towers ([position, height]), the mist banks ([position,
## scale]) and the two torches on the back wall.
const CASTLE_FLOOR := Color(0.42, 0.41, 0.44)
const CASTLE_STONE := Color(0.5, 0.49, 0.53)
const CASTLE_WALLS := [
	[Vector3(-10, 0, -11), 0.0], [Vector3(-6, 0, -11), 0.0], [Vector3(-2, 0, -11), 0.0],
	[Vector3(2, 0, -11), 0.0], [Vector3(6, 0, -11), 0.0], [Vector3(10, 0, -11), 0.0],
	[Vector3(-12, 0, -7), 90.0], [Vector3(-12, 0, -3), 90.0], [Vector3(-12, 0, 1), 90.0],
	[Vector3(13, 0, -7), 90.0], [Vector3(13, 0, -3), 90.0], [Vector3(13, 0, 1), 90.0],
]
const CASTLE_TOWERS := [
	[Vector3(-14, 0, -11), 5.0], [Vector3(14, 0, -11), 5.0], [Vector3(0, 0, -16), 9.0],
]
const CASTLE_MIST := [
	[Vector3(-6, 0.3, -6), Vector3(5, 0.5, 3)], [Vector3(6, 0.3, -7), Vector3(6, 0.5, 3)],
	[Vector3(-8, 0.3, 1), Vector3(4, 0.5, 4)], [Vector3(9, 0.3, 0), Vector3(4, 0.5, 4)],
]
const CASTLE_TORCHES := [Vector3(-4.0, 2.0, -10.0), Vector3(4.0, 2.0, -10.0)]
```

3. Replace:

```gdscript
	if zone != null and zone.backdrop == "mina":
		_build_cave(root)
		return
```

with:

```gdscript
	if zone != null and zone.backdrop == "mina":
		_build_cave(root)
		return
	if zone != null and zone.backdrop == "castillo":
		_build_castle(root, zone)
		return
```

4. Replace:

```gdscript
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
```

with:

```gdscript
	for flame_pos in CAVE_TORCHES:
		_add_torch(root, flame_pos)
	_add_lantern(root)


static func _build_castle(root: Node3D, zone: ZoneData) -> void:
	var ground := PlaneMesh.new()
	ground.size = Vector2(80, 80)
	add_mesh(root, ground, CASTLE_FLOOR, Vector3.ZERO)
	for wall in CASTLE_WALLS:
		add_model(root, DungeonMap.WALL_SCENE, wall[0], DungeonMap.WALL_SCALE, wall[1])
	for tower in CASTLE_TOWERS:
		var box := BoxMesh.new()
		box.size = Vector3(4, tower[1], 4)
		add_mesh(root, box, CASTLE_STONE, tower[0] + Vector3(0, tower[1] / 2.0, 0))
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = DungeonMap.MIST_COLOR
	for bank in CASTLE_MIST:
		var mist := MeshInstance3D.new()
		mist.mesh = unit_sphere()
		mist.material_override = mat
		mist.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mist.position = bank[0]
		mist.scale = bank[1]
		root.add_child(mist)
	for flame_pos in CASTLE_TORCHES:
		_add_torch(root, flame_pos)
	if zone.underground:
		_add_lantern(root)


## A torch: a stick, an unshaded flame at flame_pos and its warm light a metre out.
static func _add_torch(root: Node3D, flame_pos: Vector3) -> void:
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


## The fighters' own light, from the camera's side (the hero's lantern).
static func _add_lantern(root: Node3D) -> void:
	var lantern := OmniLight3D.new()
	lantern.light_color = Color(1.0, 0.85, 0.65)
	lantern.light_energy = 1.2
	lantern.omni_range = 12.0
	lantern.position = Vector3(0.5, 3.0, 3.5)
	root.add_child(lantern)
```

In `scripts/audio/music_library.gd`:

1. Replace:

```gdscript
const MINE := "mine"
```

with:

```gdscript
const MINE := "mine"
const CASTLE := "castle"
```

2. Replace:

```gdscript
const IDS: Array[String] = [TITLE, MAP, VILLAGE, FOREST, MINE, BATTLE, BOSS, VICTORY,
```

with:

```gdscript
const IDS: Array[String] = [TITLE, MAP, VILLAGE, FOREST, MINE, CASTLE, BATTLE, BOSS, VICTORY,
```

3. Replace:

```gdscript
		"drums": ["k/4 r/4 h/4 r/2 h/2"],
	},
	BATTLE: {
```

with:

```gdscript
		"drums": ["k/4 r/4 h/4 r/2 h/2"],
	},
	# The castle: a slow march in E minor.
	CASTLE: {
		"bpm": 76, "loop": true, "duty": 0.5,
		"lead": [
			"E5/6 G5/2 B5/8", "A5/4 G5/4 F#5/8", "E5/4 F#5/4 G5/4 A5/4", "B5/12 r/4",
			"C6/6 B5/2 A5/8", "G5/4 F#5/4 E5/8", "F#5/4 G5/4 A5/4 D#5/4", "E5/12 r/4",
		],
		"bass": [
			"E2/4 B2/4 E2/4 B2/4", "D2/4 A2/4 D2/4 A2/4", "C2/4 G2/4 C2/4 G2/4",
			"B1/4 F#2/4 B1/4 F#2/4", "A1/4 E2/4 A1/4 E2/4", "E2/4 B2/4 E2/4 B2/4",
			"B1/4 F#2/4 B1/4 D#2/4", "E2/8 B1/8",
		],
		"drums": ["k/4 s/4 k/4 s/2 h/2"],
	},
	BATTLE: {
```

- [ ] **Step 4: Chests, shop, inn, the finished game and the castle autoplay starts**

In `scripts/game/chests.gd`:

1. Replace:

```gdscript
## (ZoneData.cell_center()), next to the floor's route. Pure: open() changes a GameState
## and returns the message.
```

with:

```gdscript
## (ZoneData.cell_center()), next to the floor's route; so do the castle's (two in the
## courtyard, one in the throne room). Pure: open() changes a GameState and returns the
## message.
```

2. Replace:

```gdscript
	"mina_3_cofre": {"zone": "mina_3", "pos": Vector3(-24, 0, 12), "yaw": -90.0,
		"item": Inventory.ETHER},
}
```

with:

```gdscript
	"mina_3_cofre": {"zone": "mina_3", "pos": Vector3(-24, 0, 12), "yaw": -90.0,
		"item": Inventory.ETHER},
	"castillo_patio_oeste": {"zone": "castillo_patio", "pos": Vector3(-24, 0, 0),
		"yaw": 180.0, "gold": 200},
	"castillo_patio_este": {"zone": "castillo_patio", "pos": Vector3(28, 0, -24),
		"yaw": 90.0, "gold": 200},
	"castillo_trono_cofre": {"zone": "castillo_trono", "pos": Vector3(-20, 0, 8),
		"yaw": -90.0, "item": Inventory.ETHER},
}
```

In `scripts/game/shop.gd`:

1. Replace:

```gdscript
const MINA := "mina"
```

with:

```gdscript
const MINA := "mina"
const CASTILLO := "castillo"
```

2. Replace:

```gdscript
	MINA: {
		"keeper": "Herrero",
		"equipment": ["espada_acero", "armadura_acero", "escudo_acero"],
		"items": [Inventory.POTION, Inventory.ANTIDOTE, Inventory.ETHER, Inventory.WING],
	},
}
```

with:

```gdscript
	MINA: {
		"keeper": "Herrero",
		"equipment": ["espada_acero", "armadura_acero", "escudo_acero"],
		"items": [Inventory.POTION, Inventory.ANTIDOTE, Inventory.ETHER, Inventory.WING],
	},
	CASTILLO: {
		"keeper": "Mercader",
		"equipment": ["espada_platino", "armadura_platino", "escudo_platino"],
		"items": [Inventory.POTION, Inventory.ANTIDOTE, Inventory.ETHER, Inventory.WING],
	},
}
```

In `scripts/game/inn.gd`:

1. Replace:

```gdscript
## there for free) and the forest's 15 G; the later zones' will cost 30 and 50 G. Pure: works
```

with:

```gdscript
## there for free), the forest's 15 G, the mine's 30 G and the castle camp's 50 G. Pure: works
```

2. Replace:

```gdscript
const MINA := "mina"
```

with:

```gdscript
const MINA := "mina"
const CASTILLO := "castillo"
```

3. Replace:

```gdscript
	MINA: {"keeper": "Posadero", "price": 30},
}
```

with:

```gdscript
	MINA: {"keeper": "Posadero", "price": 30},
	CASTILLO: {"keeper": "Posadera", "price": 50},
}
```

In `scripts/game/game_state.gd`:

1. Replace:

```gdscript
const START_GOLD := 50
```

with:

```gdscript
const START_GOLD := 50
## The last boss: its world flag marks the game as finished.
const FINAL_BOSS := "senor_niebla"
```

2. Replace:

```gdscript
## Gold lost on a defeat: half of what is carried, rounded down (gold - lost remains).
```

with:

```gdscript
## True once the Señor de la Niebla is beaten: the adventure is over (the ending itself
## comes with the story).
func is_finished() -> bool:
	return has_flag(FINAL_BOSS)


## Gold lost on a defeat: half of what is carried, rounded down (gold - lost remains).
```

In `scripts/game/game.gd`:

1. Replace:

```gdscript
## pause menu. Emits quit_to_title when the player goes back to the title.
## On autoplay it prints the gold and the equipment each time they change.
```

with:

```gdscript
## pause menu. Emits quit_to_title when the player goes back to the title.
## Beating the Señor de la Niebla (GameState.FINAL_BOSS) marks the game as finished
## (GameState.is_finished()) with a notice; the ending itself comes with the story.
## On autoplay it prints the gold and the equipment each time they change, the level and
## the play time on every change of zone and, once the Señor de la Niebla falls, the play
## time of the whole run; then it quits.
```

2. Replace:

```gdscript
	"rey_slime": "¡Villaclaro está a salvo! La niebla del norte se disipa...",
}
```

with:

```gdscript
	"rey_slime": "¡Villaclaro está a salvo! La niebla del norte se disipa...",
	"senor_niebla": "¡Consigues el último Fragmento del amuleto! La niebla se levanta.",
}
```

3. Replace:

```gdscript
		"quest_done": true,
		"town": "mina_1",
	},
}
```

with:

```gdscript
		"quest_done": true,
		"town": "mina_1",
	},
	# Zone 3 done: Lv 13 with the Golem's EXP and gold, the mine's gear and two fragments.
	"castillo_patio": {
		"experience": 1373,
		"gold": 600,
		"gear": ["espada_acero", "armadura_acero", "escudo_acero"],
		"flags": ["rey_slime", "bruja", "mina_palanca", "llave_mina", "mina_puerta",
			"golem_piedra"],
		"key_items": ["fragmento_bosque", "fragmento_mina"],
		"quest_done": true,
		"town": "mina_1",
	},
	# Ready for the Señor de la Niebla: Lv 17 with the castle's gear.
	"castillo_trono": {
		"experience": 2244,
		"gold": 300,
		"gear": ["espada_platino", "armadura_platino", "escudo_platino"],
		"flags": ["rey_slime", "bruja", "mina_palanca", "llave_mina", "mina_puerta",
			"golem_piedra"],
		"key_items": ["fragmento_bosque", "fragmento_mina"],
		"quest_done": true,
		"town": "castillo_patio",
	},
}
```

4. Replace:

```gdscript
		print("Zona: %s" % zone_id)
```

with:

```gdscript
		print("Zona: %s (Nv %d, %s)" % [zone_id, state.hero.level, _clock(play_time)])
```

5. Replace:

```gdscript
	if won:
		var data := _autosave(not boss)
		if _autoplay_save and _save.is_empty() and not data.is_empty():
			print("Guardado: %s" % _summary(data))
			quit_to_title.emit()
			return
	_set_busy(false)
```

with:

```gdscript
	if won:
		var data := _autosave(not boss)
		if _autoplay_save and _save.is_empty() and not data.is_empty():
			print("Guardado: %s" % _summary(data))
			quit_to_title.emit()
			return
	_set_busy(false)
	if _autoplay and won and state.is_finished():
		print("Juego completado: Nv %d, tiempo de juego %s" % [state.hero.level,
			_clock(play_time)])
		get_tree().quit()
```

6. Replace:

```gdscript
## One line with every saved value, keys sorted, for --autoplay-save.
```

with:

```gdscript
## Seconds as "h:mm:ss".
static func _clock(seconds: float) -> String:
	return "%d:%02d:%02d" % [floori(seconds / 3600.0), floori(seconds / 60.0) % 60,
		floori(seconds) % 60]


## One line with every saved value, keys sorted, for --autoplay-save.
```

- [ ] **Step 5: Create the two castle maps**

Create `data/zones/castillo_patio.tres`:

```ini
[gd_resource type="Resource" script_class="ZoneData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/world/zone_data.gd" id="1_zone"]

[resource]
script = ExtResource("1_zone")
id = "castillo_patio"
display_name = "el castillo"
number = 4
half_size = Vector2(34, 30)
ground_color = Color(0.3, 0.29, 0.32, 1)
has_grass = false
safe_discs = [[Vector3(0, 0, 20), 13.0]]
village_name = "el campamento"
village_pos = Vector3(0, 0, 20)
village_radius = 13.0
buildings = [[Vector3(-9.5, 0, 22.5), 30.0, "tent"], [Vector3(9.5, 0, 22.5), -30.0, "tent"]]
entries = {
"campamento": [Vector3(0, 0, 18), 0.0],
"sur": [Vector3(0, 0, 21), 0.0]
}
start_entry = "sur"
town_entry = "campamento"
exits = [{
"entry": "castillo",
"id": "sur",
"label": "A la mina",
"lock": "",
"lock_text": "",
"pos": Vector3(0, 0, 25),
"to": "mina_3",
"yaw": 0.0
}]
npcs = [{
"id": "castillo",
"kind": "shop",
"look": "MERCHANT",
"name": "Mercader",
"pos": Vector3(-6, 0, 15),
"yaw": 180.0
}, {
"id": "castillo",
"kind": "inn",
"look": "INNKEEPER",
"name": "Posadera",
"pos": Vector3(6, 0, 15),
"yaw": 180.0
}, {
"after_flag": "senor_niebla",
"kind": "npc",
"lines": ["Este campamento es lo último antes del castillo.", "La niebla sale de la sala del trono, arriba del todo.", "Los esqueletos del patio no duermen nunca. Ve con cuidado."],
"lines_after": ["¡La niebla se ha ido! Se ve el cielo por primera vez en años.", "Lleva los fragmentos del amuleto de vuelta a Villaclaro."],
"look": "VILLAGER",
"name": "Soldado",
"pos": Vector3(-5, 0, 23),
"yaw": 180.0
}]
formations = [["esqueleto_guerrero"], ["esqueleto_picaro"], ["esqueleto_mago"], ["esqueleto_picaro"], ["esqueleto_guerrero", "esqueleto_mago"], ["esqueleto_picaro", "esqueleto_mago"]]
start_formations = [["esqueleto_guerrero"], ["esqueleto_picaro"], ["esqueleto_mago"]]
start_pos = Vector3(0, 0, 20)
start_radius = 26.0
encounter_grace = 6.0
encounter_chance = 0.025
music = "castle"
village_music = "village"
sky_top = Color(0.26, 0.24, 0.36, 1)
haze = Color(0.42, 0.4, 0.5, 1)
fog_density = 0.022
sun_color = Color(0.78, 0.75, 0.92, 1)
sun_energy = 0.4
backdrop = "castillo"
layout = PackedStringArray("#################", "#T..#...S...#..C#", "#...#.......#...#", "#...###.#.###...#", "#.......#.......#", "###.#########.###", "#...#...T...#...#", "#.C.#.......#...#", "#.....##.##.....#", "#T....#...#....T#", "########.########", "#####.......#####", "#####.......#####", "#####.......#####", "#################")
rock_color = Color(0.44, 0.43, 0.48, 1)
floor_color = Color(0.34, 0.33, 0.36, 1)
castle = true
mist_banks = 10
stairs_up = "castillo_trono"
autoplay_route = Array[Vector3]([Vector3(0, 0, 20), Vector3(-6, 0, 16.8), Vector3(6, 0, 16.8), Vector3(0, 0, 16), Vector3(0, 0, 12), Vector3(0, 0, 0), Vector3(12, 0, 0), Vector3(12, 0, 4), Vector3(20, 0, 4), Vector3(20, 0, -12), Vector3(24, 0, -16), Vector3(24, 0, -20), Vector3(27, 0, -24), Vector3(24, 0, -20), Vector3(20, 0, -12), Vector3(4, 0, -12), Vector3(4, 0, -20), Vector3(-4, 0, -20), Vector3(-4, 0, -12), Vector3(-20, 0, -12), Vector3(-20, 0, -4), Vector3(-23, 0, 0), Vector3(-20, 0, -4), Vector3(-20, 0, -12), Vector3(-4, 0, -12), Vector3(-4, 0, -20), Vector3(0, 0, -20), Vector3(0, 0, -24)])
autoplay_boss_level = 17
```

Create `data/zones/castillo_trono.tres`:

```ini
[gd_resource type="Resource" script_class="ZoneData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/world/zone_data.gd" id="1_zone"]

[resource]
script = ExtResource("1_zone")
id = "castillo_trono"
display_name = "el castillo"
number = 4
half_size = Vector2(26, 26)
ground_color = Color(0.2, 0.18, 0.22, 1)
has_grass = false
boss_id = "senor_niebla"
boss_pos = Vector3(0, 0, -16.5)
formations = [["esqueleto_guerrero"], ["esqueleto_picaro"], ["esqueleto_mago"], ["esqueleto_picaro"], ["esqueleto_guerrero", "esqueleto_mago"], ["esqueleto_picaro", "esqueleto_mago"]]
encounter_grace = 6.0
encounter_chance = 0.025
music = "castle"
village_music = "village"
haze = Color(0.16, 0.1, 0.22, 1)
fog_density = 0.01
backdrop = "castillo"
layout = PackedStringArray("#############", "#####.R.#####", "#T#.......#T#", "#...#...#...#", "#...........#", "#T..#...#..T#", "#...........#", "#...#...#...#", "#C..........#", "#...#...#...#", "#T.........T#", "#.....B.....#", "#############")
underground = true
ambient_color = Color(0.62, 0.55, 0.78, 1)
ambient_energy = 1.4
rock_color = Color(0.42, 0.4, 0.46, 1)
floor_color = Color(0.42, 0.38, 0.44, 1)
castle = true
mist_banks = 0
start_entry = "B"
stairs_down = "castillo_patio"
autoplay_route = Array[Vector3]([Vector3(0, 0, 16), Vector3(-16, 0, 16), Vector3(-16, 0, 8), Vector3(-19, 0, 8), Vector3(-16, 0, 8), Vector3(-16, 0, -8), Vector3(-12, 0, -12), Vector3(-12, 0, -16), Vector3(0, 0, -15), Vector3(12, 0, -16), Vector3(16, 0, -8), Vector3(16, 0, 16)])
autoplay_boss_level = 17
```


- [ ] **Step 6: Import and check**

```powershell
.\tools\godot.cmd --headless --path . --import
foreach ($s in "world/zone_data","world/dungeon_map","world/world_stage","world/world","battle/battle_stage","audio/music_library","game/chests","game/shop","game/inn","game/game_state","game/game") { .\tools\godot.cmd --headless --path . --check-only --script "res://scripts/$s.gd" }
```

Expected: no line with `ERROR` or `WARNING`.

- [ ] **Step 7: The castle on autoplay**

```powershell
.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 60000 -- --autoplay --autoplay-zone=castillo_trono > "$env:TEMP\trono.log" 2>&1
Select-String -Path "$env:TEMP\trono.log" -Pattern "ERROR|WARNING|Zona|niebla|levanta|Fragmento|Juego completado|Has vuelto"
.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 9000 -- --autoplay --autoplay-zone=castillo_patio > "$env:TEMP\patio.log" 2>&1
Select-String -Path "$env:TEMP\patio.log" -Pattern "ERROR|WARNING|Zona|Compras|Encuentras|aparece|Aparecen"
Remove-Item "$env:APPDATA\Godot\app_userdata\rpg-turnos\save_autoplay.json" -ErrorAction SilentlyContinue
```

Expected, throne room: `Zona de inicio: castillo_trono (Nv 17)`, `Zona: castillo_trono (Nv 17, 0:00:00)`, a skeleton battle or two, `¡El Señor de la Niebla te cierra el paso!` (only when the hero is not worn out once Task 3 lands; here as soon as the route reaches the throne), and in the boss fight `¡La niebla envuelve al Señor de la Niebla!` / `¡El Señor de la Niebla se levanta con 180 PV!`, Niebla and silence lines, then `¡Consigues el último Fragmento del amuleto! La niebla se levanta.` and `Juego completado: Nv 17 (or more), tiempo de juego ...`, after which the run quits by itself. A defeat (about one in eight) prints `Has vuelto al campamento.` and the route climbs back to the throne. Courtyard: `Compras una Armadura de platino por 550 G.` at the camp's Mercader, skeleton battles (`¡Un Esqueleto ... salvaje aparece!`, `¡Aparecen Esqueleto ... y Esqueleto mago!`), `¡Encuentras 200 monedas de oro!` twice and `Zona: castillo_trono` when the route takes the stairs. No `ERROR`, at most the Jolt warning.

- [ ] **Step 8: Save round trip in the castle**

```powershell
.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 3000 -- --autoplay --autoplay-save --autoplay-zone=castillo_patio > "$env:TEMP\save.log" 2>&1
Select-String -Path "$env:TEMP\save.log" -Pattern "Guardado|Cargado|ERROR"
Remove-Item "$env:APPDATA\Godot\app_userdata\rpg-turnos\save_autoplay.json" -ErrorAction SilentlyContinue
```

Expected: the `Guardado:` and `Cargado:` JSON lines are identical, with `"zone":"castillo_patio"`, `"town":"castillo_patio"` and `"key_items":["fragmento_bosque","fragmento_mina"]`.

- [ ] **Step 9: Frames of the castle (temporary probe at the project root)**

Create `map_probe.gd`:

```gdscript
extends Node
## One-off look at the castle maps (Task 2). Not committed: delete it after viewing the
## frames. Each shot lasts 1.5 s; the second one fades the gate towers and the camp's
## walls by hand to show the see-through.

const SHOTS := [
	["castillo_patio", Vector3(-12, 0, -12), {}],
	["castillo_patio", Vector3(0, 0, 18), {}],
	["castillo_trono", Vector3(0, 0, -12), {}],
]


func _ready() -> void:
	for shot in SHOTS:
		var world: World = preload("res://scenes/world/world.tscn").instantiate()
		world.zone = ZoneData.by_id(shot[0])
		add_child(world)
		world.set_world_flags(shot[2])
		world.set_boss_present(true)
		world.place_player(shot[1])
		if shot[0] == "castillo_patio" and shot[1].z > 0:
			for block in world._dungeon._blocks.values():
				if block.position.z > 8:
					world._dungeon._fade(block, true)
		await get_tree().create_timer(1.5).timeout
		world.queue_free()
		await get_tree().process_frame
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
$dir = "$env:TEMP\castle_maps"; New-Item -ItemType Directory -Force $dir | Out-Null
.\tools\godot.cmd --path . res://map_probe.tscn --write-movie "$dir\f.png" --fixed-fps 10 --quit-after 70
$dir2 = "$env:TEMP\castle_battle"; New-Item -ItemType Directory -Force $dir2 | Out-Null
.\tools\godot.cmd --path . --write-movie "$dir2\f.png" --fixed-fps 10 --quit-after 600 -- --autoplay --autoplay-zone=castillo_trono
Remove-Item "$env:APPDATA\Godot\app_userdata\rpg-turnos\save_autoplay.json" -ErrorAction SilentlyContinue
```

Look at `castle_maps\f00000012.png`: the courtyard in violet fog, the hero between crenellated KayKit wall pieces and square stone towers with merlons, pale mist ovals on the floor. `f00000027.png`: the camp, the hero in the middle, the Mercader and the Posadera by the gate, the Soldado and two tents in front, the two gate towers and the camp's side walls see-through (the probe fades them by hand). `f00000043.png`: the throne room, purple and dim, round pillars, the red and gold throne at the top with the big violet Señor de la Niebla in his aura in front of it. In `castle_battle`, find the frames of a skeleton battle (the yard backdrop: flagstones, a crenellated wall with two torches behind, towers, mist, dark sky indoors) and of the boss battle. Then:

```powershell
Remove-Item -Recurse $dir, $dir2
Remove-Item map_probe.gd, map_probe.gd.uid, map_probe.tscn -ErrorAction SilentlyContinue
```

- [ ] **Step 10: The other zones still play**

```powershell
.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 6000 -- --autoplay --autoplay-zone=mina_1 > "$env:TEMP\mina.log" 2>&1
Select-String -Path "$env:TEMP\mina.log" -Pattern "ERROR|WARNING|Zona|palanca"
Remove-Item "$env:APPDATA\Godot\app_userdata\rpg-turnos\save_autoplay.json" -ErrorAction SilentlyContinue
```

Expected: `Zona: mina_1 (Nv 9, 0:00:00)`, `Zona: mina_2 ...`, the lever line; the mine's rock blocks still fade (material swap); no `ERROR`, at most the Jolt warning.

- [ ] **Step 11: Commit**

```powershell
git add assets data scripts
git status --short
git commit -m "Add the castle courtyard, the camp and the throne room"
```

`git status --short` must not list any probe.

---


### Task 3: The way from the mine, and an autoplay that rests

**Files:**
- Modify: `scripts/game/shop.gd`, `scripts/game/game_state.gd`, `data/zones/mina_3.tres`, `scripts/game/game.gd`

**Interfaces:**
- Consumes: Task 2 (`GameState.FINAL_BOSS`, `is_finished()`, `Game._clock()`, the `Juego completado` branch in `_on_encounter()`, `castillo_patio` entry `sur`); `Game._on_travel_requested()`, `_on_inn()`, `_on_shop()`, `_update_boss()`, `Inventory.take()`, `Inn.price()`, `World.in_village()` (phase 5b).
- Produces:
  - `GameState.REST_HP_RATIO` 0.3, `GameState.needs_rest() -> bool`.
  - `Game.AUTOPLAY_BOSS_HP` 0.7, `AUTOPLAY_BOSS_MP` 0.4, `_wants_retreat() -> bool`, `_autoplay_restock()` (awaitable).
  - `Shop.autoplay_picks()` starts with one Ala de viaje where sold and none is carried.
  - `mina_3` exit `castillo` and entry `castillo`.

- [ ] **Step 1: Rest, restock, the boss rule and the tunnel**


In `scripts/game/shop.gd`:

1. Replace:

```gdscript
## For --autoplay: the equipment of the shop that beats what is worn and is not in the
## bag yet, in slot order, as long as the gold lasts. Once there is no such piece left
## (bought or not), potions up to AUTOPLAY_POTIONS.
```

with:

```gdscript
## For --autoplay: one Ala de viaje where it is sold if none is carried (the autoplay
## retreat flies back with it), then the equipment of the shop that beats what is worn
## and is not in the bag yet, in slot order, as long as the gold lasts. Once there is no
## such piece left (bought or not), potions up to AUTOPLAY_POTIONS.
```

2. Replace:

```gdscript
	var upgrades := 0
```

with:

```gdscript
	var upgrades := 0
	if Inventory.WING in SHOPS[shop_id].items and state.inventory.count(Inventory.WING) == 0 \
			and gold >= price(Inventory.WING):
		picks.append(Inventory.WING)
		gold -= price(Inventory.WING)
```

In `scripts/game/game_state.gd`:

1. Replace:

```gdscript
const FINAL_BOSS := "senor_niebla"
```

with:

```gdscript
const FINAL_BOSS := "senor_niebla"
## The autoplay retreat: below this share of max HP the hero needs rest.
const REST_HP_RATIO := 0.3
```

2. Replace:

```gdscript
## True once the Señor de la Niebla is beaten: the adventure is over (the ending itself
```

with:

```gdscript
## For the autoplay retreat: true when the hero is in no shape for another battle far
## from an inn: below REST_HP_RATIO of max HP, or out of potions with MP for less than
## two of his best heal spell.
func needs_rest() -> bool:
	if hero.hp < hero.max_hp * REST_HP_RATIO:
		return true
	var heal_cost := 0
	for skill in hero.skills:
		if skill.kind == Skill.HEAL:
			heal_cost = maxi(heal_cost, skill.mp_cost)
	return inventory.count(Inventory.POTION) == 0 and hero.mp < heal_cost * 2


## True once the Señor de la Niebla is beaten: the adventure is over (the ending itself
```

In `data/zones/mina_3.tres`:

1. Replace:

```ini
start_entry = "S"
```

with:

```ini
entries = {
"castillo": [Vector3(20, 0, 16), 0.0]
}
start_entry = "S"
exits = [{
"entry": "sur",
"id": "castillo",
"label": "Al castillo",
"lock": "golem_piedra",
"lock_text": "Una niebla espesa cierra el túnel del este.",
"pos": Vector3(24, 0, 18),
"to": "castillo_patio",
"yaw": 90.0
}]
```

2. Replace:

```ini
autoplay_route = Array[Vector3]([Vector3(-16, 0, -16), Vector3(-20, 0, -16), Vector3(-20, 0, -8), Vector3(0, 0, -8), Vector3(0, 0, -20), Vector3(23, 0, -20), Vector3(20, 0, -16), Vector3(20, 0, 0), Vector3(-4, 0, 0), Vector3(-4, 0, 12), Vector3(4, 0, 12), Vector3(4, 0, 8), Vector3(20, 0, 8), Vector3(20, 0, 10.8), Vector3(20, 0, 16), Vector3(20, 0, 8), Vector3(4, 0, 8), Vector3(4, 0, 12), Vector3(-4, 0, 12), Vector3(-4, 0, 0), Vector3(-12, 0, 0), Vector3(-12, 0, 12), Vector3(-23, 0, 12), Vector3(-12, 0, 12), Vector3(-12, 0, -8), Vector3(-20, 0, -8), Vector3(-20, 0, -16)])
```

with:

```ini
autoplay_route = Array[Vector3]([Vector3(-16, 0, -16), Vector3(-20, 0, -16), Vector3(-20, 0, -8), Vector3(0, 0, -8), Vector3(0, 0, -20), Vector3(23, 0, -20), Vector3(20, 0, -16), Vector3(20, 0, 0), Vector3(-4, 0, 0), Vector3(-4, 0, 12), Vector3(4, 0, 12), Vector3(4, 0, 8), Vector3(20, 0, 8), Vector3(20, 0, 10.8), Vector3(20, 0, 16), Vector3(24, 0, 18), Vector3(20, 0, 8), Vector3(4, 0, 8), Vector3(4, 0, 12), Vector3(-4, 0, 12), Vector3(-4, 0, 0), Vector3(-12, 0, 0), Vector3(-12, 0, 12), Vector3(-23, 0, 12), Vector3(-12, 0, 12), Vector3(-12, 0, -8), Vector3(-20, 0, -8), Vector3(-20, 0, -16)])
```

In `scripts/game/game.gd`:

1. Replace:

```gdscript
## On autoplay it prints the gold and the equipment each time they change, the level and
## the play time on every change of zone and, once the Señor de la Niebla falls, the play
## time of the whole run; then it quits.
```

with:

```gdscript
## On autoplay it prints the gold and the equipment each time they change, the level and
## the play time on every change of zone and, once the Señor de la Niebla falls, the play
## time of the whole run; then it quits. After a won battle, when the hero needs rest
## (GameState.needs_rest()) away from a village, it flies back with an Ala de viaje; there
## (and after a defeat) it sleeps at the inn and restocks at the shop.
```

2. Replace:

```gdscript
## On autoplay the hero only sleeps at an inn below this share of max HP, so the nights
## don't eat the gold for the shop's gear.
```

with:

```gdscript
## On autoplay the hero only sleeps at an inn below this share of max HP or MP, so the
## nights don't eat the gold for the shop's gear.
```

3. Replace:

```gdscript
		get_tree().quit()
```

with:

```gdscript
		get_tree().quit()
	elif _autoplay and won and _wants_retreat():
		state.inventory.take(Inventory.WING)
		print("Retirada al pueblo (PV %d/%d, PM %d, pociones %d)" % [state.hero.hp,
			state.hero.max_hp, state.hero.mp, state.inventory.count(Inventory.POTION)])
		await _on_travel_requested()
		await _autoplay_restock()
	elif _autoplay and outcome == BattleEngine.State.LOST:
		await _autoplay_restock()


## Autoplay: needs rest (GameState.needs_rest()) away from a village, with an Ala de
## viaje and the gold for a night at the last village's inn.
func _wants_retreat() -> bool:
	if not state.needs_rest() or _world.in_village():
		return false
	if state.inventory.count(Inventory.WING) == 0:
		return false
	var town := ZoneData.by_id(state.town_zone)
	for npc: Dictionary in town.npcs:
		if npc.kind == "inn":
			return state.gold >= Inn.price(npc.id)
	return false


## Autoplay, in the village: a night at its inn and the shop's picks, as if the hero had
## walked up to the innkeeper and the merchant.
func _autoplay_restock() -> void:
	for npc: Dictionary in _zone.npcs:
		if npc.kind == "inn":
			await _on_inn(npc.id)
	for npc: Dictionary in _zone.npcs:
		if npc.kind == "shop":
			await _on_shop(npc.id)
```

4. Replace:

```gdscript
	var hurt := state.hero.hp < state.hero.max_hp * AUTOPLAY_INN_RATIO
```

with:

```gdscript
	var hurt := state.hero.hp < state.hero.max_hp * AUTOPLAY_INN_RATIO \
		or state.hero.mp < state.hero.max_mp * AUTOPLAY_INN_RATIO
```

5. Replace:

```gdscript
## saves; without gold, or with No, nothing happens. On autoplay it only stops there
## below AUTOPLAY_INN_RATIO of max HP and with the price.
```

with:

```gdscript
## saves; without gold, or with No, nothing happens. On autoplay it only stops there
## below AUTOPLAY_INN_RATIO of max HP or MP and with the price.
```

In `scripts/game/game.gd`:

1. Replace:

```gdscript
## The zone's boss is on the map until beaten: the Rey Slime only while the quest asks
## for it; on autoplay only from the zone's autoplay_boss_level on.
func _update_boss() -> void:
	if _zone.boss_id == "":
		return
	var strong_enough := not _autoplay or state.hero.level >= _zone.autoplay_boss_level
```

with:

```gdscript
## The zone's boss is on the map until beaten: the Rey Slime only while the quest asks
## for it; on autoplay only from the zone's autoplay_boss_level on, and only while the
## hero has AUTOPLAY_BOSS_HP of his max HP and AUTOPLAY_BOSS_MP of his max MP (a worn-out
## hero fights on, or rests, first).
func _update_boss() -> void:
	if _zone.boss_id == "":
		return
	var hero := state.hero
	var strong_enough := not _autoplay or (hero.level >= _zone.autoplay_boss_level \
		and hero.hp >= hero.max_hp * AUTOPLAY_BOSS_HP \
		and hero.mp >= hero.max_mp * AUTOPLAY_BOSS_MP)
```

2. Replace:

```gdscript
const AUTOPLAY_INN_RATIO := 0.5
```

with:

```gdscript
const AUTOPLAY_INN_RATIO := 0.5
## On autoplay the boss only comes out while the hero has these shares of max HP and MP.
const AUTOPLAY_BOSS_HP := 0.7
const AUTOPLAY_BOSS_MP := 0.4
```


- [ ] **Step 2: Check**

```powershell
foreach ($s in "game/shop","game/game_state","game/game") { .\tools\godot.cmd --headless --path . --check-only --script "res://scripts/$s.gd" }
```

Expected: no line with `ERROR` or `WARNING`.

- [ ] **Step 3: From the Golem into the castle on autoplay**

```powershell
.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 60000 -- --autoplay --autoplay-zone=mina_3 > "$env:TEMP\mina3.log" 2>&1
Select-String -Path "$env:TEMP\mina3.log" -Pattern "ERROR|WARNING|Zona|túnel|Golem de piedra te|Fragmento|Retirada|Has vuelto|Juego completado"
Remove-Item "$env:APPDATA\Godot\app_userdata\rpg-turnos\save_autoplay.json" -ErrorAction SilentlyContinue
```

Expected: while the Golem lives and the hero is worn out or below Lv 13, `Una niebla espesa cierra el túnel del este.` when the route passes the tunnel; `¡El Golem de piedra te cierra el paso!` (only with 70 % HP and 40 % MP), `¡Consigues un Fragmento del amuleto (2/3)!`, then `Zona: castillo_patio (Nv n, h:mm:ss)` right after it (the route walks on through the opened tunnel), the camp's purchases, `Zona: castillo_trono`, and in the end `Juego completado: ...` (the run quits by itself). `Retirada al pueblo (...)` may show when the hero runs dry away from a village. No `ERROR`, at most the Jolt warning.

- [ ] **Step 4: The whole game on autoplay, and its play time**

```powershell
.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 150000 -- --autoplay > "$env:TEMP\full.log" 2>&1
Select-String -Path "$env:TEMP\full.log" -Pattern "ERROR|WARNING|Zona:|Retirada|cierra el paso|Fragmento|Juego completado"
Remove-Item "$env:APPDATA\Godot\app_userdata\rpg-turnos\save_autoplay.json" -ErrorAction SilentlyContinue
```

Expected (under a minute of real time): the meadow, the Rey Slime at Lv 5, `Zona: bosque (Nv 5, ~0:20-0:23)`, the Bruja at Lv 9 and the first fragment, `Zona: mina_1 (Nv 9-10, ~0:44-0:54)`, the floors, the Golem and the second fragment, `Zona: castillo_patio (Nv 15-17, ~1:24-1:30)`, the throne room and `Juego completado: Nv n, tiempo de juego h:mm:ss`. The four runs of this plan ended at **1:30:36, 1:33:26, 1:36:44 and 1:55:30** (Lv 18-20), 1-4 retreats each, the Golem beaten at the first try. No `ERROR`, at most the Jolt warning. A run that ends at 150000 frames without `Juego completado` is a failure: look at where the log loops.

- [ ] **Step 5: By hand**

Run the game (`.\tools\godot.cmd --path .`), start a new game only to check the title and Objetos (the fragments carry "(n/3)" once found); then load a save made by `--autoplay-zone=castillo_patio` if you want to walk the castle: walls stop the hero, the gate towers fade when he stands behind them, the camp's Mercader and Posadera answer, the Soldado talks.

- [ ] **Step 6: Commit**

```powershell
git add data scripts
git status --short
git commit -m "Open the tunnel from the Golem to the castle and let autoplay rest and restock"
```

---


### Task 4: Documentation, credits, final checks and web export

**Files:**
- Modify: `CLAUDE.md`, `assets/CREDITS.md`

- [ ] **Step 1: Update the docs and the credits**


In `CLAUDE.md`:

1. Replace:

```markdown
- `scenes/game/game.tscn` + `scripts/game/game.gd` (`Game`) — one play session, created by `TitleScreen` (run on its own it makes its own `AudioDirector` and default options). Owns a `GameState` and the `World` of the current zone: `_switch_zone(zone_id, entry_id)` frees the map and builds `ZoneData.by_id(zone_id)` ("" entry: the zone's start), connects its signals, reopens its chests, passes the world flags and places the boss. On `World.encounter_triggered(boss)` it fades to black, `World.set_active(false)`, instantiates a `BattleScene` with `setup(state.hero, enemies, state.inventory)`, `set_equipment(weapon, shield)`, `gold_lost = state.defeat_gold_loss()` and `zone` on top (`enemies` from `EncounterTable.pick(zone, player position, rng)`, or `[EnemyLibrary.data(zone.boss_id)]`), awaits `finished(outcome)` (`BattleEngine.State`), frees it and turns the map back on (victory: `state.gold += engine.gold_won` and `quest.on_victory(id)` for every enemy; a boss also calls `state.on_boss_defeated()` (world flag + key item) and shows `BOSS_NOTICES` ("¡Villaclaro está a salvo! La niebla del norte se disipa...") or "¡Consigues un Fragmento del amuleto!"; fled: nothing; defeat: loses half the gold, `heal_full()` and goes to the town entry of `state.town_zone` ("Has vuelto a Villaclaro." / "... al refugio de la mina.", `_to_place()`)). On `World.exit_requested(zone, entry)` (an arch or the stairs of a mine floor) it fades, switches zone and autosaves silently; the pause menu's `travel_requested` (Ala de viaje) does the same to the last village ("Vuelas a <village>."; the map is frozen during the flight so nothing triggers). `_switch_zone()` leaves the new map frozen (`World.freeze(true)`) and every path (exit, defeat, Ala, a battle's return) unfreezes it only after the fade-in, so nothing on it can fire while `Game` is still busy. On a mine floor `World.lever_pulled` sets `zone.lever_flag` ("¡Tiras de la palanca! Se oye cómo se abre una reja."), `World.key_taken` adds `zone.floor_key` to the key items and sets it as a flag ("¡Encuentras la Llave de la mina!"), `World.door_used` opens the gates with `zone.door_key` (used up: "Abres la puerta con la Llave de la mina.") or shows `zone.door_text`; each sets the flags on the map and autosaves silently; `World.village_changed(true)` makes the zone the last village visited. On `World.shop_requested(shop_id)` it freezes the map and awaits `ShopWindow.run(shop_id)` (on autoplay only when `Shop.autoplay_picks()` is not empty), then autosaves if anything changed; on `World.inn_requested(inn_id)` it asks `ShopWindow.ask()` and on Sí calls `Inn.stay()` (fade to black, `INN_NIGHT_TIME` 0.8 s, full HP and MP, autosave; on autoplay only below `AUTOPLAY_INN_RATIO` 0.5 of max HP and with the price); on `World.chest_opened(id)` it calls `Chests.open(state, id)`, opens the lid (`World.set_chest_open()`), shows what was found and saves without a notice; on `World.npc_requested(i)` it plays `World.npc_lines(i)`. `_refresh_status()` also shows the weapon and shield on the map hero (`World.set_hero_equipment()`) and, on autoplay, prints `Oro N G · Equipo: ... · ATK n DEF n` whenever it changes. `_update_boss()` shows the zone's boss until it is beaten (the Rey Slime only while `quest.boss_available()`; on autoplay only from the zone's `autoplay_boss_level`). On `World.talk_requested` it takes the lines and potions from `quest.talk()`, heals, and plays them with `World.show_dialogue()`, then shows the boss if `quest.boss_available()`. The map stays while battles come and go, so position, camera and encounter grace survive them. Music: the zone's `music` / `village_music` (`World.village_changed`), battle or boss (the battle plays victory / defeat). Autosaves (`SaveData.from_state()` → `SaveStore.save_game()`) after each talk and each won battle ("Partida guardada.", except after a boss, which shows its notice instead) and silently after a defeat (so the gold lost sticks), after a chest and after each change of zone, never in battle; a save is loaded with `SaveData.apply()` (its zone) and `World.place_player()`; counts `play_time` (stops while paused). Owns the `PauseMenu` (`available` only on the map with nothing else going on) and answers its `save_requested` / `title_requested` (the latter sets a `_leaving` guard, marks the game busy, hides the menu and ignores input, so the frozen map can't walk or roll an encounter during the fade) / `travel_requested`; emits `quit_to_title`. `--autoplay --autoplay-save` prints `Guardado: <json>` / `Cargado: <json>`; `--autoplay --autoplay-menu` tours the pause menu 1 s into the map; `--autoplay --autoplay-zone=<id>` starts a new game in that zone with `AUTOPLAY_ZONES` (bosque: Lv 5, 150 G, the zone 1 gear, the Rey Slime beaten; mina_1: Lv 9, 250 G, the zone 2 gear, the Bruja beaten, the first fragment; mina_3: Lv 13, 100 G, the zone 3 gear, both gates open, the refugio as last village).
```

with:

```markdown
- `scenes/game/game.tscn` + `scripts/game/game.gd` (`Game`) — one play session, created by `TitleScreen` (run on its own it makes its own `AudioDirector` and default options). Owns a `GameState` and the `World` of the current zone: `_switch_zone(zone_id, entry_id)` frees the map and builds `ZoneData.by_id(zone_id)` ("" entry: the zone's start), connects its signals, reopens its chests, passes the world flags and places the boss. On `World.encounter_triggered(boss)` it fades to black, `World.set_active(false)`, instantiates a `BattleScene` with `setup(state.hero, enemies, state.inventory)`, `set_equipment(weapon, shield)`, `gold_lost = state.defeat_gold_loss()` and `zone` on top (`enemies` from `EncounterTable.pick(zone, player position, rng)`, or `[EnemyLibrary.data(zone.boss_id)]`), awaits `finished(outcome)` (`BattleEngine.State`), frees it and turns the map back on (victory: `state.gold += engine.gold_won` and `quest.on_victory(id)` for every enemy; a boss also calls `state.on_boss_defeated()` (world flag + key item) and shows `BOSS_NOTICES` ("¡Villaclaro está a salvo! La niebla del norte se disipa...") or "¡Consigues un Fragmento del amuleto (n/3)!"; the Señor de la Niebla's flag (`GameState.FINAL_BOSS`) marks the game as finished, `GameState.is_finished()`: "¡Consigues el último Fragmento del amuleto! La niebla se levanta."; fled: nothing; defeat: loses half the gold, `heal_full()` and goes to the town entry of `state.town_zone` ("Has vuelto a Villaclaro." / "... al refugio de la mina.", `_to_place()`)). On `World.exit_requested(zone, entry)` (an arch or the stairs of a mine floor) it fades, switches zone and autosaves silently; the pause menu's `travel_requested` (Ala de viaje) does the same to the last village ("Vuelas a <village>."; the map is frozen during the flight so nothing triggers). `_switch_zone()` leaves the new map frozen (`World.freeze(true)`) and every path (exit, defeat, Ala, a battle's return) unfreezes it only after the fade-in, so nothing on it can fire while `Game` is still busy. On a mine floor `World.lever_pulled` sets `zone.lever_flag` ("¡Tiras de la palanca! Se oye cómo se abre una reja."), `World.key_taken` adds `zone.floor_key` to the key items and sets it as a flag ("¡Encuentras la Llave de la mina!"), `World.door_used` opens the gates with `zone.door_key` (used up: "Abres la puerta con la Llave de la mina.") or shows `zone.door_text`; each sets the flags on the map and autosaves silently; `World.village_changed(true)` makes the zone the last village visited. On `World.shop_requested(shop_id)` it freezes the map and awaits `ShopWindow.run(shop_id)` (on autoplay only when `Shop.autoplay_picks()` is not empty), then autosaves if anything changed; on `World.inn_requested(inn_id)` it asks `ShopWindow.ask()` and on Sí calls `Inn.stay()` (fade to black, `INN_NIGHT_TIME` 0.8 s, full HP and MP, autosave; on autoplay only below `AUTOPLAY_INN_RATIO` 0.5 of max HP and with the price); on `World.chest_opened(id)` it calls `Chests.open(state, id)`, opens the lid (`World.set_chest_open()`), shows what was found and saves without a notice; on `World.npc_requested(i)` it plays `World.npc_lines(i)`. `_refresh_status()` also shows the weapon and shield on the map hero (`World.set_hero_equipment()`) and, on autoplay, prints `Oro N G · Equipo: ... · ATK n DEF n` whenever it changes. `_update_boss()` shows the zone's boss until it is beaten (the Rey Slime only while `quest.boss_available()`; on autoplay only from the zone's `autoplay_boss_level`). On `World.talk_requested` it takes the lines and potions from `quest.talk()`, heals, and plays them with `World.show_dialogue()`, then shows the boss if `quest.boss_available()`. The map stays while battles come and go, so position, camera and encounter grace survive them. Music: the zone's `music` / `village_music` (`World.village_changed`), battle or boss (the battle plays victory / defeat). Autosaves (`SaveData.from_state()` → `SaveStore.save_game()`) after each talk and each won battle ("Partida guardada.", except after a boss, which shows its notice instead) and silently after a defeat (so the gold lost sticks), after a chest and after each change of zone, never in battle; a save is loaded with `SaveData.apply()` (its zone) and `World.place_player()`; counts `play_time` (stops while paused). Owns the `PauseMenu` (`available` only on the map with nothing else going on) and answers its `save_requested` / `title_requested` (the latter sets a `_leaving` guard, marks the game busy, hides the menu and ignores input, so the frozen map can't walk or roll an encounter during the fade) / `travel_requested`; emits `quit_to_title`. `--autoplay --autoplay-save` prints `Guardado: <json>` / `Cargado: <json>`; `--autoplay --autoplay-menu` tours the pause menu 1 s into the map; `--autoplay --autoplay-zone=<id>` starts a new game in that zone with `AUTOPLAY_ZONES` (bosque: Lv 5, 150 G, the zone 1 gear, the Rey Slime beaten; mina_1: Lv 9, 250 G, the zone 2 gear, the Bruja beaten, the first fragment; mina_3: Lv 13, 100 G, the zone 3 gear, both gates open, the refugio as last village).
```

2. Replace:

```markdown
- `scenes/game/game.tscn` + `scripts/game/game.gd` (`Game`) — one play session, created by `TitleScreen` (run on its own it makes its own `AudioDirector` and default options). Owns a `GameState` and the `World` of the current zone: `_switch_zone(zone_id, entry_id)` frees the map and builds `ZoneData.by_id(zone_id)` ("" entry: the zone's start), connects its signals, reopens its chests, passes the world flags and places the boss. On `World.encounter_triggered(boss)` it fades to black, `World.set_active(false)`, instantiates a `BattleScene` with `setup(state.hero, enemies, state.inventory)`, `set_equipment(weapon, shield)`, `gold_lost = state.defeat_gold_loss()` and `zone` on top (`enemies` from `EncounterTable.pick(zone, player position, rng)`, or `[EnemyLibrary.data(zone.boss_id)]`), awaits `finished(outcome)` (`BattleEngine.State`), frees it and turns the map back on (victory: `state.gold += engine.gold_won` and `quest.on_victory(id)` for every enemy; a boss also calls `state.on_boss_defeated()` (world flag + key item) and shows `BOSS_NOTICES` ("¡Villaclaro está a salvo! La niebla del norte se disipa...") or "¡Consigues un Fragmento del amuleto (n/3)!"; the Señor de la Niebla's flag (`GameState.FINAL_BOSS`) marks the game as finished, `GameState.is_finished()`: "¡Consigues el último Fragmento del amuleto! La niebla se levanta."; fled: nothing; defeat: loses half the gold, `heal_full()` and goes to the town entry of `state.town_zone` ("Has vuelto a Villaclaro." / "... al refugio de la mina.", `_to_place()`)). On `World.exit_requested(zone, entry)` (an arch or the stairs of a mine floor) it fades, switches zone and autosaves silently; the pause menu's `travel_requested` (Ala de viaje) does the same to the last village ("Vuelas a <village>."; the map is frozen during the flight so nothing triggers). `_switch_zone()` leaves the new map frozen (`World.freeze(true)`) and every path (exit, defeat, Ala, a battle's return) unfreezes it only after the fade-in, so nothing on it can fire while `Game` is still busy. On a mine floor `World.lever_pulled` sets `zone.lever_flag` ("¡Tiras de la palanca! Se oye cómo se abre una reja."), `World.key_taken` adds `zone.floor_key` to the key items and sets it as a flag ("¡Encuentras la Llave de la mina!"), `World.door_used` opens the gates with `zone.door_key` (used up: "Abres la puerta con la Llave de la mina.") or shows `zone.door_text`; each sets the flags on the map and autosaves silently; `World.village_changed(true)` makes the zone the last village visited. On `World.shop_requested(shop_id)` it freezes the map and awaits `ShopWindow.run(shop_id)` (on autoplay only when `Shop.autoplay_picks()` is not empty), then autosaves if anything changed; on `World.inn_requested(inn_id)` it asks `ShopWindow.ask()` and on Sí calls `Inn.stay()` (fade to black, `INN_NIGHT_TIME` 0.8 s, full HP and MP, autosave; on autoplay only below `AUTOPLAY_INN_RATIO` 0.5 of max HP and with the price); on `World.chest_opened(id)` it calls `Chests.open(state, id)`, opens the lid (`World.set_chest_open()`), shows what was found and saves without a notice; on `World.npc_requested(i)` it plays `World.npc_lines(i)`. `_refresh_status()` also shows the weapon and shield on the map hero (`World.set_hero_equipment()`) and, on autoplay, prints `Oro N G · Equipo: ... · ATK n DEF n` whenever it changes. `_update_boss()` shows the zone's boss until it is beaten (the Rey Slime only while `quest.boss_available()`; on autoplay only from the zone's `autoplay_boss_level`). On `World.talk_requested` it takes the lines and potions from `quest.talk()`, heals, and plays them with `World.show_dialogue()`, then shows the boss if `quest.boss_available()`. The map stays while battles come and go, so position, camera and encounter grace survive them. Music: the zone's `music` / `village_music` (`World.village_changed`), battle or boss (the battle plays victory / defeat). Autosaves (`SaveData.from_state()` → `SaveStore.save_game()`) after each talk and each won battle ("Partida guardada.", except after a boss, which shows its notice instead) and silently after a defeat (so the gold lost sticks), after a chest and after each change of zone, never in battle; a save is loaded with `SaveData.apply()` (its zone) and `World.place_player()`; counts `play_time` (stops while paused). Owns the `PauseMenu` (`available` only on the map with nothing else going on) and answers its `save_requested` / `title_requested` (the latter sets a `_leaving` guard, marks the game busy, hides the menu and ignores input, so the frozen map can't walk or roll an encounter during the fade) / `travel_requested`; emits `quit_to_title`. `--autoplay --autoplay-save` prints `Guardado: <json>` / `Cargado: <json>`; `--autoplay --autoplay-menu` tours the pause menu 1 s into the map; `--autoplay --autoplay-zone=<id>` starts a new game in that zone with `AUTOPLAY_ZONES` (bosque: Lv 5, 150 G, the zone 1 gear, the Rey Slime beaten; mina_1: Lv 9, 250 G, the zone 2 gear, the Bruja beaten, the first fragment; mina_3: Lv 13, 100 G, the zone 3 gear, both gates open, the refugio as last village).
```

with:

```markdown
- `scenes/game/game.tscn` + `scripts/game/game.gd` (`Game`) — one play session, created by `TitleScreen` (run on its own it makes its own `AudioDirector` and default options). Owns a `GameState` and the `World` of the current zone: `_switch_zone(zone_id, entry_id)` frees the map and builds `ZoneData.by_id(zone_id)` ("" entry: the zone's start), connects its signals, reopens its chests, passes the world flags and places the boss. On `World.encounter_triggered(boss)` it fades to black, `World.set_active(false)`, instantiates a `BattleScene` with `setup(state.hero, enemies, state.inventory)`, `set_equipment(weapon, shield)`, `gold_lost = state.defeat_gold_loss()` and `zone` on top (`enemies` from `EncounterTable.pick(zone, player position, rng)`, or `[EnemyLibrary.data(zone.boss_id)]`), awaits `finished(outcome)` (`BattleEngine.State`), frees it and turns the map back on (victory: `state.gold += engine.gold_won` and `quest.on_victory(id)` for every enemy; a boss also calls `state.on_boss_defeated()` (world flag + key item) and shows `BOSS_NOTICES` ("¡Villaclaro está a salvo! La niebla del norte se disipa...") or "¡Consigues un Fragmento del amuleto (n/3)!"; the Señor de la Niebla's flag (`GameState.FINAL_BOSS`) marks the game as finished, `GameState.is_finished()`: "¡Consigues el último Fragmento del amuleto! La niebla se levanta."; fled: nothing; defeat: loses half the gold, `heal_full()` and goes to the town entry of `state.town_zone` ("Has vuelto a Villaclaro." / "... al refugio de la mina." / "... al campamento.", `_to_place()`)). On `World.exit_requested(zone, entry)` (an arch or the stairs of a mine floor) it fades, switches zone and autosaves silently; the pause menu's `travel_requested` (Ala de viaje) does the same to the last village ("Vuelas a <village>."; the map is frozen during the flight so nothing triggers). `_switch_zone()` leaves the new map frozen (`World.freeze(true)`) and every path (exit, defeat, Ala, a battle's return) unfreezes it only after the fade-in, so nothing on it can fire while `Game` is still busy. On a mine floor `World.lever_pulled` sets `zone.lever_flag` ("¡Tiras de la palanca! Se oye cómo se abre una reja."), `World.key_taken` adds `zone.floor_key` to the key items and sets it as a flag ("¡Encuentras la Llave de la mina!"), `World.door_used` opens the gates with `zone.door_key` (used up: "Abres la puerta con la Llave de la mina.") or shows `zone.door_text`; each sets the flags on the map and autosaves silently; `World.village_changed(true)` makes the zone the last village visited. On `World.shop_requested(shop_id)` it freezes the map and awaits `ShopWindow.run(shop_id)` (on autoplay only when `Shop.autoplay_picks()` is not empty), then autosaves if anything changed; on `World.inn_requested(inn_id)` it asks `ShopWindow.ask()` and on Sí calls `Inn.stay()` (fade to black, `INN_NIGHT_TIME` 0.8 s, full HP and MP, autosave; on autoplay only below `AUTOPLAY_INN_RATIO` 0.5 of max HP and with the price); on `World.chest_opened(id)` it calls `Chests.open(state, id)`, opens the lid (`World.set_chest_open()`), shows what was found and saves without a notice; on `World.npc_requested(i)` it plays `World.npc_lines(i)`. `_refresh_status()` also shows the weapon and shield on the map hero (`World.set_hero_equipment()`) and, on autoplay, prints `Oro N G · Equipo: ... · ATK n DEF n` whenever it changes. `_update_boss()` shows the zone's boss until it is beaten (the Rey Slime only while `quest.boss_available()`; on autoplay only from the zone's `autoplay_boss_level`). On `World.talk_requested` it takes the lines and potions from `quest.talk()`, heals, and plays them with `World.show_dialogue()`, then shows the boss if `quest.boss_available()`. The map stays while battles come and go, so position, camera and encounter grace survive them. Music: the zone's `music` / `village_music` (`World.village_changed`), battle or boss (the battle plays victory / defeat). Autosaves (`SaveData.from_state()` → `SaveStore.save_game()`) after each talk and each won battle ("Partida guardada.", except after a boss, which shows its notice instead) and silently after a defeat (so the gold lost sticks), after a chest and after each change of zone, never in battle; a save is loaded with `SaveData.apply()` (its zone) and `World.place_player()`; counts `play_time` (stops while paused). Owns the `PauseMenu` (`available` only on the map with nothing else going on) and answers its `save_requested` / `title_requested` (the latter sets a `_leaving` guard, marks the game busy, hides the menu and ignores input, so the frozen map can't walk or roll an encounter during the fade) / `travel_requested`; emits `quit_to_title`. `--autoplay --autoplay-save` prints `Guardado: <json>` / `Cargado: <json>`; `--autoplay --autoplay-menu` tours the pause menu 1 s into the map; `--autoplay --autoplay-zone=<id>` starts a new game in that zone with `AUTOPLAY_ZONES` (bosque: Lv 5, 150 G, the zone 1 gear, the Rey Slime beaten; mina_1: Lv 9, 250 G, the zone 2 gear, the Bruja beaten, the first fragment; mina_3: Lv 13, 100 G, the zone 3 gear, both gates open, the refugio as last village).
```

3. Replace:

```markdown
- `scenes/game/game.tscn` + `scripts/game/game.gd` (`Game`) — one play session, created by `TitleScreen` (run on its own it makes its own `AudioDirector` and default options). Owns a `GameState` and the `World` of the current zone: `_switch_zone(zone_id, entry_id)` frees the map and builds `ZoneData.by_id(zone_id)` ("" entry: the zone's start), connects its signals, reopens its chests, passes the world flags and places the boss. On `World.encounter_triggered(boss)` it fades to black, `World.set_active(false)`, instantiates a `BattleScene` with `setup(state.hero, enemies, state.inventory)`, `set_equipment(weapon, shield)`, `gold_lost = state.defeat_gold_loss()` and `zone` on top (`enemies` from `EncounterTable.pick(zone, player position, rng)`, or `[EnemyLibrary.data(zone.boss_id)]`), awaits `finished(outcome)` (`BattleEngine.State`), frees it and turns the map back on (victory: `state.gold += engine.gold_won` and `quest.on_victory(id)` for every enemy; a boss also calls `state.on_boss_defeated()` (world flag + key item) and shows `BOSS_NOTICES` ("¡Villaclaro está a salvo! La niebla del norte se disipa...") or "¡Consigues un Fragmento del amuleto (n/3)!"; the Señor de la Niebla's flag (`GameState.FINAL_BOSS`) marks the game as finished, `GameState.is_finished()`: "¡Consigues el último Fragmento del amuleto! La niebla se levanta."; fled: nothing; defeat: loses half the gold, `heal_full()` and goes to the town entry of `state.town_zone` ("Has vuelto a Villaclaro." / "... al refugio de la mina." / "... al campamento.", `_to_place()`)). On `World.exit_requested(zone, entry)` (an arch or the stairs of a mine floor) it fades, switches zone and autosaves silently; the pause menu's `travel_requested` (Ala de viaje) does the same to the last village ("Vuelas a <village>."; the map is frozen during the flight so nothing triggers). `_switch_zone()` leaves the new map frozen (`World.freeze(true)`) and every path (exit, defeat, Ala, a battle's return) unfreezes it only after the fade-in, so nothing on it can fire while `Game` is still busy. On a mine floor `World.lever_pulled` sets `zone.lever_flag` ("¡Tiras de la palanca! Se oye cómo se abre una reja."), `World.key_taken` adds `zone.floor_key` to the key items and sets it as a flag ("¡Encuentras la Llave de la mina!"), `World.door_used` opens the gates with `zone.door_key` (used up: "Abres la puerta con la Llave de la mina.") or shows `zone.door_text`; each sets the flags on the map and autosaves silently; `World.village_changed(true)` makes the zone the last village visited. On `World.shop_requested(shop_id)` it freezes the map and awaits `ShopWindow.run(shop_id)` (on autoplay only when `Shop.autoplay_picks()` is not empty), then autosaves if anything changed; on `World.inn_requested(inn_id)` it asks `ShopWindow.ask()` and on Sí calls `Inn.stay()` (fade to black, `INN_NIGHT_TIME` 0.8 s, full HP and MP, autosave; on autoplay only below `AUTOPLAY_INN_RATIO` 0.5 of max HP and with the price); on `World.chest_opened(id)` it calls `Chests.open(state, id)`, opens the lid (`World.set_chest_open()`), shows what was found and saves without a notice; on `World.npc_requested(i)` it plays `World.npc_lines(i)`. `_refresh_status()` also shows the weapon and shield on the map hero (`World.set_hero_equipment()`) and, on autoplay, prints `Oro N G · Equipo: ... · ATK n DEF n` whenever it changes. `_update_boss()` shows the zone's boss until it is beaten (the Rey Slime only while `quest.boss_available()`; on autoplay only from the zone's `autoplay_boss_level`). On `World.talk_requested` it takes the lines and potions from `quest.talk()`, heals, and plays them with `World.show_dialogue()`, then shows the boss if `quest.boss_available()`. The map stays while battles come and go, so position, camera and encounter grace survive them. Music: the zone's `music` / `village_music` (`World.village_changed`), battle or boss (the battle plays victory / defeat). Autosaves (`SaveData.from_state()` → `SaveStore.save_game()`) after each talk and each won battle ("Partida guardada.", except after a boss, which shows its notice instead) and silently after a defeat (so the gold lost sticks), after a chest and after each change of zone, never in battle; a save is loaded with `SaveData.apply()` (its zone) and `World.place_player()`; counts `play_time` (stops while paused). Owns the `PauseMenu` (`available` only on the map with nothing else going on) and answers its `save_requested` / `title_requested` (the latter sets a `_leaving` guard, marks the game busy, hides the menu and ignores input, so the frozen map can't walk or roll an encounter during the fade) / `travel_requested`; emits `quit_to_title`. `--autoplay --autoplay-save` prints `Guardado: <json>` / `Cargado: <json>`; `--autoplay --autoplay-menu` tours the pause menu 1 s into the map; `--autoplay --autoplay-zone=<id>` starts a new game in that zone with `AUTOPLAY_ZONES` (bosque: Lv 5, 150 G, the zone 1 gear, the Rey Slime beaten; mina_1: Lv 9, 250 G, the zone 2 gear, the Bruja beaten, the first fragment; mina_3: Lv 13, 100 G, the zone 3 gear, both gates open, the refugio as last village).
```

with:

```markdown
- `scenes/game/game.tscn` + `scripts/game/game.gd` (`Game`) — one play session, created by `TitleScreen` (run on its own it makes its own `AudioDirector` and default options). Owns a `GameState` and the `World` of the current zone: `_switch_zone(zone_id, entry_id)` frees the map and builds `ZoneData.by_id(zone_id)` ("" entry: the zone's start), connects its signals, reopens its chests, passes the world flags and places the boss. On `World.encounter_triggered(boss)` it fades to black, `World.set_active(false)`, instantiates a `BattleScene` with `setup(state.hero, enemies, state.inventory)`, `set_equipment(weapon, shield)`, `gold_lost = state.defeat_gold_loss()` and `zone` on top (`enemies` from `EncounterTable.pick(zone, player position, rng)`, or `[EnemyLibrary.data(zone.boss_id)]`), awaits `finished(outcome)` (`BattleEngine.State`), frees it and turns the map back on (victory: `state.gold += engine.gold_won` and `quest.on_victory(id)` for every enemy; a boss also calls `state.on_boss_defeated()` (world flag + key item) and shows `BOSS_NOTICES` ("¡Villaclaro está a salvo! La niebla del norte se disipa...") or "¡Consigues un Fragmento del amuleto (n/3)!"; the Señor de la Niebla's flag (`GameState.FINAL_BOSS`) marks the game as finished, `GameState.is_finished()`: "¡Consigues el último Fragmento del amuleto! La niebla se levanta."; fled: nothing; defeat: loses half the gold, `heal_full()` and goes to the town entry of `state.town_zone` ("Has vuelto a Villaclaro." / "... al refugio de la mina." / "... al campamento.", `_to_place()`)). On `World.exit_requested(zone, entry)` (an arch or the stairs of a mine floor) it fades, switches zone and autosaves silently; the pause menu's `travel_requested` (Ala de viaje) does the same to the last village ("Vuelas a <village>."; the map is frozen during the flight so nothing triggers). `_switch_zone()` leaves the new map frozen (`World.freeze(true)`) and every path (exit, defeat, Ala, a battle's return) unfreezes it only after the fade-in, so nothing on it can fire while `Game` is still busy. On a mine floor `World.lever_pulled` sets `zone.lever_flag` ("¡Tiras de la palanca! Se oye cómo se abre una reja."), `World.key_taken` adds `zone.floor_key` to the key items and sets it as a flag ("¡Encuentras la Llave de la mina!"), `World.door_used` opens the gates with `zone.door_key` (used up: "Abres la puerta con la Llave de la mina.") or shows `zone.door_text`; each sets the flags on the map and autosaves silently; `World.village_changed(true)` makes the zone the last village visited. On `World.shop_requested(shop_id)` it freezes the map and awaits `ShopWindow.run(shop_id)` (on autoplay only when `Shop.autoplay_picks()` is not empty), then autosaves if anything changed; on `World.inn_requested(inn_id)` it asks `ShopWindow.ask()` and on Sí calls `Inn.stay()` (fade to black, `INN_NIGHT_TIME` 0.8 s, full HP and MP, autosave; on autoplay only below `AUTOPLAY_INN_RATIO` 0.5 of max HP or MP and with the price); on `World.chest_opened(id)` it calls `Chests.open(state, id)`, opens the lid (`World.set_chest_open()`), shows what was found and saves without a notice; on `World.npc_requested(i)` it plays `World.npc_lines(i)`. `_refresh_status()` also shows the weapon and shield on the map hero (`World.set_hero_equipment()`) and, on autoplay, prints `Oro N G · Equipo: ... · ATK n DEF n` whenever it changes. `_update_boss()` shows the zone's boss until it is beaten (the Rey Slime only while `quest.boss_available()`; on autoplay only from the zone's `autoplay_boss_level`). On `World.talk_requested` it takes the lines and potions from `quest.talk()`, heals, and plays them with `World.show_dialogue()`, then shows the boss if `quest.boss_available()`. The map stays while battles come and go, so position, camera and encounter grace survive them. Music: the zone's `music` / `village_music` (`World.village_changed`), battle or boss (the battle plays victory / defeat). Autosaves (`SaveData.from_state()` → `SaveStore.save_game()`) after each talk and each won battle ("Partida guardada.", except after a boss, which shows its notice instead) and silently after a defeat (so the gold lost sticks), after a chest and after each change of zone, never in battle; a save is loaded with `SaveData.apply()` (its zone) and `World.place_player()`; counts `play_time` (stops while paused). Owns the `PauseMenu` (`available` only on the map with nothing else going on) and answers its `save_requested` / `title_requested` (the latter sets a `_leaving` guard, marks the game busy, hides the menu and ignores input, so the frozen map can't walk or roll an encounter during the fade) / `travel_requested`; emits `quit_to_title`. `--autoplay --autoplay-save` prints `Guardado: <json>` / `Cargado: <json>`; `--autoplay --autoplay-menu` tours the pause menu 1 s into the map; `--autoplay --autoplay-zone=<id>` starts a new game in that zone with `AUTOPLAY_ZONES` (bosque: Lv 5, 150 G, the zone 1 gear, the Rey Slime beaten; mina_1: Lv 9, 250 G, the zone 2 gear, the Bruja beaten, the first fragment; mina_3: Lv 13, 100 G, the zone 3 gear, both gates open, the refugio as last village).
```

4. Replace:

```markdown
- `scenes/game/game.tscn` + `scripts/game/game.gd` (`Game`) — one play session, created by `TitleScreen` (run on its own it makes its own `AudioDirector` and default options). Owns a `GameState` and the `World` of the current zone: `_switch_zone(zone_id, entry_id)` frees the map and builds `ZoneData.by_id(zone_id)` ("" entry: the zone's start), connects its signals, reopens its chests, passes the world flags and places the boss. On `World.encounter_triggered(boss)` it fades to black, `World.set_active(false)`, instantiates a `BattleScene` with `setup(state.hero, enemies, state.inventory)`, `set_equipment(weapon, shield)`, `gold_lost = state.defeat_gold_loss()` and `zone` on top (`enemies` from `EncounterTable.pick(zone, player position, rng)`, or `[EnemyLibrary.data(zone.boss_id)]`), awaits `finished(outcome)` (`BattleEngine.State`), frees it and turns the map back on (victory: `state.gold += engine.gold_won` and `quest.on_victory(id)` for every enemy; a boss also calls `state.on_boss_defeated()` (world flag + key item) and shows `BOSS_NOTICES` ("¡Villaclaro está a salvo! La niebla del norte se disipa...") or "¡Consigues un Fragmento del amuleto (n/3)!"; the Señor de la Niebla's flag (`GameState.FINAL_BOSS`) marks the game as finished, `GameState.is_finished()`: "¡Consigues el último Fragmento del amuleto! La niebla se levanta."; fled: nothing; defeat: loses half the gold, `heal_full()` and goes to the town entry of `state.town_zone` ("Has vuelto a Villaclaro." / "... al refugio de la mina." / "... al campamento.", `_to_place()`)). On `World.exit_requested(zone, entry)` (an arch or the stairs of a mine floor) it fades, switches zone and autosaves silently; the pause menu's `travel_requested` (Ala de viaje) does the same to the last village ("Vuelas a <village>."; the map is frozen during the flight so nothing triggers). `_switch_zone()` leaves the new map frozen (`World.freeze(true)`) and every path (exit, defeat, Ala, a battle's return) unfreezes it only after the fade-in, so nothing on it can fire while `Game` is still busy. On a mine floor `World.lever_pulled` sets `zone.lever_flag` ("¡Tiras de la palanca! Se oye cómo se abre una reja."), `World.key_taken` adds `zone.floor_key` to the key items and sets it as a flag ("¡Encuentras la Llave de la mina!"), `World.door_used` opens the gates with `zone.door_key` (used up: "Abres la puerta con la Llave de la mina.") or shows `zone.door_text`; each sets the flags on the map and autosaves silently; `World.village_changed(true)` makes the zone the last village visited. On `World.shop_requested(shop_id)` it freezes the map and awaits `ShopWindow.run(shop_id)` (on autoplay only when `Shop.autoplay_picks()` is not empty), then autosaves if anything changed; on `World.inn_requested(inn_id)` it asks `ShopWindow.ask()` and on Sí calls `Inn.stay()` (fade to black, `INN_NIGHT_TIME` 0.8 s, full HP and MP, autosave; on autoplay only below `AUTOPLAY_INN_RATIO` 0.5 of max HP or MP and with the price); on `World.chest_opened(id)` it calls `Chests.open(state, id)`, opens the lid (`World.set_chest_open()`), shows what was found and saves without a notice; on `World.npc_requested(i)` it plays `World.npc_lines(i)`. `_refresh_status()` also shows the weapon and shield on the map hero (`World.set_hero_equipment()`) and, on autoplay, prints `Oro N G · Equipo: ... · ATK n DEF n` whenever it changes. `_update_boss()` shows the zone's boss until it is beaten (the Rey Slime only while `quest.boss_available()`; on autoplay only from the zone's `autoplay_boss_level`). On `World.talk_requested` it takes the lines and potions from `quest.talk()`, heals, and plays them with `World.show_dialogue()`, then shows the boss if `quest.boss_available()`. The map stays while battles come and go, so position, camera and encounter grace survive them. Music: the zone's `music` / `village_music` (`World.village_changed`), battle or boss (the battle plays victory / defeat). Autosaves (`SaveData.from_state()` → `SaveStore.save_game()`) after each talk and each won battle ("Partida guardada.", except after a boss, which shows its notice instead) and silently after a defeat (so the gold lost sticks), after a chest and after each change of zone, never in battle; a save is loaded with `SaveData.apply()` (its zone) and `World.place_player()`; counts `play_time` (stops while paused). Owns the `PauseMenu` (`available` only on the map with nothing else going on) and answers its `save_requested` / `title_requested` (the latter sets a `_leaving` guard, marks the game busy, hides the menu and ignores input, so the frozen map can't walk or roll an encounter during the fade) / `travel_requested`; emits `quit_to_title`. `--autoplay --autoplay-save` prints `Guardado: <json>` / `Cargado: <json>`; `--autoplay --autoplay-menu` tours the pause menu 1 s into the map; `--autoplay --autoplay-zone=<id>` starts a new game in that zone with `AUTOPLAY_ZONES` (bosque: Lv 5, 150 G, the zone 1 gear, the Rey Slime beaten; mina_1: Lv 9, 250 G, the zone 2 gear, the Bruja beaten, the first fragment; mina_3: Lv 13, 100 G, the zone 3 gear, both gates open, the refugio as last village).
```

with:

```markdown
- `scenes/game/game.tscn` + `scripts/game/game.gd` (`Game`) — one play session, created by `TitleScreen` (run on its own it makes its own `AudioDirector` and default options). Owns a `GameState` and the `World` of the current zone: `_switch_zone(zone_id, entry_id)` frees the map and builds `ZoneData.by_id(zone_id)` ("" entry: the zone's start), connects its signals, reopens its chests, passes the world flags and places the boss. On `World.encounter_triggered(boss)` it fades to black, `World.set_active(false)`, instantiates a `BattleScene` with `setup(state.hero, enemies, state.inventory)`, `set_equipment(weapon, shield)`, `gold_lost = state.defeat_gold_loss()` and `zone` on top (`enemies` from `EncounterTable.pick(zone, player position, rng)`, or `[EnemyLibrary.data(zone.boss_id)]`), awaits `finished(outcome)` (`BattleEngine.State`), frees it and turns the map back on (victory: `state.gold += engine.gold_won` and `quest.on_victory(id)` for every enemy; a boss also calls `state.on_boss_defeated()` (world flag + key item) and shows `BOSS_NOTICES` ("¡Villaclaro está a salvo! La niebla del norte se disipa...") or "¡Consigues un Fragmento del amuleto (n/3)!"; the Señor de la Niebla's flag (`GameState.FINAL_BOSS`) marks the game as finished, `GameState.is_finished()`: "¡Consigues el último Fragmento del amuleto! La niebla se levanta."; fled: nothing; defeat: loses half the gold, `heal_full()` and goes to the town entry of `state.town_zone` ("Has vuelto a Villaclaro." / "... al refugio de la mina." / "... al campamento.", `_to_place()`)). On `World.exit_requested(zone, entry)` (an arch or the stairs of a mine floor) it fades, switches zone and autosaves silently; the pause menu's `travel_requested` (Ala de viaje) does the same to the last village ("Vuelas a <village>."; the map is frozen during the flight so nothing triggers). `_switch_zone()` leaves the new map frozen (`World.freeze(true)`) and every path (exit, defeat, Ala, a battle's return) unfreezes it only after the fade-in, so nothing on it can fire while `Game` is still busy. On a mine floor `World.lever_pulled` sets `zone.lever_flag` ("¡Tiras de la palanca! Se oye cómo se abre una reja."), `World.key_taken` adds `zone.floor_key` to the key items and sets it as a flag ("¡Encuentras la Llave de la mina!"), `World.door_used` opens the gates with `zone.door_key` (used up: "Abres la puerta con la Llave de la mina.") or shows `zone.door_text`; each sets the flags on the map and autosaves silently; `World.village_changed(true)` makes the zone the last village visited. On `World.shop_requested(shop_id)` it freezes the map and awaits `ShopWindow.run(shop_id)` (on autoplay only when `Shop.autoplay_picks()` is not empty), then autosaves if anything changed; on `World.inn_requested(inn_id)` it asks `ShopWindow.ask()` and on Sí calls `Inn.stay()` (fade to black, `INN_NIGHT_TIME` 0.8 s, full HP and MP, autosave; on autoplay only below `AUTOPLAY_INN_RATIO` 0.5 of max HP or MP and with the price); on `World.chest_opened(id)` it calls `Chests.open(state, id)`, opens the lid (`World.set_chest_open()`), shows what was found and saves without a notice; on `World.npc_requested(i)` it plays `World.npc_lines(i)`. `_refresh_status()` also shows the weapon and shield on the map hero (`World.set_hero_equipment()`) and, on autoplay, prints `Oro N G · Equipo: ... · ATK n DEF n` whenever it changes. `_update_boss()` shows the zone's boss until it is beaten (the Rey Slime only while `quest.boss_available()`; on autoplay only from the zone's `autoplay_boss_level` and with `AUTOPLAY_BOSS_HP` 70 % of max HP and `AUTOPLAY_BOSS_MP` 40 % of max MP). Autoplay retreat: after a won battle, if `GameState.needs_rest()` away from a village, with an Ala de viaje and the gold for the last village's inn, it flies back ("Retirada al pueblo (...)") and `_autoplay_restock()`s (that inn, then that shop); after a defeat it restocks too. On autoplay every change of zone prints `Zona: <id> (Nv n, h:mm:ss)` and beating the Señor de la Niebla prints `Juego completado: Nv n, tiempo de juego h:mm:ss` and quits. On `World.talk_requested` it takes the lines and potions from `quest.talk()`, heals, and plays them with `World.show_dialogue()`, then shows the boss if `quest.boss_available()`. The map stays while battles come and go, so position, camera and encounter grace survive them. Music: the zone's `music` / `village_music` (`World.village_changed`), battle or boss (the battle plays victory / defeat). Autosaves (`SaveData.from_state()` → `SaveStore.save_game()`) after each talk and each won battle ("Partida guardada.", except after a boss, which shows its notice instead) and silently after a defeat (so the gold lost sticks), after a chest and after each change of zone, never in battle; a save is loaded with `SaveData.apply()` (its zone) and `World.place_player()`; counts `play_time` (stops while paused). Owns the `PauseMenu` (`available` only on the map with nothing else going on) and answers its `save_requested` / `title_requested` (the latter sets a `_leaving` guard, marks the game busy, hides the menu and ignores input, so the frozen map can't walk or roll an encounter during the fade) / `travel_requested`; emits `quit_to_title`. `--autoplay --autoplay-save` prints `Guardado: <json>` / `Cargado: <json>`; `--autoplay --autoplay-menu` tours the pause menu 1 s into the map; `--autoplay --autoplay-zone=<id>` starts a new game in that zone with `AUTOPLAY_ZONES` (bosque: Lv 5, 150 G, the zone 1 gear, the Rey Slime beaten; mina_1: Lv 9, 250 G, the zone 2 gear, the Bruja beaten, the first fragment; mina_3: Lv 13, 100 G, the zone 3 gear, both gates open, the refugio as last village).
```

5. Replace:

```markdown
- `scenes/game/game.tscn` + `scripts/game/game.gd` (`Game`) — one play session, created by `TitleScreen` (run on its own it makes its own `AudioDirector` and default options). Owns a `GameState` and the `World` of the current zone: `_switch_zone(zone_id, entry_id)` frees the map and builds `ZoneData.by_id(zone_id)` ("" entry: the zone's start), connects its signals, reopens its chests, passes the world flags and places the boss. On `World.encounter_triggered(boss)` it fades to black, `World.set_active(false)`, instantiates a `BattleScene` with `setup(state.hero, enemies, state.inventory)`, `set_equipment(weapon, shield)`, `gold_lost = state.defeat_gold_loss()` and `zone` on top (`enemies` from `EncounterTable.pick(zone, player position, rng)`, or `[EnemyLibrary.data(zone.boss_id)]`), awaits `finished(outcome)` (`BattleEngine.State`), frees it and turns the map back on (victory: `state.gold += engine.gold_won` and `quest.on_victory(id)` for every enemy; a boss also calls `state.on_boss_defeated()` (world flag + key item) and shows `BOSS_NOTICES` ("¡Villaclaro está a salvo! La niebla del norte se disipa...") or "¡Consigues un Fragmento del amuleto (n/3)!"; the Señor de la Niebla's flag (`GameState.FINAL_BOSS`) marks the game as finished, `GameState.is_finished()`: "¡Consigues el último Fragmento del amuleto! La niebla se levanta."; fled: nothing; defeat: loses half the gold, `heal_full()` and goes to the town entry of `state.town_zone` ("Has vuelto a Villaclaro." / "... al refugio de la mina." / "... al campamento.", `_to_place()`)). On `World.exit_requested(zone, entry)` (an arch or the stairs of a mine floor) it fades, switches zone and autosaves silently; the pause menu's `travel_requested` (Ala de viaje) does the same to the last village ("Vuelas a <village>."; the map is frozen during the flight so nothing triggers). `_switch_zone()` leaves the new map frozen (`World.freeze(true)`) and every path (exit, defeat, Ala, a battle's return) unfreezes it only after the fade-in, so nothing on it can fire while `Game` is still busy. On a mine floor `World.lever_pulled` sets `zone.lever_flag` ("¡Tiras de la palanca! Se oye cómo se abre una reja."), `World.key_taken` adds `zone.floor_key` to the key items and sets it as a flag ("¡Encuentras la Llave de la mina!"), `World.door_used` opens the gates with `zone.door_key` (used up: "Abres la puerta con la Llave de la mina.") or shows `zone.door_text`; each sets the flags on the map and autosaves silently; `World.village_changed(true)` makes the zone the last village visited. On `World.shop_requested(shop_id)` it freezes the map and awaits `ShopWindow.run(shop_id)` (on autoplay only when `Shop.autoplay_picks()` is not empty), then autosaves if anything changed; on `World.inn_requested(inn_id)` it asks `ShopWindow.ask()` and on Sí calls `Inn.stay()` (fade to black, `INN_NIGHT_TIME` 0.8 s, full HP and MP, autosave; on autoplay only below `AUTOPLAY_INN_RATIO` 0.5 of max HP or MP and with the price); on `World.chest_opened(id)` it calls `Chests.open(state, id)`, opens the lid (`World.set_chest_open()`), shows what was found and saves without a notice; on `World.npc_requested(i)` it plays `World.npc_lines(i)`. `_refresh_status()` also shows the weapon and shield on the map hero (`World.set_hero_equipment()`) and, on autoplay, prints `Oro N G · Equipo: ... · ATK n DEF n` whenever it changes. `_update_boss()` shows the zone's boss until it is beaten (the Rey Slime only while `quest.boss_available()`; on autoplay only from the zone's `autoplay_boss_level` and with `AUTOPLAY_BOSS_HP` 70 % of max HP and `AUTOPLAY_BOSS_MP` 40 % of max MP). Autoplay retreat: after a won battle, if `GameState.needs_rest()` away from a village, with an Ala de viaje and the gold for the last village's inn, it flies back ("Retirada al pueblo (...)") and `_autoplay_restock()`s (that inn, then that shop); after a defeat it restocks too. On autoplay every change of zone prints `Zona: <id> (Nv n, h:mm:ss)` and beating the Señor de la Niebla prints `Juego completado: Nv n, tiempo de juego h:mm:ss` and quits. On `World.talk_requested` it takes the lines and potions from `quest.talk()`, heals, and plays them with `World.show_dialogue()`, then shows the boss if `quest.boss_available()`. The map stays while battles come and go, so position, camera and encounter grace survive them. Music: the zone's `music` / `village_music` (`World.village_changed`), battle or boss (the battle plays victory / defeat). Autosaves (`SaveData.from_state()` → `SaveStore.save_game()`) after each talk and each won battle ("Partida guardada.", except after a boss, which shows its notice instead) and silently after a defeat (so the gold lost sticks), after a chest and after each change of zone, never in battle; a save is loaded with `SaveData.apply()` (its zone) and `World.place_player()`; counts `play_time` (stops while paused). Owns the `PauseMenu` (`available` only on the map with nothing else going on) and answers its `save_requested` / `title_requested` (the latter sets a `_leaving` guard, marks the game busy, hides the menu and ignores input, so the frozen map can't walk or roll an encounter during the fade) / `travel_requested`; emits `quit_to_title`. `--autoplay --autoplay-save` prints `Guardado: <json>` / `Cargado: <json>`; `--autoplay --autoplay-menu` tours the pause menu 1 s into the map; `--autoplay --autoplay-zone=<id>` starts a new game in that zone with `AUTOPLAY_ZONES` (bosque: Lv 5, 150 G, the zone 1 gear, the Rey Slime beaten; mina_1: Lv 9, 250 G, the zone 2 gear, the Bruja beaten, the first fragment; mina_3: Lv 13, 100 G, the zone 3 gear, both gates open, the refugio as last village).
```

with:

```markdown
- `scenes/game/game.tscn` + `scripts/game/game.gd` (`Game`) — one play session, created by `TitleScreen` (run on its own it makes its own `AudioDirector` and default options). Owns a `GameState` and the `World` of the current zone: `_switch_zone(zone_id, entry_id)` frees the map and builds `ZoneData.by_id(zone_id)` ("" entry: the zone's start), connects its signals, reopens its chests, passes the world flags and places the boss. On `World.encounter_triggered(boss)` it fades to black, `World.set_active(false)`, instantiates a `BattleScene` with `setup(state.hero, enemies, state.inventory)`, `set_equipment(weapon, shield)`, `gold_lost = state.defeat_gold_loss()` and `zone` on top (`enemies` from `EncounterTable.pick(zone, player position, rng)`, or `[EnemyLibrary.data(zone.boss_id)]`), awaits `finished(outcome)` (`BattleEngine.State`), frees it and turns the map back on (victory: `state.gold += engine.gold_won` and `quest.on_victory(id)` for every enemy; a boss also calls `state.on_boss_defeated()` (world flag + key item) and shows `BOSS_NOTICES` ("¡Villaclaro está a salvo! La niebla del norte se disipa...") or "¡Consigues un Fragmento del amuleto (n/3)!"; the Señor de la Niebla's flag (`GameState.FINAL_BOSS`) marks the game as finished, `GameState.is_finished()`: "¡Consigues el último Fragmento del amuleto! La niebla se levanta."; fled: nothing; defeat: loses half the gold, `heal_full()` and goes to the town entry of `state.town_zone` ("Has vuelto a Villaclaro." / "... al refugio de la mina." / "... al campamento.", `_to_place()`)). On `World.exit_requested(zone, entry)` (an arch or the stairs of a mine floor) it fades, switches zone and autosaves silently; the pause menu's `travel_requested` (Ala de viaje) does the same to the last village ("Vuelas a <village>."; the map is frozen during the flight so nothing triggers). `_switch_zone()` leaves the new map frozen (`World.freeze(true)`) and every path (exit, defeat, Ala, a battle's return) unfreezes it only after the fade-in, so nothing on it can fire while `Game` is still busy. On a mine floor `World.lever_pulled` sets `zone.lever_flag` ("¡Tiras de la palanca! Se oye cómo se abre una reja."), `World.key_taken` adds `zone.floor_key` to the key items and sets it as a flag ("¡Encuentras la Llave de la mina!"), `World.door_used` opens the gates with `zone.door_key` (used up: "Abres la puerta con la Llave de la mina.") or shows `zone.door_text`; each sets the flags on the map and autosaves silently; `World.village_changed(true)` makes the zone the last village visited. On `World.shop_requested(shop_id)` it freezes the map and awaits `ShopWindow.run(shop_id)` (on autoplay only when `Shop.autoplay_picks()` is not empty), then autosaves if anything changed; on `World.inn_requested(inn_id)` it asks `ShopWindow.ask()` and on Sí calls `Inn.stay()` (fade to black, `INN_NIGHT_TIME` 0.8 s, full HP and MP, autosave; on autoplay only below `AUTOPLAY_INN_RATIO` 0.5 of max HP or MP and with the price); on `World.chest_opened(id)` it calls `Chests.open(state, id)`, opens the lid (`World.set_chest_open()`), shows what was found and saves without a notice; on `World.npc_requested(i)` it plays `World.npc_lines(i)`. `_refresh_status()` also shows the weapon and shield on the map hero (`World.set_hero_equipment()`) and, on autoplay, prints `Oro N G · Equipo: ... · ATK n DEF n` whenever it changes. `_update_boss()` shows the zone's boss until it is beaten (the Rey Slime only while `quest.boss_available()`; on autoplay only from the zone's `autoplay_boss_level` and with `AUTOPLAY_BOSS_HP` 70 % of max HP and `AUTOPLAY_BOSS_MP` 40 % of max MP). Autoplay retreat: after a won battle, if `GameState.needs_rest()` away from a village, with an Ala de viaje and the gold for the last village's inn, it flies back ("Retirada al pueblo (...)") and `_autoplay_restock()`s (that inn, then that shop); after a defeat it restocks too. On autoplay every change of zone prints `Zona: <id> (Nv n, h:mm:ss)` and beating the Señor de la Niebla prints `Juego completado: Nv n, tiempo de juego h:mm:ss` and quits. On `World.talk_requested` it takes the lines and potions from `quest.talk()`, heals, and plays them with `World.show_dialogue()`, then shows the boss if `quest.boss_available()`. The map stays while battles come and go, so position, camera and encounter grace survive them. Music: the zone's `music` / `village_music` (`World.village_changed`), battle or boss (the battle plays victory / defeat). Autosaves (`SaveData.from_state()` → `SaveStore.save_game()`) after each talk and each won battle ("Partida guardada.", except after a boss, which shows its notice instead) and silently after a defeat (so the gold lost sticks), after a chest and after each change of zone, never in battle; a save is loaded with `SaveData.apply()` (its zone) and `World.place_player()`; counts `play_time` (stops while paused). Owns the `PauseMenu` (`available` only on the map with nothing else going on) and answers its `save_requested` / `title_requested` (the latter sets a `_leaving` guard, marks the game busy, hides the menu and ignores input, so the frozen map can't walk or roll an encounter during the fade) / `travel_requested`; emits `quit_to_title`. `--autoplay --autoplay-save` prints `Guardado: <json>` / `Cargado: <json>`; `--autoplay --autoplay-menu` tours the pause menu 1 s into the map; `--autoplay --autoplay-zone=<id>` starts a new game in that zone with `AUTOPLAY_ZONES` (bosque: Lv 5, 150 G, the zone 1 gear, the Rey Slime beaten; mina_1: Lv 9, 250 G, the zone 2 gear, the Bruja beaten, the first fragment; mina_3: Lv 13, 100 G, the zone 3 gear, both gates open, the refugio as last village; castillo_patio: Lv 13 with the Golem's 300 EXP, 600 G, the zone 3 gear, the Golem beaten, two fragments; castillo_trono: Lv 17, 300 G, the platinum gear, the camp as last village).
```

6. Replace:

```markdown
- `scripts/game/game_state.gd` (`GameState`, `RefCounted`) — session state kept in memory: the hero `Combatant` (a duplicate of `data/hero.tres` that lives the whole session; battles change its HP, MP, EXP and level in place), `inventory: Inventory` (starts with 3 potions), `quest: Quest`, `gold` (`START_GOLD` 50), `loadout: Loadout`, `bag_equipment` (Equipment ids carried but not worn), `opened_chests` (Chests ids), `world_flags` (flag → true; a beaten boss sets its enemy id, which opens the exits locked by it), `key_items` (`Inventory.KEY_ITEMS` ids), `zone_id` (the map the hero is on) and `town_zone` (last village visited; "pradera" at first), `heal_full()` (HP and MP), `use_item(id)` (outside battle, `Inventory.use()`), `refresh_equipment()` (copies the loadout bonuses into `hero.equip_attack` / `equip_defense`), `equip(id)` (from the bag; what it replaces goes to the bag), `unequip(slot)`, `on_boss_defeated(boss)` (flag + key item, returns the item given), `has_flag(flag)` ("" is always set), `defeat_gold_loss()` (half the gold, rounded down). The hero gets its own `skills` array, so learning a spell never touches `hero.tres`.
```

with:

```markdown
- `scripts/game/game_state.gd` (`GameState`, `RefCounted`) — session state kept in memory: the hero `Combatant` (a duplicate of `data/hero.tres` that lives the whole session; battles change its HP, MP, EXP and level in place), `inventory: Inventory` (starts with 3 potions), `quest: Quest`, `gold` (`START_GOLD` 50), `loadout: Loadout`, `bag_equipment` (Equipment ids carried but not worn), `opened_chests` (Chests ids), `world_flags` (flag → true; a beaten boss sets its enemy id, which opens the exits locked by it), `key_items` (`Inventory.KEY_ITEMS` ids), `zone_id` (the map the hero is on) and `town_zone` (last village visited; "pradera" at first), `heal_full()` (HP and MP), `use_item(id)` (outside battle, `Inventory.use()`), `refresh_equipment()` (copies the loadout bonuses into `hero.equip_attack` / `equip_defense`), `equip(id)` (from the bag; what it replaces goes to the bag), `unequip(slot)`, `on_boss_defeated(boss)` (flag + key item, returns the item given), `has_flag(flag)` ("" is always set), `is_finished()` (the `FINAL_BOSS` "senor_niebla" flag), `needs_rest()` (autoplay retreat: below `REST_HP_RATIO` 0.3 of max HP, or no potions and MP for less than two of the best heal), `defeat_gold_loss()` (half the gold, rounded down). The hero gets its own `skills` array, so learning a spell never touches `hero.tres`.
```

7. Replace:

```markdown
- `scripts/game/shop.gd` (`Shop`, `RefCounted`) — pure shop rules: `SHOPS` (Villaclaro: the zone 1 gear, Poción and Antídoto; Bosque: the zone 2 gear, Poción, Antídoto, Éter and Ala de viaje; Mina: the Herrero, the zone 3 steel gear and the same items), `stock()`, `price()`, `sell_price()` (half, rounded down), `buy_problem()` / `can_buy()` / `buy()`, `sell_list()` / `sell_count()` / `sell_problem()` ("Lo llevas puesto", "No vale nada") / `sell()` (each returns `{ok, text}`), `compare(state, id)` (`{stat, worn, bonus, diff}` against the piece worn in that slot), `autoplay_picks()` (upgrades first, then potions up to 3).
```

with:

```markdown
- `scripts/game/shop.gd` (`Shop`, `RefCounted`) — pure shop rules: `SHOPS` (Villaclaro: the zone 1 gear, Poción and Antídoto; Bosque: the zone 2 gear, Poción, Antídoto, Éter and Ala de viaje; Mina: the Herrero, the zone 3 steel gear and the same items; Castillo: the Mercader of the camp, the zone 4 platinum gear and the same items), `stock()`, `price()`, `sell_price()` (half, rounded down), `buy_problem()` / `can_buy()` / `buy()`, `sell_list()` / `sell_count()` / `sell_problem()` ("Lo llevas puesto", "No vale nada") / `sell()` (each returns `{ok, text}`), `compare(state, id)` (`{stat, worn, bonus, diff}` against the piece worn in that slot), `autoplay_picks()` (upgrades first, then potions up to 3).
```

8. Replace:

```markdown
- `scripts/game/shop.gd` (`Shop`, `RefCounted`) — pure shop rules: `SHOPS` (Villaclaro: the zone 1 gear, Poción and Antídoto; Bosque: the zone 2 gear, Poción, Antídoto, Éter and Ala de viaje; Mina: the Herrero, the zone 3 steel gear and the same items; Castillo: the Mercader of the camp, the zone 4 platinum gear and the same items), `stock()`, `price()`, `sell_price()` (half, rounded down), `buy_problem()` / `can_buy()` / `buy()`, `sell_list()` / `sell_count()` / `sell_problem()` ("Lo llevas puesto", "No vale nada") / `sell()` (each returns `{ok, text}`), `compare(state, id)` (`{stat, worn, bonus, diff}` against the piece worn in that slot), `autoplay_picks()` (upgrades first, then potions up to 3).
```

with:

```markdown
- `scripts/game/shop.gd` (`Shop`, `RefCounted`) — pure shop rules: `SHOPS` (Villaclaro: the zone 1 gear, Poción and Antídoto; Bosque: the zone 2 gear, Poción, Antídoto, Éter and Ala de viaje; Mina: the Herrero, the zone 3 steel gear and the same items; Castillo: the Mercader of the camp, the zone 4 platinum gear and the same items), `stock()`, `price()`, `sell_price()` (half, rounded down), `buy_problem()` / `can_buy()` / `buy()`, `sell_list()` / `sell_count()` / `sell_problem()` ("Lo llevas puesto", "No vale nada") / `sell()` (each returns `{ok, text}`), `compare(state, id)` (`{stat, worn, bonus, diff}` against the piece worn in that slot), `autoplay_picks()` (one Ala de viaje where sold if none is carried, then upgrades, then potions up to 3).
```

9. Replace:

```markdown
- `scripts/game/inn.gd` (`Inn`, `RefCounted`) — inn rules: `INNS` (Villaclaro: Posadero, 5 G; Bosque: Posadera, 15 G; Mina: Posadero, 30 G; the castle will have 50 G), `keeper()`, `price()`, `offer()`, `stay(state, id)` → `{ok, text}` (pays and heals).
```

with:

```markdown
- `scripts/game/inn.gd` (`Inn`, `RefCounted`) — inn rules: `INNS` (Villaclaro: Posadero, 5 G; Bosque: Posadera, 15 G; Mina: Posadero, 30 G; Castillo: Posadera, 50 G), `keeper()`, `price()`, `offer()`, `stay(state, id)` → `{ok, text}` (pays and heals).
```

10. Replace:

```markdown
- `scripts/game/chests.gd` (`Chests`, `RefCounted`) — the chests of every zone (`CHESTS`: zone, position, yaw and contents; the meadow's 25 G, Escudo de madera, 40 G and Éter, the first two next to its autoplay route; the forest's 50 G, 50 G and an Ala de viaje in its three glades, next to its route; the mine's 120 G, 120 G and an Éter on the C cell of each floor); `of_zone(zone_id)`; `open(state, id)` → `{opened, text}` (equipment goes on at once if its slot is empty, else into the bag).
```

with:

```markdown
- `scripts/game/chests.gd` (`Chests`, `RefCounted`) — the chests of every zone (`CHESTS`: zone, position, yaw and contents; the meadow's 25 G, Escudo de madera, 40 G and Éter, the first two next to its autoplay route; the forest's 50 G, 50 G and an Ala de viaje in its three glades, next to its route; the mine's 120 G, 120 G and an Éter on the C cell of each floor; the castle's 200 G and 200 G in the courtyard and an Éter in the throne room); `of_zone(zone_id)`; `open(state, id)` → `{opened, text}` (equipment goes on at once if its slot is empty, else into the bag).
```

11. Replace:

```markdown
- `scripts/game/inventory.gd` (`Inventory`, `RefCounted`) — items as `id → count`: `count()`, `add()`, `take()`, `to_dict()`, `set_items()`. `ITEMS` table (name, article, effect `hp` / `mp` / `cure` / `travel`, value, price, usable in `battle` / `field`) in `IDS` order: `POTION` (30 PV, 8 G), `ETHER` (15 PM, 30 G), `ANTIDOTE` (cures poison, 10 G, battle only), `WING` (Ala de viaje, 25 G, outside battle: `use()` only takes it, the pause menu asks `Game` for the trip); `Shop` sells at `price` and buys back at half. `KEY_ITEMS` (id → name: `fragmento_bosque` and `fragmento_mina` "Fragmento del amuleto", `llave_mina` "Llave de la mina"), kept in `GameState.key_items`. `problem(id, combatant, in_battle)` says why it can't be used now ("" if it can: "PV al máximo", "Solo en combate", ...); `use(id, combatant, in_battle)` → `{used, effect, amount, status, reason}`, shared by `BattleEngine` and the pause menu; `display_name()`, `article()`.
```

with:

```markdown
- `scripts/game/inventory.gd` (`Inventory`, `RefCounted`) — items as `id → count`: `count()`, `add()`, `take()`, `to_dict()`, `set_items()`. `ITEMS` table (name, article, effect `hp` / `mp` / `cure` / `travel`, value, price, usable in `battle` / `field`) in `IDS` order: `POTION` (30 PV, 8 G), `ETHER` (15 PM, 30 G), `ANTIDOTE` (cures poison, 10 G, battle only), `WING` (Ala de viaje, 25 G, outside battle: `use()` only takes it, the pause menu asks `Game` for the trip); `Shop` sells at `price` and buys back at half. `KEY_ITEMS` (id → name: `fragmento_bosque`, `fragmento_mina` and `fragmento_castillo` "Fragmento del amuleto (1/3)" / "(2/3)" / "(3/3)", `llave_mina` "Llave de la mina"), kept in `GameState.key_items`. `problem(id, combatant, in_battle)` says why it can't be used now ("" if it can: "PV al máximo", "Solo en combate", ...); `use(id, combatant, in_battle)` → `{used, effect, amount, status, reason}`, shared by `BattleEngine` and the pause menu; `display_name()`, `article()`.
```

12. Replace:

```markdown
- `scripts/world/dungeon_map.gd` (`DungeonMap`, `Node3D`) — the cells of a mine floor (`zone.layout`, set `zone` before `add_child`): floor in 3 × 3-cell chunks, a 4 × 3 × 4 m rock block with a box collider for every rock cell next to the floor (buried ones in one `MultiMesh`, no collider; three shades), torches on the `T` cells' walls (a flame and a flickering `OmniLight3D`, energy 2.5, range 8 m, no shadows), stairs (`S` steps up, `B` a dark pit, with a "Subir" / "Bajar" sign), iron gates on `D` (box collider while closed), the lever on `L` and a turning gold key on `K`; `set_flags(flags)` (gates open with `zone.door_flag`, lever down with `zone.lever_flag`, key hidden once taken), `pull_lever()`, `see_through(camera_pos, hero_pos)` (the blocks of the two rows south of the hero whose box, grown 0.6 m, cuts the camera's lines to the hero's feet or chest get a shared see-through material, alpha 0.3).
```

with:

```markdown
- `scripts/world/dungeon_map.gd` (`DungeonMap`, `Node3D`) — the cells of a mine or castle floor (`zone.layout`, set `zone` before `add_child`): floor in 3 × 3-cell chunks (`zone.floor_color`); in a castle (`zone.castle`) every rock cell next to the floor is a stone wall instead of a rock block: the KayKit `wall_straight` piece ×2 (`WALL_SCALE`; 4 × 2.2 × 1.6 m, box collider) on straight runs (`_wall_kind()`: "ew" / "ns"), a 4 × 2.6 m tower with four merlons at corners, ends and junctions, a round pillar where the cell stands alone; a darker ground plane `OUTER_GROUND` 60 m past the grid, `zone.mist_banks` flat see-through mist banks drifting over floor cells, a throne on a dais on the `R` cell; in a mine a 4 × 3 × 4 m rock block with a box collider for every rock cell next to the floor (buried ones in one `MultiMesh`, no collider; three shades), torches on the `T` cells' walls (a flame and a flickering `OmniLight3D`, energy 2.5, range 8 m, no shadows), stairs (`S` steps up, `B` a dark pit, with a "Subir" / "Bajar" sign), iron gates on `D` (box collider while closed), the lever on `L` and a turning gold key on `K`; `set_flags(flags)` (gates open with `zone.door_flag`, lever down with `zone.lever_flag`, key hidden once taken), `pull_lever()`, `see_through(camera_pos, hero_pos)` (the blocks of the two rows south of the hero whose box, grown 0.6 m, cuts the camera's lines to the hero's feet or chest get a shared see-through material, alpha 0.3).
```

13. Replace:

```markdown
- `scripts/world/dungeon_map.gd` (`DungeonMap`, `Node3D`) — the cells of a mine or castle floor (`zone.layout`, set `zone` before `add_child`): floor in 3 × 3-cell chunks (`zone.floor_color`); in a castle (`zone.castle`) every rock cell next to the floor is a stone wall instead of a rock block: the KayKit `wall_straight` piece ×2 (`WALL_SCALE`; 4 × 2.2 × 1.6 m, box collider) on straight runs (`_wall_kind()`: "ew" / "ns"), a 4 × 2.6 m tower with four merlons at corners, ends and junctions, a round pillar where the cell stands alone; a darker ground plane `OUTER_GROUND` 60 m past the grid, `zone.mist_banks` flat see-through mist banks drifting over floor cells, a throne on a dais on the `R` cell; in a mine a 4 × 3 × 4 m rock block with a box collider for every rock cell next to the floor (buried ones in one `MultiMesh`, no collider; three shades), torches on the `T` cells' walls (a flame and a flickering `OmniLight3D`, energy 2.5, range 8 m, no shadows), stairs (`S` steps up, `B` a dark pit, with a "Subir" / "Bajar" sign), iron gates on `D` (box collider while closed), the lever on `L` and a turning gold key on `K`; `set_flags(flags)` (gates open with `zone.door_flag`, lever down with `zone.lever_flag`, key hidden once taken), `pull_lever()`, `see_through(camera_pos, hero_pos)` (the blocks of the two rows south of the hero whose box, grown 0.6 m, cuts the camera's lines to the hero's feet or chest get a shared see-through material, alpha 0.3).
```

with:

```markdown
- `scripts/world/dungeon_map.gd` (`DungeonMap`, `Node3D`) — the cells of a mine or castle floor (`zone.layout`, set `zone` before `add_child`): floor in 3 × 3-cell chunks (`zone.floor_color`); in a castle (`zone.castle`) every rock cell next to the floor is a stone wall instead of a rock block: the KayKit `wall_straight` piece ×2 (`WALL_SCALE`; 4 × 2.2 × 1.6 m, box collider) on straight runs (`_wall_kind()`: "ew" / "ns"), a 4 × 2.6 m tower with four merlons at corners, ends and junctions, a round pillar where the cell stands alone; a darker ground plane `OUTER_GROUND` 60 m past the grid, `zone.mist_banks` flat see-through mist banks drifting over floor cells, a throne on a dais on the `R` cell; in a mine a 4 × 3 × 4 m rock block with a box collider for every rock cell next to the floor (buried ones in one `MultiMesh`, no collider; three shades), torches on the `T` cells' walls (a flame and a flickering `OmniLight3D`, energy 2.5, range 8 m, no shadows), stairs (`S` steps up, `B` a dark pit, with a "Subir" / "Bajar" sign), iron gates on `D` (box collider while closed), the lever on `L` and a turning gold key on `K`; `set_flags(flags)` (gates open with `zone.door_flag`, lever down with `zone.lever_flag`, key hidden once taken), `pull_lever()`, `see_through(camera_pos, hero_pos)` (the blocks of the two rows south of the hero whose box, grown 0.6 m, cuts the camera's lines to the hero's feet or chest get a shared see-through material, alpha 0.3; in a castle the models and merlons under a block fade by their `transparency`).
```

14. Replace:

```markdown
- `scripts/world/world_stage.gd` (`WorldStage`) — static builder of any zone from its `ZoneData` (`build(root, zone)` returns the grass material, which `World` pushes away from the player each frame, or null without grass; a mine floor only gets its environment, its cells are `World`'s `DungeonMap`): the zone's sky and sun (`BattleStage.build_environment(root, zone)`), ground, dirt path and safe discs, buildings from `MODELS` (KayKit `building_*` at `BUILDING_SCALE` 3.5 with box colliders fitted to their meshes; `BUILDING_RADIUS` footprints), KayKit rocks with box colliders, trees scattered with the zone's seed (denser toward the walls, clumps within `tree_clump_inset` of them, kept off the path, glades, exits, autoplay route, rocks, buildings and chests, cylinder colliders inside the walls) and bushes (no collider), the trees and bushes each drawn as a `MultiMesh`; invisible walls at `half_size`, hills outside; `is_on_path(zone, pos, margin := 0.0)` (path, safe discs and the stair rooms of a mine floor are safe), `is_grass_free(pos, zone)`, `add_cylinder_shape()`.
```

with:

```markdown
- `scripts/world/world_stage.gd` (`WorldStage`) — static builder of any zone from its `ZoneData` (`build(root, zone)` returns the grass material, which `World` pushes away from the player each frame, or null without grass; a mine or castle floor only gets its environment and its `buildings` (the camp's tents), its cells are `World`'s `DungeonMap`): the zone's sky and sun (`BattleStage.build_environment(root, zone)`), ground, dirt path and safe discs, buildings from `MODELS` (KayKit `building_*` at `BUILDING_SCALE` 3.5 with box colliders fitted to their meshes; `BUILDING_RADIUS` footprints), KayKit rocks with box colliders, trees scattered with the zone's seed (denser toward the walls, clumps within `tree_clump_inset` of them, kept off the path, glades, exits, autoplay route, rocks, buildings and chests, cylinder colliders inside the walls) and bushes (no collider), the trees and bushes each drawn as a `MultiMesh`; invisible walls at `half_size`, hills outside; `is_on_path(zone, pos, margin := 0.0)` (path, safe discs and the stair rooms of a mine floor are safe), `is_grass_free(pos, zone)`, `add_cylinder_shape()`.
```

15. Replace:

```markdown
- `scripts/world/world_stage.gd` (`WorldStage`) — static builder of any zone from its `ZoneData` (`build(root, zone)` returns the grass material, which `World` pushes away from the player each frame, or null without grass; a mine or castle floor only gets its environment and its `buildings` (the camp's tents), its cells are `World`'s `DungeonMap`): the zone's sky and sun (`BattleStage.build_environment(root, zone)`), ground, dirt path and safe discs, buildings from `MODELS` (KayKit `building_*` at `BUILDING_SCALE` 3.5 with box colliders fitted to their meshes; `BUILDING_RADIUS` footprints), KayKit rocks with box colliders, trees scattered with the zone's seed (denser toward the walls, clumps within `tree_clump_inset` of them, kept off the path, glades, exits, autoplay route, rocks, buildings and chests, cylinder colliders inside the walls) and bushes (no collider), the trees and bushes each drawn as a `MultiMesh`; invisible walls at `half_size`, hills outside; `is_on_path(zone, pos, margin := 0.0)` (path, safe discs and the stair rooms of a mine floor are safe), `is_grass_free(pos, zone)`, `add_cylinder_shape()`.
```

with:

```markdown
- `scripts/world/world_stage.gd` (`WorldStage`) — static builder of any zone from its `ZoneData` (`build(root, zone)` returns the grass material, which `World` pushes away from the player each frame, or null without grass; a mine or castle floor only gets its environment and its `buildings` (the camp's tents), its cells are `World`'s `DungeonMap`): the zone's sky and sun (`BattleStage.build_environment(root, zone)`), ground, dirt path and safe discs, buildings from `MODELS` (KayKit `building_*` at `BUILDING_SCALE` 3.5, the `tent` at `MODEL_SCALES` 6.0 with box colliders fitted to their meshes; `BUILDING_RADIUS` footprints), KayKit rocks with box colliders, trees scattered with the zone's seed (denser toward the walls, clumps within `tree_clump_inset` of them, kept off the path, glades, exits, autoplay route, rocks, buildings and chests, cylinder colliders inside the walls) and bushes (no collider), the trees and bushes each drawn as a `MultiMesh`; invisible walls at `half_size`, hills outside; `is_on_path(zone, pos, margin := 0.0)` (path, safe discs and the stair rooms of a mine floor are safe), `is_grass_free(pos, zone)`, `add_cylinder_shape()`.
```

16. Replace:

```markdown
- `scripts/world/zone_data.gd` (`ZoneData`, `Resource`) — everything a map is built from, in `data/zones/<id>.tres` (`IDS`: `pradera`, `bosque`, `mina_1`, `mina_2`, `mina_3`): field `half_size` and `outer_margin`, ground and grass colors, `has_grass`, hills, `path_points`, `safe_discs`, the village (`village_name`, `village_pos`, `village_radius`), `buildings`, `rocks`, tree and bush parameters, `glades`, `entries` (id → [pos, yaw]), `start_entry`, `town_entry`, `exits` (id, pos, yaw, to, entry, label, lock, lock_text), `npcs`, `boss_id` / `boss_pos`, `formations` / `start_formations` / `start_pos` / `start_radius`, `encounter_grace` / `encounter_chance`, `music` / `village_music`, sky, haze, fog and sun, `backdrop`, `autoplay_route`, `autoplay_boss_level`, and for a mine floor `layout` (rows of `CELL` 4 m cells, north first: `#` rock, `.` floor, `S` stairs up, `B` stairs down, `C` chest, `L` lever, `D` locked gate, `K` key, `T` floor with a torch), `underground` (black background, `ambient_color` / `ambient_energy`, no sun), `rock_color`, `stairs_up` / `stairs_down` (zone ids), `lever_flag`, `door_flag` / `door_key` / `door_text`, `floor_key`; `by_id(id)`, `entry(id)` (`"S"` / `"B"`: the floor cell next to those stairs), `exit_by_id(id)`, `all_exits()` (plus one exit per stair cell), `is_dungeon()`, `grid_size()`, `cell_center(cell)`, `cell_at(pos)`, `cell_char(cell)`, `find_cells(ch)`, `near_stairs(pos)` (within 6 m). The meadow (`pradera.tres`) keeps the positions of phase 4 and gains the north exit to the forest (closed by fog until the Rey Slime is beaten); the forest (`bosque.tres`, 60 × 80 m) has the village in a clearing (houses, shop, inn, the Leñadora), three glades with chests, the Bruja del bosque's clearing to the north with the exit to the mine behind it (closed by fog until the Bruja is beaten) and the exit back south. The mine (`mina_1.tres`, `mina_2.tres`, `mina_3.tres`, 15 × 13 cells each, `music` "mine", `backdrop` "mina", encounters every 6 m + 2.5 % per metre): floor 1 has the refugio (Herrero, Posadero, Minera; the arch back to the forest) and the stairs down; floor 2 the lever that opens the gate in front of its stairs down; floor 3 the key that opens the Golem de piedra's room.
```

with:

```markdown
- `scripts/world/zone_data.gd` (`ZoneData`, `Resource`) — everything a map is built from, in `data/zones/<id>.tres` (`IDS`: `pradera`, `bosque`, `mina_1`, `mina_2`, `mina_3`, `castillo_patio`, `castillo_trono`): field `half_size` and `outer_margin`, ground and grass colors, `has_grass`, hills, `path_points`, `safe_discs`, the village (`village_name`, `village_pos`, `village_radius`), `buildings`, `rocks`, tree and bush parameters, `glades`, `entries` (id → [pos, yaw]), `start_entry`, `town_entry`, `exits` (id, pos, yaw, to, entry, label, lock, lock_text), `npcs`, `boss_id` / `boss_pos`, `formations` / `start_formations` / `start_pos` / `start_radius`, `encounter_grace` / `encounter_chance`, `music` / `village_music`, sky, haze, fog and sun, `backdrop`, `autoplay_route`, `autoplay_boss_level`, and for a mine floor `layout` (rows of `CELL` 4 m cells, north first: `#` rock, `.` floor, `S` stairs up, `B` stairs down, `C` chest, `L` lever, `D` locked gate, `K` key, `T` floor with a torch), `underground` (black background, `ambient_color` / `ambient_energy`, no sun), `rock_color`, `stairs_up` / `stairs_down` (zone ids), `lever_flag`, `door_flag` / `door_key` / `door_text`, `floor_key`; `by_id(id)`, `entry(id)` (`"S"` / `"B"`: the floor cell next to those stairs), `exit_by_id(id)`, `all_exits()` (plus one exit per stair cell), `is_dungeon()`, `grid_size()`, `cell_center(cell)`, `cell_at(pos)`, `cell_char(cell)`, `find_cells(ch)`, `near_stairs(pos)` (within 6 m). The meadow (`pradera.tres`) keeps the positions of phase 4 and gains the north exit to the forest (closed by fog until the Rey Slime is beaten); the forest (`bosque.tres`, 60 × 80 m) has the village in a clearing (houses, shop, inn, the Leñadora), three glades with chests, the Bruja del bosque's clearing to the north with the exit to the mine behind it (closed by fog until the Bruja is beaten) and the exit back south. The mine (`mina_1.tres`, `mina_2.tres`, `mina_3.tres`, 15 × 13 cells each, `music` "mine", `backdrop` "mina", encounters every 6 m + 2.5 % per metre): floor 1 has the refugio (Herrero, Posadero, Minera; the arch back to the forest) and the stairs down; floor 2 the lever that opens the gate in front of its stairs down; floor 3 the key that opens the Golem de piedra's room.
```

17. Replace:

```markdown
- `scripts/world/zone_data.gd` (`ZoneData`, `Resource`) — everything a map is built from, in `data/zones/<id>.tres` (`IDS`: `pradera`, `bosque`, `mina_1`, `mina_2`, `mina_3`, `castillo_patio`, `castillo_trono`): field `half_size` and `outer_margin`, ground and grass colors, `has_grass`, hills, `path_points`, `safe_discs`, the village (`village_name`, `village_pos`, `village_radius`), `buildings`, `rocks`, tree and bush parameters, `glades`, `entries` (id → [pos, yaw]), `start_entry`, `town_entry`, `exits` (id, pos, yaw, to, entry, label, lock, lock_text), `npcs`, `boss_id` / `boss_pos`, `formations` / `start_formations` / `start_pos` / `start_radius`, `encounter_grace` / `encounter_chance`, `music` / `village_music`, sky, haze, fog and sun, `backdrop`, `autoplay_route`, `autoplay_boss_level`, and for a mine floor `layout` (rows of `CELL` 4 m cells, north first: `#` rock, `.` floor, `S` stairs up, `B` stairs down, `C` chest, `L` lever, `D` locked gate, `K` key, `T` floor with a torch), `underground` (black background, `ambient_color` / `ambient_energy`, no sun), `rock_color`, `stairs_up` / `stairs_down` (zone ids), `lever_flag`, `door_flag` / `door_key` / `door_text`, `floor_key`; `by_id(id)`, `entry(id)` (`"S"` / `"B"`: the floor cell next to those stairs), `exit_by_id(id)`, `all_exits()` (plus one exit per stair cell), `is_dungeon()`, `grid_size()`, `cell_center(cell)`, `cell_at(pos)`, `cell_char(cell)`, `find_cells(ch)`, `near_stairs(pos)` (within 6 m). The meadow (`pradera.tres`) keeps the positions of phase 4 and gains the north exit to the forest (closed by fog until the Rey Slime is beaten); the forest (`bosque.tres`, 60 × 80 m) has the village in a clearing (houses, shop, inn, the Leñadora), three glades with chests, the Bruja del bosque's clearing to the north with the exit to the mine behind it (closed by fog until the Bruja is beaten) and the exit back south. The mine (`mina_1.tres`, `mina_2.tres`, `mina_3.tres`, 15 × 13 cells each, `music` "mine", `backdrop` "mina", encounters every 6 m + 2.5 % per metre): floor 1 has the refugio (Herrero, Posadero, Minera; the arch back to the forest) and the stairs down; floor 2 the lever that opens the gate in front of its stairs down; floor 3 the key that opens the Golem de piedra's room.
```

with:

```markdown
- `scripts/world/zone_data.gd` (`ZoneData`, `Resource`) — everything a map is built from, in `data/zones/<id>.tres` (`IDS`: `pradera`, `bosque`, `mina_1`, `mina_2`, `mina_3`, `castillo_patio`, `castillo_trono`): field `half_size` and `outer_margin`, ground and grass colors, `has_grass`, hills, `path_points`, `safe_discs`, the village (`village_name`, `village_pos`, `village_radius`), `buildings`, `rocks`, tree and bush parameters, `glades`, `entries` (id → [pos, yaw]), `start_entry`, `town_entry`, `exits` (id, pos, yaw, to, entry, label, lock, lock_text), `npcs`, `boss_id` / `boss_pos`, `formations` / `start_formations` / `start_pos` / `start_radius`, `encounter_grace` / `encounter_chance`, `music` / `village_music`, sky, haze, fog and sun, `backdrop`, `autoplay_route`, `autoplay_boss_level`, and for a mine floor `layout` (rows of `CELL` 4 m cells, north first: `#` rock, `.` floor, `S` stairs up, `B` stairs down, `C` chest, `L` lever, `D` locked gate, `K` key, `T` floor with a torch, `R` throne), `underground` (black background, `ambient_color` / `ambient_energy`, no sun), `rock_color`, `floor_color`, `castle` (stone walls instead of rock), `mist_banks`, `stairs_up` / `stairs_down` (zone ids), `lever_flag`, `door_flag` / `door_key` / `door_text`, `floor_key`; `by_id(id)`, `entry(id)` (`"S"` / `"B"`: the floor cell next to those stairs), `exit_by_id(id)`, `all_exits()` (plus one exit per stair cell), `is_dungeon()`, `grid_size()`, `cell_center(cell)`, `cell_at(pos)`, `cell_char(cell)`, `find_cells(ch)`, `near_stairs(pos)` (within 6 m). The meadow (`pradera.tres`) keeps the positions of phase 4 and gains the north exit to the forest (closed by fog until the Rey Slime is beaten); the forest (`bosque.tres`, 60 × 80 m) has the village in a clearing (houses, shop, inn, the Leñadora), three glades with chests, the Bruja del bosque's clearing to the north with the exit to the mine behind it (closed by fog until the Bruja is beaten) and the exit back south. The mine (`mina_1.tres`, `mina_2.tres`, `mina_3.tres`, 15 × 13 cells each, `music` "mine", `backdrop` "mina", encounters every 6 m + 2.5 % per metre): floor 1 has the refugio (Herrero, Posadero, Minera; the arch back to the forest) and the stairs down; floor 2 the lever that opens the gate in front of its stairs down; floor 3 the key that opens the Golem de piedra's room.
```

18. Replace:

```markdown
- `scripts/world/zone_data.gd` (`ZoneData`, `Resource`) — everything a map is built from, in `data/zones/<id>.tres` (`IDS`: `pradera`, `bosque`, `mina_1`, `mina_2`, `mina_3`, `castillo_patio`, `castillo_trono`): field `half_size` and `outer_margin`, ground and grass colors, `has_grass`, hills, `path_points`, `safe_discs`, the village (`village_name`, `village_pos`, `village_radius`), `buildings`, `rocks`, tree and bush parameters, `glades`, `entries` (id → [pos, yaw]), `start_entry`, `town_entry`, `exits` (id, pos, yaw, to, entry, label, lock, lock_text), `npcs`, `boss_id` / `boss_pos`, `formations` / `start_formations` / `start_pos` / `start_radius`, `encounter_grace` / `encounter_chance`, `music` / `village_music`, sky, haze, fog and sun, `backdrop`, `autoplay_route`, `autoplay_boss_level`, and for a mine floor `layout` (rows of `CELL` 4 m cells, north first: `#` rock, `.` floor, `S` stairs up, `B` stairs down, `C` chest, `L` lever, `D` locked gate, `K` key, `T` floor with a torch, `R` throne), `underground` (black background, `ambient_color` / `ambient_energy`, no sun), `rock_color`, `floor_color`, `castle` (stone walls instead of rock), `mist_banks`, `stairs_up` / `stairs_down` (zone ids), `lever_flag`, `door_flag` / `door_key` / `door_text`, `floor_key`; `by_id(id)`, `entry(id)` (`"S"` / `"B"`: the floor cell next to those stairs), `exit_by_id(id)`, `all_exits()` (plus one exit per stair cell), `is_dungeon()`, `grid_size()`, `cell_center(cell)`, `cell_at(pos)`, `cell_char(cell)`, `find_cells(ch)`, `near_stairs(pos)` (within 6 m). The meadow (`pradera.tres`) keeps the positions of phase 4 and gains the north exit to the forest (closed by fog until the Rey Slime is beaten); the forest (`bosque.tres`, 60 × 80 m) has the village in a clearing (houses, shop, inn, the Leñadora), three glades with chests, the Bruja del bosque's clearing to the north with the exit to the mine behind it (closed by fog until the Bruja is beaten) and the exit back south. The mine (`mina_1.tres`, `mina_2.tres`, `mina_3.tres`, 15 × 13 cells each, `music` "mine", `backdrop` "mina", encounters every 6 m + 2.5 % per metre): floor 1 has the refugio (Herrero, Posadero, Minera; the arch back to the forest) and the stairs down; floor 2 the lever that opens the gate in front of its stairs down; floor 3 the key that opens the Golem de piedra's room.
```

with:

```markdown
- `scripts/world/zone_data.gd` (`ZoneData`, `Resource`) — everything a map is built from, in `data/zones/<id>.tres` (`IDS`: `pradera`, `bosque`, `mina_1`, `mina_2`, `mina_3`, `castillo_patio`, `castillo_trono`): field `half_size` and `outer_margin`, ground and grass colors, `has_grass`, hills, `path_points`, `safe_discs`, the village (`village_name`, `village_pos`, `village_radius`), `buildings`, `rocks`, tree and bush parameters, `glades`, `entries` (id → [pos, yaw]), `start_entry`, `town_entry`, `exits` (id, pos, yaw, to, entry, label, lock, lock_text), `npcs`, `boss_id` / `boss_pos`, `formations` / `start_formations` / `start_pos` / `start_radius`, `encounter_grace` / `encounter_chance`, `music` / `village_music`, sky, haze, fog and sun, `backdrop`, `autoplay_route`, `autoplay_boss_level`, and for a mine floor `layout` (rows of `CELL` 4 m cells, north first: `#` rock, `.` floor, `S` stairs up, `B` stairs down, `C` chest, `L` lever, `D` locked gate, `K` key, `T` floor with a torch, `R` throne), `underground` (black background, `ambient_color` / `ambient_energy`, no sun), `rock_color`, `floor_color`, `castle` (stone walls instead of rock), `mist_banks`, `stairs_up` / `stairs_down` (zone ids), `lever_flag`, `door_flag` / `door_key` / `door_text`, `floor_key`; `by_id(id)`, `entry(id)` (`"S"` / `"B"`: the floor cell next to those stairs), `exit_by_id(id)`, `all_exits()` (plus one exit per stair cell), `is_dungeon()`, `grid_size()`, `cell_center(cell)`, `cell_at(pos)`, `cell_char(cell)`, `find_cells(ch)`, `near_stairs(pos)` (within 6 m). The meadow (`pradera.tres`) keeps the positions of phase 4 and gains the north exit to the forest (closed by fog until the Rey Slime is beaten); the forest (`bosque.tres`, 60 × 80 m) has the village in a clearing (houses, shop, inn, the Leñadora), three glades with chests, the Bruja del bosque's clearing to the north with the exit to the mine behind it (closed by fog until the Bruja is beaten) and the exit back south. The mine (`mina_1.tres`, `mina_2.tres`, `mina_3.tres`, 15 × 13 cells each, `music` "mine", `backdrop` "mina", encounters every 6 m + 2.5 % per metre): floor 1 has the refugio (Herrero, Posadero, Minera; the arch back to the forest) and the stairs down; floor 2 the lever that opens the gate in front of its stairs down; floor 3 the key that opens the Golem de piedra's room and, behind the Golem, the tunnel "Al castillo" (closed by fog until the Golem is beaten). The castle (`music` "castle", `backdrop` "castillo", the same encounter pace): `castillo_patio.tres` (17 × 15 cells, open sky with dense violet fog and 10 mist banks) has the camp in its south bailey (Mercader, Posadera, Soldado, two tents; the arch back to the mine) and the courtyard behind the gate with two chests and the stairs up; `castillo_trono.tres` (13 × 13, dark indoor hall with pillars) has the throne, the Señor de la Niebla in front of it, a chest and the stairs down.
```

19. Replace:

```markdown
- `scripts/battle/enemy_library.gd` (`EnemyLibrary`, `RefCounted`) — every enemy by id (`ENEMIES`: `data/enemies/<id>.tres`: slime, bat, mushroom, rey_slime, lobo, duende, planta, bruja, golem_barro, arana, espectro, golem_piedra) and its figure (`LOOKS`); `data(id)`, `look(id)` (slime if unknown), `formation(ids)`.
```

with:

```markdown
- `scripts/battle/enemy_library.gd` (`EnemyLibrary`, `RefCounted`) — every enemy by id (`ENEMIES`: `data/enemies/<id>.tres`: slime, bat, mushroom, rey_slime, lobo, duende, planta, bruja, golem_barro, arana, espectro, golem_piedra, esqueleto_guerrero, esqueleto_picaro, esqueleto_mago, senor_niebla) and its figure (`LOOKS`); `data(id)`, `look(id)` (slime if unknown), `formation(ids)`.
```

20. Replace:

```markdown
- `scripts/battle/battle_engine.gd` (`BattleEngine`, `RefCounted`) — pure round rules for the hero against `enemies: Array[Combatant]` (fighters are ints: `BattleEvent.HERO` = −1 or an enemy index). Commands are dictionaries from `cmd_attack(target)`, `cmd_skill(skill, target)`, `cmd_item(id)`, `cmd_defend()`, `cmd_flee()`, `cmd_none()`; `problem(cmd)` (why not: "Faltan PM", "Silencio", item reasons), `can_use(cmd)`, `alive_enemies()`, `has_boss()`, `flee_chance()`. Each enemy picks when its turn comes, from `ai_weights` (`"attack"`, `"stagger"`, `"charge"` or a skill id; after a charge — the Golem de piedra: "El Golem de piedra acumula fuerza..." — its next turn is a blow of `CHARGE_MULT` 2× the damage that never misses or crits, which Defender halves; `is_charged(i)`), casts its `rescue_heal` once below `rescue_heal_ratio` of max HP (the Bruja: Curar 40 PV below 40 %), or calls its `help` once below 50 % HP while fewer than `MAX_ENEMIES` 2 stand. Initiative `speed × randf_range(0.5, 1.5)` (defending or fleeing, the hero goes first); attacks: 5 % miss, 1/16 crit (ignores DEF), damage `base × randf_range(0.875, 1.125)` rounded, minimum 1, where `base = max(1, total ATK − total DEF/2)` (crit: `ATK × 1.5`), may cause the attacker's `attack_status`; spells pay MP: damage `power × the same spread × 1.5 weak / 0.5 resist`, ignoring DEF, no miss or crit, may cause their status; heals restore `power`. Defend halves the damage taken that round (rounded up, min 1). Flee: `clamp(0.5 + (hero VEL − mean enemy VEL) × 0.05, 0.2, 0.95)`; against a boss only `NO_ESCAPE`, no turn passes. Status (`Combatant.status`): poison 8 % max HP at the end of each round; sleep loses the turn, 50 % to wake at the end of each round, damage wakes; silence 3 rounds without spells; all cleared when the battle ends. On victory: `exp_won`, `gold_won`, `Leveling.apply()`, each enemy's `drops` rolls (`drops_won`). Returns `Array[Dictionary]` events built by `BattleEvent` (`scripts/battle/battle_event.gd`); `state` is `ONGOING`, `WON`, `LOST` or `FLED`. Never touches nodes.
```

with:

```markdown
- `scripts/battle/battle_engine.gd` (`BattleEngine`, `RefCounted`) — pure round rules for the hero against `enemies: Array[Combatant]` (fighters are ints: `BattleEvent.HERO` = −1 or an enemy index). Commands are dictionaries from `cmd_attack(target)`, `cmd_skill(skill, target)`, `cmd_item(id)`, `cmd_defend()`, `cmd_flee()`, `cmd_none()`; `problem(cmd)` (why not: "Faltan PM", "Silencio", item reasons), `can_use(cmd)`, `alive_enemies()`, `has_boss()`, `flee_chance()`. Each enemy picks when its turn comes, from `ai_weights` (`"attack"`, `"stagger"`, `"charge"` or a skill id; after a charge — the Golem de piedra: "El Golem de piedra acumula fuerza..." — its next turn is a blow of `CHARGE_MULT` 2× the damage that never misses or crits, which Defender halves; `is_charged(i)`; a boss with a `next_phase` that reaches 0 HP rises once with that phase's HP, MP, ATK, DEF, VEL, skills and weights instead of falling — a `PHASE` event, the Señor de la Niebla's second phase), casts its `rescue_heal` once below `rescue_heal_ratio` of max HP (the Bruja: Curar 40 PV below 40 %), or calls its `help` once below 50 % HP while fewer than `MAX_ENEMIES` 2 stand. Initiative `speed × randf_range(0.5, 1.5)` (defending or fleeing, the hero goes first); attacks: 5 % miss, 1/16 crit (ignores DEF), damage `base × randf_range(0.875, 1.125)` rounded, minimum 1, where `base = max(1, total ATK − total DEF/2)` (crit: `ATK × 1.5`), may cause the attacker's `attack_status`; spells pay MP: damage `power × the same spread × 1.5 weak / 0.5 resist`, ignoring DEF, no miss or crit, may cause their status; heals restore `power`. Defend halves the damage taken that round (rounded up, min 1). Flee: `clamp(0.5 + (hero VEL − mean enemy VEL) × 0.05, 0.2, 0.95)`; against a boss only `NO_ESCAPE`, no turn passes. Status (`Combatant.status`): poison 8 % max HP at the end of each round; sleep loses the turn, 50 % to wake at the end of each round, damage wakes; silence 3 rounds without spells; all cleared when the battle ends. On victory: `exp_won`, `gold_won`, `Leveling.apply()`, each enemy's `drops` rolls (`drops_won`). Returns `Array[Dictionary]` events built by `BattleEvent` (`scripts/battle/battle_event.gd`); `state` is `ONGOING`, `WON`, `LOST` or `FLED`. Never touches nodes.
```

21. Replace:

```markdown
- `scripts/battle/combatant.gd` (`Combatant`, `Resource`) — fighter stats (`id`, `female`, level, HP, MP, base `attack` / `defense` plus hero-only `equip_attack` / `equip_defense` (the loadout bonuses, set by `GameState.refresh_equipment()`; `total_attack()` / `total_defense()`), speed, `skills`, hero-only `learn` (level → Skill), EXP; enemy-only `exp_reward`, `gold_reward`, `ai_weights`, `weak` / `resist` (elements), `drops` (item id → chance), `attack_status` / `attack_status_chance`, `help` (Combatant it calls), `rescue_heal` / `rescue_heal_ratio` (a heal cast once), boss-only `key_item`, `is_boss`); battle-only `status` (status → rounds, −1 until cured). Data in `data/hero.tres` and `data/enemies/*.tres` (`EnemyLibrary`); the enemies' own spells are `data/skills/llama_duende.tres`, `llamarada_bruja.tres`, `curar_bruja.tres` and `hielo_espectro.tres`.
```

with:

```markdown
- `scripts/battle/combatant.gd` (`Combatant`, `Resource`) — fighter stats (`id`, `female`, level, HP, MP, base `attack` / `defense` plus hero-only `equip_attack` / `equip_defense` (the loadout bonuses, set by `GameState.refresh_equipment()`; `total_attack()` / `total_defense()`), speed, `skills`, hero-only `learn` (level → Skill), EXP; enemy-only `exp_reward`, `gold_reward`, `ai_weights`, `weak` / `resist` (elements), `drops` (item id → chance), `attack_status` / `attack_status_chance`, `help` (Combatant it calls), `rescue_heal` / `rescue_heal_ratio` (a heal cast once), boss-only `key_item`, `next_phase` (the stats of its second phase), `is_boss`); battle-only `status` (status → rounds, −1 until cured). Data in `data/hero.tres` and `data/enemies/*.tres` (`EnemyLibrary`); the enemies' own spells are `data/skills/llama_duende.tres`, `llamarada_bruja.tres`, `curar_bruja.tres` and `hielo_espectro.tres`.
```

22. Replace:

```markdown
- `scripts/battle/combatant.gd` (`Combatant`, `Resource`) — fighter stats (`id`, `female`, level, HP, MP, base `attack` / `defense` plus hero-only `equip_attack` / `equip_defense` (the loadout bonuses, set by `GameState.refresh_equipment()`; `total_attack()` / `total_defense()`), speed, `skills`, hero-only `learn` (level → Skill), EXP; enemy-only `exp_reward`, `gold_reward`, `ai_weights`, `weak` / `resist` (elements), `drops` (item id → chance), `attack_status` / `attack_status_chance`, `help` (Combatant it calls), `rescue_heal` / `rescue_heal_ratio` (a heal cast once), boss-only `key_item`, `next_phase` (the stats of its second phase), `is_boss`); battle-only `status` (status → rounds, −1 until cured). Data in `data/hero.tres` and `data/enemies/*.tres` (`EnemyLibrary`); the enemies' own spells are `data/skills/llama_duende.tres`, `llamarada_bruja.tres`, `curar_bruja.tres` and `hielo_espectro.tres`.
```

with:

```markdown
- `scripts/battle/combatant.gd` (`Combatant`, `Resource`) — fighter stats (`id`, `female`, level, HP, MP, base `attack` / `defense` plus hero-only `equip_attack` / `equip_defense` (the loadout bonuses, set by `GameState.refresh_equipment()`; `total_attack()` / `total_defense()`), speed, `skills`, hero-only `learn` (level → Skill), EXP; enemy-only `exp_reward`, `gold_reward`, `ai_weights`, `weak` / `resist` (elements), `drops` (item id → chance), `attack_status` / `attack_status_chance`, `help` (Combatant it calls), `rescue_heal` / `rescue_heal_ratio` (a heal cast once), boss-only `key_item`, `next_phase` (the stats of its second phase), `is_boss`); battle-only `status` (status → rounds, −1 until cured). Data in `data/hero.tres` and `data/enemies/*.tres` (`EnemyLibrary`); the enemies' own spells are `data/skills/llama_duende.tres`, `llamarada_bruja.tres`, `curar_bruja.tres`, `hielo_espectro.tres`, `rayo_esqueleto.tres`, `rayo_senor.tres` and `niebla.tres` (all targets, 30, 30 % silence); the Señor de la Niebla's second phase is `senor_niebla_2.tres`.
```

23. Replace:

```markdown
- `scenes/battle/battle_actor.tscn` + `scripts/battle/battle_actor.gd` (`BattleActor`) — figure of a fighter or villager built from the `LOOKS` table (`look`: `HERO` / `SLIME` / `VILLAGER` / `KING_SLIME` / `BAT` / `MUSHROOM` / `MERCHANT` / `INNKEEPER` / `WOLF` / `GOBLIN` / `PLANT` / `WITCH` / `MUD_GOLEM` / `STONE_GOLEM` / `SPIDER` / `SPECTER`, set before `add_child`), faces -Z. `HERO` is KayKit `Knight.glb` (every hand mesh hidden; `set_equipment(weapon, shield)` shows the `Equipment.mesh()` of each under `handslot_r` / `handslot_l`, plus a wooden stick built in code for the Palo), `VILLAGER` is `Mage.glb`, `MERCHANT` / `INNKEEPER` the same Mage tinted green / orange (`tint`), `WITCH` the Mage at scale 0.75 tinted dark purple, wand kept (scale 0.65, turned 180°, unused props hidden, `AnimationPlayer` at `AnimationPlayer`, roles in `CHARACTER_ANIMS`: `Idle`, `Running_A`, `1H_Melee_Attack_Slice_Diagonal`, `Spellcast_Shoot`, `Hit_A`, `Dodge_Backward`, `Death_A`, `Cheer`); `SLIME` / `KING_SLIME` are faceted `LowPoly` blobs with eyes (king ×1.6 with a gold crown) that bounce while idle; `BAT` hovers at 1.1 m flapping two box wings; `MUSHROOM` is a stem with eyes and a spotted hemisphere cap (×1.4) that bounces; `WOLF` is a faceted body and wedge head on four legs (breathes); `GOBLIN` a small green slime with pointed ears and a red hat; `PLANT` a stem with leaves and a two-jaw head that sways and opens its upper jaw to bite in `play_attack`; `MUD_GOLEM` / `STONE_GOLEM` faceted blocks (legs, body, head, long arms) with glowing eyes, the stone one grey and ×1.55; `SPIDER` a round abdomen and small head with red eyes on eight bent legs; `SPECTER` a see-through pale drop with a blue aura that floats up and down (its materials fade with `play_defeat`). Awaitable `play_attack`, `play_hit(amount, crit, tag)` (flash overlay + floating `Label3D` number, `tag` "¡Débil!" / "¡Resiste!" under it), `play_dodge`, `play_defeat` (characters stay down, the rest fade and hide), `play_cast(color)`, `play_burn(amount, color, tag)`, `play_heal(amount, color)`, `play_status(color, amount)`, `play_appear()`, `play_stagger`, `play_cheer`; `top_height()`; `set_walking(on)` for the map; `reset()`.
```

with:

```markdown
- `scenes/battle/battle_actor.tscn` + `scripts/battle/battle_actor.gd` (`BattleActor`) — figure of a fighter or villager built from the `LOOKS` table (`look`: `HERO` / `SLIME` / `VILLAGER` / `KING_SLIME` / `BAT` / `MUSHROOM` / `MERCHANT` / `INNKEEPER` / `WOLF` / `GOBLIN` / `PLANT` / `WITCH` / `MUD_GOLEM` / `STONE_GOLEM` / `SPIDER` / `SPECTER` / `SKELETON_WARRIOR` / `SKELETON_ROGUE` / `SKELETON_MAGE` / `FOG_LORD`, set before `add_child`), faces -Z. `HERO` is KayKit `Knight.glb` (every hand mesh hidden; `set_equipment(weapon, shield)` shows the `Equipment.mesh()` of each under `handslot_r` / `handslot_l`, plus a wooden stick built in code for the Palo), `VILLAGER` is `Mage.glb`, `MERCHANT` / `INNKEEPER` the same Mage tinted green / orange (`tint`), `WITCH` the Mage at scale 0.75 tinted dark purple, wand kept (scale 0.65, turned 180°, unused props hidden, `AnimationPlayer` at `AnimationPlayer`, roles in `CHARACTER_ANIMS`: `Idle`, `Running_A`, `1H_Melee_Attack_Slice_Diagonal`, `Spellcast_Shoot`, `Hit_A`, `Dodge_Backward`, `Death_A`, `Cheer`); `SLIME` / `KING_SLIME` are faceted `LowPoly` blobs with eyes (king ×1.6 with a gold crown) that bounce while idle; `BAT` hovers at 1.1 m flapping two box wings; `MUSHROOM` is a stem with eyes and a spotted hemisphere cap (×1.4) that bounces; `WOLF` is a faceted body and wedge head on four legs (breathes); `GOBLIN` a small green slime with pointed ears and a red hat; `PLANT` a stem with leaves and a two-jaw head that sways and opens its upper jaw to bite in `play_attack`; `MUD_GOLEM` / `STONE_GOLEM` faceted blocks (legs, body, head, long arms) with glowing eyes, the stone one grey and ×1.55; `SPIDER` a round abdomen and small head with red eyes on eight bent legs; `SPECTER` a see-through pale drop with a blue aura that floats up and down (its materials fade with `play_defeat`). Awaitable `play_attack`, `play_hit(amount, crit, tag)` (flash overlay + floating `Label3D` number, `tag` "¡Débil!" / "¡Resiste!" under it), `play_dodge`, `play_defeat` (characters stay down, the rest fade and hide), `play_cast(color)`, `play_burn(amount, color, tag)`, `play_heal(amount, color)`, `play_status(color, amount)`, `play_appear()`, `play_stagger`, `play_cheer`; `top_height()`; `set_walking(on)` for the map; `reset()`.
```

24. Replace:

```markdown
- `scenes/battle/battle_actor.tscn` + `scripts/battle/battle_actor.gd` (`BattleActor`) — figure of a fighter or villager built from the `LOOKS` table (`look`: `HERO` / `SLIME` / `VILLAGER` / `KING_SLIME` / `BAT` / `MUSHROOM` / `MERCHANT` / `INNKEEPER` / `WOLF` / `GOBLIN` / `PLANT` / `WITCH` / `MUD_GOLEM` / `STONE_GOLEM` / `SPIDER` / `SPECTER` / `SKELETON_WARRIOR` / `SKELETON_ROGUE` / `SKELETON_MAGE` / `FOG_LORD`, set before `add_child`), faces -Z. `HERO` is KayKit `Knight.glb` (every hand mesh hidden; `set_equipment(weapon, shield)` shows the `Equipment.mesh()` of each under `handslot_r` / `handslot_l`, plus a wooden stick built in code for the Palo), `VILLAGER` is `Mage.glb`, `MERCHANT` / `INNKEEPER` the same Mage tinted green / orange (`tint`), `WITCH` the Mage at scale 0.75 tinted dark purple, wand kept (scale 0.65, turned 180°, unused props hidden, `AnimationPlayer` at `AnimationPlayer`, roles in `CHARACTER_ANIMS`: `Idle`, `Running_A`, `1H_Melee_Attack_Slice_Diagonal`, `Spellcast_Shoot`, `Hit_A`, `Dodge_Backward`, `Death_A`, `Cheer`); `SLIME` / `KING_SLIME` are faceted `LowPoly` blobs with eyes (king ×1.6 with a gold crown) that bounce while idle; `BAT` hovers at 1.1 m flapping two box wings; `MUSHROOM` is a stem with eyes and a spotted hemisphere cap (×1.4) that bounces; `WOLF` is a faceted body and wedge head on four legs (breathes); `GOBLIN` a small green slime with pointed ears and a red hat; `PLANT` a stem with leaves and a two-jaw head that sways and opens its upper jaw to bite in `play_attack`; `MUD_GOLEM` / `STONE_GOLEM` faceted blocks (legs, body, head, long arms) with glowing eyes, the stone one grey and ×1.55; `SPIDER` a round abdomen and small head with red eyes on eight bent legs; `SPECTER` a see-through pale drop with a blue aura that floats up and down (its materials fade with `play_defeat`). Awaitable `play_attack`, `play_hit(amount, crit, tag)` (flash overlay + floating `Label3D` number, `tag` "¡Débil!" / "¡Resiste!" under it), `play_dodge`, `play_defeat` (characters stay down, the rest fade and hide), `play_cast(color)`, `play_burn(amount, color, tag)`, `play_heal(amount, color)`, `play_status(color, amount)`, `play_appear()`, `play_stagger`, `play_cheer`; `top_height()`; `set_walking(on)` for the map; `reset()`.
```

with:

```markdown
- `scenes/battle/battle_actor.tscn` + `scripts/battle/battle_actor.gd` (`BattleActor`) — figure of a fighter or villager built from the `LOOKS` table (`look`: `HERO` / `SLIME` / `VILLAGER` / `KING_SLIME` / `BAT` / `MUSHROOM` / `MERCHANT` / `INNKEEPER` / `WOLF` / `GOBLIN` / `PLANT` / `WITCH` / `MUD_GOLEM` / `STONE_GOLEM` / `SPIDER` / `SPECTER` / `SKELETON_WARRIOR` / `SKELETON_ROGUE` / `SKELETON_MAGE` / `FOG_LORD`, set before `add_child`), faces -Z. `HERO` is KayKit `Knight.glb` (every hand mesh hidden; `set_equipment(weapon, shield)` shows the `Equipment.mesh()` of each under `handslot_r` / `handslot_l`, plus a wooden stick built in code for the Palo), `VILLAGER` is `Mage.glb`, `MERCHANT` / `INNKEEPER` the same Mage tinted green / orange (`tint`), `WITCH` the Mage at scale 0.75 tinted dark purple, wand kept (scale 0.65, turned 180°, unused props hidden, `AnimationPlayer` at `AnimationPlayer`, roles in `CHARACTER_ANIMS`: `Idle`, `Running_A`, `1H_Melee_Attack_Slice_Diagonal`, `Spellcast_Shoot`, `Hit_A`, `Dodge_Backward`, `Death_A`, `Cheer`); `SLIME` / `KING_SLIME` are faceted `LowPoly` blobs with eyes (king ×1.6 with a gold crown) that bounce while idle; `BAT` hovers at 1.1 m flapping two box wings; `MUSHROOM` is a stem with eyes and a spotted hemisphere cap (×1.4) that bounces; `WOLF` is a faceted body and wedge head on four legs (breathes); `GOBLIN` a small green slime with pointed ears and a red hat; `PLANT` a stem with leaves and a two-jaw head that sways and opens its upper jaw to bite in `play_attack`; `MUD_GOLEM` / `STONE_GOLEM` faceted blocks (legs, body, head, long arms) with glowing eyes, the stone one grey and ×1.55; `SPIDER` a round abdomen and small head with red eyes on eight bent legs; `SPECTER` a see-through pale drop with a blue aura that floats up and down (its materials fade with `play_defeat`); the skeletons are KayKit `Skeleton_Warrior` (blade and shield), `Skeleton_Rogue` (two blades, dual-wield stab) and `Skeleton_Mage` (staff) with `SKELETON_ANIMS` (`Walking_D_Skeletons`, `Hit_B`, `Death_C_Skeletons`, `Taunt`), their weapons on `BoneAttachment3D`s of `handslot.r` / `handslot.l` (`props`); `FOG_LORD` is the Skeleton_Mage ×1.6 tinted violet in a purple aura, and `play_phase()` swells and thickens the aura. Awaitable `play_attack`, `play_hit(amount, crit, tag)` (flash overlay + floating `Label3D` number, `tag` "¡Débil!" / "¡Resiste!" under it), `play_dodge`, `play_defeat` (characters stay down, the rest fade and hide), `play_cast(color)`, `play_burn(amount, color, tag)`, `play_heal(amount, color)`, `play_status(color, amount)`, `play_appear()`, `play_stagger`, `play_cheer`; `top_height()`; `set_walking(on)` for the map; `reset()`.
```

25. Replace:

```markdown
- `scripts/battle/battle_stage.gd` (`BattleStage`) — battle backdrop builder, `build(root, zone)` (tall grass around the fighters, none where they stand; KayKit rocks and trees and low-poly bushes around them; the `bosque` backdrop has darker ground and grass and `FOREST_TREES` close around; `mina` is a cave: rock floor, `CAVE_BLOCKS` wall, boulders, stalagmites, two torches and a lantern light, no grass); `build_environment(root, zone)` (procedural sky, ACES tonemap, SSAO, glow, the zone's fog, haze and sun with shadows; an `underground` zone gets a black background, a flat ambient light and no sun), `add_mesh()`, `unit_sphere()`, `add_model(root, scene, pos, scl, yaw_deg)`, `scene_mesh(scene)`, `model_aabb(model)`, `rock_radius(rock)`, `ROCK_SCENES` and `ROCK_RADII` are shared with `WorldStage`.
```

with:

```markdown
- `scripts/battle/battle_stage.gd` (`BattleStage`) — battle backdrop builder, `build(root, zone)` (tall grass around the fighters, none where they stand; KayKit rocks and trees and low-poly bushes around them; the `bosque` backdrop has darker ground and grass and `FOREST_TREES` close around; `mina` is a cave: rock floor, `CAVE_BLOCKS` wall, boulders, stalagmites, two torches and a lantern light, no grass; `castillo` is a castle yard: flagstones, `CASTLE_WALLS` of KayKit wall pieces, `CASTLE_TOWERS`, `CASTLE_MIST` banks, two torches, and the lantern when the zone is `underground`); `build_environment(root, zone)` (procedural sky, ACES tonemap, SSAO, glow, the zone's fog, haze and sun with shadows; an `underground` zone gets a black background, a flat ambient light and no sun), `add_mesh()`, `unit_sphere()`, `add_model(root, scene, pos, scl, yaw_deg)`, `scene_mesh(scene)`, `model_aabb(model)`, `rock_radius(rock)`, `ROCK_SCENES` and `ROCK_RADII` are shared with `WorldStage`.
```

26. Replace:

```markdown
- `assets/` — only the models in use, copied unchanged from the CC0 KayKit packs kept (git-ignored) in `assets_src/`: `characters/` (Adventurers: `Knight.glb`, `Mage.glb` and their extracted textures) and `medieval/` (Medieval Hexagon: red houses and well of Villaclaro, green houses, market, tavern and well of the forest village, rocks, trees, shared `hexagons_medieval.png`); `assets/CREDITS.md` lists packs, author and licence.
```

with:

```markdown
- `assets/` — only the models in use, copied unchanged from the CC0 KayKit packs kept (git-ignored) in `assets_src/`: `characters/` (Adventurers: `Knight.glb`, `Mage.glb` and their extracted textures; Skeletons: `Skeleton_Warrior.glb`, `Skeleton_Rogue.glb`, `Skeleton_Mage.glb`, the weapons `Skeleton_Blade`, `Skeleton_Staff` and `Skeleton_Shield_Small_A` and `skeleton_texture.png`) and `medieval/` (Medieval Hexagon: red houses and well of Villaclaro, green houses, market, tavern and well of the forest village, rocks, trees, shared `hexagons_medieval.png`); `assets/CREDITS.md` lists packs, author and licence.
```

27. Replace:

```markdown
- `assets/` — only the models in use, copied unchanged from the CC0 KayKit packs kept (git-ignored) in `assets_src/`: `characters/` (Adventurers: `Knight.glb`, `Mage.glb` and their extracted textures; Skeletons: `Skeleton_Warrior.glb`, `Skeleton_Rogue.glb`, `Skeleton_Mage.glb`, the weapons `Skeleton_Blade`, `Skeleton_Staff` and `Skeleton_Shield_Small_A` and `skeleton_texture.png`) and `medieval/` (Medieval Hexagon: red houses and well of Villaclaro, green houses, market, tavern and well of the forest village, rocks, trees, shared `hexagons_medieval.png`); `assets/CREDITS.md` lists packs, author and licence.
```

with:

```markdown
- `assets/` — only the models in use, copied unchanged from the CC0 KayKit packs kept (git-ignored) in `assets_src/`: `characters/` (Adventurers: `Knight.glb`, `Mage.glb` and their extracted textures; Skeletons: `Skeleton_Warrior.glb`, `Skeleton_Rogue.glb`, `Skeleton_Mage.glb`, the weapons `Skeleton_Blade`, `Skeleton_Staff` and `Skeleton_Shield_Small_A` and `skeleton_texture.png`) and `medieval/` (Medieval Hexagon: red houses and well of Villaclaro, green houses, market, tavern and well of the forest village, rocks, trees, the castle's `wall_straight` and the camp's `tent`, shared `hexagons_medieval.png`); `assets/CREDITS.md` lists packs, author and licence.
```

28. Replace:

```markdown
- `scripts/audio/music_library.gd` (`MusicLibrary`) — original tracks as note tables (`TRACKS`: bpm, loop, lead duty, bars of tokens like `"F#5/4"` = note / length in sixteenths, `r` rest, drums `k` / `s` / `h`): title, map, village (waltz), forest (E minor), mine (D minor, 88 bpm), battle, boss loop; victory and defeat don't. `build(id)` synthesizes square lead, triangle bass and noise drums into a cached `AudioStreamWAV` (22050 Hz, 16-bit mono, `LOOP_FORWARD` over the whole track); `to_stream()`, `peak()`, `clear_cache()`.
```

with:

```markdown
- `scripts/audio/music_library.gd` (`MusicLibrary`) — original tracks as note tables (`TRACKS`: bpm, loop, lead duty, bars of tokens like `"F#5/4"` = note / length in sixteenths, `r` rest, drums `k` / `s` / `h`): title, map, village (waltz), forest (E minor), mine (D minor, 88 bpm), castle (E minor march, 76 bpm), battle, boss loop; victory and defeat don't. `build(id)` synthesizes square lead, triangle bass and noise drums into a cached `AudioStreamWAV` (22050 Hz, 16-bit mono, `LOOP_FORWARD` over the whole track); `to_stream()`, `peak()`, `clear_cache()`.
```

29. Replace:

```markdown
- Start a new autoplay game in another zone (`--autoplay-zone=bosque`: Lv 5, 150 G, the zone 1 gear, the Rey Slime beaten; it buys the forest gear, sleeps at the inn when below half HP and fights the Bruja at Lv 9, then walks on into the mine): `.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 40000 -- --autoplay --autoplay-zone=bosque`. The mine: `--autoplay-zone=mina_1` (the three floors: shop, chests, lever, key, gate, Golem from Lv 13) or `--autoplay-zone=mina_3` (straight to the Golem at Lv 13).
```

with:

```markdown
- Start a new autoplay game in another zone (`--autoplay-zone=bosque`: Lv 5, 150 G, the zone 1 gear, the Rey Slime beaten; it buys the forest gear, sleeps at the inn when below half HP and fights the Bruja at Lv 9, then walks on into the mine): `.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 40000 -- --autoplay --autoplay-zone=bosque`. The mine: `--autoplay-zone=mina_1` (the three floors: shop, chests, lever, key, gate, Golem from Lv 13) or `--autoplay-zone=mina_3` (straight to the Golem at Lv 13). The castle: `--autoplay-zone=castillo_patio` (the camp's shop, the courtyard and its chests, the throne room; the Señor de la Niebla from Lv 17, then `Juego completado: ...` and it quits) or `--autoplay-zone=castillo_trono` (straight to the Señor at Lv 17).
- Whole game on autoplay, from a new game to the Señor de la Niebla (headless, under a minute of real time): `.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 150000 -- --autoplay`; it ends with `Juego completado: Nv n, tiempo de juego h:mm:ss` (1:30-1:56 in the runs of the castle plan).
```

In `assets/CREDITS.md`:

1. Replace:

```markdown
| KayKit – Medieval Hexagon Pack 1.0 | Kay Lousberg (www.kaylousberg.com) | https://github.com/KayKit-Game-Assets/KayKit-Medieval-Hexagon-Pack-1.0 | CC0 1.0 | `medieval/building_home_A_red`, `building_home_B_red`, `building_well_red`, `building_home_A_green`, `building_home_B_green`, `building_market_green`, `building_tavern_green`, `building_well_green`, `rock_single_A`–`E`, `tree_single_A`, `tree_single_B`, `trees_A_medium`, `trees_B_medium`, `hexagons_medieval.png` |
```

with:

```markdown
| KayKit – Skeletons Character Pack 1.0 | Kay Lousberg (www.kaylousberg.com) | https://github.com/KayKit-Game-Assets/KayKit-Character-Pack-Skeletons-1.0 | CC0 1.0 | `characters/Skeleton_Warrior.glb`, `Skeleton_Rogue.glb`, `Skeleton_Mage.glb` (and the textures Godot extracts from them), `Skeleton_Blade.gltf`, `Skeleton_Staff.gltf`, `Skeleton_Shield_Small_A.gltf` (with their `.bin`) and `skeleton_texture.png` |
| KayKit – Medieval Hexagon Pack 1.0 | Kay Lousberg (www.kaylousberg.com) | https://github.com/KayKit-Game-Assets/KayKit-Medieval-Hexagon-Pack-1.0 | CC0 1.0 | `medieval/building_home_A_red`, `building_home_B_red`, `building_well_red`, `building_home_A_green`, `building_home_B_green`, `building_market_green`, `building_tavern_green`, `building_well_green`, `rock_single_A`–`E`, `tree_single_A`, `tree_single_B`, `trees_A_medium`, `trees_B_medium`, `hexagons_medieval.png` |
```

2. Replace:

```markdown
| KayKit – Medieval Hexagon Pack 1.0 | Kay Lousberg (www.kaylousberg.com) | https://github.com/KayKit-Game-Assets/KayKit-Medieval-Hexagon-Pack-1.0 | CC0 1.0 | `medieval/building_home_A_red`, `building_home_B_red`, `building_well_red`, `building_home_A_green`, `building_home_B_green`, `building_market_green`, `building_tavern_green`, `building_well_green`, `rock_single_A`–`E`, `tree_single_A`, `tree_single_B`, `trees_A_medium`, `trees_B_medium`, `hexagons_medieval.png` |
```

with:

```markdown
| KayKit – Medieval Hexagon Pack 1.0 | Kay Lousberg (www.kaylousberg.com) | https://github.com/KayKit-Game-Assets/KayKit-Medieval-Hexagon-Pack-1.0 | CC0 1.0 | `medieval/building_home_A_red`, `building_home_B_red`, `building_well_red`, `building_home_A_green`, `building_home_B_green`, `building_market_green`, `building_tavern_green`, `building_well_green`, `rock_single_A`–`E`, `tree_single_A`, `tree_single_B`, `trees_A_medium`, `trees_B_medium`, `wall_straight`, `tent`, `hexagons_medieval.png` |
```

3. Replace:

```markdown
KayKit – Skeletons Character Pack 1.0 (same author, CC0,
https://github.com/KayKit-Game-Assets/KayKit-Character-Pack-Skeletons-1.0) is downloaded
in `assets_src/` for the enemies of later phases; it gets a row here when one of its
models is copied in.

The slimes, the Rey Slime's crown, the bat, the mushroom, the wolf, the goblin, the carnivorous plant and the bushes are built in code (`BattleActor`, `LowPoly`); the Bruja del bosque is the Mage tinted purple.
```

with:

```markdown
The slimes, the Rey Slime's crown, the bat, the mushroom, the wolf, the goblin, the carnivorous plant and the bushes are built in code (`BattleActor`, `LowPoly`); the Bruja del bosque is the Mage tinted purple.
```

4. Replace:

```markdown
The slimes, the Rey Slime's crown, the bat, the mushroom, the wolf, the goblin, the carnivorous plant and the bushes are built in code (`BattleActor`, `LowPoly`); the Bruja del bosque is the Mage tinted purple.
```

with:

```markdown
The slimes, the Rey Slime's crown, the bat, the mushroom, the wolf, the goblin, the carnivorous plant and the bushes are built in code (`BattleActor`, `LowPoly`); the Bruja del bosque is the Mage tinted purple; the Señor de la Niebla is the Skeleton_Mage scaled and tinted, with an aura built in code.
```


If the full run of Task 3 Step 4 gave a different time, keep "1:30-1:56 in the runs of the castle plan" and add yours after it.

- [ ] **Step 2: Check every changed script once more**

```powershell
foreach ($s in "battle/combatant","battle/battle_event","battle/battle_engine","battle/battle_actor","battle/battle_scene","battle/battle_stage","battle/enemy_library","world/zone_data","world/dungeon_map","world/world_stage","audio/music_library","game/inventory","game/chests","game/shop","game/inn","game/game_state","game/game") { .\tools\godot.cmd --headless --path . --check-only --script "res://scripts/$s.gd" }
.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 3000 -- --autoplay
Remove-Item "$env:APPDATA\Godot\app_userdata\rpg-turnos\save_autoplay.json" -ErrorAction SilentlyContinue
```

Expected: no `ERROR`, at most the Jolt warning.

- [ ] **Step 3: Web export**

```powershell
.\tools\godot.cmd --headless --path . --export-release "Web" build/web/index.html
Get-ChildItem build\web | Select-Object Name, Length
```

Expected: no `ERROR`. When this plan was run, `index.pck` was 9.2 MB (9 226 816 bytes; the three skeleton .glb add about 14 MB on disk but import to compressed scenes) and `index.wasm` 39.5 MB. Serve `build/web` with any static server, open it in a browser, play from the title to the first battle and note the FPS of the meadow (the castle can't be reached quickly by hand; it is the same renderer path as the mine). `build/` is git-ignored.

- [ ] **Step 4: Commit**

```powershell
git add CLAUDE.md assets/CREDITS.md
git status --short
git commit -m "Document the castle phase"
```

`git status --short` must show nothing untracked.

---

## Next plan

- **Phase 6 — Historia** (`docs/boost/specs/2026-11-03-historia-design.md`): the introduction, the scenes around each boss and each fragment, and the real ending once `GameState.is_finished()` (credits, back to the title, the Soldado and the villagers' lines after the flag `senor_niebla`). Worth revisiting there: the full autoplay's play time (1:30-1:56 here) against the 2 h target once the story's minutes exist, and whether the Señor de la Niebla's fight (11 rounds) should be shorter.
