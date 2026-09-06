class_name CameramanRecomposer
extends CameramanExtension

@export var tilt: float = 0.0
@export var pan: float = 0.0
@export var dutch: float = 0.0
@export var zoom_scale: float = 1.0
@export_range(0.0, 1.0) var follow_attachment: float = 1.0
@export_range(0.0, 1.0) var look_at_attachment: float = 1.0

func post_pipeline_stage_callback(
	_camera: Node,
	stage: CameramanCore.Stage,
	state: CameramanCameraState,
	_delta: float
) -> void:
	if stage != CameramanCore.Stage.FINALIZE:
		return
	var rotation: Quaternion = Quaternion.from_euler(Vector3(deg_to_rad(tilt), deg_to_rad(pan), 0.0))
	state.raw_orientation = (state.raw_orientation * rotation).normalized()
	state.orientation_correction = (
		state.orientation_correction * Quaternion(Vector3.FORWARD, deg_to_rad(dutch))
	).normalized()
	if zoom_scale > 0.0:
		state.lens.fov_degrees = rad_to_deg(2.0 * atan(tan(deg_to_rad(state.lens.fov_degrees) * 0.5) / zoom_scale))
