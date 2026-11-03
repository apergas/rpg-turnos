# Cámara cenital y vegetación Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the world-map camera into a fixed top-down camera with mouse-wheel zoom, and cover the field and the battle backdrop with tall, wind-swayed grass and flowers, leaving the path and clearing bare.

**Architecture:** `FollowCamera` is rewritten in place: fixed pitch, no yaw, zoom from the mouse wheel. `Player` moves in screen axes. A new static builder `Vegetation` generates grass tufts as chunked `MultiMeshInstance3D`s with a text shader (`shaders/grass.gdshader`) and flowers as a coloured `MultiMesh`. `WorldStage` and `BattleStage` call it with their own "can grass grow here" rule; `World` feeds the player's position to the shader each physics frame so the grass bends away.

**Tech Stack:** Godot 4.7.2, GDScript, Compatibility renderer (web build), Jolt physics.

**Spec:** `docs/boost/specs/2026-11-03-camara-vegetacion-design.md`

## Global Constraints

- **No tests of any kind**, at any point: no `tests/` folder, no test scripts, no GUT or gdUnit4. Verify by hand: `--check-only`, run the game, read the Godot output, look at recorded frames.
- **Commit messages** never mention Claude: no `Co-Authored-By`, no "Generated with", no attribution of any kind.
- **Branch:** work on `feature/camara-vegetacion`, created from `develop`. Never commit to `main` or `develop`. Never push.
- **Scenes:** `.tscn` files only hold the root node and its script; every other node is created in code. The shader is a text `.gdshader` file.
- **Renderer:** Compatibility. Everything must also run in the web export.
- **Godot:** use `.\tools\godot.cmd` (wrapper; `godot` is not on PATH).
- **Camera values:** `PITCH_DEG = 55`, `DISTANCE = 14`, zoom 9 to 20 m in steps of 1.5 m, `ZOOM_RATE = 8`, `FOV = 45`, `FOLLOW_RATE = 6`, looks 1 m above the hero. Camera south of the hero looking north; Q and E do nothing.
- **Movement:** WASD / arrows in screen axes: up = −Z (north), right = +X.
- **Grass values:**
  - 5 blades per tuft, 0.06 m wide at the base, 0.5 m tall.
  - Tuft scale 0.8 to 1.3.
  - Grid spacing 0.65 m with ±0.3 m jitter.
  - Chunks of 12 × 12 m.
  - No shadows.
  - Wind amplitude 0.08 m at the tip.
  - Push radius 0.8 m, up to 0.25 m at the tip.
- **Flowers:** about 300 per 60 × 60 m; white, yellow and purple.
- **Map grass area:** `Rect2(-36, -36, 72, 72)`. Excludes the path, the clearing and the spawn (`is_on_path` with a 0.3 m margin), and the rocks (largest radius + 0.2 m).
- **Battle grass area:** `Rect2(-20, -24, 40, 34)`. Excludes an ellipse centred on `(0, 0, -0.3)` with radii 4 m (X) and 5.5 m (Z), the battle path strip and the battle rocks. No push.
- **Encounter rate:** not changed in this plan.
- **Known noise:** one `WARNING: Jolt Physics job system exceeded the maximum number of jobs` in windowed `--fixed-fps` runs is harmless. Any other ERROR or WARNING is a real problem.

## File map

| File | Change |
|---|---|
| `scripts/world/follow_camera.gd` | Rewritten: top-down camera with zoom |
| `scripts/world/player.gd` | Moves in screen axes; loses `camera` |
| `scripts/world/world.gd` | No camera wiring for the player or yaw; keeps the grass material and pushes it each frame |
| `scripts/world/vegetation.gd` | New `Vegetation` builder (tufts, flowers, chunks, push) |
| `shaders/grass.gdshader` | New grass shader (wind, push, colour) |
| `scripts/world/world_stage.gd` | `is_on_path(pos, margin)`, `is_grass_free()`, darker floor, `build()` returns the grass material |
| `scripts/battle/battle_stage.gd` | Grass around the battle |
| `CLAUDE.md` | Layout and controls |

