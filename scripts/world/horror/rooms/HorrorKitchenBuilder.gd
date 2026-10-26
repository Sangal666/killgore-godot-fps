extends RefCounted
## Authored kitchen composition. Runtime owns nodes and gameplay state.

func build_kitchen_scenario(_runtime, anchor: Vector3) -> void:
	_runtime.task_states["kitchen"] = {"complete": false, "found": {}, "cooking": false}
	var root = Node3D.new()
	root.name = "MemoryRoom_Kitchen"
	root.position = anchor
	root.set_meta("skip_static_room_batch", true)
	_runtime.add_child(root)
	_runtime._register_memory_room_visual(root, Vector2(6.3, 32.4))
	var enamel = _runtime._dim_lit_material(Color8(117, 108, 89), 0.84, 0.62)
	var tile = _runtime._room_surface(Color8(58, 58, 52), 0.94)
	var cabinet = _runtime._dim_lit_material(Color8(43, 36, 29), 0.94, 0.38)
	var room_wall = _runtime._room_surface(Color8(45, 43, 37), 0.97)
	var wood = _runtime._dim_lit_material(Color8(77, 48, 29), 0.82, 0.54)
	var steel = _runtime._dim_lit_material(Color8(79, 76, 66), 0.52, 0.46)
	var grease = _runtime._dim_lit_material(Color8(20, 18, 15), 0.97, 0.14)
	var warm = _runtime._glow_material(Color8(218, 169, 86), 1.42)
	# Slightly larger than the first pass: furniture remains domestic scale while
	# circulation around the table gains enough room to stop feeling cramped.
	const ROOM_WIDTH = 5.90
	const ROOM_DEPTH = 4.60
	const ROOM_HEIGHT = 2.75
	const BASE_CELL_HALF = 6.0
	const BASE_CEILING = 3.65
	# The new base map reserves this complete volume as open space. The kitchen
	# shell below is therefore the only architecture here, rather than a room
	# layered over an older maze room.
	for ceiling_x in [-1.98, 0.0, 1.98]:
		for ceiling_z in [-1.15, 1.15]:
			_runtime._add_box(root, Vector3(1.90, 0.09, 2.20), Vector3(ceiling_x, ROOM_HEIGHT, ceiling_z), tile)
	_runtime._add_structure_box(root, Vector3(ROOM_WIDTH, ROOM_HEIGHT, 0.16), Vector3(0, ROOM_HEIGHT * 0.5, -2.30), room_wall)
	_runtime._add_structure_box(root, Vector3(0.16, ROOM_HEIGHT, ROOM_DEPTH), Vector3(-2.95, ROOM_HEIGHT * 0.5, 0), room_wall)
	# Right wall keeps the framed picture visible while retaining the service exit
	# at the back corner for the continuing level route.
	_runtime._add_structure_box(root, Vector3(0.16, ROOM_HEIGHT, 0.72), Vector3(2.95, ROOM_HEIGHT * 0.5, -1.94), room_wall)
	_runtime._add_structure_box(root, Vector3(0.16, ROOM_HEIGHT, 2.32), Vector3(2.95, ROOM_HEIGHT * 0.5, 1.14), room_wall)
	_runtime._add_box(root, Vector3(0.18, 0.20, 1.56), Vector3(2.95, 2.65, -0.80), cabinet)
	# South wall and door frame create the exact corridor-to-room reveal.
	_runtime._add_structure_box(root, Vector3(1.95, ROOM_HEIGHT, 0.16), Vector3(-1.975, ROOM_HEIGHT * 0.5, 2.30), room_wall)
	_runtime._add_structure_box(root, Vector3(1.95, ROOM_HEIGHT, 0.16), Vector3(1.975, ROOM_HEIGHT * 0.5, 2.30), room_wall)
	_runtime._add_box(root, Vector3(2.00, 0.20, 0.20), Vector3(0, 2.65, 2.30), cabinet)
	for x in [-1.00, 1.00]:
		_runtime._add_box(root, Vector3(0.14, 2.61, 0.22), Vector3(x, 1.305, 2.24), steel)
	# The reserved grid envelope is twelve metres wide. These solid shoulders form
	# the compact room inside that envelope and meet its native outer walls cleanly.
	_runtime._add_structure_box(root, Vector3(3.05, BASE_CEILING, ROOM_DEPTH), Vector3(-4.475, BASE_CEILING * 0.5, 0), room_wall)
	_runtime._add_structure_box(root, Vector3(3.05, BASE_CEILING, 0.72), Vector3(4.475, BASE_CEILING * 0.5, -1.94), room_wall)
	_runtime._add_structure_box(root, Vector3(3.05, BASE_CEILING, 2.28), Vector3(4.475, BASE_CEILING * 0.5, 1.16), room_wall)
	_runtime._add_structure_box(root, Vector3(BASE_CELL_HALF * 2.0, BASE_CEILING, 3.70), Vector3(0, BASE_CEILING * 0.5, -4.15), room_wall)
	# Dark final approach. The surrounding base grid is intentionally open across
	# three cells; these are its real walls and ordinary registered collision.
	const APPROACH_START_Z = 2.30
	const APPROACH_END_Z = 27.90
	const APPROACH_LENGTH = APPROACH_END_Z - APPROACH_START_Z
	const APPROACH_CENTER_Z = (APPROACH_START_Z + APPROACH_END_Z) * 0.5
	# A real left-hand maintenance bypass preserves the kitchen doorway and the
	# original direct passage. Both openings exceed the hunter's body clearance.
	for segment in [[2.30,10.4], [24.8,27.90]]:
		_runtime._add_structure_box(root, Vector3(4.92, BASE_CEILING, segment[1]-segment[0]), Vector3(-3.54, BASE_CEILING*0.5, (segment[0]+segment[1])*0.5), room_wall)
	_runtime._add_structure_box(root, Vector3(0.16, BASE_CEILING, 14.4), Vector3(-5.92, BASE_CEILING*0.5,17.6),room_wall)
	_runtime._add_structure_box(root, Vector3(1.20, BASE_CEILING,7.0), Vector3(-1.70,BASE_CEILING*0.5,17.6),room_wall)
	_runtime._add_box(root, Vector3(4.76,0.09,14.4),Vector3(-3.46,ROOM_HEIGHT,17.6),tile)
	_runtime._add_structure_box(root, Vector3(4.92, BASE_CEILING, APPROACH_LENGTH), Vector3(3.54, BASE_CEILING * 0.5, APPROACH_CENTER_Z), room_wall)
	_runtime._add_box(root, Vector3(2.15, 0.09, APPROACH_LENGTH), Vector3(0, ROOM_HEIGHT, APPROACH_CENTER_Z), tile)
	# The broad service hall now enters a real orthogonal vestibule before the
	# retained 2.15 m kitchen throat. Four staggered structural shoulders replace
	# the former pair of monolithic blocks, opening a 4.2 m first bay and a 4.0 m
	# turning bay before the final compression. Every visible floor-level mass is
	# registered through ordinary collision.
	_runtime._add_box(root, Vector3(2.15, 0.90, 0.18), Vector3(0, 3.20, 27.88), room_wall)
	_runtime._add_structure_box(root, Vector3(2.80, BASE_CEILING, 5.60), Vector3(-4.60, BASE_CEILING * 0.5, 30.70), room_wall)
	_runtime._add_structure_box(root, Vector3(2.12, BASE_CEILING, 3.10), Vector3(-2.14, BASE_CEILING * 0.5, 29.45), room_wall)
	_runtime._add_structure_box(root, Vector3(2.80, BASE_CEILING, 2.75), Vector3(4.60, BASE_CEILING * 0.5, 29.225), room_wall)
	_runtime._add_structure_box(root, Vector3(2.12, BASE_CEILING, 1.15), Vector3(2.14, BASE_CEILING * 0.5, 28.425), room_wall)
	build_kitchen_service_transition(_runtime, root, room_wall, cabinet, steel, grease, tile)
	# Left recessed door and right picture panel reproduce the interior landmarks.
	_runtime._add_box(root, Vector3(0.035, 2.10, 1.12), Vector3(-2.855, 1.05, 0.30), grease)
	for frame_z in [-0.36, 0.96]:
		_runtime._add_box(root, Vector3(0.055, 2.28, 0.07), Vector3(-2.825, 1.14, frame_z), steel)
	_runtime._add_box(root, Vector3(0.055, 0.07, 1.39), Vector3(-2.825, 2.245, 0.30), steel)
	_runtime._add_box(root, Vector3(0.035, 1.02, 1.20), Vector3(2.855, 1.48, 0.88), grease)
	for frame_z in [0.22, 1.54]:
		_runtime._add_box(root, Vector3(0.045, 1.12, 0.06), Vector3(2.825, 1.48, frame_z), steel)
	for frame_y in [0.92, 2.04]:
		_runtime._add_box(root, Vector3(0.045, 0.06, 1.32), Vector3(2.825, frame_y, 0.88), steel)
	# Fine floor joints replace the oversized grid seen in the previous version.
	for x in [-1.80, -0.90, 0.0, 0.90, 1.80]:
		_runtime._add_box(root, Vector3(0.016, 0.012, 4.40), Vector3(x, -0.012, 0), grease)
	for z in [-1.40, -0.70, 0.0, 0.70, 1.40]:
		_runtime._add_box(root, Vector3(5.65, 0.012, 0.016), Vector3(0, -0.012, z), grease)
	build_compact_kitchen_table(_runtime, root, Vector3(0.0, 0.0, 0.55), wood, enamel, steel, grease, warm)
	build_compact_kitchen_line(_runtime, root, enamel, cabinet, steel, grease, warm)
	build_kitchen_pendant(_runtime, root, cabinet, steel, warm)
	# The corridor stays black; these pools terminate inside the room so the warm
	# tableau remains legible through the doorway even with the flashlight off.
	_runtime._add_hero_spot(root, Vector3(0.0, 1.92, 0.42), Vector3(0.0, 0.78, 0.55), Color8(224, 172, 91), 6.40, 4.15, 51.0)
	_runtime._add_practical_omni(root, Vector3(0.0, 1.88, 0.42), Color8(214, 153, 70), 1.20, 2.75)
	_runtime._add_hero_spot(root, Vector3(0.0, 2.05, -1.66), Vector3(0.0, 0.86, -1.92), Color8(207, 153, 82), 3.80, 3.20, 58.0)
	_runtime._add_room_fill_light(root, Vector3(0.0, 1.42, -0.35), Color8(118, 82, 48), 0.42, 4.25)
	var stove = Node3D.new()
	stove.name = "Stove_Interact"
	stove.position = Vector3(0.58, 0.0, -1.90)
	root.add_child(stove)
	_runtime._add_box(stove, Vector3(0.78, 0.88, 0.68), Vector3(0, 0.44, 0), enamel)
	_runtime._add_box(stove, Vector3(0.82, 0.055, 0.72), Vector3(0, 0.91, 0), steel)
	for burner_position in [Vector3(-0.20, 0.95, -0.18), Vector3(0.20, 0.95, -0.18), Vector3(-0.20, 0.95, 0.18), Vector3(0.20, 0.95, 0.18)]:
		_runtime._add_disc(stove, burner_position, 0.10, 0.025, grease)
	_runtime._add_box(stove, Vector3(0.58, 0.36, 0.035), Vector3(0, 0.48, 0.36), grease)
	_runtime._add_interactable("stove", "kitchen_stove", stove, "COOK THE MEAL", "STOVE", false)
	var pan_prop = _runtime._make_task_prop(root, Vector3(0.58, 1.02, -1.88), "pan", steel)
	pan_prop.scale = Vector3.ONE * 0.48
	var knife_prop = _runtime._make_task_prop(root, Vector3(-0.62, 0.92, 0.52), "knife", steel)
	knife_prop.scale = Vector3.ONE * 0.52
	var ingredient_prop = _runtime._make_task_prop(root, Vector3(-0.25, 1.06, -1.86), "box", warm)
	ingredient_prop.scale = Vector3.ONE * 0.58
	_runtime._add_interactable("pan", "kitchen_item", pan_prop, "TAKE PAN", "PAN")
	_runtime._add_interactable("knife", "kitchen_item", knife_prop, "TAKE KNIFE", "KNIFE")
	_runtime._add_interactable("ingredients", "kitchen_item", ingredient_prop, "TAKE INGREDIENTS", "INGREDIENTS")
	_runtime._batch_static_room_boxes(root)

