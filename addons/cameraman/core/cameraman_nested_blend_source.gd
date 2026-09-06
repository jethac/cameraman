@tool
class_name CameramanNestedBlendSource
## Provides the nested blend source Cameraman type.
extends CameramanShotSource

var blend: CameramanBlend

func _init(value: CameramanBlend) -> void:
	blend = value

## Returns the camera name used in descriptions and blend lookup.
func get_camera_name() -> String:
	return blend.description()

## Returns a human-readable description of this camera source.
func get_description() -> String:
	return get_camera_name()

## Returns the latest evaluated camera state.
func get_state() -> CameramanCameraState:
	return blend.get_state()

## Returns whether this object is valid for evaluation.
func is_valid() -> bool:
	return blend != null and blend.is_valid()

## Returns the parent mixer.
func get_parent_mixer() -> Node:
	return null

## Updates the state.
func update_state(
	world_up: Vector3,
	delta: float,
	update_callback: Callable = Callable()
) -> void:
	blend.update_state(world_up, delta, update_callback)

## Handles the transition from camera event.
func on_transition_from_camera(
	from: Object,
	world_up: Vector3,
	delta: float
) -> void:
	if blend.cam_b != null and blend.cam_b.has_method("on_transition_from_camera"):
		blend.cam_b.on_transition_from_camera(from, world_up, delta)

## Handles the camera activated event.
func on_camera_activated(event: CameramanActivationEvent) -> void:
	if blend.cam_b != null:
		blend.cam_b.on_camera_activated(event)

## Handles the camera deactivated event.
func on_camera_deactivated(event: CameramanActivationEvent) -> void:
	if blend.cam_a != null:
		blend.cam_a.on_camera_deactivated(event)
	if blend.cam_b != null:
		blend.cam_b.on_camera_deactivated(event)
