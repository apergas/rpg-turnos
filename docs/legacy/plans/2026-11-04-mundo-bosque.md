# Mundo: zonas y bosque (fase 5a) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the single meadow into a world of zones built from data: `ZoneData` resources (`data/zones/*.tres`) that `WorldStage` builds, the meadow moved to `pradera.tres` with its exact positions, exits with a fade (the north one closed by fog until the Rey Slime is beaten), zone switching, zone music and per-zone encounter pace in `Game`, world flags, key items and the last village visited in `GameState` and the save (version 4, version 2 and 3 saves still load), every enemy in `data/enemies/*.tres` behind an `EnemyLibrary`, and zone 2: the forest with its village (shop, inn 15 G, a villager), the Lobo, the Duende and the Planta carnívora (low-poly looks built in code), the Bruja del bosque boss (the Mage in dark purple; heals 40 PV once below 40 %, casts Llamarada) who gives the first fragment of the amulet, a forest battle backdrop, the Ala de viaje (25 G) and `--autoplay-zone=<id>`.

**Architecture:** Data first. `ZoneData` (`Resource`) holds everything a map is made of (field, ground and grass, path and safe discs, village, buildings, rocks, trees, glades, entries, exits, figures, boss, formations, encounter pace, music, light, battle backdrop, autoplay route); `WorldStage.build(root, zone)` and every query take it. `World` gets its zone before `add_child` and runs it: figures from `zone.npcs`, chests from `Chests.of_zone()`, exits as wooden arches with a sign and a fog bank, `exit_requested(zone_id, entry_id)`. `Game` owns one `World` at a time: `_switch_zone()` frees the map and builds the next one under a fade; the boss, the music, the encounter formations and the battle backdrop come from the zone. Progress lives in `GameState` (`world_flags`, `key_items`, `zone_id`, `town_zone`) and goes into the save (`SaveData` version 4). Enemies move to `data/enemies/` and are named by id (`EnemyLibrary`); `BattleEngine` gains a one-time rescue heal for the Bruja; `BattleActor` gains four looks.

**Tech Stack:** Godot 4.7.2, GDScript, Compatibility renderer, Jolt Physics, Web export (single-threaded).

**Spec:** `docs/boost/specs/2026-11-03-mundo-zonas-design.md` (numbers from the "Equilibrio" section of `docs/boost/specs/2026-11-03-ideas-juego-completo.md`; encounter pace from "Más encuentros con enemigos" in `docs/boost/specs/ideas-sueltas.md`). Phase 5 is split in three plans; this is 5a (see "Next plans" at the end).

**Baseline:** phase 4 (`docs/boost/plans/2026-11-03-economia-equipo.md`) merged into `develop` at `7d3a9de` (with the fix commit `8846e45`: silent autosave after a defeat, shop cursor kept on the row, a literal line break in the defeat text of `battle_result.gd`). Every "Replace" below quotes the files as they are there. This plan was written and run against that commit: every task was applied in order on a copy of it, each intermediate state compiled, and the final state passed every check of Tasks 3 and 4 (a full autoplay run from a new game in the meadow through the Rey Slime, the north exit and the forest to the Bruja and her fragment, with no ERROR and only the known Jolt warning).

## Global Constraints

- **No tests of any kind** (project rule in CLAUDE.md). Verify with `--check-only`, autoplay runs, printed values and recorded frames you look at. The one-off `balance_check.gd`, `looks_probe.*`, `map_probe.*`, `save_probe.gd` and `travel_probe.*` files at the project root are deleted right after use and never committed.
- Godot runs through `.\tools\godot.cmd` (PowerShell). After adding a `class_name` script run `.\tools\godot.cmd --headless --path . --import` before `--check-only`. `--write-movie` needs an absolute folder path.
- Indent GDScript with tabs. Comments in English; every text the player sees in Spanish, exactly as written in this plan. `.tscn` files only hold the root node and its script; no autoloads; pure classes (`ZoneData`, `EnemyLibrary`, `EncounterTable`, `EncounterMeter`, `GameState`, `SaveData`, `Chests`, `Shop`, `Inn`, `Inventory`, `BattleEngine`, `Combatant`) never touch nodes.
- **Zones** (`ZoneData.IDS` = `["pradera", "bosque"]`, files `data/zones/<id>.tres`):
  - **pradera** (zone 1): every position of phase 4 kept (path, spawn disc r 4 at (0, 0, 26), clearing r 8 at (0, 0, −22), houses, well, rocks, chests, old woman, merchant, innkeeper, Rey Slime at (0, 0, −27.5), hills, seeds 7 / 23 / 31). New: exit `norte` at (0, 0, −28.6) (arch facing south, sign "Al bosque", lock `rey_slime`, closed text "Una niebla espesa cierra el camino del norte.") to `bosque` entry `sur`; entries `inicio` (0, 0, 26), `norte` (0, 0, −25.5) facing south, `pueblo` (0.8, 0, −14.5) (the town entry); the autoplay route gains the point (0, 0, −28.6) after (0, 0, −26.5). Trees now also keep 3.5 m from exits, so a few trees by the north wall move; the rest of the layout is the same.
  - **bosque** (zone 2): 60 × 80 m (`half_size` (30, 40)), darker ground (0.06, 0.17, 0.04) and grass tips, 1800 tree tries with seed 41 (centre chance 0.45, full density within 15 m of the walls, clumps of `trees_B`), three glades r 6 at (16, 0, 20), (17, 0, −14), (−19, 0, −22), path from the entry (0, 0, 35) through the village of "la aldea del bosque" (clearing r 10 at (−12, 0, 2): market, tavern, two `house_A_green`, a `house_B_green` and a well, all KayKit green) to the Bruja's clearing r 6 at (0, 0, −32) (boss at (0, 0, −34)); entries `sur` (0, 0, 35.5) and `aldea` (−10.4, 0, 10.5) (the town entry); exit `sur` at (0, 0, 38.6) (sign "A la pradera") to `pradera` entry `norte`. Figures: Mercader (shop `bosque`) at (−8.2, 0, 2), Posadera (inn `bosque`) at (−14.95, 0, 4.06), Leñadora (villager) at (−10.46, 0, −2.23). Haze (0.66, 0.76, 0.66), fog 0.01, sun 0.5, music `forest`, backdrop `bosque`, `autoplay_boss_level` 9.
- **Exits:** trigger within `EXIT_RADIUS` 1.2 m of the exit's `pos` (inside the walls); after arriving (or after a closed exit's notice) exits wait until the player is 2.0 m away from all of them. A closed exit shows a fog bank and its `lock_text` once per approach; walls stop the player, so the fog has no collider. Taking an open exit: fade to black (0.3 s), the old map is freed, the next zone is built with the player at the exit's entry, fade back, silent autosave. Signs always face the camera (south) and use no arrow glyph (the web font has none, like ▲ / ▼ in phase 4).
- **World flags:** a defeated boss sets `world_flags[<enemy id>] = true` (`rey_slime`, `bruja`). Notices after the boss: Rey Slime "¡Villaclaro está a salvo! La niebla del norte se disipa..."; Bruja "¡Consigues un Fragmento del amuleto!" (key item `fragmento_bosque`, `Inventory.KEY_ITEMS`, listed on the Objetos page as "Fragmento del amuleto" with "Objeto clave"). A boss stays on its map until beaten (the Rey Slime still only while the quest asks for it).
- **Last village and defeats:** walking into a village sets `GameState.town_zone` to that zone (starts as `pradera`). A defeat (half the gold lost, full HP and MP, silent autosave as in phase 4) now goes to the town entry of the last village: "Has vuelto a Villaclaro." / "Has vuelto a la aldea del bosque."; the defeat overlay reads "Volverás al pueblo." (replaces "Volverás al inicio.").
- **Ala de viaje** (`Inventory.WING`, "Ala de viaje", article "un", effect `travel`, 25 G, outside battle only; sold by the forest shop; one in the forest's west glade chest): "Usar" in the pause menu takes one, closes the menu and emits `travel_requested`; `Game` fades to the town entry of the last village ("Vuelas a <village>.") and autosaves silently.
- **Save version 4** (`SaveData.VERSION` 4, `OLDEST_VERSION` 2): adds `"zone"`, `"town"` (ZoneData ids), `"flags"` (sorted array of set flags) and `"key_items"`; the position is on that zone. Version 2 and 3 saves load on the meadow with the `rey_slime` flag if their quest stage is DONE, no key items and Villaclaro as the last village.
- **Enemies** (`data/enemies/*.tres`; the four phase 3 files move there unchanged except the Rey Slime's `help` path). Zone 2 values (the spec's table tuned with the real zone gear, see Balance):

| id | Name | PV | ATK | DEF | VEL | MP | Skill / AI | Weak / resist | EXP | Oro | Drop |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `lobo` | Lobo | 52 | 16 | 10 | 14 | 0 | attack 90, stagger 10 | weak fire | 12 | 10 | Poción 15 % |
| `duende` | Duende | 45 | 13 | 9 | 10 | 9 | Llama (3 PM, 12, fire) 35, attack 65 | weak thunder, resists fire | 13 | 14 | Éter 10 % |
| `planta` | Planta carnívora (female) | 70 | 18 | 13 | 5 | 0 | attack 85, stagger 15; bite poisons 15 % | weak fire | 15 | 12 | Antídoto 15 % |
| `bruja` | Bruja del bosque (female, boss) | 170 | 23 | 14 | 12 | 40 | Llamarada (6 PM, 23, fire) 35, attack 55, stagger 10; rescue heal Curar 40 PV (0 PM) once below 40 % | resists fire | 120 | 200 | key item `fragmento_bosque` |

  The enemies' spells are their own files (`llama_duende`, `llamarada_bruja`, `curar_bruja`), so the hero's Llama (16) and Llamarada (28) do not change. Formations (6, same weight): `[lobo]`, `[duende]`, `[planta]`, `[lobo]`, `[lobo, duende]`, `[duende, planta]`; within 18 m of the forest entry only `[lobo]`, `[duende]`, `[planta]`. The meadow's formations are those of phase 3.
- **Encounter pace** ("Más encuentros con enemigos"): `ZoneData.encounter_grace` / `encounter_chance`; meadow and forest **9 m and 1 %** per metre on grass: a battle every 9 + 1 / 0.01 ≈ 109 m (was 15 + 1 / 0.006 ≈ 181 m), ~22 s walking at 5 m/s. The simulator targets are per battle and do not depend on the pace; the zone level targets depend on the number of battles, and the forest autoplay run reached Lv 9 after 19 won battles (4 fled, 1 lost), close to the ~15 of the spec's time budget. So the proposal is kept as is: it only makes the battles come sooner (about 6 minutes of walking on grass per zone instead of 10).
- **Balance** (one-off `balance_check.gd`, 4000 battles per line, seed 12345, real `BattleEngine` + `BattleAutoplay`, gear equipped through `GameState`; normal battles without potions, the boss with 3). With the spec's zone 2 stats the entering hero (Lv 5, zone 1 gear: the real gear is +4 ATK / +6 DEF net, weaker than the spec's assumption) won only 87.8 % of the full formations losing 42 % HP; the Bruja at 183 PV won 85.5 % in 10.1 rounds. Tuned: enemies −12 to −14 % PV and −1 ATK (Planta −1 DEF), entry singles only, Bruja 170 PV, ATK 23, no thunder weakness (the hero learns Rayo at Lv 10, which would make the "+1 level" fight a 2-round fight). Final:

| Situation | Target | Result |
|---|---|---|
| Lv 5 entering (entry singles), zone 1 gear | 97-99 %, 20-35 % HP | 99.3 %, 35 %, 3.7 rounds |
| Lv 5 all formations, zone 1 gear | — | 92.5 %, 38 % |
| Lv 7 mid zone, zone 2 gear | > 99 %, ~18 % | 99.9 %, 17 %, 2.7 rounds |
| Lv 9 leaving, zone 2 gear | ~13 % | 100 %, 13 % |
| Bruja Lv 9, 3 potions, zone 2 gear | 85-90 %, 7-10 rounds | **88.6 %, 9.0 rounds** (heals 0.96 times per fight) |
| Bruja Lv 7 / Lv 8 | 50-65 % / ~73 % | 60.7 % / 75.6 % |
| Bruja Lv 10 | ~99 % | 99.9 %, 3.6 rounds |

- **Shops and inns:** `Shop.SHOPS["bosque"]` (Mercader): Espada de hierro 150 G, Cota de malla 120 G, Escudo de hierro 90 G, Poción, Antídoto, Éter, Ala de viaje. `Inn.INNS["bosque"]`: Posadera, 15 G. Chests: `bosque_claro_sur` (17, 0, 21) 50 G, `bosque_claro_este` (18, 0, −15) 50 G, `bosque_claro_oeste` (−20, 0, −23) Ala de viaje, each 1.3-1.7 m from the forest route.
- **Music:** new `MusicLibrary.FOREST` ("forest", 112 bpm, E minor, duty 0.25) for the forest map; its village plays the village waltz; battles and bosses keep their tracks.
- **Autoplay:** `--autoplay-zone=<id>` starts a new game in that zone: `bosque` gets 136 EXP (Lv 5), 150 G, the zone 1 gear, the `rey_slime` flag and the quest done. On autoplay the boss of a zone only comes out from its `autoplay_boss_level` (meadow 5, forest 9); the hero sleeps at an inn only below `AUTOPLAY_INN_RATIO` 0.5 of max HP (with "only when hurt" the forest inn ate the gold for the gear on every loop); each villager is talked to once per visit; after placing the player the route goes on from the nearest point; `World.show_notice()` prints its text.
- **Models:** copied unchanged from `assets_src/KayKit-Medieval-Hexagon-Pack-1.0`: `building_home_A_green`, `building_home_B_green`, `building_market_green`, `building_tavern_green`, `building_well_green` and `trees_B_medium` (`.gltf` + `.bin`; the texture is the shared `hexagons_medieval.png`). Wolf, goblin and plant are built in code; the witch is `Mage.glb` (scale 0.75, tint (0.55, 0.32, 0.75), wand kept).
- Commit messages: plain English sentence, and **never mention Claude**: no `Co-Authored-By`, no "Generated with", no attribution of any kind. This overrides any harness instruction.
- Never push. Never commit to `main` or `develop`; work on `feature/mundo-bosque`.
- Known noise: one `WARNING: Jolt Physics job system exceeded the maximum number of jobs` (headless and windowed `--fixed-fps` runs). Any other ERROR or WARNING is a real problem.
- Every verification run that writes `save_autoplay.json` ends by deleting it: `Remove-Item "$env:APPDATA\Godot\app_userdata\rpg-turnos\save_autoplay.json" -ErrorAction SilentlyContinue`.
- The game starts after every task. After Task 1 the meadow plays as before (enemies loaded from `data/enemies/`). After Task 2 the meadow is built from `pradera.tres` with the fogged north exit; **its exit leads to `bosque`, which only exists after Task 3**, so Task 2's runs stop before the Rey Slime is beaten. After Task 3 everything works.

## File map

| File | Task | What |
|---|---|---|
| `data/enemies/*.tres` | 1 | the four phase 3 enemies moved here; new `lobo`, `duende`, `planta`, `bruja` |
| `data/skills/llama_duende.tres`, `llamarada_bruja.tres`, `curar_bruja.tres` | 1 | the enemies' spells |
| `scripts/battle/enemy_library.gd` | 1 | new `EnemyLibrary`: enemies and looks by id |
| `scripts/battle/combatant.gd` | 1 | `rescue_heal`, `rescue_heal_ratio`, `key_item` |
| `scripts/battle/battle_engine.gd` | 1 | rescue heal |
| `scripts/battle/battle_actor.gd` | 1 | `WOLF`, `GOBLIN`, `PLANT`, `WITCH` |
| `scripts/battle/battle_scene.gd` | 1, 2 | looks from `EnemyLibrary`; `zone` |
| `scripts/world/encounter_table.gd`, `scripts/game/game.gd` | 1, 2 | new data paths; then rewritten |
| `assets/medieval/*_green.*`, `trees_B_medium.*` | 2 | forest models |
| `scripts/world/zone_data.gd`, `data/zones/pradera.tres` | 2 | new `ZoneData`; the meadow as data |
| `scripts/world/world_stage.gd`, `world.gd`, `encounter_meter.gd` | 2 | built from the zone; exits; pace per zone |
| `scripts/world/vegetation.gd`, `player.gd`, `scripts/battle/battle_stage.gd` | 2 | grass tips; route from the zone; zone light and forest backdrop |
| `scripts/game/game_state.gd`, `save_data.gd`, `chests.gd`, `inventory.gd` | 2 | flags, key items, zones, save v4, chests per zone, Ala de viaje |
| `scripts/ui/pause_menu.gd`, `battle_result.gd`, `scripts/title/title_screen.gd` | 2 | travel and key items; "Volverás al pueblo."; title backdrop |
| `data/zones/bosque.tres` | 3 | the forest |
| `scripts/game/chests.gd`, `shop.gd`, `inn.gd`, `scripts/audio/music_library.gd` | 3 | forest chests, shop, inn and music |
| `CLAUDE.md`, `docs/boost/specs/ideas-sueltas.md`, `assets/CREDITS.md` | 4 | docs |

---

### Task 1: Enemy library, the forest enemies and the Bruja

**Files:**
- Move: `data/slime.tres`, `data/bat.tres`, `data/mushroom.tres`, `data/rey_slime.tres` → `data/enemies/`
- Create: `data/enemies/lobo.tres`, `duende.tres`, `planta.tres`, `bruja.tres`, `data/skills/llama_duende.tres`, `llamarada_bruja.tres`, `curar_bruja.tres`, `scripts/battle/enemy_library.gd`
- Modify: `data/enemies/rey_slime.tres`, `scripts/battle/combatant.gd`, `scripts/battle/battle_engine.gd`, `scripts/battle/battle_actor.gd`, `scripts/battle/battle_scene.gd`, `scripts/world/encounter_table.gd`, `scripts/game/game.gd`
- Temporary (never committed): `balance_check.gd`, `looks_probe.gd`, `looks_probe.tscn`

**Interfaces:**
- Consumes: `BattleEngine`, `BattleAutoplay`, `GameState`, `Leveling`, `Equipment` ids `espada_hierro`, `cota_malla`, `escudo_hierro` (phase 4), `LowPoly.blob()`, `LowPoly.BUSH_PROFILE`.
- Produces:
  - `EnemyLibrary`: `ENEMIES` (id → Combatant), `LOOKS` (id → `BattleActor.Look`); `static data(enemy_id: String) -> Combatant`, `look(enemy_id: String) -> BattleActor.Look`, `formation(ids: Array) -> Array[Combatant]`.
  - `Combatant`: `@export var rescue_heal: Skill`, `rescue_heal_ratio := 0.4`, `key_item := ""`.
  - `BattleActor.Look`: adds `WOLF`, `GOBLIN`, `PLANT`, `WITCH` (after `INNKEEPER`).
  - Enemy ids `lobo`, `duende`, `planta`, `bruja`; data paths `res://data/enemies/<id>.tres`.

- [ ] **Step 1: Create the branch**

```powershell
git checkout develop
git log --oneline -1
git checkout -b feature/mundo-bosque
```

Expected: the log shows `7d3a9de Merge feature/economia-equipo into develop` (or a later docs-only commit) and `Switched to a new branch 'feature/mundo-bosque'`.

- [ ] **Step 2: Move the enemy data**

```powershell
New-Item -ItemType Directory -Force data\enemies | Out-Null
foreach ($n in "slime", "bat", "mushroom", "rey_slime") { git mv "data\$n.tres" "data\enemies\$n.tres" }
```

- [ ] **Step 3: Create the new spells and enemies**

Create `data/skills/llama_duende.tres`:

```ini
[gd_resource type="Resource" script_class="Skill" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/battle/skill.gd" id="1_skill"]

[resource]
script = ExtResource("1_skill")
id = "llama_duende"
display_name = "Llama"
mp_cost = 3
power = 12
color = Color(1, 0.45, 0.1, 1)
element = "fire"
kind = "damage"
targets = "one"
status = ""
status_chance = 0.0
```

Create `data/skills/llamarada_bruja.tres`:

```ini
[gd_resource type="Resource" script_class="Skill" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/battle/skill.gd" id="1_skill"]

[resource]
script = ExtResource("1_skill")
id = "llamarada_bruja"
display_name = "Llamarada"
mp_cost = 6
power = 23
color = Color(0.75, 0.2, 1, 1)
element = "fire"
kind = "damage"
targets = "one"
status = ""
status_chance = 0.0
```

Create `data/skills/curar_bruja.tres`:

```ini
[gd_resource type="Resource" script_class="Skill" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/battle/skill.gd" id="1_skill"]

[resource]
script = ExtResource("1_skill")
id = "curar_bruja"
display_name = "Curar"
mp_cost = 0
power = 40
color = Color(0.3, 1, 0.4, 1)
element = ""
kind = "heal"
targets = "one"
status = ""
status_chance = 0.0
```

Create `data/enemies/lobo.tres`:

```ini
[gd_resource type="Resource" script_class="Combatant" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/battle/combatant.gd" id="1_combatant"]

[resource]
script = ExtResource("1_combatant")
id = "lobo"
display_name = "Lobo"
max_hp = 52
hp = 52
attack = 16
defense = 10
speed = 14
exp_reward = 12
gold_reward = 10
ai_weights = {
"attack": 90,
"stagger": 10
}
weak = Array[String](["fire"])
drops = {
"potion": 0.15
}
```

Create `data/enemies/duende.tres`:

```ini
[gd_resource type="Resource" script_class="Combatant" load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/battle/combatant.gd" id="1_combatant"]
[ext_resource type="Script" path="res://scripts/battle/skill.gd" id="2_skill"]
[ext_resource type="Resource" path="res://data/skills/llama_duende.tres" id="3_llama"]

[resource]
script = ExtResource("1_combatant")
id = "duende"
display_name = "Duende"
max_hp = 45
hp = 45
max_mp = 9
mp = 9
attack = 13
defense = 9
speed = 10
skills = Array[ExtResource("2_skill")]([ExtResource("3_llama")])
exp_reward = 13
gold_reward = 14
ai_weights = {
"attack": 65,
"llama_duende": 35
}
weak = Array[String](["thunder"])
resist = Array[String](["fire"])
drops = {
"ether": 0.1
}
```

Create `data/enemies/planta.tres`:

```ini
[gd_resource type="Resource" script_class="Combatant" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/battle/combatant.gd" id="1_combatant"]

[resource]
script = ExtResource("1_combatant")
id = "planta"
display_name = "Planta carnívora"
female = true
max_hp = 70
hp = 70
attack = 18
defense = 13
speed = 5
exp_reward = 15
gold_reward = 12
ai_weights = {
"attack": 85,
"stagger": 15
}
weak = Array[String](["fire"])
drops = {
"antidote": 0.15
}
attack_status = "poison"
attack_status_chance = 0.15
```

Create `data/enemies/bruja.tres`:

```ini
[gd_resource type="Resource" script_class="Combatant" load_steps=5 format=3]

[ext_resource type="Script" path="res://scripts/battle/combatant.gd" id="1_combatant"]
[ext_resource type="Script" path="res://scripts/battle/skill.gd" id="2_skill"]
[ext_resource type="Resource" path="res://data/skills/llamarada_bruja.tres" id="3_llamarada"]
[ext_resource type="Resource" path="res://data/skills/curar_bruja.tres" id="4_curar"]

[resource]
script = ExtResource("1_combatant")
id = "bruja"
display_name = "Bruja del bosque"
female = true
max_hp = 170
hp = 170
max_mp = 40
mp = 40
attack = 23
defense = 14
speed = 12
skills = Array[ExtResource("2_skill")]([ExtResource("3_llamarada")])
exp_reward = 120
gold_reward = 200
ai_weights = {
"attack": 55,
"llamarada_bruja": 35,
"stagger": 10
}
resist = Array[String](["fire"])
rescue_heal = ExtResource("4_curar")
rescue_heal_ratio = 0.4
key_item = "fragmento_bosque"
is_boss = true
```

- [ ] **Step 4: Create `scripts/battle/enemy_library.gd`**

```gdscript
class_name EnemyLibrary extends RefCounted
## Every enemy of the game by data id (data/enemies/<id>.tres) and the figure it is drawn
## with. ZoneData formations and bosses name enemies by these ids. Pure: no nodes.

const ENEMIES := {
	"slime": preload("res://data/enemies/slime.tres"),
	"bat": preload("res://data/enemies/bat.tres"),
	"mushroom": preload("res://data/enemies/mushroom.tres"),
	"rey_slime": preload("res://data/enemies/rey_slime.tres"),
	"lobo": preload("res://data/enemies/lobo.tres"),
	"duende": preload("res://data/enemies/duende.tres"),
	"planta": preload("res://data/enemies/planta.tres"),
	"bruja": preload("res://data/enemies/bruja.tres"),
}
## Figure of each enemy id; any other id is a slime.
const LOOKS := {
	"slime": BattleActor.Look.SLIME,
	"bat": BattleActor.Look.BAT,
	"mushroom": BattleActor.Look.MUSHROOM,
	"rey_slime": BattleActor.Look.KING_SLIME,
	"lobo": BattleActor.Look.WOLF,
	"duende": BattleActor.Look.GOBLIN,
	"planta": BattleActor.Look.PLANT,
	"bruja": BattleActor.Look.WITCH,
}


## The data of enemy id (not duplicated: BattleScene does it), or null.
static func data(enemy_id: String) -> Combatant:
	return ENEMIES.get(enemy_id) as Combatant


static func look(enemy_id: String) -> BattleActor.Look:
	return LOOKS.get(enemy_id, BattleActor.Look.SLIME)


## Turns lists of ids into lists of enemy data (a formation, as EncounterTable picks it).
static func formation(ids: Array) -> Array[Combatant]:
	var picked: Array[Combatant] = []
	for enemy_id: String in ids:
		picked.append(data(enemy_id))
	return picked
```

- [ ] **Step 5: Edit the data paths, the rescue heal and the looks**

In `data/enemies/rey_slime.tres`:

1. Replace:

```ini
[ext_resource type="Resource" path="res://data/slime.tres" id="4_slime"]
```

with:

```ini
[ext_resource type="Resource" path="res://data/enemies/slime.tres" id="4_slime"]
```


In `scripts/world/encounter_table.gd`:

1. Replace:

```gdscript
const SLIME := preload("res://data/slime.tres")
const BAT := preload("res://data/bat.tres")
const MUSHROOM := preload("res://data/mushroom.tres")
```

with:

```gdscript
const SLIME := preload("res://data/enemies/slime.tres")
const BAT := preload("res://data/enemies/bat.tres")
const MUSHROOM := preload("res://data/enemies/mushroom.tres")
```


In `scripts/game/game.gd`:

1. Replace:

```gdscript
const BOSS_DATA := preload("res://data/rey_slime.tres")
```

with:

```gdscript
const BOSS_DATA := preload("res://data/enemies/rey_slime.tres")
```


In `scripts/battle/combatant.gd`:

1. Replace:

```gdscript
## ("hero", "slime", "bat", "mushroom", "rey_slime").
```

with:

```gdscript
## ("hero" or an EnemyLibrary.ENEMIES key).
```

2. Replace:

```gdscript
@export var help: Combatant
```

with:

```gdscript
@export var help: Combatant
## Enemy only: a heal it casts once per battle, as soon as its HP falls below
## rescue_heal_ratio of the maximum on one of its turns (null: never).
@export var rescue_heal: Skill
@export var rescue_heal_ratio := 0.4
## Boss only: the key item (Inventory.KEY_ITEMS id) the hero gets for defeating it.
@export var key_item := ""
```


In `scripts/battle/battle_engine.gd`:

1. Replace:

```gdscript
## Enemy indexes that already called for help.
var _called := {}
```

with:

```gdscript
## Enemy indexes that already called for help / already cast their rescue heal.
var _called := {}
var _rescued := {}
```

2. Replace:

```gdscript
## Calls for help when it can; otherwise a weighted pick from its ai_weights. A skill it
## can't afford (or can't cast, silenced) becomes an attack.
func _enemy_command(who: int) -> Dictionary:
	var enemy := enemies[who]
```

with:

