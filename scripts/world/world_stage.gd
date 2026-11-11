class_name WorldStage extends RefCounted
## Builds one map of the world from its ZoneData: the sky and light of the zone, the
## ground, a field of tall grass (Vegetation) with a bare dirt path and safe discs,
## low-poly buildings and rocks with hand-made colliders, trees (denser toward the walls,
## with trunk colliders) and bushes scattered with fixed seeds, invisible walls and hills
## outside. Exits, figures and chests are World's. A dungeon floor only gets its sky and
## light and its buildings (the castle camp's tents) here: its cells are a DungeonMap,
## which World adds. Every query takes the zone.

## The Medieval Hexagon buildings are miniatures (a house is 0.8 m wide, 0.9 m tall).
const BUILDING_SCALE := 3.5
const TREE_SHADER := preload("res://shaders/tree.gdshader")
## Side of the squares the decoration is merged by (metres): a map holds a few chunks, so the
## whole decoration costs a few draws.
const DECOR_CHUNK := 48.0
## Models named by ZoneData (buildings, tree_models, clump_model).
const MODELS := {
	"house_A_red": preload("res://assets/medieval/building_home_A_red.gltf"),
	"house_B_red": preload("res://assets/medieval/building_home_B_red.gltf"),
	"well_red": preload("res://assets/medieval/building_well_red.gltf"),
	"house_A_green": preload("res://assets/medieval/building_home_A_green.gltf"),
	"house_B_green": preload("res://assets/medieval/building_home_B_green.gltf"),
	"market_green": preload("res://assets/medieval/building_market_green.gltf"),
	"tavern_green": preload("res://assets/medieval/building_tavern_green.gltf"),
	"well_green": preload("res://assets/medieval/building_well_green.gltf"),
	"tree_A": preload("res://assets/medieval/tree_single_A.gltf"),
	"tree_B": preload("res://assets/medieval/tree_single_B.gltf"),
	"trees_A": preload("res://assets/medieval/trees_A_medium.gltf"),
	"trees_B": preload("res://assets/medieval/trees_B_medium.gltf"),
	"tent": preload("res://assets/medieval/tent.gltf"),
}
## Buildings drawn at another scale than BUILDING_SCALE (the tent is a tiny prop).
const MODEL_SCALES := {"tent": 6.0}
## Half the widest side of each building at BUILDING_SCALE (measured AABBs), in metres.
const BUILDING_RADIUS := {
	"house_A_red": 1.5, "house_B_red": 1.9, "well_red": 1.3,
	"house_A_green": 1.5, "house_B_green": 1.9, "well_green": 1.3,
	"market_green": 3.2, "tavern_green": 2.4, "tent": 1.6,
}
## Tall grass keeps this far from the path and the safe discs, the rocks and the chests.
const GRASS_PATH_MARGIN := 0.3
const GRASS_ROCK_MARGIN := 0.2
const GRASS_BUILDING_MARGIN := 0.4
const CHEST_GRASS_MARGIN := 1.0
const FIGURE_GRASS_MARGIN := 1.0
## Trees keep this far from the path, the autoplay route, the rocks, the buildings, the
## chests and the exits; bushes from the path, the rocks and the chests.
const TREE_PATH_MARGIN := 3.0
const TREE_ROUTE_MARGIN := 2.5
const TREE_ROCK_MARGIN := 1.5
const TREE_BUILDING_MARGIN := 2.5
const CHEST_TREE_MARGIN := 2.2
const TREE_EXIT_MARGIN := 3.5
const BUSH_PATH_MARGIN := 0.8
const BUSH_ROCK_MARGIN := 0.6
const CHEST_BUSH_MARGIN := 1.2
const BUSH_SCALE := Vector2(0.7, 1.2)
## Colliders (only inside the walls): a trunk for single trees, a wider one for clumps.
const TRUNK_RADIUS := 0.35
const CLUMP_RADIUS := 2.0
const TREE_COLLIDER_HEIGHT := 3.0

