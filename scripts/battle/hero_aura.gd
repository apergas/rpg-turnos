class_name HeroAura extends Node3D
## Node: the golden aura of the hero at the game's top level (M-107, 3.8.0; Leveling.at_max()):
## a see-through, flame-like envelope wider than him at the feet and taller than his head
## (shaders/hero_aura.gdshader: additive, no shadow, soft edges, noise tongues that rise and
## break up at its top, breathing every BREATH_S) and golden sparks that rise from his feet
## past his head
## (CPUParticles3D: SPARKS at a time, PHONE_SPARKS on a phone and none on low quality, as
## ZoneParticles.half and .enabled say). Its owner builds it with build() and hangs it on the
## hero's BattleActor: Player on the map (the cutscenes move that same figure), BattleScene in
## battle. flash() is a short burst of light, when he reaches the top level in a battle. Only
## the hero wears it. It makes no light and keeps no game state.

const SHADER := preload("res://shaders/hero_aura.gdshader")
## Pale gold, the same on the map and in battle (a 3D colour: not a UiTokens value).
const COLOR := Color(1.0, 0.6, 0.2)
## The envelope: a capsule RADIUS wide (the shader widens its feet), HEIGHT_SHARE times the
## figure's top_height() tall (where the damage numbers go: a little over the head).
const RADIUS := 0.5
const HEIGHT_SHARE := 1.5
const SIDES := 16
const RINGS := 4
const STRENGTH := 0.85
const BREATH_S := 2.0
## The sparks: how many at a time, how long each lives, how big, how wide the ring at the feet
## they start from and how far up (share of the top) they fade.
const SPARKS := 20
const PHONE_SPARKS := 10
const SPARK_LIFETIME := 1.6
const SPARK_SIZE := 0.045
const SPARK_RING := 0.5
const SPARK_RISE := 1.4
## The flash: the glow FLASH_PEAK times stronger, back to STRENGTH in FLASH_S seconds.
const FLASH_PEAK := 6.0
const FLASH_S := 0.8

var _material: ShaderMaterial
var _sparks: CPUParticles3D = null


## Builds the envelope and the sparks round a figure top metres tall.
func build(top: float) -> void:
	var height := top * HEIGHT_SHARE
	var capsule := CapsuleMesh.new()
	capsule.radius = RADIUS
	capsule.height = height
	capsule.radial_segments = SIDES
	capsule.rings = RINGS
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_material.set_shader_parameter("aura_color", COLOR)
	_material.set_shader_parameter("strength", STRENGTH)
	_material.set_shader_parameter("height", height)
	_material.set_shader_parameter("breath_s", BREATH_S)
	var shell := MeshInstance3D.new()
	shell.mesh = capsule
	shell.material_override = _material
	shell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shell.position.y = height * 0.5 - 0.1
	add_child(shell)
	if ZoneParticles.enabled:
		_add_sparks(top, PHONE_SPARKS if ZoneParticles.half else SPARKS)


## A short burst of light, then the aura as always (BattleScene, after the level-up to the top
## level). The node must be in the tree.
func flash() -> void:
	create_tween().tween_method(_set_strength, STRENGTH * FLASH_PEAK, STRENGTH, FLASH_S)
	if _sparks != null:
		_sparks.restart()


func _set_strength(value: float) -> void:
	_material.set_shader_parameter("strength", value)


## count golden dots that rise from a ring at the feet and shrink to nothing by the head.
func _add_sparks(top: float, count: int) -> void:
	_sparks = CPUParticles3D.new()
	_sparks.amount = count
	_sparks.lifetime = SPARK_LIFETIME
	_sparks.local_coords = true
	_sparks.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	_sparks.emission_ring_axis = Vector3.UP
	_sparks.emission_ring_radius = SPARK_RING
	_sparks.emission_ring_inner_radius = SPARK_RING * 0.5
	_sparks.emission_ring_height = 0.0
	_sparks.direction = Vector3.UP
	_sparks.spread = 8.0
	_sparks.gravity = Vector3.ZERO
	_sparks.initial_velocity_max = top * SPARK_RISE / SPARK_LIFETIME
	_sparks.initial_velocity_min = _sparks.initial_velocity_max * 0.8
	var fade := Curve.new()
	fade.add_point(Vector2(0, 1))
	fade.add_point(Vector2(1, 0))
	_sparks.scale_amount_curve = fade
	var dot := QuadMesh.new()
	dot.size = Vector2.ONE * SPARK_SIZE
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.albedo_color = Color(1.0, 0.85, 0.5)
	dot.material = mat
	_sparks.mesh = dot
	_sparks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_sparks)
