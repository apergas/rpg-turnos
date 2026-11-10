class_name MonsterRoam extends RefCounted
## Where the figure of one group of monsters on the map goes; World only moves it there.
## Pure: no nodes, with the rng World gives it. Three kinds of movement:
## STILL: it never moves (mushrooms, plants, golems: their idle loop is all).
## ROAM: from one random point within radius of home to another (next_point()), waiting a
## little at each (WAIT); it never chases the hero. Shy (the hero EncounterMeter.LEVEL_GAP
## levels past the zone) it moves away from a hero closer than SHY_RADIUS, at its speed,
## never farther than SHY_REACH times its radius from home. On a dungeon floor every point
## it walks to is on a cell a hero could walk (walkable()).
## WANDER: the Slime de Metal, with no radius: cell by cell (cell_path()) to a random cell
## of the whole floor (wander_cells()) at its speed; with the hero closer than RUN_RADIUS it
## runs at RUN_SPEED to the farthest from him of RUN_PICKS random cells.

enum Kind { STILL, ROAM, WANDER }

## Closer than this to where it goes counts as arrived.
const ARRIVE := 0.15
## Seconds it waits at each point (random between the two).
const WAIT := Vector2(0.6, 2.0)
const SHY_RADIUS := 5.0
const SHY_REACH := 2.0
const RUN_RADIUS := 6.0
const RUN_SPEED := 4.5
const RUN_PICKS := 6
## Random points tried for one it may stand on before staying home.
const POINT_TRIES := 8
## The four steps between cells of cell_path().
const STEPS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

var kind := Kind.STILL
## Where the group was put (the centre of its radius).
var home := Vector3.ZERO
## Metres it walks from home (Combatant.map_roam) and how fast (Combatant.map_speed).
var radius := 0.0
var speed := 1.5
## Where it is walking to now.
var target := Vector3.ZERO
## True if it moved on the last step() (World plays the walk then).
var moving := false

var _rng: RandomNumberGenerator
## The dungeon floor it is on (null on an open map).
var _zone: ZoneData
## GameState.world_flags as World has them (a floor's gates open with one).
var _flags := {}
var _wait := 0.0
## WANDER: the cells it may go to, the cells still to walk (the next first) and whether it
## is running away.
var _cells: Array[Vector2i] = []
var _path: Array[Vector2i] = []
var _running := false


func _init(p_kind: Kind, p_home: Vector3, p_radius: float, p_speed: float,
		rng: RandomNumberGenerator, dungeon: ZoneData = null) -> void:
	kind = p_kind
	home = p_home
	radius = p_radius
	speed = p_speed
	target = p_home
	_rng = rng
	_zone = dungeon
	_wait = _rng.randf_range(WAIT.x, WAIT.y)
	if kind == Kind.WANDER and _zone != null:
		_cells = wander_cells(_zone)


## The movement of a group whose first enemy is leader, put at p_home (dungeon: the floor it
## is on, null on an open map). The Slime de Metal wanders a dungeon floor; an enemy with no
## map_roam stands still.
static func for_leader(leader: Combatant, p_home: Vector3, rng: RandomNumberGenerator,
		dungeon: ZoneData = null) -> MonsterRoam:
	if leader.id == EnemyLibrary.METAL_SLIME and dungeon != null:
		return MonsterRoam.new(Kind.WANDER, p_home, 0.0, leader.map_speed, rng, dungeon)
	var roams := leader.map_roam > 0.0
	return MonsterRoam.new(Kind.ROAM if roams else Kind.STILL, p_home, leader.map_roam,
		leader.map_speed, rng, dungeon)


func set_flags(flags: Dictionary) -> void:
	_flags = flags


## True if a hero could walk the cell of zone: not rock, and a gate only once the floor's
## door flag is set.
static func walkable(zone: ZoneData, cell: Vector2i, flags: Dictionary) -> bool:
	var ch := zone.cell_char(cell)
	if ch == ZoneData.ROCK:
		return false
	if ch == ZoneData.DOOR:
		return zone.door_flag != "" and flags.get(zone.door_flag, false)
	return true


## True if the group may stand at point: anywhere on an open map, on a walkable cell on a
## dungeon floor.
func is_free(point: Vector3) -> bool:
	return _zone == null or walkable(_zone, _zone.cell_at(point), _flags)


## A random point within radius of home where it may stand (home if POINT_TRIES fail).
func next_point() -> Vector3:
	for i in POINT_TRIES:
		var angle := _rng.randf() * TAU
		var point := home + Vector3(cos(angle), 0.0, sin(angle)) * radius * sqrt(_rng.randf())
		if is_free(point):
			return point
	return home


func arrived(pos: Vector3) -> bool:
	return _flat(pos, target) <= ARRIVE


