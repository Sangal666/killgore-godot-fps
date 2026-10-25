extends RefCounted
class_name GameData

const WeaponDataScript = preload("res://scripts/data/WeaponData.gd")
const EnemyDataScript = preload("res://scripts/data/EnemyData.gd")
const PowerupDataScript = preload("res://scripts/data/PowerupData.gd")
const LevelThemeDataScript = preload("res://scripts/data/LevelThemeData.gd")

const TILE = 4.0
const WEAPON_ORDER = ["whip", "pistol", "shotgun", "auto", "marksman", "seeker", "grenade_launcher", "plasma", "saw", "cryo", "shock_flux", "railgun", "toxic", "flak", "heavy", "incinerator"]
const AMMO_MAX = {"bullets": 340, "shells": 92, "cells": 360, "rockets": 38, "grenades": 18, "blades": 42, "chem": 240}
const COMPACT_INTERLUDE_LEVEL = 7
const TRENCH_MAP_LEVEL = 10
const RAMP_TEST_LEVEL = 11
const CITY_PROTOTYPE_LEVEL = 12
const HORROR_SEQUENCE_LEVEL = 13
const TRENCH_MAP_PATH = "res://assets/maps/map_1_v2.map"

const AMMO_PICKUPS = {
	"b": {"ammo_type": "all", "amount": 1, "name": "Ammo Cache", "color": Color8(222, 190, 82)},
	"s": {"ammo_type": "all", "amount": 1, "name": "Ammo Cache", "color": Color8(222, 190, 82)},
	"c": {"ammo_type": "all", "amount": 1, "name": "Ammo Cache", "color": Color8(222, 190, 82)},
	"r": {"ammo_type": "all", "amount": 1, "name": "Ammo Cache", "color": Color8(222, 190, 82)},
	"g": {"ammo_type": "all", "amount": 1, "name": "Ammo Cache", "color": Color8(222, 190, 82)}
}

const LEVELS = [
	["###############", "#P....M.......#", "#.....b.......#", "#..W.....S....#", "#.....G.......#", "#..Y.....J....#", "#.......K.....#", "#.....D.....X.#", "###############"],
	["###############", "#P....S....G..#", "#..W...b..S...#", "#.....#...R...#", "#..G..#..K....#", "#.....D.......#", "#..Z...E.M.g..#", "#....b....G..X#", "###############"],
	["################", "#P.....A....R..#", "#..J.......F...#", "#..Y...#..b....#", "#..S...#..K..I.#", "#...E..D.......#", "#..M....s..G...#", "#.....g....F..X#", "################"],
	["##################", "#P....#....R.....#", "#..L..#..F....c..#", "#..A..D.....G....#", "#..Z..#..E..Y....#", "#..J.....M.......#", "#...L...#....S...#", "#....K..#..T..g..#", "#...b...D.......X#", "##################"],
	["####################", "#P.....G.......R...#", "#....####D####..c..#", "#..M.#..I....#..F..#", "#....#...N...#..E..#", "#..A.D...V...D..T..#", "#....#...r...#.....#", "#..J.#..S...X#..M..#", "#....#########.....#", "#........g........K#", "####################"],
	["#####################", "#P....G.......R..H..#", "#.....U....F..E..r..#", "#..#######D#######..#", "#..#.....X..Z...#...#", "#..#..M.....c...#...#", "#..#..R..T..U...#...#", "#..D............D...#", "#..#..J.....F...#...#", "#..#######D#######..#", "#..H...A.....g.M...K#", "#####################"],
	["######################", "#P.....G.......F.....#", "#.......L...E..c..R..#", "#..S....#####....A...#", "#.......#...#..Y.....#", "#..G....D.X.D....T...#", "#...b...#...#....r...#", "#..M....#####....M...#", "#....R.....B.....g...#", "#....F..........J...K#", "######################"],
	["########################", "#P.......G.....R......H#", "#..####....c....####...#", "#..#..#...F..E..#.X#...#", "#..#..D.........D..#...#", "#..#..#....K....#..#...#", "#..####..I......####...#", "#....M.....T.....M.....#", "#....r.....B.....b..g..#", "#..A....G.....J....S...#", "########################"],
	["########################", "#P....G......F.....T..L#", "#.....c....E....R......#", "#..#####################", "#..#...........Z.......#", "#..#..B.........B...#..#", "#..D............H....#..#", "#K.#..M....A....M.g.#..#", "#####################D##", "#X...J...R..G.....T..r.#", "########################"],
	["#"],
	["#"],
	["#"],
	["#"],
	["#"],
	["####################################", "#P....M....b.......R......M.....H..#", "#....######......####......######..#", "#..A........L..............r......X#", "#.............T......J.............#", "#..####....########....########....#", "#..#...........E..............#....#", "#..#....G............B........#....#", "#..#..........Q...............#....#", "#..#....M............g........#....#", "#..####....########....########....#", "#.............R......T.............#", "#....######......####......######..#", "#..c........B..............s.......#", "#.........J.......E...........M....#", "#....H.........r.........L.........#", "#K.................................#", "####################################"]
]