func build_kitchen_service_transition(_runtime, root: Node3D, wall: Material, dark_metal: Material, steel: Material, recess: Material, ceiling_tile: Material) -> void:
	# The route arrives from +X, turns left, then commits to the narrow -Z run.
	# Everything in this pass is cladding or overhead architecture: the ordinary
	# structural boxes above remain the single source of collision and navigation.
	var transition = Node3D.new()
	transition.name = "KitchenServiceTransition"
	root.add_child(transition)
	var service_amber = _runtime._dim_lit_material(Color8(88, 70, 40), 0.92, 0.24)

	# Three separate ceiling rafts follow only open floor and lower at each portal.
	# Deliberate gaps contain the bulkhead headers, so no ceiling face intersects a
	# wall or appears to float through another slab.
	_runtime._add_box(transition, Vector3(5.55, 0.14, 9.70), Vector3(8.925, 3.47, 32.0), ceiling_tile)
	_runtime._add_box(transition, Vector3(4.30, 0.14, 4.15), Vector3(3.65, 3.13, 33.025), ceiling_tile)
	_runtime._add_box(transition, Vector3(2.14, 0.12, 2.50), Vector3(0.0, 2.77, 29.30), ceiling_tile)

	# First portal: the broad hall compresses to a clearly supported 4.2 m service
	# bay. The jambs stop exactly at the header underside; separate caps previously
	# penetrated both pieces and made the joint flicker from oblique views.
	for portal_z in [30.78, 35.22]:
		_runtime._add_structure_box(transition, Vector3(0.38, 2.76, 0.38), Vector3(5.82, 1.38, portal_z), wall)
	_runtime._add_box(transition, Vector3(0.38, 0.30, 4.82), Vector3(5.82, 2.91, 33.0), dark_metal)

	# Second portal turns the widened bay toward the narrow approach. Its left end
	# meets the west shoulder face while the right jamb stops at its underside.
	_runtime._add_structure_box(transition, Vector3(0.36, 2.55, 0.36), Vector3(3.02, 1.275, 30.82), wall)
	_runtime._add_box(transition, Vector3(4.28, 0.28, 0.34), Vector3(1.06, 2.69, 30.82), dark_metal)
	_runtime._add_box(transition, Vector3(3.92, 0.055, 0.12), Vector3(0.97, 2.52, 30.69), service_amber)

	# Shallow wall piers echo the ceiling bays without stealing any of the broad
	# circulation lane. Their decreasing separation leads the eye around the bend.
	for pier_data in [
		[9.35, 26.16, 0.42, 2.62], [9.35, 37.84, 0.42, 2.62],
		[6.25, 26.16, 0.46, 2.78], [6.25, 37.84, 0.46, 2.78],
		[3.35, 26.16, 0.50, 2.94], [3.35, 37.84, 0.50, 2.94]
	]:
		var pier_x = float(pier_data[0])
		var pier_z = float(pier_data[1])
		var pier_width = float(pier_data[2])
		var pier_height = float(pier_data[3])
		_runtime._add_box(transition, Vector3(pier_width, pier_height, 0.30), Vector3(pier_x, pier_height * 0.5, pier_z), dark_metal)
		_runtime._add_box(transition, Vector3(pier_width + 0.14, 0.10, 0.38), Vector3(pier_x, pier_height - 0.18, pier_z), steel)
	# Slightly raised wall fields make the pilasters read as attached articulation,
	# not columns dropped into the floor. They remain flush with the native walls.
	for side_z in [26.17, 37.83]:
		for panel_data in [[9.35, 2.38], [6.25, 2.24], [3.35, 2.08]]:
			_runtime._add_box(transition, Vector3(float(panel_data[1]), 1.62, 0.035), Vector3(float(panel_data[0]), 1.42, float(side_z)), recess)
			_runtime._add_box(transition, Vector3(float(panel_data[1]) + 0.12, 0.07, 0.045), Vector3(float(panel_data[0]), 0.57, float(side_z)), dark_metal)

	# The structural shoulder facing the incoming hall becomes a deliberate service
	# divider rather than an unarticulated rectangular end cap. The illuminated
	# corner stile marks the side on which the route continues.
	_runtime._add_box(transition, Vector3(0.035, 1.92, 1.76), Vector3(6.015, 1.38, 28.95), recess)
	for edge_z in [28.03, 29.87]:
		_runtime._add_box(transition, Vector3(0.050, 2.08, 0.08), Vector3(6.035, 1.38, edge_z), dark_metal)
	for edge_y in [0.40, 2.36]:
		_runtime._add_box(transition, Vector3(0.050, 0.08, 1.92), Vector3(6.035, edge_y, 28.95), dark_metal)
	_runtime._add_box(transition, Vector3(0.24, 2.82, 0.24), Vector3(6.02, 1.41, 30.08), dark_metal)
	_runtime._add_box(transition, Vector3(0.065, 1.42, 0.10), Vector3(6.16, 1.55, 30.10), service_amber)
	# Two battered horizontal rails continue the broad-hall wall rhythm across the
	# divider face and terminate cleanly at the lit corner.
	_runtime._add_box(transition, Vector3(0.055, 0.09, 1.52), Vector3(6.055, 0.72, 28.95), steel)
	_runtime._add_box(transition, Vector3(0.055, 0.09, 1.52), Vector3(6.055, 2.04, 28.95), steel)

	# Recessed panels and paired pilasters turn the long approach into a believable
	# back-of-house service passage. All faces sit on or behind the existing wall
	# plane, preserving the full 2.15 m collision opening.
	for side in [-1.0, 1.0]:
		var side_value = float(side)
		var wall_x: float = side_value * 1.086
		for bay_z in [25.65, 20.05, 14.45, 8.85]:
			var panel_x: float = -5.826 if side_value < 0 and bay_z in [20.05,14.45] else wall_x
			_runtime._add_box(transition, Vector3(0.035, 1.66, 3.60), Vector3(panel_x, 1.39, bay_z), recess)
			_runtime._add_box(transition, Vector3(0.055, 0.08, 3.72), Vector3(panel_x - side_value * 0.018, 0.54, bay_z), dark_metal)
			_runtime._add_box(transition, Vector3(0.055, 0.08, 3.72), Vector3(panel_x - side_value * 0.018, 2.25, bay_z), dark_metal)
		for rib_z in [22.90, 17.30, 11.70, 6.10]:
			var rib_x: float = -5.79 if side_value < 0 and rib_z in [22.90,17.30,11.70] else side_value * 1.075
			_runtime._add_box(transition, Vector3(0.18, 2.58, 0.30), Vector3(rib_x, 1.29, rib_z), dark_metal)
			_runtime._add_box(transition, Vector3(0.10, 0.11, 0.42), Vector3(rib_x - side_value * 0.085, 2.48, rib_z), steel)

	# Portal headers step down only twice after the threshold. Long dark gaps remain
	# between them, retaining the corridor's black rhythm and the warm kitchen reveal.
	for header_data in [[22.90, 2.66], [17.30, 2.62], [11.70, 2.62], [6.10, 2.62]]:
		var header_z = float(header_data[0])
		var header_y = float(header_data[1])
		_runtime._add_box(transition, Vector3(2.18, 0.20, 0.32), Vector3(0.0, header_y, header_z), dark_metal)
		_runtime._add_box(transition, Vector3(1.72, 0.045, 0.11), Vector3(0.0, header_y - 0.12, header_z - 0.05), steel)

	# Only two weak practicals punctuate the run. The first explains the threshold;
	# the second is deliberately sickly and dim, leaving the kitchen yellow as the
	# sole strong destination light.
	_runtime._add_practical_omni(transition, Vector3(6.15, 3.08, 32.0), Color8(126, 124, 105), 0.46, 4.20)
	_runtime._add_practical_omni(transition, Vector3(0.0, 2.51, 14.36), Color8(116, 124, 105), 0.40, 3.10)

