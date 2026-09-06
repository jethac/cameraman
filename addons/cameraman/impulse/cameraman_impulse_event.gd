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
var propagation_speed: float = 0.0
var envelope_curve: Curve
var ignore_time_scale: bool = false
var frequency_gain: float = 1.0

func get_decayed_signal(listener_position: Vector3, use_2d: bool, now: float) -> Array[Variant]:
	var elapsed: float = now - start_time
	var distance: Vector3 = listener_position - position
	if use_2d:
		distance.y = 0.0
	var propagation_delay: float = 0.0
	if impulse_type == 2 and propagation_speed > 0.0:
		propagation_delay = distance.length() / propagation_speed
	if elapsed < propagation_delay:
		return [Vector3.ZERO, Quaternion.IDENTITY]
	var active_elapsed: float = elapsed - propagation_delay
	if active_elapsed >= duration:
		return [Vector3.ZERO, Quaternion.IDENTITY]
	var normalized_time: float = clampf(
		active_elapsed / maxf(duration, 0.0001) * frequency_gain,
		0.0,
		1.0
	)
	var time_weight: float = envelope_curve.sample(normalized_time) if envelope_curve != null else (
		custom_curve.sample(normalized_time) if custom_curve != null else 1.0 - normalized_time
	)
	var distance_weight: float = 1.0
	if impulse_type == 1 and dissipation_distance > 0.0:
		distance_weight = clampf(1.0 - distance.length() / dissipation_distance, 0.0, 1.0)
	var weight: float = time_weight * pow(distance_weight, maxf(dissipation_rate, 0.001))
	var signal_value: Vector3 = signal_velocity * weight
	return [signal_value, Quaternion.from_euler(signal_value * 0.1)]

func is_expired(now: float) -> bool:
	if impulse_type == 2:
		return now - start_time >= duration + 60.0
	return now - start_time >= duration