static func is_trench_map_level(index: int) -> bool:
	return index == TRENCH_MAP_LEVEL

static func is_ramp_test_level(index: int) -> bool:
	return index == RAMP_TEST_LEVEL

static func is_city_prototype_level(index: int) -> bool:
	return index == CITY_PROTOTYPE_LEVEL

static func is_horror_sequence_level(index: int) -> bool:
	return index == HORROR_SEQUENCE_LEVEL

static func make_level(index: int) -> Array:
	if index <= 0:
		return LEVELS[0]
	if index == COMPACT_INTERLUDE_LEVEL:
		return _make_compact_interlude_level()
	if is_city_prototype_level(index):
		return _make_city_prototype_level()
	if is_horror_sequence_level(index):
		return _make_horror_sequence_level()
	if is_trench_map_level(index) or is_ramp_test_level(index):
		return LEVELS[index]
	if index >= LEVELS.size() - 1:
		return _make_boss_level()
	return _make_open_level(index - 2 if index > COMPACT_INTERLUDE_LEVEL else index - 1)

static func _make_horror_sequence_level() -> Array:
	# This map is intentionally authored from an empty grid. The kitchen is the
	# scale reference: four-metre service corridors, compact turns, long sightline
	# breaks, and no arena-sized spaces. Later memory rooms keep small reserved
	# footprints, but their final themed geometry is deliberately deferred.
	const WIDTH = 49
	const HEIGHT = 145
	var cells: Array = []
	for y in HEIGHT:
		var row: Array = []
		for x in WIDTH:
			row.append("#")
		cells.append(row)

	# The opening act deliberately returns to the original broad service-corridor
	# scale. It carries the player to the kitchen junction before the architecture
	# compresses into the retained narrow kitchen approach.
	_horror_carve_path(cells, [
		Vector2i(42, 138), Vector2i(42, 128), Vector2i(30, 128),
		Vector2i(30, 118), Vector2i(10, 118)
	], 1)
	# This is a native reservation for the kitchen architecture, not a corridor
	# drawn through an older room. The whole three-cell-wide approach and room
	# envelope are empty in the base grid; the authored kitchen builds inside it
	# with its own visible walls and ordinary structural collision.
	_horror_carve_path(cells, [Vector2i(10, 118), Vector2i(10, 110)], 1)
	_horror_carve_rect(cells, Rect2i(9, 109, 3, 3))
	_horror_carve_path(cells, [
		Vector2i(10, 110), Vector2i(34, 110), Vector2i(34, 98),
		Vector2i(18, 98), Vector2i(18, 87), Vector2i(40, 87),
		Vector2i(40, 72), Vector2i(38, 72)
	], 0)
	# Long second and third acts reserve only compact neutral rooms. Their final
	# roadside/checkpoint designs will be authored later without changing this
	# restrained circulation scale.
	_horror_carve_rect(cells, Rect2i(37, 71, 3, 3))
	_horror_carve_path(cells, [
		Vector2i(38, 72), Vector2i(25, 72), Vector2i(25, 61),
		Vector2i(8, 61), Vector2i(8, 48), Vector2i(30, 48),
		Vector2i(30, 36), Vector2i(12, 36), Vector2i(12, 26)
	], 0)
	_horror_carve_rect(cells, Rect2i(11, 25, 3, 3))
	_horror_carve_path(cells, [
		Vector2i(12, 26), Vector2i(38, 26), Vector2i(38, 12),
		Vector2i(45, 12), Vector2i(45, 5)
	], 0)

	# Small reconnecting maintenance loops support hunt/search behaviour without
	# changing the corridor language or creating giant rooms.
	_horror_carve_path(cells, [Vector2i(30, 128), Vector2i(18, 128), Vector2i(18, 121), Vector2i(30, 121)], 0)
	_horror_carve_path(cells, [Vector2i(34, 98), Vector2i(43, 98), Vector2i(43, 91), Vector2i(34, 91)], 0)
	_horror_carve_path(cells, [Vector2i(25, 61), Vector2i(39, 61), Vector2i(39, 55), Vector2i(25, 55)], 0)
	_horror_carve_path(cells, [Vector2i(30, 36), Vector2i(42, 36), Vector2i(42, 30), Vector2i(30, 30)], 0)
	# A few two-to-four-cell dead ends create hiding/search decisions and keep the
	# long route from feeling like a single tube.
	_horror_carve_path(cells, [Vector2i(36, 110), Vector2i(36, 115)], 0)
	_horror_carve_path(cells, [Vector2i(18, 87), Vector2i(12, 87)], 0)
	_horror_carve_path(cells, [Vector2i(8, 48), Vector2i(4, 48)], 0)
	_horror_carve_path(cells, [Vector2i(38, 26), Vector2i(45, 26)], 0)

	cells[138][42] = "P"
	cells[110][10] = "F"
	cells[72][38] = "F"
	cells[26][12] = "F"
	cells[5][45] = "X"
	var rows: Array = []
	for y in HEIGHT:
		rows.append("".join(cells[y]))
	return rows

