class_name MapMarks extends RefCounted
## The points of interest of a zone on its map (the map square and the pause menu's Mapa
## page), each a small square of its kind's color: shops, inns, wells (grey while dry),
## exits and, on a dungeon floor, the stairs up and down, the lever, the gates and the key.
## The lever and the gates change color once used; the key goes once taken. Pure: World and
## PauseMenu draw them.

const SHOP := "shop"
const INN := "inn"
const WELL_HP := "well_hp"
const WELL_MP := "well_mp"
const WELL_DRY := "well_dry"
const EXIT := "exit"
const STAIRS_UP := "stairs_up"
const STAIRS_DOWN := "stairs_down"
const LEVER := "lever"
const LEVER_DOWN := "lever_down"
const DOOR := "door"
const DOOR_OPEN := "door_open"
const KEY := "key"
## Every kind, in the order of the Mapa page's legend.
const KINDS: Array[String] = [SHOP, INN, WELL_HP, WELL_MP, WELL_DRY, EXIT, STAIRS_UP,
	STAIRS_DOWN, LEVER, LEVER_DOWN, DOOR, DOOR_OPEN, KEY]
## The token (UiTokens) that colours each kind.
const COLORS := {
	SHOP: &"map-shop",
	INN: &"map-inn",
	WELL_HP: &"map-well-hp",
	WELL_MP: &"map-well-mp",
	WELL_DRY: &"map-well-dry",
	EXIT: &"map-exit",
	STAIRS_UP: &"map-stairs-up",
	STAIRS_DOWN: &"map-stairs-down",
	LEVER: &"map-lever",
	LEVER_DOWN: &"map-lever-down",
	DOOR: &"map-door",
	DOOR_OPEN: &"map-door-open",
	KEY: &"map-key",
}

## The colour of one kind.
static func color_of(kind: String) -> Color:
	return UiTokens.color(COLORS[kind])


const NAMES := {
	SHOP: "Tienda",
	INN: "Posada",
	WELL_HP: "Pozo de vida",
	WELL_MP: "Pozo de maná",
	WELL_DRY: "Pozo seco",
	EXIT: "Salida",
	STAIRS_UP: "Escalera de subida",
	STAIRS_DOWN: "Escalera de bajada",
	LEVER: "Palanca",
	LEVER_DOWN: "Palanca bajada",
	DOOR: "Reja cerrada",
	DOOR_OPEN: "Reja abierta",
	KEY: "Llave",
}


## Every mark of zone now, with the world flags and the dry wells:
## [{"pos": Vector3, "kind": String, "color": Color}].
static func of_zone(zone: ZoneData, flags: Dictionary, dry_wells: Array[String]) -> Array[Dictionary]:
	var marks: Array[Dictionary] = []
	for npc: Dictionary in zone.npcs:
		if not ZoneData.is_present(npc, flags):
			continue
		if npc.kind == "shop":
			_add(marks, npc.pos, SHOP)
		elif npc.kind == "inn":
			_add(marks, npc.pos, INN)
	for well: Dictionary in zone.wells:
		var kind := WELL_HP if well.kind == Wells.HP else WELL_MP
		_add(marks, well.pos, WELL_DRY if dry_wells.has(well.id) else kind)
	for exit: Dictionary in zone.all_exits():
		if not ZoneData.is_present(exit, flags):
			continue
		var kind := EXIT
		if exit.get("stairs", false):
			kind = STAIRS_UP if exit.id == ZoneData.STAIRS_UP else STAIRS_DOWN
		_add(marks, exit.pos, kind)
	if not zone.is_dungeon():
		return marks
	if zone.lever_flag != "":
		var down: bool = flags.get(zone.lever_flag, false)
		for cell in zone.find_cells(ZoneData.LEVER):
			_add(marks, zone.cell_center(cell), LEVER_DOWN if down else LEVER)
	if zone.door_flag != "":
		var open: bool = flags.get(zone.door_flag, false)
		for cell in zone.find_cells(ZoneData.DOOR):
			_add(marks, zone.cell_center(cell), DOOR_OPEN if open else DOOR)
	if zone.floor_key != "" and not flags.get(zone.floor_key, false):
		for cell in zone.find_cells(ZoneData.KEY):
			_add(marks, zone.cell_center(cell), KEY)
	return marks


## The marks whose cell has been seen on map (the rest are not shown, nor in the legend).
static func seen(marks: Array[Dictionary], map: ExploredMap) -> Array[Dictionary]:
	var shown: Array[Dictionary] = []
	for mark in marks:
		var cell := Vector2i(map.grid_point(mark.pos)).clamp(Vector2i.ZERO, map.size - Vector2i.ONE)
		if map.is_seen(cell):
			shown.append(mark)
	return shown


## The kinds among marks, in KINDS order (the Mapa page's legend).
static func kinds_in(marks: Array[Dictionary]) -> Array[String]:
	var kinds: Array[String] = []
	for kind in KINDS:
		for mark in marks:
			if mark.kind == kind:
				kinds.append(kind)
				break
	return kinds


static func _add(marks: Array[Dictionary], pos: Vector3, kind: String) -> void:
	marks.append({"pos": pos, "kind": kind, "color": color_of(kind)})
