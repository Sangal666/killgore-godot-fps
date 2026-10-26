extends SceneTree
## Facade compatibility includes per-material shader isolation, not just pixels.
const Runtime = preload("res://scripts/world/HorrorSequenceLevel.gd")
var failures := 0
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func _initialize() -> void:
	var r := Runtime.new()
	var other := Runtime.new()
	var first: ShaderMaterial = r._make_concrete_shader(Color(.3,.3,.3),.2,.9)
	var second: ShaderMaterial = r._make_concrete_shader(Color(.3,.3,.3),.2,.9)
	check(first!=second and first.shader!=second.shader,"Factory leaked a mutable shader across materials")
	var original := second.shader.code
	first.shader.code = "shader_type spatial; void fragment(){ ALBEDO=vec3(0.0); }"
	check(second.shader.code==original,"QA shader edit mutated another material")
	check(r.flashlight_reactive_materials.size()==2 and other.flashlight_reactive_materials.is_empty(),"Runtime material lists share mutable state")
	r.free()
	other.free()
	if failures==0: print("HORROR_MODULE_BOUNDARIES_OK")
	quit(1 if failures else 0)
