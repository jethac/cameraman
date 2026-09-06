@tool
class_name CameramanImpulseListener
## Applies impulse events to a camera during the impulse pipeline stage.
## Key properties include `channel_mask`, `gain`, `use_2d_distance`, and related settings, which configure its
## behavior.
extends CameramanComponent

## Selects the physics layers or camera channels used by channel mask.
@export_flags_3d_physics var channel_mask: int = 1
## Configures the gain used by this type.
@export var gain: float = 1.0
## Sets the use 2d distance used by this type.
@export var use_2d_distance: bool = false
## Configures the use camera space used by this type.
@export var use_camera_space: bool = false
## Configures the apply after used by this type.
@export var apply_after: CameramanCore.Stage = CameramanCore.Stage.NOISE
## Configures the amplitude gain used by this type.
@export var amplitude_gain: float = 1.0
## Configures the frequency gain used by this type.
@export var frequency_gain: float = 1.0
## Configures the duration used by this type.
@export var duration: float = 1.0
## Configures the secondary noise profile used by this type.
@export var secondary_noise_profile: CameramanNoiseProfile

var _reaction_time: float = 0.0

## Returns the pipeline stage handled by this type.
func stage() -> CameramanCore.Stage:
	return apply_after

## Applies this component's camera-state mutation for the current pipeline step.
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
