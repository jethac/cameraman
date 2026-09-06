@tool
class_name CameramanComposerMath
## Provides camera-space projection, composition, and orientation helpers for framing components.
extends RefCounted

static func project_screen_offset(
	camera_position: Vector3,
	camera_orientation: Quaternion,
	target: Vector3,
	lens: CameramanLens
) -> Vector2:
	var local: Vector3 = camera_orientation.inverse() * (target - camera_position)
	if lens.is_orthographic():
		return Vector2(
			local.x / maxf(lens.orthographic_size * CameramanCameraState.aspect_ratio, 0.001),
			local.y / maxf(lens.orthographic_size, 0.001)
		)
	var depth: float = maxf(-local.z, 0.001)
	var half_height: float = tan(deg_to_rad(lens.fov_degrees) * 0.5)
	var half_width: float = half_height * CameramanCameraState.aspect_ratio
	return Vector2(local.x / depth / half_width, local.y / depth / half_height)

static func get_composition_error(
	screen_offset: Vector2,
	settings: CameramanScreenComposerSettings
) -> Vector2:
	var desired: Vector2 = settings.get_composition_offset()
	var error: Vector2 = desired - screen_offset
	if settings.dead_zone_enabled:
		var half_zone: Vector2 = settings.dead_zone_size * 0.5
		error.x = 0.0 if absf(error.x) <= half_zone.x else error.x - signf(error.x) * half_zone.x
		error.y = 0.0 if absf(error.y) <= half_zone.y else error.y - signf(error.y) * half_zone.y
	if settings.hard_limits_enabled:
		var half_limits: Vector2 = settings.hard_limits_size * 0.5
		var limited: Vector2 = screen_offset - settings.hard_limits_offset
		limited.x = clampf(limited.x, -half_limits.x, half_limits.x)
		limited.y = clampf(limited.y, -half_limits.y, half_limits.y)
		error += settings.hard_limits_offset + limited - screen_offset
	return error

static func rotate_to_composition(
	camera_position: Vector3,
	camera_orientation: Quaternion,
	target: Vector3,
	lens: CameramanLens,
	settings: CameramanScreenComposerSettings,
	delta: float,
	damping: Vector2
) -> Quaternion:
	if (target - camera_position).length_squared() < 1e-8:
		return camera_orientation
	var local: Vector3 = camera_orientation.inverse() * (target - camera_position)
	var current: Vector2 = project_screen_offset(camera_position, camera_orientation, target, lens)
	var invalid_projection: bool = (
		local.z >= -0.001
		or absf(current.x) > 2.0
		or absf(current.y) > 2.0
	)
	var desired: Vector2
	if invalid_projection:
		desired = settings.get_composition_offset()
	else:
		var error: Vector2 = get_composition_error(current, settings)
		var weight: Vector2 = Vector2(
			CameramanDamper.damp(1.0, damping.x, delta),
			CameramanDamper.damp(1.0, damping.y, delta)
		)
		desired = current + error * weight
	var half_height: float = tan(deg_to_rad(lens.fov_degrees) * 0.5)
	var half_width: float = half_height * CameramanCameraState.aspect_ratio
	var local_direction: Vector3 = Vector3(desired.x * half_width, desired.y * half_height, -1.0)
	var target_direction: Vector3 = (target - camera_position).normalized()
	var up: Vector3 = Vector3.FORWARD if absf(target_direction.dot(Vector3.UP)) > 0.999 else Vector3.UP
	var target_basis: Quaternion = Basis.looking_at(
		target_direction,
		up,
		false
	).get_rotation_quaternion()
	return (target_basis * Quaternion(local_direction, Vector3.FORWARD)).normalized()

static func move_to_composition(
	camera_position: Vector3,
	camera_orientation: Quaternion,
	target: Vector3,
	lens: CameramanLens,
	settings: CameramanScreenComposerSettings,
	delta: float,
	damping: Vector3
) -> Vector3:
	var local: Vector3 = camera_orientation.inverse() * (target - camera_position)
	var current: Vector2 = project_screen_offset(camera_position, camera_orientation, target, lens)
	if (
		local.z >= -0.001
		or absf(current.x) > 2.0
		or absf(current.y) > 2.0
	):
		current = current.clamp(Vector2(-2.0, -2.0), Vector2(2.0, 2.0))
	var error: Vector2 = get_composition_error(current, settings)
	var weight: Vector3 = Vector3(
		CameramanDamper.damp(1.0, damping.x, delta),
		CameramanDamper.damp(1.0, damping.y, delta),
		CameramanDamper.damp(1.0, damping.z, delta)
	)
	var right: Vector3 = camera_orientation * Vector3.RIGHT
	var up: Vector3 = camera_orientation * Vector3.UP
	var depth: float = maxf(camera_position.distance_to(target), 0.001)
	var half_height: float = tan(deg_to_rad(lens.fov_degrees) * 0.5) * depth
	var half_width: float = half_height * CameramanCameraState.aspect_ratio
	return right * error.x * half_width * weight.x + up * error.y * half_height * weight.y