## Where the group is delta seconds after standing at pos, with the hero at hero_pos (shy:
## a ROAM group keeps away from him). Sets moving.
func step(pos: Vector3, delta: float, hero_pos: Vector3, shy: bool) -> Vector3:
	moving = false
	match kind:
		Kind.STILL:
			return pos
		Kind.WANDER:
			return _wander(pos, delta, hero_pos)
	if shy and _flat(pos, hero_pos) < SHY_RADIUS:
		return _keep_away(pos, delta, hero_pos)
	if arrived(pos):
		_wait -= delta
		if _wait > 0.0:
			return pos
		_wait = _rng.randf_range(WAIT.x, WAIT.y)
		target = next_point()
	return _toward(pos, target, speed, delta)


## The cells the Slime de Metal walks to: plain floor or torch cells, out of the stair rooms
## and the village (the refugio).
static func wander_cells(zone: ZoneData) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var size := zone.grid_size()
	for y in size.y:
		for x in size.x:
			var cell := Vector2i(x, y)
			if not zone.cell_char(cell) in [ZoneData.FLOOR, ZoneData.TORCH]:
				continue
			var pos := zone.cell_center(cell)
			if zone.near_stairs(pos):
				continue
			if zone.village_radius > 0.0 and _flat(pos, zone.village_pos) <= zone.village_radius:
				continue
			cells.append(cell)
	return cells


## The cells from start (left out) to goal, one step at a time through walkable() cells
## (breadth first, so the shortest way); empty if goal is start or can't be reached.
static func cell_path(zone: ZoneData, start: Vector2i, goal: Vector2i,
		flags: Dictionary) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	if start == goal or not walkable(zone, goal, flags):
		return path
	var came := {start: start}
	var queue: Array[Vector2i] = [start]
	var head := 0
	while head < queue.size():
		var current := queue[head]
		head += 1
		if current == goal:
			break
		for step_dir in STEPS:
			var next: Vector2i = current + step_dir
			if came.has(next) or not walkable(zone, next, flags):
				continue
			came[next] = current
			queue.append(next)
	if not came.has(goal):
		return path
	var back := goal
	while back != start:
		path.push_front(back)
		back = came[back]
	return path


## A step straight away from the hero, kept within SHY_REACH times radius of home and where
## it may stand (else it stays).
func _keep_away(pos: Vector3, delta: float, hero_pos: Vector3) -> Vector3:
	var away := Vector3(pos.x - hero_pos.x, 0.0, pos.z - hero_pos.z)
	if away.length() < 0.01:
		away = Vector3.RIGHT
	var next := pos + away.normalized() * speed * delta
	var offset := Vector3(next.x - home.x, 0.0, next.z - home.z)
	var reach := radius * SHY_REACH
	if offset.length() > reach:
		next = home + offset.normalized() * reach
	if not is_free(next) or _flat(next, pos) < 0.001:
		return pos
	moving = true
	return next


## pos moved toward goal by spd × delta at most, never past it.
func _toward(pos: Vector3, goal: Vector3, spd: float, delta: float) -> Vector3:
	var to_goal := Vector3(goal.x - pos.x, 0.0, goal.z - pos.z)
	var dist := to_goal.length()
	if dist <= 0.001:
		return pos
	moving = true
	return pos + to_goal / dist * minf(dist, spd * delta)


## The Slime de Metal: cell by cell to a random cell, or running from a hero too close.
func _wander(pos: Vector3, delta: float, hero_pos: Vector3) -> Vector3:
	if _cells.is_empty():
		return pos
	var near := _flat(pos, hero_pos) < RUN_RADIUS
	if near and not _running:
		_running = true
		_path = cell_path(_zone, _zone.cell_at(pos), _far_cell(hero_pos), _flags)
	if _path.is_empty():
		if near:
			_path = cell_path(_zone, _zone.cell_at(pos), _far_cell(hero_pos), _flags)
		else:
			_running = false
			_wait -= delta
			if _wait > 0.0:
				return pos
			_wait = _rng.randf_range(WAIT.x, WAIT.y)
			var goal_cell := _cells[_rng.randi_range(0, _cells.size() - 1)]
			_path = cell_path(_zone, _zone.cell_at(pos), goal_cell, _flags)
		if _path.is_empty():
			return pos
	var goal := _zone.cell_center(_path[0])
	target = goal
	var next := _toward(pos, goal, RUN_SPEED if _running else speed, delta)
	if _flat(next, goal) <= ARRIVE:
		_path.pop_front()
	return next


## The farthest from hero_pos of RUN_PICKS random cells it may go to.
func _far_cell(hero_pos: Vector3) -> Vector2i:
	var best := _cells[_rng.randi_range(0, _cells.size() - 1)]
	var best_d := _flat(_zone.cell_center(best), hero_pos)
	for i in RUN_PICKS - 1:
		var cell := _cells[_rng.randi_range(0, _cells.size() - 1)]
		var d := _flat(_zone.cell_center(cell), hero_pos)
		if d > best_d:
			best = cell
			best_d = d
	return best


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))
