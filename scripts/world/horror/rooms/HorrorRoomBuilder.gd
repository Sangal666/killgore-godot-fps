extends RefCounted
## Room entrypoint facade; each composition has its own implementation.
var _kitchen = preload("res://scripts/world/horror/rooms/HorrorKitchenBuilder.gd").new()
var _roadside = preload("res://scripts/world/horror/rooms/HorrorRoadsideBuilder.gd").new()
var _passport = preload("res://scripts/world/horror/rooms/HorrorPassportBuilder.gd").new()

func build_kitchen_scenario(_runtime, anchor: Vector3) -> void:
	_kitchen.build_kitchen_scenario(_runtime, anchor)

func build_kitchen_service_transition(_runtime, root: Node3D, wall: Material, dark_metal: Material, steel: Material, recess: Material, ceiling_tile: Material) -> void:
	_kitchen.build_kitchen_service_transition(_runtime, root, wall, dark_metal, steel, recess, ceiling_tile)

func build_deferred_car_placeholder(_runtime, anchor: Vector3) -> void:
	_roadside.build_deferred_car_placeholder(_runtime, anchor)

func build_deferred_passport_placeholder(_runtime, anchor: Vector3) -> void:
	_passport.build_deferred_passport_placeholder(_runtime, anchor)

func build_compact_kitchen_table(_runtime, root: Node3D, position: Vector3, wood: Material, enamel: Material, steel: Material, grease: Material, warm: Material) -> void:
	_kitchen.build_compact_kitchen_table(_runtime, root, position, wood, enamel, steel, grease, warm)

func add_seated_kitchen_woman(_runtime, table: Node3D) -> void:
	_kitchen.add_seated_kitchen_woman(_runtime, table)

func build_kitchen_pendant(_runtime, root: Node3D, housing: Material, steel: Material, warm: Material) -> void:
	_kitchen.build_kitchen_pendant(_runtime, root, housing, steel, warm)

func build_compact_kitchen_line(_runtime, root: Node3D, enamel: Material, cabinet: Material, steel: Material, grease: Material, warm: Material) -> void:
	_kitchen.build_compact_kitchen_line(_runtime, root, enamel, cabinet, steel, grease, warm)

func build_car_scenario(_runtime, anchor: Vector3) -> void:
	_roadside.build_car_scenario(_runtime, anchor)

func build_passport_scenario(_runtime, anchor: Vector3) -> void:
	_passport.build_passport_scenario(_runtime, anchor)

func add_kitchen_hero_dressing(_runtime, root: Node3D, enamel: Material, cabinet: Material, steel: Material, grease: Material, warm: Material, sick: Material) -> void:
	_kitchen.add_kitchen_hero_dressing(_runtime, root, enamel, cabinet, steel, grease, warm, sick)

func add_roadside_hero_dressing(_runtime, root: Node3D, car: Node3D, asphalt: Material, rust: Material, rubber: Material, road_line: Material) -> void:
	_roadside.add_roadside_hero_dressing(_runtime, root, car, asphalt, rust, rubber, road_line)

func add_passport_hero_dressing(_runtime, root: Node3D, institutional: Material, dirty_white: Material, dark: Material, rubber: Material, glass: Material, cyan: Material, amber: Material, warning: Material) -> void:
	_passport.add_passport_hero_dressing(_runtime, root, institutional, dirty_white, dark, rubber, glass, cyan, amber, warning)

func dress_kitchen_memory(_runtime, root: Node3D, enamel: Material, tile: Material, cabinet: Material, steel: Material, grease: Material, warm: Material, sick: Material) -> void:
	_kitchen.dress_kitchen_memory(_runtime, root, enamel, tile, cabinet, steel, grease, warm, sick)

func dress_broken_car(_runtime, car: Node3D, car_paint: Material, rust: Material, rubber: Material, road_line: Material) -> void:
	_roadside.dress_broken_car(_runtime, car, car_paint, rust, rubber, road_line)

func dress_roadside_memory(_runtime, root: Node3D, asphalt: Material, rust: Material, rubber: Material, road_line: Material) -> void:
	_roadside.dress_roadside_memory(_runtime, root, asphalt, rust, rubber, road_line)

func dress_passport_memory(_runtime, root: Node3D, institutional: Material, dirty_white: Material, dark: Material, rubber: Material, glass: Material, cyan: Material, amber: Material, warning: Material) -> void:
	_passport.dress_passport_memory(_runtime, root, institutional, dirty_white, dark, rubber, glass, cyan, amber, warning)

