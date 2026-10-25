extends SceneTree

const LevelManagerScript = preload("res://scripts/world/LevelManager.gd")
const AssetFactoryScript = preload("res://scripts/core/AssetFactory.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var manager = LevelManagerScript.new()
	root.add_child(manager)
	manager.asset_factory = AssetFactoryScript.new()
	manager.player = Node3D.new()
	manager.add_child(manager.player)
	manager.projectile_root = Node3D.new()
	manager.add_child(manager.projectile_root)
	var shared_glow_a = manager.asset_factory.make_glow_material(Color8(80, 190, 255), 0.72)
	var shared_glow_b = manager.asset_factory.make_glow_material(Color8(80, 190, 255), 0.72)
	var distinct_glow = manager.asset_factory.make_glow_material(Color8(81, 190, 255), 0.72)
	if shared_glow_a != shared_glow_b or shared_glow_a == distinct_glow:
		_fail("glow material cache did not reuse/isolate resources correctly")
		return

	var color := Color8(120, 220, 255)
	manager.spawn_player_projectile(Vector3.ZERO, Vector3.FORWARD, 18.0, 4, false, 0.0, 4, color)
	var first = manager.projectiles.pop_back()
	var first_id: int = first.get_instance_id()
	var first_child_count: int = first.get_child_count()
	manager._recycle_projectile(first)
	if first.visible:
		_fail("recycled projectile remained visible")
		return

	manager.spawn_player_projectile(Vector3.ONE, Vector3.FORWARD, 18.0, 4, false, 0.0, 4, color)
	var second = manager.projectiles.pop_back()
	if second.get_instance_id() != first_id:
		_fail("matching projectile did not reuse the pooled instance")
		return
	if second.get_child_count() != first_child_count:
		_fail("reused projectile rebuilt or duplicated its visual children")
		return
	if not second.visible or second.life != 2.5:
		_fail("reused projectile did not reset visibility/lifetime")
		return

	manager._recycle_projectile(second)
	manager.spawn_player_projectile(Vector3.ZERO, Vector3.FORWARD, 18.0, 4, true, 4.0, 7, Color8(255, 130, 40), 0, false, 1.0)
	var rocket = manager.projectiles.pop_back()
	if rocket.get_instance_id() == first_id:
		_fail("different visual variants shared an incompatible pool")
		return

	manager.spawn_grenade(Vector3.ZERO, Vector3(2.0, 4.0, -3.0), "frag", false, 0.72)
	var first_grenade = manager.grenades.pop_back()
	var grenade_id: int = first_grenade.get_instance_id()
	var grenade_child_count: int = first_grenade.get_child_count()
	first_grenade.bounces = 4
	manager._recycle_grenade(first_grenade)
	manager.spawn_grenade(Vector3.ONE, Vector3(1.0, 3.0, -2.0), "frag", false)
	var reused_grenade = manager.grenades.pop_back()
	if reused_grenade.get_instance_id() != grenade_id:
		_fail("matching grenade did not reuse the pooled instance")
		return
	if reused_grenade.get_child_count() != grenade_child_count:
		_fail("reused grenade duplicated its visual children")
		return
	if reused_grenade.bounces != 0 or not is_equal_approx(reused_grenade.timer, 1.05):
		_fail("reused grenade did not reset bounce count/fuse")
		return
	manager._recycle_grenade(reused_grenade)
	manager.spawn_grenade(Vector3.ZERO, Vector3.UP, "cluster_child", true)
	var cluster_child = manager.grenades.pop_back()
	if cluster_child.get_instance_id() == grenade_id:
		_fail("full and lightweight grenade visuals shared an incompatible pool")
		return
	var transient = manager._acquire_transient_mesh()
	var transient_id: int = transient.get_instance_id()
	transient.mesh = BoxMesh.new()
	transient.material_override = shared_glow_a
	manager._recycle_transient_mesh(transient)
	var reused_transient = manager._acquire_transient_mesh()
	if reused_transient.get_instance_id() != transient_id:
		_fail("transient combat mesh did not reuse its pooled instance")
		return
	if reused_transient.mesh != null or reused_transient.material_override != null or not reused_transient.visible:
		_fail("transient combat mesh did not reset render resources/state")
		return

	print("PROJECTILE_POOL_OK reused_id=%d child_count=%d variant_isolated=true" % [first_id, first_child_count])
	print("GRENADE_POOL_OK reused_id=%d child_count=%d variant_isolated=true" % [grenade_id, grenade_child_count])
	print("TRANSIENT_VFX_POOL_OK reused_id=%d" % transient_id)
	quit(0)


func _fail(message: String) -> void:
	push_error("PROJECTILE_POOL_FAIL: %s" % message)
	quit(1)
