@tool
class_name CameramanShotSequence
## Scene node that drives timed shot weights and a brain override.
extends Node

## NodePath to the CameramanBrain receiving the sequence override.
@export var brain_path: NodePath
## Override priority used when multiple shot sequences target one brain.
@export var priority: int = 100

var _override_handle: int = -1
var _manual_time: float = 0.0

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_update_sequence(delta)

## Advances shot weights by delta and updates the brain override without scene time.
func manual_time_step(delta: float) -> void:
	_manual_time += delta
	for player in _find_animation_players():
		player.seek(_manual_time, true)
	_update_sequence(delta)

func _update_sequence(delta: float) -> void:
	var brain: CameramanBrain = get_node_or_null(brain_path) as CameramanBrain
	if brain == null:
		brain = _find_brain_parent()
	if brain == null:
		return
	var shots: Array[CameramanShot] = []
	for child in get_children():
		var shot: CameramanShot = child as CameramanShot
		if shot != null and shot.active and shot.weight > 0.0:
			shots.append(shot)
	shots.sort_custom(func(a: CameramanShot, b: CameramanShot) -> bool:
		return a.weight > b.weight
	)
	if shots.is_empty():
		if _override_handle >= 0:
			brain.release_camera_override(_override_handle)
			_override_handle = -1
		return
	var first: CameramanShot = shots[0]
	var camera_a: Object = _resolve_camera(first.camera, brain)
	var camera_b: Object = null
	var weight_b: float = 1.0
	if shots.size() > 1:
		camera_b = _resolve_camera(shots[1].camera, brain)
		var total: float = maxf(first.weight + shots[1].weight, 0.0001)
		weight_b = shots[1].weight / total
	_override_handle = brain.set_camera_override(
		_override_handle,
		priority,
		camera_a,
		camera_b,
		weight_b,
		delta
	)

func _resolve_camera(path: NodePath, brain: CameramanBrain) -> Object:
	var camera: Object = get_node_or_null(path)
	if camera == null:
		camera = brain.get_node_or_null(path)
	return camera

func _find_brain_parent() -> CameramanBrain:
	var current: Node = get_parent()
	while current != null:
		var brain: CameramanBrain = current as CameramanBrain
		if brain != null:
			return brain
		current = current.get_parent()
	return null

func _find_animation_players() -> Array[AnimationPlayer]:
	var result: Array[AnimationPlayer] = []
	for node in find_children("*", "AnimationPlayer", true, false):
		var player: AnimationPlayer = node as AnimationPlayer
		if player != null:
			result.append(player)
	return result
