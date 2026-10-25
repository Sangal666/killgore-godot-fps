extends Control
class_name HUDController

const GameDataScript = preload("res://scripts/core/GameData.gd")
const GameSettingsScript = preload("res://scripts/core/GameSettings.gd")

var player
var weapons
var level_manager
var asset_factory
var audio_manager
var sol_manager
var boss_current = 0
var boss_max = 1
var boss_visible = false
var message_text = ""
var message_timer = 0.0
var minimap_visible = true
var horror_map_open = false
var options_open = false
var option_index = 0
var settings := {}
var option_tab = 0
var option_tab_names = ["GAMEPLAY", "VISUAL/PERF"]
var pause_buttons: Array = []
var option_buttons: Array = []
var overlay_buttons: Array = []
var draw_weapon_state: Dictionary = {}
var option_pages = [
	["master_volume", "sfx_volume", "music_volume", "mouse_sensitivity", "screen_shake", "fullscreen", "no_gun_mode", "legacy_weapon_models", "developer_mode", "back"],
	["fps_limit", "vsync", "weather_quality", "vfx_quality", "back"]
]

func configure(player_node, weapon_manager, lm, factory, audio = null, sol = null) -> void:
	player = player_node
	weapons = weapon_manager
	level_manager = lm
	asset_factory = factory
	audio_manager = audio
	sol_manager = sol
	settings = GameSettingsScript.load_settings()
	_apply_settings()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func _process(delta: float) -> void:
	message_timer = max(0.0, message_timer - delta)
	if level_manager != null and not GameDataScript.is_horror_sequence_level(level_manager.level_index):
		horror_map_open = false
	mouse_filter = Control.MOUSE_FILTER_STOP if player != null and player.paused else Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _input(event: InputEvent) -> void:
	if player != null and player.paused and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_mouse_click(event.position)
		accept_event()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var sol_state = _sol_state()
		if player != null and player.paused and bool(sol_state.get("choice_open", false)):
			if event.keycode >= KEY_1 and event.keycode <= KEY_3:
				if sol_manager != null:
					sol_manager.choose(event.keycode - KEY_1)
				accept_event()
			return
		if player != null and player.paused:
			var paused_state = weapons.state()
			if event.keycode == KEY_ESCAPE and (String(paused_state.get("pending_weapon_pickup", "")) != "" or bool(paused_state.get("locker_open", false))):
				weapons.close_loadout_overlay()
				accept_event()
				return
			if event.keycode == KEY_O:
				options_open = not options_open
				accept_event()
				return
			if event.keycode == KEY_M and not options_open:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				get_tree().change_scene_to_file("res://scenes/ui/Menu.tscn")
				accept_event()
				return
			if options_open:
				var keys = _current_option_keys()
				if event.keycode == KEY_TAB:
					option_tab = (option_tab + 1) % option_pages.size()
					option_index = 0
					accept_event()
				elif event.keycode == KEY_UP:
					option_index = (option_index - 1 + keys.size()) % keys.size()
					accept_event()
				elif event.keycode == KEY_DOWN:
					option_index = (option_index + 1) % keys.size()
					accept_event()
				elif event.keycode == KEY_LEFT:
					_change_option(-1.0)
					accept_event()
				elif event.keycode == KEY_RIGHT:
					_change_option(1.0)
					accept_event()
				elif event.keycode == KEY_ENTER:
					_change_option(1.0)
					accept_event()
				return
		if player != null and not player.paused and event.keycode == KEY_M and level_manager != null and GameDataScript.is_horror_sequence_level(level_manager.level_index):
			horror_map_open = not horror_map_open
			accept_event()
			return
		if event.keycode == KEY_TAB and not options_open:
			minimap_visible = not minimap_visible

func show_message(text: String) -> void:
	message_text = text
	message_timer = 1.2

func set_boss(current: int, maximum: int, is_visible: bool) -> void:
	boss_current = current
	boss_max = max(1, maximum)
	boss_visible = is_visible

func _draw() -> void:
	if player == null or weapons == null:
		return
	draw_weapon_state = weapons.state()
	pause_buttons.clear()
	option_buttons.clear()
	overlay_buttons.clear()
	var screen_size = get_viewport_rect().size
	_draw_overlays(screen_size)
	var sol_state = _sol_state()
	if player.paused:
		var state = draw_weapon_state
		if bool(sol_state.get("choice_open", false)):
			_draw_sol_choice_overlay(screen_size, sol_state)
		elif String(state.get("pending_weapon_pickup", "")) != "":
			_draw_replacement_overlay(screen_size, state)
		elif bool(state.get("locker_open", false)):
			_draw_locker_overlay(screen_size, state)
		else:
			_draw_pause_menu(screen_size)
	else:
		var horror_level = GameDataScript.is_horror_sequence_level(level_manager.level_index)
		if horror_level and horror_map_open:
			_draw_horror_map(screen_size)
		else:
			if minimap_visible and not horror_level:
				_draw_minimap(screen_size)
			if not horror_level:
				_draw_crosshair(screen_size)
			_draw_objective(screen_size)
			_draw_interact_prompt(screen_size)
			if horror_level:
				_draw_horror_hud(screen_size)
			else:
				_draw_modern_hud(screen_size)
		if bool(sol_state.get("line_visible", false)):
			_draw_sol_line(screen_size, sol_state)
	if boss_visible:
		_draw_boss_bar(screen_size)
	_draw_miniboss_bars(screen_size)
	_draw_fps_counter(screen_size)
	if message_timer > 0.0:
		_draw_center_message(screen_size)

func _draw_modern_hud(screen_size: Vector2) -> void:
	var font = ThemeDB.fallback_font
	var state = draw_weapon_state
	var weapon = state.weapon
	var compact = screen_size.x < 900.0
	var amber = Color8(232, 198, 58)
	var soft = Color(0.03, 0.035, 0.045, 0.50)
	var line = Color(0.78, 0.82, 0.78, 0.32)
	var hp_color = Color8(255, 220, 68) if player.hp > 35 else Color8(255, 92, 72)
	var hp_size = 42 if not compact else 32
	draw_string(font, Vector2(28, screen_size.y - 34), "%d" % player.hp, HORIZONTAL_ALIGNMENT_LEFT, 120, hp_size, hp_color)
	draw_string(font, Vector2(32, screen_size.y - 76), player.character_name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 180, 17, Color(0.94, 0.90, 0.70, 0.70))
	draw_string(font, Vector2(122, screen_size.y - 39), "%d" % int(player.armor), HORIZONTAL_ALIGNMENT_LEFT, 70, 18, Color8(116, 202, 255))
	var dash_ratio = 1.0 - min(1.0, player.dash_cooldown / max(0.01, player.dash_total))
	var dash_y = screen_size.y - 92
	draw_rect(Rect2(30, dash_y, 132, 4), Color(0.04, 0.05, 0.06, 0.62))
	draw_rect(Rect2(30, dash_y, 132 * dash_ratio, 4), Color8(82, 190, 255))
	draw_string(font, Vector2(30, dash_y - 8), "SLIDE", HORIZONTAL_ALIGNMENT_LEFT, 70, 11, Color(0.62, 0.84, 1.0, 0.80))
	_draw_power_chips(Vector2(30, dash_y - 42))

	var ammo_w = 190.0 if not compact else 146.0
	var ammo_x = screen_size.x - ammo_w - 34.0
	var ammo_y = screen_size.y - 104.0
	draw_rect(Rect2(ammo_x, ammo_y, ammo_w, 76), soft)
	draw_rect(Rect2(ammo_x, ammo_y, ammo_w, 76), line, false, 1)
	draw_string(font, Vector2(ammo_x + 12, ammo_y + 20), _fit(weapon.display_name, 18), HORIZONTAL_ALIGNMENT_LEFT, ammo_w - 24, 16, weapon.color.lightened(0.38))
	draw_string(font, Vector2(ammo_x + 12, ammo_y + 61), state.ammo_text, HORIZONTAL_ALIGNMENT_LEFT, ammo_w - 74, 33 if not compact else 26, amber)
	_draw_grenade_icon(Vector2(ammo_x + ammo_w - 46, ammo_y + 50), Color8(170, 245, 170))
	draw_string(font, Vector2(ammo_x + ammo_w - 28, ammo_y + 62), "%d" % state.grenades, HORIZONTAL_ALIGNMENT_RIGHT, 24, 18, Color8(170, 245, 170))
	draw_string(font, Vector2(ammo_x + ammo_w - 58, ammo_y + 28), _bomb_symbol(String(state.get("bomb_type", "frag"))), HORIZONTAL_ALIGNMENT_CENTER, 54, 14, Color8(170, 245, 170))
	_draw_weapon_slots(Vector2(ammo_x, ammo_y - 36), ammo_w, state)

	var info_y = 284.0 if minimap_visible else 28.0
	var info_x = screen_size.x - 330.0
	if info_x < screen_size.x * 0.56:
		info_x = screen_size.x - 318.0
	var trench_level = GameDataScript.is_trench_map_level(level_manager.level_index)
	var ramp_level = GameDataScript.is_ramp_test_level(level_manager.level_index)
	var key_text = "EXIT" if trench_level or ramp_level else ("KEY HELD" if level_manager.key_status() else ("MATERIALIZED" if bool(level_manager.key_spawned) else "NOT YET"))
	var level_label = "MAP V2" if trench_level else ("RAMP" if ramp_level else ("TRAIN" if level_manager.level_index == 0 else ("ALGORE" if level_manager.level_index == GameDataScript.LEVELS.size() - 1 else "LEVEL %d" % level_manager.level_index)))
	_draw_float_chip(Rect2(info_x, info_y, 74, 26), level_label, Color8(255, 220, 82))
	_draw_float_chip(Rect2(info_x + 82, info_y, 118, 26), key_text, Color8(255, 220, 82) if bool(level_manager.key_spawned) or level_manager.key_status() else Color8(190, 190, 190))
	_draw_float_chip(Rect2(info_x + 208, info_y, 106, 26), "ENEMY %d" % level_manager.enemy_count(), Color8(255, 172, 172))
	if ramp_level:
		_draw_ramp_timer(Rect2(info_x, info_y - 34, 170, 26))

