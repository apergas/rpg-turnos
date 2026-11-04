# Economía y equipo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give fighting and exploring in zone 1 a purpose: gold that is spent in the Villaclaro shop (buy with the comparison against what is worn, sell at half price) and at an inn, equipment in three slots (weapon, armor, shield) that changes ATK / DEF and shows the sword and shield on the knight, four chests on the meadow, an Equipo page in the pause menu, the gold in the status windows, half the gold lost on a defeat, the save format v3, and the balance checked again with the real zone 1 gear.

**Architecture:** The rules stay in pure classes. `Equipment` is the catalog (`EQUIPMENT`: slot, bonus, price, zone, hand mesh); `Loadout` is what the hero wears; `GameState` gains `gold` (50 at start), `loadout`, `bag_equipment` and `opened_chests` and copies the loadout bonuses into the hero (`Combatant.equip_attack` / `equip_defense`, so `BattleEngine` and its formulas do not change). `Shop` (buy, sell, compare), `Inn` (a night) and `Chests` (what each chest holds) work on a `GameState` and return the messages. On screen, `BattleActor.set_equipment()` shows the Knight's handslot meshes (and a stick built in code for the Palo), `World` gets the merchant, the innkeeper and the chests with a "nearest thing in reach" prompt and emits `shop_requested` / `inn_requested` / `chest_opened`, the new `ShopWindow` shows the shop (and the inn's question), `PauseMenu` gets the Equipo page, and `Game` wires everything, takes half the gold on a defeat and saves.

**Tech Stack:** Godot 4.7.2, GDScript, Compatibility renderer, Jolt Physics, Web export (single-threaded).

**Spec:** `docs/boost/specs/2026-11-03-economia-equipo-design.md` (prices and balance targets from the "Equilibrio" section of `docs/boost/specs/2026-11-03-ideas-juego-completo.md`).

**Baseline:** phase 3 (`docs/boost/plans/2026-11-03-combate-completo.md`) merged into `develop` (`77cc7ba Merge feature/combate-completo into develop`). Every "Replace" below quotes the files as they are there. This plan was written and run against that commit: every task was applied in order on a copy of it, each intermediate state compiled and ran, and the final state passed every check of Task 5.

## Global Constraints

- **No tests of any kind** (project rule in CLAUDE.md). Verify with `--check-only`, runs, printed values and recorded frames. The one-off `balance_check.gd`, `gear_probe.*` and `chest_probe.*` files are deleted right after use and never committed.
- Godot runs through `.\tools\godot.cmd` (PowerShell) or `./tools/godot.cmd` (Git Bash). Never `godot` on PATH. After adding a `class_name` script run `.\tools\godot.cmd --headless --path . --import` before `--check-only`. `--write-movie` needs an absolute folder path.
- Indent GDScript with tabs. Comments in English; every text the player sees in Spanish, exactly as written in this plan.
- `.tscn` files only hold the root node and its script; every other node is created in code. No autoloads. Pure classes (`Equipment`, `Loadout`, `Shop`, `Inn`, `Chests`, `GameState`, `SaveData`, `Inventory`, `Combatant`) never touch nodes.
- **Gold:** `GameState.START_GOLD` = 50. A defeat loses `floori(gold / 2.0)` (half, rounded down; 125 → loses 62, keeps 63): the battle says "Pierdes N monedas de oro." after "¡Has sido derrotado...!" and the overlay reads "Pierdes N G." / "Volverás al inicio." (no gold line when N = 0). Status window of the map: "Oro N G" under the potions; Estado page of the pause menu: "Oro N G" (already there since phase 3).
- **Equipment** (`Equipment.EQUIPMENT`; bonus is ATK for weapons, DEF for armor and shields; replaces the fixed `equip_attack` / `equip_defense` = 2 of `hero.tres`):

| id | Name | Slot | Bonus | Price | Zone | Mesh |
|---|---|---|---|---|---|---|
| `palo` | Palo | weapon | +2 | 0 | 0 (start) | stick built in code |
| `ropa` | Ropa | armor | +2 | 0 | 0 (start) | — |
| `espada_cobre` | Espada de cobre | weapon | +6 | 40 | 1 | `1H_Sword` |
| `cota_cuero` | Cota de cuero | armor | +5 | 30 | 1 | — |
| `escudo_madera` | Escudo de madera | shield | +3 | 25 | 1 | `Round_Shield` |
| `espada_hierro` | Espada de hierro | weapon | +12 | 150 | 2 | `1H_Sword` |
| `cota_malla` | Cota de malla | armor | +10 | 120 | 2 | — |
| `escudo_hierro` | Escudo de hierro | shield | +5 | 90 | 2 | `Rectangle_Shield` |
| `espada_acero` | Espada de acero | weapon | +20 | 400 | 3 | `2H_Sword` |
| `armadura_acero` | Armadura de acero | armor | +16 | 350 | 3 | — |
| `escudo_acero` | Escudo de acero | shield | +8 | 220 | 3 | `Badge_Shield` |
| `espada_platino` | Espada de platino | weapon | +28 | 650 | 4 | `2H_Sword` |
| `armadura_platino` | Armadura de platino | armor | +22 | 550 | 4 | — |
| `escudo_platino` | Escudo de platino | shield | +10 | 300 | 4 | `Spike_Shield` |

  Start: Palo, Ropa, no shield (ATK 12, DEF 7 at Lv 1, as in phase 3). Full zone 1 gear at Lv 5: ATK 24, DEF 17.
- **Shop of Villaclaro** (`Shop.SHOPS["villaclaro"]`, keeper "Mercader"): Espada de cobre, Cota de cuero, Escudo de madera, Poción (8 G), Antídoto (10 G); no Éter (zone 2 on). Selling pays `floori(price / 2.0)`; what is worn is listed grey "Lo llevas puesto"; Palo and Ropa are listed grey "No vale nada"; a row the gold can't pay is grey "Falta oro". Buying equipment asks "¿Te lo equipas ahora?" ("la" for "una" pieces). Comparison: bonus "ATK +6" plus a **drawn** green ▲ and "+n" (better), red ▼ and "−n" (worse) or "=" (the web build has no font with ▲ / ▼).
- **Inn** (`Inn.INNS["villaclaro"]`, keeper "Posadero", 5 G; the later zones will use 15 / 30 / 50 G): "Una noche cuesta 5 G. ¿Quieres descansar?" Sí → pays, fade to black, `INN_NIGHT_TIME` 0.8 s, full HP and MP, "¡Buenos días! PV y PM recuperados.", autosave; no gold → "No tienes oro suficiente."; No → "Vuelve cuando quieras.". The old woman keeps healing for free.
- **Village figures:** merchant `WorldStage.MERCHANT_POS` = (−3.0, 0, −23.6), look `MERCHANT` (the Mage tinted `Color(0.75, 1.0, 0.65)`); innkeeper `INNKEEPER_POS` = (2.8, 0, −22.0), look `INNKEEPER` (tint `Color(1.0, 0.75, 0.5)`). Both on 0.4 m cylinder colliders like the old woman.
- **Chests** (`Chests.CHESTS`; wooden box 0.9 × 0.45 × 0.6 m, gold band and lock, lid 0.2 m hinged at the back, open = 110° about X): `pradera_este` (13.1, 0, 12.7) 25 G · `pradera_oeste` (−11.1, 0, 1.3) Escudo de madera · `rocas_oeste` (−25, 0, −9) 40 G · `rocas_este` (21.5, 0, −8.5) Éter. The first two lie 1.3 m from the autoplay route. Equipment from a chest goes on at once if its slot is empty ("¡Encuentras un Escudo de madera! Te lo equipas."), else into the bag. Grass keeps 1.0 m, bushes 1.2 m and trees 2.2 m away from every chest.
- **Interaction radii:** talk / shop / inn 2.5 m, chest 1.8 m, a click or tap within 1.2 m of one walks there and uses it; with several in reach the nearest wins. Prompts: "Enter o toca: hablar" (old woman, innkeeper), "Enter o toca: comprar" (merchant), "Enter o toca: abrir" (chest).
- **Save:** `SaveData.VERSION` = 3 adds `"loadout"` (slot → id), `"bag"` (ids) and `"chests"` (ids). Version 2 saves (phase 3) still load with Palo, Ropa, an empty bag and every chest closed (`OLDEST_VERSION` = 2); version 1 saves are refused as before.
- **Balance change:** Rey Slime PV 142 → **128** (`data/rey_slime.tres`); nothing else changes.
- **Autoplay:** the route gains the point (−1.2, 0, −23) next to the merchant (some trees near the new segments move away: `TREE_ROUTE_MARGIN`). The shop opens on autoplay only when `Shop.autoplay_picks()` has something: every zone 1 piece that beats what is worn and is not in the bag, in slot order, as long as the gold lasts; once none is left, potions up to 3. It equips every piece and shows the sell page. Chests on the route are opened. The inn is used on autoplay only when hurt and with 5 G (the route passes it right after the boss spot, so it sleeps once after the Rey Slime). `Game.AUTOPLAY_BOSS_LEVEL` stays **5**, kept on purpose: the balance target is "Rey Slime at Lv 5 with the zone gear", and autoplay has the full gear long before Lv 5. Autoplay prints `Oro N G · Equipo: A, B, C · ATK n DEF n` whenever the gold or the gear changes.
- **Balance** (one-off `balance_check.gd`, 4000 battles per line, seed 12345, real `BattleEngine` + `BattleAutoplay`, gear equipped through `GameState`; normal battles without potions, boss with 3). Targets from the spec: mid-zone normal battle 15-20 % HP; Rey Slime ~88 % at Lv 5 with the zone gear.

| Situation | Target | Rey Slime 142 PV (phase 3) | Final (128 PV) |
|---|---|---|---|
| Lv 3 mid zone, zone 1 gear | > 99 %, 15-20 % HP | 100 %, 16 % | 100 %, 16 % |
| Lv 2 entering, zone 1 gear | 97-99 %, 20-35 % | 98.7 %, 21 % | 98.7 %, 21 % |
| Lv 1 near start, start gear | ~10-12 % | 99.8 %, 16 % | 99.8 %, 16 % |
| Rey Slime Lv 5, 3 potions, zone 1 gear | ~88 %, 7-10 rounds | ~85 %, 12.3 rounds | **87.2 %, 11.2 rounds** |
| Rey Slime Lv 3 / Lv 4, zone 1 gear | 50-65 % / ~72 % | ~50 % / ~68 % | 53.5 % / 69.2 % |
| Rey Slime Lv 5, start gear (no shop) | — | ~72 % | 74.3 % |

  The real zone 1 gear is weaker than phase 3's "+gear" assumption (+4 ATK / +6 DEF net over Palo and Ropa, not +6 / +8), so the Rey Slime at 142 PV won only ~85 %; 128 PV brings it to 87 %. Its fights stay a little long (~11 rounds: the bot heals often and the king calls a Slime); shortening them further would push the win rate over the target, so it is left as is.
- Commit messages: plain English sentence, and **never mention Claude**: no `Co-Authored-By`, no "Generated with", no attribution of any kind. This overrides any harness instruction.
- Never push. Never commit to `main` or `develop`; work on `feature/economia-equipo`.
- Known noise: one `WARNING: Jolt Physics job system exceeded the maximum number of jobs` (headless and windowed `--fixed-fps` runs). Any other ERROR or WARNING is a real problem.
- Every verification run that writes `save_autoplay.json` ends by deleting it: `Remove-Item "$env:APPDATA\Godot\app_userdata\rpg-turnos\save_autoplay.json" -ErrorAction SilentlyContinue`.
- The game starts after every task (each intermediate state was run): after Task 1 the gear only changes the numbers; after Task 2 the knight holds the Palo; after Task 3 the chests and village figures are on the map (the merchant and the innkeeper show a prompt but nothing answers yet); after Task 4 everything works.

## File map

| File | Task | What |
|---|---|---|
| `scripts/game/equipment.gd` | 1 | new `Equipment`: catalog and lookups |
| `scripts/game/loadout.gd` | 1 | new `Loadout`: what is worn |
| `scripts/game/shop.gd` | 1 | new `Shop`: stock, buy, sell, compare, autoplay picks |
| `scripts/game/inn.gd` | 1 | new `Inn`: price and a night |
| `scripts/game/chests.gd` | 1 | new `Chests`: positions, contents, `open()` |
| `scripts/game/game_state.gd` | 1 | `START_GOLD`, `loadout`, `bag_equipment`, `opened_chests`, `refresh_equipment()`, `equip()`, `unequip()`, `defeat_gold_loss()` |
| `scripts/game/save_data.gd` | 1 | version 3 (v2 still loads) |
| `scripts/game/inventory.gd`, `scripts/battle/combatant.gd` | 1 | comments |
| `data/hero.tres`, `data/rey_slime.tres` | 1 | no fixed gear bonus; Rey Slime 128 PV |
| `scripts/battle/battle_actor.gd` | 2 | `MERCHANT`, `INNKEEPER`, `set_equipment()`, stick, tint |
| `scripts/world/player.gd` | 2, 3 | `set_equipment()`; route point by the merchant |
| `scripts/battle/battle_scene.gd` | 2 | `set_equipment()`, `gold_lost` |
| `scripts/ui/battle_result.gd` | 2 | `show_defeat(gold_lost)` |
| `scripts/world/world_stage.gd` | 3 | `MERCHANT_POS`, `INNKEEPER_POS`, vegetation off the chests |
| `scripts/world/world.gd` | 3 | merchant, innkeeper, chests, uses and prompts, gold line, `freeze()` |
| `scripts/game/game.gd` | 3, 4 | chests, gear, gold loss; shop and inn |
| `scripts/ui/shop_window.gd` | 4 | new `ShopWindow` |
| `scripts/ui/pause_menu.gd` | 4 | Equipo page |
| `CLAUDE.md` | 5 | docs |

---

### Task 1: Equipment, shop, inn and chest rules, gold and save v3

**Files:**
- Create: `scripts/game/equipment.gd`, `scripts/game/loadout.gd`, `scripts/game/shop.gd`, `scripts/game/inn.gd`, `scripts/game/chests.gd`
- Modify (whole file): `scripts/game/game_state.gd`, `scripts/game/save_data.gd`
- Modify: `scripts/game/inventory.gd`, `scripts/battle/combatant.gd`, `data/hero.tres`, `data/rey_slime.tres`
- Temporary (never committed): `balance_check.gd`

