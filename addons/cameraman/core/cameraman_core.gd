class_name CameramanCore
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
static var _live_cameras: Dictionary = {}

static func get_registry() -> CameramanRegistry:
	if registry == null:
		registry = CameramanRegistry.new()
	return registry

static func get_events() -> CameramanEventBus:
	if events == null:
		events = CameramanEventBus.new()
	return events

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