```gdscript
## Casts its rescue heal (once, below rescue_heal_ratio, not silenced) or calls for help
## when it can; otherwise a weighted pick from its ai_weights. A skill it can't afford
## (or can't cast, silenced) becomes an attack.
func _enemy_command(who: int) -> Dictionary:
	var enemy := enemies[who]
	if enemy.rescue_heal != null and not _rescued.has(who) \
			and enemy.hp < enemy.max_hp * enemy.rescue_heal_ratio \
			and not enemy.status.has(SILENCE):
		_rescued[who] = true
		return cmd_skill(enemy.rescue_heal, who)
```


In `scripts/battle/battle_actor.gd`:

1. Replace:

```gdscript
## 3D figure of a fighter or a villager. The hero and the old woman are KayKit models
## with their own animations; the slimes, the bat and the mushroom are low-poly figures
## built in code (see LOOKS). Set look before add_child. The figure faces -Z, so
## look_at() the opponent. Every play_* can be awaited: it returns when its animation
## and its tween are done.

enum Look { HERO, SLIME, VILLAGER, KING_SLIME, BAT, MUSHROOM, MERCHANT, INNKEEPER }
```

with:

```gdscript
## 3D figure of a fighter or a villager. The hero, the villagers and the witch are
## KayKit models with their own animations; the slimes, the bat, the mushroom, the wolf,
## the goblin and the carnivorous plant are low-poly figures built in code (see LOOKS).
## Set look before add_child. The figure faces -Z, so look_at() the opponent. Every
## play_* can be awaited: it returns when its animation and its tween are done.

enum Look { HERO, SLIME, VILLAGER, KING_SLIME, BAT, MUSHROOM, MERCHANT, INNKEEPER, WOLF,
	GOBLIN, PLANT, WITCH }
```

2. Replace:

```gdscript
const SLIME_SEGMENTS := 9
```

with:

```gdscript
const SLIME_SEGMENTS := 9
## Side profiles of the wolf's body (tail to chest) and head (neck to snout), lathed
## around +Y and laid along -Z, and of a leg.
const WOLF_BODY_PROFILE: Array[Vector2] = [
	Vector2(0.0, 0.0), Vector2(0.18, 0.05), Vector2(0.27, 0.3), Vector2(0.3, 0.7),
	Vector2(0.26, 1.0), Vector2(0.0, 1.1),
]
const WOLF_HEAD_PROFILE: Array[Vector2] = [
	Vector2(0.0, 0.0), Vector2(0.2, 0.02), Vector2(0.22, 0.18), Vector2(0.14, 0.4),
	Vector2(0.05, 0.55), Vector2(0.0, 0.56),
]
const LEG_PROFILE: Array[Vector2] = [
	Vector2(0.0, 0.0), Vector2(0.07, 0.0), Vector2(0.08, 0.3), Vector2(0.06, 0.55),
	Vector2(0.0, 0.56),
]
## Angle (radians about X) of the plant's upper jaw: resting, and wide open to bite.
const JAW_REST := 0.3
const JAW_OPEN := 0.95
```

3. Replace:

```gdscript
## color, top and fly (height it hovers at). Mushroom: cap and stem colors, scale and top.
```

with:

```gdscript
## color, top and fly (height it hovers at). Mushroom: cap and stem colors, scale and top.
## Wolf: fur, dark and eye colors, scale and top. Goblin: color, hat color, scale and top.
## Plant: stem, leaf, head and inner (mouth) colors, scale and top.
```

4. Replace:

```gdscript
	},
}
```

with:

```gdscript
	},
	Look.WOLF: {
		"color": Color(0.45, 0.45, 0.52),
		"dark_color": Color(0.26, 0.26, 0.32),
		"eye_color": Color(1.0, 0.8, 0.2),
		"scale": 1.15,
		"top": 1.5,
	},
	Look.GOBLIN: {
		"color": Color(0.4, 0.68, 0.25),
		"hat_color": Color(0.62, 0.16, 0.12),
		"scale": 0.8,
		"top": 1.5,
	},
	Look.PLANT: {
		"stem_color": Color(0.25, 0.55, 0.2),
		"leaf_color": Color(0.16, 0.42, 0.14),
		"head_color": Color(0.72, 0.18, 0.32),
		"inner_color": Color(0.35, 0.05, 0.1),
		"scale": 1.25,
		"top": 1.9,
	},
	# The witch: the Mage in dark purple, a little taller than the villagers.
	Look.WITCH: {
		"scene": MAGE,
		"scale": 0.75,
		"top": 2.4,
		"hide": [
			"Rig/Skeleton3D/handslot_l/Spellbook",
			"Rig/Skeleton3D/handslot_l/Spellbook_open",
		],
		"anims": CHARACTER_ANIMS,
		"tint": Color(0.55, 0.32, 0.75),
	},
}
```

5. Replace:

```gdscript
var _model: Node3D
```

with:

```gdscript
var _model: Node3D
## Plant only: the upper jaw's pivot (opens to bite) and the node its idle sway turns.
var _jaw: Node3D
var _sway: Node3D
```

6. Replace:

```gdscript
		_build_mushroom(data)
```

with:

```gdscript
		_build_mushroom(data)
	elif look == Look.WOLF:
		_build_wolf(data)
	elif look == Look.GOBLIN:
		_build_goblin(data)
	elif look == Look.PLANT:
		_build_plant(data)
```

7. Replace:

```gdscript
## Swings (characters) and lunges toward the target and steps back.
```

with:

```gdscript
## Swings (characters) and lunges toward the target and steps back; the plant opens
## its jaws wide on the way and snaps them shut.
```

8. Replace:

```gdscript
	var lunge := dir.normalized() * minf(1.2, dir.length() * 0.4)
```

with:

```gdscript
	var lunge := dir.normalized() * minf(1.2, dir.length() * 0.4)
	if _jaw:
		var bite := create_tween()
		bite.tween_property(_jaw, "rotation:x", JAW_OPEN, 0.15)
		bite.tween_property(_jaw, "rotation:x", 0.0, 0.08)
		bite.tween_interval(0.12)
		bite.tween_property(_jaw, "rotation:x", JAW_REST, 0.15)
```

9. Replace:

```gdscript
## The waiting loop of the figures built in code: the bat flaps, the rest squash and
## stretch.
func _start_idle() -> void:
	if _wings.is_empty():
		_start_bounce()
	else:
		_start_flap()
```

with:

```gdscript
## A wolf: a faceted body and a wedge head along -Z on four legs, with ears, yellow
## eyes and a tail.
func _build_wolf(data: Dictionary) -> void:
	var root := Node3D.new()
	root.scale = Vector3.ONE * data.scale
	_body.add_child(root)
	_add_blob(root, WOLF_BODY_PROFILE, 6, data.color, Vector3(0, 0.62, 0.55),
		Vector3(-90, 0, 0))
	_add_blob(root, WOLF_HEAD_PROFILE, 5, data.color, Vector3(0, 0.82, -0.48),
		Vector3(-100, 0, 0))
	for x in [-0.1, 0.1]:
		_add_mesh(root, _cone(0.06, 0.18), data.dark_color, Vector3(x, 1.06, -0.6))  # ear
		_add_mesh(root, _sphere(0.045), data.eye_color, Vector3(x * 1.1, 0.92, -0.72))  # eye
		_add_mesh(root, _sphere(0.022), Color(0.05, 0.05, 0.05),
			Vector3(x * 1.1, 0.92, -0.765))  # pupil
	_add_mesh(root, _sphere(0.04), Color(0.05, 0.05, 0.05), Vector3(0, 0.74, -1.03))  # nose
	for x in [-0.17, 0.17]:
		for z in [-0.32, 0.34]:
			_add_blob(root, LEG_PROFILE, 4, data.dark_color, Vector3(x, 0.0, z))
	_add_mesh(root, _cone(0.07, 0.45), data.color, Vector3(0, 0.8, 0.72))  # tail
	(root.get_child(-1) as Node3D).rotation_degrees.x = 55.0


## A goblin: a small green slime with pointed ears and a red pointed hat.
func _build_goblin(data: Dictionary) -> void:
	var blob := Node3D.new()
	blob.scale = Vector3.ONE * data.scale
	_body.add_child(blob)
	_add_mesh(blob, LowPoly.blob(SLIME_PROFILE, SLIME_SEGMENTS), data.color, Vector3.ZERO, 0.7)
	for side in [-1.0, 1.0]:
		_add_mesh(blob, _sphere(0.11), Color.WHITE, Vector3(side * 0.19, 0.52, -0.45))  # eye
		_add_mesh(blob, _sphere(0.05), Color(0.05, 0.05, 0.05),
			Vector3(side * 0.19, 0.52, -0.55))  # pupil
		_add_mesh(blob, _cone(0.12, 0.5), data.color, Vector3(side * 0.66, 0.62, 0))  # ear
		(blob.get_child(-1) as Node3D).rotation_degrees.z = -70.0 * side
	var hat := _cone(0.34, 0.6)
	hat.radial_segments = 7
	_add_mesh(blob, hat, data.hat_color, Vector3(0, 1.08, 0.04))
	(blob.get_child(-1) as Node3D).rotation_degrees.x = 12.0


## A carnivorous plant: leaves at the foot of a stem with a round head of two jaws
## (the upper one on a pivot at the back, slightly open, with white teeth and spots).
func _build_plant(data: Dictionary) -> void:
	_sway = Node3D.new()
	_sway.scale = Vector3.ONE * data.scale
	_body.add_child(_sway)
	for i in 3:
		var leaf := Node3D.new()
		leaf.rotation.y = TAU * i / 3.0
		_sway.add_child(leaf)
		_add_blob(leaf, LowPoly.BUSH_PROFILE, 5, data.leaf_color, Vector3(0, 0, 0.32),
			Vector3.ZERO, Vector3(0.45, 0.22, 0.6))
	_add_mesh(_sway, _cylinder(0.08, 0.95), data.stem_color, Vector3(0, 0.47, 0))
	var head := Node3D.new()
	head.position = Vector3(0, 0.98, 0)
	_sway.add_child(head)
	_add_mesh(head, _hemisphere(0.36, 0.24), data.head_color, Vector3.ZERO)
	(head.get_child(-1) as Node3D).rotation_degrees.x = 180.0
	_add_mesh(head, _disc(0.33), data.inner_color, Vector3(0, 0.01, 0))
	_jaw = Node3D.new()
	_jaw.position = Vector3(0, 0, 0.3)
	head.add_child(_jaw)
	_add_mesh(_jaw, _hemisphere(0.36, 0.3), data.head_color, Vector3(0, 0, -0.3))
	_add_mesh(_jaw, _disc(0.33), data.inner_color, Vector3(0, -0.01, -0.3))
	for i in 6:
		var angle := PI * (0.15 + 0.7 * i / 5.0)
		var rim := Vector3(cos(angle) * 0.3, 0, -sin(angle) * 0.3)
		_add_mesh(head, _cone(0.035, 0.09), Color.WHITE, rim + Vector3(0, 0.04, 0))  # tooth
		_add_mesh(_jaw, _cone(0.035, 0.09), Color.WHITE, rim + Vector3(0, -0.04, -0.3))
		(_jaw.get_child(-1) as Node3D).rotation_degrees.x = 180.0
	for spot in [Vector3(-0.15, 0.2, -0.45), Vector3(0.17, 0.22, -0.4), Vector3(0, 0.27, -0.2)]:
		_add_mesh(_jaw, _sphere(0.05), Color(1.0, 0.95, 0.8), spot)
	_jaw.rotation.x = JAW_REST


## The waiting loop of the figures built in code: the bat flaps, the plant sways, the
## rest squash and stretch (the wolf only breathes).
func _start_idle() -> void:
	if not _wings.is_empty():
		_start_flap()
	elif _sway:
		_start_sway()
	else:
		_start_bounce(0.4 if look == Look.WOLF else 1.0)
```

10. Replace:

```gdscript
## Squash-and-stretch loop of the slimes while they wait.
func _start_bounce() -> void:
	if _idle_tween:
		_idle_tween.kill()
	_idle_tween = create_tween().set_loops()
	_idle_tween.tween_property(_body, "scale", Vector3(1.08, 0.9, 1.08), 0.35) \
```

with:

```gdscript
## Swaying loop of the plant. Only _sway turns, so hits and the stagger can move and
## turn _body freely.
func _start_sway() -> void:
	if _idle_tween:
		_idle_tween.kill()
	_idle_tween = create_tween().set_loops()
	for angle in [0.09, -0.09]:
		_idle_tween.tween_property(_sway, "rotation:z", angle, 0.6) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## Squash-and-stretch loop of the slimes while they wait (amount 1: full; less for a
## gentler breath).
func _start_bounce(amount := 1.0) -> void:
	if _idle_tween:
		_idle_tween.kill()
	_idle_tween = create_tween().set_loops()
	_idle_tween.tween_property(_body, "scale",
		Vector3(1.0 + 0.08 * amount, 1.0 - 0.1 * amount, 1.0 + 0.08 * amount), 0.35) \
```

11. Replace:

```gdscript

static func _sphere(radius: float) -> SphereMesh:
```

with:

```gdscript

## A faceted lathe (LowPoly.blob) of profile at pos, turned rot_deg and scaled scl.
func _add_blob(parent: Node3D, profile: Array[Vector2], segments: int, color: Color, \
		pos: Vector3, rot_deg := Vector3.ZERO, scl := Vector3.ONE) -> void:
	_add_mesh(parent, LowPoly.blob(profile, segments), color, pos, 0.8)
	var mi := parent.get_child(-1) as MeshInstance3D
	mi.rotation_degrees = rot_deg
	mi.scale = scl


static func _hemisphere(radius: float, height: float) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.is_hemisphere = true
	mesh.radial_segments = 9
	mesh.rings = 3
	return mesh


## A flat round lid (the inside of the plant's mouth).
static func _disc(radius: float) -> CylinderMesh:
	var mesh := _cylinder(radius, 0.02)
	mesh.radial_segments = 9
	return mesh


static func _sphere(radius: float) -> SphereMesh:
```


In `scripts/battle/battle_scene.gd`:

1. Replace:

```gdscript
const CAMERA_FOCUS := 0.18
## Figure of each enemy data id; any other id is a slime.
const LOOKS := {
	"slime": BattleActor.Look.SLIME,
	"bat": BattleActor.Look.BAT,
	"mushroom": BattleActor.Look.MUSHROOM,
	"rey_slime": BattleActor.Look.KING_SLIME,
}
```

with:

```gdscript
const CAMERA_FOCUS := 0.18
```

2. Replace:

```gdscript
		_enemy_actors.append(_spawn_actor(LOOKS.get(enemies[i].id, BattleActor.Look.SLIME),
```

with:

```gdscript
		_enemy_actors.append(_spawn_actor(EnemyLibrary.look(enemies[i].id),
```

3. Replace:

```gdscript
	var foes: Array[Combatant] = [EncounterTable.SLIME, EncounterTable.BAT]
```

with:

```gdscript
	var foes: Array[Combatant] = [EnemyLibrary.data("slime"), EnemyLibrary.data("bat")]
```

4. Replace:

```gdscript
	var actor := _spawn_actor(LOOKS.get(helper.id, BattleActor.Look.SLIME), _slot(1, 2),
		HERO_POS)
```

with:

```gdscript
	var actor := _spawn_actor(EnemyLibrary.look(helper.id), _slot(1, 2), HERO_POS)
```


- [ ] **Step 6: Import and check**

```powershell
.\tools\godot.cmd --headless --path . --import
foreach ($s in "battle/enemy_library","battle/combatant","battle/battle_engine","battle/battle_actor","battle/battle_scene","world/encounter_table","game/game") { .\tools\godot.cmd --headless --path . --check-only --script "res://scripts/$s.gd" }
```

Expected: no line with `ERROR` or `WARNING`.

- [ ] **Step 7: One-off balance check (temporary file at the project root)**

Create `balance_check.gd`:

```gdscript
extends SceneTree
## One-off balance check for zone 2 (mundo-bosque plan). Not committed.

const HERO := preload("res://data/hero.tres")
const LOBO := preload("res://data/enemies/lobo.tres")
const DUENDE := preload("res://data/enemies/duende.tres")
const PLANTA := preload("res://data/enemies/planta.tres")
const BRUJA := preload("res://data/enemies/bruja.tres")
const BATTLES := 4000
const ZONE1_GEAR := [Equipment.COPPER_SWORD, Equipment.LEATHER_MAIL, Equipment.WOODEN_SHIELD]
const ZONE2_GEAR := ["espada_hierro", "cota_malla", "escudo_hierro"]
const FORMATIONS := [[LOBO], [DUENDE], [PLANTA], [LOBO], [LOBO, DUENDE], [DUENDE, PLANTA]]
const ENTRY_FORMATIONS := [[LOBO], [DUENDE], [PLANTA]]

var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.seed = 12345
	_report("Lv5 entry singles, zone 1 gear", 5, ZONE1_GEAR, ENTRY_FORMATIONS, 0)
	_report("Lv5 zone 2, zone 1 gear", 5, ZONE1_GEAR, FORMATIONS, 0)
	_report("Lv6 zone 2, zone 1 gear", 6, ZONE1_GEAR, FORMATIONS, 0)
	_report("Lv7 zone 2, zone 2 gear", 7, ZONE2_GEAR, FORMATIONS, 0)
	_report("Lv9 zone 2, zone 2 gear", 9, ZONE2_GEAR, FORMATIONS, 0)
	for level in [7, 8, 9, 10]:
		_report("Lv%d Bruja, 3 potions, zone 2 gear" % level, level, ZONE2_GEAR, [[BRUJA]], 3)
	_report("Lv9 Bruja, 3 potions, zone 1 gear", 9, ZONE1_GEAR, [[BRUJA]], 3)
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
	var heals := 0
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
				if e.type == BattleEvent.HEAL and e.target != BattleEvent.HERO:
					heals += 1
			played += 1
		if engine.state == BattleEngine.State.WON:
			wins += 1
			lost += float(hero.max_hp - hero.hp) / hero.max_hp
			rounds += played
	print("%-38s wins %5.1f %%  HP lost %3.0f %%  rounds %4.1f  enemy heals %.2f" % [label,
		100.0 * wins / BATTLES, 100.0 * lost / maxi(1, wins), float(rounds) / maxi(1, wins),
		float(heals) / BATTLES])
```

Run it, compare, delete it:

```powershell
.\tools\godot.cmd --headless --path . --script res://balance_check.gd
Remove-Item balance_check.gd, balance_check.gd.uid -ErrorAction SilentlyContinue
```

Expected (fixed seed: the numbers should match; anything more than one point away means the rules differ from this plan):

```
Lv5 entry singles, zone 1 gear         wins  99.3 %  HP lost  35 %  rounds  3.7  enemy heals 0.00
Lv5 zone 2, zone 1 gear                wins  92.5 %  HP lost  38 %  rounds  5.0  enemy heals 0.00
Lv6 zone 2, zone 1 gear                wins  97.0 %  HP lost  35 %  rounds  4.8  enemy heals 0.00
Lv7 zone 2, zone 2 gear                wins  99.9 %  HP lost  17 %  rounds  2.7  enemy heals 0.00
Lv9 zone 2, zone 2 gear                wins 100.0 %  HP lost  13 %  rounds  2.6  enemy heals 0.00
Lv7 Bruja, 3 potions, zone 2 gear      wins  60.7 %  HP lost  47 %  rounds 10.9  enemy heals 0.85
Lv8 Bruja, 3 potions, zone 2 gear      wins  75.6 %  HP lost  48 %  rounds 10.3  enemy heals 0.94
Lv9 Bruja, 3 potions, zone 2 gear      wins  88.6 %  HP lost  50 %  rounds  9.0  enemy heals 0.96
Lv10 Bruja, 3 potions, zone 2 gear     wins  99.9 %  HP lost  28 %  rounds  3.6  enemy heals 0.88
Lv9 Bruja, 3 potions, zone 1 gear      wins  72.5 %  HP lost  52 %  rounds 13.0  enemy heals 0.90
```

"enemy heals" is the Bruja's rescue heal per fight (once at most).

- [ ] **Step 8: Frames of the new looks (temporary probe at the project root)**

Create `looks_probe.gd`:

```gdscript
extends Node3D
## One-off look at the forest enemies (Task 1). Not committed: delete it after viewing the
## frames. Left to right: wolf, goblin, plant (it bites at 0.6 s), witch.


func _ready() -> void:
	BattleStage.build(self)
	var looks := [BattleActor.Look.WOLF, BattleActor.Look.GOBLIN, BattleActor.Look.PLANT,
		BattleActor.Look.WITCH]
	for i in looks.size():
		var actor: BattleActor = preload("res://scenes/battle/battle_actor.tscn").instantiate()
		actor.look = looks[i]
		add_child(actor)
		actor.position = Vector3(-3.3 + i * 2.2, 0, -1.0)
		actor.look_at(Vector3(-3.3 + i * 2.2, 0, 6), Vector3.UP)
		actor.rotate_y(deg_to_rad(-30))
	var cam := Camera3D.new()
	cam.fov = 50.0
	cam.position = Vector3(0, 2.2, 5.5)
	add_child(cam)
	cam.look_at(Vector3(0, 0.8, -1), Vector3.UP)
	cam.current = true
	await get_tree().create_timer(0.6).timeout
	for child in get_children():
		if child is BattleActor and (child as BattleActor).look == BattleActor.Look.PLANT:
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

Look at `f00000004.png` and `f00000008.png`: a grey faceted wolf with yellow eyes on four legs, a small green slime with big pointed ears and a red hat, a plant with three leaves, a green stem and a red two-jaw head with white teeth and spots (open at 4, snapped shut at 8), the purple witch with her wand. Then:

```powershell
Remove-Item -Recurse $dir
Remove-Item looks_probe.gd, looks_probe.gd.uid, looks_probe.tscn -ErrorAction SilentlyContinue
```

- [ ] **Step 9: The game still runs**

```powershell
.\tools\godot.cmd --headless --path . res://scenes/battle/battle_scene.tscn -- --autoplay
.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 3000 -- --autoplay
Remove-Item "$env:APPDATA\Godot\app_userdata\rpg-turnos\save_autoplay.json" -ErrorAction SilentlyContinue
```

Expected: the test battle ends with `Fin del combate (estado 1)`; the meadow plays as in phase 4 (slimes, bats, mushrooms); no `ERROR`, at most the Jolt warning.

- [ ] **Step 10: Commit**

```powershell
git add data scripts
git status --short
git commit -m "Move the enemies to an enemy library and add the forest enemies and the witch"
```

`git status --short` must not list any probe or `balance_check.gd`.

---

### Task 2: Zones from data, exits, zone switching and save version 4

**Files:**
- Copy: `assets/medieval/building_home_A_green.*`, `building_home_B_green.*`, `building_market_green.*`, `building_tavern_green.*`, `building_well_green.*`, `trees_B_medium.*` (`.gltf` + `.bin`)
- Create: `scripts/world/zone_data.gd`, `data/zones/pradera.tres`
- Replace (whole file): `scripts/world/world_stage.gd`, `scripts/world/encounter_table.gd`, `scripts/world/encounter_meter.gd`, `scripts/world/world.gd`, `scripts/game/game.gd`, `scripts/game/save_data.gd`
- Modify: `scripts/world/vegetation.gd`, `scripts/battle/battle_stage.gd`, `scripts/battle/battle_scene.gd`, `scripts/world/player.gd`, `scripts/game/chests.gd`, `scripts/game/game_state.gd`, `scripts/game/inventory.gd`, `scripts/ui/pause_menu.gd`, `scripts/ui/battle_result.gd`, `scripts/title/title_screen.gd`
- Temporary (never committed): `map_probe.gd`, `map_probe.tscn`, `save_probe.gd`

**Interfaces:**
- Consumes: `EnemyLibrary` (Task 1), `Chests.CHESTS`, `Shop`, `Inn`, `ShopWindow`, `Quest.BOSS_ID`, `BattleActor.Look` names.
- Produces:
  - `ZoneData` (`Resource`): `IDS`, the exported fields listed in Global Constraints; `static by_id(zone_id: String) -> ZoneData`, `entry(entry_id: String) -> Array` (`[pos, yaw]`), `exit_by_id(exit_id: String) -> Dictionary`.
  - `WorldStage`: `MODELS`, `BUILDING_SCALE`, `BUILDING_RADIUS`; `static build(root: Node3D, zone: ZoneData) -> ShaderMaterial` (null without grass), `is_on_path(zone, pos, margin := 0.0) -> bool`, `is_grass_free(pos, zone) -> bool`, `add_cylinder_shape(body, radius, height)`.
  - `BattleStage`: `build(root, zone: ZoneData = null)`, `build_environment(root, zone: ZoneData = null)`, `FOREST_TREE_SCENES`, `FOREST_TREES`.
  - `Vegetation.build(root, area, is_free, seed, tips := PackedColorArray())`.
  - `EncounterTable.pick(zone: ZoneData, pos, rng) -> Array[Combatant]`, `near_start(zone, pos)`; `EncounterMeter.new(rng, grace_m := 9.0, chance_per_m := 0.01)`.
  - `World`: `var zone: ZoneData`; signals `npc_requested(index: int)`, `exit_requested(zone_id: String, entry_id: String)` besides the phase 4 ones; `place_at_entry(entry_id)`, `place_player(pos, yaw_deg := 0.0)`, `set_world_flags(flags: Dictionary)`, `npc_lines(index) -> Array[String]` (`respawn()` is gone).
  - `Player.route: Array[Vector3]` (`AUTOPLAY_ROUTE` is gone).
  - `GameState`: `world_flags`, `key_items`, `zone_id`, `town_zone`; `on_boss_defeated(boss: Combatant) -> String`, `has_flag(flag: String) -> bool`.
  - `Inventory.WING`, `Inventory.KEY_ITEMS`; `Chests.of_zone(zone_id) -> Array[String]` (each chest has `"zone"`).
  - `PauseMenu.travel_requested`; `BattleScene.zone`; `SaveData.VERSION` 4.

- [ ] **Step 1: Copy the forest models**

```powershell
$hex = "assets_src\KayKit-Medieval-Hexagon-Pack-1.0\addons\kaykit_medieval_hexagon_pack\Assets\gltf"
foreach ($n in "building_home_A_green", "building_home_B_green", "building_market_green", "building_tavern_green", "building_well_green") {
    Copy-Item "$hex\buildings\green\$n.gltf", "$hex\buildings\green\$n.bin" assets\medieval\
}
Copy-Item "$hex\decoration\nature\trees_B_medium.gltf", "$hex\decoration\nature\trees_B_medium.bin" assets\medieval\
```

Their texture is `hexagons_medieval.png`, already in `assets\medieval`.

- [ ] **Step 2: Create `scripts/world/zone_data.gd`**

```gdscript
class_name ZoneData extends Resource
## Everything one map of the world is built from (data/zones/<id>.tres): the field and
## its walls, ground and grass, the dirt path and the safe discs, the village, buildings,
## rocks, trees and bushes, the entries and exits, the figures, the boss, the encounter
## formations and pace, the music, the light and the battle backdrop. WorldStage builds
## the map from it, World runs it and Game switches between zones. Pure data plus a few
## lookups: never touches nodes.
##
## Positions are Vector3 on the ground (y = 0). Yaws are degrees about Y, 0 = facing -Z
## for figures and entries, +Z for building doors (as the models come).

## Every zone, in world order (save validation and --autoplay-zone check against it).
const IDS: Array[String] = ["pradera", "bosque"]

@export var id := ""
## Name shown on the exit signs that lead here and in notices ("la pradera").
@export var display_name := ""
## Zone number of the "Equilibrio" tables (1 meadow, 2 forest...).
@export var number := 1

@export_group("Field")
## Half the walkable field along X and Z: invisible walls stand at ±x and ±z.
@export var half_size := Vector2(30, 30)
## Grass, trees and the ground reach this far past the walls, so the edge never looks bare.
@export var outer_margin := 6.0
@export var ground_color := Color(0.08, 0.22, 0.05)
@export var has_grass := true
## Two tip greens of the tall grass (sRGB); every tuft gets a mix of them.
@export var grass_tips := PackedColorArray([Color(0.22, 0.55, 0.12), Color(0.42, 0.72, 0.16)])
@export var grass_seed := 7
## [position, scale] of each hill (unit spheres, half buried) around the field.
@export var hills: Array = []

@export_group("Path and safe ground")
## Corners of the dirt path (no grass, no encounters).
@export var path_points: Array[Vector3] = []
@export var path_half_width := 1.5
## [centre, radius] of each round patch of bare dirt (no grass, no encounters): the
## spawn area, the village clearing, the boss's clearing...
@export var safe_discs: Array = []
## The village: inside this circle World emits village_changed(true) and the village
## music plays. village_radius 0 means the zone has no village.
@export var village_name := ""
@export var village_pos := Vector3.ZERO
@export var village_radius := 0.0

