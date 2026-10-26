extends RefCounted
## Authored passport composition. Runtime owns nodes and gameplay state.

func build_deferred_passport_placeholder(_runtime, anchor: Vector3) -> void:
	# Neutral processing room reserved for a later dedicated design pass. The
	# existing document-order mechanic remains operational and otherwise intact.
	_runtime.task_states["passport"] = {"complete": false, "documents": {}, "submitted": 0}
	var root = Node3D.new()
	root.name = "MemoryRoom_PassportControl"
	root.position = anchor
	_runtime.add_child(root)
	_runtime._register_memory_room_visual(root, Vector2(6.0, 6.0))
	var dark = _runtime._room_surface(Color8(34, 35, 32), 0.96)
	var paper = _runtime._dim_lit_material(Color8(148, 142, 119), 0.88, 0.25)
	var metal = _runtime._room_surface(Color8(62, 64, 58), 0.78)
	# A single temporary desk and loose documents mark the reserved interaction
	# points without creating a premature airport/checkpoint composition.
	_runtime._add_box(root, Vector3(4.80, 0.12, 1.20), Vector3(0.0, 0.88, 0.20), dark)
	for x in [-2.10, 2.10]:
		_runtime._add_box(root, Vector3(0.12, 0.88, 1.05), Vector3(x, 0.44, 0.20), metal)
	var guide = _runtime._make_task_prop(root, Vector3(-1.65, 1.02, 0.15), "guide", paper)
	_runtime._add_interactable("guide", "passport_guide", guide, "READ PROCESSING GUIDE", "GUIDE")
	_runtime._add_interactable("passport", "passport_doc", _runtime._make_task_prop(root, Vector3(-2.75, 0.72, 2.55), "paper", paper), "TAKE PASSPORT", "PASSPORT")
	_runtime._add_interactable("visa", "passport_doc", _runtime._make_task_prop(root, Vector3(0.0, 0.72, 2.85), "paper", paper), "TAKE VISA", "VISA")
	_runtime._add_interactable("declaration", "passport_doc", _runtime._make_task_prop(root, Vector3(2.75, 0.72, 2.55), "paper", paper), "TAKE DECLARATION", "DECLARATION")
	for index in 3:
		var document_id = String(["passport", "visa", "declaration"][index])
		var pad = _runtime._make_task_prop(root, Vector3(-1.35 + float(index) * 1.35, 1.02, 0.15), "paper", paper)
		pad.visible = false
		_runtime._add_interactable(document_id, "passport_submit", pad, "SUBMIT %s" % document_id.to_upper(), document_id.to_upper(), true, false)
	_runtime._add_room_light(root, Vector3(0.0, 3.05, 0.0), Color8(151, 143, 112), 1.10, 7.0)
	_runtime._batch_static_room_boxes(root)

