@tool
class_name CameramanBlend
## Maintains an active transition between two camera state sources.
extends RefCounted

var cam_a: Object
var cam_b: Object
var curve: Curve
var duration: float = 0.0
var time_in_blend: float = 0.0
var manual_weight: bool = false
var custom_blender: CameramanBlender = CameramanBlender.new()
var _state_a: CameramanCameraState
var _state_b: CameramanCameraState
var _state: CameramanCameraState

func _init(
	from_source: Object = null,
	to_source: Object = null,
	definition: CameramanBlendDefinition = null
) -> void:
	cam_a = from_source
	cam_b = to_source
	if definition == null:
		definition = CameramanBlendDefinition.new()
	curve = definition.get_curve()
	duration = definition.blend_time()

## Returns normalized transition progress after applying the blend curve.
func blend_weight() -> float:
	if duration <= 0.0:
		return 1.0
	return curve.sample(clampf(time_in_blend / duration, 0.0, 1.0))

## Returns true once elapsed time reaches the definition duration.
func is_complete() -> bool:
	return duration <= 0.0 or time_in_blend >= duration

func is_valid() -> bool:
	return cam_a != null and cam_b != null and cam_a.is_valid() and cam_b.is_valid()

## Returns true when either endpoint or nested source contains the supplied camera.
func uses(camera: Object) -> bool:
	return _source_uses(cam_a, camera) or _source_uses(cam_b, camera)

## Evaluates both endpoints and interpolates their states for the current frame.
func update_state(
	world_up: Vector3,
	delta: float,
	update_callback: Callable = Callable()
) -> void:
	if cam_a == null or cam_b == null:
		return
	_update_source(cam_a, world_up, delta, update_callback)
	_update_source(cam_b, world_up, delta, update_callback)
	_state_a = cam_a.get_state()
	_state_b = cam_b.get_state()
	if not manual_weight:
		time_in_blend += maxf(delta, 0.0)
	_state = custom_blender.blend(_state_a, _state_b, blend_weight())

func get_state() -> CameramanCameraState:
	if _state == null:
		if cam_a != null and cam_b != null:
			_state = custom_blender.blend(cam_a.get_state(), cam_b.get_state(), blend_weight())
		else:
			_state = CameramanCameraState.create_default()
	return _state

func description() -> String:
	return "%s -> %s (%.0f%%)" % [
		_source_description(cam_a),
		_source_description(cam_b),
		blend_weight() * 100.0
	]

func _source_description(source: Object) -> String:
	return source.get_description() if source != null else "<none>"

func _is_frozen(source: Object) -> bool:
	return source is CameramanFrozenSource

func _update_source(
	source: Object,
	world_up: Vector3,
	delta: float,
	update_callback: Callable
) -> void:
	if _is_frozen(source):
		return
	if source is CameramanNestedBlendSource:
		source.update_state(world_up, delta, update_callback)
	elif update_callback.is_valid() and source is Node3D:
		update_callback.call(source, world_up, delta)
	else:
		source.update_state(world_up, delta)

func _source_uses(source: Object, camera: Object) -> bool:
	if source == camera:
		return true
	if source is CameramanNestedBlendSource:
		return source.blend.uses(camera)
	return false
