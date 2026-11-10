class_name ZoneParticles extends RefCounted
## The particles that float around the hero on a map (ZoneData.particles): pollen and
## dandelion seeds in the meadow, leaves falling slowly in the forest, dust motes that the
## lantern lights in the mine, flakes of violet mist in the castle. A CPUParticles3D (the
## same on the Compatibility renderer and on the web) in world space: World carries its
## box (BOX, 30 × 20 m around the hero; the mine's is smaller, the lantern's reach) along
## every physics tick with follow(), and what is already floating stays where it is. Never
## in battle (World is hidden) or on the title (it has no World). DisplaySettings sets
## enabled (false on low quality: no particles) and half (a phone: half as many); a change
## shows on the next map built.

const POLLEN := "pollen"
const LEAVES := "leaves"
const DUST := "dust"
const MIST := "mist"
## Half extents, along X and Z, of the box the particles are born in around the hero.
const BOX := Vector3(15.0, 0.0, 10.0)
## Share of a particle's life spent fading in, and again fading out.
const FADE := 0.15
## Each kind: how many, the seconds each one lives, the height of the box's centre over the
## hero's feet and half the box's height ("depth"), the size of one (a leaf is 0.6 as tall
## as wide), [least, most] speed, the way they drift ("direction", "spread" degrees around
## it), spin in degrees a second (leaves), the two colours they are picked between, lit
## (shaded: only the light of the scene shows them) and round (a soft dot instead of a flat
## quad); "box" replaces BOX.
const KINDS := {
	POLLEN: {"amount": 80, "lifetime": 9.0, "height": 1.4, "depth": 1.2, "size": 0.09,
		"speed": [0.15, 0.35], "direction": Vector3(1.0, 0.15, 0.3), "spread": 60.0,
		"spin": 0.0, "colors": [Color(1.0, 1.0, 0.95, 0.9), Color(1.0, 0.88, 0.3, 0.9)],
		"lit": false, "round": true},
	LEAVES: {"amount": 50, "lifetime": 10.0, "height": 5.0, "depth": 0.8, "size": 0.2,
		"speed": [0.45, 0.6], "direction": Vector3(0.3, -1.0, 0.15), "spread": 20.0,
		"spin": 90.0, "colors": [Color(0.36, 0.55, 0.2), Color(0.78, 0.55, 0.2)],
		"lit": true, "round": false},
	DUST: {"amount": 60, "lifetime": 6.0, "height": 1.5, "depth": 1.2, "size": 0.04,
		"speed": [0.03, 0.1], "direction": Vector3.UP, "spread": 180.0, "spin": 0.0,
		"colors": [Color(1.0, 0.92, 0.75, 0.85), Color(0.9, 0.86, 0.8, 0.6)],
		"lit": true, "round": true, "box": Vector3(7.0, 0.0, 5.0)},
	MIST: {"amount": 40, "lifetime": 11.0, "height": 1.0, "depth": 0.8, "size": 0.45,
		"speed": [0.2, 0.4], "direction": Vector3(1.0, 0.1, 0.2), "spread": 30.0,
		"spin": 0.0, "colors": [Color(0.7, 0.55, 0.95, 0.45), Color(0.85, 0.75, 1.0, 0.35)],
		"lit": false, "round": true},
}

## No particles at all while false (low quality). Set by DisplaySettings.
static var enabled := true
## Half as many (a phone). Set by DisplaySettings.
static var half := false


## The particles of kind for World to carry with follow(): a Node3D named "Particles" with
## the CPUParticles3D as its only child, at the kind's height; already full (preprocess).
## null for "", an unknown kind, or while not enabled.
static func build(kind: String) -> Node3D:
	if not enabled or not KINDS.has(kind):
		return null
	var spec: Dictionary = KINDS[kind]
	var holder := Node3D.new()
	holder.name = "Particles"
	var parts := CPUParticles3D.new()
	parts.position.y = spec.height
	parts.amount = maxi(1, int(spec.amount) / (2 if half else 1))
	parts.lifetime = spec.lifetime
	parts.preprocess = spec.lifetime
	parts.local_coords = false
	parts.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	var box: Vector3 = spec.get("box", BOX)
	parts.emission_box_extents = Vector3(box.x, spec.depth, box.z)
	parts.direction = (spec.direction as Vector3).normalized()
	parts.spread = spec.spread
	parts.gravity = Vector3.ZERO
	parts.initial_velocity_min = spec.speed[0]
	parts.initial_velocity_max = spec.speed[1]
	var spin: float = spec.spin
	parts.angle_min = 0.0
	parts.angle_max = 360.0 if spin > 0.0 else 0.0
	parts.angular_velocity_min = -spin
	parts.angular_velocity_max = spin
	parts.scale_amount_min = 0.7
	parts.scale_amount_max = 1.3
	parts.color_initial_ramp = _pick(spec.colors)
	parts.color_ramp = _fade()
	parts.mesh = _mesh(spec)
	holder.add_child(parts)
	return holder


## Carries the box to pos (the hero's feet). jump: the hero was put somewhere else at once
## (an entry, a game loaded, the portal), so the particles start over there, already full.
static func follow(holder: Node3D, pos: Vector3, jump := false) -> void:
	holder.global_position = pos
	if jump:
		(holder.get_child(0) as CPUParticles3D).restart()


## A quad that always faces the camera, coloured by the particle, see-through; a soft round
## dot unless the kind is a leaf.
static func _mesh(spec: Dictionary) -> QuadMesh:
	var size: float = spec.size
	var is_round: bool = spec.round
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size) if is_round else Vector2(size, size * 0.6)
	var mat := StandardMaterial3D.new()
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.billboard_keep_scale = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if not spec.lit:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if is_round:
		mat.albedo_texture = _dot()
	quad.material = mat
	return quad


## A white dot fading to clear at its edge (built for each map: no static resource is left
## at exit).
static func _dot() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color.WHITE)
	gradient.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 32
	texture.height = 32
	return texture


## Each particle is born one of the two colours, never a mix (constant interpolation).
static func _pick(colors: Array) -> Gradient:
	var gradient := Gradient.new()
	gradient.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	gradient.offsets = PackedFloat32Array([0.0, 0.5])
	gradient.colors = PackedColorArray([colors[0], colors[1]])
	return gradient


## Over its life a particle fades in for FADE of it and out for the last FADE.
static func _fade() -> Gradient:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, FADE, 1.0 - FADE, 1.0])
	gradient.colors = PackedColorArray([Color(1.0, 1.0, 1.0, 0.0), Color.WHITE, Color.WHITE,
		Color(1.0, 1.0, 1.0, 0.0)])
	return gradient
