@tool
class_name CameramanHardLookAt
## AIM-stage component that points the camera at a target from the corrected camera position.
extends CameramanComponent

## Offset added to the selected look-at target before computing camera orientation.
@export var look_at_offset: Vector3 = Vector3.ZERO

func stage() -> CameramanCore.Stage:
	return CameramanCore.Stage.AIM

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
