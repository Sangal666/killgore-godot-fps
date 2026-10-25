extends SceneTree

const GameData = preload("res://scripts/core/GameData.gd")


func _initialize() -> void:
	var rows: Array = GameData.make_level(GameData.HORROR_SEQUENCE_LEVEL)
	if rows.is_empty():
		_fail("Horror map is empty")
		return
	var spawn := Vector2i(-1, -1)
	var exit_cell := Vector2i(-1, -1)
	var fragments: Array[Vector2i] = []
	for y in rows.size():
		var line := String(rows[y])
		for x in line.length():
			match line.substr(x, 1):
				"P": spawn = Vector2i(x, y)
				"X": exit_cell = Vector2i(x, y)
				"F": fragments.append(Vector2i(x, y))
	if spawn.x < 0 or exit_cell.x < 0 or fragments.size() != 3:
		_fail("Missing spawn, exit, or memory room anchor")
		return
	var distances := _walkable_distances(rows, spawn)
	for index in fragments.size():
		if not distances.has(fragments[index]):
			_fail("Memory room %d is unreachable at %s" % [index + 1, fragments[index]])
			return
		print("MEMORY_%d_DISTANCE=%d" % [index + 1, distances[fragments[index]]])
	if not distances.has(exit_cell):
		_fail("Exit is unreachable at %s" % exit_cell)
		return
	print("EXIT_DISTANCE=%d" % distances[exit_cell])
	print("HORROR_ROUTE_OK")
	quit(0)


func _walkable_distances(rows: Array, start: Vector2i) -> Dictionary:
	var distances := {start: 0}
	var queue: Array[Vector2i] = [start]
	var cursor := 0
	while cursor < queue.size():
		var cell := queue[cursor]
		cursor += 1
		for direction: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next_cell: Vector2i = cell + direction
			if next_cell.y < 0 or next_cell.y >= rows.size():
				continue
			var line := String(rows[next_cell.y])
			if next_cell.x < 0 or next_cell.x >= line.length() or line.substr(next_cell.x, 1) == "#":
				continue
			if distances.has(next_cell):
				continue
			distances[next_cell] = int(distances[cell]) + 1
			queue.append(next_cell)
	return distances


func _fail(reason: String) -> void:
	push_error(reason)
	quit(1)