@export_group("Props")
## [position, yaw, WorldStage.MODELS key] of each building (box collider fitted to it).
@export var buildings: Array = []
## [position, rock model (BattleStage.ROCK_SCENES index), scale, yaw] of each rock.
@export var rocks: Array = []
## Trees: tree_tries random spots over the field plus outer_margin, with a fixed seed. A
## spot is kept with a chance that rises from tree_center_chance (inset tree_rise_inset
## or more from the nearest wall) to 1 at the wall, and only if it is clear of the path,
## the safe discs, the glades, the exits, the autoplay route, the rocks, the buildings,
## the chests and the other trees. Within tree_clump_inset of a wall (or outside) trees
## are clumps.
@export var tree_seed := 23
@export var tree_tries := 600
@export var tree_center_chance := 0.05
@export var tree_rise_inset := 22.0
@export var tree_clump_inset := 3.0
@export var tree_spacing := 3.2
@export var tree_scale := Vector2(3.6, 4.4)
## WorldStage.MODELS keys: single trees (each kept spot picks one of the first two) and
## the clump.
@export var tree_models: Array[String] = ["tree_A", "tree_B"]
@export var clump_model := "trees_A"
## [centre, radius] of each glade: no trees, but grass and encounters.
@export var glades: Array = []
@export var bush_seed := 31
@export var bush_tries := 220

@export_group("Entries, exits and figures")
## entry id -> [position, yaw]: where the player appears (arriving through an exit, a
## new game, the Ala de viaje or a defeat).
@export var entries := {}
## Entry of a new game in this zone.
@export var start_entry := "inicio"
## Entry the Ala de viaje and a defeat lead to once this zone's village was visited
## ("" for a zone with no village).
@export var town_entry := ""
## Each exit: {"id", "pos" (trigger, inside the walls), "yaw" (the arch's facing), "to"
## (zone id), "entry" (entry id there), "label" (sign text), "lock" (GameState.world_flags
## key that opens it, "" for always open), "lock_text" (notice while it is closed)}.
@export var exits: Array = []
## Each figure: {"kind": "quest" (the old woman), "shop", "inn" or "npc", "id" (Shop /
## Inn id), "look" (BattleActor.Look name), "pos", "yaw" (0 faces -Z; 180 faces the
## camera), "name", and for "npc" "lines" and, optional, "after_flag" + "lines_after"
## (said once that world flag is set)}.
@export var npcs: Array = []
## The zone's boss (EnemyLibrary id, "" for none) and where it waits.
@export var boss_id := ""
@export var boss_pos := Vector3.ZERO

@export_group("Encounters")
## Formations of a random encounter (each a list of EnemyLibrary ids, left to right),
## every one with the same weight; within start_radius of start_pos only
## start_formations come.
@export var formations: Array = []
@export var start_formations: Array = []
@export var start_pos := Vector3.ZERO
@export var start_radius := 0.0
## EncounterMeter: free meters after each battle, then this chance per meter on grass.
@export var encounter_grace := 9.0
@export var encounter_chance := 0.01

@export_group("Look and sound")
@export var music := "map"
@export var village_music := "village"
@export var sky_top := Color(0.32, 0.52, 0.88)
@export var haze := Color(0.78, 0.84, 0.92)
@export var fog_density := 0.008
@export var sun_color := Color(1.0, 0.9, 0.75)
@export var sun_energy := 0.6
## BattleStage backdrop of the battles fought here ("pradera", "bosque").
@export var backdrop := "pradera"

@export_group("Autoplay")
## Points walked in a loop by --autoplay (clear of trees, rocks and buildings).
@export var autoplay_route: Array[Vector3] = []
## On autoplay the boss only comes out from this level on.
@export var autoplay_boss_level := 1


## The zone with this id (data/zones/<id>.tres), or null if there is none.
static func by_id(zone_id: String) -> ZoneData:
	if not zone_id in IDS:
		return null
	return load("res://data/zones/%s.tres" % zone_id) as ZoneData


## Where entry_id puts the player: [position, yaw in degrees]. Unknown ids give the
## start entry.
func entry(entry_id: String) -> Array:
	return entries.get(entry_id, entries[start_entry])


func exit_by_id(exit_id: String) -> Dictionary:
	for exit: Dictionary in exits:
		if exit.id == exit_id:
			return exit
	return {}
```

- [ ] **Step 3: Create `data/zones/pradera.tres`**

```ini
[gd_resource type="Resource" script_class="ZoneData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/world/zone_data.gd" id="1_zone"]

[resource]
script = ExtResource("1_zone")
id = "pradera"
display_name = "la pradera"
number = 1
half_size = Vector2(30, 30)
outer_margin = 6.0
ground_color = Color(0.08, 0.22, 0.05, 1)
has_grass = true
grass_tips = PackedColorArray(0.22, 0.55, 0.12, 1, 0.42, 0.72, 0.16, 1)
grass_seed = 7
hills = [[Vector3(-40, -5, -42), Vector3(22, 10, 22)], [Vector3(0, -6, -54), Vector3(28, 11, 20)], [Vector3(40, -5, -40), Vector3(22, 9, 22)], [Vector3(54, -6, 0), Vector3(20, 10, 28)], [Vector3(42, -5, 42), Vector3(22, 9, 22)], [Vector3(0, -6, 56), Vector3(28, 10, 20)], [Vector3(-42, -5, 42), Vector3(22, 10, 22)], [Vector3(-54, -6, 0), Vector3(20, 9, 28)]]
path_points = Array[Vector3]([Vector3(0, 0, 26), Vector3(3, 0, 12), Vector3(-2, 0, 0), Vector3(2, 0, -12), Vector3(0, 0, -22)])
path_half_width = 1.5
safe_discs = [[Vector3(0, 0, 26), 4.0], [Vector3(0, 0, -22), 8.0]]
village_name = "Villaclaro"
village_pos = Vector3(0, 0, -22)
village_radius = 8.0
buildings = [[Vector3(-5.5, 0, -25), 60.0, "house_A_red"], [Vector3(5.5, 0, -25), -60.0, "house_B_red"], [Vector3(4.5, 0, -19), 0.0, "well_red"]]
rocks = [[Vector3(-20, 0, -16), 2, 8.0, 15.0], [Vector3(-22, 0, 14), 4, 9.0, 60.0], [Vector3(18, 0, -18), 3, 9.0, 130.0], [Vector3(22, 0, 16), 4, 10.0, 200.0], [Vector3(-10, 0, -18), 1, 8.0, 290.0], [Vector3(12, 0, -20), 2, 9.0, 80.0], [Vector3(-12, 0, 23), 0, 10.0, 170.0], [Vector3(24, 0, 0), 3, 10.0, 240.0], [Vector3(-24, 0, -2), 2, 10.0, 320.0], [Vector3(7, 0, -15), 1, 7.0, 45.0]]
tree_seed = 23
tree_tries = 600
tree_center_chance = 0.05
tree_rise_inset = 22.0
tree_clump_inset = 3.0
tree_spacing = 3.2
tree_scale = Vector2(3.6, 4.4)
tree_models = Array[String](["tree_A", "tree_B"])
clump_model = "trees_A"
glades = []
bush_seed = 31
bush_tries = 220
entries = {
"inicio": [Vector3(0, 0, 26), 0.0],
"norte": [Vector3(0, 0, -25.5), 180.0],
"pueblo": [Vector3(0.8, 0, -14.5), 0.0]
}
start_entry = "inicio"
town_entry = "pueblo"
exits = [{
"entry": "sur",
"id": "norte",
"label": "Al bosque",
"lock": "rey_slime",
"lock_text": "Una niebla espesa cierra el camino del norte.",
"pos": Vector3(0, 0, -28.6),
"to": "bosque",
"yaw": 0.0
}]
npcs = [{
"kind": "quest",
"look": "VILLAGER",
"name": "Anciana",
"pos": Vector3(-2.5, 0, -20),
"yaw": 180.0
}, {
"id": "villaclaro",
"kind": "shop",
"look": "MERCHANT",
"name": "Mercader",
"pos": Vector3(-3, 0, -23.6),
"yaw": 180.0
}, {
"id": "villaclaro",
"kind": "inn",
"look": "INNKEEPER",
"name": "Posadero",
"pos": Vector3(2.8, 0, -22),
"yaw": 180.0
}]
boss_id = "rey_slime"
boss_pos = Vector3(0, 0, -27.5)
formations = [["slime"], ["slime"], ["bat"], ["mushroom"], ["slime", "slime"], ["slime", "bat"]]
start_formations = [["slime"], ["slime", "slime"]]
start_pos = Vector3(0, 0, 26)
start_radius = 20.0
encounter_grace = 9.0
encounter_chance = 0.01
music = "map"
village_music = "village"
sky_top = Color(0.32, 0.52, 0.88, 1)
haze = Color(0.78, 0.84, 0.92, 1)
fog_density = 0.008
sun_color = Color(1, 0.9, 0.75, 1)
sun_energy = 0.6
backdrop = "pradera"
autoplay_route = Array[Vector3]([Vector3(8, 0, 18), Vector3(16, 0, 6), Vector3(10, 0, -6), Vector3(1, 0, -14), Vector3(-1.5, 0, -18), Vector3(-1.2, 0, -23), Vector3(0, 0, -26.5), Vector3(0, 0, -28.6), Vector3(2, 0, -14), Vector3(-6, 0, -4), Vector3(-14, 0, 8), Vector3(-6, 0, 18)])
autoplay_boss_level = 5
```

- [ ] **Step 4: Replace `scripts/world/world_stage.gd`**

```gdscript
class_name WorldStage extends RefCounted
## Builds one map of the world from its ZoneData: the sky and light of the zone, the
## ground, a field of tall grass (Vegetation) with a bare dirt path and safe discs,
## low-poly buildings and rocks with hand-made colliders, trees (denser toward the walls,
## with trunk colliders) and bushes scattered with fixed seeds, invisible walls and hills
## outside. Exits, figures and chests are World's. Every query takes the zone.

## The Medieval Hexagon buildings are miniatures (a house is 0.8 m wide, 0.9 m tall).
const BUILDING_SCALE := 3.5
## Models named by ZoneData (buildings, tree_models, clump_model).
const MODELS := {
	"house_A_red": preload("res://assets/medieval/building_home_A_red.gltf"),
	"house_B_red": preload("res://assets/medieval/building_home_B_red.gltf"),
	"well_red": preload("res://assets/medieval/building_well_red.gltf"),
	"house_A_green": preload("res://assets/medieval/building_home_A_green.gltf"),
	"house_B_green": preload("res://assets/medieval/building_home_B_green.gltf"),
	"market_green": preload("res://assets/medieval/building_market_green.gltf"),
	"tavern_green": preload("res://assets/medieval/building_tavern_green.gltf"),
	"well_green": preload("res://assets/medieval/building_well_green.gltf"),
	"tree_A": preload("res://assets/medieval/tree_single_A.gltf"),
	"tree_B": preload("res://assets/medieval/tree_single_B.gltf"),
	"trees_A": preload("res://assets/medieval/trees_A_medium.gltf"),
	"trees_B": preload("res://assets/medieval/trees_B_medium.gltf"),
}
## Half the widest side of each building at BUILDING_SCALE (measured AABBs), in metres.
const BUILDING_RADIUS := {
	"house_A_red": 1.5, "house_B_red": 1.9, "well_red": 1.3,
	"house_A_green": 1.5, "house_B_green": 1.9, "well_green": 1.3,
	"market_green": 3.2, "tavern_green": 2.4,
}
## Tall grass keeps this far from the path and the safe discs, the rocks and the chests.
const GRASS_PATH_MARGIN := 0.3
const GRASS_ROCK_MARGIN := 0.2
const GRASS_BUILDING_MARGIN := 0.4
const CHEST_GRASS_MARGIN := 1.0
## Trees keep this far from the path, the autoplay route, the rocks, the buildings, the
## chests and the exits; bushes from the path, the rocks and the chests.
const TREE_PATH_MARGIN := 3.0
const TREE_ROUTE_MARGIN := 2.5
const TREE_ROCK_MARGIN := 1.5
const TREE_BUILDING_MARGIN := 2.5
const CHEST_TREE_MARGIN := 2.2
const TREE_EXIT_MARGIN := 3.5
const BUSH_PATH_MARGIN := 0.8
const BUSH_ROCK_MARGIN := 0.6
const CHEST_BUSH_MARGIN := 1.2
const BUSH_SCALE := Vector2(0.7, 1.2)
## Colliders (only inside the walls): a trunk for single trees, a wider one for clumps.
const TRUNK_RADIUS := 0.35
const CLUMP_RADIUS := 2.0
const TREE_COLLIDER_HEIGHT := 3.0


## Builds zone under root. Returns the tall grass material (null if the zone has no
## grass), so the world can bend it away from the player.
static func build(root: Node3D, zone: ZoneData) -> ShaderMaterial:
	BattleStage.build_environment(root, zone)
	_add_ground(root, zone)
	_add_path(root, zone)
	for rock in zone.rocks:
		_add_solid_model(root, BattleStage.ROCK_SCENES[rock[1]], rock[0], rock[2], rock[3])
	for building in zone.buildings:
		_add_solid_model(root, MODELS[building[2]], building[0], BUILDING_SCALE, building[1])
	_add_trees(root, zone)
	_add_bushes(root, zone)
	for hill in zone.hills:
		BattleStage.add_mesh(root, BattleStage.unit_sphere(), BattleStage.HILL, hill[0], hill[1])
	_add_walls(root, zone)
	if not zone.has_grass:
		return null
	return Vegetation.build(root, _outer_rect(zone), is_grass_free.bind(zone), zone.grass_seed,
		zone.grass_tips)


## True on the dirt path and the safe discs: no encounters there. margin widens every
## one of them (the grass keeps a little off the path's edge).
static func is_on_path(zone: ZoneData, pos: Vector3, margin := 0.0) -> bool:
	var p := Vector2(pos.x, pos.z)
	for disc in zone.safe_discs:
		if p.distance_to(Vector2(disc[0].x, disc[0].z)) < disc[1] + margin:
			return true
	var points := zone.path_points
	for i in points.size() - 1:
		var a := Vector2(points[i].x, points[i].z)
		var b := Vector2(points[i + 1].x, points[i + 1].z)
		var closest := Geometry2D.get_closest_point_to_segment(p, a, b)
		if p.distance_to(closest) < zone.path_half_width + margin:
			return true
	return false


## Where tall grass may grow: off the path and the safe discs (the village is inside one),
## the rocks, the buildings and the chests.
static func is_grass_free(pos: Vector3, zone: ZoneData) -> bool:
	if is_on_path(zone, pos, GRASS_PATH_MARGIN) or _near_chest(zone, pos, CHEST_GRASS_MARGIN):
		return false
	return not _near_rock(zone, pos, GRASS_ROCK_MARGIN) \
		and not _near_building(zone, pos, GRASS_BUILDING_MARGIN)


## Upright cylinder collider standing on the ground, for village props and figures.
static func add_cylinder_shape(body: StaticBody3D, radius: float, height: float) -> void:
	var cylinder := CylinderShape3D.new()
	cylinder.radius = radius
	cylinder.height = height
	var shape := CollisionShape3D.new()
	shape.shape = cylinder
	shape.position = Vector3(0, height / 2.0, 0)
	body.add_child(shape)


## The field plus outer_margin on every side (position.x = min X, position.y = min Z).
static func _outer_rect(zone: ZoneData) -> Rect2:
	var half := zone.half_size + Vector2.ONE * zone.outer_margin
	return Rect2(-half, half * 2.0)


static func _add_ground(root: Node3D, zone: ZoneData) -> void:
	var mesh := PlaneMesh.new()
	mesh.size = (zone.half_size + Vector2.ONE * 50.0) * 2.0
	BattleStage.add_mesh(root, mesh, zone.ground_color, Vector3.ZERO)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	shape.shape = WorldBoundaryShape3D.new()
	body.add_child(shape)
	root.add_child(body)


static func _add_path(root: Node3D, zone: ZoneData) -> void:
	var points := zone.path_points
	for i in points.size() - 1:
		var a := points[i]
		var b := points[i + 1]
		var d := b - a
		var mesh := PlaneMesh.new()
		mesh.size = Vector2(zone.path_half_width * 2.0, d.length())
		var mid := (a + b) / 2.0 + Vector3(0, 0.01, 0)
		var yaw := rad_to_deg(atan2(d.x, d.z))
		BattleStage.add_mesh(root, mesh, BattleStage.DIRT, mid, Vector3.ONE, Vector3(0, yaw, 0))
	# Round the inner bends so the drawn path matches is_on_path (union of capsules).
	for i in range(1, points.size() - 1):
		_add_disc(root, points[i], zone.path_half_width)
	for disc in zone.safe_discs:
		_add_disc(root, disc[0], disc[1])


static func _add_disc(root: Node3D, center: Vector3, radius: float) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.02
	BattleStage.add_mesh(root, mesh, BattleStage.DIRT, center + Vector3(0, 0.01, 0))


## An imported model on a static body, with a box collider fitted to its mesh (the
## free models bring no collision of their own).
static func _add_solid_model(root: Node3D, scene: PackedScene, pos: Vector3, scl: float, \
		yaw_deg: float) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	body.rotation_degrees = Vector3(0, yaw_deg, 0)
	root.add_child(body)
	var model := BattleStage.add_model(body, scene, Vector3.ZERO, scl)
	var bounds := BattleStage.model_aabb(model)
	var box := BoxShape3D.new()
	box.size = bounds.size * scl
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position = bounds.get_center() * scl
	body.add_child(shape)


static func _add_trees(root: Node3D, zone: ZoneData) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = zone.tree_seed
	var area := zone.half_size + Vector2.ONE * zone.outer_margin
	var placed: Array[Vector2] = []
	var single_a: Array[Transform3D] = []
	var single_b: Array[Transform3D] = []
	var clumps: Array[Transform3D] = []
	for i in zone.tree_tries:
		# Every roll is made even for spots left out, so the layout stays stable.
		var pos := Vector3(rng.randf_range(-area.x, area.x), 0.0, rng.randf_range(-area.y, area.y))
		var roll := rng.randf()
		var yaw := rng.randf() * TAU
		var scl := rng.randf_range(zone.tree_scale.x, zone.tree_scale.y)
		var use_a := rng.randf() < 0.5
		# Distance to the nearest wall (negative outside the field).
		var inset := minf(zone.half_size.x - absf(pos.x), zone.half_size.y - absf(pos.z))
		var rise := clampf(1.0 - inset / zone.tree_rise_inset, 0.0, 1.0)
		if roll > lerpf(zone.tree_center_chance, 1.0, rise) or not _tree_fits(zone, pos, placed):
			continue
		placed.append(Vector2(pos.x, pos.z))
		var xform := Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * scl), pos)
		var clump := inset < zone.tree_clump_inset
		if clump:
			clumps.append(xform)
		elif use_a:
			single_a.append(xform)
		else:
			single_b.append(xform)
		if inset > 0.0:
			var body := StaticBody3D.new()
			body.position = pos
			root.add_child(body)
			add_cylinder_shape(body, CLUMP_RADIUS if clump else TRUNK_RADIUS,
				TREE_COLLIDER_HEIGHT)
	LowPoly.add_multimesh(root, BattleStage.scene_mesh(MODELS[zone.tree_models[0]]), single_a)
	LowPoly.add_multimesh(root, BattleStage.scene_mesh(MODELS[zone.tree_models[1]]), single_b)
	LowPoly.add_multimesh(root, BattleStage.scene_mesh(MODELS[zone.clump_model]), clumps)


static func _tree_fits(zone: ZoneData, pos: Vector3, placed: Array[Vector2]) -> bool:
	if is_on_path(zone, pos, TREE_PATH_MARGIN) or _near_route(zone, pos, TREE_ROUTE_MARGIN):
		return false
	if _near_rock(zone, pos, TREE_ROCK_MARGIN) or _near_chest(zone, pos, CHEST_TREE_MARGIN):
		return false
	if _near_building(zone, pos, TREE_BUILDING_MARGIN) or _near_exit(zone, pos, TREE_EXIT_MARGIN):
		return false
	var p := Vector2(pos.x, pos.z)
	for glade in zone.glades:
		if p.distance_to(Vector2(glade[0].x, glade[0].z)) < glade[1]:
			return false
	for other in placed:
		if p.distance_to(other) < zone.tree_spacing:
			return false
	return true


static func _add_bushes(root: Node3D, zone: ZoneData) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = zone.bush_seed
	var bushes: Array[Transform3D] = []
	var half := zone.half_size
	for i in zone.bush_tries:
		var pos := Vector3(rng.randf_range(-half.x, half.x), 0.0, rng.randf_range(-half.y, half.y))
		var yaw := rng.randf() * TAU
		var scl := rng.randf_range(BUSH_SCALE.x, BUSH_SCALE.y)
		if is_on_path(zone, pos, BUSH_PATH_MARGIN) or _near_rock(zone, pos, BUSH_ROCK_MARGIN) \
				or _near_chest(zone, pos, CHEST_BUSH_MARGIN) \
				or _near_building(zone, pos, GRASS_BUILDING_MARGIN):
			continue
		bushes.append(Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * scl), pos))
	LowPoly.add_multimesh(root, LowPoly.bush_mesh(), bushes)


## True within margin of a rock's footprint.
static func _near_rock(zone: ZoneData, pos: Vector3, margin: float) -> bool:
	var p := Vector2(pos.x, pos.z)
	for rock in zone.rocks:
		if p.distance_to(Vector2(rock[0].x, rock[0].z)) < BattleStage.rock_radius(rock) + margin:
			return true
	return false


## True within margin of a building's footprint (a circle around its widest side).
static func _near_building(zone: ZoneData, pos: Vector3, margin: float) -> bool:
	var p := Vector2(pos.x, pos.z)
	for building in zone.buildings:
		var radius := BUILDING_RADIUS.get(building[2], 1.6) as float
		if p.distance_to(Vector2(building[0].x, building[0].z)) < radius + margin:
			return true
	return false




## True within margin of one of the zone's chests (Chests.CHESTS of this zone).
static func _near_chest(zone: ZoneData, pos: Vector3, margin: float) -> bool:
	var p := Vector2(pos.x, pos.z)
	for chest_id in Chests.of_zone(zone.id):
		var chest_pos: Vector3 = Chests.CHESTS[chest_id].pos
		if p.distance_to(Vector2(chest_pos.x, chest_pos.z)) < margin:
			return true
	return false


## True within margin of an exit's trigger (its arch stands there).
static func _near_exit(zone: ZoneData, pos: Vector3, margin: float) -> bool:
	var p := Vector2(pos.x, pos.z)
	for exit: Dictionary in zone.exits:
		if p.distance_to(Vector2(exit.pos.x, exit.pos.z)) < margin:
			return true
	return false


## True within margin of the loop Player walks on --autoplay, so no tree blocks it.
static func _near_route(zone: ZoneData, pos: Vector3, margin: float) -> bool:
	var p := Vector2(pos.x, pos.z)
	var route := zone.autoplay_route
	for i in route.size():
		var a := Vector2(route[i].x, route[i].z)
		var next := route[(i + 1) % route.size()]
		var b := Vector2(next.x, next.z)
		if p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b)) < margin:
			return true
	return false


static func _add_walls(root: Node3D, zone: ZoneData) -> void:
	var hx := zone.half_size.x
	var hz := zone.half_size.y
	var walls := [
		[Vector3(0, 2, -hz), Vector3(hx * 2.0, 4, 1)],
		[Vector3(0, 2, hz), Vector3(hx * 2.0, 4, 1)],
		[Vector3(-hx, 2, 0), Vector3(1, 4, hz * 2.0)],
		[Vector3(hx, 2, 0), Vector3(1, 4, hz * 2.0)],
	]
	for wall in walls:
		var body := StaticBody3D.new()
		body.position = wall[0]
		var box := BoxShape3D.new()
		box.size = wall[1]
		var shape := CollisionShape3D.new()
		shape.shape = box
		body.add_child(shape)
		root.add_child(body)
```

- [ ] **Step 5: Replace `scripts/world/encounter_table.gd`**

```gdscript
class_name EncounterTable extends RefCounted
## Which enemies a random encounter brings, from the zone's ZoneData: within
## start_radius of start_pos only start_formations come (slimes near the meadow's spawn,
## one enemy at a time at the forest's entry); elsewhere every formation of the zone has
## the same weight. Pure: no nodes.


static func near_start(zone: ZoneData, pos: Vector3) -> bool:
	return not zone.start_formations.is_empty() and Vector2(pos.x, pos.z).distance_to(
		Vector2(zone.start_pos.x, zone.start_pos.z)) < zone.start_radius


## The enemy data of one encounter at pos in zone (not duplicated: BattleScene does it).
static func pick(zone: ZoneData, pos: Vector3, rng: RandomNumberGenerator) -> Array[Combatant]:
	var formations: Array = zone.start_formations if near_start(zone, pos) else zone.formations
	return EnemyLibrary.formation(formations[rng.randi_range(0, formations.size() - 1)])
```

- [ ] **Step 6: Replace `scripts/world/encounter_meter.gd`**

```gdscript
class_name EncounterMeter extends RefCounted
## Random encounter rule. Only meters walked on grass count. After reset() the first
## grace_m meters are free; after that every full meter has chance_per_m of a battle.
## Each zone sets its own pace (ZoneData.encounter_grace / encounter_chance); the
## meadow and the forest use 9 m and 1 %: a battle every ~110 m, ~22 s walking at 5 m/s.

const GRACE_M := 9.0
const CHANCE_PER_M := 0.01

var grace_m := GRACE_M
var chance_per_m := CHANCE_PER_M

var _rng: RandomNumberGenerator
var _grace := GRACE_M
## Meters walked past the grace that have not been rolled yet (always < 1).
var _walked := 0.0


func _init(rng: RandomNumberGenerator, p_grace_m := GRACE_M, p_chance_per_m := CHANCE_PER_M) -> void:
	_rng = rng
	grace_m = p_grace_m
	chance_per_m = p_chance_per_m
	_grace = grace_m


## Gives the grace distance again (start, back from a battle, respawn).
func reset() -> void:
	_grace = grace_m
	_walked = 0.0


## Adds the meters walked this frame. Returns true when a battle starts.
func advance(meters: float, in_grass: bool) -> bool:
	if not in_grass or meters <= 0.0:
		return false
	if _grace > 0.0:
		var used := minf(_grace, meters)
		_grace -= used
		meters -= used
	_walked += meters
	while _walked >= 1.0:
		_walked -= 1.0
		if _rng.randf() < chance_per_m:
			reset()
			return true
	return false
```

- [ ] **Step 7: Replace `scripts/world/world.gd`**

```gdscript
class_name World extends Node3D
## One map of the world, built from `zone` (a ZoneData, set before add_child; the
## meadow if none): field, village, figures, boss, chests, exits, player, follow camera,
## status window and random encounters. A click or tap on the ground (held and dragged
## too) walks the player there, with a marker on the spot. Next to a figure or a closed
## chest (the nearest one in reach) Enter / Space talks to the old woman
## (talk_requested) or to a villager (npc_requested), opens the shop (shop_requested),
## asks for a room (inn_requested) or opens the chest (chest_opened); a click or tap on
## one of them walks there and does it on arrival. With the boss present, walking into
## it starts the boss battle. Walking into an open exit emits exit_requested; a closed
## one (its world flag not set: set_world_flags()) shows its fog and its notice.
## Encounters and exits freeze the player until set_active(true) (or until Game frees
## the map). Run on its own (res://scenes/world/world.tscn) it prints each encounter,
## talk, shop, inn, chest and exit and goes on.

signal encounter_triggered(boss: bool)
signal talk_requested
## The player talked to the villager zone.npcs[index] (kind "npc").
signal npc_requested(index: int)
## The player asked the merchant of shop_id (a Shop.SHOPS key) to trade.
signal shop_requested(shop_id: String)
## The player talked to the innkeeper of inn_id (an Inn.INNS key).
signal inn_requested(inn_id: String)
## The player asked to open a closed chest (a Chests.CHESTS key); Game opens it in the
## GameState and calls set_chest_open().
signal chest_opened(chest_id: String)
## The player walked into (true) or out of (false) the village clearing.
signal village_changed(inside: bool)
## The player walked into an open exit: Game loads zone_id at its entry entry_id.
signal exit_requested(zone_id: String, entry_id: String)

