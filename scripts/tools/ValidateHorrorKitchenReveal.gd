extends SceneTree
## Verify threshold, phase durations, disappearance and cinematic unlock.
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func run() -> void:
	set_meta("killgore_start_level",13)
	set_meta("killgore_level_select",true)
	set_meta("killgore_random_seed",1337)
	var main = load("res://Main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	main.set_process(false)
	main.set_physics_process(false)
	var p = main.player
	p.set_process(false)
	p.set_physics_process(false)
	p.paused = false
	p.set_horror_hidden(false)
	var r = main.level_manager.horror_runtime
	var anchor: Vector3 = r.task_anchors.kitchen
	p.global_position = anchor+Vector3(0,0.48,3.1)
	p.camera.global_position = p.global_position+Vector3.UP*1.36
	p.camera.look_at(r.kitchen_woman_figure.global_position+Vector3.UP*.86)
	check(not r._should_trigger_kitchen_woman_jumpscare(p),"Reveal triggered before doorway")
	p.global_position.z = anchor.z+2.30
	p.camera.global_position = p.global_position+Vector3.UP*1.36
	p.camera.look_at(r.kitchen_woman_figure.global_position+Vector3.UP*.86)
	check(r._should_trigger_kitchen_woman_jumpscare(p),"Reveal missing at doorway")
	r._tick_kitchen_woman_jumpscare(.01,p)
	check(r.kitchen_woman_jumpscare_state=="focus" and p.horror_cinematic_locked,"Missing focus/lock")
	r._tick_kitchen_woman_jumpscare(.56,p)
	check(r.kitchen_woman_jumpscare_state=="blackout" and r.kitchen_woman_blackout.visible and not r.kitchen_woman_figure.visible,"Blackout did not hide woman")
	r._tick_kitchen_woman_jumpscare(1.01,p)
	check(r.kitchen_woman_jumpscare_state=="reveal" and not r.kitchen_woman_blackout.visible,"Blackout did not end")
	r._tick_kitchen_woman_jumpscare(.36,p)
	check(r.kitchen_woman_jumpscare_state=="done" and not p.horror_cinematic_locked,"Cinematic did not release player")
	r._tick_kitchen_woman_jumpscare(10,p)
	check(r.kitchen_woman_jumpscare_state=="done","One-shot reveal restarted")
	if failures==0: print("HORROR_KITCHEN_REVEAL_OK")
	main.queue_free()
	for frame in 4: await process_frame
	quit(1 if failures else 0)
