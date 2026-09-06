class_name CameramanRotateWithFollowTarget
extends CameramanComponent

@export var damping: float = 0.0

func stage() -> CameramanCore.Stage:
	return CameramanCore.Stage.AIM

func mutate_camera_state(state: CameramanCameraState, delta: float) -> void:
	if follow_target == null:
		return
	var target_rotation: Quaternion = follow_target.global_basis.get_rotation_quaternion()
	if not vcam.previous_state_is_valid:
		state.raw_orientation = target_rotation
		return
	state.raw_orientation = state.raw_orientation.slerp(
		target_rotation,
		CameramanDamper.damp(1.0, damping, delta)
	)

func on_transition_from_camera(from: Object, _world_up: Vector3, _delta: float) -> bool:
	if from == null or not from.has_method("get_state"):
		return false
	var previous: CameramanCameraState = from.get_state()
	force_camera_position(previous.get_final_position(), previous.get_final_orientation())
	return true

func force_camera_position(_position: Vector3, rotation: Quaternion) -> void:
	if vcam != null:
		vcam.call("set_meta", "cameraman_rotate_follow_rotation", rotation)
