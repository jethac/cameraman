@tool
class_name CameramanInputAxisDriver
## Provides acceleration and deceleration math for input axis values.
extends RefCounted

var value: float = 0.0

func update(target: float, delta: float, accel_time: float, decel_time: float) -> float:
	var duration: float = accel_time if absf(target) > absf(value) else decel_time
	var weight: float = 1.0 if duration <= 0.0 else CameramanDamper.damp(1.0, duration, delta)
	value = lerpf(value, target, weight)
	return value