func _draw_horror_hud(screen_size: Vector2) -> void:
	var font = ThemeDB.fallback_font
	var status = level_manager.horror_fragment_status()
	var current = int(status.get("current", 0))
	var total = int(status.get("total", 3))
	var pale = Color8(189, 198, 179)
	var dim = Color(0.65, 0.68, 0.62, 0.62)
	var panel = Rect2(26, screen_size.y - 82, 214, 48)
	draw_rect(panel, Color(0.015, 0.018, 0.017, 0.68))
	draw_rect(panel, Color(0.52, 0.58, 0.50, 0.24), false, 1)
	draw_string(font, panel.position + Vector2(12, 21), "MEMORY", HORIZONTAL_ALIGNMENT_LEFT, 100, 13, dim)
	draw_string(font, panel.position + Vector2(112, 32), "%d / %d" % [current, total], HORIZONTAL_ALIGNMENT_RIGHT, 86, 25, pale)
	var flashlight_heat = player.horror_flashlight_heat_ratio() if player.has_method("horror_flashlight_heat_ratio") else 0.0
	var flashlight_text = "F  FLASHLIGHT  OFF"
	if player.horror_battery_ratio() <= 0.0:
		flashlight_text = "F  FLASHLIGHT  EMPTY"
	elif bool(player.flashlight_on):
		flashlight_text = "F  FLASHLIGHT  STRAINED" if flashlight_heat > 0.72 else "F  FLASHLIGHT  ON"
	var flashlight_color = Color8(227, 151, 73) if flashlight_heat > 0.72 else (Color8(204, 201, 174) if bool(player.flashlight_on) else Color8(146, 55, 46))
	draw_string(font, Vector2(30, screen_size.y - 96), flashlight_text, HORIZONTAL_ALIGNMENT_LEFT, 220, 12, flashlight_color)
	var battery_ratio: float = player.horror_battery_ratio()
	var battery_color = Color8(205, 184, 121) if battery_ratio > 0.20 else Color8(195, 73, 51)
	var battery_rect := Rect2(26, screen_size.y - 151, 70, 9)
	draw_rect(battery_rect, Color(0.02, 0.025, 0.023, 0.86))
	draw_rect(Rect2(battery_rect.position, Vector2(70 * battery_ratio, 9)), battery_color)
	draw_rect(battery_rect.grow(2), battery_color, false, 1)
	draw_rect(Rect2(98, screen_size.y - 149, 3, 5), battery_color)
	draw_string(font, Vector2(108, screen_size.y - 142), "%d%%" % ceili(battery_ratio * 100), HORIZONTAL_ALIGNMENT_LEFT, 45, 11, battery_color)
	var stamina_ratio = player.horror_stamina_ratio() if player.has_method("horror_stamina_ratio") else 1.0
	var stamina_rect = Rect2(26, screen_size.y - 119, 214, 7)
	draw_rect(stamina_rect, Color(0.02, 0.025, 0.023, 0.86))
	draw_rect(Rect2(stamina_rect.position, Vector2(stamina_rect.size.x * stamina_ratio, stamina_rect.size.y)), Color8(184, 157, 91))
	draw_string(font, Vector2(30, screen_size.y - 123), "SHIFT  SPRINT", HORIZONTAL_ALIGNMENT_LEFT, 126, 10, dim)
	if bool(player.horror_hidden):
		var hidden_text = "E  LEAVE LOCKER"
		draw_string(font, Vector2(screen_size.x * 0.5 - 150.0, screen_size.y - 42.0), hidden_text, HORIZONTAL_ALIGNMENT_CENTER, 300, 15, Color8(183, 202, 190))
	draw_string(font, Vector2(screen_size.x - 160, screen_size.y - 62), "M  FACILITY MAP", HORIZONTAL_ALIGNMENT_RIGHT, 130, 11, dim)
	draw_string(font, Vector2(screen_size.x - 116, screen_size.y - 38), "%d" % player.hp, HORIZONTAL_ALIGNMENT_RIGHT, 86, 23, Color8(192, 194, 177))

func _draw_horror_map(screen_size: Vector2) -> void:
	if level_manager == null or level_manager.game_map.is_empty():
		return
	var font = ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, screen_size), Color(0.006, 0.009, 0.009, 0.965))
	var grid: Array = level_manager.game_map
	var rows = grid.size()
	var cols = grid[0].size() if rows > 0 else 0
	if rows <= 0 or cols <= 0:
		return
	var available = Vector2(screen_size.x - 150.0, screen_size.y - 126.0)
	var cell_size = max(2.0, min(available.x / float(cols), available.y / float(rows)))
	var map_size = Vector2(float(cols) * cell_size, float(rows) * cell_size)
	var map_origin = (screen_size - map_size) * 0.5 + Vector2(0, 16)
	var frame = Rect2(map_origin - Vector2(14, 14), map_size + Vector2(28, 28))
	draw_rect(frame, Color(0.018, 0.023, 0.022, 0.98))
	draw_rect(frame, Color(0.46, 0.51, 0.46, 0.52), false, 2.0)
	var wall_color = Color(0.105, 0.115, 0.108, 1.0)
	var corridor_color = Color(0.035, 0.045, 0.042, 1.0)
	draw_rect(Rect2(map_origin, map_size), wall_color)
	for row_index in rows:
		var row = grid[row_index]
		var run_start = -1
		for col_index in range(cols + 1):
			var is_open = col_index < cols and String(row[col_index]) != "#"
			if is_open and run_start < 0:
				run_start = col_index
			elif not is_open and run_start >= 0:
				var run_width = float(col_index - run_start) * cell_size
				draw_rect(Rect2(map_origin + Vector2(float(run_start) * cell_size, float(row_index) * cell_size), Vector2(run_width, cell_size)), corridor_color)
				run_start = -1
	var map_data = level_manager.horror_map_data() if level_manager.has_method("horror_map_data") else {}
	for task in map_data.get("tasks", []):
		var task_position: Vector3 = task.get("position", Vector3.ZERO)
		var task_point = map_origin + Vector2(task_position.x / GameDataScript.TILE + 0.5, task_position.z / GameDataScript.TILE + 0.5) * cell_size
		var task_complete = bool(task.get("complete", false))
		var task_color = Color8(105, 154, 132) if task_complete else Color8(196, 151, 75)
		var task_id = String(task.get("id", "?"))
		var task_letter = {"kitchen": "K", "car": "C", "passport": "P"}.get(task_id, "?")
		draw_circle(task_point, max(5.0, cell_size * 0.58), Color(task_color.r, task_color.g, task_color.b, 0.22))
		draw_arc(task_point, max(6.0, cell_size * 0.72), 0.0, TAU, 16, task_color, 1.5)
		draw_string(font, task_point + Vector2(-4, 4), task_letter, HORIZONTAL_ALIGNMENT_CENTER, 8, 9, task_color)
	for fragment_position in map_data.get("fragments", []):
		var fragment_point = map_origin + Vector2(fragment_position.x / GameDataScript.TILE + 0.5, fragment_position.z / GameDataScript.TILE + 0.5) * cell_size
		draw_circle(fragment_point, max(3.0, cell_size * 0.38), Color8(230, 192, 94))
		draw_arc(fragment_point, max(5.0, cell_size * 0.62), 0.0, TAU, 16, Color(1.0, 0.80, 0.34, 0.54), 1.0)
	var exit_position: Vector3 = map_data.get("exit", level_manager.exit_pos)
	var exit_point = map_origin + Vector2(exit_position.x / GameDataScript.TILE + 0.5, exit_position.z / GameDataScript.TILE + 0.5) * cell_size
	var exit_color = Color8(126, 202, 143) if bool(map_data.get("exit_open", false)) else Color8(181, 69, 61)
	var exit_size = max(6.0, cell_size * 0.85)
	draw_rect(Rect2(exit_point - Vector2.ONE * exit_size * 0.5, Vector2.ONE * exit_size), exit_color, false, 2.0)
	var monster_marker: Dictionary = map_data.get("monster", {})
	if not monster_marker.is_empty():
		var monster_position: Vector3 = monster_marker.get("position", Vector3.ZERO)
		var monster_point = map_origin + Vector2(monster_position.x / GameDataScript.TILE + 0.5, monster_position.z / GameDataScript.TILE + 0.5) * cell_size
		var threat_color = Color8(205, 63, 55)
		var threat_pulse = 1.0 + sin(Time.get_ticks_msec() * 0.008) * 0.12
		var threat_radius = max(7.0, cell_size * 0.92) * threat_pulse
		draw_circle(monster_point, threat_radius, Color(threat_color.r, threat_color.g, threat_color.b, 0.18))
		draw_arc(monster_point, threat_radius, 0.0, TAU, 20, threat_color, 2.0)
		draw_line(monster_point + Vector2(-4, -4), monster_point + Vector2(4, 4), threat_color, 2.0)
		draw_line(monster_point + Vector2(4, -4), monster_point + Vector2(-4, 4), threat_color, 2.0)
	var player_point = map_origin + Vector2(player.global_position.x / GameDataScript.TILE + 0.5, player.global_position.z / GameDataScript.TILE + 0.5) * cell_size
	var aim = player.aim_dir()
	var map_direction = Vector2(aim.x, aim.z).normalized()
	if map_direction.length_squared() < 0.01:
		map_direction = Vector2(0, -1)
	var arrow_size = max(7.0, cell_size * 1.25)
	var side = Vector2(-map_direction.y, map_direction.x)
	var arrow = PackedVector2Array([
		player_point + map_direction * arrow_size,
		player_point - map_direction * arrow_size * 0.60 + side * arrow_size * 0.52,
		player_point - map_direction * arrow_size * 0.60 - side * arrow_size * 0.52
	])
	draw_colored_polygon(arrow, Color8(114, 219, 204))
	draw_polyline(PackedVector2Array([arrow[0], arrow[1], arrow[2], arrow[0]]), Color(0.78, 1.0, 0.94, 0.92), 1.5)
	draw_string(font, Vector2(44, 48), "FACILITY MEMORY PLAN", HORIZONTAL_ALIGNMENT_LEFT, 360, 20, Color8(190, 199, 181))
	var remaining = map_data.get("fragments", []).size()
	draw_string(font, Vector2(44, screen_size.y - 30), "M  CLOSE      MEMORY SIGNALS  %d      EXIT  %s" % [remaining, "OPEN" if bool(map_data.get("exit_open", false)) else "LOCKED"], HORIZONTAL_ALIGNMENT_LEFT, screen_size.x - 88, 13, Color(0.68, 0.72, 0.66, 0.84))