**Interfaces:**
- Consumes: `Combatant.equip_attack` / `equip_defense` / `total_attack()` / `total_defense()`, `Inventory` (`ITEMS`, `IDS`, `count()`, `add()`, `take()`, `display_name()`, `article()`), `Leveling.sync_skills()`, `BattleEngine`, `BattleAutoplay`, `EncounterTable` (phase 3).
- Produces:
  - `Equipment`: consts `WEAPON`, `ARMOR`, `SHIELD`, `SLOTS: Array[String]`, `SLOT_NAMES`, `STICK`, `CLOTHES`, `COPPER_SWORD`, `LEATHER_MAIL`, `WOODEN_SHIELD`, `STICK_MESH`, `EQUIPMENT`; `static exists(id: String) -> bool`, `display_name(id: String) -> String`, `article(id: String) -> String`, `pronoun(id: String) -> String`, `slot(id: String) -> String`, `bonus(id: String) -> int`, `price(id: String) -> int`, `mesh(id: String) -> String`, `stat_name(id: String) -> String`, `of_zone(zone: int) -> Array[String]`
  - `Loadout`: `worn(slot: String) -> String`, `is_worn(id: String) -> bool`, `equip(id: String) -> String`, `unequip(slot: String) -> String`, `attack_bonus() -> int`, `defense_bonus() -> int`, `to_dict() -> Dictionary`, `set_slots(slots: Dictionary) -> void`
  - `Shop`: `VILLACLARO`, `SHOPS`, `NO_GOLD`, `WORN`, `WORTHLESS`, `NOT_CARRIED`, `AUTOPLAY_POTIONS`; `static keeper(shop_id) -> String`, `stock(shop_id) -> Array[String]`, `is_equipment(id) -> bool`, `display_name(id)`, `article(id)`, `price(id) -> int`, `sell_price(id) -> int`, `buy_problem(state: GameState, id) -> String`, `can_buy(state, id) -> bool`, `buy(state, id) -> Dictionary` (`{ok, text}`), `sell_list(state) -> Array[String]`, `sell_count(state, id) -> int`, `sell_problem(state, id) -> String`, `sell(state, id) -> Dictionary`, `compare(state, id) -> Dictionary` (`{stat, worn, bonus, diff}`, empty for items), `autoplay_picks(state, shop_id) -> Array[String]`
  - `Inn`: `VILLACLARO`, `INNS`; `static keeper(inn_id) -> String`, `price(inn_id) -> int`, `offer(inn_id) -> String`, `stay(state: GameState, inn_id) -> Dictionary` (`{ok, text}`)
  - `Chests`: `CHESTS`; `static open(state: GameState, id: String) -> Dictionary` (`{opened, text}`)
  - `GameState`: `START_GOLD = 50`; `var gold`, `loadout: Loadout`, `bag_equipment: Array[String]`, `opened_chests: Array[String]`; `refresh_equipment() -> void`, `equip(id: String) -> bool`, `unequip(slot: String) -> void`, `defeat_gold_loss() -> int`
  - `SaveData`: `VERSION = 3`, `OLDEST_VERSION = 2`; `"loadout"`, `"bag"`, `"chests"` in the save

- [ ] **Step 1: Create the branch**

Phase 3 must already be merged into `develop`:

```powershell
git checkout develop
if ((Test-Path scripts/world/encounter_table.gd) -and (Select-String -Quiet "const VERSION := 2" scripts/game/save_data.gd)) { "develop has phase 3" } else { "STOP: merge feature/combate-completo into develop first" }
git checkout -b feature/economia-equipo
```

Expected: `develop has phase 3` and `Switched to a new branch 'feature/economia-equipo'`. If it prints STOP, stop and report.

- [ ] **Step 2: Create `scripts/game/equipment.gd`**

```gdscript
class_name Equipment extends RefCounted
## The equipment catalog: every weapon, armor and shield, with its slot, bonus (ATK for
## a weapon, DEF for armor and shields), price in gold, the zone whose shop sells it (0:
## no shop, the starting gear) and the mesh the hero shows for it (a handslot mesh of
## Knight.glb, STICK_MESH built in code, or "" for none). Pure: no nodes.

const WEAPON := "weapon"
const ARMOR := "armor"
const SHIELD := "shield"
## Slot order of every list (status, Equipo page, shop comparison).
const SLOTS: Array[String] = [WEAPON, ARMOR, SHIELD]
const SLOT_NAMES := {WEAPON: "Arma", ARMOR: "Armadura", SHIELD: "Escudo"}

const STICK := "palo"
const CLOTHES := "ropa"
const COPPER_SWORD := "espada_cobre"
const LEATHER_MAIL := "cota_cuero"
const WOODEN_SHIELD := "escudo_madera"
## Not a Knight.glb mesh: BattleActor builds a plain wooden stick for it.
const STICK_MESH := "stick"

const EQUIPMENT := {
	STICK: {"name": "Palo", "article": "un", "slot": WEAPON, "bonus": 2, "price": 0,
		"zone": 0, "mesh": STICK_MESH},
	CLOTHES: {"name": "Ropa", "article": "una", "slot": ARMOR, "bonus": 2, "price": 0,
		"zone": 0, "mesh": ""},
	COPPER_SWORD: {"name": "Espada de cobre", "article": "una", "slot": WEAPON, "bonus": 6,
		"price": 40, "zone": 1, "mesh": "1H_Sword"},
	LEATHER_MAIL: {"name": "Cota de cuero", "article": "una", "slot": ARMOR, "bonus": 5,
		"price": 30, "zone": 1, "mesh": ""},
	WOODEN_SHIELD: {"name": "Escudo de madera", "article": "un", "slot": SHIELD, "bonus": 3,
		"price": 25, "zone": 1, "mesh": "Round_Shield"},
	"espada_hierro": {"name": "Espada de hierro", "article": "una", "slot": WEAPON,
		"bonus": 12, "price": 150, "zone": 2, "mesh": "1H_Sword"},
	"cota_malla": {"name": "Cota de malla", "article": "una", "slot": ARMOR, "bonus": 10,
		"price": 120, "zone": 2, "mesh": ""},
	"escudo_hierro": {"name": "Escudo de hierro", "article": "un", "slot": SHIELD,
		"bonus": 5, "price": 90, "zone": 2, "mesh": "Rectangle_Shield"},
	"espada_acero": {"name": "Espada de acero", "article": "una", "slot": WEAPON,
		"bonus": 20, "price": 400, "zone": 3, "mesh": "2H_Sword"},
	"armadura_acero": {"name": "Armadura de acero", "article": "una", "slot": ARMOR,
		"bonus": 16, "price": 350, "zone": 3, "mesh": ""},
	"escudo_acero": {"name": "Escudo de acero", "article": "un", "slot": SHIELD,
		"bonus": 8, "price": 220, "zone": 3, "mesh": "Badge_Shield"},
	"espada_platino": {"name": "Espada de platino", "article": "una", "slot": WEAPON,
		"bonus": 28, "price": 650, "zone": 4, "mesh": "2H_Sword"},
	"armadura_platino": {"name": "Armadura de platino", "article": "una", "slot": ARMOR,
		"bonus": 22, "price": 550, "zone": 4, "mesh": ""},
	"escudo_platino": {"name": "Escudo de platino", "article": "un", "slot": SHIELD,
		"bonus": 10, "price": 300, "zone": 4, "mesh": "Spike_Shield"},
}


static func exists(id: String) -> bool:
	return EQUIPMENT.has(id)


static func display_name(id: String) -> String:
	return EQUIPMENT[id].name if EQUIPMENT.has(id) else id


static func article(id: String) -> String:
	return EQUIPMENT[id].article if EQUIPMENT.has(id) else "un"


## "lo" or "la", for "¿Te lo equipas ahora?".
static func pronoun(id: String) -> String:
	return "la" if article(id) == "una" else "lo"


static func slot(id: String) -> String:
	return EQUIPMENT[id].slot if EQUIPMENT.has(id) else ""


## ATK for a weapon, DEF for armor and shields; 0 for "" (nothing worn).
static func bonus(id: String) -> int:
	return EQUIPMENT[id].bonus if EQUIPMENT.has(id) else 0


static func price(id: String) -> int:
	return EQUIPMENT[id].price if EQUIPMENT.has(id) else 0


static func mesh(id: String) -> String:
	return EQUIPMENT[id].mesh if EQUIPMENT.has(id) else ""


## "ATK" for weapons, "DEF" for the rest.
static func stat_name(id: String) -> String:
	return "ATK" if slot(id) == WEAPON else "DEF"


## The ids sold in a zone, in catalog order.
static func of_zone(zone: int) -> Array[String]:
	var ids: Array[String] = []
	for id: String in EQUIPMENT:
		if EQUIPMENT[id].zone == zone:
			ids.append(id)
	return ids
```

- [ ] **Step 3: Create `scripts/game/loadout.gd`**

```gdscript
class_name Loadout extends RefCounted
## What the hero wears: one Equipment id per slot ("" for an empty slot). Starts with the
## Palo and the Ropa and no shield. Pure: no nodes; GameState copies the bonuses into the
## hero (Combatant.equip_attack / equip_defense).

var _slots := {
	Equipment.WEAPON: Equipment.STICK,
	Equipment.ARMOR: Equipment.CLOTHES,
	Equipment.SHIELD: "",
}


## The id worn in slot ("" if empty).
func worn(slot: String) -> String:
	return _slots.get(slot, "")


func is_worn(id: String) -> bool:
	return id != "" and worn(Equipment.slot(id)) == id


## Puts id on in its slot and returns what was there ("" if it was empty).
func equip(id: String) -> String:
	var slot := Equipment.slot(id)
	var removed: String = _slots[slot]
	_slots[slot] = id
	return removed


## Empties slot and returns what was there ("" if it was already empty).
func unequip(slot: String) -> String:
	var removed: String = _slots[slot]
	_slots[slot] = ""
	return removed


func attack_bonus() -> int:
	return Equipment.bonus(worn(Equipment.WEAPON))


func defense_bonus() -> int:
	return Equipment.bonus(worn(Equipment.ARMOR)) + Equipment.bonus(worn(Equipment.SHIELD))


## Copy as slot -> id, for the save game.
func to_dict() -> Dictionary:
	return _slots.duplicate()


## Replaces every slot (slot -> id), when a game is loaded. Unknown slots are ignored.
func set_slots(slots: Dictionary) -> void:
	for slot in Equipment.SLOTS:
		_slots[slot] = slots.get(slot, "")
```

- [ ] **Step 4: Create `scripts/game/shop.gd`**

```gdscript
class_name Shop extends RefCounted
## Shop rules: what each shop sells, buying, selling at half price and comparing a piece
## of equipment with what the hero wears. Pure: works on a GameState, never touches
## nodes. buy() and sell() return {"ok": bool, "text": String} with the message to show.

const VILLACLARO := "villaclaro"
## shop id -> keeper's name, equipment and items (Inventory ids) on sale, in list order.
## Zone 1 sells no Éter (it comes with the zone 2 shop).
const SHOPS := {
	VILLACLARO: {
		"keeper": "Mercader",
		"equipment": [Equipment.COPPER_SWORD, Equipment.LEATHER_MAIL, Equipment.WOODEN_SHIELD],
		"items": [Inventory.POTION, Inventory.ANTIDOTE],
	},
}
const NO_GOLD := "Falta oro"
const WORN := "Lo llevas puesto"
const WORTHLESS := "No vale nada"
const NOT_CARRIED := "No lo llevas"
## Potions --autoplay keeps in stock once it has the shop's equipment.
const AUTOPLAY_POTIONS := 3


static func keeper(shop_id: String) -> String:
	return SHOPS[shop_id].keeper


## Every id on sale: equipment first, then items.
static func stock(shop_id: String) -> Array[String]:
	var ids: Array[String] = []
	ids.assign(SHOPS[shop_id].equipment + SHOPS[shop_id].items)
	return ids


static func is_equipment(id: String) -> bool:
	return Equipment.exists(id)


static func display_name(id: String) -> String:
	return Equipment.display_name(id) if is_equipment(id) else Inventory.display_name(id)


static func article(id: String) -> String:
	return Equipment.article(id) if is_equipment(id) else Inventory.article(id)


static func price(id: String) -> int:
	return Equipment.price(id) if is_equipment(id) else int(Inventory.ITEMS[id].price)


## What the shop pays for id: half its price, rounded down.
static func sell_price(id: String) -> int:
	return floori(price(id) / 2.0)


## Why state can't buy id now ("" if it can).
static func buy_problem(state: GameState, id: String) -> String:
	return NO_GOLD if state.gold < price(id) else ""


static func can_buy(state: GameState, id: String) -> bool:
	return buy_problem(state, id) == ""


## Pays and puts the piece in the bag (equipment) or the inventory (items).
static func buy(state: GameState, id: String) -> Dictionary:
	var why := buy_problem(state, id)
	if why != "":
		return {"ok": false, "text": "%s." % why}
	state.gold -= price(id)
	if is_equipment(id):
		state.bag_equipment.append(id)
	else:
		state.inventory.add(id)
	return {"ok": true, "text": "Compras %s %s por %d G." % [article(id), display_name(id),
		price(id)]}


## What can be offered for sale, in list order: the equipment worn (it can't be sold, but
## is listed), the equipment in the bag (one row per id) and the items carried.
static func sell_list(state: GameState) -> Array[String]:
	var ids: Array[String] = []
	for slot in Equipment.SLOTS:
		var worn := state.loadout.worn(slot)
		if worn != "":
			ids.append(worn)
	for id: String in Equipment.EQUIPMENT:
		if id in state.bag_equipment and not ids.has(id):
			ids.append(id)
	for id in Inventory.IDS:
		if state.inventory.count(id) > 0:
			ids.append(id)
	return ids


## How many of id the hero carries that could be sold (the worn one does not count).
static func sell_count(state: GameState, id: String) -> int:
	if is_equipment(id):
		return state.bag_equipment.count(id)
	return state.inventory.count(id)


## Why id can't be sold ("" if it can): worn and none in the bag, or worth nothing.
static func sell_problem(state: GameState, id: String) -> String:
	if sell_count(state, id) <= 0:
		return WORN if state.loadout.is_worn(id) else NOT_CARRIED
	if sell_price(id) <= 0:
		return WORTHLESS
	return ""


static func sell(state: GameState, id: String) -> Dictionary:
	var why := sell_problem(state, id)
	if why != "":
		return {"ok": false, "text": "%s." % why}
	if is_equipment(id):
		state.bag_equipment.erase(id)
	else:
		state.inventory.take(id)
	state.gold += sell_price(id)
	return {"ok": true, "text": "Vendes %s %s por %d G." % [article(id), display_name(id),
		sell_price(id)]}


## Compares a piece with what is worn in its slot: {"stat": "ATK" / "DEF", "worn": id
## worn ("" if none), "bonus": the piece's bonus, "diff": bonus minus the worn one's}.
## Empty for items.
static func compare(state: GameState, id: String) -> Dictionary:
	if not is_equipment(id):
		return {}
	var worn := state.loadout.worn(Equipment.slot(id))
	return {"stat": Equipment.stat_name(id), "worn": worn, "bonus": Equipment.bonus(id),
		"diff": Equipment.bonus(id) - Equipment.bonus(worn)}


## For --autoplay: the equipment of the shop that beats what is worn and is not in the
## bag yet, in slot order, as long as the gold lasts. Once there is no such piece left
## (bought or not), potions up to AUTOPLAY_POTIONS.
static func autoplay_picks(state: GameState, shop_id: String) -> Array[String]:
	var picks: Array[String] = []
	var gold := state.gold
	var upgrades := 0
	for id: String in SHOPS[shop_id].equipment:
		if compare(state, id).diff <= 0 or id in state.bag_equipment:
			continue
		upgrades += 1
		if gold >= price(id):
			picks.append(id)
			gold -= price(id)
	if upgrades > 0:
		return picks
	var potions := state.inventory.count(Inventory.POTION)
	while potions < AUTOPLAY_POTIONS and gold >= price(Inventory.POTION):
		picks.append(Inventory.POTION)
		gold -= price(Inventory.POTION)
		potions += 1
	return picks
```

- [ ] **Step 5: Create `scripts/game/inn.gd`**

```gdscript
class_name Inn extends RefCounted
## Inn rules: a night costs the inn's price and restores all HP and MP (Game adds the
## fade to black and the autosave). Villaclaro has one as the model for the inns of the
## later zones (15, 30 and 50 G); there the old woman already heals for free. Pure: works
## on a GameState, never touches nodes.

const VILLACLARO := "villaclaro"
## inn id -> keeper's name and price of a night in gold.
const INNS := {
	VILLACLARO: {"keeper": "Posadero", "price": 5},
}


static func keeper(inn_id: String) -> String:
	return INNS[inn_id].keeper


static func price(inn_id: String) -> int:
	return INNS[inn_id].price


## The keeper's question, with the price.
static func offer(inn_id: String) -> String:
	return "Una noche cuesta %d G. ¿Quieres descansar?" % price(inn_id)


## Pays and heals. Returns {"ok": bool, "text": String} (the keeper's answer).
static func stay(state: GameState, inn_id: String) -> Dictionary:
	if state.gold < price(inn_id):
		return {"ok": false, "text": "No tienes oro suficiente."}
	state.gold -= price(inn_id)
	state.heal_full()
	return {"ok": true, "text": "¡Buenos días! PV y PM recuperados."}
```

