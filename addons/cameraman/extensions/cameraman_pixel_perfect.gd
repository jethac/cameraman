@tool
class_name CameramanPixelPerfect
## Provides the pixel perfect camera pipeline extension.
## Key properties include `enabled`, which configure its behavior.
extends CameramanExtension

## Enables or disables enabled.
@export var enabled: bool = true

## Applies extension behavior after the specified pipeline stage.
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
		state.lens.orthographic_size * 2.0 * CameramanCameraState.aspect_ratio / maxf(size.x, 1.0),
		state.lens.orthographic_size * 2.0 / maxf(size.y, 1.0)
	)
	var final_position: Vector3 = state.get_final_position()
	var rounded: Vector3 = final_position
	rounded.x = snappedf(final_position.x, pixel_size.x)
	rounded.y = snappedf(final_position.y, pixel_size.y)
	state.raw_position = rounded - state.position_correction
