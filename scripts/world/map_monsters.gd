class_name MapMonsters extends Node3D
## The groups of monsters walking on a map (MonsterGroups, MonsterRoam): placed, moved
## every physics tick near the hero, touched (check_contact(): World then starts the
## battle), taken off when beaten, faded while fled from or while an Incienso burns, and
## brought back one at a time (tick_refill()); on a dungeon floor also the Slime de Metal
## (add_rare()). Owned by World, which calls setup() and the per-tick functions in its own
## order; never stores World. On autoplay it prints "Grupos: n", "Grupo vencido (quedan n)"
## and "Grupo repuesto (n)".

## The groups were replaced or cleared (AutoplayHunter forgets the groups it left alone).
signal groups_reset

const ACTOR_SCENE := preload("res://scenes/battle/battle_actor.tscn")
## Groups of monsters farther than this from the hero neither move nor animate.
const GROUP_ANIMATE_RADIUS := 30.0
## Seconds between two hops of a slime walking on the map.
const HOP_TIME := 0.45
## Seconds of play on this map between two groups coming back while it has fewer than
## zone.monster_count, and the fade they come in with.
const REFILL_S := 45.0
const REFILL_FADE := 0.5

## DebugPanel's Monstruos: while set, no map puts any group of monsters or rare enemy
## (_add_group(), add_rare()). It lasts for the run; only DebugPanel changes it (through
## World.debug_no_groups).
static var debug_no_groups := false

## The groups on the map (AutoplayHunter reads them).
var groups: Array[Dictionary]:
	get:
		return _groups

var _zone: ZoneData
var _player: Player
var _autoplay := false
var _rng := RandomNumberGenerator.new()
## The world flags (World.set_world_flags(); the same Dictionary): an open gate is floor.
var _flags := {}
## The groups of monsters on the map (MonsterGroups), each {"node": Node3D (no collider),
## "actor": BattleActor (its first enemy's figure), "roam": MonsterRoam, "enemies":
## Array[Combatant] (the formation, data), "armed": bool (false: fled from, it starts no
## battle yet), "rare": bool (the Slime de Metal), "hop": seconds to its next hop}.
var _groups: Array[Dictionary] = []
## The hero is EncounterMeter.LEVEL_GAP levels past the zone: the moving groups keep away.
var _shy := false
## Index in _groups of the group whose battle is on (-1: none, or the boss's).
var _contact := -1
## No group starts a battle before this time (World's _sim_ms; calm()).
var _calm_until_ms := 0
## Simulation ms counted toward the next group coming back (tick_refill()).
var _refill_ms := 0.0
## True while an Incienso keeps the monsters away (Game counts its metres).
var _repelled := false


func setup(zone: ZoneData, player: Player) -> void:
	_zone = zone
	_player = player
	_autoplay = RunFlags.autoplay()
	# The groups are placed with the zone and the clock: never twice the same.
	_rng.seed = hash(zone.id) ^ Time.get_ticks_usec()


## The world flags: each group's MonsterRoam walks only on what is floor now.
func set_flags(flags: Dictionary) -> void:
	_flags = flags
	for group in _groups:
		(group.roam as MonsterRoam).set_flags(flags)


func is_repelled() -> bool:
	return _repelled


## The hero is EncounterMeter.LEVEL_GAP levels past the zone (EncounterMeter.is_shy()): the
## groups that move keep away from him; the still ones stay. They can still be touched.
func set_shy(on: bool) -> void:
	_shy = on


## Every group of the zone again (MonsterGroups.groups()), in new places, none within
## MonsterGroups.ENTRY_GAP of avoid (where the hero stands). On autoplay prints "Grupos: n".
func respawn_groups(avoid: Array[Vector3] = []) -> void:
	_refill_ms = 0.0
	for group in _groups:
		(group.node as Node3D).queue_free()
	_groups.clear()
	_contact = -1
	groups_reset.emit()
	_player.stop_hunt()
	for spot: Dictionary in MonsterGroups.groups(_zone, _rng, avoid):
		_add_group(spot.pos, spot.enemies, false)
	if _autoplay:
		print("Grupos: %d" % group_count())


## How many groups are on the map (the rare enemy apart).
func group_count() -> int:
	var count := 0
	for group in _groups:
		if not group.rare:
			count += 1
	return count


## Debug only (DebugPanel's Monstruos): every group off the map, the rare one too. While
## debug_no_groups is set none comes back.
func clear_groups() -> void:
	for group in _groups:
		(group.node as Node3D).queue_free()
	_groups.clear()
	_contact = -1
	groups_reset.emit()
	_player.stop_hunt()


## Puts the zone's rare enemy (the Slime de Metal) on this dungeon floor, away from the hero
## (MonsterGroups.rare_spot()), unless one is here already. It wanders the whole floor
## (MonsterRoam WANDER) and is touched like a group.
func add_rare(enemy_id: String) -> void:
	if debug_no_groups or has_rare() or not _zone.is_dungeon():
		return
	var spot: Variant = MonsterGroups.rare_spot(_zone, _rng, _player.global_position)
	if spot == null:
		return
	_add_group(spot, EnemyLibrary.formation([enemy_id]), true)
	if _autoplay:
		print("%s en el mapa" % EnemyLibrary.data(enemy_id).display_name)


func has_rare() -> bool:
	for group in _groups:
		if group.rare:
			return true
	return false