- [ ] **Step 6: Create `scripts/game/chests.gd`**

```gdscript
class_name Chests extends RefCounted
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


## Opens chest id for state: gives what it holds and marks it opened. Equipment goes on
## at once if its slot is empty, else into the bag. Returns {"opened": bool (false if it
## was already open), "text": String}.
static func open(state: GameState, id: String) -> Dictionary:
	if id in state.opened_chests or not CHESTS.has(id):
		return {"opened": false, "text": ""}
	state.opened_chests.append(id)
	var chest: Dictionary = CHESTS[id]
	if chest.has("gold"):
		state.gold += chest.gold
		return {"opened": true, "text": "¡Encuentras %d monedas de oro!" % chest.gold}
	if chest.has("item"):
		state.inventory.add(chest.item)
		return {"opened": true, "text": "¡Encuentras %s %s!" % [
			Inventory.article(chest.item), Inventory.display_name(chest.item)]}
	var piece: String = chest.equipment
	var text := "¡Encuentras %s %s!" % [Equipment.article(piece), Equipment.display_name(piece)]
	state.bag_equipment.append(piece)
	if state.loadout.worn(Equipment.slot(piece)) == "":
		state.equip(piece)
		text += " Te %s equipas." % Equipment.pronoun(piece)
	return {"opened": true, "text": text}
```

- [ ] **Step 7: Replace `scripts/game/game_state.gd`**

```gdscript
class_name GameState extends RefCounted
## State of the play session, kept in memory while the game is open. The hero, the
## inventory, the gold, the equipment and the village quest live here for the whole
## session; battles, shops, chests and dialogue change them in place.

const START_GOLD := 50

var hero: Combatant
var inventory := Inventory.new()
var quest := Quest.new()
var gold := START_GOLD
## What the hero wears; its bonuses are copied into the hero by refresh_equipment().
var loadout := Loadout.new()
## Equipment carried but not worn (Equipment ids; the same id may appear more than once).
var bag_equipment: Array[String] = []
## Ids of the chests already opened (Chests.CHESTS keys).
var opened_chests: Array[String] = []


func _init(hero_data: Combatant) -> void:
	hero = hero_data.duplicate() as Combatant
	# Its own list: learning a spell must never change the one in hero.tres.
	hero.skills = hero_data.skills.duplicate()
	inventory.add(Inventory.POTION, Inventory.START_POTIONS)
	refresh_equipment()


## Back to full HP and MP, used after a defeat and when talking to the old woman.
func heal_full() -> void:
	hero.hp = hero.max_hp
	hero.mp = hero.max_mp


## Uses an item outside battle, from the pause menu; see Inventory.use().
func use_item(id: String) -> Dictionary:
	return inventory.use(id, hero, false)


## Copies the loadout's bonuses into the hero (battles read total_attack/defense()).
func refresh_equipment() -> void:
	hero.equip_attack = loadout.attack_bonus()
	hero.equip_defense = loadout.defense_bonus()


## Puts on a piece from the bag; what it replaces goes to the bag. False if id is not
## in the bag.
func equip(id: String) -> bool:
	var index := bag_equipment.find(id)
	if index < 0:
		return false
	bag_equipment.remove_at(index)
	var removed := loadout.equip(id)
	if removed != "":
		bag_equipment.append(removed)
	refresh_equipment()
	return true


## Takes off what is worn in slot and puts it in the bag.
func unequip(slot: String) -> void:
	var removed := loadout.unequip(slot)
	if removed != "":
		bag_equipment.append(removed)
	refresh_equipment()


## Gold lost on a defeat: half of what is carried, rounded down (gold - lost remains).
func defeat_gold_loss() -> int:
	return floori(gold / 2.0)
```

- [ ] **Step 8: Replace `scripts/game/save_data.gd`**

```gdscript
class_name SaveData extends RefCounted
## Turns the session into a Dictionary that SaveStore writes as JSON, and back. Pure:
## no nodes, no files. JSON reads every number as a float, so apply() converts them.
## VERSION goes in every save so a later format can migrate older files. Version 2 (full
## combat) adds the gold and changes how the hero grows, so version 1 saves are refused.
## The spells are not saved: Leveling.sync_skills() gives them back from the level.
## Version 3 (economy and equipment) adds the loadout, the equipment in the bag and the
## opened chests; a version 2 save still loads, with the starting gear, an empty bag and
## every chest closed.

const VERSION := 3
## Oldest version apply() still reads.
const OLDEST_VERSION := 2
## Combatant fields of the hero that change while playing (the rest come from hero.tres).
const HERO_FIELDS: Array[String] = ["level", "experience", "hp", "max_hp", "mp", "max_mp",
	"attack", "defense", "speed"]


static func from_state(state: GameState, player_pos: Vector3, play_time: float) -> Dictionary:
	var hero := {}
	for field in HERO_FIELDS:
		hero[field] = state.hero.get(field)
	return {
		"version": VERSION,
		"hero": hero,
		"inventory": state.inventory.to_dict(),
		"quest": {"stage": state.quest.stage, "kills": state.quest.kills},
		"gold": state.gold,
		"loadout": state.loadout.to_dict(),
		"bag": state.bag_equipment.duplicate(),
		"chests": state.opened_chests.duplicate(),
		"position": [player_pos.x, player_pos.z],
		"play_time": play_time,
	}


## Loads data into state. Returns {"valid": bool, "position": Vector3, "play_time":
## float}; when valid is false, state is left untouched.
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
```

- [ ] **Step 9: Comments, hero data and the Rey Slime**

In `scripts/game/inventory.gd`:

1. Replace:

```gdscript
## value MP) or "cure" (removes the status named by value); price in gold (shops come
## later); battle / field: usable in battle / from the pause menu.
```

with:

```gdscript
## value MP) or "cure" (removes the status named by value); price in gold (Shop sells
## at it and buys back at half); battle / field: usable in battle / from the pause menu.
```

In `scripts/battle/combatant.gd`:

1. Replace:

```gdscript
## Hero only: fixed bonuses of the starting equipment (Palo +2 ATK, Ropa +2 DEF) until
## equipment becomes a system of its own.
```

with:

```gdscript
## Hero only: bonuses of the equipment worn, copied from the Loadout by
## GameState.refresh_equipment() (never saved: the loadout is).
```

In `data/hero.tres`:

1. Replace:

```ini
defense = 5
equip_attack = 2
equip_defense = 2
```

with:

```ini
defense = 5
```

In `data/rey_slime.tres`:

1. Replace:

```ini
max_hp = 142
hp = 142
```

with:

```ini
max_hp = 128
hp = 128
```

- [ ] **Step 10: Import and check**

```powershell
.\tools\godot.cmd --headless --path . --import
foreach ($s in "game/equipment","game/loadout","game/shop","game/inn","game/chests","game/game_state","game/save_data","game/inventory","battle/combatant","game/game") { .\tools\godot.cmd --headless --path . --check-only --script "res://scripts/$s.gd" }
```

Expected: no line with `ERROR` or `WARNING` (the import lists the new classes).

- [ ] **Step 11: One-off balance check (temporary file at the project root)**

Create `balance_check.gd`:

```gdscript
extends SceneTree
## One-off balance check for the economía y equipo plan (Task 1). Not committed: delete
## it after reading the output. Plays BATTLES battles per line with the real
## BattleEngine and BattleAutoplay (fixed seed) and prints the win rate, the HP lost by
## the winners (share of max HP) and the rounds, with the starting gear (Palo, Ropa) and
## with the zone 1 shop gear (Espada de cobre, Cota de cuero, Escudo de madera), equipped
## through GameState like in the game.

const HERO := preload("res://data/hero.tres")
const BOSS := preload("res://data/rey_slime.tres")
const BATTLES := 4000
const GEAR := {
	"start gear": [],
	"zone 1 gear": [Equipment.COPPER_SWORD, Equipment.LEATHER_MAIL, Equipment.WOODEN_SHIELD],
}

var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.seed = 12345
	for tag: String in GEAR:
		_report("Lv1 near start, %s" % tag, 1, GEAR[tag], EncounterTable.START_FORMATIONS, 0)
		for level in [2, 3, 5]:
			_report("Lv%d zone 1, %s" % [level, tag], level, GEAR[tag], EncounterTable.ZONES[1], 0)
		for level in [3, 4, 5, 6]:
			_report("Lv%d Rey Slime, 3 potions, %s" % [level, tag], level, GEAR[tag],
				[[BOSS]], 3)
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
			engine.resolve_round(bot.choose(engine))
			played += 1
		if engine.state == BattleEngine.State.WON:
			wins += 1
			lost += float(hero.max_hp - hero.hp) / hero.max_hp
			rounds += played
	print("%-38s wins %5.1f %%  HP lost %3.0f %%  rounds %4.1f" % [label,
		100.0 * wins / BATTLES, 100.0 * lost / maxi(1, wins), float(rounds) / maxi(1, wins)])
```

Run it, compare, delete it:

```powershell
.\tools\godot.cmd --headless --path . --script res://balance_check.gd
Remove-Item balance_check.gd, balance_check.gd.uid -ErrorAction SilentlyContinue
```

Expected (the seed is fixed, so the numbers should match exactly; anything more than one point away means the rules differ from this plan):

```
Lv1 near start, start gear             wins  99.8 %  HP lost  16 %  rounds  2.1
Lv2 zone 1, start gear                 wins  95.4 %  HP lost  25 %  rounds  2.3
Lv3 zone 1, start gear                 wins  99.8 %  HP lost  20 %  rounds  2.4
Lv5 zone 1, start gear                 wins 100.0 %  HP lost  17 %  rounds  2.9
Lv3 Rey Slime, 3 potions, start gear   wins  16.8 %  HP lost  42 %  rounds 18.6
Lv4 Rey Slime, 3 potions, start gear   wins  50.3 %  HP lost  38 %  rounds 17.0
Lv5 Rey Slime, 3 potions, start gear   wins  74.3 %  HP lost  44 %  rounds 15.0
Lv6 Rey Slime, 3 potions, start gear   wins  86.6 %  HP lost  45 %  rounds 13.4
Lv1 near start, zone 1 gear            wins 100.0 %  HP lost   6 %  rounds  2.2
Lv2 zone 1, zone 1 gear                wins  98.7 %  HP lost  21 %  rounds  2.9
Lv3 zone 1, zone 1 gear                wins 100.0 %  HP lost  16 %  rounds  2.9
Lv5 zone 1, zone 1 gear                wins 100.0 %  HP lost   9 %  rounds  2.6
Lv3 Rey Slime, 3 potions, zone 1 gear  wins  53.5 %  HP lost  34 %  rounds 14.6
Lv4 Rey Slime, 3 potions, zone 1 gear  wins  69.2 %  HP lost  35 %  rounds 13.0
Lv5 Rey Slime, 3 potions, zone 1 gear  wins  87.2 %  HP lost  42 %  rounds 11.2
Lv6 Rey Slime, 3 potions, zone 1 gear  wins  94.8 %  HP lost  43 %  rounds  9.3
```

The start-gear normal lines are the phase 3 numbers (the Palo and the Ropa give the same +2 / +2 as before).

- [ ] **Step 12: The game still runs**

```powershell
.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 4000 -- --autoplay
Remove-Item "$env:APPDATA\Godot\app_userdata\rpg-turnos\save_autoplay.json" -ErrorAction SilentlyContinue
```

Expected: battles and dialogue print as in phase 3; no `ERROR`, at most the Jolt warning.

- [ ] **Step 13: Commit**

```powershell
git add scripts data
git status --short
git commit -m "Add equipment, shop, inn and chest rules with gold and save version 3"
```

`git status --short` must not list `balance_check.gd`.

---

### Task 2: Weapon and shield on the knight, gold lost in battle

**Files:**
- Modify: `scripts/battle/battle_actor.gd`, `scripts/world/player.gd`, `scripts/battle/battle_scene.gd`, `scripts/ui/battle_result.gd`
- Temporary (never committed): `gear_probe.gd`, `gear_probe.tscn`

**Interfaces:**
- Consumes: `Equipment.mesh()`, `Equipment.STICK`, `Equipment.STICK_MESH`.
- Produces:
  - `BattleActor`: `enum Look { HERO, SLIME, VILLAGER, KING_SLIME, BAT, MUSHROOM, MERCHANT, INNKEEPER }`, consts `HAND_R`, `HAND_L`, `STICK_COLOR`, `STICK_RADIUS`, `STICK_LENGTH`, `STICK_CENTER`; `set_equipment(weapon_id: String, shield_id: String) -> void` (hero only; starts with the Palo); `LOOKS` entries may carry `"tint"`
  - `Player`: `set_equipment(weapon_id: String, shield_id: String) -> void`
  - `BattleScene`: `var gold_lost := 0`; `set_equipment(weapon_id: String, shield_id: String) -> void` (before adding it)
  - `BattleResult`: `show_defeat(gold_lost := 0) -> void`

- [ ] **Step 1: Edit the four files**

In `scripts/battle/battle_actor.gd`:

1. Replace:

```gdscript
enum Look { HERO, SLIME, VILLAGER, KING_SLIME, BAT, MUSHROOM }
```

with:

```gdscript
enum Look { HERO, SLIME, VILLAGER, KING_SLIME, BAT, MUSHROOM, MERCHANT, INNKEEPER }
```

2. Replace:

```gdscript
const SLIME_SEGMENTS := 9
## Everything that changes between looks. Characters: scene, scale, top (height of the
## damage numbers), hide (prop nodes of the model to hide) and anims. Slimes: color,
```

with:

```gdscript
const SLIME_SEGMENTS := 9
## Hand slots of the KayKit characters (BoneAttachment3D nodes).
const HAND_R := "Rig/Skeleton3D/handslot_r"
const HAND_L := "Rig/Skeleton3D/handslot_l"
## The wooden stick built in code for Equipment.STICK_MESH: along the hand's +Y like the
## Knight's swords, grip at the hand.
const STICK_COLOR := Color(0.45, 0.3, 0.16)
const STICK_RADIUS := 0.07
const STICK_LENGTH := 1.3
const STICK_CENTER := 0.45
## Everything that changes between looks. Characters: scene, scale, top (height of the
## damage numbers), hide (prop nodes of the model to hide), anims and, optional, tint
## (multiplies every imported material: the merchant is a green Mage, the innkeeper an
## orange one); the hero hides
## every hand mesh and shows only those of its equipment (set_equipment()). Slimes: color,
```

3. Replace:

```gdscript
			"Rig/Skeleton3D/handslot_l/Rectangle_Shield",
			"Rig/Skeleton3D/handslot_l/Spike_Shield",
			"Rig/Skeleton3D/handslot_r/2H_Sword",
```

with:

```gdscript
			"Rig/Skeleton3D/handslot_l/Rectangle_Shield",
			"Rig/Skeleton3D/handslot_l/Round_Shield",
			"Rig/Skeleton3D/handslot_l/Spike_Shield",
			"Rig/Skeleton3D/handslot_r/1H_Sword",
			"Rig/Skeleton3D/handslot_r/2H_Sword",
```

4. Replace:

```gdscript
			"Rig/Skeleton3D/handslot_r/1H_Wand",
		],
		"anims": CHARACTER_ANIMS,
	},
```

with:

```gdscript
			"Rig/Skeleton3D/handslot_r/1H_Wand",
		],
		"anims": CHARACTER_ANIMS,
	},
	Look.MERCHANT: {
		"scene": MAGE,
		"scale": CHARACTER_SCALE,
		"top": 2.2,
		"hide": [
			"Rig/Skeleton3D/handslot_l/Spellbook",
			"Rig/Skeleton3D/handslot_l/Spellbook_open",
			"Rig/Skeleton3D/handslot_r/1H_Wand",
		],
		"anims": CHARACTER_ANIMS,
		"tint": Color(0.75, 1.0, 0.65),
	},
	Look.INNKEEPER: {
		"scene": MAGE,
		"scale": CHARACTER_SCALE,
		"top": 2.2,
		"hide": [
			"Rig/Skeleton3D/handslot_l/Spellbook",
			"Rig/Skeleton3D/handslot_l/Spellbook_open",
			"Rig/Skeleton3D/handslot_r/1H_Wand",
		],
		"anims": CHARACTER_ANIMS,
		"tint": Color(1.0, 0.75, 0.5),
	},
```