## _near_chest()'s cache: the zone id and its chests' spots on the ground.
static var _chest_zone := ""
static var _chest_spots: Array[Vector2] = []
## Tall grass keeps this far from a small medal (Medals), so the glint shows on the ground;
## _near_medal()'s cache, like _near_chest()'s.
const MEDAL_GRASS_MARGIN := 0.8
## How far decoration keeps from what the game needs (Decor; added to the piece's radius).
## Soft pieces (no collider) may stand closer to the autoplay route: the hero walks through.
const DECOR_PATH_MARGIN := 0.3
const DECOR_ROUTE_MARGIN := 1.5
const DECOR_SOFT_ROUTE_MARGIN := 0.4
const DECOR_EXIT_MARGIN := 3.5
const DECOR_ENTRY_MARGIN := 2.0
const DECOR_PORTAL_MARGIN := 2.5
const DECOR_CHEST_MARGIN := 1.5
const DECOR_MEDAL_MARGIN := 2.0
const DECOR_FIGURE_MARGIN := 1.5
const DECOR_BOSS_MARGIN := 3.0
const DECOR_PROP_MARGIN := 0.4
## Trees keep this far from the pieces placed by hand, bushes and tall grass from every
## placed or solid piece.
const TREE_DECOR_MARGIN := 2.0
const BUSH_DECOR_MARGIN := 0.6
const GRASS_DECOR_MARGIN := 0.3
static var _medal_zone := ""
static var _medal_spots: Array[Vector2] = []
## _tree_layout()'s cache (the zone id and its trees) and near_tree()'s (x, z and the
## collider radius of each tree inside the walls).
static var _layout_zone := ""
static var _layout: Array[Dictionary] = []
static var _tree_zone := ""
static var _tree_spots: Array[Vector3] = []


## Builds zone under root. Returns the tall grass material (null if the zone has no
## grass), so the world can bend it away from the player.
static func build(root: Node3D, zone: ZoneData) -> ShaderMaterial:
	BattleStage.build_environment(root, zone)
	if zone.is_dungeon():
		for building in zone.buildings:
			_add_solid_model(root, MODELS[building[2]], building[0],
				MODEL_SCALES.get(building[2], BUILDING_SCALE), building[1])
		_add_decor(root, zone)
		return null
	_add_ground(root, zone)
	_add_path(root, zone)
	for rock in zone.rocks:
		_add_solid_model(root, BattleStage.ROCK_SCENES[rock[1]], rock[0], rock[2], rock[3])
	for building in zone.buildings:
		_add_solid_model(root, MODELS[building[2]], building[0],
			MODEL_SCALES.get(building[2], BUILDING_SCALE), building[1])
	_add_trees(root, zone)
	_add_bushes(root, zone)
	_add_decor(root, zone)
	for hill in zone.hills:
		BattleStage.add_mesh(root, BattleStage.unit_sphere(), BattleStage.HILL, hill[0], hill[1])
	_add_walls(root, zone)
	if not zone.has_grass:
		return null
	return Vegetation.build(root, _outer_rect(zone), is_grass_free.bind(zone), zone.grass_seed,
		zone.grass_tips)


## True on the dirt path and the safe discs (and in the stair rooms of a dungeon floor):
## no monster groups there. margin widens every one of them (the grass keeps a little off the
## path's edge).
static func is_on_path(zone: ZoneData, pos: Vector3, margin := 0.0) -> bool:
	if zone.is_dungeon() and zone.near_stairs(pos):
		return true
	var p := Vector2(pos.x, pos.z)
	for disc in zone.safe_discs:
		if p.distance_to(Vector2(disc[0].x, disc[0].z)) < disc[1] + margin:
			return true
	var points := zone.path_points
	for i in points.size() - 1:
		var a := Vector2(points[i].x, points[i].z)
		var b := Vector2(points[i + 1].x, points[i + 1].z)
		var closest := Geometry2D.get_closest_point_to_segment(p, a, b)
		if p.distance_to(closest) < zone.path_half_width + margin:
			return true
	return false


