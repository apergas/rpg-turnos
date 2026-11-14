class_name AutoplayHunter extends RefCounted
## Autoplay only: below the zone's autoplay_boss_level (Game: set_on()) the hero leaves the
## route for the nearest group that can start a battle (Player.hunt()), gives up after
## AUTOPLAY_HUNT_MS (or stuck on the way, Player.take_failed_hunt()) and leaves that one
## alone for AUTOPLAY_HUNT_RETRY_MS. Its timers count World's _sim_ms, the simulation's own
## clock, so a run with --fixed-fps keeps them. Owned by World, which calls step() in its
## physics tick; it reads the groups of MapMonsters and never stores World.

const AUTOPLAY_HUNT_RADIUS := 60.0
const AUTOPLAY_HUNT_RADIUS_CAVE := 12.0  # walls: a straight line to a far group fails
const AUTOPLAY_HUNT_MS := 15000
const AUTOPLAY_HUNT_RETRY_MS := 20000

var _zone: ZoneData
var _player: Player
var _monsters: MapMonsters
## Hunt groups (Game: below the zone's autoplay_boss_level), until when the one hunted now
## is followed, and group instance id -> the time until which it is left alone.
var _hunt_on := false
var _hunt_until_ms := 0
var _hunt_skip := {}


func setup(zone: ZoneData, player: Player, monsters: MapMonsters) -> void:
	_zone = zone
	_player = player
	_monsters = monsters


func is_on() -> bool:
	return _hunt_on


## Autoplay: hunt the groups (Game: while the hero is below the zone's autoplay_boss_level).
func set_on(on: bool) -> void:
	_hunt_on = on
	if not on:
		_player.stop_hunt()


## The groups were replaced or cleared (MapMonsters.groups_reset).
func forget() -> void:
	_hunt_skip.clear()


static func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))


## Autoplay: leaves the route for the nearest group within AUTOPLAY_HUNT_RADIUS that can
## start a battle, and goes back to it once that one is gone or fled from, after
## AUTOPLAY_HUNT_MS, or when the hero got stuck on the way (that one is then left alone for
## AUTOPLAY_HUNT_RETRY_MS).
func step(pos: Vector3, now: int) -> void:
	var failed := _player.take_failed_hunt()
	if failed != 0:
		_hunt_skip[failed] = now + AUTOPLAY_HUNT_RETRY_MS
	if _player.is_hunting():
		var current := _player.hunting()
		var index := _monsters.group_index(current) if current != null else -1
		if index < 0 or not _monsters.groups[index].armed:
			_player.stop_hunt()
		elif now > _hunt_until_ms:
			_hunt_skip[current.get_instance_id()] = now + AUTOPLAY_HUNT_RETRY_MS
			_player.stop_hunt()
		return
	var best: Node3D = null
	var best_d := AUTOPLAY_HUNT_RADIUS_CAVE if _zone.is_dungeon() else AUTOPLAY_HUNT_RADIUS
	for group in _monsters.groups:
		var node: Node3D = group.node
		if not group.armed or now < int(_hunt_skip.get(node.get_instance_id(), 0)):
			continue
		var d := _flat_distance(pos, node.position)
		if d < best_d:
			best = node
			best_d = d
	if best != null:
		_player.hunt(best)
		_hunt_until_ms = now + AUTOPLAY_HUNT_MS
