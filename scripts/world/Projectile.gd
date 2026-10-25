extends Node3D
class_name Projectile

var velocity = Vector3.ZERO
var damage = 1
var life = 2.5
var projectile_owner = "enemy"
var explosive = false
var radius = 0.0
var level_manager
var player
var visual: Node3D
var trail: MeshInstance3D
var impact_color = Color.WHITE
var bounce_count = 0
var max_bounces = 0
var split_on_impact = false
var visual_scale = 1.0
var burn_on_impact = false
var homing_enabled = false
var homing_strength = 0.0
var homing_range = 0.0
var slow_on_hit = false
var effect_type = ""
var saw_hit_ids = {}
var pool_key := ""

func configure(factory, color: Color, start: Vector3, vel: Vector3, dmg: int, who: String, lm, player_node, is_explosive = false, explosion_radius = 0.0, bounces: int = 0, should_split: bool = false, v_scale: float = 1.0, should_burn: bool = false, should_home: bool = false, should_slow: bool = false, p_effect_type: String = "", p_pool_key: String = "") -> void:
	visible = true
	pool_key = p_pool_key
	global_position = start
	velocity = vel
	damage = dmg
	projectile_owner = who
	level_manager = lm
	player = player_node
	explosive = is_explosive
	radius = explosion_radius
	impact_color = color
	max_bounces = bounces
	bounce_count = 0
	split_on_impact = should_split
	visual_scale = v_scale
	burn_on_impact = should_burn
	homing_enabled = should_home
	homing_strength = 12.4 if should_home else 0.0
	homing_range = 46.0 if should_home else 0.0
	slow_on_hit = should_slow
	effect_type = p_effect_type
	saw_hit_ids.clear()
	life = 2.5
	if burn_on_impact and not explosive:
		life = 0.86
	if visual == null:
		if effect_type == "saw":
			life = 3.2
			_build_saw_visual(factory, color)
		elif explosive and projectile_owner == "player":
			_build_rocket_visual(factory, color)
		else:
			_build_orb_visual(factory, color)
	elif effect_type == "saw":
		life = 3.2
	if velocity.length() > 0.01:
		look_at(global_position + velocity.normalized(), Vector3.UP)

func deactivate_for_pool() -> void:
	visible = false
	velocity = Vector3.ZERO
	level_manager = null
	player = null
	saw_hit_ids.clear()

func _build_orb_visual(factory, color: Color) -> void:
	visual = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = (0.16 if not explosive else 0.22) * visual_scale
	mesh.height = mesh.radius * 2.0
	visual.mesh = mesh
	visual.material_override = factory.make_glow_material(color, 0.92)
	add_child(visual)
	trail = MeshInstance3D.new()
	var trail_mesh = BoxMesh.new()
	trail_mesh.size = Vector3(0.08 * visual_scale, 0.08 * visual_scale, (0.9 if not explosive else 1.15) * visual_scale)
	trail.mesh = trail_mesh
	trail.position.z = 0.38
	trail.material_override = factory.make_glow_material(color, 0.35)
	add_child(trail)

func _build_rocket_visual(factory, color: Color) -> void:
	visual = Node3D.new()
	visual.name = "RocketVisual"
	add_child(visual)
	var dark = factory.make_flat_material(Color8(30, 34, 36))
	var armor = factory.make_flat_material(Color8(198, 196, 178))
	var yellow = factory.make_glow_material(Color8(255, 190, 46), 0.72)
	var flame = factory.make_glow_material(Color8(255, 92, 24), 0.95)
	var body = MeshInstance3D.new()
	var body_mesh = CylinderMesh.new()
	body_mesh.top_radius = 0.17 * visual_scale
	body_mesh.bottom_radius = 0.19 * visual_scale
	body_mesh.height = 0.92 * visual_scale
	body_mesh.radial_segments = 8
	body.mesh = body_mesh
	body.rotation_degrees.x = 90
	body.material_override = armor
	visual.add_child(body)
	var nose = MeshInstance3D.new()
	var nose_mesh = CylinderMesh.new()
	nose_mesh.top_radius = 0.0
	nose_mesh.bottom_radius = 0.18 * visual_scale
	nose_mesh.height = 0.34 * visual_scale
	nose_mesh.radial_segments = 8
	nose.mesh = nose_mesh
	nose.position.z = -0.62 * visual_scale
	nose.rotation_degrees.x = 90
	nose.material_override = yellow
	visual.add_child(nose)
	for x in [-0.17, 0.17]:
		var fin = MeshInstance3D.new()
		var fin_mesh = BoxMesh.new()
		fin_mesh.size = Vector3(0.075, 0.24, 0.28) * visual_scale
		fin.mesh = fin_mesh
		fin.position = Vector3(x * visual_scale, -0.02, 0.42 * visual_scale)
		fin.rotation_degrees.z = 18 if x > 0 else -18
		fin.material_override = dark
		visual.add_child(fin)
	trail = MeshInstance3D.new()
	var trail_mesh = CylinderMesh.new()
	trail_mesh.top_radius = 0.07 * visual_scale
	trail_mesh.bottom_radius = 0.28 * visual_scale
	trail_mesh.height = 1.35 * visual_scale
	trail_mesh.radial_segments = 8
	trail.mesh = trail_mesh
	trail.position.z = 1.02 * visual_scale
	trail.rotation_degrees.x = 90
	trail.material_override = flame
	add_child(trail)

