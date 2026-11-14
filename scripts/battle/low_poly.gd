class_name LowPoly extends RefCounted
## Constructor: static; builds meshes and MultiMesh nodes for its caller and keeps no state.
## Faceted low-poly meshes built in code and a MultiMesh helper. A blob is a lathe of
## rings taken from a side profile, every other ring turned half a segment, with one
## normal per face (flat shading), so it reads as a cut gem instead of a smooth
## sphere. The slimes and the bushes are blobs.
## The primitives (sphere, cylinder, cone, hemisphere, disc) and merged() serve BattleActor's builders.

## Side profile of a bush (x = radius, y = height in metres), bottom to top.
const BUSH_PROFILE: Array[Vector2] = [
	Vector2(0.0, 0.0), Vector2(0.5, 0.0), Vector2(0.7, 0.3), Vector2(0.62, 0.62),
	Vector2(0.34, 0.88), Vector2(0.0, 1.0),
]
const BUSH_SEGMENTS := 7
const BUSH_COLOR := Color(0.18, 0.4, 0.12)


## Lathe of profile around +Y with segments sides and flat normals.
static func blob(profile: Array[Vector2], segments: int) -> ArrayMesh:
	var rings: Array[PackedVector3Array] = []
	for i in profile.size():
		var ring := PackedVector3Array()
		var offset := 0.5 * (i % 2)
		for s in segments:
			var angle := TAU * (s + offset) / segments
			ring.append(Vector3(sin(angle) * profile[i].x, profile[i].y,
				cos(angle) * profile[i].x))
		rings.append(ring)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Smooth group 0xFFFFFFFF: no vertex is shared, every face keeps its own normal.
	st.set_smooth_group(0xFFFFFFFF)
	for i in rings.size() - 1:
		var lo := rings[i]
		var hi := rings[i + 1]
		for s in segments:
			var n := (s + 1) % segments
			_triangle(st, lo[s], hi[s], lo[n])
			_triangle(st, lo[n], hi[s], hi[n])
	st.generate_normals()
	return st.commit()


## A green bush blob 1 m tall with its material on the surface (ready for a MultiMesh).
static func bush_mesh() -> ArrayMesh:
	var mesh := blob(BUSH_PROFILE, BUSH_SEGMENTS)
	var material := StandardMaterial3D.new()
	material.albedo_color = BUSH_COLOR
	material.roughness = 1.0
	mesh.surface_set_material(0, material)
	return mesh


## One MultiMeshInstance3D drawing mesh (with its own surface materials, or override) at
## every transform. Does nothing for an empty list.
static func add_multimesh(root: Node3D, mesh: Mesh, transforms: Array[Transform3D], \
		override: Material = null) -> void:
	if transforms.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = override
	root.add_child(mmi)


## A hemisphere (flat side down) of radius and height, 9 sides and 3 rings.
static func hemisphere(radius: float, height: float) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.is_hemisphere = true
	mesh.radial_segments = 9
	mesh.rings = 3
	return mesh


## A flat round lid (the inside of the plant's mouth).
static func disc(radius: float) -> CylinderMesh:
	var mesh := cylinder(radius, 0.02)
	mesh.radial_segments = 9
	return mesh


## A sphere of radius with 10 sides and 5 rings.
static func sphere(radius: float) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 10
	mesh.rings = 5
	return mesh


## A cylinder of radius and height with 8 sides.
static func cylinder(radius: float, height: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 8
	return mesh


## A cone: a cylinder whose top radius is 0.
static func cone(radius: float, height: float) -> CylinderMesh:
	var mesh := cylinder(radius, height)
	mesh.top_radius = 0.0
	return mesh


## mesh repeated at each of xforms, merged into one mesh (one draw call).
static func merged(mesh: Mesh, xforms: Array[Transform3D]) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for xform in xforms:
		tool.append_from(mesh, 0, xform)
	return tool.commit()


## Skips triangles that collapse at the profile's tips (radius 0).
static func _triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	if a.is_equal_approx(b) or b.is_equal_approx(c) or a.is_equal_approx(c):
		return
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)
