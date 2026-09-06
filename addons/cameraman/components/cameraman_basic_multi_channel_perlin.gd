@tool
class_name CameramanBasicMultiChannelPerlin
## Provides the basic multi channel perlin camera pipeline component.
## Key properties include `noise_profile`, `pivot_offset`, `amplitude_gain`, and related settings, which configure its
## behavior.
extends CameramanComponent

## Configures the noise profile used by this type.
@export var noise_profile: CameramanNoiseProfile
## Configures the pivot offset used by this type.
@export var pivot_offset: Vector3 = Vector3.ZERO
## Configures the amplitude gain used by this type.
@export var amplitude_gain: float = 1.0
## Configures the frequency gain used by this type.
@export var frequency_gain: float = 1.0

var noise_time: float = 0.0

## Returns the pipeline stage handled by this type.
func stage() -> CameramanCore.Stage:
	return CameramanCore.Stage.NOISE

## Applies this component's camera-state mutation for the current pipeline step.
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

## Reseeds the noise generators.
func reseed() -> void:
	noise_time = 0.0
	if noise_profile != null:
		noise_profile.reseed()
