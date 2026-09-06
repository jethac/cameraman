@tool
class_name CameramanDamper
extends RefCounted

const _RESPONSE: float = 6.9077554

static func damp(initial: float, damp_time: float, delta: float) -> float:
	if delta < 0.0:
		return 0.0
	if damp_time <= 0.0:
		return initial
	return initial * (1.0 - exp(-_RESPONSE * delta / damp_time))

static func damp_vector(initial: Vector3, damp_time: Vector3, delta: float) -> Vector3:
	return Vector3(
		damp(initial.x, damp_time.x, delta),
		damp(initial.y, damp_time.y, delta),
		damp(initial.z, damp_time.z, delta)
	)

static func max_damp_time(damp_time: Vector3) -> float:
	return maxf(damp_time.x, maxf(damp_time.y, damp_time.z))

static func damp_vector2(initial: Vector2, damp_time: Vector2, delta: float) -> Vector2:
	return Vector2(
		damp(initial.x, damp_time.x, delta),
		damp(initial.y, damp_time.y, delta)
	)
