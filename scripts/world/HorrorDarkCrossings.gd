extends Node3D
## Deterministic two-lane encounters between existing ceiling-light refuges.
## The original light list is immutable; pockets change the real map, not an overlay.

const STEP := 4.0
const DIRS := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
var runtime
var crossings: Array[Dictionary] = []
var omitted: Array[Dictionary] = []
var pocket_cells: Array[Vector2i] = []
var noisy_props: Array[Dictionary] = []
var metal: Material
var wood: Material
var dark: Material
var edge: Material
var rattle: AudioStreamPlayer3D

func build(owner_runtime, raw: Array) -> void:
	runtime = owner_runtime
	metal = runtime._flat_material(Color(0.24, 0.26, 0.24), 0.83)
	wood = runtime._make_concrete_shader(Color(0.31, 0.25, 0.17), 0.32, 0.94)
	dark = runtime._flat_material(Color(0.085, 0.095, 0.09), 0.91)
	edge = runtime._flat_material(Color(0.32, 0.30, 0.22), 0.84)
	# Worn trim gives the flashlight a readable edge without a fake glow.
	# Ordinary worn trim responds to the actual light, not neon self-emission.
	edge.emission_enabled = false
	rattle = AudioStreamPlayer3D.new()
	rattle.stream = _rattle_sound()
	rattle.volume_db = -22.0
	rattle.max_distance = 14.0
	add_child(rattle)
	var links := _light_links(raw)
	for link in links:
		var cells: Array = link.cells
		var chosen := -1
		var ordered: Array[int] = []
		for index in range(2, cells.size() - 2):
			ordered.append(index)
		ordered.sort_custom(func(a, b): return absf(a - cells.size() * 0.5) < absf(b - cells.size() * 0.5))
		for index in ordered:
			if _can_place(raw, cells, index):
				chosen = index
				break
		if chosen < 0:
			var shared := false
			for crossing in crossings:
				for route_cell in cells:
					if runtime._cell_world(route_cell).distance_to(crossing.center) <= 4.01:
						crossing.get_or_add("shared_links",[]).append(link.lights)
						shared = true
						break
				if shared:
					break
			if not shared:
				var kitchen_link := false
				for route_cell in cells:
					if runtime._inside_kitchen_art_zone(runtime._cell_world(route_cell)):
						kitchen_link = true
				if kitchen_link:
					_build_kitchen_crossing(link)
				else:
					omitted.append(link)
			continue
		_build_crossing(raw, link, chosen)
	_reseat_wall_dressing(raw)
	runtime.maze_raw = raw.duplicate(true)
	if OS.is_debug_build():
		print("DARK_CROSSINGS=", crossings.size(), " LINKS=", links.size(), " UNRESOLVED=", omitted.size(), " POCKET_CELLS=", pocket_cells.size())

func _build_kitchen_crossing(link: Dictionary) -> void:
	var bay := Node3D.new()
	bay.name = "KitchenMaintenanceBypass"
	bay.position = runtime.task_anchors["kitchen"]
	add_child(bay)
	_solid(bay,Vector3(0.5,0.9,1.5),Vector3(-5.55,0.45,17.8),wood)
	_solid(bay,Vector3(0.5,1.65,1.4),Vector3(-5.55,0.825,15.8),metal)
	runtime._add_box(bay,Vector3(0.035,1.4,0.035),Vector3(-5.28,0.8,16.4),edge)
	var fast := _world_path(bay,[Vector3(0,0,26),Vector3(0,0,9.5)])
	var cover := _world_path(bay,[Vector3(0,0,26),Vector3(0,0,23.2),Vector3(-4.1,0,23.2),Vector3(-4.1,0,12),Vector3(0,0,12),Vector3(0,0,9.5)])
	crossings.append({"center":bay.to_global(Vector3(0,0,17.6)),"lights":link.lights,"node":bay,"fast":fast,"cover":cover,"battery":bay.to_global(Vector3(-4.1,0,17.8))})

func _walkable(raw: Array, cell: Vector2i) -> bool:
	return cell.y > 0 and cell.y < raw.size() - 1 and cell.x > 0 and cell.x < String(raw[cell.y]).length() - 1 and String(raw[cell.y]).substr(cell.x, 1) != "#"