func build_compact_kitchen_table(_runtime, root: Node3D, position: Vector3, wood: Material, enamel: Material, steel: Material, grease: Material, warm: Material) -> void:
	var table = Node3D.new()
	table.name = "DomesticMemory_DiningTable"
	table.position = position
	table.rotation_degrees.y = -3.0
	root.add_child(table)
	# Real dining-table proportions: 2.45 x 0.95 m, 0.80 m high.
	_runtime._add_box(table, Vector3(2.45, 0.10, 0.95), Vector3(0, 0.78, 0), wood)
	_runtime._add_box(table, Vector3(2.32, 0.025, 0.84), Vector3(0, 0.845, 0), enamel)
	for plank_z in [-0.28, 0.0, 0.28]:
		_runtime._add_box(table, Vector3(2.24, 0.010, 0.016), Vector3(0, 0.865, plank_z), grease)
	for leg in [Vector3(-1.02, 0.38, -0.34), Vector3(1.02, 0.38, -0.34), Vector3(-1.02, 0.38, 0.34), Vector3(1.02, 0.38, 0.34)]:
		_runtime._add_box(table, Vector3(0.075, 0.76, 0.075), leg, steel)
	_runtime._add_box(table, Vector3(2.10, 0.08, 0.07), Vector3(0, 0.63, -0.40), wood)
	_runtime._add_box(table, Vector3(2.10, 0.08, 0.07), Vector3(0, 0.63, 0.40), wood)
	for plate_x in [-0.62, 0.62]:
		_runtime._add_disc(table, Vector3(plate_x, 0.875, 0.02), 0.18, 0.022, enamel)
		_runtime._add_disc(table, Vector3(plate_x, 0.890, 0.02), 0.11, 0.012, warm)
		_runtime._add_disc(table, Vector3(plate_x + 0.27, 0.955, -0.25), 0.045, 0.15, steel)
	_runtime._add_disc(table, Vector3(0.0, 0.96, -0.04), 0.10, 0.20, _runtime._room_surface(Color8(96, 58, 39), 0.70))
	_runtime._add_disc(table, Vector3(0.0, 1.07, -0.04), 0.075, 0.018, grease)
	var runner = _runtime._add_box(table, Vector3(0.28, 0.014, 0.72), Vector3(0, 0.870, 0), _runtime._room_surface(Color8(90, 49, 34), 0.94))
	runner.rotation_degrees.y = 1.0
	for chair_data in [[Vector3(-1.70, 0, 0.0), -90.0], [Vector3(1.70, 0, 0.0), 90.0]]:
		var chair = Node3D.new()
		chair.position = chair_data[0]
		chair.rotation_degrees.y = float(chair_data[1])
		table.add_child(chair)
		_runtime._add_box(chair, Vector3(0.48, 0.07, 0.48), Vector3(0, 0.45, 0), wood)
		_runtime._add_box(chair, Vector3(0.48, 0.52, 0.055), Vector3(0, 0.76, 0.22), steel)
		for chair_leg in [Vector3(-0.19, 0.21, -0.18), Vector3(0.19, 0.21, -0.18), Vector3(-0.19, 0.21, 0.18), Vector3(0.19, 0.21, 0.18)]:
			_runtime._add_box(chair, Vector3(0.045, 0.42, 0.045), chair_leg, steel)
	add_seated_kitchen_woman(_runtime, table)

