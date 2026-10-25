extends RefCounted
class_name GameSettings

const SETTINGS_PATH = "user://killgore_settings.cfg"

static func defaults() -> Dictionary:
	return {
		"master_volume": 0.82,
		"sfx_volume": 0.78,
		"music_volume": 0.80,
		"mouse_sensitivity": 1.0,
		"screen_shake": 0.68,
		"fullscreen": true,
		"fps_limit": 60,
		"vsync": true,
		"weather_quality": "medium",
		"vfx_quality": "medium",
		"no_gun_mode": false,
		"legacy_weapon_models": true,
		"developer_mode": false
	}

static func load_settings() -> Dictionary:
	var settings = defaults()
	var cfg = ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		for key in settings.keys():
			settings[key] = cfg.get_value("options", key, settings[key])
	return settings

static func save_settings(settings: Dictionary) -> void:
	var cfg = ConfigFile.new()
	for key in defaults().keys():
		cfg.set_value("options", key, settings.get(key, defaults()[key]))
	cfg.save(SETTINGS_PATH)

static func apply_video(settings: Dictionary) -> void:
	var fullscreen = bool(settings.get("fullscreen", true))
	var mode = DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)
	Engine.max_fps = int(settings.get("fps_limit", 60))
	var vsync_mode = DisplayServer.VSYNC_ENABLED if bool(settings.get("vsync", true)) else DisplayServer.VSYNC_DISABLED
	DisplayServer.window_set_vsync_mode(vsync_mode)
