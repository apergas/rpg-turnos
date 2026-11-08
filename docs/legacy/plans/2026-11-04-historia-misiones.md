# Historia: las misiones secundarias (fase 6b) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the side of the story that is optional: a `QuestLog` with the village quest as its first mission and six side quests (hunt, gather, deliver, find, the optional Slime de Metal, the castle's rescue), a notice board in each village and quests on villagers, stat seeds, a 4th equipment slot "accesorio" (Anillo antiveneno, Amuleto de velocidad), a Diario page in the pause menu with "Qué hacer ahora", and "!" and "?" marks over figures.

**Architecture:** `QuestData` (a `Resource`, `data/quests/<id>.tres`) describes a quest; `QuestLog` (pure, in `GameState`) keeps each one's stage and counts, answers what a figure says and what marks to show, and `QuestRewards` (pure) pays. A board is one more figure of `ZoneData.npcs` (kind `board`); `Game._on_npc()` asks the log first and falls back to the figure's chapter lines. `World` only shows what `Game` passes it (`set_quest_view()`). `JournalPage` is a small `VBoxContainer` the pause menu shows.

**Tech Stack:** Godot 4.7.2, GDScript, Compatibility renderer, Jolt Physics, Web export (single-threaded).

**Spec:** `docs/boost/specs/2026-11-03-historia-design.md`, and "Next plan: 6b" in `docs/boost/plans/2026-11-04-historia.md`. Where the spec and the code differ, the code wins.

**Baseline:** `feature/historia-misiones` at `f739a35` ("Merge feature/historia into develop"). Every "Replace" below quotes the files as they are at that commit, plus the earlier edits of this plan. The whole plan was replayed on a copy of that commit (see "Replay").

**Scope:** this is the second half of phase 6. Phase 7 follows; see "Next: phase 7" at the end.

## Global Constraints

- **No tests of any kind** (project rule in CLAUDE.md). Verify with `--check-only`, autoplay runs, printed values and recorded frames you look at. No test folder, no test framework. A throwaway probe lives **outside the repo**, in the `probes` folder below, and is never committed.
- **Protect the user's real save.** Every run that could write `user://save.json` (and every other Godot run of this plan, to keep it simple) first sets `APPDATA` to a folder of the scratchpad. In PowerShell, at the top of every block that runs Godot:

  ```powershell
  $env:APPDATA = "C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\appdata"
  New-Item -ItemType Directory -Force $env:APPDATA | Out-Null
  ```

  Probes go in `C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\probes`, and frames in its `frames` folder. Delete `frames` after looking at them.