func _build_saw_visual(factory, color: Color) -> void:
	visual = Node3D.new()
	visual.name = "SawVisual"
	add_child(visual)
	var disc = MeshInstance3D.new()
	var disc_mesh = CylinderMesh.new()
	disc_mesh.top_radius = 0.34 * visual_scale
	disc_mesh.bottom_radius = 0.34 * visual_scale
	disc_mesh.height = 0.055 * visual_scale
	disc_mesh.radial_segments = 18
	disc.mesh = disc_mesh
	disc.rotation_degrees.x = 90
	disc.material_override = factory.make_flat_material(Color8(208, 212, 208))
	visual.add_child(disc)
	for i in 8:
		var tooth = MeshInstance3D.new()
		var tooth_mesh = BoxMesh.new()
		tooth_mesh.size = Vector3(0.12, 0.035, 0.20) * visual_scale
		tooth.mesh = tooth_mesh
		var a = TAU * float(i) / 8.0
		tooth.position = Vector3(cos(a) * 0.36, sin(a) * 0.36, 0) * visual_scale
		tooth.rotation_degrees.z = rad_to_deg(a)
		tooth.material_override = factory.make_glow_material(color.lightened(0.16), 0.52)
		visual.add_child(tooth)
	trail = MeshInstance3D.new()
	var trail_mesh = BoxMesh.new()
	trail_mesh.size = Vector3(0.08, 0.08, 0.86) * visual_scale
	trail.mesh = trail_mesh
	trail.position.z = 0.42 * visual_scale
	trail.material_override = factory.make_glow_material(color, 0.34)
	add_child(trail)

