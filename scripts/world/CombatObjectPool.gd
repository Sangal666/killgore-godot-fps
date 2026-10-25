extends RefCounted
class_name CombatObjectPool

## Owns the reusable combat-object lifecycle independently from LevelManager.
## LevelManager keeps gameplay decisions; this service only acquires, resets and
## caps projectile, grenade and short-lived mesh instances.

const ProjectileScript = preload("res://scripts/world/Projectile.gd")
const GrenadeScript = preload("res://scripts/world/Grenade.gd")
const MAX_PROJECTILES_PER_KEY := 20
const MAX_GRENADES_PER_KEY := 14
const MAX_TRANSIENT_MESHES := 96

var root: Node3D
var projectile_pools := {}
var grenade_pools := {}
var transient_meshes: Array[MeshInstance3D] = []


func configure(projectile_root: Node3D) -> void:
	root = projectile_root


func projectile_key(owner_id: String, explosive: bool, effect_type: String, color: Color, visual_scale: float) -> String:
	var visual_kind := "saw" if effect_type == "saw" else ("rocket" if explosive and owner_id == "player" else "orb")
	return "%s:%s:%08x:%.2f" % [owner_id, visual_kind, color.to_rgba32(), snappedf(visual_scale, 0.01)]


func acquire_projectile(pool_key: String):
	var pool: Array = projectile_pools.get(pool_key, [])
	while not pool.is_empty():
		var projectile = pool.pop_back()
		projectile_pools[pool_key] = pool
		if is_instance_valid(projectile):
			return projectile
	var projectile = ProjectileScript.new()
	projectile.pool_key = pool_key
	root.add_child(projectile)
	return projectile


func recycle_projectile(projectile) -> void:
	var pool_key := String(projectile.pool_key)
	if pool_key.is_empty():
		projectile.queue_free()
		return
	projectile.deactivate_for_pool()
	var pool: Array = projectile_pools.get(pool_key, [])
	if pool.size() >= MAX_PROJECTILES_PER_KEY:
		projectile.queue_free()
		return
	pool.append(projectile)
	projectile_pools[pool_key] = pool


func acquire_grenade(pool_key: String):
	var pool: Array = grenade_pools.get(pool_key, [])
	while not pool.is_empty():
		var grenade = pool.pop_back()
		grenade_pools[pool_key] = pool
		if is_instance_valid(grenade):
			return grenade
	var grenade = GrenadeScript.new()
	grenade.pool_key = pool_key
	root.add_child(grenade)
	return grenade


func recycle_grenade(grenade) -> void:
	var pool_key := String(grenade.pool_key)
	if pool_key.is_empty():
		grenade.queue_free()
		return
	grenade.deactivate_for_pool()
	var pool: Array = grenade_pools.get(pool_key, [])
	if pool.size() >= MAX_GRENADES_PER_KEY:
		grenade.queue_free()
		return
	pool.append(grenade)
	grenade_pools[pool_key] = pool


func acquire_transient_mesh() -> MeshInstance3D:
	while not transient_meshes.is_empty():
		var pooled: MeshInstance3D = transient_meshes.pop_back()
		if is_instance_valid(pooled):
			pooled.visible = true
			pooled.position = Vector3.ZERO
			pooled.rotation = Vector3.ZERO
			pooled.scale = Vector3.ONE
			pooled.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			return pooled
	var created := MeshInstance3D.new()
	created.set_meta("killgore_transient_mesh", true)
	root.add_child(created)
	return created


func recycle_transient_mesh(mesh_instance) -> void:
	if not is_instance_valid(mesh_instance) or not bool(mesh_instance.get_meta("killgore_transient_mesh", false)):
		return
	if transient_meshes.has(mesh_instance):
		return
	mesh_instance.visible = false
	mesh_instance.mesh = null
	mesh_instance.material_override = null
	if transient_meshes.size() >= MAX_TRANSIENT_MESHES:
		mesh_instance.queue_free()
		return
	transient_meshes.append(mesh_instance)


func clear() -> void:
	projectile_pools.clear()
	grenade_pools.clear()
	transient_meshes.clear()
