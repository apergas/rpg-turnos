class_name MapProps extends Node3D
## The things that stand on a map and change with the game: the exits (arch, sign and the
## fog bank of a closed one; or a portal), the Ala de viaje's return portal and the ring of the spot it
## leads back to, the wells (their water and light hidden while dry), the chests (a lid on
## a hinge) and the ring on the spot the player walks to. Owned by World, which calls
## setup(), adds it and then build(); never stores World.

## Chest model: wooden box with a gold band and a lid hinged at the back.
const CHEST_SIZE := Vector3(0.9, 0.45, 0.6)
const CHEST_LID_HEIGHT := 0.2
const CHEST_WOOD := Color(0.5, 0.3, 0.14)
const CHEST_BAND := Color(1.0, 0.78, 0.2)
## Angle of an open lid (degrees about X: the front edge swings up and back).
const CHEST_OPEN_ANGLE := 110.0
## Wells: a collider the hero walks around, and a disc of coloured water with a light.
const WELL_COLLIDER := 1.3
const WATER_HP := Color(1.0, 0.25, 0.25)
const WATER_MP := Color(0.25, 0.5, 1.0)
const WATER_RADIUS := 0.95
const WATER_HEIGHT := 1.2
## Exit arch: two posts and a beam of dark wood, a sign board with the exit's label
## (always facing the camera, south) and, while closed, a bank of fog.
const ARCH_WOOD := Color(0.36, 0.22, 0.1)
const ARCH_WIDTH := 3.6
const ARCH_HEIGHT := 3.0
const SIGN_COLOR := Color(0.62, 0.45, 0.25)
const FOG_COLOR := Color(0.92, 0.93, 0.97, 0.6)
## An exit with this "look" is the Ala de viaje's portal (TravelPortal) with its label as the
## sign, instead of the wooden arch: the Caravana and Brumaclara (3.0.0).
const PORTAL_LOOK := "portal"

## The wells that are dry now (World.set_dry_wells()); the map square's marks follow them.
var dry_wells: Array[String]:
	get:
		return _dry_wells

var _zone: ZoneData
## chest id -> lid pivot (rotation.x opens it); a chest in _open_chests is open.
var _chest_lids := {}
var _open_chests: Array[String] = []
## Well id -> its water and light, hidden while it is dry.
var _well_waters := {}
var _dry_wells: Array[String] = []
## exit id -> fog bank shown while the exit is closed.
var _fogs := {}
## exit id -> its root (arch, sign and fog): hidden while the exit is not present
## (ZoneData.is_present()).
var _arches := {}
## The return portal and the mark of the spot it leads back to (null while not on this map).
var _portal: Node3D
var _return_mark: Node3D
var _marker: MeshInstance3D


func setup(zone: ZoneData) -> void:
	_zone = zone


## The zone's chests, wells and exit arches (the stairs of a dungeon floor have none).
func build() -> void:
	for id in Chests.of_zone(_zone.id):
		_chest_lids[id] = build_chest(self, Chests.CHESTS[id])
	for well: Dictionary in _zone.wells:
		_build_well(well)
	for exit: Dictionary in _zone.all_exits():
		if not exit.get("stairs", false):
			_fogs[exit.id] = _build_exit(exit)


## The world flags: an exit not present hides, a closed one shows its fog.
func set_flags(flags: Dictionary) -> void:
	for exit: Dictionary in _zone.exits:
		var present := ZoneData.is_present(exit, flags)
		(_arches[exit.id] as Node3D).visible = present
		(_fogs[exit.id] as Node3D).visible = present and not is_open(exit, flags)


static func is_open(exit: Dictionary, flags: Dictionary) -> bool:
	return exit.lock == "" or flags.get(exit.lock, false)


func has_portal() -> bool:
	return _portal != null


## The chests of this zone not opened yet, in the order they were built.
func closed_chests() -> Array[String]:
	var closed: Array[String] = []
	for id in _chest_lids:
		if not _open_chests.has(id):
			closed.append(id)
	return closed


## The ring on the spot the player walks to (Player.move_target, null for none).
func show_marker(target: Variant) -> void:
	_marker.visible = target != null
	if _marker.visible:
		_marker.position = target