func build_passport_scenario(_runtime, anchor: Vector3) -> void:
	_runtime.task_states["passport"] = {"complete": false, "documents": {}, "submitted": 0}
	var root = Node3D.new()
	root.name = "MemoryRoom_PassportControl"
	root.position = anchor
	_runtime.add_child(root)
	_runtime._register_memory_room_visual(root, Vector2(42.0, 17.5))
	var institutional = _runtime._room_surface(Color8(111, 115, 108), 0.82, 0.12)
	var dirty_white = _runtime._room_surface(Color8(188, 186, 165), 0.72, 0.04)
	var dark = _runtime._room_surface(Color8(44, 48, 47), 0.96)
	var rubber = _runtime._room_surface(Color8(37, 39, 37), 0.92)
	var glass = _runtime._room_surface(Color(0.16, 0.25, 0.25, 0.48), 0.20, 0.22)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var cyan = _runtime._glow_material(Color8(68, 115, 111), 1.40)
	var amber = _runtime._glow_material(Color8(191, 137, 55), 1.9)
	var warning = _runtime._glow_material(Color8(155, 48, 38), 2.0)
	_runtime._add_box(root, Vector3(84.0, 0.10, 35.0), Vector3.ZERO, dark)
	# Full ceiling and a pale central concourse make the architecture readable
	# before the player reaches the desk. Side lanes stay darker and abandoned.
	_runtime._add_segmented_ceiling(root, Vector2(83.0, 34.0), 10, 5, institutional, dark)
	_runtime._add_box(root, Vector3(19.0, 0.026, 33.0), Vector3(0.0, 0.075, 0.0), _runtime._dim_lit_material(Color8(96, 103, 95), 0.90, 0.32))
	# Side cladding encloses the checkpoint in human-scale bays while preserving
	# the wide central entrance and all mission-object access.
	for z in [-11.8, -4.0, 3.8, 11.6]:
		_runtime._add_box(root, Vector3(0.20, 3.35, 7.2), Vector3(-41.55, 1.69, z), institutional)
		_runtime._add_box(root, Vector3(0.20, 3.35, 7.2), Vector3(41.55, 1.69, z), institutional)
		_runtime._add_box(root, Vector3(0.055, 0.72, 5.6), Vector3(-41.40, 1.88, z), dirty_white)
		_runtime._add_box(root, Vector3(0.055, 0.72, 5.6), Vector3(41.40, 1.88, z), dirty_white)
	# Dirty terrazzo bands lead the player through the queue and prevent the
	# entire checkpoint from collapsing into one black floor.
	for x in [-30.0, -18.0, -6.0, 6.0, 18.0, 30.0]:
		_runtime._add_box(root, Vector3(9.0, 0.025, 31.0), Vector3(x, 0.07, 0.0), _runtime._dim_lit_material(Color8(70, 74, 70), 0.90, 0.10))
	_runtime._add_box(root, Vector3(3.6, 0.035, 30.0), Vector3(0.0, 0.085, 0.0), rubber)
	# Repeating institutional wall bays establish the room before the booths are
	# reached and keep the checkpoint legible from its entrance.
	for x in [-35.0, -25.0, -15.0, -5.0, 5.0, 15.0, 25.0, 35.0]:
		_runtime._add_box(root, Vector3(8.8, 3.2, 0.16), Vector3(x, 1.62, -16.55), institutional)
		_runtime._add_box(root, Vector3(0.16, 3.25, 0.24), Vector3(x + 4.35, 1.64, -16.45), dark)
		_runtime._add_box(root, Vector3(2.8, 0.055, 0.26), Vector3(x, 2.64, -16.34), cyan)
	# A single readable security threshold leaves a broad path into the hall.
	for x in [-9.0, 9.0]:
		_runtime._add_box(root, Vector3(0.34, 2.85, 0.34), Vector3(x - 2.35, 1.43, 9.0), institutional)
		_runtime._add_box(root, Vector3(0.34, 2.85, 0.34), Vector3(x + 2.35, 1.43, 9.0), institutional)
		_runtime._add_box(root, Vector3(5.0, 0.28, 0.34), Vector3(x, 2.76, 9.0), dark)
		_runtime._add_box(root, Vector3(1.15, 0.08, 0.38), Vector3(x, 2.74, 8.82), cyan if x < 0.0 else warning)
	_runtime._add_room_sign(root, "DOCUMENT CONTROL", Vector3(0.0, 2.46, 9.15), Color8(171, 184, 169), 0.0064)
	# Low segmented queue rails form a serpentine route without becoming a wall.
	for rail in [
		[Vector3(-20.0, 0.78, 4.8), Vector3(25.0, 0.065, 0.065)],
		[Vector3(17.0, 0.78, 1.2), Vector3(25.0, 0.065, 0.065)],
		[Vector3(-17.0, 0.78, -2.4), Vector3(25.0, 0.065, 0.065)]
	]:
		var rail_position: Vector3 = rail[0]
		var rail_size: Vector3 = rail[1]
		_runtime._add_box(root, rail_size, rail_position, institutional)
		for x_offset in [-rail_size.x * 0.48, 0.0, rail_size.x * 0.48]:
			_runtime._add_box(root, Vector3(0.13, 0.88, 0.13), rail_position + Vector3(x_offset, -0.40, 0), institutional)
			_runtime._add_box(root, Vector3(0.19, 0.09, 0.19), rail_position + Vector3(x_offset, 0.02, 0), amber)
	# Three compact inspection booths, each with a lit window and document tray.
	for booth_index in 3:
		var x = -24.0 + float(booth_index) * 24.0
		_runtime._add_box(root, Vector3(13.0, 1.15, 3.4), Vector3(x, 0.58, -11.8), institutional)
		_runtime._add_box(root, Vector3(13.4, 0.18, 3.65), Vector3(x, 1.22, -11.8), dirty_white)
		_runtime._add_box(root, Vector3(11.8, 1.12, 0.09), Vector3(x, 1.83, -10.15), glass)
		_runtime._add_box(root, Vector3(3.8, 0.10, 0.18), Vector3(x, 2.66, -10.08), cyan if booth_index == 1 else warning)
		_runtime._add_box(root, Vector3(3.1, 0.08, 1.25), Vector3(x, 1.36, -9.76), rubber)
		_runtime._add_box(root, Vector3(0.22, 2.9, 0.22), Vector3(x - 6.25, 1.46, -11.75), dark)
		_runtime._add_box(root, Vector3(0.22, 2.9, 0.22), Vector3(x + 6.25, 1.46, -11.75), dark)
		if booth_index == 1:
			_runtime._add_room_sign(root, "OPEN", Vector3(x, 2.35, -9.98), Color8(151, 194, 178), 0.010)
	# Break the showroom symmetry: one lane is abandoned, one is operating, and
	# one has been dismantled into a baggage-inspection station.
	_runtime._add_box(root, Vector3(10.5, 1.05, 3.0), Vector3(-26.0, 0.54, -5.8), rubber)
	for belt_x in [-30.0, -27.5, -25.0, -22.5]:
		_runtime._add_box(root, Vector3(1.8, 0.10, 2.5), Vector3(belt_x, 1.08, -5.8), institutional)
	_runtime._add_box(root, Vector3(5.2, 2.7, 0.42), Vector3(26.0, 1.36, -7.2), dark)
	_runtime._add_box(root, Vector3(3.4, 1.7, 0.12), Vector3(26.0, 1.55, -6.96), warning)
	_runtime._add_room_sign(root, "LANE CLOSED", Vector3(26.0, 2.12, -6.88), Color8(181, 79, 65), 0.010)
	# Heavy overhead bulkhead and suspended lane indicators create the airport /
	# border-control silhouette that was missing from the old room.
	_runtime._add_box(root, Vector3(76.0, 0.42, 3.2), Vector3(0.0, 3.18, -12.2), institutional)
	for x in [-24.0, 0.0, 24.0]:
		_runtime._add_box(root, Vector3(5.8, 0.12, 0.30), Vector3(x, 2.82, -8.8), cyan if x == 0.0 else warning)
	# The segmented institutional ceiling remains visible and continuous. Only
	# the working lane keeps a focused canopy, avoiding a low black false ceiling.
	# The central lane is the only functioning checkpoint. A broad canopy and
	# backlit control wall give it hierarchy over the dismantled side lanes.
	_runtime._add_box(root, Vector3(15.0, 0.24, 3.8), Vector3(0.0, 2.82, -9.0), institutional)
	_runtime._add_box(root, Vector3(12.0, 0.06, 2.2), Vector3(0.0, 2.51, -8.7), cyan)
	# Build the working lane as a believable transaction point instead of a row
	# of abstract boxes. The split counter keeps the interaction pads reachable.
	_runtime._add_box(root, Vector3(15.0, 0.92, 2.35), Vector3(0.0, 0.48, -8.75), institutional)
	_runtime._add_box(root, Vector3(15.4, 0.16, 2.55), Vector3(0.0, 1.00, -8.75), dirty_white)
	_runtime._add_box(root, Vector3(13.8, 0.055, 0.18), Vector3(0.0, 0.88, -7.53), cyan)
	_runtime._add_box(root, Vector3(14.2, 1.35, 0.08), Vector3(0.0, 1.83, -9.78), glass)
	for divider_x in [-7.0, -2.7, 2.7, 7.0]:
		_runtime._add_box(root, Vector3(0.12, 1.55, 1.92), Vector3(divider_x, 1.78, -9.02), dark)
	for screen_x in [-5.2, 5.2]:
		_runtime._add_box(root, Vector3(2.15, 1.15, 0.18), Vector3(screen_x, 1.78, -8.82), dark)
		_runtime._add_box(root, Vector3(1.72, 0.82, 0.06), Vector3(screen_x, 1.80, -8.70), cyan)
		_runtime._add_box(root, Vector3(0.14, 0.72, 0.14), Vector3(screen_x, 1.22, -8.92), institutional)
	# Three separate document trays visually explain the required order before
	# the player reads it, while the guide still provides the exact solution.
	for tray_index in 3:
		var tray_x = -2.0 + float(tray_index) * 2.0
		_runtime._add_box(root, Vector3(1.45, 0.09, 1.12), Vector3(tray_x, 1.12, -8.15), rubber)
		_runtime._add_box(root, Vector3(1.12, 0.035, 0.82), Vector3(tray_x, 1.18, -8.15), [cyan, amber, dirty_white][tray_index])
	# Desk hardware and a single abandoned chair make the working position read
	# as a human checkpoint rather than another abstract arena barricade.
	_runtime._add_box(root, Vector3(0.55, 0.12, 0.34), Vector3(-0.55, 1.18, -8.03), dark)
	_runtime._add_box(root, Vector3(0.10, 0.42, 0.10), Vector3(-0.55, 1.40, -8.03), institutional)
	_runtime._add_box(root, Vector3(0.38, 0.42, 0.08), Vector3(-0.55, 1.58, -8.00), warning)
	_runtime._add_box(root, Vector3(1.25, 0.16, 1.15), Vector3(0.0, 0.55, -11.25), rubber)
	_runtime._add_box(root, Vector3(1.12, 1.05, 0.14), Vector3(0.0, 1.05, -11.76), institutional)
	_runtime._add_box(root, Vector3(0.16, 0.58, 0.16), Vector3(-0.42, 0.27, -11.25), institutional)
	_runtime._add_box(root, Vector3(0.16, 0.58, 0.16), Vector3(0.42, 0.27, -11.25), institutional)
	# A walk-through baggage scanner gives the dismantled lane a recognisable
	# silhouette and creates visual contrast with the active central booth.
	for scanner_x in [-31.1, -18.9]:
		_runtime._add_box(root, Vector3(0.48, 2.85, 1.15), Vector3(scanner_x, 1.43, -4.9), institutional)
	_runtime._add_box(root, Vector3(12.7, 0.48, 1.15), Vector3(-25.0, 2.72, -4.9), institutional)
	_runtime._add_box(root, Vector3(8.6, 0.08, 0.92), Vector3(-25.0, 2.45, -4.9), warning)
	_runtime._add_box(root, Vector3(3.6, 1.85, 0.24), Vector3(-17.6, 1.10, -4.6), dark)
	_runtime._add_box(root, Vector3(2.8, 1.25, 0.08), Vector3(-17.6, 1.22, -4.44), _runtime._dim_lit_material(Color8(88, 110, 102), 0.82, 1.30))
	_runtime._add_box(root, Vector3(12.5, 2.5, 0.30), Vector3(-25.0, 1.27, -8.0), rubber)
	_runtime._add_box(root, Vector3(8.0, 1.7, 0.12), Vector3(-25.0, 1.55, -7.80), _runtime._dim_lit_material(Color8(53, 66, 64), 0.82, 1.30))
	_runtime._add_box(root, Vector3(16.0, 2.2, 0.34), Vector3(25.0, 1.12, -7.7), dark)
	for closed_x in [20.0, 25.0, 30.0]:
		_runtime._add_box(root, Vector3(0.24, 2.1, 0.24), Vector3(closed_x, 1.05, -6.6), warning)
		_runtime._add_box(root, Vector3(4.2, 0.12, 0.18), Vector3(closed_x, 1.35, -6.5), warning).rotation_degrees.z = -22.0
	for column_pos in [Vector3(-35.0, 1.6, 7.5), Vector3(35.0, 1.6, 7.5), Vector3(-35.0, 1.6, -4.5), Vector3(35.0, 1.6, -4.5)]:
		_runtime._add_box(root, Vector3(1.5, 3.2, 1.5), column_pos, institutional)
		_runtime._add_box(root, Vector3(1.7, 0.10, 1.7), column_pos + Vector3(0, 1.42, 0), amber)
	# Waiting furniture stays at the sides, keeping the entrance and guide visible.
	for bench_pos in [Vector3(-31.0, 0.52, 13.4), Vector3(27.0, 0.52, 13.4)]:
		_runtime._add_box(root, Vector3(10.0, 0.18, 1.45), bench_pos, dirty_white)
		_runtime._add_box(root, Vector3(0.20, 0.52, 1.30), bench_pos + Vector3(-4.0, -0.26, 0), institutional)
		_runtime._add_box(root, Vector3(0.20, 0.52, 1.30), bench_pos + Vector3(4.0, -0.26, 0), institutional)
	# Smaller seats, discarded luggage and a clock establish the checkpoint as
	# a place people once waited in, supporting the lonely-memory theme.
	for seat_x in [-16.0, -12.5, 12.5, 16.0]:
		_runtime._add_box(root, Vector3(2.6, 0.14, 1.25), Vector3(seat_x, 0.58, 13.4), dirty_white)
		_runtime._add_box(root, Vector3(2.6, 0.95, 0.14), Vector3(seat_x, 1.02, 14.0), institutional)
	_runtime._add_box(root, Vector3(1.25, 0.92, 0.72), Vector3(21.0, 0.48, 12.4), rubber)
	_runtime._add_box(root, Vector3(0.16, 1.18, 0.16), Vector3(21.0, 1.46, 12.4), institutional)
	_runtime._add_disc(root, Vector3(0.0, 2.35, -16.32), 0.58, 0.10, dirty_white, Vector3(90, 0, 0))
	_runtime._add_box(root, Vector3(0.04, 0.33, 0.04), Vector3(0.0, 2.35, -16.18), warning).rotation_degrees.z = 22.0
	var guide_kiosk = Node3D.new()
	guide_kiosk.position = Vector3(-20.0, 0.0, 12.0)
	root.add_child(guide_kiosk)
	_runtime._add_box(guide_kiosk, Vector3(4.8, 1.15, 2.0), Vector3(0, 0.58, 0), institutional)
	_runtime._add_box(guide_kiosk, Vector3(3.8, 1.35, 0.18), Vector3(0, 1.65, -0.72), cyan)
	_runtime._add_room_sign(root, "PROCESSING GUIDE", Vector3(-20.0, 2.22, 11.25), Color8(112, 194, 184), 0.010)
	_runtime._add_room_sign(root, "ARRIVALS / PROCESSING", Vector3(0.0, 2.70, 16.32), Color8(173, 183, 166), 0.014)
	# Color-coded floor guidance remains visible at flashlight range and explains
	# the three functional zones without adding more realtime lights.
	_runtime._add_box(root, Vector3(0.18, 0.028, 19.0), Vector3(0.0, 0.10, 3.0), cyan)
	_runtime._add_box(root, Vector3(0.18, 0.028, 14.0), Vector3(-24.0, 0.10, 2.5), amber)
	_runtime._add_box(root, Vector3(0.18, 0.028, 14.0), Vector3(24.0, 0.10, 2.5), warning)
	var clerk = Node3D.new()
	clerk.name = "CheckpointClerk"
	clerk.position = Vector3(0, 1.55, -10.5)
	root.add_child(clerk)
	_runtime._add_box(clerk, Vector3(0.95, 1.45, 0.65), Vector3.ZERO, dark)
	var head = MeshInstance3D.new()
	var head_mesh = SphereMesh.new()
	head_mesh.radius = 0.32
	head_mesh.height = 0.64
	head.mesh = head_mesh
	head.position = Vector3(0, 0.88, 0)
	head.material_override = institutional
	clerk.add_child(head)
	for light_pos in [Vector3(-13, 2.66, -5), Vector3(13, 2.66, 7)]:
		_runtime._add_room_light(root, light_pos, Color8(177, 196, 180), 5.2, 16.5)
	_runtime._add_room_fill_light(root, Vector3(0.0, 2.35, -3.0), Color8(126, 146, 136), 1.20, 33.0)
	_runtime._add_room_floor_pool(root, Vector3(-24.0, 0.082, -6.0), Vector2(17.0, 15.0), Color8(76, 91, 84), 0.25)
	_runtime._add_room_floor_pool(root, Vector3(0.0, 0.082, -6.0), Vector2(17.0, 15.0), Color8(87, 103, 95), 0.28)
	_runtime._add_room_floor_pool(root, Vector3(24.0, 0.082, -6.0), Vector2(17.0, 15.0), Color8(76, 91, 84), 0.25)
	dress_passport_memory(_runtime, root, institutional, dirty_white, dark, rubber, glass, cyan, amber, warning)
	add_passport_hero_dressing(_runtime, root, institutional, dirty_white, dark, rubber, glass, cyan, amber, warning)
	var guide = _runtime._make_task_prop(root, Vector3(-20.0, 2.38, 11.22), "guide", cyan)
	_runtime._add_interactable("guide", "passport_guide", guide, "READ PROCESSING GUIDE", "GUIDE")
	_runtime._add_interactable("passport", "passport_doc", _runtime._make_task_prop(root, Vector3(-29.0, 0.72, 5.2), "paper", cyan), "TAKE PASSPORT", "PASSPORT")
	_runtime._add_interactable("visa", "passport_doc", _runtime._make_task_prop(root, Vector3(30.0, 0.72, 4.0), "paper", warning), "TAKE VISA", "VISA")
	_runtime._add_interactable("declaration", "passport_doc", _runtime._make_task_prop(root, Vector3(18.0, 0.72, 14.8), "paper", dirty_white), "TAKE DECLARATION", "DECLARATION")
	for index in 3:
		var document_id = ["passport", "visa", "declaration"][index]
		var pad = _runtime._make_task_prop(root, Vector3(-2.0 + index * 2.0, 1.48, -9.65), "paper", [cyan, warning, dirty_white][index])
		pad.visible = false
		_runtime._add_interactable(document_id, "passport_submit", pad, "SUBMIT %s" % document_id.to_upper(), document_id.to_upper(), true, false)
	_runtime._batch_static_room_boxes(root)

