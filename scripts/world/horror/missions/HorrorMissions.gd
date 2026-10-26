extends RefCounted
## Missions responsibility extracted from HorrorSequenceLevel.
## No autonomous ticks or scene ownership; runtime coordinates lifecycle.
## Bare runtime dependencies are explicit parameters; pure helpers need none.

func use(_runtime, player) -> bool:
	var item = nearest_interactable(_runtime, player, 2.45)
	if item.is_empty():
		return false
	handle_interaction(_runtime, item, player)
	return true

func interact_prompt(_runtime, player) -> String:
	var item = nearest_interactable(_runtime, player, 2.45)
	if item.is_empty():
		return ""
	if String(item.get("action", "")) == "hide_locker" and bool(player.horror_hidden):
		return "E  LEAVE LOCKER"
	return "E  %s" % String(item.get("label", "INTERACT"))

func objective_text(_runtime) -> String:
	if not bool(_runtime.task_states.get("kitchen", {}).get("complete", false)):
		var state: Dictionary = _runtime.task_states.get("kitchen", {})
		if bool(state.get("cooking", false)):
			return "KITCHEN: The stove is loud. Stay alive until the meal is ready"
		return "KITCHEN: Find the pan, knife and ingredients (%d / 3)" % int(state.get("found", {}).size())
	if not task_fragment_collected(_runtime, "kitchen"):
		return "KITCHEN: Collect the materialized memory fragment"
	if not bool(_runtime.task_states.get("car", {}).get("complete", false)):
		var state: Dictionary = _runtime.task_states.get("car", {})
		return "ROADSIDE: Recover and install the tire, fuel and engine part (%d / 3)" % int(state.get("installed", 0))
	if not task_fragment_collected(_runtime, "car"):
		return "ROADSIDE: Collect the materialized memory fragment"
	if not bool(_runtime.task_states.get("passport", {}).get("complete", false)):
		var state: Dictionary = _runtime.task_states.get("passport", {})
		if not _runtime.passport_guide_read:
			return "CHECKPOINT: Find and read the processing guide"
		return "CHECKPOINT: Submit PASSPORT, VISA, DECLARATION (%d / 3)" % int(state.get("submitted", 0))
	if not task_fragment_collected(_runtime, "passport"):
		return "CHECKPOINT: Collect the materialized memory fragment"
	return "All memories recovered. Reach the memory gate"

func task_fragment_collected(_runtime, task_id: String) -> bool:
	for fragment in _runtime.fragments:
		if String(fragment.get("task", "")) == task_id:
			return bool(fragment.get("collected", false))
	return false

func map_markers(_runtime) -> Array:
	var out: Array = []
	for task_id in ["kitchen", "car", "passport"]:
		if _runtime.task_anchors.has(task_id):
			out.append({
				"id": task_id,
				"position": _runtime.task_anchors[task_id],
				"complete": bool(_runtime.task_states.get(task_id, {}).get("complete", false))
			})
	return out

func tick_tasks(_runtime, dt: float) -> void:
	if _runtime.cooking_timer <= 0.0:
		return
	_runtime.cooking_timer = max(0.0, _runtime.cooking_timer - dt)
	_runtime._make_noise(_runtime.task_anchors["kitchen"], 1.0, 0.35)
	if _runtime.cooking_timer <= 0.0:
		complete_task(_runtime, "kitchen")
		_runtime.level_manager.message.emit("THE MEAL REMEMBERS YOU")

func tick_interactables(_runtime, dt: float, player) -> void:
	for item in _runtime.interactables:
		var node = item.get("node")
		if not bool(item.get("active", true)) or not is_instance_valid(node):
			continue
		if bool(item.get("bob", true)):
			node.rotation.y += dt * 0.55
			node.position.y = float(item.get("base_y", node.position.y)) + sin(_runtime.elapsed * 1.7 + float(item.get("phase", 0.0))) * 0.035

func nearest_interactable(_runtime, player, radius: float) -> Dictionary:
	if player == null:
		return {}
	if bool(player.horror_hidden) and not _runtime.active_locker.is_empty():
		return _runtime.active_locker
	var best: Dictionary = {}
	var best_distance = radius * radius
	for item in _runtime.interactables:
		if not bool(item.get("active", true)):
			continue
		var node = item.get("node")
		if not is_instance_valid(node):
			continue
		var distance = player.global_position.distance_squared_to(node.global_position)
		if distance < best_distance:
			best_distance = distance
			best = item
	return best