static func _horror_carve_rect(cells: Array, rect: Rect2i) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if y > 0 and y < cells.size() - 1 and x > 0 and x < cells[y].size() - 1:
				cells[y][x] = "."

static func _horror_carve_h(cells: Array, from_x: int, to_x: int, y: int, half_width: int) -> void:
	for x in range(min(from_x, to_x), max(from_x, to_x) + 1):
		for offset in range(-half_width, half_width + 1):
			cells[y + offset][x] = "."

static func _horror_carve_v(cells: Array, x: int, from_y: int, to_y: int, half_width: int) -> void:
	for y in range(min(from_y, to_y), max(from_y, to_y) + 1):
		for offset in range(-half_width, half_width + 1):
			cells[y][x + offset] = "."

static func _horror_carve_path(cells: Array, points: Array, half_width: int) -> void:
	for index in range(points.size() - 1):
		var from: Vector2i = points[index]
		var to: Vector2i = points[index + 1]
		if from.y == to.y:
			_horror_carve_h(cells, from.x, to.x, from.y, half_width)
		elif from.x == to.x:
			_horror_carve_v(cells, from.x, from.y, to.y, half_width)

static func _make_open_level(index: int) -> Array:
	var w = 38 + index * 5
	var h = 24 + index * 3
	var rows = []
	for y in range(h):
		var line = ""
		for x in range(w):
			line += "#" if x == 0 or y == 0 or x == w - 1 or y == h - 1 else "."
		rows.append(line)
	var mid = floori(float(h) / 2.0)
	_set_char(rows, 2, mid, "P")
	_build_exit_room(rows, w, h)
	_set_char(rows, int(w * 0.70), 4 if index % 2 == 0 else h - 5, "K")
	_place_weapon_progression(rows, index, w, h)
	_place_supplies(rows, index, w, h)
	_place_open_arena_enemies(rows, index, w, h)
	_place_short_cover(rows, index, w, h)
	_place_level_signature(rows, index, w, h)
	return rows

static func _make_compact_interlude_level() -> Array:
	return [
		"###########################",
		"#P...M..C.A....R.....1....#",
		"#..G..F..###..1..c..E..R..#",
		"#..J.....#.#.....E.....4..#",
		"#....b...0...g......3.....#",
		"#..T..2..#.#..4..L.....F..#",
		"#..S..2..###.....M..J.....#",
		"#.....3.....K..####D####..#",
		"#..R.....M.....#...X....#.#",
		"#..............##########.#",
		"###########################"
	]

static func _make_city_prototype_level() -> Array:
	var width = 41
	var height = 29
	var rows: Array = []
	for y in range(height):
		var line = ""
		for x in range(width):
			line += "#" if x == 0 or y == 0 or x == width - 1 or y == height - 1 else "."
		rows.append(line)
	# Broad city blocks leave a central avenue and two cross streets open.
	for rect in [
		Rect2i(5, 3, 8, 7), Rect2i(18, 3, 8, 6), Rect2i(31, 3, 6, 8),
		Rect2i(5, 19, 9, 6), Rect2i(20, 20, 8, 5), Rect2i(33, 18, 4, 7)
	]:
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				_set_char(rows, x, y, "#")
	_set_char(rows, 2, 14, "P")
	_set_char(rows, width - 3, 14, "X")
	return rows

static func _make_boss_level() -> Array:
	var w = 56
	var h = 36
	var rows = []
	for y in range(h):
		var line = ""
		for x in range(w):
			line += "#" if x == 0 or y == 0 or x == w - 1 or y == h - 1 else "."
		rows.append(line)
	var mid = floori(float(h) / 2.0)
	_set_char(rows, 3, mid, "P")
	_set_char(rows, int(w * 0.52), mid, "Q")
	_set_char(rows, int(w * 0.42), mid - 6, "7")
	_set_char(rows, int(w * 0.62), mid + 6, "9")
	_set_char(rows, w - 5, mid, "X")
	_set_char(rows, 6, mid - 5, "M")
	_set_char(rows, 6, mid + 5, "b")
	_set_char(rows, w - 8, mid - 7, "M")
	_set_char(rows, w - 8, mid + 7, "b")
	for p in [Vector2i(14, 8), Vector2i(22, 27), Vector2i(34, 7), Vector2i(43, 28), Vector2i(27, 18)]:
		_set_char(rows, p.x, p.y, ["R", "E", "1", "2", "4"][p.x % 5])
	for p in [Vector2i(18, 13), Vector2i(38, 22), Vector2i(44, 12), Vector2i(12, 24)]:
		_set_char(rows, p.x, p.y, "T")
	return rows

