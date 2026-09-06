class_name CameramanFrozenSource
extends CameramanShotSource

var source_name: String
var source_description: String
var state: CameramanCameraState

func _init(source: Object) -> void:
	source_name = source.get_camera_name()
	source_description = source.get_description()
	state = source.get_state()

func get_camera_name() -> String:
	return source_name

func get_description() -> String:
	return source_description

func get_state() -> CameramanCameraState:
	return state

func is_valid() -> bool:
	return true

func update_state(_world_up: Vector3, _delta: float) -> void:
	pass
