class_name MonsterGroups extends RefCounted
## The groups of monsters a map is built with (ZoneData.monster_count), where they stand,
## and the distances of touching them. Each group is a formation of
## EncounterTable.pick_group(); World draws only its first enemy. On an open map a group
## stands off the path (on the grass where there is some), PATH_MARGIN off the path and the safe discs (so a hero on them is
## never touched), out of the village, inside the walls and clear of the rocks, the
## buildings and the trees; on a dungeon floor, on a room cell (is_room_cell(): a corridor
## one cell wide never holds one), never in the stair rooms or the village (the refugio, the
## camp). Everywhere clear of the exits, the chests, the wells, the figures, the
## boss and the
## entries, and MIN_GAP from each other. Pure: no nodes.

## Two groups stand at least this far apart.
const MIN_GAP := 8.0
## The hero this close to a group starts its battle (World).
const CONTACT_RADIUS := 1.3
## A group the hero fled from starts no battle until he is this far from it.
const REARM_RADIUS := 4.0
## No group starts a battle this long after a battle or after the hero is placed (ms).
const CALM_MS := 1500
## The widest radius a group walks in (the bats and the specters, Combatant.map_roam).
const MAX_ROAM := 2.5
## Open map: groups keep this far off the path and the safe discs.
const PATH_MARGIN := CONTACT_RADIUS + MAX_ROAM + 0.5
## Open map: this far from a dune's footprint (a group may walk MAX_ROAM from its spot).
const DUNE_MARGIN := MAX_ROAM + 0.5
## Open map: this far inside the walls, and off the rocks, the buildings and the trunks.
const EDGE_MARGIN := 4.0
const PROP_MARGIN := 1.5
const TREE_MARGIN := 1.5
## Clear of the exits, the chests, the wells, the figures and, on a dungeon floor,
## the
## lever, the key and the gates; farther from the boss; farther still from the entries and
## from the spots to avoid (the hero).
const CLEAR_MARGIN := 5.0
const BOSS_MARGIN := 8.0
const ENTRY_GAP := 10.0
## Dungeon floor: groups keep this far outside the village circle.
const VILLAGE_MARGIN := 2.0
## Open map: random spots tried.
const OPEN_TRIES := 600
## Placements tried; the one with the most groups is kept (a small floor fits few).
const PLACE_TRIES := 6
## The rare enemy (the Slime de Metal) starts at least this far from the hero.
const RARE_GAP := 12.0
## A group that comes back (World's refill) stands at least this far from the hero.
const REFILL_GAP := 20.0
## The 2 × 2 blocks a cell can be part of (their top left corner, from the cell) and the
## four cells of a block.
const BLOCK_CORNERS: Array[Vector2i] = [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0),
	Vector2i(0, 0)]
const BLOCK: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]


## The groups of zone: [{"pos": Vector3, "enemies": Array[Combatant] (data, not
## duplicated)}], monster_count of them or fewer if the map has no room, none within
## ENTRY_GAP of avoid.
static func groups(zone: ZoneData, rng: RandomNumberGenerator,
		avoid: Array[Vector3] = []) -> Array[Dictionary]:
	var placed: Array[Dictionary] = []
	if zone.formations.is_empty() or zone.monster_count <= 0:
		return placed
	for pos in spots(zone, zone.monster_count, rng, avoid):
		placed.append({"pos": pos, "enemies": EncounterTable.pick_group(zone, pos, rng)})
	return placed


## Up to count spots of zone, MIN_GAP apart: the most of PLACE_TRIES shuffles of the same
## candidates.
static func spots(zone: ZoneData, count: int, rng: RandomNumberGenerator,
		avoid: Array[Vector3] = []) -> Array[Vector3]:
	var candidates := _candidates(zone, rng, avoid)
	var best: Array[Vector3] = []
	for attempt in PLACE_TRIES:
		_shuffle(candidates, rng)
		var picked: Array[Vector3] = []
		for pos in candidates:
			if picked.size() >= count:
				break
			if _apart(pos, picked):
				picked.append(pos)
		if picked.size() > best.size():
			best = picked
		if best.size() >= count:
			break
	return best


## A floor cell inside a room: plain floor or a torch, and one of the 2 × 2 blocks of cells
## around it is all floor (no rock, no gate). A corridor one cell wide has none.
static func is_room_cell(zone: ZoneData, cell: Vector2i) -> bool:
	if not zone.cell_char(cell) in [ZoneData.FLOOR, ZoneData.TORCH]:
		return false
	for corner in BLOCK_CORNERS:
		var whole := true
		for part in BLOCK:
			var ch := zone.cell_char(cell + corner + part)
			if ch == ZoneData.ROCK or ch == ZoneData.DOOR or ch == ZoneData.PORTAL:
				whole = false
				break
		if whole:
			return true
	return false


## Every room cell of a dungeon floor, row by row.
static func room_cells(zone: ZoneData) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var size := zone.grid_size()
	for y in size.y:
		for x in size.x:
			if is_room_cell(zone, Vector2i(x, y)):
				cells.append(Vector2i(x, y))
	return cells