static func _build_exit_room(rows: Array, w: int, h: int) -> void:
	var cy = floori(float(h) / 2.0)
	var left = w - 8
	var right = w - 2
	var top = max(2, cy - 3)
	var bottom = min(h - 2, cy + 3)
	for y in range(top, bottom + 1):
		for x in range(left, right + 1):
			var edge = x == left or x == right or y == top or y == bottom
			_set_char(rows, x, y, "#" if edge else ".")
	_set_char(rows, left, cy, "D")
	_set_char(rows, right - 2, cy, "X")
	_set_char(rows, left - 2, cy - 2, "4")
	_set_char(rows, left - 3, cy + 2, "R")

static func _place_weapon_progression(rows: Array, index: int, w: int, h: int) -> void:
	var mid = floori(float(h) / 2.0)
	var placements = [
		{"char": "S", "level": 0, "x": 7, "y": mid - 3},
		{"char": "A", "level": 1, "x": 12, "y": mid + 4},
		{"char": "C", "level": 2, "x": int(w * 0.34), "y": 5},
			{"char": "h", "level": 3, "x": int(w * 0.48), "y": h - 6},
			{"char": "L", "level": 4, "x": int(w * 0.56), "y": 5},
			{"char": "o", "level": 5, "x": int(w * 0.62), "y": mid + 6},
			{"char": "p", "level": 5, "x": int(w * 0.42), "y": h - 6},
			{"char": "m", "level": 4, "x": int(w * 0.70), "y": mid - 6},
			{"char": "k", "level": 6, "x": int(w * 0.76), "y": 6},
			{"char": "N", "level": 7, "x": int(w * 0.54), "y": h - 7},
			{"char": "u", "level": 7, "x": int(w * 0.78), "y": h - 7},
			{"char": "v", "level": 8, "x": int(w * 0.46), "y": 6},
			{"char": "H", "level": 8, "x": int(w * 0.62), "y": h - 7},
			{"char": "U", "level": 8, "x": int(w * 0.82), "y": h - 7}
	]
	for item in placements:
		if index >= item.level:
			_set_char(rows, int(item.x), int(item.y), String(item.char))
	_set_char(rows, 5, mid + 2, "W")
	var extras = ["S", "A", "C", "h", "L", "o", "p", "m", "k", "N", "u", "v", "H", "U"]
	for i in range(min(extras.size(), 2 + floori(float(index) / 2.0))):
		var x = 9 + posmod(i * 13 + index * 7, max(12, w - 20))
		var y = 4 + posmod(i * 11 + index * 5, max(8, h - 8))
		_set_char(rows, x, y, extras[posmod(i + index, extras.size())])

static func _place_supplies(rows: Array, index: int, w: int, h: int) -> void:
	var points = [
		Vector2i(8, 4),
		Vector2i(10, h - 5),
		Vector2i(int(w * 0.30), int(h * 0.72)),
		Vector2i(int(w * 0.46), 5),
		Vector2i(int(w * 0.58), h - 6),
		Vector2i(w - 11, int(h * 0.28)),
		Vector2i(int(w * 0.22), int(h * 0.42)),
		Vector2i(int(w * 0.72), int(h * 0.72)),
		Vector2i(int(w * 0.82), int(h * 0.18))
	]
	var chars = ["b", "M", "Y", "c", "I", "g", "M", "b", "r"]
	for i in range(points.size()):
		_set_char(rows, points[i].x, points[i].y, chars[(i + index) % chars.size()])
	if index >= 3:
		_set_char(rows, int(w * 0.42), int(h * 0.50), "Z")

static func _place_open_arena_enemies(rows: Array, index: int, w: int, h: int) -> void:
	var roster = ["G", "F", "R", "J", "E", "1", "3", "4", "2", "B", "T", "5"]
	var count = 13 + index * 4
	for i in range(count):
		var x = 7 + posmod(i * 9 + index * 5, max(8, w - 15))
		var y = 4 + posmod(i * 7 + index * 3, max(6, h - 8))
		if x > w - 10 and abs(y - floori(float(h) / 2.0)) < 5:
			x -= 8
		var id = roster[posmod(i + index * 2, min(roster.size(), 6 + index))]
		_set_char(rows, x, y, id)
	if index >= 5:
		_set_char(rows, int(w * 0.50), 3, "5")

static func _place_short_cover(rows: Array, index: int, w: int, h: int) -> void:
	var count = 5 + index
	for i in range(count):
		var x = 9 + posmod(i * 11 + index * 3, max(10, w - 18))
		var y = 5 + posmod(i * 13 + index * 4, max(8, h - 10))
		var horizontal = i % 2 == 0
		var length = 2 + posmod(i + index, 2)
		for j in range(length):
			var px = x + (j if horizontal else 0)
			var py = y + (0 if horizontal else j)
			if px > 3 and py > 2 and px < w - 10 and py < h - 2:
				_set_char(rows, px, py, "#")

