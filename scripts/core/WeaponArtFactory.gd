extends RefCounted
class_name WeaponArtFactory

const W = 512
const H = 256

var texture_cache = {}

func make_weapon_texture(id: String) -> Texture2D:
	return make_weapon_pickup_texture(id)

func make_weapon_pickup_texture(id: String) -> Texture2D:
	var key = "weapon_pickup_%s" % id
	if texture_cache.has(key):
		return texture_cache[key]
	var img = Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_shadow(img, Vector2(256, 206), Vector2(190, 28), Color(0, 0, 0, 0.34))
	match id:
		"whip":
			_draw_whip(img)
		"shotgun":
			_draw_shotgun(img)
		"auto":
			_draw_auto(img)
		"seeker":
			_draw_auto(img)
		"plasma":
			_draw_plasma(img)
		"heavy":
			_draw_heavy(img)
		"railgun":
			_draw_railgun(img)
		"incinerator":
			_draw_incinerator(img)
		_:
			_draw_pistol(img)
	var tex = ImageTexture.create_from_image(img)
	texture_cache[key] = tex
	return tex

func make_weapon_view_texture(id: String) -> Texture2D:
	var key = "weapon_view_%s" % id
	if texture_cache.has(key):
		return texture_cache[key]
	var img = Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_shadow(img, Vector2(326, 231), Vector2(178, 20), Color(0, 0, 0, 0.28))
	match id:
		"whip":
			_draw_view_whip(img)
		"shotgun":
			_draw_view_shotgun(img)
		"auto":
			_draw_view_auto(img)
		"seeker":
			_draw_view_auto(img)
		"plasma":
			_draw_view_plasma(img)
		"heavy":
			_draw_view_heavy(img)
		"railgun":
			_draw_view_railgun(img)
		"incinerator":
			_draw_view_incinerator(img)
		_:
			_draw_view_pistol(img)
	var tex = ImageTexture.create_from_image(img)
	texture_cache[key] = tex
	return tex

