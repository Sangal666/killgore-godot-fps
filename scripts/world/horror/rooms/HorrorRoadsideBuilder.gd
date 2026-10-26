extends RefCounted
## Authored roadside composition. Runtime owns nodes and gameplay state.

func build_deferred_car_placeholder(_runtime, anchor: Vector3) -> void:
	# Preserve the existing task state and interactions while deferring the final
	# roadside art pass. This is a compact neutral staging room, not an arena.
	_runtime.task_states["car"] = {"complete": false, "collected": {}, "fitted": {}, "installed": 0}
	var root = Node3D.new()
	root.name = "MemoryRoom_Roadside"
	root.position = anchor
	_runtime.add_child(root)
	_runtime._register_memory_room_visual(root, Vector2(6.0, 6.0))
	var dark = _runtime._room_surface(Color8(35, 34, 30), 0.96)
	var neutral = _runtime._dim_lit_material(Color8(72, 66, 55), 0.90, 0.18)
	var metal = _runtime._dim_lit_material(Color8(82, 79, 69), 0.62, 0.22)
	# One covered service plinth is enough to retain the mechanic without falsely
	# presenting this as the finished road memory.
	var car = Node3D.new()
	car.name = "DeferredVehicle_Interact"
	car.position = Vector3(0.0, 0.0, -0.35)
	root.add_child(car)
	_runtime._add_box(car, Vector3(2.20, 0.68, 1.25), Vector3(0.0, 0.36, 0.0), dark)
	_runtime._add_box(car, Vector3(1.55, 0.32, 1.05), Vector3(-0.18, 0.82, 0.0), neutral)
	_runtime._add_interactable("car", "car_install", car, "INSTALL A CAR PART", "CAR", false)
	_runtime._add_interactable("tire", "car_part", _runtime._make_task_prop(root, Vector3(-2.65, 0.64, 2.25), "wheel", dark), "TAKE TIRE", "TIRE")
	_runtime._add_interactable("fuel", "car_part", _runtime._make_task_prop(root, Vector3(0.0, 0.55, 2.65), "can", neutral), "TAKE FUEL", "FUEL")
	_runtime._add_interactable("engine", "car_part", _runtime._make_task_prop(root, Vector3(2.65, 0.58, 2.25), "engine", metal), "TAKE ENGINE PART", "ENGINE")
	_runtime._add_room_light(root, Vector3(0.0, 3.05, 0.0), Color8(157, 137, 94), 1.25, 7.0)
	_runtime._batch_static_room_boxes(root)