## Shows or removes the return portal at the zone's portal_pos.
func set_portal(on: bool) -> void:
	if _portal != null:
		_portal.queue_free()
		_portal = null
	if on:
		_portal = _build_portal(_zone.portal_pos, true)


## Shows or removes the mark on the ground of the spot the portal leads back to.
func set_return_mark(on: bool, pos: Vector3) -> void:
	if _return_mark != null:
		_return_mark.queue_free()
		_return_mark = null
	if on:
		_return_mark = _build_portal(pos, false)


## Opens (lid tipped back, tweened unless instant) or closes a chest of this zone. An
## open chest can't be used any more; ids of other zones are ignored.
func set_chest_open(chest_id: String, open: bool, instant := false) -> void:
	if not _chest_lids.has(chest_id):
		return
	var lid: Node3D = _chest_lids[chest_id]
	var angle := deg_to_rad(CHEST_OPEN_ANGLE) if open else 0.0
	if open and not _open_chests.has(chest_id):
		_open_chests.append(chest_id)
	elif not open:
		_open_chests.erase(chest_id)
	if instant:
		lid.rotation.x = angle
	else:
		lid.create_tween().tween_property(lid, "rotation:x", angle, 0.35) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Hides the water and the light of the wells in dry.
func set_dry_wells(dry: Array[String]) -> void:
	for id: String in _well_waters:
		(_well_waters[id] as Node3D).visible = not dry.has(id)
	_dry_wells = dry


## The kind (Wells.HP or Wells.MP) of the well id of this zone.
func well_kind(id: String) -> String:
	for well: Dictionary in _zone.wells:
		if well.id == id:
			return well.kind
	return Wells.HP


## Flat ring on the spot the player walks to. Drawn on top of everything, so the tall
## grass never hides it.
func build_marker() -> void:
	var ring := TorusMesh.new()
	ring.inner_radius = 0.3
	ring.outer_radius = 0.42
	ring.rings = 16
	ring.ring_segments = 4
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = UiTokens.color(&"border-focus")
	material.no_depth_test = true
	var marker := MeshInstance3D.new()
	marker.mesh = ring
	marker.material_override = material
	marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	marker.visible = false
	add_child(marker)
	_marker = marker