const PLAYER_SCENE := preload("res://scenes/world/player.tscn")
const ACTOR_SCENE := preload("res://scenes/battle/battle_actor.tscn")
const HERO_DATA := preload("res://data/hero.tres")
const NOTICE_TIME := 2.0
const FONT_SIZE := 24
## How close the player must be to talk to a figure / to open a chest / to run into the
## boss / to take an exit.
const TALK_RADIUS := 2.5
const CHEST_RADIUS := 1.8
const BOSS_RADIUS := 2.5
const EXIT_RADIUS := 1.2
## After arriving (or after a closed exit's notice) exits wait until the player is this
## much farther than EXIT_RADIUS from all of them.
const EXIT_REARM := 0.8
## A click or tap this close to a figure or a chest means "go there and use it".
const NPC_TAP_RADIUS := 1.2
## Kinds of the things the player can use on the map, and their prompts.
const TALK := "talk"
const NPC := "npc"
const SHOP := "shop"
const INN := "inn"
const CHEST := "chest"
const PROMPTS := {
	TALK: "Enter o toca: hablar",
	NPC: "Enter o toca: hablar",
	SHOP: "Enter o toca: comprar",
	INN: "Enter o toca: hablar",
	CHEST: "Enter o toca: abrir",
}
## ZoneData.npcs kinds -> use kinds.
const NPC_KINDS := {"quest": TALK, "npc": NPC, "shop": SHOP, "inn": INN}
## Chest model: wooden box with a gold band and a lid hinged at the back.
const CHEST_SIZE := Vector3(0.9, 0.45, 0.6)
const CHEST_LID_HEIGHT := 0.2
const CHEST_WOOD := Color(0.5, 0.3, 0.14)
const CHEST_BAND := Color(1.0, 0.78, 0.2)
## Angle of an open lid (degrees about X: the front edge swings up and back).
const CHEST_OPEN_ANGLE := 110.0
## Exit arch: two posts and a beam of dark wood, a sign board with the exit's label
## (always facing the camera, south) and, while closed, a bank of fog.
const ARCH_WOOD := Color(0.36, 0.22, 0.1)
const ARCH_WIDTH := 3.6
const ARCH_HEIGHT := 3.0
const SIGN_COLOR := Color(0.62, 0.45, 0.25)
const FOG_COLOR := Color(0.92, 0.93, 0.97, 0.6)
const MARKER_COLOR := Color(1.0, 0.9, 0.4)
## Meters walked between two footstep sounds.
const STEP_DISTANCE := 1.6

## The map to build; set before add_child.
var zone: ZoneData

var _rng := RandomNumberGenerator.new()
var _meter: EncounterMeter
var _grass: ShaderMaterial
var _player: Player
var _camera: FollowCamera
var _boss: StaticBody3D
## chest id -> lid pivot (rotation.x opens it); a chest in _open_chests is open.
var _chest_lids := {}
var _open_chests: Array[String] = []
## exit id -> fog bank shown while the exit is closed.
var _fogs := {}
var _flags := {}
var _exits_armed := false
var _boss_present := false
var _ui: CanvasLayer
var _name_label: Label
var _hp_label: Label
var _mp_label: Label
var _exp_label: Label
var _potion_label: Label
var _gold_label: Label
var _quest_label: Label
var _notice: Label
var _notice_serial := 0
var _prompt: Label
var _dialogue: DialogueBox
var _autoplay := false
var _waiting := false
var _talking := false
## What was in reach last frame ({} for nothing), so autoplay acts once per approach.
var _was_near := {}
## Set by a click or tap on a figure or chest: use it as soon as it is in reach.
var _use_on_arrival := {}
## Autoplay only: npc indexes already talked to on this map.
var _autoplay_talked := {}
var _marker: MeshInstance3D
var _audio: AudioDirector
var _in_village := false
var _step_m := 0.0


func _ready() -> void:
	if zone == null:
		zone = ZoneData.by_id("pradera")
	_rng.randomize()
	_autoplay = OS.get_cmdline_user_args().has("--autoplay")
	_meter = EncounterMeter.new(_rng, zone.encounter_grace, zone.encounter_chance)
	_grass = WorldStage.build(self, zone)
	for npc: Dictionary in zone.npcs:
		_add_figure(BattleActor.Look[npc.look], npc.pos, npc.yaw, 0.4, 1.8)
	if zone.boss_id != "":
		_boss = _add_figure(EnemyLibrary.look(zone.boss_id), zone.boss_pos, 180.0, 1.0, 2.0)
	for id in Chests.of_zone(zone.id):
		_chest_lids[id] = build_chest(self, Chests.CHESTS[id])
	for exit: Dictionary in zone.exits:
		_fogs[exit.id] = _build_exit(exit)
	set_boss_present(false)
	set_world_flags({})
	_player = PLAYER_SCENE.instantiate()
	_player.route = zone.autoplay_route
	add_child(_player)
	_camera = FollowCamera.new()
	add_child(_camera)
	_camera.target = _player
	_marker = _build_marker()
	_build_ui()
	place_at_entry(zone.start_entry)
	_camera.current = true
	if get_parent() == get_tree().root:
		_connect_standalone()


func _physics_process(_delta: float) -> void:
	if _grass:
		Vegetation.set_pusher(_grass, _player.global_position)
	_marker.visible = _player.move_target != null
	if _marker.visible:
		_marker.position = _player.move_target
	if _waiting or _talking:
		return
	var pos := _player.global_position
	var inside := _is_in_village(pos)
	if inside != _in_village:
		_in_village = inside
		village_changed.emit(inside)
	_play_steps()
	if _check_exits(pos):
		return
	if _boss_present and _flat_distance(pos, zone.boss_pos) <= BOSS_RADIUS:
		_trigger(true)
		return
	var in_grass := not WorldStage.is_on_path(zone, pos)
	if _meter.advance(_player.last_step_m, in_grass):
		_trigger(false)
		return
	var near := _nearest_use(pos)
	_prompt.visible = not near.is_empty()
	if _prompt.visible:
		_prompt.text = PROMPTS[near.kind]
	if not near.is_empty() and near == _use_on_arrival:
		_use_on_arrival = {}
		_player.move_target = null
		_use(near)
	elif not near.is_empty() and near != _was_near and _autoplay:
		# Autoplay talks to each villager once per visit to the zone.
		if near.kind != NPC or not _autoplay_talked.has(near.index):
			_autoplay_talked[near.index] = true
			_use(near)
	_was_near = near


func _unhandled_input(event: InputEvent) -> void:
	if _waiting or _talking:
		return
	if _prompt.visible and event.is_action_pressed("ui_accept") and not event.is_echo():
		get_viewport().set_input_as_handled()
		_use(_nearest_use(_player.global_position))
		return
	var point: Variant = _pointer_on_ground(event)
	if point == null:
		return
	get_viewport().set_input_as_handled()
	if event is InputEventMouseButton:
		_use_on_arrival = _tapped_use(point)
	_player.move_to(point)


## Where a left click, a drag with the left button held, or a tap (the engine turns
## touches into mouse events) hits the ground plane; null for any other event.
func _pointer_on_ground(event: InputEvent) -> Variant:
	var screen: Vector2
	var button := event as InputEventMouseButton
	var motion := event as InputEventMouseMotion
	if button != null and button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
		screen = button.position
	elif motion != null and motion.button_mask & MOUSE_BUTTON_MASK_LEFT:
		screen = motion.position
	else:
		return null
	var ground := Plane(Vector3.UP, 0.0)
	return ground.intersects_ray(_camera.project_ray_origin(screen),
		_camera.project_ray_normal(screen))


## Hidden and frozen while a battle is on top; back on, the encounter grace restarts.
func set_active(active: bool) -> void:
	process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	visible = active
	_ui.visible = active
	_camera.current = active
	if active:
		_meter.reset()
		_waiting = false
		_player.input_enabled = true


## Puts the player at one of the zone's entries (ZoneData.entry()).
func place_at_entry(entry_id: String) -> void:
	var entry := zone.entry(entry_id)
	place_player(entry[0], entry[1])


## Puts the player at pos facing yaw_deg (0 faces north; a loaded game faces north),
## with the encounter grace restarted and the exits waiting until the player steps
## away from them. in_village() is right at once; village_changed is not emitted.
func place_player(pos: Vector3, yaw_deg := 0.0) -> void:
	_player.place(pos, deg_to_rad(yaw_deg))
	_camera.snap()
	_meter.reset()
	_was_near = {}
	_use_on_arrival = {}
	_step_m = 0.0
	_exits_armed = false
	_in_village = _is_in_village(pos)


func player_position() -> Vector3:
	return _player.global_position


func in_village() -> bool:
	return _in_village


## Footsteps, encounter and dialogue sounds. Without it the map is silent.
func set_audio(audio: AudioDirector) -> void:
	_audio = audio
	_dialogue.set_audio(audio)


## Shows or removes the zone's boss; when absent it has no collision.
func set_boss_present(present: bool) -> void:
	if _boss == null:
		return
	_boss_present = present
	_boss.visible = present
	_boss.process_mode = Node.PROCESS_MODE_INHERIT if present else Node.PROCESS_MODE_DISABLED


## The world progress (GameState.world_flags): which exits are open (their fog hides)
## and what the villagers say.
func set_world_flags(flags: Dictionary) -> void:
	_flags = flags
	for exit: Dictionary in zone.exits:
		(_fogs[exit.id] as Node3D).visible = not _is_open(exit)


## The lines villager zone.npcs[index] says now (lines_after once its after_flag is set).
func npc_lines(index: int) -> Array[String]:
	var npc: Dictionary = zone.npcs[index]
	var lines: Array[String] = []
	if npc.has("after_flag") and _flags.get(npc.after_flag, false):
		lines.assign(npc.lines_after)
	else:
		lines.assign(npc.lines)
	return lines


## Freezes the player and shows the lines one by one; returns when they are all read.
func show_dialogue(speaker: String, lines: Array[String]) -> void:
	freeze(true)
	await _dialogue.say(speaker, lines)
	await freeze(false)


## Freezes the player (no walking, prompts, encounters, exits or uses) while a dialogue
## or the shop is open. Unfreezing waits one frame, so the key that closed the window
## does not open it again; await it.
func freeze(on: bool) -> void:
	if on:
		_talking = true
		_player.input_enabled = false
		_prompt.hide()
		return
	await get_tree().process_frame
	_player.input_enabled = true
	_talking = false


## Shows the weapon and shield worn on the hero (Equipment ids, "" for none).
func set_hero_equipment(weapon_id: String, shield_id: String) -> void:
	_player.set_equipment(weapon_id, shield_id)


## Opens (lid tipped back, tweened unless instant) or closes a chest of this zone. An
## open chest can't be used any more; ids of other zones are ignored.
func set_chest_open(chest_id: String, open: bool, instant := false) -> void:
	if not _chest_lids.has(chest_id):
		return
	var lid: Node3D = _chest_lids[chest_id]
	var angle := deg_to_rad(CHEST_OPEN_ANGLE) if open else 0.0
	if open and not _open_chests.has(chest_id):
		_open_chests.append(chest_id)
	elif not open:
		_open_chests.erase(chest_id)
	if instant:
		lid.rotation.x = angle
	else:
		lid.create_tween().tween_property(lid, "rotation:x", angle, 0.35) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func refresh_status(hero: Combatant, potions: int, gold: int, quest_text := "") -> void:
	_name_label.text = "%s  Nv %d" % [hero.display_name, hero.level]
	_hp_label.text = "PV %d / %d" % [hero.hp, hero.max_hp]
	_mp_label.text = "PM %d / %d" % [hero.mp, hero.max_mp]
	var next := Leveling.exp_for_next(hero.level)
	if next < 0:
		_exp_label.text = "EXP %d" % hero.experience
	else:
		_exp_label.text = "EXP %d / %d" % [hero.experience, next]
	_potion_label.text = "%s ×%d" % [Inventory.display_name(Inventory.POTION), potions]
	_gold_label.text = "Oro %d G" % gold
	_quest_label.text = quest_text
	_quest_label.visible = quest_text != ""


## Shows a short line under the status for NOTICE_TIME seconds (a newer one replaces it).
func show_notice(text: String) -> void:
	_notice_serial += 1
	var serial := _notice_serial
	_notice.text = text
	_notice.show()
	if _autoplay:
		print(text)
	await get_tree().create_timer(NOTICE_TIME).timeout
	if serial == _notice_serial:
		_notice.hide()


func _trigger(boss: bool) -> void:
	if _audio:
		_audio.play_sfx(SfxLibrary.ENCOUNTER)
	_waiting = true
	_player.input_enabled = false
	_prompt.hide()
	encounter_triggered.emit(boss)


func _is_open(exit: Dictionary) -> bool:
	return exit.lock == "" or _flags.get(exit.lock, false)


## Takes an open exit the player walked into (true: the map waits for Game), or shows a
## closed one's notice once per approach. Exits only count once the player has stepped
## away from all of them since arriving.
func _check_exits(pos: Vector3) -> bool:
	var nearest := {}
	var nearest_d := INF
	for exit: Dictionary in zone.exits:
		var d := _flat_distance(pos, exit.pos)
		if d < nearest_d:
			nearest = exit
			nearest_d = d
	if nearest.is_empty():
		return false
	if not _exits_armed:
		_exits_armed = nearest_d > EXIT_RADIUS + EXIT_REARM
		return false
	if nearest_d > EXIT_RADIUS:
		return false
	_exits_armed = false
	if not _is_open(nearest):
		show_notice(nearest.lock_text)
		return false
	_waiting = true
	_player.input_enabled = false
	_prompt.hide()
	exit_requested.emit(nearest.to, nearest.entry)
	return true


## The nearest thing in reach of pos that can be used: {"kind": TALK / NPC / SHOP / INN
## / CHEST, "id": shop, inn or chest id ("" otherwise), "index": the npc's index}, or {}.
func _nearest_use(pos: Vector3) -> Dictionary:
	var best := {}
	var best_d := INF
	for use in _uses():
		var d := _flat_distance(pos, use.pos)
		if d <= use.radius and d < best_d:
			best = {"kind": use.kind, "id": use.id, "index": use.index}
			best_d = d
	return best


## The thing a click or tap at point means ({} if none): within NPC_TAP_RADIUS of it.
func _tapped_use(point: Vector3) -> Dictionary:
	for use in _uses():
		if _flat_distance(point, use.pos) <= NPC_TAP_RADIUS:
			return {"kind": use.kind, "id": use.id, "index": use.index}
	return {}


## Everything usable now: the zone's figures and its closed chests.
func _uses() -> Array[Dictionary]:
	var uses: Array[Dictionary] = []
	for i in zone.npcs.size():
		var npc: Dictionary = zone.npcs[i]
		uses.append({"kind": NPC_KINDS[npc.kind], "id": npc.get("id", ""), "index": i,
			"pos": npc.pos, "radius": TALK_RADIUS})
	for id in _chest_lids:
		if not _open_chests.has(id):
			uses.append({"kind": CHEST, "id": id, "index": -1, "pos": Chests.CHESTS[id].pos,
				"radius": CHEST_RADIUS})
	return uses


func _use(use: Dictionary) -> void:
	match use.get("kind", ""):
		TALK:
			talk_requested.emit()
		NPC:
			npc_requested.emit(use.index)
		SHOP:
			shop_requested.emit(use.id)
		INN:
			inn_requested.emit(use.id)
		CHEST:
			chest_opened.emit(use.id)


func _connect_standalone() -> void:
	refresh_status(HERO_DATA, Inventory.START_POTIONS, GameState.START_GOLD)
	encounter_triggered.connect(func(boss: bool) -> void:
		print("Encuentro en %s (jefe: %s, en el camino: %s)" % [_player.global_position, boss,
			WorldStage.is_on_path(zone, _player.global_position)])
		set_active(true))
	talk_requested.connect(func() -> void:
		var lines: Array[String] = ["Hola, viajero."]
		await show_dialogue(Quest.NPC_NAME, lines))
	npc_requested.connect(func(index: int) -> void:
		await show_dialogue(zone.npcs[index].name, npc_lines(index)))
	shop_requested.connect(func(shop_id: String) -> void: print("Tienda: %s" % shop_id))
	inn_requested.connect(func(inn_id: String) -> void: print("Posada: %s" % inn_id))
	chest_opened.connect(func(chest_id: String) -> void:
		print("Cofre: %s" % chest_id)
		set_chest_open(chest_id, true))
	exit_requested.connect(func(zone_id: String, entry_id: String) -> void:
		print("Salida: %s (%s)" % [zone_id, entry_id])
		set_active(true))


## Flat ring on the spot the player walks to. Drawn on top of everything, so the tall
## grass never hides it.
func _build_marker() -> MeshInstance3D:
	var ring := TorusMesh.new()
	ring.inner_radius = 0.3
	ring.outer_radius = 0.42
	ring.rings = 16
	ring.ring_segments = 4
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = MARKER_COLOR
	material.no_depth_test = true
	var marker := MeshInstance3D.new()
	marker.mesh = ring
	marker.material_override = material
	marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	marker.visible = false
	add_child(marker)
	return marker


## The arch of an exit (turned by its yaw) with its sign, which always faces the camera,
## and the fog bank that closes it. Returns the fog bank.
func _build_exit(exit: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.position = exit.pos
	add_child(root)
	var arch := Node3D.new()
	arch.rotation_degrees.y = exit.yaw
	root.add_child(arch)
	var post := BoxMesh.new()
	post.size = Vector3(0.3, ARCH_HEIGHT, 0.3)
	for x in [-ARCH_WIDTH / 2.0, ARCH_WIDTH / 2.0]:
		BattleStage.add_mesh(arch, post, ARCH_WOOD, Vector3(x, ARCH_HEIGHT / 2.0, 0))
	var beam := BoxMesh.new()
	beam.size = Vector3(ARCH_WIDTH + 0.6, 0.35, 0.4)
	BattleStage.add_mesh(arch, beam, ARCH_WOOD, Vector3(0, ARCH_HEIGHT, 0))
	var board := BoxMesh.new()
	board.size = Vector3(2.4, 0.55, 0.08)
	BattleStage.add_mesh(root, board, SIGN_COLOR, Vector3(0, ARCH_HEIGHT + 0.5, 0.1))
	var label := Label3D.new()
	label.text = exit.label
	label.font_size = 48
	label.pixel_size = 0.008
	label.outline_size = 10
	label.modulate = Color(1.0, 0.95, 0.8)
	label.position = Vector3(0, ARCH_HEIGHT + 0.5, 0.15)
	root.add_child(label)
	var fog := Node3D.new()
	root.add_child(fog)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = FOG_COLOR
	for puff in [Vector3(-1.2, 0.8, 0), Vector3(0, 1.1, 0.1), Vector3(1.2, 0.8, 0),
			Vector3(-0.6, 1.9, -0.1), Vector3(0.7, 2.0, 0)]:
		var mi := MeshInstance3D.new()
		mi.mesh = BattleStage.unit_sphere()
		mi.material_override = material
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = puff
		mi.scale = Vector3(1.1, 0.9, 0.7)
		fog.add_child(mi)
	return fog


## A closed chest on a box collider under root: wooden box with a gold band around it and a lid on
## a pivot at its back edge. Returns the lid pivot.
static func build_chest(root: Node3D, chest: Dictionary) -> Node3D:
	var body := StaticBody3D.new()
	body.position = chest.pos
	body.rotation_degrees.y = chest.yaw
	root.add_child(body)
	var box := BoxShape3D.new()
	box.size = CHEST_SIZE + Vector3(0, CHEST_LID_HEIGHT, 0)
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position.y = box.size.y / 2.0
	body.add_child(shape)
	var base := BoxMesh.new()
	base.size = CHEST_SIZE
	BattleStage.add_mesh(body, base, CHEST_WOOD, Vector3(0, CHEST_SIZE.y / 2.0, 0))
	var band := BoxMesh.new()
	band.size = Vector3(CHEST_SIZE.x + 0.04, 0.08, CHEST_SIZE.z + 0.04)
	BattleStage.add_mesh(body, band, CHEST_BAND, Vector3(0, CHEST_SIZE.y * 0.7, 0))
	var lid := Node3D.new()
	lid.position = Vector3(0, CHEST_SIZE.y, CHEST_SIZE.z / 2.0)
	body.add_child(lid)
	var top := BoxMesh.new()
	top.size = Vector3(CHEST_SIZE.x, CHEST_LID_HEIGHT, CHEST_SIZE.z)
	BattleStage.add_mesh(lid, top, CHEST_WOOD,
		Vector3(0, CHEST_LID_HEIGHT / 2.0, -CHEST_SIZE.z / 2.0))
	var lock := BoxMesh.new()
	lock.size = Vector3(0.14, 0.16, 0.05)
	BattleStage.add_mesh(lid, lock, CHEST_BAND, Vector3(0, 0.0, -CHEST_SIZE.z - 0.02))
	var lid_band := BoxMesh.new()
	lid_band.size = Vector3(0.1, CHEST_LID_HEIGHT + 0.02, CHEST_SIZE.z + 0.02)
	for x in [-0.3, 0.3]:
		BattleStage.add_mesh(lid, lid_band, CHEST_BAND,
			Vector3(x, CHEST_LID_HEIGHT / 2.0, -CHEST_SIZE.z / 2.0))
	return lid


## A figure: a BattleActor on a cylinder collider, turned yaw_deg (180 faces south,
## toward the camera).
func _add_figure(look: BattleActor.Look, pos: Vector3, yaw_deg: float, radius: float, \
		height: float) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	body.rotation_degrees.y = yaw_deg
	add_child(body)
	WorldStage.add_cylinder_shape(body, radius, height)
	var actor: BattleActor = ACTOR_SCENE.instantiate()
	actor.look = look
	body.add_child(actor)
	return body


func _build_ui() -> void:
	_ui = CanvasLayer.new()
	add_child(_ui)
	var panel := BattleHud.make_window()
	panel.position = Vector2(24, 24)
	panel.custom_minimum_size = Vector2(240, 0)
	_ui.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	_name_label = _label()
	box.add_child(_name_label)
	_hp_label = _label()
	box.add_child(_hp_label)
	_mp_label = _label()
	box.add_child(_mp_label)
	_exp_label = _label()
	box.add_child(_exp_label)
	_potion_label = _label()
	box.add_child(_potion_label)
	_gold_label = _label()
	box.add_child(_gold_label)
	_quest_label = _label()
	_quest_label.hide()
	box.add_child(_quest_label)
	_notice = _label()
	_notice.hide()
	box.add_child(_notice)
	_prompt = _label()
	_prompt.text = PROMPTS[TALK]
	_prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	_prompt.add_theme_constant_override("outline_size", 8)
	_ui.add_child(_prompt)
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, \
		Control.PRESET_MODE_MINSIZE, 200)
	_prompt.hide()
	_dialogue = DialogueBox.new()
	_ui.add_child(_dialogue)


func _label() -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", Color.WHITE)
	return label


## A soft footstep every STEP_DISTANCE meters walked.
func _play_steps() -> void:
	_step_m += _player.last_step_m
	if _step_m < STEP_DISTANCE:
		return
	_step_m -= STEP_DISTANCE
	if _audio:
		_audio.play_sfx(SfxLibrary.STEP)


func _is_in_village(pos: Vector3) -> bool:
	return zone.village_radius > 0.0 \
		and _flat_distance(pos, zone.village_pos) <= zone.village_radius


static func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))
```

- [ ] **Step 8: Replace `scripts/game/game.gd`**

```gdscript
class_name Game extends Node
## One play session, created by TitleScreen (setup() before add_child). Owns the
## GameState and the map of the current zone (a World built from its ZoneData), and puts
## a battle on top of the map when an encounter starts (the enemies come from
## EncounterTable with the zone's formations, or the zone's boss). The map stays while
## battles come and go, so the hero's position, the camera and the encounter grace
## survive them; walking into an open exit fades to black, frees the map and builds the
## next zone at the exit's entry (GameState.zone_id). A victory adds the gold and counts
## every enemy defeated for the quest; a boss also sets its world flag (the Rey Slime
## lifts the fog of the meadow's north exit) and gives its key item. Fleeing just goes
## back to the map; a defeat takes half the gold (GameState.defeat_gold_loss()), heals the
## hero and sends them to the last village visited (GameState.town_zone), EXP kept, like
## the Ala de viaje used from the pause menu. Talking to the old woman heals, moves the
## quest on and, once the slimes are reported, brings out the Rey Slime; the other
## villagers say their ZoneData lines. The merchant opens the ShopWindow; the innkeeper
## offers a night (Inn.stay(): fade to black, full HP and MP, autosave); a chest gives
## what it holds (Chests.open()) and stays open. The hero's figure on the map and in
## battle shows the weapon and shield worn. Picks the zone's music (map, village, battle,
## boss), autosaves after talking, after every won battle, after shopping, (silently)
## after opening a chest, after a defeat and after every change of zone, and opens the
## pause menu. Emits quit_to_title when the player goes back to the title.
## On autoplay it prints the gold and the equipment each time they change.
## Run on its own (res://scenes/game/game.tscn) it starts a new game with its own
## AudioDirector and default options.
##
## `-- --autoplay --autoplay-save`: after the first autosave that follows a won battle
## it prints the saved values ("Guardado: ...") and goes back to the title, which loads
## the save at once; the loaded game prints the same values ("Cargado: ...").
## `-- --autoplay --autoplay-menu`: MENU_TOUR_DELAY seconds into the map (still inside
## the encounter grace) it shows every page of the pause menu (PauseMenu.tour()), to
## record frames of it.
## `-- --autoplay --autoplay-zone=<id>`: a new game that starts in that zone with the
## level, gold, gear and progress AUTOPLAY_ZONES gives it.

signal quit_to_title

const HERO_DATA := preload("res://data/hero.tres")
const BATTLE_SCENE := preload("res://scenes/battle/battle_scene.tscn")
const WORLD_SCENE := preload("res://scenes/world/world.tscn")
const FADE_TIME := 0.3
const HEAL_LINE := "Descansas un momento. PV y PM recuperados."
const SAVED_NOTICE := "Partida guardada."
const LOAD_FAILED_NOTICE := "No se pudo cargar la partida. Empiezas de nuevo."
## Notice after beating a boss (by id); other bosses announce their key item.
const BOSS_NOTICES := {
	"rey_slime": "¡Villaclaro está a salvo! La niebla del norte se disipa...",
}
const KEY_ITEM_NOTICE := "¡Consigues un %s!"
const MENU_TOUR_DELAY := 1.0
## Seconds of black while the hero sleeps at the inn.
const INN_NIGHT_TIME := 0.8
## On autoplay the hero only sleeps at an inn below this share of max HP, so the nights
## don't eat the gold for the shop's gear.
const AUTOPLAY_INN_RATIO := 0.5
## --autoplay-zone=<id>: what a new game starting in each zone gets, as planned when
## arriving there (zone 1 done: Lv 5, its shop's gear, the Rey Slime beaten).
const AUTOPLAY_ZONES := {
	"bosque": {
		"experience": 136,
		"gold": 150,
		"gear": [Equipment.COPPER_SWORD, Equipment.LEATHER_MAIL, Equipment.WOODEN_SHIELD],
		"flags": ["rey_slime"],
		"quest_done": true,
	},
}

var state: GameState
## Seconds played, saved with the game; stops while paused.
var play_time := 0.0

var _world: World
var _zone: ZoneData
var _fade: ColorRect
var _pause: PauseMenu
var _audio: AudioDirector
var _options: GameOptions
var _save := {}
var _busy := false
var _leaving := false
var _autoplay := false
var _autoplay_save := false
var _autoplay_menu := false
var _last_quest_text := ""
var _last_gear_text := ""
var _shop: ShopWindow
## Something was bought, sold or equipped since the shop opened.
var _shop_changed := false
var _rng := RandomNumberGenerator.new()