func _draw_grenade_icon(pos: Vector2, color: Color) -> void:
	draw_circle(pos + Vector2(6, 8), 7.0, Color(0.04, 0.10, 0.06, 0.72))
	draw_circle(pos + Vector2(6, 8), 5.0, Color(color.r, color.g, color.b, 0.36))
	draw_rect(Rect2(pos + Vector2(3, -1), Vector2(7, 5)), Color(0.05, 0.08, 0.06, 0.86))
	draw_line(pos + Vector2(9, 0), pos + Vector2(15, 4), color, 2)

func _draw_objective(screen_size: Vector2) -> void:
	if level_manager == null:
		return
	var font = ThemeDB.fallback_font
	var text = ""
	if level_manager.level_index == 0:
		text = "Training: clear enemies to materialize the key. ESC: controls"
	elif GameDataScript.is_horror_sequence_level(level_manager.level_index):
		var status = level_manager.horror_fragment_status()
		text = String(status.get("objective", "Recover the memory fragments"))
	elif GameDataScript.is_trench_map_level(level_manager.level_index):
		text = "Reach the green exit"
	elif GameDataScript.is_ramp_test_level(level_manager.level_index):
		text = "Survive the slide, then ride to the green exit"
	elif level_manager.level_index == GameDataScript.LEVELS.size() - 1:
		text = "Kill Algore, then use the exit"
	elif level_manager.key_status():
		text = "Open the green exit room"
	elif bool(level_manager.key_spawned):
		text = "Take the gold key"
	elif bool(level_manager.key_pending):
		text = "Clear enemies to reveal the key"
	else:
		text = "Find the key"
	var w = min(screen_size.x - 360.0, 840.0)
	if w < 320.0:
		w = screen_size.x - 56.0
	var pos = Vector2(28.0, 28.0)
	draw_rect(Rect2(pos - Vector2(10, 18), Vector2(w + 20, 34)), Color(0.02, 0.025, 0.03, 0.42))
	draw_rect(Rect2(pos - Vector2(10, 18), Vector2(w + 20, 34)), Color(0.95, 0.78, 0.24, 0.20), false, 1)
	draw_string(font, pos + Vector2(0, 4), _fit(text, int(w / 8.0)), HORIZONTAL_ALIGNMENT_LEFT, w, 14, Color8(240, 220, 150))

func _draw_ramp_timer(rect: Rect2) -> void:
	var font = ThemeDB.fallback_font
	var open = bool(level_manager.get("ramp_exit_available"))
	var label = "EXIT OPEN"
	if not open:
		var left = max(0.0, 180.0 - float(level_manager.get("ramp_survival_time")))
		var minutes = floori(left / 60.0)
		var seconds = floori(fmod(left, 60.0))
		label = "SURVIVE %02d:%02d" % [minutes, seconds]
	draw_rect(rect, Color(0.02, 0.025, 0.03, 0.56))
	draw_rect(rect, Color(0.95, 0.78, 0.24, 0.30), false, 1)
	draw_string(font, rect.position + Vector2(9, 18), label, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 18, 14, Color8(255, 220, 92))

func _draw_power_chips(origin: Vector2) -> void:
	var active = player.powerups.timers
	if active.is_empty():
		return
	var font = ThemeDB.fallback_font
	var x = origin.x
	for key in active.keys():
		var remaining = float(active[key])
		if remaining <= 0.0:
			continue
		var label = key.substr(0, 3).to_upper()
		var color = Color8(255, 70, 70)
		if key == "haste":
			color = Color8(110, 215, 255)
		elif key == "shield":
			color = Color8(126, 245, 160)
		draw_rect(Rect2(x, origin.y, 76, 24), Color(0.03, 0.04, 0.05, 0.54))
		draw_rect(Rect2(x, origin.y, 76, 24), Color(color.r, color.g, color.b, 0.38), false, 1)
		draw_string(font, Vector2(x + 8, origin.y + 17), "%s %.0f" % [label, remaining], HORIZONTAL_ALIGNMENT_LEFT, 62, 13, color)
		x += 82

func _draw_weapon_slots(origin: Vector2, width: float, state: Dictionary) -> void:
	var font = ThemeDB.fallback_font
	var carried: Array = state.get("carried_weapons", [])
	var count = max(1, carried.size())
	var cell = min(28.0, max(22.0, (width - 12.0) / float(count)))
	for i in carried.size():
		var id = String(carried[i])
		var unlocked = state.unlocked.has(id)
		var selected = id == state.weapon_id
		var x = origin.x + i * (cell + 4.0)
		var fill = Color(0.05, 0.055, 0.065, 0.58)
		if selected:
			fill = Color(0.82, 0.62, 0.18, 0.72)
		elif unlocked:
			fill = Color(0.18, 0.20, 0.22, 0.60)
		draw_rect(Rect2(x, origin.y, cell, 22), fill)
		draw_rect(Rect2(x, origin.y, cell, 22), Color(0.78, 0.80, 0.78, 0.34), false, 1)
		draw_string(font, Vector2(x + 5, origin.y + 16), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, cell, 12, Color.WHITE if unlocked else Color(0.6, 0.6, 0.6, 0.54))

func _bomb_symbol(kind: String) -> String:
	match kind:
		"incendiary":
			return "FIRE"
		"cryo":
			return "ICE"
		"toxic":
			return "TOX"
		"shock":
			return "SHK"
		"cluster":
			return "CLU"
		_:
			return "FRAG"

func _draw_interact_prompt(screen_size: Vector2) -> void:
	if level_manager == null or not level_manager.has_method("weapon_pickup_prompt"):
		return
	var text = level_manager.weapon_pickup_prompt()
	if text == "":
		return
	var font = ThemeDB.fallback_font
	var w = min(420.0, screen_size.x - 80.0)
	var pos = Vector2(screen_size.x * 0.5 - w * 0.5, screen_size.y * 0.62)
	draw_rect(Rect2(pos, Vector2(w, 30)), Color(0.02, 0.025, 0.03, 0.56))
	draw_rect(Rect2(pos, Vector2(w, 30)), Color(0.95, 0.78, 0.24, 0.34), false, 1.4)
	draw_string(font, pos + Vector2(0, 21), _fit(text, 36), HORIZONTAL_ALIGNMENT_CENTER, w, 17, Color8(245, 220, 150))

func _draw_compass(origin: Vector2) -> void:
	var font = ThemeDB.fallback_font
	var dirs = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
	var idx = int(round(fposmod(rad_to_deg(player.yaw), 360.0) / 45.0)) % dirs.size()
	var center = dirs[idx]
	var left = dirs[(idx - 1 + dirs.size()) % dirs.size()]
	var right = dirs[(idx + 1) % dirs.size()]
	draw_string(font, origin + Vector2(0, 18), left, HORIZONTAL_ALIGNMENT_CENTER, 62, 15, Color(0.95, 0.78, 0.26, 0.58))
	draw_string(font, origin + Vector2(58, 20), center, HORIZONTAL_ALIGNMENT_CENTER, 74, 20, Color8(232, 198, 58))
	draw_string(font, origin + Vector2(130, 18), right, HORIZONTAL_ALIGNMENT_CENTER, 62, 15, Color(0.95, 0.78, 0.26, 0.58))
	draw_line(origin + Vector2(90, 22), origin + Vector2(102, 22), Color(0.95, 0.78, 0.26, 0.54), 2)

func _draw_float_chip(rect: Rect2, text: String, color: Color) -> void:
	draw_rect(rect, Color(0.03, 0.035, 0.045, 0.48))
	draw_rect(rect, Color(color.r, color.g, color.b, 0.28), false, 1)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(7, 18), text, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 12, 13, color)