func handle_interaction(_runtime, item: Dictionary, player = null) -> void:
	var action = String(item.get("action", ""))
	var item_id = String(item.get("id", ""))
	match action:
		"hide_locker":
			if player == null:
				return
			if bool(player.horror_hidden):
				var leave_position: Vector3 = item.get("exit_position", player.global_position)
				player.set_horror_hidden(false)
				player.global_position = leave_position
				_runtime._make_noise(leave_position, 0.34, 0.42)
				_runtime.active_locker = {}
				_runtime.monster_saw_locker_entry = false
				_runtime.monster_heard_locker_entry = false
				_runtime.monster_locker_suspicion = 0.0
				_runtime.monster_locker_decision_made = false
			else:
				var locker_position: Vector3 = item["node"].global_position
				var monster_distance = _runtime.monster_root.global_position.distance_to(player.global_position) if is_instance_valid(_runtime.monster_root) else INF
				_runtime.monster_saw_locker_entry = is_instance_valid(_runtime.monster_root) and _runtime._monster_can_see_player(player, monster_distance)
				_runtime.monster_heard_locker_entry = is_instance_valid(_runtime.monster_root) and _runtime.monster_root.global_position.distance_to(locker_position) <= 9.5
				_runtime.active_locker = item
				_runtime.monster_locker_check_timer = 0.0
				_runtime.monster_locker_decision_made = false
				if _runtime.monster_saw_locker_entry:
					_runtime.monster_locker_suspicion = 1.0
				elif _runtime.monster_heard_locker_entry:
					_runtime.monster_locker_suspicion = 0.66
				elif _runtime.monster_state == "chase":
					_runtime.monster_locker_suspicion = 0.46
				else:
					_runtime.monster_locker_suspicion = 0.18
				if _runtime.monster_saw_locker_entry:
					_runtime.monster_last_known_position = locker_position
					_runtime._begin_monster_search(locker_position)
				elif _runtime.monster_state == "chase":
					_runtime._begin_monster_search(_runtime.monster_last_known_position)
				_runtime._make_noise(locker_position, 0.30, 0.38)
				player.set_horror_hidden(true, item.get("hide_position", player.global_position), float(item.get("hide_yaw", player.yaw)))
		"kitchen_item":
			var found: Dictionary = _runtime.task_states["kitchen"]["found"]
			if not found.has(item_id):
				found[item_id] = true
				consume_interactable(item)
				_runtime._make_noise(item["node"].global_position if is_instance_valid(item.get("node")) else _runtime.task_anchors["kitchen"], 0.42, 2.4)
				_runtime.level_manager.message.emit("KITCHEN ITEM: %s" % String(item.get("short", item_id)).to_upper())
		"kitchen_stove":
			var state: Dictionary = _runtime.task_states["kitchen"]
			if bool(state.get("complete", false)) or bool(state.get("cooking", false)):
				return
			if int(state["found"].size()) < 3:
				_runtime.level_manager.message.emit("THE RECIPE IS INCOMPLETE")
				return
			state["cooking"] = true
			_runtime.cooking_timer = 8.0
			_runtime._make_noise(_runtime.task_anchors["kitchen"], 1.0, 8.5)
			_runtime.level_manager.message.emit("COOKING STARTED")
		"car_part":
			var collected: Dictionary = _runtime.task_states["car"]["collected"]
			if not collected.has(item_id):
				collected[item_id] = true
				consume_interactable(item)
				_runtime.level_manager.message.emit("CAR PART: %s" % String(item.get("short", item_id)).to_upper())
		"car_install":
			var state: Dictionary = _runtime.task_states["car"]
			if bool(state.get("complete", false)):
				return
			var next_part = ""
			for part in ["tire", "fuel", "engine"]:
				if state["collected"].has(part) and not state["fitted"].has(part):
					next_part = part
					break
			if next_part == "":
				_runtime.level_manager.message.emit("FIND A MISSING CAR PART")
				return
			state["fitted"][next_part] = true
			state["installed"] = int(state.get("installed", 0)) + 1
			_runtime._make_noise(_runtime.task_anchors["car"], 0.88, 4.0)
			_runtime.level_manager.message.emit("INSTALLED %s (%d / 3)" % [next_part.to_upper(), int(state["installed"])])
			if int(state["installed"]) >= 3:
				complete_task(_runtime, "car")
		"passport_guide":
			_runtime.passport_guide_read = true
			_runtime.level_manager.message.emit("ORDER: PASSPORT > VISA > DECLARATION")
		"passport_doc":
			var documents: Dictionary = _runtime.task_states["passport"]["documents"]
			if not documents.has(item_id):
				documents[item_id] = true
				consume_interactable(item)
				activate_submission_pad(_runtime, item_id)
				_runtime.level_manager.message.emit("DOCUMENT FOUND: %s" % item_id.to_upper())
		"passport_submit":
			submit_passport_document(_runtime, item_id)

