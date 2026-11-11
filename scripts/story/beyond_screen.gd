class_name BeyondScreen extends Node3D
## What lies beyond the portal (the v2's ending): a scene built in code, never played. A
## valley of red earth slopes down to the north, a road winds down it to a village of dark
## KayKit houses with smoke rising from them and three warm lights, dark hills close it, the
## sky is red and a black sun with a red corona hangs over it. The hero (with his gear) and
## the companion stand at the head of the road with their backs to us; the camera passes over
## them and closes in on the village for CLOSE_TIME seconds while TEXT fades in. Its sky and
## fog are its camera's own environment, so the map's WorldEnvironment (hidden but still in
## the tree) does not get in the way. await run() returns on Enter or a click (autoplay: after
## AUTOPLAY_WAIT seconds, printing "Más allá: ...").

signal _advanced

const TEXT := "Al otro lado del portal, otro mundo espera..."
const TEXT_SIZE := 34
const CLOSE_TIME := 14.0
const TEXT_DELAY := 3.0
const TEXT_FADE := 2.0
const AUTOPLAY_WAIT := 2.0
## The valley drops this many degrees toward the north (−Z).
const SLOPE_DEG := 4.5
const SKY_TOP := Color(0.16, 0.02, 0.04)
const SKY_HORIZON := Color(1.0, 0.42, 0.16)
const GROUND_HORIZON := Color(0.75, 0.26, 0.12)
const FOG := Color(0.62, 0.2, 0.1)
const EARTH := Color(0.3, 0.1, 0.07)
const ROAD := Color(0.62, 0.28, 0.16)
const HILL := Color(0.17, 0.055, 0.045)
const HOUSE_TINT := Color(0.34, 0.28, 0.3)
const WINDOW_LIGHT := Color(1.0, 0.55, 0.3)
const CORONA := Color(1.0, 0.3, 0.1, 1.0)
const ROAD_WIDTH := 3.2
## The road, from the hero's feet down to the village ([x, z]; y follows the slope).
const ROAD_POINTS := [Vector2(0, 30), Vector2(1.5, 16), Vector2(-2, 0), Vector2(1, -16),
	Vector2(-1.5, -30), Vector2(0.5, -42), Vector2(0, -52)]
## The village: [WorldStage.MODELS key, x, z, yaw]; smoke rises from the first five.
const HOUSES := [["house_A_red", -9, -56, 20.0], ["house_B_red", 7, -58, -30.0],
	["tavern_green", -2, -66, 0.0], ["house_A_green", 14, -68, -60.0],
	["house_B_green", -15, -68, 50.0], ["market_green", 3, -75, 10.0],
	["house_A_red", -8, -80, -15.0], ["house_B_red", 12, -82, 35.0], ["well_red", 1, -61, 0.0]]
const LIGHTS := [Vector2(-7, -53), Vector2(6, -55), Vector2(-1, -63)]
const HILLS := [[Vector3(-70, -14, -110), Vector3(60, 36, 50)],
	[Vector3(72, -14, -120), Vector3(66, 40, 50)], [Vector3(0, -34, -200), Vector3(170, 44, 40)],
	[Vector3(-85, -6, -30), Vector3(40, 28, 70)], [Vector3(85, -6, -30), Vector3(40, 26, 70)]]
## Dead trees (KayKit tree models, tinted black) along the road: [WorldStage.MODELS key, x, z, scale, yaw].
const TREES := [["tree_A", -9.0, 6.0, 2.6, 0.0], ["tree_B", 10.0, -10.0, 2.4, 70.0],
	["tree_A", -12.0, -24.0, 2.8, 140.0], ["tree_B", 8.5, -36.0, 2.2, 200.0],
	["tree_A", -8.0, -46.0, 2.4, 20.0]]
const ROCKS := [[2, -4.0, 12.0, 4.0, 30.0], [0, 5.0, -6.0, 3.5, 100.0],
	[3, -5.0, -28.0, 4.0, 200.0], [1, 4.5, -46.0, 3.0, 280.0]]
const SUN_POS := Vector3(-30, 30, -215)
const SUN_RADIUS := 20.0
const CAMERA_FROM := Vector3(0, 3.6, 30)
const CAMERA_TO := Vector3(0, 5.2, -8)
const HERO_SPOT := Vector2(-0.8, 24)
const ALLY_SPOT := Vector2(0.9, 24.3)
const ACTOR_SCENE := preload("res://scenes/battle/battle_actor.tscn")

var _weapon := ""
var _shield := ""
var _helmet := ""
var _ally_id := ""
var _camera: Camera3D
var _label: Label
var _waiting := false
var _autoplay := false


## What the hero wears and who walks with him (set before add_child).
func setup(weapon: String, shield: String, helmet: String, ally_id: String) -> void:
	_weapon = weapon
	_shield = shield
	_helmet = helmet
	_ally_id = ally_id


