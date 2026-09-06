@tool
class_name CameramanBlender
extends RefCounted

func blend(
	state_a: CameramanCameraState,
	state_b: CameramanCameraState,
	weight: float
) -> CameramanCameraState:
	return CameramanCameraState.lerp(state_a, state_b, weight)
