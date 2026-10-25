extends RefCounted
class_name AssetFactory

var texture_cache = {}
var material_cache = {}
var glow_material_cache := {}

const MAX_GLOW_MATERIAL_CACHE = 384

const EXTERNAL_THEME_TEXTURES = {}

func make_world_material(theme, surface: String) -> StandardMaterial3D:
	var key = "%s_%s" % [theme.id, surface]
	if material_cache.has(key):
		return material_cache[key]
	if EXTERNAL_THEME_TEXTURES.has(theme.id) and EXTERNAL_THEME_TEXTURES[theme.id].has(surface):
		var external = _make_external_world_material(theme, surface, EXTERNAL_THEME_TEXTURES[theme.id][surface])
		material_cache[key] = external
		return external
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	_fill_pattern(img, theme, surface)
	var tex = ImageTexture.create_from_image(img)
	var mat = StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.roughness = 0.86
	mat.metallic = 0.05 if theme.pattern in ["rivet", "plate", "hazard"] else 0.0
	material_cache[key] = mat
	return mat

func _make_external_world_material(theme, surface: String, path: String) -> StandardMaterial3D:
	var tex = ResourceLoader.load(path)
	if not tex is Texture2D:
		var img = Image.new()
		if img.load(path) != OK:
			img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
			_fill_pattern(img, theme, surface)
		tex = ImageTexture.create_from_image(img)
	if tex == null:
		var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
		_fill_pattern(img, theme, surface)
		tex = ImageTexture.create_from_image(img)
	var mat = StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mat.set("texture_repeat", 1)
	mat.roughness = 0.78
	mat.metallic = 0.10 if surface != "floor" else 0.04
	if surface == "floor":
		mat.uv1_scale = Vector3(18.0, 18.0, 1.0)
	elif surface == "ceiling":
		mat.uv1_scale = Vector3(14.0, 14.0, 1.0)
	else:
		mat.uv1_scale = Vector3(1.0, 1.0, 1.0)
	return mat

func make_glow_material(color: Color, alpha: float) -> StandardMaterial3D:
	# Short-lived combat VFX repeatedly request the same palette. Sharing these
	# immutable glow materials avoids allocating and uploading an identical GPU
	# resource for every spark, tracer, smoke puff and blood drop.
	var key := "%08x:%d" % [color.to_rgba32(), int(round(alpha * 1000.0))]
	if glow_material_cache.has(key):
		return glow_material_cache[key]
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, alpha)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.25
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if glow_material_cache.size() < MAX_GLOW_MATERIAL_CACHE:
		glow_material_cache[key] = mat
	return mat

func make_flat_material(color: Color) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	return mat

func make_enemy_material(id: String, color: Color, accent: Color, dark := false) -> StandardMaterial3D:
	var key = "enemy_%s_%s_%s_%s" % [id, color.to_html(false), accent.to_html(false), str(dark)]
	if material_cache.has(key):
		return material_cache[key]
	var img = Image.create(48, 48, false, Image.FORMAT_RGBA8)
	var base = color.darkened(0.28) if dark else color
	var line = color.darkened(0.58)
	for y in 48:
		for x in 48:
			var n = int((x * 17 + y * 29 + (x ^ y) * 5) % 23)
			var shade = 0.18 if n > 14 else 0.0
			img.set_pixel(x, y, base.lerp(base.lightened(0.28), shade))
	match id:
		"grunt":
			for y in range(7, 48, 10):
				_line(img, 0, y, 48, y + 4, line)
		"climber":
			for x in range(6, 48, 9):
				_line(img, x, 0, x - 6, 48, accent.darkened(0.25))
		"tank":
			for x in range(0, 48, 12):
				_rect(img, x, 0, 2, 48, line)
			for y in range(0, 48, 12):
				_rect(img, 0, y, 48, 2, line)
		"brute":
			for i in 8:
				_circle(img, 5 + i * 6, 12 + int(sin(i) * 10), 2, accent.darkened(0.15))
		"ranged":
			for i in 5:
				_circle(img, 8 + i * 8, 24, 3, accent)
		"flyer":
			for y in range(4, 48, 8):
				_line(img, 0, y, 48, 48 - y, accent.darkened(0.18))
		"jumper":
			for x in range(0, 48, 8):
				_line(img, x, 48, x + 12, 0, line)
		"boss":
			for i in 9:
				_line(img, i * 6, 0, 48 - i * 3, 48, line)
				_circle(img, 24, 24, 5 + i % 3, accent.darkened(0.12))
		_:
			_rect(img, 0, 22, 48, 3, line)
	var tex = ImageTexture.create_from_image(img)
	var mat = StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.roughness = 0.82
	material_cache[key] = mat
	return mat