5. Replace:

```gdscript
## Bat only: the two wing pivots, flapped by the idle loop.
var _wings: Array[Node3D] = []
```

with:

```gdscript
## Bat only: the two wing pivots, flapped by the idle loop.
var _wings: Array[Node3D] = []
## Characters only: the imported model (its hand slots hold the equipment meshes).
var _model: Node3D
```

6. Replace:

```gdscript
## Swings (characters) and lunges toward the target and steps back.
```

with:

```gdscript
## Hero only: shows the hand meshes of the weapon and shield worn (Equipment ids, ""
## for none) and hides the rest. Armor does not change the model. Others ignore it.
func set_equipment(weapon_id: String, shield_id: String) -> void:
	if look != Look.HERO or _model == null:
		return
	var shown := {HAND_R: Equipment.mesh(weapon_id), HAND_L: Equipment.mesh(shield_id)}
	for hand: String in shown:
		for child in _model.get_node(hand).get_children():
			(child as Node3D).visible = child.name == shown[hand] and shown[hand] != ""


## Swings (characters) and lunges toward the target and steps back.
```

7. Replace:

```gdscript
	_body.add_child(model)
	for path in data.hide:
		(model.get_node(path) as Node3D).hide()
```

with:

```gdscript
	_body.add_child(model)
	_model = model
	for path in data.hide:
		(model.get_node(path) as Node3D).hide()
	if data.has("tint"):
		_tint(model, data.tint)
	if look == Look.HERO:
		var stick := _cylinder(STICK_RADIUS, STICK_LENGTH)
		stick.top_radius = STICK_RADIUS * 0.7
		_add_mesh(model.get_node(HAND_R), stick, STICK_COLOR, Vector3(0, STICK_CENTER, 0))
		var mi := model.get_node(HAND_R).get_child(-1) as MeshInstance3D
		mi.name = Equipment.STICK_MESH
		# The starting gear until set_equipment() says otherwise.
		set_equipment(Equipment.STICK, "")
```

8. Replace:

```gdscript
## Additive overlay on every mesh, so it works on the imported materials too.
```

with:

```gdscript
## Gives every mesh of an imported model copies of its materials with albedo_color
## multiplied by color (the texture is multiplied too).
static func _tint(model: Node3D, color: Color) -> void:
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		for i in mi.mesh.get_surface_count():
			var source := mi.get_active_material(i) as BaseMaterial3D
			if source == null:
				continue
			var tinted := source.duplicate() as BaseMaterial3D
			tinted.albedo_color = source.albedo_color * color
			mi.set_surface_override_material(i, tinted)


## Additive overlay on every mesh, so it works on the imported materials too.
```

In `scripts/world/player.gd`:

1. Replace:

```gdscript
## Puts the player at pos with the model turned to facing_yaw (0 faces -Z).
```

with:

```gdscript
## Shows the weapon and shield worn on the model (Equipment ids, "" for none).
func set_equipment(weapon_id: String, shield_id: String) -> void:
	_model.set_equipment(weapon_id, shield_id)


## Puts the player at pos with the model turned to facing_yaw (0 faces -Z).
```

In `scripts/battle/battle_scene.gd`:

1. Replace:

```gdscript
## Seconds per typed character of the messages (the text speed option).
var char_time := BattleHud.CHAR_TIME
```

with:

```gdscript
## Seconds per typed character of the messages (the text speed option).
var char_time := BattleHud.CHAR_TIME
## Gold the hero loses if defeated (Game takes it away; the battle only says so).
var gold_lost := 0
```

2. Replace:

```gdscript
var _audio: AudioDirector
```

with:

```gdscript
var _audio: AudioDirector
## Equipment ids the hero's figure shows (set_equipment()).
var _weapon_id := Equipment.STICK
var _shield_id := ""
```

3. Replace:

```gdscript
## Call before adding it to the tree, like setup().
func set_audio(audio: AudioDirector) -> void:
	_audio = audio
```

with:

```gdscript
## Call before adding it to the tree, like setup().
func set_audio(audio: AudioDirector) -> void:
	_audio = audio


## The weapon and shield the hero's figure holds (Equipment ids, "" for none). Call
## before adding it to the tree; without it the hero holds the starting Palo.
func set_equipment(weapon_id: String, shield_id: String) -> void:
	_weapon_id = weapon_id
	_shield_id = shield_id
```

4. Replace:

```gdscript
	_hero_actor = _spawn_actor(BattleActor.Look.HERO, HERO_POS, ENEMY_POS)
```

with:

```gdscript
	_hero_actor = _spawn_actor(BattleActor.Look.HERO, HERO_POS, ENEMY_POS)
	_hero_actor.set_equipment(_weapon_id, _shield_id)
```

5. Replace:

```gdscript
		BattleEngine.State.LOST:
			_result.show_defeat()
```

with:

```gdscript
		BattleEngine.State.LOST:
			if gold_lost > 0:
				await _say("Pierdes %d monedas de oro." % gold_lost)
			_result.show_defeat(gold_lost)
```

In `scripts/ui/battle_result.gd`:

1. Replace:

```gdscript
func show_defeat() -> void:
	_title.text = "Has sido derrotado"
	_detail.text = "Volverás al inicio."
	_open()
```

with:

```gdscript
## gold_lost: the gold taken from the hero (0 shows no gold line).
func show_defeat(gold_lost := 0) -> void:
	_title.text = "Has sido derrotado"
	_detail.text = "Volverás al inicio."
	if gold_lost > 0:
		_detail.text = "Pierdes %d G.\nVolverás al inicio." % gold_lost
	_open()
```

2. Replace:

```gdscript
## End-of-battle overlay: victory (EXP, new level, gold, items left by the enemies) or
## defeat text and a "Continuar" button. Starts hidden; the button hides it and emits
## continue_requested.
```

with:

```gdscript
## End-of-battle overlay: victory (EXP, new level, gold, items left by the enemies) or
## defeat (the gold lost) and a "Continuar" button. Starts hidden; the button hides it
## and emits continue_requested.
```

- [ ] **Step 2: Check and run the test battle**

```powershell
foreach ($s in "battle/battle_actor","world/player","battle/battle_scene","ui/battle_result") { .\tools\godot.cmd --headless --path . --check-only --script "res://scripts/$s.gd" }
.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 3000 res://scenes/battle/battle_scene.tscn -- --autoplay
```

Expected: the checks print nothing; the battle prints its messages and ends with `Fin del combate (estado 1)` (or `2` on a rare defeat), no `ERROR`.

- [ ] **Step 3: Frames of the gear (temporary probe at the project root)**

Create `gear_probe.gd`:

```gdscript
extends Node3D
## One-off look at the hero's gear (Task 2). Not committed: delete it after viewing the
## frames. Left to right: Palo; Espada de cobre and Escudo de madera; Espada de acero and
## Escudo de hierro; the merchant; the innkeeper.

const ACTOR := preload("res://scenes/battle/battle_actor.tscn")
const GEAR := [["palo", ""], ["espada_cobre", "escudo_madera"], ["espada_acero", "escudo_hierro"]]


func _ready() -> void:
	BattleStage.build_environment(self)
	var ground := PlaneMesh.new()
	ground.size = Vector2(20, 20)
	BattleStage.add_mesh(self, ground, BattleStage.GRASS, Vector3.ZERO)
	for i in GEAR.size():
		var hero: BattleActor = ACTOR.instantiate()
		hero.look = BattleActor.Look.HERO
		add_child(hero)
		hero.position = Vector3(-1.6 + i * 1.6, 0, 0)
		hero.rotation.y = PI - 0.5
		hero.set_equipment(GEAR[i][0], GEAR[i][1])
	for i in 2:
		var villager: BattleActor = ACTOR.instantiate()
		villager.look = [BattleActor.Look.MERCHANT, BattleActor.Look.INNKEEPER][i]
		add_child(villager)
		villager.position = Vector3(3.2 + i * 1.4, 0, 0)
		villager.rotation.y = PI
	var camera := Camera3D.new()
	add_child(camera)
	camera.position = Vector3(1.4, 1.6, 5.5)
	camera.look_at(Vector3(1.4, 0.8, 0))
	camera.current = true
```

Create `gear_probe.tscn`:

```ini
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://gear_probe.gd" id="1"]

[node name="GearProbe" type="Node3D"]
script = ExtResource("1")
```

```powershell
$dir = "$env:TEMP\rpg-gear"
New-Item -ItemType Directory -Force $dir | Out-Null
.\tools\godot.cmd --path . res://gear_probe.tscn --resolution 960x540 --write-movie "$dir\g.png" --fixed-fps 10 --quit-after 5
Remove-Item gear_probe.gd, gear_probe.gd.uid, gear_probe.tscn -ErrorAction SilentlyContinue
```

Open `$dir\g00000004.png`. Expected, left to right: a knight holding a brown stick (Palo, empty left hand); a knight with the short sword and the round shield; a knight with the long sword and the rectangular shield; a Mage with a greenish tint (merchant); a Mage with an orange tint (innkeeper). No other weapon or shield shows on any knight. Delete `$dir` afterwards.

- [ ] **Step 4: Commit**

```powershell
git add scripts
git status --short
git commit -m "Show the equipped weapon and shield on the knight and the gold lost on a defeat"
```

`git status --short` must not list `gear_probe`.

---

### Task 3: Merchant, innkeeper and chests on the map, gold in the status window

**Files:**
- Modify: `scripts/world/world_stage.gd`, `scripts/world/player.gd`, `scripts/game/game.gd`
- Modify (whole file): `scripts/world/world.gd`
- Temporary (never committed): `chest_probe.gd`, `chest_probe.tscn`

**Interfaces:**
- Consumes: `Chests.CHESTS`, `Chests.open()`, `Shop.VILLACLARO`, `Inn.VILLACLARO`, `GameState` (Task 1), `BattleActor.Look.MERCHANT` / `INNKEEPER`, `Player.set_equipment()`, `BattleScene.set_equipment()` / `gold_lost` (Task 2).
- Produces:
  - `WorldStage`: `MERCHANT_POS`, `INNKEEPER_POS`, `CHEST_GRASS_MARGIN`, `CHEST_TREE_MARGIN`, `CHEST_BUSH_MARGIN`
  - `Player.AUTOPLAY_ROUTE` with the point (−1.2, 0, −23)
  - `World`: signals `shop_requested(shop_id: String)`, `inn_requested(inn_id: String)`, `chest_opened(chest_id: String)`; consts `CHEST_RADIUS`, `TALK`, `SHOP`, `INN`, `CHEST`, `PROMPTS`, `CHEST_SIZE`, `CHEST_LID_HEIGHT`, `CHEST_WOOD`, `CHEST_BAND`, `CHEST_OPEN_ANGLE`; `refresh_status(hero: Combatant, potions: int, gold: int, quest_text := "")` (new `gold` argument), `freeze(on: bool)` (awaitable when unfreezing), `set_hero_equipment(weapon_id: String, shield_id: String)`, `set_chest_open(chest_id: String, open: bool, instant := false)`, `static build_chest(root: Node3D, chest: Dictionary) -> Node3D` (returns the lid pivot)
  - `Game`: `_on_chest(chest_id)`, gold loss on a defeat, gear on the map and in battle, gold and gear printed on autoplay

- [ ] **Step 1: Edit `scripts/world/world_stage.gd` and `scripts/world/player.gd`**

In `scripts/world/world_stage.gd`:

1. Replace:

```gdscript
const NPC_POS := Vector3(-2.5, 0, -20)
const BOSS_POS := Vector3(0, 0, -27.5)
```

with:

```gdscript
const NPC_POS := Vector3(-2.5, 0, -20)
const BOSS_POS := Vector3(0, 0, -27.5)
## The merchant of the Villaclaro shop, in front of the left house, and the innkeeper, in
## front of the right one.
const MERCHANT_POS := Vector3(-3.0, 0, -23.6)
const INNKEEPER_POS := Vector3(2.8, 0, -22.0)
## Grass, trees and bushes keep this far from the chests (Chests.CHESTS), so every chest
## stands in the open.
const CHEST_GRASS_MARGIN := 1.0
const CHEST_TREE_MARGIN := 2.2
const CHEST_BUSH_MARGIN := 1.2
```

2. Replace:

```gdscript
	if is_on_path(pos, GRASS_PATH_MARGIN):
		return false
	return not _near_rock(pos, GRASS_ROCK_MARGIN)
```

with:

```gdscript
	if is_on_path(pos, GRASS_PATH_MARGIN) or _near_chest(pos, CHEST_GRASS_MARGIN):
		return false
	return not _near_rock(pos, GRASS_ROCK_MARGIN)
```

3. Replace:

```gdscript
	if _near_rock(pos, TREE_ROCK_MARGIN):
		return false
```

with:

```gdscript
	if _near_rock(pos, TREE_ROCK_MARGIN) or _near_chest(pos, CHEST_TREE_MARGIN):
		return false
```

4. Replace:

```gdscript
		if is_on_path(pos, BUSH_PATH_MARGIN) or _near_rock(pos, BUSH_ROCK_MARGIN):
			continue
```

with:

```gdscript
		if is_on_path(pos, BUSH_PATH_MARGIN) or _near_rock(pos, BUSH_ROCK_MARGIN) \
				or _near_chest(pos, CHEST_BUSH_MARGIN):
			continue
```

5. Replace:

```gdscript
## True within margin of the loop Player walks on --autoplay, so no tree blocks it.
```

with:

```gdscript
## True within margin of a chest.
static func _near_chest(pos: Vector3, margin: float) -> bool:
	var p := Vector2(pos.x, pos.z)
	for id: String in Chests.CHESTS:
		var chest_pos: Vector3 = Chests.CHESTS[id].pos
		if p.distance_to(Vector2(chest_pos.x, chest_pos.z)) < margin:
			return true
	return false


## True within margin of the loop Player walks on --autoplay, so no tree blocks it.
```

In `scripts/world/player.gd`:

1. Replace:

```gdscript
## village, next to the old woman and to where the Rey Slime appears.
const AUTOPLAY_ROUTE: Array[Vector3] = [
	Vector3(8, 0, 18),
	Vector3(16, 0, 6),
	Vector3(10, 0, -6),
	Vector3(1, 0, -14),
	Vector3(-1.5, 0, -18),
```

with:

```gdscript
## village, next to the old woman, the merchant, where the Rey Slime appears and the
## innkeeper, and past two of the chests (Chests.CHESTS).
const AUTOPLAY_ROUTE: Array[Vector3] = [
	Vector3(8, 0, 18),
	Vector3(16, 0, 6),
	Vector3(10, 0, -6),
	Vector3(1, 0, -14),
	Vector3(-1.5, 0, -18),
	Vector3(-1.2, 0, -23),
```

- [ ] **Step 2: Replace `scripts/world/world.gd`**

