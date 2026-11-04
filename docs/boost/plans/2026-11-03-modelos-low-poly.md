# Modelos low-poly Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the primitive meshes with low-poly models: the hero and the old woman become animated KayKit characters, the slimes become faceted low-poly blobs with eyes (the Rey Slime with a gold crown), and the village, rocks, new trees and new bushes use low-poly models on the map and in battle.

**Architecture:** `BattleActor` keeps its public API (`Look` enum, `play_*` coroutines, `reset()`, faces −Z, `look` set before `add_child`) but builds itself from a `LOOKS` table: characters instance a KayKit `.glb`, hide the props they do not use and drive its `AnimationPlayer`; slimes are built in code with the new `LowPoly.blob()` (flat-shaded lathe). Tweens that still make sense (lunge, knockback, flash, numbers, fire ball, heal) stay. `Player` swaps its bob for `set_walking()`. `BattleStage` gains the shared model helpers and rock / tree tables; `WorldStage` places the Medieval Hexagon houses, well, rocks and seeded trees with hand-made colliders, plus procedural bushes. Trees and bushes are `MultiMesh`es.

**Tech Stack:** Godot 4.7.2, GDScript, Compatibility renderer (web build), Jolt physics, KayKit CC0 models (`.glb` / `.gltf`).

**Spec:** `docs/boost/specs/2026-11-03-modelos-low-poly-design.md`

## Global Constraints

- **No tests of any kind**, at any point: no `tests/` folder, no test scripts, no GUT or gdUnit4. Verify by hand: `--check-only`, runs, Godot output, recorded frames.
- **Commit messages** never mention Claude: no `Co-Authored-By`, no "Generated with", no attribution of any kind.
- **Branch:** `feature/modelos-low-poly` (already checked out). Never commit to `main` or `develop`. Never push.
- **Scenes:** `.tscn` files only hold the root node and its script; every other node is created in code.
- **Renderer:** Compatibility; everything must run in the web export.
- **Godot:** use `.\tools\godot.cmd` (`godot` is not on PATH). Run commands from the repo root in PowerShell. When saving Godot output to a file, let `cmd /c "... > file 2>&1"` do the redirection (PowerShell 5.1 wraps native stderr in error records) and search it with `Select-String -CaseSensitive` for `ERROR|WARNING`.
- **Assets:** only the files listed in Task 1 go into `assets/`; the packs stay in `assets_src/` (git-ignored, `.gdignore`).
- **Character models:** `res://assets/characters/Knight.glb` (hero), `res://assets/characters/Mage.glb` (old woman). Scale `0.65` (rig is 2.47 units tall with helmet → hero 1.6 m). Rotated `PI` around Y (KayKit faces +Z; `BattleActor` faces −Z). AnimationPlayer path inside the model: `AnimationPlayer` (its `root_node` is `..`, the model root). Imported animations do not loop: `Idle` and the walk animation are set to `Animation.LOOP_LINEAR` in code.
- **Animations (both characters):** idle `Idle`, walk `Running_A`, attack `1H_Melee_Attack_Slice_Diagonal`, cast `Spellcast_Shoot`, hit `Hit_A`, dodge `Dodge_Backward`, death `Death_A`, cheer `Cheer`. One-shots play at speed `1.3`; walk at `1.8`; blend `0.15` s.
- **Hidden props, Knight:** `Rig/Skeleton3D/handslot_l/1H_Sword_Offhand`, `.../handslot_l/Badge_Shield`, `.../handslot_l/Rectangle_Shield`, `.../handslot_l/Spike_Shield`, `Rig/Skeleton3D/handslot_r/2H_Sword`. Visible: `handslot_r/1H_Sword`, `handslot_l/Round_Shield`, helmet and cape.
- **Hidden props, Mage:** `Rig/Skeleton3D/handslot_l/Spellbook`, `.../handslot_l/Spellbook_open`, `Rig/Skeleton3D/handslot_r/1H_Wand`. Visible: `handslot_r/2H_Staff`, hat and cape.
- **Slimes:** `LowPoly.blob(SLIME_PROFILE, 9)` (0.98 m tall, 1.24 m wide), flat normals, eyes and pupils in front (−Z). Slime purple `Color(0.55, 0.3, 0.85)` scale 1.0; Rey Slime blue `Color(0.3, 0.45, 0.9)` scale 1.6 with a gold crown (band + 5 spikes). Slimes keep the squash bounce as idle.
- **Buildings:** `building_home_A_red` (west house), `building_home_B_red` (east house), `building_well_red`, scale `3.5`. Door on the model's +Z side; house yaws stay 60° / −60°.
- **Rocks:** `rock_single_A`–`E`, scales 4–10 (see tables). Footprint radii at scale 1: `[0.15, 0.145, 0.175, 0.145, 0.245]`.
- **Trees:** `tree_single_A`, `tree_single_B`, `trees_A_medium` (clump), scale 3.6–4.4 (map) / 3.8–4.5 (battle).
- **Map trees:** seed `23`, 600 tries over ±36 m, keep chance from `0.05` (within 8 m of the centre) rising to `1.0` at 30 m; ≥ 3.2 m apart; ≥ 3 m off the path / clearing / spawn, ≥ 2.5 m off `Player.AUTOPLAY_ROUTE`, ≥ 1.5 m off rocks; clumps beyond 27 m. Colliders only inside the walls: cylinder radius 0.35 (single) / 2.0 (clump), 3 m tall.
- **Map bushes:** seed `31`, 220 tries over ±30 m, scale 0.7–1.2, ≥ 0.8 m off the path, ≥ 0.6 m off rocks, no collider. Bush = `LowPoly.blob(BUSH_PROFILE, 7)`, 1 m tall, `Color(0.18, 0.4, 0.12)`.
- **Colliders:** box fitted to the mesh AABB × scale for houses, well and rocks (on a `StaticBody3D` turned by the yaw).
- **Web export growth:** < 15 MB (measured in a trial: `index.pck` 121 008 B → 2 882 760 B).
- **Known noise:** one `WARNING: Jolt Physics job system exceeded the maximum number of jobs` in windowed `--fixed-fps` runs is harmless. Any other ERROR or WARNING is a real problem.

## File map

| File | Change |
|---|---|
| `assets/characters/` | New: `Knight.glb`, `Mage.glb` and the textures Godot extracts from them (`Knight_knight_texture.png`, `Mage_mage_texture.png`), with `.import` files |
| `assets/medieval/` | New: houses, well, rocks A–E, trees (`.gltf` + `.bin`) and the shared `hexagons_medieval.png`, with `.import` files |
| `assets/CREDITS.md` | New: packs, author, links, licence |
| `scripts/battle/low_poly.gd` | New `LowPoly`: faceted blob meshes, bush mesh, MultiMesh helper |
| `scripts/battle/battle_actor.gd` | Rewritten: `LOOKS` table, KayKit models with animations, low-poly slimes, `set_walking()`, `play_cheer()` |
| `scripts/battle/battle_scene.gd` | Hero cheers on victory |
| `scripts/world/player.gd` | Walk / idle animations instead of the bob |
| `scripts/battle/battle_stage.gd` | Rewritten: model rocks, trees and bushes; shared `ROCK_SCENES`, `TREE_SCENES`, `add_model()`, `scene_mesh()`, `model_aabb()`, `rock_radius()` |
| `scripts/world/world_stage.gd` | Rewritten: model houses, well and rocks with box colliders, seeded trees and bushes |
| `CLAUDE.md` | Layout updates |

---

### Task 1: Low-poly assets in the repository, with credits

**Files:**
- Create: `assets/characters/*`, `assets/medieval/*` (copied from `assets_src/`)
- Create: `assets/CREDITS.md`

**Interfaces:**
- Consumes: the packs in `assets_src/`.
- Produces (resource paths used by later tasks):
  - `res://assets/characters/Knight.glb`, `res://assets/characters/Mage.glb`
  - `res://assets/medieval/building_home_A_red.gltf`, `building_home_B_red.gltf`, `building_well_red.gltf`
  - `res://assets/medieval/rock_single_A.gltf` … `rock_single_E.gltf`
  - `res://assets/medieval/tree_single_A.gltf`, `tree_single_B.gltf`, `trees_A_medium.gltf`

- [ ] **Step 1: Make sure exactly these files are in `assets/`**

They may already be there (copied while writing this plan). Running the copy again is harmless:

```powershell
$adv = "assets_src\KayKit-Character-Pack-Adventures-1.0\addons\kaykit_character_pack_adventures\Characters\gltf"
$hex = "assets_src\KayKit-Medieval-Hexagon-Pack-1.0\addons\kaykit_medieval_hexagon_pack\Assets\gltf"
New-Item -ItemType Directory -Force assets\characters, assets\medieval | Out-Null
Copy-Item "$adv\Knight.glb", "$adv\Mage.glb" assets\characters\
foreach ($n in "building_home_A_red", "building_home_B_red", "building_well_red") {
    Copy-Item "$hex\buildings\red\$n.gltf", "$hex\buildings\red\$n.bin" assets\medieval\
}
foreach ($n in "rock_single_A", "rock_single_B", "rock_single_C", "rock_single_D", "rock_single_E",
               "tree_single_A", "tree_single_B", "trees_A_medium") {
    Copy-Item "$hex\decoration\nature\$n.gltf", "$hex\decoration\nature\$n.bin" assets\medieval\
}
Copy-Item "$hex\decoration\nature\hexagons_medieval.png" assets\medieval\
```

If `assets\medieval` holds `trees_A_small.*` or `trees_B_small.*` from an earlier copy, delete them (bushes are procedural, those models are not used).

- [ ] **Step 2: Import**

```powershell
.\tools\godot.cmd --headless --path . --import
```

Expected: ends with `[ DONE ] reimport` and no `ERROR`. Godot extracts the textures embedded in the `.glb` files as `assets\characters\Knight_knight_texture.png` and `assets\characters\Mage_mage_texture.png` (they must be committed, the `.glb` imports reference them).

- [ ] **Step 3: Check the file list**

```powershell
Get-ChildItem assets -Recurse -File | Where-Object { $_.Extension -ne ".import" } | Select-Object -ExpandProperty Name
```

Expected (24 names, any order): `Knight.glb`, `Knight_knight_texture.png`, `Mage.glb`, `Mage_mage_texture.png`, `building_home_A_red.bin`, `building_home_A_red.gltf`, `building_home_B_red.bin`, `building_home_B_red.gltf`, `building_well_red.bin`, `building_well_red.gltf`, `hexagons_medieval.png`, `rock_single_A.bin` … `rock_single_E.gltf` (10 files), `tree_single_A.bin`, `tree_single_A.gltf`, `tree_single_B.bin`, `tree_single_B.gltf`, `trees_A_medium.bin`, `trees_A_medium.gltf`. About 7.4 MB on disk (the two `.glb` are 3.6 MB each, mostly animations).

- [ ] **Step 4: Write `assets/CREDITS.md`**

```markdown
# Credits

Every model in this folder is a copy of a file from a free asset pack, unchanged. All
packs are CC0 (public domain): they can be used in a commercial game without asking or
crediting, but the author deserves the thanks.

| Pack | Author | Link | Licence | Files used |
|---|---|---|---|---|
| KayKit – Adventurers Character Pack 1.0 | Kay Lousberg (www.kaylousberg.com) | https://github.com/KayKit-Game-Assets/KayKit-Character-Pack-Adventures-1.0 | CC0 1.0 | `characters/Knight.glb`, `characters/Mage.glb` (and the textures Godot extracts from them) |
| KayKit – Medieval Hexagon Pack 1.0 | Kay Lousberg (www.kaylousberg.com) | https://github.com/KayKit-Game-Assets/KayKit-Medieval-Hexagon-Pack-1.0 | CC0 1.0 | `medieval/building_home_A_red`, `building_home_B_red`, `building_well_red`, `rock_single_A`–`E`, `tree_single_A`, `tree_single_B`, `trees_A_medium`, `hexagons_medieval.png` |

KayKit – Skeletons Character Pack 1.0 (same author, CC0,
https://github.com/KayKit-Game-Assets/KayKit-Character-Pack-Skeletons-1.0) is downloaded
in `assets_src/` for the enemies of later phases; it gets a row here when one of its
models is copied in.

The slimes, the Rey Slime's crown and the bushes are built in code (`LowPoly`).
```

- [ ] **Step 5: Commit**

```powershell
git add .gitignore assets docs/boost/specs/2026-11-03-modelos-low-poly-design.md docs/boost/plans/2026-11-03-modelos-low-poly.md
git status --short
git commit -m "Add the KayKit low-poly models in use, with credits"
```

Expected `git status --short` before the commit: only `A` lines for `.gitignore`, `assets/...`, the spec and this plan (no `assets_src/`).

---

### Task 2: Animated characters and low-poly slimes

**Files:**
- Create: `scripts/battle/low_poly.gd`
- Modify (rewrite): `scripts/battle/battle_actor.gd`
- Modify: `scripts/battle/battle_scene.gd`
- Modify: `scripts/world/player.gd`

**Interfaces:**
- Consumes: Task 1 resource paths.
- Produces:
  - `LowPoly` (`RefCounted`): `static func blob(profile: Array[Vector2], segments: int) -> ArrayMesh`, `static func bush_mesh() -> ArrayMesh`, `static func add_multimesh(root: Node3D, mesh: Mesh, transforms: Array[Transform3D]) -> void`, `const BUSH_PROFILE`, `BUSH_SEGMENTS`, `BUSH_COLOR`.
  - `BattleActor`: unchanged `enum Look { HERO, SLIME, VILLAGER, KING_SLIME }`, `FIRE_COLOR`, `HEAL_COLOR`, `GOLD`, `@export var look`, `reset()`, `play_attack(target_pos: Vector3)`, `play_hit(amount: int, crit: bool)`, `play_dodge()`, `play_defeat()`, `play_cast(color := FIRE_COLOR)`, `play_burn(amount: int, color := FIRE_COLOR)`, `play_heal(amount: int)`, `play_stagger()` (all awaitable). New: `set_walking(on: bool) -> void`, `play_cheer() -> void` (awaitable), `const LOOKS`, `CHARACTER_ANIMS`, `SLIME_PROFILE`.
  - Behaviour change: a defeated character plays `Death_A` and stays lying down (not hidden); defeated slimes still fade and hide.

- [ ] **Step 1: Create `scripts/battle/low_poly.gd`**

```gdscript
class_name LowPoly extends RefCounted
## Faceted low-poly meshes built in code and a MultiMesh helper. A blob is a lathe of
## rings taken from a side profile, every other ring turned half a segment, with one
## normal per face (flat shading), so it reads as a cut gem instead of a smooth
## sphere. The slimes and the bushes are blobs.

## Side profile of a bush (x = radius, y = height in metres), bottom to top.
const BUSH_PROFILE: Array[Vector2] = [
	Vector2(0.0, 0.0), Vector2(0.5, 0.0), Vector2(0.7, 0.3), Vector2(0.62, 0.62),
	Vector2(0.34, 0.88), Vector2(0.0, 1.0),
]
const BUSH_SEGMENTS := 7
const BUSH_COLOR := Color(0.18, 0.4, 0.12)


## Lathe of profile around +Y with segments sides and flat normals.
static func blob(profile: Array[Vector2], segments: int) -> ArrayMesh:
	var rings: Array[PackedVector3Array] = []
	for i in profile.size():
		var ring := PackedVector3Array()
		var offset := 0.5 * (i % 2)
		for s in segments:
			var angle := TAU * (s + offset) / segments
			ring.append(Vector3(sin(angle) * profile[i].x, profile[i].y,
				cos(angle) * profile[i].x))
		rings.append(ring)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Smooth group 0xFFFFFFFF: no vertex is shared, every face keeps its own normal.
	st.set_smooth_group(0xFFFFFFFF)
	for i in rings.size() - 1:
		var lo := rings[i]
		var hi := rings[i + 1]
		for s in segments:
			var n := (s + 1) % segments
			_triangle(st, lo[s], hi[s], lo[n])
			_triangle(st, lo[n], hi[s], hi[n])
	st.generate_normals()
	return st.commit()


## A green bush blob 1 m tall with its material on the surface (ready for a MultiMesh).
static func bush_mesh() -> ArrayMesh:
	var mesh := blob(BUSH_PROFILE, BUSH_SEGMENTS)
	var material := StandardMaterial3D.new()
	material.albedo_color = BUSH_COLOR
	material.roughness = 1.0
	mesh.surface_set_material(0, material)
	return mesh


## One MultiMeshInstance3D drawing mesh (with its own surface materials) at every
## transform. Does nothing for an empty list.
static func add_multimesh(root: Node3D, mesh: Mesh, transforms: Array[Transform3D]) -> void:
	if transforms.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	root.add_child(mmi)


## Skips triangles that collapse at the profile's tips (radius 0).
static func _triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	if a.is_equal_approx(b) or b.is_equal_approx(c) or a.is_equal_approx(c):
		return
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)
```

- [ ] **Step 2: Rewrite `scripts/battle/battle_actor.gd`**

Replace the whole file with:

```gdscript
class_name BattleActor extends Node3D
## 3D figure of a fighter or a villager. The hero and the old woman are KayKit models
## with their own animations; the slimes are faceted low-poly blobs built in code (see
## LOOKS). Set look before add_child. The figure faces -Z, so look_at() the opponent.
## Every play_* can be awaited: it returns when its animation and its tween are done.

enum Look { HERO, SLIME, VILLAGER, KING_SLIME }

const FIRE_COLOR := Color(1.0, 0.45, 0.1)
const HEAL_COLOR := Color(0.3, 1.0, 0.4)
const GOLD := Color(1.0, 0.8, 0.2)
const KNIGHT := preload("res://assets/characters/Knight.glb")
const MAGE := preload("res://assets/characters/Mage.glb")
## KayKit characters are 2.47 units tall (helmet included); 0.65 makes the hero 1.6 m.
const CHARACTER_SCALE := 0.65
## The AnimationPlayer inside a KayKit character scene.
const ANIM_PLAYER_PATH := "AnimationPlayer"
const BLEND_TIME := 0.15
## One-shot animations (attack, spell, hit, dodge, death, cheer) play this much faster.
const ACTION_SPEED := 1.3
## The run cycle covers ~1 m/s at this scale; sped up so the feet keep closer pace with
## the 5 m/s of the map.
const WALK_SPEED := 1.8
## Strength of the additive flash on hits, spells and heals.
const FLASH_ALPHA := 0.6
## Animation played for each role, the same for both KayKit characters.
const CHARACTER_ANIMS := {
	"idle": "Idle",
	"walk": "Running_A",
	"attack": "1H_Melee_Attack_Slice_Diagonal",
	"cast": "Spellcast_Shoot",
	"hit": "Hit_A",
	"dodge": "Dodge_Backward",
	"death": "Death_A",
	"cheer": "Cheer",
}
## Side profile of a slime (x = radius, y = height), bottom to top: a drop with a tip.
const SLIME_PROFILE: Array[Vector2] = [
	Vector2(0.0, 0.0), Vector2(0.48, 0.0), Vector2(0.62, 0.18), Vector2(0.58, 0.42),
	Vector2(0.44, 0.64), Vector2(0.24, 0.8), Vector2(0.08, 0.9), Vector2(0.0, 0.98),
]
const SLIME_SEGMENTS := 9
## Everything that changes between looks. Characters: scene, scale, top (height of the
## damage numbers), hide (prop nodes of the model to hide) and anims. Slimes: color,
## scale (the whole blob, eyes and crown included), top and crown.
const LOOKS := {
	Look.HERO: {
		"scene": KNIGHT,
		"scale": CHARACTER_SCALE,
		"top": 1.9,
		"hide": [
			"Rig/Skeleton3D/handslot_l/1H_Sword_Offhand",
			"Rig/Skeleton3D/handslot_l/Badge_Shield",
			"Rig/Skeleton3D/handslot_l/Rectangle_Shield",
			"Rig/Skeleton3D/handslot_l/Spike_Shield",
			"Rig/Skeleton3D/handslot_r/2H_Sword",
		],
		"anims": CHARACTER_ANIMS,
	},
	Look.VILLAGER: {
		"scene": MAGE,
		"scale": CHARACTER_SCALE,
		"top": 2.2,
		"hide": [
			"Rig/Skeleton3D/handslot_l/Spellbook",
			"Rig/Skeleton3D/handslot_l/Spellbook_open",
			"Rig/Skeleton3D/handslot_r/1H_Wand",
		],
		"anims": CHARACTER_ANIMS,
	},
	Look.SLIME: {
		"color": Color(0.55, 0.3, 0.85),
		"scale": 1.0,
		"top": 1.3,
		"crown": false,
	},
	Look.KING_SLIME: {
		"color": Color(0.3, 0.45, 0.9),
		"scale": 1.6,
		"top": 2.1,
		"crown": true,
	},
}

@export var look := Look.HERO

## Height of the floating damage numbers.
var _top := 2.0
## Visual root moved and scaled by the tweens; the actor node itself stays put.
var _body: Node3D
## Every mesh of the figure, for the flash overlay.
var _meshes: Array[MeshInstance3D] = []
## Slime materials only (faded on defeat); the KayKit materials are left as imported.
var _materials: Array[StandardMaterial3D] = []
var _flash: StandardMaterial3D
## Characters only; null for slimes.
var _anim: AnimationPlayer
var _anims: Dictionary = {}
var _idle_tween: Tween


func _ready() -> void:
	_body = Node3D.new()
	add_child(_body)
	var data: Dictionary = LOOKS[look]
	_top = data.top
	if data.has("scene"):
		_build_character(data)
	else:
		_build_slime(data)
	for node in _body.find_children("*", "MeshInstance3D", true, false):
		_meshes.append(node as MeshInstance3D)
	_flash = StandardMaterial3D.new()
	_flash.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_flash.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_flash.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	reset()


## Back to the starting pose: visible, opaque, no flash, idle animation running.
func reset() -> void:
	show()
	_body.position = Vector3.ZERO
	_body.rotation = Vector3.ZERO
	_body.scale = Vector3.ONE
	_set_flash(false)
	for mat in _materials:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
		mat.albedo_color.a = 1.0
	if _anim:
		_anim.play(_anims.idle, 0.0)
	else:
		_start_bounce()


## Map only: the walk (run) cycle while on is true, else the idle one. Slimes ignore it.
func set_walking(on: bool) -> void:
	if _anim == null:
		return
	var anim_name: String = _anims.walk if on else _anims.idle
	if _anim.current_animation != anim_name:
		_anim.play(anim_name, BLEND_TIME, WALK_SPEED if on else 1.0)


## Swings (characters) and lunges toward the target and steps back.
func play_attack(target_pos: Vector3) -> void:
	var timer := _start("attack")
	var base := global_position
	var dir := target_pos - base
	dir.y = 0.0
	var lunge := dir.normalized() * minf(1.2, dir.length() * 0.4)
	var t := create_tween()
	if timer:
		t.tween_interval(0.15)  # the swing winds up before the step
	t.tween_property(_body, "global_position", base + lunge, 0.15) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(_body, "global_position", base, 0.2) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await t.finished
	await _end(timer)


## Hit animation, white flash, small knockback and a floating damage number.
func play_hit(amount: int, crit: bool) -> void:
	_spawn_number(amount, crit)
	var timer := _start("hit")
	var base := global_position
	var knockback := global_basis.z.normalized() * (0.5 if crit else 0.3)
	_set_flash(true)
	var t := create_tween()
	t.tween_property(_body, "global_position", base + knockback, 0.08)
	t.tween_callback(_set_flash.bind(false))
	t.tween_property(_body, "global_position", base, 0.15)
	await t.finished
	await _end(timer)


## Jumps back when an attack misses.
func play_dodge() -> void:
	var timer := _start("dodge")
	var base := global_position
	var back := global_basis.z.normalized() * 0.6
	var t := create_tween()
	t.tween_property(_body, "global_position", base + back, 0.1) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(_body, "global_position", base, 0.15)
	await t.finished
	await _end(timer)


## Characters fall with the death animation and stay down. Slimes squash, shrink and
## fade out, then hide.
func play_defeat() -> void:
	if _anim:
		var timer := _start("death")
		await timer.timeout
		return
	if _idle_tween:
		_idle_tween.kill()
	for mat in _materials:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var t := create_tween()
	t.tween_property(_body, "scale", Vector3(1.25, 0.3, 1.25), 0.2)
	t.tween_property(_body, "scale", Vector3(0.05, 0.05, 0.05), 0.35)
	t.parallel().tween_method(_set_alpha, 1.0, 0.0, 0.35)
	await t.finished
	hide()


## Glow in the spell's color with the cast animation (characters) or a small hop
## (slimes), before a spell.
func play_cast(color := FIRE_COLOR) -> void:
	_set_flash(true, color)
	var timer := _start("cast")
	if timer:
		await timer.timeout
	else:
		await _hop()
	_set_flash(false)
	await _end(timer)


## A ball in the spell's color grows on the actor and fades while the hit plays.
func play_burn(amount: int, color := FIRE_COLOR) -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	var ball := MeshInstance3D.new()
	ball.mesh = _sphere(0.5)
	ball.material_override = mat
	ball.position = Vector3(0, _top * 0.45, 0)
	ball.scale = Vector3.ONE * 0.2
	add_child(ball)
	var t := create_tween()
	t.tween_property(ball, "scale", Vector3.ONE * 1.6, 0.3) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.3).set_delay(0.1)
	t.tween_callback(ball.queue_free)
	await play_hit(amount, false)
	if t.is_running():
		await t.finished


## Green glow and a green number going up.
func play_heal(amount: int) -> void:
	_spawn_number(amount, false, HEAL_COLOR)
	_set_flash(true, HEAL_COLOR)
	await get_tree().create_timer(0.35).timeout
	_set_flash(false)


## Wobbles side to side, for a fighter that loses its turn.
func play_stagger() -> void:
	var t := create_tween()
	for angle in [12.0, -12.0, 8.0, 0.0]:
		t.tween_property(_body, "rotation_degrees:z", angle, 0.1)
	await t.finished


## Celebrates a victory: the cheer animation (characters) or a hop (slimes).
func play_cheer() -> void:
	var timer := _start("cheer")
	if timer == null:
		await _hop()
	await _end(timer)


func _build_character(data: Dictionary) -> void:
	var model: Node3D = (data.scene as PackedScene).instantiate()
	model.scale = Vector3.ONE * data.scale
	# KayKit characters face +Z; turned around they face -Z like every BattleActor.
	model.rotation.y = PI
	_body.add_child(model)
	for path in data.hide:
		(model.get_node(path) as Node3D).hide()
	_anims = data.anims
	_anim = model.get_node(ANIM_PLAYER_PATH) as AnimationPlayer
	# The imported animations do not loop; idle and walk must.
	for role in ["idle", "walk"]:
		_anim.get_animation(_anims[role]).loop_mode = Animation.LOOP_LINEAR


func _build_slime(data: Dictionary) -> void:
	var color: Color = data.color
	var blob := Node3D.new()
	blob.scale = Vector3.ONE * data.scale
	_body.add_child(blob)
	_add_mesh(blob, LowPoly.blob(SLIME_PROFILE, SLIME_SEGMENTS), color, Vector3.ZERO, 0.6)
	for x in [-0.2, 0.2]:
		_add_mesh(blob, _sphere(0.12), Color.WHITE, Vector3(x, 0.5, -0.44))  # eye
		_add_mesh(blob, _sphere(0.055), Color(0.05, 0.05, 0.05), Vector3(x, 0.5, -0.55))  # pupil
	if data.crown:
		var band := _cylinder(0.27, 0.14)
		band.top_radius = 0.22
		_add_mesh(blob, band, GOLD, Vector3(0, 0.86, 0), 0.4)
		for i in 5:
			var angle := TAU * i / 5.0
			_add_mesh(blob, _cone(0.06, 0.16), GOLD,
				Vector3(cos(angle) * 0.19, 1.01, sin(angle) * 0.19), 0.4)  # spike


## Squash-and-stretch loop of the slimes while they wait.
func _start_bounce() -> void:
	if _idle_tween:
		_idle_tween.kill()
	_idle_tween = create_tween().set_loops()
	_idle_tween.tween_property(_body, "scale", Vector3(1.08, 0.9, 1.08), 0.35) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_idle_tween.tween_property(_body, "scale", Vector3.ONE, 0.35) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _hop() -> void:
	var t := create_tween()
	t.tween_property(_body, "position:y", 0.35, 0.15) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(_body, "position:y", 0.0, 0.15) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await t.finished


## Plays the role's animation once at ACTION_SPEED and returns a timer that runs out
## when it ends; null for slimes, which have no animations.
func _start(role: String) -> SceneTreeTimer:
	if _anim == null:
		return null
	var anim_name: String = _anims[role]
	_anim.play(anim_name, BLEND_TIME, ACTION_SPEED)
	return get_tree().create_timer(_anim.get_animation(anim_name).length / ACTION_SPEED)


## Waits for a timer from _start() (if any) and goes back to the idle loop.
func _end(timer: SceneTreeTimer) -> void:
	if timer == null:
		return
	if timer.time_left > 0.0:
		await timer.timeout
	_anim.play(_anims.idle, BLEND_TIME)


func _spawn_number(amount: int, crit: bool, color := Color.WHITE) -> void:
	var label := Label3D.new()
	label.text = str(amount)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.pixel_size = 0.005
	label.font_size = 96 if crit else 64
	label.outline_size = 16
	label.modulate = Color(1.0, 0.85, 0.2) if crit else color
	label.position = Vector3(0, _top, 0)
	add_child(label)
	var t := label.create_tween().set_parallel()
	t.tween_property(label, "position:y", _top + 0.8, 0.9)
	t.tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.3)
	t.chain().tween_callback(label.queue_free)


## Additive overlay on every mesh, so it works on the imported materials too.
func _set_flash(on: bool, color := Color.WHITE) -> void:
	_flash.albedo_color = Color(color, FLASH_ALPHA)
	for mi in _meshes:
		mi.material_overlay = _flash if on else null


func _set_alpha(alpha: float) -> void:
	for mat in _materials:
		mat.albedo_color.a = alpha


func _add_mesh(parent: Node3D, mesh: Mesh, color: Color, pos: Vector3, \
		roughness := 0.8) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	_materials.append(mat)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)


static func _sphere(radius: float) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 10
	mesh.rings = 5
	return mesh


static func _cylinder(radius: float, height: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 8
	return mesh


static func _cone(radius: float, height: float) -> CylinderMesh:
	var mesh := _cylinder(radius, height)
	mesh.top_radius = 0.0
	return mesh
```

