class_name BattleActor extends Node3D
## 3D stand-in for a combatant built from primitive meshes. The model faces -Z, so
## look_at() the opponent. Animations are tweens on the inner body and can be awaited.

enum Look { HERO, SLIME, VILLAGER, KING_SLIME }

const FIRE_COLOR := Color(1.0, 0.45, 0.1)
const HEAL_COLOR := Color(0.3, 1.0, 0.4)
const GOLD := Color(1.0, 0.8, 0.2)

@export var look := Look.HERO

## Height of the floating damage numbers.
var _top := 2.0
## Visual root moved and scaled by the animations; the actor node itself stays put.
var _body: Node3D
var _materials: Array[StandardMaterial3D] = []
var _idle_tween: Tween


func _ready() -> void:
	_body = Node3D.new()
	add_child(_body)
	match look:
		Look.HERO:
			_build_hero()
		Look.SLIME:
			_build_slime()
		Look.VILLAGER:
			_build_villager()
		Look.KING_SLIME:
			_build_king_slime()
	reset()


## Back to the starting pose: visible, opaque, no flash, idle animation running.
func reset() -> void:
	show()
	_body.position = Vector3.ZERO
	_body.scale = Vector3.ONE
	_set_flash(false)
	for mat in _materials:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
		mat.albedo_color.a = 1.0
	if look == Look.SLIME or look == Look.KING_SLIME:
		_start_bounce()


## Lunges toward the target and steps back.
func play_attack(target_pos: Vector3) -> void:
	var base := global_position
	var dir := target_pos - base
	dir.y = 0.0
	var lunge := dir.normalized() * minf(1.2, dir.length() * 0.4)
	var t := create_tween()
	t.tween_property(_body, "global_position", base + lunge, 0.15) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(_body, "global_position", base, 0.2) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await t.finished


## White flash, small knockback and a floating damage number.
func play_hit(amount: int, crit: bool) -> void:
	_spawn_number(amount, crit)
	var base := global_position
	var knockback := global_basis.z.normalized() * (0.5 if crit else 0.3)
	_set_flash(true)
	var t := create_tween()
	t.tween_property(_body, "global_position", base + knockback, 0.08)
	t.tween_callback(_set_flash.bind(false))
	t.tween_property(_body, "global_position", base, 0.15)
	await t.finished


## Side step used when an attack misses.
func play_dodge() -> void:
	var base := global_position
	var side := global_basis.x.normalized() * 0.6
	var t := create_tween()
	t.tween_property(_body, "global_position", base + side, 0.1) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(_body, "global_position", base, 0.15)
	await t.finished


## Squashes, shrinks and fades out, then hides.
func play_defeat() -> void:
	if _idle_tween:
		_idle_tween.kill()
	for mat in _materials:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var t := create_tween()
	t.tween_property(_body, "scale", Vector3(1.25, 0.3, 1.25), 0.2)
	t.tween_property(_body, "scale", Vector3(0.05, 0.05, 0.05), 0.35)
	t.parallel().tween_method(_set_alpha, 1.0, 0.0, 0.35)
	await t.finished
	hide()


## Small hop with a glow in the spell's color, before a spell.
func play_cast(color := FIRE_COLOR) -> void:
	_set_flash(true, color)
	var t := create_tween()
	t.tween_property(_body, "position:y", 0.35, 0.15) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(_body, "position:y", 0.0, 0.15) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await t.finished
	_set_flash(false)


## A ball in the spell's color grows on the actor and fades while the hit plays.
func play_burn(amount: int, color := FIRE_COLOR) -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	var ball := MeshInstance3D.new()
	ball.mesh = _sphere(0.5)
	ball.material_override = mat
	ball.position = Vector3(0, _top * 0.45, 0)
	ball.scale = Vector3.ONE * 0.2
	add_child(ball)
	var t := create_tween()
	t.tween_property(ball, "scale", Vector3.ONE * 1.6, 0.3) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.3).set_delay(0.1)
	t.tween_callback(ball.queue_free)
	await play_hit(amount, false)
	if t.is_running():
		await t.finished


## Green glow and a green number going up.
func play_heal(amount: int) -> void:
	_spawn_number(amount, false, HEAL_COLOR)
	_set_flash(true, HEAL_COLOR)
	await get_tree().create_timer(0.35).timeout
	_set_flash(false)


## Wobbles side to side, for a fighter that loses its turn.
func play_stagger() -> void:
	var t := create_tween()
	for angle in [12.0, -12.0, 8.0, 0.0]:
		t.tween_property(_body, "rotation_degrees:z", angle, 0.1)
	await t.finished