## Where tall grass may grow: off the path and the safe discs (the village is inside one),
## the rocks, the buildings, the chests, the figures and the small medals.
static func is_grass_free(pos: Vector3, zone: ZoneData) -> bool:
	if is_on_path(zone, pos, GRASS_PATH_MARGIN) or _near_chest(zone, pos, CHEST_GRASS_MARGIN) \
			or _near_figure(zone, pos) or _near_medal(zone, pos) \
			or Decor.near_solid(zone, pos, GRASS_DECOR_MARGIN):
		return false
	return not _near_rock(zone, pos, GRASS_ROCK_MARGIN) \
		and not _near_building(zone, pos, GRASS_BUILDING_MARGIN)


## True within margin of the trunk (or clump) of a tree inside the walls (MonsterGroups keeps
## the groups off them).
static func near_tree(zone: ZoneData, pos: Vector3, margin: float) -> bool:
	if _tree_zone != zone.id:
		_tree_zone = zone.id
		_tree_spots.clear()
		for tree in _tree_layout(zone):
			if tree.inside:
				_tree_spots.append(Vector3(tree.pos.x, tree.pos.z,
					CLUMP_RADIUS if tree.clump else TRUNK_RADIUS))
	var p := Vector2(pos.x, pos.z)
	for spot in _tree_spots:
		if p.distance_to(Vector2(spot.x, spot.y)) < spot.z + margin:
			return true
	return false


## True if pos is clear by margin of every rock's and building's footprint.
static func is_clear_of_props(zone: ZoneData, pos: Vector3, margin: float) -> bool:
	return not _near_rock(zone, pos, margin) and not _near_building(zone, pos, margin) \
		and not Decor.near_solid(zone, pos, margin)


## Upright cylinder collider standing on the ground, for village props and figures.
static func add_cylinder_shape(body: StaticBody3D, radius: float, height: float) -> void:
	var cylinder := CylinderShape3D.new()
	cylinder.radius = radius
	cylinder.height = height
	var shape := CollisionShape3D.new()
	shape.shape = cylinder
	shape.position = Vector3(0, height / 2.0, 0)
	body.add_child(shape)


## The field plus outer_margin on every side (position.x = min X, position.y = min Z).
static func _outer_rect(zone: ZoneData) -> Rect2:
	var half := zone.half_size + Vector2.ONE * zone.outer_margin
	return Rect2(-half, half * 2.0)


static func _add_ground(root: Node3D, zone: ZoneData) -> void:
	var mesh := PlaneMesh.new()
	mesh.size = (zone.half_size + Vector2.ONE * 50.0) * 2.0
	BattleStage.add_mesh(root, mesh, zone.ground_color, Vector3.ZERO)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	shape.shape = WorldBoundaryShape3D.new()
	body.add_child(shape)
	root.add_child(body)


static func _add_path(root: Node3D, zone: ZoneData) -> void:
	var points := zone.path_points
	for i in points.size() - 1:
		var a := points[i]
		var b := points[i + 1]
		var d := b - a
		var mesh := PlaneMesh.new()
		mesh.size = Vector2(zone.path_half_width * 2.0, d.length())
		var mid := (a + b) / 2.0 + Vector3(0, 0.01, 0)
		var yaw := rad_to_deg(atan2(d.x, d.z))
		BattleStage.add_mesh(root, mesh, BattleStage.DIRT, mid, Vector3.ONE, Vector3(0, yaw, 0))
	# Round the inner bends so the drawn path matches is_on_path (union of capsules).
	for i in range(1, points.size() - 1):
		_add_disc(root, points[i], zone.path_half_width)
	for disc in zone.safe_discs:
		_add_disc(root, disc[0], disc[1])


static func _add_disc(root: Node3D, center: Vector3, radius: float) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.02
	BattleStage.add_mesh(root, mesh, BattleStage.DIRT, center + Vector3(0, 0.01, 0))


## An imported model on a static body, with a box collider fitted to its mesh (the
## free models bring no collision of their own).
static func _add_solid_model(root: Node3D, scene: PackedScene, pos: Vector3, scl: float, \
		yaw_deg: float) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	body.rotation_degrees = Vector3(0, yaw_deg, 0)
	root.add_child(body)
	var model := BattleStage.add_model(body, scene, Vector3.ZERO, scl)
	var bounds := BattleStage.model_aabb(model)
	var box := BoxShape3D.new()
	box.size = bounds.size * scl
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position = bounds.get_center() * scl
	body.add_child(shape)