func build_car_scenario(_runtime, anchor: Vector3) -> void:
	_runtime.task_states["car"] = {"complete": false, "collected": {}, "fitted": {}, "installed": 0}
	var root = Node3D.new()
	root.name = "MemoryRoom_Roadside"
	root.position = anchor
	_runtime.add_child(root)
	_runtime._register_memory_room_visual(root, Vector2(39.0, 17.0))
	var asphalt = _runtime._room_surface(Color8(52, 54, 54), 0.96)
	var road_line = _runtime._glow_material(Color8(166, 151, 103), 0.72)
	var car_paint = _runtime._room_surface(Color8(98, 113, 106), 0.56, 0.38)
	var rust = _runtime._room_surface(Color8(105, 63, 43), 0.88, 0.12)
	var rubber = _runtime._room_surface(Color8(15, 16, 16), 0.98)
	_runtime._add_box(root, Vector3(78.0, 0.10, 34.0), Vector3.ZERO, asphalt)
	# The road memory is an enclosed underpass, not an open black arena. Broad
	# ceiling slabs are intentionally cheap meshes; the pools below do the work.
	_runtime._add_segmented_ceiling(root, Vector2(77.0, 33.0), 7, 3, rubber, rust)
	_runtime._add_box(root, Vector3(76.0, 0.20, 1.1), Vector3(0.0, 2.94, -14.5), asphalt)
	_runtime._add_box(root, Vector3(76.0, 0.20, 1.1), Vector3(0.0, 2.94, 14.5), asphalt)
	for x in [-32.0, -20.0, -8.0, 4.0, 16.0, 28.0]:
		_runtime._add_box(root, Vector3(6.0, 0.025, 0.18), Vector3(x, 0.075, 0.0), road_line)
	for z in [-15.2, 15.2]:
		_runtime._add_box(root, Vector3(76.0, 0.35, 0.32), Vector3(0, 0.20, z), rust)
		for x in [-33.0, -22.0, -11.0, 0.0, 11.0, 22.0, 33.0]:
			_runtime._add_box(root, Vector3(9.2, 3.4, 0.18), Vector3(x, 1.72, z), asphalt)
			_runtime._add_box(root, Vector3(0.18, 3.5, 0.26), Vector3(x + 4.55, 1.75, z), rust)
			_runtime._add_box(root, Vector3(3.6, 0.06, 0.28), Vector3(x, 2.72, z * 0.992), road_line)
	# Raised maintenance sidewalks establish a road cross-section at a glance.
	for z in [-12.8, 12.8]:
		_runtime._add_box(root, Vector3(74.0, 0.22, 3.8), Vector3(0.0, 0.14, z), rubber)
		_runtime._add_box(root, Vector3(74.0, 0.055, 0.18), Vector3(0.0, 0.28, z - sign(z) * 1.78), road_line)
	# Tunnel service alcoves and abandoned road furniture.
	for x in [-31.0, 31.0]:
		_runtime._add_box(root, Vector3(5.5, 2.4, 4.2), Vector3(x, 1.2, 12.0), rust)
		_runtime._add_box(root, Vector3(5.0, 0.12, 3.8), Vector3(x, 2.45, 12.0), road_line)
	for x in [-26.0, -12.0, 15.0, 29.0]:
		_runtime._add_box(root, Vector3(0.18, 1.1, 0.18), Vector3(x, 0.55, -12.8), road_line)
		_runtime._add_box(root, Vector3(2.4, 0.28, 0.36), Vector3(x, 1.1, -12.8), rust)
	# Tunnel-distance markers and arrow boards turn the roadside room into a
	# believable abandoned underpass rather than a dark open arena.
	for marker_x in [-25.0, -9.0, 7.0, 23.0]:
		_runtime._add_box(root, Vector3(3.2, 1.05, 0.12), Vector3(marker_x, 1.70, 14.83), rubber)
		_runtime._add_box(root, Vector3(2.45, 0.12, 0.15), Vector3(marker_x, 1.78, 14.72), road_line)
		_runtime._add_box(root, Vector3(0.42, 0.12, 0.15), Vector3(marker_x + 0.85, 1.55, 14.70), road_line).rotation_degrees.z = -28.0
	# Concrete ribs, drainage and emergency infrastructure give the tunnel a
	# believable scale and provide landmarks while the monster searches it.
	for rib_x in [-33.0, -17.0, -1.0, 15.0, 31.0]:
		_runtime._add_box(root, Vector3(0.65, 3.45, 2.0), Vector3(rib_x, 1.73, -14.0), rust)
		_runtime._add_box(root, Vector3(0.65, 3.45, 2.0), Vector3(rib_x, 1.73, 14.0), rust)
		_runtime._add_box(root, Vector3(0.78, 0.32, 26.0), Vector3(rib_x, 3.30, 0.0), rubber)
	_runtime._add_box(root, Vector3(74.0, 0.04, 0.22), Vector3(0, 0.08, -8.4), rust)
	_runtime._add_box(root, Vector3(74.0, 0.04, 0.22), Vector3(0, 0.08, 8.4), rust)
	var call_box = Node3D.new()
	call_box.name = "EmergencyCallBox"
	call_box.position = Vector3(-31.0, 0.0, -12.4)
	root.add_child(call_box)
	_runtime._add_box(call_box, Vector3(1.1, 1.85, 0.62), Vector3(0, 0.94, 0), rust)
	_runtime._add_box(call_box, Vector3(0.72, 0.56, 0.08), Vector3(0, 1.28, -0.34), road_line)
	_runtime._add_room_sign(root, "SOS", Vector3(-31.0, 2.05, -12.72), Color8(190, 145, 88), 0.010)
	var car = Node3D.new()
	car.name = "BrokenCar_Interact"
	car.position = Vector3(1.0, 0.0, 0.0)
	root.add_child(car)
	car.rotation_degrees.y = -8.0
	car.scale = Vector3.ONE * 1.26
	_runtime._add_box(car, Vector3(7.2, 0.92, 3.0), Vector3(0, 0.76, 0), car_paint)
	# Layered bodywork, cabin glass and wheel arches keep the vehicle readable as
	# a stranded estate car instead of a single rectangular prop.
	_runtime._add_box(car, Vector3(3.25, 0.82, 2.58), Vector3(-0.72, 1.48, 0), car_paint)
	var car_glass = _runtime._room_surface(Color8(35, 54, 56), 0.22, 0.42)
	_runtime._add_box(car, Vector3(1.18, 0.62, 2.42), Vector3(-1.42, 1.53, 0), car_glass).rotation_degrees.z = -17.0
	_runtime._add_box(car, Vector3(1.18, 0.62, 2.42), Vector3(0.06, 1.53, 0), car_glass).rotation_degrees.z = 13.0
	_runtime._add_box(car, Vector3(2.50, 0.14, 2.72), Vector3(-0.68, 1.94, 0), rust)
	_runtime._add_box(car, Vector3(0.13, 0.72, 2.70), Vector3(-0.68, 1.49, 0), rust)
	_runtime._add_box(car, Vector3(0.08, 0.78, 2.38), Vector3(-2.05, 1.42, 0), rust).rotation_degrees.z = 48.0
	_runtime._add_box(car, Vector3(0.08, 0.78, 2.38), Vector3(0.85, 1.42, 0), rust).rotation_degrees.z = -48.0
	_runtime._add_box(car, Vector3(0.12, 0.54, 2.72), Vector3(-3.58, 0.82, 0), rust)
	_runtime._add_box(car, Vector3(0.34, 0.30, 3.12), Vector3(-3.68, 0.54, 0), rubber)
	_runtime._add_box(car, Vector3(0.34, 0.30, 3.12), Vector3(3.68, 0.54, 0), rubber)
	_runtime._add_box(car, Vector3(1.9, 0.14, 2.62), Vector3(3.45, 0.66, 0), rust)
	_runtime._add_box(car, Vector3(2.4, 0.16, 2.68), Vector3(2.15, 1.54, 0), car_paint).rotation_degrees.z = -24.0
	_runtime._add_box(car, Vector3(1.75, 0.07, 2.30), Vector3(2.20, 1.66, 0), rubber).rotation_degrees.z = -24.0
	_runtime._add_box(car, Vector3(1.65, 0.46, 2.18), Vector3(2.36, 1.13, 0), rust)
	for seat_z in [-0.72, 0.72]:
		_runtime._add_box(car, Vector3(0.72, 0.72, 0.58), Vector3(-0.55, 1.12, seat_z), rubber)
	for headlight_z in [-0.88, 0.88]:
		_runtime._add_box(car, Vector3(0.12, 0.30, 0.48), Vector3(3.64, 0.86, headlight_z), _runtime._glow_material(Color8(196, 178, 124), 1.2))
	for wheel_pos in [Vector3(-2.1, 0.43, -1.42), Vector3(-2.1, 0.43, 1.42), Vector3(2.1, 0.43, -1.42)]:
		var wheel = MeshInstance3D.new()
		var wheel_mesh = CylinderMesh.new()
		wheel_mesh.top_radius = 0.52
		wheel_mesh.bottom_radius = 0.52
		wheel_mesh.height = 0.30
		wheel_mesh.radial_segments = 12
		wheel.mesh = wheel_mesh
		wheel.position = wheel_pos
		wheel.rotation_degrees.z = 90.0
		wheel.material_override = rubber
		car.add_child(wheel)
	dress_broken_car(_runtime, car, car_paint, rust, rubber, road_line)
	# The missing wheel, jack and scattered tools turn the vehicle into a task
	# scene instead of an abstract car-shaped block.
	_runtime._add_disc(car, Vector3(2.1, 0.43, 1.42), 0.30, 0.22, rust, Vector3(0, 0, 90))
	_runtime._add_box(root, Vector3(1.4, 0.12, 0.18), Vector3(3.1, 0.18, 3.2), rust).rotation_degrees.y = 24.0
	_runtime._add_box(root, Vector3(0.20, 0.70, 0.20), Vector3(2.7, 0.38, 2.6), road_line).rotation_degrees.z = 27.0
	for cone_pos in [Vector3(-5.0, 0.35, -4.4), Vector3(7.0, 0.35, 4.6), Vector3(12.0, 0.35, -5.2)]:
		_runtime._add_traffic_cone(root, cone_pos, rust, road_line)
	# The concrete underpass ribs already define the ceiling. Additional rafts
	# made the road read as a stack of black slabs from player height.
	# Headlight spill remains emissive, so the broken car reads without another
	# realtime light pair.
	_runtime._add_box(root, Vector3(9.0, 0.025, 2.0), Vector3(8.4, 0.09, -1.0), _runtime._dim_lit_material(Color8(128, 116, 79), 0.92, 1.42)).rotation_degrees.y = -8.0
	_runtime._add_box(root, Vector3(7.0, 0.025, 1.2), Vector3(8.0, 0.10, 1.2), _runtime._dim_lit_material(Color8(105, 94, 66), 0.92, 1.15)).rotation_degrees.y = -8.0
	for light_pos in [Vector3(1.0, 2.70, 4.5)]:
		_runtime._add_room_light(root, light_pos, Color8(191, 170, 116), 4.6, 16.5)
	_runtime._add_room_fill_light(root, Vector3(1.0, 2.25, 0.0), Color8(124, 104, 76), 1.10, 31.0)
	_runtime._add_room_floor_pool(root, Vector3(-22.0, 0.082, -6.0), Vector2(18.0, 13.0), Color8(96, 84, 60), 0.24)
	_runtime._add_room_floor_pool(root, Vector3(1.0, 0.082, 0.0), Vector2(20.0, 14.0), Color8(99, 75, 54), 0.30)
	_runtime._add_room_floor_pool(root, Vector3(24.0, 0.082, 6.0), Vector2(18.0, 13.0), Color8(84, 71, 52), 0.22)
	_runtime._add_room_sign(root, "SERVICE BAY 19", Vector3(-17.0, 2.30, -14.82), Color8(178, 142, 94), 0.0042)
	dress_roadside_memory(_runtime, root, asphalt, rust, rubber, road_line)
	add_roadside_hero_dressing(_runtime, root, car, asphalt, rust, rubber, road_line)
	_runtime._add_interactable("car", "car_install", car, "INSTALL A CAR PART", "CAR", false)
	_runtime._add_interactable("tire", "car_part", _runtime._make_task_prop(root, Vector3(-30.0, 0.64, -10.5), "wheel", rubber), "TAKE TIRE", "TIRE")
	_runtime._add_interactable("fuel", "car_part", _runtime._make_task_prop(root, Vector3(31.0, 0.55, 11.5), "can", rust), "TAKE FUEL", "FUEL")
	_runtime._add_interactable("engine", "car_part", _runtime._make_task_prop(root, Vector3(-27.0, 0.58, 11.5), "engine", road_line), "TAKE ENGINE PART", "ENGINE")
	_runtime._batch_static_room_boxes(root)

