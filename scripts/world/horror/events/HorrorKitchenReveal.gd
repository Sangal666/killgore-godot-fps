extends RefCounted
## Events responsibility extracted from HorrorSequenceLevel.
## No autonomous ticks or scene ownership; runtime coordinates lifecycle.
## Bare runtime dependencies are explicit parameters; pure helpers need none.

func build_kitchen_woman_blackout(_runtime) -> void:
	var layer = CanvasLayer.new()
	layer.name = "KitchenWomanJumpscareLayer"
	layer.layer = 120
	_runtime.add_child(layer)
	_runtime.kitchen_woman_blackout = ColorRect.new()
	_runtime.kitchen_woman_blackout.name = "Blackout"
	_runtime.kitchen_woman_blackout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_runtime.kitchen_woman_blackout.color = Color(0.0, 0.0, 0.0, 0.0)
	_runtime.kitchen_woman_blackout.visible = false
	layer.add_child(_runtime.kitchen_woman_blackout)
	_runtime.kitchen_woman_blackout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func tick_kitchen_woman_jumpscare(_runtime, dt: float, player) -> void:
	if player == null or _runtime.kitchen_woman_jumpscare_state == "done" or not is_instance_valid(_runtime.kitchen_woman_figure):
		return
	if _runtime.kitchen_woman_jumpscare_state == "waiting":
		if should_trigger_kitchen_woman_jumpscare(_runtime, player):
			_runtime.kitchen_woman_jumpscare_state = "focus"
			_runtime.kitchen_woman_jumpscare_timer = _runtime.KITCHEN_WOMAN_FOCUS_DURATION
			player.set_horror_cinematic_lock(true)
			aim_player_at_kitchen_woman(_runtime, player)
		return
	aim_player_at_kitchen_woman(_runtime, player)
	if _runtime.kitchen_woman_jumpscare_state == "focus":
		_runtime.kitchen_woman_jumpscare_timer = maxf(0.0, _runtime.kitchen_woman_jumpscare_timer - dt)
		if _runtime.kitchen_woman_jumpscare_timer <= 0.0:
			_runtime.kitchen_woman_jumpscare_state = "blackout"
			_runtime.kitchen_woman_jumpscare_timer = _runtime.KITCHEN_WOMAN_BLACKOUT_DURATION
			if is_instance_valid(_runtime.kitchen_woman_blackout):
				_runtime.kitchen_woman_blackout.color = Color.BLACK
				_runtime.kitchen_woman_blackout.visible = true
			_runtime.kitchen_woman_figure.visible = false
	elif _runtime.kitchen_woman_jumpscare_state == "blackout":
		_runtime.kitchen_woman_jumpscare_timer = maxf(0.0, _runtime.kitchen_woman_jumpscare_timer - dt)
		if _runtime.kitchen_woman_jumpscare_timer <= 0.0:
			_runtime.kitchen_woman_jumpscare_state = "reveal"
			_runtime.kitchen_woman_jumpscare_timer = _runtime.KITCHEN_WOMAN_REVEAL_DURATION
			if is_instance_valid(_runtime.kitchen_woman_blackout):
				_runtime.kitchen_woman_blackout.visible = false
	elif _runtime.kitchen_woman_jumpscare_state == "reveal":
		_runtime.kitchen_woman_jumpscare_timer = maxf(0.0, _runtime.kitchen_woman_jumpscare_timer - dt)
		if _runtime.kitchen_woman_jumpscare_timer <= 0.0:
			_runtime.kitchen_woman_jumpscare_state = "done"
			player.set_horror_cinematic_lock(false)

func should_trigger_kitchen_woman_jumpscare(_runtime, player) -> bool:
	if not _runtime.task_anchors.has("kitchen") or bool(player.horror_hidden):
		return false
	var local_position: Vector3 = player.global_position - Vector3(_runtime.task_anchors["kitchen"])
	# The authored doorway plane is at local z=2.30. The short band accounts for
	# the player's capsule so the sequence begins as they cross the threshold,
	# before they can walk toward the table.
	if absf(local_position.x) > 1.05 or local_position.z < 2.05 or local_position.z > 2.58:
		return false
	return _runtime._player_can_see_position(player, _runtime.kitchen_woman_figure.global_position + Vector3.UP * 0.86)

func aim_player_at_kitchen_woman(_runtime, player) -> void:
	var target = _runtime.kitchen_woman_figure.global_position + Vector3.UP * 0.86
	var direction: Vector3 = (target - player.camera_origin()).normalized()
	if direction.length_squared() <= 0.0001:
		return
	player.target_yaw = atan2(-direction.x, -direction.z)
	player.target_pitch = asin(clampf(direction.y, -1.0, 1.0))

