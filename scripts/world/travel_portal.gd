class_name TravelPortal extends Node3D
## The Ala de viaje's portal in the village (World.set_portal(); 2.5.0): a dark-blue swirling
## disc (portal_swirl.gdshader) with a light-blue corona of rays around it, like an eclipse,
## sparks rising from its edge (none on low quality, half on a phone: the ZoneParticles
## flags) and a soft blue light that pulses with it; the "Portal" sign over it. ring_only:
## the glowing ring on the ground of the spot it leads back to (World.set_return_mark()).
## Seen from the south, like every figure: it stands in the XY plane.

const SWIRL_SHADER := preload("res://shaders/portal_swirl.gdshader")
## The sparks' colour, the light's colour.
const RUNE := Color(0.6, 0.85, 1.0)
const LIGHT := Color(0.45, 0.65, 1.0)
## The surface (width, height) and its centre's height; the old oval's size.
const SURFACE := Vector2(1.9, 2.7)
const CENTER_Y := 1.9
## The quad is CORONA_SCALE times the swirl's size; the corona (light-blue rays, like the sun's in
## an eclipse) fills the rest. TILT leans it back so the map camera sees more of it.
const CORONA_SCALE := 2.1
const TILT := 20.0
const SPARKS := 24
const PULSE_TIME := 1.2
const ENERGY := 1.2
const LIGHT_RANGE := 6.0
## The ring on the ground.
const MARK_SIZE := 2.2

var ring_only := false

var _light: OmniLight3D
var _time := 0.0


func _ready() -> void:
	if ring_only:
		_add_surface(Vector2.ONE * MARK_SIZE, Vector3(0, 0.05, 0), Vector3(-90, 0, 0), true)
		return
	_add_surface(SURFACE * CORONA_SCALE, Vector3(0, CENTER_Y, 0), Vector3(-TILT, 0, 0), false)
	_add_sparks()
	_light = OmniLight3D.new()
	_light.light_color = LIGHT
	_light.light_energy = ENERGY
	_light.omni_range = LIGHT_RANGE
	_light.position = Vector3(0, CENTER_Y, 0.8)
	add_child(_light)
	var label := Label3D.new()
	label.text = "Portal"
	label.font_size = 48
	label.pixel_size = 0.008
	label.outline_size = 10
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position.y = CENTER_Y + SURFACE.y * CORONA_SCALE / 2.0 + 0.4
	add_child(label)


func _process(delta: float) -> void:
	if _light == null:
		return
	_time += delta
	var pulse := sin(_time * TAU / PULSE_TIME)
	_light.light_energy = ENERGY * (1.0 + 0.15 * pulse)


func _add_surface(quad_size: Vector2, pos: Vector3, rot: Vector3, ring: bool) -> void:
	var quad := QuadMesh.new()
	quad.size = quad_size
	var mat := ShaderMaterial.new()
	mat.shader = SWIRL_SHADER
	mat.set_shader_parameter("ring_only", ring)
	mat.set_shader_parameter("corona", not ring)
	mat.set_shader_parameter("disc", 1.0 / CORONA_SCALE)
	mat.set_shader_parameter("pulse_time", PULSE_TIME)
	var mi := MeshInstance3D.new()
	mi.mesh = quad
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = pos
	mi.rotation_degrees = rot
	add_child(mi)


## Sparks rising from the surface's edge: SPARKS on a desktop, half on a phone, none on low
## quality.
func _add_sparks() -> void:
	if not ZoneParticles.enabled:
		return
	var sparks := CPUParticles3D.new()
	sparks.amount = SPARKS / 2 if ZoneParticles.half else SPARKS
	sparks.lifetime = 1.4
	sparks.position = Vector3(0, CENTER_Y, 0.05)
	sparks.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	sparks.emission_ring_axis = Vector3(0, 0, 1)
	sparks.emission_ring_radius = SURFACE.x / 2.0
	sparks.emission_ring_inner_radius = SURFACE.x / 2.0 - 0.1
	sparks.emission_ring_height = 0.0
	sparks.scale = Vector3(1.0, SURFACE.y / SURFACE.x, 1.0)  # the ring follows the oval
	sparks.direction = Vector3.UP
	sparks.spread = 15.0
	sparks.gravity = Vector3(0, 0.4, 0)
	sparks.initial_velocity_min = 0.2
	sparks.initial_velocity_max = 0.5
	var fade := Gradient.new()
	fade.set_color(0, Color(RUNE, 1.0))
	fade.set_color(1, Color(RUNE, 0.0))
	sparks.color_ramp = fade
	var dot := QuadMesh.new()
	dot.size = Vector2.ONE * 0.05
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.disable_fog = true
	dot.material = mat
	sparks.mesh = dot
	add_child(sparks)