---

### Task 1: Top-down camera and screen-axis movement

**Files:**
- Modify (rewrite): `scripts/world/follow_camera.gd`
- Modify: `scripts/world/player.gd`
- Modify: `scripts/world/world.gd`

**Interfaces:**
- Produces:
  - `FollowCamera` with `target: Node3D`, `distance: float` and `snap()`. There is no `yaw` any more.
  - `Player` no longer has a `camera` property.

- [ ] **Step 1: Create the branch**

```powershell
git checkout develop
git checkout -b feature/camara-vegetacion
```

- [ ] **Step 2: Rewrite `scripts/world/follow_camera.gd`**

Replace the whole file with:

```gdscript
class_name FollowCamera extends Camera3D
## Top-down camera for the world map: high above the target and south of it, looking
## north at a fixed angle, following it smoothly. The mouse wheel zooms between
## MIN_DISTANCE and MAX_DISTANCE. It never turns.

## Degrees below the horizon the camera looks down.
const PITCH_DEG := 55.0
## Distance from the point it looks at, in meters.
const DISTANCE := 14.0
const MIN_DISTANCE := 9.0
const MAX_DISTANCE := 20.0
const ZOOM_STEP := 1.5
## Fraction of the remaining zoom covered per second (exponential smoothing).
const ZOOM_RATE := 8.0
## Fraction of the remaining distance covered per second (exponential smoothing).
const FOLLOW_RATE := 6.0
const LOOK_HEIGHT := 1.0
const FOV := 45.0

var target: Node3D
## Current distance; moves toward the zoom goal.
var distance := DISTANCE

var _zoom_goal := DISTANCE


func _ready() -> void:
	fov = FOV


func _unhandled_input(event: InputEvent) -> void:
	var wheel := event as InputEventMouseButton
	if wheel == null or not wheel.pressed:
		return
	if wheel.button_index == MOUSE_BUTTON_WHEEL_UP:
		_zoom_goal -= ZOOM_STEP
	elif wheel.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_zoom_goal += ZOOM_STEP
	else:
		return
	_zoom_goal = clampf(_zoom_goal, MIN_DISTANCE, MAX_DISTANCE)


# Same tick as the player's movement, so the follow does not stutter.
func _physics_process(delta: float) -> void:
	if target == null:
		return
	distance = lerpf(distance, _zoom_goal, minf(1.0, ZOOM_RATE * delta))
	global_position = global_position.lerp(_goal_position(), minf(1.0, FOLLOW_RATE * delta))
	look_at(_focus(), Vector3.UP)


## Jumps to the follow position and zoom without smoothing (start and respawn).
func snap() -> void:
	distance = _zoom_goal
	global_position = _goal_position()
	look_at(_focus(), Vector3.UP)


func _focus() -> Vector3:
	return target.global_position + Vector3.UP * LOOK_HEIGHT


func _goal_position() -> Vector3:
	var pitch := deg_to_rad(PITCH_DEG)
	return _focus() + Vector3(0.0, sin(pitch), cos(pitch)) * distance
```

- [ ] **Step 3: Make `Player` move in screen axes**

In `scripts/world/player.gd`, change the class doc comment:

```gdscript
## Hero on the world map. Moves with WASD / arrows relative to the camera, turns
## smoothly toward where it walks and bobs while moving. Its model is a BattleActor.
```

to:

```gdscript
## Hero on the world map. Moves with WASD / arrows in screen axes (the top-down camera
## never turns: up is north, -Z), turns smoothly toward where it walks and bobs while
## moving. Its model is a BattleActor.
```

Delete the line:

```gdscript
var camera: FollowCamera
```

Replace the end of `_wanted_direction()`:

```gdscript
	if keys == Vector2.ZERO or camera == null:
		return Vector3.ZERO
	keys = keys.normalized()
	# Screen up is away from the camera; screen right is the camera's right.
	var forward := Vector3(-sin(camera.yaw), 0.0, -cos(camera.yaw))
	var right := Vector3(cos(camera.yaw), 0.0, -sin(camera.yaw))
	return right * keys.x - forward * keys.y
```

