class_name CameramanBrain
extends Node

signal camera_cut(brain: CameramanBrain)
signal camera_activated(brain: CameramanBrain, incoming: Object, outgoing: Object)

enum UpdateMethod { PROCESS, PHYSICS, SMART, MANUAL }
enum BlendUpdateMethod { PROCESS, PHYSICS }

@export var camera_path: NodePath
@export var show_debug_text: bool = false
@export var show_camera_frustum: bool = true
@export var ignore_time_scale: bool = false
@export var world_up_override: Node3D
@export_flags("All Channels") var channel_mask: int = 0xFFFFFFFF
@export var update_method: UpdateMethod = UpdateMethod.SMART
@export var blend_update_method: BlendUpdateMethod = BlendUpdateMethod.PROCESS
@export var lens_mode_override_enabled: bool = false
@export var default_lens_mode: CameramanLens.Mode = CameramanLens.Mode.PERSPECTIVE
@export var default_blend: CameramanBlendDefinition
@export var custom_blends: CameramanBlenderSettings

var active_virtual_camera: CameramanVirtualCameraBase
var active_blend: CameramanBlend:
	get:
		return _blend_manager.active_blend
var is_blending: bool:
	get:
		return _blend_manager.active_blend != null
var current_camera_state: CameramanCameraState = CameramanCameraState.create_default()
var _blend_manager: CameramanBlendManager = CameramanBlendManager.new()
var _frame: int = 0
var _overrides: Dictionary = {}
var _next_override_id: int = 1
var _debug_label: Label
var _live_camera: CameramanVirtualCameraBase

func _init() -> void:
	default_blend = CameramanBlendDefinition.new()

func _ready() -> void:
	process_priority = 1000

func _process(delta: float) -> void:
	if update_method == UpdateMethod.PROCESS or update_method == UpdateMethod.SMART:
		_update_frame(delta)

func _physics_process(delta: float) -> void:
	if update_method == UpdateMethod.PHYSICS:
		_update_frame(delta)

func manual_update(delta: float = -1.0) -> void:
	var step: float = delta if delta >= 0.0 else get_process_delta_time()
	_update_frame(step)

func is_live(camera: CameramanVirtualCameraBase) -> bool:
	return _blend_manager.is_live(camera)

func default_world_up() -> Vector3:
	if world_up_override != null:
		return world_up_override.global_basis.y.normalized()
	return Vector3.UP

func set_camera_override(
	identifier: int,
	priority_value: int,
	camera_a: Object,
	camera_b: Object,
	weight_b: float,
	delta: float
) -> int:
	var id: int = identifier
	if id < 0:
		id = _next_override_id
		_next_override_id += 1
	_overrides[id] = {
		"priority": priority_value,
		"camera_a": camera_a,
		"camera_b": camera_b,
		"weight_b": clampf(weight_b, 0.0, 1.0),
		"delta": delta
	}
	return id

func release_camera_override(identifier: int) -> void:
	_overrides.erase(identifier)

func get_output_camera() -> Camera3D:
	if not camera_path.is_empty():
		return get_node_or_null(camera_path) as Camera3D
	return get_parent() as Camera3D

func get_blend_definition(
	from_source: Object,
	to_source: Object,
	fallback: CameramanBlendDefinition
) -> CameramanBlendDefinition:
	if CameramanCore.get_blend_override.is_valid():
		var override_value: Object = CameramanCore.get_blend_override.call(
			from_source,
			to_source,
			fallback,
			self
		) as Object
		if override_value is CameramanBlendDefinition:
			return override_value as CameramanBlendDefinition
	if custom_blends != null:
		return custom_blends.get_blend_for(
			from_source.get_camera_name(),
			to_source.get_camera_name(),
			fallback
		)
	return fallback