```gdscript
class_name World extends Node3D
## World map: field, village, player, follow camera, status window, chests and random
## encounters. A click or tap on the ground (held and dragged too) walks the player
## there, with a marker on the spot. Next to the old woman, the merchant, the innkeeper
## or a closed chest (the nearest one in reach) Enter / Space talks (talk_requested),
## opens the shop (shop_requested), asks for a room (inn_requested) or opens the chest
## (chest_opened); a click or tap on one of them
## walks there and does it on arrival. With the Rey Slime present, walking into it
## starts the boss battle. Encounters emit encounter_triggered(boss) and freeze the
## player until set_active(true). Run on its own (res://scenes/world/world.tscn) it
## prints each encounter, shop and chest and goes on.

signal encounter_triggered(boss: bool)
signal talk_requested
## The player asked the merchant of shop_id (a Shop.SHOPS key) to trade.
signal shop_requested(shop_id: String)
## The player talked to the innkeeper of inn_id (an Inn.INNS key).
signal inn_requested(inn_id: String)
## The player asked to open a closed chest (a Chests.CHESTS key); Game opens it in the
## GameState and calls set_chest_open().
signal chest_opened(chest_id: String)
## The player walked into (true) or out of (false) the village clearing.
signal village_changed(inside: bool)

const PLAYER_SCENE := preload("res://scenes/world/player.tscn")
const ACTOR_SCENE := preload("res://scenes/battle/battle_actor.tscn")
const HERO_DATA := preload("res://data/hero.tres")
const NOTICE_TIME := 2.0
const FONT_SIZE := 24
## How close the player must be to talk to the old woman or the merchant / to open a
## chest / to run into the boss.
const TALK_RADIUS := 2.5
const CHEST_RADIUS := 1.8
const BOSS_RADIUS := 2.5
## A click or tap this close to a figure or a chest means "go there and use it".
const NPC_TAP_RADIUS := 1.2
## Kinds of the things the player can use on the map, and their prompts.
const TALK := "talk"
const SHOP := "shop"
const INN := "inn"
const CHEST := "chest"
const PROMPTS := {
	TALK: "Enter o toca: hablar",
	SHOP: "Enter o toca: comprar",
	INN: "Enter o toca: hablar",
	CHEST: "Enter o toca: abrir",
}
## Chest model: wooden box with a gold band and a lid hinged at the back.
const CHEST_SIZE := Vector3(0.9, 0.45, 0.6)
const CHEST_LID_HEIGHT := 0.2
const CHEST_WOOD := Color(0.5, 0.3, 0.14)
const CHEST_BAND := Color(1.0, 0.78, 0.2)
## Angle of an open lid (degrees about X: the front edge swings up and back).
const CHEST_OPEN_ANGLE := 110.0
const MARKER_COLOR := Color(1.0, 0.9, 0.4)
## Meters walked between two footstep sounds.
const STEP_DISTANCE := 1.6

var _rng := RandomNumberGenerator.new()
var _meter: EncounterMeter
var _grass: ShaderMaterial
var _player: Player
var _camera: FollowCamera
var _npc: StaticBody3D
var _merchant: StaticBody3D
var _innkeeper: StaticBody3D
var _boss: StaticBody3D
## chest id -> lid pivot (rotation.x opens it); a chest in _open_chests is open.
var _chest_lids := {}
var _open_chests: Array[String] = []
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
var _prompt: Label
var _dialogue: DialogueBox
var _autoplay := false
var _waiting := false
var _talking := false
## What was in reach last frame ({} for nothing), so autoplay acts once per approach.
var _was_near := {}
## Set by a click or tap on a figure or chest: use it as soon as it is in reach.
var _use_on_arrival := {}
var _marker: MeshInstance3D
var _audio: AudioDirector
var _in_village := false
var _step_m := 0.0


func _ready() -> void:
	_rng.randomize()
	_autoplay = OS.get_cmdline_user_args().has("--autoplay")
	_meter = EncounterMeter.new(_rng)
	_grass = WorldStage.build(self)
	_npc = _add_figure(BattleActor.Look.VILLAGER, WorldStage.NPC_POS, 0.4, 1.8)
	_merchant = _add_figure(BattleActor.Look.MERCHANT, WorldStage.MERCHANT_POS, 0.4, 1.8)
	_innkeeper = _add_figure(BattleActor.Look.INNKEEPER, WorldStage.INNKEEPER_POS, 0.4, 1.8)
	_boss = _add_figure(BattleActor.Look.KING_SLIME, WorldStage.BOSS_POS, 1.0, 2.0)
	for id: String in Chests.CHESTS:
		_chest_lids[id] = build_chest(self, Chests.CHESTS[id])
	set_boss_present(false)
	_player = PLAYER_SCENE.instantiate()
	add_child(_player)
	_camera = FollowCamera.new()
	add_child(_camera)
	_camera.target = _player
	_marker = _build_marker()
	_build_ui()
	respawn()
	_camera.current = true
	if get_parent() == get_tree().root:
		refresh_status(HERO_DATA, Inventory.START_POTIONS, GameState.START_GOLD)
		encounter_triggered.connect(_on_standalone_encounter)
		talk_requested.connect(_on_standalone_talk)
		shop_requested.connect(func(shop_id: String) -> void: print("Tienda: %s" % shop_id))
		inn_requested.connect(func(inn_id: String) -> void: print("Posada: %s" % inn_id))
		chest_opened.connect(func(chest_id: String) -> void:
			print("Cofre: %s" % chest_id)
			set_chest_open(chest_id, true))


func _physics_process(_delta: float) -> void:
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
	if _boss_present and _flat_distance(pos, WorldStage.BOSS_POS) <= BOSS_RADIUS:
		_trigger(true)
		return
	var in_grass := not WorldStage.is_on_path(pos)
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


## Back to the spawn point facing up the path, with the encounter grace restarted.
func respawn() -> void:
	place_player(WorldStage.SPAWN_POS)


## Puts the player at pos facing north (a loaded game), with the encounter grace
## restarted. in_village() is right at once; village_changed is not emitted.
func place_player(pos: Vector3) -> void:
	_player.place(pos, 0.0)
	_camera.snap()
	_meter.reset()
	_was_near = {}
	_use_on_arrival = {}
	_step_m = 0.0
	_in_village = _is_in_village(pos)


func player_position() -> Vector3:
	return _player.global_position


func in_village() -> bool:
	return _in_village


## Footsteps, encounter and dialogue sounds. Without it the map is silent.
func set_audio(audio: AudioDirector) -> void:
	_audio = audio
	_dialogue.set_audio(audio)


## Shows or removes the Rey Slime north of the village; when absent it has no collision.
func set_boss_present(present: bool) -> void:
	_boss_present = present
	_boss.visible = present
	_boss.process_mode = Node.PROCESS_MODE_INHERIT if present else Node.PROCESS_MODE_DISABLED


## Freezes the player and shows the lines one by one; returns when they are all read.
func show_dialogue(speaker: String, lines: Array[String]) -> void:
	freeze(true)
	await _dialogue.say(speaker, lines)
	await freeze(false)


## Freezes the player (no walking, prompts, encounters or uses) while a dialogue or the
## shop is open. Unfreezing waits one frame, so the key that closed the window does not
## open it again; await it.
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


## Opens (lid tipped back, tweened unless instant) or closes a chest. An open chest
## can't be used any more.
func set_chest_open(chest_id: String, open: bool, instant := false) -> void:
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


## Shows a short line under the status for NOTICE_TIME seconds.
func show_notice(text: String) -> void:
	_notice.text = text
	_notice.show()
	await get_tree().create_timer(NOTICE_TIME).timeout
	_notice.hide()


func _trigger(boss: bool) -> void:
	if _audio:
		_audio.play_sfx(SfxLibrary.ENCOUNTER)
	_waiting = true
	_player.input_enabled = false
	_prompt.hide()
	encounter_triggered.emit(boss)


## The nearest thing in reach of pos that can be used: {"kind": TALK / SHOP / CHEST,
## "id": shop or chest id ("" to talk)}, or {} if none.
func _nearest_use(pos: Vector3) -> Dictionary:
	var best := {}
	var best_d := INF
	for use in _uses():
		var d := _flat_distance(pos, use.pos)
		if d <= use.radius and d < best_d:
			best = {"kind": use.kind, "id": use.id}
			best_d = d
	return best


## The thing a click or tap at point means ({} if none): within NPC_TAP_RADIUS of it.
func _tapped_use(point: Vector3) -> Dictionary:
	for use in _uses():
		if _flat_distance(point, use.pos) <= NPC_TAP_RADIUS:
			return {"kind": use.kind, "id": use.id}
	return {}


## Everything usable now: the old woman, the merchant, the innkeeper and the closed
## chests.
func _uses() -> Array[Dictionary]:
	var uses: Array[Dictionary] = [
		{"kind": TALK, "id": "", "pos": WorldStage.NPC_POS, "radius": TALK_RADIUS},
		{"kind": SHOP, "id": Shop.VILLACLARO, "pos": WorldStage.MERCHANT_POS,
			"radius": TALK_RADIUS},
		{"kind": INN, "id": Inn.VILLACLARO, "pos": WorldStage.INNKEEPER_POS,
			"radius": TALK_RADIUS},
	]
	for id: String in Chests.CHESTS:
		if not _open_chests.has(id):
			uses.append({"kind": CHEST, "id": id, "pos": Chests.CHESTS[id].pos,
				"radius": CHEST_RADIUS})
	return uses


func _use(use: Dictionary) -> void:
	match use.get("kind", ""):
		TALK:
			talk_requested.emit()
		SHOP:
			shop_requested.emit(use.id)
		INN:
			inn_requested.emit(use.id)
		CHEST:
			chest_opened.emit(use.id)


func _on_standalone_encounter(boss: bool) -> void:
	print("Encuentro en %s (jefe: %s, en el camino: %s)" % [
		_player.global_position, boss, WorldStage.is_on_path(_player.global_position)])
	set_active(true)


func _on_standalone_talk() -> void:
	var lines: Array[String] = ["Hola, viajero."]
	await show_dialogue(Quest.NPC_NAME, lines)


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


## A village figure: a BattleActor on a cylinder collider, facing south (toward the
## spawn).
func _add_figure(look: BattleActor.Look, pos: Vector3, radius: float, \
		height: float) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	body.rotation.y = PI
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


static func _is_in_village(pos: Vector3) -> bool:
	return _flat_distance(pos, WorldStage.CLEARING_POS) <= WorldStage.CLEARING_RADIUS


static func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))
```

- [ ] **Step 3: Edit `scripts/game/game.gd`**

1. Replace:

```gdscript
## A victory adds the gold and counts every enemy defeated for the quest; fleeing just
## goes back to the map; a defeat heals the hero and sends them back to the spawn point,
## EXP and gold kept. Talking to the old woman heals, moves the quest on and, once the
## slimes are reported, brings out the Rey Slime. Picks the music (map, village,
## battle, boss), autosaves after talking and after every won battle, and opens the
## pause menu. Emits quit_to_title when the player goes back to the title.
```

with:

```gdscript
## A victory adds the gold and counts every enemy defeated for the quest; fleeing just
## goes back to the map; a defeat takes half the gold (GameState.defeat_gold_loss()),
## heals the hero and sends them back to the spawn point, EXP kept. Talking to the old
## woman heals, moves the quest on and, once the slimes are reported, brings out the Rey
## Slime. A chest gives what it holds (Chests.open()) and stays open. The hero's figure
## on the map and in battle shows the weapon and shield worn. Picks the music (map,
## village, battle, boss), autosaves after talking, after every won battle and
## (silently) after opening a chest, and opens the pause menu. Emits quit_to_title when
## the player goes back to the title.
## On autoplay it prints the gold and the equipment each time they change.
```

2. Replace:

```gdscript
var _last_quest_text := ""
```

with:

```gdscript
var _last_quest_text := ""
var _last_gear_text := ""
```

3. Replace:

```gdscript
	_world.talk_requested.connect(_on_talk)
```

with:

```gdscript
	_world.talk_requested.connect(_on_talk)
	_world.chest_opened.connect(_on_chest)
```

4. Replace:

```gdscript
		else:
			load_failed = true
	_update_boss()
```

with:

```gdscript
		else:
			load_failed = true
	for id in state.opened_chests:
		_world.set_chest_open(id, true, true)
	_update_boss()
```

5. Replace:

```gdscript
	battle.set_audio(_audio)
	battle.char_time = _options.char_time()
```

with:

```gdscript
	battle.set_audio(_audio)
	battle.set_equipment(state.loadout.worn(Equipment.WEAPON),
		state.loadout.worn(Equipment.SHIELD))
	battle.gold_lost = state.defeat_gold_loss()
	battle.char_time = _options.char_time()
```

6. Replace:

```gdscript
	elif outcome == BattleEngine.State.LOST:
		state.heal_full()
```

with:

```gdscript
	elif outcome == BattleEngine.State.LOST:
		state.gold -= battle.gold_lost
		state.heal_full()
```

7. Replace:

```gdscript
## Writes the save file; shows SAVED_NOTICE if notice. Returns the saved data, or an
```

with:

```gdscript
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
	if _autoplay:
		print(result.text)
	_refresh_status()
	_world.show_notice(result.text)
	_autosave(false)


## Writes the save file; shows SAVED_NOTICE if notice. Returns the saved data, or an
```

8. Replace:

```gdscript
## Updates the map's status window; on autoplay also prints each new quest line.
func _refresh_status() -> void:
	var quest_text := state.quest.status_text()
	_world.refresh_status(state.hero, state.inventory.count(Inventory.POTION), quest_text)
	if _autoplay and quest_text != _last_quest_text:
		print(quest_text)
	_last_quest_text = quest_text
```

with:

```gdscript
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
```

- [ ] **Step 4: Check, then run the map and a session**

```powershell
foreach ($s in "world/world_stage","world/player","world/world","game/game") { .\tools\godot.cmd --headless --path . --check-only --script "res://scripts/$s.gd" }
.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 900 res://scenes/world/world.tscn -- --autoplay
.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 4000 -- --autoplay
Remove-Item "$env:APPDATA\Godot\app_userdata\rpg-turnos\save_autoplay.json" -ErrorAction SilentlyContinue
```

Expected: the checks print nothing. The map alone prints, in this order and then again each lap, `Cofre: pradera_este`, `Tienda: villaclaro`, `Posada: villaclaro`, `Cofre: pradera_oeste` (each chest only once; encounter lines may appear in between). The session prints `Oro 50 G · Equipo: Palo, Ropa · ATK 12 DEF 7`, then `¡Encuentras 25 monedas de oro!` and `Oro 75 G · ...`, later `¡Encuentras un Escudo de madera! Te lo equipas.` and `Oro N G · Equipo: Palo, Ropa, Escudo de madera · ATK 12 DEF 10`; nothing happens at the merchant or the innkeeper yet. No `ERROR`.

- [ ] **Step 5: Frames of the chests (temporary probe at the project root)**

Create `chest_probe.gd`:

```gdscript
extends Node3D
## One-off look at the chests (Task 3). Not committed: delete it after viewing the
## frames. A closed chest and an open one, as World builds them, seen from the front.


func _ready() -> void:
	BattleStage.build_environment(self)
	var ground := PlaneMesh.new()
	ground.size = Vector2(20, 20)
	BattleStage.add_mesh(self, ground, BattleStage.GRASS, Vector3.ZERO)
	World.build_chest(self, {"pos": Vector3(-0.9, 0, 0), "yaw": 160.0})
	var lid := World.build_chest(self, {"pos": Vector3(0.9, 0, 0), "yaw": 200.0})
	lid.rotation.x = deg_to_rad(World.CHEST_OPEN_ANGLE)
	var camera := Camera3D.new()
	add_child(camera)
	camera.position = Vector3(0, 1.8, 3.2)
	camera.look_at(Vector3(0, 0.3, 0))
	camera.current = true
```

Create `chest_probe.tscn`:

```ini
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://chest_probe.gd" id="1"]

[node name="ChestProbe" type="Node3D"]
script = ExtResource("1")
```

```powershell
$dir = "$env:TEMP\rpg-chest"
New-Item -ItemType Directory -Force $dir | Out-Null
.\tools\godot.cmd --path . res://chest_probe.tscn --resolution 960x540 --write-movie "$dir\c.png" --fixed-fps 10 --quit-after 5
Remove-Item chest_probe.gd, chest_probe.gd.uid, chest_probe.tscn -ErrorAction SilentlyContinue
```

Open `$dir\c00000004.png`. Expected: on the left a closed brown chest with a yellow band, two yellow straps over the lid and the lock in front; on the right the same chest with the lid tipped up and back. Delete `$dir` afterwards.

