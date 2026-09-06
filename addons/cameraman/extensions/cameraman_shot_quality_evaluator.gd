@tool
class_name CameramanShotQualityEvaluator
## Provides the shot quality evaluator camera pipeline extension.
## Key properties include `optimal_distance`, `target_visible`, which configure its behavior.
extends CameramanExtension

## Sets the optimal distance used by this type.
@export var optimal_distance: Vector2 = Vector2(1.0, 20.0)
## Specifies the target used by target visible.
@export var target_visible: bool = true

## Applies extension behavior after the specified pipeline stage.
func post_pipeline_stage_callback(
	camera: Node,
	stage: CameramanCore.Stage,
	state: CameramanCameraState,
	_delta: float
) -> void:
	if stage != CameramanCore.Stage.FINALIZE:
		return
	var target: Node3D = camera.call("get_look_at") as Node3D
	var distance: float = state.raw_position.distance_to(target.global_position) if target != null else optimal_distance.x
	var distance_quality: float = 1.0 - absf(inverse_lerp(optimal_distance.x, optimal_distance.y, distance) - 0.5) * 2.0
	state.shot_quality = clampf(distance_quality if target_visible else 0.0, 0.0, 1.0)
