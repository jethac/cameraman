@tool
class_name CameramanRecomposer
## Provides the recomposer camera pipeline extension.
## Key properties include `tilt`, `pan`, `dutch`, and related settings, which configure its behavior.
extends CameramanExtension

## Configures the tilt used by this type.
@export var tilt: float = 0.0
## Configures the pan used by this type.
@export var pan: float = 0.0
## Configures the dutch used by this type.
@export var dutch: float = 0.0
## Configures the zoom scale used by this type.
@export var zoom_scale: float = 1.0
## Configures the follow attachment used by this type.
@export_range(0.0, 1.0) var follow_attachment: float = 1.0
## Configures the look at attachment used by this type.
@export_range(0.0, 1.0) var look_at_attachment: float = 1.0

var _pre_body_position: Vector3 = Vector3.ZERO
var _pre_aim_orientation: Quaternion = Quaternion.IDENTITY
var _aim_snapshot_captured: bool = false

## Applies this extension before the component pipeline runs.
func pre_pipeline_mutate_camera_state(
	_camera: Node,
	state: CameramanCameraState,
	_delta: float
) -> void:
	_pre_body_position = state.raw_position
	_pre_aim_orientation = state.raw_orientation
	_aim_snapshot_captured = false

## Applies extension behavior after the specified pipeline stage.
func post_pipeline_stage_callback(
	_camera: Node,
	stage: CameramanCore.Stage,
	state: CameramanCameraState,
	_delta: float
) -> void:
	if stage != CameramanCore.Stage.FINALIZE:
		if stage == CameramanCore.Stage.BODY and not _aim_snapshot_captured:
			_pre_aim_orientation = state.raw_orientation
			_aim_snapshot_captured = true
		return
	state.raw_position = _pre_body_position.lerp(state.raw_position, clampf(follow_attachment, 0.0, 1.0))
	var aim_delta: Quaternion = (_pre_aim_orientation.inverse() * state.raw_orientation).normalized()
	state.raw_orientation = (
		_pre_aim_orientation
		* Quaternion.IDENTITY.slerp(aim_delta, clampf(look_at_attachment, 0.0, 1.0))
	).normalized()
	var rotation: Quaternion = Quaternion.from_euler(Vector3(deg_to_rad(tilt), deg_to_rad(pan), 0.0))
	state.raw_orientation = (state.raw_orientation * rotation).normalized()
	state.orientation_correction = (
		state.orientation_correction * Quaternion(Vector3.FORWARD, deg_to_rad(dutch))
	).normalized()
	if zoom_scale > 0.0:
		state.lens.fov_degrees = rad_to_deg(2.0 * atan(tan(deg_to_rad(state.lens.fov_degrees) * 0.5) / zoom_scale))
