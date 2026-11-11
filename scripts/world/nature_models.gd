class_name NatureModels extends RefCounted
## The Kenney Nature Kit decoration (assets/nature/, CC0): every Decor id is one mesh merged
## from one or more kit models, ONE surface (the kit's materials baked into vertex colours), retinted so the pieces sit with
## the KayKit models: the kit's teal greens become the zone's green, its woods, stones and
## flower colours the softer PALETTE. Each kit model is centred on its own footprint and
## lifted out of the 0.05 its node sinks it. Cached per id and green.

const MEADOW_GREEN := Color(0.3, 0.55, 0.18)
## The kit's materials that are a green (all of them become the zone's green).
const GREENS := ["grass", "leafsGreen", "leafsDark"]
## The kit's other materials → the colour they take (closer to the KayKit browns and greys).
const PALETTE := {
	"woodBark": Color(0.45, 0.3, 0.19),
	"woodInner": Color(0.78, 0.66, 0.48),
	"wood": Color(0.58, 0.4, 0.25),
	"woodDark": Color(0.4, 0.27, 0.17),
	"woodBarkDark": Color(0.62, 0.46, 0.32),
	"stone": Color(0.55, 0.54, 0.52),
	"dirt": Color(0.5, 0.37, 0.23),
	"dirtDark": Color(0.4, 0.29, 0.18),
	"corn": Color(0.9, 0.74, 0.38),
	"leafsFall": Color(0.86, 0.5, 0.2),
	"colorRed": Color(0.8, 0.24, 0.22),
	"colorYellow": Color(0.95, 0.78, 0.3),
	"colorPurple": Color(0.58, 0.44, 0.82),
	"colorTan": Color(0.82, 0.62, 0.42),
	"_defaultMat": Color(0.92, 0.88, 0.8),
}
## How deep the kit sinks every model in its node, in kit units.
const KIT_SINK := 0.05
## id → [[kit model, scale, position, yaw]] (the models the mesh holds).
const PIECES := {
	"flowers": [["flower_redA", 2.0, Vector3.ZERO, 0.0],
		["flower_yellowB", 2.0, Vector3(0.45, 0, 0.25), 1.3],
		["flower_purpleA", 2.0, Vector3(-0.3, 0, 0.4), 2.6]],
	"mushroom": [["mushroom_red", 2.4, Vector3.ZERO, 0.0]],
	"mushrooms_red": [["mushroom_redGroup", 2.4, Vector3.ZERO, 0.0]],
	"mushrooms_tan": [["mushroom_tanGroup", 2.4, Vector3.ZERO, 0.0]],
	"fern": [["plant_flatTall", 3.0, Vector3.ZERO, 0.0]],
	"leafy": [["grass_leafsLarge", 3.0, Vector3.ZERO, 0.0]],
	"stump": [["stump_roundDetailed", 3.0, Vector3.ZERO, 0.0]],
	"stump_tall": [["stump_oldTall", 3.0, Vector3.ZERO, 0.0]],
	"log": [["log_large", 3.0, Vector3.ZERO, 0.0]],
	"log_stack": [["log_stackLarge", 3.0, Vector3.ZERO, 0.0]],
	"pot": [["pot_large", 3.0, Vector3.ZERO, 0.0]],
	"fence": [["fence_simple", 3.0, Vector3.ZERO, 0.0]],
	"fence_gate": [["fence_gate", 3.0, Vector3.ZERO, 0.0]],
	"row_wheat": [["crops_dirtRow", 3.0, Vector3.ZERO, 0.0],
		["crops_wheatStageB", 2.6, Vector3(-0.75, 0, 0), 0.0],
		["crops_wheatStageB", 2.6, Vector3(0.75, 0, 0), 0.4]],
	"row_corn": [["crops_dirtRow", 3.0, Vector3.ZERO, 0.0],
		["crops_cornStageD", 2.2, Vector3(-0.8, 0, 0), 0.0],
		["crops_cornStageD", 2.2, Vector3(0.8, 0, 0), 2.0]],
	"row_pumpkin": [["crops_dirtRow", 3.0, Vector3.ZERO, 0.0],
		["crop_pumpkin", 2.4, Vector3(-0.7, 0, 0), 0.0],
		["crop_pumpkin", 2.4, Vector3(0.7, 0, 0), 1.7]],
	"row_carrot": [["crops_dirtRow", 3.0, Vector3.ZERO, 0.0],
		["crop_carrot", 2.4, Vector3(-0.9, 0, 0), 0.0],
		["crop_carrot", 2.4, Vector3(0, 0, 0), 1.1],
		["crop_carrot", 2.4, Vector3(0.9, 0, 0), 2.3]],
	"campfire": [["campfire_stones", 3.0, Vector3.ZERO, 0.0],
		["campfire_logs", 3.0, Vector3(0, 0.03, 0), 0.5]],
}