static func _add_trees(root: Node3D, zone: ZoneData) -> void:
	var single_a: Array[Transform3D] = []
	var single_b: Array[Transform3D] = []
	var clumps: Array[Transform3D] = []
	for tree in _tree_layout(zone):
		var xform := Transform3D(Basis(Vector3.UP, tree.yaw).scaled(Vector3.ONE * tree.scale),
			tree.pos)
		if tree.clump:
			clumps.append(xform)
		elif tree.use_a:
			single_a.append(xform)
		else:
			single_b.append(xform)
		if tree.inside:
			var body := StaticBody3D.new()
			body.position = tree.pos
			root.add_child(body)
			add_cylinder_shape(body, CLUMP_RADIUS if tree.clump else TRUNK_RADIUS,
				TREE_COLLIDER_HEIGHT)
	_add_tree_kind(root, _tree_mesh(zone.tree_models[0]), single_a)
	_add_tree_kind(root, _tree_mesh(zone.tree_models[1]), single_b)
	_add_tree_kind(root, _tree_mesh(zone.clump_model), clumps)


## The trees of zone, in the order they are drawn: {"pos", "yaw", "scale", "use_a" (the
## first single model), "clump", "inside" (inside the walls: it has a collider)}. The same
## rolls every time (zone.tree_seed); the last zone asked about is kept.
static func _tree_layout(zone: ZoneData) -> Array[Dictionary]:
	if _layout_zone == zone.id:
		return _layout
	var rng := RandomNumberGenerator.new()
	rng.seed = zone.tree_seed
	var area := zone.half_size + Vector2.ONE * zone.outer_margin
	var placed: Array[Vector2] = []
	var trees: Array[Dictionary] = []
	for i in zone.tree_tries:
		# Every roll is made even for spots left out, so the layout stays stable.
		var pos := Vector3(rng.randf_range(-area.x, area.x), 0.0, rng.randf_range(-area.y, area.y))
		var roll := rng.randf()
		var yaw := rng.randf() * TAU
		var scl := rng.randf_range(zone.tree_scale.x, zone.tree_scale.y)
		var use_a := rng.randf() < 0.5
		# Distance to the nearest wall (negative outside the field).
		var inset := minf(zone.half_size.x - absf(pos.x), zone.half_size.y - absf(pos.z))
		var rise := clampf(1.0 - inset / zone.tree_rise_inset, 0.0, 1.0)
		if roll > lerpf(zone.tree_center_chance, 1.0, rise) or not _tree_fits(zone, pos, placed):
			continue
		placed.append(Vector2(pos.x, pos.z))
		trees.append({"pos": pos, "yaw": yaw, "scale": scl, "use_a": use_a,
			"clump": inset < zone.tree_clump_inset, "inside": inset > 0.0})
	_layout_zone = zone.id
	_layout = trees
	return trees


## The mesh of a tree model: a jungle palm (PalmModels: palm_A, palm_B, palms_clump) or
## the one mesh of a MODELS scene.
static func _tree_mesh(id: String) -> Mesh:
	if PalmModels.has(id):
		return PalmModels.mesh(id)
	return BattleStage.scene_mesh(MODELS[id])


## One kind of tree as a MultiMesh through TREE_SHADER (the dithered hole that keeps the
## hero in sight). Every surface keeps its own colour and its texture when it has one: the
## KayKit trees have one textured surface, the palms two plain coloured ones.
static func _add_tree_kind(root: Node3D, source_mesh: Mesh, transforms: Array[Transform3D]) -> void:
	var mesh := source_mesh.duplicate() as Mesh
	for i in mesh.get_surface_count():
		var source := mesh.surface_get_material(i) as BaseMaterial3D
		var material := ShaderMaterial.new()
		material.shader = TREE_SHADER
		material.set_shader_parameter("use_texture", source != null and source.albedo_texture != null)
		if source != null:
			material.set_shader_parameter("albedo_texture", source.albedo_texture)
			material.set_shader_parameter("albedo_color", source.albedo_color)
			material.set_shader_parameter("roughness_value", source.roughness)
		mesh.surface_set_material(i, material)
	LowPoly.add_multimesh(root, mesh, transforms)