with:

```gdscript
	if keys == Vector2.ZERO:
		return Vector3.ZERO
	keys = keys.normalized()
	# The camera sits south of the player looking north: screen up is -Z, right is +X.
	return Vector3(keys.x, 0.0, keys.y)
```

- [ ] **Step 4: Remove the camera yaw wiring from `World`**

In `scripts/world/world.gd`, in `_ready()`, delete the line:

```gdscript
	_player.camera = _camera
```

In `respawn()`, delete the line:

```gdscript
	_camera.yaw = 0.0
```

so that `respawn()` reads:

```gdscript
## Back to the spawn point facing up the path, with the encounter grace restarted.
func respawn() -> void:
	_player.place(WorldStage.SPAWN_POS, 0.0)
	_camera.snap()
	_meter.reset()
	_was_near = false
```

- [ ] **Step 5: Check the scripts**

Run each command. Each one must exit 0 and print no ERROR:

```powershell
.\tools\godot.cmd --headless --path . --check-only --script res://scripts/world/follow_camera.gd
.\tools\godot.cmd --headless --path . --check-only --script res://scripts/world/player.gd
.\tools\godot.cmd --headless --path . --check-only --script res://scripts/world/world.gd
```

Then make sure no `yaw` or `.camera` reference to the camera is left:

```powershell
Select-String -Path scripts\world\*.gd,scripts\game\*.gd -Pattern "\.yaw|camera\.yaw|_player\.camera"
```

Expected: no output.

- [ ] **Step 6: Look at it**

Record frames of the world map on its own (it prints encounters and keeps walking):

```powershell
New-Item -ItemType Directory -Force "$env:TEMP\cam1" | Out-Null
.\tools\godot.cmd --path . --write-movie "$env:TEMP\cam1\f.png" --fixed-fps 10 --quit-after 300 res://scenes/world/world.tscn -- --autoplay
```

Open about 3 frames (for example `f00000020.png`, `f00000150.png`, `f00000280.png`). Check that:

- the camera looks down at about 55° from the south;
- the hero is near the centre of the frame;
- the path, rocks and village show from above.

The output may only contain the known Jolt warning. Delete the folder afterwards:

```powershell
Remove-Item -Recurse -Force "$env:TEMP\cam1"
```

- [ ] **Step 7: Commit**

```powershell
git add scripts/world/follow_camera.gd scripts/world/player.gd scripts/world/world.gd
git commit -m "Make the world camera top-down with wheel zoom and move in screen axes"
```

---

### Task 2: Tall grass and flowers on the world map

**Files:**
- Create: `scripts/world/vegetation.gd`
- Create: `shaders/grass.gdshader`
- Modify: `scripts/world/world_stage.gd`
- Modify: `scripts/world/world.gd`

**Interfaces:**
- Consumes: `FollowCamera` and `Player` from Task 1. Nothing is called on them here.
- Produces:
  - `Vegetation.build(root: Node3D, area: Rect2, is_free: Callable, seed: int) -> ShaderMaterial`, where `area` is in metres on XZ: `position.x` is the min X, `position.y` the min Z. `is_free.call(Vector3) -> bool`.
  - `Vegetation.set_pusher(material: ShaderMaterial, pos: Vector3) -> void`.
  - `WorldStage.build(root) -> ShaderMaterial`.
  - `WorldStage.is_on_path(pos: Vector3, margin := 0.0) -> bool`.
  - `WorldStage.is_grass_free(pos: Vector3) -> bool`.

- [ ] **Step 1: Create `shaders/grass.gdshader`**

