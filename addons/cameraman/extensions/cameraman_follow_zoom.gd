class_name CameramanFollowZoom
extends CameramanExtension

@export var width: float = 1.0
@export var damping: float = 0.0
@export var min_fov: float = 1.0
@export var max_fov: float = 179.0

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