static func _tree_fits(zone: ZoneData, pos: Vector3, placed: Array[Vector2]) -> bool:
	if is_on_path(zone, pos, TREE_PATH_MARGIN) or _near_route(zone, pos, TREE_ROUTE_MARGIN):
		return false
	if Decor.near_placed(zone, pos, TREE_DECOR_MARGIN):
		return false
	if _near_rock(zone, pos, TREE_ROCK_MARGIN) or _near_chest(zone, pos, CHEST_TREE_MARGIN):
		return false
	if _near_building(zone, pos, TREE_BUILDING_MARGIN) or _near_exit(zone, pos, TREE_EXIT_MARGIN):
		return false
	var p := Vector2(pos.x, pos.z)
	for glade in zone.glades:
		if p.distance_to(Vector2(glade[0].x, glade[0].z)) < glade[1]:
			return false
	for other in placed:
		if p.distance_to(other) < zone.tree_spacing:
			return false
	return true


static func _add_bushes(root: Node3D, zone: ZoneData) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = zone.bush_seed
	var bushes: Array[Transform3D] = []
	var half := zone.half_size
	for i in zone.bush_tries:
		var pos := Vector3(rng.randf_range(-half.x, half.x), 0.0, rng.randf_range(-half.y, half.y))
		var yaw := rng.randf() * TAU
		var scl := rng.randf_range(BUSH_SCALE.x, BUSH_SCALE.y)
		if is_on_path(zone, pos, BUSH_PATH_MARGIN) or _near_rock(zone, pos, BUSH_ROCK_MARGIN) \
				or _near_chest(zone, pos, CHEST_BUSH_MARGIN) \
				or _near_building(zone, pos, GRASS_BUILDING_MARGIN) \
				or Decor.near_solid(zone, pos, BUSH_DECOR_MARGIN):
			continue
		bushes.append(Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * scl), pos))
	var material := ShaderMaterial.new()
	material.shader = TREE_SHADER
	material.set_shader_parameter("albedo_color", LowPoly.BUSH_COLOR)
	LowPoly.add_multimesh(root, LowPoly.bush_mesh(), bushes, material)


## The Kenney decoration of zone (Decor, NatureModels): the pieces merged into one mesh per
## DECOR_CHUNK-metre chunk (one surface, vertex colours, through the trees' shader), so the
## whole decoration is a handful of draws; a collider for each solid piece (always, whatever
## the quality, so the map stays the same), a flame on each campfire. With half_density (low
## quality) only every other scattered piece without a collider is drawn.
static func _add_decor(root: Node3D, zone: ZoneData) -> void:
	for line in Decor.problems(zone):
		push_warning(line)
	var chunks := {}  # Vector2i → [{"id", "xform"}]
	var soft := 0
	for piece in Decor.placed(zone) + Decor.scattered(zone):
		var solid := Decor.is_solid(piece.id)
		if piece.scattered and not solid and Vegetation.half_density:
			soft += 1
			if soft % 2 == 0:
				continue
		var xform := Transform3D(Basis(Vector3.UP, piece.yaw).scaled(Vector3.ONE * piece.scale),
			piece.pos)
		var key := Vector2i(floori(piece.pos.x / DECOR_CHUNK), floori(piece.pos.z / DECOR_CHUNK))
		if not chunks.has(key):
			chunks[key] = []
		(chunks[key] as Array).append({"id": piece.id, "xform": xform})
		if solid:
			_add_decor_collider(root, piece, NatureModels.mesh(piece.id, zone.decor_green))
		if Decor.KINDS[piece.id].get("flame", false):
			BattleStage.add_flame(root, piece.pos + Vector3(0, 0.35, 0), 2.2, Vector3(0, 0.8, 0),
				not BattleStage.plain_light)
	var material := ShaderMaterial.new()
	material.shader = TREE_SHADER
	material.set_shader_parameter("use_texture", false)
	material.set_shader_parameter("use_vertex_color", true)
	for key: Vector2i in chunks:
		var instance := MeshInstance3D.new()
		instance.mesh = NatureModels.merged(chunks[key], zone.decor_green)
		instance.material_override = material
		root.add_child(instance)


