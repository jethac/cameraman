class_name CameramanBasicMultiChannelPerlin
extends CameramanComponent

@export var noise_profile: CameramanNoiseProfile
@export var pivot_offset: Vector3 = Vector3.ZERO
@export var amplitude_gain: float = 1.0
@export var frequency_gain: float = 1.0

func stage() -> CameramanCore.Stage:
	return CameramanCore.Stage.NOISE

func mutate_camera_state(state: CameramanCameraState, _delta: float) -> void:
	if noise_profile == null:
		return
	var time_value: float = CameramanCore.current_time() * frequency_gain
	state.position_correction += noise_profile.evaluate_position(time_value) * amplitude_gain
	var orientation_noise: Vector3 = noise_profile.evaluate_orientation(time_value) * amplitude_gain
	state.orientation_correction = (
		state.orientation_correction * Quaternion.from_euler(orientation_noise)
	).normalized()

func reseed() -> void:
	if noise_profile != null:
		noise_profile.reseed()
