class_name CameramanImpulseEvent
extends RefCounted

var position: Vector3
var signal_velocity: Vector3
var radius: float
var duration: float
var channel: int
var start_time: float
var impulse_type: int
var dissipation_rate: float
var dissipation_distance: float
var envelope_shape: int = 1
var custom_curve: Curve

func get_decayed_signal(listener_position: Vector3, use_2d: bool, now: float) -> Array[Variant]:
	var elapsed: float = now - start_time
	if elapsed < 0.0 or elapsed >= duration:
		return [Vector3.ZERO, Quaternion.IDENTITY]
	var normalized_time: float = clampf(elapsed / maxf(duration, 0.0001), 0.0, 1.0)
	var time_weight: float = 1.0 - normalized_time
	if envelope_shape == 2:
		time_weight = sin(normalized_time * PI)
	elif envelope_shape == 3:
		time_weight = sin(normalized_time * TAU * 8.0) * (1.0 - normalized_time)
	elif envelope_shape == 4 and custom_curve != null:
		time_weight = custom_curve.sample(normalized_time)
	var distance: Vector3 = listener_position - position
	if use_2d:
		distance.y = 0.0
	var distance_weight: float = 1.0
	if dissipation_distance > 0.0:
		distance_weight = clampf(1.0 - distance.length() / dissipation_distance, 0.0, 1.0)
	var weight: float = time_weight * pow(distance_weight, maxf(dissipation_rate, 0.001))
	var signal_value: Vector3 = signal_velocity * weight
	return [signal_value, Quaternion.from_euler(signal_value * 0.1)]

func is_expired(now: float) -> bool:
	return now - start_time >= duration