func add_seated_kitchen_woman(_runtime, table: Node3D) -> void:
	var packed = load(_runtime.SEATED_WOMAN_MODEL_PATH) as PackedScene
	if packed == null:
		push_warning("Seated kitchen woman could not be loaded: %s" % _runtime.SEATED_WOMAN_MODEL_PATH)
		return
	var imported = packed.instantiate()
	if not imported is Node3D:
		imported.queue_free()
		push_warning("Seated kitchen woman root is not Node3D")
		return
	var holder = Node3D.new()
	holder.name = "SeatedWoman_MemoryFigure"
	# Match the reference: she sits sideways on the left chair with her back
	# toward the kitchen corridor, looking inward across the table.
	holder.position = Vector3(-1.70, 0.0, 0.0)
	holder.rotation_degrees.y = 0.0
	table.add_child(holder)
	_runtime.kitchen_woman_figure = holder
	holder.add_child(imported)
	_runtime._prepare_memory_figure(imported)
	_runtime._normalize_room_asset(imported, 1.35)

func build_kitchen_pendant(_runtime, root: Node3D, housing: Material, steel: Material, warm: Material) -> void:
	# The reference fixture hangs low and visually locks the table to the room.
	_runtime._add_box(root, Vector3(2.05, 0.09, 0.14), Vector3(0.0, 2.60, 0.42), housing)
	for suspension_x in [-0.72, 0.72]:
		_runtime._add_pipe(root, Vector3(suspension_x, 2.29, 0.42), Vector3.ZERO, 0.025, 0.62, steel)
	_runtime._add_box(root, Vector3(1.92, 0.15, 0.48), Vector3(0.0, 1.98, 0.42), housing)
	_runtime._add_box(root, Vector3(1.68, 0.028, 0.30), Vector3(0.0, 1.89, 0.42), warm)
	# Thin bevel strips stop the shade reading as a single floating cuboid.
	_runtime._add_box(root, Vector3(1.78, 0.035, 0.035), Vector3(0.0, 1.91, 0.65), steel)
	_runtime._add_box(root, Vector3(1.78, 0.035, 0.035), Vector3(0.0, 1.91, 0.19), steel)