static func _place_level_signature(rows: Array, index: int, w: int, h: int) -> void:
	var mid = floori(float(h) / 2.0)
	match index:
		0:
			for p in [Vector2i(int(w * 0.42), mid - 5), Vector2i(int(w * 0.52), mid + 5)]:
				_set_char(rows, p.x, p.y, "G")
			_set_char(rows, int(w * 0.56), mid, "Y")
		1:
			for p in [Vector2i(int(w * 0.38), 4), Vector2i(int(w * 0.58), h - 5), Vector2i(int(w * 0.72), mid)]:
				_set_char(rows, p.x, p.y, "1")
			_set_char(rows, int(w * 0.48), mid - 4, "A")
		2:
			for p in [Vector2i(int(w * 0.32), 5), Vector2i(int(w * 0.48), mid + 7), Vector2i(int(w * 0.68), 6)]:
				_set_char(rows, p.x, p.y, "3")
			_set_char(rows, int(w * 0.55), h - 7, "L")
		3:
			for p in [Vector2i(int(w * 0.36), mid - 6), Vector2i(int(w * 0.56), mid + 6), Vector2i(int(w * 0.78), mid - 4)]:
				_set_char(rows, p.x, p.y, "4")
			_set_char(rows, int(w * 0.46), 5, "N")
		4:
			for p in [Vector2i(int(w * 0.30), h - 6), Vector2i(int(w * 0.52), mid - 7), Vector2i(int(w * 0.72), mid + 7)]:
				_set_char(rows, p.x, p.y, "2")
			_set_char(rows, int(w * 0.60), mid, "I")
		5:
			for p in [Vector2i(int(w * 0.28), mid), Vector2i(int(w * 0.48), 5), Vector2i(int(w * 0.76), h - 6)]:
				_set_char(rows, p.x, p.y, "J")
			_set_char(rows, int(w * 0.66), 6, "H")
		6:
			for p in [Vector2i(int(w * 0.34), 4), Vector2i(int(w * 0.55), mid), Vector2i(int(w * 0.80), h - 5)]:
				_set_char(rows, p.x, p.y, "5")
			_set_char(rows, int(w * 0.42), h - 7, "U")
		_:
			for p in [Vector2i(int(w * 0.28), mid - 7), Vector2i(int(w * 0.50), 5), Vector2i(int(w * 0.70), h - 6), Vector2i(int(w * 0.82), mid + 5)]:
				_set_char(rows, p.x, p.y, ["B", "2", "5", "4"][p.x % 4])
			_set_char(rows, int(w * 0.58), mid + 2, "Z")
	if index >= 3:
		var mini_ids = ["6", "7", "8", "9"]
		var mini_id = mini_ids[(index - 3) % mini_ids.size()]
		var mx = int(w * (0.42 + 0.08 * float(index % 3)))
		var my = int(h * (0.30 + 0.12 * float((index + 1) % 3)))
		_set_char(rows, mx, my, mini_id)
		if index >= 6:
			_set_char(rows, int(w * 0.66), int(h * 0.58), mini_ids[(index - 2) % mini_ids.size()])

static func _set_char(rows: Array, x: int, y: int, ch: String) -> void:
	if y < 0 or y >= rows.size():
		return
	var line = String(rows[y])
	if x < 0 or x >= line.length():
		return
	rows[y] = line.substr(0, x) + ch + line.substr(x + 1)

static func make_weapon_data() -> Dictionary:
	var out = {}
	out.whip = _weapon("whip", "HELL WHIP", 5, 0.54, 0.0, 1, "", 0, 0.0, 0, true, 6.15, false, 0.0, Color8(224, 86, 48), 0.0)
	out.pistol = _weapon("pistol", "REVOLVER", 3, 0.34, 1.25, 1, "bullets", 8, 0.88, 24, false, 0.0, false, 0.0, Color8(82, 84, 96), 0.0)
	out.shotgun = _weapon("shotgun", "SHOTGUN", 1, 0.68, 9.0, 7, "shells", 8, 1.10, 12, false, 0.0, false, 0.0, Color8(116, 68, 38), 0.0)
	out.auto = _weapon("auto", "AUTO RIFLE", 1, 0.050, 3.2, 1, "bullets", 120, 1.35, 150, false, 0.0, false, 0.0, Color8(48, 118, 84), 0.0)
	out.marksman = _weapon("marksman", "M1A RIFLE", 10, 0.30, 0.65, 1, "bullets", 20, 1.05, 48, false, 0.0, false, 0.0, Color8(166, 116, 72), 0.0)
	out.seeker = _weapon("seeker", "SEEKER RIFLE", 2, 0.10, 1.65, 1, "bullets", 48, 1.45, 72, false, 0.0, false, 0.0, Color8(72, 214, 150), 28.0)
	out.grenade_launcher = _weapon("grenade_launcher", "GRENADE LAUNCHER", 8, 0.34, 1.1, 1, "rockets", 6, 1.42, 5, false, 0.0, true, 4.75, Color8(255, 188, 74), 17.0)
	out.plasma = _weapon("plasma", "PLASMA GUN", 2, 0.16, 1.2, 1, "cells", 36, 1.35, 48, false, 0.0, false, 0.0, Color8(64, 178, 238), 18.0)
	out.saw = _weapon("saw", "SAW LAUNCHER", 5, 0.32, 1.1, 1, "blades", 10, 1.20, 8, false, 0.0, false, 0.0, Color8(210, 212, 198), 25.0)
	out.cryo = _weapon("cryo", "CRYO GUN", 2, 0.18, 1.0, 1, "cells", 32, 1.24, 44, false, 0.0, false, 0.0, Color8(118, 226, 255), 19.0)
	out.shock_flux = _weapon("shock_flux", "SHOCK FLUX", 1, 0.055, 0.38, 1, "cells", 90, 1.35, 90, false, 0.0, false, 0.0, Color8(176, 116, 255), 0.0)
	out.toxic = _weapon("toxic", "TOXIC CHEM", 2, 0.075, 2.6, 1, "chem", 70, 1.40, 88, false, 0.0, false, 0.0, Color8(128, 255, 82), 13.5)
	out.flak = _weapon("flak", "FLAK CANNON", 3, 0.18, 1.6, 1, "shells", 24, 1.18, 30, false, 0.0, false, 0.0, Color8(255, 132, 82), 0.0)
	out.heavy = _weapon("heavy", "HEAVY CANNON", 10, 1.0, 0.7, 1, "rockets", 5, 1.75, 4, false, 0.0, true, 6.1, Color8(126, 126, 138), 21.5)
	out.railgun = _weapon("railgun", "RAIL LANCE", 7, 0.58, 0.0, 1, "cells", 8, 1.55, 24, false, 0.0, false, 0.0, Color8(120, 238, 255), 0.0)
	out.incinerator = _weapon("incinerator", "INCINERATOR", 1, 0.055, 5.5, 1, "cells", 96, 1.65, 112, false, 0.0, false, 0.0, Color8(255, 116, 42), 9.2)
	return out

