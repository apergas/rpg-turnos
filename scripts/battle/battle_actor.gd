class_name BattleActor extends Node3D
## 3D stand-in for a combatant built from primitive meshes. The model faces -Z, so
## look_at() the opponent. Animations are tweens on the inner body and can be awaited.

enum Look { HERO, SLIME }

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
	if look == Look.SLIME:
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


func _start_bounce() -> void:
	if _idle_tween:
		_idle_tween.kill()
	_idle_tween = create_tween().set_loops()
	_idle_tween.tween_property(_body, "scale", Vector3(1.08, 0.9, 1.08), 0.35) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_idle_tween.tween_property(_body, "scale", Vector3.ONE, 0.35) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _spawn_number(amount: int, crit: bool) -> void:
	var label := Label3D.new()
	label.text = str(amount)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.pixel_size = 0.005
	label.font_size = 96 if crit else 64
	label.outline_size = 16
	label.modulate = Color(1.0, 0.85, 0.2) if crit else Color.WHITE
	label.position = Vector3(0, _top, 0)
	add_child(label)
	var t := label.create_tween().set_parallel()
	t.tween_property(label, "position:y", _top + 0.8, 0.9)
	t.tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.3)
	t.chain().tween_callback(label.queue_free)


func _set_flash(on: bool) -> void:
	for mat in _materials:
		mat.emission_enabled = on
		mat.emission = Color.WHITE
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
