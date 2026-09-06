class_name CameramanCameraManagerBase
extends CameramanVirtualCameraBase

@export var default_blend: CameramanBlendDefinition
@export var custom_blends: CameramanBlenderSettings

var live_child: CameramanVirtualCameraBase
var _manager: CameramanBlendManager = CameramanBlendManager.new()
var _manager_state: CameramanCameraState = CameramanCameraState.create_default()

func _init() -> void:
	default_blend = CameramanBlendDefinition.new()

func is_cameraman_mixer() -> bool:
	return true

func get_child_cameras() -> Array[CameramanVirtualCameraBase]:
	var result: Array[CameramanVirtualCameraBase] = []
	for child in get_children():
		var camera: CameramanVirtualCameraBase = child as CameramanVirtualCameraBase
		if camera != null and camera.is_enabled():
			result.append(camera)
	return result

func get_description() -> String:
	return "Manager [%s]" % (
		live_child.get_description() if live_child != null else "<none>"
	)

func choose_current_camera(_world_up: Vector3, _delta: float) -> CameramanVirtualCameraBase:
	var children: Array[CameramanVirtualCameraBase] = get_child_cameras()
	children.sort_custom(func(a: CameramanVirtualCameraBase, b: CameramanVirtualCameraBase) -> bool:
		return a.get_effective_priority() > b.get_effective_priority()
	)
	return children[0] if not children.is_empty() else null

func internal_update_state(world_up: Vector3, delta: float) -> void:
	for child in get_child_cameras():
		child.update_state(world_up, delta)
	var desired: CameramanVirtualCameraBase = choose_current_camera(world_up, delta)
	if desired == null:
		_manager_state = CameramanCameraState.create_default(world_up)
		_state = _manager_state
		previous_state_is_valid = true
		return
	var changed: bool = _manager.update_root_frame(
		desired,
		world_up,
		delta,
		default_blend,
		self
	)
	if changed and desired != live_child:
		live_child = desired
	var callback: Callable = Callable(self, "_update_child")
	_manager_state = _manager.update(world_up, delta, callback)
	_state = _manager_state
	previous_state_is_valid = true

func get_state() -> CameramanCameraState:
	return _manager_state

func is_live_child(camera: CameramanVirtualCameraBase) -> bool:
	return _manager.is_live(camera)

func get_blend_definition(
	from_source: Object,
	to_source: Object,
	fallback: CameramanBlendDefinition
) -> CameramanBlendDefinition:
	if custom_blends != null:
		return custom_blends.get_blend_for(
			from_source.get_camera_name(),
			to_source.get_camera_name(),
			fallback
		)
	return fallback

func on_transition_from_camera(from: Object, world_up: Vector3, delta: float) -> void:
	if live_child != null:
		live_child.on_transition_from_camera(from, world_up, delta)
	else:
		super.on_transition_from_camera(from, world_up, delta)

func on_target_object_warped(target: Node3D, position_delta: Vector3) -> void:
	for camera in get_child_cameras():
		camera.on_target_object_warped(target, position_delta)

func force_camera_position(position: Vector3, rotation: Quaternion) -> void:
	if live_child != null:
		live_child.force_camera_position(position, rotation)
	else:
		super.force_camera_position(position, rotation)

func get_max_damp_time() -> float:
	var result: float = 0.0
	for camera in get_child_cameras():
		result = maxf(result, camera.get_max_damp_time())
	return result

func _update_child(_camera: Node3D, _world_up: Vector3, _delta: float) -> void:
	return