static func make_enemy_data() -> Dictionary:
	var out = {}
	out.G = _enemy("G", "Grunt", 5, 3.05, 8, 1.55, 0.36, false, 7.0, 8.0, 1, 0.0, false, 0.0, 0.0, 0.0, 1.65, 1.0, false, Color8(184, 58, 48), Color8(245, 225, 92), "grunt", false, true)
	out.F = _enemy("F", "Climber", 6, 4.45, 10, 1.55, 0.36, false, 7.0, 8.0, 1, 0.0, false, 0.0, 0.0, 0.0, 1.70, 0.78, false, Color8(218, 132, 52), Color8(255, 230, 112), "climber", false, true)
	out.T = _enemy("T", "Tank", 13, 2.08, 18, 1.8, 0.56, false, 7.0, 8.0, 1, 0.0, false, 0.0, 0.0, 0.0, 1.72, 1.45, false, Color8(128, 82, 188), Color8(232, 132, 255), "tank", false, true)
	out.B = _enemy("B", "Brute", 15, 2.55, 24, 1.9, 0.68, false, 7.0, 8.0, 1, 0.0, false, 0.0, 0.0, 0.0, 2.15, 1.28, false, Color8(72, 166, 92), Color8(188, 255, 175), "brute", false, true)
	out.R = _enemy("R", "Ranged", 6, 2.55, 11, 14.0, 0.88, true, 8.5, 10.3, 1, 0.0, false, 0.0, 0.0, 0.0, 1.95, 0.72, false, Color8(52, 136, 210), Color8(120, 232, 255), "ranged", false, true)
	out.E = _enemy("E", "Wraith", 7, 3.55, 10, 13.5, 0.76, true, 6.8, 11.6, 1, 0.0, false, 0.0, 0.0, 0.0, 1.45, 0.68, false, Color8(96, 190, 214), Color8(190, 255, 246), "flyer", true)
	out.J = _enemy("J", "Jumper", 7, 4.85, 14, 1.7, 0.38, false, 7.0, 8.0, 1, 0.0, true, 0.58, 0.42, 3.20, 1.75, 0.76, false, Color8(214, 142, 72), Color8(255, 242, 130), "jumper", false, true)
	out["1"] = _enemy("1", "Skyrazor", 5, 5.10, 9, 11.8, 0.58, true, 6.0, 13.8, 1, 0.0, false, 0.0, 0.0, 0.0, 1.18, 0.56, false, Color8(178, 78, 224), Color8(255, 122, 244), "skyrazor", true)
	out["2"] = _enemy("2", "Bombard Wraith", 9, 2.88, 12, 15.8, 1.52, true, 9.8, 8.6, 2, 0.18, false, 0.0, 0.0, 0.0, 1.62, 0.86, false, Color8(92, 116, 226), Color8(128, 232, 255), "bomber", true)
	out["3"] = _enemy("3", "Wall Stalker", 7, 5.45, 13, 1.70, 0.34, false, 7.0, 8.0, 1, 0.0, true, 0.58, 0.38, 2.75, 1.55, 0.62, false, Color8(176, 204, 74), Color8(234, 255, 112), "wallstalker", false, true)
	out["4"] = _enemy("4", "Hex Caster", 7, 2.70, 9, 16.0, 1.06, true, 10.5, 9.2, 3, 0.11, false, 0.0, 0.0, 0.0, 1.82, 0.66, false, Color8(74, 92, 198), Color8(204, 112, 255), "caster", false, true)
	out["5"] = _enemy("5", "Apex Seer", 8, 2.95, 16, 24.0, 1.42, true, 17.0, 17.5, 1, 0.0, false, 0.0, 0.0, 0.0, 1.70, 0.72, false, Color8(210, 222, 238), Color8(110, 255, 238), "apex", true)
	out["6"] = _enemy("6", "Iron Harbinger", 78, 3.85, 18, 18.0, 0.82, true, 8.8, 10.8, 1, 0.0, false, 0.0, 0.0, 0.0, 2.28, 1.62, false, Color8(138, 86, 92), Color8(255, 194, 82), "minitank", false, true)
	out["7"] = _enemy("7", "Storm Bishop", 58, 4.10, 15, 19.0, 0.74, true, 11.5, 16.0, 3, 0.13, false, 0.0, 0.0, 0.0, 2.12, 0.92, false, Color8(86, 106, 218), Color8(118, 244, 255), "minicaster", false, true)
	out["8"] = _enemy("8", "Void Talon", 54, 6.80, 14, 22.0, 0.44, true, 15.0, 21.4, 2, 0.11, true, 0.54, 0.34, 3.45, 1.82, 0.88, false, Color8(170, 76, 216), Color8(255, 126, 236), "miniflyer", true)
	out["9"] = _enemy("9", "Cinder Comet", 64, 6.40, 17, 20.5, 0.62, true, 13.0, 14.2, 2, 0.09, true, 0.58, 0.36, 3.80, 1.95, 1.04, false, Color8(218, 92, 46), Color8(255, 210, 82), "minibomber", true)
	out["0"] = _enemy("0", "Brood Widow", 148, 6.60, 12, 20.5, 0.56, true, 11.5, 16.8, 2, 0.10, true, 0.42, 0.34, 3.45, 1.72, 1.42, false, Color8(44, 44, 58), Color8(190, 248, 255), "spider", false, true)
	out.EX = _enemy("EX", "Contact Mine", 4, 6.25, 0, 0.0, 0.18, false, 6.0, 8.0, 1, 0.0, false, 0.0, 0.0, 0.0, 1.25, 0.72, false, Color8(198, 82, 34), Color8(255, 194, 70), "mine", false, false)
	out.DRONE = _enemy("DRONE", "Drift Drone", 190, 6.60, 10, 22.0, 0.50, true, 18.0, 18.0, 1, 0.04, false, 0.0, 0.0, 0.0, 1.55, 1.15, false, Color8(72, 84, 92), Color8(255, 186, 72), "apex", true, false)
	out.Q = _enemy("Q", "Algore", 680, 3.85, 30, 25.5, 0.38, true, 13.0, 19.4, 6, 0.18, true, 0.46, 0.40, 4.05, 4.85, 3.10, true, Color8(178, 42, 54), Color8(255, 220, 80), "boss")
	return out