```glsl
// Tall grass for Vegetation tufts (MultiMesh instances). UV.y runs from 0 at the blade
// base to 1 at its tip; INSTANCE_CUSTOM.rgb holds the tuft's tip colour. The tips sway
// with the wind and bend away from `pusher` (the player on the world map).
shader_type spatial;
render_mode cull_disabled, specular_disabled;

uniform vec3 base_color : source_color = vec3(0.16, 0.32, 0.1);
// Far below the ground by default, so nothing is pushed until set_pusher() is called.
uniform vec3 pusher = vec3(0.0, -100.0, 0.0);
uniform float push_radius = 0.8;
uniform float push_strength = 0.25;
uniform float wind_strength = 0.08;
uniform float wind_speed = 1.6;

varying vec3 tip_color;

void vertex() {
	float bend = UV.y * UV.y;
	vec3 root = MODEL_MATRIX[3].xyz;
	float wave = sin(TIME * wind_speed + root.x * 0.35 + root.z * 0.25);
	vec3 offset = vec3(wave, 0.0, wave * 0.5) * wind_strength * bend;
	vec2 away = root.xz - pusher.xz;
	float dist = length(away);
	if (dist < push_radius && dist > 0.001 && abs(root.y - pusher.y) < 2.0) {
		float k = (1.0 - dist / push_radius) * push_strength * bend;
		offset.xz += normalize(away) * k;
		offset.y -= k * 0.5;
	}
	// The offset is in world space; the vertex is in the instance's (scaled, turned) space.
	VERTEX += (inverse(MODEL_MATRIX) * vec4(offset, 0.0)).xyz;
	tip_color = INSTANCE_CUSTOM.rgb;
}

void fragment() {
	ALBEDO = mix(base_color, tip_color, UV.y);
	ROUGHNESS = 1.0;
	// Lit like the ground under it, so thin blades never flash dark or bright.
	NORMAL = (VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz;
}
```

- [ ] **Step 2: Create `scripts/world/vegetation.gd`**