- [ ] **Step 6: Commit**

```powershell
git add scripts
git status --short
git commit -m "Place the merchant, the innkeeper and the chests on the map and show the gold"
```

`git status --short` must not list `chest_probe`.

---

### Task 4: Shop window, inn and the Equipo page

**Files:**
- Create: `scripts/ui/shop_window.gd`
- Modify: `scripts/game/game.gd`, `scripts/ui/pause_menu.gd`

**Interfaces:**
- Consumes: `Shop`, `Inn`, `Equipment`, `GameState.equip()` / `unequip()` (Task 1), `World.shop_requested` / `inn_requested` / `freeze()` / `show_dialogue()` (Task 3), `BattleHud.make_window()`, `SfxLibrary`, `AudioDirector`.
- Produces:
  - `ShopWindow` (`Control`): `signal changed`; consts `BETTER`, `WORSE`, `AUTOPLAY_STEP = 0.7`…; inner class `Arrow` (`Control`, `_init(p_up: bool, p_color: Color)`); `setup(state: GameState, audio: AudioDirector)`, `run(shop_id: String)` (awaitable), `ask(speaker: String, question: String) -> bool` (awaitable), `static comparison(diff: int) -> HBoxContainer`
  - `Game`: `INN_NIGHT_TIME = 0.8`; `_on_shop(shop_id)`, `_on_inn(inn_id)`, `_build_shop()`
  - `PauseMenu`: page `"equipment"` (Equipo) between Objetos and Guardar; `tour()` shows it

- [ ] **Step 1: Create `scripts/ui/shop_window.gd`**

```gdscript
class_name ShopWindow extends Control
## Shop window of the map. run(shop_id) opens it on "¿Comprar o vender?" and returns
## when the player leaves. Comprar lists what the shop sells with its price and, for
## equipment, the comparison with what is worn (green ▲ better, red ▼ worse, = same);
## buying a piece of equipment asks "¿Te lo equipas ahora?". Vender lists what the hero
## carries at half price (what is worn is listed but can't be sold). Rows that can't be
## used now are grey with the reason. Keyboard (↑ / ↓, Enter / Space, Esc goes back),
## mouse and touch. The rules are Shop's; this window only shows them. Emits changed
## after every purchase, sale or change of equipment. ask() puts a yes / no question in
## the same window (the inn). Call setup() before adding it.
## With `-- --autoplay` run() buys Shop.autoplay_picks() by itself, equips every piece,
## shows the sell page and prints each message; ask() answers Sí by itself.

signal changed
signal _left
signal _answered(yes: bool)

const FONT_SIZE := 24
const TITLE_COLOR := Color(1.0, 0.85, 0.3)
const GREY := Color(0.6, 0.6, 0.65)
const BETTER := Color(0.35, 1.0, 0.4)
const WORSE := Color(1.0, 0.35, 0.3)
const NAME_WIDTH := 300.0
const PRICE_WIDTH := 90.0
const WINDOW_WIDTH := 640.0
## Seconds each step stays on screen on autoplay.
const AUTOPLAY_STEP := 0.7

var _state: GameState
var _audio: AudioDirector
var _shop_id := ""
var _page := ""
var _autoplay := false
## Piece just bought, waiting for the "¿Te lo equipas ahora?" answer.
var _asking := ""
var _quiet_focus := false
var _keeper: Label
var _gold: Label
var _title: Label
var _rows: VBoxContainer
var _message: Label


## A small triangle pointing up (green, better) or down (red, worse), drawn so it never
## depends on the font having ▲ / ▼ (the web build has no system fonts).
class Arrow extends Control:
	var up := true
	var color := Color.WHITE

	func _init(p_up: bool, p_color: Color) -> void:
		up = p_up
		color = p_color
		custom_minimum_size = Vector2(18, 18)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var points := PackedVector2Array([Vector2(w / 2.0, 2), Vector2(w - 1, h - 2),
			Vector2(1, h - 2)]) if up else PackedVector2Array([Vector2(1, 2),
			Vector2(w - 1, 2), Vector2(w / 2.0, h - 2)])
		draw_colored_polygon(points, color)


func setup(state: GameState, audio: AudioDirector) -> void:
	_state = state
	_audio = audio


func _ready() -> void:
	_autoplay = OS.get_cmdline_user_args().has("--autoplay")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var window := BattleHud.make_window()
	window.custom_minimum_size = Vector2(WINDOW_WIDTH, 0)
	center.add_child(window)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	window.add_child(box)
	var header := HBoxContainer.new()
	box.add_child(header)
	_keeper = _label("", TITLE_COLOR)
	_keeper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_keeper)
	_gold = _label("", Color.WHITE)
	header.add_child(_gold)
	_title = _label("", Color.WHITE)
	box.add_child(_title)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 6)
	box.add_child(_rows)
	_message = _label("", Color.WHITE)
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_message)
	hide()


## Opens the shop of shop_id (a Shop.SHOPS key) and returns when the player leaves.
func run(shop_id: String) -> void:
	_shop_id = shop_id
	_keeper.text = Shop.keeper(shop_id)
	_message.text = ""
	show()
	_sfx(SfxLibrary.DIALOGUE)
	_show_page("menu")
	if _autoplay:
		await _autoplay_run()
	else:
		await _left
	hide()
	_page = ""


## Shows speaker and question with Sí / No and returns true for Sí (Esc is No).
func ask(speaker: String, question: String) -> bool:
	_keeper.text = speaker
	_message.text = ""
	show()
	_sfx(SfxLibrary.DIALOGUE)
	_show_page("question")
	_title.text = question
	if _autoplay:
		print("%s: %s" % [speaker, question])
		get_tree().create_timer(AUTOPLAY_STEP).timeout.connect(
			func() -> void: _answered.emit(true))
	var yes: bool = await _answered
	hide()
	_page = ""
	return yes


func _unhandled_input(event: InputEvent) -> void:
	if _page == "" or _autoplay:
		return
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		_back()


## Esc / Volver: the lists and the question go back to the first page, which leaves.
func _back() -> void:
	_sfx(SfxLibrary.CANCEL)
	match _page:
		"menu":
			_page = ""
			_left.emit()
		"ask":
			_answer(false)
		"question":
			_answered.emit(false)
		_:
			_message.text = ""
			_show_page("menu")


func _show_page(page: String) -> void:
	_page = page
	_gold.text = "Oro %d G" % _state.gold
	for child in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	match page:
		"menu":
			_title.text = "¿Comprar o vender?"
			_add_button("Comprar", func() -> void: _open("buy"))
			_add_button("Vender", func() -> void: _open("sell"))
			_add_button("Salir", _back)
		"buy":
			_title.text = "Comprar"
			for id in Shop.stock(_shop_id):
				_add_buy_row(id)
			_add_button("Volver", _back)
		"sell":
			_title.text = "Vender (pago la mitad)"
			var ids := Shop.sell_list(_state)
			for id in ids:
				_add_sell_row(id)
			if ids.is_empty():
				_rows.add_child(_label("No llevas nada que vender.", Color.WHITE))
			_add_button("Volver", _back)
		"ask":
			_title.text = "¿Te %s equipas ahora?" % Equipment.pronoun(_asking)
			_add_button("Sí", func() -> void: _answer(true))
			_add_button("No", func() -> void: _answer(false))
		"question":
			_add_button("Sí", func() -> void:
				_sfx(SfxLibrary.ACCEPT)
				_answered.emit(true))
			_add_button("No", func() -> void:
				_sfx(SfxLibrary.CANCEL)
				_answered.emit(false))
	_focus_first()


func _open(page: String) -> void:
	_sfx(SfxLibrary.ACCEPT)
	_message.text = ""
	_show_page(page)


## Name and price; for equipment also its bonus and the comparison with what is worn.
func _add_buy_row(id: String) -> void:
	var row := _row()
	var why := Shop.buy_problem(_state, id)
	var button := _button(Shop.display_name(id))
	button.custom_minimum_size.x = NAME_WIDTH
	button.disabled = why != ""
	button.pressed.connect(_buy.bind(id))
	row.add_child(button)
	var price := _label("%d G" % Shop.price(id), GREY if why != "" else Color.WHITE)
	price.custom_minimum_size.x = PRICE_WIDTH
	row.add_child(price)
	var info := Shop.compare(_state, id)
	if not info.is_empty():
		row.add_child(_label("%s +%d" % [info.stat, info.bonus], Color.WHITE))
		row.add_child(comparison(info.diff))
	if why != "":
		row.add_child(_label(why, GREY))


## Name with the count carried, the price paid, and why it can't be sold if so.
func _add_sell_row(id: String) -> void:
	var row := _row()
	var why := Shop.sell_problem(_state, id)
	var count := Shop.sell_count(_state, id)
	var text := Shop.display_name(id) if count <= 1 else "%s ×%d" % [Shop.display_name(id), count]
	var button := _button(text)
	button.custom_minimum_size.x = NAME_WIDTH
	button.disabled = why != ""
	button.pressed.connect(_sell.bind(id))
	row.add_child(button)
	var price := _label("%d G" % Shop.sell_price(id), GREY if why != "" else Color.WHITE)
	price.custom_minimum_size.x = PRICE_WIDTH
	row.add_child(price)
	if why != "":
		row.add_child(_label(why, GREY))


## Green ▲ and +n when better, red ▼ and -n when worse, "=" when the same (also used by
## the Equipo page of the pause menu).
static func comparison(diff: int) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	if diff == 0:
		box.add_child(_make_label("=", Color.WHITE))
		return box
	var color := BETTER if diff > 0 else WORSE
	var arrow := Arrow.new(diff > 0, color)
	arrow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(arrow)
	box.add_child(_make_label("%+d" % diff, color))
	return box


func _buy(id: String) -> void:
	var result := Shop.buy(_state, id)
	_say(result.text)
	if not result.ok:
		_sfx(SfxLibrary.CANCEL)
		return
	_sfx(SfxLibrary.ACCEPT)
	changed.emit()
	if Shop.is_equipment(id):
		_asking = id
		_show_page("ask")
	else:
		_show_page("buy")


func _answer(equip: bool) -> void:
	if equip and _state.equip(_asking):
		_sfx(SfxLibrary.ACCEPT)
		_say("Te equipas %s %s." % [Equipment.article(_asking), Equipment.display_name(_asking)])
		changed.emit()
	_asking = ""
	_show_page("buy")


func _sell(id: String) -> void:
	var result := Shop.sell(_state, id)
	_say(result.text)
	if not result.ok:
		_sfx(SfxLibrary.CANCEL)
		return
	_sfx(SfxLibrary.ACCEPT)
	changed.emit()
	_show_page("sell")


## Autoplay: shows the first page, buys and equips each pick on the buy page, and shows
## the sell page (selling nothing) before leaving.
func _autoplay_run() -> void:
	await _wait()
	_show_page("buy")
	await _wait()
	for id in Shop.autoplay_picks(_state, _shop_id):
		_focus_row(Shop.display_name(id))
		await _wait()
		_buy(id)
		if _page == "ask":
			await _wait()
			_answer(true)
		await _wait()
	_show_page("sell")
	await _wait()
	_show_page("menu")
	await _wait()


func _wait() -> void:
	await get_tree().create_timer(AUTOPLAY_STEP).timeout


## Shows text under the list; on autoplay also prints it.
func _say(text: String) -> void:
	_message.text = text
	if _autoplay:
		print(text)


func _row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_rows.add_child(row)
	return row


func _add_button(text: String, action: Callable) -> void:
	var button := _button(text)
	button.pressed.connect(action)
	_rows.add_child(button)


func _focus_first() -> void:
	_quiet_focus = true
	for button in _rows.find_children("*", "Button", true, false):
		if not (button as Button).disabled:
			(button as Button).grab_focus()
			break
	_quiet_focus = false


func _focus_row(text: String) -> void:
	_quiet_focus = true
	for button in _rows.find_children("*", "Button", true, false):
		if (button as Button).text == text:
			(button as Button).grab_focus()
	_quiet_focus = false


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.flat = true
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	button.focus_entered.connect(func() -> void:
		if not _quiet_focus:
			_sfx(SfxLibrary.CURSOR))
	return button


func _label(text: String, color: Color) -> Label:
	return _make_label(text, color)


static func _make_label(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", color)
	return label


func _sfx(id: String) -> void:
	if _audio:
		_audio.play_sfx(id)
```

- [ ] **Step 2: Edit `scripts/game/game.gd`**

1. Replace:

```gdscript
## Slime. A chest gives what it holds (Chests.open()) and stays open. The hero's figure
## on the map and in battle shows the weapon and shield worn. Picks the music (map,
## village, battle, boss), autosaves after talking, after every won battle and
## (silently) after opening a chest, and opens the pause menu. Emits quit_to_title when
## the player goes back to the title.
```

with:

```gdscript
## Slime. The merchant opens the ShopWindow; the innkeeper offers a night (Inn.stay():
## fade to black, full HP and MP, autosave); a chest gives what it holds (Chests.open())
## and stays open. The hero's figure on the map and in battle shows the weapon and
## shield worn. Picks the music (map, village, battle, boss), autosaves after talking,
## after every won battle, after shopping and (silently) after opening a chest, and
## opens the pause menu. Emits quit_to_title when the player goes back to the title.
```

2. Replace:

```gdscript
const MENU_TOUR_DELAY := 1.0
```

with:

```gdscript
const MENU_TOUR_DELAY := 1.0
## Seconds of black while the hero sleeps at the inn.
const INN_NIGHT_TIME := 0.8
```

3. Replace:

```gdscript
var _last_gear_text := ""
```

with:

```gdscript
var _last_gear_text := ""
var _shop: ShopWindow
## Something was bought, sold or equipped since the shop opened.
var _shop_changed := false
```

4. Replace:

```gdscript
	_world.talk_requested.connect(_on_talk)
```

with:

```gdscript
	_world.talk_requested.connect(_on_talk)
	_world.shop_requested.connect(_on_shop)
	_world.inn_requested.connect(_on_inn)
```

5. Replace:

```gdscript
	_refresh_status()
	_build_fade()
```

with:

```gdscript
	_refresh_status()
	_build_shop()
	_build_fade()
```

6. Replace:

```gdscript
## A closed chest: gives what it holds, opens the lid and saves without a notice (the
```

with:

```gdscript
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
## hurt and with the price (the route passes the inn right after the boss spot).
func _on_inn(inn_id: String) -> void:
	var hurt := state.hero.hp < state.hero.max_hp
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
```

7. Replace:

```gdscript
func _build_fade() -> void:
```

with:

```gdscript
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
```

- [ ] **Step 3: Edit `scripts/ui/pause_menu.gd`**

1. Replace:

```gdscript
## Pages: main list (Estado, Objetos, Guardar, Opciones, Volver al título, Cerrar),
## Estado (hero stats, gold, spells), Objetos (items usable outside battle), Opciones
## (OptionsPanel) and a confirmation before going back to the title. Esc goes back one
## page. Keeps running while paused. Call setup() before adding it to the tree.
```

with:

```gdscript
## Pages: main list (Estado, Objetos, Equipo, Guardar, Opciones, Volver al título,
## Cerrar), Estado (hero stats, gold, spells), Objetos (items usable outside battle),
## Equipo (the three slots; choosing one lists the pieces of that slot in the bag, with
## the comparison, and Quitar), Opciones (OptionsPanel) and a confirmation before going
## back to the title. Esc goes back one page. Keeps running while paused. Call setup()
## before adding it to the tree.
```

2. Replace:

```gdscript
## The hero or the inventory changed (an item was used), so the map can refresh.
```

with:

```gdscript
## The hero, the inventory or the equipment changed, so the map can refresh.
```

3. Replace:

```gdscript
var _items_message: Label
```

with:

