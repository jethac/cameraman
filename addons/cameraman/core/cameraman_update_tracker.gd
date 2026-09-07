@tool
class_name CameramanUpdateTracker
## Records process and physics transforms to classify target update timing.
extends RefCounted

var _records: Dictionary = {}

## Records the target transform during a process update.
func record_process(target: Node3D) -> void:
	if target == null:
		return
	var record: Dictionary = _get_record(target)
	var transform: Transform3D = target.global_transform
	record["process_changed"] = transform != record["process_transform"]
	record["process_transform"] = transform
	_records[target] = record

## Records the target transform during a physics update.
func record_physics(target: Node3D) -> void:
	if target == null:
		return
	var record: Dictionary = _get_record(target)
	var transform: Transform3D = target.global_transform
	record["physics_changed"] = transform != record["physics_transform"]
	record["process_changed"] = false
	record["physics_transform"] = transform
	record["process_transform"] = transform
	_records[target] = record

## Returns true when the target changed on physics without a newer process sample.
func is_physics_driven(target: Node3D) -> bool:
	if target == null:
		return false
	var record: Dictionary = _records.get(target, {})
	return bool(record.get("physics_changed", false)) and not bool(record.get("process_changed", false))

func _get_record(target: Node3D) -> Dictionary:
	if not _records.has(target):
		var transform: Transform3D = target.global_transform
		_records[target] = {
			"process_transform": transform,
			"physics_transform": transform,
			"process_changed": false,
			"physics_changed": false
		}
	return _records[target]
