@tool
class_name CameramanHardLockToTarget
## BODY-stage component that places the camera at a target-relative offset without smoothing.
extends CameramanComponent

## Unused by the hard lock; the component intentionally writes the target offset immediately.
@export var damping: float = 0.0

func stage() -> CameramanCore.Stage:
	return CameramanCore.Stage.BODY

func mutate_camera_state(state: CameramanCameraState, _delta: float) -> void:
	if follow_target != null:
		state.raw_position = follow_target.global_position
