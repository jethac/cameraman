class_name CameramanPixelPerfect
extends CameramanExtension

@export var enabled: bool = true

func post_pipeline_stage_callback(
	camera: Node,
	stage: CameramanCore.Stage,
	state: CameramanCameraState,
	_delta: float
) -> void:
	if stage != CameramanCore.Stage.FINALIZE or not enabled:
		return
	var viewport: Viewport = camera.get_viewport()
	if viewport == null:
		return
	var size: Vector2 = viewport.get_visible_rect().size
	var pixel_size: Vector2 = Vector2(
		state.lens.orthographic_size * CameramanCameraState.aspect_ratio / maxf(size.x, 1.0),
		state.lens.orthographic_size / maxf(size.y, 1.0)
	)
	state.raw_position.x = snappedf(state.raw_position.x, pixel_size.x)
	state.raw_position.y = snappedf(state.raw_position.y, pixel_size.y)
