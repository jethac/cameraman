class_name CameramanRegistry
extends RefCounted

var _cameras: Array[Node3D] = []
var _activation_sequence: Dictionary = {}
var _sequence: int = 0
var _updated_frame: Dictionary = {}
var _last_updated_frame: Dictionary = {}

func add(camera: Node3D) -> void:
	if not _cameras.has(camera):
		_cameras.append(camera)
	_sequence += 1
	_activation_sequence[camera] = _sequence

func remove(camera: Node3D) -> void:
	_cameras.erase(camera)
	_activation_sequence.erase(camera)
	_updated_frame.erase(camera)
	_last_updated_frame.erase(camera)

func mark_activated(camera: Node3D) -> void:
	_sequence += 1
	_activation_sequence[camera] = _sequence

func get_cameras() -> Array[Node3D]:
	var result: Array[Node3D] = _cameras.duplicate()
	result.sort_custom(_sort_cameras)
	return result

func get_top_camera(channel_mask: int, brain: Node) -> Node3D:
	for camera in get_cameras():
		if not camera.call("is_enabled") or (int(camera.get("output_channel")) & channel_mask) == 0:
			continue
		var parent_mixer: Node = camera.call("get_parent_mixer") as Node
		if parent_mixer != null and parent_mixer != brain:
			continue
		return camera
	return null

func update_camera(
	camera: Node3D,
	world_up: Vector3,
	delta: float,
	frame: int
) -> void:
	if _updated_frame.get(camera, -1) == frame:
		return
	_updated_frame[camera] = frame
	var last_frame: int = int(_last_updated_frame.get(camera, frame))
	var update_delta: float = -1.0 if frame - last_frame > 1 else delta
	_last_updated_frame[camera] = frame
	camera.call("update_state", world_up, update_delta)

func _sort_cameras(a: Node3D, b: Node3D) -> bool:
	if int(a.call("get_effective_priority")) != int(b.call("get_effective_priority")):
		return int(a.call("get_effective_priority")) > int(b.call("get_effective_priority"))
	return int(_activation_sequence.get(a, 0)) > int(_activation_sequence.get(b, 0))
