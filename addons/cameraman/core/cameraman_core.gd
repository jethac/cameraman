@tool
class_name CameramanCore
## Provides shared runtime services, camera registry access, event access, and brain lookup.
extends RefCounted

enum Stage { BODY, AIM, NOISE, FINALIZE }
enum BlendHint {
	SPHERICAL_POSITION = 1,
	CYLINDRICAL_POSITION = 2,
	SCREEN_SPACE_AIM_WHEN_TARGETS_DIFFER = 4,
	INHERIT_POSITION = 8,
	IGNORE_TARGET = 16,
	FREEZE_WHEN_BLENDING_OUT = 32
}

const NO_POINT: Vector3 = Vector3(INF, INF, INF)

static var solo_camera: Node3D
static var uniform_delta_time_override: float = -1.0
static var current_time_override: float = -1.0
static var get_blend_override: Callable
static var get_custom_blender: Callable
static var registry: CameramanRegistry
static var events: CameramanEventBus
static var impulse_manager: RefCounted
static var brains: Array = []
static var _live_cameras: Dictionary = {}
static var _update_token: int = 0

static func register_brain(brain: Node) -> void:
	if brain != null and not brains.has(brain):
		brains.append(brain)

static func unregister_brain(brain: Node) -> void:
	brains.erase(brain)

static func find_brain_for(camera: Node) -> Node:
	var first_brain: Node
	for brain_value in brains.duplicate():
		var brain: Node = brain_value as Node
		if not is_instance_valid(brain):
			brains.erase(brain_value)
			continue
		if first_brain == null:
			first_brain = brain
		if brain.has_method("get_output_camera") and brain.call("get_output_camera") == camera:
			return brain
		if is_live_in_brain(brain, camera):
			return brain
	return first_brain

static func is_live_in_brain(brain: Node, camera: Node) -> bool:
	if brain == null or camera == null:
		return false
	if (
		camera is CameramanVirtualCameraBase
		and brain.has_method("is_live")
		and bool(brain.call("is_live", camera))
	):
		return true
	var parent: Node = camera.get_parent()
	if parent is CameramanCameraManagerBase and parent.is_live_child(camera):
		return is_live_in_brain(brain, parent)
	return false

static func get_registry() -> CameramanRegistry:
	if registry == null:
		registry = CameramanRegistry.new()
	return registry

static func notify_target_warped(target: Node3D, position_delta: Vector3) -> void:
	for camera in get_registry().get_cameras():
		if camera.has_method("on_target_object_warped"):
			camera.on_target_object_warped(target, position_delta)
	for brain_value in brains.duplicate():
		var brain: Node = brain_value as Node
		if is_instance_valid(brain) and brain.has_method("on_target_warped"):
			brain.on_target_warped(target)

static func get_events() -> CameramanEventBus:
	if events == null:
		events = CameramanEventBus.new()
	return events

static func get_impulse_manager() -> CameramanImpulseManager:
	if impulse_manager == null:
		impulse_manager = CameramanImpulseManager.new()
	return impulse_manager as CameramanImpulseManager

static func delta_time(raw: float) -> float:
	if uniform_delta_time_override >= 0.0:
		return uniform_delta_time_override
	return raw

static func current_time() -> float:
	if current_time_override >= 0.0:
		return current_time_override
	return Time.get_ticks_msec() * 0.001

static func is_live(camera: Node3D) -> bool:
	return camera != null and bool(_live_cameras.get(camera, false))

static func set_camera_live(camera: Node3D, live: bool) -> void:
	if camera == null:
		return
	if live:
		_live_cameras[camera] = true
	else:
		_live_cameras.erase(camera)

static func find_potential_target_brain(camera: Node3D) -> Node:
	if camera == null:
		return null
	var current: Node = camera.get_parent()
	while current != null:
		if current.has_method("is_live") and current.has_method("manual_update"):
			return current
		current = current.get_parent()
	return null

static func next_update_token() -> int:
	_update_token += 1
	return _update_token

static func update_virtual_camera(
	camera: Node3D,
	world_up: Vector3,
	delta: float,
	frame: int
) -> void:
	get_registry().update_camera(camera, world_up, delta, frame)
