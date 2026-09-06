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

func stage() -> CameramanCore.Stage:
	return apply_after

func mutate_camera_state(state: CameramanCameraState, _delta: float) -> void:
	var result: Array[Variant] = CameramanCore.get_impulse_manager().get_impulse_at(
		state.raw_position,
		use_2d_distance,
		channel_mask
	)
	state.position_correction += (result[0] as Vector3) * gain * amplitude_gain
	state.orientation_correction = (
		state.orientation_correction * (result[1] as Quaternion)
	).normalized()
