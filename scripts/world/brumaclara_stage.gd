class_name BrumaclaraStage extends RefCounted
## Constructor: what a village of the v3 adds to its map (3.0.0, Brumaclara): its lighthouse
## (Lighthouse, at ZoneData.lighthouse_pos, lit or not) and its lit windows (a warm glow on the
## wall and a small light in front of it, ZoneData.window_lights) and its forge (a stone hearth
## with its chimney and an anvil, ZoneData.forge_pos; a fire on the hearth once forge_lit); and
## darken(), the dark tint of its houses (ZoneData.building_tint; also BeyondScreen's).
## WorldStage.build() calls build() on every open map; it adds nothing where those fields are empty.
## Static only, keeps no state.

const WINDOW_LIGHT := Color(1.0, 0.8, 0.45)
const WINDOW_SIZE := Vector2(0.45, 0.6)
const WINDOW_ENERGY := 0.6
const WINDOW_RANGE := 4.0
## How far in front of its wall a window's light stands.
const WINDOW_LIGHT_OFFSET := 0.8
## The forge: its stone and its iron, and [centre in the forge's own axes (+Z its front),
## size, colour] of each block: the hearth, the chimney behind it, the anvil's foot and its top.
const FORGE_STONE := Color(0.32, 0.31, 0.36)
const FORGE_IRON := Color(0.16, 0.16, 0.19)
const FORGE_BLOCKS := [
	[Vector3(0, 0.45, 0), Vector3(1.6, 0.9, 1.1), FORGE_STONE],
	[Vector3(0, 1.75, -0.35), Vector3(0.8, 2.6, 0.45), FORGE_STONE],
	[Vector3(0.95, 0.3, 0.95), Vector3(0.3, 0.6, 0.3), FORGE_IRON],
	[Vector3(0.95, 0.68, 0.95), Vector3(0.75, 0.16, 0.34), FORGE_IRON],
]
## The fire on the hearth (in the forge's own axes), its size, where its light hangs from it
## and how far the light reaches.
const FORGE_FIRE := Vector3(0, 0.95, 0.1)
const FORGE_FIRE_SIZE := 1.4
const FORGE_FIRE_LIGHT := Vector3(0, 0.5, 0.9)
const FORGE_FIRE_RANGE := 7.0


static func build(root: Node3D, zone: ZoneData) -> void:
	if zone.lighthouse_pos != Vector3.ZERO:
		var lighthouse := Lighthouse.new()
		lighthouse.lit = zone.lighthouse_lit
		lighthouse.position = zone.lighthouse_pos
		root.add_child(lighthouse)
	for window: Array in zone.window_lights:
		_add_window(root, window[0], window[1])
	if zone.forge_pos != Vector3.ZERO:
		_add_forge(root, zone.forge_pos, zone.forge_yaw, zone.forge_lit)


## Every mesh of model in tint times its own colours (its texture stays).
static func darken(model: Node3D, tint: Color) -> void:
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		for s in mi.mesh.get_surface_count():
			var material := mi.get_active_material(s)
			if material is BaseMaterial3D:
				var dark := material.duplicate() as BaseMaterial3D
				dark.albedo_color *= tint
				mi.set_surface_override_material(s, dark)


## A lit window on a wall facing yaw (degrees; 0 faces +Z, like a building's door).
static func _add_window(root: Node3D, pos: Vector3, yaw: float) -> void:
	var quad := QuadMesh.new()
	quad.size = WINDOW_SIZE
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = WINDOW_LIGHT
	var glow := MeshInstance3D.new()
	glow.mesh = quad
	glow.material_override = material
	glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	glow.position = pos
	glow.rotation_degrees.y = yaw
	root.add_child(glow)
	var light := OmniLight3D.new()
	light.light_color = WINDOW_LIGHT
	light.light_energy = WINDOW_ENERGY
	light.omni_range = WINDOW_RANGE
	light.shadow_enabled = false
	light.position = pos + Basis(Vector3.UP, deg_to_rad(yaw)) * Vector3(0, 0, WINDOW_LIGHT_OFFSET)
	root.add_child(light)


## The forge at pos, its front facing yaw (degrees; 0 faces +Z): every block solid to the hero;
## lit, a fire on the hearth (the campfires' Flame) with its warm light in front.
static func _add_forge(root: Node3D, pos: Vector3, yaw: float, lit: bool) -> void:
	var forge := StaticBody3D.new()
	forge.position = pos
	forge.rotation_degrees.y = yaw
	root.add_child(forge)
	for block: Array in FORGE_BLOCKS:
		var box := BoxMesh.new()
		box.size = block[1]
		BattleStage.add_mesh(forge, box, block[2], block[0])
		var shape := CollisionShape3D.new()
		shape.shape = BoxShape3D.new()
		(shape.shape as BoxShape3D).size = block[1]
		shape.position = block[0]
		forge.add_child(shape)
	if lit:
		BattleStage.add_flame(forge, FORGE_FIRE, FORGE_FIRE_SIZE, FORGE_FIRE_LIGHT,
			not BattleStage.plain_light, FORGE_FIRE_RANGE)