func make_grenade_texture() -> Texture2D:
	if texture_cache.has("grenade"):
		return texture_cache["grenade"]
	var img = Image.create(256, 256, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_shadow(img, Vector2(128, 198), Vector2(70, 18), Color(0, 0, 0, 0.32))
	var armor = Color8(224, 222, 204)
	var dark = Color8(30, 34, 36)
	var accent = Color8(84, 246, 255)
	_circle(img, 128, 122, 66, dark)
	_circle(img, 128, 122, 58, armor)
	for i in 8:
		var a = TAU * float(i) / 8.0
		var p = Vector2(128 + cos(a) * 44, 122 + sin(a) * 44)
		_panel(img, [
			p + Vector2(cos(a - 0.62), sin(a - 0.62)) * 18,
			p + Vector2(cos(a + 0.62), sin(a + 0.62)) * 18,
			p + Vector2(cos(a), sin(a)) * 30
		], dark if i % 2 == 0 else Color8(238, 184, 48))
	_circle(img, 128, 122, 24, Color8(20, 42, 46))
	_circle(img, 128, 122, 18, accent)
	_circle(img, 123, 116, 7, Color8(210, 255, 255))
	var tex = ImageTexture.create_from_image(img)
	texture_cache["grenade"] = tex
	return tex

func make_hook_texture() -> Texture2D:
	if texture_cache.has("hook"):
		return texture_cache["hook"]
	var img = Image.create(256, 256, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var armor = Color8(226, 222, 205)
	var dark = Color8(28, 32, 34)
	var accent = Color8(82, 255, 110)
	_shadow(img, Vector2(128, 185), Vector2(76, 16), Color(0, 0, 0, 0.34))
	_panel(img, [Vector2(88, 118), Vector2(126, 82), Vector2(168, 104), Vector2(150, 148), Vector2(108, 152)], dark)
	_panel(img, [Vector2(100, 113), Vector2(130, 92), Vector2(156, 108), Vector2(142, 136), Vector2(112, 139)], armor)
	_panel(img, [Vector2(82, 82), Vector2(118, 104), Vector2(103, 122), Vector2(55, 120)], armor)
	_panel(img, [Vector2(174, 88), Vector2(156, 112), Vector2(173, 128), Vector2(214, 106)], armor)
	_panel(img, [Vector2(96, 160), Vector2(124, 143), Vector2(139, 157), Vector2(116, 202)], armor)
	_panel(img, [Vector2(155, 148), Vector2(170, 160), Vector2(154, 205), Vector2(137, 158)], armor)
	_circle(img, 128, 120, 20, Color8(20, 42, 32))
	_circle(img, 128, 120, 13, accent)
	_line(img, 70, 151, 185, 75, Color8(238, 184, 48), 4)
	var tex = ImageTexture.create_from_image(img)
	texture_cache["hook"] = tex
	return tex

func _draw_view_pistol(img: Image) -> void:
	var armor = Color8(230, 226, 210)
	var dark = Color8(21, 25, 27)
	var metal = Color8(74, 79, 78)
	var cyan = Color8(76, 228, 245)
	_panel(img, [Vector2(152, 142), Vector2(204, 112), Vector2(384, 134), Vector2(438, 178), Vector2(392, 210), Vector2(178, 184)], dark)
	_panel(img, [Vector2(206, 124), Vector2(356, 140), Vector2(398, 170), Vector2(370, 188), Vector2(214, 170)], armor)
	_panel(img, [Vector2(166, 154), Vector2(214, 128), Vector2(214, 176), Vector2(164, 191), Vector2(132, 174)], dark)
	_circle(img, 157, 169, 24, Color8(8, 10, 11))
	_circle(img, 157, 169, 13, cyan.darkened(0.35))
	_panel(img, [Vector2(332, 182), Vector2(392, 195), Vector2(408, 246), Vector2(350, 250)], dark)
	_panel(img, [Vector2(350, 194), Vector2(382, 202), Vector2(390, 236), Vector2(358, 238)], metal)
	_rect(img, 230, 158, 92, 8, cyan)
	_sight(img, Vector2(310, 122), cyan)
	_bolts(img, [Vector2(238, 140), Vector2(284, 146), Vector2(354, 160), Vector2(382, 188)], cyan)
	_panel_lines(img, [Vector2(220, 153), Vector2(290, 162), Vector2(342, 176)], Color8(132, 132, 124))

func _draw_view_shotgun(img: Image) -> void:
	var armor = Color8(230, 226, 210)
	var dark = Color8(20, 24, 25)
	var metal = Color8(76, 80, 78)
	var yellow = Color8(246, 186, 32)
	var cyan = Color8(72, 228, 245)
	_panel(img, [Vector2(116, 135), Vector2(194, 96), Vector2(454, 132), Vector2(510, 185), Vector2(450, 230), Vector2(154, 190)], dark)
	_panel(img, [Vector2(205, 111), Vector2(420, 137), Vector2(470, 176), Vector2(424, 205), Vector2(205, 174)], armor)
	_panel(img, [Vector2(98, 149), Vector2(166, 112), Vector2(206, 136), Vector2(202, 184), Vector2(132, 205), Vector2(72, 177)], dark)
	_circle(img, 115, 166, 42, Color8(6, 8, 8))
	_circle(img, 115, 166, 27, yellow.darkened(0.12))
	_circle(img, 115, 166, 17, Color8(7, 8, 8))
	_panel(img, [Vector2(188, 180), Vector2(430, 205), Vector2(452, 229), Vector2(172, 210)], metal)
	_rect(img, 218, 180, 220, 13, yellow)
	_rect(img, 234, 184, 180, 5, Color8(255, 232, 90))
	_panel(img, [Vector2(388, 112), Vector2(452, 126), Vector2(468, 158), Vector2(410, 153)], metal)
	_sight(img, Vector2(342, 107), cyan)
	_bolts(img, [Vector2(238, 130), Vector2(300, 140), Vector2(366, 150), Vector2(438, 178), Vector2(188, 184)], cyan)
	_panel_lines(img, [Vector2(226, 151), Vector2(318, 163), Vector2(390, 178)], Color8(136, 134, 124))

func _draw_view_auto(img: Image) -> void:
	var armor = Color8(230, 226, 210)
	var dark = Color8(20, 25, 27)
	var metal = Color8(65, 71, 72)
	var cyan = Color8(72, 228, 245)
	_panel(img, [Vector2(88, 146), Vector2(166, 104), Vector2(432, 127), Vector2(498, 176), Vector2(446, 220), Vector2(124, 191)], dark)
	_panel(img, [Vector2(178, 118), Vector2(364, 134), Vector2(426, 165), Vector2(388, 191), Vector2(178, 170)], armor)
	_panel(img, [Vector2(82, 154), Vector2(164, 122), Vector2(174, 170), Vector2(96, 184)], metal)
	_circle(img, 92, 165, 22, Color8(6, 8, 8))
	_panel(img, [Vector2(274, 191), Vector2(332, 198), Vector2(318, 252), Vector2(260, 244)], metal)
	_panel(img, [Vector2(386, 185), Vector2(438, 196), Vector2(448, 246), Vector2(406, 248)], dark)
	_rect(img, 190, 159, 150, 10, cyan)
	_rect(img, 142, 197, 220, 13, metal)
	_rect(img, 132, 210, 158, 7, cyan.darkened(0.2))
	_sight(img, Vector2(292, 108), cyan)
	_bolts(img, [Vector2(200, 135), Vector2(254, 139), Vector2(318, 149), Vector2(394, 172), Vector2(436, 195)], cyan)

func _draw_view_plasma(img: Image) -> void:
	var armor = Color8(230, 226, 210)
	var dark = Color8(18, 24, 23)
	var metal = Color8(62, 70, 68)
	var green = Color8(70, 255, 92)
	_panel(img, [Vector2(112, 131), Vector2(198, 87), Vector2(436, 126), Vector2(502, 186), Vector2(432, 231), Vector2(146, 192)], dark)
	_panel(img, [Vector2(204, 108), Vector2(348, 128), Vector2(412, 166), Vector2(374, 194), Vector2(190, 170)], armor)
	_circle(img, 130, 159, 50, Color8(8, 12, 10))
	_circle(img, 130, 159, 34, green.darkened(0.10))
	_circle(img, 130, 159, 20, Color8(186, 255, 170))
	_rect(img, 208, 166, 190, 15, green)
	_rect(img, 226, 171, 148, 6, Color8(200, 255, 178))
	_panel(img, [Vector2(176, 190), Vector2(404, 212), Vector2(380, 237), Vector2(172, 215)], metal)
	_panel(img, [Vector2(356, 188), Vector2(426, 197), Vector2(448, 250), Vector2(386, 250)], dark)
	for x in [230, 272, 314, 356]:
		_circle(img, x, 173 + int((x - 230) * 0.08), 10, green)
	_sight(img, Vector2(324, 103), green)
	_bolts(img, [Vector2(218, 128), Vector2(278, 136), Vector2(344, 149), Vector2(408, 180)], green)

func _draw_view_heavy(img: Image) -> void:
	var armor = Color8(230, 226, 210)
	var dark = Color8(20, 24, 26)
	var metal = Color8(76, 78, 78)
	var yellow = Color8(242, 184, 34)
	var cyan = Color8(70, 218, 238)
	_panel(img, [Vector2(88, 118), Vector2(184, 72), Vector2(450, 116), Vector2(512, 184), Vector2(444, 238), Vector2(118, 198)], dark)
	_panel(img, [Vector2(196, 98), Vector2(372, 121), Vector2(436, 164), Vector2(390, 199), Vector2(184, 171)], armor)
	_circle(img, 104, 160, 58, Color8(7, 8, 8))
	_circle(img, 104, 160, 41, yellow.darkened(0.18))
	_circle(img, 104, 160, 28, Color8(8, 9, 9))
	_circle(img, 104, 160, 18, Color8(1, 2, 2))
	_panel(img, [Vector2(292, 197), Vector2(374, 202), Vector2(386, 253), Vector2(298, 253)], yellow)
	_panel(img, [Vector2(376, 190), Vector2(442, 199), Vector2(466, 250), Vector2(410, 252)], dark)
	_rect(img, 204, 157, 166, 11, Color8(166, 214, 92))
	_panel(img, [Vector2(150, 193), Vector2(328, 212), Vector2(304, 238), Vector2(144, 218)], metal)
	_sight(img, Vector2(296, 85), cyan)
	_bolts(img, [Vector2(204, 114), Vector2(264, 124), Vector2(330, 139), Vector2(402, 166), Vector2(434, 202)], yellow)

func _draw_view_railgun(img: Image) -> void:
	var armor = Color8(230, 226, 210)
	var dark = Color8(18, 22, 29)
	var metal = Color8(64, 70, 74)
	var purple = Color8(188, 70, 255)
	var cyan = Color8(80, 232, 245)
	_panel(img, [Vector2(72, 133), Vector2(150, 96), Vector2(458, 128), Vector2(512, 174), Vector2(462, 214), Vector2(92, 184)], dark)
	_panel(img, [Vector2(326, 124), Vector2(436, 138), Vector2(478, 166), Vector2(442, 190), Vector2(316, 174)], armor)
	_panel(img, [Vector2(132, 118), Vector2(290, 131), Vector2(270, 154), Vector2(114, 146)], armor)
	_rect(img, 112, 162, 326, 8, purple)
	_rect(img, 132, 135, 294, 7, purple)
	_line(img, 118, 166, 432, 168, Color8(235, 196, 255), 3)
	_line(img, 140, 138, 420, 141, Color8(235, 196, 255), 2)
	_circle(img, 88, 164, 32, Color8(8, 8, 12))
	_circle(img, 88, 164, 22, purple.darkened(0.05))
	_panel(img, [Vector2(382, 189), Vector2(438, 198), Vector2(456, 248), Vector2(402, 250)], dark)
	_rect(img, 140, 193, 244, 14, metal)
	_sight(img, Vector2(376, 104), cyan)
	_bolts(img, [Vector2(154, 130), Vector2(226, 137), Vector2(330, 138), Vector2(424, 162)], cyan)

func _draw_view_incinerator(img: Image) -> void:
	var armor = Color8(230, 226, 210)
	var dark = Color8(22, 25, 25)
	var metal = Color8(70, 74, 72)
	var orange = Color8(255, 132, 36)
	var yellow = Color8(248, 190, 38)
	_panel(img, [Vector2(110, 129), Vector2(192, 91), Vector2(424, 125), Vector2(494, 184), Vector2(428, 230), Vector2(140, 192)], dark)
	_panel(img, [Vector2(196, 111), Vector2(342, 129), Vector2(406, 166), Vector2(370, 193), Vector2(188, 170)], armor)
	_circle(img, 126, 160, 43, Color8(7, 8, 8))
	_circle(img, 126, 160, 29, orange.darkened(0.08))
	_circle(img, 126, 160, 18, Color8(255, 220, 72))
	_rect(img, 206, 172, 166, 13, yellow)
	_panel(img, [Vector2(350, 185), Vector2(418, 195), Vector2(438, 248), Vector2(376, 250)], dark)
	_panel(img, [Vector2(360, 124), Vector2(426, 142), Vector2(446, 174), Vector2(388, 182)], metal)
	_flame(img, Vector2(424, 115), orange)
	_panel(img, [Vector2(168, 190), Vector2(328, 207), Vector2(306, 235), Vector2(164, 214)], metal)
	_bolts(img, [Vector2(210, 128), Vector2(276, 138), Vector2(344, 152), Vector2(404, 178)], yellow)

func _draw_view_whip(img: Image) -> void:
	var armor = Color8(230, 226, 210)
	var dark = Color8(20, 24, 24)
	var yellow = Color8(242, 184, 34)
	var cyan = Color8(82, 232, 245)
	_panel(img, [Vector2(312, 160), Vector2(366, 132), Vector2(480, 166), Vector2(510, 218), Vector2(440, 246), Vector2(326, 210)], dark)
	_panel(img, [Vector2(350, 156), Vector2(392, 142), Vector2(458, 170), Vector2(472, 204), Vector2(428, 222), Vector2(354, 196)], armor)
	_rect(img, 374, 181, 76, 9, cyan)
	var points = [
		Vector2(354, 159), Vector2(288, 104), Vector2(206, 78), Vector2(122, 101),
		Vector2(88, 150), Vector2(132, 189), Vector2(218, 184), Vector2(282, 148)
	]
	for i in range(points.size() - 1):
		_line(img, int(points[i].x), int(points[i].y), int(points[i + 1].x), int(points[i + 1].y), Color8(12, 14, 14), 12)
		_line(img, int(points[i].x), int(points[i].y), int(points[i + 1].x), int(points[i + 1].y), yellow, 5)
	for i in points.size():
		_panel(img, [
			points[i] + Vector2(-8, -7),
			points[i] + Vector2(8, -7),
			points[i] + Vector2(10, 7),
			points[i] + Vector2(-10, 7)
		], dark if i % 2 == 0 else yellow)
	_circle(img, 92, 151, 22, armor)
	for a in [0.0, PI * 0.5, PI, PI * 1.5]:
		_panel(img, [Vector2(92, 151), Vector2(92 + cos(a - 0.20) * 42, 151 + sin(a - 0.20) * 42), Vector2(92 + cos(a + 0.20) * 42, 151 + sin(a + 0.20) * 42)], armor)
	_circle(img, 92, 151, 10, yellow)

func _draw_pistol(img: Image) -> void:
	var armor = Color8(230, 226, 210)
	var shade = Color8(158, 156, 144)
	var dark = Color8(24, 29, 31)
	var cyan = Color8(76, 228, 245)
	_panel(img, [Vector2(100, 112), Vector2(148, 82), Vector2(336, 82), Vector2(398, 114), Vector2(370, 154), Vector2(128, 160)], dark)
	_panel(img, [Vector2(126, 101), Vector2(168, 76), Vector2(324, 80), Vector2(366, 109), Vector2(342, 135), Vector2(146, 139)], armor)
	_panel(img, [Vector2(92, 128), Vector2(140, 103), Vector2(156, 139), Vector2(104, 164)], dark)
	_panel(img, [Vector2(292, 146), Vector2(362, 148), Vector2(388, 226), Vector2(329, 226)], dark)
	_panel(img, [Vector2(314, 155), Vector2(352, 160), Vector2(367, 213), Vector2(336, 213)], Color8(64, 68, 68))
	_panel(img, [Vector2(158, 124), Vector2(294, 124), Vector2(278, 137), Vector2(170, 139)], cyan)
	_panel(img, [Vector2(318, 102), Vector2(354, 104), Vector2(354, 129), Vector2(318, 129)], dark)
	_rect(img, 326, 110, 22, 7, cyan)
	_barrel(img, Vector2(72, 131), 62, 38, cyan)
	_sight(img, Vector2(270, 72), cyan)
	_bolts(img, [Vector2(178, 95), Vector2(226, 90), Vector2(310, 95), Vector2(338, 152), Vector2(142, 148)], cyan)
	_panel_lines(img, [Vector2(162, 101), Vector2(250, 102), Vector2(320, 88)], shade)

func _draw_shotgun(img: Image) -> void:
	var armor = Color8(230, 226, 210)
	var dark = Color8(24, 28, 30)
	var metal = Color8(72, 76, 76)
	var yellow = Color8(246, 186, 32)
	var cyan = Color8(72, 228, 245)
	_panel(img, [Vector2(76, 104), Vector2(128, 72), Vector2(424, 74), Vector2(478, 112), Vector2(454, 164), Vector2(112, 170)], dark)
	_panel(img, [Vector2(146, 84), Vector2(382, 82), Vector2(430, 111), Vector2(402, 142), Vector2(132, 143)], armor)
	_barrel(img, Vector2(57, 134), 92, 66, yellow)
	_rect(img, 155, 122, 226, 18, yellow)
	_rect(img, 164, 127, 206, 8, Color8(255, 232, 90))
	_panel(img, [Vector2(352, 152), Vector2(440, 150), Vector2(468, 222), Vector2(402, 225)], dark)
	_panel(img, [Vector2(86, 160), Vector2(238, 160), Vector2(222, 190), Vector2(96, 192)], metal)
	_panel(img, [Vector2(392, 86), Vector2(452, 91), Vector2(465, 118), Vector2(415, 124)], metal)
	_sight(img, Vector2(328, 66), cyan)
	_bolts(img, [Vector2(174, 96), Vector2(238, 96), Vector2(312, 96), Vector2(390, 105), Vector2(118, 158), Vector2(430, 160)], cyan)
	_panel_lines(img, [Vector2(182, 112), Vector2(286, 112), Vector2(362, 94), Vector2(418, 134)], Color8(135, 134, 124))

func _draw_auto(img: Image) -> void:
	var armor = Color8(230, 226, 210)
	var dark = Color8(22, 27, 29)
	var metal = Color8(64, 70, 72)
	var cyan = Color8(72, 228, 245)
	_panel(img, [Vector2(72, 116), Vector2(132, 78), Vector2(394, 78), Vector2(452, 112), Vector2(420, 158), Vector2(112, 164)], dark)
	_panel(img, [Vector2(138, 91), Vector2(332, 88), Vector2(388, 111), Vector2(360, 138), Vector2(126, 141)], armor)
	_panel(img, [Vector2(390, 151), Vector2(442, 154), Vector2(450, 220), Vector2(410, 223)], dark)
	_panel(img, [Vector2(226, 160), Vector2(280, 160), Vector2(270, 226), Vector2(216, 224)], metal)
	_barrel(img, Vector2(55, 137), 100, 42, cyan)
	_rect(img, 156, 126, 168, 12, cyan)
	_rect(img, 120, 167, 230, 18, metal)
	_rect(img, 104, 184, 170, 10, cyan.darkened(0.2))
	_sight(img, Vector2(286, 67), cyan)
	_panel(img, [Vector2(316, 96), Vector2(366, 98), Vector2(362, 132), Vector2(314, 134)], dark)
	_rect(img, 324, 108, 30, 8, cyan)
	_bolts(img, [Vector2(148, 104), Vector2(204, 94), Vector2(270, 102), Vector2(340, 145), Vector2(405, 120)], cyan)

func _draw_plasma(img: Image) -> void:
	var armor = Color8(230, 226, 210)
	var dark = Color8(20, 25, 24)
	var metal = Color8(62, 70, 68)
	var green = Color8(70, 255, 92)
	_panel(img, [Vector2(86, 101), Vector2(154, 62), Vector2(402, 74), Vector2(466, 116), Vector2(424, 172), Vector2(126, 174)], dark)
	_panel(img, [Vector2(152, 84), Vector2(318, 82), Vector2(370, 108), Vector2(344, 142), Vector2(144, 144)], armor)
	_barrel(img, Vector2(68, 132), 86, 76, green)
	_circle(img, 82, 132, 24, green)
	_rect(img, 170, 124, 190, 18, green)
	_rect(img, 180, 130, 170, 7, Color8(190, 255, 178))
	_panel(img, [Vector2(332, 150), Vector2(414, 153), Vector2(442, 222), Vector2(374, 224)], dark)
	_panel(img, [Vector2(120, 164), Vector2(370, 166), Vector2(354, 194), Vector2(140, 195)], metal)
	for x in [188, 230, 272, 314]:
		_circle(img, x, 132, 13, green)
	_sight(img, Vector2(330, 65), green)
	_bolts(img, [Vector2(162, 96), Vector2(228, 90), Vector2(306, 96), Vector2(390, 128)], green)

func _draw_heavy(img: Image) -> void:
	var armor = Color8(230, 226, 210)
	var dark = Color8(22, 26, 28)
	var metal = Color8(76, 78, 78)
	var yellow = Color8(242, 184, 34)
	var cyan = Color8(70, 218, 238)
	_panel(img, [Vector2(70, 88), Vector2(146, 50), Vector2(416, 62), Vector2(486, 118), Vector2(442, 184), Vector2(118, 190)], dark)
	_panel(img, [Vector2(158, 75), Vector2(342, 72), Vector2(408, 106), Vector2(374, 148), Vector2(142, 151)], armor)
	_barrel(img, Vector2(58, 138), 104, 90, yellow)
	_circle(img, 70, 138, 31, dark)
	_circle(img, 70, 138, 20, Color8(10, 12, 13))
	_panel(img, [Vector2(274, 166), Vector2(360, 160), Vector2(370, 226), Vector2(292, 232)], yellow)
	_panel(img, [Vector2(366, 154), Vector2(438, 154), Vector2(468, 226), Vector2(408, 230)], dark)
	_rect(img, 178, 122, 170, 13, Color8(166, 214, 92))
	_panel(img, [Vector2(116, 178), Vector2(300, 178), Vector2(282, 205), Vector2(128, 208)], metal)
	_sight(img, Vector2(286, 52), cyan)
	_bolts(img, [Vector2(170, 88), Vector2(242, 82), Vector2(318, 91), Vector2(390, 105), Vector2(430, 162)], yellow)

func _draw_railgun(img: Image) -> void:
	var armor = Color8(230, 226, 210)
	var dark = Color8(20, 24, 30)
	var metal = Color8(64, 70, 74)
	var purple = Color8(188, 70, 255)
	var cyan = Color8(80, 232, 245)
	_panel(img, [Vector2(50, 108), Vector2(118, 74), Vector2(448, 72), Vector2(492, 108), Vector2(456, 154), Vector2(78, 162)], dark)
	_panel(img, [Vector2(312, 82), Vector2(430, 82), Vector2(462, 106), Vector2(432, 132), Vector2(306, 132)], armor)
	_panel(img, [Vector2(108, 92), Vector2(278, 90), Vector2(258, 118), Vector2(92, 122)], armor)
	_rect(img, 72, 126, 330, 11, purple)
	_rect(img, 92, 98, 300, 9, purple)
	_rect(img, 80, 130, 312, 4, Color8(235, 196, 255))
	_barrel(img, Vector2(48, 132), 58, 56, purple)
	_panel(img, [Vector2(370, 152), Vector2(434, 154), Vector2(458, 220), Vector2(398, 224)], dark)
	_rect(img, 120, 160, 260, 20, metal)
	_sight(img, Vector2(372, 62), cyan)
	_bolts(img, [Vector2(140, 102), Vector2(220, 101), Vector2(326, 94), Vector2(420, 102)], cyan)

func _draw_incinerator(img: Image) -> void:
	var armor = Color8(230, 226, 210)
	var dark = Color8(24, 27, 27)
	var metal = Color8(70, 74, 72)
	var orange = Color8(255, 132, 36)
	var yellow = Color8(248, 190, 38)
	_panel(img, [Vector2(86, 98), Vector2(148, 66), Vector2(394, 78), Vector2(462, 124), Vector2(420, 178), Vector2(120, 176)], dark)
	_panel(img, [Vector2(150, 88), Vector2(314, 86), Vector2(370, 112), Vector2(344, 145), Vector2(136, 144)], armor)
	_barrel(img, Vector2(68, 135), 86, 70, orange)
	_rect(img, 174, 134, 170, 15, yellow)
	_panel(img, [Vector2(326, 146), Vector2(400, 150), Vector2(430, 224), Vector2(360, 226)], dark)
	_panel(img, [Vector2(364, 92), Vector2(426, 98), Vector2(448, 136), Vector2(392, 148)], metal)
	_flame(img, Vector2(438, 98), orange)
	_panel(img, [Vector2(142, 164), Vector2(308, 164), Vector2(292, 194), Vector2(152, 196)], metal)
	_bolts(img, [Vector2(164, 100), Vector2(236, 96), Vector2(314, 102), Vector2(396, 124)], yellow)

func _draw_whip(img: Image) -> void:
	var armor = Color8(230, 226, 210)
	var dark = Color8(22, 26, 26)
	var yellow = Color8(242, 184, 34)
	var cyan = Color8(82, 232, 245)
	_panel(img, [Vector2(70, 144), Vector2(108, 108), Vector2(188, 116), Vector2(210, 152), Vector2(168, 184), Vector2(92, 178)], dark)
	_panel(img, [Vector2(92, 137), Vector2(118, 116), Vector2(174, 124), Vector2(188, 151), Vector2(158, 170), Vector2(104, 166)], armor)
	_rect(img, 118, 148, 62, 10, cyan)
	var points = [
		Vector2(178, 126), Vector2(232, 78), Vector2(318, 58), Vector2(416, 82),
		Vector2(456, 136), Vector2(398, 178), Vector2(304, 162), Vector2(252, 124)
	]
	for i in range(points.size() - 1):
		_line(img, int(points[i].x), int(points[i].y), int(points[i + 1].x), int(points[i + 1].y), Color8(16, 18, 18), 13)
		_line(img, int(points[i].x), int(points[i].y), int(points[i + 1].x), int(points[i + 1].y), yellow, 6)
	for i in points.size():
		_panel(img, [
			points[i] + Vector2(-10, -8),
			points[i] + Vector2(10, -8),
			points[i] + Vector2(12, 8),
			points[i] + Vector2(-12, 8)
		], dark if i % 2 == 0 else yellow)
	_circle(img, 446, 140, 26, armor)
	for a in [0.0, PI * 0.5, PI, PI * 1.5]:
		_panel(img, [Vector2(446, 140), Vector2(446 + cos(a - 0.20) * 48, 140 + sin(a - 0.20) * 48), Vector2(446 + cos(a + 0.20) * 48, 140 + sin(a + 0.20) * 48)], armor)
	_circle(img, 446, 140, 12, yellow)

func _panel(img: Image, pts: Array, color: Color) -> void:
	for i in pts.size():
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % pts.size()]
		_line(img, int(a.x), int(a.y), int(b.x), int(b.y), Color(0.02, 0.025, 0.026, 0.96), 5)
	_poly(img, pts, color)
	for i in pts.size():
		var a2: Vector2 = pts[i]
		var b2: Vector2 = pts[(i + 1) % pts.size()]
		_line(img, int(a2.x), int(a2.y), int(b2.x), int(b2.y), color.lightened(0.12), 1)

func _barrel(img: Image, center: Vector2, width: int, height: int, accent: Color) -> void:
	var dark = Color8(18, 22, 23)
	_panel(img, [
		center + Vector2(-width * 0.48, -height * 0.46),
		center + Vector2(width * 0.28, -height * 0.50),
		center + Vector2(width * 0.50, 0),
		center + Vector2(width * 0.28, height * 0.50),
		center + Vector2(-width * 0.48, height * 0.46),
		center + Vector2(-width * 0.62, 0)
	], dark)
	_panel(img, [
		center + Vector2(-width * 0.36, -height * 0.31),
		center + Vector2(width * 0.18, -height * 0.34),
		center + Vector2(width * 0.32, 0),
		center + Vector2(width * 0.18, height * 0.34),
		center + Vector2(-width * 0.36, height * 0.31),
		center + Vector2(-width * 0.48, 0)
	], accent.darkened(0.06))
	_circle(img, int(center.x - width * 0.28), int(center.y), int(height * 0.23), Color8(6, 8, 8))

func _sight(img: Image, pos: Vector2, accent: Color) -> void:
	_panel(img, [pos + Vector2(-26, 8), pos + Vector2(-12, -8), pos + Vector2(24, -4), pos + Vector2(32, 11), pos + Vector2(4, 16)], Color8(28, 32, 34))
	_rect(img, int(pos.x - 6), int(pos.y - 1), 22, 5, accent)

func _bolts(img: Image, pts: Array, accent: Color) -> void:
	for p in pts:
		_rect(img, int(p.x - 3), int(p.y - 3), 6, 6, Color8(18, 22, 24))
		_rect(img, int(p.x - 2), int(p.y - 2), 4, 4, accent)

func _panel_lines(img: Image, pts: Array, color: Color) -> void:
	for p in pts:
		_line(img, int(p.x), int(p.y), int(p.x + 38), int(p.y - 5), color, 2)

func _flame(img: Image, pos: Vector2, color: Color) -> void:
	_panel(img, [pos, pos + Vector2(52, -44), pos + Vector2(38, 4), pos + Vector2(72, 26), pos + Vector2(18, 38)], color)
	_panel(img, [pos + Vector2(10, 6), pos + Vector2(44, -18), pos + Vector2(34, 12), pos + Vector2(52, 28), pos + Vector2(18, 26)], Color8(255, 220, 72))

func _rect(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			_blend(img, xx, yy, color)

func _circle(img: Image, cx: int, cy: int, r: int, color: Color) -> void:
	for yy in range(cy - r, cy + r + 1):
		for xx in range(cx - r, cx + r + 1):
			if Vector2(xx - cx, yy - cy).length_squared() <= r * r:
				_blend(img, xx, yy, color)

func _shadow(img: Image, center: Vector2, radius: Vector2, color: Color) -> void:
	for yy in range(int(center.y - radius.y), int(center.y + radius.y) + 1):
		for xx in range(int(center.x - radius.x), int(center.x + radius.x) + 1):
			var dx = (float(xx) - center.x) / max(1.0, radius.x)
			var dy = (float(yy) - center.y) / max(1.0, radius.y)
			var d = dx * dx + dy * dy
			if d <= 1.0:
				var c = Color(color.r, color.g, color.b, color.a * (1.0 - d))
				_blend(img, xx, yy, c)

func _line(img: Image, x0: int, y0: int, x1: int, y1: int, color: Color, thickness: int = 1) -> void:
	var dx = abs(x1 - x0)
	var sx = 1 if x0 < x1 else -1
	var dy = -abs(y1 - y0)
	var sy = 1 if y0 < y1 else -1
	var err = dx + dy
	var x = x0
	var y = y0
	while true:
		_circle(img, x, y, max(0, floori(float(thickness) / 2.0)), color)
		if x == x1 and y == y1:
			break
		var e2 = 2 * err
		if e2 >= dy:
			err += dy
			x += sx
		if e2 <= dx:
			err += dx
			y += sy

func _poly(img: Image, pts: Array, color: Color) -> void:
	if pts.size() < 3:
		return
	var img_w = img.get_width()
	var img_h = img.get_height()
	var min_x = img_w
	var min_y = img_h
	var max_x = 0
	var max_y = 0
	for p in pts:
		min_x = min(min_x, int(floor(p.x)))
		min_y = min(min_y, int(floor(p.y)))
		max_x = max(max_x, int(ceil(p.x)))
		max_y = max(max_y, int(ceil(p.y)))
	for y in range(max(0, min_y), min(img_h, max_y + 1)):
		for x in range(max(0, min_x), min(img_w, max_x + 1)):
			if _point_in_poly(Vector2(x + 0.5, y + 0.5), pts):
				_blend(img, x, y, color)

func _point_in_poly(p: Vector2, pts: Array) -> bool:
	var inside = false
	var j = pts.size() - 1
	for i in pts.size():
		var pi: Vector2 = pts[i]
		var pj: Vector2 = pts[j]
		if ((pi.y > p.y) != (pj.y > p.y)) and p.x < (pj.x - pi.x) * (p.y - pi.y) / max(0.001, pj.y - pi.y) + pi.x:
			inside = not inside
		j = i
	return inside

func _blend(img: Image, x: int, y: int, color: Color) -> void:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height() or color.a <= 0.0:
		return
	var dst = img.get_pixel(x, y)
	var a = color.a + dst.a * (1.0 - color.a)
	if a <= 0.001:
		img.set_pixel(x, y, Color(0, 0, 0, 0))
		return
	var r = (color.r * color.a + dst.r * dst.a * (1.0 - color.a)) / a
	var g = (color.g * color.a + dst.g * dst.a * (1.0 - color.a)) / a
	var b = (color.b * color.a + dst.b * dst.a * (1.0 - color.a)) / a
	img.set_pixel(x, y, Color(r, g, b, a))
