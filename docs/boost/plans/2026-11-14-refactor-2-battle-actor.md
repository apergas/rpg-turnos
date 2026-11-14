# Refactor 2: BattleActor split (M-72) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Split `scripts/battle/battle_actor.gd` (2.473 lines) into `ActorLooks` (data), `CreatureBuilder` and `CharacterBuilder` (static builders) and move its mesh primitives into `LowPoly`, without changing anything the player sees.

**Architecture:** `BattleActor` stays the live figure: `_ready()`, the animations (`play_*`, `_start_*`, `_hop`, `_start`, `_end`), the floating numbers, the equipment (`set_equipment`, `_build_horns`), the flash, the highlight and the see-through. The `LOOKS` table and everything it names move to `ActorLooks`. The `_build_*` functions move to two static builders, which write into the figure only through small public builder methods of `BattleActor` (`body()`, `add_mesh()`, `add_wing()`, `set_sway()`...), never its private members. Code is moved, not rewritten: functions are cut with a helper script and their accesses renamed with `sed`.

**Tech Stack:** Godot 4.7.2, GDScript, Git Bash (`awk`, `sed`, `grep`, `cmp`).

## Global Constraints

- Spec: `docs/boost/specs/2026-11-14-refactor-arquitectura-design.md` (M-72). Guide: `docs/boost/specs/2026-11-14-refactor-arquitectura-guia.md`. Brief rules apply.
- **Behaviour must not change:** no rules, texts, balance, look, save format (version 14) or autoplay output.
- **NO TESTS OF ANY KIND** (`CLAUDE.md` overrides every TDD step). Checks are by hand: `--import`, `--check-only`, autoplay runs compared with the reference, screenshots.
- **`BattleActor.Look` keeps working** through `const Look = ActorLooks.Look` in `BattleActor` (64 uses in six scripts are not touched). Verified in Godot 4.7.2: the alias works as a type hint too (`var x: BattleActor.Look`, parameters, return types), so no type hint is changed.
- **Builders keep no state and never touch `BattleActor` privates;** they call its builder methods. The builders are `class_name X extends RefCounted` with only `static` functions and a header that starts with `## Constructor:` (the M-73 convention of plan 1).
- **Every Godot run sets APPDATA inline to the literal scratch path** `C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor`. Never use `$APPDATA` in `rm`, `mv` or `cp`. Reference logs live in `C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/`.
- **One task = one commit**, game working after each. Commit messages in English, no `Co-Authored-By`, no attribution of any kind. Never push.
- Branch `feature/refactor-2-battle-actor` from `develop` (with plan 1 merged), merged back with `git merge --no-ff`.
- `CLAUDE.md` *Layout* is updated in the same commit as the code.
- Every new `.gd` gets a `.gd.uid` from `--import`; the project commits `.uid` files, so each new one is added with its script.
- Do not edit `scripts/tools/*` (`trim_animations.gd` is an import script: touching it would reimport the models). Their comments that name "BattleActor's CHARACTER_ANIMS" / "BattleActor's hair pieces" stay as they are.
- Target (orientative): `battle_actor.gd` under 900 lines (the dry run of this plan ends at about 740).

## Hand checks (used by every task)

All commands run from Git Bash in `/c/Users/peixe/Documents/rpg-turnos`. Run them in this order after each task's code step; a task lists which ones it needs.

**H0 — import.**

```bash
mkdir -p C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --import > C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/import.log 2>&1
grep -E 'ERROR|Parse Error' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/import.log; echo "grep done"
```

Expected: only `grep done`.

**H1 — check-only, for each script the task names** (replace `<script>`):

```bash
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --check-only --script res://<script> 2>&1 | grep -E 'ERROR|Parse Error|WARNING'; echo "check done"
```

Expected: only `check done`.

