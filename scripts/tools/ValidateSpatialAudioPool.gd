extends SceneTree

const AudioManagerScript = preload("res://scripts/core/AudioManager.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var audio = AudioManagerScript.new()
	root.add_child(audio)
	await process_frame

	for i in 12:
		audio.play_at("enemy_shoot", Vector3(float(i), 0.0, 0.0), 0.03)
	if audio.active_spatial_players.size() != 12:
		_fail("first burst did not create 12 active players")
		return
	var first_ids: Dictionary = {}
	for player in audio.active_spatial_players:
		first_ids[player.get_instance_id()] = true

	audio.stop("enemy_shoot")
	await process_frame
	if not audio.active_spatial_players.is_empty():
		_fail("stopped one-shots remained active")
		return
	if audio.spatial_one_shot_pool.size() != 12:
		_fail("expected 12 pooled players after first burst")
		return

	for i in 12:
		audio.play_at("enemy_shoot", Vector3(float(i), 0.0, 1.0), 0.03)
	var reused := 0
	for player in audio.active_spatial_players:
		if first_ids.has(player.get_instance_id()):
			reused += 1
	if reused != 12:
		_fail("second burst did not fully reuse the pool")
		return

	audio.stop("enemy_shoot")
	await process_frame
	print("SPATIAL_AUDIO_POOL_OK active=0 pooled=%d reused=%d" % [audio.spatial_one_shot_pool.size(), reused])
	quit(0)


func _fail(message: String) -> void:
	push_error("SPATIAL_AUDIO_POOL_FAIL: %s" % message)
	quit(1)
