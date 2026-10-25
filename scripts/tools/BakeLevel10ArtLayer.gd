extends SceneTree

const OUTPUT_PATH = "res://scenes/levels/Level10ArtLayer.tscn"
const AssetFactoryScript = preload("res://scripts/core/AssetFactory.gd")
const GameDataScript = preload("res://scripts/core/GameData.gd")
const TrenchMapRuntimeScript = preload("res://scripts/world/TrenchMapRuntime.gd")
const ArtLayerScript = preload("res://scripts/tools/Level10ArtLayer.gd")

func _initialize() -> void:
	var runtime = TrenchMapRuntimeScript.new()
	root.add_child(runtime)
	var loaded = runtime.configure(
		AssetFactoryScript.new(),
		null,
		GameDataScript.TRENCH_MAP_PATH,
		TrenchMapRuntimeScript.ART_MODE_PROCEDURAL
	)
	if not loaded:
		push_error("Level 10 art bake failed: map could not be loaded")
		quit(1)
		return

	var dressing = runtime.map_root.get_node_or_null("BrutalistDigitalDecayDressing")
	if dressing == null:
		push_error("Level 10 art bake failed: procedural dressing was not generated")
		quit(1)
		return

	var scene_root = Node3D.new()
	scene_root.name = "Level10ArtLayer"
	scene_root.set_script(ArtLayerScript)
	root.add_child(scene_root)
	var editable = Node3D.new()
	editable.name = "EditableArt"
	scene_root.add_child(editable)

	var groups = {}
	for group_name in ["Lighting", "Emissives", "Architecture", "Cables", "Terminals", "Workstations", "ServerProps", "Story", "DecayScars", "Wayfinding", "FogAndAtmosphere", "FloorDetails"]:
		var group = Node3D.new()
		group.name = group_name
		editable.add_child(group)
		groups[group_name] = group

	for child in dressing.get_children():
		child.reparent(groups[_category_for(String(child.name))], false)

	_set_owner_recursive(editable, scene_root)
	var packed = PackedScene.new()
	var pack_error = packed.pack(scene_root)
	if pack_error != OK:
		push_error("Level 10 art bake failed while packing: %s" % error_string(pack_error))
		quit(1)
		return
	var save_error = ResourceSaver.save(packed, OUTPUT_PATH)
	if save_error != OK:
		push_error("Level 10 art bake failed while saving: %s" % error_string(save_error))
		quit(1)
		return
	print("Level 10 editable art layer baked to %s" % OUTPUT_PATH)
	quit()

func _category_for(node_name: String) -> String:
	if node_name.begins_with("DecayLight_") or node_name.begins_with("CeilingPoolLight_") or node_name.begins_with("CeilingLightCase_") or node_name.begins_with("GlobalDecayFill") or node_name.ends_with("SafetyLight") or node_name.ends_with("Pool"):
		return "Lighting"
	if node_name.begins_with("Maintenance") or node_name.begins_with("Architecture"):
		return "Architecture"
	if "Glow" in node_name or "LED" in node_name or "Screen" in node_name:
		return "Emissives"
	if node_name.begins_with("CeilingCable_") or node_name.begins_with("Cables"):
		return "Cables"
	if node_name.begins_with("WallPanel_"):
		return "Terminals"
	if node_name.begins_with("Workstation"):
		return "Workstations"
	if node_name.begins_with("Server"):
		return "ServerProps"
	if node_name.begins_with("Story"):
		return "Story"
	if node_name.begins_with("DecayScar_"):
		return "DecayScars"
	if node_name.begins_with("Wayfinding"):
		return "Wayfinding"
	if node_name.begins_with("DecayFogBand_"):
		return "FogAndAtmosphere"
	if node_name.begins_with("FloorRoute"):
		return "FloorDetails"
	return "FloorDetails"

func _set_owner_recursive(node: Node, scene_owner: Node) -> void:
	node.owner = scene_owner
	for child in node.get_children():
		_set_owner_recursive(child, scene_owner)
