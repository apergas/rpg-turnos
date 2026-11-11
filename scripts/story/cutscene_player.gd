class_name CutscenePlayer extends Node
## Plays a Cutscene on the current World: the controls are locked from the first step
## to the last (World.begin_cutscene() / end_cutscene()), the figures walk and turn, the
## camera glides, Enter or a tap moves the dialogue on. A "music" step also silences the
## ambient. Game owns it and gives it the things only Game can do: the fade, setting a
## world flag and building another map
## ("travel"). With `-- --autoplay` every step is printed (the dialogue prints its lines).

## Walking speed of the figures in a cutscene, metres per second.
const WALK_SPEED := 3.0
## Seconds the camera takes to settle on a point / back on the hero.
const CAMERA_TIME := 1.4
const CAMERA_BACK_TIME := 0.9

var world: World
## Plays the music steps; without it they are skipped.
var audio: AudioDirector
var hero_name := StoryState.DEFAULT_NAME
## await fade.call(alpha): to black (1.0) or back (0.0).
var fade: Callable
## set_flag.call(name): sets a world flag.
var set_flag: Callable
## await travel.call(zone_id, entry_id) -> World: the new map, already in the tree.
var travel: Callable

var _autoplay := false
var _scene_id := ""


func _ready() -> void:
	_autoplay = OS.get_cmdline_user_args().has("--autoplay")


## Plays every step of scene in order; returns when the last one is done and the map is
## back in the player's hands.
func play(scene: Cutscene) -> void:
	_scene_id = scene.id
	if _autoplay:
		print("Escena: %s" % scene.id)
	world.begin_cutscene()
	for step: Array in scene.steps:
		await _play_step(step)
	await world.end_cutscene()


func _play_step(step: Array) -> void:
	var kind: String = step[0]
	if _autoplay and kind != "say":
		print("  %s: %s" % [_scene_id, " ".join(step.map(func(v: Variant) -> String:
			return str(v)))])
	match kind:
		"say":
			var lines: Array[String] = []
			for line: String in step[2]:
				lines.append(StoryState.fill(line, hero_name))
			await world.say_lines(StoryState.fill(step[1], hero_name), lines)
		"move":
			if step.size() > 3 and step[3]:
				_move(step[1], step[2])
			else:
				await _move(step[1], step[2])
		"approach":
			await _approach(step[1], step[2], float(step[3]))
		"face":
			_face(step[1], step[2])
		"wait":
			await get_tree().create_timer(float(step[1])).timeout
		"camera_to":
			world.focus_camera(step[1], float(step[2]))
			await get_tree().create_timer(CAMERA_TIME).timeout
		"camera_back":
			world.follow_camera()
			await get_tree().create_timer(CAMERA_BACK_TIME).timeout
		"fade_out":
			await fade.call(1.0)
		"fade_in":
			await fade.call(0.0)
		"music":
			if audio:
				audio.play_music(step[1])
				audio.stop_ambient()  # Game brings it back when the scene ends
		"sfx":
			if audio:
				audio.play_sfx(step[1])
		"flag":
			set_flag.call(step[1])
		"travel":
			world = await travel.call(step[1], step[2])
			world.begin_cutscene()
		"cheer":
			var actors: Array[BattleActor] = []
			for who: String in step[1]:
				var actor := world.figure_actor(who)
				if actor:
					actors.append(actor)
			for i in actors.size() - 1:
				actors[i].play_cheer()
			if not actors.is_empty():
				await actors[-1].play_cheer()
		_:
			push_error("Unknown cutscene step: %s" % kind)


## Walks who in a straight line to point, turned toward it, with the walking animation.
func _move(who: String, point: Vector3) -> void:
	var node := world.figure_node(who)
	if node == null:
		return
	var from := node.global_position
	var to := Vector3(point.x, from.y, point.z)
	var distance := Vector2(from.x, from.z).distance_to(Vector2(to.x, to.z))
	if distance < 0.05:
		return
	_face(who, to)
	var actor := world.figure_actor(who)
	if actor:
		actor.set_walking(true)
	var tween := create_tween()
	tween.tween_property(node, "global_position", to, distance / WALK_SPEED)
	await tween.finished
	if actor:
		actor.set_walking(false)


## Walks who straight toward the figure other, stopping metres away from it.
func _approach(who: String, other: String, metres: float) -> void:
	var node := world.figure_node(who)
	var goal := world.figure_node(other)
	if node == null or goal == null:
		return
	var away := node.global_position - goal.global_position
	away.y = 0.0
	if away.length() <= metres:
		_face(who, other)
		return
	await _move(who, goal.global_position + away.normalized() * metres)


## Turns who toward target: another figure's name or a point.
func _face(who: String, target: Variant) -> void:
	var turn := world.figure_turn(who)
	var node := world.figure_node(who)
	if turn == null:
		return
	var point: Vector3
	if target is Vector3:
		point = target
	else:
		var other := world.figure_node(target)
		if other == null:
			return
		point = other.global_position
	var dir := point - node.global_position
	if Vector2(dir.x, dir.z).length() < 0.01:
		return
	turn.rotation.y = atan2(-dir.x, -dir.z)  # the figures face -Z