func _draw_panel(screen_size: Vector2) -> void:
	var font = ThemeDB.fallback_font
	var hud_h = 118.0
	var y = screen_size.y - hud_h
	draw_rect(Rect2(0, y, screen_size.x, hud_h), Color8(34, 34, 38))
	draw_rect(Rect2(0, y, screen_size.x, 7), Color8(116, 112, 104))
	draw_rect(Rect2(0, y + 7, screen_size.x, 2), Color8(18, 18, 20))
	var state = draw_weapon_state
	draw_string(font, Vector2(18, y + 108), player.character_name, HORIZONTAL_ALIGNMENT_LEFT, 140, 18, Color8(238, 210, 160))
	_panel_box(Vector2(14, y + 18), Vector2(94, 58), "HP", "%d%%" % player.hp, Color8(115, 245, 120) if player.hp > 55 else (Color8(255, 212, 82) if player.hp > 25 else Color8(255, 82, 72)))
	_panel_box(Vector2(116, y + 18), Vector2(132, 58), "AMMO", state.ammo_text, Color8(255, 218, 92))
	_panel_box(Vector2(256, y + 18), Vector2(78, 58), "GREN", str(state.grenades), Color8(190, 245, 190))
	_panel_box(Vector2(342, y + 18), Vector2(104, 58), "SLIDE", "READY" if player.dash_cooldown <= 0.0 else "WAIT", Color8(165, 220, 255))
	var ratio = 1.0 - min(1.0, player.dash_cooldown / max(0.01, player.dash_total))
	draw_rect(Rect2(352, y + 82, 84, 9), Color8(20, 28, 34))
	draw_rect(Rect2(352, y + 82, 84 * ratio, 9), Color8(96, 190, 255))
	_draw_face(Vector2(screen_size.x * 0.5, y + 63), player.hp)
	var right_x = max(540.0, screen_size.x - 414.0)
	var weapon = state.weapon
	_panel_box(Vector2(right_x, y + 18), Vector2(156, 58), "WEAPON", _fit(weapon.display_name, 15), weapon.color.lightened(0.25))
	_panel_box(Vector2(right_x + 164, y + 18), Vector2(102, 58), "POWER", player.powerups.active_text(), Color8(218, 218, 218))
	_panel_box(Vector2(right_x + 274, y + 18), Vector2(58, 58), "LVL", str(level_manager.level_index + 1), Color8(255, 218, 92))
	_panel_box(Vector2(right_x + 340, y + 18), Vector2(60, 58), "KEY", "YES" if level_manager.key_status() else "NO", Color8(255, 220, 75) if level_manager.key_status() else Color8(170, 170, 170))
	draw_string(font, Vector2(right_x, y + 96), "ENEMY %d" % level_manager.enemy_count(), HORIZONTAL_ALIGNMENT_LEFT, 148, 17, Color8(245, 190, 190))
	draw_string(font, Vector2(right_x + 84, y + 96), "JUMP %s" % ("READY" if player.grounded else "AIR"), HORIZONTAL_ALIGNMENT_LEFT, 100, 17, Color8(180, 220, 255))
	for i in GameDataScript.WEAPON_ORDER.size():
		var id = GameDataScript.WEAPON_ORDER[i]
		var x = right_x + 158 + i * 27
		var unlocked = state.unlocked.has(id)
		var selected = id == state.weapon_id
		draw_rect(Rect2(x, y + 86, 22, 22), Color8(172, 132, 52) if selected else (Color8(72, 72, 76) if unlocked else Color8(32, 32, 34)))
		draw_rect(Rect2(x, y + 86, 22, 22), Color8(154, 154, 154), false, 1)
		draw_string(font, Vector2(x + 6, y + 103), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, 20, 14, Color.WHITE if unlocked else Color8(96, 96, 96))

func _panel_box(pos: Vector2, box_size: Vector2, label: String, value: String, accent: Color) -> void:
	var font = ThemeDB.fallback_font
	draw_rect(Rect2(pos, box_size), Color8(54, 54, 58))
	draw_rect(Rect2(pos + Vector2(3, 3), box_size - Vector2(6, 6)), Color8(24, 24, 27))
	draw_rect(Rect2(pos, box_size), Color8(108, 108, 112), false, 1)
	draw_string(font, pos + Vector2(8, 18), label, HORIZONTAL_ALIGNMENT_LEFT, box_size.x - 12, 13, Color8(205, 205, 205))
	draw_string(font, pos + Vector2(8, 43), value, HORIZONTAL_ALIGNMENT_LEFT, box_size.x - 12, 19 if value.length() < 11 else 15, accent)

func _draw_face(center: Vector2, hp: int) -> void:
	var face = Color8(222, 162, 118) if hp > 35 else Color8(210, 112, 104)
	draw_rect(Rect2(center.x - 43, center.y - 37, 86, 74), Color8(42, 42, 45))
	draw_rect(Rect2(center.x - 43, center.y - 37, 86, 74), Color8(118, 118, 122), false, 2)
	draw_circle(center, 29, face)
	draw_rect(Rect2(center.x - 24, center.y - 25, 48, 12), Color8(120, 78, 48))
	draw_circle(center + Vector2(-11, -4), 4, Color8(18, 18, 18))
	draw_circle(center + Vector2(11, -4), 4, Color8(18, 18, 18))
	if hp > 55:
		draw_rect(Rect2(center.x - 13, center.y + 14, 26, 5), Color8(85, 25, 25))
	else:
		draw_line(center + Vector2(-14, 18), center + Vector2(0, 12), Color8(85, 25, 25), 3)
		draw_line(center + Vector2(0, 12), center + Vector2(14, 18), Color8(85, 25, 25), 3)

func _draw_weapon_view(screen_size: Vector2) -> void:
	var state = draw_weapon_state
	var weapon = state.weapon
	var bob = sin(Time.get_ticks_msec() * 0.010) * 6.0
	var recoil = 30.0 * weapons.recoil_kick
	var cx = screen_size.x * 0.5
	var base_y = screen_size.y - 80 + bob + recoil
	var c = weapon.color
	var dark = c.darkened(0.45)
	var metal = Color8(34, 34, 40)
	if state.weapon_id == "whip":
		draw_rect(Rect2(cx + 52, base_y - 20, 32, 118), Color8(78, 42, 30))
		var points = PackedVector2Array()
		for i in 9:
			var t = float(i) / 8.0
			points.append(Vector2(cx + 70 - t * 235, base_y - 78 - sin(t * PI + weapons.fire_flash_timer * 5.0) * 92))
		draw_polyline(points, c.lightened(0.3), 7)
	elif state.weapon_id == "shotgun":
		_draw_gun_rect(cx, base_y, 210, 40, dark, c, metal)
		draw_rect(Rect2(cx - 18, base_y - 118, 36, 92), metal)
		draw_rect(Rect2(cx - 86, base_y - 36, 172, 22), Color8(74, 44, 24))
	elif state.weapon_id == "auto":
		_draw_gun_rect(cx, base_y, 160, 76, dark, c, metal)
		draw_rect(Rect2(cx - 14, base_y - 132, 28, 82), metal)
		draw_rect(Rect2(cx - 54, base_y - 8, 108, 50), c.darkened(0.2))
	elif state.weapon_id == "plasma":
		_draw_gun_rect(cx, base_y, 172, 86, Color8(12, 52, 72), c, metal)
		draw_circle(Vector2(cx, base_y - 90), 24, Color8(120, 232, 255))
		draw_rect(Rect2(cx - 11, base_y - 136, 22, 60), Color8(12, 48, 70))
	elif state.weapon_id == "heavy":
		_draw_gun_rect(cx, base_y, 230, 82, Color8(45, 45, 50), c, metal)
		draw_rect(Rect2(cx - 26, base_y - 150, 52, 116), metal)
		draw_rect(Rect2(cx - 88, base_y - 40, 176, 26), Color8(86, 86, 92))
	elif state.weapon_id == "railgun":
		_draw_gun_rect(cx, base_y, 220, 44, Color8(26, 54, 64), c, metal)
		draw_rect(Rect2(cx - 70, base_y - 78, 140, 18), c.lightened(0.2))
		draw_line(Vector2(cx - 82, base_y - 68), Vector2(cx + 82, base_y - 68), Color8(220, 252, 255), 5)
	elif state.weapon_id == "incinerator":
		_draw_gun_rect(cx, base_y, 188, 72, Color8(82, 38, 22), c, metal)
		draw_circle(Vector2(cx + 78, base_y - 72), 22, Color8(255, 178, 62))
		draw_rect(Rect2(cx - 64, base_y - 112, 128, 28), c)
	else:
		_draw_gun_rect(cx, base_y, 138, 76, dark, c, metal)
		draw_rect(Rect2(cx - 12, base_y - 122, 24, 76), metal)
	if weapons.fire_flash_timer > 0.0 and not weapon.melee:
		var flash = weapons.fire_flash_timer
		var fc = Color8(120, 232, 255) if state.weapon_id in ["plasma", "railgun"] else Color8(255, 210, 74)
		draw_circle(Vector2(cx, base_y - 136), 34 * flash, fc)
		draw_circle(Vector2(cx, base_y - 136), 15 * flash, Color8(255, 82, 28))

func _draw_gun_rect(cx: float, base_y: float, w: float, h: float, dark: Color, body: Color, metal: Color) -> void:
	draw_rect(Rect2(cx - w * 0.5, base_y - h, w, h), dark)
	draw_rect(Rect2(cx - w * 0.36, base_y - h - 38, w * 0.72, h * 0.64), body)
	draw_rect(Rect2(cx - 18, base_y - h - 92, 36, 62), metal)
	draw_rect(Rect2(cx - w * 0.22, base_y - 10, w * 0.44, 66), body.darkened(0.25))

func _draw_crosshair(screen_size: Vector2) -> void:
	var c = Color8(232, 232, 226)
	var cx = screen_size.x * 0.5
	var cy = screen_size.y * 0.5
	draw_line(Vector2(cx - 12, cy), Vector2(cx - 4, cy), c, 2)
	draw_line(Vector2(cx + 4, cy), Vector2(cx + 12, cy), c, 2)
	draw_line(Vector2(cx, cy - 12), Vector2(cx, cy - 4), c, 2)
	draw_line(Vector2(cx, cy + 4), Vector2(cx, cy + 12), c, 2)

