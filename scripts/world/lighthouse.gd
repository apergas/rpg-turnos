class_name Lighthouse extends Node3D
## Node: Brumaclara's lighthouse (BrumaclaraStage builds it at ZoneData.lighthouse_pos; 3.0.0):
## a stone tower with two dark bands, a gallery, a lantern room and a red roof, solid to the
## hero, its door to the south. lit (ZoneData.lighthouse_lit, the Garza beaten): the lantern
## glows, a warm light reaches the square and a beam of light sweeps round slowly; unlit, the
## lantern room is dark glass.

const STONE := Color(0.46, 0.45, 0.5)
const STONE_DARK := Color(0.3, 0.29, 0.34)
const ROOF := Color(0.36, 0.13, 0.13)
const GLASS_DARK := Color(0.12, 0.14, 0.2)
const GLASS_LIT := Color(1.0, 0.9, 0.6)
const LIGHT := Color(1.0, 0.92, 0.75)
const TOWER_HEIGHT := 8.0
const LANTERN_Y := 9.0
const COLLIDER_RADIUS := 1.8
const LIGHT_ENERGY := 3.0
const LIGHT_RANGE := 24.0
## The beam: two cones lying on their side from the lantern, turning BEAM_TURNS times a second.
const BEAM_LENGTH := 20.0
const BEAM_ALPHA := 0.16
const BEAM_TURNS := 0.1

var lit := false

var _beam: Node3D


func _ready() -> void:
	var body := StaticBody3D.new()
	add_child(body)
	WorldStage.add_cylinder_shape(body, COLLIDER_RADIUS, TOWER_HEIGHT)
	var tower := CylinderMesh.new()
	tower.top_radius = 1.25
	tower.bottom_radius = 1.7
	tower.height = TOWER_HEIGHT
	tower.radial_segments = 10
	BattleStage.add_mesh(self, tower, STONE, Vector3(0, TOWER_HEIGHT / 2.0, 0))
	for y in [2.6, 5.4]:
		var band := CylinderMesh.new()
		var radius := lerpf(1.7, 1.25, y / TOWER_HEIGHT) + 0.04
		band.top_radius = radius
		band.bottom_radius = radius
		band.height = 0.35
		band.radial_segments = 10
		BattleStage.add_mesh(self, band, STONE_DARK, Vector3(0, y, 0))
	var gallery := LowPoly.cylinder(1.75, 0.3)
	BattleStage.add_mesh(self, gallery, STONE_DARK, Vector3(0, TOWER_HEIGHT + 0.15, 0))
	var room := BattleStage.add_mesh(self, LowPoly.cylinder(0.95, 1.5),
		GLASS_LIT if lit else GLASS_DARK, Vector3(0, LANTERN_Y, 0))
	if lit:
		(room.material_override as StandardMaterial3D).shading_mode = \
			BaseMaterial3D.SHADING_MODE_UNSHADED
	BattleStage.add_mesh(self, LowPoly.cone(1.3, 1.4), ROOF, Vector3(0, LANTERN_Y + 1.45, 0))
	var door := BoxMesh.new()
	door.size = Vector3(0.9, 1.6, 0.2)
	BattleStage.add_mesh(self, door, STONE_DARK, Vector3(0, 0.8, 1.62))
	if lit:
		_add_light()


func _process(delta: float) -> void:
	if _beam:
		_beam.rotation.y += delta * TAU * BEAM_TURNS


## The lantern's light and the beam that turns round it.
func _add_light() -> void:
	var light := OmniLight3D.new()
	light.light_color = LIGHT
	light.light_energy = LIGHT_ENERGY
	light.omni_range = LIGHT_RANGE
	light.shadow_enabled = false
	light.position.y = LANTERN_Y
	add_child(light)
	_beam = Node3D.new()
	_beam.position.y = LANTERN_Y
	add_child(_beam)
	var cone := CylinderMesh.new()
	cone.top_radius = 0.2
	cone.bottom_radius = 2.4
	cone.height = BEAM_LENGTH
	cone.cap_top = false
	cone.cap_bottom = false
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = Color(LIGHT, BEAM_ALPHA)
	for side in [-1.0, 1.0]:
		var half := MeshInstance3D.new()
		half.mesh = cone
		half.material_override = material
		half.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# Lying along ±X with its narrow end at the lantern.
		half.rotation_degrees.z = 90.0 * side
		half.position.x = side * BEAM_LENGTH / 2.0
		_beam.add_child(half)
