class_name CameramanHardLockToTarget
extends CameramanComponent

@export var damping: float = 0.0

func stage() -> CameramanCore.Stage:
	return CameramanCore.Stage.BODY

func mutate_camera_state(state: CameramanCameraState, _delta: float) -> void:
	if follow_target != null:
		state.raw_position = follow_target.global_position
