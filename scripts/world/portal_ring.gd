class_name PortalRing extends Node3D
## The portal of the abandoned city (DungeonMap's P cell, and the battle backdrop of the
## portal quarter): a ring of stone standing on two blocks, a see-through red disc, ten
## sparks turning inside it (one mesh, one draw call) and a red light. Angry, it turns fast
## and glows; calm (set_calm()), it turns slowly, its disc goes pale and its light softens.
## The ring stands in the XY plane: it is seen from the south (+Z) and the north alike.

const RADIUS := 2.0
const THICKNESS := 0.55
const DISC := Color(0.95, 0.12, 0.08, 0.55)
const DISC_CALM := Color(0.95, 0.6, 0.55, 0.3)
const SPARK := Color(1.0, 0.35, 0.15)
const SPARK_CALM := Color(1.0, 0.75, 0.65)
const SPARKS := 10
## Radians per second the sparks turn, angry and calm.
const SPIN := 1.6
const SPIN_CALM := 0.35
const LIGHT := Color(1.0, 0.25, 0.15)
const ENERGY := 3.0
const ENERGY_CALM := 1.0
const LIGHT_RANGE := 12.0
## Seconds the portal takes to calm down (set_calm() without instant).
const CALM_TIME := 2.5

## The stone of the ring and its base (set before add_child).
var stone := Color(0.44, 0.4, 0.4)

var _spin: Node3D
var _disc_material: StandardMaterial3D
var _spark_material: StandardMaterial3D
var _light: OmniLight3D
var _speed := SPIN
var _energy := ENERGY
var _time := 0.0
var _calm := false
var _tween: Tween


func _ready() -> void:
	var center := Vector3(0, RADIUS + THICKNESS, 0)
	var ring := TorusMesh.new()
	ring.inner_radius = RADIUS
	ring.outer_radius = RADIUS + THICKNESS
	ring.rings = 16
	ring.ring_segments = 6
	BattleStage.add_mesh(self, ring, stone, center, Vector3.ONE, Vector3(90, 0, 0))
	var block := BoxMesh.new()
	block.size = Vector3(1.4, 0.7, 1.3)
	for x in [-1.5, 1.5]:
		BattleStage.add_mesh(self, block, stone.darkened(0.15), Vector3(x, 0.35, 0))
	var disc := CylinderMesh.new()
	disc.top_radius = RADIUS
	disc.bottom_radius = RADIUS
	disc.height = 0.04
	disc.radial_segments = 24
	_disc_material = _glow(DISC)
	_disc_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_disc_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var disc_mi := MeshInstance3D.new()
	disc_mi.mesh = disc
	disc_mi.material_override = _disc_material
	disc_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	disc_mi.position = center
	disc_mi.rotation_degrees.x = 90.0
	add_child(disc_mi)
	_spin = Node3D.new()
	_spin.position = center
	add_child(_spin)
	var sparks := MeshInstance3D.new()
	sparks.mesh = _sparks_mesh()
	_spark_material = _glow(SPARK)
	sparks.material_override = _spark_material
	sparks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_spin.add_child(sparks)
	_light = OmniLight3D.new()
	_light.light_color = LIGHT
	_light.omni_range = LIGHT_RANGE
	_light.position = center + Vector3(0, 0, 1.5)
	add_child(_light)
	set_calm(_calm, true)


func _process(delta: float) -> void:
	_time += delta
	_spin.rotation.z += _speed * delta
	_light.light_energy = _energy * (1.0 + 0.12 * sin(_time * 5.0))


## Calm (the Devorador beaten and the scene's portal_calmo flag) or angry; instant skips the
## CALM_TIME change (a map built with the flag already set).
func set_calm(on: bool, instant := false) -> void:
	_calm = on
	if _spin == null:
		return  # _ready() applies it
	if _tween:
		_tween.kill()
	var speed := SPIN_CALM if on else SPIN
	var energy := ENERGY_CALM if on else ENERGY
	var disc := DISC_CALM if on else DISC
	var spark := SPARK_CALM if on else SPARK
	if instant or not is_inside_tree():
		_speed = speed
		_energy = energy
		_disc_material.albedo_color = disc
		_spark_material.albedo_color = spark
		return
	_tween = create_tween().set_parallel()
	_tween.tween_property(self, "_speed", speed, CALM_TIME)
	_tween.tween_property(self, "_energy", energy, CALM_TIME)
	_tween.tween_property(_disc_material, "albedo_color", disc, CALM_TIME)
	_tween.tween_property(_spark_material, "albedo_color", spark, CALM_TIME)


## Ten small spheres on a spiral inside the ring, merged into one mesh.
static func _sparks_mesh() -> ArrayMesh:
	var sphere := SphereMesh.new()
	sphere.radius = 0.16
	sphere.height = 0.32
	sphere.radial_segments = 6
	sphere.rings = 3
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in SPARKS:
		var angle := TAU * i / SPARKS
		var r := lerpf(0.5, RADIUS - 0.3, float(i % 5) / 4.0)
		tool.append_from(sphere, 0, Transform3D(Basis(), Vector3(cos(angle) * r,
			sin(angle) * r, 0.0)))
	return tool.commit()


## An unshaded material of color that fog does not dim (the portal glows through the haze).
static func _glow(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.disable_fog = true
	return mat