## A group at pos: the figure of its first enemy (no collider: nothing bumps into it),
## facing the camera, and its MonsterRoam.
func _add_group(pos: Vector3, enemies: Array[Combatant], rare: bool) -> Dictionary:
	if debug_no_groups:
		return {}
	var node := Node3D.new()
	node.position = pos
	node.rotation_degrees.y = 180.0
	add_child(node)
	var actor: BattleActor = ACTOR_SCENE.instantiate()
	actor.look = EnemyLibrary.look(enemies[0].id)
	node.add_child(actor)
	var roam := MonsterRoam.for_leader(enemies[0], pos, _rng,
		_zone if _zone.is_dungeon() else null)
	roam.set_flags(_flags)
	var group := {"node": node, "actor": actor, "roam": roam, "enemies": enemies,
		"armed": true, "rare": rare, "hop": 0.0}
	_groups.append(group)
	_fade_group(group)
	return group


## A beaten group comes back, one every REFILL_S seconds of play on this map while it has
## fewer than _zone.monster_count (MonsterGroups.refill_spot(): never near the hero), fading in.
## Not during a cutscene or an Incienso, nor on a map without monsters (the Caravana).
func tick_refill(delta: float) -> void:
	if debug_no_groups or _zone.monster_count <= 0 or _zone.formations.is_empty() \
			or _player.scripted or _repelled or group_count() >= _zone.monster_count:
		_refill_ms = 0.0
		return
	_refill_ms += delta * 1000.0
	if _refill_ms < REFILL_S * 1000.0:
		return
	_refill_ms = 0.0
	var taken: Array[Vector3] = []
	for g in _groups:
		taken.append((g.node as Node3D).position)
	var spot: Variant = MonsterGroups.refill_spot(_zone, _rng, _player.global_position, taken)
	if spot == null:
		return
	var group := _add_group(spot, EncounterTable.pick_group(_zone, spot, _rng), false)
	if group.is_empty():
		return
	(group.actor as BattleActor).play_fade_in(REFILL_FADE)
	if _autoplay:
		print("Grupo repuesto (%d)" % group_count())


## Moves every group near the hero one physics tick (MonsterRoam), turned the way it walks,
## with the walk animation and, for a slime, a hop now and then. Groups past
## GROUP_ANIMATE_RADIUS stop moving and animating (their node stops processing).
func move_groups(delta: float) -> void:
	var hero := _player.global_position
	for group in _groups:
		var node: Node3D = group.node
		var near := _flat_distance(hero, node.position) <= GROUP_ANIMATE_RADIUS
		var mode := Node.PROCESS_MODE_INHERIT if near else Node.PROCESS_MODE_DISABLED
		if node.process_mode != mode:
			node.process_mode = mode
		if not near:
			continue
		var roam: MonsterRoam = group.roam
		var actor: BattleActor = group.actor
		var before := node.position
		node.position = roam.step(before, delta, hero, _shy)
		actor.set_walking(roam.moving)
		if not roam.moving:
			continue
		var dir := node.position - before
		node.rotation.y = lerp_angle(node.rotation.y, atan2(-dir.x, -dir.z),
			minf(1.0, Player.TURN_SPEED * delta))
		if actor.hops():
			group["hop"] = float(group.hop) - delta
			if group.hop <= 0.0:
				group["hop"] = HOP_TIME
				actor.play_hop()


## A group shows half see-through while it can't start a battle: fled from, or an Incienso
## burning.
func _fade_group(group: Dictionary) -> void:
	(group.actor as BattleActor).set_faded(_repelled or not group.armed)


## The enemies of the group whose battle is starting (its formation, data: BattleScene
## duplicates them); empty for the boss's battle.
func contact_enemies() -> Array[Combatant]:
	var enemies: Array[Combatant] = []
	if _contact >= 0:
		enemies.assign(_groups[_contact].enemies)
	return enemies


## After the battle of the group touched (outcome: BattleEngine.State): WON takes it off the
## map ("Grupo vencido (quedan n)" on autoplay; another comes back later, tick_refill()),
## FLED leaves it half see-through, starting no battle until the hero is MonsterGroups.REARM_RADIUS away;
## LOST changes nothing (Game sends the hero back and the groups come back with the map).
func end_contact(outcome: int) -> void:
	if _contact < 0:
		return
	var index := _contact
	_contact = -1
	var group: Dictionary = _groups[index]
	if outcome == BattleEngine.State.WON:
		_groups.remove_at(index)
		(group.node as Node3D).queue_free()
		if _autoplay:
			print("Grupo vencido (quedan %d)" % group_count())
	elif outcome == BattleEngine.State.FLED:
		group.armed = false
		_fade_group(group)


## An Incienso burning: touching a group starts no battle and every group shows half
## see-through (the boss still waits where it is).
func set_repel(on: bool, now_ms: int) -> void:
	if _repelled == on:
		return
	_repelled = on
	if on:
		_player.stop_hunt()
	for group in _groups:
		_fade_group(group)
	if not on:
		calm(now_ms)


## No group starts a battle for MonsterGroups.CALM_MS from now.
func calm(now_ms: int) -> void:
	_calm_until_ms = now_ms + MonsterGroups.CALM_MS


## The hero within MonsterGroups.CONTACT_RADIUS of a group starts its battle (true: the
## map waits for Game), unless it is calm (calm()) or an Incienso burns. A group fled from
## starts none until the hero is MonsterGroups.REARM_RADIUS away from it.
func check_contact(pos: Vector3, now_ms: int) -> bool:
	var calm := now_ms < _calm_until_ms
	for i in _groups.size():
		var group: Dictionary = _groups[i]
		var d := _flat_distance(pos, (group.node as Node3D).position)
		if not group.armed:
			if d > MonsterGroups.REARM_RADIUS:
				group.armed = true
				_fade_group(group)
			continue
		if d <= MonsterGroups.CONTACT_RADIUS and not calm and not _repelled:
			_contact = i
			return true
	return false


## The index in _groups of the group on node (-1 if none).
func group_index(node: Node3D) -> int:
	for i in _groups.size():
		if _groups[i].node == node:
			return i
	return -1


static func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))
