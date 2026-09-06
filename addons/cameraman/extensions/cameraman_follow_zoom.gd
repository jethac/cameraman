@tool
class_name CameramanFollowZoom
## Provides the follow zoom camera pipeline extension.
## Key properties include `width`, `damping`, `min_fov`, and related settings, which configure its behavior.
extends CameramanExtension

## Configures the width used by this type.
@export var width: float = 1.0
## Controls the damping applied to damping.
@export var damping: float = 0.0
## Configures the min fov used by this type.
@export var min_fov: float = 1.0
## Configures the max fov used by this type.
@export var max_fov: float = 179.0

## Applies extension behavior after the specified pipeline stage.
func post_pipeline_stage_callback(
	_camera: Node,
	stage: CameramanCore.Stage,
	state: CameramanCameraState,
	delta: float
) -> void:
	if stage != CameramanCore.Stage.BODY:
		return
	var target_distance: float = (
		state.raw_position.distance_to(state.reference_look_at)
		if state.has_look_at()
		else state.lens.focus_distance
	)
	var desired_fov: float = rad_to_deg(2.0 * atan(width / maxf(2.0 * target_distance, 0.001)))
	var weight: float = 1.0 if damping <= 0.0 else CameramanDamper.damp(1.0, damping, delta)
	state.lens.fov_degrees = lerpf(state.lens.fov_degrees, clampf(desired_fov, min_fov, max_fov), weight)
