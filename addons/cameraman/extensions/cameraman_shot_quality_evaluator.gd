@tool
class_name CameramanShotQualityEvaluator
## FINALIZE-stage extension that evaluates target visibility and preferred camera distance.
extends CameramanExtension

## Minimum and maximum target distance that receive full quality.
@export var optimal_distance: Vector2 = Vector2(1.0, 20.0)
## Current visibility result written by the evaluator after each stage.
@export var target_visible: bool = true

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