func add_roadside_hero_dressing(_runtime, root: Node3D, car: Node3D, asphalt: Material, rust: Material, rubber: Material, road_line: Material) -> void:
	# Imported street furniture establishes a believable roadside scale.
	_runtime._add_room_asset(root, "street_light.glb", Vector3(-20.0, 0.26, -11.6), 0.0, 2.95)
	_runtime._add_room_asset(root, "street_light.glb", Vector3(6.0, 0.26, 11.6), 180.0, 2.95)
	_runtime._add_room_asset(root, "street_light.glb", Vector3(28.0, 0.26, -11.6), 0.0, 2.95)
	_runtime._add_room_asset(root, "busstop.glb", Vector3(-22.0, 0.26, 10.8), 180.0, 2.45)
	_runtime._add_room_asset(root, "dumpster_lid_closed.glb", Vector3(27.0, 0.28, 11.2), -12.0, 1.10)
	_runtime._add_room_asset(root, "pipe_rusted.glb", Vector3(34.0, 0.28, -11.6), 90.0, 1.85)
	# A contained pool of light makes the repair scene legible without exposing
	# the whole tunnel. Red hazards and cool street lamps create depth layers.
	_runtime._add_hero_spot(root, Vector3(1.0, 3.05, 6.8), Vector3(1.0, 0.75, 0.0), Color8(238, 183, 116), 8.5, 13.5, 54.0)
	_runtime._add_practical_omni(root, car.position + Vector3(3.8, 0.85, -0.9), Color8(255, 213, 142), 2.8, 6.5)
	_runtime._add_practical_omni(root, car.position + Vector3(-2.8, 0.65, 0.0), Color8(168, 46, 35), 1.9, 4.8)
	_runtime._add_practical_omni(root, car.position + Vector3(0.0, 2.35, 0.0), Color8(230, 180, 116), 3.6, 9.5)
	for hazard_position in [Vector3(-5.0, 0.72, -4.4), Vector3(7.0, 0.72, 4.6), Vector3(12.0, 0.72, -5.2)]:
		_runtime._add_disc(root, hazard_position, 0.12, 0.08, road_line)
		_runtime._add_practical_omni(root, hazard_position + Vector3(0, 0.08, 0), Color8(223, 94, 48), 0.7, 2.3)

	# A rough service island and crash barrier keep the vehicle from floating in
	# an empty arena while preserving every path around it.
	_runtime._add_box(root, Vector3(13.5, 0.10, 0.22), Vector3(0.5, 0.12, -5.8), road_line)
	for barrier_x in [-5.5, -1.5, 2.5, 6.5]:
		_runtime._add_box(root, Vector3(3.3, 0.42, 0.30), Vector3(barrier_x, 0.55, 7.2), rust).rotation_degrees.z = -5.0
		_runtime._add_box(root, Vector3(0.16, 0.62, 0.16), Vector3(barrier_x - 1.25, 0.28, 7.2), rubber)
	_runtime._add_room_sign(root, "RECOVERY 19", Vector3(1.0, 2.42, -14.70), Color8(202, 129, 77), 0.0040)
	# Wet asphalt patches catch the practical lights without turning the whole road
	# into a mirror. Oil and rain streaks form a path through the repair tableau.
	var wet = _runtime._room_surface(Color8(32, 39, 39), 0.22, 0.62)
	for puddle_data in [
		[Vector3(-10.0, 0.105, -3.8), Vector3(8.5, 0.016, 2.2), -5.0],
		[Vector3(1.8, 0.108, 3.8), Vector3(10.5, 0.016, 2.8), -9.0],
		[Vector3(17.0, 0.105, -5.0), Vector3(7.0, 0.016, 1.8), 4.0]
	]:
		var puddle = _runtime._add_box(root, puddle_data[1], puddle_data[0], wet)
		puddle.rotation_degrees.y = puddle_data[2]
	for oil_position in [Vector3(-1.2, 0.118, -1.5), Vector3(0.2, 0.119, -1.0), Vector3(1.1, 0.118, -0.4)]:
		_runtime._add_disc(root, oil_position, 0.72, 0.018, rubber)
	# Roadside storytelling: a torn cargo trail, repair blanket and distant tunnel
	# thresholds make the scene feel occupied rather than staged on a black plane.
	_runtime._add_box(root, Vector3(6.6, 0.035, 3.8), Vector3(-5.2, 0.12, 3.5), _runtime._dim_lit_material(Color8(76, 61, 47), 0.96, 0.24)).rotation_degrees.y = 8.0
	for tool_data in [
		[Vector3(-6.4, 0.18, 3.1), Vector3(1.8, 0.08, 0.13), -21.0],
		[Vector3(-4.8, 0.18, 3.8), Vector3(1.25, 0.10, 0.16), 34.0],
		[Vector3(-3.8, 0.22, 2.9), Vector3(0.32, 0.28, 0.22), 0.0]
	]:
		var tool = _runtime._add_box(root, tool_data[1], tool_data[0], rust)
		tool.rotation_degrees.y = tool_data[2]
	for debris_data in [
		[Vector3(-12.0, 0.26, 6.4), Vector3(1.5, 0.46, 0.9), -11.0],
		[Vector3(13.0, 0.22, -6.6), Vector3(1.2, 0.38, 0.8), 17.0],
		[Vector3(18.0, 0.18, 5.5), Vector3(0.9, 0.30, 0.6), -28.0]
	]:
		var debris = _runtime._add_box(root, debris_data[1], debris_data[0], rubber)
		debris.rotation_degrees.y = debris_data[2]
	# Large low-energy emissive portals retain tunnel depth without another light.
	for portal_x in [-35.5, 35.5]:
		_runtime._add_box(root, Vector3(0.22, 3.0, 20.0), Vector3(portal_x, 1.52, 0.0), _runtime._dim_lit_material(Color8(48, 45, 39), 0.94, 0.26))
		_runtime._add_box(root, Vector3(0.24, 0.16, 12.0), Vector3(portal_x * 0.997, 2.62, 0.0), road_line)

