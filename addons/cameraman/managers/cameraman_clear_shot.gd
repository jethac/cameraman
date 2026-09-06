class_name CameramanClearShot
extends CameramanCameraManagerBase

@export var activate_after: float = 0.0
@export var min_duration: float = 0.0
@export var randomize_choice: bool = false

var _candidate: CameramanVirtualCameraBase
var _candidate_time: float = 0.0
var _selected_time: float = 0.0

func choose_current_camera(_world_up: Vector3, delta: float) -> CameramanVirtualCameraBase:
	var children: Array[CameramanVirtualCameraBase] = get_child_cameras()
	if children.is_empty():
		return null
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
		_selected_time += maxf(delta, 0.0)
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