```gdscript
var _items_message: Label
var _equip_box: VBoxContainer
var _equip_message: Label
## Slot whose pieces the Equipo page lists ("" for the list of the three slots).
var _equip_slot := ""
```

4. Replace:

```gdscript
	_build_items(stack)
	_build_options(stack)
```

with:

```gdscript
	_build_items(stack)
	_build_equipment(stack)
	_build_options(stack)
```

5. Replace:

```gdscript
	for page in ["main", "status", "items", "options"]:
```

with:

```gdscript
	for page in ["main", "status", "items", "equipment", "options"]:
```

6. Replace:

```gdscript
		"options":
			_options_panel.back()
		_:
			_back_to_main()
```

with:

```gdscript
		"options":
			_options_panel.back()
		"equipment":
			if _equip_slot != "":
				_sfx(SfxLibrary.CANCEL)
				_choose_slot("")
			else:
				_back_to_main()
		_:
			_back_to_main()
```

7. Replace:

```gdscript
		"items":
			_items_message.text = ""
			_fill_items()
```

with:

```gdscript
		"items":
			_items_message.text = ""
			_fill_items()
		"equipment":
			_equip_slot = ""
			_equip_message.text = ""
			_fill_equipment()
```

8. Replace:

```gdscript
func _build_menu_button() -> void:
```

with:

```gdscript
## The three slots with what is worn ("Arma: Palo  ATK +2") and the totals; with a slot
## chosen, the pieces of that slot in the bag (bonus and comparison), Quitar and Volver.
func _fill_equipment() -> void:
	for child in _equip_box.get_children():
		_equip_box.remove_child(child)
		child.queue_free()
	var hero := _state.hero
	var loadout := _state.loadout
	if _equip_slot == "":
		for slot in Equipment.SLOTS:
			var worn := loadout.worn(slot)
			var text := "%s: %s" % [Equipment.SLOT_NAMES[slot], "nada" if worn == "" \
				else "%s  %s +%d" % [Equipment.display_name(worn), Equipment.stat_name(worn),
				Equipment.bonus(worn)]]
			var button := _button(text)
			button.pressed.connect(_choose_slot.bind(slot))
			_equip_box.add_child(button)
		_equip_box.add_child(_label("ATK %d   DEF %d" % [hero.total_attack(),
			hero.total_defense()], Color.WHITE))
		_focus_first_in(_equip_box)
		return
	_equip_box.add_child(_label("%s:" % Equipment.SLOT_NAMES[_equip_slot], TITLE_COLOR))
	var listed: Array[String] = []
	for id in _state.bag_equipment:
		if Equipment.slot(id) != _equip_slot or listed.has(id):
			continue
		listed.append(id)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		_equip_box.add_child(row)
		var button := _button(Equipment.display_name(id))
		button.custom_minimum_size = Vector2(260, 0)
		button.pressed.connect(_on_equip.bind(id))
		row.add_child(button)
		row.add_child(_label("%s +%d" % [Equipment.stat_name(id), Equipment.bonus(id)],
			Color.WHITE))
		row.add_child(ShopWindow.comparison(
			Equipment.bonus(id) - Equipment.bonus(loadout.worn(_equip_slot))))
	if listed.is_empty():
		_equip_box.add_child(_label("No llevas otra pieza.", Color.WHITE))
	if loadout.worn(_equip_slot) != "":
		var remove := _button("Quitar")
		remove.pressed.connect(_on_unequip)
		_equip_box.add_child(remove)
	var back := _button("Volver")
	back.pressed.connect(func() -> void:
		_sfx(SfxLibrary.CANCEL)
		_choose_slot(""))
	_equip_box.add_child(back)
	_focus_first_in(_equip_box)


func _choose_slot(slot: String) -> void:
	if slot != "":
		_sfx(SfxLibrary.ACCEPT)
	_equip_slot = slot
	_equip_message.text = ""
	_fill_equipment()


func _on_equip(id: String) -> void:
	if not _state.equip(id):
		return
	_sfx(SfxLibrary.ACCEPT)
	_equip_slot = ""
	_fill_equipment()
	_equip_message.text = "Te equipas %s %s." % [Equipment.article(id),
		Equipment.display_name(id)]
	state_changed.emit()


func _on_unequip() -> void:
	var worn := _state.loadout.worn(_equip_slot)
	_state.unequip(_equip_slot)
	_sfx(SfxLibrary.CANCEL)
	_equip_slot = ""
	_fill_equipment()
	_equip_message.text = "Te quitas %s %s." % [Equipment.article(worn),
		Equipment.display_name(worn)]
	state_changed.emit()


func _focus_first_in(node: Node) -> void:
	_quiet_focus = true
	var first := _first_button(node)
	if first:
		first.grab_focus()
	_quiet_focus = false


func _build_menu_button() -> void:
```

9. Replace:

```gdscript
		["Objetos", func() -> void: _open_page("items")],
```

with:

```gdscript
		["Objetos", func() -> void: _open_page("items")],
		["Equipo", func() -> void: _open_page("equipment")],
```

10. Replace:

```gdscript
func _build_options(stack: VBoxContainer) -> void:
```

with:

```gdscript
func _build_equipment(stack: VBoxContainer) -> void:
	var page := _page_box(stack, "equipment", "Equipo")
	_equip_box = VBoxContainer.new()
	page.add_child(_equip_box)
	_equip_message = _label("", Color.WHITE)
	page.add_child(_equip_message)
	page.add_child(_back_button())


func _build_options(stack: VBoxContainer) -> void:
```

- [ ] **Step 4: Import and check everything**

```powershell
.\tools\godot.cmd --headless --path . --import
foreach ($s in "ui/shop_window","game/game","ui/pause_menu","world/world","game/shop","game/inn") { .\tools\godot.cmd --headless --path . --check-only --script "res://scripts/$s.gd" }
```

Expected: no `ERROR` or `WARNING`.

- [ ] **Step 5: Whole quest on autoplay**

```powershell
.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 60000 -- --autoplay
Remove-Item "$env:APPDATA\Godot\app_userdata\rpg-turnos\save_autoplay.json" -ErrorAction SilentlyContinue
```