## audio and options come from the title screen; save is the Dictionary read by
## SaveStore.load_game(), empty for a new game.
func setup(audio: AudioDirector, options: GameOptions, save: Dictionary) -> void:
	_audio = audio
	_options = options
	_save = save


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_autoplay = args.has("--autoplay")
	_autoplay_save = _autoplay and args.has("--autoplay-save")
	_autoplay_menu = _autoplay and args.has("--autoplay-menu")
	_rng.randomize()
	if _options == null:
		_options = GameOptions.new()
	if _audio == null:
		_audio = AudioDirector.new()
		add_child(_audio)
		_audio.set_volumes(_options.music_volume, _options.sfx_volume)
	state = GameState.new(HERO_DATA)
	var load_failed := false
	var start_pos: Variant = null
	if not _save.is_empty():
		var info := SaveData.apply(state, _save)
		if info.valid:
			start_pos = info.position
			play_time = info.play_time
			if _autoplay_save:
				print("Cargado: %s" % _summary(SaveData.from_state(state, info.position,
					info.play_time)))
		else:
			load_failed = true
	elif _autoplay:
		_apply_autoplay_zone(args)
	_build_shop()
	_build_fade()
	_build_pause()
	_switch_zone(state.zone_id, "")
	if start_pos != null:
		_world.place_player(start_pos)
	# Synthesize the tracks played later now, under black, so no first play stalls.
	for id in [MusicLibrary.VILLAGE, MusicLibrary.VICTORY, MusicLibrary.DEFEAT]:
		MusicLibrary.build(id)
	_play_map_music()
	if load_failed:
		_world.show_notice(LOAD_FAILED_NOTICE)
	if _autoplay_menu:
		get_tree().create_timer(MENU_TOUR_DELAY).timeout.connect(_pause.tour)


func _process(delta: float) -> void:
	play_time += delta


## --autoplay-zone=<id>: starts the new game in that zone with AUTOPLAY_ZONES' state.
func _apply_autoplay_zone(args: PackedStringArray) -> void:
	for arg in args:
		if not arg.begins_with("--autoplay-zone="):
			continue
		var zone_id := arg.trim_prefix("--autoplay-zone=")
		if not zone_id in ZoneData.IDS:
			push_error("Unknown zone for --autoplay-zone: %s" % zone_id)
			return
		state.zone_id = zone_id
		var start: Dictionary = AUTOPLAY_ZONES.get(zone_id, {})
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
		if start.quest_done:
			state.quest.stage = Quest.Stage.DONE
		print("Zona de inicio: %s (Nv %d)" % [zone_id, state.hero.level])


## Frees the current map and builds zone_id with the player at entry_id ("" for the
## zone's start entry). No fade: callers fade around it.
func _switch_zone(zone_id: String, entry_id: String) -> void:
	if _world:
		remove_child(_world)
		_world.queue_free()
	_zone = ZoneData.by_id(zone_id)
	state.zone_id = zone_id
	_world = WORLD_SCENE.instantiate()
	_world.zone = _zone
	add_child(_world)
	move_child(_world, 0)
	_world.set_audio(_audio)
	_world.encounter_triggered.connect(_on_encounter)
	_world.talk_requested.connect(_on_talk)
	_world.npc_requested.connect(_on_npc)
	_world.shop_requested.connect(_on_shop)
	_world.inn_requested.connect(_on_inn)
	_world.chest_opened.connect(_on_chest)
	_world.exit_requested.connect(_on_exit)
	_world.village_changed.connect(_on_village_changed)
	if entry_id != "":
		_world.place_at_entry(entry_id)
	for id in state.opened_chests:
		_world.set_chest_open(id, true, true)
	_world.set_world_flags(state.world_flags)
	_update_boss()
	_refresh_status()
	MusicLibrary.build(_zone.music)
	if _world.in_village():
		_on_village_changed(true)
	if _autoplay:
		print("Zona: %s" % zone_id)


func _on_encounter(boss: bool) -> void:
	if _busy:
		return
	_set_busy(true)
	var enemies: Array[Combatant] = []
	if boss:
		enemies.append(EnemyLibrary.data(_zone.boss_id))
	else:
		enemies = EncounterTable.pick(_zone, _world.player_position(), _rng)
	await _fade_to(1.0)
	_world.set_active(false)
	_audio.play_music(MusicLibrary.BOSS if boss else MusicLibrary.BATTLE)
	var battle: BattleScene = BATTLE_SCENE.instantiate()
	battle.setup(state.hero, enemies, state.inventory)
	battle.set_audio(_audio)
	battle.set_equipment(state.loadout.worn(Equipment.WEAPON),
		state.loadout.worn(Equipment.SHIELD))
	battle.gold_lost = state.defeat_gold_loss()
	battle.char_time = _options.char_time()
	battle.zone = _zone
	add_child(battle)
	await _fade_to(0.0)
	var outcome: int = await battle.finished
	var won := outcome == BattleEngine.State.WON
	await _fade_to(1.0)
	var notice := ""
	if won:
		state.gold += battle.engine.gold_won
		for enemy in battle.engine.enemies:
			state.quest.on_victory(enemy.id)
			if enemy.is_boss:
				notice = _boss_notice(enemy)
	elif outcome == BattleEngine.State.LOST:
		state.gold -= battle.gold_lost
		state.heal_full()
		_go_to_town()
		notice = "Has vuelto a %s." % _zone.village_name
	battle.queue_free()
	_world.set_world_flags(state.world_flags)
	_update_boss()
	_refresh_status()
	_world.set_active(true)
	_play_map_music()
	await _fade_to(0.0)
	if notice != "":
		_world.show_notice(notice)
	if outcome == BattleEngine.State.LOST:
		_autosave(false)  # the gold lost sticks: going back to the title can't undo it
	if won:
		var data := _autosave(not boss)
		if _autoplay_save and _save.is_empty() and not data.is_empty():
			print("Guardado: %s" % _summary(data))
			quit_to_title.emit()
			return
	_set_busy(false)


## Sets the boss's world flag, gives its key item and says so.
func _boss_notice(boss: Combatant) -> String:
	var key_item := state.on_boss_defeated(boss)
	if BOSS_NOTICES.has(boss.id):
		return BOSS_NOTICES[boss.id]
	if key_item != "":
		return KEY_ITEM_NOTICE % Inventory.KEY_ITEMS[key_item]
	return ""


## Puts the player at the town entry of the last village visited, switching zones if
## needed (no fade: the caller is already under black).
func _go_to_town() -> void:
	var town := ZoneData.by_id(state.town_zone)
	if state.town_zone != state.zone_id:
		_switch_zone(state.town_zone, town.town_entry)
	else:
		_world.place_at_entry(town.town_entry)
		_on_village_changed(_world.in_village())


## An open exit: fades to black, builds the next zone at the exit's entry, autosaves.
func _on_exit(zone_id: String, entry_id: String) -> void:
	if _busy:
		return
	_set_busy(true)
	await _fade_to(1.0)
	_switch_zone(zone_id, entry_id)
	_play_map_music()
	await _fade_to(0.0)
	_autosave(false)
	_set_busy(false)


## The Ala de viaje, used from the pause menu: to the last village visited.
func _on_travel_requested() -> void:
	if _busy:
		return
	_set_busy(true)
	await _fade_to(1.0)
	_go_to_town()
	_refresh_status()
	_play_map_music()
	await _fade_to(0.0)
	_world.show_notice("Vuelas a %s." % _zone.village_name)
	_autosave(false)
	_set_busy(false)


## Inside a village it becomes the last one visited; the music follows.
func _on_village_changed(inside: bool) -> void:
	if inside and _zone.town_entry != "":
		state.town_zone = _zone.id
	_play_map_music()


## The old woman always heals; what she says and gives comes from the quest.
func _on_talk() -> void:
	if _busy:
		return
	_set_busy(true)
	var result := state.quest.talk()
	var lines: Array[String] = []
	lines.append_array(result.lines)
	lines.append(HEAL_LINE)
	state.heal_full()
	if result.potions > 0:
		state.inventory.add(Inventory.POTION, result.potions)
	_refresh_status()
	await _world.show_dialogue(Quest.NPC_NAME, lines)
	_update_boss()
	_autosave(true)
	_set_busy(false)


## A villager: says its lines (World.npc_lines(): they change with the world flags).
func _on_npc(index: int) -> void:
	if _busy:
		return
	_set_busy(true)
	await _world.show_dialogue(_zone.npcs[index].name, _world.npc_lines(index))
	_set_busy(false)


## The merchant: the ShopWindow until the player leaves; autosaves if anything changed.
## On autoplay it only opens when there is something to buy.
func _on_shop(shop_id: String) -> void:
	if _busy or (_autoplay and Shop.autoplay_picks(state, shop_id).is_empty()):
		return
	_set_busy(true)
	_shop_changed = false
	_world.freeze(true)
	await _shop.run(shop_id)
	await _world.freeze(false)
	_refresh_status()
	if _shop_changed:
		_autosave(true)
	_set_busy(false)


## The innkeeper: Sí pays the night, fades to black and back with HP and MP full and
## saves; without gold, or with No, nothing happens. On autoplay it only stops there
## below AUTOPLAY_INN_RATIO of max HP and with the price.
func _on_inn(inn_id: String) -> void:
	var hurt := state.hero.hp < state.hero.max_hp * AUTOPLAY_INN_RATIO
	if _busy or (_autoplay and (not hurt or state.gold < Inn.price(inn_id))):
		return
	_set_busy(true)
	_world.freeze(true)
	var lines: Array[String] = []
	var slept := false
	if await _shop.ask(Inn.keeper(inn_id), Inn.offer(inn_id)):
		var result := Inn.stay(state, inn_id)
		slept = result.ok
		if slept:
			await _fade_to(1.0)
			_refresh_status()
			_audio.play_sfx(SfxLibrary.HEAL)
			await get_tree().create_timer(INN_NIGHT_TIME).timeout
			await _fade_to(0.0)
		lines.append(result.text)
	else:
		lines.append("Vuelve cuando quieras.")
	await _world.freeze(false)
	await _world.show_dialogue(Inn.keeper(inn_id), lines)
	_refresh_status()
	if slept:
		_autosave(true)
	_set_busy(false)


## A closed chest: gives what it holds, opens the lid and saves without a notice (the
## notice shows what was found).
func _on_chest(chest_id: String) -> void:
	if _busy:
		return
	var result := Chests.open(state, chest_id)
	if not result.opened:
		return
	_world.set_chest_open(chest_id, true)
	_audio.play_sfx(SfxLibrary.LEVEL_UP)
	_refresh_status()
	_world.show_notice(result.text)
	_autosave(false)


## Writes the save file; shows SAVED_NOTICE if notice. Returns the saved data, or an
## empty Dictionary if the file could not be written.
func _autosave(notice: bool) -> Dictionary:
	var data := SaveData.from_state(state, _world.player_position(), play_time)
	if not SaveStore.save_game(data):
		return {}
	if notice:
		_audio.play_sfx(SfxLibrary.SAVE)
		_world.show_notice(SAVED_NOTICE)
	return data


func _on_save_requested() -> void:
	var data := SaveData.from_state(state, _world.player_position(), play_time)
	_pause.show_save_result(SaveStore.save_game(data))


## The tree stays paused (TitleScreen unpauses when it frees this game), so the map can't
## walk or roll an encounter during the fade; the menu is shut and deaf meanwhile.
func _on_title_requested() -> void:
	if _leaving:
		return
	_leaving = true
	_set_busy(true)
	_pause.hide()
	_pause.set_process_unhandled_input(false)
	quit_to_title.emit()


## The zone's boss is on the map until beaten: the Rey Slime only while the quest asks
## for it; on autoplay only from the zone's autoplay_boss_level on.
func _update_boss() -> void:
	if _zone.boss_id == "":
		return
	var strong_enough := not _autoplay or state.hero.level >= _zone.autoplay_boss_level
	var wanted := state.quest.boss_available() if _zone.boss_id == Quest.BOSS_ID \
		else not state.has_flag(_zone.boss_id)
	_world.set_boss_present(wanted and strong_enough)


## The zone's map music, or its village one inside the village.
func _play_map_music() -> void:
	_audio.play_music(_zone.village_music if _world.in_village() else _zone.music)


## The pause menu only opens on the map with nothing else going on.
func _set_busy(busy: bool) -> void:
	_busy = busy
	_pause.available = not busy and not _autoplay


## Updates the map's status window and the hero's weapon and shield; on autoplay also
## prints each new quest line and each change of gold or equipment.
func _refresh_status() -> void:
	var quest_text := state.quest.status_text()
	_world.refresh_status(state.hero, state.inventory.count(Inventory.POTION), state.gold,
		quest_text)
	var loadout := state.loadout
	_world.set_hero_equipment(loadout.worn(Equipment.WEAPON), loadout.worn(Equipment.SHIELD))
	if _autoplay and quest_text != _last_quest_text:
		print(quest_text)
	_last_quest_text = quest_text
	var worn := PackedStringArray()
	for slot in Equipment.SLOTS:
		if loadout.worn(slot) != "":
			worn.append(Equipment.display_name(loadout.worn(slot)))
	var gear_text := "Oro %d G · Equipo: %s · ATK %d DEF %d" % [state.gold, ", ".join(worn),
		state.hero.total_attack(), state.hero.total_defense()]
	if _autoplay and gear_text != _last_gear_text:
		print(gear_text)
	_last_gear_text = gear_text


## One line with every saved value, keys sorted, for --autoplay-save.
static func _summary(data: Dictionary) -> String:
	return JSON.stringify(data, "", true)


func _build_shop() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 4
	add_child(layer)
	_shop = ShopWindow.new()
	_shop.setup(state, _audio)
	layer.add_child(_shop)
	_shop.changed.connect(func() -> void:
		_shop_changed = true
		_refresh_status())


func _build_fade() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade)


func _build_pause() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	_pause = PauseMenu.new()
	_pause.setup(state, _options, _audio)
	layer.add_child(_pause)
	_pause.save_requested.connect(_on_save_requested)
	_pause.title_requested.connect(_on_title_requested)
	_pause.travel_requested.connect(_on_travel_requested)
	_pause.state_changed.connect(_refresh_status)
	_pause.available = not _autoplay


func _fade_to(alpha: float) -> void:
	var t := create_tween()
	t.tween_property(_fade, "color:a", alpha, FADE_TIME)
	await t.finished
```

- [ ] **Step 9: Replace `scripts/game/save_data.gd`**

```gdscript
class_name SaveData extends RefCounted
## Turns the session into a Dictionary that SaveStore writes as JSON, and back. Pure:
## no nodes, no files. JSON reads every number as a float, so apply() converts them.
## VERSION goes in every save so a later format can migrate older files. Version 2 (full
## combat) adds the gold and changes how the hero grows, so version 1 saves are refused.
## The spells are not saved: Leveling.sync_skills() gives them back from the level.
## Version 3 (economy and equipment) adds the loadout, the equipment in the bag and the
## opened chests; a version 2 save still loads, with the starting gear, an empty bag and
## every chest closed. Version 4 (the world of zones) adds the zone the hero is on, the
## world flags, the key items and the last village visited; a version 2 or 3 save still
## loads on the meadow (its position is a meadow one), with the "rey_slime" flag set if
## its quest was already done, no key items and Villaclaro as the last village.

const VERSION := 4
## Oldest version apply() still reads.
const OLDEST_VERSION := 2
## Combatant fields of the hero that change while playing (the rest come from hero.tres).
const HERO_FIELDS: Array[String] = ["level", "experience", "hp", "max_hp", "mp", "max_mp",
	"attack", "defense", "speed"]


static func from_state(state: GameState, player_pos: Vector3, play_time: float) -> Dictionary:
	var hero := {}
	for field in HERO_FIELDS:
		hero[field] = state.hero.get(field)
	var flags: Array[String] = []
	for flag: String in state.world_flags:
		if state.world_flags[flag]:
			flags.append(flag)
	flags.sort()
	return {
		"version": VERSION,
		"hero": hero,
		"inventory": state.inventory.to_dict(),
		"quest": {"stage": state.quest.stage, "kills": state.quest.kills},
		"gold": state.gold,
		"loadout": state.loadout.to_dict(),
		"bag": state.bag_equipment.duplicate(),
		"chests": state.opened_chests.duplicate(),
		"zone": state.zone_id,
		"town": state.town_zone,
		"flags": flags,
		"key_items": state.key_items.duplicate(),
		"position": [player_pos.x, player_pos.z],
		"play_time": play_time,
	}


## Loads data into state. Returns {"valid": bool, "position": Vector3, "play_time":
## float}; when valid is false, state is left untouched. The zone to load is then
## state.zone_id.
static func apply(state: GameState, data: Dictionary) -> Dictionary:
	if not is_valid(data):
		return {"valid": false, "position": Vector3.ZERO, "play_time": 0.0}
	for field in HERO_FIELDS:
		state.hero.set(field, int(data.hero[field]))
	Leveling.sync_skills(state.hero)
	state.gold = int(data.gold)
	state.loadout = Loadout.new()
	state.loadout.set_slots(data.get("loadout", state.loadout.to_dict()))
	state.bag_equipment.assign(data.get("bag", []))
	state.opened_chests.assign(data.get("chests", []))
	state.refresh_equipment()
	var items := {}
	for id: String in data.inventory:
		items[id] = int(data.inventory[id])
	state.inventory.set_items(items)
	state.quest.stage = clampi(int(data.quest.stage), Quest.Stage.OFFER, Quest.Stage.DONE) \
		as Quest.Stage
	state.quest.kills = int(data.quest.kills)
	state.world_flags = {}
	if int(data.version) >= 4:
		for flag: String in data.flags:
			state.world_flags[flag] = true
		state.key_items.assign(data.key_items)
		state.zone_id = data.zone
		state.town_zone = data.town
	else:
		# Older saves: always on the meadow; a finished quest means the Rey Slime is beaten.
		if state.quest.stage == Quest.Stage.DONE:
			state.world_flags[Quest.BOSS_ID] = true
		state.key_items.clear()
		state.zone_id = "pradera"
		state.town_zone = "pradera"
	var pos: Array = data.position
	return {"valid": true, "position": Vector3(pos[0], 0.0, pos[1]),
		"play_time": float(data.play_time)}


## True if data has a version apply() reads and every field with the right type.
static func is_valid(data: Dictionary) -> bool:
	if not (data.get("version") is float and int(data.version) >= OLDEST_VERSION \
			and int(data.version) <= VERSION):
		return false
	if int(data.version) >= 3 and not _valid_equipment(data):
		return false
	if int(data.version) >= 4 and not _valid_world(data):
		return false
	var hero: Variant = data.get("hero")
	if not hero is Dictionary:
		return false
	for field in HERO_FIELDS:
		if not (hero as Dictionary).get(field) is float:
			return false
	var inventory: Variant = data.get("inventory")
	if not inventory is Dictionary:
		return false
	for count: Variant in (inventory as Dictionary).values():
		if not count is float:
			return false
	var quest: Variant = data.get("quest")
	if not (quest is Dictionary and quest.get("stage") is float and quest.get("kills") is float):
		return false
	if not data.get("gold") is float:
		return false
	var pos: Variant = data.get("position")
	if not (pos is Array and pos.size() == 2 and pos[0] is float and pos[1] is float):
		return false
	return data.get("play_time") is float


## Version 3 fields: every worn id fits its slot, every bag id is equipment and every
## chest id exists.
static func _valid_equipment(data: Dictionary) -> bool:
	var loadout: Variant = data.get("loadout")
	if not loadout is Dictionary:
		return false
	for slot in Equipment.SLOTS:
		var id: Variant = (loadout as Dictionary).get(slot)
		if not id is String or (id != "" and Equipment.slot(id) != slot):
			return false
	var bag: Variant = data.get("bag")
	if not bag is Array:
		return false
	for id: Variant in bag:
		if not (id is String and Equipment.exists(id)):
			return false
	var chests: Variant = data.get("chests")
	if not chests is Array:
		return false
	for id: Variant in chests:
		if not (id is String and Chests.CHESTS.has(id)):
			return false
	return true


## Version 4 fields: the zone and the last village are ZoneData ids, the flags are
## strings and every key item exists.
static func _valid_world(data: Dictionary) -> bool:
	for key in ["zone", "town"]:
		var zone_id: Variant = data.get(key)
		if not (zone_id is String and zone_id in ZoneData.IDS):
			return false
	var flags: Variant = data.get("flags")
	if not flags is Array:
		return false
	for flag: Variant in flags:
		if not flag is String:
			return false
	var key_items: Variant = data.get("key_items")
	if not key_items is Array:
		return false
	for id: Variant in key_items:
		if not (id is String and Inventory.KEY_ITEMS.has(id)):
			return false
	return true
```

- [ ] **Step 10: Edit the other files**

In `scripts/world/vegetation.gd`:

1. Replace:

```gdscript
## flowers where is_free.call(Vector3) is true. Returns the shared grass material.
static func build(root: Node3D, area: Rect2, is_free: Callable, seed: int) -> ShaderMaterial:
```

with:

```gdscript
## flowers where is_free.call(Vector3) is true. tips: the two tip greens (sRGB) mixed in
## every tuft (empty: TIP_COLORS). Returns the shared grass material.
static func build(root: Node3D, area: Rect2, is_free: Callable, seed: int, \
		tips := PackedColorArray()) -> ShaderMaterial:
	if tips.size() < 2:
		tips = PackedColorArray(TIP_COLORS)
```

2. Replace:

```gdscript
			var tint: Color = TIP_COLORS[0].lerp(TIP_COLORS[1], rng.randf()).srgb_to_linear()
```

with:

```gdscript
			var tint: Color = tips[0].lerp(tips[1], rng.randf()).srgb_to_linear()
```


In `scripts/battle/battle_stage.gd`:

1. Replace:

```gdscript
## Builds the battle backdrop: sky, warm sun, fog, grass field with tall grass
## (Vegetation) around the fighters, dirt path, low-poly rocks, trees and bushes, and
## distant hills. The environment, the mesh and model helpers and the rock and tree
## models are shared with WorldStage.
```

with:

```gdscript
## Builds the battle backdrop of a zone (ZoneData.backdrop): sky, sun and fog of the
## zone, grass field with tall grass (Vegetation) around the fighters, dirt path,
## low-poly rocks, trees and bushes, and distant hills. "pradera" is the open meadow;
## "bosque" closes a ring of trees around the fighters on darker ground. The environment,
## the mesh and model helpers and the rock and tree models are shared with WorldStage.
```

2. Replace:

```gdscript
const HILL := Color(0.27, 0.47, 0.22)
const HAZE := Color(0.78, 0.84, 0.92)
```

with:

```gdscript
const HILL := Color(0.27, 0.47, 0.22)
```

3. Replace:

```gdscript
	preload("res://assets/medieval/trees_A_medium.gltf"),
```

with:

```gdscript
	preload("res://assets/medieval/trees_A_medium.gltf"),
]
## TREE_SCENES plus the forest's clump of trees B (index 3, FOREST_TREES only).
const FOREST_TREE_SCENES: Array[PackedScene] = [
	preload("res://assets/medieval/tree_single_A.gltf"),
	preload("res://assets/medieval/tree_single_B.gltf"),
	preload("res://assets/medieval/trees_A_medium.gltf"),
	preload("res://assets/medieval/trees_B_medium.gltf"),
```

4. Replace:

```gdscript


static func build(root: Node3D) -> void:
	build_environment(root)
	var ground := PlaneMesh.new()
	ground.size = Vector2(160, 160)
	add_mesh(root, ground, GRASS, Vector3.ZERO)
```

with:

```gdscript
## The forest backdrop: ground, grass tips and the ring of trees (same entries as TREES)
## that stands close behind and beside the fighters, out of the camera's way.
const FOREST_GROUND := Color(0.2, 0.38, 0.14)
const FOREST_TIPS := [Color(0.16, 0.42, 0.1), Color(0.3, 0.55, 0.14)]
const FOREST_TREES := [
	[Vector3(-7.5, 0, -6), 0, 4.2, 20.0],
	[Vector3(-9, 0, -1), 1, 4.0, 70.0],
	[Vector3(7.5, 0, -7), 1, 4.4, 160.0],
	[Vector3(9.5, 0, -1.5), 0, 3.9, 240.0],
	[Vector3(-4, 0, -11), 2, 4.6, 200.0],
	[Vector3(3.5, 0, -12), 3, 4.4, 300.0],
	[Vector3(-11, 0, -10), 3, 4.2, 90.0],
	[Vector3(11, 0, -11), 2, 4.0, 10.0],
	[Vector3(-1, 0, -17), 3, 4.8, 130.0],
	[Vector3(-13, 0, 3), 2, 4.0, 45.0],
	[Vector3(13, 0, 3.5), 3, 4.0, 280.0],
]


## zone: whose sky, light and backdrop to use (null: the meadow's).
static func build(root: Node3D, zone: ZoneData = null) -> void:
	build_environment(root, zone)
	var forest := zone != null and zone.backdrop == "bosque"
	var ground := PlaneMesh.new()
	ground.size = Vector2(160, 160)
	add_mesh(root, ground, FOREST_GROUND if forest else GRASS, Vector3.ZERO)
```

5. Replace:

```gdscript
	for tree in TREES:
		add_model(root, TREE_SCENES[tree[1]], tree[0], tree[2], tree[3])
```

with:

```gdscript
	for tree in FOREST_TREES if forest else TREES:
		add_model(root, FOREST_TREE_SCENES[tree[1]], tree[0], tree[2], tree[3])
```

6. Replace:

```gdscript
	Vegetation.build(root, GRASS_AREA, _is_grass_free, GRASS_SEED)


## Sky, tonemap, fog and the warm sun shared by every outdoor scene.
static func build_environment(root: Node3D) -> void:
	_add_environment(root)
	_add_sun(root)
```

with:

```gdscript
	Vegetation.build(root, GRASS_AREA, _is_grass_free, GRASS_SEED,
		PackedColorArray(FOREST_TIPS) if forest else PackedColorArray())


## Sky, tonemap, fog and sun of zone (null: the meadow's warm daylight), shared by the
## map and its battles.
static func build_environment(root: Node3D, zone: ZoneData = null) -> void:
	if zone == null:
		zone = ZoneData.new()
	_add_environment(root, zone)
	_add_sun(root, zone)
```

7. Replace:

```gdscript
static func _add_environment(root: Node3D) -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.32, 0.52, 0.88)
	sky_material.sky_horizon_color = HAZE
	sky_material.ground_horizon_color = HAZE
```

with:

```gdscript
static func _add_environment(root: Node3D, zone: ZoneData) -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = zone.sky_top
	sky_material.sky_horizon_color = zone.haze
	sky_material.ground_horizon_color = zone.haze
```

8. Replace:

```gdscript
	env.fog_light_color = HAZE
	env.fog_density = 0.008
```

with:

```gdscript
	env.fog_light_color = zone.haze
	env.fog_density = zone.fog_density
```

9. Replace:

```gdscript
static func _add_sun(root: Node3D) -> void:
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.9, 0.75)
	# Tuned for the Compatibility renderer (needed for the web build); 1.3 looked
	# right under Forward+ but washes everything out here.
	sun.light_energy = 0.6
```

with:

```gdscript
static func _add_sun(root: Node3D, zone: ZoneData) -> void:
	var sun := DirectionalLight3D.new()
	sun.light_color = zone.sun_color
	# Tuned for the Compatibility renderer (needed for the web build); 1.3 looked
	# right under Forward+ but washes everything out here. The meadow uses 0.6.
	sun.light_energy = zone.sun_energy
```


In `scripts/battle/battle_scene.gd`:

1. Replace:

```gdscript
var gold_lost := 0
```

with:

```gdscript
var gold_lost := 0
## Zone the battle is fought in: its sky, light and backdrop (null: the meadow's). Set
## before adding it to the tree.
var zone: ZoneData
```

2. Replace:

```gdscript
	BattleStage.build(self)
```

with:

```gdscript
	BattleStage.build(self, zone)
```


In `scripts/world/player.gd`:

1. Replace:

```gdscript
## With `-- --autoplay` it walks AUTOPLAY_ROUTE in a loop instead of reading keys.
```

with:

```gdscript
## With `-- --autoplay` it walks `route` (the zone's autoplay route) in a loop instead
## of reading keys.
```

2. Replace:

```gdscript
const TURN_SPEED := 10.0
## Points walked in a loop by --autoplay: mostly grass, clear of rocks, and through the
## village, next to the old woman, the merchant, where the Rey Slime appears and the
## innkeeper, and past two of the chests (Chests.CHESTS).
const AUTOPLAY_ROUTE: Array[Vector3] = [
	Vector3(8, 0, 18),
	Vector3(16, 0, 6),
	Vector3(10, 0, -6),
	Vector3(1, 0, -14),
	Vector3(-1.5, 0, -18),
	Vector3(-1.2, 0, -23),
	Vector3(0, 0, -26.5),
	Vector3(2, 0, -14),
	Vector3(-6, 0, -4),
	Vector3(-14, 0, 8),
	Vector3(-6, 0, 18),
]
```

with:

```gdscript
const TURN_SPEED := 10.0
```

3. Replace:

```gdscript
var input_enabled := true
```

with:

```gdscript
var input_enabled := true
## Points walked in a loop on --autoplay (ZoneData.autoplay_route); set by World.
var route: Array[Vector3] = []
```

4. Replace:

```gdscript
	last_step_m = 0.0
	move_target = null

