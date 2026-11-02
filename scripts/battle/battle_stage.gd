class_name BattleStage extends RefCounted
## Builds the battle backdrop from primitives: sky, warm sun, fog, grass field,
## dirt path, rocks and distant hills. The environment and mesh helpers are shared
## with WorldStage.

const GRASS := Color(0.32, 0.55, 0.22)
const DIRT := Color(0.62, 0.5, 0.34)
const ROCK := Color(0.5, 0.5, 0.52)
const HILL := Color(0.27, 0.47, 0.22)
const HAZE := Color(0.78, 0.84, 0.92)

## [position, scale] of each rock (unit spheres).
const ROCKS := [
	[Vector3(-5.5, 0.3, -6.0), Vector3(1.2, 0.8, 1.0)],
	[Vector3(4.5, 0.4, -8.0), Vector3(1.6, 1.1, 1.3)],
	[Vector3(6.5, 0.2, -2.5), Vector3(0.8, 0.5, 0.7)],
	[Vector3(-7.0, 0.5, -12.0), Vector3(2.0, 1.4, 1.6)],
	[Vector3(2.5, 0.15, -4.5), Vector3(0.5, 0.35, 0.45)],
]
## [position, scale] of each hill (unit spheres, half buried).
const HILLS := [
	[Vector3(-26, -4, -48), Vector3(22, 9, 22)],
	[Vector3(18, -5, -55), Vector3(28, 10, 20)],
	[Vector3(48, -6, -25), Vector3(20, 8, 20)],
	[Vector3(-50, -5, -15), Vector3(20, 8, 24)],
]


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


static func unit_sphere() -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	return mesh


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
