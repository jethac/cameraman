@tool
class_name CameramanRegistry
## Tracks registered virtual cameras and caches priority ordering for selection.
extends RefCounted

var _cameras: Array[Node3D] = []
var _activation_sequence: Dictionary = {}
var _sequence: int = 0
var _updated_frame: Dictionary = {}
var _last_updated_frame: Dictionary = {}
var _sorted: Array[Node3D] = []
var _sorted_keys: PackedInt64Array = PackedInt64Array()
var _sorted_dirty: bool = true

func add(camera: Node3D) -> void:
	if not _cameras.has(camera):
		_cameras.append(camera)
	_sequence += 1
	_activation_sequence[camera] = _sequence
	_sorted_dirty = true

func remove(camera: Node3D) -> void:
	_cameras.erase(camera)
	_activation_sequence.erase(camera)
	_updated_frame.erase(camera)
	_last_updated_frame.erase(camera)
	_sorted_dirty = true

func mark_activated(camera: Node3D) -> void:
	_sequence += 1
	_activation_sequence[camera] = _sequence
	_sorted_dirty = true

## Cameras ordered by effective priority (desc), then most recently activated.
## The order is cached and only re-sorted when a priority or activation changes,
## so per-frame callers pay O(n) priority reads instead of an O(n log n) sort.
## Returns cached cameras ordered by effective priority, then activation recency.
func get_cameras() -> Array[Node3D]:
	var count: int = _cameras.size()
	var keys: PackedInt64Array = PackedInt64Array()
	keys.resize(count)
	for index in count:
		keys[index] = int(_cameras[index].call("get_effective_priority"))
	if _sorted_dirty or keys != _sorted_keys:
		_sorted_keys = keys
		var entries: Array = []
		entries.resize(count)
		for index in count:
			var camera: Node3D = _cameras[index]
			entries[index] = [keys[index], int(_activation_sequence.get(camera, 0)), camera]
		entries.sort_custom(_sort_entries)
		_sorted.clear()
		for entry in entries:
			_sorted.append(entry[2] as Node3D)
		_sorted_dirty = false
	return _sorted.duplicate()

## Returns the highest-priority enabled camera matching channel_mask and brain.
func get_top_camera(channel_mask: int, brain: Node) -> Node3D:
	for camera in get_cameras():
		if not camera.call("is_enabled") or (int(camera.get("output_channel")) & channel_mask) == 0:
			continue
		var parent_mixer: Node = camera.call("get_parent_mixer") as Node
		if parent_mixer != null and parent_mixer != brain:
			continue
		return camera
	return null

## Updates one standby camera and records whether its state changed.
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

static func _sort_entries(a: Array, b: Array) -> bool:
	if int(a[0]) != int(b[0]):
		return int(a[0]) > int(b[0])
	return int(a[1]) > int(b[1])
