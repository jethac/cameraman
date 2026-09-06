@tool
class_name CameramanExtension
extends Node

func pre_pipeline_mutate_camera_state(
	_camera: Node,
	_state: CameramanCameraState,
	_delta: float
) -> void:
	pass

func post_pipeline_stage_callback(
	_camera: Node,
	_stage: CameramanCore.Stage,
	_state: CameramanCameraState,
	_delta: float
) -> void:
	pass

func on_transition_from_camera(
	_camera: Node,
	_from: Object,
	_world_up: Vector3,
	_delta: float
) -> bool:
	return false

func on_camera_activated(_camera: Node, _from: Object) -> void:
	pass

func on_camera_deactivated(_camera: Node, _to: Object) -> void:
	pass

func on_target_object_warped(
	_camera: Node,
	_target: Node3D,
	_delta: Vector3
) -> void:
	pass

func force_camera_position(
	_camera: Node,
	_position: Vector3,
	_rotation: Quaternion
) -> void:
	pass

func get_max_damp_time() -> float:
	return 0.0

func get_extra_state(_camera: Node) -> Dictionary:
	return {}