func _light_links(raw: Array) -> Array[Dictionary]:
	var owners: Dictionary = {}
	var parents: Dictionary = {}
	var distances: Dictionary = {}
	var queue: Array[Vector2i] = []
	for index in runtime.route_light_positions.size():
		var cell: Vector2i = runtime._world_cell(runtime.route_light_positions[index])
		owners[cell] = index
		parents[cell] = cell
		distances[cell] = 0
		queue.append(cell)
	var candidates: Dictionary = {}
	var cursor := 0
	while cursor < queue.size():
		var cell := queue[cursor]
		cursor += 1
		for direction in DIRS:
			var next: Vector2i = cell + direction
			if not _walkable(raw, next) or runtime.level_manager.is_blocked_world(runtime._cell_world(next) + Vector3.UP * 0.48, 0.32):
				continue
			if not owners.has(next):
				owners[next] = owners[cell]
				parents[next] = cell
				distances[next] = int(distances[cell]) + 1
				queue.append(next)
			elif owners[next] != owners[cell]:
				var key := Vector2i(mini(owners[cell], owners[next]), maxi(owners[cell], owners[next]))
				var length: int = distances[cell] + distances[next] + 1
				if candidates.has(key) and candidates[key].length <= length:
					continue
				candidates[key] = {"a": cell, "b": next, "length": length}
	var result: Array[Dictionary] = []
	for key in candidates:
		var candidate: Dictionary = candidates[key]
		var left: Array[Vector2i] = []
		var cell: Vector2i = candidate.a
		while true:
			left.append(cell)
			if parents[cell] == cell:
				break
			cell = parents[cell]
		left.reverse()
		cell = candidate.b
		while true:
			left.append(cell)
			if parents[cell] == cell:
				break
			cell = parents[cell]
		result.append({"lights": key, "cells": left})
	return result

func _can_place(raw: Array, cells: Array, index: int) -> bool:
	var cell: Vector2i = cells[index]
	var axis: Vector2i = cell - cells[index - 1]
	if cells[index + 1] - cell != axis:
		return false
	if cells[index - 2] != cell - axis * 2 or cells[index + 2] != cell + axis * 2:
		return false
	var position: Vector3 = runtime._cell_world(cell)
	if runtime._inside_kitchen_art_zone(position):
		return false
	for light in runtime.route_light_positions:
		if position.distance_to(light) < 8.0:
			return false
	for crossing in crossings:
		if position.distance_to(crossing.center) < 12.0:
			return false
	# Reserve a 12x12m bay. Never cut an accidental door into another corridor,
	# or alter authored room solids / existing refuges.
	for z in range(-1, 2):
		for x in range(-1, 2):
			var candidate := cell + Vector2i(x, z)
			if candidate.y < 2 or candidate.y >= raw.size() - 2 or candidate.x < 2 or candidate.x >= String(raw[candidate.y]).length() - 2:
				return false
			if runtime._inside_kitchen_art_zone(runtime._cell_world(candidate)):
				return false
			if not _walkable(raw, candidate):
				for direction in DIRS:
					var neighbor: Vector2i = candidate + direction
					if absi(neighbor.x - cell.x) > 1 or absi(neighbor.y - cell.y) > 1:
						if _walkable(raw, neighbor):
							return false
	return true

func _build_crossing(raw: Array, link: Dictionary, index: int) -> void:
	var cell: Vector2i = link.cells[index]
	var axis: Vector2i = link.cells[index + 1] - cell
	for z in range(-1, 2):
		for x in range(-1, 2):
			var candidate := cell + Vector2i(x, z)
			if not _walkable(raw, candidate):
				var row := String(raw[candidate.y])
				raw[candidate.y] = row.substr(0, candidate.x) + "." + row.substr(candidate.x + 1)
				runtime.level_manager.game_map[candidate.y][candidate.x] = "."
				pocket_cells.append(candidate)
	var bay := Node3D.new()
	bay.name = "DarkCrossing_%02d" % crossings.size()
	bay.position = runtime._cell_world(cell)
	bay.rotation.y = atan2(float(axis.x), float(axis.y))
	add_child(bay)
	var variant := crossings.size() % 4
	if variant == 0: # Overturned worktable: vertical slab plus exposed legs.
		_solid(bay, Vector3(0.22, 1.82, 3.0), Vector3(-0.8, 0.91, 0), wood)
		for z in [-1.22, 1.22]:
			_solid(bay, Vector3(0.9, 0.12, 0.12), Vector3(-1.2, 0.06, z), metal)
	elif variant == 1: # Filled fallen rack, individual solid crates match the mesh.
		_solid(bay, Vector3(1.8, 0.12, 3.0), Vector3(-0.8, 0.06, 0), metal)
		for z in [-0.93, 0.0, 0.93]:
			_solid(bay, Vector3(1.65, 1.68, 0.87), Vector3(-0.8, 0.84, z), wood)
	else: # Crate stack / abandoned, broken service equipment.
		_solid(bay, Vector3(1.8, 1.82, 2.8), Vector3(-0.8, 0.91, 0), wood if variant == 2 else metal)
		for z in [-0.9, 0.0, 0.9]:
			runtime._add_box(bay, Vector3(1.82, 0.055, 0.07), Vector3(-0.8, 1.68, z), dark)
	# Small floor-edge props never intrude into either tested lane.
	_solid(bay, Vector3(0.68, 0.7, 1.1), Vector3(-5.35, 0.35, 0.4), wood)
	_solid(bay, Vector3(0.6, 0.92, 1.25), Vector3(4.65, 0.46, -1.1), metal)
	for y in [0.17, 0.75]:
		runtime._add_box(bay, Vector3(0.64, 0.05, 1.3), Vector3(4.65, y, -1.1), dark)
	for z in [-1.62, -0.58]:
		runtime._add_box(bay, Vector3(0.12, 0.14, 0.14), Vector3(4.65, 0.08, z), dark)
	for x in ([-0.91, -0.69] if variant == 0 else [-1.66, 0.06]):
		runtime._add_box(bay, Vector3(0.045, 1.7, 0.045), Vector3(x, 0.88, -1.4), edge)
	var fast := _world_path(bay, [Vector3(0,0,-8), Vector3(1.5,0,-3.5), Vector3(1.5,0,3.5), Vector3(0,0,8)])
	var cover := _world_path(bay, [Vector3(0,0,-8), Vector3(-3.6,0,-4.2), Vector3(-3.6,0,4.2), Vector3(0,0,8)])
	# Avoid diagonal wall clipping at the pocket mouth (narrow original routes).
	fast.insert(1, bay.to_global(Vector3(0,0,-5.0)))
	fast.insert(fast.size()-1, bay.to_global(Vector3(0,0,5.0)))
	cover.insert(1, bay.to_global(Vector3(0,0,-5.0)))
	cover.insert(cover.size()-1, bay.to_global(Vector3(0,0,5.0)))
	crossings.append({"center": bay.position, "lights":link.lights, "node":bay, "fast":fast, "cover":cover, "battery":bay.to_global(Vector3(-2.65,0,0.6))})
	if crossings.size() % 3 == 1:
		runtime._add_box(bay,Vector3(0.60,0.016,1.20),Vector3(1.5,0.008,-1.1),metal)
		noisy_props.append({"position":bay.to_global(Vector3(1.5,0,-1.1)), "cooldown":0.0, "armed":true})
	runtime._merge_service_bay_meshes(bay)
	for child in bay.get_children():
		child.visibility_range_end = 52.0
		child.visibility_range_end_margin = 8.0