func tick(dt: float) -> bool:
	life -= dt
	if effect_type == "saw" and visual != null:
		visual.rotate_z(32.0 * dt)
	if homing_enabled and projectile_owner == "player" and level_manager != null and level_manager.has_method("aimed_enemy_for_homing"):
		var target = level_manager.aimed_enemy_for_homing(global_position, velocity.normalized(), homing_range)
		if target != null and is_instance_valid(target) and not target.dead:
			var aim_pos = target.global_position + Vector3(0, target.stats.height * 0.56, 0)
			var desired = (aim_pos - global_position).normalized() * velocity.length()
			velocity = velocity.lerp(desired, clamp(dt * homing_strength, 0.0, 0.38))
	var from = global_position
	var to = global_position + velocity * dt
	var wall_hit = level_manager.wall_hit_along_segment(from, to, 0.08)
	if wall_hit.hit:
		global_position = wall_hit.position
		if not explosive:
			level_manager.spawn_impact_fx(global_position, impact_color)
		if explosive:
			level_manager.explode(global_position, radius, damage, 0.42 if projectile_owner == "player" else 0.82, 1.0 if projectile_owner == "player" else 0.0)
			if projectile_owner == "player" and effect_type == "cluster_round" and level_manager.has_method("spawn_cluster_grenades"):
				level_manager.spawn_cluster_grenades(global_position, impact_color)
			if projectile_owner == "player" and burn_on_impact:
				var burn_radius = max(2.2, radius * (0.66 if effect_type == "inferno" else 0.92))
				var patch_color = Color8(255, 116, 32) if effect_type == "inferno" else impact_color
				level_manager.spawn_burning_patch(global_position, patch_color, burn_radius, 5.8, max(6.0, float(damage) * 0.48))
			return false
		if projectile_owner == "player" and effect_type == "cryo" and level_manager.has_method("spawn_status_field"):
			level_manager.spawn_status_field(global_position, "cryo", Color8(118, 226, 255), 3.6, 3.4, 0.44)
			return false
		if projectile_owner == "player" and burn_on_impact:
			var wall_patch_radius = 3.2 if effect_type in ["toxic", "toxic_pool"] else 1.65
			var wall_patch_dps = 6.8 if effect_type in ["toxic", "toxic_pool"] else 5.2
			level_manager.spawn_burning_patch(global_position, impact_color, wall_patch_radius, 4.2, wall_patch_dps)
			return false
		if projectile_owner == "player" and split_on_impact:
			level_manager.split_plasma(global_position, velocity.normalized(), damage, impact_color)
			return false
		if projectile_owner == "player" and max_bounces > bounce_count and not explosive:
			bounce_count += 1
			var normal = wall_hit.normal.normalized()
			if normal.length() <= 0.01:
				normal = -velocity.normalized()
			velocity = velocity.bounce(normal) * 0.86
			global_position += normal * 0.16
			life = max(0.18, life - 0.08)
			if velocity.length() > 0.01:
				look_at(global_position + velocity.normalized(), Vector3.UP)
			return true
		return false
	global_position = to
	if velocity.length() > 0.01:
		look_at(global_position + velocity.normalized(), Vector3.UP)
	if life <= 0.0:
		if not explosive:
			level_manager.spawn_impact_fx(global_position, impact_color)
		if explosive:
			level_manager.explode(global_position, radius, damage, 0.42 if projectile_owner == "player" else 0.82, 1.0 if projectile_owner == "player" else 0.0)
			if projectile_owner == "player" and effect_type == "cluster_round" and level_manager.has_method("spawn_cluster_grenades"):
				level_manager.spawn_cluster_grenades(global_position, impact_color)
			if projectile_owner == "player" and burn_on_impact:
				var burn_radius = max(2.2, radius * (0.66 if effect_type == "inferno" else 0.92))
				var patch_color = Color8(255, 116, 32) if effect_type == "inferno" else impact_color
				level_manager.spawn_burning_patch(global_position, patch_color, burn_radius, 5.8, max(6.0, float(damage) * 0.48))
			return false
		if projectile_owner == "player" and effect_type == "cryo" and level_manager.has_method("spawn_status_field"):
			level_manager.spawn_status_field(global_position, "cryo", Color8(118, 226, 255), 3.4, 3.2, 0.42)
			return false
		if projectile_owner == "player" and burn_on_impact:
			var life_patch_radius = 3.2 if effect_type in ["toxic", "toxic_pool"] else 1.65
			var life_patch_dps = 6.8 if effect_type in ["toxic", "toxic_pool"] else 5.2
			level_manager.spawn_burning_patch(global_position, impact_color, life_patch_radius, 4.2, life_patch_dps)
			return false
		return false
	if projectile_owner == "enemy":
		if level_manager.segment_hits_player(from, global_position, 0.75):
			if not explosive:
				level_manager.spawn_impact_fx(global_position, impact_color)
			if explosive:
				level_manager.explode(global_position, radius, damage, 0.82, 0.0)
			else:
				if slow_on_hit and player.has_method("apply_slow"):
					player.apply_slow(0.46, 1.55)
				player.damage(damage)
			return false
		var turret_hit = level_manager.find_turret_along_segment(from, global_position, 0.38) if level_manager.has_method("find_turret_along_segment") else null
		if turret_hit != null:
			if not explosive:
				level_manager.spawn_impact_fx(global_position, impact_color)
			if explosive:
				level_manager.explode(global_position, radius, damage, 0.82, 0.0)
			else:
				turret_hit.damage(damage, global_position)
			return false
	else:
		var hit = level_manager.find_enemy_along_segment(from, global_position, 0.45)
		if hit != null:
			if effect_type == "saw":
				var hit_id = str(hit.get_instance_id())
				if not saw_hit_ids.has(hit_id):
					saw_hit_ids[hit_id] = true
					level_manager.damage_enemy(hit, damage, global_position)
					level_manager.spawn_impact_fx(global_position, impact_color)
					if hit.has_method("apply_impulse"):
						hit.apply_impulse(velocity.normalized() * 2.4)
				life = max(0.16, life - 0.14)
				return life > 0.0
			level_manager.damage_enemy(hit, damage, global_position)
			level_manager.spawn_impact_fx(global_position, impact_color)
			if effect_type == "cryo" and level_manager.has_method("apply_enemy_status"):
				level_manager.apply_enemy_status(hit, "slow", 0.48, 1.65)
				if randf() < 0.26:
					level_manager.apply_enemy_status(hit, "freeze", 0.0, 0.58)
				if level_manager.has_method("spawn_status_field"):
					level_manager.spawn_status_field(global_position, "cryo", Color8(118, 226, 255), 3.35, 3.2, 0.42)
				return false
			if burn_on_impact:
				var hit_radius = 3.2 if effect_type in ["toxic", "toxic_pool"] else 1.65
				var hit_dps = 6.8 if effect_type in ["toxic", "toxic_pool"] else 5.2
				level_manager.spawn_burning_patch(global_position, impact_color, hit_radius, 4.2, hit_dps)
				return false
			if split_on_impact:
				level_manager.split_plasma(global_position, velocity.normalized(), damage, impact_color)
				return false
			if explosive:
				level_manager.explode(global_position, radius, damage, 0.42)
				if effect_type == "cluster_round" and level_manager.has_method("spawn_cluster_grenades"):
					level_manager.spawn_cluster_grenades(global_position, impact_color)
				if burn_on_impact:
					var burn_radius = max(2.2, radius * (0.66 if effect_type == "inferno" else 0.92))
					var patch_color = Color8(255, 116, 32) if effect_type == "inferno" else impact_color
					level_manager.spawn_burning_patch(global_position, patch_color, burn_radius, 5.8, max(6.0, float(damage) * 0.48))
			return false
	return true