## Where the rare enemy starts on a dungeon floor: a random cell it can wander to
## (MonsterRoam.wander_cells()), RARE_GAP from the hero; null if there is none.
static func rare_spot(zone: ZoneData, rng: RandomNumberGenerator, hero_pos: Vector3) -> Variant:
	var far: Array[Vector3] = []
	for cell in MonsterRoam.wander_cells(zone):
		var pos := zone.cell_center(cell)
		if _flat(pos, hero_pos) >= RARE_GAP:
			far.append(pos)
	if far.is_empty():
		return null
	return far[rng.randi_range(0, far.size() - 1)]


## Where one more group may stand now: a spot spots() could pick (the same _candidates()),
## REFILL_GAP or more from the hero and MIN_GAP from every group on the map (taken); null if
## there is none.
static func refill_spot(zone: ZoneData, rng: RandomNumberGenerator, hero_pos: Vector3,
		taken: Array[Vector3]) -> Variant:
	var avoid: Array[Vector3] = [hero_pos]
	var found: Array[Vector3] = []
	for pos in _candidates(zone, rng, avoid):
		if _flat(pos, hero_pos) >= REFILL_GAP and _apart(pos, taken):
			found.append(pos)
	if found.is_empty():
		return null
	return found[rng.randi_range(0, found.size() - 1)]


## The spots a group may stand on: the room cells of a dungeon floor, or OPEN_TRIES random
## points of an open map that pass _open_spot(); both only if _clear().
static func _candidates(zone: ZoneData, rng: RandomNumberGenerator,
		avoid: Array[Vector3]) -> Array[Vector3]:
	var found: Array[Vector3] = []
	if zone.is_dungeon():
		for cell in room_cells(zone):
			var pos := zone.cell_center(cell)
			if _clear(zone, pos, avoid):
				found.append(pos)
		return found
	var half := zone.half_size - Vector2.ONE * EDGE_MARGIN
	for i in OPEN_TRIES:
		var pos := Vector3(rng.randf_range(-half.x, half.x), 0.0, rng.randf_range(-half.y, half.y))
		if _open_spot(zone, pos) and _clear(zone, pos, avoid):
			found.append(pos)
	return found


## Open map: PATH_MARGIN off the path and the safe discs (on the grass where the zone has
## it; anywhere off the path where it has none, like the desert), out of the village, clear
## of the rocks, the buildings, the solid decoration and the trees, and DUNE_MARGIN off the
## dunes.
static func _open_spot(zone: ZoneData, pos: Vector3) -> bool:
	if WorldStage.is_on_path(zone, pos, PATH_MARGIN):
		return false
	if zone.village_radius > 0.0 \
			and _flat(pos, zone.village_pos) < zone.village_radius + PATH_MARGIN:
		return false
	return WorldStage.is_clear_of_props(zone, pos, PROP_MARGIN) \
		and not WorldStage.near_tree(zone, pos, TREE_MARGIN) \
		and not WorldStage.near_dune(zone, pos, DUNE_MARGIN)


## Clear of what the hero walks up to or arrives at: the exits (and stairs), chests, wells,
## figures and, on a dungeon floor, the lever, the key and the gates (CLEAR_MARGIN); the
## boss (BOSS_MARGIN); the entries and avoid (ENTRY_GAP); a dungeon floor's stair rooms and
## village.
static func _clear(zone: ZoneData, pos: Vector3, avoid: Array[Vector3]) -> bool:
	var near: Array[Vector3] = []
	for exit: Dictionary in zone.all_exits():
		near.append(exit.pos)
	for id in Chests.of_zone(zone.id):
		near.append(Chests.CHESTS[id].pos)
	for well: Dictionary in zone.wells:
		near.append(well.pos)
	for npc: Dictionary in zone.npcs:
		near.append(npc.pos)
	if zone.is_dungeon():
		for ch in [ZoneData.CHEST_CELL, ZoneData.LEVER, ZoneData.DOOR, ZoneData.KEY]:
			for cell in zone.find_cells(ch):
				near.append(zone.cell_center(cell))
	for spot in near:
		if _flat(pos, spot) < CLEAR_MARGIN:
			return false
	if (zone.boss_id != "" or zone.postgame_boss_id != "") \
			and _flat(pos, zone.boss_pos) < BOSS_MARGIN:
		return false
	for entry: Array in zone.entries.values():
		if _flat(pos, entry[0]) < ENTRY_GAP:
			return false
	for spot in avoid:
		if _flat(pos, spot) < ENTRY_GAP:
			return false
	if zone.is_dungeon():
		if zone.near_stairs(pos):
			return false
		if zone.village_radius > 0.0 \
				and _flat(pos, zone.village_pos) < zone.village_radius + VILLAGE_MARGIN:
			return false
	return true


static func _apart(pos: Vector3, picked: Array[Vector3]) -> bool:
	for other in picked:
		if _flat(pos, other) < MIN_GAP:
			return false
	return true


## Shuffles list in place with rng (Array.shuffle() would use the global one).
static func _shuffle(list: Array[Vector3], rng: RandomNumberGenerator) -> void:
	for i in range(list.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap := list[i]
		list[i] = list[j]
		list[j] = swap


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))