static func _add_decor_collider(root: Node3D, piece: Dictionary, mesh: Mesh) -> void:
	var body := StaticBody3D.new()
	body.position = piece.pos
	body.rotation = Vector3(0, piece.yaw, 0)
	root.add_child(body)
	var bounds := mesh.get_aabb()
	if Decor.KINDS[piece.id].collider == "box":
		var box := BoxShape3D.new()
		box.size = bounds.size * piece.scale
		var shape := CollisionShape3D.new()
		shape.shape = box
		shape.position = bounds.get_center() * piece.scale
		body.add_child(shape)
	else:
		add_cylinder_shape(body, Decor.radius(piece), bounds.size.y * piece.scale)


## The cells of a dungeon floor no decoration stands on: the lever, the key, the gates, the
## torches and the throne (what decor_blocker() says it would be on).
const DECOR_KEEP_CELLS := {"L": "la palanca", "K": "la llave", "D": "una reja",
	"T": "una antorcha", "R": "el trono"}


## What a piece of decoration of this radius at pos would be on that it must not ("" if the
## spot is fine): the path, the autoplay route, exits and stairs, entries, the portal,
## chests and wells, small medals, figures, the boss, rocks, buildings, trees, and on a
## dungeon floor rock cells, the stair rooms and DECOR_KEEP_CELLS. Decor asks it for the
## scattered pieces; it only asks Decor for the placed ones (near_tree() through
## _tree_fits() and near_placed()), never for the scattered ones, so is_clear_of_props()
## is not used here.
static func decor_blocker(zone: ZoneData, pos: Vector3, radius: float, solid: bool) -> String:
	if zone.is_dungeon():
		var cell := zone.cell_at(pos)
		if zone.cell_char(cell) == "#":
			return "la roca"
		if zone.near_stairs(pos):
			return "las escaleras"
		for ch: String in DECOR_KEEP_CELLS:
			for c: Vector2i in zone.find_cells(ch):
				var to_cell := zone.cell_center(c) - pos
				to_cell.y = 0.0
				if to_cell.length() < ZoneData.CELL * 0.5 + radius:
					return DECOR_KEEP_CELLS[ch]
	elif is_on_path(zone, pos, radius + DECOR_PATH_MARGIN):
		return "el camino"
	if _near_route(zone, pos, radius + (DECOR_ROUTE_MARGIN if solid else DECOR_SOFT_ROUTE_MARGIN)):
		return "la ruta automática"
	if _near_exit(zone, pos, radius + DECOR_EXIT_MARGIN):
		return "una salida"
	var p := Vector2(pos.x, pos.z)
	for entry: Array in zone.entries.values():
		if p.distance_to(Vector2(entry[0].x, entry[0].z)) < radius + DECOR_ENTRY_MARGIN:
			return "una entrada"
	if zone.portal_pos != Vector3.ZERO \
			and p.distance_to(Vector2(zone.portal_pos.x, zone.portal_pos.z)) < radius + DECOR_PORTAL_MARGIN:
		return "el portal"
	if zone.boss_id != "" \
			and p.distance_to(Vector2(zone.boss_pos.x, zone.boss_pos.z)) < radius + DECOR_BOSS_MARGIN:
		return "el jefe"
	if _near_chest(zone, pos, radius + DECOR_CHEST_MARGIN):
		return "un cofre o un pozo"
	if _near_medal(zone, pos, radius + DECOR_MEDAL_MARGIN):
		return "una medalla"
	if _near_figure(zone, pos, radius + DECOR_FIGURE_MARGIN):
		return "una figura"
	if _near_rock(zone, pos, radius + DECOR_PROP_MARGIN):
		return "una roca"
	if _near_building(zone, pos, radius + DECOR_PROP_MARGIN):
		return "una casa"
	if not zone.is_dungeon() and near_tree(zone, pos, radius + DECOR_PROP_MARGIN):
		return "un árbol"
	return ""


## True within margin of a rock's footprint.
static func _near_rock(zone: ZoneData, pos: Vector3, margin: float) -> bool:
	var p := Vector2(pos.x, pos.z)
	for rock in zone.rocks:
		if p.distance_to(Vector2(rock[0].x, rock[0].z)) < BattleStage.rock_radius(rock) + margin:
			return true
	return false


