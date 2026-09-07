@tool
class_name CameramanClearShot
## Camera manager that selects the highest-quality eligible child after optional hold times.
extends CameramanCameraManagerBase

## Seconds a candidate must remain best before activation.
@export var activate_after: float = 0.0
## Minimum seconds the selected child remains active before another switch.
@export var min_duration: float = 0.0
## Randomizes equal-quality choices instead of retaining the first one.
@export var randomize_choice: bool = false

var _candidate: CameramanVirtualCameraBase
var _candidate_time: float = 0.0
var _selected_time: float = 0.0

## Chooses the eligible child with the highest shot-quality score after hold rules.
func choose_current_camera(_world_up: Vector3, delta: float) -> CameramanVirtualCameraBase:
	var children: Array[CameramanVirtualCameraBase] = get_child_cameras()
	if children.is_empty():
		return null
	if live_child != null:
		_selected_time += maxf(delta, 0.0)
	var best: CameramanVirtualCameraBase = children[0]
	for camera in children:
		if camera.get_state().shot_quality > best.get_state().shot_quality:
			best = camera
		elif (
			is_equal_approx(camera.get_state().shot_quality, best.get_state().shot_quality)
			and camera.get_effective_priority() > best.get_effective_priority()
		):
			best = camera
	if randomize_choice and best != _candidate and children.size() > 1:
		var index: int = randi_range(0, children.size() - 1)
		best = children[index]
	if best == live_child:
		_candidate = best
		_candidate_time = 0.0
		return best
	if best != _candidate:
		_candidate = best
		_candidate_time = 0.0
	else:
		_candidate_time += maxf(delta, 0.0)
	if live_child == null or (
		_candidate_time >= activate_after and _selected_time >= min_duration
	):
		_selected_time = 0.0
		return best
	return live_child