func _build_hero() -> void:
	_top = 2.1
	_add_mesh(_capsule(0.32, 1.2), Color(0.75, 0.12, 0.12), Vector3(0, 0.6, 0))  # body / tunic
	_add_mesh(_sphere(0.27), Color(0.96, 0.78, 0.62), Vector3(0, 1.45, 0))  # head
	_add_mesh(_sphere(0.29), Color(0.92, 0.62, 0.2), Vector3(0, 1.52, 0.06), \
		Vector3.ZERO, Vector3(1.0, 0.85, 1.0))  # hair, seen from behind
	_add_mesh(_box(Vector3(0.08, 0.9, 0.04)), Color(0.75, 0.75, 0.8), \
		Vector3(0.42, 0.85, -0.2), Vector3(-30, 0, 0))  # sword


func _build_slime() -> void:
	_top = 1.4
	_add_mesh(_sphere(0.6), Color(0.55, 0.3, 0.85), Vector3(0, 0.45, 0), \
		Vector3.ZERO, Vector3(1.0, 0.75, 1.0))  # body
	for x in [-0.2, 0.2]:
		_add_mesh(_sphere(0.13), Color.WHITE, Vector3(x, 0.6, -0.48))  # eye
		_add_mesh(_sphere(0.06), Color(0.05, 0.05, 0.05), Vector3(x, 0.6, -0.6))  # pupil


func _build_villager() -> void:
	_top = 2.0
	_add_mesh(_capsule(0.34, 1.2), Color(0.45, 0.25, 0.6), Vector3(0, 0.6, 0))  # robe
	_add_mesh(_sphere(0.26), Color(0.94, 0.78, 0.66), Vector3(0, 1.42, 0))  # head
	_add_mesh(_sphere(0.28), Color(0.92, 0.92, 0.95), Vector3(0, 1.5, 0.06), \
		Vector3.ZERO, Vector3(1.0, 0.85, 1.0))  # white hair
	_add_mesh(_cylinder(0.04, 1.6), Color(0.45, 0.3, 0.15), Vector3(0.42, 0.8, -0.1))  # staff


func _build_king_slime() -> void:
	_top = 2.4
	_add_mesh(_sphere(0.6), Color(0.3, 0.45, 0.9), Vector3(0, 0.72, 0), \
		Vector3.ZERO, Vector3(1.6, 1.2, 1.6))  # body
	for x in [-0.32, 0.32]:
		_add_mesh(_sphere(0.2), Color.WHITE, Vector3(x, 0.96, -0.82))  # eye
		_add_mesh(_sphere(0.09), Color(0.05, 0.05, 0.05), Vector3(x, 0.96, -1.0))  # pupil
	_add_mesh(_cylinder(0.38, 0.22), GOLD, Vector3(0, 1.5, 0))  # crown band
	for i in 5:
		var angle := TAU * i / 5.0
		_add_mesh(_cone(0.1, 0.3), GOLD, Vector3(cos(angle) * 0.3, 1.76, sin(angle) * 0.3))  # spike


func _start_bounce() -> void:
	if _idle_tween:
		_idle_tween.kill()
	_idle_tween = create_tween().set_loops()
	_idle_tween.tween_property(_body, "scale", Vector3(1.08, 0.9, 1.08), 0.35) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_idle_tween.tween_property(_body, "scale", Vector3.ONE, 0.35) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _spawn_number(amount: int, crit: bool, color := Color.WHITE) -> void:
	var label := Label3D.new()
	label.text = str(amount)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.pixel_size = 0.005
	label.font_size = 96 if crit else 64
	label.outline_size = 16
	label.modulate = Color(1.0, 0.85, 0.2) if crit else color
	label.position = Vector3(0, _top, 0)
	add_child(label)
	var t := label.create_tween().set_parallel()
	t.tween_property(label, "position:y", _top + 0.8, 0.9)
	t.tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.3)
	t.chain().tween_callback(label.queue_free)


func _set_flash(on: bool, color := Color.WHITE) -> void:
	for mat in _materials:
		mat.emission_enabled = on
		mat.emission = color
		mat.emission_energy_multiplier = 1.5


func _set_alpha(alpha: float) -> void:
	for mat in _materials:
		mat.albedo_color.a = alpha


func _add_mesh(mesh: Mesh, color: Color, pos: Vector3, rot_deg := Vector3.ZERO, \
		scl := Vector3.ONE) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.8
	_materials.append(mat)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.scale = scl
	_body.add_child(mi)


static func _sphere(radius: float) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	return mesh


static func _capsule(radius: float, height: float) -> CapsuleMesh:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	return mesh


static func _box(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh


static func _cylinder(radius: float, height: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	return mesh


static func _cone(radius: float, height: float) -> CylinderMesh:
	var mesh := _cylinder(radius, height)
	mesh.top_radius = 0.0
	return mesh