## True within margin of a building's footprint (a circle around its widest side).
static func _near_building(zone: ZoneData, pos: Vector3, margin: float) -> bool:
	var p := Vector2(pos.x, pos.z)
	for building in zone.buildings:
		var radius := BUILDING_RADIUS.get(building[2], 1.6) as float
		if p.distance_to(Vector2(building[0].x, building[0].z)) < radius + margin:
			return true
	return false


## True within FIGURE_GRASS_MARGIN of one of the zone's figures (a cat would be lost in the
## grass).
static func _near_figure(zone: ZoneData, pos: Vector3, margin := FIGURE_GRASS_MARGIN) -> bool:
	var p := Vector2(pos.x, pos.z)
	for npc: Dictionary in zone.npcs:
		if p.distance_to(Vector2(npc.pos.x, npc.pos.z)) < margin:
			return true
	return false


## True within margin of one of the zone's chests (Chests.CHESTS of this zone) or wells
## (zone.wells). The spots of the last zone asked about are kept, so the thousands of
## grass, tree and bush candidates of a build don't look them up each time.
static func _near_chest(zone: ZoneData, pos: Vector3, margin: float) -> bool:
	if _chest_zone != zone.id:
		_chest_zone = zone.id
		_chest_spots.clear()
		for chest_id in Chests.of_zone(zone.id):
			var chest_pos: Vector3 = Chests.CHESTS[chest_id].pos
			_chest_spots.append(Vector2(chest_pos.x, chest_pos.z))
		for well: Dictionary in zone.wells:
			_chest_spots.append(Vector2(well.pos.x, well.pos.z))
	var p := Vector2(pos.x, pos.z)
	for spot in _chest_spots:
		if p.distance_to(spot) < margin:
			return true
	return false


## True within MEDAL_GRASS_MARGIN of one of the zone's small medals (taken or not: the map
## is built from the zone alone). Only the grass asks: the trees and bushes don't change.
static func _near_medal(zone: ZoneData, pos: Vector3, margin := MEDAL_GRASS_MARGIN) -> bool:
	if _medal_zone != zone.id:
		_medal_zone = zone.id
		_medal_spots.clear()
		for id in Medals.of_zone(zone.id):
			var spot: Vector3 = Medals.MEDALS[id].pos
			_medal_spots.append(Vector2(spot.x, spot.z))
	var p := Vector2(pos.x, pos.z)
	for spot in _medal_spots:
		if p.distance_to(spot) < margin:
			return true
	return false


## True within margin of an exit's trigger (its arch stands there).
static func _near_exit(zone: ZoneData, pos: Vector3, margin: float) -> bool:
	var p := Vector2(pos.x, pos.z)
	for exit: Dictionary in zone.all_exits():
		if p.distance_to(Vector2(exit.pos.x, exit.pos.z)) < margin:
			return true
	return false


## True within margin of the loop Player walks on --autoplay, so no tree blocks it.
static func _near_route(zone: ZoneData, pos: Vector3, margin: float) -> bool:
	var p := Vector2(pos.x, pos.z)
	var route := zone.autoplay_route
	for i in route.size():
		var a := Vector2(route[i].x, route[i].z)
		var next := route[(i + 1) % route.size()]
		var b := Vector2(next.x, next.z)
		if p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b)) < margin:
			return true
	return false


static func _add_walls(root: Node3D, zone: ZoneData) -> void:
	var hx := zone.half_size.x
	var hz := zone.half_size.y
	var walls := [
		[Vector3(0, 2, -hz), Vector3(hx * 2.0, 4, 1)],
		[Vector3(0, 2, hz), Vector3(hx * 2.0, 4, 1)],
		[Vector3(-hx, 2, 0), Vector3(1, 4, hz * 2.0)],
		[Vector3(hx, 2, 0), Vector3(1, 4, hz * 2.0)],
	]
	for wall in walls:
		var body := StaticBody3D.new()
		body.position = wall[0]
		var box := BoxShape3D.new()
		box.size = wall[1]
		var shape := CollisionShape3D.new()
		shape.shape = box
		body.add_child(shape)
		root.add_child(body)
