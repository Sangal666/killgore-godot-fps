extends Control

const GameSettingsScript = preload("res://scripts/core/GameSettings.gd")
const GameDataScript = preload("res://scripts/core/GameData.gd")

@onready var title_label: Label = $VBox/Title
@onready var play_btn: Button = $VBox/Play
@onready var quit_btn: Button = $VBox/Quit
@onready var version_label: Label = $VBox/Version
@onready var vbox: VBoxContainer = $VBox

var anim_time := 0.0
var settings := {}
var options_btn: Button
var level_select_btn: Button
var options_panel: PanelContainer
var level_panel: PanelContainer

func _ready() -> void:
	settings = GameSettingsScript.load_settings()
	GameSettingsScript.apply_video(settings)
	play_btn.pressed.connect(_on_play)
	quit_btn.pressed.connect(_on_quit)
	_add_level_select_button()
	_add_options_button()
	_build_options_panel()
	_build_level_panel()

func _process(delta: float) -> void:
	anim_time += delta
	var glow = 0.82 + sin(anim_time * 2.4) * 0.18
	var c = Color8(220, 180, 88)
	title_label.add_theme_color_override("font_color", Color(c.r * glow, c.g * glow, c.b * glow))

func _on_play() -> void:
	get_tree().set_meta("killgore_start_level", 0)
	get_tree().set_meta("killgore_level_select", false)
	get_tree().change_scene_to_file("res://Main.tscn")

func _on_quit() -> void:
	get_tree().quit()

func _add_options_button() -> void:
	options_btn = Button.new()
	options_btn.text = "OPTIONS"
	options_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	options_btn.add_theme_font_size_override("font_size", 24)
	options_btn.add_theme_color_override("font_color", Color8(230, 224, 202))
	options_btn.pressed.connect(func(): options_panel.visible = true)
	vbox.add_child(options_btn)
	vbox.move_child(options_btn, quit_btn.get_index())

func _add_level_select_button() -> void:
	level_select_btn = Button.new()
	level_select_btn.text = "LEVEL SELECT"
	level_select_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	level_select_btn.add_theme_font_size_override("font_size", 24)
	level_select_btn.add_theme_color_override("font_color", Color8(230, 224, 202))
	level_select_btn.pressed.connect(func(): level_panel.visible = true)
	vbox.add_child(level_select_btn)
	vbox.move_child(level_select_btn, quit_btn.get_index())

func _build_level_panel() -> void:
	level_panel = PanelContainer.new()
	level_panel.visible = false
	level_panel.anchor_left = 0.5
	level_panel.anchor_top = 0.5
	level_panel.anchor_right = 0.5
	level_panel.anchor_bottom = 0.5
	level_panel.offset_left = -250
	level_panel.offset_top = -245
	level_panel.offset_right = 250
	level_panel.offset_bottom = 245
	add_child(level_panel)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	level_panel.add_child(box)
	var title = Label.new()
	title.text = "LEVEL SELECT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color8(245, 220, 150))
	box.add_child(title)
	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	box.add_child(grid)
	for i in GameDataScript.LEVELS.size():
		var b = Button.new()
		if i == 0:
			b.text = "TRAINING"
		elif GameDataScript.is_trench_map_level(i):
			b.text = "LEVEL 10: MAP 1 V2"
		elif GameDataScript.is_ramp_test_level(i):
			b.text = "LEVEL 11: SLIDE RAMP"
		elif GameDataScript.is_city_prototype_level(i):
			b.text = "BRUTALIST CITY"
		elif GameDataScript.is_horror_sequence_level(i):
			b.text = "MNEMONIC LABYRINTH"
		elif i == GameDataScript.LEVELS.size() - 1:
			b.text = "ALGORE"
		else:
			b.text = "LEVEL %d" % i
		b.custom_minimum_size = Vector2(140, 42)
		b.add_theme_font_size_override("font_size", 18)
		var index = i
		b.pressed.connect(func():
			get_tree().set_meta("killgore_start_level", index)
			get_tree().set_meta("killgore_level_select", true)
			get_tree().change_scene_to_file("res://Main.tscn")
		)
		grid.add_child(b)
	var back = Button.new()
	back.text = "BACK"
	back.pressed.connect(func(): level_panel.visible = false)
	box.add_child(back)