- [ ] **Step 3: The hero cheers on victory (`scripts/battle/battle_scene.gd`)**

In `_play_event()`, replace:

```gdscript
		BattleEvent.VICTORY:
			await _say("¡Has ganado! Obtienes %d EXP." % event.exp)
```

with:

```gdscript
		BattleEvent.VICTORY:
			_hero_actor.play_cheer()
			await _say("¡Has ganado! Obtienes %d EXP." % event.exp)
```

(`play_cheer()` is not awaited: the hero cheers while the message types.)

- [ ] **Step 4: Walk / idle animations instead of the bob (`scripts/world/player.gd`)**

1. Replace the doc comment lines

```gdscript
## tap on the ground; keys cancel it). Turns smoothly toward where it walks and bobs
## while moving. Its model is a BattleActor.
```

with

```gdscript
## tap on the ground; keys cancel it). Turns smoothly toward where it walks and plays
## the walk animation while moving, the idle one when stopped. Its model is a
## BattleActor.
```

2. Delete the two constants

```gdscript
const BOB_HEIGHT := 0.08
const BOB_TIME := 0.18
```

3. Delete the variable `var _bob_tween: Tween`.

4. At the end of `_physics_process()`, replace `_set_bobbing(dir != Vector3.ZERO)` with:

```gdscript
	_model.set_walking(dir != Vector3.ZERO)
```

5. Delete the whole `func _set_bobbing(on: bool) -> void:` function (the last function of the file) and the blank lines before it, so the file ends with `_route_direction()`.

- [ ] **Step 5: Refresh the class cache and validate the scripts**

```powershell
.\tools\godot.cmd --headless --path . --import
foreach ($s in "battle/low_poly", "battle/battle_actor", "battle/battle_scene", "world/player", "world/world") {
    .\tools\godot.cmd --headless --path . --check-only --script "res://scripts/$s.gd"
}
```

Expected: only the `Godot Engine v4.7.2...` banner for each script, no `SCRIPT ERROR` / `Parse Error`.

- [ ] **Step 6: Full headless autoplay**

```powershell
cmd /c ".\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 15000 -- --autoplay > build\autoplay.txt 2>&1"
Select-String -CaseSensitive -Path build\autoplay.txt -Pattern "ERROR|WARNING"
Select-String -Path build\autoplay.txt -Pattern "cumplida|Rey Slime ha sido derrotado"
```

Expected: the first `Select-String` prints nothing; the second prints `¡Rey Slime ha sido derrotado!` and `Misión cumplida`.

- [ ] **Step 7: Recorded frames (map and battle)**

```powershell
New-Item -ItemType Directory -Force build\frames | Out-Null
.\tools\godot.cmd --path . --write-movie build\frames\f.png --fixed-fps 10 --quit-after 900 -- --autoplay
```

Open frames with the Read tool (e.g. `build\frames\f00000020.png`, then every ~40 frames). Check:
- Map (first frames): the knight with helmet, red cape, sword and round shield only, running animation while moving, facing where he walks.
- First battle (starts roughly between frames 60 and 150; the HUD shows "PV" bar): the knight seen from behind facing the slime, the purple faceted slime with two eyes facing the hero and bouncing; the attack swing with the lunge, the spell cast pose with an orange glow, the hit flash and number on the slime, the slime squashing away when defeated, the hero cheering at "¡Has ganado!".
- Village (around frames 450-550, dialogue box "Anciana"): the old woman as the Mage with hat and staff only (no book, no wand), idle animation, facing south.

Then delete the frames:

```powershell
Remove-Item -Recurse -Force build\frames
```

- [ ] **Step 8: Commit**

```powershell
git add scripts/battle/low_poly.gd scripts/battle/battle_actor.gd scripts/battle/battle_scene.gd scripts/world/player.gd
git commit -m "Animate the hero and the old woman with KayKit models and make the slimes low-poly"
```

---

### Task 3: Low-poly village, rocks, trees and bushes on the map and in battle

**Files:**
- Modify (rewrite): `scripts/battle/battle_stage.gd`
- Modify (rewrite): `scripts/world/world_stage.gd`