static func make_powerup_data() -> Dictionary:
	var out = {}
	out.berserk = _power("berserk", "Berserk", 24.0, Color8(245, 55, 55), 1.0, 1.0, 5.0, 1.0)
	out.haste = _power("haste", "Haste", 18.0, Color8(95, 210, 255), 1.32, 0.62, 1.0, 1.0)
	out.shield = _power("shield", "Shield", 18.0, Color8(120, 245, 160), 1.0, 1.0, 1.0, 0.48)
	return out

static func make_themes() -> Array:
	return [
		_theme("training", "Calibration Annex", "rivet", Color8(94, 99, 96), Color8(139, 139, 126), Color8(36, 40, 40), Color8(67, 70, 68), Color8(42, 45, 45), Color8(72, 76, 75), Color8(30, 34, 35), Color8(83, 174, 168)),
		_theme("brick", "Abandoned Civic Block", "plate", Color8(71, 69, 64), Color8(119, 111, 95), Color8(30, 30, 29), Color8(63, 61, 56), Color8(39, 39, 37), Color8(72, 69, 62), Color8(27, 28, 28), Color8(191, 139, 55)),
		_theme("tealtech", "Dormant Systems Wing", "rivet", Color8(60, 72, 71), Color8(104, 116, 109), Color8(25, 33, 34), Color8(49, 57, 56), Color8(31, 38, 39), Color8(56, 64, 63), Color8(22, 27, 28), Color8(67, 150, 145)),
		_theme("sandstone", "Sunken Administration", "cracked", Color8(112, 105, 89), Color8(154, 143, 116), Color8(54, 51, 44), Color8(87, 81, 68), Color8(54, 51, 45), Color8(91, 86, 75), Color8(40, 39, 37), Color8(188, 137, 62)),
		_theme("temple", "Failed Monument", "obsidian", Color8(55, 54, 52), Color8(99, 91, 78), Color8(24, 24, 24), Color8(47, 45, 42), Color8(29, 29, 28), Color8(56, 52, 47), Color8(20, 21, 21), Color8(167, 62, 43)),
		_theme("toxic", "Contaminated Maintenance", "hazard", Color8(68, 74, 65), Color8(111, 117, 91), Color8(30, 35, 30), Color8(53, 59, 51), Color8(34, 40, 35), Color8(61, 65, 56), Color8(24, 29, 27), Color8(101, 157, 91)),
		_theme("decay", "Abandoned Systems", "plate", Color8(56, 58, 56), Color8(86, 86, 78), Color8(24, 26, 26), Color8(48, 50, 48), Color8(30, 32, 32), Color8(64, 62, 54), Color8(18, 20, 20), Color8(92, 168, 162)),
		_theme("bluebunker", "Flooded Data Bunker", "plate", Color8(59, 68, 75), Color8(96, 108, 113), Color8(27, 34, 40), Color8(47, 55, 61), Color8(30, 37, 43), Color8(54, 62, 68), Color8(22, 27, 32), Color8(75, 145, 153)),
		_theme("organic", "Corrupted Memory Ward", "cracked", Color8(72, 63, 62), Color8(119, 101, 94), Color8(33, 29, 29), Color8(57, 50, 49), Color8(37, 33, 34), Color8(65, 57, 55), Color8(25, 24, 25), Color8(151, 58, 48)),
		_theme("city", "Brutalist City Prototype", "plate", Color8(49, 51, 50), Color8(91, 88, 80), Color8(18, 20, 20), Color8(43, 45, 44), Color8(57, 55, 49), Color8(31, 33, 33), Color8(45, 45, 41), Color8(172, 126, 49)),
		_theme("horror", "Mnemonic Service Labyrinth", "plate", Color8(31, 32, 31), Color8(58, 57, 52), Color8(8, 9, 9), Color8(27, 28, 27), Color8(18, 19, 19), Color8(34, 33, 30), Color8(6, 7, 7), Color8(145, 160, 137)),
		_theme("boss", "Creator Core", "obsidian", Color8(49, 46, 43), Color8(94, 82, 67), Color8(20, 19, 19), Color8(43, 40, 37), Color8(26, 25, 25), Color8(49, 45, 41), Color8(16, 16, 17), Color8(183, 123, 45))
	]

