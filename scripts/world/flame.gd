class_name Flame extends Node3D
## A real-looking flame (2.5.0) for torches and campfires (BattleStage.add_flame()): two
## crossed quads of flame.gdshader, one a little smaller and turned, that face the camera
## around Y and burn with TIME (no CPU cost); embers rising and fading (CPUParticles3D, EMBERS
## for a torch, FIRE_EMBERS for a campfire, half on a phone, none on low quality: the
## ZoneParticles flags); and a warm light whose energy flickers with slow noise. Set the
## fields before add_child. One draw call for the flame, one for the embers.

const FLAME_SHADER := preload("res://shaders/flame.gdshader")
## A quad of size 1 is this big (width, height) on a torch.
const QUAD := Vector2(0.5, 0.7)
const EMBERS := 6
const FIRE_EMBERS := 14
## From this size on it is a campfire (more embers).
const FIRE_SIZE := 1.8
const EMBER_COLOR := Color(1.0, 0.6, 0.2)
const FLICKER := 0.14
const FLICKER_SPEED := 9.0

## How big (1 a torch, 2.2 a campfire); where the light goes from the flame and how far it
## reaches; light_on false: no light (low quality on a campfire).
var size := 1.0
var light_on := true
var light_offset := Vector3(0, 0.2, 1.0)
var light_range := 10.0

var _light: OmniLight3D
var _time := 0.0
var _phase := 0.0


func _ready() -> void:
	_phase = fmod(absf(global_position.x * 1.7 + global_position.z * 2.3), TAU)
	_time = _phase
	var quads := MeshInstance3D.new()
	quads.mesh = _quads_mesh()
	var mat := ShaderMaterial.new()
	mat.shader = FLAME_SHADER
	quads.material_override = mat
	quads.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	quads.scale = Vector3.ONE * size
	# The old sphere was centred on the node: keep the flame's visual centre there.
	quads.position.y = -QUAD.y * size * 0.35
	add_child(quads)
	_add_embers()
	if light_on:
		_light = OmniLight3D.new()
		_light.light_color = DungeonMap.TORCH_COLOR
		_light.light_energy = DungeonMap.TORCH_ENERGY
		_light.omni_range = light_range
		_light.position = light_offset
		add_child(_light)


func _process(delta: float) -> void:
	if _light == null:
		return
	_time += delta
	var wave := sin(_time * FLICKER_SPEED) * 0.5 + sin(_time * 23.0 + _phase) * 0.3 \
		+ sin(_time * 3.1 + _phase * 2.0) * 0.2
	_light.light_energy = DungeonMap.TORCH_ENERGY * (1.0 + FLICKER * wave)


## Two quads, the base at the node's origin: the big one, and a smaller one turned 90° and a
## little forward (it shows when the camera looks along the first, and thickens the core).
static func _quads_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for part in [[QUAD, 0.0], [QUAD * 0.7, 90.0]]:
		var quad := QuadMesh.new()
		quad.size = part[0]
		quad.center_offset = Vector3(0, (part[0] as Vector2).y / 2.0, 0)
		tool.append_from(quad, 0, Transform3D(Basis(Vector3.UP, deg_to_rad(part[1])), Vector3.ZERO))
	return tool.commit()


func _add_embers() -> void:
	if not ZoneParticles.enabled:
		return
	var count := FIRE_EMBERS if size >= FIRE_SIZE else EMBERS
	if ZoneParticles.half:
		count = maxi(1, count / 2)
	var embers := CPUParticles3D.new()
	embers.amount = count
	embers.lifetime = 1.1
	embers.local_coords = false
	embers.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	embers.emission_sphere_radius = 0.06 * size
	embers.position.y = 0.15 * size
	embers.direction = Vector3.UP
	embers.spread = 20.0
	embers.gravity = Vector3(0, 0.6, 0)
	embers.initial_velocity_min = 0.3 * size
	embers.initial_velocity_max = 0.7 * size
	embers.scale_amount_min = 0.5
	embers.scale_amount_max = 1.0
	var fade := Gradient.new()
	fade.set_color(0, EMBER_COLOR)
	fade.set_color(1, Color(EMBER_COLOR, 0.0))
	embers.color_ramp = fade
	var dot := QuadMesh.new()
	dot.size = Vector2.ONE * 0.035 * size
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.disable_fog = true
	dot.material = mat
	embers.mesh = dot
	add_child(embers)
