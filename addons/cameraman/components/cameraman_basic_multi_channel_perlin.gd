@tool
class_name CameramanBasicMultiChannelPerlin
## NOISE-stage component that adds independent Perlin position and rotation offsets to camera
## state.
extends CameramanComponent

## Position and orientation channels sampled during the NOISE stage.
@export var noise_profile: CameramanNoiseProfile
## Point around which position noise is applied in camera-local space.
@export var pivot_offset: Vector3 = Vector3.ZERO
## Multiplies sampled position and orientation noise amplitudes.
@export var amplitude_gain: float = 1.0
## Multiplies the time frequency used to sample the noise profile.
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

## Reseeds all noise channels so subsequent samples use a new sequence.
func reseed() -> void:
	noise_time = 0.0
	if noise_profile != null:
		noise_profile.reseed()
