class_name Vegetation extends RefCounted
## Builds tall grass and flowers from code. Grass tufts (BLADES blades each) go on
## a jittered grid wherever is_free says so, split into CHUNK-sized MultiMeshes so the
## camera skips the ones it does not see. The same seed always gives the same layout.
## The returned material sways with the wind; set_pusher() bends it away from a point.

const GRASS_SHADER := preload("res://shaders/grass.gdshader")
const BLADES := 7
const BLADE_WIDTH := 0.12
const BLADE_HEIGHT := 0.7
## How far each blade's tip leans out from the tuft centre.
const BLADE_LEAN := 0.2
const SPACING := 0.45
const JITTER := 0.2
const MIN_SCALE := 0.8
const MAX_SCALE := 1.3
const CHUNK := 12.0
## Two tip greens (sRGB, saturated); every tuft gets a mix of them.
const TIP_COLORS := [Color(0.22, 0.55, 0.12), Color(0.42, 0.72, 0.16)]
const FLOWERS_PER_M2 := 300.0 / 3600.0
const FLOWER_COLORS := [Color(0.95, 0.95, 0.9), Color(0.98, 0.85, 0.2), Color(0.62, 0.42, 0.88)]
const FLOWER_HEIGHT := Vector2(0.6, 0.85)


## Fills area (metres on XZ: position.x = min X, position.y = min Z) with grass and
## flowers where is_free.call(Vector3) is true. Returns the shared grass material.
static func build(root: Node3D, area: Rect2, is_free: Callable, seed: int) -> ShaderMaterial:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var material := ShaderMaterial.new()
	material.shader = GRASS_SHADER
	var chunks := {}
	var x := area.position.x
	while x < area.end.x:
		var z := area.position.y
		while z < area.end.y:
			# Every roll is made even where no grass grows, so the layout stays stable.
			var pos := Vector3(x + rng.randf_range(-JITTER, JITTER), 0.0,
				z + rng.randf_range(-JITTER, JITTER))
			var yaw := rng.randf() * TAU
			var scl := rng.randf_range(MIN_SCALE, MAX_SCALE)
			# Custom data skips the sRGB conversion that base_color gets, so convert here.
			var tint: Color = TIP_COLORS[0].lerp(TIP_COLORS[1], rng.randf()).srgb_to_linear()
			if is_free.call(pos):
				var key := Vector2i(floori(pos.x / CHUNK), floori(pos.z / CHUNK))
				if not chunks.has(key):
					chunks[key] = []
				var basis := Basis(Vector3.UP, yaw).scaled(Vector3.ONE * scl)
				chunks[key].append([Transform3D(basis, pos), tint])
			z += SPACING
		x += SPACING
	var tuft := _tuft_mesh()
	for key in chunks:
		_add_multimesh(root, tuft, material, chunks[key], true)
	_add_flowers(root, area, is_free, rng)
	return material


## Moves the point the grass bends away from (the player).
static func set_pusher(material: ShaderMaterial, pos: Vector3) -> void:
	material.set_shader_parameter("pusher", pos)


## One tuft: BLADES triangles leaning out in spread directions; UV.y is 0 at the base
## and 1 at the tip (the shader bends and colours by it).
static func _tuft_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in BLADES:
		var angle := TAU * i / BLADES + 0.4 * i
		var out := Vector3(cos(angle), 0.0, sin(angle))
		var side := Vector3(-out.z, 0.0, out.x) * (BLADE_WIDTH / 2.0)
		var base := out * 0.05
		var tip := out * BLADE_LEAN + Vector3.UP * BLADE_HEIGHT
		st.set_uv(Vector2(0.0, 0.0))
		st.add_vertex(base - side)
		st.set_uv(Vector2(1.0, 0.0))
		st.add_vertex(base + side)
		st.set_uv(Vector2(0.5, 1.0))
		st.add_vertex(tip)
	st.generate_normals()
	return st.commit()


## Small low-poly flower heads just above the blades (no stems).
static func _add_flowers(root: Node3D, area: Rect2, is_free: Callable, \
		rng: RandomNumberGenerator) -> void:
	var items := []
	for i in roundi(area.get_area() * FLOWERS_PER_M2):
		var pos := Vector3(rng.randf_range(area.position.x, area.end.x),
			rng.randf_range(FLOWER_HEIGHT.x, FLOWER_HEIGHT.y),
			rng.randf_range(area.position.y, area.end.y))
		var color: Color = FLOWER_COLORS[rng.randi() % FLOWER_COLORS.size()]
		if is_free.call(pos):
			items.append([Transform3D(Basis(), pos), color])
	var head := SphereMesh.new()
	head.radius = 0.065
	head.height = 0.13
	head.radial_segments = 6
	head.rings = 3
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 1.0
	_add_multimesh(root, head, material, items, false)


## items holds [Transform3D, Color]; the colour goes to INSTANCE_CUSTOM (grass shader)
## when custom is true, else to the instance colour (vertex colour of the material).
static func _add_multimesh(root: Node3D, mesh: Mesh, material: Material, items: Array, \
		custom: bool) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = custom
	mm.use_colors = not custom
	mm.mesh = mesh
	mm.instance_count = items.size()
	for i in items.size():
		mm.set_instance_transform(i, items[i][0])
		if custom:
			mm.set_instance_custom_data(i, items[i][1])
		else:
			mm.set_instance_color(i, items[i][1])
	var mmi := MultiMeshInstance3D.new()
	# The shader moves blade tips up to ~0.33 m outside the chunk AABB.
	mmi.extra_cull_margin = 0.5
	mmi.multimesh = mm
	mmi.material_override = material
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mmi)