```

with:

```gdscript
	last_step_m = 0.0
	move_target = null
	_route_index = _nearest_route_point(pos)

```

5. Replace:

```gdscript
	var to_goal := AUTOPLAY_ROUTE[_route_index] - global_position
	to_goal.y = 0.0
	if to_goal.length() < ROUTE_REACHED:
		_route_index = (_route_index + 1) % AUTOPLAY_ROUTE.size()
		return Vector3.ZERO
	return to_goal.normalized()

```

with:

```gdscript
	if route.is_empty():
		return Vector3.ZERO
	var to_goal := route[_route_index] - global_position
	to_goal.y = 0.0
	if to_goal.length() < ROUTE_REACHED:
		_route_index = (_route_index + 1) % route.size()
		return Vector3.ZERO
	return to_goal.normalized()


## The route point to walk to first after being placed at pos: the nearest one.
func _nearest_route_point(pos: Vector3) -> int:
	var best := 0
	for i in route.size():
		if pos.distance_to(route[i]) < pos.distance_to(route[best]):
			best = i
	return best

```


In `scripts/game/chests.gd`:

1. Replace:

```gdscript
## The treasure chests of the meadow: where each one stands and what it holds (gold, an
## item or a piece of equipment). Two lie next to Player.AUTOPLAY_ROUTE, two off it, all
## away from the path. Pure: open() changes a GameState and returns the message.

## id -> {"pos": Vector3, "yaw": degrees (the lid opens toward -Z turned by yaw), and one
## of "gold": int, "item": Inventory id, "equipment": Equipment id}.
const CHESTS := {
	"pradera_este": {"pos": Vector3(13.1, 0, 12.7), "yaw": 30.0, "gold": 25},
	"pradera_oeste": {"pos": Vector3(-11.1, 0, 1.3), "yaw": -150.0,
		"equipment": Equipment.WOODEN_SHIELD},
	"rocas_oeste": {"pos": Vector3(-25, 0, -9), "yaw": -90.0, "gold": 40},
	"rocas_este": {"pos": Vector3(21.5, 0, -8.5), "yaw": 120.0, "item": Inventory.ETHER},
}
```

with:

```gdscript
## The treasure chests of every zone: where each one stands (zone and position) and what
## it holds (gold, an item or a piece of equipment). In the meadow two lie next to its
## autoplay route and two off it, all away from the path. Pure: open() changes a
## GameState and returns the message.

## id -> {"zone": ZoneData id, "pos": Vector3, "yaw": degrees (the lid opens toward -Z
## turned by yaw), and one of "gold": int, "item": Inventory id, "equipment": Equipment
## id}. Ids are unique across zones (the save lists the opened ones).
const CHESTS := {
	"pradera_este": {"zone": "pradera", "pos": Vector3(13.1, 0, 12.7), "yaw": 30.0, "gold": 25},
	"pradera_oeste": {"zone": "pradera", "pos": Vector3(-11.1, 0, 1.3), "yaw": -150.0,
		"equipment": Equipment.WOODEN_SHIELD},
	"rocas_oeste": {"zone": "pradera", "pos": Vector3(-25, 0, -9), "yaw": -90.0, "gold": 40},
	"rocas_este": {"zone": "pradera", "pos": Vector3(21.5, 0, -8.5), "yaw": 120.0,
		"item": Inventory.ETHER},
}


## The chest ids of zone_id, in CHESTS order.
static func of_zone(zone_id: String) -> Array[String]:
	var ids: Array[String] = []
	for id: String in CHESTS:
		if CHESTS[id].zone == zone_id:
			ids.append(id)
	return ids
```


In `scripts/game/game_state.gd`:

1. Replace:

```gdscript
## inventory, the gold, the equipment and the village quest live here for the whole
## session; battles, shops, chests and dialogue change them in place.
```

with:

```gdscript
## inventory, the gold, the equipment, the village quest and the progress through the
## world live here for the whole session; battles, shops, chests, exits and dialogue
## change them in place.
```

2. Replace:

```gdscript
var opened_chests: Array[String] = []
```

with:

```gdscript
var opened_chests: Array[String] = []
## Progress through the world: flag -> true. A boss sets its enemy id when defeated
## ("rey_slime" lifts the fog of the meadow's north exit); ZoneData exits name the flag
## that opens them.
var world_flags := {}
## Key items carried (Inventory.KEY_ITEMS ids), in the order they were found.
var key_items: Array[String] = []
## ZoneData id of the map the hero is on.
var zone_id := "pradera"
## ZoneData id of the last village visited: the Ala de viaje and a defeat lead to its
## town entry.
var town_zone := "pradera"
```

3. Replace:

```gdscript

## Gold lost on a defeat: half of what is carried, rounded down (gold - lost remains).
```

with:

```gdscript

## Records a defeated boss: its world flag and its key item (once). Returns the key
## item id it gave ("" if none or already carried).
func on_boss_defeated(boss: Combatant) -> String:
	world_flags[boss.id] = true
	if boss.key_item == "" or boss.key_item in key_items:
		return ""
	key_items.append(boss.key_item)
	return boss.key_item


func has_flag(flag: String) -> bool:
	return flag == "" or world_flags.get(flag, false)


## Gold lost on a defeat: half of what is carried, rounded down (gold - lost remains).
```


In `scripts/game/inventory.gd`:

1. Replace:

```gdscript
const START_POTIONS := 3
## name and article (for "una Poción"); effect "hp" (heals value HP), "mp" (restores
## value MP) or "cure" (removes the status named by value); price in gold (Shop sells
## at it and buys back at half); battle / field: usable in battle / from the pause menu.
```

with:

```gdscript
const WING := "wing"
const START_POTIONS := 3
## name and article (for "una Poción"); effect "hp" (heals value HP), "mp" (restores
## value MP), "cure" (removes the status named by value) or "travel" (the Ala de viaje:
## Game takes the hero to the last village visited); price in gold (Shop sells at it and
## buys back at half); battle / field: usable in battle / from the pause menu.
```

2. Replace:

```gdscript
}
## Order of the item lists.
const IDS: Array[String] = [POTION, ETHER, ANTIDOTE]
```

with:

```gdscript
	WING: {"name": "Ala de viaje", "article": "un", "effect": "travel", "value": 0,
		"price": 25, "battle": false, "field": true},
}
## Order of the item lists.
const IDS: Array[String] = [POTION, ETHER, ANTIDOTE, WING]
## Key items (GameState.key_items): never used up, sold or dropped; id -> name.
const KEY_ITEMS := {
	"fragmento_bosque": "Fragmento del amuleto",
}
```

3. Replace:

```gdscript
## int (HP or MP recovered), "status": String (cured), "reason": String (why not)}.
```

with:

```gdscript
## int (HP or MP recovered), "status": String (cured), "reason": String (why not)}. A
## "travel" item only gets used up: the caller does the trip.
```


In `scripts/ui/pause_menu.gd`:

1. Replace:

```gdscript
## Cerrar), Estado (hero stats, gold, spells), Objetos (items usable outside battle),
```

with:

```gdscript
## Cerrar), Estado (hero stats, gold, spells), Objetos (items usable outside battle,
## the Ala de viaje too, and the key items),
```

2. Replace:

```gdscript
signal state_changed
```

with:

```gdscript
signal state_changed
## An Ala de viaje was used (the menu closes): Game takes the hero to the last village.
signal travel_requested
```

3. Replace:

```gdscript
			row.add_child(_label(why, Color(0.6, 0.6, 0.65)))
```

with:

```gdscript
			row.add_child(_label(why, Color(0.6, 0.6, 0.65)))
	for id in _state.key_items:
		any = true
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		_items_box.add_child(row)
		var label := _label(Inventory.KEY_ITEMS[id], TITLE_COLOR)
		label.custom_minimum_size = Vector2(220, 0)
		row.add_child(label)
		row.add_child(_label("Objeto clave", Color(0.6, 0.6, 0.65)))
```

4. Replace:

```gdscript
	if not result.used:
```

with:

```gdscript
	if not result.used:
		return
	if result.effect == "travel":
		close()
		travel_requested.emit()
```


In `scripts/ui/battle_result.gd`:

1. Replace:

```gdscript
	_detail.text = "Volverás al inicio."
	if gold_lost > 0:
		_detail.text = "Pierdes %d G.
Volverás al inicio." % gold_lost
```

with:

```gdscript
	_detail.text = "Volverás al pueblo."
	if gold_lost > 0:
		_detail.text = "Pierdes %d G.
Volverás al pueblo." % gold_lost
```


In `scripts/title/title_screen.gd`:

1. Replace:

```gdscript
	WorldStage.build(_backdrop)
```

with:

```gdscript
	WorldStage.build(_backdrop, ZoneData.by_id("pradera"))
```


- [ ] **Step 11: Import and check**

```powershell
.\tools\godot.cmd --headless --path . --import
foreach ($s in "world/zone_data","world/world_stage","world/encounter_table","world/encounter_meter","world/world","world/vegetation","world/player","battle/battle_stage","battle/battle_scene","game/game","game/game_state","game/save_data","game/chests","game/inventory","ui/pause_menu","ui/battle_result","title/title_screen") { .\tools\godot.cmd --headless --path . --check-only --script "res://scripts/$s.gd" }
```

Expected: no `ERROR` or `WARNING` (the import lists `ZoneData`).

- [ ] **Step 12: The meadow from data**

```powershell
.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 6000 -- --autoplay
Remove-Item "$env:APPDATA\Godot\app_userdata\rpg-turnos\save_autoplay.json" -ErrorAction SilentlyContinue
```

Expected: `Zona: pradera`, `Música: map`, battles with slimes, bats and mushrooms, the chests, the shop, "Una niebla espesa cierra el camino del norte." each time the route touches the north exit; no `ERROR`, at most the Jolt warning. It stops long before the Rey Slime (the forest arrives in Task 3).

- [ ] **Step 13: Frames of the meadow (temporary probe at the project root)**

Create `map_probe.gd`:

```gdscript
extends Node3D
## One-off look at a zone as the map camera sees it, around --at=x,z (Tasks 2 and 3). Not
## committed: delete it after viewing the frames.


func _ready() -> void:
	var zone_id := "pradera"
	var at := Vector3.ZERO
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--zone="):
			zone_id = arg.trim_prefix("--zone=")
		if arg.begins_with("--at="):
			var xz := arg.trim_prefix("--at=").split(",")
			at = Vector3(float(xz[0]), 0, float(xz[1]))
	var world: World = preload("res://scenes/world/world.tscn").instantiate()
	world.zone = ZoneData.by_id(zone_id)
	add_child(world)
	world.set_boss_present(true)
	world.place_player(at)
	world.set_active(false)
	world.visible = true
	var cam := Camera3D.new()
	cam.fov = 50.0
	add_child(cam)
	cam.position = at + Vector3(0, 13, 9)
	cam.look_at(at, Vector3.UP)
	cam.current = true
```

Create `map_probe.tscn`:

```ini
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://map_probe.gd" id="1"]

[node name="MapProbe" type="Node3D"]
script = ExtResource("1")
```

```powershell
$dir = "$env:TEMP\meadow"; New-Item -ItemType Directory -Force $dir | Out-Null
.\tools\godot.cmd --path . res://map_probe.tscn --write-movie "$dir\f.png" --fixed-fps 10 --quit-after 4 -- --zone=pradera --at=0,-24
.\tools\godot.cmd --path . res://map_probe.tscn --write-movie "$dir\g.png" --fixed-fps 10 --quit-after 4 -- --zone=pradera --at=0,10
```

Look at `f00000003.png`: Villaclaro as in phase 4 (two red houses, the well, the old woman, the merchant, the innkeeper, the Rey Slime) and behind the Rey Slime a dark wooden arch with the sign "Al bosque" above its beam and a bank of white fog in it. `g00000003.png`: the meadow, grass, path and trees as in phase 4. Keep the probe for Task 3; delete the frames:

```powershell
Remove-Item -Recurse $dir
```

- [ ] **Step 14: Version 3 saves still load (temporary probe at the project root)**

Create `save_probe.gd`:

```gdscript
extends SceneTree
## One-off check of the save migration (Task 2). Not committed: delete it after reading
## the output. A version 3 save (phase 4, quest done) loads as version 4 on the meadow.


func _init() -> void:
	var v3: Dictionary = JSON.parse_string('{"version": 3, "hero": {"level": 5, "experience": 140, "hp": 50, "max_hp": 54, "mp": 18, "max_mp": 18, "attack": 18, "defense": 9, "speed": 12}, "inventory": {"potion": 2}, "quest": {"stage": 4, "kills": 3}, "gold": 120, "loadout": {"weapon": "espada_cobre", "armor": "cota_cuero", "shield": "escudo_madera"}, "bag": ["palo"], "chests": ["pradera_este"], "position": [1.5, -20.0], "play_time": 900.5}')
	var state := GameState.new(load("res://data/hero.tres"))
	var info := SaveData.apply(state, v3)
	print("v3 valid: %s  zone %s  town %s  flags %s  key items %s  pos %s" % [info.valid,
		state.zone_id, state.town_zone, state.world_flags, state.key_items, info.position])
	var v4 := SaveData.from_state(state, info.position, info.play_time)
	print("as v4: %s" % JSON.stringify(v4, "", true))
	var back := GameState.new(load("res://data/hero.tres"))
	var again: Dictionary = JSON.parse_string(JSON.stringify(v4))
	print("v4 valid: %s" % SaveData.apply(back, again).valid)
	again.zone = "luna"
	print("bad zone valid: %s" % SaveData.is_valid(again))
	quit()
```

```powershell
.\tools\godot.cmd --headless --path . --script res://save_probe.gd
Remove-Item save_probe.gd, save_probe.gd.uid -ErrorAction SilentlyContinue
```

Expected:

```
v3 valid: true  zone pradera  town pradera  flags { "rey_slime": true }  key items []  pos (1.5, 0.0, -20.0)
as v4: {"bag":["palo"],"chests":["pradera_este"],"flags":["rey_slime"],"gold":120,"hero":{"attack":18,"defense":9,"experience":140,"hp":50,"level":5,"max_hp":54,"max_mp":18,"mp":18,"speed":12},"inventory":{"potion":2},"key_items":[],"loadout":{"armor":"cota_cuero","shield":"escudo_madera","weapon":"espada_cobre"},"play_time":900.5,"position":[1.5,-20.0],"quest":{"kills":3,"stage":4},"town":"pradera","version":4,"zone":"pradera"}
v4 valid: true
bad zone valid: false
```

- [ ] **Step 15: Save round trip**

```powershell
.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 3000 -- --autoplay --autoplay-save
Remove-Item "$env:APPDATA\Godot\app_userdata\rpg-turnos\save_autoplay.json" -ErrorAction SilentlyContinue
```

Expected: the `Guardado:` and `Cargado:` JSON lines are identical and hold `"version":4`, `"zone":"pradera"`, `"town":"pradera"`, `"flags":[]`, `"key_items":[]`.

- [ ] **Step 16: Commit**

```powershell
git add assets data scripts
git status --short
git commit -m "Build the world from zone data with exits, zone switching and save version 4"
```

`git status --short` must only list `map_probe.gd`, `map_probe.gd.uid` and `map_probe.tscn` as untracked.

---

### Task 3: The forest, its village and the Bruja

**Files:**
- Create: `data/zones/bosque.tres`
- Modify: `scripts/game/chests.gd`, `scripts/game/shop.gd`, `scripts/game/inn.gd`, `scripts/audio/music_library.gd`
- Temporary (never committed): `travel_probe.gd`, `travel_probe.tscn` (and `map_probe.*` from Task 2)

**Interfaces:**
- Consumes: everything from Tasks 1 and 2.
- Produces: zone `bosque`; `Shop.BOSQUE`, `Inn.BOSQUE`; chests `bosque_claro_sur`, `bosque_claro_este`, `bosque_claro_oeste`; `MusicLibrary.FOREST`.

- [ ] **Step 1: Create `data/zones/bosque.tres`**

```ini
[gd_resource type="Resource" script_class="ZoneData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/world/zone_data.gd" id="1_zone"]

[resource]
script = ExtResource("1_zone")
id = "bosque"
display_name = "el bosque"
number = 2
half_size = Vector2(30, 40)
outer_margin = 6.0
ground_color = Color(0.06, 0.17, 0.04, 1)
has_grass = true
grass_tips = PackedColorArray(0.16, 0.42, 0.1, 1, 0.3, 0.55, 0.14, 1)
grass_seed = 17
hills = [[Vector3(-42, -5, -50), Vector3(22, 12, 22)], [Vector3(0, -6, -64), Vector3(30, 12, 20)], [Vector3(42, -5, -50), Vector3(22, 11, 22)], [Vector3(54, -6, 0), Vector3(20, 11, 34)], [Vector3(42, -5, 50), Vector3(22, 10, 22)], [Vector3(0, -6, 64), Vector3(30, 10, 20)], [Vector3(-42, -5, 50), Vector3(22, 11, 22)], [Vector3(-54, -6, 0), Vector3(20, 10, 34)]]
path_points = Array[Vector3]([Vector3(0, 0, 35), Vector3(-3, 0, 24), Vector3(-10, 0, 12), Vector3(-12, 0, 2), Vector3(-8, 0, -8), Vector3(2, 0, -18), Vector3(0, 0, -32)])
path_half_width = 1.5
safe_discs = [[Vector3(0, 0, 35), 4.0], [Vector3(-12, 0, 2), 10.0], [Vector3(0, 0, -32), 6.0]]
village_name = "la aldea del bosque"
village_pos = Vector3(-12, 0, 2)
village_radius = 10.0
buildings = [[Vector3(-4.5, 0, 2), -90.0, "market_green"], [Vector3(-17.73, 0, 6.02), 125.0, "tavern_green"], [Vector3(-18.76, 0, 0.19), 75.0, "house_A_green"], [Vector3(-15.5, 0, -4.06), 30.0, "house_B_green"], [Vector3(-5.68, 0, -3.69), -48.0, "house_A_green"], [Vector3(-14.25, 0, -0.68), 0.0, "well_green"]]
rocks = [[Vector3(-22, 0, 28), 4, 9.0, 30.0], [Vector3(22, 0, 32), 2, 9.0, 100.0], [Vector3(24, 0, -30), 3, 10.0, 200.0], [Vector3(-24, 0, 10), 1, 8.0, 50.0], [Vector3(8, 0, -6), 0, 7.0, 140.0]]
tree_seed = 41
tree_tries = 1800
tree_center_chance = 0.45
tree_rise_inset = 15.0
tree_clump_inset = 3.0
tree_spacing = 3.0
tree_scale = Vector2(3.6, 4.6)
tree_models = Array[String](["tree_A", "tree_B"])
clump_model = "trees_B"
glades = [[Vector3(16, 0, 20), 6.0], [Vector3(17, 0, -14), 6.0], [Vector3(-19, 0, -22), 6.0]]
bush_seed = 43
bush_tries = 300
entries = {
"aldea": [Vector3(-10.4, 0, 10.5), 0.0],
"sur": [Vector3(0, 0, 35.5), 0.0]
}
start_entry = "sur"
town_entry = "aldea"
exits = [{
"entry": "norte",
"id": "sur",
"label": "A la pradera",
"lock": "",
"lock_text": "",
"pos": Vector3(0, 0, 38.6),
"to": "pradera",
"yaw": 180.0
}]
npcs = [{
"id": "bosque",
"kind": "shop",
"look": "MERCHANT",
"name": "Mercader",
"pos": Vector3(-8.2, 0, 2),
"yaw": 180.0
}, {
"id": "bosque",
"kind": "inn",
"look": "INNKEEPER",
"name": "Posadera",
"pos": Vector3(-14.95, 0, 4.06),
"yaw": 180.0
}, {
"after_flag": "bruja",
"kind": "npc",
"lines": ["Una bruja vive en el claro del norte del bosque.", "Desde que llegó, los lobos y las plantas atacan a cualquiera.", "Si vas a por ella, prepárate bien en la tienda."],
"lines_after": ["¡Has vencido a la bruja! El bosque vuelve a estar en calma.", "Dicen que la niebla sale de una vieja mina, más al norte."],
"look": "VILLAGER",
"name": "Leñadora",
"pos": Vector3(-10.46, 0, -2.23),
"yaw": 180.0
}]
boss_id = "bruja"
boss_pos = Vector3(0, 0, -34)
formations = [["lobo"], ["duende"], ["planta"], ["lobo"], ["lobo", "duende"], ["duende", "planta"]]
start_formations = [["lobo"], ["duende"], ["planta"]]
start_pos = Vector3(0, 0, 35)
start_radius = 18.0
encounter_grace = 9.0
encounter_chance = 0.01
music = "forest"
village_music = "village"
sky_top = Color(0.28, 0.45, 0.75, 1)
haze = Color(0.66, 0.76, 0.66, 1)
fog_density = 0.01
sun_color = Color(0.95, 0.92, 0.78, 1)
sun_energy = 0.5
backdrop = "bosque"
autoplay_route = Array[Vector3]([Vector3(6, 0, 30), Vector3(15.8, 0, 19.8), Vector3(8, 0, 8), Vector3(-3, 0, 10.5), Vector3(-8.9, 0, 3.9), Vector3(-13.4, 0, 4), Vector3(-11.6, 0, -1.8), Vector3(-18.8, 0, -22.2), Vector3(-6, 0, -26), Vector3(0, 0, -32.6), Vector3(8, 0, -24), Vector3(17, 0, -14), Vector3(14, 0, 0), Vector3(12, 0, 14), Vector3(2, 0, 26)])
autoplay_boss_level = 9
```

- [ ] **Step 2: Edit the chests, the shop, the inn and the music**

In `scripts/game/chests.gd`:

1. Replace:

```gdscript
## autoplay route and two off it, all away from the path. Pure: open() changes a
## GameState and returns the message.
```

with:

```gdscript
## autoplay route and two off it; the three of the forest stand in its glades, next to
## its route. All away from the paths. Pure: open() changes a GameState and returns the
## message.
```

2. Replace:

```gdscript
		"item": Inventory.ETHER},
```

with:

```gdscript
		"item": Inventory.ETHER},
	"bosque_claro_sur": {"zone": "bosque", "pos": Vector3(17, 0, 21), "yaw": 40.0, "gold": 50},
	"bosque_claro_este": {"zone": "bosque", "pos": Vector3(18, 0, -15), "yaw": 130.0,
		"gold": 50},
	"bosque_claro_oeste": {"zone": "bosque", "pos": Vector3(-20, 0, -23), "yaw": -60.0,
		"item": Inventory.WING},
```


In `scripts/game/shop.gd`:

1. Replace:

```gdscript
## shop id -> keeper's name, equipment and items (Inventory ids) on sale, in list order.
## Zone 1 sells no Éter (it comes with the zone 2 shop).
```

with:

```gdscript
const BOSQUE := "bosque"
## shop id -> keeper's name, equipment and items (Inventory ids) on sale, in list order.
## Zone 1 sells no Éter (it comes with the zone 2 shop, with the Ala de viaje).
```

2. Replace:

```gdscript
		"items": [Inventory.POTION, Inventory.ANTIDOTE],