func dress_broken_car(_runtime, car: Node3D, car_paint: Material, rust: Material, rubber: Material, road_line: Material) -> void:
	var glass = _runtime._room_surface(Color(0.055, 0.095, 0.10, 0.72), 0.18, 0.36)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var upholstery = _runtime._room_surface(Color8(39, 43, 40), 0.92)
	# Windows and pillars create a recognisable cabin silhouette.
	_runtime._add_box(car, Vector3(1.36, 0.72, 2.38), Vector3(-0.70, 1.56, 0), glass)
	_runtime._add_box(car, Vector3(0.13, 0.86, 2.52), Vector3(-1.42, 1.53, 0), rust).rotation_degrees.z = 15.0
	_runtime._add_box(car, Vector3(0.13, 0.86, 2.52), Vector3(0.08, 1.53, 0), rust).rotation_degrees.z = -15.0
	for seat_z in [-0.72, 0.72]:
		_runtime._add_box(car, Vector3(0.92, 0.72, 0.64), Vector3(-0.68, 1.08, seat_z), upholstery)
		_runtime._add_box(car, Vector3(0.72, 0.92, 0.18), Vector3(-1.05, 1.46, seat_z), upholstery).rotation_degrees.z = -8.0
	# Door seams, handles, bumpers and grille make the car readable up close.
	for side_z in [-1.52, 1.52]:
		_runtime._add_box(car, Vector3(2.65, 0.055, 0.035), Vector3(-0.55, 0.91, side_z), rust)
		_runtime._add_box(car, Vector3(0.055, 0.75, 0.035), Vector3(-1.85, 0.91, side_z), rust)
		_runtime._add_box(car, Vector3(0.62, 0.09, 0.055), Vector3(-0.55, 1.12, side_z), rubber)
		_runtime._add_box(car, Vector3(0.62, 0.28, 0.16), Vector3(-0.65, 1.84, side_z), glass)
	_runtime._add_box(car, Vector3(0.22, 0.46, 2.78), Vector3(3.68, 0.52, 0), rubber)
	for grille_z in [-0.78, -0.39, 0.0, 0.39, 0.78]:
		_runtime._add_box(car, Vector3(0.08, 0.38, 0.16), Vector3(3.79, 0.63, grille_z), rust)
	_runtime._add_box(car, Vector3(0.08, 0.52, 1.16), Vector3(-3.68, 0.78, 0), rubber)
	_runtime._add_box(car, Vector3(0.09, 0.28, 0.64), Vector3(-3.75, 0.92, 0), road_line)
	# The open bonnet exposes an engine mass, hoses and a weak service light.
	_runtime._add_box(car, Vector3(2.05, 0.42, 2.18), Vector3(2.22, 0.88, 0), rubber)
	for engine_z in [-0.68, 0.0, 0.68]:
		_runtime._add_pipe(car, Vector3(2.32, 1.16, engine_z), Vector3(0, 0, 90), 0.11, 1.25, rust)
	_runtime._add_box(car, Vector3(0.68, 0.52, 0.92), Vector3(2.12, 1.12, 0), car_paint)
	_runtime._add_box(car, Vector3(1.36, 0.035, 0.10), Vector3(2.38, 1.46, 0), road_line)