```gdscript
class_name Vegetation extends RefCounted
## Builds tall grass and flowers from code. Grass tufts (BLADES thin blades each) go on
## a jittered grid wherever is_free says so, split into CHUNK-sized MultiMeshes so the
## camera skips the ones it does not see. The same seed always gives the same layout.
## The returned material sways with the wind; set_pusher() bends it away from a point.

const GRASS_SHADER := preload("res://shaders/grass.gdshader")
const BLADES := 5
const BLADE_WIDTH := 0.06
const BLADE_HEIGHT := 0.5
## How far each blade's tip leans out from the tuft centre.
const BLADE_LEAN := 0.15
const SPACING := 0.65
const JITTER := 0.3
const MIN_SCALE := 0.8
const MAX_SCALE := 1.3
const CHUNK := 12.0
## Two tip greens; every tuft gets a mix of them.
const TIP_COLORS := [Color(0.36, 0.62, 0.22), Color(0.52, 0.7, 0.26)]
const FLOWERS_PER_M2 := 300.0 / 3600.0
const FLOWER_COLORS := [Color(0.95, 0.95, 0.9), Color(0.98, 0.85, 0.2), Color(0.62, 0.42, 0.88)]
const FLOWER_HEIGHT := Vector2(0.3, 0.45)


## Fills area (metres on XZ: position.x = min X, position.y = min Z) with grass and
## flowers where is_free.call(Vector3) is true. Returns the shared grass material.
static func build(root: Node3D, area: Rect2, is_free: Callable, seed: int) -> ShaderMaterial:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var material := ShaderMaterial.new()
	material.shader = GRASS_SHADER
	var chunks := {}
	var x := area.position.x
	while x < area.end.x:
		var z := area.position.y
		while z < area.end.y:
			# Every roll is made even where no grass grows, so the layout stays stable.
			var pos := Vector3(x + rng.randf_range(-JITTER, JITTER), 0.0,
				z + rng.randf_range(-JITTER, JITTER))
			var yaw := rng.randf() * TAU
			var scl := rng.randf_range(MIN_SCALE, MAX_SCALE)
			var tint: Color = TIP_COLORS[0].lerp(TIP_COLORS[1], rng.randf())
			if is_free.call(pos):
				var key := Vector2i(floori(pos.x / CHUNK), floori(pos.z / CHUNK))
				if not chunks.has(key):
					chunks[key] = []
				var basis := Basis(Vector3.UP, yaw).scaled(Vector3.ONE * scl)
				chunks[key].append([Transform3D(basis, pos), tint])
			z += SPACING
		x += SPACING
	var tuft := _tuft_mesh()
	for key in chunks:
		_add_multimesh(root, tuft, material, chunks[key], true)
	_add_flowers(root, area, is_free, rng)
	return material


## Moves the point the grass bends away from (the player).
static func set_pusher(material: ShaderMaterial, pos: Vector3) -> void:
	material.set_shader_parameter("pusher", pos)


## One tuft: BLADES triangles leaning out in spread directions; UV.y is 0 at the base
## and 1 at the tip (the shader bends and colours by it).
static func _tuft_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in BLADES:
		var angle := TAU * i / BLADES + 0.4 * i
		var out := Vector3(cos(angle), 0.0, sin(angle))
		var side := Vector3(-out.z, 0.0, out.x) * (BLADE_WIDTH / 2.0)
		var base := out * 0.05
		var tip := out * BLADE_LEAN + Vector3.UP * BLADE_HEIGHT
		st.set_uv(Vector2(0.0, 0.0))
		st.add_vertex(base - side)
		st.set_uv(Vector2(1.0, 0.0))
		st.add_vertex(base + side)
		st.set_uv(Vector2(0.5, 1.0))
		st.add_vertex(tip)
	st.generate_normals()
	return st.commit()


## Small low-poly flower heads among the blades (the blades hide the stems).
static func _add_flowers(root: Node3D, area: Rect2, is_free: Callable, \
		rng: RandomNumberGenerator) -> void:
	var items := []
	for i in roundi(area.get_area() * FLOWERS_PER_M2):
		var pos := Vector3(rng.randf_range(area.position.x, area.end.x),
			rng.randf_range(FLOWER_HEIGHT.x, FLOWER_HEIGHT.y),
			rng.randf_range(area.position.y, area.end.y))
		var color: Color = FLOWER_COLORS[rng.randi() % FLOWER_COLORS.size()]
		if is_free.call(pos):
			items.append([Transform3D(Basis(), pos), color])
	var head := SphereMesh.new()
	head.radius = 0.05
	head.height = 0.1
	head.radial_segments = 6
	head.rings = 3
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 1.0
	_add_multimesh(root, head, material, items, false)


## items holds [Transform3D, Color]; the colour goes to INSTANCE_CUSTOM (grass shader)
## when custom is true, else to the instance colour (vertex colour of the material).
static func _add_multimesh(root: Node3D, mesh: Mesh, material: Material, items: Array, \
		custom: bool) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = custom
	mm.use_colors = not custom
	mm.mesh = mesh
	mm.instance_count = items.size()
	for i in items.size():
		mm.set_instance_transform(i, items[i][0])
		if custom:
			mm.set_instance_custom_data(i, items[i][1])
		else:
			mm.set_instance_color(i, items[i][1])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = material
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mmi)
```

- [ ] **Step 3: Add grass to `WorldStage`**

In `scripts/world/world_stage.gd`:

1. Change the class doc comment:

```gdscript
## Builds the world map from primitives: a 60 x 60 m grass field with a dirt path
## from the spawn point (south) to the village of Villaclaro in a clearing (north),
## rocks and invisible walls with collision, and hills outside the field. Same sky and
## sun as battles.
```

to:

```gdscript
## Builds the world map from primitives: a 60 x 60 m field of tall grass (Vegetation)
## with a bare dirt path from the spawn point (south) to the village of Villaclaro in a
## clearing (north), rocks and invisible walls with collision, and hills outside the
## field. Same sky and sun as battles.
```

2. After `const PATH_HALF_WIDTH := 1.5` add:

```gdscript
## Tall grass covers this area (a bit past the invisible walls so the edge never looks
## bare), except the path and clearing (plus GRASS_PATH_MARGIN) and the rocks.
const GRASS_AREA := Rect2(-36, -36, 72, 72)
const GRASS_SEED := 7
const GRASS_PATH_MARGIN := 0.3
const GRASS_ROCK_MARGIN := 0.2
## Floor under the tall grass: darker than the battle field so gaps read as shade.
const GRASS_FLOOR := Color(0.22, 0.4, 0.15)
```

3. Replace `build()`:

```gdscript
static func build(root: Node3D) -> void:
	BattleStage.build_environment(root)
	_add_ground(root)
	_add_path(root)
	for rock in ROCKS:
		_add_rock(root, rock[0], rock[1])
	_add_village(root)
	for hill in HILLS:
		BattleStage.add_mesh(root, BattleStage.unit_sphere(), BattleStage.HILL, hill[0], hill[1])
	_add_walls(root)
```

with:

```gdscript
## Returns the tall grass material, so the world can bend it away from the player.
static func build(root: Node3D) -> ShaderMaterial:
	BattleStage.build_environment(root)
	_add_ground(root)
	_add_path(root)
	for rock in ROCKS:
		_add_rock(root, rock[0], rock[1])
	_add_village(root)
	for hill in HILLS:
		BattleStage.add_mesh(root, BattleStage.unit_sphere(), BattleStage.HILL, hill[0], hill[1])
	_add_walls(root)
	return Vegetation.build(root, GRASS_AREA, is_grass_free, GRASS_SEED)
```

4. Replace `is_on_path()`:

```gdscript
## True on the dirt path, the clearing and around the spawn point: no encounters there.
static func is_on_path(pos: Vector3) -> bool:
	var p := Vector2(pos.x, pos.z)
	if p.distance_to(Vector2(SPAWN_POS.x, SPAWN_POS.z)) < SPAWN_RADIUS:
		return true
	if p.distance_to(Vector2(CLEARING_POS.x, CLEARING_POS.z)) < CLEARING_RADIUS:
		return true
	for i in PATH_POINTS.size() - 1:
		var a := Vector2(PATH_POINTS[i].x, PATH_POINTS[i].z)
		var b := Vector2(PATH_POINTS[i + 1].x, PATH_POINTS[i + 1].z)
		if p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b)) < PATH_HALF_WIDTH:
			return true
	return false
```

with:

```gdscript
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
	var p := Vector2(pos.x, pos.z)
	for rock in ROCKS:
		var scl: Vector3 = rock[1]
		var center := Vector2(rock[0].x, rock[0].z)
		if p.distance_to(center) < maxf(scl.x, scl.z) + GRASS_ROCK_MARGIN:
			return false
	return true
```

5. In `_add_ground()`, change:

```gdscript
	BattleStage.add_mesh(root, mesh, BattleStage.GRASS, Vector3.ZERO)
```

to:

```gdscript
	BattleStage.add_mesh(root, mesh, GRASS_FLOOR, Vector3.ZERO)
```

- [ ] **Step 4: Bend the grass away from the player in `World`**

In `scripts/world/world.gd`:

1. After `var _meter: EncounterMeter`, add:

```gdscript
var _grass: ShaderMaterial
```

2. In `_ready()`, change:

```gdscript
	WorldStage.build(self)
```

to:

```gdscript
	_grass = WorldStage.build(self)
```

3. At the very top of `_physics_process()`, before `if _waiting or _talking:`, add:

```gdscript
	Vegetation.set_pusher(_grass, _player.global_position)
```

so that it begins:

```gdscript
func _physics_process(_delta: float) -> void:
	Vegetation.set_pusher(_grass, _player.global_position)
	if _waiting or _talking:
		return
```

- [ ] **Step 5: Import and check**

`Vegetation` is a new `class_name`, so refresh the class cache first:

```powershell
.\tools\godot.cmd --headless --path . --import
.\tools\godot.cmd --headless --path . --check-only --script res://scripts/world/vegetation.gd
.\tools\godot.cmd --headless --path . --check-only --script res://scripts/world/world_stage.gd
.\tools\godot.cmd --headless --path . --check-only --script res://scripts/world/world.gd
```