func _update_frame(raw_delta: float) -> void:
	_frame += 1
	var delta: float = CameramanCore.delta_time(raw_delta)
	if ignore_time_scale and Engine.time_scale != 0.0:
		delta /= Engine.time_scale
	var world_up: Vector3 = default_world_up()
	var desired: Object = _get_desired_source()
	if desired == null:
		return
	var outgoing: Object = _blend_manager.active_source
	var changed: bool = _blend_manager.update_root_frame(desired, world_up, delta, default_blend, self)
	if changed and desired is CameramanVirtualCameraBase:
		active_virtual_camera = desired as CameramanVirtualCameraBase
		camera_activated.emit(self, desired, outgoing)
		if _live_camera != active_virtual_camera:
			CameramanCore.set_camera_live(_live_camera, false)
			_live_camera = active_virtual_camera
			CameramanCore.set_camera_live(_live_camera, true)
		if _blend_manager.active_blend == null:
			camera_cut.emit(self)
			CameramanCore.get_events().camera_activated.emit(
				CameramanActivationEvent.new(self, null, desired, true, world_up, delta)
			)
	current_camera_state = _blend_manager.update(world_up, delta)
	_apply_state(current_camera_state)
	CameramanCore.get_events().camera_updated.emit(self)
	_update_debug_text()

func _get_desired_source() -> Object:
	var override_entry: Dictionary = _get_top_override()
	if not override_entry.is_empty():
		var camera_b: Object = override_entry["camera_b"] as Object
		var weight_b: float = float(override_entry["weight_b"])
		if weight_b >= 1.0 or camera_b == null:
			return camera_b
		var camera_a: Object = override_entry["camera_a"] as Object
		if camera_a == null:
			return camera_b
		var definition: CameramanBlendDefinition = CameramanBlendDefinition.new()
		definition.time = maxf(float(override_entry["delta"]), 0.0)
		return CameramanFrozenSource.new(
			CameramanNestedBlendSource.new(
				CameramanBlend.new(camera_a, camera_b, definition)
			)
		)
	if CameramanCore.solo_camera != null:
		return CameramanCore.solo_camera
	return CameramanCore.get_registry().get_top_camera(channel_mask, self)

func _get_top_override() -> Dictionary:
	var selected: Dictionary = {}
	var selected_priority: int = -2147483648
	for entry in _overrides.values():
		if int(entry["priority"]) > selected_priority:
			selected = entry
			selected_priority = int(entry["priority"])
	return selected

func _apply_state(state: CameramanCameraState) -> void:
	var output: Camera3D = get_output_camera()
	if output == null:
		return
	var orientation: Quaternion = state.get_final_orientation()
	var dutch: float = deg_to_rad(state.lens.dutch_degrees)
	var basis: Basis = Basis(orientation).rotated(Vector3.FORWARD, dutch)
	output.global_transform = Transform3D(basis, state.get_final_position())
	output.keep_aspect = Camera3D.KEEP_HEIGHT
	output.near = state.lens.near
	output.far = state.lens.far
	var mode: CameramanLens.Mode = state.lens.mode_override
	if lens_mode_override_enabled:
		mode = default_lens_mode
	if mode == CameramanLens.Mode.ORTHOGRAPHIC:
		output.projection = Camera3D.PROJECTION_ORTHOGONAL
		output.size = state.lens.orthographic_size * 2.0
	elif mode == CameramanLens.Mode.FRUSTUM:
		output.projection = Camera3D.PROJECTION_FRUSTUM
		output.fov = state.lens.fov_degrees
		output.frustum_offset = state.lens.frustum_offset
	else:
		output.projection = Camera3D.PROJECTION_PERSPECTIVE
		output.fov = state.lens.fov_degrees

func _update_debug_text() -> void:
	if not show_debug_text:
		if _debug_label != null:
			_debug_label.queue_free()
			_debug_label = null
		return
	if _debug_label == null:
		_debug_label = Label.new()
		_debug_label.position = Vector2(12.0, 12.0)
		add_child(_debug_label)
	_debug_label.text = "Camera: %s\nBlend: %s" % [
		active_virtual_camera.get_camera_name() if active_virtual_camera != null else "<none>",
		active_blend.description() if active_blend != null else "<none>"
	]