func make_sprite_texture(kind: String, id: String, color: Color, accent: Color = Color.WHITE) -> Texture2D:
	var key = "%s_%s_%s_%s" % [kind, id, color.to_html(false), accent.to_html(false)]
	if texture_cache.has(key):
		return texture_cache[key]
	var img = Image.create(96, 96, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	if kind == "enemy":
		_draw_enemy(img, id, color, accent)
	elif kind == "weapon":
		_draw_weapon(img, id, color)
	elif kind == "ammo":
		_draw_ammo(img, id, color)
	elif kind == "powerup":
		_draw_powerup(img, id, color)
	elif kind == "key":
		_draw_key(img)
	elif kind == "medkit":
		_draw_medkit(img)
	else:
		_draw_pickup_orb(img, color, accent)
	var tex = ImageTexture.create_from_image(img)
	texture_cache[key] = tex
	return tex

func _fill_pattern(img: Image, theme, surface: String) -> void:
	var a = theme.wall_a
	var b = theme.wall_b
	if surface == "floor":
		a = theme.floor_a
		b = theme.floor_b
	elif surface == "ceiling":
		a = theme.ceiling_a
		b = theme.ceiling_b
	for y in 64:
		for x in 64:
			var n = int((x * 13 + y * 23 + (x ^ y) * 3) % 17)
			var t = 0.18 if n > 11 else 0.0
			var base = a.lerp(b, 0.35 + t)
			img.set_pixel(x, y, base)
	var line = theme.line
	if theme.pattern == "brick":
		_brick(img, line, surface)
	elif theme.pattern == "rivet":
		_rivet(img, line, theme.glow, surface)
	elif theme.pattern == "cracked":
		_cracked(img, line)
	elif theme.pattern == "rune":
		_rune(img, line, theme.glow)
	elif theme.pattern == "hazard":
		_hazard(img, line, theme.glow, surface)
	elif theme.pattern == "lava":
		_lava(img, line, theme.glow)
	elif theme.pattern == "plate":
		_plate(img, line, theme.glow)
	elif theme.pattern == "organic":
		_organic(img, line, theme.glow)
	else:
		_obsidian(img, line, theme.glow)

func _brick(img: Image, line: Color, surface: String) -> void:
	var step = 16 if surface != "floor" else 12
	for y in range(step, 64, step):
		_rect(img, 0, y, 64, 2, line)
	for y in range(0, 64, step):
		var off = 0 if floori(float(y) / float(step)) % 2 == 0 else 16
		for x in range(off, 64, 32):
			_rect(img, x, y, 2, step, line)

func _rivet(img: Image, line: Color, glow: Color, surface: String) -> void:
	for x in range(0, 64, 16):
		_rect(img, x, 0, 2, 64, line)
	for y in range(0, 64, 16):
		_rect(img, 0, y, 64, 2, line)
	for x in range(8, 64, 16):
		for y in range(8, 64, 16):
			_circle(img, x, y, 2, glow if surface != "floor" else line.lightened(0.35))

func _cracked(img: Image, line: Color) -> void:
	for y in range(0, 64, 18):
		_line(img, 0, y, 64, y + 7, line)
	for i in 8:
		var x = 5 + i * 7
		_line(img, x, (i * 19) % 64, x + 9, (i * 19 + 11) % 64, line.darkened(0.1))

func _rune(img: Image, line: Color, glow: Color) -> void:
	for x in range(0, 64, 12):
		_rect(img, x, 0, 2, 64, line)
	for y in range(8, 64, 24):
		_line(img, 18, y, 28, y + 11, glow)
		_line(img, 28, y + 11, 18, y + 22, glow)
		_line(img, 42, y, 34, y + 22, glow)

func _hazard(img: Image, line: Color, glow: Color, surface: String) -> void:
	for y in range(0, 64, 18):
		_rect(img, 0, y, 64, 2, line)
	for x in range(-64, 96, 16):
		_line(img, x, 64, x + 64, 0, glow if surface == "floor" else line.lightened(0.35))

func _lava(img: Image, line: Color, glow: Color) -> void:
	for i in 8:
		var y = i * 8 + 4
		_line(img, 0, y, 64, y + int(sin(i) * 8), line)
	for i in 7:
		var x = 6 + i * 9
		_line(img, x, 0, x + 8, 64, glow)

func _plate(img: Image, line: Color, glow: Color) -> void:
	for x in range(0, 64, 24):
		_rect(img, x, 0, 3, 64, line)
	for y in range(0, 64, 24):
		_rect(img, 0, y, 64, 3, line)
	for y in [12, 36, 60]:
		_rect(img, 3, y, 58, 2, glow.darkened(0.15))

func _organic(img: Image, line: Color, glow: Color) -> void:
	for i in 10:
		var y = i * 7
		_line(img, 0, y, 64, y + int(sin(i * 1.7) * 18), line)
	for i in 7:
		_circle(img, 8 + i * 9, 12 + int(sin(i) * 20) + 20, 3, glow.darkened(0.2))

func _obsidian(img: Image, line: Color, glow: Color) -> void:
	for i in 11:
		_line(img, i * 6, 0, 64 - i * 3, 64, line)
	for x in range(12, 64, 20):
		_rect(img, x, 4, 3, 56, glow.darkened(0.05))

func _draw_enemy(img: Image, id: String, color: Color, accent: Color) -> void:
	var dark = color.darkened(0.35)
	var shade = color.lightened(0.22)
	if id == "grunt":
		_poly_rect(img, 30, 28, 36, 42, color)
		_tri(img, 26, 28, 34, 6, 42, 29, dark)
		_tri(img, 66, 28, 58, 6, 50, 29, dark)
		_rect(img, 35, 54, 26, 10, dark)
	elif id == "fast":
		_poly_rect(img, 39, 18, 18, 58, color)
		for i in 5:
			_tri(img, 30 + i * 8, 24, 34 + i * 8, 8, 38 + i * 8, 24, dark)
		_rect(img, 33, 62, 30, 7, accent.darkened(0.1))
	elif id == "tank":
		_poly_rect(img, 22, 34, 52, 34, color)
		_rect(img, 15, 43, 66, 18, dark)
		_rect(img, 31, 24, 34, 14, shade)
	elif id == "brute":
		_poly_rect(img, 24, 25, 50, 50, color)
		_rect(img, 30, 57, 36, 14, dark)
		for i in 4:
			_tri(img, 35 + i * 7, 59, 38 + i * 7, 72, 42 + i * 7, 59, Color8(238, 232, 196))
	elif id == "ranged":
		_poly_rect(img, 34, 20, 28, 56, color)
		_circle(img, 48, 58, 8, accent)
		_circle(img, 28, 42, 6, accent.darkened(0.1))
		_circle(img, 68, 42, 6, accent.darkened(0.1))
	elif id == "jumper":
		_poly_rect(img, 36, 24, 24, 42, color)
		_tri(img, 35, 20, 31, 4, 43, 19, dark)
		_tri(img, 61, 20, 65, 4, 53, 19, dark)
		_tri(img, 35, 62, 10, 82, 42, 76, dark)
		_tri(img, 61, 62, 86, 82, 54, 76, dark)
	else:
		_poly_rect(img, 16, 18, 64, 58, color)
		_tri(img, 18, 22, 33, 0, 42, 24, dark)
		_tri(img, 78, 22, 63, 0, 54, 24, dark)
		_rect(img, 30, 58, 36, 14, dark)
		_circle(img, 48, 39, 10, accent)
	_circle(img, 40, 42, 4, accent)
	_circle(img, 56, 42, 4, accent)
	_rect(img, 26, 78, 44, 5, Color(0, 0, 0, 0.35))
	_outline_alpha(img)

func _draw_weapon(img: Image, id: String, color: Color) -> void:
	if id == "whip":
		_rect(img, 61, 52, 8, 32, Color8(80, 42, 28))
		for i in 8:
			_circle(img, 24 + i * 6, 30 + int(sin(i * 0.8) * 14), 3, color)
	elif id == "railgun":
		_rect(img, 13, 45, 70, 12, color.darkened(0.25))
		_rect(img, 22, 36, 48, 12, color)
		_rect(img, 35, 29, 28, 5, Color8(230, 252, 255))
		_circle(img, 76, 51, 7, Color8(120, 238, 255))
	elif id == "incinerator":
		_rect(img, 18, 48, 62, 16, color.darkened(0.25))
		_rect(img, 28, 34, 38, 18, color)
		_circle(img, 72, 44, 9, Color8(255, 188, 66))
		_tri(img, 77, 42, 92, 34, 84, 52, Color8(255, 86, 28))
	elif id == "heavy":
		_rect(img, 16, 46, 66, 18, color)
		_rect(img, 32, 30, 38, 18, color.lightened(0.14))
	elif id == "shotgun":
		_rect(img, 12, 50, 74, 10, Color8(58, 35, 22))
		_rect(img, 30, 36, 42, 18, color)
	else:
		_rect(img, 24, 42, 48, 20, color)
		_rect(img, 45, 24, 12, 24, Color8(28, 28, 32))
	if id == "plasma":
		_circle(img, 48, 34, 8, Color8(120, 232, 255))
	_outline_alpha(img)

func _draw_ammo(img: Image, id: String, color: Color) -> void:
	_rect(img, 28, 34, 40, 30, color)
	_rect(img, 31, 37, 34, 5, color.lightened(0.22))
	_rect(img, 35, 48, 26, 7, Color8(28, 28, 28))
	if id == "g":
		_circle(img, 48, 49, 13, color)
	_outline_alpha(img)

func _draw_powerup(img: Image, id: String, color: Color) -> void:
	_circle(img, 48, 48, 22, color)
	_circle(img, 48, 48, 13, Color8(245, 245, 220))
	if id == "berserk":
		_rect(img, 34, 46, 28, 5, Color8(255, 220, 200))
	elif id == "haste":
		_tri(img, 43, 27, 62, 48, 48, 48, Color8(230, 250, 255))
		_tri(img, 48, 48, 36, 68, 53, 47, Color8(230, 250, 255))
	else:
		_rect(img, 38, 38, 20, 8, Color8(230, 255, 235))
		_rect(img, 44, 38, 8, 22, Color8(230, 255, 235))
	_outline_alpha(img)

func _draw_key(img: Image) -> void:
	_circle(img, 38, 46, 15, Color8(236, 210, 46))
	_circle(img, 38, 46, 7, Color(0, 0, 0, 0))
	_rect(img, 48, 43, 32, 7, Color8(236, 210, 46))
	_rect(img, 68, 50, 5, 10, Color8(236, 210, 46))
	_rect(img, 78, 50, 5, 8, Color8(236, 210, 46))
	_outline_alpha(img)

func _draw_medkit(img: Image) -> void:
	_rect(img, 28, 32, 40, 34, Color8(235, 235, 230))
	_rect(img, 44, 36, 8, 26, Color8(210, 28, 34))
	_rect(img, 34, 45, 28, 8, Color8(210, 28, 34))
	_outline_alpha(img)

func _draw_pickup_orb(img: Image, color: Color, accent: Color) -> void:
	_circle(img, 48, 48, 20, color)
	_circle(img, 48, 48, 9, accent)
	_outline_alpha(img)

func _poly_rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	_rect(img, x, y + 8, w, h - 16, c)
	_rect(img, x + 5, y, w - 10, h, c)

func _rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy in range(max(0, y), min(img.get_height(), y + h)):
		for xx in range(max(0, x), min(img.get_width(), x + w)):
			img.set_pixel(xx, yy, c)

func _circle(img: Image, cx: int, cy: int, r: int, c: Color) -> void:
	for y in range(cy - r, cy + r + 1):
		for x in range(cx - r, cx + r + 1):
			if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
				if Vector2(x - cx, y - cy).length_squared() <= r * r:
					img.set_pixel(x, y, c)

func _tri(img: Image, x1: int, y1: int, x2: int, y2: int, x3: int, y3: int, c: Color) -> void:
	var min_x = max(0, min(x1, min(x2, x3)))
	var max_x = min(img.get_width() - 1, max(x1, max(x2, x3)))
	var min_y = max(0, min(y1, min(y2, y3)))
	var max_y = min(img.get_height() - 1, max(y1, max(y2, y3)))
	var area = _edge(x1, y1, x2, y2, x3, y3)
	if area == 0:
		return
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var w0 = _edge(x2, y2, x3, y3, x, y)
			var w1 = _edge(x3, y3, x1, y1, x, y)
			var w2 = _edge(x1, y1, x2, y2, x, y)
			if (w0 >= 0 and w1 >= 0 and w2 >= 0) or (w0 <= 0 and w1 <= 0 and w2 <= 0):
				img.set_pixel(x, y, c)

func _edge(x1, y1, x2, y2, x, y):
	return (x - x1) * (y2 - y1) - (y - y1) * (x2 - x1)

func _line(img: Image, x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	var dx = abs(x1 - x0)
	var sx = 1 if x0 < x1 else -1
	var dy = -abs(y1 - y0)
	var sy = 1 if y0 < y1 else -1
	var err = dx + dy
	while true:
		if x0 >= 0 and y0 >= 0 and x0 < img.get_width() and y0 < img.get_height():
			img.set_pixel(x0, y0, c)
		if x0 == x1 and y0 == y1:
			break
		var e2 = 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy

func _outline_alpha(img: Image) -> void:
	var copy = img.duplicate()
	for y in img.get_height():
		for x in img.get_width():
			if copy.get_pixel(x, y).a > 0:
				continue
			var near = false
			for oy in range(-1, 2):
				for ox in range(-1, 2):
					var nx = x + ox
					var ny = y + oy
					if nx >= 0 and ny >= 0 and nx < img.get_width() and ny < img.get_height():
						if copy.get_pixel(nx, ny).a > 0.1:
							near = true
			if near:
				img.set_pixel(x, y, Color(0, 0, 0, 0.82))