static var _cache: Dictionary = {}
static var _arrays: Dictionary = {}


static func has(id: String) -> bool:
	return PIECES.has(id)


## The mesh of piece id: ONE surface whose vertex colours hold the kit's materials already
## retinted (sRGB), so a piece costs one draw. Its material reads them
## (vertex_color_use_as_albedo); WorldStage swaps it for the trees' shader.
static func mesh(id: String, green: Color) -> ArrayMesh:
	var key := "%s/%s" % [id, green.to_html()]
	if not _cache.has(key):
		var data := {"vertices": PackedVector3Array(), "normals": PackedVector3Array(),
			"colors": PackedColorArray(), "indices": PackedInt32Array()}
		for piece: Array in PIECES[id]:
			var model := (load("res://assets/nature/%s.glb" % piece[0]) as PackedScene).instantiate()
			var center := _footprint_center(model)
			var placing := Transform3D(Basis(Vector3.UP, piece[3]).scaled(Vector3.ONE * piece[1]),
				piece[2]) * Transform3D(Basis.IDENTITY, Vector3(-center.x, KIT_SINK, -center.z))
			_append(model, Transform3D.IDENTITY, placing, green, data)
			model.free()
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = data.vertices
		arrays[Mesh.ARRAY_NORMAL] = data.normals
		arrays[Mesh.ARRAY_COLOR] = data.colors
		arrays[Mesh.ARRAY_INDEX] = data.indices
		var result := ArrayMesh.new()
		result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var material := StandardMaterial3D.new()
		material.vertex_color_use_as_albedo = true
		material.vertex_color_is_srgb = true
		material.roughness = 1.0
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		result.surface_set_material(0, material)
		_cache[key] = result
	return _cache[key]


## One mesh holding every item of items ({"id", "xform"}), each piece's own mesh moved by its
## transform: a whole chunk of static decoration drawn at once.
static func merged(items: Array, green: Color) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for item: Dictionary in items:
		var key := "%s/%s" % [item.id, green.to_html()]
		if not _arrays.has(key):
			_arrays[key] = mesh(item.id, green).surface_get_arrays(0)
		var source: Array = _arrays[key]
		var xform: Transform3D = item.xform
		var normal_basis := xform.basis.inverse().transposed()
		var base := vertices.size()
		for v: Vector3 in source[Mesh.ARRAY_VERTEX]:
			vertices.append(xform * v)
		for n: Vector3 in source[Mesh.ARRAY_NORMAL]:
			normals.append((normal_basis * n).normalized())
		colors.append_array(source[Mesh.ARRAY_COLOR])
		for i: int in source[Mesh.ARRAY_INDEX]:
			indices.append(base + i)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var result := ArrayMesh.new()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return result


## The middle of the model's meshes on the ground (x, z), in kit units.
static func _footprint_center(model: Node) -> Vector3:
	var box := AABB()
	var first := true
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var instance := node as MeshInstance3D
		var local := instance.transform
		var parent := instance.get_parent()
		while parent != null and parent != model and parent is Node3D:
			local = (parent as Node3D).transform * local
			parent = parent.get_parent()
		var mesh_box := local * instance.mesh.get_aabb()
		box = mesh_box if first else box.merge(mesh_box)
		first = false
	return box.get_center()


## Adds every surface of node's meshes (and its children's) to data with node's transform,
## coloured by its kit material (the zone's green, or the PALETTE).
static func _append(node: Node, parent: Transform3D, placing: Transform3D, green: Color,
		data: Dictionary) -> void:
	var here := parent
	if node is Node3D and node.get_parent() != null:
		here = parent * (node as Node3D).transform
	if node is MeshInstance3D:
		var source := (node as MeshInstance3D).mesh
		var xform := placing * here
		var normal_basis := xform.basis.inverse().transposed()
		for i in source.get_surface_count():
			var material := source.surface_get_material(i)
			var name := material.resource_name if material != null else "_defaultMat"
			var color: Color = green if GREENS.has(name) else PALETTE.get(name, Color.WHITE)
			var arrays := source.surface_get_arrays(i)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var base: int = data.vertices.size()
			for v in vertices:
				data.vertices.append(xform * v)
				data.colors.append(color)
			for n in normals:
				data.normals.append((normal_basis * n).normalized())
			if arrays[Mesh.ARRAY_INDEX] != null:
				for index: int in arrays[Mesh.ARRAY_INDEX]:
					data.indices.append(base + index)
			else:
				for index in vertices.size():
					data.indices.append(base + index)
	for child in node.get_children():
		_append(child, here, placing, green, data)


static func clear_cache() -> void:
	_cache.clear()
	_arrays.clear()
