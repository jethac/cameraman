@tool
class_name CameramanBlender
## Provides the blender runtime helper.
extends RefCounted

## Blends the supplied camera states.
func blend(
	state_a: CameramanCameraState,
	state_b: CameramanCameraState,
	weight: float
) -> CameramanCameraState:
	return CameramanCameraState.lerp(state_a, state_b, weight)
