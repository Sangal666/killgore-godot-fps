extends MeshInstance3D
class_name Gib

var velocity = Vector3.ZERO
var angular_velocity = Vector3.ZERO
var level_manager
var age = 0.0
var lifetime = 4.5
var radius = 0.09
var settled = false

func configure(lm, start_velocity: Vector3, start_angular: Vector3, life: float, hit_radius: float) -> void:
	level_manager = lm
	velocity = start_velocity
	angular_velocity = start_angular
	lifetime = life
	radius = hit_radius
	set_process(true)

func _process(delta: float) -> void:
	age += delta
	if not settled:
		velocity.y -= 15.5 * delta
		var from = global_position
		var to = global_position + velocity * delta
		var wall = level_manager.wall_hit_along_segment(from, to, radius)
		if wall.hit:
			global_position = wall.position + wall.normal * radius
			velocity = velocity.bounce(wall.normal.normalized()) * 0.38
			angular_velocity *= 0.72
		else:
			global_position = to
		var floor_y = level_manager.floor_height_at(global_position) + radius
		if global_position.y <= floor_y:
			global_position.y = floor_y
			if abs(velocity.y) > 1.2:
				velocity.y = -velocity.y * 0.24
				velocity.x *= 0.74
				velocity.z *= 0.74
			else:
				velocity.y = 0.0
				velocity.x = move_toward(velocity.x, 0.0, 6.0 * delta)
				velocity.z = move_toward(velocity.z, 0.0, 6.0 * delta)
				angular_velocity = angular_velocity.move_toward(Vector3.ZERO, 9.0 * delta)
				if Vector2(velocity.x, velocity.z).length() < 0.05 and angular_velocity.length() < 0.12:
					settled = true
		rotation_degrees += angular_velocity * delta
	else:
		velocity = Vector3.ZERO
	if age > lifetime - 0.35:
		scale = scale.move_toward(Vector3.ZERO, delta * 3.2)
	if age >= lifetime or scale.length() < 0.03:
		queue_free()
