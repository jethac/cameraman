class_name CameramanShotSource
extends RefCounted

func get_camera_name() -> String:
	push_error("Shot source must implement get_camera_name")
	return ""

func get_description() -> String:
	push_error("Shot source must implement get_description")
	return get_camera_name()

func get_state() -> CameramanCameraState:
	push_error("Shot source must implement get_state")
	return CameramanCameraState.create_default()

func is_valid() -> bool:
	push_error("Shot source must implement is_valid")
	return false

func get_parent_mixer() -> Node:
	return null

func update_state(_world_up: Vector3, _delta: float) -> void:
	push_error("Shot source must implement update_state")

func on_camera_activated(_event: CameramanActivationEvent) -> void:
	pass

func on_camera_deactivated(_event: CameramanActivationEvent) -> void:
	pass