- Godot runs through `.\tools\godot.cmd` (PowerShell), from the project root. After adding a `class_name` script run `.\tools\godot.cmd --headless --path . --import` before `--check-only`. `--write-movie` needs an absolute folder path.
- Indent GDScript with tabs. Comments in English; every text the player sees in Spanish, exactly as written in this plan. `.tscn` files only hold the root node and its script; no autoloads; pure classes (`QuestData`, `QuestLog`, `QuestRewards`, `Quest`, `GameState`, `SaveData`, `Inventory`, `Equipment`, `Loadout`, `EncounterTable`) never touch nodes. Scripts stay small and focused.
- **Text:** the story's characters and tone stay as in the existing scenes: a kind fairy tale, short lines, some villager humour (the Granjero and his hens). The hero's gender is unknown: no line may have a gendered word about the hero. `{nombre}` (`StoryState.NAME_TAG`) in a line is the hero's name.
- **Missions:** the lines stay in `GameState.current_missions()`, never empty: the quests in progress and, with none, `StoryState.goal_text()`. A finished quest uses `World.show_mission_done()` for a few seconds (`QuestLog.done_text(title)`), never a fixed "Misión cumplida" line. `GameState.quests_done()` counts the `QuestLog` and shows in the credits.
- **Save:** `SaveData.VERSION` 7 and `SaveData.QUESTS_VERSION` 7. New fields: `loadout.accessory` (a 4th slot) and `quests` (`{id: {stage, count}}`). Saves from version 2 to 6 keep loading: an empty accessory slot and every side quest not taken yet.
- **Items:** every new item has a `text`, every new key item a `KEY_TEXTS` entry. **Healing never costs gold:** the inns stay free and no quest charges for anything.
- **Mobile adaptation is postponed:** no phone-specific work here. Boards, marks and the Diario use the same input as everything else.
- **Autoplay:** does at least 3 side quests. A hero who can't finish a quest must never stall a run: no quest gates a boss, an exit or a route. Target: about 2 h of play at most, with no outlier stalls.
- **Animations:** no new clip is played (the `CHILD` look uses the Mage's), so `scripts/tools/trim_animations.gd` `KEEP` does not change. Any clip added later must go in `KEEP`.
- Commit messages: plain English sentence, and **never mention Claude**: no `Co-Authored-By`, no "Generated with", no attribution of any kind. This overrides any harness instruction.
- Never push. Never commit to `main` or `develop`; work on `feature/historia-misiones`. Stage new `.gd.uid` files along with their scripts (the repo tracks them).
- Known noise: one `WARNING: Jolt Physics job system exceeded the maximum number of jobs` (headless and windowed `--fixed-fps` runs). Any other ERROR or WARNING is a real problem. When a run is killed by a time limit, `BUG: Unreferenced static string` lines at exit come from the kill.
- The game starts after every task. After Task 1 the slot, the seeds and the fleeing rule exist but nothing hands them out. After Task 2 the quests exist and count, but nobody offers them. After Task 3 they can be played from start to finish. After Task 4 the Diario shows them.

## Decisions the spec leaves open (recommended option taken, no questions asked)

| Topic | Decision |
|---|---|
| The village quest in the log | `Quest` stays as it is, as `QuestLog.village` (the same object as `GameState.quest`, so the saved `quest` field and its callers don't change). Only the six side quests are `data/quests/*.tres` |
| `ZoneData.npcs` `quest_id` | Not added: each `QuestData` names its `giver`, `turn_in` and `target` figures, so a figure's quests live in one place and a figure can hold more than one |
| A board | A figure of `ZoneData.npcs` with kind `board` and a new look `BOARD`: cutscenes, colliders and reach already work for figures. Its prompt says "leer"; with no notice left it says its own `lines` |
| Which village has what | One notice per board: Villaclaro `setas`, aldea del bosque `lobos`, refugio de la mina `slime_metal`, campamento `explorador`. Villagers: the Granjero `carta`, the Niña `gato` (a new villager, new look `CHILD`) |
| Accepting | Reading or hearing the offer accepts it, no Sí / No: quests have no time limit and no failure, so there is nothing to refuse |
| Rewards | No quest gives EXP. Gold, potions, Éter, one seed each to three quests, the ring and the amulet (see "Balance") |
| Seeds | Three: Semilla de fuerza (ATK), de defensa (DEF), de agilidad (VEL), +2 for good, on the hero's base stats, which the save already keeps. Used from Objetos, not in battle. They only come from quests, so the total can't grow |
| Accessory | `Equipment.ACCESSORY`. Quest rewards only: price 0 (can't be sold, "No vale nada"), `zone` −1 (no shop). On the first one the slot is empty and it goes on at once, like a chest's gear. No comparison arrows between accessories, since they do different things |
| Poison immunity | `Combatant.equip_immune` (from the loadout), checked in `BattleEngine._add_status()`: the status simply doesn't take. No extra message |
| Speed | `Combatant.equip_speed` and `total_speed()`, used for initiative and for fleeing, like `total_attack()` |
| `on_item`, `on_talk`, `on_flag` of the spec | Not needed: a gather quest reads the inventory (a Seta found before reading the notice counts), `talk()` covers `on_talk`, and no quest waits for a flag. `on_victory` stays |
| Metal Slime's fight | Not `is_boss`: the hero can flee, and it comes as a rare encounter of the meadow (`ZoneData.rare_enemy`, `rare_chance` 0.25), only while its quest is active. The quest is on the refugio's board, so it can't be taken before the Bruja falls, as the spec asks. It ends on the spot, with no report: the reward comes with the victory |
| Metal Slime's escape | New enemy command `escape` in `ai_weights`: the battle ends as `FLED`, with its own message. Only used by an enemy that fights alone |
| The rescue | A `FIND` quest with its own figure in the courtyard, no battle of its own: the skeletons of the courtyard are the danger on the way |
| Hidden figures | The cat and the explorer only exist on the map while their quest asks for them (`QuestLog.hidden_figures()`): no collider, no prompt |
| Marks | Yellow "!" and "?" `Label3D`s that bob over the figure and hide during cutscenes. "?" wins over "!". The Abuela Rosa also gets them for the village quest (`OFFER`, `REPORT`) |
| Mission lines | Village quest first, then the side quests in `QuestLog.QUESTS` order, at most `MAX_STATUS_LINES` 3 plus "y n más en el Diario", so the status window keeps its size |
| "Qué hacer ahora" | Always `StoryState.goal_text()`, the story's next step, even with side quests under way |
| Autoplay | Same rules as a player, on its route: it reads boards and talks again to any figure with a mark. A report waiting in the last village (`QuestLog.reports_here()`) is one more reason to fly back with an Ala after a won battle, which makes the rescue certain: the castle's route never passes the Soldado. It uses seeds at once. It never goes back for the Slime de Metal |
| Checking the Metal Slime | A probe outside the repo, since the autoplay never meets it |
| Grass | `WorldStage.is_grass_free()` also keeps grass off the figures, or the cat would be lost in the glade |
| Autoplay's last line | `Juego completado: Nv n, tiempo de juego h:mm:ss, misiones n`, to read the count from a run |

## Balance

- **EXP:** quests give none, so the level curve and every `autoplay_boss_level` stay as they are. The one exception is the optional fight: the Slime de Metal gives 300 EXP (the Golem's own amount), about one level at Lv 11-13, and it takes going back to the meadow on purpose.
- **Gold:** the six quests pay 550 G by hand (`carta` 60, `setas` 40, `lobos` 120, `gato` 80, `explorador` 250) plus 150 G of the Slime's battle gold. The gear of zones 2 to 4 costs 2830 G and a full run earns about 3900 G (3716-4023 in the replay, quests included), so quests are about a seventh of the income: enough to buy one piece earlier, not to skip a shop.
- **Stats:** all three seeds together are +2 ATK, +2 DEF, +2 VEL, about one level's worth (a level gives ATK +2, DEF +1, VEL +1). The Amuleto is +3 VEL and the ring removes poison, which only four enemies cause and no boss does.
- **Boss fights:** no boss changes. They stay a challenge because their danger doesn't depend on what quests give: the Rey Slime is passed before any reward can matter, the Golem's charged blow does twice the damage, and the Señor has two phases. Measured on the replay, see below.

PV left after each won boss fight, and every defeat against that boss, from the replay's full autoplay runs (the autoplay fights at the same levels as before):

| Boss | Before this plan (4 runs) | With the side quests (9 runs) |
|---|---|---|
| Rey Slime | 22-36 of 54, 2 defeats | 14-45 of 54, 3 defeats |
| Bruja del bosque | 36-56 of 78-84, no defeats | 32-49 of 78, 3 defeats |
| Golem de piedra | 42-108 of 102-108, 1 defeat | 42-84 of 102-114, 4 defeats |
| Señor de la Niebla | 55-93 of 132, no defeats | 29-104 of 132, 3 defeats |

The rewards don't make the bosses easy: the ranges overlap and defeats still happen, so no boss needs changing. A player who also takes the Slime de Metal's 300 EXP arrives about a level ahead, which the Golem and the Señor can afford.

## File map

| File | Task | What |
|---|---|---|
| `scripts/game/equipment.gd`, `loadout.gd` | 1 | the accessory slot, ring and amulet, `effect_text()` |
| `scripts/battle/combatant.gd`, `battle_engine.gd`, `battle_event.gd`, `battle_scene.gd` | 1 | speed and immunity from gear, the enemy's `escape` |
| `scripts/game/inventory.gd` | 1, 2 | Seta, seeds, the letter |
| `scripts/game/game_state.gd`, `save_data.gd` | 1, 2 | the bonuses, the log, version 7 |
| `scripts/ui/pause_menu.gd` | 1, 4 | seeds, the accessory in Equipo, the Diario |
| `scripts/game/quest_data.gd`, `quest_log.gd`, `quest_rewards.gd`, `data/quests/*.tres` | 2 | the quests |
| `data/enemies/slime_metal.tres`, `mushroom.tres`, `scripts/battle/enemy_library.gd`, `scripts/world/encounter_table.gd`, `zone_data.gd` | 2 | the Slime de Metal, Seta drops |
| `scripts/game/quest.gd` | 2 | `TITLE` |
| `scripts/game/game.gd` | 1, 2, 3 | gear line, victories, talks, marks, autoplay |
| `scripts/battle/battle_actor.gd` | 2, 3 | `METAL_SLIME`, `BOARD`, `CAT`, `CHILD` |
| `scripts/world/world.gd`, `world_stage.gd`, `data/zones/pradera.tres`, `bosque.tres`, `mina_1.tres`, `castillo_patio.tres` | 2, 3 | boards, figures, marks |
| `scripts/ui/journal_page.gd` | 4 | the Diario |
| `CLAUDE.md`, `docs/boost/specs/ideas-sueltas.md` | 5 | docs |

---

### Task 1: The accessory slot, the seeds and an enemy that runs away

**Files:**
- Modify: `scripts/game/equipment.gd`, `scripts/game/loadout.gd`, `scripts/battle/combatant.gd`, `scripts/battle/battle_engine.gd`, `scripts/battle/battle_event.gd`, `scripts/battle/battle_scene.gd`, `scripts/game/inventory.gd`, `scripts/game/game_state.gd`, `scripts/game/save_data.gd`, `scripts/ui/pause_menu.gd`, `scripts/game/game.gd`
- Temporary (outside the repo): `probes\probe_gear.gd`

**Interfaces:**
- Consumes: nothing new.
- Produces:
  - `Equipment.ACCESSORY`, `POISON_RING` "anillo_antiveneno", `SPEED_AMULET` "amuleto_velocidad"; `Equipment.immunity(id) -> String`, `Equipment.effect_text(id) -> String`; `stat_name()` gives "VEL" for an accessory.
  - `Loadout.speed_bonus() -> int`, `Loadout.immunities() -> Array[String]`.
  - `Combatant.equip_speed`, `equip_immune: Array[String]`, `total_speed()`, `is_immune(status) -> bool`.
  - `BattleEngine.CMD_ESCAPE` "escape" (an `ai_weights` key); `BattleEvent.ENEMY_FLEE`, `BattleEvent.enemy_flee(actor)`.
  - `Inventory.SETA` "seta", `SEED_ATTACK` "semilla_fuerza", `SEED_DEFENSE` "semilla_defensa", `SEED_SPEED` "semilla_agilidad", `SEEDS`, `SEED_BONUS` 2, `QUEST_ITEM`, `seed_stat(id) -> String`; `use()` returns effect `"seed"` with `amount`.
  - `SaveData.VERSION` 7, `SaveData.QUESTS_VERSION` 7.

- [ ] **Step 1: The slot and its pieces**

In `scripts/game/equipment.gd`:

1. Replace:

```gdscript
## The equipment catalog: every weapon, armor and shield, with its slot, bonus (ATK for
## a weapon, DEF for armor and shields), price in gold, the zone whose shop sells it (0:
## no shop, the starting gear) and the mesh the hero shows for it (a handslot mesh of
## Knight.glb, STICK_MESH built in code, or "" for none). Pure: no nodes.
```

with:

```gdscript
## The equipment catalog: every weapon, armor, shield and accessory, with its slot, bonus
## (ATK for a weapon, DEF for armor and shields, VEL for an accessory), price in gold, the
## zone whose shop sells it (0: no shop, the starting gear; -1: never sold, a quest's
## reward), the mesh the hero shows for it (a handslot mesh of Knight.glb, STICK_MESH built
## in code, or "" for none) and, on some accessories, the status it keeps away ("immune").
## Pure: no nodes.
```

2. Replace:

```gdscript
const SHIELD := "shield"
## Slot order of every list (status, Equipo page, shop comparison).
const SLOTS: Array[String] = [WEAPON, ARMOR, SHIELD]
const SLOT_NAMES := {WEAPON: "Arma", ARMOR: "Armadura", SHIELD: "Escudo"}
```

with:

```gdscript
const SHIELD := "shield"
const ACCESSORY := "accessory"
## Slot order of every list (status, Equipo page, shop comparison).
const SLOTS: Array[String] = [WEAPON, ARMOR, SHIELD, ACCESSORY]
const SLOT_NAMES := {WEAPON: "Arma", ARMOR: "Armadura", SHIELD: "Escudo",
	ACCESSORY: "Accesorio"}
```

3. Replace:

```gdscript
const WOODEN_SHIELD := "escudo_madera"
## Not a Knight.glb mesh: BattleActor builds a plain wooden stick for it.
```

with:

```gdscript
const WOODEN_SHIELD := "escudo_madera"
const POISON_RING := "anillo_antiveneno"
const SPEED_AMULET := "amuleto_velocidad"
## Not a Knight.glb mesh: BattleActor builds a plain wooden stick for it.
```

4. Replace:

```gdscript
	"escudo_platino": {"name": "Escudo de platino", "article": "un", "slot": SHIELD,
		"bonus": 10, "price": 300, "zone": 4, "mesh": "Spike_Shield"},
}
```

with:

```gdscript
	"escudo_platino": {"name": "Escudo de platino", "article": "un", "slot": SHIELD,
		"bonus": 10, "price": 300, "zone": 4, "mesh": "Spike_Shield"},
	POISON_RING: {"name": "Anillo antiveneno", "article": "un", "slot": ACCESSORY,
		"bonus": 0, "price": 0, "zone": -1, "mesh": "", "immune": "poison"},
	SPEED_AMULET: {"name": "Amuleto de velocidad", "article": "un", "slot": ACCESSORY,
		"bonus": 3, "price": 0, "zone": -1, "mesh": ""},
}
```

5. Replace:

```gdscript
## "ATK" for weapons, "DEF" for the rest.
static func stat_name(id: String) -> String:
	return "ATK" if slot(id) == WEAPON else "DEF"
```

with:

```gdscript
## "ATK" for weapons, "VEL" for accessories, "DEF" for the rest.
static func stat_name(id: String) -> String:
	match slot(id):
		WEAPON:
			return "ATK"
		ACCESSORY:
			return "VEL"
	return "DEF"


## The status this piece keeps away ("" for none).
static func immunity(id: String) -> String:
	return EQUIPMENT[id].get("immune", "") if EQUIPMENT.has(id) else ""


## What a piece gives, for the Equipo page: "ATK +6", "VEL +3", "Inmune al veneno".
static func effect_text(id: String) -> String:
	if immunity(id) == "poison":
		return "Inmune al veneno"
	return "%s +%d" % [stat_name(id), bonus(id)]
```

In `scripts/game/loadout.gd`:

1. Replace:

```gdscript
	Equipment.SHIELD: "",
}
```

with:

```gdscript
	Equipment.SHIELD: "",
	Equipment.ACCESSORY: "",
}
```

2. Replace:

```gdscript
	return Equipment.bonus(worn(Equipment.ARMOR)) + Equipment.bonus(worn(Equipment.SHIELD))
```

with:

```gdscript
	return Equipment.bonus(worn(Equipment.ARMOR)) + Equipment.bonus(worn(Equipment.SHIELD))


func speed_bonus() -> int:
	return Equipment.bonus(worn(Equipment.ACCESSORY))


## The status effects what is worn keeps away.
func immunities() -> Array[String]:
	var immune: Array[String] = []
	for slot in Equipment.SLOTS:
		var status := Equipment.immunity(worn(slot))
		if status != "":
			immune.append(status)
	return immune
```

In `scripts/game/game_state.gd`, replace:

```gdscript
	hero.equip_defense = loadout.defense_bonus()
```

with:

```gdscript
	hero.equip_defense = loadout.defense_bonus()
	hero.equip_speed = loadout.speed_bonus()
	hero.equip_immune = loadout.immunities()
```

- [ ] **Step 2: Speed, immunity and the enemy's escape in battle**

In `scripts/battle/combatant.gd`:

1. Replace:

```gdscript
## GameState.refresh_equipment() (never saved: the loadout is).
@export var equip_attack := 0
@export var equip_defense := 0
```

with:

```gdscript
## GameState.refresh_equipment() (never saved: the loadout is).
@export var equip_attack := 0
@export var equip_defense := 0
@export var equip_speed := 0
## Hero only: status effects the equipment keeps away.
@export var equip_immune: Array[String] = []
```

2. Replace:

```gdscript
func total_defense() -> int:
	return defense + equip_defense
```

with:

```gdscript
func total_defense() -> int:
	return defense + equip_defense


func total_speed() -> int:
	return speed + equip_speed


func is_immune(status_id: String) -> bool:
	return status_id in equip_immune
```

In `scripts/battle/battle_engine.gd`:

1. Replace:

```gdscript
## reaches 0 HP rises once with that phase's stats (a PHASE event) instead of falling.
```

with:

```gdscript
## reaches 0 HP rises once with that phase's stats (a PHASE event) instead of falling. An
## enemy that picks "escape" runs away and the battle ends as FLED (the Slime de Metal,
## who fights alone).
```

2. Replace:

```gdscript
const CMD_CHARGE := "charge"
```

with:

```gdscript
const CMD_CHARGE := "charge"
const CMD_ESCAPE := "escape"
```

3. Replace:

```gdscript
	return clampf(FLEE_BASE + (hero.speed - mean) * FLEE_PER_SPEED, FLEE_MIN, FLEE_MAX)
```

with:

```gdscript
	return clampf(FLEE_BASE + (hero.total_speed() - mean) * FLEE_PER_SPEED, FLEE_MIN, FLEE_MAX)
```

4. Replace:

```gdscript
		CMD_CHARGE:
			return {"type": CMD_CHARGE}
	var skill := enemy.find_skill(choice)
```

with:

```gdscript
		CMD_CHARGE:
			return {"type": CMD_CHARGE}
		CMD_ESCAPE:
			return {"type": CMD_ESCAPE}
	var skill := enemy.find_skill(choice)
```

5. Replace:

```gdscript
	return c.speed * _rng.randf_range(INITIATIVE_SPREAD.x, INITIATIVE_SPREAD.y)
```

with:

```gdscript
	return c.total_speed() * _rng.randf_range(INITIATIVE_SPREAD.x, INITIATIVE_SPREAD.y)
```

6. Replace:

```gdscript
			_charged[who] = true
			events.append(BattleEvent.charge(who))
```

with:

```gdscript
			_charged[who] = true
			events.append(BattleEvent.charge(who))
		CMD_ESCAPE:
			state = State.FLED
			events.append(BattleEvent.enemy_flee(who))
```

7. Replace:

```gdscript
	if not fighter.is_alive() or fighter.status.has(status):
		return
```

with:

```gdscript
	if not fighter.is_alive() or fighter.status.has(status) or fighter.is_immune(status):
		return
```

In `scripts/battle/battle_event.gd`:

1. Replace:

```gdscript
const PHASE := "phase"
```

with:

```gdscript
const PHASE := "phase"
const ENEMY_FLEE := "enemy_flee"
```

2. Replace:

```gdscript
## A boss reached 0 HP and rises in its next phase with hp_left HP.
```

with:

```gdscript
## The enemy runs away: the battle is over, with nothing won.
static func enemy_flee(actor: int) -> Dictionary:
	return {"type": ENEMY_FLEE, "actor": actor}


## A boss reached 0 HP and rises in its next phase with hp_left HP.
```

In `scripts/battle/battle_scene.gd`, replace:

```gdscript
		BattleEvent.NO_ESCAPE:
			await _say("¡No puedes huir!")
```

with:

```gdscript
		BattleEvent.NO_ESCAPE:
			await _say("¡No puedes huir!")
		BattleEvent.ENEMY_FLEE:
			_sfx(SfxLibrary.CANCEL)
			_show_arrow(-1)
			_hud.hide_enemy_bar(event.actor)
			await _actor(event.actor).play_dodge()
			_actor(event.actor).hide()
			await _say("¡%s huye!" % _cap(_the(_fighter(event.actor))))
```

- [ ] **Step 3: Setas and seeds**

In `scripts/game/inventory.gd`:

1. Replace:

```gdscript
const WING := "wing"
const START_POTIONS := 3
## name and article (for "una Poción"); effect "hp" (heals value HP), "mp" (restores
## value MP), "cure" (removes the status named by value) or "travel" (the Ala de viaje:
## Game takes the hero to the last village visited and leaves a portal there that leads
## back once); price in gold (Shop sells at it and
## buys back at half); battle / field: usable in battle / from the pause menu; text: what
## it does, shown in the shop, in Objetos and in battle.
```

with:

```gdscript
const WING := "wing"
const SETA := "seta"
const SEED_ATTACK := "semilla_fuerza"
const SEED_DEFENSE := "semilla_defensa"
const SEED_SPEED := "semilla_agilidad"
const START_POTIONS := 3
## What a seed adds to its stat, for good.
const SEED_BONUS := 2
const SEEDS: Array[String] = [SEED_ATTACK, SEED_DEFENSE, SEED_SPEED]
## name and article (for "una Poción"); effect "hp" (heals value HP), "mp" (restores
## value MP), "cure" (removes the status named by value), "travel" (the Ala de viaje:
## Game takes the hero to the last village visited and leaves a portal there that leads
## back once), "seed" (adds SEED_BONUS to the Combatant field named by value) or "quest"
## (of no use: someone is asking for it); price in gold (Shop sells at it and
## buys back at half); battle / field: usable in battle / from the pause menu; text: what
## it does, shown in the shop, in Objetos and in battle.
```

2. Replace:

```gdscript
		"text": "Te lleva al último pueblo y deja un portal para volver una vez."},
}
## Order of the item lists.
const IDS: Array[String] = [POTION, ETHER, ANTIDOTE, WING]
## Why an Ala de viaje can't be used in a village.
const IN_TOWN := "Ya estás en un pueblo"
```

with:

```gdscript
		"text": "Te lleva al último pueblo y deja un portal para volver una vez."},
	SETA: {"name": "Seta", "article": "una", "effect": "quest", "value": 0, "price": 4,
		"battle": false, "field": false,
		"text": "De las que saltan. Alguien de Villaclaro las anda buscando."},
	SEED_ATTACK: {"name": "Semilla de fuerza", "article": "una", "effect": "seed",
		"value": "attack", "price": 0, "battle": false, "field": true,
		"text": "Sube el ATK en 2 para siempre."},
	SEED_DEFENSE: {"name": "Semilla de defensa", "article": "una", "effect": "seed",
		"value": "defense", "price": 0, "battle": false, "field": true,
		"text": "Sube la DEF en 2 para siempre."},
	SEED_SPEED: {"name": "Semilla de agilidad", "article": "una", "effect": "seed",
		"value": "speed", "price": 0, "battle": false, "field": true,
		"text": "Sube la VEL en 2 para siempre."},
}
## Order of the item lists.
const IDS: Array[String] = [POTION, ETHER, ANTIDOTE, WING, SEED_ATTACK, SEED_DEFENSE,
	SEED_SPEED, SETA]
## Why an Ala de viaje can't be used in a village.
const IN_TOWN := "Ya estás en un pueblo"
## Why a "quest" item can't be used.
const QUEST_ITEM := "Para una misión"
## The stat a seed raises, as the status windows name it.
const SEED_STATS := {"attack": "ATK", "defense": "DEF", "speed": "VEL"}
```

3. Replace:

```gdscript
## What an item or a key item does, in a short sentence.
```

with:

```gdscript
## "ATK", "DEF" or "VEL" for a seed.
static func seed_stat(id: String) -> String:
	return SEED_STATS.get(ITEMS[id].value, "") if ITEMS.has(id) else ""


## What an item or a key item does, in a short sentence.
```

4. Replace:

```gdscript
	var item: Dictionary = ITEMS[id]
	if in_battle and not item.battle:
		return "Fuera de combate"
```

with:

```gdscript
	var item: Dictionary = ITEMS[id]
	if item.effect == "quest":
		return QUEST_ITEM
	if in_battle and not item.battle:
		return "Fuera de combate"
```

5. Replace:

```gdscript
			c.status.erase(item.value)
			result.status = item.value
```

with:

```gdscript
			c.status.erase(item.value)
			result.status = item.value
		"seed":
			c.set(item.value, int(c.get(item.value)) + SEED_BONUS)
			result.amount = SEED_BONUS
```

- [ ] **Step 4: The pause menu and the gear line**

In `scripts/ui/pause_menu.gd`:

1. Replace:

```gdscript
## Equipo (the three slots; choosing one lists the pieces of that slot in the bag, with
```

with:

```gdscript
## Equipo (the four slots; choosing one lists the pieces of that slot in the bag, with
```

2. Replace:

```gdscript
	_stats_label.text = "ATK %d   DEF %d   VEL %d" % [hero.total_attack(),
		hero.total_defense(), hero.speed]
```

with:

```gdscript
	_stats_label.text = "ATK %d   DEF %d   VEL %d" % [hero.total_attack(),
		hero.total_defense(), hero.total_speed()]
```

3. Replace:

```gdscript
	_set_line(_items_message, ("Recuperas %d PM." if result.effect == "mp" \
		else "Recuperas %d PV.") % result.amount)
```

with:

```gdscript
	_set_line(_items_message, _use_text(id, result))
```

4. Replace:

```gdscript
## The three slots with what is worn ("Arma: Palo  ATK +2") and the totals; with a slot
```

with:

```gdscript
## What the menu says after using an item (Inventory.use()'s result).
func _use_text(id: String, result: Dictionary) -> String:
	match result.effect:
		"mp":
			return "Recuperas %d PM." % result.amount
		"seed":
			return "¡%s +%d para siempre!" % [Inventory.seed_stat(id), result.amount]
	return "Recuperas %d PV." % result.amount


## The four slots with what is worn ("Arma: Palo  ATK +2") and the totals; with a slot
```

5. Replace:

```gdscript
				else "%s  %s +%d" % [Equipment.display_name(worn), Equipment.stat_name(worn),
				Equipment.bonus(worn)]]
```

with:

```gdscript
				else "%s  %s" % [Equipment.display_name(worn), Equipment.effect_text(worn)]]
```

6. Replace:

```gdscript
		_equip_box.add_child(_label("ATK %d   DEF %d" % [hero.total_attack(),
			hero.total_defense()], Color.WHITE))
```

with:

```gdscript
		_equip_box.add_child(_label("ATK %d   DEF %d   VEL %d" % [hero.total_attack(),
			hero.total_defense(), hero.total_speed()], Color.WHITE))
```

7. Replace:

```gdscript
		row.add_child(_label("%s +%d" % [Equipment.stat_name(id), Equipment.bonus(id)],
			Color.WHITE))
		row.add_child(ShopWindow.comparison(
			Equipment.bonus(id) - Equipment.bonus(loadout.worn(_equip_slot))))
```

with:

```gdscript
		row.add_child(_label(Equipment.effect_text(id), Color.WHITE))
		if _equip_slot != Equipment.ACCESSORY:
			row.add_child(ShopWindow.comparison(
				Equipment.bonus(id) - Equipment.bonus(loadout.worn(_equip_slot))))
```

In `scripts/game/game.gd`, replace:

```gdscript
	var gear_text := "Oro %d G · Equipo: %s · ATK %d DEF %d" % [state.gold, ", ".join(worn),
		state.hero.total_attack(), state.hero.total_defense()]
```

with:

```gdscript
	var gear_text := "Oro %d G · Equipo: %s · ATK %d DEF %d VEL %d" % [state.gold,
		", ".join(worn), state.hero.total_attack(), state.hero.total_defense(),
		state.hero.total_speed()]
```

- [ ] **Step 5: The save's new slot**

In `scripts/game/save_data.gd`:

1. Replace:

```gdscript
## (StoryState.mark_seen_for_flags()) and the numbers at 0.

const VERSION := 6
## First version with the story's fields.
const STORY_VERSION := 6
```

with:

```gdscript
## (StoryState.mark_seen_for_flags()) and the numbers at 0. QUESTS_VERSION (the side quests)
## adds the accessory slot to the loadout; an older save gets it empty.

const VERSION := 7
## First version with the story's fields.
const STORY_VERSION := 6
## First version with the accessory slot.
const QUESTS_VERSION := 7
```

2. Replace:

```gdscript
	for slot in Equipment.SLOTS:
		var id: Variant = (loadout as Dictionary).get(slot)
```

with:

```gdscript
	for slot in Equipment.SLOTS:
		if slot == Equipment.ACCESSORY and int(data.version) < QUESTS_VERSION:
			continue
		var id: Variant = (loadout as Dictionary).get(slot)
```

- [ ] **Step 6: Check the scripts**

```powershell
$env:APPDATA = "C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\appdata"
New-Item -ItemType Directory -Force $env:APPDATA | Out-Null
foreach ($s in "game/equipment","game/loadout","battle/combatant","battle/battle_engine","battle/battle_event","battle/battle_scene","game/inventory","game/game_state","game/save_data","ui/pause_menu","game/game") { .\tools\godot.cmd --headless --path . --check-only --script "res://scripts/$s.gd" }
```

Expected: no `SCRIPT ERROR` or `ERROR`.

- [ ] **Step 7: Probe the rules**

Write `C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\probes\probe_gear.gd`:

```gdscript
extends SceneTree
## Throwaway check of plan 6b, Task 1. Never committed.


func _init() -> void:
	var state := GameState.new(load("res://data/hero.tres") as Combatant)
	var speed := state.hero.total_speed()
	state.bag_equipment.append(Equipment.SPEED_AMULET)
	state.equip(Equipment.SPEED_AMULET)
	print("amuleto: VEL %d -> %d (espera +3)" % [speed, state.hero.total_speed()])
	state.bag_equipment.append(Equipment.POISON_RING)
	state.equip(Equipment.POISON_RING)
	print("anillo: inmune=%s, amuleto en la bolsa=%s, VEL %d" % [state.hero.is_immune("poison"),
		Equipment.SPEED_AMULET in state.bag_equipment, state.hero.total_speed()])
	var events: Array[Dictionary] = []
	var bat := (load("res://data/enemies/bat.tres") as Combatant).duplicate() as Combatant
	var enemies: Array[Combatant] = [bat]
	var rng := RandomNumberGenerator.new()
	var engine := BattleEngine.new(state.hero, enemies, rng, state.inventory)
	engine._add_status(BattleEvent.HERO, BattleEngine.POISON, events)
	print("veneno con anillo: eventos=%d estado=%s (espera 0, {})" % [events.size(),
		state.hero.status])
	var runner := bat.duplicate() as Combatant
	runner.ai_weights = {"escape": 100}
	runner.speed = 100
	var runners: Array[Combatant] = [runner]
	engine = BattleEngine.new(state.hero, runners, rng, state.inventory)
	var round_events := engine.resolve_round(BattleEngine.cmd_defend())
	print("huida: estado=%d (FLED=%d), último evento=%s" % [engine.state,
		BattleEngine.State.FLED, round_events.back().type])
	state.inventory.add(Inventory.SEED_ATTACK)
	var attack := state.hero.attack
	print("semilla: %s, ATK %d -> %d" % [state.use_item(Inventory.SEED_ATTACK), attack,
		state.hero.attack])
	state.inventory.add(Inventory.SETA)
	print("seta: '%s' / '%s' (espera Para una misión dos veces)" % [
		state.inventory.problem(Inventory.SETA, state.hero, false),
		state.inventory.problem(Inventory.SETA, state.hero, true)])
	var saved: Dictionary = JSON.parse_string(JSON.stringify(SaveData.from_state(state,
		Vector3.ZERO, 1.0)))
	var fresh := GameState.new(load("res://data/hero.tres") as Combatant)
	print("v7: valid=%s anillo=%s ATK=%d" % [SaveData.apply(fresh, saved).valid,
		fresh.loadout.worn(Equipment.ACCESSORY), fresh.hero.attack])
	var old := saved.duplicate(true)
	old.version = 6.0
	(old.loadout as Dictionary).erase(Equipment.ACCESSORY)
	fresh = GameState.new(load("res://data/hero.tres") as Combatant)
	print("v6: valid=%s accesorio='%s'" % [SaveData.apply(fresh, old).valid,
		fresh.loadout.worn(Equipment.ACCESSORY)])
	for key in ["loadout", "bag", "chests", "zone", "town", "flags", "key_items", "portal",
			"explored", "name", "story", "stats"]:
		old.erase(key)
	old.version = 2.0
	fresh = GameState.new(load("res://data/hero.tres") as Combatant)
	print("v2: valid=%s arma=%s accesorio='%s'" % [SaveData.apply(fresh, old).valid,
		fresh.loadout.worn(Equipment.WEAPON), fresh.loadout.worn(Equipment.ACCESSORY)])
	quit()
```

```powershell
$env:APPDATA = "C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\appdata"
.\tools\godot.cmd --headless --path . --script "C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\probes\probe_gear.gd"
```

Expected: `amuleto: VEL 8 -> 11`; `anillo: inmune=true, amuleto en la bolsa=true, VEL 8`; `veneno con anillo: eventos=0 estado={}`; `huida: estado=3 (FLED=3), último evento=enemy_flee`; a seed line with `ATK 10 -> 12`; `Para una misión` twice; `v7: valid=true anillo=anillo_antiveneno ATK=12`; `v6: valid=true accesorio=''`; `v2: valid=true arma=palo accesorio=''`.

- [ ] **Step 8: A game still runs**

```powershell
$env:APPDATA = "C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\appdata"
.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 6000 -- --autoplay --autoplay-save
```

Expected: the `Guardado:` and `Cargado:` JSON lines are identical and hold `"accessory":""`. No ERROR or WARNING other than the known Jolt one.

- [ ] **Step 9: Commit**

```powershell
git add scripts
git commit -m "Add the accessory slot, stat seeds and enemies that run away"
```

---

### Task 2: The quests as rules and data

**Files:**
- Create: `scripts/game/quest_data.gd`, `scripts/game/quest_log.gd`, `scripts/game/quest_rewards.gd`, `data/quests/carta.tres`, `setas.tres`, `lobos.tres`, `gato.tres`, `slime_metal.tres`, `explorador.tres`, `data/enemies/slime_metal.tres`
- Modify: `scripts/game/quest.gd`, `scripts/game/inventory.gd`, `scripts/game/game_state.gd`, `scripts/game/save_data.gd`, `scripts/game/game.gd`, `scripts/battle/enemy_library.gd`, `scripts/battle/battle_actor.gd`, `scripts/world/encounter_table.gd`, `scripts/world/zone_data.gd`, `data/enemies/mushroom.tres`, `data/zones/pradera.tres`
- Temporary (outside the repo): `probes\probe_quests.gd`

**Interfaces:**
- Consumes (Task 1): `Equipment.POISON_RING`, `SPEED_AMULET`, `ACCESSORY`; `Inventory.SETA`, `SEED_*`; `BattleEngine.CMD_ESCAPE`; `SaveData.QUESTS_VERSION`.
- Produces:
  - `QuestData` (`Resource`): `Kind { HUNT, GATHER, DELIVER, FIND }`, `id`, `title`, `kind`, `zone`, `giver`, `turn_in_zone`, `turn_in`, `target`, `target_zone`, `goal`, `key_item`, `objective`, `status`, `report`, `offer_lines`, `found_lines`, `wait_lines`, `done_lines`, `reward_gold`, `reward_items`, `reward_equipment`.
  - `QuestLog` (`RefCounted`, `GameState.quests`): `Stage { OPEN, ACTIVE, REPORT, DONE }`, `QUESTS`, static `data(id) -> QuestData`, static `done_text(title) -> String`, `village: Quest`, `stage(id)`, `count(id)`, `is_active(id)`, `accept(state, id)`, `on_victory(state, enemy_id) -> Array[Dictionary]` (`{title, lines}` of quests finished on the spot), `wanted_enemies() -> Array[String]`, `talk(state, zone_id, figure) -> Dictionary` (`{}` or `{lines: Array[String], done: title or ""}`), `reports_here(zone_id, inventory) -> Array[String]`, `markers(zone_id, inventory) -> Dictionary` (figure name -> "!" or "?"), `hidden_figures(zone_id) -> Array[String]`, `status_lines(inventory) -> Array[String]`, `done_count() -> int`, `journal(inventory) -> Dictionary` (`{active: [{title, text}], done: [title]}`), `to_dict()`, `set_from(data)`.
  - `QuestRewards.give(state, quest) -> Array[String]`.
  - `Quest.TITLE`. `GameState.quests`. `EncounterTable.pick(zone, pos, rng, wanted := [])`. `ZoneData.rare_enemy`, `rare_chance`. `BattleActor.Look.METAL_SLIME`.

- [ ] **Step 1: The quest data class**

Create `scripts/game/quest_data.gd`:

```gdscript
class_name QuestData extends Resource
## One side quest (data/quests/<id>.tres): who offers it, what it asks for, who hears the
## report, what it says and what it pays. QuestLog keeps how far it has gone. Figures are
## called by their ZoneData.npcs "name" (a board's is "Tablón"). Lines may hold
## StoryState.NAME_TAG.

## HUNT: defeat goal enemies of data id target. GATHER: bring goal items of Inventory id
## target (the inventory is the count). DELIVER: take key_item to the turn_in figure. FIND:
## talk to the figure target in target_zone, which is only on the map while it is sought,
## then report.
enum Kind { HUNT, GATHER, DELIVER, FIND }

@export var id := ""
## Its name in the Diario and in "Misión cumplida: ...".
@export var title := ""
@export var kind := Kind.HUNT
## Where it is offered: a zone id and a figure of that zone.
@export var zone := ""
@export var giver := ""
## Who hears the report ("" : it ends on the spot, when the goal is reached).
@export var turn_in_zone := ""
@export var turn_in := ""
@export var target := ""
@export var target_zone := ""
@export var goal := 1
## DELIVER: the Inventory.KEY_ITEMS id handed over with the offer, taken at the end.
@export var key_item := ""
## A sentence for the Diario.
@export var objective := ""
## For the mission lines, after "Misión: ", kept short (the status window fits its longest
## line): with "%d / %d" for a HUNT or GATHER of several; report once it is time to go back.
@export var status := ""
@export var report := ""
## What is said when it is offered, by the target when found (FIND), by the turn_in figure
## while waiting (empty: its chapter lines) and at the end.
@export var offer_lines: Array[String] = []
@export var found_lines: Array[String] = []
@export var wait_lines: Array[String] = []
@export var done_lines: Array[String] = []
## What it pays. No quest gives EXP.
@export var reward_gold := 0
## Inventory id -> how many.
@export var reward_items := {}
## An Equipment id, or "".
@export var reward_equipment := ""
```

- [ ] **Step 2: The six quests**

Create `data/quests/carta.tres`:

```text
[gd_resource type="Resource" script_class="QuestData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/game/quest_data.gd" id="1_quest"]

[resource]
script = ExtResource("1_quest")
id = "carta"
title = "Carta para la Leñadora"
kind = 2
zone = "pradera"
giver = "Granjero"
turn_in_zone = "bosque"
turn_in = "Leñadora"
key_item = "carta_granjero"
objective = "Lleva la carta del Granjero a la Leñadora, en la aldea del bosque."
status = "carta a la Leñadora"
offer_lines = Array[String](["{nombre}, tú que vas a salir por ahí: lleva esta carta a mi hermana, la Leñadora.", "Vive en la aldea del bosque, en cuanto se pueda pasar al norte. Trata de gallinas, pero es urgente."])
done_lines = Array[String](["¿Una carta de mi hermano? A ver... que las gallinas ponen de lado. Eso ya me lo contó.", "Gracias por traerla hasta aquí, {nombre}. Toma, para el camino."])
reward_gold = 60
reward_items = {
"potion": 2
}
```

Create `data/quests/setas.tres`:

```text
[gd_resource type="Resource" script_class="QuestData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/game/quest_data.gd" id="1_quest"]

[resource]
script = ExtResource("1_quest")
id = "setas"
title = "Setas para el guiso"
kind = 1
zone = "pradera"
giver = "Tablón"
turn_in_zone = "pradera"
turn_in = "Granjero"
target = "seta"
goal = 3
objective = "Consigue 3 setas de las Setas saltarinas de la pradera para el Granjero."
status = "setas %d / %d"
report = "setas al Granjero"
offer_lines = Array[String](["Se buscan 3 setas de las que saltan. Son para un guiso. Preguntar por el Granjero.", "Debajo, con otra letra: si saltan, no son setas."])
wait_lines = Array[String](["¿Me traes mis setas? Las que saltan por la pradera son las más sabrosas.", "Cuando dejan de saltar, claro."])
done_lines = Array[String](["¡Tres setas, y casi no se mueven! Esta noche hay guiso.", "Toma, esta semilla me ha salido demasiado buena para las gallinas."])
reward_gold = 40
reward_items = {
"semilla_fuerza": 1
}
```

Create `data/quests/lobos.tres`:

```text
[gd_resource type="Resource" script_class="QuestData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/game/quest_data.gd" id="1_quest"]

[resource]
script = ExtResource("1_quest")
id = "lobos"
title = "Lobos hambrientos"
zone = "bosque"
giver = "Tablón"
turn_in_zone = "bosque"
turn_in = "Leñadora"
target = "lobo"
goal = 5
objective = "Derrota 5 lobos en el bosque para la Leñadora."
status = "lobos %d / %d"
report = "vuelve con la Leñadora"
offer_lines = Array[String](["Se ruega a quien pase por aquí que derrote a 5 lobos. Ya no dejan cortar leña en paz.", "Firmado: la Leñadora. Y debajo: por favor."])
wait_lines = Array[String](["¿Ya has espantado a esos lobos? Todavía los oigo desde aquí.", "Y yo, con el hacha en la mano, sin poder ir a ningún sitio."])
done_lines = Array[String](["¡Por fin se oye el bosque! Y mis árboles.", "Encontré este anillo en un tronco. Dicen que quien lo lleva no le teme al veneno."])
reward_gold = 120
reward_equipment = "anillo_antiveneno"
```

Create `data/quests/gato.tres`:

```text
[gd_resource type="Resource" script_class="QuestData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/game/quest_data.gd" id="1_quest"]

[resource]
script = ExtResource("1_quest")
id = "gato"
title = "El gato perdido"
kind = 3
zone = "bosque"
giver = "Niña"
turn_in_zone = "bosque"
turn_in = "Niña"
target = "Gato"
target_zone = "bosque"
objective = "Busca a Bigotes, el gato de la Niña, por los claros del bosque."
status = "busca a Bigotes"
report = "vuelve con la Niña"
offer_lines = Array[String](["¿Has visto a Bigotes? Es mi gato. Salió detrás de una mariposa y no ha vuelto.", "Le gustan los claros del bosque, los del oeste sobre todo. Yo no puedo ir: hay lobos."])
found_lines = Array[String](["¡Miau!", "Bigotes se frota contra tus piernas y sale corriendo hacia la aldea."])
wait_lines = Array[String](["¿Has encontrado a Bigotes? Si lo ves, dile que hay pescado."])
done_lines = Array[String](["¡Bigotes ha vuelto! Y huele a bosque.", "Toma, es mi semilla de la suerte. Bueno, ya no: te la doy."])
reward_gold = 80
reward_items = {
"semilla_agilidad": 1
}
```

Create `data/quests/slime_metal.tres`:

```text
[gd_resource type="Resource" script_class="QuestData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/game/quest_data.gd" id="1_quest"]

[resource]
script = ExtResource("1_quest")
id = "slime_metal"
title = "El Slime de Metal"
zone = "mina_1"
giver = "Tablón"
target = "slime_metal"
objective = "Derrota al Slime de Metal, que se deja ver por la pradera. Huye en cuanto puede."
status = "Slime de Metal (pradera)"
offer_lines = Array[String](["Se busca: Slime de Metal, visto por la pradera de Villaclaro. Muy rápido y muy duro.", "Se escapa en cuanto puede. Quien lo alcance se quedará con lo que lleva encima."])
reward_equipment = "amuleto_velocidad"
```

Create `data/quests/explorador.tres`:

```text
[gd_resource type="Resource" script_class="QuestData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/game/quest_data.gd" id="1_quest"]

[resource]
script = ExtResource("1_quest")
id = "explorador"
title = "El explorador perdido"
kind = 3
zone = "castillo_patio"
giver = "Tablón"
turn_in_zone = "castillo_patio"
turn_in = "Soldado"
target = "Explorador"
target_zone = "castillo_patio"
objective = "Busca al explorador que no volvió del patio del castillo y avisa al Soldado."
status = "busca al explorador"
report = "vuelve con el Soldado"
offer_lines = Array[String](["Un explorador entró en el patio del castillo y no ha vuelto. Quien lo encuentre, que avise al Soldado.", "También se agradecen noticias de la niebla, pero esas ya las conocemos."])
found_lines = Array[String](["¡Por fin alguien que no traquetea! Llevo dos días escondido de los esqueletos.", "Ahora que miran para otro lado, corro al campamento. ¡Gracias, {nombre}!"])
wait_lines = Array[String](["¿Alguna noticia del explorador? Entró en el patio y hacia el oeste, y hasta ahí sé."])
done_lines = Array[String](["¡Ha llegado entero! Hambriento y hablando solo, pero entero.", "Esto es del fondo de los exploradores. Tú no se lo digas al capitán."])
reward_gold = 250
reward_items = {
"ether": 2,
"semilla_defensa": 1
}
```

In `scripts/game/inventory.gd`:

1. Replace:

```gdscript
	"llave_mina": "Llave de la mina",
}
```

with:

```gdscript
	"llave_mina": "Llave de la mina",
	"carta_granjero": "Carta del Granjero",
}
```

2. Replace:

```gdscript
	"llave_mina": "Abre la reja de la tercera planta de la mina.",
}
```

with:

```gdscript
	"llave_mina": "Abre la reja de la tercera planta de la mina.",
	"carta_granjero": "Para la Leñadora, en la aldea del bosque. Huele un poco a gallina.",
}
```

In `scripts/game/quest.gd`, replace:

```gdscript
const NPC_NAME := "Abuela Rosa"
## Shown for a few seconds when the quest ends; a finished quest is not listed any more.
const DONE_TEXT := "Misión cumplida"
```

with:

```gdscript
const NPC_NAME := "Abuela Rosa"
## Its name in the Diario and in "Misión cumplida: ...".
const TITLE := "Los slimes de Villaclaro"
## Shown for a few seconds when a quest ends (QuestLog.done_text()); a finished quest is not
## listed any more.
const DONE_TEXT := "Misión cumplida"
```

- [ ] **Step 3: The log and the rewards**

Create `scripts/game/quest_rewards.gd`:

```gdscript
class_name QuestRewards extends RefCounted
## Pays a finished quest. Pure: works on a GameState and returns the lines that say so.
## The gold counts as gold won for the credits; a piece of equipment goes on at once if its
## slot is empty, else into the bag, like a chest's.


static func give(state: GameState, quest: QuestData) -> Array[String]:
	var lines: Array[String] = []
	if quest.reward_gold > 0:
		state.gold += quest.reward_gold
		state.gold_earned += quest.reward_gold
		lines.append("Recibes %d monedas de oro." % quest.reward_gold)
	for id: String in quest.reward_items:
		var amount: int = quest.reward_items[id]
		state.inventory.add(id, amount)
		if amount > 1:
			lines.append("Recibes %s ×%d." % [Inventory.display_name(id), amount])
		else:
			lines.append("Recibes %s %s." % [Inventory.article(id), Inventory.display_name(id)])
	if quest.reward_equipment != "":
		lines.append(_give_piece(state, quest.reward_equipment))
	return lines


static func _give_piece(state: GameState, piece: String) -> String:
	var text := "Recibes %s %s." % [Equipment.article(piece), Equipment.display_name(piece)]
	state.bag_equipment.append(piece)
	if state.loadout.worn(Equipment.slot(piece)) == "":
		state.equip(piece)
		text += " Te %s equipas." % Equipment.pronoun(piece)
	return text
```

Create `scripts/game/quest_log.gd`:

```gdscript
class_name QuestLog extends RefCounted
## Every mission: the village quest (Quest) first, then the side quests of QUESTS, each with
## its stage and its count. Says what a figure has to say about them, which marks to show
## and what the mission lines and the Diario read. Pure: Game passes it the GameState,
## shows what it returns and saves to_dict(). A quest never gates anything: the story goes
## on whether or not it is taken or finished.

enum Stage { OPEN, ACTIVE, REPORT, DONE }

const QUESTS := {
	"carta": preload("res://data/quests/carta.tres"),
	"setas": preload("res://data/quests/setas.tres"),
	"lobos": preload("res://data/quests/lobos.tres"),
	"gato": preload("res://data/quests/gato.tres"),
	"slime_metal": preload("res://data/quests/slime_metal.tres"),
	"explorador": preload("res://data/quests/explorador.tres"),
}
const VILLAGE_ZONE := "pradera"
const STATUS_PREFIX := "Misión: "
## Most mission lines shown at once; the rest are in the Diario.
const MAX_STATUS_LINES := 3
const MORE_LINES := "y %d más en el Diario"
const NEW_MARK := "!"
const REPORT_MARK := "?"

## The village quest, the same object as GameState.quest.
var village: Quest
## id -> Stage (OPEN if missing) and id -> enemies defeated (HUNT).
var _stages := {}
var _counts := {}


func _init(p_village: Quest) -> void:
	village = p_village


static func data(id: String) -> QuestData:
	return QUESTS[id] as QuestData


## What show_mission_done() says about a quest with this title.
static func done_text(title: String) -> String:
	return "%s: %s" % [Quest.DONE_TEXT, title]


func stage(id: String) -> Stage:
	return _stages.get(id, Stage.OPEN)


func count(id: String) -> int:
	return _counts.get(id, 0)


func is_active(id: String) -> bool:
	return stage(id) == Stage.ACTIVE or stage(id) == Stage.REPORT


## Takes the quest; a DELIVER hands over what is to be delivered.
func accept(state: GameState, id: String) -> void:
	_stages[id] = Stage.ACTIVE
	var key := data(id).key_item
	if key != "" and not key in state.key_items:
		state.key_items.append(key)


## Counts one enemy of a won battle. Returns {title, lines} of each quest that ended on the
## spot (no one to report to), already paid.
func on_victory(state: GameState, enemy_id: String) -> Array[Dictionary]:
	var finished: Array[Dictionary] = []
	for id: String in QUESTS:
		var quest := data(id)
		if quest.kind != QuestData.Kind.HUNT or quest.target != enemy_id \
				or stage(id) != Stage.ACTIVE:
			continue
		_counts[id] = count(id) + 1
		if count(id) < quest.goal:
			continue
		_stages[id] = Stage.REPORT
		if quest.turn_in == "":
			finished.append({"title": quest.title, "lines": _finish(state, quest)})
	return finished


## The enemies some active quest is hunting (a rare one only comes for them).
func wanted_enemies() -> Array[String]:
	var wanted: Array[String] = []
	for id: String in QUESTS:
		if stage(id) == Stage.ACTIVE and data(id).kind == QuestData.Kind.HUNT:
			wanted.append(data(id).target)
	return wanted


## What this figure says about a quest now, and what that does: a report it was waiting for
## (paid at once), a sought figure found, a new offer (taken), else its waiting lines.
## Returns {"lines": Array[String], "done": title of the quest finished or ""}, or {} when
## it has nothing to say about any.
func talk(state: GameState, zone_id: String, figure: String) -> Dictionary:
	if figure in reports_here(zone_id, state.inventory):
		for id: String in QUESTS:
			var quest := data(id)
			if quest.turn_in_zone == zone_id and quest.turn_in == figure \
					and _is_ready(quest, state.inventory):
				var lines: Array[String] = quest.done_lines.duplicate()
				lines.append_array(_finish(state, quest))
				return {"lines": lines, "done": quest.title}
	for id: String in QUESTS:
		var quest := data(id)
		if quest.kind == QuestData.Kind.FIND and quest.target_zone == zone_id \
				and quest.target == figure and stage(id) == Stage.ACTIVE:
			_stages[id] = Stage.REPORT
			return {"lines": quest.found_lines.duplicate(), "done": ""}
	for id: String in QUESTS:
		var quest := data(id)
		if quest.zone == zone_id and quest.giver == figure and stage(id) == Stage.OPEN:
			accept(state, id)
			return {"lines": quest.offer_lines.duplicate(), "done": ""}
	for id: String in QUESTS:
		var quest := data(id)
		if quest.turn_in_zone == zone_id and quest.turn_in == figure and is_active(id) \
				and not quest.wait_lines.is_empty():
			return {"lines": quest.wait_lines.duplicate(), "done": ""}
	return {}


## The figures of this zone with a report waiting for them.
func reports_here(zone_id: String, inventory: Inventory) -> Array[String]:
	var figures: Array[String] = []
	for id: String in QUESTS:
		var quest := data(id)
		if quest.turn_in_zone == zone_id and _is_ready(quest, inventory):
			figures.append(quest.turn_in)
	return figures


## Figure name -> mark, on this zone: "?" for a report waiting or a figure being sought, "!"
## for a new offer. "?" wins. The Abuela Rosa's are the village quest's.
func markers(zone_id: String, inventory: Inventory) -> Dictionary:
	var marks := {}
	for id: String in QUESTS:
		var quest := data(id)
		if quest.zone == zone_id and stage(id) == Stage.OPEN:
			marks[quest.giver] = NEW_MARK
	if zone_id == VILLAGE_ZONE:
		if village.stage == Quest.Stage.OFFER:
			marks[Quest.NPC_NAME] = NEW_MARK
		elif village.stage == Quest.Stage.REPORT:
			marks[Quest.NPC_NAME] = REPORT_MARK
	for id: String in QUESTS:
		var quest := data(id)
		if quest.kind == QuestData.Kind.FIND and quest.target_zone == zone_id \
				and stage(id) == Stage.ACTIVE:
			marks[quest.target] = REPORT_MARK
	for figure in reports_here(zone_id, inventory):
		marks[figure] = REPORT_MARK
	return marks


## The sought figures of this zone that are not on the map now: only while being sought.
func hidden_figures(zone_id: String) -> Array[String]:
	var hidden: Array[String] = []
	for id: String in QUESTS:
		var quest := data(id)
		if quest.kind == QuestData.Kind.FIND and quest.target_zone == zone_id \
				and stage(id) != Stage.ACTIVE:
			hidden.append(quest.target)
	return hidden


## The mission lines of the quests in progress, village quest first (empty with none);
## GameState.current_missions() is what reads them.
func status_lines(inventory: Inventory) -> Array[String]:
	var lines: Array[String] = []
	var village_line := village.status_text()
	if village_line != "":
		lines.append(village_line)
	for id: String in QUESTS:
		if is_active(id):
			lines.append(STATUS_PREFIX + _status(data(id), inventory))
	var extra := lines.size() - MAX_STATUS_LINES
	if extra > 0:
		lines.resize(MAX_STATUS_LINES)
		lines.append(MORE_LINES % extra)
	return lines


## Missions finished, the village quest included: what the credits count.
func done_count() -> int:
	var done := 1 if village.stage == Quest.Stage.DONE else 0
	for id: String in QUESTS:
		if stage(id) == Stage.DONE:
			done += 1
	return done


## For the Diario: {"active": [{"title", "text"}], "done": [titles]}.
func journal(inventory: Inventory) -> Dictionary:
	var active: Array[Dictionary] = []
	var done: Array[String] = []
	var village_line := village.status_text()
	if village_line != "":
		active.append({"title": Quest.TITLE,
			"text": _sentence(village_line.trim_prefix(STATUS_PREFIX))})
	elif village.stage == Quest.Stage.DONE:
		done.append(Quest.TITLE)
	for id: String in QUESTS:
		var quest := data(id)
		if is_active(id):
			active.append({"title": quest.title, "text": _journal_text(quest, inventory)})
		elif stage(id) == Stage.DONE:
			done.append(quest.title)
	return {"active": active, "done": done}


## For the save: only the quests already taken.
func to_dict() -> Dictionary:
	var saved := {}
	for id: String in _stages:
		saved[id] = {"stage": _stages[id], "count": count(id)}
	return saved


## Loads what to_dict() wrote (JSON numbers come back as floats); unknown ids are dropped.
func set_from(saved: Dictionary) -> void:
	_stages = {}
	_counts = {}
	for id: String in saved:
		if not QUESTS.has(id):
			continue
		_stages[id] = clampi(int(saved[id].stage), Stage.OPEN, Stage.DONE) as Stage
		_counts[id] = int(saved[id].count)


## Time to go to the turn_in figure.
func _is_ready(quest: QuestData, inventory: Inventory) -> bool:
	match stage(quest.id):
		Stage.REPORT:
			return true
		Stage.ACTIVE:
			if quest.kind == QuestData.Kind.DELIVER:
				return true
			if quest.kind == QuestData.Kind.GATHER:
				return inventory.count(quest.target) >= quest.goal
	return false


## Takes what was asked for, marks it done and pays. Returns what the payment says.
func _finish(state: GameState, quest: QuestData) -> Array[String]:
	if quest.kind == QuestData.Kind.GATHER:
		for i in quest.goal:
			state.inventory.take(quest.target)
	if quest.key_item != "":
		state.key_items.erase(quest.key_item)
	_stages[quest.id] = Stage.DONE
	return QuestRewards.give(state, quest)


## HUNT and GATHER: how many of the goal so far.
func _progress(quest: QuestData, inventory: Inventory) -> int:
	if quest.kind == QuestData.Kind.GATHER:
		return mini(inventory.count(quest.target), quest.goal)
	return count(quest.id)


func _status(quest: QuestData, inventory: Inventory) -> String:
	if _is_ready(quest, inventory) and quest.report != "":
		return quest.report
	if quest.status.contains("%d"):
		return quest.status % [_progress(quest, inventory), quest.goal]
	return quest.status


func _journal_text(quest: QuestData, inventory: Inventory) -> String:
	if _is_ready(quest, inventory) and quest.report != "":
		return _sentence(quest.report)
	if quest.goal > 1:
		return "%s (%d / %d)" % [quest.objective, _progress(quest, inventory), quest.goal]
	return quest.objective


## text with a capital and a full stop, for a mission line said in the Diario.
static func _sentence(text: String) -> String:
	return "%s%s." % [text.left(1).to_upper(), text.substr(1)]
```

In `scripts/game/game_state.gd`:

1. Replace:

```gdscript
var quest := Quest.new()
```

with:

```gdscript
var quest := Quest.new()
## Every mission: the village quest above and the side quests.
var quests := QuestLog.new(quest)
```

2. Replace:

```gdscript
## The missions under way, for the map's status window and the pause menu; never empty:
## with none in progress, the story's next step. The one place that reads them: the story's
## quest log only has to change this.
func current_missions() -> Array[String]:
	var missions: Array[String] = []
	var line := quest.status_text()
	if line != "":
		missions.append(line)
	if missions.is_empty():
```

with:

```gdscript
## The missions under way, for the map's status window and the pause menu; never empty:
## with none in progress, the story's next step. The one place that reads them.
func current_missions() -> Array[String]:
	var missions := quests.status_lines(inventory)
	if missions.is_empty():
```

3. Replace:

```gdscript
## Quests completed, for the credits: the village quest.
func quests_done() -> int:
	return 1 if quest.stage == Quest.Stage.DONE else 0
```

with:

```gdscript
## Quests completed, for the credits.
func quests_done() -> int:
	return quests.done_count()
```

In `scripts/game/save_data.gd`:

1. Replace:

```gdscript
## adds the accessory slot to the loadout; an older save gets it empty.
```

with:

```gdscript
## adds the accessory slot to the loadout and the side quests' progress; an older save gets
## the slot empty and no side quest taken.
```

2. Replace:

```gdscript
## First version with the accessory slot.
```

with:

```gdscript
## First version with the accessory slot and the side quests.
```

3. Replace:

```gdscript
		"stats": {"battles": state.battles, "steps": state.steps, "gold": state.gold_earned},
```

with:

```gdscript
		"stats": {"battles": state.battles, "steps": state.steps, "gold": state.gold_earned},
		"quests": state.quests.to_dict(),
```

4. Replace:

```gdscript
		state.gold_earned = 0
	var pos: Array = data.position
```

with:

```gdscript
		state.gold_earned = 0
	state.quests.set_from(data.get("quests", {}))
	var pos: Array = data.position
```

5. Replace:

```gdscript
	if int(data.version) >= STORY_VERSION and not _valid_story(data):
		return false
```

with:

```gdscript
	if int(data.version) >= STORY_VERSION and not _valid_story(data):
		return false
	if int(data.version) >= QUESTS_VERSION and not _valid_quests(data):
		return false
```

6. Replace:

```gdscript
## STORY_VERSION fields: a name StoryState.clean_name() keeps as it is, the story's seen
```

with:

```gdscript
## QUESTS_VERSION field: quest id -> its stage and count.
static func _valid_quests(data: Dictionary) -> bool:
	var quests: Variant = data.get("quests")
	if not quests is Dictionary:
		return false
	for id: Variant in quests:
		if not (id is String and QuestLog.QUESTS.has(id)):
			return false
		var entry: Variant = quests[id]
		if not (entry is Dictionary and entry.get("stage") is float \
				and entry.get("count") is float):
			return false
	return true


## STORY_VERSION fields: a name StoryState.clean_name() keeps as it is, the story's seen
```

- [ ] **Step 4: The Slime de Metal and the Setas**

Create `data/enemies/slime_metal.tres`:

```text
[gd_resource type="Resource" script_class="Combatant" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/battle/combatant.gd" id="1_combatant"]

[resource]
script = ExtResource("1_combatant")
id = "slime_metal"
display_name = "Slime de Metal"
max_hp = 40
hp = 40
attack = 28
defense = 300
speed = 30
exp_reward = 300
gold_reward = 150
ai_weights = {
"attack": 35,
"escape": 50,
"stagger": 15
}
resist = Array[String](["fire", "ice", "thunder"])
```

In `data/enemies/mushroom.tres`, replace:

```text
drops = {
"ether": 0.1
}
```

with:

```text
drops = {
"ether": 0.1,
"seta": 0.5
}
```

In `scripts/battle/enemy_library.gd`:

1. Replace:

```gdscript
	"senor_niebla": preload("res://data/enemies/senor_niebla.tres"),
```

with:

```gdscript
	"senor_niebla": preload("res://data/enemies/senor_niebla.tres"),
	"slime_metal": preload("res://data/enemies/slime_metal.tres"),
```

2. Replace:

```gdscript
	"senor_niebla": BattleActor.Look.FOG_LORD,
```

with:

```gdscript
	"senor_niebla": BattleActor.Look.FOG_LORD,
	"slime_metal": BattleActor.Look.METAL_SLIME,
```

In `scripts/battle/battle_actor.gd`:

1. Replace:

```gdscript
	SKELETON_ROGUE, SKELETON_MAGE, FOG_LORD, FARMER }
```

with:

```gdscript
	SKELETON_ROGUE, SKELETON_MAGE, FOG_LORD, FARMER, METAL_SLIME }
```

2. Replace:

```gdscript
	Look.KING_SLIME: {
		"color": Color(0.3, 0.45, 0.9),
		"scale": 1.6,
		"top": 2.1,
		"crown": true,
	},
```

with:

```gdscript
	Look.KING_SLIME: {
		"color": Color(0.3, 0.45, 0.9),
		"scale": 1.6,
		"top": 2.1,
		"crown": true,
	},
	Look.METAL_SLIME: {
		"color": Color(0.78, 0.82, 0.88),
		"scale": 0.8,
		"top": 1.1,
		"crown": false,
	},
```

In `scripts/world/zone_data.gd`, replace:

```gdscript
## EncounterMeter: free meters after each battle, then this chance per meter on grass.
```

with:

```gdscript
## An enemy that only comes while a quest hunts it, alone, with this chance per encounter
## (EnemyLibrary id, "" for none).
@export var rare_enemy := ""
@export var rare_chance := 0.0
## EncounterMeter: free meters after each battle, then this chance per meter on grass.
```

In `data/zones/pradera.tres`, replace:

```text
start_radius = 20.0
```

with:

```text
start_radius = 20.0
rare_enemy = "slime_metal"
rare_chance = 0.25
```

In `scripts/world/encounter_table.gd`:

1. Replace:

```gdscript
## one enemy at a time at the forest's entry); elsewhere every formation of the zone has
## the same weight. Pure: no nodes.
```

with:

```gdscript
## one enemy at a time at the forest's entry); elsewhere every formation of the zone has
## the same weight. The zone's rare enemy comes instead, alone, now and then, if a quest
## wants it. Pure: no nodes.
```

2. Replace:

```gdscript
static func pick(zone: ZoneData, pos: Vector3, rng: RandomNumberGenerator) -> Array[Combatant]:
```

with:

```gdscript
static func pick(zone: ZoneData, pos: Vector3, rng: RandomNumberGenerator,
		wanted: Array[String] = []) -> Array[Combatant]:
	if zone.rare_enemy in wanted and rng.randf() < zone.rare_chance:
		return EnemyLibrary.formation([zone.rare_enemy])
```

- [ ] **Step 5: Victories count**

In `scripts/game/game.gd`:

1. Replace:

```gdscript
		enemies = EncounterTable.pick(_zone, _world.player_position(), _rng)
```

with:

```gdscript
		enemies = EncounterTable.pick(_zone, _world.player_position(), _rng,
			state.quests.wanted_enemies())
```

2. Replace:

```gdscript
	var mission_done := false
	if won:
```

with:

```gdscript
	var mission_done := false
	var finished_quests: Array[Dictionary] = []
	if won:
```

3. Replace:

```gdscript
		mission_done = quest_was_on and state.quest.stage == Quest.Stage.DONE
```

with:

```gdscript
		mission_done = quest_was_on and state.quest.stage == Quest.Stage.DONE
		for enemy in battle.engine.enemies:
			finished_quests.append_array(state.quests.on_victory(state, enemy.id))
```

4. Replace:

```gdscript
	if mission_done:
		_world.show_mission_done(Quest.DONE_TEXT)
```

with:

```gdscript
	if mission_done:
		_world.show_mission_done(QuestLog.done_text(Quest.TITLE))
	for finished: Dictionary in finished_quests:
		_world.show_mission_done(QuestLog.done_text(finished.title))
		_world.show_notice(" ".join(finished.lines))
```

- [ ] **Step 6: Check the scripts**

```powershell
$env:APPDATA = "C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\appdata"
New-Item -ItemType Directory -Force $env:APPDATA | Out-Null
.\tools\godot.cmd --headless --path . --import
foreach ($s in "game/quest_data","game/quest_log","game/quest_rewards","game/quest","game/inventory","game/game_state","game/save_data","game/game","battle/enemy_library","battle/battle_actor","world/encounter_table","world/zone_data") { .\tools\godot.cmd --headless --path . --check-only --script "res://scripts/$s.gd" }
```

Expected: no `SCRIPT ERROR` or `ERROR`.

- [ ] **Step 7: Probe the rules**

Write `C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\probes\probe_quests.gd`:

```gdscript
extends SceneTree
## Throwaway check of plan 6b, Task 2. Never committed.


func _init() -> void:
	var state := GameState.new(load("res://data/hero.tres") as Combatant)
	state.quest.stage = Quest.Stage.DONE
	var log := state.quests
	print("sin misiones: ", state.current_missions())
	print("marcas pradera: ", log.markers("pradera", state.inventory))
	print("ocultos bosque: ", log.hidden_figures("bosque"))
	print("carta: ", log.talk(state, "pradera", "Granjero").lines[0], " | llave: ", state.key_items)
	print("tablón: ", log.talk(state, "pradera", "Tablón").lines[0])
	print("líneas: ", state.current_missions())
	state.inventory.add(Inventory.SETA, 3)
	print("marcas con setas: ", log.markers("pradera", state.inventory))
	var setas := log.talk(state, "pradera", "Granjero")
	print("setas: done=%s %s, quedan %d, semillas %d" % [setas.done, setas.lines,
		state.inventory.count(Inventory.SETA), state.inventory.count(Inventory.SEED_ATTACK)])
	var carta := log.talk(state, "bosque", "Leñadora")
	print("carta entregada: done=%s %s | llave: %s" % [carta.done, carta.lines, state.key_items])
	log.talk(state, "bosque", "Tablón")
	for i in 5:
		log.on_victory(state, "lobo")
	print("lobos: ", state.current_missions())
	var lobos := log.talk(state, "bosque", "Leñadora")
	print("lobos: done=%s accesorio=%s %s" % [lobos.done,
		state.loadout.worn(Equipment.ACCESSORY), state.hero.is_immune("poison")])
	log.talk(state, "bosque", "Niña")
	print("gato en el mapa: ", log.hidden_figures("bosque"), " marcas ",
		log.markers("bosque", state.inventory))
	print("gato: ", log.talk(state, "bosque", "Gato").lines)
	print("gato oculto: ", log.hidden_figures("bosque"), " marcas ",
		log.markers("bosque", state.inventory))
	print("informe: ", log.talk(state, "bosque", "Niña").done)
	log.talk(state, "mina_1", "Tablón")
	print("quiere: ", log.wanted_enemies())
	var zone := ZoneData.by_id("pradera")
	var rng := RandomNumberGenerator.new()
	var rare := 0
	for i in 1000:
		var picked := EncounterTable.pick(zone, Vector3.ZERO, rng, log.wanted_enemies())
		if picked[0].id == "slime_metal":
			rare += 1
	print("raro en 1000: %d (espera unos 250)" % rare)
	print("amuleto: ", log.on_victory(state, "slime_metal"), " bolsa ", state.bag_equipment)
	print("diario: ", log.journal(state.inventory))
	print("hechas: %d" % state.quests_done())
	var saved: Dictionary = JSON.parse_string(JSON.stringify(SaveData.from_state(state,
		Vector3.ZERO, 1.0)))
	var fresh := GameState.new(load("res://data/hero.tres") as Combatant)
	print("v7: valid=%s hechas=%d iguales=%s" % [SaveData.apply(fresh, saved).valid,
		fresh.quests_done(), JSON.stringify(fresh.quests.to_dict(), "", true) \
		== JSON.stringify(log.to_dict(), "", true)])
	var old := saved.duplicate(true)
	old.version = 6.0
	old.erase("quests")
	(old.loadout as Dictionary).erase(Equipment.ACCESSORY)
	fresh = GameState.new(load("res://data/hero.tres") as Combatant)
	print("v6: valid=%s hechas=%d" % [SaveData.apply(fresh, old).valid, fresh.quests_done()])
	quit()
```

```powershell
$env:APPDATA = "C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\appdata"
.\tools\godot.cmd --headless --path . --script "C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\probes\probe_quests.gd"
```

Expected: `sin misiones` shows the story's goal; the meadow's marks are `Granjero: !`, `Tablón: !`; hidden in the forest are `Gato`; the letter goes into `key_items` and out again; `setas: done=Setas para el guiso`, 0 Setas left, 1 seed; lobos `vuelve con la Leñadora`, then `accesorio=anillo_antiveneno true`; the cat shows only while sought, with a `?`; about 250 rare picks; the amulet goes to the bag because the ring is worn; `hechas: 6` (the village quest and five of the side ones, the rescue not taken); `v7: valid=true hechas=6 iguales=true`; `v6: valid=true hechas=1`.

- [ ] **Step 8: A game still runs**

```powershell
$env:APPDATA = "C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\appdata"
.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 6000 -- --autoplay --autoplay-save
```

Expected: the `Guardado:` and `Cargado:` JSON lines are identical and hold `"quests":{}` and `"version":7`. No ERROR or WARNING other than the known Jolt one.

- [ ] **Step 9: Commit**

```powershell
git add scripts data
git commit -m "Keep the missions in a quest log with six side quests as data"
```

---

### Task 3: Boards, villagers and marks on the map

**Files:**
- Modify: `scripts/battle/battle_actor.gd`, `scripts/world/world.gd`, `scripts/world/world_stage.gd`, `scripts/world/zone_data.gd`, `scripts/game/game.gd`, `data/zones/pradera.tres`, `data/zones/bosque.tres`, `data/zones/mina_1.tres`, `data/zones/castillo_patio.tres`
- Temporary (outside the repo): `probes\probe_metal.gd`

**Interfaces:**
- Consumes (Task 2): `QuestLog.talk(state, zone_id, figure) -> Dictionary`, `markers(zone_id, inventory)`, `hidden_figures(zone_id)`, `reports_here(zone_id, inventory)`, `QuestLog.done_text(title)`; figure names `Tablón`, `Granjero`, `Leñadora`, `Niña`, `Gato`, `Soldado`, `Explorador` as the `.tres` quests call them. `Inventory.SEEDS`.
- Produces: `BattleActor.Look.BOARD`, `CAT`, `CHILD`; `ZoneData.npcs` kind `"board"`; `World.BOARD`, `World.set_quest_view(marks: Dictionary, hidden_names: Array[String])`; `Game._on_npc()` asks the log first.

| Figure | Zone | Look | Position | Next to autoplay's route |
|---|---|---|---|---|
| Tablón | `pradera` | `BOARD` | (2.8, 0, −17.3) | the way back south from the north exit |
| Tablón | `bosque` | `BOARD` | (−8.2, 0, 7) | (−3, 10.5) to (−8.9, 3.9) |
| Niña | `bosque` | `CHILD` | (−11.2, 0, 6) | (−8.9, 3.9) to (−13.4, 4) |
| Gato | `bosque` | `CAT` | (−20.6, 0, −21) | (−18.8, −22.2), by the west glade's chest |
| Tablón | `mina_1` | `BOARD` | (−3, 0, 17) | (0, 17) to (−6.5, 12.5) |
| Tablón | `castillo_patio` | `BOARD` | (2.5, 0, 14.5) | (0, 16) to (0, 12) |
| Explorador | `castillo_patio` | `FARMER` | (−20.5, 0, 0.5) | (−20, −4) to (−23, 0), by the west chest |

- [ ] **Step 1: The board, the cat and the child**

In `scripts/battle/battle_actor.gd`:

1. Replace:

```gdscript
	SKELETON_ROGUE, SKELETON_MAGE, FOG_LORD, FARMER, METAL_SLIME }
```

with:

```gdscript
	SKELETON_ROGUE, SKELETON_MAGE, FOG_LORD, FARMER, METAL_SLIME, BOARD, CAT, CHILD }
```

2. Replace:

```gdscript
		"tint": Color(0.65, 0.8, 1.0),
	},
	Look.SLIME: {
```

with:

```gdscript
		"tint": Color(0.65, 0.8, 1.0),
	},
	# The Niña of the forest village: a small Mage in pink.
	Look.CHILD: {
		"scene": MAGE,
		"scale": 0.48,
		"top": 1.7,
		"hide": [
			"Rig/Skeleton3D/handslot_l/Spellbook",
			"Rig/Skeleton3D/handslot_l/Spellbook_open",
			"Rig/Skeleton3D/handslot_r/1H_Wand",
		],
		"anims": CHARACTER_ANIMS,
		"tint": Color(1.0, 0.72, 0.8),
	},
	# A notice board: it stands still.
	Look.BOARD: {
		"color": Color(0.56, 0.38, 0.2),
		"dark_color": Color(0.36, 0.22, 0.1),
		"paper_color": Color(0.93, 0.89, 0.75),
		"top": 1.9,
	},
	Look.CAT: {
		"color": Color(0.85, 0.55, 0.25),
		"dark_color": Color(0.62, 0.36, 0.14),
		"eye_color": Color(0.2, 0.75, 0.3),
		"scale": 1.2,
		"top": 1.2,
	},
	Look.SLIME: {
```

3. Replace:

```gdscript
	elif look == Look.SPECTER:
		_build_specter(data)
	else:
```

with:

```gdscript
	elif look == Look.SPECTER:
		_build_specter(data)
	elif look == Look.BOARD:
		_build_board(data)
	elif look == Look.CAT:
		_build_cat(data)
	else:
```

4. Replace:

```gdscript
func _start_idle() -> void:
	if not _wings.is_empty():
```

with:

```gdscript
func _start_idle() -> void:
	if look == Look.BOARD:
		return
	if not _wings.is_empty():
```

5. Replace:

```gdscript
		var gentle := look in [Look.WOLF, Look.MUD_GOLEM, Look.STONE_GOLEM, Look.SPIDER]
```

with:

```gdscript
		var gentle := look in [Look.WOLF, Look.MUD_GOLEM, Look.STONE_GOLEM, Look.SPIDER,
			Look.CAT]
```

6. Replace:

```gdscript
## A bat: round body with ears and eyes, hovering at data.fly, with two wings on pivots
```

with:

```gdscript
## A notice board on two posts, with its papers on the side it faces (-Z).
func _build_board(data: Dictionary) -> void:
	var post := BoxMesh.new()
	post.size = Vector3(0.12, 1.7, 0.12)
	for x in [-0.6, 0.6]:
		_add_mesh(_body, post, data.dark_color, Vector3(x, 0.85, 0))
	var board := BoxMesh.new()
	board.size = Vector3(1.5, 0.9, 0.08)
	_add_mesh(_body, board, data.color, Vector3(0, 1.3, 0))
	var paper := BoxMesh.new()
	paper.size = Vector3(0.32, 0.4, 0.01)
	for spot in [Vector3(-0.42, 1.32, -0.05), Vector3(0.02, 1.26, -0.05),
			Vector3(0.44, 1.36, -0.05)]:
		_add_mesh(_body, paper, data.paper_color, spot)


## A sitting cat: a rounded body, a head with pointed ears and eyes, and a tail.
func _build_cat(data: Dictionary) -> void:
	var root := Node3D.new()
	root.scale = Vector3.ONE * data.scale
	_body.add_child(root)
	_add_blob(root, SLIME_PROFILE, SLIME_SEGMENTS, data.color, Vector3.ZERO, Vector3.ZERO,
		Vector3(0.5, 0.6, 0.65))
	_add_mesh(root, _sphere(0.2), data.color, Vector3(0, 0.62, -0.1))
	for x in [-0.11, 0.11]:
		_add_mesh(root, _cone(0.07, 0.16), data.dark_color, Vector3(x, 0.84, -0.1))  # ear
		_add_mesh(root, _sphere(0.04), data.eye_color, Vector3(x * 0.8, 0.66, -0.28))  # eye
	_add_mesh(root, _cylinder(0.04, 0.5), data.dark_color, Vector3(0, 0.22, 0.4))  # tail
	(root.get_child(-1) as Node3D).rotation_degrees.x = 60.0


## A bat: round body with ears and eyes, hovering at data.fly, with two wings on pivots
```

- [ ] **Step 2: The figures on the zones**

In `scripts/world/zone_data.gd`, replace:

```gdscript
## Each figure: {"kind": "quest" (the old woman), "shop", "inn" or "npc", "id" (Shop /
## Inn id), "look" (BattleActor.Look name), "pos", "yaw" (0 faces -Z; 180 faces the
```

with:

```gdscript
## Each figure: {"kind": "quest" (the old woman), "shop", "inn", "npc" or "board" (a notice
## board: read, not talked to), "id" (Shop /
## Inn id), "look" (BattleActor.Look name), "pos", "yaw" (0 faces -Z; 180 faces the
```

In `data/zones/pradera.tres`, replace:

```text
"pos": Vector3(3.5, 0, -15.5),
"yaw": 180.0
}]
```

with:

```text
"pos": Vector3(3.5, 0, -15.5),
"yaw": 180.0
}, {
"kind": "board",
"lines": ["Aviso viejo: se vende gallina que pone de lado. Razón, el Granjero.", "Otro más viejo aún: se regala gallina."],
"look": "BOARD",
"name": "Tablón",
"pos": Vector3(2.8, 0, -17.3),
"yaw": 180.0
}]
```

In `data/zones/bosque.tres`, replace:

```text
"pos": Vector3(-10.46, 0, -2.23),
"yaw": 180.0
}]
```

with:

```text
"pos": Vector3(-10.46, 0, -2.23),
"yaw": 180.0
}, {
"kind": "board",
"lines": ["Aviso: el pozo no concede deseos. Dejen de tirar monedas.", "Debajo: entonces, ¿quién se las lleva?"],
"look": "BOARD",
"name": "Tablón",
"pos": Vector3(-8.2, 0, 7),
"yaw": 180.0
}, {
"kind": "npc",
"lines": ["Cuando sea mayor quiero ser leñadora. O gato."],
"lines_by_chapter": {
5: ["¿Has visto el cielo? Bigotes dice que ya era hora. Bueno, lo dice a su manera."]
},
"look": "CHILD",
"name": "Niña",
"pos": Vector3(-11.2, 0, 6),
"yaw": 180.0
}, {
"kind": "npc",
"look": "CAT",
"name": "Gato",
"pos": Vector3(-20.6, 0, -21),
"yaw": 120.0
}]
```

In `data/zones/mina_1.tres`, replace:

```text
"pos": Vector3(-10, 0, 19),
"yaw": 180.0
}]
```

with:

```text
"pos": Vector3(-10, 0, 19),
"yaw": 180.0
}, {
"kind": "board",
"lines": ["Aviso: quien coja un pico prestado, que lo devuelva.", "Debajo, con la letra de la Minera: y sin mellas."],
"look": "BOARD",
"name": "Tablón",
"pos": Vector3(-3, 0, 17),
"yaw": 180.0
}]
```

In `data/zones/castillo_patio.tres`, replace:

```text
"pos": Vector3(-5, 0, 23),
"yaw": 180.0
}]
```

with:

```text
"pos": Vector3(-5, 0, 23),
"yaw": 180.0
}, {
"kind": "board",
"lines": ["Parte del día: niebla. Parte de ayer: niebla.", "Debajo: parte de mañana, a que no lo adivinas."],
"look": "BOARD",
"name": "Tablón",
"pos": Vector3(2.5, 0, 14.5),
"yaw": 180.0
}, {
"kind": "npc",
"look": "FARMER",
"name": "Explorador",
"pos": Vector3(-20.5, 0, 0.5),
"yaw": 90.0
}]
```

In `scripts/world/world_stage.gd`:

1. Replace:

```gdscript
const CHEST_GRASS_MARGIN := 1.0
```

with:

```gdscript
const CHEST_GRASS_MARGIN := 1.0
const FIGURE_GRASS_MARGIN := 1.0
```

2. Replace:

```gdscript
## Where tall grass may grow: off the path and the safe discs (the village is inside one),
## the rocks, the buildings and the chests.
static func is_grass_free(pos: Vector3, zone: ZoneData) -> bool:
	if is_on_path(zone, pos, GRASS_PATH_MARGIN) or _near_chest(zone, pos, CHEST_GRASS_MARGIN):
		return false
```

with:

```gdscript
## Where tall grass may grow: off the path and the safe discs (the village is inside one),
## the rocks, the buildings, the chests and the figures.
static func is_grass_free(pos: Vector3, zone: ZoneData) -> bool:
	if is_on_path(zone, pos, GRASS_PATH_MARGIN) or _near_chest(zone, pos, CHEST_GRASS_MARGIN) \
			or _near_figure(zone, pos):
		return false
```

3. Replace:

```gdscript
## True within margin of one of the zone's chests (Chests.CHESTS of this zone). The
```

with:

```gdscript
## True within FIGURE_GRASS_MARGIN of one of the zone's figures (a cat would be lost in the
## grass).
static func _near_figure(zone: ZoneData, pos: Vector3) -> bool:
	var p := Vector2(pos.x, pos.z)
	for npc: Dictionary in zone.npcs:
		if p.distance_to(Vector2(npc.pos.x, npc.pos.z)) < FIGURE_GRASS_MARGIN:
			return true
	return false


## True within margin of one of the zone's chests (Chests.CHESTS of this zone). The
```

- [ ] **Step 3: Marks and hidden figures on the map**

In `scripts/world/world.gd`:

1. Replace:

```gdscript
## the map). Run on its own (res://scenes/world/world.tscn) it prints each encounter,
## talk, shop, inn, chest and exit and goes on.
```

with:

```gdscript
## the map). A "!" or "?" floats over a figure with something about a quest, and a figure a
## quest has not brought out is not on the map (set_quest_view()). Run on its own
## (res://scenes/world/world.tscn) it prints each encounter, talk, shop, inn, chest and exit
## and goes on.
```

2. Replace:

```gdscript
## The player talked to the villager zone.npcs[index] (kind "npc").
```

with:

```gdscript
## The player talked to the villager zone.npcs[index] (kind "npc") or read the board (kind
## "board").
```

3. Replace:

```gdscript
const PORTAL := "portal"
const PROMPTS := {
```

with:

```gdscript
const PORTAL := "portal"
const BOARD := "board"
const PROMPTS := {
```

4. Replace:

```gdscript
	PORTAL: "Enter o toca: volver",
}
## ZoneData.npcs kinds -> use kinds.
const NPC_KINDS := {"quest": TALK, "npc": NPC, "shop": SHOP, "inn": INN}
```

with:

```gdscript
	PORTAL: "Enter o toca: volver",
	BOARD: "Enter o toca: leer",
}
## ZoneData.npcs kinds -> use kinds.
const NPC_KINDS := {"quest": TALK, "npc": NPC, "shop": SHOP, "inn": INN, "board": BOARD}
```

5. Replace:

```gdscript
const LANTERN_HEIGHT := 2.4
```

with:

```gdscript
const LANTERN_HEIGHT := 2.4
## The "!" and "?" of the quests: over the figure, bobbing.
const QUEST_MARK_COLOR := Color(1.0, 0.85, 0.2)
const QUEST_MARK_GAP := 0.35
const QUEST_MARK_BOB := 0.12
```

6. Replace:

```gdscript
var _step_m := 0.0
```

with:

```gdscript
var _step_m := 0.0
## Figure name -> "!" or "?", the figures that are not on the map, and the labels so far.
var _quest_marks := {}
var _hidden_figures: Array[String] = []
var _mark_labels := {}
```

7. Replace:

```gdscript
	elif not near.is_empty() and near != _was_near and _autoplay and near.kind != PORTAL:
		# Autoplay talks to each villager once per visit to the zone.
		if near.kind != NPC or not _autoplay_talked.has(near.index):
			_autoplay_talked[near.index] = true
			_use(near)
```

with:

```gdscript
	elif not near.is_empty() and near != _was_near and _autoplay and near.kind != PORTAL:
		# Autoplay talks to each villager once per visit to the zone, and again when a
		# mark over it says there is something new.
		var chats: bool = near.kind == NPC or near.kind == BOARD
		if not chats or not _autoplay_talked.has(near.index) \
				or _quest_marks.has(zone.npcs[near.index].name):
			_autoplay_talked[near.index] = true
			_use(near)
```

8. Replace:

```gdscript
	_status_column.hide()
	_notice_window.hide()
```

with:

```gdscript
	_status_column.hide()
	_notice_window.hide()
	_show_quest_marks()
```

9. Replace:

```gdscript
	_player.scripted = false
	_status_column.show()
```

with:

```gdscript
	_player.scripted = false
	_status_column.show()
	_show_quest_marks()
```

10. Replace:

```gdscript
## Shows the weapon and shield worn on the hero (Equipment ids, "" for none).
```

with:

```gdscript
## What the quests show on this map (Game passes GameState.quests' answers): marks is figure
## name -> "!" or "?"; hidden_names are figures not on the map now, with no collider and
## nothing to use.
func set_quest_view(marks: Dictionary, hidden_names: Array[String]) -> void:
	_quest_marks = marks
	_hidden_figures = hidden_names
	for npc: Dictionary in zone.npcs:
		var body: StaticBody3D = _figures[npc.name]
		var shown := not hidden_names.has(npc.name)
		body.visible = shown
		body.process_mode = Node.PROCESS_MODE_INHERIT if shown else Node.PROCESS_MODE_DISABLED
	_show_quest_marks()


## One floating label per figure with a mark; none during a cutscene.
func _show_quest_marks() -> void:
	for npc: Dictionary in zone.npcs:
		var text: String = _quest_marks.get(npc.name, "")
		var label: Label3D = _mark_labels.get(npc.name)
		if label == null:
			if text == "":
				continue
			label = _build_mark(npc.name)
		label.text = text
		label.visible = text != "" and not _player.scripted


func _build_mark(figure_name: String) -> Label3D:
	var label := Label3D.new()
	label.font_size = 96
	label.pixel_size = 0.01
	label.outline_size = 16
	label.modulate = QUEST_MARK_COLOR
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.position.y = figure_actor(figure_name).top_height() + QUEST_MARK_GAP
	(_figures[figure_name] as Node3D).add_child(label)
	_mark_labels[figure_name] = label
	var bob := label.create_tween().set_loops()
	bob.tween_property(label, "position:y", label.position.y + QUEST_MARK_BOB, 0.5) \
		.set_trans(Tween.TRANS_SINE)
	bob.tween_property(label, "position:y", label.position.y, 0.5).set_trans(Tween.TRANS_SINE)
	return label


## Shows the weapon and shield worn on the hero (Equipment ids, "" for none).
```

11. Replace:

```gdscript
		var npc: Dictionary = zone.npcs[i]
		uses.append({"kind": NPC_KINDS[npc.kind], "id": npc.get("id", ""), "index": i,
```

with:

```gdscript
		var npc: Dictionary = zone.npcs[i]
		if _hidden_figures.has(npc.name):
			continue
		uses.append({"kind": NPC_KINDS[npc.kind], "id": npc.get("id", ""), "index": i,
```

12. Replace:

```gdscript
		NPC:
			npc_requested.emit(use.index)
```

with:

```gdscript
		NPC, BOARD:
			npc_requested.emit(use.index)
```

- [ ] **Step 4: Talking about quests**

In `scripts/game/game.gd`:

1. Replace:

```gdscript
## save loads in Villaclaro and the world can still be walked.
```

with:

```gdscript
## save loads in Villaclaro and the world can still be walked.
## The side quests (GameState.quests): a villager or a board asks the QuestLog first (a
## report, a figure found, a new offer) and says its chapter lines if it has nothing about
## any; the map shows the marks and the sought figures it says. Each finished quest shows
## for a few seconds (World.show_mission_done()) and no quest holds anything back. On
## autoplay it reads and talks like a player on its route, uses the seeds at once and flies
## back to report to whoever is waiting in the last village.
```

2. Replace:

```gdscript
## Autoplay: needs rest (GameState.needs_rest()), or is only kept from the zone's boss by
## its HP or MP, away from a village, with an Ala de viaje (the night at the inn is free).
func _wants_retreat() -> bool:
	return (state.needs_rest() or _boss_needs_rest()) and not _world.in_village() \
		and state.inventory.count(Inventory.WING) > 0
```

with:

```gdscript
## Autoplay: needs rest (GameState.needs_rest()), is only kept from the zone's boss by its
## HP or MP, or has a report waiting in the last village, away from a village, with an Ala
## de viaje (the night at the inn is free). The route may never pass the one who waits.
func _wants_retreat() -> bool:
	var report := not state.quests.reports_here(state.town_zone, state.inventory).is_empty()
	return (state.needs_rest() or _boss_needs_rest() or report) and not _world.in_village() \
		and state.inventory.count(Inventory.WING) > 0
```

3. Replace:

```gdscript
	for npc: Dictionary in _zone.npcs:
		if npc.kind == "shop":
			await _on_shop(npc.id)
```

with:

```gdscript
	for npc: Dictionary in _zone.npcs:
		if npc.kind == "shop":
			await _on_shop(npc.id)
	for i in _zone.npcs.size():
		if _zone.npcs[i].name in state.quests.reports_here(_zone.id, state.inventory):
			await _on_npc(i)
```

4. Replace:

```gdscript
## A villager: says its lines (World.npc_lines(): they change with the chapter).
func _on_npc(index: int) -> void:
	if _busy:
		return
	_set_busy(true)
	var lines: Array[String] = []
	for line in _world.npc_lines(index, state.chapter()):
		lines.append(StoryState.fill(line, state.hero.display_name))
	await _world.show_dialogue(_zone.npcs[index].name, lines)
	_set_busy(false)
```

with:

```gdscript
## A villager or a board: what it has about a quest (the log moves the quest on and pays),
## or else its lines (World.npc_lines(): they change with the chapter).
func _on_npc(index: int) -> void:
	if _busy:
		return
	_set_busy(true)
	var figure: String = _zone.npcs[index].name
	var talk := state.quests.talk(state, _zone.id, figure)
	var said: Array = talk.get("lines", _world.npc_lines(index, state.chapter()))
	var lines: Array[String] = []
	for line: String in said:
		lines.append(StoryState.fill(line, state.hero.display_name))
	await _world.show_dialogue(figure, lines)
	if not talk.is_empty():
		_after_quest_talk(talk.done)
	_set_busy(false)


## The map shows what changed; a finished quest says so; the game is saved.
func _after_quest_talk(done_title: String) -> void:
	if _autoplay:
		for id in Inventory.SEEDS:
			while state.inventory.count(id) > 0:
				state.use_item(id)
	_refresh_status()
	if done_title != "":
		_audio.play_sfx(SfxLibrary.LEVEL_UP)
		_world.show_mission_done(QuestLog.done_text(done_title))
	_autosave(done_title == "")
```

5. Replace:

```gdscript
## Updates the map's status window and the hero's weapon and shield; on autoplay also
## prints each new quest line and each change of gold or equipment.
func _refresh_status() -> void:
	var missions := state.current_missions()
	_world.refresh_status(state.hero, state.inventory.count(Inventory.POTION), state.gold,
		missions)
```

with:

```gdscript
## Updates the map's status window, the quests' marks and sought figures and the hero's
## weapon and shield; on autoplay also prints each new quest line and each change of gold
## or equipment.
func _refresh_status() -> void:
	var missions := state.current_missions()
	_world.refresh_status(state.hero, state.inventory.count(Inventory.POTION), state.gold,
		missions)
	_world.set_quest_view(state.quests.markers(_zone.id, state.inventory),
		state.quests.hidden_figures(_zone.id))
```

6. Replace:

```gdscript
		print("Juego completado: Nv %d, tiempo de juego %s" % [state.hero.level, time_text])
```

with:

```gdscript
		print("Juego completado: Nv %d, tiempo de juego %s, misiones %d" % [state.hero.level,
			time_text, state.quests_done()])
```

- [ ] **Step 5: Check the scripts**

```powershell
$env:APPDATA = "C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\appdata"
New-Item -ItemType Directory -Force $env:APPDATA | Out-Null
foreach ($s in "battle/battle_actor","world/world","world/world_stage","world/zone_data","game/game") { .\tools\godot.cmd --headless --path . --check-only --script "res://scripts/$s.gd" }
```

Expected: no `SCRIPT ERROR` or `ERROR`.

- [ ] **Step 6: The forest and the castle on autoplay**

```powershell
$env:APPDATA = "C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\appdata"
.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 40000 -- --autoplay --autoplay-zone=bosque | Select-String "Tablón|Niña|Gato|Misión|Recibes|ERROR|WARNING|Zona: "
.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 40000 -- --autoplay --autoplay-zone=castillo_patio | Select-String "Tablón|Explorador|Soldado|Misión|Recibes|Juego completado|ERROR|WARNING|Zona: "
```

Expected in the forest: the board and the Niña offer their quests on the first pass, `Gato: ¡Miau!`, `Misión cumplida: Lobos hambrientos` with the ring on and `Misión cumplida: El gato perdido`. In the castle: the board offers the rescue, `Explorador: ¡Por fin alguien...`; a `Retirada al pueblo` after the next won battle if an Ala is carried, and `Misión cumplida: El explorador perdido`. The run must go on fighting or reach `Juego completado`, never stand still. No ERROR or WARNING other than the known Jolt one.

- [ ] **Step 7: The whole game on autoplay**

```powershell
$env:APPDATA = "C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\appdata"
.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 150000 -- --autoplay | Select-String "Misión cumplida|Juego completado|ERROR|WARNING|Zona: "
```

Expected: at least 3 side quests finished (`Misión cumplida: Carta para la Leñadora`, `El gato perdido` and `El explorador perdido`, usually `Lobos hambrientos` too, and `Setas para el guiso` only when the fights fall that way), then `Juego completado: Nv n, tiempo de juego h:mm:ss, misiones n` with n at least 4 (the village quest counts) and a time around 1:30, under 2 h.

- [ ] **Step 8: See the marks**

```powershell
$env:APPDATA = "C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\appdata"
$frames = "C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\frames"
New-Item -ItemType Directory -Force $frames | Out-Null
.\tools\godot.cmd --path . --write-movie "$frames\f.png" --fixed-fps 10 --quit-after 2400 -- --autoplay --autoplay-zone=bosque
```

Look at frames every 10-20 s of the run (the file name is the frame, 10 per second): a yellow "!" over the board and the Niña, the board with its papers toward the camera, the Niña smaller than the villagers, then the cat with a "?" in the west glade, not lost in the grass. Then delete `$frames`.

- [ ] **Step 9: The Slime de Metal, which the autoplay never meets**

Write `C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\probes\probe_metal.gd`:

```gdscript
extends SceneTree
## Throwaway check of plan 6b, Task 3: the Slime de Metal as rules, then one fight on
## screen with a screenshot. Never committed.


func _init() -> void:
	var rng := RandomNumberGenerator.new()
	for level in [6, 9, 11, 13]:
		var wins := 0
		var rounds := 0
		for i in 400:
			var state := _hero(level)
			var enemies: Array[Combatant] = [EnemyLibrary.data("slime_metal").duplicate() as Combatant]
			var engine := BattleEngine.new(state.hero, enemies, rng, state.inventory)
			var bot := BattleAutoplay.new()
			while engine.state == BattleEngine.State.ONGOING:
				engine.resolve_round(bot.choose(engine))
				rounds += 1
			if engine.state == BattleEngine.State.WON:
				wins += 1
		print("Nv %d: gana %.0f %% de los encuentros, %.1f rondas" % [level, wins / 4.0,
			rounds / 400.0])
	var state := _hero(12)
	var enemies: Array[Combatant] = [EnemyLibrary.data("slime_metal")]
	var battle: BattleScene = load("res://scenes/battle/battle_scene.tscn").instantiate()
	battle.setup(state.hero, enemies, state.inventory)
	battle.zone = ZoneData.by_id("pradera")
	battle.finished.connect(func(outcome: int) -> void:
		print("Fin: estado %d, EXP %d, oro %d" % [outcome, battle.engine.exp_won,
			battle.engine.gold_won])
		quit())
	root.add_child.call_deferred(battle)
	create_timer(1.5).timeout.connect(func() -> void:
		var frames := OS.get_environment("FRAMES")
		root.get_texture().get_image().save_png(frames + "/metal.png"))


func _hero(level: int) -> GameState:
	var state := GameState.new(load("res://data/hero.tres") as Combatant)
	state.hero.experience = Leveling.EXP_TABLE[level - 1]
	Leveling.apply(state.hero)
	state.heal_full()
	return state
```

```powershell
$env:APPDATA = "C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\appdata"
$env:FRAMES = "C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\frames"
New-Item -ItemType Directory -Force $env:FRAMES | Out-Null
.\tools\godot.cmd --path . --script "C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\probes\probe_metal.gd" -- --autoplay
```

Expected: about 0 % at Nv 6, 16 % at Nv 9, 27 % at Nv 11 and 29 % at Nv 13 (Rayo is the first spell that hurts it, and two are needed). With `rare_chance` 0.25 that is about 14 battles of the meadow for a hero of Nv 11. The fight prints either `¡El Slime de Metal huye!` and `Fin: estado 3, EXP 0, oro 0`, or the victory and `Fin: estado 1, EXP 300, oro 150`. `frames\metal.png` shows a small silver slime. Delete `frames` afterwards. No ERROR.

- [ ] **Step 10: Commit**

```powershell
git add scripts data
git commit -m "Put notice boards, quest givers and their marks on the map"
```

---

### Task 4: The Diario

**Files:**
- Create: `scripts/ui/journal_page.gd`
- Modify: `scripts/ui/pause_menu.gd`
- Temporary (outside the repo): `probes\probe_journal.gd`

**Interfaces:**
- Consumes (Task 2): `QuestLog.journal(inventory) -> {active: [{title, text}], done: [title]}`; `GameState.story.goal_text(world_flags)`, `GameState.quests`, `GameState.inventory`. `BattleHud.fit_label(label, text, max_width)`.
- Produces: `JournalPage` (`VBoxContainer`): `fill(state: GameState)`. `PauseMenu.HERO_PAGES` gains Diario, `tour()` shows it.

- [ ] **Step 1: The page**

Create `scripts/ui/journal_page.gd`:

```gdscript
class_name JournalPage extends VBoxContainer
## The Diario of the pause menu: "Qué hacer ahora" (the story's next step), the missions in
## progress with what each one asks and the missions finished. Only reads a GameState: call
## fill() each time it opens.

## A little smaller than the other pages: seven missions must fit a 720 p window.
const HEADING_SIZE := 22
const ENTRY_SIZE := 20
const TEXT_SIZE := 18
const TITLE_COLOR := Color(1.0, 0.85, 0.3)
const GREY := Color(0.6, 0.6, 0.65)
## Long lines wrap past this width.
const TEXT_WIDTH := 720.0


func _ready() -> void:
	add_theme_constant_override("separation", 0)


func fill(state: GameState) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var journal := state.quests.journal(state.inventory)
	_heading("Qué hacer ahora")
	_line(state.story.goal_text(state.world_flags), Color.WHITE, ENTRY_SIZE)
	_heading("En curso")
	if journal.active.is_empty():
		_line("Nada por ahora.", GREY, ENTRY_SIZE)
	for entry: Dictionary in journal.active:
		_line(entry.title, Color.WHITE, ENTRY_SIZE)
		_line(entry.text, GREY, TEXT_SIZE)
	_heading("Cumplidas")
	if journal.done.is_empty():
		_line("Ninguna todavía.", GREY, ENTRY_SIZE)
	else:
		_line(", ".join(journal.done), Color.WHITE, TEXT_SIZE)


func _heading(text: String) -> void:
	_line(text, TITLE_COLOR, HEADING_SIZE)


func _line(text: String, color: Color, font_size: int) -> void:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	add_child(label)
	BattleHud.fit_label(label, text, TEXT_WIDTH)
```

- [ ] **Step 2: In the menu**

In `scripts/ui/pause_menu.gd`:

1. Replace:

```gdscript
## the comparison, and Quitar), Opciones (OptionsPanel) and a confirmation before going
```

with:

```gdscript
## the comparison, and Quitar), Diario (JournalPage: what to do now, the missions in progress
## and the finished ones), Opciones (OptionsPanel) and a confirmation before going
```

2. Replace:

```gdscript
const HERO_PAGES := [["Estado", "status"], ["Objetos", "items"], ["Equipo", "equipment"]]
```

with:

```gdscript
const HERO_PAGES := [["Estado", "status"], ["Objetos", "items"], ["Equipo", "equipment"],
	["Diario", "journal"]]
```

3. Replace:

```gdscript
var _options_panel: OptionsPanel
var _page := ""
```

with:

```gdscript
var _journal: JournalPage
var _options_panel: OptionsPanel
var _page := ""
```

4. Replace:

```gdscript
	_build_equipment(stack)
	_build_options(stack)
```

with:

```gdscript
	_build_equipment(stack)
	_build_journal(stack)
	_build_options(stack)
```

5. Replace:

```gdscript
	for page in ["main", "status", "items", "equipment", "options"]:
```

with:

```gdscript
	for page in ["main", "status", "items", "equipment", "journal", "options"]:
```

6. Replace:

```gdscript
			_equip_slot = ""
			_set_line(_equip_message, "")
			_fill_equipment()
	_quiet_focus = true
	if page == "options":
```

with:

```gdscript
			_equip_slot = ""
			_set_line(_equip_message, "")
			_fill_equipment()
		"journal":
			_journal.fill(_state)
	_quiet_focus = true
	if page == "options":
```

7. Replace:

```gdscript
func _build_options(stack: VBoxContainer) -> void:
```

with:

```gdscript
func _build_journal(stack: VBoxContainer) -> void:
	var page := _page_box(stack, "journal", "Diario")
	_journal = JournalPage.new()
	page.add_child(_journal)
	page.add_child(_back_button())


func _build_options(stack: VBoxContainer) -> void:
```

- [ ] **Step 3: Check the scripts**

```powershell
$env:APPDATA = "C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\appdata"
New-Item -ItemType Directory -Force $env:APPDATA | Out-Null
.\tools\godot.cmd --headless --path . --import
foreach ($s in "ui/journal_page","ui/pause_menu") { .\tools\godot.cmd --headless --path . --check-only --script "res://scripts/$s.gd" }
```

Expected: no `SCRIPT ERROR` or `ERROR`.

- [ ] **Step 4: See the pages**

The tour shows the main page, Estado, Objetos, Equipo, Diario and Opciones, TOUR_STEP 1.5 s each, after the name window.

```powershell
$env:APPDATA = "C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\appdata"
$frames = "C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\frames"
New-Item -ItemType Directory -Force $frames | Out-Null
.\tools\godot.cmd --path . --write-movie "$frames\f.png" --fixed-fps 10 --quit-after 140 -- --autoplay --autoplay-menu | Select-String "Menú|ERROR"
```

Expected: `Menú: journal` printed. Look at the last frames before Opciones: the Diario shows "Qué hacer ahora", "En curso" and "Cumplidas" inside its window, the Equipo page has four slots with "Accesorio: nada", and the main page has the Diario row. Then delete `$frames`.

- [ ] **Step 5: A full Diario fits**

Write `C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\probes\probe_journal.gd`:

```gdscript
extends SceneTree
## Throwaway check of plan 6b, Task 4: the Diario with every mission in progress. Never
## committed.


func _init() -> void:
	var state := GameState.new(load("res://data/hero.tres") as Combatant)
	state.quest.start()
	for id: String in QuestLog.QUESTS:
		state.quests.accept(state, id)
	state.inventory.add(Inventory.SEED_ATTACK)
	state.inventory.add(Inventory.SETA, 2)
	var layer := CanvasLayer.new()
	var menu := PauseMenu.new()
	menu.setup(state, GameOptions.new(), null)
	layer.add_child(menu)
	root.add_child.call_deferred(layer)
	create_timer(0.3).timeout.connect(func() -> void:
		menu.available = true
		menu.open()
		for page in ["journal", "items", "main"]:
			menu._show_page(page)
			await create_timer(0.3, true).timeout
			root.get_texture().get_image().save_png(OS.get_environment("FRAMES") + "/%s.png" % page)
		quit())
```

```powershell
$env:APPDATA = "C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\appdata"
$env:FRAMES = "C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\frames"
New-Item -ItemType Directory -Force $env:FRAMES | Out-Null
.\tools\godot.cmd --path . --script "C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\probes\probe_journal.gd"
```

Expected: `journal.png` shows all seven missions inside the window, with the Setas line `(2 / 3)`, under 720 px; `items.png` shows the seed with "Usar" and the Seta greyed with "Para una misión"; `main.png` shows at most four mission lines ending in "y 4 más en el Diario". Delete `frames` afterwards. No ERROR.

- [ ] **Step 6: Commit**

```powershell
git add scripts
git commit -m "Add the Diario to the pause menu"
```

---

### Task 5: Documentation, final checks and web export

**Files:**
- Modify: `CLAUDE.md`, `docs/boost/specs/ideas-sueltas.md`

**Interfaces:**
- Consumes: everything above.
- Produces: docs only.

- [ ] **Step 1: Update `CLAUDE.md`**

In `CLAUDE.md`:

1. Replace:

```markdown
- `scripts/game/quest.gd` (`Quest`, `RefCounted`) — the village quest: stages `OFFER → HUNT → REPORT → BOSS → DONE`; `on_victory(enemy_id)` (called for every enemy of a won battle) counts slimes during `HUNT` and finishes on the boss; `talk()` returns the old woman's lines and the potions to give (2 when reporting) and moves the stage on; `boss_available()`, `status_text()` ("" once done), `DONE_TEXT`.
```

with:

```markdown
- `scripts/game/quest.gd` (`Quest`, `RefCounted`) — the village quest: stages `OFFER → HUNT → REPORT → BOSS → DONE`; `on_victory(enemy_id)` (called for every enemy of a won battle) counts slimes during `HUNT` and finishes on the boss; `talk()` returns the old woman's lines and the potions to give (2 when reporting) and moves the stage on; `boss_available()`, `status_text()` ("" once done), `TITLE`, `DONE_TEXT`.
- `scripts/game/quest_log.gd` (`QuestLog`, `RefCounted`, `GameState.quests`) — every mission: the village quest (`village`, the same object as `GameState.quest`) and the six side quests of `QUESTS` (`Stage`: `OPEN → ACTIVE → REPORT → DONE`). Pure: `accept()`, `on_victory(state, enemy_id)` (returns `{title, lines}` of a quest that ends on the spot), `wanted_enemies()`, `talk(state, zone_id, figure)` → `{}` or `{lines, done}` (first a report waiting, then a sought figure found, a new offer, its waiting lines; it moves the quest on and pays), `reports_here()`, `markers()` (figure name → "!" / "?", the Abuela Rosa's too), `hidden_figures()` (sought figures are only on the map while sought), `status_lines()` (the village quest, then the rest, at most `MAX_STATUS_LINES` 3 and "y n más en el Diario"), `done_count()`, `journal()`, `to_dict()`, `set_from()`, static `done_text(title)` ("Misión cumplida: ..."). No quest gates anything. `scripts/game/quest_data.gd` (`QuestData`, `Resource`): a quest as data in `data/quests/<id>.tres` (`Kind` `HUNT` / `GATHER` / `DELIVER` / `FIND`, giver, `turn_in` ("" ends on the spot), target, goal, key item, the texts, the rewards). `scripts/game/quest_rewards.gd` (`QuestRewards`): `give(state, quest)` pays gold, items and a piece of equipment (on at once if its slot is empty) and returns the lines. The quests: `carta` (the Granjero, to the Leñadora; 60 G, 2 Pociones), `setas` (Villaclaro's board, 3 Setas, a 50 % drop of the Seta saltarina, to the Granjero; 40 G, Semilla de fuerza), `lobos` (the forest's board, 5 lobos, to the Leñadora; 120 G, Anillo antiveneno), `gato` (the Niña, the cat in the west glade; 80 G, Semilla de agilidad), `slime_metal` (the refugio's board, a rare encounter of the meadow; Amuleto de velocidad on the spot), `explorador` (the camp's board, the explorer in the courtyard, to the Soldado; 250 G, 2 Éter, Semilla de defensa). No quest gives EXP.
```

2. Replace:

```markdown
`inventory: Inventory` (starts with 3 potions), `quest: Quest`,
```

with:

```markdown
`inventory: Inventory` (starts with 3 potions), `quest: Quest`, `quests: QuestLog`,
```

3. Replace:

```markdown
`refresh_equipment()` (copies the loadout bonuses into `hero.equip_attack` / `equip_defense`),
```

with:

```markdown
`refresh_equipment()` (copies the loadout bonuses into `hero.equip_attack` / `equip_defense` / `equip_speed` / `equip_immune`),
```

4. Replace:

```markdown
slot `WEAPON` / `ARMOR` / `SHIELD`, bonus (ATK for weapons, DEF for the rest), price, zone, mesh)
```

with:

```markdown
slot `WEAPON` / `ARMOR` / `SHIELD` / `ACCESSORY`, bonus (ATK for weapons, VEL for accessories, DEF for the rest), price, zone, mesh, `immune` on an accessory; the accessories are quest rewards, zone −1, price 0: `POISON_RING` Anillo antiveneno, immune to poison, and `SPEED_AMULET` Amuleto de velocidad, VEL +3; `immunity()`, `effect_text()`)
```

5. Replace:

```markdown
`attack_bonus()`, `defense_bonus()`, `to_dict()`, `set_slots()`.
```

with:

```markdown
`attack_bonus()`, `defense_bonus()`, `speed_bonus()`, `immunities()`, `to_dict()`, `set_slots()` (a slot missing from an old save stays empty).
```

6. Replace:

```markdown
`ITEMS` table (name, article, effect `hp` / `mp` / `cure` / `travel`, value, price,
```

with:

```markdown
`ITEMS` table (name, article, effect `hp` / `mp` / `cure` / `travel` / `seed` / `quest`, value, price,
```

7. Replace:

```markdown
`WING` (Ala de viaje, 25 G, outside battle: `use()` only takes it, the pause menu asks `Game` for the trip);
```

with:

```markdown
`WING` (Ala de viaje, 25 G, outside battle: `use()` only takes it, the pause menu asks `Game` for the trip), the `SEEDS` (`SEED_ATTACK`, `SEED_DEFENSE`, `SEED_SPEED`: +2 for good to a base stat, from Objetos, only from quests) and `SETA` (`quest`: "Para una misión", no use of its own);
```

8. Replace:

```markdown
`llave_mina` "Llave de la mina"),
```

with:

```markdown
`llave_mina` "Llave de la mina", `carta_granjero` "Carta del Granjero"),
```

9. Replace:

```markdown
`version` 6 (`STORY_VERSION` adds `name`, `story` and `stats`; an older save gets the default name, the cutscenes its flags leave behind marked seen and the numbers at 0),
```

with:

```markdown
`version` 7 (`QUESTS_VERSION` adds the accessory slot and `quests`, `{id: {stage, count}}`; an older save gets an empty slot and no side quest taken. `STORY_VERSION` adds `name`, `story` and `stats`; an older save gets the default name, the cutscenes its flags leave behind marked seen and the numbers at 0),
```

10. Replace:

```markdown
the rows of `HERO_PAGES` Estado, Objetos, Equipo and "Misiones" with `GameState.current_missions()`;
```

with:

```markdown
the rows of `HERO_PAGES` Estado, Objetos, Equipo, Diario and "Misiones" with `GameState.current_missions()`;
```

11. Replace:

```markdown
Equipo (the three slots with what is worn and ATK / DEF; a slot lists the pieces of that slot in the bag with the comparison, Quitar and Volver), Opciones (`OptionsPanel`),
```

with:

```markdown
Equipo (the four slots with what is worn and ATK / DEF / VEL; a slot lists the pieces of that slot in the bag with the comparison, none for accessories, Quitar and Volver), Diario (`JournalPage`, `scripts/ui/journal_page.gd`: "Qué hacer ahora" from `StoryState.goal_text()`, "En curso" and "Cumplidas" from `QuestLog.journal()`), Opciones (`OptionsPanel`),
```

12. Replace:

```markdown
esqueleto_mago, senor_niebla) and its figure (`LOOKS`);
```

with:

```markdown
esqueleto_mago, senor_niebla, slime_metal) and its figure (`LOOKS`);
```

13. Replace:

```markdown
`pick(zone, pos, rng)` (a formation of `zone.formations`, same weight, or of `zone.start_formations` within `start_radius` of `start_pos`: slimes near the meadow's spawn, one forest enemy at a time near the forest's entry),
```

with:

```markdown
`pick(zone, pos, rng, wanted)` (`zone.rare_enemy` alone, with `rare_chance`, while it is in `wanted`: the Slime de Metal, 25 %, while its quest is on; else a formation of `zone.formations`, same weight, or of `zone.start_formations` within `start_radius` of `start_pos`: slimes near the meadow's spawn, one forest enemy at a time near the forest's entry),
```

14. Replace:

```markdown
`SKELETON_MAGE` / `FOG_LORD` / `FARMER`, set before `add_child`),
```

with:

```markdown
`SKELETON_MAGE` / `FOG_LORD` / `FARMER` / `METAL_SLIME` (a small silver slime) / `BOARD` (a notice board on two posts, still) / `CAT` / `CHILD` (a small pink Mage), set before `add_child`),
```

15. Replace:

```markdown
the Abuela Rosa `quest`, merchants `shop`, innkeepers `inn`, villagers `npc`),
```

with:

```markdown
the Abuela Rosa `quest`, merchants `shop`, innkeepers `inn`, villagers `npc`, notice boards `board`, read with "Enter o toca: leer"; `set_quest_view(marks, hidden_names)` floats a yellow "!" or "?" `Label3D` over a figure, none during a cutscene, and takes off the map the figures a quest has not brought out; autoplay talks again to a figure with a mark),
```

16. Replace:

```markdown
- Whole game on autoplay, from a new game through every cutscene to the credits (headless, under a minute of real time): `.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 150000 -- --autoplay`; it ends with `Juego completado: Nv n, tiempo de juego h:mm:ss` (1:19-1:34 in the runs of the story plan).
```

with:

```markdown
- Whole game on autoplay, from a new game through every cutscene and at least 3 side quests to the credits (headless, about a minute of real time): `.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 150000 -- --autoplay`; it ends with `Juego completado: Nv n, tiempo de juego h:mm:ss, misiones n` (1:17-1:34 in the runs of the side quests plan).
```

17. Replace:

```markdown
and the credits end with `Juego completado: Nv n, tiempo de juego h:mm:ss`;
```

with:

```markdown
and the credits end with `Juego completado: Nv n, tiempo de juego h:mm:ss, misiones n`;
```

18. Replace:

```markdown
--quit-after 125 -- --autoplay --autoplay-menu` (no prologue; after the name window, ☰ shows after MENU_TOUR_DELAY 1.0 s, then the main page, Estado, Objetos, Equipo an
```

with:

```markdown
--quit-after 140 -- --autoplay --autoplay-menu` (no prologue; after the name window, ☰ shows after MENU_TOUR_DELAY 1.0 s, then the main page, Estado, Objetos, Equipo, Diario an
```

In `docs/boost/specs/ideas-sueltas.md`, replace:

```markdown
- **Estado:** hecha: [plan](../plans/2026-11-04-interfaz.md), tarea 4; la fase 6 añade su registro en `GameState.current_missions()`. Nota: ahora esa línea muestra `StoryState.goal_text()` (la historia) en lugar de "Sigue el sendero" / "Explora el mapa".
```

with:

```markdown
- **Estado:** hecha: [plan](../plans/2026-11-04-interfaz.md), tarea 4; la fase 6 añade su registro en `GameState.current_missions()` ([plan](../plans/2026-11-04-historia-misiones.md)). Nota: sin misiones en curso, esa línea muestra `StoryState.goal_text()` (la historia) en lugar de "Sigue el sendero" / "Explora el mapa".
```

- [ ] **Step 2: Full runs**

Three full runs, each with a look at its output:

```powershell
$env:APPDATA = "C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\appdata"
New-Item -ItemType Directory -Force $env:APPDATA | Out-Null
1..3 | ForEach-Object { .\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 150000 -- --autoplay | Select-String "Misión cumplida|Juego completado|ERROR|WARNING" }
```

Expected: each ends with `Juego completado`, with at least 3 side quests, around 1:30 and always under 2 h, and no ERROR or WARNING other than the known Jolt one. If a run stops short of `Juego completado` at 150000 frames, find what it was doing before anything else: no quest may hold a run back.

- [ ] **Step 3: The save round trip**

```powershell
$env:APPDATA = "C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\appdata"
.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 6000 -- --autoplay --autoplay-save | Select-String "Guardado|Cargado|ERROR"
```

Expected: the `Guardado:` and `Cargado:` lines are identical, with `"version":7`.

- [ ] **Step 4: Web export**

```powershell
$env:APPDATA = "C:\Users\peixe\AppData\Local\Temp\claude\523c4b0c813959e8\5d798f44-87fa-4160-a1c9-e462c8de15fb\scratchpad\appdata"
New-Item -ItemType Directory -Force build/web | Out-Null
.\tools\godot.cmd --headless --path . --export-release "Web" build/web/index.html
```

The export needs the 4.7.2 templates, which live under the real `%APPDATA%\Godot\export_templates`; if the redirected `APPDATA` makes it say they are missing, run this one command with `$env:APPDATA` back at its real value (an export writes no save). Expected: `build/web/index.html` and `index.pck` are written, no ERROR.

- [ ] **Step 5: Commit**

```powershell
git add CLAUDE.md docs/boost/specs/ideas-sueltas.md docs/boost/plans/2026-11-04-historia-misiones.md
git commit -m "Document the side quests"
```

---

## Replay

The plan was applied by script to a copy of `f739a35` outside the repo, in order, with `APPDATA` pointing at the scratchpad, and the copy was deleted afterwards.

- **Anchors:** 118 replacements, each found exactly once when its turn came (Task 1: 35, Task 2: 25, Tasks 3-5: 58); 11 files created.
- **`--check-only`:** clean on the 22 scripts touched or added. The game also ran after Task 1 alone and after Tasks 1-2 alone, with identical `Guardado:` and `Cargado:` lines.
- **Probes:** the expected values above come from these runs. Saves of versions 6 and 2 load; a version 7 save comes back equal.
- **Full runs:** 10 of 10 reach `Juego completado` at Nv 18-19, in 1:17-1:34 of play (before this plan: 1:21-1:31), each with 4 side quests: `carta`, `lobos`, `gato` and `explorador`. An earlier round of 4 runs, before the retreat for a waiting report, finished `lobos` in 2 and `setas` in 1, so those two depend on the fights; `setas` rarely finishes, since few Setas saltarinas come before the hero leaves the meadow. No ERROR or WARNING beyond the known Jolt one.
- **Frames:** the cat with its "?" clear of the grass, the board with its papers toward the camera, the Niña's "?", the full Diario (seven missions, inside 720 p, which is why its fonts are smaller), Objetos and the main page's four lines. The Slime de Metal's fight on screen.
- **Web export:** written, `index.pck` 3.0 MB. It needs the real `APPDATA`, where the templates live, as Task 5 Step 4 says.

There is room left under the 2 h target: the quests add little time, because they lie on the route and their gold saves some walking for money.

## Self-review

- **Spec:** `QuestLog` and `QuestData` with `Quest` first (Task 2). Six quests of the four kinds (Task 2), offered by boards and villagers (Task 3). Seeds and accessory (Task 1), rewards (Task 2). Diario with "Qué hacer ahora" (Task 4). "!" and "?" (Task 3). `quests_done()` in the credits (Task 2). Save 7 under its own constant, 2-6 loading (Tasks 1 and 2). Autoplay with at least 3 side quests and the time checked (Tasks 3 and 5). Docs, full runs and web export (Task 5).
- **Not here on purpose:** New Game + and the superboss (out of scope in the spec), a phone layout (postponed by the user).

## Next: phase 7

Phase 7 (`docs/boost/specs/2026-11-03-pulido-publicacion-design.md`) changes in three small ways because of this plan:

- **Translations:** `i18n/textos.csv` must also take the strings of `data/quests/*.tres`, the boards' and the Niña's `lines` and the new `Inventory` and `Equipment` names, and `QuestLog` and `JournalPage` must pass theirs through `tr()`. `QuestLog.done_text()` and the `%d / %d` statuses are format strings, so they translate as whole strings.
- **Windows to check in English:** add the Diario (`JournalPage.TEXT_WIDTH` 720) and the status window with three mission lines to the list of texts that may run over.
- **Difficulty:** the Fácil EXP bonus also applies to the Slime de Metal's 300 EXP, with no change, since it goes through `BattleEngine._win()`. Quests give no EXP, so there is nothing else to scale.