Each must exit 0 with no ERROR. The import must not print a shader compile error for `grass.gdshader`.

If GDScript rejects the bare `is_grass_free` as a Callable inside the static `build()`, use `Callable(WorldStage, "is_grass_free")` instead and note it in the report.

- [ ] **Step 6: Look at it and measure the frame rate**

Frames:

```powershell
New-Item -ItemType Directory -Force "$env:TEMP\grass1" | Out-Null
.\tools\godot.cmd --path . --write-movie "$env:TEMP\grass1\f.png" --fixed-fps 10 --quit-after 300 res://scenes/world/world.tscn -- --autoplay
```

Open about 4 frames, two of them about one second apart (`f00000100.png` and `f00000110.png`). Check that:

- tall grass covers the field;
- the path, the clearing and the spawn are bare;
- no grass grows inside rocks;
- the hero stays visible;
- the blades move between the two close frames (wind);
- the grass next to the hero leans away from it;
- white, yellow and purple flowers show.

Delete the folder afterwards:

```powershell
Remove-Item -Recurse -Force "$env:TEMP\grass1"
```

Frame rate (real time, windowed):

```powershell
.\tools\godot.cmd --path . --print-fps --quit-after 1200 res://scenes/world/world.tscn -- --autoplay
```

Read the `Project FPS:` lines once the map is running. The target is 60.

If it stays clearly below 60, apply the spec's fallback in order and measure again after each:

1. `SPACING := 0.8`;
2. `BLADES := 4`.

Report the FPS you measured and any fallback you applied.

- [ ] **Step 7: Commit**

```powershell
git add shaders/grass.gdshader scripts/world/vegetation.gd scripts/world/vegetation.gd.uid scripts/world/world_stage.gd scripts/world/world.gd
git commit -m "Cover the world map with tall swaying grass and flowers that bend around the hero"
```

If the import created other `.uid` files for the new files (for example `shaders/grass.gdshader.uid`), add them too.

---

### Task 3: Grass in battle, docs, web export and full run

**Files:**
- Modify: `scripts/battle/battle_stage.gd`
- Modify: `CLAUDE.md`

**Interfaces:**
- Consumes: `Vegetation.build(root: Node3D, area: Rect2, is_free: Callable, seed: int) -> ShaderMaterial` from Task 2.

- [ ] **Step 1: Add grass around the battle in `BattleStage`**

In `scripts/battle/battle_stage.gd`:

1. Change the class doc comment:

```gdscript
## Builds the battle backdrop from primitives: sky, warm sun, fog, grass field,
## dirt path, rocks and distant hills. The environment and mesh helpers are shared
## with WorldStage.
```

to:

```gdscript
## Builds the battle backdrop from primitives: sky, warm sun, fog, grass field with
## tall grass (Vegetation) around the fighters, dirt path, rocks and distant hills. The
## environment and mesh helpers are shared with WorldStage.
```

2. After the `HILLS` constant, add:

```gdscript
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
```

3. Replace `build()`:

```gdscript
static func build(root: Node3D) -> void:
	build_environment(root)
	var ground := PlaneMesh.new()
	ground.size = Vector2(160, 160)
	add_mesh(root, ground, GRASS, Vector3.ZERO)
	var path := PlaneMesh.new()
	path.size = Vector2(2.6, 30)
	add_mesh(root, path, DIRT, Vector3(-0.2, 0.01, -0.3), Vector3.ONE, Vector3(0, -21, 0))
	for rock in ROCKS:
		add_mesh(root, unit_sphere(), ROCK, rock[0], rock[1])
	for hill in HILLS:
		add_mesh(root, unit_sphere(), HILL, hill[0], hill[1])
```

with:

```gdscript
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
		add_mesh(root, unit_sphere(), ROCK, rock[0], rock[1])
	for hill in HILLS:
		add_mesh(root, unit_sphere(), HILL, hill[0], hill[1])
	Vegetation.build(root, GRASS_AREA, _is_grass_free, GRASS_SEED)
```

