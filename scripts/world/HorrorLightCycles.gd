extends Node
## Local deterministic schedules; no global random draws or monster spawning.
const PROFILES := {
	"regular": {"on_time": 24.0, "off_time": 7.0, "warning_time": 2.4, "flicker_count": 2, "randomness": 0.0, "warning_sound": true, "monster_safe": true},
	"warning": {"on_time": 29.0, "off_time": 10.0, "warning_time": 3.0, "flicker_count": 4, "randomness": 0.0, "warning_sound": true, "monster_safe": true},
	"irregular": {"on_time": 26.0, "off_time": 9.0, "warning_time": 3.0, "flicker_count": 3, "randomness": 0.18, "warning_sound": true, "monster_safe": true},
	"trap": {"on_time": 32.0, "off_time": 11.0, "warning_time": 3.2, "flicker_count": 5, "randomness": 0.10, "warning_sound": true, "monster_safe": true}
}
var runtime
var entries: Array[Dictionary] = []
var neighbors: Dictionary = {}
var random := RandomNumberGenerator.new()

func build(owner_runtime) -> void:
	runtime = owner_runtime
	random.seed = 712031
	var links: Array = runtime.dark_crossings._light_links(runtime.maze_raw)
	var distances := {}
	for link in links:
		var a: int = link.lights[0]
		var b: int = link.lights[1]
		neighbors.get_or_add(a, []).append(b)
		neighbors.get_or_add(b, []).append(a)
		distances[a] = maxf(float(distances.get(a, 0.0)), link.cells.size() * 4.0)
		distances[b] = maxf(float(distances.get(b, 0.0)), link.cells.size() * 4.0)
	var chosen := {}
	var cap := maxi(3, runtime.route_light_positions.size() / 5)
	for index in runtime.route_light_positions.size():
		if index == 0 or index % 2 == 0 or chosen.size() >= cap: continue
		var pos: Vector3 = runtime.route_light_positions[index]
		if runtime._inside_kitchen_art_zone(pos) or pos.distance_to(runtime.level_manager.spawn_pos) < 30.0: continue
		if neighbors.get(index, []).is_empty(): continue
		var adjacent_dynamic := false
		for other in neighbors[index]:
			if chosen.has(other): adjacent_dynamic = true
		if adjacent_dynamic: continue
		chosen[index] = true
		var kind: String = ["regular", "warning", "irregular"][entries.size() % 3]
		var fixture: Node3D = runtime.get_node("SafeCeilingFixture_%03d" % index)
		var ward: Dictionary = fixture.get_meta("cycle_ward")
		var config: Dictionary = PROFILES[kind].duplicate()
		# Travel distance sets bounds; adjacent refuge lights remain permanent.
		var travel := float(distances.get(index, 24.0)) / 3.75
		config.off_time = clampf(maxf(config.off_time, travel + 1.5), 7.0, 13.0)
		config.on_time = maxf(config.on_time, travel * 2.0 + 8.0)
		var tube: MeshInstance3D = fixture.get_meta("cycle_tube")
		var material: StandardMaterial3D = tube.material_override.duplicate()
		tube.material_override = material
		var sound := AudioStreamPlayer3D.new()
		sound.stream = _warning_sound()
		sound.volume_db = -27.0
		sound.max_distance = 16.0
		fixture.add_child(sound)
		var entry := {"index": index, "kind": kind, "config": config, "ward": ward, "light": fixture.get_node("SafeDownlight"), "material": material, "sound": sound, "state": "on", "time": 0.0, "duration": config.on_time + entries.size() * 2.7, "cycle": 0, "active": true}
		ward["cycle_active"] = true
		ward["cycle_pulse"] = 1.0
		entries.append(entry)
	# One trap at most, with at least two fixed connected exits; never a dead end.
	if entries.size() >= 6:
		for entry in entries:
			if neighbors[entry.index].size() < 2 or entry.kind != "irregular": continue
			entry.kind = "trap"
			entry.config = PROFILES.trap.duplicate()
			entry.duration = entry.config.on_time
			break
	for entry in entries:
		var tint := Color8(222, 209, 169)
		if entry.kind in ["warning", "irregular"]: tint = Color8(198, 213, 207)
		if entry.kind == "trap": tint = Color8(227, 182, 137)
		entry.light.light_color = tint
		entry["color"] = tint

func tick(dt: float, player) -> void:
	if player.horror_cinematic_locked: return
	for e in entries:
		e.time += dt
		var config: Dictionary = e.config
		if e.state == "on" and e.kind == "trap":
			# Repeated double dip and warmer tint telegraph its different character.
			if e.time >= 4.0 and player.global_position.distance_to(e.ward.position) < 2.8:
				e.time = e.duration
		if e.time >= e.duration:
			e.time = 0.0
			match e.state:
				"on":
					e.state = "warning"
					e.duration = config.warning_time
					e["warning_beats"] = int(config.flicker_count) + (random.randi_range(-1, 1) if e.kind == "irregular" else 0)
					if config.warning_sound: e.sound.play()
				"warning":
					e.state = "off"
					e.duration = config.off_time * random.randf_range(1.0 - config.randomness, 1.0 + config.randomness)
				"off":
					e.state = "relight"
					e.duration = 0.85
				"relight":
					e.state = "on"
					e.cycle += 1
					e.duration = config.on_time * random.randf_range(1.0 - config.randomness, 1.0 + config.randomness)
		var pulse := 1.0
		match e.state:
			"warning": pulse = 0.38 + 0.62 * pow(absf(cos(e.time / e.duration * PI * int(e.get("warning_beats", config.flicker_count)))), 2.0)
			"off": pulse = 0.0
			"relight": pulse = smoothstep(0.0, 0.85, e.time)
			"on":
				if e.kind == "trap" and fmod(e.time, 4.2) < 0.65:
					pulse = 0.70 + 0.30 * absf(cos(e.time * 9.66))
		var active: bool = config.monster_safe and e.state != "off" and (e.state != "relight" or pulse >= 0.35)
		e.ward.cycle_pulse = pulse
		if active != e.active:
			e.active = active
			e.ward.cycle_active = active
			runtime._refresh_cycle_navigation(e.ward)
			# Relight is allowed to catch a creature already inside; it escapes
			# continuously rather than teleporting or getting stuck in a solid cell.
			if active: runtime.monster_repath_timer = 0.0
		e.light.light_energy = 24.0 * pulse
		e.material.albedo_color = Color(0.08, 0.08, 0.07).lerp(e.color, pulse)
		e.material.emission = e.color
		e.material.emission_energy_multiplier = 1.7 * pulse

func _warning_sound() -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(11025)
	for i in bytes.size():
		var t := float(i) / 22050.0
		var envelope := sin(PI * float(i) / bytes.size())
		var sample := sin(TAU * 113.0 * t) * sin(TAU * 937.0 * t) * envelope * 0.3
		bytes[i] = int(sample * 127.0) & 255
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = 22050
	stream.data = bytes
	return stream