func add_passport_hero_dressing(_runtime, root: Node3D, institutional: Material, dirty_white: Material, dark: Material, rubber: Material, glass: Material, cyan: Material, amber: Material, warning: Material) -> void:
	# Central processing portal: the eye catches this before any individual prop.
	var portal = Node3D.new()
	portal.name = "PassportHero_ProcessingPortal"
	portal.position = Vector3(0.0, 0.0, -8.9)
	root.add_child(portal)
	for x in [-7.1, 7.1]:
		_runtime._add_box(portal, Vector3(0.42, 2.90, 0.42), Vector3(x, 1.46, 0), institutional)
		_runtime._add_box(portal, Vector3(0.10, 2.20, 0.46), Vector3(x, 1.52, 0), cyan)
	_runtime._add_box(portal, Vector3(14.7, 0.45, 0.60), Vector3(0, 2.82, 0), dark)
	_runtime._add_box(portal, Vector3(9.0, 0.065, 0.64), Vector3(0, 2.57, 0), cyan)
	_runtime._add_room_sign(portal, "PROCESSING", Vector3(0, 2.25, 0.36), Color8(153, 207, 199), 0.010)
	_runtime._add_hero_spot(root, Vector3(0.0, 3.0, -3.2), Vector3(0.0, 1.0, -9.0), Color8(150, 210, 198), 7.2, 13.0, 46.0)
	_runtime._add_practical_omni(root, Vector3(0.0, 1.75, -8.0), Color8(111, 185, 177), 2.4, 6.5)
	_runtime._add_practical_omni(root, Vector3(-20.0, 1.6, 10.2), Color8(231, 171, 84), 1.8, 5.2)
	_runtime._add_practical_omni(root, Vector3(26.0, 1.7, -6.5), Color8(190, 47, 39), 1.25, 4.8)

	# A suspended clock and paired turnstiles establish airport scale and ritual.
	_runtime._add_disc(root, Vector3(10.5, 2.34, 7.4), 0.42, 0.12, dirty_white, Vector3(90, 0, 0))
	_runtime._add_pipe(root, Vector3(10.5, 2.67, 7.4), Vector3.ZERO, 0.05, 0.68, institutional)
	_runtime._add_box(root, Vector3(0.045, 0.28, 0.045), Vector3(10.5, 2.34, 7.16), dark).rotation_degrees.x = -24.0
	_runtime._add_box(root, Vector3(0.045, 0.20, 0.045), Vector3(10.5, 2.34, 7.62), warning).rotation_degrees.x = 38.0
	for gate_x in [-5.0, 5.0]:
		_runtime._add_box(root, Vector3(1.25, 0.95, 2.2), Vector3(gate_x, 0.49, 6.0), rubber)
		_runtime._add_box(root, Vector3(0.18, 0.75, 2.05), Vector3(gate_x, 1.10, 6.0), glass)
		_runtime._add_box(root, Vector3(0.62, 0.08, 0.42), Vector3(gate_x, 1.02, 4.85), amber)
		for arm_angle in [-35.0, 35.0]:
			var arm = _runtime._add_box(root, Vector3(1.8, 0.08, 0.08), Vector3(gate_x, 1.18, 6.0), institutional)
			arm.rotation_degrees.y = arm_angle

	# Irregular luggage/document clusters stop the room reading as a mirrored kit.
	for item_data in [
		[Vector3(-13.0, 0.38, 10.5), Vector3(1.4, 0.72, 0.85)],
		[Vector3(-11.6, 0.28, 11.4), Vector3(0.9, 0.52, 0.72)],
		[Vector3(13.5, 0.44, 9.8), Vector3(1.2, 0.82, 0.76)],
		[Vector3(15.0, 0.30, 11.0), Vector3(1.0, 0.56, 0.70)]
	]:
		_runtime._add_box(root, item_data[1], item_data[0], rubber)
		_runtime._add_box(root, Vector3(0.12, 0.34, 0.12), item_data[0] + Vector3(0, float(item_data[1].y) * 0.65, 0), institutional)
	# Pale wall washes and one worn information island replace the earlier sea of
	# floating labels. The objects now carry the checkpoint story themselves.
	_runtime._add_box(root, Vector3(20.0, 2.15, 0.035), Vector3(0.0, 1.45, -16.25), _runtime._dim_lit_material(Color8(72, 91, 84), 0.88, 0.32))
	_runtime._add_box(root, Vector3(19.0, 0.035, 12.0), Vector3(0.0, 0.118, -7.0), _runtime._dim_lit_material(Color8(72, 85, 78), 0.92, 0.29))
	var information = Node3D.new()
	information.name = "PassportInformationIsland"
	information.position = Vector3(14.0, 0.0, 11.8)
	root.add_child(information)
	_runtime._add_box(information, Vector3(5.6, 1.00, 2.2), Vector3(0, 0.52, 0), institutional)
	_runtime._add_box(information, Vector3(5.9, 0.14, 2.4), Vector3(0, 1.08, 0), dirty_white)
	_runtime._add_box(information, Vector3(4.2, 1.20, 0.12), Vector3(0, 1.78, -0.72), dark)
	_runtime._add_box(information, Vector3(3.6, 0.82, 0.055), Vector3(0, 1.78, -0.64), cyan)
	_runtime._add_room_sign(information, "INFORMATION", Vector3(0, 2.48, -0.74), Color8(154, 191, 180), 0.009)

