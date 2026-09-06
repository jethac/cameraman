class_name CameramanNestedBlendSource
extends CameramanShotSource

var blend: CameramanBlend

func _init(value: CameramanBlend) -> void:
	blend = value

func get_camera_name() -> String:
	return blend.description()

func get_description() -> String:
	return get_camera_name()

func get_state() -> CameramanCameraState:
	return blend.get_state()

func is_valid() -> bool:
	return blend != null and blend.is_valid()

func get_parent_mixer() -> Node:
	return null

func update_state(world_up: Vector3, delta: float) -> void:
	blend.update_state(world_up, delta)

func on_camera_activated(event: CameramanActivationEvent) -> void:
	if blend.cam_b != null:
		blend.cam_b.on_camera_activated(event)
