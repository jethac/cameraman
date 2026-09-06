@tool
class_name CameramanLookahead
extends RefCounted

var _samples: Array[Dictionary] = []

func record(position: Vector3, time_value: float) -> void:
	_samples.append({"position": position, "time": time_value})
	while _samples.size() > 8:
		_samples.pop_front()

func predict(time_ahead: float, ignore_y: bool = false) -> Vector3:
	if _samples.is_empty():
		return Vector3.ZERO
	var latest: Dictionary = _samples.back()
	if _samples.size() < 2:
		return latest["position"] as Vector3
	var first: Dictionary = _samples[0]
	var elapsed: float = float(latest["time"]) - float(first["time"])
	if elapsed <= 0.000001:
		return latest["position"] as Vector3
	var velocity: Vector3 = (
		(latest["position"] as Vector3) - (first["position"] as Vector3)
	) / elapsed
	if ignore_y:
		velocity.y = 0.0
	return (latest["position"] as Vector3) + velocity * time_ahead

func clear() -> void:
	_samples.clear()
