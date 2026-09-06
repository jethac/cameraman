@tool
class_name CameramanHardLockToTarget
## Provides the hard lock to target camera pipeline component.
## Key properties include `damping`, which configure its behavior.
extends CameramanComponent

## Controls the damping applied to damping.
@export var damping: float = 0.0

## Returns the pipeline stage handled by this type.
func stage() -> CameramanCore.Stage:
	return CameramanCore.Stage.BODY

## Applies this component's camera-state mutation for the current pipeline step.
func mutate_camera_state(state: CameramanCameraState, _delta: float) -> void:
	if follow_target != null:
		state.raw_position = follow_target.global_position
