extends SceneTree
## QA only: photographs the actual imported game actor with gameplay paused.

func _initialize() -> void:
	call_deferred("run")

func find_type(node: Node, type_name: String) -> Node:
	if node.is_class(type_name): return node
	for child in node.get_children():
		var result := find_type(child, type_name)
		if result != null: return result
	return null

func run() -> void:
	set_meta("killgore_start_level", 13)
	set_meta("killgore_level_select", true)
	set_meta("killgore_random_seed", 1337)
	change_scene_to_file("res://Main.tscn")
	for frame in 120: await process_frame
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	var main = current_scene
	main.set_physics_process(false)
	main.set_process(false)
	main.transition.visible = false
	var runtime = main.level_manager.horror_runtime
	var player = main.player
	player.set_process_input(false)
	player.set_physics_process(false)
	player.set_process(false)
	player.paused = false
	var driver = runtime.creature_animation_driver
	var bay: Node3D = runtime.dark_crossings.crossings[0].node
	var creature_position := bay.to_global(Vector3(1.4, 0.005, 2.5))
	runtime.monster_root.global_position = creature_position
	runtime.monster_root.rotation.y = bay.global_rotation.y
	runtime.monster_root.show()
	player.global_position = bay.to_global(Vector3(1.4, 0.48, -3.5))
	player.camera.global_position = bay.to_global(Vector3(1.4, 1.65, -3.5))
	player.camera.look_at(creature_position + Vector3.UP * 0.65)
	player.camera.current = true
	player.horror_battery_seconds = 100.0
	player.flashlight_on = true
	player._update_horror_flashlight_visibility()
	runtime.memory_room_visibility_timer = 0.0
	runtime._update_memory_room_visibility(0.1, player)
	for pose: StringName in [&"Idle", &"Locomotion", &"Blocked", &"Attack"]:
		for frame in (8 if pose == &"Attack" else 24):
			driver.advance_visual(1.0 / 60.0, pose, 1.3 if pose == &"Locomotion" else 0.0)
			player._tick_horror_flashlight(1.0 / 60.0)
			await process_frame
		RenderingServer.force_draw(false)
		root.get_texture().get_image().save_png("/private/tmp/creature_horror_%s.png" % pose)
		print("CREATURE_HORROR_PREVIEW ", pose)
	quit()
