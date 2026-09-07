@tool
class_name CameramanGroupFraming
## FINALIZE-stage extension that fits a target group by zooming or moving laterally.
extends CameramanExtension

enum FramingMode { HORIZONTAL, VERTICAL, HORIZONTAL_AND_VERTICAL }
enum SizeAdjustment { ZOOM_ONLY, DOLLY_ONLY, DOLLY_THEN_ZOOM }
enum LateralAdjustment { CHANGE_POSITION, CHANGE_ROTATION }

## Selects whether horizontal, vertical, or both axes are fitted.
@export var framing_mode: FramingMode = FramingMode.HORIZONTAL_AND_VERTICAL
## Desired normalized margin around the framed target group.
@export var framing_size: float = 1.0
## Normalized viewport offset applied to the group center.
@export var center_offset: Vector2 = Vector2.ZERO
## Seconds used to smooth framing position and lens changes.
@export var damping: float = 0.0
## Selects zoom-only or position-and-zoom fitting.
@export var size_adjustment: SizeAdjustment = SizeAdjustment.ZOOM_ONLY
## Selects whether lateral framing changes position or lens.
@export var lateral_adjustment: LateralAdjustment = LateralAdjustment.CHANGE_POSITION
## Minimum and maximum field of view allowed during fitting.
@export var fov_range: Vector2 = Vector2(1.0, 179.0)
## Minimum and maximum camera distance allowed during fitting.
@export var dolly_range: Vector2 = Vector2(0.0, 100.0)

func post_pipeline_stage_callback(
	camera: Node,
	stage: CameramanCore.Stage,
	state: CameramanCameraState,
	delta: float
) -> void:
	if stage != CameramanCore.Stage.BODY:
		return
	var target: CameramanTargetGroup = camera.call("get_look_at") as CameramanTargetGroup
	if target == null or target.is_empty():
		return
	var observer: Transform3D = Transform3D(
		Basis(state.raw_orientation),
		state.raw_position
	).affine_inverse()
	var bounds: AABB = target.get_view_space_bounding_box(observer)
	var center: Vector3 = bounds.get_center()
	if bounds.size.length_squared() <= 0.000001 and center.length_squared() <= 0.000001:
		return
	var depth: float = maxf(-center.z, 0.001)
	var extent: Vector2 = Vector2(bounds.size.x, bounds.size.y) * 0.5
	var required_fov: float = _required_fov(extent, depth, state.lens.fov_degrees)
	var weight: float = _weight(delta)
	if size_adjustment == SizeAdjustment.DOLLY_ONLY or size_adjustment == SizeAdjustment.DOLLY_THEN_ZOOM:
		var desired_distance: float = _required_distance(extent, state.lens.fov_degrees, depth)
		var dolly_delta: float = clampf(desired_distance - depth, -dolly_range.y, -dolly_range.x)
		if size_adjustment == SizeAdjustment.DOLLY_ONLY:
			state.raw_position += state.raw_orientation * Vector3.FORWARD * dolly_delta * weight
		else:
			var dolly_weight: float = weight
			state.raw_position += state.raw_orientation * Vector3.FORWARD * dolly_delta * dolly_weight
			var remaining_depth: float = maxf(depth + dolly_delta, 0.001)
			required_fov = _required_fov(extent, remaining_depth, state.lens.fov_degrees)
	if size_adjustment != SizeAdjustment.DOLLY_ONLY:
		state.lens.fov_degrees = lerpf(
			state.lens.fov_degrees,
			clampf(required_fov, fov_range.x, fov_range.y),
			weight
		)
	_apply_lateral_adjustment(state, center, depth, weight)

func _required_fov(extent: Vector2, depth: float, _current_fov: float) -> float:
	var vertical: float = 2.0 * atan(extent.y / maxf(depth * framing_size, 0.001))
	var horizontal: float = 2.0 * atan(
		extent.x / maxf(depth * framing_size * CameramanCameraState.aspect_ratio, 0.001)
	)
	match framing_mode:
		FramingMode.HORIZONTAL:
			return rad_to_deg(horizontal)
		FramingMode.VERTICAL:
			return rad_to_deg(vertical)
		_:
			return rad_to_deg(maxf(vertical, horizontal / CameramanCameraState.aspect_ratio))

func _required_distance(extent: Vector2, fov_degrees: float, _current_depth: float) -> float:
	var vertical_distance: float = extent.y / maxf(tan(deg_to_rad(fov_degrees) * 0.5), 0.001)
	var horizontal_fov: float = deg_to_rad(fov_degrees) * CameramanCameraState.aspect_ratio
	var horizontal_distance: float = extent.x / maxf(tan(horizontal_fov * 0.5), 0.001)
	var distance: float
	match framing_mode:
		FramingMode.HORIZONTAL:
			distance = horizontal_distance
		FramingMode.VERTICAL:
			distance = vertical_distance
		_:
			distance = maxf(vertical_distance, horizontal_distance)
	return maxf(distance / maxf(framing_size, 0.001), 0.001)

func _apply_lateral_adjustment(
	state: CameramanCameraState,
	center: Vector3,
	depth: float,
	weight: float
) -> void:
	var target_x: float = (
		center_offset.x
		* depth
		* tan(deg_to_rad(state.lens.fov_degrees) * 0.5)
		* CameramanCameraState.aspect_ratio
	)
	var target_y: float = center_offset.y * depth * tan(deg_to_rad(state.lens.fov_degrees) * 0.5)
	var local_offset: Vector3 = Vector3(target_x - center.x, target_y - center.y, 0.0)
	if lateral_adjustment == LateralAdjustment.CHANGE_POSITION:
		state.raw_position += state.raw_orientation * local_offset * weight
		return
	var desired_local_direction: Vector3 = (center + Vector3(target_x, target_y, 0.0)).normalized()
	var desired_direction: Vector3 = state.raw_orientation * desired_local_direction
	if desired_direction.length_squared() > 0.000001:
		var desired: Quaternion = Basis.looking_at(desired_direction, Vector3.UP).get_rotation_quaternion()
		state.raw_orientation = state.raw_orientation.slerp(desired, weight).normalized()

func _weight(delta: float) -> float:
	return 1.0 if damping <= 0.0 else CameramanDamper.damp(1.0, damping, delta)