func _draw_minimap(screen_size: Vector2) -> void:
	if level_manager == null or level_manager.game_map.is_empty():
		return
	var radius = clamp(min(screen_size.x * 0.095, screen_size.y * 0.155), 86.0, 126.0)
	var center = Vector2(screen_size.x - radius - 34.0, radius + 34.0)
	var world_range = GameDataScript.TILE * 17.0
	draw_circle(center, radius + 10.0, Color(0.02, 0.024, 0.032, 0.56))
	draw_circle(center, radius, Color(0.015, 0.018, 0.024, 0.58))
	draw_arc(center, radius, 0, TAU, 96, Color(0.76, 0.80, 0.76, 0.42), 2.0)
	draw_arc(center, radius * 0.62, 0, TAU, 72, Color(0.50, 0.62, 0.64, 0.16), 1.0)
	draw_line(center + Vector2(-radius, 0), center + Vector2(radius, 0), Color(0.55, 0.65, 0.66, 0.14), 1)
	draw_line(center + Vector2(0, -radius), center + Vector2(0, radius), Color(0.55, 0.65, 0.66, 0.14), 1)
	for a in [0.0, PI * 0.5, PI, PI * 1.5]:
		var tick = Vector2(cos(a), sin(a))
		draw_line(center + tick * (radius - 9.0), center + tick * (radius + 3.0), Color8(225, 196, 74), 2)
	var rows = level_manager.game_map.size()
	var cols = level_manager.game_map[0].size() if rows > 0 else 0
	var player_col = int(player.global_position.x / GameDataScript.TILE)
	var player_row = int(player.global_position.z / GameDataScript.TILE)
	var scan = int(ceil(world_range / GameDataScript.TILE)) + 2
	for r in range(max(0, player_row - scan), min(rows, player_row + scan + 1)):
		var row = level_manager.game_map[r]
		for c in range(max(0, player_col - scan), min(row.size(), player_col + scan + 1)):
			var tile = row[c]
			if not (tile == "#" or tile == "D" or tile == "X"):
				continue
			var pp = _radar_pos(center, radius, world_range, Vector3((float(c) + 0.5) * GameDataScript.TILE, 0, (float(r) + 0.5) * GameDataScript.TILE))
			if pp.distance_to(center) > radius - 3.0:
				continue
			var color = Color(0.45, 0.48, 0.50, 0.72)
			if tile == "D":
				color = Color(0.78, 0.48, 0.18, 0.86)
			elif tile == "X":
				color = Color(0.18, 0.90, 0.36, 0.92)
			draw_rect(Rect2(pp - Vector2(2.2, 2.2), Vector2(4.4, 4.4)), color)
	if GameDataScript.is_trench_map_level(level_manager.level_index) or GameDataScript.is_ramp_test_level(level_manager.level_index):
		var exit_pp = _radar_pos(center, radius, world_range, level_manager.exit_pos)
		if exit_pp.distance_to(center) <= radius - 6.0:
			draw_rect(Rect2(exit_pp - Vector2(4.2, 4.2), Vector2(8.4, 8.4)), Color(0.18, 0.90, 0.36, 0.92))
	for p in level_manager.pickups:
		if is_instance_valid(p):
			var pp = _radar_pos(center, radius, world_range, p.global_position)
			if pp.distance_to(center) > radius - 6.0:
				continue
			if p.kind == "key":
				_draw_radar_key(pp)
			elif p.kind == "medkit":
				_draw_radar_cross(pp)
			elif p.kind == "ammo":
				_draw_radar_box(pp, Color8(255, 220, 82))
			elif p.kind == "weapon":
				_draw_radar_weapon(pp)
			else:
				_draw_radar_diamond(pp, Color8(210, 160, 255), 4.0)
	if bool(level_manager.get("weapon_locker_active")):
		var locker_pp = _radar_pos(center, radius, world_range, level_manager.weapon_locker_pos)
		if locker_pp.distance_to(center) <= radius - 7.0:
			_draw_radar_locker(locker_pp)
	for e in level_manager.enemies:
		if is_instance_valid(e) and not e.dead:
			var pp = _radar_pos(center, radius, world_range, e.global_position)
			if pp.distance_to(center) > radius - 6.0:
				continue
			if e.stats.boss or String(e.stats.id) in ["0", "6", "7", "8", "9"]:
				_draw_radar_skull(pp, 8.6 if e.stats.boss else 6.8)
			else:
				draw_circle(pp, 2.7, Color8(225, 60, 62) if not e.stats.ranged else Color8(78, 178, 255))
	for pr in level_manager.projectiles:
		if is_instance_valid(pr):
			var pp = _radar_pos(center, radius, world_range, pr.global_position)
			if pp.distance_to(center) <= radius - 4.0:
				draw_circle(pp, 1.7, Color8(100, 220, 255))
	for gr in level_manager.grenades:
		if is_instance_valid(gr):
			var pp = _radar_pos(center, radius, world_range, gr.global_position)
			if pp.distance_to(center) <= radius - 4.0:
				draw_circle(pp, 2.3, Color8(110, 210, 110))
	var tri = PackedVector2Array([
		center + Vector2(0, -10),
		center + Vector2(6, 7),
		center + Vector2(0, 4),
		center + Vector2(-6, 7)
	])
	draw_colored_polygon(tri, Color8(86, 196, 255))
	draw_polyline(PackedVector2Array([tri[0], tri[1], tri[2], tri[3], tri[0]]), Color(0.0, 0.05, 0.08, 0.82), 1.2)

func _radar_pos(center: Vector2, radius: float, world_range: float, pos: Vector3) -> Vector2:
	var rel = Vector2(pos.x - player.global_position.x, pos.z - player.global_position.z)
	var radar_scale = (radius - 12.0) / max(1.0, world_range)
	var c = cos(player.yaw)
	var s = sin(player.yaw)
	var rotated = Vector2(rel.x * c - rel.y * s, rel.x * s + rel.y * c)
	return center + rotated * radar_scale

func _draw_radar_cross(pp: Vector2) -> void:
	draw_circle(pp, 5.7, Color(0.54, 0.03, 0.04, 0.76))
	draw_line(pp + Vector2(-3.4, 0), pp + Vector2(3.4, 0), Color8(255, 238, 238), 2)
	draw_line(pp + Vector2(0, -3.4), pp + Vector2(0, 3.4), Color8(255, 238, 238), 2)

func _draw_radar_box(pp: Vector2, color: Color) -> void:
	draw_rect(Rect2(pp - Vector2(4.8, 3.8), Vector2(9.6, 7.6)), Color(0.18, 0.13, 0.04, 0.76))
	draw_rect(Rect2(pp - Vector2(4.8, 3.8), Vector2(9.6, 7.6)), color, false, 1.2)
	draw_line(pp + Vector2(-2.6, -0.6), pp + Vector2(2.6, -0.6), color, 1)

func _draw_radar_key(pp: Vector2) -> void:
	draw_circle(pp, 10.0, Color(1.0, 0.84, 0.12, 0.20))
	draw_circle(pp + Vector2(-2.5, 0), 3.8, Color8(255, 238, 72))
	draw_line(pp + Vector2(1.5, 0), pp + Vector2(8.5, 0), Color8(255, 238, 72), 2.3)
	draw_line(pp + Vector2(6.0, 0), pp + Vector2(6.0, 3.8), Color8(255, 238, 72), 2.0)

func _draw_radar_weapon(pp: Vector2) -> void:
	var pts = PackedVector2Array([pp + Vector2(-6, 3), pp + Vector2(-1, -4), pp + Vector2(7, -1), pp + Vector2(2, 4)])
	draw_colored_polygon(pts, Color(0.02, 0.12, 0.17, 0.82))
	draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), Color8(120, 232, 255), 1.4)

func _draw_radar_locker(pp: Vector2) -> void:
	draw_rect(Rect2(pp - Vector2(6.0, 5.0), Vector2(12.0, 10.0)), Color(0.03, 0.12, 0.16, 0.82))
	draw_rect(Rect2(pp - Vector2(6.0, 5.0), Vector2(12.0, 10.0)), Color8(130, 232, 255), false, 1.4)
	for x in [-3.0, 0.0, 3.0]:
		draw_line(pp + Vector2(x, -3.0), pp + Vector2(x, 3.0), Color8(130, 232, 255), 1)

func _draw_radar_diamond(pp: Vector2, color: Color, radius: float) -> void:
	var pts = PackedVector2Array([pp + Vector2(0, -radius), pp + Vector2(radius, 0), pp + Vector2(0, radius), pp + Vector2(-radius, 0)])
	draw_colored_polygon(pts, Color(color.r, color.g, color.b, 0.36))
	draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), color, 1.2)

func _draw_radar_skull(pp: Vector2, radius: float) -> void:
	draw_circle(pp, radius, Color(0.70, 0.02, 0.02, 0.88))
	draw_circle(pp + Vector2(0, -radius * 0.10), radius * 0.58, Color8(240, 228, 208))
	draw_circle(pp + Vector2(-radius * 0.22, -radius * 0.15), radius * 0.12, Color8(20, 12, 12))
	draw_circle(pp + Vector2(radius * 0.22, -radius * 0.15), radius * 0.12, Color8(20, 12, 12))
	draw_rect(Rect2(pp.x - radius * 0.28, pp.y + radius * 0.25, radius * 0.56, radius * 0.22), Color8(240, 228, 208))
	draw_rect(Rect2(pp.x - radius * 0.07, pp.y + radius * 0.02, radius * 0.14, radius * 0.16), Color8(20, 12, 12))

func _map_pos(origin: Vector2, cell: float, pos: Vector3) -> Vector2:
	return origin + Vector2(pos.x / GameDataScript.TILE * cell, pos.z / GameDataScript.TILE * cell)

func _map_dot(origin: Vector2, cell: float, pos: Vector3, color: Color, radius: float) -> void:
	draw_circle(_map_pos(origin, cell, pos), radius, color)

func _map_cross(origin: Vector2, cell: float, pos: Vector3, color: Color, back: Color) -> void:
	var pp = _map_pos(origin, cell, pos)
	draw_circle(pp, 5.2, back)
	draw_line(pp + Vector2(-3.2, 0), pp + Vector2(3.2, 0), color, 2)
	draw_line(pp + Vector2(0, -3.2), pp + Vector2(0, 3.2), color, 2)

func _map_box(origin: Vector2, cell: float, pos: Vector3, color: Color, back: Color) -> void:
	var pp = _map_pos(origin, cell, pos)
	draw_rect(Rect2(pp - Vector2(4.5, 3.5), Vector2(9, 7)), back)
	draw_rect(Rect2(pp - Vector2(4.5, 3.5), Vector2(9, 7)), color, false, 1)
	draw_line(pp + Vector2(-2.5, -0.5), pp + Vector2(2.5, -0.5), color, 1)