**H2 — movie of the caravan start** (windowed, 900 frames, compared by eye with plan 1's `ref/movie-caravana/`; it shows the hero with the platinum gear and helmet, the Jefe de caravana and the other people the builders make):

```bash
rm -rf C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/movie-caravana
mkdir -p C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/movie-caravana
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --path . --write-movie C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/movie-caravana/f.png --fixed-fps 10 --quit-after 900 -- --autoplay --autoplay-zone=caravana > C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/movie-caravana.log 2>&1
find C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/movie-caravana -name 'f*.png' ! -name 'f00000[0-8][05]0.png' -delete
grep -E 'ERROR|WARNING' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/movie-caravana.log | grep -v 'Jolt Physics job system exceeded'; echo "grep done"
```

Expected: only `grep done`. Open with the Read tool the frames of `plan2/movie-caravana/` next to the same names in `ref/movie-caravana/` (frames 0, 50, ... 850; the randomness of the run may move the scene, the figures must not look different): the hero with his gear and helmet, the Jefe de caravana and any other caravan person on screen. The Yelmo de bruma's horns are built by `BattleActor._build_horns()`, which this plan does not move; they are covered by H1 on `battle_actor.gd` and by the Eco run of Task 5. Then free the space: `rm -rf C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/movie-caravana`.

**H3 — movie of the start of the v1** (600 frames, windowed):

```bash
rm -rf C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/movie
mkdir -p C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/movie
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --path . --write-movie C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/movie/f.png --fixed-fps 10 --quit-after 600 -- --autoplay > C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/movie.log 2>&1
M='^(Zona|Escena|Lugar|Compañero|Pregunta|Misión cumplida|Juego completado|Medallas|Eco de la Niebla)'
grep -E "$M" C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/movie.log > C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/ref-milestones.txt
grep -E "$M" C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/movie.log > C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/new-milestones.txt
diff C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/ref-milestones.txt C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/new-milestones.txt && echo SAME
grep -E 'ERROR|WARNING' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/movie.log; echo "grep done"
```

Expected: `SAME`, then `grep done`, with at most the known line `WARNING: Jolt Physics job system exceeded the maximum number of jobs` before it. Then open with the Read tool `plan2/movie/f00000150.png`, `f00000300.png`, `f00000450.png` and `f00000550.png` next to the same names in `ref/movie/`: the hero (with its stick or the bought gear), the villagers and the notice board, the slimes and groups on the map look the same (the autoplay is random, so the scene may differ; the figures must not). Then free the space:

```bash
rm -rf C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/movie
```

**H4 — bestiary portraits** (all 47 enemy figures):

```bash
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --path . --script res://scripts/tools/bestiary_shots.gd > C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/bestiary.log 2>&1
grep -E 'ERROR|WARNING' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/bestiary.log; echo "grep done"
git status --short assets/bestiary; echo "status done"
```

Expected: `grep done`, then only `status done`. If PNGs show as modified: when it is listed in plan 1's `ref/bestiary-unstable.txt`, it is the known noise (compare it by eye); else it is a regression: open the PNG, find the look's builder and fix the renamed access. Either way restore them before committing: `git checkout -- assets/bestiary`.

---

### Task 1: Helper and the primitives in `LowPoly`

**Files:**
- Create (scratch, outside the repo): `C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/tools/move_members.awk`
- Modify: `scripts/battle/low_poly.gd` (six new public static functions), `scripts/battle/battle_actor.gd` (the six private ones removed, 127 calls renamed), `CLAUDE.md`

**Interfaces:**
- Consumes: plan 1's references `ref/movie/`, `ref/movie.log`, `ref/movie-caravana/`, `ref/bestiary-unstable.txt`, `ref/eco.log`, `ref/v1.log` and `ref/v2.log`.
- Produces (used by Tasks 3-5):
  - `static func LowPoly.sphere(radius: float) -> SphereMesh`
  - `static func LowPoly.cylinder(radius: float, height: float) -> CylinderMesh`
  - `static func LowPoly.cone(radius: float, height: float) -> CylinderMesh`
  - `static func LowPoly.hemisphere(radius: float, height: float) -> SphereMesh`
  - `static func LowPoly.disc(radius: float) -> CylinderMesh`
  - `static func LowPoly.merged(mesh: Mesh, xforms: Array[Transform3D]) -> ArrayMesh`
  - the helper `move_members.awk`.

- [ ] **Step 1: Branch from develop**

```bash
cd /c/Users/peixe/Documents/rpg-turnos
git checkout develop
git status --short; echo "status done"
test -f scripts/game/run_flags.gd && echo "plan 1 merged"
ls C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/
git checkout -b feature/refactor-2-battle-actor
```

Expected: `status done` alone (clean tree), `plan 1 merged`, the listing shows plan 1's reference (at least `v1.log`, `v2.log`, `eco.log`, `movie/`, `movie-caravana/`), then `Switched to a new branch 'feature/refactor-2-battle-actor'`. If `plan 1 merged` is missing, stop: plan 1 must be merged first.

- [ ] **Step 2: Write the scratch helper**

`C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/tools/move_members.awk` (cuts named top-level members, each with the `##` lines right above it, out of a GDScript file; it was dry-run on the real `battle_actor.gd` while writing this plan):

```awk
# Moves named top-level members (func, static func, const, enum, var) of a GDScript file,
# each with the "##" doc lines right above it, out of the file.
# usage: awk -v names="A B C" -v moved=OUT.gd -f move_members.awk SRC.gd > SRC.new
# The members are appended to OUT.gd in source order; the rest of SRC goes to stdout, with
# no trailing blank lines. A name that is not found is reported as "NOT FOUND: name".
BEGIN { n = split(names, a, " "); for (i = 1; i <= n; i++) want[a[i]] = 1 }
{ line[NR] = $0 }
END {
	for (i = 1; i <= NR; i++) {
		if (line[i] !~ /^(static )?(func|const|enum|var) /) continue
		kind = line[i]; sub(/^static /, "", kind); sub(/ .*/, "", kind)
		name = line[i]; sub(/^(static )?(func|const|enum|var) /, "", name)
		sub(/[^A-Za-z0-9_].*/, "", name)
		if (!(name in want)) continue
		s = i; while (s > 1 && line[s - 1] ~ /^##/) s--
		e = i + 1
		while (e <= NR) {
			if (line[e] ~ /^\t/ || (kind == "func" && line[e] == "")) { e++; continue }
			if (kind != "func" && line[e] ~ /^[}\]]/) { e++ }
			break
		}
		b = e - 1; while (b > i && line[b] == "") b--
		for (k = s; k <= b; k++) { print line[k] >> moved; drop[k] = 1 }
		if (kind == "func") {
			print "" >> moved; print "" >> moved
			for (k = b + 1; k < e; k++) drop[k] = 1
		}
		found[name] = 1
	}
	last = NR
	while (last > 0 && ((last in drop) || line[last] == "")) last--
	for (i = 1; i <= last; i++) if (!(i in drop)) print line[i]
	for (nm in want) if (!(nm in found)) print "NOT FOUND: " nm > "/dev/stderr"
}
```

- [ ] **Step 3: Add the primitives to `LowPoly`**

With the Edit tool in `scripts/battle/low_poly.gd`, insert this block right above the line `## Skips triangles that collapse at the profile's tips (radius 0).` (public functions go before the private `_triangle`):

```gdscript
## A hemisphere (flat side down) of radius and height, 9 sides and 3 rings.
static func hemisphere(radius: float, height: float) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.is_hemisphere = true
	mesh.radial_segments = 9
	mesh.rings = 3
	return mesh


## A flat round lid (the inside of the plant's mouth).
static func disc(radius: float) -> CylinderMesh:
	var mesh := cylinder(radius, 0.02)
	mesh.radial_segments = 9
	return mesh


## A sphere of radius with 10 sides and 5 rings.
static func sphere(radius: float) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 10
	mesh.rings = 5
	return mesh


## A cylinder of radius and height with 8 sides.
static func cylinder(radius: float, height: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 8
	return mesh


## A cone: a cylinder whose top radius is 0.
static func cone(radius: float, height: float) -> CylinderMesh:
	var mesh := cylinder(radius, height)
	mesh.top_radius = 0.0
	return mesh


## mesh repeated at each of xforms, merged into one mesh (one draw call).
static func merged(mesh: Mesh, xforms: Array[Transform3D]) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for xform in xforms:
		tool.append_from(mesh, 0, xform)
	return tool.commit()


```

These bodies are the six `BattleActor` statics verbatim (`_disc` and `_cone` called `_cylinder`; now `cylinder`). Then add this line as the last line of the header comment (the `##` block right under `class_name LowPoly`):

```gdscript
## The primitives (sphere, cylinder, cone, hemisphere, disc) and merged() serve BattleActor's builders.
```

- [ ] **Step 5: Remove the six statics from `BattleActor` and rename their calls**

```bash
cd /c/Users/peixe/Documents/rpg-turnos
awk -v names="_hemisphere _disc _sphere _cylinder _cone _merged" -v moved=C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/discard_prims.gd -f C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/tools/move_members.awk scripts/battle/battle_actor.gd > C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/ba.new && cp C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/ba.new scripts/battle/battle_actor.gd
sed -i -E 's/\b_(sphere|cylinder|cone|disc|hemisphere|merged)\(/LowPoly.\1(/g' scripts/battle/battle_actor.gd
grep -oE 'LowPoly\.(sphere|cylinder|cone|disc|hemisphere|merged)\(' scripts/battle/battle_actor.gd | sort | uniq -c
grep -cE '\b_(sphere|cylinder|cone|disc|hemisphere|merged)\(' scripts/battle/battle_actor.gd
```

Expected (no `NOT FOUND` line from awk):

```
     28 LowPoly.cone(
     16 LowPoly.cylinder(
      3 LowPoly.disc(
      3 LowPoly.hemisphere(
      6 LowPoly.merged(
     71 LowPoly.sphere(
0
```

- [ ] **Step 6: Verify**

Run H0; H1 on `scripts/battle/low_poly.gd` and `scripts/battle/battle_actor.gd`; H2; H3; H4. All as expected there.

- [ ] **Step 7: Update `CLAUDE.md`**

In the `scripts/battle/low_poly.gd` (`LowPoly`) entry, replace `(\`override\` becomes the instance's \`material_override\`).` with:

```
(`override` becomes the instance's `material_override`), and the primitives of `BattleActor`'s builders (M-72): `sphere(radius)`, `cylinder(radius, height)`, `cone(radius, height)`, `hemisphere(radius, height)`, `disc(radius)` and `merged(mesh, xforms)` (one mesh repeated at each transform, one draw call).
```

In the `scenes/battle/battle_actor.tscn` + `scripts/battle/battle_actor.gd` entry, replace `; \`_merged()\`)` with `; \`LowPoly.merged()\`)`.

- [ ] **Step 8: Commit**

```bash
git add scripts/battle/low_poly.gd scripts/battle/battle_actor.gd CLAUDE.md
git commit -m "Move BattleActor's mesh primitives into LowPoly"
```

---

### Task 2: `ActorLooks`, the look data

**Files:**
- Create: `scripts/battle/actor_looks.gd` (+ its `.gd.uid` from `--import`)
- Modify: `scripts/battle/battle_actor.gd`, `CLAUDE.md`

**Interfaces:**
- Consumes: Task 1's helper.
- Produces:
  - `class_name ActorLooks extends RefCounted` with `enum Look { HERO, ... CARAVAN_COLLECTOR }` (same 75 values, same order) and `const LOOKS: Dictionary` (look → entry), plus the constants the entries name: `KNIGHT`, `MAGE`, `SKELETON_WARRIOR`, `SKELETON_ROGUE`, `SKELETON_MAGE`, `SKELETON_BLADE`, `SKELETON_STAFF`, `SKELETON_SHIELD`, `RIGHT_HAND_BONE`, `LEFT_HAND_BONE`, `FOG_AURA_COLOR`, `ECHO_AURA_COLOR`, `CHARACTER_SCALE`, `CHARACTER_ANIMS`, `SKELETON_ANIMS`, `ROGUE_ANIMS`, `HERO_SKIN`, `HERO_HEAD_TEXTURE`, `HERO_TUNIC`, `HERO_LEGS`, `HEAD_GREY`, `HEAD_BLACK_DARK`, `HEAD_RED`, `HEAD_BLOND`, `HEAD_BROWN_DARK`, `HEAD_BROWN_PALE`, `HAIR_GREY`, `HAIR_BLOND`, `HAIR_RED`, `HAIR_BROWN`, `SKIN_DARK`, `SKIN_PALE`, `PERSON_HIDE`, `HAIR_PIECES`, `HAIR_PROFILES`, `HAIR_SEGMENTS`.
  - In `BattleActor`: `const Look = ActorLooks.Look` (so `BattleActor.Look.X` and `actor.look = BattleActor.Look.X` keep working).

- [ ] **Step 1: Create the file's skeleton**

`scripts/battle/actor_looks.gd`:

```gdscript
class_name ActorLooks extends RefCounted
## Data only: every figure a BattleActor can be (enum Look) and what each is made of
## (LOOKS), with the KayKit models, weapons, head textures, colours and animation tables
## the entries name. Read by BattleActor, CreatureBuilder and CharacterBuilder; never
## touches nodes. BattleActor.Look is this enum (const Look = ActorLooks.Look).

```

(The file ends with one empty line after the header; the constants are appended in Step 2.)

- [ ] **Step 2: Move the enum and the constants verbatim**

```bash
cd /c/Users/peixe/Documents/rpg-turnos
rm -f C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/looks_moved.gd
awk -v names="Look KNIGHT MAGE SKELETON_WARRIOR SKELETON_ROGUE SKELETON_MAGE SKELETON_BLADE SKELETON_STAFF SKELETON_SHIELD RIGHT_HAND_BONE LEFT_HAND_BONE FOG_AURA_COLOR ECHO_AURA_COLOR CHARACTER_SCALE CHARACTER_ANIMS SKELETON_ANIMS ROGUE_ANIMS HERO_SKIN HERO_HEAD_TEXTURE HERO_TUNIC HERO_LEGS HEAD_GREY HEAD_BLACK_DARK HEAD_RED HEAD_BLOND HEAD_BROWN_DARK HEAD_BROWN_PALE HAIR_GREY HAIR_BLOND HAIR_RED HAIR_BROWN SKIN_DARK SKIN_PALE PERSON_HIDE HAIR_PIECES HAIR_PROFILES HAIR_SEGMENTS LOOKS" -v moved=C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/looks_moved.gd -f C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/tools/move_members.awk scripts/battle/battle_actor.gd > C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/ba.new && cp C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/ba.new scripts/battle/battle_actor.gd
cat C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/looks_moved.gd >> scripts/battle/actor_looks.gd
grep -cE '^(const|enum) ' scripts/battle/actor_looks.gd
```

Expected: no `NOT FOUND` line, then `38`. Each constant carries its `##` doc lines (the "KayKit characters are 2.47 units tall", "The hero as a person...", "Everything that changes between looks..." comments go with `CHARACTER_SCALE`, `HERO_SKIN` and `LOOKS`). `SKELETON_PATH` (with its "Bones the weapons hang from" comment) stays in `BattleActor` until Task 5.

With the Edit tool in `scripts/battle/actor_looks.gd`, give the two hand bones the comment they lost: replace

```gdscript
const RIGHT_HAND_BONE := "handslot.r"
```

with

```gdscript
## Bones the skeletons' weapons hang from (LOOKS "props"), under the model's Rig/Skeleton3D.
const RIGHT_HAND_BONE := "handslot.r"
```

- [ ] **Step 3: The alias and the qualified names in `BattleActor`**

With the Edit tool in `scripts/battle/battle_actor.gd`, replace

```gdscript
## play_* can be awaited: it returns when its animation and its tween are done.


## What floats under a damage number: nothing, "¡Débil!" or "¡Resiste!".
```

with

```gdscript
## play_* can be awaited: it returns when its animation and its tween are done.

## Every figure a BattleActor can be: the enum lives in ActorLooks, and BattleActor.Look.X
## keeps working through this alias.
const Look = ActorLooks.Look
## What floats under a damage number: nothing, "¡Débil!" or "¡Resiste!".
```

Then:

```bash
sed -i -E -e 's/\b(HAIR_PIECES|HAIR_PROFILES|HAIR_SEGMENTS|FOG_AURA_COLOR)\b/ActorLooks.\1/g' -e 's/\bLOOKS\[look\]/ActorLooks.LOOKS[look]/g' scripts/battle/battle_actor.gd
grep -n 'ActorLooks\.' scripts/battle/battle_actor.gd
N='KNIGHT|MAGE|SKELETON_WARRIOR|SKELETON_ROGUE|SKELETON_MAGE|SKELETON_BLADE|SKELETON_STAFF|SKELETON_SHIELD|RIGHT_HAND_BONE|LEFT_HAND_BONE|FOG_AURA_COLOR|ECHO_AURA_COLOR|CHARACTER_SCALE|CHARACTER_ANIMS|SKELETON_ANIMS|ROGUE_ANIMS|HERO_SKIN|HERO_HEAD_TEXTURE|HERO_TUNIC|HERO_LEGS|HEAD_GREY|HEAD_BLACK_DARK|HEAD_RED|HEAD_BLOND|HEAD_BROWN_DARK|HEAD_BROWN_PALE|HAIR_GREY|HAIR_BLOND|HAIR_RED|HAIR_BROWN|SKIN_DARK|SKIN_PALE|PERSON_HIDE|HAIR_PIECES|HAIR_PROFILES|HAIR_SEGMENTS|LOOKS'
grep -nE "(^|[^.A-Za-z0-9_])($N)\b" scripts/battle/battle_actor.gd | grep -vE '^[0-9]+:##'; echo "leftovers done"
```

Expected from the first grep (line numbers stripped here), these ten lines:

```
const Look = ActorLooks.Look
	var data: Dictionary = ActorLooks.LOOKS[look]
	_set_flash(true, ActorLooks.FOG_AURA_COLOR)
## A hair piece (ActorLooks.HAIR_PIECES: a beard, a bun or a ponytail), faceted like the slimes, in the
	var piece: Dictionary = ActorLooks.HAIR_PIECES[hair.style]
	profile.assign(ActorLooks.HAIR_PROFILES[piece.profile])
	_add_blob(head, profile, ActorLooks.HAIR_SEGMENTS, hair.color, piece.pos, piece.rot, piece.scale)
	_set_flash(true, ActorLooks.LOOKS[look].glow_color)
	var fly: float = ActorLooks.LOOKS[look].fly
	var beat: float = ActorLooks.LOOKS[look].get("flap_time", 0.18)
```

and `leftovers done` alone from the second.

- [ ] **Step 4: Verify, including every script that names `BattleActor.Look`**

Run H0; H1 on `scripts/battle/actor_looks.gd`, `scripts/battle/battle_actor.gd`, `scripts/battle/enemy_library.gd`, `scripts/battle/battle_scene.gd`, `scripts/world/world.gd`, `scripts/world/player.gd`, `scripts/world/zone_data.gd`, `scripts/story/beyond_screen.gd`.

Then H2, H3 and H4.

- [ ] **Step 5: Update `CLAUDE.md`**

In the `BattleActor` entry, replace `figure of a fighter or villager built from the \`LOOKS\` table (\`look\`:` with:

```
figure of a fighter or villager built from `ActorLooks.LOOKS` (`look`, an `ActorLooks.Look`, which `BattleActor.Look` aliases:
```

In the `scripts/tools/head_textures.gd` entry, replace `(see \`BattleActor\`)` with `(see \`ActorLooks\`)`.

Add this entry right after the `BattleActor` entry:

```
- `scripts/battle/actor_looks.gd` (`ActorLooks`, `RefCounted`, data only, M-72) — every figure a `BattleActor` can be: `enum Look` (`BattleActor.Look` is its alias, `const Look = ActorLooks.Look`, so `BattleActor.Look.X` keeps working) and `LOOKS` (look → what it is made of: a KayKit `scene` with `scale`, `top`, `hide`, `anims`, `tint`, `mesh_tints`, `props`, `aura`, `head_texture`, `hair`, `cape` / `hide_cape`, `wrap_color`, `neck_glow`; or the colours, `scale`, `top`, `fly`, `flap_time`, `alpha`... of a figure built in code), with what the entries name: the KayKit models and the skeletons' weapons (`KNIGHT`, `MAGE`, `SKELETON_*`), `CHARACTER_SCALE`, the animation tables `CHARACTER_ANIMS` / `SKELETON_ANIMS` / `ROGUE_ANIMS`, the hand bones, the hero's and the caravan people's colours and heads (`HERO_*`, `HEAD_*`, `HAIR_*`, `SKIN_*`, `PERSON_HIDE`), the hair pieces (`HAIR_PIECES`, `HAIR_PROFILES`, `HAIR_SEGMENTS`) and the aura colours (`FOG_AURA_COLOR`, `ECHO_AURA_COLOR`). Never touches nodes.
```

- [ ] **Step 6: Commit**

```bash
git add scripts/battle/actor_looks.gd scripts/battle/actor_looks.gd.uid scripts/battle/battle_actor.gd CLAUDE.md
git status --short; echo "status done"
git commit -m "Move BattleActor's look data into ActorLooks"
```

Expected before the commit: `status done` alone after the add (nothing left unstaged).

---

### Task 3: The builder methods and `CreatureBuilder` with the v1 figures

**Files:**
- Create: `scripts/battle/creature_builder.gd` (+ `.gd.uid`)
- Modify: `scripts/battle/battle_actor.gd`, `CLAUDE.md`

**Interfaces:**
- Consumes: `LowPoly.sphere/cylinder/cone/hemisphere/disc` (Task 1), `ActorLooks.Look` (Task 2).
- Produces, in `BattleActor` (public, for the builders only):
  - `func body() -> Node3D` (returns `_body`)
  - `func add_mesh(parent: Node3D, mesh: Mesh, color: Color, pos: Vector3, roughness := 0.8) -> void` (was `_add_mesh`; registers its material in `_materials`)
  - `func add_ghost(parent: Node3D, mesh: Mesh, color: Color, alpha: float, pos: Vector3, scl: Vector3) -> void` (was `_add_ghost`; registers in `_ghosts`)
  - `func add_blob(parent: Node3D, profile: Array[Vector2], segments: int, color: Color, pos: Vector3, rot_deg := Vector3.ZERO, scl := Vector3.ONE) -> void` (was `_add_blob`)
  - `func add_wing(pivot: Node3D) -> void` (appends to `_wings`)
  - `func set_sway(node: Node3D) -> void`, `func set_jaw(node: Node3D) -> void`, `func set_hover(node: Node3D) -> void`
- Produces, in `CreatureBuilder`: `static func build_slime|build_board|build_cat|build_bat|build_mushroom|build_wolf|build_chicken|build_goblin|build_plant|build_golem|build_spider|build_specter(actor: BattleActor, data: Dictionary) -> void` (the spec's `build_x(actor, look)`: the entry parameter keeps its current name `data`, so the bodies stay verbatim), and the constants `GOLD`, `SLIME_PROFILE`, `SLIME_SEGMENTS`, `WOLF_BODY_PROFILE`, `WOLF_HEAD_PROFILE`, `LEG_PROFILE`, `BLOCK_PROFILE`, `ABDOMEN_PROFILE`, `SPECTER_PROFILE`, `SPECTER_ALPHA`, `AURA_ALPHA`.

What each moved function writes into the actor today, and what it calls instead:

| Function | Writes / reads today | After the move |
|---|---|---|
| every one | `_body` (read), `_add_mesh` / `_add_blob` / `_add_ghost` (fill `_materials`, `_ghosts`) | `actor.body()`, `actor.add_mesh()` / `add_blob()` / `add_ghost()` |
| `_build_bat` | `_wings.append(pivot)` | `actor.add_wing(pivot)` |
| `_build_wolf` | `_materials.back()` (the rosette's material) | `(root.get_child(-1) as MeshInstance3D).material_override` (the same object: `add_mesh` sets it and adds the mesh last under `root`) |
| `_build_plant` | `_sway`, `_jaw` (set and used), `JAW_REST` | locals `sway`, `jaw` + `actor.set_sway()`, `actor.set_jaw()`, `BattleActor.JAW_REST` |
| `_build_specter` | `_hover` (set and used) | local `hover` + `actor.set_hover()` |

- [ ] **Step 1: Create the file's skeleton**

`scripts/battle/creature_builder.gd`:

```gdscript
class_name CreatureBuilder extends RefCounted
## Constructor: the BattleActor figures built in code (the slimes, the bat, the mushroom,
## the wolf, the golems, the spider, the specter, the plant, the creatures that fight beside
## the hero...), each from its ActorLooks.LOOKS entry. Static only, keeps no state: each
## build_x(actor, data) hangs its meshes under actor.body() through the actor's builder
## methods (add_mesh, add_blob, add_ghost) and names its moving parts with add_wing,
## set_sway, set_jaw and set_hover, never the actor's private members.

## The Rey Slime's crown.
```

(The file ends with that comment line: Step 2 appends `const GOLD` right under it.)

- [ ] **Step 2: Move the constants verbatim**

```bash
cd /c/Users/peixe/Documents/rpg-turnos
rm -f C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/creature_consts.gd
awk -v names="GOLD SLIME_PROFILE SLIME_SEGMENTS WOLF_BODY_PROFILE WOLF_HEAD_PROFILE LEG_PROFILE BLOCK_PROFILE ABDOMEN_PROFILE SPECTER_PROFILE SPECTER_ALPHA AURA_ALPHA" -v moved=C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/creature_consts.gd -f C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/tools/move_members.awk scripts/battle/battle_actor.gd > C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/ba.new && cp C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/ba.new scripts/battle/battle_actor.gd
cat C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/creature_consts.gd >> scripts/battle/creature_builder.gd
printf '\n\n' >> scripts/battle/creature_builder.gd
grep -cE '^const ' scripts/battle/creature_builder.gd
```

Expected: no `NOT FOUND`, then `11`.

- [ ] **Step 3: Move the twelve v1 builders and rename their accesses**

```bash
rm -f C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/creatures_a.gd
awk -v names="_build_slime _build_board _build_cat _build_bat _build_mushroom _build_wolf _build_chicken _build_goblin _build_plant _build_golem _build_spider _build_specter" -v moved=C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/creatures_a.gd -f C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/tools/move_members.awk scripts/battle/battle_actor.gd > C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/ba.new && cp C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/ba.new scripts/battle/battle_actor.gd
sed -i -E \
 -e 's/^func _build_([a-z]+)\(data: Dictionary\) -> void:$/static func build_\1(actor: BattleActor, data: Dictionary) -> void:/' \
 -e 's/\b_body\b/actor.body()/g' \
 -e 's/\b_add_(mesh|blob|ghost)\(/actor.add_\1(/g' \
 -e 's/\b_wings\.append\(pivot\)/actor.add_wing(pivot)/g' \
 -e 's/\b_sway\b/sway/g' -e 's/\b_jaw\b/jaw/g' -e 's/\b_hover\b/hover/g' \
 -e 's/^\t(sway|jaw|hover) = Node3D\.new\(\)$/\tvar \1 := Node3D.new()/' \
 -e 's/^\tactor\.body\(\)\.add_child\((sway|hover)\)$/&\n\tactor.set_\1(\1)/' \
 -e 's/^\thead\.add_child\(jaw\)$/&\n\tactor.set_jaw(jaw)/' \
 -e 's/\bJAW_REST\b/BattleActor.JAW_REST/g' \
 -e 's/^(\t+)var mat := _materials\.back\(\) as StandardMaterial3D$/\1var mat := (root.get_child(-1) as MeshInstance3D).material_override as StandardMaterial3D/' \
 C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/creatures_a.gd
cat C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/creatures_a.gd >> scripts/battle/creature_builder.gd
grep -nE '^static func|set_sway|set_jaw|set_hover|add_wing|var (sway|jaw|hover) |JAW_REST|var mat' scripts/battle/creature_builder.gd | sed -E 's/^[0-9]+://'
grep -nE '\b_(body|wings|sway|jaw|hover|devourer|eyelid|materials|ghosts|model|anims?|aura|top)\b|\bself\b' scripts/battle/creature_builder.gd; echo "privates done"
```

Expected: no `NOT FOUND`; then (dry-run output):

```
static func build_slime(actor: BattleActor, data: Dictionary) -> void:
static func build_board(actor: BattleActor, data: Dictionary) -> void:
static func build_cat(actor: BattleActor, data: Dictionary) -> void:
static func build_bat(actor: BattleActor, data: Dictionary) -> void:
		actor.add_wing(pivot)
static func build_mushroom(actor: BattleActor, data: Dictionary) -> void:
static func build_wolf(actor: BattleActor, data: Dictionary) -> void:
			var mat := (root.get_child(-1) as MeshInstance3D).material_override as StandardMaterial3D
static func build_chicken(actor: BattleActor, data: Dictionary) -> void:
static func build_goblin(actor: BattleActor, data: Dictionary) -> void:
static func build_plant(actor: BattleActor, data: Dictionary) -> void:
	var sway := Node3D.new()
	actor.set_sway(sway)
	var jaw := Node3D.new()
	actor.set_jaw(jaw)
	jaw.rotation.x = BattleActor.JAW_REST
static func build_golem(actor: BattleActor, data: Dictionary) -> void:
static func build_spider(actor: BattleActor, data: Dictionary) -> void:
static func build_specter(actor: BattleActor, data: Dictionary) -> void:
	var hover := Node3D.new()
	actor.set_hover(hover)
privates done
```

The start of `build_plant` must now read:

```gdscript
static func build_plant(actor: BattleActor, data: Dictionary) -> void:
	var sway := Node3D.new()
	sway.scale = Vector3.ONE * data.scale
	actor.body().add_child(sway)
	actor.set_sway(sway)
```

- [ ] **Step 4: The builder methods in `BattleActor`, and the remaining code renamed**

```bash
sed -i -E 's/\b_add_(mesh|blob|ghost)\(/add_\1(/g' scripts/battle/battle_actor.gd
sed -i -E 's/\b(SLIME_PROFILE|SLIME_SEGMENTS|WOLF_BODY_PROFILE|WOLF_HEAD_PROFILE|LEG_PROFILE)\b/CreatureBuilder.\1/g' scripts/battle/battle_actor.gd
sed -i -E 's/^(\t+)_build_(slime|board|cat|bat|mushroom|wolf|chicken|goblin|plant|golem|spider|specter)\(data\)$/\1CreatureBuilder.build_\2(self, data)/' scripts/battle/battle_actor.gd
grep -c 'CreatureBuilder\.build_' scripts/battle/battle_actor.gd
grep -oE 'CreatureBuilder\.[A-Z_]+' scripts/battle/battle_actor.gd | sort | uniq -c
grep -nwE 'GOLD|BLOCK_PROFILE|ABDOMEN_PROFILE|SPECTER_PROFILE|SPECTER_ALPHA|AURA_ALPHA' scripts/battle/battle_actor.gd; echo "consts done"
grep -cE '\b_add_(mesh|blob|ghost)\(' scripts/battle/battle_actor.gd
```

Expected:

```
12
      6 CreatureBuilder.LEG_PROFILE
      5 CreatureBuilder.SLIME_PROFILE
      5 CreatureBuilder.SLIME_SEGMENTS
      4 CreatureBuilder.WOLF_BODY_PROFILE
      4 CreatureBuilder.WOLF_HEAD_PROFILE
consts done
0
```

(The v2 builders still in `BattleActor` use the profiles through `CreatureBuilder.` until Task 4.)

With the Edit tool in `scripts/battle/battle_actor.gd`, replace

```gdscript
func add_mesh(parent: Node3D, mesh: Mesh, color: Color, pos: Vector3, \
```

with

```gdscript
## Builders only (CreatureBuilder, CharacterBuilder): the visual root the figure hangs
## from; the tweens move and scale it, the actor node itself stays put.
func body() -> Node3D:
	return _body


## Builders only: a wing pivot the idle loop flaps (the bat, the griffin, the gargoyle).
func add_wing(pivot: Node3D) -> void:
	_wings.append(pivot)


## Builders only: the node the idle loop sways (the plant, the worm).
func set_sway(node: Node3D) -> void:
	_sway = node


## Builders only: the plant's upper jaw, which play_attack() opens to bite.
func set_jaw(node: Node3D) -> void:
	_jaw = node


## Builders only: the node the specter's idle loop floats up and down.
func set_hover(node: Node3D) -> void:
	_hover = node


## Builders only: a mesh in one flat colour under parent; its material fades with the
## figure on defeat.
func add_mesh(parent: Node3D, mesh: Mesh, color: Color, pos: Vector3, \
```

`add_ghost` and `add_blob` keep their `##` comments; add `Builders only: ` at the start of each of those two first comment lines.

- [ ] **Step 5: Verify**

Run H0; H1 on `scripts/battle/creature_builder.gd` and `scripts/battle/battle_actor.gd`; H2; H3; H4. In H4, the portraits of the looks built here are `SLIME`, `KING_SLIME`, `METAL_SLIME`, `RED_SLIME`, `SAND_SLIME`, `BOARD`, `CAT`, `BAT`, `CRYPT_BAT`, `VULTURE`, `ICE_BAT`, the four mushrooms, `WOLF`, `WOLF_CUB`, `JAGUAR`, `SNOW_WOLF`, `CHICKEN`, `GOBLIN`, `PLANT`, `TRAP_PLANT`, the five golems, `SPIDER` and the four specters: all must come out unchanged (`git status assets/bestiary` clean, or equal by eye if listed as unstable). The ones that are not enemies (`BOARD`, `CAT`, `CHICKEN`, `WOLF_CUB`) are seen in the H3 and H2 frames when they appear; otherwise `--check-only` and the unchanged code are the check.

- [ ] **Step 6: Update `CLAUDE.md`**

In the `BattleActor` entry:
- replace `(the plant in green and pink, \`_build_plant()\`)` with `(the plant in green and pink, \`CreatureBuilder.build_plant()\`)`;
- replace `(orange cap, \`_build_mushroom()\`)` with `(orange cap, \`CreatureBuilder.build_mushroom()\`)`;
- replace `` `_build_wolf()` ×1.75 `` with `` `CreatureBuilder.build_wolf()` ×1.75 ``;
- replace `` `hops()` (the slimes) and `play_hop()`; `reset()`. `` with:

```
`hops()` (the slimes) and `play_hop()`; `reset()`. Builder methods, for `CreatureBuilder` and `CharacterBuilder` only (M-72): `body()`, `add_mesh()`, `add_blob()`, `add_ghost()`, `add_wing()`, `set_sway()`, `set_jaw()`, `set_hover()`.
```

Add this entry right after the `ActorLooks` entry:

```
- `scripts/battle/creature_builder.gd` (`CreatureBuilder`, `RefCounted`, builder, M-72) — the `BattleActor` figures built in code from their `ActorLooks.LOOKS` entry, each a `static func build_x(actor: BattleActor, data: Dictionary)`: `build_slime` (the slimes and the Rey Slime's crown, `GOLD`), `build_board`, `build_cat`, `build_bat` (also the crypt and ice bats and the Buitre), `build_mushroom`, `build_wolf` (also the cub, the Jaguar and the snow wolf), `build_chicken`, `build_goblin`, `build_plant`, `build_golem`, `build_spider` and `build_specter`, with the profiles they lathe (`SLIME_PROFILE`, `WOLF_BODY_PROFILE`, `WOLF_HEAD_PROFILE`, `LEG_PROFILE`, `BLOCK_PROFILE`, `ABDOMEN_PROFILE`, `SPECTER_PROFILE`) and the specter's opacities (`SPECTER_ALPHA`, `AURA_ALPHA`). Static, no state: it hangs the meshes under `actor.body()` through `actor.add_mesh()` / `add_blob()` / `add_ghost()` and names the moving parts with `actor.add_wing()`, `set_sway()`, `set_jaw()` and `set_hover()`, never the actor's private members. The v2's figures built in code are still `BattleActor._build_*`.
```

- [ ] **Step 7: Commit**

```bash
git add scripts/battle/creature_builder.gd scripts/battle/creature_builder.gd.uid scripts/battle/battle_actor.gd CLAUDE.md
git commit -m "Move the v1 figures built in code from BattleActor into CreatureBuilder"
```

---

### Task 4: The v2 figures in `CreatureBuilder`, and `CreatureBuilder.build()`

**Files:**
- Modify: `scripts/battle/creature_builder.gd`, `scripts/battle/battle_actor.gd`, `CLAUDE.md`

**Interfaces:**
- Consumes: everything of Task 3; `LowPoly.merged()` (Task 1).
- Produces:
  - `func BattleActor.set_devourer(mass: Node3D, eyelid: Node3D) -> void`
  - `static func CreatureBuilder.build(actor: BattleActor, data: Dictionary) -> void` (picks the `build_x` for `actor.look`; the `elif` chain of `BattleActor._ready()`, verbatim)
  - `static func CreatureBuilder.build_goat|build_griffin|build_gargoyle|build_rat|build_devourer|build_frog|build_snake|build_monkey|build_scorpion|build_worm|build_canteen|build_pot(actor: BattleActor, data: Dictionary) -> void`
  - the constants `DEVOURER_PROFILE`, `EYELID_HALF`, `DEVOURER_LUMPS`, `DEVOURER_MOUTHS`, `TREE_SHADER` move to `CreatureBuilder`; `DEVOURER_GROWTH` and `EYELID_OPEN` stay in `BattleActor` (`_devourer_wakes()` uses them).

What each moved function writes into the actor today:

| Function | Writes / reads today | After the move |
|---|---|---|
| every one | `_body`, `add_mesh` / `add_blob` | `actor.body()`, `actor.add_mesh()` / `add_blob()` |
| `_build_griffin`, `_build_gargoyle` | `_wings.append(pivot)` | `actor.add_wing(pivot)` |
| `_build_worm` | `_sway` (set and used) | local `sway` + `actor.set_sway()` |
| `_build_devourer` | `_devourer`, `_eyelid` (set and used) | locals `devourer`, `eyelid` + `actor.set_devourer(devourer, eyelid)` after the last line |
| `_build_pot` | `TREE_SHADER` | moves with it |

- [ ] **Step 1: Move the constants**

```bash
cd /c/Users/peixe/Documents/rpg-turnos
rm -f C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/creature_consts_b.gd
awk -v names="DEVOURER_PROFILE EYELID_HALF DEVOURER_LUMPS DEVOURER_MOUTHS TREE_SHADER" -v moved=C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/creature_consts_b.gd -f C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/tools/move_members.awk scripts/battle/battle_actor.gd > C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/ba.new && cp C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/ba.new scripts/battle/battle_actor.gd
cat C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/creature_consts_b.gd
```

Expected: no `NOT FOUND`, and the five constants printed with the "The Devorador del portal: the side profile..." comment above `DEVOURER_PROFILE` and "The trees' shader, for the pot's vertex colours..." above `TREE_SHADER`.

With the Edit tool in `scripts/battle/creature_builder.gd`, insert the printed constants right above the line `## The Rey Slime's crown.`, replacing the Devorador comment's three lines with:

```gdscript
## The Devorador del portal: the side profile of its mass (lathed around +Y), its eyelid's
## angle half closed, its lumps ([degrees from the front, height, size]) and its mouths round
## the mass ([degrees from the front, height]).
```

With the Edit tool in `scripts/battle/battle_actor.gd`, replace

```gdscript
const DEVOURER_GROWTH := 1.25
```

with

```gdscript
## The Devorador del portal's second phase (_devourer_wakes()): the share its mass grows by
## and its eyelid's open angle.
const DEVOURER_GROWTH := 1.25
```

- [ ] **Step 2: Move the twelve v2 builders and rename their accesses**

```bash
rm -f C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/creatures_b.gd
awk -v names="_build_goat _build_griffin _build_gargoyle _build_rat _build_devourer _build_frog _build_snake _build_monkey _build_scorpion _build_worm _build_canteen _build_pot" -v moved=C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/creatures_b.gd -f C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/tools/move_members.awk scripts/battle/battle_actor.gd > C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/ba.new && cp C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/ba.new scripts/battle/battle_actor.gd
sed -i -E \
 -e 's/^func _build_([a-z]+)\(data: Dictionary\) -> void:$/static func build_\1(actor: BattleActor, data: Dictionary) -> void:/' \
 -e 's/\b_body\b/actor.body()/g' \
 -e 's/\badd_(mesh|blob|ghost)\(/actor.add_\1(/g' \
 -e 's/\b_wings\.append\(pivot\)/actor.add_wing(pivot)/g' \
 -e 's/CreatureBuilder\.//g' \
 -e 's/\b_sway\b/sway/g' -e 's/\b_devourer\b/devourer/g' -e 's/\b_eyelid\b/eyelid/g' \
 -e 's/^\t(sway|devourer|eyelid) = Node3D\.new\(\)$/\tvar \1 := Node3D.new()/' \
 -e 's/^\tactor\.body\(\)\.add_child\(sway\)$/&\n\tactor.set_sway(sway)/' \
 -e 's/^\tdevourer\.add_child\(glow\)$/&\n\tactor.set_devourer(devourer, eyelid)/' \
 -e "s/the bat's _wings:/the bat's wings, BattleActor.add_wing():/" \
 -e "s/the bat's _wings,/the bat's wings, BattleActor.add_wing(),/" \
 -e 's/It sways \(sway\) like the plant\./It sways (BattleActor.set_sway()) like the plant./' \
 C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/creatures_b.gd
cat C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/creatures_b.gd >> scripts/battle/creature_builder.gd
grep -nE '^static func build_(goat|griffin|gargoyle|rat|devourer|frog|snake|monkey|scorpion|worm|canteen|pot)\(|set_sway|set_devourer|add_wing\(pivot|var (sway|devourer|eyelid) ' scripts/battle/creature_builder.gd | sed -E 's/^[0-9]+://'
grep -nE '\b_(body|wings|sway|jaw|hover|devourer|eyelid|materials|ghosts|model|anims?|aura|top)\b|\bself\b|CreatureBuilder\.' scripts/battle/creature_builder.gd; echo "privates done"
```

(`add_mesh` / `add_blob` were already public names in the code left in `BattleActor` since Task 3; `\b` keeps `.add_child(` untouched. The `CreatureBuilder.` prefix of the profiles is dropped inside the class itself.)

Expected: no `NOT FOUND`; then (dry-run output):

```
static func build_goat(actor: BattleActor, data: Dictionary) -> void:
static func build_griffin(actor: BattleActor, data: Dictionary) -> void:
		actor.add_wing(pivot)
static func build_gargoyle(actor: BattleActor, data: Dictionary) -> void:
		actor.add_wing(pivot)
static func build_rat(actor: BattleActor, data: Dictionary) -> void:
static func build_devourer(actor: BattleActor, data: Dictionary) -> void:
	var devourer := Node3D.new()
	var eyelid := Node3D.new()
	actor.set_devourer(devourer, eyelid)
static func build_frog(actor: BattleActor, data: Dictionary) -> void:
static func build_snake(actor: BattleActor, data: Dictionary) -> void:
static func build_monkey(actor: BattleActor, data: Dictionary) -> void:
static func build_scorpion(actor: BattleActor, data: Dictionary) -> void:
static func build_worm(actor: BattleActor, data: Dictionary) -> void:
	var sway := Node3D.new()
	actor.set_sway(sway)
static func build_canteen(actor: BattleActor, data: Dictionary) -> void:
static func build_pot(actor: BattleActor, data: Dictionary) -> void:
privates done
```

`build_devourer` must end with:

```gdscript
	glow.position = Vector3(0, 1.5, -2.2)
	devourer.add_child(glow)
	actor.set_devourer(devourer, eyelid)
```

- [ ] **Step 3: `CreatureBuilder.build()` and the shorter `_ready()`**

With the Edit tool in `scripts/battle/creature_builder.gd`, insert `build()` as the first function, right above the line `static func build_slime(actor: BattleActor, data: Dictionary) -> void:` (`build_slime` has no doc comment):

```gdscript
## Builds the figure of a look without a KayKit scene: picks its build_x from actor.look.
static func build(actor: BattleActor, data: Dictionary) -> void:
	var look: int = actor.look
	if look in [Look.BAT, Look.CRYPT_BAT, Look.VULTURE, Look.ICE_BAT]:
		build_bat(actor, data)
	elif look in [Look.MUSHROOM, Look.POISON_MUSHROOM, Look.CAVE_MUSHROOM,
			Look.TROPICAL_MUSHROOM]:
		build_mushroom(actor, data)
	elif look in [Look.WOLF, Look.WOLF_CUB, Look.JAGUAR, Look.SNOW_WOLF]:
		build_wolf(actor, data)
	elif look == Look.CHICKEN:
		build_chicken(actor, data)
	elif look == Look.GOBLIN:
		build_goblin(actor, data)
	elif look == Look.PLANT or look == Look.TRAP_PLANT:
		build_plant(actor, data)
	elif look == Look.FROG:
		build_frog(actor, data)
	elif look == Look.SNAKE:
		build_snake(actor, data)
	elif look == Look.MONKEY:
		build_monkey(actor, data)
	elif look in [Look.MUD_GOLEM, Look.STONE_GOLEM, Look.MINI_GOLEM, Look.SAND_GOLEM,
			Look.ICE_GOLEM]:
		build_golem(actor, data)
	elif look == Look.SPIDER:
		build_spider(actor, data)
	elif look in [Look.SPECTER, Look.FROST_SPECTER, Look.SUMMIT_SPIRIT, Look.SHADOW]:
		build_specter(actor, data)
	elif look == Look.GOAT:
		build_goat(actor, data)
	elif look == Look.GRIFFIN:
		build_griffin(actor, data)
	elif look == Look.GARGOYLE:
		build_gargoyle(actor, data)
	elif look == Look.RUIN_RAT:
		build_rat(actor, data)
	elif look == Look.PORTAL_DEVOURER:
		build_devourer(actor, data)
	elif look == Look.SCORPION:
		build_scorpion(actor, data)
	elif look == Look.SAND_WORM:
		build_worm(actor, data)
	elif look == Look.CANTEEN:
		build_canteen(actor, data)
	elif look == Look.POT:
		build_pot(actor, data)
	elif look == Look.BOARD:
		build_board(actor, data)
	elif look == Look.CAT:
		build_cat(actor, data)
	else:
		build_slime(actor, data)


```

and add, right under the header comment of the file (above the first `##` constant comment):

```gdscript
const Look = ActorLooks.Look
```

This is the chain of `BattleActor._ready()` verbatim, in the same order, with `self` → `actor` and the first `elif` → `if` (the `scene` branch stays in `_ready()`).

With the Edit tool in `scripts/battle/battle_actor.gd`, replace the whole `func _ready() -> void:` body down to (and including) its last line `		CreatureBuilder.build_slime(self, data)` so that the function reads:

```gdscript
func _ready() -> void:
	_body = Node3D.new()
	add_child(_body)
	var data: Dictionary = ActorLooks.LOOKS[look]
	_top = data.top
	if data.has("scene"):
		_build_character(data)
	else:
		CreatureBuilder.build(self, data)
	for node in _body.find_children("*", "MeshInstance3D", true, false):
		_meshes.append(node as MeshInstance3D)
	_flash = StandardMaterial3D.new()
	_flash.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_flash.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_flash.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_highlight = _flash.duplicate() as StandardMaterial3D
	_highlight.albedo_color = Color(HIGHLIGHT_COLOR, HIGHLIGHT_ALPHA)
	reset()
```

With the Edit tool, insert `set_devourer` right under `set_hover` (above the `add_mesh` comment):

```gdscript
## Builders only: the Devorador's mass (it grows in its second phase) and its eyelid's pivot.
func set_devourer(mass: Node3D, eyelid: Node3D) -> void:
	_devourer = mass
	_eyelid = eyelid


```

Then:

```bash
grep -nE '\b_build_[a-z]+|CreatureBuilder' scripts/battle/battle_actor.gd | sed -E 's/^[0-9]+://'
grep -nE '^(func|static func) (build|build_[a-z]+)\(' scripts/battle/creature_builder.gd | wc -l
```

Expected:

```
		_build_character(data)
		CreatureBuilder.build(self, data)
		_horns = _build_horns(helmet)
func _build_horns(helmet: MeshInstance3D) -> Node3D:
func _build_character(data: Dictionary) -> void:
```

(order by line) and `25` (`build` + 24 `build_x`).

- [ ] **Step 4: Verify**

Run H0; H1 on `scripts/battle/creature_builder.gd` and `scripts/battle/battle_actor.gd`; H2; H3; H4. H4 covers the v2 creatures (the griffin's and the gargoyle's wings, the Devorador's eye and lid, the worm, the scorpion, the goat, the rat, the frog, the snake and the monkey). Also check the Devorador's second phase once (its eye opens, `_devourer_wakes()` reads `_devourer` / `_eyelid` set by `set_devourer()`):

```bash
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --fixed-fps 10 --quit-after 100000 -- --autoplay --autoplay-zone=portal > C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/portal.log 2>&1
grep -E '^(Escena|Juego completado)|El ojo del Devorador se abre' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/portal.log
grep -E 'ERROR|WARNING' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/portal.log; echo "grep done"
```

Expected: at least one line containing `El ojo del Devorador se abre`, then `Escena: cruce` and `Juego completado (v2): Nv 40, ...` (Nv 38 to 40 in about 13-15 minutes of play time, as in `CLAUDE.md`), and `grep done` with at most the known Jolt warning before it. If the run ends before the Devorador (a defeat loop), raise `--quit-after` to 150000.

- [ ] **Step 5: Update `CLAUDE.md`**

In the `BattleActor` entry, replace `` `set_jaw()`, `set_hover()`. `` (end of the builder methods sentence of Task 3) with `` `set_jaw()`, `set_hover()`, `set_devourer()`. ``

Replace the whole `scripts/battle/creature_builder.gd` entry with:

```
- `scripts/battle/creature_builder.gd` (`CreatureBuilder`, `RefCounted`, builder, M-72) — the `BattleActor` figures built in code from their `ActorLooks.LOOKS` entry: `build(actor, data)` picks one by `actor.look` (called by `BattleActor._ready()` for every look without a `scene`), each a `static func build_x(actor: BattleActor, data: Dictionary)`: `build_slime` (the slimes and the Rey Slime's crown, `GOLD`), `build_board`, `build_cat`, `build_bat` (also the crypt and ice bats and the Buitre), `build_mushroom`, `build_wolf` (also the cub, the Jaguar and the snow wolf), `build_chicken`, `build_goblin`, `build_plant`, `build_golem`, `build_spider`, `build_specter`, `build_goat`, `build_griffin`, `build_gargoyle`, `build_rat`, `build_devourer` (`DEVOURER_PROFILE`, `DEVOURER_LUMPS`, `DEVOURER_MOUTHS`, `EYELID_HALF`), `build_frog`, `build_snake`, `build_monkey`, `build_scorpion`, `build_worm`, `build_canteen` and `build_pot` (the Kenney pot through `TREE_SHADER`), with the profiles they lathe (`SLIME_PROFILE`, `WOLF_BODY_PROFILE`, `WOLF_HEAD_PROFILE`, `LEG_PROFILE`, `BLOCK_PROFILE`, `ABDOMEN_PROFILE`, `SPECTER_PROFILE`) and the specter's opacities (`SPECTER_ALPHA`, `AURA_ALPHA`). Static, no state: it hangs the meshes under `actor.body()` through `actor.add_mesh()` / `add_blob()` / `add_ghost()` and names the moving parts with `actor.add_wing()`, `set_sway()`, `set_jaw()`, `set_hover()` and `set_devourer()`, never the actor's private members.
```

- [ ] **Step 6: Commit**

```bash
git add scripts/battle/creature_builder.gd scripts/battle/battle_actor.gd CLAUDE.md
git commit -m "Move the v2 figures built in code into CreatureBuilder and let it pick the builder"
```

---

### Task 5: `CharacterBuilder`, the KayKit figures

**Files:**
- Create: `scripts/battle/character_builder.gd` (+ `.gd.uid`)
- Modify: `scripts/battle/battle_actor.gd`, `CLAUDE.md`

**Interfaces:**
- Consumes: the builder methods of Tasks 3-4, `ActorLooks.HAIR_PIECES` / `HAIR_PROFILES` / `HAIR_SEGMENTS` (Task 2), `LowPoly.sphere/cylinder` (Task 1), `BattleActor.HAND_R`, `BattleActor.set_equipment()`, `BattleActor.top_height()`, `BattleActor.look`.
- Produces:
  - in `BattleActor`: `func set_model(model: Node3D) -> void`, `func set_aura(aura: MeshInstance3D) -> void`, `func set_animations(player: AnimationPlayer, anims: Dictionary) -> void`
  - in `CharacterBuilder`: `static func build(actor: BattleActor, data: Dictionary) -> void` (was `_build_character`), `static func tint(model: Node3D, color: Color) -> void` and `static func tint_mesh(mi: MeshInstance3D, color: Color) -> void` (were `BattleActor._tint` / `_tint_mesh`; `set_equipment()` calls them), private statics `_add_hair(actor, model, hair)`, `_add_mummy_wraps(actor, bones, color)`, `_hang_on_bone(actor, bones, bone, mesh, color, rig_transform)`; the constants `SKELETON_PATH`, `FOG_AURA_ALPHA`, `ANIM_PLAYER_PATH`, `STICK_COLOR`, `STICK_RADIUS`, `STICK_LENGTH`, `STICK_CENTER`.

What `_build_character` writes into the actor today:

| Today | After the move |
|---|---|
| `_body` (read) | `actor.body()` |
| `_model = model` | `actor.set_model(model)` (same place: `set_equipment()` below needs it) |
| `_aura = _body.get_child(-1) as MeshInstance3D` | `actor.set_aura(actor.body().get_child(-1) as MeshInstance3D)` |
| `_top` (read, aura height) | `actor.top_height()` |
| `look == Look.HERO` | `actor.look == ActorLooks.Look.HERO` |
| `set_equipment(Equipment.STICK, "")` | `actor.set_equipment(Equipment.STICK, "")` |
| `_anims = data.anims`, `_anim = model.get_node(...)`, loop modes through `_anim` / `_anims` | a local `anim`, the loop modes on it, then `actor.set_animations(anim, data.anims)` |
| `add_mesh` / `add_ghost` / `add_blob` (also in `_add_hair`, `_hang_on_bone`), `HAND_R` | `actor.add_*`, `BattleActor.HAND_R` |

- [ ] **Step 1: Create the file's skeleton and move the constants**

`scripts/battle/character_builder.gd`:

```gdscript
class_name CharacterBuilder extends RefCounted
## Constructor: the BattleActor figures that are KayKit models (the hero, the villagers, the
## witch, the skeletons, the caravan's people, the companions...), from their
## ActorLooks.LOOKS entry: the model turned to face -Z with its props hidden, weapons on
## bones, tints, head texture, cape, hair pieces, the Momia's wraps, the Armadura's ember,
## an aura and the hero's stick. Static only, keeps no state: it writes into the actor
## through its builder methods (set_model, set_aura, set_animations, add_mesh...).

## Resting opacity of an aura (LOOKS "aura": the Señor de la Niebla, the Eco).
```

```bash
cd /c/Users/peixe/Documents/rpg-turnos
rm -f C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/character_consts.gd
awk -v names="FOG_AURA_ALPHA SKELETON_PATH ANIM_PLAYER_PATH STICK_COLOR STICK_RADIUS STICK_LENGTH STICK_CENTER" -v moved=C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/character_consts.gd -f C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/tools/move_members.awk scripts/battle/battle_actor.gd > C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/ba.new && cp C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/ba.new scripts/battle/battle_actor.gd
cat C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/character_consts.gd
```

Expected (source order; the awk keeps it):

```
## Bones the weapons hang from, under the model's Rig/Skeleton3D.
const SKELETON_PATH := "Rig/Skeleton3D"
const FOG_AURA_ALPHA := 0.2
## The AnimationPlayer inside a KayKit character scene.
const ANIM_PLAYER_PATH := "AnimationPlayer"
## The wooden stick built in code for Equipment.STICK_MESH: along the hand's +Y like the
## Knight's swords, grip at the hand.
const STICK_COLOR := Color(0.45, 0.3, 0.16)
const STICK_RADIUS := 0.07
const STICK_LENGTH := 1.3
const STICK_CENTER := 0.45
```

Append them to `scripts/battle/character_builder.gd` with the Edit tool so that `const FOG_AURA_ALPHA := 0.2` sits right under the skeleton's last comment line (`## Resting opacity of an aura ...`) and the other constants follow with their comments, then two empty lines.

With the Edit tool in `scripts/battle/battle_actor.gd`, give `FOG_AURA_PHASE_ALPHA` (now alone) a comment: replace `const FOG_AURA_PHASE_ALPHA := 0.38` with

```gdscript
## The Señor de la Niebla's aura in his second phase (play_phase()): thicker.
const FOG_AURA_PHASE_ALPHA := 0.38
```

- [ ] **Step 2: Move the six functions and rename their accesses**

```bash
rm -f C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/characters.gd
awk -v names="_build_character _add_hair _add_mummy_wraps _hang_on_bone _tint _tint_mesh" -v moved=C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/characters.gd -f C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/tools/move_members.awk scripts/battle/battle_actor.gd > C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/ba.new && cp C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/ba.new scripts/battle/battle_actor.gd
sed -i -E \
 -e 's/^func _build_character\(data: Dictionary\) -> void:$/static func build(actor: BattleActor, data: Dictionary) -> void:/' \
 -e 's/^func _add_hair\(model: Node3D, hair: Dictionary\) -> void:$/static func _add_hair(actor: BattleActor, model: Node3D, hair: Dictionary) -> void:/' \
 -e 's/^func _add_mummy_wraps\(bones: Skeleton3D, color: Color\) -> void:$/static func _add_mummy_wraps(actor: BattleActor, bones: Skeleton3D, color: Color) -> void:/' \
 -e 's/^func _hang_on_bone\(bones: Skeleton3D, bone: String, mesh: Mesh, color: Color,$/static func _hang_on_bone(actor: BattleActor, bones: Skeleton3D, bone: String, mesh: Mesh, color: Color,/' \
 -e 's/\b_tint_mesh\(/tint_mesh(/g' -e 's/\b_tint\(/tint(/g' \
 -e 's/\b_add_hair\(model,/_add_hair(actor, model,/' \
 -e 's/\b_add_mummy_wraps\(bones,/_add_mummy_wraps(actor, bones,/' \
 -e 's/\b_hang_on_bone\(bones,/_hang_on_bone(actor, bones,/g' \
 -e 's/\b_body\b/actor.body()/g' \
 -e 's/\badd_(mesh|blob|ghost)\(/actor.add_\1(/g' \
 -e 's/\bHAND_R\b/BattleActor.HAND_R/g' \
 -e 's/\b_top\b/actor.top_height()/g' \
 -e 's/^\t_model = model$/\tactor.set_model(model)/' \
 -e 's/^\t\t_aura = (actor\.body\(\)\.get_child\(-1\) as MeshInstance3D)$/\t\tactor.set_aura(\1)/' \
 -e 's/^\tif look == Look\.HERO:$/\tif actor.look == ActorLooks.Look.HERO:/' \
 -e 's/^\t\tset_equipment\(Equipment\.STICK, ""\)$/\t\tactor.set_equipment(Equipment.STICK, "")/' \
 -e 's/^\t_anims = data\.anims$/\tvar anim := model.get_node(ANIM_PLAYER_PATH) as AnimationPlayer/' \
 -e '/^\t_anim = model\.get_node\(ANIM_PLAYER_PATH\) as AnimationPlayer$/d' \
 -e 's/^\t\t_anim\.get_animation\(_anims\[role\]\)\.loop_mode = Animation\.LOOP_LINEAR$/\t\tanim.get_animation(data.anims[role]).loop_mode = Animation.LOOP_LINEAR\n\tactor.set_animations(anim, data.anims)/' \
 C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/characters.gd
cat C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/characters.gd >> scripts/battle/character_builder.gd
grep -nE '^static func|actor\.set_|_hang_on_bone\(actor|actor\.look' scripts/battle/character_builder.gd | sed -E 's/^[0-9]+://'
grep -nE '\b_(body|wings|sway|jaw|hover|devourer|eyelid|materials|ghosts|model|anims?|aura|top)\b|\bself\b|[^.]\bLook\.' scripts/battle/character_builder.gd; echo "privates done"
```

Expected: no `NOT FOUND`; then (dry-run output):

```
static func build(actor: BattleActor, data: Dictionary) -> void:
	actor.set_model(model)
		actor.set_aura(actor.body().get_child(-1) as MeshInstance3D)
	if actor.look == ActorLooks.Look.HERO:
		actor.set_equipment(Equipment.STICK, "")
	actor.set_animations(anim, data.anims)
static func _add_hair(actor: BattleActor, model: Node3D, hair: Dictionary) -> void:
static func _add_mummy_wraps(actor: BattleActor, bones: Skeleton3D, color: Color) -> void:
		_hang_on_bone(actor, bones, bone, cylinder, color, Transform3D(basis, pos))
		_hang_on_bone(actor, bones, end[0], strip, color * 0.92,
static func _hang_on_bone(actor: BattleActor, bones: Skeleton3D, bone: String, mesh: Mesh, color: Color,
static func tint(model: Node3D, color: Color) -> void:
static func tint_mesh(mi: MeshInstance3D, color: Color) -> void:
privates done
```

`build()` must end with:

```gdscript
		# The starting gear until set_equipment() says otherwise.
		actor.set_equipment(Equipment.STICK, "")
	var anim := model.get_node(ANIM_PLAYER_PATH) as AnimationPlayer
	# The imported animations do not loop; idle and walk must.
	for role in ["idle", "walk"]:
		anim.get_animation(data.anims[role]).loop_mode = Animation.LOOP_LINEAR
	actor.set_animations(anim, data.anims)
```

Give `build()` a doc comment (it had none): with the Edit tool insert right above `static func build(actor: BattleActor, data: Dictionary) -> void:`

```gdscript
## Builds the KayKit figure of data (a LOOKS entry with a "scene") on actor.
```

- [ ] **Step 3: The rest of `BattleActor`**

```bash
sed -i -E -e 's/\b_tint_mesh\(/CharacterBuilder.tint_mesh(/g' -e 's/\b_tint\(/CharacterBuilder.tint(/g' -e 's/^\t\t_build_character\(data\)$/\t\tCharacterBuilder.build(self, data)/' scripts/battle/battle_actor.gd
grep -oE 'CharacterBuilder\.(tint_mesh|tint|build)\(' scripts/battle/battle_actor.gd | sort | uniq -c
grep -nE 'SKELETON_PATH|FOG_AURA_ALPHA|ANIM_PLAYER_PATH|STICK_(COLOR|RADIUS|LENGTH|CENTER)|_build_character|_add_hair|_add_mummy|_hang_on|\b_tint' scripts/battle/battle_actor.gd; echo "leftovers done"
```

Expected:

```
      1 CharacterBuilder.build(
      2 CharacterBuilder.tint(
      4 CharacterBuilder.tint_mesh(
leftovers done
```

(three `tint_mesh` calls in `set_equipment()` plus its comment "Drop the previous tint first, or CharacterBuilder.tint_mesh() would multiply onto it.")

With the Edit tool in `scripts/battle/battle_actor.gd`, insert right under `set_devourer` (above the `add_mesh` comment):

```gdscript
## Builders only: the imported KayKit model (its hand slots hold the equipment meshes).
func set_model(model: Node3D) -> void:
	_model = model


## Builders only: the aura ball of the Señor de la Niebla and the Eco (play_phase() swells it).
func set_aura(aura: MeshInstance3D) -> void:
	_aura = aura


## Builders only: the model's AnimationPlayer and the role -> clip table it plays.
func set_animations(player: AnimationPlayer, anims: Dictionary) -> void:
	_anim = player
	_anims = anims


```

Replace the header comment of `scripts/battle/battle_actor.gd` (every `##` line between `class_name BattleActor extends Node3D` and the empty line before `## Every figure a BattleActor can be`) with:

```gdscript
## 3D figure of a fighter or a villager, alive: its animations (play_*), the floating
## numbers, the hero's equipment (set_equipment(), the Yelmo's horns), the flash, the
## highlight and the see-through of the map. What it looks like is data in ActorLooks
## (look, set before add_child); its meshes are built by CharacterBuilder (the KayKit
## models) or CreatureBuilder (the figures built in code), which write into it only through
## its builder methods (body(), add_mesh(), add_blob(), add_ghost(), add_wing(), set_sway(),
## set_jaw(), set_hover(), set_devourer(), set_model(), set_aura(), set_animations()).
## The figure faces -Z, so look_at() the opponent. Every play_* can be awaited: it returns
## when its animation and its tween are done.
```

Then:

```bash
wc -l scripts/battle/battle_actor.gd scripts/battle/actor_looks.gd scripts/battle/creature_builder.gd scripts/battle/character_builder.gd
```

Expected: `battle_actor.gd` under 900 lines (about 740), `actor_looks.gd` about 820, `creature_builder.gd` about 770, `character_builder.gd` about 175.

- [ ] **Step 4: Verify**

Run H0; H1 on `scripts/battle/character_builder.gd`, `scripts/battle/creature_builder.gd`, `scripts/battle/actor_looks.gd` and `scripts/battle/battle_actor.gd`; H2; H3; H4. H2 shows the KayKit figures that matter here (the hero with his gear and helmet, the Jefe de caravana and the caravan people with their heads, hair and capes, the companion); H4 covers the skeletons, `FOG_LORD`, `FOG_ECHO`, `MUMMY`, `HOLLOW_ARMOR`, `SENTINEL` and `CITY_GUARDIAN` with their weapons, auras, wraps and embers. Both must look unchanged.

Then the Eco run (a KayKit boss with an aura, the platinum hero, the Yelmo put on in battle) against the reference:

```bash
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --fixed-fps 10 --quit-after 40000 -- --autoplay --autoplay-zone=eco > C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/eco.log 2>&1
grep -E '^Eco de la Niebla' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/eco.log | head -3
grep -E '^Eco de la Niebla' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/eco.log | head -3
grep -E 'ERROR|WARNING' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/eco.log; echo "grep done"
```

Expected: both print `Eco de la Niebla: victoria (...)` / `derrota (...)` lines (the counts vary with chance; the new run must print such lines), and `grep done` with at most the known Jolt warning.

- [ ] **Step 5: Update `CLAUDE.md`**

In the `BattleActor` entry:
- replace `` `set_devourer()`. `` (end of the builder methods sentence) with `` `set_devourer()`, `set_model()`, `set_aura()`, `set_animations()`. ``;
- replace `(\`hair\` {style beard / bun / tail, color}, \`_add_hair()\`)` with `(\`hair\` {style beard / bun / tail, color}, built by \`CharacterBuilder\`)`;
- replace `(linen wraps built on the bones, \`_add_mummy_wraps()\`)` with `(linen wraps built on the bones by \`CharacterBuilder\`)`;
- replace `(the weapon and the shield tinted with \`Equipment.tint()\`:` with `(the weapon and the shield tinted with \`Equipment.tint()\` through \`CharacterBuilder.tint()\` / \`tint_mesh()\`:`.

Add this entry right after the `CreatureBuilder` entry:

```
- `scripts/battle/character_builder.gd` (`CharacterBuilder`, `RefCounted`, builder, M-72) — the `BattleActor` figures that are KayKit models, from their `ActorLooks.LOOKS` entry: `build(actor, data)` (called by `BattleActor._ready()` for every look with a `scene`: the model turned to face -Z with its `hide` props hidden, the skeletons' weapons on `BoneAttachment3D`s of their hand bones (`SKELETON_PATH`), `tint` / `mesh_tints`, the Armadura hueca's ember (`neck_glow`), the Momia's wraps (`_add_mummy_wraps()`, `_hang_on_bone()`), `head_texture`, the cape (`cape` / `hide_cape`), the hair pieces (`_add_hair()`), an `aura` ball (`FOG_AURA_ALPHA`), the hero's wooden stick (`STICK_*`) and the looping idle and walk clips of `ANIM_PLAYER_PATH`), and `tint(model, color)` / `tint_mesh(mi, color)` (copies of the imported materials with the albedo multiplied; `BattleActor.set_equipment()` uses them too). Static, no state: it writes into the actor only through `actor.set_model()`, `set_aura()`, `set_animations()`, `add_mesh()`, `add_blob()`, `add_ghost()` and `set_equipment()`.
```

In *Conventions*, the line plan 1 wrote about the three kinds of script names the builders: run `grep -n 'CreatureBuilder' CLAUDE.md`. If none of its matches is in the *Conventions* section, add `` `CreatureBuilder`, `CharacterBuilder` `` to the list of builder classes in that line (after `UiStyle`).

- [ ] **Step 6: Commit**

```bash
git add scripts/battle/character_builder.gd scripts/battle/character_builder.gd.uid scripts/battle/battle_actor.gd CLAUDE.md
git commit -m "Move the KayKit figures from BattleActor into CharacterBuilder"
```

---

### Task 6: Whole-game check, master document and merge

**Files:**
- Modify: `docs/boost/documento-maestro.md`

**Interfaces:**
- Consumes: Tasks 1-5.
- Produces: M-72 marked `hecho`; `feature/refactor-2-battle-actor` merged into `develop`.

- [ ] **Step 1: The v1 and the v2 on autoplay against the reference**

```bash
cd /c/Users/peixe/Documents/rpg-turnos
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --fixed-fps 10 --quit-after 150000 -- --autoplay > C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/v1.log 2>&1
APPDATA="C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor" ./tools/godot.cmd --headless --path . --fixed-fps 10 --quit-after 500000 -- --autoplay --autoplay-zone=caravana > C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/v2.log 2>&1
M='^(Zona|Escena|Lugar|Compañero|Pregunta|Misión cumplida|Juego completado|Medallas|Eco de la Niebla)'
for run in v1 v2; do
  grep -E "$M" C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/$run.log | grep -vE '^(Misión cumplida|Juego completado)' > C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/$run-ref-m.txt
  grep -E "$M" C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/$run.log | grep -vE '^(Misión cumplida|Juego completado)' > C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/$run-new-m.txt
  diff C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/$run-ref-m.txt C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/$run-new-m.txt && echo "$run SAME"
  grep -E '^Juego completado' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/ref/$run.log C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/$run.log
  grep -E 'ERROR|WARNING' C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2/$run.log; echo "$run grep done"
done
```

(The v1 takes a few minutes, the v2 about 20. The milestones are compared without `Misión cumplida` lines, whose number and order depend on chance, as the guide allows; look at those two lists by eye.)

Expected: `v1 SAME` and `v2 SAME` (a `Lugar:` or `Zona:` line repeated or missing after a defeat is chance, not a regression: check it against the reference by eye); the `Juego completado:` lines of each pair at the same level (v1: Nv 18; v2: Nv 40) with play times within about 5 minutes of each other; each `grep done` with at most the known Jolt warning before it.

- [ ] **Step 2: Mark M-72 done in the master document**

In `docs/boost/documento-maestro.md`, the refactor row is either still the single row `| Sin versión · M-70 a M-74 | ... | spec |` or (after plan 1) split per M-id.

- If an `M-72` row exists, change its state cell from `spec` to `hecho` and add ` · [plan](plans/2026-11-14-refactor-2-battle-actor.md)` before the closing `)` of its links.
- If the single row `M-70 a M-74` is still there, replace it with these rows (M-73 and M-74 marked as plan 1 left them: `hecho` if plan 1 is merged, which Task 1 Step 1 confirmed):

```
| Sin versión · M-70 | Refactor de arquitectura: trocear `Game` ([spec](specs/2026-11-14-refactor-arquitectura-design.md) · [guía](specs/2026-11-14-refactor-arquitectura-guia.md)) | spec |
| Sin versión · M-71 | Refactor de arquitectura: trocear `World` ([spec](specs/2026-11-14-refactor-arquitectura-design.md) · [guía](specs/2026-11-14-refactor-arquitectura-guia.md)) | spec |
| Sin versión · M-72 | Refactor de arquitectura: `BattleActor` troceado en `ActorLooks`, `CreatureBuilder`, `CharacterBuilder` y las primitivas de `LowPoly` ([spec](specs/2026-11-14-refactor-arquitectura-design.md) · [guía](specs/2026-11-14-refactor-arquitectura-guia.md) · [plan](plans/2026-11-14-refactor-2-battle-actor.md)) | hecho |
| Sin versión · M-73 | Refactor de arquitectura: cabeceras `## Constructor:` y las tres clases de script en `CLAUDE.md` ([spec](specs/2026-11-14-refactor-arquitectura-design.md) · [plan](plans/2026-11-14-refactor-1-runflags-builders.md)) | hecho |
| Sin versión · M-74 | Refactor de arquitectura: `RunFlags` y las regiones de autoplay ([spec](specs/2026-11-14-refactor-arquitectura-design.md) · [plan](plans/2026-11-14-refactor-1-runflags-builders.md)) | hecho |
```

- [ ] **Step 3: Commit and merge**

```bash
git add docs/boost/documento-maestro.md
git commit -m "Mark M-72 (BattleActor split) done in the master document"
git checkout develop
git merge --no-ff feature/refactor-2-battle-actor -m "Merge feature/refactor-2-battle-actor into develop"
git log --oneline -8
```

Expected: the merge commit on top of the six commits of this plan (Tasks 1-6). Do not push.

- [ ] **Step 4: Free the scratch space**

```bash
rm -rf C:/Users/peixe/AppData/Local/Temp/villaclaro-refactor/plan2
```

Keep plan 1's whole `ref/` folder: plans 3 and 4 compare against it.