func consume_interactable(item: Dictionary) -> void:
	item["active"] = false
	var node = item.get("node")
	if is_instance_valid(node):
		node.visible = false

func activate_submission_pad(_runtime, document_id: String) -> void:
	for item in _runtime.interactables:
		if String(item.get("action", "")) == "passport_submit" and String(item.get("id", "")) == document_id:
			item["active"] = true
			var node = item.get("node")
			if is_instance_valid(node):
				node.visible = true

func submit_passport_document(_runtime, document_id: String) -> void:
	if not _runtime.passport_guide_read:
		_runtime.level_manager.message.emit("READ THE PROCESSING GUIDE FIRST")
		return
	var state: Dictionary = _runtime.task_states["passport"]
	var order = ["passport", "visa", "declaration"]
	var expected = String(order[int(state.get("submitted", 0))])
	if document_id != expected:
		state["submitted"] = 0
		_runtime._make_noise(_runtime.task_anchors["passport"], 1.0, 5.0)
		_runtime.level_manager.message.emit("PROCESSING ERROR. ORDER RESET")
		return
	state["submitted"] = int(state.get("submitted", 0)) + 1
	_runtime.level_manager.message.emit("ACCEPTED: %s" % document_id.to_upper())
	if int(state["submitted"]) >= 3:
		complete_task(_runtime, "passport")

func complete_task(_runtime, task_id: String) -> void:
	var state: Dictionary = _runtime.task_states[task_id]
	if bool(state.get("complete", false)):
		return
	state["complete"] = true
	_runtime.monster_director_tension = min(1.0, _runtime.monster_director_tension + 0.20)
	_runtime._add_memory_fragment(_runtime.task_anchors[task_id], task_id)
	_runtime.level_manager.message.emit("MEMORY FRAGMENT MATERIALIZED")

func add_interactable(_runtime, item_id: String, action: String, node: Node3D, label: String, short_label: String, bob: bool = true, active: bool = true, extra: Dictionary = {}) -> void:
	node.set_meta("skip_static_room_batch", true)
	var entry = {
		"id": item_id,
		"action": action,
		"node": node,
		"label": label,
		"short": short_label,
		"active": active,
		"bob": bob,
		"base_y": node.position.y,
		"phase": float(_runtime.interactables.size()) * 1.31
	}
	for key in extra.keys():
		entry[key] = extra[key]
	_runtime.interactables.append(entry)

func collect_fragment(_runtime, fragment: Dictionary) -> void:
	fragment["collected"] = true
	_runtime.fragments_collected += 1
	var node: Node3D = fragment["node"]
	var tween = _runtime.create_tween().bind_node(node).set_parallel(true)
	tween.tween_property(node, "scale", Vector3(2.6, 2.6, 2.6), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "position:y", node.position.y + 0.75, 0.22)
	tween.chain().tween_property(node, "scale", Vector3.ZERO, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(node.queue_free)
	_runtime.fragment_collected.emit(_runtime.fragments_collected, _runtime.FRAGMENT_TOTAL)
	if _runtime.fragments_collected >= _runtime.FRAGMENT_TOTAL:
		unlock_exit(_runtime)

func unlock_exit(_runtime) -> void:
	if is_instance_valid(_runtime.exit_light):
		_runtime.exit_light.light_color = Color8(185, 218, 164)
		_runtime.exit_light.light_energy = 2.8
	if is_instance_valid(_runtime.exit_panel):
		_runtime.exit_panel.material_override = _runtime._glow_material(Color8(155, 201, 139), 3.0)