func build_compact_kitchen_line(_runtime, root: Node3D, enamel: Material, cabinet: Material, steel: Material, grease: Material, warm: Material) -> void:
	var line = Node3D.new()
	line.name = "CompactKitchen_WorkLine"
	line.position = Vector3(0.0, 0.0, -1.96)
	root.add_child(line)
	# A 3.6 m run plus one domestic fridge fills the five-metre back wall.
	for unit_x in [-1.65, -0.85, -0.05]:
		_runtime._add_box(line, Vector3(0.72, 0.84, 0.62), Vector3(unit_x, 0.42, 0), cabinet)
		_runtime._add_box(line, Vector3(0.61, 0.66, 0.025), Vector3(unit_x, 0.46, 0.325), enamel)
		_runtime._add_box(line, Vector3(0.22, 0.025, 0.035), Vector3(unit_x, 0.48, 0.345), steel)
	_runtime._add_box(line, Vector3(3.62, 0.07, 0.72), Vector3(-0.48, 0.89, 0), steel)
	_runtime._add_box(line, Vector3(3.72, 0.54, 0.035), Vector3(-0.48, 1.20, -0.33), _runtime._room_surface(Color8(67, 61, 51), 0.90))
	# Sink and correctly scaled faucet.
	_runtime._add_box(line, Vector3(0.72, 0.045, 0.45), Vector3(-1.42, 0.94, 0.02), grease)
	_runtime._add_box(line, Vector3(0.56, 0.025, 0.34), Vector3(-1.42, 0.97, 0.02), _runtime._room_surface(Color8(50, 57, 54), 0.38, 0.38))
	_runtime._add_pipe(line, Vector3(-1.42, 1.24, -0.08), Vector3.ZERO, 0.025, 0.45, steel)
	_runtime._add_pipe(line, Vector3(-1.42, 1.40, 0.05), Vector3(90, 0, 0), 0.025, 0.26, steel)
	# Shallow upper cabinets and an open shelf break up the silhouette.
	for upper_x in [-1.55, -0.78, -0.01]:
		_runtime._add_box(line, Vector3(0.70, 0.62, 0.34), Vector3(upper_x, 1.92, -0.12), cabinet)
		_runtime._add_box(line, Vector3(0.59, 0.51, 0.025), Vector3(upper_x, 1.92, 0.06), enamel)
		# A concealed strip reads as reflected light on the backsplash, not as a
		# row of floating bulbs.
		_runtime._add_box(line, Vector3(0.58, 0.022, 0.12), Vector3(upper_x, 1.595, 0.055), warm)
	_runtime._add_box(line, Vector3(0.88, 0.055, 0.30), Vector3(1.20, 1.72, 0.06), steel)
	_runtime._add_box(line, Vector3(0.88, 0.055, 0.30), Vector3(1.20, 2.18, 0.06), steel)
	for index in 3:
		var jar_color = Color8(112, 70 + index * 13, 43 + index * 8) if index % 2 == 0 else Color8(76, 96, 67)
		_runtime._add_disc(line, Vector3(0.92 + float(index) * 0.28, 1.88, 0.07), 0.055, 0.20, _runtime._room_surface(jar_color, 0.76))
	# Normal 60 cm cooker hood above the integrated stove.
	_runtime._add_box(root, Vector3(0.82, 0.18, 0.44), Vector3(0.58, 1.88, -1.98), cabinet)
	_runtime._add_box(root, Vector3(0.54, 0.48, 0.27), Vector3(0.58, 2.21, -2.11), steel)
	_runtime._add_box(root, Vector3(0.58, 0.025, 0.28), Vector3(0.58, 1.78, -1.76), warm)
	# Fridge and narrow pantry use domestic dimensions, layered doors and trims.
	_runtime._add_box(root, Vector3(0.78, 1.92, 0.68), Vector3(2.36, 0.96, -1.94), enamel)
	_runtime._add_box(root, Vector3(0.66, 0.54, 0.025), Vector3(2.36, 1.59, -1.585), cabinet)
	_runtime._add_box(root, Vector3(0.66, 1.08, 0.025), Vector3(2.36, 0.75, -1.585), cabinet)
	_runtime._add_box(root, Vector3(0.025, 0.50, 0.035), Vector3(2.64, 1.12, -1.56), steel)

