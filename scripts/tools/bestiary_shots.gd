extends SceneTree
## Renders one portrait per enemy to assets/bestiary/<id>.png. Run once, not headless:
## tools/godot.cmd --path . --script res://scripts/tools/bestiary_shots.gd
## then --headless --path . --import. Excluded from the exports (scripts/tools/*).

const ACTOR_SCENE := preload("res://scenes/battle/battle_actor.tscn")
const SIZE := Vector2i(128, 128)


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/bestiary"))
	for id: String in EnemyLibrary.ENEMIES:
		var view := SubViewport.new()
		view.size = SIZE
		view.transparent_bg = true
		view.own_world_3d = true
		view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(view)
		var sun := DirectionalLight3D.new()
		sun.rotation_degrees = Vector3(-50, 30, 0)
		view.add_child(sun)
		var environment := Environment.new()
		environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		environment.ambient_light_color = Color.WHITE
		environment.ambient_light_energy = 0.7
		var world := WorldEnvironment.new()
		world.environment = environment
		view.add_child(world)
		var actor := ACTOR_SCENE.instantiate() as BattleActor
		actor.look = EnemyLibrary.look(id)
		view.add_child(actor)
		var camera := Camera3D.new()
		var top := actor.top_height()
		camera.position = Vector3(0, top * 0.55, -maxf(2.2, top * 1.9))
		camera.fov = 40.0
		view.add_child(camera)
		camera.look_at(Vector3(0, top * 0.45, 0))
		camera.current = true
		for frame in 8:
			await process_frame
		await RenderingServer.frame_post_draw
		view.get_texture().get_image().save_png("res://assets/bestiary/%s.png" % id)
		view.queue_free()
	quit()