static func _weapon(id, display_name, damage, cooldown, spread, shots, ammo, mag, reload, pickup, melee, melee_range, explosive, radius, color, projectile_speed):
	var w = WeaponDataScript.new()
	w.id = id
	w.display_name = display_name
	w.damage = damage
	w.cooldown = cooldown
	w.spread_degrees = spread
	w.shots = shots
	w.ammo_type = ammo
	w.mag_size = mag
	w.reload_time = reload
	w.pickup_ammo = pickup
	w.melee = melee
	w.melee_range = melee_range
	w.explosive = explosive
	w.explosion_radius = radius
	w.color = color
	w.projectile_speed = projectile_speed
	return w

static func _enemy(id, display_name, hp, speed, damage, attack_range, cooldown, ranged, ideal_range, projectile_speed, projectile_count, projectile_spread, jumping, jump_cooldown, jump_duration, jump_height, height, width, boss, color, accent, sprite_key, flying = false, climbing = false):
	var e = EnemyDataScript.new()
	e.id = id
	e.display_name = display_name
	e.hp = hp
	e.speed = speed
	e.damage = damage
	e.attack_range = attack_range
	e.cooldown = cooldown
	e.ranged = ranged
	e.ideal_range = ideal_range
	e.projectile_speed = projectile_speed
	e.projectile_count = projectile_count
	e.projectile_spread = projectile_spread
	e.jumping = jumping
	e.jump_cooldown = jump_cooldown
	e.jump_duration = jump_duration
	e.jump_height = jump_height
	e.height = height
	e.width = width
	e.boss = boss
	e.color = color
	e.accent = accent
	e.sprite_key = sprite_key
	e.flying = flying
	e.climbing = climbing
	return e

static func _power(id, display_name, duration, color, speed, dash, damage, shield):
	var p = PowerupDataScript.new()
	p.id = id
	p.display_name = display_name
	p.duration = duration
	p.color = color
	p.speed_multiplier = speed
	p.dash_multiplier = dash
	p.damage_multiplier = damage
	p.shield_multiplier = shield
	return p

static func _theme(id, display_name, pattern, wall_a, wall_b, line, floor_a, floor_b, ceiling_a, ceiling_b, glow):
	var t = LevelThemeDataScript.new()
	t.id = id
	t.display_name = display_name
	t.pattern = pattern
	t.wall_a = wall_a
	t.wall_b = wall_b
	t.line = line
	t.floor_a = floor_a
	t.floor_b = floor_b
	t.ceiling_a = ceiling_a
	t.ceiling_b = ceiling_b
	t.glow = glow
	return t
