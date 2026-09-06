class_name CameramanHardLookAt
extends CameramanComponent

@export var look_at_offset: Vector3 = Vector3.ZERO

func stage() -> CameramanCore.Stage:
	return CameramanCore.Stage.AIM

func mutate_camera_state(state: CameramanCameraState, _delta: float) -> void:
	if not state.has_look_at():
		return
	var target: Vector3 = state.reference_look_at + look_at_offset
	var direction: Vector3 = target - state.raw_position
	if direction.length_squared() < 0.000001:
		return
	state.raw_orientation = Basis.looking_at(direction.normalized(), state.reference_up, false).get_rotation_quaternion()