**Interfaces:**
- Consumes: Task 1 resource paths; `LowPoly.add_multimesh()`, `LowPoly.bush_mesh()` (Task 2); `Player.AUTOPLAY_ROUTE` (existing); `Vegetation.build()` (existing).
- Produces:
  - `BattleStage`: `const ROCK_SCENES: Array[PackedScene]`, `ROCK_RADII: Array[float]`, `TREE_SCENES: Array[PackedScene]`, `ROCKS`, `TREES`, `BUSHES`; `static func add_model(root: Node3D, scene: PackedScene, pos: Vector3, scl: float, yaw_deg := 0.0) -> Node3D`, `static func scene_mesh(scene: PackedScene) -> Mesh`, `static func model_aabb(model: Node3D) -> AABB`, `static func rock_radius(rock: Array) -> float`. Kept: `GRASS`, `DIRT`, `HILL`, `HAZE`, `build()`, `build_environment()`, `add_mesh()`, `unit_sphere()`. Removed: `ROCK` (no longer used).
  - `WorldStage`: same public API as before (`build(root) -> ShaderMaterial`, `is_on_path(pos, margin := 0.0)`, `is_grass_free(pos)`, `add_cylinder_shape()`, `FIELD_HALF`, `SPAWN_POS`, `CLEARING_POS`, `NPC_POS`, `BOSS_POS`, `PATH_POINTS`, ...). `ROCKS` entries become `[position, rock model, scale, yaw]`; `HOUSES` entries become `[position, yaw, scene]`. Removed: `HOUSE_SIZE`, `WALL_COLOR`, `ROOF_COLOR`, `DOOR_COLOR`, `WATER_COLOR`, `WELL_RADIUS`.

- [ ] **Step 1: Rewrite `scripts/battle/battle_stage.gd`**

Replace the whole file with:

```gdscript
class_name BattleStage extends RefCounted
## Builds the battle backdrop: sky, warm sun, fog, grass field with tall grass
## (Vegetation) around the fighters, dirt path, low-poly rocks, trees and bushes, and
## distant hills. The environment, the mesh and model helpers and the rock and tree
## models are shared with WorldStage.

const GRASS := Color(0.32, 0.55, 0.22)
const DIRT := Color(0.62, 0.5, 0.34)
const HILL := Color(0.27, 0.47, 0.22)
const HAZE := Color(0.78, 0.84, 0.92)

## KayKit Medieval Hexagon rocks A to E (index used by the ROCKS tables).
const ROCK_SCENES: Array[PackedScene] = [
	preload("res://assets/medieval/rock_single_A.gltf"),
	preload("res://assets/medieval/rock_single_B.gltf"),
	preload("res://assets/medieval/rock_single_C.gltf"),
	preload("res://assets/medieval/rock_single_D.gltf"),
	preload("res://assets/medieval/rock_single_E.gltf"),
]
## Half the widest side of each rock model at scale 1 (measured AABBs), in metres.
const ROCK_RADII: Array[float] = [0.15, 0.145, 0.175, 0.145, 0.245]
## Single tree A, single tree B and a clump of trees (index used by the TREES tables).
const TREE_SCENES: Array[PackedScene] = [
	preload("res://assets/medieval/tree_single_A.gltf"),
	preload("res://assets/medieval/tree_single_B.gltf"),
	preload("res://assets/medieval/trees_A_medium.gltf"),
]
## [position, rock model, scale, yaw in degrees] of each rock.
const ROCKS := [
	[Vector3(-5.5, 0, -6.0), 2, 7.0, 30.0],
	[Vector3(4.5, 0, -8.0), 4, 8.0, 110.0],
	[Vector3(6.5, 0, -2.5), 1, 5.0, 200.0],
	[Vector3(-7.0, 0, -12.0), 4, 10.0, 250.0],
	[Vector3(2.5, 0, -4.5), 0, 4.0, 80.0],
]
## [position, tree model, scale, yaw in degrees] of each tree, behind the fighters.
const TREES := [
	[Vector3(-10, 0, -15), 0, 4.0, 20.0],
	[Vector3(-14, 0, -7), 1, 4.2, 70.0],
	[Vector3(11, 0, -17), 2, 4.0, 0.0],
	[Vector3(15, 0, -8), 0, 3.8, 140.0],
	[Vector3(-4, 0, -21), 2, 4.5, 200.0],
	[Vector3(4, 0, -24), 1, 4.4, 300.0],
	[Vector3(-18, 0, -18), 2, 4.0, 90.0],
]
## [position, scale] of each bush.
const BUSHES := [
	[Vector3(-4.5, 0, -3.5), 0.9],
	[Vector3(5.0, 0, -5.5), 0.8],
	[Vector3(-8.5, 0, -9.0), 1.1],
	[Vector3(8.5, 0, -11.0), 1.0],
	[Vector3(1.0, 0, -12.5), 0.9],
	[Vector3(-6.0, 0, 1.0), 0.8],
]
## [position, scale] of each hill (unit spheres, half buried).
const HILLS := [
	[Vector3(-26, -4, -48), Vector3(22, 9, 22)],
	[Vector3(18, -5, -55), Vector3(28, 10, 20)],
	[Vector3(48, -6, -25), Vector3(20, 8, 20)],
	[Vector3(-50, -5, -15), Vector3(20, 8, 24)],
]
## Tall grass around the fighters; none in the ellipse where they stand and the camera
## looks, on the path strip or in the rocks. Nobody walks here, so it is never pushed.
const GRASS_AREA := Rect2(-20, -24, 40, 34)
const GRASS_SEED := 11
const CLEAR_CENTER := Vector2(0.0, -0.3)
const CLEAR_RADII := Vector2(4.0, 5.5)
## The path plane: centre, size and yaw as built in build(), plus the grass margin.
const PATH_CENTER := Vector3(-0.2, 0.0, -0.3)
const PATH_SIZE := Vector2(2.6, 30.0)
const PATH_YAW_DEG := -21.0
const GRASS_MARGIN := 0.3


static func build(root: Node3D) -> void:
	build_environment(root)
	var ground := PlaneMesh.new()
	ground.size = Vector2(160, 160)
	add_mesh(root, ground, GRASS, Vector3.ZERO)
	var path := PlaneMesh.new()
	path.size = PATH_SIZE
	add_mesh(root, path, DIRT, PATH_CENTER + Vector3(0, 0.01, 0), Vector3.ONE,
		Vector3(0, PATH_YAW_DEG, 0))
	for rock in ROCKS:
		add_model(root, ROCK_SCENES[rock[1]], rock[0], rock[2], rock[3])
	for tree in TREES:
		add_model(root, TREE_SCENES[tree[1]], tree[0], tree[2], tree[3])
	var bushes: Array[Transform3D] = []
	for i in BUSHES.size():
		bushes.append(Transform3D(Basis(Vector3.UP, i * 0.8).scaled(Vector3.ONE * BUSHES[i][1]),
			BUSHES[i][0]))
	LowPoly.add_multimesh(root, LowPoly.bush_mesh(), bushes)
	for hill in HILLS:
		add_mesh(root, unit_sphere(), HILL, hill[0], hill[1])
	Vegetation.build(root, GRASS_AREA, _is_grass_free, GRASS_SEED)


## Sky, tonemap, fog and the warm sun shared by every outdoor scene.
static func build_environment(root: Node3D) -> void:
	_add_environment(root)
	_add_sun(root)


static func add_mesh(root: Node3D, mesh: Mesh, color: Color, pos: Vector3, \
		scl := Vector3.ONE, rot_deg := Vector3.ZERO) -> MeshInstance3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 1.0
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.scale = scl
	mi.rotation_degrees = rot_deg
	root.add_child(mi)
	return mi


## An imported model (its own materials) standing at pos, scaled evenly and turned
## yaw_deg around Y.
static func add_model(root: Node3D, scene: PackedScene, pos: Vector3, scl: float, \
		yaw_deg := 0.0) -> Node3D:
	var model: Node3D = scene.instantiate()
	model.position = pos
	model.scale = Vector3.ONE * scl
	model.rotation_degrees = Vector3(0, yaw_deg, 0)
	root.add_child(model)
	return model


## The mesh of a single-mesh model (the Medieval Hexagon ones), for MultiMeshes.
static func scene_mesh(scene: PackedScene) -> Mesh:
	var model := scene.instantiate()
	var mesh := (model.get_child(0) as MeshInstance3D).mesh
	model.free()
	return mesh


## Bounds of a single-mesh model at scale 1, in its own axes.
static func model_aabb(model: Node3D) -> AABB:
	return (model.get_child(0) as MeshInstance3D).get_aabb()


## Footprint radius of a [position, rock model, scale, yaw] entry.
static func rock_radius(rock: Array) -> float:
	return ROCK_RADII[rock[1]] * rock[2]


static func unit_sphere() -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	return mesh


static func _is_grass_free(pos: Vector3) -> bool:
	var p := Vector2(pos.x, pos.z)
	if ((p - CLEAR_CENTER) / CLEAR_RADII).length_squared() < 1.0:
		return false
	# Into the path plane's own axes (it is turned PATH_YAW_DEG around Y).
	var local := (pos - PATH_CENTER).rotated(Vector3.UP, -deg_to_rad(PATH_YAW_DEG))
	if absf(local.x) < PATH_SIZE.x / 2.0 + GRASS_MARGIN \
			and absf(local.z) < PATH_SIZE.y / 2.0 + GRASS_MARGIN:
		return false
	for rock in ROCKS:
		if p.distance_to(Vector2(rock[0].x, rock[0].z)) < rock_radius(rock) + GRASS_MARGIN:
			return false
	return true


static func _add_environment(root: Node3D) -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.32, 0.52, 0.88)
	sky_material.sky_horizon_color = HAZE
	sky_material.ground_horizon_color = HAZE
	sky_material.ground_bottom_color = Color(0.3, 0.4, 0.3)
	var sky := Sky.new()
	sky.sky_material = sky_material
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.ssao_enabled = true
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.fog_enabled = true
	env.fog_light_color = HAZE
	env.fog_density = 0.008
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	root.add_child(world_env)


static func _add_sun(root: Node3D) -> void:
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.9, 0.75)
	# Tuned for the Compatibility renderer (needed for the web build); 1.3 looked
	# right under Forward+ but washes everything out here.
	sun.light_energy = 0.6
	sun.shadow_enabled = true
	sun.rotation_degrees = Vector3(-40, 35, 0)
	root.add_child(sun)
```

