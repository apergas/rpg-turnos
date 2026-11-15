class_name Crystals extends RefCounted
## Constructor: the glowing crystals of the Cuevas de cristal (3.1.0; ZoneData.crystals). A
## cluster of crystal points growing from a cave wall that lights the floor round it
## (add_cluster(): DungeonMap puts one on each T cell instead of a torch, V3Backdrops on the
## walls of the Cuevas' battles), the bars of a crystal gate (add_bars(), DungeonMap's D cells)
## and the knob of the lever (KNOB). Blue or violet by a shade index. Static only, keeps no
## game state: its static vars cache the one crystal mesh and its two materials.

## Side profile of one crystal point (lathed around +Y, SIDES sides): a hexagonal prism with
## a point, PROFILE_HEIGHT tall at scale 1.
const PROFILE: Array[Vector2] = [
	Vector2(0.0, 0.0), Vector2(0.09, 0.0), Vector2(0.1, 0.32), Vector2(0.06, 0.42),
	Vector2(0.0, 0.5),
]
const PROFILE_HEIGHT := 0.5
const SIDES := 6
## The two colours of the crystals (by shade index, wrapping round) and how much they glow.
const COLORS: Array[Color] = [Color(0.45, 0.72, 1.0), Color(0.72, 0.52, 1.0)]
const EMISSION := 0.8
## A cluster's light: how bright, how far it reaches, and where it hangs (out from the wall
## and up from the floor).
const LIGHT_ENERGY := 2.2
const LIGHT_RANGE := 9.0
const LIGHT_OUT := 0.9
const LIGHT_HEIGHT := 1.4
## The points of a cluster: [along the wall, up from the floor, out from the wall, tilt out of
## the wall in degrees, size]: three big ones on the floor, two smaller up the wall.
const CLUSTER := [
	[0.0, 0.0, 0.2, 12.0, 2.4], [-0.5, 0.0, 0.15, 28.0, 1.6], [0.45, 0.0, 0.2, 22.0, 1.8],
	[-0.25, 1.5, 0.0, 65.0, 1.1], [0.3, 2.0, 0.0, 75.0, 0.9],
]
## The knob on the lever's handle (DungeonMap), in the crystals' light blue.
const KNOB := Color(0.55, 0.85, 1.0)
## Crystals across a gate, and how thick each one is (times the profile).
const BAR_COUNT := 7
const BAR_THICKNESS := 1.6

static var _mesh: ArrayMesh
static var _materials := {}


## The mesh of one crystal point, made once.
static func mesh() -> ArrayMesh:
	if _mesh == null:
		_mesh = LowPoly.blob(PROFILE, SIDES)
	return _mesh


## The glowing material of the colour shade picks (any int: it wraps round COLORS), made once.
static func material(shade: int) -> StandardMaterial3D:
	var index := posmod(shade, COLORS.size())
	if not _materials.has(index):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = COLORS[index]
		mat.emission_enabled = true
		mat.emission = COLORS[index]
		mat.emission_energy_multiplier = EMISSION
		mat.roughness = 0.25
		_materials[index] = mat
	return _materials[index]


## A cluster of crystals growing from a wall: at_wall is the foot of the wall on the floor,
## out the unit step from the wall into the cell, shade the colour; with light, a light of its
## colour hangs in front of it.
static func add_cluster(root: Node3D, at_wall: Vector3, out: Vector3, shade: int,
		light := true) -> void:
	var along := out.cross(Vector3.UP)
	for point: Array in CLUSTER:
		var crystal := MeshInstance3D.new()
		crystal.mesh = mesh()
		crystal.material_override = material(shade)
		crystal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		crystal.position = at_wall + along * float(point[0]) + Vector3.UP * float(point[1]) \
			+ out * float(point[2])
		# Turned about the wall's line, so its point leans out of the wall.
		crystal.basis = Basis(along, -deg_to_rad(point[3])).scaled(Vector3.ONE * float(point[4]))
		root.add_child(crystal)
	if light:
		var glow := OmniLight3D.new()
		glow.light_color = COLORS[posmod(shade, COLORS.size())]
		glow.light_energy = LIGHT_ENERGY
		glow.omni_range = LIGHT_RANGE
		glow.position = at_wall + out * LIGHT_OUT + Vector3.UP * LIGHT_HEIGHT
		root.add_child(glow)


## The bars of a crystal gate: BAR_COUNT tall crystals across width, height tall, under body
## (the gate's node, already turned across its corridor; they hide with it).
static func add_bars(body: Node3D, width: float, height: float) -> void:
	for i in BAR_COUNT:
		var bar := MeshInstance3D.new()
		bar.mesh = mesh()
		bar.material_override = material(i)
		bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		bar.position = Vector3(-width / 2.0 + width * (i + 0.5) / BAR_COUNT, 0.0, 0.0)
		var tall := height / PROFILE_HEIGHT * (0.85 if i % 2 == 0 else 1.0)
		bar.scale = Vector3(BAR_THICKNESS, tall, BAR_THICKNESS)
		body.add_child(bar)
