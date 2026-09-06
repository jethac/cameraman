@tool
class_name CameramanFrozenSource
## Provides the frozen source Cameraman type.
extends CameramanShotSource

var source_name: String
var source_description: String
var state: CameramanCameraState

func _init(source: Object) -> void:
	source_name = source.get_camera_name()
	source_description = source.get_description()
	state = source.get_state()

## Returns the camera name used in descriptions and blend lookup.
func get_camera_name() -> String:
	return source_name

## Returns a human-readable description of this camera source.
func get_description() -> String:
	return source_description

## Returns the latest evaluated camera state.
func get_state() -> CameramanCameraState:
	return state

## Returns whether this object is valid for evaluation.
func is_valid() -> bool:
	return true

## Updates the state.
func update_state(_world_up: Vector3, _delta: float) -> void:
	pass
