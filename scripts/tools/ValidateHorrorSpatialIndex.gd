extends SceneTree
var failures := 0
var checks := 0
func _initialize() -> void: call_deferred("run")
func verify(condition: bool, label: String) -> void:
	checks+=1
	if not condition:
		failures+=1
		push_error(label)
func run() -> void:
	set_meta("killgore_start_level",13)
	set_meta("killgore_level_select",true)
	set_meta("killgore_random_seed",1337)
	change_scene_to_file("res://Main.tscn")
	for i in 8: await process_frame
	current_scene.set_physics_process(false)
	var manager = current_scene.level_manager
	var runtime = manager.horror_runtime
	var rng := RandomNumberGenerator.new()
	rng.seed=1337
	for solid in manager.solid_areas:
		for radius in [0.42,0.85]:
			for offset in [Vector3.ZERO,Vector3(solid.half.x+radius,0,0),Vector3(0,0,solid.half.y+radius),Vector3(-solid.half.x-radius-0.01,0,0)]:
				var p: Vector3=solid.center+offset
				p.y=0.48
				var expected:=false
				for original in manager.solid_areas:
					if p.y<float(original.height)-0.16 and absf(p.x-original.center.x)<=original.half.x+radius and absf(p.z-original.center.z)<=original.half.y+radius:
						expected=true
						break
				verify(manager._solid_area_blocks(p,radius)==expected,"Spatial collision differs at "+str(p))
	for i in 500:
		var solid: Dictionary = manager.solid_areas[i%manager.solid_areas.size()]
		var a: Vector3=solid.center+Vector3(rng.randf_range(-12,12),0,rng.randf_range(-12,12))
		a.y=1.0
		var b:=a+Vector3(rng.randf_range(-22,22),0,rng.randf_range(-22,22))
		var expected:=false
		var actual:=false
		for original in manager.solid_areas:
			if intersects(original,a,b): expected=true; break
		for candidate in manager.query_solid_areas(a,b):
			if intersects(candidate,a,b): actual=true; break
		verify(actual==expected,"Spatial ray differs")
	for ward in runtime.monster_warding_lights:
		for offset in [Vector3.ZERO,Vector3(float(ward.radius)+0.8,0,0),Vector3(0,0,float(ward.radius)+0.9)]:
			var p: Vector3=ward.position+offset
			var expected:=false
			for original in runtime.monster_warding_lights:
				if original.get("safe_zone",false) and p.distance_to(original.position)<=float(original.radius)+0.85 and runtime._grid_has_clear_line(p+Vector3.UP*0.5,original.position+Vector3.UP*0.5):
					expected=true
					break
			verify(runtime._monster_position_in_warding_light(p,0.85)==expected,"Safe light index differs")
	print("HORROR_SPATIAL_INDEX_CHECKS=",checks," FAILURES=",failures)
	quit(0 if failures==0 else 1)
func intersects(solid: Dictionary,a: Vector3,b: Vector3) -> bool:
	return AABB(Vector3(solid.center.x-solid.half.x,0,solid.center.z-solid.half.y),Vector3(solid.half.x*2,float(solid.height),solid.half.y*2)).intersects_segment(a,b)!=null
