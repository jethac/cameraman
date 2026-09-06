@tool
class_name CameramanExternalImpulseListener
## Provides the external impulse listener scene node.
## Key properties include `channel_mask`, `gain`, `use_2d_distance`, and related settings, which configure its
## behavior.
extends Node3D

## Selects the physics layers or camera channels used by channel mask.
@export_flags_3d_physics var channel_mask: int = 1
## Configures the gain used by this type.
@export var gain: float = 1.0
## Sets the use 2d distance used by this type.
@export var use_2d_distance: bool = false
## Configures the use camera space used by this type.
@export var use_camera_space: bool = false
## Configures the amplitude gain used by this type.
@export var amplitude_gain: float = 1.0
## Configures the frequency gain used by this type.
@export var frequency_gain: float = 1.0
## Configures the duration used by this type.
@export var duration: float = 1.0
## Configures the secondary noise profile used by this type.
@export var secondary_noise_profile: CameramanNoiseProfile

var _reaction_time: float = 0.0
var _last_position_offset: Vector3 = Vector3.ZERO
var _last_rotation_offset: Quaternion = Quaternion.IDENTITY

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	global_position -= _last_position_offset
	global_basis = (global_basis * Basis(_last_rotation_offset.inverse())).orthonormalized()
	_last_position_offset = Vector3.ZERO
	_last_rotation_offset = Quaternion.IDENTITY
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
	var position_offset: Vector3 = position_signal * gain * amplitude_gain
	var rotation_offset: Quaternion = rotation_signal
	if secondary_noise_profile != null and _reaction_time > 0.0:
		var noise_time: float = (duration - _reaction_time) * frequency_gain
		position_offset += secondary_noise_profile.evaluate_position(noise_time) * magnitude * amplitude_gain
		rotation_offset = (
			rotation_offset
			* Quaternion.from_euler(
				secondary_noise_profile.evaluate_orientation(noise_time) * magnitude * amplitude_gain
			)
		).normalized()
	global_position += position_offset
	global_basis = (global_basis * Basis(rotation_offset)).orthonormalized()
	_last_position_offset = position_offset
	_last_rotation_offset = rotation_offset
