class_name PalmModels extends RefCounted
## The jungle palms: the Kenney Nature Kit models (assets/nature/, CC0) merged into one
## mesh per id, scaled to the size the jungle wants (5-6 m tall, a clump's palms 3-4 m: the top-down camera sits about 11 m up, so taller crowns covered the screen).
## Each mesh has two surfaces (trunk, fronds) with a plain colour: the kit's fronds are
## teal, so they are tinted green to sit with the KayKit greens. The meshes of a model
## (the detailed palms keep their fronds in child meshes) are merged with their own
## transforms.

const TRUNK_COLOR := Color(0.56, 0.38, 0.22)
const FROND_COLOR := Color(0.3, 0.68, 0.2)
## The kit's palms are stocky: the models are squeezed this much sideways.
const TRUNK_SLIM := 0.75

## id → [[model, scale, position, yaw]] (the palms the mesh holds).
const PALMS := {
	"palm_A": [["tree_palmDetailedTall", 4.7, Vector3.ZERO, 0.0]],
	"palm_B": [["tree_palmBend", 3.9, Vector3.ZERO, 0.6]],
	"palms_clump": [
		["tree_palmDetailedShort", 3.8, Vector3(0.0, 0.0, 0.0), 0.3],
		["tree_palmShort", 3.0, Vector3(1.3, 0.0, 0.7), 2.2],
		["tree_palmDetailedShort", 3.4, Vector3(-0.9, 0.0, 1.1), 4.1],
	],
}

static var _cache: Dictionary = {}


static func has(id: String) -> bool:
	return PALMS.has(id)


static func mesh(id: String) -> ArrayMesh:
	if not _cache.has(id):
		var trunk := SurfaceTool.new()
		trunk.begin(Mesh.PRIMITIVE_TRIANGLES)
		var fronds := SurfaceTool.new()
		fronds.begin(Mesh.PRIMITIVE_TRIANGLES)
		for palm: Array in PALMS[id]:
			var model := (load("res://assets/nature/%s.glb" % palm[0]) as PackedScene).instantiate()
			var placing := Transform3D(Basis(Vector3.UP, palm[3]).scaled(Vector3(palm[1] * TRUNK_SLIM, palm[1], palm[1] * TRUNK_SLIM)), palm[2])
			_append(model, Transform3D.IDENTITY, placing, trunk, fronds)
			model.free()
		var result := ArrayMesh.new()
		for pair in [[trunk, TRUNK_COLOR], [fronds, FROND_COLOR]]:
			var st: SurfaceTool = pair[0]
			st.generate_normals()
			st.commit(result)
			var material := StandardMaterial3D.new()
			material.albedo_color = pair[1]
			material.roughness = 1.0
			material.cull_mode = BaseMaterial3D.CULL_DISABLED
			result.surface_set_material(result.get_surface_count() - 1, material)
		_cache[id] = result
	return _cache[id]


## Adds every surface of node's meshes (and its children's) to the trunk or the fronds:
## the kit's trunks are the warm surfaces, the fronds the cool ones.
static func _append(node: Node, parent: Transform3D, placing: Transform3D, trunk: SurfaceTool,
		fronds: SurfaceTool) -> void:
	var here := parent
	if node is Node3D and node.get_parent() != null:
		here = parent * (node as Node3D).transform
	if node is MeshInstance3D:
		var source := (node as MeshInstance3D).mesh
		for i in source.get_surface_count():
			var material := source.surface_get_material(i) as BaseMaterial3D
			var warm := material != null and material.albedo_color.r > material.albedo_color.g
			(trunk if warm else fronds).append_from(source, i, placing * here)
	for child in node.get_children():
		_append(child, here, placing, trunk, fronds)


static func clear_cache() -> void:
	_cache.clear()