func _ready() -> void:
	_autoplay = OS.get_cmdline_user_args().has("--autoplay")
	_build_camera()
	_build_land()
	_build_village()
	_build_sun()
	_build_figures()
	_build_text()


## Moves the camera in, fades the text in and waits for Enter or a click.
func run() -> void:
	var t := create_tween().set_parallel()
	t.tween_method(_place_camera, 0.0, 1.0, CLOSE_TIME) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(_label, "modulate:a", 1.0, TEXT_FADE).set_delay(TEXT_DELAY)
	await t.finished
	if _autoplay:
		print("Más allá: %s" % TEXT)
		await get_tree().create_timer(AUTOPLAY_WAIT).timeout
		return
	_waiting = true
	await _advanced
	_waiting = false


func _unhandled_input(event: InputEvent) -> void:
	if not _waiting:
		return
	var click: bool = event is InputEventMouseButton and event.pressed \
		and event.button_index == MOUSE_BUTTON_LEFT
	if click or (event.is_action_pressed("ui_accept") and not event.is_echo()):
		get_viewport().set_input_as_handled()
		_advanced.emit()


## The height of the valley's ground at z (it drops to the north).
static func ground_y(z: float) -> float:
	return z * tan(deg_to_rad(SLOPE_DEG))


static func _on_ground(x: float, z: float) -> Vector3:
	return Vector3(x, ground_y(z), z)


func _place_camera(t: float) -> void:
	var from := CAMERA_FROM + Vector3(0, ground_y(CAMERA_FROM.z), 0)
	var to := CAMERA_TO + Vector3(0, ground_y(CAMERA_TO.z), 0)
	_camera.position = from.lerp(to, t)
	_camera.look_at(_on_ground(0, -62) + Vector3(0, 4, 0))


func _build_camera() -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = SKY_TOP
	sky_material.sky_horizon_color = SKY_HORIZON
	sky_material.ground_horizon_color = GROUND_HORIZON
	sky_material.ground_bottom_color = HILL
	var sky := Sky.new()
	sky.sky_material = sky_material
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.glow_enabled = true
	env.glow_intensity = 0.35
	env.fog_enabled = true
	env.fog_light_color = FOG
	env.fog_density = 0.0055
	_camera = Camera3D.new()
	_camera.environment = env
	_camera.fov = 55.0
	add_child(_camera)
	_place_camera(0.0)
	_camera.make_current()
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(0.95, 0.5, 0.38)
	sun.light_energy = 0.55
	sun.shadow_enabled = true
	sun.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY  # no bright disc: the sun is black
	sun.rotation_degrees = Vector3(-30, 150, 0)
	add_child(sun)


func _build_land() -> void:
	var ground := PlaneMesh.new()
	ground.size = Vector2(400, 400)
	BattleStage.add_mesh(self, ground, EARTH, Vector3.ZERO, Vector3.ONE,
		Vector3(-SLOPE_DEG, 0, 0))
	for i in ROAD_POINTS.size() - 1:
		var a := _on_ground(ROAD_POINTS[i].x, ROAD_POINTS[i].y) + Vector3(0, 0.03, 0)
		var b := _on_ground(ROAD_POINTS[i + 1].x, ROAD_POINTS[i + 1].y) + Vector3(0, 0.03, 0)
		var strip := BoxMesh.new()
		strip.size = Vector3(ROAD_WIDTH, 0.04, a.distance_to(b) + 2.0)
		var mi := MeshInstance3D.new()
		mi.mesh = strip
		var mat := StandardMaterial3D.new()
		mat.albedo_color = ROAD
		mat.roughness = 1.0
		mi.material_override = mat
		mi.transform = Transform3D(Basis.looking_at(b - a, Vector3.UP), (a + b) / 2.0)
		add_child(mi)
	for hill in HILLS:
		BattleStage.add_mesh(self, BattleStage.unit_sphere(), HILL, hill[0], hill[1])
	for tree in TREES:
		var dead := BattleStage.add_model(self, WorldStage.MODELS[tree[0]],
			_on_ground(tree[1], tree[2]), tree[3], tree[4])
		_darken(dead, Color(0.1, 0.07, 0.07))
	for rock in ROCKS:
		BattleStage.add_model(self, BattleStage.ROCK_SCENES[rock[0]],
			_on_ground(rock[1], rock[2]), rock[3], rock[4])


