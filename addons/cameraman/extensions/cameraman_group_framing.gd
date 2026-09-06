class_name CameramanGroupFraming
extends CameramanExtension

enum FramingMode { HORIZONTAL, VERTICAL, HORIZONTAL_AND_VERTICAL }
enum SizeAdjustment { ZOOM_ONLY, DOLLY_ONLY, DOLLY_THEN_ZOOM }
enum LateralAdjustment { CHANGE_POSITION, CHANGE_ROTATION }

@export var framing_mode: FramingMode = FramingMode.HORIZONTAL_AND_VERTICAL
@export var framing_size: float = 1.0
@export var center_offset: Vector2 = Vector2.ZERO
@export var damping: float = 0.0
@export var size_adjustment: SizeAdjustment = SizeAdjustment.ZOOM_ONLY
@export var lateral_adjustment: LateralAdjustment = LateralAdjustment.CHANGE_POSITION
@export var fov_range: Vector2 = Vector2(1.0, 179.0)
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
	var sphere: Array[Variant] = target.get_sphere()
	var radius: float = maxf(float(sphere[1]), 0.001)
	var distance: float = maxf(state.raw_position.distance_to(sphere[0] as Vector3), 0.001)
	var desired_fov: float = rad_to_deg(2.0 * atan(radius / maxf(framing_size * distance, 0.001)))
	var weight: float = CameramanDamper.damp(1.0, damping, delta)
	if size_adjustment != SizeAdjustment.DOLLY_ONLY:
		state.lens.fov_degrees = lerpf(
			state.lens.fov_degrees,
			clampf(desired_fov, fov_range.x, fov_range.y),
			weight
		)
