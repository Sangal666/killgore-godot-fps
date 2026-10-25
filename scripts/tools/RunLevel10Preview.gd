extends SceneTree

var launched := false

func _initialize() -> void:
	process_frame.connect(_launch_preview, CONNECT_ONE_SHOT)

func _launch_preview() -> void:
	if launched:
		return
	launched = true
	set_meta("killgore_start_level", 10)
	set_meta("killgore_level_select", true)
	change_scene_to_file("res://Main.tscn")