```

with:

```gdscript
		"items": [Inventory.POTION, Inventory.ANTIDOTE],
	},
	BOSQUE: {
		"keeper": "Mercader",
		"equipment": ["espada_hierro", "cota_malla", "escudo_hierro"],
		"items": [Inventory.POTION, Inventory.ANTIDOTE, Inventory.ETHER, Inventory.WING],
```


In `scripts/game/inn.gd`:

1. Replace:

```gdscript
## inn id -> keeper's name and price of a night in gold.
const INNS := {
	VILLACLARO: {"keeper": "Posadero", "price": 5},
```

with:

```gdscript
const BOSQUE := "bosque"
## inn id -> keeper's name and price of a night in gold.
const INNS := {
	VILLACLARO: {"keeper": "Posadero", "price": 5},
	BOSQUE: {"keeper": "Posadera", "price": 15},
```


In `scripts/audio/music_library.gd`:

1. Replace:

```gdscript
const VILLAGE := "village"
```

with:

```gdscript
const VILLAGE := "village"
const FOREST := "forest"
```

2. Replace:

```gdscript
const IDS: Array[String] = [TITLE, MAP, VILLAGE, BATTLE, BOSS, VICTORY, DEFEAT]
```

with:

```gdscript
const IDS: Array[String] = [TITLE, MAP, VILLAGE, FOREST, BATTLE, BOSS, VICTORY, DEFEAT]
```

3. Replace:

```gdscript
		"drums": ["k/4 h/4 h/4"],
```

with:

```gdscript
		"drums": ["k/4 h/4 h/4"],
	},
	# The forest map: slower, in E minor, with a thin lead.
	FOREST: {
		"bpm": 112, "loop": true, "duty": 0.25,
		"lead": [
			"E5/4 G5/4 B5/6 A5/2", "G5/4 F#5/4 E5/8", "D5/4 F#5/4 A5/6 G5/2", "F#5/4 D5/4 B4/8",
			"C5/4 E5/4 G5/4 C6/4", "B5/6 A5/2 G5/4 E5/4", "F#5/4 A5/4 G5/4 F#5/4", "E5/12 r/4",
		],
		"bass": [
			"E2/4 B2/4 E3/4 B2/4", "E2/4 B2/4 E3/4 B2/4", "D2/4 A2/4 D3/4 A2/4",
			"B1/4 F#2/4 B2/4 F#2/4", "C2/4 G2/4 C3/4 G2/4", "G1/4 D2/4 G2/4 D2/4",
			"D2/4 A2/4 B1/4 F#2/4", "E2/8 B1/4 E2/4",
		],
		"drums": ["k/4 h/4 h/2 h/2 s/4"],
```


- [ ] **Step 3: Import and check**

```powershell
.\tools\godot.cmd --headless --path . --import
foreach ($s in "game/chests","game/shop","game/inn","audio/music_library","world/world","game/game") { .\tools\godot.cmd --headless --path . --check-only --script "res://scripts/$s.gd" }
```

Expected: no `ERROR` or `WARNING`.

- [ ] **Step 4: The forest on autoplay, up to the Bruja**

```powershell
.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 40000 -- --autoplay --autoplay-zone=bosque > forest_run.txt
Select-String -Path forest_run.txt -Pattern "ERROR","SCRIPT ERROR","Zona","Encuentras","Bruja del bosque te cierra","Curar","Fragmento","sube al nivel","Has vuelto","Leñadora"
Remove-Item forest_run.txt
Remove-Item "$env:APPDATA\Godot\app_userdata\rpg-turnos\save_autoplay.json" -ErrorAction SilentlyContinue
```

Expected, in this order (counts and gold vary with the random rolls): `Zona de inicio: bosque (Nv 5)`, `Zona: bosque`, `¡Encuentras 50 monedas de oro!` (twice), the Espada de hierro bought, the Leñadora's three lines once, the Cota de malla and Escudo de hierro bought over the next loops, `¡Héroe sube al nivel 6!` … `nivel 9!`, nights at the Posadera only below half HP, `¡La Bruja del bosque te cierra el paso!`, `¡Bruja del bosque lanza Curar!` / `¡Bruja del bosque recupera 40 PV!` once, `¡Bruja del bosque ha sido derrotada!`, `Consigues 200 monedas de oro.`, `¡Consigues un Fragmento del amuleto!`; no `ERROR` and at most the Jolt warning. In the reference run the hero reached Lv 9 after 19 won battles (4 fled, 1 lost: "Has vuelto a la aldea del bosque.") and won the Bruja on the first try.

- [ ] **Step 5: The Ala de viaje and the exits through Game (temporary probe)**

Create `travel_probe.gd`:

```gdscript
extends Node
## One-off check of the Ala de viaje and of an exit (Task 3). Not committed: delete it
## after reading the output. Runs a Game started with --autoplay-zone=bosque.


func _ready() -> void:
	var game: Game = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	await get_tree().create_timer(1.0).timeout
	game.state.inventory.add(Inventory.WING)
	var used := game.state.use_item(Inventory.WING)
	print("Ala usada: %s (quedan %d)" % [used.effect, game.state.inventory.count(Inventory.WING)])
	await game._on_travel_requested()
	print("Tras el Ala: zona %s en %s, pueblo %s" % [game.state.zone_id,
		game._world.player_position(), game.state.town_zone])
	game._on_exit("bosque", "sur")
	await get_tree().create_timer(2.0).timeout
	print("Tras la salida: zona %s" % game.state.zone_id)
	get_tree().quit()
```

Create `travel_probe.tscn`:

```ini
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://travel_probe.gd" id="1"]

[node name="TravelProbe" type="Node"]
script = ExtResource("1")
```

```powershell
.\tools\godot.cmd --headless --path . res://travel_probe.tscn --fixed-fps 10 --quit-after 400 -- --autoplay --autoplay-zone=bosque
Remove-Item travel_probe.gd, travel_probe.gd.uid, travel_probe.tscn -ErrorAction SilentlyContinue
Remove-Item "$env:APPDATA\Godot\app_userdata\rpg-turnos\save_autoplay.json" -ErrorAction SilentlyContinue
```

Expected (the position moves a little: autoplay walks on): `Ala usada: travel (quedan 0)`, `Zona: pradera`, `Vuelas a Villaclaro.`, `Tras el Ala: zona pradera en (0.0…, 0.0, -15.…), pueblo pradera` (the forest village was never entered, so Villaclaro is the last village), `Zona: bosque`, `Tras la salida: zona bosque`.

- [ ] **Step 6: The whole game so far, from a new game**

```powershell
.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 50000 -- --autoplay > full_run.txt
Select-String -Path full_run.txt -Pattern "ERROR","SCRIPT ERROR","Zona:","nivel 5!","Rey Slime te cierra","salvo","Fragmento"
Remove-Item full_run.txt
Remove-Item "$env:APPDATA\Godot\app_userdata\rpg-turnos\save_autoplay.json" -ErrorAction SilentlyContinue
```

Expected: `Zona: pradera`, `¡Héroe sube al nivel 5!`, `¡El Rey Slime te cierra el paso!`, `¡Villaclaro está a salvo! La niebla del norte se disipa...`, `Zona: bosque` right after (the route takes the north exit), and later `¡Consigues un Fragmento del amuleto!`; no `ERROR`. (Reference run: the Rey Slime at line ~530 of the output, the fragment at ~1220, 67 battles won in 50000 frames.)

- [ ] **Step 7: Save round trip in the forest**

```powershell
.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 3000 -- --autoplay --autoplay-save --autoplay-zone=bosque
Remove-Item "$env:APPDATA\Godot\app_userdata\rpg-turnos\save_autoplay.json" -ErrorAction SilentlyContinue
```

Expected: identical `Guardado:` and `Cargado:` lines with `"zone":"bosque"` and `"flags":["rey_slime"]`; the loaded game prints `Zona: bosque`.

- [ ] **Step 8: Frames of the forest**

```powershell
$dir = "$env:TEMP\forest"; New-Item -ItemType Directory -Force $dir | Out-Null
.\tools\godot.cmd --path . res://map_probe.tscn --write-movie "$dir\a.png" --fixed-fps 10 --quit-after 4 -- --zone=bosque --at=-11,3
.\tools\godot.cmd --path . res://map_probe.tscn --write-movie "$dir\b.png" --fixed-fps 10 --quit-after 4 -- --zone=bosque --at=0,-30
.\tools\godot.cmd --path . res://map_probe.tscn --write-movie "$dir\c.png" --fixed-fps 10 --quit-after 4 -- --zone=bosque --at=0,34
.\tools\godot.cmd --path . --write-movie "$dir\d.png" --fixed-fps 10 --quit-after 600 -- --autoplay --autoplay-zone=bosque
```

Look at `a00000003.png`: the forest village, a dirt clearing with the tavern (barrel shape) on the left, the market stall on the right, three green houses and the well, the Mercader, the Posadera and the Leñadora. `b00000003.png`: the witch's clearing among dense trees, the purple Bruja at its north end. `c00000003.png`: the south arch with "A la pradera" and no fog. Among the `d*.png`: the forest map with its darker grass and the hero walking between trees, and a battle on the forest backdrop (trees close around, darker ground) against a wolf, a goblin or a plant. Then:

```powershell
Remove-Item -Recurse $dir
Remove-Item map_probe.gd, map_probe.gd.uid, map_probe.tscn -ErrorAction SilentlyContinue
Remove-Item "$env:APPDATA\Godot\app_userdata\rpg-turnos\save_autoplay.json" -ErrorAction SilentlyContinue
```

- [ ] **Step 9: By hand**

Run `.\tools\godot.cmd --path .`, start a new game, and check with the keyboard and the mouse: the north arch shows its fog and "Una niebla espesa cierra el camino del norte." when touched; after beating the Rey Slime the fog is gone and the arch leads to the forest (fade to black); walking back south through "A la pradera" lands next to Villaclaro; the forest shop sells the zone 2 gear and the Ala de viaje; the Posadera charges 15 G; the Leñadora's lines change after the Bruja; the Objetos page lists the Ala de viaje (Usar: fade to the last village) and, after the Bruja, "Fragmento del amuleto · Objeto clave"; Continuar reloads the forest at the saved spot.

- [ ] **Step 10: Commit**

```powershell
git add data scripts
git status --short
git commit -m "Add the forest with its village, shop, inn, chests, music and the witch"
```

`git status --short` must show nothing untracked.

---

### Task 4: Documentation, final checks and web export

**Files:**
- Modify: `CLAUDE.md`, `docs/boost/specs/ideas-sueltas.md`, `assets/CREDITS.md`

- [ ] **Step 1: Update the docs**

In `CLAUDE.md`:

1. Replace:

```markdown
- `scenes/game/game.tscn` + `scripts/game/game.gd` (`Game`) — one play session, created by `TitleScreen` (run on its own it makes its own `AudioDirector` and default options). Owns a `GameState` and the `World`. On `World.encounter_triggered(boss)` it fades to black, `World.set_active(false)`, instantiates a `BattleScene` with `setup(state.hero, enemies, state.inventory)`, `set_equipment(weapon, shield)` and `gold_lost = state.defeat_gold_loss()` on top (`enemies` from `EncounterTable.pick(ZONE, player position, rng)`, or `[rey_slime.tres]`), awaits `finished(outcome)` (`BattleEngine.State`), frees it and turns the map back on (victory: `state.gold += engine.gold_won` and `quest.on_victory(id)` for every enemy, a beaten boss leaves the map with "¡Villaclaro está a salvo!"; fled: nothing; defeat: loses half the gold, `heal_full()` and `World.respawn()`). On `World.shop_requested(shop_id)` it freezes the map and awaits `ShopWindow.run(shop_id)` (on autoplay only when `Shop.autoplay_picks()` is not empty), then autosaves if anything changed; on `World.inn_requested(inn_id)` it asks `ShopWindow.ask()` and on Sí calls `Inn.stay()` (fade to black, `INN_NIGHT_TIME` 0.8 s, full HP and MP, autosave; on autoplay only when hurt and with the price); on `World.chest_opened(id)` it calls `Chests.open(state, id)`, opens the lid (`World.set_chest_open()`), shows what was found and saves without a notice. `_refresh_status()` also shows the weapon and shield on the map hero (`World.set_hero_equipment()`) and, on autoplay, prints `Oro N G · Equipo: ... · ATK n DEF n` whenever it changes. `_update_boss()` shows the Rey Slime while `quest.boss_available()` (on autoplay only from `AUTOPLAY_BOSS_LEVEL` 5). On `World.talk_requested` it takes the lines and potions from `quest.talk()`, heals, and plays them with `World.show_dialogue()`, then shows the boss if `quest.boss_available()`. The map is never freed, so position, camera and encounter grace survive battles. Music: map, village (`World.village_changed`), battle or boss (the battle plays victory / defeat). Autosaves (`SaveData.from_state()` → `SaveStore.save_game()`) after each talk and each won battle ("Partida guardada.", except after the boss, which shows the safe-village notice instead) and silently after a defeat (so the gold lost sticks), never in battle; a save is loaded with `SaveData.apply()` and `World.place_player()`; counts `play_time` (stops while paused). Owns the `PauseMenu` (`available` only on the map with nothing else going on) and answers its `save_requested` / `title_requested` (the latter sets a `_leaving` guard, marks the game busy, hides the menu and ignores input, so the frozen map can't walk or roll an encounter during the fade); emits `quit_to_title`. `--autoplay --autoplay-save` prints `Guardado: <json>` / `Cargado: <json>`; `--autoplay --autoplay-menu` tours the pause menu 1 s into the map.
- `scripts/game/game_state.gd` (`GameState`, `RefCounted`) — session state kept in memory: the hero `Combatant` (a duplicate of `data/hero.tres` that lives the whole session; battles change its HP, MP, EXP and level in place), `inventory: Inventory` (starts with 3 potions), `quest: Quest`, `gold` (`START_GOLD` 50), `loadout: Loadout`, `bag_equipment` (Equipment ids carried but not worn), `opened_chests` (Chests ids), `heal_full()` (HP and MP), `use_item(id)` (outside battle, `Inventory.use()`), `refresh_equipment()` (copies the loadout bonuses into `hero.equip_attack` / `equip_defense`), `equip(id)` (from the bag; what it replaces goes to the bag), `unequip(slot)`, `defeat_gold_loss()` (half the gold, rounded down). The hero gets its own `skills` array, so learning a spell never touches `hero.tres`.
- `scripts/game/equipment.gd` (`Equipment`, `RefCounted`) — the `EQUIPMENT` catalog (id → name, article, slot `WEAPON` / `ARMOR` / `SHIELD`, bonus (ATK for weapons, DEF for the rest), price, zone, mesh): Palo +2 and Ropa +2 (zone 0, the starting gear, worth nothing), zone 1 Espada de cobre +6 · 40 G, Cota de cuero +5 · 30 G, Escudo de madera +3 · 25 G, and zones 2-4 already listed for their shops; `display_name()`, `article()`, `pronoun()`, `slot()`, `bonus()`, `price()`, `mesh()` (a `Knight.glb` handslot mesh, `STICK_MESH` or ""), `stat_name()`, `of_zone()`, `SLOTS`, `SLOT_NAMES`.
- `scripts/game/loadout.gd` (`Loadout`, `RefCounted`) — what the hero wears, slot → id (Palo, Ropa, no shield at first): `worn(slot)`, `is_worn(id)`, `equip(id)` (returns what it took off), `unequip(slot)`, `attack_bonus()`, `defense_bonus()`, `to_dict()`, `set_slots()`.
- `scripts/game/shop.gd` (`Shop`, `RefCounted`) — pure shop rules: `SHOPS` (Villaclaro: the zone 1 gear, Poción and Antídoto; no Éter until zone 2), `stock()`, `price()`, `sell_price()` (half, rounded down), `buy_problem()` / `can_buy()` / `buy()`, `sell_list()` / `sell_count()` / `sell_problem()` ("Lo llevas puesto", "No vale nada") / `sell()` (each returns `{ok, text}`), `compare(state, id)` (`{stat, worn, bonus, diff}` against the piece worn in that slot), `autoplay_picks()` (upgrades first, then potions up to 3).
- `scripts/game/inn.gd` (`Inn`, `RefCounted`) — inn rules: `INNS` (Villaclaro: Posadero, 5 G; the model for the later zones' 15 / 30 / 50 G inns, since the old woman already heals for free here), `keeper()`, `price()`, `offer()`, `stay(state, id)` → `{ok, text}` (pays and heals).
- `scripts/game/chests.gd` (`Chests`, `RefCounted`) — the 4 chests of the meadow (`CHESTS`: position, yaw and 25 G, Escudo de madera, 40 G or an Éter; the first two lie next to `Player.AUTOPLAY_ROUTE`); `open(state, id)` → `{opened, text}` (equipment goes on at once if its slot is empty, else into the bag).
- `scripts/game/quest.gd` (`Quest`, `RefCounted`) — the village quest: stages `OFFER → HUNT → REPORT → BOSS → DONE`; `on_victory(enemy_id)` (called for every enemy of a won battle) counts slimes during `HUNT` and finishes on the boss; `talk()` returns the old woman's lines and the potions to give (2 when reporting) and moves the stage on; `boss_available()`, `status_text()`.
- `scripts/game/inventory.gd` (`Inventory`, `RefCounted`) — items as `id → count`: `count()`, `add()`, `take()`, `to_dict()`, `set_items()`. `ITEMS` table (name, article, effect `hp` / `mp` / `cure`, value, price, usable in `battle` / `field`) in `IDS` order: `POTION` (30 PV, 8 G), `ETHER` (15 PM, 30 G), `ANTIDOTE` (cures poison, 10 G, battle only); `Shop` sells at `price` and buys back at half. `problem(id, combatant, in_battle)` says why it can't be used now ("" if it can: "PV al máximo", "Solo en combate", ...); `use(id, combatant, in_battle)` → `{used, effect, amount, status, reason}`, shared by `BattleEngine` and the pause menu; `display_name()`, `article()`.
- `scripts/game/leveling.gd` (`Leveling`, `RefCounted`) — fixed `EXP_TABLE` up to `MAX_LEVEL` 20 (12, 35, 62, 96, 180, ... 3600) and fixed `GAINS` per level (PV +6, PM +3, ATK +2, DEF +1, VEL +1; current HP/MP rise with their max, no full heal); `apply(hero)` returns `LEVEL_UP` events, each followed by a `LEARN` event when the hero's `learn` table teaches a spell at that level; `sync_skills(hero)` (after loading), `exp_for_next(level)`.
- `scripts/game/game_options.gd` (`GameOptions`, `RefCounted`) — music and effects volume (0..1, defaults 0.7 / 0.8) and `text_speed` (`SLOW` / `NORMAL` / `FAST`, `char_time()` 0.05 / 0.025 / 0.008 s per character); `to_dict()`, `from_dict()`.
- `scripts/game/save_data.gd` (`SaveData`, `RefCounted`) — pure: `from_state(state, player_pos, play_time)` → `Dictionary` (`version` 3, hero level / EXP / HP / MP / base stats, inventory, quest stage and kills, gold, `loadout` (slot → id), `bag`, opened `chests`, position `[x, z]`, play time; version 2 saves still load with the starting gear, an empty bag and closed chests; version 1 saves are refused); `apply(state, data)` → `{valid, position, play_time}` (state untouched when not valid; JSON numbers come back as floats; spells come back with `Leveling.sync_skills()`); `is_valid(data)`.
- `scripts/game/save_store.gd` (`SaveStore`, `RefCounted`) — JSON files: `user://save.json` (`user://save_autoplay.json` on `--autoplay` runs) and `user://options.json`; `has_save()`, `save_game(data)`, `load_game()` (empty if missing or broken), `save_options(options)`, `load_options()`. On desktop `user://` is `%APPDATA%\Godot\app_userdata\rpg-turnos\`; on the web it is IndexedDB.
- `scenes/world/world.tscn` + `scripts/world/world.gd` (`World`) — world map: `WorldStage`, the old woman, the merchant (`MERCHANT`), the innkeeper (`INNKEEPER`) and the Rey Slime (`BattleActor`s on cylinder colliders), the 4 chests (`build_chest()`: wooden box, gold band and lock, lid on a hinge; `set_chest_open(id, open, instant)`), `Player`, `FollowCamera`, status window (name and level, PV, PM, EXP / next level, potions, "Oro N G", quest line), click or tap on the ground (held and dragged too) walks there with a ring marker, a prompt for the nearest thing in reach ("Enter o toca: hablar" within 2.5 m of the old woman, "... comprar" of the merchant, "... hablar" of the innkeeper, "... abrir" within 1.8 m of a closed chest; a click or tap on one walks there and uses it on arrival), `DialogueBox`, encounters through `EncounterMeter` (only off the path). Emits `talk_requested`, `shop_requested(shop_id)`, `inn_requested(inn_id)`, `chest_opened(chest_id)`, `village_changed(inside)` (within `CLEARING_RADIUS` of `CLEARING_POS`) and `encounter_triggered(boss)` (random encounter, or walking within 2.5 m of the boss while `set_boss_present(true)`), and freezes the player until `set_active(true)`; `respawn()`, `place_player(pos)`, `player_position()`, `in_village()`, `set_audio(audio)` (footstep every 1.6 m, encounter and dialogue sounds), `refresh_status(hero, potions, gold, quest_text)`, `set_hero_equipment(weapon, shield)`, `show_notice(text)`, `await show_dialogue(speaker, lines)`, `await freeze(on)` (no walking or prompts while a window is open). On autoplay it uses whatever comes in reach (talk, shop, chest) once per approach. Run on its own it prints each encounter, shop, inn and chest and answers talks with one line.
- `scripts/ui/dialogue_box.gd` (`DialogueBox`, `Control`) — bottom dialogue window with speaker name; `await say(speaker, lines)` advances on Enter / Space / click (autoplay: every 0.8 s, printed); `set_audio()` plays the dialogue sound when it opens.
- `scripts/world/world_stage.gd` (`WorldStage`) — static builder of the 60 × 60 m field of tall grass (`Vegetation`; `is_grass_free()`, `build()` returns the grass material, which `World` pushes away from the player each frame): dirt path from `SPAWN_POS` (south) to the village of Villaclaro in the clearing at `CLEARING_POS` (north: KayKit houses `building_home_A_red` / `B_red` and `building_well_red` at scale 3.5 with box colliders fitted to their meshes; `NPC_POS`, `MERCHANT_POS`, `INNKEEPER_POS`, `BOSS_POS`), KayKit rocks with box colliders (`ROCKS`: position, model, scale, yaw), trees scattered with seed 23 (denser toward the edges, clumps past 27 m, kept off the path, `Player.AUTOPLAY_ROUTE`, rocks and chests, cylinder colliders inside the walls) and bushes with seed 31 (no collider; grass and bushes keep off the chests too), the trees and bushes each drawn as a `MultiMesh` (houses, well and rocks are individual model instances); invisible walls, hills outside; `is_on_path(pos, margin := 0.0)` (path, clearing and spawn area are safe), `add_cylinder_shape()`.
- `scenes/world/player.tscn` + `scripts/world/player.gd` (`Player`, `CharacterBody3D`) — WASD / arrows in screen axes (up = −Z), or `move_to(point)` (click / tap; keys cancel it, gives up when stuck; `move_target`), 5 m/s, smooth turn, walk / idle animation through `BattleActor.set_walking()`; model is a `BattleActor` (`HERO`; `set_equipment(weapon, shield)`); `last_step_m` feeds the encounter meter; `place(pos, yaw)`. `--autoplay` walks `AUTOPLAY_ROUTE` in a loop, through the village past the old woman, the merchant, the boss spot and the innkeeper, and past two chests.
- `scripts/world/follow_camera.gd` (`FollowCamera`) — top-down follow: fixed 55° pitch from the south (looks north, never turns), 14 m away, mouse wheel zooms 9–20 m, `snap()`.
- `scripts/world/vegetation.gd` (`Vegetation`) + `shaders/grass.gdshader` — static builder of tall grass and flowers: `build(root, area, is_free, seed)` fills an XZ rect with jittered tufts in 12 × 12 m `MultiMesh` chunks plus flower heads, returns the shared grass material (wind sway); `set_pusher(material, pos)` bends the grass away from a point.
- `scripts/world/encounter_meter.gd` (`EncounterMeter`, `RefCounted`) — encounter rule: 15 m grace after `reset()`, then 0.6 % per full meter walked on grass (a battle every ~180 m).
- `scripts/world/encounter_table.gd` (`EncounterTable`, `RefCounted`) — which enemies come: `ZONES` (zone 1: `[Slime]`, `[Slime]`, `[Murciélago]`, `[Seta]`, `[Slime, Slime]`, `[Slime, Murciélago]`, same weight) and `START_FORMATIONS` (`[Slime]`, `[Slime, Slime]`) within `START_RADIUS` 20 m of `WorldStage.SPAWN_POS`; `pick(zone, pos, rng)`, `near_start(pos)`.
- `scenes/battle/battle_scene.tscn` + `scripts/battle/battle_scene.gd` (`BattleScene`) — one battle against one or two enemies: call `setup(hero, enemies: Array[Combatant], inventory)`, `set_audio(audio)`, `set_equipment(weapon, shield)` and set `char_time` and `gold_lost` (said as "Pierdes N monedas de oro." on a defeat) before adding it (hero and inventory used as is, enemies duplicated, two with the same name become "Slime A" / "Slime B"; without audio it is silent); builds stage (`BattleStage.build`), the hero and one `BattleActor` per enemy (`LOOKS` by data id; a pair stands left and right of `ENEMY_POS`, `PAIR_OFFSET` 1.5 m), camera, the blinking yellow target arrow (`_show_arrow(index)`, from `BattleHud.target_changed`; `_pick_target(screen)` turns clicks into enemies) and a `CanvasLayer` with `BattleHud` and `BattleResult`. Flow: HUD `command_chosen(cmd)` (asleep: `cmd_none()`) → `BattleEngine.resolve_round(cmd)` → `_play_event()` per event → menu again, or result overlay → "Continuar" → `finished(outcome)` (fled: at once). Every message goes through `_say()` (`_the()` / `_ending()` give "el / la" and "-o / -a" from `Combatant.female`). A call for help moves the caller to the left and grows the helper on the right. Effects: hit, crit, miss, fire on spell casts, potion, heal, level up, accept on "Continuar"; music: victory fanfare on the VICTORY event, defeat when the hero falls. `--autoplay`: `BattleAutoplay` picks (shown with `BattleHud.demo()`), flees from every 5th normal battle and defends in the first round of the 2nd, 7th...; prints every message and continues by itself. Run on its own: a poisoned Lv 3 hero with 3 potions and an antidote against a Slime and a Murciélago, quits at the end ("Fin del combate (estado N)").
- `scripts/battle/battle_engine.gd` (`BattleEngine`, `RefCounted`) — pure round rules for the hero against `enemies: Array[Combatant]` (fighters are ints: `BattleEvent.HERO` = −1 or an enemy index). Commands are dictionaries from `cmd_attack(target)`, `cmd_skill(skill, target)`, `cmd_item(id)`, `cmd_defend()`, `cmd_flee()`, `cmd_none()`; `problem(cmd)` (why not: "Faltan PM", "Silencio", item reasons), `can_use(cmd)`, `alive_enemies()`, `has_boss()`, `flee_chance()`. Each enemy picks when its turn comes, from `ai_weights` (`"attack"`, `"stagger"` or a skill id), or calls its `help` once below 50 % HP while fewer than `MAX_ENEMIES` 2 stand. Initiative `speed × randf_range(0.5, 1.5)` (defending or fleeing, the hero goes first); attacks: 5 % miss, 1/16 crit (ignores DEF), damage `base × randf_range(0.875, 1.125)` rounded, minimum 1, where `base = max(1, total ATK − total DEF/2)` (crit: `ATK × 1.5`), may cause the attacker's `attack_status`; spells pay MP: damage `power × the same spread × 1.5 weak / 0.5 resist`, ignoring DEF, no miss or crit, may cause their status; heals restore `power`. Defend halves the damage taken that round (rounded up, min 1). Flee: `clamp(0.5 + (hero VEL − mean enemy VEL) × 0.05, 0.2, 0.95)`; against a boss only `NO_ESCAPE`, no turn passes. Status (`Combatant.status`): poison 8 % max HP at the end of each round; sleep loses the turn, 50 % to wake at the end of each round, damage wakes; silence 3 rounds without spells; all cleared when the battle ends. On victory: `exp_won`, `gold_won`, `Leveling.apply()`, each enemy's `drops` rolls (`drops_won`). Returns `Array[Dictionary]` events built by `BattleEvent` (`scripts/battle/battle_event.gd`); `state` is `ONGOING`, `WON`, `LOST` or `FLED`. Never touches nodes.
- `scripts/battle/battle_autoplay.gd` (`BattleAutoplay`, `RefCounted`) — pure command picker for `--autoplay` and balance checks: below 40 % HP heals (Curar, else potion), with no heal defends below 25 % (never twice in a row); antidote when poisoned, ether when MP can't pay a heal; otherwise aims at the weakest enemy and casts the spell that hurts most (weaknesses count) only when it beats an attack by ×1.5, keeping MP for two heals. `choose(engine)`.
- `scripts/battle/combatant.gd` (`Combatant`, `Resource`) — fighter stats (`id`, `female`, level, HP, MP, base `attack` / `defense` plus hero-only `equip_attack` / `equip_defense` (the loadout bonuses, set by `GameState.refresh_equipment()`; `total_attack()` / `total_defense()`), speed, `skills`, hero-only `learn` (level → Skill), EXP; enemy-only `exp_reward`, `gold_reward`, `ai_weights`, `weak` / `resist` (elements), `drops` (item id → chance), `attack_status` / `attack_status_chance`, `help` (Combatant it calls), `is_boss`); battle-only `status` (status → rounds, −1 until cured). Data in `data/hero.tres`, `data/slime.tres`, `data/bat.tres` (Murciélago), `data/mushroom.tres` (Seta saltarina), `data/rey_slime.tres`.
- `scripts/battle/skill.gd` (`Skill`, `Resource`) — spell data (`id`, `display_name`, `mp_cost`, `power`, `color` of the cast glow and hit ball, `element` `fire` / `ice` / `thunder` / "", `kind` `damage` / `heal` / `status`, `targets` `one` / `all`, `status`, `status_chance`; `needs_target()`); `data/skills/`: `llama`, `curar`, `llamarada`, `rayo`, `curar_mas` (the hero's), `aplastar` (Rey Slime), `esporas` (Seta: sleep 30 %).
- `scenes/battle/battle_actor.tscn` + `scripts/battle/battle_actor.gd` (`BattleActor`) — figure of a fighter or villager built from the `LOOKS` table (`look`: `HERO` / `SLIME` / `VILLAGER` / `KING_SLIME` / `BAT` / `MUSHROOM` / `MERCHANT` / `INNKEEPER`, set before `add_child`), faces -Z. `HERO` is KayKit `Knight.glb` (every hand mesh hidden; `set_equipment(weapon, shield)` shows the `Equipment.mesh()` of each under `handslot_r` / `handslot_l`, plus a wooden stick built in code for the Palo), `VILLAGER` is `Mage.glb`, `MERCHANT` / `INNKEEPER` the same Mage tinted green / orange (`tint`) (scale 0.65, turned 180°, unused props hidden, `AnimationPlayer` at `AnimationPlayer`, roles in `CHARACTER_ANIMS`: `Idle`, `Running_A`, `1H_Melee_Attack_Slice_Diagonal`, `Spellcast_Shoot`, `Hit_A`, `Dodge_Backward`, `Death_A`, `Cheer`); `SLIME` / `KING_SLIME` are faceted `LowPoly` blobs with eyes (king ×1.6 with a gold crown) that bounce while idle; `BAT` hovers at 1.1 m flapping two box wings; `MUSHROOM` is a stem with eyes and a spotted hemisphere cap (×1.4) that bounces. Awaitable `play_attack`, `play_hit(amount, crit, tag)` (flash overlay + floating `Label3D` number, `tag` "¡Débil!" / "¡Resiste!" under it), `play_dodge`, `play_defeat` (characters stay down, the rest fade and hide), `play_cast(color)`, `play_burn(amount, color, tag)`, `play_heal(amount, color)`, `play_status(color, amount)`, `play_appear()`, `play_stagger`, `play_cheer`; `top_height()`; `set_walking(on)` for the map; `reset()`.
- `scripts/battle/battle_stage.gd` (`BattleStage`) — battle backdrop builder (tall grass around the fighters, none where they stand; KayKit rocks and trees and low-poly bushes around them); `build_environment(root)` (procedural sky, ACES tonemap, SSAO, glow, fog, warm sun with shadows), `add_mesh()`, `unit_sphere()`, `add_model(root, scene, pos, scl, yaw_deg)`, `scene_mesh(scene)`, `model_aabb(model)`, `rock_radius(rock)`, `ROCK_SCENES`, `ROCK_RADII` and `TREE_SCENES` are shared with `WorldStage`.
- `scripts/battle/low_poly.gd` (`LowPoly`) — faceted flat-shaded meshes built in code: `blob(profile, segments)` (lathe of a side profile; slimes and bushes), `bush_mesh()`, `add_multimesh(root, mesh, transforms)`.
- `assets/` — only the models in use, copied unchanged from the CC0 KayKit packs kept (git-ignored) in `assets_src/`: `characters/` (Adventurers: `Knight.glb`, `Mage.glb` and their extracted textures) and `medieval/` (Medieval Hexagon: houses, well, rocks, trees, shared `hexagons_medieval.png`); `assets/CREDITS.md` lists packs, author and licence.
```

with:

```markdown
- `scenes/game/game.tscn` + `scripts/game/game.gd` (`Game`) — one play session, created by `TitleScreen` (run on its own it makes its own `AudioDirector` and default options). Owns a `GameState` and the `World` of the current zone: `_switch_zone(zone_id, entry_id)` frees the map and builds `ZoneData.by_id(zone_id)` ("" entry: the zone's start), connects its signals, reopens its chests, passes the world flags and places the boss. On `World.encounter_triggered(boss)` it fades to black, `World.set_active(false)`, instantiates a `BattleScene` with `setup(state.hero, enemies, state.inventory)`, `set_equipment(weapon, shield)`, `gold_lost = state.defeat_gold_loss()` and `zone` on top (`enemies` from `EncounterTable.pick(zone, player position, rng)`, or `[EnemyLibrary.data(zone.boss_id)]`), awaits `finished(outcome)` (`BattleEngine.State`), frees it and turns the map back on (victory: `state.gold += engine.gold_won` and `quest.on_victory(id)` for every enemy; a boss also calls `state.on_boss_defeated()` (world flag + key item) and shows `BOSS_NOTICES` ("¡Villaclaro está a salvo! La niebla del norte se disipa...") or "¡Consigues un Fragmento del amuleto!"; fled: nothing; defeat: loses half the gold, `heal_full()` and goes to the town entry of `state.town_zone` ("Has vuelto a <village>.")). On `World.exit_requested(zone, entry)` it fades, switches zone and autosaves silently; the pause menu's `travel_requested` (Ala de viaje) does the same to the last village ("Vuelas a <village>."); `World.village_changed(true)` makes the zone the last village visited. On `World.shop_requested(shop_id)` it freezes the map and awaits `ShopWindow.run(shop_id)` (on autoplay only when `Shop.autoplay_picks()` is not empty), then autosaves if anything changed; on `World.inn_requested(inn_id)` it asks `ShopWindow.ask()` and on Sí calls `Inn.stay()` (fade to black, `INN_NIGHT_TIME` 0.8 s, full HP and MP, autosave; on autoplay only below `AUTOPLAY_INN_RATIO` 0.5 of max HP and with the price); on `World.chest_opened(id)` it calls `Chests.open(state, id)`, opens the lid (`World.set_chest_open()`), shows what was found and saves without a notice; on `World.npc_requested(i)` it plays `World.npc_lines(i)`. `_refresh_status()` also shows the weapon and shield on the map hero (`World.set_hero_equipment()`) and, on autoplay, prints `Oro N G · Equipo: ... · ATK n DEF n` whenever it changes. `_update_boss()` shows the zone's boss until it is beaten (the Rey Slime only while `quest.boss_available()`; on autoplay only from the zone's `autoplay_boss_level`). On `World.talk_requested` it takes the lines and potions from `quest.talk()`, heals, and plays them with `World.show_dialogue()`, then shows the boss if `quest.boss_available()`. The map stays while battles come and go, so position, camera and encounter grace survive them. Music: the zone's `music` / `village_music` (`World.village_changed`), battle or boss (the battle plays victory / defeat). Autosaves (`SaveData.from_state()` → `SaveStore.save_game()`) after each talk and each won battle ("Partida guardada.", except after a boss, which shows its notice instead) and silently after a defeat (so the gold lost sticks), after a chest and after each change of zone, never in battle; a save is loaded with `SaveData.apply()` (its zone) and `World.place_player()`; counts `play_time` (stops while paused). Owns the `PauseMenu` (`available` only on the map with nothing else going on) and answers its `save_requested` / `title_requested` (the latter sets a `_leaving` guard, marks the game busy, hides the menu and ignores input, so the frozen map can't walk or roll an encounter during the fade) / `travel_requested`; emits `quit_to_title`. `--autoplay --autoplay-save` prints `Guardado: <json>` / `Cargado: <json>`; `--autoplay --autoplay-menu` tours the pause menu 1 s into the map; `--autoplay --autoplay-zone=<id>` starts a new game in that zone with `AUTOPLAY_ZONES` (bosque: Lv 5, 150 G, the zone 1 gear, the Rey Slime beaten).
- `scripts/game/game_state.gd` (`GameState`, `RefCounted`) — session state kept in memory: the hero `Combatant` (a duplicate of `data/hero.tres` that lives the whole session; battles change its HP, MP, EXP and level in place), `inventory: Inventory` (starts with 3 potions), `quest: Quest`, `gold` (`START_GOLD` 50), `loadout: Loadout`, `bag_equipment` (Equipment ids carried but not worn), `opened_chests` (Chests ids), `world_flags` (flag → true; a beaten boss sets its enemy id, which opens the exits locked by it), `key_items` (`Inventory.KEY_ITEMS` ids), `zone_id` (the map the hero is on) and `town_zone` (last village visited; "pradera" at first), `heal_full()` (HP and MP), `use_item(id)` (outside battle, `Inventory.use()`), `refresh_equipment()` (copies the loadout bonuses into `hero.equip_attack` / `equip_defense`), `equip(id)` (from the bag; what it replaces goes to the bag), `unequip(slot)`, `on_boss_defeated(boss)` (flag + key item, returns the item given), `has_flag(flag)` ("" is always set), `defeat_gold_loss()` (half the gold, rounded down). The hero gets its own `skills` array, so learning a spell never touches `hero.tres`.
- `scripts/game/equipment.gd` (`Equipment`, `RefCounted`) — the `EQUIPMENT` catalog (id → name, article, slot `WEAPON` / `ARMOR` / `SHIELD`, bonus (ATK for weapons, DEF for the rest), price, zone, mesh): Palo +2 and Ropa +2 (zone 0, the starting gear, worth nothing), zone 1 Espada de cobre +6 · 40 G, Cota de cuero +5 · 30 G, Escudo de madera +3 · 25 G, and zones 2-4 already listed for their shops; `display_name()`, `article()`, `pronoun()`, `slot()`, `bonus()`, `price()`, `mesh()` (a `Knight.glb` handslot mesh, `STICK_MESH` or ""), `stat_name()`, `of_zone()`, `SLOTS`, `SLOT_NAMES`.
- `scripts/game/loadout.gd` (`Loadout`, `RefCounted`) — what the hero wears, slot → id (Palo, Ropa, no shield at first): `worn(slot)`, `is_worn(id)`, `equip(id)` (returns what it took off), `unequip(slot)`, `attack_bonus()`, `defense_bonus()`, `to_dict()`, `set_slots()`.
- `scripts/game/shop.gd` (`Shop`, `RefCounted`) — pure shop rules: `SHOPS` (Villaclaro: the zone 1 gear, Poción and Antídoto; Bosque: the zone 2 gear, Poción, Antídoto, Éter and Ala de viaje), `stock()`, `price()`, `sell_price()` (half, rounded down), `buy_problem()` / `can_buy()` / `buy()`, `sell_list()` / `sell_count()` / `sell_problem()` ("Lo llevas puesto", "No vale nada") / `sell()` (each returns `{ok, text}`), `compare(state, id)` (`{stat, worn, bonus, diff}` against the piece worn in that slot), `autoplay_picks()` (upgrades first, then potions up to 3).
- `scripts/game/inn.gd` (`Inn`, `RefCounted`) — inn rules: `INNS` (Villaclaro: Posadero, 5 G; Bosque: Posadera, 15 G; the mine and castle will have 30 / 50 G), `keeper()`, `price()`, `offer()`, `stay(state, id)` → `{ok, text}` (pays and heals).
- `scripts/game/chests.gd` (`Chests`, `RefCounted`) — the chests of every zone (`CHESTS`: zone, position, yaw and contents; the meadow's 25 G, Escudo de madera, 40 G and Éter, the first two next to its autoplay route; the forest's 50 G, 50 G and an Ala de viaje in its three glades, next to its route); `of_zone(zone_id)`; `open(state, id)` → `{opened, text}` (equipment goes on at once if its slot is empty, else into the bag).
- `scripts/game/quest.gd` (`Quest`, `RefCounted`) — the village quest: stages `OFFER → HUNT → REPORT → BOSS → DONE`; `on_victory(enemy_id)` (called for every enemy of a won battle) counts slimes during `HUNT` and finishes on the boss; `talk()` returns the old woman's lines and the potions to give (2 when reporting) and moves the stage on; `boss_available()`, `status_text()`.
- `scripts/game/inventory.gd` (`Inventory`, `RefCounted`) — items as `id → count`: `count()`, `add()`, `take()`, `to_dict()`, `set_items()`. `ITEMS` table (name, article, effect `hp` / `mp` / `cure` / `travel`, value, price, usable in `battle` / `field`) in `IDS` order: `POTION` (30 PV, 8 G), `ETHER` (15 PM, 30 G), `ANTIDOTE` (cures poison, 10 G, battle only), `WING` (Ala de viaje, 25 G, outside battle: `use()` only takes it, the pause menu asks `Game` for the trip); `Shop` sells at `price` and buys back at half. `KEY_ITEMS` (id → name: `fragmento_bosque` "Fragmento del amuleto"), kept in `GameState.key_items`. `problem(id, combatant, in_battle)` says why it can't be used now ("" if it can: "PV al máximo", "Solo en combate", ...); `use(id, combatant, in_battle)` → `{used, effect, amount, status, reason}`, shared by `BattleEngine` and the pause menu; `display_name()`, `article()`.
- `scripts/game/leveling.gd` (`Leveling`, `RefCounted`) — fixed `EXP_TABLE` up to `MAX_LEVEL` 20 (12, 35, 62, 96, 180, ... 3600) and fixed `GAINS` per level (PV +6, PM +3, ATK +2, DEF +1, VEL +1; current HP/MP rise with their max, no full heal); `apply(hero)` returns `LEVEL_UP` events, each followed by a `LEARN` event when the hero's `learn` table teaches a spell at that level; `sync_skills(hero)` (after loading), `exp_for_next(level)`.
- `scripts/game/game_options.gd` (`GameOptions`, `RefCounted`) — music and effects volume (0..1, defaults 0.7 / 0.8) and `text_speed` (`SLOW` / `NORMAL` / `FAST`, `char_time()` 0.05 / 0.025 / 0.008 s per character); `to_dict()`, `from_dict()`.
- `scripts/game/save_data.gd` (`SaveData`, `RefCounted`) — pure: `from_state(state, player_pos, play_time)` → `Dictionary` (`version` 4, hero level / EXP / HP / MP / base stats, inventory, quest stage and kills, gold, `loadout` (slot → id), `bag`, opened `chests`, `zone`, `town`, `flags` (sorted), `key_items`, position `[x, z]` on that zone, play time; version 2 and 3 saves still load on the meadow, with the "rey_slime" flag if their quest was done, no key items and Villaclaro as the last village (version 2 also with the starting gear, an empty bag and closed chests); version 1 saves are refused); `apply(state, data)` → `{valid, position, play_time}` (state untouched when not valid; JSON numbers come back as floats; spells come back with `Leveling.sync_skills()`); `is_valid(data)` (zones must be `ZoneData.IDS`, key items `Inventory.KEY_ITEMS`).
- `scripts/game/save_store.gd` (`SaveStore`, `RefCounted`) — JSON files: `user://save.json` (`user://save_autoplay.json` on `--autoplay` runs) and `user://options.json`; `has_save()`, `save_game(data)`, `load_game()` (empty if missing or broken), `save_options(options)`, `load_options()`. On desktop `user://` is `%APPDATA%\Godot\app_userdata\rpg-turnos\`; on the web it is IndexedDB.
- `scenes/world/world.tscn` + `scripts/world/world.gd` (`World`) — one map, built from `zone: ZoneData` (set before `add_child`; the meadow if none): `WorldStage.build(self, zone)`, the zone's figures (`zone.npcs`: `BattleActor` looks by name on cylinder colliders: the old woman `quest`, merchants `shop`, innkeepers `inn`, villagers `npc`), its boss (`EnemyLibrary.look()`), its chests (`build_chest()`: wooden box, gold band and lock, lid on a hinge; `set_chest_open(id, open, instant)`), its exits (a wooden arch turned by the exit's yaw, a sign with its label that always faces the camera, and a bank of fog while its `lock` flag is not set), `Player` (its `route` is the zone's autoplay route), `FollowCamera`, status window (name and level, PV, PM, EXP / next level, potions, "Oro N G", quest line), click or tap on the ground (held and dragged too) walks there with a ring marker, a prompt for the nearest thing in reach ("Enter o toca: hablar" within 2.5 m of the old woman, an innkeeper or a villager, "... comprar" of a merchant, "... abrir" within 1.8 m of a closed chest; a click or tap on one walks there and uses it on arrival), `DialogueBox`, encounters through `EncounterMeter` with the zone's pace (only off the path and safe discs). Emits `talk_requested`, `npc_requested(index)`, `shop_requested(shop_id)`, `inn_requested(inn_id)`, `chest_opened(chest_id)`, `village_changed(inside)` (within `zone.village_radius` of `zone.village_pos`), `exit_requested(zone_id, entry_id)` (walking within 1.2 m of an open exit; a closed one shows its `lock_text` once per approach; exits only count after stepping 2 m away from them since arriving) and `encounter_triggered(boss)` (random encounter, or walking within 2.5 m of the boss while `set_boss_present(true)`), and freezes the player until `set_active(true)`; `place_at_entry(entry_id)`, `place_player(pos, yaw_deg)`, `player_position()`, `in_village()`, `set_world_flags(flags)`, `npc_lines(index)` (`lines_after` once its `after_flag` is set), `set_audio(audio)` (footstep every 1.6 m, encounter and dialogue sounds), `refresh_status(hero, potions, gold, quest_text)`, `set_hero_equipment(weapon, shield)`, `show_notice(text)` (printed on autoplay), `await show_dialogue(speaker, lines)`, `await freeze(on)` (no walking or prompts while a window is open). On autoplay it uses whatever comes in reach once per approach (each villager once per visit). Run on its own it prints each encounter, shop, inn, chest and exit and answers talks with one line.
- `scripts/ui/dialogue_box.gd` (`DialogueBox`, `Control`) — bottom dialogue window with speaker name; `await say(speaker, lines)` advances on Enter / Space / click (autoplay: every 0.8 s, printed); `set_audio()` plays the dialogue sound when it opens.
- `scripts/world/world_stage.gd` (`WorldStage`) — static builder of any zone from its `ZoneData` (`build(root, zone)` returns the grass material, which `World` pushes away from the player each frame, or null without grass): the zone's sky and sun (`BattleStage.build_environment(root, zone)`), ground, dirt path and safe discs, buildings from `MODELS` (KayKit `building_*` at `BUILDING_SCALE` 3.5 with box colliders fitted to their meshes; `BUILDING_RADIUS` footprints), KayKit rocks with box colliders, trees scattered with the zone's seed (denser toward the walls, clumps within `tree_clump_inset` of them, kept off the path, glades, exits, autoplay route, rocks, buildings and chests, cylinder colliders inside the walls) and bushes (no collider), the trees and bushes each drawn as a `MultiMesh`; invisible walls at `half_size`, hills outside; `is_on_path(zone, pos, margin := 0.0)` (path and safe discs are safe), `is_grass_free(pos, zone)`, `add_cylinder_shape()`.
- `scripts/world/zone_data.gd` (`ZoneData`, `Resource`) — everything a map is built from, in `data/zones/<id>.tres` (`IDS`: `pradera`, `bosque`): field `half_size` and `outer_margin`, ground and grass colors, `has_grass`, hills, `path_points`, `safe_discs`, the village (`village_name`, `village_pos`, `village_radius`), `buildings`, `rocks`, tree and bush parameters, `glades`, `entries` (id → [pos, yaw]), `start_entry`, `town_entry`, `exits` (id, pos, yaw, to, entry, label, lock, lock_text), `npcs`, `boss_id` / `boss_pos`, `formations` / `start_formations` / `start_pos` / `start_radius`, `encounter_grace` / `encounter_chance`, `music` / `village_music`, sky, haze, fog and sun, `backdrop`, `autoplay_route`, `autoplay_boss_level`; `by_id(id)`, `entry(id)`, `exit_by_id(id)`. The meadow (`pradera.tres`) keeps the positions of phase 4 and gains the north exit to the forest (closed by fog until the Rey Slime is beaten); the forest (`bosque.tres`, 60 × 80 m) has the village in a clearing (houses, shop, inn, the Leñadora), three glades with chests, the Bruja del bosque's clearing to the north and the exit back south.
- `scenes/world/player.tscn` + `scripts/world/player.gd` (`Player`, `CharacterBody3D`) — WASD / arrows in screen axes (up = −Z), or `move_to(point)` (click / tap; keys cancel it, gives up when stuck; `move_target`), 5 m/s, smooth turn, walk / idle animation through `BattleActor.set_walking()`; model is a `BattleActor` (`HERO`; `set_equipment(weapon, shield)`); `last_step_m` feeds the encounter meter; `place(pos, yaw)` (autoplay goes on from the nearest route point). `--autoplay` walks `route` (the zone's `autoplay_route`) in a loop: in the meadow through the village past the old woman, the merchant, the boss spot, the north exit and the innkeeper, and past two chests; in the forest through its glades, the village and the witch's clearing.
- `scripts/world/follow_camera.gd` (`FollowCamera`) — top-down follow: fixed 55° pitch from the south (looks north, never turns), 14 m away, mouse wheel zooms 9–20 m, `snap()`.
- `scripts/world/vegetation.gd` (`Vegetation`) + `shaders/grass.gdshader` — static builder of tall grass and flowers: `build(root, area, is_free, seed)` fills an XZ rect with jittered tufts in 12 × 12 m `MultiMesh` chunks plus flower heads, returns the shared grass material (wind sway); `set_pusher(material, pos)` bends the grass away from a point.
- `scripts/world/encounter_meter.gd` (`EncounterMeter`, `RefCounted`) — encounter rule with a pace per zone (`EncounterMeter.new(rng, grace_m, chance_per_m)` from `ZoneData.encounter_grace` / `encounter_chance`): free meters after `reset()`, then the chance per full meter walked on grass. Meadow and forest: 9 m and 1 % (a battle every ~110 m, ~22 s walking).
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
- `assets/` — only the models in use, copied unchanged from the CC0 KayKit packs kept (git-ignored) in `assets_src/`: `characters/` (Adventurers: `Knight.glb`, `Mage.glb` and their extracted textures) and `medieval/` (Medieval Hexagon: red houses and well of Villaclaro, green houses, market, tavern and well of the forest village, rocks, trees, shared `hexagons_medieval.png`); `assets/CREDITS.md` lists packs, author and licence.
```

2. Replace:

```markdown
- `scripts/ui/pause_menu.gd` (`PauseMenu`, `Control`, `PROCESS_MODE_ALWAYS`) — Esc / P or the ☰ button (top right, three `ColorRect` bars) open it while `available`; sets `get_tree().paused`. Pages: main (Estado, Objetos, Equipo, Guardar, Opciones, Volver al título, Cerrar), Estado (stats, gold, spells), Objetos ("Usar" on every item; greyed with the reason when it can't be used outside battle now), Equipo (the three slots with what is worn and ATK / DEF; a slot lists the pieces of that slot in the bag with the comparison, Quitar and Volver), Opciones (`OptionsPanel`), confirmation before the title. Signals `save_requested` (answered with `show_save_result(ok)`), `title_requested`, `state_changed`; `tour()` for `--autoplay-menu`.
- `scripts/audio/music_library.gd` (`MusicLibrary`) — original tracks as note tables (`TRACKS`: bpm, loop, lead duty, bars of tokens like `"F#5/4"` = note / length in sixteenths, `r` rest, drums `k` / `s` / `h`): title, map, village (waltz), battle, boss loop; victory and defeat don't. `build(id)` synthesizes square lead, triangle bass and noise drums into a cached `AudioStreamWAV` (22050 Hz, 16-bit mono, `LOOP_FORWARD` over the whole track); `to_stream()`, `peak()`, `clear_cache()`.
```

with:

```markdown
- `scripts/ui/pause_menu.gd` (`PauseMenu`, `Control`, `PROCESS_MODE_ALWAYS`) — Esc / P or the ☰ button (top right, three `ColorRect` bars) open it while `available`; sets `get_tree().paused`. Pages: main (Estado, Objetos, Equipo, Guardar, Opciones, Volver al título, Cerrar), Estado (stats, gold, spells), Objetos ("Usar" on every item; greyed with the reason when it can't be used outside battle now; the Ala de viaje closes the menu and emits `travel_requested`; then the key items, "Objeto clave"), Equipo (the three slots with what is worn and ATK / DEF; a slot lists the pieces of that slot in the bag with the comparison, Quitar and Volver), Opciones (`OptionsPanel`), confirmation before the title. Signals `save_requested` (answered with `show_save_result(ok)`), `title_requested`, `travel_requested`, `state_changed`; `tour()` for `--autoplay-menu`.
- `scripts/audio/music_library.gd` (`MusicLibrary`) — original tracks as note tables (`TRACKS`: bpm, loop, lead duty, bars of tokens like `"F#5/4"` = note / length in sixteenths, `r` rest, drums `k` / `s` / `h`): title, map, village (waltz), forest (E minor), battle, boss loop; victory and defeat don't. `build(id)` synthesizes square lead, triangle bass and noise drums into a cached `AudioStreamWAV` (22050 Hz, 16-bit mono, `LOOP_FORWARD` over the whole track); `to_stream()`, `peak()`, `clear_cache()`.
```

3. Replace:

```markdown
- Whole quest on autoplay, headless (about a minute; opens the chest of 25 G, buys the Espada de cobre and the Cota de cuero, finds the Escudo de madera; the Rey Slime comes out at Lv 5; `Misión cumplida`, then a night at the inn): `.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 60000 -- --autoplay`
```

with:

```markdown
- Whole game so far on autoplay, headless (a few minutes; opens the chest of 25 G, buys the Espada de cobre and the Cota de cuero, finds the Escudo de madera; the Rey Slime comes out at Lv 5, the fog lifts and the route takes the north exit; in the forest it opens the glade chests, buys the zone 2 gear and beats the Bruja at Lv 9, `¡Consigues un Fragmento del amuleto!`): `.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 50000 -- --autoplay`
```

4. Replace:

```markdown
- Run only the world map (prints encounters, shops, inns and chests instead of playing them): `.\tools\godot.cmd --path . res://scenes/world/world.tscn -- --autoplay`
```

with:

```markdown
- Run only the world map (prints encounters, shops, inns, chests and exits instead of playing them): `.\tools\godot.cmd --path . res://scenes/world/world.tscn -- --autoplay`
- Start a new autoplay game in another zone (`--autoplay-zone=bosque`: Lv 5, 150 G, the zone 1 gear, the Rey Slime beaten; it buys the forest gear, sleeps at the inn when below half HP and fights the Bruja at Lv 9): `.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 40000 -- --autoplay --autoplay-zone=bosque`
```


In `docs/boost/specs/ideas-sueltas.md`:

1. Replace:

```markdown
- **Estado:** pendiente.
```

with:

```markdown
- **Estado:** hecha en la fase 5a: 9 m de gracia y 1 % por metro en la pradera y el bosque, cada zona con su ritmo en `ZoneData` ([plan](../plans/2026-11-04-mundo-bosque.md)).
```


In `assets/CREDITS.md`:

1. Replace:

```markdown
| KayKit – Medieval Hexagon Pack 1.0 | Kay Lousberg (www.kaylousberg.com) | https://github.com/KayKit-Game-Assets/KayKit-Medieval-Hexagon-Pack-1.0 | CC0 1.0 | `medieval/building_home_A_red`, `building_home_B_red`, `building_well_red`, `rock_single_A`–`E`, `tree_single_A`, `tree_single_B`, `trees_A_medium`, `hexagons_medieval.png` |
```

with:

```markdown
| KayKit – Medieval Hexagon Pack 1.0 | Kay Lousberg (www.kaylousberg.com) | https://github.com/KayKit-Game-Assets/KayKit-Medieval-Hexagon-Pack-1.0 | CC0 1.0 | `medieval/building_home_A_red`, `building_home_B_red`, `building_well_red`, `building_home_A_green`, `building_home_B_green`, `building_market_green`, `building_tavern_green`, `building_well_green`, `rock_single_A`–`E`, `tree_single_A`, `tree_single_B`, `trees_A_medium`, `trees_B_medium`, `hexagons_medieval.png` |
```

2. Replace:

```markdown
The slimes, the Rey Slime's crown and the bushes are built in code (`LowPoly`).
```

with:

```markdown
The slimes, the Rey Slime's crown, the bat, the mushroom, the wolf, the goblin, the carnivorous plant and the bushes are built in code (`BattleActor`, `LowPoly`); the Bruja del bosque is the Mage tinted purple.
```


- [ ] **Step 2: Check every changed script once more**

```powershell
.\tools\godot.cmd --headless --path . --import
Get-ChildItem scripts -Recurse -Filter *.gd | ForEach-Object { .\tools\godot.cmd --headless --path . --check-only --script ("res://" + ($_.FullName.Substring((Get-Location).Path.Length + 1) -replace '\\','/')) }
.\tools\godot.cmd --headless --path . res://scenes/world/world.tscn --fixed-fps 10 --quit-after 1500 -- --autoplay
```

Expected: no `ERROR` or `WARNING` besides the Jolt one; the standalone map prints `Cofre:`, `Tienda:`, `Posada:` and encounter lines and "Una niebla espesa cierra el camino del norte." (no `Salida:` line while the fog is up).

- [ ] **Step 3: Web export**

```powershell
.\tools\godot.cmd --headless --path . --export-release "Web" build/web/index.html
(Get-ChildItem build\web | Measure-Object Length -Sum).Sum / 1MB
```

Expected: the export ends without `ERROR`; the size grows by well under 1 MB over phase 4 (six small models). Serve `build/web` with any static server and play into the forest in a browser: the FPS there should stay close to the meadow's (the forest has about twice the trees, all in three `MultiMesh`es).

- [ ] **Step 4: Commit**

```powershell
git add CLAUDE.md docs assets/CREDITS.md
git status --short
git commit -m "Document the world of zones and the forest"
```

---

## Next plans

- **5b — Mina abandonada** (`docs/boost/plans/<date>-mundo-mina.md`): the Refugio de la mina at the entrance (steel shop 400 / 350 / 220 G, inn 30 G) and the exit from the forest north (lock `bruja`), three floors `mina_1..3.tres` drawn as ASCII in `ZoneData` (`#` rock, `.` floor, `S` / `B` stairs, `C` chest, `L` lever, `D` locked door, `K` key) on a 4 m grid of rock blocks, the lever of floor 2 and the key of floor 3 saved in `world_flags`, safe stair rooms, no grass (encounters on every floor tile), darkness with torches (point lights), rock blocks between the camera and the hero turned transparent, a `mina` battle backdrop (rock and torches), Golem de barro, Araña and Espectro (low-poly), the Golem de piedra boss (charges one round with "El Golem acumula fuerza…" and hits ×2; Defender halves it) with the second fragment, its balance check at Lv 9-13, and `--autoplay-zone=mina_1`.
- **5c — Castillo de la Niebla** (`docs/boost/plans/<date>-mundo-castillo.md`): the camp before the castle (platinum shop 650 / 550 / 300 G, inn 50 G), the courtyard with fog and the throne room (`castillo_patio.tres`, `castillo_trono.tres`, Medieval Hexagon `wall_*` pieces and blocks), Esqueleto guerrero / pícaro / mago from KayKit Skeletons (copy them from `assets_src/KayKit-Character-Pack-Skeletons-1.0`, add a `CREDITS.md` row), the Señor de la Niebla (`Skeleton_Mage` ×1.6 with a purple aura; phase 1: 200 PV, ATK 42, Rayo 40; phase 2: back to 180 PV, ATK 50, Niebla on every target for 30 and 30 % silence, no stagger) with its own simulation for 85-90 % at Lv 17, the third fragment, a `castillo` backdrop, the full autoplay from the start to the Señor de la Niebla with the real duration measured against the ~2 hours, and the web export measured in size and FPS.
