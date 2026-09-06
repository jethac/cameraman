class_name CameramanBlendManager
extends RefCounted

var active_blend: CameramanBlend
var active_source: Object
var _owner: Node

func update_root_frame(
	desired: Object,
	world_up: Vector3,
	delta: float,
	default_definition: CameramanBlendDefinition,
	owner: CameramanBrain
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
		return true
	active_blend = CameramanBlend.new(from_source, desired, definition)
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

func update(world_up: Vector3, delta: float) -> CameramanCameraState:
	if active_blend != null:
		active_blend.update_state(world_up, delta)
		var result: CameramanCameraState = active_blend.get_state()
		if active_blend.is_complete():
			CameramanCore.get_events().blend_finished.emit(_owner, active_blend.cam_b)
			active_source = active_blend.cam_b
			active_blend = null
		return result
	_update_source(world_up, delta)
	return active_source.get_state()

func get_state() -> CameramanCameraState:
	if active_blend != null:
		return active_blend.get_state()
	if active_source != null:
		return active_source.get_state()
	return CameramanCameraState.create_default()

func is_live(camera: CameramanVirtualCameraBase) -> bool:
	if active_source == camera:
		return true
	return active_blend != null and active_blend.uses(camera)

func _update_source(world_up: Vector3, delta: float) -> void:
	if active_source != null:
		active_source.update_state(world_up, delta)