func _build_village() -> void:
	for i in HOUSES.size():
		var house: Array = HOUSES[i]
		var model := BattleStage.add_model(self, WorldStage.MODELS[house[0]],
			_on_ground(house[1], house[2]), WorldStage.BUILDING_SCALE, house[3])
		_darken(model)
		if i < 5:
			var top := BattleStage.model_aabb(model).end.y * WorldStage.BUILDING_SCALE
			_add_smoke(_on_ground(house[1], house[2]) + Vector3(0.8, top, 0.5))
	for i in 7:
		var house: Array = HOUSES[i]
		_add_windows(_on_ground(house[1], house[2]), house[3])
	for spot in LIGHTS:
		var lamp := OmniLight3D.new()
		lamp.light_color = WINDOW_LIGHT
		lamp.light_energy = 1.5
		lamp.omni_range = 8.0
		lamp.position = _on_ground(spot.x, spot.y) + Vector3(0, 1.5, 0)
		add_child(lamp)


## Two small warm lit windows on the front of a house (they glow in the fog).
func _add_windows(pos: Vector3, yaw: float) -> void:
	var basis := Basis(Vector3.UP, deg_to_rad(yaw))
	for dx in [-0.9, 0.9]:
		var win := MeshInstance3D.new()
		var quad := BoxMesh.new()
		quad.size = Vector3(0.7, 0.8, 0.1)
		win.mesh = quad
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = WINDOW_LIGHT
		win.material_override = mat
		win.position = pos + basis * Vector3(dx, 1.6, 1.55)
		win.rotation_degrees = Vector3(0, yaw, 0)
		add_child(win)


## Every mesh of model in HOUSE_TINT times its own colours (its texture stays).
func _darken(model: Node3D, tint := HOUSE_TINT) -> void:
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		for s in mi.mesh.get_surface_count():
			var mat := mi.get_active_material(s)
			if mat is BaseMaterial3D:
				var dark := mat.duplicate() as BaseMaterial3D
				dark.albedo_color *= tint
				mi.set_surface_override_material(s, dark)


## Grey smoke rising slowly from a chimney and drifting east, already full when shown.
func _add_smoke(pos: Vector3) -> void:
	var smoke := CPUParticles3D.new()
	smoke.amount = 18
	smoke.lifetime = 7.0
	smoke.preprocess = 7.0
	var puff := SphereMesh.new()
	puff.radius = 0.5
	puff.height = 1.0
	puff.radial_segments = 6
	puff.rings = 3
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	puff.material = mat
	smoke.mesh = puff
	smoke.direction = Vector3(0.15, 1, 0)
	smoke.spread = 12.0
	smoke.gravity = Vector3(0.25, 0.35, 0)
	smoke.initial_velocity_min = 0.4
	smoke.initial_velocity_max = 0.8
	smoke.scale_amount_min = 0.8
	smoke.scale_amount_max = 1.4
	var grow := Curve.new()
	grow.add_point(Vector2(0, 0.4))
	grow.add_point(Vector2(1, 2.2))
	smoke.scale_amount_curve = grow
	var fade := Gradient.new()
	fade.set_color(0, Color(0.2, 0.17, 0.17, 0.0))
	fade.add_point(0.15, Color(0.22, 0.2, 0.2, 0.7))
	fade.set_color(fade.get_point_count() - 1, Color(0.3, 0.28, 0.28, 0.0))
	smoke.color_ramp = fade
	smoke.position = pos
	add_child(smoke)


## The black sun: a black ball with a slightly bigger red one behind it (its corona); neither
## is fogged.
func _build_sun() -> void:
	for layer in [[SUN_RADIUS * 1.16, CORONA, Vector3(0, 0, -8)], [SUN_RADIUS, Color.BLACK,
			Vector3.ZERO]]:
		var ball := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = layer[0]
		sphere.height = layer[0] * 2.0
		ball.mesh = sphere
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = layer[1]
		mat.disable_fog = true
		if layer[1].a < 1.0:
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		ball.material_override = mat
		ball.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ball.position = SUN_POS + layer[2]
		add_child(ball)


## The hero and the companion at the head of the road, their backs to the camera (a
## BattleActor faces -Z), still.
func _build_figures() -> void:
	var hero: BattleActor = ACTOR_SCENE.instantiate()
	hero.look = BattleActor.Look.HERO
	hero.position = _on_ground(HERO_SPOT.x, HERO_SPOT.y)
	add_child(hero)
	hero.set_equipment(_weapon, _shield, _helmet)
	if _ally_id != "":
		var ally: BattleActor = ACTOR_SCENE.instantiate()
		ally.look = EnemyLibrary.look(_ally_id)
		ally.position = _on_ground(ALLY_SPOT.x, ALLY_SPOT.y)
		add_child(ally)


func _build_text() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 9  # under Game's fade (10)
	add_child(layer)
	_label = Label.new()
	_label.text = TEXT
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_size_override("font_size", TEXT_SIZE)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 8)
	_label.modulate.a = 0.0
	layer.add_child(_label)
	_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_label.offset_top = -140.0
	_label.offset_bottom = -60.0
	_label.offset_left = 40.0
	_label.offset_right = -40.0
