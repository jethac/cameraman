@tool
class_name CameramanExtension
## Defines the extension contract for post-pipeline state changes and camera lifecycle events.
extends Node

## Applies this extension before the component pipeline runs.
func pre_pipeline_mutate_camera_state(
	_camera: Node,
	_state: CameramanCameraState,
	_delta: float
) -> void:
	pass

## Applies extension behavior after the specified pipeline stage.
func post_pipeline_stage_callback(
	_camera: Node,
	_stage: CameramanCore.Stage,
	_state: CameramanCameraState,
	_delta: float
) -> void:
	pass

## Handles the transition from camera event.
func on_transition_from_camera(
	_camera: Node,
	_from: Object,
	_world_up: Vector3,
	_delta: float
) -> bool:
	return false

## Handles the camera activated event.
func on_camera_activated(_camera: Node, _from: Object) -> void:
	pass

## Handles the camera deactivated event.
func on_camera_deactivated(_camera: Node, _to: Object) -> void:
	pass

## Handles the target object warped event.
func on_target_object_warped(
	_camera: Node,
	_target: Node3D,
	_delta: Vector3
) -> void:
	pass

## Forces the camera and its pipeline state to a position and rotation.
func force_camera_position(
	_camera: Node,
	_position: Vector3,
	_rotation: Quaternion
) -> void:
	pass

## Returns the longest damping time configured by this type.
func get_max_damp_time() -> float:
	return 0.0

## Returns the extra state.
func get_extra_state(_camera: Node) -> Dictionary:
	return {}