func dress_passport_memory(_runtime, root: Node3D, institutional: Material, dirty_white: Material, dark: Material, rubber: Material, glass: Material, cyan: Material, amber: Material, warning: Material) -> void:
	# The institutional ceiling is built once by _build_passport_scenario().
	# Large arrivals board and its dead modules establish the room at a glance.
	var board = Node3D.new()
	board.name = "Passport_ArrivalsBoard"
	board.position = Vector3(0.0, 2.46, 15.85)
	root.add_child(board)
	_runtime._add_box(board, Vector3(25.0, 1.55, 0.16), Vector3.ZERO, dark)
	for row_index in 3:
		for column_index in 6:
			var alive = (row_index + column_index) % 4 != 0
			var module_material = cyan if alive else rubber
			_runtime._add_box(board, Vector3(3.45, 0.22, 0.035), Vector3(-9.2 + column_index * 3.68, 0.45 - row_index * 0.43, -0.10), module_material)
	# Passport stamps, paper stacks and desk lamps make the working booth tactile.
	for desk_x in [-5.2, 0.0, 5.2]:
		for stack_index in 3:
			_runtime._add_box(root, Vector3(0.72, 0.035, 0.54), Vector3(desk_x + 1.1, 1.12 + stack_index * 0.045, -8.35), dirty_white)
		_runtime._add_disc(root, Vector3(desk_x - 1.05, 1.20, -8.26), 0.16, 0.18, warning, Vector3(90, 0, 0))
		_runtime._add_pipe(root, Vector3(desk_x - 1.05, 1.58, -8.55), Vector3.ZERO, 0.055, 0.70, institutional)
		_runtime._add_box(root, Vector3(0.62, 0.08, 0.48), Vector3(desk_x - 1.05, 1.88, -8.38), amber)
	# Luggage and document archive storage populate the side lanes while keeping
	# all mission items visible and reachable.
	for archive_x in [-37.0, 37.0]:
		for shelf_y in [0.55, 1.35, 2.15]:
			_runtime._add_box(root, Vector3(5.8, 0.10, 1.25), Vector3(archive_x, shelf_y, -1.0), institutional)
			for file_index in 4:
				var file_x = archive_x - 2.0 + file_index * 1.25
				_runtime._add_box(root, Vector3(0.72, 0.56, 0.92), Vector3(file_x, shelf_y + 0.34, -1.0), warning if file_index == 0 else rubber)
	for luggage in [Vector3(-31.0, 0.46, 10.8), Vector3(-28.8, 0.35, 11.6), Vector3(26.0, 0.52, 11.0), Vector3(29.0, 0.38, 12.0)]:
		_runtime._add_box(root, Vector3(1.25, 0.82, 0.72), luggage, rubber)
		_runtime._add_box(root, Vector3(0.12, 0.42, 0.12), luggage + Vector3(0, 0.60, 0), institutional)
	# The guide and the three document locations get restrained floor notation;
	# the color language matches the submission trays rather than floating UI.
	_runtime._add_emissive_task_marker(root, Vector3(-20.0, 0.105, 10.4), cyan, 3.0)
	_runtime._add_emissive_task_marker(root, Vector3(-29.0, 0.105, 5.2), cyan, 2.6)
	_runtime._add_emissive_task_marker(root, Vector3(30.0, 0.105, 4.0), warning, 2.6)
	_runtime._add_emissive_task_marker(root, Vector3(18.0, 0.105, 14.8), dirty_white, 2.6)
	# Thin glass side screens catch the flashlight and give the central checkpoint
	# depth without blocking its interaction pads.
	for screen_x in [-8.2, 8.2]:
		_runtime._add_box(root, Vector3(0.08, 1.82, 3.4), Vector3(screen_x, 1.72, -8.9), glass)
		_runtime._add_box(root, Vector3(0.16, 2.0, 0.16), Vector3(screen_x, 1.70, -10.55), institutional)
		_runtime._add_box(root, Vector3(0.16, 2.0, 0.16), Vector3(screen_x, 1.70, -7.25), institutional)
	_runtime._add_room_sign(root, "NO RETURN / NO RECORD", Vector3(25.0, 2.15, -16.30), Color8(156, 64, 54), 0.009)

