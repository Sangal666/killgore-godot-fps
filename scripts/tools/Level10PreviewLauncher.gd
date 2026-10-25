extends Node


func _ready() -> void:
	get_tree().set_meta("killgore_start_level", 10)
	get_tree().set_meta("killgore_level_select", true)
	get_tree().call_deferred("change_scene_to_file", "res://Main.tscn")
