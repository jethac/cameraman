@tool
class_name CameramanUpdateTracker
## Provides the update tracker runtime helper.
extends RefCounted

var _records: Dictionary = {}

## Records the target's latest process transform.
func record_process(target: Node3D) -> void:
	if target == null:
		return
	var record: Dictionary = _get_record(target)
	var transform: Transform3D = target.global_transform
	record["process_changed"] = transform != record["process_transform"]
	record["process_transform"] = transform
	_records[target] = record

## Records the target's latest physics transform.
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

## Returns whether the target is driven by physics updates.
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