func dress_roadside_memory(_runtime, root: Node3D, asphalt: Material, rust: Material, rubber: Material, road_line: Material) -> void:
	# The underpass ceiling is built once by _build_car_scenario().
	# Drainage, oil and old lane repairs make the floor tell the breakdown story.
	var puddle = _runtime._room_surface(Color(0.025, 0.030, 0.031, 0.78), 0.16, 0.46)
	puddle.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for puddle_data in [
		[Vector3(-8.0, 0.102, 4.5), Vector3(7.5, 0.018, 2.8), -9.0],
		[Vector3(4.0, 0.103, -4.0), Vector3(5.4, 0.018, 2.2), 16.0],
		[Vector3(20.0, 0.103, 7.2), Vector3(4.2, 0.018, 1.8), -21.0]
	]:
		var stain = _runtime._add_box(root, puddle_data[1], puddle_data[0], puddle)
		stain.rotation_degrees.y = float(puddle_data[2])
	# A repair kit, luggage and safety triangles form a close-range prop cluster.
	var toolbox = Node3D.new()
	toolbox.name = "Roadside_Toolbox"
	toolbox.position = Vector3(5.8, 0.0, 3.0)
	toolbox.rotation_degrees.y = -17.0
	root.add_child(toolbox)
	_runtime._add_box(toolbox, Vector3(2.0, 0.48, 0.92), Vector3(0, 0.28, 0), rust)
	_runtime._add_box(toolbox, Vector3(1.72, 0.06, 0.68), Vector3(0, 0.55, 0), road_line)
	_runtime._add_box(toolbox, Vector3(0.62, 0.30, 0.12), Vector3(0, 0.78, 0), rubber)
	for tool_x in [-0.68, -0.18, 0.34, 0.72]:
		_runtime._add_box(root, Vector3(0.48, 0.055, 0.10), Vector3(6.1 + tool_x, 0.13, 4.0 + tool_x * 0.25), road_line).rotation_degrees.y = 18.0 + tool_x * 21.0
	for case_data in [
		[Vector3(-12.0, 0.48, 11.2), Vector3(1.45, 0.92, 0.74)],
		[Vector3(-10.5, 0.36, 12.2), Vector3(1.10, 0.68, 0.62)]
	]:
		_runtime._add_box(root, case_data[1], case_data[0], rubber)
	# Repeating cable trays and dripping pipes fill the ceiling without adding
	# expensive light nodes.
	for z in [-10.5, 10.5]:
		_runtime._add_box(root, Vector3(70.0, 0.18, 0.72), Vector3(0, _runtime.WALL_HEIGHT - 0.42, z), rust)
		for x in [-28.0, -14.0, 0.0, 14.0, 28.0]:
			_runtime._add_pipe(root, Vector3(x, _runtime.WALL_HEIGHT - 0.54, z), Vector3(0, 0, 90), 0.08, 8.0, rubber)
	_runtime._add_emissive_task_marker(root, Vector3(-30.0, 0.31, -10.5), road_line, 3.2)
	_runtime._add_emissive_task_marker(root, Vector3(31.0, 0.31, 11.5), road_line, 3.2)
	_runtime._add_emissive_task_marker(root, Vector3(-27.0, 0.31, 11.5), road_line, 3.2)