4. Add this function after `unit_sphere()`:

```gdscript
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
		var scl: Vector3 = rock[1]
		if p.distance_to(Vector2(rock[0].x, rock[0].z)) < maxf(scl.x, scl.z) + GRASS_MARGIN:
			return false
	return true
```

If GDScript rejects the bare `_is_grass_free` as a Callable inside the static `build()`, use `Callable(BattleStage, "_is_grass_free")` and note it in the report. Use the same form Task 2 ended up using for `is_grass_free`.

- [ ] **Step 2: Check the script**

```powershell
.\tools\godot.cmd --headless --path . --check-only --script res://scripts/battle/battle_stage.gd
```

It must exit 0 with no ERROR.

- [ ] **Step 3: Update `CLAUDE.md`**

In the Layout list:

1. Replace the `follow_camera.gd` line:

```markdown
- `scripts/world/follow_camera.gd` (`FollowCamera`) — third-person follow (6 m back, 3.5 m up), Q / E turn it, `snap()`.
```

with:

```markdown
- `scripts/world/follow_camera.gd` (`FollowCamera`) — top-down follow: fixed 55° pitch from the south (looks north, never turns), 14 m away, mouse wheel zooms 9–20 m, `snap()`.
- `scripts/world/vegetation.gd` (`Vegetation`) + `shaders/grass.gdshader` — static builder of tall grass and flowers: `build(root, area, is_free, seed)` fills an XZ rect with jittered tufts in 12 × 12 m `MultiMesh` chunks plus flower heads, returns the shared grass material (wind sway); `set_pusher(material, pos)` bends the grass away from a point.
```

2. In the `player.gd` line, replace:

```markdown
WASD / arrows relative to `FollowCamera.yaw`,
```

with:

```markdown
WASD / arrows in screen axes (up = −Z),
```

3. In the `world_stage.gd` line, replace:

```markdown
static builder of the 60 × 60 m field: dirt path
```

with:

```markdown
static builder of the 60 × 60 m field of tall grass (`Vegetation`; `is_grass_free()`, `build()` returns the grass material, which `World` pushes away from the player each frame): dirt path
```

and replace:

```markdown
`is_on_path(pos)` (path, clearing and spawn area are safe)
```

with:

```markdown
`is_on_path(pos, margin)` (path, clearing and spawn area are safe)
```

4. In the `battle_stage.gd` line, replace:

```markdown
— battle backdrop builder;
```

with:

```markdown
— battle backdrop builder (tall grass around the fighters, none where they stand);
```

- [ ] **Step 4: Full autoplay run**

```powershell
.\tools\godot.cmd --headless --path . --fixed-fps 10 --quit-after 15000 -- --autoplay
```

The quest must run through as before:

- the old woman's lines;
- "Misión: slimes 1 / 3" … "Misión cumplida";
- "¡El Rey Slime te cierra el paso!".

There must be no ERROR or WARNING, apart from the known Jolt one.

- [ ] **Step 5: Look at a battle**

```powershell
New-Item -ItemType Directory -Force "$env:TEMP\grass2" | Out-Null
.\tools\godot.cmd --path . --write-movie "$env:TEMP\grass2\f.png" --fixed-fps 10 --quit-after 900 -- --autoplay
```

Find a frame from inside a battle; the first random battle starts within the first ~60 s. Check that:

- tall grass surrounds the battle;
- none covers the hero, the slime or the lower part of the screen;
- the battle path stays bare.

Delete the folder afterwards:

```powershell
Remove-Item -Recurse -Force "$env:TEMP\grass2"
```

- [ ] **Step 6: Web export**

```powershell
.\tools\godot.cmd --headless --path . --export-release "Web" build/web/index.html
```

It must finish with no ERROR. Note the size of `build/web/index.pck` in the report. `build/` is not committed.

- [ ] **Step 7: Commit**

```powershell
git add scripts/battle/battle_stage.gd CLAUDE.md
git commit -m "Add tall grass around battles and document the top-down camera and vegetation"
```