func add_kitchen_hero_dressing(_runtime, root: Node3D, enamel: Material, cabinet: Material, steel: Material, grease: Material, warm: Material, sick: Material) -> void:
	# A compact cook line gives the oversized room one unmistakable focal point.
	var cook_line = Node3D.new()
	cook_line.name = "KitchenHero_CookLine"
	cook_line.position = Vector3(23.0, 0.0, -14.45)
	root.add_child(cook_line)
	_runtime._add_box(cook_line, Vector3(8.0, 0.22, 3.0), Vector3(0, 2.55, 0.10), grease)
	_runtime._add_box(cook_line, Vector3(6.9, 0.16, 2.35), Vector3(0, 2.38, 0.10), steel)
	_runtime._add_box(cook_line, Vector3(0.22, 1.45, 0.22), Vector3(-3.15, 1.78, 0.10), cabinet)
	_runtime._add_box(cook_line, Vector3(0.22, 1.45, 0.22), Vector3(3.15, 1.78, 0.10), cabinet)
	_runtime._add_box(cook_line, Vector3(6.5, 0.055, 0.32), Vector3(0, 2.19, 1.30), warm)
	for burner_x in [-1.8, -0.6, 0.6, 1.8]:
		_runtime._add_disc(cook_line, Vector3(burner_x, 1.28, 0.0), 0.34, 0.055, warm)
	for utensil_x in [-2.6, -1.75, -0.9, 0.9, 1.75, 2.6]:
		_runtime._add_pipe(cook_line, Vector3(utensil_x, 1.78, 1.36), Vector3.ZERO, 0.035, 0.72, steel)
	_runtime._add_room_sign(cook_line, "COOK / MEMORY SERVICE", Vector3(0, 2.82, 1.43), Color8(224, 183, 104), 0.010)
	_runtime._add_practical_omni(root, Vector3(23.0, 1.65, -13.1), Color8(255, 151, 72), 2.4, 5.8)

	# The domestic table is the emotional counterpoint to the industrial cook line.
	_runtime._add_hero_spot(root, Vector3(-18.5, 2.72, 5.0), Vector3(-18.5, 0.85, 8.8), Color8(225, 194, 137), 4.9, 9.5, 46.0)
	_runtime._add_practical_omni(root, Vector3(-18.5, 2.25, 8.8), Color8(231, 187, 119), 1.8, 5.0)
	# A service threshold frames the entrance without closing the route.
	for frame_x in [-6.4, 6.4]:
		_runtime._add_box(root, Vector3(0.34, 2.8, 0.34), Vector3(frame_x, 1.42, 11.0), cabinet)
	_runtime._add_box(root, Vector3(13.2, 0.22, 0.34), Vector3(0, 2.88, 11.0), cabinet)
	_runtime._add_box(root, Vector3(4.4, 0.028, 0.20), Vector3(0, 2.72, 10.96), sick)

	_runtime._add_room_asset(root, "duct_long.glb", Vector3(0.0, 2.78, -2.5), 90.0, 0.56)
	_runtime._add_room_asset(root, "pipe_rusted.glb", Vector3(-28.8, 2.48, -2.0), 0.0, 2.25)

	# Central preparation island: visible immediately from the entrance and dense
	# enough to make the room read as a working kitchen before any UI prompt does.
	var island = Node3D.new()
	island.name = "KitchenHero_PreparationIsland"
	island.position = Vector3(3.0, 0.0, -3.0)
	island.rotation_degrees.y = -7.0
	root.add_child(island)
	_runtime._add_box(island, Vector3(10.8, 0.92, 3.9), Vector3(0, 0.50, 0), cabinet)
	_runtime._add_box(island, Vector3(11.2, 0.16, 4.25), Vector3(0, 1.02, 0), steel)
	_runtime._add_box(island, Vector3(4.2, 0.12, 2.25), Vector3(-2.55, 1.12, 0), grease)
	_runtime._add_box(island, Vector3(3.65, 0.08, 1.75), Vector3(2.75, 1.13, 0), _runtime._room_surface(Color8(44, 53, 50), 0.34, 0.38))
	for burner_position in [Vector3(-3.6, 1.20, -0.58), Vector3(-1.55, 1.20, -0.58), Vector3(-3.6, 1.20, 0.58), Vector3(-1.55, 1.20, 0.58)]:
		_runtime._add_disc(island, burner_position, 0.46, 0.055, warm)
	_runtime._add_pipe(island, Vector3(2.75, 1.72, 0.72), Vector3.ZERO, 0.075, 1.12, steel)
	_runtime._add_pipe(island, Vector3(2.75, 2.12, 0.22), Vector3(90, 0, 0), 0.075, 0.82, steel)
	for cabinet_x in [-4.25, -1.45, 1.45, 4.25]:
		_runtime._add_box(island, Vector3(2.45, 0.66, 0.065), Vector3(cabinet_x, 0.52, 1.98), enamel)
		_runtime._add_box(island, Vector3(0.72, 0.045, 0.09), Vector3(cabinet_x, 0.60, 2.03), steel)
	_runtime._add_box(island, Vector3(8.6, 0.34, 3.0), Vector3(0, 2.77, 0), grease)
	_runtime._add_box(island, Vector3(7.7, 0.055, 2.32), Vector3(0, 2.57, 0), warm)
	for support_x in [-3.55, 3.55]:
		_runtime._add_box(island, Vector3(0.20, 1.52, 0.20), Vector3(support_x, 1.94, 0), steel)
	_runtime._add_room_sign(island, "PREP  /  SERVICE", Vector3(0, 2.33, 1.58), Color8(223, 190, 125), 0.009)
	_runtime._add_hero_spot(root, Vector3(3.0, 3.05, 2.0), Vector3(3.0, 0.92, -3.0), Color8(255, 205, 139), 8.7, 12.5, 58.0)
	_runtime._add_practical_omni(root, Vector3(3.0, 2.20, -3.0), Color8(247, 188, 111), 3.4, 8.5)

	# Refrigerator and pantry silhouettes stop the far wall feeling like generic
	# corridor cladding. One door is left ajar as a small memory-story beat.
	for fridge_x in [-26.0, -22.2, -18.4]:
		_runtime._add_box(root, Vector3(3.35, 2.72, 2.15), Vector3(fridge_x, 1.38, -13.65), enamel)
		_runtime._add_box(root, Vector3(2.92, 1.98, 0.08), Vector3(fridge_x, 1.48, -12.54), cabinet)
		_runtime._add_box(root, Vector3(0.08, 1.22, 0.10), Vector3(fridge_x + 1.13, 1.55, -12.46), steel)
	_runtime._add_box(root, Vector3(3.0, 2.45, 0.12), Vector3(-17.0, 1.38, -12.0), enamel).rotation_degrees.y = -24.0
	_runtime._add_practical_omni(root, Vector3(-19.2, 1.55, -11.8), Color8(151, 188, 166), 1.45, 4.6)

	# Hand-worked preparation clutter. These silhouettes are concentrated around
	# the hero island so the room reads as a kitchen from the doorway, not only
	# after the player reaches the objective marker.
	for pot_x in [-3.35, -2.35]:
		_runtime._add_disc(island, Vector3(pot_x, 1.30, 0.48), 0.42, 0.30, steel)
		_runtime._add_disc(island, Vector3(pot_x, 1.48, 0.48), 0.32, 0.045, grease)
	_runtime._add_box(island, Vector3(1.45, 0.065, 0.82), Vector3(0.35, 1.22, -0.55), enamel).rotation_degrees.y = -8.0
	for knife_x in [-0.12, 0.18, 0.48]:
		var knife = _runtime._add_box(island, Vector3(0.72, 0.035, 0.10), Vector3(knife_x, 1.28, -0.52), steel)
		knife.rotation_degrees.y = -18.0 + knife_x * 12.0
	for jar_data in [
		[Vector3(3.35, 1.38, -0.65), Color8(147, 76, 48)],
		[Vector3(3.85, 1.33, -0.55), Color8(107, 132, 91)],
		[Vector3(4.28, 1.30, -0.42), Color8(177, 143, 72)]
	]:
		_runtime._add_disc(island, jar_data[0], 0.18, 0.42, _runtime._room_surface(jar_data[1], 0.74))
	# Warm backsplash cards fake reflected practical light at a fraction of the
	# cost of extra dynamic lights.
	_runtime._add_box(root, Vector3(16.0, 1.75, 0.035), Vector3(3.0, 1.50, -16.34), _runtime._dim_lit_material(Color8(91, 78, 58), 0.86, 0.28))
	_runtime._add_box(root, Vector3(10.0, 0.035, 6.0), Vector3(3.0, 0.115, -3.0), _runtime._dim_lit_material(Color8(82, 70, 50), 0.92, 0.30))

