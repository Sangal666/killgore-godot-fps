extends RefCounted
## Persistent local decisions: approach the edge, watch, orbit or hold a corner.
var state := "Dormant"
var age := 0.0
var watch_timer := 0.0
var decision_timer := 0.0
var side := 1.0
var failed_plans := 0
var attention_beats := 0
func enter() -> void:
	state = "Hesitate"
	age = 0.0
	watch_timer = 0.30
	decision_timer = 0.0
	failed_plans = 0
	attention_beats = 0
func release() -> void:
	state = "Reacquire"
func tick(r, dt: float, p, pressure: float) -> void:
	age += dt
	watch_timer = maxf(0,watch_timer-dt)
	decision_timer -= dt
	if watch_timer>0 and pressure<0.30:
		state = "Watch"
		r.monster_current_speed = move_toward(r.monster_current_speed,0,dt*4.0)
		return
	if decision_timer<=0:
		var planned: bool = r._plan_flashlight_retreat()
		decision_timer = 0.9
		if planned:
			failed_plans = 0
			state = "EdgeStep" if pressure>0 else "Orbit"
		else:
			failed_plans += 1
			state = "CornerWatch"
			if failed_plans==2: side *= -1.0
			watch_timer = 0.55
	if r.creature_retreat_path.is_empty():
		state = "CornerWatch"
		r.monster_current_speed = move_toward(r.monster_current_speed,0,dt*4.0)
	else:
		r.monster_current_speed = move_toward(r.monster_current_speed,0.72,dt*2.0)
		r._advance_monster_motion(dt,p,r.monster_current_speed)
	if age > 2.7+attention_beats*3.4 and pressure<=0:
		attention_beats += 1
		watch_timer = 0.45+0.12*sin(age*0.7)
