extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	set_meta("killgore_start_level",13)
	set_meta("killgore_level_select",true)
	set_meta("killgore_random_seed",1337)
	change_scene_to_file("res://Main.tscn")
	for i in 180:
		await process_frame
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280,720)
	current_scene.set_physics_process(false)
	current_scene.set_process(false)
	current_scene.transition.visible=false
	var player = current_scene.player
	var runtime = current_scene.level_manager.horror_runtime
	var encounter: Dictionary = runtime.dark_crossings.crossings[0]
	var bay: Node3D = encounter.node
	player.set_physics_process(false)
	player.set_process(false)
	player.paused=false
	player.horror_battery_seconds=100.0
	for shot in [
		{"id":"choice","point":Vector3(0,0,-7),"aim":Vector3(0,1.3,2),"on":true},
		{"id":"dark_silhouette","point":Vector3(0,0,-7),"aim":Vector3(0,1.3,2),"on":false},
		{"id":"cover_lane","point":Vector3(-3.6,0,-3.8),"aim":Vector3(-2.8,1.3,1.5),"on":true},
		{"id":"beam_hold","point":Vector3(1.5,0,-4),"aim":Vector3(1.5,1.15,2),"on":true}
	]:
		player.global_position=bay.to_global(shot.point)+Vector3.UP*0.48
		player.camera.global_position=bay.to_global(shot.point)+Vector3.UP*1.65
		player.camera.look_at(bay.to_global(shot.aim))
		player.camera.current=true
		player.flashlight_on=shot.on
		player._update_horror_flashlight_visibility()
		runtime.memory_room_visibility_timer=0.0
		runtime._update_memory_room_visibility(0.1,player)
		if shot.id=="beam_hold":
			runtime.monster_root.global_position=bay.to_global(Vector3(1.5,0,1.8))
			runtime.monster_root.show()
			runtime.monster_state="chase"
			runtime.darkness_time=5.0
		for frame in 100:
			player._tick_horror_flashlight(1.0/60.0)
			if shot.id=="beam_hold":
				runtime._tick_amalgam(1.0/60.0,player)
			await process_frame
		RenderingServer.force_draw(false)
		root.get_texture().get_image().save_png("/private/tmp/dark_crossing_"+shot.id+".png")
		print("DARK_CAPTURE ",shot.id," FPS=",Engine.get_frames_per_second()," BATTERY=",player.horror_battery_seconds)
	quit()