func dress_kitchen_memory(_runtime, root: Node3D, enamel: Material, tile: Material, cabinet: Material, steel: Material, grease: Material, warm: Material, sick: Material) -> void:
	# The structural ceiling is built once by _build_kitchen_scenario().
	# Cabinet fronts, handles and vents turn the long counter bank into readable
	# kitchen furniture when it enters the flashlight cone.
	for x in [-26.0, -20.5, -15.0, -9.5, -4.0, 1.5, 7.0, 12.5, 18.0]:
		for offset in [-1.18, 1.18]:
			_runtime._add_box(root, Vector3(2.18, 0.73, 0.055), Vector3(x + offset, 0.58, -14.25), cabinet)
			_runtime._add_box(root, Vector3(0.62, 0.055, 0.075), Vector3(x + offset, 0.62, -14.19), steel)
	# Open shelving is filled unevenly so it feels abandoned rather than copied.
	for shelf_y in [0.72, 1.52, 2.32]:
		for item_index in 5:
			var item_x = 16.8 + float(item_index) * 1.55
			var item_height = 0.24 + float((item_index + int(shelf_y * 10.0)) % 3) * 0.13
			_runtime._add_box(root, Vector3(0.62, item_height, 0.66), Vector3(item_x, shelf_y + 0.12, 14.35), enamel if item_index % 2 == 0 else grease)
			if item_index in [1, 4]:
				_runtime._add_box(root, Vector3(0.38, 0.045, 0.70), Vector3(item_x, shelf_y + item_height * 0.55, 14.35), warm)
	# A battered service trolley, trays and a tipped waste bin fill the transition
	# between task stations while leaving the player route broad and clear.
	var trolley = Node3D.new()
	trolley.name = "Kitchen_ServiceTrolley"
	trolley.position = Vector3(18.0, 0.0, 5.8)
	trolley.rotation_degrees.y = -14.0
	root.add_child(trolley)
	for shelf_y in [0.34, 0.96]:
		_runtime._add_box(trolley, Vector3(4.0, 0.12, 1.75), Vector3(0, shelf_y, 0), steel)
	for leg in [Vector3(-1.72, 0.48, -0.64), Vector3(1.72, 0.48, -0.64), Vector3(-1.72, 0.48, 0.64), Vector3(1.72, 0.48, 0.64)]:
		_runtime._add_box(trolley, Vector3(0.13, 0.88, 0.13), leg, cabinet)
		_runtime._add_disc(trolley, leg + Vector3(0, -0.43, 0), 0.16, 0.10, grease, Vector3(90, 0, 0))
	for tray_x in [-1.25, 0.0, 1.25]:
		_runtime._add_box(trolley, Vector3(0.94, 0.045, 1.12), Vector3(tray_x, 1.04, 0), enamel)
	var bin = Node3D.new()
	bin.name = "Kitchen_TippedWaste"
	bin.position = Vector3(27.0, 0.30, 5.5)
	bin.rotation_degrees = Vector3(0, 20, 72)
	root.add_child(bin)
	_runtime._add_box(bin, Vector3(1.0, 1.25, 1.0), Vector3.ZERO, grease)
	for scrap_position in [Vector3(25.7, 0.12, 5.0), Vector3(24.8, 0.10, 6.1), Vector3(26.0, 0.11, 7.0)]:
		_runtime._add_box(root, Vector3(0.72, 0.035, 0.48), scrap_position, enamel)
	# Task markings visually connect the scavenged items to the cooking station.
	_runtime._add_emissive_task_marker(root, Vector3(-22.0, 0.105, -12.8), warm, 3.0)
	_runtime._add_emissive_task_marker(root, Vector3(-2.0, 0.105, 2.5), sick, 2.6)
	_runtime._add_emissive_task_marker(root, Vector3(20.0, 0.105, 12.7), warm, 3.0)
	_runtime._add_emissive_task_marker(root, Vector3(23.0, 0.105, -12.7), warm, 4.0)
	_runtime._add_room_sign(root, "NO SERVICE / 02:17", Vector3(-24.5, 2.05, 16.42), Color8(151, 116, 70), 0.009)