## The arch of an exit (turned by its yaw) with its sign, which always faces the camera,
## and the fog bank that closes it; or, for an exit with "look": PORTAL_LOOK, the swirling
## portal with the exit's label over it (never closed: its fog bank is empty). Returns the
## fog bank.
func _build_exit(exit: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.position = exit.pos
	add_child(root)
	_arches[exit.id] = root
	if exit.get("look", "") == PORTAL_LOOK:
		var portal := TravelPortal.new()
		portal.sign_text = exit.label
		portal.rotation_degrees.y = exit.yaw
		root.add_child(portal)
		var none := Node3D.new()
		root.add_child(none)
		return none
	var arch := Node3D.new()
	arch.rotation_degrees.y = exit.yaw
	root.add_child(arch)
	var post := BoxMesh.new()
	post.size = Vector3(0.3, ARCH_HEIGHT, 0.3)
	for x in [-ARCH_WIDTH / 2.0, ARCH_WIDTH / 2.0]:
		BattleStage.add_mesh(arch, post, ARCH_WOOD, Vector3(x, ARCH_HEIGHT / 2.0, 0))
	var beam := BoxMesh.new()
	beam.size = Vector3(ARCH_WIDTH + 0.6, 0.35, 0.4)
	BattleStage.add_mesh(arch, beam, ARCH_WOOD, Vector3(0, ARCH_HEIGHT, 0))
	var board := BoxMesh.new()
	board.size = Vector3(2.4, 0.55, 0.08)
	BattleStage.add_mesh(root, board, SIGN_COLOR, Vector3(0, ARCH_HEIGHT + 0.5, 0.1))
	var label := Label3D.new()
	label.text = exit.label
	UiTheme.style_3d(label, &"display-m", &"text-display-soft", UiTokens.OUTLINE_L)
	label.pixel_size = 0.008
	label.position = Vector3(0, ARCH_HEIGHT + 0.5, 0.15)
	root.add_child(label)
	var fog := Node3D.new()
	root.add_child(fog)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = FOG_COLOR
	for puff in [Vector3(-1.2, 0.8, 0), Vector3(0, 1.1, 0.1), Vector3(1.2, 0.8, 0),
			Vector3(-0.6, 1.9, -0.1), Vector3(0.7, 2.0, 0)]:
		var mi := MeshInstance3D.new()
		mi.mesh = BattleStage.unit_sphere()
		mi.material_override = material
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = puff
		mi.scale = Vector3(1.1, 0.9, 0.7)
		fog.add_child(mi)
	return fog


## The Ala de viaje's return portal at pos (full: the standing portal with its sign), or only
## the glowing ring on the ground of the spot it leads back to (TravelPortal).
func _build_portal(pos: Vector3, full: bool) -> Node3D:
	var portal := TravelPortal.new()
	portal.ring_only = not full
	portal.position = pos
	add_child(portal)
	return portal


## A well: its model (green in the forest village, red elsewhere) on a cylinder collider,
## with a disc of coloured water inside the rim and a light over it.
func _build_well(well: Dictionary) -> void:
	var body := StaticBody3D.new()
	body.position = well.pos
	add_child(body)
	WorldStage.add_cylinder_shape(body, WELL_COLLIDER, 2.0)
	var model_id := "well_green" if _zone.id == "bosque" else "well_red"
	BattleStage.add_model(body, WorldStage.MODELS[model_id], Vector3.ZERO,
		WorldStage.BUILDING_SCALE)
	var water := Node3D.new()
	water.position.y = WATER_HEIGHT
	body.add_child(water)
	var color := WATER_HP if well.kind == Wells.HP else WATER_MP
	var disc := CylinderMesh.new()
	disc.top_radius = WATER_RADIUS
	disc.bottom_radius = WATER_RADIUS
	disc.height = 0.05
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	var mesh := MeshInstance3D.new()
	mesh.mesh = disc
	mesh.material_override = material
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	water.add_child(mesh)
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 1.5
	light.omni_range = 4.0
	light.shadow_enabled = false
	light.position.y = 0.6
	water.add_child(light)
	_well_waters[well.id] = water


## A closed chest on a box collider under root: wooden box with a gold band around it and a lid on
## a pivot at its back edge. Returns the lid pivot.
static func build_chest(root: Node3D, chest: Dictionary) -> Node3D:
	var body := StaticBody3D.new()
	body.position = chest.pos
	body.rotation_degrees.y = chest.yaw
	root.add_child(body)
	var box := BoxShape3D.new()
	box.size = CHEST_SIZE + Vector3(0, CHEST_LID_HEIGHT, 0)
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position.y = box.size.y / 2.0
	body.add_child(shape)
	var base := BoxMesh.new()
	base.size = CHEST_SIZE
	BattleStage.add_mesh(body, base, CHEST_WOOD, Vector3(0, CHEST_SIZE.y / 2.0, 0))
	var band := BoxMesh.new()
	band.size = Vector3(CHEST_SIZE.x + 0.04, 0.08, CHEST_SIZE.z + 0.04)
	BattleStage.add_mesh(body, band, CHEST_BAND, Vector3(0, CHEST_SIZE.y * 0.7, 0))
	var lid := Node3D.new()
	lid.position = Vector3(0, CHEST_SIZE.y, CHEST_SIZE.z / 2.0)
	body.add_child(lid)
	var top := BoxMesh.new()
	top.size = Vector3(CHEST_SIZE.x, CHEST_LID_HEIGHT, CHEST_SIZE.z)
	BattleStage.add_mesh(lid, top, CHEST_WOOD,
		Vector3(0, CHEST_LID_HEIGHT / 2.0, -CHEST_SIZE.z / 2.0))
	var lock := BoxMesh.new()
	lock.size = Vector3(0.14, 0.16, 0.05)
	BattleStage.add_mesh(lid, lock, CHEST_BAND, Vector3(0, 0.0, -CHEST_SIZE.z - 0.02))
	var lid_band := BoxMesh.new()
	lid_band.size = Vector3(0.1, CHEST_LID_HEIGHT + 0.02, CHEST_SIZE.z + 0.02)
	for x in [-0.3, 0.3]:
		BattleStage.add_mesh(lid, lid_band, CHEST_BAND,
			Vector3(x, CHEST_LID_HEIGHT / 2.0, -CHEST_SIZE.z / 2.0))
	return lid