func _map_key(origin: Vector2, cell: float, pos: Vector3) -> void:
	var pp = _map_pos(origin, cell, pos)
	draw_circle(pp, 8.0, Color(1.0, 0.86, 0.18, 0.20))
	draw_circle(pp + Vector2(-2.0, 0), 3.3, Color8(255, 240, 82))
	draw_line(pp + Vector2(1.0, 0), pp + Vector2(7.0, 0), Color8(255, 240, 82), 2)
	draw_line(pp + Vector2(5.0, 0), pp + Vector2(5.0, 3.0), Color8(255, 240, 82), 2)

func _map_weapon(origin: Vector2, cell: float, pos: Vector3) -> void:
	var pp = _map_pos(origin, cell, pos)
	var pts = PackedVector2Array([pp + Vector2(-5, 3), pp + Vector2(-1, -4), pp + Vector2(6, -1), pp + Vector2(2, 4)])
	var closed = PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]])
	draw_colored_polygon(pts, Color(0.02, 0.12, 0.17, 0.82))
	draw_polyline(closed, Color8(120, 232, 255), 1.4)

func _map_diamond(origin: Vector2, cell: float, pos: Vector3, color: Color, radius: float) -> void:
	var pp = _map_pos(origin, cell, pos)
	var pts = PackedVector2Array([pp + Vector2(0, -radius), pp + Vector2(radius, 0), pp + Vector2(0, radius), pp + Vector2(-radius, 0)])
	var closed = PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]])
	draw_colored_polygon(pts, Color(color.r, color.g, color.b, 0.36))
	draw_polyline(closed, color, 1.2)

func _map_skull(origin: Vector2, cell: float, pos: Vector3, radius: float) -> void:
	var pp = _map_pos(origin, cell, pos)
	draw_circle(pp, radius, Color(0.70, 0.02, 0.02, 0.88))
	draw_circle(pp + Vector2(0, -radius * 0.10), radius * 0.58, Color8(240, 228, 208))
	draw_circle(pp + Vector2(-radius * 0.22, -radius * 0.15), radius * 0.12, Color8(20, 12, 12))
	draw_circle(pp + Vector2(radius * 0.22, -radius * 0.15), radius * 0.12, Color8(20, 12, 12))
	draw_rect(Rect2(pp.x - radius * 0.28, pp.y + radius * 0.25, radius * 0.56, radius * 0.22), Color8(240, 228, 208))
	draw_rect(Rect2(pp.x - radius * 0.07, pp.y + radius * 0.02, radius * 0.14, radius * 0.16), Color8(20, 12, 12))

func _draw_overlays(screen_size: Vector2) -> void:
	draw_rect(Rect2(0, 0, screen_size.x, 6), Color(0, 0, 0, 0.08))
	if player.damage_flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, screen_size), Color(0.8, 0.0, 0.0, 0.34 * player.damage_flash))
	if player.dash_flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, screen_size), Color(0.25, 0.72, 1.0, 0.20 * player.dash_flash))
	if player.powerups.is_active("shield"):
		draw_rect(Rect2(5, 5, screen_size.x - 10, screen_size.y - 10), Color(0.26, 1.0, 0.55, 0.38), false, 4)
	if player.powerups.is_active("berserk"):
		draw_rect(Rect2(Vector2.ZERO, screen_size), Color(0.65, 0.0, 0.0, 0.13))
	if player.powerups.is_active("haste"):
		for x in range(0, int(screen_size.x), 84):
			draw_line(Vector2(x, 0), Vector2(x - 120, screen_size.y), Color(0.45, 0.85, 1.0, 0.18), 2)

func _draw_boss_bar(screen_size: Vector2) -> void:
	var w = min(520.0, screen_size.x * 0.62)
	var x = screen_size.x * 0.5 - w * 0.5
	var y = 20.0
	var ratio = clamp(float(boss_current) / float(boss_max), 0.0, 1.0)
	var label = "ALGORE"
	if level_manager != null:
		for e in level_manager.enemies:
			if is_instance_valid(e) and not e.dead and e.stats.boss:
				label = String(e.stats.display_name).to_upper()
				break
	var bar_color = Color8(225, 58, 70)
	draw_rect(Rect2(x, y, w, 20), Color8(48, 18, 20))
	draw_rect(Rect2(x, y, w * ratio, 20), bar_color)
	draw_rect(Rect2(x, y, w, 20), Color8(242, 196, 130), false, 2)
	draw_string(ThemeDB.fallback_font, Vector2(x, y + 46), label, HORIZONTAL_ALIGNMENT_CENTER, w, 22, Color8(255, 238, 192))

func _draw_miniboss_bars(screen_size: Vector2) -> void:
	if level_manager == null:
		return
	var font = ThemeDB.fallback_font
	var y = 54.0 if boss_visible else 20.0
	var shown = 0
	for e in level_manager.enemies:
		if not is_instance_valid(e) or e.dead:
			continue
		if not (String(e.stats.id) in ["0", "6", "7", "8", "9"]):
			continue
		var w = min(280.0, screen_size.x * 0.32)
		var h = 10.0
		var x = screen_size.x * 0.5 - w * 0.5
		var yy = y + shown * 26.0
		var ratio = clamp(float(e.hp) / float(max(1, e.stats.hp)), 0.0, 1.0)
		draw_rect(Rect2(x, yy, w, h), Color(0.08, 0.015, 0.018, 0.72))
		draw_rect(Rect2(x, yy, w * ratio, h), e.stats.color.lightened(0.18))
		draw_rect(Rect2(x, yy, w, h), Color(0.95, 0.78, 0.44, 0.38), false, 1)
		draw_string(font, Vector2(x, yy + 24), _fit(e.stats.display_name.to_upper(), 22), HORIZONTAL_ALIGNMENT_CENTER, w, 13, Color(1.0, 0.88, 0.66, 0.84))
		shown += 1
		if shown >= 4:
			return

func _draw_center_message(screen_size: Vector2) -> void:
	draw_string(ThemeDB.fallback_font, Vector2(0, 98), message_text, HORIZONTAL_ALIGNMENT_CENTER, screen_size.x, 30, Color8(246, 236, 210))

func _draw_fps_counter(screen_size: Vector2) -> void:
	var font = ThemeDB.fallback_font
	var fps = Engine.get_frames_per_second()
	var color = Color8(130, 255, 170) if fps >= 55 else (Color8(255, 218, 92) if fps >= 42 else Color8(255, 112, 92))
	draw_rect(Rect2(screen_size.x - 78, 8, 64, 22), Color(0.02, 0.025, 0.03, 0.48))
	draw_string(font, Vector2(screen_size.x - 74, 24), "%d FPS" % fps, HORIZONTAL_ALIGNMENT_RIGHT, 56, 12, color)

func _handle_mouse_click(pos: Vector2) -> void:
	for button in overlay_buttons + option_buttons + pause_buttons:
		var rect: Rect2 = button.rect
		if not rect.has_point(pos):
			continue
		var action = String(button.action)
		var value = button.get("value", "")
		match action:
			"resume":
				options_open = false
				player.paused = false
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			"options":
				options_open = true
			"main_menu":
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				get_tree().change_scene_to_file("res://scenes/ui/Menu.tscn")
			"quit":
				get_tree().quit()
			"option_tab":
				option_tab = int(value)
				option_index = 0
			"option_change":
				option_index = int(value)
				_change_option(1.0)
			"options_back":
				options_open = false
			"replace":
				weapons.replace_carried_weapon(String(value))
			"locker_toggle":
				weapons.toggle_locker_weapon(String(value))
			"bomb_select":
				weapons.set_bomb_type(String(value))
			"locker_close":
				weapons.close_loadout_overlay()
			"sol_choice":
				if sol_manager != null:
					sol_manager.choose(int(value))
		return

func _sol_state() -> Dictionary:
	if sol_manager == null or not sol_manager.has_method("state"):
		return {}
	return sol_manager.state()

func _draw_sol_line(screen_size: Vector2, sol_state: Dictionary) -> void:
	var font = ThemeDB.fallback_font
	var panel_w = min(620.0, screen_size.x - 72.0)
	var panel_h = 112.0
	var pos = Vector2(36.0, screen_size.y * 0.18)
	draw_rect(Rect2(pos, Vector2(panel_w, panel_h)), Color(0.012, 0.014, 0.018, 0.70))
	draw_rect(Rect2(pos, Vector2(panel_w, panel_h)), Color(0.55, 0.48, 0.30, 0.38), false, 1.4)
	_draw_sol_portrait(pos + Vector2(20, 18), 54.0, String(sol_state.get("mood", "proud")))
	draw_string(font, pos + Vector2(92, 28), String(sol_state.get("speaker", "SOL")), HORIZONTAL_ALIGNMENT_LEFT, 140, 16, Color8(238, 204, 120))
	_draw_wrapped_text(String(sol_state.get("text", "")), pos + Vector2(92, 56), panel_w - 114, 2, 17, Color8(226, 226, 216))

