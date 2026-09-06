@tool
class_name CameramanBlendManager
## Provides the blend manager runtime helper.
extends RefCounted

var active_blend: CameramanBlend
var active_source: Object
var _owner: Node
var _blend_outgoing_event_source: Object

## Updates the root frame.
func update_root_frame(
	desired: Object,
	world_up: Vector3,
	delta: float,
	default_definition: CameramanBlendDefinition,
	owner: Node
) -> bool:
	if desired == null:
		return false
	if active_source == desired and active_blend == null:
		return false
	if active_blend != null and active_blend.cam_b == desired:
		return false
	_owner = owner
	var from_source: Object = active_source
	if active_blend != null and not active_blend.is_complete():
		from_source = CameramanNestedBlendSource.new(active_blend)
	var outgoing_event_source: Object = from_source
	from_source = _freeze_if_needed(from_source)
	_call_transition(desired, from_source, world_up, delta)
	var definition: CameramanBlendDefinition = default_definition
	if from_source != null:
		definition = owner.get_blend_definition(from_source, desired, default_definition)
	if from_source == null or definition.blend_time() <= 0.0:
		active_source = desired
		active_blend = null
		var cut_event: CameramanActivationEvent = CameramanActivationEvent.new(
			owner, from_source, desired, true, world_up, delta
		)
		desired.on_camera_activated(cut_event)
		CameramanCore.get_events().emit_activation(cut_event)
		if from_source != null:
			CameramanCore.get_events().camera_deactivated.emit(owner, outgoing_event_source)
			var deactivation_event: CameramanActivationEvent = CameramanActivationEvent.new(
				owner, from_source, desired, true, world_up, delta
			)
			if from_source.has_method("on_camera_deactivated"):
				from_source.on_camera_deactivated(deactivation_event)
		return true
	active_blend = CameramanBlend.new(from_source, desired, definition)
	_blend_outgoing_event_source = outgoing_event_source
	if CameramanCore.get_custom_blender.is_valid():
		var blender_value: Object = CameramanCore.get_custom_blender.call(from_source, desired) as Object
		if blender_value is CameramanBlender:
			active_blend.custom_blender = blender_value as CameramanBlender
	active_source = desired
	var blend_event: CameramanBlendEvent = CameramanBlendEvent.new(owner, active_blend)
	CameramanCore.get_events().emit_blend(blend_event)
	var activation_event: CameramanActivationEvent = CameramanActivationEvent.new(
		owner, from_source, desired, false, world_up, delta
	)
	desired.on_camera_activated(activation_event)
	CameramanCore.get_events().emit_activation(activation_event)
	return true

## Updates the current runtime state.
func update(
	world_up: Vector3,
	delta: float,
	update_callback: Callable = Callable()
) -> CameramanCameraState:
	if active_blend != null:
		active_blend.update_state(world_up, delta, update_callback)
		var result: CameramanCameraState = active_blend.get_state()
		if active_blend.is_complete():
			var outgoing: Object = _blend_outgoing_event_source
			CameramanCore.get_events().blend_finished.emit(_owner, active_blend.cam_b)
			CameramanCore.get_events().camera_deactivated.emit(_owner, outgoing)
			var deactivation_event: CameramanActivationEvent = CameramanActivationEvent.new(
				_owner, outgoing, active_blend.cam_b, false, world_up, delta
			)
			if outgoing.has_method("on_camera_deactivated"):
				outgoing.on_camera_deactivated(deactivation_event)
			active_source = active_blend.cam_b
			active_blend = null
			_blend_outgoing_event_source = null
		return result
	_update_source(world_up, delta, update_callback)
	return active_source.get_state()

## Returns the latest evaluated camera state.
func get_state() -> CameramanCameraState:
	if active_blend != null:
		return active_blend.get_state()
	if active_source != null:
		return active_source.get_state()
	return CameramanCameraState.create_default()

## Returns whether this camera source is live.
func is_live(camera: CameramanVirtualCameraBase) -> bool:
	if active_source == camera:
		return true
	if active_source is CameramanNestedBlendSource and active_source.blend.uses(camera):
		return true
	return active_blend != null and active_blend.uses(camera)

func _update_source(world_up: Vector3, delta: float, update_callback: Callable) -> void:
	if active_source != null:
		if active_source is CameramanNestedBlendSource:
			active_source.update_state(world_up, delta, update_callback)
		elif update_callback.is_valid() and active_source is Node3D:
			update_callback.call(active_source, world_up, delta)
		else:
			active_source.update_state(world_up, delta)

func _call_transition(
	desired: Object,
	from_source: Object,
	world_up: Vector3,
	delta: float
) -> void:
	if desired.has_method("on_transition_from_camera"):
		desired.on_transition_from_camera(from_source, world_up, delta)

func _freeze_if_needed(source: Object) -> Object:
	if source == null or not source.has_method("get_state"):
		return source
	var state: CameramanCameraState = source.get_state()
	if (state.blend_hint & CameramanCore.BlendHint.FREEZE_WHEN_BLENDING_OUT) != 0:
		return CameramanFrozenSource.new(source)
	return source
