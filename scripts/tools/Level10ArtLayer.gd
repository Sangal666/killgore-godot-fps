@tool
extends Node3D

const AssetFactoryScript = preload("res://scripts/core/AssetFactory.gd")
const GameDataScript = preload("res://scripts/core/GameData.gd")
const TrenchMapRuntimeScript = preload("res://scripts/world/TrenchMapRuntime.gd")

@export var show_reference_geometry := true:
	set(value):
		show_reference_geometry = value
		if is_inside_tree() and Engine.is_editor_hint():
			call_deferred("_rebuild_editor_preview")

@export var rebuild_preview := false:
	set(value):
		rebuild_preview = false
		if value and is_inside_tree() and Engine.is_editor_hint():
			call_deferred("_rebuild_editor_preview")

func _ready() -> void:
	if Engine.is_editor_hint():
		call_deferred("_rebuild_editor_preview")

func _rebuild_editor_preview() -> void:
	if not Engine.is_editor_hint() or not is_inside_tree():
		return
	var old_preview = get_node_or_null("__EDITOR_REFERENCE_DO_NOT_EDIT")
	if old_preview != null:
		old_preview.free()
	if not show_reference_geometry:
		return

	var preview = TrenchMapRuntimeScript.new()
	preview.name = "__EDITOR_REFERENCE_DO_NOT_EDIT"
	add_child(preview)
	preview.configure(
		AssetFactoryScript.new(),
		null,
		GameDataScript.TRENCH_MAP_PATH,
		TrenchMapRuntimeScript.ART_MODE_NONE
	)
	_add_marker(preview, "SPAWN_REFERENCE", preview.spawn_pos + Vector3.UP * 0.55, Color(0.20, 0.85, 1.0, 0.72))
	_add_marker(preview, "EXIT_REFERENCE", preview.exit_pos + Vector3.UP * 0.55, Color(0.25, 1.0, 0.42, 0.72))

func _add_marker(parent: Node3D, marker_name: String, marker_position: Vector3, color: Color) -> void:
	var marker = MeshInstance3D.new()
	marker.name = marker_name
	var mesh = CylinderMesh.new()
	mesh.top_radius = 0.28
	mesh.bottom_radius = 0.28
	mesh.height = 1.1
	mesh.radial_segments = 12
	marker.mesh = mesh
	marker.position = marker_position
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = Color(color.r, color.g, color.b)
	material.emission_energy_multiplier = 0.8
	marker.material_override = material
	marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(marker)
