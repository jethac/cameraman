@tool
class_name CameramanHardLookAt
## Provides the hard look at camera pipeline component.
## Key properties include `look_at_offset`, which configure its behavior.
extends CameramanComponent

## Configures the look at offset used by this type.
@export var look_at_offset: Vector3 = Vector3.ZERO

## Returns the pipeline stage handled by this type.
func stage() -> CameramanCore.Stage:
	return CameramanCore.Stage.AIM

## Applies this component's camera-state mutation for the current pipeline step.
func mutate_camera_state(state: CameramanCameraState, _delta: float) -> void:
	if not state.has_look_at():
		return
	var target: Vector3 = state.reference_look_at + look_at_offset
	var direction: Vector3 = target - state.get_final_position()
	if direction.length_squared() < 0.000001:
		return
	var up: Vector3 = (
		Vector3.FORWARD
		if absf(direction.normalized().dot(state.reference_up)) > 0.999
		else state.reference_up
	)
	state.raw_orientation = Basis.looking_at(direction.normalized(), up, false).get_rotation_quaternion()