Expected (about a minute; battles in between vary): `¡Encuentras 25 monedas de oro!`, then at the merchant `Compras una Espada de cobre por 40 G.`, `Te equipas una Espada de cobre.`, `Compras una Cota de cuero por 30 G.`, `Te equipas una Cota de cuero.`, then `¡Encuentras un Escudo de madera! Te lo equipas.` and `Oro 5 G · Equipo: Espada de cobre, Cota de cuero, Escudo de madera · ATK 16 DEF 13` (the gold may differ by a battle's worth); later visits only buy potions (`Compras una Poción por 8 G.`) when one is missing; `¡Héroe sube al nivel 5!`, `¡El Rey Slime te cierra el paso!`, `Misión cumplida`, then `Posadero: Una noche cuesta 5 G. ¿Quieres descansar?` and `Posadero: ¡Buenos días! PV y PM recuperados.`. A defeat, if one happens, prints `Pierdes N monedas de oro.` with N half the gold. No `ERROR`, at most the Jolt warning.

- [ ] **Step 6: Save round trip**

```powershell
.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 6000 -- --autoplay --autoplay-save
Remove-Item "$env:APPDATA\Godot\app_userdata\rpg-turnos\save_autoplay.json" -ErrorAction SilentlyContinue
```

Expected: the `Guardado:` and `Cargado:` lines are identical and include `"version":3` and the `"loadout"`, `"bag"` and `"chests"` fields with the run's values (the save comes after the first won battle; in the run behind this plan: `"bag":["palo","ropa"]`, `"chests":["pradera_este"]`, `"loadout":{"armor":"cota_cuero","shield":"","weapon":"espada_cobre"}`).

- [ ] **Step 7: Frames of the shop and the Equipo page**

```powershell
$dir = "$env:TEMP\rpg-shop"
New-Item -ItemType Directory -Force $dir | Out-Null
.\tools\godot.cmd --path . --resolution 960x540 --write-movie "$dir\f.png" --fixed-fps 10 --quit-after 260 -- --autoplay
Remove-Item "$env:APPDATA\Godot\app_userdata\rpg-turnos\save_autoplay.json" -ErrorAction SilentlyContinue
$menu = "$env:TEMP\rpg-menu"
New-Item -ItemType Directory -Force $menu | Out-Null
.\tools\godot.cmd --path . --resolution 960x540 --write-movie "$menu\f.png" --fixed-fps 10 --quit-after 110 -- --autoplay --autoplay-menu
Remove-Item "$env:APPDATA\Godot\app_userdata\rpg-turnos\save_autoplay.json" -ErrorAction SilentlyContinue
```

Look through `$dir` around frames 190-235: the shop window ("Mercader", "Oro N G" on the right), first "¿Comprar o vender?", then "Comprar" with Espada de cobre 40 G "ATK +6" and a green triangle "+4", Cota de cuero 30 G "DEF +5" green "+3", Escudo de madera 25 G "DEF +3" green "+3", Poción 8 G, Antídoto 10 G, Volver (rows the gold can't pay are grey with "Falta oro"), then "¿Te lo equipas ahora?", and finally "Vender (pago la mitad)" with the worn pieces grey ("Lo llevas puesto"), Palo and Ropa grey ("No vale nada") and "Poción ×3  4 G". On the map frames the status window shows "Oro N G" and the knight holds the sword. In `$menu` around frame 78 the Equipo page shows "Arma: Palo  ATK +2", "Armadura: Ropa  DEF +2", "Escudo: nada", "ATK 12   DEF 7" and Volver. Delete both folders afterwards.

- [ ] **Step 8: Keyboard, mouse and touch by hand**

Run `.\tools\godot.cmd --path .`, start a new game and check: walking to the merchant shows "Enter o toca: comprar"; Enter opens the shop; ↑ / ↓ move, Enter buys, Esc goes back and leaves; a click on a row buys; after buying the sword "Sí" equips it and the knight holds it on the map; selling the Palo is refused, selling a potion pays 4 G; clicking the innkeeper walks there and asks for 5 G; Sí fades to black and heals; the pause menu's Equipo page swaps the sword and the Palo both ways and "Quitar" empties a slot (the model follows); walking to a chest shows "Enter o toca: abrir" and Enter opens it once. With the browser's touch emulation (or a phone, after Task 5's export) the same works by tapping.

- [ ] **Step 9: Commit**

```powershell
git add scripts
git status --short
git commit -m "Add the shop window, the inn and the Equipo page of the pause menu"
```

---

### Task 5: Documentation, final checks and web export

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Update `CLAUDE.md`**

Apply these replacements in order (the later ones match text the earlier ones add):

1. Replace:

```markdown
instantiates a `BattleScene` with `setup(state.hero, enemies, state.inventory)` on top (`enemies` from `EncounterTable.pick(ZONE, player position, rng)`, or `[rey_slime.tres]`), awaits `finished(outcome)` (`BattleEngine.State`), frees it and turns the map back on (victory: `state.gold += engine.gold_won` and `quest.on_victory(id)` for every enemy, a beaten boss leaves the map with "¡Villaclaro está a salvo!"; fled: nothing; defeat: `heal_full()` and `World.respawn()`).
```

with:

```markdown
instantiates a `BattleScene` with `setup(state.hero, enemies, state.inventory)`, `set_equipment(weapon, shield)` and `gold_lost = state.defeat_gold_loss()` on top (`enemies` from `EncounterTable.pick(ZONE, player position, rng)`, or `[rey_slime.tres]`), awaits `finished(outcome)` (`BattleEngine.State`), frees it and turns the map back on (victory: `state.gold += engine.gold_won` and `quest.on_victory(id)` for every enemy, a beaten boss leaves the map with "¡Villaclaro está a salvo!"; fled: nothing; defeat: loses half the gold, `heal_full()` and `World.respawn()`). On `World.shop_requested(shop_id)` it freezes the map and awaits `ShopWindow.run(shop_id)` (on autoplay only when `Shop.autoplay_picks()` is not empty), then autosaves if anything changed; on `World.chest_opened(id)` it calls `Chests.open(state, id)`, opens the lid (`World.set_chest_open()`), shows what was found and saves without a notice. `_refresh_status()` also shows the weapon and shield on the map hero (`World.set_hero_equipment()`) and, on autoplay, prints `Oro N G · Equipo: ... · ATK n DEF n` whenever it changes.
```

2. Replace:

```markdown
`quest: Quest`, `gold` (won in battle, saved; shops come in phase 4), `heal_full()` (HP and MP), `use_item(id)` (outside battle, `Inventory.use()`). The hero gets its own `skills` array, so learning a spell never touches `hero.tres`.
```

with:

```markdown
`quest: Quest`, `gold` (`START_GOLD` 50), `loadout: Loadout`, `bag_equipment` (Equipment ids carried but not worn), `opened_chests` (Chests ids), `heal_full()` (HP and MP), `use_item(id)` (outside battle, `Inventory.use()`), `refresh_equipment()` (copies the loadout bonuses into `hero.equip_attack` / `equip_defense`), `equip(id)` (from the bag; what it replaces goes to the bag), `unequip(slot)`, `defeat_gold_loss()` (half the gold, rounded down). The hero gets its own `skills` array, so learning a spell never touches `hero.tres`.
- `scripts/game/equipment.gd` (`Equipment`, `RefCounted`) — the `EQUIPMENT` catalog (id → name, article, slot `WEAPON` / `ARMOR` / `SHIELD`, bonus (ATK for weapons, DEF for the rest), price, zone, mesh): Palo +2 and Ropa +2 (zone 0, the starting gear, worth nothing), zone 1 Espada de cobre +6 · 40 G, Cota de cuero +5 · 30 G, Escudo de madera +3 · 25 G, and zones 2-4 already listed for their shops; `display_name()`, `article()`, `pronoun()`, `slot()`, `bonus()`, `price()`, `mesh()` (a `Knight.glb` handslot mesh, `STICK_MESH` or ""), `stat_name()`, `of_zone()`, `SLOTS`, `SLOT_NAMES`.
- `scripts/game/loadout.gd` (`Loadout`, `RefCounted`) — what the hero wears, slot → id (Palo, Ropa, no shield at first): `worn(slot)`, `is_worn(id)`, `equip(id)` (returns what it took off), `unequip(slot)`, `attack_bonus()`, `defense_bonus()`, `to_dict()`, `set_slots()`.
- `scripts/game/shop.gd` (`Shop`, `RefCounted`) — pure shop rules: `SHOPS` (Villaclaro: the zone 1 gear, Poción and Antídoto; no Éter until zone 2), `stock()`, `price()`, `sell_price()` (half, rounded down), `buy_problem()` / `can_buy()` / `buy()`, `sell_list()` / `sell_count()` / `sell_problem()` ("Lo llevas puesto", "No vale nada") / `sell()` (each returns `{ok, text}`), `compare(state, id)` (`{stat, worn, bonus, diff}` against the piece worn in that slot), `autoplay_picks()` (upgrades first, then potions up to 3).
- `scripts/game/chests.gd` (`Chests`, `RefCounted`) — the 4 chests of the meadow (`CHESTS`: position, yaw and 25 G, Escudo de madera, 40 G or an Éter; the first two lie next to `Player.AUTOPLAY_ROUTE`); `open(state, id)` → `{opened, text}` (equipment goes on at once if its slot is empty, else into the bag).
```

3. Replace:

```markdown
`ANTIDOTE` (cures poison, 10 G, battle only).
```

with:

```markdown
`ANTIDOTE` (cures poison, 10 G, battle only); `Shop` sells at `price` and buys back at half.
```

4. Replace:

```markdown
(`version` 2, hero level / EXP / HP / MP / base stats, inventory, quest stage and kills, gold, position `[x, z]`, play time; version 1 saves are refused)
```

with:

```markdown
(`version` 3, hero level / EXP / HP / MP / base stats, inventory, quest stage and kills, gold, `loadout` (slot → id), `bag`, opened `chests`, position `[x, z]`, play time; version 2 saves still load with the starting gear, an empty bag and closed chests; version 1 saves are refused)
```

5. Replace:

```markdown
- `scenes/world/world.tscn` + `scripts/world/world.gd` (`World`) — world map: `WorldStage`, the old woman and the Rey Slime (`BattleActor`s on cylinder colliders), `Player`, `FollowCamera`, status window (name and level, PV, PM, EXP / next level, potions, quest line), click or tap on the ground (held and dragged too) walks there with a ring marker, "Enter o toca: hablar" prompt within 2.5 m of the old woman (a click or tap on her walks there and talks on arrival), `DialogueBox`, encounters through `EncounterMeter` (only off the path). Emits `talk_requested`, `village_changed(inside)`
```

with:

```markdown
- `scenes/world/world.tscn` + `scripts/world/world.gd` (`World`) — world map: `WorldStage`, the old woman, the merchant (`MERCHANT`) and the Rey Slime (`BattleActor`s on cylinder colliders), the 4 chests (`build_chest()`: wooden box, gold band and lock, lid on a hinge; `set_chest_open(id, open, instant)`), `Player`, `FollowCamera`, status window (name and level, PV, PM, EXP / next level, potions, "Oro N G", quest line), click or tap on the ground (held and dragged too) walks there with a ring marker, a prompt for the nearest thing in reach ("Enter o toca: hablar" within 2.5 m of the old woman, "... comprar" of the merchant, "... abrir" within 1.8 m of a closed chest; a click or tap on one walks there and uses it on arrival), `DialogueBox`, encounters through `EncounterMeter` (only off the path). Emits `talk_requested`, `shop_requested(shop_id)`, `chest_opened(chest_id)`, `village_changed(inside)`
```

6. Replace:

```markdown
`refresh_status(hero, potions, quest_text)`, `show_notice(text)`, `await show_dialogue(speaker, lines)`. On autoplay it asks to talk each time the player comes near the old woman. Run on its own it prints each encounter and answers talks with one line.
```

with:

```markdown
`refresh_status(hero, potions, gold, quest_text)`, `set_hero_equipment(weapon, shield)`, `show_notice(text)`, `await show_dialogue(speaker, lines)`, `await freeze(on)` (no walking or prompts while a window is open). On autoplay it uses whatever comes in reach (talk, shop, chest) once per approach. Run on its own it prints each encounter, shop and chest and answers talks with one line.
```

7. Replace:

```markdown
`NPC_POS`, `BOSS_POS`),
```

with:

```markdown
`NPC_POS`, `MERCHANT_POS`, `BOSS_POS`),
```

8. Replace:

```markdown
kept off the path, `Player.AUTOPLAY_ROUTE` and rocks, cylinder colliders inside the walls) and bushes with seed 31 (no collider),
```

with:

```markdown
kept off the path, `Player.AUTOPLAY_ROUTE`, rocks and chests, cylinder colliders inside the walls) and bushes with seed 31 (no collider; grass and bushes keep off the chests too),
```

9. Replace:

```markdown
model is a `BattleActor` (`HERO`); `last_step_m` feeds the encounter meter; `place(pos, yaw)`. `--autoplay` walks `AUTOPLAY_ROUTE` in a loop, through the village past the old woman and the boss spot.
```

with:

```markdown
model is a `BattleActor` (`HERO`; `set_equipment(weapon, shield)`); `last_step_m` feeds the encounter meter; `place(pos, yaw)`. `--autoplay` walks `AUTOPLAY_ROUTE` in a loop, through the village past the old woman, the merchant and the boss spot, and past two chests.
```

10. Replace:

```markdown
call `setup(hero, enemies: Array[Combatant], inventory)`, `set_audio(audio)` and set `char_time` before adding it
```

with:

```markdown
call `setup(hero, enemies: Array[Combatant], inventory)`, `set_audio(audio)`, `set_equipment(weapon, shield)` and set `char_time` and `gold_lost` (said as "Pierdes N monedas de oro." on a defeat) before adding it
```

11. Replace:

```markdown
hero-only `equip_attack` / `equip_defense` (Palo +2, Ropa +2 until phase 4; `total_attack()` / `total_defense()`)
```

with:

```markdown
hero-only `equip_attack` / `equip_defense` (the loadout bonuses, set by `GameState.refresh_equipment()`; `total_attack()` / `total_defense()`)
```

12. Replace:

```markdown
(`look`: `HERO` / `SLIME` / `VILLAGER` / `KING_SLIME` / `BAT` / `MUSHROOM`, set before `add_child`), faces -Z. `HERO` is KayKit `Knight.glb`, `VILLAGER` is `Mage.glb`
```

with:

```markdown
(`look`: `HERO` / `SLIME` / `VILLAGER` / `KING_SLIME` / `BAT` / `MUSHROOM` / `MERCHANT`, set before `add_child`), faces -Z. `HERO` is KayKit `Knight.glb` (every hand mesh hidden; `set_equipment(weapon, shield)` shows the `Equipment.mesh()` of each under `handslot_r` / `handslot_l`, plus a wooden stick built in code for the Palo), `VILLAGER` is `Mage.glb`, `MERCHANT` the same Mage tinted green (`tint`)
```

13. Replace:

```markdown
victory overlay (EXP, new level, gold, items left) or defeat overlay, with "Continuar"
```

with:

```markdown
victory overlay (EXP, new level, gold, items left) or defeat overlay (`show_defeat(gold_lost)`), with "Continuar"
```

14. Replace:

```markdown
Pages: main (Estado, Objetos, Guardar, Opciones, Volver al título, Cerrar), Estado (stats, gold, spells), Objetos ("Usar" on every item; greyed with the reason when it can't be used outside battle now), Opciones
```

with:

```markdown
Pages: main (Estado, Objetos, Equipo, Guardar, Opciones, Volver al título, Cerrar), Estado (stats, gold, spells), Objetos ("Usar" on every item; greyed with the reason when it can't be used outside battle now), Equipo (the three slots with what is worn and ATK / DEF; a slot lists the pieces of that slot in the bag with the comparison, Quitar and Volver), Opciones
```

15. Replace:

```markdown
- `scripts/ui/options_panel.gd`
```

with:

```markdown
- `scripts/ui/shop_window.gd` (`ShopWindow`, `Control`) — the shop: `setup(state, audio)`, `await run(shop_id)`; "¿Comprar o vender?" (Comprar / Vender / Salir), the buy list (price, bonus and the comparison with what is worn: a drawn green ▲ / red ▼ triangle (`Arrow`, no font glyph) and +n / −n, or "="; rows that can't be bought are grey with "Falta oro"), "¿Te lo equipas ahora?" after buying equipment, the sell list (half price; worn pieces listed grey). Keyboard (↑ / ↓, Enter / Space, Esc back), mouse and touch. Emits `changed`. `static comparison(diff)` is shared with the Equipo page. On autoplay it buys `Shop.autoplay_picks()`, equips them, shows the sell page and prints each message.
- `scripts/ui/options_panel.gd`
```

16. Replace:

```markdown
- Whole quest on autoplay, headless (about a minute; the Rey Slime comes out at Lv 5; ends with `Misión cumplida`)
```

with:

```markdown
- Whole quest on autoplay, headless (about a minute; opens the chest of 25 G, buys the Espada de cobre and the Cota de cuero, finds the Escudo de madera; the Rey Slime comes out at Lv 5; ends with `Misión cumplida`)
```

17. Replace:

```markdown
then the main page, Estado, Objetos and Opciones appear every TOUR_STEP 1.5 s).
```

with:

```markdown
then the main page, Estado, Objetos, Equipo and Opciones appear every TOUR_STEP 1.5 s).
```

18. Replace:

```markdown
- Run only the world map (prints encounters instead of fighting)
```

with:

```markdown
- Run only the world map (prints encounters, shops and chests instead of playing them)
```

Then:

1. Replace:

```markdown
then autosaves if anything changed; on `World.chest_opened(id)`
```

with:

```markdown
then autosaves if anything changed; on `World.inn_requested(inn_id)` it asks `ShopWindow.ask()` and on Sí calls `Inn.stay()` (fade to black, `INN_NIGHT_TIME` 0.8 s, full HP and MP, autosave; on autoplay only when hurt and with the price); on `World.chest_opened(id)`
```

2. Replace:

```markdown
- `scripts/game/chests.gd` (`Chests`, `RefCounted`)
```

with:

```markdown
- `scripts/game/inn.gd` (`Inn`, `RefCounted`) — inn rules: `INNS` (Villaclaro: Posadero, 5 G; the model for the later zones' 15 / 30 / 50 G inns, since the old woman already heals for free here), `keeper()`, `price()`, `offer()`, `stay(state, id)` → `{ok, text}` (pays and heals).
- `scripts/game/chests.gd` (`Chests`, `RefCounted`)
```

3. Replace:

```markdown
the old woman, the merchant (`MERCHANT`) and the Rey Slime
```

with:

```markdown
the old woman, the merchant (`MERCHANT`), the innkeeper (`INNKEEPER`) and the Rey Slime
```

4. Replace:

```markdown
"... comprar" of the merchant,
```

with:

```markdown
"... comprar" of the merchant, "... hablar" of the innkeeper,
```

5. Replace:

```markdown
Emits `talk_requested`, `shop_requested(shop_id)`, `chest_opened(chest_id)`,
```

with:

```markdown
Emits `talk_requested`, `shop_requested(shop_id)`, `inn_requested(inn_id)`, `chest_opened(chest_id)`,
```

6. Replace:

```markdown
it prints each encounter, shop and chest and answers talks with one line.
```

with:

```markdown
it prints each encounter, shop, inn and chest and answers talks with one line.
```

7. Replace:

```markdown
`NPC_POS`, `MERCHANT_POS`, `BOSS_POS`),
```

with:

```markdown
`NPC_POS`, `MERCHANT_POS`, `INNKEEPER_POS`, `BOSS_POS`),
```

8. Replace:

```markdown
through the village past the old woman, the merchant and the boss spot, and past two chests.
```

with:

```markdown
through the village past the old woman, the merchant, the boss spot and the innkeeper, and past two chests.
```

9. Replace:

```markdown
/ `MUSHROOM` / `MERCHANT`, set before
```

with:

```markdown
/ `MUSHROOM` / `MERCHANT` / `INNKEEPER`, set before
```

10. Replace:

```markdown
`MERCHANT` the same Mage tinted green (`tint`)
```

with:

```markdown
`MERCHANT` / `INNKEEPER` the same Mage tinted green / orange (`tint`)
```

11. Replace:

```markdown
Emits `changed`. `static comparison(diff)` is shared with the Equipo page.
```

with:

```markdown
Emits `changed`. `await ask(speaker, question)` puts a Sí / No question in the same window (the inn; Esc is No). `static comparison(diff)` is shared with the Equipo page.
```

12. Replace:

```markdown
finds the Escudo de madera; the Rey Slime comes out at Lv 5; ends with `Misión cumplida`)
```

with:

```markdown
finds the Escudo de madera; the Rey Slime comes out at Lv 5; `Misión cumplida`, then a night at the inn)
```

13. Replace:

```markdown
- Run only the world map (prints encounters, shops and chests instead of playing them)
```

with:

```markdown
- Run only the world map (prints encounters, shops, inns and chests instead of playing them)
```

- [ ] **Step 2: Check every changed script once more and run the quest**

```powershell
.\tools\godot.cmd --headless --path . --import
foreach ($s in "game/equipment","game/loadout","game/shop","game/inn","game/chests","game/game_state","game/save_data","game/game","game/inventory","ui/shop_window","ui/pause_menu","ui/battle_result","battle/battle_scene","battle/battle_actor","battle/combatant","world/world","world/world_stage","world/player") { .\tools\godot.cmd --headless --path . --check-only --script "res://scripts/$s.gd" }
.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 60000 -- --autoplay
Remove-Item "$env:APPDATA\Godot\app_userdata\rpg-turnos\save_autoplay.json" -ErrorAction SilentlyContinue
```

Expected: the checks print nothing; the quest ends as in Task 4 Step 5.

- [ ] **Step 3: Web export**

```powershell
.\tools\godot.cmd --headless --path . --export-release "Web" build/web/index.html
```

Expected: no `ERROR`; `build/web` holds `index.html`, `index.js`, `index.pck`, `index.wasm` and the rest. Serve it (`python -m http.server -d build/web 8000`) and check in the browser that the shop's green / red triangles are drawn (not boxes) and that the shop works with the mouse.

- [ ] **Step 4: Windowed run (for the user)**

`.\tools\godot.cmd --path .`: play a new game, buy the sword, open a chest, sleep at the inn, swap gear in Equipo, save, go back to the title and Continuar: gold, gear and opened chests are kept.

- [ ] **Step 5: Commit**

```powershell
git add CLAUDE.md
git commit -m "Document the economy and equipment phase"
```

---

## Self-review against the spec

| Spec item | Where |
|---|---|
| Oro inicial 50 G | `GameState.START_GOLD` (Task 1) |
| Perder la mitad al perder, dicho en la derrota | `GameState.defeat_gold_loss()`, `BattleScene.gold_lost`, `BattleResult.show_defeat()` (Tasks 1-3) |
| Ranuras arma / armadura / escudo; Palo +2, Ropa +2, sin escudo; sustituyen las bonificaciones fijas | `Equipment`, `Loadout`, `hero.tres` without `equip_*` (Task 1) |
| Tabla `EQUIPMENT` con id, nombre, ranura, bonificación, precio y zona; zonas 2-4 ya apuntadas | `Equipment.EQUIPMENT` (Task 1) |
| Mercader junto a la casa de la izquierda, `VILLAGER` en otro color | `MERCHANT_POS`, `Look.MERCHANT` tint (Tasks 2-3) |
| "¿Comprar o vender?", comparación ▲ verde / ▼ roja / =, "¿Te lo equipas ahora?", vender a mitad, no vender lo puesto | `ShopWindow`, `Shop` (Tasks 1, 4) |
| Poción 8 G, Antídoto 10 G, Éter 30 G solo desde la zona 2 | `Shop.SHOPS`, `Inventory.ITEMS` (Task 1) |
| Posada: posadero, 5 G, fundido, curación, autoguardado; la anciana sigue curando gratis | `Inn`, `Game._on_inn()`, `Look.INNKEEPER` (Tasks 1-4) |
| 4 cofres (25 G, 40 G, Éter, Escudo de madera), Enter o toque, recordados y guardados | `Chests`, `World` uses, `opened_chests`, save v3 (Tasks 1, 3) |
| Equipo visible: handslot meshes, sin escudo mano vacía, armadura no cambia el modelo | `BattleActor.set_equipment()` (Task 2) |
| Opción Equipo en el menú de pausa | `PauseMenu` Equipo page (Task 4) |
| `attack` / `defense` = base + equipo, fórmulas iguales | `Combatant.total_attack()` / `total_defense()` fed by `GameState.refresh_equipment()` (Task 1) |
| "Oro 123 G" en el mapa y en el menú de pausa | `World` status window (Task 3); Estado page (phase 3) |
| Equilibrio repetido con el equipo real | Task 1 Step 11; Rey Slime 128 PV |
| Arquitectura: `Equipment`, `Loadout`, `Shop` puros; `GameState` + `SaveData`; `World` con señales `shop_requested` / `chest_opened` y cofres hechos en código; `ShopWindow` en `scripts/ui/`; `BattleActor.set_equipment()` | Tasks 1-4 (plus `Inn`, `Chests` and `inn_requested`, which the spec's inn and chests need) |
| Verificación: autoplay compra y abre los cofres de su ruta e imprime oro y equipo; fotogramas de tienda, cofres y héroe; simulador; guardar y cargar; web | Task 4 Steps 5-7, Task 2 Step 3, Task 3 Step 5, Task 1 Step 11, Task 4 Step 6, Task 5 Step 3 |
| Fuera de alcance: tiendas de otras zonas, rareza, regateo | Not done (only the catalog rows and the inn model) |