func _solid(parent: Node3D, size: Vector3, position: Vector3, material: Material) -> void:
	runtime._add_box(parent, size, position, material)
	var half := parent.global_basis.x.abs() * size.x * 0.5 + parent.global_basis.z.abs() * size.z * 0.5
	runtime.level_manager.solid_areas.append({"center":parent.to_global(position), "half":Vector2(half.x,half.z), "height":position.y + size.y * 0.5, "dark_crossing":true})

func _world_path(bay: Node3D, points: Array) -> Array[Vector3]:
	var result: Array[Vector3] = []
	for point in points:
		result.append(bay.to_global(point))
	return result

func _reseat_wall_dressing(raw: Array) -> void:
	for bay in runtime.get_children():
		if not String(bay.name).begins_with("ServiceBay_"):
			continue
		var outward: Vector3 = -bay.basis.z
		var behind: Vector2i = runtime._world_cell(bay.position + outward * 0.5)
		if not _walkable(raw, behind):
			continue
		var shift := outward * STEP
		var new_wall: Vector3 = bay.position + shift
		for attempt in 4:
			if not _walkable(raw, runtime._world_cell(new_wall + outward * 0.5)):
				break
			shift += outward * STEP
			new_wall = bay.position + shift
		for solid in runtime.level_manager.solid_areas:
			if solid.get("dressing_owner",0) == bay.get_instance_id():
				solid.center += shift
		bay.position = new_wall

func relocate_batteries(pickups: Array) -> void:
	if crossings.is_empty():
		return
	for index in pickups.size():
		var crossing: Dictionary = crossings[mini(crossings.size()-1, floori(float(index) * crossings.size() / pickups.size()))]
		pickups[index].global_position = crossing.battery

func tick(dt: float, player) -> void:
	for prop in noisy_props:
		prop.cooldown = maxf(0.0, prop.cooldown - dt)
		var distance: float = player.global_position.distance_to(prop.position)
		if distance > 2.2:
			prop.armed = true
		if distance < 1.05 and player.horizontal_speed > 1.2 and prop.armed and prop.cooldown <= 0.0:
			prop.armed = false
			prop.cooldown = 12.0
			runtime._make_noise(prop.position, 0.52, 0.8)
			player.add_shake(0.018)
			rattle.global_position = prop.position + Vector3.UP * 0.08
			rattle.play()

func _rattle_sound() -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(3520 * 2)
	for index in 3520:
		var time := float(index) / 16000.0
		var pulse := sin(time * 1273.0) * 0.4 + sin(time * 3187.0) * 0.24 + sin(time * 6911.0) * 0.12
		var value := pulse * exp(-time * 23.0) * minf(1.0,time * 500.0)
		bytes.encode_s16(index*2,int(clampf(value,-1,1)*32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 16000
	stream.data = bytes
	return stream