func _draw_sol_choice_overlay(screen_size: Vector2, sol_state: Dictionary) -> void:
	var font = ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, screen_size), Color(0, 0, 0, 0.70))
	var panel_w = min(760.0, screen_size.x - 80.0)
	var panel_h = 342.0
	var pos = Vector2(screen_size.x * 0.5 - panel_w * 0.5, screen_size.y * 0.5 - panel_h * 0.5)
	draw_rect(Rect2(pos, Vector2(panel_w, panel_h)), Color(0.012, 0.014, 0.018, 0.90))
	draw_rect(Rect2(pos, Vector2(panel_w, panel_h)), Color(0.65, 0.56, 0.34, 0.42), false, 2)
	_draw_sol_portrait(pos + Vector2(34, 36), 76.0, String(sol_state.get("mood", "proud")))
	draw_string(font, pos + Vector2(134, 58), "SOLITUDE", HORIZONTAL_ALIGNMENT_LEFT, 260, 24, Color8(238, 204, 120))
	draw_string(font, pos + Vector2(134, 96), _fit(String(sol_state.get("text", "")), 82), HORIZONTAL_ALIGNMENT_LEFT, panel_w - 170, 17, Color8(230, 230, 220))
	var choices: Array = sol_state.get("choices", [])
	var start_y = pos.y + 156.0
	for i in choices.size():
		var choice: Dictionary = choices[i]
		var rect = Rect2(pos.x + 60, start_y + i * 48.0, panel_w - 120, 34)
		_draw_click_button(rect, "%d  %s" % [i + 1, _fit(String(choice.get("text", "")), 62)], Color8(245, 220, 150), overlay_buttons, "sol_choice", i)
	draw_string(font, Vector2(pos.x, pos.y + panel_h - 22), "Click or press 1-3", HORIZONTAL_ALIGNMENT_CENTER, panel_w, 14, Color8(170, 176, 174))

func _draw_sol_portrait(pos: Vector2, side: float, mood: String) -> void:
	var accent = Color8(232, 198, 58)
	if mood == "warm":
		accent = Color8(215, 190, 138)
	elif mood == "defensive":
		accent = Color8(235, 138, 82)
	elif mood == "cold":
		accent = Color8(120, 192, 210)
	draw_rect(Rect2(pos, Vector2(side, side)), Color(0.025, 0.028, 0.032, 0.94))
	draw_rect(Rect2(pos, Vector2(side, side)), Color(accent.r, accent.g, accent.b, 0.55), false, 1.5)
	var center = pos + Vector2(side * 0.5, side * 0.48)
	draw_circle(center, side * 0.22, Color(0.78, 0.76, 0.66, 0.92))
	draw_rect(Rect2(center.x - side * 0.18, center.y + side * 0.22, side * 0.36, side * 0.16), Color(0.78, 0.76, 0.66, 0.84))
	draw_line(pos + Vector2(side * 0.24, side * 0.28), pos + Vector2(side * 0.40, side * 0.22), accent, 2)
	draw_line(pos + Vector2(side * 0.60, side * 0.22), pos + Vector2(side * 0.76, side * 0.28), accent, 2)
	draw_circle(center + Vector2(-side * 0.08, -side * 0.02), side * 0.026, Color(0.04, 0.04, 0.045))
	draw_circle(center + Vector2(side * 0.08, -side * 0.02), side * 0.026, Color(0.04, 0.04, 0.045))

func _draw_wrapped_text(text: String, pos: Vector2, max_width: float, max_lines: int, font_size: int, color: Color) -> void:
	var font = ThemeDB.fallback_font
	var words = text.split(" ")
	var lines = []
	var current = ""
	var consumed = 0
	for word in words:
		var candidate = word if current == "" else "%s %s" % [current, word]
		if font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= max_width:
			current = candidate
			consumed += 1
		else:
			if current != "":
				lines.append(current)
			current = word
			consumed += 1
			if lines.size() >= max_lines:
				break
	if current != "" and lines.size() < max_lines:
		lines.append(current)
	var overflow = consumed < words.size()
	for i in lines.size():
		var line = String(lines[i])
		if i == max_lines - 1 and overflow:
			while line.length() > 3 and font.get_string_size(line + "...", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > max_width:
				line = line.substr(0, line.length() - 1).strip_edges()
			line += "..."
		draw_string(font, pos + Vector2(0, float(i) * 21.0), line, HORIZONTAL_ALIGNMENT_LEFT, max_width, font_size, color)

func _draw_click_button(rect: Rect2, text: String, accent: Color, target: Array, action: String, value = "") -> void:
	var mouse = get_viewport().get_mouse_position()
	var hovered = rect.has_point(mouse)
	var fill = Color(0.04, 0.05, 0.06, 0.78) if not hovered else Color(0.12, 0.13, 0.14, 0.88)
	draw_rect(rect, fill)
	draw_rect(rect, Color(accent.r, accent.g, accent.b, 0.54 if hovered else 0.32), false, 1.4)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(0, rect.size.y * 0.64), text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 18, accent.lightened(0.15) if hovered else accent)
	target.append({"rect": rect, "action": action, "value": value})

func _draw_pause_menu(screen_size: Vector2) -> void:
	var font = ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, screen_size), Color(0, 0, 0, 0.68))
	if options_open:
		_draw_options_menu(screen_size)
		return
	var panel_w = min(620.0, screen_size.x - 80.0)
	var panel_h = 330.0
	var pos = Vector2(screen_size.x * 0.5 - panel_w * 0.5, screen_size.y * 0.5 - panel_h * 0.5)
	draw_rect(Rect2(pos, Vector2(panel_w, panel_h)), Color(0.02, 0.024, 0.032, 0.78))
	draw_rect(Rect2(pos, Vector2(panel_w, panel_h)), Color(0.95, 0.78, 0.35, 0.32), false, 2)
	draw_string(font, Vector2(pos.x, pos.y + 54), "PAUSED", HORIZONTAL_ALIGNMENT_CENTER, panel_w, 42, Color.WHITE)
	var bx = pos.x + panel_w - 178
	var by = pos.y + 88
	_draw_click_button(Rect2(bx, by, 132, 30), "RESUME", Color8(245, 220, 150), pause_buttons, "resume")
	_draw_click_button(Rect2(bx, by + 40, 132, 30), "OPTIONS", Color8(150, 220, 255), pause_buttons, "options")
	_draw_click_button(Rect2(bx, by + 80, 132, 30), "MAIN MENU", Color8(150, 220, 255), pause_buttons, "main_menu")
	_draw_click_button(Rect2(bx, by + 120, 132, 30), "QUIT", Color8(255, 156, 140), pause_buttons, "quit")
	var rows = [
		["SPACE", "Jump / hold for Super Jump"],
		["SHIFT", "Slide on ground / Glide in air"],
		["Q", "Grapple"],
		["RMB", "Weapon special"],
		["G / MMB", "Grenade"],
		["E", "Use / open door"],
		["O", "Options"],
		["M", "Main Menu"],
		["Q while paused", "Quit"]
	]
	var start_y = pos.y + 92
	for i in rows.size():
		var row_y = start_y + i * 25.0
		var key_col = Color8(245, 216, 112) if i < 5 else Color8(150, 220, 255)
		draw_string(font, Vector2(pos.x + 54, row_y), String(rows[i][0]), HORIZONTAL_ALIGNMENT_LEFT, 170, 17, key_col)
		draw_string(font, Vector2(pos.x + 170, row_y), String(rows[i][1]), HORIZONTAL_ALIGNMENT_LEFT, panel_w - 360, 17, Color8(224, 224, 218))
	draw_string(font, Vector2(pos.x, pos.y + panel_h - 24), "ESC resumes", HORIZONTAL_ALIGNMENT_CENTER, panel_w, 16, Color8(180, 190, 196))

func _draw_replacement_overlay(screen_size: Vector2, state: Dictionary) -> void:
	var font = ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, screen_size), Color(0, 0, 0, 0.72))
	var panel_w = min(620.0, screen_size.x - 80.0)
	var panel_h = 300.0
	var pos = Vector2(screen_size.x * 0.5 - panel_w * 0.5, screen_size.y * 0.5 - panel_h * 0.5)
	var new_id = String(state.pending_weapon_pickup)
	var new_name = new_id.to_upper()
	if weapons.weapons.has(new_id):
		new_name = weapons.weapons[new_id].display_name
	draw_rect(Rect2(pos, Vector2(panel_w, panel_h)), Color(0.02, 0.024, 0.032, 0.88))
	draw_rect(Rect2(pos, Vector2(panel_w, panel_h)), Color(0.95, 0.78, 0.35, 0.36), false, 2)
	draw_string(font, Vector2(pos.x, pos.y + 48), "LOADOUT FULL", HORIZONTAL_ALIGNMENT_CENTER, panel_w, 32, Color.WHITE)
	draw_string(font, Vector2(pos.x + 36, pos.y + 84), "Replace one weapon to carry %s" % new_name.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, panel_w - 72, 17, Color8(230, 224, 200))
	var carried: Array = state.get("carried_weapons", [])
	var start_x = pos.x + 36
	var start_y = pos.y + 124
	var button_w = (panel_w - 84) / 2.0
	for i in carried.size():
		var old_id = String(carried[i])
		var old_name = old_id.to_upper()
		if weapons.weapons.has(old_id):
			old_name = weapons.weapons[old_id].display_name
		var rect = Rect2(start_x + (i % 2) * (button_w + 12), start_y + floori(float(i) / 2.0) * 46, button_w, 34)
		_draw_click_button(rect, "%d  %s" % [i + 1, _fit(old_name, 18)], Color8(245, 220, 150), overlay_buttons, "replace", old_id)

