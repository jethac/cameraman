class_name CameramanBasicMultiChannelPerlin
extends CameramanComponent

@export var noise_profile: CameramanNoiseProfile
@export var pivot_offset: Vector3 = Vector3.ZERO
@export var amplitude_gain: float = 1.0
@export var frequency_gain: float = 1.0

var noise_time: float = 0.0

func stage() -> CameramanCore.Stage:
	return CameramanCore.Stage.NOISE

func mutate_camera_state(state: CameramanCameraState, delta: float) -> void:
	if noise_profile == null:
		return
	if delta >= 0.0:
		noise_time += delta
	var time_value: float = noise_time * frequency_gain
	state.position_correction += (
		noise_profile.evaluate_position(time_value + pivot_offset.x) * amplitude_gain
	)
	var orientation_noise: Vector3 = noise_profile.evaluate_orientation(time_value) * amplitude_gain
	state.orientation_correction = (
		state.orientation_correction * Quaternion.from_euler(orientation_noise)
	).normalized()

func reseed() -> void:
	noise_time = 0.0
	if noise_profile != null:
		noise_profile.reseed()
