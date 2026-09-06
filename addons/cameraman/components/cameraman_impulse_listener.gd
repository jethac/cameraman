class_name CameramanImpulseListener
extends CameramanComponent

@export_flags_3d_physics var channel_mask: int = 1
@export var gain: float = 1.0
@export var use_2d_distance: bool = false
@export var use_camera_space: bool = false
@export var apply_after: CameramanCore.Stage = CameramanCore.Stage.NOISE
@export var amplitude_gain: float = 1.0
@export var frequency_gain: float = 1.0
@export var duration: float = 1.0
@export var secondary_noise_profile: CameramanNoiseProfile

var _reaction_time: float = 0.0

func stage() -> CameramanCore.Stage:
	return apply_after

func mutate_camera_state(state: CameramanCameraState, delta: float) -> void:
	if delta >= 0.0:
		_reaction_time = maxf(_reaction_time - delta, 0.0)
	var result: Array[Variant] = CameramanCore.get_impulse_manager().get_impulse_at(
		state.raw_position,
		use_2d_distance,
		channel_mask
	)
	var signal_position: Vector3 = result[0] as Vector3
	if use_camera_space:
		signal_position = state.raw_orientation * signal_position
	state.position_correction += signal_position * gain * amplitude_gain
	state.orientation_correction = (
		state.orientation_correction * (result[1] as Quaternion)
	).normalized()
	var magnitude: float = signal_position.length()
	if magnitude > 0.0:
		_reaction_time = duration
	if secondary_noise_profile != null and _reaction_time > 0.0:
		var noise_time: float = (duration - _reaction_time) * frequency_gain
		state.position_correction += secondary_noise_profile.evaluate_position(noise_time) * magnitude * amplitude_gain
		state.orientation_correction = (
			state.orientation_correction
			* Quaternion.from_euler(
				secondary_noise_profile.evaluate_orientation(noise_time) * magnitude * amplitude_gain
			)
		).normalized()
