class_name SourceWell extends Node3D
## Node: the Fuente de la Niebla (3.3.0): a ring of old stones round a pool of blue light that
## breathes (its light and its pool swell and sink every BREATH seconds), a faint column of light
## over it and the mist that rises from it (ZoneParticles.WELL_MIST; none on low quality).
## BrumaclaraStage puts one on the map at ZoneData.source_pos, solid to the hero and the monsters;
## V3Backdrops one behind the enemies of the "fuente" backdrop (solid false, before add_child).

const STONE := Color(0.3, 0.31, 0.38)
const WATER := Color(0.4, 0.66, 1.0)
const GLOW := Color(0.55, 0.78, 1.0)
## The ring: RIM_STONES blocks round a circle of RIM_RADIUS, RIM_HEIGHT tall; the pool inside.
const RIM_RADIUS := 2.4
const RIM_HEIGHT := 0.6
const RIM_STONES := 14
const POOL_RADIUS := 2.1
## The column of light over the pool: its height and its opacity at the top of a breath.
const COLUMN_HEIGHT := 7.0
const COLUMN_ALPHA := 0.14
## Seconds of one breath; the light's energy at its lowest and its highest, its reach and height.
const BREATH := 4.0
const LIGHT_ENERGY := Vector2(0.8, 2.8)
const LIGHT_RANGE := 14.0
const LIGHT_HEIGHT := 1.6

var solid := true

var _light: OmniLight3D
var _pool: StandardMaterial3D
var _column: StandardMaterial3D
var _time := 0.0


func _ready() -> void:
	if solid:
		var body := StaticBody3D.new()
		add_child(body)
		WorldStage.add_cylinder_shape(body, RIM_RADIUS, RIM_HEIGHT)
	var stone := BoxMesh.new()
	stone.size = Vector3(1.1, RIM_HEIGHT, 0.7)
	var stones: Array[Transform3D] = []
	for i in RIM_STONES:
		var angle := TAU * i / RIM_STONES
		stones.append(Transform3D(Basis(Vector3.UP, angle),
			Vector3(sin(angle), 0, cos(angle)) * RIM_RADIUS + Vector3(0, RIM_HEIGHT / 2.0, 0)))
	LowPoly.add_multimesh(self, stone, stones, _material(STONE, false))
	_pool = _material(WATER, true)
	var pool := MeshInstance3D.new()
	pool.mesh = LowPoly.disc(POOL_RADIUS)
	pool.material_override = _pool
	pool.position.y = RIM_HEIGHT * 0.7
	add_child(pool)
	_column = _material(Color(GLOW, COLUMN_ALPHA), true)
	_column.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_column.cull_mode = BaseMaterial3D.CULL_DISABLED
	var column := MeshInstance3D.new()
	column.mesh = LowPoly.cylinder(POOL_RADIUS * 0.75, COLUMN_HEIGHT)
	column.material_override = _column
	column.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	column.position.y = RIM_HEIGHT + COLUMN_HEIGHT / 2.0
	add_child(column)
	_light = OmniLight3D.new()
	_light.light_color = GLOW
	_light.omni_range = LIGHT_RANGE
	_light.shadow_enabled = false
	_light.position.y = LIGHT_HEIGHT
	add_child(_light)
	var mist := ZoneParticles.build(ZoneParticles.WELL_MIST)
	if mist != null:
		add_child(mist)
	_breathe(0.0)


func _process(delta: float) -> void:
	_time += delta
	_breathe(_time)


## The Fuente at time t: at the bottom of a breath every BREATH seconds, at its top halfway.
func _breathe(t: float) -> void:
	var breath := 0.5 - 0.5 * cos(TAU * t / BREATH)
	_light.light_energy = lerpf(LIGHT_ENERGY.x, LIGHT_ENERGY.y, breath)
	_pool.albedo_color = WATER.lerp(Color.WHITE, 0.35 * breath)
	_column.albedo_color.a = COLUMN_ALPHA * (0.4 + 0.6 * breath)


static func _material(color: Color, unshaded: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	if unshaded:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material