- [ ] **Step 2: Rewrite `scripts/world/world_stage.gd`**

Replace the whole file with:

```gdscript
class_name WorldStage extends RefCounted
## Builds the world map: a 60 x 60 m field of tall grass (Vegetation) with a bare dirt
## path from the spawn point (south) to the village of Villaclaro in a clearing
## (north), low-poly houses, well and rocks with hand-made colliders, trees (denser
## toward the edges, with trunk colliders) and bushes scattered with fixed seeds,
## invisible walls, and hills outside the field. Same sky and sun as battles.

const FIELD_HALF := 30.0
const SPAWN_POS := Vector3(0, 0, 26)
const SPAWN_RADIUS := 4.0
const CLEARING_POS := Vector3(0, 0, -22)
const CLEARING_RADIUS := 8.0
const PATH_HALF_WIDTH := 1.5
## Tall grass covers this area (a bit past the invisible walls so the edge never looks
## bare), except the path and clearing (plus GRASS_PATH_MARGIN) and the rocks.
const GRASS_AREA := Rect2(-36, -36, 72, 72)
const GRASS_SEED := 7
const GRASS_PATH_MARGIN := 0.3
const GRASS_ROCK_MARGIN := 0.2
## Floor under the tall grass: darker than the battle field so gaps read as shade.
const GRASS_FLOOR := Color(0.08, 0.22, 0.05)
## Where the old woman stands and where the Rey Slime waits once the quest unlocks it.
const NPC_POS := Vector3(-2.5, 0, -20)
const BOSS_POS := Vector3(0, 0, -27.5)
const HOUSE_A := preload("res://assets/medieval/building_home_A_red.gltf")
const HOUSE_B := preload("res://assets/medieval/building_home_B_red.gltf")
const WELL := preload("res://assets/medieval/building_well_red.gltf")
## The Medieval Hexagon buildings are miniatures (a house is 0.8 m wide, 0.9 m tall).
const BUILDING_SCALE := 3.5
## [position, yaw in degrees, model] of each village house. The door is on the model's
## +Z side; the yaw turns it to the clearing.
const HOUSES := [
	[Vector3(-5.5, 0, -25), 60.0, HOUSE_A],
	[Vector3(5.5, 0, -25), -60.0, HOUSE_B],
]
const WELL_POS := Vector3(4.5, 0, -19)
## Corners of the dirt path, from the spawn point to the clearing.
const PATH_POINTS: Array[Vector3] = [
	Vector3(0, 0, 26),
	Vector3(3, 0, 12),
	Vector3(-2, 0, 0),
	Vector3(2, 0, -12),
	Vector3(0, 0, -22),
]
## [position, rock model (BattleStage.ROCK_SCENES), scale, yaw in degrees] of each
## rock, kept off the path and off the autoplay route.
const ROCKS := [
	[Vector3(-20, 0, -16), 2, 8.0, 15.0],
	[Vector3(-22, 0, 14), 4, 9.0, 60.0],
	[Vector3(18, 0, -18), 3, 9.0, 130.0],
	[Vector3(22, 0, 16), 4, 10.0, 200.0],
	[Vector3(-10, 0, -18), 1, 8.0, 290.0],
	[Vector3(12, 0, -20), 2, 9.0, 80.0],
	[Vector3(-12, 0, 23), 0, 10.0, 170.0],
	[Vector3(24, 0, 0), 3, 10.0, 240.0],
	[Vector3(-24, 0, -2), 2, 10.0, 320.0],
	[Vector3(7, 0, -15), 1, 7.0, 45.0],
]
## Trees: TREE_TRIES random spots over a square of TREE_AREA_HALF with a fixed seed. A
## spot is kept with a chance that rises from TREE_CENTER_CHANCE (up to TREE_RISE_FROM
## from the centre) to 1 at the field's edge, and only if it is clear of the path, the
## autoplay route, the rocks and the other trees.
const TREE_SEED := 23
const TREE_TRIES := 600
const TREE_AREA_HALF := 36.0
const TREE_CENTER_CHANCE := 0.05
const TREE_RISE_FROM := 8.0
const TREE_SPACING := 3.2
const TREE_PATH_MARGIN := 3.0
const TREE_ROUTE_MARGIN := 2.5
const TREE_ROCK_MARGIN := 1.5
const TREE_SCALE := Vector2(3.6, 4.4)
## Past this distance from the centre (largest of |x| and |z|) trees are clumps.
const CLUMP_FROM := 27.0
## Colliders (only inside the walls): a trunk for single trees, a wider one for clumps.
const TRUNK_RADIUS := 0.35
const CLUMP_RADIUS := 2.0
const TREE_COLLIDER_HEIGHT := 3.0
## Bushes: BUSH_TRIES random spots inside the walls with a fixed seed, kept off the path
## and the rocks. They have no collider; the hero walks through them like the grass.
const BUSH_SEED := 31
const BUSH_TRIES := 220
const BUSH_SCALE := Vector2(0.7, 1.2)
const BUSH_PATH_MARGIN := 0.8
const BUSH_ROCK_MARGIN := 0.6
## [position, scale] of each hill (unit spheres, half buried) around the field.
const HILLS := [
	[Vector3(-40, -5, -42), Vector3(22, 10, 22)],
	[Vector3(0, -6, -54), Vector3(28, 11, 20)],
	[Vector3(40, -5, -40), Vector3(22, 9, 22)],
	[Vector3(54, -6, 0), Vector3(20, 10, 28)],
	[Vector3(42, -5, 42), Vector3(22, 9, 22)],
	[Vector3(0, -6, 56), Vector3(28, 10, 20)],
	[Vector3(-42, -5, 42), Vector3(22, 10, 22)],
	[Vector3(-54, -6, 0), Vector3(20, 9, 28)],
]


## Returns the tall grass material, so the world can bend it away from the player.
static func build(root: Node3D) -> ShaderMaterial:
	BattleStage.build_environment(root)
	_add_ground(root)
	_add_path(root)
	for rock in ROCKS:
		_add_solid_model(root, BattleStage.ROCK_SCENES[rock[1]], rock[0], rock[2], rock[3])
	_add_village(root)
	_add_trees(root)
	_add_bushes(root)
	for hill in HILLS:
		BattleStage.add_mesh(root, BattleStage.unit_sphere(), BattleStage.HILL, hill[0], hill[1])
	_add_walls(root)
	return Vegetation.build(root, GRASS_AREA, is_grass_free, GRASS_SEED)


## True on the dirt path, the clearing and around the spawn point: no encounters there.
## margin widens every one of them (the grass keeps a little off the path's edge).
static func is_on_path(pos: Vector3, margin := 0.0) -> bool:
	var p := Vector2(pos.x, pos.z)
	if p.distance_to(Vector2(SPAWN_POS.x, SPAWN_POS.z)) < SPAWN_RADIUS + margin:
		return true
	if p.distance_to(Vector2(CLEARING_POS.x, CLEARING_POS.z)) < CLEARING_RADIUS + margin:
		return true
	for i in PATH_POINTS.size() - 1:
		var a := Vector2(PATH_POINTS[i].x, PATH_POINTS[i].z)
		var b := Vector2(PATH_POINTS[i + 1].x, PATH_POINTS[i + 1].z)
		var closest := Geometry2D.get_closest_point_to_segment(p, a, b)
		if p.distance_to(closest) < PATH_HALF_WIDTH + margin:
			return true
	return false


## Where tall grass may grow: off the path and clearing (the village is inside the
## clearing) and off the rocks.
static func is_grass_free(pos: Vector3) -> bool:
	if is_on_path(pos, GRASS_PATH_MARGIN):
		return false
	return not _near_rock(pos, GRASS_ROCK_MARGIN)


## Upright cylinder collider standing on the ground, for village props and figures.
static func add_cylinder_shape(body: StaticBody3D, radius: float, height: float) -> void:
	var cylinder := CylinderShape3D.new()
	cylinder.radius = radius
	cylinder.height = height
	var shape := CollisionShape3D.new()
	shape.shape = cylinder
	shape.position = Vector3(0, height / 2.0, 0)
	body.add_child(shape)


static func _add_ground(root: Node3D) -> void:
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(160, 160)
	BattleStage.add_mesh(root, mesh, GRASS_FLOOR, Vector3.ZERO)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	shape.shape = WorldBoundaryShape3D.new()
	body.add_child(shape)
	root.add_child(body)


static func _add_path(root: Node3D) -> void:
	for i in PATH_POINTS.size() - 1:
		var a := PATH_POINTS[i]
		var b := PATH_POINTS[i + 1]
		var d := b - a
		var mesh := PlaneMesh.new()
		mesh.size = Vector2(PATH_HALF_WIDTH * 2.0, d.length())
		var mid := (a + b) / 2.0 + Vector3(0, 0.01, 0)
		var yaw := rad_to_deg(atan2(d.x, d.z))
		BattleStage.add_mesh(root, mesh, BattleStage.DIRT, mid, Vector3.ONE, Vector3(0, yaw, 0))
	# Round the inner bends so the drawn path matches is_on_path (union of capsules).
	for i in range(1, PATH_POINTS.size() - 1):
		_add_disc(root, PATH_POINTS[i], PATH_HALF_WIDTH)
	_add_disc(root, SPAWN_POS, SPAWN_RADIUS)
	_add_disc(root, CLEARING_POS, CLEARING_RADIUS)


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


static func _add_village(root: Node3D) -> void:
	for house in HOUSES:
		_add_solid_model(root, house[2], house[0], BUILDING_SCALE, house[1])
	_add_solid_model(root, WELL, WELL_POS, BUILDING_SCALE, 0.0)


static func _add_trees(root: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = TREE_SEED
	var placed: Array[Vector2] = []
	var single_a: Array[Transform3D] = []
	var single_b: Array[Transform3D] = []
	var clumps: Array[Transform3D] = []
	for i in TREE_TRIES:
		# Every roll is made even for spots left out, so the layout stays stable.
		var pos := Vector3(rng.randf_range(-TREE_AREA_HALF, TREE_AREA_HALF), 0.0,
			rng.randf_range(-TREE_AREA_HALF, TREE_AREA_HALF))
		var roll := rng.randf()
		var yaw := rng.randf() * TAU
		var scl := rng.randf_range(TREE_SCALE.x, TREE_SCALE.y)
		var use_a := rng.randf() < 0.5
		var edge := maxf(absf(pos.x), absf(pos.z))
		var rise := clampf((edge - TREE_RISE_FROM) / (FIELD_HALF - TREE_RISE_FROM), 0.0, 1.0)
		if roll > lerpf(TREE_CENTER_CHANCE, 1.0, rise) or not _tree_fits(pos, placed):
			continue
		placed.append(Vector2(pos.x, pos.z))
		var xform := Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * scl), pos)
		var clump := edge > CLUMP_FROM
		if clump:
			clumps.append(xform)
		elif use_a:
			single_a.append(xform)
		else:
			single_b.append(xform)
		if edge < FIELD_HALF:
			var body := StaticBody3D.new()
			body.position = pos
			root.add_child(body)
			add_cylinder_shape(body, CLUMP_RADIUS if clump else TRUNK_RADIUS,
				TREE_COLLIDER_HEIGHT)
	LowPoly.add_multimesh(root, BattleStage.scene_mesh(BattleStage.TREE_SCENES[0]), single_a)
	LowPoly.add_multimesh(root, BattleStage.scene_mesh(BattleStage.TREE_SCENES[1]), single_b)
	LowPoly.add_multimesh(root, BattleStage.scene_mesh(BattleStage.TREE_SCENES[2]), clumps)


static func _tree_fits(pos: Vector3, placed: Array[Vector2]) -> bool:
	if is_on_path(pos, TREE_PATH_MARGIN) or _near_route(pos, TREE_ROUTE_MARGIN):
		return false
	if _near_rock(pos, TREE_ROCK_MARGIN):
		return false
	var p := Vector2(pos.x, pos.z)
	for other in placed:
		if p.distance_to(other) < TREE_SPACING:
			return false
	return true


static func _add_bushes(root: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = BUSH_SEED
	var bushes: Array[Transform3D] = []
	for i in BUSH_TRIES:
		var pos := Vector3(rng.randf_range(-FIELD_HALF, FIELD_HALF), 0.0,
			rng.randf_range(-FIELD_HALF, FIELD_HALF))
		var yaw := rng.randf() * TAU
		var scl := rng.randf_range(BUSH_SCALE.x, BUSH_SCALE.y)
		if is_on_path(pos, BUSH_PATH_MARGIN) or _near_rock(pos, BUSH_ROCK_MARGIN):
			continue
		bushes.append(Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * scl), pos))
	LowPoly.add_multimesh(root, LowPoly.bush_mesh(), bushes)


## True within margin of a rock's footprint.
static func _near_rock(pos: Vector3, margin: float) -> bool:
	var p := Vector2(pos.x, pos.z)
	for rock in ROCKS:
		var center := Vector2(rock[0].x, rock[0].z)
		if p.distance_to(center) < BattleStage.rock_radius(rock) + margin:
			return true
	return false


## True within margin of the loop Player walks on --autoplay, so no tree blocks it.
static func _near_route(pos: Vector3, margin: float) -> bool:
	var p := Vector2(pos.x, pos.z)
	var route := Player.AUTOPLAY_ROUTE
	for i in route.size():
		var a := Vector2(route[i].x, route[i].z)
		var next := route[(i + 1) % route.size()]
		var b := Vector2(next.x, next.z)
		if p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b)) < margin:
			return true
	return false


static func _add_walls(root: Node3D) -> void:
	var h := FIELD_HALF
	var walls := [
		[Vector3(0, 2, -h), Vector3(h * 2.0, 4, 1)],
		[Vector3(0, 2, h), Vector3(h * 2.0, 4, 1)],
		[Vector3(-h, 2, 0), Vector3(1, 4, h * 2.0)],
		[Vector3(h, 2, 0), Vector3(1, 4, h * 2.0)],
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

- [ ] **Step 3: Validate the scripts**

```powershell
foreach ($s in "battle/battle_stage", "world/world_stage", "battle/battle_scene", "world/world", "game/game") {
    .\tools\godot.cmd --headless --path . --check-only --script "res://scripts/$s.gd"
}
```

Expected: only the banner for each script.

- [ ] **Step 4: Map on its own**

```powershell
cmd /c ".\tools\godot.cmd --headless --path . res://scenes/world/world.tscn --fixed-fps 10 --quit-after 3000 -- --autoplay > build\world.txt 2>&1"
Select-String -CaseSensitive -Path build\world.txt -Pattern "ERROR|WARNING"
Select-String -Path build\world.txt -Pattern "Encuentro"
```

Expected: no ERROR / WARNING; several `Encuentro en (...)` lines (the player keeps walking the route, so no tree blocks it).

- [ ] **Step 5: Full headless autoplay**

```powershell
cmd /c ".\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 15000 -- --autoplay > build\autoplay.txt 2>&1"
Select-String -CaseSensitive -Path build\autoplay.txt -Pattern "ERROR|WARNING"
Select-String -Path build\autoplay.txt -Pattern "cumplida"
```

Expected: no ERROR / WARNING; `Misión cumplida`.

- [ ] **Step 6: Recorded frames**

```powershell
New-Item -ItemType Directory -Force build\frames | Out-Null
.\tools\godot.cmd --path . --write-movie build\frames\f.png --fixed-fps 10 --quit-after 900 -- --autoplay
```

Check with the Read tool:
- Map: pale-green low-poly pine trees and clumps, denser toward the edges, none on the path; faceted green bushes in the grass; grey low-poly rocks; nothing blocking the hero's route.
- Village (frames ~450-550): the red-roofed house A (west) and the taller house B with stairs (east) with their doors turned toward the clearing, the red-roofed well east of the old woman.
- Battle: rocks, trees behind the slime, a few bushes; the path and the fighters' area clear.

If a model looks washed out (the KayKit palette is pastel under ACES and fog), that is the pack's style; do not change the lighting in this plan. Then:

```powershell
Remove-Item -Recurse -Force build\frames
```

- [ ] **Step 7: Commit**

```powershell
git add scripts/battle/battle_stage.gd scripts/world/world_stage.gd
git commit -m "Build the village, rocks, trees and bushes from low-poly models"
```

---

### Task 4: Documentation, full check and web export

**Files:**
- Modify: `CLAUDE.md`

**Interfaces:**
- Consumes: everything above.
- Produces: up-to-date `CLAUDE.md` Layout.

- [ ] **Step 1: Update `CLAUDE.md` Layout**

1. Replace the `world_stage.gd` bullet with:

```markdown
- `scripts/world/world_stage.gd` (`WorldStage`) — static builder of the 60 × 60 m field of tall grass (`Vegetation`; `is_grass_free()`, `build()` returns the grass material, which `World` pushes away from the player each frame): dirt path from `SPAWN_POS` (south) to the village of Villaclaro in the clearing at `CLEARING_POS` (north: KayKit houses `building_home_A_red` / `B_red` and `building_well_red` at scale 3.5 with box colliders fitted to their meshes; `NPC_POS`, `BOSS_POS`), KayKit rocks with box colliders (`ROCKS`: position, model, scale, yaw), trees scattered with seed 23 (denser toward the edges, clumps past 27 m, kept off the path, `Player.AUTOPLAY_ROUTE` and rocks, cylinder colliders inside the walls) and bushes with seed 31 (no collider), all as `MultiMesh`es; invisible walls, hills outside; `is_on_path(pos, margin := 0.0)` (path, clearing and spawn area are safe), `add_cylinder_shape()`.
```

2. In the `player.gd` bullet, replace `smooth turn, bob while walking;` with `smooth turn, walk / idle animation through `BattleActor.set_walking()`;`.

3. Replace the `battle_actor.gd` bullet with:

```markdown
- `scenes/battle/battle_actor.tscn` + `scripts/battle/battle_actor.gd` (`BattleActor`) — figure of a fighter or villager built from the `LOOKS` table (`look`: `HERO` / `SLIME` / `VILLAGER` / `KING_SLIME`, set before `add_child`), faces -Z. `HERO` is KayKit `Knight.glb`, `VILLAGER` is `Mage.glb` (scale 0.65, turned 180°, unused props hidden, `AnimationPlayer` at `AnimationPlayer`, roles in `CHARACTER_ANIMS`: `Idle`, `Running_A`, `1H_Melee_Attack_Slice_Diagonal`, `Spellcast_Shoot`, `Hit_A`, `Dodge_Backward`, `Death_A`, `Cheer`); `SLIME` / `KING_SLIME` are faceted `LowPoly` blobs with eyes (king ×1.6 with a gold crown) that bounce while idle. Awaitable `play_attack`, `play_hit` (flash overlay + floating `Label3D` number), `play_dodge`, `play_defeat` (characters stay down, slimes fade and hide), `play_cast(color)`, `play_burn(amount, color)`, `play_heal`, `play_stagger`, `play_cheer`; `set_walking(on)` for the map; `reset()`.
```

4. Replace the `battle_stage.gd` bullet with:

```markdown
- `scripts/battle/battle_stage.gd` (`BattleStage`) — battle backdrop builder (tall grass around the fighters, none where they stand; KayKit rocks and trees and low-poly bushes behind them); `build_environment(root)` (procedural sky, ACES tonemap, SSAO, glow, fog, warm sun with shadows), `add_mesh()`, `unit_sphere()`, `add_model(root, scene, pos, scl, yaw_deg)`, `scene_mesh(scene)`, `model_aabb(model)`, `rock_radius(rock)`, `ROCK_SCENES`, `ROCK_RADII` and `TREE_SCENES` are shared with `WorldStage`.
- `scripts/battle/low_poly.gd` (`LowPoly`) — faceted flat-shaded meshes built in code: `blob(profile, segments)` (lathe of a side profile; slimes and bushes), `bush_mesh()`, `add_multimesh(root, mesh, transforms)`.
- `assets/` — only the models in use, copied unchanged from the CC0 KayKit packs kept (git-ignored) in `assets_src/`: `characters/` (Adventurers: `Knight.glb`, `Mage.glb` and their extracted textures) and `medieval/` (Medieval Hexagon: houses, well, rocks, trees, shared `hexagons_medieval.png`); `assets/CREDITS.md` lists packs, author and licence.
```

- [ ] **Step 2: Full headless autoplay**

```powershell
cmd /c ".\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 15000 -- --autoplay > build\autoplay.txt 2>&1"
Select-String -CaseSensitive -Path build\autoplay.txt -Pattern "ERROR|WARNING"
Select-String -Path build\autoplay.txt -Pattern "te cierra el paso|cumplida"
```

Expected: no ERROR / WARNING; `¡El Rey Slime te cierra el paso!` and `Misión cumplida`.

- [ ] **Step 3: Frames of the whole quest, Rey Slime included**

The boss fight comes before frame 4000 (measured twice in a trial). Movie Maker always records at the project's 1280x720 (`--resolution` does not change it), so this writes about 4 GB of PNGs: check there are at least 6 GB free first, and delete the folder right after.

```powershell
New-Item -ItemType Directory -Force build\frames | Out-Null
cmd /c ".\tools\godot.cmd --path . --write-movie build\frames\f.png --fixed-fps 10 --quit-after 4000 -- --autoplay > build\movie.txt 2>&1"
Select-String -CaseSensitive -Path build\movie.txt -Pattern "ERROR|WARNING"
```

Expected: at most the known Jolt warning. Open frames from the end backwards (`f00003900.png`, `f00003700.png`, ...) until the Rey Slime shows: on the map north of the village (blue faceted slime, gold crown, facing south) and in its battle (crown visible, bounce, hit flash, squash on defeat; the hero's attack, spell, hit and, if he loses a fight, the death fall). Then:

```powershell
Remove-Item -Recurse -Force build\frames
```

- [ ] **Step 4: Web export and size**

```powershell
$before = (Get-Item build\web\index.pck -ErrorAction SilentlyContinue).Length
.\tools\godot.cmd --headless --path . --export-release "Web" build/web/index.html
$after = (Get-Item build\web\index.pck).Length
"before: $before  after: $after  growth MB: {0:N2}" -f (($after - $before) / 1MB)
```

Expected: export without ERROR; `index.pck` about 2.9 MB, growth well under 15 MB (trial: 121 008 → 2 882 760 bytes). If `build\web` did not exist before, `$before` is empty: compare with 121 008 bytes.

- [ ] **Step 5: Open the web build**

Serve `build/web` with any static server (e.g. `npx http-server build/web -p 8060` or the `.claude/launch.json` preview if present) and open it in the browser pane: the map loads with the knight, trees, rocks and village; walk into the grass until a battle starts and check the models render the same as on desktop.

- [ ] **Step 6: Commit**

```powershell
git add CLAUDE.md
git commit -m "Document the low-poly models, LowPoly and the asset folder"
```

---

## Self-review

- **Spec coverage:** packs and `assets/` copy (Task 1); credits (Task 1 Step 4); hero `Knight.glb` with `1H_Sword` + `Round_Shield` only, old woman `Mage.glb` with `2H_Staff` only (Task 2, `LOOKS.hide`); slime / king slime faceted with eyes and crown at ×1.6 (Task 2); `LOOKS` table with scene, scale, animation names and adornments (Task 2); animations plus tweens kept, awaitable (Task 2); idle animation replaces the bob, slimes keep their bounce (Task 2); `Player` walk / idle (Task 2 Step 4); red houses and well at 3.5, trees ~4, rocks 8–10 on the map (4–10 in battle) (Task 3); trees off the path with a fixed seed, denser toward the edges (Task 3); hand-made box / cylinder colliders (Task 3); bushes (procedural, Task 2 `LowPoly` + Task 3); materials left as imported (Task 3 Step 6 note); web growth < 15 MB (Task 4 Step 4); verification by `--import`, `--check-only`, frames, autoplay and web (every task). Skeletons pack: credited as downloaded, no model copied (out of scope until enemies of later zones).
- **Placeholders:** none; every file is given whole or as exact replacements.
- **Names:** `LowPoly.blob / bush_mesh / add_multimesh`, `BattleStage.add_model / scene_mesh / model_aabb / rock_radius / ROCK_SCENES / ROCK_RADII / TREE_SCENES`, `BattleActor.set_walking / play_cheer / LOOKS / CHARACTER_ANIMS / SLIME_PROFILE` are used with the same signatures in every task.
- **Deviation from the spec, on purpose:** the map "walk" animation is `Running_A` at 1.8× (the hero moves at 5 m/s; `Walking_A` covers only ~0.5 m/s at this scale and would slide badly). The Medieval Hexagon pack has no bush model, so bushes are procedural blobs like the slimes.
```
