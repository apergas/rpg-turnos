class_name PalmMeshes extends RefCounted
## The jungle palms, built in code like the slimes and the bushes: a slightly curved trunk
## of stacked tapered segments (brown, banded) and a crown of drooping fronds (green, flat
## shaded, both faces). Plain vertex colours, no texture. Each mesh has two surfaces (trunk,
## fronds) whose material takes the vertex colour as albedo. At scale 1 a palm stands
## 7-9 m tall (a clump's palms 4-6 m).

const TRUNK_SIDES := 7
const TRUNK_RINGS := 8
const TRUNK_COLORS: Array[Color] = [Color(0.47, 0.32, 0.18), Color(0.38, 0.25, 0.14)]
const FROND_COLORS: Array[Color] = [Color(0.2, 0.52, 0.16), Color(0.14, 0.42, 0.12)]
const FROND_STEPS := 5

static var _cache: Dictionary = {}


## "palm_A" (tall, straight), "palm_B" (bent) or "palms_clump" (three short ones).
static func has(id: String) -> bool:
	return id == "palm_A" or id == "palm_B" or id == "palms_clump"


static func mesh(id: String) -> ArrayMesh:
	if not _cache.has(id):
		var trunk := _begin()
		var fronds := _begin()
		match id:
			"palm_A":
				_palm(trunk, fronds, Vector3.ZERO, 8.5, 0.3, 0.0, 9, 0)
			"palm_B":
				_palm(trunk, fronds, Vector3.ZERO, 7.5, 2.4, 0.6, 7, 1)
			_:
				_palm(trunk, fronds, Vector3(0.0, 0.0, 0.0), 5.5, 0.9, 0.3, 7, 0)
				_palm(trunk, fronds, Vector3(1.3, 0.0, 0.7), 4.2, 0.6, 2.2, 6, 1)
				_palm(trunk, fronds, Vector3(-0.9, 0.0, 1.1), 4.8, 0.7, 4.1, 7, 2)
		var result := ArrayMesh.new()
		for st in [trunk, fronds]:
			st.generate_normals()
			st.commit(result)
		var material := StandardMaterial3D.new()
		material.vertex_color_use_as_albedo = true
		material.roughness = 1.0
		result.surface_set_material(0, material)
		result.surface_set_material(1, material)
		_cache[id] = result
	return _cache[id]


static func _begin() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(0xFFFFFFFF)
	return st


static func _tri(st: SurfaceTool, color: Color, a: Vector3, b: Vector3, c: Vector3) -> void:
	for p in [a, b, c]:
		st.set_color(color)
		st.add_vertex(p)


## One palm at base: trunk of height, leaning bend metres toward the yaw direction, and a
## crown of fronds.
static func _palm(trunk: SurfaceTool, fronds: SurfaceTool, base: Vector3, height: float,
		bend: float, yaw: float, frond_count: int, variant: int) -> void:
	var lean := Vector3(sin(yaw), 0.0, cos(yaw))
	var rings: Array[PackedVector3Array] = []
	var centers: Array[Vector3] = []
	for i in TRUNK_RINGS + 1:
		var t := float(i) / TRUNK_RINGS
		var center := base + Vector3(0, t * height, 0) + lean * (bend * t * t)
		var radius := lerpf(0.3, 0.14, t) * (1.0 + 0.12 * (i % 2))  # a little banded
		var ring := PackedVector3Array()
		for s in TRUNK_SIDES:
			var angle := TAU * (s + 0.5 * (i % 2)) / TRUNK_SIDES
			ring.append(center + Vector3(sin(angle) * radius, 0, cos(angle) * radius))
		rings.append(ring)
		centers.append(center)
	for i in TRUNK_RINGS:
		var color := TRUNK_COLORS[i % 2]
		for s in TRUNK_SIDES:
			var n := (s + 1) % TRUNK_SIDES
			_tri(trunk, color, rings[i][s], rings[i + 1][s], rings[i][n])
			_tri(trunk, color, rings[i][n], rings[i + 1][s], rings[i + 1][n])
	var top := centers[TRUNK_RINGS]
	for s in TRUNK_SIDES:  # a cap, so nothing shows through the crown
		_tri(trunk, TRUNK_COLORS[1], top + Vector3(0, 0.1, 0), rings[TRUNK_RINGS][(s + 1) % TRUNK_SIDES],
			rings[TRUNK_RINGS][s])
	for f in frond_count:
		var angle := yaw + TAU * f / frond_count + variant * 0.4
		_frond(fronds, top + Vector3(0, 0.05, 0), angle, 2.7 + 0.3 * ((f + variant) % 3), f)


## One drooping frond from origin outward: a folded strip (spine raised, edges lower), with
## both faces, so it reads from above and from below.
static func _frond(st: SurfaceTool, origin: Vector3, angle: float, length: float,
		index: int) -> void:
	var out := Vector3(sin(angle), 0, cos(angle))
	var side := Vector3(out.z, 0, -out.x)
	var spine: Array[Vector3] = []
	var half: Array[float] = []
	for i in FROND_STEPS + 1:
		var s := float(i) / FROND_STEPS
		spine.append(origin + out * (length * s) + Vector3(0, 0.9 * s - 2.1 * s * s, 0))
		half.append(0.5 * sin(PI * pow(s, 0.7)) + 0.03)
	for i in FROND_STEPS:
		var color := FROND_COLORS[(i + index) % 2]
		var a := spine[i]
		var b := spine[i + 1]
		var al := a + side * half[i] - Vector3(0, half[i] * 0.45, 0)
		var ar := a - side * half[i] - Vector3(0, half[i] * 0.45, 0)
		var bl := b + side * half[i + 1] - Vector3(0, half[i + 1] * 0.45, 0)
		var br := b - side * half[i + 1] - Vector3(0, half[i + 1] * 0.45, 0)
		for quad in [[a, b, al, bl], [a, ar, b, br]]:
			_tri(st, color, quad[0], quad[1], quad[2])
			_tri(st, color, quad[2], quad[1], quad[3])
			_tri(st, color, quad[0], quad[2], quad[1])  # the underside
			_tri(st, color, quad[2], quad[3], quad[1])