func _build_options_panel() -> void:
	options_panel = PanelContainer.new()
	options_panel.visible = false
	options_panel.anchor_left = 0.5
	options_panel.anchor_top = 0.5
	options_panel.anchor_right = 0.5
	options_panel.anchor_bottom = 0.5
	options_panel.offset_left = -330
	options_panel.offset_top = -285
	options_panel.offset_right = 330
	options_panel.offset_bottom = 285
	add_child(options_panel)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	options_panel.add_child(box)
	var title = Label.new()
	title.text = "OPTIONS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color8(245, 220, 150))
	box.add_child(title)
	var tabs = TabContainer.new()
	tabs.custom_minimum_size = Vector2(620, 430)
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(tabs)
	var gameplay = VBoxContainer.new()
	gameplay.name = "Gameplay"
	gameplay.add_theme_constant_override("separation", 10)
	tabs.add_child(gameplay)
	_add_slider(gameplay, "Master Volume", "master_volume", 0.0, 1.0)
	_add_slider(gameplay, "SFX Volume", "sfx_volume", 0.0, 1.0)
	_add_slider(gameplay, "Music Volume", "music_volume", 0.0, 1.0)
	_add_slider(gameplay, "Mouse Sensitivity", "mouse_sensitivity", 0.45, 1.85)
	_add_slider(gameplay, "Screen Shake", "screen_shake", 0.25, 1.0)
	_add_check(gameplay, "Fullscreen", "fullscreen", true)
	_add_check(gameplay, "No Gun Mode", "no_gun_mode")
	_add_check(gameplay, "Legacy Weapon Models", "legacy_weapon_models")
	_add_check(gameplay, "Developer Mode", "developer_mode")
	var visual = VBoxContainer.new()
	visual.name = "Visual Perf"
	visual.add_theme_constant_override("separation", 10)
	tabs.add_child(visual)
	_add_option_button(visual, "FPS Limit", "fps_limit", [
		{"label": "30 FPS", "value": 30},
		{"label": "60 FPS", "value": 60},
		{"label": "90 FPS", "value": 90},
		{"label": "120 FPS", "value": 120},
		{"label": "144 FPS", "value": 144},
		{"label": "Unlimited", "value": 0}
	], true)
	_add_check(visual, "VSync", "vsync", true)
	_add_option_button(visual, "Weather Quality", "weather_quality", [
		{"label": "Off", "value": "off"},
		{"label": "Low", "value": "low"},
		{"label": "Medium", "value": "medium"},
		{"label": "High", "value": "high"}
	])
	_add_option_button(visual, "VFX Quality", "vfx_quality", [
		{"label": "Low", "value": "low"},
		{"label": "Medium", "value": "medium"},
		{"label": "High", "value": "high"}
	])
	var back = Button.new()
	back.text = "BACK"
	back.pressed.connect(func(): options_panel.visible = false)
	box.add_child(back)

func _add_check(parent: Control, label_text: String, key: String, apply_video := false) -> void:
	var check = CheckButton.new()
	check.text = label_text
	check.button_pressed = bool(settings.get(key, GameSettingsScript.defaults()[key]))
	check.toggled.connect(func(on):
		settings[key] = on
		if apply_video:
			GameSettingsScript.apply_video(settings)
		GameSettingsScript.save_settings(settings)
	)
	parent.add_child(check)

func _add_option_button(parent: Control, label_text: String, key: String, options: Array, apply_video := false) -> void:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	var label = Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 180
	row.add_child(label)
	var button = OptionButton.new()
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(button)
	var current = settings.get(key, GameSettingsScript.defaults()[key])
	var selected = 0
	for i in options.size():
		var item = options[i]
		button.add_item(String(item["label"]))
		button.set_item_metadata(i, item["value"])
		if item["value"] == current:
			selected = i
	button.select(selected)
	button.item_selected.connect(func(index):
		settings[key] = button.get_item_metadata(index)
		if apply_video:
			GameSettingsScript.apply_video(settings)
		GameSettingsScript.save_settings(settings)
	)

func _add_slider(parent: Control, label_text: String, key: String, min_value: float, max_value: float) -> void:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	var label = Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 160
	row.add_child(label)
	var slider = HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = 0.01
	slider.value = float(settings.get(key, GameSettingsScript.defaults()[key]))
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)
	var value = Label.new()
	value.custom_minimum_size.x = 44
	value.text = "%d%%" % int(slider.value * 100.0)
	row.add_child(value)
	slider.value_changed.connect(func(v):
		settings[key] = v
		value.text = "%d%%" % int(v * 100.0)
		GameSettingsScript.save_settings(settings)
	)