func _draw_locker_overlay(screen_size: Vector2, state: Dictionary) -> void:
	var font = ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, screen_size), Color(0, 0, 0, 0.72))
	var panel_w = min(760.0, screen_size.x - 80.0)
	var panel_h = min(500.0, screen_size.y - 80.0)
	var pos = Vector2(screen_size.x * 0.5 - panel_w * 0.5, screen_size.y * 0.5 - panel_h * 0.5)
	draw_rect(Rect2(pos, Vector2(panel_w, panel_h)), Color(0.02, 0.024, 0.032, 0.90))
	draw_rect(Rect2(pos, Vector2(panel_w, panel_h)), Color(0.45, 0.82, 0.95, 0.32), false, 2)
	draw_string(font, Vector2(pos.x, pos.y + 44), "WEAPON LOCKER", HORIZONTAL_ALIGNMENT_CENTER, panel_w, 32, Color.WHITE)
	draw_string(font, Vector2(pos.x, pos.y + 76), "Select up to 5 carried weapons", HORIZONTAL_ALIGNMENT_CENTER, panel_w, 16, Color8(190, 224, 235))
	var carried: Array = state.get("carried_weapons", [])
	var unlocked: Dictionary = state.get("unlocked", {})
	var cols = 4
	var button_w = (panel_w - 72.0) / float(cols)
	var start = pos + Vector2(24, 104)
	var row_h = 35.0
	var drawn = 0
	for id in GameDataScript.WEAPON_ORDER:
		if not unlocked.has(id):
			continue
		var weapon = weapons.weapons[id]
		var rect = Rect2(start.x + (drawn % cols) * (button_w + 12), start.y + floori(float(drawn) / float(cols)) * row_h, button_w, 27)
		var carried_mark = "[x] " if carried.has(id) else "[ ] "
		var accent = Color8(245, 220, 150) if carried.has(id) else Color8(150, 220, 255)
		_draw_click_button(rect, carried_mark + _fit(weapon.display_name, 17), accent, overlay_buttons, "locker_toggle", id)
		drawn += 1
	var bomb_y = min(pos.y + panel_h - 98.0, start.y + (floori(float(drawn + cols - 1) / float(cols)) + 1) * row_h + 6.0)
	draw_string(font, Vector2(pos.x + 26, bomb_y - 8), "GRENADE TYPE", HORIZONTAL_ALIGNMENT_LEFT, 220, 15, Color8(190, 224, 235))
	var bomb_types: Array = state.get("bomb_types", [])
	var current_bomb = String(state.get("bomb_type", "frag"))
	var bomb_w = (panel_w - 72.0) / max(1.0, float(bomb_types.size()))
	for i in bomb_types.size():
		var kind = String(bomb_types[i])
		var rect = Rect2(pos.x + 24 + i * bomb_w, bomb_y + 6, bomb_w - 7, 27)
		var accent = Color8(245, 220, 150) if kind == current_bomb else Color8(150, 220, 255)
		_draw_click_button(rect, _bomb_symbol(kind), accent, overlay_buttons, "bomb_select", kind)
	var close_rect = Rect2(pos.x + panel_w * 0.5 - 70, pos.y + panel_h - 52, 140, 32)
	_draw_click_button(close_rect, "CLOSE", Color8(245, 220, 150), overlay_buttons, "locker_close")

func _draw_options_menu(screen_size: Vector2) -> void:
	var font = ThemeDB.fallback_font
	var w = min(620.0, screen_size.x - 60.0)
	var h = 430.0
	var pos = Vector2(screen_size.x * 0.5 - w * 0.5, screen_size.y * 0.5 - h * 0.5)
	draw_rect(Rect2(pos, Vector2(w, h)), Color8(24, 24, 28))
	draw_rect(Rect2(pos, Vector2(w, h)), Color8(186, 148, 78), false, 2)
	draw_string(font, pos + Vector2(0, 42), "OPTIONS", HORIZONTAL_ALIGNMENT_CENTER, w, 32, Color8(245, 220, 150))
	for i in option_tab_names.size():
		var tab_w = 150.0
		var tab_pos = Vector2(pos.x + 42 + i * (tab_w + 10.0), pos.y + 62)
		var active = i == option_tab
		draw_rect(Rect2(tab_pos, Vector2(tab_w, 26)), Color8(78, 64, 40) if active else Color8(36, 38, 42))
		draw_rect(Rect2(tab_pos, Vector2(tab_w, 26)), Color8(186, 148, 78), false, 1)
		draw_string(font, tab_pos + Vector2(0, 19), option_tab_names[i], HORIZONTAL_ALIGNMENT_CENTER, tab_w, 14, Color8(245, 220, 150) if active else Color8(176, 176, 176))
		option_buttons.append({"rect": Rect2(tab_pos, Vector2(tab_w, 26)), "action": "option_tab", "value": i})
	var labels = {
		"master_volume": "MASTER VOLUME",
		"sfx_volume": "SFX VOLUME",
		"music_volume": "MUSIC VOLUME",
		"mouse_sensitivity": "MOUSE SENS",
		"screen_shake": "SCREEN SHAKE",
		"fullscreen": "FULLSCREEN",
		"fps_limit": "FPS LIMIT",
		"vsync": "VSYNC",
		"weather_quality": "WEATHER QUALITY",
		"vfx_quality": "VFX QUALITY",
		"no_gun_mode": "NO GUN MODE",
		"legacy_weapon_models": "LEGACY WEAPONS",
		"developer_mode": "DEVELOPER MODE",
		"back": "BACK"
	}
	var keys = _current_option_keys()
	option_index = clamp(option_index, 0, keys.size() - 1)
	for i in keys.size():
		var key = keys[i]
		var y = pos.y + 124 + i * 31
		var selected = i == option_index
		if selected:
			draw_rect(Rect2(pos.x + 26, y - 20, w - 52, 27), Color8(78, 64, 40))
		var row_rect = Rect2(pos.x + 26, y - 20, w - 52, 27)
		if row_rect.has_point(get_viewport().get_mouse_position()):
			draw_rect(row_rect, Color(0.20, 0.19, 0.14, 0.62))
		draw_string(font, Vector2(pos.x + 42, y), labels[key], HORIZONTAL_ALIGNMENT_LEFT, 250, 20, Color.WHITE if selected else Color8(210, 210, 210))
		var value = _option_value_text(key)
		draw_string(font, Vector2(pos.x + w - 220, y), value, HORIZONTAL_ALIGNMENT_RIGHT, 180, 20, Color8(150, 220, 255) if key != "back" else Color8(245, 220, 150))
		option_buttons.append({"rect": row_rect, "action": "options_back" if key == "back" else "option_change", "value": i})
	draw_string(font, Vector2(pos.x, pos.y + h - 18), "Click to change  |  TAB changes page  |  O Back", HORIZONTAL_ALIGNMENT_CENTER, w, 16, Color8(176, 176, 176))

func _current_option_keys() -> Array:
	return option_pages[option_tab]

func _option_value_text(key: String) -> String:
	if key == "fullscreen":
		return "ON" if bool(settings.get("fullscreen", true)) else "OFF"
	if key in ["no_gun_mode", "legacy_weapon_models", "developer_mode", "vsync"]:
		return "ON" if bool(settings.get(key, false)) else "OFF"
	if key == "fps_limit":
		var fps = int(settings.get("fps_limit", 60))
		return "UNLIMITED" if fps <= 0 else "%d FPS" % fps
	if key in ["weather_quality", "vfx_quality"]:
		return String(settings.get(key, GameSettingsScript.defaults()[key])).to_upper()
	if key == "back":
		return "ENTER"
	return "%d%%" % int(float(settings.get(key, GameSettingsScript.defaults().get(key, 1.0))) * 100.0)

func _change_option(dir: float) -> void:
	var keys = _current_option_keys()
	option_index = clamp(option_index, 0, keys.size() - 1)
	var key = keys[option_index]
	if key == "back":
		options_open = false
		return
	if key == "fullscreen":
		settings["fullscreen"] = not bool(settings.get("fullscreen", true))
	elif key in ["no_gun_mode", "legacy_weapon_models", "developer_mode", "vsync"]:
		settings[key] = not bool(settings.get(key, false))
	elif key == "fps_limit":
		_cycle_option(key, [30, 60, 90, 120, 144, 0], dir)
	elif key == "weather_quality":
		_cycle_option(key, ["off", "low", "medium", "high"], dir)
	elif key == "vfx_quality":
		_cycle_option(key, ["low", "medium", "high"], dir)
	else:
		var step = 0.05
		var min_v = 0.0
		var max_v = 1.0
		if key == "mouse_sensitivity":
			min_v = 0.45
			max_v = 1.85
		elif key == "screen_shake":
			min_v = 0.25
			max_v = 1.0
		settings[key] = clamp(float(settings.get(key, GameSettingsScript.defaults()[key])) + dir * step, min_v, max_v)
	_apply_settings()
	GameSettingsScript.save_settings(settings)

func _cycle_option(key: String, values: Array, dir: float) -> void:
	var current = settings.get(key, GameSettingsScript.defaults()[key])
	var idx = values.find(current)
	if idx < 0:
		idx = 0
	idx = posmod(idx + (1 if dir >= 0.0 else -1), values.size())
	settings[key] = values[idx]

func _apply_settings() -> void:
	if player != null:
		player.set_mouse_sensitivity(float(settings.get("mouse_sensitivity", 1.0)))
		player.set_screen_shake(float(settings.get("screen_shake", 0.68)))
	if audio_manager != null:
		audio_manager.set_master_volume(float(settings.get("master_volume", 0.82)))
		audio_manager.set_sfx_volume(float(settings.get("sfx_volume", 0.78)))
		if audio_manager.has_method("set_music_volume"):
			audio_manager.set_music_volume(float(settings.get("music_volume", 0.80)))
	if weapons != null and weapons.has_method("set_no_gun_mode"):
		weapons.set_no_gun_mode(bool(settings.get("no_gun_mode", false)))
	if weapons != null and weapons.has_method("set_legacy_weapon_models"):
		weapons.set_legacy_weapon_models(bool(settings.get("legacy_weapon_models", false)))
	if player != null and player.has_method("set_developer_mode"):
		player.set_developer_mode(bool(settings.get("developer_mode", false)))
	if weapons != null and weapons.has_method("set_developer_mode"):
		weapons.set_developer_mode(bool(settings.get("developer_mode", false)))
	if level_manager != null and level_manager.has_method("set_developer_mode"):
		level_manager.set_developer_mode(bool(settings.get("developer_mode", false)))
	if level_manager != null and level_manager.has_method("set_performance_settings"):
		level_manager.set_performance_settings(settings)
	GameSettingsScript.apply_video(settings)

func _fit(text: String, max_len: int) -> String:
	if text.length() <= max_len:
		return text
	return text.substr(0, max_len - 1)
