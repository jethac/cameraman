class_name CameramanExternalImpulseListener
extends Node3D

@export_flags_3d_physics var channel_mask: int = 1
@export var gain: float = 1.0
@export var use_2d_distance: bool = false
@export var use_camera_space: bool = false
@export var amplitude_gain: float = 1.0
@export var frequency_gain: float = 1.0
@export var duration: float = 1.0
@export var secondary_noise_profile: CameramanNoiseProfile

var _reaction_time: float = 0.0

func _process(delta: float) -> void:
	_reaction_time = maxf(_reaction_time - delta, 0.0)
	var result: Array[Variant] = CameramanCore.get_impulse_manager().get_impulse_at(
		global_position,
		use_2d_distance,
		channel_mask
	)
	var position_signal: Vector3 = result[0] as Vector3
	var rotation_signal: Quaternion = result[1] as Quaternion
	var magnitude: float = position_signal.length()
	if magnitude > 0.0:
		_reaction_time = duration
	global_position += position_signal * gain * amplitude_gain
	global_basis = (global_basis * Basis(rotation_signal)).orthonormalized()
	if secondary_noise_profile != null and _reaction_time > 0.0:
		var noise_time: float = (duration - _reaction_time) * frequency_gain
		global_position += secondary_noise_profile.evaluate_position(noise_time) * magnitude * amplitude_gain
		global_basis = (
			global_basis
			* Basis(Quaternion.from_euler(
				secondary_noise_profile.evaluate_orientation(noise_time) * magnitude * amplitude_gain
			))
		).orthonormalized()
